; Restricted AArch64 NEON toward-zero saturating float-to-int via
; CallDescriptor / vector VRegs (no new opcode):
;   llvm.aarch64.neon.fcvtzs / fcvtzu
;     AdvSIMD_FPToIntRounding: anyint (anyfloat)
;     ISel SIMDTwoVectorFPToInt, baseline HasNEON:
;       <2 x float> -> <2 x i32> / <4 x float> -> <4 x i32>
;       <2 x double> -> <2 x i64>
;     plus HasFullFP16:
;       <4 x half> -> <4 x i16> / <8 x half> -> <8 x i16>
; Clang vcvt*_s / vcvt*_u.  Must not lower to fptosi/fptoui
; (FCVTZS saturates OOR and maps NaN to 0; fptosi is poison).
; Not rounding fcvt{a,m,n,p}{s,u}.  Not fixed-point vcvtfp2fx*.
; Well-formed scalar is
; vmp-aarch64-neon-scalar-fcvtz-semantic.ll and must not stay
; here as a skip (it would virtualize).  v1i64 stays out.
; Last-token +fullfp16
; required for half; f32/f64 need no extra token.  +fp16fml
; does not count.  Command-line -mattr never consulted for
; eligibility.  Exact C non-vararg.  Ordinary tail accepted and replayed as non-tail; see vmp-direct-call-tail-eligibility-semantic.ll.
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
declare <2 x i32> @llvm.aarch64.neon.fcvtzs.v2i32.v2f32(<2 x float>)
declare <4 x i32> @llvm.aarch64.neon.fcvtzs.v4i32.v4f32(<4 x float>)
declare <2 x i64> @llvm.aarch64.neon.fcvtzs.v2i64.v2f64(<2 x double>)
declare <4 x i16> @llvm.aarch64.neon.fcvtzs.v4i16.v4f16(<4 x half>)
declare <8 x i16> @llvm.aarch64.neon.fcvtzu.v8i16.v8f16(<8 x half>)
declare <2 x i32> @llvm.aarch64.neon.fcvtzu.v2i32.v2f32(<2 x float>)
declare <4 x i32> @llvm.aarch64.neon.fcvtzu.v4i32.v4f32(<4 x float>)
declare <2 x i64> @llvm.aarch64.neon.fcvtzu.v2i64.v2f64(<2 x double>)
; Well-formed scalar llvm.aarch64.neon.fcvtzs.i32.f32 is
; vmp-aarch64-neon-scalar-fcvtz-semantic.ll and would
; virtualize here.
declare <1 x i64> @llvm.aarch64.neon.fcvtzu.v1i64.v1f64(<1 x double>)
declare <2 x i16> @llvm.aarch64.neon.fcvtzs.v2i16.v2f16(<2 x half>)
declare <4 x i16> @llvm.aarch64.neon.fcvtzs.v4i16.v4bf16(<4 x bfloat>)
declare <2 x i32> @llvm.aarch64.neon.fcvtzs.v2i32.v4f32(<4 x float>)
declare <vscale x 4 x i32> @llvm.aarch64.sve.fcvtzs.nxv4i32.nxv4f32(<vscale x 4 x i32>, <vscale x 4 x i1>, <vscale x 4 x float>)

@sink_v2f32 = global <2 x float> zeroinitializer, align 8
@sink_v2i32 = global <2 x i32> zeroinitializer, align 8
@sink_v4f32 = global <4 x float> zeroinitializer, align 16
@sink_v4i32 = global <4 x i32> zeroinitializer, align 16
@sink_v2f64 = global <2 x double> zeroinitializer, align 16
@sink_v2i64 = global <2 x i64> zeroinitializer, align 16
@sink_v4f16 = global <4 x half> zeroinitializer, align 8
@sink_v4i16 = global <4 x i16> zeroinitializer, align 8
@sink_v8f16 = global <8 x half> zeroinitializer, align 16
@sink_v8i16 = global <8 x i16> zeroinitializer, align 16

define <2 x i32> @protected_fcvtzs_v2f32(<2 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i32> @llvm.aarch64.neon.fcvtzs.v2i32.v2f32(<2 x float> %a)
  ret <2 x i32> %r
}

define <4 x i32> @protected_fcvtzs_v4f32(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.fcvtzs.v4i32.v4f32(<4 x float> %a)
  ret <4 x i32> %r
}

define <2 x i64> @protected_fcvtzs_v2f64(<2 x double> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.aarch64.neon.fcvtzs.v2i64.v2f64(<2 x double> %a)
  ret <2 x i64> %r
}

define <2 x i32> @protected_fcvtzu_v2f32(<2 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i32> @llvm.aarch64.neon.fcvtzu.v2i32.v2f32(<2 x float> %a)
  ret <2 x i32> %r
}

define <4 x i32> @protected_fcvtzu_v4f32(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.fcvtzu.v4i32.v4f32(<4 x float> %a)
  ret <4 x i32> %r
}

define <2 x i64> @protected_fcvtzu_v2f64(<2 x double> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.aarch64.neon.fcvtzu.v2i64.v2f64(<2 x double> %a)
  ret <2 x i64> %r
}

define <4 x i16> @protected_fcvtzs_v4f16(<4 x half> %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i16> @llvm.aarch64.neon.fcvtzs.v4i16.v4f16(<4 x half> %a)
  ret <4 x i16> %r
}

define <8 x i16> @protected_fcvtzu_v8f16(<8 x half> %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <8 x i16> @llvm.aarch64.neon.fcvtzu.v8i16.v8f16(<8 x half> %a)
  ret <8 x i16> %r
}

define <4 x i16> @protected_fcvtzs_last_fullfp16(<4 x half> %a) noinline optnone "target-features"="+neon,+fp16fml,+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i16> @llvm.aarch64.neon.fcvtzs.v4i16.v4f16(<4 x half> %a)
  ret <4 x i16> %r
}

; Toward-zero / OOR / NaN constants: 0.9, -0.9, +inf, qNaN.
define <4 x i32> @protected_fcvtzs_bounds_v4f32() noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.fcvtzs.v4i32.v4f32(
      <4 x float> <float 0x3FECCCCCC0000000, float 0xBFECCCCCC0000000,
                   float 0x7FF0000000000000, float 0x7FF8000000000000>)
  ret <4 x i32> %r
}

define <4 x i16> @unsupported_f16_no_fullfp16(<4 x half> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i16> @llvm.aarch64.neon.fcvtzs.v4i16.v4f16(<4 x half> %a)
  ret <4 x i16> %r
}

define <4 x i16> @unsupported_fullfp16_disabled(<4 x half> %a) noinline optnone "target-features"="+fullfp16,-fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i16> @llvm.aarch64.neon.fcvtzs.v4i16.v4f16(<4 x half> %a)
  ret <4 x i16> %r
}

define <4 x i16> @unsupported_fp16fml_only(<4 x half> %a) noinline optnone "target-features"="+fp16fml" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i16> @llvm.aarch64.neon.fcvtzs.v4i16.v4f16(<4 x half> %a)
  ret <4 x i16> %r
}

; Well-formed rounding fcvt{a,m,n,p}{s,u} is covered by
; vmp-aarch64-neon-fcvt-rounding-semantic.ll.  Well-formed
; fptosi / fptoui already virtualize as vector conversions.

define <1 x i64> @unsupported_v1f64(<1 x double> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <1 x i64> @llvm.aarch64.neon.fcvtzu.v1i64.v1f64(<1 x double> %a)
  ret <1 x i64> %r
}

define <2 x i16> @unsupported_v2f16(<2 x half> %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <2 x i16> @llvm.aarch64.neon.fcvtzs.v2i16.v2f16(<2 x half> %a)
  ret <2 x i16> %r
}

define <4 x i16> @unsupported_bfloat(<4 x bfloat> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i16> @llvm.aarch64.neon.fcvtzs.v4i16.v4bf16(<4 x bfloat> %a)
  ret <4 x i16> %r
}

define <2 x i32> @unsupported_mismatch(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i32> @llvm.aarch64.neon.fcvtzs.v2i32.v4f32(<4 x float> %a)
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
  %r = call fastcc <4 x i32> @llvm.aarch64.neon.fcvtzs.v4i32.v4f32(<4 x float> %a)
  ret <4 x i32> %r
}


define <4 x i32> @unsupported_musttail(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call <4 x i32> @llvm.aarch64.neon.fcvtzs.v4i32.v4f32(<4 x float> %a)
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_bundle(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.fcvtzs.v4i32.v4f32(<4 x float> %a) [ "deopt"(i32 0) ]
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_noreturn(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.fcvtzs.v4i32.v4f32(<4 x float> %a) noreturn
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_returns_twice(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.fcvtzs.v4i32.v4f32(<4 x float> %a) returns_twice
  ret <4 x i32> %r
}

define void @unsupported_sret(ptr sret(i32) %p, ptr byval(i32) %q) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @ext_sret_byval(ptr sret(i32) %p, ptr byval(i32) %q)
  ret void
}

define i32 @main() {
entry:
  %s2 = load volatile <2 x float>, ptr @sink_v2f32, align 8
  %r0 = call <2 x i32> @protected_fcvtzs_v2f32(<2 x float> %s2)
  store volatile <2 x i32> %r0, ptr @sink_v2i32, align 8
  %s4 = load volatile <4 x float>, ptr @sink_v4f32, align 16
  %r1 = call <4 x i32> @protected_fcvtzs_v4f32(<4 x float> %s4)
  store volatile <4 x i32> %r1, ptr @sink_v4i32, align 16
  %d2 = load volatile <2 x double>, ptr @sink_v2f64, align 16
  %r2 = call <2 x i64> @protected_fcvtzs_v2f64(<2 x double> %d2)
  store volatile <2 x i64> %r2, ptr @sink_v2i64, align 16
  %r3 = call <2 x i32> @protected_fcvtzu_v2f32(<2 x float> %s2)
  store volatile <2 x i32> %r3, ptr @sink_v2i32, align 8
  %r4 = call <4 x i32> @protected_fcvtzu_v4f32(<4 x float> %s4)
  store volatile <4 x i32> %r4, ptr @sink_v4i32, align 16
  %r5 = call <2 x i64> @protected_fcvtzu_v2f64(<2 x double> %d2)
  store volatile <2 x i64> %r5, ptr @sink_v2i64, align 16
  %h4 = load volatile <4 x half>, ptr @sink_v4f16, align 8
  %r6 = call <4 x i16> @protected_fcvtzs_v4f16(<4 x half> %h4)
  store volatile <4 x i16> %r6, ptr @sink_v4i16, align 8
  %h8 = load volatile <8 x half>, ptr @sink_v8f16, align 16
  %r7 = call <8 x i16> @protected_fcvtzu_v8f16(<8 x half> %h8)
  store volatile <8 x i16> %r7, ptr @sink_v8i16, align 16
  %r8 = call <4 x i16> @protected_fcvtzs_last_fullfp16(<4 x half> %h4)
  store volatile <4 x i16> %r8, ptr @sink_v4i16, align 8
  %r9 = call <4 x i32> @protected_fcvtzs_bounds_v4f32()
  store volatile <4 x i32> %r9, ptr @sink_v4i32, align 16
  ret i32 0
}

; SKIP-DAG: Skipping VMP on unsupported_f16_no_fullfp16: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_fullfp16_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_fp16fml_only: unsupported target feature
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
; SKIP-DAG: Skipping VMP on unsupported_sret: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_fcvtzs_v2f32:
; SKIP-NOT: Skipping VMP on protected_fcvtzs_v4f32:
; SKIP-NOT: Skipping VMP on protected_fcvtzs_v2f64:
; SKIP-NOT: Skipping VMP on protected_fcvtzu_v2f32:
; SKIP-NOT: Skipping VMP on protected_fcvtzu_v4f32:
; SKIP-NOT: Skipping VMP on protected_fcvtzu_v2f64:
; SKIP-NOT: Skipping VMP on protected_fcvtzs_v4f16:
; SKIP-NOT: Skipping VMP on protected_fcvtzu_v8f16:
; SKIP-NOT: Skipping VMP on protected_fcvtzs_last_fullfp16:
; SKIP-NOT: Skipping VMP on protected_fcvtzs_bounds_v4f32:

; VIRT: define <2 x i32> @protected_fcvtzs_v2f32({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i32> @llvm.aarch64.neon.fcvtzs.v2i32.v2f32(
; VIRT: define <4 x i32> @protected_fcvtzs_v4f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <2 x i64> @protected_fcvtzs_v2f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <2 x i32> @protected_fcvtzu_v2f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i32> @llvm.aarch64.neon.fcvtzu.v2i32.v2f32(
; VIRT: define <4 x i32> @protected_fcvtzu_v4f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <2 x i64> @protected_fcvtzu_v2f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <4 x i16> @protected_fcvtzs_v4f16({{.*}} #[[PROTH:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i16> @llvm.aarch64.neon.fcvtzs.v4i16.v4f16(
; VIRT: define <8 x i16> @protected_fcvtzu_v8f16({{.*}} #[[PROTH]] {
; VIRT: vmp.dispatch:
; VIRT: define <4 x i16> @protected_fcvtzs_last_fullfp16({{.*}} #[[PROTL:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: define <4 x i32> @protected_fcvtzs_bounds_v4f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.aarch64.neon.fcvtzs.v4i32.v4f32(
; VIRT: define {{.*}} @unsupported_f16_no_fullfp16({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; AARCH64-ASM: {{^[[:space:]]*}}fcvtzs{{[ \t]}}
; AARCH64-ASM: {{^[[:space:]]*}}fcvtzu{{[ \t]}}
; HOST: Skipping VMP: only AArch64 targets are supported
