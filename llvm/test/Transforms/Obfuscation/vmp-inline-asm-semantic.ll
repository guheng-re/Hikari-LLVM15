; Restricted direct InlineAsm CallInst: ATT, non-throwing, not
; alignstack, CallingConv::C, non-vararg FunctionType matching the
; InlineAsm, 0..8 args.  Result/args are void (result only) / i1..i64
; / AS0 pointer.  I/O constraints only "r"; clobbers only {memory} /
; {cc}.  Replayed through CallDescriptor (InlineAsm* on the
; descriptor).  Ordinary tail is a hint and is replayed as TCK_None.
; musttail stays early "musttail call" (musttail of inline asm is
; verifier-invalid, so the negative uses a same-prototype helper
; plus accepted-shape nop).  Out-of-shape asm stays "inline
; assembly" and keeps hikari.vmp.selected.  InvokeInst stays closed.
; Restricted CallBr is vmp-inline-asm-callbr-semantic.ll.
;
; Plan lock-in: i64 / AS0 pointer / {cc} must virtualize; alignstack
; / unwind / matching / early-clobber stay "inline assembly".
; Pointer *memory* (ldr/str through an AS0 "r" pointer) is
; vmp-inline-asm-pointer-memory-semantic.ll, not the empty-string
; pointer register copy below.
; Host cannot execute AArch64 inline asm (lli fatal).  FileCheck +
; AArch64 llc/readobj/asm only.  O0/O2 x 97/7.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.ll > %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o0.live.ll -o - | FileCheck %s --check-prefix=ASM
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.ll > %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o2.live.ll -o - | FileCheck %s --check-prefix=ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.s7.ll > %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o0.s7.live.ll -o - | FileCheck %s --check-prefix=ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.s7.ll > %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o2.s7.live.ll -o - | FileCheck %s --check-prefix=ASM
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %s | opt -S -verify-each -aesSeed=97 -passes='default<O0>' - 2>&1 | FileCheck %s --check-prefix=HOST

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()

define void @protected_nop() noinline optnone {
entry:
  call void @hikari_vmp()
  call void asm sideeffect "nop", ""()
  ret void
}

define void @protected_nop_tail() noinline optnone {
entry:
  call void @hikari_vmp()
  tail call void asm sideeffect "nop", ""()
  ret void
}

define i32 @protected_copy(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 asm "", "=r,r"(i32 %x)
  ret i32 %r
}

define i32 @protected_copy_tail(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = tail call i32 asm "", "=r,r"(i32 %x)
  ret i32 %r
}

define i32 @protected_mov(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 asm "mov ${0:w}, ${1:w}", "=r,r"(i32 %x)
  ret i32 %r
}

define void @protected_dmb() noinline optnone {
entry:
  call void @hikari_vmp()
  call void asm sideeffect "dmb ish", "~{memory}"()
  ret void
}

define i64 @protected_copy_i64(i64 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 asm "", "=r,r"(i64 %x)
  ret i64 %r
}

define ptr @protected_copy_ptr(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call ptr asm "", "=r,r"(ptr %p)
  ret ptr %r
}

define void @protected_cc() noinline optnone {
entry:
  call void @hikari_vmp()
  call void asm sideeffect "nop", "~{cc}"()
  ret void
}

define i32 @musttail_helper(i32 %x) noinline {
entry:
  ret i32 %x
}

define i32 @unsupported_musttail(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  call void asm sideeffect "nop", ""()
  %r = musttail call i32 @musttail_helper(i32 %x)
  ret i32 %r
}

define i32 @unsupported_bundle(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 asm "", "=r,r"(i32 %x) [ "deopt"(i32 0) ]
  ret i32 %r
}

define i32 @unsupported_fastcc(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc i32 asm "", "=r,r"(i32 %x)
  ret i32 %r
}

define void @unsupported_sret(ptr sret(i32) %p) noinline optnone {
entry:
  call void @hikari_vmp()
  call void asm sideeffect "nop", "r"(ptr sret(i32) %p)
  ret void
}

define fp128 @unsupported_fp128(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 asm "", "=r,r"(fp128 %a)
  ret fp128 %r
}

define void @unsupported_clobber_sp() noinline optnone {
entry:
  call void @hikari_vmp()
  call void asm sideeffect "nop", "~{sp}"()
  ret void
}

define void @unsupported_intel() noinline optnone {
entry:
  call void @hikari_vmp()
  call void asm sideeffect inteldialect "nop", ""()
  ret void
}

define void @unsupported_alignstack() noinline optnone {
entry:
  call void @hikari_vmp()
  call void asm sideeffect alignstack "nop", ""()
  ret void
}

define void @unsupported_unwind() noinline optnone {
entry:
  call void @hikari_vmp()
  call void asm sideeffect unwind "nop", ""()
  ret void
}

define i32 @unsupported_matching(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 asm "", "=r,0"(i32 %x)
  ret i32 %r
}

define i32 @unsupported_earlyclobber(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 asm "", "=&r,r"(i32 %x)
  ret i32 %r
}

define void @main() {
entry:
  ret void
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: inline assembly
; SKIP-DAG: Skipping VMP on unsupported_fastcc: inline assembly
; SKIP-DAG: Skipping VMP on unsupported_sret: inline assembly
; SKIP-DAG: Skipping VMP on unsupported_fp128: inline assembly
; SKIP-DAG: Skipping VMP on unsupported_clobber_sp: inline assembly
; SKIP-DAG: Skipping VMP on unsupported_intel: inline assembly
; SKIP-DAG: Skipping VMP on unsupported_alignstack: inline assembly
; SKIP-DAG: Skipping VMP on unsupported_unwind: inline assembly
; SKIP-DAG: Skipping VMP on unsupported_matching: inline assembly
; SKIP-DAG: Skipping VMP on unsupported_earlyclobber: inline assembly
; SKIP-NOT: Skipping VMP on protected_nop:
; SKIP-NOT: Skipping VMP on protected_nop_tail:
; SKIP-NOT: Skipping VMP on protected_copy:
; SKIP-NOT: Skipping VMP on protected_copy_tail:
; SKIP-NOT: Skipping VMP on protected_mov:
; SKIP-NOT: Skipping VMP on protected_dmb:
; SKIP-NOT: Skipping VMP on protected_copy_i64:
; SKIP-NOT: Skipping VMP on protected_copy_ptr:
; SKIP-NOT: Skipping VMP on protected_cc:

; VIRT-LABEL: define void @protected_nop(
; VIRT-SAME: #[[PROT:[0-9]+]]
; VIRT: vmp.dispatch:
; VIRT-NOT: tail call void asm
; VIRT: call void asm sideeffect "nop", ""()
; VIRT-LABEL: define void @protected_nop_tail(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT-NOT: tail call void asm
; VIRT: call void asm sideeffect "nop", ""()
; VIRT-LABEL: define i32 @protected_copy(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT-NOT: tail call i32 asm
; VIRT: call i32 asm "", "=r,r"(i32
; VIRT-LABEL: define i32 @protected_copy_tail(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT-NOT: tail call i32 asm
; VIRT: call i32 asm "", "=r,r"(i32
; VIRT-LABEL: define i32 @protected_mov(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call i32 asm "mov ${0:w}, ${1:w}", "=r,r"(i32
; VIRT-LABEL: define void @protected_dmb(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call void asm sideeffect "dmb ish", "~{memory}"()
; VIRT-LABEL: define i64 @protected_copy_i64(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call i64 asm "", "=r,r"(i64
; VIRT-LABEL: define ptr @protected_copy_ptr(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call ptr asm "", "=r,r"(ptr
; VIRT-LABEL: define void @protected_cc(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call void asm sideeffect "nop", "~{cc}"()
; VIRT-LABEL: define {{.*}} @unsupported_musttail(
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call i32 @musttail_helper(
; VIRT: define {{.*}} @unsupported_bundle({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fastcc({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_sret({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fp128({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_clobber_sp({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_intel({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_alignstack({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call void asm sideeffect alignstack "nop", ""()
; VIRT: define {{.*}} @unsupported_unwind({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call void asm sideeffect unwind "nop", ""()
; VIRT: define {{.*}} @unsupported_matching({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call i32 asm "", "=r,0"(i32
; VIRT: define {{.*}} @unsupported_earlyclobber({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call i32 asm "", "=&r,r"(i32
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; ASM-DAG: nop
; ASM-DAG: dmb{{.*}}ish
; ASM-DAG: mov
; HOST: Skipping VMP: only AArch64 targets are supported
