; RUN: opt -S -verify-each -aesSeed=59 -passes='default<O0>' %s -o %t.o0.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=59 -passes='default<O2>' %s -o %t.o2.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: FileCheck %s < %t.o0.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare i8 @llvm.smul.fix.i8(i8, i8, i32 immarg)
declare i8 @llvm.umul.fix.i8(i8, i8, i32 immarg)

; Covers scale=0 (ordinary product) and non-zero scale (true fixed-point shift).
; Results are mixed so incorrect scale handling changes the compared value.
define i32 @reference(i8 %a, i8 %b) {
entry:
  ; scale 0: product without fixed-point right shift.
  %s0 = call i8 @llvm.smul.fix.i8(i8 %a, i8 %b, i32 0)
  %u0 = call i8 @llvm.umul.fix.i8(i8 %a, i8 %b, i32 0)
  ; scale 4: multiply then arithmetic/logical shift toward zero scale.
  %s4 = call i8 @llvm.smul.fix.i8(i8 %a, i8 %b, i32 4)
  %u4 = call i8 @llvm.umul.fix.i8(i8 %a, i8 %b, i32 4)
  %s0.z = zext i8 %s0 to i32
  %u0.z = zext i8 %u0 to i32
  ; Keep sign of smul.fix scale-4 so a negative product is observable.
  %s4.s = sext i8 %s4 to i32
  %u4.z = zext i8 %u4 to i32
  %mix0 = xor i32 %s0.z, %u0.z
  %mix1 = xor i32 %s4.s, %u4.z
  %result = xor i32 %mix0, %mix1
  ret i32 %result
}

define i32 @protected(i8 %a, i8 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %s0 = call i8 @llvm.smul.fix.i8(i8 %a, i8 %b, i32 0)
  %u0 = call i8 @llvm.umul.fix.i8(i8 %a, i8 %b, i32 0)
  %s4 = call i8 @llvm.smul.fix.i8(i8 %a, i8 %b, i32 4)
  %u4 = call i8 @llvm.umul.fix.i8(i8 %a, i8 %b, i32 4)
  %s0.z = zext i8 %s0 to i32
  %u0.z = zext i8 %u0 to i32
  %s4.s = sext i8 %s4 to i32
  %u4.z = zext i8 %u4 to i32
  %mix0 = xor i32 %s0.z, %u0.z
  %mix1 = xor i32 %s4.s, %u4.z
  %result = xor i32 %mix0, %mix1
  ret i32 %result
}

define i32 @main() {
entry:
  ; Positive operands: smul.fix/umul.fix both produce positive scale-4 results.
  %e0 = call i32 @reference(i8 48, i8 5)
  %a0 = call i32 @protected(i8 48, i8 5)
  ; Negative * positive: smul.fix scale-4 yields a negative result; umul.fix is unsigned.
  %e1 = call i32 @reference(i8 -48, i8 5)
  %a1 = call i32 @protected(i8 -48, i8 5)
  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %e1, %a1
  %ok = and i1 %m0, %m1
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; CHECK-LABEL: define i32 @protected(
; CHECK: vmp.dispatch:
; CHECK-DAG: call i8 @llvm.smul.fix.i8({{.*}}, i32 0)
; CHECK-DAG: call i8 @llvm.umul.fix.i8({{.*}}, i32 0)
; CHECK-DAG: call i8 @llvm.smul.fix.i8({{.*}}, i32 4)
; CHECK-DAG: call i8 @llvm.umul.fix.i8({{.*}}, i32 4)
; CHECK: "hikari.vmp.virtualized"
