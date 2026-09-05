; Restricted fixed bfloat-vector VMP on the existing i128 vector VReg
; frame.  Total width 1..128, bfloat elements, last-token function
; "target-features" +bf16 only (exact token; +bf16fml / +fullfp16 do
; not count; command-line -mattr is never read).  Well-shaped bfloat
; vector SSA missing or ending in -bf16 skips as unsupported target
; feature and keeps hikari.vmp.selected.
;
; Covers args/returns, constants, phi, select, freeze, non-atomic AS0
; load/store, extractelement/insertelement, constant-mask
; shufflevector, same-width bitcast to integer vectors/scalars,
; fadd/fsub/fmul/fdiv/frem/fneg/fcmp, same-lane N=1..4 fpext
; <N x bfloat> -> <N x float> / fptrunc <N x float> -> <N x bfloat>
; (both vector VRegs stay <=128 bits), and same-lane sitofp/uitofp
; / fptosi/fptoui between i1/i8/i16/i32/i64 vectors and bfloat
; vectors when each side is independently <=128 bits.  No new VM
; opcode.  Arithmetic, fcmp, width casts, and integer conversions
; legalize lane-by-lane through existing scalar integer<->f32,
; bfloat->f32 promote, and exact RNE helpers; fneg/select/shuffle
; are i16 bit ops.  Native `fadd <N x bfloat>` /
; `shufflevector <N x bfloat>` / `fpext <N x bfloat>` /
; `fptrunc ... to <N x bfloat>` / `sitofp ... to <N x bfloat>` /
; `fptosi <N x bfloat>` must not reach AArch64 ISel.
;
; Not opened: FastMathFlags, atomics, unlisted vector calls/intrinsics
; (constrained stays closed; listed fabs/sqrt/fma/fmuladd are the independent
; +bf16 math surface; ordinary direct C bfloat-vector ABI is the
; independent vmp-bfloat-vector-call-semantic.ll surface), constrained
; FP, >128, scalable, aggregate bfloat fields, nonzero AS,
; bfloat<->half/double, N>4 f32 conversion, i128-element or overwide
; integer conversions, float-vector bitcasts.
;
; Host x86 cannot be assumed to select bfloat vectors.  This lit is
; FileCheck + AArch64 llc/readobj only (function +bf16, no global
; -mattr).  Do not invent a host lli semantic oracle.
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
declare <4 x bfloat> @llvm.fabs.v4bf16(<4 x bfloat>)
declare <4 x bfloat> @llvm.experimental.constrained.fadd.v4bf16(<4 x bfloat>, <4 x bfloat>, metadata, metadata)
declare <4 x bfloat> @ext_v4bf16(<4 x bfloat>)

@g.v4bf16 = private global <4 x bfloat> zeroinitializer, align 8

; ----- positives (last-token +bf16) -----

define <4 x bfloat> @protected_add_v4(<4 x bfloat> %a, <4 x bfloat> %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %s = fadd <4 x bfloat> %a, %b
  ret <4 x bfloat> %s
}

define <4 x bfloat> @protected_ret_v4(<4 x bfloat> %a) noinline optnone "target-features"="+neon,+bf16" {
entry:
  call void @hikari_vmp()
  ret <4 x bfloat> %a
}

define <4 x bfloat> @protected_work_v4(<4 x bfloat> %a, <4 x bfloat> %b, i32 %idx) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %s = fadd <4 x bfloat> %a, %b
  %d = fsub <4 x bfloat> %s, %b
  %m = fmul <4 x bfloat> %d, %a
  %q = fdiv <4 x bfloat> %m, %a
  %r = frem <4 x bfloat> %q, %a
  %n = fneg <4 x bfloat> %r
  %c = fcmp ogt <4 x bfloat> %n, %b
  %sel = select <4 x i1> %c, <4 x bfloat> %n, <4 x bfloat> %b
  store <4 x bfloat> %sel, ptr @g.v4bf16, align 8
  %ld = load <4 x bfloat>, ptr @g.v4bf16, align 8
  %e = extractelement <4 x bfloat> %ld, i32 0
  %ins = insertelement <4 x bfloat> %ld, bfloat %e, i32 %idx
  %fr = freeze <4 x bfloat> %ins
  ret <4 x bfloat> %fr
}

define <4 x bfloat> @protected_phi_v4(i1 %c, <4 x bfloat> %a, <4 x bfloat> %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  br i1 %c, label %left, label %right
left:
  br label %join
right:
  br label %join
join:
  %p = phi <4 x bfloat> [ %a, %left ], [ %b, %right ]
  %s = select i1 %c, <4 x bfloat> %p, <4 x bfloat> %a
  ret <4 x bfloat> %s
}

define <4 x bfloat> @protected_loop_v4(<4 x bfloat> %a, i32 %n) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  br label %loop
loop:
  %iv = phi i32 [ 0, %entry ], [ %iv.next, %loop ]
  %acc = phi <4 x bfloat> [ %a, %entry ], [ %acc.next, %loop ]
  %acc.next = fadd <4 x bfloat> %acc, %a
  %iv.next = add i32 %iv, 1
  %cmp = icmp slt i32 %iv.next, %n
  br i1 %cmp, label %loop, label %done
done:
  ret <4 x bfloat> %acc.next
}

define <8 x bfloat> @protected_v8(<8 x bfloat> %a, <8 x bfloat> %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %s = fadd <8 x bfloat> %a, %b
  %e = extractelement <8 x bfloat> %s, i32 0
  %ins = insertelement <8 x bfloat> %s, bfloat %e, i32 7
  ret <8 x bfloat> %ins
}

define <4 x bfloat> @protected_last_token(<4 x bfloat> %a, <4 x bfloat> %b) noinline optnone "target-features"="-bf16,+neon,+bf16" {
entry:
  call void @hikari_vmp()
  %s = fadd <4 x bfloat> %a, %b
  ret <4 x bfloat> %s
}

define <4 x bfloat> @protected_shuffle_v4(<4 x bfloat> %a, <4 x bfloat> %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %s = shufflevector <4 x bfloat> %a, <4 x bfloat> %b, <4 x i32> <i32 0, i32 5, i32 2, i32 7>
  ret <4 x bfloat> %s
}

define <4 x i16> @protected_bitcast_v4i16(<4 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %v = bitcast <4 x bfloat> %a to <4 x i16>
  %b = bitcast <4 x i16> %v to <4 x bfloat>
  %r = bitcast <4 x bfloat> %b to <4 x i16>
  ret <4 x i16> %r
}

define i64 @protected_bitcast_i64(<4 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %w = bitcast <4 x bfloat> %a to i64
  %b = bitcast i64 %w to <4 x bfloat>
  %r = bitcast <4 x bfloat> %b to i64
  ret i64 %r
}

define <4 x float> @protected_fpext_v4(<4 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %e = fpext <4 x bfloat> %a to <4 x float>
  ret <4 x float> %e
}

define <4 x bfloat> @protected_fptrunc_v4(<4 x float> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %t = fptrunc <4 x float> %a to <4 x bfloat>
  ret <4 x bfloat> %t
}

define <4 x bfloat> @protected_fpext_fptrunc_v4(<4 x bfloat> %a, <4 x float> %x) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %e = fpext <4 x bfloat> %a to <4 x float>
  %s = fadd <4 x float> %e, %x
  %t = fptrunc <4 x float> %s to <4 x bfloat>
  ret <4 x bfloat> %t
}

define <2 x float> @protected_fpext_v2(<2 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %e = fpext <2 x bfloat> %a to <2 x float>
  ret <2 x float> %e
}

define <4 x bfloat> @protected_sitofp_v4i1(<4 x i1> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = sitofp <4 x i1> %a to <4 x bfloat>
  ret <4 x bfloat> %r
}

define <4 x bfloat> @protected_uitofp_v4i1(<4 x i1> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = uitofp <4 x i1> %a to <4 x bfloat>
  ret <4 x bfloat> %r
}

define <4 x i1> @protected_fptosi_v4i1(<4 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = fptosi <4 x bfloat> %a to <4 x i1>
  ret <4 x i1> %r
}

define <4 x i1> @protected_fptoui_v4i1(<4 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = fptoui <4 x bfloat> %a to <4 x i1>
  ret <4 x i1> %r
}

define <4 x bfloat> @protected_sitofp_v4i8(<4 x i8> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = sitofp <4 x i8> %a to <4 x bfloat>
  ret <4 x bfloat> %r
}

define <4 x bfloat> @protected_uitofp_v4i16(<4 x i16> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = uitofp <4 x i16> %a to <4 x bfloat>
  ret <4 x bfloat> %r
}

define <4 x bfloat> @protected_sitofp_v4i32(<4 x i32> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = sitofp <4 x i32> %a to <4 x bfloat>
  ret <4 x bfloat> %r
}

define <4 x bfloat> @protected_uitofp_v4i32(<4 x i32> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = uitofp <4 x i32> %a to <4 x bfloat>
  ret <4 x bfloat> %r
}

define <4 x i32> @protected_fptosi_v4i32(<4 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = fptosi <4 x bfloat> %a to <4 x i32>
  ret <4 x i32> %r
}

define <4 x i32> @protected_fptoui_v4i32(<4 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = fptoui <4 x bfloat> %a to <4 x i32>
  ret <4 x i32> %r
}

define <2 x bfloat> @protected_sitofp_v2i64(<2 x i64> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = sitofp <2 x i64> %a to <2 x bfloat>
  ret <2 x bfloat> %r
}

define <2 x i64> @protected_fptosi_v2i64(<2 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = fptosi <2 x bfloat> %a to <2 x i64>
  ret <2 x i64> %r
}

define <4 x i32> @protected_intcast_arith_v4(<4 x i32> %a, <4 x bfloat> %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %e = sitofp <4 x i32> %a to <4 x bfloat>
  %s = fadd <4 x bfloat> %e, %b
  %r = fptosi <4 x bfloat> %s to <4 x i32>
  ret <4 x i32> %r
}

; ----- negatives -----

; Pointer args keep the function type supported; the bfloat-vector
; load is well-shaped and skips as a feature miss (not a cast).
define i32 @unsupported_bf16_vec_no_feature(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %a = load <4 x bfloat>, ptr %p, align 8
  %s = fadd <4 x bfloat> %a, %a
  %e = extractelement <4 x bfloat> %s, i32 0
  %b = bitcast bfloat %e to i16
  %z = zext i16 %b to i32
  ret i32 %z
}

define i32 @unsupported_bf16_vec_disabled(ptr %p) noinline optnone "target-features"="+neon,+bf16,-bf16" {
entry:
  call void @hikari_vmp()
  %a = load <4 x bfloat>, ptr %p, align 8
  %s = fadd <4 x bfloat> %a, %a
  %e = extractelement <4 x bfloat> %s, i32 0
  %b = bitcast bfloat %e to i16
  %z = zext i16 %b to i32
  ret i32 %z
}

define <4 x bfloat> @unsupported_bf16_vec_fmf(<4 x bfloat> %a, <4 x bfloat> %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %s = fadd nnan <4 x bfloat> %a, %b
  ret <4 x bfloat> %s
}

; LLVM 15 rejects atomic loads of bfloat vectors as invalid IR.
; A scalar atomic bfloat in a +bf16 vector function still fails closed.
define <4 x bfloat> @unsupported_bf16_vec_atomic(<4 x bfloat> %a, ptr %p) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %v = load atomic bfloat, ptr %p seq_cst, align 2
  %ins = insertelement <4 x bfloat> %a, bfloat %v, i32 0
  ret <4 x bfloat> %ins
}

; Listed fabs/sqrt/fma/fmuladd are the independent +bf16 math surface.
; constrained stays closed.
define <4 x bfloat> @unsupported_bf16_vec_math(<4 x bfloat> %a, <4 x bfloat> %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x bfloat> @llvm.experimental.constrained.fadd.v4bf16(<4 x bfloat> %a, <4 x bfloat> %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret <4 x bfloat> %r
}

; Ordinary C bfloat-vector ABI is the independent call surface.
; fastcc stays closed here.
define <4 x bfloat> @unsupported_bf16_vec_call(<4 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call fastcc <4 x bfloat> @ext_v4bf16(<4 x bfloat> %a)
  ret <4 x bfloat> %r
}

define <16 x bfloat> @unsupported_bf16_vec_wide(<16 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  ret <16 x bfloat> %a
}

define <vscale x 4 x bfloat> @unsupported_bf16_vec_scalable(<vscale x 4 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  ret <vscale x 4 x bfloat> %a
}

define i64 @unsupported_bf16_vec_shuffle_no_feature(i64 %x, i64 %y) noinline optnone {
entry:
  call void @hikari_vmp()
  %a = bitcast i64 %x to <4 x bfloat>
  %b = bitcast i64 %y to <4 x bfloat>
  %s = shufflevector <4 x bfloat> %a, <4 x bfloat> %b, <4 x i32> <i32 0, i32 5, i32 2, i32 7>
  %r = bitcast <4 x bfloat> %s to i64
  ret i64 %r
}

define i64 @unsupported_bf16_vec_bitcast_no_feature(i64 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %b = bitcast i64 %x to <4 x bfloat>
  %r = bitcast <4 x bfloat> %b to i64
  ret i64 %r
}

define <2 x float> @unsupported_bf16_vec_float_bitcast(<4 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = bitcast <4 x bfloat> %a to <2 x float>
  ret <2 x float> %r
}

; Unique feature miss on the width-cast itself: float source is already
; a supported vector frame without +bf16.
define i64 @unsupported_bf16_vec_fptrunc_no_feature(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = fptrunc <4 x float> %a to <4 x bfloat>
  %r = bitcast <4 x bfloat> %t to i64
  ret i64 %r
}

define i64 @unsupported_bf16_vec_fptrunc_disabled(<4 x float> %a) noinline optnone "target-features"="+neon,+bf16,-bf16" {
entry:
  call void @hikari_vmp()
  %t = fptrunc <4 x float> %a to <4 x bfloat>
  %r = bitcast <4 x bfloat> %t to i64
  ret i64 %r
}

; Same-width bfloat<->half is valid IR; fpext/fptrunc between them is not.
define <4 x half> @unsupported_bf16_vec_half_cast(<4 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = bitcast <4 x bfloat> %a to <4 x half>
  ret <4 x half> %r
}

define <2 x double> @unsupported_bf16_vec_fpext_double(<2 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = fpext <2 x bfloat> %a to <2 x double>
  ret <2 x double> %r
}

; Unique feature miss on the integer conversion: i32 source is already
; a supported vector frame without +bf16.
define i64 @unsupported_bf16_vec_sitofp_no_feature(<4 x i32> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = sitofp <4 x i32> %a to <4 x bfloat>
  %r = bitcast <4 x bfloat> %t to i64
  ret i64 %r
}

define i64 @unsupported_bf16_vec_sitofp_disabled(<4 x i32> %a) noinline optnone "target-features"="+neon,+bf16,-bf16" {
entry:
  call void @hikari_vmp()
  %t = sitofp <4 x i32> %a to <4 x bfloat>
  %r = bitcast <4 x bfloat> %t to i64
  ret i64 %r
}

; i128 elements stay closed.  Dest is not an i1..i64 vector frame.
define i128 @unsupported_bf16_vec_fptosi_i128(<1 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = fptosi <1 x bfloat> %a to <1 x i128>
  %s = extractelement <1 x i128> %r, i32 0
  ret i128 %s
}

; LLVM 15 sitofp/uitofp/fptosi/fptoui require equal element counts
; (verifier).  A lane-mismatch form is not well-formed IR.  Closest
; closed over-wide integer dest: <8 x bfloat> is in-surface, <8 x i32>
; is 256 bits.
define i32 @unsupported_bf16_vec_fptosi_wide(<8 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = fptosi <8 x bfloat> %a to <8 x i32>
  %e = extractelement <8 x i32> %r, i32 0
  ret i32 %e
}

; N=8 keeps the bfloat VReg at 128 bits; the f32 side is 256 bits.
define <8 x bfloat> @unsupported_bf16_vec_fpext_wide(<8 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %e = fpext <8 x bfloat> %a to <8 x float>
  %t = fptrunc <8 x float> %e to <8 x bfloat>
  ret <8 x bfloat> %t
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_bf16_vec_no_feature: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_bf16_vec_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_bf16_vec_fmf: unsupported float fadd instruction
; SKIP-DAG: Skipping VMP on unsupported_bf16_vec_atomic: unsupported float load instruction
; SKIP-DAG: Skipping VMP on unsupported_bf16_vec_math: unsupported call
; SKIP-DAG: Skipping VMP on unsupported_bf16_vec_call: unsupported call
; SKIP-DAG: Skipping VMP on unsupported_bf16_vec_wide: unsupported
; SKIP-DAG: Skipping VMP on unsupported_bf16_vec_scalable: unsupported
; SKIP-DAG: Skipping VMP on unsupported_bf16_vec_shuffle_no_feature: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_bf16_vec_bitcast_no_feature: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_bf16_vec_float_bitcast: unsupported vector cast instruction
; SKIP-DAG: Skipping VMP on unsupported_bf16_vec_fptrunc_no_feature: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_bf16_vec_fptrunc_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_bf16_vec_half_cast: unsupported vector cast instruction
; SKIP-DAG: Skipping VMP on unsupported_bf16_vec_fpext_double: unsupported vector cast instruction
; SKIP-DAG: Skipping VMP on unsupported_bf16_vec_sitofp_no_feature: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_bf16_vec_sitofp_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_bf16_vec_fptosi_i128: unsupported vector cast instruction
; SKIP-DAG: Skipping VMP on unsupported_bf16_vec_fptosi_wide: unsupported vector cast instruction
; SKIP-DAG: Skipping VMP on unsupported_bf16_vec_fpext_wide: unsupported vector cast instruction
; SKIP-NOT: Skipping VMP on protected_add_v4:
; SKIP-NOT: Skipping VMP on protected_ret_v4:
; SKIP-NOT: Skipping VMP on protected_work_v4:
; SKIP-NOT: Skipping VMP on protected_phi_v4:
; SKIP-NOT: Skipping VMP on protected_loop_v4:
; SKIP-NOT: Skipping VMP on protected_v8:
; SKIP-NOT: Skipping VMP on protected_last_token:
; SKIP-NOT: Skipping VMP on protected_shuffle_v4:
; SKIP-NOT: Skipping VMP on protected_bitcast_v4i16:
; SKIP-NOT: Skipping VMP on protected_bitcast_i64:
; SKIP-NOT: Skipping VMP on protected_fpext_v4:
; SKIP-NOT: Skipping VMP on protected_fptrunc_v4:
; SKIP-NOT: Skipping VMP on protected_fpext_fptrunc_v4:
; SKIP-NOT: Skipping VMP on protected_fpext_v2:
; SKIP-NOT: Skipping VMP on protected_sitofp_v4i1:
; SKIP-NOT: Skipping VMP on protected_uitofp_v4i1:
; SKIP-NOT: Skipping VMP on protected_fptosi_v4i1:
; SKIP-NOT: Skipping VMP on protected_fptoui_v4i1:
; SKIP-NOT: Skipping VMP on protected_sitofp_v4i8:
; SKIP-NOT: Skipping VMP on protected_uitofp_v4i16:
; SKIP-NOT: Skipping VMP on protected_sitofp_v4i32:
; SKIP-NOT: Skipping VMP on protected_uitofp_v4i32:
; SKIP-NOT: Skipping VMP on protected_fptosi_v4i32:
; SKIP-NOT: Skipping VMP on protected_fptoui_v4i32:
; SKIP-NOT: Skipping VMP on protected_sitofp_v2i64:
; SKIP-NOT: Skipping VMP on protected_fptosi_v2i64:
; SKIP-NOT: Skipping VMP on protected_intcast_arith_v4:

; VIRT: define <4 x bfloat> @protected_add_v4({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; Legalized bf16 vector add is f32 with no FastMathFlags.
; VIRT-NOT: fadd{{.*}}bfloat
; VIRT: fadd{{.*}} float
; Inf/NaN must not take the RNE bias-add.
; VIRT: icmp eq i32 {{.*}}, 2139095040
; VIRT: or i32 {{.*}}, 64
; VIRT: define <4 x bfloat> @protected_ret_v4({{.*}} #[[PROTNEON:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: define <4 x bfloat> @protected_work_v4({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: fadd{{.*}}bfloat
; VIRT-DAG: fadd{{.*}} float
; VIRT-DAG: fsub{{.*}} float
; VIRT-DAG: fmul{{.*}} float
; VIRT-DAG: fdiv{{.*}} float
; VIRT-DAG: frem{{.*}} float
; VIRT-DAG: fcmp{{.*}} float
; VIRT-DAG: load <4 x bfloat>
; VIRT-DAG: store <4 x bfloat>
; VIRT-DAG: extractelement <4 x bfloat>
; VIRT-DAG: insertelement <4 x bfloat>
; VIRT-DAG: freeze <4 x bfloat>
; VIRT: define <4 x bfloat> @protected_phi_v4({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <4 x bfloat> @protected_loop_v4({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: fadd{{.*}} float
; VIRT: define <8 x bfloat> @protected_v8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: fadd{{.*}}bfloat
; VIRT: fadd{{.*}} float
; VIRT: define <4 x bfloat> @protected_last_token({{.*}} #[[PROTLAST:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: fadd{{.*}} float
; VIRT: define <4 x bfloat> @protected_shuffle_v4({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: shufflevector <4 x bfloat>
; VIRT: shufflevector <4 x i16>
; VIRT: define <4 x i16> @protected_bitcast_v4i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: bitcast <4 x bfloat> {{.*}} to <4 x i16>
; VIRT-DAG: bitcast <4 x i16> {{.*}} to <4 x bfloat>
; VIRT: define i64 @protected_bitcast_i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: bitcast <4 x bfloat> {{.*}} to i64
; VIRT-DAG: bitcast i64 {{.*}} to <4 x bfloat>
; VIRT: define <4 x float> @protected_fpext_v4({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: fpext{{.*}}bfloat
; VIRT: zext <4 x i16>
; VIRT: define <4 x bfloat> @protected_fptrunc_v4({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: fptrunc{{.*}}bfloat
; VIRT: icmp eq i32 {{.*}}, 2139095040
; VIRT: or i32 {{.*}}, 64
; VIRT: define <4 x bfloat> @protected_fpext_fptrunc_v4({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: fpext{{.*}}bfloat
; VIRT-NOT: fptrunc{{.*}}bfloat
; VIRT: fadd{{.*}} float
; VIRT: define <2 x float> @protected_fpext_v2({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: fpext{{.*}}bfloat
; VIRT: zext <2 x i16>
; VIRT: define <4 x bfloat> @protected_sitofp_v4i1({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: sitofp{{.*}}bfloat
; VIRT: sitofp i1 {{.*}} to float
; VIRT: define <4 x bfloat> @protected_uitofp_v4i1({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: uitofp{{.*}}bfloat
; VIRT: uitofp i1 {{.*}} to float
; VIRT: define <4 x i1> @protected_fptosi_v4i1({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: fptosi{{.*}}bfloat
; VIRT: fptosi float {{.*}} to i1
; VIRT: define <4 x i1> @protected_fptoui_v4i1({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: fptoui{{.*}}bfloat
; VIRT: fptoui float {{.*}} to i1
; VIRT: define <4 x bfloat> @protected_sitofp_v4i8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: sitofp{{.*}}bfloat
; VIRT: sitofp i8 {{.*}} to float
; VIRT: define <4 x bfloat> @protected_uitofp_v4i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: uitofp{{.*}}bfloat
; VIRT: uitofp i16 {{.*}} to float
; VIRT: define <4 x bfloat> @protected_sitofp_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: sitofp{{.*}}bfloat
; VIRT: sitofp i32 {{.*}} to float
; VIRT: icmp eq i32 {{.*}}, 2139095040
; VIRT: define <4 x bfloat> @protected_uitofp_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: uitofp{{.*}}bfloat
; VIRT: uitofp i32 {{.*}} to float
; VIRT: define <4 x i32> @protected_fptosi_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: fptosi{{.*}}bfloat
; VIRT: fptosi float {{.*}} to i32
; VIRT: define <4 x i32> @protected_fptoui_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: fptoui{{.*}}bfloat
; VIRT: fptoui float {{.*}} to i32
; VIRT: define <2 x bfloat> @protected_sitofp_v2i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: sitofp{{.*}}bfloat
; VIRT: sitofp i64 {{.*}} to float
; VIRT: define <2 x i64> @protected_fptosi_v2i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: fptosi{{.*}}bfloat
; VIRT: fptosi float {{.*}} to i64
; VIRT: define <4 x i32> @protected_intcast_arith_v4({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: sitofp{{.*}}bfloat
; VIRT-NOT: fadd{{.*}}bfloat
; VIRT-NOT: fptosi{{.*}}bfloat
; VIRT: fadd{{.*}} float
; VIRT: define {{.*}} @unsupported_bf16_vec_no_feature({{.*}} #[[UNSUPFEAT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_bf16_vec_disabled({{.*}} #[[UNSUPDIS:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_bf16_vec_fmf({{.*}} #[[UNSUPFMF:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: fadd nnan <4 x bfloat>
; VIRT: define {{.*}} @unsupported_bf16_vec_atomic({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_bf16_vec_math({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_bf16_vec_call({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_bf16_vec_wide({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_bf16_vec_scalable({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_bf16_vec_shuffle_no_feature({{.*}} #[[UNSUPFEAT]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_bf16_vec_bitcast_no_feature({{.*}} #[[UNSUPFEAT]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_bf16_vec_float_bitcast({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: bitcast <4 x bfloat> {{.*}} to <2 x float>
; VIRT: define {{.*}} @unsupported_bf16_vec_fptrunc_no_feature({{.*}} #[[UNSUPFEAT]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_bf16_vec_fptrunc_disabled({{.*}} #[[UNSUPDIS]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_bf16_vec_half_cast({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: bitcast <4 x bfloat> {{.*}} to <4 x half>
; VIRT: define {{.*}} @unsupported_bf16_vec_fpext_double({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: fpext <2 x bfloat>
; VIRT: define {{.*}} @unsupported_bf16_vec_sitofp_no_feature({{.*}} #[[UNSUPFEAT]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_bf16_vec_sitofp_disabled({{.*}} #[[UNSUPDIS]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_bf16_vec_fptosi_i128({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: fptosi <1 x bfloat>
; VIRT: define {{.*}} @unsupported_bf16_vec_fptosi_wide({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: fptosi <8 x bfloat>
; VIRT: define {{.*}} @unsupported_bf16_vec_fpext_wide({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: fpext <8 x bfloat>
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[PROTNEON]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[PROTLAST]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPFEAT]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT: attributes #[[UNSUPDIS]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT: attributes #[[UNSUPFMF]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPFEAT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPDIS]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPFMF]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
