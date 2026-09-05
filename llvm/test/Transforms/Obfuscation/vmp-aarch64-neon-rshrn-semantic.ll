; Restricted AArch64 NEON non-saturating rounding-narrow shift via
; CallDescriptor / vector VRegs (no new opcode):
;   llvm.aarch64.neon.rshrn
;     AdvSIMD_2Arg_Scalar_Narrow: anyint (extended, i32)
;     ISel SIMDVectorRShiftNarrowBHS, baseline HasNEON:
;       <8 x i8>(<8 x i16>, i32)   imm 1..8
;       <4 x i16>(<4 x i32>, i32)  imm 1..16
;       <2 x i32>(<2 x i64>, i32)  imm 1..32
; Only in-tree non-saturating rounding-narrow IR ID.  No neon.shrn
; ID (SHRN is trunc+ashr).  No rshrn2 ID (high-half is concat of
; this ID).  Half-element immediates may ISel as raddhn; still the
; same IR.  The i32 shift is not ImmArg; ISel matches
; vecshiftR*Narrow so it stays on CallDescriptor ImmediateArguments.
; Saturating sqshrn/uqshrn/sqrshrn/uqrshrn/sqshrun/sqrshrun are an
; independent surface and must not stay here as leftovers.
; Exact C non-vararg.  Ordinary tail accepted and replayed as non-tail; see vmp-direct-call-tail-eligibility-semantic.ll.
; No last-token gate.
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
declare <8 x i8> @llvm.aarch64.neon.rshrn.v8i8(<8 x i16>, i32)
declare <4 x i16> @llvm.aarch64.neon.rshrn.v4i16(<4 x i32>, i32)
declare <2 x i32> @llvm.aarch64.neon.rshrn.v2i32(<2 x i64>, i32)
declare i32 @llvm.aarch64.neon.rshrn.i32(i64, i32)
declare <4 x i8> @llvm.aarch64.neon.rshrn.v4i8(<4 x i16>, i32)
declare <vscale x 16 x i8> @llvm.aarch64.sve.rshrnb.nxv8i16(<vscale x 8 x i16>, i32)

@sink_v8i8 = global <8 x i8> zeroinitializer, align 8
@sink_v16i8 = global <16 x i8> zeroinitializer, align 16
@sink_v4i16 = global <4 x i16> zeroinitializer, align 8
@sink_v2i32 = global <2 x i32> zeroinitializer, align 8
@sink_v8i16 = global <8 x i16> zeroinitializer, align 16
@sink_v4i32 = global <4 x i32> zeroinitializer, align 16
@sink_v2i64 = global <2 x i64> zeroinitializer, align 16

define <8 x i8> @protected_rshrn_v8i8(<8 x i16> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i8> @llvm.aarch64.neon.rshrn.v8i8(<8 x i16> %a, i32 3)
  ret <8 x i8> %r
}

define <4 x i16> @protected_rshrn_v4i16(<4 x i32> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i16> @llvm.aarch64.neon.rshrn.v4i16(<4 x i32> %a, i32 9)
  ret <4 x i16> %r
}

define <2 x i32> @protected_rshrn_v2i32(<2 x i64> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i32> @llvm.aarch64.neon.rshrn.v2i32(<2 x i64> %a, i32 19)
  ret <2 x i32> %r
}

define <8 x i8> @protected_rshrn_v8i8_imm1(<8 x i16> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i8> @llvm.aarch64.neon.rshrn.v8i8(<8 x i16> %a, i32 1)
  ret <8 x i8> %r
}

; High-half is the same ID plus concat, not rshrn2 in IR.
define <16 x i8> @protected_rshrn_high_v16i8(<8 x i8> %lo, <8 x i16> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %hi = call <8 x i8> @llvm.aarch64.neon.rshrn.v8i8(<8 x i16> %a, i32 3)
  %r = shufflevector <8 x i8> %lo, <8 x i8> %hi, <16 x i32> <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7, i32 8, i32 9, i32 10, i32 11, i32 12, i32 13, i32 14, i32 15>
  ret <16 x i8> %r
}

; ----- negatives: selected, not virtualized -----

define <8 x i8> @unsupported_dynamic(<8 x i16> %a, i32 %s) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i8> @llvm.aarch64.neon.rshrn.v8i8(<8 x i16> %a, i32 %s)
  ret <8 x i8> %r
}

define <8 x i8> @unsupported_imm0(<8 x i16> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i8> @llvm.aarch64.neon.rshrn.v8i8(<8 x i16> %a, i32 0)
  ret <8 x i8> %r
}

define <8 x i8> @unsupported_imm_oor(<8 x i16> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i8> @llvm.aarch64.neon.rshrn.v8i8(<8 x i16> %a, i32 9)
  ret <8 x i8> %r
}

define i32 @unsupported_scalar(i64 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.rshrn.i32(i64 %a, i32 3)
  ret i32 %r
}

define <4 x i8> @unsupported_v4i8(<4 x i16> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i8> @llvm.aarch64.neon.rshrn.v4i8(<4 x i16> %a, i32 3)
  ret <4 x i8> %r
}

define <vscale x 16 x i8> @unsupported_sve_rshrnb(<vscale x 8 x i16> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 16 x i8> @llvm.aarch64.sve.rshrnb.nxv8i16(<vscale x 8 x i16> %a, i32 3)
  ret <vscale x 16 x i8> %r
}

define <8 x i8> @unsupported_fastcc(<8 x i16> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc <8 x i8> @llvm.aarch64.neon.rshrn.v8i8(<8 x i16> %a, i32 3)
  ret <8 x i8> %r
}


define <8 x i8> @unsupported_musttail(<8 x i16> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call <8 x i8> @llvm.aarch64.neon.rshrn.v8i8(<8 x i16> %a, i32 3)
  ret <8 x i8> %r
}

define <8 x i8> @unsupported_bundle(<8 x i16> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i8> @llvm.aarch64.neon.rshrn.v8i8(<8 x i16> %a, i32 3) [ "deopt"(i32 0) ]
  ret <8 x i8> %r
}

define <8 x i8> @unsupported_noreturn(<8 x i16> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i8> @llvm.aarch64.neon.rshrn.v8i8(<8 x i16> %a, i32 3) noreturn
  ret <8 x i8> %r
}

define <8 x i8> @unsupported_returns_twice(<8 x i16> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i8> @llvm.aarch64.neon.rshrn.v8i8(<8 x i16> %a, i32 3) returns_twice
  ret <8 x i8> %r
}

define i32 @main() {
entry:
  %w8h = load volatile <8 x i16>, ptr @sink_v8i16, align 16
  %r0 = call <8 x i8> @protected_rshrn_v8i8(<8 x i16> %w8h)
  store volatile <8 x i8> %r0, ptr @sink_v8i8, align 8
  %w4s = load volatile <4 x i32>, ptr @sink_v4i32, align 16
  %r1 = call <4 x i16> @protected_rshrn_v4i16(<4 x i32> %w4s)
  store volatile <4 x i16> %r1, ptr @sink_v4i16, align 8
  %w2d = load volatile <2 x i64>, ptr @sink_v2i64, align 16
  %r2 = call <2 x i32> @protected_rshrn_v2i32(<2 x i64> %w2d)
  store volatile <2 x i32> %r2, ptr @sink_v2i32, align 8
  %r3 = call <8 x i8> @protected_rshrn_v8i8_imm1(<8 x i16> %w8h)
  store volatile <8 x i8> %r3, ptr @sink_v8i8, align 8
  %lo = load volatile <8 x i8>, ptr @sink_v8i8, align 8
  %r4 = call <16 x i8> @protected_rshrn_high_v16i8(<8 x i8> %lo, <8 x i16> %w8h)
  store volatile <16 x i8> %r4, ptr @sink_v16i8, align 16
  ret i32 0
}

; SKIP-DAG: Skipping VMP on unsupported_dynamic: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_imm0: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_imm_oor: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_scalar: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_v4i8: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_sve_rshrnb: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_noreturn: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_returns_twice: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_rshrn_v8i8:
; SKIP-NOT: Skipping VMP on protected_rshrn_v4i16:
; SKIP-NOT: Skipping VMP on protected_rshrn_v2i32:
; SKIP-NOT: Skipping VMP on protected_rshrn_v8i8_imm1:
; SKIP-NOT: Skipping VMP on protected_rshrn_high_v16i8:

; VIRT: define <8 x i8> @protected_rshrn_v8i8({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x i8> @llvm.aarch64.neon.rshrn.v8i8(
; VIRT: define <4 x i16> @protected_rshrn_v4i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i16> @llvm.aarch64.neon.rshrn.v4i16(
; VIRT: define <2 x i32> @protected_rshrn_v2i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i32> @llvm.aarch64.neon.rshrn.v2i32(
; VIRT: define <8 x i8> @protected_rshrn_v8i8_imm1({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x i8> @llvm.aarch64.neon.rshrn.v8i8(
; VIRT: define <16 x i8> @protected_rshrn_high_v16i8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x i8> @llvm.aarch64.neon.rshrn.v8i8(
; VIRT: define {{.*}} @unsupported_dynamic({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; AARCH64-ASM-DAG: {{^[[:space:]]*}}rshrn{{[ \t]}}{{v[0-9]+}}.8b
; AARCH64-ASM-DAG: {{^[[:space:]]*}}rshrn{{[ \t]}}{{v[0-9]+}}.4h
; AARCH64-ASM-DAG: {{^[[:space:]]*}}rshrn{{[ \t]}}{{v[0-9]+}}.2s
; HOST: Skipping VMP: only AArch64 targets are supported
