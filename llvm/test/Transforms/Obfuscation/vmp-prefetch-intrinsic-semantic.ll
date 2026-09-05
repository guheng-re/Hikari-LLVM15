; llvm.prefetch: C, exact non-vararg void(ptr, i32, i32, i32).  AS0
; ordinary pointer + i32 ImmArg ranges (rw {0,1}, locality {0..3},
; cache {0,1}).  Replay via CallDescriptor (pointer VReg + immediate
; args); never fold or delete.  Ordinary tail accepted and replayed as TCK_None.
;
; Host IntrinsicLowering strips prefetch, so store/load around it is
; reliable — but FileCheck + AArch64 llc/readobj/asm are the contract
; checks.  No lli (replay, not host lowering, is the point).
;
; Non-AS0 uses the .p1 overload (function AS1 arg hits the argument
; gate).  Out-of-range rw/locality/cache cannot share a module
; (verifier: invalid arguments to llvm.prefetch).  poison pointer is
; the dedicated type/operand skip.  Call-site noreturn is the
; probed-legal malformed form.
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
declare void @llvm.prefetch.p0(ptr, i32 immarg, i32 immarg, i32)
declare void @llvm.prefetch.p1(ptr addrspace(1), i32 immarg, i32 immarg, i32)
declare void @ext_sret_byval(ptr sret(i32), ptr byval(i32))

; ----- positives -----

define i32 @protected(i32 %val) noinline optnone {
entry:
  call void @hikari_vmp()
  %buf = alloca [4 x i32], align 4
  %p = getelementptr inbounds [4 x i32], ptr %buf, i64 0, i64 0
  call void @llvm.prefetch.p0(ptr %p, i32 0, i32 3, i32 1)
  store i32 %val, ptr %p, align 4
  %out = load i32, ptr %p, align 4
  ret i32 %out
}

define void @protected_write(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.prefetch.p0(ptr %p, i32 1, i32 0, i32 0)
  ret void
}

; ----- negatives -----

define void @unsupported_malformed(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.prefetch.p0(ptr %p, i32 0, i32 3, i32 1) noreturn
  ret void
}

define void @unsupported_as1_arg(ptr addrspace(1) %p) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.prefetch.p1(ptr addrspace(1) %p, i32 0, i32 3, i32 1)
  ret void
}

define void @unsupported_poison(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.prefetch.p0(ptr poison, i32 0, i32 3, i32 1)
  ret void
}


define void @unsupported_musttail(ptr %p, i32 %a, i32 %b, i32 %c) noinline optnone {
entry:
  call void @hikari_vmp()
  musttail call void @llvm.prefetch.p0(ptr %p, i32 0, i32 3, i32 1)
  ret void
}

define void @unsupported_bundle(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.prefetch.p0(ptr %p, i32 0, i32 3, i32 1) [ "deopt"(i32 0) ]
  ret void
}

define void @unsupported_fastcc(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  call fastcc void @llvm.prefetch.p0(ptr %p, i32 0, i32 3, i32 1)
  ret void
}

define void @unsupported_sret(ptr sret(i32) %p, ptr byval(i32) %q) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @ext_sret_byval(ptr sret(i32) %p, ptr byval(i32) %q)
  ret void
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_malformed: unsupported prefetch
; SKIP-DAG: Skipping VMP on unsupported_as1_arg: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_poison: unsupported prefetch
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported prefetch
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported prefetch
; SKIP-DAG: Skipping VMP on unsupported_sret: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected:
; SKIP-NOT: Skipping VMP on protected_write:

; VIRT: define i32 @protected({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call void @hikari_vmp()
; Prefetch is re-emitted with immediate rw/locality/cache (never deleted).
; VIRT-DAG: call void @llvm.prefetch.p0(ptr {{.*}}, i32 0, i32 3, i32 1)
; VIRT: }
; VIRT: define void @protected_write({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: call void @llvm.prefetch.p0(ptr {{.*}}, i32 1, i32 0, i32 0)
; VIRT: }
; VIRT: define {{.*}} @unsupported_malformed({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_as1_arg({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_poison({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_musttail({{.*}} #[[UNSUPMUST:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call void @llvm.prefetch.p0(
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
; AArch64 ISel of the replayed prefetch (not deleted).
; AARCH64-ASM: prfm
