; Scalar llvm.minimum.f32 / llvm.maximum.f32 via normal Call path (float VReg).
; Distinct from minnum/maxnum (NaN / signed-zero ordering).  No dedicated VM
; opcode.  Fast-math minimum/maximum.f32 is VMP-supported (CallDescriptor FMF
; mask restored): reference_fast_minimum_maximum runs natively,
; protected_fast_minimum_maximum is virtualized with the partial nnan ninf
; flag combination and re-emits the exact flags in the VM calls.
; Vector stays rejected (f64 coverage lives in vmp-minimum-maximum-double.ll).
;
; Host x86 lli/JIT cannot select llvm.minimum/maximum.  Do not rewrite those
; intrinsics to minnum/maxnum and do not strip functions for host.  Validate
; with FileCheck + AArch64 object generation only (same IR that VMP produces).
;
; RUN: opt -S -verify-each -aesSeed=174 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.ll -o %t.o0.o
; RUN: opt -S -verify-each -aesSeed=174 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.ll -o %t.o2.o

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare float @llvm.minimum.f32(float, float)
declare float @llvm.maximum.f32(float, float)
declare <2 x float> @llvm.minimum.v2f32(<2 x float>, <2 x float>)

; Bit-pattern i32 inputs: bitcast to float, minimum+maximum, xor bitcasts.
define i32 @reference_minimum_maximum(i32 %a_bits, i32 %b_bits) noinline optnone {
entry:
  %a = bitcast i32 %a_bits to float
  %b = bitcast i32 %b_bits to float
  %mn = call float @llvm.minimum.f32(float %a, float %b)
  %mx = call float @llvm.maximum.f32(float %a, float %b)
  %mn.i = bitcast float %mn to i32
  %mx.i = bitcast float %mx to i32
  %mix = xor i32 %mn.i, %mx.i
  ret i32 %mix
}

define i32 @protected_minimum_maximum(i32 %a_bits, i32 %b_bits) noinline optnone {
entry:
  call void @hikari_vmp()
  %a = bitcast i32 %a_bits to float
  %b = bitcast i32 %b_bits to float
  %mn = call float @llvm.minimum.f32(float %a, float %b)
  %mx = call float @llvm.maximum.f32(float %a, float %b)
  %mn.i = bitcast float %mn to i32
  %mx.i = bitcast float %mx to i32
  %mix = xor i32 %mn.i, %mx.i
  ret i32 %mix
}

; Fast-math minimum/maximum.f32 is VMP-supported (CallDescriptor FMF mask
; restored): same minimum+maximum xor-mix under the partial nnan ninf flags.
define i32 @reference_fast_minimum_maximum(i32 %a_bits, i32 %b_bits) noinline optnone {
entry:
  %a = bitcast i32 %a_bits to float
  %b = bitcast i32 %b_bits to float
  %mn = call nnan ninf float @llvm.minimum.f32(float %a, float %b)
  %mx = call nnan ninf float @llvm.maximum.f32(float %a, float %b)
  %mn.i = bitcast float %mn to i32
  %mx.i = bitcast float %mx to i32
  %mix = xor i32 %mn.i, %mx.i
  ret i32 %mix
}

define i32 @protected_fast_minimum_maximum(i32 %a_bits, i32 %b_bits) noinline optnone {
entry:
  call void @hikari_vmp()
  %a = bitcast i32 %a_bits to float
  %b = bitcast i32 %b_bits to float
  %mn = call nnan ninf float @llvm.minimum.f32(float %a, float %b)
  %mx = call nnan ninf float @llvm.maximum.f32(float %a, float %b)
  %mn.i = bitcast float %mn to i32
  %mx.i = bitcast float %mx to i32
  %mix = xor i32 %mn.i, %mx.i
  ret i32 %mix
}

; Vector llvm.minimum.v2f32 stays rejected.  <2 x float> return fires the
; return-type gate (stable skip) with the native vector call preserved in IR.
define <2 x float> @unsupported_minimum_v2f32(<2 x float> %a, <2 x float> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.minimum.v2f32(<2 x float> %a, <2 x float> %b)
  ret <2 x float> %r
}

define i32 @main() {
entry:
  ; finite: 1.0 and -2.0
  %e0 = call i32 @reference_minimum_maximum(i32 1065353216, i32 -1073741824)
  %a0 = call i32 @protected_minimum_maximum(i32 1065353216, i32 -1073741824)
  ; one quiet NaN (0x7fc01234) and 1.0
  %e1 = call i32 @reference_minimum_maximum(i32 2143294004, i32 1065353216)
  %a1 = call i32 @protected_minimum_maximum(i32 2143294004, i32 1065353216)
  ; both quiet NaN with differing payloads
  %e2 = call i32 @reference_minimum_maximum(i32 2143294004, i32 2143298676)
  %a2 = call i32 @protected_minimum_maximum(i32 2143294004, i32 2143298676)
  ; +0 and -0
  %e3 = call i32 @reference_minimum_maximum(i32 0, i32 -2147483648)
  %a3 = call i32 @protected_minimum_maximum(i32 0, i32 -2147483648)
  ; fast minimum/maximum: 1.0/-2.0 and 3.0/1.5 (finite inputs, nnan ninf)
  %e4 = call i32 @reference_fast_minimum_maximum(i32 1065353216, i32 -1073741824)
  %a4 = call i32 @protected_fast_minimum_maximum(i32 1065353216, i32 -1073741824)
  %e5 = call i32 @reference_fast_minimum_maximum(i32 1077936128, i32 1069547520)
  %a5 = call i32 @protected_fast_minimum_maximum(i32 1077936128, i32 1069547520)
  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %e1, %a1
  %m2 = icmp eq i32 %e2, %a2
  %m3 = icmp eq i32 %e3, %a3
  %m4 = icmp eq i32 %e4, %a4
  %m5 = icmp eq i32 %e5, %a5
  %t0 = and i1 %m0, %m1
  %t1 = and i1 %t0, %m2
  %t2 = and i1 %t1, %m3
  %t3 = and i1 %t2, %m4
  %ok = and i1 %t3, %m5
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with: 174
; SKIP-DAG: Skipping VMP on unsupported_minimum_v2f32: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_minimum_maximum:
; SKIP-NOT: Skipping VMP on protected_fast_minimum_maximum:

; VIRT: define i32 @protected_minimum_maximum({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: call float @llvm.minimum.f32(
; VIRT-DAG: call float @llvm.maximum.f32(
; VIRT: define i32 @protected_fast_minimum_maximum({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: call nnan ninf float @llvm.minimum.f32(
; VIRT-DAG: call nnan ninf float @llvm.maximum.f32(
; VIRT: define <2 x float> @unsupported_minimum_v2f32({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call <2 x float> @llvm.minimum.v2f32(
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
