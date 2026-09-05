; Restricted SVE integer math on full-register types: last-token +sve,
; nxv16i8 / nxv8i16 / nxv4i32 / nxv2i64.  IDs: abs, smin, smax, umin,
; umax, ctpop, ctlz, cttz, bswap, bitreverse, sadd.sat, ssub.sat,
; uadd.sat, usub.sat, fshl, fshr.  Rebuilt as the same intrinsic on
; the nxv16i8 data frame (not CallDescriptor).  abs is_int_min_poison
; and ctlz/cttz is_zero_undef ImmArgs stay in Variant.  Funnel uses
; three same-type vectors (including rotate fshl(a,a,n)).  sshl.sat /
; ushl.sat stay skipped (LLVM 15 ISel UnrollVectorOp fatal).  Host
; cannot execute AArch64 SVE.  FileCheck + AArch64 llc/readobj/asm
; (llc: -mattr=+sve -fast-isel=false).  O0/O2 x 97/7.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.ll > %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+sve -fast-isel=false -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+sve -fast-isel=false %t.o0.live.ll -o - | FileCheck %s --check-prefix=ASM
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.ll > %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+sve -fast-isel=false -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+sve -fast-isel=false %t.o2.live.ll -o - | FileCheck %s --check-prefix=ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.s7.ll > %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+sve -fast-isel=false -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+sve -fast-isel=false %t.o0.s7.live.ll -o - | FileCheck %s --check-prefix=ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.s7.ll > %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+sve -fast-isel=false -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+sve -fast-isel=false %t.o2.s7.live.ll -o - | FileCheck %s --check-prefix=ASM
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %s | opt -S -verify-each -aesSeed=97 -passes='default<O0>' - 2>&1 | FileCheck %s --check-prefix=HOST
; RUN: opt -S -verify-each -aesSeed=97 -vmp-max-bytecode-words=1 -passes='default<O0>' %s -o %t.budget.ll 2>%t.budget.err
; RUN: FileCheck %s --check-prefix=BUDGET-ERR < %t.budget.err
; RUN: FileCheck %s --check-prefix=BUDGET-IR < %t.budget.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare <vscale x 4 x i32> @llvm.abs.nxv4i32(<vscale x 4 x i32>, i1)
declare <vscale x 8 x i16> @llvm.abs.nxv8i16(<vscale x 8 x i16>, i1)
declare <vscale x 16 x i8> @llvm.abs.nxv16i8(<vscale x 16 x i8>, i1)
declare <vscale x 2 x i64> @llvm.abs.nxv2i64(<vscale x 2 x i64>, i1)
declare <vscale x 4 x i32> @llvm.smin.nxv4i32(<vscale x 4 x i32>, <vscale x 4 x i32>)
declare <vscale x 4 x i32> @llvm.smax.nxv4i32(<vscale x 4 x i32>, <vscale x 4 x i32>)
declare <vscale x 4 x i32> @llvm.umin.nxv4i32(<vscale x 4 x i32>, <vscale x 4 x i32>)
declare <vscale x 4 x i32> @llvm.umax.nxv4i32(<vscale x 4 x i32>, <vscale x 4 x i32>)
declare <vscale x 16 x i8> @llvm.smin.nxv16i8(<vscale x 16 x i8>, <vscale x 16 x i8>)
declare <vscale x 2 x i64> @llvm.umax.nxv2i64(<vscale x 2 x i64>, <vscale x 2 x i64>)
declare <vscale x 4 x i32> @llvm.ctpop.nxv4i32(<vscale x 4 x i32>)
declare <vscale x 4 x i32> @llvm.ctlz.nxv4i32(<vscale x 4 x i32>, i1)
declare <vscale x 4 x i32> @llvm.sadd.sat.nxv4i32(<vscale x 4 x i32>, <vscale x 4 x i32>)
declare <vscale x 4 x i32> @llvm.ssub.sat.nxv4i32(<vscale x 4 x i32>, <vscale x 4 x i32>)
declare <vscale x 4 x i32> @llvm.uadd.sat.nxv4i32(<vscale x 4 x i32>, <vscale x 4 x i32>)
declare <vscale x 4 x i32> @llvm.usub.sat.nxv4i32(<vscale x 4 x i32>, <vscale x 4 x i32>)
declare <vscale x 4 x i32> @llvm.cttz.nxv4i32(<vscale x 4 x i32>, i1)
declare <vscale x 4 x i32> @llvm.bswap.nxv4i32(<vscale x 4 x i32>)
declare <vscale x 8 x i16> @llvm.bswap.nxv8i16(<vscale x 8 x i16>)
declare <vscale x 2 x i64> @llvm.bswap.nxv2i64(<vscale x 2 x i64>)
declare <vscale x 4 x i32> @llvm.bitreverse.nxv4i32(<vscale x 4 x i32>)
declare <vscale x 16 x i8> @llvm.bitreverse.nxv16i8(<vscale x 16 x i8>)
declare <vscale x 4 x i32> @llvm.fshl.nxv4i32(<vscale x 4 x i32>, <vscale x 4 x i32>, <vscale x 4 x i32>)
declare <vscale x 4 x i32> @llvm.fshr.nxv4i32(<vscale x 4 x i32>, <vscale x 4 x i32>, <vscale x 4 x i32>)
declare <vscale x 16 x i8> @llvm.fshl.nxv16i8(<vscale x 16 x i8>, <vscale x 16 x i8>, <vscale x 16 x i8>)
declare <vscale x 2 x i64> @llvm.fshr.nxv2i64(<vscale x 2 x i64>, <vscale x 2 x i64>, <vscale x 2 x i64>)
declare <vscale x 4 x i32> @llvm.sshl.sat.nxv4i32(<vscale x 4 x i32>, <vscale x 4 x i32>)
declare <vscale x 8 x i8> @llvm.abs.nxv8i8(<vscale x 8 x i8>, i1)

define <vscale x 4 x i32> @protected_abs_i32(<vscale x 4 x i32> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.abs.nxv4i32(<vscale x 4 x i32> %a, i1 false)
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @protected_abs_int_min_poison(<vscale x 4 x i32> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.abs.nxv4i32(<vscale x 4 x i32> %a, i1 true)
  ret <vscale x 4 x i32> %r
}

define <vscale x 8 x i16> @protected_abs_i16(<vscale x 8 x i16> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 8 x i16> @llvm.abs.nxv8i16(<vscale x 8 x i16> %a, i1 false)
  ret <vscale x 8 x i16> %r
}

define <vscale x 16 x i8> @protected_abs_i8(<vscale x 16 x i8> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 16 x i8> @llvm.abs.nxv16i8(<vscale x 16 x i8> %a, i1 false)
  ret <vscale x 16 x i8> %r
}

define <vscale x 2 x i64> @protected_abs_i64(<vscale x 2 x i64> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 2 x i64> @llvm.abs.nxv2i64(<vscale x 2 x i64> %a, i1 false)
  ret <vscale x 2 x i64> %r
}

define <vscale x 4 x i32> @protected_smin_i32(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.smin.nxv4i32(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b)
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @protected_smax_i32(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.smax.nxv4i32(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b)
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @protected_umin_i32(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.umin.nxv4i32(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b)
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @protected_umax_i32(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.umax.nxv4i32(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b)
  ret <vscale x 4 x i32> %r
}

define <vscale x 16 x i8> @protected_smin_i8(<vscale x 16 x i8> %a, <vscale x 16 x i8> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 16 x i8> @llvm.smin.nxv16i8(<vscale x 16 x i8> %a, <vscale x 16 x i8> %b)
  ret <vscale x 16 x i8> %r
}

define <vscale x 2 x i64> @protected_umax_i64(<vscale x 2 x i64> %a, <vscale x 2 x i64> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 2 x i64> @llvm.umax.nxv2i64(<vscale x 2 x i64> %a, <vscale x 2 x i64> %b)
  ret <vscale x 2 x i64> %r
}

define <vscale x 4 x i32> @protected_ctpop_i32(<vscale x 4 x i32> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.ctpop.nxv4i32(<vscale x 4 x i32> %a)
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @protected_ctlz_i32(<vscale x 4 x i32> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.ctlz.nxv4i32(<vscale x 4 x i32> %a, i1 false)
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @protected_ctlz_zero_undef(<vscale x 4 x i32> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.ctlz.nxv4i32(<vscale x 4 x i32> %a, i1 true)
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @protected_sadd_sat_i32(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.sadd.sat.nxv4i32(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b)
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @protected_ssub_sat_i32(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.ssub.sat.nxv4i32(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b)
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @protected_uadd_sat_i32(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.uadd.sat.nxv4i32(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b)
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @protected_usub_sat_i32(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.usub.sat.nxv4i32(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b)
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @protected_cttz_i32(<vscale x 4 x i32> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.cttz.nxv4i32(<vscale x 4 x i32> %a, i1 false)
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @protected_cttz_zero_undef(<vscale x 4 x i32> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.cttz.nxv4i32(<vscale x 4 x i32> %a, i1 true)
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @protected_bswap_i32(<vscale x 4 x i32> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.bswap.nxv4i32(<vscale x 4 x i32> %a)
  ret <vscale x 4 x i32> %r
}

define <vscale x 8 x i16> @protected_bswap_i16(<vscale x 8 x i16> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 8 x i16> @llvm.bswap.nxv8i16(<vscale x 8 x i16> %a)
  ret <vscale x 8 x i16> %r
}

define <vscale x 2 x i64> @protected_bswap_i64(<vscale x 2 x i64> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 2 x i64> @llvm.bswap.nxv2i64(<vscale x 2 x i64> %a)
  ret <vscale x 2 x i64> %r
}

define <vscale x 4 x i32> @protected_bitreverse_i32(<vscale x 4 x i32> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.bitreverse.nxv4i32(<vscale x 4 x i32> %a)
  ret <vscale x 4 x i32> %r
}

define <vscale x 16 x i8> @protected_bitreverse_i8(<vscale x 16 x i8> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 16 x i8> @llvm.bitreverse.nxv16i8(<vscale x 16 x i8> %a)
  ret <vscale x 16 x i8> %r
}

define <vscale x 4 x i32> @protected_fshl_i32(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b, <vscale x 4 x i32> %c) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.fshl.nxv4i32(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b, <vscale x 4 x i32> %c)
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @protected_fshl_rot_i32(<vscale x 4 x i32> %a, <vscale x 4 x i32> %n) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.fshl.nxv4i32(<vscale x 4 x i32> %a, <vscale x 4 x i32> %a, <vscale x 4 x i32> %n)
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @protected_fshr_i32(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b, <vscale x 4 x i32> %c) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.fshr.nxv4i32(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b, <vscale x 4 x i32> %c)
  ret <vscale x 4 x i32> %r
}

define <vscale x 16 x i8> @protected_fshl_i8(<vscale x 16 x i8> %a, <vscale x 16 x i8> %b, <vscale x 16 x i8> %c) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 16 x i8> @llvm.fshl.nxv16i8(<vscale x 16 x i8> %a, <vscale x 16 x i8> %b, <vscale x 16 x i8> %c)
  ret <vscale x 16 x i8> %r
}

define <vscale x 2 x i64> @protected_fshr_i64(<vscale x 2 x i64> %a, <vscale x 2 x i64> %b, <vscale x 2 x i64> %c) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 2 x i64> @llvm.fshr.nxv2i64(<vscale x 2 x i64> %a, <vscale x 2 x i64> %b, <vscale x 2 x i64> %c)
  ret <vscale x 2 x i64> %r
}

define <vscale x 4 x i32> @unsupported_nofeat(<vscale x 4 x i32> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.abs.nxv4i32(<vscale x 4 x i32> %a, i1 false)
  ret <vscale x 4 x i32> %r
}

define i32 @unsupported_internal_nofeat(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %a = load <vscale x 4 x i32>, ptr %p, align 16
  %r = call <vscale x 4 x i32> @llvm.abs.nxv4i32(<vscale x 4 x i32> %a, i1 false)
  ret i32 0
}

define i32 @unsupported_sshl_sat(ptr %p) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %a = load <vscale x 4 x i32>, ptr %p, align 16
  %b = load <vscale x 4 x i32>, ptr %p, align 16
  %r = call <vscale x 4 x i32> @llvm.sshl.sat.nxv4i32(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b)
  ret i32 0
}

define i32 @unsupported_partial(ptr %p) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %a = load <vscale x 8 x i8>, ptr %p, align 8
  %r = call <vscale x 8 x i8> @llvm.abs.nxv8i8(<vscale x 8 x i8> %a, i1 false)
  ret i32 0
}

define i32 @unsupported_poison(<vscale x 4 x i32> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.abs.nxv4i32(<vscale x 4 x i32> poison, i1 false)
  ret i32 0
}

define void @main() {
entry:
  ret void
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_nofeat: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_internal_nofeat: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_sshl_sat: unsupported sshl.sat
; SKIP-DAG: Skipping VMP on unsupported_partial: unsupported vector load instruction
; SKIP-DAG: Skipping VMP on unsupported_poison: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_abs_i32:
; SKIP-NOT: Skipping VMP on protected_abs_int_min_poison:
; SKIP-NOT: Skipping VMP on protected_abs_i16:
; SKIP-NOT: Skipping VMP on protected_abs_i8:
; SKIP-NOT: Skipping VMP on protected_abs_i64:
; SKIP-NOT: Skipping VMP on protected_smin_i32:
; SKIP-NOT: Skipping VMP on protected_smax_i32:
; SKIP-NOT: Skipping VMP on protected_umin_i32:
; SKIP-NOT: Skipping VMP on protected_umax_i32:
; SKIP-NOT: Skipping VMP on protected_smin_i8:
; SKIP-NOT: Skipping VMP on protected_umax_i64:
; SKIP-NOT: Skipping VMP on protected_ctpop_i32:
; SKIP-NOT: Skipping VMP on protected_ctlz_i32:
; SKIP-NOT: Skipping VMP on protected_ctlz_zero_undef:
; SKIP-NOT: Skipping VMP on protected_sadd_sat_i32:
; SKIP-NOT: Skipping VMP on protected_ssub_sat_i32:
; SKIP-NOT: Skipping VMP on protected_uadd_sat_i32:
; SKIP-NOT: Skipping VMP on protected_usub_sat_i32:
; SKIP-NOT: Skipping VMP on protected_cttz_i32:
; SKIP-NOT: Skipping VMP on protected_cttz_zero_undef:
; SKIP-NOT: Skipping VMP on protected_bswap_i32:
; SKIP-NOT: Skipping VMP on protected_bswap_i16:
; SKIP-NOT: Skipping VMP on protected_bswap_i64:
; SKIP-NOT: Skipping VMP on protected_bitreverse_i32:
; SKIP-NOT: Skipping VMP on protected_bitreverse_i8:
; SKIP-NOT: Skipping VMP on protected_fshl_i32:
; SKIP-NOT: Skipping VMP on protected_fshl_rot_i32:
; SKIP-NOT: Skipping VMP on protected_fshr_i32:
; SKIP-NOT: Skipping VMP on protected_fshl_i8:
; SKIP-NOT: Skipping VMP on protected_fshr_i64:

; VIRT-LABEL: define <vscale x 4 x i32> @protected_abs_i32(
; VIRT-SAME: #[[PROT:[0-9]+]]
; VIRT: vmp.sve.regs
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x i32> @llvm.abs.nxv4i32({{.*}}, i1 false)
; VIRT-LABEL: define <vscale x 4 x i32> @protected_abs_int_min_poison(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x i32> @llvm.abs.nxv4i32({{.*}}, i1 true)
; VIRT-LABEL: define <vscale x 8 x i16> @protected_abs_i16(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 8 x i16> @llvm.abs.nxv8i16(
; VIRT-LABEL: define <vscale x 16 x i8> @protected_abs_i8(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 16 x i8> @llvm.abs.nxv16i8(
; VIRT-LABEL: define <vscale x 2 x i64> @protected_abs_i64(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 2 x i64> @llvm.abs.nxv2i64(
; VIRT-LABEL: define <vscale x 4 x i32> @protected_smin_i32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x i32> @llvm.smin.nxv4i32(
; VIRT-LABEL: define <vscale x 4 x i32> @protected_smax_i32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x i32> @llvm.smax.nxv4i32(
; VIRT-LABEL: define <vscale x 4 x i32> @protected_umin_i32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x i32> @llvm.umin.nxv4i32(
; VIRT-LABEL: define <vscale x 4 x i32> @protected_umax_i32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x i32> @llvm.umax.nxv4i32(
; VIRT-LABEL: define <vscale x 16 x i8> @protected_smin_i8(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 16 x i8> @llvm.smin.nxv16i8(
; VIRT-LABEL: define <vscale x 2 x i64> @protected_umax_i64(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 2 x i64> @llvm.umax.nxv2i64(
; VIRT-LABEL: define <vscale x 4 x i32> @protected_ctpop_i32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x i32> @llvm.ctpop.nxv4i32(
; VIRT-LABEL: define <vscale x 4 x i32> @protected_ctlz_i32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x i32> @llvm.ctlz.nxv4i32({{.*}}, i1 false)
; VIRT-LABEL: define <vscale x 4 x i32> @protected_ctlz_zero_undef(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x i32> @llvm.ctlz.nxv4i32({{.*}}, i1 true)
; VIRT-LABEL: define <vscale x 4 x i32> @protected_sadd_sat_i32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x i32> @llvm.sadd.sat.nxv4i32(
; VIRT-LABEL: define <vscale x 4 x i32> @protected_ssub_sat_i32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x i32> @llvm.ssub.sat.nxv4i32(
; VIRT-LABEL: define <vscale x 4 x i32> @protected_uadd_sat_i32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x i32> @llvm.uadd.sat.nxv4i32(
; VIRT-LABEL: define <vscale x 4 x i32> @protected_usub_sat_i32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x i32> @llvm.usub.sat.nxv4i32(
; VIRT-LABEL: define <vscale x 4 x i32> @protected_cttz_i32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x i32> @llvm.cttz.nxv4i32({{.*}}, i1 false)
; VIRT-LABEL: define <vscale x 4 x i32> @protected_cttz_zero_undef(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x i32> @llvm.cttz.nxv4i32({{.*}}, i1 true)
; VIRT-LABEL: define <vscale x 4 x i32> @protected_bswap_i32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x i32> @llvm.bswap.nxv4i32(
; VIRT-LABEL: define <vscale x 8 x i16> @protected_bswap_i16(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 8 x i16> @llvm.bswap.nxv8i16(
; VIRT-LABEL: define <vscale x 2 x i64> @protected_bswap_i64(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 2 x i64> @llvm.bswap.nxv2i64(
; VIRT-LABEL: define <vscale x 4 x i32> @protected_bitreverse_i32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x i32> @llvm.bitreverse.nxv4i32(
; VIRT-LABEL: define <vscale x 16 x i8> @protected_bitreverse_i8(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 16 x i8> @llvm.bitreverse.nxv16i8(
; VIRT-LABEL: define <vscale x 4 x i32> @protected_fshl_i32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x i32> @llvm.fshl.nxv4i32(
; VIRT-LABEL: define <vscale x 4 x i32> @protected_fshl_rot_i32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x i32> @llvm.fshl.nxv4i32(
; VIRT-LABEL: define <vscale x 4 x i32> @protected_fshr_i32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x i32> @llvm.fshr.nxv4i32(
; VIRT-LABEL: define <vscale x 16 x i8> @protected_fshl_i8(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 16 x i8> @llvm.fshl.nxv16i8(
; VIRT-LABEL: define <vscale x 2 x i64> @protected_fshr_i64(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 2 x i64> @llvm.fshr.nxv2i64(
; VIRT: define {{.*}} @unsupported_nofeat({{.*}} #[[UNSUP:[0-9]+]]
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; ASM-DAG: abs{{.*}}z{{[0-9]+}}.s
; ASM-DAG: abs{{.*}}z{{[0-9]+}}.h
; ASM-DAG: abs{{.*}}z{{[0-9]+}}.b
; ASM-DAG: abs{{.*}}z{{[0-9]+}}.d
; ASM-DAG: smin{{.*}}z{{[0-9]+}}.s
; ASM-DAG: smax{{.*}}z{{[0-9]+}}.s
; ASM-DAG: umin{{.*}}z{{[0-9]+}}.s
; ASM-DAG: umax{{.*}}z{{[0-9]+}}.s
; ASM-DAG: smin{{.*}}z{{[0-9]+}}.b
; ASM-DAG: umax{{.*}}z{{[0-9]+}}.d
; ASM-DAG: cnt{{.*}}z{{[0-9]+}}.s
; ASM-DAG: clz{{.*}}z{{[0-9]+}}.s
; ASM-DAG: sqadd{{.*}}z{{[0-9]+}}.s
; ASM-DAG: sqsub{{.*}}z{{[0-9]+}}.s
; ASM-DAG: uqadd{{.*}}z{{[0-9]+}}.s
; ASM-DAG: uqsub{{.*}}z{{[0-9]+}}.s
; ASM-DAG: rbit{{.*}}z{{[0-9]+}}.s
; ASM-DAG: rbit{{.*}}z{{[0-9]+}}.b
; ASM-DAG: revb{{.*}}z{{[0-9]+}}.s
; ASM-DAG: revb{{.*}}z{{[0-9]+}}.h
; ASM-DAG: revb{{.*}}z{{[0-9]+}}.d
; ASM-DAG: and{{.*}}#0x1f
; ASM-DAG: lsr{{.*}}#1
; HOST: Skipping VMP: only AArch64 targets are supported
; BUDGET-ERR: Skipping VMP on protected_abs_i32: bytecode word budget
; BUDGET-IR-LABEL: define <vscale x 4 x i32> @protected_abs_i32(
; BUDGET-IR-NOT: vmp.dispatch
; BUDGET-IR: call <vscale x 4 x i32> @llvm.abs.nxv4i32(
