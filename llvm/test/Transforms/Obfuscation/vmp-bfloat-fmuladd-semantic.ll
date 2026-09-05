; Last-token +bf16 llvm.fmuladd on scalar bfloat and supported
; fixed 1..128 bfloat vectors.  Exact token only.  Well-shaped
; calls missing or ending in -bf16 skip as unsupported target
; feature and keep hikari.vmp.selected.
;
; LangRef: fmuladd may fuse but need not.  Legalize promotes each
; bfloat operand exactly to f32 and calls llvm.fma.f32 per lane,
; then RNE back.  Never replay llvm.fmuladd.bf16 / .vNbf16, never
; llvm.fmuladd.f32, and never two bfloat rounding steps.  That
; picks the single fused rounding the source semantics allow.
;
; No new VM opcode.  CallDescriptor.LegalizeBFloatMath.  FMF is
; rejected.  Ordinary tail is replayed as a non-tail f32 fma.
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
declare bfloat @llvm.fmuladd.bf16(bfloat, bfloat, bfloat)
declare bfloat @llvm.fma.bf16(bfloat, bfloat, bfloat)
declare <2 x bfloat> @llvm.fmuladd.v2bf16(<2 x bfloat>, <2 x bfloat>, <2 x bfloat>)
declare <4 x bfloat> @llvm.fmuladd.v4bf16(<4 x bfloat>, <4 x bfloat>, <4 x bfloat>)
declare <8 x bfloat> @llvm.fmuladd.v8bf16(<8 x bfloat>, <8 x bfloat>, <8 x bfloat>)
declare <16 x bfloat> @llvm.fmuladd.v16bf16(<16 x bfloat>, <16 x bfloat>, <16 x bfloat>)
declare <vscale x 4 x bfloat> @llvm.fmuladd.nxv4bf16(<vscale x 4 x bfloat>, <vscale x 4 x bfloat>, <vscale x 4 x bfloat>)
declare bfloat @llvm.experimental.constrained.fmuladd.bf16(bfloat, bfloat, bfloat, metadata, metadata)

; ----- positives -----

define bfloat @protected_fmuladd(bfloat %a, bfloat %b, bfloat %c) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.fmuladd.bf16(bfloat %a, bfloat %b, bfloat %c)
  ret bfloat %r
}

define <2 x bfloat> @protected_fmuladd_v2(<2 x bfloat> %a, <2 x bfloat> %b, <2 x bfloat> %c) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <2 x bfloat> @llvm.fmuladd.v2bf16(<2 x bfloat> %a, <2 x bfloat> %b, <2 x bfloat> %c)
  ret <2 x bfloat> %r
}

define <4 x bfloat> @protected_fmuladd_v4(<4 x bfloat> %a, <4 x bfloat> %b, <4 x bfloat> %c) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x bfloat> @llvm.fmuladd.v4bf16(<4 x bfloat> %a, <4 x bfloat> %b, <4 x bfloat> %c)
  ret <4 x bfloat> %r
}

define <8 x bfloat> @protected_fmuladd_v8(<8 x bfloat> %a, <8 x bfloat> %b, <8 x bfloat> %c) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <8 x bfloat> @llvm.fmuladd.v8bf16(<8 x bfloat> %a, <8 x bfloat> %b, <8 x bfloat> %c)
  ret <8 x bfloat> %r
}

; fmuladd and fma both legalize to f32 llvm.fma; fmuladd must not
; become f32 fmuladd or two bfloat rounding steps.
define bfloat @protected_fmuladd_vs_fma(bfloat %a, bfloat %b, bfloat %c) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %m = call bfloat @llvm.fmuladd.bf16(bfloat %a, bfloat %b, bfloat %c)
  %f = call bfloat @llvm.fma.bf16(bfloat %a, bfloat %b, bfloat %c)
  %r = fadd bfloat %m, %f
  ret bfloat %r
}

; Runtime NaN / -0 / Inf keep special-value shapes live under O2.
define bfloat @protected_fmuladd_special(i1 %c, bfloat %a, bfloat %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %nan = select i1 %c, bfloat 0xR7FC0, bfloat %a
  %n0 = select i1 %c, bfloat 0xR8000, bfloat %b
  %inf = select i1 %c, bfloat 0xR7F80, bfloat %a
  %r = call bfloat @llvm.fmuladd.bf16(bfloat %nan, bfloat %n0, bfloat %inf)
  ret bfloat %r
}


define bfloat @protected_last_token(bfloat %a, bfloat %b, bfloat %c) noinline optnone "target-features"="+neon,+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.fmuladd.bf16(bfloat %a, bfloat %b, bfloat %c)
  ret bfloat %r
}

; ----- negatives -----

define i32 @unsupported_fmuladd_no_feature(i16 %a, i16 %b, i16 %c) noinline optnone {
entry:
  call void @hikari_vmp()
  %x = bitcast i16 %a to bfloat
  %y = bitcast i16 %b to bfloat
  %z = bitcast i16 %c to bfloat
  %r = call bfloat @llvm.fmuladd.bf16(bfloat %x, bfloat %y, bfloat %z)
  %t = bitcast bfloat %r to i16
  %w = zext i16 %t to i32
  ret i32 %w
}

define i32 @unsupported_fmuladd_disabled(i16 %a, i16 %b, i16 %c) noinline optnone "target-features"="+neon,+bf16,-bf16" {
entry:
  call void @hikari_vmp()
  %x = bitcast i16 %a to bfloat
  %y = bitcast i16 %b to bfloat
  %z = bitcast i16 %c to bfloat
  %r = call bfloat @llvm.fmuladd.bf16(bfloat %x, bfloat %y, bfloat %z)
  %t = bitcast bfloat %r to i16
  %w = zext i16 %t to i32
  ret i32 %w
}

define bfloat @unsupported_fmuladd_fmf(bfloat %a, bfloat %b, bfloat %c) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call nnan bfloat @llvm.fmuladd.bf16(bfloat %a, bfloat %b, bfloat %c)
  ret bfloat %r
}

define bfloat @unsupported_fmuladd_fastcc(bfloat %a, bfloat %b, bfloat %c) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call fastcc bfloat @llvm.fmuladd.bf16(bfloat %a, bfloat %b, bfloat %c)
  ret bfloat %r
}

define bfloat @unsupported_fmuladd_musttail(bfloat %a, bfloat %b, bfloat %c) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = musttail call bfloat @llvm.fmuladd.bf16(bfloat %a, bfloat %b, bfloat %c)
  ret bfloat %r
}

define bfloat @unsupported_fmuladd_bundle(bfloat %a, bfloat %b, bfloat %c) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.fmuladd.bf16(bfloat %a, bfloat %b, bfloat %c) [ "deopt"() ]
  ret bfloat %r
}

define bfloat @unsupported_fmuladd_poison(bfloat %a, bfloat %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.fmuladd.bf16(bfloat %a, bfloat %b, bfloat poison)
  ret bfloat %r
}

define bfloat @unsupported_fmuladd_undef(bfloat %a, bfloat %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.fmuladd.bf16(bfloat %a, bfloat %b, bfloat undef)
  ret bfloat %r
}

define bfloat @unsupported_constrained(bfloat %a, bfloat %b, bfloat %c) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.experimental.constrained.fmuladd.bf16(bfloat %a, bfloat %b, bfloat %c, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret bfloat %r
}

define <16 x bfloat> @unsupported_wide(<16 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <16 x bfloat> @llvm.fmuladd.v16bf16(<16 x bfloat> %a, <16 x bfloat> %a, <16 x bfloat> %a)
  ret <16 x bfloat> %r
}

define i32 @unsupported_scalable() noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x bfloat> @llvm.fmuladd.nxv4bf16(<vscale x 4 x bfloat> zeroinitializer, <vscale x 4 x bfloat> zeroinitializer, <vscale x 4 x bfloat> zeroinitializer)
  ret i32 0
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_fmuladd_no_feature: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_fmuladd_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_fmuladd_fmf: unsupported float call instruction
; SKIP-DAG: Skipping VMP on unsupported_fmuladd_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_fmuladd_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_fmuladd_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_fmuladd_poison: unsupported call
; SKIP-DAG: Skipping VMP on unsupported_fmuladd_undef: unsupported call
; SKIP-DAG: Skipping VMP on unsupported_constrained: unsupported call
; SKIP-DAG: Skipping VMP on unsupported_wide: unsupported
; SKIP-DAG: Skipping VMP on unsupported_scalable: unsupported call
; SKIP-NOT: Skipping VMP on protected_fmuladd:
; SKIP-NOT: Skipping VMP on protected_fmuladd_v2:
; SKIP-NOT: Skipping VMP on protected_fmuladd_v4:
; SKIP-NOT: Skipping VMP on protected_fmuladd_v8:
; SKIP-NOT: Skipping VMP on protected_fmuladd_vs_fma:
; SKIP-NOT: Skipping VMP on protected_fmuladd_special:
; SKIP-NOT: Skipping VMP on protected_last_token:

; VIRT: define bfloat @protected_fmuladd({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.fmuladd.bf16
; VIRT-NOT: call{{.*}}@llvm.fmuladd.f32
; VIRT-NOT: fmul{{.*}}bfloat
; VIRT-NOT: fadd{{.*}}bfloat
; VIRT-DAG: shl{{.*}} i32
; VIRT: call float @llvm.fma.f32
; VIRT: icmp eq i32 {{.*}}, 2139095040
; VIRT: define <2 x bfloat> @protected_fmuladd_v2({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.fmuladd.v2bf16
; VIRT-NOT: call{{.*}}@llvm.fmuladd
; VIRT: call float @llvm.fma.f32
; VIRT: define <4 x bfloat> @protected_fmuladd_v4({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.fmuladd.v4bf16
; VIRT-NOT: call{{.*}}@llvm.fmuladd
; VIRT: call float @llvm.fma.f32
; VIRT: define <8 x bfloat> @protected_fmuladd_v8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.fmuladd.v8bf16
; VIRT-NOT: call{{.*}}@llvm.fmuladd
; VIRT: call float @llvm.fma.f32
; VIRT: define bfloat @protected_fmuladd_vs_fma({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.fmuladd
; VIRT-NOT: call{{.*}}@llvm.fma.bf16
; VIRT-NOT: fadd{{.*}}bfloat
; VIRT-DAG: call float @llvm.fma.f32
; VIRT-DAG: fadd{{.*}} float
; VIRT: define bfloat @protected_fmuladd_special({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.fmuladd
; VIRT: call float @llvm.fma.f32
; VIRT: icmp eq i32 {{.*}}, 2139095040
; VIRT: or i32 {{.*}}, 64
; VIRT: define bfloat @protected_last_token({{.*}} #[[PROTLAST:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.fma.f32
; VIRT: define {{.*}} @unsupported_fmuladd_no_feature({{.*}} #[[UNSUPFEAT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fmuladd_disabled({{.*}} #[[UNSUPDIS:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fmuladd_fmf({{.*}} #[[UNSUPFMF:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call nnan bfloat @llvm.fmuladd.bf16(
; VIRT: define {{.*}} @unsupported_fmuladd_fastcc({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fmuladd_musttail({{.*}} #[[UNSUPMUST:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fmuladd_bundle({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fmuladd_poison({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fmuladd_undef({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_constrained({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_wide({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_scalable({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPFMF]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT: attributes #[[PROTLAST]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPFEAT]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT: attributes #[[UNSUPDIS]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT: attributes #[[UNSUPMUST]] = { noinline optnone "target-features"="+bf16" }
; VIRT-NOT: attributes #[[UNSUPFEAT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPDIS]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPFMF]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPMUST]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPMUST]] = { {{.*}}"hikari.vmp.selected"

; AARCH64: Arch: aarch64
