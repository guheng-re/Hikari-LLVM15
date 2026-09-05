; Restricted llvm.smul/umul/sdiv/udiv.fix and .fix.sat on identical
; fixed i8/i16/i32/i64 vectors whose total primitive width is exactly
; 64 or 128.  Scale is an i32 ConstantInt ImmArg replayed via
; CallDescriptor ImmediateArguments.  Replayed via the existing
; CallDescriptor and vector VReg frame.  Scalar fixed-point, vector
; bit/sat, half, and ordinary vector arithmetic stay unchanged.
; Leftover widths such as <3 x i32> (96) stay out: AArch64 llc crashes
; on those ISel paths.  i1/i128 elements, float/half/bfloat, scalable,
; >128, non-i32-constant scale, fastcc, musttail, bundle, constrained,
; and poison stay out.  C, exact non-vararg FTy, formal type equality,
; true i32 ImmArg scale.  Ordinary tail accepted and replayed as TCK_None;
; musttail, bundles, noreturn, returns_twice, and complex ABI stay out.  drop-unsupported strips
; only @unsupported_* so leftover widths never reach AArch64 llc.
;
; Host lli cannot execute these vector IDs: x86 ISel crashes, and the
; LLVM 15 interpreter cannot lower llvm.smul.fix.v* (Code generator
; does not support intrinsic).  Do not invent a host semantic oracle.
; FileCheck + AArch64 llc/readobj only.  @main still encodes the
; intended reference/protected comparisons for AArch64 object build.
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
declare void @ext_sret_byval(ptr sret(i32), ptr byval(i32))
declare <8 x i8> @llvm.smul.fix.v8i8(<8 x i8>, <8 x i8>, i32 immarg)
declare <8 x i8> @llvm.umul.fix.v8i8(<8 x i8>, <8 x i8>, i32 immarg)
declare <16 x i8> @llvm.smul.fix.v16i8(<16 x i8>, <16 x i8>, i32 immarg)
declare <4 x i16> @llvm.sdiv.fix.v4i16(<4 x i16>, <4 x i16>, i32 immarg)
declare <8 x i16> @llvm.udiv.fix.v8i16(<8 x i16>, <8 x i16>, i32 immarg)
declare <2 x i32> @llvm.smul.fix.sat.v2i32(<2 x i32>, <2 x i32>, i32 immarg)
declare <4 x i32> @llvm.smul.fix.v4i32(<4 x i32>, <4 x i32>, i32 immarg)
declare <4 x i32> @llvm.umul.fix.v4i32(<4 x i32>, <4 x i32>, i32 immarg)
declare <4 x i32> @llvm.sdiv.fix.v4i32(<4 x i32>, <4 x i32>, i32 immarg)
declare <4 x i32> @llvm.udiv.fix.v4i32(<4 x i32>, <4 x i32>, i32 immarg)
declare <4 x i32> @llvm.smul.fix.sat.v4i32(<4 x i32>, <4 x i32>, i32 immarg)
declare <4 x i32> @llvm.umul.fix.sat.v4i32(<4 x i32>, <4 x i32>, i32 immarg)
declare <4 x i32> @llvm.sdiv.fix.sat.v4i32(<4 x i32>, <4 x i32>, i32 immarg)
declare <4 x i32> @llvm.udiv.fix.sat.v4i32(<4 x i32>, <4 x i32>, i32 immarg)
declare <1 x i64> @llvm.sdiv.fix.sat.v1i64(<1 x i64>, <1 x i64>, i32 immarg)
declare <2 x i64> @llvm.udiv.fix.sat.v2i64(<2 x i64>, <2 x i64>, i32 immarg)
declare <8 x i1> @llvm.smul.fix.v8i1(<8 x i1>, <8 x i1>, i32 immarg)
declare <1 x i128> @llvm.smul.fix.v1i128(<1 x i128>, <1 x i128>, i32 immarg)
declare <4 x half> @llvm.experimental.constrained.fmul.v4f16(<4 x half>, <4 x half>, metadata, metadata)
declare <vscale x 4 x i32> @llvm.smul.fix.nxv4i32(<vscale x 4 x i32>, <vscale x 4 x i32>, i32 immarg)
declare <3 x i32> @llvm.smul.fix.v3i32(<3 x i32>, <3 x i32>, i32 immarg)
declare <4 x i8> @llvm.smul.fix.v4i8(<4 x i8>, <4 x i8>, i32 immarg)
declare <8 x i32> @llvm.smul.fix.v8i32(<8 x i32>, <8 x i32>, i32 immarg)

; ----- positives: all eight IDs on <4 x i32>, plus width/element reps -----

declare <4 x half> @llvm.experimental.constrained.pow.v4f16(<4 x half>, <4 x half>, metadata, metadata)

define <4 x i32> @reference_smul_fix_v4i32(<4 x i32> %a, <4 x i32> %b) {
entry:
  %r = call <4 x i32> @llvm.smul.fix.v4i32(<4 x i32> %a, <4 x i32> %b, i32 0)
  ret <4 x i32> %r
}

define <4 x i32> @protected_smul_fix_v4i32(<4 x i32> %a, <4 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.smul.fix.v4i32(<4 x i32> %a, <4 x i32> %b, i32 0)
  ret <4 x i32> %r
}

define <4 x i32> @reference_umul_fix_v4i32(<4 x i32> %a, <4 x i32> %b) {
entry:
  %r = call <4 x i32> @llvm.umul.fix.v4i32(<4 x i32> %a, <4 x i32> %b, i32 2)
  ret <4 x i32> %r
}

define <4 x i32> @protected_umul_fix_v4i32(<4 x i32> %a, <4 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.umul.fix.v4i32(<4 x i32> %a, <4 x i32> %b, i32 2)
  ret <4 x i32> %r
}

define <4 x i32> @reference_sdiv_fix_v4i32(<4 x i32> %a, <4 x i32> %b) {
entry:
  %r = call <4 x i32> @llvm.sdiv.fix.v4i32(<4 x i32> %a, <4 x i32> %b, i32 0)
  ret <4 x i32> %r
}

define <4 x i32> @protected_sdiv_fix_v4i32(<4 x i32> %a, <4 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.sdiv.fix.v4i32(<4 x i32> %a, <4 x i32> %b, i32 0)
  ret <4 x i32> %r
}

define <4 x i32> @reference_udiv_fix_v4i32(<4 x i32> %a, <4 x i32> %b) {
entry:
  %r = call <4 x i32> @llvm.udiv.fix.v4i32(<4 x i32> %a, <4 x i32> %b, i32 2)
  ret <4 x i32> %r
}

define <4 x i32> @protected_udiv_fix_v4i32(<4 x i32> %a, <4 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.udiv.fix.v4i32(<4 x i32> %a, <4 x i32> %b, i32 2)
  ret <4 x i32> %r
}

define <4 x i32> @reference_smul_fix_sat_v4i32(<4 x i32> %a, <4 x i32> %b) {
entry:
  %r = call <4 x i32> @llvm.smul.fix.sat.v4i32(<4 x i32> %a, <4 x i32> %b, i32 0)
  ret <4 x i32> %r
}

define <4 x i32> @protected_smul_fix_sat_v4i32(<4 x i32> %a, <4 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.smul.fix.sat.v4i32(<4 x i32> %a, <4 x i32> %b, i32 0)
  ret <4 x i32> %r
}

define <4 x i32> @reference_umul_fix_sat_v4i32(<4 x i32> %a, <4 x i32> %b) {
entry:
  %r = call <4 x i32> @llvm.umul.fix.sat.v4i32(<4 x i32> %a, <4 x i32> %b, i32 2)
  ret <4 x i32> %r
}

define <4 x i32> @protected_umul_fix_sat_v4i32(<4 x i32> %a, <4 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.umul.fix.sat.v4i32(<4 x i32> %a, <4 x i32> %b, i32 2)
  ret <4 x i32> %r
}

define <4 x i32> @reference_sdiv_fix_sat_v4i32(<4 x i32> %a, <4 x i32> %b) {
entry:
  %r = call <4 x i32> @llvm.sdiv.fix.sat.v4i32(<4 x i32> %a, <4 x i32> %b, i32 0)
  ret <4 x i32> %r
}

define <4 x i32> @protected_sdiv_fix_sat_v4i32(<4 x i32> %a, <4 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.sdiv.fix.sat.v4i32(<4 x i32> %a, <4 x i32> %b, i32 0)
  ret <4 x i32> %r
}

define <4 x i32> @reference_udiv_fix_sat_v4i32(<4 x i32> %a, <4 x i32> %b) {
entry:
  %r = call <4 x i32> @llvm.udiv.fix.sat.v4i32(<4 x i32> %a, <4 x i32> %b, i32 2)
  ret <4 x i32> %r
}

define <4 x i32> @protected_udiv_fix_sat_v4i32(<4 x i32> %a, <4 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.udiv.fix.sat.v4i32(<4 x i32> %a, <4 x i32> %b, i32 2)
  ret <4 x i32> %r
}

define <8 x i8> @reference_smul_fix_v8i8(<8 x i8> %a, <8 x i8> %b) {
entry:
  %r = call <8 x i8> @llvm.smul.fix.v8i8(<8 x i8> %a, <8 x i8> %b, i32 0)
  ret <8 x i8> %r
}

define <8 x i8> @protected_smul_fix_v8i8(<8 x i8> %a, <8 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i8> @llvm.smul.fix.v8i8(<8 x i8> %a, <8 x i8> %b, i32 0)
  ret <8 x i8> %r
}

define <16 x i8> @reference_smul_fix_v16i8(<16 x i8> %a, <16 x i8> %b) {
entry:
  %r = call <16 x i8> @llvm.smul.fix.v16i8(<16 x i8> %a, <16 x i8> %b, i32 2)
  ret <16 x i8> %r
}

define <16 x i8> @protected_smul_fix_v16i8(<16 x i8> %a, <16 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <16 x i8> @llvm.smul.fix.v16i8(<16 x i8> %a, <16 x i8> %b, i32 2)
  ret <16 x i8> %r
}

define <4 x i16> @reference_sdiv_fix_v4i16(<4 x i16> %a, <4 x i16> %b) {
entry:
  %r = call <4 x i16> @llvm.sdiv.fix.v4i16(<4 x i16> %a, <4 x i16> %b, i32 0)
  ret <4 x i16> %r
}

define <4 x i16> @protected_sdiv_fix_v4i16(<4 x i16> %a, <4 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i16> @llvm.sdiv.fix.v4i16(<4 x i16> %a, <4 x i16> %b, i32 0)
  ret <4 x i16> %r
}

define <8 x i16> @reference_udiv_fix_v8i16(<8 x i16> %a, <8 x i16> %b) {
entry:
  %r = call <8 x i16> @llvm.udiv.fix.v8i16(<8 x i16> %a, <8 x i16> %b, i32 2)
  ret <8 x i16> %r
}

define <8 x i16> @protected_udiv_fix_v8i16(<8 x i16> %a, <8 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i16> @llvm.udiv.fix.v8i16(<8 x i16> %a, <8 x i16> %b, i32 2)
  ret <8 x i16> %r
}

define <2 x i32> @reference_smul_fix_sat_v2i32(<2 x i32> %a, <2 x i32> %b) {
entry:
  %r = call <2 x i32> @llvm.smul.fix.sat.v2i32(<2 x i32> %a, <2 x i32> %b, i32 0)
  ret <2 x i32> %r
}

define <2 x i32> @protected_smul_fix_sat_v2i32(<2 x i32> %a, <2 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i32> @llvm.smul.fix.sat.v2i32(<2 x i32> %a, <2 x i32> %b, i32 0)
  ret <2 x i32> %r
}

define <1 x i64> @reference_sdiv_fix_sat_v1i64(<1 x i64> %a, <1 x i64> %b) {
entry:
  %r = call <1 x i64> @llvm.sdiv.fix.sat.v1i64(<1 x i64> %a, <1 x i64> %b, i32 0)
  ret <1 x i64> %r
}

define <1 x i64> @protected_sdiv_fix_sat_v1i64(<1 x i64> %a, <1 x i64> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <1 x i64> @llvm.sdiv.fix.sat.v1i64(<1 x i64> %a, <1 x i64> %b, i32 0)
  ret <1 x i64> %r
}

define <2 x i64> @reference_udiv_fix_sat_v2i64(<2 x i64> %a, <2 x i64> %b) {
entry:
  %r = call <2 x i64> @llvm.udiv.fix.sat.v2i64(<2 x i64> %a, <2 x i64> %b, i32 2)
  ret <2 x i64> %r
}

define <2 x i64> @protected_udiv_fix_sat_v2i64(<2 x i64> %a, <2 x i64> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.udiv.fix.sat.v2i64(<2 x i64> %a, <2 x i64> %b, i32 2)
  ret <2 x i64> %r
}

define <4 x i32> @reference_smul_fix_phi_v4i32(<4 x i32> %a, <4 x i32> %b, i1 %c) {
entry:
  br i1 %c, label %left, label %right
left:
  %l = call <4 x i32> @llvm.smul.fix.v4i32(<4 x i32> %a, <4 x i32> %b, i32 0)
  br label %join
right:
  %r = call <4 x i32> @llvm.umul.fix.v4i32(<4 x i32> %a, <4 x i32> %b, i32 2)
  br label %join
join:
  %p = phi <4 x i32> [ %l, %left ], [ %r, %right ]
  ret <4 x i32> %p
}

define <4 x i32> @protected_smul_fix_phi_v4i32(<4 x i32> %a, <4 x i32> %b, i1 %c) noinline optnone {
entry:
  call void @hikari_vmp()
  br i1 %c, label %left, label %right
left:
  %l = call <4 x i32> @llvm.smul.fix.v4i32(<4 x i32> %a, <4 x i32> %b, i32 0)
  br label %join
right:
  %r = call <4 x i32> @llvm.umul.fix.v4i32(<4 x i32> %a, <4 x i32> %b, i32 2)
  br label %join
join:
  %p = phi <4 x i32> [ %l, %left ], [ %r, %right ]
  ret <4 x i32> %p
}

define <4 x i32> @reference_smul_fix_loop_v4i32(<4 x i32> %a, i32 %n) {
entry:
  br label %hdr
hdr:
  %acc = phi <4 x i32> [ %a, %entry ], [ %nxt, %hdr ]
  %i = phi i32 [ 0, %entry ], [ %i.nxt, %hdr ]
  %cur = call <4 x i32> @llvm.smul.fix.v4i32(<4 x i32> %acc, <4 x i32> <i32 1, i32 1, i32 1, i32 1>, i32 0)
  %nxt = add <4 x i32> %acc, <i32 1, i32 1, i32 1, i32 1>
  %i.nxt = add i32 %i, 1
  %more = icmp ult i32 %i.nxt, %n
  br i1 %more, label %hdr, label %done
done:
  ret <4 x i32> %cur
}

define <4 x i32> @protected_smul_fix_loop_v4i32(<4 x i32> %a, i32 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  br label %hdr
hdr:
  %acc = phi <4 x i32> [ %a, %entry ], [ %nxt, %hdr ]
  %i = phi i32 [ 0, %entry ], [ %i.nxt, %hdr ]
  %cur = call <4 x i32> @llvm.smul.fix.v4i32(<4 x i32> %acc, <4 x i32> <i32 1, i32 1, i32 1, i32 1>, i32 0)
  %nxt = add <4 x i32> %acc, <i32 1, i32 1, i32 1, i32 1>
  %i.nxt = add i32 %i, 1
  %more = icmp ult i32 %i.nxt, %n
  br i1 %more, label %hdr, label %done
done:
  ret <4 x i32> %cur
}

; ----- negatives: selected, not virtualized -----


define <4 x i32> @unsupported_fix_malformed(<4 x i32> %a, <4 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.smul.fix.v4i32(<4 x i32> %a, <4 x i32> %b, i32 0) noreturn
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_fix_returns_twice(<4 x i32> %a, <4 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.smul.fix.v4i32(<4 x i32> %a, <4 x i32> %b, i32 0) returns_twice
  ret <4 x i32> %r
}

define void @unsupported_fix_sret(ptr sret(i32) %p, ptr byval(i32) %q) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @ext_sret_byval(ptr sret(i32) %p, ptr byval(i32) %q)
  ret void
}

define <8 x i1> @unsupported_fix_i1(<8 x i1> %a, <8 x i1> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i1> @llvm.smul.fix.v8i1(<8 x i1> %a, <8 x i1> %b, i32 0)
  ret <8 x i1> %r
}

define <1 x i128> @unsupported_fix_i128(<1 x i128> %a, <1 x i128> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <1 x i128> @llvm.smul.fix.v1i128(<1 x i128> %a, <1 x i128> %b, i32 0)
  ret <1 x i128> %r
}

define <4 x half> @unsupported_fix_half(<4 x half> %a, <4 x half> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x half> @llvm.experimental.constrained.fmul.v4f16(<4 x half> %a, <4 x half> %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret <4 x half> %r
}

define <4 x bfloat> @unsupported_fix_bfloat(<4 x bfloat> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  ret <4 x bfloat> %a
}

define <vscale x 4 x i32> @unsupported_fix_scalable(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.smul.fix.nxv4i32(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b, i32 0)
  ret <vscale x 4 x i32> %r
}

; Critical: leftover 96-bit must skip.  AArch64 llc crashes on this width.
define <3 x i32> @unsupported_fix_v3i32(<3 x i32> %a, <3 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <3 x i32> @llvm.smul.fix.v3i32(<3 x i32> %a, <3 x i32> %b, i32 0)
  ret <3 x i32> %r
}

define <4 x i8> @unsupported_fix_v4i8(<4 x i8> %a, <4 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i8> @llvm.smul.fix.v4i8(<4 x i8> %a, <4 x i8> %b, i32 0)
  ret <4 x i8> %r
}

define <8 x i32> @unsupported_fix_wide(<8 x i32> %a, <8 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i32> @llvm.smul.fix.v8i32(<8 x i32> %a, <8 x i32> %b, i32 0)
  ret <8 x i32> %r
}

define <4 x i32> @unsupported_fix_fastcc(<4 x i32> %a, <4 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc <4 x i32> @llvm.smul.fix.v4i32(<4 x i32> %a, <4 x i32> %b, i32 0)
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_fix_musttail(<4 x i32> %a, <4 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call <4 x i32> @llvm.smul.fix.v4i32(<4 x i32> %a, <4 x i32> %b, i32 0)
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_fix_bundle(<4 x i32> %a, <4 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.smul.fix.v4i32(<4 x i32> %a, <4 x i32> %b, i32 0) [ "deopt"(i32 0) ]
  ret <4 x i32> %r
}

define <4 x half> @unsupported_fix_constrained(<4 x half> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x half> @llvm.experimental.constrained.pow.v4f16(<4 x half> %a, <4 x half> %a, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret <4 x half> %r
}

define <4 x i32> @unsupported_fix_poison(<4 x i32> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.smul.fix.v4i32(<4 x i32> poison, <4 x i32> %a, i32 0)
  ret <4 x i32> %r
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

define i32 @main() {
entry:
  %a32 = add <4 x i32> <i32 2, i32 3, i32 4, i32 5>, zeroinitializer
  %b32 = add <4 x i32> <i32 3, i32 2, i32 1, i32 4>, zeroinitializer
  %er0 = call <4 x i32> @reference_smul_fix_v4i32(<4 x i32> %a32, <4 x i32> %b32)
  %ar0 = call <4 x i32> @protected_smul_fix_v4i32(<4 x i32> %a32, <4 x i32> %b32)
  %em0 = call i32 @vec_i32_mix(<4 x i32> %er0)
  %am0 = call i32 @vec_i32_mix(<4 x i32> %ar0)
  %m0 = icmp eq i32 %em0, %am0

  %er1 = call <4 x i32> @reference_umul_fix_v4i32(<4 x i32> %a32, <4 x i32> %b32)
  %ar1 = call <4 x i32> @protected_umul_fix_v4i32(<4 x i32> %a32, <4 x i32> %b32)
  %em1 = call i32 @vec_i32_mix(<4 x i32> %er1)
  %am1 = call i32 @vec_i32_mix(<4 x i32> %ar1)
  %m1 = icmp eq i32 %em1, %am1

  %er2 = call <4 x i32> @reference_sdiv_fix_v4i32(<4 x i32> %a32, <4 x i32> %b32)
  %ar2 = call <4 x i32> @protected_sdiv_fix_v4i32(<4 x i32> %a32, <4 x i32> %b32)
  %em2 = call i32 @vec_i32_mix(<4 x i32> %er2)
  %am2 = call i32 @vec_i32_mix(<4 x i32> %ar2)
  %m2 = icmp eq i32 %em2, %am2

  %er3 = call <4 x i32> @reference_udiv_fix_v4i32(<4 x i32> %a32, <4 x i32> %b32)
  %ar3 = call <4 x i32> @protected_udiv_fix_v4i32(<4 x i32> %a32, <4 x i32> %b32)
  %em3 = call i32 @vec_i32_mix(<4 x i32> %er3)
  %am3 = call i32 @vec_i32_mix(<4 x i32> %ar3)
  %m3 = icmp eq i32 %em3, %am3

  %er4 = call <4 x i32> @reference_smul_fix_sat_v4i32(<4 x i32> %a32, <4 x i32> %b32)
  %ar4 = call <4 x i32> @protected_smul_fix_sat_v4i32(<4 x i32> %a32, <4 x i32> %b32)
  %em4 = call i32 @vec_i32_mix(<4 x i32> %er4)
  %am4 = call i32 @vec_i32_mix(<4 x i32> %ar4)
  %m4 = icmp eq i32 %em4, %am4

  %er5 = call <4 x i32> @reference_umul_fix_sat_v4i32(<4 x i32> %a32, <4 x i32> %b32)
  %ar5 = call <4 x i32> @protected_umul_fix_sat_v4i32(<4 x i32> %a32, <4 x i32> %b32)
  %em5 = call i32 @vec_i32_mix(<4 x i32> %er5)
  %am5 = call i32 @vec_i32_mix(<4 x i32> %ar5)
  %m5 = icmp eq i32 %em5, %am5

  %er6 = call <4 x i32> @reference_sdiv_fix_sat_v4i32(<4 x i32> %a32, <4 x i32> %b32)
  %ar6 = call <4 x i32> @protected_sdiv_fix_sat_v4i32(<4 x i32> %a32, <4 x i32> %b32)
  %em6 = call i32 @vec_i32_mix(<4 x i32> %er6)
  %am6 = call i32 @vec_i32_mix(<4 x i32> %ar6)
  %m6 = icmp eq i32 %em6, %am6

  %er7 = call <4 x i32> @reference_udiv_fix_sat_v4i32(<4 x i32> %a32, <4 x i32> %b32)
  %ar7 = call <4 x i32> @protected_udiv_fix_sat_v4i32(<4 x i32> %a32, <4 x i32> %b32)
  %em7 = call i32 @vec_i32_mix(<4 x i32> %er7)
  %am7 = call i32 @vec_i32_mix(<4 x i32> %ar7)
  %m7 = icmp eq i32 %em7, %am7

  %a8 = add <8 x i8> <i8 2, i8 3, i8 4, i8 5, i8 1, i8 2, i8 3, i8 4>, zeroinitializer
  %b8 = add <8 x i8> <i8 2, i8 1, i8 2, i8 1, i8 3, i8 2, i8 1, i8 2>, zeroinitializer
  %er8 = call <8 x i8> @reference_smul_fix_v8i8(<8 x i8> %a8, <8 x i8> %b8)
  %ar8 = call <8 x i8> @protected_smul_fix_v8i8(<8 x i8> %a8, <8 x i8> %b8)
  %er8z = zext <8 x i8> %er8 to <8 x i16>
  %ar8z = zext <8 x i8> %ar8 to <8 x i16>
  %er8c = bitcast <8 x i16> %er8z to <4 x i32>
  %ar8c = bitcast <8 x i16> %ar8z to <4 x i32>
  %em8 = call i32 @vec_i32_mix(<4 x i32> %er8c)
  %am8 = call i32 @vec_i32_mix(<4 x i32> %ar8c)
  %m8 = icmp eq i32 %em8, %am8

  %a16w = add <16 x i8> <i8 1, i8 2, i8 1, i8 2, i8 1, i8 2, i8 1, i8 2, i8 1, i8 2, i8 1, i8 2, i8 1, i8 2, i8 1, i8 2>, zeroinitializer
  %b16w = add <16 x i8> <i8 2, i8 2, i8 2, i8 2, i8 2, i8 2, i8 2, i8 2, i8 2, i8 2, i8 2, i8 2, i8 2, i8 2, i8 2, i8 2>, zeroinitializer
  %er9 = call <16 x i8> @reference_smul_fix_v16i8(<16 x i8> %a16w, <16 x i8> %b16w)
  %ar9 = call <16 x i8> @protected_smul_fix_v16i8(<16 x i8> %a16w, <16 x i8> %b16w)
  %er9c = bitcast <16 x i8> %er9 to <4 x i32>
  %ar9c = bitcast <16 x i8> %ar9 to <4 x i32>
  %em9 = call i32 @vec_i32_mix(<4 x i32> %er9c)
  %am9 = call i32 @vec_i32_mix(<4 x i32> %ar9c)
  %m9 = icmp eq i32 %em9, %am9

  %a16 = add <4 x i16> <i16 8, i16 12, i16 16, i16 20>, zeroinitializer
  %b16 = add <4 x i16> <i16 2, i16 3, i16 4, i16 5>, zeroinitializer
  %er10 = call <4 x i16> @reference_sdiv_fix_v4i16(<4 x i16> %a16, <4 x i16> %b16)
  %ar10 = call <4 x i16> @protected_sdiv_fix_v4i16(<4 x i16> %a16, <4 x i16> %b16)
  %er10c = bitcast <4 x i16> %er10 to <2 x i32>
  %ar10c = bitcast <4 x i16> %ar10 to <2 x i32>
  %e100 = extractelement <2 x i32> %er10c, i32 0
  %e101 = extractelement <2 x i32> %er10c, i32 1
  %a100 = extractelement <2 x i32> %ar10c, i32 0
  %a101 = extractelement <2 x i32> %ar10c, i32 1
  %ex10 = xor i32 %e100, %e101
  %ax10 = xor i32 %a100, %a101
  %m10 = icmp eq i32 %ex10, %ax10

  %a16b = add <8 x i16> <i16 8, i16 12, i16 16, i16 20, i16 24, i16 28, i16 32, i16 36>, zeroinitializer
  %b16b = add <8 x i16> <i16 2, i16 2, i16 2, i16 2, i16 2, i16 2, i16 2, i16 2>, zeroinitializer
  %er11 = call <8 x i16> @reference_udiv_fix_v8i16(<8 x i16> %a16b, <8 x i16> %b16b)
  %ar11 = call <8 x i16> @protected_udiv_fix_v8i16(<8 x i16> %a16b, <8 x i16> %b16b)
  %er11c = bitcast <8 x i16> %er11 to <4 x i32>
  %ar11c = bitcast <8 x i16> %ar11 to <4 x i32>
  %em11 = call i32 @vec_i32_mix(<4 x i32> %er11c)
  %am11 = call i32 @vec_i32_mix(<4 x i32> %ar11c)
  %m11 = icmp eq i32 %em11, %am11

  %a2 = add <2 x i32> <i32 3, i32 4>, zeroinitializer
  %b2 = add <2 x i32> <i32 2, i32 2>, zeroinitializer
  %er12 = call <2 x i32> @reference_smul_fix_sat_v2i32(<2 x i32> %a2, <2 x i32> %b2)
  %ar12 = call <2 x i32> @protected_smul_fix_sat_v2i32(<2 x i32> %a2, <2 x i32> %b2)
  %e120 = extractelement <2 x i32> %er12, i32 0
  %e121 = extractelement <2 x i32> %er12, i32 1
  %a120 = extractelement <2 x i32> %ar12, i32 0
  %a121 = extractelement <2 x i32> %ar12, i32 1
  %ex12 = xor i32 %e120, %e121
  %ax12 = xor i32 %a120, %a121
  %m12 = icmp eq i32 %ex12, %ax12

  %a64 = add <1 x i64> <i64 12>, zeroinitializer
  %b64 = add <1 x i64> <i64 3>, zeroinitializer
  %er13 = call <1 x i64> @reference_sdiv_fix_sat_v1i64(<1 x i64> %a64, <1 x i64> %b64)
  %ar13 = call <1 x i64> @protected_sdiv_fix_sat_v1i64(<1 x i64> %a64, <1 x i64> %b64)
  %e13 = extractelement <1 x i64> %er13, i32 0
  %a13v = extractelement <1 x i64> %ar13, i32 0
  %m13 = icmp eq i64 %e13, %a13v

  %a64b = add <2 x i64> <i64 16, i64 20>, zeroinitializer
  %b64b = add <2 x i64> <i64 2, i64 4>, zeroinitializer
  %er14 = call <2 x i64> @reference_udiv_fix_sat_v2i64(<2 x i64> %a64b, <2 x i64> %b64b)
  %ar14 = call <2 x i64> @protected_udiv_fix_sat_v2i64(<2 x i64> %a64b, <2 x i64> %b64b)
  %e140 = extractelement <2 x i64> %er14, i32 0
  %e141 = extractelement <2 x i64> %er14, i32 1
  %a140 = extractelement <2 x i64> %ar14, i32 0
  %a141 = extractelement <2 x i64> %ar14, i32 1
  %ex14 = xor i64 %e140, %e141
  %ax14 = xor i64 %a140, %a141
  %m14 = icmp eq i64 %ex14, %ax14

  %er16 = call <4 x i32> @reference_smul_fix_phi_v4i32(<4 x i32> %a32, <4 x i32> %b32, i1 true)
  %ar16 = call <4 x i32> @protected_smul_fix_phi_v4i32(<4 x i32> %a32, <4 x i32> %b32, i1 true)
  %em16 = call i32 @vec_i32_mix(<4 x i32> %er16)
  %am16 = call i32 @vec_i32_mix(<4 x i32> %ar16)
  %m16 = icmp eq i32 %em16, %am16

  %er17 = call <4 x i32> @reference_smul_fix_loop_v4i32(<4 x i32> %a32, i32 2)
  %ar17 = call <4 x i32> @protected_smul_fix_loop_v4i32(<4 x i32> %a32, i32 2)
  %em17 = call i32 @vec_i32_mix(<4 x i32> %er17)
  %am17 = call i32 @vec_i32_mix(<4 x i32> %ar17)
  %m17 = icmp eq i32 %em17, %am17

  %t0 = and i1 %m0, %m1
  %t1 = and i1 %m2, %m3
  %t2 = and i1 %m4, %m5
  %t3 = and i1 %m6, %m7
  %t4 = and i1 %m8, %m9
  %t5 = and i1 %m10, %m11
  %t6 = and i1 %m12, %m13
  %t7 = and i1 %m14, %m14
  %t8 = and i1 %m16, %m17
  %u0 = and i1 %t0, %t1
  %u1 = and i1 %t2, %t3
  %u2 = and i1 %t4, %t5
  %u3 = and i1 %t6, %t7
  %v0 = and i1 %u0, %u1
  %v1 = and i1 %u2, %u3
  %ok = and i1 %v0, %v1
  %ok2 = and i1 %ok, %t8
  %code = select i1 %ok2, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_fix_i1: unsupported smul.fix
; SKIP-DAG: Skipping VMP on unsupported_fix_i128: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_fix_half: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_fix_bfloat: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_fix_scalable: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_fix_v3i32: unsupported smul.fix
; SKIP-DAG: Skipping VMP on unsupported_fix_v4i8: unsupported smul.fix
; SKIP-DAG: Skipping VMP on unsupported_fix_wide: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_fix_fastcc: unsupported smul.fix
; SKIP-DAG: Skipping VMP on unsupported_fix_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_fix_bundle: unsupported smul.fix
; SKIP-DAG: Skipping VMP on unsupported_fix_constrained: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_fix_poison: unsupported smul.fix
; SKIP-DAG: Skipping VMP on unsupported_fix_malformed: unsupported smul.fix
; SKIP-DAG: Skipping VMP on unsupported_fix_returns_twice: unsupported smul.fix
; SKIP-DAG: Skipping VMP on unsupported_fix_sret: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_smul_fix_v4i32:
; SKIP-NOT: Skipping VMP on protected_umul_fix_v4i32:
; SKIP-NOT: Skipping VMP on protected_sdiv_fix_v4i32:
; SKIP-NOT: Skipping VMP on protected_udiv_fix_v4i32:
; SKIP-NOT: Skipping VMP on protected_smul_fix_sat_v4i32:
; SKIP-NOT: Skipping VMP on protected_umul_fix_sat_v4i32:
; SKIP-NOT: Skipping VMP on protected_sdiv_fix_sat_v4i32:
; SKIP-NOT: Skipping VMP on protected_udiv_fix_sat_v4i32:
; SKIP-NOT: Skipping VMP on protected_smul_fix_v8i8:
; SKIP-NOT: Skipping VMP on protected_smul_fix_v16i8:
; SKIP-NOT: Skipping VMP on protected_sdiv_fix_v4i16:
; SKIP-NOT: Skipping VMP on protected_udiv_fix_v8i16:
; SKIP-NOT: Skipping VMP on protected_smul_fix_sat_v2i32:
; SKIP-NOT: Skipping VMP on protected_sdiv_fix_sat_v1i64:
; SKIP-NOT: Skipping VMP on protected_udiv_fix_sat_v2i64:
; SKIP-NOT: Skipping VMP on protected_smul_fix_phi_v4i32:
; SKIP-NOT: Skipping VMP on protected_smul_fix_loop_v4i32:

; VIRT: define <4 x i32> @protected_smul_fix_v4i32({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.smul.fix.v4i32({{.*}}, i32 0)
; VIRT: define <4 x i32> @protected_umul_fix_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.umul.fix.v4i32({{.*}}, i32 2)
; VIRT: define <4 x i32> @protected_sdiv_fix_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.sdiv.fix.v4i32({{.*}}, i32 0)
; VIRT: define <4 x i32> @protected_udiv_fix_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.udiv.fix.v4i32({{.*}}, i32 2)
; VIRT: define <4 x i32> @protected_smul_fix_sat_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.smul.fix.sat.v4i32({{.*}}, i32 0)
; VIRT: define <4 x i32> @protected_umul_fix_sat_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.umul.fix.sat.v4i32({{.*}}, i32 2)
; VIRT: define <4 x i32> @protected_sdiv_fix_sat_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.sdiv.fix.sat.v4i32({{.*}}, i32 0)
; VIRT: define <4 x i32> @protected_udiv_fix_sat_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.udiv.fix.sat.v4i32({{.*}}, i32 2)
; VIRT: define <8 x i8> @protected_smul_fix_v8i8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x i8> @llvm.smul.fix.v8i8({{.*}}, i32 0)
; VIRT: define <16 x i8> @protected_smul_fix_v16i8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <16 x i8> @llvm.smul.fix.v16i8({{.*}}, i32 2)
; VIRT: define <4 x i16> @protected_sdiv_fix_v4i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i16> @llvm.sdiv.fix.v4i16({{.*}}, i32 0)
; VIRT: define <8 x i16> @protected_udiv_fix_v8i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x i16> @llvm.udiv.fix.v8i16({{.*}}, i32 2)
; VIRT: define <2 x i32> @protected_smul_fix_sat_v2i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i32> @llvm.smul.fix.sat.v2i32({{.*}}, i32 0)
; VIRT: define <1 x i64> @protected_sdiv_fix_sat_v1i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <1 x i64> @llvm.sdiv.fix.sat.v1i64({{.*}}, i32 0)
; VIRT: define <2 x i64> @protected_udiv_fix_sat_v2i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i64> @llvm.udiv.fix.sat.v2i64({{.*}}, i32 2)
; VIRT: define <4 x i32> @protected_smul_fix_phi_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.smul.fix.v4i32({{.*}}, i32 0)
; VIRT: define <4 x i32> @protected_smul_fix_loop_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.smul.fix.v4i32({{.*}}, i32 0)
; VIRT: define {{.*}} @unsupported_fix_malformed({{.*}} #[[UNSUPATTR:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fix_returns_twice({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fix_sret({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fix_i1({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fix_i128({{.*}} #[[UNSUP_ARG:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fix_half({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fix_bfloat({{.*}} #[[UNSUP_ARG]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fix_scalable({{.*}} #[[UNSUP_SC:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fix_v3i32({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fix_v4i8({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fix_wide({{.*}} #[[UNSUP_W:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fix_fastcc({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fix_musttail({{.*}} #[[UNSUP_MT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call <4 x i32> @llvm.smul.fix.v4i32(
; VIRT: define {{.*}} @unsupported_fix_bundle({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call <4 x i32> @llvm.smul.fix.v4i32({{.*}}[ "deopt"(i32 0) ]
; VIRT: define {{.*}} @unsupported_fix_constrained({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fix_poison({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_MT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_ARG]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_SC]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_W]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
