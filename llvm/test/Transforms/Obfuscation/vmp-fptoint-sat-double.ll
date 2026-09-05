; Scalar llvm.fptosi/fptoui.sat.i32.f64 and i64.f64 via the normal Call path
; (double arg VReg, i32/i64 result VReg).  f32 sat behavior is unchanged.
; Each intrinsic has its own reference/* (native) and protected/* (VMP)
; pair; i32 and i64 results are compared independently so a mix-up among
; the four or a width swap cannot pass.  No dedicated VM opcode.
; Runtime inputs stay defined for these saturating conversions: +/- 1.5
; (unsigned negative clamps to zero) and exactly-representable finite
; values outside each destination range (saturation).  Inf/NaN omitted.
; Negative cases: fptosi.sat.i32.f16 (well-shaped half sat without
; last-token +fullfp16 is an unsupported-target-feature skip; the
; independent half sat surface lives in
; vmp-half-sat-convert-semantic.ll), fptosi.sat.v2i1.v2f32 (i1 dest
; stays out of the widened vector sat surface), and
; fptosi.sat.i1.f64 are AArch64-llc selectable, so they are the real
; no-feature half / unsupported dest-width vector / unsupported
; scalar dest-width gates.  O0 carries the detailed VIRT
; checks; O2 re-checks eligibility/stability.
;
; RUN: opt -S -verify-each -aesSeed=179 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.ll -o %t.o0.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=179 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP-O2 < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT-O2 < %t.o2.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.ll -o %t.o2.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare i32 @llvm.fptosi.sat.i32.f64(double)
declare i32 @llvm.fptoui.sat.i32.f64(double)
declare i64 @llvm.fptosi.sat.i64.f64(double)
declare i64 @llvm.fptoui.sat.i64.f64(double)
declare i32 @llvm.fptosi.sat.i32.f16(half)
declare <2 x i1> @llvm.fptosi.sat.v2i1.v2f32(<2 x float>)
declare i1 @llvm.fptosi.sat.i1.f64(double)

; ---- reference: native i32.f64 / i64.f64 sat conversions ----

define i32 @reference_fptosi_sat_i32_double(double %x) {
entry:
  %r = call i32 @llvm.fptosi.sat.i32.f64(double %x)
  ret i32 %r
}

define i32 @reference_fptoui_sat_i32_double(double %x) {
entry:
  %r = call i32 @llvm.fptoui.sat.i32.f64(double %x)
  ret i32 %r
}

define i64 @reference_fptosi_sat_i64_double(double %x) {
entry:
  %r = call i64 @llvm.fptosi.sat.i64.f64(double %x)
  ret i64 %r
}

define i64 @reference_fptoui_sat_i64_double(double %x) {
entry:
  %r = call i64 @llvm.fptoui.sat.i64.f64(double %x)
  ret i64 %r
}

; ---- protected: same four sat conversions under VMP ----

define i32 @protected_fptosi_sat_i32_double(double %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.fptosi.sat.i32.f64(double %x)
  ret i32 %r
}

define i32 @protected_fptoui_sat_i32_double(double %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.fptoui.sat.i32.f64(double %x)
  ret i32 %r
}

define i64 @protected_fptosi_sat_i64_double(double %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.fptosi.sat.i64.f64(double %x)
  ret i64 %r
}

define i64 @protected_fptoui_sat_i64_double(double %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.fptoui.sat.i64.f64(double %x)
  ret i64 %r
}

; ---- negative cases: must SKIP, never virtualize ----

; Well-shaped half sat without last-token +fullfp16 is a feature skip.
; Keep the operand on an argument so O2 IPSCCP cannot constant-fold
; before VMP.  Do not add +fullfp16 here (this file llc's the full
; native module).
define i32 @unsupported_fptosi_sat_f16(half %h) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.fptosi.sat.i32.f16(half %h)
  ret i32 %r
}

; i1 dest stays outside the widened vector sat surface (i8/i16/i32/i64 only).
; Keep operands on arguments so O2 IPSCCP cannot constant-fold before VMP.
define <2 x i1> @unsupported_fptosi_sat_v2i1(<2 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i1> @llvm.fptosi.sat.v2i1.v2f32(<2 x float> %a)
  ret <2 x i1> %r
}

; i1 result width stays outside the scalar sat surface (i8/i16/i32/i64 only).
define i1 @unsupported_fptosi_sat_i1(double %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i1 @llvm.fptosi.sat.i1.f64(double %x)
  ret i1 %r
}

; ---- main: independent i32/i64 parity for each intrinsic ----

define i32 @main() {
entry:
  ; +1.5 toward zero -> 1 for all four
  %e0s32 = call i32 @reference_fptosi_sat_i32_double(double 1.500000e+00)
  %a0s32 = call i32 @protected_fptosi_sat_i32_double(double 1.500000e+00)
  %e0u32 = call i32 @reference_fptoui_sat_i32_double(double 1.500000e+00)
  %a0u32 = call i32 @protected_fptoui_sat_i32_double(double 1.500000e+00)
  %e0s64 = call i64 @reference_fptosi_sat_i64_double(double 1.500000e+00)
  %a0s64 = call i64 @protected_fptosi_sat_i64_double(double 1.500000e+00)
  %e0u64 = call i64 @reference_fptoui_sat_i64_double(double 1.500000e+00)
  %a0u64 = call i64 @protected_fptoui_sat_i64_double(double 1.500000e+00)
  ; -1.5 toward zero -> signed -1; unsigned clamps to 0
  %e1s32 = call i32 @reference_fptosi_sat_i32_double(double -1.500000e+00)
  %a1s32 = call i32 @protected_fptosi_sat_i32_double(double -1.500000e+00)
  %e1u32 = call i32 @reference_fptoui_sat_i32_double(double -1.500000e+00)
  %a1u32 = call i32 @protected_fptoui_sat_i32_double(double -1.500000e+00)
  %e1s64 = call i64 @reference_fptosi_sat_i64_double(double -1.500000e+00)
  %a1s64 = call i64 @protected_fptosi_sat_i64_double(double -1.500000e+00)
  %e1u64 = call i64 @reference_fptoui_sat_i64_double(double -1.500000e+00)
  %a1u64 = call i64 @protected_fptoui_sat_i64_double(double -1.500000e+00)
  ; 2^32 = 4294967296.0: i32 signed/unsigned saturate; i64 exact
  %e2s32 = call i32 @reference_fptosi_sat_i32_double(double 0x41F0000000000000)
  %a2s32 = call i32 @protected_fptosi_sat_i32_double(double 0x41F0000000000000)
  %e2u32 = call i32 @reference_fptoui_sat_i32_double(double 0x41F0000000000000)
  %a2u32 = call i32 @protected_fptoui_sat_i32_double(double 0x41F0000000000000)
  %e2s64 = call i64 @reference_fptosi_sat_i64_double(double 0x41F0000000000000)
  %a2s64 = call i64 @protected_fptosi_sat_i64_double(double 0x41F0000000000000)
  %e2u64 = call i64 @reference_fptoui_sat_i64_double(double 0x41F0000000000000)
  %a2u64 = call i64 @protected_fptoui_sat_i64_double(double 0x41F0000000000000)
  ; 2^64: all four saturate to distinct extrema (width and signedness)
  %e3s32 = call i32 @reference_fptosi_sat_i32_double(double 0x43F0000000000000)
  %a3s32 = call i32 @protected_fptosi_sat_i32_double(double 0x43F0000000000000)
  %e3u32 = call i32 @reference_fptoui_sat_i32_double(double 0x43F0000000000000)
  %a3u32 = call i32 @protected_fptoui_sat_i32_double(double 0x43F0000000000000)
  %e3s64 = call i64 @reference_fptosi_sat_i64_double(double 0x43F0000000000000)
  %a3s64 = call i64 @protected_fptosi_sat_i64_double(double 0x43F0000000000000)
  %e3u64 = call i64 @reference_fptoui_sat_i64_double(double 0x43F0000000000000)
  %a3u64 = call i64 @protected_fptoui_sat_i64_double(double 0x43F0000000000000)
  ; next double below -2^63: signed saturate to min; unsigned clamps to 0
  %e4s32 = call i32 @reference_fptosi_sat_i32_double(double 0xC3E0000000000001)
  %a4s32 = call i32 @protected_fptosi_sat_i32_double(double 0xC3E0000000000001)
  %e4u32 = call i32 @reference_fptoui_sat_i32_double(double 0xC3E0000000000001)
  %a4u32 = call i32 @protected_fptoui_sat_i32_double(double 0xC3E0000000000001)
  %e4s64 = call i64 @reference_fptosi_sat_i64_double(double 0xC3E0000000000001)
  %a4s64 = call i64 @protected_fptosi_sat_i64_double(double 0xC3E0000000000001)
  %e4u64 = call i64 @reference_fptoui_sat_i64_double(double 0xC3E0000000000001)
  %a4u64 = call i64 @protected_fptoui_sat_i64_double(double 0xC3E0000000000001)
  %m0s32 = icmp eq i32 %e0s32, %a0s32
  %m0u32 = icmp eq i32 %e0u32, %a0u32
  %m0s64 = icmp eq i64 %e0s64, %a0s64
  %m0u64 = icmp eq i64 %e0u64, %a0u64
  %m1s32 = icmp eq i32 %e1s32, %a1s32
  %m1u32 = icmp eq i32 %e1u32, %a1u32
  %m1s64 = icmp eq i64 %e1s64, %a1s64
  %m1u64 = icmp eq i64 %e1u64, %a1u64
  %m2s32 = icmp eq i32 %e2s32, %a2s32
  %m2u32 = icmp eq i32 %e2u32, %a2u32
  %m2s64 = icmp eq i64 %e2s64, %a2s64
  %m2u64 = icmp eq i64 %e2u64, %a2u64
  %m3s32 = icmp eq i32 %e3s32, %a3s32
  %m3u32 = icmp eq i32 %e3u32, %a3u32
  %m3s64 = icmp eq i64 %e3s64, %a3s64
  %m3u64 = icmp eq i64 %e3u64, %a3u64
  %m4s32 = icmp eq i32 %e4s32, %a4s32
  %m4u32 = icmp eq i32 %e4u32, %a4u32
  %m4s64 = icmp eq i64 %e4s64, %a4s64
  %m4u64 = icmp eq i64 %e4u64, %a4u64
  %t0 = and i1 %m0s32, %m0u32
  %t1 = and i1 %m0s64, %m0u64
  %t2 = and i1 %m1s32, %m1u32
  %t3 = and i1 %m1s64, %m1u64
  %t4 = and i1 %m2s32, %m2u32
  %t5 = and i1 %m2s64, %m2u64
  %t6 = and i1 %m3s32, %m3u32
  %t7 = and i1 %m3s64, %m3u64
  %t8 = and i1 %m4s32, %m4u32
  %t9 = and i1 %m4s64, %m4u64
  %u0 = and i1 %t0, %t1
  %u1 = and i1 %t2, %t3
  %u2 = and i1 %t4, %t5
  %u3 = and i1 %t6, %t7
  %u4 = and i1 %t8, %t9
  %v0 = and i1 %u0, %u1
  %v1 = and i1 %u2, %u3
  %w0 = and i1 %v0, %v1
  %ok = and i1 %w0, %u4
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; ---- O0 checks ----

; SKIP-DAG: Skipping VMP on unsupported_fptosi_sat_f16: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_fptosi_sat_v2i1: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_fptosi_sat_i1: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_fptosi_sat_i32_double:
; SKIP-NOT: Skipping VMP on protected_fptoui_sat_i32_double:
; SKIP-NOT: Skipping VMP on protected_fptosi_sat_i64_double:
; SKIP-NOT: Skipping VMP on protected_fptoui_sat_i64_double:

; VIRT-LABEL: define i32 @protected_fptosi_sat_i32_double(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.fptosi.sat.i32.f64(

; VIRT-LABEL: define i32 @protected_fptoui_sat_i32_double(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.fptoui.sat.i32.f64(

; VIRT-LABEL: define i64 @protected_fptosi_sat_i64_double(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.fptosi.sat.i64.f64(

; VIRT-LABEL: define i64 @protected_fptoui_sat_i64_double(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.fptoui.sat.i64.f64(

; Negative cases stay native: no dispatch, no virtualized attribute.
; VIRT-LABEL: define i32 @unsupported_fptosi_sat_f16(
; VIRT-NOT: vmp.dispatch
; VIRT: call i32 @llvm.fptosi.sat.i32.f16(
; VIRT-LABEL: define <2 x i1> @unsupported_fptosi_sat_v2i1(
; VIRT-NOT: vmp.dispatch
; VIRT: call <2 x i1> @llvm.fptosi.sat.v2i1.v2f32(
; VIRT-LABEL: define i1 @unsupported_fptosi_sat_i1(
; VIRT-NOT: vmp.dispatch
; VIRT: call i1 @llvm.fptosi.sat.i1.f64(

; VIRT: attributes{{.*}}"hikari.vmp.virtualized"{{.*}}

; ---- O2 checks ----

; SKIP-O2-DAG: Skipping VMP on unsupported_fptosi_sat_f16: unsupported target feature
; SKIP-O2-DAG: Skipping VMP on unsupported_fptosi_sat_v2i1: unsupported call instruction
; SKIP-O2-DAG: Skipping VMP on unsupported_fptosi_sat_i1: unsupported call instruction
; SKIP-O2-NOT: Skipping VMP on protected_fptosi_sat_i32_double:
; SKIP-O2-NOT: Skipping VMP on protected_fptoui_sat_i32_double:
; SKIP-O2-NOT: Skipping VMP on protected_fptosi_sat_i64_double:
; SKIP-O2-NOT: Skipping VMP on protected_fptoui_sat_i64_double:

; VIRT-O2-LABEL: define i32 @protected_fptosi_sat_i32_double(
; VIRT-O2: %vmp.fregs = alloca
; VIRT-O2: vmp.dispatch:
; VIRT-O2: call i32 @llvm.fptosi.sat.i32.f64(

; VIRT-O2-LABEL: define i32 @protected_fptoui_sat_i32_double(
; VIRT-O2: %vmp.fregs = alloca
; VIRT-O2: vmp.dispatch:
; VIRT-O2: call i32 @llvm.fptoui.sat.i32.f64(

; VIRT-O2-LABEL: define i64 @protected_fptosi_sat_i64_double(
; VIRT-O2: %vmp.fregs = alloca
; VIRT-O2: vmp.dispatch:
; VIRT-O2: call i64 @llvm.fptosi.sat.i64.f64(

; VIRT-O2-LABEL: define i64 @protected_fptoui_sat_i64_double(
; VIRT-O2: %vmp.fregs = alloca
; VIRT-O2: vmp.dispatch:
; VIRT-O2: call i64 @llvm.fptoui.sat.i64.f64(

; Negative cases stay native at O2 as well.
; VIRT-O2-LABEL: define i32 @unsupported_fptosi_sat_f16(
; VIRT-O2-NOT: vmp.dispatch
; VIRT-O2: call i32 @llvm.fptosi.sat.i32.f16(
; VIRT-O2-LABEL: define <2 x i1> @unsupported_fptosi_sat_v2i1(
; VIRT-O2-NOT: vmp.dispatch
; VIRT-O2: call <2 x i1> @llvm.fptosi.sat.v2i1.v2f32(
; VIRT-O2-LABEL: define i1 @unsupported_fptosi_sat_i1(
; VIRT-O2-NOT: vmp.dispatch
; VIRT-O2: call i1 @llvm.fptosi.sat.i1.f64(
; VIRT-O2: attributes{{.*}}"hikari.vmp.virtualized"{{.*}}
