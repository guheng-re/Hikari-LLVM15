; Restricted AArch64 NEON fixed-point conversions via
; CallDescriptor ImmediateArguments / vector VRegs (no new
; opcode):
;   llvm.aarch64.neon.vcvtfp2fxs / vcvtfp2fxu
;     AdvSIMD_CvtFPToFx: anyint (anyfloat, i32)
;     ISel SIMDVectorRShiftSD -> fcvtzs/fcvtzu #fbits
;   llvm.aarch64.neon.vcvtfxs2fp / vcvtfxu2fp
;     AdvSIMD_CvtFxToFP: anyfloat (anyint, i32)
;     ISel SIMDVectorRShiftToFP -> scvtf/ucvtf #fbits
; Layouts (baseline HasNEON):
;   <2 x float> <-> <2 x i32>   vecshiftR32  1..32
;   <4 x float> <-> <4 x i32>   vecshiftR32  1..32
;   <2 x double> <-> <2 x i64>  vecshiftR64  1..64
; plus HasFullFP16:
;   <4 x half> <-> <4 x i16>    vecshiftR16  1..16
;   <8 x half> <-> <8 x i16>    vecshiftR16  1..16
; The i32 fbits is not ImmArg; keep it on ImmediateArguments.
; Must not lower to sitofp/uitofp/fptosi/fptoui or unscaled
; fcvtzs.  Rounding fcvt{a,m,n,p}{s,u} stay on the independent
; surface.  Well-formed scalar is
; vmp-aarch64-neon-scalar-fixedpoint-cvt-semantic.ll and must
; not stay here as a skip (it would virtualize).  v1f64 stay out.
; Last-token +fullfp16 required for half; f32/f64 need no extra
; token.  +fp16fml does not count.  Command-line -mattr is never
; consulted.  Exact C non-vararg.  Ordinary tail accepted and replayed as non-tail; see vmp-direct-call-tail-eligibility-semantic.ll.
;
; Host cannot select these AArch64 intrinsics; no lli.
; FileCheck + AArch64 llc/readobj/asm (-mattr=+fullfp16).
; O0/O2 x 97/7.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.ll -o %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+fullfp16 -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+fullfp16 %t.o0.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.ll -o %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+fullfp16 -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+fullfp16 %t.o2.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.s7.ll -o %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+fullfp16 -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+fullfp16 %t.o0.s7.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.s7.ll -o %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+fullfp16 -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+fullfp16 %t.o2.s7.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %s | opt -S -verify-each -aesSeed=97 -passes='default<O0>' - 2>&1 | FileCheck %s --check-prefix=HOST

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare <4 x i32> @llvm.aarch64.neon.vcvtfp2fxs.v4i32.v4f32(<4 x float>, i32)
declare <4 x i32> @llvm.aarch64.neon.vcvtfp2fxu.v4i32.v4f32(<4 x float>, i32)
declare <4 x float> @llvm.aarch64.neon.vcvtfxs2fp.v4f32.v4i32(<4 x i32>, i32)
declare <4 x float> @llvm.aarch64.neon.vcvtfxu2fp.v4f32.v4i32(<4 x i32>, i32)
declare <2 x i32> @llvm.aarch64.neon.vcvtfp2fxs.v2i32.v2f32(<2 x float>, i32)
declare <2 x i64> @llvm.aarch64.neon.vcvtfp2fxs.v2i64.v2f64(<2 x double>, i32)
declare <2 x double> @llvm.aarch64.neon.vcvtfxs2fp.v2f64.v2i64(<2 x i64>, i32)
declare <4 x i16> @llvm.aarch64.neon.vcvtfp2fxs.v4i16.v4f16(<4 x half>, i32)
declare <8 x i16> @llvm.aarch64.neon.vcvtfp2fxs.v8i16.v8f16(<8 x half>, i32)
; Well-formed scalar llvm.aarch64.neon.vcvtfp2fxs.i32.f32 is
; vmp-aarch64-neon-scalar-fixedpoint-cvt-semantic.ll and would
; virtualize here.
declare <1 x i64> @llvm.aarch64.neon.vcvtfp2fxs.v1i64.v1f64(<1 x double>, i32)
declare <2 x i16> @llvm.aarch64.neon.vcvtfp2fxs.v2i16.v2f16(<2 x half>, i32)
declare <4 x i16> @llvm.aarch64.neon.vcvtfp2fxs.v4i16.v4bf16(<4 x bfloat>, i32)
declare <2 x i32> @llvm.aarch64.neon.vcvtfp2fxs.v2i32.v4f32(<4 x float>, i32)
declare <vscale x 4 x i32> @llvm.aarch64.sve.fcvtzs.nxv4i32.nxv4f32(<vscale x 4 x i32>, <vscale x 4 x i1>, <vscale x 4 x float>)

@sink_v4f32 = global <4 x float> zeroinitializer, align 16
@sink_v4i32 = global <4 x i32> zeroinitializer, align 16
@sink_v2f32 = global <2 x float> zeroinitializer, align 8
@sink_v2i32 = global <2 x i32> zeroinitializer, align 8
@sink_v2f64 = global <2 x double> zeroinitializer, align 16
@sink_v2i64 = global <2 x i64> zeroinitializer, align 16
@sink_v4f16 = global <4 x half> zeroinitializer, align 8
@sink_v4i16 = global <4 x i16> zeroinitializer, align 8
@sink_v8f16 = global <8 x half> zeroinitializer, align 16
@sink_v8i16 = global <8 x i16> zeroinitializer, align 16

define <4 x i32> @protected_fp2fxs_v4f32(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.vcvtfp2fxs.v4i32.v4f32(<4 x float> %a, i32 1)
  ret <4 x i32> %r
}

define <4 x i32> @protected_fp2fxs_v4f32_max(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.vcvtfp2fxs.v4i32.v4f32(<4 x float> %a, i32 32)
  ret <4 x i32> %r
}

define <4 x i32> @protected_fp2fxu_v4f32(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.vcvtfp2fxu.v4i32.v4f32(<4 x float> %a, i32 16)
  ret <4 x i32> %r
}

define <4 x float> @protected_fxs2fp_v4i32(<4 x i32> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.vcvtfxs2fp.v4f32.v4i32(<4 x i32> %a, i32 1)
  ret <4 x float> %r
}

define <4 x float> @protected_fxu2fp_v4i32(<4 x i32> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.vcvtfxu2fp.v4f32.v4i32(<4 x i32> %a, i32 32)
  ret <4 x float> %r
}

define <2 x i32> @protected_fp2fxs_v2f32(<2 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i32> @llvm.aarch64.neon.vcvtfp2fxs.v2i32.v2f32(<2 x float> %a, i32 1)
  ret <2 x i32> %r
}

define <2 x i64> @protected_fp2fxs_v2f64(<2 x double> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.aarch64.neon.vcvtfp2fxs.v2i64.v2f64(<2 x double> %a, i32 1)
  ret <2 x i64> %r
}

define <2 x double> @protected_fxs2fp_v2i64(<2 x i64> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x double> @llvm.aarch64.neon.vcvtfxs2fp.v2f64.v2i64(<2 x i64> %a, i32 64)
  ret <2 x double> %r
}

define <4 x i16> @protected_fp2fxs_v4f16(<4 x half> %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i16> @llvm.aarch64.neon.vcvtfp2fxs.v4i16.v4f16(<4 x half> %a, i32 1)
  ret <4 x i16> %r
}

define <8 x i16> @protected_fp2fxs_v8f16(<8 x half> %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <8 x i16> @llvm.aarch64.neon.vcvtfp2fxs.v8i16.v8f16(<8 x half> %a, i32 16)
  ret <8 x i16> %r
}

define <4 x i16> @protected_fp2fxs_last_fullfp16(<4 x half> %a) noinline optnone "target-features"="+neon,+fp16fml,+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i16> @llvm.aarch64.neon.vcvtfp2fxs.v4i16.v4f16(<4 x half> %a, i32 8)
  ret <4 x i16> %r
}

define <4 x i16> @unsupported_f16_no_fullfp16(<4 x half> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i16> @llvm.aarch64.neon.vcvtfp2fxs.v4i16.v4f16(<4 x half> %a, i32 1)
  ret <4 x i16> %r
}

define <4 x i16> @unsupported_fullfp16_disabled(<4 x half> %a) noinline optnone "target-features"="+fullfp16,-fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i16> @llvm.aarch64.neon.vcvtfp2fxs.v4i16.v4f16(<4 x half> %a, i32 1)
  ret <4 x i16> %r
}

define <4 x i16> @unsupported_fp16fml_only(<4 x half> %a) noinline optnone "target-features"="+fp16fml" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i16> @llvm.aarch64.neon.vcvtfp2fxs.v4i16.v4f16(<4 x half> %a, i32 1)
  ret <4 x i16> %r
}

define <4 x i32> @unsupported_imm0(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.vcvtfp2fxs.v4i32.v4f32(<4 x float> %a, i32 0)
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_imm33(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.vcvtfp2fxs.v4i32.v4f32(<4 x float> %a, i32 33)
  ret <4 x i32> %r
}

define <4 x i16> @unsupported_imm17_f16(<4 x half> %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i16> @llvm.aarch64.neon.vcvtfp2fxs.v4i16.v4f16(<4 x half> %a, i32 17)
  ret <4 x i16> %r
}

define <4 x i32> @unsupported_dyn_imm(<4 x float> %a, i32 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.vcvtfp2fxs.v4i32.v4f32(<4 x float> %a, i32 %n)
  ret <4 x i32> %r
}

define <1 x i64> @unsupported_v1f64(<1 x double> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <1 x i64> @llvm.aarch64.neon.vcvtfp2fxs.v1i64.v1f64(<1 x double> %a, i32 1)
  ret <1 x i64> %r
}

define <2 x i16> @unsupported_v2f16(<2 x half> %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <2 x i16> @llvm.aarch64.neon.vcvtfp2fxs.v2i16.v2f16(<2 x half> %a, i32 1)
  ret <2 x i16> %r
}

define <4 x i16> @unsupported_bfloat(<4 x bfloat> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i16> @llvm.aarch64.neon.vcvtfp2fxs.v4i16.v4bf16(<4 x bfloat> %a, i32 1)
  ret <4 x i16> %r
}

define <2 x i32> @unsupported_mismatch(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i32> @llvm.aarch64.neon.vcvtfp2fxs.v2i32.v4f32(<4 x float> %a, i32 1)
  ret <2 x i32> %r
}

define <vscale x 4 x i32> @unsupported_sve_fcvtzs(<vscale x 4 x i32> %a, <vscale x 4 x i1> %pg, <vscale x 4 x float> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.aarch64.sve.fcvtzs.nxv4i32.nxv4f32(<vscale x 4 x i32> %a, <vscale x 4 x i1> %pg, <vscale x 4 x float> %b)
  ret <vscale x 4 x i32> %r
}

define <4 x i32> @unsupported_fastcc(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc <4 x i32> @llvm.aarch64.neon.vcvtfp2fxs.v4i32.v4f32(<4 x float> %a, i32 1)
  ret <4 x i32> %r
}


define <4 x i32> @unsupported_musttail(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call <4 x i32> @llvm.aarch64.neon.vcvtfp2fxs.v4i32.v4f32(<4 x float> %a, i32 1)
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_bundle(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.vcvtfp2fxs.v4i32.v4f32(<4 x float> %a, i32 1) [ "deopt"(i32 0) ]
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_noreturn(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.vcvtfp2fxs.v4i32.v4f32(<4 x float> %a, i32 1) noreturn
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_returns_twice(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.vcvtfp2fxs.v4i32.v4f32(<4 x float> %a, i32 1) returns_twice
  ret <4 x i32> %r
}

define i32 @main() {
entry:
  %s4 = load volatile <4 x float>, ptr @sink_v4f32, align 16
  %r0 = call <4 x i32> @protected_fp2fxs_v4f32(<4 x float> %s4)
  store volatile <4 x i32> %r0, ptr @sink_v4i32, align 16
  %r1 = call <4 x i32> @protected_fp2fxs_v4f32_max(<4 x float> %s4)
  store volatile <4 x i32> %r1, ptr @sink_v4i32, align 16
  %r2 = call <4 x i32> @protected_fp2fxu_v4f32(<4 x float> %s4)
  store volatile <4 x i32> %r2, ptr @sink_v4i32, align 16
  %i4 = load volatile <4 x i32>, ptr @sink_v4i32, align 16
  %r3 = call <4 x float> @protected_fxs2fp_v4i32(<4 x i32> %i4)
  store volatile <4 x float> %r3, ptr @sink_v4f32, align 16
  %r4 = call <4 x float> @protected_fxu2fp_v4i32(<4 x i32> %i4)
  store volatile <4 x float> %r4, ptr @sink_v4f32, align 16
  %s2 = load volatile <2 x float>, ptr @sink_v2f32, align 8
  %r5 = call <2 x i32> @protected_fp2fxs_v2f32(<2 x float> %s2)
  store volatile <2 x i32> %r5, ptr @sink_v2i32, align 8
  %d2 = load volatile <2 x double>, ptr @sink_v2f64, align 16
  %r6 = call <2 x i64> @protected_fp2fxs_v2f64(<2 x double> %d2)
  store volatile <2 x i64> %r6, ptr @sink_v2i64, align 16
  %l2 = load volatile <2 x i64>, ptr @sink_v2i64, align 16
  %r7 = call <2 x double> @protected_fxs2fp_v2i64(<2 x i64> %l2)
  store volatile <2 x double> %r7, ptr @sink_v2f64, align 16
  %h4 = load volatile <4 x half>, ptr @sink_v4f16, align 8
  %r8 = call <4 x i16> @protected_fp2fxs_v4f16(<4 x half> %h4)
  store volatile <4 x i16> %r8, ptr @sink_v4i16, align 8
  %h8 = load volatile <8 x half>, ptr @sink_v8f16, align 16
  %r9 = call <8 x i16> @protected_fp2fxs_v8f16(<8 x half> %h8)
  store volatile <8 x i16> %r9, ptr @sink_v8i16, align 16
  %r10 = call <4 x i16> @protected_fp2fxs_last_fullfp16(<4 x half> %h4)
  store volatile <4 x i16> %r10, ptr @sink_v4i16, align 8
  ret i32 0
}

; SKIP-DAG: Skipping VMP on unsupported_f16_no_fullfp16: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_fullfp16_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_fp16fml_only: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_imm0: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_imm33: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_imm17_f16: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_dyn_imm: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_v1f64: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_v2f16: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_bfloat: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_mismatch: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_sve_fcvtzs: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_noreturn: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_returns_twice: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_fp2fxs_v4f32:
; SKIP-NOT: Skipping VMP on protected_fp2fxs_v4f32_max:
; SKIP-NOT: Skipping VMP on protected_fp2fxu_v4f32:
; SKIP-NOT: Skipping VMP on protected_fxs2fp_v4i32:
; SKIP-NOT: Skipping VMP on protected_fxu2fp_v4i32:
; SKIP-NOT: Skipping VMP on protected_fp2fxs_v2f32:
; SKIP-NOT: Skipping VMP on protected_fp2fxs_v2f64:
; SKIP-NOT: Skipping VMP on protected_fxs2fp_v2i64:
; SKIP-NOT: Skipping VMP on protected_fp2fxs_v4f16:
; SKIP-NOT: Skipping VMP on protected_fp2fxs_v8f16:
; SKIP-NOT: Skipping VMP on protected_fp2fxs_last_fullfp16:

; VIRT: define <4 x i32> @protected_fp2fxs_v4f32({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.aarch64.neon.vcvtfp2fxs.v4i32.v4f32({{.*}}, i32 1)
; VIRT: define <4 x i32> @protected_fp2fxs_v4f32_max({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.aarch64.neon.vcvtfp2fxs.v4i32.v4f32({{.*}}, i32 32)
; VIRT: define <4 x i32> @protected_fp2fxu_v4f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.aarch64.neon.vcvtfp2fxu.v4i32.v4f32({{.*}}, i32 16)
; VIRT: define <4 x float> @protected_fxs2fp_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x float> @llvm.aarch64.neon.vcvtfxs2fp.v4f32.v4i32({{.*}}, i32 1)
; VIRT: define <4 x float> @protected_fxu2fp_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x float> @llvm.aarch64.neon.vcvtfxu2fp.v4f32.v4i32({{.*}}, i32 32)
; VIRT: define <2 x i32> @protected_fp2fxs_v2f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <2 x i64> @protected_fp2fxs_v2f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <2 x double> @protected_fxs2fp_v2i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <4 x i16> @protected_fp2fxs_v4f16({{.*}} #[[PROTH:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i16> @llvm.aarch64.neon.vcvtfp2fxs.v4i16.v4f16({{.*}}, i32 1)
; VIRT: define <8 x i16> @protected_fp2fxs_v8f16({{.*}} #[[PROTH]] {
; VIRT: vmp.dispatch:
; VIRT: define <4 x i16> @protected_fp2fxs_last_fullfp16({{.*}} #[[LAST:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: define {{.*}} @unsupported_f16_no_fullfp16({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT: attributes #[[PROTH]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT: attributes #[[LAST]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; AARCH64-ASM-DAG: {{^[[:space:]]*}}fcvtzs{{[ \t]}}{{v[0-9]+}}.4s, {{v[0-9]+}}.4s, #1
; AARCH64-ASM-DAG: {{^[[:space:]]*}}fcvtzs{{[ \t]}}{{v[0-9]+}}.4s, {{v[0-9]+}}.4s, #32
; AARCH64-ASM-DAG: {{^[[:space:]]*}}fcvtzu{{[ \t]}}{{v[0-9]+}}.4s, {{v[0-9]+}}.4s, #16
; AARCH64-ASM-DAG: {{^[[:space:]]*}}scvtf{{[ \t]}}{{v[0-9]+}}.4s, {{v[0-9]+}}.4s, #1
; AARCH64-ASM-DAG: {{^[[:space:]]*}}ucvtf{{[ \t]}}{{v[0-9]+}}.4s, {{v[0-9]+}}.4s, #32
; AARCH64-ASM-DAG: {{^[[:space:]]*}}fcvtzs{{[ \t]}}{{v[0-9]+}}.2s, {{v[0-9]+}}.2s, #1
; AARCH64-ASM-DAG: {{^[[:space:]]*}}fcvtzs{{[ \t]}}{{v[0-9]+}}.2d, {{v[0-9]+}}.2d, #1
; AARCH64-ASM-DAG: {{^[[:space:]]*}}scvtf{{[ \t]}}{{v[0-9]+}}.2d, {{v[0-9]+}}.2d, #64
; AARCH64-ASM-DAG: {{^[[:space:]]*}}fcvtzs{{[ \t]}}{{v[0-9]+}}.4h, {{v[0-9]+}}.4h, #1
; AARCH64-ASM-DAG: {{^[[:space:]]*}}fcvtzs{{[ \t]}}{{v[0-9]+}}.8h, {{v[0-9]+}}.8h, #16
; HOST: Skipping VMP: only AArch64 targets are supported
