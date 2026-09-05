; Feasibility probe: well-shaped C llvm.experimental.constrained.fadd is
; now a supported VMP surface.  These sentinels keep the same scalar
; types but use non-C fastcc so they remain a stable skip
; ("unsupported call instruction") while staying selectable by
; AArch64/x86 codegen.
;
; RUN: opt -S -verify-each -aesSeed=137 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.ll -o %t.o0.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=137 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.ll -o %t.o2.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare float @llvm.experimental.constrained.fadd.f32(float, float, metadata, metadata)
declare double @llvm.experimental.constrained.fadd.f64(double, double, metadata, metadata)

define float @unsupported_constrained_fadd_f32(float %a, float %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc float @llvm.experimental.constrained.fadd.f32(float %a, float %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret float %r
}

define double @unsupported_constrained_fadd_f64(double %a, double %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc double @llvm.experimental.constrained.fadd.f64(double %a, double %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret double %r
}

define i32 @main() {
entry:
  ret i32 0
}

; SKIP-DAG: Skipping VMP on unsupported_constrained_fadd_f32: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_constrained_fadd_f64: unsupported call instruction

; VIRT-LABEL: define float @unsupported_constrained_fadd_f32(
; VIRT-NOT: vmp.dispatch
; VIRT: call fastcc float @llvm.experimental.constrained.fadd.f32(
; VIRT-LABEL: define double @unsupported_constrained_fadd_f64(
; VIRT-NOT: vmp.dispatch
; VIRT: call fastcc double @llvm.experimental.constrained.fadd.f64(
; VIRT-NOT: "hikari.vmp.virtualized"
