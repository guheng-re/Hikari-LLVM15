; Scalar i8 llvm.sadd/uadd/ssub/usub.sat via normal Call re-emit path.
; Covers positive/negative saturation, unsigned overflow/underflow, and normal
; non-saturating paths.  Over-wide <8 x i32> sat stays outside the 1..128
; vector sat surface (return-type gate).  Operands are function parameters
; so O2 cannot constant-fold the intrinsics.
;
; RUN: opt -S -verify-each -aesSeed=157 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.ll -o %t.o0.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=157 -passes='default<O2>' %s -o %t.o2.ll
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.ll -o %t.o2.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare i8 @llvm.sadd.sat.i8(i8, i8)
declare i8 @llvm.uadd.sat.i8(i8, i8)
declare i8 @llvm.ssub.sat.i8(i8, i8)
declare i8 @llvm.usub.sat.i8(i8, i8)
declare <8 x i32> @llvm.sadd.sat.v8i32(<8 x i32>, <8 x i32>)

; Pack four i8 results into one i32 for easy differential (low to high bytes).
define i32 @pack4(i8 %a, i8 %b, i8 %c, i8 %d) {
entry:
  %az = zext i8 %a to i32
  %bz = zext i8 %b to i32
  %cz = zext i8 %c to i32
  %dz = zext i8 %d to i32
  %bsh = shl i32 %bz, 8
  %csh = shl i32 %cz, 16
  %dsh = shl i32 %dz, 24
  %t0 = or i32 %az, %bsh
  %t1 = or i32 %csh, %dsh
  %out = or i32 %t0, %t1
  ret i32 %out
}

; Overflow/underflow paths: +sat, -sat, u-overflow, u-underflow.
; Call sites pass (100,100), (-100,100), (200,100), (10,20).
define i32 @reference_sat_edge(i8 %sa, i8 %sb, i8 %ua, i8 %ub, i8 %ss, i8 %st, i8 %us, i8 %ut) {
entry:
  %sadd = call i8 @llvm.sadd.sat.i8(i8 %sa, i8 %sb)
  %ssub = call i8 @llvm.ssub.sat.i8(i8 %ss, i8 %st)
  %uadd = call i8 @llvm.uadd.sat.i8(i8 %ua, i8 %ub)
  %usub = call i8 @llvm.usub.sat.i8(i8 %us, i8 %ut)
  %out = call i32 @pack4(i8 %sadd, i8 %ssub, i8 %uadd, i8 %usub)
  ret i32 %out
}

define i32 @protected_sat_edge(i8 %sa, i8 %sb, i8 %ua, i8 %ub, i8 %ss, i8 %st, i8 %us, i8 %ut) noinline optnone {
entry:
  call void @hikari_vmp()
  %sadd = call i8 @llvm.sadd.sat.i8(i8 %sa, i8 %sb)
  %ssub = call i8 @llvm.ssub.sat.i8(i8 %ss, i8 %st)
  %uadd = call i8 @llvm.uadd.sat.i8(i8 %ua, i8 %ub)
  %usub = call i8 @llvm.usub.sat.i8(i8 %us, i8 %ut)
  %out = call i32 @pack4(i8 %sadd, i8 %ssub, i8 %uadd, i8 %usub)
  ret i32 %out
}

; Normal non-saturating paths for all four.
; Call sites pass (10,20), (50,20), (10,20), (50,20).
define i32 @reference_sat_normal(i8 %sa, i8 %sb, i8 %ua, i8 %ub, i8 %ss, i8 %st, i8 %us, i8 %ut) {
entry:
  %sadd = call i8 @llvm.sadd.sat.i8(i8 %sa, i8 %sb)
  %ssub = call i8 @llvm.ssub.sat.i8(i8 %ss, i8 %st)
  %uadd = call i8 @llvm.uadd.sat.i8(i8 %ua, i8 %ub)
  %usub = call i8 @llvm.usub.sat.i8(i8 %us, i8 %ut)
  %out = call i32 @pack4(i8 %sadd, i8 %ssub, i8 %uadd, i8 %usub)
  ret i32 %out
}

define i32 @protected_sat_normal(i8 %sa, i8 %sb, i8 %ua, i8 %ub, i8 %ss, i8 %st, i8 %us, i8 %ut) noinline optnone {
entry:
  call void @hikari_vmp()
  %sadd = call i8 @llvm.sadd.sat.i8(i8 %sa, i8 %sb)
  %ssub = call i8 @llvm.ssub.sat.i8(i8 %ss, i8 %st)
  %uadd = call i8 @llvm.uadd.sat.i8(i8 %ua, i8 %ub)
  %usub = call i8 @llvm.usub.sat.i8(i8 %us, i8 %ut)
  %out = call i32 @pack4(i8 %sadd, i8 %ssub, i8 %uadd, i8 %usub)
  ret i32 %out
}

; Over-wide same-lane sat stays outside the 1..128 vector sat surface.
define <8 x i32> @unsupported_vector_sat(<8 x i32> %a, <8 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %sadd = call <8 x i32> @llvm.sadd.sat.v8i32(<8 x i32> %a, <8 x i32> %b)
  ret <8 x i32> %sadd
}

define i32 @main() {
entry:
  ; edge: sadd 100+100, ssub -100-100, uadd 200+100, usub 10-20
  %e0 = call i32 @reference_sat_edge(i8 100, i8 100, i8 200, i8 100, i8 -100, i8 100, i8 10, i8 20)
  %a0 = call i32 @protected_sat_edge(i8 100, i8 100, i8 200, i8 100, i8 -100, i8 100, i8 10, i8 20)
  ; normal: 10+20, 50-20, 10+20, 50-20
  %e1 = call i32 @reference_sat_normal(i8 10, i8 20, i8 10, i8 20, i8 50, i8 20, i8 50, i8 20)
  %a1 = call i32 @protected_sat_normal(i8 10, i8 20, i8 10, i8 20, i8 50, i8 20, i8 50, i8 20)
  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %e1, %a1
  %ok = and i1 %m0, %m1
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with: 157
; Vector return is rejected at the return-type gate (stable skip reason).
; SKIP-DAG: Skipping VMP on unsupported_vector_sat: unsupported return type
; SKIP-NOT: Skipping VMP on protected_sat_edge:
; SKIP-NOT: Skipping VMP on protected_sat_normal:

; VIRT: define i32 @protected_sat_edge({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: call i8 @llvm.sadd.sat.i8(
; VIRT-DAG: call i8 @llvm.ssub.sat.i8(
; VIRT-DAG: call i8 @llvm.uadd.sat.i8(
; VIRT-DAG: call i8 @llvm.usub.sat.i8(
; VIRT: define i32 @protected_sat_normal({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: call i8 @llvm.sadd.sat.i8(
; VIRT-DAG: call i8 @llvm.ssub.sat.i8(
; VIRT-DAG: call i8 @llvm.uadd.sat.i8(
; VIRT-DAG: call i8 @llvm.usub.sat.i8(
; VIRT: define <8 x i32> @unsupported_vector_sat({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call <8 x i32> @llvm.sadd.sat.v8i32(
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected" }
