; RUN: opt -S -verify-each -aesSeed=53 -passes='default<O0>' %s -o %t.o0.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=53 -passes='default<O2>' %s -o %t.o2.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: FileCheck %s < %t.o0.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare i8 @llvm.sshl.sat.i8(i8, i8)
declare i8 @llvm.ushl.sat.i8(i8, i8)

; Covers signed/unsigned saturating left shifts: no-sat, +sat, and -sat to i8 min.
define i32 @reference(i32 %unused) {
entry:
  %sshl0 = call i8 @llvm.sshl.sat.i8(i8 4, i8 2)    ; 16, no sat
  %sshl1 = call i8 @llvm.sshl.sat.i8(i8 4, i8 5)    ; +sat to 127
  %sshl2 = call i8 @llvm.sshl.sat.i8(i8 -4, i8 5)   ; -sat to -128
  %ushl0 = call i8 @llvm.ushl.sat.i8(i8 4, i8 2)    ; 16, no sat
  %ushl1 = call i8 @llvm.ushl.sat.i8(i8 4, i8 6)    ; u-sat to 255
  %sshl0.z = zext i8 %sshl0 to i32
  %sshl1.z = zext i8 %sshl1 to i32
  %sshl2.s = sext i8 %sshl2 to i32
  %ushl0.z = zext i8 %ushl0 to i32
  %ushl1.z = zext i8 %ushl1 to i32
  %mix0 = xor i32 %sshl0.z, %sshl1.z
  %mix1 = xor i32 %ushl0.z, %ushl1.z
  %mix2 = xor i32 %mix0, %mix1
  %result = xor i32 %mix2, %sshl2.s
  ret i32 %result
}

define i32 @protected(i32 %unused) noinline optnone {
entry:
  call void @hikari_vmp()
  %sshl0 = call i8 @llvm.sshl.sat.i8(i8 4, i8 2)
  %sshl1 = call i8 @llvm.sshl.sat.i8(i8 4, i8 5)
  %sshl2 = call i8 @llvm.sshl.sat.i8(i8 -4, i8 5)
  %ushl0 = call i8 @llvm.ushl.sat.i8(i8 4, i8 2)
  %ushl1 = call i8 @llvm.ushl.sat.i8(i8 4, i8 6)
  %sshl0.z = zext i8 %sshl0 to i32
  %sshl1.z = zext i8 %sshl1 to i32
  %sshl2.s = sext i8 %sshl2 to i32
  %ushl0.z = zext i8 %ushl0 to i32
  %ushl1.z = zext i8 %ushl1 to i32
  %mix0 = xor i32 %sshl0.z, %sshl1.z
  %mix1 = xor i32 %ushl0.z, %ushl1.z
  %mix2 = xor i32 %mix0, %mix1
  %result = xor i32 %mix2, %sshl2.s
  ret i32 %result
}

define i32 @main() {
entry:
  %expected = call i32 @reference(i32 0)
  %actual = call i32 @protected(i32 0)
  %match = icmp eq i32 %expected, %actual
  %code = select i1 %match, i32 0, i32 1
  ret i32 %code
}

; CHECK-LABEL: define i32 @protected(
; CHECK: vmp.dispatch:
; CHECK-DAG: call i8 @llvm.sshl.sat.i8(
; CHECK-DAG: call i8 @llvm.ushl.sat.i8(
; CHECK: "hikari.vmp.virtualized"
