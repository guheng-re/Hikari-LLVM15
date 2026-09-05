; IEEE half scalar and natural-width half-vector fields on the existing
; small flat-aggregate surface: named sized struct or small array, 1..4
; fields, conservative alloc size 1..16, no nesting.  Reuses the
; aggregate i128 frame and native insertvalue/extractvalue/load/store/
; select/phi/ret plus ordinary direct C aggregate args/returns.
; No +fullfp16 gate — this is bit-pattern / memory / C ABI only.
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

%hh = type { half, half }
%hhi = type { half, i32 }
%phhi = type <{ half, i32 }>
%hv = type { <2 x half>, half }
%h4s = type { <4 x half> }
%harr = type [2 x half]
%halfnest = type { { %hh, i32 }, i32 }

declare void @hikari_vmp()

@slot.hh = private global %hh zeroinitializer, align 2
@slot.hv = private global %hv zeroinitializer, align 4
@slot.phhi = private global %phhi zeroinitializer, align 1

define i32 @bits_half(half %h) {
entry:
  %i = bitcast half %h to i16
  %z = zext i16 %i to i32
  ret i32 %z
}

define i32 @fold_hh(%hh %p) {
entry:
  %a = extractvalue %hh %p, 0
  %b = extractvalue %hh %p, 1
  %ba = call i32 @bits_half(half %a)
  %bb = call i32 @bits_half(half %b)
  %r = xor i32 %ba, %bb
  ret i32 %r
}

define %hh @swap_hh(%hh %p) noinline {
entry:
  %a = extractvalue %hh %p, 0
  %b = extractvalue %hh %p, 1
  %q0 = insertvalue %hh poison, half %b, 0
  %q1 = insertvalue %hh %q0, half %a, 1
  ret %hh %q1
}

define %hh @make_hh(half %a, half %b) noinline {
entry:
  %p0 = insertvalue %hh poison, half %a, 0
  %p1 = insertvalue %hh %p0, half %b, 1
  ret %hh %p1
}

define i32 @reference_hh(half %a, half %b, i1 %c) noinline optnone {
entry:
  %p0 = insertvalue %hh poison, half %a, 0
  %p1 = insertvalue %hh %p0, half %b, 1
  %alt = insertvalue %hh zeroinitializer, half %a, 0
  %sel = select i1 %c, %hh %p1, %hh %alt
  br i1 %c, label %left, label %right

left:
  %lp = insertvalue %hh %sel, half %b, 1
  br label %join

right:
  %rp = insertvalue %hh %sel, half %a, 1
  br label %join

join:
  %phi = phi %hh [ %lp, %left ], [ %rp, %right ]
  store %hh %phi, ptr @slot.hh, align 2
  %ld = load %hh, ptr @slot.hh, align 2
  %called = call %hh @make_hh(half %a, half %b)
  %sw = call %hh @swap_hh(%hh %ld)
  %r0 = call i32 @fold_hh(%hh %ld)
  %r1 = call i32 @fold_hh(%hh %called)
  %r2 = call i32 @fold_hh(%hh %sw)
  %r3 = call i32 @fold_hh(%hh %phi)
  %x0 = xor i32 %r0, %r1
  %x1 = xor i32 %r2, %r3
  %out = xor i32 %x0, %x1
  ret i32 %out
}

define i32 @protected_hh(half %a, half %b, i1 %c) noinline optnone {
entry:
  call void @hikari_vmp()
  %p0 = insertvalue %hh poison, half %a, 0
  %p1 = insertvalue %hh %p0, half %b, 1
  %alt = insertvalue %hh zeroinitializer, half %a, 0
  %sel = select i1 %c, %hh %p1, %hh %alt
  br i1 %c, label %left, label %right

left:
  %lp = insertvalue %hh %sel, half %b, 1
  br label %join

right:
  %rp = insertvalue %hh %sel, half %a, 1
  br label %join

join:
  %phi = phi %hh [ %lp, %left ], [ %rp, %right ]
  store %hh %phi, ptr @slot.hh, align 2
  %ld = load %hh, ptr @slot.hh, align 2
  %called = call %hh @make_hh(half %a, half %b)
  %sw = call %hh @swap_hh(%hh %ld)
  %r0 = call i32 @fold_hh(%hh %ld)
  %r1 = call i32 @fold_hh(%hh %called)
  %r2 = call i32 @fold_hh(%hh %sw)
  %r3 = call i32 @fold_hh(%hh %phi)
  %x0 = xor i32 %r0, %r1
  %x1 = xor i32 %r2, %r3
  %out = xor i32 %x0, %x1
  ret i32 %out
}

define i32 @fold_hhi(%hhi %p) {
entry:
  %h = extractvalue %hhi %p, 0
  %i = extractvalue %hhi %p, 1
  %bh = call i32 @bits_half(half %h)
  %r = xor i32 %bh, %i
  ret i32 %r
}

define i32 @fold_phhi(%phhi %p) {
entry:
  %h = extractvalue %phhi %p, 0
  %i = extractvalue %phhi %p, 1
  %bh = call i32 @bits_half(half %h)
  %r = xor i32 %bh, %i
  ret i32 %r
}

; Unpacked {half, i32} vs packed <{half, i32}>: same field bits, different
; in-memory padding.  Compare fields, then raw memory of each layout.
define i32 @reference_layout(half %h, i32 %k) noinline optnone {
entry:
  %u0 = insertvalue %hhi poison, half %h, 0
  %u1 = insertvalue %hhi %u0, i32 %k, 1
  %p0 = insertvalue %phhi poison, half %h, 0
  %p1 = insertvalue %phhi %p0, i32 %k, 1
  %ru = call i32 @fold_hhi(%hhi %u1)
  %rp = call i32 @fold_phhi(%phhi %p1)
  %ubuf = alloca [8 x i8], align 4
  store %hhi %u1, ptr %ubuf, align 4
  store %phhi %p1, ptr @slot.phhi, align 1
  %uld = load %hhi, ptr %ubuf, align 4
  %pld = load %phhi, ptr @slot.phhi, align 1
  %ru2 = call i32 @fold_hhi(%hhi %uld)
  %rp2 = call i32 @fold_phhi(%phhi %pld)
  %memu = load i16, ptr %ubuf, align 2
  %memp = load i16, ptr @slot.phhi, align 1
  %mu = zext i16 %memu to i32
  %mp = zext i16 %memp to i32
  %x0 = xor i32 %ru, %rp
  %x1 = xor i32 %ru2, %rp2
  %x2 = xor i32 %mu, %mp
  %y0 = xor i32 %x0, %x1
  %out = xor i32 %y0, %x2
  ret i32 %out
}

define i32 @protected_layout(half %h, i32 %k) noinline optnone {
entry:
  call void @hikari_vmp()
  %u0 = insertvalue %hhi poison, half %h, 0
  %u1 = insertvalue %hhi %u0, i32 %k, 1
  %p0 = insertvalue %phhi poison, half %h, 0
  %p1 = insertvalue %phhi %p0, i32 %k, 1
  %ru = call i32 @fold_hhi(%hhi %u1)
  %rp = call i32 @fold_phhi(%phhi %p1)
  %ubuf = alloca [8 x i8], align 4
  store %hhi %u1, ptr %ubuf, align 4
  store %phhi %p1, ptr @slot.phhi, align 1
  %uld = load %hhi, ptr %ubuf, align 4
  %pld = load %phhi, ptr @slot.phhi, align 1
  %ru2 = call i32 @fold_hhi(%hhi %uld)
  %rp2 = call i32 @fold_phhi(%phhi %pld)
  %memu = load i16, ptr %ubuf, align 2
  %memp = load i16, ptr @slot.phhi, align 1
  %mu = zext i16 %memu to i32
  %mp = zext i16 %memp to i32
  %x0 = xor i32 %ru, %rp
  %x1 = xor i32 %ru2, %rp2
  %x2 = xor i32 %mu, %mp
  %y0 = xor i32 %x0, %x1
  %out = xor i32 %y0, %x2
  ret i32 %out
}

define i32 @fold_hv(%hv %p) {
entry:
  %v = extractvalue %hv %p, 0
  %h = extractvalue %hv %p, 1
  %e0 = extractelement <2 x half> %v, i32 0
  %e1 = extractelement <2 x half> %v, i32 1
  %b0 = call i32 @bits_half(half %e0)
  %b1 = call i32 @bits_half(half %e1)
  %b2 = call i32 @bits_half(half %h)
  %x0 = xor i32 %b0, %b1
  %r = xor i32 %x0, %b2
  ret i32 %r
}

define %hv @make_hv(<2 x half> %v, half %h) noinline {
entry:
  %p0 = insertvalue %hv poison, <2 x half> %v, 0
  %p1 = insertvalue %hv %p0, half %h, 1
  ret %hv %p1
}

define i32 @reference_hv(<2 x half> %v, half %h, i1 %c) noinline optnone {
entry:
  %p0 = insertvalue %hv poison, <2 x half> %v, 0
  %p1 = insertvalue %hv %p0, half %h, 1
  %alt0 = insertvalue %hv zeroinitializer, <2 x half> %v, 0
  %sel = select i1 %c, %hv %p1, %hv %alt0
  br i1 %c, label %left, label %right

left:
  %lp = insertvalue %hv %sel, half %h, 1
  br label %join

right:
  %rh = extractelement <2 x half> %v, i32 0
  %rp = insertvalue %hv %sel, half %rh, 1
  br label %join

join:
  %phi = phi %hv [ %lp, %left ], [ %rp, %right ]
  store %hv %phi, ptr @slot.hv, align 4
  %ld = load %hv, ptr @slot.hv, align 4
  %called = call %hv @make_hv(<2 x half> %v, half %h)
  %r0 = call i32 @fold_hv(%hv %ld)
  %r1 = call i32 @fold_hv(%hv %called)
  %r2 = call i32 @fold_hv(%hv %phi)
  %x0 = xor i32 %r0, %r1
  %out = xor i32 %x0, %r2
  ret i32 %out
}

define i32 @protected_hv(<2 x half> %v, half %h, i1 %c) noinline optnone {
entry:
  call void @hikari_vmp()
  %p0 = insertvalue %hv poison, <2 x half> %v, 0
  %p1 = insertvalue %hv %p0, half %h, 1
  %alt0 = insertvalue %hv zeroinitializer, <2 x half> %v, 0
  %sel = select i1 %c, %hv %p1, %hv %alt0
  br i1 %c, label %left, label %right

left:
  %lp = insertvalue %hv %sel, half %h, 1
  br label %join

right:
  %rh = extractelement <2 x half> %v, i32 0
  %rp = insertvalue %hv %sel, half %rh, 1
  br label %join

join:
  %phi = phi %hv [ %lp, %left ], [ %rp, %right ]
  store %hv %phi, ptr @slot.hv, align 4
  %ld = load %hv, ptr @slot.hv, align 4
  %called = call %hv @make_hv(<2 x half> %v, half %h)
  %r0 = call i32 @fold_hv(%hv %ld)
  %r1 = call i32 @fold_hv(%hv %called)
  %r2 = call i32 @fold_hv(%hv %phi)
  %x0 = xor i32 %r0, %r1
  %out = xor i32 %x0, %r2
  ret i32 %out
}

define %h4s @reference_ret_h4s(<4 x half> %v) noinline optnone {
entry:
  %p = insertvalue %h4s poison, <4 x half> %v, 0
  ret %h4s %p
}

define %h4s @protected_ret_h4s(<4 x half> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %p = insertvalue %h4s poison, <4 x half> %v, 0
  ret %h4s %p
}

define i32 @reference_harr(half %a, half %b) noinline optnone {
entry:
  %p0 = insertvalue %harr poison, half %a, 0
  %p1 = insertvalue %harr %p0, half %b, 1
  %e0 = extractvalue %harr %p1, 0
  %e1 = extractvalue %harr %p1, 1
  %b0 = call i32 @bits_half(half %e0)
  %b1 = call i32 @bits_half(half %e1)
  %out = xor i32 %b0, %b1
  ret i32 %out
}

define i32 @protected_harr(half %a, half %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %p0 = insertvalue %harr poison, half %a, 0
  %p1 = insertvalue %harr %p0, half %b, 1
  %e0 = extractvalue %harr %p1, 0
  %e1 = extractvalue %harr %p1, 1
  %b0 = call i32 @bits_half(half %e0)
  %b1 = call i32 @bits_half(half %e1)
  %out = xor i32 %b0, %b1
  ret i32 %out
}

define i32 @unsupported_agg_half_nested(i32 %k) noinline optnone {
entry:
  call void @hikari_vmp()
  %n = insertvalue %halfnest poison, i32 %k, 1
  %e = extractvalue %halfnest %n, 1
  ret i32 %e
}

define i32 @unsupported_agg_five_half(half %h) noinline optnone {
entry:
  call void @hikari_vmp()
  %n = insertvalue [9 x half] poison, half %h, 0
  %e = extractvalue [9 x half] %n, 0
  %b = bitcast half %e to i16
  %z = zext i16 %b to i32
  ret i32 %z
}

define i32 @unsupported_agg_odd_halfvec(<3 x half> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %n = insertvalue { <3 x half> } poison, <3 x half> %v, 0
  %h = extractvalue { <3 x half> } %n, 0
  %e = extractelement <3 x half> %h, i32 0
  %b = bitcast half %e to i16
  %z = zext i16 %b to i32
  ret i32 %z
}

define i32 @main() {
entry:
  ; 1.0, 2.0
  %e0 = call i32 @reference_hh(half 0xH3C00, half 0xH4000, i1 true)
  %p0 = call i32 @protected_hh(half 0xH3C00, half 0xH4000, i1 true)
  %ok0 = icmp eq i32 %e0, %p0
  %e1 = call i32 @reference_hh(half 0xH4200, half 0xH3800, i1 false)
  %p1 = call i32 @protected_hh(half 0xH4200, half 0xH3800, i1 false)
  %ok1 = icmp eq i32 %e1, %p1
  %e2 = call i32 @reference_layout(half 0xH3C00, i32 7)
  %p2 = call i32 @protected_layout(half 0xH3C00, i32 7)
  %ok2 = icmp eq i32 %e2, %p2
  %v0 = insertelement <2 x half> poison, half 0xH3C00, i32 0
  %v1 = insertelement <2 x half> %v0, half 0xH4000, i32 1
  %e3 = call i32 @reference_hv(<2 x half> %v1, half 0xH3800, i1 true)
  %p3 = call i32 @protected_hv(<2 x half> %v1, half 0xH3800, i1 true)
  %ok3 = icmp eq i32 %e3, %p3
  %e4 = call i32 @reference_hv(<2 x half> %v1, half 0xH4200, i1 false)
  %p4 = call i32 @protected_hv(<2 x half> %v1, half 0xH4200, i1 false)
  %ok4 = icmp eq i32 %e4, %p4
  %w0 = insertelement <4 x half> poison, half 0xH3C00, i32 0
  %w1 = insertelement <4 x half> %w0, half 0xH4000, i32 1
  %w2 = insertelement <4 x half> %w1, half 0xH4200, i32 2
  %w3 = insertelement <4 x half> %w2, half 0xH3800, i32 3
  %er = call %h4s @reference_ret_h4s(<4 x half> %w3)
  %pr = call %h4s @protected_ret_h4s(<4 x half> %w3)
  %erv = extractvalue %h4s %er, 0
  %prv = extractvalue %h4s %pr, 0
  %erb = bitcast <4 x half> %erv to <4 x i16>
  %prb = bitcast <4 x half> %prv to <4 x i16>
  %er0 = extractelement <4 x i16> %erb, i32 0
  %er1 = extractelement <4 x i16> %erb, i32 1
  %er2 = extractelement <4 x i16> %erb, i32 2
  %er3 = extractelement <4 x i16> %erb, i32 3
  %pr0 = extractelement <4 x i16> %prb, i32 0
  %pr1 = extractelement <4 x i16> %prb, i32 1
  %pr2 = extractelement <4 x i16> %prb, i32 2
  %pr3 = extractelement <4 x i16> %prb, i32 3
  %ok5a = icmp eq i16 %er0, %pr0
  %ok5b = icmp eq i16 %er1, %pr1
  %ok5c = icmp eq i16 %er2, %pr2
  %ok5d = icmp eq i16 %er3, %pr3
  %ok5e = and i1 %ok5a, %ok5b
  %ok5f = and i1 %ok5c, %ok5d
  %ok5 = and i1 %ok5e, %ok5f
  %e6 = call i32 @reference_harr(half 0xH3C00, half 0xH4400)
  %p6 = call i32 @protected_harr(half 0xH3C00, half 0xH4400)
  %ok6 = icmp eq i32 %e6, %p6
  %t0 = and i1 %ok0, %ok1
  %t1 = and i1 %ok2, %ok3
  %t2 = and i1 %ok4, %ok5
  %t3 = and i1 %t0, %t1
  %t4 = and i1 %t2, %ok6
  %ok = and i1 %t3, %t4
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP-DAG: Skipping VMP on unsupported_agg_half_nested: unsupported aggregate instruction
; SKIP-DAG: Skipping VMP on unsupported_agg_five_half: unsupported aggregate instruction
; SKIP-DAG: Skipping VMP on unsupported_agg_odd_halfvec: unsupported aggregate instruction
; SKIP-NOT: Skipping VMP on protected_hh:
; SKIP-NOT: Skipping VMP on protected_layout:
; SKIP-NOT: Skipping VMP on protected_hv:
; SKIP-NOT: Skipping VMP on protected_ret_h4s:
; SKIP-NOT: Skipping VMP on protected_harr:
; SKIP-NOT: Skipping VMP on reference_hh:
; SKIP-NOT: Skipping VMP on swap_hh:
; SKIP-NOT: Skipping VMP on make_hh:
; SKIP-O0-DAG: Skipping VMP on unsupported_agg_half_nested: unsupported aggregate instruction

; VIRT-LABEL: define i32 @protected_hh(
; VIRT: %vmp.aregs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: insertvalue %hh
; VIRT-DAG: load volatile %hh,
; VIRT-DAG: store volatile %hh
; VIRT-DAG: call %hh @make_hh(
; VIRT-DAG: call %hh @swap_hh(%hh

; VIRT-LABEL: define i32 @protected_layout(
; VIRT: vmp.dispatch:
; VIRT-DAG: insertvalue %hhi
; VIRT-DAG: insertvalue %phhi

; VIRT-LABEL: define i32 @protected_hv(
; VIRT: %vmp.vregs = alloca
; VIRT: %vmp.aregs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: insertvalue %hv
; VIRT-DAG: call %hv @make_hv(

; VIRT-LABEL: define %h4s @protected_ret_h4s(
; VIRT: vmp.dispatch:
; VIRT: ret %h4s

; VIRT-LABEL: define i32 @protected_harr(
; VIRT: vmp.dispatch:
; VIRT-DAG: insertvalue [2 x half]
; VIRT-DAG: extractvalue [2 x half]

; VIRT: define {{.*}} @unsupported_agg_half_nested({{.*}} #[[UNSUPATTR:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_agg_five_half({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_agg_odd_halfvec({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #{{[0-9]+}} = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.virtualized"
