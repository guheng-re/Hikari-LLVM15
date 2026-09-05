; Restricted AArch64 NEON absolute floating compare via
; CallDescriptor (float vector VRegs in, integer-mask vector out):
;   llvm.aarch64.neon.facge / facgt
;     AdvSIMD_2Arg_FloatCompare: anyint (anyfloat, match)
;     ISel SIMDThreeSameVectorFPCmp, baseline HasNEON:
;       <2 x i32>(<2 x float>) / <4 x i32>(<4 x float>) /
;       <2 x i64>(<2 x double>)
;     plus HasFullFP16:
;       <4 x i16>(<4 x half>) / <8 x i16>(<8 x half>)
; Clang vcage/vcagt; vcale/vcalt swap operands.  Must not lower
; to fabs+fcmp or generic fcmp: FACGE/FACGT raise Invalid on
; sNaN; ARM FABS does not, so the composite loses the exception.
; |+0|==|-0|.  qNaN is unordered-false (zero mask).  Result is
; an all-ones / zero integer lane, not i1.  Well-formed scalar
; facge/facgt is
; vmp-aarch64-neon-scalar-facge-facgt-semantic.ll and must not
; stay here as a skip (it would virtualize).  Last-token
; +fullfp16 required for half; f32/f64 need
; no extra token.  +fp16fml does not count.  FastMathFlags
; cannot attach (integer-mask result).  Command-line -mattr
; never consulted for eligibility.  Exact C non-vararg.
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
declare <2 x i32> @llvm.aarch64.neon.facge.v2i32.v2f32(<2 x float>, <2 x float>)
declare <4 x i32> @llvm.aarch64.neon.facge.v4i32.v4f32(<4 x float>, <4 x float>)
declare <2 x i64> @llvm.aarch64.neon.facge.v2i64.v2f64(<2 x double>, <2 x double>)
declare <4 x i16> @llvm.aarch64.neon.facge.v4i16.v4f16(<4 x half>, <4 x half>)
declare <8 x i16> @llvm.aarch64.neon.facge.v8i16.v8f16(<8 x half>, <8 x half>)
declare <2 x i32> @llvm.aarch64.neon.facgt.v2i32.v2f32(<2 x float>, <2 x float>)
declare <4 x i32> @llvm.aarch64.neon.facgt.v4i32.v4f32(<4 x float>, <4 x float>)
declare <2 x i64> @llvm.aarch64.neon.facgt.v2i64.v2f64(<2 x double>, <2 x double>)
declare <4 x i16> @llvm.aarch64.neon.facgt.v4i16.v4f16(<4 x half>, <4 x half>)
declare <1 x i64> @llvm.aarch64.neon.facge.v1i64.v1f64(<1 x double>, <1 x double>)
declare <2 x i16> @llvm.aarch64.neon.facge.v2i16.v2f16(<2 x half>, <2 x half>)
declare <4 x i16> @llvm.aarch64.neon.facge.v4i16.v4bf16(<4 x bfloat>, <4 x bfloat>)
declare <4 x i16> @llvm.aarch64.neon.facge.v4i16.v4f32(<4 x float>, <4 x float>)
declare <vscale x 4 x i1> @llvm.aarch64.sve.facge.nxv4f32(<vscale x 4 x i1>, <vscale x 4 x float>, <vscale x 4 x float>)

@sink_v2f32 = global <2 x float> zeroinitializer, align 8
@sink_v4f32 = global <4 x float> zeroinitializer, align 16
@sink_v2f64 = global <2 x double> zeroinitializer, align 16
@sink_v4f16 = global <4 x half> zeroinitializer, align 8
@sink_v8f16 = global <8 x half> zeroinitializer, align 16
@sink_v2i32 = global <2 x i32> zeroinitializer, align 8
@sink_v4i32 = global <4 x i32> zeroinitializer, align 16
@sink_v2i64 = global <2 x i64> zeroinitializer, align 16
@sink_v4i16 = global <4 x i16> zeroinitializer, align 8
@sink_v8i16 = global <8 x i16> zeroinitializer, align 16

define <2 x i32> @protected_facge_v2f32(<2 x float> %a, <2 x float> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i32> @llvm.aarch64.neon.facge.v2i32.v2f32(<2 x float> %a, <2 x float> %b)
  ret <2 x i32> %r
}

define <4 x i32> @protected_facge_v4f32(<4 x float> %a, <4 x float> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.facge.v4i32.v4f32(<4 x float> %a, <4 x float> %b)
  ret <4 x i32> %r
}

define <2 x i64> @protected_facge_v2f64(<2 x double> %a, <2 x double> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.aarch64.neon.facge.v2i64.v2f64(<2 x double> %a, <2 x double> %b)
  ret <2 x i64> %r
}

define <4 x i16> @protected_facge_v4f16(<4 x half> %a, <4 x half> %b) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i16> @llvm.aarch64.neon.facge.v4i16.v4f16(<4 x half> %a, <4 x half> %b)
  ret <4 x i16> %r
}

define <8 x i16> @protected_facge_v8f16(<8 x half> %a, <8 x half> %b) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <8 x i16> @llvm.aarch64.neon.facge.v8i16.v8f16(<8 x half> %a, <8 x half> %b)
  ret <8 x i16> %r
}

define <4 x i32> @protected_facgt_v4f32(<4 x float> %a, <4 x float> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.facgt.v4i32.v4f32(<4 x float> %a, <4 x float> %b)
  ret <4 x i32> %r
}

define <2 x i64> @protected_facgt_v2f64(<2 x double> %a, <2 x double> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.aarch64.neon.facgt.v2i64.v2f64(<2 x double> %a, <2 x double> %b)
  ret <2 x i64> %r
}

define <4 x i16> @protected_facgt_last_fullfp16(<4 x half> %a, <4 x half> %b) noinline optnone "target-features"="+neon,+fp16fml,+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i16> @llvm.aarch64.neon.facgt.v4i16.v4f16(<4 x half> %a, <4 x half> %b)
  ret <4 x i16> %r
}

; Well-formed scalar llvm.aarch64.neon.facge/facgt is
; vmp-aarch64-neon-scalar-facge-facgt-semantic.ll.

define <1 x i64> @unsupported_v1f64(<1 x double> %a, <1 x double> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <1 x i64> @llvm.aarch64.neon.facge.v1i64.v1f64(<1 x double> %a, <1 x double> %b)
  ret <1 x i64> %r
}

define <2 x i16> @unsupported_v2f16(<2 x half> %a, <2 x half> %b) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <2 x i16> @llvm.aarch64.neon.facge.v2i16.v2f16(<2 x half> %a, <2 x half> %b)
  ret <2 x i16> %r
}

define <4 x i16> @unsupported_bfloat(<4 x bfloat> %a, <4 x bfloat> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i16> @llvm.aarch64.neon.facge.v4i16.v4bf16(<4 x bfloat> %a, <4 x bfloat> %b)
  ret <4 x i16> %r
}

define <4 x i16> @unsupported_mismatch(<4 x float> %a, <4 x float> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i16> @llvm.aarch64.neon.facge.v4i16.v4f32(<4 x float> %a, <4 x float> %b)
  ret <4 x i16> %r
}

define <4 x i16> @unsupported_f16_no_fullfp16(<4 x half> %a, <4 x half> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i16> @llvm.aarch64.neon.facge.v4i16.v4f16(<4 x half> %a, <4 x half> %b)
  ret <4 x i16> %r
}

define <4 x i16> @unsupported_fullfp16_disabled(<4 x half> %a, <4 x half> %b) noinline optnone "target-features"="+fullfp16,-fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i16> @llvm.aarch64.neon.facge.v4i16.v4f16(<4 x half> %a, <4 x half> %b)
  ret <4 x i16> %r
}

define <4 x i16> @unsupported_fp16fml_only(<4 x half> %a, <4 x half> %b) noinline optnone "target-features"="+fp16fml" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i16> @llvm.aarch64.neon.facge.v4i16.v4f16(<4 x half> %a, <4 x half> %b)
  ret <4 x i16> %r
}

define <vscale x 4 x i1> @unsupported_sve_facge(<vscale x 4 x i1> %pg, <vscale x 4 x float> %a, <vscale x 4 x float> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i1> @llvm.aarch64.sve.facge.nxv4f32(<vscale x 4 x i1> %pg, <vscale x 4 x float> %a, <vscale x 4 x float> %b)
  ret <vscale x 4 x i1> %r
}

define <4 x i32> @unsupported_fastcc(<4 x float> %a, <4 x float> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc <4 x i32> @llvm.aarch64.neon.facge.v4i32.v4f32(<4 x float> %a, <4 x float> %b)
  ret <4 x i32> %r
}


define <4 x i32> @unsupported_musttail(<4 x float> %a, <4 x float> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call <4 x i32> @llvm.aarch64.neon.facge.v4i32.v4f32(<4 x float> %a, <4 x float> %b)
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_bundle(<4 x float> %a, <4 x float> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.facge.v4i32.v4f32(<4 x float> %a, <4 x float> %b) [ "deopt"(i32 0) ]
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_noreturn(<4 x float> %a, <4 x float> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.facge.v4i32.v4f32(<4 x float> %a, <4 x float> %b) noreturn
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_returns_twice(<4 x float> %a, <4 x float> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.facge.v4i32.v4f32(<4 x float> %a, <4 x float> %b) returns_twice
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
  %a2 = load volatile <2 x float>, ptr @sink_v2f32, align 8
  %b2 = load volatile <2 x float>, ptr @sink_v2f32, align 8
  %r0 = call <2 x i32> @protected_facge_v2f32(<2 x float> %a2, <2 x float> %b2)
  store volatile <2 x i32> %r0, ptr @sink_v2i32, align 8
  %a4 = load volatile <4 x float>, ptr @sink_v4f32, align 16
  %b4 = load volatile <4 x float>, ptr @sink_v4f32, align 16
  %r1 = call <4 x i32> @protected_facge_v4f32(<4 x float> %a4, <4 x float> %b4)
  store volatile <4 x i32> %r1, ptr @sink_v4i32, align 16
  %ad = load volatile <2 x double>, ptr @sink_v2f64, align 16
  %bd = load volatile <2 x double>, ptr @sink_v2f64, align 16
  %r2 = call <2 x i64> @protected_facge_v2f64(<2 x double> %ad, <2 x double> %bd)
  store volatile <2 x i64> %r2, ptr @sink_v2i64, align 16
  %h4a = load volatile <4 x half>, ptr @sink_v4f16, align 8
  %h4b = load volatile <4 x half>, ptr @sink_v4f16, align 8
  %r3 = call <4 x i16> @protected_facge_v4f16(<4 x half> %h4a, <4 x half> %h4b)
  store volatile <4 x i16> %r3, ptr @sink_v4i16, align 8
  %h8a = load volatile <8 x half>, ptr @sink_v8f16, align 16
  %h8b = load volatile <8 x half>, ptr @sink_v8f16, align 16
  %r4 = call <8 x i16> @protected_facge_v8f16(<8 x half> %h8a, <8 x half> %h8b)
  store volatile <8 x i16> %r4, ptr @sink_v8i16, align 16
  %r5 = call <4 x i32> @protected_facgt_v4f32(<4 x float> %a4, <4 x float> %b4)
  store volatile <4 x i32> %r5, ptr @sink_v4i32, align 16
  %r6 = call <2 x i64> @protected_facgt_v2f64(<2 x double> %ad, <2 x double> %bd)
  store volatile <2 x i64> %r6, ptr @sink_v2i64, align 16
  %r7 = call <4 x i16> @protected_facgt_last_fullfp16(<4 x half> %h4a, <4 x half> %h4b)
  store volatile <4 x i16> %r7, ptr @sink_v4i16, align 8
  ret i32 0
}

; SKIP-DAG: Skipping VMP on unsupported_v1f64: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_v2f16: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_bfloat: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_mismatch: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_f16_no_fullfp16: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_fullfp16_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_fp16fml_only: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_sve_facge: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_noreturn: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_returns_twice: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_sret: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_facge_v2f32:
; SKIP-NOT: Skipping VMP on protected_facge_v4f32:
; SKIP-NOT: Skipping VMP on protected_facge_v2f64:
; SKIP-NOT: Skipping VMP on protected_facge_v4f16:
; SKIP-NOT: Skipping VMP on protected_facge_v8f16:
; SKIP-NOT: Skipping VMP on protected_facgt_v4f32:
; SKIP-NOT: Skipping VMP on protected_facgt_v2f64:
; SKIP-NOT: Skipping VMP on protected_facgt_last_fullfp16:

; VIRT: define <2 x i32> @protected_facge_v2f32({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i32> @llvm.aarch64.neon.facge.v2i32.v2f32(
; VIRT: define <4 x i32> @protected_facge_v4f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.aarch64.neon.facge.v4i32.v4f32(
; VIRT: define <2 x i64> @protected_facge_v2f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <4 x i16> @protected_facge_v4f16({{.*}} #[[PROTH:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i16> @llvm.aarch64.neon.facge.v4i16.v4f16(
; VIRT: define <8 x i16> @protected_facge_v8f16({{.*}} #[[PROTH]] {
; VIRT: vmp.dispatch:
; VIRT: define <4 x i32> @protected_facgt_v4f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.aarch64.neon.facgt.v4i32.v4f32(
; VIRT: define <2 x i64> @protected_facgt_v2f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <4 x i16> @protected_facgt_last_fullfp16({{.*}} #[[PROTL:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i16> @llvm.aarch64.neon.facgt.v4i16.v4f16(
; VIRT: define {{.*}} @unsupported_v1f64({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; AARCH64-ASM-DAG: {{^[[:space:]]*}}facge{{[ \t]}}
; AARCH64-ASM-DAG: {{^[[:space:]]*}}facgt{{[ \t]}}
; HOST: Skipping VMP: only AArch64 targets are supported
