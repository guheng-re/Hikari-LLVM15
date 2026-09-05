; Restricted SVE full-register float SSA: last-token +sve, types
; <vscale x 4 x float> / <vscale x 2 x double>; <vscale x 8 x half>
; also requires last-token +fullfp16.  Same-type fadd/fsub/fmul/fdiv
; (FastMathFlags replayed), fneg, fcmp (predicate frame), scalar-i1
; and lane-matched pred select, phi, freeze, non-atomic AS0 load/store,
; function args/returns.  Reuses the nxv16i8 data frame.  frem is
; ISel-fatal and stays skipped.  No extract/insert/shuffle, no SVE
; float CallDescriptor, no scalable bfloat.  Well-shaped feature miss
; is "unsupported target feature"; ABI-only miss is return/argument
; type.  Host cannot execute AArch64 SVE.  FileCheck + AArch64
; llc/readobj/asm only (llc: -mattr=+sve,+fullfp16 -fast-isel=false).
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

define <vscale x 4 x float> @protected_fadd(<vscale x 4 x float> %a, <vscale x 4 x float> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = fadd <vscale x 4 x float> %a, %b
  ret <vscale x 4 x float> %r
}

define <vscale x 4 x float> @protected_fadd_nnan(<vscale x 4 x float> %a, <vscale x 4 x float> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = fadd nnan <vscale x 4 x float> %a, %b
  ret <vscale x 4 x float> %r
}

define <vscale x 4 x float> @protected_fsub(<vscale x 4 x float> %a, <vscale x 4 x float> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = fsub <vscale x 4 x float> %a, %b
  ret <vscale x 4 x float> %r
}

define <vscale x 4 x float> @protected_fmul(<vscale x 4 x float> %a, <vscale x 4 x float> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = fmul <vscale x 4 x float> %a, %b
  ret <vscale x 4 x float> %r
}

define <vscale x 4 x float> @protected_fdiv(<vscale x 4 x float> %a, <vscale x 4 x float> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = fdiv <vscale x 4 x float> %a, %b
  ret <vscale x 4 x float> %r
}

define <vscale x 4 x float> @protected_fneg(<vscale x 4 x float> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = fneg <vscale x 4 x float> %a
  ret <vscale x 4 x float> %r
}

define <vscale x 2 x double> @protected_fadd_f64(<vscale x 2 x double> %a, <vscale x 2 x double> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = fadd <vscale x 2 x double> %a, %b
  ret <vscale x 2 x double> %r
}

define <vscale x 8 x half> @protected_fadd_f16(<vscale x 8 x half> %a, <vscale x 8 x half> %b) noinline optnone "target-features"="+sve,+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = fadd <vscale x 8 x half> %a, %b
  ret <vscale x 8 x half> %r
}

define <vscale x 4 x i1> @protected_fcmp(<vscale x 4 x float> %a, <vscale x 4 x float> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = fcmp ogt <vscale x 4 x float> %a, %b
  ret <vscale x 4 x i1> %r
}

define <vscale x 4 x float> @protected_select(i1 %c, <vscale x 4 x float> %a, <vscale x 4 x float> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = select i1 %c, <vscale x 4 x float> %a, <vscale x 4 x float> %b
  ret <vscale x 4 x float> %r
}

define <vscale x 4 x float> @protected_pred_select(<vscale x 4 x i1> %m, <vscale x 4 x float> %a, <vscale x 4 x float> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = select <vscale x 4 x i1> %m, <vscale x 4 x float> %a, <vscale x 4 x float> %b
  ret <vscale x 4 x float> %r
}

define <vscale x 4 x float> @protected_phi(i1 %c, <vscale x 4 x float> %a, <vscale x 4 x float> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  br i1 %c, label %t, label %f
t:
  br label %j
f:
  br label %j
j:
  %p = phi <vscale x 4 x float> [ %a, %t ], [ %b, %f ]
  ret <vscale x 4 x float> %p
}

define <vscale x 4 x float> @protected_freeze(<vscale x 4 x float> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = freeze <vscale x 4 x float> %a
  ret <vscale x 4 x float> %r
}

define <vscale x 4 x float> @protected_load_store(ptr %p, ptr %q) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %v = load <vscale x 4 x float>, ptr %p, align 16
  %w = fadd <vscale x 4 x float> %v, %v
  store <vscale x 4 x float> %w, ptr %q, align 16
  ret <vscale x 4 x float> %w
}

define <vscale x 4 x float> @unsupported_nofeat(<vscale x 4 x float> %a, <vscale x 4 x float> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = fadd <vscale x 4 x float> %a, %b
  ret <vscale x 4 x float> %r
}

define <vscale x 4 x float> @unsupported_disabled(<vscale x 4 x float> %a, <vscale x 4 x float> %b) noinline optnone "target-features"="+sve,-sve" {
entry:
  call void @hikari_vmp()
  %r = fadd <vscale x 4 x float> %a, %b
  ret <vscale x 4 x float> %r
}

define <vscale x 4 x float> @unsupported_sve2_only(<vscale x 4 x float> %a, <vscale x 4 x float> %b) noinline optnone "target-features"="+sve2" {
entry:
  call void @hikari_vmp()
  %r = fadd <vscale x 4 x float> %a, %b
  ret <vscale x 4 x float> %r
}

define <vscale x 8 x half> @unsupported_half_nofp16(<vscale x 8 x half> %a, <vscale x 8 x half> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = fadd <vscale x 8 x half> %a, %b
  ret <vscale x 8 x half> %r
}

define <vscale x 8 x half> @unsupported_half_disabled(<vscale x 8 x half> %a, <vscale x 8 x half> %b) noinline optnone "target-features"="+sve,+fullfp16,-fullfp16" {
entry:
  call void @hikari_vmp()
  %r = fadd <vscale x 8 x half> %a, %b
  ret <vscale x 8 x half> %r
}

define <vscale x 4 x float> @unsupported_frem(<vscale x 4 x float> %a, <vscale x 4 x float> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = frem <vscale x 4 x float> %a, %b
  ret <vscale x 4 x float> %r
}

define <vscale x 2 x float> @unsupported_partial(<vscale x 2 x float> %a, <vscale x 2 x float> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = fadd <vscale x 2 x float> %a, %b
  ret <vscale x 2 x float> %r
}

define float @unsupported_extract(<vscale x 4 x float> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = extractelement <vscale x 4 x float> %a, i32 0
  ret float %r
}

define void @main() {
entry:
  ret void
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_nofeat: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_disabled: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_sve2_only: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_half_nofp16: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_half_disabled: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_frem: unsupported float frem instruction
; SKIP-DAG: Skipping VMP on unsupported_partial: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_extract: unsupported extractelement instruction
; SKIP-NOT: Skipping VMP on protected_fadd:
; SKIP-NOT: Skipping VMP on protected_fadd_nnan:
; SKIP-NOT: Skipping VMP on protected_fsub:
; SKIP-NOT: Skipping VMP on protected_fmul:
; SKIP-NOT: Skipping VMP on protected_fdiv:
; SKIP-NOT: Skipping VMP on protected_fneg:
; SKIP-NOT: Skipping VMP on protected_fadd_f64:
; SKIP-NOT: Skipping VMP on protected_fadd_f16:
; SKIP-NOT: Skipping VMP on protected_fcmp:
; SKIP-NOT: Skipping VMP on protected_select:
; SKIP-NOT: Skipping VMP on protected_pred_select:
; SKIP-NOT: Skipping VMP on protected_phi:
; SKIP-NOT: Skipping VMP on protected_freeze:
; SKIP-NOT: Skipping VMP on protected_load_store:

; VIRT-LABEL: define <vscale x 4 x float> @protected_fadd(
; VIRT-SAME: #[[PROT:[0-9]+]]
; VIRT: vmp.sve.regs
; VIRT: vmp.dispatch:
; VIRT: fadd <vscale x 4 x float>
; VIRT-LABEL: define <vscale x 4 x float> @protected_fadd_nnan(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: fadd nnan <vscale x 4 x float>
; VIRT-LABEL: define <vscale x 4 x float> @protected_fsub(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: fsub <vscale x 4 x float>
; VIRT-LABEL: define <vscale x 4 x float> @protected_fmul(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: fmul <vscale x 4 x float>
; VIRT-LABEL: define <vscale x 4 x float> @protected_fdiv(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: fdiv <vscale x 4 x float>
; VIRT-LABEL: define <vscale x 4 x float> @protected_fneg(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: fneg <vscale x 4 x float>
; VIRT-LABEL: define <vscale x 2 x double> @protected_fadd_f64(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: fadd <vscale x 2 x double>
; VIRT-LABEL: define <vscale x 8 x half> @protected_fadd_f16(
; VIRT-SAME: #[[PROTHALF:[0-9]+]]
; VIRT: vmp.dispatch:
; VIRT: fadd <vscale x 8 x half>
; VIRT-LABEL: define <vscale x 4 x i1> @protected_fcmp(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.sve.preds
; VIRT: vmp.dispatch:
; VIRT: fcmp ogt <vscale x 4 x float>
; VIRT-LABEL: define <vscale x 4 x float> @protected_select(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: select i1
; VIRT-LABEL: define <vscale x 4 x float> @protected_pred_select(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: select <vscale x 4 x i1>
; VIRT-LABEL: define <vscale x 4 x float> @protected_phi(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT-LABEL: define <vscale x 4 x float> @protected_freeze(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: freeze <vscale x 4 x float>
; VIRT-LABEL: define <vscale x 4 x float> @protected_load_store(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT-DAG: load <vscale x 4 x float>, ptr
; VIRT-DAG: store <vscale x 4 x float>
; VIRT: define {{.*}} @unsupported_nofeat({{.*}} #[[UNSUP:[0-9]+]]
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[PROTHALF]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; ASM-DAG: fadd{{.*}}z{{[0-9]+}}.s
; ASM-DAG: fsub{{.*}}z{{[0-9]+}}.s
; ASM-DAG: fmul{{.*}}z{{[0-9]+}}.s
; ASM-DAG: fdiv{{.*}}z{{[0-9]+}}.s
; ASM-DAG: fneg{{.*}}z{{[0-9]+}}.s
; ASM-DAG: fadd{{.*}}z{{[0-9]+}}.d
; ASM-DAG: fadd{{.*}}z{{[0-9]+}}.h
; ASM-DAG: fcmgt{{.*}}p{{[0-9]+}}.s
; HOST: Skipping VMP: only AArch64 targets are supported
; BUDGET-ERR: Skipping VMP on protected_fadd: bytecode word budget
; BUDGET-IR-LABEL: define <vscale x 4 x float> @protected_fadd(
; BUDGET-IR-NOT: vmp.dispatch
; BUDGET-IR: fadd <vscale x 4 x float>
