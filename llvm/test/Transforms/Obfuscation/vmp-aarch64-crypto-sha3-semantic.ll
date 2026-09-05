; Restricted AArch64 SHA-3 state-transform via CallDescriptor /
; vector VRegs:
;   llvm.aarch64.crypto.eor3s / eor3u / bcaxs / bcaxu
;     Crypto_SHA3_3Arg (overloaded); this surface is only <2 x i64>
;     ISel EOR3 / BCAX under HasSHA3 (also has v16i8/v8i16/v4i32)
;   llvm.aarch64.crypto.rax1
;     Crypto_SHA3_2Arg: two <2 x i64>
;     ISel RAX1
;   llvm.aarch64.crypto.xar
;     Crypto_SHA3_2ArgImm: two <2 x i64> + i64 ImmArg
;     ISel XAR, timm0_63 in [0, 64)
; All under HasSHA3 / FEAT_SHA3.  Last-token function +sha3
; required; missing or final -sha3, +sha2, and +crypto do not
; count.  Command-line -mattr is never consulted.  Exact C
; non-vararg.  Ordinary tail accepted and replayed as non-tail; see vmp-direct-call-tail-eligibility-semantic.ll.
; SHA-1 / SHA-256 / SHA-512 / AES / SM3 / SM4 / SVE stay out.
; No new opcode.  xar rotate stays on ImmediateArguments.
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
declare <2 x i64> @llvm.aarch64.crypto.eor3u.v2i64(<2 x i64>, <2 x i64>, <2 x i64>)
declare <2 x i64> @llvm.aarch64.crypto.eor3s.v2i64(<2 x i64>, <2 x i64>, <2 x i64>)
declare <2 x i64> @llvm.aarch64.crypto.bcaxu.v2i64(<2 x i64>, <2 x i64>, <2 x i64>)
declare <2 x i64> @llvm.aarch64.crypto.rax1(<2 x i64>, <2 x i64>)
declare <2 x i64> @llvm.aarch64.crypto.xar(<2 x i64>, <2 x i64>, i64)
declare <16 x i8> @llvm.aarch64.crypto.eor3u.v16i8(<16 x i8>, <16 x i8>, <16 x i8>)
declare <vscale x 2 x i64> @llvm.aarch64.sve.rax1(<vscale x 2 x i64>, <vscale x 2 x i64>)

@sink_v2i64 = global <2 x i64> zeroinitializer, align 16

define <2 x i64> @protected_eor3u(<2 x i64> %a, <2 x i64> %b, <2 x i64> %c) noinline optnone "target-features"="+sha3" {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.aarch64.crypto.eor3u.v2i64(<2 x i64> %a, <2 x i64> %b, <2 x i64> %c)
  ret <2 x i64> %r
}

define <2 x i64> @protected_eor3s(<2 x i64> %a, <2 x i64> %b, <2 x i64> %c) noinline optnone "target-features"="+sha3" {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.aarch64.crypto.eor3s.v2i64(<2 x i64> %a, <2 x i64> %b, <2 x i64> %c)
  ret <2 x i64> %r
}

define <2 x i64> @protected_bcaxu(<2 x i64> %a, <2 x i64> %b, <2 x i64> %c) noinline optnone "target-features"="+sha3" {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.aarch64.crypto.bcaxu.v2i64(<2 x i64> %a, <2 x i64> %b, <2 x i64> %c)
  ret <2 x i64> %r
}

define <2 x i64> @protected_rax1(<2 x i64> %a, <2 x i64> %b) noinline optnone "target-features"="+sha3" {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.aarch64.crypto.rax1(<2 x i64> %a, <2 x i64> %b)
  ret <2 x i64> %r
}

define <2 x i64> @protected_xar(<2 x i64> %a, <2 x i64> %b) noinline optnone "target-features"="+sha3" {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.aarch64.crypto.xar(<2 x i64> %a, <2 x i64> %b, i64 0)
  ret <2 x i64> %r
}

define <2 x i64> @protected_xar_63(<2 x i64> %a, <2 x i64> %b) noinline optnone "target-features"="+sha3" {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.aarch64.crypto.xar(<2 x i64> %a, <2 x i64> %b, i64 63)
  ret <2 x i64> %r
}

define <2 x i64> @protected_eor3u_last_sha3(<2 x i64> %a, <2 x i64> %b, <2 x i64> %c) noinline optnone "target-features"="+neon,+crc,+sha3" {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.aarch64.crypto.eor3u.v2i64(<2 x i64> %a, <2 x i64> %b, <2 x i64> %c)
  ret <2 x i64> %r
}

define <2 x i64> @unsupported_no_sha3(<2 x i64> %a, <2 x i64> %b, <2 x i64> %c) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.aarch64.crypto.eor3u.v2i64(<2 x i64> %a, <2 x i64> %b, <2 x i64> %c)
  ret <2 x i64> %r
}

define <2 x i64> @unsupported_sha3_disabled(<2 x i64> %a, <2 x i64> %b, <2 x i64> %c) noinline optnone "target-features"="+sha3,-sha3" {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.aarch64.crypto.eor3u.v2i64(<2 x i64> %a, <2 x i64> %b, <2 x i64> %c)
  ret <2 x i64> %r
}

define <2 x i64> @unsupported_sha2_only(<2 x i64> %a, <2 x i64> %b, <2 x i64> %c) noinline optnone "target-features"="+sha2" {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.aarch64.crypto.eor3u.v2i64(<2 x i64> %a, <2 x i64> %b, <2 x i64> %c)
  ret <2 x i64> %r
}

define <2 x i64> @unsupported_crypto_only(<2 x i64> %a, <2 x i64> %b, <2 x i64> %c) noinline optnone "target-features"="+crypto" {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.aarch64.crypto.eor3u.v2i64(<2 x i64> %a, <2 x i64> %b, <2 x i64> %c)
  ret <2 x i64> %r
}

; Well-formed SHA-512 / SHA-1 / SHA-256 / AES / SM3 / SM4 are
; independent surfaces and must not stay here with their
; last-token features.

define <16 x i8> @unsupported_eor3u_v16i8(<16 x i8> %a, <16 x i8> %b, <16 x i8> %c) noinline optnone "target-features"="+sha3" {
entry:
  call void @hikari_vmp()
  %r = call <16 x i8> @llvm.aarch64.crypto.eor3u.v16i8(<16 x i8> %a, <16 x i8> %b, <16 x i8> %c)
  ret <16 x i8> %r
}

define <2 x i64> @unsupported_xar_oob(<2 x i64> %a, <2 x i64> %b) noinline optnone "target-features"="+sha3" {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.aarch64.crypto.xar(<2 x i64> %a, <2 x i64> %b, i64 64)
  ret <2 x i64> %r
}

define <2 x i64> @unsupported_xar_neg(<2 x i64> %a, <2 x i64> %b) noinline optnone "target-features"="+sha3" {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.aarch64.crypto.xar(<2 x i64> %a, <2 x i64> %b, i64 -1)
  ret <2 x i64> %r
}

define <vscale x 2 x i64> @unsupported_sve_rax1(<vscale x 2 x i64> %a, <vscale x 2 x i64> %b) noinline optnone "target-features"="+sha3" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 2 x i64> @llvm.aarch64.sve.rax1(<vscale x 2 x i64> %a, <vscale x 2 x i64> %b)
  ret <vscale x 2 x i64> %r
}

define <2 x i64> @unsupported_fastcc(<2 x i64> %a, <2 x i64> %b, <2 x i64> %c) noinline optnone "target-features"="+sha3" {
entry:
  call void @hikari_vmp()
  %r = call fastcc <2 x i64> @llvm.aarch64.crypto.eor3u.v2i64(<2 x i64> %a, <2 x i64> %b, <2 x i64> %c)
  ret <2 x i64> %r
}


define <2 x i64> @unsupported_musttail(<2 x i64> %a, <2 x i64> %b, <2 x i64> %c) noinline optnone "target-features"="+sha3" {
entry:
  call void @hikari_vmp()
  %r = musttail call <2 x i64> @llvm.aarch64.crypto.eor3u.v2i64(<2 x i64> %a, <2 x i64> %b, <2 x i64> %c)
  ret <2 x i64> %r
}

define <2 x i64> @unsupported_bundle(<2 x i64> %a, <2 x i64> %b, <2 x i64> %c) noinline optnone "target-features"="+sha3" {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.aarch64.crypto.eor3u.v2i64(<2 x i64> %a, <2 x i64> %b, <2 x i64> %c) [ "deopt"(i32 0) ]
  ret <2 x i64> %r
}

define <2 x i64> @unsupported_noreturn(<2 x i64> %a, <2 x i64> %b, <2 x i64> %c) noinline optnone "target-features"="+sha3" {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.aarch64.crypto.eor3u.v2i64(<2 x i64> %a, <2 x i64> %b, <2 x i64> %c) noreturn
  ret <2 x i64> %r
}

define <2 x i64> @unsupported_returns_twice(<2 x i64> %a, <2 x i64> %b, <2 x i64> %c) noinline optnone "target-features"="+sha3" {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.aarch64.crypto.eor3u.v2i64(<2 x i64> %a, <2 x i64> %b, <2 x i64> %c) returns_twice
  ret <2 x i64> %r
}

define i32 @main() {
entry:
  %v = load volatile <2 x i64>, ptr @sink_v2i64, align 16
  %r0 = call <2 x i64> @protected_eor3u(<2 x i64> %v, <2 x i64> %v, <2 x i64> %v)
  store volatile <2 x i64> %r0, ptr @sink_v2i64, align 16
  %r1 = call <2 x i64> @protected_eor3s(<2 x i64> %v, <2 x i64> %v, <2 x i64> %v)
  store volatile <2 x i64> %r1, ptr @sink_v2i64, align 16
  %r2 = call <2 x i64> @protected_bcaxu(<2 x i64> %v, <2 x i64> %v, <2 x i64> %v)
  store volatile <2 x i64> %r2, ptr @sink_v2i64, align 16
  %r3 = call <2 x i64> @protected_rax1(<2 x i64> %v, <2 x i64> %v)
  store volatile <2 x i64> %r3, ptr @sink_v2i64, align 16
  %r4 = call <2 x i64> @protected_xar(<2 x i64> %v, <2 x i64> %v)
  store volatile <2 x i64> %r4, ptr @sink_v2i64, align 16
  %r5 = call <2 x i64> @protected_xar_63(<2 x i64> %v, <2 x i64> %v)
  store volatile <2 x i64> %r5, ptr @sink_v2i64, align 16
  %r6 = call <2 x i64> @protected_eor3u_last_sha3(<2 x i64> %v, <2 x i64> %v, <2 x i64> %v)
  store volatile <2 x i64> %r6, ptr @sink_v2i64, align 16
  ret i32 0
}

; SKIP-DAG: Skipping VMP on unsupported_no_sha3: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_sha3_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_sha2_only: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_crypto_only: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_eor3u_v16i8: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_xar_oob: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_xar_neg: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_sve_rax1: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_noreturn: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_returns_twice: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_eor3u:
; SKIP-NOT: Skipping VMP on protected_eor3s:
; SKIP-NOT: Skipping VMP on protected_bcaxu:
; SKIP-NOT: Skipping VMP on protected_rax1:
; SKIP-NOT: Skipping VMP on protected_xar:
; SKIP-NOT: Skipping VMP on protected_xar_63:
; SKIP-NOT: Skipping VMP on protected_eor3u_last_sha3:

; VIRT: define <2 x i64> @protected_eor3u({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i64> @llvm.aarch64.crypto.eor3u.v2i64(
; VIRT: define <2 x i64> @protected_eor3s({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i64> @llvm.aarch64.crypto.eor3s.v2i64(
; VIRT: define <2 x i64> @protected_bcaxu({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i64> @llvm.aarch64.crypto.bcaxu.v2i64(
; VIRT: define <2 x i64> @protected_rax1({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i64> @llvm.aarch64.crypto.rax1(
; VIRT: define <2 x i64> @protected_xar({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i64> @llvm.aarch64.crypto.xar({{.*}}i64 0)
; VIRT: define <2 x i64> @protected_xar_63({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i64> @llvm.aarch64.crypto.xar({{.*}}i64 63)
; VIRT: define <2 x i64> @protected_eor3u_last_sha3({{.*}} #[[LAST:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i64> @llvm.aarch64.crypto.eor3u.v2i64(
; VIRT: define {{.*}} @unsupported_no_sha3({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT: attributes #[[LAST]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; AARCH64-ASM: {{^[[:space:]]*}}eor3{{[ \t]}}
; AARCH64-ASM: {{^[[:space:]]*}}bcax{{[ \t]}}
; AARCH64-ASM: {{^[[:space:]]*}}rax1{{[ \t]}}
; AARCH64-ASM: {{^[[:space:]]*}}xar{{[ \t]}}
; HOST: Skipping VMP: only AArch64 targets are supported
