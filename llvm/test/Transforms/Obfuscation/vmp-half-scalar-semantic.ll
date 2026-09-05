; Restricted scalar half on the existing float VReg frame.  Covers basic
; arith, fcmp, select, phi, stack/global load/store, i16 bitcast,
; integer conversions, fpext/fptrunc with float, direct C call/return,
; and the listed pure math intrinsics (CallDescriptor replay; canonicalize
; still lowers to fmul x, 1.0).  Scalar half math requires last-token
; function "target-features" +fullfp16.  Listed scalar half
; transcendentals (sin/cos/exp/exp2/log/log2/log10/pow/powi.i32) use the
; same CallDescriptor replay and last-token +fullfp16 gate.  Fixed half
; vectors live in vmp-half-vector-semantic.ll.  Listed half-vector math
; with last-token +fullfp16 lives in vmp-half-vector-math-semantic.ll.
; Constrained forms, aggregate fields, atomics, bfloat/fp128 stay rejected.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.ll > %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.live.ll > %t.o0.host.in.ll
; RUN: python3 %S/Inputs/vmp-drop-host-minmax.py %t.o0.host.in.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.ll > %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.live.ll > %t.o2.host.in.ll
; RUN: python3 %S/Inputs/vmp-drop-host-minmax.py %t.o2.host.in.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.s7.ll > %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.s7.live.ll > %t.o0.s7.host.in.ll
; RUN: python3 %S/Inputs/vmp-drop-host-minmax.py %t.o0.s7.host.in.ll > %t.o0.s7.host.ll
; RUN: lli -force-interpreter %t.o0.s7.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.s7.ll > %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.s7.live.ll > %t.o2.s7.host.in.ll
; RUN: python3 %S/Inputs/vmp-drop-host-minmax.py %t.o2.s7.host.in.ll > %t.o2.s7.host.ll
; RUN: lli -force-interpreter %t.o2.s7.host.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare half @llvm.sqrt.f16(half)
declare half @llvm.fma.f16(half, half, half)
declare half @llvm.fmuladd.f16(half, half, half)
declare half @llvm.fabs.f16(half)
declare half @llvm.minnum.f16(half, half)
declare half @llvm.maxnum.f16(half, half)
declare half @llvm.minimum.f16(half, half)
declare half @llvm.maximum.f16(half, half)
declare half @llvm.ceil.f16(half)
declare half @llvm.floor.f16(half)
declare half @llvm.trunc.f16(half)
declare half @llvm.round.f16(half)
declare half @llvm.rint.f16(half)
declare half @llvm.nearbyint.f16(half)
declare half @llvm.roundeven.f16(half)
declare half @llvm.copysign.f16(half, half)
declare half @llvm.canonicalize.f16(half)
declare half @llvm.sin.f16(half)
declare half @llvm.cos.f16(half)
declare half @llvm.exp.f16(half)
declare half @llvm.exp2.f16(half)
declare half @llvm.log.f16(half)
declare half @llvm.log2.f16(half)
declare half @llvm.log10.f16(half)
declare half @llvm.pow.f16(half, half)
declare half @llvm.powi.f16.i32(half, i32)
declare half @llvm.powi.f16.i64(half, i64)
declare <2 x half> @llvm.sqrt.v2f16(<2 x half>)
declare <2 x half> @llvm.sin.v2f16(<2 x half>)
declare bfloat @llvm.sin.bf16(bfloat)

@g.half = private global half 0xH0000, align 2

define i32 @bits_half(half %h) {
entry:
  %i = bitcast half %h to i16
  %z = zext i16 %i to i32
  ret i32 %z
}

define half @add_half(half %a, half %b) noinline {
entry:
  %s = fadd half %a, %b
  ret half %s
}

define i32 @reference_work(half %a, half %b, i1 %c, i16 %raw, i32 %k) noinline optnone {
entry:
  %stk = alloca half, align 2
  %sum = fadd nnan half %a, %b
  %dif = fsub half %sum, %a
  %prod = fmul half %dif, %b
  %quot = fdiv half %prod, %a
  %rem = frem half %quot, %b
  %neg = fneg half %rem
  %ogt = fcmp ogt half %neg, %a
  %sel = select i1 %ogt, half %neg, half %a
  br i1 %c, label %left, label %right

left:
  %lp = fadd half %sel, %a
  br label %join

right:
  %rp = fadd half %sel, %b
  br label %join

join:
  %phi = phi half [ %lp, %left ], [ %rp, %right ]
  store half %phi, ptr %stk, align 2
  %ld = load half, ptr %stk, align 2
  store half %ld, ptr @g.half, align 2
  %gld = load half, ptr @g.half, align 2
  %fromi = bitcast i16 %raw to half
  %toi = bitcast half %gld to i16
  %si = sitofp i32 %k to half
  %ui = uitofp i32 %k to half
  %fi = fptosi half %si to i32
  %fu = fptoui half %ui to i32
  %ext = fpext half %fromi to float
  %tr = fptrunc float %ext to half
  %called = call half @add_half(half %tr, half %a)
  %mix0 = fadd half %called, %fromi
  %b0 = call i32 @bits_half(half %mix0)
  %b1 = zext i16 %toi to i32
  %x0 = xor i32 %b0, %b1
  %x1 = xor i32 %fi, %fu
  %out = xor i32 %x0, %x1
  ret i32 %out
}

define i32 @protected_work(half %a, half %b, i1 %c, i16 %raw, i32 %k) noinline optnone {
entry:
  call void @hikari_vmp()
  %stk = alloca half, align 2
  %sum = fadd nnan half %a, %b
  %dif = fsub half %sum, %a
  %prod = fmul half %dif, %b
  %quot = fdiv half %prod, %a
  %rem = frem half %quot, %b
  %neg = fneg half %rem
  %ogt = fcmp ogt half %neg, %a
  %sel = select i1 %ogt, half %neg, half %a
  br i1 %c, label %left, label %right

left:
  %lp = fadd half %sel, %a
  br label %join

right:
  %rp = fadd half %sel, %b
  br label %join

join:
  %phi = phi half [ %lp, %left ], [ %rp, %right ]
  store half %phi, ptr %stk, align 2
  %ld = load half, ptr %stk, align 2
  store half %ld, ptr @g.half, align 2
  %gld = load half, ptr @g.half, align 2
  %fromi = bitcast i16 %raw to half
  %toi = bitcast half %gld to i16
  %si = sitofp i32 %k to half
  %ui = uitofp i32 %k to half
  %fi = fptosi half %si to i32
  %fu = fptoui half %ui to i32
  %ext = fpext half %fromi to float
  %tr = fptrunc float %ext to half
  %called = call half @add_half(half %tr, half %a)
  %mix0 = fadd half %called, %fromi
  %b0 = call i32 @bits_half(half %mix0)
  %b1 = zext i16 %toi to i32
  %x0 = xor i32 %b0, %b1
  %x1 = xor i32 %fi, %fu
  %out = xor i32 %x0, %x1
  ret i32 %out
}

define i32 @reference(half %a, half %b, i1 %c, i16 %raw, i32 %k) noinline optnone {
entry:
  %r = call i32 @reference_work(half %a, half %b, i1 %c, i16 %raw, i32 %k)
  ret i32 %r
}

define i32 @protected(half %a, half %b, i1 %c, i16 %raw, i32 %k) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @protected_work(half %a, half %b, i1 %c, i16 %raw, i32 %k)
  ret i32 %r
}

; Pure half math via CallDescriptor.  canonicalize is compared against the
; same fmul x, 1.0 lowering VMP applies.  fptosi/fptoui are not used here.
; Special values (NaN, ±0, ±inf) and rounding boundaries are passed in.
define i32 @reference_math(half %a, half %b, half %c) noinline optnone "target-features"="+fullfp16" {
entry:
  %sq = call half @llvm.sqrt.f16(half %a)
  %sqf = call nnan ninf half @llvm.sqrt.f16(half %a)
  %fm = call half @llvm.fma.f16(half %a, half %b, half %c)
  %fa = call half @llvm.fmuladd.f16(half %a, half %b, half %c)
  %ab = call half @llvm.fabs.f16(half %b)
  %abn = call nnan half @llvm.fabs.f16(half %b)
  %mn = call half @llvm.minnum.f16(half %a, half %b)
  %mx = call half @llvm.maxnum.f16(half %a, half %b)
  %ce = call half @llvm.ceil.f16(half %c)
  %fl = call half @llvm.floor.f16(half %c)
  %tr = call half @llvm.trunc.f16(half %c)
  %ro = call half @llvm.round.f16(half %c)
  %ri = call half @llvm.rint.f16(half %c)
  %ni = call half @llvm.nearbyint.f16(half %c)
  %re = call half @llvm.roundeven.f16(half %c)
  %cs = call half @llvm.copysign.f16(half %a, half %b)
  %ca = fmul half %a, 0xH3C00
  %caf = fmul nnan half %a, 0xH3C00
  %b0 = call i32 @bits_half(half %sq)
  %b1 = call i32 @bits_half(half %sqf)
  %b2 = call i32 @bits_half(half %fm)
  %b3 = call i32 @bits_half(half %fa)
  %b4 = call i32 @bits_half(half %ab)
  %b5 = call i32 @bits_half(half %abn)
  %b6 = call i32 @bits_half(half %mn)
  %b7 = call i32 @bits_half(half %mx)
  %b8 = call i32 @bits_half(half %ce)
  %b9 = call i32 @bits_half(half %fl)
  %b10 = call i32 @bits_half(half %tr)
  %b11 = call i32 @bits_half(half %ro)
  %b12 = call i32 @bits_half(half %ri)
  %b13 = call i32 @bits_half(half %ni)
  %b14 = call i32 @bits_half(half %re)
  %b15 = call i32 @bits_half(half %cs)
  %b16 = call i32 @bits_half(half %ca)
  %b17 = call i32 @bits_half(half %caf)
  %x0 = xor i32 %b0, %b1
  %x1 = xor i32 %b2, %b3
  %x2 = xor i32 %b4, %b5
  %x3 = xor i32 %b6, %b7
  %x4 = xor i32 %b8, %b9
  %x5 = xor i32 %b10, %b11
  %x6 = xor i32 %b12, %b13
  %x7 = xor i32 %b14, %b15
  %x8 = xor i32 %b16, %b17
  %y0 = xor i32 %x0, %x1
  %y1 = xor i32 %x2, %x3
  %y2 = xor i32 %x4, %x5
  %y3 = xor i32 %x6, %x7
  %z0 = xor i32 %y0, %y1
  %z1 = xor i32 %y2, %y3
  %out = xor i32 %z0, %z1
  %out2 = xor i32 %out, %x8
  ret i32 %out2
}

define i32 @protected_math(half %a, half %b, half %c) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %sq = call half @llvm.sqrt.f16(half %a)
  %sqf = call nnan ninf half @llvm.sqrt.f16(half %a)
  %fm = call half @llvm.fma.f16(half %a, half %b, half %c)
  %fa = call half @llvm.fmuladd.f16(half %a, half %b, half %c)
  %ab = call half @llvm.fabs.f16(half %b)
  %abn = call nnan half @llvm.fabs.f16(half %b)
  %mn = call half @llvm.minnum.f16(half %a, half %b)
  %mx = call half @llvm.maxnum.f16(half %a, half %b)
  %ce = call half @llvm.ceil.f16(half %c)
  %fl = call half @llvm.floor.f16(half %c)
  %tr = call half @llvm.trunc.f16(half %c)
  %ro = call half @llvm.round.f16(half %c)
  %ri = call half @llvm.rint.f16(half %c)
  %ni = call half @llvm.nearbyint.f16(half %c)
  %re = call half @llvm.roundeven.f16(half %c)
  %cs = call half @llvm.copysign.f16(half %a, half %b)
  %ca = call half @llvm.canonicalize.f16(half %a)
  %caf = call nnan half @llvm.canonicalize.f16(half %a)
  %b0 = call i32 @bits_half(half %sq)
  %b1 = call i32 @bits_half(half %sqf)
  %b2 = call i32 @bits_half(half %fm)
  %b3 = call i32 @bits_half(half %fa)
  %b4 = call i32 @bits_half(half %ab)
  %b5 = call i32 @bits_half(half %abn)
  %b6 = call i32 @bits_half(half %mn)
  %b7 = call i32 @bits_half(half %mx)
  %b8 = call i32 @bits_half(half %ce)
  %b9 = call i32 @bits_half(half %fl)
  %b10 = call i32 @bits_half(half %tr)
  %b11 = call i32 @bits_half(half %ro)
  %b12 = call i32 @bits_half(half %ri)
  %b13 = call i32 @bits_half(half %ni)
  %b14 = call i32 @bits_half(half %re)
  %b15 = call i32 @bits_half(half %cs)
  %b16 = call i32 @bits_half(half %ca)
  %b17 = call i32 @bits_half(half %caf)
  %x0 = xor i32 %b0, %b1
  %x1 = xor i32 %b2, %b3
  %x2 = xor i32 %b4, %b5
  %x3 = xor i32 %b6, %b7
  %x4 = xor i32 %b8, %b9
  %x5 = xor i32 %b10, %b11
  %x6 = xor i32 %b12, %b13
  %x7 = xor i32 %b14, %b15
  %x8 = xor i32 %b16, %b17
  %y0 = xor i32 %x0, %x1
  %y1 = xor i32 %x2, %x3
  %y2 = xor i32 %x4, %x5
  %y3 = xor i32 %x6, %x7
  %z0 = xor i32 %y0, %y1
  %z1 = xor i32 %y2, %y3
  %out = xor i32 %z0, %z1
  %out2 = xor i32 %out, %x8
  ret i32 %out2
}

; Host x86 lli/ORC cannot select llvm.minimum/maximum.f16.  FileCheck and
; AArch64 llc still cover the re-emit; the host lli IR drops this function.
define i32 @protected_minmax(half %a, half %b) noinline optnone "target-features"="+neon,+fullfp16,+fp-armv8" {
entry:
  call void @hikari_vmp()
  %mi = call half @llvm.minimum.f16(half %a, half %b)
  %ma = call half @llvm.maximum.f16(half %a, half %b)
  %mif = call nnan half @llvm.minimum.f16(half %a, half %b)
  %b0 = call i32 @bits_half(half %mi)
  %b1 = call i32 @bits_half(half %ma)
  %b2 = call i32 @bits_half(half %mif)
  %x0 = xor i32 %b0, %b1
  %out = xor i32 %x0, %b2
  ret i32 %out
}

; Finite in-domain halfs only.  Do not bit-compare NaN/inf/domain errors.
define i32 @reference_transcendental(half %x, half %y, i32 %e) noinline optnone "target-features"="+fullfp16" {
entry:
  %si = call half @llvm.sin.f16(half %x)
  %sif = call nnan ninf half @llvm.sin.f16(half %x)
  %co = call half @llvm.cos.f16(half %x)
  %ex = call half @llvm.exp.f16(half %x)
  %e2 = call half @llvm.exp2.f16(half %x)
  %lg = call half @llvm.log.f16(half %y)
  %l2 = call half @llvm.log2.f16(half %y)
  %l10 = call half @llvm.log10.f16(half %y)
  %pw = call half @llvm.pow.f16(half %y, half %x)
  %pwi = call half @llvm.powi.f16.i32(half %y, i32 %e)
  %b0 = call i32 @bits_half(half %si)
  %b1 = call i32 @bits_half(half %sif)
  %b2 = call i32 @bits_half(half %co)
  %b3 = call i32 @bits_half(half %ex)
  %b4 = call i32 @bits_half(half %e2)
  %b5 = call i32 @bits_half(half %lg)
  %b6 = call i32 @bits_half(half %l2)
  %b7 = call i32 @bits_half(half %l10)
  %b8 = call i32 @bits_half(half %pw)
  %b9 = call i32 @bits_half(half %pwi)
  %x0 = xor i32 %b0, %b1
  %x1 = xor i32 %b2, %b3
  %x2 = xor i32 %b4, %b5
  %x3 = xor i32 %b6, %b7
  %x4 = xor i32 %b8, %b9
  %y0 = xor i32 %x0, %x1
  %y1 = xor i32 %x2, %x3
  %out = xor i32 %y0, %y1
  %out2 = xor i32 %out, %x4
  ret i32 %out2
}

define i32 @protected_transcendental(half %x, half %y, i32 %e) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %si = call half @llvm.sin.f16(half %x)
  %sif = call nnan ninf half @llvm.sin.f16(half %x)
  %co = call half @llvm.cos.f16(half %x)
  %ex = call half @llvm.exp.f16(half %x)
  %e2 = call half @llvm.exp2.f16(half %x)
  %lg = call half @llvm.log.f16(half %y)
  %l2 = call half @llvm.log2.f16(half %y)
  %l10 = call half @llvm.log10.f16(half %y)
  %pw = call half @llvm.pow.f16(half %y, half %x)
  %pwi = call half @llvm.powi.f16.i32(half %y, i32 %e)
  %b0 = call i32 @bits_half(half %si)
  %b1 = call i32 @bits_half(half %sif)
  %b2 = call i32 @bits_half(half %co)
  %b3 = call i32 @bits_half(half %ex)
  %b4 = call i32 @bits_half(half %e2)
  %b5 = call i32 @bits_half(half %lg)
  %b6 = call i32 @bits_half(half %l2)
  %b7 = call i32 @bits_half(half %l10)
  %b8 = call i32 @bits_half(half %pw)
  %b9 = call i32 @bits_half(half %pwi)
  %x0 = xor i32 %b0, %b1
  %x1 = xor i32 %b2, %b3
  %x2 = xor i32 %b4, %b5
  %x3 = xor i32 %b6, %b7
  %x4 = xor i32 %b8, %b9
  %y0 = xor i32 %x0, %x1
  %y1 = xor i32 %x2, %x3
  %out = xor i32 %y0, %y1
  %out2 = xor i32 %out, %x4
  ret i32 %out2
}

; Well-shaped half sin/pow without last-token +fullfp16.
define i32 @unsupported_sin_f16(half %h) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.sin.f16(half %h)
  %b = bitcast half %r to i16
  %z = zext i16 %b to i32
  ret i32 %z
}

define i32 @unsupported_pow_f16(half %h) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.pow.f16(half %h, half %h)
  %b = bitcast half %r to i16
  %z = zext i16 %b to i32
  ret i32 %z
}

define i32 @unsupported_half_transcendental_fullfp16_disabled(half %h) noinline optnone "target-features"="+neon,+fullfp16,-fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.cos.f16(half %h)
  %b = bitcast half %r to i16
  %z = zext i16 %b to i32
  ret i32 %z
}

define i32 @unsupported_sin_v2f16(<2 x half> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x half> @llvm.sin.v2f16(<2 x half> %v)
  %e = extractelement <2 x half> %r, i32 0
  %b = bitcast half %e to i16
  %z = zext i16 %b to i32
  ret i32 %z
}

define i32 @unsupported_sin_bf16() noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.sin.bf16(bfloat 0.000000e+00)
  %e = fpext bfloat %r to float
  %bits = bitcast float %e to i32
  ret i32 %bits
}

define i32 @unsupported_powi_i64(half %h, i64 %e) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.powi.f16.i64(half %h, i64 %e)
  %b = bitcast half %r to i16
  %z = zext i16 %b to i32
  ret i32 %z
}

define i32 @unsupported_sqrt_v2f16(<2 x half> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x half> @llvm.sqrt.v2f16(<2 x half> %v)
  %e = extractelement <2 x half> %r, i32 0
  %b = bitcast half %e to i16
  %z = zext i16 %b to i32
  ret i32 %z
}

; Well-shaped scalar half math without function +fullfp16.
define i32 @unsupported_half_math_no_fullfp16(half %h) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.sqrt.f16(half %h)
  %b = bitcast half %r to i16
  %z = zext i16 %b to i32
  ret i32 %z
}

; Last token wins: +fullfp16 then -fullfp16 is disabled.
define i32 @unsupported_half_math_fullfp16_disabled(half %h) noinline optnone "target-features"="+neon,+fullfp16,-fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.fabs.f16(half %h)
  %c = call half @llvm.ceil.f16(half %r)
  %b = bitcast half %c to i16
  %z = zext i16 %b to i32
  ret i32 %z
}

define i32 @unsupported_bfloat(bfloat %a, bfloat %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %s = fadd bfloat %a, %b
  %e = fpext bfloat %s to float
  %bits = bitcast float %e to i32
  ret i32 %bits
}

; Supported <2 x half> freeze is covered in vmp-half-vector-semantic.ll.
; Wide half freeze stays off VectorFreeze.
define i32 @unsupported_half_vector_freeze() noinline optnone {
entry:
  call void @hikari_vmp()
  %f = freeze <16 x half> zeroinitializer
  ret i32 0
}

define i32 @unsupported_half_atomic(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %v = load atomic half, ptr %p seq_cst, align 2
  %b = bitcast half %v to i16
  %z = zext i16 %b to i32
  ret i32 %z
}

define i32 @main() {
entry:
  %e0 = call i32 @reference(half 0xH3C00, half 0xH4000, i1 true, i16 15360, i32 2)
  %a0 = call i32 @protected(half 0xH3C00, half 0xH4000, i1 true, i16 15360, i32 2)
  %ok0 = icmp eq i32 %e0, %a0
  %e1 = call i32 @reference(half 0xH4200, half 0xH3800, i1 false, i16 16384, i32 1)
  %a1 = call i32 @protected(half 0xH4200, half 0xH3800, i1 false, i16 16384, i32 1)
  %ok1 = icmp eq i32 %e1, %a1
  ; %a is finite non-negative so nnan/ninf sqrt is defined.
  ; 4.0, -2.0, 1.5
  %em0 = call i32 @reference_math(half 0xH4400, half 0xHC000, half 0xH3E00)
  %pm0 = call i32 @protected_math(half 0xH4400, half 0xHC000, half 0xH3E00)
  %ok2 = icmp eq i32 %em0, %pm0
  ; +0, -0, 2.5
  %em1 = call i32 @reference_math(half 0xH0000, half 0xH8000, half 0xH4100)
  %pm1 = call i32 @protected_math(half 0xH0000, half 0xH8000, half 0xH4100)
  %ok3 = icmp eq i32 %em1, %pm1
  ; 1.0, -inf, -1.5
  %em2 = call i32 @reference_math(half 0xH3C00, half 0xHFC00, half 0xHBE00)
  %pm2 = call i32 @protected_math(half 0xH3C00, half 0xHFC00, half 0xHBE00)
  %ok4 = icmp eq i32 %em2, %pm2
  ; 0.25, qNaN, +inf  (min/max/copysign/fabs of NaN and inf)
  %em3 = call i32 @reference_math(half 0xH3400, half 0xH7E00, half 0xH7C00)
  %pm3 = call i32 @protected_math(half 0xH3400, half 0xH7E00, half 0xH7C00)
  %ok5 = icmp eq i32 %em3, %pm3
  ; 0.5, 2.0, powi 2 — finite, in-domain for all nine listed calls.
  %et = call i32 @reference_transcendental(half 0xH3800, half 0xH4000, i32 2)
  %pt = call i32 @protected_transcendental(half 0xH3800, half 0xH4000, i32 2)
  %ok6 = icmp eq i32 %et, %pt
  %t0 = and i1 %ok0, %ok1
  %t1 = and i1 %ok2, %ok3
  %t2 = and i1 %ok4, %ok5
  %t3 = and i1 %t0, %t1
  %t4 = and i1 %t2, %ok6
  %ok = and i1 %t3, %t4
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP-DAG: Skipping VMP on unsupported_bfloat: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_half_vector_freeze: unsupported freeze instruction
; SKIP-DAG: Skipping VMP on unsupported_half_atomic: unsupported float load instruction
; SKIP-DAG: Skipping VMP on unsupported_sin_f16: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_pow_f16: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_half_transcendental_fullfp16_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_sin_v2f16: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_sin_bf16: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_powi_i64: unsupported powi
; SKIP-DAG: Skipping VMP on unsupported_sqrt_v2f16: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_half_math_no_fullfp16: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_half_math_fullfp16_disabled: unsupported target feature
; SKIP-NOT: Skipping VMP on protected:
; SKIP-NOT: Skipping VMP on protected_work:
; SKIP-NOT: Skipping VMP on protected_math:
; SKIP-NOT: Skipping VMP on protected_minmax:
; SKIP-NOT: Skipping VMP on protected_transcendental:
; SKIP-NOT: Skipping VMP on reference:
; SKIP-NOT: Skipping VMP on reference_work:
; SKIP-NOT: Skipping VMP on reference_math:
; SKIP-NOT: Skipping VMP on reference_transcendental:
; SKIP-NOT: Skipping VMP on add_half:

; VIRT-LABEL: define i32 @reference_work(
; VIRT-NOT: vmp.dispatch

; VIRT-LABEL: define i32 @protected_work(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: fadd{{.*}} half
; VIRT-DAG: fsub half
; VIRT-DAG: fmul half
; VIRT-DAG: fdiv half
; VIRT-DAG: frem half
; VIRT-DAG: fneg half
; VIRT-DAG: fcmp ogt half
; VIRT-DAG: select i1 {{.*}}, half
; VIRT-DAG: store{{.*}} half
; VIRT-DAG: load half
; VIRT-DAG: bitcast half {{.*}} to i16
; VIRT-DAG: bitcast i16 {{.*}} to half
; VIRT-DAG: sitofp i32 {{.*}} to half
; VIRT-DAG: fpext half {{.*}} to float
; VIRT-DAG: fptrunc float {{.*}} to half
; VIRT-DAG: call half @add_half(

; VIRT-LABEL: define i32 @protected(
; VIRT: vmp.dispatch:
; VIRT: call i32 @protected_work(

; VIRT-LABEL: define i32 @protected_math(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: call half @llvm.sqrt.f16(
; VIRT-DAG: call nnan ninf half @llvm.sqrt.f16(
; VIRT-DAG: call half @llvm.fma.f16(
; VIRT-DAG: call half @llvm.fmuladd.f16(
; VIRT-DAG: call half @llvm.fabs.f16(
; VIRT-DAG: call nnan half @llvm.fabs.f16(
; VIRT-DAG: call half @llvm.minnum.f16(
; VIRT-DAG: call half @llvm.maxnum.f16(
; VIRT-DAG: call half @llvm.ceil.f16(
; VIRT-DAG: call half @llvm.floor.f16(
; VIRT-DAG: call half @llvm.trunc.f16(
; VIRT-DAG: call half @llvm.round.f16(
; VIRT-DAG: call half @llvm.rint.f16(
; VIRT-DAG: call half @llvm.nearbyint.f16(
; VIRT-DAG: call half @llvm.roundeven.f16(
; VIRT-DAG: call half @llvm.copysign.f16(
; VIRT-DAG: fmul{{.*}} half
; VIRT-NOT: call{{.*}} @llvm.canonicalize.f16(

; VIRT-LABEL: define i32 @protected_minmax(
; VIRT: vmp.dispatch:
; VIRT-DAG: call half @llvm.minimum.f16(
; VIRT-DAG: call half @llvm.maximum.f16(
; VIRT-DAG: call nnan half @llvm.minimum.f16(

; VIRT-LABEL: define i32 @protected_transcendental(
; VIRT: vmp.dispatch:
; VIRT-DAG: call half @llvm.sin.f16(
; VIRT-DAG: call nnan ninf half @llvm.sin.f16(
; VIRT-DAG: call half @llvm.cos.f16(
; VIRT-DAG: call half @llvm.exp.f16(
; VIRT-DAG: call half @llvm.exp2.f16(
; VIRT-DAG: call half @llvm.log.f16(
; VIRT-DAG: call half @llvm.log2.f16(
; VIRT-DAG: call half @llvm.log10.f16(
; VIRT-DAG: call half @llvm.pow.f16(
; VIRT-DAG: call half @llvm.powi.f16.i32(

; VIRT: define {{.*}} @unsupported_sin_f16({{.*}} #[[UNSUPATTR:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_pow_f16({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_half_transcendental_fullfp16_disabled({{.*}} #[[UNSUPFEAT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_sin_v2f16({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_sin_bf16({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_powi_i64(
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_sqrt_v2f16({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_half_math_no_fullfp16({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_half_math_fullfp16_disabled({{.*}} #[[UNSUPFEAT]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_bfloat({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_half_vector_freeze({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_half_atomic({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #{{[0-9]+}} = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT: attributes #[[UNSUPFEAT]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPFEAT]] = { {{.*}}"hikari.vmp.virtualized"