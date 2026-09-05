; RUN: opt -S -verify-each -aesSeed=67 -passes='default<O0>' %s -o %t.o0.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=67 -passes='default<O2>' %s -o %t.o2.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: FileCheck %s < %t.o0.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare i8 @llvm.smul.fix.sat.i8(i8, i8, i32 immarg)
declare i8 @llvm.umul.fix.sat.i8(i8, i8, i32 immarg)
declare i8 @llvm.sdiv.fix.sat.i8(i8, i8, i32 immarg)
declare i8 @llvm.udiv.fix.sat.i8(i8, i8, i32 immarg)

; All four saturating fixed-point ops, scale 0 and non-zero scale 4.
; Mix results so wrong scale/saturation changes the compared value.
define i32 @reference(i8 %a, i8 %b) {
entry:
  %sm0 = call i8 @llvm.smul.fix.sat.i8(i8 %a, i8 %b, i32 0)
  %um0 = call i8 @llvm.umul.fix.sat.i8(i8 %a, i8 %b, i32 0)
  %sd0 = call i8 @llvm.sdiv.fix.sat.i8(i8 %a, i8 %b, i32 0)
  %ud0 = call i8 @llvm.udiv.fix.sat.i8(i8 %a, i8 %b, i32 0)
  %sm4 = call i8 @llvm.smul.fix.sat.i8(i8 %a, i8 %b, i32 4)
  %um4 = call i8 @llvm.umul.fix.sat.i8(i8 %a, i8 %b, i32 4)
  %sd4 = call i8 @llvm.sdiv.fix.sat.i8(i8 %a, i8 %b, i32 4)
  %ud4 = call i8 @llvm.udiv.fix.sat.i8(i8 %a, i8 %b, i32 4)
  %sm0.z = zext i8 %sm0 to i32
  %um0.z = zext i8 %um0 to i32
  %sd0.s = sext i8 %sd0 to i32
  %ud0.z = zext i8 %ud0 to i32
  %sm4.s = sext i8 %sm4 to i32
  %um4.z = zext i8 %um4 to i32
  %sd4.s = sext i8 %sd4 to i32
  %ud4.z = zext i8 %ud4 to i32
  %m0 = xor i32 %sm0.z, %um0.z
  %m1 = xor i32 %sd0.s, %ud0.z
  %m2 = xor i32 %sm4.s, %um4.z
  %m3 = xor i32 %sd4.s, %ud4.z
  %m01 = xor i32 %m0, %m1
  %m23 = xor i32 %m2, %m3
  %result = xor i32 %m01, %m23
  ret i32 %result
}

define i32 @protected(i8 %a, i8 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %sm0 = call i8 @llvm.smul.fix.sat.i8(i8 %a, i8 %b, i32 0)
  %um0 = call i8 @llvm.umul.fix.sat.i8(i8 %a, i8 %b, i32 0)
  %sd0 = call i8 @llvm.sdiv.fix.sat.i8(i8 %a, i8 %b, i32 0)
  %ud0 = call i8 @llvm.udiv.fix.sat.i8(i8 %a, i8 %b, i32 0)
  %sm4 = call i8 @llvm.smul.fix.sat.i8(i8 %a, i8 %b, i32 4)
  %um4 = call i8 @llvm.umul.fix.sat.i8(i8 %a, i8 %b, i32 4)
  %sd4 = call i8 @llvm.sdiv.fix.sat.i8(i8 %a, i8 %b, i32 4)
  %ud4 = call i8 @llvm.udiv.fix.sat.i8(i8 %a, i8 %b, i32 4)
  %sm0.z = zext i8 %sm0 to i32
  %um0.z = zext i8 %um0 to i32
  %sd0.s = sext i8 %sd0 to i32
  %ud0.z = zext i8 %ud0 to i32
  %sm4.s = sext i8 %sm4 to i32
  %um4.z = zext i8 %um4 to i32
  %sd4.s = sext i8 %sd4 to i32
  %ud4.z = zext i8 %ud4 to i32
  %m0 = xor i32 %sm0.z, %um0.z
  %m1 = xor i32 %sd0.s, %ud0.z
  %m2 = xor i32 %sm4.s, %um4.z
  %m3 = xor i32 %sd4.s, %ud4.z
  %m01 = xor i32 %m0, %m1
  %m23 = xor i32 %m2, %m3
  %result = xor i32 %m01, %m23
  ret i32 %result
}

define i32 @main() {
entry:
  ; In-range (no saturation): 6*7 and 6/7 at scale 0/4.
  %e0 = call i32 @reference(i8 6, i8 7)
  %a0 = call i32 @protected(i8 6, i8 7)
  ; Signed overflow sat: 100*100 → +127; also exercises sdiv/udiv with same pair.
  %e1 = call i32 @reference(i8 100, i8 100)
  %a1 = call i32 @protected(i8 100, i8 100)
  ; Negative * positive: smul.fix.sat saturates toward -128; udiv sees unsigned bits.
  %e2 = call i32 @reference(i8 -100, i8 3)
  %a2 = call i32 @protected(i8 -100, i8 3)
  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %e1, %a1
  %m2 = icmp eq i32 %e2, %a2
  %t0 = and i1 %m0, %m1
  %ok = and i1 %t0, %m2
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; CHECK-LABEL: define i32 @protected(
; CHECK: vmp.dispatch:
; CHECK-DAG: call i8 @llvm.smul.fix.sat.i8({{.*}}, i32 0)
; CHECK-DAG: call i8 @llvm.umul.fix.sat.i8({{.*}}, i32 0)
; CHECK-DAG: call i8 @llvm.sdiv.fix.sat.i8({{.*}}, i32 0)
; CHECK-DAG: call i8 @llvm.udiv.fix.sat.i8({{.*}}, i32 0)
; CHECK-DAG: call i8 @llvm.smul.fix.sat.i8({{.*}}, i32 4)
; CHECK-DAG: call i8 @llvm.umul.fix.sat.i8({{.*}}, i32 4)
; CHECK-DAG: call i8 @llvm.sdiv.fix.sat.i8({{.*}}, i32 4)
; CHECK-DAG: call i8 @llvm.udiv.fix.sat.i8({{.*}}, i32 4)
; CHECK: "hikari.vmp.virtualized"
