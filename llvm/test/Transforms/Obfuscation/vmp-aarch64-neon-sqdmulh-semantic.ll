; Restricted AArch64 NEON saturating doubling multiply-high via
; CallDescriptor / vector VRegs:
;   llvm.aarch64.neon.sqdmulh / sqrdmulh
;     AdvSIMD_2IntArg: anyint (match, match)
;     ISel SIMDThreeSameVectorHS: v4i16 / v8i16 / v2i32 / v4i32
;   llvm.aarch64.neon.sqdmulh_lane / sqrdmulh_lane
;   llvm.aarch64.neon.sqdmulh_laneq / sqrdmulh_laneq
;     AdvSIMD_2VectorArg_Lane: anyint (match, anyint, i32)
;     lane:  64-bit same-element index vector, i32 imm in [0, Nsrc)
;     laneq: 128-bit same-element index vector, i32 imm in [0, Nsrc)
;     ISel SIMDIndexedHSPatterns; lane is not ImmArg but ISel requires
;     VectorIndex* / ConstantSDNode, so it stays a CallDescriptor
;     immediate.
; Baseline HasNEON; no +rdm / +aes gate.  Accumulating sqrdmlah /
; sqrdmlsh is vmp-aarch64-neon-sqrdmlah-semantic.ll (last-token +rdm).
; Exact C non-vararg.  Ordinary tail accepted and replayed as non-tail; see vmp-direct-call-tail-eligibility-semantic.ll.
; Well-formed scalar i32 is
; vmp-aarch64-neon-scalar-sqdmulh-semantic.ll and must not stay
; here as a skip (it would virtualize).  i8/i64, half/bfloat, SVE,
; and other multiplies stay out.  No new opcode.
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
declare <4 x i16> @llvm.aarch64.neon.sqdmulh.v4i16(<4 x i16>, <4 x i16>)
declare <8 x i16> @llvm.aarch64.neon.sqdmulh.v8i16(<8 x i16>, <8 x i16>)
declare <2 x i32> @llvm.aarch64.neon.sqdmulh.v2i32(<2 x i32>, <2 x i32>)
declare <4 x i32> @llvm.aarch64.neon.sqdmulh.v4i32(<4 x i32>, <4 x i32>)
declare <8 x i16> @llvm.aarch64.neon.sqrdmulh.v8i16(<8 x i16>, <8 x i16>)
declare <4 x i16> @llvm.aarch64.neon.sqdmulh.lane.v4i16.v4i16(<4 x i16>, <4 x i16>, i32)
declare <8 x i16> @llvm.aarch64.neon.sqrdmulh.laneq.v8i16.v8i16(<8 x i16>, <8 x i16>, i32)
declare <2 x i32> @llvm.aarch64.neon.sqdmulh.lane.v2i32.v2i32(<2 x i32>, <2 x i32>, i32)
declare <4 x i32> @llvm.aarch64.neon.sqrdmulh.laneq.v4i32.v4i32(<4 x i32>, <4 x i32>, i32)
declare <4 x i16> @llvm.aarch64.neon.sqdmulh.laneq.v4i16.v8i16(<4 x i16>, <8 x i16>, i32)
declare <8 x i16> @llvm.aarch64.neon.sqdmulh.lane.v8i16.v4i16(<8 x i16>, <4 x i16>, i32)
declare <4 x i16> @llvm.aarch64.neon.sqdmulh.laneq.v4i16.v4i16(<4 x i16>, <4 x i16>, i32)
declare <4 x i16> @llvm.aarch64.neon.sqdmulh.lane.v4i16.v8i16(<4 x i16>, <8 x i16>, i32)
; Well-formed scalar llvm.aarch64.neon.sqdmulh.i32 / sqrdmulh.i32
; is vmp-aarch64-neon-scalar-sqdmulh-semantic.ll and would
; virtualize here.
declare <8 x i8> @llvm.aarch64.neon.sqdmulh.v8i8(<8 x i8>, <8 x i8>)
declare <2 x i64> @llvm.aarch64.neon.sqdmulh.v2i64(<2 x i64>, <2 x i64>)
; Well-formed pmul.v8i8 / v16i8 is vmp-aarch64-neon-pmul-semantic.ll
; and would virtualize here.
declare <8 x i16> @llvm.aarch64.neon.pmul.v8i16(<8 x i16>, <8 x i16>)
declare <vscale x 8 x i16> @llvm.aarch64.sve.sqdmulh.nxv8i16(<vscale x 8 x i16>, <vscale x 8 x i16>)

@sink_v4i16 = global <4 x i16> zeroinitializer, align 8
@sink_v8i16 = global <8 x i16> zeroinitializer, align 16
@sink_v2i32 = global <2 x i32> zeroinitializer, align 8
@sink_v4i32 = global <4 x i32> zeroinitializer, align 16

define <4 x i16> @protected_sqdmulh_v4i16(<4 x i16> %a, <4 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i16> @llvm.aarch64.neon.sqdmulh.v4i16(<4 x i16> %a, <4 x i16> %b)
  ret <4 x i16> %r
}

define <8 x i16> @protected_sqdmulh_v8i16(<8 x i16> %a, <8 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i16> @llvm.aarch64.neon.sqdmulh.v8i16(<8 x i16> %a, <8 x i16> %b)
  ret <8 x i16> %r
}

define <2 x i32> @protected_sqdmulh_v2i32(<2 x i32> %a, <2 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i32> @llvm.aarch64.neon.sqdmulh.v2i32(<2 x i32> %a, <2 x i32> %b)
  ret <2 x i32> %r
}

define <4 x i32> @protected_sqdmulh_v4i32(<4 x i32> %a, <4 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.sqdmulh.v4i32(<4 x i32> %a, <4 x i32> %b)
  ret <4 x i32> %r
}

define <8 x i16> @protected_sqrdmulh_v8i16(<8 x i16> %a, <8 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i16> @llvm.aarch64.neon.sqrdmulh.v8i16(<8 x i16> %a, <8 x i16> %b)
  ret <8 x i16> %r
}

; last-token +rdm is not required and must not change the non-accumulating surface.
define <8 x i16> @protected_sqrdmulh_nordm(<8 x i16> %a, <8 x i16> %b) noinline optnone "target-features"="-rdm" {
entry:
  call void @hikari_vmp()
  %r = call <8 x i16> @llvm.aarch64.neon.sqrdmulh.v8i16(<8 x i16> %a, <8 x i16> %b)
  ret <8 x i16> %r
}

; last-token +rdm is ignored for the non-accumulating family (not a gate).
define <8 x i16> @protected_sqrdmulh_rdm(<8 x i16> %a, <8 x i16> %b) noinline optnone "target-features"="+rdm" {
entry:
  call void @hikari_vmp()
  %r = call <8 x i16> @llvm.aarch64.neon.sqrdmulh.v8i16(<8 x i16> %a, <8 x i16> %b)
  ret <8 x i16> %r
}

define <4 x i16> @protected_sqdmulh_lane(<4 x i16> %a, <4 x i16> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i16> @llvm.aarch64.neon.sqdmulh.lane.v4i16.v4i16(<4 x i16> %a, <4 x i16> %v, i32 3)
  ret <4 x i16> %r
}

define <8 x i16> @protected_sqrdmulh_laneq(<8 x i16> %a, <8 x i16> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i16> @llvm.aarch64.neon.sqrdmulh.laneq.v8i16.v8i16(<8 x i16> %a, <8 x i16> %v, i32 7)
  ret <8 x i16> %r
}

define <2 x i32> @protected_sqdmulh_lane_s(<2 x i32> %a, <2 x i32> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i32> @llvm.aarch64.neon.sqdmulh.lane.v2i32.v2i32(<2 x i32> %a, <2 x i32> %v, i32 1)
  ret <2 x i32> %r
}

define <4 x i32> @protected_sqrdmulh_laneq_s(<4 x i32> %a, <4 x i32> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.sqrdmulh.laneq.v4i32.v4i32(<4 x i32> %a, <4 x i32> %v, i32 3)
  ret <4 x i32> %r
}

; ISel SIMDIndexedHSPatterns mixed widths: laneq uses 128-bit idx, lane 64-bit.
define <4 x i16> @protected_sqdmulh_laneq_mixed(<4 x i16> %a, <8 x i16> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i16> @llvm.aarch64.neon.sqdmulh.laneq.v4i16.v8i16(<4 x i16> %a, <8 x i16> %v, i32 7)
  ret <4 x i16> %r
}

define <8 x i16> @protected_sqdmulh_lane_mixed(<8 x i16> %a, <4 x i16> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i16> @llvm.aarch64.neon.sqdmulh.lane.v8i16.v4i16(<8 x i16> %a, <4 x i16> %v, i32 3)
  ret <8 x i16> %r
}

define <8 x i8> @unsupported_v8i8(<8 x i8> %a, <8 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i8> @llvm.aarch64.neon.sqdmulh.v8i8(<8 x i8> %a, <8 x i8> %b)
  ret <8 x i8> %r
}

define <2 x i64> @unsupported_v2i64(<2 x i64> %a, <2 x i64> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.aarch64.neon.sqdmulh.v2i64(<2 x i64> %a, <2 x i64> %b)
  ret <2 x i64> %r
}

define <4 x i16> @unsupported_lane_dynamic(<4 x i16> %a, <4 x i16> %v, i32 %lane) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i16> @llvm.aarch64.neon.sqdmulh.lane.v4i16.v4i16(<4 x i16> %a, <4 x i16> %v, i32 %lane)
  ret <4 x i16> %r
}

define <4 x i16> @unsupported_lane_oob(<4 x i16> %a, <4 x i16> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i16> @llvm.aarch64.neon.sqdmulh.lane.v4i16.v4i16(<4 x i16> %a, <4 x i16> %v, i32 4)
  ret <4 x i16> %r
}

define <4 x i16> @unsupported_lane_neg(<4 x i16> %a, <4 x i16> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i16> @llvm.aarch64.neon.sqdmulh.lane.v4i16.v4i16(<4 x i16> %a, <4 x i16> %v, i32 -1)
  ret <4 x i16> %r
}

define <4 x i16> @unsupported_laneq_narrow_idx(<4 x i16> %a, <4 x i16> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i16> @llvm.aarch64.neon.sqdmulh.laneq.v4i16.v4i16(<4 x i16> %a, <4 x i16> %v, i32 1)
  ret <4 x i16> %r
}

define <4 x i16> @unsupported_lane_wide_idx(<4 x i16> %a, <8 x i16> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i16> @llvm.aarch64.neon.sqdmulh.lane.v4i16.v8i16(<4 x i16> %a, <8 x i16> %v, i32 1)
  ret <4 x i16> %r
}

; Well-formed llvm.aarch64.neon.sqrdmlah / sqrdmlsh with last-token
; +rdm is covered by vmp-aarch64-neon-sqrdmlah-semantic.ll and must
; not stay here as a negative (it would virtualize).
; Well-formed llvm.aarch64.neon.smull / umull is
; vmp-aarch64-neon-smull-semantic.ll.

define <8 x i16> @unsupported_pmul(<8 x i16> %a, <8 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i16> @llvm.aarch64.neon.pmul.v8i16(<8 x i16> %a, <8 x i16> %b)
  ret <8 x i16> %r
}

define <vscale x 8 x i16> @unsupported_sve(<vscale x 8 x i16> %a, <vscale x 8 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 8 x i16> @llvm.aarch64.sve.sqdmulh.nxv8i16(<vscale x 8 x i16> %a, <vscale x 8 x i16> %b)
  ret <vscale x 8 x i16> %r
}

define <8 x i16> @unsupported_fastcc(<8 x i16> %a, <8 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc <8 x i16> @llvm.aarch64.neon.sqdmulh.v8i16(<8 x i16> %a, <8 x i16> %b)
  ret <8 x i16> %r
}


define <8 x i16> @unsupported_musttail(<8 x i16> %a, <8 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call <8 x i16> @llvm.aarch64.neon.sqdmulh.v8i16(<8 x i16> %a, <8 x i16> %b)
  ret <8 x i16> %r
}

define <8 x i16> @unsupported_bundle(<8 x i16> %a, <8 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i16> @llvm.aarch64.neon.sqdmulh.v8i16(<8 x i16> %a, <8 x i16> %b) [ "deopt"(i32 0) ]
  ret <8 x i16> %r
}

define i32 @main() {
entry:
  %a4 = load volatile <4 x i16>, ptr @sink_v4i16, align 8
  %b4 = load volatile <4 x i16>, ptr @sink_v4i16, align 8
  %r0 = call <4 x i16> @protected_sqdmulh_v4i16(<4 x i16> %a4, <4 x i16> %b4)
  store volatile <4 x i16> %r0, ptr @sink_v4i16, align 8
  %a8 = load volatile <8 x i16>, ptr @sink_v8i16, align 16
  %b8 = load volatile <8 x i16>, ptr @sink_v8i16, align 16
  %r1 = call <8 x i16> @protected_sqdmulh_v8i16(<8 x i16> %a8, <8 x i16> %b8)
  store volatile <8 x i16> %r1, ptr @sink_v8i16, align 16
  %a2 = load volatile <2 x i32>, ptr @sink_v2i32, align 8
  %b2 = load volatile <2 x i32>, ptr @sink_v2i32, align 8
  %r2 = call <2 x i32> @protected_sqdmulh_v2i32(<2 x i32> %a2, <2 x i32> %b2)
  store volatile <2 x i32> %r2, ptr @sink_v2i32, align 8
  %a32 = load volatile <4 x i32>, ptr @sink_v4i32, align 16
  %b32 = load volatile <4 x i32>, ptr @sink_v4i32, align 16
  %r3 = call <4 x i32> @protected_sqdmulh_v4i32(<4 x i32> %a32, <4 x i32> %b32)
  store volatile <4 x i32> %r3, ptr @sink_v4i32, align 16
  %r4 = call <8 x i16> @protected_sqrdmulh_v8i16(<8 x i16> %a8, <8 x i16> %b8)
  store volatile <8 x i16> %r4, ptr @sink_v8i16, align 16
  %r5 = call <8 x i16> @protected_sqrdmulh_nordm(<8 x i16> %a8, <8 x i16> %b8)
  store volatile <8 x i16> %r5, ptr @sink_v8i16, align 16
  %r5b = call <8 x i16> @protected_sqrdmulh_rdm(<8 x i16> %a8, <8 x i16> %b8)
  store volatile <8 x i16> %r5b, ptr @sink_v8i16, align 16
  %r6 = call <4 x i16> @protected_sqdmulh_lane(<4 x i16> %a4, <4 x i16> %b4)
  store volatile <4 x i16> %r6, ptr @sink_v4i16, align 8
  %r7 = call <8 x i16> @protected_sqrdmulh_laneq(<8 x i16> %a8, <8 x i16> %b8)
  store volatile <8 x i16> %r7, ptr @sink_v8i16, align 16
  %r8 = call <2 x i32> @protected_sqdmulh_lane_s(<2 x i32> %a2, <2 x i32> %b2)
  store volatile <2 x i32> %r8, ptr @sink_v2i32, align 8
  %r9 = call <4 x i32> @protected_sqrdmulh_laneq_s(<4 x i32> %a32, <4 x i32> %b32)
  store volatile <4 x i32> %r9, ptr @sink_v4i32, align 16
  %r10 = call <4 x i16> @protected_sqdmulh_laneq_mixed(<4 x i16> %a4, <8 x i16> %a8)
  store volatile <4 x i16> %r10, ptr @sink_v4i16, align 8
  %r11 = call <8 x i16> @protected_sqdmulh_lane_mixed(<8 x i16> %a8, <4 x i16> %a4)
  store volatile <8 x i16> %r11, ptr @sink_v8i16, align 16
  ret i32 0
}

; SKIP-DAG: Skipping VMP on unsupported_v8i8: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_v2i64: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_lane_dynamic: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_lane_oob: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_lane_neg: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_laneq_narrow_idx: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_lane_wide_idx: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_pmul: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_sve: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_sqdmulh_v4i16:
; SKIP-NOT: Skipping VMP on protected_sqdmulh_v8i16:
; SKIP-NOT: Skipping VMP on protected_sqdmulh_v2i32:
; SKIP-NOT: Skipping VMP on protected_sqdmulh_v4i32:
; SKIP-NOT: Skipping VMP on protected_sqrdmulh_v8i16:
; SKIP-NOT: Skipping VMP on protected_sqrdmulh_nordm:
; SKIP-NOT: Skipping VMP on protected_sqrdmulh_rdm:
; SKIP-NOT: Skipping VMP on protected_sqdmulh_lane:
; SKIP-NOT: Skipping VMP on protected_sqrdmulh_laneq:
; SKIP-NOT: Skipping VMP on protected_sqdmulh_lane_s:
; SKIP-NOT: Skipping VMP on protected_sqrdmulh_laneq_s:
; SKIP-NOT: Skipping VMP on protected_sqdmulh_laneq_mixed:
; SKIP-NOT: Skipping VMP on protected_sqdmulh_lane_mixed:

; VIRT: define <4 x i16> @protected_sqdmulh_v4i16({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i16> @llvm.aarch64.neon.sqdmulh.v4i16(
; VIRT: define <8 x i16> @protected_sqdmulh_v8i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x i16> @llvm.aarch64.neon.sqdmulh.v8i16(
; VIRT: define <2 x i32> @protected_sqdmulh_v2i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <4 x i32> @protected_sqdmulh_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <8 x i16> @protected_sqrdmulh_v8i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x i16> @llvm.aarch64.neon.sqrdmulh.v8i16(
; VIRT: define <8 x i16> @protected_sqrdmulh_nordm({{.*}} #[[NORDM:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: define <8 x i16> @protected_sqrdmulh_rdm({{.*}} #[[RDM:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: define <4 x i16> @protected_sqdmulh_lane({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i16> @llvm.aarch64.neon.sqdmulh.lane.v4i16.v4i16({{.*}} i32 3)
; VIRT: define <8 x i16> @protected_sqrdmulh_laneq({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x i16> @llvm.aarch64.neon.sqrdmulh.laneq.v8i16.v8i16({{.*}} i32 7)
; VIRT: define <4 x i16> @protected_sqdmulh_laneq_mixed({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i16> @llvm.aarch64.neon.sqdmulh.laneq.v4i16.v8i16({{.*}} i32 7)
; VIRT: define <8 x i16> @protected_sqdmulh_lane_mixed({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x i16> @llvm.aarch64.neon.sqdmulh.lane.v8i16.v4i16({{.*}} i32 3)
; VIRT: define {{.*}} @unsupported_v8i8({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT: attributes #[[NORDM]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT: attributes #[[RDM]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; AARCH64-ASM: sqdmulh
; AARCH64-ASM: sqrdmulh
; HOST: Skipping VMP: only AArch64 targets are supported
