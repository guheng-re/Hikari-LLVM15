; Restricted AArch64 NEON integer across-lane reduce via
; CallDescriptor (vector VReg in, integer VReg out):
;   llvm.aarch64.neon.saddv / uaddv / sminv / uminv / smaxv / umaxv
;     AdvSIMD_1VectorArg_Int_Across: anyint (anyvector)
;     ISel SIMDAcrossLanes + v2i32 pairwise fallback, baseline HasNEON:
;       i32 (<8 x i8>) / i32 (<16 x i8>)
;       i32 (<4 x i16>) / i32 (<8 x i16>)
;       i32 (<2 x i32>) / i32 (<4 x i32>)
;     saddv/uaddv only: i64 (<2 x i64>) via ADDPv2i64p
; Clang emits i32 then truncates to i8/i16.  Not saddlv/uaddlv
; (vmp-aarch64-neon-addlv-semantic.ll),
; not faddv/fminv (faddv is vmp-aarch64-neon-faddv-semantic.ll),
; not llvm.vector.reduce.*, not SVE.  Exact C
; non-vararg.  Ordinary tail accepted and replayed as non-tail; see vmp-direct-call-tail-eligibility-semantic.ll.  No
; last-token gate.  No new opcode.
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
declare i32 @llvm.aarch64.neon.saddv.i32.v8i8(<8 x i8>)
declare i32 @llvm.aarch64.neon.saddv.i32.v2i32(<2 x i32>)
declare i32 @llvm.aarch64.neon.saddv.i32.v4i32(<4 x i32>)
declare i64 @llvm.aarch64.neon.saddv.i64.v2i64(<2 x i64>)
declare i32 @llvm.aarch64.neon.uaddv.i32.v16i8(<16 x i8>)
declare i64 @llvm.aarch64.neon.uaddv.i64.v2i64(<2 x i64>)
declare i32 @llvm.aarch64.neon.sminv.i32.v8i8(<8 x i8>)
declare i32 @llvm.aarch64.neon.sminv.i32.v4i32(<4 x i32>)
declare i32 @llvm.aarch64.neon.uminv.i32.v4i16(<4 x i16>)
declare i32 @llvm.aarch64.neon.uminv.i32.v2i32(<2 x i32>)
declare i32 @llvm.aarch64.neon.smaxv.i32.v16i8(<16 x i8>)
declare i32 @llvm.aarch64.neon.umaxv.i32.v4i32(<4 x i32>)
declare i8 @llvm.aarch64.neon.saddv.i8.v8i8(<8 x i8>)
declare i32 @llvm.aarch64.neon.sminv.i32.v2i64(<2 x i64>)
declare i32 @llvm.aarch64.neon.saddv.i32.v4i8(<4 x i8>)
declare i32 @llvm.aarch64.neon.saddv.i32.v8i32(<8 x i32>)
declare i64 @llvm.aarch64.sve.saddv.nxv16i8(<vscale x 16 x i1>, <vscale x 16 x i8>)

@sink_v8i8 = global <8 x i8> zeroinitializer, align 8
@sink_v16i8 = global <16 x i8> zeroinitializer, align 16
@sink_v4i16 = global <4 x i16> zeroinitializer, align 8
@sink_v2i32 = global <2 x i32> zeroinitializer, align 8
@sink_v4i32 = global <4 x i32> zeroinitializer, align 16
@sink_v2i64 = global <2 x i64> zeroinitializer, align 16
@sink_i32 = global i32 0, align 4
@sink_i64 = global i64 0, align 8

define i32 @protected_saddv_v8i8(<8 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.saddv.i32.v8i8(<8 x i8> %a)
  ret i32 %r
}

define i32 @protected_saddv_v2i32(<2 x i32> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.saddv.i32.v2i32(<2 x i32> %a)
  ret i32 %r
}

define i32 @protected_saddv_v4i32(<4 x i32> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.saddv.i32.v4i32(<4 x i32> %a)
  ret i32 %r
}

define i64 @protected_saddv_v2i64(<2 x i64> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.aarch64.neon.saddv.i64.v2i64(<2 x i64> %a)
  ret i64 %r
}

define i32 @protected_uaddv_v16i8(<16 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.uaddv.i32.v16i8(<16 x i8> %a)
  ret i32 %r
}

define i64 @protected_uaddv_v2i64(<2 x i64> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.aarch64.neon.uaddv.i64.v2i64(<2 x i64> %a)
  ret i64 %r
}

define i32 @protected_sminv_v8i8(<8 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.sminv.i32.v8i8(<8 x i8> %a)
  ret i32 %r
}

define i32 @protected_sminv_v4i32(<4 x i32> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.sminv.i32.v4i32(<4 x i32> %a)
  ret i32 %r
}

define i32 @protected_uminv_v4i16(<4 x i16> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.uminv.i32.v4i16(<4 x i16> %a)
  ret i32 %r
}

define i32 @protected_uminv_v2i32(<2 x i32> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.uminv.i32.v2i32(<2 x i32> %a)
  ret i32 %r
}

define i32 @protected_smaxv_v16i8(<16 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.smaxv.i32.v16i8(<16 x i8> %a)
  ret i32 %r
}

define i32 @protected_umaxv_v4i32(<4 x i32> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.umaxv.i32.v4i32(<4 x i32> %a)
  ret i32 %r
}

; Well-formed llvm.aarch64.neon.saddlv / uaddlv is
; vmp-aarch64-neon-addlv-semantic.ll and must not stay here as a
; negative (it would virtualize).

define i8 @unsupported_i8_result(<8 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i8 @llvm.aarch64.neon.saddv.i8.v8i8(<8 x i8> %a)
  ret i8 %r
}

define i32 @unsupported_sminv_v2i64(<2 x i64> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.sminv.i32.v2i64(<2 x i64> %a)
  ret i32 %r
}

define i32 @unsupported_v4i8(<4 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.saddv.i32.v4i8(<4 x i8> %a)
  ret i32 %r
}

define i32 @unsupported_v8i32(<8 x i32> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.saddv.i32.v8i32(<8 x i32> %a)
  ret i32 %r
}

; Well-formed llvm.aarch64.neon.faddv is
; vmp-aarch64-neon-faddv-semantic.ll and must not stay here as a
; negative (it would virtualize).

define i64 @unsupported_sve_saddv(<vscale x 16 x i1> %pg, <vscale x 16 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.aarch64.sve.saddv.nxv16i8(<vscale x 16 x i1> %pg, <vscale x 16 x i8> %a)
  ret i64 %r
}

define i32 @unsupported_fastcc(<8 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc i32 @llvm.aarch64.neon.saddv.i32.v8i8(<8 x i8> %a)
  ret i32 %r
}


define i32 @unsupported_musttail(<8 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call i32 @llvm.aarch64.neon.saddv.i32.v8i8(<8 x i8> %a)
  ret i32 %r
}

define i32 @unsupported_bundle(<8 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.saddv.i32.v8i8(<8 x i8> %a) [ "deopt"(i32 0) ]
  ret i32 %r
}

define i32 @main() {
entry:
  %a8 = load volatile <8 x i8>, ptr @sink_v8i8, align 8
  %r0 = call i32 @protected_saddv_v8i8(<8 x i8> %a8)
  store volatile i32 %r0, ptr @sink_i32, align 4
  %a2s = load volatile <2 x i32>, ptr @sink_v2i32, align 8
  %r1 = call i32 @protected_saddv_v2i32(<2 x i32> %a2s)
  store volatile i32 %r1, ptr @sink_i32, align 4
  %a4s = load volatile <4 x i32>, ptr @sink_v4i32, align 16
  %r2 = call i32 @protected_saddv_v4i32(<4 x i32> %a4s)
  store volatile i32 %r2, ptr @sink_i32, align 4
  %a2d = load volatile <2 x i64>, ptr @sink_v2i64, align 16
  %r3 = call i64 @protected_saddv_v2i64(<2 x i64> %a2d)
  store volatile i64 %r3, ptr @sink_i64, align 8
  %a16 = load volatile <16 x i8>, ptr @sink_v16i8, align 16
  %r4 = call i32 @protected_uaddv_v16i8(<16 x i8> %a16)
  store volatile i32 %r4, ptr @sink_i32, align 4
  %r5 = call i64 @protected_uaddv_v2i64(<2 x i64> %a2d)
  store volatile i64 %r5, ptr @sink_i64, align 8
  %r6 = call i32 @protected_sminv_v8i8(<8 x i8> %a8)
  store volatile i32 %r6, ptr @sink_i32, align 4
  %r7 = call i32 @protected_sminv_v4i32(<4 x i32> %a4s)
  store volatile i32 %r7, ptr @sink_i32, align 4
  %a4h = load volatile <4 x i16>, ptr @sink_v4i16, align 8
  %r8 = call i32 @protected_uminv_v4i16(<4 x i16> %a4h)
  store volatile i32 %r8, ptr @sink_i32, align 4
  %r9 = call i32 @protected_uminv_v2i32(<2 x i32> %a2s)
  store volatile i32 %r9, ptr @sink_i32, align 4
  %r10 = call i32 @protected_smaxv_v16i8(<16 x i8> %a16)
  store volatile i32 %r10, ptr @sink_i32, align 4
  %r11 = call i32 @protected_umaxv_v4i32(<4 x i32> %a4s)
  store volatile i32 %r11, ptr @sink_i32, align 4
  ret i32 0
}

; SKIP-DAG: Skipping VMP on unsupported_i8_result: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_sminv_v2i64: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_v4i8: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_v8i32: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_sve_saddv: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_saddv_v8i8:
; SKIP-NOT: Skipping VMP on protected_saddv_v2i32:
; SKIP-NOT: Skipping VMP on protected_saddv_v4i32:
; SKIP-NOT: Skipping VMP on protected_saddv_v2i64:
; SKIP-NOT: Skipping VMP on protected_uaddv_v16i8:
; SKIP-NOT: Skipping VMP on protected_uaddv_v2i64:
; SKIP-NOT: Skipping VMP on protected_sminv_v8i8:
; SKIP-NOT: Skipping VMP on protected_sminv_v4i32:
; SKIP-NOT: Skipping VMP on protected_uminv_v4i16:
; SKIP-NOT: Skipping VMP on protected_uminv_v2i32:
; SKIP-NOT: Skipping VMP on protected_smaxv_v16i8:
; SKIP-NOT: Skipping VMP on protected_umaxv_v4i32:

; VIRT: define i32 @protected_saddv_v8i8({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.neon.saddv.i32.v8i8(
; VIRT: define i32 @protected_saddv_v2i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define i32 @protected_saddv_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define i64 @protected_saddv_v2i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.aarch64.neon.saddv.i64.v2i64(
; VIRT: define i32 @protected_uaddv_v16i8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.neon.uaddv.i32.v16i8(
; VIRT: define i64 @protected_uaddv_v2i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define i32 @protected_sminv_v8i8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.neon.sminv.i32.v8i8(
; VIRT: define i32 @protected_sminv_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define i32 @protected_uminv_v4i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.neon.uminv.i32.v4i16(
; VIRT: define i32 @protected_uminv_v2i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define i32 @protected_smaxv_v16i8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.neon.smaxv.i32.v16i8(
; VIRT: define i32 @protected_umaxv_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.neon.umaxv.i32.v4i32(
; VIRT: define {{.*}} @unsupported_i8_result({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; AARCH64-ASM: {{^[[:space:]]*}}addv{{[ \t]}}
; AARCH64-ASM: {{^[[:space:]]*}}sminv{{[ \t]}}
; AARCH64-ASM: {{^[[:space:]]*}}uminv{{[ \t]}}
; AARCH64-ASM: {{^[[:space:]]*}}smaxv{{[ \t]}}
; AARCH64-ASM: {{^[[:space:]]*}}umaxv{{[ \t]}}
; HOST: Skipping VMP: only AArch64 targets are supported
