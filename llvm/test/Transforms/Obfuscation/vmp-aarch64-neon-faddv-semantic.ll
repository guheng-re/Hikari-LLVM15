; Restricted AArch64 NEON across-lane floating add via
; CallDescriptor (vector VReg in, scalar float VReg out):
;   llvm.aarch64.neon.faddv
;     AdvSIMD_1VectorArg_Float_Across: anyfloat (anyvector)
;     ISel legal pairs (AArch64InstrInfo.td, FADDP tree, HasNEON):
;       float  (<2 x float>)   FADDPv2i32p
;       float  (<4 x float>)   FADDPv4f32 then FADDPv2i32p
;       double (<2 x double>)  FADDPv2i64p
; Clang vaddv_f32 / vaddvq_f32 / vaddvq_f64.  No neon.faddv half
; ISel; vaddv_f16 is SVE.  Must not lower to
; llvm.vector.reduce.fadd, pairwise neon.faddp, element-wise fadd,
; or unordered reassociation.  FastMathFlags are rejected by the
; existing float-call FMF gate.  Exact C non-vararg.  Ordinary tail accepted and replayed as non-tail; see vmp-direct-call-tail-eligibility-semantic.ll.  No extra +neon / +fullfp16.
; No new opcode.
;
; Host cannot select this AArch64 intrinsic; no lli.
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
declare void @ext_sret_byval(ptr sret(i32), ptr byval(i32))
declare float @llvm.aarch64.neon.faddv.f32.v2f32(<2 x float>)
declare float @llvm.aarch64.neon.faddv.f32.v4f32(<4 x float>)
declare double @llvm.aarch64.neon.faddv.f64.v2f64(<2 x double>)
declare half @llvm.aarch64.neon.faddv.f16.v4f16(<4 x half>)
declare half @llvm.aarch64.neon.faddv.f16.v2f16(<2 x half>)
declare bfloat @llvm.aarch64.neon.faddv.bf16.v4bf16(<4 x bfloat>)
declare double @llvm.aarch64.neon.faddv.f64.v1f64(<1 x double>)
declare float @llvm.aarch64.neon.faddv.f32.v3f32(<3 x float>)
declare double @llvm.aarch64.neon.faddv.f64.v4f32(<4 x float>)
declare float @llvm.aarch64.sve.faddv.nxv4f32(<vscale x 4 x i1>, <vscale x 4 x float>)

@sink_v2f32 = global <2 x float> zeroinitializer, align 8
@sink_v4f32 = global <4 x float> zeroinitializer, align 16
@sink_v2f64 = global <2 x double> zeroinitializer, align 16
@sink_f32 = global float 0.0, align 4
@sink_f64 = global double 0.0, align 8

define float @protected_faddv_v2f32(<2 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.aarch64.neon.faddv.f32.v2f32(<2 x float> %a)
  ret float %r
}

define float @protected_faddv_v4f32(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.aarch64.neon.faddv.f32.v4f32(<4 x float> %a)
  ret float %r
}

define double @protected_faddv_v2f64(<2 x double> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call double @llvm.aarch64.neon.faddv.f64.v2f64(<2 x double> %a)
  ret double %r
}

define float @unsupported_fmf(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call nnan ninf float @llvm.aarch64.neon.faddv.f32.v4f32(<4 x float> %a)
  ret float %r
}

define half @unsupported_half(<4 x half> %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.aarch64.neon.faddv.f16.v4f16(<4 x half> %a)
  ret half %r
}

define half @unsupported_v2f16(<2 x half> %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.aarch64.neon.faddv.f16.v2f16(<2 x half> %a)
  ret half %r
}

define bfloat @unsupported_bfloat(<4 x bfloat> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.aarch64.neon.faddv.bf16.v4bf16(<4 x bfloat> %a)
  ret bfloat %r
}

define double @unsupported_v1f64(<1 x double> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call double @llvm.aarch64.neon.faddv.f64.v1f64(<1 x double> %a)
  ret double %r
}

define float @unsupported_v3f32(<3 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.aarch64.neon.faddv.f32.v3f32(<3 x float> %a)
  ret float %r
}

define double @unsupported_mismatch(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call double @llvm.aarch64.neon.faddv.f64.v4f32(<4 x float> %a)
  ret double %r
}

define float @unsupported_sve_faddv(<vscale x 4 x i1> %pg, <vscale x 4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.aarch64.sve.faddv.nxv4f32(<vscale x 4 x i1> %pg, <vscale x 4 x float> %a)
  ret float %r
}

define float @unsupported_fastcc(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc float @llvm.aarch64.neon.faddv.f32.v4f32(<4 x float> %a)
  ret float %r
}


define float @unsupported_musttail(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call float @llvm.aarch64.neon.faddv.f32.v4f32(<4 x float> %a)
  ret float %r
}

define float @unsupported_bundle(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.aarch64.neon.faddv.f32.v4f32(<4 x float> %a) [ "deopt"(i32 0) ]
  ret float %r
}

define float @unsupported_noreturn(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.aarch64.neon.faddv.f32.v4f32(<4 x float> %a) noreturn
  ret float %r
}

define float @unsupported_returns_twice(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.aarch64.neon.faddv.f32.v4f32(<4 x float> %a) returns_twice
  ret float %r
}

define void @unsupported_sret(ptr sret(i32) %p, ptr byval(i32) %q) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @ext_sret_byval(ptr sret(i32) %p, ptr byval(i32) %q)
  ret void
}

; Well-formed llvm.aarch64.neon.faddp is
; vmp-aarch64-neon-faddp-semantic.ll and must not stay here as a
; negative (it would virtualize).  Well-formed
; llvm.vector.reduce.fadd is the generic reduce surface.

define i32 @main() {
entry:
  %a2 = load volatile <2 x float>, ptr @sink_v2f32, align 8
  %r0 = call float @protected_faddv_v2f32(<2 x float> %a2)
  store volatile float %r0, ptr @sink_f32, align 4
  %a4 = load volatile <4 x float>, ptr @sink_v4f32, align 16
  %r1 = call float @protected_faddv_v4f32(<4 x float> %a4)
  store volatile float %r1, ptr @sink_f32, align 4
  %ad = load volatile <2 x double>, ptr @sink_v2f64, align 16
  %r2 = call double @protected_faddv_v2f64(<2 x double> %ad)
  store volatile double %r2, ptr @sink_f64, align 8
  ret i32 0
}

; SKIP-DAG: Skipping VMP on unsupported_fmf: unsupported float call instruction
; SKIP-DAG: Skipping VMP on unsupported_half: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_v2f16: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_bfloat: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_v1f64: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_v3f32: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_mismatch: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_sve_faddv: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_noreturn: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_returns_twice: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_sret: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_faddv_v2f32:
; SKIP-NOT: Skipping VMP on protected_faddv_v4f32:
; SKIP-NOT: Skipping VMP on protected_faddv_v2f64:

; VIRT: define float @protected_faddv_v2f32({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.aarch64.neon.faddv.f32.v2f32(
; VIRT: define float @protected_faddv_v4f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.aarch64.neon.faddv.f32.v4f32(
; VIRT: define double @protected_faddv_v2f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call double @llvm.aarch64.neon.faddv.f64.v2f64(
; VIRT: define {{.*}} @unsupported_v1f64({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; AARCH64-ASM: {{^[[:space:]]*}}faddp{{[ \t]}}
; HOST: Skipping VMP: only AArch64 targets are supported
