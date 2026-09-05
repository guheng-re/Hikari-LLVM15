; Scalar llvm.cos.f64 direct call under VMP (f32 behavior unchanged).
; reference/* run natively, protected/* are virtualized; bitcast-to-integer
; parity proves the interpreter re-emits the exact cos intrinsic.  Runtime
; inputs cover +0.0, -0.0, an ordinary positive, an ordinary negative, +inf,
; and a quiet NaN.  Assertions compare reference vs protected bit patterns
; only: LangRef does not pin the NaN payload or a libm implementation.
; Negative cases (cos.f16, cos.v2f32, constrained fadd.f64) SKIP with no
; vmp.dispatch.  O0 carries the detailed VIRT checks; O2 re-checks
; eligibility/stability.
;
; RUN: opt -S -verify-each -aesSeed=123 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.ll -o %t.o0.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=123 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP-O2 < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT-O2 < %t.o2.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.ll -o %t.o2.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare double @llvm.cos.f64(double)
declare half @llvm.cos.f16(half)
declare <2 x float> @llvm.cos.v2f32(<2 x float>)

; ---- reference: native cos.f64, result compared as i64 bits ----

define i64 @reference_cos_double(double %x) {
entry:
  %r = call double @llvm.cos.f64(double %x)
  %b = bitcast double %r to i64
  ret i64 %b
}

; ---- protected: same cos.f64 under VMP ----

define i64 @protected_cos_double(double %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call double @llvm.cos.f64(double %x)
  %b = bitcast double %r to i64
  ret i64 %b
}

; ---- negative cases: must SKIP, never virtualize ----

; cos.f16 rejected by the argument-type gate (half parameter; O2 IPSCCP would
; constant-fold a constant-operand cos.f16 before VMP sees it, so keep the
; half operand on an argument): unsupported call instruction.
define double @unsupported_cos_f16(half %h) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.cos.f16(half %h)
  %f = fpext half %r to double
  ret double %f
}

; Vector llvm.cos.v2f32 rejected at the return-type gate (<2 x float>
; result/arg).  Keep operands on arguments so O2 IPSCCP cannot constant-fold
; the intrinsic before VMP sees it.  Native call is preserved.
define <2 x float> @unsupported_cos_v2f32(<2 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.cos.v2f32(<2 x float> %a)
  ret <2 x float> %r
}

; Fast-math cos.f64 is VMP-supported (CallDescriptor FMF mask restored).
define i64 @reference_fast_cos_f64(double %x) {
entry:
  %r = call fast double @llvm.cos.f64(double %x)
  %bits64 = bitcast double %r to i64
  ret i64 %bits64
}

define i64 @protected_fast_cos_f64(double %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fast double @llvm.cos.f64(double %x)
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

; ---- main: parity checks (+0, -0, ordinary +/-, +inf, quiet NaN) ----

define i32 @main() {
entry:
  ; +0.0
  %e0 = call i64 @reference_cos_double(double 0.000000e+00)
  %a0 = call i64 @protected_cos_double(double 0.000000e+00)
  ; -0.0
  %e1 = call i64 @reference_cos_double(double -0.000000e+00)
  %a1 = call i64 @protected_cos_double(double -0.000000e+00)
  ; ordinary positive
  %e2 = call i64 @reference_cos_double(double 1.500000e+00)
  %a2 = call i64 @protected_cos_double(double 1.500000e+00)
  ; ordinary negative
  %e3 = call i64 @reference_cos_double(double -1.500000e+00)
  %a3 = call i64 @protected_cos_double(double -1.500000e+00)
  ; +inf
  %e4 = call i64 @reference_cos_double(double 0x7FF0000000000000)
  %a4 = call i64 @protected_cos_double(double 0x7FF0000000000000)
  ; quiet NaN: compare reference vs protected bits only
  %e5 = call i64 @reference_cos_double(double 0x7FF8000000001234)
  %a5 = call i64 @protected_cos_double(double 0x7FF8000000001234)
  ; fast cos: 1.5 and -2.0 (finite, non-NaN, non-Inf inputs)
  %e6 = call i64 @reference_fast_cos_f64(double 1.500000e+00)
  %a6 = call i64 @protected_fast_cos_f64(double 1.500000e+00)
  %e7 = call i64 @reference_fast_cos_f64(double -2.000000e+00)
  %a7 = call i64 @protected_fast_cos_f64(double -2.000000e+00)
  %m0 = icmp eq i64 %e0, %a0
  %m1 = icmp eq i64 %e1, %a1
  %m2 = icmp eq i64 %e2, %a2
  %m3 = icmp eq i64 %e3, %a3
  %m4 = icmp eq i64 %e4, %a4
  %m5 = icmp eq i64 %e5, %a5
  %m6 = icmp eq i64 %e6, %a6
  %m7 = icmp eq i64 %e7, %a7
  %t0 = and i1 %m0, %m1
  %t1 = and i1 %t0, %m2
  %t2 = and i1 %t1, %m3
  %t3 = and i1 %t2, %m4
  %t4 = and i1 %t3, %m5
  %t5 = and i1 %t4, %m6
  %ok = and i1 %t5, %m7
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; ---- O0 checks ----

; SKIP-DAG: Skipping VMP on unsupported_cos_f16: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_cos_v2f32: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_constrained_fadd_f64: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_cos_double:
; SKIP-NOT: Skipping VMP on protected_fast_cos_f64:

; VIRT-LABEL: define i64 @protected_cos_double(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: call double @llvm.cos.f64(double
; VIRT-DAG: bitcast double {{.*}} to i64

; Negative cases stay native: no dispatch, no virtualized attribute.
; VIRT-LABEL: define double @unsupported_cos_f16(
; VIRT-NOT: vmp.dispatch
; VIRT: call half @llvm.cos.f16(
; VIRT-LABEL: define <2 x float> @unsupported_cos_v2f32(
; VIRT-NOT: vmp.dispatch
; VIRT: call <2 x float> @llvm.cos.v2f32(
; VIRT-LABEL: define i64 @protected_fast_cos_f64(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT: call fast double @llvm.cos.f64(double
; VIRT: bitcast double {{.*}} to i64
; VIRT-LABEL: define double @unsupported_constrained_fadd_f64(
; VIRT-NOT: vmp.dispatch
; VIRT: call fastcc double @llvm.experimental.constrained.fadd.f64(double {{.*}}, double {{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")

; VIRT: attributes{{.*}}"hikari.vmp.virtualized"{{.*}}

; ---- O2 checks ----

; SKIP-O2-DAG: Skipping VMP on unsupported_cos_f16: unsupported call instruction
; SKIP-O2-DAG: Skipping VMP on unsupported_cos_v2f32: unsupported call instruction
; SKIP-O2-DAG: Skipping VMP on unsupported_constrained_fadd_f64: unsupported call instruction
; SKIP-O2-NOT: Skipping VMP on protected_cos_double:
; SKIP-O2-NOT: Skipping VMP on protected_fast_cos_f64:

; VIRT-O2-LABEL: define i64 @protected_cos_double(
; VIRT-O2: %vmp.fregs = alloca
; VIRT-O2: vmp.dispatch:
; VIRT-O2: call double @llvm.cos.f64(double
; Negative cases stay native at O2 as well.
; VIRT-O2-LABEL: define double @unsupported_cos_f16(
; VIRT-O2-NOT: vmp.dispatch
; VIRT-O2: call half @llvm.cos.f16(
; VIRT-O2-LABEL: define <2 x float> @unsupported_cos_v2f32(
; VIRT-O2-NOT: vmp.dispatch
; VIRT-O2: call <2 x float> @llvm.cos.v2f32(
; VIRT-O2-LABEL: define i64 @protected_fast_cos_f64(
; VIRT-O2: %vmp.fregs = alloca
; VIRT-O2: vmp.dispatch:
; VIRT-O2: call fast double @llvm.cos.f64(double
; VIRT-O2: bitcast double {{.*}} to i64
; VIRT-O2-LABEL: define double @unsupported_constrained_fadd_f64(
; VIRT-O2-NOT: vmp.dispatch
; VIRT-O2: call fastcc double @llvm.experimental.constrained.fadd.f64(double {{.*}}, double {{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")
; VIRT-O2: attributes{{.*}}"hikari.vmp.virtualized"{{.*}}
