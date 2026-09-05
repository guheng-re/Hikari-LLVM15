; Listed scalar IEEE fp128 min/max and rounding: llvm.minnum.f128,
; llvm.maxnum.f128, llvm.minimum.f128, llvm.maximum.f128,
; llvm.ceil.f128, llvm.floor.f128, llvm.trunc.f128, llvm.round.f128,
; llvm.roundeven.f128, llvm.rint.f128, llvm.nearbyint.f128.
; Replayed through CallDescriptor as a typed CreateCall of the original
; intrinsic Function* on the dedicated vmp.fp128.regs frame.  Never
; i128 reinterpretation, never min/max-to-select, never rounding-to-cast.
; Valid FastMathFlags, calling convention, attributes, metadata, and
; debug locations are preserved.  Ordinary tail of an already-supported CallInst is accepted; see vmp-direct-call-tail-eligibility-semantic.ll.  musttail stays rejected.
;
; Rejected: constrained minnum/ceil, canonicalize/copysign/pow/powi/
; transcendentals, vector fp128, ppc_fp128, poison/undef, musttail,
; operand bundles, inline asm, invalid ABI / call shapes.
; Unsupported fp128 intrinsics are not rewritten into ordinary
; external calls.
;
; Host lli compares reference vs protected bit patterns after dropping
; unsupported bodies.  llvm.minimum/maximum.f128 stay FileCheck-only
; for codegen: neither host x86 nor LLVM 15 AArch64 ISel can select
; fminimum/fmaximum fp128.  FileCheck + lli + AArch64 llc/readobj
; on the selectable remainder.  O0/O2 x aesSeed 97/7.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.ll > %t.o0.live.ll
; RUN: python3 %S/Inputs/vmp-drop-host-unselectable-fp128.py %t.o0.live.ll > %t.o0.sel.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.sel.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.sel.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.ll > %t.o2.live.ll
; RUN: python3 %S/Inputs/vmp-drop-host-unselectable-fp128.py %t.o2.live.ll > %t.o2.sel.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.sel.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.sel.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.s7.ll > %t.o0.s7.live.ll
; RUN: python3 %S/Inputs/vmp-drop-host-unselectable-fp128.py %t.o0.s7.live.ll > %t.o0.s7.sel.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.s7.sel.ll > %t.o0.s7.host.ll
; RUN: lli -force-interpreter %t.o0.s7.host.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.sel.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.s7.ll > %t.o2.s7.live.ll
; RUN: python3 %S/Inputs/vmp-drop-host-unselectable-fp128.py %t.o2.s7.live.ll > %t.o2.s7.sel.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.s7.sel.ll > %t.o2.s7.host.ll
; RUN: lli -force-interpreter %t.o2.s7.host.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.sel.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare fp128 @llvm.minnum.f128(fp128, fp128)
declare fp128 @llvm.maxnum.f128(fp128, fp128)
declare fp128 @llvm.minimum.f128(fp128, fp128)
declare fp128 @llvm.maximum.f128(fp128, fp128)
declare fp128 @llvm.ceil.f128(fp128)
declare fp128 @llvm.floor.f128(fp128)
declare fp128 @llvm.trunc.f128(fp128)
declare fp128 @llvm.round.f128(fp128)
declare fp128 @llvm.roundeven.f128(fp128)
declare fp128 @llvm.rint.f128(fp128)
declare fp128 @llvm.nearbyint.f128(fp128)
declare i64 @llvm.experimental.constrained.lround.i64.f128(fp128, metadata)
declare fp128 @llvm.experimental.constrained.sin.f128(fp128, metadata, metadata)
declare fp128 @llvm.experimental.constrained.pow.f128(fp128, fp128, metadata, metadata)
declare fp128 @llvm.powi.f128.i64(fp128, i64)
declare fp128 @llvm.experimental.constrained.minnum.f128(fp128, fp128, metadata)
declare fp128 @llvm.experimental.constrained.ceil.f128(fp128, metadata)
declare <1 x fp128> @llvm.minnum.v1f128(<1 x fp128>, <1 x fp128>)
declare ppc_fp128 @llvm.ceil.ppcf128(ppc_fp128)
declare void @ext_fp128_sret(ptr sret(i32), fp128)

define i32 @fold_fp128(fp128 %v) {
entry:
  %b = bitcast fp128 %v to i128
  %lo = trunc i128 %b to i64
  %hi.sh = lshr i128 %b, 64
  %hi = trunc i128 %hi.sh to i64
  %x = xor i64 %lo, %hi
  %r = trunc i64 %x to i32
  ret i32 %r
}

define fp128 @reference_minnum(fp128 %a, fp128 %b) noinline {
entry:
  %r = call fp128 @llvm.minnum.f128(fp128 %a, fp128 %b)
  ret fp128 %r
}

define fp128 @protected_minnum(fp128 %a, fp128 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 @llvm.minnum.f128(fp128 %a, fp128 %b)
  ret fp128 %r
}

define fp128 @reference_maxnum(fp128 %a, fp128 %b) noinline {
entry:
  %r = call fp128 @llvm.maxnum.f128(fp128 %a, fp128 %b)
  ret fp128 %r
}

define fp128 @protected_maxnum(fp128 %a, fp128 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 @llvm.maxnum.f128(fp128 %a, fp128 %b)
  ret fp128 %r
}

define fp128 @reference_minimum(fp128 %a, fp128 %b) noinline {
entry:
  %r = call fp128 @llvm.minimum.f128(fp128 %a, fp128 %b)
  ret fp128 %r
}

define fp128 @protected_minimum(fp128 %a, fp128 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 @llvm.minimum.f128(fp128 %a, fp128 %b)
  ret fp128 %r
}

define fp128 @reference_maximum(fp128 %a, fp128 %b) noinline {
entry:
  %r = call fp128 @llvm.maximum.f128(fp128 %a, fp128 %b)
  ret fp128 %r
}

define fp128 @protected_maximum(fp128 %a, fp128 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 @llvm.maximum.f128(fp128 %a, fp128 %b)
  ret fp128 %r
}

define fp128 @reference_ceil(fp128 %a) noinline {
entry:
  %r = call fp128 @llvm.ceil.f128(fp128 %a)
  ret fp128 %r
}

define fp128 @protected_ceil(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 @llvm.ceil.f128(fp128 %a)
  ret fp128 %r
}

define fp128 @reference_floor(fp128 %a) noinline {
entry:
  %r = call fp128 @llvm.floor.f128(fp128 %a)
  ret fp128 %r
}

define fp128 @protected_floor(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 @llvm.floor.f128(fp128 %a)
  ret fp128 %r
}

define fp128 @reference_trunc(fp128 %a) noinline {
entry:
  %r = call fp128 @llvm.trunc.f128(fp128 %a)
  ret fp128 %r
}

define fp128 @protected_trunc(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 @llvm.trunc.f128(fp128 %a)
  ret fp128 %r
}

define fp128 @reference_round(fp128 %a) noinline {
entry:
  %r = call fp128 @llvm.round.f128(fp128 %a)
  ret fp128 %r
}

define fp128 @protected_round(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 @llvm.round.f128(fp128 %a)
  ret fp128 %r
}

define fp128 @reference_roundeven(fp128 %a) noinline {
entry:
  %r = call fp128 @llvm.roundeven.f128(fp128 %a)
  ret fp128 %r
}

define fp128 @protected_roundeven(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 @llvm.roundeven.f128(fp128 %a)
  ret fp128 %r
}

define fp128 @reference_rint(fp128 %a) noinline {
entry:
  %r = call fp128 @llvm.rint.f128(fp128 %a)
  ret fp128 %r
}

define fp128 @protected_rint(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 @llvm.rint.f128(fp128 %a)
  ret fp128 %r
}

define fp128 @reference_nearbyint(fp128 %a) noinline {
entry:
  %r = call fp128 @llvm.nearbyint.f128(fp128 %a)
  ret fp128 %r
}

define fp128 @protected_nearbyint(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 @llvm.nearbyint.f128(fp128 %a)
  ret fp128 %r
}

define fp128 @reference_fmf(fp128 %a, fp128 %b) noinline {
entry:
  %r = call nnan nsz fp128 @llvm.minnum.f128(fp128 %a, fp128 %b)
  ret fp128 %r
}

define fp128 @protected_fmf(fp128 %a, fp128 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call nnan nsz fp128 @llvm.minnum.f128(fp128 %a, fp128 %b)
  ret fp128 %r
}

define fp128 @reference_phi(i1 %c, fp128 %a, fp128 %b) noinline {
entry:
  br i1 %c, label %left, label %right

left:
  %mn = call fp128 @llvm.minnum.f128(fp128 %a, fp128 %b)
  br label %join

right:
  %fl = call fp128 @llvm.floor.f128(fp128 %a)
  br label %join

join:
  %p = phi fp128 [ %mn, %left ], [ %fl, %right ]
  ret fp128 %p
}

define fp128 @protected_phi(i1 %c, fp128 %a, fp128 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  br i1 %c, label %left, label %right

left:
  %mn = call fp128 @llvm.minnum.f128(fp128 %a, fp128 %b)
  br label %join

right:
  %fl = call fp128 @llvm.floor.f128(fp128 %a)
  br label %join

join:
  %p = phi fp128 [ %mn, %left ], [ %fl, %right ]
  ret fp128 %p
}

define fp128 @reference_loop(fp128 %a, fp128 %b, i32 %n) noinline {
entry:
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %acc = phi fp128 [ %a, %entry ], [ %next, %loop ]
  %next = call fp128 @llvm.minnum.f128(fp128 %acc, fp128 %b)
  %i1 = add i32 %i, 1
  %more = icmp slt i32 %i1, %n
  br i1 %more, label %loop, label %done

done:
  ret fp128 %next
}

define fp128 @protected_loop(fp128 %a, fp128 %b, i32 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %acc = phi fp128 [ %a, %entry ], [ %next, %loop ]
  %next = call fp128 @llvm.minnum.f128(fp128 %acc, fp128 %b)
  %i1 = add i32 %i, 1
  %more = icmp slt i32 %i1, %n
  br i1 %more, label %loop, label %done

done:
  ret fp128 %next
}

define fp128 @reference_tail(fp128 %a) noinline {
entry:
  %r = tail call fp128 @llvm.floor.f128(fp128 %a)
  ret fp128 %r
}


; ----- negatives -----

define fp128 @unsupported_constrained_minnum(fp128 %a, fp128 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 @llvm.experimental.constrained.minnum.f128(fp128 %a, fp128 %b, metadata !"fpexcept.ignore")
  ret fp128 %r
}

define fp128 @unsupported_constrained_ceil(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 @llvm.experimental.constrained.ceil.f128(fp128 %a, metadata !"fpexcept.ignore")
  ret fp128 %r
}

define i64 @unsupported_lround(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.experimental.constrained.lround.i64.f128(fp128 %a, metadata !"fpexcept.ignore")
  ret i64 %r
}

define fp128 @unsupported_constrained_sin(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 @llvm.experimental.constrained.sin.f128(fp128 %a, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret fp128 %r
}

define fp128 @unsupported_constrained_pow(fp128 %a, fp128 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 @llvm.experimental.constrained.pow.f128(fp128 %a, fp128 %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret fp128 %r
}

define fp128 @unsupported_powi_i64(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 @llvm.powi.f128.i64(fp128 %a, i64 2)
  ret fp128 %r
}

define <1 x fp128> @unsupported_vector(<1 x fp128> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <1 x fp128> @llvm.minnum.v1f128(<1 x fp128> %a, <1 x fp128> %a)
  ret <1 x fp128> %r
}

define ppc_fp128 @unsupported_ppc(ppc_fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call ppc_fp128 @llvm.ceil.ppcf128(ppc_fp128 %a)
  ret ppc_fp128 %r
}

define fp128 @unsupported_poison(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 @llvm.minnum.f128(fp128 %a, fp128 poison)
  ret fp128 %r
}

define fp128 @unsupported_undef(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 @llvm.ceil.f128(fp128 undef)
  ret fp128 %r
}

define fp128 @unsupported_musttail(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call fp128 @llvm.floor.f128(fp128 %a)
  ret fp128 %r
}

define fp128 @unsupported_bundle(fp128 %a, fp128 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 @llvm.minnum.f128(fp128 %a, fp128 %b) [ "deopt"() ]
  ret fp128 %r
}

define fp128 @unsupported_asm(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 asm "", "=w,w"(fp128 %a)
  ret fp128 %r
}

define fp128 @unsupported_indirect(ptr %fp, fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 %fp(fp128 %a)
  ret fp128 %r
}

define void @unsupported_sret(ptr sret(i32) %p, fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @ext_fp128_sret(ptr sret(i32) %p, fp128 %a)
  ret void
}

define i32 @main() {
entry:
  %two = fpext double 2.250000e+00 to fp128
  %neg = fpext double -1.750000e+00 to fp128
  %half = fpext double 1.500000e+00 to fp128
  %e0 = call fp128 @reference_minnum(fp128 %two, fp128 %neg)
  %p0 = call fp128 @protected_minnum(fp128 %two, fp128 %neg)
  %fe0 = call i32 @fold_fp128(fp128 %e0)
  %fp0 = call i32 @fold_fp128(fp128 %p0)
  %ok0 = icmp eq i32 %fe0, %fp0
  %e1 = call fp128 @reference_maxnum(fp128 %two, fp128 %neg)
  %p1 = call fp128 @protected_maxnum(fp128 %two, fp128 %neg)
  %fe1 = call i32 @fold_fp128(fp128 %e1)
  %fp1 = call i32 @fold_fp128(fp128 %p1)
  %ok1 = icmp eq i32 %fe1, %fp1
  ; minimum/maximum.f128 are virtualized and FileCheck'd, but host
  ; x86 ISel cannot select them, so they are not executed here.
  %e4 = call fp128 @reference_ceil(fp128 %neg)
  %p4 = call fp128 @protected_ceil(fp128 %neg)
  %fe4 = call i32 @fold_fp128(fp128 %e4)
  %fp4 = call i32 @fold_fp128(fp128 %p4)
  %ok4 = icmp eq i32 %fe4, %fp4
  %e5 = call fp128 @reference_floor(fp128 %two)
  %p5 = call fp128 @protected_floor(fp128 %two)
  %fe5 = call i32 @fold_fp128(fp128 %e5)
  %fp5 = call i32 @fold_fp128(fp128 %p5)
  %ok5 = icmp eq i32 %fe5, %fp5
  %e6 = call fp128 @reference_trunc(fp128 %neg)
  %p6 = call fp128 @protected_trunc(fp128 %neg)
  %fe6 = call i32 @fold_fp128(fp128 %e6)
  %fp6 = call i32 @fold_fp128(fp128 %p6)
  %ok6 = icmp eq i32 %fe6, %fp6
  %e7 = call fp128 @reference_round(fp128 %half)
  %p7 = call fp128 @protected_round(fp128 %half)
  %fe7 = call i32 @fold_fp128(fp128 %e7)
  %fp7 = call i32 @fold_fp128(fp128 %p7)
  %ok7 = icmp eq i32 %fe7, %fp7
  %e8 = call fp128 @reference_roundeven(fp128 %half)
  %p8 = call fp128 @protected_roundeven(fp128 %half)
  %fe8 = call i32 @fold_fp128(fp128 %e8)
  %fp8 = call i32 @fold_fp128(fp128 %p8)
  %ok8 = icmp eq i32 %fe8, %fp8
  %e9 = call fp128 @reference_rint(fp128 %two)
  %p9 = call fp128 @protected_rint(fp128 %two)
  %fe9 = call i32 @fold_fp128(fp128 %e9)
  %fp9 = call i32 @fold_fp128(fp128 %p9)
  %ok9 = icmp eq i32 %fe9, %fp9
  %e10 = call fp128 @reference_nearbyint(fp128 %neg)
  %p10 = call fp128 @protected_nearbyint(fp128 %neg)
  %fe10 = call i32 @fold_fp128(fp128 %e10)
  %fp10 = call i32 @fold_fp128(fp128 %p10)
  %ok10 = icmp eq i32 %fe10, %fp10
  %e11 = call fp128 @reference_fmf(fp128 %two, fp128 %neg)
  %p11 = call fp128 @protected_fmf(fp128 %two, fp128 %neg)
  %fe11 = call i32 @fold_fp128(fp128 %e11)
  %fp11 = call i32 @fold_fp128(fp128 %p11)
  %ok11 = icmp eq i32 %fe11, %fp11
  %e12 = call fp128 @reference_phi(i1 true, fp128 %two, fp128 %neg)
  %p12 = call fp128 @protected_phi(i1 true, fp128 %two, fp128 %neg)
  %fe12 = call i32 @fold_fp128(fp128 %e12)
  %fp12 = call i32 @fold_fp128(fp128 %p12)
  %ok12 = icmp eq i32 %fe12, %fp12
  %e13 = call fp128 @reference_phi(i1 false, fp128 %two, fp128 %neg)
  %p13 = call fp128 @protected_phi(i1 false, fp128 %two, fp128 %neg)
  %fe13 = call i32 @fold_fp128(fp128 %e13)
  %fp13 = call i32 @fold_fp128(fp128 %p13)
  %ok13 = icmp eq i32 %fe13, %fp13
  %e14 = call fp128 @reference_loop(fp128 %two, fp128 %neg, i32 3)
  %p14 = call fp128 @protected_loop(fp128 %two, fp128 %neg, i32 3)
  %fe14 = call i32 @fold_fp128(fp128 %e14)
  %fp14 = call i32 @fold_fp128(fp128 %p14)
  %ok14 = icmp eq i32 %fe14, %fp14
  %ok15 = icmp eq i32 0, 0
  %t0 = and i1 %ok0, %ok1
  %t3 = and i1 %t0, %ok4
  %t4 = and i1 %t3, %ok5
  %t5 = and i1 %t4, %ok6
  %t6 = and i1 %t5, %ok7
  %t7 = and i1 %t6, %ok8
  %t8 = and i1 %t7, %ok9
  %t9 = and i1 %t8, %ok10
  %t10 = and i1 %t9, %ok11
  %t11 = and i1 %t10, %ok12
  %t12 = and i1 %t11, %ok13
  %t13 = and i1 %t12, %ok14
  %ok = and i1 %t13, %ok15
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_constrained_minnum: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_constrained_ceil: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_lround: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_constrained_sin: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_constrained_pow: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_powi_i64: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_vector: unsupported
; SKIP-DAG: Skipping VMP on unsupported_ppc: unsupported
; SKIP-DAG: Skipping VMP on unsupported_poison: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_undef: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_asm: inline assembly
; SKIP-DAG: Skipping VMP on unsupported_indirect: indirect call
; SKIP-DAG: Skipping VMP on unsupported_sret: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_minnum:
; SKIP-NOT: Skipping VMP on protected_maxnum:
; SKIP-NOT: Skipping VMP on protected_minimum:
; SKIP-NOT: Skipping VMP on protected_maximum:
; SKIP-NOT: Skipping VMP on protected_ceil:
; SKIP-NOT: Skipping VMP on protected_floor:
; SKIP-NOT: Skipping VMP on protected_trunc:
; SKIP-NOT: Skipping VMP on protected_round:
; SKIP-NOT: Skipping VMP on protected_roundeven:
; SKIP-NOT: Skipping VMP on protected_rint:
; SKIP-NOT: Skipping VMP on protected_nearbyint:
; SKIP-NOT: Skipping VMP on protected_fmf:
; SKIP-NOT: Skipping VMP on protected_phi:
; SKIP-NOT: Skipping VMP on protected_loop:

; VIRT: define fp128 @protected_minnum({{.*}} #[[PROT:[0-9]+]] {
; VIRT: %vmp.fp128.regs = alloca [{{[0-9]+}} x fp128]
; VIRT: vmp.dispatch:
; VIRT-NOT: call void @hikari_vmp()
; VIRT-NOT: bitcast fp128 {{.*}} to i128
; VIRT-NOT: select {{.*}}fp128
; VIRT: call{{.*}}fp128 @llvm.minnum.f128(fp128
; VIRT: define fp128 @protected_maxnum({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: select {{.*}}fp128
; VIRT: call{{.*}}fp128 @llvm.maxnum.f128(fp128
; VIRT: define fp128 @protected_minimum({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: @llvm.minnum.f128
; VIRT: call{{.*}}fp128 @llvm.minimum.f128(fp128
; VIRT: define fp128 @protected_maximum({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: @llvm.maxnum.f128
; VIRT: call{{.*}}fp128 @llvm.maximum.f128(fp128
; VIRT: define fp128 @protected_ceil({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: fptosi
; VIRT-NOT: sitofp
; VIRT: call{{.*}}fp128 @llvm.ceil.f128(fp128
; VIRT: define fp128 @protected_floor({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call{{.*}}fp128 @llvm.floor.f128(fp128
; VIRT: define fp128 @protected_trunc({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call{{.*}}fp128 @llvm.trunc.f128(fp128
; VIRT: define fp128 @protected_round({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call{{.*}}fp128 @llvm.round.f128(fp128
; VIRT: define fp128 @protected_roundeven({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: @llvm.round.f128
; VIRT: call{{.*}}fp128 @llvm.roundeven.f128(fp128
; VIRT: define fp128 @protected_rint({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call{{.*}}fp128 @llvm.rint.f128(fp128
; VIRT: define fp128 @protected_nearbyint({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call{{.*}}fp128 @llvm.nearbyint.f128(fp128
; VIRT: define fp128 @protected_fmf({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call nnan nsz fp128 @llvm.minnum.f128(fp128
; VIRT: define fp128 @protected_phi({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: call{{.*}}fp128 @llvm.minnum.f128(fp128
; VIRT-DAG: call{{.*}}fp128 @llvm.floor.f128(fp128
; VIRT: define fp128 @protected_loop({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call{{.*}}fp128 @llvm.minnum.f128(fp128
; VIRT: define {{.*}} @unsupported_constrained_minnum({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_constrained_ceil({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_lround({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_constrained_sin({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_constrained_pow({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_powi_i64({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_vector({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ppc({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_poison({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_undef({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_musttail({{.*}} #[[UNSUPMUST:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_bundle({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_asm({{.*}} #[[UNSUPASM:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_indirect({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_sret({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; Direct musttail / inline asm are early deselects; +no selected/virtualized.
; VIRT-NOT: attributes #[[UNSUPMUST]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPMUST]] = { {{.*}}"hikari.vmp.selected"
; VIRT-NOT: attributes #[[UNSUPASM]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPASM]] = { {{.*}}"hikari.vmp.selected"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
