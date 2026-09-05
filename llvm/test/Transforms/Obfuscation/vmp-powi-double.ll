; Scalar llvm.powi.f64.i32 direct call under VMP (f32.i32 behavior unchanged).
; reference/* run natively, protected/* are virtualized; bitcast-to-integer
; parity proves the interpreter re-emits the exact powi intrinsic.  Runtime
; inputs cover a positive exponent, a negative exponent, a zero exponent,
; a negative base with odd and even exponents, a zero base, and a quiet NaN
; base.  Assertions compare reference vs protected bit patterns only: do not
; pin the NaN payload or a libm implementation.  Fast-math powi.f64.i32 is
; VMP-supported (CallDescriptor FMF mask restored).  Negative cases
; (powi.f16.i32 feature-gate, powi.f64.i64 dedicated skip, constrained
; fadd.f64) SKIP with no vmp.dispatch.  v2f32 powi stays on the existing
; vector surface.  O0 carries the detailed VIRT checks; O2 re-checks
; eligibility/stability.
;
; Full opt IR is FileChecked (SKIP/VIRT and SKIP-O2/VIRT-O2), including the
; i64-exponent skip probe.  Default AArch64 llc cannot select
; llvm.powi.f64.i64 (POWI libcall exponent must match sizeof(int)).  Object
; emission and host lli therefore use the live call graph from main only
; (internalize+globaldce).
;
; RUN: opt -S -verify-each -aesSeed=175 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.ll -o %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.live.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=175 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP-O2 < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT-O2 < %t.o2.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.ll -o %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.live.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare double @llvm.powi.f64.i32(double, i32)
declare half @llvm.powi.f16.i32(half, i32)
declare <2 x float> @llvm.powi.v2f32.i32(<2 x float>, i32)
declare double @llvm.powi.f64.i64(double, i64)

; ---- reference: native powi.f64.i32, result compared as i64 bits ----

define i64 @reference_powi_double(double %x, i32 %e) {
entry:
  %r = call double @llvm.powi.f64.i32(double %x, i32 %e)
  %b = bitcast double %r to i64
  ret i64 %b
}

; ---- protected: same powi.f64.i32 under VMP ----

define i64 @protected_powi_double(double %x, i32 %e) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call double @llvm.powi.f64.i32(double %x, i32 %e)
  %b = bitcast double %r to i64
  ret i64 %b
}

; ---- negative cases: must SKIP, never virtualize ----

; Well-shaped powi.f16.i32 without last-token +fullfp16 stays on the
; scalar-half feature gate (O2 IPSCCP would fold a constant operand, so
; keep the half on an argument): unsupported target feature.
define double @unsupported_powi_f16(half %h, i32 %e) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.powi.f16.i32(half %h, i32 %e)
  %f = fpext half %r to double
  ret double %f
}

; Vector llvm.powi.v2f32.i32 is the existing f32/f64 vector powi surface
; (not this scalar-math dedicated skip).  Keep operands on arguments so
; O2 IPSCCP cannot constant-fold the intrinsic before VMP sees it.
define <2 x float> @vector_powi_v2f32(<2 x float> %a, i32 %e) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.powi.v2f32.i32(<2 x float> %a, i32 %e)
  ret <2 x float> %r
}

; i64 exponent rejected by the powi whitelist (strictly i32).  Function
; argument/return types are otherwise legal, so this is an unsupported powi.
define double @unsupported_powi_i64(double %x, i64 %e) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call double @llvm.powi.f64.i64(double %x, i64 %e)
  ret double %r
}

; Fast-math powi.f64.i32 is VMP-supported (CallDescriptor FMF mask restored).
define i64 @reference_fast_powi_f64(double %x, i32 %e) {
entry:
  %r = call fast double @llvm.powi.f64.i32(double %x, i32 %e)
  %bits64 = bitcast double %r to i64
  ret i64 %bits64
}

define i64 @protected_fast_powi_f64(double %x, i32 %e) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fast double @llvm.powi.f64.i32(double %x, i32 %e)
  %bits64 = bitcast double %r to i64
  ret i64 %bits64
}

; llvm.experimental.constrained.fadd.f64 uses non-C fastcc so the now-
; supported C constrained-fadd surface stays a skip ("unsupported call
; instruction").
declare double @llvm.experimental.constrained.fadd.f64(double, double, metadata, metadata)

define double @unsupported_constrained_fadd_f64(double %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc double @llvm.experimental.constrained.fadd.f64(double %x, double %x, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret double %r
}

; ---- main: parity checks (pos/neg/zero exp, neg base odd/even, zero, qNaN) ----

define i32 @main() {
entry:
  ; positive exponent: 2.0 ^ 3
  %e0 = call i64 @reference_powi_double(double 2.000000e+00, i32 3)
  %a0 = call i64 @protected_powi_double(double 2.000000e+00, i32 3)
  ; negative exponent: 2.0 ^ -2
  %e1 = call i64 @reference_powi_double(double 2.000000e+00, i32 -2)
  %a1 = call i64 @protected_powi_double(double 2.000000e+00, i32 -2)
  ; zero exponent: 2.0 ^ 0
  %e2 = call i64 @reference_powi_double(double 2.000000e+00, i32 0)
  %a2 = call i64 @protected_powi_double(double 2.000000e+00, i32 0)
  ; negative base, odd exponent: -2.0 ^ 3
  %e3 = call i64 @reference_powi_double(double -2.000000e+00, i32 3)
  %a3 = call i64 @protected_powi_double(double -2.000000e+00, i32 3)
  ; negative base, even exponent: -2.0 ^ 2
  %e4 = call i64 @reference_powi_double(double -2.000000e+00, i32 2)
  %a4 = call i64 @protected_powi_double(double -2.000000e+00, i32 2)
  ; zero base: 0.0 ^ 3
  %e5 = call i64 @reference_powi_double(double 0.000000e+00, i32 3)
  %a5 = call i64 @protected_powi_double(double 0.000000e+00, i32 3)
  ; quiet NaN base: compare reference vs protected bits only
  %e6 = call i64 @reference_powi_double(double 0x7FF8000000001234, i32 1)
  %a6 = call i64 @protected_powi_double(double 0x7FF8000000001234, i32 1)
  ; fast powi: 4.0 ^ 2 and 2.0 ^ 3 (finite base, i32 exponents)
  %e7 = call i64 @reference_fast_powi_f64(double 4.000000e+00, i32 2)
  %a7 = call i64 @protected_fast_powi_f64(double 4.000000e+00, i32 2)
  %e8 = call i64 @reference_fast_powi_f64(double 2.000000e+00, i32 3)
  %a8 = call i64 @protected_fast_powi_f64(double 2.000000e+00, i32 3)
  %m0 = icmp eq i64 %e0, %a0
  %m1 = icmp eq i64 %e1, %a1
  %m2 = icmp eq i64 %e2, %a2
  %m3 = icmp eq i64 %e3, %a3
  %m4 = icmp eq i64 %e4, %a4
  %m5 = icmp eq i64 %e5, %a5
  %m6 = icmp eq i64 %e6, %a6
  %m7 = icmp eq i64 %e7, %a7
  %m8 = icmp eq i64 %e8, %a8
  %t0 = and i1 %m0, %m1
  %t1 = and i1 %t0, %m2
  %t2 = and i1 %t1, %m3
  %t3 = and i1 %t2, %m4
  %t4 = and i1 %t3, %m5
  %t5 = and i1 %t4, %m6
  %t6 = and i1 %t5, %m7
  %ok = and i1 %t6, %m8
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; ---- O0 checks ----

; SKIP-DAG: Skipping VMP on unsupported_powi_f16: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_powi_i64: unsupported powi
; SKIP-DAG: Skipping VMP on unsupported_constrained_fadd_f64: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_powi_double:
; SKIP-NOT: Skipping VMP on protected_fast_powi_f64:
; SKIP-NOT: Skipping VMP on vector_powi_v2f32:

; VIRT-LABEL: define i64 @protected_powi_double(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: call double @llvm.powi.f64.i32(double
; VIRT-DAG: bitcast double {{.*}} to i64

; Negative cases stay native: no dispatch, no virtualized attribute.
; VIRT-LABEL: define double @unsupported_powi_f16(
; VIRT-NOT: vmp.dispatch
; VIRT: call half @llvm.powi.f16.i32(
; VIRT-LABEL: define <2 x float> @vector_powi_v2f32(
; VIRT: vmp.dispatch:
; VIRT: call <2 x float> @llvm.powi.v2f32.i32(
; VIRT-LABEL: define double @unsupported_powi_i64(
; VIRT-NOT: vmp.dispatch
; VIRT: call double @llvm.powi.f64.i64(
; VIRT-LABEL: define i64 @protected_fast_powi_f64(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT: call fast double @llvm.powi.f64.i32(double
; VIRT: bitcast double {{.*}} to i64
; VIRT-LABEL: define double @unsupported_constrained_fadd_f64(
; VIRT-NOT: vmp.dispatch
; VIRT: call fastcc double @llvm.experimental.constrained.fadd.f64(double {{.*}}, double {{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")

; VIRT: attributes{{.*}}"hikari.vmp.virtualized"{{.*}}

; ---- O2 checks ----

; SKIP-O2-DAG: Skipping VMP on unsupported_powi_f16: unsupported target feature
; SKIP-O2-DAG: Skipping VMP on unsupported_powi_i64: unsupported powi
; SKIP-O2-DAG: Skipping VMP on unsupported_constrained_fadd_f64: unsupported call instruction
; SKIP-O2-NOT: Skipping VMP on protected_powi_double:
; SKIP-O2-NOT: Skipping VMP on protected_fast_powi_f64:
; SKIP-O2-NOT: Skipping VMP on vector_powi_v2f32:

; VIRT-O2-LABEL: define i64 @protected_powi_double(
; VIRT-O2: %vmp.fregs = alloca
; VIRT-O2: vmp.dispatch:
; VIRT-O2: call double @llvm.powi.f64.i32(double
; Negative cases stay native at O2 as well.
; VIRT-O2-LABEL: define double @unsupported_powi_f16(
; VIRT-O2-NOT: vmp.dispatch
; VIRT-O2: call half @llvm.powi.f16.i32(
; VIRT-O2-LABEL: define <2 x float> @vector_powi_v2f32(
; VIRT-O2: vmp.dispatch:
; VIRT-O2: call <2 x float> @llvm.powi.v2f32.i32(
; VIRT-O2-LABEL: define double @unsupported_powi_i64(
; VIRT-O2-NOT: vmp.dispatch
; VIRT-O2: call double @llvm.powi.f64.i64(
; VIRT-O2-LABEL: define i64 @protected_fast_powi_f64(
; VIRT-O2: %vmp.fregs = alloca
; VIRT-O2: vmp.dispatch:
; VIRT-O2: call fast double @llvm.powi.f64.i32(double
; VIRT-O2: bitcast double {{.*}} to i64
; VIRT-O2-LABEL: define double @unsupported_constrained_fadd_f64(
; VIRT-O2-NOT: vmp.dispatch
; VIRT-O2: call fastcc double @llvm.experimental.constrained.fadd.f64(double {{.*}}, double {{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")
; VIRT-O2: attributes{{.*}}"hikari.vmp.virtualized"{{.*}}
