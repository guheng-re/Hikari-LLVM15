; Restricted same-lane full-register SVE llvm.fptosi.sat / llvm.fptoui.sat:
; last-token +sve; nxv4f32->nxv4i32, nxv2f64->nxv2i64; nxv8f16->nxv8i16
; also last-token +fullfp16.  Both sides reuse the nxv16i8 data frame.
; Rebuilt as the same intrinsic (not CallDescriptor, not plain fptosi).
; Mismatched element width and partial-register forms stay skipped.
; Host cannot execute AArch64 SVE.  FileCheck + AArch64 llc/readobj/asm
; (llc: -mattr=+sve,+fullfp16 -fast-isel=false).  O0/O2 x 97/7.
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
declare <vscale x 4 x i32> @llvm.fptosi.sat.nxv4i32.nxv4f32(<vscale x 4 x float>)
declare <vscale x 4 x i32> @llvm.fptoui.sat.nxv4i32.nxv4f32(<vscale x 4 x float>)
declare <vscale x 2 x i64> @llvm.fptosi.sat.nxv2i64.nxv2f64(<vscale x 2 x double>)
declare <vscale x 2 x i64> @llvm.fptoui.sat.nxv2i64.nxv2f64(<vscale x 2 x double>)
declare <vscale x 8 x i16> @llvm.fptosi.sat.nxv8i16.nxv8f16(<vscale x 8 x half>)
declare <vscale x 8 x i16> @llvm.fptoui.sat.nxv8i16.nxv8f16(<vscale x 8 x half>)
declare <vscale x 4 x i32> @llvm.fptosi.sat.nxv4i32.nxv4f16(<vscale x 4 x half>)

define <vscale x 4 x i32> @protected_si_f32(<vscale x 4 x float> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.fptosi.sat.nxv4i32.nxv4f32(<vscale x 4 x float> %a)
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @protected_ui_f32(<vscale x 4 x float> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.fptoui.sat.nxv4i32.nxv4f32(<vscale x 4 x float> %a)
  ret <vscale x 4 x i32> %r
}

define <vscale x 2 x i64> @protected_si_f64(<vscale x 2 x double> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 2 x i64> @llvm.fptosi.sat.nxv2i64.nxv2f64(<vscale x 2 x double> %a)
  ret <vscale x 2 x i64> %r
}

define <vscale x 2 x i64> @protected_ui_f64(<vscale x 2 x double> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 2 x i64> @llvm.fptoui.sat.nxv2i64.nxv2f64(<vscale x 2 x double> %a)
  ret <vscale x 2 x i64> %r
}

define <vscale x 8 x i16> @protected_si_f16(<vscale x 8 x half> %a) noinline optnone "target-features"="+sve,+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 8 x i16> @llvm.fptosi.sat.nxv8i16.nxv8f16(<vscale x 8 x half> %a)
  ret <vscale x 8 x i16> %r
}

define <vscale x 8 x i16> @protected_ui_f16(<vscale x 8 x half> %a) noinline optnone "target-features"="+sve,+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 8 x i16> @llvm.fptoui.sat.nxv8i16.nxv8f16(<vscale x 8 x half> %a)
  ret <vscale x 8 x i16> %r
}

define <vscale x 4 x i32> @unsupported_nofeat(<vscale x 4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.fptosi.sat.nxv4i32.nxv4f32(<vscale x 4 x float> %a)
  ret <vscale x 4 x i32> %r
}

define i32 @unsupported_internal_nofeat(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %a = load <vscale x 4 x float>, ptr %p, align 16
  %r = call <vscale x 4 x i32> @llvm.fptosi.sat.nxv4i32.nxv4f32(<vscale x 4 x float> %a)
  ret i32 0
}

define i32 @unsupported_half_nofp16(ptr %p) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %a = load <vscale x 8 x half>, ptr %p, align 16
  %r = call <vscale x 8 x i16> @llvm.fptosi.sat.nxv8i16.nxv8f16(<vscale x 8 x half> %a)
  ret i32 0
}

define i32 @unsupported_mismatch(ptr %p) noinline optnone "target-features"="+sve,+fullfp16" {
entry:
  call void @hikari_vmp()
  %a = load <vscale x 4 x half>, ptr %p, align 8
  %r = call <vscale x 4 x i32> @llvm.fptosi.sat.nxv4i32.nxv4f16(<vscale x 4 x half> %a)
  ret i32 0
}

define i32 @unsupported_poison(<vscale x 4 x float> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.fptosi.sat.nxv4i32.nxv4f32(<vscale x 4 x float> poison)
  ret i32 0
}

define void @main() {
entry:
  ret void
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_nofeat: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_internal_nofeat: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_half_nofp16: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_mismatch: unsupported vector load instruction
; SKIP-DAG: Skipping VMP on unsupported_poison: unsupported fptosi.sat
; SKIP-NOT: Skipping VMP on protected_si_f32:
; SKIP-NOT: Skipping VMP on protected_ui_f32:
; SKIP-NOT: Skipping VMP on protected_si_f64:
; SKIP-NOT: Skipping VMP on protected_ui_f64:
; SKIP-NOT: Skipping VMP on protected_si_f16:
; SKIP-NOT: Skipping VMP on protected_ui_f16:

; VIRT-LABEL: define <vscale x 4 x i32> @protected_si_f32(
; VIRT-SAME: #[[PROT:[0-9]+]]
; VIRT: vmp.sve.regs
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x i32> @llvm.fptosi.sat.nxv4i32.nxv4f32(
; VIRT-LABEL: define <vscale x 4 x i32> @protected_ui_f32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x i32> @llvm.fptoui.sat.nxv4i32.nxv4f32(
; VIRT-LABEL: define <vscale x 2 x i64> @protected_si_f64(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 2 x i64> @llvm.fptosi.sat.nxv2i64.nxv2f64(
; VIRT-LABEL: define <vscale x 2 x i64> @protected_ui_f64(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 2 x i64> @llvm.fptoui.sat.nxv2i64.nxv2f64(
; VIRT-LABEL: define <vscale x 8 x i16> @protected_si_f16(
; VIRT-SAME: #[[PROTHALF:[0-9]+]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 8 x i16> @llvm.fptosi.sat.nxv8i16.nxv8f16(
; VIRT-LABEL: define <vscale x 8 x i16> @protected_ui_f16(
; VIRT-SAME: #[[PROTHALF]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 8 x i16> @llvm.fptoui.sat.nxv8i16.nxv8f16(
; VIRT: define {{.*}} @unsupported_nofeat({{.*}} #[[UNSUP:[0-9]+]]
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[PROTHALF]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; ASM-DAG: fcvtzs{{.*}}z{{[0-9]+}}.s
; ASM-DAG: fcvtzu{{.*}}z{{[0-9]+}}.s
; ASM-DAG: fcvtzs{{.*}}z{{[0-9]+}}.d
; ASM-DAG: fcvtzu{{.*}}z{{[0-9]+}}.d
; ASM-DAG: fcvtzs{{.*}}z{{[0-9]+}}.h
; ASM-DAG: fcvtzu{{.*}}z{{[0-9]+}}.h
; HOST: Skipping VMP: only AArch64 targets are supported
; BUDGET-ERR: Skipping VMP on protected_si_f32: bytecode word budget
; BUDGET-IR-LABEL: define <vscale x 4 x i32> @protected_si_f32(
; BUDGET-IR-NOT: vmp.dispatch
; BUDGET-IR: call <vscale x 4 x i32> @llvm.fptosi.sat.nxv4i32.nxv4f32(
