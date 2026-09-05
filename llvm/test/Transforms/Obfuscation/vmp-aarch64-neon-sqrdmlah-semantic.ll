; Restricted AArch64 NEON RDM accumulate/subtract multiply-high via
; CallDescriptor / vector VRegs:
;   llvm.aarch64.neon.sqrdmlah / sqrdmlsh
;     AdvSIMD_3IntArg: anyint (match, match, match)
;     ISel SIMDThreeSameVectorSQRDMLxHTiedHS: v4i16 / v8i16 / v2i32 / v4i32
;     Predicates HasNEON+HasRDM
; Last-token function +rdm required (HasRDM / FEAT_RDM).  Missing or
; final -rdm is "unsupported target feature".  Command-line -mattr is
; never used for eligibility.  NEON has no .lane/.laneq IR IDs
; (clang splat_lane + 3-arg; ISel SIMDIndexedSQRDMLxHSDTied matches
; duplane of this form).  SVE lane IDs stay out.  Exact C non-vararg.
; Ordinary tail accepted and replayed as non-tail; see vmp-direct-call-tail-eligibility-semantic.ll.  Does not change the
; ungated sqdmulh/sqrdmulh surface.  No new opcode.
;
; Host cannot select these AArch64 intrinsics; no lli.
; FileCheck + AArch64 llc/readobj/asm.  O0/O2 x 97/7.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.ll -o %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+rdm -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+rdm %t.o0.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.ll -o %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+rdm -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+rdm %t.o2.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.s7.ll -o %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+rdm -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+rdm %t.o0.s7.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.s7.ll -o %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+rdm -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+rdm %t.o2.s7.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %s | opt -S -verify-each -aesSeed=97 -passes='default<O0>' - 2>&1 | FileCheck %s --check-prefix=HOST

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare <4 x i16> @llvm.aarch64.neon.sqrdmlah.v4i16(<4 x i16>, <4 x i16>, <4 x i16>)
declare <8 x i16> @llvm.aarch64.neon.sqrdmlah.v8i16(<8 x i16>, <8 x i16>, <8 x i16>)
declare <2 x i32> @llvm.aarch64.neon.sqrdmlah.v2i32(<2 x i32>, <2 x i32>, <2 x i32>)
declare <4 x i32> @llvm.aarch64.neon.sqrdmlah.v4i32(<4 x i32>, <4 x i32>, <4 x i32>)
declare <8 x i16> @llvm.aarch64.neon.sqrdmlsh.v8i16(<8 x i16>, <8 x i16>, <8 x i16>)
declare <4 x i32> @llvm.aarch64.neon.sqrdmlsh.v4i32(<4 x i32>, <4 x i32>, <4 x i32>)
declare i32 @llvm.aarch64.neon.sqrdmlah.i32(i32, i32, i32)
declare <8 x i8> @llvm.aarch64.neon.sqrdmlah.v8i8(<8 x i8>, <8 x i8>, <8 x i8>)
declare <2 x i64> @llvm.aarch64.neon.sqrdmlah.v2i64(<2 x i64>, <2 x i64>, <2 x i64>)
declare <vscale x 8 x i16> @llvm.aarch64.sve.sqrdmlah.nxv8i16(<vscale x 8 x i16>, <vscale x 8 x i16>, <vscale x 8 x i16>)
declare <vscale x 8 x i16> @llvm.aarch64.sve.sqrdmlah.lane.nxv8i16(<vscale x 8 x i16>, <vscale x 8 x i16>, <vscale x 8 x i16>, i32)

@sink_v4i16 = global <4 x i16> zeroinitializer, align 8
@sink_v8i16 = global <8 x i16> zeroinitializer, align 16
@sink_v2i32 = global <2 x i32> zeroinitializer, align 8
@sink_v4i32 = global <4 x i32> zeroinitializer, align 16

define <4 x i16> @protected_sqrdmlah_v4i16(<4 x i16> %a, <4 x i16> %b, <4 x i16> %c) noinline optnone "target-features"="+rdm" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i16> @llvm.aarch64.neon.sqrdmlah.v4i16(<4 x i16> %a, <4 x i16> %b, <4 x i16> %c)
  ret <4 x i16> %r
}

define <8 x i16> @protected_sqrdmlah_v8i16(<8 x i16> %a, <8 x i16> %b, <8 x i16> %c) noinline optnone "target-features"="+rdm" {
entry:
  call void @hikari_vmp()
  %r = call <8 x i16> @llvm.aarch64.neon.sqrdmlah.v8i16(<8 x i16> %a, <8 x i16> %b, <8 x i16> %c)
  ret <8 x i16> %r
}

define <2 x i32> @protected_sqrdmlah_v2i32(<2 x i32> %a, <2 x i32> %b, <2 x i32> %c) noinline optnone "target-features"="+rdm" {
entry:
  call void @hikari_vmp()
  %r = call <2 x i32> @llvm.aarch64.neon.sqrdmlah.v2i32(<2 x i32> %a, <2 x i32> %b, <2 x i32> %c)
  ret <2 x i32> %r
}

define <4 x i32> @protected_sqrdmlah_v4i32(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c) noinline optnone "target-features"="+rdm" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.sqrdmlah.v4i32(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c)
  ret <4 x i32> %r
}

define <8 x i16> @protected_sqrdmlsh_v8i16(<8 x i16> %a, <8 x i16> %b, <8 x i16> %c) noinline optnone "target-features"="+rdm" {
entry:
  call void @hikari_vmp()
  %r = call <8 x i16> @llvm.aarch64.neon.sqrdmlsh.v8i16(<8 x i16> %a, <8 x i16> %b, <8 x i16> %c)
  ret <8 x i16> %r
}

define <4 x i32> @protected_sqrdmlsh_v4i32(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c) noinline optnone "target-features"="+rdm" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.sqrdmlsh.v4i32(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c)
  ret <4 x i32> %r
}

define <8 x i16> @protected_sqrdmlah_last_rdm(<8 x i16> %a, <8 x i16> %b, <8 x i16> %c) noinline optnone "target-features"="+neon,+crc,+rdm" {
entry:
  call void @hikari_vmp()
  %r = call <8 x i16> @llvm.aarch64.neon.sqrdmlah.v8i16(<8 x i16> %a, <8 x i16> %b, <8 x i16> %c)
  ret <8 x i16> %r
}

define <8 x i16> @unsupported_no_rdm(<8 x i16> %a, <8 x i16> %b, <8 x i16> %c) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i16> @llvm.aarch64.neon.sqrdmlah.v8i16(<8 x i16> %a, <8 x i16> %b, <8 x i16> %c)
  ret <8 x i16> %r
}

define <8 x i16> @unsupported_rdm_disabled(<8 x i16> %a, <8 x i16> %b, <8 x i16> %c) noinline optnone "target-features"="+rdm,-rdm" {
entry:
  call void @hikari_vmp()
  %r = call <8 x i16> @llvm.aarch64.neon.sqrdmlah.v8i16(<8 x i16> %a, <8 x i16> %b, <8 x i16> %c)
  ret <8 x i16> %r
}

define <8 x i16> @unsupported_neon_only(<8 x i16> %a, <8 x i16> %b, <8 x i16> %c) noinline optnone "target-features"="+neon" {
entry:
  call void @hikari_vmp()
  %r = call <8 x i16> @llvm.aarch64.neon.sqrdmlsh.v8i16(<8 x i16> %a, <8 x i16> %b, <8 x i16> %c)
  ret <8 x i16> %r
}

define i32 @unsupported_scalar(i32 %a, i32 %b, i32 %c) noinline optnone "target-features"="+rdm" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.sqrdmlah.i32(i32 %a, i32 %b, i32 %c)
  ret i32 %r
}

define <8 x i8> @unsupported_v8i8(<8 x i8> %a, <8 x i8> %b, <8 x i8> %c) noinline optnone "target-features"="+rdm" {
entry:
  call void @hikari_vmp()
  %r = call <8 x i8> @llvm.aarch64.neon.sqrdmlah.v8i8(<8 x i8> %a, <8 x i8> %b, <8 x i8> %c)
  ret <8 x i8> %r
}

define <2 x i64> @unsupported_v2i64(<2 x i64> %a, <2 x i64> %b, <2 x i64> %c) noinline optnone "target-features"="+rdm" {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.aarch64.neon.sqrdmlah.v2i64(<2 x i64> %a, <2 x i64> %b, <2 x i64> %c)
  ret <2 x i64> %r
}

; Well-formed llvm.aarch64.neon.smull / umull is
; vmp-aarch64-neon-smull-semantic.ll and must not stay here as a
; negative (it would virtualize).

define <vscale x 8 x i16> @unsupported_sve(<vscale x 8 x i16> %a, <vscale x 8 x i16> %b, <vscale x 8 x i16> %c) noinline optnone "target-features"="+rdm" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 8 x i16> @llvm.aarch64.sve.sqrdmlah.nxv8i16(<vscale x 8 x i16> %a, <vscale x 8 x i16> %b, <vscale x 8 x i16> %c)
  ret <vscale x 8 x i16> %r
}

; NEON has no sqrdmlah_lane IR ID; SVE lane stays out.
define <vscale x 8 x i16> @unsupported_sve_lane(<vscale x 8 x i16> %a, <vscale x 8 x i16> %b, <vscale x 8 x i16> %c) noinline optnone "target-features"="+rdm" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 8 x i16> @llvm.aarch64.sve.sqrdmlah.lane.nxv8i16(<vscale x 8 x i16> %a, <vscale x 8 x i16> %b, <vscale x 8 x i16> %c, i32 3)
  ret <vscale x 8 x i16> %r
}

define <8 x i16> @unsupported_fastcc(<8 x i16> %a, <8 x i16> %b, <8 x i16> %c) noinline optnone "target-features"="+rdm" {
entry:
  call void @hikari_vmp()
  %r = call fastcc <8 x i16> @llvm.aarch64.neon.sqrdmlah.v8i16(<8 x i16> %a, <8 x i16> %b, <8 x i16> %c)
  ret <8 x i16> %r
}


define <8 x i16> @unsupported_musttail(<8 x i16> %a, <8 x i16> %b, <8 x i16> %c) noinline optnone "target-features"="+rdm" {
entry:
  call void @hikari_vmp()
  %r = musttail call <8 x i16> @llvm.aarch64.neon.sqrdmlah.v8i16(<8 x i16> %a, <8 x i16> %b, <8 x i16> %c)
  ret <8 x i16> %r
}

define <8 x i16> @unsupported_bundle(<8 x i16> %a, <8 x i16> %b, <8 x i16> %c) noinline optnone "target-features"="+rdm" {
entry:
  call void @hikari_vmp()
  %r = call <8 x i16> @llvm.aarch64.neon.sqrdmlah.v8i16(<8 x i16> %a, <8 x i16> %b, <8 x i16> %c) [ "deopt"(i32 0) ]
  ret <8 x i16> %r
}

define i32 @main() {
entry:
  %a4 = load volatile <4 x i16>, ptr @sink_v4i16, align 8
  %b4 = load volatile <4 x i16>, ptr @sink_v4i16, align 8
  %c4 = load volatile <4 x i16>, ptr @sink_v4i16, align 8
  %r0 = call <4 x i16> @protected_sqrdmlah_v4i16(<4 x i16> %a4, <4 x i16> %b4, <4 x i16> %c4)
  store volatile <4 x i16> %r0, ptr @sink_v4i16, align 8
  %a8 = load volatile <8 x i16>, ptr @sink_v8i16, align 16
  %b8 = load volatile <8 x i16>, ptr @sink_v8i16, align 16
  %c8 = load volatile <8 x i16>, ptr @sink_v8i16, align 16
  %r1 = call <8 x i16> @protected_sqrdmlah_v8i16(<8 x i16> %a8, <8 x i16> %b8, <8 x i16> %c8)
  store volatile <8 x i16> %r1, ptr @sink_v8i16, align 16
  %a2 = load volatile <2 x i32>, ptr @sink_v2i32, align 8
  %b2 = load volatile <2 x i32>, ptr @sink_v2i32, align 8
  %c2 = load volatile <2 x i32>, ptr @sink_v2i32, align 8
  %r2 = call <2 x i32> @protected_sqrdmlah_v2i32(<2 x i32> %a2, <2 x i32> %b2, <2 x i32> %c2)
  store volatile <2 x i32> %r2, ptr @sink_v2i32, align 8
  %a32 = load volatile <4 x i32>, ptr @sink_v4i32, align 16
  %b32 = load volatile <4 x i32>, ptr @sink_v4i32, align 16
  %c32 = load volatile <4 x i32>, ptr @sink_v4i32, align 16
  %r3 = call <4 x i32> @protected_sqrdmlah_v4i32(<4 x i32> %a32, <4 x i32> %b32, <4 x i32> %c32)
  store volatile <4 x i32> %r3, ptr @sink_v4i32, align 16
  %r4 = call <8 x i16> @protected_sqrdmlsh_v8i16(<8 x i16> %a8, <8 x i16> %b8, <8 x i16> %c8)
  store volatile <8 x i16> %r4, ptr @sink_v8i16, align 16
  %r5 = call <4 x i32> @protected_sqrdmlsh_v4i32(<4 x i32> %a32, <4 x i32> %b32, <4 x i32> %c32)
  store volatile <4 x i32> %r5, ptr @sink_v4i32, align 16
  %r6 = call <8 x i16> @protected_sqrdmlah_last_rdm(<8 x i16> %a8, <8 x i16> %b8, <8 x i16> %c8)
  store volatile <8 x i16> %r6, ptr @sink_v8i16, align 16
  ret i32 0
}

; SKIP-DAG: Skipping VMP on unsupported_no_rdm: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_rdm_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_neon_only: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_scalar: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_v8i8: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_v2i64: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_sve: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_sve_lane: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_sqrdmlah_v4i16:
; SKIP-NOT: Skipping VMP on protected_sqrdmlah_v8i16:
; SKIP-NOT: Skipping VMP on protected_sqrdmlah_v2i32:
; SKIP-NOT: Skipping VMP on protected_sqrdmlah_v4i32:
; SKIP-NOT: Skipping VMP on protected_sqrdmlsh_v8i16:
; SKIP-NOT: Skipping VMP on protected_sqrdmlsh_v4i32:
; SKIP-NOT: Skipping VMP on protected_sqrdmlah_last_rdm:

; VIRT: define <4 x i16> @protected_sqrdmlah_v4i16({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i16> @llvm.aarch64.neon.sqrdmlah.v4i16(
; VIRT: define <8 x i16> @protected_sqrdmlah_v8i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x i16> @llvm.aarch64.neon.sqrdmlah.v8i16(
; VIRT: define <2 x i32> @protected_sqrdmlah_v2i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <4 x i32> @protected_sqrdmlah_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <8 x i16> @protected_sqrdmlsh_v8i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x i16> @llvm.aarch64.neon.sqrdmlsh.v8i16(
; VIRT: define <4 x i32> @protected_sqrdmlsh_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <8 x i16> @protected_sqrdmlah_last_rdm({{.*}} #[[LASTRDM:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x i16> @llvm.aarch64.neon.sqrdmlah.v8i16(
; VIRT: define {{.*}} @unsupported_no_rdm({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT: attributes #[[LASTRDM]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; AARCH64-ASM: sqrdmlah
; AARCH64-ASM: sqrdmlsh
; HOST: Skipping VMP: only AArch64 targets are supported
