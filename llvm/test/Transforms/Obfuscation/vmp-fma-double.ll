; Scalar llvm.fma.f64 / llvm.fmuladd.f64 direct call under VMP.
; Generic fixed f32/f64 vector fma/fmuladd lives in
; vmp-fp-vector-fma-semantic.ll and is not re-covered here.
; reference/* run natively, protected/* are virtualized; bitcast-to-integer
; parity proves the interpreter re-emits the exact fma/fmuladd
; intrinsics.  fma and fmuladd are compared independently (not XOR-mixed)
; so a swap of the two cannot pass.  Runtime inputs cover ordinary finite
; values, exact cancellation, negative zero, and a quiet NaN operand.
; Assertions compare reference vs protected bit patterns only: do not pin
; NaN payload.  Negative cases (fma.v2f16, leftover fma.v8f64, constrained
; fadd.f64) SKIP with no vmp.dispatch.  O0 carries the detailed VIRT
; checks; O2 re-checks eligibility/stability.
;
; RUN: opt -S -verify-each -aesSeed=177 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.ll -o %t.o0.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=177 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP-O2 < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT-O2 < %t.o2.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.ll -o %t.o2.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare double @llvm.fma.f64(double, double, double)
declare double @llvm.fmuladd.f64(double, double, double)
declare <2 x half> @llvm.fma.v2f16(<2 x half>, <2 x half>, <2 x half>)
declare <8 x double> @llvm.fma.v8f64(<8 x double>, <8 x double>, <8 x double>)

; ---- reference: native fma.f64 / fmuladd.f64, compared as i64 bits ----

define i64 @reference_fma_double(double %a, double %b, double %c) {
entry:
  %r = call double @llvm.fma.f64(double %a, double %b, double %c)
  %i = bitcast double %r to i64
  ret i64 %i
}

define i64 @reference_fmuladd_double(double %a, double %b, double %c) {
entry:
  %r = call double @llvm.fmuladd.f64(double %a, double %b, double %c)
  %i = bitcast double %r to i64
  ret i64 %i
}

; ---- protected: same fma.f64 / fmuladd.f64 under VMP ----

define i64 @protected_fma_double(double %a, double %b, double %c) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call double @llvm.fma.f64(double %a, double %b, double %c)
  %i = bitcast double %r to i64
  ret i64 %i
}

define i64 @protected_fmuladd_double(double %a, double %b, double %c) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call double @llvm.fmuladd.f64(double %a, double %b, double %c)
  %i = bitcast double %r to i64
  ret i64 %i
}

; ---- negative cases: must SKIP, never virtualize ----

; fma.v2f16 is a listed half-vector math intrinsic.  Without last-token
; +fullfp16 it is skipped as unsupported target feature (O2 IPSCCP would
; constant-fold a constant-operand fma.f16 before VMP sees it, so keep
; the vector operand on an argument).
define double @unsupported_fma_v2f16(<2 x half> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x half> @llvm.fma.v2f16(<2 x half> %v, <2 x half> %v, <2 x half> %v)
  %e = extractelement <2 x half> %r, i32 0
  %f = fpext half %e to double
  ret double %f
}

; Leftover >128-bit vector llvm.fma.v8f64 stays rejected (unsupported
; return type).  Keep operands on arguments so O2 IPSCCP cannot
; constant-fold the intrinsic before VMP sees it.  Native call is
; preserved.  Legal-width f32/f64 vector fma is covered by
; vmp-fp-vector-fma-semantic.ll.
define <8 x double> @unsupported_fma_v8f64(<8 x double> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x double> @llvm.fma.v8f64(<8 x double> %a, <8 x double> %a, <8 x double> %a)
  ret <8 x double> %r
}

; Fast-math fmuladd.f64 is VMP-supported (CallDescriptor FMF mask restored).
define i64 @reference_fast_fmuladd_f64(double %x) {
entry:
  %r = call fast double @llvm.fmuladd.f64(double %x, double %x, double %x)
  %bits64 = bitcast double %r to i64
  ret i64 %bits64
}

define i64 @protected_fast_fmuladd_f64(double %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fast double @llvm.fmuladd.f64(double %x, double %x, double %x)
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

; ---- main: parity checks (finite, cancel, -0, qNaN); fma vs fmuladd split ----

define i32 @main() {
entry:
  ; ordinary finite: 1.5 * 2.0 + 3.0
  %e0f = call i64 @reference_fma_double(double 1.500000e+00, double 2.000000e+00, double 3.000000e+00)
  %a0f = call i64 @protected_fma_double(double 1.500000e+00, double 2.000000e+00, double 3.000000e+00)
  %e0m = call i64 @reference_fmuladd_double(double 1.500000e+00, double 2.000000e+00, double 3.000000e+00)
  %a0m = call i64 @protected_fmuladd_double(double 1.500000e+00, double 2.000000e+00, double 3.000000e+00)
  ; cancellation: 2.0 * 2.0 + (-4.0)
  %e1f = call i64 @reference_fma_double(double 2.000000e+00, double 2.000000e+00, double -4.000000e+00)
  %a1f = call i64 @protected_fma_double(double 2.000000e+00, double 2.000000e+00, double -4.000000e+00)
  %e1m = call i64 @reference_fmuladd_double(double 2.000000e+00, double 2.000000e+00, double -4.000000e+00)
  %a1m = call i64 @protected_fmuladd_double(double 2.000000e+00, double 2.000000e+00, double -4.000000e+00)
  ; negative zero multiplier: -0.0 * 1.0 + 0.0
  %e2f = call i64 @reference_fma_double(double -0.000000e+00, double 1.000000e+00, double 0.000000e+00)
  %a2f = call i64 @protected_fma_double(double -0.000000e+00, double 1.000000e+00, double 0.000000e+00)
  %e2m = call i64 @reference_fmuladd_double(double -0.000000e+00, double 1.000000e+00, double 0.000000e+00)
  %a2m = call i64 @protected_fmuladd_double(double -0.000000e+00, double 1.000000e+00, double 0.000000e+00)
  ; quiet NaN operand: compare reference vs protected bits only
  %e3f = call i64 @reference_fma_double(double 0x7FF8000000001234, double 1.000000e+00, double 2.000000e+00)
  %a3f = call i64 @protected_fma_double(double 0x7FF8000000001234, double 1.000000e+00, double 2.000000e+00)
  %e3m = call i64 @reference_fmuladd_double(double 0x7FF8000000001234, double 1.000000e+00, double 2.000000e+00)
  %a3m = call i64 @protected_fmuladd_double(double 0x7FF8000000001234, double 1.000000e+00, double 2.000000e+00)
  %m0f = icmp eq i64 %e0f, %a0f
  %m0m = icmp eq i64 %e0m, %a0m
  %m1f = icmp eq i64 %e1f, %a1f
  %m1m = icmp eq i64 %e1m, %a1m
  %m2f = icmp eq i64 %e2f, %a2f
  %m2m = icmp eq i64 %e2m, %a2m
  %m3f = icmp eq i64 %e3f, %a3f
  %m3m = icmp eq i64 %e3m, %a3m
  ; fast fmuladd: ordinary finite and negative inputs (safe finite values)
  %e4m = call i64 @reference_fast_fmuladd_f64(double 1.500000e+00)
  %a4m = call i64 @protected_fast_fmuladd_f64(double 1.500000e+00)
  %e5m = call i64 @reference_fast_fmuladd_f64(double -2.000000e+00)
  %a5m = call i64 @protected_fast_fmuladd_f64(double -2.000000e+00)
  %m4m = icmp eq i64 %e4m, %a4m
  %m5m = icmp eq i64 %e5m, %a5m
  %t0 = and i1 %m0f, %m0m
  %t1 = and i1 %m1f, %m1m
  %t2 = and i1 %m2f, %m2m
  %t3 = and i1 %m3f, %m3m
  %t4 = and i1 %t0, %t1
  %t5 = and i1 %t2, %t3
  %t6 = and i1 %t4, %t5
  %t7 = and i1 %m4m, %m5m
  %ok = and i1 %t6, %t7
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; ---- O0 checks ----

; SKIP-DAG: Skipping VMP on unsupported_fma_v2f16: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_fma_v8f64: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_constrained_fadd_f64: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_fma_double:
; SKIP-NOT: Skipping VMP on protected_fmuladd_double:
; SKIP-NOT: Skipping VMP on protected_fast_fmuladd_f64:

; VIRT-LABEL: define i64 @protected_fma_double(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: call double @llvm.fma.f64(double
; VIRT-DAG: bitcast double {{.*}} to i64

; VIRT-LABEL: define i64 @protected_fmuladd_double(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: call double @llvm.fmuladd.f64(double
; VIRT-DAG: bitcast double {{.*}} to i64

; Negative cases stay native: no dispatch, no virtualized attribute.
; VIRT-LABEL: define double @unsupported_fma_v2f16(
; VIRT-NOT: vmp.dispatch
; VIRT: call <2 x half> @llvm.fma.v2f16(
; VIRT-LABEL: define <8 x double> @unsupported_fma_v8f64(
; VIRT-NOT: vmp.dispatch
; VIRT: call <8 x double> @llvm.fma.v8f64(
; VIRT-LABEL: define i64 @protected_fast_fmuladd_f64(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT: call fast double @llvm.fmuladd.f64(double
; VIRT: bitcast double {{.*}} to i64
; VIRT-LABEL: define double @unsupported_constrained_fadd_f64(
; VIRT-NOT: vmp.dispatch
; VIRT: call fastcc double @llvm.experimental.constrained.fadd.f64(double {{.*}}, double {{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")

; VIRT: attributes{{.*}}"hikari.vmp.virtualized"{{.*}}

; ---- O2 checks ----

; SKIP-O2-DAG: Skipping VMP on unsupported_fma_v2f16: unsupported target feature
; SKIP-O2-DAG: Skipping VMP on unsupported_fma_v8f64: unsupported return type
; SKIP-O2-DAG: Skipping VMP on unsupported_constrained_fadd_f64: unsupported call instruction
; SKIP-O2-NOT: Skipping VMP on protected_fma_double:
; SKIP-O2-NOT: Skipping VMP on protected_fmuladd_double:
; SKIP-O2-NOT: Skipping VMP on protected_fast_fmuladd_f64:

; VIRT-O2-LABEL: define i64 @protected_fma_double(
; VIRT-O2: %vmp.fregs = alloca
; VIRT-O2: vmp.dispatch:
; VIRT-O2-DAG: call double @llvm.fma.f64(double

; VIRT-O2-LABEL: define i64 @protected_fmuladd_double(
; VIRT-O2: %vmp.fregs = alloca
; VIRT-O2: vmp.dispatch:
; VIRT-O2-DAG: call double @llvm.fmuladd.f64(double
; Negative cases stay native at O2 as well.
; VIRT-O2-LABEL: define double @unsupported_fma_v2f16(
; VIRT-O2-NOT: vmp.dispatch
; VIRT-O2: call <2 x half> @llvm.fma.v2f16(
; VIRT-O2-LABEL: define <8 x double> @unsupported_fma_v8f64(
; VIRT-O2-NOT: vmp.dispatch
; VIRT-O2: call <8 x double> @llvm.fma.v8f64(
; VIRT-O2-LABEL: define double @unsupported_constrained_fadd_f64(
; VIRT-O2-NOT: vmp.dispatch
; VIRT-O2: call fastcc double @llvm.experimental.constrained.fadd.f64(double {{.*}}, double {{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")
; VIRT-O2: attributes{{.*}}"hikari.vmp.virtualized"{{.*}}
