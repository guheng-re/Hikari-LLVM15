; Restricted AArch64 scalar saturating abs/neg via CallDescriptor /
; integer VRegs:
;   llvm.aarch64.neon.sqabs / sqneg
;     AdvSIMD_1IntArg: anyint (match)
;     ISel SIMDTwoScalarBHSD, baseline HasNEON:
;       i32(i32) / i64(i64)
; i8/i16 encodings exist but have empty ISel patterns.  Clang
; vqabss_s32 / vqabsd_s64 / vqnegs_s32 / vqnegd_s64.  Must not
; lower to llvm.abs or generic sub.  INT_MIN saturates to
; INT_MAX for both sqabs and sqneg (unlike neon.abs).  Vector sat-absneg is
; vmp-aarch64-neon-sat-absneg-semantic.ll and must not stay here
; as a well-formed skip.  v1i64 stays out.  No last-token.
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
declare void @ext_sret_byval(ptr sret(i32), ptr byval(i32))
declare i32 @llvm.aarch64.neon.sqabs.i32(i32)
declare i64 @llvm.aarch64.neon.sqabs.i64(i64)
declare i32 @llvm.aarch64.neon.sqneg.i32(i32)
declare i64 @llvm.aarch64.neon.sqneg.i64(i64)
declare i8 @llvm.aarch64.neon.sqabs.i8(i8)
declare i16 @llvm.aarch64.neon.sqneg.i16(i16)
declare <1 x i64> @llvm.aarch64.neon.sqabs.v1i64(<1 x i64>)
declare <vscale x 4 x i32> @llvm.aarch64.sve.sqabs.nxv4i32(<vscale x 4 x i32>, <vscale x 4 x i1>, <vscale x 4 x i32>)

@sink_i32 = global i32 0, align 4
@sink_i64 = global i64 0, align 8

define i32 @protected_sqabs_i32(i32 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.sqabs.i32(i32 %a)
  ret i32 %r
}

define i64 @protected_sqabs_i64(i64 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.aarch64.neon.sqabs.i64(i64 %a)
  ret i64 %r
}

define i32 @protected_sqneg_i32(i32 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.sqneg.i32(i32 %a)
  ret i32 %r
}

define i64 @protected_sqneg_i64(i64 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.aarch64.neon.sqneg.i64(i64 %a)
  ret i64 %r
}

; INT_MIN saturates to INT_MAX (not leftover as INT_MIN).
define i32 @protected_sqabs_smin() noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.sqabs.i32(i32 -2147483648)
  ret i32 %r
}

; ----- negatives: selected, not virtualized -----

define i8 @unsupported_i8(i8 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i8 @llvm.aarch64.neon.sqabs.i8(i8 %a)
  ret i8 %r
}

define i16 @unsupported_i16(i16 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i16 @llvm.aarch64.neon.sqneg.i16(i16 %a)
  ret i16 %r
}

define <1 x i64> @unsupported_v1i64(<1 x i64> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <1 x i64> @llvm.aarch64.neon.sqabs.v1i64(<1 x i64> %a)
  ret <1 x i64> %r
}

define <vscale x 4 x i32> @unsupported_sve(<vscale x 4 x i1> %pg, <vscale x 4 x i32> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.aarch64.sve.sqabs.nxv4i32(<vscale x 4 x i32> %a, <vscale x 4 x i1> %pg, <vscale x 4 x i32> %a)
  ret <vscale x 4 x i32> %r
}

define i32 @unsupported_fastcc(i32 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc i32 @llvm.aarch64.neon.sqabs.i32(i32 %a)
  ret i32 %r
}


define i32 @unsupported_musttail(i32 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call i32 @llvm.aarch64.neon.sqabs.i32(i32 %a)
  ret i32 %r
}

define i32 @unsupported_bundle(i32 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.sqabs.i32(i32 %a) [ "deopt"(i32 0) ]
  ret i32 %r
}

define i32 @unsupported_noreturn(i32 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.sqabs.i32(i32 %a) noreturn
  ret i32 %r
}

define i32 @unsupported_returns_twice(i32 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.sqabs.i32(i32 %a) returns_twice
  ret i32 %r
}

define void @unsupported_sret(ptr sret(i32) %p, ptr byval(i32) %q) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @ext_sret_byval(ptr sret(i32) %p, ptr byval(i32) %q)
  ret void
}

define i32 @main() {
entry:
  %a = load volatile i32, ptr @sink_i32, align 4
  %r0 = call i32 @protected_sqabs_i32(i32 %a)
  store volatile i32 %r0, ptr @sink_i32, align 4
  %b = load volatile i64, ptr @sink_i64, align 8
  %r1 = call i64 @protected_sqabs_i64(i64 %b)
  store volatile i64 %r1, ptr @sink_i64, align 8
  %r2 = call i32 @protected_sqneg_i32(i32 %a)
  store volatile i32 %r2, ptr @sink_i32, align 4
  %r3 = call i64 @protected_sqneg_i64(i64 %b)
  store volatile i64 %r3, ptr @sink_i64, align 8
  %r4 = call i32 @protected_sqabs_smin()
  store volatile i32 %r4, ptr @sink_i32, align 4
  ret i32 0
}

; SKIP-DAG: Skipping VMP on unsupported_i8: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_i16: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_v1i64: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_sve: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_noreturn: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_returns_twice: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_sret: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_sqabs_i32:
; SKIP-NOT: Skipping VMP on protected_sqabs_i64:
; SKIP-NOT: Skipping VMP on protected_sqneg_i32:
; SKIP-NOT: Skipping VMP on protected_sqneg_i64:
; SKIP-NOT: Skipping VMP on protected_sqabs_smin:

; VIRT: define i32 @protected_sqabs_i32({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.neon.sqabs.i32(
; VIRT: define i64 @protected_sqabs_i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.aarch64.neon.sqabs.i64(
; VIRT: define i32 @protected_sqneg_i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.neon.sqneg.i32(
; VIRT: define i64 @protected_sqneg_i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.aarch64.neon.sqneg.i64(
; VIRT: define i32 @protected_sqabs_smin({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.neon.sqabs.i32(
; VIRT: define {{.*}} @unsupported_i8({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; AARCH64-ASM-DAG: {{^[[:space:]]*}}sqabs{{[ \t]}}
; AARCH64-ASM-DAG: {{^[[:space:]]*}}sqneg{{[ \t]}}
; HOST: Skipping VMP: only AArch64 targets are supported
