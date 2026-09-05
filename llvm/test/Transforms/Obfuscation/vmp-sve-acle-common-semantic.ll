; Common ACLE SVE leftovers: last-token +sve; full-register data /
; predicates.  Predicated add/mul/sdiv/sel/fadd, convert.to/from.svbool,
; and_z, cntb, lasta, dup.x, index, zip1, compact (.s), cmpeq, abs.
; i8/i16 sdiv and compact stay skipped (Cannot select).  Host cannot
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
declare <vscale x 4 x i32> @llvm.aarch64.sve.add.nxv4i32(<vscale x 4 x i1>, <vscale x 4 x i32>, <vscale x 4 x i32>)
declare <vscale x 16 x i8> @llvm.aarch64.sve.mul.nxv16i8(<vscale x 16 x i1>, <vscale x 16 x i8>, <vscale x 16 x i8>)
declare <vscale x 4 x i32> @llvm.aarch64.sve.sdiv.nxv4i32(<vscale x 4 x i1>, <vscale x 4 x i32>, <vscale x 4 x i32>)
declare <vscale x 16 x i8> @llvm.aarch64.sve.sdiv.nxv16i8(<vscale x 16 x i1>, <vscale x 16 x i8>, <vscale x 16 x i8>)
declare <vscale x 4 x float> @llvm.aarch64.sve.sel.nxv4f32(<vscale x 4 x i1>, <vscale x 4 x float>, <vscale x 4 x float>)
declare <vscale x 4 x float> @llvm.aarch64.sve.fadd.nxv4f32(<vscale x 4 x i1>, <vscale x 4 x float>, <vscale x 4 x float>)
declare <vscale x 4 x i1> @llvm.aarch64.sve.and.z.nxv4i1(<vscale x 4 x i1>, <vscale x 4 x i1>, <vscale x 4 x i1>)
declare <vscale x 16 x i1> @llvm.aarch64.sve.convert.to.svbool.nxv4i1(<vscale x 4 x i1>)
declare <vscale x 4 x i1> @llvm.aarch64.sve.convert.from.svbool.nxv4i1(<vscale x 16 x i1>)
declare i64 @llvm.aarch64.sve.cntb(i32)
declare i32 @llvm.aarch64.sve.lasta.nxv4i32(<vscale x 4 x i1>, <vscale x 4 x i32>)
declare <vscale x 4 x i32> @llvm.aarch64.sve.dup.x.nxv4i32(i32)
declare <vscale x 4 x i32> @llvm.aarch64.sve.index.nxv4i32(i32, i32)
declare <vscale x 4 x i32> @llvm.aarch64.sve.zip1.nxv4i32(<vscale x 4 x i32>, <vscale x 4 x i32>)
declare <vscale x 4 x i32> @llvm.aarch64.sve.compact.nxv4i32(<vscale x 4 x i1>, <vscale x 4 x i32>)
declare <vscale x 16 x i8> @llvm.aarch64.sve.compact.nxv16i8(<vscale x 16 x i1>, <vscale x 16 x i8>)
declare <vscale x 4 x i1> @llvm.aarch64.sve.cmpeq.nxv4i32(<vscale x 4 x i1>, <vscale x 4 x i32>, <vscale x 4 x i32>)
declare <vscale x 4 x i32> @llvm.aarch64.sve.abs.nxv4i32(<vscale x 4 x i32>, <vscale x 4 x i1>, <vscale x 4 x i32>)

define <vscale x 4 x i32> @protected_add(<vscale x 4 x i1> %p, <vscale x 4 x i32> %a, <vscale x 4 x i32> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.aarch64.sve.add.nxv4i32(<vscale x 4 x i1> %p, <vscale x 4 x i32> %a, <vscale x 4 x i32> %b)
  ret <vscale x 4 x i32> %r
}

define <vscale x 16 x i8> @protected_mul(<vscale x 16 x i1> %p, <vscale x 16 x i8> %a, <vscale x 16 x i8> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 16 x i8> @llvm.aarch64.sve.mul.nxv16i8(<vscale x 16 x i1> %p, <vscale x 16 x i8> %a, <vscale x 16 x i8> %b)
  ret <vscale x 16 x i8> %r
}

define <vscale x 4 x i32> @protected_sdiv(<vscale x 4 x i1> %p, <vscale x 4 x i32> %a, <vscale x 4 x i32> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.aarch64.sve.sdiv.nxv4i32(<vscale x 4 x i1> %p, <vscale x 4 x i32> %a, <vscale x 4 x i32> %b)
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x float> @protected_sel_f32(<vscale x 4 x i1> %p, <vscale x 4 x float> %a, <vscale x 4 x float> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x float> @llvm.aarch64.sve.sel.nxv4f32(<vscale x 4 x i1> %p, <vscale x 4 x float> %a, <vscale x 4 x float> %b)
  ret <vscale x 4 x float> %r
}

define <vscale x 4 x float> @protected_fadd(<vscale x 4 x i1> %p, <vscale x 4 x float> %a, <vscale x 4 x float> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x float> @llvm.aarch64.sve.fadd.nxv4f32(<vscale x 4 x i1> %p, <vscale x 4 x float> %a, <vscale x 4 x float> %b)
  ret <vscale x 4 x float> %r
}

define <vscale x 4 x i1> @protected_andz(<vscale x 4 x i1> %pg, <vscale x 4 x i1> %a, <vscale x 4 x i1> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i1> @llvm.aarch64.sve.and.z.nxv4i1(<vscale x 4 x i1> %pg, <vscale x 4 x i1> %a, <vscale x 4 x i1> %b)
  ret <vscale x 4 x i1> %r
}

define <vscale x 16 x i1> @protected_to_svbool(<vscale x 4 x i1> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 16 x i1> @llvm.aarch64.sve.convert.to.svbool.nxv4i1(<vscale x 4 x i1> %a)
  ret <vscale x 16 x i1> %r
}

define <vscale x 4 x i1> @protected_from_svbool(<vscale x 16 x i1> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i1> @llvm.aarch64.sve.convert.from.svbool.nxv4i1(<vscale x 16 x i1> %a)
  ret <vscale x 4 x i1> %r
}

define i64 @protected_cntb() noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.aarch64.sve.cntb(i32 31)
  ret i64 %r
}

define i32 @protected_lasta(<vscale x 4 x i1> %p, <vscale x 4 x i32> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.sve.lasta.nxv4i32(<vscale x 4 x i1> %p, <vscale x 4 x i32> %a)
  ret i32 %r
}

define <vscale x 4 x i32> @protected_dupx(i32 %s) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.aarch64.sve.dup.x.nxv4i32(i32 %s)
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @protected_index(i32 %s, i32 %st) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.aarch64.sve.index.nxv4i32(i32 %s, i32 %st)
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @protected_zip1(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.aarch64.sve.zip1.nxv4i32(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b)
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @protected_compact(<vscale x 4 x i1> %p, <vscale x 4 x i32> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.aarch64.sve.compact.nxv4i32(<vscale x 4 x i1> %p, <vscale x 4 x i32> %a)
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i1> @protected_cmpeq(<vscale x 4 x i1> %p, <vscale x 4 x i32> %a, <vscale x 4 x i32> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i1> @llvm.aarch64.sve.cmpeq.nxv4i32(<vscale x 4 x i1> %p, <vscale x 4 x i32> %a, <vscale x 4 x i32> %b)
  ret <vscale x 4 x i1> %r
}

define <vscale x 4 x i32> @protected_abs(<vscale x 4 x i32> %in, <vscale x 4 x i1> %p, <vscale x 4 x i32> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.aarch64.sve.abs.nxv4i32(<vscale x 4 x i32> %in, <vscale x 4 x i1> %p, <vscale x 4 x i32> %a)
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @unsupported_nofeat(<vscale x 4 x i1> %p, <vscale x 4 x i32> %a, <vscale x 4 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.aarch64.sve.add.nxv4i32(<vscale x 4 x i1> %p, <vscale x 4 x i32> %a, <vscale x 4 x i32> %b)
  ret <vscale x 4 x i32> %r
}

define i32 @unsupported_sdiv_i8(<vscale x 16 x i1> %p, <vscale x 16 x i8> %a, <vscale x 16 x i8> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 16 x i8> @llvm.aarch64.sve.sdiv.nxv16i8(<vscale x 16 x i1> %p, <vscale x 16 x i8> %a, <vscale x 16 x i8> %b)
  ret i32 0
}

define i32 @unsupported_compact_i8(<vscale x 16 x i1> %p, <vscale x 16 x i8> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 16 x i8> @llvm.aarch64.sve.compact.nxv16i8(<vscale x 16 x i1> %p, <vscale x 16 x i8> %a)
  ret i32 0
}

define i32 @unsupported_poison(<vscale x 4 x i1> %p, <vscale x 4 x i32> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.aarch64.sve.add.nxv4i32(<vscale x 4 x i1> %p, <vscale x 4 x i32> %a, <vscale x 4 x i32> poison)
  ret i32 0
}

define void @main() {
entry:
  ret void
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_nofeat: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_sdiv_i8: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_compact_i8: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_poison: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_add:
; SKIP-NOT: Skipping VMP on protected_mul:
; SKIP-NOT: Skipping VMP on protected_sdiv:
; SKIP-NOT: Skipping VMP on protected_sel_f32:
; SKIP-NOT: Skipping VMP on protected_fadd:
; SKIP-NOT: Skipping VMP on protected_andz:
; SKIP-NOT: Skipping VMP on protected_to_svbool:
; SKIP-NOT: Skipping VMP on protected_from_svbool:
; SKIP-NOT: Skipping VMP on protected_cntb:
; SKIP-NOT: Skipping VMP on protected_lasta:
; SKIP-NOT: Skipping VMP on protected_dupx:
; SKIP-NOT: Skipping VMP on protected_index:
; SKIP-NOT: Skipping VMP on protected_zip1:
; SKIP-NOT: Skipping VMP on protected_compact:
; SKIP-NOT: Skipping VMP on protected_cmpeq:
; SKIP-NOT: Skipping VMP on protected_abs:

; VIRT-LABEL: define <vscale x 4 x i32> @protected_add(
; VIRT-SAME: #[[PROT:[0-9]+]]
; VIRT: vmp.sve.regs
; VIRT: vmp.sve.preds
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x i32> @llvm.aarch64.sve.add.nxv4i32(
; VIRT-LABEL: define <vscale x 16 x i8> @protected_mul(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 16 x i8> @llvm.aarch64.sve.mul.nxv16i8(
; VIRT-LABEL: define <vscale x 4 x i32> @protected_sdiv(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x i32> @llvm.aarch64.sve.sdiv.nxv4i32(
; VIRT-LABEL: define <vscale x 4 x float> @protected_sel_f32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x float> @llvm.aarch64.sve.sel.nxv4f32(
; VIRT-LABEL: define <vscale x 4 x float> @protected_fadd(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x float> @llvm.aarch64.sve.fadd.nxv4f32(
; VIRT-LABEL: define <vscale x 4 x i1> @protected_andz(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x i1> @llvm.aarch64.sve.and.z.nxv4i1(
; VIRT-LABEL: define <vscale x 16 x i1> @protected_to_svbool(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 16 x i1> @llvm.aarch64.sve.convert.to.svbool.nxv4i1(
; VIRT-LABEL: define <vscale x 4 x i1> @protected_from_svbool(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x i1> @llvm.aarch64.sve.convert.from.svbool.nxv4i1(
; VIRT-LABEL: define i64 @protected_cntb(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.aarch64.sve.cntb(i32 31)
; VIRT-LABEL: define i32 @protected_lasta(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.sve.lasta.nxv4i32(
; VIRT-LABEL: define <vscale x 4 x i32> @protected_dupx(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x i32> @llvm.aarch64.sve.dup.x.nxv4i32(
; VIRT-LABEL: define <vscale x 4 x i32> @protected_index(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x i32> @llvm.aarch64.sve.index.nxv4i32(
; VIRT-LABEL: define <vscale x 4 x i32> @protected_zip1(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x i32> @llvm.aarch64.sve.zip1.nxv4i32(
; VIRT-LABEL: define <vscale x 4 x i32> @protected_compact(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x i32> @llvm.aarch64.sve.compact.nxv4i32(
; VIRT-LABEL: define <vscale x 4 x i1> @protected_cmpeq(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x i1> @llvm.aarch64.sve.cmpeq.nxv4i32(
; VIRT-LABEL: define <vscale x 4 x i32> @protected_abs(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x i32> @llvm.aarch64.sve.abs.nxv4i32(
; VIRT: define {{.*}} @unsupported_nofeat({{.*}} #[[UNSUP:[0-9]+]]
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; ASM-DAG: add{{.*}}p{{[0-9]+}}/m
; ASM-DAG: mul{{.*}}p{{[0-9]+}}/m
; ASM-DAG: sdiv{{.*}}p{{[0-9]+}}/m
; ASM-DAG: sel{{.*}}z
; ASM-DAG: fadd{{.*}}p{{[0-9]+}}/m
; ASM-DAG: and{{.*}}p{{[0-9]+}}/z
; ASM-DAG: cntb
; ASM-DAG: lasta
; ASM-DAG: index{{.*}}z
; ASM-DAG: zip1{{.*}}z
; ASM-DAG: compact{{.*}}z
; ASM-DAG: cmpeq{{.*}}p
; ASM-DAG: abs{{.*}}p{{[0-9]+}}/m
; HOST: Skipping VMP: only AArch64 targets are supported
; BUDGET-ERR: Skipping VMP on protected_add: bytecode word budget
; BUDGET-IR-LABEL: define <vscale x 4 x i32> @protected_add(
; BUDGET-IR-NOT: vmp.dispatch
; BUDGET-IR: call <vscale x 4 x i32> @llvm.aarch64.sve.add.nxv4i32(
