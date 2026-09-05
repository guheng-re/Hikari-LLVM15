; Restricted SVE predicate helpers: last-token +sve; full-register
; predicates nxv16i1 / nxv8i1 / nxv4i1 / nxv2i1.  IDs:
; llvm.experimental.vector.reverse, llvm.aarch64.sve.ptrue (i32 ImmArg
; pattern 0..31), llvm.aarch64.sve.cntp (two matching preds to i64),
; and llvm.aarch64.sve.ptest.any/first/last (two matching preds to i1).
; Reverse / ptrue write the nxv16i1 frame; cntp / ptest write the
; integer frame.  Predicate splice stays skipped (ISel legalizes via
; integer ext).  Host cannot execute AArch64 SVE.  FileCheck + AArch64
; llc/readobj/asm (llc: -mattr=+sve -fast-isel=false).  O0/O2 x 97/7.
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
declare <vscale x 16 x i1> @llvm.experimental.vector.reverse.nxv16i1(<vscale x 16 x i1>)
declare <vscale x 4 x i1> @llvm.experimental.vector.reverse.nxv4i1(<vscale x 4 x i1>)
declare <vscale x 2 x i1> @llvm.experimental.vector.reverse.nxv2i1(<vscale x 2 x i1>)
declare <vscale x 16 x i1> @llvm.aarch64.sve.ptrue.nxv16i1(i32)
declare <vscale x 4 x i1> @llvm.aarch64.sve.ptrue.nxv4i1(i32)
declare i64 @llvm.aarch64.sve.cntp.nxv4i1(<vscale x 4 x i1>, <vscale x 4 x i1>)
declare i64 @llvm.aarch64.sve.cntp.nxv16i1(<vscale x 16 x i1>, <vscale x 16 x i1>)
declare i1 @llvm.aarch64.sve.ptest.any.nxv4i1(<vscale x 4 x i1>, <vscale x 4 x i1>)
declare i1 @llvm.aarch64.sve.ptest.first.nxv16i1(<vscale x 16 x i1>, <vscale x 16 x i1>)
declare i1 @llvm.aarch64.sve.ptest.last.nxv4i1(<vscale x 4 x i1>, <vscale x 4 x i1>)
declare <vscale x 4 x i1> @llvm.experimental.vector.splice.nxv4i1(<vscale x 4 x i1>, <vscale x 4 x i1>, i32)
declare <vscale x 1 x i1> @llvm.aarch64.sve.ptrue.nxv1i1(i32)

define <vscale x 16 x i1> @protected_rev_p16(<vscale x 16 x i1> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 16 x i1> @llvm.experimental.vector.reverse.nxv16i1(<vscale x 16 x i1> %a)
  ret <vscale x 16 x i1> %r
}

define <vscale x 4 x i1> @protected_rev_p4(<vscale x 4 x i1> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i1> @llvm.experimental.vector.reverse.nxv4i1(<vscale x 4 x i1> %a)
  ret <vscale x 4 x i1> %r
}

define <vscale x 2 x i1> @protected_rev_p2(<vscale x 2 x i1> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 2 x i1> @llvm.experimental.vector.reverse.nxv2i1(<vscale x 2 x i1> %a)
  ret <vscale x 2 x i1> %r
}

define <vscale x 16 x i1> @protected_ptrue_all() noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 16 x i1> @llvm.aarch64.sve.ptrue.nxv16i1(i32 31)
  ret <vscale x 16 x i1> %r
}

define <vscale x 4 x i1> @protected_ptrue_s() noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i1> @llvm.aarch64.sve.ptrue.nxv4i1(i32 31)
  ret <vscale x 4 x i1> %r
}

define <vscale x 4 x i1> @protected_ptrue_vl1() noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i1> @llvm.aarch64.sve.ptrue.nxv4i1(i32 1)
  ret <vscale x 4 x i1> %r
}

define i64 @protected_cntp_p4(<vscale x 4 x i1> %pg, <vscale x 4 x i1> %pn) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.aarch64.sve.cntp.nxv4i1(<vscale x 4 x i1> %pg, <vscale x 4 x i1> %pn)
  ret i64 %r
}

define i64 @protected_cntp_p16(<vscale x 16 x i1> %pg, <vscale x 16 x i1> %pn) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.aarch64.sve.cntp.nxv16i1(<vscale x 16 x i1> %pg, <vscale x 16 x i1> %pn)
  ret i64 %r
}

define i1 @protected_ptest_any_p4(<vscale x 4 x i1> %pg, <vscale x 4 x i1> %pn) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call i1 @llvm.aarch64.sve.ptest.any.nxv4i1(<vscale x 4 x i1> %pg, <vscale x 4 x i1> %pn)
  ret i1 %r
}

define i1 @protected_ptest_first_p16(<vscale x 16 x i1> %pg, <vscale x 16 x i1> %pn) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call i1 @llvm.aarch64.sve.ptest.first.nxv16i1(<vscale x 16 x i1> %pg, <vscale x 16 x i1> %pn)
  ret i1 %r
}

define i1 @protected_ptest_last_p4(<vscale x 4 x i1> %pg, <vscale x 4 x i1> %pn) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call i1 @llvm.aarch64.sve.ptest.last.nxv4i1(<vscale x 4 x i1> %pg, <vscale x 4 x i1> %pn)
  ret i1 %r
}

define <vscale x 4 x i1> @unsupported_nofeat_ptrue() noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i1> @llvm.aarch64.sve.ptrue.nxv4i1(i32 31)
  ret <vscale x 4 x i1> %r
}

define i32 @unsupported_internal_nofeat() noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i1> @llvm.aarch64.sve.ptrue.nxv4i1(i32 31)
  ret i32 0
}

define i32 @unsupported_pred_splice(<vscale x 4 x i1> %a, <vscale x 4 x i1> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i1> @llvm.experimental.vector.splice.nxv4i1(<vscale x 4 x i1> %a, <vscale x 4 x i1> %b, i32 1)
  ret i32 0
}

define i32 @unsupported_poison_ptest(<vscale x 4 x i1> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call i1 @llvm.aarch64.sve.ptest.any.nxv4i1(<vscale x 4 x i1> %a, <vscale x 4 x i1> poison)
  ret i32 0
}

define i32 @unsupported_poison_rev(<vscale x 4 x i1> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i1> @llvm.experimental.vector.reverse.nxv4i1(<vscale x 4 x i1> poison)
  ret i32 0
}

define <vscale x 4 x i1> @unsupported_ptrue_pat32() noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i1> @llvm.aarch64.sve.ptrue.nxv4i1(i32 32)
  ret <vscale x 4 x i1> %r
}

define i32 @unsupported_nxv1(<vscale x 4 x i1> %unused) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 1 x i1> @llvm.aarch64.sve.ptrue.nxv1i1(i32 31)
  ret i32 0
}

define void @main() {
entry:
  ret void
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_nofeat_ptrue: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_internal_nofeat: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_pred_splice: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_poison_ptest: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_poison_rev: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_ptrue_pat32: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_nxv1: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_rev_p16:
; SKIP-NOT: Skipping VMP on protected_rev_p4:
; SKIP-NOT: Skipping VMP on protected_rev_p2:
; SKIP-NOT: Skipping VMP on protected_ptrue_all:
; SKIP-NOT: Skipping VMP on protected_ptrue_s:
; SKIP-NOT: Skipping VMP on protected_ptrue_vl1:
; SKIP-NOT: Skipping VMP on protected_cntp_p4:
; SKIP-NOT: Skipping VMP on protected_cntp_p16:
; SKIP-NOT: Skipping VMP on protected_ptest_any_p4:
; SKIP-NOT: Skipping VMP on protected_ptest_first_p16:
; SKIP-NOT: Skipping VMP on protected_ptest_last_p4:

; VIRT-LABEL: define <vscale x 16 x i1> @protected_rev_p16(
; VIRT-SAME: #[[PROT:[0-9]+]]
; VIRT: vmp.sve.preds
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 16 x i1> @llvm.experimental.vector.reverse.nxv16i1(
; VIRT-LABEL: define <vscale x 4 x i1> @protected_rev_p4(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x i1> @llvm.experimental.vector.reverse.nxv4i1(
; VIRT-LABEL: define <vscale x 2 x i1> @protected_rev_p2(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 2 x i1> @llvm.experimental.vector.reverse.nxv2i1(
; VIRT-LABEL: define <vscale x 16 x i1> @protected_ptrue_all(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 16 x i1> @llvm.aarch64.sve.ptrue.nxv16i1(i32 31)
; VIRT-LABEL: define <vscale x 4 x i1> @protected_ptrue_s(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x i1> @llvm.aarch64.sve.ptrue.nxv4i1(i32 31)
; VIRT-LABEL: define <vscale x 4 x i1> @protected_ptrue_vl1(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x i1> @llvm.aarch64.sve.ptrue.nxv4i1(i32 1)
; VIRT-LABEL: define i64 @protected_cntp_p4(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.aarch64.sve.cntp.nxv4i1(
; VIRT-LABEL: define i64 @protected_cntp_p16(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.aarch64.sve.cntp.nxv16i1(
; VIRT-LABEL: define i1 @protected_ptest_any_p4(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call i1 @llvm.aarch64.sve.ptest.any.nxv4i1(
; VIRT-LABEL: define i1 @protected_ptest_first_p16(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call i1 @llvm.aarch64.sve.ptest.first.nxv16i1(
; VIRT-LABEL: define i1 @protected_ptest_last_p4(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call i1 @llvm.aarch64.sve.ptest.last.nxv4i1(
; VIRT: define {{.*}} @unsupported_nofeat_ptrue({{.*}} #[[UNSUP:[0-9]+]]
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; ASM-DAG: rev{{.*}}p{{[0-9]+}}.b
; ASM-DAG: rev{{.*}}p{{[0-9]+}}.s
; ASM-DAG: rev{{.*}}p{{[0-9]+}}.d
; ASM-DAG: ptrue{{.*}}p{{[0-9]+}}.b
; ASM-DAG: ptrue{{.*}}p{{[0-9]+}}.s
; ASM-DAG: cntp{{.*}}p{{[0-9]+}}
; ASM-DAG: ptest{{.*}}p{{[0-9]+}}
; HOST: Skipping VMP: only AArch64 targets are supported
; BUDGET-ERR: Skipping VMP on protected_rev_p16: bytecode word budget
; BUDGET-IR-LABEL: define <vscale x 16 x i1> @protected_rev_p16(
; BUDGET-IR-NOT: vmp.dispatch
; BUDGET-IR: call <vscale x 16 x i1> @llvm.experimental.vector.reverse.nxv16i1(
