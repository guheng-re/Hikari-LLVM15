; Restricted AArch64 NEON unsigned integer reciprocal /
; reciprocal-sqrt estimate via CallDescriptor / integer vector
; VRegs (no new opcode):
;   llvm.aarch64.neon.urecpe / ursqrte
;     AdvSIMD_1VectorArg: anyvector (match)
;     ISel SIMDTwoVectorS, baseline HasNEON:
;       <2 x i32> / <4 x i32>
; Must not replay as udiv or frecpe/frecpx.  No scalar integer ID.
; Exact C non-vararg.  Ordinary tail accepted and replayed as non-tail; see vmp-direct-call-tail-eligibility-semantic.ll.
; No last-token gate.
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
declare <2 x i32> @llvm.aarch64.neon.urecpe.v2i32(<2 x i32>)
declare <4 x i32> @llvm.aarch64.neon.urecpe.v4i32(<4 x i32>)
declare <2 x i32> @llvm.aarch64.neon.ursqrte.v2i32(<2 x i32>)
declare <4 x i32> @llvm.aarch64.neon.ursqrte.v4i32(<4 x i32>)
declare <8 x i16> @llvm.aarch64.neon.urecpe.v8i16(<8 x i16>)
declare <2 x i64> @llvm.aarch64.neon.ursqrte.v2i64(<2 x i64>)
declare <vscale x 4 x i32> @llvm.aarch64.sve.urecpe.nxv4i32(<vscale x 4 x i32>, <vscale x 4 x i1>, <vscale x 4 x i32>)

@sink_v2i32 = global <2 x i32> zeroinitializer, align 8
@sink_v4i32 = global <4 x i32> zeroinitializer, align 16

define <2 x i32> @protected_urecpe_v2i32(<2 x i32> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i32> @llvm.aarch64.neon.urecpe.v2i32(<2 x i32> %a)
  ret <2 x i32> %r
}

define <4 x i32> @protected_urecpe_v4i32(<4 x i32> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.urecpe.v4i32(<4 x i32> %a)
  ret <4 x i32> %r
}

define <2 x i32> @protected_ursqrte_v2i32(<2 x i32> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i32> @llvm.aarch64.neon.ursqrte.v2i32(<2 x i32> %a)
  ret <2 x i32> %r
}

define <4 x i32> @protected_ursqrte_v4i32(<4 x i32> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.ursqrte.v4i32(<4 x i32> %a)
  ret <4 x i32> %r
}

; ----- negatives: selected, not virtualized -----

define <8 x i16> @unsupported_v8i16(<8 x i16> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i16> @llvm.aarch64.neon.urecpe.v8i16(<8 x i16> %a)
  ret <8 x i16> %r
}

define <2 x i64> @unsupported_v2i64(<2 x i64> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.aarch64.neon.ursqrte.v2i64(<2 x i64> %a)
  ret <2 x i64> %r
}

define <vscale x 4 x i32> @unsupported_sve_urecpe(<vscale x 4 x i32> %a, <vscale x 4 x i1> %pg) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.aarch64.sve.urecpe.nxv4i32(<vscale x 4 x i32> %a, <vscale x 4 x i1> %pg, <vscale x 4 x i32> %a)
  ret <vscale x 4 x i32> %r
}

define <2 x i32> @unsupported_fastcc(<2 x i32> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc <2 x i32> @llvm.aarch64.neon.urecpe.v2i32(<2 x i32> %a)
  ret <2 x i32> %r
}


define <2 x i32> @unsupported_musttail(<2 x i32> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call <2 x i32> @llvm.aarch64.neon.urecpe.v2i32(<2 x i32> %a)
  ret <2 x i32> %r
}

define <2 x i32> @unsupported_bundle(<2 x i32> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i32> @llvm.aarch64.neon.urecpe.v2i32(<2 x i32> %a) [ "deopt"(i32 0) ]
  ret <2 x i32> %r
}

define <2 x i32> @unsupported_noreturn(<2 x i32> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i32> @llvm.aarch64.neon.urecpe.v2i32(<2 x i32> %a) noreturn
  ret <2 x i32> %r
}

define <2 x i32> @unsupported_returns_twice(<2 x i32> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i32> @llvm.aarch64.neon.urecpe.v2i32(<2 x i32> %a) returns_twice
  ret <2 x i32> %r
}

define i32 @main() {
entry:
  %a2 = load volatile <2 x i32>, ptr @sink_v2i32, align 8
  %r0 = call <2 x i32> @protected_urecpe_v2i32(<2 x i32> %a2)
  store volatile <2 x i32> %r0, ptr @sink_v2i32, align 8
  %a4 = load volatile <4 x i32>, ptr @sink_v4i32, align 16
  %r1 = call <4 x i32> @protected_urecpe_v4i32(<4 x i32> %a4)
  store volatile <4 x i32> %r1, ptr @sink_v4i32, align 16
  %r2 = call <2 x i32> @protected_ursqrte_v2i32(<2 x i32> %a2)
  store volatile <2 x i32> %r2, ptr @sink_v2i32, align 8
  %r3 = call <4 x i32> @protected_ursqrte_v4i32(<4 x i32> %a4)
  store volatile <4 x i32> %r3, ptr @sink_v4i32, align 16
  ret i32 0
}

; SKIP-DAG: Skipping VMP on unsupported_v8i16: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_v2i64: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_sve_urecpe: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_noreturn: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_returns_twice: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_urecpe_v2i32:
; SKIP-NOT: Skipping VMP on protected_urecpe_v4i32:
; SKIP-NOT: Skipping VMP on protected_ursqrte_v2i32:
; SKIP-NOT: Skipping VMP on protected_ursqrte_v4i32:

; VIRT: define <2 x i32> @protected_urecpe_v2i32({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i32> @llvm.aarch64.neon.urecpe.v2i32(
; VIRT: define <4 x i32> @protected_urecpe_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.aarch64.neon.urecpe.v4i32(
; VIRT: define <2 x i32> @protected_ursqrte_v2i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i32> @llvm.aarch64.neon.ursqrte.v2i32(
; VIRT: define <4 x i32> @protected_ursqrte_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.aarch64.neon.ursqrte.v4i32(
; VIRT: define {{.*}} @unsupported_v8i16({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; AARCH64-ASM-DAG: {{^[[:space:]]*}}urecpe{{[ \t]}}{{v[0-9]+}}.2s
; AARCH64-ASM-DAG: {{^[[:space:]]*}}urecpe{{[ \t]}}{{v[0-9]+}}.4s
; AARCH64-ASM-DAG: {{^[[:space:]]*}}ursqrte{{[ \t]}}{{v[0-9]+}}.2s
; AARCH64-ASM-DAG: {{^[[:space:]]*}}ursqrte{{[ \t]}}{{v[0-9]+}}.4s
; HOST: Skipping VMP: only AArch64 targets are supported
