; Restricted same-lane full-register SVE sitofp/uitofp/fptosi/fptoui:
; last-token +sve; nxv4i32<->nxv4f32, nxv2i64<->nxv2f64; nxv8i16<->nxv8f16
; also last-token +fullfp16.  Both sides reuse the nxv16i8 data frame.
; fpext/fptrunc change VL bits so one side is never a full-register type
; and stay skipped.  Missing last-token features stay skipped.
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

define <vscale x 4 x float> @protected_sitofp_i32(<vscale x 4 x i32> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = sitofp <vscale x 4 x i32> %a to <vscale x 4 x float>
  ret <vscale x 4 x float> %r
}

define <vscale x 4 x float> @protected_uitofp_i32(<vscale x 4 x i32> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = uitofp <vscale x 4 x i32> %a to <vscale x 4 x float>
  ret <vscale x 4 x float> %r
}

define <vscale x 4 x i32> @protected_fptosi_f32(<vscale x 4 x float> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = fptosi <vscale x 4 x float> %a to <vscale x 4 x i32>
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @protected_fptoui_f32(<vscale x 4 x float> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = fptoui <vscale x 4 x float> %a to <vscale x 4 x i32>
  ret <vscale x 4 x i32> %r
}

define <vscale x 2 x double> @protected_sitofp_i64(<vscale x 2 x i64> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = sitofp <vscale x 2 x i64> %a to <vscale x 2 x double>
  ret <vscale x 2 x double> %r
}

define <vscale x 2 x i64> @protected_fptosi_f64(<vscale x 2 x double> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = fptosi <vscale x 2 x double> %a to <vscale x 2 x i64>
  ret <vscale x 2 x i64> %r
}

define <vscale x 8 x half> @protected_sitofp_i16(<vscale x 8 x i16> %a) noinline optnone "target-features"="+sve,+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = sitofp <vscale x 8 x i16> %a to <vscale x 8 x half>
  ret <vscale x 8 x half> %r
}

define <vscale x 8 x i16> @protected_fptosi_f16(<vscale x 8 x half> %a) noinline optnone "target-features"="+sve,+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = fptosi <vscale x 8 x half> %a to <vscale x 8 x i16>
  ret <vscale x 8 x i16> %r
}

define <vscale x 4 x float> @unsupported_nofeat(<vscale x 4 x i32> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = sitofp <vscale x 4 x i32> %a to <vscale x 4 x float>
  ret <vscale x 4 x float> %r
}

define i32 @unsupported_internal_nofeat(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %a = load <vscale x 4 x i32>, ptr %p, align 16
  %r = sitofp <vscale x 4 x i32> %a to <vscale x 4 x float>
  ret i32 0
}

define <vscale x 8 x half> @unsupported_half_nofp16(<vscale x 8 x i16> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = sitofp <vscale x 8 x i16> %a to <vscale x 8 x half>
  ret <vscale x 8 x half> %r
}

define i32 @unsupported_fpext(<vscale x 4 x float> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = fpext <vscale x 4 x float> %a to <vscale x 4 x double>
  ret i32 0
}

define i32 @unsupported_fptrunc(<vscale x 2 x double> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = fptrunc <vscale x 2 x double> %a to <vscale x 2 x float>
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
; SKIP-DAG: Skipping VMP on unsupported_fpext: unsupported vector cast instruction
; SKIP-DAG: Skipping VMP on unsupported_fptrunc: unsupported vector cast instruction
; SKIP-NOT: Skipping VMP on protected_sitofp_i32:
; SKIP-NOT: Skipping VMP on protected_uitofp_i32:
; SKIP-NOT: Skipping VMP on protected_fptosi_f32:
; SKIP-NOT: Skipping VMP on protected_fptoui_f32:
; SKIP-NOT: Skipping VMP on protected_sitofp_i64:
; SKIP-NOT: Skipping VMP on protected_fptosi_f64:
; SKIP-NOT: Skipping VMP on protected_sitofp_i16:
; SKIP-NOT: Skipping VMP on protected_fptosi_f16:

; VIRT-LABEL: define <vscale x 4 x float> @protected_sitofp_i32(
; VIRT-SAME: #[[PROT:[0-9]+]]
; VIRT: vmp.sve.regs
; VIRT: vmp.dispatch:
; VIRT: sitofp <vscale x 4 x i32> {{.*}} to <vscale x 4 x float>
; VIRT-LABEL: define <vscale x 4 x float> @protected_uitofp_i32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: uitofp <vscale x 4 x i32> {{.*}} to <vscale x 4 x float>
; VIRT-LABEL: define <vscale x 4 x i32> @protected_fptosi_f32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: fptosi <vscale x 4 x float> {{.*}} to <vscale x 4 x i32>
; VIRT-LABEL: define <vscale x 4 x i32> @protected_fptoui_f32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: fptoui <vscale x 4 x float> {{.*}} to <vscale x 4 x i32>
; VIRT-LABEL: define <vscale x 2 x double> @protected_sitofp_i64(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: sitofp <vscale x 2 x i64> {{.*}} to <vscale x 2 x double>
; VIRT-LABEL: define <vscale x 2 x i64> @protected_fptosi_f64(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: fptosi <vscale x 2 x double> {{.*}} to <vscale x 2 x i64>
; VIRT-LABEL: define <vscale x 8 x half> @protected_sitofp_i16(
; VIRT-SAME: #[[PROTHALF:[0-9]+]]
; VIRT: vmp.dispatch:
; VIRT: sitofp <vscale x 8 x i16> {{.*}} to <vscale x 8 x half>
; VIRT-LABEL: define <vscale x 8 x i16> @protected_fptosi_f16(
; VIRT-SAME: #[[PROTHALF]]
; VIRT: vmp.dispatch:
; VIRT: fptosi <vscale x 8 x half> {{.*}} to <vscale x 8 x i16>
; VIRT: define {{.*}} @unsupported_nofeat({{.*}} #[[UNSUP:[0-9]+]]
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[PROTHALF]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; ASM-DAG: scvtf{{.*}}z{{[0-9]+}}.s
; ASM-DAG: ucvtf{{.*}}z{{[0-9]+}}.s
; ASM-DAG: fcvtzs{{.*}}z{{[0-9]+}}.s
; ASM-DAG: fcvtzu{{.*}}z{{[0-9]+}}.s
; ASM-DAG: scvtf{{.*}}z{{[0-9]+}}.d
; ASM-DAG: fcvtzs{{.*}}z{{[0-9]+}}.d
; ASM-DAG: scvtf{{.*}}z{{[0-9]+}}.h
; ASM-DAG: fcvtzs{{.*}}z{{[0-9]+}}.h
; HOST: Skipping VMP: only AArch64 targets are supported
; BUDGET-ERR: Skipping VMP on protected_sitofp_i32: bytecode word budget
; BUDGET-IR-LABEL: define <vscale x 4 x float> @protected_sitofp_i32(
; BUDGET-IR-NOT: vmp.dispatch
; BUDGET-IR: sitofp <vscale x 4 x i32>
