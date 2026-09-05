; AArch64 scalar builtins via VMP:
;   i32 @llvm.aarch64.fjcvtzs(double) — CallDescriptor, double float VReg
;     to i32 integer VReg.  Requires exact function "target-features"
;     +jsconv (last +jsconv/-jsconv wins; +jsconv2 does not count).
;     Missing / final -jsconv / +jsconv2 is "unsupported target feature"
;     and must not receive hikari.vmp.virtualized.  Command-line -mattr
;     is never used for eligibility.
;   void @llvm.aarch64.break(i32 ImmArg 0..65535) — dedicated terminating
;     opcode: re-emits break then unreachable, no PC advance, not a generic
;     noreturn Call.  No feature gate.  Dynamic / OOR / musttail / bundle /
;     returns_twice skip with the original body plus hikari.vmp.selected
;     (no bytecode).
; A dynamic break ImmArg cannot appear under -verify-each; a separate
; -disable-verify probe rewrites the legal immediate.
;
; Host x86_64 cannot select these.  No lli.  llc AArch64 on the live
; main-reachable subset: fjcvtzs and brk in the virtualized handlers.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.ll -o %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+jsconv %t.o0.live.ll -o - | FileCheck %s --check-prefix=ASM
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.ll -o %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+jsconv %t.o2.live.ll -o - | FileCheck %s --check-prefix=ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: sed -e 's/call void @llvm.aarch64.break(i32 42)/call void @llvm.aarch64.break(i32 %dyn)/' %s > %t.dyn.ll
; RUN: opt -S -disable-verify -aesSeed=97 -passes='default<O0>' %t.dyn.ll -o %t.dyn.out.ll 2>%t.dyn.err
; RUN: FileCheck %s --check-prefix=DYN < %t.dyn.err

target triple = "aarch64-unknown-linux-gnu"

@sink = global i32 0

declare void @hikari_vmp()
declare i32 @llvm.aarch64.fjcvtzs(double)
declare void @llvm.aarch64.break(i32 immarg)

define i32 @reference_fjcvtzs(double %d) "target-features"="+jsconv" {
entry:
  %r = call i32 @llvm.aarch64.fjcvtzs(double %d)
  store volatile i32 %r, ptr @sink
  ret i32 %r
}

define i32 @protected_fjcvtzs(double %d) noinline optnone "target-features"="+jsconv" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.fjcvtzs(double %d)
  store volatile i32 %r, ptr @sink
  ret i32 %r
}

define void @protected_break(i32 %dyn) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.break(i32 42)
  unreachable
}

define i32 @unsupported_fjcvtzs_no_target_features(double %d) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.fjcvtzs(double %d)
  ret i32 %r
}

define i32 @unsupported_fjcvtzs_jsconv_disabled(double %d) noinline optnone "target-features"="+jsconv,-jsconv" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.fjcvtzs(double %d)
  ret i32 %r
}

define i32 @unsupported_fjcvtzs_jsconv2_only(double %d) noinline optnone "target-features"="+jsconv2" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.fjcvtzs(double %d)
  ret i32 %r
}

define i32 @unsupported_fjcvtzs_musttail(double %d) noinline optnone "target-features"="+jsconv" {
entry:
  call void @hikari_vmp()
  %r = musttail call i32 @llvm.aarch64.fjcvtzs(double %d)
  ret i32 %r
}

define i32 @unsupported_fjcvtzs_bundle(double %d) noinline optnone "target-features"="+jsconv" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.fjcvtzs(double %d) [ "deopt"(i32 0) ]
  ret i32 %r
}

define void @unsupported_break_oor() noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.break(i32 65536)
  unreachable
}

define void @unsupported_break_musttail() noinline optnone {
entry:
  call void @hikari_vmp()
  musttail call void @llvm.aarch64.break(i32 2)
  ret void
}

define void @unsupported_break_bundle() noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.break(i32 2) [ "deopt"(i32 0) ]
  unreachable
}

define void @unsupported_break_returns_twice() noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.break(i32 2) returns_twice
  unreachable
}

define i32 @main(double %d) {
entry:
  %e = call i32 @reference_fjcvtzs(double %d)
  %a = call i32 @protected_fjcvtzs(double %d)
  call void @protected_break(i32 0)
  %x = xor i32 %e, %a
  ret i32 %x
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_fjcvtzs_no_target_features: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_fjcvtzs_jsconv_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_fjcvtzs_jsconv2_only: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_fjcvtzs_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_fjcvtzs_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_break_oor: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_break_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_break_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_break_returns_twice: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_fjcvtzs:
; SKIP-NOT: Skipping VMP on protected_break:

; DYN: Skipping VMP on protected_break: unsupported call instruction

; VIRT: define i32 @protected_fjcvtzs({{.*}} #[[PROT_FJC:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.fjcvtzs(
; VIRT: define void @protected_break({{.*}} #[[PROT_BRK:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.aarch64.break(i32 42)
; VIRT-NOT: call void @llvm.aarch64.break(i32 %
; VIRT: define i32 @unsupported_fjcvtzs_no_target_features({{.*}} #[[UNSUP_NO:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call i32 @llvm.aarch64.fjcvtzs(
; VIRT: define i32 @unsupported_fjcvtzs_jsconv_disabled({{.*}} #[[UNSUP_DIS:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call i32 @llvm.aarch64.fjcvtzs(
; VIRT: define i32 @unsupported_fjcvtzs_jsconv2_only({{.*}} #[[UNSUP_J2:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call i32 @llvm.aarch64.fjcvtzs(
; VIRT: define i32 @unsupported_fjcvtzs_musttail({{.*}} #[[UNSUP_MT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call i32 @llvm.aarch64.fjcvtzs(
; VIRT: define i32 @unsupported_fjcvtzs_bundle({{.*}} #[[UNSUP_SELJ:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define void @unsupported_break_oor({{.*}} #[[UNSUP_NO]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call void @llvm.aarch64.break(i32 65536)
; VIRT: define void @unsupported_break_musttail({{.*}} #[[UNSUP_MTB:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define void @unsupported_break_bundle({{.*}} #[[UNSUP_NO]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define void @unsupported_break_returns_twice({{.*}} #[[UNSUP_NO]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT_FJC]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[PROT_BRK]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP_NO]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUP_NO]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT: attributes #[[UNSUP_DIS]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUP_DIS]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT: attributes #[[UNSUP_J2]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUP_J2]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT: attributes #[[UNSUP_SELJ]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUP_SELJ]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_MT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }

; Virtualized handlers: fjcvtzs and brk (not only the native reference).
; ASM: protected_fjcvtzs:
; ASM: fjcvtzs
; ASM: protected_break:
; ASM: brk
