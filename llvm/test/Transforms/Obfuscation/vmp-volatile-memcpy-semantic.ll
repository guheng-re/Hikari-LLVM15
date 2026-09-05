; Volatile llvm.memcpy / memmove / memset / memcpy.inline via normal Call path
; (constant length, AS0, isvolatile i1 ImmArg true preserved on re-emit).
; No dedicated VM opcode.
;
; RUN: opt -S -verify-each -aesSeed=170 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.ll -o %t.o0.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=170 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.ll -o %t.o2.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg)
declare void @llvm.memmove.p0.p0.i64(ptr nocapture writeonly, ptr nocapture readonly, i64, i1 immarg)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare void @llvm.memcpy.inline.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64 immarg, i1 immarg)

; Entry-static [4 x i32]: store pattern, volatile memcpy 16 bytes, load sum.
define i32 @reference_volatile_memcpy(i32 %a, i32 %b, i32 %c, i32 %d) {
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
  call void @llvm.memcpy.p0.p0.i64(ptr align 4 %dst, ptr align 4 %src, i64 16, i1 true)
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

define i32 @protected_volatile_memcpy(i32 %a, i32 %b, i32 %c, i32 %d) noinline optnone {
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
  call void @llvm.memcpy.p0.p0.i64(ptr align 4 %dst, ptr align 4 %src, i64 16, i1 true)
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

; Overlapping dest-after-src volatile memmove (true memmove, not memcpy).
define i32 @reference_volatile_memmove(i32 %v) {
entry:
  %buf = alloca [8 x i8], align 1
  store i32 %v, ptr %buf, align 1
  %after = getelementptr inbounds i8, ptr %buf, i64 1
  call void @llvm.memmove.p0.p0.i64(ptr align 1 %after, ptr align 1 %buf, i64 4, i1 true)
  %out = load i32, ptr %after, align 1
  ret i32 %out
}

define i32 @protected_volatile_memmove(i32 %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %buf = alloca [8 x i8], align 1
  store i32 %v, ptr %buf, align 1
  %after = getelementptr inbounds i8, ptr %buf, i64 1
  call void @llvm.memmove.p0.p0.i64(ptr align 1 %after, ptr align 1 %buf, i64 4, i1 true)
  %out = load i32, ptr %after, align 1
  ret i32 %out
}

; Entry-static [4 x i32]: volatile memset fill, load first word.
define i32 @reference_volatile_memset(i8 %fill) {
entry:
  %buf = alloca [4 x i32], align 4
  call void @llvm.memset.p0.i64(ptr align 4 %buf, i8 %fill, i64 16, i1 true)
  %out = load i32, ptr %buf, align 4
  ret i32 %out
}

define i32 @protected_volatile_memset(i8 %fill) noinline optnone {
entry:
  call void @hikari_vmp()
  %buf = alloca [4 x i32], align 4
  call void @llvm.memset.p0.i64(ptr align 4 %buf, i8 %fill, i64 16, i1 true)
  %out = load i32, ptr %buf, align 4
  ret i32 %out
}

; Volatile memcpy.inline: length ImmArg constant + isvolatile true re-emitted.
define i32 @reference_volatile_memcpy_inline(i32 %a, i32 %b, i32 %c, i32 %d) {
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
  call void @llvm.memcpy.inline.p0.p0.i64(ptr align 4 %dst, ptr align 4 %src, i64 16, i1 true)
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

define i32 @protected_volatile_memcpy_inline(i32 %a, i32 %b, i32 %c, i32 %d) noinline optnone {
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
  call void @llvm.memcpy.inline.p0.p0.i64(ptr align 4 %dst, ptr align 4 %src, i64 16, i1 true)
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
  %e0 = call i32 @reference_volatile_memcpy(i32 1, i32 2, i32 3, i32 4)
  %a0 = call i32 @protected_volatile_memcpy(i32 1, i32 2, i32 3, i32 4)
  %e1 = call i32 @reference_volatile_memcpy(i32 10, i32 20, i32 30, i32 40)
  %a1 = call i32 @protected_volatile_memcpy(i32 10, i32 20, i32 30, i32 40)
  %e2 = call i32 @reference_volatile_memmove(i32 305419896)
  %a2 = call i32 @protected_volatile_memmove(i32 305419896)
  %e3 = call i32 @reference_volatile_memmove(i32 -7)
  %a3 = call i32 @protected_volatile_memmove(i32 -7)
  %e4 = call i32 @reference_volatile_memset(i8 171)
  %a4 = call i32 @protected_volatile_memset(i8 171)
  %e5 = call i32 @reference_volatile_memset(i8 0)
  %a5 = call i32 @protected_volatile_memset(i8 0)
  %e6 = call i32 @reference_volatile_memcpy_inline(i32 1, i32 2, i32 3, i32 4)
  %a6 = call i32 @protected_volatile_memcpy_inline(i32 1, i32 2, i32 3, i32 4)
  %e7 = call i32 @reference_volatile_memcpy_inline(i32 10, i32 20, i32 30, i32 40)
  %a7 = call i32 @protected_volatile_memcpy_inline(i32 10, i32 20, i32 30, i32 40)
  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %e1, %a1
  %m2 = icmp eq i32 %e2, %a2
  %m3 = icmp eq i32 %e3, %a3
  %m4 = icmp eq i32 %e4, %a4
  %m5 = icmp eq i32 %e5, %a5
  %m6 = icmp eq i32 %e6, %a6
  %m7 = icmp eq i32 %e7, %a7
  %t0 = and i1 %m0, %m1
  %t1 = and i1 %m2, %m3
  %t2 = and i1 %m4, %m5
  %t3 = and i1 %m6, %m7
  %u0 = and i1 %t0, %t1
  %u1 = and i1 %t2, %t3
  %ok = and i1 %u0, %u1
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with: 170
; SKIP-NOT: Skipping VMP on protected_volatile_memcpy:
; SKIP-NOT: Skipping VMP on protected_volatile_memmove:
; SKIP-NOT: Skipping VMP on protected_volatile_memset:
; SKIP-NOT: Skipping VMP on protected_volatile_memcpy_inline:

; VIRT: define i32 @protected_volatile_memcpy({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.memcpy.p0.p0.i64(ptr align 4 %{{.*}}, ptr align 4 %{{.*}}, i64 %{{.*}}, i1 true)
; VIRT: define i32 @protected_volatile_memmove({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.memmove.p0.p0.i64(ptr align 1 %{{.*}}, ptr align 1 %{{.*}}, i64 %{{.*}}, i1 true)
; VIRT: define i32 @protected_volatile_memset({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.memset.p0.i64(ptr align 4 %{{.*}}, i8 %{{.*}}, i64 %{{.*}}, i1 true)
; VIRT: define i32 @protected_volatile_memcpy_inline({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; length ImmArg + isvolatile ImmArg stay true constants on re-emit
; VIRT: call void @llvm.memcpy.inline.p0.p0.i64(ptr align 4 %{{.*}}, ptr align 4 %{{.*}}, i64 16, i1 true)
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
