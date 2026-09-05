; Restricted SVE llvm.masked.gather / llvm.masked.scatter: last-token
; +sve, four full-register integer types, matching nxv16/8/4/2i1 and
; matching AS0 nxv16/8/4/2 ptr, i32 power-of-two ConstantInt alignment,
; same-type passthru.  Addresses come from a restricted scalable GEP
; (scalar AS0 base + matching integer vector index, plus the same 2/3
; index AoS/Wrap forms as fixed gather) or a phi of those GEPs.  Not a
; pointer-vector function ABI and not a constant/poison address vector.
; Dedicated nxv2ptr chunk frame (vmp.sve.pvregs); CreateMaskedGather/
; Scatter (predicated ld1*/st1* gather, never a per-lane scalar loop).
; Host cannot execute AArch64 SVE.  FileCheck + AArch64 llc/readobj/asm
; only (llc: -mattr=+sve -fast-isel=false).  O0/O2 x 97/7.
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

%Pair = type { i32, i32 }

declare void @hikari_vmp()
declare <vscale x 16 x i8> @llvm.masked.gather.nxv16i8.nxv16p0(<vscale x 16 x ptr>, i32 immarg, <vscale x 16 x i1>, <vscale x 16 x i8>)
declare <vscale x 8 x i16> @llvm.masked.gather.nxv8i16.nxv8p0(<vscale x 8 x ptr>, i32 immarg, <vscale x 8 x i1>, <vscale x 8 x i16>)
declare <vscale x 4 x i32> @llvm.masked.gather.nxv4i32.nxv4p0(<vscale x 4 x ptr>, i32 immarg, <vscale x 4 x i1>, <vscale x 4 x i32>)
declare <vscale x 2 x i64> @llvm.masked.gather.nxv2i64.nxv2p0(<vscale x 2 x ptr>, i32 immarg, <vscale x 2 x i1>, <vscale x 2 x i64>)
declare void @llvm.masked.scatter.nxv16i8.nxv16p0(<vscale x 16 x i8>, <vscale x 16 x ptr>, i32 immarg, <vscale x 16 x i1>)
declare void @llvm.masked.scatter.nxv8i16.nxv8p0(<vscale x 8 x i16>, <vscale x 8 x ptr>, i32 immarg, <vscale x 8 x i1>)
declare void @llvm.masked.scatter.nxv4i32.nxv4p0(<vscale x 4 x i32>, <vscale x 4 x ptr>, i32 immarg, <vscale x 4 x i1>)
declare void @llvm.masked.scatter.nxv2i64.nxv2p0(<vscale x 2 x i64>, <vscale x 2 x ptr>, i32 immarg, <vscale x 2 x i1>)
declare <vscale x 4 x i64> @llvm.masked.gather.nxv4i64.nxv4p0(<vscale x 4 x ptr>, i32 immarg, <vscale x 4 x i1>, <vscale x 4 x i64>)
declare <vscale x 8 x i8> @llvm.masked.gather.nxv8i8.nxv8p0(<vscale x 8 x ptr>, i32 immarg, <vscale x 8 x i1>, <vscale x 8 x i8>)
declare <vscale x 4 x i32> @llvm.masked.gather.nxv4i32.nxv4p1(<vscale x 4 x ptr addrspace(1)>, i32 immarg, <vscale x 4 x i1>, <vscale x 4 x i32>)
declare <vscale x 4 x i32> @llvm.masked.expandload.nxv4i32(ptr, <vscale x 4 x i1>, <vscale x 4 x i32>)

define <vscale x 4 x i32> @protected_g_dyn(ptr %base, <vscale x 4 x i32> %idx, <vscale x 4 x i1> %m, <vscale x 4 x i32> %pt) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %ps = getelementptr i32, ptr %base, <vscale x 4 x i32> %idx
  %r = call <vscale x 4 x i32> @llvm.masked.gather.nxv4i32.nxv4p0(<vscale x 4 x ptr> %ps, i32 4, <vscale x 4 x i1> %m, <vscale x 4 x i32> %pt)
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @protected_g_true(ptr %base, <vscale x 4 x i32> %idx, <vscale x 4 x i32> %pt) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %ones = icmp eq <vscale x 4 x i32> zeroinitializer, zeroinitializer
  %ps = getelementptr i32, ptr %base, <vscale x 4 x i32> %idx
  %r = call <vscale x 4 x i32> @llvm.masked.gather.nxv4i32.nxv4p0(<vscale x 4 x ptr> %ps, i32 4, <vscale x 4 x i1> %ones, <vscale x 4 x i32> %pt)
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @protected_g_false(ptr %base, <vscale x 4 x i32> %idx, <vscale x 4 x i32> %pt) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %ps = getelementptr i32, ptr %base, <vscale x 4 x i32> %idx
  %r = call <vscale x 4 x i32> @llvm.masked.gather.nxv4i32.nxv4p0(<vscale x 4 x ptr> %ps, i32 4, <vscale x 4 x i1> zeroinitializer, <vscale x 4 x i32> %pt)
  ret <vscale x 4 x i32> %r
}

define void @protected_s_dyn(ptr %base, <vscale x 4 x i32> %idx, <vscale x 4 x i1> %m, <vscale x 4 x i32> %v) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %ps = getelementptr i32, ptr %base, <vscale x 4 x i32> %idx
  call void @llvm.masked.scatter.nxv4i32.nxv4p0(<vscale x 4 x i32> %v, <vscale x 4 x ptr> %ps, i32 4, <vscale x 4 x i1> %m)
  ret void
}

define <vscale x 16 x i8> @protected_g_i8(ptr %base, <vscale x 16 x i8> %idx, <vscale x 16 x i1> %m, <vscale x 16 x i8> %pt) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %ps = getelementptr i8, ptr %base, <vscale x 16 x i8> %idx
  %r = call <vscale x 16 x i8> @llvm.masked.gather.nxv16i8.nxv16p0(<vscale x 16 x ptr> %ps, i32 1, <vscale x 16 x i1> %m, <vscale x 16 x i8> %pt)
  ret <vscale x 16 x i8> %r
}

define <vscale x 8 x i16> @protected_g_i16(ptr %base, <vscale x 8 x i16> %idx, <vscale x 8 x i1> %m, <vscale x 8 x i16> %pt) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %ps = getelementptr i16, ptr %base, <vscale x 8 x i16> %idx
  %r = call <vscale x 8 x i16> @llvm.masked.gather.nxv8i16.nxv8p0(<vscale x 8 x ptr> %ps, i32 2, <vscale x 8 x i1> %m, <vscale x 8 x i16> %pt)
  ret <vscale x 8 x i16> %r
}

define <vscale x 2 x i64> @protected_g_i64(ptr %base, <vscale x 2 x i64> %idx, <vscale x 2 x i1> %m, <vscale x 2 x i64> %pt) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %ps = getelementptr i64, ptr %base, <vscale x 2 x i64> %idx
  %r = call <vscale x 2 x i64> @llvm.masked.gather.nxv2i64.nxv2p0(<vscale x 2 x ptr> %ps, i32 8, <vscale x 2 x i1> %m, <vscale x 2 x i64> %pt)
  ret <vscale x 2 x i64> %r
}

define void @protected_s_i8(ptr %base, <vscale x 16 x i8> %idx, <vscale x 16 x i1> %m, <vscale x 16 x i8> %v) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %ps = getelementptr i8, ptr %base, <vscale x 16 x i8> %idx
  call void @llvm.masked.scatter.nxv16i8.nxv16p0(<vscale x 16 x i8> %v, <vscale x 16 x ptr> %ps, i32 1, <vscale x 16 x i1> %m)
  ret void
}

define void @protected_s_i64(ptr %base, <vscale x 2 x i64> %idx, <vscale x 2 x i1> %m, <vscale x 2 x i64> %v) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %ps = getelementptr i64, ptr %base, <vscale x 2 x i64> %idx
  call void @llvm.masked.scatter.nxv2i64.nxv2p0(<vscale x 2 x i64> %v, <vscale x 2 x ptr> %ps, i32 8, <vscale x 2 x i1> %m)
  ret void
}

define <vscale x 4 x i32> @protected_g_aos(ptr %base, <vscale x 4 x i32> %idx, <vscale x 4 x i1> %m, <vscale x 4 x i32> %pt) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %ps = getelementptr %Pair, ptr %base, <vscale x 4 x i32> %idx, i32 1
  %r = call <vscale x 4 x i32> @llvm.masked.gather.nxv4i32.nxv4p0(<vscale x 4 x ptr> %ps, i32 4, <vscale x 4 x i1> %m, <vscale x 4 x i32> %pt)
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @protected_g_phi(ptr %b0, ptr %b1, i1 %c, <vscale x 4 x i32> %idx, <vscale x 4 x i1> %m, <vscale x 4 x i32> %pt) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  br i1 %c, label %left, label %right
left:
  %p0 = getelementptr i32, ptr %b0, <vscale x 4 x i32> %idx
  br label %join
right:
  %p1 = getelementptr i32, ptr %b1, <vscale x 4 x i32> %idx
  br label %join
join:
  %ps = phi <vscale x 4 x ptr> [ %p0, %left ], [ %p1, %right ]
  %r = call <vscale x 4 x i32> @llvm.masked.gather.nxv4i32.nxv4p0(<vscale x 4 x ptr> %ps, i32 4, <vscale x 4 x i1> %m, <vscale x 4 x i32> %pt)
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @unsupported_nofeat(ptr %base, <vscale x 4 x i32> %idx, <vscale x 4 x i1> %m, <vscale x 4 x i32> %pt) noinline optnone {
entry:
  call void @hikari_vmp()
  %ps = getelementptr i32, ptr %base, <vscale x 4 x i32> %idx
  %r = call <vscale x 4 x i32> @llvm.masked.gather.nxv4i32.nxv4p0(<vscale x 4 x ptr> %ps, i32 4, <vscale x 4 x i1> %m, <vscale x 4 x i32> %pt)
  ret <vscale x 4 x i32> %r
}

; Scalar ABI + live well-shaped body: last-token feature miss, not ABI.
define i32 @unsupported_internal_nofeat(ptr %base) noinline optnone {
entry:
  call void @hikari_vmp()
  %ps = getelementptr i32, ptr %base, <vscale x 4 x i32> zeroinitializer
  %r = call <vscale x 4 x i32> @llvm.masked.gather.nxv4i32.nxv4p0(<vscale x 4 x ptr> %ps, i32 4, <vscale x 4 x i1> zeroinitializer, <vscale x 4 x i32> zeroinitializer)
  ret i32 0
}

define i32 @unsupported_wide(ptr %base) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i64> @llvm.masked.gather.nxv4i64.nxv4p0(<vscale x 4 x ptr> zeroinitializer, i32 8, <vscale x 4 x i1> zeroinitializer, <vscale x 4 x i64> zeroinitializer)
  ret i32 0
}

define i32 @unsupported_mismatch(ptr %base) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 8 x i8> @llvm.masked.gather.nxv8i8.nxv8p0(<vscale x 8 x ptr> zeroinitializer, i32 1, <vscale x 8 x i1> zeroinitializer, <vscale x 8 x i8> zeroinitializer)
  ret i32 0
}

define i32 @unsupported_poison(ptr %base, <vscale x 4 x i32> %idx, <vscale x 4 x i1> %m) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %ps = getelementptr i32, ptr %base, <vscale x 4 x i32> %idx
  %r = call <vscale x 4 x i32> @llvm.masked.gather.nxv4i32.nxv4p0(<vscale x 4 x ptr> %ps, i32 4, <vscale x 4 x i1> %m, <vscale x 4 x i32> poison)
  ret i32 0
}

define i32 @unsupported_as1() noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.masked.gather.nxv4i32.nxv4p1(<vscale x 4 x ptr addrspace(1)> zeroinitializer, i32 4, <vscale x 4 x i1> zeroinitializer, <vscale x 4 x i32> zeroinitializer)
  ret i32 0
}

; SVE expandload/compressstore stay rejected: LLVM 15 AArch64 ISel
; lowers them to ordinary predicated ld1/st1 (same as masked.load/
; store), which is not compact-sequence semantics.
define i32 @unsupported_expand(ptr %p) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.masked.expandload.nxv4i32(ptr %p, <vscale x 4 x i1> zeroinitializer, <vscale x 4 x i32> zeroinitializer)
  ret i32 0
}

define void @main() {
entry:
  ret void
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_nofeat: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_internal_nofeat: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_wide: unsupported masked memory instruction
; SKIP-DAG: Skipping VMP on unsupported_mismatch: unsupported masked memory instruction
; SKIP-DAG: Skipping VMP on unsupported_poison: unsupported masked memory instruction
; SKIP-DAG: Skipping VMP on unsupported_as1: unsupported masked memory instruction
; SKIP-DAG: Skipping VMP on unsupported_expand: unsupported masked memory instruction
; SKIP-NOT: Skipping VMP on protected_g_dyn:
; SKIP-NOT: Skipping VMP on protected_g_true:
; SKIP-NOT: Skipping VMP on protected_g_false:
; SKIP-NOT: Skipping VMP on protected_s_dyn:
; SKIP-NOT: Skipping VMP on protected_g_i8:
; SKIP-NOT: Skipping VMP on protected_g_i16:
; SKIP-NOT: Skipping VMP on protected_g_i64:
; SKIP-NOT: Skipping VMP on protected_s_i8:
; SKIP-NOT: Skipping VMP on protected_s_i64:
; SKIP-NOT: Skipping VMP on protected_g_aos:
; SKIP-NOT: Skipping VMP on protected_g_phi:

; VIRT-LABEL: define <vscale x 4 x i32> @protected_g_dyn(
; VIRT-SAME: #[[PROT:[0-9]+]]
; VIRT: vmp.sve.regs
; VIRT: vmp.sve.preds
; VIRT: vmp.sve.pvregs
; VIRT: vmp.dispatch:
; VIRT-DAG: getelementptr i32, ptr
; VIRT-DAG: call <vscale x 4 x i32> @llvm.masked.gather.nxv4i32.nxv4p0(
; VIRT-LABEL: define <vscale x 4 x i32> @protected_g_true(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x i32> @llvm.masked.gather.nxv4i32.nxv4p0(
; VIRT-LABEL: define <vscale x 4 x i32> @protected_g_false(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x i32> @llvm.masked.gather.nxv4i32.nxv4p0(
; VIRT-LABEL: define void @protected_s_dyn(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.masked.scatter.nxv4i32.nxv4p0(
; VIRT-LABEL: define <vscale x 16 x i8> @protected_g_i8(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 16 x i8> @llvm.masked.gather.nxv16i8.nxv16p0(
; VIRT-LABEL: define <vscale x 8 x i16> @protected_g_i16(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 8 x i16> @llvm.masked.gather.nxv8i16.nxv8p0(
; VIRT-LABEL: define <vscale x 2 x i64> @protected_g_i64(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 2 x i64> @llvm.masked.gather.nxv2i64.nxv2p0(
; VIRT-LABEL: define void @protected_s_i8(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.masked.scatter.nxv16i8.nxv16p0(
; VIRT-LABEL: define void @protected_s_i64(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.masked.scatter.nxv2i64.nxv2p0(
; VIRT-LABEL: define <vscale x 4 x i32> @protected_g_aos(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT-DAG: getelementptr %Pair, ptr
; VIRT-DAG: call <vscale x 4 x i32> @llvm.masked.gather.nxv4i32.nxv4p0(
; VIRT-LABEL: define <vscale x 4 x i32> @protected_g_phi(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT-DAG: getelementptr i32, ptr
; VIRT-DAG: call <vscale x 4 x i32> @llvm.masked.gather.nxv4i32.nxv4p0(
; VIRT: define {{.*}} @unsupported_nofeat({{.*}} #[[UNSUP:[0-9]+]]
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; ASM-DAG: ld1w{{.*}}/z
; ASM-DAG: ld1h{{.*}}/z
; ASM-DAG: ld1b{{.*}}/z
; ASM-DAG: ld1d{{.*}}/z
; ASM-DAG: st1w
; ASM-DAG: st1b
; ASM-DAG: st1d
; HOST: Skipping VMP: only AArch64 targets are supported
; BUDGET-ERR: Skipping VMP on protected_g_dyn: bytecode word budget
; BUDGET-IR-LABEL: define <vscale x 4 x i32> @protected_g_dyn(
; BUDGET-IR-NOT: vmp.dispatch
; BUDGET-IR: call <vscale x 4 x i32> @llvm.masked.gather.nxv4i32.nxv4p0(
