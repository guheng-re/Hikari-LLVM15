; Scalar llvm.lround/llround/lrint/llrint.i64.f64 via the normal Call path
; (double arg VReg, i64 result VReg).  f32 i64-round behavior is unchanged.
; Each intrinsic has its own reference/* (native) and protected/* (VMP)
; pair; i64 results are compared independently so a mix-up among the four
; cannot pass.  No dedicated VM opcode.
; Runtime inputs stay in-range: +/- halfway, +/- non-halfway, +/- zero.
; NaN and out-of-range conversions are omitted (LangRef leaves those
; results undefined).
; Negative cases: half and vector lround overloads are not AArch64-llc
; selectable here, so the existing compilable equivalents (round.f16 /
; round.v2f32) are used; i32-result lround.i32.f64 is the real width gate;
; fast is illegal on i64-returning lround, so the constrained fadd.f64
; sentinel is used: AArch64/X86 select it, but it is never in the
; intrinsic whitelist (rounding/exception metadata, not FMF).
; O0 carries the detailed VIRT checks; O2 re-checks eligibility/stability.
;
; RUN: opt -S -verify-each -aesSeed=178 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.ll -o %t.o0.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=178 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP-O2 < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT-O2 < %t.o2.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.ll -o %t.o2.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare i64 @llvm.lround.i64.f64(double)
declare i64 @llvm.llround.i64.f64(double)
declare i64 @llvm.lrint.i64.f64(double)
declare i64 @llvm.llrint.i64.f64(double)
declare i32 @llvm.lround.i32.f64(double)
declare <2 x half> @llvm.round.v2f16(<2 x half>)
declare <2 x float> @llvm.round.v2f32(<2 x float>)
declare double @llvm.experimental.constrained.fadd.f64(double, double, metadata, metadata)

; ---- reference: native i64.f64 rounding, compared as i64 ----

define i64 @reference_lround_double(double %x) {
entry:
  %r = call i64 @llvm.lround.i64.f64(double %x)
  ret i64 %r
}

define i64 @reference_llround_double(double %x) {
entry:
  %r = call i64 @llvm.llround.i64.f64(double %x)
  ret i64 %r
}

define i64 @reference_lrint_double(double %x) {
entry:
  %r = call i64 @llvm.lrint.i64.f64(double %x)
  ret i64 %r
}

define i64 @reference_llrint_double(double %x) {
entry:
  %r = call i64 @llvm.llrint.i64.f64(double %x)
  ret i64 %r
}

; ---- protected: same four i64.f64 rounding intrinsics under VMP ----

define i64 @protected_lround_double(double %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.lround.i64.f64(double %x)
  ret i64 %r
}

define i64 @protected_llround_double(double %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.llround.i64.f64(double %x)
  ret i64 %r
}

define i64 @protected_lrint_double(double %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.lrint.i64.f64(double %x)
  ret i64 %r
}

define i64 @protected_llrint_double(double %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.llrint.i64.f64(double %x)
  ret i64 %r
}

; ---- negative cases: must SKIP, never virtualize ----

; llvm.lround.i64.f16 is not AArch64-selectable without +fullfp16 (llc
; cannot select lround f16).  Use the existing compilable half equivalent
; (round.f16) with the operand on an argument so O2 IPSCCP cannot
; constant-fold before VMP: unsupported argument type.
define double @unsupported_round_v2f16(<2 x half> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x half> @llvm.round.v2f16(<2 x half> %v)
  %e = extractelement <2 x half> %r, i32 0
  %f = fpext half %e to double
  ret double %f
}

; llvm.lround has no vector overload.  Use the existing compilable vector
; equivalent (round.v2f32).  Keep operands on arguments so O2 IPSCCP
; cannot constant-fold before VMP: unsupported return type.
define <2 x float> @unsupported_round_v2f32(<2 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.round.v2f32(<2 x float> %a)
  ret <2 x float> %r
}

; i32 result width must remain unsupported (whitelist is strictly i64).
define i32 @unsupported_lround_i32(double %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.lround.i32.f64(double %x)
  ret i32 %r
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

; ---- main: independent i64 parity for each intrinsic ----

define i32 @main() {
entry:
  ; +0.5 halfway
  %e0a = call i64 @reference_lround_double(double 5.000000e-01)
  %a0a = call i64 @protected_lround_double(double 5.000000e-01)
  %e0b = call i64 @reference_llround_double(double 5.000000e-01)
  %a0b = call i64 @protected_llround_double(double 5.000000e-01)
  %e0c = call i64 @reference_lrint_double(double 5.000000e-01)
  %a0c = call i64 @protected_lrint_double(double 5.000000e-01)
  %e0d = call i64 @reference_llrint_double(double 5.000000e-01)
  %a0d = call i64 @protected_llrint_double(double 5.000000e-01)
  ; -0.5 halfway
  %e1a = call i64 @reference_lround_double(double -5.000000e-01)
  %a1a = call i64 @protected_lround_double(double -5.000000e-01)
  %e1b = call i64 @reference_llround_double(double -5.000000e-01)
  %a1b = call i64 @protected_llround_double(double -5.000000e-01)
  %e1c = call i64 @reference_lrint_double(double -5.000000e-01)
  %a1c = call i64 @protected_lrint_double(double -5.000000e-01)
  %e1d = call i64 @reference_llrint_double(double -5.000000e-01)
  %a1d = call i64 @protected_llrint_double(double -5.000000e-01)
  ; +1.2 non-halfway
  %e2a = call i64 @reference_lround_double(double 1.200000e+00)
  %a2a = call i64 @protected_lround_double(double 1.200000e+00)
  %e2b = call i64 @reference_llround_double(double 1.200000e+00)
  %a2b = call i64 @protected_llround_double(double 1.200000e+00)
  %e2c = call i64 @reference_lrint_double(double 1.200000e+00)
  %a2c = call i64 @protected_lrint_double(double 1.200000e+00)
  %e2d = call i64 @reference_llrint_double(double 1.200000e+00)
  %a2d = call i64 @protected_llrint_double(double 1.200000e+00)
  ; -1.2 non-halfway
  %e3a = call i64 @reference_lround_double(double -1.200000e+00)
  %a3a = call i64 @protected_lround_double(double -1.200000e+00)
  %e3b = call i64 @reference_llround_double(double -1.200000e+00)
  %a3b = call i64 @protected_llround_double(double -1.200000e+00)
  %e3c = call i64 @reference_lrint_double(double -1.200000e+00)
  %a3c = call i64 @protected_lrint_double(double -1.200000e+00)
  %e3d = call i64 @reference_llrint_double(double -1.200000e+00)
  %a3d = call i64 @protected_llrint_double(double -1.200000e+00)
  ; +0.0
  %e4a = call i64 @reference_lround_double(double 0.000000e+00)
  %a4a = call i64 @protected_lround_double(double 0.000000e+00)
  %e4b = call i64 @reference_llround_double(double 0.000000e+00)
  %a4b = call i64 @protected_llround_double(double 0.000000e+00)
  %e4c = call i64 @reference_lrint_double(double 0.000000e+00)
  %a4c = call i64 @protected_lrint_double(double 0.000000e+00)
  %e4d = call i64 @reference_llrint_double(double 0.000000e+00)
  %a4d = call i64 @protected_llrint_double(double 0.000000e+00)
  ; -0.0
  %e5a = call i64 @reference_lround_double(double -0.000000e+00)
  %a5a = call i64 @protected_lround_double(double -0.000000e+00)
  %e5b = call i64 @reference_llround_double(double -0.000000e+00)
  %a5b = call i64 @protected_llround_double(double -0.000000e+00)
  %e5c = call i64 @reference_lrint_double(double -0.000000e+00)
  %a5c = call i64 @protected_lrint_double(double -0.000000e+00)
  %e5d = call i64 @reference_llrint_double(double -0.000000e+00)
  %a5d = call i64 @protected_llrint_double(double -0.000000e+00)
  %m0a = icmp eq i64 %e0a, %a0a
  %m0b = icmp eq i64 %e0b, %a0b
  %m0c = icmp eq i64 %e0c, %a0c
  %m0d = icmp eq i64 %e0d, %a0d
  %m1a = icmp eq i64 %e1a, %a1a
  %m1b = icmp eq i64 %e1b, %a1b
  %m1c = icmp eq i64 %e1c, %a1c
  %m1d = icmp eq i64 %e1d, %a1d
  %m2a = icmp eq i64 %e2a, %a2a
  %m2b = icmp eq i64 %e2b, %a2b
  %m2c = icmp eq i64 %e2c, %a2c
  %m2d = icmp eq i64 %e2d, %a2d
  %m3a = icmp eq i64 %e3a, %a3a
  %m3b = icmp eq i64 %e3b, %a3b
  %m3c = icmp eq i64 %e3c, %a3c
  %m3d = icmp eq i64 %e3d, %a3d
  %m4a = icmp eq i64 %e4a, %a4a
  %m4b = icmp eq i64 %e4b, %a4b
  %m4c = icmp eq i64 %e4c, %a4c
  %m4d = icmp eq i64 %e4d, %a4d
  %m5a = icmp eq i64 %e5a, %a5a
  %m5b = icmp eq i64 %e5b, %a5b
  %m5c = icmp eq i64 %e5c, %a5c
  %m5d = icmp eq i64 %e5d, %a5d
  %t0 = and i1 %m0a, %m0b
  %t1 = and i1 %m0c, %m0d
  %t2 = and i1 %m1a, %m1b
  %t3 = and i1 %m1c, %m1d
  %t4 = and i1 %m2a, %m2b
  %t5 = and i1 %m2c, %m2d
  %t6 = and i1 %m3a, %m3b
  %t7 = and i1 %m3c, %m3d
  %t8 = and i1 %m4a, %m4b
  %t9 = and i1 %m4c, %m4d
  %t10 = and i1 %m5a, %m5b
  %t11 = and i1 %m5c, %m5d
  %u0 = and i1 %t0, %t1
  %u1 = and i1 %t2, %t3
  %u2 = and i1 %t4, %t5
  %u3 = and i1 %t6, %t7
  %u4 = and i1 %t8, %t9
  %u5 = and i1 %t10, %t11
  %v0 = and i1 %u0, %u1
  %v1 = and i1 %u2, %u3
  %v2 = and i1 %u4, %u5
  %w0 = and i1 %v0, %v1
  %ok = and i1 %w0, %v2
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; ---- O0 checks ----

; SKIP-DAG: Skipping VMP on unsupported_round_v2f16: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_round_v2f32: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_lround_i32: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_constrained_fadd_f64: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_lround_double:
; SKIP-NOT: Skipping VMP on protected_llround_double:
; SKIP-NOT: Skipping VMP on protected_lrint_double:
; SKIP-NOT: Skipping VMP on protected_llrint_double:

; VIRT-LABEL: define i64 @protected_lround_double(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.lround.i64.f64(

; VIRT-LABEL: define i64 @protected_llround_double(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.llround.i64.f64(

; VIRT-LABEL: define i64 @protected_lrint_double(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.lrint.i64.f64(

; VIRT-LABEL: define i64 @protected_llrint_double(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.llrint.i64.f64(

; Negative cases stay native: no dispatch, no virtualized attribute.
; VIRT-LABEL: define double @unsupported_round_v2f16(
; VIRT-NOT: vmp.dispatch
; VIRT: call <2 x half> @llvm.round.v2f16(
; VIRT-LABEL: define <2 x float> @unsupported_round_v2f32(
; VIRT-NOT: vmp.dispatch
; VIRT: call <2 x float> @llvm.round.v2f32(
; VIRT-LABEL: define i32 @unsupported_lround_i32(
; VIRT-NOT: vmp.dispatch
; VIRT: call i32 @llvm.lround.i32.f64(
; VIRT-LABEL: define double @unsupported_constrained_fadd_f64(
; VIRT-NOT: vmp.dispatch
; VIRT: call fastcc double @llvm.experimental.constrained.fadd.f64(double {{.*}}, double {{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")

; VIRT: attributes{{.*}}"hikari.vmp.virtualized"{{.*}}

; ---- O2 checks ----

; SKIP-O2-DAG: Skipping VMP on unsupported_round_v2f16: unsupported call instruction
; SKIP-O2-DAG: Skipping VMP on unsupported_round_v2f32: unsupported call instruction
; SKIP-O2-DAG: Skipping VMP on unsupported_lround_i32: unsupported call instruction
; SKIP-O2-DAG: Skipping VMP on unsupported_constrained_fadd_f64: unsupported call instruction
; SKIP-O2-NOT: Skipping VMP on protected_lround_double:
; SKIP-O2-NOT: Skipping VMP on protected_llround_double:
; SKIP-O2-NOT: Skipping VMP on protected_lrint_double:
; SKIP-O2-NOT: Skipping VMP on protected_llrint_double:

; VIRT-O2-LABEL: define i64 @protected_lround_double(
; VIRT-O2: %vmp.fregs = alloca
; VIRT-O2: vmp.dispatch:
; VIRT-O2: call i64 @llvm.lround.i64.f64(

; VIRT-O2-LABEL: define i64 @protected_llround_double(
; VIRT-O2: %vmp.fregs = alloca
; VIRT-O2: vmp.dispatch:
; VIRT-O2: call i64 @llvm.llround.i64.f64(

; VIRT-O2-LABEL: define i64 @protected_lrint_double(
; VIRT-O2: %vmp.fregs = alloca
; VIRT-O2: vmp.dispatch:
; VIRT-O2: call i64 @llvm.lrint.i64.f64(

; VIRT-O2-LABEL: define i64 @protected_llrint_double(
; VIRT-O2: %vmp.fregs = alloca
; VIRT-O2: vmp.dispatch:
; VIRT-O2: call i64 @llvm.llrint.i64.f64(

; Negative cases stay native at O2 as well.
; VIRT-O2-LABEL: define double @unsupported_round_v2f16(
; VIRT-O2-NOT: vmp.dispatch
; VIRT-O2: call <2 x half> @llvm.round.v2f16(
; VIRT-O2-LABEL: define <2 x float> @unsupported_round_v2f32(
; VIRT-O2-NOT: vmp.dispatch
; VIRT-O2: call <2 x float> @llvm.round.v2f32(
; VIRT-O2-LABEL: define i32 @unsupported_lround_i32(
; VIRT-O2-NOT: vmp.dispatch
; VIRT-O2: call i32 @llvm.lround.i32.f64(
; VIRT-O2-LABEL: define double @unsupported_constrained_fadd_f64(
; VIRT-O2-NOT: vmp.dispatch
; VIRT-O2: call fastcc double @llvm.experimental.constrained.fadd.f64(double {{.*}}, double {{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")
; VIRT-O2: attributes{{.*}}"hikari.vmp.virtualized"{{.*}}
