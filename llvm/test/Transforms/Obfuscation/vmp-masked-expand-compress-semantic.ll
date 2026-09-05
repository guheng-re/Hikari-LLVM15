; Restricted llvm.masked.expandload / llvm.masked.compressstore.
; Fixed 1..128 vectors (integer / half / f32 / f64), AS0 ptr, matching
; <N x i1> mask and passthru/value.  No alignment ImmArg.  Replayed
; via CallDescriptor.  Expand: consecutive loads fill active lanes;
; inactive lanes keep passthru.  Compress: active lanes pack into
; consecutive stores.  Every accepted element type has a live
; protected_* pair that survives vmp-drop-unsupported.py and is
; compared against a reference on the host interpreter.  Gather/scatter
; live coverage is vmp-masked-gather-scatter-semantic.ll.
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
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.s7.ll > %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare <4 x i32> @llvm.masked.expandload.v4i32(ptr, <4 x i1>, <4 x i32>)
declare void @llvm.masked.compressstore.v4i32(<4 x i32>, ptr, <4 x i1>)
declare <4 x float> @llvm.masked.expandload.v4f32(ptr, <4 x i1>, <4 x float>)
declare void @llvm.masked.compressstore.v4f32(<4 x float>, ptr, <4 x i1>)
declare <8 x i8> @llvm.masked.expandload.v8i8(ptr, <8 x i1>, <8 x i8>)
declare void @llvm.masked.compressstore.v8i8(<8 x i8>, ptr, <8 x i1>)
declare <4 x i16> @llvm.masked.expandload.v4i16(ptr, <4 x i1>, <4 x i16>)
declare void @llvm.masked.compressstore.v4i16(<4 x i16>, ptr, <4 x i1>)
declare <2 x i64> @llvm.masked.expandload.v2i64(ptr, <2 x i1>, <2 x i64>)
declare void @llvm.masked.compressstore.v2i64(<2 x i64>, ptr, <2 x i1>)
declare <4 x half> @llvm.masked.expandload.v4f16(ptr, <4 x i1>, <4 x half>)
declare void @llvm.masked.compressstore.v4f16(<4 x half>, ptr, <4 x i1>)
declare <2 x double> @llvm.masked.expandload.v2f64(ptr, <2 x i1>, <2 x double>)
declare void @llvm.masked.compressstore.v2f64(<2 x double>, ptr, <2 x i1>)
declare <8 x i1> @llvm.masked.expandload.v8i1(ptr, <8 x i1>, <8 x i1>)
declare void @llvm.masked.compressstore.v8i1(<8 x i1>, ptr, <8 x i1>)
declare <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr>, i32, <4 x i1>, <4 x i32>)
declare <8 x i32> @llvm.masked.expandload.v8i32(ptr, <8 x i1>, <8 x i32>)

@src.i32 = private global [8 x i32] [i32 10, i32 20, i32 30, i32 40, i32 50, i32 60, i32 70, i32 80], align 16
@src.f32 = private global [4 x float] [float 1.000000e+00, float 2.000000e+00, float 3.000000e+00, float 4.000000e+00], align 16
@src.i8 = private global [8 x i8] [i8 1, i8 2, i8 3, i8 4, i8 5, i8 6, i8 7, i8 8], align 8
@src.i16 = private global [4 x i16] [i16 10, i16 20, i16 30, i16 40], align 8
@src.i64 = private global [2 x i64] [i64 10, i64 20], align 16
@src.half = private global [4 x half] [half 1.000000e+00, half 2.000000e+00, half 3.000000e+00, half 4.000000e+00], align 8
@src.f64 = private global [2 x double] [double 1.000000e+00, double 2.000000e+00], align 16
@src.i1 = private global [8 x i8] [i8 1, i8 0, i8 1, i8 0, i8 1, i8 0, i8 1, i8 0], align 8
@sentinel = private global i32 291, align 4

define i32 @fold_i32x4(<4 x i32> %v) {
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

define i32 @fold_mem4(ptr %p) {
entry:
  %v = load <4 x i32>, ptr %p, align 4
  %r = call i32 @fold_i32x4(<4 x i32> %v)
  ret i32 %r
}

define i32 @fold_i8x8(<8 x i8> %v) {
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

define i32 @fold_i16x4(<4 x i16> %v) {
entry:
  %e0 = extractelement <4 x i16> %v, i32 0
  %e1 = extractelement <4 x i16> %v, i32 1
  %e2 = extractelement <4 x i16> %v, i32 2
  %e3 = extractelement <4 x i16> %v, i32 3
  %z0 = zext i16 %e0 to i32
  %z1 = zext i16 %e1 to i32
  %z2 = zext i16 %e2 to i32
  %z3 = zext i16 %e3 to i32
  %s0 = add i32 %z0, %z1
  %s1 = add i32 %z2, %z3
  %r = xor i32 %s0, %s1
  ret i32 %r
}

define i32 @fold_mem_i16x4(ptr %p) {
entry:
  %v = load <4 x i16>, ptr %p, align 2
  %r = call i32 @fold_i16x4(<4 x i16> %v)
  ret i32 %r
}

define i32 @fold_i64x2(<2 x i64> %v) {
entry:
  %e0 = extractelement <2 x i64> %v, i32 0
  %e1 = extractelement <2 x i64> %v, i32 1
  %x = xor i64 %e0, %e1
  %r = trunc i64 %x to i32
  ret i32 %r
}

define i32 @fold_mem_i64x2(ptr %p) {
entry:
  %v = load <2 x i64>, ptr %p, align 8
  %r = call i32 @fold_i64x2(<2 x i64> %v)
  ret i32 %r
}

define i32 @fold_i1x8(<8 x i1> %v) {
entry:
  %e0 = extractelement <8 x i1> %v, i32 0
  %e1 = extractelement <8 x i1> %v, i32 1
  %e2 = extractelement <8 x i1> %v, i32 4
  %e3 = extractelement <8 x i1> %v, i32 5
  %z0 = zext i1 %e0 to i32
  %z1 = zext i1 %e1 to i32
  %z2 = zext i1 %e2 to i32
  %z3 = zext i1 %e3 to i32
  %s0 = add i32 %z0, %z1
  %s1 = add i32 %z2, %z3
  %r = xor i32 %s0, %s1
  ret i32 %r
}

define i32 @fold_mem_i1bytes(ptr %p) {
entry:
  %b0 = load i8, ptr %p, align 1
  %p1 = getelementptr inbounds i8, ptr %p, i64 1
  %b1 = load i8, ptr %p1, align 1
  %z0 = zext i8 %b0 to i32
  %z1 = zext i8 %b1 to i32
  %r = xor i32 %z0, %z1
  ret i32 %r
}

define i32 @reference_expand(ptr %p, <4 x i32> %passthru) noinline optnone {
entry:
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix = insertelement <4 x i1> %mix0, i1 true, i32 2
  %ld.mix = call <4 x i32> @llvm.masked.expandload.v4i32(ptr %p, <4 x i1> %mix, <4 x i32> %passthru)
  %ld.all = call <4 x i32> @llvm.masked.expandload.v4i32(ptr %p, <4 x i1> <i1 true, i1 true, i1 true, i1 true>, <4 x i32> %passthru)
  %ld.none = call <4 x i32> @llvm.masked.expandload.v4i32(ptr %p, <4 x i1> zeroinitializer, <4 x i32> %passthru)
  %a = call i32 @fold_i32x4(<4 x i32> %ld.mix)
  %b = call i32 @fold_i32x4(<4 x i32> %ld.all)
  %c = call i32 @fold_i32x4(<4 x i32> %ld.none)
  %s0 = xor i32 %a, %b
  %r = xor i32 %s0, %c
  ret i32 %r
}

define i32 @protected_expand(ptr %p, <4 x i32> %passthru) noinline optnone {
entry:
  call void @hikari_vmp()
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix = insertelement <4 x i1> %mix0, i1 true, i32 2
  %ld.mix = call <4 x i32> @llvm.masked.expandload.v4i32(ptr %p, <4 x i1> %mix, <4 x i32> %passthru)
  %ld.all = call <4 x i32> @llvm.masked.expandload.v4i32(ptr %p, <4 x i1> <i1 true, i1 true, i1 true, i1 true>, <4 x i32> %passthru)
  %ld.none = call <4 x i32> @llvm.masked.expandload.v4i32(ptr %p, <4 x i1> zeroinitializer, <4 x i32> %passthru)
  %a = call i32 @fold_i32x4(<4 x i32> %ld.mix)
  %b = call i32 @fold_i32x4(<4 x i32> %ld.all)
  %c = call i32 @fold_i32x4(<4 x i32> %ld.none)
  %s0 = xor i32 %a, %b
  %r = xor i32 %s0, %c
  ret i32 %r
}

define i32 @reference_compress(<4 x i32> %v, ptr %dst) noinline optnone {
entry:
  store <4 x i32> <i32 1, i32 1, i32 1, i32 1>, ptr %dst, align 4
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix = insertelement <4 x i1> %mix0, i1 true, i32 2
  call void @llvm.masked.compressstore.v4i32(<4 x i32> %v, ptr %dst, <4 x i1> %mix)
  %r = call i32 @fold_mem4(ptr %dst)
  ret i32 %r
}

define i32 @protected_compress(<4 x i32> %v, ptr %dst) noinline optnone {
entry:
  call void @hikari_vmp()
  store <4 x i32> <i32 1, i32 1, i32 1, i32 1>, ptr %dst, align 4
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix = insertelement <4 x i1> %mix0, i1 true, i32 2
  call void @llvm.masked.compressstore.v4i32(<4 x i32> %v, ptr %dst, <4 x i1> %mix)
  %r = call i32 @fold_mem4(ptr %dst)
  ret i32 %r
}

define i32 @reference_expand_f32(ptr %p, <4 x float> %passthru) noinline optnone {
entry:
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix = insertelement <4 x i1> %mix0, i1 true, i32 2
  %ld = call <4 x float> @llvm.masked.expandload.v4f32(ptr %p, <4 x i1> %mix, <4 x float> %passthru)
  %bits = bitcast <4 x float> %ld to <4 x i32>
  %r = call i32 @fold_i32x4(<4 x i32> %bits)
  ret i32 %r
}

define i32 @protected_expand_f32(ptr %p, <4 x float> %passthru) noinline optnone {
entry:
  call void @hikari_vmp()
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix = insertelement <4 x i1> %mix0, i1 true, i32 2
  %ld = call <4 x float> @llvm.masked.expandload.v4f32(ptr %p, <4 x i1> %mix, <4 x float> %passthru)
  %bits = bitcast <4 x float> %ld to <4 x i32>
  %r = call i32 @fold_i32x4(<4 x i32> %bits)
  ret i32 %r
}

define i32 @reference_expand_i8(ptr %p, <8 x i8> %passthru) noinline optnone {
entry:
  %m = insertelement <8 x i1> zeroinitializer, i1 true, i32 0
  %m2 = insertelement <8 x i1> %m, i1 true, i32 3
  %ld = call <8 x i8> @llvm.masked.expandload.v8i8(ptr %p, <8 x i1> %m2, <8 x i8> %passthru)
  %r = call i32 @fold_i8x8(<8 x i8> %ld)
  ret i32 %r
}

define i32 @protected_expand_i8(ptr %p, <8 x i8> %passthru) noinline optnone {
entry:
  call void @hikari_vmp()
  %m = insertelement <8 x i1> zeroinitializer, i1 true, i32 0
  %m2 = insertelement <8 x i1> %m, i1 true, i32 3
  %ld = call <8 x i8> @llvm.masked.expandload.v8i8(ptr %p, <8 x i1> %m2, <8 x i8> %passthru)
  %r = call i32 @fold_i8x8(<8 x i8> %ld)
  ret i32 %r
}


define i32 @protected_expand_phi(i1 %c, ptr %p, <4 x i32> %passthru) noinline optnone {
entry:
  call void @hikari_vmp()
  br i1 %c, label %left, label %right

left:
  %l = call <4 x i32> @llvm.masked.expandload.v4i32(ptr %p, <4 x i1> <i1 true, i1 false, i1 true, i1 false>, <4 x i32> %passthru)
  %lz = call i32 @fold_i32x4(<4 x i32> %l)
  br label %done

right:
  %r = call <4 x i32> @llvm.masked.expandload.v4i32(ptr %p, <4 x i1> zeroinitializer, <4 x i32> %passthru)
  %rz = call i32 @fold_i32x4(<4 x i32> %r)
  br label %done

done:
  %pphi = phi i32 [ %lz, %left ], [ %rz, %right ]
  ret i32 %pphi
}

define i32 @protected_expand_loop(ptr %p, <4 x i32> %passthru, i32 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %i2, %loop ]
  %acc = phi i32 [ 0, %entry ], [ %acc2, %loop ]
  %ld = call <4 x i32> @llvm.masked.expandload.v4i32(ptr %p, <4 x i1> <i1 true, i1 false, i1 true, i1 false>, <4 x i32> %passthru)
  %k = call i32 @fold_i32x4(<4 x i32> %ld)
  %acc2 = add i32 %acc, %k
  %i2 = add i32 %i, 1
  %more = icmp slt i32 %i2, %n
  br i1 %more, label %loop, label %done

done:
  ret i32 %acc2
}

define i32 @protected_expand_null_inactive(<4 x i32> %passthru) noinline optnone {
entry:
  call void @hikari_vmp()
  %ld = call <4 x i32> @llvm.masked.expandload.v4i32(ptr null, <4 x i1> zeroinitializer, <4 x i32> %passthru)
  %r = call i32 @fold_i32x4(<4 x i32> %ld)
  ret i32 %r
}

define i32 @reference_expand_i16(ptr %p, <4 x i16> %passthru) noinline optnone {
entry:
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix = insertelement <4 x i1> %mix0, i1 true, i32 2
  %ld = call <4 x i16> @llvm.masked.expandload.v4i16(ptr %p, <4 x i1> %mix, <4 x i16> %passthru)
  %r = call i32 @fold_i16x4(<4 x i16> %ld)
  ret i32 %r
}

define i32 @protected_expand_i16(ptr %p, <4 x i16> %passthru) noinline optnone {
entry:
  call void @hikari_vmp()
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix = insertelement <4 x i1> %mix0, i1 true, i32 2
  %ld = call <4 x i16> @llvm.masked.expandload.v4i16(ptr %p, <4 x i1> %mix, <4 x i16> %passthru)
  %r = call i32 @fold_i16x4(<4 x i16> %ld)
  ret i32 %r
}

define i32 @reference_compress_i16(<4 x i16> %v, ptr %dst) noinline optnone {
entry:
  store <4 x i16> <i16 1, i16 1, i16 1, i16 1>, ptr %dst, align 2
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix = insertelement <4 x i1> %mix0, i1 true, i32 2
  call void @llvm.masked.compressstore.v4i16(<4 x i16> %v, ptr %dst, <4 x i1> %mix)
  %r = call i32 @fold_mem_i16x4(ptr %dst)
  ret i32 %r
}

define i32 @protected_compress_i16(<4 x i16> %v, ptr %dst) noinline optnone {
entry:
  call void @hikari_vmp()
  store <4 x i16> <i16 1, i16 1, i16 1, i16 1>, ptr %dst, align 2
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix = insertelement <4 x i1> %mix0, i1 true, i32 2
  call void @llvm.masked.compressstore.v4i16(<4 x i16> %v, ptr %dst, <4 x i1> %mix)
  %r = call i32 @fold_mem_i16x4(ptr %dst)
  ret i32 %r
}

define i32 @reference_expand_i64(ptr %p, <2 x i64> %passthru) noinline optnone {
entry:
  %mix = insertelement <2 x i1> zeroinitializer, i1 true, i32 0
  %ld = call <2 x i64> @llvm.masked.expandload.v2i64(ptr %p, <2 x i1> %mix, <2 x i64> %passthru)
  %r = call i32 @fold_i64x2(<2 x i64> %ld)
  ret i32 %r
}

define i32 @protected_expand_i64(ptr %p, <2 x i64> %passthru) noinline optnone {
entry:
  call void @hikari_vmp()
  %mix = insertelement <2 x i1> zeroinitializer, i1 true, i32 0
  %ld = call <2 x i64> @llvm.masked.expandload.v2i64(ptr %p, <2 x i1> %mix, <2 x i64> %passthru)
  %r = call i32 @fold_i64x2(<2 x i64> %ld)
  ret i32 %r
}

define i32 @reference_compress_i64(<2 x i64> %v, ptr %dst) noinline optnone {
entry:
  store <2 x i64> <i64 1, i64 1>, ptr %dst, align 8
  %mix = insertelement <2 x i1> zeroinitializer, i1 true, i32 0
  call void @llvm.masked.compressstore.v2i64(<2 x i64> %v, ptr %dst, <2 x i1> %mix)
  %r = call i32 @fold_mem_i64x2(ptr %dst)
  ret i32 %r
}

define i32 @protected_compress_i64(<2 x i64> %v, ptr %dst) noinline optnone {
entry:
  call void @hikari_vmp()
  store <2 x i64> <i64 1, i64 1>, ptr %dst, align 8
  %mix = insertelement <2 x i1> zeroinitializer, i1 true, i32 0
  call void @llvm.masked.compressstore.v2i64(<2 x i64> %v, ptr %dst, <2 x i1> %mix)
  %r = call i32 @fold_mem_i64x2(ptr %dst)
  ret i32 %r
}

define i32 @reference_expand_half(ptr %p, <4 x half> %passthru) noinline optnone {
entry:
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix = insertelement <4 x i1> %mix0, i1 true, i32 2
  %ld = call <4 x half> @llvm.masked.expandload.v4f16(ptr %p, <4 x i1> %mix, <4 x half> %passthru)
  %bits = bitcast <4 x half> %ld to <4 x i16>
  %r = call i32 @fold_i16x4(<4 x i16> %bits)
  ret i32 %r
}

define i32 @protected_expand_half(ptr %p, <4 x half> %passthru) noinline optnone {
entry:
  call void @hikari_vmp()
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix = insertelement <4 x i1> %mix0, i1 true, i32 2
  %ld = call <4 x half> @llvm.masked.expandload.v4f16(ptr %p, <4 x i1> %mix, <4 x half> %passthru)
  %bits = bitcast <4 x half> %ld to <4 x i16>
  %r = call i32 @fold_i16x4(<4 x i16> %bits)
  ret i32 %r
}

define i32 @reference_compress_half(<4 x half> %v, ptr %dst) noinline optnone {
entry:
  store <4 x half> <half 1.000000e+00, half 1.000000e+00, half 1.000000e+00, half 1.000000e+00>, ptr %dst, align 2
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix = insertelement <4 x i1> %mix0, i1 true, i32 2
  call void @llvm.masked.compressstore.v4f16(<4 x half> %v, ptr %dst, <4 x i1> %mix)
  %mem = load <4 x half>, ptr %dst, align 2
  %bits = bitcast <4 x half> %mem to <4 x i16>
  %r = call i32 @fold_i16x4(<4 x i16> %bits)
  ret i32 %r
}

define i32 @protected_compress_half(<4 x half> %v, ptr %dst) noinline optnone {
entry:
  call void @hikari_vmp()
  store <4 x half> <half 1.000000e+00, half 1.000000e+00, half 1.000000e+00, half 1.000000e+00>, ptr %dst, align 2
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix = insertelement <4 x i1> %mix0, i1 true, i32 2
  call void @llvm.masked.compressstore.v4f16(<4 x half> %v, ptr %dst, <4 x i1> %mix)
  %mem = load <4 x half>, ptr %dst, align 2
  %bits = bitcast <4 x half> %mem to <4 x i16>
  %r = call i32 @fold_i16x4(<4 x i16> %bits)
  ret i32 %r
}

define i32 @reference_expand_f64(ptr %p, <2 x double> %passthru) noinline optnone {
entry:
  %mix = insertelement <2 x i1> zeroinitializer, i1 true, i32 0
  %ld = call <2 x double> @llvm.masked.expandload.v2f64(ptr %p, <2 x i1> %mix, <2 x double> %passthru)
  %bits = bitcast <2 x double> %ld to <2 x i64>
  %r = call i32 @fold_i64x2(<2 x i64> %bits)
  ret i32 %r
}

define i32 @protected_expand_f64(ptr %p, <2 x double> %passthru) noinline optnone {
entry:
  call void @hikari_vmp()
  %mix = insertelement <2 x i1> zeroinitializer, i1 true, i32 0
  %ld = call <2 x double> @llvm.masked.expandload.v2f64(ptr %p, <2 x i1> %mix, <2 x double> %passthru)
  %bits = bitcast <2 x double> %ld to <2 x i64>
  %r = call i32 @fold_i64x2(<2 x i64> %bits)
  ret i32 %r
}

define i32 @reference_compress_f64(<2 x double> %v, ptr %dst) noinline optnone {
entry:
  store <2 x double> <double 1.000000e+00, double 1.000000e+00>, ptr %dst, align 8
  %mix = insertelement <2 x i1> zeroinitializer, i1 true, i32 0
  call void @llvm.masked.compressstore.v2f64(<2 x double> %v, ptr %dst, <2 x i1> %mix)
  %mem = load <2 x double>, ptr %dst, align 8
  %bits = bitcast <2 x double> %mem to <2 x i64>
  %r = call i32 @fold_i64x2(<2 x i64> %bits)
  ret i32 %r
}

define i32 @protected_compress_f64(<2 x double> %v, ptr %dst) noinline optnone {
entry:
  call void @hikari_vmp()
  store <2 x double> <double 1.000000e+00, double 1.000000e+00>, ptr %dst, align 8
  %mix = insertelement <2 x i1> zeroinitializer, i1 true, i32 0
  call void @llvm.masked.compressstore.v2f64(<2 x double> %v, ptr %dst, <2 x i1> %mix)
  %mem = load <2 x double>, ptr %dst, align 8
  %bits = bitcast <2 x double> %mem to <2 x i64>
  %r = call i32 @fold_i64x2(<2 x i64> %bits)
  ret i32 %r
}

define i32 @reference_expand_i1(ptr %p, <8 x i1> %passthru) noinline optnone {
entry:
  %m = insertelement <8 x i1> zeroinitializer, i1 true, i32 0
  %m2 = insertelement <8 x i1> %m, i1 true, i32 3
  %ld = call <8 x i1> @llvm.masked.expandload.v8i1(ptr %p, <8 x i1> %m2, <8 x i1> %passthru)
  %r = call i32 @fold_i1x8(<8 x i1> %ld)
  ret i32 %r
}

define i32 @protected_expand_i1(ptr %p, <8 x i1> %passthru) noinline optnone {
entry:
  call void @hikari_vmp()
  %m = insertelement <8 x i1> zeroinitializer, i1 true, i32 0
  %m2 = insertelement <8 x i1> %m, i1 true, i32 3
  %ld = call <8 x i1> @llvm.masked.expandload.v8i1(ptr %p, <8 x i1> %m2, <8 x i1> %passthru)
  %r = call i32 @fold_i1x8(<8 x i1> %ld)
  ret i32 %r
}

define i32 @reference_compress_i1(<8 x i1> %v, ptr %dst) noinline optnone {
entry:
  store <8 x i8> <i8 9, i8 9, i8 9, i8 9, i8 9, i8 9, i8 9, i8 9>, ptr %dst, align 1
  %m = insertelement <8 x i1> zeroinitializer, i1 true, i32 0
  %m2 = insertelement <8 x i1> %m, i1 true, i32 3
  call void @llvm.masked.compressstore.v8i1(<8 x i1> %v, ptr %dst, <8 x i1> %m2)
  %r = call i32 @fold_mem_i1bytes(ptr %dst)
  ret i32 %r
}

define i32 @protected_compress_i1(<8 x i1> %v, ptr %dst) noinline optnone {
entry:
  call void @hikari_vmp()
  store <8 x i8> <i8 9, i8 9, i8 9, i8 9, i8 9, i8 9, i8 9, i8 9>, ptr %dst, align 1
  %m = insertelement <8 x i1> zeroinitializer, i1 true, i32 0
  %m2 = insertelement <8 x i1> %m, i1 true, i32 3
  call void @llvm.masked.compressstore.v8i1(<8 x i1> %v, ptr %dst, <8 x i1> %m2)
  %r = call i32 @fold_mem_i1bytes(ptr %dst)
  ret i32 %r
}

define i32 @sink_i32(ptr %p, i32 %x) {
entry:
  ret i32 %x
}

define i32 @unsupported_expand_gather(<4 x i1> %m, <4 x i32> %t) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> poison, i32 4, <4 x i1> %m, <4 x i32> %t)
  %e = extractelement <4 x i32> %r, i32 0
  ret i32 %e
}

define i32 @unsupported_expand_wide(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i32> @llvm.masked.expandload.v8i32(ptr %p, <8 x i1> zeroinitializer, <8 x i32> zeroinitializer)
  %e = extractelement <8 x i32> %r, i32 0
  ret i32 %e
}

define i32 @unsupported_expand_musttail(ptr %p, i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %pt = insertelement <4 x i32> zeroinitializer, i32 %x, i32 0
  %ld = call <4 x i32> @llvm.masked.expandload.v4i32(ptr %p, <4 x i1> zeroinitializer, <4 x i32> %pt)
  %e = extractelement <4 x i32> %ld, i32 0
  %r = musttail call i32 @sink_i32(ptr %p, i32 %e)
  ret i32 %r
}

define i32 @unsupported_expand_poison(ptr %p, <4 x i1> %m) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.masked.expandload.v4i32(ptr %p, <4 x i1> %m, <4 x i32> poison)
  %e = extractelement <4 x i32> %r, i32 0
  ret i32 %e
}

define i32 @main() {
entry:
  %d0 = alloca [4 x i32], align 16
  %d1 = alloca [4 x i32], align 16
  %d16r = alloca [4 x i16], align 8
  %d16p = alloca [4 x i16], align 8
  %d64r = alloca [2 x i64], align 16
  %d64p = alloca [2 x i64], align 16
  %dhr = alloca [4 x half], align 8
  %dhp = alloca [4 x half], align 8
  %dfr = alloca [2 x double], align 16
  %dfp = alloca [2 x double], align 16
  %d1r = alloca [8 x i8], align 8
  %d1p = alloca [8 x i8], align 8
  %pt0 = insertelement <4 x i32> undef, i32 1, i32 0
  %pt1 = insertelement <4 x i32> %pt0, i32 2, i32 1
  %pt2 = insertelement <4 x i32> %pt1, i32 3, i32 2
  %pt3 = insertelement <4 x i32> %pt2, i32 4, i32 3
  %sv0 = insertelement <4 x i32> undef, i32 9, i32 0
  %sv1 = insertelement <4 x i32> %sv0, i32 8, i32 1
  %sv2 = insertelement <4 x i32> %sv1, i32 7, i32 2
  %sv3 = insertelement <4 x i32> %sv2, i32 6, i32 3
  %i8p0 = insertelement <8 x i8> undef, i8 9, i32 0
  %i8p1 = insertelement <8 x i8> %i8p0, i8 8, i32 1
  %i8p2 = insertelement <8 x i8> %i8p1, i8 7, i32 2
  %i8p3 = insertelement <8 x i8> %i8p2, i8 6, i32 3
  %i8p4 = insertelement <8 x i8> %i8p3, i8 5, i32 4
  %i8p5 = insertelement <8 x i8> %i8p4, i8 4, i32 5
  %i8p6 = insertelement <8 x i8> %i8p5, i8 3, i32 6
  %i8p7 = insertelement <8 x i8> %i8p6, i8 2, i32 7
  %fpt = sitofp <4 x i32> %pt3 to <4 x float>
  %i16pt = trunc <4 x i32> %pt3 to <4 x i16>
  %i16sv = trunc <4 x i32> %sv3 to <4 x i16>
  %i64p0 = insertelement <2 x i64> undef, i64 1, i32 0
  %i64pt = insertelement <2 x i64> %i64p0, i64 2, i32 1
  %i64s0 = insertelement <2 x i64> undef, i64 9, i32 0
  %i64sv = insertelement <2 x i64> %i64s0, i64 8, i32 1
  %hpt = sitofp <4 x i32> %pt3 to <4 x half>
  %hsv = sitofp <4 x i32> %sv3 to <4 x half>
  %f64pt = sitofp <2 x i64> %i64pt to <2 x double>
  %f64sv = sitofp <2 x i64> %i64sv to <2 x double>
  %i1p0 = insertelement <8 x i1> undef, i1 true, i32 0
  %i1p1 = insertelement <8 x i1> %i1p0, i1 false, i32 1
  %i1p2 = insertelement <8 x i1> %i1p1, i1 true, i32 2
  %i1p3 = insertelement <8 x i1> %i1p2, i1 false, i32 3
  %i1p4 = insertelement <8 x i1> %i1p3, i1 true, i32 4
  %i1p5 = insertelement <8 x i1> %i1p4, i1 false, i32 5
  %i1p6 = insertelement <8 x i1> %i1p5, i1 true, i32 6
  %i1pt = insertelement <8 x i1> %i1p6, i1 false, i32 7

  %e0 = call i32 @reference_expand(ptr @src.i32, <4 x i32> %pt3)
  %a0 = call i32 @protected_expand(ptr @src.i32, <4 x i32> %pt3)
  %e1 = call i32 @reference_compress(<4 x i32> %sv3, ptr %d0)
  %a1 = call i32 @protected_compress(<4 x i32> %sv3, ptr %d1)
  %e2 = call i32 @reference_expand_f32(ptr @src.f32, <4 x float> %fpt)
  %a2 = call i32 @protected_expand_f32(ptr @src.f32, <4 x float> %fpt)
  %e3 = call i32 @reference_expand_i8(ptr @src.i8, <8 x i8> %i8p7)
  %a3 = call i32 @protected_expand_i8(ptr @src.i8, <8 x i8> %i8p7)
  %e5 = call i32 @protected_expand_phi(i1 true, ptr @src.i32, <4 x i32> %pt3)
  %e5r = call <4 x i32> @llvm.masked.expandload.v4i32(ptr @src.i32, <4 x i1> <i1 true, i1 false, i1 true, i1 false>, <4 x i32> %pt3)
  %e5x = call i32 @fold_i32x4(<4 x i32> %e5r)
  %e6 = call i32 @protected_expand_phi(i1 false, ptr @src.i32, <4 x i32> %pt3)
  %e6x = call i32 @fold_i32x4(<4 x i32> %pt3)
  %e7 = call i32 @protected_expand_loop(ptr @src.i32, <4 x i32> %pt3, i32 3)
  %e7x = mul i32 %e5x, 3
  %e8 = call i32 @protected_expand_null_inactive(<4 x i32> %pt3)
  %e8x = call i32 @fold_i32x4(<4 x i32> %pt3)
  %e9 = call i32 @reference_expand_i16(ptr @src.i16, <4 x i16> %i16pt)
  %a9 = call i32 @protected_expand_i16(ptr @src.i16, <4 x i16> %i16pt)
  %e10 = call i32 @reference_compress_i16(<4 x i16> %i16sv, ptr %d16r)
  %a10 = call i32 @protected_compress_i16(<4 x i16> %i16sv, ptr %d16p)
  %e11 = call i32 @reference_expand_i64(ptr @src.i64, <2 x i64> %i64pt)
  %a11 = call i32 @protected_expand_i64(ptr @src.i64, <2 x i64> %i64pt)
  %e12 = call i32 @reference_compress_i64(<2 x i64> %i64sv, ptr %d64r)
  %a12 = call i32 @protected_compress_i64(<2 x i64> %i64sv, ptr %d64p)
  %e13 = call i32 @reference_expand_half(ptr @src.half, <4 x half> %hpt)
  %a13 = call i32 @protected_expand_half(ptr @src.half, <4 x half> %hpt)
  %e14 = call i32 @reference_compress_half(<4 x half> %hsv, ptr %dhr)
  %a14 = call i32 @protected_compress_half(<4 x half> %hsv, ptr %dhp)
  %e15 = call i32 @reference_expand_f64(ptr @src.f64, <2 x double> %f64pt)
  %a15 = call i32 @protected_expand_f64(ptr @src.f64, <2 x double> %f64pt)
  %e16 = call i32 @reference_compress_f64(<2 x double> %f64sv, ptr %dfr)
  %a16 = call i32 @protected_compress_f64(<2 x double> %f64sv, ptr %dfp)
  %e17 = call i32 @reference_expand_i1(ptr @src.i1, <8 x i1> %i1pt)
  %a17 = call i32 @protected_expand_i1(ptr @src.i1, <8 x i1> %i1pt)
  %e18 = call i32 @reference_compress_i1(<8 x i1> %i1pt, ptr %d1r)
  %a18 = call i32 @protected_compress_i1(<8 x i1> %i1pt, ptr %d1p)
  %sn = load i32, ptr @sentinel, align 4
  %oksn = icmp eq i32 %sn, 291

  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %e1, %a1
  %m2 = icmp eq i32 %e2, %a2
  %m3 = icmp eq i32 %e3, %a3
  %m5 = icmp eq i32 %e5, %e5x
  %m6 = icmp eq i32 %e6, %e6x
  %m7 = icmp eq i32 %e7, %e7x
  %m8 = icmp eq i32 %e8, %e8x
  %m9 = icmp eq i32 %e9, %a9
  %m10 = icmp eq i32 %e10, %a10
  %m11 = icmp eq i32 %e11, %a11
  %m12 = icmp eq i32 %e12, %a12
  %m13 = icmp eq i32 %e13, %a13
  %m14 = icmp eq i32 %e14, %a14
  %m15 = icmp eq i32 %e15, %a15
  %m16 = icmp eq i32 %e16, %a16
  %m17 = icmp eq i32 %e17, %a17
  %m18 = icmp eq i32 %e18, %a18
  %t0 = and i1 %m0, %m1
  %t1 = and i1 %m2, %m3
  %t2 = and i1 %m5, %m5
  %t3 = and i1 %m6, %m7
  %t4 = and i1 %m8, %m9
  %t5 = and i1 %m10, %m11
  %t6 = and i1 %m12, %m13
  %t7 = and i1 %m14, %m15
  %t8 = and i1 %m16, %m17
  %ok0 = and i1 %t0, %t1
  %ok1 = and i1 %t2, %t3
  %ok2 = and i1 %t4, %t5
  %ok3 = and i1 %t6, %t7
  %ok4 = and i1 %t8, %m18
  %ok5 = and i1 %ok0, %ok1
  %ok6 = and i1 %ok2, %ok3
  %ok7 = and i1 %ok4, %oksn
  %ok8 = and i1 %ok5, %ok6
  %ok = and i1 %ok8, %ok7
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_expand_gather: unsupported masked memory instruction
; SKIP-DAG: Skipping VMP on unsupported_expand_wide: unsupported masked memory instruction
; SKIP-DAG: Skipping VMP on unsupported_expand_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_expand_poison: unsupported masked memory instruction
; SKIP-NOT: Skipping VMP on protected_expand:
; SKIP-NOT: Skipping VMP on protected_compress:
; SKIP-NOT: Skipping VMP on protected_expand_f32:
; SKIP-NOT: Skipping VMP on protected_expand_i8:
; SKIP-NOT: Skipping VMP on protected_expand_i16:
; SKIP-NOT: Skipping VMP on protected_compress_i16:
; SKIP-NOT: Skipping VMP on protected_expand_i64:
; SKIP-NOT: Skipping VMP on protected_compress_i64:
; SKIP-NOT: Skipping VMP on protected_expand_half:
; SKIP-NOT: Skipping VMP on protected_compress_half:
; SKIP-NOT: Skipping VMP on protected_expand_f64:
; SKIP-NOT: Skipping VMP on protected_compress_f64:
; SKIP-NOT: Skipping VMP on protected_expand_i1:
; SKIP-NOT: Skipping VMP on protected_compress_i1:
; SKIP-NOT: Skipping VMP on protected_expand_phi:
; SKIP-NOT: Skipping VMP on protected_expand_loop:
; SKIP-NOT: Skipping VMP on protected_expand_null_inactive:

; VIRT: define i32 @protected_expand({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.masked.expandload.v4i32(
; VIRT: define i32 @protected_compress({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.masked.compressstore.v4i32(
; VIRT: define i32 @protected_expand_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x float> @llvm.masked.expandload.v4f32(
; VIRT: define i32 @protected_expand_i8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x i8> @llvm.masked.expandload.v8i8(
; VIRT: define i32 @protected_expand_phi({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.masked.expandload.v4i32(
; VIRT: define i32 @protected_expand_loop({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.masked.expandload.v4i32(
; VIRT: define i32 @protected_expand_null_inactive({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.masked.expandload.v4i32(ptr {{.*}}, <4 x i1> {{.*}}, <4 x i32> {{.*}})
; VIRT: define i32 @protected_expand_i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i16> @llvm.masked.expandload.v4i16(
; VIRT: define i32 @protected_compress_i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.masked.compressstore.v4i16(
; VIRT: define i32 @protected_expand_i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i64> @llvm.masked.expandload.v2i64(
; VIRT: define i32 @protected_compress_i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.masked.compressstore.v2i64(
; VIRT: define i32 @protected_expand_half({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x half> @llvm.masked.expandload.v4f16(
; VIRT: define i32 @protected_compress_half({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.masked.compressstore.v4f16(
; VIRT: define i32 @protected_expand_f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x double> @llvm.masked.expandload.v2f64(
; VIRT: define i32 @protected_compress_f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.masked.compressstore.v2f64(
; VIRT: define i32 @protected_expand_i1({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x i1> @llvm.masked.expandload.v8i1(
; VIRT: define i32 @protected_compress_i1({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.masked.compressstore.v8i1(
; VIRT: define i32 @unsupported_expand_gather({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define i32 @unsupported_expand_wide({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define i32 @unsupported_expand_musttail({{.*}} #[[UNSUP_MT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call i32 @sink_i32(
; VIRT: define i32 @unsupported_expand_poison({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"
; VIRT-NOT: attributes #[[UNSUP_MT]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
