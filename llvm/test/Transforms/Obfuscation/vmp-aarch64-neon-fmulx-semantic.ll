; Restricted AArch64 NEON extending multiply via CallDescriptor /
; vector VRegs (no new opcode):
;   llvm.aarch64.neon.fmulx
;     AdvSIMD_2FloatArg: anyfloat (match, match), Commutative
;     ISel SIMDThreeSameVectorFP, baseline HasNEON:
;       <2 x float> / <4 x float> / <2 x double>
;     plus HasFullFP16 for <4 x half> / <8 x half>
; No neon.fmulx.lane / .laneq IR ID.  clang vmulx_lane is splat +
; the same ID (ISel SIMDFPIndexed may fold duplane).  Must not
; replay as fmul (0*Inf / NaN differ).  Well-formed scalar
; fmulx.f32/.f64/.f16 is
; vmp-aarch64-neon-scalar-fmulx-semantic.ll and must not stay
; here as a skip (it would virtualize).  v1f64 stays out.
; Last-token +fullfp16 required for half; f32/f64 need no extra
; token.  +fp16fml does not count.
; Command-line -mattr is never consulted.  Exact C non-vararg.
; Ordinary tail accepted and replayed as non-tail; see vmp-direct-call-tail-eligibility-semantic.ll.
;
; Host cannot select this AArch64 intrinsic; no lli.
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
declare <4 x half> @llvm.aarch64.neon.fmulx.v4f16(<4 x half>, <4 x half>)
declare <8 x half> @llvm.aarch64.neon.fmulx.v8f16(<8 x half>, <8 x half>)
declare <2 x float> @llvm.aarch64.neon.fmulx.v2f32(<2 x float>, <2 x float>)
declare <4 x float> @llvm.aarch64.neon.fmulx.v4f32(<4 x float>, <4 x float>)
declare <2 x double> @llvm.aarch64.neon.fmulx.v2f64(<2 x double>, <2 x double>)
declare <1 x double> @llvm.aarch64.neon.fmulx.v1f64(<1 x double>, <1 x double>)
declare <2 x half> @llvm.aarch64.neon.fmulx.v2f16(<2 x half>, <2 x half>)
declare <4 x bfloat> @llvm.aarch64.neon.fmulx.v4bf16(<4 x bfloat>, <4 x bfloat>)
declare <vscale x 4 x float> @llvm.aarch64.sve.fmulx.nxv4f32(<vscale x 4 x i1>, <vscale x 4 x float>, <vscale x 4 x float>)

@sink_v4f16 = global <4 x half> zeroinitializer, align 8
@sink_v8f16 = global <8 x half> zeroinitializer, align 16
@sink_v2f32 = global <2 x float> zeroinitializer, align 8
@sink_v4f32 = global <4 x float> zeroinitializer, align 16
@sink_v2f64 = global <2 x double> zeroinitializer, align 16

define <4 x half> @protected_fmulx_v4f16(<4 x half> %a, <4 x half> %b) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x half> @llvm.aarch64.neon.fmulx.v4f16(<4 x half> %a, <4 x half> %b)
  ret <4 x half> %r
}

define <8 x half> @protected_fmulx_v8f16(<8 x half> %a, <8 x half> %b) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <8 x half> @llvm.aarch64.neon.fmulx.v8f16(<8 x half> %a, <8 x half> %b)
  ret <8 x half> %r
}

define <2 x float> @protected_fmulx_v2f32(<2 x float> %a, <2 x float> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.aarch64.neon.fmulx.v2f32(<2 x float> %a, <2 x float> %b)
  ret <2 x float> %r
}

define <4 x float> @protected_fmulx_v4f32(<4 x float> %a, <4 x float> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.fmulx.v4f32(<4 x float> %a, <4 x float> %b)
  ret <4 x float> %r
}

define <2 x double> @protected_fmulx_v2f64(<2 x double> %a, <2 x double> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x double> @llvm.aarch64.neon.fmulx.v2f64(<2 x double> %a, <2 x double> %b)
  ret <2 x double> %r
}

define <4 x half> @protected_fmulx_last_fullfp16(<4 x half> %a, <4 x half> %b) noinline optnone "target-features"="+neon,+fp16fml,+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x half> @llvm.aarch64.neon.fmulx.v4f16(<4 x half> %a, <4 x half> %b)
  ret <4 x half> %r
}

; clang vmulx_lane is splat + fmulx, not a lane IR ID.
define <4 x float> @protected_fmulx_splat_lane(<4 x float> %a, <4 x float> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %s = shufflevector <4 x float> %b, <4 x float> %b, <4 x i32> <i32 1, i32 1, i32 1, i32 1>
  %r = call <4 x float> @llvm.aarch64.neon.fmulx.v4f32(<4 x float> %a, <4 x float> %s)
  ret <4 x float> %r
}

; ----- negatives: selected, not virtualized -----

define <4 x half> @unsupported_f16_no_fullfp16(<4 x half> %a, <4 x half> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x half> @llvm.aarch64.neon.fmulx.v4f16(<4 x half> %a, <4 x half> %b)
  ret <4 x half> %r
}

define <4 x half> @unsupported_fullfp16_disabled(<4 x half> %a, <4 x half> %b) noinline optnone "target-features"="+fullfp16,-fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x half> @llvm.aarch64.neon.fmulx.v4f16(<4 x half> %a, <4 x half> %b)
  ret <4 x half> %r
}

define <4 x half> @unsupported_fp16fml_only(<4 x half> %a, <4 x half> %b) noinline optnone "target-features"="+fp16fml" {
entry:
  call void @hikari_vmp()
  %r = call <4 x half> @llvm.aarch64.neon.fmulx.v4f16(<4 x half> %a, <4 x half> %b)
  ret <4 x half> %r
}

; Well-formed scalar llvm.aarch64.neon.fmulx is
; vmp-aarch64-neon-scalar-fmulx-semantic.ll.

define <1 x double> @unsupported_v1f64(<1 x double> %a, <1 x double> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <1 x double> @llvm.aarch64.neon.fmulx.v1f64(<1 x double> %a, <1 x double> %b)
  ret <1 x double> %r
}

define <2 x half> @unsupported_v2f16(<2 x half> %a, <2 x half> %b) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <2 x half> @llvm.aarch64.neon.fmulx.v2f16(<2 x half> %a, <2 x half> %b)
  ret <2 x half> %r
}

define <4 x bfloat> @unsupported_bfloat(<4 x bfloat> %a, <4 x bfloat> %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x bfloat> @llvm.aarch64.neon.fmulx.v4bf16(<4 x bfloat> %a, <4 x bfloat> %b)
  ret <4 x bfloat> %r
}

define <vscale x 4 x float> @unsupported_sve_fmulx(<vscale x 4 x i1> %pg, <vscale x 4 x float> %a, <vscale x 4 x float> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x float> @llvm.aarch64.sve.fmulx.nxv4f32(<vscale x 4 x i1> %pg, <vscale x 4 x float> %a, <vscale x 4 x float> %b)
  ret <vscale x 4 x float> %r
}

define <4 x float> @unsupported_fastcc(<4 x float> %a, <4 x float> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc <4 x float> @llvm.aarch64.neon.fmulx.v4f32(<4 x float> %a, <4 x float> %b)
  ret <4 x float> %r
}


define <4 x float> @unsupported_musttail(<4 x float> %a, <4 x float> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call <4 x float> @llvm.aarch64.neon.fmulx.v4f32(<4 x float> %a, <4 x float> %b)
  ret <4 x float> %r
}

define <4 x float> @unsupported_bundle(<4 x float> %a, <4 x float> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.fmulx.v4f32(<4 x float> %a, <4 x float> %b) [ "deopt"(i32 0) ]
  ret <4 x float> %r
}

define <4 x float> @unsupported_noreturn(<4 x float> %a, <4 x float> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.fmulx.v4f32(<4 x float> %a, <4 x float> %b) noreturn
  ret <4 x float> %r
}

define <4 x float> @unsupported_returns_twice(<4 x float> %a, <4 x float> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.fmulx.v4f32(<4 x float> %a, <4 x float> %b) returns_twice
  ret <4 x float> %r
}

define i32 @main() {
entry:
  %h4a = load volatile <4 x half>, ptr @sink_v4f16, align 8
  %h4b = load volatile <4 x half>, ptr @sink_v4f16, align 8
  %r0 = call <4 x half> @protected_fmulx_v4f16(<4 x half> %h4a, <4 x half> %h4b)
  store volatile <4 x half> %r0, ptr @sink_v4f16, align 8
  %h8a = load volatile <8 x half>, ptr @sink_v8f16, align 16
  %h8b = load volatile <8 x half>, ptr @sink_v8f16, align 16
  %r1 = call <8 x half> @protected_fmulx_v8f16(<8 x half> %h8a, <8 x half> %h8b)
  store volatile <8 x half> %r1, ptr @sink_v8f16, align 16
  %s2a = load volatile <2 x float>, ptr @sink_v2f32, align 8
  %s2b = load volatile <2 x float>, ptr @sink_v2f32, align 8
  %r2 = call <2 x float> @protected_fmulx_v2f32(<2 x float> %s2a, <2 x float> %s2b)
  store volatile <2 x float> %r2, ptr @sink_v2f32, align 8
  %s4a = load volatile <4 x float>, ptr @sink_v4f32, align 16
  %s4b = load volatile <4 x float>, ptr @sink_v4f32, align 16
  %r3 = call <4 x float> @protected_fmulx_v4f32(<4 x float> %s4a, <4 x float> %s4b)
  store volatile <4 x float> %r3, ptr @sink_v4f32, align 16
  %d2a = load volatile <2 x double>, ptr @sink_v2f64, align 16
  %d2b = load volatile <2 x double>, ptr @sink_v2f64, align 16
  %r4 = call <2 x double> @protected_fmulx_v2f64(<2 x double> %d2a, <2 x double> %d2b)
  store volatile <2 x double> %r4, ptr @sink_v2f64, align 16
  %r5 = call <4 x half> @protected_fmulx_last_fullfp16(<4 x half> %h4a, <4 x half> %h4b)
  store volatile <4 x half> %r5, ptr @sink_v4f16, align 8
  %r6 = call <4 x float> @protected_fmulx_splat_lane(<4 x float> %s4a, <4 x float> %s4b)
  store volatile <4 x float> %r6, ptr @sink_v4f32, align 16
  ret i32 0
}

; SKIP-DAG: Skipping VMP on unsupported_f16_no_fullfp16: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_fullfp16_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_fp16fml_only: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_v1f64: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_v2f16: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_bfloat: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_sve_fmulx: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_noreturn: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_returns_twice: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_fmulx_v4f16:
; SKIP-NOT: Skipping VMP on protected_fmulx_v8f16:
; SKIP-NOT: Skipping VMP on protected_fmulx_v2f32:
; SKIP-NOT: Skipping VMP on protected_fmulx_v4f32:
; SKIP-NOT: Skipping VMP on protected_fmulx_v2f64:
; SKIP-NOT: Skipping VMP on protected_fmulx_last_fullfp16:
; SKIP-NOT: Skipping VMP on protected_fmulx_splat_lane:

; VIRT: define <4 x half> @protected_fmulx_v4f16({{.*}} #[[PROTH:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x half> @llvm.aarch64.neon.fmulx.v4f16(
; VIRT: define <8 x half> @protected_fmulx_v8f16({{.*}} #[[PROTH]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x half> @llvm.aarch64.neon.fmulx.v8f16(
; VIRT: define <2 x float> @protected_fmulx_v2f32({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x float> @llvm.aarch64.neon.fmulx.v2f32(
; VIRT: define <4 x float> @protected_fmulx_v4f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x float> @llvm.aarch64.neon.fmulx.v4f32(
; VIRT: define <2 x double> @protected_fmulx_v2f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x double> @llvm.aarch64.neon.fmulx.v2f64(
; VIRT: define <4 x half> @protected_fmulx_last_fullfp16({{.*}} #[[LAST:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x half> @llvm.aarch64.neon.fmulx.v4f16(
; VIRT: define <4 x float> @protected_fmulx_splat_lane({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x float> @llvm.aarch64.neon.fmulx.v4f32(
; VIRT: define {{.*}} @unsupported_f16_no_fullfp16({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROTH]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT: attributes #[[LAST]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; AARCH64-ASM-DAG: {{^[[:space:]]*}}fmulx{{[ \t]}}{{v[0-9]+}}.4h
; AARCH64-ASM-DAG: {{^[[:space:]]*}}fmulx{{[ \t]}}{{v[0-9]+}}.8h
; AARCH64-ASM-DAG: {{^[[:space:]]*}}fmulx{{[ \t]}}{{v[0-9]+}}.2s
; AARCH64-ASM-DAG: {{^[[:space:]]*}}fmulx{{[ \t]}}{{v[0-9]+}}.4s
; AARCH64-ASM-DAG: {{^[[:space:]]*}}fmulx{{[ \t]}}{{v[0-9]+}}.2d
; HOST: Skipping VMP: only AArch64 targets are supported
