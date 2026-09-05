; Generic llvm.sin/cos/exp/exp2/log/log2/log10 on supported fixed
; f32/f64 vectors (total 1..128).  Replayed via the existing
; CallDescriptor and vector VReg frame.  Scalar transcendentals stay
; on the existing scalar helpers.  Half vectors stay on the last-token
; +fullfp16 half-vector math path and are not accepted here.  Vector
; pow/powi and other unlisted IDs stay out (f32/f64 vector canonicalize
; is a separate VectorFMul surface; half-vector canonicalize without
; last-token +fullfp16 is a feature skip).  bfloat/fp128,
; scalable, >128-bit, constrained, fastcc, musttail, and bundle stay
; out.  Ordinary tail accepted and replayed as TCK_None.
; Host lli compares only finite, in-domain values.
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
declare <2 x float> @llvm.sin.v2f32(<2 x float>)
declare <4 x float> @llvm.cos.v4f32(<4 x float>)
declare <2 x double> @llvm.exp.v2f64(<2 x double>)
declare <3 x float> @llvm.exp2.v3f32(<3 x float>)
declare <2 x float> @llvm.log.v2f32(<2 x float>)
declare <4 x float> @llvm.log2.v4f32(<4 x float>)
declare <2 x double> @llvm.log10.v2f64(<2 x double>)
declare <4 x float> @llvm.sin.v4f32(<4 x float>)
declare <4 x bfloat> @llvm.sin.v4bf16(<4 x bfloat>)
declare <vscale x 4 x float> @llvm.cos.nxv4f32(<vscale x 4 x float>)
declare <8 x double> @llvm.exp.v8f64(<8 x double>)
declare <4 x float> @llvm.exp2.v4f32(<4 x float>)
declare <4 x float> @llvm.log.v4f32(<4 x float>)
declare <4 x half> @llvm.canonicalize.v4f16(<4 x half>)

declare <4 x half> @llvm.experimental.constrained.pow.v4f16(<4 x half>, <4 x half>, metadata, metadata)

define <2 x float> @reference_sin_v2f32(<2 x float> %a) {
entry:
  %r = call <2 x float> @llvm.sin.v2f32(<2 x float> %a)
  ret <2 x float> %r
}

define <2 x float> @protected_sin_v2f32(<2 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.sin.v2f32(<2 x float> %a)
  ret <2 x float> %r
}

define <4 x float> @reference_cos_v4f32(<4 x float> %a) {
entry:
  %r = call <4 x float> @llvm.cos.v4f32(<4 x float> %a)
  ret <4 x float> %r
}

define <4 x float> @protected_cos_v4f32(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.cos.v4f32(<4 x float> %a)
  ret <4 x float> %r
}

define <2 x double> @reference_exp_v2f64(<2 x double> %a) {
entry:
  %r = call <2 x double> @llvm.exp.v2f64(<2 x double> %a)
  ret <2 x double> %r
}

define <2 x double> @protected_exp_v2f64(<2 x double> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x double> @llvm.exp.v2f64(<2 x double> %a)
  ret <2 x double> %r
}

define <3 x float> @reference_exp2_v3f32(<3 x float> %a) {
entry:
  %r = call <3 x float> @llvm.exp2.v3f32(<3 x float> %a)
  ret <3 x float> %r
}

define <3 x float> @protected_exp2_v3f32(<3 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <3 x float> @llvm.exp2.v3f32(<3 x float> %a)
  ret <3 x float> %r
}

define <2 x float> @reference_log_v2f32(<2 x float> %a) {
entry:
  %r = call <2 x float> @llvm.log.v2f32(<2 x float> %a)
  ret <2 x float> %r
}

define <2 x float> @protected_log_v2f32(<2 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.log.v2f32(<2 x float> %a)
  ret <2 x float> %r
}

define <4 x float> @reference_log2_v4f32(<4 x float> %a) {
entry:
  %r = call <4 x float> @llvm.log2.v4f32(<4 x float> %a)
  ret <4 x float> %r
}

define <4 x float> @protected_log2_v4f32(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.log2.v4f32(<4 x float> %a)
  ret <4 x float> %r
}

define <2 x double> @reference_log10_v2f64(<2 x double> %a) {
entry:
  %r = call <2 x double> @llvm.log10.v2f64(<2 x double> %a)
  ret <2 x double> %r
}

define <2 x double> @protected_log10_v2f64(<2 x double> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x double> @llvm.log10.v2f64(<2 x double> %a)
  ret <2 x double> %r
}

define <4 x float> @reference_fast_sin_v4f32(<4 x float> %a) {
entry:
  %r = call fast <4 x float> @llvm.sin.v4f32(<4 x float> %a)
  ret <4 x float> %r
}

define <4 x float> @protected_fast_sin_v4f32(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fast <4 x float> @llvm.sin.v4f32(<4 x float> %a)
  ret <4 x float> %r
}

; ----- negatives: selected, not virtualized -----

define <4 x bfloat> @unsupported_sin_bfloat(<4 x bfloat> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x bfloat> @llvm.sin.v4bf16(<4 x bfloat> %a)
  ret <4 x bfloat> %r
}

define <vscale x 4 x float> @unsupported_cos_scalable(<vscale x 4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x float> @llvm.cos.nxv4f32(<vscale x 4 x float> %a)
  ret <vscale x 4 x float> %r
}

define <8 x double> @unsupported_exp_wide(<8 x double> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x double> @llvm.exp.v8f64(<8 x double> %a)
  ret <8 x double> %r
}

define <4 x float> @unsupported_exp2_fastcc(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc <4 x float> @llvm.exp2.v4f32(<4 x float> %a)
  ret <4 x float> %r
}

define <4 x float> @unsupported_log_musttail(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call <4 x float> @llvm.log.v4f32(<4 x float> %a)
  ret <4 x float> %r
}

define <4 x float> @unsupported_sin_bundle(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.sin.v4f32(<4 x float> %a) [ "deopt"(i32 0) ]
  ret <4 x float> %r
}

define <4 x half> @unsupported_sin_constrained(<4 x half> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x half> @llvm.experimental.constrained.pow.v4f16(<4 x half> %a, <4 x half> %a, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret <4 x half> %r
}

define <4 x half> @unsupported_canonicalize_unlisted(<4 x half> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x half> @llvm.canonicalize.v4f16(<4 x half> %a)
  ret <4 x half> %r
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
  ; Finite trig / exp inputs.  No NaN, inf, or out-of-domain log args.
  %a2 = fadd <2 x float> <float 5.000000e-01, float 1.000000e+00>, zeroinitializer
  %er0 = call <2 x float> @reference_sin_v2f32(<2 x float> %a2)
  %ar0 = call <2 x float> @protected_sin_v2f32(<2 x float> %a2)
  %er0c = bitcast <2 x float> %er0 to <2 x i32>
  %ar0c = bitcast <2 x float> %ar0 to <2 x i32>
  %er0z = zext <2 x i32> %er0c to <2 x i64>
  %ar0z = zext <2 x i32> %ar0c to <2 x i64>
  %er0w = bitcast <2 x i64> %er0z to <4 x i32>
  %ar0w = bitcast <2 x i64> %ar0z to <4 x i32>
  %em0 = call i32 @vec_i32_mix(<4 x i32> %er0w)
  %am0 = call i32 @vec_i32_mix(<4 x i32> %ar0w)
  %m0 = icmp eq i32 %em0, %am0

  %l2 = fadd <2 x float> <float 1.000000e+00, float 2.000000e+00>, zeroinitializer
  %er0l = call <2 x float> @reference_log_v2f32(<2 x float> %l2)
  %ar0l = call <2 x float> @protected_log_v2f32(<2 x float> %l2)
  %er0lc = bitcast <2 x float> %er0l to <2 x i32>
  %ar0lc = bitcast <2 x float> %ar0l to <2 x i32>
  %er0lz = zext <2 x i32> %er0lc to <2 x i64>
  %ar0lz = zext <2 x i32> %ar0lc to <2 x i64>
  %er0lw = bitcast <2 x i64> %er0lz to <4 x i32>
  %ar0lw = bitcast <2 x i64> %ar0lz to <4 x i32>
  %em0l = call i32 @vec_i32_mix(<4 x i32> %er0lw)
  %am0l = call i32 @vec_i32_mix(<4 x i32> %ar0lw)
  %m0l = icmp eq i32 %em0l, %am0l

  %a4 = fadd <4 x float> <float 5.000000e-01, float 1.000000e+00, float 2.500000e-01, float 7.500000e-01>, zeroinitializer
  %er1 = call <4 x float> @reference_cos_v4f32(<4 x float> %a4)
  %ar1 = call <4 x float> @protected_cos_v4f32(<4 x float> %a4)
  %er1c = bitcast <4 x float> %er1 to <4 x i32>
  %ar1c = bitcast <4 x float> %ar1 to <4 x i32>
  %em1 = call i32 @vec_i32_mix(<4 x i32> %er1c)
  %am1 = call i32 @vec_i32_mix(<4 x i32> %ar1c)
  %m1 = icmp eq i32 %em1, %am1

  %l4 = fadd <4 x float> <float 1.000000e+00, float 2.000000e+00, float 4.000000e+00, float 8.000000e+00>, zeroinitializer
  %er1l = call <4 x float> @reference_log2_v4f32(<4 x float> %l4)
  %ar1l = call <4 x float> @protected_log2_v4f32(<4 x float> %l4)
  %er1lc = bitcast <4 x float> %er1l to <4 x i32>
  %ar1lc = bitcast <4 x float> %ar1l to <4 x i32>
  %em1l = call i32 @vec_i32_mix(<4 x i32> %er1lc)
  %am1l = call i32 @vec_i32_mix(<4 x i32> %ar1lc)
  %m1l = icmp eq i32 %em1l, %am1l

  %er1f = call <4 x float> @reference_fast_sin_v4f32(<4 x float> %a4)
  %ar1f = call <4 x float> @protected_fast_sin_v4f32(<4 x float> %a4)
  %er1fc = bitcast <4 x float> %er1f to <4 x i32>
  %ar1fc = bitcast <4 x float> %ar1f to <4 x i32>
  %em1f = call i32 @vec_i32_mix(<4 x i32> %er1fc)
  %am1f = call i32 @vec_i32_mix(<4 x i32> %ar1fc)
  %m1f = icmp eq i32 %em1f, %am1f

  %ad = fadd <2 x double> <double 0.000000e+00, double 1.000000e+00>, zeroinitializer
  %er2 = call <2 x double> @reference_exp_v2f64(<2 x double> %ad)
  %ar2 = call <2 x double> @protected_exp_v2f64(<2 x double> %ad)
  %er2c = bitcast <2 x double> %er2 to <4 x i32>
  %ar2c = bitcast <2 x double> %ar2 to <4 x i32>
  %em2 = call i32 @vec_i32_mix(<4 x i32> %er2c)
  %am2 = call i32 @vec_i32_mix(<4 x i32> %ar2c)
  %m2 = icmp eq i32 %em2, %am2

  %ld = fadd <2 x double> <double 1.000000e+00, double 1.000000e+01>, zeroinitializer
  %er2l = call <2 x double> @reference_log10_v2f64(<2 x double> %ld)
  %ar2l = call <2 x double> @protected_log10_v2f64(<2 x double> %ld)
  %er2lc = bitcast <2 x double> %er2l to <4 x i32>
  %ar2lc = bitcast <2 x double> %ar2l to <4 x i32>
  %em2l = call i32 @vec_i32_mix(<4 x i32> %er2lc)
  %am2l = call i32 @vec_i32_mix(<4 x i32> %ar2lc)
  %m2l = icmp eq i32 %em2l, %am2l

  %a3 = fadd <3 x float> <float 0.000000e+00, float 1.000000e+00, float 2.000000e+00>, zeroinitializer
  %er3 = call <3 x float> @reference_exp2_v3f32(<3 x float> %a3)
  %ar3 = call <3 x float> @protected_exp2_v3f32(<3 x float> %a3)
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

  %t0 = and i1 %m0, %m0l
  %t1 = and i1 %m1, %m1l
  %t2 = and i1 %m1f, %m2
  %t3 = and i1 %m2l, %m3
  %t4 = and i1 %t0, %t1
  %t5 = and i1 %t2, %t3
  %ok = and i1 %t4, %t5
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_sin_bfloat: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_cos_scalable: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_exp_wide: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_exp2_fastcc: unsupported exp2
; SKIP-DAG: Skipping VMP on unsupported_log_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_sin_bundle: unsupported sin
; SKIP-DAG: Skipping VMP on unsupported_sin_constrained: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_canonicalize_unlisted: unsupported target feature
; SKIP-NOT: Skipping VMP on protected_sin_v2f32:
; SKIP-NOT: Skipping VMP on protected_cos_v4f32:
; SKIP-NOT: Skipping VMP on protected_exp_v2f64:
; SKIP-NOT: Skipping VMP on protected_exp2_v3f32:
; SKIP-NOT: Skipping VMP on protected_log_v2f32:
; SKIP-NOT: Skipping VMP on protected_log2_v4f32:
; SKIP-NOT: Skipping VMP on protected_log10_v2f64:
; SKIP-NOT: Skipping VMP on protected_fast_sin_v4f32:

; VIRT: define <2 x float> @protected_sin_v2f32({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x float> @llvm.sin.v2f32(
; VIRT: define <4 x float> @protected_cos_v4f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x float> @llvm.cos.v4f32(
; VIRT: define <2 x double> @protected_exp_v2f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x double> @llvm.exp.v2f64(
; VIRT: define <3 x float> @protected_exp2_v3f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <3 x float> @llvm.exp2.v3f32(
; VIRT: define <2 x float> @protected_log_v2f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x float> @llvm.log.v2f32(
; VIRT: define <4 x float> @protected_log2_v4f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x float> @llvm.log2.v4f32(
; VIRT: define <2 x double> @protected_log10_v2f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x double> @llvm.log10.v2f64(
; VIRT: define <4 x float> @protected_fast_sin_v4f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call fast <4 x float> @llvm.sin.v4f32(
; VIRT: define {{.*}} @unsupported_sin_bfloat({{.*}} #[[UNSUP_RET:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cos_scalable({{.*}} #[[UNSUP_SC:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_exp_wide({{.*}} #[[UNSUP_W:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_exp2_fastcc({{.*}} #[[UNSUPATTR:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_log_musttail({{.*}} #[[UNSUP_MT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call <4 x float> @llvm.log.v4f32(
; VIRT: define {{.*}} @unsupported_sin_bundle({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call <4 x float> @llvm.sin.v4f32({{.*}}[ "deopt"(i32 0) ]
; VIRT: define {{.*}} @unsupported_sin_constrained({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_canonicalize_unlisted({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_MT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_RET]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_SC]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_W]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
