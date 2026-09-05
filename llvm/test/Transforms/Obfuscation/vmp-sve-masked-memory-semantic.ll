; Restricted SVE llvm.masked.load / llvm.masked.store: last-token +sve,
; four full-register integer types, matching nxv16/8/4/2i1, AS0 scalar
; ptr, i32 power-of-two ConstantInt alignment, same-type passthru.
; Dedicated ScalableMaskedLoad/Store reconstruct CreateMaskedLoad/Store
; (predicated ld1/st1 + merging mov).  Not CallDescriptor, not an
; unpredicated load/store plus select.  Data/pred/ptr use their own
; VReg frames.  Restricted SVE gather/scatter is the dedicated
; vmp-sve-gather-scatter-semantic.ll surface; leftovers here keep
; constant address vectors so they stay "unsupported masked memory".
; Lane-mismatched mask/data is verifier-illegal IR and
; is not a lit sentinel; leftovers use legal out-of-surface shapes
; (half-register / non-four-width data, poison, non-AS0, gather).
; Well-shaped SVE ABI without +sve is still "unsupported return type"
; (or argument type).  Scalar-ABI well-shaped body without +sve is
; "unsupported target feature".  Host cannot execute AArch64 SVE.
; FileCheck + AArch64 llc/readobj/asm only
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
declare <vscale x 16 x i8> @llvm.masked.load.nxv16i8.p0(ptr, i32 immarg, <vscale x 16 x i1>, <vscale x 16 x i8>)
declare <vscale x 8 x i16> @llvm.masked.load.nxv8i16.p0(ptr, i32 immarg, <vscale x 8 x i1>, <vscale x 8 x i16>)
declare <vscale x 4 x i32> @llvm.masked.load.nxv4i32.p0(ptr, i32 immarg, <vscale x 4 x i1>, <vscale x 4 x i32>)
declare <vscale x 2 x i64> @llvm.masked.load.nxv2i64.p0(ptr, i32 immarg, <vscale x 2 x i1>, <vscale x 2 x i64>)
declare void @llvm.masked.store.nxv16i8.p0(<vscale x 16 x i8>, ptr, i32 immarg, <vscale x 16 x i1>)
declare void @llvm.masked.store.nxv8i16.p0(<vscale x 8 x i16>, ptr, i32 immarg, <vscale x 8 x i1>)
declare void @llvm.masked.store.nxv4i32.p0(<vscale x 4 x i32>, ptr, i32 immarg, <vscale x 4 x i1>)
declare void @llvm.masked.store.nxv2i64.p0(<vscale x 2 x i64>, ptr, i32 immarg, <vscale x 2 x i1>)
declare <vscale x 4 x i32> @llvm.masked.gather.nxv4i32.nxv4p0(<vscale x 4 x ptr>, i32 immarg, <vscale x 4 x i1>, <vscale x 4 x i32>)
declare void @llvm.masked.scatter.nxv4i32.nxv4p0(<vscale x 4 x i32>, <vscale x 4 x ptr>, i32 immarg, <vscale x 4 x i1>)
declare <vscale x 4 x i64> @llvm.masked.load.nxv4i64.p0(ptr, i32 immarg, <vscale x 4 x i1>, <vscale x 4 x i64>)
declare <vscale x 8 x i8> @llvm.masked.load.nxv8i8.p0(ptr, i32 immarg, <vscale x 8 x i1>, <vscale x 8 x i8>)
declare <vscale x 4 x i32> @llvm.masked.load.nxv4i32.p1(ptr addrspace(1), i32 immarg, <vscale x 4 x i1>, <vscale x 4 x i32>)

@g.as1 = addrspace(1) global i32 0

define <vscale x 4 x i32> @protected_mload_dyn(ptr %p, <vscale x 4 x i1> %m, <vscale x 4 x i32> %pt) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.masked.load.nxv4i32.p0(ptr %p, i32 16, <vscale x 4 x i1> %m, <vscale x 4 x i32> %pt)
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @protected_mload_true(ptr %p, <vscale x 4 x i32> %pt) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %ones = icmp eq <vscale x 4 x i32> zeroinitializer, zeroinitializer
  %r = call <vscale x 4 x i32> @llvm.masked.load.nxv4i32.p0(ptr %p, i32 16, <vscale x 4 x i1> %ones, <vscale x 4 x i32> %pt)
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @protected_mload_false(ptr %p, <vscale x 4 x i32> %pt) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.masked.load.nxv4i32.p0(ptr %p, i32 16, <vscale x 4 x i1> zeroinitializer, <vscale x 4 x i32> %pt)
  ret <vscale x 4 x i32> %r
}

define void @protected_mstore_dyn(ptr %p, <vscale x 4 x i1> %m, <vscale x 4 x i32> %v) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  call void @llvm.masked.store.nxv4i32.p0(<vscale x 4 x i32> %v, ptr %p, i32 16, <vscale x 4 x i1> %m)
  ret void
}

define <vscale x 16 x i8> @protected_mload_i8(ptr %p, <vscale x 16 x i1> %m, <vscale x 16 x i8> %pt) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 16 x i8> @llvm.masked.load.nxv16i8.p0(ptr %p, i32 1, <vscale x 16 x i1> %m, <vscale x 16 x i8> %pt)
  ret <vscale x 16 x i8> %r
}

define <vscale x 8 x i16> @protected_mload_i16(ptr %p, <vscale x 8 x i1> %m, <vscale x 8 x i16> %pt) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 8 x i16> @llvm.masked.load.nxv8i16.p0(ptr %p, i32 2, <vscale x 8 x i1> %m, <vscale x 8 x i16> %pt)
  ret <vscale x 8 x i16> %r
}

define <vscale x 2 x i64> @protected_mload_i64(ptr %p, <vscale x 2 x i1> %m, <vscale x 2 x i64> %pt) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 2 x i64> @llvm.masked.load.nxv2i64.p0(ptr %p, i32 8, <vscale x 2 x i1> %m, <vscale x 2 x i64> %pt)
  ret <vscale x 2 x i64> %r
}

define void @protected_mstore_i8(ptr %p, <vscale x 16 x i1> %m, <vscale x 16 x i8> %v) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  call void @llvm.masked.store.nxv16i8.p0(<vscale x 16 x i8> %v, ptr %p, i32 1, <vscale x 16 x i1> %m)
  ret void
}

define void @protected_mstore_i16(ptr %p, <vscale x 8 x i1> %m, <vscale x 8 x i16> %v) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  call void @llvm.masked.store.nxv8i16.p0(<vscale x 8 x i16> %v, ptr %p, i32 2, <vscale x 8 x i1> %m)
  ret void
}

define void @protected_mstore_i64(ptr %p, <vscale x 2 x i1> %m, <vscale x 2 x i64> %v) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  call void @llvm.masked.store.nxv2i64.p0(<vscale x 2 x i64> %v, ptr %p, i32 8, <vscale x 2 x i1> %m)
  ret void
}

define <vscale x 4 x i32> @protected_mload_gep(ptr %p, i64 %i, <vscale x 4 x i1> %m, <vscale x 4 x i32> %pt) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %q = getelementptr i32, ptr %p, i64 %i
  %r = call <vscale x 4 x i32> @llvm.masked.load.nxv4i32.p0(ptr %q, i32 4, <vscale x 4 x i1> %m, <vscale x 4 x i32> %pt)
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @unsupported_nofeat(ptr %p, <vscale x 4 x i1> %m, <vscale x 4 x i32> %pt) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.masked.load.nxv4i32.p0(ptr %p, i32 16, <vscale x 4 x i1> %m, <vscale x 4 x i32> %pt)
  ret <vscale x 4 x i32> %r
}

; Scalar ABI + live well-shaped body: last-token feature miss, not ABI.
define i32 @unsupported_internal_nofeat(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.masked.load.nxv4i32.p0(ptr %p, i32 16, <vscale x 4 x i1> zeroinitializer, <vscale x 4 x i32> zeroinitializer)
  ret i32 0
}

; nxv4i64 is legal IR but not one of the four full-register types.
define i32 @unsupported_wide(ptr %p) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i64> @llvm.masked.load.nxv4i64.p0(ptr %p, i32 8, <vscale x 4 x i1> zeroinitializer, <vscale x 4 x i64> zeroinitializer)
  ret i32 0
}

; Half-register data + matching nxv8i1: legal stand-in for mask/data
; surface mismatch.  True lane mismatch is verifier-illegal.
define i32 @unsupported_mismatch(ptr %p) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 8 x i8> @llvm.masked.load.nxv8i8.p0(ptr %p, i32 1, <vscale x 8 x i1> zeroinitializer, <vscale x 8 x i8> zeroinitializer)
  ret i32 0
}

define i32 @unsupported_poison(ptr %p) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.masked.load.nxv4i32.p0(ptr %p, i32 16, <vscale x 4 x i1> zeroinitializer, <vscale x 4 x i32> poison)
  ret i32 0
}

define <vscale x 4 x i32> @unsupported_as1(<vscale x 4 x i1> %m, <vscale x 4 x i32> %pt) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.masked.load.nxv4i32.p1(ptr addrspace(1) @g.as1, i32 4, <vscale x 4 x i1> %m, <vscale x 4 x i32> %pt)
  ret <vscale x 4 x i32> %r
}

; Scalar ABI so the dedicated masked-memory skip fires (pointer-vector
; args would be "unsupported argument type" first).
define i32 @unsupported_gather() noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.masked.gather.nxv4i32.nxv4p0(<vscale x 4 x ptr> zeroinitializer, i32 4, <vscale x 4 x i1> zeroinitializer, <vscale x 4 x i32> zeroinitializer)
  ret i32 0
}

define void @unsupported_scatter() noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  call void @llvm.masked.scatter.nxv4i32.nxv4p0(<vscale x 4 x i32> zeroinitializer, <vscale x 4 x ptr> zeroinitializer, i32 4, <vscale x 4 x i1> zeroinitializer)
  ret void
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
; SKIP-DAG: Skipping VMP on unsupported_gather: unsupported masked memory instruction
; SKIP-DAG: Skipping VMP on unsupported_scatter: unsupported masked memory instruction
; SKIP-NOT: Skipping VMP on protected_mload_dyn:
; SKIP-NOT: Skipping VMP on protected_mload_true:
; SKIP-NOT: Skipping VMP on protected_mload_false:
; SKIP-NOT: Skipping VMP on protected_mstore_dyn:
; SKIP-NOT: Skipping VMP on protected_mload_i8:
; SKIP-NOT: Skipping VMP on protected_mload_i16:
; SKIP-NOT: Skipping VMP on protected_mload_i64:
; SKIP-NOT: Skipping VMP on protected_mstore_i8:
; SKIP-NOT: Skipping VMP on protected_mstore_i16:
; SKIP-NOT: Skipping VMP on protected_mstore_i64:
; SKIP-NOT: Skipping VMP on protected_mload_gep:

; VIRT-LABEL: define <vscale x 4 x i32> @protected_mload_dyn(
; VIRT-SAME: #[[PROT:[0-9]+]]
; VIRT: vmp.sve.regs
; VIRT: vmp.sve.preds
; VIRT: vmp.dispatch:
; VIRT-DAG: llvm.aarch64.sve.convert.{{to|from}}.svbool
; VIRT-DAG: call <vscale x 4 x i32> @llvm.masked.load.nxv4i32.p0(
; VIRT-LABEL: define <vscale x 4 x i32> @protected_mload_true(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x i32> @llvm.masked.load.nxv4i32.p0(
; VIRT-LABEL: define <vscale x 4 x i32> @protected_mload_false(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x i32> @llvm.masked.load.nxv4i32.p0(
; VIRT-LABEL: define void @protected_mstore_dyn(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.masked.store.nxv4i32.p0(
; VIRT-LABEL: define <vscale x 16 x i8> @protected_mload_i8(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 16 x i8> @llvm.masked.load.nxv16i8.p0(
; VIRT-LABEL: define <vscale x 8 x i16> @protected_mload_i16(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 8 x i16> @llvm.masked.load.nxv8i16.p0(
; VIRT-LABEL: define <vscale x 2 x i64> @protected_mload_i64(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 2 x i64> @llvm.masked.load.nxv2i64.p0(
; VIRT-LABEL: define void @protected_mstore_i8(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.masked.store.nxv16i8.p0(
; VIRT-LABEL: define void @protected_mstore_i16(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.masked.store.nxv8i16.p0(
; VIRT-LABEL: define void @protected_mstore_i64(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.masked.store.nxv2i64.p0(
; VIRT-LABEL: define <vscale x 4 x i32> @protected_mload_gep(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT-DAG: getelementptr i32, ptr
; VIRT-DAG: call <vscale x 4 x i32> @llvm.masked.load.nxv4i32.p0(
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
; ASM-DAG: st1h
; ASM-DAG: st1b
; ASM-DAG: st1d
; ASM-DAG: mov{{.*}}/m
; HOST: Skipping VMP: only AArch64 targets are supported
; BUDGET-ERR: Skipping VMP on protected_mload_dyn: bytecode word budget
; BUDGET-IR-LABEL: define <vscale x 4 x i32> @protected_mload_dyn(
; BUDGET-IR-NOT: vmp.dispatch
; BUDGET-IR: call <vscale x 4 x i32> @llvm.masked.load.nxv4i32.p0(
