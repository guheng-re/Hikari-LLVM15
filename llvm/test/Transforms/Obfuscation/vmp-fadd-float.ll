; Bounded scalar float arith/select/phi/mem/calls + float↔int casts (no fpext).
; Pure SSA double smoke cases below are virtualized; full double parity: vmp-fadd-double.ll.
; RUN: opt -S -verify-each -aesSeed=101 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=101 -passes='default<O2>' %s -o %t.o2.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()

; Direct float helpers (ordinary calls with float args/results).
define void @float_sink(float %x) {
entry:
  ret void
}

define float @float_combine(float %a, float %b) noinline {
entry:
  %s = fadd float %a, %b
  %t = fmul float %s, 2.000000e+00
  ret float %t
}

; Straight-line float arith + fneg + fcmp + float select (bitcast mix).
define i32 @reference(float %a, float %b) {
entry:
  %s0 = fadd float %a, %b
  %s1 = fadd float %s0, 1.000000e+00
  %s2 = fsub float %s1, %b
  %s3 = fsub float %s2, 0.500000e+00
  %s4 = fmul float %s3, %a
  %s5 = fmul float %s4, 2.000000e+00
  %s6 = fdiv float %s5, %b
  %s7 = fdiv float %s6, 2.000000e+00
  %s8 = frem float %s7, %b
  %s9 = frem float %s8, 1.500000e+00
  %s10 = fneg float %s9
  %s11 = fneg float %s10
  %ce = fcmp oeq float %s11, %s11
  %cl = fcmp olt float %a, %b
  %cg = fcmp ogt float %s5, %s6
  %sel = select i1 %cl, float %s11, float %s10
  %sel2 = select i1 %cg, float %sel, float %a
  %ze = zext i1 %ce to i32
  %zl = zext i1 %cl to i32
  %zg = zext i1 %cg to i32
  %bits = bitcast float %sel2 to i32
  %t0 = xor i32 %bits, %ze
  %t1 = xor i32 %t0, %zl
  %t2 = xor i32 %t1, %zg
  ret i32 %t2
}

define i32 @protected(float %a, float %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %s0 = fadd float %a, %b
  %s1 = fadd float %s0, 1.000000e+00
  %s2 = fsub float %s1, %b
  %s3 = fsub float %s2, 0.500000e+00
  %s4 = fmul float %s3, %a
  %s5 = fmul float %s4, 2.000000e+00
  %s6 = fdiv float %s5, %b
  %s7 = fdiv float %s6, 2.000000e+00
  %s8 = frem float %s7, %b
  %s9 = frem float %s8, 1.500000e+00
  %s10 = fneg float %s9
  %s11 = fneg float %s10
  %ce = fcmp oeq float %s11, %s11
  %cl = fcmp olt float %a, %b
  %cg = fcmp ogt float %s5, %s6
  %sel = select i1 %cl, float %s11, float %s10
  %sel2 = select i1 %cg, float %sel, float %a
  %ze = zext i1 %ce to i32
  %zl = zext i1 %cl to i32
  %zg = zext i1 %cg to i32
  %bits = bitcast float %sel2 to i32
  %t0 = xor i32 %bits, %ze
  %t1 = xor i32 %t0, %zl
  %t2 = xor i32 %t1, %zg
  ret i32 %t2
}

; Special bit patterns: +0/-0 and NaN under fneg/fcmp, plus frem/fdiv edges.
define i32 @reference_special() {
entry:
  %p0 = fneg float 0.000000e+00
  %n0 = fneg float -0.000000e+00
  %pn0 = fneg float %p0
  %nn0 = fneg float %n0
  %nan = fadd float 0x7FF8000000000000, 0.000000e+00
  %nan_neg = fneg float %nan
  %nan_dneg = fneg float %nan_neg
  ; +0 == -0 ordered; NaN unordered predicates; select preserves ±0/NaN bits.
  %ceq = fcmp oeq float 0.000000e+00, -0.000000e+00
  %cuno = fcmp uno float %nan, %nan
  %cone = fcmp one float 1.000000e+00, 2.000000e+00
  %sel_nz = select i1 %ceq, float -0.000000e+00, float 0.000000e+00
  %sel_nan = select i1 %cuno, float %nan_neg, float %nan
  %bsel_nz = bitcast float %sel_nz to i32
  %bsel_nan = bitcast float %sel_nan to i32
  %zceq = zext i1 %ceq to i32
  %zcuno = zext i1 %cuno to i32
  %zcone = zext i1 %cone to i32
  %nz = fadd float -0.000000e+00, -0.000000e+00
  %nz2 = fsub float -0.000000e+00, 0.000000e+00
  %nz3 = fmul float -0.000000e+00, 1.000000e+00
  %nz4 = fdiv float -0.000000e+00, 1.000000e+00
  %nz5 = frem float -0.000000e+00, 1.000000e+00
  %pos = frem float 5.500000e+00, 2.000000e+00
  %neg = frem float -5.500000e+00, 2.000000e+00
  %negd = frem float 5.500000e+00, -2.000000e+00
  %nan2 = fsub float 0x7FF8000000000000, 1.000000e+00
  %nan3 = fmul float 0x7FF8000000000000, 2.000000e+00
  %nan4 = fdiv float 0x7FF8000000000000, 2.000000e+00
  %nan5 = frem float 0x7FF8000000000000, 2.000000e+00
  %inf = fdiv float 1.000000e+00, 0.000000e+00
  %ninf = fdiv float -1.000000e+00, 0.000000e+00
  %zd = frem float 1.000000e+00, 0.000000e+00
  %nzd = frem float -1.000000e+00, 0.000000e+00
  %bp0 = bitcast float %p0 to i32
  %bn0 = bitcast float %n0 to i32
  %bpn0 = bitcast float %pn0 to i32
  %bnn0 = bitcast float %nn0 to i32
  %bnan = bitcast float %nan to i32
  %bnan_neg = bitcast float %nan_neg to i32
  %bnan_dneg = bitcast float %nan_dneg to i32
  %bnz = bitcast float %nz to i32
  %bnz2 = bitcast float %nz2 to i32
  %bnz3 = bitcast float %nz3 to i32
  %bnz4 = bitcast float %nz4 to i32
  %bnz5 = bitcast float %nz5 to i32
  %bpos = bitcast float %pos to i32
  %bneg = bitcast float %neg to i32
  %bnegd = bitcast float %negd to i32
  %bnan2 = bitcast float %nan2 to i32
  %bnan3 = bitcast float %nan3 to i32
  %bnan4 = bitcast float %nan4 to i32
  %bnan5 = bitcast float %nan5 to i32
  %binf = bitcast float %inf to i32
  %bninf = bitcast float %ninf to i32
  %bzd = bitcast float %zd to i32
  %bnzd = bitcast float %nzd to i32
  ; Sign-bit sensitive diffs: +0 vs fneg(+0)= -0, -0 vs fneg(-0)= +0, NaN sign flip.
  %d0 = xor i32 %bp0, %bn0
  %d1 = xor i32 %bpn0, %bnn0
  %d2 = xor i32 %bnan, %bnan_neg
  %d3 = xor i32 %bnan_neg, %bnan_dneg
  %m0 = xor i32 %bnz, %bnz2
  %m1 = xor i32 %m0, %bnz3
  %m2 = xor i32 %m1, %bnz4
  %m3 = xor i32 %m2, %bnz5
  %m4 = xor i32 %bpos, %bneg
  %m5 = xor i32 %m4, %bnegd
  %m6 = xor i32 %bnan2, %bnan3
  %m7 = xor i32 %m6, %bnan4
  %m8 = xor i32 %m7, %bnan5
  %m9 = xor i32 %binf, %bninf
  %m10 = xor i32 %bzd, %bnzd
  %s0 = xor i32 %d0, %d1
  %s1 = xor i32 %s0, %d2
  %s2 = xor i32 %s1, %d3
  %mix = xor i32 %m3, %m5
  %mix2 = xor i32 %mix, %m8
  %mix3 = xor i32 %mix2, %m9
  %mix4 = xor i32 %mix3, %m10
  %mix5 = xor i32 %mix4, %s2
  %fc0 = xor i32 %zceq, %zcuno
  %fc1 = xor i32 %fc0, %zcone
  %fc2 = xor i32 %fc1, %bsel_nz
  %fc3 = xor i32 %fc2, %bsel_nan
  %mix6 = xor i32 %mix5, %fc3
  ret i32 %mix6
}

define i32 @protected_special() noinline optnone {
entry:
  call void @hikari_vmp()
  %p0 = fneg float 0.000000e+00
  %n0 = fneg float -0.000000e+00
  %pn0 = fneg float %p0
  %nn0 = fneg float %n0
  %nan = fadd float 0x7FF8000000000000, 0.000000e+00
  %nan_neg = fneg float %nan
  %nan_dneg = fneg float %nan_neg
  %ceq = fcmp oeq float 0.000000e+00, -0.000000e+00
  %cuno = fcmp uno float %nan, %nan
  %cone = fcmp one float 1.000000e+00, 2.000000e+00
  %sel_nz = select i1 %ceq, float -0.000000e+00, float 0.000000e+00
  %sel_nan = select i1 %cuno, float %nan_neg, float %nan
  %bsel_nz = bitcast float %sel_nz to i32
  %bsel_nan = bitcast float %sel_nan to i32
  %zceq = zext i1 %ceq to i32
  %zcuno = zext i1 %cuno to i32
  %zcone = zext i1 %cone to i32
  %nz = fadd float -0.000000e+00, -0.000000e+00
  %nz2 = fsub float -0.000000e+00, 0.000000e+00
  %nz3 = fmul float -0.000000e+00, 1.000000e+00
  %nz4 = fdiv float -0.000000e+00, 1.000000e+00
  %nz5 = frem float -0.000000e+00, 1.000000e+00
  %pos = frem float 5.500000e+00, 2.000000e+00
  %neg = frem float -5.500000e+00, 2.000000e+00
  %negd = frem float 5.500000e+00, -2.000000e+00
  %nan2 = fsub float 0x7FF8000000000000, 1.000000e+00
  %nan3 = fmul float 0x7FF8000000000000, 2.000000e+00
  %nan4 = fdiv float 0x7FF8000000000000, 2.000000e+00
  %nan5 = frem float 0x7FF8000000000000, 2.000000e+00
  %inf = fdiv float 1.000000e+00, 0.000000e+00
  %ninf = fdiv float -1.000000e+00, 0.000000e+00
  %zd = frem float 1.000000e+00, 0.000000e+00
  %nzd = frem float -1.000000e+00, 0.000000e+00
  %bp0 = bitcast float %p0 to i32
  %bn0 = bitcast float %n0 to i32
  %bpn0 = bitcast float %pn0 to i32
  %bnn0 = bitcast float %nn0 to i32
  %bnan = bitcast float %nan to i32
  %bnan_neg = bitcast float %nan_neg to i32
  %bnan_dneg = bitcast float %nan_dneg to i32
  %bnz = bitcast float %nz to i32
  %bnz2 = bitcast float %nz2 to i32
  %bnz3 = bitcast float %nz3 to i32
  %bnz4 = bitcast float %nz4 to i32
  %bnz5 = bitcast float %nz5 to i32
  %bpos = bitcast float %pos to i32
  %bneg = bitcast float %neg to i32
  %bnegd = bitcast float %negd to i32
  %bnan2 = bitcast float %nan2 to i32
  %bnan3 = bitcast float %nan3 to i32
  %bnan4 = bitcast float %nan4 to i32
  %bnan5 = bitcast float %nan5 to i32
  %binf = bitcast float %inf to i32
  %bninf = bitcast float %ninf to i32
  %bzd = bitcast float %zd to i32
  %bnzd = bitcast float %nzd to i32
  %d0 = xor i32 %bp0, %bn0
  %d1 = xor i32 %bpn0, %bnn0
  %d2 = xor i32 %bnan, %bnan_neg
  %d3 = xor i32 %bnan_neg, %bnan_dneg
  %m0 = xor i32 %bnz, %bnz2
  %m1 = xor i32 %m0, %bnz3
  %m2 = xor i32 %m1, %bnz4
  %m3 = xor i32 %m2, %bnz5
  %m4 = xor i32 %bpos, %bneg
  %m5 = xor i32 %m4, %bnegd
  %m6 = xor i32 %bnan2, %bnan3
  %m7 = xor i32 %m6, %bnan4
  %m8 = xor i32 %m7, %bnan5
  %m9 = xor i32 %binf, %bninf
  %m10 = xor i32 %bzd, %bnzd
  %s0 = xor i32 %d0, %d1
  %s1 = xor i32 %s0, %d2
  %s2 = xor i32 %s1, %d3
  %mix = xor i32 %m3, %m5
  %mix2 = xor i32 %mix, %m8
  %mix3 = xor i32 %mix2, %m9
  %mix4 = xor i32 %mix3, %m10
  %mix5 = xor i32 %mix4, %s2
  %fc0 = xor i32 %zceq, %zcuno
  %fc1 = xor i32 %fc0, %zcone
  %fc2 = xor i32 %fc1, %bsel_nz
  %fc3 = xor i32 %fc2, %bsel_nan
  %mix6 = xor i32 %mix5, %fc3
  ret i32 %mix6
}

; Float-return path: arith/fneg/fcmp/select; fold via float<->i32 bitcast.
define float @reference_fret(float %a, float %b) {
entry:
  %s = fadd float %a, %b
  %t = fsub float %s, 2.000000e+00
  %u = fmul float %t, 0.500000e+00
  %v = fdiv float %u, %b
  %w = frem float %v, 1.250000e+00
  %x = fneg float %w
  %c = fcmp olt float %x, %a
  %y = select i1 %c, float %x, float %a
  %z = zext i1 %c to i32
  %bits = bitcast float %y to i32
  %mix = xor i32 %bits, %z
  %out = bitcast i32 %mix to float
  ret float %out
}

define float @protected_fret(float %a, float %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %s = fadd float %a, %b
  %t = fsub float %s, 2.000000e+00
  %u = fmul float %t, 0.500000e+00
  %v = fdiv float %u, %b
  %w = frem float %v, 1.250000e+00
  %x = fneg float %w
  %c = fcmp olt float %x, %a
  %y = select i1 %c, float %x, float %a
  %z = zext i1 %c to i32
  %bits = bitcast float %y to i32
  %mix = xor i32 %bits, %z
  %out = bitcast i32 %mix to float
  ret float %out
}

; i32 wrappers bitcast float results for host lli bit-pattern compare.
define i32 @reference_fret_bits(float %a, float %b) {
entry:
  %f = call float @reference_fret(float %a, float %b)
  %bits = bitcast float %f to i32
  ret i32 %bits
}

define i32 @protected_fret_bits(float %a, float %b) {
entry:
  %f = call float @protected_fret(float %a, float %b)
  %bits = bitcast float %f to i32
  ret i32 %bits
}

; Supported: ordinary direct float call (void sink + float return helper).
define i32 @reference_float_call(float %a, float %b) {
entry:
  %s = fadd float %a, %b
  call void @float_sink(float %s)
  %c = call float @float_combine(float %a, float %b)
  %bits = bitcast float %c to i32
  ret i32 %bits
}

define i32 @protected_float_call(float %a, float %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %s = fadd float %a, %b
  call void @float_sink(float %s)
  %c = call float @float_combine(float %a, float %b)
  %bits = bitcast float %c to i32
  ret i32 %bits
}

; Unsupported: fptrunc in a double-arg function (fpext/fptrunc remain out of scope).
define float @unsupported_double_call_arg(double %a, float %b) {
entry:
  call void @hikari_vmp()
  %t = fptrunc double %a to float
  %r = fadd float %t, %b
  ret float %r
}

; Unsupported: ternary indirect float (same-type unary/binary f32 is covered
; by vmp-indirect-call-float-semantic.ll).
define float @unsupported_indirect_float_call(ptr %fp, float %a, float %b) {
entry:
  call void @hikari_vmp()
  %r = call float %fp(float %a, float %b, float %a)
  ret float %r
}

; FastMathFlags on ordinary direct float calls are VMP-supported
; (CallDescriptor FMF mask restored by emitCallHandler).
define i32 @protected_fast_float_call(float %a, float %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call nnan ninf float @float_combine(float %a, float %b)
  %b0 = bitcast float %r to i32
  ret i32 %b0
}

; FastMathFlags on fneg are VMP-supported (re-emitted with exact flags).
define i32 @protected_fast_fneg(float %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = fneg fast float %a
  %b = bitcast float %r to i32
  ret i32 %b
}

; FastMathFlags on fcmp are VMP-supported (packed predicate+FMF Variant).
define i1 @protected_fast_fcmp(float %a, float %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = fcmp fast oeq float %a, %b
  ret i1 %r
}

; Pure SSA double smoke (full parity lives in vmp-fadd-double.ll).
define double @unsupported_double(double %a, double %b) {
entry:
  call void @hikari_vmp()
  %r = fadd double %a, %b
  ret double %r
}

define i1 @unsupported_double_fcmp(double %a, double %b) {
entry:
  call void @hikari_vmp()
  %r = fcmp oeq double %a, %b
  ret i1 %r
}

define double @unsupported_double_select(i1 %c, double %a, double %b) {
entry:
  call void @hikari_vmp()
  %r = select i1 %c, double %a, double %b
  ret double %r
}

; Supported: plain scalar float PHI (edge copies via FloatMove).
define float @reference_float_phi(i1 %c, float %a, float %b) {
entry:
  br i1 %c, label %t, label %f
t:
  %ta = fadd float %a, 0.000000e+00
  br label %join
f:
  %fb = fsub float %b, 0.000000e+00
  br label %join
join:
  %r = phi float [ %ta, %t ], [ %fb, %f ]
  %n = fneg float %r
  ret float %n
}

define float @protected_float_phi(i1 %c, float %a, float %b) noinline optnone {
entry:
  call void @hikari_vmp()
  br i1 %c, label %t, label %f
t:
  %ta = fadd float %a, 0.000000e+00
  br label %join
f:
  %fb = fsub float %b, 0.000000e+00
  br label %join
join:
  %r = phi float [ %ta, %t ], [ %fb, %f ]
  %n = fneg float %r
  ret float %n
}

define i32 @reference_float_phi_bits(i1 %c, float %a, float %b) {
entry:
  %f = call float @reference_float_phi(i1 %c, float %a, float %b)
  %bits = bitcast float %f to i32
  ret i32 %bits
}

define i32 @protected_float_phi_bits(i1 %c, float %a, float %b) {
entry:
  %f = call float @protected_float_phi(i1 %c, float %a, float %b)
  %bits = bitcast float %f to i32
  ret i32 %bits
}

; Loop-carried float PHI (not diamond-only): -0 then NaN bit patterns across iterations.
define i32 @reference_float_phi_special() {
entry:
  %nz0 = fneg float 0.000000e+00
  br label %loop.nz.header

loop.nz.header:
  %i.nz = phi i32 [ 0, %entry ], [ %i.nz.next, %loop.nz.body ]
  %acc.nz = phi float [ %nz0, %entry ], [ %acc.nz.next, %loop.nz.body ]
  %cont.nz = icmp slt i32 %i.nz, 3
  br i1 %cont.nz, label %loop.nz.body, label %loop.nz.exit

loop.nz.body:
  ; Keep -0 across backedge FloatMove: fmul by +1.
  %acc.nz.next = fmul float %acc.nz, 1.000000e+00
  %i.nz.next = add nsw i32 %i.nz, 1
  br label %loop.nz.header

loop.nz.exit:
  %bnz = bitcast float %acc.nz to i32
  %nan0 = fadd float 0x7FF8000000000000, 0.000000e+00
  br label %loop.nan.header

loop.nan.header:
  %i.nan = phi i32 [ 0, %loop.nz.exit ], [ %i.nan.next, %loop.nan.body ]
  %acc.nan = phi float [ %nan0, %loop.nz.exit ], [ %acc.nan.next, %loop.nan.body ]
  %cont.nan = icmp slt i32 %i.nan, 3
  br i1 %cont.nan, label %loop.nan.body, label %loop.nan.exit

loop.nan.body:
  ; Keep NaN payload across backedge FloatMove: fadd +0.
  %acc.nan.next = fadd float %acc.nan, 0.000000e+00
  %i.nan.next = add nsw i32 %i.nan, 1
  br label %loop.nan.header

loop.nan.exit:
  %bnan = bitcast float %acc.nan to i32
  %mix = xor i32 %bnz, %bnan
  ret i32 %mix
}

define i32 @protected_float_phi_special() noinline optnone {
entry:
  call void @hikari_vmp()
  %nz0 = fneg float 0.000000e+00
  br label %loop.nz.header

loop.nz.header:
  %i.nz = phi i32 [ 0, %entry ], [ %i.nz.next, %loop.nz.body ]
  %acc.nz = phi float [ %nz0, %entry ], [ %acc.nz.next, %loop.nz.body ]
  %cont.nz = icmp slt i32 %i.nz, 3
  br i1 %cont.nz, label %loop.nz.body, label %loop.nz.exit

loop.nz.body:
  %acc.nz.next = fmul float %acc.nz, 1.000000e+00
  %i.nz.next = add nsw i32 %i.nz, 1
  br label %loop.nz.header

loop.nz.exit:
  %bnz = bitcast float %acc.nz to i32
  %nan0 = fadd float 0x7FF8000000000000, 0.000000e+00
  br label %loop.nan.header

loop.nan.header:
  %i.nan = phi i32 [ 0, %loop.nz.exit ], [ %i.nan.next, %loop.nan.body ]
  %acc.nan = phi float [ %nan0, %loop.nz.exit ], [ %acc.nan.next, %loop.nan.body ]
  %cont.nan = icmp slt i32 %i.nan, 3
  br i1 %cont.nan, label %loop.nan.body, label %loop.nan.exit

loop.nan.body:
  %acc.nan.next = fadd float %acc.nan, 0.000000e+00
  %i.nan.next = add nsw i32 %i.nan, 1
  br label %loop.nan.header

loop.nan.exit:
  %bnan = bitcast float %acc.nan to i32
  %mix = xor i32 %bnz, %bnan
  ret i32 %mix
}

; Pure SSA double PHI smoke (edge copies via FloatMove).
define double @unsupported_double_phi(i1 %c, double %a, double %b) {
entry:
  call void @hikari_vmp()
  br i1 %c, label %t, label %f
t:
  br label %join
f:
  br label %join
join:
  %r = phi double [ %a, %t ], [ %b, %f ]
  ret double %r
}

; FastMathFlags on float phi are VMP-supported (final edge FloatMove carries
; them through a same-value FMF select).
define float @protected_fast_float_phi(i1 %c, float %a, float %b) noinline optnone {
entry:
  call void @hikari_vmp()
  br i1 %c, label %t, label %f
t:
  br label %join
f:
  br label %join
join:
  %r = phi nnan float [ %a, %t ], [ %b, %f ]
  ret float %r
}

; FastMathFlags on select are VMP-supported (re-emitted with exact flags).
define float @protected_fast_float_select(i1 %c, float %a, float %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = select nnan ninf i1 %c, float %a, float %b
  ret float %r
}

; Safety regression: fast half fadd (FMF on a non-scalar-f32/f64 width) skips.
define float @unsupported_fast_fadd(float %a, float %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = fadd fast half 0xH3C00, 0xH4000
  %f = fpext half %r to float
  ret float %f
}

; Scalar float load/store via stack slot (non-atomic).
define i32 @reference_float_mem(float %a, float %b) {
entry:
  %slot = alloca float, align 4
  %s = fadd float %a, %b
  store float %s, ptr %slot, align 4
  %l = load float, ptr %slot, align 4
  %t = fmul float %l, 2.000000e+00
  store volatile float %t, ptr %slot, align 4
  %lv = load volatile float, ptr %slot, align 4
  %bits = bitcast float %lv to i32
  ret i32 %bits
}

define i32 @protected_float_mem(float %a, float %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %slot = alloca float, align 4
  %s = fadd float %a, %b
  store float %s, ptr %slot, align 4
  %l = load float, ptr %slot, align 4
  %t = fmul float %l, 2.000000e+00
  store volatile float %t, ptr %slot, align 4
  %lv = load volatile float, ptr %slot, align 4
  %bits = bitcast float %lv to i32
  ret i32 %bits
}

; Float memory preserves -0 and NaN bit patterns.
define i32 @reference_float_mem_special() {
entry:
  %slot = alloca float, align 4
  %nz = fneg float 0.000000e+00
  store float %nz, ptr %slot, align 4
  %lnz = load float, ptr %slot, align 4
  %bnz = bitcast float %lnz to i32
  %nan = fadd float 0x7FF8000000000000, 0.000000e+00
  store float %nan, ptr %slot, align 4
  %lnan = load float, ptr %slot, align 4
  %bnan = bitcast float %lnan to i32
  %mix = xor i32 %bnz, %bnan
  ret i32 %mix
}

define i32 @protected_float_mem_special() noinline optnone {
entry:
  call void @hikari_vmp()
  %slot = alloca float, align 4
  %nz = fneg float 0.000000e+00
  store float %nz, ptr %slot, align 4
  %lnz = load float, ptr %slot, align 4
  %bnz = bitcast float %lnz to i32
  %nan = fadd float 0x7FF8000000000000, 0.000000e+00
  store float %nan, ptr %slot, align 4
  %lnan = load float, ptr %slot, align 4
  %bnan = bitcast float %lnan to i32
  %mix = xor i32 %bnz, %bnan
  ret i32 %mix
}

; Pure SSA double load/store smoke.
define double @unsupported_double_mem(double %a) {
entry:
  call void @hikari_vmp()
  %slot = alloca double, align 8
  store double %a, ptr %slot, align 8
  %l = load double, ptr %slot, align 8
  ret double %l
}

; Unsupported: atomic half load (f32 atomic load/store is VMP-supported).
; Void/AS0-ptr signature so the miss is the float-load gate, not a type gate.
define void @unsupported_atomic_float_load(ptr %p) {
entry:
  call void @hikari_vmp()
  %l = load atomic half, ptr %p unordered, align 2
  ret void
}

; Unsupported: atomic half store.
define void @unsupported_atomic_float_store(ptr %p) {
entry:
  call void @hikari_vmp()
  store atomic half 0xH3C00, ptr %p unordered, align 2
  ret void
}

; Scalar float <-> integer casts across supported widths.
; sitofp/uitofp: i1/i8/i16/i32/i64.  fptosi/fptoui: i8/i16/i32/i64 only.
; (fptosi/fptoui to i1 are only exercised in special with in-range values;
;  out-of-range fp->int is poison and must not appear in parity checks.)
define i32 @reference_float_cast(i32 %x, float %f) {
entry:
  %x1 = trunc i32 %x to i1
  %x8 = trunc i32 %x to i8
  %x16 = trunc i32 %x to i16
  %x64 = sext i32 %x to i64
  ; sitofp: signed integer -> float
  %sf1 = sitofp i1 %x1 to float
  %sf8 = sitofp i8 %x8 to float
  %sf16 = sitofp i16 %x16 to float
  %sf32 = sitofp i32 %x to float
  %sf64 = sitofp i64 %x64 to float
  ; uitofp: unsigned integer -> float
  %uf1 = uitofp i1 %x1 to float
  %uf8 = uitofp i8 %x8 to float
  %uf16 = uitofp i16 %x16 to float
  %uf32 = uitofp i32 %x to float
  %uf64 = uitofp i64 %x64 to float
  %s0 = fadd float %sf1, %sf8
  %s1 = fadd float %s0, %sf16
  %s2 = fadd float %s1, %sf32
  %s3 = fadd float %s2, %sf64
  %s4 = fadd float %uf1, %uf8
  %s5 = fadd float %s4, %uf16
  %s6 = fadd float %s5, %uf32
  %s7 = fadd float %s6, %uf64
  %s = fadd float %s3, %s7
  ; fptosi / fptoui: float -> i8/i16/i32/i64 (caller must pass in-range non-neg for fptoui)
  %si8 = fptosi float %f to i8
  %si16 = fptosi float %f to i16
  %si32 = fptosi float %f to i32
  %si64 = fptosi float %f to i64
  %ui8 = fptoui float %f to i8
  %ui16 = fptoui float %f to i16
  %ui32 = fptoui float %f to i32
  %ui64 = fptoui float %f to i64
  %zi8 = zext i8 %si8 to i32
  %zi16 = zext i16 %si16 to i32
  %zu8 = zext i8 %ui8 to i32
  %zu16 = zext i16 %ui16 to i32
  %zi64t = trunc i64 %si64 to i32
  %zu64t = trunc i64 %ui64 to i32
  %m0 = xor i32 %si32, %ui32
  %m1 = xor i32 %zi8, %zi16
  %m2 = xor i32 %zu8, %zu16
  %m3 = xor i32 %zi64t, %zu64t
  %m4 = xor i32 %m0, %m1
  %m5 = xor i32 %m2, %m3
  %m6 = xor i32 %m4, %m5
  %bits = bitcast float %s to i32
  %mix = xor i32 %bits, %m6
  ret i32 %mix
}

define i32 @protected_float_cast(i32 %x, float %f) noinline optnone {
entry:
  call void @hikari_vmp()
  %x1 = trunc i32 %x to i1
  %x8 = trunc i32 %x to i8
  %x16 = trunc i32 %x to i16
  %x64 = sext i32 %x to i64
  %sf1 = sitofp i1 %x1 to float
  %sf8 = sitofp i8 %x8 to float
  %sf16 = sitofp i16 %x16 to float
  %sf32 = sitofp i32 %x to float
  %sf64 = sitofp i64 %x64 to float
  %uf1 = uitofp i1 %x1 to float
  %uf8 = uitofp i8 %x8 to float
  %uf16 = uitofp i16 %x16 to float
  %uf32 = uitofp i32 %x to float
  %uf64 = uitofp i64 %x64 to float
  %s0 = fadd float %sf1, %sf8
  %s1 = fadd float %s0, %sf16
  %s2 = fadd float %s1, %sf32
  %s3 = fadd float %s2, %sf64
  %s4 = fadd float %uf1, %uf8
  %s5 = fadd float %s4, %uf16
  %s6 = fadd float %s5, %uf32
  %s7 = fadd float %s6, %uf64
  %s = fadd float %s3, %s7
  %si8 = fptosi float %f to i8
  %si16 = fptosi float %f to i16
  %si32 = fptosi float %f to i32
  %si64 = fptosi float %f to i64
  %ui8 = fptoui float %f to i8
  %ui16 = fptoui float %f to i16
  %ui32 = fptoui float %f to i32
  %ui64 = fptoui float %f to i64
  %zi8 = zext i8 %si8 to i32
  %zi16 = zext i16 %si16 to i32
  %zu8 = zext i8 %ui8 to i32
  %zu16 = zext i16 %ui16 to i32
  %zi64t = trunc i64 %si64 to i32
  %zu64t = trunc i64 %ui64 to i32
  %m0 = xor i32 %si32, %ui32
  %m1 = xor i32 %zi8, %zi16
  %m2 = xor i32 %zu8, %zu16
  %m3 = xor i32 %zi64t, %zu64t
  %m4 = xor i32 %m0, %m1
  %m5 = xor i32 %m2, %m3
  %m6 = xor i32 %m4, %m5
  %bits = bitcast float %s to i32
  %mix = xor i32 %bits, %m6
  ret i32 %mix
}

; Numeric edges (all results defined — no out-of-range fp->int poison):
; negative sitofp/fptosi, large uitofp, zero, i1 int->fp and in-range fp->i1,
; fractional trunc, small-width round-trip, i64, -0.0.
define i32 @reference_float_cast_special() {
entry:
  ; Negative signed -> float -> signed
  %neg = sitofp i32 -42 to float
  %neg.back = fptosi float %neg to i32
  ; Large unsigned (high bit set) i32/i64 -> float (bit-pattern mix)
  %big32 = uitofp i32 -1 to float
  %big32.bits = bitcast float %big32 to i32
  %big64 = uitofp i64 -1 to float
  %big64.bits = bitcast float %big64 to i32
  ; Zero sitofp / fptosi(+0)
  %z.s0 = sitofp i32 0 to float
  %z.s1 = fptosi float %z.s0 to i32
  %z.f = fptosi float 0.000000e+00 to i32
  ; i1 true/false through sitofp/uitofp
  %i1t.s = sitofp i1 true to float
  %i1t.u = uitofp i1 true to float
  %i1f.s = sitofp i1 false to float
  %i1f.u = uitofp i1 false to float
  %i1.sadd = fadd float %i1t.s, %i1f.s
  %i1.uadd = fadd float %i1t.u, %i1f.u
  %i1.sum = fadd float %i1.sadd, %i1.uadd
  %i1.bits = bitcast float %i1.sum to i32
  ; fp->i1 only with in-range values: signed i1 is {0,-1}, unsigned i1 is {0,1}
  %i1.si0 = fptosi float 0.000000e+00 to i1
  %i1.si1 = fptosi float -1.000000e+00 to i1
  %i1.ui0 = fptoui float 0.000000e+00 to i1
  %i1.ui1 = fptoui float 1.000000e+00 to i1
  %i1.zi0 = zext i1 %i1.si0 to i32
  %i1.zi1 = zext i1 %i1.si1 to i32
  %i1.zu0 = zext i1 %i1.ui0 to i32
  %i1.zu1 = zext i1 %i1.ui1 to i32
  %i1.zxor = xor i32 %i1.zi0, %i1.zi1
  %i1.uxor = xor i32 %i1.zu0, %i1.zu1
  %i1.mix = xor i32 %i1.zxor, %i1.uxor
  ; Fractional / negative float truncation (fptoui only on non-negative)
  %frac.s = fptosi float -3.750000e+00 to i32
  %frac.u = fptoui float 3.750000e+00 to i32
  ; Round-trip sitofp/fptosi and uitofp/fptoui on small widths
  %rt.s0 = sitofp i16 -100 to float
  %rt.s1 = fptosi float %rt.s0 to i16
  %rt.s = sext i16 %rt.s1 to i32
  %rt.u0 = uitofp i8 200 to float
  %rt.u1 = fptoui float %rt.u0 to i8
  %rt.u = zext i8 %rt.u1 to i32
  ; i64 signed value that fits exactly in float mantissa
  %i64.s0 = sitofp i64 -1000000 to float
  %i64.s1 = fptosi float %i64.s0 to i64
  %i64.st = trunc i64 %i64.s1 to i32
  ; -0.0 through fptosi / fptoui (both yield 0)
  %nz = fneg float 0.000000e+00
  %nz.s = fptosi float %nz to i32
  %nz.u = fptoui float %nz to i32
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

define i32 @protected_float_cast_special() noinline optnone {
entry:
  call void @hikari_vmp()
  %neg = sitofp i32 -42 to float
  %neg.back = fptosi float %neg to i32
  %big32 = uitofp i32 -1 to float
  %big32.bits = bitcast float %big32 to i32
  %big64 = uitofp i64 -1 to float
  %big64.bits = bitcast float %big64 to i32
  %z.s0 = sitofp i32 0 to float
  %z.s1 = fptosi float %z.s0 to i32
  %z.f = fptosi float 0.000000e+00 to i32
  %i1t.s = sitofp i1 true to float
  %i1t.u = uitofp i1 true to float
  %i1f.s = sitofp i1 false to float
  %i1f.u = uitofp i1 false to float
  %i1.sadd = fadd float %i1t.s, %i1f.s
  %i1.uadd = fadd float %i1t.u, %i1f.u
  %i1.sum = fadd float %i1.sadd, %i1.uadd
  %i1.bits = bitcast float %i1.sum to i32
  %i1.si0 = fptosi float 0.000000e+00 to i1
  %i1.si1 = fptosi float -1.000000e+00 to i1
  %i1.ui0 = fptoui float 0.000000e+00 to i1
  %i1.ui1 = fptoui float 1.000000e+00 to i1
  %i1.zi0 = zext i1 %i1.si0 to i32
  %i1.zi1 = zext i1 %i1.si1 to i32
  %i1.zu0 = zext i1 %i1.ui0 to i32
  %i1.zu1 = zext i1 %i1.ui1 to i32
  %i1.zxor = xor i32 %i1.zi0, %i1.zi1
  %i1.uxor = xor i32 %i1.zu0, %i1.zu1
  %i1.mix = xor i32 %i1.zxor, %i1.uxor
  %frac.s = fptosi float -3.750000e+00 to i32
  %frac.u = fptoui float 3.750000e+00 to i32
  %rt.s0 = sitofp i16 -100 to float
  %rt.s1 = fptosi float %rt.s0 to i16
  %rt.s = sext i16 %rt.s1 to i32
  %rt.u0 = uitofp i8 200 to float
  %rt.u1 = fptoui float %rt.u0 to i8
  %rt.u = zext i8 %rt.u1 to i32
  %i64.s0 = sitofp i64 -1000000 to float
  %i64.s1 = fptosi float %i64.s0 to i64
  %i64.st = trunc i64 %i64.s1 to i32
  %nz = fneg float 0.000000e+00
  %nz.s = fptosi float %nz to i32
  %nz.u = fptoui float %nz to i32
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

; Pure SSA double cast smoke (sitofp/uitofp/fptosi/fptoui).
define double @unsupported_sitofp_double(i32 %x) {
entry:
  call void @hikari_vmp()
  %d = sitofp i32 %x to double
  ret double %d
}

define double @unsupported_uitofp_double(i32 %x) {
entry:
  call void @hikari_vmp()
  %d = uitofp i32 %x to double
  ret double %d
}

define i32 @unsupported_fptosi_double(double %d) {
entry:
  call void @hikari_vmp()
  %i = fptosi double %d to i32
  ret i32 %i
}

define i32 @unsupported_fptoui_double(double %d) {
entry:
  call void @hikari_vmp()
  %i = fptoui double %d to i32
  ret i32 %i
}

; Unsupported: fpext float to double.
define double @unsupported_fpext(float %f) {
entry:
  call void @hikari_vmp()
  %d = fpext float %f to double
  ret double %d
}

; Unsupported: fptrunc double to float.
define float @unsupported_fptrunc(double %d) {
entry:
  call void @hikari_vmp()
  %f = fptrunc double %d to float
  ret float %f
}

define i32 @main() {
entry:
  %e0 = call i32 @reference(float 1.500000e+00, float 2.250000e+00)
  %a0 = call i32 @protected(float 1.500000e+00, float 2.250000e+00)
  %e1 = call i32 @reference_special()
  %a1 = call i32 @protected_special()
  %e2 = call i32 @reference_fret_bits(float 3.000000e+00, float 4.000000e+00)
  %a2 = call i32 @protected_fret_bits(float 3.000000e+00, float 4.000000e+00)
  %e3 = call i32 @reference_float_phi_bits(i1 true, float 1.500000e+00, float 2.250000e+00)
  %a3 = call i32 @protected_float_phi_bits(i1 true, float 1.500000e+00, float 2.250000e+00)
  %e4 = call i32 @reference_float_phi_bits(i1 false, float 1.500000e+00, float 2.250000e+00)
  %a4 = call i32 @protected_float_phi_bits(i1 false, float 1.500000e+00, float 2.250000e+00)
  %e5 = call i32 @reference_float_phi_special()
  %a5 = call i32 @protected_float_phi_special()
  %e6 = call i32 @reference_float_mem(float 1.500000e+00, float 2.250000e+00)
  %a6 = call i32 @protected_float_mem(float 1.500000e+00, float 2.250000e+00)
  %e7 = call i32 @reference_float_mem_special()
  %a7 = call i32 @protected_float_mem_special()
  %e8 = call i32 @reference_float_call(float 1.500000e+00, float 2.250000e+00)
  %a8 = call i32 @protected_float_call(float 1.500000e+00, float 2.250000e+00)
  ; Multi-width casts: non-negative float so fptoui stays defined; negative x exercises sitofp.
  %e9 = call i32 @reference_float_cast(i32 7, float 3.500000e+00)
  %a9 = call i32 @protected_float_cast(i32 7, float 3.500000e+00)
  %e10 = call i32 @reference_float_cast(i32 -9, float 2.250000e+00)
  %a10 = call i32 @protected_float_cast(i32 -9, float 2.250000e+00)
  %e11 = call i32 @reference_float_cast(i32 0, float 0.000000e+00)
  %a11 = call i32 @protected_float_cast(i32 0, float 0.000000e+00)
  %e12 = call i32 @reference_float_cast(i32 1, float 1.000000e+00)
  %a12 = call i32 @protected_float_cast(i32 1, float 1.000000e+00)
  %e13 = call i32 @reference_float_cast_special()
  %a13 = call i32 @protected_float_cast_special()
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
  %ok = and i1 %t11, %m13
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP-NOT: Skipping VMP on unsupported_double_call_arg:
; SKIP-NOT: Skipping VMP on unsupported_indirect_float_call:
; SKIP-DAG: Skipping VMP on unsupported_fast_fadd: unsupported float fadd instruction
; SKIP-DAG: Skipping VMP on unsupported_atomic_float_load: unsupported float load instruction
; SKIP-DAG: Skipping VMP on unsupported_atomic_float_store: unsupported float store instruction
; SKIP-NOT: Skipping VMP on unsupported_fpext:
; SKIP-NOT: Skipping VMP on unsupported_fptrunc:
; Pure SSA double surfaces are virtualized (see vmp-fadd-double.ll).
; SKIP-NOT: Skipping VMP on unsupported_double:
; SKIP-NOT: Skipping VMP on unsupported_double_fcmp:
; SKIP-NOT: Skipping VMP on unsupported_double_select:
; SKIP-NOT: Skipping VMP on unsupported_double_phi:
; SKIP-NOT: Skipping VMP on unsupported_double_mem:
; SKIP-NOT: Skipping VMP on unsupported_sitofp_double:
; SKIP-NOT: Skipping VMP on unsupported_uitofp_double:
; SKIP-NOT: Skipping VMP on unsupported_fptosi_double:
; SKIP-NOT: Skipping VMP on unsupported_fptoui_double:

; VIRT-LABEL: define i32 @protected(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: fadd float
; VIRT-DAG: fsub float
; VIRT-DAG: fmul float
; VIRT-DAG: fdiv float
; VIRT-DAG: frem float
; VIRT-DAG: fneg float
; VIRT-DAG: fcmp {{.*}} float
; VIRT-DAG: select i1 {{.*}} float
; VIRT-LABEL: define i32 @protected_special(
; VIRT: %vmp.fregs = alloca
; VIRT-DAG: fadd float
; VIRT-DAG: fsub float
; VIRT-DAG: fmul float
; VIRT-DAG: fdiv float
; VIRT-DAG: frem float
; VIRT-DAG: fneg float
; VIRT-DAG: fcmp {{.*}} float
; VIRT-DAG: select i1 {{.*}} float
; VIRT-LABEL: define float @protected_fret(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: fadd float
; VIRT-DAG: fsub float
; VIRT-DAG: fmul float
; VIRT-DAG: fdiv float
; VIRT-DAG: frem float
; VIRT-DAG: fneg float
; VIRT-DAG: fcmp {{.*}} float
; VIRT-DAG: select i1 {{.*}} float
; VIRT-DAG: ret float
; VIRT-LABEL: define i32 @protected_float_call(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: fadd float
; VIRT-DAG: call void @float_sink(float
; VIRT-DAG: call float @float_combine(float
; VIRT-LABEL: define float @unsupported_double_call_arg(
; VIRT: fptrunc double
; VIRT-LABEL: define float @unsupported_indirect_float_call(
; VIRT: vmp.dispatch:
; VIRT: call float
; VIRT-LABEL: define i32 @protected_fast_float_call(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT: call nnan ninf float @float_combine
; VIRT-LABEL: define i32 @protected_fast_fneg(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT: fneg fast float
; VIRT-LABEL: define i1 @protected_fast_fcmp(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT: fcmp fast oeq float
; VIRT-LABEL: define double @unsupported_double(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: fadd double
; VIRT-LABEL: define i1 @unsupported_double_fcmp(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: fcmp {{.*}} double
; VIRT-LABEL: define double @unsupported_double_select(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: select i1 {{.*}} double
; VIRT-LABEL: define float @protected_float_phi(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: fadd float
; VIRT-DAG: fsub float
; VIRT-DAG: fneg float
; VIRT-DAG: ret float
; Residual SSA float PHI must be gone (lowered to FloatMove edge copies).
; Bound NOT to the next define so intermediate non-virtualized PHI IR is not scanned.
; VIRT-NOT: phi float
; VIRT-LABEL: define i32 @reference_float_phi_bits(
; VIRT-LABEL: define i32 @protected_float_phi_special(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: fneg float
; VIRT-DAG: fmul float
; VIRT-DAG: fadd float
; Loop-carried float PHI must be edge-copied (no residual SSA float PHI).
; VIRT-NOT: phi float
; VIRT-LABEL: define double @unsupported_double_phi(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; Residual SSA double PHI must be gone (lowered to FloatMove edge copies).
; VIRT-NOT: phi double
; VIRT-LABEL: define float @protected_fast_float_phi(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT: select nnan i1 true
; VIRT-NOT: phi float
; VIRT-LABEL: define float @protected_fast_float_select(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT: select nnan ninf i1
; VIRT-LABEL: define float @unsupported_fast_fadd(
; VIRT: fadd fast half
; VIRT-NOT: "hikari.vmp.virtualized"
; VIRT-LABEL: define i32 @protected_float_mem(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: fadd float
; VIRT-DAG: fmul float
; VIRT-DAG: store float
; VIRT-DAG: load float
; VIRT-DAG: store volatile float
; VIRT-DAG: load volatile float
; VIRT-LABEL: define i32 @protected_float_mem_special(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: fneg float
; VIRT-DAG: fadd float
; VIRT-DAG: store float
; VIRT-DAG: load float
; VIRT-LABEL: define double @unsupported_double_mem(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: store double
; VIRT-DAG: load double
; VIRT-LABEL: define void @unsupported_atomic_float_load(
; VIRT: load atomic half
; VIRT-NOT: "hikari.vmp.virtualized"
; VIRT-LABEL: define void @unsupported_atomic_float_store(
; VIRT: store atomic half
; VIRT-NOT: "hikari.vmp.virtualized"
; VIRT-LABEL: define i32 @protected_float_cast(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: sitofp i1 {{.*}} to float
; VIRT-DAG: sitofp i8 {{.*}} to float
; VIRT-DAG: sitofp i16 {{.*}} to float
; VIRT-DAG: sitofp i32 {{.*}} to float
; VIRT-DAG: sitofp i64 {{.*}} to float
; VIRT-DAG: uitofp i1 {{.*}} to float
; VIRT-DAG: uitofp i8 {{.*}} to float
; VIRT-DAG: uitofp i16 {{.*}} to float
; VIRT-DAG: uitofp i32 {{.*}} to float
; VIRT-DAG: uitofp i64 {{.*}} to float
; Avoid "to i1" matching "to i16" — anchor width with non-digit / EOL.
; VIRT-DAG: fptosi float {{.*}} to i8{{([^0-9]|$)}}
; VIRT-DAG: fptosi float {{.*}} to i16{{([^0-9]|$)}}
; VIRT-DAG: fptosi float {{.*}} to i32{{([^0-9]|$)}}
; VIRT-DAG: fptosi float {{.*}} to i64{{([^0-9]|$)}}
; VIRT-DAG: fptoui float {{.*}} to i8{{([^0-9]|$)}}
; VIRT-DAG: fptoui float {{.*}} to i16{{([^0-9]|$)}}
; VIRT-DAG: fptoui float {{.*}} to i32{{([^0-9]|$)}}
; VIRT-DAG: fptoui float {{.*}} to i64{{([^0-9]|$)}}
; VIRT-DAG: fadd float
; VIRT-LABEL: define i32 @protected_float_cast_special(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: sitofp i32 {{.*}} to float
; VIRT-DAG: sitofp i16 {{.*}} to float
; VIRT-DAG: sitofp i1 {{.*}} to float
; VIRT-DAG: sitofp i64 {{.*}} to float
; VIRT-DAG: uitofp i32 {{.*}} to float
; VIRT-DAG: uitofp i64 {{.*}} to float
; VIRT-DAG: uitofp i1 {{.*}} to float
; VIRT-DAG: uitofp i8 {{.*}} to float
; VIRT-DAG: fptosi float {{.*}} to i32{{([^0-9]|$)}}
; VIRT-DAG: fptosi float {{.*}} to i16{{([^0-9]|$)}}
; VIRT-DAG: fptosi float {{.*}} to i1{{([^0-9]|$)}}
; VIRT-DAG: fptosi float {{.*}} to i64{{([^0-9]|$)}}
; VIRT-DAG: fptoui float {{.*}} to i32{{([^0-9]|$)}}
; VIRT-DAG: fptoui float {{.*}} to i1{{([^0-9]|$)}}
; VIRT-DAG: fptoui float {{.*}} to i8{{([^0-9]|$)}}
; VIRT-DAG: fneg float
; VIRT-LABEL: define double @unsupported_sitofp_double(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: sitofp i32 {{.*}} to double
; VIRT-LABEL: define double @unsupported_uitofp_double(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: uitofp i32 {{.*}} to double
; VIRT-LABEL: define i32 @unsupported_fptosi_double(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: fptosi double {{.*}} to i32
; VIRT-LABEL: define i32 @unsupported_fptoui_double(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: fptoui double {{.*}} to i32
; VIRT-LABEL: define double @unsupported_fpext(
; VIRT: fpext float
; VIRT-NOT: "hikari.vmp.virtualized"
; VIRT-LABEL: define float @unsupported_fptrunc(
; VIRT: fptrunc double
; VIRT-NOT: "hikari.vmp.virtualized"
; VIRT: attributes{{.*}}"hikari.vmp.virtualized"
