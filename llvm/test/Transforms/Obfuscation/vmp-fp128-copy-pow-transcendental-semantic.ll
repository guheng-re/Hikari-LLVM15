; Listed scalar IEEE fp128 copysign / pow / powi / transcendentals:
; llvm.copysign.f128, llvm.pow.f128, llvm.powi.f128.i32, llvm.sin.f128,
; llvm.cos.f128, llvm.exp.f128, llvm.exp2.f128, llvm.log.f128,
; llvm.log2.f128, llvm.log10.f128.  Replayed through CallDescriptor as
; a typed CreateCall of the original intrinsic Function* on the
; dedicated vmp.fp128.regs frame.  Never i128 reinterpretation.
; pow stays pow; powi stays powi with an i32 exponent.  Valid
; FastMathFlags, calling convention, attributes, metadata, and
; debug locations are preserved.  Ordinary tail of an already-supported CallInst is accepted; see vmp-direct-call-tail-eligibility-semantic.ll.  musttail stays rejected.
;
; Rejected: constrained lround, constrained forms, vector fp128, ppc_fp128,
; i64 powi, poison/undef, musttail, operand bundles, inline asm,
; invalid ABI / call shapes.  Listed canonicalize.f128 lives in
; vmp-fp128-canonicalize-semantic.ll.  Listed is.fpclass.f128 lives
; in vmp-fp128-fpclass-semantic.ll.  Unsupported fp128 intrinsics
; are not rewritten into ordinary external calls.
;
; Host lli compares reference vs protected bit patterns after dropping
; unsupported bodies.  FileCheck + lli + AArch64 llc/readobj.
; O0/O2 x aesSeed 97/7.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.ll > %t.o0.live.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.live.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.ll > %t.o2.live.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.live.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.s7.ll > %t.o0.s7.live.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.s7.live.ll > %t.o0.s7.host.ll
; RUN: lli -force-interpreter %t.o0.s7.host.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.s7.ll > %t.o2.s7.live.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.s7.live.ll > %t.o2.s7.host.ll
; RUN: lli -force-interpreter %t.o2.s7.host.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare fp128 @llvm.copysign.f128(fp128, fp128)
declare fp128 @llvm.pow.f128(fp128, fp128)
declare fp128 @llvm.powi.f128.i32(fp128, i32)
declare fp128 @llvm.powi.f128.i64(fp128, i64)
declare fp128 @llvm.sin.f128(fp128)
declare fp128 @llvm.cos.f128(fp128)
declare fp128 @llvm.exp.f128(fp128)
declare fp128 @llvm.exp2.f128(fp128)
declare fp128 @llvm.log.f128(fp128)
declare fp128 @llvm.log2.f128(fp128)
declare fp128 @llvm.log10.f128(fp128)
declare i64 @llvm.experimental.constrained.lround.i64.f128(fp128, metadata)
declare fp128 @llvm.experimental.constrained.sin.f128(fp128, metadata, metadata)
declare fp128 @llvm.experimental.constrained.pow.f128(fp128, fp128, metadata, metadata)
declare fp128 @llvm.experimental.constrained.cos.f128(fp128, metadata, metadata)
declare <1 x fp128> @llvm.sin.v1f128(<1 x fp128>)
declare ppc_fp128 @llvm.cos.ppcf128(ppc_fp128)
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

define fp128 @reference_copysign(fp128 %a, fp128 %b) noinline {
entry:
  %r = call fp128 @llvm.copysign.f128(fp128 %a, fp128 %b)
  ret fp128 %r
}

define fp128 @protected_copysign(fp128 %a, fp128 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 @llvm.copysign.f128(fp128 %a, fp128 %b)
  ret fp128 %r
}

define fp128 @reference_pow(fp128 %a, fp128 %b) noinline {
entry:
  %r = call fp128 @llvm.pow.f128(fp128 %a, fp128 %b)
  ret fp128 %r
}

define fp128 @protected_pow(fp128 %a, fp128 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 @llvm.pow.f128(fp128 %a, fp128 %b)
  ret fp128 %r
}

define fp128 @reference_powi(fp128 %a, i32 %e) noinline {
entry:
  %r = call fp128 @llvm.powi.f128.i32(fp128 %a, i32 %e)
  ret fp128 %r
}

define fp128 @protected_powi(fp128 %a, i32 %e) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 @llvm.powi.f128.i32(fp128 %a, i32 %e)
  ret fp128 %r
}

define fp128 @reference_sin(fp128 %a) noinline {
entry:
  %r = call fp128 @llvm.sin.f128(fp128 %a)
  ret fp128 %r
}

define fp128 @protected_sin(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 @llvm.sin.f128(fp128 %a)
  ret fp128 %r
}

define fp128 @reference_cos(fp128 %a) noinline {
entry:
  %r = call fp128 @llvm.cos.f128(fp128 %a)
  ret fp128 %r
}

define fp128 @protected_cos(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 @llvm.cos.f128(fp128 %a)
  ret fp128 %r
}

define fp128 @reference_exp(fp128 %a) noinline {
entry:
  %r = call fp128 @llvm.exp.f128(fp128 %a)
  ret fp128 %r
}

define fp128 @protected_exp(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 @llvm.exp.f128(fp128 %a)
  ret fp128 %r
}

define fp128 @reference_exp2(fp128 %a) noinline {
entry:
  %r = call fp128 @llvm.exp2.f128(fp128 %a)
  ret fp128 %r
}

define fp128 @protected_exp2(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 @llvm.exp2.f128(fp128 %a)
  ret fp128 %r
}

define fp128 @reference_log(fp128 %a) noinline {
entry:
  %r = call fp128 @llvm.log.f128(fp128 %a)
  ret fp128 %r
}

define fp128 @protected_log(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 @llvm.log.f128(fp128 %a)
  ret fp128 %r
}

define fp128 @reference_log2(fp128 %a) noinline {
entry:
  %r = call fp128 @llvm.log2.f128(fp128 %a)
  ret fp128 %r
}

define fp128 @protected_log2(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 @llvm.log2.f128(fp128 %a)
  ret fp128 %r
}

define fp128 @reference_log10(fp128 %a) noinline {
entry:
  %r = call fp128 @llvm.log10.f128(fp128 %a)
  ret fp128 %r
}

define fp128 @protected_log10(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 @llvm.log10.f128(fp128 %a)
  ret fp128 %r
}

define fp128 @reference_fmf(fp128 %a) noinline {
entry:
  %r = call nnan nsz fp128 @llvm.sin.f128(fp128 %a)
  ret fp128 %r
}

define fp128 @protected_fmf(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call nnan nsz fp128 @llvm.sin.f128(fp128 %a)
  ret fp128 %r
}

define fp128 @reference_phi(i1 %c, fp128 %a, fp128 %b) noinline {
entry:
  br i1 %c, label %left, label %right

left:
  %cs = call fp128 @llvm.copysign.f128(fp128 %a, fp128 %b)
  br label %join

right:
  %sn = call fp128 @llvm.sin.f128(fp128 %a)
  br label %join

join:
  %p = phi fp128 [ %cs, %left ], [ %sn, %right ]
  ret fp128 %p
}

define fp128 @protected_phi(i1 %c, fp128 %a, fp128 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  br i1 %c, label %left, label %right

left:
  %cs = call fp128 @llvm.copysign.f128(fp128 %a, fp128 %b)
  br label %join

right:
  %sn = call fp128 @llvm.sin.f128(fp128 %a)
  br label %join

join:
  %p = phi fp128 [ %cs, %left ], [ %sn, %right ]
  ret fp128 %p
}

define fp128 @reference_loop(fp128 %a, i32 %n) noinline {
entry:
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %acc = phi fp128 [ %a, %entry ], [ %next, %loop ]
  %next = call fp128 @llvm.powi.f128.i32(fp128 %acc, i32 1)
  %i1 = add i32 %i, 1
  %more = icmp slt i32 %i1, %n
  br i1 %more, label %loop, label %done

done:
  ret fp128 %next
}

define fp128 @protected_loop(fp128 %a, i32 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %acc = phi fp128 [ %a, %entry ], [ %next, %loop ]
  %next = call fp128 @llvm.powi.f128.i32(fp128 %acc, i32 1)
  %i1 = add i32 %i, 1
  %more = icmp slt i32 %i1, %n
  br i1 %more, label %loop, label %done

done:
  ret fp128 %next
}

define fp128 @reference_tail(fp128 %a) noinline {
entry:
  %r = tail call fp128 @llvm.cos.f128(fp128 %a)
  ret fp128 %r
}


; ----- negatives -----

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

define fp128 @unsupported_constrained_cos(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 @llvm.experimental.constrained.cos.f128(fp128 %a, metadata !"round.tonearest", metadata !"fpexcept.ignore")
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
  %r = call <1 x fp128> @llvm.sin.v1f128(<1 x fp128> %a)
  ret <1 x fp128> %r
}

define ppc_fp128 @unsupported_ppc(ppc_fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call ppc_fp128 @llvm.cos.ppcf128(ppc_fp128 %a)
  ret ppc_fp128 %r
}

define fp128 @unsupported_poison(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 @llvm.sin.f128(fp128 poison)
  ret fp128 %r
}

define fp128 @unsupported_undef(fp128 %a, fp128 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 @llvm.copysign.f128(fp128 %a, fp128 undef)
  ret fp128 %r
}

define fp128 @unsupported_musttail(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call fp128 @llvm.cos.f128(fp128 %a)
  ret fp128 %r
}

define fp128 @unsupported_bundle(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 @llvm.sin.f128(fp128 %a) [ "deopt"() ]
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
  %neg = fpext double -2.250000e+00 to fp128
  %pos = fpext double 1.500000e+00 to fp128
  %two = fpext double 2.000000e+00 to fp128
  %three = fpext double 3.000000e+00 to fp128
  %half = fpext double 5.000000e-01 to fp128
  %one = fpext double 1.000000e+00 to fp128
  %eight = fpext double 8.000000e+00 to fp128
  %e0 = call fp128 @reference_copysign(fp128 %neg, fp128 %pos)
  %p0 = call fp128 @protected_copysign(fp128 %neg, fp128 %pos)
  %fe0 = call i32 @fold_fp128(fp128 %e0)
  %fp0 = call i32 @fold_fp128(fp128 %p0)
  %ok0 = icmp eq i32 %fe0, %fp0
  %e1 = call fp128 @reference_pow(fp128 %two, fp128 %three)
  %p1 = call fp128 @protected_pow(fp128 %two, fp128 %three)
  %fe1 = call i32 @fold_fp128(fp128 %e1)
  %fp1 = call i32 @fold_fp128(fp128 %p1)
  %ok1 = icmp eq i32 %fe1, %fp1
  %e2 = call fp128 @reference_powi(fp128 %two, i32 3)
  %p2 = call fp128 @protected_powi(fp128 %two, i32 3)
  %fe2 = call i32 @fold_fp128(fp128 %e2)
  %fp2 = call i32 @fold_fp128(fp128 %p2)
  %ok2 = icmp eq i32 %fe2, %fp2
  %e3 = call fp128 @reference_sin(fp128 %half)
  %p3 = call fp128 @protected_sin(fp128 %half)
  %fe3 = call i32 @fold_fp128(fp128 %e3)
  %fp3 = call i32 @fold_fp128(fp128 %p3)
  %ok3 = icmp eq i32 %fe3, %fp3
  %e4 = call fp128 @reference_cos(fp128 %half)
  %p4 = call fp128 @protected_cos(fp128 %half)
  %fe4 = call i32 @fold_fp128(fp128 %e4)
  %fp4 = call i32 @fold_fp128(fp128 %p4)
  %ok4 = icmp eq i32 %fe4, %fp4
  %e5 = call fp128 @reference_exp(fp128 %one)
  %p5 = call fp128 @protected_exp(fp128 %one)
  %fe5 = call i32 @fold_fp128(fp128 %e5)
  %fp5 = call i32 @fold_fp128(fp128 %p5)
  %ok5 = icmp eq i32 %fe5, %fp5
  %e6 = call fp128 @reference_exp2(fp128 %three)
  %p6 = call fp128 @protected_exp2(fp128 %three)
  %fe6 = call i32 @fold_fp128(fp128 %e6)
  %fp6 = call i32 @fold_fp128(fp128 %p6)
  %ok6 = icmp eq i32 %fe6, %fp6
  %e7 = call fp128 @reference_log(fp128 %eight)
  %p7 = call fp128 @protected_log(fp128 %eight)
  %fe7 = call i32 @fold_fp128(fp128 %e7)
  %fp7 = call i32 @fold_fp128(fp128 %p7)
  %ok7 = icmp eq i32 %fe7, %fp7
  %e8 = call fp128 @reference_log2(fp128 %eight)
  %p8 = call fp128 @protected_log2(fp128 %eight)
  %fe8 = call i32 @fold_fp128(fp128 %e8)
  %fp8 = call i32 @fold_fp128(fp128 %p8)
  %ok8 = icmp eq i32 %fe8, %fp8
  %e9 = call fp128 @reference_log10(fp128 %eight)
  %p9 = call fp128 @protected_log10(fp128 %eight)
  %fe9 = call i32 @fold_fp128(fp128 %e9)
  %fp9 = call i32 @fold_fp128(fp128 %p9)
  %ok9 = icmp eq i32 %fe9, %fp9
  %e10 = call fp128 @reference_fmf(fp128 %half)
  %p10 = call fp128 @protected_fmf(fp128 %half)
  %fe10 = call i32 @fold_fp128(fp128 %e10)
  %fp10 = call i32 @fold_fp128(fp128 %p10)
  %ok10 = icmp eq i32 %fe10, %fp10
  %e11 = call fp128 @reference_phi(i1 true, fp128 %neg, fp128 %pos)
  %p11 = call fp128 @protected_phi(i1 true, fp128 %neg, fp128 %pos)
  %fe11 = call i32 @fold_fp128(fp128 %e11)
  %fp11 = call i32 @fold_fp128(fp128 %p11)
  %ok11 = icmp eq i32 %fe11, %fp11
  %e12 = call fp128 @reference_phi(i1 false, fp128 %half, fp128 %pos)
  %p12 = call fp128 @protected_phi(i1 false, fp128 %half, fp128 %pos)
  %fe12 = call i32 @fold_fp128(fp128 %e12)
  %fp12 = call i32 @fold_fp128(fp128 %p12)
  %ok12 = icmp eq i32 %fe12, %fp12
  %e13 = call fp128 @reference_loop(fp128 %two, i32 3)
  %p13 = call fp128 @protected_loop(fp128 %two, i32 3)
  %fe13 = call i32 @fold_fp128(fp128 %e13)
  %fp13 = call i32 @fold_fp128(fp128 %p13)
  %ok13 = icmp eq i32 %fe13, %fp13
  %ok14 = icmp eq i32 0, 0
  %t0 = and i1 %ok0, %ok1
  %t1 = and i1 %t0, %ok2
  %t2 = and i1 %t1, %ok3
  %t3 = and i1 %t2, %ok4
  %t4 = and i1 %t3, %ok5
  %t5 = and i1 %t4, %ok6
  %t6 = and i1 %t5, %ok7
  %t7 = and i1 %t6, %ok8
  %t8 = and i1 %t7, %ok9
  %t9 = and i1 %t8, %ok10
  %t10 = and i1 %t9, %ok11
  %t11 = and i1 %t10, %ok12
  %t12 = and i1 %t11, %ok13
  %ok = and i1 %t12, %ok14
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_lround: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_constrained_sin: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_constrained_pow: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_constrained_cos: unsupported call instruction
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
; SKIP-NOT: Skipping VMP on protected_copysign:
; SKIP-NOT: Skipping VMP on protected_pow:
; SKIP-NOT: Skipping VMP on protected_powi:
; SKIP-NOT: Skipping VMP on protected_sin:
; SKIP-NOT: Skipping VMP on protected_cos:
; SKIP-NOT: Skipping VMP on protected_exp:
; SKIP-NOT: Skipping VMP on protected_exp2:
; SKIP-NOT: Skipping VMP on protected_log:
; SKIP-NOT: Skipping VMP on protected_log2:
; SKIP-NOT: Skipping VMP on protected_log10:
; SKIP-NOT: Skipping VMP on protected_fmf:
; SKIP-NOT: Skipping VMP on protected_phi:
; SKIP-NOT: Skipping VMP on protected_loop:

; VIRT: define fp128 @protected_copysign({{.*}} #[[PROT:[0-9]+]] {
; VIRT: %vmp.fp128.regs = alloca [{{[0-9]+}} x fp128]
; VIRT: vmp.dispatch:
; VIRT-NOT: call void @hikari_vmp()
; VIRT-NOT: bitcast fp128 {{.*}} to i128
; VIRT: call{{.*}}fp128 @llvm.copysign.f128(fp128
; VIRT: define fp128 @protected_pow({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: @llvm.powi
; VIRT: call{{.*}}fp128 @llvm.pow.f128(fp128
; VIRT: define fp128 @protected_powi({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: @llvm.pow.f128
; VIRT: call{{.*}}fp128 @llvm.powi.f128.i32(fp128{{.*}}i32
; VIRT: define fp128 @protected_sin({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call{{.*}}fp128 @llvm.sin.f128(fp128
; VIRT: define fp128 @protected_cos({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call{{.*}}fp128 @llvm.cos.f128(fp128
; VIRT: define fp128 @protected_exp({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call{{.*}}fp128 @llvm.exp.f128(fp128
; VIRT: define fp128 @protected_exp2({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call{{.*}}fp128 @llvm.exp2.f128(fp128
; VIRT: define fp128 @protected_log({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call{{.*}}fp128 @llvm.log.f128(fp128
; VIRT: define fp128 @protected_log2({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call{{.*}}fp128 @llvm.log2.f128(fp128
; VIRT: define fp128 @protected_log10({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call{{.*}}fp128 @llvm.log10.f128(fp128
; VIRT: define fp128 @protected_fmf({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call nnan nsz fp128 @llvm.sin.f128(fp128
; VIRT: define fp128 @protected_phi({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: call{{.*}}fp128 @llvm.copysign.f128(fp128
; VIRT-DAG: call{{.*}}fp128 @llvm.sin.f128(fp128
; VIRT: define fp128 @protected_loop({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call{{.*}}fp128 @llvm.powi.f128.i32(fp128{{.*}}i32
; VIRT: define {{.*}} @unsupported_lround({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_constrained_sin({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_constrained_pow({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_constrained_cos({{.*}} #[[UNSUP]] {
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
