; Restricted llvm.is.fpclass on fixed f32/f64 vectors (total 1..128).
; Result is a same-lane <N x i1> mask.  The i32 class test is an ImmArg
; ConstantInt and is replayed via CallDescriptor ImmediateArguments, never
; a VReg.  Scalar is.fpclass and ordinary tail semantics are unchanged.
; Fixed half-vector is.fpclass is a separate last-token +fullfp16 surface;
; this file's half negative has no +fullfp16 and must stay a feature skip.
; No dedicated VM opcode.
;
; Masks: fcNormal=264, fcZero=96, fcInf=516, fcNan=3.  Host lli compares
; reference vs protected bits for finite, +/-0, +/-inf, and a quiet NaN
; (payload is not pinned).
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
declare <2 x i1> @llvm.is.fpclass.v2f32(<2 x float>, i32)
declare <4 x i1> @llvm.is.fpclass.v4f32(<4 x float>, i32)
declare <2 x i1> @llvm.is.fpclass.v2f64(<2 x double>, i32)
declare <3 x i1> @llvm.is.fpclass.v3f32(<3 x float>, i32)
declare <4 x i1> @llvm.is.fpclass.v4f16(<4 x half>, i32)
declare <4 x i1> @llvm.is.fpclass.v4bf16(<4 x bfloat>, i32)
declare <vscale x 4 x i1> @llvm.is.fpclass.nxv4f32(<vscale x 4 x float>, i32)
declare <8 x i1> @llvm.is.fpclass.v8f64(<8 x double>, i32)

declare <4 x half> @llvm.experimental.constrained.pow.v4f16(<4 x half>, <4 x half>, metadata, metadata)

define <2 x i1> @reference_fpclass_normal_v2f32(<2 x float> %a) {
entry:
  %r = call <2 x i1> @llvm.is.fpclass.v2f32(<2 x float> %a, i32 264)
  ret <2 x i1> %r
}

define <2 x i1> @protected_fpclass_normal_v2f32(<2 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i1> @llvm.is.fpclass.v2f32(<2 x float> %a, i32 264)
  ret <2 x i1> %r
}

define <4 x i1> @reference_fpclass_zero_v4f32(<4 x float> %a) {
entry:
  %r = call <4 x i1> @llvm.is.fpclass.v4f32(<4 x float> %a, i32 96)
  ret <4 x i1> %r
}

define <4 x i1> @protected_fpclass_zero_v4f32(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i1> @llvm.is.fpclass.v4f32(<4 x float> %a, i32 96)
  ret <4 x i1> %r
}

define <2 x i1> @reference_fpclass_inf_v2f64(<2 x double> %a) {
entry:
  %r = call <2 x i1> @llvm.is.fpclass.v2f64(<2 x double> %a, i32 516)
  ret <2 x i1> %r
}

define <2 x i1> @protected_fpclass_inf_v2f64(<2 x double> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i1> @llvm.is.fpclass.v2f64(<2 x double> %a, i32 516)
  ret <2 x i1> %r
}

define <3 x i1> @reference_fpclass_nan_v3f32(<3 x float> %a) {
entry:
  %r = call <3 x i1> @llvm.is.fpclass.v3f32(<3 x float> %a, i32 3)
  ret <3 x i1> %r
}

define <3 x i1> @protected_fpclass_nan_v3f32(<3 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <3 x i1> @llvm.is.fpclass.v3f32(<3 x float> %a, i32 3)
  ret <3 x i1> %r
}

; ----- negatives: selected, not virtualized -----

define <4 x i1> @unsupported_fpclass_half(<4 x half> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i1> @llvm.is.fpclass.v4f16(<4 x half> %a, i32 3)
  ret <4 x i1> %r
}

define <4 x i1> @unsupported_fpclass_bfloat(<4 x bfloat> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i1> @llvm.is.fpclass.v4bf16(<4 x bfloat> %a, i32 3)
  ret <4 x i1> %r
}

define <vscale x 4 x i1> @unsupported_fpclass_scalable(<vscale x 4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i1> @llvm.is.fpclass.nxv4f32(<vscale x 4 x float> %a, i32 3)
  ret <vscale x 4 x i1> %r
}

define <8 x i1> @unsupported_fpclass_wide(<8 x double> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i1> @llvm.is.fpclass.v8f64(<8 x double> %a, i32 3)
  ret <8 x i1> %r
}

define <2 x i1> @unsupported_fpclass_fastcc(<2 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc <2 x i1> @llvm.is.fpclass.v2f32(<2 x float> %a, i32 264)
  ret <2 x i1> %r
}

define <2 x i1> @unsupported_fpclass_musttail(<2 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call <2 x i1> @llvm.is.fpclass.v2f32(<2 x float> %a, i32 264)
  ret <2 x i1> %r
}

define <2 x i1> @unsupported_fpclass_bundle(<2 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i1> @llvm.is.fpclass.v2f32(<2 x float> %a, i32 264) [ "deopt"(i32 0) ]
  ret <2 x i1> %r
}

define <4 x half> @unsupported_fpclass_constrained(<4 x half> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x half> @llvm.experimental.constrained.pow.v4f16(<4 x half> %a, <4 x half> %a, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret <4 x half> %r
}

define i32 @mask2_bits(<2 x i1> %v) {
entry:
  %e0 = extractelement <2 x i1> %v, i32 0
  %e1 = extractelement <2 x i1> %v, i32 1
  %z0 = zext i1 %e0 to i32
  %z1 = zext i1 %e1 to i32
  %s1 = shl i32 %z1, 1
  %r = or i32 %z0, %s1
  ret i32 %r
}

define i32 @mask4_bits(<4 x i1> %v) {
entry:
  %e0 = extractelement <4 x i1> %v, i32 0
  %e1 = extractelement <4 x i1> %v, i32 1
  %e2 = extractelement <4 x i1> %v, i32 2
  %e3 = extractelement <4 x i1> %v, i32 3
  %z0 = zext i1 %e0 to i32
  %z1 = zext i1 %e1 to i32
  %z2 = zext i1 %e2 to i32
  %z3 = zext i1 %e3 to i32
  %s1 = shl i32 %z1, 1
  %s2 = shl i32 %z2, 2
  %s3 = shl i32 %z3, 3
  %o0 = or i32 %z0, %s1
  %o1 = or i32 %s2, %s3
  %r = or i32 %o0, %o1
  ret i32 %r
}

define i32 @main() {
entry:
  ; 1.5, -2.5  — both normal
  %nbits = add <2 x i32> <i32 1069547520, i32 -1071644672>, zeroinitializer
  %norm = bitcast <2 x i32> %nbits to <2 x float>
  %er0 = call <2 x i1> @reference_fpclass_normal_v2f32(<2 x float> %norm)
  %ar0 = call <2 x i1> @protected_fpclass_normal_v2f32(<2 x float> %norm)
  %em0 = call i32 @mask2_bits(<2 x i1> %er0)
  %am0 = call i32 @mask2_bits(<2 x i1> %ar0)
  %m0 = icmp eq i32 %em0, %am0

  ; +0, -0, 1.5, -2.5  — zeros vs normals
  %zbits = add <4 x i32> <i32 0, i32 -2147483648, i32 1069547520, i32 -1071644672>, zeroinitializer
  %zvec = bitcast <4 x i32> %zbits to <4 x float>
  %er1 = call <4 x i1> @reference_fpclass_zero_v4f32(<4 x float> %zvec)
  %ar1 = call <4 x i1> @protected_fpclass_zero_v4f32(<4 x float> %zvec)
  %em1 = call i32 @mask4_bits(<4 x i1> %er1)
  %am1 = call i32 @mask4_bits(<4 x i1> %ar1)
  %m1 = icmp eq i32 %em1, %am1

  ; +inf, -inf
  %ibits = add <2 x i64> <i64 9218868437227405312, i64 -4503599627370496>, zeroinitializer
  %ivec = bitcast <2 x i64> %ibits to <2 x double>
  %er2 = call <2 x i1> @reference_fpclass_inf_v2f64(<2 x double> %ivec)
  %ar2 = call <2 x i1> @protected_fpclass_inf_v2f64(<2 x double> %ivec)
  %em2 = call i32 @mask2_bits(<2 x i1> %er2)
  %am2 = call i32 @mask2_bits(<2 x i1> %ar2)
  %m2 = icmp eq i32 %em2, %am2

  ; qNaN, 1.5, +0  — leftover <3 x float>
  %qbits = add <3 x i32> <i32 2143289344, i32 1069547520, i32 0>, zeroinitializer
  %qvec = bitcast <3 x i32> %qbits to <3 x float>
  %er3 = call <3 x i1> @reference_fpclass_nan_v3f32(<3 x float> %qvec)
  %ar3 = call <3 x i1> @protected_fpclass_nan_v3f32(<3 x float> %qvec)
  %e30 = extractelement <3 x i1> %er3, i32 0
  %e31 = extractelement <3 x i1> %er3, i32 1
  %e32 = extractelement <3 x i1> %er3, i32 2
  %a30 = extractelement <3 x i1> %ar3, i32 0
  %a31 = extractelement <3 x i1> %ar3, i32 1
  %a32 = extractelement <3 x i1> %ar3, i32 2
  %c0 = icmp eq i1 %e30, %a30
  %c1 = icmp eq i1 %e31, %a31
  %c2 = icmp eq i1 %e32, %a32
  %c01 = and i1 %c0, %c1
  %m3 = and i1 %c01, %c2

  %t0 = and i1 %m0, %m1
  %t1 = and i1 %m2, %m3
  %ok = and i1 %t0, %t1
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_fpclass_half: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_fpclass_bfloat: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_fpclass_scalable: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_fpclass_wide: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_fpclass_fastcc: unsupported is.fpclass
; SKIP-DAG: Skipping VMP on unsupported_fpclass_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_fpclass_bundle: unsupported is.fpclass
; SKIP-DAG: Skipping VMP on unsupported_fpclass_constrained: unsupported target feature
; SKIP-NOT: Skipping VMP on protected_fpclass_normal_v2f32:
; SKIP-NOT: Skipping VMP on protected_fpclass_zero_v4f32:
; SKIP-NOT: Skipping VMP on protected_fpclass_inf_v2f64:
; SKIP-NOT: Skipping VMP on protected_fpclass_nan_v3f32:

; VIRT: define <2 x i1> @protected_fpclass_normal_v2f32({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i1> @llvm.is.fpclass.v2f32({{.*}}, i32 264)
; VIRT: define <4 x i1> @protected_fpclass_zero_v4f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i1> @llvm.is.fpclass.v4f32({{.*}}, i32 96)
; VIRT: define <2 x i1> @protected_fpclass_inf_v2f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i1> @llvm.is.fpclass.v2f64({{.*}}, i32 516)
; VIRT: define <3 x i1> @protected_fpclass_nan_v3f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <3 x i1> @llvm.is.fpclass.v3f32({{.*}}, i32 3)
; VIRT: define {{.*}} @unsupported_fpclass_half({{.*}} #[[UNSUPATTR:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fpclass_bfloat({{.*}} #[[UNSUP_ARG:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fpclass_scalable({{.*}} #[[UNSUP_SC:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fpclass_wide({{.*}} #[[UNSUP_W:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fpclass_fastcc({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fpclass_musttail({{.*}} #[[UNSUP_MT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call <2 x i1> @llvm.is.fpclass.v2f32(
; VIRT: define {{.*}} @unsupported_fpclass_bundle({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call <2 x i1> @llvm.is.fpclass.v2f32({{.*}}[ "deopt"(i32 0) ]
; VIRT: define {{.*}} @unsupported_fpclass_constrained({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_MT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_ARG]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_SC]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_W]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
