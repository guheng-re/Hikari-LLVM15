; Restricted SVE llvm.masked.gather / scatter on full-register float:
; last-token +sve, nxv4f32 / nxv2f64; nxv8f16 also last-token +fullfp16.
; Matching pred and AS0 nxv4/2/8 ptr from a restricted scalable GEP
; (scalar AS0 base + matching integer vector index).  CreateMaskedGather/
; Scatter (predicated ld1*/st1* gather, never a per-lane loop).
; Constant/poison address vectors, partial widths, missing tokens stay
; skipped.  Host cannot execute AArch64 SVE.  FileCheck + AArch64
; llc/readobj/asm (llc: -mattr=+sve,+fullfp16 -fast-isel=false).
; O0/O2 x 97/7.
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
declare <vscale x 4 x float> @llvm.masked.gather.nxv4f32.nxv4p0(<vscale x 4 x ptr>, i32 immarg, <vscale x 4 x i1>, <vscale x 4 x float>)
declare void @llvm.masked.scatter.nxv4f32.nxv4p0(<vscale x 4 x float>, <vscale x 4 x ptr>, i32 immarg, <vscale x 4 x i1>)
declare <vscale x 2 x double> @llvm.masked.gather.nxv2f64.nxv2p0(<vscale x 2 x ptr>, i32 immarg, <vscale x 2 x i1>, <vscale x 2 x double>)
declare void @llvm.masked.scatter.nxv2f64.nxv2p0(<vscale x 2 x double>, <vscale x 2 x ptr>, i32 immarg, <vscale x 2 x i1>)
declare <vscale x 8 x half> @llvm.masked.gather.nxv8f16.nxv8p0(<vscale x 8 x ptr>, i32 immarg, <vscale x 8 x i1>, <vscale x 8 x half>)
declare void @llvm.masked.scatter.nxv8f16.nxv8p0(<vscale x 8 x half>, <vscale x 8 x ptr>, i32 immarg, <vscale x 8 x i1>)
declare <vscale x 2 x float> @llvm.masked.gather.nxv2f32.nxv2p0(<vscale x 2 x ptr>, i32 immarg, <vscale x 2 x i1>, <vscale x 2 x float>)
declare <vscale x 4 x float> @llvm.masked.expandload.nxv4f32.p0(ptr, <vscale x 4 x i1>, <vscale x 4 x float>)

define <vscale x 4 x float> @protected_g_f32(ptr %base, <vscale x 4 x i32> %idx, <vscale x 4 x i1> %m, <vscale x 4 x float> %pt) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %ps = getelementptr float, ptr %base, <vscale x 4 x i32> %idx
  %r = call <vscale x 4 x float> @llvm.masked.gather.nxv4f32.nxv4p0(<vscale x 4 x ptr> %ps, i32 4, <vscale x 4 x i1> %m, <vscale x 4 x float> %pt)
  ret <vscale x 4 x float> %r
}

define <vscale x 4 x float> @protected_g_false(ptr %base, <vscale x 4 x i32> %idx, <vscale x 4 x float> %pt) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %ps = getelementptr float, ptr %base, <vscale x 4 x i32> %idx
  %r = call <vscale x 4 x float> @llvm.masked.gather.nxv4f32.nxv4p0(<vscale x 4 x ptr> %ps, i32 4, <vscale x 4 x i1> zeroinitializer, <vscale x 4 x float> %pt)
  ret <vscale x 4 x float> %r
}

define void @protected_s_f32(ptr %base, <vscale x 4 x i32> %idx, <vscale x 4 x i1> %m, <vscale x 4 x float> %v) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %ps = getelementptr float, ptr %base, <vscale x 4 x i32> %idx
  call void @llvm.masked.scatter.nxv4f32.nxv4p0(<vscale x 4 x float> %v, <vscale x 4 x ptr> %ps, i32 4, <vscale x 4 x i1> %m)
  ret void
}

define <vscale x 2 x double> @protected_g_f64(ptr %base, <vscale x 2 x i64> %idx, <vscale x 2 x i1> %m, <vscale x 2 x double> %pt) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %ps = getelementptr double, ptr %base, <vscale x 2 x i64> %idx
  %r = call <vscale x 2 x double> @llvm.masked.gather.nxv2f64.nxv2p0(<vscale x 2 x ptr> %ps, i32 8, <vscale x 2 x i1> %m, <vscale x 2 x double> %pt)
  ret <vscale x 2 x double> %r
}

define void @protected_s_f64(ptr %base, <vscale x 2 x i64> %idx, <vscale x 2 x i1> %m, <vscale x 2 x double> %v) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %ps = getelementptr double, ptr %base, <vscale x 2 x i64> %idx
  call void @llvm.masked.scatter.nxv2f64.nxv2p0(<vscale x 2 x double> %v, <vscale x 2 x ptr> %ps, i32 8, <vscale x 2 x i1> %m)
  ret void
}

define <vscale x 8 x half> @protected_g_f16(ptr %base, <vscale x 8 x i16> %idx, <vscale x 8 x i1> %m, <vscale x 8 x half> %pt) noinline optnone "target-features"="+sve,+fullfp16" {
entry:
  call void @hikari_vmp()
  %ps = getelementptr half, ptr %base, <vscale x 8 x i16> %idx
  %r = call <vscale x 8 x half> @llvm.masked.gather.nxv8f16.nxv8p0(<vscale x 8 x ptr> %ps, i32 2, <vscale x 8 x i1> %m, <vscale x 8 x half> %pt)
  ret <vscale x 8 x half> %r
}

define void @protected_s_f16(ptr %base, <vscale x 8 x i16> %idx, <vscale x 8 x i1> %m, <vscale x 8 x half> %v) noinline optnone "target-features"="+sve,+fullfp16" {
entry:
  call void @hikari_vmp()
  %ps = getelementptr half, ptr %base, <vscale x 8 x i16> %idx
  call void @llvm.masked.scatter.nxv8f16.nxv8p0(<vscale x 8 x half> %v, <vscale x 8 x ptr> %ps, i32 2, <vscale x 8 x i1> %m)
  ret void
}

define <vscale x 4 x float> @unsupported_nofeat(ptr %base, <vscale x 4 x i32> %idx, <vscale x 4 x i1> %m, <vscale x 4 x float> %pt) noinline optnone {
entry:
  call void @hikari_vmp()
  %ps = getelementptr float, ptr %base, <vscale x 4 x i32> %idx
  %r = call <vscale x 4 x float> @llvm.masked.gather.nxv4f32.nxv4p0(<vscale x 4 x ptr> %ps, i32 4, <vscale x 4 x i1> %m, <vscale x 4 x float> %pt)
  ret <vscale x 4 x float> %r
}

define i32 @unsupported_internal_nofeat(ptr %base, ptr %idxp) noinline optnone {
entry:
  call void @hikari_vmp()
  %idx = load <vscale x 4 x i32>, ptr %idxp, align 16
  %ps = getelementptr float, ptr %base, <vscale x 4 x i32> %idx
  %r = call <vscale x 4 x float> @llvm.masked.gather.nxv4f32.nxv4p0(<vscale x 4 x ptr> %ps, i32 4, <vscale x 4 x i1> zeroinitializer, <vscale x 4 x float> zeroinitializer)
  ret i32 0
}

define <vscale x 8 x half> @unsupported_half_nofp16(ptr %base, <vscale x 8 x i16> %idx, <vscale x 8 x i1> %m, <vscale x 8 x half> %pt) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %ps = getelementptr half, ptr %base, <vscale x 8 x i16> %idx
  %r = call <vscale x 8 x half> @llvm.masked.gather.nxv8f16.nxv8p0(<vscale x 8 x ptr> %ps, i32 2, <vscale x 8 x i1> %m, <vscale x 8 x half> %pt)
  ret <vscale x 8 x half> %r
}

define i32 @unsupported_partial() noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 2 x float> @llvm.masked.gather.nxv2f32.nxv2p0(<vscale x 2 x ptr> zeroinitializer, i32 4, <vscale x 2 x i1> zeroinitializer, <vscale x 2 x float> zeroinitializer)
  ret i32 0
}

define i32 @unsupported_constaddr() noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x float> @llvm.masked.gather.nxv4f32.nxv4p0(<vscale x 4 x ptr> zeroinitializer, i32 4, <vscale x 4 x i1> zeroinitializer, <vscale x 4 x float> zeroinitializer)
  ret i32 0
}

define i32 @unsupported_poison(ptr %base, <vscale x 4 x i32> %idx, <vscale x 4 x i1> %m) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %ps = getelementptr float, ptr %base, <vscale x 4 x i32> %idx
  %r = call <vscale x 4 x float> @llvm.masked.gather.nxv4f32.nxv4p0(<vscale x 4 x ptr> %ps, i32 4, <vscale x 4 x i1> %m, <vscale x 4 x float> poison)
  ret i32 0
}

define i32 @unsupported_expand(ptr %p) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x float> @llvm.masked.expandload.nxv4f32.p0(ptr %p, <vscale x 4 x i1> zeroinitializer, <vscale x 4 x float> zeroinitializer)
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
; SKIP-DAG: Skipping VMP on unsupported_partial: unsupported masked memory instruction
; SKIP-DAG: Skipping VMP on unsupported_constaddr: unsupported masked memory instruction
; SKIP-DAG: Skipping VMP on unsupported_poison: unsupported masked memory instruction
; SKIP-DAG: Skipping VMP on unsupported_expand: unsupported masked memory instruction
; SKIP-NOT: Skipping VMP on protected_g_f32:
; SKIP-NOT: Skipping VMP on protected_g_false:
; SKIP-NOT: Skipping VMP on protected_s_f32:
; SKIP-NOT: Skipping VMP on protected_g_f64:
; SKIP-NOT: Skipping VMP on protected_s_f64:
; SKIP-NOT: Skipping VMP on protected_g_f16:
; SKIP-NOT: Skipping VMP on protected_s_f16:

; VIRT-LABEL: define <vscale x 4 x float> @protected_g_f32(
; VIRT-SAME: #[[PROT:[0-9]+]]
; VIRT: vmp.sve.regs
; VIRT: vmp.sve.preds
; VIRT: vmp.sve.pvregs
; VIRT: vmp.dispatch:
; VIRT-DAG: getelementptr float, ptr
; VIRT-DAG: call <vscale x 4 x float> @llvm.masked.gather.nxv4f32.nxv4p0(
; VIRT-LABEL: define <vscale x 4 x float> @protected_g_false(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x float> @llvm.masked.gather.nxv4f32.nxv4p0(
; VIRT-LABEL: define void @protected_s_f32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.masked.scatter.nxv4f32.nxv4p0(
; VIRT-LABEL: define <vscale x 2 x double> @protected_g_f64(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 2 x double> @llvm.masked.gather.nxv2f64.nxv2p0(
; VIRT-LABEL: define void @protected_s_f64(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.masked.scatter.nxv2f64.nxv2p0(
; VIRT-LABEL: define <vscale x 8 x half> @protected_g_f16(
; VIRT-SAME: #[[PROTHALF:[0-9]+]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 8 x half> @llvm.masked.gather.nxv8f16.nxv8p0(
; VIRT-LABEL: define void @protected_s_f16(
; VIRT-SAME: #[[PROTHALF]]
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.masked.scatter.nxv8f16.nxv8p0(
; VIRT: define {{.*}} @unsupported_nofeat({{.*}} #[[UNSUP:[0-9]+]]
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[PROTHALF]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; ASM-DAG: ld1w{{.*}}/z
; ASM-DAG: ld1d{{.*}}/z
; ASM-DAG: ld1h{{.*}}/z
; ASM-DAG: st1w
; ASM-DAG: st1d
; ASM-DAG: st1h
; HOST: Skipping VMP: only AArch64 targets are supported
; BUDGET-ERR: Skipping VMP on protected_g_f32: bytecode word budget
; BUDGET-IR-LABEL: define <vscale x 4 x float> @protected_g_f32(
; BUDGET-IR-NOT: vmp.dispatch
; BUDGET-IR: call <vscale x 4 x float> @llvm.masked.gather.nxv4f32.nxv4p0(
