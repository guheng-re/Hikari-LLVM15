; Restricted SVE llvm.masked.load / llvm.masked.store on full-register
; float types: last-token +sve, <vscale x 4 x float> / <vscale x 2 x
; double>; <vscale x 8 x half> also last-token +fullfp16.  Matching
; predicate, AS0 scalar ptr, i32 power-of-two align ImmArg, same-type
; passthru.  Rebuilt as CreateMaskedLoad/Store (predicated ld1/st1),
; never an unpredicated load/store plus select.  frem, expand/compress,
; missing last-token features, and partial widths stay skipped.
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
declare <vscale x 4 x float> @llvm.masked.load.nxv4f32.p0(ptr, i32 immarg, <vscale x 4 x i1>, <vscale x 4 x float>)
declare void @llvm.masked.store.nxv4f32.p0(<vscale x 4 x float>, ptr, i32 immarg, <vscale x 4 x i1>)
declare <vscale x 2 x double> @llvm.masked.load.nxv2f64.p0(ptr, i32 immarg, <vscale x 2 x i1>, <vscale x 2 x double>)
declare void @llvm.masked.store.nxv2f64.p0(<vscale x 2 x double>, ptr, i32 immarg, <vscale x 2 x i1>)
declare <vscale x 8 x half> @llvm.masked.load.nxv8f16.p0(ptr, i32 immarg, <vscale x 8 x i1>, <vscale x 8 x half>)
declare void @llvm.masked.store.nxv8f16.p0(<vscale x 8 x half>, ptr, i32 immarg, <vscale x 8 x i1>)
declare <vscale x 2 x float> @llvm.masked.load.nxv2f32.p0(ptr, i32 immarg, <vscale x 2 x i1>, <vscale x 2 x float>)
declare <vscale x 4 x float> @llvm.masked.expandload.nxv4f32.p0(ptr, <vscale x 4 x i1>, <vscale x 4 x float>)
declare void @llvm.masked.compressstore.nxv4f32.p0(<vscale x 4 x float>, ptr, <vscale x 4 x i1>)

define <vscale x 4 x float> @protected_mload_f32(ptr %p, <vscale x 4 x i1> %m, <vscale x 4 x float> %pt) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x float> @llvm.masked.load.nxv4f32.p0(ptr %p, i32 16, <vscale x 4 x i1> %m, <vscale x 4 x float> %pt)
  ret <vscale x 4 x float> %r
}

define <vscale x 4 x float> @protected_mload_false(ptr %p, <vscale x 4 x float> %pt) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x float> @llvm.masked.load.nxv4f32.p0(ptr %p, i32 16, <vscale x 4 x i1> zeroinitializer, <vscale x 4 x float> %pt)
  ret <vscale x 4 x float> %r
}

define void @protected_mstore_f32(ptr %p, <vscale x 4 x i1> %m, <vscale x 4 x float> %v) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  call void @llvm.masked.store.nxv4f32.p0(<vscale x 4 x float> %v, ptr %p, i32 16, <vscale x 4 x i1> %m)
  ret void
}

define <vscale x 2 x double> @protected_mload_f64(ptr %p, <vscale x 2 x i1> %m, <vscale x 2 x double> %pt) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 2 x double> @llvm.masked.load.nxv2f64.p0(ptr %p, i32 8, <vscale x 2 x i1> %m, <vscale x 2 x double> %pt)
  ret <vscale x 2 x double> %r
}

define void @protected_mstore_f64(ptr %p, <vscale x 2 x i1> %m, <vscale x 2 x double> %v) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  call void @llvm.masked.store.nxv2f64.p0(<vscale x 2 x double> %v, ptr %p, i32 8, <vscale x 2 x i1> %m)
  ret void
}

define <vscale x 8 x half> @protected_mload_f16(ptr %p, <vscale x 8 x i1> %m, <vscale x 8 x half> %pt) noinline optnone "target-features"="+sve,+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 8 x half> @llvm.masked.load.nxv8f16.p0(ptr %p, i32 2, <vscale x 8 x i1> %m, <vscale x 8 x half> %pt)
  ret <vscale x 8 x half> %r
}

define void @protected_mstore_f16(ptr %p, <vscale x 8 x i1> %m, <vscale x 8 x half> %v) noinline optnone "target-features"="+sve,+fullfp16" {
entry:
  call void @hikari_vmp()
  call void @llvm.masked.store.nxv8f16.p0(<vscale x 8 x half> %v, ptr %p, i32 2, <vscale x 8 x i1> %m)
  ret void
}

define <vscale x 4 x float> @unsupported_nofeat(ptr %p, <vscale x 4 x i1> %m, <vscale x 4 x float> %pt) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x float> @llvm.masked.load.nxv4f32.p0(ptr %p, i32 16, <vscale x 4 x i1> %m, <vscale x 4 x float> %pt)
  ret <vscale x 4 x float> %r
}

define i32 @unsupported_internal_nofeat(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x float> @llvm.masked.load.nxv4f32.p0(ptr %p, i32 16, <vscale x 4 x i1> zeroinitializer, <vscale x 4 x float> zeroinitializer)
  ret i32 0
}

define <vscale x 8 x half> @unsupported_half_nofp16(ptr %p, <vscale x 8 x i1> %m, <vscale x 8 x half> %pt) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 8 x half> @llvm.masked.load.nxv8f16.p0(ptr %p, i32 2, <vscale x 8 x i1> %m, <vscale x 8 x half> %pt)
  ret <vscale x 8 x half> %r
}

define i32 @unsupported_partial(ptr %p) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 2 x float> @llvm.masked.load.nxv2f32.p0(ptr %p, i32 8, <vscale x 2 x i1> zeroinitializer, <vscale x 2 x float> zeroinitializer)
  ret i32 0
}

define i32 @unsupported_frem(<vscale x 4 x float> %a, <vscale x 4 x float> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = frem <vscale x 4 x float> %a, %b
  ret i32 0
}

define i32 @unsupported_expand(ptr %p) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x float> @llvm.masked.expandload.nxv4f32.p0(ptr %p, <vscale x 4 x i1> zeroinitializer, <vscale x 4 x float> zeroinitializer)
  ret i32 0
}

define i32 @unsupported_compress(ptr %p, <vscale x 4 x float> %v) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  call void @llvm.masked.compressstore.nxv4f32.p0(<vscale x 4 x float> %v, ptr %p, <vscale x 4 x i1> zeroinitializer)
  ret i32 0
}

define i32 @unsupported_poison(ptr %p) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x float> @llvm.masked.load.nxv4f32.p0(ptr %p, i32 16, <vscale x 4 x i1> zeroinitializer, <vscale x 4 x float> poison)
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
; SKIP-DAG: Skipping VMP on unsupported_frem: unsupported float frem instruction
; SKIP-DAG: Skipping VMP on unsupported_expand: unsupported masked memory instruction
; SKIP-DAG: Skipping VMP on unsupported_compress: unsupported masked memory instruction
; SKIP-DAG: Skipping VMP on unsupported_poison: unsupported masked memory instruction
; SKIP-NOT: Skipping VMP on protected_mload_f32:
; SKIP-NOT: Skipping VMP on protected_mload_false:
; SKIP-NOT: Skipping VMP on protected_mstore_f32:
; SKIP-NOT: Skipping VMP on protected_mload_f64:
; SKIP-NOT: Skipping VMP on protected_mstore_f64:
; SKIP-NOT: Skipping VMP on protected_mload_f16:
; SKIP-NOT: Skipping VMP on protected_mstore_f16:

; VIRT-LABEL: define <vscale x 4 x float> @protected_mload_f32(
; VIRT-SAME: #[[PROT:[0-9]+]]
; VIRT: vmp.sve.regs
; VIRT: vmp.sve.preds
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x float> @llvm.masked.load.nxv4f32.p0(
; VIRT-LABEL: define <vscale x 4 x float> @protected_mload_false(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x float> @llvm.masked.load.nxv4f32.p0(
; VIRT-LABEL: define void @protected_mstore_f32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.masked.store.nxv4f32.p0(
; VIRT-LABEL: define <vscale x 2 x double> @protected_mload_f64(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 2 x double> @llvm.masked.load.nxv2f64.p0(
; VIRT-LABEL: define void @protected_mstore_f64(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.masked.store.nxv2f64.p0(
; VIRT-LABEL: define <vscale x 8 x half> @protected_mload_f16(
; VIRT-SAME: #[[PROTHALF:[0-9]+]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 8 x half> @llvm.masked.load.nxv8f16.p0(
; VIRT-LABEL: define void @protected_mstore_f16(
; VIRT-SAME: #[[PROTHALF]]
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.masked.store.nxv8f16.p0(
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
; BUDGET-ERR: Skipping VMP on protected_mload_f32: bytecode word budget
; BUDGET-IR-LABEL: define <vscale x 4 x float> @protected_mload_f32(
; BUDGET-IR-NOT: vmp.dispatch
; BUDGET-IR: call <vscale x 4 x float> @llvm.masked.load.nxv4f32.p0(
