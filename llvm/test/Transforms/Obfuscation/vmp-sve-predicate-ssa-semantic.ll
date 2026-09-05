; Restricted SVE predicate SSA: last-token +sve.  Same-type icmp of the
; four full-register integer types only, result predicates nxv16i1 /
; nxv8i1 / nxv4i1 / nxv2i1 (legal PPR views).  Independent nxv16i1
; VReg frame (vmp.sve.preds); unpacked preds spill via convert.to/from
; svbool, operate on the native view, then pack.  Same-type pred
; and/or/xor, freeze (normal/undef/poison), and pred/pred/pred select.
; Vector-condition data select requires exact lane match.  Own-function
; pred args/returns.  No pred memory, no scalar-i1 pred select, no
; nxv1i1, no SVE CallDescriptor, no SVE float.  Host cannot execute
; AArch64 SVE.  FileCheck + AArch64 llc/readobj/asm only
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

define <vscale x 16 x i1> @protected_icmp_i8(<vscale x 16 x i8> %a, <vscale x 16 x i8> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = icmp eq <vscale x 16 x i8> %a, %b
  ret <vscale x 16 x i1> %r
}

define <vscale x 8 x i1> @protected_icmp_i16(<vscale x 8 x i16> %a, <vscale x 8 x i16> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = icmp eq <vscale x 8 x i16> %a, %b
  ret <vscale x 8 x i1> %r
}

define <vscale x 4 x i1> @protected_icmp_i32(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = icmp eq <vscale x 4 x i32> %a, %b
  ret <vscale x 4 x i1> %r
}

define <vscale x 2 x i1> @protected_icmp_i64(<vscale x 2 x i64> %a, <vscale x 2 x i64> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = icmp eq <vscale x 2 x i64> %a, %b
  ret <vscale x 2 x i1> %r
}

define <vscale x 4 x i32> @protected_icmp_sel(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b, <vscale x 4 x i32> %c) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %p = icmp slt <vscale x 4 x i32> %a, %b
  %r = select <vscale x 4 x i1> %p, <vscale x 4 x i32> %a, <vscale x 4 x i32> %c
  ret <vscale x 4 x i32> %r
}

define <vscale x 16 x i8> @protected_icmp_sel_i8(<vscale x 16 x i8> %a, <vscale x 16 x i8> %b, <vscale x 16 x i8> %c) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %p = icmp ne <vscale x 16 x i8> %a, %b
  %r = select <vscale x 16 x i1> %p, <vscale x 16 x i8> %a, <vscale x 16 x i8> %c
  ret <vscale x 16 x i8> %r
}

define <vscale x 8 x i16> @protected_icmp_sel_i16(<vscale x 8 x i16> %a, <vscale x 8 x i16> %b, <vscale x 8 x i16> %c) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %p = icmp ugt <vscale x 8 x i16> %a, %b
  %r = select <vscale x 8 x i1> %p, <vscale x 8 x i16> %a, <vscale x 8 x i16> %c
  ret <vscale x 8 x i16> %r
}

define <vscale x 2 x i64> @protected_icmp_sel_i64(<vscale x 2 x i64> %a, <vscale x 2 x i64> %b, <vscale x 2 x i64> %c) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %p = icmp sge <vscale x 2 x i64> %a, %b
  %r = select <vscale x 2 x i1> %p, <vscale x 2 x i64> %a, <vscale x 2 x i64> %c
  ret <vscale x 2 x i64> %r
}

define <vscale x 4 x i32> @protected_icmp_preds(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b, <vscale x 4 x i32> %z) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %eq = icmp eq <vscale x 4 x i32> %a, %b
  %s0 = select <vscale x 4 x i1> %eq, <vscale x 4 x i32> %a, <vscale x 4 x i32> %z
  %ne = icmp ne <vscale x 4 x i32> %a, %b
  %s1 = select <vscale x 4 x i1> %ne, <vscale x 4 x i32> %s0, <vscale x 4 x i32> %z
  %ugt = icmp ugt <vscale x 4 x i32> %a, %b
  %s2 = select <vscale x 4 x i1> %ugt, <vscale x 4 x i32> %s1, <vscale x 4 x i32> %z
  %uge = icmp uge <vscale x 4 x i32> %a, %b
  %s3 = select <vscale x 4 x i1> %uge, <vscale x 4 x i32> %s2, <vscale x 4 x i32> %z
  %ult = icmp ult <vscale x 4 x i32> %a, %b
  %s4 = select <vscale x 4 x i1> %ult, <vscale x 4 x i32> %s3, <vscale x 4 x i32> %z
  %ule = icmp ule <vscale x 4 x i32> %a, %b
  %s5 = select <vscale x 4 x i1> %ule, <vscale x 4 x i32> %s4, <vscale x 4 x i32> %z
  %sgt = icmp sgt <vscale x 4 x i32> %a, %b
  %s6 = select <vscale x 4 x i1> %sgt, <vscale x 4 x i32> %s5, <vscale x 4 x i32> %z
  %sge = icmp sge <vscale x 4 x i32> %a, %b
  %s7 = select <vscale x 4 x i1> %sge, <vscale x 4 x i32> %s6, <vscale x 4 x i32> %z
  %slt = icmp slt <vscale x 4 x i32> %a, %b
  %s8 = select <vscale x 4 x i1> %slt, <vscale x 4 x i32> %s7, <vscale x 4 x i32> %z
  %sle = icmp sle <vscale x 4 x i32> %a, %b
  %r = select <vscale x 4 x i1> %sle, <vscale x 4 x i32> %s8, <vscale x 4 x i32> %z
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @protected_pred_phi(i1 %c, <vscale x 4 x i32> %a, <vscale x 4 x i32> %b, <vscale x 4 x i32> %t, <vscale x 4 x i32> %f) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  br i1 %c, label %l, label %r
l:
  %pl = icmp slt <vscale x 4 x i32> %a, %b
  br label %j
r:
  %pr = icmp sgt <vscale x 4 x i32> %a, %b
  br label %j
j:
  %p = phi <vscale x 4 x i1> [ %pl, %l ], [ %pr, %r ]
  %s = select <vscale x 4 x i1> %p, <vscale x 4 x i32> %t, <vscale x 4 x i32> %f
  ret <vscale x 4 x i32> %s
}

define <vscale x 4 x i32> @protected_pred_arg(<vscale x 4 x i1> %p, <vscale x 4 x i32> %a, <vscale x 4 x i32> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = select <vscale x 4 x i1> %p, <vscale x 4 x i32> %a, <vscale x 4 x i32> %b
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i1> @protected_pred_identity(<vscale x 4 x i1> %p) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  ret <vscale x 4 x i1> %p
}

define <vscale x 4 x i1> @protected_pred_and(<vscale x 4 x i1> %a, <vscale x 4 x i1> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = and <vscale x 4 x i1> %a, %b
  ret <vscale x 4 x i1> %r
}

define <vscale x 4 x i1> @protected_pred_or(<vscale x 4 x i1> %a, <vscale x 4 x i1> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = or <vscale x 4 x i1> %a, %b
  ret <vscale x 4 x i1> %r
}

define <vscale x 4 x i1> @protected_pred_xor(<vscale x 4 x i1> %a, <vscale x 4 x i1> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = xor <vscale x 4 x i1> %a, %b
  ret <vscale x 4 x i1> %r
}

define <vscale x 16 x i1> @protected_pred_and_i8(<vscale x 16 x i1> %a, <vscale x 16 x i1> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = and <vscale x 16 x i1> %a, %b
  ret <vscale x 16 x i1> %r
}

define <vscale x 8 x i1> @protected_pred_or_i16(<vscale x 8 x i1> %a, <vscale x 8 x i1> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = or <vscale x 8 x i1> %a, %b
  ret <vscale x 8 x i1> %r
}

define <vscale x 2 x i1> @protected_pred_xor_i64(<vscale x 2 x i1> %a, <vscale x 2 x i1> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = xor <vscale x 2 x i1> %a, %b
  ret <vscale x 2 x i1> %r
}

define <vscale x 4 x i1> @protected_pred_freeze(<vscale x 4 x i1> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = freeze <vscale x 4 x i1> %a
  ret <vscale x 4 x i1> %r
}

define <vscale x 4 x i1> @protected_pred_freeze_poison() noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = freeze <vscale x 4 x i1> poison
  ret <vscale x 4 x i1> %r
}

define <vscale x 4 x i1> @protected_pred_freeze_undef() noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = freeze <vscale x 4 x i1> undef
  ret <vscale x 4 x i1> %r
}

define <vscale x 4 x i1> @protected_pred_select(<vscale x 4 x i1> %c, <vscale x 4 x i1> %a, <vscale x 4 x i1> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = select <vscale x 4 x i1> %c, <vscale x 4 x i1> %a, <vscale x 4 x i1> %b
  ret <vscale x 4 x i1> %r
}

define <vscale x 16 x i1> @protected_pred_select_i8(<vscale x 16 x i1> %c, <vscale x 16 x i1> %a, <vscale x 16 x i1> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = select <vscale x 16 x i1> %c, <vscale x 16 x i1> %a, <vscale x 16 x i1> %b
  ret <vscale x 16 x i1> %r
}

define <vscale x 4 x i1> @unsupported_nofeat(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = icmp eq <vscale x 4 x i32> %a, %b
  ret <vscale x 4 x i1> %r
}

define <vscale x 4 x i1> @unsupported_disabled(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b) noinline optnone "target-features"="+sve,-sve" {
entry:
  call void @hikari_vmp()
  %r = icmp eq <vscale x 4 x i32> %a, %b
  ret <vscale x 4 x i1> %r
}

define <vscale x 4 x i1> @unsupported_sve2_only(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b) noinline optnone "target-features"="+sve2" {
entry:
  call void @hikari_vmp()
  %r = icmp eq <vscale x 4 x i32> %a, %b
  ret <vscale x 4 x i1> %r
}

define <vscale x 1 x i1> @unsupported_pred_nxv1(<vscale x 1 x i64> %a, <vscale x 1 x i64> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = icmp eq <vscale x 1 x i64> %a, %b
  ret <vscale x 1 x i1> %r
}

define <vscale x 8 x i1> @unsupported_icmp_partial(<vscale x 8 x i8> %a, <vscale x 8 x i8> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = icmp eq <vscale x 8 x i8> %a, %b
  ret <vscale x 8 x i1> %r
}

define <vscale x 4 x i1> @unsupported_pred_shl(<vscale x 4 x i1> %a, <vscale x 4 x i1> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = shl <vscale x 4 x i1> %a, %b
  ret <vscale x 4 x i1> %r
}

define <vscale x 4 x i1> @unsupported_pred_load(ptr %p) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = load <vscale x 4 x i1>, ptr %p
  ret <vscale x 4 x i1> %r
}

define <vscale x 4 x i1> @unsupported_pred_select_i1(i1 %c, <vscale x 4 x i1> %a, <vscale x 4 x i1> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = select i1 %c, <vscale x 4 x i1> %a, <vscale x 4 x i1> %b
  ret <vscale x 4 x i1> %r
}

define <vscale x 4 x i1> @helper_pred(<vscale x 4 x i1> %p) {
entry:
  ret <vscale x 4 x i1> %p
}

define <vscale x 4 x i1> @unsupported_pred_call(<vscale x 4 x i1> %p) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i1> @helper_pred(<vscale x 4 x i1> %p)
  ret <vscale x 4 x i1> %r
}

define void @main() {
entry:
  ret void
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_nofeat: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_disabled: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_sve2_only: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_pred_nxv1: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_icmp_partial: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_pred_shl: unsupported vector binary instruction
; SKIP-DAG: Skipping VMP on unsupported_pred_load: unsupported vector load instruction
; SKIP-DAG: Skipping VMP on unsupported_pred_select_i1: unsupported vector select instruction
; SKIP-DAG: Skipping VMP on unsupported_pred_call: unsupported call return type
; SKIP-NOT: Skipping VMP on protected_icmp_i8:
; SKIP-NOT: Skipping VMP on protected_icmp_i16:
; SKIP-NOT: Skipping VMP on protected_icmp_i32:
; SKIP-NOT: Skipping VMP on protected_icmp_i64:
; SKIP-NOT: Skipping VMP on protected_icmp_sel:
; SKIP-NOT: Skipping VMP on protected_icmp_sel_i8:
; SKIP-NOT: Skipping VMP on protected_icmp_sel_i16:
; SKIP-NOT: Skipping VMP on protected_icmp_sel_i64:
; SKIP-NOT: Skipping VMP on protected_icmp_preds:
; SKIP-NOT: Skipping VMP on protected_pred_phi:
; SKIP-NOT: Skipping VMP on protected_pred_arg:
; SKIP-NOT: Skipping VMP on protected_pred_identity:
; SKIP-NOT: Skipping VMP on protected_pred_and:
; SKIP-NOT: Skipping VMP on protected_pred_or:
; SKIP-NOT: Skipping VMP on protected_pred_xor:
; SKIP-NOT: Skipping VMP on protected_pred_and_i8:
; SKIP-NOT: Skipping VMP on protected_pred_or_i16:
; SKIP-NOT: Skipping VMP on protected_pred_xor_i64:
; SKIP-NOT: Skipping VMP on protected_pred_freeze:
; SKIP-NOT: Skipping VMP on protected_pred_freeze_poison:
; SKIP-NOT: Skipping VMP on protected_pred_freeze_undef:
; SKIP-NOT: Skipping VMP on protected_pred_select:
; SKIP-NOT: Skipping VMP on protected_pred_select_i8:

; VIRT-LABEL: define <vscale x 16 x i1> @protected_icmp_i8(
; VIRT-SAME: #[[PROT:[0-9]+]]
; VIRT: vmp.sve.preds
; VIRT: vmp.dispatch:
; VIRT: icmp eq <vscale x 16 x i8>
; VIRT-LABEL: define <vscale x 8 x i1> @protected_icmp_i16(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: icmp eq <vscale x 8 x i16>
; VIRT-LABEL: define <vscale x 4 x i1> @protected_icmp_i32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: icmp eq <vscale x 4 x i32>
; VIRT-LABEL: define <vscale x 2 x i1> @protected_icmp_i64(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: icmp eq <vscale x 2 x i64>
; VIRT-LABEL: define <vscale x 4 x i32> @protected_icmp_sel(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT-DAG: icmp slt <vscale x 4 x i32>
; VIRT-DAG: select <vscale x 4 x i1>
; VIRT-LABEL: define <vscale x 16 x i8> @protected_icmp_sel_i8(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT-DAG: icmp ne <vscale x 16 x i8>
; VIRT-DAG: select <vscale x 16 x i1>
; VIRT-LABEL: define <vscale x 8 x i16> @protected_icmp_sel_i16(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT-DAG: icmp ugt <vscale x 8 x i16>
; VIRT-DAG: select <vscale x 8 x i1>
; VIRT-LABEL: define <vscale x 2 x i64> @protected_icmp_sel_i64(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT-DAG: icmp sge <vscale x 2 x i64>
; VIRT-DAG: select <vscale x 2 x i1>
; VIRT-LABEL: define <vscale x 4 x i32> @protected_icmp_preds(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT-DAG: icmp eq <vscale x 4 x i32>
; VIRT-DAG: icmp ne <vscale x 4 x i32>
; VIRT-DAG: icmp ugt <vscale x 4 x i32>
; VIRT-DAG: icmp uge <vscale x 4 x i32>
; VIRT-DAG: icmp ult <vscale x 4 x i32>
; VIRT-DAG: icmp ule <vscale x 4 x i32>
; VIRT-DAG: icmp sgt <vscale x 4 x i32>
; VIRT-DAG: icmp sge <vscale x 4 x i32>
; VIRT-DAG: icmp slt <vscale x 4 x i32>
; VIRT-DAG: icmp sle <vscale x 4 x i32>
; VIRT-LABEL: define <vscale x 4 x i32> @protected_pred_phi(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: select <vscale x 4 x i1>
; VIRT-LABEL: define <vscale x 4 x i32> @protected_pred_arg(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: select <vscale x 4 x i1>
; VIRT-LABEL: define <vscale x 4 x i1> @protected_pred_identity(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT-LABEL: define <vscale x 4 x i1> @protected_pred_and(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: and <vscale x 4 x i1>
; VIRT-LABEL: define <vscale x 4 x i1> @protected_pred_or(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: or <vscale x 4 x i1>
; VIRT-LABEL: define <vscale x 4 x i1> @protected_pred_xor(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: xor <vscale x 4 x i1>
; VIRT-LABEL: define <vscale x 16 x i1> @protected_pred_and_i8(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: and <vscale x 16 x i1>
; VIRT-LABEL: define <vscale x 8 x i1> @protected_pred_or_i16(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: or <vscale x 8 x i1>
; VIRT-LABEL: define <vscale x 2 x i1> @protected_pred_xor_i64(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: xor <vscale x 2 x i1>
; VIRT-LABEL: define <vscale x 4 x i1> @protected_pred_freeze(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: freeze <vscale x 4 x i1>
; VIRT-LABEL: define <vscale x 4 x i1> @protected_pred_freeze_poison(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: freeze <vscale x 4 x i1> poison
; VIRT-LABEL: define <vscale x 4 x i1> @protected_pred_freeze_undef(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: freeze <vscale x 4 x i1> undef
; VIRT-LABEL: define <vscale x 4 x i1> @protected_pred_select(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: select <vscale x 4 x i1> {{.*}}, <vscale x 4 x i1>
; VIRT-LABEL: define <vscale x 16 x i1> @protected_pred_select_i8(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: select <vscale x 16 x i1> {{.*}}, <vscale x 16 x i1>
; VIRT: define {{.*}} @unsupported_nofeat({{.*}} #[[UNSUP:[0-9]+]]
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; ASM-DAG: cmpeq{{.*}}p{{[0-9]+}}
; ASM-DAG: sel{{.*}}z{{[0-9]+}}
; ASM-DAG: and{{.*}}p{{[0-9]+}}
; ASM-DAG: eor{{.*}}p{{[0-9]+}}
; ASM-DAG: sel{{.*}}p{{[0-9]+}}.b
; HOST: Skipping VMP: only AArch64 targets are supported
; BUDGET-ERR: Skipping VMP on protected_icmp_i8: bytecode word budget
; BUDGET-IR-LABEL: define <vscale x 16 x i1> @protected_icmp_i8(
; BUDGET-IR-NOT: vmp.dispatch
; BUDGET-IR: icmp eq <vscale x 16 x i8>
