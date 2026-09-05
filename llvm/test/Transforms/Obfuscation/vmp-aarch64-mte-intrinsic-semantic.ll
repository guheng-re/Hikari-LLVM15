; AArch64 MTE main-path via normal Call path: irg/addg/gmi/ldg/stg/subp/
; tagp/settag/settag.zero/stgp.  No dedicated VM opcode.  Requires an
; explicit function "target-features" enabling exact +mte (last +mte/-mte
; token wins; +mte2 does not count).  AS0 pointers; tagp i64 ImmArg stays
; a CallDescriptor ImmediateArgument (never a VReg).  addg 0..15 and
; settag size (multiple of 16) also stay ImmediateArguments so AArch64
; isel still sees ConstantInt after re-emit.  irg.sp is stack-only and
; stays rejected.  Missing/disabled +mte reports "unsupported target
; feature"; wrong shape / irg.sp / dynamic tagp ImmArg report unsupported
; call.  Command-line -mattr is never used for eligibility.
;
; Host x86_64 cannot select MTE.  No lli.  FileCheck + AArch64 llc
; -mattr=+mte on the live main-reachable subset (internalize + globaldce).
; A dynamic tagp ImmArg cannot appear under -verify-each; a separate
; -disable-verify probe rewrites the legal tagp immediate.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.ll -o %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+mte -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.ll -o %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+mte -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: sed -e 's/call ptr @llvm.aarch64.tagp.p0(ptr %r3, ptr %r0, i64 2)/call ptr @llvm.aarch64.tagp.p0(ptr %r3, ptr %r0, i64 %excl)/' %s > %t.dyn.ll
; RUN: opt -S -disable-verify -aesSeed=97 -passes='default<O0>' %t.dyn.ll -o %t.dyn.out.ll 2>%t.dyn.err
; RUN: FileCheck %s --check-prefix=DYN < %t.dyn.err

target triple = "aarch64-unknown-linux-gnu"

@sink_p = global ptr null
@sink_i = global i64 0
@as1g = addrspace(1) global i8 0

declare void @hikari_vmp()
declare ptr @llvm.aarch64.irg(ptr, i64)
declare ptr @llvm.aarch64.addg(ptr, i64)
declare i64 @llvm.aarch64.gmi(ptr, i64)
declare ptr @llvm.aarch64.ldg(ptr, ptr)
declare void @llvm.aarch64.stg(ptr, ptr)
declare i64 @llvm.aarch64.subp(ptr, ptr)
declare ptr @llvm.aarch64.tagp.p0(ptr, ptr, i64)
declare void @llvm.aarch64.settag(ptr, i64)
declare void @llvm.aarch64.settag.zero(ptr, i64)
declare void @llvm.aarch64.stgp(ptr, i64, i64)
declare ptr @llvm.aarch64.irg.sp(i64)
declare ptr addrspace(1) @llvm.aarch64.tagp.p1(ptr addrspace(1), ptr, i64)

define i64 @reference_mte(ptr %p, ptr %q, i64 %excl) "target-features"="+mte" {
entry:
  %r0 = call ptr @llvm.aarch64.irg(ptr %p, i64 %excl)
  %r1 = call ptr @llvm.aarch64.addg(ptr %r0, i64 7)
  %r2 = call i64 @llvm.aarch64.gmi(ptr %r1, i64 %excl)
  %r3 = call ptr @llvm.aarch64.ldg(ptr %r1, ptr %q)
  call void @llvm.aarch64.stg(ptr %r3, ptr %q)
  %r4 = call i64 @llvm.aarch64.subp(ptr %r3, ptr %q)
  %r5 = call ptr @llvm.aarch64.tagp.p0(ptr %r3, ptr %r0, i64 2)
  call void @llvm.aarch64.settag(ptr %r5, i64 16)
  call void @llvm.aarch64.settag.zero(ptr %r5, i64 16)
  call void @llvm.aarch64.stgp(ptr %r5, i64 %r2, i64 %r4)
  %out = xor i64 %r2, %r4
  store volatile ptr %r5, ptr @sink_p
  store volatile i64 %out, ptr @sink_i
  ret i64 %out
}

define i64 @protected_mte(ptr %p, ptr %q, i64 %excl) noinline optnone "target-features"="+mte" {
entry:
  call void @hikari_vmp()
  %r0 = call ptr @llvm.aarch64.irg(ptr %p, i64 %excl)
  %r1 = call ptr @llvm.aarch64.addg(ptr %r0, i64 7)
  %r2 = call i64 @llvm.aarch64.gmi(ptr %r1, i64 %excl)
  %r3 = call ptr @llvm.aarch64.ldg(ptr %r1, ptr %q)
  call void @llvm.aarch64.stg(ptr %r3, ptr %q)
  %r4 = call i64 @llvm.aarch64.subp(ptr %r3, ptr %q)
  %r5 = call ptr @llvm.aarch64.tagp.p0(ptr %r3, ptr %r0, i64 2)
  call void @llvm.aarch64.settag(ptr %r5, i64 16)
  call void @llvm.aarch64.settag.zero(ptr %r5, i64 16)
  call void @llvm.aarch64.stgp(ptr %r5, i64 %r2, i64 %r4)
  %out = xor i64 %r2, %r4
  store volatile ptr %r5, ptr @sink_p
  store volatile i64 %out, ptr @sink_i
  ret i64 %out
}

define i64 @protected_mte_multi(ptr %p, i64 %excl) noinline optnone "target-features"="+neon,+mte,+fp-armv8" {
entry:
  call void @hikari_vmp()
  %r = call ptr @llvm.aarch64.irg(ptr %p, i64 %excl)
  store volatile ptr %r, ptr @sink_p
  ret i64 %excl
}

define i64 @unsupported_mte_disabled(ptr %p, i64 %excl) noinline optnone "target-features"="+mte,-mte" {
entry:
  call void @hikari_vmp()
  %r = call ptr @llvm.aarch64.irg(ptr %p, i64 %excl)
  store volatile ptr %r, ptr @sink_p
  ret i64 %excl
}

define i64 @unsupported_mte_no_target_features(ptr %p, i64 %excl) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call ptr @llvm.aarch64.irg(ptr %p, i64 %excl)
  store volatile ptr %r, ptr @sink_p
  ret i64 %excl
}

define i64 @unsupported_mte2_only(ptr %p, i64 %excl) noinline optnone "target-features"="+mte2" {
entry:
  call void @hikari_vmp()
  %r = call ptr @llvm.aarch64.irg(ptr %p, i64 %excl)
  store volatile ptr %r, ptr @sink_p
  ret i64 %excl
}

define i64 @unsupported_tagp_as1() noinline optnone "target-features"="+mte" {
entry:
  call void @hikari_vmp()
  %t = call ptr addrspace(1) @llvm.aarch64.tagp.p1(ptr addrspace(1) @as1g, ptr @sink_p, i64 1)
  ret i64 0
}

define ptr @unsupported_irg_sp(i64 %excl) noinline optnone "target-features"="+mte" {
entry:
  call void @hikari_vmp()
  %t = call ptr @llvm.aarch64.irg.sp(i64 %excl)
  ret ptr %t
}

define i64 @main(ptr %p, ptr %q, i64 %excl) {
entry:
  %e0 = call i64 @reference_mte(ptr %p, ptr %q, i64 %excl)
  %a0 = call i64 @protected_mte(ptr %p, ptr %q, i64 %excl)
  %b0 = call i64 @protected_mte_multi(ptr %p, i64 %excl)
  %x = xor i64 %e0, %a0
  %y = xor i64 %x, %b0
  ret i64 %y
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_mte_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_mte_no_target_features: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_mte2_only: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_tagp_as1: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_irg_sp: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_mte:
; SKIP-NOT: Skipping VMP on protected_mte_multi:

; DYN: Skipping VMP on protected_mte: unsupported call instruction

; VIRT: define i64 @protected_mte({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: call ptr @llvm.aarch64.irg(
; VIRT-DAG: call ptr @llvm.aarch64.addg({{.*}}, i64 7)
; VIRT-DAG: call i64 @llvm.aarch64.gmi(
; VIRT-DAG: call ptr @llvm.aarch64.ldg(
; VIRT-DAG: call void @llvm.aarch64.stg(
; VIRT-DAG: call i64 @llvm.aarch64.subp(
; VIRT-DAG: call ptr @llvm.aarch64.tagp.{{.*}}({{.*}}, i64 2)
; VIRT-DAG: call void @llvm.aarch64.settag({{.*}}, i64 16)
; VIRT-DAG: call void @llvm.aarch64.settag.zero({{.*}}, i64 16)
; VIRT-DAG: call void @llvm.aarch64.stgp(
; VIRT: define i64 @protected_mte_multi({{.*}} #[[PROT_MULTI:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call ptr @llvm.aarch64.irg(
; VIRT: define i64 @unsupported_mte_disabled({{.*}} #[[UNSUP_DIS:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call ptr @llvm.aarch64.irg(
; VIRT: define i64 @unsupported_mte_no_target_features({{.*}} #[[UNSUP_NO:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call ptr @llvm.aarch64.irg(
; VIRT: define i64 @unsupported_mte2_only({{.*}} #[[UNSUP_MTE2:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call ptr @llvm.aarch64.irg(
; VIRT: define {{.*}}@unsupported_tagp_as1({{.*}} #[[UNSUP_AS1:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call {{.*}}@llvm.aarch64.tagp.
; VIRT: define ptr @unsupported_irg_sp({{.*}} #[[UNSUP_AS1]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call ptr @llvm.aarch64.irg.sp(
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[PROT_MULTI]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP_DIS]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT: attributes #[[UNSUP_NO]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT: attributes #[[UNSUP_MTE2]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT: attributes #[[UNSUP_AS1]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
