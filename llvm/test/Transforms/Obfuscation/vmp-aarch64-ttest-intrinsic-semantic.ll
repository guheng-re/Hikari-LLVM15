; AArch64 TME llvm.aarch64.ttest via normal Call path: exact i64() shape,
; i64 result VReg.  No dedicated VM opcode.  Requires an explicit function
; "target-features" enabling exact +tme (last +tme/-tme token wins; +tme2
; does not count).  Missing/disabled/+tme2 reports "unsupported target
; feature".  tstart/tcommit/tcancel change transaction boundaries; the VMP
; dispatcher would alter capacity and abort semantics, so they stay
; rejected as unsupported calls and keep the original body plus
; hikari.vmp.selected.  ttest musttail/bundle/noreturn/returns_twice stay
; rejected.  Command-line -mattr is never used for eligibility.
;
; Host x86_64 cannot select TME.  No lli.  FileCheck + AArch64 llc
; assembly on the live main-reachable subset must contain ttest inside
; the virtualized handler.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.ll -o %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+tme %t.o0.live.ll -o - | FileCheck %s --check-prefix=ASM
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.ll -o %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+tme %t.o2.live.ll -o - | FileCheck %s --check-prefix=ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll

target triple = "aarch64-unknown-linux-gnu"

@sink = global i64 0

declare void @hikari_vmp()
declare i64 @llvm.aarch64.ttest()
declare i64 @llvm.aarch64.tstart()
declare void @llvm.aarch64.tcommit()
declare void @llvm.aarch64.tcancel(i64 immarg)

define i64 @reference_ttest() "target-features"="+tme" {
entry:
  %r = call i64 @llvm.aarch64.ttest()
  store volatile i64 %r, ptr @sink
  ret i64 %r
}

define i64 @protected_ttest() noinline optnone "target-features"="+tme" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.aarch64.ttest()
  store volatile i64 %r, ptr @sink
  ret i64 %r
}

define i64 @protected_ttest_multi() noinline optnone "target-features"="+neon,+tme,+fp-armv8" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.aarch64.ttest()
  store volatile i64 %r, ptr @sink
  ret i64 %r
}

define i64 @unsupported_tme_disabled() noinline optnone "target-features"="+tme,-tme" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.aarch64.ttest()
  ret i64 %r
}

define i64 @unsupported_no_target_features() noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.aarch64.ttest()
  ret i64 %r
}

define i64 @unsupported_tme2_only() noinline optnone "target-features"="+tme2" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.aarch64.ttest()
  ret i64 %r
}

define i64 @unsupported_tstart() noinline optnone "target-features"="+tme" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.aarch64.tstart()
  ret i64 %r
}

define void @unsupported_tcommit() noinline optnone "target-features"="+tme" {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.tcommit()
  ret void
}

define void @unsupported_tcancel() noinline optnone "target-features"="+tme" {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.tcancel(i64 0)
  ret void
}

define i64 @unsupported_ttest_musttail() noinline optnone "target-features"="+tme" {
entry:
  call void @hikari_vmp()
  %r = musttail call i64 @llvm.aarch64.ttest()
  ret i64 %r
}

define i64 @unsupported_ttest_bundle() noinline optnone "target-features"="+tme" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.aarch64.ttest() [ "deopt"(i32 0) ]
  ret i64 %r
}

define i64 @unsupported_ttest_noreturn() noinline optnone "target-features"="+tme" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.aarch64.ttest() noreturn
  ret i64 %r
}

define i64 @unsupported_ttest_returns_twice() noinline optnone "target-features"="+tme" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.aarch64.ttest() returns_twice
  ret i64 %r
}

define i64 @main() {
entry:
  %e = call i64 @reference_ttest()
  %a = call i64 @protected_ttest()
  %b = call i64 @protected_ttest_multi()
  %x = xor i64 %e, %a
  %y = xor i64 %x, %b
  ret i64 %y
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_tme_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_no_target_features: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_tme2_only: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_tstart: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_tcommit: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_tcancel: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_ttest_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_ttest_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_ttest_noreturn: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_ttest_returns_twice: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_ttest:
; SKIP-NOT: Skipping VMP on protected_ttest_multi:

; VIRT: define i64 @protected_ttest({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.aarch64.ttest(
; VIRT: define i64 @protected_ttest_multi({{.*}} #[[PROT_MULTI:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.aarch64.ttest(
; VIRT: define i64 @unsupported_tme_disabled({{.*}} #[[UNSUP_DIS:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call i64 @llvm.aarch64.ttest(
; VIRT: define i64 @unsupported_no_target_features({{.*}} #[[UNSUP_NO:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call i64 @llvm.aarch64.ttest(
; VIRT: define i64 @unsupported_tme2_only({{.*}} #[[UNSUP_TME2:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call i64 @llvm.aarch64.ttest(
; VIRT: define i64 @unsupported_tstart({{.*}} #[[UNSUP_TME:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call i64 @llvm.aarch64.tstart(
; VIRT: define void @unsupported_tcommit({{.*}} #[[UNSUP_TME]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call void @llvm.aarch64.tcommit(
; VIRT: define void @unsupported_tcancel({{.*}} #[[UNSUP_TME]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call void @llvm.aarch64.tcancel(
; VIRT: define i64 @unsupported_ttest_musttail({{.*}} #[[UNSUP_MT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call i64 @llvm.aarch64.ttest(
; VIRT: define i64 @unsupported_ttest_bundle({{.*}} #[[UNSUP_TME]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call i64 @llvm.aarch64.ttest({{.*}}[ "deopt"(i32 0) ]
; VIRT: define i64 @unsupported_ttest_noreturn({{.*}} #[[UNSUP_TME]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call i64 @llvm.aarch64.ttest(
; VIRT: define i64 @unsupported_ttest_returns_twice({{.*}} #[[UNSUP_TME]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call i64 @llvm.aarch64.ttest(
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[PROT_MULTI]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP_DIS]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT: attributes #[[UNSUP_NO]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT: attributes #[[UNSUP_TME2]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT: attributes #[[UNSUP_TME]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUP_MT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }

; The virtualized handler (not only the native reference) must select ttest.
; ASM: protected_ttest:
; ASM: ttest
; ASM: protected_ttest_multi:
; ASM: ttest
