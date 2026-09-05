; Non-fast and fast llvm.canonicalize.f64 are VMP-eligible and planned as
; FMul(x, 1.0) (LangRef-compatible expansion when not constant-folded);
; fast canonicalize carries its exact FMF onto the lowered fmul.  f32
; canonicalize behavior is unchanged.  The constrained-fadd sentinel is
; rejected by the intrinsic whitelist; half and >128-bit vector
; canonicalize stay rejected (see negatives).  In-range f32/f64
; vector canonicalize is a separate surface.
;
; Full opt IR is FileChecked (SKIP/VIRT and SKIP-O2/VIRT-O2), including dead
; skip probes that still contain llvm.canonicalize (f16/v8f64 — not
; selectable by AArch64/X86).  Object emission and host lli therefore use the
; live call graph from main only (internalize+globaldce), which has no residual
; canonicalize after VMP lowering — not an SSA-identity rewrite of FMul.
;
; reference uses the same FMul expansion VMP applies; protected uses
; non-fast llvm.canonicalize.f64.  Results are compared as i64 bits
; (finite, +0, -0, +inf, quiet NaN).  Compare reference vs protected only;
; do not pin a NaN payload.
;
; RUN: opt -S -verify-each -aesSeed=121 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.ll -o %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.live.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=121 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP-O2 < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT-O2 < %t.o2.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.ll -o %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.live.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare double @llvm.canonicalize.f64(double)
declare double @llvm.experimental.constrained.fadd.f64(double, double, metadata, metadata)
declare <2 x half> @llvm.canonicalize.v2f16(<2 x half>)
declare <8 x double> @llvm.canonicalize.v8f64(<8 x double>)

; Reference uses the same LangRef expansion VMP applies (fmul by 1.0).
define i64 @reference_canonicalize_double(double %x) {
entry:
  %r = fmul double %x, 1.000000e+00
  %b = bitcast double %r to i64
  ret i64 %b
}

define i64 @protected_canonicalize_double(double %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call double @llvm.canonicalize.f64(double %x)
  %b = bitcast double %r to i64
  ret i64 %b
}

; Fast-math canonicalize.f64 is VMP-supported: the planner lowers it to
; FMul(x, 1.0) carrying the exact flags in the opcode Variant.
define i64 @reference_fast_canonicalize_double(double %x) {
entry:
  %r = fmul nnan ninf double %x, 1.000000e+00
  %b = bitcast double %r to i64
  ret i64 %b
}

define i64 @protected_fast_canonicalize_double(double %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call nnan ninf double @llvm.canonicalize.f64(double %x)
  %b = bitcast double %r to i64
  ret i64 %b
}

; ---- negative cases: must SKIP, never virtualize ----

; canonicalize.v2f16 rejected as a half-vector math intrinsic (half parameter; O2
; IPSCCP would constant-fold a constant-operand canonicalize.f16 before VMP
; sees it, so keep the vector operand on an argument): unsupported call instruction.
define double @unsupported_canonicalize_v2f16(<2 x half> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x half> @llvm.canonicalize.v2f16(<2 x half> %v)
  %e = extractelement <2 x half> %r, i32 0
  %f = fpext half %e to double
  ret double %f
}

; Wide llvm.canonicalize.v8f64 stays outside the 1..128 f32/f64 vector
; canonicalize surface.  Keep operands on arguments so O2 IPSCCP cannot
; constant-fold the intrinsic before VMP sees it.  Native call is preserved.
define <8 x double> @unsupported_canonicalize_v8f64(<8 x double> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x double> @llvm.canonicalize.v8f64(<8 x double> %a)
  ret <8 x double> %r
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

; ---- main: parity checks (finite, zeros, +inf, qNaN) ----

define i32 @main() {
entry:
  ; finite +1.5: compare reference vs protected bits only
  %e0 = call i64 @reference_canonicalize_double(double 1.500000e+00)
  %a0 = call i64 @protected_canonicalize_double(double 1.500000e+00)
  ; +0.0
  %e1 = call i64 @reference_canonicalize_double(double 0.000000e+00)
  %a1 = call i64 @protected_canonicalize_double(double 0.000000e+00)
  ; -0.0
  %e2 = call i64 @reference_canonicalize_double(double -0.000000e+00)
  %a2 = call i64 @protected_canonicalize_double(double -0.000000e+00)
  ; +inf
  %e3 = call i64 @reference_canonicalize_double(double 0x7FF0000000000000)
  %a3 = call i64 @protected_canonicalize_double(double 0x7FF0000000000000)
  ; quiet NaN: compare reference vs protected bits only; do not pin payload
  %e4 = call i64 @reference_canonicalize_double(double 0x7FF8000000001234)
  %a4 = call i64 @protected_canonicalize_double(double 0x7FF8000000001234)
  ; fast canonicalize: +1.5 and -2.5 (finite inputs, partial nnan ninf flags)
  %e5 = call i64 @reference_fast_canonicalize_double(double 1.500000e+00)
  %a5 = call i64 @protected_fast_canonicalize_double(double 1.500000e+00)
  %e6 = call i64 @reference_fast_canonicalize_double(double -2.500000e+00)
  %a6 = call i64 @protected_fast_canonicalize_double(double -2.500000e+00)
  %m0 = icmp eq i64 %e0, %a0
  %m1 = icmp eq i64 %e1, %a1
  %m2 = icmp eq i64 %e2, %a2
  %m3 = icmp eq i64 %e3, %a3
  %m4 = icmp eq i64 %e4, %a4
  %m5 = icmp eq i64 %e5, %a5
  %m6 = icmp eq i64 %e6, %a6
  %t0 = and i1 %m0, %m1
  %t1 = and i1 %t0, %m2
  %t2 = and i1 %t1, %m3
  %t3 = and i1 %t2, %m4
  %t4 = and i1 %t3, %m5
  %ok = and i1 %t4, %m6
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; ---- O0 checks ----

; SKIP: seeded with: 121
; SKIP-DAG: Skipping VMP on unsupported_canonicalize_v2f16: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_canonicalize_v8f64: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_constrained_fadd_f64: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_canonicalize_double:
; SKIP-NOT: Skipping VMP on protected_fast_canonicalize_double:

; VIRT-LABEL: define i64 @protected_canonicalize_double(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: fmul double
; VIRT-NOT: {{call.*@llvm.canonicalize.f64}}

; VIRT-LABEL: define i64 @protected_fast_canonicalize_double(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT: fmul nnan ninf double
; VIRT-NOT: {{call.*@llvm.canonicalize.f64}}

; Negative cases stay native: no dispatch, no virtualized attribute.
; VIRT-LABEL: define double @unsupported_canonicalize_v2f16(
; VIRT-NOT: vmp.dispatch
; VIRT: call <2 x half> @llvm.canonicalize.v2f16(
; VIRT-LABEL: define <8 x double> @unsupported_canonicalize_v8f64(
; VIRT-NOT: vmp.dispatch
; VIRT: call <8 x double> @llvm.canonicalize.v8f64(
; VIRT-LABEL: define double @unsupported_constrained_fadd_f64(
; VIRT-NOT: vmp.dispatch
; VIRT: call fastcc double @llvm.experimental.constrained.fadd.f64(double {{.*}}, double {{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")

; VIRT: attributes{{.*}}"hikari.vmp.virtualized"

; ---- O2 checks ----

; SKIP-O2-DAG: Skipping VMP on unsupported_canonicalize_v2f16: unsupported call instruction
; SKIP-O2-DAG: Skipping VMP on unsupported_canonicalize_v8f64: unsupported return type
; SKIP-O2-DAG: Skipping VMP on unsupported_constrained_fadd_f64: unsupported call instruction
; SKIP-O2-NOT: Skipping VMP on protected_canonicalize_double:
; SKIP-O2-NOT: Skipping VMP on protected_fast_canonicalize_double:

; VIRT-O2-LABEL: define i64 @protected_canonicalize_double(
; VIRT-O2: %vmp.fregs = alloca
; VIRT-O2: vmp.dispatch:
; VIRT-O2-DAG: fmul double
; VIRT-O2-NOT: {{call.*@llvm.canonicalize.f64}}

; VIRT-O2-LABEL: define i64 @protected_fast_canonicalize_double(
; VIRT-O2: %vmp.fregs = alloca
; VIRT-O2: vmp.dispatch:
; VIRT-O2: fmul nnan ninf double
; VIRT-O2-NOT: {{call.*@llvm.canonicalize.f64}}
; Negative cases stay native at O2 as well.
; VIRT-O2-LABEL: define double @unsupported_canonicalize_v2f16(
; VIRT-O2-NOT: vmp.dispatch
; VIRT-O2: call <2 x half> @llvm.canonicalize.v2f16(
; VIRT-O2-LABEL: define <8 x double> @unsupported_canonicalize_v8f64(
; VIRT-O2-NOT: vmp.dispatch
; VIRT-O2: call <8 x double> @llvm.canonicalize.v8f64(
; VIRT-O2-LABEL: define double @unsupported_constrained_fadd_f64(
; VIRT-O2-NOT: vmp.dispatch
; VIRT-O2: call fastcc double @llvm.experimental.constrained.fadd.f64(double {{.*}}, double {{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")
; VIRT-O2: attributes{{.*}}"hikari.vmp.virtualized"
