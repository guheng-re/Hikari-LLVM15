; Scalar f32/f64 fcmp with FastMathFlags under VMP.  The interpreter unpacks
; predicate (low 4 bits) and FMF (seven bits above) from the packed Variant
; and re-applies the exact flags.  f32 uses full 'fast'; f64 uses the partial
; combination nnan ninf; each covers oeq/olt/une.  reference/* run natively,
; vmp/* are virtualized; main compares zext i1 results (inputs 3.5/2.25 and
; 7.0/2.0 never produce NaN/Inf, so the declared flags are never violated).
; Negative cases (half and vector fast fcmp via the argument gate) and a
; non-AArch64 module skip safely.
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
; RUN: opt -S -verify-each -aesSeed=109 -mtriple=x86_64-unknown-linux-gnu -passes='default<O0>' %s -o %t.x86.ll 2>%t.x86.err
; RUN: FileCheck %s --check-prefix=SKIP-X86 < %t.x86.err

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()

; ---- reference: native fcmp with FMF ----

; f32 with full 'fast', three predicates.
define i32 @reference_fcmp_f32(float %x, float %y) {
entry:
  %c0 = fcmp fast oeq float %x, %y
  %c1 = fcmp fast olt float %x, %y
  %c2 = fcmp fast une float %x, %y
  %z0 = zext i1 %c0 to i32
  %z1 = zext i1 %c1 to i32
  %z2 = zext i1 %c2 to i32
  %t0 = add i32 %z0, %z1
  %result = add i32 %t0, %z2
  ret i32 %result
}

; f64 with the partial combination nnan ninf, three predicates.
define i64 @reference_fcmp_f64(double %x, double %y) {
entry:
  %c0 = fcmp nnan ninf oeq double %x, %y
  %c1 = fcmp nnan ninf olt double %x, %y
  %c2 = fcmp nnan ninf une double %x, %y
  %z0 = zext i1 %c0 to i64
  %z1 = zext i1 %c1 to i64
  %z2 = zext i1 %c2 to i64
  %t0 = add i64 %z0, %z1
  %result = add i64 %t0, %z2
  ret i64 %result
}

; ---- vmp: same chains under VMP ----

define i32 @vmp_fcmp_f32(float %x, float %y) noinline optnone {
entry:
  call void @hikari_vmp()
  %c0 = fcmp fast oeq float %x, %y
  %c1 = fcmp fast olt float %x, %y
  %c2 = fcmp fast une float %x, %y
  %z0 = zext i1 %c0 to i32
  %z1 = zext i1 %c1 to i32
  %z2 = zext i1 %c2 to i32
  %t0 = add i32 %z0, %z1
  %result = add i32 %t0, %z2
  ret i32 %result
}

define i64 @vmp_fcmp_f64(double %x, double %y) noinline optnone {
entry:
  call void @hikari_vmp()
  %c0 = fcmp nnan ninf oeq double %x, %y
  %c1 = fcmp nnan ninf olt double %x, %y
  %c2 = fcmp nnan ninf une double %x, %y
  %z0 = zext i1 %c0 to i64
  %z1 = zext i1 %c1 to i64
  %z2 = zext i1 %c2 to i64
  %t0 = add i64 %z0, %z1
  %result = add i64 %t0, %z2
  ret i64 %result
}

; ---- negative cases: must SKIP, never virtualize ----

; half fast fcmp rejected at the argument-type gate.
define i32 @unsupported_half_fast_fcmp(half %h) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = fcmp fast oeq half %h, %h
  ret i32 0
}

; vector fast fcmp rejected at the argument-type gate.
define i32 @unsupported_vec_fast_fcmp(<2 x float> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = fcmp fast oeq <2 x float> %v, %v
  ret i32 0
}

; ---- main: parity checks ----

define i32 @main() {
entry:
  %e0 = call i32 @reference_fcmp_f32(float 3.500000e+00, float 2.250000e+00)
  %a0 = call i32 @vmp_fcmp_f32(float 3.500000e+00, float 2.250000e+00)
  %e1 = call i64 @reference_fcmp_f64(double 7.000000e+00, double 2.000000e+00)
  %a1 = call i64 @vmp_fcmp_f64(double 7.000000e+00, double 2.000000e+00)
  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i64 %e1, %a1
  %ok = and i1 %m0, %m1
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; ---- O0 checks ----

; SKIP-DAG: Skipping VMP on unsupported_half_fast_fcmp: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_vec_fast_fcmp: unsupported argument type
; SKIP-NOT: Skipping VMP on vmp_:

; VIRT-LABEL: define i32 @vmp_fcmp_f32(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: fcmp fast oeq float
; VIRT-DAG: fcmp fast olt float
; VIRT-DAG: fcmp fast une float
; VIRT-LABEL: define i64 @vmp_fcmp_f64(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: fcmp nnan ninf oeq double
; VIRT-DAG: fcmp nnan ninf olt double
; VIRT-DAG: fcmp nnan ninf une double

; Negative cases stay native: no dispatch, no virtualized attribute.
; VIRT-LABEL: define i32 @unsupported_half_fast_fcmp(
; VIRT-NOT: vmp.dispatch
; VIRT: fcmp fast oeq half
; VIRT-LABEL: define i32 @unsupported_vec_fast_fcmp(
; VIRT-NOT: vmp.dispatch
; VIRT: fcmp fast oeq <2 x float>

; VIRT: attributes{{.*}}"hikari.vmp.virtualized"

; ---- O2 checks ----

; SKIP-O2-DAG: Skipping VMP on unsupported_half_fast_fcmp: unsupported argument type
; SKIP-O2-DAG: Skipping VMP on unsupported_vec_fast_fcmp: unsupported argument type
; SKIP-O2-NOT: Skipping VMP on vmp_:

; VIRT-O2-LABEL: define i32 @vmp_fcmp_f32(
; VIRT-O2: %vmp.fregs = alloca
; VIRT-O2: vmp.dispatch:
; VIRT-O2: fcmp fast oeq float
; VIRT-O2: attributes{{.*}}"hikari.vmp.virtualized"

; Non-AArch64 module triple: VMP skips all selected functions wholesale.
; SKIP-X86: Skipping VMP: only AArch64 targets are supported
