; Scalar llvm.expect / llvm.expect.with.probability: identity on
; operand 0.  Every VMP scalar integer width (i1/i8/i16/i32/i64/i128).
; Lowered to Move of the runtime value into the matching integer /
; i128 VReg.  Never CallDescriptor and never re-emitted.  Probability
; must be a finite double ConstantFP in the closed interval [0.0, 1.0]
; (IEEE APFloat compare; -0.0 equals +0.0 and is accepted) and is
; dropped.
;
; Rejected: poison/undef, vector, i2, dynamic/non-double probability,
; NaN / +Inf / -Inf / negative / >1.0 probability, musttail, bundles,
; fastcc, indirect, sret.
;
; Host lli can lower llvm.expect (IntrinsicLowering).  It cannot lower
; expect.with.probability, so those references use the raw value.
; FileCheck + lli + AArch64 llc/readobj.  O0/O2 x aesSeed 97/7.
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
declare i1 @llvm.expect.i1(i1, i1)
declare i8 @llvm.expect.i8(i8, i8)
declare i16 @llvm.expect.i16(i16, i16)
declare i32 @llvm.expect.i32(i32, i32)
declare i64 @llvm.expect.i64(i64, i64)
declare i128 @llvm.expect.i128(i128, i128)
declare i1 @llvm.expect.with.probability.i1(i1, i1, double)
declare i32 @llvm.expect.with.probability.i32(i32, i32, double)
declare i64 @llvm.expect.with.probability.i64(i64, i64, double)
declare i128 @llvm.expect.with.probability.i128(i128, i128, double)
declare i2 @llvm.expect.i2(i2, i2)
declare <4 x i32> @llvm.expect.v4i32(<4 x i32>, <4 x i32>)
declare void @ext_sret_byval(ptr sret(i32), ptr byval(i32))

; ----- positives -----

define i32 @reference_i1(i32 %x) noinline {
entry:
  %cmp = icmp sgt i32 %x, 0
  %e = call i1 @llvm.expect.i1(i1 %cmp, i1 true)
  br i1 %e, label %pos, label %neg

pos:
  ret i32 1

neg:
  ret i32 0
}

define i32 @protected_i1(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %cmp = icmp sgt i32 %x, 0
  %e = call i1 @llvm.expect.i1(i1 %cmp, i1 true)
  br i1 %e, label %pos, label %neg

pos:
  ret i32 1

neg:
  ret i32 0
}

define i8 @reference_i8(i8 %x) noinline {
entry:
  %e = call i8 @llvm.expect.i8(i8 %x, i8 1)
  ret i8 %e
}

define i8 @protected_i8(i8 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %e = call i8 @llvm.expect.i8(i8 %x, i8 1)
  ret i8 %e
}

define i16 @reference_i16(i16 %x) noinline {
entry:
  %e = call i16 @llvm.expect.i16(i16 %x, i16 2)
  ret i16 %e
}

define i16 @protected_i16(i16 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %e = call i16 @llvm.expect.i16(i16 %x, i16 2)
  ret i16 %e
}

define i32 @reference_i32(i32 %x) noinline {
entry:
  %e = call i32 @llvm.expect.i32(i32 %x, i32 0)
  ret i32 %e
}

define i32 @protected_i32(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %e = call i32 @llvm.expect.i32(i32 %x, i32 0)
  ret i32 %e
}

define i64 @reference_i64(i64 %x) noinline {
entry:
  %e = call i64 @llvm.expect.i64(i64 %x, i64 1)
  ret i64 %e
}

define i64 @protected_i64(i64 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %e = call i64 @llvm.expect.i64(i64 %x, i64 1)
  ret i64 %e
}

define i128 @reference_i128(i128 %x) noinline {
entry:
  %e = call i128 @llvm.expect.i128(i128 %x, i128 0)
  ret i128 %e
}

define i128 @protected_i128(i128 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %e = call i128 @llvm.expect.i128(i128 %x, i128 0)
  ret i128 %e
}

define i32 @reference_prob(i32 %x) noinline {
entry:
  %cmp = icmp sgt i32 %x, 0
  br i1 %cmp, label %pos, label %neg

pos:
  ret i32 4

neg:
  ret i32 5
}

define i32 @protected_prob(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %cmp = icmp sgt i32 %x, 0
  %e = call i1 @llvm.expect.with.probability.i1(i1 %cmp, i1 true, double 8.000000e-01)
  br i1 %e, label %pos, label %neg

pos:
  ret i32 4

neg:
  ret i32 5
}

define i32 @reference_prob_i32(i32 %x) noinline {
entry:
  ret i32 %x
}

define i32 @protected_prob_i32(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %e = call i32 @llvm.expect.with.probability.i32(i32 %x, i32 7, double 1.000000e+00)
  ret i32 %e
}

define i64 @reference_prob_i64(i64 %x) noinline {
entry:
  ret i64 %x
}

define i64 @protected_prob_i64(i64 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %e = call i64 @llvm.expect.with.probability.i64(i64 %x, i64 0, double 0.000000e+00)
  ret i64 %e
}

define i128 @reference_prob_i128(i128 %x) noinline {
entry:
  ret i128 %x
}

define i128 @protected_prob_i128(i128 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %e = call i128 @llvm.expect.with.probability.i128(i128 %x, i128 1, double 5.000000e-01)
  ret i128 %e
}

define i32 @reference_prob_nzero(i32 %x) noinline {
entry:
  ret i32 %x
}

define i32 @protected_prob_nzero(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %e = call i32 @llvm.expect.with.probability.i32(i32 %x, i32 0, double -0.000000e+00)
  ret i32 %e
}

define i32 @reference_phi(i1 %c, i32 %a, i32 %b) noinline {
entry:
  br i1 %c, label %left, label %right

left:
  %l = call i32 @llvm.expect.i32(i32 %a, i32 1)
  br label %join

right:
  %r = call i32 @llvm.expect.i32(i32 %b, i32 0)
  br label %join

join:
  %p = phi i32 [ %l, %left ], [ %r, %right ]
  ret i32 %p
}

define i32 @protected_phi(i1 %c, i32 %a, i32 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  br i1 %c, label %left, label %right

left:
  %l = call i32 @llvm.expect.i32(i32 %a, i32 1)
  br label %join

right:
  %r = call i32 @llvm.expect.i32(i32 %b, i32 0)
  br label %join

join:
  %p = phi i32 [ %l, %left ], [ %r, %right ]
  ret i32 %p
}

define i32 @reference_loop(i32 %x, i32 %n) noinline {
entry:
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %acc = phi i32 [ 0, %entry ], [ %next, %loop ]
  %e = call i32 @llvm.expect.i32(i32 %x, i32 1)
  %next = add i32 %acc, %e
  %i1 = add i32 %i, 1
  %more = icmp slt i32 %i1, %n
  br i1 %more, label %loop, label %done

done:
  ret i32 %next
}

define i32 @protected_loop(i32 %x, i32 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %acc = phi i32 [ 0, %entry ], [ %next, %loop ]
  %e = call i32 @llvm.expect.i32(i32 %x, i32 1)
  %next = add i32 %acc, %e
  %i1 = add i32 %i, 1
  %more = icmp slt i32 %i1, %n
  br i1 %more, label %loop, label %done

done:
  ret i32 %next
}

define i32 @reference_tail(i32 %x) noinline {
entry:
  %e = tail call i32 @llvm.expect.i32(i32 %x, i32 3)
  ret i32 %e
}

define i32 @protected_tail(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %e = tail call i32 @llvm.expect.i32(i32 %x, i32 3)
  ret i32 %e
}

; ----- negatives -----

define i32 @unsupported_poison(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.expect.i32(i32 poison, i32 0)
  ret i32 %r
}

define i32 @unsupported_undef(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.expect.i32(i32 undef, i32 0)
  ret i32 %r
}

define <4 x i32> @unsupported_vector(<4 x i32> %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.expect.v4i32(<4 x i32> %x, <4 x i32> %x)
  ret <4 x i32> %r
}

define i2 @unsupported_i2(i2 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i2 @llvm.expect.i2(i2 %x, i2 0)
  ret i2 %r
}

define i32 @unsupported_dyn_prob(i32 %x, double %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.expect.with.probability.i32(i32 %x, i32 1, double %p)
  ret i32 %r
}

define i32 @unsupported_prob_nan(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.expect.with.probability.i32(i32 %x, i32 1, double 0x7FF8000000000000)
  ret i32 %r
}

define i32 @unsupported_prob_pinf(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.expect.with.probability.i32(i32 %x, i32 1, double 0x7FF0000000000000)
  ret i32 %r
}

define i32 @unsupported_prob_ninf(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.expect.with.probability.i32(i32 %x, i32 1, double 0xFFF0000000000000)
  ret i32 %r
}

define i32 @unsupported_prob_neg(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.expect.with.probability.i32(i32 %x, i32 1, double -1.000000e-01)
  ret i32 %r
}

define i32 @unsupported_prob_gt1(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.expect.with.probability.i32(i32 %x, i32 1, double 2.000000e+00)
  ret i32 %r
}

define i32 @unsupported_musttail(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call i32 @llvm.expect.i32(i32 %x, i32 0)
  ret i32 %r
}

define i32 @unsupported_bundle(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.expect.i32(i32 %x, i32 0) [ "deopt"(i32 0) ]
  ret i32 %r
}

define i32 @unsupported_fastcc(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc i32 @llvm.expect.i32(i32 %x, i32 0)
  ret i32 %r
}


define i32 @unsupported_indirect(ptr %fp, i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 %fp(i32 %x) [ "deopt"(i32 0) ]
  ret i32 %r
}

define void @unsupported_sret(ptr sret(i32) %p, ptr byval(i32) %q) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @ext_sret_byval(ptr sret(i32) %p, ptr byval(i32) %q)
  ret void
}

define i32 @main() {
entry:
  %e0 = call i32 @reference_i1(i32 5)
  %p0 = call i32 @protected_i1(i32 5)
  %ok0 = icmp eq i32 %e0, %p0
  %e0b = call i32 @reference_i1(i32 -2)
  %p0b = call i32 @protected_i1(i32 -2)
  %ok0b = icmp eq i32 %e0b, %p0b
  %e8 = call i8 @reference_i8(i8 9)
  %p8 = call i8 @protected_i8(i8 9)
  %ok8 = icmp eq i8 %e8, %p8
  %e16 = call i16 @reference_i16(i16 11)
  %p16 = call i16 @protected_i16(i16 11)
  %ok16 = icmp eq i16 %e16, %p16
  %e32 = call i32 @reference_i32(i32 13)
  %p32 = call i32 @protected_i32(i32 13)
  %ok32 = icmp eq i32 %e32, %p32
  %e64 = call i64 @reference_i64(i64 15)
  %p64 = call i64 @protected_i64(i64 15)
  %ok64 = icmp eq i64 %e64, %p64
  %e128 = call i128 @reference_i128(i128 17)
  %p128 = call i128 @protected_i128(i128 17)
  %ok128 = icmp eq i128 %e128, %p128
  %ep = call i32 @reference_prob(i32 4)
  %pp = call i32 @protected_prob(i32 4)
  %okp = icmp eq i32 %ep, %pp
  %epb = call i32 @reference_prob(i32 -1)
  %ppb = call i32 @protected_prob(i32 -1)
  %okpb = icmp eq i32 %epb, %ppb
  %ep32 = call i32 @reference_prob_i32(i32 21)
  %pp32 = call i32 @protected_prob_i32(i32 21)
  %okp32 = icmp eq i32 %ep32, %pp32
  %ep64 = call i64 @reference_prob_i64(i64 23)
  %pp64 = call i64 @protected_prob_i64(i64 23)
  %okp64 = icmp eq i64 %ep64, %pp64
  %ep128 = call i128 @reference_prob_i128(i128 25)
  %pp128 = call i128 @protected_prob_i128(i128 25)
  %okp128 = icmp eq i128 %ep128, %pp128
  %epn0 = call i32 @reference_prob_nzero(i32 27)
  %ppn0 = call i32 @protected_prob_nzero(i32 27)
  %okpn0 = icmp eq i32 %epn0, %ppn0
  %ephi = call i32 @reference_phi(i1 true, i32 3, i32 8)
  %pphi = call i32 @protected_phi(i1 true, i32 3, i32 8)
  %okphi = icmp eq i32 %ephi, %pphi
  %ephi2 = call i32 @reference_phi(i1 false, i32 3, i32 8)
  %pphi2 = call i32 @protected_phi(i1 false, i32 3, i32 8)
  %okphi2 = icmp eq i32 %ephi2, %pphi2
  %el = call i32 @reference_loop(i32 2, i32 4)
  %pl = call i32 @protected_loop(i32 2, i32 4)
  %okl = icmp eq i32 %el, %pl
  %et = call i32 @reference_tail(i32 6)
  %pt = call i32 @protected_tail(i32 6)
  %okt = icmp eq i32 %et, %pt
  %t0 = and i1 %ok0, %ok0b
  %t1 = and i1 %t0, %ok8
  %t2 = and i1 %t1, %ok16
  %t3 = and i1 %t2, %ok32
  %t4 = and i1 %t3, %ok64
  %t5 = and i1 %t4, %ok128
  %t6 = and i1 %t5, %okp
  %t7 = and i1 %t6, %okpb
  %t8 = and i1 %t7, %okp32
  %t9 = and i1 %t8, %okp64
  %t10 = and i1 %t9, %okp128
  %t10b = and i1 %t10, %okpn0
  %t11 = and i1 %t10b, %okphi
  %t12 = and i1 %t11, %okphi2
  %t13 = and i1 %t12, %okl
  %ok = and i1 %t13, %okt
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_poison: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_undef: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_vector: unsupported
; SKIP-DAG: Skipping VMP on unsupported_i2: unsupported
; SKIP-DAG: Skipping VMP on unsupported_dyn_prob: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_prob_nan: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_prob_pinf: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_prob_ninf: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_prob_neg: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_prob_gt1: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_indirect: indirect call
; SKIP-DAG: Skipping VMP on unsupported_sret: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_i1:
; SKIP-NOT: Skipping VMP on protected_i8:
; SKIP-NOT: Skipping VMP on protected_i16:
; SKIP-NOT: Skipping VMP on protected_i32:
; SKIP-NOT: Skipping VMP on protected_i64:
; SKIP-NOT: Skipping VMP on protected_i128:
; SKIP-NOT: Skipping VMP on protected_prob:
; SKIP-NOT: Skipping VMP on protected_prob_i32:
; SKIP-NOT: Skipping VMP on protected_prob_i64:
; SKIP-NOT: Skipping VMP on protected_prob_i128:
; SKIP-NOT: Skipping VMP on protected_prob_nzero:
; SKIP-NOT: Skipping VMP on protected_phi:
; SKIP-NOT: Skipping VMP on protected_loop:
; SKIP-NOT: Skipping VMP on protected_tail:

; VIRT: define i32 @protected_i1({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call void @hikari_vmp()
; VIRT-NOT: @llvm.expect
; VIRT: }
; VIRT: define i8 @protected_i8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: @llvm.expect
; VIRT: }
; VIRT: define i16 @protected_i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: @llvm.expect
; VIRT: }
; VIRT: define i32 @protected_i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: @llvm.expect
; VIRT: }
; VIRT: define i64 @protected_i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: @llvm.expect
; VIRT: }
; VIRT: define i128 @protected_i128({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: @llvm.expect
; VIRT: }
; VIRT: define i32 @protected_prob({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: expect.with.probability
; VIRT: }
; VIRT: define i32 @protected_prob_i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: expect.with.probability
; VIRT: }
; VIRT: define i64 @protected_prob_i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: expect.with.probability
; VIRT: }
; VIRT: define i128 @protected_prob_i128({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: expect.with.probability
; VIRT: }
; VIRT: define i32 @protected_prob_nzero({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: expect.with.probability
; VIRT: }
; VIRT: define i32 @protected_phi({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: @llvm.expect
; VIRT: }
; VIRT: define i32 @protected_loop({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: @llvm.expect
; VIRT: }
; VIRT: define i32 @protected_tail({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: tail call
; VIRT-NOT: @llvm.expect
; VIRT: }
; VIRT: define {{.*}} @unsupported_poison({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_undef({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_vector({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_i2({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_dyn_prob({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_prob_nan({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_prob_pinf({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_prob_ninf({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_prob_neg({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_prob_gt1({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_musttail({{.*}} #[[UNSUPMUST:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_bundle({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fastcc({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_indirect({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_sret({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPMUST]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPMUST]] = { {{.*}}"hikari.vmp.selected"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
