; Restricted llvm.fptosi.sat / llvm.fptoui.sat on same-lane fixed
; f32/f64 sources to i8/i16/i32/i64 destinations (each side total
; 1..128 independently).  Replayed via the existing CallDescriptor
; and vector VReg frame.  Ordinary vector fptosi/fptoui instructions
; and scalar sat helpers stay unchanged.  Well-shaped half sat without
; last-token +fullfp16 is an unsupported-target-feature skip
; (independent surface: vmp-half-sat-convert-semantic.ll).
; bfloat/fp128, scalable,
; >128 on either side, i1 or other dest widths, fastcc, musttail,
; bundle, and constrained/other IDs stay out.  Well-formed LLVM
; overloads cannot express a lane mismatch.  Ordinary tail accepted and replayed as TCK_None.
; Host lli
; uses finite values only: in-range, negative unsigned clamp-to-zero,
; and overflow saturation.  No NaN/inf.  drop-unsupported strips only
; @unsupported_* so newly accepted dest widths stay live for llc/lli.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.ll > %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.live.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.ll > %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.live.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.s7.ll > %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.s7.live.ll > %t.o0.s7.host.ll
; RUN: lli -force-interpreter %t.o0.s7.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.s7.ll > %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.s7.live.ll > %t.o2.s7.host.ll
; RUN: lli -force-interpreter %t.o2.s7.host.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare <2 x i32> @llvm.fptosi.sat.v2i32.v2f32(<2 x float>)
declare <4 x i32> @llvm.fptoui.sat.v4i32.v4f32(<4 x float>)
declare <2 x i64> @llvm.fptosi.sat.v2i64.v2f64(<2 x double>)
declare <2 x i64> @llvm.fptoui.sat.v2i64.v2f64(<2 x double>)
declare <3 x i32> @llvm.fptosi.sat.v3i32.v3f32(<3 x float>)
declare <4 x i8> @llvm.fptosi.sat.v4i8.v4f32(<4 x float>)
declare <4 x i8> @llvm.fptoui.sat.v4i8.v4f32(<4 x float>)
declare <4 x i16> @llvm.fptosi.sat.v4i16.v4f32(<4 x float>)
declare <4 x i16> @llvm.fptoui.sat.v4i16.v4f32(<4 x float>)
declare <2 x i64> @llvm.fptosi.sat.v2i64.v2f32(<2 x float>)
declare <2 x i64> @llvm.fptoui.sat.v2i64.v2f32(<2 x float>)
declare <2 x i8> @llvm.fptosi.sat.v2i8.v2f64(<2 x double>)
declare <2 x i8> @llvm.fptoui.sat.v2i8.v2f64(<2 x double>)
declare <2 x i16> @llvm.fptosi.sat.v2i16.v2f64(<2 x double>)
declare <2 x i16> @llvm.fptoui.sat.v2i16.v2f64(<2 x double>)
declare <2 x i32> @llvm.fptosi.sat.v2i32.v2f64(<2 x double>)
declare <2 x i32> @llvm.fptoui.sat.v2i32.v2f64(<2 x double>)
declare <3 x i8> @llvm.fptosi.sat.v3i8.v3f32(<3 x float>)
declare <4 x i32> @llvm.fptosi.sat.v4i32.v4f16(<4 x half>)
declare <4 x i32> @llvm.fptosi.sat.v4i32.v4bf16(<4 x bfloat>)
declare <vscale x 4 x i32> @llvm.fptosi.sat.nxv4i32.nxv4f32(<vscale x 4 x float>)
declare <8 x i32> @llvm.fptosi.sat.v8i32.v8f32(<8 x float>)
declare <2 x i1> @llvm.fptosi.sat.v2i1.v2f32(<2 x float>)
declare <1 x i64> @llvm.fptosi.sat.v1i64.v1f128(<1 x fp128>)
declare <3 x i64> @llvm.fptosi.sat.v3i64.v3f32(<3 x float>)
declare <2 x i32> @llvm.fptoui.sat.v2i32.v2f32(<2 x float>)

declare <2 x half> @llvm.experimental.constrained.pow.v2f16(<2 x half>, <2 x half>, metadata, metadata)

define <2 x i32> @reference_fptosi_sat_v2f32(<2 x float> %a) {
entry:
  %r = call <2 x i32> @llvm.fptosi.sat.v2i32.v2f32(<2 x float> %a)
  ret <2 x i32> %r
}

define <2 x i32> @protected_fptosi_sat_v2f32(<2 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i32> @llvm.fptosi.sat.v2i32.v2f32(<2 x float> %a)
  ret <2 x i32> %r
}

define <4 x i32> @reference_fptoui_sat_v4f32(<4 x float> %a) {
entry:
  %r = call <4 x i32> @llvm.fptoui.sat.v4i32.v4f32(<4 x float> %a)
  ret <4 x i32> %r
}

define <4 x i32> @protected_fptoui_sat_v4f32(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.fptoui.sat.v4i32.v4f32(<4 x float> %a)
  ret <4 x i32> %r
}

define <2 x i64> @reference_fptosi_sat_v2f64(<2 x double> %a) {
entry:
  %r = call <2 x i64> @llvm.fptosi.sat.v2i64.v2f64(<2 x double> %a)
  ret <2 x i64> %r
}

define <2 x i64> @protected_fptosi_sat_v2f64(<2 x double> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.fptosi.sat.v2i64.v2f64(<2 x double> %a)
  ret <2 x i64> %r
}

define <2 x i64> @reference_fptoui_sat_v2f64(<2 x double> %a) {
entry:
  %r = call <2 x i64> @llvm.fptoui.sat.v2i64.v2f64(<2 x double> %a)
  ret <2 x i64> %r
}

define <2 x i64> @protected_fptoui_sat_v2f64(<2 x double> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.fptoui.sat.v2i64.v2f64(<2 x double> %a)
  ret <2 x i64> %r
}

define <3 x i32> @reference_fptosi_sat_v3f32(<3 x float> %a) {
entry:
  %r = call <3 x i32> @llvm.fptosi.sat.v3i32.v3f32(<3 x float> %a)
  ret <3 x i32> %r
}

define <3 x i32> @protected_fptosi_sat_v3f32(<3 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <3 x i32> @llvm.fptosi.sat.v3i32.v3f32(<3 x float> %a)
  ret <3 x i32> %r
}

define <2 x i32> @reference_fptosi_sat_phi_v2f32(<2 x float> %a, <2 x float> %b, i1 %c) {
entry:
  br i1 %c, label %left, label %right
left:
  %l = call <2 x i32> @llvm.fptosi.sat.v2i32.v2f32(<2 x float> %a)
  br label %join
right:
  %r = call <2 x i32> @llvm.fptosi.sat.v2i32.v2f32(<2 x float> %b)
  br label %join
join:
  %p = phi <2 x i32> [ %l, %left ], [ %r, %right ]
  ret <2 x i32> %p
}

define <2 x i32> @protected_fptosi_sat_phi_v2f32(<2 x float> %a, <2 x float> %b, i1 %c) noinline optnone {
entry:
  call void @hikari_vmp()
  br i1 %c, label %left, label %right
left:
  %l = call <2 x i32> @llvm.fptosi.sat.v2i32.v2f32(<2 x float> %a)
  br label %join
right:
  %r = call <2 x i32> @llvm.fptosi.sat.v2i32.v2f32(<2 x float> %b)
  br label %join
join:
  %p = phi <2 x i32> [ %l, %left ], [ %r, %right ]
  ret <2 x i32> %p
}

define <2 x i32> @reference_fptosi_sat_loop_v2f32(<2 x float> %a, i32 %n) {
entry:
  br label %hdr
hdr:
  %acc = phi <2 x float> [ %a, %entry ], [ %nxtf, %hdr ]
  %i = phi i32 [ 0, %entry ], [ %i.nxt, %hdr ]
  %cur = call <2 x i32> @llvm.fptosi.sat.v2i32.v2f32(<2 x float> %acc)
  %nxtf = fadd <2 x float> %acc, <float 1.000000e+00, float -1.000000e+00>
  %i.nxt = add i32 %i, 1
  %more = icmp ult i32 %i.nxt, %n
  br i1 %more, label %hdr, label %done
done:
  ret <2 x i32> %cur
}

define <2 x i32> @protected_fptosi_sat_loop_v2f32(<2 x float> %a, i32 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  br label %hdr
hdr:
  %acc = phi <2 x float> [ %a, %entry ], [ %nxtf, %hdr ]
  %i = phi i32 [ 0, %entry ], [ %i.nxt, %hdr ]
  %cur = call <2 x i32> @llvm.fptosi.sat.v2i32.v2f32(<2 x float> %acc)
  %nxtf = fadd <2 x float> %acc, <float 1.000000e+00, float -1.000000e+00>
  %i.nxt = add i32 %i, 1
  %more = icmp ult i32 %i.nxt, %n
  br i1 %more, label %hdr, label %done
done:
  ret <2 x i32> %cur
}

define <4 x i8> @reference_fptosi_sat_v4f32_i8(<4 x float> %a) {
entry:
  %r = call <4 x i8> @llvm.fptosi.sat.v4i8.v4f32(<4 x float> %a)
  ret <4 x i8> %r
}

define <4 x i8> @protected_fptosi_sat_v4f32_i8(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i8> @llvm.fptosi.sat.v4i8.v4f32(<4 x float> %a)
  ret <4 x i8> %r
}

define <4 x i8> @reference_fptoui_sat_v4f32_i8(<4 x float> %a) {
entry:
  %r = call <4 x i8> @llvm.fptoui.sat.v4i8.v4f32(<4 x float> %a)
  ret <4 x i8> %r
}

define <4 x i8> @protected_fptoui_sat_v4f32_i8(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i8> @llvm.fptoui.sat.v4i8.v4f32(<4 x float> %a)
  ret <4 x i8> %r
}

define <4 x i16> @reference_fptosi_sat_v4f32_i16(<4 x float> %a) {
entry:
  %r = call <4 x i16> @llvm.fptosi.sat.v4i16.v4f32(<4 x float> %a)
  ret <4 x i16> %r
}

define <4 x i16> @protected_fptosi_sat_v4f32_i16(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i16> @llvm.fptosi.sat.v4i16.v4f32(<4 x float> %a)
  ret <4 x i16> %r
}

define <4 x i16> @reference_fptoui_sat_v4f32_i16(<4 x float> %a) {
entry:
  %r = call <4 x i16> @llvm.fptoui.sat.v4i16.v4f32(<4 x float> %a)
  ret <4 x i16> %r
}

define <4 x i16> @protected_fptoui_sat_v4f32_i16(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i16> @llvm.fptoui.sat.v4i16.v4f32(<4 x float> %a)
  ret <4 x i16> %r
}

define <2 x i64> @reference_fptosi_sat_v2f32_i64(<2 x float> %a) {
entry:
  %r = call <2 x i64> @llvm.fptosi.sat.v2i64.v2f32(<2 x float> %a)
  ret <2 x i64> %r
}

define <2 x i64> @protected_fptosi_sat_v2f32_i64(<2 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.fptosi.sat.v2i64.v2f32(<2 x float> %a)
  ret <2 x i64> %r
}

define <2 x i64> @reference_fptoui_sat_v2f32_i64(<2 x float> %a) {
entry:
  %r = call <2 x i64> @llvm.fptoui.sat.v2i64.v2f32(<2 x float> %a)
  ret <2 x i64> %r
}

define <2 x i64> @protected_fptoui_sat_v2f32_i64(<2 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.fptoui.sat.v2i64.v2f32(<2 x float> %a)
  ret <2 x i64> %r
}

define <2 x i8> @reference_fptosi_sat_v2f64_i8(<2 x double> %a) {
entry:
  %r = call <2 x i8> @llvm.fptosi.sat.v2i8.v2f64(<2 x double> %a)
  ret <2 x i8> %r
}

define <2 x i8> @protected_fptosi_sat_v2f64_i8(<2 x double> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i8> @llvm.fptosi.sat.v2i8.v2f64(<2 x double> %a)
  ret <2 x i8> %r
}

define <2 x i8> @reference_fptoui_sat_v2f64_i8(<2 x double> %a) {
entry:
  %r = call <2 x i8> @llvm.fptoui.sat.v2i8.v2f64(<2 x double> %a)
  ret <2 x i8> %r
}

define <2 x i8> @protected_fptoui_sat_v2f64_i8(<2 x double> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i8> @llvm.fptoui.sat.v2i8.v2f64(<2 x double> %a)
  ret <2 x i8> %r
}

define <2 x i16> @reference_fptosi_sat_v2f64_i16(<2 x double> %a) {
entry:
  %r = call <2 x i16> @llvm.fptosi.sat.v2i16.v2f64(<2 x double> %a)
  ret <2 x i16> %r
}

define <2 x i16> @protected_fptosi_sat_v2f64_i16(<2 x double> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i16> @llvm.fptosi.sat.v2i16.v2f64(<2 x double> %a)
  ret <2 x i16> %r
}

define <2 x i16> @reference_fptoui_sat_v2f64_i16(<2 x double> %a) {
entry:
  %r = call <2 x i16> @llvm.fptoui.sat.v2i16.v2f64(<2 x double> %a)
  ret <2 x i16> %r
}

define <2 x i16> @protected_fptoui_sat_v2f64_i16(<2 x double> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i16> @llvm.fptoui.sat.v2i16.v2f64(<2 x double> %a)
  ret <2 x i16> %r
}

define <2 x i32> @reference_fptosi_sat_v2f64_i32(<2 x double> %a) {
entry:
  %r = call <2 x i32> @llvm.fptosi.sat.v2i32.v2f64(<2 x double> %a)
  ret <2 x i32> %r
}

define <2 x i32> @protected_fptosi_sat_v2f64_i32(<2 x double> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i32> @llvm.fptosi.sat.v2i32.v2f64(<2 x double> %a)
  ret <2 x i32> %r
}

define <2 x i32> @reference_fptoui_sat_v2f64_i32(<2 x double> %a) {
entry:
  %r = call <2 x i32> @llvm.fptoui.sat.v2i32.v2f64(<2 x double> %a)
  ret <2 x i32> %r
}

define <2 x i32> @protected_fptoui_sat_v2f64_i32(<2 x double> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i32> @llvm.fptoui.sat.v2i32.v2f64(<2 x double> %a)
  ret <2 x i32> %r
}

define <3 x i8> @reference_fptosi_sat_v3f32_i8(<3 x float> %a) {
entry:
  %r = call <3 x i8> @llvm.fptosi.sat.v3i8.v3f32(<3 x float> %a)
  ret <3 x i8> %r
}

define <3 x i8> @protected_fptosi_sat_v3f32_i8(<3 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <3 x i8> @llvm.fptosi.sat.v3i8.v3f32(<3 x float> %a)
  ret <3 x i8> %r
}

define <2 x i32> @reference_fptosi_sat_tail_v2f32(<2 x float> %a) {
entry:
  %r = tail call <2 x i32> @llvm.fptosi.sat.v2i32.v2f32(<2 x float> %a)
  ret <2 x i32> %r
}


; ----- negatives: selected, not virtualized -----

; Well-shaped half-vector sat without last-token +fullfp16 is a feature
; skip.  Do not add +fullfp16 here.
define <4 x i32> @unsupported_sat_half(<4 x half> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.fptosi.sat.v4i32.v4f16(<4 x half> %a)
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_sat_bfloat(<4 x bfloat> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.fptosi.sat.v4i32.v4bf16(<4 x bfloat> %a)
  ret <4 x i32> %r
}

define <vscale x 4 x i32> @unsupported_sat_scalable(<vscale x 4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.fptosi.sat.nxv4i32.nxv4f32(<vscale x 4 x float> %a)
  ret <vscale x 4 x i32> %r
}

define <8 x i32> @unsupported_sat_wide(<8 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i32> @llvm.fptosi.sat.v8i32.v8f32(<8 x float> %a)
  ret <8 x i32> %r
}

define <2 x i1> @unsupported_sat_i1(<2 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i1> @llvm.fptosi.sat.v2i1.v2f32(<2 x float> %a)
  ret <2 x i1> %r
}

define <1 x i64> @unsupported_sat_fp128(<1 x fp128> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <1 x i64> @llvm.fptosi.sat.v1i64.v1f128(<1 x fp128> %a)
  ret <1 x i64> %r
}

define <3 x i64> @unsupported_sat_dest_wide(<3 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <3 x i64> @llvm.fptosi.sat.v3i64.v3f32(<3 x float> %a)
  ret <3 x i64> %r
}

define <2 x i32> @unsupported_sat_fastcc(<2 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc <2 x i32> @llvm.fptosi.sat.v2i32.v2f32(<2 x float> %a)
  ret <2 x i32> %r
}

define <2 x i32> @unsupported_sat_musttail(<2 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call <2 x i32> @llvm.fptosi.sat.v2i32.v2f32(<2 x float> %a)
  ret <2 x i32> %r
}

define <2 x i32> @unsupported_sat_bundle(<2 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i32> @llvm.fptosi.sat.v2i32.v2f32(<2 x float> %a) [ "deopt"(i32 0) ]
  ret <2 x i32> %r
}

define <2 x half> @unsupported_sat_constrained(<2 x half> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x half> @llvm.experimental.constrained.pow.v2f16(<2 x half> %a, <2 x half> %a, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret <2 x half> %r
}

define i32 @vec_i32_mix(<4 x i32> %v) {
entry:
  %e0 = extractelement <4 x i32> %v, i32 0
  %e1 = extractelement <4 x i32> %v, i32 1
  %e2 = extractelement <4 x i32> %v, i32 2
  %e3 = extractelement <4 x i32> %v, i32 3
  %x0 = xor i32 %e0, %e1
  %x1 = xor i32 %e2, %e3
  %r = xor i32 %x0, %x1
  ret i32 %r
}

define i32 @vec_i8_mix4(<4 x i8> %v) {
entry:
  %e0 = extractelement <4 x i8> %v, i32 0
  %e1 = extractelement <4 x i8> %v, i32 1
  %e2 = extractelement <4 x i8> %v, i32 2
  %e3 = extractelement <4 x i8> %v, i32 3
  %z0 = zext i8 %e0 to i32
  %z1 = zext i8 %e1 to i32
  %z2 = zext i8 %e2 to i32
  %z3 = zext i8 %e3 to i32
  %x0 = xor i32 %z0, %z1
  %x1 = xor i32 %z2, %z3
  %r = xor i32 %x0, %x1
  ret i32 %r
}

define i32 @vec_i8_mix2(<2 x i8> %v) {
entry:
  %e0 = extractelement <2 x i8> %v, i32 0
  %e1 = extractelement <2 x i8> %v, i32 1
  %z0 = zext i8 %e0 to i32
  %z1 = zext i8 %e1 to i32
  %r = xor i32 %z0, %z1
  ret i32 %r
}

define i32 @vec_i16_mix4(<4 x i16> %v) {
entry:
  %e0 = extractelement <4 x i16> %v, i32 0
  %e1 = extractelement <4 x i16> %v, i32 1
  %e2 = extractelement <4 x i16> %v, i32 2
  %e3 = extractelement <4 x i16> %v, i32 3
  %z0 = zext i16 %e0 to i32
  %z1 = zext i16 %e1 to i32
  %z2 = zext i16 %e2 to i32
  %z3 = zext i16 %e3 to i32
  %x0 = xor i32 %z0, %z1
  %x1 = xor i32 %z2, %z3
  %r = xor i32 %x0, %x1
  ret i32 %r
}

define i32 @vec_i16_mix2(<2 x i16> %v) {
entry:
  %e0 = extractelement <2 x i16> %v, i32 0
  %e1 = extractelement <2 x i16> %v, i32 1
  %z0 = zext i16 %e0 to i32
  %z1 = zext i16 %e1 to i32
  %r = xor i32 %z0, %z1
  ret i32 %r
}

define i32 @vec_i32_mix2(<2 x i32> %v) {
entry:
  %e0 = extractelement <2 x i32> %v, i32 0
  %e1 = extractelement <2 x i32> %v, i32 1
  %r = xor i32 %e0, %e1
  ret i32 %r
}

define i32 @main() {
entry:
  %a2 = fadd <2 x float> <float 1.500000e+00, float -1.500000e+00>, zeroinitializer
  %er0 = call <2 x i32> @reference_fptosi_sat_v2f32(<2 x float> %a2)
  %ar0 = call <2 x i32> @protected_fptosi_sat_v2f32(<2 x float> %a2)
  %er0z = zext <2 x i32> %er0 to <2 x i64>
  %ar0z = zext <2 x i32> %ar0 to <2 x i64>
  %er0w = bitcast <2 x i64> %er0z to <4 x i32>
  %ar0w = bitcast <2 x i64> %ar0z to <4 x i32>
  %em0 = call i32 @vec_i32_mix(<4 x i32> %er0w)
  %am0 = call i32 @vec_i32_mix(<4 x i32> %ar0w)
  %m0 = icmp eq i32 %em0, %am0

  %b2 = fadd <2 x float> <float 3.000000e+09, float -3.000000e+09>, zeroinitializer
  %er0s = call <2 x i32> @reference_fptosi_sat_v2f32(<2 x float> %b2)
  %ar0s = call <2 x i32> @protected_fptosi_sat_v2f32(<2 x float> %b2)
  %er0sz = zext <2 x i32> %er0s to <2 x i64>
  %ar0sz = zext <2 x i32> %ar0s to <2 x i64>
  %er0sw = bitcast <2 x i64> %er0sz to <4 x i32>
  %ar0sw = bitcast <2 x i64> %ar0sz to <4 x i32>
  %em0s = call i32 @vec_i32_mix(<4 x i32> %er0sw)
  %am0s = call i32 @vec_i32_mix(<4 x i32> %ar0sw)
  %m0s = icmp eq i32 %em0s, %am0s

  %er0p = call <2 x i32> @reference_fptosi_sat_phi_v2f32(<2 x float> %a2, <2 x float> %b2, i1 true)
  %ar0p = call <2 x i32> @protected_fptosi_sat_phi_v2f32(<2 x float> %a2, <2 x float> %b2, i1 true)
  %er0pz = zext <2 x i32> %er0p to <2 x i64>
  %ar0pz = zext <2 x i32> %ar0p to <2 x i64>
  %er0pw = bitcast <2 x i64> %er0pz to <4 x i32>
  %ar0pw = bitcast <2 x i64> %ar0pz to <4 x i32>
  %em0p = call i32 @vec_i32_mix(<4 x i32> %er0pw)
  %am0p = call i32 @vec_i32_mix(<4 x i32> %ar0pw)
  %m0p = icmp eq i32 %em0p, %am0p

  %er0q = call <2 x i32> @reference_fptosi_sat_phi_v2f32(<2 x float> %a2, <2 x float> %b2, i1 false)
  %ar0q = call <2 x i32> @protected_fptosi_sat_phi_v2f32(<2 x float> %a2, <2 x float> %b2, i1 false)
  %er0qz = zext <2 x i32> %er0q to <2 x i64>
  %ar0qz = zext <2 x i32> %ar0q to <2 x i64>
  %er0qw = bitcast <2 x i64> %er0qz to <4 x i32>
  %ar0qw = bitcast <2 x i64> %ar0qz to <4 x i32>
  %em0q = call i32 @vec_i32_mix(<4 x i32> %er0qw)
  %am0q = call i32 @vec_i32_mix(<4 x i32> %ar0qw)
  %m0q = icmp eq i32 %em0q, %am0q

  %er0l = call <2 x i32> @reference_fptosi_sat_loop_v2f32(<2 x float> %a2, i32 2)
  %ar0l = call <2 x i32> @protected_fptosi_sat_loop_v2f32(<2 x float> %a2, i32 2)
  %er0lz = zext <2 x i32> %er0l to <2 x i64>
  %ar0lz = zext <2 x i32> %ar0l to <2 x i64>
  %er0lw = bitcast <2 x i64> %er0lz to <4 x i32>
  %ar0lw = bitcast <2 x i64> %ar0lz to <4 x i32>
  %em0l = call i32 @vec_i32_mix(<4 x i32> %er0lw)
  %am0l = call i32 @vec_i32_mix(<4 x i32> %ar0lw)
  %m0l = icmp eq i32 %em0l, %am0l

  %a4 = fadd <4 x float> <float 1.500000e+00, float -1.500000e+00, float 3.000000e+09, float 5.000000e+09>, zeroinitializer
  %er1 = call <4 x i32> @reference_fptoui_sat_v4f32(<4 x float> %a4)
  %ar1 = call <4 x i32> @protected_fptoui_sat_v4f32(<4 x float> %a4)
  %em1 = call i32 @vec_i32_mix(<4 x i32> %er1)
  %am1 = call i32 @vec_i32_mix(<4 x i32> %ar1)
  %m1 = icmp eq i32 %em1, %am1

  %ad = fadd <2 x double> <double 1.500000e+00, double 0x43E0000000000000>, zeroinitializer
  %er2 = call <2 x i64> @reference_fptosi_sat_v2f64(<2 x double> %ad)
  %ar2 = call <2 x i64> @protected_fptosi_sat_v2f64(<2 x double> %ad)
  %er2c = bitcast <2 x i64> %er2 to <4 x i32>
  %ar2c = bitcast <2 x i64> %ar2 to <4 x i32>
  %em2 = call i32 @vec_i32_mix(<4 x i32> %er2c)
  %am2 = call i32 @vec_i32_mix(<4 x i32> %ar2c)
  %m2 = icmp eq i32 %em2, %am2

  %ud = fadd <2 x double> <double -1.500000e+00, double 0x43F0000000000000>, zeroinitializer
  %er2u = call <2 x i64> @reference_fptoui_sat_v2f64(<2 x double> %ud)
  %ar2u = call <2 x i64> @protected_fptoui_sat_v2f64(<2 x double> %ud)
  %er2uc = bitcast <2 x i64> %er2u to <4 x i32>
  %ar2uc = bitcast <2 x i64> %ar2u to <4 x i32>
  %em2u = call i32 @vec_i32_mix(<4 x i32> %er2uc)
  %am2u = call i32 @vec_i32_mix(<4 x i32> %ar2uc)
  %m2u = icmp eq i32 %em2u, %am2u

  %a3 = fadd <3 x float> <float 1.500000e+00, float -2.250000e+00, float 4.000000e+00>, zeroinitializer
  %er3 = call <3 x i32> @reference_fptosi_sat_v3f32(<3 x float> %a3)
  %ar3 = call <3 x i32> @protected_fptosi_sat_v3f32(<3 x float> %a3)
  %e30 = extractelement <3 x i32> %er3, i32 0
  %e31 = extractelement <3 x i32> %er3, i32 1
  %e32 = extractelement <3 x i32> %er3, i32 2
  %a30 = extractelement <3 x i32> %ar3, i32 0
  %a31 = extractelement <3 x i32> %ar3, i32 1
  %a32 = extractelement <3 x i32> %ar3, i32 2
  %ex = xor i32 %e30, %e31
  %ey = xor i32 %ex, %e32
  %ax = xor i32 %a30, %a31
  %ay = xor i32 %ax, %a32
  %m3 = icmp eq i32 %ey, %ay

  %c8 = fadd <4 x float> <float 1.500000e+00, float -1.500000e+00, float 2.000000e+02, float -2.000000e+02>, zeroinitializer
  %er8s = call <4 x i8> @reference_fptosi_sat_v4f32_i8(<4 x float> %c8)
  %ar8s = call <4 x i8> @protected_fptosi_sat_v4f32_i8(<4 x float> %c8)
  %em8s = call i32 @vec_i8_mix4(<4 x i8> %er8s)
  %am8s = call i32 @vec_i8_mix4(<4 x i8> %ar8s)
  %m8s = icmp eq i32 %em8s, %am8s

  %c8u = fadd <4 x float> <float 1.500000e+00, float -1.500000e+00, float 3.000000e+02, float 0.000000e+00>, zeroinitializer
  %er8u = call <4 x i8> @reference_fptoui_sat_v4f32_i8(<4 x float> %c8u)
  %ar8u = call <4 x i8> @protected_fptoui_sat_v4f32_i8(<4 x float> %c8u)
  %em8u = call i32 @vec_i8_mix4(<4 x i8> %er8u)
  %am8u = call i32 @vec_i8_mix4(<4 x i8> %ar8u)
  %m8u = icmp eq i32 %em8u, %am8u

  %c16 = fadd <4 x float> <float 1.500000e+00, float -1.500000e+00, float 4.000000e+04, float -4.000000e+04>, zeroinitializer
  %er16s = call <4 x i16> @reference_fptosi_sat_v4f32_i16(<4 x float> %c16)
  %ar16s = call <4 x i16> @protected_fptosi_sat_v4f32_i16(<4 x float> %c16)
  %em16s = call i32 @vec_i16_mix4(<4 x i16> %er16s)
  %am16s = call i32 @vec_i16_mix4(<4 x i16> %ar16s)
  %m16s = icmp eq i32 %em16s, %am16s

  %c16u = fadd <4 x float> <float 1.500000e+00, float -1.500000e+00, float 7.000000e+04, float 0.000000e+00>, zeroinitializer
  %er16u = call <4 x i16> @reference_fptoui_sat_v4f32_i16(<4 x float> %c16u)
  %ar16u = call <4 x i16> @protected_fptoui_sat_v4f32_i16(<4 x float> %c16u)
  %em16u = call i32 @vec_i16_mix4(<4 x i16> %er16u)
  %am16u = call i32 @vec_i16_mix4(<4 x i16> %ar16u)
  %m16u = icmp eq i32 %em16u, %am16u

  %c64 = fadd <2 x float> <float 1.500000e+00, float -1.500000e+00>, zeroinitializer
  %er64s = call <2 x i64> @reference_fptosi_sat_v2f32_i64(<2 x float> %c64)
  %ar64s = call <2 x i64> @protected_fptosi_sat_v2f32_i64(<2 x float> %c64)
  %er64sc = bitcast <2 x i64> %er64s to <4 x i32>
  %ar64sc = bitcast <2 x i64> %ar64s to <4 x i32>
  %em64s = call i32 @vec_i32_mix(<4 x i32> %er64sc)
  %am64s = call i32 @vec_i32_mix(<4 x i32> %ar64sc)
  %m64s = icmp eq i32 %em64s, %am64s

  %c64u = fadd <2 x float> <float -1.500000e+00, float 3.000000e+09>, zeroinitializer
  %er64u = call <2 x i64> @reference_fptoui_sat_v2f32_i64(<2 x float> %c64u)
  %ar64u = call <2 x i64> @protected_fptoui_sat_v2f32_i64(<2 x float> %c64u)
  %er64uc = bitcast <2 x i64> %er64u to <4 x i32>
  %ar64uc = bitcast <2 x i64> %ar64u to <4 x i32>
  %em64u = call i32 @vec_i32_mix(<4 x i32> %er64uc)
  %am64u = call i32 @vec_i32_mix(<4 x i32> %ar64uc)
  %m64u = icmp eq i32 %em64u, %am64u

  %d8 = fadd <2 x double> <double 1.500000e+00, double -2.000000e+02>, zeroinitializer
  %erd8s = call <2 x i8> @reference_fptosi_sat_v2f64_i8(<2 x double> %d8)
  %ard8s = call <2 x i8> @protected_fptosi_sat_v2f64_i8(<2 x double> %d8)
  %emd8s = call i32 @vec_i8_mix2(<2 x i8> %erd8s)
  %amd8s = call i32 @vec_i8_mix2(<2 x i8> %ard8s)
  %md8s = icmp eq i32 %emd8s, %amd8s

  %d8u = fadd <2 x double> <double -1.500000e+00, double 3.000000e+02>, zeroinitializer
  %erd8u = call <2 x i8> @reference_fptoui_sat_v2f64_i8(<2 x double> %d8u)
  %ard8u = call <2 x i8> @protected_fptoui_sat_v2f64_i8(<2 x double> %d8u)
  %emd8u = call i32 @vec_i8_mix2(<2 x i8> %erd8u)
  %amd8u = call i32 @vec_i8_mix2(<2 x i8> %ard8u)
  %md8u = icmp eq i32 %emd8u, %amd8u

  %d16 = fadd <2 x double> <double 1.500000e+00, double -4.000000e+04>, zeroinitializer
  %erd16s = call <2 x i16> @reference_fptosi_sat_v2f64_i16(<2 x double> %d16)
  %ard16s = call <2 x i16> @protected_fptosi_sat_v2f64_i16(<2 x double> %d16)
  %emd16s = call i32 @vec_i16_mix2(<2 x i16> %erd16s)
  %amd16s = call i32 @vec_i16_mix2(<2 x i16> %ard16s)
  %md16s = icmp eq i32 %emd16s, %amd16s

  %d16u = fadd <2 x double> <double -1.500000e+00, double 7.000000e+04>, zeroinitializer
  %erd16u = call <2 x i16> @reference_fptoui_sat_v2f64_i16(<2 x double> %d16u)
  %ard16u = call <2 x i16> @protected_fptoui_sat_v2f64_i16(<2 x double> %d16u)
  %emd16u = call i32 @vec_i16_mix2(<2 x i16> %erd16u)
  %amd16u = call i32 @vec_i16_mix2(<2 x i16> %ard16u)
  %md16u = icmp eq i32 %emd16u, %amd16u

  %d32 = fadd <2 x double> <double 1.500000e+00, double 3.000000e+09>, zeroinitializer
  %erd32s = call <2 x i32> @reference_fptosi_sat_v2f64_i32(<2 x double> %d32)
  %ard32s = call <2 x i32> @protected_fptosi_sat_v2f64_i32(<2 x double> %d32)
  %emd32s = call i32 @vec_i32_mix2(<2 x i32> %erd32s)
  %amd32s = call i32 @vec_i32_mix2(<2 x i32> %ard32s)
  %md32s = icmp eq i32 %emd32s, %amd32s

  %d32u = fadd <2 x double> <double -1.500000e+00, double 5.000000e+09>, zeroinitializer
  %erd32u = call <2 x i32> @reference_fptoui_sat_v2f64_i32(<2 x double> %d32u)
  %ard32u = call <2 x i32> @protected_fptoui_sat_v2f64_i32(<2 x double> %d32u)
  %emd32u = call i32 @vec_i32_mix2(<2 x i32> %erd32u)
  %amd32u = call i32 @vec_i32_mix2(<2 x i32> %ard32u)
  %md32u = icmp eq i32 %emd32u, %amd32u

  %a3b = fadd <3 x float> <float 1.500000e+00, float -2.250000e+00, float 2.000000e+02>, zeroinitializer
  %er3b = call <3 x i8> @reference_fptosi_sat_v3f32_i8(<3 x float> %a3b)
  %ar3b = call <3 x i8> @protected_fptosi_sat_v3f32_i8(<3 x float> %a3b)
  %e3b0 = extractelement <3 x i8> %er3b, i32 0
  %e3b1 = extractelement <3 x i8> %er3b, i32 1
  %e3b2 = extractelement <3 x i8> %er3b, i32 2
  %a3b0 = extractelement <3 x i8> %ar3b, i32 0
  %a3b1 = extractelement <3 x i8> %ar3b, i32 1
  %a3b2 = extractelement <3 x i8> %ar3b, i32 2
  %ez0 = zext i8 %e3b0 to i32
  %ez1 = zext i8 %e3b1 to i32
  %ez2 = zext i8 %e3b2 to i32
  %az0 = zext i8 %a3b0 to i32
  %az1 = zext i8 %a3b1 to i32
  %az2 = zext i8 %a3b2 to i32
  %exb = xor i32 %ez0, %ez1
  %eyb = xor i32 %exb, %ez2
  %axb = xor i32 %az0, %az1
  %ayb = xor i32 %axb, %az2
  %m3b = icmp eq i32 %eyb, %ayb

  %t0 = and i1 %m0, %m0s
  %t1 = and i1 %m0p, %m0q
  %t2 = and i1 %m0l, %m1
  %t3 = and i1 %m2, %m2u
  %t4 = and i1 %t0, %t1
  %t5 = and i1 %t2, %t3
  %t6 = and i1 %m3, %m8s
  %t7 = and i1 %m8u, %m16s
  %t8 = and i1 %m16u, %m64s
  %t9 = and i1 %m64u, %md8s
  %t10 = and i1 %md8u, %md16s
  %t11 = and i1 %md16u, %md32s
  %t12 = and i1 %md32u, %m3b
  %u0 = and i1 %t4, %t5
  %u1 = and i1 %t6, %t7
  %u2 = and i1 %t8, %t9
  %u3 = and i1 %t10, %t11
  %u4 = and i1 %t12, %t12
  %v0 = and i1 %u0, %u1
  %v1 = and i1 %u2, %u3
  %ok = and i1 %v0, %v1
  %ok2 = and i1 %ok, %u4
  %code = select i1 %ok2, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_sat_half: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_sat_bfloat: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_sat_scalable: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_sat_wide: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_sat_i1: unsupported fptosi.sat
; SKIP-DAG: Skipping VMP on unsupported_sat_fp128: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_sat_dest_wide: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_sat_fastcc: unsupported fptosi.sat
; SKIP-DAG: Skipping VMP on unsupported_sat_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_sat_bundle: unsupported fptosi.sat
; SKIP-DAG: Skipping VMP on unsupported_sat_constrained: unsupported target feature
; SKIP-NOT: Skipping VMP on protected_fptosi_sat_v2f32:
; SKIP-NOT: Skipping VMP on protected_fptoui_sat_v4f32:
; SKIP-NOT: Skipping VMP on protected_fptosi_sat_v2f64:
; SKIP-NOT: Skipping VMP on protected_fptoui_sat_v2f64:
; SKIP-NOT: Skipping VMP on protected_fptosi_sat_v3f32:
; SKIP-NOT: Skipping VMP on protected_fptosi_sat_phi_v2f32:
; SKIP-NOT: Skipping VMP on protected_fptosi_sat_loop_v2f32:
; SKIP-NOT: Skipping VMP on protected_fptosi_sat_v4f32_i8:
; SKIP-NOT: Skipping VMP on protected_fptoui_sat_v4f32_i8:
; SKIP-NOT: Skipping VMP on protected_fptosi_sat_v4f32_i16:
; SKIP-NOT: Skipping VMP on protected_fptoui_sat_v4f32_i16:
; SKIP-NOT: Skipping VMP on protected_fptosi_sat_v2f32_i64:
; SKIP-NOT: Skipping VMP on protected_fptoui_sat_v2f32_i64:
; SKIP-NOT: Skipping VMP on protected_fptosi_sat_v2f64_i8:
; SKIP-NOT: Skipping VMP on protected_fptoui_sat_v2f64_i8:
; SKIP-NOT: Skipping VMP on protected_fptosi_sat_v2f64_i16:
; SKIP-NOT: Skipping VMP on protected_fptoui_sat_v2f64_i16:
; SKIP-NOT: Skipping VMP on protected_fptosi_sat_v2f64_i32:
; SKIP-NOT: Skipping VMP on protected_fptoui_sat_v2f64_i32:
; SKIP-NOT: Skipping VMP on protected_fptosi_sat_v3f32_i8:


; VIRT: define <2 x i32> @protected_fptosi_sat_v2f32({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i32> @llvm.fptosi.sat.v2i32.v2f32(
; VIRT: define <4 x i32> @protected_fptoui_sat_v4f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.fptoui.sat.v4i32.v4f32(
; VIRT: define <2 x i64> @protected_fptosi_sat_v2f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i64> @llvm.fptosi.sat.v2i64.v2f64(
; VIRT: define <2 x i64> @protected_fptoui_sat_v2f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i64> @llvm.fptoui.sat.v2i64.v2f64(
; VIRT: define <3 x i32> @protected_fptosi_sat_v3f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <3 x i32> @llvm.fptosi.sat.v3i32.v3f32(
; VIRT: define <2 x i32> @protected_fptosi_sat_phi_v2f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i32> @llvm.fptosi.sat.v2i32.v2f32(
; VIRT: define <2 x i32> @protected_fptosi_sat_loop_v2f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i32> @llvm.fptosi.sat.v2i32.v2f32(
; VIRT: define <4 x i8> @protected_fptosi_sat_v4f32_i8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i8> @llvm.fptosi.sat.v4i8.v4f32(
; VIRT: define <4 x i8> @protected_fptoui_sat_v4f32_i8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i8> @llvm.fptoui.sat.v4i8.v4f32(
; VIRT: define <4 x i16> @protected_fptosi_sat_v4f32_i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i16> @llvm.fptosi.sat.v4i16.v4f32(
; VIRT: define <4 x i16> @protected_fptoui_sat_v4f32_i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i16> @llvm.fptoui.sat.v4i16.v4f32(
; VIRT: define <2 x i64> @protected_fptosi_sat_v2f32_i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i64> @llvm.fptosi.sat.v2i64.v2f32(
; VIRT: define <2 x i64> @protected_fptoui_sat_v2f32_i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i64> @llvm.fptoui.sat.v2i64.v2f32(
; VIRT: define <2 x i8> @protected_fptosi_sat_v2f64_i8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i8> @llvm.fptosi.sat.v2i8.v2f64(
; VIRT: define <2 x i8> @protected_fptoui_sat_v2f64_i8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i8> @llvm.fptoui.sat.v2i8.v2f64(
; VIRT: define <2 x i16> @protected_fptosi_sat_v2f64_i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i16> @llvm.fptosi.sat.v2i16.v2f64(
; VIRT: define <2 x i16> @protected_fptoui_sat_v2f64_i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i16> @llvm.fptoui.sat.v2i16.v2f64(
; VIRT: define <2 x i32> @protected_fptosi_sat_v2f64_i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i32> @llvm.fptosi.sat.v2i32.v2f64(
; VIRT: define <2 x i32> @protected_fptoui_sat_v2f64_i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i32> @llvm.fptoui.sat.v2i32.v2f64(
; VIRT: define <3 x i8> @protected_fptosi_sat_v3f32_i8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <3 x i8> @llvm.fptosi.sat.v3i8.v3f32(
; VIRT: define {{.*}} @unsupported_sat_half({{.*}} #[[UNSUPATTR:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_sat_bfloat({{.*}} #[[UNSUP_ARG:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_sat_scalable({{.*}} #[[UNSUP_SC:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_sat_wide({{.*}} #[[UNSUP_W:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_sat_i1({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_sat_fp128({{.*}} #[[UNSUP_ARG]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_sat_dest_wide({{.*}} #[[UNSUP_W]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_sat_fastcc({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_sat_musttail({{.*}} #[[UNSUP_MT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call <2 x i32> @llvm.fptosi.sat.v2i32.v2f32(
; VIRT: define {{.*}} @unsupported_sat_bundle({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call <2 x i32> @llvm.fptosi.sat.v2i32.v2f32({{.*}}[ "deopt"(i32 0) ]
; VIRT: define {{.*}} @unsupported_sat_constrained({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_MT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_ARG]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_SC]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_W]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
