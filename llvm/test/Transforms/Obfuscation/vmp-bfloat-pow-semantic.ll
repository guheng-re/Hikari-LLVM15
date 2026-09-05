; Listed last-token +bf16 llvm.pow and llvm.powi on scalar bfloat and
; supported fixed bfloat vectors (total width 1..128).  pow takes
; matching bfloat operands.  powi takes a bfloat scalar or fixed
; bfloat-vector base plus a scalar i32 exponent (LangRef).  Exact
; token only.  Well-shaped listed calls missing or ending in -bf16
; skip as unsupported target feature and keep hikari.vmp.selected.
;
; No new VM opcode.  CallDescriptor.LegalizeBFloatMath: promote each
; bfloat operand to f32, keep the i32 powi exponent unchanged on the
; integer VReg, call llvm.pow.f32 / llvm.powi.f32, and RNE back.
; Vectors are per-lane so <8 x bfloat> never becomes <8 x float>.
; Native llvm.pow.bf16 / llvm.powi.v4bf16.i32 must not reach AArch64
; ISel.
;
; Not opened: FastMathFlags, constrained pow, non-i32 or
; vector exponents, atomics, scalable/>128, poison/undef, invalid
; signatures, absent or last-token -bf16.  LLVM 15 powi cannot have a
; vector exponent (verifier); the shape helper still requires scalar
; i32.
;
; Host x86 cannot be assumed to select bfloat pow.  This lit is
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
declare bfloat @llvm.pow.bf16(bfloat, bfloat)
declare bfloat @llvm.powi.bf16.i32(bfloat, i32)
declare bfloat @llvm.powi.bf16.i64(bfloat, i64)
declare bfloat @llvm.fmuladd.bf16(bfloat, bfloat, bfloat)
declare bfloat @llvm.experimental.constrained.pow.bf16(bfloat, bfloat, metadata, metadata)
declare <4 x bfloat> @llvm.pow.v4bf16(<4 x bfloat>, <4 x bfloat>)
declare <4 x bfloat> @llvm.powi.v4bf16.i32(<4 x bfloat>, i32)
declare <8 x bfloat> @llvm.powi.v8bf16.i32(<8 x bfloat>, i32)

; ----- positives -----

define bfloat @protected_pow(bfloat %a, bfloat %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.pow.bf16(bfloat %a, bfloat %b)
  ret bfloat %r
}

define bfloat @protected_powi(bfloat %a, i32 %e) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.powi.bf16.i32(bfloat %a, i32 %e)
  ret bfloat %r
}

define bfloat @protected_pow_mix(bfloat %a, bfloat %b, i32 %e) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %p = call bfloat @llvm.pow.bf16(bfloat %a, bfloat %b)
  %q = call bfloat @llvm.powi.bf16.i32(bfloat %p, i32 %e)
  %s = fadd bfloat %q, %a
  ret bfloat %s
}

define bfloat @protected_last_token(bfloat %a, i32 %e) noinline optnone "target-features"="-bf16,+neon,+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.powi.bf16.i32(bfloat %a, i32 %e)
  ret bfloat %r
}

define <4 x bfloat> @protected_pow_v4(<4 x bfloat> %a, <4 x bfloat> %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x bfloat> @llvm.pow.v4bf16(<4 x bfloat> %a, <4 x bfloat> %b)
  ret <4 x bfloat> %r
}

define <4 x bfloat> @protected_powi_v4(<4 x bfloat> %a, i32 %e) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x bfloat> @llvm.powi.v4bf16.i32(<4 x bfloat> %a, i32 %e)
  ret <4 x bfloat> %r
}

define <8 x bfloat> @protected_powi_v8(<8 x bfloat> %a, i32 %e) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <8 x bfloat> @llvm.powi.v8bf16.i32(<8 x bfloat> %a, i32 %e)
  ret <8 x bfloat> %r
}

; ----- negatives -----

define i16 @unsupported_pow_no_feature(i16 %a, i16 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %x = bitcast i16 %a to bfloat
  %y = bitcast i16 %b to bfloat
  %r = call bfloat @llvm.pow.bf16(bfloat %x, bfloat %y)
  %s = bitcast bfloat %r to i16
  ret i16 %s
}

define i16 @unsupported_powi_disabled(i16 %a, i32 %e) noinline optnone "target-features"="+neon,+bf16,-bf16" {
entry:
  call void @hikari_vmp()
  %x = bitcast i16 %a to bfloat
  %r = call bfloat @llvm.powi.bf16.i32(bfloat %x, i32 %e)
  %s = bitcast bfloat %r to i16
  ret i16 %s
}

define bfloat @unsupported_pow_fmf(bfloat %a, bfloat %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call nnan bfloat @llvm.pow.bf16(bfloat %a, bfloat %b)
  ret bfloat %r
}

define bfloat @unsupported_powi_fmf(bfloat %a, i32 %e) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call nnan bfloat @llvm.powi.bf16.i32(bfloat %a, i32 %e)
  ret bfloat %r
}

define bfloat @unsupported_powi_i64(bfloat %a, i64 %e) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.powi.bf16.i64(bfloat %a, i64 %e)
  ret bfloat %r
}

define bfloat @unsupported_fmuladd(bfloat %a, bfloat %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.experimental.constrained.pow.bf16(bfloat %a, bfloat %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret bfloat %r
}

define bfloat @unsupported_constrained_pow(bfloat %a, bfloat %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.experimental.constrained.pow.bf16(bfloat %a, bfloat %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret bfloat %r
}

define bfloat @unsupported_pow_poison(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.pow.bf16(bfloat %a, bfloat poison)
  ret bfloat %r
}

define i64 @unsupported_pow_v4_no_feature(i64 %x, i64 %y) noinline optnone {
entry:
  call void @hikari_vmp()
  %a = bitcast i64 %x to <4 x bfloat>
  %b = bitcast i64 %y to <4 x bfloat>
  %r = call <4 x bfloat> @llvm.pow.v4bf16(<4 x bfloat> %a, <4 x bfloat> %b)
  %s = bitcast <4 x bfloat> %r to i64
  ret i64 %s
}

define <4 x bfloat> @unsupported_powi_v4_fmf(<4 x bfloat> %a, i32 %e) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call nnan <4 x bfloat> @llvm.powi.v4bf16.i32(<4 x bfloat> %a, i32 %e)
  ret <4 x bfloat> %r
}

define <16 x bfloat> @unsupported_pow_v16(<16 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  ret <16 x bfloat> %a
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_pow_no_feature: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_powi_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_pow_fmf: unsupported float call instruction
; SKIP-DAG: Skipping VMP on unsupported_powi_fmf: unsupported float call instruction
; SKIP-DAG: Skipping VMP on unsupported_powi_i64: unsupported call
; SKIP-DAG: Skipping VMP on unsupported_fmuladd: unsupported call
; SKIP-DAG: Skipping VMP on unsupported_constrained_pow: unsupported call
; SKIP-DAG: Skipping VMP on unsupported_pow_poison: unsupported call
; SKIP-DAG: Skipping VMP on unsupported_pow_v4_no_feature: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_powi_v4_fmf: unsupported float call instruction
; SKIP-DAG: Skipping VMP on unsupported_pow_v16: unsupported
; SKIP-NOT: Skipping VMP on protected_pow:
; SKIP-NOT: Skipping VMP on protected_powi:
; SKIP-NOT: Skipping VMP on protected_pow_mix:
; SKIP-NOT: Skipping VMP on protected_last_token:
; SKIP-NOT: Skipping VMP on protected_pow_v4:
; SKIP-NOT: Skipping VMP on protected_powi_v4:
; SKIP-NOT: Skipping VMP on protected_powi_v8:

; VIRT: define bfloat @protected_pow({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.pow.bf16
; VIRT: call float @llvm.pow.f32
; VIRT: icmp eq i32 {{.*}}, 2139095040
; VIRT: define bfloat @protected_powi({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.powi.bf16
; VIRT: call float @llvm.powi.f32
; VIRT: define bfloat @protected_pow_mix({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.pow.bf16
; VIRT-NOT: call{{.*}}@llvm.powi.bf16
; VIRT-NOT: fadd{{.*}}bfloat
; VIRT-DAG: call float @llvm.pow.f32
; VIRT-DAG: call float @llvm.powi.f32
; VIRT-DAG: fadd{{.*}} float
; VIRT: define bfloat @protected_last_token({{.*}} #[[PROTLAST:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.powi.f32
; VIRT: define <4 x bfloat> @protected_pow_v4({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.pow.v4bf16
; VIRT: call float @llvm.pow.f32
; VIRT: define <4 x bfloat> @protected_powi_v4({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.powi.v4bf16
; VIRT: call float @llvm.powi.f32
; VIRT: define <8 x bfloat> @protected_powi_v8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.powi.v8bf16
; VIRT: call float @llvm.powi.f32
; VIRT: define {{.*}} @unsupported_pow_no_feature({{.*}} #[[UNSUPFEAT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_powi_disabled({{.*}} #[[UNSUPDIS:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_pow_fmf({{.*}} #[[UNSUPFMF:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call nnan bfloat @llvm.pow.bf16
; VIRT: define {{.*}} @unsupported_powi_fmf({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_powi_i64({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call bfloat @llvm.powi.bf16.i64
; VIRT: define {{.*}} @unsupported_fmuladd({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_constrained_pow({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_pow_poison({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_pow_v4_no_feature({{.*}} #[[UNSUPFEAT]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_powi_v4_fmf({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call nnan <4 x bfloat> @llvm.powi.v4bf16.i32
; VIRT: define {{.*}} @unsupported_pow_v16({{.*}} #[[UNSUPFMF]] {
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
