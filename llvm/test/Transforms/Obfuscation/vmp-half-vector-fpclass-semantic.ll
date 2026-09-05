; Restricted llvm.is.fpclass on fixed IEEE half vectors (total 1..128).
; Result is a same-lane <N x i1>.  The i32 class test is an ImmArg
; ConstantInt replayed via CallDescriptor ImmediateArguments.  Requires
; last-token function +fullfp16.  Well-shaped calls missing or ending
; in -fullfp16 skip as unsupported target feature and keep
; hikari.vmp.selected.  Does not change scalar or f32/f64 vector
; is.fpclass, listed half-vector math, or ordinary tail.  No FMF path
; and no dedicated VM opcode.
;
; Host x86 cannot be assumed to select half-vector is.fpclass.  This
; lit is FileCheck + AArch64 llc/readobj only (function +fullfp16, no
; global -mattr).  Do not invent a host lli semantic oracle.
;
; Masks: fcNormal=264, fcZero=96, fcInf=516, fcNan=3.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.ll > %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.ll > %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.s7.ll > %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.s7.ll > %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare <4 x i1> @llvm.is.fpclass.v4f16(<4 x half>, i32)
declare <8 x i1> @llvm.is.fpclass.v8f16(<8 x half>, i32)
declare <3 x i1> @llvm.is.fpclass.v3f16(<3 x half>, i32)
declare <4 x i1> @llvm.is.fpclass.v4bf16(<4 x bfloat>, i32)
declare <vscale x 4 x i1> @llvm.is.fpclass.nxv4f16(<vscale x 4 x half>, i32)
declare <16 x i1> @llvm.is.fpclass.v16f16(<16 x half>, i32)

declare <4 x half> @llvm.experimental.constrained.pow.v4f16(<4 x half>, <4 x half>, metadata, metadata)

define <4 x i1> @reference_fpclass_normal_v4f16(<4 x half> %a) {
entry:
  %r = call <4 x i1> @llvm.is.fpclass.v4f16(<4 x half> %a, i32 264)
  ret <4 x i1> %r
}

define <4 x i1> @protected_fpclass_normal_v4f16(<4 x half> %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i1> @llvm.is.fpclass.v4f16(<4 x half> %a, i32 264)
  ret <4 x i1> %r
}

define <8 x i1> @reference_fpclass_zero_v8f16(<8 x half> %a) {
entry:
  %r = call <8 x i1> @llvm.is.fpclass.v8f16(<8 x half> %a, i32 96)
  ret <8 x i1> %r
}

define <8 x i1> @protected_fpclass_zero_v8f16(<8 x half> %a) noinline optnone "target-features"="+neon,+fullfp16,+fp-armv8" {
entry:
  call void @hikari_vmp()
  %r = call <8 x i1> @llvm.is.fpclass.v8f16(<8 x half> %a, i32 96)
  ret <8 x i1> %r
}

define <3 x i1> @reference_fpclass_inf_v3f16(<3 x half> %a) {
entry:
  %r = call <3 x i1> @llvm.is.fpclass.v3f16(<3 x half> %a, i32 516)
  ret <3 x i1> %r
}

define <3 x i1> @protected_fpclass_inf_v3f16(<3 x half> %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <3 x i1> @llvm.is.fpclass.v3f16(<3 x half> %a, i32 516)
  ret <3 x i1> %r
}

define <4 x i1> @reference_fpclass_nan_v4f16(<4 x half> %a) {
entry:
  %r = call <4 x i1> @llvm.is.fpclass.v4f16(<4 x half> %a, i32 3)
  ret <4 x i1> %r
}

define <4 x i1> @protected_fpclass_nan_v4f16(<4 x half> %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i1> @llvm.is.fpclass.v4f16(<4 x half> %a, i32 3)
  ret <4 x i1> %r
}

; ----- negatives: selected, not virtualized -----

define <4 x i1> @unsupported_half_fpclass_no_fullfp16(<4 x half> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i1> @llvm.is.fpclass.v4f16(<4 x half> %a, i32 264)
  ret <4 x i1> %r
}

define <4 x i1> @unsupported_half_fpclass_fullfp16_disabled(<4 x half> %a) noinline optnone "target-features"="+neon,+fullfp16,-fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i1> @llvm.is.fpclass.v4f16(<4 x half> %a, i32 264)
  ret <4 x i1> %r
}

define <4 x i1> @unsupported_half_fpclass_bfloat(<4 x bfloat> %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i1> @llvm.is.fpclass.v4bf16(<4 x bfloat> %a, i32 3)
  ret <4 x i1> %r
}

define <vscale x 4 x i1> @unsupported_half_fpclass_scalable(<vscale x 4 x half> %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i1> @llvm.is.fpclass.nxv4f16(<vscale x 4 x half> %a, i32 3)
  ret <vscale x 4 x i1> %r
}

define <16 x i1> @unsupported_half_fpclass_wide(<16 x half> %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <16 x i1> @llvm.is.fpclass.v16f16(<16 x half> %a, i32 3)
  ret <16 x i1> %r
}

define <4 x i1> @unsupported_half_fpclass_fastcc(<4 x half> %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call fastcc <4 x i1> @llvm.is.fpclass.v4f16(<4 x half> %a, i32 264)
  ret <4 x i1> %r
}

define <4 x i1> @unsupported_half_fpclass_musttail(<4 x half> %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = musttail call <4 x i1> @llvm.is.fpclass.v4f16(<4 x half> %a, i32 264)
  ret <4 x i1> %r
}

define <4 x i1> @unsupported_half_fpclass_bundle(<4 x half> %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i1> @llvm.is.fpclass.v4f16(<4 x half> %a, i32 264) [ "deopt"(i32 0) ]
  ret <4 x i1> %r
}

define <4 x half> @unsupported_half_fpclass_constrained(<4 x half> %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x half> @llvm.experimental.constrained.pow.v4f16(<4 x half> %a, <4 x half> %a, metadata !"round.tonearest", metadata !"fpexcept.ignore") [ "deopt"(i32 0) ]
  ret <4 x half> %r
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_half_fpclass_no_fullfp16: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_half_fpclass_fullfp16_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_half_fpclass_bfloat: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_half_fpclass_scalable: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_half_fpclass_wide: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_half_fpclass_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_half_fpclass_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_half_fpclass_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_half_fpclass_constrained: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_fpclass_normal_v4f16:
; SKIP-NOT: Skipping VMP on protected_fpclass_zero_v8f16:
; SKIP-NOT: Skipping VMP on protected_fpclass_inf_v3f16:
; SKIP-NOT: Skipping VMP on protected_fpclass_nan_v4f16:

; VIRT: define <4 x i1> @protected_fpclass_normal_v4f16({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i1> @llvm.is.fpclass.v4f16({{.*}}, i32 264)
; VIRT: define <8 x i1> @protected_fpclass_zero_v8f16({{.*}} #[[PROT2:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x i1> @llvm.is.fpclass.v8f16({{.*}}, i32 96)
; VIRT: define <3 x i1> @protected_fpclass_inf_v3f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <3 x i1> @llvm.is.fpclass.v3f16({{.*}}, i32 516)
; VIRT: define <4 x i1> @protected_fpclass_nan_v4f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i1> @llvm.is.fpclass.v4f16({{.*}}, i32 3)
; VIRT: define {{.*}} @unsupported_half_fpclass_no_fullfp16({{.*}} #[[UNSUPATTR:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_half_fpclass_fullfp16_disabled({{.*}} #[[UNSUPFEAT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_half_fpclass_bfloat({{.*}} #[[UNSUP_ARG:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_half_fpclass_scalable({{.*}} #[[UNSUP_SC:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_half_fpclass_wide({{.*}} #[[UNSUP_W:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_half_fpclass_fastcc({{.*}} #[[UNSUPCC:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_half_fpclass_musttail({{.*}} #[[UNSUP_MT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call <4 x i1> @llvm.is.fpclass.v4f16(
; VIRT: define {{.*}} @unsupported_half_fpclass_bundle({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call <4 x i1> @llvm.is.fpclass.v4f16({{.*}}[ "deopt"(i32 0) ]
; VIRT: define {{.*}} @unsupported_half_fpclass_constrained({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[PROT2]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT: attributes #[[UNSUPFEAT]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPFEAT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPCC]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_MT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_ARG]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_SC]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_W]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
