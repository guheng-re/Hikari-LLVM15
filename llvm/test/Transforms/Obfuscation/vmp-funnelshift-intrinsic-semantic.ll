; RUN: opt -S -verify-each -aesSeed=61 -passes='default<O0>' %s -o %t.o0.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=61 -passes='default<O2>' %s -o %t.o2.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: FileCheck %s < %t.o0.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare i32 @llvm.fshl.i32(i32, i32, i32)
declare i32 @llvm.fshr.i32(i32, i32, i32)

define i32 @reference(i32 %x) {
entry:
  %y = xor i32 %x, -1
  %left = call i32 @llvm.fshl.i32(i32 %x, i32 %y, i32 7)
  %right = call i32 @llvm.fshr.i32(i32 %x, i32 %y, i32 11)
  ; Counts 32 and 33 exercise i32 modulo-width reduction (32→0, 33→1).
  %wrap32 = call i32 @llvm.fshl.i32(i32 %x, i32 %y, i32 32)
  %wrap33 = call i32 @llvm.fshr.i32(i32 %x, i32 %y, i32 33)
  %mix0 = xor i32 %left, %right
  %mix1 = xor i32 %wrap32, %wrap33
  %result = xor i32 %mix0, %mix1
  ret i32 %result
}

define i32 @protected(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %y = xor i32 %x, -1
  %left = call i32 @llvm.fshl.i32(i32 %x, i32 %y, i32 7)
  %right = call i32 @llvm.fshr.i32(i32 %x, i32 %y, i32 11)
  %wrap32 = call i32 @llvm.fshl.i32(i32 %x, i32 %y, i32 32)
  %wrap33 = call i32 @llvm.fshr.i32(i32 %x, i32 %y, i32 33)
  %mix0 = xor i32 %left, %right
  %mix1 = xor i32 %wrap32, %wrap33
  %result = xor i32 %mix0, %mix1
  ret i32 %result
}

define i32 @main() {
entry:
  %expected = call i32 @reference(i32 305419896)
  %actual = call i32 @protected(i32 305419896)
  %match = icmp eq i32 %expected, %actual
  %code = select i1 %match, i32 0, i32 1
  ret i32 %code
}

; CHECK-LABEL: define i32 @protected(
; Counts 32/33 land in entry-block integer register initializers.
; CHECK-DAG: store volatile i64 32,
; CHECK-DAG: store volatile i64 33,
; CHECK: vmp.dispatch:
; CHECK-DAG: call i32 @llvm.fshl.i32(
; CHECK-DAG: call i32 @llvm.fshr.i32(
; CHECK: "hikari.vmp.virtualized"
