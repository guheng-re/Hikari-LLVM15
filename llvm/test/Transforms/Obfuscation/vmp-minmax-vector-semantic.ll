; Generic llvm.smin/smax/umin/umax on supported fixed integer vectors
; (total 1..128, elements i1/i8/i16/i32/i64).  Replayed via the existing
; CallDescriptor and vector VReg frame.  Scalar i1..i64/i128 stay on
; vmp-minmax-intrinsic-semantic.ll / vmp-i128-abs-minmax-sat-semantic.ll.
; Legal-width f32/f64 minnum/minimum/maxnum/maximum live in
; vmp-fp-vector-minmax-semantic.ll.  Half minnum, constrained minnum,
; leftover wide maxnum, vector
; reduce, i128 vectors, >128-bit vectors, poison/undef operands, and
; scalable forms stay out.  C, exact non-vararg FTy, formal type
; equality.  Ordinary tail accepted and replayed as TCK_None;
; musttail, bundles, noreturn, returns_twice, and complex ABI stay out.
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
declare <4 x i32> @llvm.smin.v4i32(<4 x i32>, <4 x i32>)
declare <8 x i16> @llvm.smax.v8i16(<8 x i16>, <8 x i16>)
declare <16 x i8> @llvm.umin.v16i8(<16 x i8>, <16 x i8>)
declare <2 x i64> @llvm.umax.v2i64(<2 x i64>, <2 x i64>)
declare <2 x i64> @llvm.smin.v2i64(<2 x i64>, <2 x i64>)
declare <2 x i64> @llvm.smax.v2i64(<2 x i64>, <2 x i64>)
declare <8 x i8> @llvm.smin.v8i8(<8 x i8>, <8 x i8>)
declare <4 x i16> @llvm.umax.v4i16(<4 x i16>, <4 x i16>)
declare <2 x i32> @llvm.umin.v2i32(<2 x i32>, <2 x i32>)
declare <8 x i1> @llvm.smin.v8i1(<8 x i1>, <8 x i1>)
declare <4 x i32> @llvm.smax.v4i32(<4 x i32>, <4 x i32>)
declare <4 x i32> @llvm.umin.v4i32(<4 x i32>, <4 x i32>)
declare <4 x i32> @llvm.umax.v4i32(<4 x i32>, <4 x i32>)
declare <1 x i64> @llvm.smin.v1i64(<1 x i64>, <1 x i64>)
declare <4 x i8> @llvm.umin.v4i8(<4 x i8>, <4 x i8>)
declare <3 x i32> @llvm.smin.v3i32(<3 x i32>, <3 x i32>)
declare <4 x half> @llvm.minnum.v4f16(<4 x half>, <4 x half>)
declare <8 x double> @llvm.maxnum.v8f64(<8 x double>, <8 x double>)
declare <1 x i128> @llvm.smin.v1i128(<1 x i128>, <1 x i128>)
declare <4 x i64> @llvm.smin.v4i64(<4 x i64>, <4 x i64>)
declare <vscale x 4 x i32> @llvm.smin.nxv4i32(<vscale x 4 x i32>, <vscale x 4 x i32>)

declare <4 x half> @llvm.experimental.constrained.pow.v4f16(<4 x half>, <4 x half>, metadata, metadata)

define <4 x i32> @reference_smin_v4i32(<4 x i32> %a, <4 x i32> %b) {
entry:
  %r = call <4 x i32> @llvm.smin.v4i32(<4 x i32> %a, <4 x i32> %b)
  ret <4 x i32> %r
}

define <4 x i32> @protected_smin_v4i32(<4 x i32> %a, <4 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.smin.v4i32(<4 x i32> %a, <4 x i32> %b)
  ret <4 x i32> %r
}

define <8 x i16> @reference_smax_v8i16(<8 x i16> %a, <8 x i16> %b) {
entry:
  %r = call <8 x i16> @llvm.smax.v8i16(<8 x i16> %a, <8 x i16> %b)
  ret <8 x i16> %r
}

define <8 x i16> @protected_smax_v8i16(<8 x i16> %a, <8 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i16> @llvm.smax.v8i16(<8 x i16> %a, <8 x i16> %b)
  ret <8 x i16> %r
}

define <16 x i8> @reference_umin_v16i8(<16 x i8> %a, <16 x i8> %b) {
entry:
  %r = call <16 x i8> @llvm.umin.v16i8(<16 x i8> %a, <16 x i8> %b)
  ret <16 x i8> %r
}

define <16 x i8> @protected_umin_v16i8(<16 x i8> %a, <16 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <16 x i8> @llvm.umin.v16i8(<16 x i8> %a, <16 x i8> %b)
  ret <16 x i8> %r
}

define <2 x i64> @reference_umax_v2i64(<2 x i64> %a, <2 x i64> %b) {
entry:
  %r = call <2 x i64> @llvm.umax.v2i64(<2 x i64> %a, <2 x i64> %b)
  ret <2 x i64> %r
}

define <2 x i64> @protected_umax_v2i64(<2 x i64> %a, <2 x i64> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.umax.v2i64(<2 x i64> %a, <2 x i64> %b)
  ret <2 x i64> %r
}

; Signed i64 lanes: <i64 1, i64 -1> vs <i64 2, i64 3> differs from umax.
define <2 x i64> @reference_smin_v2i64(<2 x i64> %a, <2 x i64> %b) {
entry:
  %r = call <2 x i64> @llvm.smin.v2i64(<2 x i64> %a, <2 x i64> %b)
  ret <2 x i64> %r
}

define <2 x i64> @protected_smin_v2i64(<2 x i64> %a, <2 x i64> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.smin.v2i64(<2 x i64> %a, <2 x i64> %b)
  ret <2 x i64> %r
}

define <2 x i64> @reference_smax_v2i64(<2 x i64> %a, <2 x i64> %b) {
entry:
  %r = call <2 x i64> @llvm.smax.v2i64(<2 x i64> %a, <2 x i64> %b)
  ret <2 x i64> %r
}

define <2 x i64> @protected_smax_v2i64(<2 x i64> %a, <2 x i64> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.smax.v2i64(<2 x i64> %a, <2 x i64> %b)
  ret <2 x i64> %r
}

define <8 x i8> @reference_smin_v8i8(<8 x i8> %a, <8 x i8> %b) {
entry:
  %r = call <8 x i8> @llvm.smin.v8i8(<8 x i8> %a, <8 x i8> %b)
  ret <8 x i8> %r
}

define <8 x i8> @protected_smin_v8i8(<8 x i8> %a, <8 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i8> @llvm.smin.v8i8(<8 x i8> %a, <8 x i8> %b)
  ret <8 x i8> %r
}

define <4 x i16> @reference_umax_v4i16(<4 x i16> %a, <4 x i16> %b) {
entry:
  %r = call <4 x i16> @llvm.umax.v4i16(<4 x i16> %a, <4 x i16> %b)
  ret <4 x i16> %r
}

define <4 x i16> @protected_umax_v4i16(<4 x i16> %a, <4 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i16> @llvm.umax.v4i16(<4 x i16> %a, <4 x i16> %b)
  ret <4 x i16> %r
}

define <2 x i32> @reference_umin_v2i32(<2 x i32> %a, <2 x i32> %b) {
entry:
  %r = call <2 x i32> @llvm.umin.v2i32(<2 x i32> %a, <2 x i32> %b)
  ret <2 x i32> %r
}

define <2 x i32> @protected_umin_v2i32(<2 x i32> %a, <2 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i32> @llvm.umin.v2i32(<2 x i32> %a, <2 x i32> %b)
  ret <2 x i32> %r
}

define <8 x i1> @reference_smin_v8i1(<8 x i1> %a, <8 x i1> %b) {
entry:
  %r = call <8 x i1> @llvm.smin.v8i1(<8 x i1> %a, <8 x i1> %b)
  ret <8 x i1> %r
}

define <8 x i1> @protected_smin_v8i1(<8 x i1> %a, <8 x i1> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i1> @llvm.smin.v8i1(<8 x i1> %a, <8 x i1> %b)
  ret <8 x i1> %r
}

; All four IDs on one ISel type, plus a constant vector operand.
define <4 x i32> @reference_all_v4i32(<4 x i32> %a, <4 x i32> %b) {
entry:
  %n = call <4 x i32> @llvm.smin.v4i32(<4 x i32> %a, <4 x i32> %b)
  %x = call <4 x i32> @llvm.smax.v4i32(<4 x i32> %a, <4 x i32> %b)
  %u = call <4 x i32> @llvm.umin.v4i32(<4 x i32> %a, <4 x i32> %b)
  %m = call <4 x i32> @llvm.umax.v4i32(<4 x i32> %a, <4 x i32> %b)
  %k = call <4 x i32> @llvm.smin.v4i32(<4 x i32> %a, <4 x i32> <i32 0, i32 1, i32 -1, i32 8>)
  %t0 = xor <4 x i32> %n, %x
  %t1 = xor <4 x i32> %u, %m
  %t2 = xor <4 x i32> %t0, %t1
  %r = xor <4 x i32> %t2, %k
  ret <4 x i32> %r
}

define <4 x i32> @protected_all_v4i32(<4 x i32> %a, <4 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %n = call <4 x i32> @llvm.smin.v4i32(<4 x i32> %a, <4 x i32> %b)
  %x = call <4 x i32> @llvm.smax.v4i32(<4 x i32> %a, <4 x i32> %b)
  %u = call <4 x i32> @llvm.umin.v4i32(<4 x i32> %a, <4 x i32> %b)
  %m = call <4 x i32> @llvm.umax.v4i32(<4 x i32> %a, <4 x i32> %b)
  %k = call <4 x i32> @llvm.smin.v4i32(<4 x i32> %a, <4 x i32> <i32 0, i32 1, i32 -1, i32 8>)
  %t0 = xor <4 x i32> %n, %x
  %t1 = xor <4 x i32> %u, %m
  %t2 = xor <4 x i32> %t0, %t1
  %r = xor <4 x i32> %t2, %k
  ret <4 x i32> %r
}

; 64-bit i64 and leftover <4 x i8> are in the generic integer-vector
; surface (unlike the NEON sat-int ISel allowlist).
define <1 x i64> @reference_smin_v1i64(<1 x i64> %a, <1 x i64> %b) {
entry:
  %r = call <1 x i64> @llvm.smin.v1i64(<1 x i64> %a, <1 x i64> %b)
  ret <1 x i64> %r
}

define <1 x i64> @protected_smin_v1i64(<1 x i64> %a, <1 x i64> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <1 x i64> @llvm.smin.v1i64(<1 x i64> %a, <1 x i64> %b)
  ret <1 x i64> %r
}

define <4 x i8> @reference_umin_v4i8(<4 x i8> %a, <4 x i8> %b) {
entry:
  %r = call <4 x i8> @llvm.umin.v4i8(<4 x i8> %a, <4 x i8> %b)
  ret <4 x i8> %r
}

define <4 x i8> @protected_umin_v4i8(<4 x i8> %a, <4 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i8> @llvm.umin.v4i8(<4 x i8> %a, <4 x i8> %b)
  ret <4 x i8> %r
}

define <3 x i32> @reference_smin_v3i32(<3 x i32> %a, <3 x i32> %b) {
entry:
  %r = call <3 x i32> @llvm.smin.v3i32(<3 x i32> %a, <3 x i32> %b)
  ret <3 x i32> %r
}

define <3 x i32> @protected_smin_v3i32(<3 x i32> %a, <3 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <3 x i32> @llvm.smin.v3i32(<3 x i32> %a, <3 x i32> %b)
  ret <3 x i32> %r
}

define <3 x i32> @reference_smin_phi_v3i32(<3 x i32> %a, <3 x i32> %b, i1 %c) {
entry:
  br i1 %c, label %left, label %right
left:
  %l = call <3 x i32> @llvm.smin.v3i32(<3 x i32> %a, <3 x i32> %b)
  br label %join
right:
  %r = call <3 x i32> @llvm.smin.v3i32(<3 x i32> %b, <3 x i32> %a)
  br label %join
join:
  %p = phi <3 x i32> [ %l, %left ], [ %r, %right ]
  ret <3 x i32> %p
}

define <3 x i32> @protected_smin_phi_v3i32(<3 x i32> %a, <3 x i32> %b, i1 %c) noinline optnone {
entry:
  call void @hikari_vmp()
  br i1 %c, label %left, label %right
left:
  %l = call <3 x i32> @llvm.smin.v3i32(<3 x i32> %a, <3 x i32> %b)
  br label %join
right:
  %r = call <3 x i32> @llvm.smin.v3i32(<3 x i32> %b, <3 x i32> %a)
  br label %join
join:
  %p = phi <3 x i32> [ %l, %left ], [ %r, %right ]
  ret <3 x i32> %p
}

; Back-edge accumulator.  Distinct from the diamond join above.
define <3 x i32> @reference_smin_loopphi_v3i32(<3 x i32> %a, <3 x i32> %step, i32 %n) {
entry:
  br label %hdr
hdr:
  %acc = phi <3 x i32> [ %a, %entry ], [ %nxt, %hdr ]
  %i = phi i32 [ 0, %entry ], [ %i.nxt, %hdr ]
  %nxt = call <3 x i32> @llvm.smin.v3i32(<3 x i32> %acc, <3 x i32> %step)
  %i.nxt = add i32 %i, 1
  %more = icmp ult i32 %i.nxt, %n
  br i1 %more, label %hdr, label %done
done:
  ret <3 x i32> %nxt
}

define <3 x i32> @protected_smin_loopphi_v3i32(<3 x i32> %a, <3 x i32> %step, i32 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  br label %hdr
hdr:
  %acc = phi <3 x i32> [ %a, %entry ], [ %nxt, %hdr ]
  %i = phi i32 [ 0, %entry ], [ %i.nxt, %hdr ]
  %nxt = call <3 x i32> @llvm.smin.v3i32(<3 x i32> %acc, <3 x i32> %step)
  %i.nxt = add i32 %i, 1
  %more = icmp ult i32 %i.nxt, %n
  br i1 %more, label %hdr, label %done
done:
  ret <3 x i32> %nxt
}

; ----- negatives: selected, not virtualized -----

define <4 x half> @unsupported_minmax_minnum_half(<4 x half> %a, <4 x half> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x half> @llvm.minnum.v4f16(<4 x half> %a, <4 x half> %b)
  ret <4 x half> %r
}

define <4 x half> @unsupported_minmax_minnum_constrained(<4 x half> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x half> @llvm.experimental.constrained.pow.v4f16(<4 x half> %a, <4 x half> %a, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret <4 x half> %r
}

define <8 x double> @unsupported_minmax_maxnum_wide(<8 x double> %a, <8 x double> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x double> @llvm.maxnum.v8f64(<8 x double> %a, <8 x double> %b)
  ret <8 x double> %r
}

; Well-formed llvm.aarch64.neon.smin / smax is
; vmp-aarch64-neon-int-extrema-semantic.ll and must not stay
; here as a negative (it would virtualize).

define <1 x i128> @unsupported_minmax_v1i128(<1 x i128> %a, <1 x i128> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <1 x i128> @llvm.smin.v1i128(<1 x i128> %a, <1 x i128> %b)
  ret <1 x i128> %r
}

define <4 x i64> @unsupported_minmax_wide(<4 x i64> %a, <4 x i64> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i64> @llvm.smin.v4i64(<4 x i64> %a, <4 x i64> %b)
  ret <4 x i64> %r
}

define <4 x i32> @unsupported_minmax_poison(<4 x i32> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.smin.v4i32(<4 x i32> %a, <4 x i32> poison)
  ret <4 x i32> %r
}


define <4 x i32> @unsupported_minmax_fastcc(<4 x i32> %a, <4 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc <4 x i32> @llvm.smin.v4i32(<4 x i32> %a, <4 x i32> %b)
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_minmax_malformed(<4 x i32> %a, <4 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.smin.v4i32(<4 x i32> %a, <4 x i32> %b) noreturn
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_minmax_returns_twice(<4 x i32> %a, <4 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.smin.v4i32(<4 x i32> %a, <4 x i32> %b) returns_twice
  ret <4 x i32> %r
}

define void @unsupported_minmax_sret(ptr sret(i32) %p, ptr byval(i32) %q) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @ext_sret_byval(ptr sret(i32) %p, ptr byval(i32) %q)
  ret void
}

define <vscale x 4 x i32> @unsupported_minmax_scalable(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.smin.nxv4i32(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b)
  ret <vscale x 4 x i32> %r
}

define <4 x i32> @unsupported_minmax_musttail(<4 x i32> %a, <4 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call <4 x i32> @llvm.smin.v4i32(<4 x i32> %a, <4 x i32> %b)
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_minmax_bundle(<4 x i32> %a, <4 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.smin.v4i32(<4 x i32> %a, <4 x i32> %b) [ "deopt"(i32 0) ]
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
  %a32 = add <4 x i32> <i32 -8, i32 3, i32 9, i32 -1>, zeroinitializer
  %b32 = add <4 x i32> <i32 2, i32 -4, i32 9, i32 7>, zeroinitializer
  %er0 = call <4 x i32> @reference_smin_v4i32(<4 x i32> %a32, <4 x i32> %b32)
  %ar0 = call <4 x i32> @protected_smin_v4i32(<4 x i32> %a32, <4 x i32> %b32)
  %em0 = call i32 @vec_i32_mix(<4 x i32> %er0)
  %am0 = call i32 @vec_i32_mix(<4 x i32> %ar0)
  %c0 = icmp eq i32 %em0, %am0

  %a16 = add <8 x i16> <i16 -2, i16 1, i16 4, i16 -9, i16 0, i16 8, i16 -3, i16 5>, zeroinitializer
  %b16 = add <8 x i16> <i16 3, i16 -1, i16 4, i16 2, i16 -8, i16 8, i16 1, i16 -6>, zeroinitializer
  %er1 = call <8 x i16> @reference_smax_v8i16(<8 x i16> %a16, <8 x i16> %b16)
  %ar1 = call <8 x i16> @protected_smax_v8i16(<8 x i16> %a16, <8 x i16> %b16)
  %er1c = bitcast <8 x i16> %er1 to <4 x i32>
  %ar1c = bitcast <8 x i16> %ar1 to <4 x i32>
  %em1 = call i32 @vec_i32_mix(<4 x i32> %er1c)
  %am1 = call i32 @vec_i32_mix(<4 x i32> %ar1c)
  %c1 = icmp eq i32 %em1, %am1

  %a8 = add <16 x i8> <i8 1, i8 255, i8 3, i8 0, i8 9, i8 8, i8 7, i8 6, i8 5, i8 4, i8 3, i8 2, i8 1, i8 0, i8 255, i8 128>, zeroinitializer
  %b8 = add <16 x i8> <i8 2, i8 1, i8 3, i8 255, i8 0, i8 8, i8 9, i8 6, i8 5, i8 10, i8 3, i8 2, i8 200, i8 0, i8 1, i8 127>, zeroinitializer
  %er2 = call <16 x i8> @reference_umin_v16i8(<16 x i8> %a8, <16 x i8> %b8)
  %ar2 = call <16 x i8> @protected_umin_v16i8(<16 x i8> %a8, <16 x i8> %b8)
  %er2c = bitcast <16 x i8> %er2 to <4 x i32>
  %ar2c = bitcast <16 x i8> %ar2 to <4 x i32>
  %em2 = call i32 @vec_i32_mix(<4 x i32> %er2c)
  %am2 = call i32 @vec_i32_mix(<4 x i32> %ar2c)
  %c2 = icmp eq i32 %em2, %am2

  %a64 = add <2 x i64> <i64 1, i64 -1>, zeroinitializer
  %b64 = add <2 x i64> <i64 2, i64 3>, zeroinitializer
  %er3 = call <2 x i64> @reference_umax_v2i64(<2 x i64> %a64, <2 x i64> %b64)
  %ar3 = call <2 x i64> @protected_umax_v2i64(<2 x i64> %a64, <2 x i64> %b64)
  %er3c = bitcast <2 x i64> %er3 to <4 x i32>
  %ar3c = bitcast <2 x i64> %ar3 to <4 x i32>
  %em3 = call i32 @vec_i32_mix(<4 x i32> %er3c)
  %am3 = call i32 @vec_i32_mix(<4 x i32> %ar3c)
  %c3 = icmp eq i32 %em3, %am3

  %er3s = call <2 x i64> @reference_smin_v2i64(<2 x i64> %a64, <2 x i64> %b64)
  %ar3s = call <2 x i64> @protected_smin_v2i64(<2 x i64> %a64, <2 x i64> %b64)
  %er3sc = bitcast <2 x i64> %er3s to <4 x i32>
  %ar3sc = bitcast <2 x i64> %ar3s to <4 x i32>
  %em3s = call i32 @vec_i32_mix(<4 x i32> %er3sc)
  %am3s = call i32 @vec_i32_mix(<4 x i32> %ar3sc)
  %c3s = icmp eq i32 %em3s, %am3s

  %er3x = call <2 x i64> @reference_smax_v2i64(<2 x i64> %a64, <2 x i64> %b64)
  %ar3x = call <2 x i64> @protected_smax_v2i64(<2 x i64> %a64, <2 x i64> %b64)
  %er3xc = bitcast <2 x i64> %er3x to <4 x i32>
  %ar3xc = bitcast <2 x i64> %ar3x to <4 x i32>
  %em3x = call i32 @vec_i32_mix(<4 x i32> %er3xc)
  %am3x = call i32 @vec_i32_mix(<4 x i32> %ar3xc)
  %c3x = icmp eq i32 %em3x, %am3x

  %a88 = add <8 x i8> <i8 -128, i8 1, i8 2, i8 -3, i8 4, i8 5, i8 -6, i8 7>, zeroinitializer
  %b88 = add <8 x i8> <i8 0, i8 -1, i8 9, i8 -3, i8 -8, i8 5, i8 1, i8 8>, zeroinitializer
  %er4 = call <8 x i8> @reference_smin_v8i8(<8 x i8> %a88, <8 x i8> %b88)
  %ar4 = call <8 x i8> @protected_smin_v8i8(<8 x i8> %a88, <8 x i8> %b88)
  %er4z = zext <8 x i8> %er4 to <8 x i16>
  %ar4z = zext <8 x i8> %ar4 to <8 x i16>
  %er4c = bitcast <8 x i16> %er4z to <4 x i32>
  %ar4c = bitcast <8 x i16> %ar4z to <4 x i32>
  %em4 = call i32 @vec_i32_mix(<4 x i32> %er4c)
  %am4 = call i32 @vec_i32_mix(<4 x i32> %ar4c)
  %c4 = icmp eq i32 %em4, %am4

  %a416 = add <4 x i16> <i16 1, i16 65535, i16 3, i16 8>, zeroinitializer
  %b416 = add <4 x i16> <i16 2, i16 1, i16 3, i16 0>, zeroinitializer
  %er5 = call <4 x i16> @reference_umax_v4i16(<4 x i16> %a416, <4 x i16> %b416)
  %ar5 = call <4 x i16> @protected_umax_v4i16(<4 x i16> %a416, <4 x i16> %b416)
  %er5z = zext <4 x i16> %er5 to <4 x i32>
  %ar5z = zext <4 x i16> %ar5 to <4 x i32>
  %em5 = call i32 @vec_i32_mix(<4 x i32> %er5z)
  %am5 = call i32 @vec_i32_mix(<4 x i32> %ar5z)
  %c5 = icmp eq i32 %em5, %am5

  %a2 = add <2 x i32> <i32 1, i32 -1>, zeroinitializer
  %b2 = add <2 x i32> <i32 2, i32 3>, zeroinitializer
  %er6 = call <2 x i32> @reference_umin_v2i32(<2 x i32> %a2, <2 x i32> %b2)
  %ar6 = call <2 x i32> @protected_umin_v2i32(<2 x i32> %a2, <2 x i32> %b2)
  %e60 = extractelement <2 x i32> %er6, i32 0
  %e61 = extractelement <2 x i32> %er6, i32 1
  %a60 = extractelement <2 x i32> %ar6, i32 0
  %a61 = extractelement <2 x i32> %ar6, i32 1
  %em6 = xor i32 %e60, %e61
  %am6 = xor i32 %a60, %a61
  %c6 = icmp eq i32 %em6, %am6

  %a1 = add <8 x i1> <i1 1, i1 0, i1 1, i1 1, i1 0, i1 0, i1 1, i1 0>, zeroinitializer
  %b1 = add <8 x i1> <i1 0, i1 0, i1 1, i1 0, i1 1, i1 0, i1 1, i1 1>, zeroinitializer
  %er7 = call <8 x i1> @reference_smin_v8i1(<8 x i1> %a1, <8 x i1> %b1)
  %ar7 = call <8 x i1> @protected_smin_v8i1(<8 x i1> %a1, <8 x i1> %b1)
  %eb7 = bitcast <8 x i1> %er7 to i8
  %ab7 = bitcast <8 x i1> %ar7 to i8
  %c7 = icmp eq i8 %eb7, %ab7

  %er8 = call <4 x i32> @reference_all_v4i32(<4 x i32> %a32, <4 x i32> %b32)
  %ar8 = call <4 x i32> @protected_all_v4i32(<4 x i32> %a32, <4 x i32> %b32)
  %em8 = call i32 @vec_i32_mix(<4 x i32> %er8)
  %am8 = call i32 @vec_i32_mix(<4 x i32> %ar8)
  %c8 = icmp eq i32 %em8, %am8

  %a164 = add <1 x i64> <i64 -8>, zeroinitializer
  %b164 = add <1 x i64> <i64 3>, zeroinitializer
  %er9 = call <1 x i64> @reference_smin_v1i64(<1 x i64> %a164, <1 x i64> %b164)
  %ar9 = call <1 x i64> @protected_smin_v1i64(<1 x i64> %a164, <1 x i64> %b164)
  %e9 = extractelement <1 x i64> %er9, i32 0
  %a9 = extractelement <1 x i64> %ar9, i32 0
  %c9 = icmp eq i64 %e9, %a9

  %a48 = add <4 x i8> <i8 1, i8 255, i8 3, i8 0>, zeroinitializer
  %b48 = add <4 x i8> <i8 2, i8 1, i8 3, i8 255>, zeroinitializer
  %er10 = call <4 x i8> @reference_umin_v4i8(<4 x i8> %a48, <4 x i8> %b48)
  %ar10 = call <4 x i8> @protected_umin_v4i8(<4 x i8> %a48, <4 x i8> %b48)
  %er10z = zext <4 x i8> %er10 to <4 x i32>
  %ar10z = zext <4 x i8> %ar10 to <4 x i32>
  %em10 = call i32 @vec_i32_mix(<4 x i32> %er10z)
  %am10 = call i32 @vec_i32_mix(<4 x i32> %ar10z)
  %c10 = icmp eq i32 %em10, %am10

  %a3 = add <3 x i32> <i32 -8, i32 3, i32 9>, zeroinitializer
  %b3 = add <3 x i32> <i32 2, i32 -4, i32 1>, zeroinitializer
  %er11 = call <3 x i32> @reference_smin_v3i32(<3 x i32> %a3, <3 x i32> %b3)
  %ar11 = call <3 x i32> @protected_smin_v3i32(<3 x i32> %a3, <3 x i32> %b3)
  %e110 = extractelement <3 x i32> %er11, i32 0
  %e111 = extractelement <3 x i32> %er11, i32 1
  %e112 = extractelement <3 x i32> %er11, i32 2
  %a110 = extractelement <3 x i32> %ar11, i32 0
  %a111 = extractelement <3 x i32> %ar11, i32 1
  %a112 = extractelement <3 x i32> %ar11, i32 2
  %em11a = xor i32 %e110, %e111
  %em11 = xor i32 %em11a, %e112
  %am11a = xor i32 %a110, %a111
  %am11 = xor i32 %am11a, %a112
  %c11 = icmp eq i32 %em11, %am11

  %er12t = call <3 x i32> @reference_smin_phi_v3i32(<3 x i32> %a3, <3 x i32> %b3, i1 true)
  %ar12t = call <3 x i32> @protected_smin_phi_v3i32(<3 x i32> %a3, <3 x i32> %b3, i1 true)
  %er12f = call <3 x i32> @reference_smin_phi_v3i32(<3 x i32> %a3, <3 x i32> %b3, i1 false)
  %ar12f = call <3 x i32> @protected_smin_phi_v3i32(<3 x i32> %a3, <3 x i32> %b3, i1 false)
  %et0 = extractelement <3 x i32> %er12t, i32 0
  %et1 = extractelement <3 x i32> %er12t, i32 1
  %et2 = extractelement <3 x i32> %er12t, i32 2
  %at0 = extractelement <3 x i32> %ar12t, i32 0
  %at1 = extractelement <3 x i32> %ar12t, i32 1
  %at2 = extractelement <3 x i32> %ar12t, i32 2
  %emt = xor i32 %et0, %et1
  %emt2 = xor i32 %emt, %et2
  %amt = xor i32 %at0, %at1
  %amt2 = xor i32 %amt, %at2
  %c12t = icmp eq i32 %emt2, %amt2
  %ef0 = extractelement <3 x i32> %er12f, i32 0
  %ef1 = extractelement <3 x i32> %er12f, i32 1
  %ef2 = extractelement <3 x i32> %er12f, i32 2
  %af0 = extractelement <3 x i32> %ar12f, i32 0
  %af1 = extractelement <3 x i32> %ar12f, i32 1
  %af2 = extractelement <3 x i32> %ar12f, i32 2
  %emf = xor i32 %ef0, %ef1
  %emf2 = xor i32 %emf, %ef2
  %amf = xor i32 %af0, %af1
  %amf2 = xor i32 %amf, %af2
  %c12f = icmp eq i32 %emf2, %amf2
  %c12 = and i1 %c12t, %c12f

  %er13 = call <3 x i32> @reference_smin_loopphi_v3i32(<3 x i32> %a3, <3 x i32> %b3, i32 3)
  %ar13 = call <3 x i32> @protected_smin_loopphi_v3i32(<3 x i32> %a3, <3 x i32> %b3, i32 3)
  %el0 = extractelement <3 x i32> %er13, i32 0
  %el1 = extractelement <3 x i32> %er13, i32 1
  %el2 = extractelement <3 x i32> %er13, i32 2
  %al0 = extractelement <3 x i32> %ar13, i32 0
  %al1 = extractelement <3 x i32> %ar13, i32 1
  %al2 = extractelement <3 x i32> %ar13, i32 2
  %eml = xor i32 %el0, %el1
  %eml2 = xor i32 %eml, %el2
  %aml = xor i32 %al0, %al1
  %aml2 = xor i32 %aml, %al2
  %c13 = icmp eq i32 %eml2, %aml2

  %ok01 = and i1 %c0, %c1
  %ok23 = and i1 %c2, %c3
  %ok45 = and i1 %c4, %c5
  %ok67 = and i1 %c6, %c7
  %ok03 = and i1 %ok01, %ok23
  %ok47 = and i1 %ok45, %ok67
  %ok07 = and i1 %ok03, %ok47
  %ok8 = and i1 %ok07, %c8
  %ok910 = and i1 %c9, %c10
  %ok3sx = and i1 %c3s, %c3x
  %okbase = and i1 %ok8, %ok910
  %ok3 = and i1 %okbase, %ok3sx
  %okv3 = and i1 %c11, %c12
  %okv3l = and i1 %okv3, %c13
  %ok = and i1 %ok3, %okv3l
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_minmax_minnum_half: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_minmax_minnum_constrained: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_minmax_maxnum_wide: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_minmax_v1i128: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_minmax_wide: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_minmax_poison: unsupported smin
; SKIP-DAG: Skipping VMP on unsupported_minmax_scalable: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_minmax_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_minmax_bundle: unsupported smin
; SKIP-DAG: Skipping VMP on unsupported_minmax_fastcc: unsupported smin
; SKIP-DAG: Skipping VMP on unsupported_minmax_malformed: unsupported smin
; SKIP-DAG: Skipping VMP on unsupported_minmax_returns_twice: unsupported smin
; SKIP-DAG: Skipping VMP on unsupported_minmax_sret: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_smin_v4i32:
; SKIP-NOT: Skipping VMP on protected_smax_v8i16:
; SKIP-NOT: Skipping VMP on protected_umin_v16i8:
; SKIP-NOT: Skipping VMP on protected_umax_v2i64:
; SKIP-NOT: Skipping VMP on protected_smin_v2i64:
; SKIP-NOT: Skipping VMP on protected_smax_v2i64:
; SKIP-NOT: Skipping VMP on protected_smin_v8i8:
; SKIP-NOT: Skipping VMP on protected_umax_v4i16:
; SKIP-NOT: Skipping VMP on protected_umin_v2i32:
; SKIP-NOT: Skipping VMP on protected_smin_v8i1:
; SKIP-NOT: Skipping VMP on protected_all_v4i32:
; SKIP-NOT: Skipping VMP on protected_smin_v1i64:
; SKIP-NOT: Skipping VMP on protected_umin_v4i8:
; SKIP-NOT: Skipping VMP on protected_smin_v3i32:
; SKIP-NOT: Skipping VMP on protected_smin_phi_v3i32:
; SKIP-NOT: Skipping VMP on protected_smin_loopphi_v3i32:

; VIRT: define <4 x i32> @protected_smin_v4i32({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.smin.v4i32(
; VIRT: define <8 x i16> @protected_smax_v8i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x i16> @llvm.smax.v8i16(
; VIRT: define <16 x i8> @protected_umin_v16i8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <16 x i8> @llvm.umin.v16i8(
; VIRT: define <2 x i64> @protected_umax_v2i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i64> @llvm.umax.v2i64(
; VIRT: define <2 x i64> @protected_smin_v2i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i64> @llvm.smin.v2i64(
; VIRT: define <2 x i64> @protected_smax_v2i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i64> @llvm.smax.v2i64(
; VIRT: define <8 x i8> @protected_smin_v8i8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x i8> @llvm.smin.v8i8(
; VIRT: define <4 x i16> @protected_umax_v4i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i16> @llvm.umax.v4i16(
; VIRT: define <2 x i32> @protected_umin_v2i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i32> @llvm.umin.v2i32(
; VIRT: define <8 x i1> @protected_smin_v8i1({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x i1> @llvm.smin.v8i1(
; VIRT: define <4 x i32> @protected_all_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: call <4 x i32> @llvm.smin.v4i32(
; VIRT-DAG: call <4 x i32> @llvm.smax.v4i32(
; VIRT-DAG: call <4 x i32> @llvm.umin.v4i32(
; VIRT-DAG: call <4 x i32> @llvm.umax.v4i32(
; VIRT: define <1 x i64> @protected_smin_v1i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <1 x i64> @llvm.smin.v1i64(
; VIRT: define <4 x i8> @protected_umin_v4i8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i8> @llvm.umin.v4i8(
; VIRT: define <3 x i32> @protected_smin_v3i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <3 x i32> @llvm.smin.v3i32(
; VIRT: define <3 x i32> @protected_smin_phi_v3i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <3 x i32> @llvm.smin.v3i32(
; VIRT: define <3 x i32> @protected_smin_loopphi_v3i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <3 x i32> @llvm.smin.v3i32(
; VIRT: define {{.*}} @unsupported_minmax_minnum_half({{.*}} #[[UNSUPATTR:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_minmax_minnum_constrained({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_minmax_maxnum_wide({{.*}} {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_minmax_v1i128({{.*}} #[[UNSUP_RET:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_minmax_wide({{.*}} #[[UNSUP_RET]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_minmax_poison({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_minmax_fastcc({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_minmax_malformed({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_minmax_returns_twice({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_minmax_sret({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_minmax_scalable({{.*}} #[[UNSUP_RET]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_minmax_musttail({{.*}} #[[UNSUP_MT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call <4 x i32> @llvm.smin.v4i32(
; VIRT: define {{.*}} @unsupported_minmax_bundle({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call <4 x i32> @llvm.smin.v4i32({{.*}}[ "deopt"(i32 0) ]
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_MT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_RET]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
