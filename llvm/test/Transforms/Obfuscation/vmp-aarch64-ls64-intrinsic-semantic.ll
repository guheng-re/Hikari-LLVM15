; AArch64 LS64 via VMP: st64b (void ptr AS0 + 8*i64), st64bv/st64bv0
; (i64 ptr AS0 + 8*i64) on CallDescriptor; ld64b {i64 x8} split into eight
; integer VRegs from single-index extractvalue 0..7 only.  No general
; aggregate VReg.  Requires exact function "target-features" +ls64 (last
; +ls64/-ls64 wins; +ls642 does not count).  Missing/disabled/+ls642 is
; "unsupported target feature".  Non-AS0, musttail/bundle/noreturn/
; returns_twice, and non-extract aggregate uses stay rejected.  Failure
; is late-eligibility: original body plus hikari.vmp.selected, no
; bytecode globals.  Command-line -mattr is never used for eligibility.
;
; Host x86_64 cannot select LS64.  No lli.  FileCheck + AArch64 llc
; -mattr=+ls64 assembly on the live main-reachable subset must contain
; ld64b/st64b/st64bv/st64bv0 inside the virtualized handlers.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.ll -o %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+ls64 %t.o0.live.ll -o - | FileCheck %s --check-prefix=ASM
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.ll -o %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+ls64 %t.o2.live.ll -o - | FileCheck %s --check-prefix=ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll

target triple = "aarch64-unknown-linux-gnu"

@sink = global i64 0

declare void @hikari_vmp()
declare { i64, i64, i64, i64, i64, i64, i64, i64 } @llvm.aarch64.ld64b(ptr)
declare void @llvm.aarch64.st64b(ptr, i64, i64, i64, i64, i64, i64, i64, i64)
declare i64 @llvm.aarch64.st64bv(ptr, i64, i64, i64, i64, i64, i64, i64, i64)
declare i64 @llvm.aarch64.st64bv0(ptr, i64, i64, i64, i64, i64, i64, i64, i64)

define i64 @reference_ld64b(ptr %p) "target-features"="+ls64" {
entry:
  %v = call { i64, i64, i64, i64, i64, i64, i64, i64 } @llvm.aarch64.ld64b(ptr %p)
  %e0 = extractvalue { i64, i64, i64, i64, i64, i64, i64, i64 } %v, 0
  %e7 = extractvalue { i64, i64, i64, i64, i64, i64, i64, i64 } %v, 7
  %s = xor i64 %e0, %e7
  store volatile i64 %s, ptr @sink
  ret i64 %s
}

define i64 @protected_ld64b(ptr %p) noinline optnone "target-features"="+ls64" {
entry:
  call void @hikari_vmp()
  %v = call { i64, i64, i64, i64, i64, i64, i64, i64 } @llvm.aarch64.ld64b(ptr %p)
  %e0 = extractvalue { i64, i64, i64, i64, i64, i64, i64, i64 } %v, 0
  %e1 = extractvalue { i64, i64, i64, i64, i64, i64, i64, i64 } %v, 1
  %e2 = extractvalue { i64, i64, i64, i64, i64, i64, i64, i64 } %v, 2
  %e3 = extractvalue { i64, i64, i64, i64, i64, i64, i64, i64 } %v, 3
  %e4 = extractvalue { i64, i64, i64, i64, i64, i64, i64, i64 } %v, 4
  %e5 = extractvalue { i64, i64, i64, i64, i64, i64, i64, i64 } %v, 5
  %e6 = extractvalue { i64, i64, i64, i64, i64, i64, i64, i64 } %v, 6
  %e7 = extractvalue { i64, i64, i64, i64, i64, i64, i64, i64 } %v, 7
  %a = add i64 %e0, %e1
  %b = add i64 %e2, %e3
  %c = add i64 %e4, %e5
  %d = add i64 %e6, %e7
  %ab = xor i64 %a, %b
  %cd = xor i64 %c, %d
  %s = xor i64 %ab, %cd
  store volatile i64 %s, ptr @sink
  ret i64 %s
}

define void @protected_st64b(ptr %p, i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g, i64 %h) noinline optnone "target-features"="+ls64" {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.st64b(ptr %p, i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g, i64 %h)
  ret void
}

define i64 @protected_st64bv(ptr %p, i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g, i64 %h) noinline optnone "target-features"="+ls64" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.aarch64.st64bv(ptr %p, i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g, i64 %h)
  store volatile i64 %r, ptr @sink
  ret i64 %r
}

define i64 @protected_st64bv0(ptr %p, i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g, i64 %h) noinline optnone "target-features"="+ls64" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.aarch64.st64bv0(ptr %p, i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g, i64 %h)
  store volatile i64 %r, ptr @sink
  ret i64 %r
}

define i64 @protected_ls64_multi(ptr %p, i64 %a) noinline optnone "target-features"="+neon,+ls64,+fp-armv8" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.aarch64.st64bv(ptr %p, i64 %a, i64 %a, i64 %a, i64 %a, i64 %a, i64 %a, i64 %a, i64 %a)
  ret i64 %r
}

define i64 @unsupported_ls64_disabled(ptr %p) noinline optnone "target-features"="+ls64,-ls64" {
entry:
  call void @hikari_vmp()
  %v = call { i64, i64, i64, i64, i64, i64, i64, i64 } @llvm.aarch64.ld64b(ptr %p)
  %e = extractvalue { i64, i64, i64, i64, i64, i64, i64, i64 } %v, 0
  ret i64 %e
}

define i64 @unsupported_no_target_features(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %v = call { i64, i64, i64, i64, i64, i64, i64, i64 } @llvm.aarch64.ld64b(ptr %p)
  %e = extractvalue { i64, i64, i64, i64, i64, i64, i64, i64 } %v, 0
  ret i64 %e
}

define i64 @unsupported_ls642_only(ptr %p) noinline optnone "target-features"="+ls642" {
entry:
  call void @hikari_vmp()
  %v = call { i64, i64, i64, i64, i64, i64, i64, i64 } @llvm.aarch64.ld64b(ptr %p)
  %e = extractvalue { i64, i64, i64, i64, i64, i64, i64, i64 } %v, 0
  ret i64 %e
}

define void @unsupported_st64b_musttail(ptr %p, i64 %a) noinline optnone "target-features"="+ls64" {
entry:
  call void @hikari_vmp()
  musttail call void @llvm.aarch64.st64b(ptr %p, i64 %a, i64 %a, i64 %a, i64 %a, i64 %a, i64 %a, i64 %a, i64 %a)
  ret void
}

define i64 @unsupported_st64bv_bundle(ptr %p, i64 %a) noinline optnone "target-features"="+ls64" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.aarch64.st64bv(ptr %p, i64 %a, i64 %a, i64 %a, i64 %a, i64 %a, i64 %a, i64 %a, i64 %a) [ "deopt"(i32 0) ]
  ret i64 %r
}

define i64 @unsupported_st64bv_noreturn(ptr %p, i64 %a) noinline optnone "target-features"="+ls64" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.aarch64.st64bv(ptr %p, i64 %a, i64 %a, i64 %a, i64 %a, i64 %a, i64 %a, i64 %a, i64 %a) noreturn
  ret i64 %r
}

define i64 @unsupported_st64bv_returns_twice(ptr %p, i64 %a) noinline optnone "target-features"="+ls64" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.aarch64.st64bv(ptr %p, i64 %a, i64 %a, i64 %a, i64 %a, i64 %a, i64 %a, i64 %a, i64 %a) returns_twice
  ret i64 %r
}

define void @unsupported_ld64b_aggregate_store(ptr %p, ptr %out) noinline optnone "target-features"="+ls64" {
entry:
  call void @hikari_vmp()
  %v = call { i64, i64, i64, i64, i64, i64, i64, i64 } @llvm.aarch64.ld64b(ptr %p)
  store { i64, i64, i64, i64, i64, i64, i64, i64 } %v, ptr %out
  ret void
}

define i64 @unsupported_ld64b_insertvalue(ptr %p) noinline optnone "target-features"="+ls64" {
entry:
  call void @hikari_vmp()
  %v = call { i64, i64, i64, i64, i64, i64, i64, i64 } @llvm.aarch64.ld64b(ptr %p)
  %w = insertvalue { i64, i64, i64, i64, i64, i64, i64, i64 } %v, i64 1, 0
  %e = extractvalue { i64, i64, i64, i64, i64, i64, i64, i64 } %w, 0
  ret i64 %e
}

define i64 @main(ptr %p, i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g, i64 %h) {
entry:
  %l0 = call i64 @reference_ld64b(ptr %p)
  %l1 = call i64 @protected_ld64b(ptr %p)
  call void @protected_st64b(ptr %p, i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g, i64 %h)
  %s0 = call i64 @protected_st64bv(ptr %p, i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g, i64 %h)
  %s1 = call i64 @protected_st64bv0(ptr %p, i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g, i64 %h)
  %m = call i64 @protected_ls64_multi(ptr %p, i64 %a)
  %x = xor i64 %l0, %l1
  %y = xor i64 %s0, %s1
  %z = xor i64 %x, %y
  %w = xor i64 %z, %m
  ret i64 %w
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_ls64_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_no_target_features: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_ls642_only: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_st64b_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_st64bv_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_st64bv_noreturn: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_st64bv_returns_twice: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_ld64b_aggregate_store: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_ld64b_insertvalue: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_ld64b:
; SKIP-NOT: Skipping VMP on protected_st64b:
; SKIP-NOT: Skipping VMP on protected_st64bv:
; SKIP-NOT: Skipping VMP on protected_st64bv0:
; SKIP-NOT: Skipping VMP on protected_ls64_multi:

; VIRT: define i64 @protected_ld64b({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call {{.*}}@llvm.aarch64.ld64b(
; VIRT-DAG: extractvalue {{.*}}, 0
; VIRT-DAG: extractvalue {{.*}}, 7
; VIRT: define void @protected_st64b({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.aarch64.st64b(
; VIRT: define i64 @protected_st64bv({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.aarch64.st64bv(
; VIRT: define i64 @protected_st64bv0({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.aarch64.st64bv0(
; VIRT: define i64 @protected_ls64_multi({{.*}} #[[PROT_MULTI:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.aarch64.st64bv(
; VIRT: define i64 @unsupported_ls64_disabled({{.*}} #[[UNSUP_DIS:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call {{.*}}@llvm.aarch64.ld64b(
; VIRT: define i64 @unsupported_no_target_features({{.*}} #[[UNSUP_NO:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call {{.*}}@llvm.aarch64.ld64b(
; VIRT: define i64 @unsupported_ls642_only({{.*}} #[[UNSUP_642:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call {{.*}}@llvm.aarch64.ld64b(
; VIRT: define void @unsupported_st64b_musttail({{.*}} #[[UNSUP_MT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call void @llvm.aarch64.st64b(
; VIRT: define i64 @unsupported_st64bv_bundle({{.*}} #[[UNSUP_SEL:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define i64 @unsupported_st64bv_noreturn({{.*}} #[[UNSUP_SEL]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define i64 @unsupported_st64bv_returns_twice({{.*}} #[[UNSUP_SEL]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define void @unsupported_ld64b_aggregate_store({{.*}} #[[UNSUP_SEL]] {
; VIRT-NOT: vmp.dispatch
; VIRT: store { i64, i64, i64, i64, i64, i64, i64, i64 }
; VIRT: define i64 @unsupported_ld64b_insertvalue({{.*}} #[[UNSUP_SEL]] {
; VIRT-NOT: vmp.dispatch
; VIRT: insertvalue
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[PROT_MULTI]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP_DIS]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT: attributes #[[UNSUP_NO]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT: attributes #[[UNSUP_642]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT: attributes #[[UNSUP_SEL]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUP_MT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }

; Virtualized handlers (not only native reference) must select LS64.
; ASM: protected_ld64b:
; ASM: ld64b
; ASM: protected_st64b:
; ASM: st64b x
; ASM: protected_st64bv:
; ASM: st64bv x
; ASM: protected_st64bv0:
; ASM: st64bv0
