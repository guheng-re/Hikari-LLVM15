; Restricted AArch64 NEON saturating doubling multiply-long
; accumulate / subtract.  LLVM 15 has no llvm.aarch64.neon.sqdmlal
; / sqdmlsl IR IDs (IntrinsicsAArch64.td defines only sqdmull /
; sqdmulls.scalar and SVE sqdmlalb/t / sqdmlslb/t).  clang
; vqdmlal / vqdmlsl is NEONMAP2 to sqdmull + sqadd / sqsub.
; ISel SIMDLongThreeVectorSQDMLXTiedHS (baseline HasNEON):
;   sqdmlal: sqadd(acc, sqdmull(a,b))
;     v4i32 acc + v4i16,v4i16  -> sqdmlal v.4s, v.4h
;     v2i64 acc + v2i32,v2i32  -> sqdmlal v.2d, v.2s
;   sqdmlsl: sqsub(acc, sqdmull(a,b))  same pairs
; HS only: no i8 source.  High-half sqdmlal2 is extract_high of
; the 128-bit sources then the same low IR, not a second ID.
; Lane / laneq is splat shufflevector then the same IR; ISel
; SIMDIndexedLongSQDMLXSDTied matches duplane
; (VectorIndexH 0..7 on i16, VectorIndexS 0..3 on i32).  No
; NEON .lane IR ID and no ImmArg.  Do not invent CallDescriptor
; IDs.  Never lower to ordinary mul/add/sub.  Coverage is
; existing sqdmull + sqadd/sqsub CallDescriptor.  Well-formed
; sqdmulls.scalar-only is
; vmp-aarch64-neon-sqdmulls-scalar-semantic.ll.  Composite
; sqdmulls.scalar + scalar sqadd stays out: no dedicated
; scalar sqdmlal ID.  Exact C non-vararg.  Ordinary tail accepted and replayed as non-tail; see vmp-direct-call-tail-eligibility-semantic.ll.  No last-token gate.  No
; new opcode.
;
; VReg replay splits the ISel sqdmlal idiom into sqdmull then
; sqadd/sqsub.  Host cannot select these AArch64 intrinsics;
; no lli.  FileCheck + AArch64 llc/readobj/asm.  O0/O2 x 97/7.
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
declare <4 x i32> @llvm.aarch64.neon.sqdmull.v4i32(<4 x i16>, <4 x i16>)
declare <2 x i64> @llvm.aarch64.neon.sqdmull.v2i64(<2 x i32>, <2 x i32>)
declare <4 x i32> @llvm.aarch64.neon.sqadd.v4i32(<4 x i32>, <4 x i32>)
declare <2 x i64> @llvm.aarch64.neon.sqadd.v2i64(<2 x i64>, <2 x i64>)
declare <4 x i32> @llvm.aarch64.neon.sqsub.v4i32(<4 x i32>, <4 x i32>)
declare <2 x i64> @llvm.aarch64.neon.sqsub.v2i64(<2 x i64>, <2 x i64>)
declare i64 @llvm.aarch64.neon.sqdmulls.scalar(i32, i32)
declare i64 @llvm.aarch64.neon.sqadd.i64(i64, i64)
declare i32 @llvm.aarch64.neon.sqadd.i32(i32, i32)
declare <8 x i16> @llvm.aarch64.neon.sqdmull.v8i16(<8 x i8>, <8 x i8>)
declare <8 x i16> @llvm.aarch64.neon.sqadd.v8i16(<8 x i16>, <8 x i16>)
declare <8 x i32> @llvm.aarch64.neon.sqdmull.v8i32(<8 x i16>, <8 x i16>)
declare <8 x i32> @llvm.aarch64.neon.sqadd.v8i32(<8 x i32>, <8 x i32>)

declare <vscale x 4 x i32> @llvm.aarch64.sve.sqdmlalb.nxv4i32(<vscale x 4 x i32>, <vscale x 8 x i16>, <vscale x 8 x i16>)
declare <vscale x 4 x i32> @llvm.aarch64.sve.sqdmlslb.nxv4i32(<vscale x 4 x i32>, <vscale x 8 x i16>, <vscale x 8 x i16>)

@sink_v4i16 = global <4 x i16> zeroinitializer, align 8
@sink_v8i16 = global <8 x i16> zeroinitializer, align 16
@sink_v4i32 = global <4 x i32> zeroinitializer, align 16
@sink_v2i32 = global <2 x i32> zeroinitializer, align 8
@sink_v2i64 = global <2 x i64> zeroinitializer, align 16

define <4 x i32> @protected_sqdmlal_v4i32(<4 x i32> %acc, <4 x i16> %a, <4 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %mul = call <4 x i32> @llvm.aarch64.neon.sqdmull.v4i32(<4 x i16> %a, <4 x i16> %b)
  %r = call <4 x i32> @llvm.aarch64.neon.sqadd.v4i32(<4 x i32> %acc, <4 x i32> %mul)
  ret <4 x i32> %r
}

define <2 x i64> @protected_sqdmlal_v2i64(<2 x i64> %acc, <2 x i32> %a, <2 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %mul = call <2 x i64> @llvm.aarch64.neon.sqdmull.v2i64(<2 x i32> %a, <2 x i32> %b)
  %r = call <2 x i64> @llvm.aarch64.neon.sqadd.v2i64(<2 x i64> %acc, <2 x i64> %mul)
  ret <2 x i64> %r
}

define <4 x i32> @protected_sqdmlsl_v4i32(<4 x i32> %acc, <4 x i16> %a, <4 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %mul = call <4 x i32> @llvm.aarch64.neon.sqdmull.v4i32(<4 x i16> %a, <4 x i16> %b)
  %r = call <4 x i32> @llvm.aarch64.neon.sqsub.v4i32(<4 x i32> %acc, <4 x i32> %mul)
  ret <4 x i32> %r
}

define <2 x i64> @protected_sqdmlsl_v2i64(<2 x i64> %acc, <2 x i32> %a, <2 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %mul = call <2 x i64> @llvm.aarch64.neon.sqdmull.v2i64(<2 x i32> %a, <2 x i32> %b)
  %r = call <2 x i64> @llvm.aarch64.neon.sqsub.v2i64(<2 x i64> %acc, <2 x i64> %mul)
  ret <2 x i64> %r
}

define <4 x i32> @protected_sqdmlal_high_v4i32(<4 x i32> %acc, <8 x i16> %a, <8 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %ha = shufflevector <8 x i16> %a, <8 x i16> undef, <4 x i32> <i32 4, i32 5, i32 6, i32 7>
  %hb = shufflevector <8 x i16> %b, <8 x i16> undef, <4 x i32> <i32 4, i32 5, i32 6, i32 7>
  %mul = call <4 x i32> @llvm.aarch64.neon.sqdmull.v4i32(<4 x i16> %ha, <4 x i16> %hb)
  %r = call <4 x i32> @llvm.aarch64.neon.sqadd.v4i32(<4 x i32> %acc, <4 x i32> %mul)
  ret <4 x i32> %r
}

define <2 x i64> @protected_sqdmlal_high_v2i64(<2 x i64> %acc, <4 x i32> %a, <4 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %ha = shufflevector <4 x i32> %a, <4 x i32> undef, <2 x i32> <i32 2, i32 3>
  %hb = shufflevector <4 x i32> %b, <4 x i32> undef, <2 x i32> <i32 2, i32 3>
  %mul = call <2 x i64> @llvm.aarch64.neon.sqdmull.v2i64(<2 x i32> %ha, <2 x i32> %hb)
  %r = call <2 x i64> @llvm.aarch64.neon.sqadd.v2i64(<2 x i64> %acc, <2 x i64> %mul)
  ret <2 x i64> %r
}

define <4 x i32> @protected_sqdmlsl_high_v4i32(<4 x i32> %acc, <8 x i16> %a, <8 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %ha = shufflevector <8 x i16> %a, <8 x i16> undef, <4 x i32> <i32 4, i32 5, i32 6, i32 7>
  %hb = shufflevector <8 x i16> %b, <8 x i16> undef, <4 x i32> <i32 4, i32 5, i32 6, i32 7>
  %mul = call <4 x i32> @llvm.aarch64.neon.sqdmull.v4i32(<4 x i16> %ha, <4 x i16> %hb)
  %r = call <4 x i32> @llvm.aarch64.neon.sqsub.v4i32(<4 x i32> %acc, <4 x i32> %mul)
  ret <4 x i32> %r
}

define <2 x i64> @protected_sqdmlsl_high_v2i64(<2 x i64> %acc, <4 x i32> %a, <4 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %ha = shufflevector <4 x i32> %a, <4 x i32> undef, <2 x i32> <i32 2, i32 3>
  %hb = shufflevector <4 x i32> %b, <4 x i32> undef, <2 x i32> <i32 2, i32 3>
  %mul = call <2 x i64> @llvm.aarch64.neon.sqdmull.v2i64(<2 x i32> %ha, <2 x i32> %hb)
  %r = call <2 x i64> @llvm.aarch64.neon.sqsub.v2i64(<2 x i64> %acc, <2 x i64> %mul)
  ret <2 x i64> %r
}

define <4 x i32> @protected_sqdmlal_lane_v4i32(<4 x i32> %acc, <4 x i16> %a, <4 x i16> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %splat = shufflevector <4 x i16> %v, <4 x i16> undef, <4 x i32> <i32 3, i32 3, i32 3, i32 3>
  %mul = call <4 x i32> @llvm.aarch64.neon.sqdmull.v4i32(<4 x i16> %a, <4 x i16> %splat)
  %r = call <4 x i32> @llvm.aarch64.neon.sqadd.v4i32(<4 x i32> %acc, <4 x i32> %mul)
  ret <4 x i32> %r
}

define <2 x i64> @protected_sqdmlal_lane_v2i64(<2 x i64> %acc, <2 x i32> %a, <2 x i32> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %splat = shufflevector <2 x i32> %v, <2 x i32> undef, <2 x i32> <i32 1, i32 1>
  %mul = call <2 x i64> @llvm.aarch64.neon.sqdmull.v2i64(<2 x i32> %a, <2 x i32> %splat)
  %r = call <2 x i64> @llvm.aarch64.neon.sqadd.v2i64(<2 x i64> %acc, <2 x i64> %mul)
  ret <2 x i64> %r
}

define <4 x i32> @protected_sqdmlsl_lane_v4i32(<4 x i32> %acc, <4 x i16> %a, <4 x i16> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %splat = shufflevector <4 x i16> %v, <4 x i16> undef, <4 x i32> <i32 3, i32 3, i32 3, i32 3>
  %mul = call <4 x i32> @llvm.aarch64.neon.sqdmull.v4i32(<4 x i16> %a, <4 x i16> %splat)
  %r = call <4 x i32> @llvm.aarch64.neon.sqsub.v4i32(<4 x i32> %acc, <4 x i32> %mul)
  ret <4 x i32> %r
}

define <2 x i64> @protected_sqdmlsl_lane_v2i64(<2 x i64> %acc, <2 x i32> %a, <2 x i32> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %splat = shufflevector <2 x i32> %v, <2 x i32> undef, <2 x i32> <i32 1, i32 1>
  %mul = call <2 x i64> @llvm.aarch64.neon.sqdmull.v2i64(<2 x i32> %a, <2 x i32> %splat)
  %r = call <2 x i64> @llvm.aarch64.neon.sqsub.v2i64(<2 x i64> %acc, <2 x i64> %mul)
  ret <2 x i64> %r
}

define <4 x i32> @protected_sqdmlal_smin_v4i32(<4 x i32> %acc) noinline optnone {
entry:
  call void @hikari_vmp()
  %mul = call <4 x i32> @llvm.aarch64.neon.sqdmull.v4i32(
      <4 x i16> <i16 -32768, i16 -32768, i16 -32768, i16 -32768>,
      <4 x i16> <i16 -32768, i16 -32768, i16 -32768, i16 -32768>)
  %r = call <4 x i32> @llvm.aarch64.neon.sqadd.v4i32(<4 x i32> %acc, <4 x i32> %mul)
  ret <4 x i32> %r
}

define <2 x i64> @protected_sqdmlsl_smin_v2i64(<2 x i64> %acc) noinline optnone {
entry:
  call void @hikari_vmp()
  %mul = call <2 x i64> @llvm.aarch64.neon.sqdmull.v2i64(
      <2 x i32> <i32 -2147483648, i32 -2147483648>,
      <2 x i32> <i32 -2147483648, i32 -2147483648>)
  %r = call <2 x i64> @llvm.aarch64.neon.sqsub.v2i64(<2 x i64> %acc, <2 x i64> %mul)
  ret <2 x i64> %r
}

; Well-formed llvm.aarch64.neon.sqdmull is
; vmp-aarch64-neon-sqdmull-semantic.ll and must not stay here as a
; negative (it would virtualize).  Well-formed sqadd/sqsub is the
; sat-int surface.

define i64 @unsupported_scalar(i64 %acc, i32 %a, i32 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %mul = call i64 @llvm.aarch64.neon.sqdmulls.scalar(i32 %a, i32 %b)
  %r = call i64 @llvm.aarch64.neon.sqadd.i64(i64 %acc, i64 %mul)
  ret i64 %r
}

define i32 @unsupported_scalar_i32(i32 %acc, i32 %a, i32 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.sqadd.i32(i32 %acc, i32 %a)
  ret i32 %r
}

define <8 x i16> @unsupported_i8(<8 x i16> %acc, <8 x i8> %a, <8 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %mul = call <8 x i16> @llvm.aarch64.neon.sqdmull.v8i16(<8 x i8> %a, <8 x i8> %b)
  %r = call <8 x i16> @llvm.aarch64.neon.sqadd.v8i16(<8 x i16> %acc, <8 x i16> %mul)
  ret <8 x i16> %r
}

define <8 x i32> @unsupported_v8i32(<8 x i32> %acc, <8 x i16> %a, <8 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %mul = call <8 x i32> @llvm.aarch64.neon.sqdmull.v8i32(<8 x i16> %a, <8 x i16> %b)
  %r = call <8 x i32> @llvm.aarch64.neon.sqadd.v8i32(<8 x i32> %acc, <8 x i32> %mul)
  ret <8 x i32> %r
}

; Well-formed llvm.aarch64.neon.fabd is covered by
; vmp-aarch64-neon-fabd-semantic.ll and must not stay here as a
; negative (it would virtualize, or half would become a feature miss).

define <4 x bfloat> @unsupported_bfloat(<4 x bfloat> %acc, <4 x bfloat> %a, <4 x bfloat> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  ret <4 x bfloat> %acc
}

define <vscale x 4 x i32> @unsupported_sve_sqdmlalb(<vscale x 4 x i32> %acc, <vscale x 8 x i16> %a, <vscale x 8 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.aarch64.sve.sqdmlalb.nxv4i32(<vscale x 4 x i32> %acc, <vscale x 8 x i16> %a, <vscale x 8 x i16> %b)
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @unsupported_sve_sqdmlslb(<vscale x 4 x i32> %acc, <vscale x 8 x i16> %a, <vscale x 8 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.aarch64.sve.sqdmlslb.nxv4i32(<vscale x 4 x i32> %acc, <vscale x 8 x i16> %a, <vscale x 8 x i16> %b)
  ret <vscale x 4 x i32> %r
}

define <4 x i32> @unsupported_fastcc(<4 x i32> %acc, <4 x i16> %a, <4 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %mul = call fastcc <4 x i32> @llvm.aarch64.neon.sqdmull.v4i32(<4 x i16> %a, <4 x i16> %b)
  %r = call <4 x i32> @llvm.aarch64.neon.sqadd.v4i32(<4 x i32> %acc, <4 x i32> %mul)
  ret <4 x i32> %r
}


define <4 x i32> @unsupported_musttail(<4 x i32> %acc, <4 x i16> %a, <4 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %mul = musttail call <4 x i32> @llvm.aarch64.neon.sqdmull.v4i32(<4 x i16> %a, <4 x i16> %b)
  ret <4 x i32> %mul
}

define <4 x i32> @unsupported_bundle(<4 x i32> %acc, <4 x i16> %a, <4 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %mul = call <4 x i32> @llvm.aarch64.neon.sqdmull.v4i32(<4 x i16> %a, <4 x i16> %b) [ "deopt"(i32 0) ]
  %r = call <4 x i32> @llvm.aarch64.neon.sqadd.v4i32(<4 x i32> %acc, <4 x i32> %mul)
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_noreturn(<4 x i32> %acc, <4 x i16> %a, <4 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %mul = call <4 x i32> @llvm.aarch64.neon.sqdmull.v4i32(<4 x i16> %a, <4 x i16> %b) noreturn
  %r = call <4 x i32> @llvm.aarch64.neon.sqadd.v4i32(<4 x i32> %acc, <4 x i32> %mul)
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_returns_twice(<4 x i32> %acc, <4 x i16> %a, <4 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %mul = call <4 x i32> @llvm.aarch64.neon.sqdmull.v4i32(<4 x i16> %a, <4 x i16> %b) returns_twice
  %r = call <4 x i32> @llvm.aarch64.neon.sqadd.v4i32(<4 x i32> %acc, <4 x i32> %mul)
  ret <4 x i32> %r
}

define i32 @main() {
entry:
  %acc4 = load volatile <4 x i32>, ptr @sink_v4i32, align 16
  %a4 = load volatile <4 x i16>, ptr @sink_v4i16, align 8
  %b4 = load volatile <4 x i16>, ptr @sink_v4i16, align 8
  %r0 = call <4 x i32> @protected_sqdmlal_v4i32(<4 x i32> %acc4, <4 x i16> %a4, <4 x i16> %b4)
  store volatile <4 x i32> %r0, ptr @sink_v4i32, align 16
  %acc2 = load volatile <2 x i64>, ptr @sink_v2i64, align 16
  %a2 = load volatile <2 x i32>, ptr @sink_v2i32, align 8
  %b2 = load volatile <2 x i32>, ptr @sink_v2i32, align 8
  %r1 = call <2 x i64> @protected_sqdmlal_v2i64(<2 x i64> %acc2, <2 x i32> %a2, <2 x i32> %b2)
  store volatile <2 x i64> %r1, ptr @sink_v2i64, align 16
  %r2 = call <4 x i32> @protected_sqdmlsl_v4i32(<4 x i32> %acc4, <4 x i16> %a4, <4 x i16> %b4)
  store volatile <4 x i32> %r2, ptr @sink_v4i32, align 16
  %r3 = call <2 x i64> @protected_sqdmlsl_v2i64(<2 x i64> %acc2, <2 x i32> %a2, <2 x i32> %b2)
  store volatile <2 x i64> %r3, ptr @sink_v2i64, align 16
  %a8 = load volatile <8 x i16>, ptr @sink_v8i16, align 16
  %b8 = load volatile <8 x i16>, ptr @sink_v8i16, align 16
  %r4 = call <4 x i32> @protected_sqdmlal_high_v4i32(<4 x i32> %acc4, <8 x i16> %a8, <8 x i16> %b8)
  store volatile <4 x i32> %r4, ptr @sink_v4i32, align 16
  %a4s = load volatile <4 x i32>, ptr @sink_v4i32, align 16
  %b4s = load volatile <4 x i32>, ptr @sink_v4i32, align 16
  %r5 = call <2 x i64> @protected_sqdmlal_high_v2i64(<2 x i64> %acc2, <4 x i32> %a4s, <4 x i32> %b4s)
  store volatile <2 x i64> %r5, ptr @sink_v2i64, align 16
  %r6 = call <4 x i32> @protected_sqdmlsl_high_v4i32(<4 x i32> %acc4, <8 x i16> %a8, <8 x i16> %b8)
  store volatile <4 x i32> %r6, ptr @sink_v4i32, align 16
  %r7 = call <2 x i64> @protected_sqdmlsl_high_v2i64(<2 x i64> %acc2, <4 x i32> %a4s, <4 x i32> %b4s)
  store volatile <2 x i64> %r7, ptr @sink_v2i64, align 16
  %r8 = call <4 x i32> @protected_sqdmlal_lane_v4i32(<4 x i32> %acc4, <4 x i16> %a4, <4 x i16> %b4)
  store volatile <4 x i32> %r8, ptr @sink_v4i32, align 16
  %r9 = call <2 x i64> @protected_sqdmlal_lane_v2i64(<2 x i64> %acc2, <2 x i32> %a2, <2 x i32> %b2)
  store volatile <2 x i64> %r9, ptr @sink_v2i64, align 16
  %r10 = call <4 x i32> @protected_sqdmlsl_lane_v4i32(<4 x i32> %acc4, <4 x i16> %a4, <4 x i16> %b4)
  store volatile <4 x i32> %r10, ptr @sink_v4i32, align 16
  %r11 = call <2 x i64> @protected_sqdmlsl_lane_v2i64(<2 x i64> %acc2, <2 x i32> %a2, <2 x i32> %b2)
  store volatile <2 x i64> %r11, ptr @sink_v2i64, align 16
  %r12 = call <4 x i32> @protected_sqdmlal_smin_v4i32(<4 x i32> %acc4)
  store volatile <4 x i32> %r12, ptr @sink_v4i32, align 16
  %r13 = call <2 x i64> @protected_sqdmlsl_smin_v2i64(<2 x i64> %acc2)
  store volatile <2 x i64> %r13, ptr @sink_v2i64, align 16
  ret i32 0
}

; SKIP-DAG: Skipping VMP on unsupported_scalar: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_scalar_i32: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_i8: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_v8i32: unsupported return type

; SKIP-DAG: Skipping VMP on unsupported_bfloat: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_sve_sqdmlalb: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_sve_sqdmlslb: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_noreturn: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_returns_twice: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_sqdmlal_v4i32:
; SKIP-NOT: Skipping VMP on protected_sqdmlal_v2i64:
; SKIP-NOT: Skipping VMP on protected_sqdmlsl_v4i32:
; SKIP-NOT: Skipping VMP on protected_sqdmlsl_v2i64:
; SKIP-NOT: Skipping VMP on protected_sqdmlal_high_v4i32:
; SKIP-NOT: Skipping VMP on protected_sqdmlal_high_v2i64:
; SKIP-NOT: Skipping VMP on protected_sqdmlsl_high_v4i32:
; SKIP-NOT: Skipping VMP on protected_sqdmlsl_high_v2i64:
; SKIP-NOT: Skipping VMP on protected_sqdmlal_lane_v4i32:
; SKIP-NOT: Skipping VMP on protected_sqdmlal_lane_v2i64:
; SKIP-NOT: Skipping VMP on protected_sqdmlsl_lane_v4i32:
; SKIP-NOT: Skipping VMP on protected_sqdmlsl_lane_v2i64:
; SKIP-NOT: Skipping VMP on protected_sqdmlal_smin_v4i32:
; SKIP-NOT: Skipping VMP on protected_sqdmlsl_smin_v2i64:

; VIRT: define <4 x i32> @protected_sqdmlal_v4i32({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.aarch64.neon.sqdmull.v4i32(
; VIRT: define <2 x i64> @protected_sqdmlal_v2i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <4 x i32> @protected_sqdmlsl_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.aarch64.neon.sqsub.v4i32(
; VIRT: define <2 x i64> @protected_sqdmlsl_v2i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <4 x i32> @protected_sqdmlal_high_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <2 x i64> @protected_sqdmlal_high_v2i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <4 x i32> @protected_sqdmlsl_high_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <2 x i64> @protected_sqdmlsl_high_v2i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <4 x i32> @protected_sqdmlal_lane_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <2 x i64> @protected_sqdmlal_lane_v2i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <4 x i32> @protected_sqdmlsl_lane_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <2 x i64> @protected_sqdmlsl_lane_v2i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <4 x i32> @protected_sqdmlal_smin_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <2 x i64> @protected_sqdmlsl_smin_v2i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define {{.*}} @unsupported_scalar({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; VReg replay splits the ISel sqdmlal idiom into sqdmull then sqadd/sqsub.
; AARCH64-ASM: {{^[[:space:]]*}}sqdmull{{[ \t]}}
; AARCH64-ASM: {{^[[:space:]]*}}sqadd{{[ \t]}}
; AARCH64-ASM: {{^[[:space:]]*}}sqsub{{[ \t]}}
; HOST: Skipping VMP: only AArch64 targets are supported
