; Restricted AArch64 scalar neon fmin/fmax/fminnm/fmaxnm via
; CallDescriptor / scalar float VRegs (same IR IDs as the
; vector surface):
;   llvm.aarch64.neon.fmin / fmax / fminnm / fmaxnm
;     AdvSIMD_2FloatArg: anyfloat (match, match)
;     ISel custom-lowers to FMINIMUM/FMAXIMUM/FMINNUM/FMAXNUM,
;     then TwoOperandFPData: fmin/fmax/fminnm/fmaxnm s/d
;     plus HasFullFP16: h
; Clang vmins_f32 / vmaxnmh_f16.  Must not rewrite to
; llvm.minimum / llvm.minnum (different IDs).  Vector fminmax
; is vmp-aarch64-neon-fminmax-semantic.ll and must not stay
; here as a well-formed skip.  Last-token +fullfp16 required
; for half; f32/f64 need no extra token.  +fp16fml does not
; count.  FastMathFlags are rejected by the existing float-
; call FMF gate.  Command-line -mattr never consulted.
; Exact C non-vararg.  Ordinary tail accepted and replayed as non-tail; see vmp-direct-call-tail-eligibility-semantic.ll.  No new opcode.
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
declare float @llvm.aarch64.neon.fmin.f32(float, float)
declare float @llvm.aarch64.neon.fmax.f32(float, float)
declare float @llvm.aarch64.neon.fminnm.f32(float, float)
declare float @llvm.aarch64.neon.fmaxnm.f32(float, float)
declare double @llvm.aarch64.neon.fmin.f64(double, double)
declare half @llvm.aarch64.neon.fmin.f16(half, half)
declare half @llvm.aarch64.neon.fmaxnm.f16(half, half)
declare <1 x double> @llvm.aarch64.neon.fmin.v1f64(<1 x double>, <1 x double>)
declare bfloat @llvm.aarch64.neon.fmin.bf16(bfloat, bfloat)
declare <vscale x 4 x float> @llvm.aarch64.sve.fmin.nxv4f32(<vscale x 4 x i1>, <vscale x 4 x float>, <vscale x 4 x float>)

@sink_f32 = global float 0.0, align 4
@sink_f64 = global double 0.0, align 8
@sink_f16 = global half 0xH0000, align 2

define float @protected_fmin_f32(float %a, float %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.aarch64.neon.fmin.f32(float %a, float %b)
  ret float %r
}

define float @protected_fmax_f32(float %a, float %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.aarch64.neon.fmax.f32(float %a, float %b)
  ret float %r
}

define float @protected_fminnm_f32(float %a, float %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.aarch64.neon.fminnm.f32(float %a, float %b)
  ret float %r
}

define float @protected_fmaxnm_f32(float %a, float %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.aarch64.neon.fmaxnm.f32(float %a, float %b)
  ret float %r
}

define double @protected_fmin_f64(double %a, double %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call double @llvm.aarch64.neon.fmin.f64(double %a, double %b)
  ret double %r
}

define half @protected_fmin_f16(half %a, half %b) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.aarch64.neon.fmin.f16(half %a, half %b)
  ret half %r
}

define half @protected_fmaxnm_last_fullfp16(half %a, half %b) noinline optnone "target-features"="+neon,+fp16fml,+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.aarch64.neon.fmaxnm.f16(half %a, half %b)
  ret half %r
}

; ----- negatives: selected, not virtualized -----

define float @unsupported_nnan(float %a, float %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call nnan ninf float @llvm.aarch64.neon.fmin.f32(float %a, float %b)
  ret float %r
}

define half @unsupported_f16_no_fullfp16(half %a, half %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.aarch64.neon.fmin.f16(half %a, half %b)
  ret half %r
}

define half @unsupported_fullfp16_disabled(half %a, half %b) noinline optnone "target-features"="+fullfp16,-fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.aarch64.neon.fmin.f16(half %a, half %b)
  ret half %r
}

define half @unsupported_fp16fml_only(half %a, half %b) noinline optnone "target-features"="+fp16fml" {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.aarch64.neon.fmin.f16(half %a, half %b)
  ret half %r
}

define <1 x double> @unsupported_v1f64(<1 x double> %a, <1 x double> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <1 x double> @llvm.aarch64.neon.fmin.v1f64(<1 x double> %a, <1 x double> %b)
  ret <1 x double> %r
}

define bfloat @unsupported_bfloat(bfloat %a, bfloat %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.aarch64.neon.fmin.bf16(bfloat %a, bfloat %b)
  ret bfloat %r
}

define <vscale x 4 x float> @unsupported_sve(<vscale x 4 x i1> %pg, <vscale x 4 x float> %a, <vscale x 4 x float> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x float> @llvm.aarch64.sve.fmin.nxv4f32(<vscale x 4 x i1> %pg, <vscale x 4 x float> %a, <vscale x 4 x float> %b)
  ret <vscale x 4 x float> %r
}

define float @unsupported_fastcc(float %a, float %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc float @llvm.aarch64.neon.fmin.f32(float %a, float %b)
  ret float %r
}


define float @unsupported_musttail(float %a, float %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call float @llvm.aarch64.neon.fmin.f32(float %a, float %b)
  ret float %r
}

define float @unsupported_bundle(float %a, float %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.aarch64.neon.fmin.f32(float %a, float %b) [ "deopt"(i32 0) ]
  ret float %r
}

define float @unsupported_noreturn(float %a, float %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.aarch64.neon.fmin.f32(float %a, float %b) noreturn
  ret float %r
}

define float @unsupported_returns_twice(float %a, float %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.aarch64.neon.fmin.f32(float %a, float %b) returns_twice
  ret float %r
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
  %b = load volatile float, ptr @sink_f32, align 4
  %r0 = call float @protected_fmin_f32(float %a, float %b)
  store volatile float %r0, ptr @sink_f32, align 4
  %r1 = call float @protected_fmax_f32(float %a, float %b)
  store volatile float %r1, ptr @sink_f32, align 4
  %r2 = call float @protected_fminnm_f32(float %a, float %b)
  store volatile float %r2, ptr @sink_f32, align 4
  %r3 = call float @protected_fmaxnm_f32(float %a, float %b)
  store volatile float %r3, ptr @sink_f32, align 4
  %d0 = load volatile double, ptr @sink_f64, align 8
  %d1 = load volatile double, ptr @sink_f64, align 8
  %r4 = call double @protected_fmin_f64(double %d0, double %d1)
  store volatile double %r4, ptr @sink_f64, align 8
  %h0 = load volatile half, ptr @sink_f16, align 2
  %h1 = load volatile half, ptr @sink_f16, align 2
  %r5 = call half @protected_fmin_f16(half %h0, half %h1)
  store volatile half %r5, ptr @sink_f16, align 2
  %r6 = call half @protected_fmaxnm_last_fullfp16(half %h0, half %h1)
  store volatile half %r6, ptr @sink_f16, align 2
  ret i32 0
}

; SKIP-DAG: Skipping VMP on unsupported_nnan: unsupported float call instruction
; SKIP-DAG: Skipping VMP on unsupported_f16_no_fullfp16: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_fullfp16_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_fp16fml_only: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_v1f64: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_bfloat: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_sve: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_noreturn: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_returns_twice: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_sret: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_fmin_f32:
; SKIP-NOT: Skipping VMP on protected_fmax_f32:
; SKIP-NOT: Skipping VMP on protected_fminnm_f32:
; SKIP-NOT: Skipping VMP on protected_fmaxnm_f32:
; SKIP-NOT: Skipping VMP on protected_fmin_f64:
; SKIP-NOT: Skipping VMP on protected_fmin_f16:
; SKIP-NOT: Skipping VMP on protected_fmaxnm_last_fullfp16:

; VIRT: define float @protected_fmin_f32({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.aarch64.neon.fmin.f32(
; VIRT: define float @protected_fmax_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.aarch64.neon.fmax.f32(
; VIRT: define float @protected_fminnm_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.aarch64.neon.fminnm.f32(
; VIRT: define float @protected_fmaxnm_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.aarch64.neon.fmaxnm.f32(
; VIRT: define double @protected_fmin_f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call double @llvm.aarch64.neon.fmin.f64(
; VIRT: define half @protected_fmin_f16({{.*}} #[[PROTH:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call half @llvm.aarch64.neon.fmin.f16(
; VIRT: define half @protected_fmaxnm_last_fullfp16({{.*}} #[[PROTL:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: define {{.*}} @unsupported_nnan({{.*}} #[[UNSUP0:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_f16_no_fullfp16({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT: attributes #[[PROTH]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT: attributes #[[PROTL]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; AARCH64-ASM-DAG: {{^[[:space:]]*}}fmin{{[ \t]}}{{[sdh]}}
; AARCH64-ASM-DAG: {{^[[:space:]]*}}fmax{{[ \t]}}{{[sdh]}}
; AARCH64-ASM-DAG: {{^[[:space:]]*}}fminnm{{[ \t]}}{{[sdh]}}
; AARCH64-ASM-DAG: {{^[[:space:]]*}}fmaxnm{{[ \t]}}{{[sdh]}}
; HOST: Skipping VMP: only AArch64 targets are supported
