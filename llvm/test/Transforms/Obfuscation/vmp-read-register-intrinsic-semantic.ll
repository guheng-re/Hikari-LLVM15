; AArch64 llvm.read_register / llvm.read_volatile_register: i64 result,
; metadata argument exactly !{!"pc"}.  The name is a MetadataAsValue
; special argument on CallDescriptor (TrackingMDNodeRef, rebuilt in
; emitCallHandler, never a VReg payload).  protected uses two distinct
; !{!"pc"} nodes so re-emit must preserve each tracked operand (not a
; single raw MDNode* that dies on RAUW).  write_register stays skipped:
; llc accepts "sp"/"nzcv"/"TPIDR_EL0" but none are baseline-safe for VMP;
; "pc" write is an llc fatal.  Wrong metadata / width / call attributes
; skip.  No host lli: the interpreter cannot lower read_register.
; AArch64 llc is the codegen check.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.ll -o %t.o0.o
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP-O2 < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT-O2 < %t.o2.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.ll -o %t.o2.o
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP-O2 < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT-O2 < %t.o2.s7.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare i64 @llvm.read_register.i64(metadata)
declare i64 @llvm.read_volatile_register.i64(metadata)
declare i32 @llvm.read_register.i32(metadata)
declare void @llvm.write_register.i64(metadata, i64)

define i64 @reference() {
entry:
  %a = call i64 @llvm.read_register.i64(metadata !0)
  %b = call i64 @llvm.read_volatile_register.i64(metadata !4)
  %x = xor i64 %a, %b
  ret i64 %x
}

define i64 @protected() noinline optnone {
entry:
  call void @hikari_vmp()
  %a = call i64 @llvm.read_register.i64(metadata !0)
  %b = call i64 @llvm.read_volatile_register.i64(metadata !4)
  %x = xor i64 %a, %b
  ret i64 %x
}

define i64 @unsupported_write_register(i64 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.write_register.i64(metadata !1, i64 %x)
  ret i64 %x
}

define i64 @unsupported_name() noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call i64 @llvm.read_register.i64(metadata !1)
  ret i64 %t
}

define i64 @unsupported_extra_md() noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call i64 @llvm.read_register.i64(metadata !2)
  ret i64 %t
}

define i32 @unsupported_i32() noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call i32 @llvm.read_register.i32(metadata !0)
  ret i32 %t
}

define i64 @unsupported_noreturn() noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call i64 @llvm.read_register.i64(metadata !0) noreturn
  ret i64 %t
}

define i64 @unsupported_bundle() noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call i64 @llvm.read_register.i64(metadata !0) [ "deopt"(i32 0) ]
  ret i64 %t
}

define i32 @main() {
entry:
  %e = call i64 @reference()
  %a = call i64 @protected()
  ; PC values are not compared: they are not stable across calls.
  ; Keep both live so neither is DCE'd.
  %mix = xor i64 %e, %a
  %lo = trunc i64 %mix to i32
  ret i32 %lo
}

!0 = distinct !{!"pc"}
!4 = distinct !{!"pc"}
!1 = !{!"sp"}
!2 = !{!"pc", !"x"}

; SKIP-DAG: Skipping VMP on unsupported_write_register: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_name: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_extra_md: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_i32: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_noreturn: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected:
; SKIP-NOT: Skipping VMP on reference:

; VIRT: define i64 @protected(){{.*}}#[[POSATTR:[0-9]+]] {
; VIRT: %vmp.regs = alloca
; VIRT: vmp.dispatch:
; Distinct !{!"pc"} operands must both be re-emitted (not collapsed to a
; dangling raw MDNode* or a single shared operand).
; VIRT-DAG: call i64 @llvm.read_register.i64(metadata ![[PC0:[0-9]+]])
; VIRT-DAG: call i64 @llvm.read_volatile_register.i64(metadata ![[PC1:[0-9]+]])

; VIRT-LABEL: define i64 @unsupported_write_register(
; VIRT-NOT: vmp.dispatch
; VIRT: call void @llvm.write_register.i64
; VIRT-LABEL: define i64 @unsupported_name(
; VIRT-NOT: vmp.dispatch
; VIRT: call i64 @llvm.read_register.i64
; VIRT-LABEL: define i64 @unsupported_extra_md(
; VIRT-NOT: vmp.dispatch
; VIRT: call i64 @llvm.read_register.i64
; VIRT-LABEL: define i32 @unsupported_i32(
; VIRT-NOT: vmp.dispatch
; VIRT: call i32 @llvm.read_register.i32
; VIRT-LABEL: define i64 @unsupported_noreturn(
; VIRT-NOT: vmp.dispatch
; VIRT: call i64 @llvm.read_register.i64
; VIRT-LABEL: define i64 @unsupported_bundle(
; VIRT-NOT: vmp.dispatch
; VIRT: call i64 @llvm.read_register.i64

; VIRT: attributes #[[POSATTR]] = { noinline optnone "hikari.vmp.selected" "hikari.vmp.virtualized" }{{$}}
; VIRT-DAG: ![[PC0]] = distinct !{!"pc"}
; VIRT-DAG: ![[PC1]] = distinct !{!"pc"}

; SKIP-O2-DAG: Skipping VMP on unsupported_write_register: unsupported call instruction
; SKIP-O2-DAG: Skipping VMP on unsupported_name: unsupported call instruction
; SKIP-O2-DAG: Skipping VMP on unsupported_extra_md: unsupported call instruction
; SKIP-O2-DAG: Skipping VMP on unsupported_i32: unsupported call instruction
; SKIP-O2-DAG: Skipping VMP on unsupported_noreturn: unsupported call instruction
; SKIP-O2-DAG: Skipping VMP on unsupported_bundle: unsupported call instruction
; SKIP-O2-NOT: Skipping VMP on protected:

; VIRT-O2: define i64 @protected(){{.*}}#[[POSATTR:[0-9]+]] {
; VIRT-O2: %vmp.regs = alloca
; VIRT-O2: vmp.dispatch:
; VIRT-O2-DAG: call i64 @llvm.read_register.i64(metadata ![[PC0:[0-9]+]])
; VIRT-O2-DAG: call i64 @llvm.read_volatile_register.i64(metadata ![[PC1:[0-9]+]])
; VIRT-O2-LABEL: define i64 @unsupported_write_register(
; VIRT-O2-NOT: vmp.dispatch
; VIRT-O2: call void @llvm.write_register.i64
; VIRT-O2: attributes #[[POSATTR]] = { noinline optnone "hikari.vmp.selected" "hikari.vmp.virtualized" }{{$}}
; VIRT-O2-DAG: ![[PC0]] = distinct !{!"pc"}
; VIRT-O2-DAG: ![[PC1]] = distinct !{!"pc"}
