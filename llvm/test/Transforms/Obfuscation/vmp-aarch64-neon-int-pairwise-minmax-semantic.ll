; Restricted AArch64 NEON same-width pairwise integer extrema via
; CallDescriptor / vector VRegs:
;   llvm.aarch64.neon.smaxp / umaxp / sminp / uminp
;     AdvSIMD_2VectorArg: anyvector (match, match)
;     ISel SIMDThreeSameVectorBHS, baseline HasNEON:
;       <8 x i8> / <16 x i8> / <4 x i16>
;       <8 x i16> / <2 x i32> / <4 x i32>
; Clang vpmax / vpmin integer forms.  Not element-wise
; smax / smin / umax / umin (independent surface).  Not a shuffle of adjacent pairs.
; Not across-lane smaxv / sminv.  Not addp / fmaxp.  No i64
; (BHS excludes D).  Exact C non-vararg.  Ordinary tail accepted and replayed as non-tail; see vmp-direct-call-tail-eligibility-semantic.ll.  No last-token gate.  No new opcode.
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
declare void @ext_sret_byval(ptr sret(i32), ptr byval(i32))
declare <8 x i8> @llvm.aarch64.neon.smaxp.v8i8(<8 x i8>, <8 x i8>)
declare <16 x i8> @llvm.aarch64.neon.smaxp.v16i8(<16 x i8>, <16 x i8>)
declare <4 x i16> @llvm.aarch64.neon.umaxp.v4i16(<4 x i16>, <4 x i16>)
declare <8 x i16> @llvm.aarch64.neon.umaxp.v8i16(<8 x i16>, <8 x i16>)
declare <2 x i32> @llvm.aarch64.neon.sminp.v2i32(<2 x i32>, <2 x i32>)
declare <4 x i32> @llvm.aarch64.neon.sminp.v4i32(<4 x i32>, <4 x i32>)
declare <8 x i8> @llvm.aarch64.neon.uminp.v8i8(<8 x i8>, <8 x i8>)
declare <16 x i8> @llvm.aarch64.neon.uminp.v16i8(<16 x i8>, <16 x i8>)
declare <4 x i16> @llvm.aarch64.neon.uminp.v4i16(<4 x i16>, <4 x i16>)
declare <4 x i32> @llvm.aarch64.neon.smaxp.v4i32(<4 x i32>, <4 x i32>)
declare <2 x i64> @llvm.aarch64.neon.smaxp.v2i64(<2 x i64>, <2 x i64>)
declare <1 x i32> @llvm.aarch64.neon.smaxp.v1i32(<1 x i32>, <1 x i32>)
declare <4 x i8> @llvm.aarch64.neon.sminp.v4i8(<4 x i8>, <4 x i8>)
declare <8 x i32> @llvm.aarch64.neon.umaxp.v8i32(<8 x i32>, <8 x i32>)
declare <8 x i1> @llvm.aarch64.neon.uminp.v8i1(<8 x i1>, <8 x i1>)

declare <vscale x 16 x i8> @llvm.aarch64.sve.smaxp.nxv16i8(<vscale x 16 x i1>, <vscale x 16 x i8>, <vscale x 16 x i8>)

@sink_v8i8 = global <8 x i8> zeroinitializer, align 8
@sink_v16i8 = global <16 x i8> zeroinitializer, align 16
@sink_v4i16 = global <4 x i16> zeroinitializer, align 8
@sink_v8i16 = global <8 x i16> zeroinitializer, align 16
@sink_v2i32 = global <2 x i32> zeroinitializer, align 8
@sink_v4i32 = global <4 x i32> zeroinitializer, align 16

define <8 x i8> @protected_smaxp_v8i8(<8 x i8> %a, <8 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i8> @llvm.aarch64.neon.smaxp.v8i8(<8 x i8> %a, <8 x i8> %b)
  ret <8 x i8> %r
}

define <16 x i8> @protected_smaxp_v16i8(<16 x i8> %a, <16 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <16 x i8> @llvm.aarch64.neon.smaxp.v16i8(<16 x i8> %a, <16 x i8> %b)
  ret <16 x i8> %r
}

define <4 x i32> @protected_smaxp_v4i32(<4 x i32> %a, <4 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.smaxp.v4i32(<4 x i32> %a, <4 x i32> %b)
  ret <4 x i32> %r
}

define <4 x i16> @protected_umaxp_v4i16(<4 x i16> %a, <4 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i16> @llvm.aarch64.neon.umaxp.v4i16(<4 x i16> %a, <4 x i16> %b)
  ret <4 x i16> %r
}

define <8 x i16> @protected_umaxp_v8i16(<8 x i16> %a, <8 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i16> @llvm.aarch64.neon.umaxp.v8i16(<8 x i16> %a, <8 x i16> %b)
  ret <8 x i16> %r
}

define <2 x i32> @protected_sminp_v2i32(<2 x i32> %a, <2 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i32> @llvm.aarch64.neon.sminp.v2i32(<2 x i32> %a, <2 x i32> %b)
  ret <2 x i32> %r
}

define <4 x i32> @protected_sminp_v4i32(<4 x i32> %a, <4 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.sminp.v4i32(<4 x i32> %a, <4 x i32> %b)
  ret <4 x i32> %r
}

define <8 x i8> @protected_uminp_v8i8(<8 x i8> %a, <8 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i8> @llvm.aarch64.neon.uminp.v8i8(<8 x i8> %a, <8 x i8> %b)
  ret <8 x i8> %r
}

define <16 x i8> @protected_uminp_v16i8(<16 x i8> %a, <16 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <16 x i8> @llvm.aarch64.neon.uminp.v16i8(<16 x i8> %a, <16 x i8> %b)
  ret <16 x i8> %r
}

define <4 x i16> @protected_uminp_v4i16(<4 x i16> %a, <4 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i16> @llvm.aarch64.neon.uminp.v4i16(<4 x i16> %a, <4 x i16> %b)
  ret <4 x i16> %r
}

; Well-formed llvm.aarch64.neon.addp is covered by
; vmp-aarch64-neon-addp-semantic.ll and must not stay here as a
; negative (it would virtualize).  Well-formed fmaxp / fminp is
; covered by vmp-aarch64-neon-fminmax-pairwise-semantic.ll.
; Well-formed smaxv / sminv is covered by
; vmp-aarch64-neon-int-across-semantic.ll.  Generic llvm.smax /
; llvm.smin already virtualize as integer-vector min/max.

define <2 x i64> @unsupported_v2i64(<2 x i64> %a, <2 x i64> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.aarch64.neon.smaxp.v2i64(<2 x i64> %a, <2 x i64> %b)
  ret <2 x i64> %r
}

define <1 x i32> @unsupported_v1i32(<1 x i32> %a, <1 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <1 x i32> @llvm.aarch64.neon.smaxp.v1i32(<1 x i32> %a, <1 x i32> %b)
  ret <1 x i32> %r
}

define <4 x i8> @unsupported_v4i8(<4 x i8> %a, <4 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i8> @llvm.aarch64.neon.sminp.v4i8(<4 x i8> %a, <4 x i8> %b)
  ret <4 x i8> %r
}

define <8 x i32> @unsupported_v8i32(<8 x i32> %a, <8 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i32> @llvm.aarch64.neon.umaxp.v8i32(<8 x i32> %a, <8 x i32> %b)
  ret <8 x i32> %r
}

define <8 x i1> @unsupported_i1(<8 x i1> %a, <8 x i1> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i1> @llvm.aarch64.neon.uminp.v8i1(<8 x i1> %a, <8 x i1> %b)
  ret <8 x i1> %r
}

; Well-formed llvm.aarch64.neon.smax / smin / umax / umin is
; vmp-aarch64-neon-int-extrema-semantic.ll and must not stay
; here as a negative (it would virtualize).

define <vscale x 16 x i8> @unsupported_sve_smaxp(<vscale x 16 x i1> %pg, <vscale x 16 x i8> %a, <vscale x 16 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 16 x i8> @llvm.aarch64.sve.smaxp.nxv16i8(<vscale x 16 x i1> %pg, <vscale x 16 x i8> %a, <vscale x 16 x i8> %b)
  ret <vscale x 16 x i8> %r
}

define <8 x i8> @unsupported_fastcc(<8 x i8> %a, <8 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc <8 x i8> @llvm.aarch64.neon.smaxp.v8i8(<8 x i8> %a, <8 x i8> %b)
  ret <8 x i8> %r
}


define <8 x i8> @unsupported_musttail(<8 x i8> %a, <8 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call <8 x i8> @llvm.aarch64.neon.smaxp.v8i8(<8 x i8> %a, <8 x i8> %b)
  ret <8 x i8> %r
}

define <8 x i8> @unsupported_bundle(<8 x i8> %a, <8 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i8> @llvm.aarch64.neon.smaxp.v8i8(<8 x i8> %a, <8 x i8> %b) [ "deopt"(i32 0) ]
  ret <8 x i8> %r
}

define <8 x i8> @unsupported_noreturn(<8 x i8> %a, <8 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i8> @llvm.aarch64.neon.smaxp.v8i8(<8 x i8> %a, <8 x i8> %b) noreturn
  ret <8 x i8> %r
}

define <8 x i8> @unsupported_returns_twice(<8 x i8> %a, <8 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i8> @llvm.aarch64.neon.smaxp.v8i8(<8 x i8> %a, <8 x i8> %b) returns_twice
  ret <8 x i8> %r
}

define void @unsupported_sret(ptr sret(i32) %p, ptr byval(i32) %q) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @ext_sret_byval(ptr sret(i32) %p, ptr byval(i32) %q)
  ret void
}

define i32 @main() {
entry:
  %a8 = load volatile <8 x i8>, ptr @sink_v8i8, align 8
  %b8 = load volatile <8 x i8>, ptr @sink_v8i8, align 8
  %r0 = call <8 x i8> @protected_smaxp_v8i8(<8 x i8> %a8, <8 x i8> %b8)
  store volatile <8 x i8> %r0, ptr @sink_v8i8, align 8
  %a16 = load volatile <16 x i8>, ptr @sink_v16i8, align 16
  %b16 = load volatile <16 x i8>, ptr @sink_v16i8, align 16
  %r1 = call <16 x i8> @protected_smaxp_v16i8(<16 x i8> %a16, <16 x i8> %b16)
  store volatile <16 x i8> %r1, ptr @sink_v16i8, align 16
  %a4s = load volatile <4 x i32>, ptr @sink_v4i32, align 16
  %b4s = load volatile <4 x i32>, ptr @sink_v4i32, align 16
  %r2 = call <4 x i32> @protected_smaxp_v4i32(<4 x i32> %a4s, <4 x i32> %b4s)
  store volatile <4 x i32> %r2, ptr @sink_v4i32, align 16
  %a4h = load volatile <4 x i16>, ptr @sink_v4i16, align 8
  %b4h = load volatile <4 x i16>, ptr @sink_v4i16, align 8
  %r3 = call <4 x i16> @protected_umaxp_v4i16(<4 x i16> %a4h, <4 x i16> %b4h)
  store volatile <4 x i16> %r3, ptr @sink_v4i16, align 8
  %a8h = load volatile <8 x i16>, ptr @sink_v8i16, align 16
  %b8h = load volatile <8 x i16>, ptr @sink_v8i16, align 16
  %r4 = call <8 x i16> @protected_umaxp_v8i16(<8 x i16> %a8h, <8 x i16> %b8h)
  store volatile <8 x i16> %r4, ptr @sink_v8i16, align 16
  %a2s = load volatile <2 x i32>, ptr @sink_v2i32, align 8
  %b2s = load volatile <2 x i32>, ptr @sink_v2i32, align 8
  %r5 = call <2 x i32> @protected_sminp_v2i32(<2 x i32> %a2s, <2 x i32> %b2s)
  store volatile <2 x i32> %r5, ptr @sink_v2i32, align 8
  %r6 = call <4 x i32> @protected_sminp_v4i32(<4 x i32> %a4s, <4 x i32> %b4s)
  store volatile <4 x i32> %r6, ptr @sink_v4i32, align 16
  %r7 = call <8 x i8> @protected_uminp_v8i8(<8 x i8> %a8, <8 x i8> %b8)
  store volatile <8 x i8> %r7, ptr @sink_v8i8, align 8
  %r8 = call <16 x i8> @protected_uminp_v16i8(<16 x i8> %a16, <16 x i8> %b16)
  store volatile <16 x i8> %r8, ptr @sink_v16i8, align 16
  %r9 = call <4 x i16> @protected_uminp_v4i16(<4 x i16> %a4h, <4 x i16> %b4h)
  store volatile <4 x i16> %r9, ptr @sink_v4i16, align 8
  ret i32 0
}

; SKIP-DAG: Skipping VMP on unsupported_v2i64: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_v1i32: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_v4i8: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_v8i32: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_i1: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_sve_smaxp: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_noreturn: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_returns_twice: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_sret: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_smaxp_v8i8:
; SKIP-NOT: Skipping VMP on protected_smaxp_v16i8:
; SKIP-NOT: Skipping VMP on protected_smaxp_v4i32:
; SKIP-NOT: Skipping VMP on protected_umaxp_v4i16:
; SKIP-NOT: Skipping VMP on protected_umaxp_v8i16:
; SKIP-NOT: Skipping VMP on protected_sminp_v2i32:
; SKIP-NOT: Skipping VMP on protected_sminp_v4i32:
; SKIP-NOT: Skipping VMP on protected_uminp_v8i8:
; SKIP-NOT: Skipping VMP on protected_uminp_v16i8:
; SKIP-NOT: Skipping VMP on protected_uminp_v4i16:

; VIRT: define <8 x i8> @protected_smaxp_v8i8({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x i8> @llvm.aarch64.neon.smaxp.v8i8(
; VIRT: define <16 x i8> @protected_smaxp_v16i8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <4 x i32> @protected_smaxp_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <4 x i16> @protected_umaxp_v4i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i16> @llvm.aarch64.neon.umaxp.v4i16(
; VIRT: define <8 x i16> @protected_umaxp_v8i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <2 x i32> @protected_sminp_v2i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i32> @llvm.aarch64.neon.sminp.v2i32(
; VIRT: define <4 x i32> @protected_sminp_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <8 x i8> @protected_uminp_v8i8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x i8> @llvm.aarch64.neon.uminp.v8i8(
; VIRT: define <16 x i8> @protected_uminp_v16i8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <4 x i16> @protected_uminp_v4i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define {{.*}} @unsupported_v2i64({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; AARCH64-ASM: {{^[[:space:]]*}}smaxp{{[ \t]}}
; AARCH64-ASM: {{^[[:space:]]*}}umaxp{{[ \t]}}
; AARCH64-ASM: {{^[[:space:]]*}}sminp{{[ \t]}}
; AARCH64-ASM: {{^[[:space:]]*}}uminp{{[ \t]}}
; HOST: Skipping VMP: only AArch64 targets are supported
