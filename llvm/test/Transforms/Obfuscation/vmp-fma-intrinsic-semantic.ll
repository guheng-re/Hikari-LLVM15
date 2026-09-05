; Scalar llvm.fma.f32 / llvm.fmuladd.f32 via normal Call path (float VReg frame).
; RUN: opt -S -verify-each -aesSeed=53 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=53 -passes='default<O2>' %s -o %t.o2.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare float @llvm.fma.f32(float, float, float)
declare float @llvm.fmuladd.f32(float, float, float)

; Bit-pattern i32 inputs: bitcast to float, fma, bitcast result back to i32.
define i32 @reference_fma(i32 %bits_a, i32 %bits_b, i32 %bits_c) {
entry:
  %a = bitcast i32 %bits_a to float
  %b = bitcast i32 %bits_b to float
  %c = bitcast i32 %bits_c to float
  %r = call float @llvm.fma.f32(float %a, float %b, float %c)
  %out = bitcast float %r to i32
  ret i32 %out
}

define i32 @protected_fma(i32 %bits_a, i32 %bits_b, i32 %bits_c) noinline optnone {
entry:
  call void @hikari_vmp()
  %a = bitcast i32 %bits_a to float
  %b = bitcast i32 %bits_b to float
  %c = bitcast i32 %bits_c to float
  %r = call float @llvm.fma.f32(float %a, float %b, float %c)
  %out = bitcast float %r to i32
  ret i32 %out
}

; Same bitcast pattern for llvm.fmuladd.f32.
define i32 @reference_fmuladd(i32 %bits_a, i32 %bits_b, i32 %bits_c) {
entry:
  %a = bitcast i32 %bits_a to float
  %b = bitcast i32 %bits_b to float
  %c = bitcast i32 %bits_c to float
  %r = call float @llvm.fmuladd.f32(float %a, float %b, float %c)
  %out = bitcast float %r to i32
  ret i32 %out
}

define i32 @protected_fmuladd(i32 %bits_a, i32 %bits_b, i32 %bits_c) noinline optnone {
entry:
  call void @hikari_vmp()
  %a = bitcast i32 %bits_a to float
  %b = bitcast i32 %bits_b to float
  %c = bitcast i32 %bits_c to float
  %r = call float @llvm.fmuladd.f32(float %a, float %b, float %c)
  %out = bitcast float %r to i32
  ret i32 %out
}

; Fast-math fma is VMP-supported (CallDescriptor FMF mask restored).
define i32 @reference_fast_fma(i32 %bits_a, i32 %bits_b, i32 %bits_c) {
entry:
  %a = bitcast i32 %bits_a to float
  %b = bitcast i32 %bits_b to float
  %c = bitcast i32 %bits_c to float
  %r = call fast float @llvm.fma.f32(float %a, float %b, float %c)
  %out = bitcast float %r to i32
  ret i32 %out
}

define i32 @protected_fast_fma(i32 %bits_a, i32 %bits_b, i32 %bits_c) noinline optnone {
entry:
  call void @hikari_vmp()
  %a = bitcast i32 %bits_a to float
  %b = bitcast i32 %bits_b to float
  %c = bitcast i32 %bits_c to float
  %r = call fast float @llvm.fma.f32(float %a, float %b, float %c)
  %out = bitcast float %r to i32
  ret i32 %out
}

; Fast-math fmuladd is VMP-supported (CallDescriptor FMF mask restored).
define i32 @reference_fast_fmuladd(i32 %bits_a, i32 %bits_b, i32 %bits_c) {
entry:
  %a = bitcast i32 %bits_a to float
  %b = bitcast i32 %bits_b to float
  %c = bitcast i32 %bits_c to float
  %r = call fast float @llvm.fmuladd.f32(float %a, float %b, float %c)
  %out = bitcast float %r to i32
  ret i32 %out
}

define i32 @protected_fast_fmuladd(i32 %bits_a, i32 %bits_b, i32 %bits_c) noinline optnone {
entry:
  call void @hikari_vmp()
  %a = bitcast i32 %bits_a to float
  %b = bitcast i32 %bits_b to float
  %c = bitcast i32 %bits_c to float
  %r = call fast float @llvm.fmuladd.f32(float %a, float %b, float %c)
  %out = bitcast float %r to i32
  ret i32 %out
}

; llvm.experimental.constrained.fadd.f32 uses non-C fastcc so the now-
; supported C constrained-fadd surface stays a skip ("unsupported call
; instruction").
declare float @llvm.experimental.constrained.fadd.f32(float, float, metadata, metadata)

define i32 @unsupported_constrained_fadd_f32(i32 %bits) noinline optnone {
entry:
  call void @hikari_vmp()
  %a = bitcast i32 %bits to float
  %r = call fastcc float @llvm.experimental.constrained.fadd.f32(float %a, float %a, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  %out = bitcast float %r to i32
  ret i32 %out
}

define i32 @main() {
entry:
  ; positive: fma(1.0, 2.0, 3.0)  bits 0x3f800000, 0x40000000, 0x40400000
  %e0 = call i32 @reference_fma(i32 1065353216, i32 1073741824, i32 1077936128)
  %a0 = call i32 @protected_fma(i32 1065353216, i32 1073741824, i32 1077936128)
  ; negative: fma(-1.0, 2.0, -3.0)  bits 0xbf800000, 0x40000000, 0xc0400000
  %e1 = call i32 @reference_fma(i32 -1082130432, i32 1073741824, i32 -1069547520)
  %a1 = call i32 @protected_fma(i32 -1082130432, i32 1073741824, i32 -1069547520)
  ; zero: fma(0.0, 5.0, 0.0)  bits 0, 0x40a00000, 0
  %e2 = call i32 @reference_fma(i32 0, i32 1084227584, i32 0)
  %a2 = call i32 @protected_fma(i32 0, i32 1084227584, i32 0)
  ; fmuladd positive: fmuladd(1.0, 2.0, 3.0)
  %e3 = call i32 @reference_fmuladd(i32 1065353216, i32 1073741824, i32 1077936128)
  %a3 = call i32 @protected_fmuladd(i32 1065353216, i32 1073741824, i32 1077936128)
  ; fmuladd negative: fmuladd(-1.0, 2.0, -3.0)
  %e4 = call i32 @reference_fmuladd(i32 -1082130432, i32 1073741824, i32 -1069547520)
  %a4 = call i32 @protected_fmuladd(i32 -1082130432, i32 1073741824, i32 -1069547520)
  ; fast fma positive: fma(1.0, 2.0, 3.0)
  %e5 = call i32 @reference_fast_fma(i32 1065353216, i32 1073741824, i32 1077936128)
  %a5 = call i32 @protected_fast_fma(i32 1065353216, i32 1073741824, i32 1077936128)
  ; fast fma negative: fma(-1.0, 2.0, -3.0)
  %e6 = call i32 @reference_fast_fma(i32 -1082130432, i32 1073741824, i32 -1069547520)
  %a6 = call i32 @protected_fast_fma(i32 -1082130432, i32 1073741824, i32 -1069547520)
  ; fast fmuladd positive: fmuladd(1.0, 2.0, 3.0)
  %e7 = call i32 @reference_fast_fmuladd(i32 1065353216, i32 1073741824, i32 1077936128)
  %a7 = call i32 @protected_fast_fmuladd(i32 1065353216, i32 1073741824, i32 1077936128)
  ; fast fmuladd negative: fmuladd(-1.0, 2.0, -3.0)
  %e8 = call i32 @reference_fast_fmuladd(i32 -1082130432, i32 1073741824, i32 -1069547520)
  %a8 = call i32 @protected_fast_fmuladd(i32 -1082130432, i32 1073741824, i32 -1069547520)
  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %e1, %a1
  %m2 = icmp eq i32 %e2, %a2
  %m3 = icmp eq i32 %e3, %a3
  %m4 = icmp eq i32 %e4, %a4
  %m5 = icmp eq i32 %e5, %a5
  %m6 = icmp eq i32 %e6, %a6
  %m7 = icmp eq i32 %e7, %a7
  %m8 = icmp eq i32 %e8, %a8
  %t0 = and i1 %m0, %m1
  %t1 = and i1 %t0, %m2
  %t2 = and i1 %t1, %m3
  %t3 = and i1 %t2, %m4
  %t4 = and i1 %t3, %m5
  %t5 = and i1 %t4, %m6
  %t6 = and i1 %t5, %m7
  %ok = and i1 %t6, %m8
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with: 53
; SKIP-DAG: Skipping VMP on unsupported_constrained_fadd_f32: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_fma:
; SKIP-NOT: Skipping VMP on protected_fmuladd:
; SKIP-NOT: Skipping VMP on protected_fast_fma:
; SKIP-NOT: Skipping VMP on protected_fast_fmuladd:

; VIRT-LABEL: define i32 @protected_fma(
; VIRT: vmp.dispatch:
; VIRT-DAG: call float @llvm.fma.f32(
; VIRT-LABEL: define i32 @protected_fmuladd(
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.fmuladd.f32(
; VIRT-LABEL: define i32 @protected_fast_fma(
; VIRT: vmp.dispatch:
; VIRT: call fast float @llvm.fma.f32(
; VIRT-LABEL: define i32 @protected_fast_fmuladd(
; VIRT: vmp.dispatch:
; VIRT: call fast float @llvm.fmuladd.f32(
; VIRT-LABEL: define i32 @unsupported_constrained_fadd_f32(
; VIRT-NOT: vmp.dispatch
; VIRT: call fastcc float @llvm.experimental.constrained.fadd.f32(float {{.*}}, float {{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")

; VIRT: attributes{{.*}}"hikari.vmp.virtualized"
