; Restricted AArch64 NEON complex fused multiply-add via
; CallDescriptor / existing vector VRegs (no new opcode):
;   llvm.aarch64.neon.vcmla.rot0 / rot90 / rot180 / rot270
;     AdvSIMD_3VectorArg: three same-type vectors
;     Rotation is the IR ID, not an ImmArg.
;     ISel FCMLA under HasComplxNum+HasNEON (token "complxnum"):
;       <2 x float> / <4 x float> / <2 x double>
;     plus HasFullFP16 for <4 x half> / <8 x half>
;     asm fcmla Vd.T, Vn.T, Vm.T, #0/#90/#180/#270
; No neon.vcmla.lane IR ID.  clang vcmla_*_lane is splat + the same
; ID.  ISel indexed forms exist only for v4f16 / v8f16 / v4f32.
; Last-token function +complxnum required; half also needs last-token
; +fullfp16.  +fp16fml / +v8.3a / +i8mm / +dotprod do not count.
; Command-line -mattr is never consulted.  Exact C non-vararg.
; Ordinary tail accepted and replayed as non-tail; see vmp-direct-call-tail-eligibility-semantic.ll.  Well-formed vcadd
; is vmp-aarch64-neon-vcadd-semantic.ll.  bf16 / SVE stay out.
;
; Host cannot select these AArch64 intrinsics; no lli.
; FileCheck + AArch64 llc/readobj/asm (-mattr=+complxnum,+fullfp16).
; O0/O2 x 97/7.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.ll -o %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+complxnum,+fullfp16 -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+complxnum,+fullfp16 %t.o0.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.ll -o %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+complxnum,+fullfp16 -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+complxnum,+fullfp16 %t.o2.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.s7.ll -o %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+complxnum,+fullfp16 -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+complxnum,+fullfp16 %t.o0.s7.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.s7.ll -o %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+complxnum,+fullfp16 -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+complxnum,+fullfp16 %t.o2.s7.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %s | opt -S -verify-each -aesSeed=97 -passes='default<O0>' - 2>&1 | FileCheck %s --check-prefix=HOST

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare <4 x half> @llvm.aarch64.neon.vcmla.rot0.v4f16(<4 x half>, <4 x half>, <4 x half>)
declare <8 x half> @llvm.aarch64.neon.vcmla.rot0.v8f16(<8 x half>, <8 x half>, <8 x half>)
declare <2 x float> @llvm.aarch64.neon.vcmla.rot0.v2f32(<2 x float>, <2 x float>, <2 x float>)
declare <4 x float> @llvm.aarch64.neon.vcmla.rot0.v4f32(<4 x float>, <4 x float>, <4 x float>)
declare <4 x float> @llvm.aarch64.neon.vcmla.rot90.v4f32(<4 x float>, <4 x float>, <4 x float>)
declare <4 x float> @llvm.aarch64.neon.vcmla.rot180.v4f32(<4 x float>, <4 x float>, <4 x float>)
declare <4 x float> @llvm.aarch64.neon.vcmla.rot270.v4f32(<4 x float>, <4 x float>, <4 x float>)
declare <2 x double> @llvm.aarch64.neon.vcmla.rot0.v2f64(<2 x double>, <2 x double>, <2 x double>)
declare <1 x double> @llvm.aarch64.neon.vcmla.rot0.v1f64(<1 x double>, <1 x double>, <1 x double>)
declare <8 x bfloat> @llvm.aarch64.neon.vcmla.rot0.v8bf16(<8 x bfloat>, <8 x bfloat>, <8 x bfloat>)
declare <4 x i32> @llvm.aarch64.neon.smmla.v4i32.v16i8(<4 x i32>, <16 x i8>, <16 x i8>)
declare <4 x i32> @llvm.aarch64.neon.sdot.v4i32.v16i8(<4 x i32>, <16 x i8>, <16 x i8>)

declare <vscale x 4 x float> @llvm.aarch64.sve.fcmla.nxv4f32(<vscale x 4 x i1>, <vscale x 4 x float>, <vscale x 4 x float>, <vscale x 4 x float>, i32)

@sink_v4f16 = global <4 x half> zeroinitializer, align 8
@sink_v8f16 = global <8 x half> zeroinitializer, align 16
@sink_v2f32 = global <2 x float> zeroinitializer, align 8
@sink_v4f32 = global <4 x float> zeroinitializer, align 16
@sink_v2f64 = global <2 x double> zeroinitializer, align 16

define <4 x half> @protected_vcmla_v4f16(<4 x half> %a, <4 x half> %b, <4 x half> %c) noinline optnone "target-features"="+complxnum,+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x half> @llvm.aarch64.neon.vcmla.rot0.v4f16(<4 x half> %a, <4 x half> %b, <4 x half> %c)
  ret <4 x half> %r
}

define <8 x half> @protected_vcmla_v8f16(<8 x half> %a, <8 x half> %b, <8 x half> %c) noinline optnone "target-features"="+complxnum,+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <8 x half> @llvm.aarch64.neon.vcmla.rot0.v8f16(<8 x half> %a, <8 x half> %b, <8 x half> %c)
  ret <8 x half> %r
}

define <2 x float> @protected_vcmla_v2f32(<2 x float> %a, <2 x float> %b, <2 x float> %c) noinline optnone "target-features"="+complxnum" {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.aarch64.neon.vcmla.rot0.v2f32(<2 x float> %a, <2 x float> %b, <2 x float> %c)
  ret <2 x float> %r
}

define <4 x float> @protected_vcmla_rot0_v4f32(<4 x float> %a, <4 x float> %b, <4 x float> %c) noinline optnone "target-features"="+complxnum" {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.vcmla.rot0.v4f32(<4 x float> %a, <4 x float> %b, <4 x float> %c)
  ret <4 x float> %r
}

define <4 x float> @protected_vcmla_rot90_v4f32(<4 x float> %a, <4 x float> %b, <4 x float> %c) noinline optnone "target-features"="+complxnum" {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.vcmla.rot90.v4f32(<4 x float> %a, <4 x float> %b, <4 x float> %c)
  ret <4 x float> %r
}

define <4 x float> @protected_vcmla_rot180_v4f32(<4 x float> %a, <4 x float> %b, <4 x float> %c) noinline optnone "target-features"="+complxnum" {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.vcmla.rot180.v4f32(<4 x float> %a, <4 x float> %b, <4 x float> %c)
  ret <4 x float> %r
}

define <4 x float> @protected_vcmla_rot270_v4f32(<4 x float> %a, <4 x float> %b, <4 x float> %c) noinline optnone "target-features"="+complxnum" {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.vcmla.rot270.v4f32(<4 x float> %a, <4 x float> %b, <4 x float> %c)
  ret <4 x float> %r
}

define <2 x double> @protected_vcmla_v2f64(<2 x double> %a, <2 x double> %b, <2 x double> %c) noinline optnone "target-features"="+complxnum" {
entry:
  call void @hikari_vmp()
  %r = call <2 x double> @llvm.aarch64.neon.vcmla.rot0.v2f64(<2 x double> %a, <2 x double> %b, <2 x double> %c)
  ret <2 x double> %r
}

; clang vcmla_lane is splat + the same ID.  No neon.vcmla.lane IR ID.
define <4 x float> @protected_vcmla_splat(<4 x float> %a, <4 x float> %b, <4 x float> %c) noinline optnone "target-features"="+complxnum" {
entry:
  call void @hikari_vmp()
  %splat = shufflevector <4 x float> %c, <4 x float> undef, <4 x i32> <i32 0, i32 1, i32 0, i32 1>
  %r = call <4 x float> @llvm.aarch64.neon.vcmla.rot0.v4f32(<4 x float> %a, <4 x float> %b, <4 x float> %splat)
  ret <4 x float> %r
}

define <4 x float> @protected_vcmla_last_complxnum(<4 x float> %a, <4 x float> %b, <4 x float> %c) noinline optnone "target-features"="+neon,+crc,+complxnum" {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.vcmla.rot0.v4f32(<4 x float> %a, <4 x float> %b, <4 x float> %c)
  ret <4 x float> %r
}

define <4 x float> @unsupported_no_complxnum(<4 x float> %a, <4 x float> %b, <4 x float> %c) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.vcmla.rot0.v4f32(<4 x float> %a, <4 x float> %b, <4 x float> %c)
  ret <4 x float> %r
}

define <4 x float> @unsupported_complxnum_disabled(<4 x float> %a, <4 x float> %b, <4 x float> %c) noinline optnone "target-features"="+complxnum,-complxnum" {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.vcmla.rot0.v4f32(<4 x float> %a, <4 x float> %b, <4 x float> %c)
  ret <4 x float> %r
}

define <4 x float> @unsupported_fullfp16_only(<4 x float> %a, <4 x float> %b, <4 x float> %c) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.vcmla.rot0.v4f32(<4 x float> %a, <4 x float> %b, <4 x float> %c)
  ret <4 x float> %r
}

define <8 x half> @unsupported_f16_no_fullfp16(<8 x half> %a, <8 x half> %b, <8 x half> %c) noinline optnone "target-features"="+complxnum" {
entry:
  call void @hikari_vmp()
  %r = call <8 x half> @llvm.aarch64.neon.vcmla.rot0.v8f16(<8 x half> %a, <8 x half> %b, <8 x half> %c)
  ret <8 x half> %r
}

define <4 x float> @unsupported_fp16fml_only(<4 x float> %a, <4 x float> %b, <4 x float> %c) noinline optnone "target-features"="+fp16fml" {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.vcmla.rot0.v4f32(<4 x float> %a, <4 x float> %b, <4 x float> %c)
  ret <4 x float> %r
}

define <4 x float> @unsupported_i8mm_only(<4 x float> %a, <4 x float> %b, <4 x float> %c) noinline optnone "target-features"="+i8mm" {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.vcmla.rot0.v4f32(<4 x float> %a, <4 x float> %b, <4 x float> %c)
  ret <4 x float> %r
}

define <4 x float> @unsupported_dotprod_only(<4 x float> %a, <4 x float> %b, <4 x float> %c) noinline optnone "target-features"="+dotprod" {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.vcmla.rot0.v4f32(<4 x float> %a, <4 x float> %b, <4 x float> %c)
  ret <4 x float> %r
}

; Well-formed llvm.aarch64.neon.vcadd.rot90 / rot270 with last-token
; +complxnum is vmp-aarch64-neon-vcadd-semantic.ll and must not stay
; here (it would virtualize).

define <4 x i32> @unsupported_smmla(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b) noinline optnone "target-features"="+complxnum" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.smmla.v4i32.v16i8(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b)
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_sdot(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b) noinline optnone "target-features"="+complxnum" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.sdot.v4i32.v16i8(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b)
  ret <4 x i32> %r
}

; Well-formed llvm.aarch64.neon.usdot is
; vmp-aarch64-neon-usdot-semantic.ll.

define <8 x bfloat> @unsupported_bfloat(<8 x bfloat> %a, <8 x bfloat> %b, <8 x bfloat> %c) noinline optnone "target-features"="+complxnum,+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <8 x bfloat> @llvm.aarch64.neon.vcmla.rot0.v8bf16(<8 x bfloat> %a, <8 x bfloat> %b, <8 x bfloat> %c)
  ret <8 x bfloat> %r
}

define <1 x double> @unsupported_v1f64(<1 x double> %a, <1 x double> %b, <1 x double> %c) noinline optnone "target-features"="+complxnum" {
entry:
  call void @hikari_vmp()
  %r = call <1 x double> @llvm.aarch64.neon.vcmla.rot0.v1f64(<1 x double> %a, <1 x double> %b, <1 x double> %c)
  ret <1 x double> %r
}

define <vscale x 4 x float> @unsupported_sve_fcmla(<vscale x 4 x i1> %pg, <vscale x 4 x float> %a, <vscale x 4 x float> %b, <vscale x 4 x float> %c) noinline optnone "target-features"="+complxnum" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x float> @llvm.aarch64.sve.fcmla.nxv4f32(<vscale x 4 x i1> %pg, <vscale x 4 x float> %a, <vscale x 4 x float> %b, <vscale x 4 x float> %c, i32 90)
  ret <vscale x 4 x float> %r
}

define <4 x float> @unsupported_fastcc(<4 x float> %a, <4 x float> %b, <4 x float> %c) noinline optnone "target-features"="+complxnum" {
entry:
  call void @hikari_vmp()
  %r = call fastcc <4 x float> @llvm.aarch64.neon.vcmla.rot0.v4f32(<4 x float> %a, <4 x float> %b, <4 x float> %c)
  ret <4 x float> %r
}


define <4 x float> @unsupported_musttail(<4 x float> %a, <4 x float> %b, <4 x float> %c) noinline optnone "target-features"="+complxnum" {
entry:
  call void @hikari_vmp()
  %r = musttail call <4 x float> @llvm.aarch64.neon.vcmla.rot0.v4f32(<4 x float> %a, <4 x float> %b, <4 x float> %c)
  ret <4 x float> %r
}

define <4 x float> @unsupported_bundle(<4 x float> %a, <4 x float> %b, <4 x float> %c) noinline optnone "target-features"="+complxnum" {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.vcmla.rot0.v4f32(<4 x float> %a, <4 x float> %b, <4 x float> %c) [ "deopt"(i32 0) ]
  ret <4 x float> %r
}

define <4 x float> @unsupported_noreturn(<4 x float> %a, <4 x float> %b, <4 x float> %c) noinline optnone "target-features"="+complxnum" {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.vcmla.rot0.v4f32(<4 x float> %a, <4 x float> %b, <4 x float> %c) noreturn
  ret <4 x float> %r
}

define <4 x float> @unsupported_returns_twice(<4 x float> %a, <4 x float> %b, <4 x float> %c) noinline optnone "target-features"="+complxnum" {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.vcmla.rot0.v4f32(<4 x float> %a, <4 x float> %b, <4 x float> %c) returns_twice
  ret <4 x float> %r
}

define i32 @main() {
entry:
  %h4a = load volatile <4 x half>, ptr @sink_v4f16, align 8
  %h4b = load volatile <4 x half>, ptr @sink_v4f16, align 8
  %h4c = load volatile <4 x half>, ptr @sink_v4f16, align 8
  %r0 = call <4 x half> @protected_vcmla_v4f16(<4 x half> %h4a, <4 x half> %h4b, <4 x half> %h4c)
  store volatile <4 x half> %r0, ptr @sink_v4f16, align 8
  %h8a = load volatile <8 x half>, ptr @sink_v8f16, align 16
  %h8b = load volatile <8 x half>, ptr @sink_v8f16, align 16
  %h8c = load volatile <8 x half>, ptr @sink_v8f16, align 16
  %r1 = call <8 x half> @protected_vcmla_v8f16(<8 x half> %h8a, <8 x half> %h8b, <8 x half> %h8c)
  store volatile <8 x half> %r1, ptr @sink_v8f16, align 16
  %s2a = load volatile <2 x float>, ptr @sink_v2f32, align 8
  %s2b = load volatile <2 x float>, ptr @sink_v2f32, align 8
  %s2c = load volatile <2 x float>, ptr @sink_v2f32, align 8
  %r2 = call <2 x float> @protected_vcmla_v2f32(<2 x float> %s2a, <2 x float> %s2b, <2 x float> %s2c)
  store volatile <2 x float> %r2, ptr @sink_v2f32, align 8
  %s4a = load volatile <4 x float>, ptr @sink_v4f32, align 16
  %s4b = load volatile <4 x float>, ptr @sink_v4f32, align 16
  %s4c = load volatile <4 x float>, ptr @sink_v4f32, align 16
  %r3 = call <4 x float> @protected_vcmla_rot0_v4f32(<4 x float> %s4a, <4 x float> %s4b, <4 x float> %s4c)
  store volatile <4 x float> %r3, ptr @sink_v4f32, align 16
  %r4 = call <4 x float> @protected_vcmla_rot90_v4f32(<4 x float> %s4a, <4 x float> %s4b, <4 x float> %s4c)
  store volatile <4 x float> %r4, ptr @sink_v4f32, align 16
  %r5 = call <4 x float> @protected_vcmla_rot180_v4f32(<4 x float> %s4a, <4 x float> %s4b, <4 x float> %s4c)
  store volatile <4 x float> %r5, ptr @sink_v4f32, align 16
  %r6 = call <4 x float> @protected_vcmla_rot270_v4f32(<4 x float> %s4a, <4 x float> %s4b, <4 x float> %s4c)
  store volatile <4 x float> %r6, ptr @sink_v4f32, align 16
  %d2a = load volatile <2 x double>, ptr @sink_v2f64, align 16
  %d2b = load volatile <2 x double>, ptr @sink_v2f64, align 16
  %d2c = load volatile <2 x double>, ptr @sink_v2f64, align 16
  %r7 = call <2 x double> @protected_vcmla_v2f64(<2 x double> %d2a, <2 x double> %d2b, <2 x double> %d2c)
  store volatile <2 x double> %r7, ptr @sink_v2f64, align 16
  %r8 = call <4 x float> @protected_vcmla_splat(<4 x float> %s4a, <4 x float> %s4b, <4 x float> %s4c)
  store volatile <4 x float> %r8, ptr @sink_v4f32, align 16
  %r9 = call <4 x float> @protected_vcmla_last_complxnum(<4 x float> %s4a, <4 x float> %s4b, <4 x float> %s4c)
  store volatile <4 x float> %r9, ptr @sink_v4f32, align 16
  ret i32 0
}

; SKIP-DAG: Skipping VMP on unsupported_no_complxnum: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_complxnum_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_fullfp16_only: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_f16_no_fullfp16: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_fp16fml_only: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_i8mm_only: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_dotprod_only: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_smmla: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_sdot: unsupported target feature

; SKIP-DAG: Skipping VMP on unsupported_bfloat: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_v1f64: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_sve_fcmla: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_noreturn: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_returns_twice: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_vcmla_v4f16:
; SKIP-NOT: Skipping VMP on protected_vcmla_v8f16:
; SKIP-NOT: Skipping VMP on protected_vcmla_v2f32:
; SKIP-NOT: Skipping VMP on protected_vcmla_rot0_v4f32:
; SKIP-NOT: Skipping VMP on protected_vcmla_rot90_v4f32:
; SKIP-NOT: Skipping VMP on protected_vcmla_rot180_v4f32:
; SKIP-NOT: Skipping VMP on protected_vcmla_rot270_v4f32:
; SKIP-NOT: Skipping VMP on protected_vcmla_v2f64:
; SKIP-NOT: Skipping VMP on protected_vcmla_splat:
; SKIP-NOT: Skipping VMP on protected_vcmla_last_complxnum:

; VIRT: define <4 x half> @protected_vcmla_v4f16({{.*}} #[[PROTH:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x half> @llvm.aarch64.neon.vcmla.rot0.v4f16(
; VIRT: define <8 x half> @protected_vcmla_v8f16({{.*}} #[[PROTH]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x half> @llvm.aarch64.neon.vcmla.rot0.v8f16(
; VIRT: define <2 x float> @protected_vcmla_v2f32({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x float> @llvm.aarch64.neon.vcmla.rot0.v2f32(
; VIRT: define <4 x float> @protected_vcmla_rot0_v4f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x float> @llvm.aarch64.neon.vcmla.rot0.v4f32(
; VIRT: define <4 x float> @protected_vcmla_rot90_v4f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x float> @llvm.aarch64.neon.vcmla.rot90.v4f32(
; VIRT: define <4 x float> @protected_vcmla_rot180_v4f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x float> @llvm.aarch64.neon.vcmla.rot180.v4f32(
; VIRT: define <4 x float> @protected_vcmla_rot270_v4f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x float> @llvm.aarch64.neon.vcmla.rot270.v4f32(
; VIRT: define <2 x double> @protected_vcmla_v2f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x double> @llvm.aarch64.neon.vcmla.rot0.v2f64(
; VIRT: define <4 x float> @protected_vcmla_splat({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x float> @llvm.aarch64.neon.vcmla.rot0.v4f32(
; VIRT: define <4 x float> @protected_vcmla_last_complxnum({{.*}} #[[LAST:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x float> @llvm.aarch64.neon.vcmla.rot0.v4f32(
; VIRT: define {{.*}} @unsupported_no_complxnum({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROTH]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT: attributes #[[LAST]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; AARCH64-ASM: {{^[[:space:]]*}}fcmla{{[ \t]}}{{v[0-9]+}}.4h{{.*}}#0
; AARCH64-ASM: {{^[[:space:]]*}}fcmla{{[ \t]}}{{v[0-9]+}}.8h{{.*}}#0
; AARCH64-ASM: {{^[[:space:]]*}}fcmla{{[ \t]}}{{v[0-9]+}}.2s{{.*}}#0
; AARCH64-ASM: {{^[[:space:]]*}}fcmla{{[ \t]}}{{v[0-9]+}}.4s{{.*}}#0
; AARCH64-ASM: {{^[[:space:]]*}}fcmla{{[ \t]}}{{v[0-9]+}}.4s{{.*}}#90
; AARCH64-ASM: {{^[[:space:]]*}}fcmla{{[ \t]}}{{v[0-9]+}}.4s{{.*}}#180
; AARCH64-ASM: {{^[[:space:]]*}}fcmla{{[ \t]}}{{v[0-9]+}}.4s{{.*}}#270
; AARCH64-ASM: {{^[[:space:]]*}}fcmla{{[ \t]}}{{v[0-9]+}}.2d{{.*}}#0
; HOST: Skipping VMP: only AArch64 targets are supported
