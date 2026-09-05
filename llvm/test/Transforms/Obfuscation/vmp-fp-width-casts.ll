; Scalar f32<->f64 fpext/fptrunc under VMP: numeric width conversions only.
; reference/* run natively, protected/* are virtualized; bitcast-to-integer
; parity proves the interpreter widens/narrows values instead of moving bits:
; float 1.1 (bit pattern 0x3F8CCCDD) widening must not bit-extend to
; 0x000000003F8CCCDD, and double 1.1 truncation must round to the f32 value.
; Negative cases (half, fp128, fast-math, vector) SKIP with no vmp.dispatch.
; O0 carries the detailed VIRT checks; O2 re-checks eligibility/stability.
;
; RUN: opt -S -verify-each -aesSeed=109 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.ll -o %t.o0.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=109 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP-O2 < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT-O2 < %t.o2.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.ll -o %t.o2.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()

; ---- reference: native execution of the same width-cast chains ----

; f32 -> f64 numeric widen; result compared as i64 bits.
define i32 @reference_widen(float %x) {
entry:
  %d = fpext float %x to double
  %b = bitcast double %d to i64
  %lo = trunc i64 %b to i32
  %hi = lshr i64 %b, 32
  %hi32 = trunc i64 %hi to i32
  %mix = xor i32 %lo, %hi32
  ret i32 %mix
}

; f32 -> f64 -> f32 round trip must reproduce the f32 bit pattern.
define i32 @reference_roundtrip(float %x) {
entry:
  %d = fpext float %x to double
  %r = fptrunc double %d to float
  %b = bitcast float %r to i32
  ret i32 %b
}

; f64 -> f32 numeric truncation, then widen back.
define i32 @reference_narrow(double %x) {
entry:
  %f = fptrunc double %x to float
  %d = fpext float %f to double
  %b = bitcast double %d to i64
  %lo = trunc i64 %b to i32
  %hi = lshr i64 %b, 32
  %hi32 = trunc i64 %hi to i32
  %mix = xor i32 %lo, %hi32
  ret i32 %mix
}

; Width cast after a float phi merge (branch/phi).
define i32 @reference_branch(double %x, i1 %c) {
entry:
  br i1 %c, label %t, label %f

t:
  %d1 = fptrunc double %x to float
  br label %join

f:
  %d2 = fptrunc double 2.250000e+00 to float
  br label %join

join:
  %p = phi float [ %d1, %t ], [ %d2, %f ]
  %w = fpext float %p to double
  %b = bitcast double %w to i64
  %lo = trunc i64 %b to i32
  %hi = lshr i64 %b, 32
  %hi32 = trunc i64 %hi to i32
  %mix = xor i32 %lo, %hi32
  ret i32 %mix
}

; ---- protected: the same chains under VMP ----

define i32 @protected_widen(float %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %d = fpext float %x to double
  %b = bitcast double %d to i64
  %lo = trunc i64 %b to i32
  %hi = lshr i64 %b, 32
  %hi32 = trunc i64 %hi to i32
  %mix = xor i32 %lo, %hi32
  ret i32 %mix
}

define i32 @protected_roundtrip(float %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %d = fpext float %x to double
  %r = fptrunc double %d to float
  %b = bitcast float %r to i32
  ret i32 %b
}

define i32 @protected_narrow(double %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %f = fptrunc double %x to float
  %d = fpext float %f to double
  %b = bitcast double %d to i64
  %lo = trunc i64 %b to i32
  %hi = lshr i64 %b, 32
  %hi32 = trunc i64 %hi to i32
  %mix = xor i32 %lo, %hi32
  ret i32 %mix
}

define i32 @protected_branch(double %x, i1 %c) noinline optnone {
entry:
  call void @hikari_vmp()
  br i1 %c, label %t, label %f

t:
  %d1 = fptrunc double %x to float
  br label %join

f:
  %d2 = fptrunc double 2.250000e+00 to float
  br label %join

join:
  %p = phi float [ %d1, %t ], [ %d2, %f ]
  %w = fpext float %p to double
  %b = bitcast double %w to i64
  %lo = trunc i64 %b to i32
  %hi = lshr i64 %b, 32
  %hi32 = trunc i64 %hi to i32
  %mix = xor i32 %lo, %hi32
  ret i32 %mix
}

; ---- negative cases: must SKIP, never virtualize ----

define float @unsupported_half_fptrunc(float %f) noinline optnone {
entry:
  call void @hikari_vmp()
  %h = fptrunc float %f to half
  ret float %f
}

define double @unsupported_fp128_fpext(double %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %q = fpext double %x to ppc_fp128
  ret double %x
}

; LLVM 15's parser rejects fast-math keywords on fpext/fptrunc (a LLVM 16+
; syntax), so a textual FMF width cast cannot exist here; this chain keeps an
; unsupported step via a half-width truncation (rejected at the cast gate).
define float @unsupported_fmf_fptrunc(float %a, i1 %c) noinline optnone {
entry:
  call void @hikari_vmp()
  %h = fptrunc float %a to half
  %f = fpext half %h to float
  ret float %f
}

define i32 @unsupported_vec_fpext(<2 x float> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %d = fpext <2 x float> %v to <2 x double>
  %b = bitcast <2 x double> %d to i128
  %lo = trunc i128 %b to i32
  ret i32 %lo
}

; ---- main: parity checks ----

define i32 @main() {
entry:
  ; float 1.1 (bit pattern 0x3F8CCCDD) written as its exact double pattern
  ; 0x3FF4CCCD00000000 (decimal 1.100000e+00 rounds and is not a legal IR
  ; float constant); double 1.1 is 0x3FF199999999999A.
  %e0 = call i32 @reference_widen(float 0x3FF4CCCD00000000)
  %a0 = call i32 @protected_widen(float 0x3FF4CCCD00000000)
  %e1 = call i32 @reference_roundtrip(float 0x3FF4CCCD00000000)
  %a1 = call i32 @protected_roundtrip(float 0x3FF4CCCD00000000)
  %e2 = call i32 @reference_narrow(double 0x3FF199999999999A)
  %a2 = call i32 @protected_narrow(double 0x3FF199999999999A)
  %e3 = call i32 @reference_branch(double 0x3FF199999999999A, i1 true)
  %a3 = call i32 @protected_branch(double 0x3FF199999999999A, i1 true)
  %e4 = call i32 @reference_branch(double 0x3FF199999999999A, i1 false)
  %a4 = call i32 @protected_branch(double 0x3FF199999999999A, i1 false)
  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %e1, %a1
  %m2 = icmp eq i32 %e2, %a2
  %m3 = icmp eq i32 %e3, %a3
  %m4 = icmp eq i32 %e4, %a4
  %ok0 = and i1 %m0, %m1
  %ok1 = and i1 %m2, %m3
  %ok2 = and i1 %ok0, %ok1
  %ok = and i1 %ok2, %m4
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; ---- O0 checks ----

; SKIP-DAG: Skipping VMP on unsupported_half_fptrunc: unsupported cast instruction
; SKIP-DAG: Skipping VMP on unsupported_fp128_fpext: unsupported cast instruction
; SKIP-DAG: Skipping VMP on unsupported_fmf_fptrunc: unsupported cast instruction
; SKIP-DAG: Skipping VMP on unsupported_vec_fpext: unsupported argument type
; SKIP-NOT: Skipping VMP on protected:

; VIRT-LABEL: define i32 @protected_widen(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: fpext float {{.*}} to double
; VIRT-DAG: bitcast double {{.*}} to i64
; VIRT-LABEL: define i32 @protected_roundtrip(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: fpext float {{.*}} to double
; VIRT-DAG: fptrunc double {{.*}} to float
; VIRT-DAG: bitcast float {{.*}} to i32
; VIRT-LABEL: define i32 @protected_narrow(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: fptrunc double {{.*}} to float
; VIRT-DAG: fpext float {{.*}} to double
; VIRT-LABEL: define i32 @protected_branch(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: fptrunc double
; VIRT-DAG: fpext float {{.*}} to double
; Residual SSA float PHI gone (FloatMove edge copies); bound to next LABEL.
; VIRT-NOT: phi float

; Negative cases stay native: no dispatch, no virtualized attribute.
; VIRT-LABEL: define float @unsupported_half_fptrunc(
; VIRT-NOT: vmp.dispatch
; VIRT: fptrunc float {{.*}} to half
; VIRT-LABEL: define double @unsupported_fp128_fpext(
; VIRT-NOT: vmp.dispatch
; VIRT: fpext double {{.*}} to ppc_fp128
; VIRT-LABEL: define float @unsupported_fmf_fptrunc(
; VIRT-NOT: vmp.dispatch
; VIRT: fptrunc float {{.*}} to half
; VIRT-LABEL: define i32 @unsupported_vec_fpext(
; VIRT-NOT: vmp.dispatch
; VIRT: fpext <2 x float>

; VIRT: attributes{{.*}}"hikari.vmp.virtualized"{{.*}}

; ---- O2 checks ----

; SKIP-O2-DAG: Skipping VMP on unsupported_half_fptrunc: unsupported cast instruction
; SKIP-O2-DAG: Skipping VMP on unsupported_fp128_fpext: unsupported cast instruction
; SKIP-O2-DAG: Skipping VMP on unsupported_fmf_fptrunc: unsupported cast instruction
; SKIP-O2-DAG: Skipping VMP on unsupported_vec_fpext: unsupported argument type
; SKIP-O2-NOT: Skipping VMP on protected:

; VIRT-O2-LABEL: define i32 @protected_widen(
; VIRT-O2: %vmp.fregs = alloca
; VIRT-O2: vmp.dispatch:
; VIRT-O2: fpext float {{.*}} to double
; VIRT-O2: fptrunc double {{.*}} to float
; VIRT-O2: attributes{{.*}}"hikari.vmp.virtualized"{{.*}}
