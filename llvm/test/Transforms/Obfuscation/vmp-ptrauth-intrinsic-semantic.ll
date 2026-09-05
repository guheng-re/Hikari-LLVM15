; Generic llvm.ptrauth.sign / llvm.ptrauth.sign_generic via CallDescriptor.
; This LLVM 15 AArch64 SDAG only selects those two IDs (PAC* / PACGA).
; auth / strip / resign / blend stay rejected.  Key is i32 ImmArg 0..3
; (ASIA/ASIB/ASDA/ASDB) and stays a true constant on replay.  Value and
; discriminator are ordinary i64 VRegs.  Requires last-token function
; "target-features" +pauth; +pauth2 / missing / final -pauth report
; "unsupported target feature".  Command-line -mattr is never used for
; eligibility.  No new VM opcode.  Host cannot execute PAC; no lli.
; FileCheck + AArch64 llc on the live main-reachable subset.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.ll -o %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+pauth -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+pauth %t.o0.live.ll -o - | FileCheck %s --check-prefix=ASM
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.ll -o %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+pauth -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+pauth %t.o2.live.ll -o - | FileCheck %s --check-prefix=ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.s7.ll -o %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+pauth -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.s7.ll -o %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+pauth -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare i64 @llvm.ptrauth.sign(i64, i32, i64)
declare i64 @llvm.ptrauth.sign.generic(i64, i64)
declare i64 @llvm.ptrauth.auth(i64, i32, i64)
declare i64 @llvm.ptrauth.strip(i64, i32)
declare i64 @llvm.ptrauth.resign(i64, i32, i64, i32, i64)
declare i64 @llvm.ptrauth.blend(i64, i64)

define i64 @sink_i64(ptr %p, i64 %x) {
entry:
  ret i64 %x
}

define i64 @protected_ptrauth_sign_ia(i64 %v, i64 %d) noinline optnone "target-features"="+pauth" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.ptrauth.sign(i64 %v, i32 0, i64 %d)
  ret i64 %r
}

define i64 @protected_ptrauth_sign_ib(i64 %v, i64 %d) noinline optnone "target-features"="+pauth" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.ptrauth.sign(i64 %v, i32 1, i64 %d)
  ret i64 %r
}

define i64 @protected_ptrauth_sign_da(i64 %v, i64 %d) noinline optnone "target-features"="+pauth" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.ptrauth.sign(i64 %v, i32 2, i64 %d)
  ret i64 %r
}

define i64 @protected_ptrauth_sign_db(i64 %v, i64 %d) noinline optnone "target-features"="+pauth" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.ptrauth.sign(i64 %v, i32 3, i64 %d)
  ret i64 %r
}

define i64 @protected_ptrauth_sign_ia_zero(i64 %v) noinline optnone "target-features"="+pauth" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.ptrauth.sign(i64 %v, i32 0, i64 0)
  ret i64 %r
}

define i64 @protected_ptrauth_sign_generic(i64 %v, i64 %d) noinline optnone "target-features"="+pauth" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.ptrauth.sign.generic(i64 %v, i64 %d)
  ret i64 %r
}

define i64 @protected_ptrauth_sign_multi(i64 %v, i64 %d) noinline optnone "target-features"="+neon,+pauth,+fp-armv8" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.ptrauth.sign(i64 %v, i32 0, i64 %d)
  ret i64 %r
}


define i64 @protected_ptrauth_sign_phi(i1 %c, i64 %v, i64 %d) noinline optnone "target-features"="+pauth" {
entry:
  call void @hikari_vmp()
  br i1 %c, label %left, label %right

left:
  %l = call i64 @llvm.ptrauth.sign(i64 %v, i32 0, i64 %d)
  br label %done

right:
  %r = call i64 @llvm.ptrauth.sign(i64 %v, i32 1, i64 %d)
  br label %done

done:
  %p = phi i64 [ %l, %left ], [ %r, %right ]
  ret i64 %p
}

define i64 @protected_ptrauth_sign_loop(i64 %v, i64 %d, i32 %n) noinline optnone "target-features"="+pauth" {
entry:
  call void @hikari_vmp()
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %i2, %loop ]
  %acc = phi i64 [ %v, %entry ], [ %s, %loop ]
  %s = call i64 @llvm.ptrauth.sign(i64 %acc, i32 0, i64 %d)
  %i2 = add i32 %i, 1
  %more = icmp slt i32 %i2, %n
  br i1 %more, label %loop, label %done

done:
  ret i64 %s
}

define i64 @unsupported_ptrauth_no_features(i64 %v, i64 %d) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.ptrauth.sign(i64 %v, i32 0, i64 %d)
  ret i64 %r
}

define i64 @unsupported_ptrauth_disabled(i64 %v, i64 %d) noinline optnone "target-features"="+pauth,-pauth" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.ptrauth.sign(i64 %v, i32 0, i64 %d)
  ret i64 %r
}

define i64 @unsupported_ptrauth_pauth2(i64 %v, i64 %d) noinline optnone "target-features"="+pauth2" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.ptrauth.sign(i64 %v, i32 0, i64 %d)
  ret i64 %r
}

define i64 @unsupported_ptrauth_auth(i64 %v, i64 %d) noinline optnone "target-features"="+pauth" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.ptrauth.auth(i64 %v, i32 0, i64 %d)
  ret i64 %r
}

define i64 @unsupported_ptrauth_strip(i64 %v) noinline optnone "target-features"="+pauth" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.ptrauth.strip(i64 %v, i32 0)
  ret i64 %r
}

define i64 @unsupported_ptrauth_resign(i64 %v, i64 %d) noinline optnone "target-features"="+pauth" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.ptrauth.resign(i64 %v, i32 0, i64 %d, i32 1, i64 %d)
  ret i64 %r
}

define i64 @unsupported_ptrauth_blend(i64 %a, i64 %i) noinline optnone "target-features"="+pauth" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.ptrauth.blend(i64 %a, i64 %i)
  ret i64 %r
}

define i64 @unsupported_ptrauth_bad_key(i64 %v, i64 %d) noinline optnone "target-features"="+pauth" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.ptrauth.sign(i64 %v, i32 4, i64 %d)
  ret i64 %r
}

define i64 @unsupported_ptrauth_musttail(ptr %p, i64 %v) noinline optnone "target-features"="+pauth" {
entry:
  call void @hikari_vmp()
  %s = call i64 @llvm.ptrauth.sign(i64 %v, i32 0, i64 0)
  %r = musttail call i64 @sink_i64(ptr %p, i64 %s)
  ret i64 %r
}

define i64 @unsupported_ptrauth_poison(i64 %d) noinline optnone "target-features"="+pauth" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.ptrauth.sign(i64 poison, i32 0, i64 %d)
  ret i64 %r
}

define i64 @unsupported_ptrauth_bundle(i64 %v, i64 %d) noinline optnone "target-features"="+pauth" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.ptrauth.sign(i64 %v, i32 0, i64 %d) [ "deopt"() ]
  ret i64 %r
}

define i32 @main() {
entry:
  %a0 = call i64 @protected_ptrauth_sign_ia(i64 1, i64 2)
  %a1 = call i64 @protected_ptrauth_sign_ib(i64 1, i64 2)
  %a2 = call i64 @protected_ptrauth_sign_da(i64 1, i64 2)
  %a3 = call i64 @protected_ptrauth_sign_db(i64 1, i64 2)
  %a4 = call i64 @protected_ptrauth_sign_ia_zero(i64 1)
  %a5 = call i64 @protected_ptrauth_sign_generic(i64 1, i64 2)
  %a6 = call i64 @protected_ptrauth_sign_multi(i64 1, i64 2)
  %a8 = call i64 @protected_ptrauth_sign_phi(i1 true, i64 1, i64 2)
  %a9 = call i64 @protected_ptrauth_sign_loop(i64 1, i64 2, i32 2)
  %mix0 = xor i64 %a0, %a1
  %mix1 = xor i64 %a2, %a3
  %mix2 = xor i64 %a4, %a5
  %mix3 = xor i64 %a6, %a6
  %mix4 = xor i64 %a8, %a9
  %t0 = xor i64 %mix0, %mix1
  %t1 = xor i64 %mix2, %mix3
  %t2 = xor i64 %t0, %t1
  %keep = xor i64 %t2, %mix4
  %trunc = trunc i64 %keep to i32
  %code = and i32 %trunc, 0
  ret i32 %code
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_ptrauth_no_features: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_ptrauth_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_ptrauth_pauth2: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_ptrauth_auth: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_ptrauth_strip: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_ptrauth_resign: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_ptrauth_blend: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_ptrauth_bad_key: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_ptrauth_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_ptrauth_poison: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_ptrauth_bundle: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_ptrauth_sign_ia:
; SKIP-NOT: Skipping VMP on protected_ptrauth_sign_ib:
; SKIP-NOT: Skipping VMP on protected_ptrauth_sign_da:
; SKIP-NOT: Skipping VMP on protected_ptrauth_sign_db:
; SKIP-NOT: Skipping VMP on protected_ptrauth_sign_ia_zero:
; SKIP-NOT: Skipping VMP on protected_ptrauth_sign_generic:
; SKIP-NOT: Skipping VMP on protected_ptrauth_sign_multi:
; SKIP-NOT: Skipping VMP on protected_ptrauth_sign_phi:
; SKIP-NOT: Skipping VMP on protected_ptrauth_sign_loop:

; VIRT: define i64 @protected_ptrauth_sign_ia({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.ptrauth.sign(i64 {{.*}}, i32 0, i64 {{.*}})
; VIRT: define i64 @protected_ptrauth_sign_ib({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.ptrauth.sign(i64 {{.*}}, i32 1, i64 {{.*}})
; VIRT: define i64 @protected_ptrauth_sign_da({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.ptrauth.sign(i64 {{.*}}, i32 2, i64 {{.*}})
; VIRT: define i64 @protected_ptrauth_sign_db({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.ptrauth.sign(i64 {{.*}}, i32 3, i64 {{.*}})
; VIRT: define i64 @protected_ptrauth_sign_ia_zero({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.ptrauth.sign(i64 {{.*}}, i32 0, i64 {{.*}})
; VIRT: define i64 @protected_ptrauth_sign_generic({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.ptrauth.sign.generic(i64 {{.*}}, i64 {{.*}})
; VIRT: define i64 @protected_ptrauth_sign_multi({{.*}} #[[PROT_MULTI:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.ptrauth.sign(i64 {{.*}}, i32 0, i64 {{.*}})
; VIRT: define i64 @protected_ptrauth_sign_phi({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.ptrauth.sign(i64 {{.*}}, i32 0, i64 {{.*}})
; VIRT: define i64 @protected_ptrauth_sign_loop({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.ptrauth.sign(i64 {{.*}}, i32 0, i64 {{.*}})
; VIRT: define i64 @unsupported_ptrauth_no_features({{.*}} #[[UNSUP_NO:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define i64 @unsupported_ptrauth_disabled({{.*}} #[[UNSUP_DIS:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define i64 @unsupported_ptrauth_pauth2({{.*}} #[[UNSUP_P2:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define i64 @unsupported_ptrauth_auth({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define i64 @unsupported_ptrauth_strip({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define i64 @unsupported_ptrauth_resign({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define i64 @unsupported_ptrauth_blend({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define i64 @unsupported_ptrauth_bad_key({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define i64 @unsupported_ptrauth_musttail({{.*}} #[[UNSUP_MT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call i64 @sink_i64(
; VIRT: define i64 @unsupported_ptrauth_poison({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define i64 @unsupported_ptrauth_bundle({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT: attributes #[[PROT_MULTI]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"
; VIRT-NOT: attributes #[[UNSUP_MT]] = { {{.*}}"hikari.vmp.virtualized"

; ASM: pacia
; ASM: pacib
; ASM: pacda
; ASM: pacdb
; ASM: pacga

; AARCH64: Arch: aarch64
