; Restricted AArch64 NEON polynomial-multiply long via CallDescriptor:
;   llvm.aarch64.neon.pmull.v8i16(<8 x i8>, <8 x i8>) -> <8 x i16>
;     ISel PMULLv8i8, baseline HasNEON / AdvSIMD
;   llvm.aarch64.neon.pmull64(i64, i64) -> <16 x i8>
;     ISel PMULLv1i64, last-token function +aes (HasAES / FEAT_AES)
; Exact C non-vararg ABI.  Ordinary tail accepted and replayed as
; non-tail; see vmp-direct-call-tail-eligibility-semantic.ll.  musttail / bundles / noreturn / complex ABI
; stay out.  smull/umull is vmp-aarch64-neon-smull-semantic.ll.
; SVE pmullb/t and other Long widths are not accepted.  Well-formed
; crypto aese is vmp-aarch64-crypto-aes-semantic.ll.
; Same-width pmul is vmp-aarch64-neon-pmul-semantic.ll.  No new opcode.
; Command-line -mattr
; is never consulted for eligibility.
;
; Host cannot select these AArch64 intrinsics; no lli.
; FileCheck + AArch64 llc/readobj/asm (pmull mnemonic).  O0/O2 x 97/7.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.ll -o %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+aes -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+aes %t.o0.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.ll -o %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+aes -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+aes %t.o2.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.s7.ll -o %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+aes -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+aes %t.o0.s7.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.s7.ll -o %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+aes -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+aes %t.o2.s7.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %s | opt -S -verify-each -aesSeed=97 -passes='default<O0>' - 2>&1 | FileCheck %s --check-prefix=HOST

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare <8 x i16> @llvm.aarch64.neon.pmull.v8i16(<8 x i8>, <8 x i8>)
declare <16 x i8> @llvm.aarch64.neon.pmull64(i64, i64)
declare <4 x i32> @llvm.aarch64.neon.pmull.v4i32(<4 x i16>, <4 x i16>)
declare <vscale x 2 x i64> @llvm.aarch64.sve.pmullb.pair.nxv2i64(<vscale x 2 x i64>, <vscale x 2 x i64>)

@sink_v8i8 = global <8 x i8> zeroinitializer, align 8
@sink_v8i16 = global <8 x i16> zeroinitializer, align 16
@sink_v16i8 = global <16 x i8> zeroinitializer, align 16

define <8 x i16> @protected_pmull_v8(<8 x i8> %a, <8 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i16> @llvm.aarch64.neon.pmull.v8i16(<8 x i8> %a, <8 x i8> %b)
  ret <8 x i16> %r
}

define <16 x i8> @protected_pmull64(i64 %a, i64 %b) noinline optnone "target-features"="+aes" {
entry:
  call void @hikari_vmp()
  %r = call <16 x i8> @llvm.aarch64.neon.pmull64(i64 %a, i64 %b)
  ret <16 x i8> %r
}

define <16 x i8> @protected_pmull64_last_aes(i64 %a, i64 %b) noinline optnone "target-features"="+neon,+crc,+aes" {
entry:
  call void @hikari_vmp()
  %r = call <16 x i8> @llvm.aarch64.neon.pmull64(i64 %a, i64 %b)
  ret <16 x i8> %r
}

; Well-formed llvm.aarch64.neon.smull / umull is covered by
; vmp-aarch64-neon-smull-semantic.ll and must not stay here as a
; negative (it would virtualize).

; Well-formed llvm.aarch64.neon.pmul.v8i8 / v16i8 is covered by
; vmp-aarch64-neon-pmul-semantic.ll and must not stay here as a
; negative (it would virtualize).

define <4 x i32> @unsupported_pmull_v4i32(<4 x i16> %a, <4 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.pmull.v4i32(<4 x i16> %a, <4 x i16> %b)
  ret <4 x i32> %r
}

; Well-formed llvm.aarch64.crypto.aese is covered by
; vmp-aarch64-crypto-aes-semantic.ll and must not stay here as a
; negative (it would virtualize when last-token +aes).

define <vscale x 2 x i64> @unsupported_sve_pmullb(<vscale x 2 x i64> %a, <vscale x 2 x i64> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 2 x i64> @llvm.aarch64.sve.pmullb.pair.nxv2i64(<vscale x 2 x i64> %a, <vscale x 2 x i64> %b)
  ret <vscale x 2 x i64> %r
}

define <8 x i16> @unsupported_pmull_fastcc(<8 x i8> %a, <8 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc <8 x i16> @llvm.aarch64.neon.pmull.v8i16(<8 x i8> %a, <8 x i8> %b)
  ret <8 x i16> %r
}


define <8 x i16> @unsupported_pmull_musttail(<8 x i8> %a, <8 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call <8 x i16> @llvm.aarch64.neon.pmull.v8i16(<8 x i8> %a, <8 x i8> %b)
  ret <8 x i16> %r
}

define <8 x i16> @unsupported_pmull_bundle(<8 x i8> %a, <8 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i16> @llvm.aarch64.neon.pmull.v8i16(<8 x i8> %a, <8 x i8> %b) [ "deopt"(i32 0) ]
  ret <8 x i16> %r
}

define <16 x i8> @unsupported_pmull64_no_aes(i64 %a, i64 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <16 x i8> @llvm.aarch64.neon.pmull64(i64 %a, i64 %b)
  ret <16 x i8> %r
}

define <16 x i8> @unsupported_pmull64_aes_disabled(i64 %a, i64 %b) noinline optnone "target-features"="+aes,-aes" {
entry:
  call void @hikari_vmp()
  %r = call <16 x i8> @llvm.aarch64.neon.pmull64(i64 %a, i64 %b)
  ret <16 x i8> %r
}

define <16 x i8> @unsupported_pmull64_aes2_only(i64 %a, i64 %b) noinline optnone "target-features"="+aes2" {
entry:
  call void @hikari_vmp()
  %r = call <16 x i8> @llvm.aarch64.neon.pmull64(i64 %a, i64 %b)
  ret <16 x i8> %r
}

define <16 x i8> @unsupported_pmull64_crypto_only(i64 %a, i64 %b) noinline optnone "target-features"="+crypto" {
entry:
  call void @hikari_vmp()
  %r = call <16 x i8> @llvm.aarch64.neon.pmull64(i64 %a, i64 %b)
  ret <16 x i8> %r
}

define i32 @main() {
entry:
  %za = load volatile <8 x i8>, ptr @sink_v8i8, align 8
  %zb = load volatile <8 x i8>, ptr @sink_v8i8, align 8
  %r0 = call <8 x i16> @protected_pmull_v8(<8 x i8> %za, <8 x i8> %zb)
  store volatile <8 x i16> %r0, ptr @sink_v8i16, align 16
  %r1 = call <16 x i8> @protected_pmull64(i64 1, i64 2)
  store volatile <16 x i8> %r1, ptr @sink_v16i8, align 16
  %r2 = call <16 x i8> @protected_pmull64_last_aes(i64 3, i64 4)
  store volatile <16 x i8> %r2, ptr @sink_v16i8, align 16
  ret i32 0
}

; SKIP-DAG: Skipping VMP on unsupported_pmull_v4i32: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_sve_pmullb: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_pmull_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_pmull_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_pmull_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_pmull64_no_aes: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_pmull64_aes_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_pmull64_aes2_only: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_pmull64_crypto_only: unsupported target feature
; SKIP-NOT: Skipping VMP on protected_pmull_v8:
; SKIP-NOT: Skipping VMP on protected_pmull64:
; SKIP-NOT: Skipping VMP on protected_pmull64_last_aes:

; VIRT: define <8 x i16> @protected_pmull_v8({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x i16> @llvm.aarch64.neon.pmull.v8i16(
; VIRT: define <16 x i8> @protected_pmull64({{.*}} #[[AES:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <16 x i8> @llvm.aarch64.neon.pmull64(
; VIRT: define <16 x i8> @protected_pmull64_last_aes({{.*}} #[[AES2:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <16 x i8> @llvm.aarch64.neon.pmull64(
; VIRT: define {{.*}} @unsupported_pmull_v4i32({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT: attributes #[[AES]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT: attributes #[[AES2]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; AARCH64-ASM: pmull
; HOST: Skipping VMP: only AArch64 targets are supported
