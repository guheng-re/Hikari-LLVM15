; Scalar llvm.ptrmask.p0.i64 via normal Call path (AS0 ptr + i64 mask VRegs).
; No dedicated VM opcode.  i32 mask form remains unsupported.
;
; RUN: opt -S -verify-each -aesSeed=153 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.ll -o %t.o0.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=153 -passes='default<O2>' %s -o %t.o2.ll
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.ll -o %t.o2.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare ptr @llvm.ptrmask.p0.i64(ptr, i64)
declare ptr @llvm.ptrmask.p0.i32(ptr, i32)

; align 8 alloca: ptrmask with -8 yields same aligned address; store/load i32.
define i32 @reference_ptrmask(i32 %val) {
entry:
  %buf = alloca i32, align 8
  %p = call ptr @llvm.ptrmask.p0.i64(ptr %buf, i64 -8)
  store i32 %val, ptr %p, align 4
  %out = load i32, ptr %p, align 4
  ret i32 %out
}

define i32 @protected_ptrmask(i32 %val) noinline optnone {
entry:
  call void @hikari_vmp()
  %buf = alloca i32, align 8
  %p = call ptr @llvm.ptrmask.p0.i64(ptr %buf, i64 -8)
  store i32 %val, ptr %p, align 4
  %out = load i32, ptr %p, align 4
  ret i32 %out
}

; i32 mask width must remain unsupported (whitelist is strictly i64).
define i32 @unsupported_ptrmask_i32(i32 %val) noinline optnone {
entry:
  call void @hikari_vmp()
  %buf = alloca i32, align 8
  %p = call ptr @llvm.ptrmask.p0.i32(ptr %buf, i32 -8)
  store i32 %val, ptr %p, align 4
  %out = load i32, ptr %p, align 4
  ret i32 %out
}

define i32 @main() {
entry:
  %e0 = call i32 @reference_ptrmask(i32 42)
  %a0 = call i32 @protected_ptrmask(i32 42)
  %e1 = call i32 @reference_ptrmask(i32 -7)
  %a1 = call i32 @protected_ptrmask(i32 -7)
  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %e1, %a1
  %ok = and i1 %m0, %m1
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with: 153
; SKIP-DAG: Skipping VMP on unsupported_ptrmask_i32: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_ptrmask:

; VIRT: define i32 @protected_ptrmask({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call ptr @llvm.ptrmask.p0.i64(
; VIRT: define i32 @unsupported_ptrmask_i32({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call ptr @llvm.ptrmask.p0.i32(
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected" }
