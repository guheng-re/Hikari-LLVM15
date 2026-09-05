; Scalar f32/f64 fadd/fsub/fmul/fdiv/frem with FastMathFlags under VMP.
; The interpreter re-applies the exact flag combination (encoded in
; VMInstruction::Variant); reference/* run natively.  f32 uses full 'fast';
; f64 uses the partial combination nnan ninf nsz.  Runtime inputs respect the
; declared flags (no NaN/Inf/zero-division for the partial set).  Negative
; cases (vector fast fadd via argument gate, half fast fadd via the float
; binary gate) and a non-AArch64 module skip safely.
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

; ---- reference: native execution of the same FMF chains ----

; f32 with full 'fast' (all seven flags).
define i32 @reference_f32(float %x, float %y) {
entry:
  %a = fadd fast float %x, %y
  %b = fsub fast float %x, %y
  %c = fmul fast float %x, %y
  %d = fdiv fast float %x, %y
  %e = frem fast float %x, %y
  %s0 = fadd float %a, %b
  %s1 = fadd float %c, %d
  %s2 = fadd float %s0, %s1
  %s3 = fadd float %s2, %e
  %bits = bitcast float %s3 to i32
  ret i32 %bits
}

; f64 with the partial combination nnan ninf nsz.
define i64 @reference_f64(double %x, double %y) {
entry:
  %a = fadd nnan ninf nsz double %x, %y
  %b = fsub nnan ninf nsz double %x, %y
  %c = fmul nnan ninf nsz double %x, %y
  %d = fdiv nnan ninf nsz double %x, %y
  %e = frem nnan ninf nsz double %x, %y
  %s0 = fadd double %a, %b
  %s1 = fadd double %c, %d
  %s2 = fadd double %s0, %s1
  %s3 = fadd double %s2, %e
  %bits = bitcast double %s3 to i64
  ret i64 %bits
}

; ---- vmp: same chains under VMP ----

define i32 @vmp_f32(float %x, float %y) noinline optnone {
entry:
  call void @hikari_vmp()
  %a = fadd fast float %x, %y
  %b = fsub fast float %x, %y
  %c = fmul fast float %x, %y
  %d = fdiv fast float %x, %y
  %e = frem fast float %x, %y
  %s0 = fadd float %a, %b
  %s1 = fadd float %c, %d
  %s2 = fadd float %s0, %s1
  %s3 = fadd float %s2, %e
  %bits = bitcast float %s3 to i32
  ret i32 %bits
}

define i64 @vmp_f64(double %x, double %y) noinline optnone {
entry:
  call void @hikari_vmp()
  %a = fadd nnan ninf nsz double %x, %y
  %b = fsub nnan ninf nsz double %x, %y
  %c = fmul nnan ninf nsz double %x, %y
  %d = fdiv nnan ninf nsz double %x, %y
  %e = frem nnan ninf nsz double %x, %y
  %s0 = fadd double %a, %b
  %s1 = fadd double %c, %d
  %s2 = fadd double %s0, %s1
  %s3 = fadd double %s2, %e
  %bits = bitcast double %s3 to i64
  ret i64 %bits
}

; ---- negative cases: must SKIP, never virtualize ----

; Vector fast fadd rejected at the argument-type gate.
define i32 @unsupported_vec_fast_fadd(<2 x float> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = fadd fast <2 x float> %v, %v
  ret i32 0
}

; half fast fadd rejected at the argument-type gate (a constant-operand half
; fadd would be constant-folded by O2 IPSCCP before VMP sees it, so keep the
; half operand on an argument): unsupported argument type.
define i32 @unsupported_half_fast_fadd(half %h) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = fadd fast half %h, %h
  ret i32 0
}

; ---- main: parity checks ----

define i32 @main() {
entry:
  %e0 = call i32 @reference_f32(float 3.500000e+00, float 2.250000e+00)
  %a0 = call i32 @vmp_f32(float 3.500000e+00, float 2.250000e+00)
  %e1 = call i64 @reference_f64(double 7.000000e+00, double 2.000000e+00)
  %a1 = call i64 @vmp_f64(double 7.000000e+00, double 2.000000e+00)
  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i64 %e1, %a1
  %ok = and i1 %m0, %m1
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; ---- O0 checks ----

; SKIP-DAG: Skipping VMP on unsupported_vec_fast_fadd: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_half_fast_fadd: unsupported argument type
; SKIP-NOT: Skipping VMP on vmp_:

; VIRT-LABEL: define i32 @vmp_f32(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: fadd fast float
; VIRT-DAG: fsub fast float
; VIRT-DAG: fmul fast float
; VIRT-DAG: fdiv fast float
; VIRT-DAG: frem fast float
; VIRT-LABEL: define i64 @vmp_f64(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: fadd nnan ninf nsz double
; VIRT-DAG: fsub nnan ninf nsz double
; VIRT-DAG: fmul nnan ninf nsz double
; VIRT-DAG: fdiv nnan ninf nsz double
; VIRT-DAG: frem nnan ninf nsz double

; Negative cases stay native: no dispatch, no virtualized attribute.
; VIRT-LABEL: define i32 @unsupported_vec_fast_fadd(
; VIRT-NOT: vmp.dispatch
; VIRT: fadd fast <2 x float>
; VIRT-LABEL: define i32 @unsupported_half_fast_fadd(
; VIRT-NOT: vmp.dispatch
; VIRT: fadd fast half

; VIRT: attributes{{.*}}"hikari.vmp.virtualized"

; ---- O2 checks ----

; SKIP-O2-DAG: Skipping VMP on unsupported_vec_fast_fadd: unsupported argument type
; SKIP-O2-DAG: Skipping VMP on unsupported_half_fast_fadd: unsupported argument type
; SKIP-O2-NOT: Skipping VMP on vmp_:

; VIRT-O2-LABEL: define i32 @vmp_f32(
; VIRT-O2: %vmp.fregs = alloca
; VIRT-O2: vmp.dispatch:
; VIRT-O2: fadd fast float
; VIRT-O2: attributes{{.*}}"hikari.vmp.virtualized"

; Non-AArch64 module triple: VMP skips all selected functions wholesale.
; SKIP-X86: Skipping VMP: only AArch64 targets are supported
