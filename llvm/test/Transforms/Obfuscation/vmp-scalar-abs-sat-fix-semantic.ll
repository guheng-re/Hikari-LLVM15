; Scalar integer abs / saturating add-sub-shift / fixed-point
; CallDescriptor family: llvm.abs (T(T, i1) is_int_min_poison ImmArg),
; sadd/uadd/ssub/usub/sshl/ushl.sat (T(T,T)), smul/umul/sdiv/udiv.fix
; and .fix.sat (T(T,T,i32) scale ImmArg).  Widths i1..i64 plus
; restricted scalar i128 (replayed here on i8/i32; i128 lives on
; vmp-i128-abs-minmax-sat-semantic.ll / vmp-i128-fixpoint-semantic.ll).
; C, exact non-vararg FTy, formal type equality.  Ordinary tail accepted and replayed as TCK_None.
; Replay; no new opcode.  Vectors stay on their own surface.
;
; Host lli is reliable for these scalar i8 IDs (existing abs/sat/fix
; lits).  FileCheck + host lli + AArch64 llc/readobj.  O0/O2 x 97/7.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.ll > %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.live.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.ll > %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.live.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.s7.ll > %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.s7.live.ll > %t.o0.s7.host.ll
; RUN: lli -force-interpreter %t.o0.s7.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.s7.ll > %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.s7.live.ll > %t.o2.s7.host.ll
; RUN: lli -force-interpreter %t.o2.s7.host.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare i8 @llvm.abs.i8(i8, i1 immarg)
declare i8 @llvm.sadd.sat.i8(i8, i8)
declare i8 @llvm.uadd.sat.i8(i8, i8)
declare i8 @llvm.ssub.sat.i8(i8, i8)
declare i8 @llvm.usub.sat.i8(i8, i8)
declare i8 @llvm.sshl.sat.i8(i8, i8)
declare i8 @llvm.ushl.sat.i8(i8, i8)
declare i8 @llvm.smul.fix.i8(i8, i8, i32 immarg)
declare i8 @llvm.umul.fix.i8(i8, i8, i32 immarg)
declare i8 @llvm.sdiv.fix.i8(i8, i8, i32 immarg)
declare i8 @llvm.udiv.fix.i8(i8, i8, i32 immarg)
declare i8 @llvm.smul.fix.sat.i8(i8, i8, i32 immarg)
declare i8 @llvm.umul.fix.sat.i8(i8, i8, i32 immarg)
declare i8 @llvm.sdiv.fix.sat.i8(i8, i8, i32 immarg)
declare i8 @llvm.udiv.fix.sat.i8(i8, i8, i32 immarg)
declare i32 @llvm.abs.i32(i32, i1 immarg)
declare i32 @llvm.sadd.sat.i32(i32, i32)
declare i32 @llvm.smul.fix.i32(i32, i32, i32 immarg)
declare void @ext_sret_byval(ptr sret(i32), ptr byval(i32))

; ----- positives (host lli: i8 mix) -----

define i32 @reference(i8 %x, i8 %y) noinline {
entry:
  %min = call i8 @llvm.abs.i8(i8 %x, i1 false)
  %neg = call i8 @llvm.abs.i8(i8 %y, i1 true)
  %sadd = call i8 @llvm.sadd.sat.i8(i8 %x, i8 %y)
  %ssub = call i8 @llvm.ssub.sat.i8(i8 %x, i8 %y)
  %uadd = call i8 @llvm.uadd.sat.i8(i8 %x, i8 %y)
  %usub = call i8 @llvm.usub.sat.i8(i8 %x, i8 %y)
  %sshl = call i8 @llvm.sshl.sat.i8(i8 %x, i8 2)
  %ushl = call i8 @llvm.ushl.sat.i8(i8 %x, i8 2)
  %sm0 = call i8 @llvm.smul.fix.i8(i8 %x, i8 %y, i32 0)
  %um0 = call i8 @llvm.umul.fix.i8(i8 %x, i8 %y, i32 0)
  %sm4 = call i8 @llvm.smul.fix.i8(i8 %x, i8 %y, i32 4)
  %sd0 = call i8 @llvm.sdiv.fix.i8(i8 %x, i8 %y, i32 0)
  %ud0 = call i8 @llvm.udiv.fix.i8(i8 %x, i8 %y, i32 0)
  %sms = call i8 @llvm.smul.fix.sat.i8(i8 %x, i8 %y, i32 0)
  %ums = call i8 @llvm.umul.fix.sat.i8(i8 %x, i8 %y, i32 0)
  %sds = call i8 @llvm.sdiv.fix.sat.i8(i8 %x, i8 %y, i32 0)
  %uds = call i8 @llvm.udiv.fix.sat.i8(i8 %x, i8 %y, i32 0)
  %a = xor i8 %min, %neg
  %b = xor i8 %sadd, %ssub
  %c = xor i8 %uadd, %usub
  %d = xor i8 %sshl, %ushl
  %e = xor i8 %sm0, %um0
  %f = xor i8 %sm4, %sd0
  %g = xor i8 %ud0, %sms
  %h = xor i8 %ums, %sds
  %i = xor i8 %a, %b
  %j = xor i8 %c, %d
  %k = xor i8 %e, %f
  %l = xor i8 %g, %h
  %m = xor i8 %i, %j
  %n = xor i8 %k, %l
  %o = xor i8 %m, %n
  %p = xor i8 %o, %uds
  %r = zext i8 %p to i32
  ret i32 %r
}

define i32 @protected(i8 %x, i8 %y) noinline optnone {
entry:
  call void @hikari_vmp()
  %min = call i8 @llvm.abs.i8(i8 %x, i1 false)
  %neg = call i8 @llvm.abs.i8(i8 %y, i1 true)
  %sadd = call i8 @llvm.sadd.sat.i8(i8 %x, i8 %y)
  %ssub = call i8 @llvm.ssub.sat.i8(i8 %x, i8 %y)
  %uadd = call i8 @llvm.uadd.sat.i8(i8 %x, i8 %y)
  %usub = call i8 @llvm.usub.sat.i8(i8 %x, i8 %y)
  %sshl = call i8 @llvm.sshl.sat.i8(i8 %x, i8 2)
  %ushl = call i8 @llvm.ushl.sat.i8(i8 %x, i8 2)
  %sm0 = call i8 @llvm.smul.fix.i8(i8 %x, i8 %y, i32 0)
  %um0 = call i8 @llvm.umul.fix.i8(i8 %x, i8 %y, i32 0)
  %sm4 = call i8 @llvm.smul.fix.i8(i8 %x, i8 %y, i32 4)
  %sd0 = call i8 @llvm.sdiv.fix.i8(i8 %x, i8 %y, i32 0)
  %ud0 = call i8 @llvm.udiv.fix.i8(i8 %x, i8 %y, i32 0)
  %sms = call i8 @llvm.smul.fix.sat.i8(i8 %x, i8 %y, i32 0)
  %ums = call i8 @llvm.umul.fix.sat.i8(i8 %x, i8 %y, i32 0)
  %sds = call i8 @llvm.sdiv.fix.sat.i8(i8 %x, i8 %y, i32 0)
  %uds = call i8 @llvm.udiv.fix.sat.i8(i8 %x, i8 %y, i32 0)
  %a = xor i8 %min, %neg
  %b = xor i8 %sadd, %ssub
  %c = xor i8 %uadd, %usub
  %d = xor i8 %sshl, %ushl
  %e = xor i8 %sm0, %um0
  %f = xor i8 %sm4, %sd0
  %g = xor i8 %ud0, %sms
  %h = xor i8 %ums, %sds
  %i = xor i8 %a, %b
  %j = xor i8 %c, %d
  %k = xor i8 %e, %f
  %l = xor i8 %g, %h
  %m = xor i8 %i, %j
  %n = xor i8 %k, %l
  %o = xor i8 %m, %n
  %p = xor i8 %o, %uds
  %r = zext i8 %p to i32
  ret i32 %r
}

define i32 @protected_i32(i32 %x, i32 %y) noinline optnone {
entry:
  call void @hikari_vmp()
  %a = call i32 @llvm.abs.i32(i32 %x, i1 false)
  %s = call i32 @llvm.sadd.sat.i32(i32 %x, i32 %y)
  %m = call i32 @llvm.smul.fix.i32(i32 %x, i32 %y, i32 0)
  %r = xor i32 %a, %s
  %o = xor i32 %r, %m
  ret i32 %o
}

; ----- negatives -----


define i8 @unsupported_abs_malformed(i8 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i8 @llvm.abs.i8(i8 %x, i1 false) noreturn
  ret i8 %r
}

define i8 @unsupported_abs_musttail(i8 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call i8 @llvm.abs.i8(i8 %x, i1 false)
  ret i8 %r
}

define i8 @unsupported_abs_bundle(i8 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i8 @llvm.abs.i8(i8 %x, i1 false) [ "deopt"(i32 0) ]
  ret i8 %r
}

define i8 @unsupported_abs_fastcc(i8 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc i8 @llvm.abs.i8(i8 %x, i1 false)
  ret i8 %r
}

define i8 @unsupported_abs_poison() noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i8 @llvm.abs.i8(i8 poison, i1 false)
  ret i8 %r
}

define i8 @unsupported_abs_returns_twice(i8 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i8 @llvm.abs.i8(i8 %x, i1 false) returns_twice
  ret i8 %r
}


define i8 @unsupported_sadd_fastcc(i8 %x, i8 %y) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc i8 @llvm.sadd.sat.i8(i8 %x, i8 %y)
  ret i8 %r
}

define i8 @unsupported_sadd_poison(i8 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i8 @llvm.sadd.sat.i8(i8 %x, i8 poison)
  ret i8 %r
}


define i8 @unsupported_smul_fastcc(i8 %x, i8 %y) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc i8 @llvm.smul.fix.i8(i8 %x, i8 %y, i32 0)
  ret i8 %r
}

define i8 @unsupported_smul_poison(i8 %y) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i8 @llvm.smul.fix.i8(i8 poison, i8 %y, i32 0)
  ret i8 %r
}

define i8 @unsupported_smul_malformed(i8 %x, i8 %y) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i8 @llvm.smul.fix.i8(i8 %x, i8 %y, i32 0) noreturn
  ret i8 %r
}

define void @unsupported_as1_arg(ptr addrspace(1) %unused) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i8 @llvm.abs.i8(i8 1, i1 false)
  ret void
}

define void @unsupported_sret(ptr sret(i32) %p, ptr byval(i32) %q) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @ext_sret_byval(ptr sret(i32) %p, ptr byval(i32) %q)
  ret void
}

define i32 @main() {
entry:
  %e0 = call i32 @reference(i8 48, i8 5)
  %a0 = call i32 @protected(i8 48, i8 5)
  %e1 = call i32 @reference(i8 -48, i8 5)
  %a1 = call i32 @protected(i8 -48, i8 5)
  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %e1, %a1
  %ok = and i1 %m0, %m1
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_abs_malformed: unsupported abs
; SKIP-DAG: Skipping VMP on unsupported_abs_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_abs_bundle: unsupported abs
; SKIP-DAG: Skipping VMP on unsupported_abs_fastcc: unsupported abs
; SKIP-DAG: Skipping VMP on unsupported_abs_poison: unsupported abs
; SKIP-DAG: Skipping VMP on unsupported_abs_returns_twice: unsupported abs
; SKIP-DAG: Skipping VMP on unsupported_sadd_fastcc: unsupported sadd.sat
; SKIP-DAG: Skipping VMP on unsupported_sadd_poison: unsupported sadd.sat
; SKIP-DAG: Skipping VMP on unsupported_smul_fastcc: unsupported smul.fix
; SKIP-DAG: Skipping VMP on unsupported_smul_poison: unsupported smul.fix
; SKIP-DAG: Skipping VMP on unsupported_smul_malformed: unsupported smul.fix
; SKIP-DAG: Skipping VMP on unsupported_as1_arg: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_sret: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected:
; SKIP-NOT: Skipping VMP on protected_i32:

; VIRT: define i32 @protected({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: call i8 @llvm.abs.i8({{.*}}, i1 false)
; VIRT-DAG: call i8 @llvm.abs.i8({{.*}}, i1 true)
; VIRT-DAG: call i8 @llvm.sadd.sat.i8(
; VIRT-DAG: call i8 @llvm.ssub.sat.i8(
; VIRT-DAG: call i8 @llvm.uadd.sat.i8(
; VIRT-DAG: call i8 @llvm.usub.sat.i8(
; VIRT-DAG: call i8 @llvm.sshl.sat.i8(
; VIRT-DAG: call i8 @llvm.ushl.sat.i8(
; VIRT-DAG: call i8 @llvm.smul.fix.i8({{.*}}, i32 0)
; VIRT-DAG: call i8 @llvm.umul.fix.i8({{.*}}, i32 0)
; VIRT-DAG: call i8 @llvm.smul.fix.i8({{.*}}, i32 4)
; VIRT-DAG: call i8 @llvm.sdiv.fix.i8({{.*}}, i32 0)
; VIRT-DAG: call i8 @llvm.udiv.fix.i8({{.*}}, i32 0)
; VIRT-DAG: call i8 @llvm.smul.fix.sat.i8({{.*}}, i32 0)
; VIRT-DAG: call i8 @llvm.umul.fix.sat.i8({{.*}}, i32 0)
; VIRT-DAG: call i8 @llvm.sdiv.fix.sat.i8({{.*}}, i32 0)
; VIRT-DAG: call i8 @llvm.udiv.fix.sat.i8({{.*}}, i32 0)
; VIRT: }
; VIRT: define i32 @protected_i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: call i32 @llvm.abs.i32({{.*}}, i1 false)
; VIRT-DAG: call i32 @llvm.sadd.sat.i32(
; VIRT-DAG: call i32 @llvm.smul.fix.i32({{.*}}, i32 0)
; VIRT: }
; VIRT: define {{.*}} @unsupported_abs_malformed({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_abs_musttail({{.*}} #[[UNSUPMUST:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call i8 @llvm.abs.i8(
; VIRT: define {{.*}} @unsupported_abs_bundle({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_abs_fastcc({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_abs_poison({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_abs_returns_twice({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_sadd_fastcc({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_sadd_poison({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_smul_fastcc({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_smul_poison({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_smul_malformed({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_as1_arg({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_sret({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPMUST]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPMUST]] = { {{.*}}"hikari.vmp.selected"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
