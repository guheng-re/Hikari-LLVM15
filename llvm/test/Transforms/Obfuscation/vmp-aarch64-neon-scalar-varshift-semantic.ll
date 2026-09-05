; Restricted AArch64 scalar non-saturating variable shift via
; CallDescriptor / integer VRegs:
;   llvm.aarch64.neon.sshl / ushl
;   llvm.aarch64.neon.srshl / urshl
;     AdvSIMD_2IntArg: anyint (match, match)
;     Extra ISel Pats: only i64(i64, i64) -> *SHLv1i64
;     SIMDThreeScalarD is v1i64 only (kept out).
; i32 CannotYetSelect.  Clang vshld_s64 / vshld_u64 /
; vrshld_s64 / vrshld_u64.  Must not lower to generic shl
; or sat sqshl.  Amount is signed (negative = right).
; srshl/urshl round.  Amount is not ImmArg.  Vector
; varshift is vmp-aarch64-neon-varshift-semantic.ll and
; must not stay here as a well-formed skip.  No last-token.
; No FMF.  Command-line -mattr never consulted.  Exact C
; non-vararg.  Ordinary tail accepted and replayed as non-tail; see vmp-direct-call-tail-eligibility-semantic.ll.
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
declare void @ext_sret_byval(ptr sret(i64), ptr byval(i64))
declare i64 @llvm.aarch64.neon.sshl.i64(i64, i64)
declare i64 @llvm.aarch64.neon.ushl.i64(i64, i64)
declare i64 @llvm.aarch64.neon.srshl.i64(i64, i64)
declare i64 @llvm.aarch64.neon.urshl.i64(i64, i64)
declare i32 @llvm.aarch64.neon.sshl.i32(i32, i32)
declare <1 x i64> @llvm.aarch64.neon.sshl.v1i64(<1 x i64>, <1 x i64>)
declare <vscale x 16 x i8> @llvm.aarch64.sve.srshl.nxv16i8(<vscale x 16 x i1>, <vscale x 16 x i8>, <vscale x 16 x i8>)

@sink_i64 = global i64 0, align 8

define i64 @protected_sshl_i64(i64 %a, i64 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.aarch64.neon.sshl.i64(i64 %a, i64 %b)
  ret i64 %r
}

define i64 @protected_ushl_i64(i64 %a, i64 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.aarch64.neon.ushl.i64(i64 %a, i64 %b)
  ret i64 %r
}

define i64 @protected_srshl_i64(i64 %a, i64 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.aarch64.neon.srshl.i64(i64 %a, i64 %b)
  ret i64 %r
}

define i64 @protected_urshl_i64(i64 %a, i64 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.aarch64.neon.urshl.i64(i64 %a, i64 %b)
  ret i64 %r
}

; 3 >> 1: srshl rounds (may fold to srshr #1 before VMP).
define i64 @protected_srshl_negamt() noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.aarch64.neon.srshl.i64(i64 3, i64 -1)
  ret i64 %r
}

; 3 >> 1 trunc via sshl stays register form.
define i64 @protected_sshl_negamt() noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.aarch64.neon.sshl.i64(i64 3, i64 -1)
  ret i64 %r
}

; ----- negatives: selected, not virtualized -----

define i32 @unsupported_i32(i32 %a, i32 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.sshl.i32(i32 %a, i32 %b)
  ret i32 %r
}

define <1 x i64> @unsupported_v1i64(<1 x i64> %a, <1 x i64> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <1 x i64> @llvm.aarch64.neon.sshl.v1i64(<1 x i64> %a, <1 x i64> %b)
  ret <1 x i64> %r
}

define <vscale x 16 x i8> @unsupported_sve(<vscale x 16 x i1> %pg, <vscale x 16 x i8> %a, <vscale x 16 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 16 x i8> @llvm.aarch64.sve.srshl.nxv16i8(<vscale x 16 x i1> %pg, <vscale x 16 x i8> %a, <vscale x 16 x i8> %b)
  ret <vscale x 16 x i8> %r
}

define i64 @unsupported_fastcc(i64 %a, i64 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc i64 @llvm.aarch64.neon.sshl.i64(i64 %a, i64 %b)
  ret i64 %r
}


define i64 @unsupported_musttail(i64 %a, i64 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call i64 @llvm.aarch64.neon.sshl.i64(i64 %a, i64 %b)
  ret i64 %r
}

define i64 @unsupported_bundle(i64 %a, i64 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.aarch64.neon.sshl.i64(i64 %a, i64 %b) [ "deopt"(i32 0) ]
  ret i64 %r
}

define i64 @unsupported_noreturn(i64 %a, i64 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.aarch64.neon.sshl.i64(i64 %a, i64 %b) noreturn
  ret i64 %r
}

define i64 @unsupported_returns_twice(i64 %a, i64 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.aarch64.neon.sshl.i64(i64 %a, i64 %b) returns_twice
  ret i64 %r
}

define void @unsupported_sret(ptr sret(i64) %p, ptr byval(i64) %q) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @ext_sret_byval(ptr sret(i64) %p, ptr byval(i64) %q)
  ret void
}

define i32 @main() {
entry:
  %a = load volatile i64, ptr @sink_i64, align 8
  %b = load volatile i64, ptr @sink_i64, align 8
  %r0 = call i64 @protected_sshl_i64(i64 %a, i64 %b)
  store volatile i64 %r0, ptr @sink_i64, align 8
  %r1 = call i64 @protected_ushl_i64(i64 %a, i64 %b)
  store volatile i64 %r1, ptr @sink_i64, align 8
  %r2 = call i64 @protected_srshl_i64(i64 %a, i64 %b)
  store volatile i64 %r2, ptr @sink_i64, align 8
  %r3 = call i64 @protected_urshl_i64(i64 %a, i64 %b)
  store volatile i64 %r3, ptr @sink_i64, align 8
  %r4 = call i64 @protected_srshl_negamt()
  store volatile i64 %r4, ptr @sink_i64, align 8
  %r5 = call i64 @protected_sshl_negamt()
  store volatile i64 %r5, ptr @sink_i64, align 8
  ret i32 0
}

; SKIP-DAG: Skipping VMP on unsupported_i32: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_v1i64: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_sve: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_noreturn: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_returns_twice: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_sret: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_sshl_i64:
; SKIP-NOT: Skipping VMP on protected_ushl_i64:
; SKIP-NOT: Skipping VMP on protected_srshl_i64:
; SKIP-NOT: Skipping VMP on protected_urshl_i64:
; SKIP-NOT: Skipping VMP on protected_srshl_negamt:
; SKIP-NOT: Skipping VMP on protected_sshl_negamt:

; VIRT: define i64 @protected_sshl_i64({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.aarch64.neon.sshl.i64(
; VIRT: define i64 @protected_ushl_i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.aarch64.neon.ushl.i64(
; VIRT: define i64 @protected_srshl_i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.aarch64.neon.srshl.i64(
; VIRT: define i64 @protected_urshl_i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.aarch64.neon.urshl.i64(
; VIRT: define i64 @protected_srshl_negamt({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.aarch64.neon.srshl.i64(
; VIRT: define i64 @protected_sshl_negamt({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.aarch64.neon.sshl.i64(
; VIRT: define {{.*}} @unsupported_i32({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; AARCH64-ASM-DAG: {{^[[:space:]]*}}sshl{{[ \t]}}
; AARCH64-ASM-DAG: {{^[[:space:]]*}}ushl{{[ \t]}}
; AARCH64-ASM-DAG: {{^[[:space:]]*}}srshl{{[ \t]}}
; AARCH64-ASM-DAG: {{^[[:space:]]*}}urshl{{[ \t]}}
; HOST: Skipping VMP: only AArch64 targets are supported
