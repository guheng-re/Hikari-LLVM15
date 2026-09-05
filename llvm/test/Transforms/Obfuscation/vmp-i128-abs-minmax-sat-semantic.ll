; Restricted scalar i128 abs / smin/smax/umin/umax /
; sadd.sat/uadd.sat/ssub.sat/usub.sat/sshl.sat/ushl.sat.  Replayed
; through the independent i128 VReg frame and the ordinary Call path.
; Extractvalue i128 *with.overflow lives in vmp-i128-overflow-semantic.ll.
; This file keeps a still-rejected insertvalue / whole-pair overflow use.
; Scalar abs / sat: C, exact FTy, formal type equality, i1 ImmArg on
; abs.  Ordinary tail accepted and replayed as TCK_None.  Minmax already hardened separately.
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
declare i128 @llvm.abs.i128(i128, i1 immarg)
declare i128 @llvm.smin.i128(i128, i128)
declare i128 @llvm.smax.i128(i128, i128)
declare i128 @llvm.umin.i128(i128, i128)
declare i128 @llvm.umax.i128(i128, i128)
declare i128 @llvm.sadd.sat.i128(i128, i128)
declare i128 @llvm.uadd.sat.i128(i128, i128)
declare i128 @llvm.ssub.sat.i128(i128, i128)
declare i128 @llvm.usub.sat.i128(i128, i128)
declare i128 @llvm.sshl.sat.i128(i128, i128)
declare i128 @llvm.ushl.sat.i128(i128, i128)
declare { i128, i1 } @llvm.uadd.with.overflow.i128(i128, i128)
declare void @ext_sret_byval(ptr sret(i32), ptr byval(i32))

; i128 signed minimum / maximum.
; INT_MIN = -2^127, INT_MAX = 2^127-1.
define i32 @reference_abs(i128 %a) noinline optnone {
entry:
  %abs.f = call i128 @llvm.abs.i128(i128 %a, i1 false)
  %safe = or i128 %a, 1
  %abs.t = call i128 @llvm.abs.i128(i128 %safe, i1 true)
  %abs.min = call i128 @llvm.abs.i128(i128 -170141183460469231731687303715884105728, i1 false)
  %t0 = xor i128 %abs.f, %abs.t
  %t1 = xor i128 %t0, %abs.min
  %lo = trunc i128 %t1 to i32
  %hi64 = lshr i128 %t1, 32
  %hi = trunc i128 %hi64 to i32
  %out = xor i32 %lo, %hi
  ret i32 %out
}

define i32 @protected_abs(i128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %abs.f = call i128 @llvm.abs.i128(i128 %a, i1 false)
  %safe = or i128 %a, 1
  %abs.t = call i128 @llvm.abs.i128(i128 %safe, i1 true)
  %abs.min = call i128 @llvm.abs.i128(i128 -170141183460469231731687303715884105728, i1 false)
  %t0 = xor i128 %abs.f, %abs.t
  %t1 = xor i128 %t0, %abs.min
  %lo = trunc i128 %t1 to i32
  %hi64 = lshr i128 %t1, 32
  %hi = trunc i128 %hi64 to i32
  %out = xor i32 %lo, %hi
  ret i32 %out
}

define i32 @reference_minmax(i128 %a) noinline optnone {
entry:
  ; Non-absorbing arg/constant mixes.  smin(%a, INT_MIN) and friends
  ; fold to a module-wide constant (O2 then drops the four families).
  %smin.a = call i128 @llvm.smin.i128(i128 %a, i128 305419896)
  %smax.a = call i128 @llvm.smax.i128(i128 %a, i128 -305419896)
  %umin.a = call i128 @llvm.umin.i128(i128 %a, i128 305419896)
  %umax.a = call i128 @llvm.umax.i128(i128 %a, i128 305419896)
  ; Boundary-adjacent constants: result still depends on %a, but the
  ; extrema appear when main passes INT_MIN / INT_MAX / 0 / -1.
  %smin.lo = call i128 @llvm.smin.i128(i128 %a, i128 -170141183460469231731687303715884105727)
  %smax.hi = call i128 @llvm.smax.i128(i128 %a, i128 170141183460469231731687303715884105726)
  %umin.lo = call i128 @llvm.umin.i128(i128 %a, i128 1)
  %umax.hi = call i128 @llvm.umax.i128(i128 %a, i128 -2)
  %smin.c = call i128 @llvm.smin.i128(i128 -170141183460469231731687303715884105728, i128 170141183460469231731687303715884105727)
  %smax.c = call i128 @llvm.smax.i128(i128 -170141183460469231731687303715884105728, i128 170141183460469231731687303715884105727)
  %umin.c = call i128 @llvm.umin.i128(i128 0, i128 -1)
  %umax.c = call i128 @llvm.umax.i128(i128 0, i128 -1)
  %t0 = xor i128 %smin.a, %smax.a
  %t1 = xor i128 %t0, %umin.a
  %t2 = xor i128 %t1, %umax.a
  %t3 = xor i128 %t2, %smin.lo
  %t4 = xor i128 %t3, %smax.hi
  %t5 = xor i128 %t4, %umin.lo
  %t6 = xor i128 %t5, %umax.hi
  %t7 = xor i128 %t6, %smin.c
  %t8 = xor i128 %t7, %smax.c
  %t9 = xor i128 %t8, %umin.c
  %t10 = xor i128 %t9, %umax.c
  %lo = trunc i128 %t10 to i32
  %hi64 = lshr i128 %t10, 32
  %hi = trunc i128 %hi64 to i32
  %out = xor i32 %lo, %hi
  ret i32 %out
}

define i32 @protected_minmax(i128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %smin.a = call i128 @llvm.smin.i128(i128 %a, i128 305419896)
  %smax.a = call i128 @llvm.smax.i128(i128 %a, i128 -305419896)
  %umin.a = call i128 @llvm.umin.i128(i128 %a, i128 305419896)
  %umax.a = call i128 @llvm.umax.i128(i128 %a, i128 305419896)
  %smin.lo = call i128 @llvm.smin.i128(i128 %a, i128 -170141183460469231731687303715884105727)
  %smax.hi = call i128 @llvm.smax.i128(i128 %a, i128 170141183460469231731687303715884105726)
  %umin.lo = call i128 @llvm.umin.i128(i128 %a, i128 1)
  %umax.hi = call i128 @llvm.umax.i128(i128 %a, i128 -2)
  %smin.c = call i128 @llvm.smin.i128(i128 -170141183460469231731687303715884105728, i128 170141183460469231731687303715884105727)
  %smax.c = call i128 @llvm.smax.i128(i128 -170141183460469231731687303715884105728, i128 170141183460469231731687303715884105727)
  %umin.c = call i128 @llvm.umin.i128(i128 0, i128 -1)
  %umax.c = call i128 @llvm.umax.i128(i128 0, i128 -1)
  %t0 = xor i128 %smin.a, %smax.a
  %t1 = xor i128 %t0, %umin.a
  %t2 = xor i128 %t1, %umax.a
  %t3 = xor i128 %t2, %smin.lo
  %t4 = xor i128 %t3, %smax.hi
  %t5 = xor i128 %t4, %umin.lo
  %t6 = xor i128 %t5, %umax.hi
  %t7 = xor i128 %t6, %smin.c
  %t8 = xor i128 %t7, %smax.c
  %t9 = xor i128 %t8, %umin.c
  %t10 = xor i128 %t9, %umax.c
  %lo = trunc i128 %t10 to i32
  %hi64 = lshr i128 %t10, 32
  %hi = trunc i128 %hi64 to i32
  %out = xor i32 %lo, %hi
  ret i32 %out
}

define i32 @reference_sat_addsub(i128 %a) noinline optnone {
entry:
  %sadd.a = call i128 @llvm.sadd.sat.i128(i128 %a, i128 1)
  %sadd.hi = call i128 @llvm.sadd.sat.i128(i128 170141183460469231731687303715884105727, i128 1)
  %sadd.lo = call i128 @llvm.sadd.sat.i128(i128 -170141183460469231731687303715884105728, i128 -1)
  %ssub.a = call i128 @llvm.ssub.sat.i128(i128 %a, i128 1)
  %ssub.lo = call i128 @llvm.ssub.sat.i128(i128 -170141183460469231731687303715884105728, i128 1)
  %ssub.hi = call i128 @llvm.ssub.sat.i128(i128 170141183460469231731687303715884105727, i128 -1)
  %uadd.a = call i128 @llvm.uadd.sat.i128(i128 %a, i128 1)
  %uadd.hi = call i128 @llvm.uadd.sat.i128(i128 -1, i128 1)
  %usub.a = call i128 @llvm.usub.sat.i128(i128 %a, i128 1)
  %usub.lo = call i128 @llvm.usub.sat.i128(i128 0, i128 1)
  %t0 = xor i128 %sadd.a, %sadd.hi
  %t1 = xor i128 %t0, %sadd.lo
  %t2 = xor i128 %t1, %ssub.a
  %t3 = xor i128 %t2, %ssub.lo
  %t4 = xor i128 %t3, %ssub.hi
  %t5 = xor i128 %t4, %uadd.a
  %t6 = xor i128 %t5, %uadd.hi
  %t7 = xor i128 %t6, %usub.a
  %t8 = xor i128 %t7, %usub.lo
  %lo = trunc i128 %t8 to i32
  %hi64 = lshr i128 %t8, 32
  %hi = trunc i128 %hi64 to i32
  %out = xor i32 %lo, %hi
  ret i32 %out
}

define i32 @protected_sat_addsub(i128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %sadd.a = call i128 @llvm.sadd.sat.i128(i128 %a, i128 1)
  %sadd.hi = call i128 @llvm.sadd.sat.i128(i128 170141183460469231731687303715884105727, i128 1)
  %sadd.lo = call i128 @llvm.sadd.sat.i128(i128 -170141183460469231731687303715884105728, i128 -1)
  %ssub.a = call i128 @llvm.ssub.sat.i128(i128 %a, i128 1)
  %ssub.lo = call i128 @llvm.ssub.sat.i128(i128 -170141183460469231731687303715884105728, i128 1)
  %ssub.hi = call i128 @llvm.ssub.sat.i128(i128 170141183460469231731687303715884105727, i128 -1)
  %uadd.a = call i128 @llvm.uadd.sat.i128(i128 %a, i128 1)
  %uadd.hi = call i128 @llvm.uadd.sat.i128(i128 -1, i128 1)
  %usub.a = call i128 @llvm.usub.sat.i128(i128 %a, i128 1)
  %usub.lo = call i128 @llvm.usub.sat.i128(i128 0, i128 1)
  %t0 = xor i128 %sadd.a, %sadd.hi
  %t1 = xor i128 %t0, %sadd.lo
  %t2 = xor i128 %t1, %ssub.a
  %t3 = xor i128 %t2, %ssub.lo
  %t4 = xor i128 %t3, %ssub.hi
  %t5 = xor i128 %t4, %uadd.a
  %t6 = xor i128 %t5, %uadd.hi
  %t7 = xor i128 %t6, %usub.a
  %t8 = xor i128 %t7, %usub.lo
  %lo = trunc i128 %t8 to i32
  %hi64 = lshr i128 %t8, 32
  %hi = trunc i128 %hi64 to i32
  %out = xor i32 %lo, %hi
  ret i32 %out
}

define i32 @reference_sat_shl(i128 %a) noinline optnone {
entry:
  %sshl.a = call i128 @llvm.sshl.sat.i128(i128 %a, i128 1)
  %sshl.hi = call i128 @llvm.sshl.sat.i128(i128 2, i128 127)
  %sshl.lo = call i128 @llvm.sshl.sat.i128(i128 -2, i128 127)
  %ushl.a = call i128 @llvm.ushl.sat.i128(i128 %a, i128 1)
  %ushl.hi = call i128 @llvm.ushl.sat.i128(i128 1, i128 127)
  %ushl.ov = call i128 @llvm.ushl.sat.i128(i128 -1, i128 1)
  %t0 = xor i128 %sshl.a, %sshl.hi
  %t1 = xor i128 %t0, %sshl.lo
  %t2 = xor i128 %t1, %ushl.a
  %t3 = xor i128 %t2, %ushl.hi
  %t4 = xor i128 %t3, %ushl.ov
  %lo = trunc i128 %t4 to i32
  %hi64 = lshr i128 %t4, 32
  %hi = trunc i128 %hi64 to i32
  %out = xor i32 %lo, %hi
  ret i32 %out
}

define i32 @protected_sat_shl(i128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %sshl.a = call i128 @llvm.sshl.sat.i128(i128 %a, i128 1)
  %sshl.hi = call i128 @llvm.sshl.sat.i128(i128 2, i128 127)
  %sshl.lo = call i128 @llvm.sshl.sat.i128(i128 -2, i128 127)
  %ushl.a = call i128 @llvm.ushl.sat.i128(i128 %a, i128 1)
  %ushl.hi = call i128 @llvm.ushl.sat.i128(i128 1, i128 127)
  %ushl.ov = call i128 @llvm.ushl.sat.i128(i128 -1, i128 1)
  %t0 = xor i128 %sshl.a, %sshl.hi
  %t1 = xor i128 %t0, %sshl.lo
  %t2 = xor i128 %t1, %ushl.a
  %t3 = xor i128 %t2, %ushl.hi
  %t4 = xor i128 %t3, %ushl.ov
  %lo = trunc i128 %t4 to i32
  %hi64 = lshr i128 %t4, 32
  %hi = trunc i128 %hi64 to i32
  %out = xor i32 %lo, %hi
  ret i32 %out
}

; Still unsupported: insertvalue / whole-pair use of the overflow
; aggregate.  The dedicated AddWithOverflow path accepts only
; single-index extractvalue 0/1, at most once each.

define i128 @unsupported_i128_abs_fastcc(i128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc i128 @llvm.abs.i128(i128 %a, i1 false)
  ret i128 %r
}

define i128 @unsupported_i128_abs_malformed(i128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i128 @llvm.abs.i128(i128 %a, i1 false) noreturn
  ret i128 %r
}

define i128 @unsupported_i128_abs_poison() noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i128 @llvm.abs.i128(i128 poison, i1 false)
  ret i128 %r
}


define void @unsupported_i128_abssat_sret(ptr sret(i32) %p, ptr byval(i32) %q) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @ext_sret_byval(ptr sret(i32) %p, ptr byval(i32) %q)
  ret void
}

define i32 @unsupported_i128_overflow(i128 %a, i128 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %p = call { i128, i1 } @llvm.uadd.with.overflow.i128(i128 %a, i128 %b)
  %q = insertvalue { i128, i1 } %p, i1 true, 1
  %s = extractvalue { i128, i1 } %q, 0
  %t = trunc i128 %s to i32
  ret i32 %t
}

define i32 @main() {
entry:
  %ea0 = call i32 @reference_abs(i128 -42)
  %aa0 = call i32 @protected_abs(i128 -42)
  %oka0 = icmp eq i32 %ea0, %aa0
  %ea1 = call i32 @reference_abs(i128 42)
  %aa1 = call i32 @protected_abs(i128 42)
  %oka1 = icmp eq i32 %ea1, %aa1
  %ea2 = call i32 @reference_abs(i128 -170141183460469231731687303715884105728)
  %aa2 = call i32 @protected_abs(i128 -170141183460469231731687303715884105728)
  %oka2 = icmp eq i32 %ea2, %aa2
  %em0 = call i32 @reference_minmax(i128 0)
  %am0 = call i32 @protected_minmax(i128 0)
  %okm0 = icmp eq i32 %em0, %am0
  %em1 = call i32 @reference_minmax(i128 -1)
  %am1 = call i32 @protected_minmax(i128 -1)
  %okm1 = icmp eq i32 %em1, %am1
  %em2 = call i32 @reference_minmax(i128 -170141183460469231731687303715884105728)
  %am2 = call i32 @protected_minmax(i128 -170141183460469231731687303715884105728)
  %okm2 = icmp eq i32 %em2, %am2
  %em3 = call i32 @reference_minmax(i128 170141183460469231731687303715884105727)
  %am3 = call i32 @protected_minmax(i128 170141183460469231731687303715884105727)
  %okm3 = icmp eq i32 %em3, %am3
  %es0 = call i32 @reference_sat_addsub(i128 0)
  %as0 = call i32 @protected_sat_addsub(i128 0)
  %oks0 = icmp eq i32 %es0, %as0
  %es1 = call i32 @reference_sat_addsub(i128 1)
  %as1 = call i32 @protected_sat_addsub(i128 1)
  %oks1 = icmp eq i32 %es1, %as1
  %es2 = call i32 @reference_sat_addsub(i128 -1)
  %as2 = call i32 @protected_sat_addsub(i128 -1)
  %oks2 = icmp eq i32 %es2, %as2
  %es3 = call i32 @reference_sat_addsub(i128 170141183460469231731687303715884105727)
  %as3 = call i32 @protected_sat_addsub(i128 170141183460469231731687303715884105727)
  %oks3 = icmp eq i32 %es3, %as3
  %es4 = call i32 @reference_sat_addsub(i128 -170141183460469231731687303715884105728)
  %as4 = call i32 @protected_sat_addsub(i128 -170141183460469231731687303715884105728)
  %oks4 = icmp eq i32 %es4, %as4
  %eh0 = call i32 @reference_sat_shl(i128 0)
  %ah0 = call i32 @protected_sat_shl(i128 0)
  %okh0 = icmp eq i32 %eh0, %ah0
  %eh1 = call i32 @reference_sat_shl(i128 1)
  %ah1 = call i32 @protected_sat_shl(i128 1)
  %okh1 = icmp eq i32 %eh1, %ah1
  %eh2 = call i32 @reference_sat_shl(i128 -1)
  %ah2 = call i32 @protected_sat_shl(i128 -1)
  %okh2 = icmp eq i32 %eh2, %ah2
  %t0 = and i1 %oka0, %oka1
  %t1 = and i1 %t0, %oka2
  %t2 = and i1 %t1, %okm0
  %t3 = and i1 %t2, %okm1
  %t4 = and i1 %t3, %okm2
  %t5 = and i1 %t4, %okm3
  %t6 = and i1 %t5, %oks0
  %t7 = and i1 %t6, %oks1
  %t8 = and i1 %t7, %oks2
  %t9 = and i1 %t8, %oks3
  %t10 = and i1 %t9, %oks4
  %t11 = and i1 %t10, %okh0
  %t12 = and i1 %t11, %okh1
  %ok = and i1 %t12, %okh2
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP-DAG: Skipping VMP on unsupported_i128_abs_fastcc: unsupported abs
; SKIP-DAG: Skipping VMP on unsupported_i128_abs_malformed: unsupported abs
; SKIP-DAG: Skipping VMP on unsupported_i128_abs_poison: unsupported abs
; SKIP-DAG: Skipping VMP on unsupported_i128_abssat_sret: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_i128_overflow: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_abs:
; SKIP-NOT: Skipping VMP on protected_minmax:
; SKIP-NOT: Skipping VMP on protected_sat_addsub:
; SKIP-NOT: Skipping VMP on protected_sat_shl:
; SKIP-NOT: Skipping VMP on reference_abs:
; SKIP-NOT: Skipping VMP on reference_minmax:
; SKIP-NOT: Skipping VMP on reference_sat_addsub:
; SKIP-NOT: Skipping VMP on reference_sat_shl:

; VIRT-LABEL: define i32 @protected_abs(
; VIRT: %vmp.i128.regs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: call i128 @llvm.abs.i128({{.*}}, i1 false)
; VIRT-DAG: call i128 @llvm.abs.i128({{.*}}, i1 true)
; VIRT-LABEL: define i32 @protected_minmax(
; VIRT: %vmp.i128.regs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: call i128 @llvm.smin.i128(
; VIRT-DAG: call i128 @llvm.smax.i128(
; VIRT-DAG: call i128 @llvm.umin.i128(
; VIRT-DAG: call i128 @llvm.umax.i128(
; VIRT-LABEL: define i32 @protected_sat_addsub(
; VIRT: %vmp.i128.regs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: call i128 @llvm.sadd.sat.i128(
; VIRT-DAG: call i128 @llvm.uadd.sat.i128(
; VIRT-DAG: call i128 @llvm.ssub.sat.i128(
; VIRT-DAG: call i128 @llvm.usub.sat.i128(
; VIRT-LABEL: define i32 @protected_sat_shl(
; VIRT: %vmp.i128.regs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: call i128 @llvm.sshl.sat.i128(
; VIRT-DAG: call i128 @llvm.ushl.sat.i128(
; VIRT: define {{.*}} @unsupported_i128_abs_fastcc({{.*}} #[[UNSUPATTR:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_i128_abs_malformed({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_i128_abs_poison({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_i128_abssat_sret({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define i32 @unsupported_i128_overflow({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #{{[0-9]+}} = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
