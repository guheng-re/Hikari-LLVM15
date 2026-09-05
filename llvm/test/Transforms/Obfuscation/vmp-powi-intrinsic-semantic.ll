; Scalar llvm.powi.f32.i32 via normal Call path (float base + i32 exp VRegs).
; Fast-math powi.f32.i32 is VMP-supported (CallDescriptor FMF mask restored);
; the constrained-fadd sentinel is rejected by the intrinsic whitelist.
;
; RUN: opt -S -verify-each -aesSeed=129 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.ll -o %t.o0.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=129 -passes='default<O2>' %s -o %t.o2.ll
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.ll -o %t.o2.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare float @llvm.powi.f32.i32(float, i32)

; Bit-pattern i32 base + i32 exponent: powi, bitcast result back to i32.
define i32 @reference_powi(i32 %bits, i32 %exp) {
entry:
  %a = bitcast i32 %bits to float
  %r = call float @llvm.powi.f32.i32(float %a, i32 %exp)
  %out = bitcast float %r to i32
  ret i32 %out
}

define i32 @protected_powi(i32 %bits, i32 %exp) noinline optnone {
entry:
  call void @hikari_vmp()
  %a = bitcast i32 %bits to float
  %r = call float @llvm.powi.f32.i32(float %a, i32 %exp)
  %out = bitcast float %r to i32
  ret i32 %out
}

; Fast-math powi is VMP-supported (CallDescriptor FMF mask restored).
define i32 @reference_fast_powi(i32 %bits, i32 %exp) {
entry:
  %a = bitcast i32 %bits to float
  %r = call fast float @llvm.powi.f32.i32(float %a, i32 %exp)
  %out = bitcast float %r to i32
  ret i32 %out
}

define i32 @protected_fast_powi(i32 %bits, i32 %exp) noinline optnone {
entry:
  call void @hikari_vmp()
  %a = bitcast i32 %bits to float
  %r = call fast float @llvm.powi.f32.i32(float %a, i32 %exp)
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
  ; Base 2.0 bits 0x40000000 with exponents 0, 1, 3, -2
  %e0 = call i32 @reference_powi(i32 1073741824, i32 0)
  %a0 = call i32 @protected_powi(i32 1073741824, i32 0)
  %e1 = call i32 @reference_powi(i32 1073741824, i32 1)
  %a1 = call i32 @protected_powi(i32 1073741824, i32 1)
  %e2 = call i32 @reference_powi(i32 1073741824, i32 3)
  %a2 = call i32 @protected_powi(i32 1073741824, i32 3)
  %e3 = call i32 @reference_powi(i32 1073741824, i32 -2)
  %a3 = call i32 @protected_powi(i32 1073741824, i32 -2)
  ; fast powi: base 4.0 exp 2, base 2.0 exp 3 (finite base, i32 exponents)
  %e4 = call i32 @reference_fast_powi(i32 1082130432, i32 2)
  %a4 = call i32 @protected_fast_powi(i32 1082130432, i32 2)
  %e5 = call i32 @reference_fast_powi(i32 1073741824, i32 3)
  %a5 = call i32 @protected_fast_powi(i32 1073741824, i32 3)
  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %e1, %a1
  %m2 = icmp eq i32 %e2, %a2
  %m3 = icmp eq i32 %e3, %a3
  %m4 = icmp eq i32 %e4, %a4
  %m5 = icmp eq i32 %e5, %a5
  %t0 = and i1 %m0, %m1
  %t1 = and i1 %t0, %m2
  %t2 = and i1 %t1, %m3
  %t3 = and i1 %t2, %m4
  %ok = and i1 %t3, %m5
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with: 129
; SKIP-DAG: Skipping VMP on unsupported_constrained_fadd_f32: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_powi:
; SKIP-NOT: Skipping VMP on protected_fast_powi:

; VIRT-LABEL: define i32 @protected_powi(
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.powi.f32.i32(
; VIRT-LABEL: define i32 @protected_fast_powi(
; VIRT: vmp.dispatch:
; VIRT: call fast float @llvm.powi.f32.i32(
; VIRT-LABEL: define i32 @unsupported_constrained_fadd_f32(
; VIRT-NOT: vmp.dispatch
; VIRT: call fastcc float @llvm.experimental.constrained.fadd.f32(float {{.*}}, float {{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")

; VIRT: attributes{{.*}}"hikari.vmp.virtualized"
