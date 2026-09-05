; Restricted AArch64 scalar fixed-point conversions via
; CallDescriptor ImmediateArguments (no new opcode):
;   llvm.aarch64.neon.vcvtfp2fxs / vcvtfp2fxu
;     AdvSIMD_CvtFPToFx: anyint (anyfloat, i32)
;   llvm.aarch64.neon.vcvtfxs2fp / vcvtfxu2fp
;     AdvSIMD_CvtFxToFP: anyfloat (anyint, i32)
;     ISel extra Pats after SIMDFPScalarRShift:
;       i32(f32)/f32(i32) vecshiftR32 1..32
;       i64(f64)/f64(i64) vecshiftR64 1..64
;       i32(f16) vecshiftR32 1..32 / i64(f16) 1..64
;       f16(i32/i64) vecshiftR16 1..16
; Asm is SIMD-scalar fcvtzs/scvtf s/d/h, #fbits (not GPR
; fcvtzs w,s,#n).  Clang vcvts_n_s32_f32 / vcvtd_n_s64_f64 /
; vcvth_n_s32_f16.  Must not lower to sitofp/uitofp/fptosi/
; fptoui or unscaled fcvtzs.  Mixed i32(f64)/i16(f16) have
; no Pat.  Vector fixed-point is
; vmp-aarch64-neon-fixedpoint-cvt-semantic.ll and must not
; stay here as a well-formed skip.  Last-token +fullfp16
; required for half; f32/f64 need no extra token.  +fp16fml
; does not count.  Command-line -mattr never consulted.
; Exact C non-vararg.  Ordinary tail accepted and replayed as non-tail; see vmp-direct-call-tail-eligibility-semantic.ll.  FMF on fx2fp is rejected by the float-call gate.
; No new opcode.
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
declare void @ext_sret_byval(ptr sret(i32), ptr byval(i32))
declare i32 @llvm.aarch64.neon.vcvtfp2fxs.i32.f32(float, i32)
declare i32 @llvm.aarch64.neon.vcvtfp2fxu.i32.f32(float, i32)
declare float @llvm.aarch64.neon.vcvtfxs2fp.f32.i32(i32, i32)
declare float @llvm.aarch64.neon.vcvtfxu2fp.f32.i32(i32, i32)
declare i64 @llvm.aarch64.neon.vcvtfp2fxs.i64.f64(double, i32)
declare double @llvm.aarch64.neon.vcvtfxs2fp.f64.i64(i64, i32)
declare i32 @llvm.aarch64.neon.vcvtfp2fxs.i32.f16(half, i32)
declare half @llvm.aarch64.neon.vcvtfxs2fp.f16.i32(i32, i32)
declare i32 @llvm.aarch64.neon.vcvtfp2fxs.i32.f64(double, i32)
declare i16 @llvm.aarch64.neon.vcvtfp2fxs.i16.f16(half, i32)
declare <1 x i64> @llvm.aarch64.neon.vcvtfp2fxs.v1i64.v1f64(<1 x double>, i32)
declare <vscale x 4 x i32> @llvm.aarch64.sve.fcvtzs.nxv4i32.nxv4f32(<vscale x 4 x i32>, <vscale x 4 x i1>, <vscale x 4 x float>)

@sink_f32 = global float 0.0, align 4
@sink_f64 = global double 0.0, align 8
@sink_f16 = global half 0xH0000, align 2
@sink_i32 = global i32 0, align 4
@sink_i64 = global i64 0, align 8

define i32 @protected_fp2fxs_f32(float %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.vcvtfp2fxs.i32.f32(float %a, i32 1)
  ret i32 %r
}

define i32 @protected_fp2fxs_f32_max(float %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.vcvtfp2fxs.i32.f32(float %a, i32 32)
  ret i32 %r
}

define i32 @protected_fp2fxu_f32(float %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.vcvtfp2fxu.i32.f32(float %a, i32 1)
  ret i32 %r
}

define float @protected_fxs2fp_i32(i32 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.aarch64.neon.vcvtfxs2fp.f32.i32(i32 %a, i32 1)
  ret float %r
}

define float @protected_fxu2fp_i32(i32 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.aarch64.neon.vcvtfxu2fp.f32.i32(i32 %a, i32 32)
  ret float %r
}

define i64 @protected_fp2fxs_f64(double %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.aarch64.neon.vcvtfp2fxs.i64.f64(double %a, i32 1)
  ret i64 %r
}

define double @protected_fxs2fp_i64(i64 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call double @llvm.aarch64.neon.vcvtfxs2fp.f64.i64(i64 %a, i32 64)
  ret double %r
}

define i32 @protected_fp2fxs_f16(half %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.vcvtfp2fxs.i32.f16(half %a, i32 1)
  ret i32 %r
}

define half @protected_fxs2fp_last_fullfp16(i32 %a) noinline optnone "target-features"="+neon,+fp16fml,+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.aarch64.neon.vcvtfxs2fp.f16.i32(i32 %a, i32 16)
  ret half %r
}

; 1.0 with #1 stays live fcvtzs s,s,#1 (not folded).
define i32 @protected_fp2fxs_const() noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.vcvtfp2fxs.i32.f32(float 1.000000e+00, i32 1)
  ret i32 %r
}

; ----- negatives: selected, not virtualized -----

define i16 @unsupported_i16_f16(half %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i16 @llvm.aarch64.neon.vcvtfp2fxs.i16.f16(half %a, i32 1)
  ret i16 %r
}

define i32 @unsupported_mix_f64(double %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.vcvtfp2fxs.i32.f64(double %a, i32 1)
  ret i32 %r
}

define i32 @unsupported_imm0(float %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.vcvtfp2fxs.i32.f32(float %a, i32 0)
  ret i32 %r
}

define i32 @unsupported_imm33(float %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.vcvtfp2fxs.i32.f32(float %a, i32 33)
  ret i32 %r
}

define half @unsupported_imm17_f16(i32 %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.aarch64.neon.vcvtfxs2fp.f16.i32(i32 %a, i32 17)
  ret half %r
}

define i32 @unsupported_dyn_imm(float %a, i32 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.vcvtfp2fxs.i32.f32(float %a, i32 %n)
  ret i32 %r
}

define i32 @unsupported_f16_no_fullfp16(half %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.vcvtfp2fxs.i32.f16(half %a, i32 1)
  ret i32 %r
}

define i32 @unsupported_fullfp16_disabled(half %a) noinline optnone "target-features"="+fullfp16,-fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.vcvtfp2fxs.i32.f16(half %a, i32 1)
  ret i32 %r
}

define i32 @unsupported_fp16fml_only(half %a) noinline optnone "target-features"="+fp16fml" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.vcvtfp2fxs.i32.f16(half %a, i32 1)
  ret i32 %r
}

define <1 x i64> @unsupported_v1f64(<1 x double> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <1 x i64> @llvm.aarch64.neon.vcvtfp2fxs.v1i64.v1f64(<1 x double> %a, i32 1)
  ret <1 x i64> %r
}

define <vscale x 4 x i32> @unsupported_sve(<vscale x 4 x i32> %a, <vscale x 4 x i1> %pg, <vscale x 4 x float> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.aarch64.sve.fcvtzs.nxv4i32.nxv4f32(<vscale x 4 x i32> %a, <vscale x 4 x i1> %pg, <vscale x 4 x float> %b)
  ret <vscale x 4 x i32> %r
}

define float @unsupported_nnan(i32 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call nnan float @llvm.aarch64.neon.vcvtfxs2fp.f32.i32(i32 %a, i32 1)
  ret float %r
}

define i32 @unsupported_fastcc(float %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc i32 @llvm.aarch64.neon.vcvtfp2fxs.i32.f32(float %a, i32 1)
  ret i32 %r
}


define i32 @unsupported_musttail(float %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call i32 @llvm.aarch64.neon.vcvtfp2fxs.i32.f32(float %a, i32 1)
  ret i32 %r
}

define i32 @unsupported_bundle(float %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.vcvtfp2fxs.i32.f32(float %a, i32 1) [ "deopt"(i32 0) ]
  ret i32 %r
}

define i32 @unsupported_noreturn(float %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.vcvtfp2fxs.i32.f32(float %a, i32 1) noreturn
  ret i32 %r
}

define i32 @unsupported_returns_twice(float %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.vcvtfp2fxs.i32.f32(float %a, i32 1) returns_twice
  ret i32 %r
}

define void @unsupported_sret(ptr sret(i32) %p, ptr byval(i32) %q) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @ext_sret_byval(ptr sret(i32) %p, ptr byval(i32) %q)
  ret void
}

define i32 @main() {
entry:
  %a = load volatile float, ptr @sink_f32, align 4
  %r0 = call i32 @protected_fp2fxs_f32(float %a)
  store volatile i32 %r0, ptr @sink_i32, align 4
  %r1 = call i32 @protected_fp2fxs_f32_max(float %a)
  store volatile i32 %r1, ptr @sink_i32, align 4
  %r2 = call i32 @protected_fp2fxu_f32(float %a)
  store volatile i32 %r2, ptr @sink_i32, align 4
  %i = load volatile i32, ptr @sink_i32, align 4
  %r3 = call float @protected_fxs2fp_i32(i32 %i)
  store volatile float %r3, ptr @sink_f32, align 4
  %r4 = call float @protected_fxu2fp_i32(i32 %i)
  store volatile float %r4, ptr @sink_f32, align 4
  %d = load volatile double, ptr @sink_f64, align 8
  %r5 = call i64 @protected_fp2fxs_f64(double %d)
  store volatile i64 %r5, ptr @sink_i64, align 8
  %k = load volatile i64, ptr @sink_i64, align 8
  %r6 = call double @protected_fxs2fp_i64(i64 %k)
  store volatile double %r6, ptr @sink_f64, align 8
  %h = load volatile half, ptr @sink_f16, align 2
  %r7 = call i32 @protected_fp2fxs_f16(half %h)
  store volatile i32 %r7, ptr @sink_i32, align 4
  %r8 = call half @protected_fxs2fp_last_fullfp16(i32 %i)
  store volatile half %r8, ptr @sink_f16, align 2
  %r9 = call i32 @protected_fp2fxs_const()
  store volatile i32 %r9, ptr @sink_i32, align 4
  ret i32 0
}

; SKIP-DAG: Skipping VMP on unsupported_i16_f16: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_mix_f64: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_imm0: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_imm33: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_imm17_f16: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_dyn_imm: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_f16_no_fullfp16: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_fullfp16_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_fp16fml_only: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_v1f64: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_sve: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_nnan: unsupported float call instruction
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_noreturn: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_returns_twice: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_sret: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_fp2fxs_f32:
; SKIP-NOT: Skipping VMP on protected_fp2fxs_f32_max:
; SKIP-NOT: Skipping VMP on protected_fp2fxu_f32:
; SKIP-NOT: Skipping VMP on protected_fxs2fp_i32:
; SKIP-NOT: Skipping VMP on protected_fxu2fp_i32:
; SKIP-NOT: Skipping VMP on protected_fp2fxs_f64:
; SKIP-NOT: Skipping VMP on protected_fxs2fp_i64:
; SKIP-NOT: Skipping VMP on protected_fp2fxs_f16:
; SKIP-NOT: Skipping VMP on protected_fxs2fp_last_fullfp16:
; SKIP-NOT: Skipping VMP on protected_fp2fxs_const:

; VIRT: define i32 @protected_fp2fxs_f32({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.neon.vcvtfp2fxs.i32.f32({{.*}}, i32 1)
; VIRT: define i32 @protected_fp2fxs_f32_max({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.neon.vcvtfp2fxs.i32.f32({{.*}}, i32 32)
; VIRT: define i32 @protected_fp2fxu_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.neon.vcvtfp2fxu.i32.f32({{.*}}, i32 1)
; VIRT: define float @protected_fxs2fp_i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.aarch64.neon.vcvtfxs2fp.f32.i32({{.*}}, i32 1)
; VIRT: define float @protected_fxu2fp_i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define i64 @protected_fp2fxs_f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define double @protected_fxs2fp_i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call double @llvm.aarch64.neon.vcvtfxs2fp.f64.i64({{.*}}, i32 64)
; VIRT: define i32 @protected_fp2fxs_f16({{.*}} #[[PROTH:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.neon.vcvtfp2fxs.i32.f16({{.*}}, i32 1)
; VIRT: define half @protected_fxs2fp_last_fullfp16({{.*}} #[[PROTL:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: define i32 @protected_fp2fxs_const({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.neon.vcvtfp2fxs.i32.f32({{.*}}, i32 1)
; VIRT: define {{.*}} @unsupported_i16_f16({{.*}} #[[UNSUPH:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_mix_f64({{.*}} #[[UNSUP0:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_f16_no_fullfp16({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT: attributes #[[PROTH]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT: attributes #[[PROTL]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; AARCH64-ASM-DAG: {{^[[:space:]]*}}fcvtzs{{[ \t]}}{{[sdh]}}{{[0-9]+}}, {{[sdh]}}{{[0-9]+}}, #{{[0-9]+}}
; AARCH64-ASM-DAG: {{^[[:space:]]*}}fcvtzu{{[ \t]}}{{[sdh]}}{{[0-9]+}}, {{[sdh]}}{{[0-9]+}}, #{{[0-9]+}}
; AARCH64-ASM-DAG: {{^[[:space:]]*}}scvtf{{[ \t]}}{{[sdh]}}{{[0-9]+}}, {{[sdh]}}{{[0-9]+}}, #{{[0-9]+}}
; AARCH64-ASM-DAG: {{^[[:space:]]*}}ucvtf{{[ \t]}}{{[sdh]}}{{[0-9]+}}, {{[sdh]}}{{[0-9]+}}, #{{[0-9]+}}
; HOST: Skipping VMP: only AArch64 targets are supported
