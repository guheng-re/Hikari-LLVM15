; Restricted llvm.vector.insert / llvm.vector.extract on supported
; fixed vectors.  Lowered to existing VectorShuffle (extract: one
; shuffle; insert: widen + blend).  Must not Call-replay: host lli
; cannot execute the intrinsic.  idx is an i64 ImmArg, a multiple of
; the subvector length, and in range.  >128 / poison / undef /
; musttail / bundles stay rejected.  Scalable is also rejected, but
; is omitted here so AArch64 llc without +sve can compile the module.
; No new VM opcode.
; Reference uses equivalent shufflevector so lli can compare.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare <2 x i32> @llvm.vector.extract.v2i32.v4i32(<4 x i32>, i64 immarg)
declare <1 x i32> @llvm.vector.extract.v1i32.v4i32(<4 x i32>, i64 immarg)
declare <4 x i32> @llvm.vector.extract.v4i32.v4i32(<4 x i32>, i64 immarg)
declare <4 x i32> @llvm.vector.insert.v4i32.v2i32(<4 x i32>, <2 x i32>, i64 immarg)
declare <4 x i32> @llvm.vector.insert.v4i32.v4i32(<4 x i32>, <4 x i32>, i64 immarg)
declare <4 x float> @llvm.vector.extract.v4f32.v4f32(<4 x float>, i64 immarg)
declare <2 x float> @llvm.vector.extract.v2f32.v4f32(<4 x float>, i64 immarg)
declare <4 x float> @llvm.vector.insert.v4f32.v2f32(<4 x float>, <2 x float>, i64 immarg)
declare <4 x i8> @llvm.vector.extract.v4i8.v8i8(<8 x i8>, i64 immarg)
declare <8 x i8> @llvm.vector.insert.v8i8.v4i8(<8 x i8>, <4 x i8>, i64 immarg)
declare <4 x i32> @llvm.vector.extract.v4i32.v8i32(<8 x i32>, i64 immarg)

define i32 @sink_i32(ptr %p, i32 %x) {
entry:
  ret i32 %x
}

define i32 @fold_v4i32(<4 x i32> %v) {
entry:
  %e0 = extractelement <4 x i32> %v, i32 0
  %e1 = extractelement <4 x i32> %v, i32 1
  %e2 = extractelement <4 x i32> %v, i32 2
  %e3 = extractelement <4 x i32> %v, i32 3
  %s0 = add i32 %e0, %e1
  %s1 = add i32 %e2, %e3
  %r = xor i32 %s0, %s1
  ret i32 %r
}

define i32 @fold_v2i32(<2 x i32> %v) {
entry:
  %e0 = extractelement <2 x i32> %v, i32 0
  %e1 = extractelement <2 x i32> %v, i32 1
  %r = add i32 %e0, %e1
  ret i32 %r
}

define i32 @fold_v4f32(<4 x float> %v) {
entry:
  %bits = bitcast <4 x float> %v to <4 x i32>
  %r = call i32 @fold_v4i32(<4 x i32> %bits)
  ret i32 %r
}

define i32 @fold_v2f32(<2 x float> %v) {
entry:
  %bits = bitcast <2 x float> %v to <2 x i32>
  %r = call i32 @fold_v2i32(<2 x i32> %bits)
  ret i32 %r
}

define i32 @fold_v8i8(<8 x i8> %v) {
entry:
  %e0 = extractelement <8 x i8> %v, i32 0
  %e1 = extractelement <8 x i8> %v, i32 1
  %e2 = extractelement <8 x i8> %v, i32 4
  %e3 = extractelement <8 x i8> %v, i32 5
  %z0 = zext i8 %e0 to i32
  %z1 = zext i8 %e1 to i32
  %z2 = zext i8 %e2 to i32
  %z3 = zext i8 %e3 to i32
  %s0 = add i32 %z0, %z1
  %s1 = add i32 %z2, %z3
  %r = xor i32 %s0, %s1
  ret i32 %r
}

define i32 @reference_extract_lo(<4 x i32> %v) {
entry:
  %s = shufflevector <4 x i32> %v, <4 x i32> %v, <2 x i32> <i32 0, i32 1>
  %r = call i32 @fold_v2i32(<2 x i32> %s)
  ret i32 %r
}

define i32 @protected_extract_lo(<4 x i32> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %s = call <2 x i32> @llvm.vector.extract.v2i32.v4i32(<4 x i32> %v, i64 0)
  %r = call i32 @fold_v2i32(<2 x i32> %s)
  ret i32 %r
}

define i32 @reference_extract_hi(<4 x i32> %v) {
entry:
  %s = shufflevector <4 x i32> %v, <4 x i32> %v, <2 x i32> <i32 2, i32 3>
  %r = call i32 @fold_v2i32(<2 x i32> %s)
  ret i32 %r
}

define i32 @protected_extract_hi(<4 x i32> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %s = call <2 x i32> @llvm.vector.extract.v2i32.v4i32(<4 x i32> %v, i64 2)
  %r = call i32 @fold_v2i32(<2 x i32> %s)
  ret i32 %r
}

define i32 @reference_extract_lane(<4 x i32> %v) {
entry:
  %s = shufflevector <4 x i32> %v, <4 x i32> %v, <1 x i32> <i32 3>
  %e = extractelement <1 x i32> %s, i32 0
  ret i32 %e
}

define i32 @protected_extract_lane(<4 x i32> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %s = call <1 x i32> @llvm.vector.extract.v1i32.v4i32(<4 x i32> %v, i64 3)
  %e = extractelement <1 x i32> %s, i32 0
  ret i32 %e
}

define i32 @reference_extract_id(<4 x i32> %v) {
entry:
  %r = call i32 @fold_v4i32(<4 x i32> %v)
  ret i32 %r
}

define i32 @protected_extract_id(<4 x i32> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %s = call <4 x i32> @llvm.vector.extract.v4i32.v4i32(<4 x i32> %v, i64 0)
  %r = call i32 @fold_v4i32(<4 x i32> %s)
  ret i32 %r
}

define i32 @reference_insert_lo(<4 x i32> %d, <2 x i32> %s) {
entry:
  %w = shufflevector <2 x i32> %s, <2 x i32> %s, <4 x i32> <i32 0, i32 1, i32 0, i32 0>
  %m = shufflevector <4 x i32> %d, <4 x i32> %w, <4 x i32> <i32 4, i32 5, i32 2, i32 3>
  %r = call i32 @fold_v4i32(<4 x i32> %m)
  ret i32 %r
}

define i32 @protected_insert_lo(<4 x i32> %d, <2 x i32> %s) noinline optnone {
entry:
  call void @hikari_vmp()
  %m = call <4 x i32> @llvm.vector.insert.v4i32.v2i32(<4 x i32> %d, <2 x i32> %s, i64 0)
  %r = call i32 @fold_v4i32(<4 x i32> %m)
  ret i32 %r
}

define i32 @reference_insert_hi(<4 x i32> %d, <2 x i32> %s) {
entry:
  %w = shufflevector <2 x i32> %s, <2 x i32> %s, <4 x i32> <i32 0, i32 1, i32 0, i32 0>
  %m = shufflevector <4 x i32> %d, <4 x i32> %w, <4 x i32> <i32 0, i32 1, i32 4, i32 5>
  %r = call i32 @fold_v4i32(<4 x i32> %m)
  ret i32 %r
}

define i32 @protected_insert_hi(<4 x i32> %d, <2 x i32> %s) noinline optnone {
entry:
  call void @hikari_vmp()
  %m = call <4 x i32> @llvm.vector.insert.v4i32.v2i32(<4 x i32> %d, <2 x i32> %s, i64 2)
  %r = call i32 @fold_v4i32(<4 x i32> %m)
  ret i32 %r
}

define i32 @reference_insert_all(<4 x i32> %d, <4 x i32> %s) {
entry:
  %r = call i32 @fold_v4i32(<4 x i32> %s)
  ret i32 %r
}

define i32 @protected_insert_all(<4 x i32> %d, <4 x i32> %s) noinline optnone {
entry:
  call void @hikari_vmp()
  %m = call <4 x i32> @llvm.vector.insert.v4i32.v4i32(<4 x i32> %d, <4 x i32> %s, i64 0)
  %r = call i32 @fold_v4i32(<4 x i32> %m)
  ret i32 %r
}

define i32 @reference_extract_f32(<4 x float> %v) {
entry:
  %s = shufflevector <4 x float> %v, <4 x float> %v, <2 x i32> <i32 0, i32 1>
  %r = call i32 @fold_v2f32(<2 x float> %s)
  ret i32 %r
}

define i32 @protected_extract_f32(<4 x float> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %s = call <2 x float> @llvm.vector.extract.v2f32.v4f32(<4 x float> %v, i64 0)
  %r = call i32 @fold_v2f32(<2 x float> %s)
  ret i32 %r
}

define i32 @reference_insert_f32(<4 x float> %d, <2 x float> %s) {
entry:
  %w = shufflevector <2 x float> %s, <2 x float> %s, <4 x i32> <i32 0, i32 1, i32 0, i32 0>
  %m = shufflevector <4 x float> %d, <4 x float> %w, <4 x i32> <i32 0, i32 1, i32 4, i32 5>
  %r = call i32 @fold_v4f32(<4 x float> %m)
  ret i32 %r
}

define i32 @protected_insert_f32(<4 x float> %d, <2 x float> %s) noinline optnone {
entry:
  call void @hikari_vmp()
  %m = call <4 x float> @llvm.vector.insert.v4f32.v2f32(<4 x float> %d, <2 x float> %s, i64 2)
  %r = call i32 @fold_v4f32(<4 x float> %m)
  ret i32 %r
}

define i32 @reference_insert_i8(<8 x i8> %d, <4 x i8> %s) {
entry:
  %w = shufflevector <4 x i8> %s, <4 x i8> %s, <8 x i32> <i32 0, i32 1, i32 2, i32 3, i32 0, i32 0, i32 0, i32 0>
  %m = shufflevector <8 x i8> %d, <8 x i8> %w, <8 x i32> <i32 8, i32 9, i32 10, i32 11, i32 4, i32 5, i32 6, i32 7>
  %r = call i32 @fold_v8i8(<8 x i8> %m)
  ret i32 %r
}

define i32 @protected_insert_i8(<8 x i8> %d, <4 x i8> %s) noinline optnone {
entry:
  call void @hikari_vmp()
  %m = call <8 x i8> @llvm.vector.insert.v8i8.v4i8(<8 x i8> %d, <4 x i8> %s, i64 0)
  %r = call i32 @fold_v8i8(<8 x i8> %m)
  ret i32 %r
}

define i32 @protected_extract_tail(<4 x i32> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %s = tail call <2 x i32> @llvm.vector.extract.v2i32.v4i32(<4 x i32> %v, i64 0)
  %r = call i32 @fold_v2i32(<2 x i32> %s)
  ret i32 %r
}

define i32 @protected_extract_phi(i1 %c, <4 x i32> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  br i1 %c, label %left, label %right

left:
  %l = call <2 x i32> @llvm.vector.extract.v2i32.v4i32(<4 x i32> %v, i64 0)
  %lz = call i32 @fold_v2i32(<2 x i32> %l)
  br label %done

right:
  %r = call <2 x i32> @llvm.vector.extract.v2i32.v4i32(<4 x i32> %v, i64 2)
  %rz = call i32 @fold_v2i32(<2 x i32> %r)
  br label %done

done:
  %p = phi i32 [ %lz, %left ], [ %rz, %right ]
  ret i32 %p
}

define i32 @protected_extract_loop(<4 x i32> %v, i32 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %i2, %loop ]
  %acc = phi i32 [ 0, %entry ], [ %acc2, %loop ]
  %s = call <2 x i32> @llvm.vector.extract.v2i32.v4i32(<4 x i32> %v, i64 0)
  %k = call i32 @fold_v2i32(<2 x i32> %s)
  %acc2 = add i32 %acc, %k
  %i2 = add i32 %i, 1
  %more = icmp slt i32 %i2, %n
  br i1 %more, label %loop, label %done

done:
  ret i32 %acc2
}

define i32 @unsupported_extract_wide(<8 x i32> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %s = call <4 x i32> @llvm.vector.extract.v4i32.v8i32(<8 x i32> %v, i64 0)
  %r = call i32 @fold_v4i32(<4 x i32> %s)
  ret i32 %r
}

define i32 @unsupported_extract_poison(<4 x i32> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %s = call <2 x i32> @llvm.vector.extract.v2i32.v4i32(<4 x i32> poison, i64 0)
  %r = call i32 @fold_v2i32(<2 x i32> %s)
  ret i32 %r
}

define i32 @unsupported_extract_undef(<4 x i32> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %s = call <2 x i32> @llvm.vector.extract.v2i32.v4i32(<4 x i32> undef, i64 0)
  %r = call i32 @fold_v2i32(<2 x i32> %s)
  ret i32 %r
}

define i32 @unsupported_extract_musttail(ptr %p, i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %v = insertelement <4 x i32> zeroinitializer, i32 %x, i32 0
  %s = call <2 x i32> @llvm.vector.extract.v2i32.v4i32(<4 x i32> %v, i64 0)
  %z = call i32 @fold_v2i32(<2 x i32> %s)
  %r = musttail call i32 @sink_i32(ptr %p, i32 %z)
  ret i32 %r
}

define i32 @unsupported_extract_bundle(<4 x i32> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %s = call <2 x i32> @llvm.vector.extract.v2i32.v4i32(<4 x i32> %v, i64 0) [ "deopt"() ]
  %r = call i32 @fold_v2i32(<2 x i32> %s)
  ret i32 %r
}

define i32 @unsupported_insert_poison(<4 x i32> %d, <2 x i32> %s) noinline optnone {
entry:
  call void @hikari_vmp()
  %m = call <4 x i32> @llvm.vector.insert.v4i32.v2i32(<4 x i32> %d, <2 x i32> poison, i64 0)
  %r = call i32 @fold_v4i32(<4 x i32> %m)
  ret i32 %r
}

define i32 @main() {
entry:
  %a = insertelement <4 x i32> undef, i32 1, i32 0
  %b = insertelement <4 x i32> %a, i32 2, i32 1
  %c = insertelement <4 x i32> %b, i32 3, i32 2
  %d = insertelement <4 x i32> %c, i32 4, i32 3
  %s0 = insertelement <2 x i32> undef, i32 9, i32 0
  %s1 = insertelement <2 x i32> %s0, i32 8, i32 1
  %fa = insertelement <4 x float> undef, float 1.000000e+00, i32 0
  %fb = insertelement <4 x float> %fa, float 2.000000e+00, i32 1
  %fc = insertelement <4 x float> %fb, float 3.000000e+00, i32 2
  %fd = insertelement <4 x float> %fc, float 4.000000e+00, i32 3
  %fs0 = insertelement <2 x float> undef, float 5.000000e+00, i32 0
  %fs1 = insertelement <2 x float> %fs0, float 6.000000e+00, i32 1
  %i8a = insertelement <8 x i8> undef, i8 1, i32 0
  %i8b = insertelement <8 x i8> %i8a, i8 2, i32 1
  %i8c = insertelement <8 x i8> %i8b, i8 3, i32 2
  %i8d = insertelement <8 x i8> %i8c, i8 4, i32 3
  %i8e = insertelement <8 x i8> %i8d, i8 5, i32 4
  %i8f = insertelement <8 x i8> %i8e, i8 6, i32 5
  %i8g = insertelement <8 x i8> %i8f, i8 7, i32 6
  %i8h = insertelement <8 x i8> %i8g, i8 8, i32 7
  %i8s0 = insertelement <4 x i8> undef, i8 9, i32 0
  %i8s1 = insertelement <4 x i8> %i8s0, i8 10, i32 1
  %i8s2 = insertelement <4 x i8> %i8s1, i8 11, i32 2
  %i8s3 = insertelement <4 x i8> %i8s2, i8 12, i32 3

  %e0 = call i32 @reference_extract_lo(<4 x i32> %d)
  %a0 = call i32 @protected_extract_lo(<4 x i32> %d)
  %e1 = call i32 @reference_extract_hi(<4 x i32> %d)
  %a1 = call i32 @protected_extract_hi(<4 x i32> %d)
  %e2 = call i32 @reference_extract_lane(<4 x i32> %d)
  %a2 = call i32 @protected_extract_lane(<4 x i32> %d)
  %e3 = call i32 @reference_extract_id(<4 x i32> %d)
  %a3 = call i32 @protected_extract_id(<4 x i32> %d)
  %e4 = call i32 @reference_insert_lo(<4 x i32> %d, <2 x i32> %s1)
  %a4 = call i32 @protected_insert_lo(<4 x i32> %d, <2 x i32> %s1)
  %e5 = call i32 @reference_insert_hi(<4 x i32> %d, <2 x i32> %s1)
  %a5 = call i32 @protected_insert_hi(<4 x i32> %d, <2 x i32> %s1)
  %e6 = call i32 @reference_insert_all(<4 x i32> %d, <4 x i32> %d)
  %a6 = call i32 @protected_insert_all(<4 x i32> %d, <4 x i32> %d)
  %e7 = call i32 @reference_extract_f32(<4 x float> %fd)
  %a7 = call i32 @protected_extract_f32(<4 x float> %fd)
  %e8 = call i32 @reference_insert_f32(<4 x float> %fd, <2 x float> %fs1)
  %a8 = call i32 @protected_insert_f32(<4 x float> %fd, <2 x float> %fs1)
  %e9 = call i32 @reference_insert_i8(<8 x i8> %i8h, <4 x i8> %i8s3)
  %a9 = call i32 @protected_insert_i8(<8 x i8> %i8h, <4 x i8> %i8s3)
  %e10 = call i32 @reference_extract_lo(<4 x i32> %d)
  %a10 = call i32 @protected_extract_tail(<4 x i32> %d)
  %e11 = call i32 @reference_extract_lo(<4 x i32> %d)
  %a11 = call i32 @protected_extract_phi(i1 true, <4 x i32> %d)
  %e12 = call i32 @reference_extract_hi(<4 x i32> %d)
  %a12 = call i32 @protected_extract_phi(i1 false, <4 x i32> %d)
  %e13 = call i32 @reference_extract_lo(<4 x i32> %d)
  %t13 = mul i32 %e13, 3
  %a13 = call i32 @protected_extract_loop(<4 x i32> %d, i32 3)

  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %e1, %a1
  %m2 = icmp eq i32 %e2, %a2
  %m3 = icmp eq i32 %e3, %a3
  %m4 = icmp eq i32 %e4, %a4
  %m5 = icmp eq i32 %e5, %a5
  %m6 = icmp eq i32 %e6, %a6
  %m7 = icmp eq i32 %e7, %a7
  %m8 = icmp eq i32 %e8, %a8
  %m9 = icmp eq i32 %e9, %a9
  %m10 = icmp eq i32 %e10, %a10
  %m11 = icmp eq i32 %e11, %a11
  %m12 = icmp eq i32 %e12, %a12
  %m13 = icmp eq i32 %t13, %a13
  %t0 = and i1 %m0, %m1
  %t1 = and i1 %m2, %m3
  %t2 = and i1 %m4, %m5
  %t3 = and i1 %m6, %m7
  %t4 = and i1 %m8, %m9
  %t5 = and i1 %m10, %m11
  %t6 = and i1 %m12, %m13
  %ok0 = and i1 %t0, %t1
  %ok1 = and i1 %t2, %t3
  %ok2 = and i1 %t4, %t5
  %ok3 = and i1 %ok0, %ok1
  %ok4 = and i1 %ok2, %t6
  %ok = and i1 %ok3, %ok4
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_extract_wide: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_extract_poison: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_extract_undef: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_extract_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_extract_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_insert_poison: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_extract_lo:
; SKIP-NOT: Skipping VMP on protected_extract_hi:
; SKIP-NOT: Skipping VMP on protected_extract_lane:
; SKIP-NOT: Skipping VMP on protected_extract_id:
; SKIP-NOT: Skipping VMP on protected_insert_lo:
; SKIP-NOT: Skipping VMP on protected_insert_hi:
; SKIP-NOT: Skipping VMP on protected_insert_all:
; SKIP-NOT: Skipping VMP on protected_extract_f32:
; SKIP-NOT: Skipping VMP on protected_insert_f32:
; SKIP-NOT: Skipping VMP on protected_insert_i8:
; SKIP-NOT: Skipping VMP on protected_extract_tail:
; SKIP-NOT: Skipping VMP on protected_extract_phi:
; SKIP-NOT: Skipping VMP on protected_extract_loop:

; VIRT: define i32 @protected_extract_lo({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call {{.*}}@llvm.vector.extract
; VIRT: define i32 @protected_extract_hi({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call {{.*}}@llvm.vector.extract
; VIRT: define i32 @protected_extract_lane({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call {{.*}}@llvm.vector.extract
; VIRT: define i32 @protected_extract_id({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call {{.*}}@llvm.vector.extract
; VIRT: define i32 @protected_insert_lo({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call {{.*}}@llvm.vector.insert
; VIRT: define i32 @protected_insert_hi({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call {{.*}}@llvm.vector.insert
; VIRT: define i32 @protected_insert_all({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call {{.*}}@llvm.vector.insert
; VIRT: define i32 @protected_extract_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call {{.*}}@llvm.vector.extract
; VIRT: define i32 @protected_insert_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call {{.*}}@llvm.vector.insert
; VIRT: define i32 @protected_insert_i8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call {{.*}}@llvm.vector.insert
; VIRT: define i32 @protected_extract_tail({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: tail call
; VIRT-NOT: call {{.*}}@llvm.vector.extract
; VIRT: define i32 @protected_extract_phi({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call {{.*}}@llvm.vector.extract
; VIRT: define i32 @protected_extract_loop({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call {{.*}}@llvm.vector.extract
; VIRT: define i32 @unsupported_extract_wide({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define i32 @unsupported_extract_poison({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define i32 @unsupported_extract_undef({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define i32 @unsupported_extract_musttail({{.*}} #[[UNSUP_MT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call i32 @sink_i32(
; VIRT: define i32 @unsupported_extract_bundle({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define i32 @unsupported_insert_poison({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"
; VIRT-NOT: attributes #[[UNSUP_MT]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
