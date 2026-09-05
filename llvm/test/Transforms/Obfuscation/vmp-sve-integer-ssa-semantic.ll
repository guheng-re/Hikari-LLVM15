; Restricted SVE full-register integer SSA: last-token +sve, types
; <vscale x 16 x i8> / <vscale x 8 x i16> / <vscale x 4 x i32> /
; <vscale x 2 x i64>.  Same-type binaries: add/sub/mul/shl (nuw/nsw),
; lshr/ashr/udiv/sdiv (exact), urem/srem (no BinaryFlag), and/or/xor
; (no BinaryFlag).  Flags never cross-replay.  scalar-i1 select, phi,
; freeze, non-atomic AS0 load/store, function args/returns.
; Independent nxv16i8 VReg frame (same-size bitcast).  Vector icmp /
; predicate SSA is the dedicated vmp-sve-predicate-ssa-semantic.ll
; surface.  No extract/insert/shuffle, no SVE CallDescriptor.  Well-shaped feature miss is "unsupported
; target feature".  Host cannot execute AArch64 SVE.  FileCheck +
; AArch64 llc/readobj/asm only (llc: -mattr=+sve -fast-isel=false;
; LLVM 15 FastISel fatals on scalable store TypeSize).  O0/O2 x 97/7.
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

define <vscale x 4 x i32> @protected_add(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = add <vscale x 4 x i32> %a, %b
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @protected_add_nuw(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = add nuw <vscale x 4 x i32> %a, %b
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @protected_add_nsw(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = add nsw <vscale x 4 x i32> %a, %b
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @protected_sub_nuw_nsw(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = sub nuw nsw <vscale x 4 x i32> %a, %b
  ret <vscale x 4 x i32> %r
}

define <vscale x 16 x i8> @protected_xor_i8(<vscale x 16 x i8> %a, <vscale x 16 x i8> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = xor <vscale x 16 x i8> %a, %b
  ret <vscale x 16 x i8> %r
}

define <vscale x 2 x i64> @protected_and_i64(<vscale x 2 x i64> %a, <vscale x 2 x i64> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = and <vscale x 2 x i64> %a, %b
  ret <vscale x 2 x i64> %r
}

define <vscale x 4 x i32> @protected_load_store(ptr %p, ptr %q) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %v = load <vscale x 4 x i32>, ptr %p, align 16
  %w = add <vscale x 4 x i32> %v, %v
  store <vscale x 4 x i32> %w, ptr %q, align 16
  ret <vscale x 4 x i32> %w
}

define <vscale x 4 x i32> @protected_phi(i1 %c, <vscale x 4 x i32> %a, <vscale x 4 x i32> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  br i1 %c, label %t, label %f
t:
  br label %j
f:
  br label %j
j:
  %p = phi <vscale x 4 x i32> [ %a, %t ], [ %b, %f ]
  ret <vscale x 4 x i32> %p
}

define <vscale x 4 x i32> @protected_select(i1 %c, <vscale x 4 x i32> %a, <vscale x 4 x i32> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = select i1 %c, <vscale x 4 x i32> %a, <vscale x 4 x i32> %b
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @protected_freeze(<vscale x 4 x i32> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = freeze <vscale x 4 x i32> %a
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @protected_mul(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = mul <vscale x 4 x i32> %a, %b
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @protected_mul_nuw(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = mul nuw <vscale x 4 x i32> %a, %b
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @protected_mul_nsw(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = mul nsw <vscale x 4 x i32> %a, %b
  ret <vscale x 4 x i32> %r
}

define <vscale x 16 x i8> @protected_mul_i8(<vscale x 16 x i8> %a, <vscale x 16 x i8> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = mul <vscale x 16 x i8> %a, %b
  ret <vscale x 16 x i8> %r
}

define <vscale x 4 x i32> @protected_shl(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = shl <vscale x 4 x i32> %a, %b
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @protected_shl_nuw_nsw(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = shl nuw nsw <vscale x 4 x i32> %a, %b
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @protected_lshr(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = lshr <vscale x 4 x i32> %a, %b
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @protected_lshr_exact(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = lshr exact <vscale x 4 x i32> %a, %b
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @protected_ashr(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = ashr <vscale x 4 x i32> %a, %b
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @protected_ashr_exact(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = ashr exact <vscale x 4 x i32> %a, %b
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @protected_udiv(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = udiv <vscale x 4 x i32> %a, %b
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @protected_udiv_exact(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = udiv exact <vscale x 4 x i32> %a, %b
  ret <vscale x 4 x i32> %r
}

define <vscale x 2 x i64> @protected_udiv_i64(<vscale x 2 x i64> %a, <vscale x 2 x i64> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = udiv <vscale x 2 x i64> %a, %b
  ret <vscale x 2 x i64> %r
}

define <vscale x 4 x i32> @protected_sdiv(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = sdiv <vscale x 4 x i32> %a, %b
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @protected_sdiv_exact(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = sdiv exact <vscale x 4 x i32> %a, %b
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @protected_urem(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = urem <vscale x 4 x i32> %a, %b
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @protected_srem(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = srem <vscale x 4 x i32> %a, %b
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @unsupported_nofeat(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = add <vscale x 4 x i32> %a, %b
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @unsupported_disabled(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b) noinline optnone "target-features"="+sve,-sve" {
entry:
  call void @hikari_vmp()
  %r = add <vscale x 4 x i32> %a, %b
  ret <vscale x 4 x i32> %r
}

define <vscale x 4 x i32> @unsupported_sve2_only(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b) noinline optnone "target-features"="+sve2" {
entry:
  call void @hikari_vmp()
  %r = add <vscale x 4 x i32> %a, %b
  ret <vscale x 4 x i32> %r
}

define <vscale x 8 x i8> @unsupported_partial(<vscale x 8 x i8> %a, <vscale x 8 x i8> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = add <vscale x 8 x i8> %a, %b
  ret <vscale x 8 x i8> %r
}

define <vscale x 4 x i32> @unsupported_inner_narrow(<vscale x 4 x i32> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %c = load volatile <vscale x 8 x i8>, ptr undef
  %n = add <vscale x 8 x i8> %c, %c
  store volatile <vscale x 8 x i8> %n, ptr undef
  ret <vscale x 4 x i32> %a
}

define <vscale x 1 x i1> @unsupported_icmp(<vscale x 1 x i64> %a, <vscale x 1 x i64> %b) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = icmp eq <vscale x 1 x i64> %a, %b
  ret <vscale x 1 x i1> %r
}

define i32 @unsupported_extract(<vscale x 4 x i32> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = extractelement <vscale x 4 x i32> %a, i32 0
  ret i32 %r
}

define void @main() {
entry:
  ret void
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_nofeat: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_disabled: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_sve2_only: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_partial: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_inner_narrow: unsupported vector load instruction
; SKIP-DAG: Skipping VMP on unsupported_icmp: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_extract: unsupported extractelement instruction
; SKIP-NOT: Skipping VMP on protected_add:
; SKIP-NOT: Skipping VMP on protected_add_nuw:
; SKIP-NOT: Skipping VMP on protected_add_nsw:
; SKIP-NOT: Skipping VMP on protected_sub_nuw_nsw:
; SKIP-NOT: Skipping VMP on protected_xor_i8:
; SKIP-NOT: Skipping VMP on protected_and_i64:
; SKIP-NOT: Skipping VMP on protected_load_store:
; SKIP-NOT: Skipping VMP on protected_phi:
; SKIP-NOT: Skipping VMP on protected_select:
; SKIP-NOT: Skipping VMP on protected_freeze:
; SKIP-NOT: Skipping VMP on protected_mul:
; SKIP-NOT: Skipping VMP on protected_mul_nuw:
; SKIP-NOT: Skipping VMP on protected_mul_nsw:
; SKIP-NOT: Skipping VMP on protected_mul_i8:
; SKIP-NOT: Skipping VMP on protected_shl:
; SKIP-NOT: Skipping VMP on protected_shl_nuw_nsw:
; SKIP-NOT: Skipping VMP on protected_lshr:
; SKIP-NOT: Skipping VMP on protected_lshr_exact:
; SKIP-NOT: Skipping VMP on protected_ashr:
; SKIP-NOT: Skipping VMP on protected_ashr_exact:
; SKIP-NOT: Skipping VMP on protected_udiv:
; SKIP-NOT: Skipping VMP on protected_udiv_exact:
; SKIP-NOT: Skipping VMP on protected_udiv_i64:
; SKIP-NOT: Skipping VMP on protected_sdiv:
; SKIP-NOT: Skipping VMP on protected_sdiv_exact:
; SKIP-NOT: Skipping VMP on protected_urem:
; SKIP-NOT: Skipping VMP on protected_srem:

; VIRT-LABEL: define <vscale x 4 x i32> @protected_add(
; VIRT-SAME: #[[PROT:[0-9]+]]
; VIRT: vmp.sve.regs
; VIRT: vmp.dispatch:
; VIRT: add <vscale x 4 x i32>
; VIRT-LABEL: define <vscale x 4 x i32> @protected_add_nuw(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: add nuw <vscale x 4 x i32>
; VIRT-LABEL: define <vscale x 4 x i32> @protected_add_nsw(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: add nsw <vscale x 4 x i32>
; VIRT-LABEL: define <vscale x 4 x i32> @protected_sub_nuw_nsw(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: sub nuw nsw <vscale x 4 x i32>
; VIRT-LABEL: define <vscale x 16 x i8> @protected_xor_i8(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: xor <vscale x 16 x i8>
; VIRT-LABEL: define <vscale x 2 x i64> @protected_and_i64(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: and <vscale x 2 x i64>
; VIRT-LABEL: define <vscale x 4 x i32> @protected_load_store(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT-DAG: load <vscale x 4 x i32>, ptr
; VIRT-DAG: store <vscale x 4 x i32>
; VIRT-LABEL: define <vscale x 4 x i32> @protected_phi(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT-LABEL: define <vscale x 4 x i32> @protected_select(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: select i1
; VIRT-LABEL: define <vscale x 4 x i32> @protected_freeze(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: freeze <vscale x 4 x i32>
; VIRT-LABEL: define <vscale x 4 x i32> @protected_mul(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: mul <vscale x 4 x i32>
; VIRT-LABEL: define <vscale x 4 x i32> @protected_mul_nuw(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: mul nuw <vscale x 4 x i32>
; VIRT-LABEL: define <vscale x 4 x i32> @protected_mul_nsw(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: mul nsw <vscale x 4 x i32>
; VIRT-LABEL: define <vscale x 16 x i8> @protected_mul_i8(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: mul <vscale x 16 x i8>
; VIRT-LABEL: define <vscale x 4 x i32> @protected_shl(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: shl <vscale x 4 x i32>
; VIRT-LABEL: define <vscale x 4 x i32> @protected_shl_nuw_nsw(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: shl nuw nsw <vscale x 4 x i32>
; VIRT-LABEL: define <vscale x 4 x i32> @protected_lshr(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: lshr <vscale x 4 x i32>
; VIRT-LABEL: define <vscale x 4 x i32> @protected_lshr_exact(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: lshr exact <vscale x 4 x i32>
; VIRT-LABEL: define <vscale x 4 x i32> @protected_ashr(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: ashr <vscale x 4 x i32>
; VIRT-LABEL: define <vscale x 4 x i32> @protected_ashr_exact(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: ashr exact <vscale x 4 x i32>
; VIRT-LABEL: define <vscale x 4 x i32> @protected_udiv(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: udiv <vscale x 4 x i32>
; VIRT-LABEL: define <vscale x 4 x i32> @protected_udiv_exact(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: udiv exact <vscale x 4 x i32>
; VIRT-LABEL: define <vscale x 2 x i64> @protected_udiv_i64(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: udiv <vscale x 2 x i64>
; VIRT-LABEL: define <vscale x 4 x i32> @protected_sdiv(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: sdiv <vscale x 4 x i32>
; VIRT-LABEL: define <vscale x 4 x i32> @protected_sdiv_exact(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: sdiv exact <vscale x 4 x i32>
; VIRT-LABEL: define <vscale x 4 x i32> @protected_urem(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: urem <vscale x 4 x i32>
; VIRT-LABEL: define <vscale x 4 x i32> @protected_srem(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: srem <vscale x 4 x i32>
; VIRT: define {{.*}} @unsupported_nofeat({{.*}} #[[UNSUP:[0-9]+]]
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; ASM-DAG: add{{.*}}z{{[0-9]+}}.s
; ASM-DAG: mul{{.*}}z{{[0-9]+}}.s
; ASM-DAG: lsl{{.*}}z{{[0-9]+}}.s
; ASM-DAG: lsr{{.*}}z{{[0-9]+}}.s
; ASM-DAG: asr{{.*}}z{{[0-9]+}}.s
; ASM-DAG: udiv{{.*}}z{{[0-9]+}}.s
; ASM-DAG: sdiv{{.*}}z{{[0-9]+}}.s
; HOST: Skipping VMP: only AArch64 targets are supported
; BUDGET-ERR: Skipping VMP on protected_add: bytecode word budget
; BUDGET-IR-LABEL: define <vscale x 4 x i32> @protected_add(
; BUDGET-IR-NOT: vmp.dispatch
; BUDGET-IR: add <vscale x 4 x i32>
