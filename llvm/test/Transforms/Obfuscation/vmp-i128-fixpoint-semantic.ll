; Restricted scalar i128 smul/umul/sdiv/udiv.fix and .fix.sat.
; Replayed through the existing CallDescriptor and i128 VReg frame.
; Scale is an i32 ImmArg kept as a true constant.  Scale 0 and a
; non-zero scale are both checked.  Divisors are non-zero.
; Host lli cannot materialize i128 sdiv.fix libcalls (__divei4).
; No lli.  No new VM opcode.  C, exact FTy, formal type equality,
; i32 ImmArg scale.  Ordinary tail accepted and replayed as TCK_None.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.ll > %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.ll > %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.s7.ll > %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.s7.ll > %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare i128 @llvm.smul.fix.i128(i128, i128, i32 immarg)
declare i128 @llvm.umul.fix.i128(i128, i128, i32 immarg)
declare i128 @llvm.sdiv.fix.i128(i128, i128, i32 immarg)
declare i128 @llvm.udiv.fix.i128(i128, i128, i32 immarg)
declare i128 @llvm.smul.fix.sat.i128(i128, i128, i32 immarg)
declare i128 @llvm.umul.fix.sat.i128(i128, i128, i32 immarg)
declare i128 @llvm.sdiv.fix.sat.i128(i128, i128, i32 immarg)
declare i128 @llvm.udiv.fix.sat.i128(i128, i128, i32 immarg)
declare void @ext_sret_byval(ptr sret(i32), ptr byval(i32))

define i32 @fold_i128(i128 %v) {
entry:
  %lo = trunc i128 %v to i32
  %hi64 = lshr i128 %v, 32
  %hi = trunc i128 %hi64 to i32
  %out = xor i32 %lo, %hi
  ret i32 %out
}

define i32 @mix8(i128 %a, i128 %b, i128 %c, i128 %d, i128 %e, i128 %f, i128 %g, i128 %h) {
entry:
  %x0 = xor i128 %a, %b
  %x1 = xor i128 %c, %d
  %x2 = xor i128 %e, %f
  %x3 = xor i128 %g, %h
  %y0 = xor i128 %x0, %x1
  %y1 = xor i128 %x2, %x3
  %z = xor i128 %y0, %y1
  %r = call i32 @fold_i128(i128 %z)
  ret i32 %r
}

define i32 @reference_fix(i128 %a, i128 %b) noinline optnone {
entry:
  %sm0 = call i128 @llvm.smul.fix.i128(i128 %a, i128 %b, i32 0)
  %um0 = call i128 @llvm.umul.fix.i128(i128 %a, i128 %b, i32 0)
  %sd0 = call i128 @llvm.sdiv.fix.i128(i128 %a, i128 %b, i32 0)
  %ud0 = call i128 @llvm.udiv.fix.i128(i128 %a, i128 %b, i32 0)
  %sms = call i128 @llvm.smul.fix.sat.i128(i128 %a, i128 %b, i32 0)
  %ums = call i128 @llvm.umul.fix.sat.i128(i128 %a, i128 %b, i32 0)
  %sds = call i128 @llvm.sdiv.fix.sat.i128(i128 %a, i128 %b, i32 0)
  %uds = call i128 @llvm.udiv.fix.sat.i128(i128 %a, i128 %b, i32 0)
  %r = call i32 @mix8(i128 %sm0, i128 %um0, i128 %sd0, i128 %ud0, i128 %sms, i128 %ums, i128 %sds, i128 %uds)
  ret i32 %r
}

define i32 @protected_fix(i128 %a, i128 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %sm0 = call i128 @llvm.smul.fix.i128(i128 %a, i128 %b, i32 0)
  %um0 = call i128 @llvm.umul.fix.i128(i128 %a, i128 %b, i32 0)
  %sd0 = call i128 @llvm.sdiv.fix.i128(i128 %a, i128 %b, i32 0)
  %ud0 = call i128 @llvm.udiv.fix.i128(i128 %a, i128 %b, i32 0)
  %sms = call i128 @llvm.smul.fix.sat.i128(i128 %a, i128 %b, i32 0)
  %ums = call i128 @llvm.umul.fix.sat.i128(i128 %a, i128 %b, i32 0)
  %sds = call i128 @llvm.sdiv.fix.sat.i128(i128 %a, i128 %b, i32 0)
  %uds = call i128 @llvm.udiv.fix.sat.i128(i128 %a, i128 %b, i32 0)
  %r = call i32 @mix8(i128 %sm0, i128 %um0, i128 %sd0, i128 %ud0, i128 %sms, i128 %ums, i128 %sds, i128 %uds)
  ret i32 %r
}

define i32 @reference_fix_scale(i128 %a, i128 %b) noinline optnone {
entry:
  %sm = call i128 @llvm.smul.fix.i128(i128 %a, i128 %b, i32 8)
  %um = call i128 @llvm.umul.fix.i128(i128 %a, i128 %b, i32 8)
  %sd = call i128 @llvm.sdiv.fix.i128(i128 %a, i128 %b, i32 8)
  %ud = call i128 @llvm.udiv.fix.i128(i128 %a, i128 %b, i32 8)
  %sms = call i128 @llvm.smul.fix.sat.i128(i128 %a, i128 %b, i32 8)
  %ums = call i128 @llvm.umul.fix.sat.i128(i128 %a, i128 %b, i32 8)
  %sds = call i128 @llvm.sdiv.fix.sat.i128(i128 %a, i128 %b, i32 8)
  %uds = call i128 @llvm.udiv.fix.sat.i128(i128 %a, i128 %b, i32 8)
  %r = call i32 @mix8(i128 %sm, i128 %um, i128 %sd, i128 %ud, i128 %sms, i128 %ums, i128 %sds, i128 %uds)
  ret i32 %r
}

define i32 @protected_fix_scale(i128 %a, i128 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %sm = call i128 @llvm.smul.fix.i128(i128 %a, i128 %b, i32 8)
  %um = call i128 @llvm.umul.fix.i128(i128 %a, i128 %b, i32 8)
  %sd = call i128 @llvm.sdiv.fix.i128(i128 %a, i128 %b, i32 8)
  %ud = call i128 @llvm.udiv.fix.i128(i128 %a, i128 %b, i32 8)
  %sms = call i128 @llvm.smul.fix.sat.i128(i128 %a, i128 %b, i32 8)
  %ums = call i128 @llvm.umul.fix.sat.i128(i128 %a, i128 %b, i32 8)
  %sds = call i128 @llvm.sdiv.fix.sat.i128(i128 %a, i128 %b, i32 8)
  %uds = call i128 @llvm.udiv.fix.sat.i128(i128 %a, i128 %b, i32 8)
  %r = call i32 @mix8(i128 %sm, i128 %um, i128 %sd, i128 %ud, i128 %sms, i128 %ums, i128 %sds, i128 %uds)
  ret i32 %r
}


define i128 @unsupported_i128_fix_fastcc(i128 %a, i128 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc i128 @llvm.smul.fix.i128(i128 %a, i128 %b, i32 0)
  ret i128 %r
}

define i128 @unsupported_i128_fix_malformed(i128 %a, i128 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i128 @llvm.smul.fix.i128(i128 %a, i128 %b, i32 0) noreturn
  ret i128 %r
}

define void @unsupported_i128_fix_sret(ptr sret(i32) %p, ptr byval(i32) %q) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @ext_sret_byval(ptr sret(i32) %p, ptr byval(i32) %q)
  ret void
}

define i128 @sink_i128_2(i128 %a, i128 %b) {
entry:
  ret i128 %a
}

define i128 @unsupported_i128_fix_musttail(i128 %a, i128 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i128 @llvm.smul.fix.i128(i128 %a, i128 %b, i32 0)
  %v = musttail call i128 @sink_i128_2(i128 %r, i128 %b)
  ret i128 %v
}

define i128 @unsupported_i128_fix_poison(i128 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i128 @llvm.smul.fix.i128(i128 poison, i128 %b, i32 0)
  ret i128 %r
}

define i32 @main() {
entry:
  %e0 = call i32 @reference_fix(i128 48, i128 5)
  %a0 = call i32 @protected_fix(i128 48, i128 5)
  %e1 = call i32 @reference_fix(i128 -48, i128 5)
  %a1 = call i32 @protected_fix(i128 -48, i128 5)
  %e2 = call i32 @reference_fix_scale(i128 48, i128 5)
  %a2 = call i32 @protected_fix_scale(i128 48, i128 5)
  %e3 = call i32 @reference_fix_scale(i128 -48, i128 5)
  %a3 = call i32 @protected_fix_scale(i128 -48, i128 5)
  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %e1, %a1
  %m2 = icmp eq i32 %e2, %a2
  %m3 = icmp eq i32 %e3, %a3
  %t0 = and i1 %m0, %m1
  %t1 = and i1 %m2, %m3
  %ok = and i1 %t0, %t1
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_i128_fix_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_i128_fix_poison: unsupported smul.fix
; SKIP-DAG: Skipping VMP on unsupported_i128_fix_fastcc: unsupported smul.fix
; SKIP-DAG: Skipping VMP on unsupported_i128_fix_malformed: unsupported smul.fix
; SKIP-DAG: Skipping VMP on unsupported_i128_fix_sret: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_fix:
; SKIP-NOT: Skipping VMP on protected_fix_scale:
; SKIP-NOT: Skipping VMP on reference_fix:

; VIRT: define i32 @protected_fix({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: call i128 @llvm.smul.fix.i128({{.*}}, i32 0)
; VIRT-DAG: call i128 @llvm.umul.fix.i128({{.*}}, i32 0)
; VIRT-DAG: call i128 @llvm.sdiv.fix.i128({{.*}}, i32 0)
; VIRT-DAG: call i128 @llvm.udiv.fix.i128({{.*}}, i32 0)
; VIRT-DAG: call i128 @llvm.smul.fix.sat.i128({{.*}}, i32 0)
; VIRT-DAG: call i128 @llvm.umul.fix.sat.i128({{.*}}, i32 0)
; VIRT-DAG: call i128 @llvm.sdiv.fix.sat.i128({{.*}}, i32 0)
; VIRT-DAG: call i128 @llvm.udiv.fix.sat.i128({{.*}}, i32 0)
; VIRT: define i32 @protected_fix_scale({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: call i128 @llvm.smul.fix.i128({{.*}}, i32 8)
; VIRT: define i128 @unsupported_i128_fix_fastcc({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define i128 @unsupported_i128_fix_malformed({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define void @unsupported_i128_fix_sret({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define i128 @unsupported_i128_fix_musttail({{.*}} #[[UNSUP_MT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call i128 @sink_i128_2(
; VIRT: define i128 @unsupported_i128_fix_poison({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"
; VIRT-NOT: attributes #[[UNSUP_MT]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
