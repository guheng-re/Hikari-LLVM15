; Restricted AArch64 NEON FP16 fused multiply-add/subtract-long via
; CallDescriptor / existing vector VRegs (no new opcode):
;   llvm.aarch64.neon.fmlal / fmlsl / fmlal2 / fmlsl2
;     AdvSIMD_FP16FML (overloaded)
;     ISel SIMDThreeSameVectorFML under HasNEON+HasFP16FML:
;       <2 x float>(<2 x float>, <4 x half>, <4 x half>)
;         fmlal/fmlsl/fmlal2/fmlsl2  Rd.2s, Rn.2h, Rm.2h
;       <4 x float>(<4 x float>, <8 x half>, <8 x half>)
;         fmlal/fmlsl/fmlal2/fmlsl2  Rd.4s, Rn.4h, Rm.4h
; fmlal/fmlsl are the low half; fmlal2/fmlsl2 are the high half.
; Last-token function +fp16fml required; missing or final -fp16fml,
; +fullfp16, +bf16, +i8mm, and +dotprod do not count.  Command-line
; -mattr is never consulted.  Exact C non-vararg.  Ordinary tail accepted and replayed as non-tail; see vmp-direct-call-tail-eligibility-semantic.ll.  No neon.fmlal.lane IR ID; clang
; vfmlal_lane_* is splat + the same ID.  bfmlalb / bfdot / sdot /
; smmla / SVE stay out.
;
; Host cannot select these AArch64 intrinsics; no lli.
; FileCheck + AArch64 llc/readobj/asm (-mattr=+fp16fml).  O0/O2 x 97/7.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.ll -o %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+fp16fml -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+fp16fml %t.o0.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.ll -o %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+fp16fml -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+fp16fml %t.o2.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.s7.ll -o %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+fp16fml -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+fp16fml %t.o0.s7.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.s7.ll -o %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+fp16fml -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+fp16fml %t.o2.s7.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %s | opt -S -verify-each -aesSeed=97 -passes='default<O0>' - 2>&1 | FileCheck %s --check-prefix=HOST

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare <2 x float> @llvm.aarch64.neon.fmlal.v2f32.v4f16(<2 x float>, <4 x half>, <4 x half>)
declare <2 x float> @llvm.aarch64.neon.fmlsl.v2f32.v4f16(<2 x float>, <4 x half>, <4 x half>)
declare <2 x float> @llvm.aarch64.neon.fmlal2.v2f32.v4f16(<2 x float>, <4 x half>, <4 x half>)
declare <2 x float> @llvm.aarch64.neon.fmlsl2.v2f32.v4f16(<2 x float>, <4 x half>, <4 x half>)
declare <4 x float> @llvm.aarch64.neon.fmlal.v4f32.v8f16(<4 x float>, <8 x half>, <8 x half>)
declare <4 x float> @llvm.aarch64.neon.fmlsl.v4f32.v8f16(<4 x float>, <8 x half>, <8 x half>)
declare <4 x float> @llvm.aarch64.neon.fmlal2.v4f32.v8f16(<4 x float>, <8 x half>, <8 x half>)
declare <4 x float> @llvm.aarch64.neon.fmlsl2.v4f32.v8f16(<4 x float>, <8 x half>, <8 x half>)
declare <4 x float> @llvm.aarch64.neon.fmlal.v4f32.v4f16(<4 x float>, <4 x half>, <4 x half>)
declare <4 x float> @llvm.aarch64.neon.fmlal.v4f32.v8bf16(<4 x float>, <8 x bfloat>, <8 x bfloat>)
declare <4 x i32> @llvm.aarch64.neon.smmla.v4i32.v16i8(<4 x i32>, <16 x i8>, <16 x i8>)
declare <4 x i32> @llvm.aarch64.neon.sdot.v4i32.v16i8(<4 x i32>, <16 x i8>, <16 x i8>)

declare <vscale x 4 x float> @llvm.aarch64.sve.fmlalb.nxv4f32(<vscale x 4 x float>, <vscale x 8 x half>, <vscale x 8 x half>)

@sink_v2f32 = global <2 x float> zeroinitializer, align 8
@sink_v4f32 = global <4 x float> zeroinitializer, align 16
@sink_v4f16 = global <4 x half> zeroinitializer, align 8
@sink_v8f16 = global <8 x half> zeroinitializer, align 16

define <2 x float> @protected_fmlal_v4(<2 x float> %acc, <4 x half> %a, <4 x half> %b) noinline optnone "target-features"="+fp16fml" {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.aarch64.neon.fmlal.v2f32.v4f16(<2 x float> %acc, <4 x half> %a, <4 x half> %b)
  ret <2 x float> %r
}

define <2 x float> @protected_fmlsl_v4(<2 x float> %acc, <4 x half> %a, <4 x half> %b) noinline optnone "target-features"="+fp16fml" {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.aarch64.neon.fmlsl.v2f32.v4f16(<2 x float> %acc, <4 x half> %a, <4 x half> %b)
  ret <2 x float> %r
}

define <2 x float> @protected_fmlal2_v4(<2 x float> %acc, <4 x half> %a, <4 x half> %b) noinline optnone "target-features"="+fp16fml" {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.aarch64.neon.fmlal2.v2f32.v4f16(<2 x float> %acc, <4 x half> %a, <4 x half> %b)
  ret <2 x float> %r
}

define <2 x float> @protected_fmlsl2_v4(<2 x float> %acc, <4 x half> %a, <4 x half> %b) noinline optnone "target-features"="+fp16fml" {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.aarch64.neon.fmlsl2.v2f32.v4f16(<2 x float> %acc, <4 x half> %a, <4 x half> %b)
  ret <2 x float> %r
}

define <4 x float> @protected_fmlal_v8(<4 x float> %acc, <8 x half> %a, <8 x half> %b) noinline optnone "target-features"="+fp16fml" {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.fmlal.v4f32.v8f16(<4 x float> %acc, <8 x half> %a, <8 x half> %b)
  ret <4 x float> %r
}

define <4 x float> @protected_fmlsl_v8(<4 x float> %acc, <8 x half> %a, <8 x half> %b) noinline optnone "target-features"="+fp16fml" {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.fmlsl.v4f32.v8f16(<4 x float> %acc, <8 x half> %a, <8 x half> %b)
  ret <4 x float> %r
}

define <4 x float> @protected_fmlal2_v8(<4 x float> %acc, <8 x half> %a, <8 x half> %b) noinline optnone "target-features"="+fp16fml" {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.fmlal2.v4f32.v8f16(<4 x float> %acc, <8 x half> %a, <8 x half> %b)
  ret <4 x float> %r
}

define <4 x float> @protected_fmlsl2_v8(<4 x float> %acc, <8 x half> %a, <8 x half> %b) noinline optnone "target-features"="+fp16fml" {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.fmlsl2.v4f32.v8f16(<4 x float> %acc, <8 x half> %a, <8 x half> %b)
  ret <4 x float> %r
}

; clang vfmlal_laneq_low: splat a half lane then the same IR ID.
; No neon.fmlal.lane ID.  ISel may fold to FMLALlane.
define <4 x float> @protected_fmlal_laneq(<4 x float> %acc, <8 x half> %a, <8 x half> %b) noinline optnone "target-features"="+fp16fml" {
entry:
  call void @hikari_vmp()
  %splat = shufflevector <8 x half> %b, <8 x half> undef, <8 x i32> zeroinitializer
  %r = call <4 x float> @llvm.aarch64.neon.fmlal.v4f32.v8f16(<4 x float> %acc, <8 x half> %a, <8 x half> %splat)
  ret <4 x float> %r
}

define <4 x float> @protected_fmlal_last_fp16fml(<4 x float> %acc, <8 x half> %a, <8 x half> %b) noinline optnone "target-features"="+neon,+crc,+fp16fml" {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.fmlal.v4f32.v8f16(<4 x float> %acc, <8 x half> %a, <8 x half> %b)
  ret <4 x float> %r
}

define <4 x float> @unsupported_no_fp16fml(<4 x float> %acc, <8 x half> %a, <8 x half> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.fmlal.v4f32.v8f16(<4 x float> %acc, <8 x half> %a, <8 x half> %b)
  ret <4 x float> %r
}

define <4 x float> @unsupported_fp16fml_disabled(<4 x float> %acc, <8 x half> %a, <8 x half> %b) noinline optnone "target-features"="+fp16fml,-fp16fml" {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.fmlal.v4f32.v8f16(<4 x float> %acc, <8 x half> %a, <8 x half> %b)
  ret <4 x float> %r
}

define <4 x float> @unsupported_fullfp16_only(<4 x float> %acc, <8 x half> %a, <8 x half> %b) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.fmlal.v4f32.v8f16(<4 x float> %acc, <8 x half> %a, <8 x half> %b)
  ret <4 x float> %r
}

define <4 x float> @unsupported_bf16_only(<4 x float> %acc, <8 x half> %a, <8 x half> %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.fmlal.v4f32.v8f16(<4 x float> %acc, <8 x half> %a, <8 x half> %b)
  ret <4 x float> %r
}

define <4 x float> @unsupported_i8mm_only(<4 x float> %acc, <8 x half> %a, <8 x half> %b) noinline optnone "target-features"="+i8mm" {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.fmlal.v4f32.v8f16(<4 x float> %acc, <8 x half> %a, <8 x half> %b)
  ret <4 x float> %r
}

define <4 x float> @unsupported_dotprod_only(<4 x float> %acc, <8 x half> %a, <8 x half> %b) noinline optnone "target-features"="+dotprod" {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.fmlal.v4f32.v8f16(<4 x float> %acc, <8 x half> %a, <8 x half> %b)
  ret <4 x float> %r
}

; Well-formed llvm.aarch64.neon.bfmlalb / bfdot with last-token +bf16
; is vmp-aarch64-neon-bf16-fml-semantic.ll /
; vmp-aarch64-neon-bf16-semantic.ll and must not stay here.

define <4 x i32> @unsupported_smmla(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b) noinline optnone "target-features"="+fp16fml" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.smmla.v4i32.v16i8(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b)
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_sdot(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b) noinline optnone "target-features"="+fp16fml" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.sdot.v4i32.v16i8(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b)
  ret <4 x i32> %r
}

; Well-formed llvm.aarch64.neon.usdot is
; vmp-aarch64-neon-usdot-semantic.ll.

define <4 x float> @unsupported_bfloat(<4 x float> %acc, <8 x bfloat> %a, <8 x bfloat> %b) noinline optnone "target-features"="+fp16fml,+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.fmlal.v4f32.v8bf16(<4 x float> %acc, <8 x bfloat> %a, <8 x bfloat> %b)
  ret <4 x float> %r
}

define <4 x float> @unsupported_mixed_width(<4 x float> %acc, <4 x half> %a, <4 x half> %b) noinline optnone "target-features"="+fp16fml" {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.fmlal.v4f32.v4f16(<4 x float> %acc, <4 x half> %a, <4 x half> %b)
  ret <4 x float> %r
}

define <vscale x 4 x float> @unsupported_sve_fmlalb(<vscale x 4 x float> %acc, <vscale x 8 x half> %a, <vscale x 8 x half> %b) noinline optnone "target-features"="+fp16fml" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x float> @llvm.aarch64.sve.fmlalb.nxv4f32(<vscale x 4 x float> %acc, <vscale x 8 x half> %a, <vscale x 8 x half> %b)
  ret <vscale x 4 x float> %r
}

define <4 x float> @unsupported_fastcc(<4 x float> %acc, <8 x half> %a, <8 x half> %b) noinline optnone "target-features"="+fp16fml" {
entry:
  call void @hikari_vmp()
  %r = call fastcc <4 x float> @llvm.aarch64.neon.fmlal.v4f32.v8f16(<4 x float> %acc, <8 x half> %a, <8 x half> %b)
  ret <4 x float> %r
}


define <4 x float> @unsupported_musttail(<4 x float> %acc, <8 x half> %a, <8 x half> %b) noinline optnone "target-features"="+fp16fml" {
entry:
  call void @hikari_vmp()
  %r = musttail call <4 x float> @llvm.aarch64.neon.fmlal.v4f32.v8f16(<4 x float> %acc, <8 x half> %a, <8 x half> %b)
  ret <4 x float> %r
}

define <4 x float> @unsupported_bundle(<4 x float> %acc, <8 x half> %a, <8 x half> %b) noinline optnone "target-features"="+fp16fml" {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.fmlal.v4f32.v8f16(<4 x float> %acc, <8 x half> %a, <8 x half> %b) [ "deopt"(i32 0) ]
  ret <4 x float> %r
}

define <4 x float> @unsupported_noreturn(<4 x float> %acc, <8 x half> %a, <8 x half> %b) noinline optnone "target-features"="+fp16fml" {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.fmlal.v4f32.v8f16(<4 x float> %acc, <8 x half> %a, <8 x half> %b) noreturn
  ret <4 x float> %r
}

define <4 x float> @unsupported_returns_twice(<4 x float> %acc, <8 x half> %a, <8 x half> %b) noinline optnone "target-features"="+fp16fml" {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.fmlal.v4f32.v8f16(<4 x float> %acc, <8 x half> %a, <8 x half> %b) returns_twice
  ret <4 x float> %r
}

define i32 @main() {
entry:
  %acc2 = load volatile <2 x float>, ptr @sink_v2f32, align 8
  %a4 = load volatile <4 x half>, ptr @sink_v4f16, align 8
  %b4 = load volatile <4 x half>, ptr @sink_v4f16, align 8
  %r0 = call <2 x float> @protected_fmlal_v4(<2 x float> %acc2, <4 x half> %a4, <4 x half> %b4)
  store volatile <2 x float> %r0, ptr @sink_v2f32, align 8
  %r1 = call <2 x float> @protected_fmlsl_v4(<2 x float> %acc2, <4 x half> %a4, <4 x half> %b4)
  store volatile <2 x float> %r1, ptr @sink_v2f32, align 8
  %r2 = call <2 x float> @protected_fmlal2_v4(<2 x float> %acc2, <4 x half> %a4, <4 x half> %b4)
  store volatile <2 x float> %r2, ptr @sink_v2f32, align 8
  %r3 = call <2 x float> @protected_fmlsl2_v4(<2 x float> %acc2, <4 x half> %a4, <4 x half> %b4)
  store volatile <2 x float> %r3, ptr @sink_v2f32, align 8
  %acc4 = load volatile <4 x float>, ptr @sink_v4f32, align 16
  %a8 = load volatile <8 x half>, ptr @sink_v8f16, align 16
  %b8 = load volatile <8 x half>, ptr @sink_v8f16, align 16
  %r4 = call <4 x float> @protected_fmlal_v8(<4 x float> %acc4, <8 x half> %a8, <8 x half> %b8)
  store volatile <4 x float> %r4, ptr @sink_v4f32, align 16
  %r5 = call <4 x float> @protected_fmlsl_v8(<4 x float> %acc4, <8 x half> %a8, <8 x half> %b8)
  store volatile <4 x float> %r5, ptr @sink_v4f32, align 16
  %r6 = call <4 x float> @protected_fmlal2_v8(<4 x float> %acc4, <8 x half> %a8, <8 x half> %b8)
  store volatile <4 x float> %r6, ptr @sink_v4f32, align 16
  %r7 = call <4 x float> @protected_fmlsl2_v8(<4 x float> %acc4, <8 x half> %a8, <8 x half> %b8)
  store volatile <4 x float> %r7, ptr @sink_v4f32, align 16
  %r8 = call <4 x float> @protected_fmlal_laneq(<4 x float> %acc4, <8 x half> %a8, <8 x half> %b8)
  store volatile <4 x float> %r8, ptr @sink_v4f32, align 16
  %r9 = call <4 x float> @protected_fmlal_last_fp16fml(<4 x float> %acc4, <8 x half> %a8, <8 x half> %b8)
  store volatile <4 x float> %r9, ptr @sink_v4f32, align 16
  ret i32 0
}

; SKIP-DAG: Skipping VMP on unsupported_no_fp16fml: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_fp16fml_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_fullfp16_only: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_bf16_only: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_i8mm_only: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_dotprod_only: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_smmla: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_sdot: unsupported target feature

; SKIP-DAG: Skipping VMP on unsupported_bfloat: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_mixed_width: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_sve_fmlalb: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_noreturn: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_returns_twice: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_fmlal_v4:
; SKIP-NOT: Skipping VMP on protected_fmlsl_v4:
; SKIP-NOT: Skipping VMP on protected_fmlal2_v4:
; SKIP-NOT: Skipping VMP on protected_fmlsl2_v4:
; SKIP-NOT: Skipping VMP on protected_fmlal_v8:
; SKIP-NOT: Skipping VMP on protected_fmlsl_v8:
; SKIP-NOT: Skipping VMP on protected_fmlal2_v8:
; SKIP-NOT: Skipping VMP on protected_fmlsl2_v8:
; SKIP-NOT: Skipping VMP on protected_fmlal_laneq:
; SKIP-NOT: Skipping VMP on protected_fmlal_last_fp16fml:

; VIRT: define <2 x float> @protected_fmlal_v4({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x float> @llvm.aarch64.neon.fmlal.v2f32.v4f16(
; VIRT: define <2 x float> @protected_fmlsl_v4({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x float> @llvm.aarch64.neon.fmlsl.v2f32.v4f16(
; VIRT: define <2 x float> @protected_fmlal2_v4({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x float> @llvm.aarch64.neon.fmlal2.v2f32.v4f16(
; VIRT: define <2 x float> @protected_fmlsl2_v4({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x float> @llvm.aarch64.neon.fmlsl2.v2f32.v4f16(
; VIRT: define <4 x float> @protected_fmlal_v8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x float> @llvm.aarch64.neon.fmlal.v4f32.v8f16(
; VIRT: define <4 x float> @protected_fmlsl_v8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x float> @llvm.aarch64.neon.fmlsl.v4f32.v8f16(
; VIRT: define <4 x float> @protected_fmlal2_v8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x float> @llvm.aarch64.neon.fmlal2.v4f32.v8f16(
; VIRT: define <4 x float> @protected_fmlsl2_v8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x float> @llvm.aarch64.neon.fmlsl2.v4f32.v8f16(
; VIRT: define <4 x float> @protected_fmlal_laneq({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x float> @llvm.aarch64.neon.fmlal.v4f32.v8f16(
; VIRT: define <4 x float> @protected_fmlal_last_fp16fml({{.*}} #[[LAST:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x float> @llvm.aarch64.neon.fmlal.v4f32.v8f16(
; VIRT: define {{.*}} @unsupported_no_fp16fml({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT: attributes #[[LAST]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; AARCH64-ASM: {{^[[:space:]]*}}fmlal{{[ \t]}}{{v[0-9]+}}.2s
; AARCH64-ASM: {{^[[:space:]]*}}fmlsl{{[ \t]}}{{v[0-9]+}}.2s
; AARCH64-ASM: {{^[[:space:]]*}}fmlal2{{[ \t]}}{{v[0-9]+}}.2s
; AARCH64-ASM: {{^[[:space:]]*}}fmlsl2{{[ \t]}}{{v[0-9]+}}.2s
; AARCH64-ASM: {{^[[:space:]]*}}fmlal{{[ \t]}}{{v[0-9]+}}.4s
; AARCH64-ASM: {{^[[:space:]]*}}fmlsl{{[ \t]}}{{v[0-9]+}}.4s
; AARCH64-ASM: {{^[[:space:]]*}}fmlal2{{[ \t]}}{{v[0-9]+}}.4s
; AARCH64-ASM: {{^[[:space:]]*}}fmlsl2{{[ \t]}}{{v[0-9]+}}.4s
; HOST: Skipping VMP: only AArch64 targets are supported
