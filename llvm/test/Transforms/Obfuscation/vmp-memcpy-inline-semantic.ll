; Scalar llvm.memcpy.inline via normal Call path (constant length + isvolatile
; immargs preserved on re-emit).  No dedicated VM opcode.
; Volatile memcpy.inline coverage lives in vmp-volatile-memcpy-semantic.ll.
;
; RUN: opt -S -verify-each -aesSeed=133 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.ll -o %t.o0.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=133 -passes='default<O2>' %s -o %t.o2.ll
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.ll -o %t.o2.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare void @llvm.memcpy.inline.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64 immarg, i1 immarg)

; Entry-static alloca buffers: write i32 pattern, memcpy.inline 16 bytes, read back.
define i32 @reference_memcpy_inline(i32 %a, i32 %b, i32 %c, i32 %d) {
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
  call void @llvm.memcpy.inline.p0.p0.i64(ptr align 4 %dst, ptr align 4 %src, i64 16, i1 false)
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

define i32 @protected_memcpy_inline(i32 %a, i32 %b, i32 %c, i32 %d) noinline optnone {
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
  call void @llvm.memcpy.inline.p0.p0.i64(ptr align 4 %dst, ptr align 4 %src, i64 16, i1 false)
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

define i32 @main() {
entry:
  %e0 = call i32 @reference_memcpy_inline(i32 1, i32 2, i32 3, i32 4)
  %a0 = call i32 @protected_memcpy_inline(i32 1, i32 2, i32 3, i32 4)
  %e1 = call i32 @reference_memcpy_inline(i32 10, i32 20, i32 30, i32 40)
  %a1 = call i32 @protected_memcpy_inline(i32 10, i32 20, i32 30, i32 40)
  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %e1, %a1
  %ok = and i1 %m0, %m1
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with: 133
; SKIP-NOT: Skipping VMP on protected_memcpy_inline:

; VIRT-LABEL: define i32 @protected_memcpy_inline(
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.memcpy.inline.p0.p0.i64({{.*}}, i64 16, i1 false)
; VIRT: attributes{{.*}}"hikari.vmp.virtualized"
