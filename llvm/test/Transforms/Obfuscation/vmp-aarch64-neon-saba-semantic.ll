; Restricted AArch64 NEON absolute-difference accumulate.
; LLVM 15 has no llvm.aarch64.neon.saba / uaba IR IDs
; (IntrinsicsAArch64.td defines only SVE saba/uaba).  clang vaba is
; SOpInst OP_ABA: acc + vabd(a,b).  ISel SIMDThreeSameVectorBHSTied
; (baseline HasNEON) matches:
;   saba: add (acc, sabd(a,b))  v8i8 / v16i8 / v4i16 / v8i16 / v2i32 / v4i32
;   uaba: add (acc, uabd(a,b))  same widths
; Coverage is existing sabd/uabd CallDescriptor + VectorAdd.
; Do not invent CallDescriptor IDs.  SABAL/UABAL have no IR ID.
; Widening sabdl/uabdl is vmp-aarch64-neon-sabdl-semantic.ll.
; v2i64 / v4i8 / fabd / SVE stay out.  No new opcode.
;
; VReg replay splits the ISel saba idiom into sabd/uabd then add.
; Host cannot select the AArch64 abd intrinsic; no lli.
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
declare <8 x i8> @llvm.aarch64.neon.sabd.v8i8(<8 x i8>, <8 x i8>)
declare <16 x i8> @llvm.aarch64.neon.sabd.v16i8(<16 x i8>, <16 x i8>)
declare <4 x i16> @llvm.aarch64.neon.sabd.v4i16(<4 x i16>, <4 x i16>)
declare <8 x i16> @llvm.aarch64.neon.sabd.v8i16(<8 x i16>, <8 x i16>)
declare <2 x i32> @llvm.aarch64.neon.sabd.v2i32(<2 x i32>, <2 x i32>)
declare <4 x i32> @llvm.aarch64.neon.sabd.v4i32(<4 x i32>, <4 x i32>)
declare <8 x i8> @llvm.aarch64.neon.uabd.v8i8(<8 x i8>, <8 x i8>)
declare <16 x i8> @llvm.aarch64.neon.uabd.v16i8(<16 x i8>, <16 x i8>)
declare <4 x i16> @llvm.aarch64.neon.uabd.v4i16(<4 x i16>, <4 x i16>)
declare <8 x i16> @llvm.aarch64.neon.uabd.v8i16(<8 x i16>, <8 x i16>)
declare <2 x i32> @llvm.aarch64.neon.uabd.v2i32(<2 x i32>, <2 x i32>)
declare <4 x i32> @llvm.aarch64.neon.uabd.v4i32(<4 x i32>, <4 x i32>)
declare <2 x i64> @llvm.aarch64.neon.sabd.v2i64(<2 x i64>, <2 x i64>)
declare <4 x i8> @llvm.aarch64.neon.sabd.v4i8(<4 x i8>, <4 x i8>)
declare <8 x i32> @llvm.aarch64.neon.sabd.v8i32(<8 x i32>, <8 x i32>)

declare <vscale x 16 x i8> @llvm.aarch64.sve.saba.nxv16i8(<vscale x 16 x i8>, <vscale x 16 x i8>, <vscale x 16 x i8>)
declare <vscale x 8 x i16> @llvm.aarch64.sve.sabalb.nxv8i16(<vscale x 8 x i16>, <vscale x 16 x i8>, <vscale x 16 x i8>)

@sink_v8i8 = global <8 x i8> zeroinitializer, align 8
@sink_v16i8 = global <16 x i8> zeroinitializer, align 16
@sink_v4i16 = global <4 x i16> zeroinitializer, align 8
@sink_v8i16 = global <8 x i16> zeroinitializer, align 16
@sink_v2i32 = global <2 x i32> zeroinitializer, align 8
@sink_v4i32 = global <4 x i32> zeroinitializer, align 16

define <8 x i8> @protected_saba_v8i8(<8 x i8> %acc, <8 x i8> %a, <8 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %abd = call <8 x i8> @llvm.aarch64.neon.sabd.v8i8(<8 x i8> %a, <8 x i8> %b)
  %r = add <8 x i8> %acc, %abd
  ret <8 x i8> %r
}

define <16 x i8> @protected_saba_v16i8(<16 x i8> %acc, <16 x i8> %a, <16 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %abd = call <16 x i8> @llvm.aarch64.neon.sabd.v16i8(<16 x i8> %a, <16 x i8> %b)
  %r = add <16 x i8> %acc, %abd
  ret <16 x i8> %r
}

define <4 x i16> @protected_saba_v4i16(<4 x i16> %acc, <4 x i16> %a, <4 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %abd = call <4 x i16> @llvm.aarch64.neon.sabd.v4i16(<4 x i16> %a, <4 x i16> %b)
  %r = add <4 x i16> %acc, %abd
  ret <4 x i16> %r
}

define <8 x i16> @protected_saba_v8i16(<8 x i16> %acc, <8 x i16> %a, <8 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %abd = call <8 x i16> @llvm.aarch64.neon.sabd.v8i16(<8 x i16> %a, <8 x i16> %b)
  %r = add <8 x i16> %acc, %abd
  ret <8 x i16> %r
}

define <2 x i32> @protected_saba_v2i32(<2 x i32> %acc, <2 x i32> %a, <2 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %abd = call <2 x i32> @llvm.aarch64.neon.sabd.v2i32(<2 x i32> %a, <2 x i32> %b)
  %r = add <2 x i32> %acc, %abd
  ret <2 x i32> %r
}

define <4 x i32> @protected_saba_v4i32(<4 x i32> %acc, <4 x i32> %a, <4 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %abd = call <4 x i32> @llvm.aarch64.neon.sabd.v4i32(<4 x i32> %a, <4 x i32> %b)
  %r = add <4 x i32> %acc, %abd
  ret <4 x i32> %r
}

define <8 x i8> @protected_uaba_v8i8(<8 x i8> %acc, <8 x i8> %a, <8 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %abd = call <8 x i8> @llvm.aarch64.neon.uabd.v8i8(<8 x i8> %a, <8 x i8> %b)
  %r = add <8 x i8> %acc, %abd
  ret <8 x i8> %r
}

define <16 x i8> @protected_uaba_v16i8(<16 x i8> %acc, <16 x i8> %a, <16 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %abd = call <16 x i8> @llvm.aarch64.neon.uabd.v16i8(<16 x i8> %a, <16 x i8> %b)
  %r = add <16 x i8> %acc, %abd
  ret <16 x i8> %r
}

define <4 x i16> @protected_uaba_v4i16(<4 x i16> %acc, <4 x i16> %a, <4 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %abd = call <4 x i16> @llvm.aarch64.neon.uabd.v4i16(<4 x i16> %a, <4 x i16> %b)
  %r = add <4 x i16> %acc, %abd
  ret <4 x i16> %r
}

define <8 x i16> @protected_uaba_v8i16(<8 x i16> %acc, <8 x i16> %a, <8 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %abd = call <8 x i16> @llvm.aarch64.neon.uabd.v8i16(<8 x i16> %a, <8 x i16> %b)
  %r = add <8 x i16> %acc, %abd
  ret <8 x i16> %r
}

define <2 x i32> @protected_uaba_v2i32(<2 x i32> %acc, <2 x i32> %a, <2 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %abd = call <2 x i32> @llvm.aarch64.neon.uabd.v2i32(<2 x i32> %a, <2 x i32> %b)
  %r = add <2 x i32> %acc, %abd
  ret <2 x i32> %r
}

define <4 x i32> @protected_uaba_v4i32(<4 x i32> %acc, <4 x i32> %a, <4 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %abd = call <4 x i32> @llvm.aarch64.neon.uabd.v4i32(<4 x i32> %a, <4 x i32> %b)
  %r = add <4 x i32> %acc, %abd
  ret <4 x i32> %r
}

define <2 x i64> @unsupported_v2i64(<2 x i64> %acc, <2 x i64> %a, <2 x i64> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %abd = call <2 x i64> @llvm.aarch64.neon.sabd.v2i64(<2 x i64> %a, <2 x i64> %b)
  %r = add <2 x i64> %acc, %abd
  ret <2 x i64> %r
}

define <4 x i8> @unsupported_v4i8(<4 x i8> %acc, <4 x i8> %a, <4 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %abd = call <4 x i8> @llvm.aarch64.neon.sabd.v4i8(<4 x i8> %a, <4 x i8> %b)
  %r = add <4 x i8> %acc, %abd
  ret <4 x i8> %r
}

define <8 x i32> @unsupported_v8i32(<8 x i32> %acc, <8 x i32> %a, <8 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %abd = call <8 x i32> @llvm.aarch64.neon.sabd.v8i32(<8 x i32> %a, <8 x i32> %b)
  %r = add <8 x i32> %acc, %abd
  ret <8 x i32> %r
}

; Well-formed llvm.aarch64.neon.fabd is covered by
; vmp-aarch64-neon-fabd-semantic.ll and must not stay here as a
; negative (it would virtualize).

define <vscale x 16 x i8> @unsupported_sve_saba(<vscale x 16 x i8> %acc, <vscale x 16 x i8> %a, <vscale x 16 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 16 x i8> @llvm.aarch64.sve.saba.nxv16i8(<vscale x 16 x i8> %acc, <vscale x 16 x i8> %a, <vscale x 16 x i8> %b)
  ret <vscale x 16 x i8> %r
}

define <vscale x 8 x i16> @unsupported_sve_sabalb(<vscale x 8 x i16> %acc, <vscale x 16 x i8> %a, <vscale x 16 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 8 x i16> @llvm.aarch64.sve.sabalb.nxv8i16(<vscale x 8 x i16> %acc, <vscale x 16 x i8> %a, <vscale x 16 x i8> %b)
  ret <vscale x 8 x i16> %r
}

define <8 x i8> @unsupported_fastcc(<8 x i8> %acc, <8 x i8> %a, <8 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %abd = call fastcc <8 x i8> @llvm.aarch64.neon.sabd.v8i8(<8 x i8> %a, <8 x i8> %b)
  %r = add <8 x i8> %acc, %abd
  ret <8 x i8> %r
}


define <8 x i8> @unsupported_musttail(<8 x i8> %acc, <8 x i8> %a, <8 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  ; musttail must be followed by ret of the call; the add half cannot
  ; legally follow.  This still rejects the ABA-shaped function.
  %abd = musttail call <8 x i8> @llvm.aarch64.neon.sabd.v8i8(<8 x i8> %a, <8 x i8> %b)
  ret <8 x i8> %abd
}

define <8 x i8> @unsupported_bundle(<8 x i8> %acc, <8 x i8> %a, <8 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %abd = call <8 x i8> @llvm.aarch64.neon.sabd.v8i8(<8 x i8> %a, <8 x i8> %b) [ "deopt"(i32 0) ]
  %r = add <8 x i8> %acc, %abd
  ret <8 x i8> %r
}

define i32 @main() {
entry:
  %acc8 = load volatile <8 x i8>, ptr @sink_v8i8, align 8
  %a8 = load volatile <8 x i8>, ptr @sink_v8i8, align 8
  %b8 = load volatile <8 x i8>, ptr @sink_v8i8, align 8
  %r0 = call <8 x i8> @protected_saba_v8i8(<8 x i8> %acc8, <8 x i8> %a8, <8 x i8> %b8)
  store volatile <8 x i8> %r0, ptr @sink_v8i8, align 8
  %acc16 = load volatile <16 x i8>, ptr @sink_v16i8, align 16
  %a16 = load volatile <16 x i8>, ptr @sink_v16i8, align 16
  %b16 = load volatile <16 x i8>, ptr @sink_v16i8, align 16
  %r1 = call <16 x i8> @protected_saba_v16i8(<16 x i8> %acc16, <16 x i8> %a16, <16 x i8> %b16)
  store volatile <16 x i8> %r1, ptr @sink_v16i8, align 16
  %acc4h = load volatile <4 x i16>, ptr @sink_v4i16, align 8
  %a4h = load volatile <4 x i16>, ptr @sink_v4i16, align 8
  %b4h = load volatile <4 x i16>, ptr @sink_v4i16, align 8
  %r2 = call <4 x i16> @protected_saba_v4i16(<4 x i16> %acc4h, <4 x i16> %a4h, <4 x i16> %b4h)
  store volatile <4 x i16> %r2, ptr @sink_v4i16, align 8
  %acc8h = load volatile <8 x i16>, ptr @sink_v8i16, align 16
  %a8h = load volatile <8 x i16>, ptr @sink_v8i16, align 16
  %b8h = load volatile <8 x i16>, ptr @sink_v8i16, align 16
  %r3 = call <8 x i16> @protected_saba_v8i16(<8 x i16> %acc8h, <8 x i16> %a8h, <8 x i16> %b8h)
  store volatile <8 x i16> %r3, ptr @sink_v8i16, align 16
  %acc2s = load volatile <2 x i32>, ptr @sink_v2i32, align 8
  %a2s = load volatile <2 x i32>, ptr @sink_v2i32, align 8
  %b2s = load volatile <2 x i32>, ptr @sink_v2i32, align 8
  %r4 = call <2 x i32> @protected_saba_v2i32(<2 x i32> %acc2s, <2 x i32> %a2s, <2 x i32> %b2s)
  store volatile <2 x i32> %r4, ptr @sink_v2i32, align 8
  %acc4s = load volatile <4 x i32>, ptr @sink_v4i32, align 16
  %a4s = load volatile <4 x i32>, ptr @sink_v4i32, align 16
  %b4s = load volatile <4 x i32>, ptr @sink_v4i32, align 16
  %r5 = call <4 x i32> @protected_saba_v4i32(<4 x i32> %acc4s, <4 x i32> %a4s, <4 x i32> %b4s)
  store volatile <4 x i32> %r5, ptr @sink_v4i32, align 16
  %r6 = call <8 x i8> @protected_uaba_v8i8(<8 x i8> %acc8, <8 x i8> %a8, <8 x i8> %b8)
  store volatile <8 x i8> %r6, ptr @sink_v8i8, align 8
  %r7 = call <16 x i8> @protected_uaba_v16i8(<16 x i8> %acc16, <16 x i8> %a16, <16 x i8> %b16)
  store volatile <16 x i8> %r7, ptr @sink_v16i8, align 16
  %r8 = call <4 x i16> @protected_uaba_v4i16(<4 x i16> %acc4h, <4 x i16> %a4h, <4 x i16> %b4h)
  store volatile <4 x i16> %r8, ptr @sink_v4i16, align 8
  %r9 = call <8 x i16> @protected_uaba_v8i16(<8 x i16> %acc8h, <8 x i16> %a8h, <8 x i16> %b8h)
  store volatile <8 x i16> %r9, ptr @sink_v8i16, align 16
  %r10 = call <2 x i32> @protected_uaba_v2i32(<2 x i32> %acc2s, <2 x i32> %a2s, <2 x i32> %b2s)
  store volatile <2 x i32> %r10, ptr @sink_v2i32, align 8
  %r11 = call <4 x i32> @protected_uaba_v4i32(<4 x i32> %acc4s, <4 x i32> %a4s, <4 x i32> %b4s)
  store volatile <4 x i32> %r11, ptr @sink_v4i32, align 16
  ret i32 0
}

; SKIP-DAG: Skipping VMP on unsupported_v2i64: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_v4i8: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_v8i32: unsupported return type

; SKIP-DAG: Skipping VMP on unsupported_sve_saba: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_sve_sabalb: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_saba_v8i8:
; SKIP-NOT: Skipping VMP on protected_saba_v16i8:
; SKIP-NOT: Skipping VMP on protected_saba_v4i16:
; SKIP-NOT: Skipping VMP on protected_saba_v8i16:
; SKIP-NOT: Skipping VMP on protected_saba_v2i32:
; SKIP-NOT: Skipping VMP on protected_saba_v4i32:
; SKIP-NOT: Skipping VMP on protected_uaba_v8i8:
; SKIP-NOT: Skipping VMP on protected_uaba_v16i8:
; SKIP-NOT: Skipping VMP on protected_uaba_v4i16:
; SKIP-NOT: Skipping VMP on protected_uaba_v8i16:
; SKIP-NOT: Skipping VMP on protected_uaba_v2i32:
; SKIP-NOT: Skipping VMP on protected_uaba_v4i32:

; VIRT: define <8 x i8> @protected_saba_v8i8({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x i8> @llvm.aarch64.neon.sabd.v8i8(
; VIRT: define <16 x i8> @protected_saba_v16i8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <4 x i16> @protected_saba_v4i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <8 x i16> @protected_saba_v8i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <2 x i32> @protected_saba_v2i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <4 x i32> @protected_saba_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <8 x i8> @protected_uaba_v8i8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x i8> @llvm.aarch64.neon.uabd.v8i8(
; VIRT: define <16 x i8> @protected_uaba_v16i8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <4 x i16> @protected_uaba_v4i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <8 x i16> @protected_uaba_v8i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <2 x i32> @protected_uaba_v2i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <4 x i32> @protected_uaba_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define {{.*}} @unsupported_v2i64({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; VReg replay splits the ISel saba idiom into abd then add.
; AARCH64-ASM: {{^[[:space:]]*}}sabd{{[ \t]}}
; AARCH64-ASM: {{^[[:space:]]*}}uabd{{[ \t]}}
; AARCH64-ASM: add{{[ \t]+}}v
; HOST: Skipping VMP: only AArch64 targets are supported
