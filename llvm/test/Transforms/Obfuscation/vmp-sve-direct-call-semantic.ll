; Restricted direct C calls that carry full-register SVE data args or
; results: last-token +sve; nxv16i8 / nxv8i16 / nxv4i32 / nxv2i64;
; nxv4f32 / nxv2f64; nxv8f16 also last-token +fullfp16.  Mixed with
; ordinary scalars.  Replayed via CallDescriptor / nxv16i8 VRegs
; (TCK_None).  Predicates, pointer vectors, indirect, musttail, and
; SVE-typed ABI without +sve stay skipped.  Host cannot execute
; AArch64 SVE.  FileCheck + AArch64 llc/readobj/asm (llc: -mattr=+sve,
; +fullfp16 -fast-isel=false).  O0/O2 x 97/7.
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

define <vscale x 4 x i32> @helper_id_i32(<vscale x 4 x i32> %a) {
entry:
  ret <vscale x 4 x i32> %a
}

define <vscale x 4 x i32> @helper_add_i32(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b) {
entry:
  %r = add <vscale x 4 x i32> %a, %b
  ret <vscale x 4 x i32> %r
}

define <vscale x 16 x i8> @helper_id_i8(<vscale x 16 x i8> %a) {
entry:
  ret <vscale x 16 x i8> %a
}

define <vscale x 4 x float> @helper_id_f32(<vscale x 4 x float> %a) {
entry:
  ret <vscale x 4 x float> %a
}

define <vscale x 8 x half> @helper_id_f16(<vscale x 8 x half> %a) {
entry:
  ret <vscale x 8 x half> %a
}

define void @helper_store_i32(ptr %p, <vscale x 4 x i32> %a) {
entry:
  store <vscale x 4 x i32> %a, ptr %p, align 16
  ret void
}

define <vscale x 4 x i32> @helper_mix(i32 %s, <vscale x 4 x i32> %a) {
entry:
  %b = insertelement <vscale x 4 x i32> %a, i32 %s, i32 0
  ret <vscale x 4 x i32> %b
}

define <vscale x 4 x i1> @helper_pred(<vscale x 4 x i1> %p) {
entry:
  ret <vscale x 4 x i1> %p
}

define <vscale x 4 x i32> @protected_id_i32(<vscale x 4 x i32> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @helper_id_i32(<vscale x 4 x i32> %a)
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @protected_add_i32(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @helper_add_i32(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b)
  ret <vscale x 4 x i32> %r
}

define <vscale x 16 x i8> @protected_id_i8(<vscale x 16 x i8> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 16 x i8> @helper_id_i8(<vscale x 16 x i8> %a)
  ret <vscale x 16 x i8> %r
}

define <vscale x 4 x float> @protected_id_f32(<vscale x 4 x float> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x float> @helper_id_f32(<vscale x 4 x float> %a)
  ret <vscale x 4 x float> %r
}

define <vscale x 4 x float> @protected_id_f32_nnan(<vscale x 4 x float> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call nnan <vscale x 4 x float> @helper_id_f32(<vscale x 4 x float> %a)
  ret <vscale x 4 x float> %r
}

define <vscale x 8 x half> @protected_id_f16(<vscale x 8 x half> %a) noinline optnone "target-features"="+sve,+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 8 x half> @helper_id_f16(<vscale x 8 x half> %a)
  ret <vscale x 8 x half> %r
}

define void @protected_store_i32(ptr %p, <vscale x 4 x i32> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  call void @helper_store_i32(ptr %p, <vscale x 4 x i32> %a)
  ret void
}

define <vscale x 4 x i32> @protected_mix(i32 %s, <vscale x 4 x i32> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @helper_mix(i32 %s, <vscale x 4 x i32> %a)
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @unsupported_nofeat(<vscale x 4 x i32> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @helper_id_i32(<vscale x 4 x i32> %a)
  ret <vscale x 4 x i32> %r
}

define i32 @unsupported_internal_nofeat(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %a = load <vscale x 4 x i32>, ptr %p, align 16
  %r = call <vscale x 4 x i32> @helper_id_i32(<vscale x 4 x i32> %a)
  ret i32 0
}

define <vscale x 8 x half> @unsupported_half_nofp16(<vscale x 8 x half> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 8 x half> @helper_id_f16(<vscale x 8 x half> %a)
  ret <vscale x 8 x half> %r
}

define <vscale x 4 x i1> @unsupported_pred(<vscale x 4 x i1> %p) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i1> @helper_pred(<vscale x 4 x i1> %p)
  ret <vscale x 4 x i1> %r
}

define i32 @unsupported_indirect(ptr %fp, <vscale x 4 x i32> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> %fp(<vscale x 4 x i32> %a)
  ret i32 0
}

define <vscale x 4 x i32> @unsupported_musttail(<vscale x 4 x i32> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = musttail call <vscale x 4 x i32> @helper_id_i32(<vscale x 4 x i32> %a)
  ret <vscale x 4 x i32> %r
}

define i32 @unsupported_poison(<vscale x 4 x i32> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @helper_id_i32(<vscale x 4 x i32> poison)
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
; SKIP-DAG: Skipping VMP on unsupported_pred: unsupported call return type
; SKIP-DAG: Skipping VMP on unsupported_indirect: indirect call
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_poison: unsupported call return type
; SKIP-NOT: Skipping VMP on protected_id_i32:
; SKIP-NOT: Skipping VMP on protected_add_i32:
; SKIP-NOT: Skipping VMP on protected_id_i8:
; SKIP-NOT: Skipping VMP on protected_id_f32:
; SKIP-NOT: Skipping VMP on protected_id_f32_nnan:
; SKIP-NOT: Skipping VMP on protected_id_f16:
; SKIP-NOT: Skipping VMP on protected_store_i32:
; SKIP-NOT: Skipping VMP on protected_mix:

; VIRT-LABEL: define <vscale x 4 x i32> @protected_id_i32(
; VIRT-SAME: #[[PROT:[0-9]+]]
; VIRT: vmp.sve.regs
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x i32> @helper_id_i32(
; VIRT-LABEL: define <vscale x 4 x i32> @protected_add_i32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x i32> @helper_add_i32(
; VIRT-LABEL: define <vscale x 16 x i8> @protected_id_i8(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 16 x i8> @helper_id_i8(
; VIRT-LABEL: define <vscale x 4 x float> @protected_id_f32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x float> @helper_id_f32(
; VIRT-LABEL: define <vscale x 4 x float> @protected_id_f32_nnan(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call nnan <vscale x 4 x float> @helper_id_f32(
; VIRT-LABEL: define <vscale x 8 x half> @protected_id_f16(
; VIRT-SAME: #[[PROTHALF:[0-9]+]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 8 x half> @helper_id_f16(
; VIRT-LABEL: define void @protected_store_i32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call void @helper_store_i32(
; VIRT-LABEL: define <vscale x 4 x i32> @protected_mix(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call <vscale x 4 x i32> @helper_mix(
; VIRT: define {{.*}} @unsupported_nofeat({{.*}} #[[UNSUP:[0-9]+]]
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[PROTHALF]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; ASM-DAG: bl{{.*}}helper_id_i32
; ASM-DAG: bl{{.*}}helper_add_i32
; ASM-DAG: bl{{.*}}helper_id_i8
; ASM-DAG: bl{{.*}}helper_id_f32
; ASM-DAG: bl{{.*}}helper_id_f16
; ASM-DAG: bl{{.*}}helper_store_i32
; ASM-DAG: bl{{.*}}helper_mix
; HOST: Skipping VMP: only AArch64 targets are supported
; BUDGET-ERR: Skipping VMP on protected_id_i32: bytecode word budget
; BUDGET-IR-LABEL: define <vscale x 4 x i32> @protected_id_i32(
; BUDGET-IR-NOT: vmp.dispatch
; BUDGET-IR: call <vscale x 4 x i32> @helper_id_i32(
