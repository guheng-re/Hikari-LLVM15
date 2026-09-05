; Restricted SVE same-granule bitcast, llvm.experimental.stepvector,
; llvm.experimental.vector.reverse, and llvm.get.active.lane.mask.
; last-token +sve; full-register data / matching predicates; nxv8f16
; also last-token +fullfp16.  Bitcast/step/reverse use the nxv16i8
; frame; active.lane.mask writes the nxv16i1 frame.  Host cannot
; execute AArch64 SVE.  FileCheck + AArch64 llc/readobj/asm (llc:
; -mattr=+sve,+fullfp16 -fast-isel=false).  O0/O2 x 97/7.
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
declare <vscale x 4 x i32> @llvm.experimental.stepvector.nxv4i32()
declare <vscale x 16 x i8> @llvm.experimental.stepvector.nxv16i8()
declare <vscale x 2 x i64> @llvm.experimental.stepvector.nxv2i64()
declare <vscale x 4 x i32> @llvm.experimental.vector.reverse.nxv4i32(<vscale x 4 x i32>)
declare <vscale x 4 x float> @llvm.experimental.vector.reverse.nxv4f32(<vscale x 4 x float>)
declare <vscale x 4 x i1> @llvm.get.active.lane.mask.nxv4i1.i64(i64, i64)
declare <vscale x 16 x i1> @llvm.get.active.lane.mask.nxv16i1.i64(i64, i64)

define <vscale x 4 x i32> @protected_bc_i8_i32(<vscale x 16 x i8> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = bitcast <vscale x 16 x i8> %a to <vscale x 4 x i32>
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x float> @protected_bc_i32_f32(<vscale x 4 x i32> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = bitcast <vscale x 4 x i32> %a to <vscale x 4 x float>
  ret <vscale x 4 x float> %r
}

define <vscale x 2 x double> @protected_bc_i64_f64(<vscale x 2 x i64> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = bitcast <vscale x 2 x i64> %a to <vscale x 2 x double>
  ret <vscale x 2 x double> %r
}

define <vscale x 8 x half> @protected_bc_i16_f16(<vscale x 8 x i16> %a) noinline optnone "target-features"="+sve,+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = bitcast <vscale x 8 x i16> %a to <vscale x 8 x half>
  ret <vscale x 8 x half> %r
}

define <vscale x 4 x i32> @protected_step_i32() noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.experimental.stepvector.nxv4i32()
  ret <vscale x 4 x i32> %r
}

define <vscale x 16 x i8> @protected_step_i8() noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 16 x i8> @llvm.experimental.stepvector.nxv16i8()
  ret <vscale x 16 x i8> %r
}

define <vscale x 2 x i64> @protected_step_i64() noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 2 x i64> @llvm.experimental.stepvector.nxv2i64()
  ret <vscale x 2 x i64> %r
}

define <vscale x 4 x i32> @protected_rev_i32(<vscale x 4 x i32> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.experimental.vector.reverse.nxv4i32(<vscale x 4 x i32> %a)
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x float> @protected_rev_f32(<vscale x 4 x float> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x float> @llvm.experimental.vector.reverse.nxv4f32(<vscale x 4 x float> %a)
  ret <vscale x 4 x float> %r
}

define <vscale x 4 x i1> @protected_alm_i32(i64 %tc, i64 %n) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i1> @llvm.get.active.lane.mask.nxv4i1.i64(i64 %tc, i64 %n)
  ret <vscale x 4 x i1> %r
}

define <vscale x 16 x i1> @protected_alm_i8(i64 %tc, i64 %n) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 16 x i1> @llvm.get.active.lane.mask.nxv16i1.i64(i64 %tc, i64 %n)
  ret <vscale x 16 x i1> %r
}

define <vscale x 4 x i32> @unsupported_nofeat_step() noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.experimental.stepvector.nxv4i32()
  ret <vscale x 4 x i32> %r
}

define i32 @unsupported_internal_nofeat() noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.experimental.stepvector.nxv4i32()
  ret i32 0
}

define <vscale x 8 x half> @unsupported_half_nofp16(<vscale x 8 x i16> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = bitcast <vscale x 8 x i16> %a to <vscale x 8 x half>
  ret <vscale x 8 x half> %r
}

define i32 @unsupported_zext(ptr %p) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %a = load <vscale x 4 x i8>, ptr %p, align 4
  %r = zext <vscale x 4 x i8> %a to <vscale x 4 x i32>
  ret i32 0
}

define i32 @unsupported_poison_rev(<vscale x 4 x i32> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.experimental.vector.reverse.nxv4i32(<vscale x 4 x i32> poison)
  ret i32 0
}

define void @main() {
entry:
  ret void
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_nofeat_step: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_internal_nofeat: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_half_nofp16: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_zext: unsupported vector load instruction
; SKIP-DAG: Skipping VMP on unsupported_poison_rev: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_bc_i8_i32:
; SKIP-NOT: Skipping VMP on protected_bc_i32_f32:
; SKIP-NOT: Skipping VMP on protected_bc_i64_f64:
; SKIP-NOT: Skipping VMP on protected_bc_i16_f16:
; SKIP-NOT: Skipping VMP on protected_step_i32:
; SKIP-NOT: Skipping VMP on protected_step_i8:
; SKIP-NOT: Skipping VMP on protected_step_i64:
; SKIP-NOT: Skipping VMP on protected_rev_i32:
; SKIP-NOT: Skipping VMP on protected_rev_f32:
; SKIP-NOT: Skipping VMP on protected_alm_i32:
; SKIP-NOT: Skipping VMP on protected_alm_i8:

; VIRT-LABEL: define <vscale x 4 x i32> @protected_bc_i8_i32(
; VIRT-SAME: #[[PROT:[0-9]+]]
; VIRT: vmp.sve.regs
; VIRT: vmp.dispatch:
; VIRT: bitcast <vscale x 16 x i8>
; VIRT-LABEL: define <vscale x 4 x float> @protected_bc_i32_f32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: bitcast <vscale x 4 x i32>
; VIRT-LABEL: define <vscale x 2 x double> @protected_bc_i64_f64(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: bitcast <vscale x 2 x i64>
; VIRT-LABEL: define <vscale x 8 x half> @protected_bc_i16_f16(
; VIRT-SAME: #[[PROTHALF:[0-9]+]]
; VIRT: vmp.dispatch:
; VIRT: bitcast <vscale x 8 x i16>
; VIRT-LABEL: define <vscale x 4 x i32> @protected_step_i32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x i32> @llvm.experimental.stepvector.nxv4i32(
; VIRT-LABEL: define <vscale x 16 x i8> @protected_step_i8(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 16 x i8> @llvm.experimental.stepvector.nxv16i8(
; VIRT-LABEL: define <vscale x 2 x i64> @protected_step_i64(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 2 x i64> @llvm.experimental.stepvector.nxv2i64(
; VIRT-LABEL: define <vscale x 4 x i32> @protected_rev_i32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x i32> @llvm.experimental.vector.reverse.nxv4i32(
; VIRT-LABEL: define <vscale x 4 x float> @protected_rev_f32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x float> @llvm.experimental.vector.reverse.nxv4f32(
; VIRT-LABEL: define <vscale x 4 x i1> @protected_alm_i32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.sve.preds
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x i1> @llvm.get.active.lane.mask.nxv4i1.i64(
; VIRT-LABEL: define <vscale x 16 x i1> @protected_alm_i8(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 16 x i1> @llvm.get.active.lane.mask.nxv16i1.i64(
; VIRT: define {{.*}} @unsupported_nofeat_step({{.*}} #[[UNSUP:[0-9]+]]
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[PROTHALF]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; ASM-DAG: index{{.*}}#0, #1
; ASM-DAG: rev{{.*}}z{{[0-9]+}}.s
; ASM-DAG: whilelo{{.*}}p{{[0-9]+}}.s
; ASM-DAG: whilelo{{.*}}p{{[0-9]+}}.b
; HOST: Skipping VMP: only AArch64 targets are supported
; BUDGET-ERR: Skipping VMP on protected_bc_i8_i32: bytecode word budget
; BUDGET-IR-LABEL: define <vscale x 4 x i32> @protected_bc_i8_i32(
; BUDGET-IR-NOT: vmp.dispatch
; BUDGET-IR: bitcast <vscale x 16 x i8>
