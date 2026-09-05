; Restricted AArch64 crypto SHA-1 via CallDescriptor / integer and
; vector VRegs:
;   llvm.aarch64.crypto.sha1h
;     Crypto_SHA_1Hash: i32(i32)           ISel SHAInstSS sha1h
;   llvm.aarch64.crypto.sha1c / sha1p / sha1m
;     Crypto_SHA_5Hash4Schedule:
;       <4 x i32>(<4 x i32>, i32, <4 x i32>)
;       ISel SHATiedInstQSV sha1c/sha1p/sha1m
;   llvm.aarch64.crypto.sha1su0
;     Crypto_SHA_12Schedule: three <4 x i32>
;     ISel SHATiedInstVVV sha1su0
;   llvm.aarch64.crypto.sha1su1
;     Crypto_SHA_8Schedule: two <4 x i32>
;     ISel SHATiedInstVV sha1su1
; All six under HasSHA2 / FEAT_SHA1+SHA256.  Last-token function
; +sha2 required; missing or final -sha2, +sha3, and +crypto do
; not count.  Command-line -mattr is never consulted for
; eligibility.  Exact C non-vararg.  Ordinary tail accepted and replayed as non-tail; see vmp-direct-call-tail-eligibility-semantic.ll.  SM4 / AES / SVE stay out.  Well-formed
; SHA-256 is vmp-aarch64-crypto-sha256-semantic.ll.
; No new opcode.  These IDs are non-overloaded; other widths /
; half / bfloat are verifier-illegal, not IR negatives.
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
declare i32 @llvm.aarch64.crypto.sha1h(i32)
declare <4 x i32> @llvm.aarch64.crypto.sha1c(<4 x i32>, i32, <4 x i32>)
declare <4 x i32> @llvm.aarch64.crypto.sha1p(<4 x i32>, i32, <4 x i32>)
declare <4 x i32> @llvm.aarch64.crypto.sha1m(<4 x i32>, i32, <4 x i32>)
declare <4 x i32> @llvm.aarch64.crypto.sha1su0(<4 x i32>, <4 x i32>, <4 x i32>)
declare <4 x i32> @llvm.aarch64.crypto.sha1su1(<4 x i32>, <4 x i32>)
declare <vscale x 16 x i8> @llvm.aarch64.sve.aese(<vscale x 16 x i8>, <vscale x 16 x i8>)

@sink_i32 = global i32 0, align 4
@sink_v4i32 = global <4 x i32> zeroinitializer, align 16

define i32 @protected_sha1h(i32 %a) noinline optnone "target-features"="+sha2" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.crypto.sha1h(i32 %a)
  ret i32 %r
}

define <4 x i32> @protected_sha1c(<4 x i32> %h, i32 %s, <4 x i32> %w) noinline optnone "target-features"="+sha2" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.crypto.sha1c(<4 x i32> %h, i32 %s, <4 x i32> %w)
  ret <4 x i32> %r
}

define <4 x i32> @protected_sha1p(<4 x i32> %h, i32 %s, <4 x i32> %w) noinline optnone "target-features"="+sha2" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.crypto.sha1p(<4 x i32> %h, i32 %s, <4 x i32> %w)
  ret <4 x i32> %r
}

define <4 x i32> @protected_sha1m(<4 x i32> %h, i32 %s, <4 x i32> %w) noinline optnone "target-features"="+sha2" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.crypto.sha1m(<4 x i32> %h, i32 %s, <4 x i32> %w)
  ret <4 x i32> %r
}

define <4 x i32> @protected_sha1su0(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c) noinline optnone "target-features"="+sha2" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.crypto.sha1su0(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c)
  ret <4 x i32> %r
}

define <4 x i32> @protected_sha1su1(<4 x i32> %a, <4 x i32> %b) noinline optnone "target-features"="+sha2" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.crypto.sha1su1(<4 x i32> %a, <4 x i32> %b)
  ret <4 x i32> %r
}

define <4 x i32> @protected_sha1c_last_sha2(<4 x i32> %h, i32 %s, <4 x i32> %w) noinline optnone "target-features"="+neon,+crc,+sha2" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.crypto.sha1c(<4 x i32> %h, i32 %s, <4 x i32> %w)
  ret <4 x i32> %r
}

define i32 @unsupported_no_sha2(i32 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.crypto.sha1h(i32 %a)
  ret i32 %r
}

define i32 @unsupported_sha2_disabled(i32 %a) noinline optnone "target-features"="+sha2,-sha2" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.crypto.sha1h(i32 %a)
  ret i32 %r
}

define i32 @unsupported_sha3_only(i32 %a) noinline optnone "target-features"="+sha3" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.crypto.sha1h(i32 %a)
  ret i32 %r
}

define i32 @unsupported_crypto_only(i32 %a) noinline optnone "target-features"="+crypto" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.crypto.sha1h(i32 %a)
  ret i32 %r
}

; Well-formed llvm.aarch64.crypto.sha256h is covered by
; vmp-aarch64-crypto-sha256-semantic.ll and must not stay here
; with last-token +sha2 (it would virtualize).

; Well-formed llvm.aarch64.crypto.aese is covered by
; vmp-aarch64-crypto-aes-semantic.ll and must not stay here with
; last-token +aes (it would virtualize).

; Well-formed llvm.aarch64.crypto.sm4e is covered by
; vmp-aarch64-crypto-sm4-semantic.ll.  Missing +sm4 would skip as
; unsupported target feature, not stay here as a SHA-1 negative.

define <vscale x 16 x i8> @unsupported_sve_aese(<vscale x 16 x i8> %a, <vscale x 16 x i8> %b) noinline optnone "target-features"="+sha2" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 16 x i8> @llvm.aarch64.sve.aese(<vscale x 16 x i8> %a, <vscale x 16 x i8> %b)
  ret <vscale x 16 x i8> %r
}

define i32 @unsupported_fastcc(i32 %a) noinline optnone "target-features"="+sha2" {
entry:
  call void @hikari_vmp()
  %r = call fastcc i32 @llvm.aarch64.crypto.sha1h(i32 %a)
  ret i32 %r
}


define i32 @unsupported_musttail(i32 %a) noinline optnone "target-features"="+sha2" {
entry:
  call void @hikari_vmp()
  %r = musttail call i32 @llvm.aarch64.crypto.sha1h(i32 %a)
  ret i32 %r
}

define i32 @unsupported_bundle(i32 %a) noinline optnone "target-features"="+sha2" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.crypto.sha1h(i32 %a) [ "deopt"(i32 0) ]
  ret i32 %r
}

define i32 @unsupported_noreturn(i32 %a) noinline optnone "target-features"="+sha2" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.crypto.sha1h(i32 %a) noreturn
  ret i32 %r
}

define i32 @unsupported_returns_twice(i32 %a) noinline optnone "target-features"="+sha2" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.crypto.sha1h(i32 %a) returns_twice
  ret i32 %r
}

define i32 @main() {
entry:
  %s = load volatile i32, ptr @sink_i32, align 4
  %v = load volatile <4 x i32>, ptr @sink_v4i32, align 16
  %r0 = call i32 @protected_sha1h(i32 %s)
  store volatile i32 %r0, ptr @sink_i32, align 4
  %r1 = call <4 x i32> @protected_sha1c(<4 x i32> %v, i32 %s, <4 x i32> %v)
  store volatile <4 x i32> %r1, ptr @sink_v4i32, align 16
  %r2 = call <4 x i32> @protected_sha1p(<4 x i32> %v, i32 %s, <4 x i32> %v)
  store volatile <4 x i32> %r2, ptr @sink_v4i32, align 16
  %r3 = call <4 x i32> @protected_sha1m(<4 x i32> %v, i32 %s, <4 x i32> %v)
  store volatile <4 x i32> %r3, ptr @sink_v4i32, align 16
  %r4 = call <4 x i32> @protected_sha1su0(<4 x i32> %v, <4 x i32> %v, <4 x i32> %v)
  store volatile <4 x i32> %r4, ptr @sink_v4i32, align 16
  %r5 = call <4 x i32> @protected_sha1su1(<4 x i32> %v, <4 x i32> %v)
  store volatile <4 x i32> %r5, ptr @sink_v4i32, align 16
  %r6 = call <4 x i32> @protected_sha1c_last_sha2(<4 x i32> %v, i32 %s, <4 x i32> %v)
  store volatile <4 x i32> %r6, ptr @sink_v4i32, align 16
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
; SKIP-NOT: Skipping VMP on protected_sha1h:
; SKIP-NOT: Skipping VMP on protected_sha1c:
; SKIP-NOT: Skipping VMP on protected_sha1p:
; SKIP-NOT: Skipping VMP on protected_sha1m:
; SKIP-NOT: Skipping VMP on protected_sha1su0:
; SKIP-NOT: Skipping VMP on protected_sha1su1:
; SKIP-NOT: Skipping VMP on protected_sha1c_last_sha2:

; VIRT: define i32 @protected_sha1h({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.crypto.sha1h(
; VIRT: define <4 x i32> @protected_sha1c({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.aarch64.crypto.sha1c(
; VIRT: define <4 x i32> @protected_sha1p({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.aarch64.crypto.sha1p(
; VIRT: define <4 x i32> @protected_sha1m({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.aarch64.crypto.sha1m(
; VIRT: define <4 x i32> @protected_sha1su0({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.aarch64.crypto.sha1su0(
; VIRT: define <4 x i32> @protected_sha1su1({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.aarch64.crypto.sha1su1(
; VIRT: define <4 x i32> @protected_sha1c_last_sha2({{.*}} #[[LAST:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.aarch64.crypto.sha1c(
; VIRT: define {{.*}} @unsupported_no_sha2({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT: attributes #[[LAST]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; AARCH64-ASM: {{^[[:space:]]*}}sha1h{{[ \t]}}
; AARCH64-ASM: {{^[[:space:]]*}}sha1c{{[ \t]}}
; AARCH64-ASM: {{^[[:space:]]*}}sha1p{{[ \t]}}
; AARCH64-ASM: {{^[[:space:]]*}}sha1m{{[ \t]}}
; AARCH64-ASM: {{^[[:space:]]*}}sha1su0{{[ \t]}}
; AARCH64-ASM: {{^[[:space:]]*}}sha1su1{{[ \t]}}
; HOST: Skipping VMP: only AArch64 targets are supported
