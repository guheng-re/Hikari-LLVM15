; Restricted SVE float math on full-register types: last-token +sve,
; nxv4f32 / nxv2f64; nxv8f16 also last-token +fullfp16.  IDs: sqrt,
; fabs, fma, fmuladd, minnum, maxnum, minimum, maximum, ceil, floor,
; trunc, round, roundeven, rint, nearbyint, copysign.  Rebuilt as the
; same intrinsic on the nxv16i8 data frame (not CallDescriptor).
; FastMathFlags replayed.  sin/pow stay skipped (LLVM 15 ISel fatal);
; canonicalize cannot select.  Host cannot execute AArch64 SVE.
; FileCheck + AArch64 llc/readobj/asm (llc: -mattr=+sve,+fullfp16
; -fast-isel=false).  O0/O2 x 97/7.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.ll > %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+sve,+fullfp16 -fast-isel=false -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+sve,+fullfp16 -fast-isel=false %t.o0.live.ll -o - | FileCheck %s --check-prefix=ASM
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.ll > %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+sve,+fullfp16 -fast-isel=false -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+sve,+fullfp16 -fast-isel=false %t.o2.live.ll -o - | FileCheck %s --check-prefix=ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.s7.ll > %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+sve,+fullfp16 -fast-isel=false -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+sve,+fullfp16 -fast-isel=false %t.o0.s7.live.ll -o - | FileCheck %s --check-prefix=ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.s7.ll > %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+sve,+fullfp16 -fast-isel=false -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+sve,+fullfp16 -fast-isel=false %t.o2.s7.live.ll -o - | FileCheck %s --check-prefix=ASM
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %s | opt -S -verify-each -aesSeed=97 -passes='default<O0>' - 2>&1 | FileCheck %s --check-prefix=HOST
; RUN: opt -S -verify-each -aesSeed=97 -vmp-max-bytecode-words=1 -passes='default<O0>' %s -o %t.budget.ll 2>%t.budget.err
; RUN: FileCheck %s --check-prefix=BUDGET-ERR < %t.budget.err
; RUN: FileCheck %s --check-prefix=BUDGET-IR < %t.budget.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare <vscale x 4 x float> @llvm.sqrt.nxv4f32(<vscale x 4 x float>)
declare <vscale x 4 x float> @llvm.fabs.nxv4f32(<vscale x 4 x float>)
declare <vscale x 4 x float> @llvm.fma.nxv4f32(<vscale x 4 x float>, <vscale x 4 x float>, <vscale x 4 x float>)
declare <vscale x 4 x float> @llvm.fmuladd.nxv4f32(<vscale x 4 x float>, <vscale x 4 x float>, <vscale x 4 x float>)
declare <vscale x 4 x float> @llvm.minnum.nxv4f32(<vscale x 4 x float>, <vscale x 4 x float>)
declare <vscale x 4 x float> @llvm.maxnum.nxv4f32(<vscale x 4 x float>, <vscale x 4 x float>)
declare <vscale x 4 x float> @llvm.minimum.nxv4f32(<vscale x 4 x float>, <vscale x 4 x float>)
declare <vscale x 4 x float> @llvm.maximum.nxv4f32(<vscale x 4 x float>, <vscale x 4 x float>)
declare <vscale x 4 x float> @llvm.ceil.nxv4f32(<vscale x 4 x float>)
declare <vscale x 4 x float> @llvm.floor.nxv4f32(<vscale x 4 x float>)
declare <vscale x 4 x float> @llvm.trunc.nxv4f32(<vscale x 4 x float>)
declare <vscale x 4 x float> @llvm.round.nxv4f32(<vscale x 4 x float>)
declare <vscale x 4 x float> @llvm.roundeven.nxv4f32(<vscale x 4 x float>)
declare <vscale x 4 x float> @llvm.rint.nxv4f32(<vscale x 4 x float>)
declare <vscale x 4 x float> @llvm.nearbyint.nxv4f32(<vscale x 4 x float>)
declare <vscale x 4 x float> @llvm.copysign.nxv4f32(<vscale x 4 x float>, <vscale x 4 x float>)
declare <vscale x 2 x double> @llvm.sqrt.nxv2f64(<vscale x 2 x double>)
declare <vscale x 2 x double> @llvm.trunc.nxv2f64(<vscale x 2 x double>)
declare <vscale x 8 x half> @llvm.sqrt.nxv8f16(<vscale x 8 x half>)
declare <vscale x 8 x half> @llvm.fabs.nxv8f16(<vscale x 8 x half>)
declare <vscale x 8 x half> @llvm.trunc.nxv8f16(<vscale x 8 x half>)
declare <vscale x 4 x float> @llvm.sin.nxv4f32(<vscale x 4 x float>)
declare <vscale x 4 x float> @llvm.canonicalize.nxv4f32(<vscale x 4 x float>)
declare <vscale x 2 x float> @llvm.sqrt.nxv2f32(<vscale x 2 x float>)

define <vscale x 4 x float> @protected_sqrt_f32(<vscale x 4 x float> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x float> @llvm.sqrt.nxv4f32(<vscale x 4 x float> %a)
  ret <vscale x 4 x float> %r
}

define <vscale x 4 x float> @protected_sqrt_nnan(<vscale x 4 x float> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call nnan <vscale x 4 x float> @llvm.sqrt.nxv4f32(<vscale x 4 x float> %a)
  ret <vscale x 4 x float> %r
}

define <vscale x 4 x float> @protected_fabs_f32(<vscale x 4 x float> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x float> @llvm.fabs.nxv4f32(<vscale x 4 x float> %a)
  ret <vscale x 4 x float> %r
}

define <vscale x 4 x float> @protected_fma_f32(<vscale x 4 x float> %a, <vscale x 4 x float> %b, <vscale x 4 x float> %c) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x float> @llvm.fma.nxv4f32(<vscale x 4 x float> %a, <vscale x 4 x float> %b, <vscale x 4 x float> %c)
  ret <vscale x 4 x float> %r
}

define <vscale x 4 x float> @protected_fmuladd_f32(<vscale x 4 x float> %a, <vscale x 4 x float> %b, <vscale x 4 x float> %c) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x float> @llvm.fmuladd.nxv4f32(<vscale x 4 x float> %a, <vscale x 4 x float> %b, <vscale x 4 x float> %c)
  ret <vscale x 4 x float> %r
}

define <vscale x 4 x float> @protected_minnum_f32(<vscale x 4 x float> %a, <vscale x 4 x float> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x float> @llvm.minnum.nxv4f32(<vscale x 4 x float> %a, <vscale x 4 x float> %b)
  ret <vscale x 4 x float> %r
}

define <vscale x 4 x float> @protected_maxnum_f32(<vscale x 4 x float> %a, <vscale x 4 x float> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x float> @llvm.maxnum.nxv4f32(<vscale x 4 x float> %a, <vscale x 4 x float> %b)
  ret <vscale x 4 x float> %r
}

define <vscale x 4 x float> @protected_minimum_f32(<vscale x 4 x float> %a, <vscale x 4 x float> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x float> @llvm.minimum.nxv4f32(<vscale x 4 x float> %a, <vscale x 4 x float> %b)
  ret <vscale x 4 x float> %r
}

define <vscale x 4 x float> @protected_maximum_f32(<vscale x 4 x float> %a, <vscale x 4 x float> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x float> @llvm.maximum.nxv4f32(<vscale x 4 x float> %a, <vscale x 4 x float> %b)
  ret <vscale x 4 x float> %r
}

define <vscale x 4 x float> @protected_ceil_f32(<vscale x 4 x float> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x float> @llvm.ceil.nxv4f32(<vscale x 4 x float> %a)
  ret <vscale x 4 x float> %r
}

define <vscale x 4 x float> @protected_floor_f32(<vscale x 4 x float> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x float> @llvm.floor.nxv4f32(<vscale x 4 x float> %a)
  ret <vscale x 4 x float> %r
}

define <vscale x 4 x float> @protected_trunc_f32(<vscale x 4 x float> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x float> @llvm.trunc.nxv4f32(<vscale x 4 x float> %a)
  ret <vscale x 4 x float> %r
}

define <vscale x 4 x float> @protected_round_f32(<vscale x 4 x float> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x float> @llvm.round.nxv4f32(<vscale x 4 x float> %a)
  ret <vscale x 4 x float> %r
}

define <vscale x 4 x float> @protected_roundeven_f32(<vscale x 4 x float> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x float> @llvm.roundeven.nxv4f32(<vscale x 4 x float> %a)
  ret <vscale x 4 x float> %r
}

define <vscale x 4 x float> @protected_rint_f32(<vscale x 4 x float> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x float> @llvm.rint.nxv4f32(<vscale x 4 x float> %a)
  ret <vscale x 4 x float> %r
}

define <vscale x 4 x float> @protected_nearbyint_f32(<vscale x 4 x float> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x float> @llvm.nearbyint.nxv4f32(<vscale x 4 x float> %a)
  ret <vscale x 4 x float> %r
}

define <vscale x 4 x float> @protected_copysign_f32(<vscale x 4 x float> %a, <vscale x 4 x float> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x float> @llvm.copysign.nxv4f32(<vscale x 4 x float> %a, <vscale x 4 x float> %b)
  ret <vscale x 4 x float> %r
}

define <vscale x 2 x double> @protected_sqrt_f64(<vscale x 2 x double> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 2 x double> @llvm.sqrt.nxv2f64(<vscale x 2 x double> %a)
  ret <vscale x 2 x double> %r
}

define <vscale x 2 x double> @protected_trunc_f64(<vscale x 2 x double> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 2 x double> @llvm.trunc.nxv2f64(<vscale x 2 x double> %a)
  ret <vscale x 2 x double> %r
}

define <vscale x 8 x half> @protected_sqrt_f16(<vscale x 8 x half> %a) noinline optnone "target-features"="+sve,+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 8 x half> @llvm.sqrt.nxv8f16(<vscale x 8 x half> %a)
  ret <vscale x 8 x half> %r
}

define <vscale x 8 x half> @protected_fabs_f16(<vscale x 8 x half> %a) noinline optnone "target-features"="+sve,+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 8 x half> @llvm.fabs.nxv8f16(<vscale x 8 x half> %a)
  ret <vscale x 8 x half> %r
}

define <vscale x 8 x half> @protected_trunc_f16(<vscale x 8 x half> %a) noinline optnone "target-features"="+sve,+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 8 x half> @llvm.trunc.nxv8f16(<vscale x 8 x half> %a)
  ret <vscale x 8 x half> %r
}

define <vscale x 4 x float> @unsupported_nofeat(<vscale x 4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x float> @llvm.sqrt.nxv4f32(<vscale x 4 x float> %a)
  ret <vscale x 4 x float> %r
}

define i32 @unsupported_internal_nofeat(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %a = load <vscale x 4 x float>, ptr %p, align 16
  %r = call <vscale x 4 x float> @llvm.sqrt.nxv4f32(<vscale x 4 x float> %a)
  ret i32 0
}

define <vscale x 8 x half> @unsupported_half_nofp16(<vscale x 8 x half> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 8 x half> @llvm.sqrt.nxv8f16(<vscale x 8 x half> %a)
  ret <vscale x 8 x half> %r
}

define i32 @unsupported_sin(<vscale x 4 x float> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x float> @llvm.sin.nxv4f32(<vscale x 4 x float> %a)
  ret i32 0
}

define i32 @unsupported_canonicalize(ptr %p) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %a = load <vscale x 4 x float>, ptr %p, align 16
  %r = call <vscale x 4 x float> @llvm.canonicalize.nxv4f32(<vscale x 4 x float> %a)
  ret i32 0
}

define i32 @unsupported_partial(ptr %p) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %a = load <vscale x 2 x float>, ptr %p, align 8
  %r = call <vscale x 2 x float> @llvm.sqrt.nxv2f32(<vscale x 2 x float> %a)
  ret i32 0
}

define i32 @unsupported_poison(<vscale x 4 x float> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x float> @llvm.sqrt.nxv4f32(<vscale x 4 x float> poison)
  ret i32 0
}

define void @main() {
entry:
  ret void
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_nofeat: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_internal_nofeat: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_half_nofp16: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_sin: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_canonicalize: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_partial: unsupported vector load instruction
; SKIP-DAG: Skipping VMP on unsupported_poison: unsupported float call instruction
; SKIP-NOT: Skipping VMP on protected_sqrt_f32:
; SKIP-NOT: Skipping VMP on protected_sqrt_nnan:
; SKIP-NOT: Skipping VMP on protected_fabs_f32:
; SKIP-NOT: Skipping VMP on protected_fma_f32:
; SKIP-NOT: Skipping VMP on protected_fmuladd_f32:
; SKIP-NOT: Skipping VMP on protected_minnum_f32:
; SKIP-NOT: Skipping VMP on protected_maxnum_f32:
; SKIP-NOT: Skipping VMP on protected_minimum_f32:
; SKIP-NOT: Skipping VMP on protected_maximum_f32:
; SKIP-NOT: Skipping VMP on protected_ceil_f32:
; SKIP-NOT: Skipping VMP on protected_floor_f32:
; SKIP-NOT: Skipping VMP on protected_trunc_f32:
; SKIP-NOT: Skipping VMP on protected_round_f32:
; SKIP-NOT: Skipping VMP on protected_roundeven_f32:
; SKIP-NOT: Skipping VMP on protected_rint_f32:
; SKIP-NOT: Skipping VMP on protected_nearbyint_f32:
; SKIP-NOT: Skipping VMP on protected_copysign_f32:
; SKIP-NOT: Skipping VMP on protected_sqrt_f64:
; SKIP-NOT: Skipping VMP on protected_trunc_f64:
; SKIP-NOT: Skipping VMP on protected_sqrt_f16:
; SKIP-NOT: Skipping VMP on protected_fabs_f16:
; SKIP-NOT: Skipping VMP on protected_trunc_f16:

; VIRT-LABEL: define <vscale x 4 x float> @protected_sqrt_f32(
; VIRT-SAME: #[[PROT:[0-9]+]]
; VIRT: vmp.sve.regs
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x float> @llvm.sqrt.nxv4f32(
; VIRT-LABEL: define <vscale x 4 x float> @protected_sqrt_nnan(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call nnan <vscale x 4 x float> @llvm.sqrt.nxv4f32(
; VIRT-LABEL: define <vscale x 4 x float> @protected_fabs_f32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x float> @llvm.fabs.nxv4f32(
; VIRT-LABEL: define <vscale x 4 x float> @protected_fma_f32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x float> @llvm.fma.nxv4f32(
; VIRT-LABEL: define <vscale x 4 x float> @protected_fmuladd_f32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x float> @llvm.fmuladd.nxv4f32(
; VIRT-LABEL: define <vscale x 4 x float> @protected_minnum_f32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x float> @llvm.minnum.nxv4f32(
; VIRT-LABEL: define <vscale x 4 x float> @protected_maxnum_f32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x float> @llvm.maxnum.nxv4f32(
; VIRT-LABEL: define <vscale x 4 x float> @protected_minimum_f32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x float> @llvm.minimum.nxv4f32(
; VIRT-LABEL: define <vscale x 4 x float> @protected_maximum_f32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x float> @llvm.maximum.nxv4f32(
; VIRT-LABEL: define <vscale x 4 x float> @protected_ceil_f32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x float> @llvm.ceil.nxv4f32(
; VIRT-LABEL: define <vscale x 4 x float> @protected_floor_f32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x float> @llvm.floor.nxv4f32(
; VIRT-LABEL: define <vscale x 4 x float> @protected_trunc_f32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x float> @llvm.trunc.nxv4f32(
; VIRT-LABEL: define <vscale x 4 x float> @protected_round_f32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x float> @llvm.round.nxv4f32(
; VIRT-LABEL: define <vscale x 4 x float> @protected_roundeven_f32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x float> @llvm.roundeven.nxv4f32(
; VIRT-LABEL: define <vscale x 4 x float> @protected_rint_f32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x float> @llvm.rint.nxv4f32(
; VIRT-LABEL: define <vscale x 4 x float> @protected_nearbyint_f32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x float> @llvm.nearbyint.nxv4f32(
; VIRT-LABEL: define <vscale x 4 x float> @protected_copysign_f32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x float> @llvm.copysign.nxv4f32(
; VIRT-LABEL: define <vscale x 2 x double> @protected_sqrt_f64(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 2 x double> @llvm.sqrt.nxv2f64(
; VIRT-LABEL: define <vscale x 2 x double> @protected_trunc_f64(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 2 x double> @llvm.trunc.nxv2f64(
; VIRT-LABEL: define <vscale x 8 x half> @protected_sqrt_f16(
; VIRT-SAME: #[[PROTHALF:[0-9]+]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 8 x half> @llvm.sqrt.nxv8f16(
; VIRT-LABEL: define <vscale x 8 x half> @protected_fabs_f16(
; VIRT-SAME: #[[PROTHALF]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 8 x half> @llvm.fabs.nxv8f16(
; VIRT-LABEL: define <vscale x 8 x half> @protected_trunc_f16(
; VIRT-SAME: #[[PROTHALF]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 8 x half> @llvm.trunc.nxv8f16(
; VIRT: define {{.*}} @unsupported_nofeat({{.*}} #[[UNSUP:[0-9]+]]
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[PROTHALF]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; ASM-DAG: fsqrt{{.*}}z{{[0-9]+}}.s
; ASM-DAG: fabs{{.*}}z{{[0-9]+}}.s
; ASM-DAG: fmad{{.*}}z{{[0-9]+}}.s
; ASM-DAG: fminnm{{.*}}z{{[0-9]+}}.s
; ASM-DAG: fmaxnm{{.*}}z{{[0-9]+}}.s
; ASM-DAG: fmin{{.*}}z{{[0-9]+}}.s
; ASM-DAG: fmax{{.*}}z{{[0-9]+}}.s
; ASM-DAG: frintp{{.*}}z{{[0-9]+}}.s
; ASM-DAG: frintm{{.*}}z{{[0-9]+}}.s
; ASM-DAG: frintz{{.*}}z{{[0-9]+}}.s
; ASM-DAG: frinta{{.*}}z{{[0-9]+}}.s
; ASM-DAG: frintn{{.*}}z{{[0-9]+}}.s
; ASM-DAG: frintx{{.*}}z{{[0-9]+}}.s
; ASM-DAG: frinti{{.*}}z{{[0-9]+}}.s
; ASM-DAG: and{{.*}}#0x80000000
; ASM-DAG: fsqrt{{.*}}z{{[0-9]+}}.d
; ASM-DAG: frintz{{.*}}z{{[0-9]+}}.d
; ASM-DAG: fsqrt{{.*}}z{{[0-9]+}}.h
; ASM-DAG: frintz{{.*}}z{{[0-9]+}}.h
; HOST: Skipping VMP: only AArch64 targets are supported
; BUDGET-ERR: Skipping VMP on protected_sqrt_f32: bytecode word budget
; BUDGET-IR-LABEL: define <vscale x 4 x float> @protected_sqrt_f32(
; BUDGET-IR-NOT: vmp.dispatch
; BUDGET-IR: call <vscale x 4 x float> @llvm.sqrt.nxv4f32(
