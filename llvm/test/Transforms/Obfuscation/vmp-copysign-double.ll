; Scalar llvm.copysign.f64 direct call under VMP (f32 behavior unchanged).
; reference/* run natively, protected/* are virtualized; bitcast-to-integer
; parity proves the interpreter re-emits the exact copysign intrinsic.
; Runtime inputs cover ordinary positive, negative, negative zero as the
; sign source, and NaN-magnitude sign propagation.
; Fast-math copysign.f64 is VMP-supported (CallDescriptor FMF mask restored):
; reference_fast_copysign_double runs natively, protected_fast_copysign_double
; is virtualized; main compares their i64 bit patterns on finite non-NaN
; inputs (full 'fast' flags).
; Negative cases (copysign.f16, constrained fadd.f64) SKIP with no
; vmp.dispatch.  O0 carries the detailed VIRT checks; O2 re-checks
; eligibility/stability.
;
; RUN: opt -S -verify-each -aesSeed=111 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.ll -o %t.o0.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=111 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP-O2 < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT-O2 < %t.o2.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.ll -o %t.o2.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare double @llvm.copysign.f64(double, double)
declare <2 x half> @llvm.copysign.v2f16(<2 x half>, <2 x half>)
declare double @llvm.experimental.constrained.fadd.f64(double, double, metadata, metadata)

; ---- reference: native copysign.f64, result compared as i64 bits ----

define i64 @reference_copysign_double(double %mag, double %sgn) {
entry:
  %r = call double @llvm.copysign.f64(double %mag, double %sgn)
  %b = bitcast double %r to i64
  ret i64 %b
}

; ---- protected: same copysign.f64 under VMP ----

define i64 @protected_copysign_double(double %mag, double %sgn) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call double @llvm.copysign.f64(double %mag, double %sgn)
  %b = bitcast double %r to i64
  ret i64 %b
}

; ---- fast-math copysign.f64: VMP-supported (FMF mask restored) ----

define i64 @reference_fast_copysign_double(double %mag, double %sgn) {
entry:
  %r = call fast double @llvm.copysign.f64(double %mag, double %sgn)
  %b = bitcast double %r to i64
  ret i64 %b
}

define i64 @protected_fast_copysign_double(double %mag, double %sgn) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fast double @llvm.copysign.f64(double %mag, double %sgn)
  %b = bitcast double %r to i64
  ret i64 %b
}

; ---- negative cases: must SKIP, never virtualize ----

; copysign.v2f16 rejected as a half-vector math intrinsic (half parameter; O2 IPSCCP
; would constant-fold a constant-operand copysign.f16 before VMP sees it, so
; keep the vector operand on an argument): unsupported call instruction.
define double @unsupported_copysign_v2f16(<2 x half> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x half> @llvm.copysign.v2f16(<2 x half> %v, <2 x half> %v)
  %e = extractelement <2 x half> %r, i32 0
  %f = fpext half %e to double
  ret double %f
}

; llvm.experimental.constrained.fadd.f64 uses non-C fastcc so the now-
; supported C constrained-fadd surface stays a skip ("unsupported call
; instruction").
define double @unsupported_constrained_fadd_f64(double %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc double @llvm.experimental.constrained.fadd.f64(double %x, double %x, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret double %r
}

; ---- main: parity checks (positive, negative, -0 sign, NaN magnitude) ----

define i32 @main() {
entry:
  %e0 = call i64 @reference_copysign_double(double 1.500000e+00, double 2.000000e+00)
  %a0 = call i64 @protected_copysign_double(double 1.500000e+00, double 2.000000e+00)
  %e1 = call i64 @reference_copysign_double(double 1.500000e+00, double -2.500000e+00)
  %a1 = call i64 @protected_copysign_double(double 1.500000e+00, double -2.500000e+00)
  %e2 = call i64 @reference_copysign_double(double 1.500000e+00, double -0.000000e+00)
  %a2 = call i64 @protected_copysign_double(double 1.500000e+00, double -0.000000e+00)
  %e3 = call i64 @reference_copysign_double(double 0x7FF8000000001234, double -1.000000e+00)
  %a3 = call i64 @protected_copysign_double(double 0x7FF8000000001234, double -1.000000e+00)
  ; fast copysign: 1.5 with -2.5 sign, and -3.0 with +4.0 sign (finite inputs)
  %e4 = call i64 @reference_fast_copysign_double(double 1.500000e+00, double -2.500000e+00)
  %a4 = call i64 @protected_fast_copysign_double(double 1.500000e+00, double -2.500000e+00)
  %e5 = call i64 @reference_fast_copysign_double(double -3.000000e+00, double 4.000000e+00)
  %a5 = call i64 @protected_fast_copysign_double(double -3.000000e+00, double 4.000000e+00)
  %m0 = icmp eq i64 %e0, %a0
  %m1 = icmp eq i64 %e1, %a1
  %m2 = icmp eq i64 %e2, %a2
  %m3 = icmp eq i64 %e3, %a3
  %m4 = icmp eq i64 %e4, %a4
  %m5 = icmp eq i64 %e5, %a5
  %t0 = and i1 %m0, %m1
  %t1 = and i1 %t0, %m2
  %t2 = and i1 %t1, %m3
  %t3 = and i1 %t2, %m4
  %ok = and i1 %t3, %m5
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; ---- O0 checks ----

; SKIP-DAG: Skipping VMP on unsupported_copysign_v2f16: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_constrained_fadd_f64: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_copysign_double:
; SKIP-NOT: Skipping VMP on protected_fast_copysign_double:

; VIRT-LABEL: define i64 @protected_copysign_double(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: call double @llvm.copysign.f64(double
; VIRT-DAG: bitcast double {{.*}} to i64

; VIRT-LABEL: define i64 @protected_fast_copysign_double(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT: call fast double @llvm.copysign.f64(double
; VIRT: bitcast double {{.*}} to i64

; Negative cases stay native: no dispatch, no virtualized attribute.
; VIRT-LABEL: define double @unsupported_copysign_v2f16(
; VIRT-NOT: vmp.dispatch
; VIRT: call <2 x half> @llvm.copysign.v2f16(
; VIRT-LABEL: define double @unsupported_constrained_fadd_f64(
; VIRT-NOT: vmp.dispatch
; VIRT: call fastcc double @llvm.experimental.constrained.fadd.f64(double {{.*}}, double {{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")

; VIRT: attributes{{.*}}"hikari.vmp.virtualized"{{.*}}

; ---- O2 checks ----

; SKIP-O2-DAG: Skipping VMP on unsupported_copysign_v2f16: unsupported call instruction
; SKIP-O2-DAG: Skipping VMP on unsupported_constrained_fadd_f64: unsupported call instruction
; SKIP-O2-NOT: Skipping VMP on protected_copysign_double:
; SKIP-O2-NOT: Skipping VMP on protected_fast_copysign_double:

; VIRT-O2-LABEL: define i64 @protected_copysign_double(
; VIRT-O2: %vmp.fregs = alloca
; VIRT-O2: vmp.dispatch:
; VIRT-O2: call double @llvm.copysign.f64(double
; VIRT-O2-LABEL: define i64 @protected_fast_copysign_double(
; VIRT-O2: %vmp.fregs = alloca
; VIRT-O2: vmp.dispatch:
; VIRT-O2: call fast double @llvm.copysign.f64(double
; VIRT-O2: bitcast double {{.*}} to i64
; Negative cases stay native at O2 as well.
; VIRT-O2-LABEL: define double @unsupported_copysign_v2f16(
; VIRT-O2-NOT: vmp.dispatch
; VIRT-O2: call <2 x half> @llvm.copysign.v2f16(
; VIRT-O2-LABEL: define double @unsupported_constrained_fadd_f64(
; VIRT-O2-NOT: vmp.dispatch
; VIRT-O2: call fastcc double @llvm.experimental.constrained.fadd.f64(double {{.*}}, double {{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")
; VIRT-O2: attributes{{.*}}"hikari.vmp.virtualized"{{.*}}
