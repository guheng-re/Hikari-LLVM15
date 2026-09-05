; Restricted llvm.canonicalize on fixed IEEE half vectors (total 1..128).
; Eligibility only: the planner reuses VectorFMul(x, splat 1.0) with
; packVectorVariant FastMathFlags.  llvm.canonicalize is never
; re-emitted.  Requires last-token function +fullfp16.  Well-shaped
; calls missing or ending in -fullfp16 skip as unsupported target
; feature and keep hikari.vmp.selected.  Does not change scalar half
; canonicalize, or f32/f64 vector canonicalize.  Ordinary tail is
; accepted as ordinary tail and replayed as a non-tail call; see vmp-direct-call-tail-eligibility-semantic.ll.  No dedicated VM opcode.
;
; reference uses the same vector fmul x, 1.0 expansion.  Host x86
; cannot be assumed to select half vector fmul / canonicalize.  This
; lit is FileCheck + AArch64 llc/readobj only (function +fullfp16, no
; global -mattr).  Do not invent a host lli semantic oracle.
;
; Widths: <2 x half>=32, <3 x half>=48, <4 x half>=64, <8 x half>=128.
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
declare <2 x half> @llvm.canonicalize.v2f16(<2 x half>)
declare <3 x half> @llvm.canonicalize.v3f16(<3 x half>)
declare <4 x half> @llvm.canonicalize.v4f16(<4 x half>)
declare <8 x half> @llvm.canonicalize.v8f16(<8 x half>)
declare <4 x bfloat> @llvm.canonicalize.v4bf16(<4 x bfloat>)
declare <vscale x 4 x half> @llvm.canonicalize.nxv4f16(<vscale x 4 x half>)
declare <16 x half> @llvm.canonicalize.v16f16(<16 x half>)

declare <4 x half> @llvm.experimental.constrained.pow.v4f16(<4 x half>, <4 x half>, metadata, metadata)

define <2 x half> @reference_canonicalize_v2f16(<2 x half> %a) {
entry:
  %r = fmul <2 x half> %a, <half 0xH3C00, half 0xH3C00>
  ret <2 x half> %r
}

define <2 x half> @protected_canonicalize_v2f16(<2 x half> %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <2 x half> @llvm.canonicalize.v2f16(<2 x half> %a)
  ret <2 x half> %r
}

define <3 x half> @reference_canonicalize_v3f16(<3 x half> %a) {
entry:
  %r = fmul <3 x half> %a, <half 0xH3C00, half 0xH3C00, half 0xH3C00>
  ret <3 x half> %r
}

define <3 x half> @protected_canonicalize_v3f16(<3 x half> %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <3 x half> @llvm.canonicalize.v3f16(<3 x half> %a)
  ret <3 x half> %r
}

define <4 x half> @reference_canonicalize_v4f16(<4 x half> %a) {
entry:
  %r = fmul <4 x half> %a, <half 0xH3C00, half 0xH3C00, half 0xH3C00, half 0xH3C00>
  ret <4 x half> %r
}

define <4 x half> @protected_canonicalize_v4f16(<4 x half> %a) noinline optnone "target-features"="+neon,+fullfp16,+fp-armv8" {
entry:
  call void @hikari_vmp()
  %r = call <4 x half> @llvm.canonicalize.v4f16(<4 x half> %a)
  ret <4 x half> %r
}

define <8 x half> @reference_canonicalize_v8f16(<8 x half> %a) {
entry:
  %r = fmul <8 x half> %a, <half 0xH3C00, half 0xH3C00, half 0xH3C00, half 0xH3C00, half 0xH3C00, half 0xH3C00, half 0xH3C00, half 0xH3C00>
  ret <8 x half> %r
}

define <8 x half> @protected_canonicalize_v8f16(<8 x half> %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <8 x half> @llvm.canonicalize.v8f16(<8 x half> %a)
  ret <8 x half> %r
}

define <4 x half> @reference_fast_canonicalize_v4f16(<4 x half> %a) {
entry:
  %r = fmul fast <4 x half> %a, <half 0xH3C00, half 0xH3C00, half 0xH3C00, half 0xH3C00>
  ret <4 x half> %r
}

define <4 x half> @protected_fast_canonicalize_v4f16(<4 x half> %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call fast <4 x half> @llvm.canonicalize.v4f16(<4 x half> %a)
  ret <4 x half> %r
}

define <4 x half> @reference_canonicalize_tail_v4f16(<4 x half> %a) {
entry:
  %r = fmul <4 x half> %a, <half 0xH3C00, half 0xH3C00, half 0xH3C00, half 0xH3C00>
  ret <4 x half> %r
}


; Inputs covering +0/-0, +inf, and a quiet NaN payload (FileCheck only).
define <4 x half> @protected_canonicalize_special_v4f16(<4 x half> %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x half> @llvm.canonicalize.v4f16(<4 x half> %a)
  ret <4 x half> %r
}

; ----- negatives: selected, not virtualized -----

define <4 x half> @unsupported_half_canonicalize_no_fullfp16(<4 x half> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x half> @llvm.canonicalize.v4f16(<4 x half> %a)
  ret <4 x half> %r
}

define <4 x half> @unsupported_half_canonicalize_fullfp16_disabled(<4 x half> %a) noinline optnone "target-features"="+neon,+fullfp16,-fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x half> @llvm.canonicalize.v4f16(<4 x half> %a)
  ret <4 x half> %r
}

define <4 x bfloat> @unsupported_half_canonicalize_bfloat(<4 x bfloat> %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x bfloat> @llvm.canonicalize.v4bf16(<4 x bfloat> %a)
  ret <4 x bfloat> %r
}

define <vscale x 4 x half> @unsupported_half_canonicalize_scalable(<vscale x 4 x half> %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x half> @llvm.canonicalize.nxv4f16(<vscale x 4 x half> %a)
  ret <vscale x 4 x half> %r
}

define <16 x half> @unsupported_half_canonicalize_wide(<16 x half> %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <16 x half> @llvm.canonicalize.v16f16(<16 x half> %a)
  ret <16 x half> %r
}

define <4 x half> @unsupported_half_canonicalize_fastcc(<4 x half> %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call fastcc <4 x half> @llvm.canonicalize.v4f16(<4 x half> %a)
  ret <4 x half> %r
}

define <4 x half> @unsupported_half_canonicalize_musttail(<4 x half> %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = musttail call <4 x half> @llvm.canonicalize.v4f16(<4 x half> %a)
  ret <4 x half> %r
}

define <4 x half> @unsupported_half_canonicalize_bundle(<4 x half> %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x half> @llvm.canonicalize.v4f16(<4 x half> %a) [ "deopt"(i32 0) ]
  ret <4 x half> %r
}

define <4 x half> @unsupported_half_canonicalize_constrained(<4 x half> %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x half> @llvm.experimental.constrained.pow.v4f16(<4 x half> %a, <4 x half> %a, metadata !"round.tonearest", metadata !"fpexcept.ignore") [ "deopt"(i32 0) ]
  ret <4 x half> %r
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_half_canonicalize_no_fullfp16: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_half_canonicalize_fullfp16_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_half_canonicalize_bfloat: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_half_canonicalize_scalable: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_half_canonicalize_wide: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_half_canonicalize_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_half_canonicalize_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_half_canonicalize_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_half_canonicalize_constrained: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_canonicalize_v2f16:
; SKIP-NOT: Skipping VMP on protected_canonicalize_v3f16:
; SKIP-NOT: Skipping VMP on protected_canonicalize_v4f16:
; SKIP-NOT: Skipping VMP on protected_canonicalize_v8f16:
; SKIP-NOT: Skipping VMP on protected_fast_canonicalize_v4f16:
; SKIP-NOT: Skipping VMP on protected_canonicalize_special_v4f16:

; VIRT: define <2 x half> @protected_canonicalize_v2f16({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: fmul <2 x half>
; VIRT-NOT: {{call.*@llvm.canonicalize}}
; VIRT: define <3 x half> @protected_canonicalize_v3f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: fmul <3 x half>
; VIRT-NOT: {{call.*@llvm.canonicalize}}
; VIRT: define <4 x half> @protected_canonicalize_v4f16({{.*}} #[[PROT2:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: fmul <4 x half>
; VIRT-NOT: {{call.*@llvm.canonicalize}}
; VIRT: define <8 x half> @protected_canonicalize_v8f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: fmul <8 x half>
; VIRT-NOT: {{call.*@llvm.canonicalize}}
; VIRT: define <4 x half> @protected_fast_canonicalize_v4f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: fmul fast <4 x half>
; VIRT-NOT: {{call.*@llvm.canonicalize}}
; VIRT: define <4 x half> @protected_canonicalize_special_v4f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: fmul <4 x half>
; VIRT-NOT: {{call.*@llvm.canonicalize}}
; VIRT: define {{.*}} @unsupported_half_canonicalize_no_fullfp16({{.*}} #[[UNSUPATTR:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_half_canonicalize_fullfp16_disabled({{.*}} #[[UNSUPFEAT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_half_canonicalize_bfloat({{.*}} #[[UNSUP_RET:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_half_canonicalize_scalable({{.*}} #[[UNSUP_SC:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_half_canonicalize_wide({{.*}} #[[UNSUP_W:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_half_canonicalize_fastcc({{.*}} #[[UNSUPCC:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_half_canonicalize_musttail({{.*}} #[[UNSUP_MT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call <4 x half> @llvm.canonicalize.v4f16(
; VIRT: define {{.*}} @unsupported_half_canonicalize_bundle({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call <4 x half> @llvm.canonicalize.v4f16({{.*}}[ "deopt"(i32 0) ]
; VIRT: define {{.*}} @unsupported_half_canonicalize_constrained({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[PROT2]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT: attributes #[[UNSUPFEAT]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPFEAT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPCC]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_MT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_RET]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_SC]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_W]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
