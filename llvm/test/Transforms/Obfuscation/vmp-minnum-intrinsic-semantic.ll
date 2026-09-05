; Scalar llvm.minnum.f32 / llvm.maxnum.f32 via normal Call path (float VReg).
; Fast-math minnum/maxnum.f32 is VMP-supported (CallDescriptor FMF mask
; restored): reference_fast_minmax runs natively, protected_fast_minmax is
; virtualized; main compares their i32 bit patterns on finite inputs (full
; 'fast' flags).  The constrained-fadd sentinel is rejected by the
; intrinsic whitelist (rounding/exception metadata, not FMF).
;
; RUN: opt -S -verify-each -aesSeed=67 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.ll -o %t.o0.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=67 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP-O2 < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT-O2 < %t.o2.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.ll -o %t.o2.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare float @llvm.minnum.f32(float, float)
declare float @llvm.maxnum.f32(float, float)
declare float @llvm.experimental.constrained.fadd.f32(float, float, metadata, metadata)

; Bit-pattern i32 inputs: bitcast to float, minnum+maxnum, xor bitcasts of results.
define i32 @reference_minmax(i32 %a_bits, i32 %b_bits) {
entry:
  %a = bitcast i32 %a_bits to float
  %b = bitcast i32 %b_bits to float
  %mn = call float @llvm.minnum.f32(float %a, float %b)
  %mx = call float @llvm.maxnum.f32(float %a, float %b)
  %mn.i = bitcast float %mn to i32
  %mx.i = bitcast float %mx to i32
  %mix = xor i32 %mn.i, %mx.i
  ret i32 %mix
}

define i32 @protected_minmax(i32 %a_bits, i32 %b_bits) noinline optnone {
entry:
  call void @hikari_vmp()
  %a = bitcast i32 %a_bits to float
  %b = bitcast i32 %b_bits to float
  %mn = call float @llvm.minnum.f32(float %a, float %b)
  %mx = call float @llvm.maxnum.f32(float %a, float %b)
  %mn.i = bitcast float %mn to i32
  %mx.i = bitcast float %mx to i32
  %mix = xor i32 %mn.i, %mx.i
  ret i32 %mix
}

; Fast-math minnum/maxnum.f32 is VMP-supported (CallDescriptor FMF mask
; restored): same minnum+maxnum xor-mix under full 'fast' flags.
define i32 @reference_fast_minmax(i32 %a_bits, i32 %b_bits) {
entry:
  %a = bitcast i32 %a_bits to float
  %b = bitcast i32 %b_bits to float
  %mn = call fast float @llvm.minnum.f32(float %a, float %b)
  %mx = call fast float @llvm.maxnum.f32(float %a, float %b)
  %mn.i = bitcast float %mn to i32
  %mx.i = bitcast float %mx to i32
  %mix = xor i32 %mn.i, %mx.i
  ret i32 %mix
}

define i32 @protected_fast_minmax(i32 %a_bits, i32 %b_bits) noinline optnone {
entry:
  call void @hikari_vmp()
  %a = bitcast i32 %a_bits to float
  %b = bitcast i32 %b_bits to float
  %mn = call fast float @llvm.minnum.f32(float %a, float %b)
  %mx = call fast float @llvm.maxnum.f32(float %a, float %b)
  %mn.i = bitcast float %mn to i32
  %mx.i = bitcast float %mx to i32
  %mix = xor i32 %mn.i, %mx.i
  ret i32 %mix
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
  ; finite: 1.0 and -2.0
  %e0 = call i32 @reference_minmax(i32 1065353216, i32 -1073741824)
  %a0 = call i32 @protected_minmax(i32 1065353216, i32 -1073741824)
  ; one quiet NaN (0x7fc01234) and 1.0
  %e1 = call i32 @reference_minmax(i32 2143294004, i32 1065353216)
  %a1 = call i32 @protected_minmax(i32 2143294004, i32 1065353216)
  ; both quiet NaN with differing payloads: 0x7fc01234 and 0x7fc02434
  %e2 = call i32 @reference_minmax(i32 2143294004, i32 2143298676)
  %a2 = call i32 @protected_minmax(i32 2143294004, i32 2143298676)
  ; +0 and -0
  %e3 = call i32 @reference_minmax(i32 0, i32 -2147483648)
  %a3 = call i32 @protected_minmax(i32 0, i32 -2147483648)
  ; fast minmax: 1.0/-2.0 and 3.0/1.5 (finite inputs, full 'fast' flags)
  %e4 = call i32 @reference_fast_minmax(i32 1065353216, i32 -1073741824)
  %a4 = call i32 @protected_fast_minmax(i32 1065353216, i32 -1073741824)
  %e5 = call i32 @reference_fast_minmax(i32 1077936128, i32 1069547520)
  %a5 = call i32 @protected_fast_minmax(i32 1077936128, i32 1069547520)
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

; SKIP: seeded with: 67
; SKIP-DAG: Skipping VMP on unsupported_constrained_fadd_f32: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_minmax:
; SKIP-NOT: Skipping VMP on protected_fast_minmax:

; VIRT-LABEL: define i32 @protected_minmax(
; VIRT: vmp.dispatch:
; VIRT-DAG: call float @llvm.minnum.f32(
; VIRT-DAG: call float @llvm.maxnum.f32(
; VIRT-LABEL: define i32 @protected_fast_minmax(
; VIRT: vmp.dispatch:
; VIRT-DAG: call fast float @llvm.minnum.f32(
; VIRT-DAG: call fast float @llvm.maxnum.f32(
; VIRT-LABEL: define i32 @unsupported_constrained_fadd_f32(
; VIRT-NOT: vmp.dispatch
; VIRT: call fastcc float @llvm.experimental.constrained.fadd.f32(float {{.*}}, float {{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")

; VIRT: attributes{{.*}}"hikari.vmp.virtualized"

; ---- O2 checks ----

; SKIP-O2-DAG: Skipping VMP on unsupported_constrained_fadd_f32: unsupported call instruction
; SKIP-O2-NOT: Skipping VMP on protected_minmax:
; SKIP-O2-NOT: Skipping VMP on protected_fast_minmax:

; VIRT-O2-LABEL: define i32 @protected_minmax(
; VIRT-O2: vmp.dispatch:
; VIRT-O2-DAG: call float @llvm.minnum.f32(
; VIRT-O2-DAG: call float @llvm.maxnum.f32(
; VIRT-O2-LABEL: define i32 @protected_fast_minmax(
; VIRT-O2: vmp.dispatch:
; VIRT-O2-DAG: call fast float @llvm.minnum.f32(
; VIRT-O2-DAG: call fast float @llvm.maxnum.f32(
; VIRT-O2-LABEL: define i32 @unsupported_constrained_fadd_f32(
; VIRT-O2-NOT: vmp.dispatch
; VIRT-O2: call fastcc float @llvm.experimental.constrained.fadd.f32(float {{.*}}, float {{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")
; VIRT-O2: attributes{{.*}}"hikari.vmp.virtualized"
