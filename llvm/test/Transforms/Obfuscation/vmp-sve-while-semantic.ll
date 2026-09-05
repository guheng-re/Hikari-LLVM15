; Restricted base-SVE whilelo/lt/le/ls and the existing
; llvm.get.active.lane.mask surface: last-token +sve; full-register
; predicates; i32/i64 start+limit.  Dest on the nxv16i1 frame
; (ScalableActiveLaneMask).  SVE2 whilege/gt/hs/hi stay skipped
; (Cannot select without +sve2).  nxv1i1 cannot select.  Host cannot
; execute AArch64 SVE.  FileCheck + AArch64 llc/readobj/asm
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
declare <vscale x 4 x i1> @llvm.aarch64.sve.whilelo.nxv4i1.i64(i64, i64)
declare <vscale x 4 x i1> @llvm.aarch64.sve.whilelo.nxv4i1.i32(i32, i32)
declare <vscale x 16 x i1> @llvm.aarch64.sve.whilelo.nxv16i1.i64(i64, i64)
declare <vscale x 8 x i1> @llvm.aarch64.sve.whilelt.nxv8i1.i64(i64, i64)
declare <vscale x 2 x i1> @llvm.aarch64.sve.whilele.nxv2i1.i64(i64, i64)
declare <vscale x 4 x i1> @llvm.aarch64.sve.whilels.nxv4i1.i64(i64, i64)
declare <vscale x 4 x i1> @llvm.get.active.lane.mask.nxv4i1.i64(i64, i64)
declare <vscale x 4 x i1> @llvm.aarch64.sve.whilege.nxv4i1.i64(i64, i64)
declare <vscale x 1 x i1> @llvm.aarch64.sve.whilelo.nxv1i1.i64(i64, i64)

define <vscale x 4 x i1> @protected_whilelo_i64(i64 %a, i64 %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i1> @llvm.aarch64.sve.whilelo.nxv4i1.i64(i64 %a, i64 %b)
  ret <vscale x 4 x i1> %r
}

define <vscale x 4 x i1> @protected_whilelo_i32(i32 %a, i32 %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i1> @llvm.aarch64.sve.whilelo.nxv4i1.i32(i32 %a, i32 %b)
  ret <vscale x 4 x i1> %r
}

define <vscale x 16 x i1> @protected_whilelo_b(i64 %a, i64 %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 16 x i1> @llvm.aarch64.sve.whilelo.nxv16i1.i64(i64 %a, i64 %b)
  ret <vscale x 16 x i1> %r
}

define <vscale x 8 x i1> @protected_whilelt(i64 %a, i64 %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 8 x i1> @llvm.aarch64.sve.whilelt.nxv8i1.i64(i64 %a, i64 %b)
  ret <vscale x 8 x i1> %r
}

define <vscale x 2 x i1> @protected_whilele(i64 %a, i64 %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 2 x i1> @llvm.aarch64.sve.whilele.nxv2i1.i64(i64 %a, i64 %b)
  ret <vscale x 2 x i1> %r
}

define <vscale x 4 x i1> @protected_whilels(i64 %a, i64 %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i1> @llvm.aarch64.sve.whilels.nxv4i1.i64(i64 %a, i64 %b)
  ret <vscale x 4 x i1> %r
}

define <vscale x 4 x i1> @protected_alm(i64 %a, i64 %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i1> @llvm.get.active.lane.mask.nxv4i1.i64(i64 %a, i64 %b)
  ret <vscale x 4 x i1> %r
}

define <vscale x 4 x i1> @unsupported_nofeat(i64 %a, i64 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i1> @llvm.aarch64.sve.whilelo.nxv4i1.i64(i64 %a, i64 %b)
  ret <vscale x 4 x i1> %r
}

define i32 @unsupported_internal_nofeat(i64 %a, i64 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i1> @llvm.aarch64.sve.whilelo.nxv4i1.i64(i64 %a, i64 %b)
  ret i32 0
}

define i32 @unsupported_whilege(i64 %a, i64 %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i1> @llvm.aarch64.sve.whilege.nxv4i1.i64(i64 %a, i64 %b)
  ret i32 0
}

define i32 @unsupported_nxv1(i64 %a, i64 %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 1 x i1> @llvm.aarch64.sve.whilelo.nxv1i1.i64(i64 %a, i64 %b)
  ret i32 0
}

define i32 @unsupported_poison(i64 %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i1> @llvm.aarch64.sve.whilelo.nxv4i1.i64(i64 %a, i64 poison)
  ret i32 0
}

define void @main() {
entry:
  ret void
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_nofeat: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_internal_nofeat: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_whilege: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_nxv1: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_poison: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_whilelo_i64:
; SKIP-NOT: Skipping VMP on protected_whilelo_i32:
; SKIP-NOT: Skipping VMP on protected_whilelo_b:
; SKIP-NOT: Skipping VMP on protected_whilelt:
; SKIP-NOT: Skipping VMP on protected_whilele:
; SKIP-NOT: Skipping VMP on protected_whilels:
; SKIP-NOT: Skipping VMP on protected_alm:

; VIRT-LABEL: define <vscale x 4 x i1> @protected_whilelo_i64(
; VIRT-SAME: #[[PROT:[0-9]+]]
; VIRT: vmp.sve.preds
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x i1> @llvm.aarch64.sve.whilelo.nxv4i1.i64(
; VIRT-LABEL: define <vscale x 4 x i1> @protected_whilelo_i32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x i1> @llvm.aarch64.sve.whilelo.nxv4i1.i32(
; VIRT-LABEL: define <vscale x 16 x i1> @protected_whilelo_b(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 16 x i1> @llvm.aarch64.sve.whilelo.nxv16i1.i64(
; VIRT-LABEL: define <vscale x 8 x i1> @protected_whilelt(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 8 x i1> @llvm.aarch64.sve.whilelt.nxv8i1.i64(
; VIRT-LABEL: define <vscale x 2 x i1> @protected_whilele(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 2 x i1> @llvm.aarch64.sve.whilele.nxv2i1.i64(
; VIRT-LABEL: define <vscale x 4 x i1> @protected_whilels(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x i1> @llvm.aarch64.sve.whilels.nxv4i1.i64(
; VIRT-LABEL: define <vscale x 4 x i1> @protected_alm(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x i1> @llvm.get.active.lane.mask.nxv4i1.i64(
; VIRT: define {{.*}} @unsupported_nofeat({{.*}} #[[UNSUP:[0-9]+]]
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; ASM-DAG: whilelo{{.*}}p{{[0-9]+}}.s
; ASM-DAG: whilelo{{.*}}p{{[0-9]+}}.b
; ASM-DAG: whilelt{{.*}}p{{[0-9]+}}.h
; ASM-DAG: whilele{{.*}}p{{[0-9]+}}.d
; ASM-DAG: whilels{{.*}}p{{[0-9]+}}.s
; HOST: Skipping VMP: only AArch64 targets are supported
; BUDGET-ERR: Skipping VMP on protected_whilelo_i64: bytecode word budget
; BUDGET-IR-LABEL: define <vscale x 4 x i1> @protected_whilelo_i64(
; BUDGET-IR-NOT: vmp.dispatch
; BUDGET-IR: call <vscale x 4 x i1> @llvm.aarch64.sve.whilelo.nxv4i1.i64(
