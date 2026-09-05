; Small flat aggregate SSA on VMP: 1..4 fields of i1/i8/i16/i32/i64/AS0
; ptr/f32/f64 or a supported fixed vector, alloc size 1..64.
; insertvalue/extractvalue, load/store, phi/select, direct C call
; args/returns.  Vector fields travel through the existing vector frame.
; Overflow/cmpxchg/ld64b/rndr stay exploded into scalar VRegs.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP-O0 < %t.o0.err
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
; RUN: FileCheck %s --check-prefix=SKIP-O0 < %t.o0.s7.err
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

%pair = type { i32, i32 }
%mixed = type { ptr, i32 }
%ff = type { float, float }
%vecfield = type { <2 x i32>, i32 }
%varr = type [2 x <2 x i32>]
%fvpair = type { <2 x float>, float }
%dd = type { double, double }

declare void @hikari_vmp()

@slot.pair = private global %pair { i32 10, i32 20 }, align 8
@slot.vec = private global %vecfield { <2 x i32> <i32 1, i32 2>, i32 3 }, align 8

define %pair @make_pair(i32 %a, i32 %b) noinline {
entry:
  %p0 = insertvalue %pair poison, i32 %a, 0
  %p1 = insertvalue %pair %p0, i32 %b, 1
  ret %pair %p1
}

define i32 @sum_pair(%pair %p) noinline {
entry:
  %a = extractvalue %pair %p, 0
  %b = extractvalue %pair %p, 1
  %s = add i32 %a, %b
  ret i32 %s
}

define i32 @reference_pair(i32 %a, i32 %b, i1 %c) noinline optnone {
entry:
  %p0 = insertvalue %pair poison, i32 %a, 0
  %p1 = insertvalue %pair %p0, i32 %b, 1
  %alt = insertvalue %pair zeroinitializer, i32 %a, 0
  %sel = select i1 %c, %pair %p1, %pair %alt
  br i1 %c, label %left, label %right

left:
  %lp = insertvalue %pair %sel, i32 1, 1
  br label %join

right:
  %rp = insertvalue %pair %sel, i32 2, 1
  br label %join

join:
  %phi = phi %pair [ %lp, %left ], [ %rp, %right ]
  store %pair %phi, ptr @slot.pair, align 8
  %ld = load %pair, ptr @slot.pair, align 8
  %called = call %pair @make_pair(i32 %a, i32 %b)
  %s0 = call i32 @sum_pair(%pair %ld)
  %s1 = call i32 @sum_pair(%pair %called)
  %e0 = extractvalue %pair %ld, 0
  %e1 = extractvalue %pair %phi, 1
  %x0 = xor i32 %s0, %s1
  %x1 = xor i32 %e0, %e1
  %out = xor i32 %x0, %x1
  ret i32 %out
}

define i32 @protected_pair(i32 %a, i32 %b, i1 %c) noinline optnone {
entry:
  call void @hikari_vmp()
  %p0 = insertvalue %pair poison, i32 %a, 0
  %p1 = insertvalue %pair %p0, i32 %b, 1
  %alt = insertvalue %pair zeroinitializer, i32 %a, 0
  %sel = select i1 %c, %pair %p1, %pair %alt
  br i1 %c, label %left, label %right

left:
  %lp = insertvalue %pair %sel, i32 1, 1
  br label %join

right:
  %rp = insertvalue %pair %sel, i32 2, 1
  br label %join

join:
  %phi = phi %pair [ %lp, %left ], [ %rp, %right ]
  store %pair %phi, ptr @slot.pair, align 8
  %ld = load %pair, ptr @slot.pair, align 8
  %called = call %pair @make_pair(i32 %a, i32 %b)
  %s0 = call i32 @sum_pair(%pair %ld)
  %s1 = call i32 @sum_pair(%pair %called)
  %e0 = extractvalue %pair %ld, 0
  %e1 = extractvalue %pair %phi, 1
  %x0 = xor i32 %s0, %s1
  %x1 = xor i32 %e0, %e1
  %out = xor i32 %x0, %x1
  ret i32 %out
}

define i32 @reference_mixed(ptr %p, i32 %n) noinline optnone {
entry:
  %m0 = insertvalue %mixed poison, ptr %p, 0
  %m1 = insertvalue %mixed %m0, i32 %n, 1
  %q = extractvalue %mixed %m1, 0
  %k = extractvalue %mixed %m1, 1
  %v = load i32, ptr %q, align 4
  %s = add i32 %v, %k
  ret i32 %s
}

define i32 @protected_mixed(ptr %p, i32 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  %m0 = insertvalue %mixed poison, ptr %p, 0
  %m1 = insertvalue %mixed %m0, i32 %n, 1
  %q = extractvalue %mixed %m1, 0
  %k = extractvalue %mixed %m1, 1
  %v = load i32, ptr %q, align 4
  %s = add i32 %v, %k
  ret i32 %s
}

define i32 @reference_array([2 x i64] %a) noinline optnone {
entry:
  %x = extractvalue [2 x i64] %a, 0
  %y = extractvalue [2 x i64] %a, 1
  %z = xor i64 %x, %y
  %t = trunc i64 %z to i32
  ret i32 %t
}

define i32 @protected_array([2 x i64] %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %x = extractvalue [2 x i64] %a, 0
  %y = extractvalue [2 x i64] %a, 1
  %z = xor i64 %x, %y
  %t = trunc i64 %z to i32
  ret i32 %t
}

define i32 @reference_ff(float %x, float %y) noinline optnone {
entry:
  %p0 = insertvalue %ff poison, float %x, 0
  %p1 = insertvalue %ff %p0, float %y, 1
  %a = extractvalue %ff %p1, 0
  %b = extractvalue %ff %p1, 1
  %s = fadd float %a, %b
  %bits = bitcast float %s to i32
  ret i32 %bits
}

define i32 @protected_ff(float %x, float %y) noinline optnone {
entry:
  call void @hikari_vmp()
  %p0 = insertvalue %ff poison, float %x, 0
  %p1 = insertvalue %ff %p0, float %y, 1
  %a = extractvalue %ff %p1, 0
  %b = extractvalue %ff %p1, 1
  %s = fadd float %a, %b
  %bits = bitcast float %s to i32
  ret i32 %bits
}

define i32 @fold_i32x2(<2 x i32> %v) {
entry:
  %e0 = extractelement <2 x i32> %v, i32 0
  %e1 = extractelement <2 x i32> %v, i32 1
  %r = xor i32 %e0, %e1
  ret i32 %r
}

define %vecfield @make_vecfield(<2 x i32> %v, i32 %k) noinline {
entry:
  %p0 = insertvalue %vecfield poison, <2 x i32> %v, 0
  %p1 = insertvalue %vecfield %p0, i32 %k, 1
  ret %vecfield %p1
}

define i32 @reference_vecfield(<2 x i32> %v, i32 %k, i1 %c) noinline optnone {
entry:
  %p0 = insertvalue %vecfield poison, <2 x i32> %v, 0
  %p1 = insertvalue %vecfield %p0, i32 %k, 1
  %alt = insertvalue %vecfield zeroinitializer, <2 x i32> %v, 0
  %sel = select i1 %c, %vecfield %p1, %vecfield %alt
  br i1 %c, label %left, label %right

left:
  %lp = insertvalue %vecfield %sel, i32 1, 1
  br label %join

right:
  %rp = insertvalue %vecfield %sel, i32 2, 1
  br label %join

join:
  %phi = phi %vecfield [ %lp, %left ], [ %rp, %right ]
  store %vecfield %phi, ptr @slot.vec, align 8
  %ld = load %vecfield, ptr @slot.vec, align 8
  %called = call %vecfield @make_vecfield(<2 x i32> %v, i32 %k)
  %lv = extractvalue %vecfield %ld, 0
  %lk = extractvalue %vecfield %ld, 1
  %cv = extractvalue %vecfield %called, 0
  %ck = extractvalue %vecfield %called, 1
  %pv = extractvalue %vecfield %phi, 0
  %addv = add <2 x i32> %lv, %cv
  %mixv = xor <2 x i32> %addv, %pv
  %vr = call i32 @fold_i32x2(<2 x i32> %mixv)
  %kr = xor i32 %lk, %ck
  %out = xor i32 %vr, %kr
  ret i32 %out
}

define i32 @protected_vecfield(<2 x i32> %v, i32 %k, i1 %c) noinline optnone {
entry:
  call void @hikari_vmp()
  %p0 = insertvalue %vecfield poison, <2 x i32> %v, 0
  %p1 = insertvalue %vecfield %p0, i32 %k, 1
  %alt = insertvalue %vecfield zeroinitializer, <2 x i32> %v, 0
  %sel = select i1 %c, %vecfield %p1, %vecfield %alt
  br i1 %c, label %left, label %right

left:
  %lp = insertvalue %vecfield %sel, i32 1, 1
  br label %join

right:
  %rp = insertvalue %vecfield %sel, i32 2, 1
  br label %join

join:
  %phi = phi %vecfield [ %lp, %left ], [ %rp, %right ]
  store %vecfield %phi, ptr @slot.vec, align 8
  %ld = load %vecfield, ptr @slot.vec, align 8
  %called = call %vecfield @make_vecfield(<2 x i32> %v, i32 %k)
  %lv = extractvalue %vecfield %ld, 0
  %lk = extractvalue %vecfield %ld, 1
  %cv = extractvalue %vecfield %called, 0
  %ck = extractvalue %vecfield %called, 1
  %pv = extractvalue %vecfield %phi, 0
  %addv = add <2 x i32> %lv, %cv
  %mixv = xor <2 x i32> %addv, %pv
  %vr = call i32 @fold_i32x2(<2 x i32> %mixv)
  %kr = xor i32 %lk, %ck
  %out = xor i32 %vr, %kr
  ret i32 %out
}

define i32 @reference_varr(<2 x i32> %a, <2 x i32> %b) noinline optnone {
entry:
  %p0 = insertvalue %varr poison, <2 x i32> %a, 0
  %p1 = insertvalue %varr %p0, <2 x i32> %b, 1
  %x = extractvalue %varr %p1, 0
  %y = extractvalue %varr %p1, 1
  %z = xor <2 x i32> %x, %y
  %r = call i32 @fold_i32x2(<2 x i32> %z)
  ret i32 %r
}

define i32 @protected_varr(<2 x i32> %a, <2 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %p0 = insertvalue %varr poison, <2 x i32> %a, 0
  %p1 = insertvalue %varr %p0, <2 x i32> %b, 1
  %x = extractvalue %varr %p1, 0
  %y = extractvalue %varr %p1, 1
  %z = xor <2 x i32> %x, %y
  %r = call i32 @fold_i32x2(<2 x i32> %z)
  ret i32 %r
}

define i32 @reference_fvpair(<2 x float> %v, float %s) noinline optnone {
entry:
  %p0 = insertvalue %fvpair poison, <2 x float> %v, 0
  %p1 = insertvalue %fvpair %p0, float %s, 1
  %ev = extractvalue %fvpair %p1, 0
  %es = extractvalue %fvpair %p1, 1
  %e0 = extractelement <2 x float> %ev, i32 0
  %e1 = extractelement <2 x float> %ev, i32 1
  %t = fadd float %e0, %e1
  %u = fadd float %t, %es
  %bits = bitcast float %u to i32
  ret i32 %bits
}

define i32 @protected_fvpair(<2 x float> %v, float %s) noinline optnone {
entry:
  call void @hikari_vmp()
  %p0 = insertvalue %fvpair poison, <2 x float> %v, 0
  %p1 = insertvalue %fvpair %p0, float %s, 1
  %ev = extractvalue %fvpair %p1, 0
  %es = extractvalue %fvpair %p1, 1
  %e0 = extractelement <2 x float> %ev, i32 0
  %e1 = extractelement <2 x float> %ev, i32 1
  %t = fadd float %e0, %e1
  %u = fadd float %t, %es
  %bits = bitcast float %u to i32
  ret i32 %bits
}

define %pair @reference_ret_pair(i32 %a, i32 %b) noinline optnone {
entry:
  %p0 = insertvalue %pair poison, i32 %a, 0
  %p1 = insertvalue %pair %p0, i32 %b, 1
  ret %pair %p1
}

define %pair @protected_ret_pair(i32 %a, i32 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %p0 = insertvalue %pair poison, i32 %a, 0
  %p1 = insertvalue %pair %p0, i32 %b, 1
  ret %pair %p1
}

define %dd @reference_ret_dd(double %x, double %y) noinline optnone {
entry:
  %p0 = insertvalue %dd poison, double %x, 0
  %p1 = insertvalue %dd %p0, double %y, 1
  ret %dd %p1
}

define %dd @protected_ret_dd(double %x, double %y) noinline optnone {
entry:
  call void @hikari_vmp()
  %p0 = insertvalue %dd poison, double %x, 0
  %p1 = insertvalue %dd %p0, double %y, 1
  ret %dd %p1
}

define %vecfield @reference_ret_vecfield(<2 x i32> %v, i32 %k) noinline optnone {
entry:
  %p0 = insertvalue %vecfield poison, <2 x i32> %v, 0
  %p1 = insertvalue %vecfield %p0, i32 %k, 1
  ret %vecfield %p1
}

define %vecfield @protected_ret_vecfield(<2 x i32> %v, i32 %k) noinline optnone {
entry:
  call void @hikari_vmp()
  %p0 = insertvalue %vecfield poison, <2 x i32> %v, 0
  %p1 = insertvalue %vecfield %p0, i32 %k, 1
  ret %vecfield %p1
}

; ----- negatives -----

%nest = type { { %pair, i32 }, i32 }
%five = type { i32, i32, i32, i32, i32, i32, i32, i32, i32 }
%wide3 = type { i64, i64, i64, i64, i64, i64, i64, i64, i64 }
%widevec = type { <2 x i64>, <2 x i64>, <2 x i64>, <2 x i64>, i64 }
%scalefield = type { <vscale x 2 x i32>, i32 }
%non_natural_vec = type { <3 x i32> }
; {half,half} is a supported field pair.  Nine halfs exceed the
; 1..8 field cap (and 16 bytes) and stay rejected.


define i32 @unsupported_agg_nested(i32 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %n = insertvalue %nest poison, i32 %a, 1
  %e = extractvalue %nest %n, 1
  ret i32 %e
}

define i32 @unsupported_agg_five(i32 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %n = insertvalue %five poison, i32 %a, 0
  %e = extractvalue %five %n, 0
  ret i32 %e
}

define i32 @unsupported_agg_wide(i64 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %n = insertvalue %wide3 poison, i64 %a, 0
  %e = extractvalue %wide3 %n, 0
  %t = trunc i64 %e to i32
  ret i32 %t
}

define i32 @unsupported_agg_widevec(i32 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %w = zext i32 %a to i64
  %n = insertvalue %widevec poison, i64 %w, 4
  %e = extractvalue %widevec %n, 4
  %t = trunc i64 %e to i32
  ret i32 %t
}

define i32 @unsupported_agg_scalevec(i32 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %n = insertvalue %scalefield poison, i32 %a, 1
  %e = extractvalue %scalefield %n, 1
  ret i32 %e
}

define i32 @unsupported_agg_non_natural_vec(<3 x i32> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %n = insertvalue %non_natural_vec poison, <3 x i32> %v, 0
  %e = extractvalue %non_natural_vec %n, 0
  %t = extractelement <3 x i32> %e, i32 0
  ret i32 %t
}

; Matching C void sret-only calls are accepted on the dedicated
; isSupportedDirectSretCall path (vmp-sret-semantic.ll).  sret+byval
; stays a rejected complex ABI combination.
define void @sink_sret_byval(ptr sret(%pair) %p, ptr byval(%pair) %q) noinline {
entry:
  store %pair zeroinitializer, ptr %p, align 4
  ret void
}

; Matching C byval-only calls are accepted on isSupportedDirectByvalCall
; (vmp-byval-semantic.ll).  This file keeps a type-mismatched byval.
define void @sink_byval_i32(ptr byval(i32) %p) noinline {
entry:
  ret void
}

; Matching C byref-only calls are accepted on isSupportedDirectByrefCall
; (vmp-byref-semantic.ll).  This file keeps a type-mismatched byref.
define void @sink_byref_i32(ptr byref(i32) %p) noinline {
entry:
  ret void
}

define i32 @unsupported_agg_sret(ptr %p, ptr %q) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @sink_sret_byval(ptr sret(%pair) %p, ptr byval(%pair) %q)
  ret i32 0
}

define i32 @unsupported_agg_byval(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @sink_byval_i32(ptr byval(%pair) %p)
  ret i32 0
}

define i32 @unsupported_agg_byref(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @sink_byref_i32(ptr byref(%pair) %p)
  ret i32 0
}

define i32 @unsupported_agg_half(half %h) noinline optnone {
entry:
  call void @hikari_vmp()
  %n = insertvalue [9 x half] poison, half %h, 0
  %e = extractvalue [9 x half] %n, 0
  %b = bitcast half %e to i16
  %z = zext i16 %b to i32
  ret i32 %z
}

define i32 @main() {
entry:
  %cell = alloca i32, align 4
  store i32 7, ptr %cell, align 4
  %e0 = call i32 @reference_pair(i32 3, i32 5, i1 true)
  %a0 = call i32 @protected_pair(i32 3, i32 5, i1 true)
  %ok0 = icmp eq i32 %e0, %a0
  %e1 = call i32 @reference_pair(i32 9, i32 1, i1 false)
  %a1 = call i32 @protected_pair(i32 9, i32 1, i1 false)
  %ok1 = icmp eq i32 %e1, %a1
  %e2 = call i32 @reference_mixed(ptr %cell, i32 4)
  %a2 = call i32 @protected_mixed(ptr %cell, i32 4)
  %ok2 = icmp eq i32 %e2, %a2
  %arr0 = insertvalue [2 x i64] poison, i64 11, 0
  %arr1 = insertvalue [2 x i64] %arr0, i64 22, 1
  %e3 = call i32 @reference_array([2 x i64] %arr1)
  %a3 = call i32 @protected_array([2 x i64] %arr1)
  %ok3 = icmp eq i32 %e3, %a3
  %e4 = call i32 @reference_ff(float 1.500000e+00, float 2.250000e+00)
  %a4 = call i32 @protected_ff(float 1.500000e+00, float 2.250000e+00)
  %ok4 = icmp eq i32 %e4, %a4
  %vv0 = insertelement <2 x i32> poison, i32 4, i32 0
  %vv1 = insertelement <2 x i32> %vv0, i32 6, i32 1
  %ww0 = insertelement <2 x i32> poison, i32 8, i32 0
  %ww1 = insertelement <2 x i32> %ww0, i32 1, i32 1
  %e5 = call i32 @reference_vecfield(<2 x i32> %vv1, i32 9, i1 true)
  %a5 = call i32 @protected_vecfield(<2 x i32> %vv1, i32 9, i1 true)
  %ok5 = icmp eq i32 %e5, %a5
  %e6 = call i32 @reference_vecfield(<2 x i32> %vv1, i32 9, i1 false)
  %a6 = call i32 @protected_vecfield(<2 x i32> %vv1, i32 9, i1 false)
  %ok6 = icmp eq i32 %e6, %a6
  %e7 = call i32 @reference_varr(<2 x i32> %vv1, <2 x i32> %ww1)
  %a7 = call i32 @protected_varr(<2 x i32> %vv1, <2 x i32> %ww1)
  %ok7 = icmp eq i32 %e7, %a7
  %fv0 = insertelement <2 x float> poison, float 1.000000e+00, i32 0
  %fv1 = insertelement <2 x float> %fv0, float 3.000000e+00, i32 1
  %e8 = call i32 @reference_fvpair(<2 x float> %fv1, float 2.000000e+00)
  %a8 = call i32 @protected_fvpair(<2 x float> %fv1, float 2.000000e+00)
  %ok8 = icmp eq i32 %e8, %a8
  %erp = call %pair @reference_ret_pair(i32 3, i32 5)
  %arp = call %pair @protected_ret_pair(i32 3, i32 5)
  %erp0 = extractvalue %pair %erp, 0
  %erp1 = extractvalue %pair %erp, 1
  %arp0 = extractvalue %pair %arp, 0
  %arp1 = extractvalue %pair %arp, 1
  %ok9a = icmp eq i32 %erp0, %arp0
  %ok9b = icmp eq i32 %erp1, %arp1
  %ok9 = and i1 %ok9a, %ok9b
  %erd = call %dd @reference_ret_dd(double 1.500000e+00, double 2.250000e+00)
  %ard = call %dd @protected_ret_dd(double 1.500000e+00, double 2.250000e+00)
  %erd0 = extractvalue %dd %erd, 0
  %erd1 = extractvalue %dd %erd, 1
  %ard0 = extractvalue %dd %ard, 0
  %ard1 = extractvalue %dd %ard, 1
  %erd0i = bitcast double %erd0 to i64
  %erd1i = bitcast double %erd1 to i64
  %ard0i = bitcast double %ard0 to i64
  %ard1i = bitcast double %ard1 to i64
  %ok10a = icmp eq i64 %erd0i, %ard0i
  %ok10b = icmp eq i64 %erd1i, %ard1i
  %ok10 = and i1 %ok10a, %ok10b
  %erv = call %vecfield @reference_ret_vecfield(<2 x i32> %vv1, i32 9)
  %arv = call %vecfield @protected_ret_vecfield(<2 x i32> %vv1, i32 9)
  %ervv = extractvalue %vecfield %erv, 0
  %ervk = extractvalue %vecfield %erv, 1
  %arvv = extractvalue %vecfield %arv, 0
  %arvk = extractvalue %vecfield %arv, 1
  %erv0 = extractelement <2 x i32> %ervv, i32 0
  %erv1 = extractelement <2 x i32> %ervv, i32 1
  %arv0 = extractelement <2 x i32> %arvv, i32 0
  %arv1 = extractelement <2 x i32> %arvv, i32 1
  %ok11a = icmp eq i32 %erv0, %arv0
  %ok11b = icmp eq i32 %erv1, %arv1
  %ok11c = icmp eq i32 %ervk, %arvk
  %ok11d = and i1 %ok11a, %ok11b
  %ok11 = and i1 %ok11d, %ok11c
  %t0 = and i1 %ok0, %ok1
  %t1 = and i1 %ok2, %ok3
  %t2 = and i1 %ok4, %ok5
  %t3 = and i1 %ok6, %ok7
  %u0 = and i1 %t0, %t1
  %u1 = and i1 %t2, %t3
  %u2 = and i1 %u0, %u1
  %u3 = and i1 %ok8, %ok9
  %u4 = and i1 %ok10, %ok11
  %u5 = and i1 %u3, %u4
  %ok = and i1 %u2, %u5
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP-DAG: Skipping VMP on unsupported_agg_nested: unsupported aggregate instruction
; SKIP-DAG: Skipping VMP on unsupported_agg_five: unsupported aggregate instruction
; SKIP-DAG: Skipping VMP on unsupported_agg_wide: unsupported aggregate instruction
; SKIP-DAG: Skipping VMP on unsupported_agg_widevec: unsupported aggregate instruction
; SKIP-DAG: Skipping VMP on unsupported_agg_scalevec: unsupported aggregate instruction
; SKIP-DAG: Skipping VMP on unsupported_agg_non_natural_vec: unsupported aggregate instruction
; SKIP-DAG: Skipping VMP on unsupported_agg_sret: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_agg_byval: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_agg_byref: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_agg_half: unsupported aggregate instruction
; SKIP-O0-DAG: Skipping VMP on unsupported_agg_nested: unsupported aggregate instruction
; SKIP-NOT: Skipping VMP on protected_pair:
; SKIP-NOT: Skipping VMP on protected_mixed:
; SKIP-NOT: Skipping VMP on protected_array:
; SKIP-NOT: Skipping VMP on protected_ff:
; SKIP-NOT: Skipping VMP on protected_vecfield:
; SKIP-NOT: Skipping VMP on protected_varr:
; SKIP-NOT: Skipping VMP on protected_fvpair:
; SKIP-NOT: Skipping VMP on protected_ret_pair:
; SKIP-NOT: Skipping VMP on protected_ret_dd:
; SKIP-NOT: Skipping VMP on protected_ret_vecfield:


; VIRT-LABEL: define i32 @protected_pair(
; VIRT: %vmp.aregs = alloca [{{[0-9]+}} x [4 x i128]]
; VIRT: store volatile %pair
; VIRT: vmp.dispatch:
; VIRT-DAG: insertvalue %pair
; VIRT-DAG: extractvalue %pair
; VIRT-DAG: load volatile %pair,
; VIRT-DAG: store volatile %pair
; VIRT-DAG: call %pair @make_pair(
; VIRT-DAG: call i32 @sum_pair(%pair

; VIRT-LABEL: define i32 @protected_mixed(
; VIRT: vmp.dispatch:
; VIRT-DAG: insertvalue %mixed
; VIRT-DAG: extractvalue %mixed

; VIRT-LABEL: define i32 @protected_array(
; VIRT: vmp.dispatch:
; VIRT-DAG: extractvalue [2 x i64]

; VIRT-LABEL: define i32 @protected_ff(
; VIRT: vmp.dispatch:
; VIRT-DAG: insertvalue %ff
; VIRT-DAG: extractvalue %ff

; VIRT-LABEL: define i32 @protected_vecfield(
; VIRT: %vmp.vregs = alloca [{{[0-9]+}} x i128]
; VIRT: %vmp.aregs = alloca [{{[0-9]+}} x [4 x i128]]
; VIRT: store volatile %vecfield
; VIRT: bitcast <2 x i32> {{.*}} to i64
; VIRT: store volatile i128
; VIRT: vmp.dispatch:
; VIRT-DAG: insertvalue %vecfield
; VIRT-DAG: extractvalue %vecfield
; VIRT-DAG: load volatile %vecfield,
; VIRT-DAG: store volatile %vecfield
; VIRT-DAG: bitcast <2 x i32> {{.*}} to i64
; VIRT-DAG: call %vecfield @make_vecfield(

; VIRT-LABEL: define i32 @protected_varr(
; VIRT: vmp.dispatch:
; VIRT-DAG: insertvalue [2 x <2 x i32>]
; VIRT-DAG: extractvalue [2 x <2 x i32>]

; VIRT-LABEL: define i32 @protected_fvpair(
; VIRT: vmp.dispatch:
; VIRT-DAG: insertvalue %fvpair
; VIRT-DAG: extractvalue %fvpair

; VIRT-LABEL: define %pair @protected_ret_pair(
; VIRT: vmp.dispatch:
; VIRT: ret %pair

; VIRT-LABEL: define %dd @protected_ret_dd(
; VIRT: vmp.dispatch:
; VIRT: ret %dd

; VIRT-LABEL: define %vecfield @protected_ret_vecfield(
; VIRT: vmp.dispatch:
; VIRT: ret %vecfield

; VIRT: define {{.*}} @unsupported_agg_nested({{.*}} #[[UNSUPATTR:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_agg_five({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_agg_wide({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_agg_widevec({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_agg_scalevec({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_agg_non_natural_vec({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_agg_sret({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_agg_byval({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_agg_byref({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_agg_half({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #{{[0-9]+}} = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.virtualized"
