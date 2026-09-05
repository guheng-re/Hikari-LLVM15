; Restricted AArch64 crypto SHA-256 via CallDescriptor / vector VRegs:
;   llvm.aarch64.crypto.sha256h / sha256h2
;     Crypto_SHA_8Hash4Schedule: three <4 x i32>
;     ISel SHATiedInstQQV sha256h / sha256h2
;   llvm.aarch64.crypto.sha256su0
;     Crypto_SHA_8Schedule: two <4 x i32>
;     ISel SHATiedInstVV sha256su0
;   llvm.aarch64.crypto.sha256su1
;     Crypto_SHA_12Schedule: three <4 x i32>
;     ISel SHATiedInstVVV sha256su1
; All four under HasSHA2 / FEAT_SHA1+SHA256.  Last-token function
; +sha2 required; missing or final -sha2, +sha3, and +crypto do
; not count.  Command-line -mattr is never consulted for
; eligibility.  Exact C non-vararg.  Ordinary tail accepted and replayed as non-tail; see vmp-direct-call-tail-eligibility-semantic.ll.  SHA-1 / AES / SM4 / SVE stay out.
; Well-formed SHA-512 is vmp-aarch64-crypto-sha512-semantic.ll.
; No new opcode.  These IDs are non-overloaded; other
; widths / half / bfloat are verifier-illegal, not IR negatives.
;
; Host cannot select these AArch64 intrinsics; no lli.
; FileCheck + AArch64 llc/readobj/asm (-mattr=+sha2).  O0/O2 x 97/7.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.ll -o %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+sha2 -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+sha2 %t.o0.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.ll -o %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+sha2 -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+sha2 %t.o2.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.s7.ll -o %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+sha2 -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+sha2 %t.o0.s7.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.s7.ll -o %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+sha2 -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+sha2 %t.o2.s7.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %s | opt -S -verify-each -aesSeed=97 -passes='default<O0>' - 2>&1 | FileCheck %s --check-prefix=HOST

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare <4 x i32> @llvm.aarch64.crypto.sha256h(<4 x i32>, <4 x i32>, <4 x i32>)
declare <4 x i32> @llvm.aarch64.crypto.sha256h2(<4 x i32>, <4 x i32>, <4 x i32>)
declare <4 x i32> @llvm.aarch64.crypto.sha256su0(<4 x i32>, <4 x i32>)
declare <4 x i32> @llvm.aarch64.crypto.sha256su1(<4 x i32>, <4 x i32>, <4 x i32>)
declare <vscale x 16 x i8> @llvm.aarch64.sve.aese(<vscale x 16 x i8>, <vscale x 16 x i8>)

@sink_v4i32 = global <4 x i32> zeroinitializer, align 16

define <4 x i32> @protected_sha256h(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c) noinline optnone "target-features"="+sha2" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.crypto.sha256h(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c)
  ret <4 x i32> %r
}

define <4 x i32> @protected_sha256h2(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c) noinline optnone "target-features"="+sha2" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.crypto.sha256h2(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c)
  ret <4 x i32> %r
}

define <4 x i32> @protected_sha256su0(<4 x i32> %a, <4 x i32> %b) noinline optnone "target-features"="+sha2" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.crypto.sha256su0(<4 x i32> %a, <4 x i32> %b)
  ret <4 x i32> %r
}

define <4 x i32> @protected_sha256su1(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c) noinline optnone "target-features"="+sha2" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.crypto.sha256su1(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c)
  ret <4 x i32> %r
}

define <4 x i32> @protected_sha256h_last_sha2(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c) noinline optnone "target-features"="+neon,+crc,+sha2" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.crypto.sha256h(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c)
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_no_sha2(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.crypto.sha256h(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c)
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_sha2_disabled(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c) noinline optnone "target-features"="+sha2,-sha2" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.crypto.sha256h(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c)
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_sha3_only(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c) noinline optnone "target-features"="+sha3" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.crypto.sha256h(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c)
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_crypto_only(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c) noinline optnone "target-features"="+crypto" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.crypto.sha256h(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c)
  ret <4 x i32> %r
}

; Well-formed llvm.aarch64.crypto.sha1h / sha1c is covered by
; vmp-aarch64-crypto-sha1-semantic.ll and must not stay here with
; last-token +sha2 (it would virtualize).

; Well-formed llvm.aarch64.crypto.aese is covered by
; vmp-aarch64-crypto-aes-semantic.ll and must not stay here with
; last-token +aes (it would virtualize).

; Well-formed llvm.aarch64.crypto.sha512h is covered by
; vmp-aarch64-crypto-sha512-semantic.ll.  Missing +sha3 would skip
; as unsupported target feature, not stay here as a SHA-256 negative.

; Well-formed llvm.aarch64.crypto.sm4e is covered by
; vmp-aarch64-crypto-sm4-semantic.ll.  Missing +sm4 would skip as
; unsupported target feature, not stay here as a SHA-256 negative.

define <vscale x 16 x i8> @unsupported_sve_aese(<vscale x 16 x i8> %a, <vscale x 16 x i8> %b) noinline optnone "target-features"="+sha2" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 16 x i8> @llvm.aarch64.sve.aese(<vscale x 16 x i8> %a, <vscale x 16 x i8> %b)
  ret <vscale x 16 x i8> %r
}

define <4 x i32> @unsupported_fastcc(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c) noinline optnone "target-features"="+sha2" {
entry:
  call void @hikari_vmp()
  %r = call fastcc <4 x i32> @llvm.aarch64.crypto.sha256h(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c)
  ret <4 x i32> %r
}


define <4 x i32> @unsupported_musttail(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c) noinline optnone "target-features"="+sha2" {
entry:
  call void @hikari_vmp()
  %r = musttail call <4 x i32> @llvm.aarch64.crypto.sha256h(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c)
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_bundle(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c) noinline optnone "target-features"="+sha2" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.crypto.sha256h(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c) [ "deopt"(i32 0) ]
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_noreturn(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c) noinline optnone "target-features"="+sha2" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.crypto.sha256h(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c) noreturn
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_returns_twice(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c) noinline optnone "target-features"="+sha2" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.crypto.sha256h(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c) returns_twice
  ret <4 x i32> %r
}

define i32 @main() {
entry:
  %v = load volatile <4 x i32>, ptr @sink_v4i32, align 16
  %r0 = call <4 x i32> @protected_sha256h(<4 x i32> %v, <4 x i32> %v, <4 x i32> %v)
  store volatile <4 x i32> %r0, ptr @sink_v4i32, align 16
  %r1 = call <4 x i32> @protected_sha256h2(<4 x i32> %v, <4 x i32> %v, <4 x i32> %v)
  store volatile <4 x i32> %r1, ptr @sink_v4i32, align 16
  %r2 = call <4 x i32> @protected_sha256su0(<4 x i32> %v, <4 x i32> %v)
  store volatile <4 x i32> %r2, ptr @sink_v4i32, align 16
  %r3 = call <4 x i32> @protected_sha256su1(<4 x i32> %v, <4 x i32> %v, <4 x i32> %v)
  store volatile <4 x i32> %r3, ptr @sink_v4i32, align 16
  %r4 = call <4 x i32> @protected_sha256h_last_sha2(<4 x i32> %v, <4 x i32> %v, <4 x i32> %v)
  store volatile <4 x i32> %r4, ptr @sink_v4i32, align 16
  ret i32 0
}

; SKIP-DAG: Skipping VMP on unsupported_no_sha2: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_sha2_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_sha3_only: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_crypto_only: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_sve_aese: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_noreturn: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_returns_twice: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_sha256h:
; SKIP-NOT: Skipping VMP on protected_sha256h2:
; SKIP-NOT: Skipping VMP on protected_sha256su0:
; SKIP-NOT: Skipping VMP on protected_sha256su1:
; SKIP-NOT: Skipping VMP on protected_sha256h_last_sha2:

; VIRT: define <4 x i32> @protected_sha256h({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.aarch64.crypto.sha256h(
; VIRT: define <4 x i32> @protected_sha256h2({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.aarch64.crypto.sha256h2(
; VIRT: define <4 x i32> @protected_sha256su0({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.aarch64.crypto.sha256su0(
; VIRT: define <4 x i32> @protected_sha256su1({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.aarch64.crypto.sha256su1(
; VIRT: define <4 x i32> @protected_sha256h_last_sha2({{.*}} #[[LAST:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.aarch64.crypto.sha256h(
; VIRT: define {{.*}} @unsupported_no_sha2({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT: attributes #[[LAST]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; AARCH64-ASM: {{^[[:space:]]*}}sha256h{{[ \t]}}
; AARCH64-ASM: {{^[[:space:]]*}}sha256h2{{[ \t]}}
; AARCH64-ASM: {{^[[:space:]]*}}sha256su0{{[ \t]}}
; AARCH64-ASM: {{^[[:space:]]*}}sha256su1{{[ \t]}}
; HOST: Skipping VMP: only AArch64 targets are supported
