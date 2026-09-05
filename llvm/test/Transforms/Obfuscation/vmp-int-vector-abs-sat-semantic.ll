; Restricted llvm.abs / sadd.sat / uadd.sat / ssub.sat / usub.sat /
; sshl.sat / ushl.sat on fixed i8/i16/i32/i64 vectors (each side total
; 1..128).  Replayed via the existing CallDescriptor and vector VReg
; frame.  Scalar abs/sat, restricted scalar i128 abs/sat, AArch64 NEON
; sqadd/uqadd/sqsub/uqsub, and ordinary vector arithmetic stay
; unchanged.  i1/i128 elements, float/half/bfloat, scalable, pointer,
; aggregate, and >128 stay out.  abs keeps the i1 ImmArg
; is_int_min_poison on ImmediateArguments; true is only used without
; signed-min lanes.  Sat shifts use defined in-range counts: a count
; that overflows the value saturates, a count >= bitwidth is poison
; and is not used for host lli.  C, exact non-vararg FTy, formal type
; equality, true ImmArg.  Ordinary tail accepted and replayed as TCK_None;
; musttail, bundles, noreturn, returns_twice, and complex ABI stay out.
; drop-unsupported strips only @unsupported_*.
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
declare void @ext_sret_byval(ptr sret(i32), ptr byval(i32))
declare <16 x i8> @llvm.abs.v16i8(<16 x i8>, i1 immarg)
declare <16 x i8> @llvm.sadd.sat.v16i8(<16 x i8>, <16 x i8>)
declare <16 x i8> @llvm.uadd.sat.v16i8(<16 x i8>, <16 x i8>)
declare <8 x i8> @llvm.abs.v8i8(<8 x i8>, i1 immarg)
declare <8 x i16> @llvm.ssub.sat.v8i16(<8 x i16>, <8 x i16>)
declare <8 x i16> @llvm.usub.sat.v8i16(<8 x i16>, <8 x i16>)
declare <4 x i32> @llvm.abs.v4i32(<4 x i32>, i1 immarg)
declare <4 x i32> @llvm.sshl.sat.v4i32(<4 x i32>, <4 x i32>)
declare <4 x i32> @llvm.sadd.sat.v4i32(<4 x i32>, <4 x i32>)
declare <2 x i32> @llvm.ushl.sat.v2i32(<2 x i32>, <2 x i32>)
declare <2 x i64> @llvm.ushl.sat.v2i64(<2 x i64>, <2 x i64>)
declare <3 x i32> @llvm.sadd.sat.v3i32(<3 x i32>, <3 x i32>)
declare <8 x i1> @llvm.abs.v8i1(<8 x i1>, i1 immarg)
declare <1 x i128> @llvm.sadd.sat.v1i128(<1 x i128>, <1 x i128>)
declare <4 x half> @llvm.fabs.v4f16(<4 x half>)
declare <4 x bfloat> @llvm.fabs.v4bf16(<4 x bfloat>)
declare <vscale x 4 x i32> @llvm.sadd.sat.nxv4i32(<vscale x 4 x i32>, <vscale x 4 x i32>)
declare <8 x i32> @llvm.sadd.sat.v8i32(<8 x i32>, <8 x i32>)
declare <8 x i1> @llvm.sadd.sat.v8i1(<8 x i1>, <8 x i1>)
declare <3 x i32> @llvm.smul.fix.v3i32(<3 x i32>, <3 x i32>, i32 immarg)

declare <4 x half> @llvm.experimental.constrained.pow.v4f16(<4 x half>, <4 x half>, metadata, metadata)

define <16 x i8> @reference_abs_v16i8(<16 x i8> %a) {
entry:
  %r = call <16 x i8> @llvm.abs.v16i8(<16 x i8> %a, i1 false)
  ret <16 x i8> %r
}

define <16 x i8> @protected_abs_v16i8(<16 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <16 x i8> @llvm.abs.v16i8(<16 x i8> %a, i1 false)
  ret <16 x i8> %r
}

define <4 x i32> @reference_abs_v4i32(<4 x i32> %a, <4 x i32> %safe) {
entry:
  %z = call <4 x i32> @llvm.abs.v4i32(<4 x i32> %a, i1 false)
  %t = call <4 x i32> @llvm.abs.v4i32(<4 x i32> %safe, i1 true)
  %r = xor <4 x i32> %z, %t
  ret <4 x i32> %r
}

define <4 x i32> @protected_abs_v4i32(<4 x i32> %a, <4 x i32> %safe) noinline optnone {
entry:
  call void @hikari_vmp()
  %z = call <4 x i32> @llvm.abs.v4i32(<4 x i32> %a, i1 false)
  %t = call <4 x i32> @llvm.abs.v4i32(<4 x i32> %safe, i1 true)
  %r = xor <4 x i32> %z, %t
  ret <4 x i32> %r
}

define <8 x i8> @reference_abs_v8i8(<8 x i8> %a) {
entry:
  %r = call <8 x i8> @llvm.abs.v8i8(<8 x i8> %a, i1 false)
  ret <8 x i8> %r
}

define <8 x i8> @protected_abs_v8i8(<8 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i8> @llvm.abs.v8i8(<8 x i8> %a, i1 false)
  ret <8 x i8> %r
}

define <16 x i8> @reference_sadd_sat_v16i8(<16 x i8> %a, <16 x i8> %b) {
entry:
  %r = call <16 x i8> @llvm.sadd.sat.v16i8(<16 x i8> %a, <16 x i8> %b)
  ret <16 x i8> %r
}

define <16 x i8> @protected_sadd_sat_v16i8(<16 x i8> %a, <16 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <16 x i8> @llvm.sadd.sat.v16i8(<16 x i8> %a, <16 x i8> %b)
  ret <16 x i8> %r
}

define <16 x i8> @reference_uadd_sat_v16i8(<16 x i8> %a, <16 x i8> %b) {
entry:
  %r = call <16 x i8> @llvm.uadd.sat.v16i8(<16 x i8> %a, <16 x i8> %b)
  ret <16 x i8> %r
}

define <16 x i8> @protected_uadd_sat_v16i8(<16 x i8> %a, <16 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <16 x i8> @llvm.uadd.sat.v16i8(<16 x i8> %a, <16 x i8> %b)
  ret <16 x i8> %r
}

define <8 x i16> @reference_ssub_sat_v8i16(<8 x i16> %a, <8 x i16> %b) {
entry:
  %r = call <8 x i16> @llvm.ssub.sat.v8i16(<8 x i16> %a, <8 x i16> %b)
  ret <8 x i16> %r
}

define <8 x i16> @protected_ssub_sat_v8i16(<8 x i16> %a, <8 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i16> @llvm.ssub.sat.v8i16(<8 x i16> %a, <8 x i16> %b)
  ret <8 x i16> %r
}

define <8 x i16> @reference_usub_sat_v8i16(<8 x i16> %a, <8 x i16> %b) {
entry:
  %r = call <8 x i16> @llvm.usub.sat.v8i16(<8 x i16> %a, <8 x i16> %b)
  ret <8 x i16> %r
}

define <8 x i16> @protected_usub_sat_v8i16(<8 x i16> %a, <8 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i16> @llvm.usub.sat.v8i16(<8 x i16> %a, <8 x i16> %b)
  ret <8 x i16> %r
}

define <4 x i32> @reference_sshl_sat_v4i32(<4 x i32> %a, <4 x i32> %n) {
entry:
  %r = call <4 x i32> @llvm.sshl.sat.v4i32(<4 x i32> %a, <4 x i32> %n)
  ret <4 x i32> %r
}

define <4 x i32> @protected_sshl_sat_v4i32(<4 x i32> %a, <4 x i32> %n) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.sshl.sat.v4i32(<4 x i32> %a, <4 x i32> %n)
  ret <4 x i32> %r
}

define <2 x i64> @reference_ushl_sat_v2i64(<2 x i64> %a, <2 x i64> %n) {
entry:
  %r = call <2 x i64> @llvm.ushl.sat.v2i64(<2 x i64> %a, <2 x i64> %n)
  ret <2 x i64> %r
}

define <2 x i64> @protected_ushl_sat_v2i64(<2 x i64> %a, <2 x i64> %n) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.ushl.sat.v2i64(<2 x i64> %a, <2 x i64> %n)
  ret <2 x i64> %r
}

define <2 x i32> @reference_ushl_sat_v2i32(<2 x i32> %a, <2 x i32> %n) {
entry:
  %r = call <2 x i32> @llvm.ushl.sat.v2i32(<2 x i32> %a, <2 x i32> %n)
  ret <2 x i32> %r
}

define <2 x i32> @protected_ushl_sat_v2i32(<2 x i32> %a, <2 x i32> %n) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i32> @llvm.ushl.sat.v2i32(<2 x i32> %a, <2 x i32> %n)
  ret <2 x i32> %r
}

define <3 x i32> @reference_sadd_sat_v3i32(<3 x i32> %a, <3 x i32> %b) {
entry:
  %r = call <3 x i32> @llvm.sadd.sat.v3i32(<3 x i32> %a, <3 x i32> %b)
  ret <3 x i32> %r
}

define <3 x i32> @protected_sadd_sat_v3i32(<3 x i32> %a, <3 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <3 x i32> @llvm.sadd.sat.v3i32(<3 x i32> %a, <3 x i32> %b)
  ret <3 x i32> %r
}

define <4 x i32> @reference_sadd_sat_phi_v4i32(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c, i1 %p) {
entry:
  br i1 %p, label %left, label %right
left:
  %l = call <4 x i32> @llvm.sadd.sat.v4i32(<4 x i32> %a, <4 x i32> %b)
  br label %join
right:
  %r = call <4 x i32> @llvm.sadd.sat.v4i32(<4 x i32> %a, <4 x i32> %c)
  br label %join
join:
  %q = phi <4 x i32> [ %l, %left ], [ %r, %right ]
  ret <4 x i32> %q
}

define <4 x i32> @protected_sadd_sat_phi_v4i32(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c, i1 %p) noinline optnone {
entry:
  call void @hikari_vmp()
  br i1 %p, label %left, label %right
left:
  %l = call <4 x i32> @llvm.sadd.sat.v4i32(<4 x i32> %a, <4 x i32> %b)
  br label %join
right:
  %r = call <4 x i32> @llvm.sadd.sat.v4i32(<4 x i32> %a, <4 x i32> %c)
  br label %join
join:
  %q = phi <4 x i32> [ %l, %left ], [ %r, %right ]
  ret <4 x i32> %q
}

define <4 x i32> @reference_sadd_sat_loop_v4i32(<4 x i32> %a, <4 x i32> %b, i32 %n) {
entry:
  br label %hdr
hdr:
  %acc = phi <4 x i32> [ %a, %entry ], [ %nxt, %hdr ]
  %i = phi i32 [ 0, %entry ], [ %i.nxt, %hdr ]
  %cur = call <4 x i32> @llvm.sadd.sat.v4i32(<4 x i32> %acc, <4 x i32> %b)
  %nxt = add <4 x i32> %acc, <i32 1, i32 -1, i32 2, i32 0>
  %i.nxt = add i32 %i, 1
  %more = icmp ult i32 %i.nxt, %n
  br i1 %more, label %hdr, label %done
done:
  ret <4 x i32> %cur
}

define <4 x i32> @protected_sadd_sat_loop_v4i32(<4 x i32> %a, <4 x i32> %b, i32 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  br label %hdr
hdr:
  %acc = phi <4 x i32> [ %a, %entry ], [ %nxt, %hdr ]
  %i = phi i32 [ 0, %entry ], [ %i.nxt, %hdr ]
  %cur = call <4 x i32> @llvm.sadd.sat.v4i32(<4 x i32> %acc, <4 x i32> %b)
  %nxt = add <4 x i32> %acc, <i32 1, i32 -1, i32 2, i32 0>
  %i.nxt = add i32 %i, 1
  %more = icmp ult i32 %i.nxt, %n
  br i1 %more, label %hdr, label %done
done:
  ret <4 x i32> %cur
}

; ----- negatives: selected, not virtualized -----


define <4 x i32> @unsupported_abssat_malformed(<4 x i32> %a, <4 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.sadd.sat.v4i32(<4 x i32> %a, <4 x i32> %b) noreturn
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_abssat_returns_twice(<4 x i32> %a, <4 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.sadd.sat.v4i32(<4 x i32> %a, <4 x i32> %b) returns_twice
  ret <4 x i32> %r
}

define void @unsupported_abssat_sret(ptr sret(i32) %p, ptr byval(i32) %q) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @ext_sret_byval(ptr sret(i32) %p, ptr byval(i32) %q)
  ret void
}

define <8 x i1> @unsupported_abssat_i1(<8 x i1> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i1> @llvm.abs.v8i1(<8 x i1> %a, i1 false)
  ret <8 x i1> %r
}

define <1 x i128> @unsupported_abssat_i128(<1 x i128> %a, <1 x i128> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <1 x i128> @llvm.sadd.sat.v1i128(<1 x i128> %a, <1 x i128> %b)
  ret <1 x i128> %r
}

define <4 x half> @unsupported_abssat_half(<4 x half> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x half> @llvm.fabs.v4f16(<4 x half> %a)
  ret <4 x half> %r
}

define <4 x bfloat> @unsupported_abssat_bfloat(<4 x bfloat> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x bfloat> @llvm.fabs.v4bf16(<4 x bfloat> %a)
  ret <4 x bfloat> %r
}

define i64 @unsupported_abssat_fp128(<1 x fp128> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  ret i64 0
}

define <vscale x 4 x i32> @unsupported_abssat_scalable(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.sadd.sat.nxv4i32(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b)
  ret <vscale x 4 x i32> %r
}

define <8 x i32> @unsupported_abssat_wide(<8 x i32> %a, <8 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i32> @llvm.sadd.sat.v8i32(<8 x i32> %a, <8 x i32> %b)
  ret <8 x i32> %r
}

define <8 x i1> @unsupported_abssat_sadd_i1(<8 x i1> %a, <8 x i1> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i1> @llvm.sadd.sat.v8i1(<8 x i1> %a, <8 x i1> %b)
  ret <8 x i1> %r
}

; Leftover 96-bit smul.fix stays out of the 64/128-only vector
; fix-point surface (AArch64 llc crashes on this width).
define <3 x i32> @unsupported_abssat_fix(<3 x i32> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <3 x i32> @llvm.smul.fix.v3i32(<3 x i32> %a, <3 x i32> %a, i32 2)
  ret <3 x i32> %r
}

define <4 x i32> @unsupported_abssat_fastcc(<4 x i32> %a, <4 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc <4 x i32> @llvm.sadd.sat.v4i32(<4 x i32> %a, <4 x i32> %b)
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_abssat_musttail(<4 x i32> %a, <4 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call <4 x i32> @llvm.sadd.sat.v4i32(<4 x i32> %a, <4 x i32> %b)
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_abssat_bundle(<4 x i32> %a, <4 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.sadd.sat.v4i32(<4 x i32> %a, <4 x i32> %b) [ "deopt"(i32 0) ]
  ret <4 x i32> %r
}

define <4 x half> @unsupported_abssat_constrained(<4 x half> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x half> @llvm.experimental.constrained.pow.v4f16(<4 x half> %a, <4 x half> %a, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret <4 x half> %r
}

define <4 x i32> @unsupported_abssat_poison(<4 x i32> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.sadd.sat.v4i32(<4 x i32> %a, <4 x i32> poison)
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
  %a8 = add <16 x i8> <i8 -128, i8 -42, i8 0, i8 7, i8 127, i8 1, i8 -1, i8 9, i8 3, i8 -3, i8 16, i8 -16, i8 64, i8 -64, i8 5, i8 6>, zeroinitializer
  %er0 = call <16 x i8> @reference_abs_v16i8(<16 x i8> %a8)
  %ar0 = call <16 x i8> @protected_abs_v16i8(<16 x i8> %a8)
  %er0c = bitcast <16 x i8> %er0 to <4 x i32>
  %ar0c = bitcast <16 x i8> %ar0 to <4 x i32>
  %em0 = call i32 @vec_i32_mix(<4 x i32> %er0c)
  %am0 = call i32 @vec_i32_mix(<4 x i32> %ar0c)
  %m0 = icmp eq i32 %em0, %am0

  %a32 = add <4 x i32> <i32 -2147483648, i32 -42, i32 0, i32 16>, zeroinitializer
  %safe32 = or <4 x i32> %a32, <i32 1, i32 1, i32 1, i32 1>
  %er1 = call <4 x i32> @reference_abs_v4i32(<4 x i32> %a32, <4 x i32> %safe32)
  %ar1 = call <4 x i32> @protected_abs_v4i32(<4 x i32> %a32, <4 x i32> %safe32)
  %em1 = call i32 @vec_i32_mix(<4 x i32> %er1)
  %am1 = call i32 @vec_i32_mix(<4 x i32> %ar1)
  %m1 = icmp eq i32 %em1, %am1

  %b8 = add <8 x i8> <i8 -128, i8 -1, i8 0, i8 7, i8 42, i8 -42, i8 9, i8 3>, zeroinitializer
  %er2 = call <8 x i8> @reference_abs_v8i8(<8 x i8> %b8)
  %ar2 = call <8 x i8> @protected_abs_v8i8(<8 x i8> %b8)
  %er2z = zext <8 x i8> %er2 to <8 x i16>
  %ar2z = zext <8 x i8> %ar2 to <8 x i16>
  %er2c = bitcast <8 x i16> %er2z to <4 x i32>
  %ar2c = bitcast <8 x i16> %ar2z to <4 x i32>
  %em2 = call i32 @vec_i32_mix(<4 x i32> %er2c)
  %am2 = call i32 @vec_i32_mix(<4 x i32> %ar2c)
  %m2 = icmp eq i32 %em2, %am2

  %sa = add <16 x i8> <i8 100, i8 -100, i8 10, i8 127, i8 -128, i8 50, i8 -50, i8 1, i8 2, i8 3, i8 4, i8 5, i8 6, i8 7, i8 8, i8 9>, zeroinitializer
  %sb = add <16 x i8> <i8 50, i8 -50, i8 20, i8 1, i8 -1, i8 80, i8 -80, i8 1, i8 1, i8 1, i8 1, i8 1, i8 1, i8 1, i8 1, i8 1>, zeroinitializer
  %er3 = call <16 x i8> @reference_sadd_sat_v16i8(<16 x i8> %sa, <16 x i8> %sb)
  %ar3 = call <16 x i8> @protected_sadd_sat_v16i8(<16 x i8> %sa, <16 x i8> %sb)
  %er3c = bitcast <16 x i8> %er3 to <4 x i32>
  %ar3c = bitcast <16 x i8> %ar3 to <4 x i32>
  %em3 = call i32 @vec_i32_mix(<4 x i32> %er3c)
  %am3 = call i32 @vec_i32_mix(<4 x i32> %ar3c)
  %m3 = icmp eq i32 %em3, %am3

  %ua = add <16 x i8> <i8 -56, i8 10, i8 -1, i8 200, i8 1, i8 2, i8 3, i8 4, i8 5, i8 6, i8 7, i8 8, i8 9, i8 11, i8 12, i8 13>, zeroinitializer
  %ub = add <16 x i8> <i8 100, i8 20, i8 1, i8 60, i8 1, i8 1, i8 1, i8 1, i8 1, i8 1, i8 1, i8 1, i8 1, i8 1, i8 1, i8 1>, zeroinitializer
  %er4 = call <16 x i8> @reference_uadd_sat_v16i8(<16 x i8> %ua, <16 x i8> %ub)
  %ar4 = call <16 x i8> @protected_uadd_sat_v16i8(<16 x i8> %ua, <16 x i8> %ub)
  %er4c = bitcast <16 x i8> %er4 to <4 x i32>
  %ar4c = bitcast <16 x i8> %ar4 to <4 x i32>
  %em4 = call i32 @vec_i32_mix(<4 x i32> %er4c)
  %am4 = call i32 @vec_i32_mix(<4 x i32> %ar4c)
  %m4 = icmp eq i32 %em4, %am4

  %ssa = add <8 x i16> <i16 -30000, i16 30000, i16 10, i16 -32768, i16 32767, i16 50, i16 -50, i16 1>, zeroinitializer
  %ssb = add <8 x i16> <i16 4000, i16 -4000, i16 20, i16 1, i16 -1, i16 80, i16 -80, i16 1>, zeroinitializer
  %er5 = call <8 x i16> @reference_ssub_sat_v8i16(<8 x i16> %ssa, <8 x i16> %ssb)
  %ar5 = call <8 x i16> @protected_ssub_sat_v8i16(<8 x i16> %ssa, <8 x i16> %ssb)
  %er5c = bitcast <8 x i16> %er5 to <4 x i32>
  %ar5c = bitcast <8 x i16> %ar5 to <4 x i32>
  %em5 = call i32 @vec_i32_mix(<4 x i32> %er5c)
  %am5 = call i32 @vec_i32_mix(<4 x i32> %ar5c)
  %m5 = icmp eq i32 %em5, %am5

  %usa = add <8 x i16> <i16 10, i16 50, i16 1, i16 65535, i16 20, i16 3, i16 4, i16 5>, zeroinitializer
  %usb = add <8 x i16> <i16 20, i16 20, i16 0, i16 1, i16 5, i16 1, i16 1, i16 1>, zeroinitializer
  %er6 = call <8 x i16> @reference_usub_sat_v8i16(<8 x i16> %usa, <8 x i16> %usb)
  %ar6 = call <8 x i16> @protected_usub_sat_v8i16(<8 x i16> %usa, <8 x i16> %usb)
  %er6c = bitcast <8 x i16> %er6 to <4 x i32>
  %ar6c = bitcast <8 x i16> %ar6 to <4 x i32>
  %em6 = call i32 @vec_i32_mix(<4 x i32> %er6c)
  %am6 = call i32 @vec_i32_mix(<4 x i32> %ar6c)
  %m6 = icmp eq i32 %em6, %am6

  %sha = add <4 x i32> <i32 4, i32 -4, i32 4, i32 -4>, zeroinitializer
  %shn = add <4 x i32> <i32 2, i32 2, i32 30, i32 30>, zeroinitializer
  %er7 = call <4 x i32> @reference_sshl_sat_v4i32(<4 x i32> %sha, <4 x i32> %shn)
  %ar7 = call <4 x i32> @protected_sshl_sat_v4i32(<4 x i32> %sha, <4 x i32> %shn)
  %em7 = call i32 @vec_i32_mix(<4 x i32> %er7)
  %am7 = call i32 @vec_i32_mix(<4 x i32> %ar7)
  %m7 = icmp eq i32 %em7, %am7

  %uha = add <2 x i64> <i64 1, i64 3>, zeroinitializer
  %uhn = add <2 x i64> <i64 2, i64 63>, zeroinitializer
  %er8 = call <2 x i64> @reference_ushl_sat_v2i64(<2 x i64> %uha, <2 x i64> %uhn)
  %ar8 = call <2 x i64> @protected_ushl_sat_v2i64(<2 x i64> %uha, <2 x i64> %uhn)
  %er8c = bitcast <2 x i64> %er8 to <4 x i32>
  %ar8c = bitcast <2 x i64> %ar8 to <4 x i32>
  %em8 = call i32 @vec_i32_mix(<4 x i32> %er8c)
  %am8 = call i32 @vec_i32_mix(<4 x i32> %ar8c)
  %m8 = icmp eq i32 %em8, %am8

  %uh2a = add <2 x i32> <i32 4, i32 3>, zeroinitializer
  %uh2n = add <2 x i32> <i32 2, i32 31>, zeroinitializer
  %er9 = call <2 x i32> @reference_ushl_sat_v2i32(<2 x i32> %uh2a, <2 x i32> %uh2n)
  %ar9 = call <2 x i32> @protected_ushl_sat_v2i32(<2 x i32> %uh2a, <2 x i32> %uh2n)
  %e90 = extractelement <2 x i32> %er9, i32 0
  %e91 = extractelement <2 x i32> %er9, i32 1
  %a90 = extractelement <2 x i32> %ar9, i32 0
  %a91 = extractelement <2 x i32> %ar9, i32 1
  %ex9 = xor i32 %e90, %e91
  %ax9 = xor i32 %a90, %a91
  %m9 = icmp eq i32 %ex9, %ax9

  %a3 = add <3 x i32> <i32 2000000000, i32 -2000000000, i32 10>, zeroinitializer
  %b3 = add <3 x i32> <i32 2000000000, i32 -2000000000, i32 20>, zeroinitializer
  %er10 = call <3 x i32> @reference_sadd_sat_v3i32(<3 x i32> %a3, <3 x i32> %b3)
  %ar10 = call <3 x i32> @protected_sadd_sat_v3i32(<3 x i32> %a3, <3 x i32> %b3)
  %e100 = extractelement <3 x i32> %er10, i32 0
  %e101 = extractelement <3 x i32> %er10, i32 1
  %e102 = extractelement <3 x i32> %er10, i32 2
  %a100 = extractelement <3 x i32> %ar10, i32 0
  %a101 = extractelement <3 x i32> %ar10, i32 1
  %a102 = extractelement <3 x i32> %ar10, i32 2
  %ex10 = xor i32 %e100, %e101
  %ey10 = xor i32 %ex10, %e102
  %ax10 = xor i32 %a100, %a101
  %ay10 = xor i32 %ax10, %a102
  %m10 = icmp eq i32 %ey10, %ay10

  %pa = add <4 x i32> <i32 100, i32 -100, i32 1, i32 2>, zeroinitializer
  %pb = add <4 x i32> <i32 50, i32 -50, i32 3, i32 4>, zeroinitializer
  %pc = add <4 x i32> <i32 2000000000, i32 -2000000000, i32 5, i32 6>, zeroinitializer
  %er11 = call <4 x i32> @reference_sadd_sat_phi_v4i32(<4 x i32> %pa, <4 x i32> %pb, <4 x i32> %pc, i1 true)
  %ar11 = call <4 x i32> @protected_sadd_sat_phi_v4i32(<4 x i32> %pa, <4 x i32> %pb, <4 x i32> %pc, i1 true)
  %em11 = call i32 @vec_i32_mix(<4 x i32> %er11)
  %am11 = call i32 @vec_i32_mix(<4 x i32> %ar11)
  %m11 = icmp eq i32 %em11, %am11

  %er12 = call <4 x i32> @reference_sadd_sat_phi_v4i32(<4 x i32> %pa, <4 x i32> %pb, <4 x i32> %pc, i1 false)
  %ar12 = call <4 x i32> @protected_sadd_sat_phi_v4i32(<4 x i32> %pa, <4 x i32> %pb, <4 x i32> %pc, i1 false)
  %em12 = call i32 @vec_i32_mix(<4 x i32> %er12)
  %am12 = call i32 @vec_i32_mix(<4 x i32> %ar12)
  %m12 = icmp eq i32 %em12, %am12

  %er13 = call <4 x i32> @reference_sadd_sat_loop_v4i32(<4 x i32> %pa, <4 x i32> %pb, i32 2)
  %ar13 = call <4 x i32> @protected_sadd_sat_loop_v4i32(<4 x i32> %pa, <4 x i32> %pb, i32 2)
  %em13 = call i32 @vec_i32_mix(<4 x i32> %er13)
  %am13 = call i32 @vec_i32_mix(<4 x i32> %ar13)
  %m13 = icmp eq i32 %em13, %am13

  %t0 = and i1 %m0, %m1
  %t1 = and i1 %m2, %m3
  %t2 = and i1 %m4, %m5
  %t3 = and i1 %m6, %m7
  %t4 = and i1 %m8, %m9
  %t5 = and i1 %m10, %m11
  %t6 = and i1 %m12, %m13
  %u0 = and i1 %t0, %t1
  %u1 = and i1 %t2, %t3
  %u2 = and i1 %t4, %t5
  %v0 = and i1 %u0, %u1
  %v1 = and i1 %u2, %t6
  %ok = and i1 %v0, %v1
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_abssat_i1: unsupported abs
; SKIP-DAG: Skipping VMP on unsupported_abssat_i128: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_abssat_half: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_abssat_bfloat: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_abssat_fp128: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_abssat_scalable: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_abssat_wide: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_abssat_sadd_i1: unsupported sadd.sat
; SKIP-DAG: Skipping VMP on unsupported_abssat_fix: unsupported smul.fix
; SKIP-DAG: Skipping VMP on unsupported_abssat_fastcc: unsupported sadd.sat
; SKIP-DAG: Skipping VMP on unsupported_abssat_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_abssat_bundle: unsupported sadd.sat
; SKIP-DAG: Skipping VMP on unsupported_abssat_constrained: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_abssat_poison: unsupported sadd.sat
; SKIP-DAG: Skipping VMP on unsupported_abssat_malformed: unsupported sadd.sat
; SKIP-DAG: Skipping VMP on unsupported_abssat_returns_twice: unsupported sadd.sat
; SKIP-DAG: Skipping VMP on unsupported_abssat_sret: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_abs_v16i8:
; SKIP-NOT: Skipping VMP on protected_abs_v4i32:
; SKIP-NOT: Skipping VMP on protected_abs_v8i8:
; SKIP-NOT: Skipping VMP on protected_sadd_sat_v16i8:
; SKIP-NOT: Skipping VMP on protected_uadd_sat_v16i8:
; SKIP-NOT: Skipping VMP on protected_ssub_sat_v8i16:
; SKIP-NOT: Skipping VMP on protected_usub_sat_v8i16:
; SKIP-NOT: Skipping VMP on protected_sshl_sat_v4i32:
; SKIP-NOT: Skipping VMP on protected_ushl_sat_v2i64:
; SKIP-NOT: Skipping VMP on protected_ushl_sat_v2i32:
; SKIP-NOT: Skipping VMP on protected_sadd_sat_v3i32:
; SKIP-NOT: Skipping VMP on protected_sadd_sat_phi_v4i32:
; SKIP-NOT: Skipping VMP on protected_sadd_sat_loop_v4i32:

; VIRT: define <16 x i8> @protected_abs_v16i8({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <16 x i8> @llvm.abs.v16i8({{.*}}, i1 false)
; VIRT: define <4 x i32> @protected_abs_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: call <4 x i32> @llvm.abs.v4i32({{.*}}, i1 false)
; VIRT-DAG: call <4 x i32> @llvm.abs.v4i32({{.*}}, i1 true)
; VIRT: define <8 x i8> @protected_abs_v8i8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x i8> @llvm.abs.v8i8({{.*}}, i1 false)
; VIRT: define <16 x i8> @protected_sadd_sat_v16i8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <16 x i8> @llvm.sadd.sat.v16i8(
; VIRT: define <16 x i8> @protected_uadd_sat_v16i8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <16 x i8> @llvm.uadd.sat.v16i8(
; VIRT: define <8 x i16> @protected_ssub_sat_v8i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x i16> @llvm.ssub.sat.v8i16(
; VIRT: define <8 x i16> @protected_usub_sat_v8i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x i16> @llvm.usub.sat.v8i16(
; VIRT: define <4 x i32> @protected_sshl_sat_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.sshl.sat.v4i32(
; VIRT: define <2 x i64> @protected_ushl_sat_v2i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i64> @llvm.ushl.sat.v2i64(
; VIRT: define <2 x i32> @protected_ushl_sat_v2i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i32> @llvm.ushl.sat.v2i32(
; VIRT: define <3 x i32> @protected_sadd_sat_v3i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <3 x i32> @llvm.sadd.sat.v3i32(
; VIRT: define <4 x i32> @protected_sadd_sat_phi_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.sadd.sat.v4i32(
; VIRT: define <4 x i32> @protected_sadd_sat_loop_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.sadd.sat.v4i32(
; VIRT: define {{.*}} @unsupported_abssat_malformed({{.*}} #[[UNSUPATTR:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_abssat_returns_twice({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_abssat_sret({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_abssat_i1({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_abssat_i128({{.*}} #[[UNSUP_I128:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_abssat_half({{.*}} #[[UNSUP_H:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_abssat_bfloat({{.*}} #[[UNSUP_BF:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_abssat_fp128({{.*}} #[[UNSUP_ARG:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_abssat_scalable({{.*}} #[[UNSUP_SC:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_abssat_wide({{.*}} #[[UNSUP_W:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_abssat_sadd_i1({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_abssat_fix({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_abssat_fastcc({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_abssat_musttail({{.*}} #[[UNSUP_MT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call <4 x i32> @llvm.sadd.sat.v4i32(
; VIRT: define {{.*}} @unsupported_abssat_bundle({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call <4 x i32> @llvm.sadd.sat.v4i32({{.*}}[ "deopt"(i32 0) ]
; VIRT: define {{.*}} @unsupported_abssat_constrained({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_abssat_poison({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_MT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_ARG]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_SC]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_W]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_I128]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_H]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_BF]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
