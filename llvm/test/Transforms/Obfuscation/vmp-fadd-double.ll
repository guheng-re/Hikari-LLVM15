; Bounded pure SSA double (f64) arith/select/phi/mem/calls/casts/freeze via float VReg frame.
; Slot packing must use f64 bitcast (vmp.d.bits64 / vmp.d.val), not f32 zext/trunc path.
; fpext/fptrunc, FMF, atomic half, non-subset indirect calls, and math intrinsics on double stay out.
;
; Pipeline (FileCheck on O0 only, same discipline as vmp-fadd-float.ll):
;   O0: opt → SKIP (stderr) → host lli parity → VIRT (O0 IR) → AArch64 llc isel
;   O2: opt → host lli parity → AArch64 llc isel
; O2 is not FileCheck'd: default<O2> can constant-fold reference sides and reshape IR;
; host lli still compares remaining protected vs expected bits.
; RUN: opt -S -verify-each -aesSeed=103 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o0.ll -o /dev/null
; RUN: opt -S -verify-each -aesSeed=103 -passes='default<O2>' %s -o %t.o2.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o2.ll -o /dev/null

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()

; Keep the sink argument live so default<O2> cannot rewrite it to poison
; (VMP rejects poison call args → would skip protected_double_call at O2).
@__vmp_double_sink_slot = private global double 0.000000e+00

; Direct double helpers (ordinary calls with double args/results).
define void @double_sink(double %x) {
entry:
  store volatile double %x, ptr @__vmp_double_sink_slot, align 8
  ret void
}

define double @double_combine(double %a, double %b) noinline {
entry:
  %s = fadd double %a, %b
  %t = fmul double %s, 2.000000e+00
  ret double %t
}

; Straight-line double arith + fneg + fcmp + double select (bitcast mix to i64/i32).
define i32 @reference(double %a, double %b) {
entry:
  %s0 = fadd double %a, %b
  %s1 = fadd double %s0, 1.000000e+00
  %s2 = fsub double %s1, %b
  %s3 = fsub double %s2, 5.000000e-01
  %s4 = fmul double %s3, %a
  %s5 = fmul double %s4, 2.000000e+00
  %s6 = fdiv double %s5, %b
  %s7 = fdiv double %s6, 2.000000e+00
  %s8 = frem double %s7, %b
  %s9 = frem double %s8, 1.500000e+00
  %s10 = fneg double %s9
  %s11 = fneg double %s10
  %ce = fcmp oeq double %s11, %s11
  %cl = fcmp olt double %a, %b
  %cg = fcmp ogt double %s5, %s6
  %sel = select i1 %cl, double %s11, double %s10
  %sel2 = select i1 %cg, double %sel, double %a
  %ze = zext i1 %ce to i32
  %zl = zext i1 %cl to i32
  %zg = zext i1 %cg to i32
  %bits64 = bitcast double %sel2 to i64
  %bits = trunc i64 %bits64 to i32
  %hi = lshr i64 %bits64, 32
  %hi32 = trunc i64 %hi to i32
  %t0 = xor i32 %bits, %hi32
  %t1 = xor i32 %t0, %ze
  %t2 = xor i32 %t1, %zl
  %t3 = xor i32 %t2, %zg
  ret i32 %t3
}

define i32 @protected(double %a, double %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %s0 = fadd double %a, %b
  %s1 = fadd double %s0, 1.000000e+00
  %s2 = fsub double %s1, %b
  %s3 = fsub double %s2, 5.000000e-01
  %s4 = fmul double %s3, %a
  %s5 = fmul double %s4, 2.000000e+00
  %s6 = fdiv double %s5, %b
  %s7 = fdiv double %s6, 2.000000e+00
  %s8 = frem double %s7, %b
  %s9 = frem double %s8, 1.500000e+00
  %s10 = fneg double %s9
  %s11 = fneg double %s10
  %ce = fcmp oeq double %s11, %s11
  %cl = fcmp olt double %a, %b
  %cg = fcmp ogt double %s5, %s6
  %sel = select i1 %cl, double %s11, double %s10
  %sel2 = select i1 %cg, double %sel, double %a
  %ze = zext i1 %ce to i32
  %zl = zext i1 %cl to i32
  %zg = zext i1 %cg to i32
  %bits64 = bitcast double %sel2 to i64
  %bits = trunc i64 %bits64 to i32
  %hi = lshr i64 %bits64, 32
  %hi32 = trunc i64 %hi to i32
  %t0 = xor i32 %bits, %hi32
  %t1 = xor i32 %t0, %ze
  %t2 = xor i32 %t1, %zl
  %t3 = xor i32 %t2, %zg
  ret i32 %t3
}

; Special values: -0 and quiet NaN through arith/select/bitcast.
define i32 @reference_special() {
entry:
  %nz = fneg double 0.000000e+00
  %bnz64 = bitcast double %nz to i64
  %bnz = trunc i64 %bnz64 to i32
  %bnz.h = lshr i64 %bnz64, 32
  %bnz.hi = trunc i64 %bnz.h to i32
  %nan = fadd double 0x7FF8000000000000, 0.000000e+00
  %bnan64 = bitcast double %nan to i64
  %bnan = trunc i64 %bnan64 to i32
  %bnan.h = lshr i64 %bnan64, 32
  %bnan.hi = trunc i64 %bnan.h to i32
  %pos = fadd double 1.000000e+00, 2.000000e+00
  %neg = fneg double %pos
  %bneg64 = bitcast double %neg to i64
  %bneg = trunc i64 %bneg64 to i32
  %bneg.h = lshr i64 %bneg64, 32
  %bneg.hi = trunc i64 %bneg.h to i32
  %ce = fcmp oeq double %nz, 0.000000e+00
  %cn = fcmp uno double %nan, %nan
  %ze = zext i1 %ce to i32
  %zn = zext i1 %cn to i32
  %t0 = xor i32 %bnz, %bnz.hi
  %t1 = xor i32 %bnan, %bnan.hi
  %t2 = xor i32 %bneg, %bneg.hi
  %t3 = xor i32 %t0, %t1
  %t4 = xor i32 %t3, %t2
  %t5 = xor i32 %t4, %ze
  %mix = xor i32 %t5, %zn
  ret i32 %mix
}

define i32 @protected_special() noinline optnone {
entry:
  call void @hikari_vmp()
  %nz = fneg double 0.000000e+00
  %bnz64 = bitcast double %nz to i64
  %bnz = trunc i64 %bnz64 to i32
  %bnz.h = lshr i64 %bnz64, 32
  %bnz.hi = trunc i64 %bnz.h to i32
  %nan = fadd double 0x7FF8000000000000, 0.000000e+00
  %bnan64 = bitcast double %nan to i64
  %bnan = trunc i64 %bnan64 to i32
  %bnan.h = lshr i64 %bnan64, 32
  %bnan.hi = trunc i64 %bnan.h to i32
  %pos = fadd double 1.000000e+00, 2.000000e+00
  %neg = fneg double %pos
  %bneg64 = bitcast double %neg to i64
  %bneg = trunc i64 %bneg64 to i32
  %bneg.h = lshr i64 %bneg64, 32
  %bneg.hi = trunc i64 %bneg.h to i32
  %ce = fcmp oeq double %nz, 0.000000e+00
  %cn = fcmp uno double %nan, %nan
  %ze = zext i1 %ce to i32
  %zn = zext i1 %cn to i32
  %t0 = xor i32 %bnz, %bnz.hi
  %t1 = xor i32 %bnan, %bnan.hi
  %t2 = xor i32 %bneg, %bneg.hi
  %t3 = xor i32 %t0, %t1
  %t4 = xor i32 %t3, %t2
  %t5 = xor i32 %t4, %ze
  %mix = xor i32 %t5, %zn
  ret i32 %mix
}

; Double-returning protected body (arith + fcmp + select + bitcast round-trip).
define double @reference_dret(double %a, double %b) {
entry:
  %s = fadd double %a, %b
  %t = fsub double %s, 2.000000e+00
  %u = fmul double %t, 5.000000e-01
  %v = fdiv double %u, %b
  %w = frem double %v, 1.250000e+00
  %x = fneg double %w
  %c = fcmp olt double %x, %a
  %y = select i1 %c, double %x, double %a
  %z = zext i1 %c to i64
  %bits = bitcast double %y to i64
  %mix = xor i64 %bits, %z
  %out = bitcast i64 %mix to double
  ret double %out
}

define double @protected_dret(double %a, double %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %s = fadd double %a, %b
  %t = fsub double %s, 2.000000e+00
  %u = fmul double %t, 5.000000e-01
  %v = fdiv double %u, %b
  %w = frem double %v, 1.250000e+00
  %x = fneg double %w
  %c = fcmp olt double %x, %a
  %y = select i1 %c, double %x, double %a
  %z = zext i1 %c to i64
  %bits = bitcast double %y to i64
  %mix = xor i64 %bits, %z
  %out = bitcast i64 %mix to double
  ret double %out
}

define i32 @reference_dret_bits(double %a, double %b) {
entry:
  %d = call double @reference_dret(double %a, double %b)
  %bits64 = bitcast double %d to i64
  %lo = trunc i64 %bits64 to i32
  %hi = lshr i64 %bits64, 32
  %hi32 = trunc i64 %hi to i32
  %mix = xor i32 %lo, %hi32
  ret i32 %mix
}

define i32 @protected_dret_bits(double %a, double %b) {
entry:
  %d = call double @protected_dret(double %a, double %b)
  %bits64 = bitcast double %d to i64
  %lo = trunc i64 %bits64 to i32
  %hi = lshr i64 %bits64, 32
  %hi32 = trunc i64 %hi to i32
  %mix = xor i32 %lo, %hi32
  ret i32 %mix
}

; Supported: ordinary direct double call (void sink + double return helper).
define i32 @reference_double_call(double %a, double %b) {
entry:
  %s = fadd double %a, %b
  call void @double_sink(double %s)
  %c = call double @double_combine(double %a, double %b)
  %bits64 = bitcast double %c to i64
  %lo = trunc i64 %bits64 to i32
  %hi = lshr i64 %bits64, 32
  %hi32 = trunc i64 %hi to i32
  %mix = xor i32 %lo, %hi32
  ret i32 %mix
}

define i32 @protected_double_call(double %a, double %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %s = fadd double %a, %b
  call void @double_sink(double %s)
  %c = call double @double_combine(double %a, double %b)
  %bits64 = bitcast double %c to i64
  %lo = trunc i64 %bits64 to i32
  %hi = lshr i64 %bits64, 32
  %hi32 = trunc i64 %hi to i32
  %mix = xor i32 %lo, %hi32
  ret i32 %mix
}

; Unsupported: ternary indirect double (same-type unary/binary f64 is covered
; by vmp-indirect-call-float-semantic.ll).
define double @unsupported_indirect_double_call(ptr %fp, double %a, double %b) {
entry:
  call void @hikari_vmp()
  %r = call double %fp(double %a, double %b, double %a)
  ret double %r
}

; FastMathFlags on ordinary direct double calls are VMP-supported
; (CallDescriptor FMF mask restored by emitCallHandler).
define i32 @protected_fast_double_call(double %a, double %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call nnan ninf double @double_combine(double %a, double %b)
  %bits64 = bitcast double %r to i64
  %lo = trunc i64 %bits64 to i32
  %hi = lshr i64 %bits64, 32
  %hi32 = trunc i64 %hi to i32
  %mix = xor i32 %lo, %hi32
  ret i32 %mix
}

; FastMathFlags on fneg are VMP-supported (re-emitted with exact flags).
define i32 @protected_fast_fneg(double %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = fneg fast double %a
  %b = bitcast double %r to i64
  %lo = trunc i64 %b to i32
  %hi = lshr i64 %b, 32
  %hi32 = trunc i64 %hi to i32
  %mix = xor i32 %lo, %hi32
  ret i32 %mix
}

; FastMathFlags on fcmp are VMP-supported (packed predicate+FMF Variant).
define i1 @protected_fast_fcmp(double %a, double %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = fcmp fast oeq double %a, %b
  ret i1 %r
}

define double @unsupported_fast_fadd(double %a, double %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = fadd fast half 0xH3C00, 0xH4000
  %d = fpext half %r to double
  ret double %d
}

; FastMathFlags on select are VMP-supported (re-emitted with exact flags).
define double @protected_fast_double_select(i1 %c, double %a, double %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = select nnan ninf i1 %c, double %a, double %b
  ret double %r
}

; Plain scalar double PHI (edge copies via FloatMove).
define double @reference_double_phi(i1 %c, double %a, double %b) {
entry:
  br i1 %c, label %t, label %f
t:
  %ta = fadd double %a, 0.000000e+00
  br label %join
f:
  %fb = fsub double %b, 0.000000e+00
  br label %join
join:
  %r = phi double [ %ta, %t ], [ %fb, %f ]
  %n = fneg double %r
  ret double %n
}

define double @protected_double_phi(i1 %c, double %a, double %b) noinline optnone {
entry:
  call void @hikari_vmp()
  br i1 %c, label %t, label %f
t:
  %ta = fadd double %a, 0.000000e+00
  br label %join
f:
  %fb = fsub double %b, 0.000000e+00
  br label %join
join:
  %r = phi double [ %ta, %t ], [ %fb, %f ]
  %n = fneg double %r
  ret double %n
}

define i32 @reference_double_phi_bits(i1 %c, double %a, double %b) {
entry:
  %d = call double @reference_double_phi(i1 %c, double %a, double %b)
  %bits64 = bitcast double %d to i64
  %lo = trunc i64 %bits64 to i32
  %hi = lshr i64 %bits64, 32
  %hi32 = trunc i64 %hi to i32
  %mix = xor i32 %lo, %hi32
  ret i32 %mix
}

define i32 @protected_double_phi_bits(i1 %c, double %a, double %b) {
entry:
  %d = call double @protected_double_phi(i1 %c, double %a, double %b)
  %bits64 = bitcast double %d to i64
  %lo = trunc i64 %bits64 to i32
  %hi = lshr i64 %bits64, 32
  %hi32 = trunc i64 %hi to i32
  %mix = xor i32 %lo, %hi32
  ret i32 %mix
}

; Loop-carried double PHI: -0 then NaN across iterations.
define i32 @reference_double_phi_special() {
entry:
  %nz0 = fneg double 0.000000e+00
  br label %loop.nz.header

loop.nz.header:
  %i.nz = phi i32 [ 0, %entry ], [ %i.nz.next, %loop.nz.body ]
  %acc.nz = phi double [ %nz0, %entry ], [ %acc.nz.next, %loop.nz.body ]
  %cont.nz = icmp slt i32 %i.nz, 3
  br i1 %cont.nz, label %loop.nz.body, label %loop.nz.exit

loop.nz.body:
  %acc.nz.next = fmul double %acc.nz, 1.000000e+00
  %i.nz.next = add nsw i32 %i.nz, 1
  br label %loop.nz.header

loop.nz.exit:
  %bnz64 = bitcast double %acc.nz to i64
  %bnz = trunc i64 %bnz64 to i32
  %bnz.h = lshr i64 %bnz64, 32
  %bnz.hi = trunc i64 %bnz.h to i32
  %nan0 = fadd double 0x7FF8000000000000, 0.000000e+00
  br label %loop.nan.header

loop.nan.header:
  %i.nan = phi i32 [ 0, %loop.nz.exit ], [ %i.nan.next, %loop.nan.body ]
  %acc.nan = phi double [ %nan0, %loop.nz.exit ], [ %acc.nan.next, %loop.nan.body ]
  %cont.nan = icmp slt i32 %i.nan, 3
  br i1 %cont.nan, label %loop.nan.body, label %loop.nan.exit

loop.nan.body:
  %acc.nan.next = fadd double %acc.nan, 0.000000e+00
  %i.nan.next = add nsw i32 %i.nan, 1
  br label %loop.nan.header

loop.nan.exit:
  %bnan64 = bitcast double %acc.nan to i64
  %bnan = trunc i64 %bnan64 to i32
  %bnan.h = lshr i64 %bnan64, 32
  %bnan.hi = trunc i64 %bnan.h to i32
  %t0 = xor i32 %bnz, %bnz.hi
  %t1 = xor i32 %bnan, %bnan.hi
  %mix = xor i32 %t0, %t1
  ret i32 %mix
}

define i32 @protected_double_phi_special() noinline optnone {
entry:
  call void @hikari_vmp()
  %nz0 = fneg double 0.000000e+00
  br label %loop.nz.header

loop.nz.header:
  %i.nz = phi i32 [ 0, %entry ], [ %i.nz.next, %loop.nz.body ]
  %acc.nz = phi double [ %nz0, %entry ], [ %acc.nz.next, %loop.nz.body ]
  %cont.nz = icmp slt i32 %i.nz, 3
  br i1 %cont.nz, label %loop.nz.body, label %loop.nz.exit

loop.nz.body:
  %acc.nz.next = fmul double %acc.nz, 1.000000e+00
  %i.nz.next = add nsw i32 %i.nz, 1
  br label %loop.nz.header

loop.nz.exit:
  %bnz64 = bitcast double %acc.nz to i64
  %bnz = trunc i64 %bnz64 to i32
  %bnz.h = lshr i64 %bnz64, 32
  %bnz.hi = trunc i64 %bnz.h to i32
  %nan0 = fadd double 0x7FF8000000000000, 0.000000e+00
  br label %loop.nan.header

loop.nan.header:
  %i.nan = phi i32 [ 0, %loop.nz.exit ], [ %i.nan.next, %loop.nan.body ]
  %acc.nan = phi double [ %nan0, %loop.nz.exit ], [ %acc.nan.next, %loop.nan.body ]
  %cont.nan = icmp slt i32 %i.nan, 3
  br i1 %cont.nan, label %loop.nan.body, label %loop.nan.exit

loop.nan.body:
  %acc.nan.next = fadd double %acc.nan, 0.000000e+00
  %i.nan.next = add nsw i32 %i.nan, 1
  br label %loop.nan.header

loop.nan.exit:
  %bnan64 = bitcast double %acc.nan to i64
  %bnan = trunc i64 %bnan64 to i32
  %bnan.h = lshr i64 %bnan64, 32
  %bnan.hi = trunc i64 %bnan.h to i32
  %t0 = xor i32 %bnz, %bnz.hi
  %t1 = xor i32 %bnan, %bnan.hi
  %mix = xor i32 %t0, %t1
  ret i32 %mix
}

; FastMathFlags on double phi are VMP-supported (final edge FloatMove carries
; them through a same-value FMF select).
define double @protected_fast_double_phi(i1 %c, double %a, double %b) noinline optnone {
entry:
  call void @hikari_vmp()
  br i1 %c, label %t, label %f
t:
  br label %join
f:
  br label %join
join:
  %r = phi nnan double [ %a, %t ], [ %b, %f ]
  ret double %r
}

; Non-atomic double load/store (incl. volatile).
define i32 @reference_double_mem(double %a, double %b) {
entry:
  %slot = alloca double, align 8
  %s = fadd double %a, %b
  store double %s, ptr %slot, align 8
  %l = load double, ptr %slot, align 8
  %m = fmul double %l, 2.000000e+00
  store volatile double %m, ptr %slot, align 8
  %lv = load volatile double, ptr %slot, align 8
  %bits64 = bitcast double %lv to i64
  %lo = trunc i64 %bits64 to i32
  %hi = lshr i64 %bits64, 32
  %hi32 = trunc i64 %hi to i32
  %mix = xor i32 %lo, %hi32
  ret i32 %mix
}

define i32 @protected_double_mem(double %a, double %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %slot = alloca double, align 8
  %s = fadd double %a, %b
  store double %s, ptr %slot, align 8
  %l = load double, ptr %slot, align 8
  %m = fmul double %l, 2.000000e+00
  store volatile double %m, ptr %slot, align 8
  %lv = load volatile double, ptr %slot, align 8
  %bits64 = bitcast double %lv to i64
  %lo = trunc i64 %bits64 to i32
  %hi = lshr i64 %bits64, 32
  %hi32 = trunc i64 %hi to i32
  %mix = xor i32 %lo, %hi32
  ret i32 %mix
}

define i32 @reference_double_mem_special() {
entry:
  %slot = alloca double, align 8
  %nz = fneg double 0.000000e+00
  store double %nz, ptr %slot, align 8
  %lnz = load double, ptr %slot, align 8
  %bnz64 = bitcast double %lnz to i64
  %bnz = trunc i64 %bnz64 to i32
  %bnz.h = lshr i64 %bnz64, 32
  %bnz.hi = trunc i64 %bnz.h to i32
  %nan = fadd double 0x7FF8000000000000, 0.000000e+00
  store double %nan, ptr %slot, align 8
  %lnan = load double, ptr %slot, align 8
  %bnan64 = bitcast double %lnan to i64
  %bnan = trunc i64 %bnan64 to i32
  %bnan.h = lshr i64 %bnan64, 32
  %bnan.hi = trunc i64 %bnan.h to i32
  %t0 = xor i32 %bnz, %bnz.hi
  %t1 = xor i32 %bnan, %bnan.hi
  %mix = xor i32 %t0, %t1
  ret i32 %mix
}

define i32 @protected_double_mem_special() noinline optnone {
entry:
  call void @hikari_vmp()
  %slot = alloca double, align 8
  %nz = fneg double 0.000000e+00
  store double %nz, ptr %slot, align 8
  %lnz = load double, ptr %slot, align 8
  %bnz64 = bitcast double %lnz to i64
  %bnz = trunc i64 %bnz64 to i32
  %bnz.h = lshr i64 %bnz64, 32
  %bnz.hi = trunc i64 %bnz.h to i32
  %nan = fadd double 0x7FF8000000000000, 0.000000e+00
  store double %nan, ptr %slot, align 8
  %lnan = load double, ptr %slot, align 8
  %bnan64 = bitcast double %lnan to i64
  %bnan = trunc i64 %bnan64 to i32
  %bnan.h = lshr i64 %bnan64, 32
  %bnan.hi = trunc i64 %bnan.h to i32
  %t0 = xor i32 %bnz, %bnz.hi
  %t1 = xor i32 %bnan, %bnan.hi
  %mix = xor i32 %t0, %t1
  ret i32 %mix
}

; Unsupported: atomic half load/store (f32/f64 atomic load/store is VMP-supported).
; Void/AS0-ptr signature so the miss is the float load/store gate, not a type gate.
define void @unsupported_atomic_double_load(ptr %p) {
entry:
  call void @hikari_vmp()
  %l = load atomic half, ptr %p unordered, align 2
  ret void
}

define void @unsupported_atomic_double_store(ptr %p) {
entry:
  call void @hikari_vmp()
  store atomic half 0xH3C00, ptr %p unordered, align 2
  ret void
}

; Scalar double <-> integer casts across supported widths.
; sitofp/uitofp: i1/i8/i16/i32/i64.  fptosi/fptoui: i8/i16/i32/i64 in the
; multi-width path; fp->i1 only in cast_special with in-range values.
define i32 @reference_double_cast(i32 %x, double %d) {
entry:
  %x1 = trunc i32 %x to i1
  %x8 = trunc i32 %x to i8
  %x16 = trunc i32 %x to i16
  %x64 = sext i32 %x to i64
  %s1 = sitofp i1 %x1 to double
  %s8 = sitofp i8 %x8 to double
  %s16 = sitofp i16 %x16 to double
  %s32 = sitofp i32 %x to double
  %s64 = sitofp i64 %x64 to double
  %u1 = uitofp i1 %x1 to double
  %u8 = uitofp i8 %x8 to double
  %u16 = uitofp i16 %x16 to double
  %u32 = uitofp i32 %x to double
  %u64 = uitofp i64 %x64 to double
  %a0 = fadd double %s1, %s8
  %a1 = fadd double %a0, %s16
  %a2 = fadd double %a1, %s32
  %a3 = fadd double %a2, %s64
  %a4 = fadd double %a3, %u1
  %a5 = fadd double %a4, %u8
  %a6 = fadd double %a5, %u16
  %a7 = fadd double %a6, %u32
  %a8 = fadd double %a7, %u64
  %a9 = fadd double %a8, %d
  %fi8 = fptosi double %d to i8
  %fi16 = fptosi double %d to i16
  %fi32 = fptosi double %d to i32
  %fi64 = fptosi double %d to i64
  %fu8 = fptoui double %d to i8
  %fu16 = fptoui double %d to i16
  %fu32 = fptoui double %d to i32
  %fu64 = fptoui double %d to i64
  %z8 = zext i8 %fi8 to i32
  %z16 = zext i16 %fi16 to i32
  %z64 = trunc i64 %fi64 to i32
  %zu8 = zext i8 %fu8 to i32
  %zu16 = zext i16 %fu16 to i32
  %zu64 = trunc i64 %fu64 to i32
  %bits64 = bitcast double %a9 to i64
  %blo = trunc i64 %bits64 to i32
  %bhi = lshr i64 %bits64, 32
  %bhi32 = trunc i64 %bhi to i32
  %m0 = xor i32 %blo, %bhi32
  %m1 = xor i32 %fi32, %z8
  %m2 = xor i32 %z16, %z64
  %m3 = xor i32 %fu32, %zu8
  %m4 = xor i32 %zu16, %zu64
  %m5 = xor i32 %m0, %m1
  %m6 = xor i32 %m2, %m3
  %m7 = xor i32 %m5, %m6
  %mix = xor i32 %m7, %m4
  ret i32 %mix
}

define i32 @protected_double_cast(i32 %x, double %d) noinline optnone {
entry:
  call void @hikari_vmp()
  %x1 = trunc i32 %x to i1
  %x8 = trunc i32 %x to i8
  %x16 = trunc i32 %x to i16
  %x64 = sext i32 %x to i64
  %s1 = sitofp i1 %x1 to double
  %s8 = sitofp i8 %x8 to double
  %s16 = sitofp i16 %x16 to double
  %s32 = sitofp i32 %x to double
  %s64 = sitofp i64 %x64 to double
  %u1 = uitofp i1 %x1 to double
  %u8 = uitofp i8 %x8 to double
  %u16 = uitofp i16 %x16 to double
  %u32 = uitofp i32 %x to double
  %u64 = uitofp i64 %x64 to double
  %a0 = fadd double %s1, %s8
  %a1 = fadd double %a0, %s16
  %a2 = fadd double %a1, %s32
  %a3 = fadd double %a2, %s64
  %a4 = fadd double %a3, %u1
  %a5 = fadd double %a4, %u8
  %a6 = fadd double %a5, %u16
  %a7 = fadd double %a6, %u32
  %a8 = fadd double %a7, %u64
  %a9 = fadd double %a8, %d
  %fi8 = fptosi double %d to i8
  %fi16 = fptosi double %d to i16
  %fi32 = fptosi double %d to i32
  %fi64 = fptosi double %d to i64
  %fu8 = fptoui double %d to i8
  %fu16 = fptoui double %d to i16
  %fu32 = fptoui double %d to i32
  %fu64 = fptoui double %d to i64
  %z8 = zext i8 %fi8 to i32
  %z16 = zext i16 %fi16 to i32
  %z64 = trunc i64 %fi64 to i32
  %zu8 = zext i8 %fu8 to i32
  %zu16 = zext i16 %fu16 to i32
  %zu64 = trunc i64 %fu64 to i32
  %bits64 = bitcast double %a9 to i64
  %blo = trunc i64 %bits64 to i32
  %bhi = lshr i64 %bits64, 32
  %bhi32 = trunc i64 %bhi to i32
  %m0 = xor i32 %blo, %bhi32
  %m1 = xor i32 %fi32, %z8
  %m2 = xor i32 %z16, %z64
  %m3 = xor i32 %fu32, %zu8
  %m4 = xor i32 %zu16, %zu64
  %m5 = xor i32 %m0, %m1
  %m6 = xor i32 %m2, %m3
  %m7 = xor i32 %m5, %m6
  %mix = xor i32 %m7, %m4
  ret i32 %mix
}

; Numeric edges (all results defined — no out-of-range fp->int poison):
; negative sitofp/fptosi, large uitofp, zero, i1 int->fp and in-range fp->i1,
; fractional trunc, small-width round-trip, i64, -0.0.
define i32 @reference_double_cast_special() {
entry:
  %neg = sitofp i32 -42 to double
  %neg.back = fptosi double %neg to i32
  %big32 = uitofp i32 -1 to double
  %big32.bits64 = bitcast double %big32 to i64
  %big32.bits = trunc i64 %big32.bits64 to i32
  %big64 = uitofp i64 -1 to double
  %big64.bits64 = bitcast double %big64 to i64
  %big64.bits = trunc i64 %big64.bits64 to i32
  %z.s0 = sitofp i32 0 to double
  %z.s1 = fptosi double %z.s0 to i32
  %z.f = fptosi double 0.000000e+00 to i32
  %i1t.s = sitofp i1 true to double
  %i1t.u = uitofp i1 true to double
  %i1f.s = sitofp i1 false to double
  %i1f.u = uitofp i1 false to double
  %i1.sadd = fadd double %i1t.s, %i1f.s
  %i1.uadd = fadd double %i1t.u, %i1f.u
  %i1.sum = fadd double %i1.sadd, %i1.uadd
  %i1.bits64 = bitcast double %i1.sum to i64
  %i1.bits = trunc i64 %i1.bits64 to i32
  %i1.si0 = fptosi double 0.000000e+00 to i1
  %i1.si1 = fptosi double -1.000000e+00 to i1
  %i1.ui0 = fptoui double 0.000000e+00 to i1
  %i1.ui1 = fptoui double 1.000000e+00 to i1
  %i1.zi0 = zext i1 %i1.si0 to i32
  %i1.zi1 = zext i1 %i1.si1 to i32
  %i1.zu0 = zext i1 %i1.ui0 to i32
  %i1.zu1 = zext i1 %i1.ui1 to i32
  %i1.zxor = xor i32 %i1.zi0, %i1.zi1
  %i1.uxor = xor i32 %i1.zu0, %i1.zu1
  %i1.mix = xor i32 %i1.zxor, %i1.uxor
  %frac.s = fptosi double -3.750000e+00 to i32
  %frac.u = fptoui double 3.750000e+00 to i32
  %rt.s0 = sitofp i16 -100 to double
  %rt.s1 = fptosi double %rt.s0 to i16
  %rt.s = sext i16 %rt.s1 to i32
  %rt.u0 = uitofp i8 200 to double
  %rt.u1 = fptoui double %rt.u0 to i8
  %rt.u = zext i8 %rt.u1 to i32
  %i64.s0 = sitofp i64 -1000000 to double
  %i64.s1 = fptosi double %i64.s0 to i64
  %i64.st = trunc i64 %i64.s1 to i32
  %nz = fneg double 0.000000e+00
  %nz.s = fptosi double %nz to i32
  %nz.u = fptoui double %nz to i32
  %m0 = xor i32 %neg.back, %big32.bits
  %m1 = xor i32 %big64.bits, %z.s1
  %m2 = xor i32 %z.f, %i1.bits
  %m3 = xor i32 %i1.mix, %frac.s
  %m4 = xor i32 %frac.u, %rt.s
  %m5 = xor i32 %rt.u, %i64.st
  %m6 = xor i32 %nz.s, %nz.u
  %m7 = xor i32 %m0, %m1
  %m8 = xor i32 %m2, %m3
  %m9 = xor i32 %m4, %m5
  %m10 = xor i32 %m7, %m8
  %m11 = xor i32 %m9, %m6
  %mix = xor i32 %m10, %m11
  ret i32 %mix
}

define i32 @protected_double_cast_special() noinline optnone {
entry:
  call void @hikari_vmp()
  %neg = sitofp i32 -42 to double
  %neg.back = fptosi double %neg to i32
  %big32 = uitofp i32 -1 to double
  %big32.bits64 = bitcast double %big32 to i64
  %big32.bits = trunc i64 %big32.bits64 to i32
  %big64 = uitofp i64 -1 to double
  %big64.bits64 = bitcast double %big64 to i64
  %big64.bits = trunc i64 %big64.bits64 to i32
  %z.s0 = sitofp i32 0 to double
  %z.s1 = fptosi double %z.s0 to i32
  %z.f = fptosi double 0.000000e+00 to i32
  %i1t.s = sitofp i1 true to double
  %i1t.u = uitofp i1 true to double
  %i1f.s = sitofp i1 false to double
  %i1f.u = uitofp i1 false to double
  %i1.sadd = fadd double %i1t.s, %i1f.s
  %i1.uadd = fadd double %i1t.u, %i1f.u
  %i1.sum = fadd double %i1.sadd, %i1.uadd
  %i1.bits64 = bitcast double %i1.sum to i64
  %i1.bits = trunc i64 %i1.bits64 to i32
  %i1.si0 = fptosi double 0.000000e+00 to i1
  %i1.si1 = fptosi double -1.000000e+00 to i1
  %i1.ui0 = fptoui double 0.000000e+00 to i1
  %i1.ui1 = fptoui double 1.000000e+00 to i1
  %i1.zi0 = zext i1 %i1.si0 to i32
  %i1.zi1 = zext i1 %i1.si1 to i32
  %i1.zu0 = zext i1 %i1.ui0 to i32
  %i1.zu1 = zext i1 %i1.ui1 to i32
  %i1.zxor = xor i32 %i1.zi0, %i1.zi1
  %i1.uxor = xor i32 %i1.zu0, %i1.zu1
  %i1.mix = xor i32 %i1.zxor, %i1.uxor
  %frac.s = fptosi double -3.750000e+00 to i32
  %frac.u = fptoui double 3.750000e+00 to i32
  %rt.s0 = sitofp i16 -100 to double
  %rt.s1 = fptosi double %rt.s0 to i16
  %rt.s = sext i16 %rt.s1 to i32
  %rt.u0 = uitofp i8 200 to double
  %rt.u1 = fptoui double %rt.u0 to i8
  %rt.u = zext i8 %rt.u1 to i32
  %i64.s0 = sitofp i64 -1000000 to double
  %i64.s1 = fptosi double %i64.s0 to i64
  %i64.st = trunc i64 %i64.s1 to i32
  %nz = fneg double 0.000000e+00
  %nz.s = fptosi double %nz to i32
  %nz.u = fptoui double %nz to i32
  %m0 = xor i32 %neg.back, %big32.bits
  %m1 = xor i32 %big64.bits, %z.s1
  %m2 = xor i32 %z.f, %i1.bits
  %m3 = xor i32 %i1.mix, %frac.s
  %m4 = xor i32 %frac.u, %rt.s
  %m5 = xor i32 %rt.u, %i64.st
  %m6 = xor i32 %nz.s, %nz.u
  %m7 = xor i32 %m0, %m1
  %m8 = xor i32 %m2, %m3
  %m9 = xor i32 %m4, %m5
  %m10 = xor i32 %m7, %m8
  %m11 = xor i32 %m9, %m6
  %mix = xor i32 %m10, %m11
  ret i32 %mix
}

; Pure SSA double freeze (FloatFreeze handler, BitWidth 64).
define i32 @reference_double_freeze(double %a, double %b) {
entry:
  %fa = freeze double %a
  %fb = freeze double %b
  %s = fadd double %fa, %fb
  %fs = freeze double %s
  %bits64 = bitcast double %fs to i64
  %lo = trunc i64 %bits64 to i32
  %hi = lshr i64 %bits64, 32
  %hi32 = trunc i64 %hi to i32
  %mix = xor i32 %lo, %hi32
  ret i32 %mix
}

define i32 @protected_double_freeze(double %a, double %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %fa = freeze double %a
  %fb = freeze double %b
  %s = fadd double %fa, %fb
  %fs = freeze double %s
  %bits64 = bitcast double %fs to i64
  %lo = trunc i64 %bits64 to i32
  %hi = lshr i64 %bits64, 32
  %hi32 = trunc i64 %hi to i32
  %mix = xor i32 %lo, %hi32
  ret i32 %mix
}

; Unsupported: fast ternary indirect call around width casts (unary/binary
; indirect calls, fast fadd/fneg/select/phi are VMP-supported; ternary
; indirect signatures stay out).
define double @unsupported_fpext(ptr %fp, float %a, float %b, float %c) {
entry:
  call void @hikari_vmp()
  %s = call fast float %fp(float %a, float %b, float %c)
  %d = fpext float %s to double
  ret double %d
}

define float @unsupported_fptrunc(ptr %fp, double %d, double %e, double %f) {
entry:
  call void @hikari_vmp()
  %s = call fast double %fp(double %d, double %e, double %f)
  %r = fptrunc double %s to float
  ret float %r
}

define i32 @main() {
entry:
  %e0 = call i32 @reference(double 1.500000e+00, double 2.250000e+00)
  %a0 = call i32 @protected(double 1.500000e+00, double 2.250000e+00)
  %e1 = call i32 @reference_special()
  %a1 = call i32 @protected_special()
  %e2 = call i32 @reference_dret_bits(double 3.000000e+00, double 4.000000e+00)
  %a2 = call i32 @protected_dret_bits(double 3.000000e+00, double 4.000000e+00)
  %e3 = call i32 @reference_double_phi_bits(i1 true, double 1.500000e+00, double 2.250000e+00)
  %a3 = call i32 @protected_double_phi_bits(i1 true, double 1.500000e+00, double 2.250000e+00)
  %e4 = call i32 @reference_double_phi_bits(i1 false, double 1.500000e+00, double 2.250000e+00)
  %a4 = call i32 @protected_double_phi_bits(i1 false, double 1.500000e+00, double 2.250000e+00)
  %e5 = call i32 @reference_double_phi_special()
  %a5 = call i32 @protected_double_phi_special()
  %e6 = call i32 @reference_double_mem(double 1.500000e+00, double 2.250000e+00)
  %a6 = call i32 @protected_double_mem(double 1.500000e+00, double 2.250000e+00)
  %e7 = call i32 @reference_double_mem_special()
  %a7 = call i32 @protected_double_mem_special()
  %e8 = call i32 @reference_double_call(double 1.500000e+00, double 2.250000e+00)
  %a8 = call i32 @protected_double_call(double 1.500000e+00, double 2.250000e+00)
  ; Multi-width casts: non-negative double so fptoui stays defined; negative x exercises sitofp.
  %e9 = call i32 @reference_double_cast(i32 7, double 3.500000e+00)
  %a9 = call i32 @protected_double_cast(i32 7, double 3.500000e+00)
  %e10 = call i32 @reference_double_cast(i32 -9, double 2.250000e+00)
  %a10 = call i32 @protected_double_cast(i32 -9, double 2.250000e+00)
  %e11 = call i32 @reference_double_cast(i32 0, double 0.000000e+00)
  %a11 = call i32 @protected_double_cast(i32 0, double 0.000000e+00)
  %e12 = call i32 @reference_double_cast(i32 1, double 1.000000e+00)
  %a12 = call i32 @protected_double_cast(i32 1, double 1.000000e+00)
  %e13 = call i32 @reference_double_cast_special()
  %a13 = call i32 @protected_double_cast_special()
  %e14 = call i32 @reference_double_freeze(double 1.500000e+00, double -2.250000e+00)
  %a14 = call i32 @protected_double_freeze(double 1.500000e+00, double -2.250000e+00)
  %e15 = call i32 @reference_double_freeze(double 0.000000e+00, double 0x7FF8000000000000)
  %a15 = call i32 @protected_double_freeze(double 0.000000e+00, double 0x7FF8000000000000)
  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %e1, %a1
  %m2 = icmp eq i32 %e2, %a2
  %m3 = icmp eq i32 %e3, %a3
  %m4 = icmp eq i32 %e4, %a4
  %m5 = icmp eq i32 %e5, %a5
  %m6 = icmp eq i32 %e6, %a6
  %m7 = icmp eq i32 %e7, %a7
  %m8 = icmp eq i32 %e8, %a8
  %m9 = icmp eq i32 %e9, %a9
  %m10 = icmp eq i32 %e10, %a10
  %m11 = icmp eq i32 %e11, %a11
  %m12 = icmp eq i32 %e12, %a12
  %m13 = icmp eq i32 %e13, %a13
  %m14 = icmp eq i32 %e14, %a14
  %m15 = icmp eq i32 %e15, %a15
  %t0 = and i1 %m0, %m1
  %t1 = and i1 %t0, %m2
  %t2 = and i1 %t1, %m3
  %t3 = and i1 %t2, %m4
  %t4 = and i1 %t3, %m5
  %t5 = and i1 %t4, %m6
  %t6 = and i1 %t5, %m7
  %t7 = and i1 %t6, %m8
  %t8 = and i1 %t7, %m9
  %t9 = and i1 %t8, %m10
  %t10 = and i1 %t9, %m11
  %t11 = and i1 %t10, %m12
  %t12 = and i1 %t11, %m13
  %t13 = and i1 %t12, %m14
  %ok = and i1 %t13, %m15
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP-NOT: Skipping VMP on unsupported_indirect_double_call:
; SKIP-DAG: Skipping VMP on unsupported_fast_fadd: unsupported float fadd instruction
; SKIP-DAG: Skipping VMP on unsupported_atomic_double_load: unsupported float load instruction
; SKIP-DAG: Skipping VMP on unsupported_atomic_double_store: unsupported float store instruction
; SKIP-NOT: Skipping VMP on unsupported_fpext:
; SKIP-NOT: Skipping VMP on unsupported_fptrunc:
; O0-only SKIP-NOT: protected* below must not appear in O0 stderr (colon anchors exact name).
; SKIP-NOT: Skipping VMP on protected:
; SKIP-NOT: Skipping VMP on protected_special:
; SKIP-NOT: Skipping VMP on protected_dret:
; SKIP-NOT: Skipping VMP on protected_double_call:
; SKIP-NOT: Skipping VMP on protected_double_phi:
; SKIP-NOT: Skipping VMP on protected_double_phi_special:
; SKIP-NOT: Skipping VMP on protected_double_mem:
; SKIP-NOT: Skipping VMP on protected_double_mem_special:
; SKIP-NOT: Skipping VMP on protected_double_cast:
; SKIP-NOT: Skipping VMP on protected_double_cast_special:
; SKIP-NOT: Skipping VMP on protected_double_freeze:

; VIRT checks are on O0 IR only (see RUN lines).
; VIRT-LABEL: define i32 @protected(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; f64 float-frame packing names (not f32 zext/trunc helpers).
; VIRT-DAG: %vmp.d.bits64{{.*}} = bitcast double
; VIRT-DAG: %vmp.d.val{{.*}} = bitcast i64
; VIRT-DAG: fadd double
; VIRT-DAG: fsub double
; VIRT-DAG: fmul double
; VIRT-DAG: fdiv double
; VIRT-DAG: frem double
; VIRT-DAG: fneg double
; VIRT-DAG: fcmp {{.*}} double
; VIRT-DAG: select i1 {{.*}} double
; VIRT-DAG: bitcast double {{.*}} to i64
; Bound NOT to next LABEL: pure double body must not use f32 slot helpers / f32 arith.
; VIRT-NOT: %vmp.f.bits32
; VIRT-NOT: %vmp.f.trunc32
; VIRT-NOT: %vmp.f.slot
; VIRT-NOT: fadd float
; VIRT-LABEL: define i32 @protected_special(
; VIRT: %vmp.fregs = alloca
; VIRT-DAG: %vmp.d.bits64{{.*}} = bitcast double
; VIRT-DAG: %vmp.d.val{{.*}} = bitcast i64
; VIRT-DAG: fneg double
; VIRT-DAG: fadd double
; VIRT-DAG: fcmp {{.*}} double
; VIRT-DAG: bitcast double {{.*}} to i64
; VIRT-LABEL: define double @protected_dret(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: %vmp.d.bits64{{.*}} = bitcast double
; VIRT-DAG: %vmp.d.val{{.*}} = bitcast i64
; VIRT-DAG: fadd double
; VIRT-DAG: fsub double
; VIRT-DAG: fmul double
; VIRT-DAG: fdiv double
; VIRT-DAG: frem double
; VIRT-DAG: fneg double
; VIRT-DAG: fcmp {{.*}} double
; VIRT-DAG: select i1 {{.*}} double
; VIRT-DAG: bitcast double {{.*}} to i64
; VIRT-DAG: bitcast i64 {{.*}} to double
; VIRT-DAG: ret double
; VIRT-LABEL: define i32 @protected_double_call(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: fadd double
; VIRT-DAG: call void @double_sink(double
; VIRT-DAG: call double @double_combine(double
; VIRT-LABEL: define double @unsupported_indirect_double_call(
; VIRT: vmp.dispatch:
; VIRT: call double
; VIRT-LABEL: define i32 @protected_fast_double_call(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT: call nnan ninf double @double_combine
; VIRT-LABEL: define i32 @protected_fast_fneg(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT: fneg fast double
; VIRT-LABEL: define i1 @protected_fast_fcmp(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT: fcmp fast oeq double
; VIRT-LABEL: define double @unsupported_fast_fadd(
; VIRT: fadd fast half
; VIRT-NOT: "hikari.vmp.virtualized"
; VIRT-LABEL: define double @protected_fast_double_select(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT: select nnan ninf i1
; VIRT-LABEL: define double @protected_double_phi(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: fadd double
; VIRT-DAG: fsub double
; VIRT-DAG: fneg double
; Residual SSA double PHI gone (FloatMove edge copies). Bound NOT to next LABEL.
; VIRT-NOT: phi double
; VIRT-LABEL: define i32 @reference_double_phi_bits(
; VIRT-LABEL: define i32 @protected_double_phi_special(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: fneg double
; VIRT-DAG: fmul double
; VIRT-DAG: fadd double
; Loop-carried double PHI: edge-copied; bound NOT to next LABEL.
; VIRT-NOT: phi double
; VIRT-LABEL: define double @protected_fast_double_phi(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT: select nnan i1 true
; VIRT-NOT: phi double
; VIRT-LABEL: define i32 @protected_double_mem(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: fadd double
; VIRT-DAG: fmul double
; VIRT-DAG: store double
; VIRT-DAG: load double
; VIRT-DAG: store volatile double
; VIRT-DAG: load volatile double
; VIRT-LABEL: define i32 @protected_double_mem_special(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: fneg double
; VIRT-DAG: fadd double
; VIRT-DAG: store double
; VIRT-DAG: load double
; VIRT-LABEL: define void @unsupported_atomic_double_load(
; VIRT: load atomic half
; VIRT-NOT: "hikari.vmp.virtualized"
; VIRT-LABEL: define void @unsupported_atomic_double_store(
; VIRT: store atomic half
; VIRT-NOT: "hikari.vmp.virtualized"
; VIRT-LABEL: define i32 @protected_double_cast(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: sitofp i1 {{.*}} to double
; VIRT-DAG: sitofp i8 {{.*}} to double
; VIRT-DAG: sitofp i16 {{.*}} to double
; VIRT-DAG: sitofp i32 {{.*}} to double
; VIRT-DAG: sitofp i64 {{.*}} to double
; VIRT-DAG: uitofp i1 {{.*}} to double
; VIRT-DAG: uitofp i8 {{.*}} to double
; VIRT-DAG: uitofp i16 {{.*}} to double
; VIRT-DAG: uitofp i32 {{.*}} to double
; VIRT-DAG: uitofp i64 {{.*}} to double
; Avoid "to i1" matching "to i16" — anchor width with non-digit / EOL.
; VIRT-DAG: fptosi double {{.*}} to i8{{([^0-9]|$)}}
; VIRT-DAG: fptosi double {{.*}} to i16{{([^0-9]|$)}}
; VIRT-DAG: fptosi double {{.*}} to i32{{([^0-9]|$)}}
; VIRT-DAG: fptosi double {{.*}} to i64{{([^0-9]|$)}}
; VIRT-DAG: fptoui double {{.*}} to i8{{([^0-9]|$)}}
; VIRT-DAG: fptoui double {{.*}} to i16{{([^0-9]|$)}}
; VIRT-DAG: fptoui double {{.*}} to i32{{([^0-9]|$)}}
; VIRT-DAG: fptoui double {{.*}} to i64{{([^0-9]|$)}}
; VIRT-DAG: fadd double
; VIRT-DAG: bitcast double {{.*}} to i64
; VIRT-LABEL: define i32 @protected_double_cast_special(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: sitofp i32 {{.*}} to double
; VIRT-DAG: sitofp i16 {{.*}} to double
; VIRT-DAG: sitofp i1 {{.*}} to double
; VIRT-DAG: sitofp i64 {{.*}} to double
; VIRT-DAG: uitofp i32 {{.*}} to double
; VIRT-DAG: uitofp i64 {{.*}} to double
; VIRT-DAG: uitofp i1 {{.*}} to double
; VIRT-DAG: uitofp i8 {{.*}} to double
; VIRT-DAG: fptosi double {{.*}} to i32{{([^0-9]|$)}}
; VIRT-DAG: fptosi double {{.*}} to i16{{([^0-9]|$)}}
; VIRT-DAG: fptosi double {{.*}} to i1{{([^0-9]|$)}}
; VIRT-DAG: fptosi double {{.*}} to i64{{([^0-9]|$)}}
; VIRT-DAG: fptoui double {{.*}} to i32{{([^0-9]|$)}}
; VIRT-DAG: fptoui double {{.*}} to i1{{([^0-9]|$)}}
; VIRT-DAG: fptoui double {{.*}} to i8{{([^0-9]|$)}}
; VIRT-DAG: fneg double
; VIRT-DAG: bitcast double {{.*}} to i64
; VIRT-LABEL: define i32 @protected_double_freeze(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: %vmp.d.bits64{{.*}} = bitcast double
; VIRT-DAG: %vmp.d.val{{.*}} = bitcast i64
; VIRT-DAG: freeze double
; VIRT-DAG: fadd double
; VIRT-DAG: bitcast double {{.*}} to i64
; VIRT-NOT: %vmp.f.bits32
; VIRT-NOT: freeze float
; VIRT-LABEL: define double @unsupported_fpext(
; VIRT: vmp.dispatch:
; VIRT: call fast float
; VIRT-LABEL: define float @unsupported_fptrunc(
; VIRT: vmp.dispatch:
; VIRT: call fast double
; VIRT: attributes{{.*}}"hikari.vmp.virtualized"
