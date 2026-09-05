; AArch64-only llvm.aarch64.crc32* / clrex / hint / cls / sdiv / udiv /
; frint32z/64z/32x/64x.f32 via normal Call path.
; Dual-i32 CRC forms: i32 result + two i32 VReg args.  crc32x/cx: i32 result,
; i32 then i64 VReg args.  clrex: void / zero args.  hint: void / single i32
; ConstantInt imm 0..127 kept as CallDescriptor immediate (never VReg).
; No dedicated VM opcode.  CRC requires explicit function "target-features"
; enabling +crc (last +crc/-crc token wins); frint32z/64z/32x/64x.f32 require
; exact +fptoint (last +fptoint/-fptoint wins).  clrex/hint/cls/sdiv/udiv have no feature gate.
; Missing/disabled +crc reports "unsupported target feature".  Dynamic/OOR
; hint reports "unsupported hint".  Ordinary tail accepted and replayed
; as non-tail (C, exact FTy, formal type equality) on every ID in this family.
; Command-line -mattr is never used for eligibility or object gen.
;
; Host x86_64 cannot select these AArch64 intrinsics.  Do not rewrite them for
; host and do not strip functions.  Validate with FileCheck + AArch64 object
; generation on the live main-reachable subset (internalize + globaldce).
;
; RUN: opt -S -verify-each -aesSeed=202 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.ll -o %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: opt -S -verify-each -aesSeed=202 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.ll -o %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare i32 @llvm.aarch64.crc32w(i32, i32)
declare i32 @llvm.aarch64.crc32b(i32, i32)
declare i32 @llvm.aarch64.crc32h(i32, i32)
declare i32 @llvm.aarch64.crc32cb(i32, i32)
declare i32 @llvm.aarch64.crc32cw(i32, i32)
declare i32 @llvm.aarch64.crc32ch(i32, i32)
declare i32 @llvm.aarch64.crc32x(i32, i64)
declare i32 @llvm.aarch64.crc32cx(i32, i64)
declare void @llvm.aarch64.clrex()
declare void @llvm.aarch64.hint(i32)
declare i32 @llvm.aarch64.cls(i32)
declare i32 @llvm.aarch64.cls64(i64)
declare i32 @llvm.aarch64.sdiv.i32(i32, i32)
declare i64 @llvm.aarch64.sdiv.i64(i64, i64)
declare i32 @llvm.aarch64.udiv.i32(i32, i32)
declare i64 @llvm.aarch64.udiv.i64(i64, i64)
declare float @llvm.aarch64.frint32z.f32(float)
declare double @llvm.aarch64.frint32z.f64(double)
declare float @llvm.aarch64.frint64z.f32(float)
declare double @llvm.aarch64.frint64z.f64(double)
declare float @llvm.aarch64.frint32x.f32(float)
declare double @llvm.aarch64.frint32x.f64(double)
declare float @llvm.aarch64.frint64x.f32(float)
declare double @llvm.aarch64.frint64x.f64(double)

; Explicit +crc on the function attribute (not inferred from llc -mattr).
define i32 @reference_crc32w(i32 %a, i32 %b) "target-features"="+crc" {
entry:
  %r = call i32 @llvm.aarch64.crc32w(i32 %a, i32 %b)
  ret i32 %r
}

define i32 @protected_crc32w(i32 %a, i32 %b) noinline optnone "target-features"="+crc" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.crc32w(i32 %a, i32 %b)
  ret i32 %r
}

; Multi-feature list still enables CRC when the last exact +crc token wins.
define i32 @protected_crc32w_multi(i32 %a, i32 %b) noinline optnone "target-features"="+neon,+crc,+fp-armv8" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.crc32w(i32 %a, i32 %b)
  ret i32 %r
}

define i32 @reference_crc32b(i32 %a, i32 %b) "target-features"="+crc" {
entry:
  %r = call i32 @llvm.aarch64.crc32b(i32 %a, i32 %b)
  ret i32 %r
}

define i32 @protected_crc32b(i32 %a, i32 %b) noinline optnone "target-features"="+crc" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.crc32b(i32 %a, i32 %b)
  ret i32 %r
}

define i32 @reference_crc32h(i32 %a, i32 %b) "target-features"="+crc" {
entry:
  %r = call i32 @llvm.aarch64.crc32h(i32 %a, i32 %b)
  ret i32 %r
}

define i32 @protected_crc32h(i32 %a, i32 %b) noinline optnone "target-features"="+crc" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.crc32h(i32 %a, i32 %b)
  ret i32 %r
}

define i32 @reference_crc32cb(i32 %a, i32 %b) "target-features"="+crc" {
entry:
  %r = call i32 @llvm.aarch64.crc32cb(i32 %a, i32 %b)
  ret i32 %r
}

define i32 @protected_crc32cb(i32 %a, i32 %b) noinline optnone "target-features"="+crc" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.crc32cb(i32 %a, i32 %b)
  ret i32 %r
}

define i32 @reference_crc32cw(i32 %a, i32 %b) "target-features"="+crc" {
entry:
  %r = call i32 @llvm.aarch64.crc32cw(i32 %a, i32 %b)
  ret i32 %r
}

define i32 @protected_crc32cw(i32 %a, i32 %b) noinline optnone "target-features"="+crc" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.crc32cw(i32 %a, i32 %b)
  ret i32 %r
}

define i32 @reference_crc32ch(i32 %a, i32 %b) "target-features"="+crc" {
entry:
  %r = call i32 @llvm.aarch64.crc32ch(i32 %a, i32 %b)
  ret i32 %r
}

define i32 @protected_crc32ch(i32 %a, i32 %b) noinline optnone "target-features"="+crc" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.crc32ch(i32 %a, i32 %b)
  ret i32 %r
}

define i32 @reference_crc32x(i32 %a, i64 %b) "target-features"="+crc" {
entry:
  %r = call i32 @llvm.aarch64.crc32x(i32 %a, i64 %b)
  ret i32 %r
}

define i32 @protected_crc32x(i32 %a, i64 %b) noinline optnone "target-features"="+crc" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.crc32x(i32 %a, i64 %b)
  ret i32 %r
}

define i32 @reference_crc32cx(i32 %a, i64 %b) "target-features"="+crc" {
entry:
  %r = call i32 @llvm.aarch64.crc32cx(i32 %a, i64 %b)
  ret i32 %r
}

define i32 @protected_crc32cx(i32 %a, i64 %b) noinline optnone "target-features"="+crc" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.crc32cx(i32 %a, i64 %b)
  ret i32 %r
}

; Last token -crc wins over an earlier +crc — feature-gate skip (not call).
define i32 @unsupported_crc32w_crc_disabled(i32 %a, i32 %b) noinline optnone "target-features"="+neon,+crc,-crc" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.crc32w(i32 %a, i32 %b)
  ret i32 %r
}

; No target-features attribute — feature-gate skip (even with valid shape).
define i32 @unsupported_crc32w_no_target_features(i32 %a, i32 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.crc32w(i32 %a, i32 %b)
  ret i32 %r
}

; Well-shaped crc32cx without +crc: feature-gate (not call reject).
define i32 @unsupported_crc32cx_no_target_features(i32 %a, i64 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.crc32cx(i32 %a, i64 %b)
  ret i32 %r
}

; llvm.aarch64.clrex: void / zero args; no target-features gate required.
define void @reference_clrex() {
entry:
  call void @llvm.aarch64.clrex()
  ret void
}

define void @protected_clrex() noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.clrex()
  ret void
}

; llvm.aarch64.hint: void / single i32 ConstantInt imm 0..127; no +crc gate.
define void @reference_hint() {
entry:
  call void @llvm.aarch64.hint(i32 0)
  ret void
}

define void @protected_hint() noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.hint(i32 0)
  ret void
}

; llvm.aarch64.cls: i32 result, single ordinary i32 arg; no feature gate.
define i32 @reference_cls(i32 %x) {
entry:
  %r = call i32 @llvm.aarch64.cls(i32 %x)
  ret i32 %r
}

define i32 @protected_cls(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.cls(i32 %x)
  ret i32 %r
}

; llvm.aarch64.cls64: i32 result, single ordinary i64 arg; no feature gate.
define i32 @reference_cls64(i64 %x) {
entry:
  %r = call i32 @llvm.aarch64.cls64(i64 %x)
  ret i32 %r
}

define i32 @protected_cls64(i64 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.cls64(i64 %x)
  ret i32 %r
}

; llvm.aarch64.sdiv.i32 / i64 only (not IR sdiv, not udiv, not mixed widths).
define i32 @reference_sdiv_i32(i32 %a, i32 %b) {
entry:
  %r = call i32 @llvm.aarch64.sdiv.i32(i32 %a, i32 %b)
  ret i32 %r
}

define i32 @protected_sdiv_i32(i32 %a, i32 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.sdiv.i32(i32 %a, i32 %b)
  ret i32 %r
}

define i64 @reference_sdiv_i64(i64 %a, i64 %b) {
entry:
  %r = call i64 @llvm.aarch64.sdiv.i64(i64 %a, i64 %b)
  ret i64 %r
}

define i64 @protected_sdiv_i64(i64 %a, i64 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.aarch64.sdiv.i64(i64 %a, i64 %b)
  ret i64 %r
}

; llvm.aarch64.udiv.i32 / i64 only (not IR udiv, not sdiv, not mixed widths).
define i32 @reference_udiv_i32(i32 %a, i32 %b) {
entry:
  %r = call i32 @llvm.aarch64.udiv.i32(i32 %a, i32 %b)
  ret i32 %r
}

define i32 @protected_udiv_i32(i32 %a, i32 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.udiv.i32(i32 %a, i32 %b)
  ret i32 %r
}

define i64 @reference_udiv_i64(i64 %a, i64 %b) {
entry:
  %r = call i64 @llvm.aarch64.udiv.i64(i64 %a, i64 %b)
  ret i64 %r
}

define i64 @protected_udiv_i64(i64 %a, i64 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.aarch64.udiv.i64(i64 %a, i64 %b)
  ret i64 %r
}

; llvm.aarch64.frint32z.f32 only (not f64 / frint64z / frint*x).
; Requires exact function +fptoint (also needed for AArch64 isel).
define float @reference_frint32z_f32(float %x) "target-features"="+fptoint" {
entry:
  %r = call float @llvm.aarch64.frint32z.f32(float %x)
  ret float %r
}

define float @protected_frint32z_f32(float %x) noinline optnone "target-features"="+fptoint" {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.aarch64.frint32z.f32(float %x)
  ret float %r
}

; Multi-feature list: last exact +fptoint enables frint32z.
define float @protected_frint32z_f32_multi(float %x) noinline optnone "target-features"="+neon,+fptoint,+fp-armv8" {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.aarch64.frint32z.f32(float %x)
  ret float %r
}

; Missing target-features: feature-gate skip (shape OK).
define float @unsupported_frint32z_no_target_features(float %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.aarch64.frint32z.f32(float %x)
  ret float %r
}

; Last token -fptoint wins over earlier +fptoint — feature-gate skip.
define float @unsupported_frint32z_fptoint_disabled(float %x) noinline optnone "target-features"="+fptoint,-fptoint" {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.aarch64.frint32z.f32(float %x)
  ret float %r
}

; Double overload stays rejected this round (not feature gate).
define i32 @unsupported_frint32z_f64(double %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call double @llvm.aarch64.frint32z.f64(double %x)
  %bits = bitcast double %r to i64
  %out = trunc i64 %bits to i32
  ret i32 %out
}

; llvm.aarch64.frint64z.f32 only (not f64); same +fptoint gate as frint32z.
define float @reference_frint64z_f32(float %x) "target-features"="+fptoint" {
entry:
  %r = call float @llvm.aarch64.frint64z.f32(float %x)
  ret float %r
}

define float @protected_frint64z_f32(float %x) noinline optnone "target-features"="+fptoint" {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.aarch64.frint64z.f32(float %x)
  ret float %r
}

define float @protected_frint64z_f32_multi(float %x) noinline optnone "target-features"="+neon,+fptoint,+fp-armv8" {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.aarch64.frint64z.f32(float %x)
  ret float %r
}

define float @unsupported_frint64z_no_target_features(float %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.aarch64.frint64z.f32(float %x)
  ret float %r
}

define float @unsupported_frint64z_fptoint_disabled(float %x) noinline optnone "target-features"="+fptoint,-fptoint" {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.aarch64.frint64z.f32(float %x)
  ret float %r
}

define i32 @unsupported_frint64z_f64(double %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call double @llvm.aarch64.frint64z.f64(double %x)
  %bits = bitcast double %r to i64
  %out = trunc i64 %bits to i32
  ret i32 %out
}

; llvm.aarch64.frint32x.f32 only (not f64); same +fptoint gate as frint32z/64z.
define float @reference_frint32x_f32(float %x) "target-features"="+fptoint" {
entry:
  %r = call float @llvm.aarch64.frint32x.f32(float %x)
  ret float %r
}

define float @protected_frint32x_f32(float %x) noinline optnone "target-features"="+fptoint" {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.aarch64.frint32x.f32(float %x)
  ret float %r
}

define float @protected_frint32x_f32_multi(float %x) noinline optnone "target-features"="+neon,+fptoint,+fp-armv8" {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.aarch64.frint32x.f32(float %x)
  ret float %r
}

define float @unsupported_frint32x_no_target_features(float %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.aarch64.frint32x.f32(float %x)
  ret float %r
}

define float @unsupported_frint32x_fptoint_disabled(float %x) noinline optnone "target-features"="+fptoint,-fptoint" {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.aarch64.frint32x.f32(float %x)
  ret float %r
}

define i32 @unsupported_frint32x_f64(double %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call double @llvm.aarch64.frint32x.f64(double %x)
  %bits = bitcast double %r to i64
  %out = trunc i64 %bits to i32
  ret i32 %out
}

; llvm.aarch64.frint64x.f32 only (not f64); same +fptoint gate as other FRINT f32.
define float @reference_frint64x_f32(float %x) "target-features"="+fptoint" {
entry:
  %r = call float @llvm.aarch64.frint64x.f32(float %x)
  ret float %r
}

define float @protected_frint64x_f32(float %x) noinline optnone "target-features"="+fptoint" {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.aarch64.frint64x.f32(float %x)
  ret float %r
}

define float @protected_frint64x_f32_multi(float %x) noinline optnone "target-features"="+neon,+fptoint,+fp-armv8" {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.aarch64.frint64x.f32(float %x)
  ret float %r
}

define float @unsupported_frint64x_no_target_features(float %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.aarch64.frint64x.f32(float %x)
  ret float %r
}

define float @unsupported_frint64x_fptoint_disabled(float %x) noinline optnone "target-features"="+fptoint,-fptoint" {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.aarch64.frint64x.f32(float %x)
  ret float %r
}

define i32 @unsupported_frint64x_f64(double %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call double @llvm.aarch64.frint64x.f64(double %x)
  %bits = bitcast double %r to i64
  %out = trunc i64 %bits to i32
  ret i32 %out
}

; Illegal AArch64 barrier CRm stays rejected (not generalized from cls*).
declare void @llvm.aarch64.dmb(i32)
define void @unsupported_dmb_crm0() noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.dmb(i32 0)
  ret void
}

; Dynamic hint imm cannot stay as CallDescriptor immediate — reject.
define void @unsupported_hint_dynamic(i32 %imm) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.hint(i32 %imm)
  ret void
}

; Out-of-range HINT encoding (>127) stays rejected.
define void @unsupported_hint_oor() noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.hint(i32 128)
  ret void
}

define i32 @main() {
entry:
  %e0 = call i32 @reference_crc32w(i32 0, i32 0)
  %a0 = call i32 @protected_crc32w(i32 0, i32 0)
  %b0 = call i32 @protected_crc32w_multi(i32 0, i32 0)
  %e1 = call i32 @reference_crc32w(i32 1, i32 305419896)
  %a1 = call i32 @protected_crc32w(i32 1, i32 305419896)
  %b1 = call i32 @protected_crc32w_multi(i32 1, i32 305419896)
  %eb0 = call i32 @reference_crc32b(i32 0, i32 0)
  %ab0 = call i32 @protected_crc32b(i32 0, i32 0)
  %eb1 = call i32 @reference_crc32b(i32 1, i32 305419896)
  %ab1 = call i32 @protected_crc32b(i32 1, i32 305419896)
  %eh0 = call i32 @reference_crc32h(i32 0, i32 0)
  %ah0 = call i32 @protected_crc32h(i32 0, i32 0)
  %eh1 = call i32 @reference_crc32h(i32 1, i32 305419896)
  %ah1 = call i32 @protected_crc32h(i32 1, i32 305419896)
  %ecb0 = call i32 @reference_crc32cb(i32 0, i32 0)
  %acb0 = call i32 @protected_crc32cb(i32 0, i32 0)
  %ecb1 = call i32 @reference_crc32cb(i32 1, i32 305419896)
  %acb1 = call i32 @protected_crc32cb(i32 1, i32 305419896)
  %ecw0 = call i32 @reference_crc32cw(i32 0, i32 0)
  %acw0 = call i32 @protected_crc32cw(i32 0, i32 0)
  %ecw1 = call i32 @reference_crc32cw(i32 1, i32 305419896)
  %acw1 = call i32 @protected_crc32cw(i32 1, i32 305419896)
  %ech0 = call i32 @reference_crc32ch(i32 0, i32 0)
  %ach0 = call i32 @protected_crc32ch(i32 0, i32 0)
  %ech1 = call i32 @reference_crc32ch(i32 1, i32 305419896)
  %ach1 = call i32 @protected_crc32ch(i32 1, i32 305419896)
  %ex0 = call i32 @reference_crc32x(i32 0, i64 0)
  %ax0 = call i32 @protected_crc32x(i32 0, i64 0)
  %ex1 = call i32 @reference_crc32x(i32 1, i64 1311768467463790320)
  %ax1 = call i32 @protected_crc32x(i32 1, i64 1311768467463790320)
  %ecx0 = call i32 @reference_crc32cx(i32 0, i64 0)
  %acx0 = call i32 @protected_crc32cx(i32 0, i64 0)
  %ecx1 = call i32 @reference_crc32cx(i32 1, i64 1311768467463790320)
  %acx1 = call i32 @protected_crc32cx(i32 1, i64 1311768467463790320)
  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %e1, %a1
  %m2 = icmp eq i32 %e0, %b0
  %m3 = icmp eq i32 %e1, %b1
  %m4 = icmp eq i32 %eb0, %ab0
  %m5 = icmp eq i32 %eb1, %ab1
  %m6 = icmp eq i32 %eh0, %ah0
  %m7 = icmp eq i32 %eh1, %ah1
  %m8 = icmp eq i32 %ecb0, %acb0
  %m9 = icmp eq i32 %ecb1, %acb1
  %m10 = icmp eq i32 %ecw0, %acw0
  %m11 = icmp eq i32 %ecw1, %acw1
  %m12 = icmp eq i32 %ech0, %ach0
  %m13 = icmp eq i32 %ech1, %ach1
  %m14 = icmp eq i32 %ex0, %ax0
  %m15 = icmp eq i32 %ex1, %ax1
  %m16 = icmp eq i32 %ecx0, %acx0
  %m17 = icmp eq i32 %ecx1, %acx1
  %t0 = and i1 %m0, %m1
  %t1 = and i1 %m2, %m3
  %t2 = and i1 %m4, %m5
  %t3 = and i1 %m6, %m7
  %t4 = and i1 %m8, %m9
  %t5 = and i1 %m10, %m11
  %t6 = and i1 %m12, %m13
  %t7 = and i1 %m14, %m15
  %t8 = and i1 %m16, %m17
  %t9 = and i1 %t0, %t1
  %t10 = and i1 %t2, %t3
  %t11 = and i1 %t4, %t5
  %t12 = and i1 %t6, %t7
  %t13 = and i1 %t9, %t10
  %t14 = and i1 %t11, %t12
  %t15 = and i1 %t13, %t14
  %ec0 = call i32 @reference_cls(i32 0)
  %ac0 = call i32 @protected_cls(i32 0)
  %ec1 = call i32 @reference_cls(i32 -1)
  %ac1 = call i32 @protected_cls(i32 -1)
  %m18 = icmp eq i32 %ec0, %ac0
  %m19 = icmp eq i32 %ec1, %ac1
  %t16 = and i1 %m18, %m19
  %ec640 = call i32 @reference_cls64(i64 0)
  %ac640 = call i32 @protected_cls64(i64 0)
  %ec641 = call i32 @reference_cls64(i64 -1)
  %ac641 = call i32 @protected_cls64(i64 -1)
  %m20 = icmp eq i32 %ec640, %ac640
  %m21 = icmp eq i32 %ec641, %ac641
  %t17 = and i1 %m20, %m21
  %t18 = and i1 %t16, %t17
  %es0 = call i32 @reference_sdiv_i32(i32 42, i32 7)
  %as0 = call i32 @protected_sdiv_i32(i32 42, i32 7)
  %es1 = call i32 @reference_sdiv_i32(i32 -42, i32 7)
  %as1 = call i32 @protected_sdiv_i32(i32 -42, i32 7)
  %m22 = icmp eq i32 %es0, %as0
  %m23 = icmp eq i32 %es1, %as1
  %t19 = and i1 %m22, %m23
  %es640 = call i64 @reference_sdiv_i64(i64 42, i64 7)
  %as640 = call i64 @protected_sdiv_i64(i64 42, i64 7)
  %es641 = call i64 @reference_sdiv_i64(i64 -42, i64 7)
  %as641 = call i64 @protected_sdiv_i64(i64 -42, i64 7)
  %m24 = icmp eq i64 %es640, %as640
  %m25 = icmp eq i64 %es641, %as641
  %t20 = and i1 %m24, %m25
  %t21 = and i1 %t19, %t20
  %t22 = and i1 %t18, %t21
  %eu0 = call i32 @reference_udiv_i32(i32 42, i32 7)
  %au0 = call i32 @protected_udiv_i32(i32 42, i32 7)
  %eu1 = call i32 @reference_udiv_i32(i32 100, i32 3)
  %au1 = call i32 @protected_udiv_i32(i32 100, i32 3)
  %m26 = icmp eq i32 %eu0, %au0
  %m27 = icmp eq i32 %eu1, %au1
  %t23 = and i1 %m26, %m27
  %eu640 = call i64 @reference_udiv_i64(i64 42, i64 7)
  %au640 = call i64 @protected_udiv_i64(i64 42, i64 7)
  %eu641 = call i64 @reference_udiv_i64(i64 100, i64 3)
  %au641 = call i64 @protected_udiv_i64(i64 100, i64 3)
  %m28 = icmp eq i64 %eu640, %au640
  %m29 = icmp eq i64 %eu641, %au641
  %t24 = and i1 %m28, %m29
  %t25 = and i1 %t23, %t24
  %t26 = and i1 %t22, %t25
  %ef0 = call float @reference_frint32z_f32(float 1.500000e+00)
  %af0 = call float @protected_frint32z_f32(float 1.500000e+00)
  %bf0 = call float @protected_frint32z_f32_multi(float 1.500000e+00)
  %ef1 = call float @reference_frint32z_f32(float -2.250000e+00)
  %af1 = call float @protected_frint32z_f32(float -2.250000e+00)
  %bf1 = call float @protected_frint32z_f32_multi(float -2.250000e+00)
  %ef0i = bitcast float %ef0 to i32
  %af0i = bitcast float %af0 to i32
  %bf0i = bitcast float %bf0 to i32
  %ef1i = bitcast float %ef1 to i32
  %af1i = bitcast float %af1 to i32
  %bf1i = bitcast float %bf1 to i32
  %m30 = icmp eq i32 %ef0i, %af0i
  %m31 = icmp eq i32 %ef1i, %af1i
  %m32 = icmp eq i32 %ef0i, %bf0i
  %m33 = icmp eq i32 %ef1i, %bf1i
  %t27 = and i1 %m30, %m31
  %t27b = and i1 %m32, %m33
  %t27c = and i1 %t27, %t27b
  %t28 = and i1 %t26, %t27c
  %eg0 = call float @reference_frint64z_f32(float 1.500000e+00)
  %ag0 = call float @protected_frint64z_f32(float 1.500000e+00)
  %bg0 = call float @protected_frint64z_f32_multi(float 1.500000e+00)
  %eg1 = call float @reference_frint64z_f32(float -2.250000e+00)
  %ag1 = call float @protected_frint64z_f32(float -2.250000e+00)
  %bg1 = call float @protected_frint64z_f32_multi(float -2.250000e+00)
  %eg0i = bitcast float %eg0 to i32
  %ag0i = bitcast float %ag0 to i32
  %bg0i = bitcast float %bg0 to i32
  %eg1i = bitcast float %eg1 to i32
  %ag1i = bitcast float %ag1 to i32
  %bg1i = bitcast float %bg1 to i32
  %m34 = icmp eq i32 %eg0i, %ag0i
  %m35 = icmp eq i32 %eg1i, %ag1i
  %m36 = icmp eq i32 %eg0i, %bg0i
  %m37 = icmp eq i32 %eg1i, %bg1i
  %t29 = and i1 %m34, %m35
  %t29b = and i1 %m36, %m37
  %t29c = and i1 %t29, %t29b
  %t30 = and i1 %t28, %t29c
  %ei0 = call float @reference_frint32x_f32(float 1.500000e+00)
  %ai0 = call float @protected_frint32x_f32(float 1.500000e+00)
  %bi0 = call float @protected_frint32x_f32_multi(float 1.500000e+00)
  %ei1 = call float @reference_frint32x_f32(float -2.250000e+00)
  %ai1 = call float @protected_frint32x_f32(float -2.250000e+00)
  %bi1 = call float @protected_frint32x_f32_multi(float -2.250000e+00)
  %ei0i = bitcast float %ei0 to i32
  %ai0i = bitcast float %ai0 to i32
  %bi0i = bitcast float %bi0 to i32
  %ei1i = bitcast float %ei1 to i32
  %ai1i = bitcast float %ai1 to i32
  %bi1i = bitcast float %bi1 to i32
  %m38 = icmp eq i32 %ei0i, %ai0i
  %m39 = icmp eq i32 %ei1i, %ai1i
  %m40 = icmp eq i32 %ei0i, %bi0i
  %m41 = icmp eq i32 %ei1i, %bi1i
  %t31 = and i1 %m38, %m39
  %t31b = and i1 %m40, %m41
  %t31c = and i1 %t31, %t31b
  %t32 = and i1 %t30, %t31c
  %ej0 = call float @reference_frint64x_f32(float 1.500000e+00)
  %aj0 = call float @protected_frint64x_f32(float 1.500000e+00)
  %bj0 = call float @protected_frint64x_f32_multi(float 1.500000e+00)
  %ej1 = call float @reference_frint64x_f32(float -2.250000e+00)
  %aj1 = call float @protected_frint64x_f32(float -2.250000e+00)
  %bj1 = call float @protected_frint64x_f32_multi(float -2.250000e+00)
  %ej0i = bitcast float %ej0 to i32
  %aj0i = bitcast float %aj0 to i32
  %bj0i = bitcast float %bj0 to i32
  %ej1i = bitcast float %ej1 to i32
  %aj1i = bitcast float %aj1 to i32
  %bj1i = bitcast float %bj1 to i32
  %m42 = icmp eq i32 %ej0i, %aj0i
  %m43 = icmp eq i32 %ej1i, %aj1i
  %m44 = icmp eq i32 %ej0i, %bj0i
  %m45 = icmp eq i32 %ej1i, %bj1i
  %t33 = and i1 %m42, %m43
  %t33b = and i1 %m44, %m45
  %t33c = and i1 %t33, %t33b
  %t34 = and i1 %t32, %t33c
  %ok = and i1 %t15, %t8
  %ok2 = and i1 %ok, %t34
  call void @reference_clrex()
  call void @protected_clrex()
  call void @reference_hint()
  call void @protected_hint()
  %code = select i1 %ok2, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with: 202
; SKIP-DAG: Skipping VMP on unsupported_crc32w_crc_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_crc32w_no_target_features: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_crc32cx_no_target_features: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_hint_dynamic: unsupported hint
; SKIP-DAG: Skipping VMP on unsupported_hint_oor: unsupported hint
; SKIP-DAG: Skipping VMP on unsupported_dmb_crm0: unsupported dmb
; SKIP-DAG: Skipping VMP on unsupported_frint32z_no_target_features: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_frint32z_fptoint_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_frint32z_f64: unsupported frint
; SKIP-DAG: Skipping VMP on unsupported_frint64z_no_target_features: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_frint64z_fptoint_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_frint64z_f64: unsupported frint
; SKIP-DAG: Skipping VMP on unsupported_frint32x_no_target_features: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_frint32x_fptoint_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_frint32x_f64: unsupported frint
; SKIP-DAG: Skipping VMP on unsupported_frint64x_no_target_features: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_frint64x_fptoint_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_frint64x_f64: unsupported frint
; SKIP-NOT: Skipping VMP on protected_crc32w:
; SKIP-NOT: Skipping VMP on protected_crc32w_multi:
; SKIP-NOT: Skipping VMP on protected_crc32b:
; SKIP-NOT: Skipping VMP on protected_crc32h:
; SKIP-NOT: Skipping VMP on protected_crc32cb:
; SKIP-NOT: Skipping VMP on protected_crc32cw:
; SKIP-NOT: Skipping VMP on protected_crc32ch:
; SKIP-NOT: Skipping VMP on protected_crc32x:
; SKIP-NOT: Skipping VMP on protected_crc32cx:
; SKIP-NOT: Skipping VMP on protected_clrex:
; SKIP-NOT: Skipping VMP on protected_hint:
; SKIP-NOT: Skipping VMP on protected_cls:
; SKIP-NOT: Skipping VMP on protected_cls64:
; SKIP-NOT: Skipping VMP on protected_sdiv_i32:
; SKIP-NOT: Skipping VMP on protected_sdiv_i64:
; SKIP-NOT: Skipping VMP on protected_udiv_i32:
; SKIP-NOT: Skipping VMP on protected_udiv_i64:
; SKIP-NOT: Skipping VMP on protected_frint32z_f32:
; SKIP-NOT: Skipping VMP on protected_frint32z_f32_multi:
; SKIP-NOT: Skipping VMP on protected_frint64z_f32:
; SKIP-NOT: Skipping VMP on protected_frint64z_f32_multi:
; SKIP-NOT: Skipping VMP on protected_frint32x_f32:
; SKIP-NOT: Skipping VMP on protected_frint32x_f32_multi:
; SKIP-NOT: Skipping VMP on protected_frint64x_f32:
; SKIP-NOT: Skipping VMP on protected_frint64x_f32_multi:

; VIRT: define i32 @protected_crc32w({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.crc32w(
; VIRT: define i32 @protected_crc32w_multi({{.*}} #[[PROT_MULTI:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.crc32w(
; VIRT: define i32 @protected_crc32b({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.crc32b(
; VIRT: define i32 @protected_crc32h({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.crc32h(
; VIRT: define i32 @protected_crc32cb({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.crc32cb(
; VIRT: define i32 @protected_crc32cw({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.crc32cw(
; VIRT: define i32 @protected_crc32ch({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.crc32ch(
; VIRT: define i32 @protected_crc32x({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.crc32x(
; VIRT: define i32 @protected_crc32cx({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.crc32cx(
; VIRT: define i32 @unsupported_crc32w_crc_disabled({{.*}} #[[UNSUP_DIS:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call i32 @llvm.aarch64.crc32w(
; VIRT: define i32 @unsupported_crc32w_no_target_features({{.*}} #[[UNSUP_NO:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call i32 @llvm.aarch64.crc32w(
; VIRT: define i32 @unsupported_crc32cx_no_target_features({{.*}} #[[UNSUP_NO]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call i32 @llvm.aarch64.crc32cx(
; VIRT: define void @protected_clrex({{.*}} #[[PROT_VOID:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.aarch64.clrex(
; VIRT: define void @protected_hint({{.*}} #[[PROT_VOID]] {
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.aarch64.hint(i32 0)
; VIRT: define i32 @protected_cls({{.*}} #[[PROT_VOID]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.cls(
; VIRT: define i32 @protected_cls64({{.*}} #[[PROT_VOID]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.cls64(
; VIRT: define i32 @protected_sdiv_i32({{.*}} #[[PROT_VOID]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.sdiv.i32(
; VIRT: define i64 @protected_sdiv_i64({{.*}} #[[PROT_VOID]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.aarch64.sdiv.i64(
; VIRT: define i32 @protected_udiv_i32({{.*}} #[[PROT_VOID]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.udiv.i32(
; VIRT: define i64 @protected_udiv_i64({{.*}} #[[PROT_VOID]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.aarch64.udiv.i64(
; VIRT: define float @protected_frint32z_f32({{.*}} #[[PROT_FRINT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.aarch64.frint32z.f32(
; VIRT: define float @protected_frint32z_f32_multi({{.*}} #[[PROT_FRINT_MULTI:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.aarch64.frint32z.f32(
; VIRT: define float @unsupported_frint32z_no_target_features({{.*}} #[[UNSUP_NO]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call float @llvm.aarch64.frint32z.f32(
; VIRT: define float @unsupported_frint32z_fptoint_disabled({{.*}} #[[UNSUP_FPT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call float @llvm.aarch64.frint32z.f32(
; VIRT: define i32 @unsupported_frint32z_f64({{.*}} #[[UNSUP_NO]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call double @llvm.aarch64.frint32z.f64(
; VIRT: define float @protected_frint64z_f32({{.*}} #[[PROT_FRINT]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.aarch64.frint64z.f32(
; VIRT: define float @protected_frint64z_f32_multi({{.*}} #[[PROT_FRINT_MULTI]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.aarch64.frint64z.f32(
; VIRT: define float @unsupported_frint64z_no_target_features({{.*}} #[[UNSUP_NO]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call float @llvm.aarch64.frint64z.f32(
; VIRT: define float @unsupported_frint64z_fptoint_disabled({{.*}} #[[UNSUP_FPT]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call float @llvm.aarch64.frint64z.f32(
; VIRT: define i32 @unsupported_frint64z_f64({{.*}} #[[UNSUP_NO]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call double @llvm.aarch64.frint64z.f64(
; VIRT: define float @protected_frint32x_f32({{.*}} #[[PROT_FRINT]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.aarch64.frint32x.f32(
; VIRT: define float @protected_frint32x_f32_multi({{.*}} #[[PROT_FRINT_MULTI]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.aarch64.frint32x.f32(
; VIRT: define float @unsupported_frint32x_no_target_features({{.*}} #[[UNSUP_NO]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call float @llvm.aarch64.frint32x.f32(
; VIRT: define float @unsupported_frint32x_fptoint_disabled({{.*}} #[[UNSUP_FPT]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call float @llvm.aarch64.frint32x.f32(
; VIRT: define i32 @unsupported_frint32x_f64({{.*}} #[[UNSUP_NO]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call double @llvm.aarch64.frint32x.f64(
; VIRT: define float @protected_frint64x_f32({{.*}} #[[PROT_FRINT]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.aarch64.frint64x.f32(
; VIRT: define float @protected_frint64x_f32_multi({{.*}} #[[PROT_FRINT_MULTI]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.aarch64.frint64x.f32(
; VIRT: define float @unsupported_frint64x_no_target_features({{.*}} #[[UNSUP_NO]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call float @llvm.aarch64.frint64x.f32(
; VIRT: define float @unsupported_frint64x_fptoint_disabled({{.*}} #[[UNSUP_FPT]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call float @llvm.aarch64.frint64x.f32(
; VIRT: define i32 @unsupported_frint64x_f64({{.*}} #[[UNSUP_NO]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call double @llvm.aarch64.frint64x.f64(
; VIRT: define void @unsupported_dmb_crm0({{.*}} #[[UNSUP_NO]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call void @llvm.aarch64.dmb(i32 0)
; VIRT: define void @unsupported_hint_dynamic({{.*}} #[[UNSUP_NO]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call void @llvm.aarch64.hint(i32 %{{.*}})
; VIRT: define void @unsupported_hint_oor({{.*}} #[[UNSUP_NO]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call void @llvm.aarch64.hint(i32 128)
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[PROT_MULTI]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP_DIS]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT: attributes #[[UNSUP_NO]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT: attributes #[[PROT_VOID]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[PROT_FRINT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }