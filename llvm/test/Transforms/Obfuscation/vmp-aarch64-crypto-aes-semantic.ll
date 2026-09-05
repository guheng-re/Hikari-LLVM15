; Restricted AArch64 crypto AES via CallDescriptor / vector VRegs:
;   llvm.aarch64.crypto.aese / aesd
;     Crypto_AES_DataKey: <16 x i8>(<16 x i8>, <16 x i8>)
;   llvm.aarch64.crypto.aesmc / aesimc
;     Crypto_AES_Data: <16 x i8>(<16 x i8>)
; ISel AESTiedInst / AESInst, HasAES / FEAT_AES.  Last-token
; function +aes required; missing or final -aes, +aes2, and
; +crypto do not count.  Command-line -mattr is never consulted
; for eligibility.  Exact C non-vararg.  Ordinary tail accepted and replayed as non-tail; see vmp-direct-call-tail-eligibility-semantic.ll.  SHA-256 / SM4 / SVE stay out.  Well-formed
; SHA-1 is vmp-aarch64-crypto-sha1-semantic.ll.  No new opcode.
; These four IDs are non-overloaded v16i8; scalar / v8i8 / half /
; bfloat / 256-bit forms are verifier-illegal, not IR negatives.
;
; Host cannot select these AArch64 intrinsics; no lli.
; FileCheck + AArch64 llc/readobj/asm (-mattr=+aes).  O0/O2 x 97/7.
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
declare <16 x i8> @llvm.aarch64.crypto.aese(<16 x i8>, <16 x i8>)
declare <16 x i8> @llvm.aarch64.crypto.aesd(<16 x i8>, <16 x i8>)
declare <16 x i8> @llvm.aarch64.crypto.aesmc(<16 x i8>)
declare <16 x i8> @llvm.aarch64.crypto.aesimc(<16 x i8>)
declare <vscale x 16 x i8> @llvm.aarch64.sve.aese(<vscale x 16 x i8>, <vscale x 16 x i8>)

@sink_v16i8 = global <16 x i8> zeroinitializer, align 16

define <16 x i8> @protected_aese(<16 x i8> %d, <16 x i8> %k) noinline optnone "target-features"="+aes" {
entry:
  call void @hikari_vmp()
  %r = call <16 x i8> @llvm.aarch64.crypto.aese(<16 x i8> %d, <16 x i8> %k)
  ret <16 x i8> %r
}

define <16 x i8> @protected_aesd(<16 x i8> %d, <16 x i8> %k) noinline optnone "target-features"="+aes" {
entry:
  call void @hikari_vmp()
  %r = call <16 x i8> @llvm.aarch64.crypto.aesd(<16 x i8> %d, <16 x i8> %k)
  ret <16 x i8> %r
}

define <16 x i8> @protected_aesmc(<16 x i8> %d) noinline optnone "target-features"="+aes" {
entry:
  call void @hikari_vmp()
  %r = call <16 x i8> @llvm.aarch64.crypto.aesmc(<16 x i8> %d)
  ret <16 x i8> %r
}

define <16 x i8> @protected_aesimc(<16 x i8> %d) noinline optnone "target-features"="+aes" {
entry:
  call void @hikari_vmp()
  %r = call <16 x i8> @llvm.aarch64.crypto.aesimc(<16 x i8> %d)
  ret <16 x i8> %r
}

define <16 x i8> @protected_aese_last_aes(<16 x i8> %d, <16 x i8> %k) noinline optnone "target-features"="+neon,+crc,+aes" {
entry:
  call void @hikari_vmp()
  %r = call <16 x i8> @llvm.aarch64.crypto.aese(<16 x i8> %d, <16 x i8> %k)
  ret <16 x i8> %r
}

define <16 x i8> @unsupported_no_aes(<16 x i8> %d, <16 x i8> %k) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <16 x i8> @llvm.aarch64.crypto.aese(<16 x i8> %d, <16 x i8> %k)
  ret <16 x i8> %r
}

define <16 x i8> @unsupported_aes_disabled(<16 x i8> %d, <16 x i8> %k) noinline optnone "target-features"="+aes,-aes" {
entry:
  call void @hikari_vmp()
  %r = call <16 x i8> @llvm.aarch64.crypto.aese(<16 x i8> %d, <16 x i8> %k)
  ret <16 x i8> %r
}

define <16 x i8> @unsupported_aes2_only(<16 x i8> %d, <16 x i8> %k) noinline optnone "target-features"="+aes2" {
entry:
  call void @hikari_vmp()
  %r = call <16 x i8> @llvm.aarch64.crypto.aese(<16 x i8> %d, <16 x i8> %k)
  ret <16 x i8> %r
}

define <16 x i8> @unsupported_crypto_only(<16 x i8> %d, <16 x i8> %k) noinline optnone "target-features"="+crypto" {
entry:
  call void @hikari_vmp()
  %r = call <16 x i8> @llvm.aarch64.crypto.aese(<16 x i8> %d, <16 x i8> %k)
  ret <16 x i8> %r
}

; Well-formed llvm.aarch64.crypto.sha1h is covered by
; vmp-aarch64-crypto-sha1-semantic.ll.  Missing +sha2 would skip as
; unsupported target feature, not stay here as an AES negative.

; Well-formed llvm.aarch64.crypto.sm4e is covered by
; vmp-aarch64-crypto-sm4-semantic.ll.  Missing +sm4 would skip as
; unsupported target feature, not stay here as an AES negative.

define <vscale x 16 x i8> @unsupported_sve_aese(<vscale x 16 x i8> %a, <vscale x 16 x i8> %b) noinline optnone "target-features"="+aes" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 16 x i8> @llvm.aarch64.sve.aese(<vscale x 16 x i8> %a, <vscale x 16 x i8> %b)
  ret <vscale x 16 x i8> %r
}

define <16 x i8> @unsupported_fastcc(<16 x i8> %d, <16 x i8> %k) noinline optnone "target-features"="+aes" {
entry:
  call void @hikari_vmp()
  %r = call fastcc <16 x i8> @llvm.aarch64.crypto.aese(<16 x i8> %d, <16 x i8> %k)
  ret <16 x i8> %r
}


define <16 x i8> @unsupported_musttail(<16 x i8> %d, <16 x i8> %k) noinline optnone "target-features"="+aes" {
entry:
  call void @hikari_vmp()
  %r = musttail call <16 x i8> @llvm.aarch64.crypto.aese(<16 x i8> %d, <16 x i8> %k)
  ret <16 x i8> %r
}

define <16 x i8> @unsupported_bundle(<16 x i8> %d, <16 x i8> %k) noinline optnone "target-features"="+aes" {
entry:
  call void @hikari_vmp()
  %r = call <16 x i8> @llvm.aarch64.crypto.aese(<16 x i8> %d, <16 x i8> %k) [ "deopt"(i32 0) ]
  ret <16 x i8> %r
}

define <16 x i8> @unsupported_noreturn(<16 x i8> %d, <16 x i8> %k) noinline optnone "target-features"="+aes" {
entry:
  call void @hikari_vmp()
  %r = call <16 x i8> @llvm.aarch64.crypto.aese(<16 x i8> %d, <16 x i8> %k) noreturn
  ret <16 x i8> %r
}

define <16 x i8> @unsupported_returns_twice(<16 x i8> %d, <16 x i8> %k) noinline optnone "target-features"="+aes" {
entry:
  call void @hikari_vmp()
  %r = call <16 x i8> @llvm.aarch64.crypto.aese(<16 x i8> %d, <16 x i8> %k) returns_twice
  ret <16 x i8> %r
}

define i32 @main() {
entry:
  %d = load volatile <16 x i8>, ptr @sink_v16i8, align 16
  %k = load volatile <16 x i8>, ptr @sink_v16i8, align 16
  %r0 = call <16 x i8> @protected_aese(<16 x i8> %d, <16 x i8> %k)
  store volatile <16 x i8> %r0, ptr @sink_v16i8, align 16
  %r1 = call <16 x i8> @protected_aesd(<16 x i8> %d, <16 x i8> %k)
  store volatile <16 x i8> %r1, ptr @sink_v16i8, align 16
  %r2 = call <16 x i8> @protected_aesmc(<16 x i8> %d)
  store volatile <16 x i8> %r2, ptr @sink_v16i8, align 16
  %r3 = call <16 x i8> @protected_aesimc(<16 x i8> %d)
  store volatile <16 x i8> %r3, ptr @sink_v16i8, align 16
  %r4 = call <16 x i8> @protected_aese_last_aes(<16 x i8> %d, <16 x i8> %k)
  store volatile <16 x i8> %r4, ptr @sink_v16i8, align 16
  ret i32 0
}

; SKIP-DAG: Skipping VMP on unsupported_no_aes: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_aes_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_aes2_only: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_crypto_only: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_sve_aese: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_noreturn: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_returns_twice: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_aese:
; SKIP-NOT: Skipping VMP on protected_aesd:
; SKIP-NOT: Skipping VMP on protected_aesmc:
; SKIP-NOT: Skipping VMP on protected_aesimc:
; SKIP-NOT: Skipping VMP on protected_aese_last_aes:

; VIRT: define <16 x i8> @protected_aese({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <16 x i8> @llvm.aarch64.crypto.aese(
; VIRT: define <16 x i8> @protected_aesd({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <16 x i8> @llvm.aarch64.crypto.aesd(
; VIRT: define <16 x i8> @protected_aesmc({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <16 x i8> @llvm.aarch64.crypto.aesmc(
; VIRT: define <16 x i8> @protected_aesimc({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <16 x i8> @llvm.aarch64.crypto.aesimc(
; VIRT: define <16 x i8> @protected_aese_last_aes({{.*}} #[[LAST:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <16 x i8> @llvm.aarch64.crypto.aese(
; VIRT: define {{.*}} @unsupported_no_aes({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT: attributes #[[LAST]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized" }

; AARCH64: Arch: aarch64
; AARCH64-ASM: {{^[[:space:]]*}}aese{{[ \t]}}
; AARCH64-ASM: {{^[[:space:]]*}}aesd{{[ \t]}}
; AARCH64-ASM: {{^[[:space:]]*}}aesmc{{[ \t]}}
; AARCH64-ASM: {{^[[:space:]]*}}aesimc{{[ \t]}}
; HOST: Skipping VMP: only AArch64 targets are supported
