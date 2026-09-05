; Listed last-token +bf16 llvm.fabs / llvm.sqrt / llvm.fma on scalar
; bfloat and supported fixed bfloat vectors (total width 1..128).
; Exact token only (+bf16fml / +fullfp16 do not count; command-line
; -mattr is never read).  Well-shaped listed calls missing or ending
; in -bf16 skip as unsupported target feature and keep
; hikari.vmp.selected.
;
; No new VM opcode.  CallDescriptor.LegalizeBFloatMath: fabs clears
; the i16 sign bit; sqrt/fma promote each operand to f32, call
; llvm.sqrt.f32 / llvm.fma.f32, and RNE back (per-lane on vectors so
; <8 x bfloat> never becomes <8 x float>).  Native llvm.*.bf16 /
; llvm.*.vNbf16 must not reach AArch64 ISel.
;
; Not opened: FastMathFlags, constrained, atomics,
; scalable/>128, poison/undef, invalid signatures, absent or
; last-token -bf16.  minnum/maxnum/minimum/maximum/copysign,
; listed rounding/transcendentals, and pow/powi are independent
; +bf16 surfaces.
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
declare bfloat @llvm.fabs.bf16(bfloat)
declare bfloat @llvm.sqrt.bf16(bfloat)
declare bfloat @llvm.fma.bf16(bfloat, bfloat, bfloat)
declare bfloat @llvm.fmuladd.bf16(bfloat, bfloat, bfloat)
declare bfloat @llvm.canonicalize.bf16(bfloat)
declare bfloat @llvm.experimental.constrained.sqrt.bf16(bfloat, metadata, metadata)
declare bfloat @llvm.experimental.constrained.fadd.bf16(bfloat, bfloat, metadata, metadata)
declare <4 x bfloat> @llvm.experimental.constrained.fadd.v4bf16(<4 x bfloat>, <4 x bfloat>, metadata, metadata)
declare <4 x bfloat> @llvm.fabs.v4bf16(<4 x bfloat>)
declare <4 x bfloat> @llvm.sqrt.v4bf16(<4 x bfloat>)
declare <4 x bfloat> @llvm.fma.v4bf16(<4 x bfloat>, <4 x bfloat>, <4 x bfloat>)
declare <4 x bfloat> @llvm.fmuladd.v4bf16(<4 x bfloat>, <4 x bfloat>, <4 x bfloat>)
declare <8 x bfloat> @llvm.fabs.v8bf16(<8 x bfloat>)
declare <8 x bfloat> @llvm.sqrt.v8bf16(<8 x bfloat>)

; ----- positives -----

define bfloat @protected_fabs(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.fabs.bf16(bfloat %a)
  ret bfloat %r
}

define bfloat @protected_sqrt(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.sqrt.bf16(bfloat %a)
  ret bfloat %r
}

define bfloat @protected_fma(bfloat %a, bfloat %b, bfloat %c) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.fma.bf16(bfloat %a, bfloat %b, bfloat %c)
  ret bfloat %r
}

define bfloat @protected_math_mix(bfloat %a, bfloat %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %x = call bfloat @llvm.fabs.bf16(bfloat %a)
  %y = call bfloat @llvm.sqrt.bf16(bfloat %b)
  %s = fadd bfloat %x, %y
  ret bfloat %s
}

define bfloat @protected_last_token(bfloat %a) noinline optnone "target-features"="-bf16,+neon,+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.fabs.bf16(bfloat %a)
  ret bfloat %r
}

define <4 x bfloat> @protected_fabs_v4(<4 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x bfloat> @llvm.fabs.v4bf16(<4 x bfloat> %a)
  ret <4 x bfloat> %r
}

define <4 x bfloat> @protected_sqrt_v4(<4 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x bfloat> @llvm.sqrt.v4bf16(<4 x bfloat> %a)
  ret <4 x bfloat> %r
}

define <4 x bfloat> @protected_fma_v4(<4 x bfloat> %a, <4 x bfloat> %b, <4 x bfloat> %c) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x bfloat> @llvm.fma.v4bf16(<4 x bfloat> %a, <4 x bfloat> %b, <4 x bfloat> %c)
  ret <4 x bfloat> %r
}

define <8 x bfloat> @protected_sqrt_v8(<8 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <8 x bfloat> @llvm.sqrt.v8bf16(<8 x bfloat> %a)
  ret <8 x bfloat> %r
}

; ----- negatives -----

; Unique feature miss: i16 source is already a supported integer frame.
define i16 @unsupported_fabs_no_feature(i16 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %b = bitcast i16 %a to bfloat
  %r = call bfloat @llvm.fabs.bf16(bfloat %b)
  %s = bitcast bfloat %r to i16
  ret i16 %s
}

define i16 @unsupported_sqrt_disabled(i16 %a) noinline optnone "target-features"="+neon,+bf16,-bf16" {
entry:
  call void @hikari_vmp()
  %b = bitcast i16 %a to bfloat
  %r = call bfloat @llvm.sqrt.bf16(bfloat %b)
  %s = bitcast bfloat %r to i16
  ret i16 %s
}

define bfloat @unsupported_fabs_fmf(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call nnan bfloat @llvm.fabs.bf16(bfloat %a)
  ret bfloat %r
}

define bfloat @unsupported_fmuladd(bfloat %a, bfloat %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.experimental.constrained.fadd.bf16(bfloat %a, bfloat %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret bfloat %r
}

; Listed pow/powi, canonicalize/is.fpclass, and fmuladd are
; independent +bf16 surfaces.  constrained stays closed.
define bfloat @unsupported_minnum(bfloat %a, bfloat %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.experimental.constrained.fadd.bf16(bfloat %a, bfloat %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret bfloat %r
}

define bfloat @unsupported_constrained_sqrt(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.experimental.constrained.sqrt.bf16(bfloat %a, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret bfloat %r
}

define bfloat @unsupported_fabs_poison() noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.fabs.bf16(bfloat poison)
  ret bfloat %r
}

define i64 @unsupported_fabs_v4_no_feature(i64 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %a = bitcast i64 %x to <4 x bfloat>
  %r = call <4 x bfloat> @llvm.fabs.v4bf16(<4 x bfloat> %a)
  %s = bitcast <4 x bfloat> %r to i64
  ret i64 %s
}

define <4 x bfloat> @unsupported_fabs_v4_fmf(<4 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call nnan <4 x bfloat> @llvm.fabs.v4bf16(<4 x bfloat> %a)
  ret <4 x bfloat> %r
}

define <4 x bfloat> @unsupported_fmuladd_v4(<4 x bfloat> %a, <4 x bfloat> %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x bfloat> @llvm.experimental.constrained.fadd.v4bf16(<4 x bfloat> %a, <4 x bfloat> %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret <4 x bfloat> %r
}

define <16 x bfloat> @unsupported_fabs_v16(<16 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  ret <16 x bfloat> %a
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_fabs_no_feature: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_sqrt_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_fabs_fmf: unsupported float call instruction
; SKIP-DAG: Skipping VMP on unsupported_fmuladd: unsupported call
; SKIP-DAG: Skipping VMP on unsupported_minnum: unsupported call
; SKIP-DAG: Skipping VMP on unsupported_constrained_sqrt: unsupported call
; SKIP-DAG: Skipping VMP on unsupported_fabs_poison: unsupported call
; SKIP-DAG: Skipping VMP on unsupported_fabs_v4_no_feature: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_fabs_v4_fmf: unsupported float call instruction
; SKIP-DAG: Skipping VMP on unsupported_fmuladd_v4: unsupported call
; SKIP-DAG: Skipping VMP on unsupported_fabs_v16: unsupported
; SKIP-NOT: Skipping VMP on protected_fabs:
; SKIP-NOT: Skipping VMP on protected_sqrt:
; SKIP-NOT: Skipping VMP on protected_fma:
; SKIP-NOT: Skipping VMP on protected_math_mix:
; SKIP-NOT: Skipping VMP on protected_last_token:
; SKIP-NOT: Skipping VMP on protected_fabs_v4:
; SKIP-NOT: Skipping VMP on protected_sqrt_v4:
; SKIP-NOT: Skipping VMP on protected_fma_v4:
; SKIP-NOT: Skipping VMP on protected_sqrt_v8:

; VIRT: define bfloat @protected_fabs({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.fabs.bf16
; VIRT: and i16 {{.*}}, 32767
; VIRT: define bfloat @protected_sqrt({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.sqrt.bf16
; VIRT: call float @llvm.sqrt.f32
; VIRT: icmp eq i32 {{.*}}, 2139095040
; VIRT: define bfloat @protected_fma({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.fma.bf16
; VIRT: call float @llvm.fma.f32
; VIRT: icmp eq i32 {{.*}}, 2139095040
; VIRT: define bfloat @protected_math_mix({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.fabs.bf16
; VIRT-NOT: call{{.*}}@llvm.sqrt.bf16
; VIRT-NOT: fadd{{.*}}bfloat
; VIRT-DAG: and i16 {{.*}}, 32767
; VIRT-DAG: call float @llvm.sqrt.f32
; VIRT-DAG: fadd{{.*}} float
; VIRT: define bfloat @protected_last_token({{.*}} #[[PROTLAST:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: and i16 {{.*}}, 32767
; VIRT: define <4 x bfloat> @protected_fabs_v4({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.fabs.v4bf16
; VIRT: and <4 x i16>
; VIRT: define <4 x bfloat> @protected_sqrt_v4({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.sqrt.v4bf16
; VIRT: call float @llvm.sqrt.f32
; VIRT: define <4 x bfloat> @protected_fma_v4({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.fma.v4bf16
; VIRT: call float @llvm.fma.f32
; VIRT: define <8 x bfloat> @protected_sqrt_v8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.sqrt.v8bf16
; VIRT: call float @llvm.sqrt.f32
; VIRT: define {{.*}} @unsupported_fabs_no_feature({{.*}} #[[UNSUPFEAT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_sqrt_disabled({{.*}} #[[UNSUPDIS:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fabs_fmf({{.*}} #[[UNSUPFMF:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call nnan bfloat @llvm.fabs.bf16
; VIRT: define {{.*}} @unsupported_fmuladd({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_minnum({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_constrained_sqrt({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fabs_poison({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fabs_v4_no_feature({{.*}} #[[UNSUPFEAT]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fabs_v4_fmf({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call nnan <4 x bfloat> @llvm.fabs.v4bf16
; VIRT: define {{.*}} @unsupported_fmuladd_v4({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fabs_v16({{.*}} #[[UNSUPFMF]] {
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
