; Generic llvm.ceil/floor/trunc/round/rint/nearbyint/roundeven,
; llvm.copysign, llvm.pow, and llvm.powi (vector base + i32 exponent)
; on supported fixed f32/f64 vectors (total 1..128).  Replayed via the
; existing CallDescriptor and vector VReg frame.  Scalar rounding /
; copysign / pow stay on the existing scalar helpers.  Half vectors
; stay on the last-token +fullfp16 half-vector math path and are not
; accepted here.  Vector sin/cos/exp/log and other transcendentals
; stay out.  bfloat/fp128, scalable, >128-bit, fastcc, musttail,
; bundle, and non-i32 powi stay out.  Ordinary tail accepted and
; replayed as TCK_None.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.ll > %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.live.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.ll > %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.live.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.s7.ll > %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.s7.live.ll > %t.o0.s7.host.ll
; RUN: lli -force-interpreter %t.o0.s7.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.s7.ll > %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.s7.live.ll > %t.o2.s7.host.ll
; RUN: lli -force-interpreter %t.o2.s7.host.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare <2 x float> @llvm.ceil.v2f32(<2 x float>)
declare <4 x float> @llvm.floor.v4f32(<4 x float>)
declare <2 x double> @llvm.trunc.v2f64(<2 x double>)
declare <3 x float> @llvm.round.v3f32(<3 x float>)
declare <2 x float> @llvm.rint.v2f32(<2 x float>)
declare <2 x float> @llvm.nearbyint.v2f32(<2 x float>)
declare <4 x float> @llvm.roundeven.v4f32(<4 x float>)
declare <4 x float> @llvm.ceil.v4f32(<4 x float>)
declare <2 x float> @llvm.copysign.v2f32(<2 x float>, <2 x float>)
declare <2 x float> @llvm.pow.v2f32(<2 x float>, <2 x float>)
declare <4 x float> @llvm.powi.v4f32.i32(<4 x float>, i32)
declare <4 x bfloat> @llvm.ceil.v4bf16(<4 x bfloat>)
declare <vscale x 4 x float> @llvm.floor.nxv4f32(<vscale x 4 x float>)
declare <8 x double> @llvm.trunc.v8f64(<8 x double>)
declare <4 x float> @llvm.copysign.v4f32(<4 x float>, <4 x float>)
declare <4 x float> @llvm.pow.v4f32(<4 x float>, <4 x float>)
declare <4 x float> @llvm.powi.v4f32.i64(<4 x float>, i64)

define <2 x float> @reference_ceil_v2f32(<2 x float> %a) {
entry:
  %r = call <2 x float> @llvm.ceil.v2f32(<2 x float> %a)
  ret <2 x float> %r
}

define <2 x float> @protected_ceil_v2f32(<2 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.ceil.v2f32(<2 x float> %a)
  ret <2 x float> %r
}

define <4 x float> @reference_floor_v4f32(<4 x float> %a) {
entry:
  %r = call <4 x float> @llvm.floor.v4f32(<4 x float> %a)
  ret <4 x float> %r
}

define <4 x float> @protected_floor_v4f32(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.floor.v4f32(<4 x float> %a)
  ret <4 x float> %r
}

define <2 x double> @reference_trunc_v2f64(<2 x double> %a) {
entry:
  %r = call <2 x double> @llvm.trunc.v2f64(<2 x double> %a)
  ret <2 x double> %r
}

define <2 x double> @protected_trunc_v2f64(<2 x double> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x double> @llvm.trunc.v2f64(<2 x double> %a)
  ret <2 x double> %r
}

define <3 x float> @reference_round_v3f32(<3 x float> %a) {
entry:
  %r = call <3 x float> @llvm.round.v3f32(<3 x float> %a)
  ret <3 x float> %r
}

define <3 x float> @protected_round_v3f32(<3 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <3 x float> @llvm.round.v3f32(<3 x float> %a)
  ret <3 x float> %r
}

define <2 x float> @reference_rint_v2f32(<2 x float> %a) {
entry:
  %r = call <2 x float> @llvm.rint.v2f32(<2 x float> %a)
  ret <2 x float> %r
}

define <2 x float> @protected_rint_v2f32(<2 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.rint.v2f32(<2 x float> %a)
  ret <2 x float> %r
}

define <2 x float> @reference_nearbyint_v2f32(<2 x float> %a) {
entry:
  %r = call <2 x float> @llvm.nearbyint.v2f32(<2 x float> %a)
  ret <2 x float> %r
}

define <2 x float> @protected_nearbyint_v2f32(<2 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.nearbyint.v2f32(<2 x float> %a)
  ret <2 x float> %r
}

define <4 x float> @reference_roundeven_v4f32(<4 x float> %a) {
entry:
  %r = call <4 x float> @llvm.roundeven.v4f32(<4 x float> %a)
  ret <4 x float> %r
}

define <4 x float> @protected_roundeven_v4f32(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.roundeven.v4f32(<4 x float> %a)
  ret <4 x float> %r
}

define <2 x float> @reference_copysign_v2f32(<2 x float> %a, <2 x float> %b) {
entry:
  %r = call <2 x float> @llvm.copysign.v2f32(<2 x float> %a, <2 x float> %b)
  ret <2 x float> %r
}

define <2 x float> @protected_copysign_v2f32(<2 x float> %a, <2 x float> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.copysign.v2f32(<2 x float> %a, <2 x float> %b)
  ret <2 x float> %r
}

define <2 x float> @reference_pow_v2f32(<2 x float> %a, <2 x float> %b) {
entry:
  %r = call <2 x float> @llvm.pow.v2f32(<2 x float> %a, <2 x float> %b)
  ret <2 x float> %r
}

define <2 x float> @protected_pow_v2f32(<2 x float> %a, <2 x float> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.pow.v2f32(<2 x float> %a, <2 x float> %b)
  ret <2 x float> %r
}

define <4 x float> @reference_powi_v4f32(<4 x float> %a, i32 %e) {
entry:
  %r = call <4 x float> @llvm.powi.v4f32.i32(<4 x float> %a, i32 %e)
  ret <4 x float> %r
}

define <4 x float> @protected_powi_v4f32(<4 x float> %a, i32 %e) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.powi.v4f32.i32(<4 x float> %a, i32 %e)
  ret <4 x float> %r
}

define <4 x float> @reference_fast_ceil_v4f32(<4 x float> %a) {
entry:
  %r = call fast <4 x float> @llvm.ceil.v4f32(<4 x float> %a)
  ret <4 x float> %r
}

define <4 x float> @protected_fast_ceil_v4f32(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fast <4 x float> @llvm.ceil.v4f32(<4 x float> %a)
  ret <4 x float> %r
}

; ----- negatives: selected, not virtualized -----

define <4 x bfloat> @unsupported_round_bfloat(<4 x bfloat> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x bfloat> @llvm.ceil.v4bf16(<4 x bfloat> %a)
  ret <4 x bfloat> %r
}

define <vscale x 4 x float> @unsupported_ceil_scalable(<vscale x 4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x float> @llvm.floor.nxv4f32(<vscale x 4 x float> %a)
  ret <vscale x 4 x float> %r
}

define <8 x double> @unsupported_floor_wide(<8 x double> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x double> @llvm.trunc.v8f64(<8 x double> %a)
  ret <8 x double> %r
}

define <4 x float> @unsupported_copysign_fastcc(<4 x float> %a, <4 x float> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc <4 x float> @llvm.copysign.v4f32(<4 x float> %a, <4 x float> %b)
  ret <4 x float> %r
}

define <4 x float> @unsupported_pow_musttail(<4 x float> %a, <4 x float> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call <4 x float> @llvm.pow.v4f32(<4 x float> %a, <4 x float> %b)
  ret <4 x float> %r
}

define <4 x float> @unsupported_pow_bundle(<4 x float> %a, <4 x float> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.pow.v4f32(<4 x float> %a, <4 x float> %b) [ "deopt"(i32 0) ]
  ret <4 x float> %r
}

define <4 x float> @unsupported_powi_i64(<4 x float> %a, i64 %e) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.powi.v4f32.i64(<4 x float> %a, i64 %e)
  ret <4 x float> %r
}

define i32 @vec_i32_mix(<4 x i32> %v) {
entry:
  %e0 = extractelement <4 x i32> %v, i32 0
  %e1 = extractelement <4 x i32> %v, i32 1
  %e2 = extractelement <4 x i32> %v, i32 2
  %e3 = extractelement <4 x i32> %v, i32 3
  %x0 = xor i32 %e0, %e1
  %x1 = xor i32 %e2, %e3
  %r = xor i32 %x0, %x1
  ret i32 %r
}

define i32 @main() {
entry:
  %a2 = fadd <2 x float> <float 1.250000e+00, float -2.250000e+00>, zeroinitializer
  %er0 = call <2 x float> @reference_ceil_v2f32(<2 x float> %a2)
  %ar0 = call <2 x float> @protected_ceil_v2f32(<2 x float> %a2)
  %er0c = bitcast <2 x float> %er0 to <2 x i32>
  %ar0c = bitcast <2 x float> %ar0 to <2 x i32>
  %er0z = zext <2 x i32> %er0c to <2 x i64>
  %ar0z = zext <2 x i32> %ar0c to <2 x i64>
  %er0w = bitcast <2 x i64> %er0z to <4 x i32>
  %ar0w = bitcast <2 x i64> %ar0z to <4 x i32>
  %em0 = call i32 @vec_i32_mix(<4 x i32> %er0w)
  %am0 = call i32 @vec_i32_mix(<4 x i32> %ar0w)
  %m0 = icmp eq i32 %em0, %am0

  %er0r = call <2 x float> @reference_rint_v2f32(<2 x float> %a2)
  %ar0r = call <2 x float> @protected_rint_v2f32(<2 x float> %a2)
  %er0rc = bitcast <2 x float> %er0r to <2 x i32>
  %ar0rc = bitcast <2 x float> %ar0r to <2 x i32>
  %er0rz = zext <2 x i32> %er0rc to <2 x i64>
  %ar0rz = zext <2 x i32> %ar0rc to <2 x i64>
  %er0rw = bitcast <2 x i64> %er0rz to <4 x i32>
  %ar0rw = bitcast <2 x i64> %ar0rz to <4 x i32>
  %em0r = call i32 @vec_i32_mix(<4 x i32> %er0rw)
  %am0r = call i32 @vec_i32_mix(<4 x i32> %ar0rw)
  %m0r = icmp eq i32 %em0r, %am0r

  %er0n = call <2 x float> @reference_nearbyint_v2f32(<2 x float> %a2)
  %ar0n = call <2 x float> @protected_nearbyint_v2f32(<2 x float> %a2)
  %er0nc = bitcast <2 x float> %er0n to <2 x i32>
  %ar0nc = bitcast <2 x float> %ar0n to <2 x i32>
  %er0nz = zext <2 x i32> %er0nc to <2 x i64>
  %ar0nz = zext <2 x i32> %ar0nc to <2 x i64>
  %er0nw = bitcast <2 x i64> %er0nz to <4 x i32>
  %ar0nw = bitcast <2 x i64> %ar0nz to <4 x i32>
  %em0n = call i32 @vec_i32_mix(<4 x i32> %er0nw)
  %am0n = call i32 @vec_i32_mix(<4 x i32> %ar0nw)
  %m0n = icmp eq i32 %em0n, %am0n

  %b2 = fadd <2 x float> <float -3.000000e+00, float 4.000000e+00>, zeroinitializer
  %er0csg = call <2 x float> @reference_copysign_v2f32(<2 x float> %a2, <2 x float> %b2)
  %ar0csg = call <2 x float> @protected_copysign_v2f32(<2 x float> %a2, <2 x float> %b2)
  %er0cc = bitcast <2 x float> %er0csg to <2 x i32>
  %ar0cc = bitcast <2 x float> %ar0csg to <2 x i32>
  %er0cz = zext <2 x i32> %er0cc to <2 x i64>
  %ar0cz = zext <2 x i32> %ar0cc to <2 x i64>
  %er0cw = bitcast <2 x i64> %er0cz to <4 x i32>
  %ar0cw = bitcast <2 x i64> %ar0cz to <4 x i32>
  %em0c = call i32 @vec_i32_mix(<4 x i32> %er0cw)
  %am0c = call i32 @vec_i32_mix(<4 x i32> %ar0cw)
  %m0c = icmp eq i32 %em0c, %am0c

  %pbase = fadd <2 x float> <float 2.000000e+00, float 4.000000e+00>, zeroinitializer
  %pexp = fadd <2 x float> <float 3.000000e+00, float 2.000000e+00>, zeroinitializer
  %er0p = call <2 x float> @reference_pow_v2f32(<2 x float> %pbase, <2 x float> %pexp)
  %ar0p = call <2 x float> @protected_pow_v2f32(<2 x float> %pbase, <2 x float> %pexp)
  %er0pc = bitcast <2 x float> %er0p to <2 x i32>
  %ar0pc = bitcast <2 x float> %ar0p to <2 x i32>
  %er0pz = zext <2 x i32> %er0pc to <2 x i64>
  %ar0pz = zext <2 x i32> %ar0pc to <2 x i64>
  %er0pw = bitcast <2 x i64> %er0pz to <4 x i32>
  %ar0pw = bitcast <2 x i64> %ar0pz to <4 x i32>
  %em0p = call i32 @vec_i32_mix(<4 x i32> %er0pw)
  %am0p = call i32 @vec_i32_mix(<4 x i32> %ar0pw)
  %m0p = icmp eq i32 %em0p, %am0p

  %a4 = fadd <4 x float> <float 1.250000e+00, float -1.750000e+00, float 2.000000e+00, float 0.250000e+00>, zeroinitializer
  %er1 = call <4 x float> @reference_floor_v4f32(<4 x float> %a4)
  %ar1 = call <4 x float> @protected_floor_v4f32(<4 x float> %a4)
  %er1c = bitcast <4 x float> %er1 to <4 x i32>
  %ar1c = bitcast <4 x float> %ar1 to <4 x i32>
  %em1 = call i32 @vec_i32_mix(<4 x i32> %er1c)
  %am1 = call i32 @vec_i32_mix(<4 x i32> %ar1c)
  %m1 = icmp eq i32 %em1, %am1

  %er1e = call <4 x float> @reference_roundeven_v4f32(<4 x float> %a4)
  %ar1e = call <4 x float> @protected_roundeven_v4f32(<4 x float> %a4)
  %er1ec = bitcast <4 x float> %er1e to <4 x i32>
  %ar1ec = bitcast <4 x float> %ar1e to <4 x i32>
  %em1e = call i32 @vec_i32_mix(<4 x i32> %er1ec)
  %am1e = call i32 @vec_i32_mix(<4 x i32> %ar1ec)
  %m1e = icmp eq i32 %em1e, %am1e

  %er1f = call <4 x float> @reference_fast_ceil_v4f32(<4 x float> %a4)
  %ar1f = call <4 x float> @protected_fast_ceil_v4f32(<4 x float> %a4)
  %er1fc = bitcast <4 x float> %er1f to <4 x i32>
  %ar1fc = bitcast <4 x float> %ar1f to <4 x i32>
  %em1f = call i32 @vec_i32_mix(<4 x i32> %er1fc)
  %am1f = call i32 @vec_i32_mix(<4 x i32> %ar1fc)
  %m1f = icmp eq i32 %em1f, %am1f

  %p4 = fadd <4 x float> <float 2.000000e+00, float 2.000000e+00, float 4.000000e+00, float 8.000000e+00>, zeroinitializer
  %er1i = call <4 x float> @reference_powi_v4f32(<4 x float> %p4, i32 3)
  %ar1i = call <4 x float> @protected_powi_v4f32(<4 x float> %p4, i32 3)
  %er1ic = bitcast <4 x float> %er1i to <4 x i32>
  %ar1ic = bitcast <4 x float> %ar1i to <4 x i32>
  %em1i = call i32 @vec_i32_mix(<4 x i32> %er1ic)
  %am1i = call i32 @vec_i32_mix(<4 x i32> %ar1ic)
  %m1i = icmp eq i32 %em1i, %am1i

  %ad = fadd <2 x double> <double 1.750000e+00, double -2.250000e+00>, zeroinitializer
  %er2 = call <2 x double> @reference_trunc_v2f64(<2 x double> %ad)
  %ar2 = call <2 x double> @protected_trunc_v2f64(<2 x double> %ad)
  %er2c = bitcast <2 x double> %er2 to <4 x i32>
  %ar2c = bitcast <2 x double> %ar2 to <4 x i32>
  %em2 = call i32 @vec_i32_mix(<4 x i32> %er2c)
  %am2 = call i32 @vec_i32_mix(<4 x i32> %ar2c)
  %m2 = icmp eq i32 %em2, %am2

  %a3 = fadd <3 x float> <float 1.250000e+00, float -2.250000e+00, float 0.500000e+00>, zeroinitializer
  %er3 = call <3 x float> @reference_round_v3f32(<3 x float> %a3)
  %ar3 = call <3 x float> @protected_round_v3f32(<3 x float> %a3)
  %e30 = extractelement <3 x float> %er3, i32 0
  %e31 = extractelement <3 x float> %er3, i32 1
  %e32 = extractelement <3 x float> %er3, i32 2
  %a30 = extractelement <3 x float> %ar3, i32 0
  %a31 = extractelement <3 x float> %ar3, i32 1
  %a32 = extractelement <3 x float> %ar3, i32 2
  %e30i = bitcast float %e30 to i32
  %e31i = bitcast float %e31 to i32
  %e32i = bitcast float %e32 to i32
  %a30i = bitcast float %a30 to i32
  %a31i = bitcast float %a31 to i32
  %a32i = bitcast float %a32 to i32
  %ex = xor i32 %e30i, %e31i
  %ey = xor i32 %ex, %e32i
  %ax = xor i32 %a30i, %a31i
  %ay = xor i32 %ax, %a32i
  %m3 = icmp eq i32 %ey, %ay

  %t0 = and i1 %m0, %m0r
  %t1 = and i1 %m0n, %m0c
  %t2 = and i1 %m0p, %m1
  %t3 = and i1 %m1e, %m1f
  %t4 = and i1 %m1i, %m2
  %t5 = and i1 %t0, %t1
  %t6 = and i1 %t2, %t3
  %t7 = and i1 %t4, %m3
  %t8 = and i1 %t5, %t6
  %ok = and i1 %t8, %t7
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_round_bfloat: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_ceil_scalable: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_floor_wide: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_copysign_fastcc: unsupported copysign
; SKIP-DAG: Skipping VMP on unsupported_pow_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_pow_bundle: unsupported pow
; SKIP-DAG: Skipping VMP on unsupported_powi_i64: unsupported powi
; SKIP-NOT: Skipping VMP on protected_ceil_v2f32:
; SKIP-NOT: Skipping VMP on protected_floor_v4f32:
; SKIP-NOT: Skipping VMP on protected_trunc_v2f64:
; SKIP-NOT: Skipping VMP on protected_round_v3f32:
; SKIP-NOT: Skipping VMP on protected_rint_v2f32:
; SKIP-NOT: Skipping VMP on protected_nearbyint_v2f32:
; SKIP-NOT: Skipping VMP on protected_roundeven_v4f32:
; SKIP-NOT: Skipping VMP on protected_copysign_v2f32:
; SKIP-NOT: Skipping VMP on protected_pow_v2f32:
; SKIP-NOT: Skipping VMP on protected_powi_v4f32:
; SKIP-NOT: Skipping VMP on protected_fast_ceil_v4f32:

; VIRT: define <2 x float> @protected_ceil_v2f32({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x float> @llvm.ceil.v2f32(
; VIRT: define <4 x float> @protected_floor_v4f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x float> @llvm.floor.v4f32(
; VIRT: define <2 x double> @protected_trunc_v2f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x double> @llvm.trunc.v2f64(
; VIRT: define <3 x float> @protected_round_v3f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <3 x float> @llvm.round.v3f32(
; VIRT: define <2 x float> @protected_rint_v2f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x float> @llvm.rint.v2f32(
; VIRT: define <2 x float> @protected_nearbyint_v2f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x float> @llvm.nearbyint.v2f32(
; VIRT: define <4 x float> @protected_roundeven_v4f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x float> @llvm.roundeven.v4f32(
; VIRT: define <2 x float> @protected_copysign_v2f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x float> @llvm.copysign.v2f32(
; VIRT: define <2 x float> @protected_pow_v2f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x float> @llvm.pow.v2f32(
; VIRT: define <4 x float> @protected_powi_v4f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x float> @llvm.powi.v4f32.i32(
; VIRT: define <4 x float> @protected_fast_ceil_v4f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call fast <4 x float> @llvm.ceil.v4f32(
; VIRT: define {{.*}} @unsupported_round_bfloat({{.*}} #[[UNSUP_RET:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ceil_scalable({{.*}} #[[UNSUP_SC:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_floor_wide({{.*}} #[[UNSUP_W:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_copysign_fastcc({{.*}} #[[UNSUPATTR:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_pow_musttail({{.*}} #[[UNSUP_MT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call <4 x float> @llvm.pow.v4f32(
; VIRT: define {{.*}} @unsupported_pow_bundle({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call <4 x float> @llvm.pow.v4f32({{.*}}[ "deopt"(i32 0) ]
; VIRT: define {{.*}} @unsupported_powi_i64({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call <4 x float> @llvm.powi.v4f32.i64(
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_MT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_RET]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_SC]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_W]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
