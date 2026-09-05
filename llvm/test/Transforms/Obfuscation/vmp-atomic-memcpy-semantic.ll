; llvm.memcpy.element.unordered.atomic via normal Call path (AS0, strictly
; positive constant length multiple of elementsize, explicit align >= elementsize,
; i32 elementsize immarg).  Dynamic / zero / negative length remain unsupported.
; (Align < elementsize is rejected by LLVM verifier before VMP; eligibility still
; checks explicit align >= elementsize.)  Host lli needs the compiler-rt-style
; libcall for element size 4.
;
; RUN: opt -S -verify-each -aesSeed=137 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.ll -o %t.o0.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=137 -passes='default<O2>' %s -o %t.o2.ll
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.ll -o %t.o2.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare void @llvm.memcpy.element.unordered.atomic.p0.p0.i64(ptr nocapture writeonly, ptr nocapture readonly, i64, i32 immarg)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg)

; Host/runtime stub used when the intrinsic is lowered to a libcall.
define void @__llvm_memcpy_element_unordered_atomic_4(ptr %dest, ptr %src, i64 %len) {
entry:
  call void @llvm.memcpy.p0.p0.i64(ptr %dest, ptr %src, i64 %len, i1 false)
  ret void
}

; Entry-static alloca src/dst: write i32 pattern, atomic memcpy length 16 elementsize 4.
define i32 @reference_atomic_memcpy(i32 %a, i32 %b, i32 %c, i32 %d) {
entry:
  %src = alloca [4 x i32], align 4
  %dst = alloca [4 x i32], align 4
  %s0 = getelementptr inbounds [4 x i32], ptr %src, i64 0, i64 0
  store i32 %a, ptr %s0, align 4
  %s1 = getelementptr inbounds [4 x i32], ptr %src, i64 0, i64 1
  store i32 %b, ptr %s1, align 4
  %s2 = getelementptr inbounds [4 x i32], ptr %src, i64 0, i64 2
  store i32 %c, ptr %s2, align 4
  %s3 = getelementptr inbounds [4 x i32], ptr %src, i64 0, i64 3
  store i32 %d, ptr %s3, align 4
  call void @llvm.memcpy.element.unordered.atomic.p0.p0.i64(ptr align 4 %dst, ptr align 4 %src, i64 16, i32 4)
  %d0 = load i32, ptr %dst, align 4
  %d1p = getelementptr inbounds [4 x i32], ptr %dst, i64 0, i64 1
  %d1 = load i32, ptr %d1p, align 4
  %d2p = getelementptr inbounds [4 x i32], ptr %dst, i64 0, i64 2
  %d2 = load i32, ptr %d2p, align 4
  %d3p = getelementptr inbounds [4 x i32], ptr %dst, i64 0, i64 3
  %d3 = load i32, ptr %d3p, align 4
  %t0 = add i32 %d0, %d1
  %t1 = add i32 %d2, %d3
  %out = add i32 %t0, %t1
  ret i32 %out
}

define i32 @protected_atomic_memcpy(i32 %a, i32 %b, i32 %c, i32 %d) noinline optnone {
entry:
  call void @hikari_vmp()
  %src = alloca [4 x i32], align 4
  %dst = alloca [4 x i32], align 4
  %s0 = getelementptr inbounds [4 x i32], ptr %src, i64 0, i64 0
  store i32 %a, ptr %s0, align 4
  %s1 = getelementptr inbounds [4 x i32], ptr %src, i64 0, i64 1
  store i32 %b, ptr %s1, align 4
  %s2 = getelementptr inbounds [4 x i32], ptr %src, i64 0, i64 2
  store i32 %c, ptr %s2, align 4
  %s3 = getelementptr inbounds [4 x i32], ptr %src, i64 0, i64 3
  store i32 %d, ptr %s3, align 4
  call void @llvm.memcpy.element.unordered.atomic.p0.p0.i64(ptr align 4 %dst, ptr align 4 %src, i64 16, i32 4)
  %d0 = load i32, ptr %dst, align 4
  %d1p = getelementptr inbounds [4 x i32], ptr %dst, i64 0, i64 1
  %d1 = load i32, ptr %d1p, align 4
  %d2p = getelementptr inbounds [4 x i32], ptr %dst, i64 0, i64 2
  %d2 = load i32, ptr %d2p, align 4
  %d3p = getelementptr inbounds [4 x i32], ptr %dst, i64 0, i64 3
  %d3 = load i32, ptr %d3p, align 4
  %t0 = add i32 %d0, %d1
  %t1 = add i32 %d2, %d3
  %out = add i32 %t0, %t1
  ret i32 %out
}

; Dynamic length must remain unsupported (constant length only).
; noinline optnone keeps the call alive under O2 so FileCheck stays stable.
define i32 @unsupported_dynamic_atomic_memcpy(i32 %a, i64 %len) noinline optnone {
entry:
  call void @hikari_vmp()
  %src = alloca i32, align 4
  %dst = alloca i32, align 4
  store i32 %a, ptr %src, align 4
  call void @llvm.memcpy.element.unordered.atomic.p0.p0.i64(ptr align 4 %dst, ptr align 4 %src, i64 %len, i32 4)
  %v = load i32, ptr %dst, align 4
  ret i32 %v
}

; Literal negative length must remain unsupported.
define i32 @unsupported_negative_len_atomic_memcpy(i32 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %src = alloca i32, align 4
  %dst = alloca i32, align 4
  store i32 %a, ptr %src, align 4
  call void @llvm.memcpy.element.unordered.atomic.p0.p0.i64(ptr align 4 %dst, ptr align 4 %src, i64 -4, i32 4)
  %v = load i32, ptr %dst, align 4
  ret i32 %v
}

; Zero length must remain unsupported (strictly positive length only).
define i32 @unsupported_zero_len_atomic_memcpy(i32 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %src = alloca i32, align 4
  %dst = alloca i32, align 4
  store i32 %a, ptr %src, align 4
  call void @llvm.memcpy.element.unordered.atomic.p0.p0.i64(ptr align 4 %dst, ptr align 4 %src, i64 0, i32 4)
  %v = load i32, ptr %dst, align 4
  ret i32 %v
}

define i32 @main() {
entry:
  %e0 = call i32 @reference_atomic_memcpy(i32 1, i32 2, i32 3, i32 4)
  %a0 = call i32 @protected_atomic_memcpy(i32 1, i32 2, i32 3, i32 4)
  %e1 = call i32 @reference_atomic_memcpy(i32 10, i32 20, i32 30, i32 40)
  %a1 = call i32 @protected_atomic_memcpy(i32 10, i32 20, i32 30, i32 40)
  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %e1, %a1
  %ok = and i1 %m0, %m1
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with: 137
; SKIP-DAG: Skipping VMP on unsupported_dynamic_atomic_memcpy: unsupported atomic memcpy
; SKIP-DAG: Skipping VMP on unsupported_negative_len_atomic_memcpy: unsupported atomic memcpy
; SKIP-DAG: Skipping VMP on unsupported_zero_len_atomic_memcpy: unsupported atomic memcpy
; SKIP-NOT: Skipping VMP on protected_atomic_memcpy:

; VIRT: define i32 @protected_atomic_memcpy({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; Elementsize ImmArg stays a true constant; length may materialize via VReg.
; VIRT: call void @llvm.memcpy.element.unordered.atomic.p0.p0.i64({{.*}}, i32 4)
; Skipped probes share selected-only attrs (no virtualized).
; VIRT: define i32 @unsupported_dynamic_atomic_memcpy({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call void @llvm.memcpy.element.unordered.atomic.p0.p0.i64({{.*}}, i64 %{{.*}}, i32 4)
; VIRT: define i32 @unsupported_negative_len_atomic_memcpy({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call void @llvm.memcpy.element.unordered.atomic.p0.p0.i64({{.*}}, i64 -4, i32 4)
; VIRT: define i32 @unsupported_zero_len_atomic_memcpy({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call void @llvm.memcpy.element.unordered.atomic.p0.p0.i64({{.*}}, i64 0, i32 4)
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected" }
