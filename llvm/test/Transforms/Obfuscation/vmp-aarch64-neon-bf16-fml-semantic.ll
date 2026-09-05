; Restricted AArch64 NEON BF16 fused multiply-add-long via
; CallDescriptor / existing vector VRegs (no LegalizeBFloatMath,
; no new opcode):
;   llvm.aarch64.neon.bfmlalb / bfmlalt
;     AdvSIMD_BF16FML (non-overloaded):
;       <4 x float>(<4 x float>, <8 x bfloat>, <8 x bfloat>)
;     ISel SIMDBF16MLAL under HasNEON+HasBF16:
;       bfmlalb / bfmlalt  Rd.4s, Rn.8h, Rm.8h
; LLVM 15 AArch64 has no FeatureBF16FML / "+bf16fml".  ISel token
; is exact "bf16".  Last-token function +bf16 required; missing or
; final -bf16, +bf16fml, +i8mm, and +dotprod do not count.
; Command-line -mattr is never consulted.  Exact C non-vararg.
; Ordinary tail accepted and replayed as non-tail; see vmp-direct-call-tail-eligibility-semantic.ll.  No neon.bfmlal*.lane
; IR ID; clang vbfmlalb_lane is splat + the same ID.  bfdot / bfmmla /
; sdot / smmla / SVE stay out.  Half/f32 substitutions are verifier-
; illegal on the non-overloaded ID.  Do not fold bfloat into
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
declare <4 x float> @llvm.aarch64.neon.bfmlalb(<4 x float>, <8 x bfloat>, <8 x bfloat>)
declare <4 x float> @llvm.aarch64.neon.bfmlalt(<4 x float>, <8 x bfloat>, <8 x bfloat>)
declare <4 x i32> @llvm.aarch64.neon.smmla.v4i32.v16i8(<4 x i32>, <16 x i8>, <16 x i8>)
declare <4 x i32> @llvm.aarch64.neon.sdot.v4i32.v16i8(<4 x i32>, <16 x i8>, <16 x i8>)

declare <vscale x 4 x float> @llvm.aarch64.sve.bfmlalb(<vscale x 4 x float>, <vscale x 8 x bfloat>, <vscale x 8 x bfloat>)

@sink_v4f32 = global <4 x float> zeroinitializer, align 16
@sink_v8bf16 = global <8 x bfloat> zeroinitializer, align 16

define <4 x float> @protected_bfmlalb(<4 x float> %acc, <8 x bfloat> %a, <8 x bfloat> %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.bfmlalb(<4 x float> %acc, <8 x bfloat> %a, <8 x bfloat> %b)
  ret <4 x float> %r
}

define <4 x float> @protected_bfmlalt(<4 x float> %acc, <8 x bfloat> %a, <8 x bfloat> %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.bfmlalt(<4 x float> %acc, <8 x bfloat> %a, <8 x bfloat> %b)
  ret <4 x float> %r
}

; clang vbfmlalb_laneq: splat a bfloat lane then the same IR ID.
; No neon.bfmlalb.lane ID.  ISel may fold to BFMLALBIdx.
define <4 x float> @protected_bfmlalb_laneq(<4 x float> %acc, <8 x bfloat> %a, <8 x bfloat> %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %splat = shufflevector <8 x bfloat> %b, <8 x bfloat> undef, <8 x i32> zeroinitializer
  %r = call <4 x float> @llvm.aarch64.neon.bfmlalb(<4 x float> %acc, <8 x bfloat> %a, <8 x bfloat> %splat)
  ret <4 x float> %r
}

define <4 x float> @protected_bfmlalb_last_bf16(<4 x float> %acc, <8 x bfloat> %a, <8 x bfloat> %b) noinline optnone "target-features"="+neon,+crc,+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.bfmlalb(<4 x float> %acc, <8 x bfloat> %a, <8 x bfloat> %b)
  ret <4 x float> %r
}

; Feature miss uses integer formals + bitcast so the existing bfloat
; formal gate is not the first reject.  Skip is unsupported target feature.
define <4 x float> @unsupported_no_bf16(<4 x float> %acc, <8 x i16> %ai, <8 x i16> %bi) noinline optnone {
entry:
  call void @hikari_vmp()
  %a = bitcast <8 x i16> %ai to <8 x bfloat>
  %b = bitcast <8 x i16> %bi to <8 x bfloat>
  %r = call <4 x float> @llvm.aarch64.neon.bfmlalb(<4 x float> %acc, <8 x bfloat> %a, <8 x bfloat> %b)
  ret <4 x float> %r
}

define <4 x float> @unsupported_bf16_disabled(<4 x float> %acc, <8 x i16> %ai, <8 x i16> %bi) noinline optnone "target-features"="+bf16,-bf16" {
entry:
  call void @hikari_vmp()
  %a = bitcast <8 x i16> %ai to <8 x bfloat>
  %b = bitcast <8 x i16> %bi to <8 x bfloat>
  %r = call <4 x float> @llvm.aarch64.neon.bfmlalb(<4 x float> %acc, <8 x bfloat> %a, <8 x bfloat> %b)
  ret <4 x float> %r
}

define <4 x float> @unsupported_bf16fml_only(<4 x float> %acc, <8 x i16> %ai, <8 x i16> %bi) noinline optnone "target-features"="+bf16fml" {
entry:
  call void @hikari_vmp()
  %a = bitcast <8 x i16> %ai to <8 x bfloat>
  %b = bitcast <8 x i16> %bi to <8 x bfloat>
  %r = call <4 x float> @llvm.aarch64.neon.bfmlalb(<4 x float> %acc, <8 x bfloat> %a, <8 x bfloat> %b)
  ret <4 x float> %r
}

define <4 x float> @unsupported_i8mm_only(<4 x float> %acc, <8 x i16> %ai, <8 x i16> %bi) noinline optnone "target-features"="+i8mm" {
entry:
  call void @hikari_vmp()
  %a = bitcast <8 x i16> %ai to <8 x bfloat>
  %b = bitcast <8 x i16> %bi to <8 x bfloat>
  %r = call <4 x float> @llvm.aarch64.neon.bfmlalb(<4 x float> %acc, <8 x bfloat> %a, <8 x bfloat> %b)
  ret <4 x float> %r
}

define <4 x float> @unsupported_dotprod_only(<4 x float> %acc, <8 x i16> %ai, <8 x i16> %bi) noinline optnone "target-features"="+dotprod" {
entry:
  call void @hikari_vmp()
  %a = bitcast <8 x i16> %ai to <8 x bfloat>
  %b = bitcast <8 x i16> %bi to <8 x bfloat>
  %r = call <4 x float> @llvm.aarch64.neon.bfmlalb(<4 x float> %acc, <8 x bfloat> %a, <8 x bfloat> %b)
  ret <4 x float> %r
}

; Well-formed llvm.aarch64.neon.bfdot / bfmmla with last-token +bf16
; is vmp-aarch64-neon-bf16-semantic.ll and must not stay here.

define <4 x i32> @unsupported_smmla(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.smmla.v4i32.v16i8(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b)
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_sdot(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.sdot.v4i32.v16i8(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b)
  ret <4 x i32> %r
}

; Well-formed llvm.aarch64.neon.usdot is
; vmp-aarch64-neon-usdot-semantic.ll.

define <vscale x 4 x float> @unsupported_sve_bfmlalb(<vscale x 4 x float> %acc, <vscale x 8 x bfloat> %a, <vscale x 8 x bfloat> %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x float> @llvm.aarch64.sve.bfmlalb(<vscale x 4 x float> %acc, <vscale x 8 x bfloat> %a, <vscale x 8 x bfloat> %b)
  ret <vscale x 4 x float> %r
}

define <4 x float> @unsupported_fastcc(<4 x float> %acc, <8 x bfloat> %a, <8 x bfloat> %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call fastcc <4 x float> @llvm.aarch64.neon.bfmlalb(<4 x float> %acc, <8 x bfloat> %a, <8 x bfloat> %b)
  ret <4 x float> %r
}


define <4 x float> @unsupported_musttail(<4 x float> %acc, <8 x bfloat> %a, <8 x bfloat> %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = musttail call <4 x float> @llvm.aarch64.neon.bfmlalb(<4 x float> %acc, <8 x bfloat> %a, <8 x bfloat> %b)
  ret <4 x float> %r
}

define <4 x float> @unsupported_bundle(<4 x float> %acc, <8 x bfloat> %a, <8 x bfloat> %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.bfmlalb(<4 x float> %acc, <8 x bfloat> %a, <8 x bfloat> %b) [ "deopt"(i32 0) ]
  ret <4 x float> %r
}

define <4 x float> @unsupported_noreturn(<4 x float> %acc, <8 x bfloat> %a, <8 x bfloat> %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.bfmlalb(<4 x float> %acc, <8 x bfloat> %a, <8 x bfloat> %b) noreturn
  ret <4 x float> %r
}

define <4 x float> @unsupported_returns_twice(<4 x float> %acc, <8 x bfloat> %a, <8 x bfloat> %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.bfmlalb(<4 x float> %acc, <8 x bfloat> %a, <8 x bfloat> %b) returns_twice
  ret <4 x float> %r
}

define i32 @main() {
entry:
  %acc = load volatile <4 x float>, ptr @sink_v4f32, align 16
  %a = load volatile <8 x bfloat>, ptr @sink_v8bf16, align 16
  %b = load volatile <8 x bfloat>, ptr @sink_v8bf16, align 16
  %r0 = call <4 x float> @protected_bfmlalb(<4 x float> %acc, <8 x bfloat> %a, <8 x bfloat> %b)
  store volatile <4 x float> %r0, ptr @sink_v4f32, align 16
  %r1 = call <4 x float> @protected_bfmlalt(<4 x float> %acc, <8 x bfloat> %a, <8 x bfloat> %b)
  store volatile <4 x float> %r1, ptr @sink_v4f32, align 16
  %r2 = call <4 x float> @protected_bfmlalb_laneq(<4 x float> %acc, <8 x bfloat> %a, <8 x bfloat> %b)
  store volatile <4 x float> %r2, ptr @sink_v4f32, align 16
  %r3 = call <4 x float> @protected_bfmlalb_last_bf16(<4 x float> %acc, <8 x bfloat> %a, <8 x bfloat> %b)
  store volatile <4 x float> %r3, ptr @sink_v4f32, align 16
  ret i32 0
}

; SKIP-DAG: Skipping VMP on unsupported_no_bf16: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_bf16_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_bf16fml_only: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_i8mm_only: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_dotprod_only: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_smmla: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_sdot: unsupported target feature

; SKIP-DAG: Skipping VMP on unsupported_sve_bfmlalb: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_noreturn: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_returns_twice: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_bfmlalb:
; SKIP-NOT: Skipping VMP on protected_bfmlalt:
; SKIP-NOT: Skipping VMP on protected_bfmlalb_laneq:
; SKIP-NOT: Skipping VMP on protected_bfmlalb_last_bf16:

; VIRT: define <4 x float> @protected_bfmlalb({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x float> @llvm.aarch64.neon.bfmlalb(
; VIRT: define <4 x float> @protected_bfmlalt({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x float> @llvm.aarch64.neon.bfmlalt(
; VIRT: define <4 x float> @protected_bfmlalb_laneq({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x float> @llvm.aarch64.neon.bfmlalb(
; VIRT: define <4 x float> @protected_bfmlalb_last_bf16({{.*}} #[[LAST:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x float> @llvm.aarch64.neon.bfmlalb(
; VIRT: define {{.*}} @unsupported_no_bf16({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT: attributes #[[LAST]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; AARCH64-ASM: {{^[[:space:]]*}}bfmlalb{{[ \t]}}
; AARCH64-ASM: {{^[[:space:]]*}}bfmlalt{{[ \t]}}
; HOST: Skipping VMP: only AArch64 targets are supported
