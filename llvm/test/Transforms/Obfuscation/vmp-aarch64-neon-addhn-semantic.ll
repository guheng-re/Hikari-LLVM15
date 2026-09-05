; Restricted AArch64 NEON narrow-high add/sub via CallDescriptor /
; vector VRegs:
;   llvm.aarch64.neon.addhn / subhn / raddhn / rsubhn
;     AdvSIMD_2VectorArg_Narrow: anyvector (ext, ext)
;     ISel SIMDNarrowThreeVectorBHS low-half, baseline HasNEON:
;       <8 x i8>(<8 x i16>, <8 x i16>) -> addhn/subhn/raddhn/rsubhn .8b
;       <4 x i16>(<4 x i32>, <4 x i32>) -> ... .4h
;       <2 x i32>(<2 x i64>, <2 x i64>) -> ... .2s
; High-half addhn2 is concat_vectors of two of these calls, not a
; second IR ID.  i8 sources, i64 results, v4i8, 256-bit args, SVE
; addhnb/t, widening/sat, and non-C stay out.  Exact C non-vararg.
; Ordinary tail accepted and replayed as non-tail; see vmp-direct-call-tail-eligibility-semantic.ll.  No last-token gate.
; No new opcode.
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
declare <8 x i8> @llvm.aarch64.neon.addhn.v8i8(<8 x i16>, <8 x i16>)
declare <4 x i16> @llvm.aarch64.neon.addhn.v4i16(<4 x i32>, <4 x i32>)
declare <2 x i32> @llvm.aarch64.neon.addhn.v2i32(<2 x i64>, <2 x i64>)
declare <8 x i8> @llvm.aarch64.neon.subhn.v8i8(<8 x i16>, <8 x i16>)
declare <4 x i16> @llvm.aarch64.neon.subhn.v4i16(<4 x i32>, <4 x i32>)
declare <2 x i32> @llvm.aarch64.neon.subhn.v2i32(<2 x i64>, <2 x i64>)
declare <8 x i8> @llvm.aarch64.neon.raddhn.v8i8(<8 x i16>, <8 x i16>)
declare <4 x i16> @llvm.aarch64.neon.raddhn.v4i16(<4 x i32>, <4 x i32>)
declare <2 x i32> @llvm.aarch64.neon.raddhn.v2i32(<2 x i64>, <2 x i64>)
declare <8 x i8> @llvm.aarch64.neon.rsubhn.v8i8(<8 x i16>, <8 x i16>)
declare <4 x i16> @llvm.aarch64.neon.rsubhn.v4i16(<4 x i32>, <4 x i32>)
declare <2 x i32> @llvm.aarch64.neon.rsubhn.v2i32(<2 x i64>, <2 x i64>)
declare <16 x i8> @llvm.aarch64.neon.addhn.v16i8(<16 x i16>, <16 x i16>)
declare <4 x i8> @llvm.aarch64.neon.addhn.v4i8(<4 x i16>, <4 x i16>)
declare <vscale x 16 x i8> @llvm.aarch64.sve.addhnb.nxv8i16(<vscale x 8 x i16>, <vscale x 8 x i16>)

@sink_v8i8 = global <8 x i8> zeroinitializer, align 8
@sink_v8i16 = global <8 x i16> zeroinitializer, align 16
@sink_v4i16 = global <4 x i16> zeroinitializer, align 8
@sink_v4i32 = global <4 x i32> zeroinitializer, align 16
@sink_v2i32 = global <2 x i32> zeroinitializer, align 8
@sink_v2i64 = global <2 x i64> zeroinitializer, align 16

define <8 x i8> @protected_addhn_v8(<8 x i16> %a, <8 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i8> @llvm.aarch64.neon.addhn.v8i8(<8 x i16> %a, <8 x i16> %b)
  ret <8 x i8> %r
}

define <4 x i16> @protected_addhn_v4(<4 x i32> %a, <4 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i16> @llvm.aarch64.neon.addhn.v4i16(<4 x i32> %a, <4 x i32> %b)
  ret <4 x i16> %r
}

define <2 x i32> @protected_addhn_v2(<2 x i64> %a, <2 x i64> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i32> @llvm.aarch64.neon.addhn.v2i32(<2 x i64> %a, <2 x i64> %b)
  ret <2 x i32> %r
}

define <8 x i8> @protected_subhn_v8(<8 x i16> %a, <8 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i8> @llvm.aarch64.neon.subhn.v8i8(<8 x i16> %a, <8 x i16> %b)
  ret <8 x i8> %r
}

define <4 x i16> @protected_subhn_v4(<4 x i32> %a, <4 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i16> @llvm.aarch64.neon.subhn.v4i16(<4 x i32> %a, <4 x i32> %b)
  ret <4 x i16> %r
}

define <2 x i32> @protected_subhn_v2(<2 x i64> %a, <2 x i64> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i32> @llvm.aarch64.neon.subhn.v2i32(<2 x i64> %a, <2 x i64> %b)
  ret <2 x i32> %r
}

define <8 x i8> @protected_raddhn_v8(<8 x i16> %a, <8 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i8> @llvm.aarch64.neon.raddhn.v8i8(<8 x i16> %a, <8 x i16> %b)
  ret <8 x i8> %r
}

define <4 x i16> @protected_raddhn_v4(<4 x i32> %a, <4 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i16> @llvm.aarch64.neon.raddhn.v4i16(<4 x i32> %a, <4 x i32> %b)
  ret <4 x i16> %r
}

define <2 x i32> @protected_raddhn_v2(<2 x i64> %a, <2 x i64> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i32> @llvm.aarch64.neon.raddhn.v2i32(<2 x i64> %a, <2 x i64> %b)
  ret <2 x i32> %r
}

define <8 x i8> @protected_rsubhn_v8(<8 x i16> %a, <8 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i8> @llvm.aarch64.neon.rsubhn.v8i8(<8 x i16> %a, <8 x i16> %b)
  ret <8 x i8> %r
}

define <4 x i16> @protected_rsubhn_v4(<4 x i32> %a, <4 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i16> @llvm.aarch64.neon.rsubhn.v4i16(<4 x i32> %a, <4 x i32> %b)
  ret <4 x i16> %r
}

define <2 x i32> @protected_rsubhn_v2(<2 x i64> %a, <2 x i64> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i32> @llvm.aarch64.neon.rsubhn.v2i32(<2 x i64> %a, <2 x i64> %b)
  ret <2 x i32> %r
}

define <16 x i8> @unsupported_wide_v16(<16 x i16> %a, <16 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <16 x i8> @llvm.aarch64.neon.addhn.v16i8(<16 x i16> %a, <16 x i16> %b)
  ret <16 x i8> %r
}

define <4 x i8> @unsupported_v4i8(<4 x i16> %a, <4 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i8> @llvm.aarch64.neon.addhn.v4i8(<4 x i16> %a, <4 x i16> %b)
  ret <4 x i8> %r
}

; Well-formed llvm.aarch64.neon.saddlp / uaddlp is covered by
; vmp-aarch64-neon-saddlp-semantic.ll and must not stay here as a
; negative (it would virtualize).

define <vscale x 16 x i8> @unsupported_sve(<vscale x 8 x i16> %a, <vscale x 8 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 16 x i8> @llvm.aarch64.sve.addhnb.nxv8i16(<vscale x 8 x i16> %a, <vscale x 8 x i16> %b)
  ret <vscale x 16 x i8> %r
}

define <8 x i8> @unsupported_fastcc(<8 x i16> %a, <8 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc <8 x i8> @llvm.aarch64.neon.addhn.v8i8(<8 x i16> %a, <8 x i16> %b)
  ret <8 x i8> %r
}


define <8 x i8> @unsupported_musttail(<8 x i16> %a, <8 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call <8 x i8> @llvm.aarch64.neon.addhn.v8i8(<8 x i16> %a, <8 x i16> %b)
  ret <8 x i8> %r
}

define <8 x i8> @unsupported_bundle(<8 x i16> %a, <8 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i8> @llvm.aarch64.neon.addhn.v8i8(<8 x i16> %a, <8 x i16> %b) [ "deopt"(i32 0) ]
  ret <8 x i8> %r
}

define i32 @main() {
entry:
  %a8 = load volatile <8 x i16>, ptr @sink_v8i16, align 16
  %b8 = load volatile <8 x i16>, ptr @sink_v8i16, align 16
  %r0 = call <8 x i8> @protected_addhn_v8(<8 x i16> %a8, <8 x i16> %b8)
  store volatile <8 x i8> %r0, ptr @sink_v8i8, align 8
  %a4 = load volatile <4 x i32>, ptr @sink_v4i32, align 16
  %b4 = load volatile <4 x i32>, ptr @sink_v4i32, align 16
  %r1 = call <4 x i16> @protected_addhn_v4(<4 x i32> %a4, <4 x i32> %b4)
  store volatile <4 x i16> %r1, ptr @sink_v4i16, align 8
  %a2 = load volatile <2 x i64>, ptr @sink_v2i64, align 16
  %b2 = load volatile <2 x i64>, ptr @sink_v2i64, align 16
  %r2 = call <2 x i32> @protected_addhn_v2(<2 x i64> %a2, <2 x i64> %b2)
  store volatile <2 x i32> %r2, ptr @sink_v2i32, align 8
  %r3 = call <8 x i8> @protected_subhn_v8(<8 x i16> %a8, <8 x i16> %b8)
  store volatile <8 x i8> %r3, ptr @sink_v8i8, align 8
  %r4 = call <4 x i16> @protected_subhn_v4(<4 x i32> %a4, <4 x i32> %b4)
  store volatile <4 x i16> %r4, ptr @sink_v4i16, align 8
  %r5 = call <2 x i32> @protected_subhn_v2(<2 x i64> %a2, <2 x i64> %b2)
  store volatile <2 x i32> %r5, ptr @sink_v2i32, align 8
  %r6 = call <8 x i8> @protected_raddhn_v8(<8 x i16> %a8, <8 x i16> %b8)
  store volatile <8 x i8> %r6, ptr @sink_v8i8, align 8
  %r7 = call <4 x i16> @protected_raddhn_v4(<4 x i32> %a4, <4 x i32> %b4)
  store volatile <4 x i16> %r7, ptr @sink_v4i16, align 8
  %r8 = call <2 x i32> @protected_raddhn_v2(<2 x i64> %a2, <2 x i64> %b2)
  store volatile <2 x i32> %r8, ptr @sink_v2i32, align 8
  %r9 = call <8 x i8> @protected_rsubhn_v8(<8 x i16> %a8, <8 x i16> %b8)
  store volatile <8 x i8> %r9, ptr @sink_v8i8, align 8
  %r10 = call <4 x i16> @protected_rsubhn_v4(<4 x i32> %a4, <4 x i32> %b4)
  store volatile <4 x i16> %r10, ptr @sink_v4i16, align 8
  %r11 = call <2 x i32> @protected_rsubhn_v2(<2 x i64> %a2, <2 x i64> %b2)
  store volatile <2 x i32> %r11, ptr @sink_v2i32, align 8
  ret i32 0
}

; SKIP-DAG: Skipping VMP on unsupported_wide_v16: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_v4i8: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_sve: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_addhn_v8:
; SKIP-NOT: Skipping VMP on protected_addhn_v4:
; SKIP-NOT: Skipping VMP on protected_addhn_v2:
; SKIP-NOT: Skipping VMP on protected_subhn_v8:
; SKIP-NOT: Skipping VMP on protected_subhn_v4:
; SKIP-NOT: Skipping VMP on protected_subhn_v2:
; SKIP-NOT: Skipping VMP on protected_raddhn_v8:
; SKIP-NOT: Skipping VMP on protected_raddhn_v4:
; SKIP-NOT: Skipping VMP on protected_raddhn_v2:
; SKIP-NOT: Skipping VMP on protected_rsubhn_v8:
; SKIP-NOT: Skipping VMP on protected_rsubhn_v4:
; SKIP-NOT: Skipping VMP on protected_rsubhn_v2:

; VIRT: define <8 x i8> @protected_addhn_v8({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x i8> @llvm.aarch64.neon.addhn.v8i8(
; VIRT: define <4 x i16> @protected_addhn_v4({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <2 x i32> @protected_addhn_v2({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <8 x i8> @protected_subhn_v8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x i8> @llvm.aarch64.neon.subhn.v8i8(
; VIRT: define <4 x i16> @protected_subhn_v4({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <2 x i32> @protected_subhn_v2({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <8 x i8> @protected_raddhn_v8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x i8> @llvm.aarch64.neon.raddhn.v8i8(
; VIRT: define <4 x i16> @protected_raddhn_v4({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <2 x i32> @protected_raddhn_v2({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <8 x i8> @protected_rsubhn_v8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x i8> @llvm.aarch64.neon.rsubhn.v8i8(
; VIRT: define <4 x i16> @protected_rsubhn_v4({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <2 x i32> @protected_rsubhn_v2({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define {{.*}} @unsupported_wide_v16({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; AARCH64-ASM: {{^[[:space:]]*}}addhn{{[ \t]}}
; AARCH64-ASM: {{^[[:space:]]*}}subhn{{[ \t]}}
; AARCH64-ASM: raddhn
; AARCH64-ASM: rsubhn
; HOST: Skipping VMP: only AArch64 targets are supported
