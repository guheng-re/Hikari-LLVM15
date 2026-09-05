; Restricted llvm.ctpop / bswap / bitreverse / ctlz / cttz / fshl / fshr
; on fixed i8/i16/i32/i64 vectors (each side total 1..128).  Replayed
; via the existing CallDescriptor and vector VReg frame.  Scalar bit
; helpers, restricted scalar i128 bit/rotate, ordinary vector
; arithmetic, half gating, and VMP internal decode fshl stay unchanged.
; i1/i128 elements, float/half/bfloat, scalable, pointer, aggregate,
; and >128 stay out.  bswap is i16/i32/i64 only (i8 is not well-formed
; LLVM IR).  ctlz/cttz keep the i1 ImmArg on ImmediateArguments; true
; is only used with non-zero lanes.  fshl/fshr accept ordinary
; two-operand funnel (A and B need not be the same SSA).  C, exact
; non-vararg FTy, formal type equality, true ImmArg.  Ordinary tail,
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
declare <16 x i8> @llvm.ctpop.v16i8(<16 x i8>)
declare <8 x i8> @llvm.bitreverse.v8i8(<8 x i8>)
declare <8 x i16> @llvm.bswap.v8i16(<8 x i16>)
declare <8 x i16> @llvm.cttz.v8i16(<8 x i16>, i1 immarg)
declare <2 x i32> @llvm.bswap.v2i32(<2 x i32>)
declare <4 x i32> @llvm.bitreverse.v4i32(<4 x i32>)
declare <4 x i32> @llvm.ctlz.v4i32(<4 x i32>, i1 immarg)
declare <4 x i32> @llvm.cttz.v4i32(<4 x i32>, i1 immarg)
declare <4 x i32> @llvm.ctpop.v4i32(<4 x i32>)
declare <4 x i32> @llvm.fshl.v4i32(<4 x i32>, <4 x i32>, <4 x i32>)
declare <2 x i64> @llvm.ctlz.v2i64(<2 x i64>, i1 immarg)
declare <2 x i64> @llvm.fshr.v2i64(<2 x i64>, <2 x i64>, <2 x i64>)
declare <3 x i32> @llvm.ctpop.v3i32(<3 x i32>)
declare <3 x i32> @llvm.fshl.v3i32(<3 x i32>, <3 x i32>, <3 x i32>)
declare <16 x i8> @llvm.cttz.v16i8(<16 x i8>, i1 immarg)
declare <8 x i1> @llvm.ctpop.v8i1(<8 x i1>)
declare <1 x i128> @llvm.ctpop.v1i128(<1 x i128>)
declare <4 x half> @llvm.fabs.v4f16(<4 x half>)
declare <4 x bfloat> @llvm.fabs.v4bf16(<4 x bfloat>)
declare <vscale x 4 x i32> @llvm.ctpop.nxv4i32(<vscale x 4 x i32>)
declare <8 x i32> @llvm.ctpop.v8i32(<8 x i32>)
declare <3 x i32> @llvm.smul.fix.v3i32(<3 x i32>, <3 x i32>, i32 immarg)
declare <8 x i1> @llvm.fshl.v8i1(<8 x i1>, <8 x i1>, <8 x i1>)

declare <4 x half> @llvm.experimental.constrained.pow.v4f16(<4 x half>, <4 x half>, metadata, metadata)

define <16 x i8> @reference_ctpop_v16i8(<16 x i8> %a) {
entry:
  %r = call <16 x i8> @llvm.ctpop.v16i8(<16 x i8> %a)
  ret <16 x i8> %r
}

define <16 x i8> @protected_ctpop_v16i8(<16 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <16 x i8> @llvm.ctpop.v16i8(<16 x i8> %a)
  ret <16 x i8> %r
}

define <8 x i8> @reference_bitreverse_v8i8(<8 x i8> %a) {
entry:
  %r = call <8 x i8> @llvm.bitreverse.v8i8(<8 x i8> %a)
  ret <8 x i8> %r
}

define <8 x i8> @protected_bitreverse_v8i8(<8 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i8> @llvm.bitreverse.v8i8(<8 x i8> %a)
  ret <8 x i8> %r
}

define <8 x i16> @reference_bswap_v8i16(<8 x i16> %a) {
entry:
  %r = call <8 x i16> @llvm.bswap.v8i16(<8 x i16> %a)
  ret <8 x i16> %r
}

define <8 x i16> @protected_bswap_v8i16(<8 x i16> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i16> @llvm.bswap.v8i16(<8 x i16> %a)
  ret <8 x i16> %r
}

define <2 x i32> @reference_bswap_v2i32(<2 x i32> %a) {
entry:
  %r = call <2 x i32> @llvm.bswap.v2i32(<2 x i32> %a)
  ret <2 x i32> %r
}

define <2 x i32> @protected_bswap_v2i32(<2 x i32> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i32> @llvm.bswap.v2i32(<2 x i32> %a)
  ret <2 x i32> %r
}

define <4 x i32> @reference_bitreverse_v4i32(<4 x i32> %a) {
entry:
  %r = call <4 x i32> @llvm.bitreverse.v4i32(<4 x i32> %a)
  ret <4 x i32> %r
}

define <4 x i32> @protected_bitreverse_v4i32(<4 x i32> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.bitreverse.v4i32(<4 x i32> %a)
  ret <4 x i32> %r
}

define <4 x i32> @reference_ctlz_v4i32(<4 x i32> %a, <4 x i32> %nz) {
entry:
  %z = call <4 x i32> @llvm.ctlz.v4i32(<4 x i32> %a, i1 false)
  %t = call <4 x i32> @llvm.ctlz.v4i32(<4 x i32> %nz, i1 true)
  %r = xor <4 x i32> %z, %t
  ret <4 x i32> %r
}

define <4 x i32> @protected_ctlz_v4i32(<4 x i32> %a, <4 x i32> %nz) noinline optnone {
entry:
  call void @hikari_vmp()
  %z = call <4 x i32> @llvm.ctlz.v4i32(<4 x i32> %a, i1 false)
  %t = call <4 x i32> @llvm.ctlz.v4i32(<4 x i32> %nz, i1 true)
  %r = xor <4 x i32> %z, %t
  ret <4 x i32> %r
}

define <8 x i16> @reference_cttz_v8i16(<8 x i16> %a, <8 x i16> %nz) {
entry:
  %z = call <8 x i16> @llvm.cttz.v8i16(<8 x i16> %a, i1 false)
  %t = call <8 x i16> @llvm.cttz.v8i16(<8 x i16> %nz, i1 true)
  %r = xor <8 x i16> %z, %t
  ret <8 x i16> %r
}

define <8 x i16> @protected_cttz_v8i16(<8 x i16> %a, <8 x i16> %nz) noinline optnone {
entry:
  call void @hikari_vmp()
  %z = call <8 x i16> @llvm.cttz.v8i16(<8 x i16> %a, i1 false)
  %t = call <8 x i16> @llvm.cttz.v8i16(<8 x i16> %nz, i1 true)
  %r = xor <8 x i16> %z, %t
  ret <8 x i16> %r
}

define <2 x i64> @reference_ctlz_v2i64(<2 x i64> %a) {
entry:
  %r = call <2 x i64> @llvm.ctlz.v2i64(<2 x i64> %a, i1 false)
  ret <2 x i64> %r
}

define <2 x i64> @protected_ctlz_v2i64(<2 x i64> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.ctlz.v2i64(<2 x i64> %a, i1 false)
  ret <2 x i64> %r
}

define <4 x i32> @reference_fshl_v4i32(<4 x i32> %a, <4 x i32> %b, <4 x i32> %n) {
entry:
  %r = call <4 x i32> @llvm.fshl.v4i32(<4 x i32> %a, <4 x i32> %b, <4 x i32> %n)
  ret <4 x i32> %r
}

define <4 x i32> @protected_fshl_v4i32(<4 x i32> %a, <4 x i32> %b, <4 x i32> %n) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.fshl.v4i32(<4 x i32> %a, <4 x i32> %b, <4 x i32> %n)
  ret <4 x i32> %r
}

define <2 x i64> @reference_fshr_v2i64(<2 x i64> %a, <2 x i64> %b, <2 x i64> %n) {
entry:
  %r = call <2 x i64> @llvm.fshr.v2i64(<2 x i64> %a, <2 x i64> %b, <2 x i64> %n)
  ret <2 x i64> %r
}

define <2 x i64> @protected_fshr_v2i64(<2 x i64> %a, <2 x i64> %b, <2 x i64> %n) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.fshr.v2i64(<2 x i64> %a, <2 x i64> %b, <2 x i64> %n)
  ret <2 x i64> %r
}

define <3 x i32> @reference_ctpop_v3i32(<3 x i32> %a) {
entry:
  %r = call <3 x i32> @llvm.ctpop.v3i32(<3 x i32> %a)
  ret <3 x i32> %r
}

define <3 x i32> @protected_ctpop_v3i32(<3 x i32> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <3 x i32> @llvm.ctpop.v3i32(<3 x i32> %a)
  ret <3 x i32> %r
}

define <3 x i32> @reference_fshl_v3i32(<3 x i32> %a, <3 x i32> %b, <3 x i32> %n) {
entry:
  %r = call <3 x i32> @llvm.fshl.v3i32(<3 x i32> %a, <3 x i32> %b, <3 x i32> %n)
  ret <3 x i32> %r
}

define <3 x i32> @protected_fshl_v3i32(<3 x i32> %a, <3 x i32> %b, <3 x i32> %n) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <3 x i32> @llvm.fshl.v3i32(<3 x i32> %a, <3 x i32> %b, <3 x i32> %n)
  ret <3 x i32> %r
}

define <4 x i32> @reference_ctpop_phi_v4i32(<4 x i32> %a, <4 x i32> %b, i1 %c) {
entry:
  br i1 %c, label %left, label %right
left:
  %l = call <4 x i32> @llvm.ctpop.v4i32(<4 x i32> %a)
  br label %join
right:
  %r = call <4 x i32> @llvm.ctpop.v4i32(<4 x i32> %b)
  br label %join
join:
  %p = phi <4 x i32> [ %l, %left ], [ %r, %right ]
  ret <4 x i32> %p
}

define <4 x i32> @protected_ctpop_phi_v4i32(<4 x i32> %a, <4 x i32> %b, i1 %c) noinline optnone {
entry:
  call void @hikari_vmp()
  br i1 %c, label %left, label %right
left:
  %l = call <4 x i32> @llvm.ctpop.v4i32(<4 x i32> %a)
  br label %join
right:
  %r = call <4 x i32> @llvm.ctpop.v4i32(<4 x i32> %b)
  br label %join
join:
  %p = phi <4 x i32> [ %l, %left ], [ %r, %right ]
  ret <4 x i32> %p
}

define <4 x i32> @reference_ctpop_loop_v4i32(<4 x i32> %a, i32 %n) {
entry:
  br label %hdr
hdr:
  %acc = phi <4 x i32> [ %a, %entry ], [ %nxt, %hdr ]
  %i = phi i32 [ 0, %entry ], [ %i.nxt, %hdr ]
  %cur = call <4 x i32> @llvm.ctpop.v4i32(<4 x i32> %acc)
  %nxt = add <4 x i32> %acc, <i32 1, i32 -1, i32 2, i32 0>
  %i.nxt = add i32 %i, 1
  %more = icmp ult i32 %i.nxt, %n
  br i1 %more, label %hdr, label %done
done:
  ret <4 x i32> %cur
}

define <4 x i32> @protected_ctpop_loop_v4i32(<4 x i32> %a, i32 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  br label %hdr
hdr:
  %acc = phi <4 x i32> [ %a, %entry ], [ %nxt, %hdr ]
  %i = phi i32 [ 0, %entry ], [ %i.nxt, %hdr ]
  %cur = call <4 x i32> @llvm.ctpop.v4i32(<4 x i32> %acc)
  %nxt = add <4 x i32> %acc, <i32 1, i32 -1, i32 2, i32 0>
  %i.nxt = add i32 %i, 1
  %more = icmp ult i32 %i.nxt, %n
  br i1 %more, label %hdr, label %done
done:
  ret <4 x i32> %cur
}

; ----- negatives: selected, not virtualized -----


define <4 x i32> @unsupported_bit_malformed(<4 x i32> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.ctpop.v4i32(<4 x i32> %a) noreturn
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_bit_returns_twice(<4 x i32> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.ctpop.v4i32(<4 x i32> %a) returns_twice
  ret <4 x i32> %r
}

define void @unsupported_bit_sret(ptr sret(i32) %p, ptr byval(i32) %q) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @ext_sret_byval(ptr sret(i32) %p, ptr byval(i32) %q)
  ret void
}

define <8 x i1> @unsupported_bit_i1(<8 x i1> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i1> @llvm.ctpop.v8i1(<8 x i1> %a)
  ret <8 x i1> %r
}

define <1 x i128> @unsupported_bit_i128(<1 x i128> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <1 x i128> @llvm.ctpop.v1i128(<1 x i128> %a)
  ret <1 x i128> %r
}

define <4 x half> @unsupported_bit_half(<4 x half> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x half> @llvm.fabs.v4f16(<4 x half> %a)
  ret <4 x half> %r
}

define <4 x bfloat> @unsupported_bit_bfloat(<4 x bfloat> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x bfloat> @llvm.fabs.v4bf16(<4 x bfloat> %a)
  ret <4 x bfloat> %r
}

define i64 @unsupported_bit_fp128(<1 x fp128> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  ret i64 0
}

define <vscale x 4 x i32> @unsupported_bit_scalable(<vscale x 4 x i32> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.ctpop.nxv4i32(<vscale x 4 x i32> %a)
  ret <vscale x 4 x i32> %r
}

define <8 x i32> @unsupported_bit_wide(<8 x i32> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i32> @llvm.ctpop.v8i32(<8 x i32> %a)
  ret <8 x i32> %r
}

define <8 x i1> @unsupported_bit_fshl_i1(<8 x i1> %a, <8 x i1> %b, <8 x i1> %n) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i1> @llvm.fshl.v8i1(<8 x i1> %a, <8 x i1> %b, <8 x i1> %n)
  ret <8 x i1> %r
}

; Leftover 96-bit smul.fix stays out of the 64/128-only vector
; fix-point surface (AArch64 llc crashes on this width).
define <3 x i32> @unsupported_bit_fix(<3 x i32> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <3 x i32> @llvm.smul.fix.v3i32(<3 x i32> %a, <3 x i32> %a, i32 2)
  ret <3 x i32> %r
}

define <4 x i32> @unsupported_bit_fastcc(<4 x i32> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc <4 x i32> @llvm.ctpop.v4i32(<4 x i32> %a)
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_bit_musttail(<4 x i32> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call <4 x i32> @llvm.ctpop.v4i32(<4 x i32> %a)
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_bit_bundle(<4 x i32> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.ctpop.v4i32(<4 x i32> %a) [ "deopt"(i32 0) ]
  ret <4 x i32> %r
}

define <4 x half> @unsupported_bit_constrained(<4 x half> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x half> @llvm.experimental.constrained.pow.v4f16(<4 x half> %a, <4 x half> %a, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret <4 x half> %r
}

define <4 x i32> @unsupported_bit_poison(<4 x i32> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.ctpop.v4i32(<4 x i32> poison)
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
  %a8 = add <16 x i8> <i8 1, i8 2, i8 4, i8 8, i8 15, i8 16, i8 32, i8 64, i8 127, i8 -1, i8 -128, i8 3, i8 5, i8 6, i8 7, i8 9>, zeroinitializer
  %er0 = call <16 x i8> @reference_ctpop_v16i8(<16 x i8> %a8)
  %ar0 = call <16 x i8> @protected_ctpop_v16i8(<16 x i8> %a8)
  %er0c = bitcast <16 x i8> %er0 to <4 x i32>
  %ar0c = bitcast <16 x i8> %ar0 to <4 x i32>
  %em0 = call i32 @vec_i32_mix(<4 x i32> %er0c)
  %am0 = call i32 @vec_i32_mix(<4 x i32> %ar0c)
  %m0 = icmp eq i32 %em0, %am0

  %b8 = add <8 x i8> <i8 1, i8 2, i8 4, i8 8, i8 15, i8 -1, i8 128, i8 7>, zeroinitializer
  %er1 = call <8 x i8> @reference_bitreverse_v8i8(<8 x i8> %b8)
  %ar1 = call <8 x i8> @protected_bitreverse_v8i8(<8 x i8> %b8)
  %er1z = zext <8 x i8> %er1 to <8 x i16>
  %ar1z = zext <8 x i8> %ar1 to <8 x i16>
  %er1c = bitcast <8 x i16> %er1z to <4 x i32>
  %ar1c = bitcast <8 x i16> %ar1z to <4 x i32>
  %em1 = call i32 @vec_i32_mix(<4 x i32> %er1c)
  %am1 = call i32 @vec_i32_mix(<4 x i32> %ar1c)
  %m1 = icmp eq i32 %em1, %am1

  %a16 = add <8 x i16> <i16 1, i16 256, i16 -2, i16 4096, i16 7, i16 -1, i16 128, i16 9>, zeroinitializer
  %er2 = call <8 x i16> @reference_bswap_v8i16(<8 x i16> %a16)
  %ar2 = call <8 x i16> @protected_bswap_v8i16(<8 x i16> %a16)
  %er2c = bitcast <8 x i16> %er2 to <4 x i32>
  %ar2c = bitcast <8 x i16> %ar2 to <4 x i32>
  %em2 = call i32 @vec_i32_mix(<4 x i32> %er2c)
  %am2 = call i32 @vec_i32_mix(<4 x i32> %ar2c)
  %m2 = icmp eq i32 %em2, %am2

  %nz16 = or <8 x i16> %a16, <i16 1, i16 1, i16 1, i16 1, i16 1, i16 1, i16 1, i16 1>
  %er2t = call <8 x i16> @reference_cttz_v8i16(<8 x i16> %a16, <8 x i16> %nz16)
  %ar2t = call <8 x i16> @protected_cttz_v8i16(<8 x i16> %a16, <8 x i16> %nz16)
  %er2tc = bitcast <8 x i16> %er2t to <4 x i32>
  %ar2tc = bitcast <8 x i16> %ar2t to <4 x i32>
  %em2t = call i32 @vec_i32_mix(<4 x i32> %er2tc)
  %am2t = call i32 @vec_i32_mix(<4 x i32> %ar2tc)
  %m2t = icmp eq i32 %em2t, %am2t

  %a2 = add <2 x i32> <i32 16909060, i32 -2>, zeroinitializer
  %er3 = call <2 x i32> @reference_bswap_v2i32(<2 x i32> %a2)
  %ar3 = call <2 x i32> @protected_bswap_v2i32(<2 x i32> %a2)
  %e30 = extractelement <2 x i32> %er3, i32 0
  %e31 = extractelement <2 x i32> %er3, i32 1
  %a30 = extractelement <2 x i32> %ar3, i32 0
  %a31 = extractelement <2 x i32> %ar3, i32 1
  %ex3 = xor i32 %e30, %e31
  %ax3 = xor i32 %a30, %a31
  %m3 = icmp eq i32 %ex3, %ax3

  %a32 = add <4 x i32> <i32 1, i32 2, i32 -1, i32 16>, zeroinitializer
  %er4 = call <4 x i32> @reference_bitreverse_v4i32(<4 x i32> %a32)
  %ar4 = call <4 x i32> @protected_bitreverse_v4i32(<4 x i32> %a32)
  %em4 = call i32 @vec_i32_mix(<4 x i32> %er4)
  %am4 = call i32 @vec_i32_mix(<4 x i32> %ar4)
  %m4 = icmp eq i32 %em4, %am4

  %nz32 = or <4 x i32> %a32, <i32 1, i32 1, i32 1, i32 1>
  %er5 = call <4 x i32> @reference_ctlz_v4i32(<4 x i32> %a32, <4 x i32> %nz32)
  %ar5 = call <4 x i32> @protected_ctlz_v4i32(<4 x i32> %a32, <4 x i32> %nz32)
  %em5 = call i32 @vec_i32_mix(<4 x i32> %er5)
  %am5 = call i32 @vec_i32_mix(<4 x i32> %ar5)
  %m5 = icmp eq i32 %em5, %am5

  %a64 = add <2 x i64> <i64 1, i64 16>, zeroinitializer
  %er6 = call <2 x i64> @reference_ctlz_v2i64(<2 x i64> %a64)
  %ar6 = call <2 x i64> @protected_ctlz_v2i64(<2 x i64> %a64)
  %er6c = bitcast <2 x i64> %er6 to <4 x i32>
  %ar6c = bitcast <2 x i64> %ar6 to <4 x i32>
  %em6 = call i32 @vec_i32_mix(<4 x i32> %er6c)
  %am6 = call i32 @vec_i32_mix(<4 x i32> %ar6c)
  %m6 = icmp eq i32 %em6, %am6

  %b32 = add <4 x i32> <i32 9, i32 4, i32 3, i32 1>, zeroinitializer
  %n32 = add <4 x i32> <i32 1, i32 2, i32 3, i32 5>, zeroinitializer
  %er7 = call <4 x i32> @reference_fshl_v4i32(<4 x i32> %a32, <4 x i32> %b32, <4 x i32> %n32)
  %ar7 = call <4 x i32> @protected_fshl_v4i32(<4 x i32> %a32, <4 x i32> %b32, <4 x i32> %n32)
  %em7 = call i32 @vec_i32_mix(<4 x i32> %er7)
  %am7 = call i32 @vec_i32_mix(<4 x i32> %ar7)
  %m7 = icmp eq i32 %em7, %am7

  %b64 = add <2 x i64> <i64 3, i64 5>, zeroinitializer
  %n64 = add <2 x i64> <i64 1, i64 4>, zeroinitializer
  %er8 = call <2 x i64> @reference_fshr_v2i64(<2 x i64> %a64, <2 x i64> %b64, <2 x i64> %n64)
  %ar8 = call <2 x i64> @protected_fshr_v2i64(<2 x i64> %a64, <2 x i64> %b64, <2 x i64> %n64)
  %er8c = bitcast <2 x i64> %er8 to <4 x i32>
  %ar8c = bitcast <2 x i64> %ar8 to <4 x i32>
  %em8 = call i32 @vec_i32_mix(<4 x i32> %er8c)
  %am8 = call i32 @vec_i32_mix(<4 x i32> %ar8c)
  %m8 = icmp eq i32 %em8, %am8

  %a3 = add <3 x i32> <i32 1, i32 2, i32 15>, zeroinitializer
  %er9 = call <3 x i32> @reference_ctpop_v3i32(<3 x i32> %a3)
  %ar9 = call <3 x i32> @protected_ctpop_v3i32(<3 x i32> %a3)
  %e90 = extractelement <3 x i32> %er9, i32 0
  %e91 = extractelement <3 x i32> %er9, i32 1
  %e92 = extractelement <3 x i32> %er9, i32 2
  %a90 = extractelement <3 x i32> %ar9, i32 0
  %a91 = extractelement <3 x i32> %ar9, i32 1
  %a92 = extractelement <3 x i32> %ar9, i32 2
  %ex9 = xor i32 %e90, %e91
  %ey9 = xor i32 %ex9, %e92
  %ax9 = xor i32 %a90, %a91
  %ay9 = xor i32 %ax9, %a92
  %m9 = icmp eq i32 %ey9, %ay9

  %b3 = add <3 x i32> <i32 8, i32 4, i32 1>, zeroinitializer
  %n3 = add <3 x i32> <i32 1, i32 2, i32 3>, zeroinitializer
  %er10 = call <3 x i32> @reference_fshl_v3i32(<3 x i32> %a3, <3 x i32> %b3, <3 x i32> %n3)
  %ar10 = call <3 x i32> @protected_fshl_v3i32(<3 x i32> %a3, <3 x i32> %b3, <3 x i32> %n3)
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

  %er11 = call <4 x i32> @reference_ctpop_phi_v4i32(<4 x i32> %a32, <4 x i32> %b32, i1 true)
  %ar11 = call <4 x i32> @protected_ctpop_phi_v4i32(<4 x i32> %a32, <4 x i32> %b32, i1 true)
  %em11 = call i32 @vec_i32_mix(<4 x i32> %er11)
  %am11 = call i32 @vec_i32_mix(<4 x i32> %ar11)
  %m11 = icmp eq i32 %em11, %am11

  %er12 = call <4 x i32> @reference_ctpop_phi_v4i32(<4 x i32> %a32, <4 x i32> %b32, i1 false)
  %ar12 = call <4 x i32> @protected_ctpop_phi_v4i32(<4 x i32> %a32, <4 x i32> %b32, i1 false)
  %em12 = call i32 @vec_i32_mix(<4 x i32> %er12)
  %am12 = call i32 @vec_i32_mix(<4 x i32> %ar12)
  %m12 = icmp eq i32 %em12, %am12

  %er13 = call <4 x i32> @reference_ctpop_loop_v4i32(<4 x i32> %a32, i32 2)
  %ar13 = call <4 x i32> @protected_ctpop_loop_v4i32(<4 x i32> %a32, i32 2)
  %em13 = call i32 @vec_i32_mix(<4 x i32> %er13)
  %am13 = call i32 @vec_i32_mix(<4 x i32> %ar13)
  %m13 = icmp eq i32 %em13, %am13

  %t0 = and i1 %m0, %m1
  %t1 = and i1 %m2, %m2t
  %t2 = and i1 %m3, %m4
  %t3 = and i1 %m5, %m6
  %t4 = and i1 %m7, %m8
  %t5 = and i1 %m9, %m10
  %t6 = and i1 %m11, %m12
  %u0 = and i1 %t0, %t1
  %u1 = and i1 %t2, %t3
  %u2 = and i1 %t4, %t5
  %u3 = and i1 %t6, %m13
  %v0 = and i1 %u0, %u1
  %v1 = and i1 %u2, %u3
  %ok = and i1 %v0, %v1
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_bit_i1: unsupported ctpop
; SKIP-DAG: Skipping VMP on unsupported_bit_i128: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_bit_half: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_bit_bfloat: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_bit_fp128: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_bit_scalable: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_bit_wide: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_bit_fshl_i1: unsupported fshl
; SKIP-DAG: Skipping VMP on unsupported_bit_fix: unsupported smul.fix
; SKIP-DAG: Skipping VMP on unsupported_bit_fastcc: unsupported ctpop
; SKIP-DAG: Skipping VMP on unsupported_bit_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bit_bundle: unsupported ctpop
; SKIP-DAG: Skipping VMP on unsupported_bit_constrained: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_bit_poison: unsupported ctpop
; SKIP-DAG: Skipping VMP on unsupported_bit_malformed: unsupported ctpop
; SKIP-DAG: Skipping VMP on unsupported_bit_returns_twice: unsupported ctpop
; SKIP-DAG: Skipping VMP on unsupported_bit_sret: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_ctpop_v16i8:
; SKIP-NOT: Skipping VMP on protected_bitreverse_v8i8:
; SKIP-NOT: Skipping VMP on protected_bswap_v8i16:
; SKIP-NOT: Skipping VMP on protected_bswap_v2i32:
; SKIP-NOT: Skipping VMP on protected_bitreverse_v4i32:
; SKIP-NOT: Skipping VMP on protected_ctlz_v4i32:
; SKIP-NOT: Skipping VMP on protected_cttz_v8i16:
; SKIP-NOT: Skipping VMP on protected_ctlz_v2i64:
; SKIP-NOT: Skipping VMP on protected_fshl_v4i32:
; SKIP-NOT: Skipping VMP on protected_fshr_v2i64:
; SKIP-NOT: Skipping VMP on protected_ctpop_v3i32:
; SKIP-NOT: Skipping VMP on protected_fshl_v3i32:
; SKIP-NOT: Skipping VMP on protected_ctpop_phi_v4i32:
; SKIP-NOT: Skipping VMP on protected_ctpop_loop_v4i32:

; VIRT: define <16 x i8> @protected_ctpop_v16i8({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <16 x i8> @llvm.ctpop.v16i8(
; VIRT: define <8 x i8> @protected_bitreverse_v8i8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x i8> @llvm.bitreverse.v8i8(
; VIRT: define <8 x i16> @protected_bswap_v8i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x i16> @llvm.bswap.v8i16(
; VIRT: define <2 x i32> @protected_bswap_v2i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i32> @llvm.bswap.v2i32(
; VIRT: define <4 x i32> @protected_bitreverse_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.bitreverse.v4i32(
; VIRT: define <4 x i32> @protected_ctlz_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: call <4 x i32> @llvm.ctlz.v4i32({{.*}}, i1 false)
; VIRT-DAG: call <4 x i32> @llvm.ctlz.v4i32({{.*}}, i1 true)
; VIRT: define <8 x i16> @protected_cttz_v8i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: call <8 x i16> @llvm.cttz.v8i16({{.*}}, i1 false)
; VIRT-DAG: call <8 x i16> @llvm.cttz.v8i16({{.*}}, i1 true)
; VIRT: define <2 x i64> @protected_ctlz_v2i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i64> @llvm.ctlz.v2i64({{.*}}, i1 false)
; VIRT: define <4 x i32> @protected_fshl_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.fshl.v4i32(
; VIRT: define <2 x i64> @protected_fshr_v2i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i64> @llvm.fshr.v2i64(
; VIRT: define <3 x i32> @protected_ctpop_v3i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <3 x i32> @llvm.ctpop.v3i32(
; VIRT: define <3 x i32> @protected_fshl_v3i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <3 x i32> @llvm.fshl.v3i32(
; VIRT: define <4 x i32> @protected_ctpop_phi_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.ctpop.v4i32(
; VIRT: define <4 x i32> @protected_ctpop_loop_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.ctpop.v4i32(
; VIRT: define {{.*}} @unsupported_bit_malformed({{.*}} #[[UNSUPATTR:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_bit_returns_twice({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_bit_sret({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_bit_i1({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_bit_i128({{.*}} #[[UNSUP_I128:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_bit_half({{.*}} #[[UNSUP_H:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_bit_bfloat({{.*}} #[[UNSUP_ARG:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_bit_fp128({{.*}} #[[UNSUP_ARG]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_bit_scalable({{.*}} #[[UNSUP_SC:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_bit_wide({{.*}} #[[UNSUP_W:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_bit_fshl_i1({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_bit_fix({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_bit_fastcc({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_bit_musttail({{.*}} #[[UNSUP_MT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call <4 x i32> @llvm.ctpop.v4i32(
; VIRT: define {{.*}} @unsupported_bit_bundle({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call <4 x i32> @llvm.ctpop.v4i32({{.*}}[ "deopt"(i32 0) ]
; VIRT: define {{.*}} @unsupported_bit_constrained({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_bit_poison({{.*}} #[[UNSUPATTR]] {
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

; AARCH64: Arch: aarch64
