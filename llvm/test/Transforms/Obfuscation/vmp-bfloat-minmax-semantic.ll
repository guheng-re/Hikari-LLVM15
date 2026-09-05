; Listed last-token +bf16 llvm.minnum / llvm.maxnum / llvm.minimum /
; llvm.maximum / llvm.copysign on scalar bfloat and supported fixed
; bfloat vectors (total width 1..128).  Exact token only (+bf16fml /
; +fullfp16 do not count; command-line -mattr is never read).
; Well-shaped listed calls missing or ending in -bf16 skip as
; unsupported target feature and keep hikari.vmp.selected.
;
; No new VM opcode.  CallDescriptor.LegalizeBFloatMath: minnum/maxnum/
; minimum/maximum promote each operand to f32, call the matching f32
; intrinsic (so minnum vs IEEE minimum keep NaN / signed-zero rules),
; and RNE back (per-lane on vectors).  copysign is exact i16 sign-bit
; selection.  Native llvm.*.bf16 / llvm.*.vNbf16 must not reach
; AArch64 ISel.
;
; Not opened: FastMathFlags, constrained minmax, atomics,
; transcendentals, scalable/>128, poison/undef, invalid signatures,
; absent or last-token -bf16.
;
; Host x86 cannot be assumed to select bfloat minmax.  This lit is
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
declare bfloat @llvm.minnum.bf16(bfloat, bfloat)
declare bfloat @llvm.maxnum.bf16(bfloat, bfloat)
declare bfloat @llvm.minimum.bf16(bfloat, bfloat)
declare bfloat @llvm.maximum.bf16(bfloat, bfloat)
declare bfloat @llvm.copysign.bf16(bfloat, bfloat)
declare bfloat @llvm.fmuladd.bf16(bfloat, bfloat, bfloat)
declare bfloat @llvm.experimental.constrained.minnum.bf16(bfloat, bfloat, metadata)
declare <4 x bfloat> @llvm.minnum.v4bf16(<4 x bfloat>, <4 x bfloat>)
declare <4 x bfloat> @llvm.minimum.v4bf16(<4 x bfloat>, <4 x bfloat>)
declare <4 x bfloat> @llvm.copysign.v4bf16(<4 x bfloat>, <4 x bfloat>)
declare <4 x bfloat> @llvm.maxnum.v4bf16(<4 x bfloat>, <4 x bfloat>)
declare <8 x bfloat> @llvm.maximum.v8bf16(<8 x bfloat>, <8 x bfloat>)

; ----- positives -----

define bfloat @protected_minnum(bfloat %a, bfloat %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.minnum.bf16(bfloat %a, bfloat %b)
  ret bfloat %r
}

define bfloat @protected_maxnum(bfloat %a, bfloat %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.maxnum.bf16(bfloat %a, bfloat %b)
  ret bfloat %r
}

define bfloat @protected_minimum(bfloat %a, bfloat %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.minimum.bf16(bfloat %a, bfloat %b)
  ret bfloat %r
}

define bfloat @protected_maximum(bfloat %a, bfloat %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.maximum.bf16(bfloat %a, bfloat %b)
  ret bfloat %r
}

define bfloat @protected_copysign(bfloat %a, bfloat %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.copysign.bf16(bfloat %a, bfloat %b)
  ret bfloat %r
}

; Distinct IDs: minnum returns the number if the other is NaN;
; minimum is IEEE and prefers NaN.  Legalize must call the matching
; f32 intrinsic, not collapse both to one helper.
define bfloat @protected_minnum_nan(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.minnum.bf16(bfloat %a, bfloat 0xR7FC0)
  ret bfloat %r
}

define bfloat @protected_minimum_nan(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.minimum.bf16(bfloat %a, bfloat 0xR7FC0)
  ret bfloat %r
}

; Signed-zero shape: copysign(x, -0) is an i16 sign insert of 0x8000.
define bfloat @protected_copysign_negzero(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.copysign.bf16(bfloat %a, bfloat 0xR8000)
  ret bfloat %r
}

define bfloat @protected_minmax_mix(bfloat %a, bfloat %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %m = call bfloat @llvm.minnum.bf16(bfloat %a, bfloat %b)
  %s = fadd bfloat %m, %a
  ret bfloat %s
}

define bfloat @protected_last_token(bfloat %a, bfloat %b) noinline optnone "target-features"="-bf16,+neon,+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.maxnum.bf16(bfloat %a, bfloat %b)
  ret bfloat %r
}

define <4 x bfloat> @protected_minnum_v4(<4 x bfloat> %a, <4 x bfloat> %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x bfloat> @llvm.minnum.v4bf16(<4 x bfloat> %a, <4 x bfloat> %b)
  ret <4 x bfloat> %r
}

define <4 x bfloat> @protected_minimum_v4(<4 x bfloat> %a, <4 x bfloat> %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x bfloat> @llvm.minimum.v4bf16(<4 x bfloat> %a, <4 x bfloat> %b)
  ret <4 x bfloat> %r
}

define <4 x bfloat> @protected_copysign_v4(<4 x bfloat> %a, <4 x bfloat> %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x bfloat> @llvm.copysign.v4bf16(<4 x bfloat> %a, <4 x bfloat> %b)
  ret <4 x bfloat> %r
}

define <8 x bfloat> @protected_maximum_v8(<8 x bfloat> %a, <8 x bfloat> %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <8 x bfloat> @llvm.maximum.v8bf16(<8 x bfloat> %a, <8 x bfloat> %b)
  ret <8 x bfloat> %r
}

; ----- negatives -----

define i16 @unsupported_minnum_no_feature(i16 %a, i16 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %x = bitcast i16 %a to bfloat
  %y = bitcast i16 %b to bfloat
  %r = call bfloat @llvm.minnum.bf16(bfloat %x, bfloat %y)
  %s = bitcast bfloat %r to i16
  ret i16 %s
}

define i16 @unsupported_maxnum_disabled(i16 %a, i16 %b) noinline optnone "target-features"="+neon,+bf16,-bf16" {
entry:
  call void @hikari_vmp()
  %x = bitcast i16 %a to bfloat
  %y = bitcast i16 %b to bfloat
  %r = call bfloat @llvm.maxnum.bf16(bfloat %x, bfloat %y)
  %s = bitcast bfloat %r to i16
  ret i16 %s
}

define bfloat @unsupported_minnum_fmf(bfloat %a, bfloat %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call nnan bfloat @llvm.minnum.bf16(bfloat %a, bfloat %b)
  ret bfloat %r
}

define bfloat @unsupported_copysign_fmf(bfloat %a, bfloat %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call nnan bfloat @llvm.copysign.bf16(bfloat %a, bfloat %b)
  ret bfloat %r
}

define bfloat @unsupported_fmuladd(bfloat %a, bfloat %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.experimental.constrained.minnum.bf16(bfloat %a, bfloat %b, metadata !"fpexcept.ignore")
  ret bfloat %r
}

define bfloat @unsupported_constrained_minnum(bfloat %a, bfloat %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.experimental.constrained.minnum.bf16(bfloat %a, bfloat %b, metadata !"fpexcept.ignore")
  ret bfloat %r
}

define bfloat @unsupported_minnum_poison(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.minnum.bf16(bfloat %a, bfloat poison)
  ret bfloat %r
}

define i64 @unsupported_minnum_v4_no_feature(i64 %x, i64 %y) noinline optnone {
entry:
  call void @hikari_vmp()
  %a = bitcast i64 %x to <4 x bfloat>
  %b = bitcast i64 %y to <4 x bfloat>
  %r = call <4 x bfloat> @llvm.minnum.v4bf16(<4 x bfloat> %a, <4 x bfloat> %b)
  %s = bitcast <4 x bfloat> %r to i64
  ret i64 %s
}

define <4 x bfloat> @unsupported_copysign_v4_fmf(<4 x bfloat> %a, <4 x bfloat> %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call nnan <4 x bfloat> @llvm.copysign.v4bf16(<4 x bfloat> %a, <4 x bfloat> %b)
  ret <4 x bfloat> %r
}

define <16 x bfloat> @unsupported_minnum_v16(<16 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  ret <16 x bfloat> %a
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_minnum_no_feature: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_maxnum_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_minnum_fmf: unsupported float call instruction
; SKIP-DAG: Skipping VMP on unsupported_copysign_fmf: unsupported float call instruction
; SKIP-DAG: Skipping VMP on unsupported_fmuladd: unsupported call
; SKIP-DAG: Skipping VMP on unsupported_constrained_minnum: unsupported call
; SKIP-DAG: Skipping VMP on unsupported_minnum_poison: unsupported call
; SKIP-DAG: Skipping VMP on unsupported_minnum_v4_no_feature: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_copysign_v4_fmf: unsupported float call instruction
; SKIP-DAG: Skipping VMP on unsupported_minnum_v16: unsupported
; SKIP-NOT: Skipping VMP on protected_minnum:
; SKIP-NOT: Skipping VMP on protected_maxnum:
; SKIP-NOT: Skipping VMP on protected_minimum:
; SKIP-NOT: Skipping VMP on protected_maximum:
; SKIP-NOT: Skipping VMP on protected_copysign:
; SKIP-NOT: Skipping VMP on protected_minnum_nan:
; SKIP-NOT: Skipping VMP on protected_minimum_nan:
; SKIP-NOT: Skipping VMP on protected_copysign_negzero:
; SKIP-NOT: Skipping VMP on protected_minmax_mix:
; SKIP-NOT: Skipping VMP on protected_last_token:
; SKIP-NOT: Skipping VMP on protected_minnum_v4:
; SKIP-NOT: Skipping VMP on protected_minimum_v4:
; SKIP-NOT: Skipping VMP on protected_copysign_v4:
; SKIP-NOT: Skipping VMP on protected_maximum_v8:

; VIRT: define bfloat @protected_minnum({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.minnum.bf16
; VIRT: call float @llvm.minnum.f32
; VIRT: icmp eq i32 {{.*}}, 2139095040
; VIRT: define bfloat @protected_maxnum({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.maxnum.bf16
; VIRT: call float @llvm.maxnum.f32
; VIRT: define bfloat @protected_minimum({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.minimum.bf16
; VIRT: call float @llvm.minimum.f32
; VIRT: define bfloat @protected_maximum({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.maximum.bf16
; VIRT: call float @llvm.maximum.f32
; VIRT: define bfloat @protected_copysign({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.copysign.bf16
; VIRT: and i16 {{.*}}, 32767
; VIRT: and i16 {{.*}}, -32768
; VIRT: define bfloat @protected_minnum_nan({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.minnum.bf16
; VIRT-NOT: call float @llvm.minimum.f32
; VIRT: call float @llvm.minnum.f32
; VIRT: define bfloat @protected_minimum_nan({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.minimum.bf16
; VIRT-NOT: call float @llvm.minnum.f32
; VIRT: call float @llvm.minimum.f32
; VIRT: define bfloat @protected_copysign_negzero({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.copysign.bf16
; VIRT: and i16 {{.*}}, -32768
; VIRT: define bfloat @protected_minmax_mix({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.minnum.bf16
; VIRT-NOT: fadd{{.*}}bfloat
; VIRT-DAG: call float @llvm.minnum.f32
; VIRT-DAG: fadd{{.*}} float
; VIRT: define bfloat @protected_last_token({{.*}} #[[PROTLAST:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.maxnum.f32
; VIRT: define <4 x bfloat> @protected_minnum_v4({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.minnum.v4bf16
; VIRT: call float @llvm.minnum.f32
; VIRT: define <4 x bfloat> @protected_minimum_v4({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.minimum.v4bf16
; VIRT: call float @llvm.minimum.f32
; VIRT: define <4 x bfloat> @protected_copysign_v4({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.copysign.v4bf16
; VIRT: and <4 x i16>
; VIRT: define <8 x bfloat> @protected_maximum_v8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.maximum.v8bf16
; VIRT: call float @llvm.maximum.f32
; VIRT: define {{.*}} @unsupported_minnum_no_feature({{.*}} #[[UNSUPFEAT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_maxnum_disabled({{.*}} #[[UNSUPDIS:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_minnum_fmf({{.*}} #[[UNSUPFMF:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call nnan bfloat @llvm.minnum.bf16
; VIRT: define {{.*}} @unsupported_copysign_fmf({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fmuladd({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_constrained_minnum({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_minnum_poison({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_minnum_v4_no_feature({{.*}} #[[UNSUPFEAT]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_copysign_v4_fmf({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call nnan <4 x bfloat> @llvm.copysign.v4bf16
; VIRT: define {{.*}} @unsupported_minnum_v16({{.*}} #[[UNSUPFMF]] {
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
