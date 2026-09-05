; Restricted scalar i128 *add/*sub/*mul.with.overflow through the
; dedicated AddWithOverflow path only (never ordinary Call / aggregate
; VRegs).  Every use is a single-index extractvalue of field 0 (i128
; result, independent i128 frame) or field 1 (i1 flag, integer frame).
; insertvalue / whole-pair use stays rejected.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.ll > %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.live.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.ll > %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.live.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.s7.ll > %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.s7.live.ll > %t.o0.s7.host.ll
; RUN: lli -force-interpreter %t.o0.s7.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.s7.ll > %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.s7.live.ll > %t.o2.s7.host.ll
; RUN: lli -force-interpreter %t.o2.s7.host.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare { i128, i1 } @llvm.sadd.with.overflow.i128(i128, i128)
declare { i128, i1 } @llvm.uadd.with.overflow.i128(i128, i128)
declare { i128, i1 } @llvm.ssub.with.overflow.i128(i128, i128)
declare { i128, i1 } @llvm.usub.with.overflow.i128(i128, i128)
declare { i128, i1 } @llvm.smul.with.overflow.i128(i128, i128)
declare { i128, i1 } @llvm.umul.with.overflow.i128(i128, i128)

; INT_MIN = -2^127, INT_MAX = 2^127-1, UINT_MAX = 2^128-1.
; Pack each result (lo^hi32) with its flag in a distinct i32 bit so a
; fault in either extract field changes the exit code.

define i32 @reference_ov(i128 %a, i128 %b) noinline optnone {
entry:
  %sadd = call { i128, i1 } @llvm.sadd.with.overflow.i128(i128 %a, i128 %b)
  %sadd.r = extractvalue { i128, i1 } %sadd, 0
  %sadd.f = extractvalue { i128, i1 } %sadd, 1
  %uadd = call { i128, i1 } @llvm.uadd.with.overflow.i128(i128 %a, i128 %b)
  %uadd.r = extractvalue { i128, i1 } %uadd, 0
  %uadd.f = extractvalue { i128, i1 } %uadd, 1
  %ssub = call { i128, i1 } @llvm.ssub.with.overflow.i128(i128 %a, i128 %b)
  %ssub.r = extractvalue { i128, i1 } %ssub, 0
  %ssub.f = extractvalue { i128, i1 } %ssub, 1
  %usub = call { i128, i1 } @llvm.usub.with.overflow.i128(i128 %a, i128 %b)
  %usub.r = extractvalue { i128, i1 } %usub, 0
  %usub.f = extractvalue { i128, i1 } %usub, 1
  %smul = call { i128, i1 } @llvm.smul.with.overflow.i128(i128 %a, i128 %b)
  %smul.r = extractvalue { i128, i1 } %smul, 0
  %smul.f = extractvalue { i128, i1 } %smul, 1
  %umul = call { i128, i1 } @llvm.umul.with.overflow.i128(i128 %a, i128 %b)
  %umul.r = extractvalue { i128, i1 } %umul, 0
  %umul.f = extractvalue { i128, i1 } %umul, 1
  ; Arg + constant mixes (signed/unsigned overflow when %a is a bound).
  %sadd.c = call { i128, i1 } @llvm.sadd.with.overflow.i128(i128 %a, i128 1)
  %sadd.cr = extractvalue { i128, i1 } %sadd.c, 0
  %sadd.cf = extractvalue { i128, i1 } %sadd.c, 1
  %uadd.c = call { i128, i1 } @llvm.uadd.with.overflow.i128(i128 %a, i128 1)
  %uadd.cr = extractvalue { i128, i1 } %uadd.c, 0
  %uadd.cf = extractvalue { i128, i1 } %uadd.c, 1
  %ssub.c = call { i128, i1 } @llvm.ssub.with.overflow.i128(i128 %a, i128 1)
  %ssub.cr = extractvalue { i128, i1 } %ssub.c, 0
  %ssub.cf = extractvalue { i128, i1 } %ssub.c, 1
  %usub.c = call { i128, i1 } @llvm.usub.with.overflow.i128(i128 %a, i128 1)
  %usub.cr = extractvalue { i128, i1 } %usub.c, 0
  %usub.cf = extractvalue { i128, i1 } %usub.c, 1
  %smul.c = call { i128, i1 } @llvm.smul.with.overflow.i128(i128 %a, i128 -1)
  %smul.cr = extractvalue { i128, i1 } %smul.c, 0
  %smul.cf = extractvalue { i128, i1 } %smul.c, 1
  %umul.c = call { i128, i1 } @llvm.umul.with.overflow.i128(i128 %a, i128 2)
  %umul.cr = extractvalue { i128, i1 } %umul.c, 0
  %umul.cf = extractvalue { i128, i1 } %umul.c, 1
  %t0 = xor i128 %sadd.r, %uadd.r
  %t1 = xor i128 %t0, %ssub.r
  %t2 = xor i128 %t1, %usub.r
  %t3 = xor i128 %t2, %smul.r
  %t4 = xor i128 %t3, %umul.r
  %t5 = xor i128 %t4, %sadd.cr
  %t6 = xor i128 %t5, %uadd.cr
  %t7 = xor i128 %t6, %ssub.cr
  %t8 = xor i128 %t7, %usub.cr
  %t9 = xor i128 %t8, %smul.cr
  %t10 = xor i128 %t9, %umul.cr
  %lo = trunc i128 %t10 to i32
  %hi64 = lshr i128 %t10, 32
  %hi = trunc i128 %hi64 to i32
  %mix = xor i32 %lo, %hi
  %f0 = zext i1 %sadd.f to i32
  %f1 = zext i1 %uadd.f to i32
  %f1s = shl i32 %f1, 1
  %f2 = zext i1 %ssub.f to i32
  %f2s = shl i32 %f2, 2
  %f3 = zext i1 %usub.f to i32
  %f3s = shl i32 %f3, 3
  %f4 = zext i1 %smul.f to i32
  %f4s = shl i32 %f4, 4
  %f5 = zext i1 %umul.f to i32
  %f5s = shl i32 %f5, 5
  %f6 = zext i1 %sadd.cf to i32
  %f6s = shl i32 %f6, 6
  %f7 = zext i1 %uadd.cf to i32
  %f7s = shl i32 %f7, 7
  %f8 = zext i1 %ssub.cf to i32
  %f8s = shl i32 %f8, 8
  %f9 = zext i1 %usub.cf to i32
  %f9s = shl i32 %f9, 9
  %f10 = zext i1 %smul.cf to i32
  %f10s = shl i32 %f10, 10
  %f11 = zext i1 %umul.cf to i32
  %f11s = shl i32 %f11, 11
  %p0 = or i32 %f0, %f1s
  %p1 = or i32 %p0, %f2s
  %p2 = or i32 %p1, %f3s
  %p3 = or i32 %p2, %f4s
  %p4 = or i32 %p3, %f5s
  %p5 = or i32 %p4, %f6s
  %p6 = or i32 %p5, %f7s
  %p7 = or i32 %p6, %f8s
  %p8 = or i32 %p7, %f9s
  %p9 = or i32 %p8, %f10s
  %flags = or i32 %p9, %f11s
  %out = xor i32 %mix, %flags
  ret i32 %out
}

define i32 @protected_ov(i128 %a, i128 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %sadd = call { i128, i1 } @llvm.sadd.with.overflow.i128(i128 %a, i128 %b)
  %sadd.r = extractvalue { i128, i1 } %sadd, 0
  %sadd.f = extractvalue { i128, i1 } %sadd, 1
  %uadd = call { i128, i1 } @llvm.uadd.with.overflow.i128(i128 %a, i128 %b)
  %uadd.r = extractvalue { i128, i1 } %uadd, 0
  %uadd.f = extractvalue { i128, i1 } %uadd, 1
  %ssub = call { i128, i1 } @llvm.ssub.with.overflow.i128(i128 %a, i128 %b)
  %ssub.r = extractvalue { i128, i1 } %ssub, 0
  %ssub.f = extractvalue { i128, i1 } %ssub, 1
  %usub = call { i128, i1 } @llvm.usub.with.overflow.i128(i128 %a, i128 %b)
  %usub.r = extractvalue { i128, i1 } %usub, 0
  %usub.f = extractvalue { i128, i1 } %usub, 1
  %smul = call { i128, i1 } @llvm.smul.with.overflow.i128(i128 %a, i128 %b)
  %smul.r = extractvalue { i128, i1 } %smul, 0
  %smul.f = extractvalue { i128, i1 } %smul, 1
  %umul = call { i128, i1 } @llvm.umul.with.overflow.i128(i128 %a, i128 %b)
  %umul.r = extractvalue { i128, i1 } %umul, 0
  %umul.f = extractvalue { i128, i1 } %umul, 1
  %sadd.c = call { i128, i1 } @llvm.sadd.with.overflow.i128(i128 %a, i128 1)
  %sadd.cr = extractvalue { i128, i1 } %sadd.c, 0
  %sadd.cf = extractvalue { i128, i1 } %sadd.c, 1
  %uadd.c = call { i128, i1 } @llvm.uadd.with.overflow.i128(i128 %a, i128 1)
  %uadd.cr = extractvalue { i128, i1 } %uadd.c, 0
  %uadd.cf = extractvalue { i128, i1 } %uadd.c, 1
  %ssub.c = call { i128, i1 } @llvm.ssub.with.overflow.i128(i128 %a, i128 1)
  %ssub.cr = extractvalue { i128, i1 } %ssub.c, 0
  %ssub.cf = extractvalue { i128, i1 } %ssub.c, 1
  %usub.c = call { i128, i1 } @llvm.usub.with.overflow.i128(i128 %a, i128 1)
  %usub.cr = extractvalue { i128, i1 } %usub.c, 0
  %usub.cf = extractvalue { i128, i1 } %usub.c, 1
  %smul.c = call { i128, i1 } @llvm.smul.with.overflow.i128(i128 %a, i128 -1)
  %smul.cr = extractvalue { i128, i1 } %smul.c, 0
  %smul.cf = extractvalue { i128, i1 } %smul.c, 1
  %umul.c = call { i128, i1 } @llvm.umul.with.overflow.i128(i128 %a, i128 2)
  %umul.cr = extractvalue { i128, i1 } %umul.c, 0
  %umul.cf = extractvalue { i128, i1 } %umul.c, 1
  %t0 = xor i128 %sadd.r, %uadd.r
  %t1 = xor i128 %t0, %ssub.r
  %t2 = xor i128 %t1, %usub.r
  %t3 = xor i128 %t2, %smul.r
  %t4 = xor i128 %t3, %umul.r
  %t5 = xor i128 %t4, %sadd.cr
  %t6 = xor i128 %t5, %uadd.cr
  %t7 = xor i128 %t6, %ssub.cr
  %t8 = xor i128 %t7, %usub.cr
  %t9 = xor i128 %t8, %smul.cr
  %t10 = xor i128 %t9, %umul.cr
  %lo = trunc i128 %t10 to i32
  %hi64 = lshr i128 %t10, 32
  %hi = trunc i128 %hi64 to i32
  %mix = xor i32 %lo, %hi
  %f0 = zext i1 %sadd.f to i32
  %f1 = zext i1 %uadd.f to i32
  %f1s = shl i32 %f1, 1
  %f2 = zext i1 %ssub.f to i32
  %f2s = shl i32 %f2, 2
  %f3 = zext i1 %usub.f to i32
  %f3s = shl i32 %f3, 3
  %f4 = zext i1 %smul.f to i32
  %f4s = shl i32 %f4, 4
  %f5 = zext i1 %umul.f to i32
  %f5s = shl i32 %f5, 5
  %f6 = zext i1 %sadd.cf to i32
  %f6s = shl i32 %f6, 6
  %f7 = zext i1 %uadd.cf to i32
  %f7s = shl i32 %f7, 7
  %f8 = zext i1 %ssub.cf to i32
  %f8s = shl i32 %f8, 8
  %f9 = zext i1 %usub.cf to i32
  %f9s = shl i32 %f9, 9
  %f10 = zext i1 %smul.cf to i32
  %f10s = shl i32 %f10, 10
  %f11 = zext i1 %umul.cf to i32
  %f11s = shl i32 %f11, 11
  %p0 = or i32 %f0, %f1s
  %p1 = or i32 %p0, %f2s
  %p2 = or i32 %p1, %f3s
  %p3 = or i32 %p2, %f4s
  %p4 = or i32 %p3, %f5s
  %p5 = or i32 %p4, %f6s
  %p6 = or i32 %p5, %f7s
  %p7 = or i32 %p6, %f8s
  %p8 = or i32 %p7, %f9s
  %p9 = or i32 %p8, %f10s
  %flags = or i32 %p9, %f11s
  %out = xor i32 %mix, %flags
  ret i32 %out
}

; Still-rejected: insertvalue / whole-pair use of the overflow aggregate.
; The dedicated path requires only single-index extractvalue 0/1.
define i32 @unsupported_i128_overflow_agg(i128 %a, i128 %b) noinline optnone {
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
  ; No overflow.
  %e0 = call i32 @reference_ov(i128 0, i128 0)
  %a0 = call i32 @protected_ov(i128 0, i128 0)
  %ok0 = icmp eq i32 %e0, %a0
  %e1 = call i32 @reference_ov(i128 1, i128 1)
  %a1 = call i32 @protected_ov(i128 1, i128 1)
  %ok1 = icmp eq i32 %e1, %a1
  ; Signed add overflow: INT_MAX + 1.  Also sadd.c / ssub / smul bounds.
  %e2 = call i32 @reference_ov(i128 170141183460469231731687303715884105727, i128 1)
  %a2 = call i32 @protected_ov(i128 170141183460469231731687303715884105727, i128 1)
  %ok2 = icmp eq i32 %e2, %a2
  ; Unsigned add overflow: UINT_MAX + 1.
  %e3 = call i32 @reference_ov(i128 -1, i128 1)
  %a3 = call i32 @protected_ov(i128 -1, i128 1)
  %ok3 = icmp eq i32 %e3, %a3
  ; Signed sub overflow: INT_MIN - 1.  Also smul(INT_MIN, -1).
  %e4 = call i32 @reference_ov(i128 -170141183460469231731687303715884105728, i128 1)
  %a4 = call i32 @protected_ov(i128 -170141183460469231731687303715884105728, i128 1)
  %ok4 = icmp eq i32 %e4, %a4
  ; Unsigned sub overflow: 0 - 1.
  %e5 = call i32 @reference_ov(i128 0, i128 1)
  %a5 = call i32 @protected_ov(i128 0, i128 1)
  %ok5 = icmp eq i32 %e5, %a5
  ; Signed add + mul overflow: INT_MIN + (-1), INT_MIN * (-1).
  %e6 = call i32 @reference_ov(i128 -170141183460469231731687303715884105728, i128 -1)
  %a6 = call i32 @protected_ov(i128 -170141183460469231731687303715884105728, i128 -1)
  %ok6 = icmp eq i32 %e6, %a6
  ; Unsigned (and signed) mul overflow: 2^64 * 2^64 = 2^128.
  %e7 = call i32 @reference_ov(i128 18446744073709551616, i128 18446744073709551616)
  %a7 = call i32 @protected_ov(i128 18446744073709551616, i128 18446744073709551616)
  %ok7 = icmp eq i32 %e7, %a7
  %t0 = and i1 %ok0, %ok1
  %t1 = and i1 %t0, %ok2
  %t2 = and i1 %t1, %ok3
  %t3 = and i1 %t2, %ok4
  %t4 = and i1 %t3, %ok5
  %t5 = and i1 %t4, %ok6
  %ok = and i1 %t5, %ok7
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP-DAG: Skipping VMP on unsupported_i128_overflow_agg: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_ov:
; SKIP-NOT: Skipping VMP on reference_ov:

; VIRT-LABEL: define i32 @protected_ov(
; VIRT: %vmp.i128.regs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: call { i128, i1 } @llvm.sadd.with.overflow.i128(
; VIRT-DAG: call { i128, i1 } @llvm.uadd.with.overflow.i128(
; VIRT-DAG: call { i128, i1 } @llvm.ssub.with.overflow.i128(
; VIRT-DAG: call { i128, i1 } @llvm.usub.with.overflow.i128(
; VIRT-DAG: call { i128, i1 } @llvm.smul.with.overflow.i128(
; VIRT-DAG: call { i128, i1 } @llvm.umul.with.overflow.i128(
; VIRT-DAG: [[SA:%.*]] = call { i128, i1 } @llvm.sadd.with.overflow.i128(i128 [[SAA:%.*]], i128 [[SAB:%.*]])
; VIRT-DAG: [[SAA]] = load volatile i128, ptr {{.*}}
; VIRT-DAG: [[SAB]] = load volatile i128, ptr {{.*}}
; VIRT-DAG: [[SAR:%.*]] = extractvalue { i128, i1 } [[SA]], 0
; VIRT-DAG: store volatile i128 [[SAR]], ptr {{.*}}
; VIRT-DAG: [[SAF:%.*]] = extractvalue { i128, i1 } [[SA]], 1
; VIRT-DAG: [[SAFW:%.*]] = zext i1 [[SAF]] to i64
; VIRT-DAG: store volatile i64 [[SAFW]], ptr {{.*}}
; VIRT: define i32 @unsupported_i128_overflow_agg({{.*}} #[[UNSUPATTR:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #{{[0-9]+}} = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.virtualized"
