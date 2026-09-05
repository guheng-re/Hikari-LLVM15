; AArch64 scalar system status / RNG via VMP.
; get.fpcr i64() and set.fpcr void(i64) use CallDescriptor (no feature gate).
; rndr/rndrrs {i64,i1} split into i64/i1 VRegs from single-index extractvalue
; 0 and 1 (at most one each); no general aggregate VReg.  rndr/rndrrs require
; exact function "target-features" +rand (last +rand/-rand wins; +rand2 does
; not count).  Missing/disabled/+rand2 is "unsupported target feature".
; musttail/bundle/noreturn/returns_twice/complex ABI and unknown/duplicate
; aggregate uses skip with the original body plus hikari.vmp.selected
; (no bytecode table).  Command-line -mattr is never used for eligibility.
;
; Host x86_64 cannot select these.  No lli.  llc AArch64 on the live
; main-reachable subset: mrs/msr FPCR for get/set_fpcr; RNDR/RNDRRS
; (selected mrs forms) in the virtualized rndr/rndrrs handlers.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.ll -o %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+rand %t.o0.live.ll -o - | FileCheck %s --check-prefix=ASM
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.ll -o %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+rand %t.o2.live.ll -o - | FileCheck %s --check-prefix=ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll

target triple = "aarch64-unknown-linux-gnu"

@sink = global i64 0

declare void @hikari_vmp()
declare i64 @llvm.aarch64.get.fpcr()
declare void @llvm.aarch64.set.fpcr(i64)
declare { i64, i1 } @llvm.aarch64.rndr()
declare { i64, i1 } @llvm.aarch64.rndrrs()

define i64 @reference_get_fpcr() {
entry:
  %r = call i64 @llvm.aarch64.get.fpcr()
  store volatile i64 %r, ptr @sink
  ret i64 %r
}

define i64 @protected_get_fpcr() noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.aarch64.get.fpcr()
  store volatile i64 %r, ptr @sink
  ret i64 %r
}

define void @protected_set_fpcr(i64 %v) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.set.fpcr(i64 %v)
  ret void
}

define i64 @protected_rndr() noinline optnone "target-features"="+rand" {
entry:
  call void @hikari_vmp()
  %v = call { i64, i1 } @llvm.aarch64.rndr()
  %bits = extractvalue { i64, i1 } %v, 0
  %ok = extractvalue { i64, i1 } %v, 1
  %okz = zext i1 %ok to i64
  %s = xor i64 %bits, %okz
  store volatile i64 %s, ptr @sink
  ret i64 %s
}

define i64 @protected_rndrrs() noinline optnone "target-features"="+rand" {
entry:
  call void @hikari_vmp()
  %v = call { i64, i1 } @llvm.aarch64.rndrrs()
  %bits = extractvalue { i64, i1 } %v, 0
  %ok = extractvalue { i64, i1 } %v, 1
  %okz = zext i1 %ok to i64
  %s = xor i64 %bits, %okz
  store volatile i64 %s, ptr @sink
  ret i64 %s
}

define i64 @protected_rndr_multi() noinline optnone "target-features"="+neon,+rand,+fp-armv8" {
entry:
  call void @hikari_vmp()
  %v = call { i64, i1 } @llvm.aarch64.rndr()
  %bits = extractvalue { i64, i1 } %v, 0
  ret i64 %bits
}

define i64 @unsupported_rand_disabled() noinline optnone "target-features"="+rand,-rand" {
entry:
  call void @hikari_vmp()
  %v = call { i64, i1 } @llvm.aarch64.rndr()
  %e = extractvalue { i64, i1 } %v, 0
  ret i64 %e
}

define i64 @unsupported_no_target_features() noinline optnone {
entry:
  call void @hikari_vmp()
  %v = call { i64, i1 } @llvm.aarch64.rndr()
  %e = extractvalue { i64, i1 } %v, 0
  ret i64 %e
}

define i64 @unsupported_rand2_only() noinline optnone "target-features"="+rand2" {
entry:
  call void @hikari_vmp()
  %v = call { i64, i1 } @llvm.aarch64.rndr()
  %e = extractvalue { i64, i1 } %v, 0
  ret i64 %e
}

define i64 @unsupported_get_fpcr_musttail() noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call i64 @llvm.aarch64.get.fpcr()
  ret i64 %r
}

define void @unsupported_set_fpcr_bundle(i64 %v) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.set.fpcr(i64 %v) [ "deopt"(i32 0) ]
  ret void
}

define i64 @unsupported_rndr_noreturn() noinline optnone "target-features"="+rand" {
entry:
  call void @hikari_vmp()
  %v = call { i64, i1 } @llvm.aarch64.rndr() noreturn
  %e = extractvalue { i64, i1 } %v, 0
  ret i64 %e
}

define i64 @unsupported_rndrrs_returns_twice() noinline optnone "target-features"="+rand" {
entry:
  call void @hikari_vmp()
  %v = call { i64, i1 } @llvm.aarch64.rndrrs() returns_twice
  %e = extractvalue { i64, i1 } %v, 0
  ret i64 %e
}

define void @unsupported_rndr_aggregate_store(ptr %out) noinline optnone "target-features"="+rand" {
entry:
  call void @hikari_vmp()
  %v = call { i64, i1 } @llvm.aarch64.rndr()
  store { i64, i1 } %v, ptr %out
  ret void
}

define i64 @unsupported_rndr_dup_extract() noinline optnone "target-features"="+rand" {
entry:
  call void @hikari_vmp()
  %v = call { i64, i1 } @llvm.aarch64.rndr()
  %a = extractvalue { i64, i1 } %v, 0
  %b = extractvalue { i64, i1 } %v, 0
  %s = xor i64 %a, %b
  ret i64 %s
}

define i64 @unsupported_rndr_insertvalue() noinline optnone "target-features"="+rand" {
entry:
  call void @hikari_vmp()
  %v = call { i64, i1 } @llvm.aarch64.rndr()
  %w = insertvalue { i64, i1 } %v, i64 1, 0
  %e = extractvalue { i64, i1 } %w, 0
  ret i64 %e
}

define i64 @main(i64 %v) {
entry:
  %g0 = call i64 @reference_get_fpcr()
  %g1 = call i64 @protected_get_fpcr()
  call void @protected_set_fpcr(i64 %v)
  %r0 = call i64 @protected_rndr()
  %r1 = call i64 @protected_rndrrs()
  %r2 = call i64 @protected_rndr_multi()
  %x = xor i64 %g0, %g1
  %y = xor i64 %r0, %r1
  %z = xor i64 %x, %y
  %w = xor i64 %z, %r2
  ret i64 %w
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_rand_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_no_target_features: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_rand2_only: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_get_fpcr_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_set_fpcr_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_rndr_noreturn: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_rndrrs_returns_twice: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_rndr_aggregate_store: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_rndr_dup_extract: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_rndr_insertvalue: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_get_fpcr:
; SKIP-NOT: Skipping VMP on protected_set_fpcr:
; SKIP-NOT: Skipping VMP on protected_rndr:
; SKIP-NOT: Skipping VMP on protected_rndrrs:
; SKIP-NOT: Skipping VMP on protected_rndr_multi:

; VIRT: define i64 @protected_get_fpcr({{.*}} #[[PROT_FP:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.aarch64.get.fpcr(
; VIRT: define void @protected_set_fpcr({{.*}} #[[PROT_FP]] {
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.aarch64.set.fpcr(
; VIRT: define i64 @protected_rndr({{.*}} #[[PROT_RAND:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call {{.*}}@llvm.aarch64.rndr(
; VIRT-DAG: extractvalue {{.*}}, 0
; VIRT-DAG: extractvalue {{.*}}, 1
; VIRT: define i64 @protected_rndrrs({{.*}} #[[PROT_RAND]] {
; VIRT: vmp.dispatch:
; VIRT: call {{.*}}@llvm.aarch64.rndrrs(
; VIRT: define i64 @protected_rndr_multi({{.*}} #[[PROT_MULTI:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call {{.*}}@llvm.aarch64.rndr(
; VIRT: define i64 @unsupported_rand_disabled({{.*}} #[[UNSUP_DIS:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define i64 @unsupported_no_target_features({{.*}} #[[UNSUP_NO:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define i64 @unsupported_rand2_only({{.*}} #[[UNSUP_R2:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define i64 @unsupported_get_fpcr_musttail({{.*}} #[[UNSUP_MT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call i64 @llvm.aarch64.get.fpcr(
; VIRT: define void @unsupported_set_fpcr_bundle({{.*}} #[[UNSUP_NO]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define i64 @unsupported_rndr_noreturn({{.*}} #[[UNSUP_SEL1:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define i64 @unsupported_rndrrs_returns_twice({{.*}} #[[UNSUP_SEL1]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define void @unsupported_rndr_aggregate_store({{.*}} #[[UNSUP_SEL1]] {
; VIRT-NOT: vmp.dispatch
; VIRT: store { i64, i1 }
; VIRT: define i64 @unsupported_rndr_dup_extract({{.*}} #[[UNSUP_SEL1]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define i64 @unsupported_rndr_insertvalue({{.*}} #[[UNSUP_SEL1]] {
; VIRT-NOT: vmp.dispatch
; VIRT: insertvalue
; VIRT: attributes #[[PROT_FP]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[PROT_RAND]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[PROT_MULTI]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP_DIS]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT: attributes #[[UNSUP_NO]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT: attributes #[[UNSUP_R2]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT: attributes #[[UNSUP_SEL1]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUP_MT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }

; Virtualized handlers: FPCR via mrs/msr; RNG via mrs RNDR/RNDRRS.
; ASM: protected_get_fpcr:
; ASM: mrs {{.*}}FPCR
; ASM: protected_set_fpcr:
; ASM: msr FPCR
; ASM: protected_rndr:
; ASM: RNDR
; ASM: protected_rndrrs:
; ASM: RNDRRS
