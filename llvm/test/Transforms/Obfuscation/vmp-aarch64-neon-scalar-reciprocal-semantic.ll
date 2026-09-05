; Restricted AArch64 scalar reciprocal estimate / Newton step via
; CallDescriptor / scalar float VRegs:
;   llvm.aarch64.neon.frecpe / frsqrte
;     AdvSIMD_1FloatArg: anyfloat (match)
;     ISel SIMDFPTwoScalar + f16/f32/f64 pats, HasNEONorSME
;   llvm.aarch64.neon.frecps / frsqrts
;     AdvSIMD_2FloatArg: anyfloat (match, match)
;     ISel SIMDFPThreeScalar, HasNEONorSME
; Half needs HasFullFP16 (FRECPEv1f16 / *16).  Clang vrecpes_f32 /
; vrecped_f64 / vrecpeh_f16 / vrecpss_f32 / ... and vrsqrt*.
; Must not lower to fdiv / fmul / fsub (estimate tables; step is
; 2-ab or (3-ab)/2).  Vector estimate/step is
; vmp-aarch64-neon-reciprocal-semantic.ll and must not stay here
; as a well-formed skip.  frecpx is
; vmp-aarch64-neon-frecpx-semantic.ll.  v1f64 stays out.
; Last-token +fullfp16 required for half; f32/f64 need no extra
; token.  +fp16fml does not count.  FastMathFlags are rejected
; by the existing float-call FMF gate.  No rounding ImmArg.
; Command-line -mattr never consulted.  Exact C non-vararg.
; Ordinary tail accepted and replayed as non-tail; see vmp-direct-call-tail-eligibility-semantic.ll.  No new opcode.
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
declare float @llvm.aarch64.neon.frecpe.f32(float)
declare double @llvm.aarch64.neon.frsqrte.f64(double)
declare float @llvm.aarch64.neon.frecps.f32(float, float)
declare double @llvm.aarch64.neon.frsqrts.f64(double, double)
declare half @llvm.aarch64.neon.frecpe.f16(half)
declare half @llvm.aarch64.neon.frecps.f16(half, half)
declare half @llvm.aarch64.neon.frsqrte.f16(half)
declare <1 x double> @llvm.aarch64.neon.frecpe.v1f64(<1 x double>)
declare bfloat @llvm.aarch64.neon.frecpe.bf16(bfloat)
declare <vscale x 4 x float> @llvm.aarch64.sve.frecpe.x.nxv4f32(<vscale x 4 x float>)

@sink_f32 = global float 0.000000e+00, align 4
@sink_f64 = global double 0.000000e+00, align 8
@sink_f16 = global half 0xH0000, align 2

define float @protected_frecpe_f32(float %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.aarch64.neon.frecpe.f32(float %a)
  ret float %r
}

define double @protected_frsqrte_f64(double %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call double @llvm.aarch64.neon.frsqrte.f64(double %a)
  ret double %r
}

define float @protected_frecps_f32(float %a, float %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.aarch64.neon.frecps.f32(float %a, float %b)
  ret float %r
}

define double @protected_frsqrts_f64(double %a, double %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call double @llvm.aarch64.neon.frsqrts.f64(double %a, double %b)
  ret double %r
}

define half @protected_frecpe_f16(half %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.aarch64.neon.frecpe.f16(half %a)
  ret half %r
}

define half @protected_frecps_f16(half %a, half %b) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.aarch64.neon.frecps.f16(half %a, half %b)
  ret half %r
}

define half @protected_frsqrte_last_fullfp16(half %a) noinline optnone "target-features"="+neon,+fp16fml,+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.aarch64.neon.frsqrte.f16(half %a)
  ret half %r
}

; ----- negatives: selected, not virtualized -----

define float @unsupported_fmf(float %a, float %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call nnan ninf float @llvm.aarch64.neon.frecps.f32(float %a, float %b)
  ret float %r
}

define half @unsupported_f16_no_fullfp16(half %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.aarch64.neon.frecpe.f16(half %a)
  ret half %r
}

define half @unsupported_fullfp16_disabled(half %a, half %b) noinline optnone "target-features"="+fullfp16,-fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.aarch64.neon.frecps.f16(half %a, half %b)
  ret half %r
}

define half @unsupported_fp16fml_only(half %a) noinline optnone "target-features"="+fp16fml" {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.aarch64.neon.frsqrte.f16(half %a)
  ret half %r
}

define <1 x double> @unsupported_v1f64(<1 x double> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <1 x double> @llvm.aarch64.neon.frecpe.v1f64(<1 x double> %a)
  ret <1 x double> %r
}

define bfloat @unsupported_bfloat(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.aarch64.neon.frecpe.bf16(bfloat %a)
  ret bfloat %r
}

define <vscale x 4 x float> @unsupported_sve(<vscale x 4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x float> @llvm.aarch64.sve.frecpe.x.nxv4f32(<vscale x 4 x float> %a)
  ret <vscale x 4 x float> %r
}

define float @unsupported_fastcc(float %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc float @llvm.aarch64.neon.frecpe.f32(float %a)
  ret float %r
}


define float @unsupported_musttail(float %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call float @llvm.aarch64.neon.frecpe.f32(float %a)
  ret float %r
}

define float @unsupported_bundle(float %a, float %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.aarch64.neon.frecps.f32(float %a, float %b) [ "deopt"(i32 0) ]
  ret float %r
}

define float @unsupported_noreturn(float %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.aarch64.neon.frecpe.f32(float %a) noreturn
  ret float %r
}

define float @unsupported_returns_twice(float %a, float %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.aarch64.neon.frecps.f32(float %a, float %b) returns_twice
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
  %s = load volatile float, ptr @sink_f32, align 4
  %r0 = call float @protected_frecpe_f32(float %s)
  store volatile float %r0, ptr @sink_f32, align 4
  %d = load volatile double, ptr @sink_f64, align 8
  %r1 = call double @protected_frsqrte_f64(double %d)
  store volatile double %r1, ptr @sink_f64, align 8
  %r2 = call float @protected_frecps_f32(float %s, float %r0)
  store volatile float %r2, ptr @sink_f32, align 4
  %r3 = call double @protected_frsqrts_f64(double %d, double %r1)
  store volatile double %r3, ptr @sink_f64, align 8
  %h = load volatile half, ptr @sink_f16, align 2
  %r4 = call half @protected_frecpe_f16(half %h)
  store volatile half %r4, ptr @sink_f16, align 2
  %r5 = call half @protected_frecps_f16(half %h, half %r4)
  store volatile half %r5, ptr @sink_f16, align 2
  %r6 = call half @protected_frsqrte_last_fullfp16(half %h)
  store volatile half %r6, ptr @sink_f16, align 2
  ret i32 0
}

; SKIP-DAG: Skipping VMP on unsupported_fmf: unsupported float call instruction
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
; SKIP-NOT: Skipping VMP on protected_frecpe_f32:
; SKIP-NOT: Skipping VMP on protected_frsqrte_f64:
; SKIP-NOT: Skipping VMP on protected_frecps_f32:
; SKIP-NOT: Skipping VMP on protected_frsqrts_f64:
; SKIP-NOT: Skipping VMP on protected_frecpe_f16:
; SKIP-NOT: Skipping VMP on protected_frecps_f16:
; SKIP-NOT: Skipping VMP on protected_frsqrte_last_fullfp16:

; VIRT: define float @protected_frecpe_f32({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.aarch64.neon.frecpe.f32(
; VIRT: define double @protected_frsqrte_f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call double @llvm.aarch64.neon.frsqrte.f64(
; VIRT: define float @protected_frecps_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.aarch64.neon.frecps.f32(
; VIRT: define double @protected_frsqrts_f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call double @llvm.aarch64.neon.frsqrts.f64(
; VIRT: define half @protected_frecpe_f16({{.*}} #[[PROTH:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call half @llvm.aarch64.neon.frecpe.f16(
; VIRT: define half @protected_frecps_f16({{.*}} #[[PROTH]] {
; VIRT: vmp.dispatch:
; VIRT: call half @llvm.aarch64.neon.frecps.f16(
; VIRT: define half @protected_frsqrte_last_fullfp16({{.*}} #[[LAST:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call half @llvm.aarch64.neon.frsqrte.f16(
; VIRT: define {{.*}} @unsupported_f16_no_fullfp16({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT: attributes #[[PROTH]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT: attributes #[[LAST]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; AARCH64-ASM-DAG: {{^[[:space:]]*}}frecpe{{[ \t]}}{{s[0-9]+}}
; AARCH64-ASM-DAG: {{^[[:space:]]*}}frsqrte{{[ \t]}}{{d[0-9]+}}
; AARCH64-ASM-DAG: {{^[[:space:]]*}}frecps{{[ \t]}}{{s[0-9]+}}
; AARCH64-ASM-DAG: {{^[[:space:]]*}}frsqrts{{[ \t]}}{{d[0-9]+}}
; AARCH64-ASM-DAG: {{^[[:space:]]*}}frecpe{{[ \t]}}{{h[0-9]+}}
; AARCH64-ASM-DAG: {{^[[:space:]]*}}frecps{{[ \t]}}{{h[0-9]+}}
; AARCH64-ASM-DAG: {{^[[:space:]]*}}frsqrte{{[ \t]}}{{h[0-9]+}}
; HOST: Skipping VMP: only AArch64 targets are supported
