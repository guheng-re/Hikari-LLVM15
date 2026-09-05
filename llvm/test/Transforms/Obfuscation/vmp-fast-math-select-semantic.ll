; Scalar f32/f64 select with FastMathFlags under VMP.  The interpreter
; re-applies the exact flag combination (encoded in VMInstruction::Variant).
; f32 uses full 'fast'; f64 uses the partial combination nnan ninf.  Both
; condition values (true/false) are exercised so the select really picks an
; arm; reference/* run natively, vmp/* are virtualized; main compares
; bitcast results.  Negative cases (half and vector fast select via the
; argument gate) and a non-AArch64 module skip safely.
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

; ---- reference: native select with FMF ----

; f32 with full 'fast'.
define i32 @reference_select_f32(i1 %c, float %x, float %y) {
entry:
  %r = select fast i1 %c, float %x, float %y
  %b = bitcast float %r to i32
  ret i32 %b
}

; f64 with the partial combination nnan ninf.
define i64 @reference_select_f64(i1 %c, double %x, double %y) {
entry:
  %r = select nnan ninf i1 %c, double %x, double %y
  %b = bitcast double %r to i64
  ret i64 %b
}

; ---- vmp: same chains under VMP ----

define i32 @vmp_select_f32(i1 %c, float %x, float %y) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = select fast i1 %c, float %x, float %y
  %b = bitcast float %r to i32
  ret i32 %b
}

define i64 @vmp_select_f64(i1 %c, double %x, double %y) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = select nnan ninf i1 %c, double %x, double %y
  %b = bitcast double %r to i64
  ret i64 %b
}

; ---- negative cases: must SKIP, never virtualize ----

; half fast select rejected at the argument-type gate.
define i32 @unsupported_half_fast_select(i1 %c, half %h) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = select fast i1 %c, half %h, half %h
  ret i32 0
}

; vector fast select rejected at the argument-type gate.
define i32 @unsupported_vec_fast_select(i1 %c, <2 x float> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = select fast i1 %c, <2 x float> %v, <2 x float> %v
  ret i32 0
}

; ---- main: parity checks (both condition values) ----

define i32 @main() {
entry:
  %e0 = call i32 @reference_select_f32(i1 true, float 3.500000e+00, float 2.250000e+00)
  %a0 = call i32 @vmp_select_f32(i1 true, float 3.500000e+00, float 2.250000e+00)
  %e1 = call i32 @reference_select_f32(i1 false, float 3.500000e+00, float 2.250000e+00)
  %a1 = call i32 @vmp_select_f32(i1 false, float 3.500000e+00, float 2.250000e+00)
  %e2 = call i64 @reference_select_f64(i1 true, double 7.000000e+00, double 2.000000e+00)
  %a2 = call i64 @vmp_select_f64(i1 true, double 7.000000e+00, double 2.000000e+00)
  %e3 = call i64 @reference_select_f64(i1 false, double 7.000000e+00, double 2.000000e+00)
  %a3 = call i64 @vmp_select_f64(i1 false, double 7.000000e+00, double 2.000000e+00)
  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %e1, %a1
  %m2 = icmp eq i64 %e2, %a2
  %m3 = icmp eq i64 %e3, %a3
  %ok0 = and i1 %m0, %m1
  %ok1 = and i1 %m2, %m3
  %ok = and i1 %ok0, %ok1
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; ---- O0 checks ----

; SKIP-DAG: Skipping VMP on unsupported_half_fast_select: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_vec_fast_select: unsupported argument type
; SKIP-NOT: Skipping VMP on vmp_:

; VIRT-LABEL: define i32 @vmp_select_f32(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT: select fast i1
; VIRT-LABEL: define i64 @vmp_select_f64(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT: select nnan ninf i1

; Negative cases stay native: no dispatch, no virtualized attribute.
; VIRT-LABEL: define i32 @unsupported_half_fast_select(
; VIRT-NOT: vmp.dispatch
; VIRT: select fast i1 %c, half
; VIRT-LABEL: define i32 @unsupported_vec_fast_select(
; VIRT-NOT: vmp.dispatch
; VIRT: select fast i1 %c, <2 x float>

; VIRT: attributes{{.*}}"hikari.vmp.virtualized"

; ---- O2 checks ----

; SKIP-O2-DAG: Skipping VMP on unsupported_half_fast_select: unsupported argument type
; SKIP-O2-DAG: Skipping VMP on unsupported_vec_fast_select: unsupported argument type
; SKIP-O2-NOT: Skipping VMP on vmp_:

; VIRT-O2-LABEL: define i32 @vmp_select_f32(
; VIRT-O2: %vmp.fregs = alloca
; VIRT-O2: vmp.dispatch:
; VIRT-O2: select fast i1
; VIRT-O2: attributes{{.*}}"hikari.vmp.virtualized"

; Non-AArch64 module triple: VMP skips all selected functions wholesale.
; SKIP-X86: Skipping VMP: only AArch64 targets are supported
