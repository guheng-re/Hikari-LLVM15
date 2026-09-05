; Scalar llvm.sqrt.f64 direct call under VMP (f32 behavior unchanged).
; reference/* run natively, protected/* are virtualized; bitcast-to-integer
; parity proves the interpreter re-emits the exact sqrt intrinsic.  Runtime
; non-perfect-square inputs (3.5, 2.0) exercise real square roots.
; Negative cases (sqrt.f16, constrained fadd.f64) SKIP with no vmp.dispatch.
; O0 carries the detailed VIRT checks; O2 re-checks eligibility/stability.
;
; RUN: opt -S -verify-each -aesSeed=109 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.ll -o %t.o0.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=109 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP-O2 < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT-O2 < %t.o2.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.ll -o %t.o2.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare double @llvm.sqrt.f64(double)
declare <2 x half> @llvm.sqrt.v2f16(<2 x half>)

; ---- reference: native sqrt.f64, result compared as i64 bits ----

define i32 @reference_sqrt_double(double %x) {
entry:
  %r = call double @llvm.sqrt.f64(double %x)
  %b = bitcast double %r to i64
  %lo = trunc i64 %b to i32
  %hi = lshr i64 %b, 32
  %hi32 = trunc i64 %hi to i32
  %mix = xor i32 %lo, %hi32
  ret i32 %mix
}

; ---- protected: same sqrt.f64 under VMP ----

define i32 @protected_sqrt_double(double %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call double @llvm.sqrt.f64(double %x)
  %b = bitcast double %r to i64
  %lo = trunc i64 %b to i32
  %hi = lshr i64 %b, 32
  %hi32 = trunc i64 %hi to i32
  %mix = xor i32 %lo, %hi32
  ret i32 %mix
}

; ---- negative cases: must SKIP, never virtualize ----

; sqrt.v2f16 rejected as a half-vector math intrinsic (half parameter; O2 IPSCCP would
; constant-fold a constant-operand sqrt.f16 before VMP sees it, so keep the
; half operand on an argument): unsupported argument type.
define double @unsupported_sqrt_v2f16(<2 x half> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x half> @llvm.sqrt.v2f16(<2 x half> %v)
  %e = extractelement <2 x half> %r, i32 0
  %f = fpext half %e to double
  ret double %f
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

; ---- main: parity checks ----

define i32 @main() {
entry:
  %e0 = call i32 @reference_sqrt_double(double 3.500000e+00)
  %a0 = call i32 @protected_sqrt_double(double 3.500000e+00)
  %e1 = call i32 @reference_sqrt_double(double 2.000000e+00)
  %a1 = call i32 @protected_sqrt_double(double 2.000000e+00)
  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %e1, %a1
  %ok = and i1 %m0, %m1
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; ---- O0 checks ----

; SKIP-DAG: Skipping VMP on unsupported_sqrt_v2f16: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_constrained_fadd_f64: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_sqrt_double:

; VIRT-LABEL: define i32 @protected_sqrt_double(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: call double @llvm.sqrt.f64(double
; VIRT-DAG: bitcast double {{.*}} to i64

; Negative cases stay native: no dispatch, no virtualized attribute.
; VIRT-LABEL: define double @unsupported_sqrt_v2f16(
; VIRT-NOT: vmp.dispatch
; VIRT: call <2 x half> @llvm.sqrt.v2f16(
; VIRT-LABEL: define double @unsupported_constrained_fadd_f64(
; VIRT-NOT: vmp.dispatch
; VIRT: call fastcc double @llvm.experimental.constrained.fadd.f64(double {{.*}}, double {{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")

; VIRT: attributes{{.*}}"hikari.vmp.virtualized"{{.*}}

; ---- O2 checks ----

; SKIP-O2-DAG: Skipping VMP on unsupported_sqrt_v2f16: unsupported call instruction
; SKIP-O2-DAG: Skipping VMP on unsupported_constrained_fadd_f64: unsupported call instruction
; SKIP-O2-NOT: Skipping VMP on protected_sqrt_double:

; VIRT-O2-LABEL: define i32 @protected_sqrt_double(
; VIRT-O2: %vmp.fregs = alloca
; VIRT-O2: vmp.dispatch:
; VIRT-O2: call double @llvm.sqrt.f64(double
; Negative cases stay native at O2 as well.
; VIRT-O2-LABEL: define double @unsupported_sqrt_v2f16(
; VIRT-O2-NOT: vmp.dispatch
; VIRT-O2: call <2 x half> @llvm.sqrt.v2f16(
; VIRT-O2-LABEL: define double @unsupported_constrained_fadd_f64(
; VIRT-O2-NOT: vmp.dispatch
; VIRT-O2: call fastcc double @llvm.experimental.constrained.fadd.f64(double {{.*}}, double {{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")
; VIRT-O2: attributes{{.*}}"hikari.vmp.virtualized"{{.*}}
