; Restricted scalar bfloat basic SSA and non-atomic AS0 memory on the
; existing 16-bit float VReg frame.  Requires last-token function
; "target-features" +bf16 (exact token; +bf16fml / +fullfp16 do not
; count; command-line -mattr is never read).  Well-shaped scalar bfloat
; SSA / memory missing or ending in -bf16 skips as unsupported target
; feature and keeps hikari.vmp.selected.
;
; Covers fadd/fsub/fmul/fdiv/frem/fneg, fcmp, select, phi, freeze,
; non-atomic AS0 load/store, bfloat<->i16 bitcast, scalar bfloat<->float
; fpext/fptrunc, scalar bfloat<->i1/i8/i16/i32/i64 sitofp/uitofp/
; fptosi/fptoui, constants, and the virtualized function's own scalar
; bfloat args/returns.  Listed llvm.fabs / llvm.sqrt / llvm.fma are
; the independent +bf16 math surface (see vmp-bfloat-math-semantic.ll).
; No new VM opcode: 16-bit float-frame ops set Variant bit 7 (fcmp
; bit 11; fpext/fptrunc bit 15).
;
; Not opened: unlisted math (constrained/minnum/transcendentals),
; constrained/sat conversions, bfloat vectors except the independent
; vector surface,
; aggregates, indirect / general call ABI, atomics, bfloat<->double/
; half width casts, i128, SVE.  Scalar bfloat SSA or direct calls with
; any FastMathFlags are rejected.  Ordinary direct C calls (including
; ordinary tail, replayed as a non-tail CallInst) may carry scalar
; bfloat args/returns (CallDescriptor, float VReg) when the caller
; has last-token +bf16.  musttail / named-bfloat C vararg calls stay
; rejected.
;
; Host x86 cannot be assumed to select scalar bfloat.  LLVM 15 AArch64
; ISel also cannot select native bf16 arithmetic / fcmp / fpext /
; fptrunc / select; the interpreter legalizes those through i16 bits
; and f32, which llc can select.  This lit is FileCheck + AArch64
; llc/readobj only (function +bf16, no global -mattr).  Do not invent
; a host lli semantic oracle.  Native reference functions with
; `fadd bfloat` are omitted because llc cannot select them.
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
declare bfloat @llvm.fabs.bf16(bfloat)
declare bfloat @llvm.fmuladd.bf16(bfloat, bfloat, bfloat)
declare bfloat @llvm.experimental.constrained.fadd.bf16(bfloat, bfloat, metadata, metadata)
declare bfloat @ext_bf16(bfloat)
declare void @ext_bf16_sink(bfloat)
declare bfloat @ext_bf16_src()
declare bfloat @ext_bf16_vararg(bfloat, ...)

@g.bf16 = private global bfloat 0xR0000, align 2

; ----- positives (last-token +bf16) -----

define bfloat @protected_add(bfloat %a, bfloat %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %s = fadd bfloat %a, %b
  ret bfloat %s
}

define bfloat @protected_ret(bfloat %a) noinline optnone "target-features"="+neon,+bf16" {
entry:
  call void @hikari_vmp()
  ret bfloat %a
}

define i32 @protected_work(bfloat %a, bfloat %b, i1 %c, i16 %raw) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %stk = alloca bfloat, align 2
  %sum = fadd bfloat %a, %b
  %dif = fsub bfloat %sum, %a
  %prod = fmul bfloat %dif, %b
  %quot = fdiv bfloat %prod, %a
  %rem = frem bfloat %quot, %b
  %neg = fneg bfloat %rem
  %ogt = fcmp ogt bfloat %neg, %a
  %sel = select i1 %ogt, bfloat %neg, bfloat %a
  %fr = freeze bfloat %sel
  br i1 %c, label %left, label %right

left:
  %lp = fadd bfloat %fr, %a
  br label %join

right:
  %rp = fadd bfloat %fr, %b
  br label %join

join:
  %phi = phi bfloat [ %lp, %left ], [ %rp, %right ]
  store bfloat %phi, ptr %stk, align 2
  %ld = load bfloat, ptr %stk, align 2
  store bfloat %ld, ptr @g.bf16, align 2
  %gld = load bfloat, ptr @g.bf16, align 2
  %fromi = bitcast i16 %raw to bfloat
  %mix = fadd bfloat %gld, %fromi
  %bits = bitcast bfloat %mix to i16
  %z = zext i16 %bits to i32
  ret i32 %z
}

define i32 @protected_loop(bfloat %a, i32 %n) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  br label %loop

loop:
  %acc = phi bfloat [ %a, %entry ], [ %next, %loop ]
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %next = fadd bfloat %acc, %a
  %i1 = add i32 %i, 1
  %c = icmp slt i32 %i1, %n
  br i1 %c, label %loop, label %done

done:
  %bits = bitcast bfloat %next to i16
  %z = zext i16 %bits to i32
  ret i32 %z
}

; Last token wins: +bf16 after an earlier disable.
define bfloat @protected_last_token(bfloat %a, bfloat %b) noinline optnone "target-features"="-bf16,+neon,+bf16" {
entry:
  call void @hikari_vmp()
  %s = fadd bfloat %a, %b
  ret bfloat %s
}

define float @protected_fpext(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %e = fpext bfloat %a to float
  ret float %e
}

define bfloat @protected_fptrunc(float %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %t = fptrunc float %a to bfloat
  ret bfloat %t
}

; Cross: bfloat<->float convert with ordinary f32 SSA.
define bfloat @protected_convert_roundtrip(bfloat %a, float %x) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %e = fpext bfloat %a to float
  %s = fadd float %e, %x
  %t = fptrunc float %s to bfloat
  ret bfloat %t
}

; Cross: new bfloat<->float with the existing half<->float width surface.
define half @protected_bf16_to_half(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %f = fpext bfloat %a to float
  %h = fptrunc float %f to half
  ret half %h
}

define bfloat @protected_half_to_bf16(half %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %f = fpext half %a to float
  %b = fptrunc float %f to bfloat
  ret bfloat %b
}

define bfloat @protected_sitofp_i32(i32 %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = sitofp i32 %a to bfloat
  ret bfloat %r
}

define bfloat @protected_uitofp_i32(i32 %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = uitofp i32 %a to bfloat
  ret bfloat %r
}

define i32 @protected_fptosi_i32(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = fptosi bfloat %a to i32
  ret i32 %r
}

define i32 @protected_fptoui_i32(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = fptoui bfloat %a to i32
  ret i32 %r
}

define i64 @protected_intcast_mix(i16 %s, i64 %u, bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %bf = sitofp i16 %s to bfloat
  %ext = fpext bfloat %bf to float
  %add = fadd float %ext, 1.0
  %back = fptrunc float %add to bfloat
  %si = fptosi bfloat %back to i32
  %uf = uitofp i64 %u to bfloat
  %ui = fptoui bfloat %uf to i32
  %z = zext i32 %si to i64
  %t = zext i32 %ui to i64
  %or = or i64 %z, %t
  ret i64 %or
}

define i32 @protected_intcast_i1_i8(i1 %b, i8 %c, bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %s1 = sitofp i1 %b to bfloat
  %u8 = uitofp i8 %c to bfloat
  %si8 = fptosi bfloat %a to i8
  %ui8 = fptoui bfloat %a to i8
  %z1 = fptosi bfloat %s1 to i32
  %z8 = sext i8 %si8 to i32
  %t = zext i8 %ui8 to i32
  %or = or i32 %z1, %z8
  %r = or i32 %or, %t
  ret i32 %r
}

define bfloat @protected_call(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @ext_bf16(bfloat %a)
  ret bfloat %r
}

define void @protected_call_sink(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  call void @ext_bf16_sink(bfloat %a)
  ret void
}

define bfloat @protected_call_src() noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @ext_bf16_src()
  ret bfloat %r
}

define float @protected_call_then_fpext(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @ext_bf16(bfloat %a)
  %e = fpext bfloat %r to float
  ret float %e
}



; ----- negatives -----

; Well-shaped scalar bfloat SSA, no target-features: feature skip.
; i16 args keep the fadd live under O2 (constant bfloat fadd folds).
define i32 @unsupported_bf16_no_feature(i16 %a, i16 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %x = bitcast i16 %a to bfloat
  %y = bitcast i16 %b to bfloat
  %s = fadd bfloat %x, %y
  %bits = bitcast bfloat %s to i16
  %z = zext i16 %bits to i32
  ret i32 %z
}

; Last token -bf16: feature skip.
define i32 @unsupported_bf16_disabled(i16 %a, i16 %b) noinline optnone "target-features"="+neon,+bf16,-bf16" {
entry:
  call void @hikari_vmp()
  %x = bitcast i16 %a to bfloat
  %y = bitcast i16 %b to bfloat
  %s = fadd bfloat %x, %y
  %bits = bitcast bfloat %s to i16
  %z = zext i16 %bits to i32
  ret i32 %z
}

; Related token is not +bf16.
define i32 @unsupported_bf16fml_only(i16 %a, i16 %b) noinline optnone "target-features"="+bf16fml" {
entry:
  call void @hikari_vmp()
  %x = bitcast i16 %a to bfloat
  %y = bitcast i16 %b to bfloat
  %s = fadd bfloat %x, %y
  %bits = bitcast bfloat %s to i16
  %z = zext i16 %bits to i32
  ret i32 %z
}

; +fullfp16 does not enable bfloat.
define i32 @unsupported_fullfp16_not_bf16(i16 %a, i16 %b) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %x = bitcast i16 %a to bfloat
  %y = bitcast i16 %b to bfloat
  %s = fadd bfloat %x, %y
  %bits = bitcast bfloat %s to i16
  %z = zext i16 %bits to i32
  ret i32 %z
}

; 1..128 bfloat vectors are the independent +bf16 vector surface.
; Keep this sentinel as an oversized vector so the skip reason stays
; "unsupported return type".
define <16 x bfloat> @unsupported_bfloat_vector() noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  ret <16 x bfloat> zeroinitializer
}

; fabs/sqrt/fma/fmuladd are the listed +bf16 math surface.
; constrained stays closed.
define bfloat @unsupported_bfloat_math(bfloat %a, bfloat %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.experimental.constrained.fadd.bf16(bfloat %a, bfloat %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret bfloat %r
}

define bfloat @unsupported_bfloat_constrained(bfloat %a, bfloat %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.experimental.constrained.fadd.bf16(bfloat %a, bfloat %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret bfloat %r
}

define i32 @unsupported_bfloat_atomic(ptr %p) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %v = load atomic bfloat, ptr %p seq_cst, align 2
  %b = bitcast bfloat %v to i16
  %z = zext i16 %b to i32
  ret i32 %z
}

define float @unsupported_fpext_no_feature(i16 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %b = bitcast i16 %a to bfloat
  %e = fpext bfloat %b to float
  ret float %e
}

; Width-cast only, last token -bf16: no bfloat ABI, so the skip is the
; convert feature gate (not unsupported argument/return type).
define float @unsupported_fptrunc_disabled(float %a) noinline optnone "target-features"="+neon,+bf16,-bf16" {
entry:
  call void @hikari_vmp()
  %t = fptrunc float %a to bfloat
  %e = fpext bfloat %t to float
  ret float %e
}

define i32 @unsupported_sitofp_no_feature(i32 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %b = sitofp i32 %a to bfloat
  %i = bitcast bfloat %b to i16
  %z = zext i16 %i to i32
  ret i32 %z
}

define i32 @unsupported_fptosi_no_feature(i16 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %b = bitcast i16 %a to bfloat
  %r = fptosi bfloat %b to i32
  ret i32 %r
}

define i32 @unsupported_sitofp_disabled(i32 %a) noinline optnone "target-features"="+neon,+bf16,-bf16" {
entry:
  call void @hikari_vmp()
  %b = sitofp i32 %a to bfloat
  %i = bitcast bfloat %b to i16
  %z = zext i16 %i to i32
  ret i32 %z
}

define bfloat @unsupported_sitofp_i128(i128 %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = sitofp i128 %a to bfloat
  ret bfloat %r
}

; Same-lane i1..i64 vector sitofp is the independent +bf16 vector
; surface.  i128 elements stay closed.
define <2 x bfloat> @unsupported_sitofp_vector(<2 x i128> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = sitofp <2 x i128> %a to <2 x bfloat>
  ret <2 x bfloat> %r
}

define double @unsupported_bfloat_fpext_double(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %e = fpext bfloat %a to double
  ret double %e
}

define bfloat @unsupported_bfloat_fptrunc_double(double %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %t = fptrunc double %a to bfloat
  ret bfloat %t
}

define { bfloat, bfloat } @unsupported_bfloat_aggregate(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %s = insertvalue { bfloat, bfloat } poison, bfloat %a, 0
  %t = insertvalue { bfloat, bfloat } %s, bfloat %a, 1
  ret { bfloat, bfloat } %t
}

define bfloat @unsupported_bfloat_fmf_fadd(bfloat %a, bfloat %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %s = fadd nnan bfloat %a, %b
  ret bfloat %s
}

define bfloat @unsupported_bfloat_fmf_fneg(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %n = fneg nnan bfloat %a
  ret bfloat %n
}

define i1 @unsupported_bfloat_fmf_fcmp(bfloat %a, bfloat %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %c = fcmp nnan ogt bfloat %a, %b
  ret i1 %c
}

define bfloat @unsupported_bfloat_fmf_select(i1 %c, bfloat %a, bfloat %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %s = select nnan i1 %c, bfloat %a, bfloat %b
  ret bfloat %s
}

define bfloat @unsupported_bfloat_fmf_phi(i1 %c, bfloat %a, bfloat %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  br i1 %c, label %left, label %right

left:
  br label %join

right:
  br label %join

join:
  %p = phi nnan bfloat [ %a, %left ], [ %b, %right ]
  ret bfloat %p
}

define i32 @unsupported_call_no_feature() noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call bfloat @ext_bf16(bfloat 0xR3F80)
  %i = bitcast bfloat %r to i16
  %z = zext i16 %i to i32
  ret i32 %z
}

define i32 @unsupported_call_disabled() noinline optnone "target-features"="+neon,+bf16,-bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @ext_bf16(bfloat 0xR3F80)
  %i = bitcast bfloat %r to i16
  %z = zext i16 %i to i32
  ret i32 %z
}

define bfloat @unsupported_call_fmf(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call nnan bfloat @ext_bf16(bfloat %a)
  ret bfloat %r
}

define bfloat @unsupported_call_fastcc(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call fastcc bfloat @ext_bf16(bfloat %a)
  ret bfloat %r
}

define bfloat @unsupported_call_musttail(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = musttail call bfloat @ext_bf16(bfloat %a)
  ret bfloat %r
}

define bfloat @unsupported_call_vararg(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat (bfloat, ...) @ext_bf16_vararg(bfloat %a)
  ret bfloat %r
}

; Ordinary C indirect is the independent +bf16 surface
; (vmp-bfloat-indirect-call-semantic.ll).  fastcc keeps this
; sentinel closed; ordinary tail is now a positive on that surface.
define bfloat @unsupported_bfloat_indirect(ptr %fp, bfloat %x) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call fastcc bfloat %fp(bfloat %x)
  ret bfloat %r
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_bf16_no_feature: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_bf16_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_bf16fml_only: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_fullfp16_not_bf16: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_bfloat_vector: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_bfloat_math: unsupported call
; SKIP-DAG: Skipping VMP on unsupported_bfloat_constrained: unsupported call
; SKIP-DAG: Skipping VMP on unsupported_bfloat_atomic: unsupported float load instruction
; SKIP-DAG: Skipping VMP on unsupported_fpext_no_feature: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_fptrunc_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_sitofp_no_feature: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_fptosi_no_feature: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_sitofp_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_sitofp_i128: unsupported
; SKIP-DAG: Skipping VMP on unsupported_sitofp_vector: unsupported
; SKIP-DAG: Skipping VMP on unsupported_bfloat_fpext_double: unsupported cast instruction
; SKIP-DAG: Skipping VMP on unsupported_bfloat_fptrunc_double: unsupported cast instruction
; SKIP-DAG: Skipping VMP on unsupported_bfloat_aggregate: unsupported
; SKIP-DAG: Skipping VMP on unsupported_bfloat_fmf_fadd: unsupported float fadd instruction
; SKIP-DAG: Skipping VMP on unsupported_bfloat_fmf_fneg: unsupported float fneg instruction
; SKIP-DAG: Skipping VMP on unsupported_bfloat_fmf_fcmp: unsupported float comparison
; SKIP-DAG: Skipping VMP on unsupported_bfloat_fmf_select: unsupported float select instruction
; SKIP-DAG: Skipping VMP on unsupported_bfloat_fmf_phi: unsupported float phi instruction
; SKIP-DAG: Skipping VMP on unsupported_call_no_feature: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_call_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_call_fmf: unsupported float call instruction
; SKIP-DAG: Skipping VMP on unsupported_call_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_call_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_call_vararg: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_bfloat_indirect: indirect call
; SKIP-NOT: Skipping VMP on protected_add:
; SKIP-NOT: Skipping VMP on protected_ret:
; SKIP-NOT: Skipping VMP on protected_work:
; SKIP-NOT: Skipping VMP on protected_loop:
; SKIP-NOT: Skipping VMP on protected_last_token:
; SKIP-NOT: Skipping VMP on protected_fpext:
; SKIP-NOT: Skipping VMP on protected_fptrunc:
; SKIP-NOT: Skipping VMP on protected_convert_roundtrip:
; SKIP-NOT: Skipping VMP on protected_bf16_to_half:
; SKIP-NOT: Skipping VMP on protected_half_to_bf16:
; SKIP-NOT: Skipping VMP on protected_sitofp_i32:
; SKIP-NOT: Skipping VMP on protected_uitofp_i32:
; SKIP-NOT: Skipping VMP on protected_fptosi_i32:
; SKIP-NOT: Skipping VMP on protected_fptoui_i32:
; SKIP-NOT: Skipping VMP on protected_intcast_mix:
; SKIP-NOT: Skipping VMP on protected_intcast_i1_i8:
; SKIP-NOT: Skipping VMP on protected_call:
; SKIP-NOT: Skipping VMP on protected_call_sink:
; SKIP-NOT: Skipping VMP on protected_call_src:
; SKIP-NOT: Skipping VMP on protected_call_then_fpext:

; VIRT: define bfloat @protected_add({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; Legalized bf16 add is f32 with no FastMathFlags.
; VIRT-NOT: nnan
; VIRT: fadd{{.*}} float
; Inf/NaN must not take the RNE bias-add: 0x7F800000 compare and
; qNaN quiet bit 0x0040 (APFloat sNaN must not become Inf).
; VIRT: icmp eq i32 {{.*}}, 2139095040
; VIRT: or i32 {{.*}}, 64
; VIRT: define bfloat @protected_ret({{.*}} #[[PROTNEON:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: define i32 @protected_work({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: fadd{{.*}} float
; VIRT-DAG: fsub{{.*}} float
; VIRT-DAG: fmul{{.*}} float
; VIRT-DAG: fdiv{{.*}} float
; VIRT-DAG: frem{{.*}} float
; VIRT-DAG: fcmp{{.*}} float
; VIRT-DAG: bitcast bfloat
; VIRT-DAG: bitcast i16
; VIRT-DAG: load bfloat
; VIRT-DAG: store bfloat
; VIRT: define i32 @protected_loop({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: fadd{{.*}} float
; VIRT: define bfloat @protected_last_token({{.*}} #[[PROTLAST:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: fadd{{.*}} float
; VIRT: define float @protected_fpext({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: fpext bfloat
; VIRT: shl{{.*}} i32
; VIRT: define bfloat @protected_fptrunc({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: fptrunc
; VIRT: icmp eq i32 {{.*}}, 2139095040
; VIRT: or i32 {{.*}}, 64
; VIRT: define bfloat @protected_convert_roundtrip({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: fpext bfloat
; VIRT-NOT: fptrunc {{.*}} bfloat
; VIRT-DAG: shl{{.*}} i32
; VIRT-DAG: fadd{{.*}} float
; VIRT-DAG: icmp eq i32 {{.*}}, 2139095040
; VIRT: define half @protected_bf16_to_half({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: fpext bfloat
; VIRT-DAG: shl{{.*}} i32
; VIRT-DAG: fptrunc{{.*}} half
; VIRT: define bfloat @protected_half_to_bf16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: fptrunc {{.*}} bfloat
; VIRT-DAG: fpext{{.*}} float
; VIRT-DAG: icmp eq i32 {{.*}}, 2139095040
; VIRT: define bfloat @protected_sitofp_i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: sitofp {{.*}} bfloat
; VIRT: sitofp{{.*}} float
; VIRT: icmp eq i32 {{.*}}, 2139095040
; VIRT: define bfloat @protected_uitofp_i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: uitofp {{.*}} bfloat
; VIRT: uitofp{{.*}} float
; VIRT: define i32 @protected_fptosi_i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: fptosi bfloat
; VIRT-DAG: shl{{.*}} i32
; VIRT-DAG: fptosi{{.*}} i32
; VIRT: define i32 @protected_fptoui_i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: fptoui bfloat
; VIRT-DAG: shl{{.*}} i32
; VIRT-DAG: fptoui{{.*}} i32
; VIRT: define i64 @protected_intcast_mix({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: sitofp {{.*}} bfloat
; VIRT-NOT: fpext bfloat
; VIRT-DAG: sitofp{{.*}} float
; VIRT-DAG: uitofp{{.*}} float
; VIRT-DAG: fptosi{{.*}} i32
; VIRT-DAG: fptoui{{.*}} i32
; VIRT: define i32 @protected_intcast_i1_i8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: sitofp {{.*}} bfloat
; VIRT-NOT: uitofp {{.*}} bfloat
; VIRT-NOT: fptosi bfloat
; VIRT-NOT: fptoui bfloat
; VIRT-DAG: sitofp{{.*}} float
; VIRT-DAG: uitofp{{.*}} float
; VIRT-DAG: fptosi{{.*}} i8
; VIRT-DAG: fptoui{{.*}} i8
; VIRT-DAG: fptosi{{.*}} i32
; VIRT: define bfloat @protected_call({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: nnan
; VIRT: call{{.*}}bfloat @ext_bf16(
; VIRT: define void @protected_call_sink({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; Void sink is not an FPMathOperator: do not query FMF / invent nnan.
; VIRT-NOT: nnan
; VIRT: call{{.*}}void @ext_bf16_sink(
; VIRT: define bfloat @protected_call_src({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call{{.*}}bfloat @ext_bf16_src(
; VIRT: define float @protected_call_then_fpext({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: fpext bfloat
; VIRT-DAG: call{{.*}}bfloat @ext_bf16(
; VIRT-DAG: shl{{.*}} i32
; VIRT: define {{.*}} @unsupported_bf16_no_feature({{.*}} #[[UNSUPFEAT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_bf16_disabled({{.*}} #[[UNSUPDIS:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_bf16fml_only({{.*}} #[[UNSUPFML:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fullfp16_not_bf16({{.*}} #[[UNSUPFP16:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_bfloat_vector({{.*}} #[[UNSUPATTR:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_bfloat_math({{.*}} #[[UNSUPMATH:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_bfloat_constrained({{.*}} #[[UNSUPCON:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_bfloat_atomic({{.*}} #[[UNSUPLOAD:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fpext_no_feature({{.*}} #[[UNSUPFEAT]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fptrunc_disabled({{.*}} #[[UNSUPDIS]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_sitofp_no_feature({{.*}} #[[UNSUPFEAT]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fptosi_no_feature({{.*}} #[[UNSUPFEAT]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_sitofp_disabled({{.*}} #[[UNSUPDIS]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_sitofp_i128({{.*}} #[[UNSUPI128:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_sitofp_vector({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_bfloat_fpext_double({{.*}} #[[UNSUPCAST:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_bfloat_fptrunc_double({{.*}} #[[UNSUPCAST]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_bfloat_aggregate({{.*}} #[[UNSUPAGG:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_bfloat_fmf_fadd({{.*}} #[[UNSUPFMF:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: fadd nnan bfloat
; VIRT: define {{.*}} @unsupported_bfloat_fmf_fneg({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: fneg nnan bfloat
; VIRT: define {{.*}} @unsupported_bfloat_fmf_fcmp({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: fcmp nnan ogt bfloat
; VIRT: define {{.*}} @unsupported_bfloat_fmf_select({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: select nnan i1
; VIRT: define {{.*}} @unsupported_bfloat_fmf_phi({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: phi nnan bfloat
; VIRT: define {{.*}} @unsupported_call_no_feature({{.*}} #[[UNSUPFEAT]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_call_disabled({{.*}} #[[UNSUPDIS]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_call_fmf({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call nnan bfloat @ext_bf16(
; VIRT: define {{.*}} @unsupported_call_fastcc({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_call_musttail({{.*}} #[[UNSUPMUST:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_call_vararg({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_bfloat_indirect({{.*}} #[[UNSUPIND:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[PROTNEON]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[PROTLAST]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT-DAG: attributes #[[UNSUPFMF]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-DAG: attributes #[[UNSUPFEAT]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-DAG: attributes #[[UNSUPDIS]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; Direct musttail is an early deselect (dedicated "musttail call");
; +bf16 is kept, no selected/virtualized, no dispatcher.
; VIRT: attributes #[[UNSUPMUST]] = { noinline optnone "target-features"="+bf16" }
; VIRT-NOT: attributes #[[UNSUPFEAT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPDIS]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPFMF]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPMUST]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPMUST]] = { {{.*}}"hikari.vmp.selected"

; AARCH64: Arch: aarch64
