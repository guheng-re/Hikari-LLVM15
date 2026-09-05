; Restricted AArch64 scalar signed-to-unsigned saturating left
; shift via CallDescriptor / integer VRegs + ImmediateArguments:
;   llvm.aarch64.neon.sqshlu
;     AdvSIMD_2IntArg: anyint (match, match)
;     ISel tryCombineShiftImm -> SQSHLU_I, then
;     SIMDScalarLShiftBHSD, baseline HasNEON:
;       i32(i32, i32 imm 0..31) / i64(i64, i64 imm 0..63)
; i8/i16 encodings exist but have empty ISel patterns.  Clang
; vqshlus_n_s32 / vqshlud_n_s64.  vqshlub_n_s8 / vqshluh_n_s16
; Use64BitVectors.  No register-form SQSHLU: dynamic / OOB /
; negative cannot select.  Must not lower to sqshl / ushl /
; generic shl.  Negatives saturate to 0.  Amount is not ImmArg
; but stays on ImmediateArguments.  Vector sqshlu is
; vmp-aarch64-neon-sqshlu-semantic.ll and must not stay here
; as a well-formed skip.  v1i64 stays out.  No last-token.
; No FMF.  Command-line -mattr never consulted.  Exact C
; non-vararg.  Ordinary tail accepted and replayed as non-tail; see vmp-direct-call-tail-eligibility-semantic.ll.
; No new opcode.
;
; Host cannot select this AArch64 intrinsic; no lli.
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
declare i32 @llvm.aarch64.neon.sqshlu.i32(i32, i32)
declare i64 @llvm.aarch64.neon.sqshlu.i64(i64, i64)
declare i8 @llvm.aarch64.neon.sqshlu.i8(i8, i8)
declare i16 @llvm.aarch64.neon.sqshlu.i16(i16, i16)
declare <1 x i64> @llvm.aarch64.neon.sqshlu.v1i64(<1 x i64>, <1 x i64>)
declare <vscale x 16 x i8> @llvm.aarch64.sve.sqshlu.nxv16i8(<vscale x 16 x i1>, <vscale x 16 x i8>, i32)

@sink_i32 = global i32 0, align 4
@sink_i64 = global i64 0, align 8

define i32 @protected_sqshlu_i32(i32 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.sqshlu.i32(i32 %a, i32 1)
  ret i32 %r
}

define i64 @protected_sqshlu_i64(i64 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.aarch64.neon.sqshlu.i64(i64 %a, i64 1)
  ret i64 %r
}

define i32 @protected_sqshlu_imm0(i32 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.sqshlu.i32(i32 %a, i32 0)
  ret i32 %r
}

define i32 @protected_sqshlu_imm31(i32 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.sqshlu.i32(i32 %a, i32 31)
  ret i32 %r
}

define i64 @protected_sqshlu_imm63(i64 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.aarch64.neon.sqshlu.i64(i64 %a, i64 63)
  ret i64 %r
}

; INT_MIN << 1 saturates to 0; stays live sqshlu (not folded).
define i32 @protected_sqshlu_smin() noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.sqshlu.i32(i32 -2147483648, i32 1)
  ret i32 %r
}

; ----- negatives: selected, not virtualized -----

define i8 @unsupported_i8(i8 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i8 @llvm.aarch64.neon.sqshlu.i8(i8 %a, i8 1)
  ret i8 %r
}

define i16 @unsupported_i16(i16 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i16 @llvm.aarch64.neon.sqshlu.i16(i16 %a, i16 1)
  ret i16 %r
}

define <1 x i64> @unsupported_v1i64(<1 x i64> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <1 x i64> @llvm.aarch64.neon.sqshlu.v1i64(<1 x i64> %a, <1 x i64> <i64 1>)
  ret <1 x i64> %r
}

define i32 @unsupported_dynamic(i32 %a, i32 %amt) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.sqshlu.i32(i32 %a, i32 %amt)
  ret i32 %r
}

define i32 @unsupported_oor(i32 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.sqshlu.i32(i32 %a, i32 32)
  ret i32 %r
}

define i32 @unsupported_negimm(i32 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.sqshlu.i32(i32 %a, i32 -1)
  ret i32 %r
}

define <vscale x 16 x i8> @unsupported_sve(<vscale x 16 x i1> %pg, <vscale x 16 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 16 x i8> @llvm.aarch64.sve.sqshlu.nxv16i8(<vscale x 16 x i1> %pg, <vscale x 16 x i8> %a, i32 2)
  ret <vscale x 16 x i8> %r
}

define i32 @unsupported_fastcc(i32 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc i32 @llvm.aarch64.neon.sqshlu.i32(i32 %a, i32 1)
  ret i32 %r
}


define i32 @unsupported_musttail(i32 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call i32 @llvm.aarch64.neon.sqshlu.i32(i32 %a, i32 1)
  ret i32 %r
}

define i32 @unsupported_bundle(i32 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.sqshlu.i32(i32 %a, i32 1) [ "deopt"(i32 0) ]
  ret i32 %r
}

define i32 @unsupported_noreturn(i32 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.sqshlu.i32(i32 %a, i32 1) noreturn
  ret i32 %r
}

define i32 @unsupported_returns_twice(i32 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.sqshlu.i32(i32 %a, i32 1) returns_twice
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
  %r0 = call i32 @protected_sqshlu_i32(i32 %a)
  store volatile i32 %r0, ptr @sink_i32, align 4
  %b = load volatile i64, ptr @sink_i64, align 8
  %r1 = call i64 @protected_sqshlu_i64(i64 %b)
  store volatile i64 %r1, ptr @sink_i64, align 8
  %r2 = call i32 @protected_sqshlu_imm0(i32 %a)
  store volatile i32 %r2, ptr @sink_i32, align 4
  %r3 = call i32 @protected_sqshlu_imm31(i32 %a)
  store volatile i32 %r3, ptr @sink_i32, align 4
  %r4 = call i64 @protected_sqshlu_imm63(i64 %b)
  store volatile i64 %r4, ptr @sink_i64, align 8
  %r5 = call i32 @protected_sqshlu_smin()
  store volatile i32 %r5, ptr @sink_i32, align 4
  ret i32 0
}

; SKIP-DAG: Skipping VMP on unsupported_i8: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_i16: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_v1i64: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_dynamic: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_oor: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_negimm: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_sve: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_noreturn: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_returns_twice: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_sret: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_sqshlu_i32:
; SKIP-NOT: Skipping VMP on protected_sqshlu_i64:
; SKIP-NOT: Skipping VMP on protected_sqshlu_imm0:
; SKIP-NOT: Skipping VMP on protected_sqshlu_imm31:
; SKIP-NOT: Skipping VMP on protected_sqshlu_imm63:
; SKIP-NOT: Skipping VMP on protected_sqshlu_smin:

; VIRT: define i32 @protected_sqshlu_i32({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.neon.sqshlu.i32({{.*}} i32 1)
; VIRT: define i64 @protected_sqshlu_i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.aarch64.neon.sqshlu.i64({{.*}} i64 1)
; VIRT: define i32 @protected_sqshlu_imm0({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.neon.sqshlu.i32({{.*}} i32 0)
; VIRT: define i32 @protected_sqshlu_imm31({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.neon.sqshlu.i32({{.*}} i32 31)
; VIRT: define i64 @protected_sqshlu_imm63({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.aarch64.neon.sqshlu.i64({{.*}} i64 63)
; VIRT: define i32 @protected_sqshlu_smin({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.neon.sqshlu.i32({{.*}} i32 1)
; VIRT: define {{.*}} @unsupported_i8({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; AARCH64-ASM-DAG: {{^[[:space:]]*}}sqshlu{{[ \t]}}
; HOST: Skipping VMP: only AArch64 targets are supported
