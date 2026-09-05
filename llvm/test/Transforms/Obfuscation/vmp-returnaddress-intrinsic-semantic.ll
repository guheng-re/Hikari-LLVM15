; llvm.returnaddress(i32 0): current function incoming LR.  VMP rewrites
; this function in place, so depth 0 must be replayed as the original
; intrinsic with a true ImmArg 0 (never a VReg load).  Do not fold or
; synthesize an address.  AArch64 LowerRETURNADDR(0) copies LR/x30 then
; XPACLRI (hint #7).  Depth > 0 walks the FP chain and is not trusted
; after VMP/CFF frame changes.
;
; Host IntrinsicLowering replaces the call with null; ORC JIT was
; probed and two same-function reads are not reliably equal, so no lli.
; FileCheck + AArch64 llc/readobj/asm only.
;
; Dynamic / poison / undef depth cannot share a module with the
; canonical ImmArg declare (verifier: "immarg operand has non-immediate
; parameter").  The legal poison form next to a live depth-0 call is a
; pointer icmp against poison (comparison operand gate).
;
; Rejected: depth>0, poison icmp, AS1 args, musttail, bundles, fastcc,
; sret+byval.  Ordinary tail is accepted and demoted.
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
declare ptr @llvm.returnaddress(i32 immarg)
declare void @ext_sret_byval(ptr sret(i32), ptr byval(i32))

; ----- positives -----

define i32 @protected() noinline optnone {
entry:
  call void @hikari_vmp()
  %a = call ptr @llvm.returnaddress(i32 0)
  %b = call ptr @llvm.returnaddress(i32 0)
  %eq = icmp eq ptr %a, %b
  %c = zext i1 %eq to i32
  ret i32 %c
}

define ptr @protected_loop(i32 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %ra = call ptr @llvm.returnaddress(i32 0)
  store ptr %ra, ptr %slot, align 8
  %i1 = add i32 %i, 1
  %more = icmp slt i32 %i1, %n
  br i1 %more, label %loop, label %done

done:
  %out = load ptr, ptr %slot, align 8
  ret ptr %out
}

define ptr @protected_tail() noinline optnone {
entry:
  call void @hikari_vmp()
  %p = tail call ptr @llvm.returnaddress(i32 0)
  ret ptr %p
}

; ----- negatives -----

define ptr @unsupported_depth1() noinline optnone {
entry:
  call void @hikari_vmp()
  %a = call ptr @llvm.returnaddress(i32 1)
  ret ptr %a
}

define i1 @unsupported_poison() noinline optnone {
entry:
  call void @hikari_vmp()
  %a = call ptr @llvm.returnaddress(i32 0)
  %c = icmp eq ptr %a, poison
  ret i1 %c
}

define ptr @unsupported_as1_arg(ptr addrspace(1) %unused) noinline optnone {
entry:
  call void @hikari_vmp()
  %a = call ptr @llvm.returnaddress(i32 0)
  ret ptr %a
}

define ptr @unsupported_musttail() noinline optnone {
entry:
  call void @hikari_vmp()
  %a = musttail call ptr @llvm.returnaddress(i32 0)
  ret ptr %a
}

define ptr @unsupported_bundle() noinline optnone {
entry:
  call void @hikari_vmp()
  %a = call ptr @llvm.returnaddress(i32 0) [ "deopt"(i32 0) ]
  ret ptr %a
}

define ptr @unsupported_fastcc() noinline optnone {
entry:
  call void @hikari_vmp()
  %a = call fastcc ptr @llvm.returnaddress(i32 0)
  ret ptr %a
}

define void @unsupported_sret(ptr sret(i32) %p, ptr byval(i32) %q) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @ext_sret_byval(ptr sret(i32) %p, ptr byval(i32) %q)
  ret void
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_depth1: unsupported returnaddress
; SKIP-DAG: Skipping VMP on unsupported_poison: unsupported comparison
; SKIP-DAG: Skipping VMP on unsupported_as1_arg: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported returnaddress
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported returnaddress
; SKIP-DAG: Skipping VMP on unsupported_sret: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected:
; SKIP-NOT: Skipping VMP on protected_loop:
; SKIP-NOT: Skipping VMP on protected_tail:

; VIRT: define i32 @protected({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call void @hikari_vmp()
; The depth-0 intrinsic is re-emitted with a literal i32 0 immarg
; (never a VReg load/trunc, never null / inttoptr).
; VIRT-DAG: [[RA0:%.*]] = call ptr @llvm.returnaddress(i32 0)
; VIRT-DAG: [[RA1:%.*]] = call ptr @llvm.returnaddress(i32 0)
; VIRT-DAG: store volatile ptr [[RA0]], ptr {{.*}}, align 8
; VIRT-DAG: store volatile ptr [[RA1]], ptr {{.*}}, align 8
; VIRT-NOT: call ptr @llvm.returnaddress(i32 1)
; VIRT: }
; VIRT: define ptr @protected_loop({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: [[RL:%.*]] = call ptr @llvm.returnaddress(i32 0)
; VIRT-DAG: store volatile ptr [[RL]], ptr {{.*}}, align 8
; VIRT: }
; VIRT: define ptr @protected_tail({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: tail call ptr @llvm.returnaddress
; VIRT-DAG: [[RT:%.*]] = call ptr @llvm.returnaddress(i32 0)
; VIRT-DAG: store volatile ptr [[RT]], ptr {{.*}}, align 8
; VIRT: }
; VIRT: define {{.*}} @unsupported_depth1({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call ptr @llvm.returnaddress(i32 1)
; VIRT: define {{.*}} @unsupported_poison({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call ptr @llvm.returnaddress(i32 0)
; VIRT: define {{.*}} @unsupported_as1_arg({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_musttail({{.*}} #[[UNSUPMUST:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call ptr @llvm.returnaddress(i32 0)
; VIRT: define {{.*}} @unsupported_bundle({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fastcc({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_sret({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPMUST]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPMUST]] = { {{.*}}"hikari.vmp.selected"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; Depth 0: copy incoming LR then XPACLRI (hint #7).  Must not be a
; synthesized constant pointer.
; AARCH64-ASM: hint #7
