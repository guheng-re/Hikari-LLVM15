; Coherent eligibility hardening for fixed f32/f64 vector listed
; math: fma/fmuladd, sqrt/fabs, minnum/maxnum, ceil/floor/trunc/round,
; copysign/pow/powi.i32, sin, fptosi.sat, canonicalize, is.fpclass.
; C, exact non-vararg FTy, formal type equality.  fpclass mask is a
; true i32 ImmArg.  powi exponent is an ordinary i32 (SSA allowed).
; Ordinary tail accepted and replayed as TCK_None.  Replay / VectorFMul canonicalize lowering;
; no new opcode.  Caps stay 1..128.  Do not touch half/bfloat/fp128/
; reduce/constrained.
;
; Host lli is reliable for the v2f32 mix of fma/sqrt/fabs/minnum.
; The rest is FileCheck-only (x86 JIT cannot select some IDs).
; O0/O2 x 97/7.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.ll > %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: python3 %S/Inputs/vmp-drop-host-fp-vector-math.py %t.o0.live.ll > %t.o0.host.src.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.host.src.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.ll > %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: python3 %S/Inputs/vmp-drop-host-fp-vector-math.py %t.o2.live.ll > %t.o2.host.src.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.host.src.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.s7.ll > %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: python3 %S/Inputs/vmp-drop-host-fp-vector-math.py %t.o0.s7.live.ll > %t.o0.s7.host.src.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.s7.host.src.ll > %t.o0.s7.host.ll
; RUN: lli -force-interpreter %t.o0.s7.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.s7.ll > %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: python3 %S/Inputs/vmp-drop-host-fp-vector-math.py %t.o2.s7.live.ll > %t.o2.s7.host.src.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.s7.host.src.ll > %t.o2.s7.host.ll
; RUN: lli -force-interpreter %t.o2.s7.host.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare <2 x float> @llvm.fma.v2f32(<2 x float>, <2 x float>, <2 x float>)
declare <2 x float> @llvm.fmuladd.v2f32(<2 x float>, <2 x float>, <2 x float>)
declare <2 x float> @llvm.sqrt.v2f32(<2 x float>)
declare <2 x float> @llvm.fabs.v2f32(<2 x float>)
declare <2 x float> @llvm.minnum.v2f32(<2 x float>, <2 x float>)
declare <2 x float> @llvm.maxnum.v2f32(<2 x float>, <2 x float>)
declare <2 x float> @llvm.minimum.v2f32(<2 x float>, <2 x float>)
declare <2 x float> @llvm.maximum.v2f32(<2 x float>, <2 x float>)
declare <2 x float> @llvm.ceil.v2f32(<2 x float>)
declare <2 x float> @llvm.floor.v2f32(<2 x float>)
declare <2 x float> @llvm.trunc.v2f32(<2 x float>)
declare <2 x float> @llvm.round.v2f32(<2 x float>)
declare <2 x float> @llvm.rint.v2f32(<2 x float>)
declare <2 x float> @llvm.nearbyint.v2f32(<2 x float>)
declare <2 x float> @llvm.roundeven.v2f32(<2 x float>)
declare <2 x float> @llvm.copysign.v2f32(<2 x float>, <2 x float>)
declare <2 x float> @llvm.pow.v2f32(<2 x float>, <2 x float>)
declare <2 x float> @llvm.powi.v2f32.i32(<2 x float>, i32)
declare <2 x float> @llvm.powi.v2f32.i64(<2 x float>, i64)
declare <2 x float> @llvm.sin.v2f32(<2 x float>)
declare <2 x float> @llvm.cos.v2f32(<2 x float>)
declare <2 x float> @llvm.exp.v2f32(<2 x float>)
declare <2 x float> @llvm.exp2.v2f32(<2 x float>)
declare <2 x float> @llvm.log.v2f32(<2 x float>)
declare <2 x float> @llvm.log2.v2f32(<2 x float>)
declare <2 x float> @llvm.log10.v2f32(<2 x float>)
declare <2 x float> @llvm.canonicalize.v2f32(<2 x float>)
declare <2 x i1> @llvm.is.fpclass.v2f32(<2 x float>, i32)
declare <2 x i32> @llvm.fptosi.sat.v2i32.v2f32(<2 x float>)
declare <2 x i32> @llvm.fptoui.sat.v2i32.v2f32(<2 x float>)
declare <2 x double> @llvm.sqrt.v2f64(<2 x double>)
declare <4 x half> @llvm.sqrt.v4f16(<4 x half>)
declare float @llvm.experimental.constrained.fadd.f32(float, float, metadata, metadata)
declare void @ext_sret_byval(ptr sret(i32), ptr byval(i32))

define i32 @vec_mix(<2 x i32> %v) {
entry:
  %e0 = extractelement <2 x i32> %v, i32 0
  %e1 = extractelement <2 x i32> %v, i32 1
  %r = xor i32 %e0, %e1
  ret i32 %r
}

define i32 @reference(<2 x float> %x, <2 x float> %y, <2 x float> %z) noinline {
entry:
  %fm = call <2 x float> @llvm.fma.v2f32(<2 x float> %x, <2 x float> %y, <2 x float> %z)
  %sq = call <2 x float> @llvm.sqrt.v2f32(<2 x float> %x)
  %ab = call <2 x float> @llvm.fabs.v2f32(<2 x float> %y)
  %mn = call <2 x float> @llvm.minnum.v2f32(<2 x float> %x, <2 x float> %y)
  %a = bitcast <2 x float> %fm to <2 x i32>
  %b = bitcast <2 x float> %sq to <2 x i32>
  %c = bitcast <2 x float> %ab to <2 x i32>
  %d = bitcast <2 x float> %mn to <2 x i32>
  %e = xor <2 x i32> %a, %b
  %f = xor <2 x i32> %c, %d
  %g = xor <2 x i32> %e, %f
  %r = call i32 @vec_mix(<2 x i32> %g)
  ret i32 %r
}

define i32 @protected(<2 x float> %x, <2 x float> %y, <2 x float> %z) noinline optnone {
entry:
  call void @hikari_vmp()
  %fm = call <2 x float> @llvm.fma.v2f32(<2 x float> %x, <2 x float> %y, <2 x float> %z)
  %sq = call <2 x float> @llvm.sqrt.v2f32(<2 x float> %x)
  %ab = call <2 x float> @llvm.fabs.v2f32(<2 x float> %y)
  %mn = call <2 x float> @llvm.minnum.v2f32(<2 x float> %x, <2 x float> %y)
  %a = bitcast <2 x float> %fm to <2 x i32>
  %b = bitcast <2 x float> %sq to <2 x i32>
  %c = bitcast <2 x float> %ab to <2 x i32>
  %d = bitcast <2 x float> %mn to <2 x i32>
  %e = xor <2 x i32> %a, %b
  %f = xor <2 x i32> %c, %d
  %g = xor <2 x i32> %e, %f
  %r = call i32 @vec_mix(<2 x i32> %g)
  ret i32 %r
}

define <2 x float> @protected_more(<2 x float> %x, <2 x float> %y) noinline optnone {
entry:
  call void @hikari_vmp()
  %fa = call <2 x float> @llvm.fmuladd.v2f32(<2 x float> %x, <2 x float> %y, <2 x float> %x)
  %mx = call <2 x float> @llvm.maxnum.v2f32(<2 x float> %x, <2 x float> %y)
  %c = call <2 x float> @llvm.ceil.v2f32(<2 x float> %x)
  %f = call <2 x float> @llvm.floor.v2f32(<2 x float> %x)
  %t = call <2 x float> @llvm.trunc.v2f32(<2 x float> %x)
  %r = call <2 x float> @llvm.round.v2f32(<2 x float> %x)
  %cs = call <2 x float> @llvm.copysign.v2f32(<2 x float> %x, <2 x float> %y)
  %a = fadd <2 x float> %fa, %mx
  %b = fadd <2 x float> %c, %f
  %d = fadd <2 x float> %t, %r
  %e = fadd <2 x float> %a, %b
  %g = fadd <2 x float> %d, %cs
  %o = fadd <2 x float> %e, %g
  ret <2 x float> %o
}

define <2 x float> @protected_round_rest(<2 x float> %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %ri = call <2 x float> @llvm.rint.v2f32(<2 x float> %x)
  %n = call <2 x float> @llvm.nearbyint.v2f32(<2 x float> %x)
  %e = call <2 x float> @llvm.roundeven.v2f32(<2 x float> %x)
  %a = fadd <2 x float> %ri, %n
  %r = fadd <2 x float> %a, %e
  ret <2 x float> %r
}

define <2 x float> @protected_transcendental(<2 x float> %x, <2 x float> %y) noinline optnone {
entry:
  call void @hikari_vmp()
  %s = call <2 x float> @llvm.sin.v2f32(<2 x float> %x)
  %c = call <2 x float> @llvm.cos.v2f32(<2 x float> %x)
  %e = call <2 x float> @llvm.exp.v2f32(<2 x float> %x)
  %e2 = call <2 x float> @llvm.exp2.v2f32(<2 x float> %x)
  %l = call <2 x float> @llvm.log.v2f32(<2 x float> %x)
  %l2 = call <2 x float> @llvm.log2.v2f32(<2 x float> %x)
  %l10 = call <2 x float> @llvm.log10.v2f32(<2 x float> %x)
  %pw = call <2 x float> @llvm.pow.v2f32(<2 x float> %x, <2 x float> %y)
  %pi = call <2 x float> @llvm.powi.v2f32.i32(<2 x float> %x, i32 2)
  %a = fadd <2 x float> %s, %c
  %b = fadd <2 x float> %e, %e2
  %d = fadd <2 x float> %l, %l2
  %f = fadd <2 x float> %l10, %pw
  %g = fadd <2 x float> %a, %b
  %h = fadd <2 x float> %d, %f
  %i = fadd <2 x float> %g, %h
  %r = fadd <2 x float> %i, %pi
  ret <2 x float> %r
}

define <2 x float> @protected_minmax_ieee(<2 x float> %x, <2 x float> %y) noinline optnone {
entry:
  call void @hikari_vmp()
  %mi = call <2 x float> @llvm.minimum.v2f32(<2 x float> %x, <2 x float> %y)
  %ma = call <2 x float> @llvm.maximum.v2f32(<2 x float> %x, <2 x float> %y)
  %r = fadd <2 x float> %mi, %ma
  ret <2 x float> %r
}

define <2 x float> @protected_canonicalize(<2 x float> %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.canonicalize.v2f32(<2 x float> %x)
  ret <2 x float> %r
}

define <2 x i1> @protected_fpclass(<2 x float> %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i1> @llvm.is.fpclass.v2f32(<2 x float> %x, i32 2016)
  ret <2 x i1> %r
}

define <2 x i32> @protected_sat(<2 x float> %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %s = call <2 x i32> @llvm.fptosi.sat.v2i32.v2f32(<2 x float> %x)
  %u = call <2 x i32> @llvm.fptoui.sat.v2i32.v2f32(<2 x float> %x)
  %r = xor <2 x i32> %s, %u
  ret <2 x i32> %r
}

define <2 x double> @protected_f64(<2 x double> %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x double> @llvm.sqrt.v2f64(<2 x double> %x)
  ret <2 x double> %r
}

define <2 x float> @protected_fast_sqrt(<2 x float> %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call nnan ninf <2 x float> @llvm.sqrt.v2f32(<2 x float> %x)
  ret <2 x float> %r
}


define <2 x float> @unsupported_fma_fastcc(<2 x float> %x, <2 x float> %y, <2 x float> %z) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc <2 x float> @llvm.fma.v2f32(<2 x float> %x, <2 x float> %y, <2 x float> %z)
  ret <2 x float> %r
}

define <2 x float> @unsupported_fma_musttail(<2 x float> %x, <2 x float> %y, <2 x float> %z) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call <2 x float> @llvm.fma.v2f32(<2 x float> %x, <2 x float> %y, <2 x float> %z)
  ret <2 x float> %r
}

define <2 x float> @unsupported_fma_bundle(<2 x float> %x, <2 x float> %y, <2 x float> %z) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.fma.v2f32(<2 x float> %x, <2 x float> %y, <2 x float> %z) [ "deopt"(i32 0) ]
  ret <2 x float> %r
}

define <2 x float> @unsupported_sqrt_poison() noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.sqrt.v2f32(<2 x float> poison)
  ret <2 x float> %r
}

define <2 x float> @unsupported_sqrt_noreturn(<2 x float> %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.sqrt.v2f32(<2 x float> %x) noreturn
  ret <2 x float> %r
}

define <2 x float> @unsupported_powi_i64(<2 x float> %x, i64 %e) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.powi.v2f32.i64(<2 x float> %x, i64 %e)
  ret <2 x float> %r
}


define <2 x i1> @unsupported_fpclass_fastcc(<2 x float> %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc <2 x i1> @llvm.is.fpclass.v2f32(<2 x float> %x, i32 2016)
  ret <2 x i1> %r
}



define <4 x half> @unsupported_half_sqrt(<4 x half> %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x half> @llvm.sqrt.v4f16(<4 x half> %x)
  ret <4 x half> %r
}

define float @unsupported_constrained_fadd_f32(float %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc float @llvm.experimental.constrained.fadd.f32(float %x, float %x, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret float %r
}

define void @unsupported_as1_arg(ptr addrspace(1) %unused) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.sqrt.v2f32(<2 x float> <float 4.000000e+00, float 9.000000e+00>)
  ret void
}

define void @unsupported_sret(ptr sret(i32) %p, ptr byval(i32) %q) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @ext_sret_byval(ptr sret(i32) %p, ptr byval(i32) %q)
  ret void
}

define i32 @main() {
entry:
  %x = fadd <2 x float> <float 4.000000e+00, float 9.000000e+00>, zeroinitializer
  %y = fadd <2 x float> <float 1.000000e+00, float 2.000000e+00>, zeroinitializer
  %z = fadd <2 x float> <float -1.000000e+00, float 0.500000e+00>, zeroinitializer
  %e0 = call i32 @reference(<2 x float> %x, <2 x float> %y, <2 x float> %z)
  %a0 = call i32 @protected(<2 x float> %x, <2 x float> %y, <2 x float> %z)
  %x1 = fadd <2 x float> <float 1.600000e+01, float 2.500000e+01>, zeroinitializer
  %e1 = call i32 @reference(<2 x float> %x1, <2 x float> %y, <2 x float> %z)
  %a1 = call i32 @protected(<2 x float> %x1, <2 x float> %y, <2 x float> %z)
  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %e1, %a1
  %ok = and i1 %m0, %m1
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_fma_fastcc: unsupported fma
; SKIP-DAG: Skipping VMP on unsupported_fma_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_fma_bundle: unsupported fma
; SKIP-DAG: Skipping VMP on unsupported_sqrt_poison: unsupported sqrt
; SKIP-DAG: Skipping VMP on unsupported_sqrt_noreturn: unsupported sqrt
; SKIP-DAG: Skipping VMP on unsupported_powi_i64: unsupported powi
; SKIP-DAG: Skipping VMP on unsupported_fpclass_fastcc: unsupported is.fpclass
; SKIP-DAG: Skipping VMP on unsupported_half_sqrt: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_constrained_fadd_f32: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_as1_arg: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_sret: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected:
; SKIP-NOT: Skipping VMP on protected_more:
; SKIP-NOT: Skipping VMP on protected_round_rest:
; SKIP-NOT: Skipping VMP on protected_transcendental:
; SKIP-NOT: Skipping VMP on protected_minmax_ieee:
; SKIP-NOT: Skipping VMP on protected_canonicalize:
; SKIP-NOT: Skipping VMP on protected_fpclass:
; SKIP-NOT: Skipping VMP on protected_sat:
; SKIP-NOT: Skipping VMP on protected_f64:
; SKIP-NOT: Skipping VMP on protected_fast_sqrt:

; VIRT-LABEL: define i32 @protected(
; VIRT-SAME: #[[PROT:[0-9]+]]
; VIRT: vmp.dispatch:
; VIRT-DAG: call <2 x float> @llvm.fma.v2f32(
; VIRT-DAG: call <2 x float> @llvm.sqrt.v2f32(
; VIRT-DAG: call <2 x float> @llvm.fabs.v2f32(
; VIRT-DAG: call <2 x float> @llvm.minnum.v2f32(
; VIRT-LABEL: define <2 x float> @protected_more(
; VIRT: vmp.dispatch:
; VIRT-DAG: call <2 x float> @llvm.fmuladd.v2f32(
; VIRT-DAG: call <2 x float> @llvm.maxnum.v2f32(
; VIRT-DAG: call <2 x float> @llvm.ceil.v2f32(
; VIRT-DAG: call <2 x float> @llvm.floor.v2f32(
; VIRT-DAG: call <2 x float> @llvm.trunc.v2f32(
; VIRT-DAG: call <2 x float> @llvm.round.v2f32(
; VIRT-DAG: call <2 x float> @llvm.copysign.v2f32(
; VIRT-LABEL: define <2 x float> @protected_round_rest(
; VIRT: vmp.dispatch:
; VIRT-DAG: call <2 x float> @llvm.rint.v2f32(
; VIRT-DAG: call <2 x float> @llvm.nearbyint.v2f32(
; VIRT-DAG: call <2 x float> @llvm.roundeven.v2f32(
; VIRT-LABEL: define <2 x float> @protected_transcendental(
; VIRT: vmp.dispatch:
; VIRT-DAG: call <2 x float> @llvm.sin.v2f32(
; VIRT-DAG: call <2 x float> @llvm.cos.v2f32(
; VIRT-DAG: call <2 x float> @llvm.exp.v2f32(
; VIRT-DAG: call <2 x float> @llvm.exp2.v2f32(
; VIRT-DAG: call <2 x float> @llvm.log.v2f32(
; VIRT-DAG: call <2 x float> @llvm.log2.v2f32(
; VIRT-DAG: call <2 x float> @llvm.log10.v2f32(
; VIRT-DAG: call <2 x float> @llvm.pow.v2f32(
; VIRT-DAG: call <2 x float> @llvm.powi.v2f32.i32(
; VIRT-LABEL: define <2 x float> @protected_minmax_ieee(
; VIRT: vmp.dispatch:
; VIRT-DAG: call <2 x float> @llvm.minimum.v2f32(
; VIRT-DAG: call <2 x float> @llvm.maximum.v2f32(
; VIRT-LABEL: define <2 x float> @protected_canonicalize(
; VIRT: vmp.dispatch:
; VIRT: fmul
; VIRT-LABEL: define <2 x i1> @protected_fpclass(
; VIRT: vmp.dispatch:
; VIRT: call <2 x i1> @llvm.is.fpclass.v2f32({{.*}}, i32 2016)
; VIRT-LABEL: define <2 x i32> @protected_sat(
; VIRT: vmp.dispatch:
; VIRT-DAG: call <2 x i32> @llvm.fptosi.sat.v2i32.v2f32(
; VIRT-DAG: call <2 x i32> @llvm.fptoui.sat.v2i32.v2f32(
; VIRT-LABEL: define <2 x double> @protected_f64(
; VIRT: vmp.dispatch:
; VIRT: call <2 x double> @llvm.sqrt.v2f64(
; VIRT-LABEL: define <2 x float> @protected_fast_sqrt(
; VIRT: vmp.dispatch:
; VIRT: call nnan ninf <2 x float> @llvm.sqrt.v2f32(
; VIRT: define {{.*}} @unsupported_fma_fastcc({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_fma_musttail(
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call <2 x float> @llvm.fma.v2f32(
; VIRT-LABEL: define {{.*}} @unsupported_fma_bundle(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_sqrt_poison(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_sqrt_noreturn(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_powi_i64(
; VIRT-NOT: vmp.dispatch
; VIRT: call <2 x float> @llvm.powi.v2f32.i64(
; VIRT-LABEL: define {{.*}} @unsupported_fpclass_fastcc(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_half_sqrt(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_constrained_fadd_f32(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_as1_arg(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_sret(
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.selected"

; AARCH64: Arch: aarch64
