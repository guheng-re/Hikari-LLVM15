; llvm.memmove.element.unordered.atomic via normal Call path (AS0, strictly
; positive constant length multiple of elementsize, explicit align >= elementsize,
; i32 elementsize immarg).  Overlapping dest-after-src exercises memmove semantics.
; Dynamic / zero length remain unsupported.  Host lli needs the compiler-rt-style
; libcall for element size 4.
;
; RUN: opt -S -verify-each -aesSeed=139 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.ll -o %t.o0.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=139 -passes='default<O2>' %s -o %t.o2.ll
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.ll -o %t.o2.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare void @llvm.memmove.element.unordered.atomic.p0.p0.i64(ptr nocapture writeonly, ptr nocapture readonly, i64, i32 immarg)
declare void @llvm.memmove.p0.p0.i64(ptr nocapture writeonly, ptr nocapture readonly, i64, i1 immarg)

; Host/runtime stub used when the intrinsic is lowered to a libcall.
define void @__llvm_memmove_element_unordered_atomic_4(ptr %dest, ptr %src, i64 %len) {
entry:
  call void @llvm.memmove.p0.p0.i64(ptr %dest, ptr %src, i64 %len, i1 false)
  ret void
}

; [5 x i32] buffer: init words 0..4, then memmove(buf+1, buf, 16) overlapping
; dest-after-source; return mixed words so naive forward memcpy would mismatch.
define i32 @reference_atomic_memmove(i32 %a, i32 %b, i32 %c, i32 %d, i32 %e) {
entry:
  %buf = alloca [5 x i32], align 4
  %p0 = getelementptr inbounds [5 x i32], ptr %buf, i64 0, i64 0
  store i32 %a, ptr %p0, align 4
  %p1 = getelementptr inbounds [5 x i32], ptr %buf, i64 0, i64 1
  store i32 %b, ptr %p1, align 4
  %p2 = getelementptr inbounds [5 x i32], ptr %buf, i64 0, i64 2
  store i32 %c, ptr %p2, align 4
  %p3 = getelementptr inbounds [5 x i32], ptr %buf, i64 0, i64 3
  store i32 %d, ptr %p3, align 4
  %p4 = getelementptr inbounds [5 x i32], ptr %buf, i64 0, i64 4
  store i32 %e, ptr %p4, align 4
  ; dest = index 1, src = index 0, length 16 (4 elements), elementsize 4
  call void @llvm.memmove.element.unordered.atomic.p0.p0.i64(ptr align 4 %p1, ptr align 4 %p0, i64 16, i32 4)
  %w0 = load i32, ptr %p0, align 4
  %w1 = load i32, ptr %p1, align 4
  %w2 = load i32, ptr %p2, align 4
  %w3 = load i32, ptr %p3, align 4
  %w4 = load i32, ptr %p4, align 4
  %t0 = add i32 %w0, %w1
  %t1 = add i32 %w2, %w3
  %t2 = add i32 %t0, %t1
  %out = add i32 %t2, %w4
  ret i32 %out
}

define i32 @protected_atomic_memmove(i32 %a, i32 %b, i32 %c, i32 %d, i32 %e) noinline optnone {
entry:
  call void @hikari_vmp()
  %buf = alloca [5 x i32], align 4
  %p0 = getelementptr inbounds [5 x i32], ptr %buf, i64 0, i64 0
  store i32 %a, ptr %p0, align 4
  %p1 = getelementptr inbounds [5 x i32], ptr %buf, i64 0, i64 1
  store i32 %b, ptr %p1, align 4
  %p2 = getelementptr inbounds [5 x i32], ptr %buf, i64 0, i64 2
  store i32 %c, ptr %p2, align 4
  %p3 = getelementptr inbounds [5 x i32], ptr %buf, i64 0, i64 3
  store i32 %d, ptr %p3, align 4
  %p4 = getelementptr inbounds [5 x i32], ptr %buf, i64 0, i64 4
  store i32 %e, ptr %p4, align 4
  call void @llvm.memmove.element.unordered.atomic.p0.p0.i64(ptr align 4 %p1, ptr align 4 %p0, i64 16, i32 4)
  %w0 = load i32, ptr %p0, align 4
  %w1 = load i32, ptr %p1, align 4
  %w2 = load i32, ptr %p2, align 4
  %w3 = load i32, ptr %p3, align 4
  %w4 = load i32, ptr %p4, align 4
  %t0 = add i32 %w0, %w1
  %t1 = add i32 %w2, %w3
  %t2 = add i32 %t0, %t1
  %out = add i32 %t2, %w4
  ret i32 %out
}

; Dynamic length must remain unsupported.
define i32 @unsupported_dynamic_atomic_memmove(i32 %a, i64 %len) noinline optnone {
entry:
  call void @hikari_vmp()
  %src = alloca i32, align 4
  %dst = alloca i32, align 4
  store i32 %a, ptr %src, align 4
  call void @llvm.memmove.element.unordered.atomic.p0.p0.i64(ptr align 4 %dst, ptr align 4 %src, i64 %len, i32 4)
  %v = load i32, ptr %dst, align 4
  ret i32 %v
}

; Zero length must remain unsupported (strictly positive length only).
define i32 @unsupported_zero_len_atomic_memmove(i32 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %src = alloca i32, align 4
  %dst = alloca i32, align 4
  store i32 %a, ptr %src, align 4
  call void @llvm.memmove.element.unordered.atomic.p0.p0.i64(ptr align 4 %dst, ptr align 4 %src, i64 0, i32 4)
  %v = load i32, ptr %dst, align 4
  ret i32 %v
}

define i32 @main() {
entry:
  %e0 = call i32 @reference_atomic_memmove(i32 1, i32 2, i32 3, i32 4, i32 5)
  %a0 = call i32 @protected_atomic_memmove(i32 1, i32 2, i32 3, i32 4, i32 5)
  %e1 = call i32 @reference_atomic_memmove(i32 10, i32 20, i32 30, i32 40, i32 50)
  %a1 = call i32 @protected_atomic_memmove(i32 10, i32 20, i32 30, i32 40, i32 50)
  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %e1, %a1
  %ok = and i1 %m0, %m1
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with: 139
; SKIP-DAG: Skipping VMP on unsupported_dynamic_atomic_memmove: unsupported atomic memmove
; SKIP-DAG: Skipping VMP on unsupported_zero_len_atomic_memmove: unsupported atomic memmove
; SKIP-NOT: Skipping VMP on protected_atomic_memmove:

; VIRT: define i32 @protected_atomic_memmove({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; Elementsize ImmArg stays a true constant; original atomic memmove is re-emitted.
; VIRT: call void @llvm.memmove.element.unordered.atomic.p0.p0.i64({{.*}}, i32 4)
; VIRT: define i32 @unsupported_dynamic_atomic_memmove({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call void @llvm.memmove.element.unordered.atomic.p0.p0.i64({{.*}}, i64 %{{.*}}, i32 4)
; VIRT: define i32 @unsupported_zero_len_atomic_memmove({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call void @llvm.memmove.element.unordered.atomic.p0.p0.i64({{.*}}, i64 0, i32 4)
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected" }
