; AArch64 MOPS tagged memset via normal Call path:
;   ptr @llvm.aarch64.mops.memset.tag(ptr AS0, i8, i64)
; No dedicated VM opcode.  Dest / fill / length are pointer / i8 / i64 VRegs;
; the ptr result uses the pointer VReg frame.  Requires an explicit function
; "target-features" enabling both exact +mops and exact +mte (each last
; +feat/-feat token wins; +mops2 does not count as +mops).  Missing either
; feature reports "unsupported target feature".  Non-AS0 / wrong type /
; other MOPS / MTE stack-only irg.sp stay generic rejects.  Command-line
; -mattr is never used for eligibility.
;
; Host x86_64 cannot select MOPS+MTE.  No lli.  FileCheck + AArch64 llc
; -mattr=+mops,+mte assembly on the live main-reachable subset must contain
; setgp/setgm/setge from the re-emitted intrinsic.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.ll -o %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+mops,+mte %t.o0.live.ll -o - | FileCheck %s --check-prefix=ASM
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.ll -o %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+mops,+mte %t.o2.live.ll -o - | FileCheck %s --check-prefix=ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll

target triple = "aarch64-unknown-linux-gnu"

@sink = global ptr null

declare void @hikari_vmp()
declare ptr @llvm.aarch64.mops.memset.tag(ptr, i8, i64)
declare ptr @llvm.aarch64.irg.sp(i64)
declare i128 @llvm.ctpop.i128(i128)

define ptr @reference_mops_tag(ptr %p, i8 %v, i64 %n) "target-features"="+mops,+mte" {
entry:
  %r = call ptr @llvm.aarch64.mops.memset.tag(ptr %p, i8 %v, i64 %n)
  store volatile ptr %r, ptr @sink
  ret ptr %r
}

define ptr @protected_mops_tag(ptr %p, i8 %v, i64 %n) noinline optnone "target-features"="+mops,+mte" {
entry:
  call void @hikari_vmp()
  %r = call ptr @llvm.aarch64.mops.memset.tag(ptr %p, i8 %v, i64 %n)
  store volatile ptr %r, ptr @sink
  ret ptr %r
}

define ptr @protected_mops_tag_multi(ptr %p, i8 %v, i64 %n) noinline optnone "target-features"="+neon,+mops,+mte,+fp-armv8" {
entry:
  call void @hikari_vmp()
  %r = call ptr @llvm.aarch64.mops.memset.tag(ptr %p, i8 %v, i64 %n)
  store volatile ptr %r, ptr @sink
  ret ptr %r
}

define ptr @unsupported_mops_no_mte(ptr %p, i8 %v, i64 %n) noinline optnone "target-features"="+mops,-mte" {
entry:
  call void @hikari_vmp()
  %r = call ptr @llvm.aarch64.mops.memset.tag(ptr %p, i8 %v, i64 %n)
  ret ptr %r
}

define ptr @unsupported_mte_no_mops(ptr %p, i8 %v, i64 %n) noinline optnone "target-features"="+mte,-mops" {
entry:
  call void @hikari_vmp()
  %r = call ptr @llvm.aarch64.mops.memset.tag(ptr %p, i8 %v, i64 %n)
  ret ptr %r
}

define ptr @unsupported_mops2_only(ptr %p, i8 %v, i64 %n) noinline optnone "target-features"="+mops2,+mte" {
entry:
  call void @hikari_vmp()
  %r = call ptr @llvm.aarch64.mops.memset.tag(ptr %p, i8 %v, i64 %n)
  ret ptr %r
}

; AS1 cannot be a memset.tag operand (fixed llvm_ptr_ty / AS0).  An AS1
; argument is rejected at the function-type gate.
define i64 @unsupported_as1(ptr addrspace(1) %p, i8 %v, i64 %n) noinline optnone "target-features"="+mops,+mte" {
entry:
  call void @hikari_vmp()
  ret i64 %n
}

; i128 is not a memset.tag size (fixed i64).  A second declare of
; memset.tag with i32/i128 is illegal under -verify-each, so this sibling
; widens to i128 (unsupported cast) to cover the wrong-width reject.
define i64 @unsupported_wrong_width(i64 %n) noinline optnone "target-features"="+mops,+mte" {
entry:
  call void @hikari_vmp()
  %w = zext i64 %n to i128
  %c = call i128 @llvm.ctpop.i128(i128 %w)
  %t = trunc i128 %c to i64
  ret i64 %t
}

; MTE stack-only irg.sp must not be opened by the MOPS whitelist.
define ptr @unsupported_irg_sp(i64 %excl) noinline optnone "target-features"="+mops,+mte" {
entry:
  call void @hikari_vmp()
  %t = call ptr @llvm.aarch64.irg.sp(i64 %excl)
  ret ptr %t
}

define ptr @main(ptr %p, i8 %v, i64 %n) {
entry:
  %e = call ptr @reference_mops_tag(ptr %p, i8 %v, i64 %n)
  %a = call ptr @protected_mops_tag(ptr %p, i8 %v, i64 %n)
  %b = call ptr @protected_mops_tag_multi(ptr %p, i8 %v, i64 %n)
  store volatile ptr %e, ptr @sink
  store volatile ptr %a, ptr @sink
  store volatile ptr %b, ptr @sink
  ret ptr %a
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_mops_no_mte: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_mte_no_mops: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_mops2_only: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_as1: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_wrong_width: unsupported cast instruction
; SKIP-DAG: Skipping VMP on unsupported_irg_sp: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_mops_tag:
; SKIP-NOT: Skipping VMP on protected_mops_tag_multi:

; VIRT: define ptr @protected_mops_tag({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call ptr @llvm.aarch64.mops.memset.tag(
; VIRT: define ptr @protected_mops_tag_multi({{.*}} #[[PROT_MULTI:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call ptr @llvm.aarch64.mops.memset.tag(
; VIRT: define ptr @unsupported_mops_no_mte({{.*}} #[[UNSUP_MTE:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call ptr @llvm.aarch64.mops.memset.tag(
; VIRT: define ptr @unsupported_mte_no_mops({{.*}} #[[UNSUP_MOPS:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call ptr @llvm.aarch64.mops.memset.tag(
; VIRT: define ptr @unsupported_mops2_only({{.*}} #[[UNSUP_MOPS2:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call ptr @llvm.aarch64.mops.memset.tag(
; VIRT: define i64 @unsupported_as1({{.*}} #[[UNSUP_SHAPE:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define i64 @unsupported_wrong_width({{.*}} #[[UNSUP_SHAPE]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call i128 @llvm.ctpop.i128(
; VIRT: define ptr @unsupported_irg_sp({{.*}} #[[UNSUP_SHAPE]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call ptr @llvm.aarch64.irg.sp(
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[PROT_MULTI]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP_MTE]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT: attributes #[[UNSUP_MOPS]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT: attributes #[[UNSUP_MOPS2]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT: attributes #[[UNSUP_SHAPE]] = { {{.*}}"hikari.vmp.selected"{{.*}} }

; ASM-DAG: setgp
; ASM-DAG: setgm
; ASM-DAG: setge
