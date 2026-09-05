; Scalar llvm.copysign.f32 via normal Call path (float VReg frame).
; Fast-math copysign.f32 is VMP-supported (CallDescriptor FMF mask restored):
; reference_fast_copysign runs natively, protected_fast_copysign is
; virtualized; main compares their i32 bit patterns on finite non-NaN inputs
; (full 'fast' flags).  The constrained-fadd sentinel is rejected by the
; intrinsic whitelist (rounding/exception metadata, not FMF).
;
; RUN: opt -S -verify-each -aesSeed=63 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.ll -o %t.o0.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=63 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP-O2 < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT-O2 < %t.o2.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.ll -o %t.o2.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare float @llvm.copysign.f32(float, float)
declare float @llvm.experimental.constrained.fadd.f32(float, float, metadata, metadata)

; Bit-pattern i32 inputs: bitcast to float, copysign, bitcast result back to i32.
define i32 @reference_copysign(i32 %magnitude_bits, i32 %sign_bits) {
entry:
  %mag = bitcast i32 %magnitude_bits to float
  %sgn = bitcast i32 %sign_bits to float
  %r = call float @llvm.copysign.f32(float %mag, float %sgn)
  %out = bitcast float %r to i32
  ret i32 %out
}

define i32 @protected_copysign(i32 %magnitude_bits, i32 %sign_bits) noinline optnone {
entry:
  call void @hikari_vmp()
  %mag = bitcast i32 %magnitude_bits to float
  %sgn = bitcast i32 %sign_bits to float
  %r = call float @llvm.copysign.f32(float %mag, float %sgn)
  %out = bitcast float %r to i32
  ret i32 %out
}

; Fast-math copysign.f32 is VMP-supported (CallDescriptor FMF mask restored).
define i32 @reference_fast_copysign(i32 %magnitude_bits, i32 %sign_bits) {
entry:
  %mag = bitcast i32 %magnitude_bits to float
  %sgn = bitcast i32 %sign_bits to float
  %r = call fast float @llvm.copysign.f32(float %mag, float %sgn)
  %out = bitcast float %r to i32
  ret i32 %out
}

define i32 @protected_fast_copysign(i32 %magnitude_bits, i32 %sign_bits) noinline optnone {
entry:
  call void @hikari_vmp()
  %mag = bitcast i32 %magnitude_bits to float
  %sgn = bitcast i32 %sign_bits to float
  %r = call fast float @llvm.copysign.f32(float %mag, float %sgn)
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
  ; +1.5 with -0 sign: 0x3fc00000, 0x80000000
  %e0 = call i32 @reference_copysign(i32 1069547520, i32 -2147483648)
  %a0 = call i32 @protected_copysign(i32 1069547520, i32 -2147483648)
  ; -2.0 with +0 sign: 0xc0000000, 0
  %e1 = call i32 @reference_copysign(i32 -1073741824, i32 0)
  %a1 = call i32 @protected_copysign(i32 -1073741824, i32 0)
  ; +0 magnitude with -1 sign: 0, 0xbf800000
  %e2 = call i32 @reference_copysign(i32 0, i32 -1082130432)
  %a2 = call i32 @protected_copysign(i32 0, i32 -1082130432)
  ; quiet NaN magnitude 0x7fc01234 with -1 sign: 2143294004, -1082130432
  %e3 = call i32 @reference_copysign(i32 2143294004, i32 -1082130432)
  %a3 = call i32 @protected_copysign(i32 2143294004, i32 -1082130432)
  ; fast copysign: +1.5 with -0 sign, and -2.5 with +1 sign (finite inputs)
  %e4 = call i32 @reference_fast_copysign(i32 1069547520, i32 -2147483648)
  %a4 = call i32 @protected_fast_copysign(i32 1069547520, i32 -2147483648)
  %e5 = call i32 @reference_fast_copysign(i32 -1071644672, i32 1065353216)
  %a5 = call i32 @protected_fast_copysign(i32 -1071644672, i32 1065353216)
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

; SKIP: seeded with: 63
; SKIP-DAG: Skipping VMP on unsupported_constrained_fadd_f32: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_copysign:
; SKIP-NOT: Skipping VMP on protected_fast_copysign:

; VIRT-LABEL: define i32 @protected_copysign(
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.copysign.f32(
; VIRT-LABEL: define i32 @protected_fast_copysign(
; VIRT: vmp.dispatch:
; VIRT: call fast float @llvm.copysign.f32(
; VIRT-LABEL: define i32 @unsupported_constrained_fadd_f32(
; VIRT-NOT: vmp.dispatch
; VIRT: call fastcc float @llvm.experimental.constrained.fadd.f32(float {{.*}}, float {{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")

; VIRT: attributes{{.*}}"hikari.vmp.virtualized"

; ---- O2 checks ----

; SKIP-O2-DAG: Skipping VMP on unsupported_constrained_fadd_f32: unsupported call instruction
; SKIP-O2-NOT: Skipping VMP on protected_copysign:
; SKIP-O2-NOT: Skipping VMP on protected_fast_copysign:

; VIRT-O2-LABEL: define i32 @protected_copysign(
; VIRT-O2: vmp.dispatch:
; VIRT-O2: call float @llvm.copysign.f32(
; VIRT-O2-LABEL: define i32 @protected_fast_copysign(
; VIRT-O2: vmp.dispatch:
; VIRT-O2: call fast float @llvm.copysign.f32(
; VIRT-O2-LABEL: define i32 @unsupported_constrained_fadd_f32(
; VIRT-O2-NOT: vmp.dispatch
; VIRT-O2: call fastcc float @llvm.experimental.constrained.fadd.f32(float {{.*}}, float {{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")
; VIRT-O2: attributes{{.*}}"hikari.vmp.virtualized"
