; Scalar llvm.is.fpclass.f32/f64 via the normal Call path (i1 result, scalar
; float/double operand, i32 immarg mask).  The mask travels on the
; CallDescriptor (ImmediateArguments) and stays a true i32 constant on
; re-emit, never a VReg.  Masks used: fcNan=1, fcPosZero|fcNegZero=1536,
; finite (normal+subnormal+zero)=2016, fcPosInf|fcNegInf=24.  reference/*
; run natively, protected/* are virtualized; main compares the OR of the
; four zext'd i1 results over bitcast inputs covering +/-0, finite +/-, +/-
; inf, and quiet NaN.  Half llvm.is.fpclass.f16 without last-token
; +fullfp16 is a feature skip (separate surface).  >128-bit vector
; is_fpclass stays rejected; in-range f32/f64 vector is.fpclass is a
; separate surface.
;
; RUN: opt -S -verify-each -aesSeed=147 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.ll -o %t.o0.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=147 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP-O2 < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT-O2 < %t.o2.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.ll -o %t.o2.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare i1 @llvm.is.fpclass.f32(float, i32)
declare i1 @llvm.is.fpclass.f64(double, i32)
declare i1 @llvm.is.fpclass.f16(half, i32)
declare <8 x i1> @llvm.is.fpclass.v8f64(<8 x double>, i32)

; ---- reference: native is.fpclass.f32, OR of four zext'd i1 results ----

define i32 @reference_fpclass_f32(i32 %bits) {
entry:
  %a = bitcast i32 %bits to float
  %r0 = call i1 @llvm.is.fpclass.f32(float %a, i32 1)
  %r1 = call i1 @llvm.is.fpclass.f32(float %a, i32 1536)
  %r2 = call i1 @llvm.is.fpclass.f32(float %a, i32 2016)
  %r3 = call i1 @llvm.is.fpclass.f32(float %a, i32 24)
  %z0 = zext i1 %r0 to i32
  %z1 = zext i1 %r1 to i32
  %z2 = zext i1 %r2 to i32
  %z3 = zext i1 %r3 to i32
  %o0 = or i32 %z0, %z1
  %o1 = or i32 %o0, %z2
  %o2 = or i32 %o1, %z3
  ret i32 %o2
}

; ---- protected: same is.fpclass.f32 under VMP ----

define i32 @protected_fpclass_f32(i32 %bits) noinline optnone {
entry:
  call void @hikari_vmp()
  %a = bitcast i32 %bits to float
  %r0 = call i1 @llvm.is.fpclass.f32(float %a, i32 1)
  %r1 = call i1 @llvm.is.fpclass.f32(float %a, i32 1536)
  %r2 = call i1 @llvm.is.fpclass.f32(float %a, i32 2016)
  %r3 = call i1 @llvm.is.fpclass.f32(float %a, i32 24)
  %z0 = zext i1 %r0 to i32
  %z1 = zext i1 %r1 to i32
  %z2 = zext i1 %r2 to i32
  %z3 = zext i1 %r3 to i32
  %o0 = or i32 %z0, %z1
  %o1 = or i32 %o0, %z2
  %o2 = or i32 %o1, %z3
  ret i32 %o2
}

; ---- reference: native is.fpclass.f64, OR of four zext'd i1 results ----

define i32 @reference_fpclass_f64(double %x) {
entry:
  %r0 = call i1 @llvm.is.fpclass.f64(double %x, i32 1)
  %r1 = call i1 @llvm.is.fpclass.f64(double %x, i32 1536)
  %r2 = call i1 @llvm.is.fpclass.f64(double %x, i32 2016)
  %r3 = call i1 @llvm.is.fpclass.f64(double %x, i32 24)
  %z0 = zext i1 %r0 to i32
  %z1 = zext i1 %r1 to i32
  %z2 = zext i1 %r2 to i32
  %z3 = zext i1 %r3 to i32
  %o0 = or i32 %z0, %z1
  %o1 = or i32 %o0, %z2
  %o2 = or i32 %o1, %z3
  ret i32 %o2
}

; ---- protected: same is.fpclass.f64 under VMP ----

define i32 @protected_fpclass_f64(double %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r0 = call i1 @llvm.is.fpclass.f64(double %x, i32 1)
  %r1 = call i1 @llvm.is.fpclass.f64(double %x, i32 1536)
  %r2 = call i1 @llvm.is.fpclass.f64(double %x, i32 2016)
  %r3 = call i1 @llvm.is.fpclass.f64(double %x, i32 24)
  %z0 = zext i1 %r0 to i32
  %z1 = zext i1 %r1 to i32
  %z2 = zext i1 %r2 to i32
  %z3 = zext i1 %r3 to i32
  %o0 = or i32 %z0, %z1
  %o1 = or i32 %o0, %z2
  %o2 = or i32 %o1, %z3
  ret i32 %o2
}

; ---- negative cases: must SKIP, never virtualize ----

; Wide llvm.is.fpclass.v8f64 stays outside the 1..128 f32/f64 vector
; is.fpclass surface; native call is preserved.
define <8 x i1> @unsupported_fpclass_v8f64(<8 x double> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i1> @llvm.is.fpclass.v8f64(<8 x double> %a, i32 1)
  ret <8 x i1> %r
}

; Half llvm.is.fpclass.f16 without last-token +fullfp16 is a feature skip.
define i32 @unsupported_fpclass_f16(half %h) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i1 @llvm.is.fpclass.f16(half %h, i32 1)
  %z = zext i1 %r to i32
  ret i32 %z
}

; ---- main: parity checks (f32 bitcast inputs; f64 double inputs) ----

define i32 @main() {
entry:
  ; f32: +0 bits 0
  %e0 = call i32 @reference_fpclass_f32(i32 0)
  %a0 = call i32 @protected_fpclass_f32(i32 0)
  ; f32: -0 bits 0x80000000
  %e1 = call i32 @reference_fpclass_f32(i32 -2147483648)
  %a1 = call i32 @protected_fpclass_f32(i32 -2147483648)
  ; f32: +1.5 bits 0x3fc00000
  %e2 = call i32 @reference_fpclass_f32(i32 1069547520)
  %a2 = call i32 @protected_fpclass_f32(i32 1069547520)
  ; f32: -2.5 bits 0xc0200000
  %e3 = call i32 @reference_fpclass_f32(i32 -1071644672)
  %a3 = call i32 @protected_fpclass_f32(i32 -1071644672)
  ; f32: +inf bits 0x7f800000
  %e4 = call i32 @reference_fpclass_f32(i32 2139095040)
  %a4 = call i32 @protected_fpclass_f32(i32 2139095040)
  ; f32: -inf bits 0xff800000
  %e5 = call i32 @reference_fpclass_f32(i32 -8388608)
  %a5 = call i32 @protected_fpclass_f32(i32 -8388608)
  ; f32: quiet NaN bits 0x7fc01234
  %e6 = call i32 @reference_fpclass_f32(i32 2143294004)
  %a6 = call i32 @protected_fpclass_f32(i32 2143294004)
  ; f64: +0.0
  %e7 = call i32 @reference_fpclass_f64(double 0.000000e+00)
  %a7 = call i32 @protected_fpclass_f64(double 0.000000e+00)
  ; f64: -0.0
  %e8 = call i32 @reference_fpclass_f64(double -0.000000e+00)
  %a8 = call i32 @protected_fpclass_f64(double -0.000000e+00)
  ; f64: +1.5
  %e9 = call i32 @reference_fpclass_f64(double 1.500000e+00)
  %a9 = call i32 @protected_fpclass_f64(double 1.500000e+00)
  ; f64: -2.5
  %e10 = call i32 @reference_fpclass_f64(double -2.500000e+00)
  %a10 = call i32 @protected_fpclass_f64(double -2.500000e+00)
  ; f64: +inf
  %e11 = call i32 @reference_fpclass_f64(double 0x7FF0000000000000)
  %a11 = call i32 @protected_fpclass_f64(double 0x7FF0000000000000)
  ; f64: -inf
  %e12 = call i32 @reference_fpclass_f64(double 0xFFF0000000000000)
  %a12 = call i32 @protected_fpclass_f64(double 0xFFF0000000000000)
  ; f64: quiet NaN
  %e13 = call i32 @reference_fpclass_f64(double 0x7FF8000000001234)
  %a13 = call i32 @protected_fpclass_f64(double 0x7FF8000000001234)
  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %e1, %a1
  %m2 = icmp eq i32 %e2, %a2
  %m3 = icmp eq i32 %e3, %a3
  %m4 = icmp eq i32 %e4, %a4
  %m5 = icmp eq i32 %e5, %a5
  %m6 = icmp eq i32 %e6, %a6
  %m7 = icmp eq i32 %e7, %a7
  %m8 = icmp eq i32 %e8, %a8
  %m9 = icmp eq i32 %e9, %a9
  %m10 = icmp eq i32 %e10, %a10
  %m11 = icmp eq i32 %e11, %a11
  %m12 = icmp eq i32 %e12, %a12
  %m13 = icmp eq i32 %e13, %a13
  %t0 = and i1 %m0, %m1
  %t1 = and i1 %t0, %m2
  %t2 = and i1 %t1, %m3
  %t3 = and i1 %t2, %m4
  %t4 = and i1 %t3, %m5
  %t5 = and i1 %t4, %m6
  %t6 = and i1 %t5, %m7
  %t7 = and i1 %t6, %m8
  %t8 = and i1 %t7, %m9
  %t9 = and i1 %t8, %m10
  %t10 = and i1 %t9, %m11
  %t11 = and i1 %t10, %m12
  %ok = and i1 %t11, %m13
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; ---- O0 checks ----

; SKIP-DAG: Skipping VMP on unsupported_fpclass_v8f64: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_fpclass_f16: unsupported target feature
; SKIP-NOT: Skipping VMP on protected_fpclass_f32:
; SKIP-NOT: Skipping VMP on protected_fpclass_f64:

; VIRT-LABEL: define i32 @protected_fpclass_f32(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: call i1 @llvm.is.fpclass.f32(float {{.*}}, i32 1)
; VIRT-DAG: call i1 @llvm.is.fpclass.f32(float {{.*}}, i32 1536)
; VIRT-DAG: call i1 @llvm.is.fpclass.f32(float {{.*}}, i32 2016)
; VIRT-DAG: call i1 @llvm.is.fpclass.f32(float {{.*}}, i32 24)

; VIRT-LABEL: define i32 @protected_fpclass_f64(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: call i1 @llvm.is.fpclass.f64(double {{.*}}, i32 1)
; VIRT-DAG: call i1 @llvm.is.fpclass.f64(double {{.*}}, i32 1536)
; VIRT-DAG: call i1 @llvm.is.fpclass.f64(double {{.*}}, i32 2016)
; VIRT-DAG: call i1 @llvm.is.fpclass.f64(double {{.*}}, i32 24)

; Negative cases stay native: no dispatch, no virtualized attribute.
; VIRT-LABEL: define <8 x i1> @unsupported_fpclass_v8f64(
; VIRT-NOT: vmp.dispatch
; VIRT: call <8 x i1> @llvm.is.fpclass.v8f64(
; VIRT-LABEL: define i32 @unsupported_fpclass_f16(
; VIRT-NOT: vmp.dispatch
; VIRT: call i1 @llvm.is.fpclass.f16(

; VIRT: attributes{{.*}}"hikari.vmp.virtualized"{{.*}}

; ---- O2 checks ----

; SKIP-O2-DAG: Skipping VMP on unsupported_fpclass_v8f64: unsupported argument type
; SKIP-O2-DAG: Skipping VMP on unsupported_fpclass_f16: unsupported target feature
; SKIP-O2-NOT: Skipping VMP on protected_fpclass_f32:
; SKIP-O2-NOT: Skipping VMP on protected_fpclass_f64:

; VIRT-O2-LABEL: define i32 @protected_fpclass_f32(
; VIRT-O2: %vmp.fregs = alloca
; VIRT-O2: vmp.dispatch:
; VIRT-O2-DAG: call i1 @llvm.is.fpclass.f32(float {{.*}}, i32 1)
; VIRT-O2-DAG: call i1 @llvm.is.fpclass.f32(float {{.*}}, i32 1536)
; VIRT-O2-DAG: call i1 @llvm.is.fpclass.f32(float {{.*}}, i32 2016)
; VIRT-O2-DAG: call i1 @llvm.is.fpclass.f32(float {{.*}}, i32 24)

; VIRT-O2-LABEL: define i32 @protected_fpclass_f64(
; VIRT-O2: %vmp.fregs = alloca
; VIRT-O2: vmp.dispatch:
; VIRT-O2-DAG: call i1 @llvm.is.fpclass.f64(double {{.*}}, i32 1)
; VIRT-O2-DAG: call i1 @llvm.is.fpclass.f64(double {{.*}}, i32 1536)
; VIRT-O2-DAG: call i1 @llvm.is.fpclass.f64(double {{.*}}, i32 2016)
; VIRT-O2-DAG: call i1 @llvm.is.fpclass.f64(double {{.*}}, i32 24)
; Negative cases stay native at O2 as well.
; VIRT-O2-LABEL: define <8 x i1> @unsupported_fpclass_v8f64(
; VIRT-O2-NOT: vmp.dispatch
; VIRT-O2: call <8 x i1> @llvm.is.fpclass.v8f64(
; VIRT-O2-LABEL: define i32 @unsupported_fpclass_f16(
; VIRT-O2-NOT: vmp.dispatch
; VIRT-O2: call i1 @llvm.is.fpclass.f16(
; VIRT-O2: attributes{{.*}}"hikari.vmp.virtualized"{{.*}}
