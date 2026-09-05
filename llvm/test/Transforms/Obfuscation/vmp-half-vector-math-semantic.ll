; Restricted listed math on fixed IEEE half vectors (total width 1..128)
; via existing CallDescriptor replay (F16 vector VRegs, FastMathFlags).
; Requires last-token function "target-features" +fullfp16.  Scalar half,
; f32/f64, and base half-vector SSA are not gated here.
;
; Host x86 lli/ORC cannot select llvm.minimum/maximum.v4f16.  Those stay
; FileCheck + AArch64 llc only (function +fullfp16, no global -mattr).
; Other listed ops are compared on finite in-domain inputs.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP-O0 < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.ll > %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.live.ll > %t.o0.host.in.ll
; RUN: python3 %S/Inputs/vmp-drop-host-half-vec-math.py %t.o0.host.in.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.ll > %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.live.ll > %t.o2.host.in.ll
; RUN: python3 %S/Inputs/vmp-drop-host-half-vec-math.py %t.o2.host.in.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP-O0 < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.s7.ll > %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.s7.live.ll > %t.o0.s7.host.in.ll
; RUN: python3 %S/Inputs/vmp-drop-host-half-vec-math.py %t.o0.s7.host.in.ll > %t.o0.s7.host.ll
; RUN: lli -force-interpreter %t.o0.s7.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.s7.ll > %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.s7.live.ll > %t.o2.s7.host.in.ll
; RUN: python3 %S/Inputs/vmp-drop-host-half-vec-math.py %t.o2.s7.host.in.ll > %t.o2.s7.host.ll
; RUN: lli -force-interpreter %t.o2.s7.host.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()

declare <4 x half> @llvm.sqrt.v4f16(<4 x half>)
declare <4 x half> @llvm.fma.v4f16(<4 x half>, <4 x half>, <4 x half>)
declare <4 x half> @llvm.fmuladd.v4f16(<4 x half>, <4 x half>, <4 x half>)
declare <4 x half> @llvm.fabs.v4f16(<4 x half>)
declare <4 x half> @llvm.minnum.v4f16(<4 x half>, <4 x half>)
declare <4 x half> @llvm.maxnum.v4f16(<4 x half>, <4 x half>)
declare <4 x half> @llvm.minimum.v4f16(<4 x half>, <4 x half>)
declare <4 x half> @llvm.maximum.v4f16(<4 x half>, <4 x half>)
declare <4 x half> @llvm.ceil.v4f16(<4 x half>)
declare <4 x half> @llvm.floor.v4f16(<4 x half>)
declare <4 x half> @llvm.trunc.v4f16(<4 x half>)
declare <4 x half> @llvm.round.v4f16(<4 x half>)
declare <4 x half> @llvm.rint.v4f16(<4 x half>)
declare <4 x half> @llvm.nearbyint.v4f16(<4 x half>)
declare <4 x half> @llvm.roundeven.v4f16(<4 x half>)
declare <4 x half> @llvm.copysign.v4f16(<4 x half>, <4 x half>)
declare <4 x half> @llvm.sin.v4f16(<4 x half>)
declare <4 x half> @llvm.cos.v4f16(<4 x half>)
declare <4 x half> @llvm.exp.v4f16(<4 x half>)
declare <4 x half> @llvm.exp2.v4f16(<4 x half>)
declare <4 x half> @llvm.log.v4f16(<4 x half>)
declare <4 x half> @llvm.log2.v4f16(<4 x half>)
declare <4 x half> @llvm.log10.v4f16(<4 x half>)
declare <4 x half> @llvm.pow.v4f16(<4 x half>, <4 x half>)
declare <4 x half> @llvm.powi.v4f16.i32(<4 x half>, i32)
declare <4 x half> @llvm.powi.v4f16.i64(<4 x half>, i64)
declare <4 x bfloat> @llvm.sqrt.v4bf16(<4 x bfloat>)
declare <vscale x 4 x half> @llvm.sqrt.nxv4f16(<vscale x 4 x half>)
declare <16 x half> @llvm.sqrt.v16f16(<16 x half>)

declare <4 x half> @llvm.experimental.constrained.pow.v4f16(<4 x half>, <4 x half>, metadata, metadata)

define i32 @fold_i16x4(<4 x i16> %v) {
entry:
  %e0 = extractelement <4 x i16> %v, i32 0
  %e1 = extractelement <4 x i16> %v, i32 1
  %e2 = extractelement <4 x i16> %v, i32 2
  %e3 = extractelement <4 x i16> %v, i32 3
  %z0 = zext i16 %e0 to i32
  %z1 = zext i16 %e1 to i32
  %z2 = zext i16 %e2 to i32
  %z3 = zext i16 %e3 to i32
  %s0 = add i32 %z0, %z1
  %s1 = add i32 %z2, %z3
  %r = xor i32 %s0, %s1
  ret i32 %r
}

define i32 @fold_halfx4(<4 x half> %v) {
entry:
  %bits = bitcast <4 x half> %v to <4 x i16>
  %r = call i32 @fold_i16x4(<4 x i16> %bits)
  ret i32 %r
}

define <4 x half> @make_h4(half %a, half %b, half %c, half %d) {
entry:
  %v0 = insertelement <4 x half> poison, half %a, i32 0
  %v1 = insertelement <4 x half> %v0, half %b, i32 1
  %v2 = insertelement <4 x half> %v1, half %c, i32 2
  %v3 = insertelement <4 x half> %v2, half %d, i32 3
  ret <4 x half> %v3
}

define i32 @reference_math(<4 x half> %a, <4 x half> %b, <4 x half> %c, i32 %e) noinline optnone "target-features"="+fullfp16" {
entry:
  %sq = call <4 x half> @llvm.sqrt.v4f16(<4 x half> %a)
  %sqf = call nnan ninf <4 x half> @llvm.sqrt.v4f16(<4 x half> %a)
  %fm = call <4 x half> @llvm.fma.v4f16(<4 x half> %a, <4 x half> %b, <4 x half> %c)
  %fa = call <4 x half> @llvm.fmuladd.v4f16(<4 x half> %a, <4 x half> %b, <4 x half> %c)
  %ab = call <4 x half> @llvm.fabs.v4f16(<4 x half> %b)
  %mn = call <4 x half> @llvm.minnum.v4f16(<4 x half> %a, <4 x half> %b)
  %mx = call <4 x half> @llvm.maxnum.v4f16(<4 x half> %a, <4 x half> %b)
  %ce = call <4 x half> @llvm.ceil.v4f16(<4 x half> %c)
  %fl = call <4 x half> @llvm.floor.v4f16(<4 x half> %c)
  %tr = call <4 x half> @llvm.trunc.v4f16(<4 x half> %c)
  %ro = call <4 x half> @llvm.round.v4f16(<4 x half> %c)
  %ri = call <4 x half> @llvm.rint.v4f16(<4 x half> %c)
  %ni = call <4 x half> @llvm.nearbyint.v4f16(<4 x half> %c)
  %re = call <4 x half> @llvm.roundeven.v4f16(<4 x half> %c)
  %cs = call <4 x half> @llvm.copysign.v4f16(<4 x half> %a, <4 x half> %b)
  %pwi = call <4 x half> @llvm.powi.v4f16.i32(<4 x half> %b, i32 %e)
  %r0 = call i32 @fold_halfx4(<4 x half> %sq)
  %r1 = call i32 @fold_halfx4(<4 x half> %sqf)
  %r2 = call i32 @fold_halfx4(<4 x half> %fm)
  %r3 = call i32 @fold_halfx4(<4 x half> %fa)
  %r4 = call i32 @fold_halfx4(<4 x half> %ab)
  %r5 = call i32 @fold_halfx4(<4 x half> %mn)
  %r6 = call i32 @fold_halfx4(<4 x half> %mx)
  %r7 = call i32 @fold_halfx4(<4 x half> %ce)
  %r8 = call i32 @fold_halfx4(<4 x half> %fl)
  %r9 = call i32 @fold_halfx4(<4 x half> %tr)
  %r10 = call i32 @fold_halfx4(<4 x half> %ro)
  %r11 = call i32 @fold_halfx4(<4 x half> %ri)
  %r12 = call i32 @fold_halfx4(<4 x half> %ni)
  %r13 = call i32 @fold_halfx4(<4 x half> %re)
  %r14 = call i32 @fold_halfx4(<4 x half> %cs)
  %r15 = call i32 @fold_halfx4(<4 x half> %pwi)
  %x0 = xor i32 %r0, %r1
  %x1 = xor i32 %r2, %r3
  %x2 = xor i32 %r4, %r5
  %x3 = xor i32 %r6, %r7
  %x4 = xor i32 %r8, %r9
  %x5 = xor i32 %r10, %r11
  %x6 = xor i32 %r12, %r13
  %x7 = xor i32 %r14, %r15
  %y0 = xor i32 %x0, %x1
  %y1 = xor i32 %x2, %x3
  %y2 = xor i32 %x4, %x5
  %y3 = xor i32 %x6, %x7
  %out = xor i32 %y0, %y1
  %out2 = xor i32 %y2, %y3
  %out3 = xor i32 %out, %out2
  ret i32 %out3
}

define i32 @protected_math(<4 x half> %a, <4 x half> %b, <4 x half> %c, i32 %e) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %sq = call <4 x half> @llvm.sqrt.v4f16(<4 x half> %a)
  %sqf = call nnan ninf <4 x half> @llvm.sqrt.v4f16(<4 x half> %a)
  %fm = call <4 x half> @llvm.fma.v4f16(<4 x half> %a, <4 x half> %b, <4 x half> %c)
  %fa = call <4 x half> @llvm.fmuladd.v4f16(<4 x half> %a, <4 x half> %b, <4 x half> %c)
  %ab = call <4 x half> @llvm.fabs.v4f16(<4 x half> %b)
  %mn = call <4 x half> @llvm.minnum.v4f16(<4 x half> %a, <4 x half> %b)
  %mx = call <4 x half> @llvm.maxnum.v4f16(<4 x half> %a, <4 x half> %b)
  %ce = call <4 x half> @llvm.ceil.v4f16(<4 x half> %c)
  %fl = call <4 x half> @llvm.floor.v4f16(<4 x half> %c)
  %tr = call <4 x half> @llvm.trunc.v4f16(<4 x half> %c)
  %ro = call <4 x half> @llvm.round.v4f16(<4 x half> %c)
  %ri = call <4 x half> @llvm.rint.v4f16(<4 x half> %c)
  %ni = call <4 x half> @llvm.nearbyint.v4f16(<4 x half> %c)
  %re = call <4 x half> @llvm.roundeven.v4f16(<4 x half> %c)
  %cs = call <4 x half> @llvm.copysign.v4f16(<4 x half> %a, <4 x half> %b)
  %pwi = call <4 x half> @llvm.powi.v4f16.i32(<4 x half> %b, i32 %e)
  %r0 = call i32 @fold_halfx4(<4 x half> %sq)
  %r1 = call i32 @fold_halfx4(<4 x half> %sqf)
  %r2 = call i32 @fold_halfx4(<4 x half> %fm)
  %r3 = call i32 @fold_halfx4(<4 x half> %fa)
  %r4 = call i32 @fold_halfx4(<4 x half> %ab)
  %r5 = call i32 @fold_halfx4(<4 x half> %mn)
  %r6 = call i32 @fold_halfx4(<4 x half> %mx)
  %r7 = call i32 @fold_halfx4(<4 x half> %ce)
  %r8 = call i32 @fold_halfx4(<4 x half> %fl)
  %r9 = call i32 @fold_halfx4(<4 x half> %tr)
  %r10 = call i32 @fold_halfx4(<4 x half> %ro)
  %r11 = call i32 @fold_halfx4(<4 x half> %ri)
  %r12 = call i32 @fold_halfx4(<4 x half> %ni)
  %r13 = call i32 @fold_halfx4(<4 x half> %re)
  %r14 = call i32 @fold_halfx4(<4 x half> %cs)
  %r15 = call i32 @fold_halfx4(<4 x half> %pwi)
  %x0 = xor i32 %r0, %r1
  %x1 = xor i32 %r2, %r3
  %x2 = xor i32 %r4, %r5
  %x3 = xor i32 %r6, %r7
  %x4 = xor i32 %r8, %r9
  %x5 = xor i32 %r10, %r11
  %x6 = xor i32 %r12, %r13
  %x7 = xor i32 %r14, %r15
  %y0 = xor i32 %x0, %x1
  %y1 = xor i32 %x2, %x3
  %y2 = xor i32 %x4, %x5
  %y3 = xor i32 %x6, %x7
  %out = xor i32 %y0, %y1
  %out2 = xor i32 %y2, %y3
  %out3 = xor i32 %out, %out2
  ret i32 %out3
}

define i32 @reference_transcendental(<4 x half> %x, <4 x half> %y) noinline optnone "target-features"="+fullfp16" {
entry:
  %si = call <4 x half> @llvm.sin.v4f16(<4 x half> %x)
  %sif = call nnan ninf <4 x half> @llvm.sin.v4f16(<4 x half> %x)
  %co = call <4 x half> @llvm.cos.v4f16(<4 x half> %x)
  %ex = call <4 x half> @llvm.exp.v4f16(<4 x half> %x)
  %e2 = call <4 x half> @llvm.exp2.v4f16(<4 x half> %x)
  %lg = call <4 x half> @llvm.log.v4f16(<4 x half> %y)
  %l2 = call <4 x half> @llvm.log2.v4f16(<4 x half> %y)
  %l10 = call <4 x half> @llvm.log10.v4f16(<4 x half> %y)
  %pw = call <4 x half> @llvm.pow.v4f16(<4 x half> %y, <4 x half> %x)
  %r0 = call i32 @fold_halfx4(<4 x half> %si)
  %r1 = call i32 @fold_halfx4(<4 x half> %sif)
  %r2 = call i32 @fold_halfx4(<4 x half> %co)
  %r3 = call i32 @fold_halfx4(<4 x half> %ex)
  %r4 = call i32 @fold_halfx4(<4 x half> %e2)
  %r5 = call i32 @fold_halfx4(<4 x half> %lg)
  %r6 = call i32 @fold_halfx4(<4 x half> %l2)
  %r7 = call i32 @fold_halfx4(<4 x half> %l10)
  %r8 = call i32 @fold_halfx4(<4 x half> %pw)
  %x0 = xor i32 %r0, %r1
  %x1 = xor i32 %r2, %r3
  %x2 = xor i32 %r4, %r5
  %x3 = xor i32 %r6, %r7
  %y0 = xor i32 %x0, %x1
  %y1 = xor i32 %x2, %x3
  %out = xor i32 %y0, %y1
  %out2 = xor i32 %out, %r8
  ret i32 %out2
}

define i32 @protected_transcendental(<4 x half> %x, <4 x half> %y) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %si = call <4 x half> @llvm.sin.v4f16(<4 x half> %x)
  %sif = call nnan ninf <4 x half> @llvm.sin.v4f16(<4 x half> %x)
  %co = call <4 x half> @llvm.cos.v4f16(<4 x half> %x)
  %ex = call <4 x half> @llvm.exp.v4f16(<4 x half> %x)
  %e2 = call <4 x half> @llvm.exp2.v4f16(<4 x half> %x)
  %lg = call <4 x half> @llvm.log.v4f16(<4 x half> %y)
  %l2 = call <4 x half> @llvm.log2.v4f16(<4 x half> %y)
  %l10 = call <4 x half> @llvm.log10.v4f16(<4 x half> %y)
  %pw = call <4 x half> @llvm.pow.v4f16(<4 x half> %y, <4 x half> %x)
  %r0 = call i32 @fold_halfx4(<4 x half> %si)
  %r1 = call i32 @fold_halfx4(<4 x half> %sif)
  %r2 = call i32 @fold_halfx4(<4 x half> %co)
  %r3 = call i32 @fold_halfx4(<4 x half> %ex)
  %r4 = call i32 @fold_halfx4(<4 x half> %e2)
  %r5 = call i32 @fold_halfx4(<4 x half> %lg)
  %r6 = call i32 @fold_halfx4(<4 x half> %l2)
  %r7 = call i32 @fold_halfx4(<4 x half> %l10)
  %r8 = call i32 @fold_halfx4(<4 x half> %pw)
  %x0 = xor i32 %r0, %r1
  %x1 = xor i32 %r2, %r3
  %x2 = xor i32 %r4, %r5
  %x3 = xor i32 %r6, %r7
  %y0 = xor i32 %x0, %x1
  %y1 = xor i32 %x2, %x3
  %out = xor i32 %y0, %y1
  %out2 = xor i32 %out, %r8
  ret i32 %out2
}

; FileCheck + AArch64 llc only.  Host x86 cannot select fminimum/fmaximum v4f16.
define i32 @reference_minmax(<4 x half> %a, <4 x half> %b) noinline optnone "target-features"="+neon,+fullfp16,+fp-armv8" {
entry:
  %mi = call <4 x half> @llvm.minimum.v4f16(<4 x half> %a, <4 x half> %b)
  %ma = call <4 x half> @llvm.maximum.v4f16(<4 x half> %a, <4 x half> %b)
  %mif = call nnan <4 x half> @llvm.minimum.v4f16(<4 x half> %a, <4 x half> %b)
  %r0 = call i32 @fold_halfx4(<4 x half> %mi)
  %r1 = call i32 @fold_halfx4(<4 x half> %ma)
  %r2 = call i32 @fold_halfx4(<4 x half> %mif)
  %x0 = xor i32 %r0, %r1
  %out = xor i32 %x0, %r2
  ret i32 %out
}

define i32 @protected_minmax(<4 x half> %a, <4 x half> %b) noinline optnone "target-features"="+neon,+fullfp16,+fp-armv8" {
entry:
  call void @hikari_vmp()
  %mi = call <4 x half> @llvm.minimum.v4f16(<4 x half> %a, <4 x half> %b)
  %ma = call <4 x half> @llvm.maximum.v4f16(<4 x half> %a, <4 x half> %b)
  %mif = call nnan <4 x half> @llvm.minimum.v4f16(<4 x half> %a, <4 x half> %b)
  %r0 = call i32 @fold_halfx4(<4 x half> %mi)
  %r1 = call i32 @fold_halfx4(<4 x half> %ma)
  %r2 = call i32 @fold_halfx4(<4 x half> %mif)
  %x0 = xor i32 %r0, %r1
  %out = xor i32 %x0, %r2
  ret i32 %out
}

define i32 @reference_loop(<4 x half> %a, <4 x half> %b, i1 %c) noinline optnone "target-features"="+fullfp16" {
entry:
  br i1 %c, label %left, label %right

left:
  %ls = call <4 x half> @llvm.sqrt.v4f16(<4 x half> %a)
  br label %join

right:
  %rs = call <4 x half> @llvm.fabs.v4f16(<4 x half> %b)
  br label %join

join:
  %phi = phi <4 x half> [ %ls, %left ], [ %rs, %right ]
  %s = fadd <4 x half> %phi, %a
  %out = call i32 @fold_halfx4(<4 x half> %s)
  ret i32 %out
}

define i32 @protected_loop(<4 x half> %a, <4 x half> %b, i1 %c) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  br i1 %c, label %left, label %right

left:
  %ls = call <4 x half> @llvm.sqrt.v4f16(<4 x half> %a)
  br label %join

right:
  %rs = call <4 x half> @llvm.fabs.v4f16(<4 x half> %b)
  br label %join

join:
  %phi = phi <4 x half> [ %ls, %left ], [ %rs, %right ]
  %s = fadd <4 x half> %phi, %a
  %out = call i32 @fold_halfx4(<4 x half> %s)
  ret i32 %out
}

define i32 @unsupported_half_vec_math_no_fullfp16(<4 x half> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x half> @llvm.sqrt.v4f16(<4 x half> %v)
  %e = extractelement <4 x half> %r, i32 0
  %b = bitcast half %e to i16
  %z = zext i16 %b to i32
  ret i32 %z
}

define i32 @unsupported_half_vec_math_fullfp16_disabled(<4 x half> %v) noinline optnone "target-features"="+neon,+fullfp16,-fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x half> @llvm.fabs.v4f16(<4 x half> %v)
  %e = extractelement <4 x half> %r, i32 0
  %b = bitcast half %e to i16
  %z = zext i16 %b to i32
  ret i32 %z
}

define i32 @unsupported_sqrt_v4bf16() noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x bfloat> @llvm.sqrt.v4bf16(<4 x bfloat> zeroinitializer)
  ret i32 0
}

define i32 @unsupported_sqrt_nxv4f16() noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x half> @llvm.sqrt.nxv4f16(<vscale x 4 x half> zeroinitializer)
  ret i32 0
}

define i32 @unsupported_sqrt_v16f16(<16 x half> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <16 x half> @llvm.sqrt.v16f16(<16 x half> %v)
  ret i32 0
}

define i32 @unsupported_constrained_v4f16(<4 x half> %v) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x half> @llvm.experimental.constrained.pow.v4f16(<4 x half> %v, <4 x half> %v, metadata !"round.tonearest", metadata !"fpexcept.ignore") [ "deopt"(i32 0) ]
  %e = extractelement <4 x half> %r, i32 0
  %b = bitcast half %e to i16
  %z = zext i16 %b to i32
  ret i32 %z
}

define i32 @unsupported_powi_v4f16_i64(<4 x half> %v, i64 %e) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x half> @llvm.powi.v4f16.i64(<4 x half> %v, i64 %e)
  %x = extractelement <4 x half> %r, i32 0
  %b = bitcast half %x to i16
  %z = zext i16 %b to i32
  ret i32 %z
}

define i32 @main() {
entry:
  ; 4,2,1,0.5 and 2,1,4,0.5 and 1.5,2.5,0.5,1 ; powi 2
  %a = call <4 x half> @make_h4(half 0xH4400, half 0xH4000, half 0xH3C00, half 0xH3800)
  %b = call <4 x half> @make_h4(half 0xH4000, half 0xH3C00, half 0xH4400, half 0xH3800)
  %c = call <4 x half> @make_h4(half 0xH3E00, half 0xH4100, half 0xH3800, half 0xH3C00)
  %em = call i32 @reference_math(<4 x half> %a, <4 x half> %b, <4 x half> %c, i32 2)
  %pm = call i32 @protected_math(<4 x half> %a, <4 x half> %b, <4 x half> %c, i32 2)
  %ok0 = icmp eq i32 %em, %pm
  %x = call <4 x half> @make_h4(half 0xH3800, half 0xH3C00, half 0xH3400, half 0xH3800)
  %y = call <4 x half> @make_h4(half 0xH4000, half 0xH4400, half 0xH3C00, half 0xH4000)
  %et = call i32 @reference_transcendental(<4 x half> %x, <4 x half> %y)
  %pt = call i32 @protected_transcendental(<4 x half> %x, <4 x half> %y)
  %ok1 = icmp eq i32 %et, %pt
  %el0 = call i32 @reference_loop(<4 x half> %a, <4 x half> %b, i1 true)
  %pl0 = call i32 @protected_loop(<4 x half> %a, <4 x half> %b, i1 true)
  %ok2 = icmp eq i32 %el0, %pl0
  %el1 = call i32 @reference_loop(<4 x half> %b, <4 x half> %c, i1 false)
  %pl1 = call i32 @protected_loop(<4 x half> %b, <4 x half> %c, i1 false)
  %ok3 = icmp eq i32 %el1, %pl1
  %t0 = and i1 %ok0, %ok1
  %t1 = and i1 %ok2, %ok3
  %ok = and i1 %t0, %t1
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP-DAG: Skipping VMP on unsupported_half_vec_math_no_fullfp16: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_half_vec_math_fullfp16_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_sqrt_v4bf16: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_sqrt_v16f16: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_constrained_v4f16: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_powi_v4f16_i64: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_math:
; SKIP-NOT: Skipping VMP on protected_transcendental:
; SKIP-NOT: Skipping VMP on protected_minmax:
; SKIP-NOT: Skipping VMP on protected_loop:
; SKIP-NOT: Skipping VMP on reference_math:
; SKIP-NOT: Skipping VMP on reference_transcendental:
; Constant scalable forms can fold under default<O2>.
; SKIP-O0-DAG: Skipping VMP on unsupported_sqrt_nxv4f16: unsupported call instruction

; VIRT-LABEL: define i32 @protected_math(
; VIRT: vmp.dispatch:
; VIRT-DAG: call <4 x half> @llvm.sqrt.v4f16(
; VIRT-DAG: call nnan ninf <4 x half> @llvm.sqrt.v4f16(
; VIRT-DAG: call <4 x half> @llvm.fma.v4f16(
; VIRT-DAG: call <4 x half> @llvm.fmuladd.v4f16(
; VIRT-DAG: call <4 x half> @llvm.fabs.v4f16(
; VIRT-DAG: call <4 x half> @llvm.minnum.v4f16(
; VIRT-DAG: call <4 x half> @llvm.maxnum.v4f16(
; VIRT-DAG: call <4 x half> @llvm.ceil.v4f16(
; VIRT-DAG: call <4 x half> @llvm.floor.v4f16(
; VIRT-DAG: call <4 x half> @llvm.trunc.v4f16(
; VIRT-DAG: call <4 x half> @llvm.round.v4f16(
; VIRT-DAG: call <4 x half> @llvm.rint.v4f16(
; VIRT-DAG: call <4 x half> @llvm.nearbyint.v4f16(
; VIRT-DAG: call <4 x half> @llvm.roundeven.v4f16(
; VIRT-DAG: call <4 x half> @llvm.copysign.v4f16(
; VIRT-DAG: call <4 x half> @llvm.powi.v4f16.i32(

; VIRT-LABEL: define i32 @protected_transcendental(
; VIRT: vmp.dispatch:
; VIRT-DAG: call <4 x half> @llvm.sin.v4f16(
; VIRT-DAG: call nnan ninf <4 x half> @llvm.sin.v4f16(
; VIRT-DAG: call <4 x half> @llvm.cos.v4f16(
; VIRT-DAG: call <4 x half> @llvm.exp.v4f16(
; VIRT-DAG: call <4 x half> @llvm.exp2.v4f16(
; VIRT-DAG: call <4 x half> @llvm.log.v4f16(
; VIRT-DAG: call <4 x half> @llvm.log2.v4f16(
; VIRT-DAG: call <4 x half> @llvm.log10.v4f16(
; VIRT-DAG: call <4 x half> @llvm.pow.v4f16(

; VIRT-LABEL: define i32 @protected_minmax(
; VIRT: vmp.dispatch:
; VIRT-DAG: call <4 x half> @llvm.minimum.v4f16(
; VIRT-DAG: call <4 x half> @llvm.maximum.v4f16(
; VIRT-DAG: call nnan <4 x half> @llvm.minimum.v4f16(

; VIRT-LABEL: define i32 @protected_loop(
; VIRT: vmp.dispatch:
; VIRT-DAG: call <4 x half> @llvm.sqrt.v4f16(
; VIRT-DAG: call <4 x half> @llvm.fabs.v4f16(
; VIRT-DAG: fadd <4 x half>

; VIRT: define {{.*}} @unsupported_half_vec_math_no_fullfp16({{.*}} #[[UNSUPATTR:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_half_vec_math_fullfp16_disabled({{.*}} #[[UNSUPFEAT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_sqrt_v4bf16({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_sqrt_v16f16({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_constrained_v4f16(
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_powi_v4f16_i64(
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #{{[0-9]+}} = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT: attributes #[[UNSUPFEAT]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPFEAT]] = { {{.*}}"hikari.vmp.virtualized"
