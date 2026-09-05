; Common memory-intrinsic CallDescriptor family: memcpy / memmove /
; memset / memcpy.inline and memcpy/memmove/memset.element.unordered.atomic.
; C, exact non-vararg FTy, formal type equality, AS0 pointers, i32/i64
; lengths (memcpy.inline ImmArg constant).  Ordinary tail accepted and replayed as TCK_None.
; Atomic: positive constant length multiple of power-of-two elementsize,
; explicit align >= elementsize.  Replay; never fold.  No new opcode.
;
; Host IntrinsicLowering maps ordinary mem* to libc; lli of the
; store/copy/load sequence is reliable.  Atomic element forms are
; FileCheck + AArch64 llc only (host needs compiler-rt libcalls).
;
; FileCheck + host lli (ordinary) + AArch64 llc/readobj.  O0/O2 x 97/7.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.ll > %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.live.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.ll > %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.live.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.s7.ll > %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.s7.live.ll > %t.o0.s7.host.ll
; RUN: lli -force-interpreter %t.o0.s7.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.s7.ll > %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.s7.live.ll > %t.o2.s7.host.ll
; RUN: lli -force-interpreter %t.o2.s7.host.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg)
declare void @llvm.memmove.p0.p0.i64(ptr nocapture writeonly, ptr nocapture readonly, i64, i1 immarg)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare void @llvm.memcpy.inline.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64 immarg, i1 immarg)
declare void @llvm.memcpy.element.unordered.atomic.p0.p0.i64(ptr nocapture writeonly, ptr nocapture readonly, i64, i32 immarg)
declare void @llvm.memmove.element.unordered.atomic.p0.p0.i64(ptr nocapture writeonly, ptr nocapture readonly, i64, i32 immarg)
declare void @llvm.memset.element.unordered.atomic.p0.i64(ptr nocapture writeonly, i8, i64, i32 immarg)
declare void @ext_sret_byval(ptr sret(i32), ptr byval(i32))

; Host/runtime stubs if atomic-element forms lower to libcalls.
define void @__llvm_memcpy_element_unordered_atomic_4(ptr %dest, ptr %src, i64 %len) {
entry:
  call void @llvm.memcpy.p0.p0.i64(ptr %dest, ptr %src, i64 %len, i1 false)
  ret void
}
define void @__llvm_memmove_element_unordered_atomic_4(ptr %dest, ptr %src, i64 %len) {
entry:
  call void @llvm.memmove.p0.p0.i64(ptr %dest, ptr %src, i64 %len, i1 false)
  ret void
}
define void @__llvm_memset_element_unordered_atomic_4(ptr %dest, i8 %val, i64 %len) {
entry:
  call void @llvm.memset.p0.i64(ptr %dest, i8 %val, i64 %len, i1 false)
  ret void
}

; ----- positives (ordinary mem: host-checked) -----

define i32 @protected(i32 %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %src = alloca [4 x i32], align 4
  %dst = alloca [4 x i32], align 4
  %p = getelementptr inbounds [4 x i32], ptr %src, i64 0, i64 0
  store i32 %v, ptr %p, align 4
  %p1 = getelementptr inbounds [4 x i32], ptr %src, i64 0, i64 1
  store i32 2, ptr %p1, align 4
  %p2 = getelementptr inbounds [4 x i32], ptr %src, i64 0, i64 2
  store i32 3, ptr %p2, align 4
  %p3 = getelementptr inbounds [4 x i32], ptr %src, i64 0, i64 3
  store i32 4, ptr %p3, align 4
  call void @llvm.memcpy.p0.p0.i64(ptr align 4 %dst, ptr align 4 %src, i64 16, i1 false)
  %d0 = load i32, ptr %dst, align 4
  ret i32 %d0
}

define i32 @protected_memset() noinline optnone {
entry:
  call void @hikari_vmp()
  %buf = alloca [4 x i32], align 4
  call void @llvm.memset.p0.i64(ptr align 4 %buf, i8 7, i64 16, i1 false)
  %v = load i32, ptr %buf, align 4
  ret i32 %v
}

define i32 @protected_memmove(i32 %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %buf = alloca [5 x i8], align 1
  store i32 %v, ptr %buf, align 1
  %after = getelementptr inbounds i8, ptr %buf, i64 1
  call void @llvm.memmove.p0.p0.i64(ptr align 1 %after, ptr align 1 %buf, i64 4, i1 false)
  %out = load i32, ptr %after, align 1
  ret i32 %out
}

define i32 @protected_memcpy_inline(i32 %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %src = alloca i32, align 4
  %dst = alloca i32, align 4
  store i32 %v, ptr %src, align 4
  call void @llvm.memcpy.inline.p0.p0.i64(ptr align 4 %dst, ptr align 4 %src, i64 4, i1 false)
  %out = load i32, ptr %dst, align 4
  ret i32 %out
}

define i32 @protected_atomic_memcpy(i32 %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %src = alloca [4 x i32], align 4
  %dst = alloca [4 x i32], align 4
  store i32 %v, ptr %src, align 4
  call void @llvm.memcpy.element.unordered.atomic.p0.p0.i64(ptr align 4 %dst, ptr align 4 %src, i64 16, i32 4)
  %out = load i32, ptr %dst, align 4
  ret i32 %out
}

define i32 @protected_atomic_memmove(i32 %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %buf = alloca [5 x i32], align 4
  store i32 %v, ptr %buf, align 4
  %p1 = getelementptr inbounds [5 x i32], ptr %buf, i64 0, i64 1
  call void @llvm.memmove.element.unordered.atomic.p0.p0.i64(ptr align 4 %p1, ptr align 4 %buf, i64 16, i32 4)
  %out = load i32, ptr %p1, align 4
  ret i32 %out
}

define i32 @protected_atomic_memset() noinline optnone {
entry:
  call void @hikari_vmp()
  %buf = alloca [4 x i32], align 4
  call void @llvm.memset.element.unordered.atomic.p0.i64(ptr align 4 %buf, i8 9, i64 16, i32 4)
  %out = load i32, ptr %buf, align 4
  ret i32 %out
}

; ----- negatives -----

define void @unsupported_memcpy_malformed(ptr %d, ptr %s) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.memcpy.p0.p0.i64(ptr %d, ptr %s, i64 4, i1 false) noreturn
  ret void
}


define void @unsupported_memcpy_musttail(ptr %d, ptr %s, i64 %n, i1 %v) noinline optnone {
entry:
  call void @hikari_vmp()
  musttail call void @llvm.memcpy.p0.p0.i64(ptr %d, ptr %s, i64 4, i1 false)
  ret void
}

define void @unsupported_memcpy_bundle(ptr %d, ptr %s) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.memcpy.p0.p0.i64(ptr %d, ptr %s, i64 4, i1 false) [ "deopt"(i32 0) ]
  ret void
}

define void @unsupported_memcpy_fastcc(ptr %d, ptr %s) noinline optnone {
entry:
  call void @hikari_vmp()
  call fastcc void @llvm.memcpy.p0.p0.i64(ptr %d, ptr %s, i64 4, i1 false)
  ret void
}



define void @unsupported_memset_fastcc(ptr %d) noinline optnone {
entry:
  call void @hikari_vmp()
  call fastcc void @llvm.memset.p0.i64(ptr %d, i8 0, i64 4, i1 false)
  ret void
}



define void @unsupported_atomic_memmove_fastcc(ptr %d, ptr %s) noinline optnone {
entry:
  call void @hikari_vmp()
  call fastcc void @llvm.memmove.element.unordered.atomic.p0.p0.i64(ptr align 4 %d, ptr align 4 %s, i64 16, i32 4)
  ret void
}


define void @unsupported_as1_arg(ptr addrspace(1) %unused) noinline optnone {
entry:
  call void @hikari_vmp()
  %p = alloca i8, align 1
  call void @llvm.memset.p0.i64(ptr %p, i8 0, i64 1, i1 false)
  ret void
}

define void @unsupported_sret(ptr sret(i32) %p, ptr byval(i32) %q) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @ext_sret_byval(ptr sret(i32) %p, ptr byval(i32) %q)
  ret void
}

define i32 @reference(i32 %v) noinline {
entry:
  %src = alloca [4 x i32], align 4
  %dst = alloca [4 x i32], align 4
  store i32 %v, ptr %src, align 4
  %p1 = getelementptr inbounds [4 x i32], ptr %src, i64 0, i64 1
  store i32 2, ptr %p1, align 4
  %p2 = getelementptr inbounds [4 x i32], ptr %src, i64 0, i64 2
  store i32 3, ptr %p2, align 4
  %p3 = getelementptr inbounds [4 x i32], ptr %src, i64 0, i64 3
  store i32 4, ptr %p3, align 4
  call void @llvm.memcpy.p0.p0.i64(ptr align 4 %dst, ptr align 4 %src, i64 16, i1 false)
  %d0 = load i32, ptr %dst, align 4
  ret i32 %d0
}

define i32 @reference_memset() noinline {
entry:
  %buf = alloca [4 x i32], align 4
  call void @llvm.memset.p0.i64(ptr align 4 %buf, i8 7, i64 16, i1 false)
  %v = load i32, ptr %buf, align 4
  ret i32 %v
}

define i32 @reference_memmove(i32 %v) noinline {
entry:
  %buf = alloca [5 x i8], align 1
  store i32 %v, ptr %buf, align 1
  %after = getelementptr inbounds i8, ptr %buf, i64 1
  call void @llvm.memmove.p0.p0.i64(ptr align 1 %after, ptr align 1 %buf, i64 4, i1 false)
  %out = load i32, ptr %after, align 1
  ret i32 %out
}

define i32 @reference_memcpy_inline(i32 %v) noinline {
entry:
  %src = alloca i32, align 4
  %dst = alloca i32, align 4
  store i32 %v, ptr %src, align 4
  call void @llvm.memcpy.inline.p0.p0.i64(ptr align 4 %dst, ptr align 4 %src, i64 4, i1 false)
  %out = load i32, ptr %dst, align 4
  ret i32 %out
}

define i32 @main() {
entry:
  %e0 = call i32 @reference(i32 42)
  %a0 = call i32 @protected(i32 42)
  %m0 = icmp eq i32 %e0, %a0
  %e1 = call i32 @reference_memset()
  %a1 = call i32 @protected_memset()
  %m1 = icmp eq i32 %e1, %a1
  %e2 = call i32 @reference_memmove(i32 305419896)
  %a2 = call i32 @protected_memmove(i32 305419896)
  %m2 = icmp eq i32 %e2, %a2
  %e3 = call i32 @reference_memcpy_inline(i32 99)
  %a3 = call i32 @protected_memcpy_inline(i32 99)
  %m3 = icmp eq i32 %e3, %a3
  %t0 = and i1 %m0, %m1
  %t1 = and i1 %m2, %m3
  %ok = and i1 %t0, %t1
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_memcpy_malformed: unsupported memcpy
; SKIP-DAG: Skipping VMP on unsupported_memcpy_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_memcpy_bundle: unsupported memcpy
; SKIP-DAG: Skipping VMP on unsupported_memcpy_fastcc: unsupported memcpy
; SKIP-DAG: Skipping VMP on unsupported_memset_fastcc: unsupported memset
; SKIP-DAG: Skipping VMP on unsupported_atomic_memmove_fastcc: unsupported atomic memmove
; SKIP-DAG: Skipping VMP on unsupported_as1_arg: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_sret: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected:
; SKIP-NOT: Skipping VMP on protected_memset:
; SKIP-NOT: Skipping VMP on protected_memmove:
; SKIP-NOT: Skipping VMP on protected_memcpy_inline:
; SKIP-NOT: Skipping VMP on protected_atomic_memcpy:
; SKIP-NOT: Skipping VMP on protected_atomic_memmove:
; SKIP-NOT: Skipping VMP on protected_atomic_memset:

; VIRT: define i32 @protected({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: call void @llvm.memcpy.p0.p0.i64({{.*}}, i1 false)
; VIRT: }
; VIRT: define i32 @protected_memset({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: call void @llvm.memset.p0.i64({{.*}}, i1 false)
; VIRT: }
; VIRT: define i32 @protected_memmove({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: call void @llvm.memmove.p0.p0.i64({{.*}}, i1 false)
; VIRT: }
; VIRT: define i32 @protected_memcpy_inline({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: call void @llvm.memcpy.inline.p0.p0.i64({{.*}}, i64 4, i1 false)
; VIRT: }
; VIRT: define i32 @protected_atomic_memcpy({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: call void @llvm.memcpy.element.unordered.atomic.p0.p0.i64({{.*}}, i32 4)
; VIRT: }
; VIRT: define i32 @protected_atomic_memmove({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: call void @llvm.memmove.element.unordered.atomic.p0.p0.i64({{.*}}, i32 4)
; VIRT: }
; VIRT: define i32 @protected_atomic_memset({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: call void @llvm.memset.element.unordered.atomic.p0.i64({{.*}}, i32 4)
; VIRT: }
; VIRT: define {{.*}} @unsupported_memcpy_malformed({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_memcpy_musttail({{.*}} #[[UNSUPMUST:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call void @llvm.memcpy.p0.p0.i64(
; VIRT: define {{.*}} @unsupported_memcpy_bundle({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_memcpy_fastcc({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_memset_fastcc({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_atomic_memmove_fastcc({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_as1_arg({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_sret({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPMUST]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPMUST]] = { {{.*}}"hikari.vmp.selected"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
