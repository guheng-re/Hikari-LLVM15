; llvm.addressofreturnaddress(): address of this function's return-
; address slot.  C, exact non-vararg ptr(), AS0, zero args.  VMP
; rewrites this function in place, so the slot must be replayed as the
; original intrinsic (never folded or synthesized).  AArch64
; LowerADDROFRETURNADDR is FP+8 (x29).
;
; Host IntrinsicLowering / JIT are not faithful and the slot address
; is not stable across the VMP rewrite, so no lli.
; FileCheck + AArch64 llc/readobj/asm only.
;
; A non-ptr() / vararg FunctionType cannot share a module with the
; canonical declare (verifier: incompatible signature).  Call-site
; noreturn is the probed-legal malformed form.  Ordinary tail is
; rejected.
;
; FileCheck + AArch64 llc/readobj/asm.  O0/O2 x aesSeed 97/7.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.ll > %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o0.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.ll > %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o2.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.s7.ll > %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o0.s7.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.s7.ll > %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o2.s7.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare ptr @llvm.addressofreturnaddress.p0()
declare ptr addrspace(1) @llvm.addressofreturnaddress.p1()

; ----- positives -----

define i32 @protected() noinline optnone {
entry:
  call void @hikari_vmp()
  %a = call ptr @llvm.addressofreturnaddress.p0()
  %b = call ptr @llvm.addressofreturnaddress.p0()
  %eq = icmp eq ptr %a, %b
  %c = zext i1 %eq to i32
  ret i32 %c
}

; ----- negatives -----

; Call-site noreturn is verifier-legal malformed (doesNotReturn).
define ptr @unsupported_malformed() noinline optnone {
entry:
  call void @hikari_vmp()
  %a = call ptr @llvm.addressofreturnaddress.p0() noreturn
  ret ptr %a
}

define ptr @unsupported_as1() noinline optnone {
entry:
  call void @hikari_vmp()
  %a = call ptr addrspace(1) @llvm.addressofreturnaddress.p1()
  %c = addrspacecast ptr addrspace(1) %a to ptr
  ret ptr %c
}


define ptr @unsupported_musttail() noinline optnone {
entry:
  call void @hikari_vmp()
  %a = musttail call ptr @llvm.addressofreturnaddress.p0()
  ret ptr %a
}

define ptr @unsupported_bundle() noinline optnone {
entry:
  call void @hikari_vmp()
  %a = call ptr @llvm.addressofreturnaddress.p0() [ "deopt"(i32 0) ]
  ret ptr %a
}

define ptr @unsupported_fastcc() noinline optnone {
entry:
  call void @hikari_vmp()
  %a = call fastcc ptr @llvm.addressofreturnaddress.p0()
  ret ptr %a
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_malformed: unsupported addressofreturnaddress
; SKIP-DAG: Skipping VMP on unsupported_as1: unsupported addressofreturnaddress
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported addressofreturnaddress
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported addressofreturnaddress
; SKIP-NOT: Skipping VMP on protected:

; VIRT: define i32 @protected({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call void @hikari_vmp()
; The slot address is re-emitted as the original intrinsic (never
; null / inttoptr / a synthesized GEP).
; VIRT-DAG: [[AO0:%.*]] = call ptr @llvm.addressofreturnaddress.p0()
; VIRT-DAG: [[AO1:%.*]] = call ptr @llvm.addressofreturnaddress.p0()
; VIRT-DAG: store volatile ptr [[AO0]], ptr {{.*}}, align 8
; VIRT-DAG: store volatile ptr [[AO1]], ptr {{.*}}, align 8
; VIRT: }
; VIRT: define {{.*}} @unsupported_malformed({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_as1({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call ptr addrspace(1) @llvm.addressofreturnaddress.p1()
; VIRT: define {{.*}} @unsupported_musttail({{.*}} #[[UNSUPMUST:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call ptr @llvm.addressofreturnaddress.p0()
; VIRT: define {{.*}} @unsupported_bundle({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fastcc({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPMUST]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPMUST]] = { {{.*}}"hikari.vmp.selected"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; Slot address lowers from FP (x29) + 8.  Must not be a synthesized
; constant pointer.
; AARCH64-ASM: x29
