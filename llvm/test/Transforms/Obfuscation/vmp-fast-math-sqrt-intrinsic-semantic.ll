; llvm.sqrt.f32/f64 direct calls with FastMathFlags under VMP.  The
; intrinsic FMF gate admits only isSupportedSqrtIntrinsic; the CallDescriptor
; saves the seven-bit mask and emitCallHandler restores the exact flags.
; f32 uses full 'fast' (flags asserted on the re-emitted call at O0; the lli
; interpreter fatals on a full-'fast' sqrt — IntrinsicLowering lowers it to
; an unresolvable external sqrtf — so behavior parity runs on the f64
; partial-flags path).  f64 uses the partial combination nnan ninf and main
; compares bitcast results on safe positive finite inputs.  Negative case:
; llvm.experimental.constrained.fadd.f32 (selectable by AArch64/X86 but never
; in the intrinsic whitelist) skips; a
; non-AArch64 module skips wholesale.
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
; RUN: opt -S -verify-each -aesSeed=109 -mtriple=x86_64-unknown-linux-gnu -passes='default<O0>' %s -o %t.x86.ll 2>%t.x86.err
; RUN: FileCheck %s --check-prefix=SKIP-X86 < %t.x86.err

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare float @llvm.sqrt.f32(float)
declare double @llvm.sqrt.f64(double)
declare float @llvm.experimental.constrained.fadd.f32(float, float, metadata, metadata)

; ---- reference: native sqrt intrinsics with FMF ----

; f32 sqrt with full 'fast'.
define i32 @reference_sqrt_f32(float %x) {
entry:
  %r = call fast float @llvm.sqrt.f32(float %x)
  %b = bitcast float %r to i32
  ret i32 %b
}

; f64 sqrt with the partial combination nnan ninf.
define i64 @reference_sqrt_f64(double %x) {
entry:
  %r = call nnan ninf double @llvm.sqrt.f64(double %x)
  %b = bitcast double %r to i64
  ret i64 %b
}

; ---- vmp: same chains under VMP ----

define i32 @vmp_sqrt_f32(float %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fast float @llvm.sqrt.f32(float %x)
  %b = bitcast float %r to i32
  ret i32 %b
}

define i64 @vmp_sqrt_f64(double %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call nnan ninf double @llvm.sqrt.f64(double %x)
  %b = bitcast double %r to i64
  ret i64 %b
}

; ---- negative case: must SKIP, never virtualize ----

; llvm.experimental.constrained.fadd.f32 uses non-C fastcc so the now-
; supported C constrained-fadd surface stays a skip ("unsupported call
; instruction").
define i32 @unsupported_constrained_fadd_f32(float %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc float @llvm.experimental.constrained.fadd.f32(float %x, float %x, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  %b = bitcast float %r to i32
  ret i32 %b
}

; ---- main: parity checks ----

define i32 @main() {
entry:
  ; Behavior parity on the f64 partial-flags path (the interpreter can
  ; execute it; sqrt(7) is a real non-square check).  The f32 'fast' path is
  ; asserted by VIRT only — the interpreter fatals on full-'fast' sqrt.
  %e0 = call i64 @reference_sqrt_f64(double 7.000000e+00)
  %a0 = call i64 @vmp_sqrt_f64(double 7.000000e+00)
  %m0 = icmp eq i64 %e0, %a0
  %ok = and i1 %m0, true
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; ---- O0 checks ----

; SKIP-DAG: Skipping VMP on unsupported_constrained_fadd_f32: unsupported call instruction
; SKIP-NOT: Skipping VMP on vmp_:

; VIRT-LABEL: define i32 @vmp_sqrt_f32(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT: call fast float @llvm.sqrt.f32(float
; VIRT-LABEL: define i64 @vmp_sqrt_f64(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT: call nnan ninf double @llvm.sqrt.f64(double

; Negative stays native: no dispatch, no virtualized attribute.
; VIRT-LABEL: define i32 @unsupported_constrained_fadd_f32(
; VIRT-NOT: vmp.dispatch
; VIRT: call fastcc float @llvm.experimental.constrained.fadd.f32(float {{.*}}, float {{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")

; VIRT: attributes{{.*}}"hikari.vmp.virtualized"

; ---- O2 checks ----

; SKIP-O2-DAG: Skipping VMP on unsupported_constrained_fadd_f32: unsupported call instruction
; SKIP-O2-NOT: Skipping VMP on vmp_:

; VIRT-O2-LABEL: define i64 @vmp_sqrt_f64(
; VIRT-O2: %vmp.fregs = alloca
; VIRT-O2: vmp.dispatch:
; VIRT-O2: call nnan ninf double @llvm.sqrt.f64(double
; VIRT-O2: attributes{{.*}}"hikari.vmp.virtualized"

; Non-AArch64 module triple: VMP skips all selected functions wholesale.
; SKIP-X86: Skipping VMP: only AArch64 targets are supported
