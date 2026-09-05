; Restricted llvm.fptosi.sat / llvm.fptoui.sat on scalar IEEE half and
; same-lane fixed half vectors.  Dest is i8/i16/i32/i64 (scalar or
; same-lane vector).  Each vector side independently totals 1..128;
; leftover (non-power-of-two) lanes are allowed.  Replayed via the
; existing CallDescriptor and integer/float/vector VReg frames.
; Requires last-token function +fullfp16.  Well-shaped calls missing
; or ending in -fullfp16 skip as unsupported target feature and keep
; hikari.vmp.selected.  Does not change f32/f64 scalar or vector sat,
; ordinary fptosi/fptoui, half base SSA, or listed half math.  Scalar
; Ordinary tail (scalar and vector half sat) is accepted and replayed as a non-tail call; see vmp-direct-call-tail-eligibility-semantic.ll.
; No FMF path and no dedicated VM opcode.
;
; Host x86 cannot be assumed to select half sat converts.  This lit
; is FileCheck + AArch64 llc/readobj only (function +fullfp16, no
; global -mattr).  Do not invent a host lli semantic oracle.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.ll > %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.ll > %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.s7.ll > %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.s7.ll > %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare i8 @llvm.fptosi.sat.i8.f16(half)
declare i8 @llvm.fptoui.sat.i8.f16(half)
declare i16 @llvm.fptosi.sat.i16.f16(half)
declare i16 @llvm.fptoui.sat.i16.f16(half)
declare i32 @llvm.fptosi.sat.i32.f16(half)
declare i32 @llvm.fptoui.sat.i32.f16(half)
declare i64 @llvm.fptosi.sat.i64.f16(half)
declare i64 @llvm.fptoui.sat.i64.f16(half)
declare i1 @llvm.fptosi.sat.i1.f16(half)
declare <4 x i8> @llvm.fptosi.sat.v4i8.v4f16(<4 x half>)
declare <4 x i8> @llvm.fptoui.sat.v4i8.v4f16(<4 x half>)
declare <8 x i16> @llvm.fptosi.sat.v8i16.v8f16(<8 x half>)
declare <8 x i16> @llvm.fptoui.sat.v8i16.v8f16(<8 x half>)
declare <4 x i32> @llvm.fptosi.sat.v4i32.v4f16(<4 x half>)
declare <4 x i32> @llvm.fptoui.sat.v4i32.v4f16(<4 x half>)
declare <2 x i64> @llvm.fptosi.sat.v2i64.v2f16(<2 x half>)
declare <2 x i64> @llvm.fptoui.sat.v2i64.v2f16(<2 x half>)
declare <3 x i8> @llvm.fptosi.sat.v3i8.v3f16(<3 x half>)
declare <3 x i32> @llvm.fptosi.sat.v3i32.v3f16(<3 x half>)
declare <2 x i1> @llvm.fptosi.sat.v2i1.v2f16(<2 x half>)
declare i32 @llvm.fptosi.sat.i32.bf16(bfloat)
declare i128 @llvm.fptosi.sat.i128.f128(fp128)
declare <4 x i32> @llvm.fptosi.sat.v4i32.v4bf16(<4 x bfloat>)
declare <vscale x 4 x i32> @llvm.fptosi.sat.nxv4i32.nxv4f16(<vscale x 4 x half>)
declare <16 x i8> @llvm.fptosi.sat.v16i8.v16f16(<16 x half>)
declare <4 x i64> @llvm.fptosi.sat.v4i64.v4f16(<4 x half>)

; ----- scalar positives -----

declare <2 x half> @llvm.experimental.constrained.pow.v2f16(<2 x half>, <2 x half>, metadata, metadata)

define i8 @reference_fptosi_sat_i8_f16(half %a) {
entry:
  %r = call i8 @llvm.fptosi.sat.i8.f16(half %a)
  ret i8 %r
}

define i8 @protected_fptosi_sat_i8_f16(half %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i8 @llvm.fptosi.sat.i8.f16(half %a)
  ret i8 %r
}

define i8 @reference_fptoui_sat_i8_f16(half %a) {
entry:
  %r = call i8 @llvm.fptoui.sat.i8.f16(half %a)
  ret i8 %r
}

define i8 @protected_fptoui_sat_i8_f16(half %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i8 @llvm.fptoui.sat.i8.f16(half %a)
  ret i8 %r
}

define i16 @reference_fptosi_sat_i16_f16(half %a) {
entry:
  %r = call i16 @llvm.fptosi.sat.i16.f16(half %a)
  ret i16 %r
}

define i16 @protected_fptosi_sat_i16_f16(half %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i16 @llvm.fptosi.sat.i16.f16(half %a)
  ret i16 %r
}

define i16 @reference_fptoui_sat_i16_f16(half %a) {
entry:
  %r = call i16 @llvm.fptoui.sat.i16.f16(half %a)
  ret i16 %r
}

define i16 @protected_fptoui_sat_i16_f16(half %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i16 @llvm.fptoui.sat.i16.f16(half %a)
  ret i16 %r
}

define i32 @reference_fptosi_sat_i32_f16(half %a) {
entry:
  %r = call i32 @llvm.fptosi.sat.i32.f16(half %a)
  ret i32 %r
}

define i32 @protected_fptosi_sat_i32_f16(half %a) noinline optnone "target-features"="+neon,+fullfp16,+fp-armv8" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.fptosi.sat.i32.f16(half %a)
  ret i32 %r
}

define i32 @reference_fptoui_sat_i32_f16(half %a) {
entry:
  %r = call i32 @llvm.fptoui.sat.i32.f16(half %a)
  ret i32 %r
}

define i32 @protected_fptoui_sat_i32_f16(half %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.fptoui.sat.i32.f16(half %a)
  ret i32 %r
}

define i64 @reference_fptosi_sat_i64_f16(half %a) {
entry:
  %r = call i64 @llvm.fptosi.sat.i64.f16(half %a)
  ret i64 %r
}

define i64 @protected_fptosi_sat_i64_f16(half %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.fptosi.sat.i64.f16(half %a)
  ret i64 %r
}

define i64 @reference_fptoui_sat_i64_f16(half %a) {
entry:
  %r = call i64 @llvm.fptoui.sat.i64.f16(half %a)
  ret i64 %r
}

define i64 @protected_fptoui_sat_i64_f16(half %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.fptoui.sat.i64.f16(half %a)
  ret i64 %r
}

define i8 @reference_fptosi_sat_i8_tail_f16(half %a) {
entry:
  %r = tail call i8 @llvm.fptosi.sat.i8.f16(half %a)
  ret i8 %r
}

define i8 @protected_fptosi_sat_i8_tail_f16(half %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = tail call i8 @llvm.fptosi.sat.i8.f16(half %a)
  ret i8 %r
}

define i8 @reference_fptosi_sat_i8_phi_f16(half %a, half %b, i1 %c) {
entry:
  br i1 %c, label %left, label %right
left:
  %l = call i8 @llvm.fptosi.sat.i8.f16(half %a)
  br label %join
right:
  %r = call i8 @llvm.fptosi.sat.i8.f16(half %b)
  br label %join
join:
  %p = phi i8 [ %l, %left ], [ %r, %right ]
  ret i8 %p
}

define i8 @protected_fptosi_sat_i8_phi_f16(half %a, half %b, i1 %c) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  br i1 %c, label %left, label %right
left:
  %l = call i8 @llvm.fptosi.sat.i8.f16(half %a)
  br label %join
right:
  %r = call i8 @llvm.fptosi.sat.i8.f16(half %b)
  br label %join
join:
  %p = phi i8 [ %l, %left ], [ %r, %right ]
  ret i8 %p
}

define i8 @reference_fptosi_sat_i8_loop_f16(half %a, i32 %n) {
entry:
  br label %hdr
hdr:
  %acc = phi half [ %a, %entry ], [ %nxt, %hdr ]
  %i = phi i32 [ 0, %entry ], [ %i.nxt, %hdr ]
  %cur = call i8 @llvm.fptosi.sat.i8.f16(half %acc)
  %nxt = fadd half %acc, 0xH3C00
  %i.nxt = add i32 %i, 1
  %more = icmp ult i32 %i.nxt, %n
  br i1 %more, label %hdr, label %done
done:
  ret i8 %cur
}

define i8 @protected_fptosi_sat_i8_loop_f16(half %a, i32 %n) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  br label %hdr
hdr:
  %acc = phi half [ %a, %entry ], [ %nxt, %hdr ]
  %i = phi i32 [ 0, %entry ], [ %i.nxt, %hdr ]
  %cur = call i8 @llvm.fptosi.sat.i8.f16(half %acc)
  %nxt = fadd half %acc, 0xH3C00
  %i.nxt = add i32 %i, 1
  %more = icmp ult i32 %i.nxt, %n
  br i1 %more, label %hdr, label %done
done:
  ret i8 %cur
}

; Inputs that exercise in-range, unsigned clamp-to-zero, and overflow
; saturation stay on arguments so FileCheck can still see the call.
define i8 @protected_fptoui_sat_i8_neg_f16(half %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i8 @llvm.fptoui.sat.i8.f16(half %a)
  ret i8 %r
}

define i8 @protected_fptosi_sat_i8_ovf_f16(half %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i8 @llvm.fptosi.sat.i8.f16(half %a)
  ret i8 %r
}

; ----- vector positives -----

define <4 x i8> @reference_fptosi_sat_v4f16_i8(<4 x half> %a) {
entry:
  %r = call <4 x i8> @llvm.fptosi.sat.v4i8.v4f16(<4 x half> %a)
  ret <4 x i8> %r
}

define <4 x i8> @protected_fptosi_sat_v4f16_i8(<4 x half> %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i8> @llvm.fptosi.sat.v4i8.v4f16(<4 x half> %a)
  ret <4 x i8> %r
}

define <4 x i8> @reference_fptoui_sat_v4f16_i8(<4 x half> %a) {
entry:
  %r = call <4 x i8> @llvm.fptoui.sat.v4i8.v4f16(<4 x half> %a)
  ret <4 x i8> %r
}

define <4 x i8> @protected_fptoui_sat_v4f16_i8(<4 x half> %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i8> @llvm.fptoui.sat.v4i8.v4f16(<4 x half> %a)
  ret <4 x i8> %r
}

define <8 x i16> @reference_fptosi_sat_v8f16_i16(<8 x half> %a) {
entry:
  %r = call <8 x i16> @llvm.fptosi.sat.v8i16.v8f16(<8 x half> %a)
  ret <8 x i16> %r
}

define <8 x i16> @protected_fptosi_sat_v8f16_i16(<8 x half> %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <8 x i16> @llvm.fptosi.sat.v8i16.v8f16(<8 x half> %a)
  ret <8 x i16> %r
}

define <8 x i16> @reference_fptoui_sat_v8f16_i16(<8 x half> %a) {
entry:
  %r = call <8 x i16> @llvm.fptoui.sat.v8i16.v8f16(<8 x half> %a)
  ret <8 x i16> %r
}

define <8 x i16> @protected_fptoui_sat_v8f16_i16(<8 x half> %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <8 x i16> @llvm.fptoui.sat.v8i16.v8f16(<8 x half> %a)
  ret <8 x i16> %r
}

define <4 x i32> @reference_fptosi_sat_v4f16_i32(<4 x half> %a) {
entry:
  %r = call <4 x i32> @llvm.fptosi.sat.v4i32.v4f16(<4 x half> %a)
  ret <4 x i32> %r
}

define <4 x i32> @protected_fptosi_sat_v4f16_i32(<4 x half> %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.fptosi.sat.v4i32.v4f16(<4 x half> %a)
  ret <4 x i32> %r
}

define <4 x i32> @reference_fptoui_sat_v4f16_i32(<4 x half> %a) {
entry:
  %r = call <4 x i32> @llvm.fptoui.sat.v4i32.v4f16(<4 x half> %a)
  ret <4 x i32> %r
}

define <4 x i32> @protected_fptoui_sat_v4f16_i32(<4 x half> %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.fptoui.sat.v4i32.v4f16(<4 x half> %a)
  ret <4 x i32> %r
}

define <2 x i64> @reference_fptosi_sat_v2f16_i64(<2 x half> %a) {
entry:
  %r = call <2 x i64> @llvm.fptosi.sat.v2i64.v2f16(<2 x half> %a)
  ret <2 x i64> %r
}

define <2 x i64> @protected_fptosi_sat_v2f16_i64(<2 x half> %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.fptosi.sat.v2i64.v2f16(<2 x half> %a)
  ret <2 x i64> %r
}

define <2 x i64> @reference_fptoui_sat_v2f16_i64(<2 x half> %a) {
entry:
  %r = call <2 x i64> @llvm.fptoui.sat.v2i64.v2f16(<2 x half> %a)
  ret <2 x i64> %r
}

define <2 x i64> @protected_fptoui_sat_v2f16_i64(<2 x half> %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.fptoui.sat.v2i64.v2f16(<2 x half> %a)
  ret <2 x i64> %r
}

define <3 x i8> @reference_fptosi_sat_v3f16_i8(<3 x half> %a) {
entry:
  %r = call <3 x i8> @llvm.fptosi.sat.v3i8.v3f16(<3 x half> %a)
  ret <3 x i8> %r
}

define <3 x i8> @protected_fptosi_sat_v3f16_i8(<3 x half> %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <3 x i8> @llvm.fptosi.sat.v3i8.v3f16(<3 x half> %a)
  ret <3 x i8> %r
}

define <3 x i32> @reference_fptosi_sat_v3f16_i32(<3 x half> %a) {
entry:
  %r = call <3 x i32> @llvm.fptosi.sat.v3i32.v3f16(<3 x half> %a)
  ret <3 x i32> %r
}

define <3 x i32> @protected_fptosi_sat_v3f16_i32(<3 x half> %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <3 x i32> @llvm.fptosi.sat.v3i32.v3f16(<3 x half> %a)
  ret <3 x i32> %r
}

define <4 x i8> @reference_fptosi_sat_tail_v4f16(<4 x half> %a) {
entry:
  %r = tail call <4 x i8> @llvm.fptosi.sat.v4i8.v4f16(<4 x half> %a)
  ret <4 x i8> %r
}


define <4 x i8> @reference_fptosi_sat_phi_v4f16(<4 x half> %a, <4 x half> %b, i1 %c) {
entry:
  br i1 %c, label %left, label %right
left:
  %l = call <4 x i8> @llvm.fptosi.sat.v4i8.v4f16(<4 x half> %a)
  br label %join
right:
  %r = call <4 x i8> @llvm.fptosi.sat.v4i8.v4f16(<4 x half> %b)
  br label %join
join:
  %p = phi <4 x i8> [ %l, %left ], [ %r, %right ]
  ret <4 x i8> %p
}

define <4 x i8> @protected_fptosi_sat_phi_v4f16(<4 x half> %a, <4 x half> %b, i1 %c) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  br i1 %c, label %left, label %right
left:
  %l = call <4 x i8> @llvm.fptosi.sat.v4i8.v4f16(<4 x half> %a)
  br label %join
right:
  %r = call <4 x i8> @llvm.fptosi.sat.v4i8.v4f16(<4 x half> %b)
  br label %join
join:
  %p = phi <4 x i8> [ %l, %left ], [ %r, %right ]
  ret <4 x i8> %p
}

define <4 x i8> @protected_fptoui_sat_v4f16_neg(<4 x half> %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i8> @llvm.fptoui.sat.v4i8.v4f16(<4 x half> %a)
  ret <4 x i8> %r
}

define <4 x i8> @protected_fptosi_sat_v4f16_ovf(<4 x half> %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i8> @llvm.fptosi.sat.v4i8.v4f16(<4 x half> %a)
  ret <4 x i8> %r
}

; ----- negatives: selected, not virtualized -----

define i32 @unsupported_half_sat_scalar_no_fullfp16(half %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.fptosi.sat.i32.f16(half %a)
  ret i32 %r
}

define i32 @unsupported_half_sat_scalar_fullfp16_disabled(half %a) noinline optnone "target-features"="+neon,+fullfp16,-fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.fptosi.sat.i32.f16(half %a)
  ret i32 %r
}

define <4 x i32> @unsupported_half_sat_vector_no_fullfp16(<4 x half> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.fptosi.sat.v4i32.v4f16(<4 x half> %a)
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_half_sat_vector_fullfp16_disabled(<4 x half> %a) noinline optnone "target-features"="+neon,+fullfp16,-fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.fptosi.sat.v4i32.v4f16(<4 x half> %a)
  ret <4 x i32> %r
}

define i1 @unsupported_half_sat_i1(half %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i1 @llvm.fptosi.sat.i1.f16(half %a)
  ret i1 %r
}

define <2 x i1> @unsupported_half_sat_v2i1(<2 x half> %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <2 x i1> @llvm.fptosi.sat.v2i1.v2f16(<2 x half> %a)
  ret <2 x i1> %r
}

define i32 @unsupported_half_sat_bfloat(bfloat %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.fptosi.sat.i32.bf16(bfloat %a)
  ret i32 %r
}

define i128 @unsupported_half_sat_fp128(fp128 %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i128 @llvm.fptosi.sat.i128.f128(fp128 %a)
  ret i128 %r
}

define <4 x i32> @unsupported_half_sat_vec_bfloat(<4 x bfloat> %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.fptosi.sat.v4i32.v4bf16(<4 x bfloat> %a)
  ret <4 x i32> %r
}

define <vscale x 4 x i32> @unsupported_half_sat_scalable(<vscale x 4 x half> %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.fptosi.sat.nxv4i32.nxv4f16(<vscale x 4 x half> %a)
  ret <vscale x 4 x i32> %r
}

define <16 x i8> @unsupported_half_sat_src_wide(<16 x half> %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <16 x i8> @llvm.fptosi.sat.v16i8.v16f16(<16 x half> %a)
  ret <16 x i8> %r
}

define <4 x i64> @unsupported_half_sat_dest_wide(<4 x half> %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i64> @llvm.fptosi.sat.v4i64.v4f16(<4 x half> %a)
  ret <4 x i64> %r
}

define i32 @unsupported_half_sat_fastcc(half %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call fastcc i32 @llvm.fptosi.sat.i32.f16(half %a)
  ret i32 %r
}

define i32 @unsupported_half_sat_musttail(half %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = musttail call i32 @llvm.fptosi.sat.i32.f16(half %a)
  ret i32 %r
}

define i32 @unsupported_half_sat_bundle(half %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.fptosi.sat.i32.f16(half %a) [ "deopt"(i32 0) ]
  ret i32 %r
}

define <2 x half> @unsupported_half_sat_constrained(<2 x half> %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <2 x half> @llvm.experimental.constrained.pow.v2f16(<2 x half> %a, <2 x half> %a, metadata !"round.tonearest", metadata !"fpexcept.ignore") [ "deopt"(i32 0) ]
  ret <2 x half> %r
}

define i8 @unsupported_half_sat_poison(half %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i8 @llvm.fptosi.sat.i8.f16(half poison)
  ret i8 %r
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_half_sat_scalar_no_fullfp16: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_half_sat_scalar_fullfp16_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_half_sat_vector_no_fullfp16: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_half_sat_vector_fullfp16_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_half_sat_i1: unsupported fptosi.sat
; SKIP-DAG: Skipping VMP on unsupported_half_sat_v2i1: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_half_sat_bfloat: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_half_sat_fp128: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_half_sat_vec_bfloat: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_half_sat_scalable: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_half_sat_src_wide: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_half_sat_dest_wide: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_half_sat_fastcc: unsupported fptosi.sat
; SKIP-DAG: Skipping VMP on unsupported_half_sat_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_half_sat_bundle: unsupported fptosi.sat
; SKIP-DAG: Skipping VMP on unsupported_half_sat_constrained: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_half_sat_poison: unsupported fptosi.sat
; SKIP-NOT: Skipping VMP on protected_fptosi_sat_i8_f16:
; SKIP-NOT: Skipping VMP on protected_fptoui_sat_i8_f16:
; SKIP-NOT: Skipping VMP on protected_fptosi_sat_i16_f16:
; SKIP-NOT: Skipping VMP on protected_fptoui_sat_i16_f16:
; SKIP-NOT: Skipping VMP on protected_fptosi_sat_i32_f16:
; SKIP-NOT: Skipping VMP on protected_fptoui_sat_i32_f16:
; SKIP-NOT: Skipping VMP on protected_fptosi_sat_i64_f16:
; SKIP-NOT: Skipping VMP on protected_fptoui_sat_i64_f16:
; SKIP-NOT: Skipping VMP on protected_fptosi_sat_i8_tail_f16:
; SKIP-NOT: Skipping VMP on protected_fptosi_sat_i8_phi_f16:
; SKIP-NOT: Skipping VMP on protected_fptosi_sat_i8_loop_f16:
; SKIP-NOT: Skipping VMP on protected_fptoui_sat_i8_neg_f16:
; SKIP-NOT: Skipping VMP on protected_fptosi_sat_i8_ovf_f16:
; SKIP-NOT: Skipping VMP on protected_fptosi_sat_v4f16_i8:
; SKIP-NOT: Skipping VMP on protected_fptoui_sat_v4f16_i8:
; SKIP-NOT: Skipping VMP on protected_fptosi_sat_v8f16_i16:
; SKIP-NOT: Skipping VMP on protected_fptoui_sat_v8f16_i16:
; SKIP-NOT: Skipping VMP on protected_fptosi_sat_v4f16_i32:
; SKIP-NOT: Skipping VMP on protected_fptoui_sat_v4f16_i32:
; SKIP-NOT: Skipping VMP on protected_fptosi_sat_v2f16_i64:
; SKIP-NOT: Skipping VMP on protected_fptoui_sat_v2f16_i64:
; SKIP-NOT: Skipping VMP on protected_fptosi_sat_v3f16_i8:
; SKIP-NOT: Skipping VMP on protected_fptosi_sat_v3f16_i32:
; SKIP-NOT: Skipping VMP on protected_fptosi_sat_phi_v4f16:
; SKIP-NOT: Skipping VMP on protected_fptoui_sat_v4f16_neg:
; SKIP-NOT: Skipping VMP on protected_fptosi_sat_v4f16_ovf:

; VIRT: define i8 @protected_fptosi_sat_i8_f16({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call i8 @llvm.fptosi.sat.i8.f16(
; VIRT: define i8 @protected_fptoui_sat_i8_f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i8 @llvm.fptoui.sat.i8.f16(
; VIRT: define i16 @protected_fptosi_sat_i16_f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i16 @llvm.fptosi.sat.i16.f16(
; VIRT: define i16 @protected_fptoui_sat_i16_f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i16 @llvm.fptoui.sat.i16.f16(
; VIRT: define i32 @protected_fptosi_sat_i32_f16({{.*}} #[[PROT2:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.fptosi.sat.i32.f16(
; VIRT: define i32 @protected_fptoui_sat_i32_f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.fptoui.sat.i32.f16(
; VIRT: define i64 @protected_fptosi_sat_i64_f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.fptosi.sat.i64.f16(
; VIRT: define i64 @protected_fptoui_sat_i64_f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.fptoui.sat.i64.f16(
; VIRT: define i8 @protected_fptosi_sat_i8_tail_f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: tail call
; VIRT: call i8 @llvm.fptosi.sat.i8.f16(
; VIRT: define i8 @protected_fptosi_sat_i8_phi_f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i8 @llvm.fptosi.sat.i8.f16(
; VIRT: define i8 @protected_fptosi_sat_i8_loop_f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i8 @llvm.fptosi.sat.i8.f16(
; VIRT: define i8 @protected_fptoui_sat_i8_neg_f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i8 @llvm.fptoui.sat.i8.f16(
; VIRT: define i8 @protected_fptosi_sat_i8_ovf_f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i8 @llvm.fptosi.sat.i8.f16(
; VIRT: define <4 x i8> @protected_fptosi_sat_v4f16_i8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i8> @llvm.fptosi.sat.v4i8.v4f16(
; VIRT: define <4 x i8> @protected_fptoui_sat_v4f16_i8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i8> @llvm.fptoui.sat.v4i8.v4f16(
; VIRT: define <8 x i16> @protected_fptosi_sat_v8f16_i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x i16> @llvm.fptosi.sat.v8i16.v8f16(
; VIRT: define <8 x i16> @protected_fptoui_sat_v8f16_i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x i16> @llvm.fptoui.sat.v8i16.v8f16(
; VIRT: define <4 x i32> @protected_fptosi_sat_v4f16_i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.fptosi.sat.v4i32.v4f16(
; VIRT: define <4 x i32> @protected_fptoui_sat_v4f16_i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.fptoui.sat.v4i32.v4f16(
; VIRT: define <2 x i64> @protected_fptosi_sat_v2f16_i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i64> @llvm.fptosi.sat.v2i64.v2f16(
; VIRT: define <2 x i64> @protected_fptoui_sat_v2f16_i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i64> @llvm.fptoui.sat.v2i64.v2f16(
; VIRT: define <3 x i8> @protected_fptosi_sat_v3f16_i8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <3 x i8> @llvm.fptosi.sat.v3i8.v3f16(
; VIRT: define <3 x i32> @protected_fptosi_sat_v3f16_i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <3 x i32> @llvm.fptosi.sat.v3i32.v3f16(
; VIRT: define <4 x i8> @protected_fptosi_sat_phi_v4f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i8> @llvm.fptosi.sat.v4i8.v4f16(
; VIRT: define <4 x i8> @protected_fptoui_sat_v4f16_neg({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i8> @llvm.fptoui.sat.v4i8.v4f16(
; VIRT: define <4 x i8> @protected_fptosi_sat_v4f16_ovf({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i8> @llvm.fptosi.sat.v4i8.v4f16(
; VIRT: define {{.*}} @unsupported_half_sat_scalar_no_fullfp16({{.*}} #[[UNSUPATTR:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_half_sat_scalar_fullfp16_disabled({{.*}} #[[UNSUPFEAT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_half_sat_vector_no_fullfp16({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_half_sat_vector_fullfp16_disabled({{.*}} #[[UNSUPFEAT]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_half_sat_i1({{.*}} #[[UNSUPCC:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_half_sat_v2i1({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_half_sat_bfloat({{.*}} #[[UNSUP_ARG:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_half_sat_fp128({{.*}} #[[UNSUP_ARG]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_half_sat_vec_bfloat({{.*}} #[[UNSUP_ARG]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_half_sat_scalable({{.*}} #[[UNSUP_SC:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_half_sat_src_wide({{.*}} #[[UNSUP_W:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_half_sat_dest_wide({{.*}} #[[UNSUP_DW:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_half_sat_fastcc({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_half_sat_musttail({{.*}} #[[UNSUP_MT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call i32 @llvm.fptosi.sat.i32.f16(
; VIRT: define {{.*}} @unsupported_half_sat_bundle({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call i32 @llvm.fptosi.sat.i32.f16({{.*}}[ "deopt"(i32 0) ]
; VIRT: define {{.*}} @unsupported_half_sat_constrained({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_half_sat_poison({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[PROT2]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT-DAG: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-DAG: attributes #[[UNSUPFEAT]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPFEAT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPCC]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_MT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_ARG]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_SC]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_W]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_DW]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
