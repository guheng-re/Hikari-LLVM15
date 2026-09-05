; Restricted AArch64 NEON BF16 conversion via CallDescriptor /
; existing scalar-bfloat and bfloat-vector VRegs (no
; LegalizeBFloatMath, no fptrunc/fpext, no new opcode):
;   llvm.aarch64.neon.bfcvt
;     DefaultAttrsIntrinsic: bfloat(float)
;     ISel BFCVT under HasNEONorSME+HasBF16: bfcvt h, s
;   llvm.aarch64.neon.bfcvtn
;     DefaultAttrsIntrinsic: <8 x bfloat>(<4 x float>)
;     ISel BFCVTN under HasNEON+HasBF16: bfcvtn v.4h, v.4s
;     (low 4 lanes; high half zeroed)
;   llvm.aarch64.neon.bfcvtn2
;     DefaultAttrsIntrinsic: <8 x bfloat>(<8 x bfloat>, <4 x float>)
;     ISel BFCVTN2 tied dest: bfcvtn2 v.8h, v.4s
;     (operand 0 is the preserved low half)
; ARM BFCVT is round-to-odd and mayRaiseFPException=1.  Must replay
; the native ID.  Last-token function +bf16 required; missing or
; final -bf16, +bf16fml, +i8mm, and +dotprod do not count.
; Command-line -mattr is never consulted.  Exact C non-vararg.
; Ordinary tail accepted and replayed as non-tail; see vmp-direct-call-tail-eligibility-semantic.ll.  Non-overloaded:
; half/f64/v8f32 substitutions are verifier-illegal.  SVE
; fcvt.bf16f32 / fcvtnt stay out.  Do not fold bfloat into
; isSupportedFixedVectorType.
;
; Host cannot select these AArch64 intrinsics; no lli.
; FileCheck + AArch64 llc/readobj/asm (-mattr=+bf16).  O0/O2 x 97/7.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.ll -o %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+bf16 -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+bf16 %t.o0.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.ll -o %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+bf16 -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+bf16 %t.o2.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.s7.ll -o %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+bf16 -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+bf16 %t.o0.s7.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.s7.ll -o %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+bf16 -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+bf16 %t.o2.s7.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %s | opt -S -verify-each -aesSeed=97 -passes='default<O0>' - 2>&1 | FileCheck %s --check-prefix=HOST

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare void @ext_sret_byval(ptr sret(i32), ptr byval(i32))
declare bfloat @llvm.aarch64.neon.bfcvt(float)
declare <8 x bfloat> @llvm.aarch64.neon.bfcvtn(<4 x float>)
declare <8 x bfloat> @llvm.aarch64.neon.bfcvtn2(<8 x bfloat>, <4 x float>)
declare <vscale x 8 x bfloat> @llvm.aarch64.sve.fcvt.bf16f32(<vscale x 8 x bfloat>, <vscale x 8 x i1>, <vscale x 4 x float>)

@sink_f32 = global float 0.0, align 4
@sink_bf16 = global bfloat 0xR0000, align 2
@sink_v4f32 = global <4 x float> zeroinitializer, align 16
@sink_v8bf16 = global <8 x bfloat> zeroinitializer, align 16

define bfloat @protected_bfcvt(float %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.aarch64.neon.bfcvt(float %a)
  ret bfloat %r
}

define <8 x bfloat> @protected_bfcvtn(<4 x float> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <8 x bfloat> @llvm.aarch64.neon.bfcvtn(<4 x float> %a)
  ret <8 x bfloat> %r
}

; Tied dest: operand 0 is the inactive low half and must be replayed.
define <8 x bfloat> @protected_bfcvtn2(<8 x bfloat> %inactive, <4 x float> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <8 x bfloat> @llvm.aarch64.neon.bfcvtn2(<8 x bfloat> %inactive, <4 x float> %a)
  ret <8 x bfloat> %r
}

define bfloat @protected_bfcvt_last_bf16(float %a) noinline optnone "target-features"="+neon,+bf16fml,+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.aarch64.neon.bfcvt(float %a)
  ret bfloat %r
}

; Feature miss uses integer results / bitcast so the existing bfloat
; formal/return gate is not the first reject.  Skip is unsupported
; target feature.
define i16 @unsupported_no_bf16(float %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.aarch64.neon.bfcvt(float %a)
  %i = bitcast bfloat %r to i16
  ret i16 %i
}

define <8 x i16> @unsupported_bf16_disabled(<4 x float> %a) noinline optnone "target-features"="+bf16,-bf16" {
entry:
  call void @hikari_vmp()
  %r = call <8 x bfloat> @llvm.aarch64.neon.bfcvtn(<4 x float> %a)
  %i = bitcast <8 x bfloat> %r to <8 x i16>
  ret <8 x i16> %i
}

define i16 @unsupported_bf16fml_only(float %a) noinline optnone "target-features"="+bf16fml" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.aarch64.neon.bfcvt(float %a)
  %i = bitcast bfloat %r to i16
  ret i16 %i
}

; Malformed high-half: poison tied low half is not a supported operand.
define <8 x bfloat> @unsupported_poison_low(<4 x float> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <8 x bfloat> @llvm.aarch64.neon.bfcvtn2(<8 x bfloat> poison, <4 x float> %a)
  ret <8 x bfloat> %r
}

define <vscale x 8 x bfloat> @unsupported_sve_bfcvt(<vscale x 8 x bfloat> %inactive, <vscale x 8 x i1> %pg, <vscale x 4 x float> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 8 x bfloat> @llvm.aarch64.sve.fcvt.bf16f32(<vscale x 8 x bfloat> %inactive, <vscale x 8 x i1> %pg, <vscale x 4 x float> %a)
  ret <vscale x 8 x bfloat> %r
}

define bfloat @unsupported_fastcc(float %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call fastcc bfloat @llvm.aarch64.neon.bfcvt(float %a)
  ret bfloat %r
}


define bfloat @unsupported_musttail(float %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = musttail call bfloat @llvm.aarch64.neon.bfcvt(float %a)
  ret bfloat %r
}

define bfloat @unsupported_bundle(float %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.aarch64.neon.bfcvt(float %a) [ "deopt"(i32 0) ]
  ret bfloat %r
}

define bfloat @unsupported_noreturn(float %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.aarch64.neon.bfcvt(float %a) noreturn
  ret bfloat %r
}

define bfloat @unsupported_returns_twice(float %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.aarch64.neon.bfcvt(float %a) returns_twice
  ret bfloat %r
}

define void @unsupported_sret(ptr sret(i32) %p, ptr byval(i32) %q) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  call void @ext_sret_byval(ptr sret(i32) %p, ptr byval(i32) %q)
  ret void
}

define bfloat @unsupported_fmf(float %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call nnan bfloat @llvm.aarch64.neon.bfcvt(float %a)
  ret bfloat %r
}

define i32 @main() {
entry:
  %a = load volatile float, ptr @sink_f32, align 4
  %r0 = call bfloat @protected_bfcvt(float %a)
  store volatile bfloat %r0, ptr @sink_bf16, align 2
  %v = load volatile <4 x float>, ptr @sink_v4f32, align 16
  %r1 = call <8 x bfloat> @protected_bfcvtn(<4 x float> %v)
  store volatile <8 x bfloat> %r1, ptr @sink_v8bf16, align 16
  %lo = load volatile <8 x bfloat>, ptr @sink_v8bf16, align 16
  %r2 = call <8 x bfloat> @protected_bfcvtn2(<8 x bfloat> %lo, <4 x float> %v)
  store volatile <8 x bfloat> %r2, ptr @sink_v8bf16, align 16
  %r3 = call bfloat @protected_bfcvt_last_bf16(float %a)
  store volatile bfloat %r3, ptr @sink_bf16, align 2
  ret i32 0
}

; SKIP-DAG: Skipping VMP on unsupported_no_bf16: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_bf16_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_bf16fml_only: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_poison_low: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_sve_bfcvt: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_noreturn: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_returns_twice: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_sret: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_fmf: unsupported float call instruction
; SKIP-NOT: Skipping VMP on protected_bfcvt:
; SKIP-NOT: Skipping VMP on protected_bfcvtn:
; SKIP-NOT: Skipping VMP on protected_bfcvtn2:
; SKIP-NOT: Skipping VMP on protected_bfcvt_last_bf16:

; VIRT: define bfloat @protected_bfcvt({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call bfloat @llvm.aarch64.neon.bfcvt(
; VIRT: define <8 x bfloat> @protected_bfcvtn({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x bfloat> @llvm.aarch64.neon.bfcvtn(
; VIRT: define <8 x bfloat> @protected_bfcvtn2({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x bfloat> @llvm.aarch64.neon.bfcvtn2(<8 x bfloat> %{{.*}}, <4 x float> %{{.*}})
; VIRT: define bfloat @protected_bfcvt_last_bf16({{.*}} #[[LAST:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call bfloat @llvm.aarch64.neon.bfcvt(
; VIRT: define {{.*}} @unsupported_no_bf16({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT: attributes #[[LAST]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; AARCH64-ASM-DAG: {{^[[:space:]]*}}bfcvt{{[ \t]}}
; AARCH64-ASM-DAG: {{^[[:space:]]*}}bfcvtn{{[ \t]}}
; AARCH64-ASM-DAG: {{^[[:space:]]*}}bfcvtn2{{[ \t]}}
; HOST: Skipping VMP: only AArch64 targets are supported
