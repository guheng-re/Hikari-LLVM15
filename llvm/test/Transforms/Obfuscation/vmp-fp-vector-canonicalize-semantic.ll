; Restricted llvm.canonicalize on fixed f32/f64 vectors (total 1..128).
; Eligibility only: the planner lowers each lane to VectorFMul(x, splat
; 1.0) with packVectorVariant FastMathFlags, matching the scalar
; FMul(x, 1.0) expansion.  llvm.canonicalize is never re-emitted
; (AArch64/X86 cannot select it).  Scalar canonicalize and ordinary
; tail semantics are unchanged.  Well-shaped half-vector canonicalize
; without last-token +fullfp16 is a feature skip (separate surface).
;
; reference uses the same vector fmul x, 1.0 expansion.  protected uses
; llvm.canonicalize.  Host lli compares bit patterns for finite values,
; +0, -0, +inf, and a quiet NaN payload.
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
declare <2 x float> @llvm.canonicalize.v2f32(<2 x float>)
declare <2 x double> @llvm.canonicalize.v2f64(<2 x double>)
declare <3 x float> @llvm.canonicalize.v3f32(<3 x float>)
declare <4 x float> @llvm.canonicalize.v4f32(<4 x float>)
declare <4 x half> @llvm.canonicalize.v4f16(<4 x half>)
declare <4 x bfloat> @llvm.canonicalize.v4bf16(<4 x bfloat>)
declare <vscale x 4 x float> @llvm.canonicalize.nxv4f32(<vscale x 4 x float>)
declare <8 x double> @llvm.canonicalize.v8f64(<8 x double>)

declare <4 x half> @llvm.experimental.constrained.pow.v4f16(<4 x half>, <4 x half>, metadata, metadata)

define <2 x float> @reference_canonicalize_v2f32(<2 x float> %a) {
entry:
  %r = fmul <2 x float> %a, <float 1.000000e+00, float 1.000000e+00>
  ret <2 x float> %r
}

define <2 x float> @protected_canonicalize_v2f32(<2 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.canonicalize.v2f32(<2 x float> %a)
  ret <2 x float> %r
}

define <2 x double> @reference_canonicalize_v2f64(<2 x double> %a) {
entry:
  %r = fmul <2 x double> %a, <double 1.000000e+00, double 1.000000e+00>
  ret <2 x double> %r
}

define <2 x double> @protected_canonicalize_v2f64(<2 x double> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x double> @llvm.canonicalize.v2f64(<2 x double> %a)
  ret <2 x double> %r
}

define <3 x float> @reference_canonicalize_v3f32(<3 x float> %a) {
entry:
  %r = fmul <3 x float> %a, <float 1.000000e+00, float 1.000000e+00, float 1.000000e+00>
  ret <3 x float> %r
}

define <3 x float> @protected_canonicalize_v3f32(<3 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <3 x float> @llvm.canonicalize.v3f32(<3 x float> %a)
  ret <3 x float> %r
}

define <4 x float> @reference_fast_canonicalize_v4f32(<4 x float> %a) {
entry:
  %r = fmul fast <4 x float> %a, <float 1.000000e+00, float 1.000000e+00, float 1.000000e+00, float 1.000000e+00>
  ret <4 x float> %r
}

define <4 x float> @protected_fast_canonicalize_v4f32(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fast <4 x float> @llvm.canonicalize.v4f32(<4 x float> %a)
  ret <4 x float> %r
}

; ----- negatives: selected, not virtualized -----

define <4 x half> @unsupported_canonicalize_half(<4 x half> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x half> @llvm.canonicalize.v4f16(<4 x half> %a)
  ret <4 x half> %r
}

define <4 x bfloat> @unsupported_canonicalize_bfloat(<4 x bfloat> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x bfloat> @llvm.canonicalize.v4bf16(<4 x bfloat> %a)
  ret <4 x bfloat> %r
}

define <vscale x 4 x float> @unsupported_canonicalize_scalable(<vscale x 4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x float> @llvm.canonicalize.nxv4f32(<vscale x 4 x float> %a)
  ret <vscale x 4 x float> %r
}

define <8 x double> @unsupported_canonicalize_wide(<8 x double> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x double> @llvm.canonicalize.v8f64(<8 x double> %a)
  ret <8 x double> %r
}

define <4 x float> @unsupported_canonicalize_fastcc(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc <4 x float> @llvm.canonicalize.v4f32(<4 x float> %a)
  ret <4 x float> %r
}

define <4 x float> @unsupported_canonicalize_musttail(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call <4 x float> @llvm.canonicalize.v4f32(<4 x float> %a)
  ret <4 x float> %r
}

define <4 x float> @unsupported_canonicalize_bundle(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.canonicalize.v4f32(<4 x float> %a) [ "deopt"(i32 0) ]
  ret <4 x float> %r
}

; LLVM 15 has no constrained.canonicalize; constrained.fmul is the
; constrained analogue of the fmul x, 1.0 lowering and stays unlisted.
define <4 x half> @unsupported_canonicalize_constrained(<4 x half> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x half> @llvm.experimental.constrained.pow.v4f16(<4 x half> %a, <4 x half> %a, metadata !"round.tonearest", metadata !"fpexcept.ignore")
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
  ; 1.5, -2.5
  %nbits = add <2 x i32> <i32 1069547520, i32 -1071644672>, zeroinitializer
  %norm = bitcast <2 x i32> %nbits to <2 x float>
  %er0 = call <2 x float> @reference_canonicalize_v2f32(<2 x float> %norm)
  %ar0 = call <2 x float> @protected_canonicalize_v2f32(<2 x float> %norm)
  %er0c = bitcast <2 x float> %er0 to <2 x i32>
  %ar0c = bitcast <2 x float> %ar0 to <2 x i32>
  %er0z = zext <2 x i32> %er0c to <2 x i64>
  %ar0z = zext <2 x i32> %ar0c to <2 x i64>
  %er0w = bitcast <2 x i64> %er0z to <4 x i32>
  %ar0w = bitcast <2 x i64> %ar0z to <4 x i32>
  %em0 = call i32 @vec_i32_mix(<4 x i32> %er0w)
  %am0 = call i32 @vec_i32_mix(<4 x i32> %ar0w)
  %m0 = icmp eq i32 %em0, %am0

  ; +0, -0
  %zbits = add <2 x i32> <i32 0, i32 -2147483648>, zeroinitializer
  %zeros = bitcast <2 x i32> %zbits to <2 x float>
  %er0z2 = call <2 x float> @reference_canonicalize_v2f32(<2 x float> %zeros)
  %ar0z2 = call <2 x float> @protected_canonicalize_v2f32(<2 x float> %zeros)
  %er0zc = bitcast <2 x float> %er0z2 to <2 x i32>
  %ar0zc = bitcast <2 x float> %ar0z2 to <2 x i32>
  %er0zz = zext <2 x i32> %er0zc to <2 x i64>
  %ar0zz = zext <2 x i32> %ar0zc to <2 x i64>
  %er0zw = bitcast <2 x i64> %er0zz to <4 x i32>
  %ar0zw = bitcast <2 x i64> %ar0zz to <4 x i32>
  %em0z = call i32 @vec_i32_mix(<4 x i32> %er0zw)
  %am0z = call i32 @vec_i32_mix(<4 x i32> %ar0zw)
  %m0z = icmp eq i32 %em0z, %am0z

  ; +inf, quiet NaN payload 0x7FC01234
  %sbits = add <2 x i32> <i32 2139095040, i32 2143294004>, zeroinitializer
  %spec = bitcast <2 x i32> %sbits to <2 x float>
  %er0s = call <2 x float> @reference_canonicalize_v2f32(<2 x float> %spec)
  %ar0s = call <2 x float> @protected_canonicalize_v2f32(<2 x float> %spec)
  %er0sc = bitcast <2 x float> %er0s to <2 x i32>
  %ar0sc = bitcast <2 x float> %ar0s to <2 x i32>
  %er0sz = zext <2 x i32> %er0sc to <2 x i64>
  %ar0sz = zext <2 x i32> %ar0sc to <2 x i64>
  %er0sw = bitcast <2 x i64> %er0sz to <4 x i32>
  %ar0sw = bitcast <2 x i64> %ar0sz to <4 x i32>
  %em0s = call i32 @vec_i32_mix(<4 x i32> %er0sw)
  %am0s = call i32 @vec_i32_mix(<4 x i32> %ar0sw)
  %m0s = icmp eq i32 %em0s, %am0s

  %dbits0 = add <2 x i64> <i64 4609434218613702656, i64 -4602678819172646912>, zeroinitializer
  %dnorm = bitcast <2 x i64> %dbits0 to <2 x double>
  %er1 = call <2 x double> @reference_canonicalize_v2f64(<2 x double> %dnorm)
  %ar1 = call <2 x double> @protected_canonicalize_v2f64(<2 x double> %dnorm)
  %er1c = bitcast <2 x double> %er1 to <4 x i32>
  %ar1c = bitcast <2 x double> %ar1 to <4 x i32>
  %em1 = call i32 @vec_i32_mix(<4 x i32> %er1c)
  %am1 = call i32 @vec_i32_mix(<4 x i32> %ar1c)
  %m1 = icmp eq i32 %em1, %am1

  ; +inf, quiet NaN payload 0x7FF8000000001234
  %dbits1 = add <2 x i64> <i64 9218868437227405312, i64 9221120237041095220>, zeroinitializer
  %dspec = bitcast <2 x i64> %dbits1 to <2 x double>
  %er1s = call <2 x double> @reference_canonicalize_v2f64(<2 x double> %dspec)
  %ar1s = call <2 x double> @protected_canonicalize_v2f64(<2 x double> %dspec)
  %er1sc = bitcast <2 x double> %er1s to <4 x i32>
  %ar1sc = bitcast <2 x double> %ar1s to <4 x i32>
  %em1s = call i32 @vec_i32_mix(<4 x i32> %er1sc)
  %am1s = call i32 @vec_i32_mix(<4 x i32> %ar1sc)
  %m1s = icmp eq i32 %em1s, %am1s

  %tbits = add <3 x i32> <i32 1069547520, i32 0, i32 -2147483648>, zeroinitializer
  %tvec = bitcast <3 x i32> %tbits to <3 x float>
  %er3 = call <3 x float> @reference_canonicalize_v3f32(<3 x float> %tvec)
  %ar3 = call <3 x float> @protected_canonicalize_v3f32(<3 x float> %tvec)
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

  %fbits = add <4 x i32> <i32 1069547520, i32 -1071644672, i32 0, i32 -2147483648>, zeroinitializer
  %fvec = bitcast <4 x i32> %fbits to <4 x float>
  %er1f = call <4 x float> @reference_fast_canonicalize_v4f32(<4 x float> %fvec)
  %ar1f = call <4 x float> @protected_fast_canonicalize_v4f32(<4 x float> %fvec)
  %er1fc = bitcast <4 x float> %er1f to <4 x i32>
  %ar1fc = bitcast <4 x float> %ar1f to <4 x i32>
  %em1f = call i32 @vec_i32_mix(<4 x i32> %er1fc)
  %am1f = call i32 @vec_i32_mix(<4 x i32> %ar1fc)
  %m1f = icmp eq i32 %em1f, %am1f

  %t0 = and i1 %m0, %m0z
  %t1 = and i1 %m0s, %m1
  %t2 = and i1 %m1s, %m3
  %t3 = and i1 %t0, %t1
  %ok = and i1 %t3, %t2
  %ok2 = and i1 %ok, %m1f
  %code = select i1 %ok2, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_canonicalize_half: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_canonicalize_bfloat: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_canonicalize_scalable: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_canonicalize_wide: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_canonicalize_fastcc: unsupported canonicalize
; SKIP-DAG: Skipping VMP on unsupported_canonicalize_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_canonicalize_bundle: unsupported canonicalize
; SKIP-DAG: Skipping VMP on unsupported_canonicalize_constrained: unsupported target feature
; SKIP-NOT: Skipping VMP on protected_canonicalize_v2f32:
; SKIP-NOT: Skipping VMP on protected_canonicalize_v2f64:
; SKIP-NOT: Skipping VMP on protected_canonicalize_v3f32:
; SKIP-NOT: Skipping VMP on protected_fast_canonicalize_v4f32:

; VIRT: define <2 x float> @protected_canonicalize_v2f32({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: fmul <2 x float>
; VIRT-NOT: {{call.*@llvm.canonicalize}}
; VIRT: define <2 x double> @protected_canonicalize_v2f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: fmul <2 x double>
; VIRT-NOT: {{call.*@llvm.canonicalize}}
; VIRT: define <3 x float> @protected_canonicalize_v3f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: fmul <3 x float>
; VIRT-NOT: {{call.*@llvm.canonicalize}}
; VIRT: define <4 x float> @protected_fast_canonicalize_v4f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: fmul fast <4 x float>
; VIRT-NOT: {{call.*@llvm.canonicalize}}
; VIRT: define {{.*}} @unsupported_canonicalize_half({{.*}} #[[UNSUPATTR:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_canonicalize_bfloat({{.*}} #[[UNSUP_RET:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_canonicalize_scalable({{.*}} #[[UNSUP_SC:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_canonicalize_wide({{.*}} #[[UNSUP_W:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_canonicalize_fastcc({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_canonicalize_musttail({{.*}} #[[UNSUP_MT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call <4 x float> @llvm.canonicalize.v4f32(
; VIRT: define {{.*}} @unsupported_canonicalize_bundle({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call <4 x float> @llvm.canonicalize.v4f32({{.*}}[ "deopt"(i32 0) ]
; VIRT: define {{.*}} @unsupported_canonicalize_constrained({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_MT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_RET]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_SC]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_W]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
