; Restricted AArch64 NEON saturating doubling long multiply via
; CallDescriptor / vector VRegs:
;   llvm.aarch64.neon.sqdmull
;     AdvSIMD_2VectorArg_Long: anyvector (trunc, trunc)
;     ISel SIMDLongThreeVectorHS low-half, baseline HasNEON:
;       <4 x i32>(<4 x i16>, <4 x i16>) -> sqdmull v.4s, v.4h
;       <2 x i64>(<2 x i32>, <2 x i32>) -> sqdmull v.2d, v.2s
; HS only: no i8 source.  High-half sqdmull2 is extract_high + this
; same IR form, not a second ID.  No NEON lane ID.  Accumulate
; sqdmlal/sqdmlsl has no IR ID
; (vmp-aarch64-neon-sqdmlal-semantic.ll locks sqdmull+sqadd/sqsub).
; sqdmulls.scalar is
; vmp-aarch64-neon-sqdmulls-scalar-semantic.ll.
; 256-bit Long, smull/umull/pmull, and SVE sqdmullb/t stay out.
; Exact C non-vararg.  Ordinary tail accepted and replayed as non-tail; see vmp-direct-call-tail-eligibility-semantic.ll.
; No last-token gate.  No new opcode.
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
declare <4 x i32> @llvm.aarch64.neon.sqdmull.v4i32(<4 x i16>, <4 x i16>)
declare <2 x i64> @llvm.aarch64.neon.sqdmull.v2i64(<2 x i32>, <2 x i32>)
declare <8 x i16> @llvm.aarch64.neon.sqdmull.v8i16(<8 x i8>, <8 x i8>)
declare <8 x i32> @llvm.aarch64.neon.sqdmull.v8i32(<8 x i16>, <8 x i16>)
declare <8 x i16> @llvm.aarch64.neon.pmul.v8i16(<8 x i16>, <8 x i16>)
declare <vscale x 4 x i32> @llvm.aarch64.sve.sqdmullb.nxv4i32(<vscale x 8 x i16>, <vscale x 8 x i16>)
declare <vscale x 4 x i32> @llvm.aarch64.sve.sqdmullt.nxv4i32(<vscale x 8 x i16>, <vscale x 8 x i16>)

@sink_v4i16 = global <4 x i16> zeroinitializer, align 8
@sink_v4i32 = global <4 x i32> zeroinitializer, align 16
@sink_v2i32 = global <2 x i32> zeroinitializer, align 8
@sink_v2i64 = global <2 x i64> zeroinitializer, align 16

define <4 x i32> @protected_sqdmull_v4i32(<4 x i16> %a, <4 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.sqdmull.v4i32(<4 x i16> %a, <4 x i16> %b)
  ret <4 x i32> %r
}

define <2 x i64> @protected_sqdmull_v2i64(<2 x i32> %a, <2 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.aarch64.neon.sqdmull.v2i64(<2 x i32> %a, <2 x i32> %b)
  ret <2 x i64> %r
}

; Well-formed llvm.aarch64.neon.sqdmulls.scalar is
; vmp-aarch64-neon-sqdmulls-scalar-semantic.ll and must not stay
; here with SKIP (it would virtualize).

define <8 x i16> @unsupported_v8i8(<8 x i8> %a, <8 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i16> @llvm.aarch64.neon.sqdmull.v8i16(<8 x i8> %a, <8 x i8> %b)
  ret <8 x i16> %r
}

define <8 x i32> @unsupported_wide_v8i32(<8 x i16> %a, <8 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i32> @llvm.aarch64.neon.sqdmull.v8i32(<8 x i16> %a, <8 x i16> %b)
  ret <8 x i32> %r
}

define <8 x i16> @unsupported_pmul(<8 x i16> %a, <8 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i16> @llvm.aarch64.neon.pmul.v8i16(<8 x i16> %a, <8 x i16> %b)
  ret <8 x i16> %r
}

define <vscale x 4 x i32> @unsupported_sve_b(<vscale x 8 x i16> %a, <vscale x 8 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.aarch64.sve.sqdmullb.nxv4i32(<vscale x 8 x i16> %a, <vscale x 8 x i16> %b)
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @unsupported_sve_t(<vscale x 8 x i16> %a, <vscale x 8 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.aarch64.sve.sqdmullt.nxv4i32(<vscale x 8 x i16> %a, <vscale x 8 x i16> %b)
  ret <vscale x 4 x i32> %r
}

define <4 x i32> @unsupported_fastcc(<4 x i16> %a, <4 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc <4 x i32> @llvm.aarch64.neon.sqdmull.v4i32(<4 x i16> %a, <4 x i16> %b)
  ret <4 x i32> %r
}


define <4 x i32> @unsupported_musttail(<4 x i16> %a, <4 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call <4 x i32> @llvm.aarch64.neon.sqdmull.v4i32(<4 x i16> %a, <4 x i16> %b)
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_bundle(<4 x i16> %a, <4 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.sqdmull.v4i32(<4 x i16> %a, <4 x i16> %b) [ "deopt"(i32 0) ]
  ret <4 x i32> %r
}

define i32 @main() {
entry:
  %a4 = load volatile <4 x i16>, ptr @sink_v4i16, align 8
  %b4 = load volatile <4 x i16>, ptr @sink_v4i16, align 8
  %r0 = call <4 x i32> @protected_sqdmull_v4i32(<4 x i16> %a4, <4 x i16> %b4)
  store volatile <4 x i32> %r0, ptr @sink_v4i32, align 16
  %a2 = load volatile <2 x i32>, ptr @sink_v2i32, align 8
  %b2 = load volatile <2 x i32>, ptr @sink_v2i32, align 8
  %r1 = call <2 x i64> @protected_sqdmull_v2i64(<2 x i32> %a2, <2 x i32> %b2)
  store volatile <2 x i64> %r1, ptr @sink_v2i64, align 16
  ret i32 0
}

; SKIP-DAG: Skipping VMP on unsupported_v8i8: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_wide_v8i32: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_pmul: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_sve_b: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_sve_t: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_sqdmull_v4i32:
; SKIP-NOT: Skipping VMP on protected_sqdmull_v2i64:

; VIRT: define <4 x i32> @protected_sqdmull_v4i32({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.aarch64.neon.sqdmull.v4i32(
; VIRT: define <2 x i64> @protected_sqdmull_v2i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i64> @llvm.aarch64.neon.sqdmull.v2i64(
; VIRT: define {{.*}} @unsupported_v8i8({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; AARCH64-ASM: sqdmull{{[ \t]}}
; HOST: Skipping VMP: only AArch64 targets are supported
