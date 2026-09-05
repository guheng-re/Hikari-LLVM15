; Restricted AArch64 NEON v8.5-A FRINT32/64 via CallDescriptor /
; vector float VRegs (no new opcode):
;   llvm.aarch64.neon.frint32z / frint32x
;   llvm.aarch64.neon.frint64z / frint64x
;     AdvSIMD_1FloatArg: anyfloat (match)
;     ISel FRIntNNTVector / SIMDTwoVectorSD, HasFRInt3264:
;       <2 x float> / <4 x float> / <2 x double>
; z = toward zero, forced into 32- or 64-bit integer range.
; x = current rounding mode, same range.  Must not lower to
; llvm.ceil/floor/trunc/rint (those are FRINTA/M/P/I).  Scalar
; llvm.aarch64.frint32/64*.f32 is the existing path, not this
; surface.  Last-token +fptoint required.  +v8.5a is not +fptoint.
; Command-line -mattr is never consulted for eligibility.
; half / bfloat / scalar neon overload / SVE stay out.  Exact C
; non-vararg.  Ordinary tail accepted and replayed as non-tail; see vmp-direct-call-tail-eligibility-semantic.ll.
;
; Host cannot select these AArch64 intrinsics; no lli.
; FileCheck + AArch64 llc/readobj/asm (-mattr=+fptoint).
; O0/O2 x 97/7.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.ll -o %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+fptoint -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+fptoint %t.o0.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.ll -o %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+fptoint -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+fptoint %t.o2.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.s7.ll -o %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+fptoint -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+fptoint %t.o0.s7.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.s7.ll -o %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+fptoint -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+fptoint %t.o2.s7.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %s | opt -S -verify-each -aesSeed=97 -passes='default<O0>' - 2>&1 | FileCheck %s --check-prefix=HOST

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare <2 x float> @llvm.aarch64.neon.frint32z.v2f32(<2 x float>)
declare <4 x float> @llvm.aarch64.neon.frint32z.v4f32(<4 x float>)
declare <2 x double> @llvm.aarch64.neon.frint32z.v2f64(<2 x double>)
declare <4 x float> @llvm.aarch64.neon.frint32x.v4f32(<4 x float>)
declare <4 x float> @llvm.aarch64.neon.frint64z.v4f32(<4 x float>)
declare <4 x float> @llvm.aarch64.neon.frint64x.v4f32(<4 x float>)
declare <2 x double> @llvm.aarch64.neon.frint64x.v2f64(<2 x double>)
declare float @llvm.aarch64.neon.frint32z.f32(float)
declare <4 x half> @llvm.aarch64.neon.frint32z.v4f16(<4 x half>)
declare <1 x double> @llvm.aarch64.neon.frint32z.v1f64(<1 x double>)
declare <4 x bfloat> @llvm.aarch64.neon.frint32z.v4bf16(<4 x bfloat>)
declare double @llvm.aarch64.frint32z.f64(double)
declare <vscale x 4 x float> @llvm.aarch64.sve.frinta.nxv4f32(<vscale x 4 x float>, <vscale x 4 x i1>, <vscale x 4 x float>)

@sink_v2f32 = global <2 x float> zeroinitializer, align 8
@sink_v4f32 = global <4 x float> zeroinitializer, align 16
@sink_v2f64 = global <2 x double> zeroinitializer, align 16

define <4 x float> @protected_frint32z_v4f32(<4 x float> %a) noinline optnone "target-features"="+fptoint" {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.frint32z.v4f32(<4 x float> %a)
  ret <4 x float> %r
}

define <4 x float> @protected_frint32x_v4f32(<4 x float> %a) noinline optnone "target-features"="+fptoint" {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.frint32x.v4f32(<4 x float> %a)
  ret <4 x float> %r
}

define <4 x float> @protected_frint64z_v4f32(<4 x float> %a) noinline optnone "target-features"="+fptoint" {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.frint64z.v4f32(<4 x float> %a)
  ret <4 x float> %r
}

define <4 x float> @protected_frint64x_v4f32(<4 x float> %a) noinline optnone "target-features"="+fptoint" {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.frint64x.v4f32(<4 x float> %a)
  ret <4 x float> %r
}

define <2 x float> @protected_frint32z_v2f32(<2 x float> %a) noinline optnone "target-features"="+fptoint" {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.aarch64.neon.frint32z.v2f32(<2 x float> %a)
  ret <2 x float> %r
}

define <2 x double> @protected_frint32z_v2f64(<2 x double> %a) noinline optnone "target-features"="+fptoint" {
entry:
  call void @hikari_vmp()
  %r = call <2 x double> @llvm.aarch64.neon.frint32z.v2f64(<2 x double> %a)
  ret <2 x double> %r
}

define <2 x double> @protected_frint64x_v2f64(<2 x double> %a) noinline optnone "target-features"="+fptoint" {
entry:
  call void @hikari_vmp()
  %r = call <2 x double> @llvm.aarch64.neon.frint64x.v2f64(<2 x double> %a)
  ret <2 x double> %r
}

define <4 x float> @protected_frint32z_last_fptoint(<4 x float> %a) noinline optnone "target-features"="+neon,+v8.5a,+fptoint" {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.frint32z.v4f32(<4 x float> %a)
  ret <4 x float> %r
}

define <4 x float> @unsupported_no_fptoint(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.frint32z.v4f32(<4 x float> %a)
  ret <4 x float> %r
}

define <4 x float> @unsupported_fptoint_disabled(<4 x float> %a) noinline optnone "target-features"="+fptoint,-fptoint" {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.frint32z.v4f32(<4 x float> %a)
  ret <4 x float> %r
}

define <4 x float> @unsupported_v85a_only(<4 x float> %a) noinline optnone "target-features"="+v8.5a" {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.frint32z.v4f32(<4 x float> %a)
  ret <4 x float> %r
}

define float @unsupported_scalar_neon(float %a) noinline optnone "target-features"="+fptoint" {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.aarch64.neon.frint32z.f32(float %a)
  ret float %r
}

define <4 x half> @unsupported_half(<4 x half> %a) noinline optnone "target-features"="+fptoint,+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x half> @llvm.aarch64.neon.frint32z.v4f16(<4 x half> %a)
  ret <4 x half> %r
}

define <1 x double> @unsupported_v1f64(<1 x double> %a) noinline optnone "target-features"="+fptoint" {
entry:
  call void @hikari_vmp()
  %r = call <1 x double> @llvm.aarch64.neon.frint32z.v1f64(<1 x double> %a)
  ret <1 x double> %r
}

define <4 x bfloat> @unsupported_bfloat(<4 x bfloat> %a) noinline optnone "target-features"="+fptoint" {
entry:
  call void @hikari_vmp()
  %r = call <4 x bfloat> @llvm.aarch64.neon.frint32z.v4bf16(<4 x bfloat> %a)
  ret <4 x bfloat> %r
}

define double @unsupported_scalar_f64(double %a) noinline optnone "target-features"="+fptoint" {
entry:
  call void @hikari_vmp()
  %r = call double @llvm.aarch64.frint32z.f64(double %a)
  ret double %r
}

define <vscale x 4 x float> @unsupported_sve_frinta(<vscale x 4 x float> %inactive, <vscale x 4 x i1> %pg, <vscale x 4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x float> @llvm.aarch64.sve.frinta.nxv4f32(<vscale x 4 x float> %inactive, <vscale x 4 x i1> %pg, <vscale x 4 x float> %a)
  ret <vscale x 4 x float> %r
}

define <4 x float> @unsupported_fastcc(<4 x float> %a) noinline optnone "target-features"="+fptoint" {
entry:
  call void @hikari_vmp()
  %r = call fastcc <4 x float> @llvm.aarch64.neon.frint32z.v4f32(<4 x float> %a)
  ret <4 x float> %r
}


define <4 x float> @unsupported_musttail(<4 x float> %a) noinline optnone "target-features"="+fptoint" {
entry:
  call void @hikari_vmp()
  %r = musttail call <4 x float> @llvm.aarch64.neon.frint32z.v4f32(<4 x float> %a)
  ret <4 x float> %r
}

define <4 x float> @unsupported_bundle(<4 x float> %a) noinline optnone "target-features"="+fptoint" {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.frint32z.v4f32(<4 x float> %a) [ "deopt"(i32 0) ]
  ret <4 x float> %r
}

define <4 x float> @unsupported_noreturn(<4 x float> %a) noinline optnone "target-features"="+fptoint" {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.frint32z.v4f32(<4 x float> %a) noreturn
  ret <4 x float> %r
}

define <4 x float> @unsupported_returns_twice(<4 x float> %a) noinline optnone "target-features"="+fptoint" {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.frint32z.v4f32(<4 x float> %a) returns_twice
  ret <4 x float> %r
}

define i32 @main() {
entry:
  %s4 = load volatile <4 x float>, ptr @sink_v4f32, align 16
  %r0 = call <4 x float> @protected_frint32z_v4f32(<4 x float> %s4)
  store volatile <4 x float> %r0, ptr @sink_v4f32, align 16
  %r1 = call <4 x float> @protected_frint32x_v4f32(<4 x float> %s4)
  store volatile <4 x float> %r1, ptr @sink_v4f32, align 16
  %r2 = call <4 x float> @protected_frint64z_v4f32(<4 x float> %s4)
  store volatile <4 x float> %r2, ptr @sink_v4f32, align 16
  %r3 = call <4 x float> @protected_frint64x_v4f32(<4 x float> %s4)
  store volatile <4 x float> %r3, ptr @sink_v4f32, align 16
  %s2 = load volatile <2 x float>, ptr @sink_v2f32, align 8
  %r4 = call <2 x float> @protected_frint32z_v2f32(<2 x float> %s2)
  store volatile <2 x float> %r4, ptr @sink_v2f32, align 8
  %d2 = load volatile <2 x double>, ptr @sink_v2f64, align 16
  %r5 = call <2 x double> @protected_frint32z_v2f64(<2 x double> %d2)
  store volatile <2 x double> %r5, ptr @sink_v2f64, align 16
  %r6 = call <2 x double> @protected_frint64x_v2f64(<2 x double> %d2)
  store volatile <2 x double> %r6, ptr @sink_v2f64, align 16
  %r7 = call <4 x float> @protected_frint32z_last_fptoint(<4 x float> %s4)
  store volatile <4 x float> %r7, ptr @sink_v4f32, align 16
  ret i32 0
}

; SKIP-DAG: Skipping VMP on unsupported_no_fptoint: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_fptoint_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_v85a_only: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_scalar_neon: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_half: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_v1f64: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_bfloat: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_scalar_f64: unsupported frint
; SKIP-DAG: Skipping VMP on unsupported_sve_frinta: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_noreturn: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_returns_twice: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_frint32z_v4f32:
; SKIP-NOT: Skipping VMP on protected_frint32x_v4f32:
; SKIP-NOT: Skipping VMP on protected_frint64z_v4f32:
; SKIP-NOT: Skipping VMP on protected_frint64x_v4f32:
; SKIP-NOT: Skipping VMP on protected_frint32z_v2f32:
; SKIP-NOT: Skipping VMP on protected_frint32z_v2f64:
; SKIP-NOT: Skipping VMP on protected_frint64x_v2f64:
; SKIP-NOT: Skipping VMP on protected_frint32z_last_fptoint:

; VIRT: define <4 x float> @protected_frint32z_v4f32({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x float> @llvm.aarch64.neon.frint32z.v4f32(
; VIRT: define <4 x float> @protected_frint32x_v4f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x float> @llvm.aarch64.neon.frint32x.v4f32(
; VIRT: define <4 x float> @protected_frint64z_v4f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x float> @llvm.aarch64.neon.frint64z.v4f32(
; VIRT: define <4 x float> @protected_frint64x_v4f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x float> @llvm.aarch64.neon.frint64x.v4f32(
; VIRT: define <2 x float> @protected_frint32z_v2f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <2 x double> @protected_frint32z_v2f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <2 x double> @protected_frint64x_v2f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <4 x float> @protected_frint32z_last_fptoint({{.*}} #[[LAST:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: define {{.*}} @unsupported_no_fptoint({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT: attributes #[[LAST]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; AARCH64-ASM-DAG: {{^[[:space:]]*}}frint32z{{[ \t]}}{{v[0-9]+}}.4s
; AARCH64-ASM-DAG: {{^[[:space:]]*}}frint32x{{[ \t]}}{{v[0-9]+}}.4s
; AARCH64-ASM-DAG: {{^[[:space:]]*}}frint64z{{[ \t]}}{{v[0-9]+}}.4s
; AARCH64-ASM-DAG: {{^[[:space:]]*}}frint64x{{[ \t]}}{{v[0-9]+}}.4s
; AARCH64-ASM-DAG: {{^[[:space:]]*}}frint32z{{[ \t]}}{{v[0-9]+}}.2s
; AARCH64-ASM-DAG: {{^[[:space:]]*}}frint32z{{[ \t]}}{{v[0-9]+}}.2d
; AARCH64-ASM-DAG: {{^[[:space:]]*}}frint64x{{[ \t]}}{{v[0-9]+}}.2d
; HOST: Skipping VMP: only AArch64 targets are supported
