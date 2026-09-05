; Restricted AArch64 crypto SM4 via CallDescriptor / vector VRegs:
;   llvm.aarch64.crypto.sm4e / sm4ekey
;     Crypto_SM4_2Vector: <4 x i32>(<4 x i32>, <4 x i32>)
;     ISel SM4E / SM4ENCKEY under HasSM4 / FEAT_SM4
; Last-token function +sm4 required; missing or final -sm4,
; +sha2, and +crypto do not count.  Command-line -mattr is never
; consulted for eligibility.  Exact C non-vararg.  Ordinary tail accepted and replayed as non-tail; see vmp-direct-call-tail-eligibility-semantic.ll.  AES / SHA / SVE stay out.
; Well-formed SM3 is vmp-aarch64-crypto-sm3-semantic.ll.
; No new opcode.  These IDs are non-overloaded; other
; widths / half / bfloat are verifier-illegal, not IR negatives.
;
; Host cannot select these AArch64 intrinsics; no lli.
; FileCheck + AArch64 llc/readobj/asm (-mattr=+sm4).  O0/O2 x 97/7.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.ll -o %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+sm4 -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+sm4 %t.o0.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.ll -o %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+sm4 -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+sm4 %t.o2.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.s7.ll -o %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+sm4 -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+sm4 %t.o0.s7.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.s7.ll -o %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+sm4 -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+sm4 %t.o2.s7.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %s | opt -S -verify-each -aesSeed=97 -passes='default<O0>' - 2>&1 | FileCheck %s --check-prefix=HOST

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare <4 x i32> @llvm.aarch64.crypto.sm4e(<4 x i32>, <4 x i32>)
declare <4 x i32> @llvm.aarch64.crypto.sm4ekey(<4 x i32>, <4 x i32>)
declare <vscale x 4 x i32> @llvm.aarch64.sve.sm4e(<vscale x 4 x i32>, <vscale x 4 x i32>)

@sink_v4i32 = global <4 x i32> zeroinitializer, align 16

define <4 x i32> @protected_sm4e(<4 x i32> %a, <4 x i32> %b) noinline optnone "target-features"="+sm4" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.crypto.sm4e(<4 x i32> %a, <4 x i32> %b)
  ret <4 x i32> %r
}

define <4 x i32> @protected_sm4ekey(<4 x i32> %a, <4 x i32> %b) noinline optnone "target-features"="+sm4" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.crypto.sm4ekey(<4 x i32> %a, <4 x i32> %b)
  ret <4 x i32> %r
}

define <4 x i32> @protected_sm4e_last_sm4(<4 x i32> %a, <4 x i32> %b) noinline optnone "target-features"="+neon,+crc,+sm4" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.crypto.sm4e(<4 x i32> %a, <4 x i32> %b)
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_no_sm4(<4 x i32> %a, <4 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.crypto.sm4e(<4 x i32> %a, <4 x i32> %b)
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_sm4_disabled(<4 x i32> %a, <4 x i32> %b) noinline optnone "target-features"="+sm4,-sm4" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.crypto.sm4e(<4 x i32> %a, <4 x i32> %b)
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_sha2_only(<4 x i32> %a, <4 x i32> %b) noinline optnone "target-features"="+sha2" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.crypto.sm4e(<4 x i32> %a, <4 x i32> %b)
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_crypto_only(<4 x i32> %a, <4 x i32> %b) noinline optnone "target-features"="+crypto" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.crypto.sm4e(<4 x i32> %a, <4 x i32> %b)
  ret <4 x i32> %r
}

; Well-formed AES / SHA-1 / SHA-256 are independent surfaces and
; must not stay here with their last-token features (they would
; virtualize).

; Well-formed llvm.aarch64.crypto.sm3ss1 is covered by
; vmp-aarch64-crypto-sm3-semantic.ll and must not stay here with
; last-token +sm4 (it would virtualize).

define <vscale x 4 x i32> @unsupported_sve_sm4e(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b) noinline optnone "target-features"="+sm4" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.aarch64.sve.sm4e(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b)
  ret <vscale x 4 x i32> %r
}

define <4 x i32> @unsupported_fastcc(<4 x i32> %a, <4 x i32> %b) noinline optnone "target-features"="+sm4" {
entry:
  call void @hikari_vmp()
  %r = call fastcc <4 x i32> @llvm.aarch64.crypto.sm4e(<4 x i32> %a, <4 x i32> %b)
  ret <4 x i32> %r
}


define <4 x i32> @unsupported_musttail(<4 x i32> %a, <4 x i32> %b) noinline optnone "target-features"="+sm4" {
entry:
  call void @hikari_vmp()
  %r = musttail call <4 x i32> @llvm.aarch64.crypto.sm4e(<4 x i32> %a, <4 x i32> %b)
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_bundle(<4 x i32> %a, <4 x i32> %b) noinline optnone "target-features"="+sm4" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.crypto.sm4e(<4 x i32> %a, <4 x i32> %b) [ "deopt"(i32 0) ]
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_noreturn(<4 x i32> %a, <4 x i32> %b) noinline optnone "target-features"="+sm4" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.crypto.sm4e(<4 x i32> %a, <4 x i32> %b) noreturn
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_returns_twice(<4 x i32> %a, <4 x i32> %b) noinline optnone "target-features"="+sm4" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.crypto.sm4e(<4 x i32> %a, <4 x i32> %b) returns_twice
  ret <4 x i32> %r
}

define i32 @main() {
entry:
  %v = load volatile <4 x i32>, ptr @sink_v4i32, align 16
  %r0 = call <4 x i32> @protected_sm4e(<4 x i32> %v, <4 x i32> %v)
  store volatile <4 x i32> %r0, ptr @sink_v4i32, align 16
  %r1 = call <4 x i32> @protected_sm4ekey(<4 x i32> %v, <4 x i32> %v)
  store volatile <4 x i32> %r1, ptr @sink_v4i32, align 16
  %r2 = call <4 x i32> @protected_sm4e_last_sm4(<4 x i32> %v, <4 x i32> %v)
  store volatile <4 x i32> %r2, ptr @sink_v4i32, align 16
  ret i32 0
}

; SKIP-DAG: Skipping VMP on unsupported_no_sm4: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_sm4_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_sha2_only: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_crypto_only: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_sve_sm4e: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_noreturn: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_returns_twice: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_sm4e:
; SKIP-NOT: Skipping VMP on protected_sm4ekey:
; SKIP-NOT: Skipping VMP on protected_sm4e_last_sm4:

; VIRT: define <4 x i32> @protected_sm4e({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.aarch64.crypto.sm4e(
; VIRT: define <4 x i32> @protected_sm4ekey({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.aarch64.crypto.sm4ekey(
; VIRT: define <4 x i32> @protected_sm4e_last_sm4({{.*}} #[[LAST:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.aarch64.crypto.sm4e(
; VIRT: define {{.*}} @unsupported_no_sm4({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT: attributes #[[LAST]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; AARCH64-ASM: {{^[[:space:]]*}}sm4e{{[ \t]}}
; AARCH64-ASM: {{^[[:space:]]*}}sm4ekey{{[ \t]}}
; HOST: Skipping VMP: only AArch64 targets are supported
