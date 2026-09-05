; Scalar half/float/double math CallDescriptor family: llvm.fma /
; llvm.fmuladd, sqrt, sin, cos, exp, exp2, log, log2, log10, powi
; (i32 exponent), pow, fabs, copysign, minnum/maxnum, minimum/maximum.
; Type surface is the existing scalar half/f32/f64 set.  Half listed
; math still needs last-token function +fullfp16.  C, exact non-vararg
; FTy, formal type equality.  Ordinary tail accepted and replayed as TCK_None.  Replay; no new
; opcode.  Do not touch fp128, bfloat, vectors, constrained math, or
; rounding/fpclass families.
;
; Host lli is reliable for the f32 mix of sqrt/fabs/fma/fmuladd/
; minnum/maxnum/copysign (existing family lits).  minimum/maximum,
; transcendentals, half, and full-'fast' sqrt are FileCheck-only
; (x86 lli cannot select fminimum).
; O0/O2 x 97/7.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.ll > %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: python3 %S/Inputs/vmp-drop-host-scalar-fp-math.py %t.o0.live.ll > %t.o0.host.src.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.host.src.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.ll > %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: python3 %S/Inputs/vmp-drop-host-scalar-fp-math.py %t.o2.live.ll > %t.o2.host.src.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.host.src.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.s7.ll > %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: python3 %S/Inputs/vmp-drop-host-scalar-fp-math.py %t.o0.s7.live.ll > %t.o0.s7.host.src.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.s7.host.src.ll > %t.o0.s7.host.ll
; RUN: lli -force-interpreter %t.o0.s7.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.s7.ll > %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: python3 %S/Inputs/vmp-drop-host-scalar-fp-math.py %t.o2.s7.live.ll > %t.o2.s7.host.src.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.s7.host.src.ll > %t.o2.s7.host.ll
; RUN: lli -force-interpreter %t.o2.s7.host.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare float @llvm.fma.f32(float, float, float)
declare float @llvm.fmuladd.f32(float, float, float)
declare float @llvm.sqrt.f32(float)
declare float @llvm.sin.f32(float)
declare float @llvm.cos.f32(float)
declare float @llvm.exp.f32(float)
declare float @llvm.exp2.f32(float)
declare float @llvm.log.f32(float)
declare float @llvm.log2.f32(float)
declare float @llvm.log10.f32(float)
declare float @llvm.powi.f32.i32(float, i32)
declare float @llvm.powi.f32.i64(float, i64)
declare float @llvm.pow.f32(float, float)
declare float @llvm.fabs.f32(float)
declare float @llvm.copysign.f32(float, float)
declare float @llvm.minnum.f32(float, float)
declare float @llvm.maxnum.f32(float, float)
declare float @llvm.minimum.f32(float, float)
declare float @llvm.maximum.f32(float, float)
declare double @llvm.sqrt.f64(double)
declare double @llvm.fabs.f64(double)
declare double @llvm.fma.f64(double, double, double)
declare half @llvm.sqrt.f16(half)
declare half @llvm.fma.f16(half, half, half)
declare half @llvm.sin.f16(half)
declare float @llvm.experimental.constrained.fadd.f32(float, float, metadata, metadata)
declare void @ext_sret_byval(ptr sret(i32), ptr byval(i32))

; ----- host-reliable f32 mix (SSA args so O2 cannot fold before VMP) -----

define i32 @reference(float %x, float %y, float %z) noinline {
entry:
  %sq = call float @llvm.sqrt.f32(float %x)
  %ab = call float @llvm.fabs.f32(float %y)
  %fm = call float @llvm.fma.f32(float %x, float %y, float %z)
  %fa = call float @llvm.fmuladd.f32(float %x, float %y, float %z)
  %mn = call float @llvm.minnum.f32(float %x, float %y)
  %mx = call float @llvm.maxnum.f32(float %x, float %y)
  %cs = call float @llvm.copysign.f32(float %x, float %y)
  %a = bitcast float %sq to i32
  %b = bitcast float %ab to i32
  %c = bitcast float %fm to i32
  %d = bitcast float %fa to i32
  %e = bitcast float %mn to i32
  %f = bitcast float %mx to i32
  %i = bitcast float %cs to i32
  %j = xor i32 %a, %b
  %k = xor i32 %c, %d
  %l = xor i32 %e, %f
  %n = xor i32 %j, %k
  %p = xor i32 %l, %n
  %r = xor i32 %p, %i
  ret i32 %r
}

define i32 @protected(float %x, float %y, float %z) noinline optnone {
entry:
  call void @hikari_vmp()
  %sq = call float @llvm.sqrt.f32(float %x)
  %ab = call float @llvm.fabs.f32(float %y)
  %fm = call float @llvm.fma.f32(float %x, float %y, float %z)
  %fa = call float @llvm.fmuladd.f32(float %x, float %y, float %z)
  %mn = call float @llvm.minnum.f32(float %x, float %y)
  %mx = call float @llvm.maxnum.f32(float %x, float %y)
  %cs = call float @llvm.copysign.f32(float %x, float %y)
  %a = bitcast float %sq to i32
  %b = bitcast float %ab to i32
  %c = bitcast float %fm to i32
  %d = bitcast float %fa to i32
  %e = bitcast float %mn to i32
  %f = bitcast float %mx to i32
  %i = bitcast float %cs to i32
  %j = xor i32 %a, %b
  %k = xor i32 %c, %d
  %l = xor i32 %e, %f
  %n = xor i32 %j, %k
  %p = xor i32 %l, %n
  %r = xor i32 %p, %i
  ret i32 %r
}

define float @protected_minmax(float %x, float %y) noinline optnone {
entry:
  call void @hikari_vmp()
  %mi = call float @llvm.minimum.f32(float %x, float %y)
  %ma = call float @llvm.maximum.f32(float %x, float %y)
  %r = fadd float %mi, %ma
  ret float %r
}

define i64 @protected_f64(double %x, double %y, double %z) noinline optnone {
entry:
  call void @hikari_vmp()
  %sq = call double @llvm.sqrt.f64(double %x)
  %ab = call double @llvm.fabs.f64(double %y)
  %fm = call double @llvm.fma.f64(double %x, double %y, double %z)
  %a = bitcast double %sq to i64
  %b = bitcast double %ab to i64
  %c = bitcast double %fm to i64
  %d = xor i64 %a, %b
  %r = xor i64 %d, %c
  ret i64 %r
}

; FileCheck-only: listed transcendentals + pow/powi.  Not in main.
define float @protected_transcendental(float %x, float %y) noinline optnone {
entry:
  call void @hikari_vmp()
  %s = call float @llvm.sin.f32(float %x)
  %c = call float @llvm.cos.f32(float %x)
  %e = call float @llvm.exp.f32(float %x)
  %e2 = call float @llvm.exp2.f32(float %x)
  %l = call float @llvm.log.f32(float %x)
  %l2 = call float @llvm.log2.f32(float %x)
  %l10 = call float @llvm.log10.f32(float %x)
  %pw = call float @llvm.pow.f32(float %x, float %y)
  %pi = call float @llvm.powi.f32.i32(float %x, i32 2)
  %a = fadd float %s, %c
  %b = fadd float %e, %e2
  %d = fadd float %l, %l2
  %f = fadd float %l10, %pw
  %g = fadd float %a, %b
  %h = fadd float %d, %f
  %i = fadd float %g, %h
  %r = fadd float %i, %pi
  ret float %r
}

define float @protected_fast_sqrt(float %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call nnan ninf float @llvm.sqrt.f32(float %x)
  ret float %r
}

define i32 @protected_half(half %x, half %y, half %z) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %sq = call half @llvm.sqrt.f16(half %x)
  %fm = call half @llvm.fma.f16(half %x, half %y, half %z)
  %sn = call half @llvm.sin.f16(half %x)
  %a = bitcast half %sq to i16
  %b = bitcast half %fm to i16
  %c = bitcast half %sn to i16
  %d = xor i16 %a, %b
  %e = xor i16 %d, %c
  %r = zext i16 %e to i32
  ret i32 %r
}

; ----- negatives -----


define float @unsupported_sqrt_malformed(float %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.sqrt.f32(float %x) noreturn
  ret float %r
}

define float @unsupported_sqrt_musttail(float %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call float @llvm.sqrt.f32(float %x)
  ret float %r
}

define float @unsupported_sqrt_bundle(float %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.sqrt.f32(float %x) [ "deopt"(i32 0) ]
  ret float %r
}

define float @unsupported_sqrt_fastcc(float %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc float @llvm.sqrt.f32(float %x)
  ret float %r
}

define float @unsupported_sqrt_poison() noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.sqrt.f32(float poison)
  ret float %r
}

define float @unsupported_sqrt_returns_twice(float %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.sqrt.f32(float %x) returns_twice
  ret float %r
}


define float @unsupported_fma_fastcc(float %x, float %y, float %z) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc float @llvm.fma.f32(float %x, float %y, float %z)
  ret float %r
}


define float @unsupported_powi_i64(float %x, i64 %e) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.powi.f32.i64(float %x, i64 %e)
  ret float %r
}


define float @unsupported_minnum_poison(float %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.minnum.f32(float %x, float poison)
  ret float %r
}

define float @unsupported_minimum_fastcc(float %x, float %y) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc float @llvm.minimum.f32(float %x, float %y)
  ret float %r
}

define half @unsupported_half_sqrt_no_fullfp16(half %h) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.sqrt.f16(half %h)
  ret half %r
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
  %r = call float @llvm.sqrt.f32(float 4.000000e+00)
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
  %e0 = call i32 @reference(float 4.000000e+00, float 9.000000e+00, float 2.000000e+00)
  %a0 = call i32 @protected(float 4.000000e+00, float 9.000000e+00, float 2.000000e+00)
  %e1 = call i32 @reference(float 1.600000e+01, float -2.000000e+00, float 1.000000e+00)
  %a1 = call i32 @protected(float 1.600000e+01, float -2.000000e+00, float 1.000000e+00)
  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %e1, %a1
  %ok = and i1 %m0, %m1
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_sqrt_malformed: unsupported sqrt
; SKIP-DAG: Skipping VMP on unsupported_sqrt_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_sqrt_bundle: unsupported sqrt
; SKIP-DAG: Skipping VMP on unsupported_sqrt_fastcc: unsupported sqrt
; SKIP-DAG: Skipping VMP on unsupported_sqrt_poison: unsupported sqrt
; SKIP-DAG: Skipping VMP on unsupported_sqrt_returns_twice: unsupported sqrt
; SKIP-DAG: Skipping VMP on unsupported_fma_fastcc: unsupported fma
; SKIP-DAG: Skipping VMP on unsupported_powi_i64: unsupported powi
; SKIP-DAG: Skipping VMP on unsupported_minnum_poison: unsupported minnum
; SKIP-DAG: Skipping VMP on unsupported_minimum_fastcc: unsupported minimum
; SKIP-DAG: Skipping VMP on unsupported_half_sqrt_no_fullfp16: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_constrained_fadd_f32: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_as1_arg: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_sret: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected:
; SKIP-NOT: Skipping VMP on protected_minmax:
; SKIP-NOT: Skipping VMP on protected_f64:
; SKIP-NOT: Skipping VMP on protected_transcendental:
; SKIP-NOT: Skipping VMP on protected_fast_sqrt:
; SKIP-NOT: Skipping VMP on protected_half:

; VIRT-LABEL: define i32 @protected(
; VIRT-SAME: #[[PROT:[0-9]+]]
; VIRT: vmp.dispatch:
; VIRT-DAG: call float @llvm.sqrt.f32(
; VIRT-DAG: call float @llvm.fabs.f32(
; VIRT-DAG: call float @llvm.fma.f32(
; VIRT-DAG: call float @llvm.fmuladd.f32(
; VIRT-DAG: call float @llvm.minnum.f32(
; VIRT-DAG: call float @llvm.maxnum.f32(
; VIRT-DAG: call float @llvm.copysign.f32(
; VIRT-LABEL: define float @protected_minmax(
; VIRT: vmp.dispatch:
; VIRT-DAG: call float @llvm.minimum.f32(
; VIRT-DAG: call float @llvm.maximum.f32(
; VIRT-LABEL: define i64 @protected_f64(
; VIRT: vmp.dispatch:
; VIRT-DAG: call double @llvm.sqrt.f64(
; VIRT-DAG: call double @llvm.fabs.f64(
; VIRT-DAG: call double @llvm.fma.f64(
; VIRT-LABEL: define float @protected_transcendental(
; VIRT: vmp.dispatch:
; VIRT-DAG: call float @llvm.sin.f32(
; VIRT-DAG: call float @llvm.cos.f32(
; VIRT-DAG: call float @llvm.exp.f32(
; VIRT-DAG: call float @llvm.exp2.f32(
; VIRT-DAG: call float @llvm.log.f32(
; VIRT-DAG: call float @llvm.log2.f32(
; VIRT-DAG: call float @llvm.log10.f32(
; VIRT-DAG: call float @llvm.pow.f32(
; VIRT-DAG: call float @llvm.powi.f32.i32(
; VIRT-LABEL: define float @protected_fast_sqrt(
; VIRT: vmp.dispatch:
; VIRT: call nnan ninf float @llvm.sqrt.f32(
; VIRT-LABEL: define i32 @protected_half(
; VIRT-SAME: #[[PROTHALF:[0-9]+]]
; VIRT: vmp.dispatch:
; VIRT-DAG: call half @llvm.sqrt.f16(
; VIRT-DAG: call half @llvm.fma.f16(
; VIRT-DAG: call half @llvm.sin.f16(
; VIRT: define {{.*}} @unsupported_sqrt_malformed({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_sqrt_musttail(
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call float @llvm.sqrt.f32(
; VIRT-LABEL: define {{.*}} @unsupported_sqrt_bundle(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_sqrt_fastcc(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_sqrt_poison(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_sqrt_returns_twice(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_fma_fastcc(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_powi_i64(
; VIRT-NOT: vmp.dispatch
; VIRT: call float @llvm.powi.f32.i64(
; VIRT-LABEL: define {{.*}} @unsupported_minnum_poison(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_minimum_fastcc(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_half_sqrt_no_fullfp16(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_constrained_fadd_f32(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_as1_arg(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_sret(
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[PROTHALF]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.selected"
; VIRT-NOT: attributes #[[PROTHALF]] = { {{.*}}"hikari.vmp.selected"

; AARCH64: Arch: aarch64
