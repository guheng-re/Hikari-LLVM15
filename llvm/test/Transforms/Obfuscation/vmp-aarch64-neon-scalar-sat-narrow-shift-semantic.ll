; Restricted AArch64 scalar saturating narrowing shift via
; CallDescriptor / integer VRegs + ImmediateArguments:
;   llvm.aarch64.neon.sqshrn / uqshrn
;   llvm.aarch64.neon.sqrshrn / uqrshrn
;   llvm.aarch64.neon.sqshrun / sqrshrun
;     AdvSIMD_2Arg_Scalar_Narrow: anyint (extended, i32)
;     ISel SIMDScalarRShiftBHS, baseline HasNEON:
;       i32(i64, i32)  vecshiftR32 imm 1..32
; i16(i32)/i8(i16) encodings exist but have empty ISel
; patterns.  Clang vqshrnd_n_s64 / vqshrnd_n_u64 /
; vqrshrnd_n_s64 / vqshrund_n_s64.  vqshrns_n_s32 /
; vqshrnh_n_s16 Use64BitVectors.  Must not lower to
; scalar.sqxtn or generic lshr+trunc.  sqshrun/sqrshrun
; signed->unsigned: negatives saturate to 0.  Amount is
; not ImmArg; stays on ImmediateArguments.  Vector
; sat-narrow-shift is
; vmp-aarch64-neon-sat-narrow-shift-semantic.ll and must
; not stay here as a well-formed skip.  rshrn stays out.
; No last-token.  No FMF.  Command-line -mattr never
; consulted.  Exact C non-vararg.  Ordinary tail accepted and replayed as non-tail; see vmp-direct-call-tail-eligibility-semantic.ll.  No new opcode.
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
declare i32 @llvm.aarch64.neon.sqshrn.i32(i64, i32)
declare i32 @llvm.aarch64.neon.uqshrn.i32(i64, i32)
declare i32 @llvm.aarch64.neon.sqrshrn.i32(i64, i32)
declare i32 @llvm.aarch64.neon.uqrshrn.i32(i64, i32)
declare i32 @llvm.aarch64.neon.sqshrun.i32(i64, i32)
declare i32 @llvm.aarch64.neon.sqrshrun.i32(i64, i32)
declare i16 @llvm.aarch64.neon.sqshrn.i16(i32, i32)
declare <vscale x 16 x i8> @llvm.aarch64.sve.sqshrnb.nxv8i16(<vscale x 8 x i16>, i32)

@sink_i32 = global i32 0, align 4
@sink_i64 = global i64 0, align 8

define i32 @protected_sqshrn_i32(i64 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.sqshrn.i32(i64 %a, i32 3)
  ret i32 %r
}

define i32 @protected_uqshrn_i32(i64 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.uqshrn.i32(i64 %a, i32 3)
  ret i32 %r
}

define i32 @protected_sqrshrn_i32(i64 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.sqrshrn.i32(i64 %a, i32 1)
  ret i32 %r
}

define i32 @protected_uqrshrn_i32(i64 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.uqrshrn.i32(i64 %a, i32 1)
  ret i32 %r
}

define i32 @protected_sqshrun_i32(i64 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.sqshrun.i32(i64 %a, i32 1)
  ret i32 %r
}

define i32 @protected_sqrshrun_i32(i64 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.sqrshrun.i32(i64 %a, i32 1)
  ret i32 %r
}

define i32 @protected_sqshrn_imm32(i64 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.sqshrn.i32(i64 %a, i32 32)
  ret i32 %r
}

; signed->unsigned: -1 saturates to 0; stays live sqshrun.
define i32 @protected_sqshrun_neg() noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.sqshrun.i32(i64 -1, i32 1)
  ret i32 %r
}

; ----- negatives: selected, not virtualized -----

define i16 @unsupported_i16(i32 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i16 @llvm.aarch64.neon.sqshrn.i16(i32 %a, i32 1)
  ret i16 %r
}

define i32 @unsupported_dynamic(i64 %a, i32 %amt) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.sqshrn.i32(i64 %a, i32 %amt)
  ret i32 %r
}

define i32 @unsupported_imm0(i64 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.sqshrn.i32(i64 %a, i32 0)
  ret i32 %r
}

define i32 @unsupported_oor(i64 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.sqshrn.i32(i64 %a, i32 33)
  ret i32 %r
}

define <vscale x 16 x i8> @unsupported_sve(<vscale x 8 x i16> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 16 x i8> @llvm.aarch64.sve.sqshrnb.nxv8i16(<vscale x 8 x i16> %a, i32 2)
  ret <vscale x 16 x i8> %r
}

define i32 @unsupported_fastcc(i64 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc i32 @llvm.aarch64.neon.sqshrn.i32(i64 %a, i32 3)
  ret i32 %r
}


define i32 @unsupported_musttail(i64 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call i32 @llvm.aarch64.neon.sqshrn.i32(i64 %a, i32 3)
  ret i32 %r
}

define i32 @unsupported_bundle(i64 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.sqshrn.i32(i64 %a, i32 3) [ "deopt"(i32 0) ]
  ret i32 %r
}

define i32 @unsupported_noreturn(i64 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.sqshrn.i32(i64 %a, i32 3) noreturn
  ret i32 %r
}

define i32 @unsupported_returns_twice(i64 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.sqshrn.i32(i64 %a, i32 3) returns_twice
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
  %a = load volatile i64, ptr @sink_i64, align 8
  %r0 = call i32 @protected_sqshrn_i32(i64 %a)
  store volatile i32 %r0, ptr @sink_i32, align 4
  %r1 = call i32 @protected_uqshrn_i32(i64 %a)
  store volatile i32 %r1, ptr @sink_i32, align 4
  %r2 = call i32 @protected_sqrshrn_i32(i64 %a)
  store volatile i32 %r2, ptr @sink_i32, align 4
  %r3 = call i32 @protected_uqrshrn_i32(i64 %a)
  store volatile i32 %r3, ptr @sink_i32, align 4
  %r4 = call i32 @protected_sqshrun_i32(i64 %a)
  store volatile i32 %r4, ptr @sink_i32, align 4
  %r5 = call i32 @protected_sqrshrun_i32(i64 %a)
  store volatile i32 %r5, ptr @sink_i32, align 4
  %r6 = call i32 @protected_sqshrn_imm32(i64 %a)
  store volatile i32 %r6, ptr @sink_i32, align 4
  %r7 = call i32 @protected_sqshrun_neg()
  store volatile i32 %r7, ptr @sink_i32, align 4
  ret i32 0
}

; SKIP-DAG: Skipping VMP on unsupported_i16: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_dynamic: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_imm0: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_oor: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_sve: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_noreturn: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_returns_twice: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_sret: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_sqshrn_i32:
; SKIP-NOT: Skipping VMP on protected_uqshrn_i32:
; SKIP-NOT: Skipping VMP on protected_sqrshrn_i32:
; SKIP-NOT: Skipping VMP on protected_uqrshrn_i32:
; SKIP-NOT: Skipping VMP on protected_sqshrun_i32:
; SKIP-NOT: Skipping VMP on protected_sqrshrun_i32:
; SKIP-NOT: Skipping VMP on protected_sqshrn_imm32:
; SKIP-NOT: Skipping VMP on protected_sqshrun_neg:

; VIRT: define i32 @protected_sqshrn_i32({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.neon.sqshrn.i32({{.*}} i32 3)
; VIRT: define i32 @protected_uqshrn_i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.neon.uqshrn.i32({{.*}} i32 3)
; VIRT: define i32 @protected_sqrshrn_i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.neon.sqrshrn.i32({{.*}} i32 1)
; VIRT: define i32 @protected_uqrshrn_i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.neon.uqrshrn.i32({{.*}} i32 1)
; VIRT: define i32 @protected_sqshrun_i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.neon.sqshrun.i32({{.*}} i32 1)
; VIRT: define i32 @protected_sqrshrun_i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.neon.sqrshrun.i32({{.*}} i32 1)
; VIRT: define i32 @protected_sqshrn_imm32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.neon.sqshrn.i32({{.*}} i32 32)
; VIRT: define i32 @protected_sqshrun_neg({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.neon.sqshrun.i32({{.*}} i32 1)
; VIRT: define {{.*}} @unsupported_i16({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; AARCH64-ASM-DAG: {{^[[:space:]]*}}sqshrn{{[ \t]}}
; AARCH64-ASM-DAG: {{^[[:space:]]*}}uqshrn{{[ \t]}}
; AARCH64-ASM-DAG: {{^[[:space:]]*}}sqrshrn{{[ \t]}}
; AARCH64-ASM-DAG: {{^[[:space:]]*}}uqrshrn{{[ \t]}}
; AARCH64-ASM-DAG: {{^[[:space:]]*}}sqshrun{{[ \t]}}
; AARCH64-ASM-DAG: {{^[[:space:]]*}}sqrshrun{{[ \t]}}
; HOST: Skipping VMP: only AArch64 targets are supported
