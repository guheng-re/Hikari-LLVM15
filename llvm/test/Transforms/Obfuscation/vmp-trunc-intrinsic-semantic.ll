; Scalar llvm.trunc.f32 via normal Call path (float VReg frame).
; Fast-math trunc.f32 is VMP-supported (CallDescriptor FMF mask restored):
; reference_fast_trunc runs natively, protected_fast_trunc is virtualized;
; main compares their i32 bit patterns on finite positive/negative
; non-integer inputs (full 'fast' flags).  The constrained-fadd sentinel
; is rejected by the intrinsic whitelist (rounding/exception metadata, not
; FMF); AArch64/X86 select it, so the object step needs no DCE.
;
; RUN: opt -S -verify-each -aesSeed=79 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.ll -o %t.o0.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=79 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP-O2 < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT-O2 < %t.o2.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.ll -o %t.o2.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare float @llvm.trunc.f32(float)
declare float @llvm.experimental.constrained.fadd.f32(float, float, metadata, metadata)

; Bit-pattern i32 input: bitcast to float, trunc, bitcast result back to i32.
define i32 @reference_trunc(i32 %bits) {
entry:
  %a = bitcast i32 %bits to float
  %r = call float @llvm.trunc.f32(float %a)
  %out = bitcast float %r to i32
  ret i32 %out
}

define i32 @protected_trunc(i32 %bits) noinline optnone {
entry:
  call void @hikari_vmp()
  %a = bitcast i32 %bits to float
  %r = call float @llvm.trunc.f32(float %a)
  %out = bitcast float %r to i32
  ret i32 %out
}

; Fast-math trunc.f32 is VMP-supported (CallDescriptor FMF mask restored).
define i32 @reference_fast_trunc(i32 %bits) {
entry:
  %a = bitcast i32 %bits to float
  %r = call fast float @llvm.trunc.f32(float %a)
  %out = bitcast float %r to i32
  ret i32 %out
}

define i32 @protected_fast_trunc(i32 %bits) noinline optnone {
entry:
  call void @hikari_vmp()
  %a = bitcast i32 %bits to float
  %r = call fast float @llvm.trunc.f32(float %a)
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
  ; +1.5  bits 0x3fc00000 -> trunc -> +1.0
  %e0 = call i32 @reference_trunc(i32 1069547520)
  %a0 = call i32 @protected_trunc(i32 1069547520)
  ; -1.5  bits 0xbfc00000 -> trunc -> -1.0
  %e1 = call i32 @reference_trunc(i32 -1077936128)
  %a1 = call i32 @protected_trunc(i32 -1077936128)
  ; +0.0 bits 0
  %e2 = call i32 @reference_trunc(i32 0)
  %a2 = call i32 @protected_trunc(i32 0)
  ; -0.0 bits 0x80000000
  %e3 = call i32 @reference_trunc(i32 -2147483648)
  %a3 = call i32 @protected_trunc(i32 -2147483648)
  ; +inf bits 0x7f800000
  %e4 = call i32 @reference_trunc(i32 2139095040)
  %a4 = call i32 @protected_trunc(i32 2139095040)
  ; fast trunc: +1.5 and -2.5, then +2.5 and -3.5 (finite non-integer inputs)
  %e5 = call i32 @reference_fast_trunc(i32 1069547520)
  %a5 = call i32 @protected_fast_trunc(i32 1069547520)
  %e6 = call i32 @reference_fast_trunc(i32 -1071644672)
  %a6 = call i32 @protected_fast_trunc(i32 -1071644672)
  %e7 = call i32 @reference_fast_trunc(i32 1075838976)
  %a7 = call i32 @protected_fast_trunc(i32 1075838976)
  %e8 = call i32 @reference_fast_trunc(i32 -1070596096)
  %a8 = call i32 @protected_fast_trunc(i32 -1070596096)
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

; SKIP: seeded with: 79
; SKIP-DAG: Skipping VMP on unsupported_constrained_fadd_f32: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_trunc:
; SKIP-NOT: Skipping VMP on protected_fast_trunc:

; VIRT-LABEL: define i32 @protected_trunc(
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.trunc.f32(
; VIRT-LABEL: define i32 @protected_fast_trunc(
; VIRT: vmp.dispatch:
; VIRT: call fast float @llvm.trunc.f32(
; VIRT-LABEL: define i32 @unsupported_constrained_fadd_f32(
; VIRT-NOT: vmp.dispatch
; VIRT: call fastcc float @llvm.experimental.constrained.fadd.f32(float {{.*}}, float {{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")

; VIRT: attributes{{.*}}"hikari.vmp.virtualized"

; ---- O2 checks ----

; SKIP-O2-DAG: Skipping VMP on unsupported_constrained_fadd_f32: unsupported call instruction
; SKIP-O2-NOT: Skipping VMP on protected_trunc:
; SKIP-O2-NOT: Skipping VMP on protected_fast_trunc:

; VIRT-O2-LABEL: define i32 @protected_trunc(
; VIRT-O2: vmp.dispatch:
; VIRT-O2: call float @llvm.trunc.f32(
; VIRT-O2-LABEL: define i32 @protected_fast_trunc(
; VIRT-O2: vmp.dispatch:
; VIRT-O2: call fast float @llvm.trunc.f32(
; VIRT-O2-LABEL: define i32 @unsupported_constrained_fadd_f32(
; VIRT-O2-NOT: vmp.dispatch
; VIRT-O2: call fastcc float @llvm.experimental.constrained.fadd.f32(float {{.*}}, float {{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")
; VIRT-O2: attributes{{.*}}"hikari.vmp.virtualized"
