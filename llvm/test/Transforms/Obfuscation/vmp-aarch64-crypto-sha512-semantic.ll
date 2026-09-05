; Restricted AArch64 crypto SHA-512 via CallDescriptor / vector VRegs:
;   llvm.aarch64.crypto.sha512h / sha512h2 / sha512su1
;     Crypto_SHA512_3Arg: three <2 x i64>
;     ISel SHA512H / SHA512H2 / SHA512SU1
;   llvm.aarch64.crypto.sha512su0
;     Crypto_SHA512_2Arg: two <2 x i64>
;     ISel SHA512SU0
; All four under HasSHA3 / FEAT_SHA3.  ISel Predicates = [HasSHA3];
; FeatureSHA3 token is "sha3" (Enable SHA512 and SHA3), not +sha2.
; Last-token function +sha3 required; missing or final -sha3,
; +sha2, and +crypto do not count.  Command-line -mattr is never
; consulted.  Exact C non-vararg.  Ordinary tail accepted and replayed as non-tail; see vmp-direct-call-tail-eligibility-semantic.ll.  SHA-1 / SHA-256 / AES / SM3 / SM4 / SVE stay
; out.  Well-formed SHA-3 eor3/bcax/rax1/xar is
; vmp-aarch64-crypto-sha3-semantic.ll.  No new opcode.  IDs are
; non-overloaded;
; other widths / half / bfloat are verifier-illegal.
;
; Host cannot select these AArch64 intrinsics; no lli.
; FileCheck + AArch64 llc/readobj/asm (-mattr=+sha3).  O0/O2 x 97/7.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.ll -o %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+sha3 -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+sha3 %t.o0.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.ll -o %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+sha3 -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+sha3 %t.o2.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.s7.ll -o %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+sha3 -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+sha3 %t.o0.s7.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.s7.ll -o %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+sha3 -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+sha3 %t.o2.s7.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %s | opt -S -verify-each -aesSeed=97 -passes='default<O0>' - 2>&1 | FileCheck %s --check-prefix=HOST

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare <2 x i64> @llvm.aarch64.crypto.sha512h(<2 x i64>, <2 x i64>, <2 x i64>)
declare <2 x i64> @llvm.aarch64.crypto.sha512h2(<2 x i64>, <2 x i64>, <2 x i64>)
declare <2 x i64> @llvm.aarch64.crypto.sha512su0(<2 x i64>, <2 x i64>)
declare <2 x i64> @llvm.aarch64.crypto.sha512su1(<2 x i64>, <2 x i64>, <2 x i64>)
declare <vscale x 16 x i8> @llvm.aarch64.sve.aese(<vscale x 16 x i8>, <vscale x 16 x i8>)

@sink_v2i64 = global <2 x i64> zeroinitializer, align 16

define <2 x i64> @protected_sha512h(<2 x i64> %a, <2 x i64> %b, <2 x i64> %c) noinline optnone "target-features"="+sha3" {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.aarch64.crypto.sha512h(<2 x i64> %a, <2 x i64> %b, <2 x i64> %c)
  ret <2 x i64> %r
}

define <2 x i64> @protected_sha512h2(<2 x i64> %a, <2 x i64> %b, <2 x i64> %c) noinline optnone "target-features"="+sha3" {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.aarch64.crypto.sha512h2(<2 x i64> %a, <2 x i64> %b, <2 x i64> %c)
  ret <2 x i64> %r
}

define <2 x i64> @protected_sha512su0(<2 x i64> %a, <2 x i64> %b) noinline optnone "target-features"="+sha3" {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.aarch64.crypto.sha512su0(<2 x i64> %a, <2 x i64> %b)
  ret <2 x i64> %r
}

define <2 x i64> @protected_sha512su1(<2 x i64> %a, <2 x i64> %b, <2 x i64> %c) noinline optnone "target-features"="+sha3" {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.aarch64.crypto.sha512su1(<2 x i64> %a, <2 x i64> %b, <2 x i64> %c)
  ret <2 x i64> %r
}

define <2 x i64> @protected_sha512h_last_sha3(<2 x i64> %a, <2 x i64> %b, <2 x i64> %c) noinline optnone "target-features"="+neon,+crc,+sha3" {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.aarch64.crypto.sha512h(<2 x i64> %a, <2 x i64> %b, <2 x i64> %c)
  ret <2 x i64> %r
}

define <2 x i64> @unsupported_no_sha3(<2 x i64> %a, <2 x i64> %b, <2 x i64> %c) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.aarch64.crypto.sha512h(<2 x i64> %a, <2 x i64> %b, <2 x i64> %c)
  ret <2 x i64> %r
}

define <2 x i64> @unsupported_sha3_disabled(<2 x i64> %a, <2 x i64> %b, <2 x i64> %c) noinline optnone "target-features"="+sha3,-sha3" {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.aarch64.crypto.sha512h(<2 x i64> %a, <2 x i64> %b, <2 x i64> %c)
  ret <2 x i64> %r
}

define <2 x i64> @unsupported_sha2_only(<2 x i64> %a, <2 x i64> %b, <2 x i64> %c) noinline optnone "target-features"="+sha2" {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.aarch64.crypto.sha512h(<2 x i64> %a, <2 x i64> %b, <2 x i64> %c)
  ret <2 x i64> %r
}

define <2 x i64> @unsupported_crypto_only(<2 x i64> %a, <2 x i64> %b, <2 x i64> %c) noinline optnone "target-features"="+crypto" {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.aarch64.crypto.sha512h(<2 x i64> %a, <2 x i64> %b, <2 x i64> %c)
  ret <2 x i64> %r
}

; Well-formed SHA-1 / SHA-256 / AES / SM3 / SM4 are independent
; surfaces and must not stay here with their last-token features.

; Well-formed llvm.aarch64.crypto.rax1 is covered by
; vmp-aarch64-crypto-sha3-semantic.ll and must not stay here with
; last-token +sha3 (it would virtualize).

define <vscale x 16 x i8> @unsupported_sve_aese(<vscale x 16 x i8> %a, <vscale x 16 x i8> %b) noinline optnone "target-features"="+sha3" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 16 x i8> @llvm.aarch64.sve.aese(<vscale x 16 x i8> %a, <vscale x 16 x i8> %b)
  ret <vscale x 16 x i8> %r
}

define <2 x i64> @unsupported_fastcc(<2 x i64> %a, <2 x i64> %b, <2 x i64> %c) noinline optnone "target-features"="+sha3" {
entry:
  call void @hikari_vmp()
  %r = call fastcc <2 x i64> @llvm.aarch64.crypto.sha512h(<2 x i64> %a, <2 x i64> %b, <2 x i64> %c)
  ret <2 x i64> %r
}


define <2 x i64> @unsupported_musttail(<2 x i64> %a, <2 x i64> %b, <2 x i64> %c) noinline optnone "target-features"="+sha3" {
entry:
  call void @hikari_vmp()
  %r = musttail call <2 x i64> @llvm.aarch64.crypto.sha512h(<2 x i64> %a, <2 x i64> %b, <2 x i64> %c)
  ret <2 x i64> %r
}

define <2 x i64> @unsupported_bundle(<2 x i64> %a, <2 x i64> %b, <2 x i64> %c) noinline optnone "target-features"="+sha3" {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.aarch64.crypto.sha512h(<2 x i64> %a, <2 x i64> %b, <2 x i64> %c) [ "deopt"(i32 0) ]
  ret <2 x i64> %r
}

define <2 x i64> @unsupported_noreturn(<2 x i64> %a, <2 x i64> %b, <2 x i64> %c) noinline optnone "target-features"="+sha3" {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.aarch64.crypto.sha512h(<2 x i64> %a, <2 x i64> %b, <2 x i64> %c) noreturn
  ret <2 x i64> %r
}

define <2 x i64> @unsupported_returns_twice(<2 x i64> %a, <2 x i64> %b, <2 x i64> %c) noinline optnone "target-features"="+sha3" {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.aarch64.crypto.sha512h(<2 x i64> %a, <2 x i64> %b, <2 x i64> %c) returns_twice
  ret <2 x i64> %r
}

define i32 @main() {
entry:
  %v = load volatile <2 x i64>, ptr @sink_v2i64, align 16
  %r0 = call <2 x i64> @protected_sha512h(<2 x i64> %v, <2 x i64> %v, <2 x i64> %v)
  store volatile <2 x i64> %r0, ptr @sink_v2i64, align 16
  %r1 = call <2 x i64> @protected_sha512h2(<2 x i64> %v, <2 x i64> %v, <2 x i64> %v)
  store volatile <2 x i64> %r1, ptr @sink_v2i64, align 16
  %r2 = call <2 x i64> @protected_sha512su0(<2 x i64> %v, <2 x i64> %v)
  store volatile <2 x i64> %r2, ptr @sink_v2i64, align 16
  %r3 = call <2 x i64> @protected_sha512su1(<2 x i64> %v, <2 x i64> %v, <2 x i64> %v)
  store volatile <2 x i64> %r3, ptr @sink_v2i64, align 16
  %r4 = call <2 x i64> @protected_sha512h_last_sha3(<2 x i64> %v, <2 x i64> %v, <2 x i64> %v)
  store volatile <2 x i64> %r4, ptr @sink_v2i64, align 16
  ret i32 0
}

; SKIP-DAG: Skipping VMP on unsupported_no_sha3: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_sha3_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_sha2_only: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_crypto_only: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_sve_aese: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_noreturn: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_returns_twice: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_sha512h:
; SKIP-NOT: Skipping VMP on protected_sha512h2:
; SKIP-NOT: Skipping VMP on protected_sha512su0:
; SKIP-NOT: Skipping VMP on protected_sha512su1:
; SKIP-NOT: Skipping VMP on protected_sha512h_last_sha3:

; VIRT: define <2 x i64> @protected_sha512h({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i64> @llvm.aarch64.crypto.sha512h(
; VIRT: define <2 x i64> @protected_sha512h2({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i64> @llvm.aarch64.crypto.sha512h2(
; VIRT: define <2 x i64> @protected_sha512su0({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i64> @llvm.aarch64.crypto.sha512su0(
; VIRT: define <2 x i64> @protected_sha512su1({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i64> @llvm.aarch64.crypto.sha512su1(
; VIRT: define <2 x i64> @protected_sha512h_last_sha3({{.*}} #[[LAST:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i64> @llvm.aarch64.crypto.sha512h(
; VIRT: define {{.*}} @unsupported_no_sha3({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT: attributes #[[LAST]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; AARCH64-ASM: {{^[[:space:]]*}}sha512h{{[ \t]}}
; AARCH64-ASM: {{^[[:space:]]*}}sha512h2{{[ \t]}}
; AARCH64-ASM: {{^[[:space:]]*}}sha512su0{{[ \t]}}
; AARCH64-ASM: {{^[[:space:]]*}}sha512su1{{[ \t]}}
; HOST: Skipping VMP: only AArch64 targets are supported
