; Restricted SVE llvm.experimental.vector.splice on full-register
; data: last-token +sve; nxv16i8 / nxv8i16 / nxv4i32 / nxv2i64 /
; nxv4f32 / nxv2f64; nxv8f16 also last-token +fullfp16.  Rebuilt as
; the same intrinsic on the nxv16i8 frame (ScalableVecHelper).  i32
; ImmArg stays in Variant.  Positive idx ISel is ext; negative idx
; with a known SVE pred pattern is ptrue+rev+splice.  nxv16i8 -9..-15
; is verifier-legal but has no pred pattern and stays skipped.
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
declare <vscale x 4 x i32> @llvm.experimental.vector.splice.nxv4i32(<vscale x 4 x i32>, <vscale x 4 x i32>, i32)
declare <vscale x 16 x i8> @llvm.experimental.vector.splice.nxv16i8(<vscale x 16 x i8>, <vscale x 16 x i8>, i32)
declare <vscale x 2 x i64> @llvm.experimental.vector.splice.nxv2i64(<vscale x 2 x i64>, <vscale x 2 x i64>, i32)
declare <vscale x 4 x float> @llvm.experimental.vector.splice.nxv4f32(<vscale x 4 x float>, <vscale x 4 x float>, i32)
declare <vscale x 8 x half> @llvm.experimental.vector.splice.nxv8f16(<vscale x 8 x half>, <vscale x 8 x half>, i32)
declare <vscale x 4 x i1> @llvm.experimental.vector.splice.nxv4i1(<vscale x 4 x i1>, <vscale x 4 x i1>, i32)
declare <vscale x 8 x i8> @llvm.experimental.vector.splice.nxv8i8(<vscale x 8 x i8>, <vscale x 8 x i8>, i32)

define <vscale x 4 x i32> @protected_sp_i32_p1(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.experimental.vector.splice.nxv4i32(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b, i32 1)
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @protected_sp_i32_0(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.experimental.vector.splice.nxv4i32(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b, i32 0)
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @protected_sp_i32_n1(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.experimental.vector.splice.nxv4i32(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b, i32 -1)
  ret <vscale x 4 x i32> %r
}

define <vscale x 16 x i8> @protected_sp_i8_p1(<vscale x 16 x i8> %a, <vscale x 16 x i8> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 16 x i8> @llvm.experimental.vector.splice.nxv16i8(<vscale x 16 x i8> %a, <vscale x 16 x i8> %b, i32 1)
  ret <vscale x 16 x i8> %r
}

define <vscale x 16 x i8> @protected_sp_i8_n16(<vscale x 16 x i8> %a, <vscale x 16 x i8> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 16 x i8> @llvm.experimental.vector.splice.nxv16i8(<vscale x 16 x i8> %a, <vscale x 16 x i8> %b, i32 -16)
  ret <vscale x 16 x i8> %r
}

define <vscale x 2 x i64> @protected_sp_i64_p1(<vscale x 2 x i64> %a, <vscale x 2 x i64> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 2 x i64> @llvm.experimental.vector.splice.nxv2i64(<vscale x 2 x i64> %a, <vscale x 2 x i64> %b, i32 1)
  ret <vscale x 2 x i64> %r
}

define <vscale x 4 x float> @protected_sp_f32_p1(<vscale x 4 x float> %a, <vscale x 4 x float> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x float> @llvm.experimental.vector.splice.nxv4f32(<vscale x 4 x float> %a, <vscale x 4 x float> %b, i32 1)
  ret <vscale x 4 x float> %r
}

define <vscale x 8 x half> @protected_sp_f16_p1(<vscale x 8 x half> %a, <vscale x 8 x half> %b) noinline optnone "target-features"="+sve,+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 8 x half> @llvm.experimental.vector.splice.nxv8f16(<vscale x 8 x half> %a, <vscale x 8 x half> %b, i32 1)
  ret <vscale x 8 x half> %r
}

define <vscale x 4 x i32> @unsupported_nofeat(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.experimental.vector.splice.nxv4i32(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b, i32 1)
  ret <vscale x 4 x i32> %r
}

define i32 @unsupported_internal_nofeat(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %a = load <vscale x 4 x i32>, ptr %p, align 16
  %r = call <vscale x 4 x i32> @llvm.experimental.vector.splice.nxv4i32(<vscale x 4 x i32> %a, <vscale x 4 x i32> %a, i32 1)
  ret i32 0
}

define <vscale x 8 x half> @unsupported_half_nofp16(<vscale x 8 x half> %a, <vscale x 8 x half> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 8 x half> @llvm.experimental.vector.splice.nxv8f16(<vscale x 8 x half> %a, <vscale x 8 x half> %b, i32 1)
  ret <vscale x 8 x half> %r
}

define i32 @unsupported_pred(<vscale x 4 x i1> %a, <vscale x 4 x i1> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i1> @llvm.experimental.vector.splice.nxv4i1(<vscale x 4 x i1> %a, <vscale x 4 x i1> %b, i32 1)
  ret i32 0
}

define i32 @unsupported_halfreg(ptr %p) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %a = load <vscale x 8 x i8>, ptr %p, align 8
  %r = call <vscale x 8 x i8> @llvm.experimental.vector.splice.nxv8i8(<vscale x 8 x i8> %a, <vscale x 8 x i8> %a, i32 1)
  ret i32 0
}

define i32 @unsupported_poison(<vscale x 4 x i32> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.experimental.vector.splice.nxv4i32(<vscale x 4 x i32> %a, <vscale x 4 x i32> poison, i32 1)
  ret i32 0
}

define <vscale x 16 x i8> @unsupported_neg9(<vscale x 16 x i8> %a, <vscale x 16 x i8> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 16 x i8> @llvm.experimental.vector.splice.nxv16i8(<vscale x 16 x i8> %a, <vscale x 16 x i8> %b, i32 -9)
  ret <vscale x 16 x i8> %r
}

define void @main() {
entry:
  ret void
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_nofeat: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_internal_nofeat: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_half_nofp16: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_pred: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_halfreg: unsupported vector load instruction
; SKIP-DAG: Skipping VMP on unsupported_poison: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_neg9: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_sp_i32_p1:
; SKIP-NOT: Skipping VMP on protected_sp_i32_0:
; SKIP-NOT: Skipping VMP on protected_sp_i32_n1:
; SKIP-NOT: Skipping VMP on protected_sp_i8_p1:
; SKIP-NOT: Skipping VMP on protected_sp_i8_n16:
; SKIP-NOT: Skipping VMP on protected_sp_i64_p1:
; SKIP-NOT: Skipping VMP on protected_sp_f32_p1:
; SKIP-NOT: Skipping VMP on protected_sp_f16_p1:

; VIRT-LABEL: define <vscale x 4 x i32> @protected_sp_i32_p1(
; VIRT-SAME: #[[PROT:[0-9]+]]
; VIRT: vmp.sve.regs
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x i32> @llvm.experimental.vector.splice.nxv4i32({{.*}}, i32 1)
; VIRT-LABEL: define <vscale x 4 x i32> @protected_sp_i32_0(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x i32> @llvm.experimental.vector.splice.nxv4i32({{.*}}, i32 0)
; VIRT-LABEL: define <vscale x 4 x i32> @protected_sp_i32_n1(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x i32> @llvm.experimental.vector.splice.nxv4i32({{.*}}, i32 -1)
; VIRT-LABEL: define <vscale x 16 x i8> @protected_sp_i8_p1(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 16 x i8> @llvm.experimental.vector.splice.nxv16i8({{.*}}, i32 1)
; VIRT-LABEL: define <vscale x 16 x i8> @protected_sp_i8_n16(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 16 x i8> @llvm.experimental.vector.splice.nxv16i8({{.*}}, i32 -16)
; VIRT-LABEL: define <vscale x 2 x i64> @protected_sp_i64_p1(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 2 x i64> @llvm.experimental.vector.splice.nxv2i64({{.*}}, i32 1)
; VIRT-LABEL: define <vscale x 4 x float> @protected_sp_f32_p1(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x float> @llvm.experimental.vector.splice.nxv4f32({{.*}}, i32 1)
; VIRT-LABEL: define <vscale x 8 x half> @protected_sp_f16_p1(
; VIRT-SAME: #[[PROTHALF:[0-9]+]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 8 x half> @llvm.experimental.vector.splice.nxv8f16({{.*}}, i32 1)
; VIRT: define {{.*}} @unsupported_nofeat({{.*}} #[[UNSUP:[0-9]+]]
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[PROTHALF]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; ASM-DAG: ext{{.*}}#4
; ASM-DAG: ext{{.*}}#1
; ASM-DAG: ext{{.*}}#8
; ASM-DAG: splice{{.*}}z{{[0-9]+}}.s
; ASM-DAG: splice{{.*}}z{{[0-9]+}}.b
; HOST: Skipping VMP: only AArch64 targets are supported
; BUDGET-ERR: Skipping VMP on protected_sp_i32_p1: bytecode word budget
; BUDGET-IR-LABEL: define <vscale x 4 x i32> @protected_sp_i32_p1(
; BUDGET-IR-NOT: vmp.dispatch
; BUDGET-IR: call <vscale x 4 x i32> @llvm.experimental.vector.splice.nxv4i32(
