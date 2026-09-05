; Last-token +bf16 llvm.is.fpclass and llvm.canonicalize on scalar
; bfloat and supported fixed 1..128 bfloat vectors.  Exact token only.
; Well-shaped listed calls missing or ending in -bf16 skip as
; unsupported target feature and keep hikari.vmp.selected.
;
; is.fpclass: scalar bfloat -> i1, or same-lane fixed bfloat vector
; -> <N x i1>, plus an i32 ConstantInt ImmArg mask.  Each bfloat is
; promoted exactly to f32 and classified with llvm.is.fpclass.f32 per
; lane.  Native bfloat is.fpclass must not reach AArch64 ISel.
;
; canonicalize: promote to f32, use the validated f32 lowering
; (fmul x, 1.0), then RNE back (Inf/NaN short-circuit).  Never replay
; llvm.canonicalize.bf16 or llvm.canonicalize.f32.
;
; No new VM opcode.  CallDescriptor.LegalizeBFloatMath.  FMF is
; rejected.  Ordinary tail is allowed; musttail is not.
;
; Host x86 cannot be assumed to select bfloat.  This lit is FileCheck
; + AArch64 llc/readobj only (function +bf16, no global -mattr).
;
; Masks: fcNormal=264, fcZero=96, fcInf=516, fcNan=3, fcSubnormal=144,
; fcNeg=60.
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
declare i1 @llvm.is.fpclass.bf16(bfloat, i32)
declare <4 x i1> @llvm.is.fpclass.v4bf16(<4 x bfloat>, i32)
declare <8 x i1> @llvm.is.fpclass.v8bf16(<8 x bfloat>, i32)
declare <16 x i1> @llvm.is.fpclass.v16bf16(<16 x bfloat>, i32)
declare <vscale x 4 x i1> @llvm.is.fpclass.nxv4bf16(<vscale x 4 x bfloat>, i32)
declare bfloat @llvm.canonicalize.bf16(bfloat)
declare <4 x bfloat> @llvm.canonicalize.v4bf16(<4 x bfloat>)
declare <8 x bfloat> @llvm.canonicalize.v8bf16(<8 x bfloat>)
declare bfloat @llvm.fmuladd.bf16(bfloat, bfloat, bfloat)
declare bfloat @llvm.experimental.constrained.fadd.bf16(bfloat, bfloat, metadata, metadata)

; ----- positives -----

define i1 @protected_fpclass_normal(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call i1 @llvm.is.fpclass.bf16(bfloat %a, i32 264)
  ret i1 %r
}

define i1 @protected_fpclass_zero(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call i1 @llvm.is.fpclass.bf16(bfloat %a, i32 96)
  ret i1 %r
}

define i1 @protected_fpclass_inf(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call i1 @llvm.is.fpclass.bf16(bfloat %a, i32 516)
  ret i1 %r
}

define i1 @protected_fpclass_nan(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call i1 @llvm.is.fpclass.bf16(bfloat %a, i32 3)
  ret i1 %r
}

define i1 @protected_fpclass_subnormal(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call i1 @llvm.is.fpclass.bf16(bfloat %a, i32 144)
  ret i1 %r
}

define i1 @protected_fpclass_neg(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call i1 @llvm.is.fpclass.bf16(bfloat %a, i32 60)
  ret i1 %r
}


define <4 x i1> @protected_fpclass_v4(<4 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i1> @llvm.is.fpclass.v4bf16(<4 x bfloat> %a, i32 3)
  ret <4 x i1> %r
}

define <8 x i1> @protected_fpclass_v8(<8 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <8 x i1> @llvm.is.fpclass.v8bf16(<8 x bfloat> %a, i32 96)
  ret <8 x i1> %r
}

define bfloat @protected_canonicalize(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.canonicalize.bf16(bfloat %a)
  ret bfloat %r
}

define <4 x bfloat> @protected_canonicalize_v4(<4 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x bfloat> @llvm.canonicalize.v4bf16(<4 x bfloat> %a)
  ret <4 x bfloat> %r
}

define <8 x bfloat> @protected_canonicalize_v8(<8 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <8 x bfloat> @llvm.canonicalize.v8bf16(<8 x bfloat> %a)
  ret <8 x bfloat> %r
}

; Runtime select keeps signed-zero / NaN shapes live under O2.
define bfloat @protected_canonicalize_negzero(i1 %c) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %z = select i1 %c, bfloat 0xR8000, bfloat 0xR0000
  %r = call bfloat @llvm.canonicalize.bf16(bfloat %z)
  ret bfloat %r
}

define bfloat @protected_canonicalize_nan(i1 %c, bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %n = select i1 %c, bfloat 0xR7FC0, bfloat %a
  %r = call bfloat @llvm.canonicalize.bf16(bfloat %n)
  ret bfloat %r
}

define i1 @protected_last_token(bfloat %a) noinline optnone "target-features"="+neon,+bf16" {
entry:
  call void @hikari_vmp()
  %r = call i1 @llvm.is.fpclass.bf16(bfloat %a, i32 264)
  ret i1 %r
}

define bfloat @protected_mix(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %c = call bfloat @llvm.canonicalize.bf16(bfloat %a)
  %ok = call i1 @llvm.is.fpclass.bf16(bfloat %c, i32 264)
  %r = select i1 %ok, bfloat %c, bfloat %a
  ret bfloat %r
}

; ----- negatives -----

define i32 @unsupported_fpclass_no_feature() noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i1 @llvm.is.fpclass.bf16(bfloat 0xR3F80, i32 264)
  %z = zext i1 %r to i32
  ret i32 %z
}

define i32 @unsupported_fpclass_disabled() noinline optnone "target-features"="+neon,+bf16,-bf16" {
entry:
  call void @hikari_vmp()
  %r = call i1 @llvm.is.fpclass.bf16(bfloat 0xR3F80, i32 264)
  %z = zext i1 %r to i32
  ret i32 %z
}

define i32 @unsupported_canon_no_feature() noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.canonicalize.bf16(bfloat 0xR3F80)
  %b = bitcast bfloat %r to i16
  %z = zext i16 %b to i32
  ret i32 %z
}

define i32 @unsupported_canon_bf16fml_only() noinline optnone "target-features"="+bf16fml" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.canonicalize.bf16(bfloat 0xR3F80)
  %b = bitcast bfloat %r to i16
  %z = zext i16 %b to i32
  ret i32 %z
}

define bfloat @unsupported_canon_fmf(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call nnan bfloat @llvm.canonicalize.bf16(bfloat %a)
  ret bfloat %r
}

define i1 @unsupported_fpclass_fastcc(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call fastcc i1 @llvm.is.fpclass.bf16(bfloat %a, i32 264)
  ret i1 %r
}

define i1 @unsupported_fpclass_musttail(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = musttail call i1 @llvm.is.fpclass.bf16(bfloat %a, i32 264)
  ret i1 %r
}

define i1 @unsupported_fpclass_bundle(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call i1 @llvm.is.fpclass.bf16(bfloat %a, i32 264) [ "deopt"() ]
  ret i1 %r
}

define i1 @unsupported_fpclass_poison() noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call i1 @llvm.is.fpclass.bf16(bfloat poison, i32 3)
  ret i1 %r
}

define bfloat @unsupported_canon_undef() noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.canonicalize.bf16(bfloat undef)
  ret bfloat %r
}

define i32 @unsupported_fpclass_wide() noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <16 x i1> @llvm.is.fpclass.v16bf16(<16 x bfloat> zeroinitializer, i32 3)
  %e = extractelement <16 x i1> %r, i32 0
  %z = zext i1 %e to i32
  ret i32 %z
}

define i32 @unsupported_fpclass_scalable() noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i1> @llvm.is.fpclass.nxv4bf16(<vscale x 4 x bfloat> zeroinitializer, i32 3)
  %e = extractelement <vscale x 4 x i1> %r, i32 0
  %z = zext i1 %e to i32
  ret i32 %z
}

define bfloat @unsupported_constrained(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.experimental.constrained.fadd.bf16(bfloat %a, bfloat %a, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret bfloat %r
}

define bfloat @unsupported_fmuladd(bfloat %a, bfloat %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.experimental.constrained.fadd.bf16(bfloat %a, bfloat %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret bfloat %r
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_fpclass_no_feature: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_fpclass_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_canon_no_feature: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_canon_bf16fml_only: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_canon_fmf: unsupported float call instruction
; SKIP-DAG: Skipping VMP on unsupported_fpclass_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_fpclass_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_fpclass_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_fpclass_poison: unsupported call
; SKIP-DAG: Skipping VMP on unsupported_canon_undef: unsupported call
; SKIP-DAG: Skipping VMP on unsupported_fpclass_wide: unsupported call
; SKIP-DAG: Skipping VMP on unsupported_fpclass_scalable: unsupported call
; SKIP-DAG: Skipping VMP on unsupported_constrained: unsupported call
; SKIP-DAG: Skipping VMP on unsupported_fmuladd: unsupported call
; SKIP-NOT: Skipping VMP on protected_fpclass_normal:
; SKIP-NOT: Skipping VMP on protected_fpclass_zero:
; SKIP-NOT: Skipping VMP on protected_fpclass_inf:
; SKIP-NOT: Skipping VMP on protected_fpclass_nan:
; SKIP-NOT: Skipping VMP on protected_fpclass_subnormal:
; SKIP-NOT: Skipping VMP on protected_fpclass_neg:
; SKIP-NOT: Skipping VMP on protected_fpclass_v4:
; SKIP-NOT: Skipping VMP on protected_fpclass_v8:
; SKIP-NOT: Skipping VMP on protected_canonicalize:
; SKIP-NOT: Skipping VMP on protected_canonicalize_v4:
; SKIP-NOT: Skipping VMP on protected_canonicalize_v8:
; SKIP-NOT: Skipping VMP on protected_canonicalize_negzero:
; SKIP-NOT: Skipping VMP on protected_canonicalize_nan:
; SKIP-NOT: Skipping VMP on protected_last_token:
; SKIP-NOT: Skipping VMP on protected_mix:

; VIRT: define i1 @protected_fpclass_normal({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.is.fpclass.bf16
; VIRT-DAG: shl{{.*}} i32
; VIRT: call i1 @llvm.is.fpclass.f32({{.*}}, i32 264)
; VIRT: define i1 @protected_fpclass_zero({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.is.fpclass.bf16
; VIRT: call i1 @llvm.is.fpclass.f32({{.*}}, i32 96)
; VIRT: define i1 @protected_fpclass_inf({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i1 @llvm.is.fpclass.f32({{.*}}, i32 516)
; VIRT: define i1 @protected_fpclass_nan({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i1 @llvm.is.fpclass.f32({{.*}}, i32 3)
; VIRT: define i1 @protected_fpclass_subnormal({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i1 @llvm.is.fpclass.f32({{.*}}, i32 144)
; VIRT: define i1 @protected_fpclass_neg({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i1 @llvm.is.fpclass.f32({{.*}}, i32 60)
; VIRT: define <4 x i1> @protected_fpclass_v4({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.is.fpclass.v4bf16
; VIRT: call i1 @llvm.is.fpclass.f32({{.*}}, i32 3)
; VIRT: define <8 x i1> @protected_fpclass_v8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.is.fpclass.v8bf16
; VIRT: call i1 @llvm.is.fpclass.f32({{.*}}, i32 96)
; VIRT: define bfloat @protected_canonicalize({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.canonicalize.bf16
; VIRT-NOT: call{{.*}}@llvm.canonicalize.f32
; VIRT: fmul{{.*}} float
; VIRT: icmp eq i32 {{.*}}, 2139095040
; VIRT: define <4 x bfloat> @protected_canonicalize_v4({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.canonicalize.v4bf16
; VIRT-NOT: call{{.*}}@llvm.canonicalize.f32
; VIRT: fmul{{.*}} float
; VIRT: define <8 x bfloat> @protected_canonicalize_v8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.canonicalize.v8bf16
; VIRT: fmul{{.*}} float
; VIRT: define bfloat @protected_canonicalize_negzero({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.canonicalize
; VIRT: fmul{{.*}} float
; VIRT: define bfloat @protected_canonicalize_nan({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.canonicalize
; VIRT: fmul{{.*}} float
; VIRT: icmp eq i32 {{.*}}, 2139095040
; VIRT: or i32 {{.*}}, 64
; VIRT: define i1 @protected_last_token({{.*}} #[[PROTLAST:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call i1 @llvm.is.fpclass.f32({{.*}}, i32 264)
; VIRT: define bfloat @protected_mix({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.canonicalize.bf16
; VIRT-NOT: call{{.*}}@llvm.is.fpclass.bf16
; VIRT-DAG: fmul{{.*}} float
; VIRT-DAG: call i1 @llvm.is.fpclass.f32
; VIRT: define {{.*}} @unsupported_fpclass_no_feature({{.*}} #[[UNSUPFEAT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fpclass_disabled({{.*}} #[[UNSUPDIS:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_canon_no_feature({{.*}} #[[UNSUPFEAT]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_canon_bf16fml_only({{.*}} #[[UNSUPFML:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_canon_fmf({{.*}} #[[UNSUPFMF:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call nnan bfloat @llvm.canonicalize.bf16(
; VIRT: define {{.*}} @unsupported_fpclass_fastcc({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fpclass_musttail({{.*}} #[[UNSUPMUST:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fpclass_bundle({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fpclass_poison({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_canon_undef({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fpclass_wide({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fpclass_scalable({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_constrained({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fmuladd({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPFMF]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT: attributes #[[PROTLAST]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPFEAT]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT: attributes #[[UNSUPDIS]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT: attributes #[[UNSUPFML]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT: attributes #[[UNSUPMUST]] = { noinline optnone "target-features"="+bf16" }
; VIRT-NOT: attributes #[[UNSUPFEAT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPDIS]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPFMF]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPMUST]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPMUST]] = { {{.*}}"hikari.vmp.selected"

; AARCH64: Arch: aarch64
