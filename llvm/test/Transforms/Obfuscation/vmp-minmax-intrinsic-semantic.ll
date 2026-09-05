; RUN: opt -S -verify-each -aesSeed=59 -passes='default<O0>' %s -o %t.o0.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=59 -passes='default<O2>' %s -o %t.o2.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: FileCheck %s < %t.o0.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare i8 @llvm.smin.i8(i8, i8)
declare i8 @llvm.smax.i8(i8, i8)
declare i8 @llvm.umin.i8(i8, i8)
declare i8 @llvm.umax.i8(i8, i8)

; Signed bounds (-128/127) and unsigned bounds (0/255) exercise min/max edges.
define i32 @reference(i32 %unused) {
entry:
  %smin = call i8 @llvm.smin.i8(i8 -128, i8 127)
  %smax = call i8 @llvm.smax.i8(i8 -128, i8 127)
  %umin = call i8 @llvm.umin.i8(i8 0, i8 255)
  %umax = call i8 @llvm.umax.i8(i8 0, i8 255)
  %smin.z = sext i8 %smin to i32
  %smax.z = sext i8 %smax to i32
  %umin.z = zext i8 %umin to i32
  %umax.z = zext i8 %umax to i32
  %mix0 = xor i32 %smin.z, %smax.z
  %mix1 = xor i32 %umin.z, %umax.z
  %result = xor i32 %mix0, %mix1
  ret i32 %result
}

define i32 @protected(i32 %unused) noinline optnone {
entry:
  call void @hikari_vmp()
  %smin = call i8 @llvm.smin.i8(i8 -128, i8 127)
  %smax = call i8 @llvm.smax.i8(i8 -128, i8 127)
  %umin = call i8 @llvm.umin.i8(i8 0, i8 255)
  %umax = call i8 @llvm.umax.i8(i8 0, i8 255)
  %smin.z = sext i8 %smin to i32
  %smax.z = sext i8 %smax to i32
  %umin.z = zext i8 %umin to i32
  %umax.z = zext i8 %umax to i32
  %mix0 = xor i32 %smin.z, %smax.z
  %mix1 = xor i32 %umin.z, %umax.z
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
; CHECK-DAG: call i8 @llvm.smin.i8(
; CHECK-DAG: call i8 @llvm.smax.i8(
; CHECK-DAG: call i8 @llvm.umin.i8(
; CHECK-DAG: call i8 @llvm.umax.i8(
; CHECK: "hikari.vmp.virtualized"
