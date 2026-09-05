; Restricted AArch64 NEON inexact narrowing (round-to-odd) via
; CallDescriptor / existing float VRegs (no new opcode):
;   llvm.aarch64.neon.fcvtxn
;     AdvSIMD_1VectorArg_Expand: anyvector (anyvector)
;     ISel SIMDFPInexactCvtTwoVector, baseline HasNEON:
;       <2 x float>(<2 x double>) -> fcvtxn v.2s, v.2d
;   llvm.aarch64.sisd.fcvtxn
;     float(double) -> fcvtxn s, d
; High-half fcvtxn2 is concat_vectors of the same vector ID, not
; a second IR ID.  Must not lower to fptrunc / FCVTN.  No neon.fcvtn
; IR ID.  half / bfloat / v4f32 direct / SVE stay out.  No last-token
; gate.  Exact C non-vararg.  Ordinary tail accepted and replayed as non-tail; see vmp-direct-call-tail-eligibility-semantic.ll.
;
; Host cannot select these AArch64 intrinsics; no lli.
; FileCheck + AArch64 llc/readobj/asm.  O0/O2 x 97/7.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.ll -o %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o0.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.ll -o %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o2.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.s7.ll -o %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o0.s7.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.s7.ll -o %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o2.s7.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %s | opt -S -verify-each -aesSeed=97 -passes='default<O0>' - 2>&1 | FileCheck %s --check-prefix=HOST

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare <2 x float> @llvm.aarch64.neon.fcvtxn.v2f32.v2f64(<2 x double>)
declare float @llvm.aarch64.sisd.fcvtxn(double)
declare <2 x i32> @llvm.aarch64.neon.fcvtxn.v2i32.v2f64(<2 x double>)
declare <4 x float> @llvm.aarch64.neon.fcvtxn.v4f32.v2f64(<2 x double>)
declare <2 x half> @llvm.aarch64.neon.fcvtxn.v2f16.v2f32(<2 x float>)
declare <2 x float> @llvm.aarch64.neon.fcvtxn.v2f32.v2bf16(<2 x bfloat>)
declare <vscale x 4 x float> @llvm.aarch64.sve.fcvtxnt.f32f64(<vscale x 4 x float>, <vscale x 2 x i1>, <vscale x 2 x double>)

@sink_v2f64 = global <2 x double> zeroinitializer, align 16
@sink_v2f32 = global <2 x float> zeroinitializer, align 8
@sink_f64 = global double 0.0, align 8
@sink_f32 = global float 0.0, align 4
@sink_v4f32 = global <4 x float> zeroinitializer, align 16

define <2 x float> @protected_fcvtxn_v2f64(<2 x double> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.aarch64.neon.fcvtxn.v2f32.v2f64(<2 x double> %a)
  ret <2 x float> %r
}

define float @protected_sisd_fcvtxn(double %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.aarch64.sisd.fcvtxn(double %a)
  ret float %r
}

; High-half is concat of the same vector ID, not fcvtxn2.
define <4 x float> @protected_fcvtxn_high(<2 x float> %lo, <2 x double> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %hi = call <2 x float> @llvm.aarch64.neon.fcvtxn.v2f32.v2f64(<2 x double> %a)
  %r = shufflevector <2 x float> %lo, <2 x float> %hi, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  ret <4 x float> %r
}

define <2 x i32> @unsupported_i32_dest(<2 x double> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i32> @llvm.aarch64.neon.fcvtxn.v2i32.v2f64(<2 x double> %a)
  ret <2 x i32> %r
}

define <4 x float> @unsupported_v4f32(<2 x double> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.fcvtxn.v4f32.v2f64(<2 x double> %a)
  ret <4 x float> %r
}

define <2 x half> @unsupported_half(<2 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x half> @llvm.aarch64.neon.fcvtxn.v2f16.v2f32(<2 x float> %a)
  ret <2 x half> %r
}

define <2 x float> @unsupported_bfloat(<2 x bfloat> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.aarch64.neon.fcvtxn.v2f32.v2bf16(<2 x bfloat> %a)
  ret <2 x float> %r
}

define <vscale x 4 x float> @unsupported_sve_fcvtxnt(<vscale x 4 x float> %a, <vscale x 2 x i1> %pg, <vscale x 2 x double> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x float> @llvm.aarch64.sve.fcvtxnt.f32f64(<vscale x 4 x float> %a, <vscale x 2 x i1> %pg, <vscale x 2 x double> %b)
  ret <vscale x 4 x float> %r
}

define <2 x float> @unsupported_fastcc(<2 x double> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc <2 x float> @llvm.aarch64.neon.fcvtxn.v2f32.v2f64(<2 x double> %a)
  ret <2 x float> %r
}


define <2 x float> @unsupported_musttail(<2 x double> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call <2 x float> @llvm.aarch64.neon.fcvtxn.v2f32.v2f64(<2 x double> %a)
  ret <2 x float> %r
}

define <2 x float> @unsupported_bundle(<2 x double> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.aarch64.neon.fcvtxn.v2f32.v2f64(<2 x double> %a) [ "deopt"(i32 0) ]
  ret <2 x float> %r
}

define <2 x float> @unsupported_noreturn(<2 x double> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.aarch64.neon.fcvtxn.v2f32.v2f64(<2 x double> %a) noreturn
  ret <2 x float> %r
}

define <2 x float> @unsupported_returns_twice(<2 x double> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.aarch64.neon.fcvtxn.v2f32.v2f64(<2 x double> %a) returns_twice
  ret <2 x float> %r
}

define i32 @main() {
entry:
  %d = load volatile <2 x double>, ptr @sink_v2f64, align 16
  %r0 = call <2 x float> @protected_fcvtxn_v2f64(<2 x double> %d)
  store volatile <2 x float> %r0, ptr @sink_v2f32, align 8
  %s = load volatile double, ptr @sink_f64, align 8
  %r1 = call float @protected_sisd_fcvtxn(double %s)
  store volatile float %r1, ptr @sink_f32, align 4
  %lo = load volatile <2 x float>, ptr @sink_v2f32, align 8
  %r2 = call <4 x float> @protected_fcvtxn_high(<2 x float> %lo, <2 x double> %d)
  store volatile <4 x float> %r2, ptr @sink_v4f32, align 16
  ret i32 0
}

; SKIP-DAG: Skipping VMP on unsupported_i32_dest: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_v4f32: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_half: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_bfloat: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_sve_fcvtxnt: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_noreturn: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_returns_twice: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_fcvtxn_v2f64:
; SKIP-NOT: Skipping VMP on protected_sisd_fcvtxn:
; SKIP-NOT: Skipping VMP on protected_fcvtxn_high:

; VIRT: define <2 x float> @protected_fcvtxn_v2f64({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x float> @llvm.aarch64.neon.fcvtxn.v2f32.v2f64(
; VIRT: define float @protected_sisd_fcvtxn({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.aarch64.sisd.fcvtxn(
; VIRT: define <4 x float> @protected_fcvtxn_high({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x float> @llvm.aarch64.neon.fcvtxn.v2f32.v2f64(
; VIRT: define {{.*}} @unsupported_i32_dest({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; AARCH64-ASM: {{^[[:space:]]*}}fcvtxn{{[ \t]}}{{v[0-9]+}}.2s
; AARCH64-ASM: {{^[[:space:]]*}}fcvtxn{{[ \t]}}s
; HOST: Skipping VMP: only AArch64 targets are supported
