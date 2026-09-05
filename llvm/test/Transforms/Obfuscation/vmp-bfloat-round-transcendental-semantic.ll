; Listed last-token +bf16 same-type rounding and transcendental
; intrinsics on scalar bfloat and supported fixed bfloat vectors
; (total width 1..128): llvm.ceil / floor / trunc / round / roundeven
; / rint / nearbyint / sin / cos / exp / exp2 / log / log2 / log10.
; Exact token only.  Well-shaped listed calls missing or ending in
; -bf16 skip as unsupported target feature and keep
; hikari.vmp.selected.
;
; No new VM opcode.  CallDescriptor.LegalizeBFloatMath promotes each
; operand to f32, calls the matching f32 intrinsic (rint vs nearbyint
; keep their specified rounding-mode / exception behavior), and RNE
; back.  Vectors are per-lane so <8 x bfloat> never becomes
; <8 x float>.  Native llvm.*.bf16 / llvm.*.vNbf16 must not reach
; AArch64 ISel.
;
; Not opened: FastMathFlags, constrained, unlisted IDs
; (pow/powi are the independent +bf16 power surface), atomics,
; scalable/>128, poison/undef, invalid signatures, absent or
; last-token -bf16.
;
; Host x86 cannot be assumed to select bfloat math.  This lit is
; FileCheck + AArch64 llc/readobj only (function +bf16, no global
; -mattr).
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
declare bfloat @llvm.ceil.bf16(bfloat)
declare bfloat @llvm.floor.bf16(bfloat)
declare bfloat @llvm.trunc.bf16(bfloat)
declare bfloat @llvm.round.bf16(bfloat)
declare bfloat @llvm.roundeven.bf16(bfloat)
declare bfloat @llvm.rint.bf16(bfloat)
declare bfloat @llvm.nearbyint.bf16(bfloat)
declare bfloat @llvm.sin.bf16(bfloat)
declare bfloat @llvm.cos.bf16(bfloat)
declare bfloat @llvm.exp.bf16(bfloat)
declare bfloat @llvm.exp2.bf16(bfloat)
declare bfloat @llvm.log.bf16(bfloat)
declare bfloat @llvm.log2.bf16(bfloat)
declare bfloat @llvm.log10.bf16(bfloat)
declare bfloat @llvm.fmuladd.bf16(bfloat, bfloat, bfloat)
declare bfloat @llvm.powi.bf16.i64(bfloat, i64)
declare bfloat @llvm.experimental.constrained.ceil.bf16(bfloat, metadata)
declare <4 x bfloat> @llvm.rint.v4bf16(<4 x bfloat>)
declare <4 x bfloat> @llvm.sin.v4bf16(<4 x bfloat>)
declare <4 x bfloat> @llvm.log10.v4bf16(<4 x bfloat>)
declare <8 x bfloat> @llvm.exp.v8bf16(<8 x bfloat>)

; ----- positives -----

define bfloat @protected_ceil(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.ceil.bf16(bfloat %a)
  ret bfloat %r
}

define bfloat @protected_floor(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.floor.bf16(bfloat %a)
  ret bfloat %r
}

define bfloat @protected_trunc(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.trunc.bf16(bfloat %a)
  ret bfloat %r
}

define bfloat @protected_round(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.round.bf16(bfloat %a)
  ret bfloat %r
}

define bfloat @protected_roundeven(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.roundeven.bf16(bfloat %a)
  ret bfloat %r
}

define bfloat @protected_rint(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.rint.bf16(bfloat %a)
  ret bfloat %r
}

define bfloat @protected_nearbyint(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.nearbyint.bf16(bfloat %a)
  ret bfloat %r
}

define bfloat @protected_sin(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.sin.bf16(bfloat %a)
  ret bfloat %r
}

define bfloat @protected_cos(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.cos.bf16(bfloat %a)
  ret bfloat %r
}

define bfloat @protected_exp(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.exp.bf16(bfloat %a)
  ret bfloat %r
}

define bfloat @protected_exp2(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.exp2.bf16(bfloat %a)
  ret bfloat %r
}

define bfloat @protected_log(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.log.bf16(bfloat %a)
  ret bfloat %r
}

define bfloat @protected_log2(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.log2.bf16(bfloat %a)
  ret bfloat %r
}

define bfloat @protected_log10(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.log10.bf16(bfloat %a)
  ret bfloat %r
}

define bfloat @protected_round_mix(bfloat %a, bfloat %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %c = call bfloat @llvm.ceil.bf16(bfloat %a)
  %s = fadd bfloat %c, %b
  ret bfloat %s
}

define bfloat @protected_last_token(bfloat %a) noinline optnone "target-features"="-bf16,+neon,+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.floor.bf16(bfloat %a)
  ret bfloat %r
}

define <4 x bfloat> @protected_rint_v4(<4 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x bfloat> @llvm.rint.v4bf16(<4 x bfloat> %a)
  ret <4 x bfloat> %r
}

define <4 x bfloat> @protected_sin_v4(<4 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x bfloat> @llvm.sin.v4bf16(<4 x bfloat> %a)
  ret <4 x bfloat> %r
}

define <4 x bfloat> @protected_log10_v4(<4 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x bfloat> @llvm.log10.v4bf16(<4 x bfloat> %a)
  ret <4 x bfloat> %r
}

define <8 x bfloat> @protected_exp_v8(<8 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <8 x bfloat> @llvm.exp.v8bf16(<8 x bfloat> %a)
  ret <8 x bfloat> %r
}

; ----- negatives -----

define i16 @unsupported_ceil_no_feature(i16 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %b = bitcast i16 %a to bfloat
  %r = call bfloat @llvm.ceil.bf16(bfloat %b)
  %s = bitcast bfloat %r to i16
  ret i16 %s
}

define i16 @unsupported_sin_disabled(i16 %a) noinline optnone "target-features"="+neon,+bf16,-bf16" {
entry:
  call void @hikari_vmp()
  %b = bitcast i16 %a to bfloat
  %r = call bfloat @llvm.sin.bf16(bfloat %b)
  %s = bitcast bfloat %r to i16
  ret i16 %s
}

define bfloat @unsupported_floor_fmf(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call nnan bfloat @llvm.floor.bf16(bfloat %a)
  ret bfloat %r
}

; pow/powi and canonicalize/is.fpclass are independent +bf16
; surfaces.  constrained and non-i32 powi stay closed.
define bfloat @unsupported_pow(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.experimental.constrained.ceil.bf16(bfloat %a, metadata !"fpexcept.ignore")
  ret bfloat %r
}

define bfloat @unsupported_powi(bfloat %a, i64 %e) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.powi.bf16.i64(bfloat %a, i64 %e)
  ret bfloat %r
}

define bfloat @unsupported_constrained_ceil(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.experimental.constrained.ceil.bf16(bfloat %a, metadata !"fpexcept.ignore")
  ret bfloat %r
}

define bfloat @unsupported_rint_poison() noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.rint.bf16(bfloat poison)
  ret bfloat %r
}

define i64 @unsupported_sin_v4_no_feature(i64 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %a = bitcast i64 %x to <4 x bfloat>
  %r = call <4 x bfloat> @llvm.sin.v4bf16(<4 x bfloat> %a)
  %s = bitcast <4 x bfloat> %r to i64
  ret i64 %s
}

define <4 x bfloat> @unsupported_sin_v4_fmf(<4 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call nnan <4 x bfloat> @llvm.sin.v4bf16(<4 x bfloat> %a)
  ret <4 x bfloat> %r
}

define <16 x bfloat> @unsupported_ceil_v16(<16 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  ret <16 x bfloat> %a
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_ceil_no_feature: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_sin_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_floor_fmf: unsupported float call instruction
; SKIP-DAG: Skipping VMP on unsupported_pow: unsupported call
; SKIP-DAG: Skipping VMP on unsupported_powi: unsupported call
; SKIP-DAG: Skipping VMP on unsupported_constrained_ceil: unsupported call
; SKIP-DAG: Skipping VMP on unsupported_rint_poison: unsupported call
; SKIP-DAG: Skipping VMP on unsupported_sin_v4_no_feature: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_sin_v4_fmf: unsupported float call instruction
; SKIP-DAG: Skipping VMP on unsupported_ceil_v16: unsupported
; SKIP-NOT: Skipping VMP on protected_ceil:
; SKIP-NOT: Skipping VMP on protected_floor:
; SKIP-NOT: Skipping VMP on protected_trunc:
; SKIP-NOT: Skipping VMP on protected_round:
; SKIP-NOT: Skipping VMP on protected_roundeven:
; SKIP-NOT: Skipping VMP on protected_rint:
; SKIP-NOT: Skipping VMP on protected_nearbyint:
; SKIP-NOT: Skipping VMP on protected_sin:
; SKIP-NOT: Skipping VMP on protected_cos:
; SKIP-NOT: Skipping VMP on protected_exp:
; SKIP-NOT: Skipping VMP on protected_exp2:
; SKIP-NOT: Skipping VMP on protected_log:
; SKIP-NOT: Skipping VMP on protected_log2:
; SKIP-NOT: Skipping VMP on protected_log10:
; SKIP-NOT: Skipping VMP on protected_round_mix:
; SKIP-NOT: Skipping VMP on protected_last_token:
; SKIP-NOT: Skipping VMP on protected_rint_v4:
; SKIP-NOT: Skipping VMP on protected_sin_v4:
; SKIP-NOT: Skipping VMP on protected_log10_v4:
; SKIP-NOT: Skipping VMP on protected_exp_v8:

; VIRT: define bfloat @protected_ceil({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.ceil.bf16
; VIRT: call float @llvm.ceil.f32
; VIRT: define bfloat @protected_floor({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.floor.bf16
; VIRT: call float @llvm.floor.f32
; VIRT: define bfloat @protected_trunc({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.trunc.bf16
; VIRT: call float @llvm.trunc.f32
; VIRT: define bfloat @protected_round({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.round.bf16
; VIRT: call float @llvm.round.f32
; VIRT: define bfloat @protected_roundeven({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.roundeven.bf16
; VIRT: call float @llvm.roundeven.f32
; VIRT: define bfloat @protected_rint({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.rint.bf16
; VIRT-NOT: call float @llvm.nearbyint.f32
; VIRT: call float @llvm.rint.f32
; VIRT: define bfloat @protected_nearbyint({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.nearbyint.bf16
; VIRT-NOT: call float @llvm.rint.f32
; VIRT: call float @llvm.nearbyint.f32
; VIRT: define bfloat @protected_sin({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.sin.bf16
; VIRT: call float @llvm.sin.f32
; VIRT: define bfloat @protected_cos({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.cos.bf16
; VIRT: call float @llvm.cos.f32
; VIRT: define bfloat @protected_exp({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.exp.bf16
; VIRT: call float @llvm.exp.f32
; VIRT: define bfloat @protected_exp2({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.exp2.bf16
; VIRT: call float @llvm.exp2.f32
; VIRT: define bfloat @protected_log({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.log.bf16
; VIRT: call float @llvm.log.f32
; VIRT: define bfloat @protected_log2({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.log2.bf16
; VIRT: call float @llvm.log2.f32
; VIRT: define bfloat @protected_log10({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.log10.bf16
; VIRT: call float @llvm.log10.f32
; VIRT: define bfloat @protected_round_mix({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.ceil.bf16
; VIRT-NOT: fadd{{.*}}bfloat
; VIRT-DAG: call float @llvm.ceil.f32
; VIRT-DAG: fadd{{.*}} float
; VIRT: define bfloat @protected_last_token({{.*}} #[[PROTLAST:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.floor.f32
; VIRT: define <4 x bfloat> @protected_rint_v4({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.rint.v4bf16
; VIRT: call float @llvm.rint.f32
; VIRT: define <4 x bfloat> @protected_sin_v4({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.sin.v4bf16
; VIRT: call float @llvm.sin.f32
; VIRT: define <4 x bfloat> @protected_log10_v4({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.log10.v4bf16
; VIRT: call float @llvm.log10.f32
; VIRT: define <8 x bfloat> @protected_exp_v8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.exp.v8bf16
; VIRT: call float @llvm.exp.f32
; VIRT: define {{.*}} @unsupported_ceil_no_feature({{.*}} #[[UNSUPFEAT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_sin_disabled({{.*}} #[[UNSUPDIS:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_floor_fmf({{.*}} #[[UNSUPFMF:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call nnan bfloat @llvm.floor.bf16
; VIRT: define {{.*}} @unsupported_pow({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_powi({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_constrained_ceil({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_rint_poison({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_sin_v4_no_feature({{.*}} #[[UNSUPFEAT]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_sin_v4_fmf({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call nnan <4 x bfloat> @llvm.sin.v4bf16
; VIRT: define {{.*}} @unsupported_ceil_v16({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[PROTLAST]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPFEAT]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT: attributes #[[UNSUPDIS]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT: attributes #[[UNSUPFMF]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPFEAT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPDIS]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPFMF]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
