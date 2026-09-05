; llvm.frameaddress(i32 0): current function FP.  Aligns with the
; returnaddress depth-0 contract: C, exact non-vararg ptr(i32), AS0
; result, i32 ImmArg ConstantInt 0.  VMP rewrites this function in
; place, so depth 0 must be replayed as the original intrinsic with a
; true ImmArg 0 (never a VReg load).  Do not fold or synthesize an
; address.  AArch64 LowerFRAMEADDR(0) copies FP/x29.  Depth > 0 walks
; the FP chain and is not trusted after VMP/CFF frame changes.
;
; Frame addresses are not stable across the VMP rewrite (the
; interpreter frame is not the original frame) and host
; IntrinsicLowering / JIT are not faithful, so no lli.
; FileCheck + AArch64 llc/readobj/asm only.
;
; Dynamic / non-ImmArg / poison depth and a non-ptr(i32) / vararg
; FunctionType cannot share a module with the canonical declare
; (verifier: immarg non-immediate, or "incompatible signature").
; The legal poison form next to a live depth-0 call is a pointer icmp
; against poison.  Call-site noreturn is the probed-legal malformed
; form (doesNotReturn).  Ordinary tail accepted and replayed as TCK_None.
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
declare ptr @llvm.frameaddress.p0(i32 immarg)
declare ptr addrspace(1) @llvm.frameaddress.p1(i32 immarg)
declare void @ext_sret_byval(ptr sret(i32), ptr byval(i32))

; ----- positives -----

define i32 @protected() noinline optnone {
entry:
  call void @hikari_vmp()
  %a = call ptr @llvm.frameaddress.p0(i32 0)
  %b = call ptr @llvm.frameaddress.p0(i32 0)
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
  %fa = call ptr @llvm.frameaddress.p0(i32 0)
  store ptr %fa, ptr %slot, align 8
  %i1 = add i32 %i, 1
  %more = icmp slt i32 %i1, %n
  br i1 %more, label %loop, label %done

done:
  %out = load ptr, ptr %slot, align 8
  ret ptr %out
}

; ----- negatives -----

define ptr @unsupported_depth1() noinline optnone {
entry:
  call void @hikari_vmp()
  %a = call ptr @llvm.frameaddress.p0(i32 1)
  ret ptr %a
}

; Call-site noreturn is verifier-legal and hits doesNotReturn.
; A non-ptr(i32) / vararg FunctionType is rejected by the gate but
; cannot appear beside the canonical declare (verifier incompatible
; signature).
define ptr @unsupported_malformed() noinline optnone {
entry:
  call void @hikari_vmp()
  %a = call ptr @llvm.frameaddress.p0(i32 0) noreturn
  ret ptr %a
}

define ptr @unsupported_as1() noinline optnone {
entry:
  call void @hikari_vmp()
  %a = call ptr addrspace(1) @llvm.frameaddress.p1(i32 0)
  %c = addrspacecast ptr addrspace(1) %a to ptr
  ret ptr %c
}

define i1 @unsupported_poison() noinline optnone {
entry:
  call void @hikari_vmp()
  %a = call ptr @llvm.frameaddress.p0(i32 0)
  %c = icmp eq ptr %a, poison
  ret i1 %c
}


define ptr @unsupported_musttail() noinline optnone {
entry:
  call void @hikari_vmp()
  %a = musttail call ptr @llvm.frameaddress.p0(i32 0)
  ret ptr %a
}

define ptr @unsupported_bundle() noinline optnone {
entry:
  call void @hikari_vmp()
  %a = call ptr @llvm.frameaddress.p0(i32 0) [ "deopt"(i32 0) ]
  ret ptr %a
}

define ptr @unsupported_fastcc() noinline optnone {
entry:
  call void @hikari_vmp()
  %a = call fastcc ptr @llvm.frameaddress.p0(i32 0)
  ret ptr %a
}

define void @unsupported_sret(ptr sret(i32) %p, ptr byval(i32) %q) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @ext_sret_byval(ptr sret(i32) %p, ptr byval(i32) %q)
  ret void
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_depth1: unsupported frameaddress
; SKIP-DAG: Skipping VMP on unsupported_malformed: unsupported frameaddress
; SKIP-DAG: Skipping VMP on unsupported_as1: unsupported frameaddress
; SKIP-DAG: Skipping VMP on unsupported_poison: unsupported comparison
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported frameaddress
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported frameaddress
; SKIP-DAG: Skipping VMP on unsupported_sret: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected:
; SKIP-NOT: Skipping VMP on protected_loop:

; VIRT: define i32 @protected({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call void @hikari_vmp()
; The depth-0 intrinsic is re-emitted with a literal i32 0 immarg
; (never a VReg load/trunc, never null / inttoptr).
; VIRT-DAG: [[FA0:%.*]] = call ptr @llvm.frameaddress.p0(i32 0)
; VIRT-DAG: [[FA1:%.*]] = call ptr @llvm.frameaddress.p0(i32 0)
; VIRT-DAG: store volatile ptr [[FA0]], ptr {{.*}}, align 8
; VIRT-DAG: store volatile ptr [[FA1]], ptr {{.*}}, align 8
; VIRT-NOT: call ptr @llvm.frameaddress.p0(i32 1)
; VIRT: }
; VIRT: define ptr @protected_loop({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: [[FL:%.*]] = call ptr @llvm.frameaddress.p0(i32 0)
; VIRT-DAG: store volatile ptr [[FL]], ptr {{.*}}, align 8
; VIRT: }
; VIRT: define {{.*}} @unsupported_depth1({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call ptr @llvm.frameaddress.p0(i32 1)
; VIRT: define {{.*}} @unsupported_malformed({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_as1({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call ptr addrspace(1) @llvm.frameaddress.p1(i32 0)
; VIRT: define {{.*}} @unsupported_poison({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_musttail({{.*}} #[[UNSUPMUST:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call ptr @llvm.frameaddress.p0(i32 0)
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
; Depth 0: copy incoming FP (x29).  Must not be a synthesized constant.
; AARCH64-ASM: x29
