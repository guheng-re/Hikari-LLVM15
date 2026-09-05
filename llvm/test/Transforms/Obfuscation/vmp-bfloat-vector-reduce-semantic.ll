; Last-token +bf16 llvm.vector.reduce.fadd / fmul / fmin / fmax on
; supported fixed 1..128 bfloat vectors.  Exact token only (+bf16fml
; / +fullfp16 do not count; command-line -mattr is never read).
; Well-shaped listed calls missing or ending in -bf16 skip as
; unsupported target feature and keep hikari.vmp.selected.
;
; No new VM opcode.  CallDescriptor.LegalizeBFloatMath.  Sequential
; no-reassoc fadd/fmul start from the scalar bfloat start value and
; walk lanes 0..N-1: promote both operands, one f32 fadd/fmul, RNE
; back after every step.  Never f32-accumulate-then-one-RNE, never
; replay llvm.vector.reduce.*.bf16 / *.f32.  fmin/fmax reuse the
; existing bfloat minnum/maxnum legalize per remaining lane (N=1 is
; extract only) so NaN and signed-zero follow that surface.
;
; FMF including reassoc, musttail, bundles, noreturn,
; returns_twice, non-C, vararg, constrained, vp.reduce, non-bfloat,
; scalable, overwide, poison/undef, and missing / last-token -bf16
; stay closed.
;
; Host x86 cannot be assumed to select bfloat.  This lit is
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
declare bfloat @llvm.vector.reduce.fadd.v1bf16(bfloat, <1 x bfloat>)
declare bfloat @llvm.vector.reduce.fadd.v2bf16(bfloat, <2 x bfloat>)
declare bfloat @llvm.vector.reduce.fadd.v4bf16(bfloat, <4 x bfloat>)
declare bfloat @llvm.vector.reduce.fmul.v4bf16(bfloat, <4 x bfloat>)
declare bfloat @llvm.vector.reduce.fmin.v1bf16(<1 x bfloat>)
declare bfloat @llvm.vector.reduce.fmin.v4bf16(<4 x bfloat>)
declare bfloat @llvm.vector.reduce.fmax.v4bf16(<4 x bfloat>)
declare bfloat @llvm.vector.reduce.fmax.v8bf16(<8 x bfloat>)
declare bfloat @llvm.vector.reduce.fadd.v16bf16(bfloat, <16 x bfloat>)
declare bfloat @llvm.vector.reduce.fmin.nxv4bf16(<vscale x 4 x bfloat>)
declare bfloat @llvm.vp.reduce.fadd.v4bf16(bfloat, <4 x bfloat>, <4 x i1>, i32)
declare <4 x bfloat> @llvm.experimental.constrained.fadd.v4bf16(<4 x bfloat>, <4 x bfloat>, metadata, metadata)

; ----- positives -----

define bfloat @protected_reduce_fadd_v1(bfloat %s, <1 x bfloat> %v) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.vector.reduce.fadd.v1bf16(bfloat %s, <1 x bfloat> %v)
  ret bfloat %r
}

define bfloat @protected_reduce_fadd_v2(bfloat %s, <2 x bfloat> %v) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.vector.reduce.fadd.v2bf16(bfloat %s, <2 x bfloat> %v)
  ret bfloat %r
}

define bfloat @protected_reduce_fadd_v4(bfloat %s, <4 x bfloat> %v) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.vector.reduce.fadd.v4bf16(bfloat %s, <4 x bfloat> %v)
  ret bfloat %r
}

define bfloat @protected_reduce_fmul_v4(bfloat %s, <4 x bfloat> %v) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.vector.reduce.fmul.v4bf16(bfloat %s, <4 x bfloat> %v)
  ret bfloat %r
}

define bfloat @protected_reduce_fmin_v1(<1 x bfloat> %v) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.vector.reduce.fmin.v1bf16(<1 x bfloat> %v)
  ret bfloat %r
}

define bfloat @protected_reduce_fmin_v4(<4 x bfloat> %v) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.vector.reduce.fmin.v4bf16(<4 x bfloat> %v)
  ret bfloat %r
}

define bfloat @protected_reduce_fmax_v4(<4 x bfloat> %v) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.vector.reduce.fmax.v4bf16(<4 x bfloat> %v)
  ret bfloat %r
}

define bfloat @protected_reduce_fmax_v8(<8 x bfloat> %v) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.vector.reduce.fmax.v8bf16(<8 x bfloat> %v)
  ret bfloat %r
}

; Runtime NaN / -0 keep special-value shapes live under O2.
define bfloat @protected_reduce_special(i1 %c, bfloat %s, <4 x bfloat> %v) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %nan = select i1 %c, bfloat 0xR7FC0, bfloat %s
  %n0 = select i1 %c, bfloat 0xR8000, bfloat %s
  %v0 = insertelement <4 x bfloat> %v, bfloat %n0, i32 0
  %a = call bfloat @llvm.vector.reduce.fadd.v4bf16(bfloat %nan, <4 x bfloat> %v0)
  %m = call bfloat @llvm.vector.reduce.fmin.v4bf16(<4 x bfloat> %v0)
  %r = fadd bfloat %a, %m
  ret bfloat %r
}

define bfloat @protected_last_token(bfloat %s, <4 x bfloat> %v) noinline optnone "target-features"="+neon,+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.vector.reduce.fadd.v4bf16(bfloat %s, <4 x bfloat> %v)
  ret bfloat %r
}

; ----- negatives -----

define i32 @unsupported_reduce_no_feature(i16 %s, <4 x i16> %bits) noinline optnone {
entry:
  call void @hikari_vmp()
  %start = bitcast i16 %s to bfloat
  %v = bitcast <4 x i16> %bits to <4 x bfloat>
  %r = call bfloat @llvm.vector.reduce.fadd.v4bf16(bfloat %start, <4 x bfloat> %v)
  %t = bitcast bfloat %r to i16
  %w = zext i16 %t to i32
  ret i32 %w
}

define i32 @unsupported_reduce_disabled(i16 %s, <4 x i16> %bits) noinline optnone "target-features"="+neon,+bf16,-bf16" {
entry:
  call void @hikari_vmp()
  %start = bitcast i16 %s to bfloat
  %v = bitcast <4 x i16> %bits to <4 x bfloat>
  %r = call bfloat @llvm.vector.reduce.fadd.v4bf16(bfloat %start, <4 x bfloat> %v)
  %t = bitcast bfloat %r to i16
  %w = zext i16 %t to i32
  ret i32 %w
}

define i32 @unsupported_reduce_bf16fml_only(i16 %s, <4 x i16> %bits) noinline optnone "target-features"="+bf16fml" {
entry:
  call void @hikari_vmp()
  %start = bitcast i16 %s to bfloat
  %v = bitcast <4 x i16> %bits to <4 x bfloat>
  %r = call bfloat @llvm.vector.reduce.fadd.v4bf16(bfloat %start, <4 x bfloat> %v)
  %t = bitcast bfloat %r to i16
  %w = zext i16 %t to i32
  ret i32 %w
}

define bfloat @unsupported_reduce_reassoc(bfloat %s, <4 x bfloat> %v) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call reassoc bfloat @llvm.vector.reduce.fadd.v4bf16(bfloat %s, <4 x bfloat> %v)
  ret bfloat %r
}

define bfloat @unsupported_reduce_fast(bfloat %s, <4 x bfloat> %v) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call fast bfloat @llvm.vector.reduce.fmul.v4bf16(bfloat %s, <4 x bfloat> %v)
  ret bfloat %r
}

define bfloat @unsupported_reduce_nnan(<4 x bfloat> %v) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call nnan bfloat @llvm.vector.reduce.fmin.v4bf16(<4 x bfloat> %v)
  ret bfloat %r
}


define bfloat @unsupported_reduce_musttail(bfloat %s, <4 x bfloat> %v) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = musttail call bfloat @llvm.vector.reduce.fadd.v4bf16(bfloat %s, <4 x bfloat> %v)
  ret bfloat %r
}

define bfloat @unsupported_reduce_bundle(bfloat %s, <4 x bfloat> %v) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.vector.reduce.fadd.v4bf16(bfloat %s, <4 x bfloat> %v) [ "deopt"() ]
  ret bfloat %r
}

define bfloat @unsupported_reduce_noreturn(<4 x bfloat> %v) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.vector.reduce.fmin.v4bf16(<4 x bfloat> %v) noreturn
  ret bfloat %r
}

define bfloat @unsupported_reduce_returns_twice(<4 x bfloat> %v) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.vector.reduce.fmax.v4bf16(<4 x bfloat> %v) returns_twice
  ret bfloat %r
}

define bfloat @unsupported_reduce_fastcc(bfloat %s, <4 x bfloat> %v) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call fastcc bfloat @llvm.vector.reduce.fadd.v4bf16(bfloat %s, <4 x bfloat> %v)
  ret bfloat %r
}

define bfloat @unsupported_reduce_poison(bfloat %s, <4 x bfloat> %v) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.vector.reduce.fadd.v4bf16(bfloat %s, <4 x bfloat> poison)
  ret bfloat %r
}

define bfloat @unsupported_reduce_undef(<4 x bfloat> %v) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.vector.reduce.fmin.v4bf16(<4 x bfloat> undef)
  ret bfloat %r
}

define <4 x bfloat> @unsupported_constrained(<4 x bfloat> %a, <4 x bfloat> %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x bfloat> @llvm.experimental.constrained.fadd.v4bf16(<4 x bfloat> %a, <4 x bfloat> %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret <4 x bfloat> %r
}

define bfloat @unsupported_vp(bfloat %s, <4 x bfloat> %v) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.vp.reduce.fadd.v4bf16(bfloat %s, <4 x bfloat> %v, <4 x i1> <i1 true, i1 true, i1 true, i1 true>, i32 4)
  ret bfloat %r
}

define bfloat @unsupported_wide(bfloat %s) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.vector.reduce.fadd.v16bf16(bfloat %s, <16 x bfloat> zeroinitializer)
  ret bfloat %r
}

define i32 @unsupported_scalable() noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.vector.reduce.fmin.nxv4bf16(<vscale x 4 x bfloat> zeroinitializer)
  ret i32 0
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_reduce_no_feature: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_reduce_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_reduce_bf16fml_only: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_reduce_reassoc: unsupported float call instruction
; SKIP-DAG: Skipping VMP on unsupported_reduce_fast: unsupported float call instruction
; SKIP-DAG: Skipping VMP on unsupported_reduce_nnan: unsupported float call instruction
; SKIP-DAG: Skipping VMP on unsupported_reduce_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_reduce_bundle: unsupported vector reduce instruction
; SKIP-DAG: Skipping VMP on unsupported_reduce_noreturn: unsupported vector reduce instruction
; SKIP-DAG: Skipping VMP on unsupported_reduce_returns_twice: unsupported vector reduce instruction
; SKIP-DAG: Skipping VMP on unsupported_reduce_fastcc: unsupported vector reduce instruction
; SKIP-DAG: Skipping VMP on unsupported_reduce_poison: unsupported vector reduce instruction
; SKIP-DAG: Skipping VMP on unsupported_reduce_undef: unsupported vector reduce instruction
; SKIP-DAG: Skipping VMP on unsupported_constrained: unsupported call
; SKIP-DAG: Skipping VMP on unsupported_vp: unsupported vector reduce instruction
; SKIP-DAG: Skipping VMP on unsupported_wide: unsupported vector reduce instruction
; SKIP-DAG: Skipping VMP on unsupported_scalable: unsupported vector reduce instruction
; SKIP-NOT: Skipping VMP on protected_reduce_fadd_v1:
; SKIP-NOT: Skipping VMP on protected_reduce_fadd_v2:
; SKIP-NOT: Skipping VMP on protected_reduce_fadd_v4:
; SKIP-NOT: Skipping VMP on protected_reduce_fmul_v4:
; SKIP-NOT: Skipping VMP on protected_reduce_fmin_v1:
; SKIP-NOT: Skipping VMP on protected_reduce_fmin_v4:
; SKIP-NOT: Skipping VMP on protected_reduce_fmax_v4:
; SKIP-NOT: Skipping VMP on protected_reduce_fmax_v8:
; SKIP-NOT: Skipping VMP on protected_reduce_special:
; SKIP-NOT: Skipping VMP on protected_last_token:

; VIRT: define bfloat @protected_reduce_fadd_v1({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.vector.reduce
; VIRT-NOT: fadd <
; VIRT: fadd float
; VIRT: icmp eq i32 {{.*}}, 2139095040
; VIRT: define bfloat @protected_reduce_fadd_v2({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.vector.reduce
; VIRT-NOT: fadd <
; VIRT: fadd float
; VIRT: icmp eq i32 {{.*}}, 2139095040
; VIRT: fadd float
; VIRT: icmp eq i32 {{.*}}, 2139095040
; VIRT: define bfloat @protected_reduce_fadd_v4({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.vector.reduce
; VIRT-NOT: fadd <
; VIRT: fadd float
; VIRT: icmp eq i32 {{.*}}, 2139095040
; VIRT: fadd float
; VIRT: icmp eq i32 {{.*}}, 2139095040
; VIRT: fadd float
; VIRT: icmp eq i32 {{.*}}, 2139095040
; VIRT: fadd float
; VIRT: icmp eq i32 {{.*}}, 2139095040
; VIRT: define bfloat @protected_reduce_fmul_v4({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.vector.reduce
; VIRT-NOT: fmul <
; VIRT: fmul float
; VIRT: icmp eq i32 {{.*}}, 2139095040
; VIRT: fmul float
; VIRT: icmp eq i32 {{.*}}, 2139095040
; VIRT: fmul float
; VIRT: icmp eq i32 {{.*}}, 2139095040
; VIRT: fmul float
; VIRT: icmp eq i32 {{.*}}, 2139095040
; VIRT: define bfloat @protected_reduce_fmin_v1({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.vector.reduce
; VIRT-NOT: call{{.*}}@llvm.minnum
; VIRT: define bfloat @protected_reduce_fmin_v4({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.vector.reduce
; VIRT-NOT: call{{.*}}@llvm.minnum.bf16
; VIRT: call float @llvm.minnum.f32
; VIRT: icmp eq i32 {{.*}}, 2139095040
; VIRT: call float @llvm.minnum.f32
; VIRT: icmp eq i32 {{.*}}, 2139095040
; VIRT: call float @llvm.minnum.f32
; VIRT: icmp eq i32 {{.*}}, 2139095040
; VIRT: define bfloat @protected_reduce_fmax_v4({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.vector.reduce
; VIRT-NOT: call{{.*}}@llvm.maxnum.bf16
; VIRT: call float @llvm.maxnum.f32
; VIRT: icmp eq i32 {{.*}}, 2139095040
; VIRT: define bfloat @protected_reduce_fmax_v8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.vector.reduce
; VIRT-NOT: call{{.*}}@llvm.maxnum.bf16
; VIRT: call float @llvm.maxnum.f32
; VIRT: icmp eq i32 {{.*}}, 2139095040
; VIRT: call float @llvm.maxnum.f32
; VIRT: define bfloat @protected_reduce_special({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.vector.reduce
; VIRT-NOT: fadd{{.*}}bfloat
; VIRT-DAG: fadd float
; VIRT-DAG: call float @llvm.minnum.f32
; VIRT: icmp eq i32 {{.*}}, 2139095040
; VIRT: or i32 {{.*}}, 64
; VIRT: define bfloat @protected_last_token({{.*}} #[[PROTLAST:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.vector.reduce
; VIRT: fadd float
; VIRT: define {{.*}} @unsupported_reduce_no_feature({{.*}} #[[UNSUPFEAT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_reduce_disabled({{.*}} #[[UNSUPDIS:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_reduce_bf16fml_only({{.*}} #[[UNSUPFML:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_reduce_reassoc({{.*}} #[[UNSUPFMF:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call reassoc bfloat @llvm.vector.reduce.fadd.v4bf16(
; VIRT: define {{.*}} @unsupported_reduce_fast({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_reduce_nnan({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_reduce_musttail({{.*}} #[[UNSUPMUST:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_reduce_bundle({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_reduce_noreturn({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_reduce_returns_twice({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_reduce_fastcc({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_reduce_poison({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_reduce_undef({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_constrained({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_vp({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_wide({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_scalable({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[PROTLAST]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPFEAT]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT: attributes #[[UNSUPDIS]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT: attributes #[[UNSUPFML]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT: attributes #[[UNSUPFMF]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT: attributes #[[UNSUPMUST]] = { noinline optnone "target-features"="+bf16" }
; VIRT-NOT: attributes #[[UNSUPFEAT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPDIS]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPFML]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPFMF]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPMUST]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPMUST]] = { {{.*}}"hikari.vmp.selected"

; AARCH64: Arch: aarch64
