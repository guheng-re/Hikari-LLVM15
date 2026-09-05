; Scalar llvm.fabs.f32 via normal Call path (float VReg frame).
; Fast-math fabs.f32 is VMP-supported (CallDescriptor FMF mask restored):
; reference_fast_fabs runs natively, protected_fast_fabs is virtualized; main
; compares their i32 bit patterns on finite inputs (full 'fast' flags).
; The constrained-fadd sentinel is rejected by the intrinsic whitelist
; (rounding/exception metadata, not FMF); AArch64/X86 select it, so the
; object step needs no DCE.
;
; RUN: opt -S -verify-each -aesSeed=61 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.ll -o %t.o0.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=61 -passes='default<O2>' %s -o %t.o2.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.ll -o %t.o2.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare float @llvm.fabs.f32(float)
declare float @llvm.experimental.constrained.fadd.f32(float, float, metadata, metadata)

; Bit-pattern i32 input: bitcast to float, fabs, bitcast result back to i32.
define i32 @reference_fabs(i32 %bits) {
entry:
  %a = bitcast i32 %bits to float
  %r = call float @llvm.fabs.f32(float %a)
  %out = bitcast float %r to i32
  ret i32 %out
}

define i32 @protected_fabs(i32 %bits) noinline optnone {
entry:
  call void @hikari_vmp()
  %a = bitcast i32 %bits to float
  %r = call float @llvm.fabs.f32(float %a)
  %out = bitcast float %r to i32
  ret i32 %out
}

; Fast-math fabs.f32 is VMP-supported (CallDescriptor FMF mask restored).
define i32 @reference_fast_fabs(i32 %bits) {
entry:
  %a = bitcast i32 %bits to float
  %r = call fast float @llvm.fabs.f32(float %a)
  %out = bitcast float %r to i32
  ret i32 %out
}

define i32 @protected_fast_fabs(i32 %bits) noinline optnone {
entry:
  call void @hikari_vmp()
  %a = bitcast i32 %bits to float
  %r = call fast float @llvm.fabs.f32(float %a)
  %out = bitcast float %r to i32
  ret i32 %out
}

; llvm.experimental.constrained.fadd.f32 uses non-C fastcc so the now-
; supported C constrained-fadd surface stays a skip ("unsupported call
; instruction").
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
  ; +1.0  bits 0x3f800000
  %e0 = call i32 @reference_fabs(i32 1065353216)
  %a0 = call i32 @protected_fabs(i32 1065353216)
  ; -1.0  bits 0xbf800000
  %e1 = call i32 @reference_fabs(i32 -1082130432)
  %a1 = call i32 @protected_fabs(i32 -1082130432)
  ; -0.0  bits 0x80000000
  %e2 = call i32 @reference_fabs(i32 -2147483648)
  %a2 = call i32 @protected_fabs(i32 -2147483648)
  ; -inf  bits 0xff800000
  %e3 = call i32 @reference_fabs(i32 -8388608)
  %a3 = call i32 @protected_fabs(i32 -8388608)
  ; fast fabs: +1.0 and -2.0 (finite inputs, full 'fast' flags)
  %e4 = call i32 @reference_fast_fabs(i32 1065353216)
  %a4 = call i32 @protected_fast_fabs(i32 1065353216)
  %e5 = call i32 @reference_fast_fabs(i32 -1073741824)
  %a5 = call i32 @protected_fast_fabs(i32 -1073741824)
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

; SKIP: seeded with: 61
; SKIP-DAG: Skipping VMP on unsupported_constrained_fadd_f32: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_fabs:
; SKIP-NOT: Skipping VMP on protected_fast_fabs:

; VIRT-LABEL: define i32 @protected_fabs(
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.fabs.f32(
; VIRT-LABEL: define i32 @protected_fast_fabs(
; VIRT: vmp.dispatch:
; VIRT: call fast float @llvm.fabs.f32(
; VIRT-LABEL: define i32 @unsupported_constrained_fadd_f32(
; VIRT-NOT: vmp.dispatch
; VIRT: call fastcc float @llvm.experimental.constrained.fadd.f32(float {{.*}}, float {{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")

; VIRT: attributes{{.*}}"hikari.vmp.virtualized"
