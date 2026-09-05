; Restricted AArch64 NEON element-wise polynomial multiply via
; CallDescriptor / vector VRegs only:
;   llvm.aarch64.neon.pmul.v8i8(<8 x i8>, <8 x i8>) -> <8 x i8>
;     ISel PMULv8i8, baseline HasNEON / AdvSIMD
;   llvm.aarch64.neon.pmul.v16i8(<16 x i8>, <16 x i8>) -> <16 x i8>
;     ISel PMULv16i8, baseline HasNEON / AdvSIMD
; Exact C non-vararg ABI.  Ordinary tail accepted and replayed as
; non-tail; see vmp-direct-call-tail-eligibility-semantic.ll.  musttail / bundles / noreturn / complex ABI
; stay out.  smull/umull/pmull (separate surfaces), saturating
; multiplies, float, SVE pmul, and other widths are not accepted.
; No +aes gate.  No new opcode.  Command-line -mattr is never used.
;
; Host cannot select these AArch64 intrinsics; no lli.
; FileCheck + AArch64 llc/readobj/asm (pmul mnemonic).  O0/O2 x 97/7.
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
declare <8 x i8> @llvm.aarch64.neon.pmul.v8i8(<8 x i8>, <8 x i8>)
declare <16 x i8> @llvm.aarch64.neon.pmul.v16i8(<16 x i8>, <16 x i8>)
declare <8 x i16> @llvm.aarch64.neon.pmul.v8i16(<8 x i16>, <8 x i16>)
declare <4 x i8> @llvm.aarch64.neon.pmul.v4i8(<4 x i8>, <4 x i8>)
declare <4 x i32> @llvm.aarch64.neon.pmul.v4i32(<4 x i32>, <4 x i32>)
declare <vscale x 16 x i8> @llvm.aarch64.sve.pmul.nxv16i8(<vscale x 16 x i8>, <vscale x 16 x i8>)

@sink8 = global <8 x i8> zeroinitializer, align 8
@sink16 = global <16 x i8> zeroinitializer, align 16

define <8 x i8> @protected_pmul_v8(<8 x i8> %a, <8 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i8> @llvm.aarch64.neon.pmul.v8i8(<8 x i8> %a, <8 x i8> %b)
  ret <8 x i8> %r
}

define <16 x i8> @protected_pmul_v16(<16 x i8> %a, <16 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <16 x i8> @llvm.aarch64.neon.pmul.v16i8(<16 x i8> %a, <16 x i8> %b)
  ret <16 x i8> %r
}

define <8 x i16> @unsupported_pmul_v8i16(<8 x i16> %a, <8 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i16> @llvm.aarch64.neon.pmul.v8i16(<8 x i16> %a, <8 x i16> %b)
  ret <8 x i16> %r
}

define <4 x i8> @unsupported_pmul_v4i8(<4 x i8> %a, <4 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i8> @llvm.aarch64.neon.pmul.v4i8(<4 x i8> %a, <4 x i8> %b)
  ret <4 x i8> %r
}

define <4 x i32> @unsupported_pmul_v4i32(<4 x i32> %a, <4 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.pmul.v4i32(<4 x i32> %a, <4 x i32> %b)
  ret <4 x i32> %r
}

; Well-formed llvm.aarch64.neon.smull / umull is covered by
; vmp-aarch64-neon-smull-semantic.ll and must not stay here as a
; negative (it would virtualize).

; Well-formed llvm.aarch64.neon.sqdmulh / sqrdmulh is covered by
; vmp-aarch64-neon-sqdmulh-semantic.ll and must not stay here as a
; negative (it would virtualize).

; Well-formed llvm.aarch64.crypto.aese is covered by
; vmp-aarch64-crypto-aes-semantic.ll.  Missing +aes would skip as
; unsupported target feature, not stay here as a pmul negative.

define <vscale x 16 x i8> @unsupported_sve_pmul(<vscale x 16 x i8> %a, <vscale x 16 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 16 x i8> @llvm.aarch64.sve.pmul.nxv16i8(<vscale x 16 x i8> %a, <vscale x 16 x i8> %b)
  ret <vscale x 16 x i8> %r
}

define <8 x i8> @unsupported_pmul_fastcc(<8 x i8> %a, <8 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc <8 x i8> @llvm.aarch64.neon.pmul.v8i8(<8 x i8> %a, <8 x i8> %b)
  ret <8 x i8> %r
}


define <8 x i8> @unsupported_pmul_musttail(<8 x i8> %a, <8 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call <8 x i8> @llvm.aarch64.neon.pmul.v8i8(<8 x i8> %a, <8 x i8> %b)
  ret <8 x i8> %r
}

define <8 x i8> @unsupported_pmul_bundle(<8 x i8> %a, <8 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i8> @llvm.aarch64.neon.pmul.v8i8(<8 x i8> %a, <8 x i8> %b) [ "deopt"(i32 0) ]
  ret <8 x i8> %r
}

define i32 @main() {
entry:
  %a8 = load volatile <8 x i8>, ptr @sink8, align 8
  %b8 = load volatile <8 x i8>, ptr @sink8, align 8
  %r0 = call <8 x i8> @protected_pmul_v8(<8 x i8> %a8, <8 x i8> %b8)
  store volatile <8 x i8> %r0, ptr @sink8, align 8
  %a16 = load volatile <16 x i8>, ptr @sink16, align 16
  %b16 = load volatile <16 x i8>, ptr @sink16, align 16
  %r1 = call <16 x i8> @protected_pmul_v16(<16 x i8> %a16, <16 x i8> %b16)
  store volatile <16 x i8> %r1, ptr @sink16, align 16
  ret i32 0
}

; SKIP-DAG: Skipping VMP on unsupported_pmul_v8i16: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_pmul_v4i8: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_pmul_v4i32: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_sve_pmul: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_pmul_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_pmul_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_pmul_bundle: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_pmul_v8:
; SKIP-NOT: Skipping VMP on protected_pmul_v16:

; VIRT: define <8 x i8> @protected_pmul_v8({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x i8> @llvm.aarch64.neon.pmul.v8i8(
; VIRT: define <16 x i8> @protected_pmul_v16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <16 x i8> @llvm.aarch64.neon.pmul.v16i8(
; VIRT: define {{.*}} @unsupported_pmul_v8i16({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; AARCH64-ASM: pmul{{[ \t]+}}v
; HOST: Skipping VMP: only AArch64 targets are supported
