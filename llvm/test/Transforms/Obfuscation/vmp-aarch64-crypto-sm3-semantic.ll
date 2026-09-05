; Restricted AArch64 crypto SM3 via CallDescriptor / vector VRegs:
;   llvm.aarch64.crypto.sm3ss1 / sm3partw1 / sm3partw2
;     Crypto_SM3_3Vector: three <4 x i32>
;     ISel SM3SS1 / SM3PARTW1 / SM3PARTW2
;   llvm.aarch64.crypto.sm3tt1a / tt1b / tt2a / tt2b
;     Crypto_SM3_3VectorIndexed:
;       <4 x i32>(<4 x i32>, <4 x i32>, <4 x i32>, i64 imm)
;     ISel SM3TT* with VectorIndexS i64 ImmArg in [0, 4)
; All seven under HasSM4 / FEAT_SM4 (FeatureSM4 enables SM3 and
; SM4).  Last-token function +sm4 required; missing or final
; -sm4, +sha2, and +crypto do not count.  Command-line -mattr
; is never consulted.  Exact C non-vararg.  Ordinary tail accepted and replayed as non-tail; see vmp-direct-call-tail-eligibility-semantic.ll.  SM4 / AES / SHA / SVE stay
; out.  No new opcode.  IDs are non-overloaded; other widths /
; half / bfloat / dynamic tt* lanes are verifier-illegal or
; shape-rejected.  tt* i64 lane stays on ImmediateArguments.
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
declare <4 x i32> @llvm.aarch64.crypto.sm3ss1(<4 x i32>, <4 x i32>, <4 x i32>)
declare <4 x i32> @llvm.aarch64.crypto.sm3partw1(<4 x i32>, <4 x i32>, <4 x i32>)
declare <4 x i32> @llvm.aarch64.crypto.sm3partw2(<4 x i32>, <4 x i32>, <4 x i32>)
declare <4 x i32> @llvm.aarch64.crypto.sm3tt1a(<4 x i32>, <4 x i32>, <4 x i32>, i64)
declare <4 x i32> @llvm.aarch64.crypto.sm3tt1b(<4 x i32>, <4 x i32>, <4 x i32>, i64)
declare <4 x i32> @llvm.aarch64.crypto.sm3tt2a(<4 x i32>, <4 x i32>, <4 x i32>, i64)
declare <4 x i32> @llvm.aarch64.crypto.sm3tt2b(<4 x i32>, <4 x i32>, <4 x i32>, i64)
declare <vscale x 4 x i32> @llvm.aarch64.sve.sm4e(<vscale x 4 x i32>, <vscale x 4 x i32>)

@sink_v4i32 = global <4 x i32> zeroinitializer, align 16

define <4 x i32> @protected_sm3ss1(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c) noinline optnone "target-features"="+sm4" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.crypto.sm3ss1(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c)
  ret <4 x i32> %r
}

define <4 x i32> @protected_sm3partw1(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c) noinline optnone "target-features"="+sm4" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.crypto.sm3partw1(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c)
  ret <4 x i32> %r
}

define <4 x i32> @protected_sm3partw2(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c) noinline optnone "target-features"="+sm4" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.crypto.sm3partw2(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c)
  ret <4 x i32> %r
}

define <4 x i32> @protected_sm3tt1a(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c) noinline optnone "target-features"="+sm4" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.crypto.sm3tt1a(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c, i64 0)
  ret <4 x i32> %r
}

define <4 x i32> @protected_sm3tt1b(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c) noinline optnone "target-features"="+sm4" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.crypto.sm3tt1b(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c, i64 1)
  ret <4 x i32> %r
}

define <4 x i32> @protected_sm3tt2a(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c) noinline optnone "target-features"="+sm4" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.crypto.sm3tt2a(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c, i64 2)
  ret <4 x i32> %r
}

define <4 x i32> @protected_sm3tt2b(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c) noinline optnone "target-features"="+sm4" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.crypto.sm3tt2b(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c, i64 3)
  ret <4 x i32> %r
}

define <4 x i32> @protected_sm3ss1_last_sm4(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c) noinline optnone "target-features"="+neon,+crc,+sm4" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.crypto.sm3ss1(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c)
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_no_sm4(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.crypto.sm3ss1(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c)
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_sm4_disabled(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c) noinline optnone "target-features"="+sm4,-sm4" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.crypto.sm3ss1(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c)
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_sha2_only(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c) noinline optnone "target-features"="+sha2" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.crypto.sm3ss1(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c)
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_crypto_only(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c) noinline optnone "target-features"="+crypto" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.crypto.sm3ss1(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c)
  ret <4 x i32> %r
}

; Well-formed llvm.aarch64.crypto.sm4e is covered by
; vmp-aarch64-crypto-sm4-semantic.ll and must not stay here with
; last-token +sm4 (it would virtualize).

; Well-formed AES / SHA-1 / SHA-256 are independent surfaces.

define <4 x i32> @unsupported_tt_oob(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c) noinline optnone "target-features"="+sm4" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.crypto.sm3tt1a(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c, i64 4)
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_tt_neg(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c) noinline optnone "target-features"="+sm4" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.crypto.sm3tt1a(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c, i64 -1)
  ret <4 x i32> %r
}

define <vscale x 4 x i32> @unsupported_sve_sm4e(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b) noinline optnone "target-features"="+sm4" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.aarch64.sve.sm4e(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b)
  ret <vscale x 4 x i32> %r
}

define <4 x i32> @unsupported_fastcc(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c) noinline optnone "target-features"="+sm4" {
entry:
  call void @hikari_vmp()
  %r = call fastcc <4 x i32> @llvm.aarch64.crypto.sm3ss1(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c)
  ret <4 x i32> %r
}


define <4 x i32> @unsupported_musttail(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c) noinline optnone "target-features"="+sm4" {
entry:
  call void @hikari_vmp()
  %r = musttail call <4 x i32> @llvm.aarch64.crypto.sm3ss1(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c)
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_bundle(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c) noinline optnone "target-features"="+sm4" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.crypto.sm3ss1(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c) [ "deopt"(i32 0) ]
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_noreturn(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c) noinline optnone "target-features"="+sm4" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.crypto.sm3ss1(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c) noreturn
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_returns_twice(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c) noinline optnone "target-features"="+sm4" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.crypto.sm3ss1(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c) returns_twice
  ret <4 x i32> %r
}

define i32 @main() {
entry:
  %v = load volatile <4 x i32>, ptr @sink_v4i32, align 16
  %r0 = call <4 x i32> @protected_sm3ss1(<4 x i32> %v, <4 x i32> %v, <4 x i32> %v)
  store volatile <4 x i32> %r0, ptr @sink_v4i32, align 16
  %r1 = call <4 x i32> @protected_sm3partw1(<4 x i32> %v, <4 x i32> %v, <4 x i32> %v)
  store volatile <4 x i32> %r1, ptr @sink_v4i32, align 16
  %r2 = call <4 x i32> @protected_sm3partw2(<4 x i32> %v, <4 x i32> %v, <4 x i32> %v)
  store volatile <4 x i32> %r2, ptr @sink_v4i32, align 16
  %r3 = call <4 x i32> @protected_sm3tt1a(<4 x i32> %v, <4 x i32> %v, <4 x i32> %v)
  store volatile <4 x i32> %r3, ptr @sink_v4i32, align 16
  %r4 = call <4 x i32> @protected_sm3tt1b(<4 x i32> %v, <4 x i32> %v, <4 x i32> %v)
  store volatile <4 x i32> %r4, ptr @sink_v4i32, align 16
  %r5 = call <4 x i32> @protected_sm3tt2a(<4 x i32> %v, <4 x i32> %v, <4 x i32> %v)
  store volatile <4 x i32> %r5, ptr @sink_v4i32, align 16
  %r6 = call <4 x i32> @protected_sm3tt2b(<4 x i32> %v, <4 x i32> %v, <4 x i32> %v)
  store volatile <4 x i32> %r6, ptr @sink_v4i32, align 16
  %r7 = call <4 x i32> @protected_sm3ss1_last_sm4(<4 x i32> %v, <4 x i32> %v, <4 x i32> %v)
  store volatile <4 x i32> %r7, ptr @sink_v4i32, align 16
  ret i32 0
}

; SKIP-DAG: Skipping VMP on unsupported_no_sm4: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_sm4_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_sha2_only: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_crypto_only: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_tt_oob: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_tt_neg: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_sve_sm4e: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_noreturn: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_returns_twice: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_sm3ss1:
; SKIP-NOT: Skipping VMP on protected_sm3partw1:
; SKIP-NOT: Skipping VMP on protected_sm3partw2:
; SKIP-NOT: Skipping VMP on protected_sm3tt1a:
; SKIP-NOT: Skipping VMP on protected_sm3tt1b:
; SKIP-NOT: Skipping VMP on protected_sm3tt2a:
; SKIP-NOT: Skipping VMP on protected_sm3tt2b:
; SKIP-NOT: Skipping VMP on protected_sm3ss1_last_sm4:

; VIRT: define <4 x i32> @protected_sm3ss1({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.aarch64.crypto.sm3ss1(
; VIRT: define <4 x i32> @protected_sm3partw1({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.aarch64.crypto.sm3partw1(
; VIRT: define <4 x i32> @protected_sm3partw2({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.aarch64.crypto.sm3partw2(
; VIRT: define <4 x i32> @protected_sm3tt1a({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.aarch64.crypto.sm3tt1a({{.*}}i64 0)
; VIRT: define <4 x i32> @protected_sm3tt1b({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.aarch64.crypto.sm3tt1b({{.*}}i64 1)
; VIRT: define <4 x i32> @protected_sm3tt2a({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.aarch64.crypto.sm3tt2a({{.*}}i64 2)
; VIRT: define <4 x i32> @protected_sm3tt2b({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.aarch64.crypto.sm3tt2b({{.*}}i64 3)
; VIRT: define <4 x i32> @protected_sm3ss1_last_sm4({{.*}} #[[LAST:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.aarch64.crypto.sm3ss1(
; VIRT: define {{.*}} @unsupported_no_sm4({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT: attributes #[[LAST]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; AARCH64-ASM: {{^[[:space:]]*}}sm3ss1{{[ \t]}}
; AARCH64-ASM: {{^[[:space:]]*}}sm3partw1{{[ \t]}}
; AARCH64-ASM: {{^[[:space:]]*}}sm3partw2{{[ \t]}}
; AARCH64-ASM: {{^[[:space:]]*}}sm3tt1a{{[ \t]}}
; AARCH64-ASM: {{^[[:space:]]*}}sm3tt1b{{[ \t]}}
; AARCH64-ASM: {{^[[:space:]]*}}sm3tt2a{{[ \t]}}
; AARCH64-ASM: {{^[[:space:]]*}}sm3tt2b{{[ \t]}}
; HOST: Skipping VMP: only AArch64 targets are supported
