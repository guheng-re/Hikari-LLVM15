; Non-fast and fast llvm.canonicalize.f32 are VMP-eligible and planned as
; FMul(x, 1.0) (LangRef-compatible expansion when not constant-folded);
; fast canonicalize carries its exact FMF onto the lowered fmul.
; The constrained-fadd sentinel is rejected with "unsupported call
; instruction" (see unsupported_constrained_fadd_f32).
;
; Full opt IR is FileChecked (SKIP/VIRT), including the dead fast-skip probe that
; still contains llvm.experimental.constrained.fadd.f32 — selectable by
; AArch64/X86, so object
; emission and host lli run directly on the full opt output.
;
; RUN: opt -S -verify-each -aesSeed=103 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.ll -o %t.o0.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=103 -passes='default<O2>' %s -o %t.o2.ll
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.ll -o %t.o2.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare float @llvm.canonicalize.f32(float)
declare float @llvm.experimental.constrained.fadd.f32(float, float, metadata, metadata)

; Reference uses the same LangRef expansion VMP applies (fmul by 1.0).
define i32 @reference_canonicalize(i32 %bits) {
entry:
  %a = bitcast i32 %bits to float
  %r = fmul float %a, 1.000000e+00
  %out = bitcast float %r to i32
  ret i32 %out
}

define i32 @protected_canonicalize(i32 %bits) noinline optnone {
entry:
  call void @hikari_vmp()
  %a = bitcast i32 %bits to float
  %r = call float @llvm.canonicalize.f32(float %a)
  %out = bitcast float %r to i32
  ret i32 %out
}

; Fast-math canonicalize.f32 is VMP-supported: the planner lowers it to
; FMul(x, 1.0) carrying the exact flags in the opcode Variant.
define i32 @reference_fast_canonicalize(i32 %bits) {
entry:
  %a = bitcast i32 %bits to float
  %r = fmul fast float %a, 1.000000e+00
  %out = bitcast float %r to i32
  ret i32 %out
}

define i32 @protected_fast_canonicalize(i32 %bits) noinline optnone {
entry:
  call void @hikari_vmp()
  %a = bitcast i32 %bits to float
  %r = call fast float @llvm.canonicalize.f32(float %a)
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
  ; finite +1.5  bits 0x3fc00000
  %e0 = call i32 @reference_canonicalize(i32 1069547520)
  %a0 = call i32 @protected_canonicalize(i32 1069547520)
  ; +0.0 bits 0
  %e1 = call i32 @reference_canonicalize(i32 0)
  %a1 = call i32 @protected_canonicalize(i32 0)
  ; -0.0 bits 0x80000000
  %e2 = call i32 @reference_canonicalize(i32 -2147483648)
  %a2 = call i32 @protected_canonicalize(i32 -2147483648)
  ; +inf bits 0x7f800000
  %e3 = call i32 @reference_canonicalize(i32 2139095040)
  %a3 = call i32 @protected_canonicalize(i32 2139095040)
  ; quiet NaN with payload 0x7fc01234 = 2143294004
  %e4 = call i32 @reference_canonicalize(i32 2143294004)
  %a4 = call i32 @protected_canonicalize(i32 2143294004)
  ; fast canonicalize: +1.5 and -2.5 (finite inputs, full 'fast' flags)
  %e5 = call i32 @reference_fast_canonicalize(i32 1069547520)
  %a5 = call i32 @protected_fast_canonicalize(i32 1069547520)
  %e6 = call i32 @reference_fast_canonicalize(i32 -1071644672)
  %a6 = call i32 @protected_fast_canonicalize(i32 -1071644672)
  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %e1, %a1
  %m2 = icmp eq i32 %e2, %a2
  %m3 = icmp eq i32 %e3, %a3
  %m4 = icmp eq i32 %e4, %a4
  %m5 = icmp eq i32 %e5, %a5
  %m6 = icmp eq i32 %e6, %a6
  %t0 = and i1 %m0, %m1
  %t1 = and i1 %t0, %m2
  %t2 = and i1 %t1, %m3
  %t3 = and i1 %t2, %m4
  %t4 = and i1 %t3, %m5
  %ok = and i1 %t4, %m6
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with: 103
; SKIP-DAG: Skipping VMP on unsupported_constrained_fadd_f32: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_canonicalize:
; SKIP-NOT: Skipping VMP on protected_fast_canonicalize:

; VIRT-LABEL: define i32 @protected_canonicalize(
; VIRT: vmp.dispatch:
; VIRT-DAG: fmul float
; VIRT-NOT: {{call.*@llvm.canonicalize.f32}}
; VIRT-LABEL: define i32 @protected_fast_canonicalize(
; VIRT: vmp.dispatch:
; VIRT-DAG: fmul fast float
; VIRT-NOT: {{call.*@llvm.canonicalize.f32}}
; VIRT-LABEL: define i32 @unsupported_constrained_fadd_f32(
; VIRT: call fastcc float @llvm.experimental.constrained.fadd.f32(float {{.*}}, float {{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")

; VIRT: attributes{{.*}}"hikari.vmp.virtualized"
