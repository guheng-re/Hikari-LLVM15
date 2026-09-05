; Lock implicit llvm.memset.inline support via MemSetInst in
; isSupportedMemoryIntrinsic (constant length + isvolatile immargs preserved).
; Volatile memset.inline remains unsupported.
;
; RUN: opt -S -verify-each -aesSeed=135 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.ll -o %t.o0.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=135 -passes='default<O2>' %s -o %t.o2.ll
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.ll -o %t.o2.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare void @llvm.memset.inline.p0.i64(ptr nocapture writeonly, i8, i64 immarg, i1 immarg)

; Entry-static alloca: memset.inline 16 bytes with fill, load words and mix.
define i32 @reference_memset_inline(i8 %fill) {
entry:
  %buf = alloca [4 x i32], align 4
  call void @llvm.memset.inline.p0.i64(ptr align 4 %buf, i8 %fill, i64 16, i1 false)
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

define i32 @protected_memset_inline(i8 %fill) noinline optnone {
entry:
  call void @hikari_vmp()
  %buf = alloca [4 x i32], align 4
  call void @llvm.memset.inline.p0.i64(ptr align 4 %buf, i8 %fill, i64 16, i1 false)
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

; Volatile memset.inline must remain skipped (no virtualized attribute).
define i32 @unsupported_volatile_memset_inline(i8 %fill) {
entry:
  call void @hikari_vmp()
  %buf = alloca i32, align 4
  call void @llvm.memset.inline.p0.i64(ptr align 4 %buf, i8 %fill, i64 4, i1 true)
  %v = load i32, ptr %buf, align 4
  ret i32 %v
}

define i32 @main() {
entry:
  %e0 = call i32 @reference_memset_inline(i8 0)
  %a0 = call i32 @protected_memset_inline(i8 0)
  %e1 = call i32 @reference_memset_inline(i8 171)
  %a1 = call i32 @protected_memset_inline(i8 171)
  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %e1, %a1
  %ok = and i1 %m0, %m1
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with: 135
; SKIP-DAG: Skipping VMP on unsupported_volatile_memset_inline: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_memset_inline:

; VIRT: define i32 @protected_memset_inline({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.memset.inline.p0.i64({{.*}}, i64 16, i1 false)
; VIRT: define i32 @unsupported_volatile_memset_inline({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call void @llvm.memset.inline.p0.i64({{.*}}, i64 4, i1 true)
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected" }
