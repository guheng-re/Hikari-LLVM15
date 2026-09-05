; Restricted AArch64 NEON shift-insert via CallDescriptor /
; vector VRegs (no new opcode):
;   llvm.aarch64.neon.vsli / vsri
;     AdvSIMD_3VectorArg_Scalar: anyvector (match, match, i32)
;     Clang vsli_n / vsri_n are WInst -> these IDs, not generic
;     shl/lshr/or.  ISel LowerINTRINSIC_WO_CHAIN to VSLI/VSRI then
;     SIMDVectorL/RShiftBHSDTied, baseline HasNEON:
;       <8 x i8> / <16 x i8> / <4 x i16> / <8 x i16>
;       <2 x i32> / <4 x i32> / <2 x i64>
;     vsli imm vecshiftL: 0 .. EltBits-1
;     vsri imm vecshiftR: 1 .. EltBits
; The i32 shift is not ImmArg; it stays on CallDescriptor
; ImmediateArguments.  v1i64 is the scalar SLId/SRId form.
; Generic or+shift that ISel may fold to SLI is already the
; ordinary integer-vector surface.  Exact C non-vararg.
; Ordinary tail accepted and replayed as non-tail; see vmp-direct-call-tail-eligibility-semantic.ll.  No last-token gate.
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
declare <8 x i8> @llvm.aarch64.neon.vsli.v8i8(<8 x i8>, <8 x i8>, i32)
declare <16 x i8> @llvm.aarch64.neon.vsli.v16i8(<16 x i8>, <16 x i8>, i32)
declare <4 x i16> @llvm.aarch64.neon.vsli.v4i16(<4 x i16>, <4 x i16>, i32)
declare <2 x i64> @llvm.aarch64.neon.vsli.v2i64(<2 x i64>, <2 x i64>, i32)
declare <8 x i8> @llvm.aarch64.neon.vsri.v8i8(<8 x i8>, <8 x i8>, i32)
declare <8 x i16> @llvm.aarch64.neon.vsri.v8i16(<8 x i16>, <8 x i16>, i32)
declare <4 x i32> @llvm.aarch64.neon.vsri.v4i32(<4 x i32>, <4 x i32>, i32)
declare <2 x i32> @llvm.aarch64.neon.vsri.v2i32(<2 x i32>, <2 x i32>, i32)
declare <1 x i64> @llvm.aarch64.neon.vsli.v1i64(<1 x i64>, <1 x i64>, i32)
declare <4 x i8> @llvm.aarch64.neon.vsli.v4i8(<4 x i8>, <4 x i8>, i32)
declare <vscale x 16 x i8> @llvm.aarch64.sve.sli.nxv16i8(<vscale x 16 x i8>, <vscale x 16 x i8>, i32)

@sink_v8i8 = global <8 x i8> zeroinitializer, align 8
@sink_v16i8 = global <16 x i8> zeroinitializer, align 16
@sink_v4i16 = global <4 x i16> zeroinitializer, align 8
@sink_v8i16 = global <8 x i16> zeroinitializer, align 16
@sink_v2i32 = global <2 x i32> zeroinitializer, align 8
@sink_v4i32 = global <4 x i32> zeroinitializer, align 16
@sink_v2i64 = global <2 x i64> zeroinitializer, align 16

define <8 x i8> @protected_vsli_v8i8(<8 x i8> %d, <8 x i8> %s) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i8> @llvm.aarch64.neon.vsli.v8i8(<8 x i8> %d, <8 x i8> %s, i32 0)
  ret <8 x i8> %r
}

define <16 x i8> @protected_vsli_v16i8(<16 x i8> %d, <16 x i8> %s) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <16 x i8> @llvm.aarch64.neon.vsli.v16i8(<16 x i8> %d, <16 x i8> %s, i32 7)
  ret <16 x i8> %r
}

define <4 x i16> @protected_vsli_v4i16(<4 x i16> %d, <4 x i16> %s) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i16> @llvm.aarch64.neon.vsli.v4i16(<4 x i16> %d, <4 x i16> %s, i32 1)
  ret <4 x i16> %r
}

define <2 x i64> @protected_vsli_v2i64(<2 x i64> %d, <2 x i64> %s) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.aarch64.neon.vsli.v2i64(<2 x i64> %d, <2 x i64> %s, i32 63)
  ret <2 x i64> %r
}

define <8 x i8> @protected_vsri_v8i8(<8 x i8> %d, <8 x i8> %s) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i8> @llvm.aarch64.neon.vsri.v8i8(<8 x i8> %d, <8 x i8> %s, i32 1)
  ret <8 x i8> %r
}

define <8 x i16> @protected_vsri_v8i16(<8 x i16> %d, <8 x i16> %s) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i16> @llvm.aarch64.neon.vsri.v8i16(<8 x i16> %d, <8 x i16> %s, i32 16)
  ret <8 x i16> %r
}

define <4 x i32> @protected_vsri_v4i32(<4 x i32> %d, <4 x i32> %s) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.vsri.v4i32(<4 x i32> %d, <4 x i32> %s, i32 8)
  ret <4 x i32> %r
}

define <2 x i32> @protected_vsri_v2i32(<2 x i32> %d, <2 x i32> %s) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i32> @llvm.aarch64.neon.vsri.v2i32(<2 x i32> %d, <2 x i32> %s, i32 32)
  ret <2 x i32> %r
}

; ----- negatives: selected, not virtualized -----

define <8 x i8> @unsupported_dynamic(<8 x i8> %d, <8 x i8> %s, i32 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i8> @llvm.aarch64.neon.vsli.v8i8(<8 x i8> %d, <8 x i8> %s, i32 %n)
  ret <8 x i8> %r
}

define <8 x i8> @unsupported_vsli_imm8(<8 x i8> %d, <8 x i8> %s) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i8> @llvm.aarch64.neon.vsli.v8i8(<8 x i8> %d, <8 x i8> %s, i32 8)
  ret <8 x i8> %r
}

define <8 x i8> @unsupported_vsri_imm0(<8 x i8> %d, <8 x i8> %s) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i8> @llvm.aarch64.neon.vsri.v8i8(<8 x i8> %d, <8 x i8> %s, i32 0)
  ret <8 x i8> %r
}

define <1 x i64> @unsupported_v1i64(<1 x i64> %d, <1 x i64> %s) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <1 x i64> @llvm.aarch64.neon.vsli.v1i64(<1 x i64> %d, <1 x i64> %s, i32 1)
  ret <1 x i64> %r
}

define <4 x i8> @unsupported_v4i8(<4 x i8> %d, <4 x i8> %s) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i8> @llvm.aarch64.neon.vsli.v4i8(<4 x i8> %d, <4 x i8> %s, i32 1)
  ret <4 x i8> %r
}

define <vscale x 16 x i8> @unsupported_sve_sli(<vscale x 16 x i8> %d, <vscale x 16 x i8> %s) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 16 x i8> @llvm.aarch64.sve.sli.nxv16i8(<vscale x 16 x i8> %d, <vscale x 16 x i8> %s, i32 1)
  ret <vscale x 16 x i8> %r
}

define <8 x i8> @unsupported_fastcc(<8 x i8> %d, <8 x i8> %s) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc <8 x i8> @llvm.aarch64.neon.vsli.v8i8(<8 x i8> %d, <8 x i8> %s, i32 1)
  ret <8 x i8> %r
}


define <8 x i8> @unsupported_musttail(<8 x i8> %d, <8 x i8> %s) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call <8 x i8> @llvm.aarch64.neon.vsli.v8i8(<8 x i8> %d, <8 x i8> %s, i32 1)
  ret <8 x i8> %r
}

define <8 x i8> @unsupported_bundle(<8 x i8> %d, <8 x i8> %s) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i8> @llvm.aarch64.neon.vsli.v8i8(<8 x i8> %d, <8 x i8> %s, i32 1) [ "deopt"(i32 0) ]
  ret <8 x i8> %r
}

define <8 x i8> @unsupported_noreturn(<8 x i8> %d, <8 x i8> %s) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i8> @llvm.aarch64.neon.vsli.v8i8(<8 x i8> %d, <8 x i8> %s, i32 1) noreturn
  ret <8 x i8> %r
}

define <8 x i8> @unsupported_returns_twice(<8 x i8> %d, <8 x i8> %s) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i8> @llvm.aarch64.neon.vsli.v8i8(<8 x i8> %d, <8 x i8> %s, i32 1) returns_twice
  ret <8 x i8> %r
}

define i32 @main() {
entry:
  %a8 = load volatile <8 x i8>, ptr @sink_v8i8, align 8
  %b8 = load volatile <8 x i8>, ptr @sink_v8i8, align 8
  %r0 = call <8 x i8> @protected_vsli_v8i8(<8 x i8> %a8, <8 x i8> %b8)
  store volatile <8 x i8> %r0, ptr @sink_v8i8, align 8
  %a16 = load volatile <16 x i8>, ptr @sink_v16i8, align 16
  %b16 = load volatile <16 x i8>, ptr @sink_v16i8, align 16
  %r1 = call <16 x i8> @protected_vsli_v16i8(<16 x i8> %a16, <16 x i8> %b16)
  store volatile <16 x i8> %r1, ptr @sink_v16i8, align 16
  %a4h = load volatile <4 x i16>, ptr @sink_v4i16, align 8
  %b4h = load volatile <4 x i16>, ptr @sink_v4i16, align 8
  %r2 = call <4 x i16> @protected_vsli_v4i16(<4 x i16> %a4h, <4 x i16> %b4h)
  store volatile <4 x i16> %r2, ptr @sink_v4i16, align 8
  %a2d = load volatile <2 x i64>, ptr @sink_v2i64, align 16
  %b2d = load volatile <2 x i64>, ptr @sink_v2i64, align 16
  %r3 = call <2 x i64> @protected_vsli_v2i64(<2 x i64> %a2d, <2 x i64> %b2d)
  store volatile <2 x i64> %r3, ptr @sink_v2i64, align 16
  %r4 = call <8 x i8> @protected_vsri_v8i8(<8 x i8> %a8, <8 x i8> %b8)
  store volatile <8 x i8> %r4, ptr @sink_v8i8, align 8
  %a8h = load volatile <8 x i16>, ptr @sink_v8i16, align 16
  %b8h = load volatile <8 x i16>, ptr @sink_v8i16, align 16
  %r5 = call <8 x i16> @protected_vsri_v8i16(<8 x i16> %a8h, <8 x i16> %b8h)
  store volatile <8 x i16> %r5, ptr @sink_v8i16, align 16
  %a4s = load volatile <4 x i32>, ptr @sink_v4i32, align 16
  %b4s = load volatile <4 x i32>, ptr @sink_v4i32, align 16
  %r6 = call <4 x i32> @protected_vsri_v4i32(<4 x i32> %a4s, <4 x i32> %b4s)
  store volatile <4 x i32> %r6, ptr @sink_v4i32, align 16
  %a2s = load volatile <2 x i32>, ptr @sink_v2i32, align 8
  %b2s = load volatile <2 x i32>, ptr @sink_v2i32, align 8
  %r7 = call <2 x i32> @protected_vsri_v2i32(<2 x i32> %a2s, <2 x i32> %b2s)
  store volatile <2 x i32> %r7, ptr @sink_v2i32, align 8
  ret i32 0
}

; SKIP-DAG: Skipping VMP on unsupported_dynamic: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_vsli_imm8: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_vsri_imm0: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_v1i64: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_v4i8: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_sve_sli: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_noreturn: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_returns_twice: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_vsli_v8i8:
; SKIP-NOT: Skipping VMP on protected_vsli_v16i8:
; SKIP-NOT: Skipping VMP on protected_vsli_v4i16:
; SKIP-NOT: Skipping VMP on protected_vsli_v2i64:
; SKIP-NOT: Skipping VMP on protected_vsri_v8i8:
; SKIP-NOT: Skipping VMP on protected_vsri_v8i16:
; SKIP-NOT: Skipping VMP on protected_vsri_v4i32:
; SKIP-NOT: Skipping VMP on protected_vsri_v2i32:

; VIRT: define <8 x i8> @protected_vsli_v8i8({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x i8> @llvm.aarch64.neon.vsli.v8i8(
; VIRT: define <16 x i8> @protected_vsli_v16i8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <16 x i8> @llvm.aarch64.neon.vsli.v16i8(
; VIRT: define <4 x i16> @protected_vsli_v4i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <2 x i64> @protected_vsli_v2i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i64> @llvm.aarch64.neon.vsli.v2i64(
; VIRT: define <8 x i8> @protected_vsri_v8i8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x i8> @llvm.aarch64.neon.vsri.v8i8(
; VIRT: define <8 x i16> @protected_vsri_v8i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x i16> @llvm.aarch64.neon.vsri.v8i16(
; VIRT: define <4 x i32> @protected_vsri_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <2 x i32> @protected_vsri_v2i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i32> @llvm.aarch64.neon.vsri.v2i32(
; VIRT: define {{.*}} @unsupported_dynamic({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; AARCH64-ASM-DAG: {{^[[:space:]]*}}sli{{[ \t]}}{{v[0-9]+}}.8b
; AARCH64-ASM-DAG: {{^[[:space:]]*}}sli{{[ \t]}}{{v[0-9]+}}.16b
; AARCH64-ASM-DAG: {{^[[:space:]]*}}sli{{[ \t]}}{{v[0-9]+}}.4h
; AARCH64-ASM-DAG: {{^[[:space:]]*}}sli{{[ \t]}}{{v[0-9]+}}.2d
; AARCH64-ASM-DAG: {{^[[:space:]]*}}sri{{[ \t]}}{{v[0-9]+}}.8b
; AARCH64-ASM-DAG: {{^[[:space:]]*}}sri{{[ \t]}}{{v[0-9]+}}.8h
; AARCH64-ASM-DAG: {{^[[:space:]]*}}sri{{[ \t]}}{{v[0-9]+}}.4s
; AARCH64-ASM-DAG: {{^[[:space:]]*}}sri{{[ \t]}}{{v[0-9]+}}.2s
; HOST: Skipping VMP: only AArch64 targets are supported
