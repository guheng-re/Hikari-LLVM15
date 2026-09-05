; Generic llvm.minnum/maxnum/minimum/maximum on supported fixed
; f32/f64 vectors (total 1..128).  Replayed via the existing
; CallDescriptor and vector VReg frame.  Integer smin/smax stay on
; vmp-minmax-vector-semantic.ll.  Half vectors stay on the existing
; last-token +fullfp16 half-vector math path and are not accepted here.
; bfloat/fp128, scalable, >128-bit, constrained, poison/undef, fastcc,
; and musttail/bundle stay out.  Host x86 cannot select llvm.minimum/
; maximum vectors, so those two IDs are FileCheck + AArch64 llc only
; and are not executed on host lli.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.ll > %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.live.ll -o %t.o0.hostsrc.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.hostsrc.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.ll > %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.live.ll -o %t.o2.hostsrc.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.hostsrc.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.s7.ll > %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.s7.live.ll -o %t.o0.s7.hostsrc.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.s7.hostsrc.ll > %t.o0.s7.host.ll
; RUN: lli -force-interpreter %t.o0.s7.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.s7.ll > %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.s7.live.ll -o %t.o2.s7.hostsrc.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.s7.hostsrc.ll > %t.o2.s7.host.ll
; RUN: lli -force-interpreter %t.o2.s7.host.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare <2 x float> @llvm.minnum.v2f32(<2 x float>, <2 x float>)
declare <4 x float> @llvm.maxnum.v4f32(<4 x float>, <4 x float>)
declare <2 x double> @llvm.minimum.v2f64(<2 x double>, <2 x double>)
declare <2 x float> @llvm.maximum.v2f32(<2 x float>, <2 x float>)
declare <3 x float> @llvm.minnum.v3f32(<3 x float>, <3 x float>)
declare <4 x float> @llvm.minnum.v4f32(<4 x float>, <4 x float>)
declare <4 x half> @llvm.minnum.v4f16(<4 x half>, <4 x half>)
declare <4 x bfloat> @llvm.maxnum.v4bf16(<4 x bfloat>, <4 x bfloat>)
declare <vscale x 4 x float> @llvm.minnum.nxv4f32(<vscale x 4 x float>, <vscale x 4 x float>)
declare <8 x double> @llvm.maximum.v8f64(<8 x double>, <8 x double>)

declare <4 x half> @llvm.experimental.constrained.pow.v4f16(<4 x half>, <4 x half>, metadata, metadata)

define <2 x float> @reference_minnum_v2f32(<2 x float> %a, <2 x float> %b) {
entry:
  %r = call <2 x float> @llvm.minnum.v2f32(<2 x float> %a, <2 x float> %b)
  ret <2 x float> %r
}

define <2 x float> @protected_minnum_v2f32(<2 x float> %a, <2 x float> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.minnum.v2f32(<2 x float> %a, <2 x float> %b)
  ret <2 x float> %r
}

define <4 x float> @reference_maxnum_v4f32(<4 x float> %a, <4 x float> %b) {
entry:
  %r = call <4 x float> @llvm.maxnum.v4f32(<4 x float> %a, <4 x float> %b)
  ret <4 x float> %r
}

define <4 x float> @protected_maxnum_v4f32(<4 x float> %a, <4 x float> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.maxnum.v4f32(<4 x float> %a, <4 x float> %b)
  ret <4 x float> %r
}

define <2 x double> @reference_minimum_v2f64(<2 x double> %a, <2 x double> %b) {
entry:
  %r = call <2 x double> @llvm.minimum.v2f64(<2 x double> %a, <2 x double> %b)
  ret <2 x double> %r
}

define <2 x double> @protected_minimum_v2f64(<2 x double> %a, <2 x double> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x double> @llvm.minimum.v2f64(<2 x double> %a, <2 x double> %b)
  ret <2 x double> %r
}

define <2 x float> @reference_maximum_v2f32(<2 x float> %a, <2 x float> %b) {
entry:
  %r = call <2 x float> @llvm.maximum.v2f32(<2 x float> %a, <2 x float> %b)
  ret <2 x float> %r
}

define <2 x float> @protected_maximum_v2f32(<2 x float> %a, <2 x float> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.maximum.v2f32(<2 x float> %a, <2 x float> %b)
  ret <2 x float> %r
}

define <3 x float> @reference_minnum_v3f32(<3 x float> %a, <3 x float> %b) {
entry:
  %r = call <3 x float> @llvm.minnum.v3f32(<3 x float> %a, <3 x float> %b)
  ret <3 x float> %r
}

define <3 x float> @protected_minnum_v3f32(<3 x float> %a, <3 x float> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <3 x float> @llvm.minnum.v3f32(<3 x float> %a, <3 x float> %b)
  ret <3 x float> %r
}

define <4 x float> @protected_fast_minnum_v4f32(<4 x float> %a, <4 x float> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fast <4 x float> @llvm.minnum.v4f32(<4 x float> %a, <4 x float> %b)
  ret <4 x float> %r
}

; ----- negatives: selected, not virtualized -----

define <4 x half> @unsupported_fpminmax_half(<4 x half> %a, <4 x half> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x half> @llvm.minnum.v4f16(<4 x half> %a, <4 x half> %b)
  ret <4 x half> %r
}

define <4 x bfloat> @unsupported_fpminmax_bfloat(<4 x bfloat> %a, <4 x bfloat> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x bfloat> @llvm.maxnum.v4bf16(<4 x bfloat> %a, <4 x bfloat> %b)
  ret <4 x bfloat> %r
}

define <vscale x 4 x float> @unsupported_fpminmax_scalable(<vscale x 4 x float> %a, <vscale x 4 x float> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x float> @llvm.minnum.nxv4f32(<vscale x 4 x float> %a, <vscale x 4 x float> %b)
  ret <vscale x 4 x float> %r
}

define <8 x double> @unsupported_fpminmax_wide(<8 x double> %a, <8 x double> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x double> @llvm.maximum.v8f64(<8 x double> %a, <8 x double> %b)
  ret <8 x double> %r
}

define <4 x half> @unsupported_fpminmax_constrained(<4 x half> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x half> @llvm.experimental.constrained.pow.v4f16(<4 x half> %a, <4 x half> %a, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret <4 x half> %r
}

define <4 x float> @unsupported_fpminmax_fastcc(<4 x float> %a, <4 x float> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc <4 x float> @llvm.maxnum.v4f32(<4 x float> %a, <4 x float> %b)
  ret <4 x float> %r
}

define <4 x float> @unsupported_fpminmax_musttail(<4 x float> %a, <4 x float> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call <4 x float> @llvm.maxnum.v4f32(<4 x float> %a, <4 x float> %b)
  ret <4 x float> %r
}

define <4 x float> @unsupported_fpminmax_bundle(<4 x float> %a, <4 x float> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.maxnum.v4f32(<4 x float> %a, <4 x float> %b) [ "deopt"(i32 0) ]
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
  %a2 = fadd <2 x float> <float 1.250000e+00, float -2.000000e+00>, zeroinitializer
  %b2 = fadd <2 x float> <float 3.000000e+00, float -4.000000e+00>, zeroinitializer
  %er0 = call <2 x float> @reference_minnum_v2f32(<2 x float> %a2, <2 x float> %b2)
  %ar0 = call <2 x float> @protected_minnum_v2f32(<2 x float> %a2, <2 x float> %b2)
  %er0c = bitcast <2 x float> %er0 to <2 x i32>
  %ar0c = bitcast <2 x float> %ar0 to <2 x i32>
  %er0z = zext <2 x i32> %er0c to <2 x i64>
  %ar0z = zext <2 x i32> %ar0c to <2 x i64>
  %er0w = bitcast <2 x i64> %er0z to <4 x i32>
  %ar0w = bitcast <2 x i64> %ar0z to <4 x i32>
  %em0 = call i32 @vec_i32_mix(<4 x i32> %er0w)
  %am0 = call i32 @vec_i32_mix(<4 x i32> %ar0w)
  %m0 = icmp eq i32 %em0, %am0

  %a4 = fadd <4 x float> <float 1.000000e+00, float -1.500000e+00, float 2.000000e+00, float 0.250000e+00>, zeroinitializer
  %b4 = fadd <4 x float> <float 2.000000e+00, float -4.000000e+00, float -0.500000e+00, float 3.000000e+00>, zeroinitializer
  %er1 = call <4 x float> @reference_maxnum_v4f32(<4 x float> %a4, <4 x float> %b4)
  %ar1 = call <4 x float> @protected_maxnum_v4f32(<4 x float> %a4, <4 x float> %b4)
  %er1c = bitcast <4 x float> %er1 to <4 x i32>
  %ar1c = bitcast <4 x float> %ar1 to <4 x i32>
  %em1 = call i32 @vec_i32_mix(<4 x i32> %er1c)
  %am1 = call i32 @vec_i32_mix(<4 x i32> %ar1c)
  %m1 = icmp eq i32 %em1, %am1

  %a3 = fadd <3 x float> <float 1.000000e+00, float -2.000000e+00, float 0.500000e+00>, zeroinitializer
  %b3 = fadd <3 x float> <float 3.000000e+00, float 0.250000e+00, float -1.000000e+00>, zeroinitializer
  %er3 = call <3 x float> @reference_minnum_v3f32(<3 x float> %a3, <3 x float> %b3)
  %ar3 = call <3 x float> @protected_minnum_v3f32(<3 x float> %a3, <3 x float> %b3)
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

  %ok = and i1 %m0, %m1
  %ok2 = and i1 %ok, %m3
  %code = select i1 %ok2, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_fpminmax_half: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_fpminmax_bfloat: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_fpminmax_scalable: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_fpminmax_wide: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_fpminmax_constrained: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_fpminmax_fastcc: unsupported maxnum
; SKIP-DAG: Skipping VMP on unsupported_fpminmax_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_fpminmax_bundle: unsupported maxnum
; SKIP-NOT: Skipping VMP on protected_minnum_v2f32:
; SKIP-NOT: Skipping VMP on protected_maxnum_v4f32:
; SKIP-NOT: Skipping VMP on protected_minimum_v2f64:
; SKIP-NOT: Skipping VMP on protected_maximum_v2f32:
; SKIP-NOT: Skipping VMP on protected_minnum_v3f32:
; SKIP-NOT: Skipping VMP on protected_fast_minnum_v4f32:

; VIRT: define <2 x float> @protected_minnum_v2f32({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x float> @llvm.minnum.v2f32(
; VIRT: define <4 x float> @protected_maxnum_v4f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x float> @llvm.maxnum.v4f32(
; VIRT: define <2 x double> @protected_minimum_v2f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x double> @llvm.minimum.v2f64(
; VIRT: define <2 x float> @protected_maximum_v2f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x float> @llvm.maximum.v2f32(
; VIRT: define <3 x float> @protected_minnum_v3f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <3 x float> @llvm.minnum.v3f32(
; VIRT: define <4 x float> @protected_fast_minnum_v4f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call fast <4 x float> @llvm.minnum.v4f32(
; VIRT: define {{.*}} @unsupported_fpminmax_half({{.*}} #[[UNSUPATTR:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fpminmax_bfloat({{.*}} #[[UNSUP_RET:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fpminmax_scalable({{.*}} #[[UNSUP_SC:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fpminmax_wide({{.*}} #[[UNSUP_W:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fpminmax_constrained({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fpminmax_fastcc({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fpminmax_musttail({{.*}} #[[UNSUP_MT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call <4 x float> @llvm.maxnum.v4f32(
; VIRT: define {{.*}} @unsupported_fpminmax_bundle({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call <4 x float> @llvm.maxnum.v4f32({{.*}}[ "deopt"(i32 0) ]
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_MT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_RET]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_SC]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_W]] = { {{.*}}"hikari.vmp.virtualized"
