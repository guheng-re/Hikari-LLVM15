; llvm.memset.element.unordered.atomic via normal Call path (AS0 dest, i8 fill,
; strictly positive constant length multiple of elementsize, explicit dest align
; >= elementsize, i32 elementsize immarg).  Dynamic / zero length remain
; unsupported.
;
; Non-power-of-two elementsize (e.g. i32 3) is rejected by the LLVM IR verifier
; ("element size ... must be a power of 2") before VMP runs, so it cannot appear
; in -verify-each tests.  Instead, length not a multiple of a legal elementsize
; (e.g. length 15, elementsize 4) is verifier-legal but fails the eligibility
; multiple-of-elementsize rule.
;
; Host lli needs the compiler-rt-style libcall for element size 4.
;
; RUN: opt -S -verify-each -aesSeed=141 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.ll -o %t.o0.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=141 -passes='default<O2>' %s -o %t.o2.ll
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.ll -o %t.o2.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare void @llvm.memset.element.unordered.atomic.p0.i64(ptr nocapture writeonly, i8, i64, i32 immarg)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)

; Host/runtime stub used when the intrinsic is lowered to a libcall.
define void @__llvm_memset_element_unordered_atomic_4(ptr %dest, i8 %val, i64 %len) {
entry:
  call void @llvm.memset.p0.i64(ptr %dest, i8 %val, i64 %len, i1 false)
  ret void
}

; Entry-static [4 x i32]: atomic memset length 16 elementsize 4 with fill, load words.
define i32 @reference_atomic_memset(i8 %fill) {
entry:
  %buf = alloca [4 x i32], align 4
  call void @llvm.memset.element.unordered.atomic.p0.i64(ptr align 4 %buf, i8 %fill, i64 16, i32 4)
  %w0 = load i32, ptr %buf, align 4
  %p1 = getelementptr inbounds [4 x i32], ptr %buf, i64 0, i64 1
  %w1 = load i32, ptr %p1, align 4
  %p2 = getelementptr inbounds [4 x i32], ptr %buf, i64 0, i64 2
  %w2 = load i32, ptr %p2, align 4
  %p3 = getelementptr inbounds [4 x i32], ptr %buf, i64 0, i64 3
  %w3 = load i32, ptr %p3, align 4
  %t0 = add i32 %w0, %w1
  %t1 = add i32 %w2, %w3
  %out = xor i32 %t0, %t1
  ret i32 %out
}

define i32 @protected_atomic_memset(i8 %fill) noinline optnone {
entry:
  call void @hikari_vmp()
  %buf = alloca [4 x i32], align 4
  call void @llvm.memset.element.unordered.atomic.p0.i64(ptr align 4 %buf, i8 %fill, i64 16, i32 4)
  %w0 = load i32, ptr %buf, align 4
  %p1 = getelementptr inbounds [4 x i32], ptr %buf, i64 0, i64 1
  %w1 = load i32, ptr %p1, align 4
  %p2 = getelementptr inbounds [4 x i32], ptr %buf, i64 0, i64 2
  %w2 = load i32, ptr %p2, align 4
  %p3 = getelementptr inbounds [4 x i32], ptr %buf, i64 0, i64 3
  %w3 = load i32, ptr %p3, align 4
  %t0 = add i32 %w0, %w1
  %t1 = add i32 %w2, %w3
  %out = xor i32 %t0, %t1
  ret i32 %out
}

; Dynamic length must remain unsupported.
define i32 @unsupported_dynamic_atomic_memset(i8 %fill, i64 %len) noinline optnone {
entry:
  call void @hikari_vmp()
  %buf = alloca i32, align 4
  call void @llvm.memset.element.unordered.atomic.p0.i64(ptr align 4 %buf, i8 %fill, i64 %len, i32 4)
  %v = load i32, ptr %buf, align 4
  ret i32 %v
}

; Zero length must remain unsupported (strictly positive length only).
define i32 @unsupported_zero_len_atomic_memset(i8 %fill) noinline optnone {
entry:
  call void @hikari_vmp()
  %buf = alloca i32, align 4
  call void @llvm.memset.element.unordered.atomic.p0.i64(ptr align 4 %buf, i8 %fill, i64 0, i32 4)
  %v = load i32, ptr %buf, align 4
  ret i32 %v
}

; Length not a multiple of elementsize (legal power-of-two elementsize 4) must
; remain unsupported.  (Non-power-of-two elementsize is verifier-invalid.)
define i32 @unsupported_nonmultiple_len_atomic_memset(i8 %fill) noinline optnone {
entry:
  call void @hikari_vmp()
  %buf = alloca [4 x i32], align 4
  call void @llvm.memset.element.unordered.atomic.p0.i64(ptr align 4 %buf, i8 %fill, i64 15, i32 4)
  %v = load i32, ptr %buf, align 4
  ret i32 %v
}

define i32 @main() {
entry:
  %e0 = call i32 @reference_atomic_memset(i8 0)
  %a0 = call i32 @protected_atomic_memset(i8 0)
  %e1 = call i32 @reference_atomic_memset(i8 171)
  %a1 = call i32 @protected_atomic_memset(i8 171)
  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %e1, %a1
  %ok = and i1 %m0, %m1
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with: 141
; SKIP-DAG: Skipping VMP on unsupported_dynamic_atomic_memset: unsupported atomic memset
; SKIP-DAG: Skipping VMP on unsupported_zero_len_atomic_memset: unsupported atomic memset
; SKIP-DAG: Skipping VMP on unsupported_nonmultiple_len_atomic_memset: unsupported atomic memset
; SKIP-NOT: Skipping VMP on protected_atomic_memset:

; VIRT: define i32 @protected_atomic_memset({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; Elementsize ImmArg stays a true constant; original atomic memset is re-emitted.
; VIRT: call void @llvm.memset.element.unordered.atomic.p0.i64({{.*}}, i32 4)
; VIRT: define i32 @unsupported_dynamic_atomic_memset({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call void @llvm.memset.element.unordered.atomic.p0.i64({{.*}}, i64 %{{.*}}, i32 4)
; VIRT: define i32 @unsupported_zero_len_atomic_memset({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call void @llvm.memset.element.unordered.atomic.p0.i64({{.*}}, i64 0, i32 4)
; VIRT: define i32 @unsupported_nonmultiple_len_atomic_memset({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call void @llvm.memset.element.unordered.atomic.p0.i64({{.*}}, i64 15, i32 4)
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected" }
