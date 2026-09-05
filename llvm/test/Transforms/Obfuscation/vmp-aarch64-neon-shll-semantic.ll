; Restricted AArch64 NEON widening left shift via CallDescriptor /
; vector VRegs (no sext/zext+shl rewrite, no new opcode):
;   llvm.aarch64.neon.shll
;     AdvSIMD_2VectorArg_Scalar_Wide_BySize: result (truncated)
;     ISel SHLL low-half, baseline HasNEON:
;       <8 x i16>(<8 x i8>)    shll #8
;       <4 x i32>(<4 x i16>)   shll #16
;       <2 x i64>(<2 x i32>)   shll #32
;   llvm.aarch64.neon.sshll / ushll
;     AdvSIMD_2VectorArg_Scalar_Wide: result (truncated, i32)
;     ISel SSHLL/USHLL vecshiftL8/16/32:
;       same three pairs; imm 0..7 / 0..15 / 0..31
; The i32 shift is not ImmArg; it stays a true ConstantInt on
; ImmediateArguments.  No shll2/sshll2/ushll2 IR ID: high-half is
; extract_high / shufflevector + the same low-half ID.  Wide
; sources (v16i8/v8i16/v4i32) are not accepted on the ID itself.
; Exact C non-vararg.  Ordinary tail accepted and replayed as non-tail; see vmp-direct-call-tail-eligibility-semantic.ll.
; No last-token gate.  Dynamic / OOR / negative immediates stay out.
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
declare <8 x i16> @llvm.aarch64.neon.shll.v8i16(<8 x i8>)
declare <4 x i32> @llvm.aarch64.neon.shll.v4i32(<4 x i16>)
declare <2 x i64> @llvm.aarch64.neon.shll.v2i64(<2 x i32>)
declare <8 x i16> @llvm.aarch64.neon.sshll.v8i16(<8 x i8>, i32)
declare <4 x i32> @llvm.aarch64.neon.sshll.v4i32(<4 x i16>, i32)
declare <2 x i64> @llvm.aarch64.neon.sshll.v2i64(<2 x i32>, i32)
declare <8 x i16> @llvm.aarch64.neon.ushll.v8i16(<8 x i8>, i32)
declare <4 x i32> @llvm.aarch64.neon.ushll.v4i32(<4 x i16>, i32)
declare <2 x i64> @llvm.aarch64.neon.ushll.v2i64(<2 x i32>, i32)
declare <16 x i16> @llvm.aarch64.neon.sshll.v16i16(<16 x i8>, i32)
declare <4 x i16> @llvm.aarch64.neon.sshll.v4i16(<4 x i8>, i32)
declare <vscale x 8 x i16> @llvm.aarch64.sve.sshllb.nxv8i16(<vscale x 16 x i8>, i32)

@sink_v8i8 = global <8 x i8> zeroinitializer, align 8
@sink_v16i8 = global <16 x i8> zeroinitializer, align 16
@sink_v4i16 = global <4 x i16> zeroinitializer, align 8
@sink_v2i32 = global <2 x i32> zeroinitializer, align 8
@sink_v8i16 = global <8 x i16> zeroinitializer, align 16
@sink_v4i32 = global <4 x i32> zeroinitializer, align 16
@sink_v2i64 = global <2 x i64> zeroinitializer, align 16

define <8 x i16> @protected_shll_v8i16(<8 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i16> @llvm.aarch64.neon.shll.v8i16(<8 x i8> %a)
  ret <8 x i16> %r
}

define <4 x i32> @protected_shll_v4i32(<4 x i16> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.shll.v4i32(<4 x i16> %a)
  ret <4 x i32> %r
}

define <2 x i64> @protected_shll_v2i64(<2 x i32> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.aarch64.neon.shll.v2i64(<2 x i32> %a)
  ret <2 x i64> %r
}

define <8 x i16> @protected_sshll_v8i16_0(<8 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i16> @llvm.aarch64.neon.sshll.v8i16(<8 x i8> %a, i32 0)
  ret <8 x i16> %r
}

define <8 x i16> @protected_sshll_v8i16_7(<8 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i16> @llvm.aarch64.neon.sshll.v8i16(<8 x i8> %a, i32 7)
  ret <8 x i16> %r
}

define <4 x i32> @protected_sshll_v4i32_15(<4 x i16> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.sshll.v4i32(<4 x i16> %a, i32 15)
  ret <4 x i32> %r
}

define <2 x i64> @protected_sshll_v2i64_31(<2 x i32> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.aarch64.neon.sshll.v2i64(<2 x i32> %a, i32 31)
  ret <2 x i64> %r
}

define <8 x i16> @protected_ushll_v8i16_7(<8 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i16> @llvm.aarch64.neon.ushll.v8i16(<8 x i8> %a, i32 7)
  ret <8 x i16> %r
}

define <4 x i32> @protected_ushll_v4i32_0(<4 x i16> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.ushll.v4i32(<4 x i16> %a, i32 0)
  ret <4 x i32> %r
}

define <2 x i64> @protected_ushll_v2i64_31(<2 x i32> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.aarch64.neon.ushll.v2i64(<2 x i32> %a, i32 31)
  ret <2 x i64> %r
}

; High-half is extract + the same low-half ID, not a wide-source ID.
define <8 x i16> @protected_sshll_high(<16 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %hi = shufflevector <16 x i8> %a, <16 x i8> %a, <8 x i32> <i32 8, i32 9, i32 10, i32 11, i32 12, i32 13, i32 14, i32 15>
  %r = call <8 x i16> @llvm.aarch64.neon.sshll.v8i16(<8 x i8> %hi, i32 1)
  ret <8 x i16> %r
}

define <8 x i16> @unsupported_dyn(<8 x i8> %a, i32 %s) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i16> @llvm.aarch64.neon.sshll.v8i16(<8 x i8> %a, i32 %s)
  ret <8 x i16> %r
}

define <8 x i16> @unsupported_oor8(<8 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i16> @llvm.aarch64.neon.sshll.v8i16(<8 x i8> %a, i32 8)
  ret <8 x i16> %r
}

define <4 x i32> @unsupported_oor16(<4 x i16> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.ushll.v4i32(<4 x i16> %a, i32 16)
  ret <4 x i32> %r
}

define <2 x i64> @unsupported_oor32(<2 x i32> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.aarch64.neon.sshll.v2i64(<2 x i32> %a, i32 32)
  ret <2 x i64> %r
}

define <8 x i16> @unsupported_neg(<8 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i16> @llvm.aarch64.neon.ushll.v8i16(<8 x i8> %a, i32 -1)
  ret <8 x i16> %r
}

define <16 x i16> @unsupported_wide(<16 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <16 x i16> @llvm.aarch64.neon.sshll.v16i16(<16 x i8> %a, i32 1)
  ret <16 x i16> %r
}

define <4 x i16> @unsupported_v4i8(<4 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i16> @llvm.aarch64.neon.sshll.v4i16(<4 x i8> %a, i32 1)
  ret <4 x i16> %r
}

define <vscale x 8 x i16> @unsupported_sve(<vscale x 16 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 8 x i16> @llvm.aarch64.sve.sshllb.nxv8i16(<vscale x 16 x i8> %a, i32 1)
  ret <vscale x 8 x i16> %r
}

define <8 x i16> @unsupported_fastcc(<8 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc <8 x i16> @llvm.aarch64.neon.sshll.v8i16(<8 x i8> %a, i32 1)
  ret <8 x i16> %r
}


define <8 x i16> @unsupported_musttail(<8 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call <8 x i16> @llvm.aarch64.neon.sshll.v8i16(<8 x i8> %a, i32 1)
  ret <8 x i16> %r
}

define <8 x i16> @unsupported_bundle(<8 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i16> @llvm.aarch64.neon.sshll.v8i16(<8 x i8> %a, i32 1) [ "deopt"(i32 0) ]
  ret <8 x i16> %r
}

define <8 x i16> @unsupported_noreturn(<8 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i16> @llvm.aarch64.neon.sshll.v8i16(<8 x i8> %a, i32 1) noreturn
  ret <8 x i16> %r
}

define <8 x i16> @unsupported_returns_twice(<8 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i16> @llvm.aarch64.neon.sshll.v8i16(<8 x i8> %a, i32 1) returns_twice
  ret <8 x i16> %r
}

define void @unsupported_sret(ptr sret(i32) %p, ptr byval(i32) %q) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @ext_sret_byval(ptr sret(i32) %p, ptr byval(i32) %q)
  ret void
}

define i32 @main() {
entry:
  %a8 = load volatile <8 x i8>, ptr @sink_v8i8, align 8
  %a16 = load volatile <4 x i16>, ptr @sink_v4i16, align 8
  %a32 = load volatile <2 x i32>, ptr @sink_v2i32, align 8
  %a16b = load volatile <16 x i8>, ptr @sink_v16i8, align 16
  %r0 = call <8 x i16> @protected_shll_v8i16(<8 x i8> %a8)
  store volatile <8 x i16> %r0, ptr @sink_v8i16, align 16
  %r1 = call <4 x i32> @protected_shll_v4i32(<4 x i16> %a16)
  store volatile <4 x i32> %r1, ptr @sink_v4i32, align 16
  %r2 = call <2 x i64> @protected_shll_v2i64(<2 x i32> %a32)
  store volatile <2 x i64> %r2, ptr @sink_v2i64, align 16
  %r3 = call <8 x i16> @protected_sshll_v8i16_0(<8 x i8> %a8)
  store volatile <8 x i16> %r3, ptr @sink_v8i16, align 16
  %r4 = call <8 x i16> @protected_sshll_v8i16_7(<8 x i8> %a8)
  store volatile <8 x i16> %r4, ptr @sink_v8i16, align 16
  %r5 = call <4 x i32> @protected_sshll_v4i32_15(<4 x i16> %a16)
  store volatile <4 x i32> %r5, ptr @sink_v4i32, align 16
  %r6 = call <2 x i64> @protected_sshll_v2i64_31(<2 x i32> %a32)
  store volatile <2 x i64> %r6, ptr @sink_v2i64, align 16
  %r7 = call <8 x i16> @protected_ushll_v8i16_7(<8 x i8> %a8)
  store volatile <8 x i16> %r7, ptr @sink_v8i16, align 16
  %r8 = call <4 x i32> @protected_ushll_v4i32_0(<4 x i16> %a16)
  store volatile <4 x i32> %r8, ptr @sink_v4i32, align 16
  %r9 = call <2 x i64> @protected_ushll_v2i64_31(<2 x i32> %a32)
  store volatile <2 x i64> %r9, ptr @sink_v2i64, align 16
  %r10 = call <8 x i16> @protected_sshll_high(<16 x i8> %a16b)
  store volatile <8 x i16> %r10, ptr @sink_v8i16, align 16
  ret i32 0
}

; SKIP-DAG: Skipping VMP on unsupported_dyn: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_oor8: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_oor16: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_oor32: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_neg: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_wide: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_v4i8: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_sve: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_noreturn: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_returns_twice: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_sret: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_shll_v8i16:
; SKIP-NOT: Skipping VMP on protected_shll_v4i32:
; SKIP-NOT: Skipping VMP on protected_shll_v2i64:
; SKIP-NOT: Skipping VMP on protected_sshll_v8i16_0:
; SKIP-NOT: Skipping VMP on protected_sshll_v8i16_7:
; SKIP-NOT: Skipping VMP on protected_sshll_v4i32_15:
; SKIP-NOT: Skipping VMP on protected_sshll_v2i64_31:
; SKIP-NOT: Skipping VMP on protected_ushll_v8i16_7:
; SKIP-NOT: Skipping VMP on protected_ushll_v4i32_0:
; SKIP-NOT: Skipping VMP on protected_ushll_v2i64_31:
; SKIP-NOT: Skipping VMP on protected_sshll_high:

; VIRT: define <8 x i16> @protected_shll_v8i16({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x i16> @llvm.aarch64.neon.shll.v8i16(
; VIRT: define <4 x i32> @protected_shll_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.aarch64.neon.shll.v4i32(
; VIRT: define <2 x i64> @protected_shll_v2i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i64> @llvm.aarch64.neon.shll.v2i64(
; VIRT: define <8 x i16> @protected_sshll_v8i16_0({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x i16> @llvm.aarch64.neon.sshll.v8i16({{.*}}, i32 0)
; VIRT: define <8 x i16> @protected_sshll_v8i16_7({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x i16> @llvm.aarch64.neon.sshll.v8i16({{.*}}, i32 7)
; VIRT: define <4 x i32> @protected_sshll_v4i32_15({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.aarch64.neon.sshll.v4i32({{.*}}, i32 15)
; VIRT: define <2 x i64> @protected_sshll_v2i64_31({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i64> @llvm.aarch64.neon.sshll.v2i64({{.*}}, i32 31)
; VIRT: define <8 x i16> @protected_ushll_v8i16_7({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x i16> @llvm.aarch64.neon.ushll.v8i16({{.*}}, i32 7)
; VIRT: define <4 x i32> @protected_ushll_v4i32_0({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.aarch64.neon.ushll.v4i32({{.*}}, i32 0)
; VIRT: define <2 x i64> @protected_ushll_v2i64_31({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i64> @llvm.aarch64.neon.ushll.v2i64({{.*}}, i32 31)
; VIRT: define <8 x i16> @protected_sshll_high({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x i16> @llvm.aarch64.neon.sshll.v8i16({{.*}}, i32 1)
; VIRT: define {{.*}} @unsupported_dyn({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; AARCH64-ASM-DAG: {{^[[:space:]]*}}shll{{[ \t]}}
; AARCH64-ASM-DAG: {{^[[:space:]]*}}sshll{{[ \t]}}
; AARCH64-ASM-DAG: {{^[[:space:]]*}}ushll{{[ \t]}}
; HOST: Skipping VMP: only AArch64 targets are supported
