; Large flat aggregates on the expanded [4 x i128] aggregate slot
; (conservative alloc 1..64).  This is not a field-count-only leftover:
; {i32 x 5} (20), {i64 x 3} (24), {i64 x 4} (32), [8 x i64] (64),
; named {i64 x 8} (64), {<4 x i32>, i32} (32), and {double x 3} (24)
; must virtualize through vmp.aregs.  Same field types as the small
; surface (i1/i8/i16/i32/i64/AS0 ptr/half/f32/f64 or a fixed vector of
; width 8/16/32/64/128).  insertvalue/extractvalue, load/store,
; phi/select, ordinary direct C args/returns, and restricted indirect
; C replay.  Nested, leftover-width vector fields, 9+ fields,
; >64-byte layouts, reserved NEON/ld64b tuples that now size-match the
; slot, and i128 fields stay rejected.
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

%wide3 = type { i64, i64, i64 }
%fivei32 = type { i32, i32, i32, i32, i32 }
%quad64 = type { i64, i64, i64, i64 }
%octa64 = type { i64, i64, i64, i64, i64, i64, i64, i64 }
%widevec32 = type { <4 x i32>, i32 }
%dd3 = type { double, double, double }
%pair = type { i32, i32 }
%nest = type { { %pair, i32 }, i32 }
%leftover = type { <3 x i32> }
%i128field = type { i128 }
%oversize = type { <2 x i64>, <2 x i64>, <2 x i64>, <2 x i64>, i64 }

declare void @hikari_vmp()
declare { <8 x i8>, <8 x i8> } @llvm.aarch64.neon.ld1x2.v8i8.p0(ptr)
declare { <16 x i8>, <16 x i8> } @llvm.aarch64.neon.ld2.v16i8.p0(ptr)
declare { <16 x i8>, <16 x i8>, <16 x i8>, <16 x i8> } @llvm.aarch64.neon.ld4.v16i8.p0(ptr)
declare { i64, i64, i64, i64, i64, i64, i64, i64 } @llvm.aarch64.ld64b(ptr)

@slot.wide3 = private global %wide3 zeroinitializer, align 8
@slot.five = private global %fivei32 zeroinitializer, align 4
@slot.octa = private global [8 x i64] zeroinitializer, align 8
@slot.octa64 = private global %octa64 zeroinitializer, align 8
@slot.widevec32 = private global %widevec32 zeroinitializer, align 16
@slot.dd3 = private global %dd3 zeroinitializer, align 8

; ----- native helpers -----

define i32 @fold_wide3(%wide3 %p) {
entry:
  %a = extractvalue %wide3 %p, 0
  %b = extractvalue %wide3 %p, 1
  %c = extractvalue %wide3 %p, 2
  %x = xor i64 %a, %b
  %y = xor i64 %x, %c
  %r = trunc i64 %y to i32
  ret i32 %r
}

define i32 @fold_fivei32(%fivei32 %p) {
entry:
  %a = extractvalue %fivei32 %p, 0
  %b = extractvalue %fivei32 %p, 1
  %c = extractvalue %fivei32 %p, 2
  %d = extractvalue %fivei32 %p, 3
  %e = extractvalue %fivei32 %p, 4
  %x0 = xor i32 %a, %b
  %x1 = xor i32 %c, %d
  %x2 = xor i32 %x0, %x1
  %r = xor i32 %x2, %e
  ret i32 %r
}

define i32 @fold_quad64(%quad64 %p) {
entry:
  %a = extractvalue %quad64 %p, 0
  %b = extractvalue %quad64 %p, 1
  %c = extractvalue %quad64 %p, 2
  %d = extractvalue %quad64 %p, 3
  %x0 = xor i64 %a, %b
  %x1 = xor i64 %c, %d
  %y = xor i64 %x0, %x1
  %r = trunc i64 %y to i32
  ret i32 %r
}

define i32 @fold_octa([8 x i64] %p) {
entry:
  %e0 = extractvalue [8 x i64] %p, 0
  %e1 = extractvalue [8 x i64] %p, 1
  %e2 = extractvalue [8 x i64] %p, 2
  %e3 = extractvalue [8 x i64] %p, 3
  %e4 = extractvalue [8 x i64] %p, 4
  %e5 = extractvalue [8 x i64] %p, 5
  %e6 = extractvalue [8 x i64] %p, 6
  %e7 = extractvalue [8 x i64] %p, 7
  %x0 = xor i64 %e0, %e1
  %x1 = xor i64 %e2, %e3
  %x2 = xor i64 %e4, %e5
  %x3 = xor i64 %e6, %e7
  %y0 = xor i64 %x0, %x1
  %y1 = xor i64 %x2, %x3
  %z = xor i64 %y0, %y1
  %r = trunc i64 %z to i32
  ret i32 %r
}

define %wide3 @swap_wide3(%wide3 %p) noinline {
entry:
  %a = extractvalue %wide3 %p, 0
  %c = extractvalue %wide3 %p, 2
  %q0 = insertvalue %wide3 %p, i64 %c, 0
  %q1 = insertvalue %wide3 %q0, i64 %a, 2
  ret %wide3 %q1
}

define %wide3 @rot_wide3(%wide3 %p) noinline {
entry:
  %a = extractvalue %wide3 %p, 0
  %b = extractvalue %wide3 %p, 1
  %q0 = insertvalue %wide3 %p, i64 %b, 0
  %q1 = insertvalue %wide3 %q0, i64 %a, 1
  ret %wide3 %q1
}

define %wide3 @make_wide3(i64 %a, i64 %b, i64 %c) {
entry:
  %p0 = insertvalue %wide3 poison, i64 %a, 0
  %p1 = insertvalue %wide3 %p0, i64 %b, 1
  %p2 = insertvalue %wide3 %p1, i64 %c, 2
  ret %wide3 %p2
}

define i32 @fold_octa64(%octa64 %p) {
entry:
  %e0 = extractvalue %octa64 %p, 0
  %e1 = extractvalue %octa64 %p, 1
  %e2 = extractvalue %octa64 %p, 2
  %e3 = extractvalue %octa64 %p, 3
  %e4 = extractvalue %octa64 %p, 4
  %e5 = extractvalue %octa64 %p, 5
  %e6 = extractvalue %octa64 %p, 6
  %e7 = extractvalue %octa64 %p, 7
  %x0 = xor i64 %e0, %e1
  %x1 = xor i64 %e2, %e3
  %x2 = xor i64 %e4, %e5
  %x3 = xor i64 %e6, %e7
  %y0 = xor i64 %x0, %x1
  %y1 = xor i64 %x2, %x3
  %z = xor i64 %y0, %y1
  %r = trunc i64 %z to i32
  ret i32 %r
}

define %octa64 @swap_octa64(%octa64 %p) noinline {
entry:
  %a = extractvalue %octa64 %p, 0
  %h = extractvalue %octa64 %p, 7
  %q0 = insertvalue %octa64 %p, i64 %h, 0
  %q1 = insertvalue %octa64 %q0, i64 %a, 7
  ret %octa64 %q1
}

define %octa64 @make_octa64(i64 %a, i64 %b) {
entry:
  %p0 = insertvalue %octa64 poison, i64 %a, 0
  %p1 = insertvalue %octa64 %p0, i64 %b, 1
  %p2 = insertvalue %octa64 %p1, i64 2, 2
  %p3 = insertvalue %octa64 %p2, i64 3, 3
  %p4 = insertvalue %octa64 %p3, i64 4, 4
  %p5 = insertvalue %octa64 %p4, i64 5, 5
  %p6 = insertvalue %octa64 %p5, i64 6, 6
  %p7 = insertvalue %octa64 %p6, i64 7, 7
  ret %octa64 %p7
}

define i32 @fold_widevec32(%widevec32 %p) {
entry:
  %v = extractvalue %widevec32 %p, 0
  %k = extractvalue %widevec32 %p, 1
  %e0 = extractelement <4 x i32> %v, i32 0
  %e1 = extractelement <4 x i32> %v, i32 1
  %e2 = extractelement <4 x i32> %v, i32 2
  %e3 = extractelement <4 x i32> %v, i32 3
  %x0 = xor i32 %e0, %e1
  %x1 = xor i32 %e2, %e3
  %x2 = xor i32 %x0, %x1
  %r = xor i32 %x2, %k
  ret i32 %r
}

define i32 @fold_dd3(%dd3 %p) {
entry:
  %a = extractvalue %dd3 %p, 0
  %b = extractvalue %dd3 %p, 1
  %c = extractvalue %dd3 %p, 2
  %ia = bitcast double %a to i64
  %ib = bitcast double %b to i64
  %ic = bitcast double %c to i64
  %x = xor i64 %ia, %ib
  %y = xor i64 %x, %ic
  %r = trunc i64 %y to i32
  ret i32 %r
}

; ----- 24-byte {i64,i64,i64}: select / diamond phi / load / store / call -----

define i32 @reference_wide3(i64 %a, i64 %b, i64 %c, i1 %p) noinline optnone {
entry:
  %v0 = insertvalue %wide3 poison, i64 %a, 0
  %v1 = insertvalue %wide3 %v0, i64 %b, 1
  %v2 = insertvalue %wide3 %v1, i64 %c, 2
  %alt = insertvalue %wide3 zeroinitializer, i64 %a, 0
  %sel = select i1 %p, %wide3 %v2, %wide3 %alt
  br i1 %p, label %left, label %right

left:
  %lp = insertvalue %wide3 %sel, i64 9, 2
  br label %join

right:
  %rp = insertvalue %wide3 %sel, i64 11, 2
  br label %join

join:
  %phi = phi %wide3 [ %lp, %left ], [ %rp, %right ]
  store %wide3 %phi, ptr @slot.wide3, align 8
  %ld = load %wide3, ptr @slot.wide3, align 8
  %sw = call %wide3 @swap_wide3(%wide3 %ld)
  %s0 = call i32 @fold_wide3(%wide3 %ld)
  %s1 = call i32 @fold_wide3(%wide3 %sw)
  %e0 = extractvalue %wide3 %ld, 0
  %e2 = extractvalue %wide3 %phi, 2
  %t0 = trunc i64 %e0 to i32
  %t2 = trunc i64 %e2 to i32
  %x0 = xor i32 %s0, %s1
  %x1 = xor i32 %t0, %t2
  %out = xor i32 %x0, %x1
  ret i32 %out
}

define i32 @protected_wide3(i64 %a, i64 %b, i64 %c, i1 %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %v0 = insertvalue %wide3 poison, i64 %a, 0
  %v1 = insertvalue %wide3 %v0, i64 %b, 1
  %v2 = insertvalue %wide3 %v1, i64 %c, 2
  %alt = insertvalue %wide3 zeroinitializer, i64 %a, 0
  %sel = select i1 %p, %wide3 %v2, %wide3 %alt
  br i1 %p, label %left, label %right

left:
  %lp = insertvalue %wide3 %sel, i64 9, 2
  br label %join

right:
  %rp = insertvalue %wide3 %sel, i64 11, 2
  br label %join

join:
  %phi = phi %wide3 [ %lp, %left ], [ %rp, %right ]
  store %wide3 %phi, ptr @slot.wide3, align 8
  %ld = load %wide3, ptr @slot.wide3, align 8
  %sw = call %wide3 @swap_wide3(%wide3 %ld)
  %s0 = call i32 @fold_wide3(%wide3 %ld)
  %s1 = call i32 @fold_wide3(%wide3 %sw)
  %e0 = extractvalue %wide3 %ld, 0
  %e2 = extractvalue %wide3 %phi, 2
  %t0 = trunc i64 %e0 to i32
  %t2 = trunc i64 %e2 to i32
  %x0 = xor i32 %s0, %s1
  %x1 = xor i32 %t0, %t2
  %out = xor i32 %x0, %x1
  ret i32 %out
}

; ----- 20-byte {i32 x 5} -----

define i32 @reference_fivei32(i32 %a, i32 %b) noinline optnone {
entry:
  %p0 = insertvalue %fivei32 poison, i32 %a, 0
  %p1 = insertvalue %fivei32 %p0, i32 %b, 1
  %p2 = insertvalue %fivei32 %p1, i32 3, 2
  %p3 = insertvalue %fivei32 %p2, i32 5, 3
  %p4 = insertvalue %fivei32 %p3, i32 7, 4
  store %fivei32 %p4, ptr @slot.five, align 4
  %ld = load %fivei32, ptr @slot.five, align 4
  %r = call i32 @fold_fivei32(%fivei32 %ld)
  ret i32 %r
}

define i32 @protected_fivei32(i32 %a, i32 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %p0 = insertvalue %fivei32 poison, i32 %a, 0
  %p1 = insertvalue %fivei32 %p0, i32 %b, 1
  %p2 = insertvalue %fivei32 %p1, i32 3, 2
  %p3 = insertvalue %fivei32 %p2, i32 5, 3
  %p4 = insertvalue %fivei32 %p3, i32 7, 4
  store %fivei32 %p4, ptr @slot.five, align 4
  %ld = load %fivei32, ptr @slot.five, align 4
  %r = call i32 @fold_fivei32(%fivei32 %ld)
  ret i32 %r
}

; ----- 32-byte {i64 x 4} -----

define i32 @reference_quad64(i64 %a, i64 %b) noinline optnone {
entry:
  %p0 = insertvalue %quad64 poison, i64 %a, 0
  %p1 = insertvalue %quad64 %p0, i64 %b, 1
  %p2 = insertvalue %quad64 %p1, i64 3, 2
  %p3 = insertvalue %quad64 %p2, i64 5, 3
  %r = call i32 @fold_quad64(%quad64 %p3)
  ret i32 %r
}

define i32 @protected_quad64(i64 %a, i64 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %p0 = insertvalue %quad64 poison, i64 %a, 0
  %p1 = insertvalue %quad64 %p0, i64 %b, 1
  %p2 = insertvalue %quad64 %p1, i64 3, 2
  %p3 = insertvalue %quad64 %p2, i64 5, 3
  %r = call i32 @fold_quad64(%quad64 %p3)
  ret i32 %r
}

; ----- 64-byte [8 x i64] fills the slot -----

define i32 @reference_octa(i64 %a, i64 %b) noinline optnone {
entry:
  %p0 = insertvalue [8 x i64] poison, i64 %a, 0
  %p1 = insertvalue [8 x i64] %p0, i64 %b, 1
  %p2 = insertvalue [8 x i64] %p1, i64 2, 2
  %p3 = insertvalue [8 x i64] %p2, i64 3, 3
  %p4 = insertvalue [8 x i64] %p3, i64 4, 4
  %p5 = insertvalue [8 x i64] %p4, i64 5, 5
  %p6 = insertvalue [8 x i64] %p5, i64 6, 6
  %p7 = insertvalue [8 x i64] %p6, i64 7, 7
  store [8 x i64] %p7, ptr @slot.octa, align 8
  %ld = load [8 x i64], ptr @slot.octa, align 8
  %r = call i32 @fold_octa([8 x i64] %ld)
  ret i32 %r
}

define i32 @protected_octa(i64 %a, i64 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %p0 = insertvalue [8 x i64] poison, i64 %a, 0
  %p1 = insertvalue [8 x i64] %p0, i64 %b, 1
  %p2 = insertvalue [8 x i64] %p1, i64 2, 2
  %p3 = insertvalue [8 x i64] %p2, i64 3, 3
  %p4 = insertvalue [8 x i64] %p3, i64 4, 4
  %p5 = insertvalue [8 x i64] %p4, i64 5, 5
  %p6 = insertvalue [8 x i64] %p5, i64 6, 6
  %p7 = insertvalue [8 x i64] %p6, i64 7, 7
  store [8 x i64] %p7, ptr @slot.octa, align 8
  %ld = load [8 x i64], ptr @slot.octa, align 8
  %r = call i32 @fold_octa([8 x i64] %ld)
  ret i32 %r
}

; ----- [8 x i64] diamond join (not a loop): select [8 x i64] / phi [8 x i64] -----

define i32 @reference_phi_8xi64(i64 %a, i64 %b, i1 %c) noinline optnone {
entry:
  %p0 = insertvalue [8 x i64] poison, i64 %a, 0
  %p1 = insertvalue [8 x i64] %p0, i64 %b, 1
  %p2 = insertvalue [8 x i64] %p1, i64 2, 2
  %p3 = insertvalue [8 x i64] %p2, i64 3, 3
  %p4 = insertvalue [8 x i64] %p3, i64 4, 4
  %p5 = insertvalue [8 x i64] %p4, i64 5, 5
  %p6 = insertvalue [8 x i64] %p5, i64 6, 6
  %p7 = insertvalue [8 x i64] %p6, i64 7, 7
  %alt = insertvalue [8 x i64] zeroinitializer, i64 %a, 0
  %sel = select i1 %c, [8 x i64] %p7, [8 x i64] %alt
  br i1 %c, label %left, label %right

left:
  %lp = insertvalue [8 x i64] %sel, i64 9, 7
  br label %join

right:
  %rp = insertvalue [8 x i64] %sel, i64 11, 7
  br label %join

join:
  %phi = phi [8 x i64] [ %lp, %left ], [ %rp, %right ]
  store [8 x i64] %phi, ptr @slot.octa, align 8
  %ld = load [8 x i64], ptr @slot.octa, align 8
  %r = call i32 @fold_octa([8 x i64] %ld)
  ret i32 %r
}

define i32 @protected_phi_8xi64(i64 %a, i64 %b, i1 %c) noinline optnone {
entry:
  call void @hikari_vmp()
  %p0 = insertvalue [8 x i64] poison, i64 %a, 0
  %p1 = insertvalue [8 x i64] %p0, i64 %b, 1
  %p2 = insertvalue [8 x i64] %p1, i64 2, 2
  %p3 = insertvalue [8 x i64] %p2, i64 3, 3
  %p4 = insertvalue [8 x i64] %p3, i64 4, 4
  %p5 = insertvalue [8 x i64] %p4, i64 5, 5
  %p6 = insertvalue [8 x i64] %p5, i64 6, 6
  %p7 = insertvalue [8 x i64] %p6, i64 7, 7
  %alt = insertvalue [8 x i64] zeroinitializer, i64 %a, 0
  %sel = select i1 %c, [8 x i64] %p7, [8 x i64] %alt
  br i1 %c, label %left, label %right

left:
  %lp = insertvalue [8 x i64] %sel, i64 9, 7
  br label %join

right:
  %rp = insertvalue [8 x i64] %sel, i64 11, 7
  br label %join

join:
  %phi = phi [8 x i64] [ %lp, %left ], [ %rp, %right ]
  store [8 x i64] %phi, ptr @slot.octa, align 8
  %ld = load [8 x i64], ptr @slot.octa, align 8
  %r = call i32 @fold_octa([8 x i64] %ld)
  ret i32 %r
}

; ----- [8 x i64] back-edge loop phi (not a diamond join) -----

define i32 @reference_loopphi_8xi64(i64 %n) noinline optnone {
entry:
  %init = insertvalue [8 x i64] zeroinitializer, i64 %n, 0
  br label %loop

loop:
  %acc = phi [8 x i64] [ %init, %entry ], [ %next, %loop ]
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %cur = extractvalue [8 x i64] %acc, 0
  %inc = add i64 %cur, 1
  %next = insertvalue [8 x i64] %acc, i64 %inc, 0
  %i1 = add i32 %i, 1
  %c = icmp slt i32 %i1, 3
  br i1 %c, label %loop, label %done

done:
  %r = call i32 @fold_octa([8 x i64] %next)
  ret i32 %r
}

define i32 @protected_loopphi_8xi64(i64 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  %init = insertvalue [8 x i64] zeroinitializer, i64 %n, 0
  br label %loop

loop:
  %acc = phi [8 x i64] [ %init, %entry ], [ %next, %loop ]
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %cur = extractvalue [8 x i64] %acc, 0
  %inc = add i64 %cur, 1
  %next = insertvalue [8 x i64] %acc, i64 %inc, 0
  %i1 = add i32 %i, 1
  %c = icmp slt i32 %i1, 3
  br i1 %c, label %loop, label %done

done:
  %r = call i32 @fold_octa([8 x i64] %next)
  ret i32 %r
}

; ----- 24-byte aggregate return -----

define %wide3 @reference_ret_wide3(i64 %a, i64 %b, i64 %c) noinline optnone {
entry:
  %p0 = insertvalue %wide3 poison, i64 %a, 0
  %p1 = insertvalue %wide3 %p0, i64 %b, 1
  %p2 = insertvalue %wide3 %p1, i64 %c, 2
  ret %wide3 %p2
}

define %wide3 @protected_ret_wide3(i64 %a, i64 %b, i64 %c) noinline optnone {
entry:
  call void @hikari_vmp()
  %p0 = insertvalue %wide3 poison, i64 %a, 0
  %p1 = insertvalue %wide3 %p0, i64 %b, 1
  %p2 = insertvalue %wide3 %p1, i64 %c, 2
  ret %wide3 %p2
}

; ----- restricted indirect C call of a 24-byte aggregate -----

define %wide3 @reference_indirect(ptr %fp, %wide3 %p) noinline optnone {
entry:
  %r = call %wide3 %fp(%wide3 %p)
  ret %wide3 %r
}

define %wide3 @protected_indirect(ptr %fp, %wide3 %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call %wide3 %fp(%wide3 %p)
  ret %wide3 %r
}

; ----- back-edge loop phi on 24-byte aggregate -----

define i32 @reference_loopphi_wide3(i64 %n) noinline optnone {
entry:
  %init = insertvalue %wide3 zeroinitializer, i64 %n, 0
  br label %loop

loop:
  %acc = phi %wide3 [ %init, %entry ], [ %next, %loop ]
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %cur = extractvalue %wide3 %acc, 0
  %inc = add i64 %cur, 1
  %next = insertvalue %wide3 %acc, i64 %inc, 0
  %i1 = add i32 %i, 1
  %c = icmp slt i32 %i1, 3
  br i1 %c, label %loop, label %done

done:
  %r = call i32 @fold_wide3(%wide3 %next)
  ret i32 %r
}

define i32 @protected_loopphi_wide3(i64 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  %init = insertvalue %wide3 zeroinitializer, i64 %n, 0
  br label %loop

loop:
  %acc = phi %wide3 [ %init, %entry ], [ %next, %loop ]
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %cur = extractvalue %wide3 %acc, 0
  %inc = add i64 %cur, 1
  %next = insertvalue %wide3 %acc, i64 %inc, 0
  %i1 = add i32 %i, 1
  %c = icmp slt i32 %i1, 3
  br i1 %c, label %loop, label %done

done:
  %r = call i32 @fold_wide3(%wide3 %next)
  ret i32 %r
}

; ----- 64-byte named {i64 x 8}: select / diamond join (not a loop) / load / store -----

define i32 @reference_octa64(i64 %a, i64 %b, i1 %p) noinline optnone {
entry:
  %v0 = insertvalue %octa64 poison, i64 %a, 0
  %v1 = insertvalue %octa64 %v0, i64 %b, 1
  %v2 = insertvalue %octa64 %v1, i64 2, 2
  %v3 = insertvalue %octa64 %v2, i64 3, 3
  %v4 = insertvalue %octa64 %v3, i64 4, 4
  %v5 = insertvalue %octa64 %v4, i64 5, 5
  %v6 = insertvalue %octa64 %v5, i64 6, 6
  %v7 = insertvalue %octa64 %v6, i64 7, 7
  %alt = insertvalue %octa64 zeroinitializer, i64 %a, 0
  %sel = select i1 %p, %octa64 %v7, %octa64 %alt
  br i1 %p, label %left, label %right

left:
  %lp = insertvalue %octa64 %sel, i64 9, 7
  br label %join

right:
  %rp = insertvalue %octa64 %sel, i64 11, 7
  br label %join

join:
  %phi = phi %octa64 [ %lp, %left ], [ %rp, %right ]
  store %octa64 %phi, ptr @slot.octa64, align 8
  %ld = load %octa64, ptr @slot.octa64, align 8
  %sw = call %octa64 @swap_octa64(%octa64 %ld)
  %s0 = call i32 @fold_octa64(%octa64 %ld)
  %s1 = call i32 @fold_octa64(%octa64 %sw)
  %e0 = extractvalue %octa64 %ld, 0
  %e7 = extractvalue %octa64 %phi, 7
  %t0 = trunc i64 %e0 to i32
  %t7 = trunc i64 %e7 to i32
  %x0 = xor i32 %s0, %s1
  %x1 = xor i32 %t0, %t7
  %out = xor i32 %x0, %x1
  ret i32 %out
}

define i32 @protected_octa64(i64 %a, i64 %b, i1 %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %v0 = insertvalue %octa64 poison, i64 %a, 0
  %v1 = insertvalue %octa64 %v0, i64 %b, 1
  %v2 = insertvalue %octa64 %v1, i64 2, 2
  %v3 = insertvalue %octa64 %v2, i64 3, 3
  %v4 = insertvalue %octa64 %v3, i64 4, 4
  %v5 = insertvalue %octa64 %v4, i64 5, 5
  %v6 = insertvalue %octa64 %v5, i64 6, 6
  %v7 = insertvalue %octa64 %v6, i64 7, 7
  %alt = insertvalue %octa64 zeroinitializer, i64 %a, 0
  %sel = select i1 %p, %octa64 %v7, %octa64 %alt
  br i1 %p, label %left, label %right

left:
  %lp = insertvalue %octa64 %sel, i64 9, 7
  br label %join

right:
  %rp = insertvalue %octa64 %sel, i64 11, 7
  br label %join

join:
  %phi = phi %octa64 [ %lp, %left ], [ %rp, %right ]
  store %octa64 %phi, ptr @slot.octa64, align 8
  %ld = load %octa64, ptr @slot.octa64, align 8
  %sw = call %octa64 @swap_octa64(%octa64 %ld)
  %s0 = call i32 @fold_octa64(%octa64 %ld)
  %s1 = call i32 @fold_octa64(%octa64 %sw)
  %e0 = extractvalue %octa64 %ld, 0
  %e7 = extractvalue %octa64 %phi, 7
  %t0 = trunc i64 %e0 to i32
  %t7 = trunc i64 %e7 to i32
  %x0 = xor i32 %s0, %s1
  %x1 = xor i32 %t0, %t7
  %out = xor i32 %x0, %x1
  ret i32 %out
}

; ----- back-edge loop phi on the 64-byte named struct (not a diamond join) -----

define i32 @reference_loopphi_octa64(i64 %n) noinline optnone {
entry:
  %init = insertvalue %octa64 zeroinitializer, i64 %n, 0
  br label %loop

loop:
  %acc = phi %octa64 [ %init, %entry ], [ %next, %loop ]
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %cur = extractvalue %octa64 %acc, 0
  %inc = add i64 %cur, 1
  %next = insertvalue %octa64 %acc, i64 %inc, 0
  %i1 = add i32 %i, 1
  %c = icmp slt i32 %i1, 3
  br i1 %c, label %loop, label %done

done:
  %r = call i32 @fold_octa64(%octa64 %next)
  ret i32 %r
}

define i32 @protected_loopphi_octa64(i64 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  %init = insertvalue %octa64 zeroinitializer, i64 %n, 0
  br label %loop

loop:
  %acc = phi %octa64 [ %init, %entry ], [ %next, %loop ]
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %cur = extractvalue %octa64 %acc, 0
  %inc = add i64 %cur, 1
  %next = insertvalue %octa64 %acc, i64 %inc, 0
  %i1 = add i32 %i, 1
  %c = icmp slt i32 %i1, 3
  br i1 %c, label %loop, label %done

done:
  %r = call i32 @fold_octa64(%octa64 %next)
  ret i32 %r
}

; ----- 64-byte named-struct return and restricted indirect C call -----

define %octa64 @reference_ret_octa64(i64 %a, i64 %b) noinline optnone {
entry:
  %r = call %octa64 @make_octa64(i64 %a, i64 %b)
  ret %octa64 %r
}

define %octa64 @protected_ret_octa64(i64 %a, i64 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call %octa64 @make_octa64(i64 %a, i64 %b)
  ret %octa64 %r
}

define %octa64 @reference_indirect_octa64(ptr %fp, %octa64 %p) noinline optnone {
entry:
  %r = call %octa64 %fp(%octa64 %p)
  ret %octa64 %r
}

define %octa64 @protected_indirect_octa64(ptr %fp, %octa64 %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call %octa64 %fp(%octa64 %p)
  ret %octa64 %r
}

; ----- 32-byte {<4 x i32>, i32}: newly size-legal vector field in the 64-byte slot -----

define i32 @reference_widevec32(<4 x i32> %v, i32 %k) noinline optnone {
entry:
  %p0 = insertvalue %widevec32 poison, <4 x i32> %v, 0
  %p1 = insertvalue %widevec32 %p0, i32 %k, 1
  store %widevec32 %p1, ptr @slot.widevec32, align 16
  %ld = load %widevec32, ptr @slot.widevec32, align 16
  %r = call i32 @fold_widevec32(%widevec32 %ld)
  ret i32 %r
}

define i32 @protected_widevec32(<4 x i32> %v, i32 %k) noinline optnone {
entry:
  call void @hikari_vmp()
  %p0 = insertvalue %widevec32 poison, <4 x i32> %v, 0
  %p1 = insertvalue %widevec32 %p0, i32 %k, 1
  store %widevec32 %p1, ptr @slot.widevec32, align 16
  %ld = load %widevec32, ptr @slot.widevec32, align 16
  %r = call i32 @fold_widevec32(%widevec32 %ld)
  ret i32 %r
}

; ----- 24-byte {double x 3} in the 64-byte slot -----

define i32 @reference_dd3(double %a, double %b, double %c) noinline optnone {
entry:
  %p0 = insertvalue %dd3 poison, double %a, 0
  %p1 = insertvalue %dd3 %p0, double %b, 1
  %p2 = insertvalue %dd3 %p1, double %c, 2
  store %dd3 %p2, ptr @slot.dd3, align 8
  %ld = load %dd3, ptr @slot.dd3, align 8
  %r = call i32 @fold_dd3(%dd3 %ld)
  ret i32 %r
}

define i32 @protected_dd3(double %a, double %b, double %c) noinline optnone {
entry:
  call void @hikari_vmp()
  %p0 = insertvalue %dd3 poison, double %a, 0
  %p1 = insertvalue %dd3 %p0, double %b, 1
  %p2 = insertvalue %dd3 %p1, double %c, 2
  store %dd3 %p2, ptr @slot.dd3, align 8
  %ld = load %dd3, ptr @slot.dd3, align 8
  %r = call i32 @fold_dd3(%dd3 %ld)
  ret i32 %r
}

; ----- negatives: safety rejects stay closed -----

define i32 @unsupported_agg_nine(i8 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %n = insertvalue [9 x i8] poison, i8 %a, 0
  %e = extractvalue [9 x i8] %n, 0
  %z = zext i8 %e to i32
  ret i32 %z
}

define i32 @unsupported_agg_oversize(i64 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %n = insertvalue %oversize poison, i64 %a, 4
  %e = extractvalue %oversize %n, 4
  %t = trunc i64 %e to i32
  ret i32 %t
}

define i32 @unsupported_agg_nested(i32 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %n = insertvalue %nest poison, i32 %a, 1
  %e = extractvalue %nest %n, 1
  ret i32 %e
}

define i32 @unsupported_agg_leftover(<3 x i32> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %n = insertvalue %leftover poison, <3 x i32> %v, 0
  %e = extractvalue %leftover %n, 0
  %t = extractelement <3 x i32> %e, i32 0
  ret i32 %t
}

define i32 @unsupported_agg_i128(i128 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %n = insertvalue %i128field poison, i128 %x, 0
  %e = extractvalue %i128field %n, 0
  %t = trunc i128 %e to i32
  ret i32 %t
}

; 16-byte NEON pair must stay a reserved producer: whole-tuple store
; is never the ordinary 1..64-byte aggregate frame.
define void @unsupported_neon_ld2_store_tuple(ptr %p, ptr %q) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <8 x i8>, <8 x i8> } @llvm.aarch64.neon.ld1x2.v8i8.p0(ptr %p)
  store { <8 x i8>, <8 x i8> } %t, ptr %q, align 8
  ret void
}

; 32-byte NEON pair now size-matches the slot; whole tuple still must skip.
define void @unsupported_neon_ld2_v16_store_tuple(ptr %p, ptr %q) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <16 x i8>, <16 x i8> } @llvm.aarch64.neon.ld2.v16i8.p0(ptr %p)
  store { <16 x i8>, <16 x i8> } %t, ptr %q, align 16
  ret void
}

; 64-byte NEON ld4 now size-matches the slot; whole tuple still must skip.
define void @unsupported_neon_ld4_v16_store_tuple(ptr %p, ptr %q) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <16 x i8>, <16 x i8>, <16 x i8>, <16 x i8> } @llvm.aarch64.neon.ld4.v16i8.p0(ptr %p)
  store { <16 x i8>, <16 x i8>, <16 x i8>, <16 x i8> } %t, ptr %q, align 16
  ret void
}

; {i64 x 8} ld64b is exactly 64 bytes / 8 fields.  Whole-tuple store must
; stay exploded, not occupy the expanded aggregate slot.
define void @unsupported_ld64b_store_tuple(ptr %p, ptr %q) noinline optnone "target-features"="+ls64" {
entry:
  call void @hikari_vmp()
  %t = call { i64, i64, i64, i64, i64, i64, i64, i64 } @llvm.aarch64.ld64b(ptr %p)
  store { i64, i64, i64, i64, i64, i64, i64, i64 } %t, ptr %q
  ret void
}

define i32 @main() {
entry:
  %e0 = call i32 @reference_wide3(i64 1, i64 2, i64 3, i1 true)
  %a0 = call i32 @protected_wide3(i64 1, i64 2, i64 3, i1 true)
  %ok0 = icmp eq i32 %e0, %a0
  %e1 = call i32 @reference_wide3(i64 9, i64 8, i64 7, i1 false)
  %a1 = call i32 @protected_wide3(i64 9, i64 8, i64 7, i1 false)
  %ok1 = icmp eq i32 %e1, %a1
  %e2 = call i32 @reference_fivei32(i32 4, i32 6)
  %a2 = call i32 @protected_fivei32(i32 4, i32 6)
  %ok2 = icmp eq i32 %e2, %a2
  %e3 = call i32 @reference_quad64(i64 10, i64 20)
  %a3 = call i32 @protected_quad64(i64 10, i64 20)
  %ok3 = icmp eq i32 %e3, %a3
  %e4 = call i32 @reference_octa(i64 11, i64 13)
  %a4 = call i32 @protected_octa(i64 11, i64 13)
  %ok4 = icmp eq i32 %e4, %a4
  %er = call %wide3 @reference_ret_wide3(i64 1, i64 2, i64 3)
  %ar = call %wide3 @protected_ret_wide3(i64 1, i64 2, i64 3)
  %fr = call i32 @fold_wide3(%wide3 %er)
  %fa = call i32 @fold_wide3(%wide3 %ar)
  %ok5 = icmp eq i32 %fr, %fa
  %seed = call %wide3 @make_wide3(i64 3, i64 4, i64 5)
  %ei = call %wide3 @reference_indirect(ptr @swap_wide3, %wide3 %seed)
  %ai = call %wide3 @protected_indirect(ptr @swap_wide3, %wide3 %seed)
  %fi = call i32 @fold_wide3(%wide3 %ei)
  %fj = call i32 @fold_wide3(%wide3 %ai)
  %ok6 = icmp eq i32 %fi, %fj
  %el = call i32 @reference_loopphi_wide3(i64 10)
  %al = call i32 @protected_loopphi_wide3(i64 10)
  %ok7 = icmp eq i32 %el, %al
  %e8 = call i32 @reference_octa64(i64 1, i64 2, i1 true)
  %a8 = call i32 @protected_octa64(i64 1, i64 2, i1 true)
  %ok8 = icmp eq i32 %e8, %a8
  %e9 = call i32 @reference_octa64(i64 3, i64 4, i1 false)
  %a9 = call i32 @protected_octa64(i64 3, i64 4, i1 false)
  %ok9 = icmp eq i32 %e9, %a9
  %e10 = call i32 @reference_loopphi_octa64(i64 10)
  %a10 = call i32 @protected_loopphi_octa64(i64 10)
  %ok10 = icmp eq i32 %e10, %a10
  %ero = call %octa64 @reference_ret_octa64(i64 1, i64 2)
  %aro = call %octa64 @protected_ret_octa64(i64 1, i64 2)
  %fro = call i32 @fold_octa64(%octa64 %ero)
  %fao = call i32 @fold_octa64(%octa64 %aro)
  %ok11 = icmp eq i32 %fro, %fao
  %seedo = call %octa64 @make_octa64(i64 3, i64 4)
  %eio = call %octa64 @reference_indirect_octa64(ptr @swap_octa64, %octa64 %seedo)
  %aio = call %octa64 @protected_indirect_octa64(ptr @swap_octa64, %octa64 %seedo)
  %fio = call i32 @fold_octa64(%octa64 %eio)
  %fjo = call i32 @fold_octa64(%octa64 %aio)
  %ok12 = icmp eq i32 %fio, %fjo
  %vv0 = insertelement <4 x i32> poison, i32 1, i32 0
  %vv1 = insertelement <4 x i32> %vv0, i32 2, i32 1
  %vv2 = insertelement <4 x i32> %vv1, i32 3, i32 2
  %vv3 = insertelement <4 x i32> %vv2, i32 4, i32 3
  %e13 = call i32 @reference_widevec32(<4 x i32> %vv3, i32 9)
  %a13 = call i32 @protected_widevec32(<4 x i32> %vv3, i32 9)
  %ok13 = icmp eq i32 %e13, %a13
  %e14 = call i32 @reference_dd3(double 1.500000e+00, double 2.250000e+00, double 3.000000e+00)
  %a14 = call i32 @protected_dd3(double 1.500000e+00, double 2.250000e+00, double 3.000000e+00)
  %ok14 = icmp eq i32 %e14, %a14
  %e15 = call i32 @reference_phi_8xi64(i64 1, i64 2, i1 true)
  %a15 = call i32 @protected_phi_8xi64(i64 1, i64 2, i1 true)
  %ok15 = icmp eq i32 %e15, %a15
  %e16 = call i32 @reference_phi_8xi64(i64 3, i64 4, i1 false)
  %a16 = call i32 @protected_phi_8xi64(i64 3, i64 4, i1 false)
  %ok16 = icmp eq i32 %e16, %a16
  %e17 = call i32 @reference_loopphi_8xi64(i64 10)
  %a17 = call i32 @protected_loopphi_8xi64(i64 10)
  %ok17 = icmp eq i32 %e17, %a17
  %t0 = and i1 %ok0, %ok1
  %t1 = and i1 %ok2, %ok3
  %t2 = and i1 %ok4, %ok5
  %t3 = and i1 %ok6, %ok7
  %t4 = and i1 %ok8, %ok9
  %t5 = and i1 %ok10, %ok11
  %t6 = and i1 %ok12, %ok13
  %u0 = and i1 %t0, %t1
  %u1 = and i1 %t2, %t3
  %u2 = and i1 %t4, %t5
  %u3 = and i1 %t6, %ok14
  %t7 = and i1 %ok15, %ok16
  %u4 = and i1 %u0, %u1
  %u5 = and i1 %u2, %u3
  %u6 = and i1 %t7, %ok17
  %u7 = and i1 %u4, %u5
  %ok = and i1 %u6, %u7
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP-DAG: Skipping VMP on unsupported_agg_nine: unsupported aggregate instruction
; SKIP-DAG: Skipping VMP on unsupported_agg_oversize: unsupported aggregate instruction
; SKIP-DAG: Skipping VMP on unsupported_agg_nested: unsupported aggregate instruction
; SKIP-DAG: Skipping VMP on unsupported_agg_leftover: unsupported aggregate instruction
; SKIP-DAG: Skipping VMP on unsupported_agg_i128: unsupported aggregate instruction
; SKIP-DAG: Skipping VMP on unsupported_neon_ld2_store_tuple: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_neon_ld2_v16_store_tuple: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_neon_ld4_v16_store_tuple: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_ld64b_store_tuple: unsupported call instruction
; SKIP-O0-DAG: Skipping VMP on unsupported_agg_nine: unsupported aggregate instruction
; SKIP-NOT: Skipping VMP on protected_wide3:
; SKIP-NOT: Skipping VMP on protected_fivei32:
; SKIP-NOT: Skipping VMP on protected_quad64:
; SKIP-NOT: Skipping VMP on protected_octa:
; SKIP-NOT: Skipping VMP on protected_ret_wide3:
; SKIP-NOT: Skipping VMP on protected_indirect:
; SKIP-NOT: Skipping VMP on protected_loopphi_wide3:
; SKIP-NOT: Skipping VMP on protected_octa64:
; SKIP-NOT: Skipping VMP on protected_loopphi_octa64:
; SKIP-NOT: Skipping VMP on protected_ret_octa64:
; SKIP-NOT: Skipping VMP on protected_indirect_octa64:
; SKIP-NOT: Skipping VMP on protected_widevec32:
; SKIP-NOT: Skipping VMP on protected_dd3:
; SKIP-NOT: Skipping VMP on protected_phi_8xi64:
; SKIP-NOT: Skipping VMP on protected_loopphi_8xi64:

; VIRT-LABEL: define i32 @protected_wide3(
; VIRT: %vmp.aregs = alloca [{{[0-9]+}} x [4 x i128]]
; VIRT: store volatile %wide3
; VIRT: vmp.dispatch:
; VIRT-DAG: insertvalue %wide3
; VIRT-DAG: extractvalue %wide3
; VIRT-DAG: load volatile %wide3,
; VIRT-DAG: store volatile %wide3
; VIRT-DAG: call %wide3 @swap_wide3(

; VIRT-LABEL: define i32 @protected_fivei32(
; VIRT: %vmp.aregs = alloca [{{[0-9]+}} x [4 x i128]]
; VIRT: vmp.dispatch:
; VIRT-DAG: insertvalue %fivei32
; VIRT-DAG: load volatile %fivei32,
; VIRT-DAG: store volatile %fivei32
; VIRT-DAG: call i32 @fold_fivei32(%fivei32

; VIRT-LABEL: define i32 @protected_quad64(
; VIRT: vmp.dispatch:
; VIRT-DAG: insertvalue %quad64
; VIRT-DAG: call i32 @fold_quad64(%quad64

; VIRT-LABEL: define i32 @protected_octa(
; VIRT: vmp.dispatch:
; VIRT-DAG: insertvalue [8 x i64]
; VIRT-DAG: load volatile [8 x i64],
; VIRT-DAG: store volatile [8 x i64]
; VIRT-DAG: call i32 @fold_octa([8 x i64]

; VIRT-LABEL: define i32 @protected_phi_8xi64(
; VIRT: vmp.dispatch:
; VIRT-DAG: insertvalue [8 x i64]
; VIRT-DAG: select i1 {{.*}}, [8 x i64]
; VIRT-DAG: load volatile [8 x i64],
; VIRT-DAG: store volatile [8 x i64]
; VIRT-DAG: call i32 @fold_octa([8 x i64]

; VIRT-LABEL: define i32 @protected_loopphi_8xi64(
; VIRT: vmp.dispatch:
; VIRT-DAG: insertvalue [8 x i64]
; VIRT-DAG: extractvalue [8 x i64]
; VIRT-DAG: call i32 @fold_octa([8 x i64]

; VIRT-LABEL: define %wide3 @protected_ret_wide3(
; VIRT: vmp.dispatch:
; VIRT: ret %wide3

; VIRT-LABEL: define %wide3 @protected_indirect(
; VIRT: vmp.dispatch:
; VIRT: call %wide3

; VIRT-LABEL: define i32 @protected_loopphi_wide3(
; VIRT: vmp.dispatch:
; VIRT-DAG: insertvalue %wide3
; VIRT-DAG: extractvalue %wide3
; VIRT-DAG: call i32 @fold_wide3(%wide3

; VIRT-LABEL: define i32 @protected_octa64(
; VIRT: %vmp.aregs = alloca [{{[0-9]+}} x [4 x i128]]
; VIRT: store volatile %octa64
; VIRT: vmp.dispatch:
; VIRT-DAG: insertvalue %octa64
; VIRT-DAG: extractvalue %octa64
; VIRT-DAG: load volatile %octa64,
; VIRT-DAG: store volatile %octa64
; VIRT-DAG: call %octa64 @swap_octa64(

; VIRT-LABEL: define i32 @protected_loopphi_octa64(
; VIRT: vmp.dispatch:
; VIRT-DAG: insertvalue %octa64
; VIRT-DAG: extractvalue %octa64
; VIRT-DAG: call i32 @fold_octa64(%octa64

; VIRT-LABEL: define %octa64 @protected_ret_octa64(
; VIRT: vmp.dispatch:
; VIRT: ret %octa64

; VIRT-LABEL: define %octa64 @protected_indirect_octa64(
; VIRT: vmp.dispatch:
; VIRT: call %octa64

; VIRT-LABEL: define i32 @protected_widevec32(
; VIRT: %vmp.vregs = alloca [{{[0-9]+}} x i128]
; VIRT: %vmp.aregs = alloca [{{[0-9]+}} x [4 x i128]]
; VIRT: vmp.dispatch:
; VIRT-DAG: insertvalue %widevec32
; VIRT-DAG: load volatile %widevec32,
; VIRT-DAG: store volatile %widevec32
; VIRT-DAG: call i32 @fold_widevec32(%widevec32

; VIRT-LABEL: define i32 @protected_dd3(
; VIRT: vmp.dispatch:
; VIRT-DAG: insertvalue %dd3
; VIRT-DAG: load volatile %dd3,
; VIRT-DAG: store volatile %dd3
; VIRT-DAG: call i32 @fold_dd3(%dd3

; VIRT: define {{.*}} @unsupported_agg_nine({{.*}} #[[UNSUPATTR:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_agg_oversize({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_agg_nested({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_agg_leftover({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_agg_i128({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_neon_ld2_store_tuple({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_neon_ld2_v16_store_tuple({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_neon_ld4_v16_store_tuple({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ld64b_store_tuple({{.*}} #[[UNSUPLS64:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #{{[0-9]+}} = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT: attributes #[[UNSUPLS64]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPLS64]] = { {{.*}}"hikari.vmp.virtualized"
