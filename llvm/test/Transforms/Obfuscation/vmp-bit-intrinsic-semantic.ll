; RUN: opt -S -verify-each -aesSeed=43 -passes='default<O0>' %s -o %t.o0.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=43 -passes='default<O2>' %s -o %t.o2.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: FileCheck %s < %t.o0.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare i32 @llvm.ctpop.i32(i32)
declare i32 @llvm.bswap.i32(i32)
declare i32 @llvm.bitreverse.i32(i32)

define i32 @reference(i32 %x) {
entry:
  %pop = call i32 @llvm.ctpop.i32(i32 %x)
  %swapped = call i32 @llvm.bswap.i32(i32 %x)
  %reversed = call i32 @llvm.bitreverse.i32(i32 %x)
  %mix0 = xor i32 %pop, %swapped
  %result = xor i32 %mix0, %reversed
  ret i32 %result
}

define i32 @protected(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %pop = call i32 @llvm.ctpop.i32(i32 %x)
  %swapped = call i32 @llvm.bswap.i32(i32 %x)
  %reversed = call i32 @llvm.bitreverse.i32(i32 %x)
  %mix0 = xor i32 %pop, %swapped
  %result = xor i32 %mix0, %reversed
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
; CHECK: vmp.dispatch:
; CHECK-DAG: call i32 @llvm.ctpop.i32(
; CHECK-DAG: call i32 @llvm.bswap.i32(
; CHECK-DAG: call i32 @llvm.bitreverse.i32(
; CHECK: "hikari.vmp.virtualized"
