; RUN: opt -S -verify-each -aesSeed=53 -passes='default<O0>' %s -o %t.o0.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=53 -passes='default<O2>' %s -o %t.o2.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: FileCheck %s < %t.o0.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare i8 @llvm.sadd.sat.i8(i8, i8)
declare i8 @llvm.uadd.sat.i8(i8, i8)
declare i8 @llvm.ssub.sat.i8(i8, i8)
declare i8 @llvm.usub.sat.i8(i8, i8)

; Covers signed positive/negative saturation and unsigned overflow/underflow.
define i32 @reference(i32 %unused) {
entry:
  %sadd = call i8 @llvm.sadd.sat.i8(i8 100, i8 100)   ; +saturate to 127
  %ssub = call i8 @llvm.ssub.sat.i8(i8 -100, i8 100)  ; -saturate to -128
  %uadd = call i8 @llvm.uadd.sat.i8(i8 200, i8 100)   ; u-overflow to 255
  %usub = call i8 @llvm.usub.sat.i8(i8 10, i8 20)     ; u-underflow to 0
  %sadd.z = zext i8 %sadd to i32
  %ssub.z = sext i8 %ssub to i32
  %uadd.z = zext i8 %uadd to i32
  %usub.z = zext i8 %usub to i32
  %mix0 = xor i32 %sadd.z, %ssub.z
  %mix1 = xor i32 %uadd.z, %usub.z
  %result = xor i32 %mix0, %mix1
  ret i32 %result
}

define i32 @protected(i32 %unused) noinline optnone {
entry:
  call void @hikari_vmp()
  %sadd = call i8 @llvm.sadd.sat.i8(i8 100, i8 100)
  %ssub = call i8 @llvm.ssub.sat.i8(i8 -100, i8 100)
  %uadd = call i8 @llvm.uadd.sat.i8(i8 200, i8 100)
  %usub = call i8 @llvm.usub.sat.i8(i8 10, i8 20)
  %sadd.z = zext i8 %sadd to i32
  %ssub.z = sext i8 %ssub to i32
  %uadd.z = zext i8 %uadd to i32
  %usub.z = zext i8 %usub to i32
  %mix0 = xor i32 %sadd.z, %ssub.z
  %mix1 = xor i32 %uadd.z, %usub.z
  %result = xor i32 %mix0, %mix1
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
; CHECK-DAG: call i8 @llvm.sadd.sat.i8(
; CHECK-DAG: call i8 @llvm.ssub.sat.i8(
; CHECK-DAG: call i8 @llvm.uadd.sat.i8(
; CHECK-DAG: call i8 @llvm.usub.sat.i8(
; CHECK: "hikari.vmp.virtualized"
