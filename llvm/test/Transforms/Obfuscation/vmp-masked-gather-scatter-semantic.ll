; Restricted llvm.masked.gather / llvm.masked.scatter.
; Data is a supported fixed 1..128 vector with N<=8 lanes.  Live
; gather and scatter cover every accepted element type:
; i1 / i8 / i16 / i32 / i64 / half / f32 / f64.  Pointers are a matching
; <N x ptr> AS0 with N in 1..8, held in a dedicated [8 x ptr]
; pointer-vector VReg (not a general pointer-vector ABI, not [8 x i64]).
; Slot packing copies pointer values so LLVM provenance is preserved;
; the interpreter must not ptrtoint/inttoptr the address vector.
; Addresses come from a scalar-base vector GEP (one integer-vector
; index, that plus a ConstantInt AoS struct field or in-range
; array element, the 3-index Wrap form, or the clang AoS form
; getelementptr [4 x %Pair], ptr, i32 0 / i64 0, <4 x i32>, i32 1;
; a non-zero or dynamic leading index is rejected), a pointer-vector
; constant, or insertelement of scalar AS0 pointers.  Live pointer-vector
; SSA also covers extractelement, scalar/mask select, diamond phi, and
; a backedge phi (PointerVectorExtractElement / Select / Move).
; Alignment is an i32 ImmArg.  Replayed via CallDescriptor.  Scalable /
; non-zero AS / N>8 / function-arg pointer vectors / poison stay rejected.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP-O0 < %t.o0.err
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
; RUN: FileCheck %s --check-prefix=SKIP-O0 < %t.o0.s7.err
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
declare <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr>, i32, <4 x i1>, <4 x i32>)
declare void @llvm.masked.scatter.v4i32.v4p0(<4 x i32>, <4 x ptr>, i32, <4 x i1>)
declare <4 x float> @llvm.masked.gather.v4f32.v4p0(<4 x ptr>, i32, <4 x i1>, <4 x float>)
declare void @llvm.masked.scatter.v4f32.v4p0(<4 x float>, <4 x ptr>, i32, <4 x i1>)
declare <8 x i8> @llvm.masked.gather.v8i8.v8p0(<8 x ptr>, i32, <8 x i1>, <8 x i8>)
declare void @llvm.masked.scatter.v8i8.v8p0(<8 x i8>, <8 x ptr>, i32, <8 x i1>)
declare <4 x i16> @llvm.masked.gather.v4i16.v4p0(<4 x ptr>, i32, <4 x i1>, <4 x i16>)
declare void @llvm.masked.scatter.v4i16.v4p0(<4 x i16>, <4 x ptr>, i32, <4 x i1>)
declare <4 x half> @llvm.masked.gather.v4f16.v4p0(<4 x ptr>, i32, <4 x i1>, <4 x half>)
declare void @llvm.masked.scatter.v4f16.v4p0(<4 x half>, <4 x ptr>, i32, <4 x i1>)
declare <2 x i64> @llvm.masked.gather.v2i64.v2p0(<2 x ptr>, i32, <2 x i1>, <2 x i64>)
declare void @llvm.masked.scatter.v2i64.v2p0(<2 x i64>, <2 x ptr>, i32, <2 x i1>)
declare <2 x double> @llvm.masked.gather.v2f64.v2p0(<2 x ptr>, i32, <2 x i1>, <2 x double>)
declare void @llvm.masked.scatter.v2f64.v2p0(<2 x double>, <2 x ptr>, i32, <2 x i1>)
declare <8 x i1> @llvm.masked.gather.v8i1.v8p0(<8 x ptr>, i32, <8 x i1>, <8 x i1>)
declare void @llvm.masked.scatter.v8i1.v8p0(<8 x i1>, <8 x ptr>, i32, <8 x i1>)
declare <vscale x 4 x i32> @llvm.masked.gather.nxv4i32.nxv4p0(<vscale x 4 x ptr>, i32, <vscale x 4 x i1>, <vscale x 4 x i32>)
declare <4 x i32> @llvm.masked.gather.v4i32.v4p1(<4 x ptr addrspace(1)>, i32, <4 x i1>, <4 x i32>)
declare <16 x i8> @llvm.masked.gather.v16i8.v16p0(<16 x ptr>, i32, <16 x i1>, <16 x i8>)
declare <8 x i32> @llvm.masked.gather.v8i32.v8p0(<8 x ptr>, i32, <8 x i1>, <8 x i32>)

@src.i32 = private global [8 x i32] [i32 10, i32 20, i32 30, i32 40, i32 50, i32 60, i32 70, i32 80], align 16
@src.f32 = private global [4 x float] [float 1.000000e+00, float 2.000000e+00, float 3.000000e+00, float 4.000000e+00], align 16
@src.i8 = private global [8 x i8] [i8 1, i8 2, i8 3, i8 4, i8 5, i8 6, i8 7, i8 8], align 8
@src.half = private global [4 x half] [half 1.000000e+00, half 2.000000e+00, half 3.000000e+00, half 4.000000e+00], align 8
@src.i64 = private global [2 x i64] [i64 10, i64 20], align 16
@src.i16 = private global [4 x i16] [i16 10, i16 20, i16 30, i16 40], align 8
@src.f64 = private global [2 x double] [double 1.000000e+00, double 2.000000e+00], align 16
@src.i1 = private global [8 x i8] [i8 1, i8 0, i8 1, i8 0, i8 1, i8 0, i8 1, i8 0], align 8
@sentinel = private global i32 291, align 4

%Pair = type { i32, i32 }
%Wrap = type { [2 x i32] }
%Deep = type { %Wrap }
@src.pair = private global [4 x %Pair] [
  %Pair { i32 10, i32 11 },
  %Pair { i32 20, i32 21 },
  %Pair { i32 30, i32 31 },
  %Pair { i32 40, i32 41 }
], align 16
@src.rows = private global [4 x [2 x i32]] [
  [2 x i32] [i32 10, i32 11],
  [2 x i32] [i32 20, i32 21],
  [2 x i32] [i32 30, i32 31],
  [2 x i32] [i32 40, i32 41]
], align 16
@src.wrap = private global [4 x %Wrap] [
  %Wrap { [2 x i32] [i32 10, i32 11] },
  %Wrap { [2 x i32] [i32 20, i32 21] },
  %Wrap { [2 x i32] [i32 30, i32 31] },
  %Wrap { [2 x i32] [i32 40, i32 41] }
], align 16

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

define i32 @fold_i64x2(<2 x i64> %v) {
entry:
  %e0 = extractelement <2 x i64> %v, i32 0
  %e1 = extractelement <2 x i64> %v, i32 1
  %x = xor i64 %e0, %e1
  %r = trunc i64 %x to i32
  ret i32 %r
}

define i32 @fold_mem_i16x4(ptr %p) {
entry:
  %v = load <4 x i16>, ptr %p, align 2
  %r = call i32 @fold_i16x4(<4 x i16> %v)
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
  %e2 = extractelement <8 x i1> %v, i32 3
  %z0 = zext i1 %e0 to i32
  %z1 = zext i1 %e1 to i32
  %z2 = zext i1 %e2 to i32
  %s0 = add i32 %z0, %z1
  %r = xor i32 %s0, %z2
  ret i32 %r
}

define i32 @fold_mem_i1bytes(ptr %p) {
entry:
  %b0 = load i8, ptr %p, align 1
  %p1 = getelementptr inbounds i8, ptr %p, i64 1
  %b1 = load i8, ptr %p1, align 1
  %p3 = getelementptr inbounds i8, ptr %p, i64 3
  %b3 = load i8, ptr %p3, align 1
  %z0 = zext i8 %b0 to i32
  %z1 = zext i8 %b1 to i32
  %z3 = zext i8 %b3 to i32
  %s0 = add i32 %z0, %z1
  %r = xor i32 %s0, %z3
  ret i32 %r
}

define i32 @reference_gather(ptr %base, <4 x i32> %passthru) noinline optnone {
entry:
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix = insertelement <4 x i1> %mix0, i1 true, i32 2
  %idx = insertelement <4 x i32> zeroinitializer, i32 1, i32 0
  %idx2 = insertelement <4 x i32> %idx, i32 3, i32 2
  %ptrs = getelementptr i32, ptr %base, <4 x i32> %idx2
  %ld.mix = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> %ptrs, i32 4, <4 x i1> %mix, <4 x i32> %passthru)
  %ptrs.all = getelementptr i32, ptr %base, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  %ld.all = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> %ptrs.all, i32 4, <4 x i1> <i1 true, i1 true, i1 true, i1 true>, <4 x i32> %passthru)
  %ld.none = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> zeroinitializer, i32 4, <4 x i1> zeroinitializer, <4 x i32> %passthru)
  %a = call i32 @fold_i32x4(<4 x i32> %ld.mix)
  %b = call i32 @fold_i32x4(<4 x i32> %ld.all)
  %c = call i32 @fold_i32x4(<4 x i32> %ld.none)
  %s0 = xor i32 %a, %b
  %r = xor i32 %s0, %c
  ret i32 %r
}

define i32 @protected_gather(ptr %base, <4 x i32> %passthru) noinline optnone {
entry:
  call void @hikari_vmp()
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix = insertelement <4 x i1> %mix0, i1 true, i32 2
  %idx = insertelement <4 x i32> zeroinitializer, i32 1, i32 0
  %idx2 = insertelement <4 x i32> %idx, i32 3, i32 2
  %ptrs = getelementptr i32, ptr %base, <4 x i32> %idx2
  %ld.mix = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> %ptrs, i32 4, <4 x i1> %mix, <4 x i32> %passthru)
  %ptrs.all = getelementptr i32, ptr %base, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  %ld.all = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> %ptrs.all, i32 4, <4 x i1> <i1 true, i1 true, i1 true, i1 true>, <4 x i32> %passthru)
  %ld.none = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> zeroinitializer, i32 4, <4 x i1> zeroinitializer, <4 x i32> %passthru)
  %a = call i32 @fold_i32x4(<4 x i32> %ld.mix)
  %b = call i32 @fold_i32x4(<4 x i32> %ld.all)
  %c = call i32 @fold_i32x4(<4 x i32> %ld.none)
  %s0 = xor i32 %a, %b
  %r = xor i32 %s0, %c
  ret i32 %r
}

define i32 @reference_scatter(<4 x i32> %v, ptr %base) noinline optnone {
entry:
  store <4 x i32> <i32 1, i32 1, i32 1, i32 1>, ptr %base, align 4
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix = insertelement <4 x i1> %mix0, i1 true, i32 2
  %idx = insertelement <4 x i32> zeroinitializer, i32 0, i32 0
  %idx2 = insertelement <4 x i32> %idx, i32 2, i32 2
  %ptrs = getelementptr i32, ptr %base, <4 x i32> %idx2
  call void @llvm.masked.scatter.v4i32.v4p0(<4 x i32> %v, <4 x ptr> %ptrs, i32 4, <4 x i1> %mix)
  %r = call i32 @fold_mem4(ptr %base)
  ret i32 %r
}

define i32 @protected_scatter(<4 x i32> %v, ptr %base) noinline optnone {
entry:
  call void @hikari_vmp()
  store <4 x i32> <i32 1, i32 1, i32 1, i32 1>, ptr %base, align 4
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix = insertelement <4 x i1> %mix0, i1 true, i32 2
  %idx = insertelement <4 x i32> zeroinitializer, i32 0, i32 0
  %idx2 = insertelement <4 x i32> %idx, i32 2, i32 2
  %ptrs = getelementptr i32, ptr %base, <4 x i32> %idx2
  call void @llvm.masked.scatter.v4i32.v4p0(<4 x i32> %v, <4 x ptr> %ptrs, i32 4, <4 x i1> %mix)
  %r = call i32 @fold_mem4(ptr %base)
  ret i32 %r
}

define i32 @reference_gather_f32(ptr %base, <4 x float> %passthru) noinline optnone {
entry:
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix = insertelement <4 x i1> %mix0, i1 true, i32 2
  %ptrs = getelementptr float, ptr %base, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  %ld = call <4 x float> @llvm.masked.gather.v4f32.v4p0(<4 x ptr> %ptrs, i32 4, <4 x i1> %mix, <4 x float> %passthru)
  %bits = bitcast <4 x float> %ld to <4 x i32>
  %r = call i32 @fold_i32x4(<4 x i32> %bits)
  ret i32 %r
}

define i32 @protected_gather_f32(ptr %base, <4 x float> %passthru) noinline optnone {
entry:
  call void @hikari_vmp()
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix = insertelement <4 x i1> %mix0, i1 true, i32 2
  %ptrs = getelementptr float, ptr %base, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  %ld = call <4 x float> @llvm.masked.gather.v4f32.v4p0(<4 x ptr> %ptrs, i32 4, <4 x i1> %mix, <4 x float> %passthru)
  %bits = bitcast <4 x float> %ld to <4 x i32>
  %r = call i32 @fold_i32x4(<4 x i32> %bits)
  ret i32 %r
}

define i32 @reference_gather_i8(ptr %base, <8 x i8> %passthru) noinline optnone {
entry:
  %m = insertelement <8 x i1> zeroinitializer, i1 true, i32 0
  %m2 = insertelement <8 x i1> %m, i1 true, i32 3
  %ptrs = getelementptr i8, ptr %base, <8 x i8> <i8 0, i8 1, i8 2, i8 3, i8 4, i8 5, i8 6, i8 7>
  %ld = call <8 x i8> @llvm.masked.gather.v8i8.v8p0(<8 x ptr> %ptrs, i32 1, <8 x i1> %m2, <8 x i8> %passthru)
  %r = call i32 @fold_i8x8(<8 x i8> %ld)
  ret i32 %r
}

define i32 @protected_gather_i8(ptr %base, <8 x i8> %passthru) noinline optnone {
entry:
  call void @hikari_vmp()
  %m = insertelement <8 x i1> zeroinitializer, i1 true, i32 0
  %m2 = insertelement <8 x i1> %m, i1 true, i32 3
  %ptrs = getelementptr i8, ptr %base, <8 x i8> <i8 0, i8 1, i8 2, i8 3, i8 4, i8 5, i8 6, i8 7>
  %ld = call <8 x i8> @llvm.masked.gather.v8i8.v8p0(<8 x ptr> %ptrs, i32 1, <8 x i1> %m2, <8 x i8> %passthru)
  %r = call i32 @fold_i8x8(<8 x i8> %ld)
  ret i32 %r
}

define i32 @reference_gather_half(ptr %base, <4 x half> %passthru) noinline optnone {
entry:
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix = insertelement <4 x i1> %mix0, i1 true, i32 2
  %ptrs = getelementptr half, ptr %base, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  %ld = call <4 x half> @llvm.masked.gather.v4f16.v4p0(<4 x ptr> %ptrs, i32 2, <4 x i1> %mix, <4 x half> %passthru)
  %bits = bitcast <4 x half> %ld to <4 x i16>
  %r = call i32 @fold_i16x4(<4 x i16> %bits)
  ret i32 %r
}

define i32 @protected_gather_half(ptr %base, <4 x half> %passthru) noinline optnone {
entry:
  call void @hikari_vmp()
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix = insertelement <4 x i1> %mix0, i1 true, i32 2
  %ptrs = getelementptr half, ptr %base, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  %ld = call <4 x half> @llvm.masked.gather.v4f16.v4p0(<4 x ptr> %ptrs, i32 2, <4 x i1> %mix, <4 x half> %passthru)
  %bits = bitcast <4 x half> %ld to <4 x i16>
  %r = call i32 @fold_i16x4(<4 x i16> %bits)
  ret i32 %r
}

define i32 @reference_gather_i64(ptr %base, <2 x i64> %passthru) noinline optnone {
entry:
  %mix = insertelement <2 x i1> zeroinitializer, i1 true, i32 0
  %ptrs = getelementptr i64, ptr %base, <2 x i32> <i32 0, i32 1>
  %ld = call <2 x i64> @llvm.masked.gather.v2i64.v2p0(<2 x ptr> %ptrs, i32 8, <2 x i1> %mix, <2 x i64> %passthru)
  %r = call i32 @fold_i64x2(<2 x i64> %ld)
  ret i32 %r
}

define i32 @protected_gather_i64(ptr %base, <2 x i64> %passthru) noinline optnone {
entry:
  call void @hikari_vmp()
  %mix = insertelement <2 x i1> zeroinitializer, i1 true, i32 0
  %ptrs = getelementptr i64, ptr %base, <2 x i32> <i32 0, i32 1>
  %ld = call <2 x i64> @llvm.masked.gather.v2i64.v2p0(<2 x ptr> %ptrs, i32 8, <2 x i1> %mix, <2 x i64> %passthru)
  %r = call i32 @fold_i64x2(<2 x i64> %ld)
  ret i32 %r
}

define i32 @reference_gather_i16(ptr %base, <4 x i16> %passthru) noinline optnone {
entry:
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix = insertelement <4 x i1> %mix0, i1 true, i32 2
  %ptrs = getelementptr i16, ptr %base, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  %ld = call <4 x i16> @llvm.masked.gather.v4i16.v4p0(<4 x ptr> %ptrs, i32 2, <4 x i1> %mix, <4 x i16> %passthru)
  %r = call i32 @fold_i16x4(<4 x i16> %ld)
  ret i32 %r
}

define i32 @protected_gather_i16(ptr %base, <4 x i16> %passthru) noinline optnone {
entry:
  call void @hikari_vmp()
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix = insertelement <4 x i1> %mix0, i1 true, i32 2
  %ptrs = getelementptr i16, ptr %base, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  %ld = call <4 x i16> @llvm.masked.gather.v4i16.v4p0(<4 x ptr> %ptrs, i32 2, <4 x i1> %mix, <4 x i16> %passthru)
  %r = call i32 @fold_i16x4(<4 x i16> %ld)
  ret i32 %r
}

define i32 @reference_scatter_i16(<4 x i16> %v, ptr %base) noinline optnone {
entry:
  store <4 x i16> <i16 1, i16 1, i16 1, i16 1>, ptr %base, align 2
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix = insertelement <4 x i1> %mix0, i1 true, i32 2
  %ptrs = getelementptr i16, ptr %base, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  call void @llvm.masked.scatter.v4i16.v4p0(<4 x i16> %v, <4 x ptr> %ptrs, i32 2, <4 x i1> %mix)
  %r = call i32 @fold_mem_i16x4(ptr %base)
  ret i32 %r
}

define i32 @protected_scatter_i16(<4 x i16> %v, ptr %base) noinline optnone {
entry:
  call void @hikari_vmp()
  store <4 x i16> <i16 1, i16 1, i16 1, i16 1>, ptr %base, align 2
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix = insertelement <4 x i1> %mix0, i1 true, i32 2
  %ptrs = getelementptr i16, ptr %base, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  call void @llvm.masked.scatter.v4i16.v4p0(<4 x i16> %v, <4 x ptr> %ptrs, i32 2, <4 x i1> %mix)
  %r = call i32 @fold_mem_i16x4(ptr %base)
  ret i32 %r
}

define i32 @reference_gather_f64(ptr %base, <2 x double> %passthru) noinline optnone {
entry:
  %mix = insertelement <2 x i1> zeroinitializer, i1 true, i32 0
  %ptrs = getelementptr double, ptr %base, <2 x i32> <i32 0, i32 1>
  %ld = call <2 x double> @llvm.masked.gather.v2f64.v2p0(<2 x ptr> %ptrs, i32 8, <2 x i1> %mix, <2 x double> %passthru)
  %bits = bitcast <2 x double> %ld to <2 x i64>
  %r = call i32 @fold_i64x2(<2 x i64> %bits)
  ret i32 %r
}

define i32 @protected_gather_f64(ptr %base, <2 x double> %passthru) noinline optnone {
entry:
  call void @hikari_vmp()
  %mix = insertelement <2 x i1> zeroinitializer, i1 true, i32 0
  %ptrs = getelementptr double, ptr %base, <2 x i32> <i32 0, i32 1>
  %ld = call <2 x double> @llvm.masked.gather.v2f64.v2p0(<2 x ptr> %ptrs, i32 8, <2 x i1> %mix, <2 x double> %passthru)
  %bits = bitcast <2 x double> %ld to <2 x i64>
  %r = call i32 @fold_i64x2(<2 x i64> %bits)
  ret i32 %r
}

define i32 @reference_scatter_f64(<2 x double> %v, ptr %base) noinline optnone {
entry:
  store <2 x double> <double 1.000000e+00, double 1.000000e+00>, ptr %base, align 8
  %mix = insertelement <2 x i1> zeroinitializer, i1 true, i32 0
  %ptrs = getelementptr double, ptr %base, <2 x i32> <i32 0, i32 1>
  call void @llvm.masked.scatter.v2f64.v2p0(<2 x double> %v, <2 x ptr> %ptrs, i32 8, <2 x i1> %mix)
  %mem = load <2 x double>, ptr %base, align 8
  %bits = bitcast <2 x double> %mem to <2 x i64>
  %r = call i32 @fold_i64x2(<2 x i64> %bits)
  ret i32 %r
}

define i32 @protected_scatter_f64(<2 x double> %v, ptr %base) noinline optnone {
entry:
  call void @hikari_vmp()
  store <2 x double> <double 1.000000e+00, double 1.000000e+00>, ptr %base, align 8
  %mix = insertelement <2 x i1> zeroinitializer, i1 true, i32 0
  %ptrs = getelementptr double, ptr %base, <2 x i32> <i32 0, i32 1>
  call void @llvm.masked.scatter.v2f64.v2p0(<2 x double> %v, <2 x ptr> %ptrs, i32 8, <2 x i1> %mix)
  %mem = load <2 x double>, ptr %base, align 8
  %bits = bitcast <2 x double> %mem to <2 x i64>
  %r = call i32 @fold_i64x2(<2 x i64> %bits)
  ret i32 %r
}

define i32 @reference_gather_i1(ptr %base, <8 x i1> %passthru) noinline optnone {
entry:
  %m = insertelement <8 x i1> zeroinitializer, i1 true, i32 0
  %m2 = insertelement <8 x i1> %m, i1 true, i32 3
  %ptrs = getelementptr i1, ptr %base, <8 x i8> <i8 0, i8 1, i8 2, i8 3, i8 4, i8 5, i8 6, i8 7>
  %ld = call <8 x i1> @llvm.masked.gather.v8i1.v8p0(<8 x ptr> %ptrs, i32 1, <8 x i1> %m2, <8 x i1> %passthru)
  %r = call i32 @fold_i1x8(<8 x i1> %ld)
  ret i32 %r
}

define i32 @protected_gather_i1(ptr %base, <8 x i1> %passthru) noinline optnone {
entry:
  call void @hikari_vmp()
  %m = insertelement <8 x i1> zeroinitializer, i1 true, i32 0
  %m2 = insertelement <8 x i1> %m, i1 true, i32 3
  %ptrs = getelementptr i1, ptr %base, <8 x i8> <i8 0, i8 1, i8 2, i8 3, i8 4, i8 5, i8 6, i8 7>
  %ld = call <8 x i1> @llvm.masked.gather.v8i1.v8p0(<8 x ptr> %ptrs, i32 1, <8 x i1> %m2, <8 x i1> %passthru)
  %r = call i32 @fold_i1x8(<8 x i1> %ld)
  ret i32 %r
}

define i32 @reference_scatter_i1(<8 x i1> %v, ptr %base) noinline optnone {
entry:
  store <8 x i8> <i8 9, i8 9, i8 9, i8 9, i8 9, i8 9, i8 9, i8 9>, ptr %base, align 1
  %m = insertelement <8 x i1> zeroinitializer, i1 true, i32 0
  %m2 = insertelement <8 x i1> %m, i1 true, i32 3
  %ptrs = getelementptr i1, ptr %base, <8 x i8> <i8 0, i8 1, i8 2, i8 3, i8 4, i8 5, i8 6, i8 7>
  call void @llvm.masked.scatter.v8i1.v8p0(<8 x i1> %v, <8 x ptr> %ptrs, i32 1, <8 x i1> %m2)
  %r = call i32 @fold_mem_i1bytes(ptr %base)
  ret i32 %r
}

define i32 @protected_scatter_i1(<8 x i1> %v, ptr %base) noinline optnone {
entry:
  call void @hikari_vmp()
  store <8 x i8> <i8 9, i8 9, i8 9, i8 9, i8 9, i8 9, i8 9, i8 9>, ptr %base, align 1
  %m = insertelement <8 x i1> zeroinitializer, i1 true, i32 0
  %m2 = insertelement <8 x i1> %m, i1 true, i32 3
  %ptrs = getelementptr i1, ptr %base, <8 x i8> <i8 0, i8 1, i8 2, i8 3, i8 4, i8 5, i8 6, i8 7>
  call void @llvm.masked.scatter.v8i1.v8p0(<8 x i1> %v, <8 x ptr> %ptrs, i32 1, <8 x i1> %m2)
  %r = call i32 @fold_mem_i1bytes(ptr %base)
  ret i32 %r
}

define i32 @reference_scatter_f32(<4 x float> %v, ptr %base) noinline optnone {
entry:
  store <4 x float> <float 1.000000e+00, float 1.000000e+00, float 1.000000e+00, float 1.000000e+00>, ptr %base, align 4
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix = insertelement <4 x i1> %mix0, i1 true, i32 2
  %ptrs = getelementptr float, ptr %base, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  call void @llvm.masked.scatter.v4f32.v4p0(<4 x float> %v, <4 x ptr> %ptrs, i32 4, <4 x i1> %mix)
  %mem = load <4 x float>, ptr %base, align 4
  %bits = bitcast <4 x float> %mem to <4 x i32>
  %r = call i32 @fold_i32x4(<4 x i32> %bits)
  ret i32 %r
}

define i32 @protected_scatter_f32(<4 x float> %v, ptr %base) noinline optnone {
entry:
  call void @hikari_vmp()
  store <4 x float> <float 1.000000e+00, float 1.000000e+00, float 1.000000e+00, float 1.000000e+00>, ptr %base, align 4
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix = insertelement <4 x i1> %mix0, i1 true, i32 2
  %ptrs = getelementptr float, ptr %base, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  call void @llvm.masked.scatter.v4f32.v4p0(<4 x float> %v, <4 x ptr> %ptrs, i32 4, <4 x i1> %mix)
  %mem = load <4 x float>, ptr %base, align 4
  %bits = bitcast <4 x float> %mem to <4 x i32>
  %r = call i32 @fold_i32x4(<4 x i32> %bits)
  ret i32 %r
}

define i32 @reference_scatter_i8(<8 x i8> %v, ptr %base) noinline optnone {
entry:
  store <8 x i8> <i8 1, i8 1, i8 1, i8 1, i8 1, i8 1, i8 1, i8 1>, ptr %base, align 1
  %m = insertelement <8 x i1> zeroinitializer, i1 true, i32 0
  %m2 = insertelement <8 x i1> %m, i1 true, i32 3
  %ptrs = getelementptr i8, ptr %base, <8 x i8> <i8 0, i8 1, i8 2, i8 3, i8 4, i8 5, i8 6, i8 7>
  call void @llvm.masked.scatter.v8i8.v8p0(<8 x i8> %v, <8 x ptr> %ptrs, i32 1, <8 x i1> %m2)
  %mem = load <8 x i8>, ptr %base, align 1
  %r = call i32 @fold_i8x8(<8 x i8> %mem)
  ret i32 %r
}

define i32 @protected_scatter_i8(<8 x i8> %v, ptr %base) noinline optnone {
entry:
  call void @hikari_vmp()
  store <8 x i8> <i8 1, i8 1, i8 1, i8 1, i8 1, i8 1, i8 1, i8 1>, ptr %base, align 1
  %m = insertelement <8 x i1> zeroinitializer, i1 true, i32 0
  %m2 = insertelement <8 x i1> %m, i1 true, i32 3
  %ptrs = getelementptr i8, ptr %base, <8 x i8> <i8 0, i8 1, i8 2, i8 3, i8 4, i8 5, i8 6, i8 7>
  call void @llvm.masked.scatter.v8i8.v8p0(<8 x i8> %v, <8 x ptr> %ptrs, i32 1, <8 x i1> %m2)
  %mem = load <8 x i8>, ptr %base, align 1
  %r = call i32 @fold_i8x8(<8 x i8> %mem)
  ret i32 %r
}

define i32 @reference_scatter_half(<4 x half> %v, ptr %base) noinline optnone {
entry:
  store <4 x half> <half 1.000000e+00, half 1.000000e+00, half 1.000000e+00, half 1.000000e+00>, ptr %base, align 2
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix = insertelement <4 x i1> %mix0, i1 true, i32 2
  %ptrs = getelementptr half, ptr %base, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  call void @llvm.masked.scatter.v4f16.v4p0(<4 x half> %v, <4 x ptr> %ptrs, i32 2, <4 x i1> %mix)
  %mem = load <4 x half>, ptr %base, align 2
  %bits = bitcast <4 x half> %mem to <4 x i16>
  %r = call i32 @fold_i16x4(<4 x i16> %bits)
  ret i32 %r
}

define i32 @protected_scatter_half(<4 x half> %v, ptr %base) noinline optnone {
entry:
  call void @hikari_vmp()
  store <4 x half> <half 1.000000e+00, half 1.000000e+00, half 1.000000e+00, half 1.000000e+00>, ptr %base, align 2
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix = insertelement <4 x i1> %mix0, i1 true, i32 2
  %ptrs = getelementptr half, ptr %base, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  call void @llvm.masked.scatter.v4f16.v4p0(<4 x half> %v, <4 x ptr> %ptrs, i32 2, <4 x i1> %mix)
  %mem = load <4 x half>, ptr %base, align 2
  %bits = bitcast <4 x half> %mem to <4 x i16>
  %r = call i32 @fold_i16x4(<4 x i16> %bits)
  ret i32 %r
}

define i32 @reference_scatter_i64(<2 x i64> %v, ptr %base) noinline optnone {
entry:
  store <2 x i64> <i64 1, i64 1>, ptr %base, align 8
  %mix = insertelement <2 x i1> zeroinitializer, i1 true, i32 0
  %ptrs = getelementptr i64, ptr %base, <2 x i32> <i32 0, i32 1>
  call void @llvm.masked.scatter.v2i64.v2p0(<2 x i64> %v, <2 x ptr> %ptrs, i32 8, <2 x i1> %mix)
  %r = call i32 @fold_mem_i64x2(ptr %base)
  ret i32 %r
}

define i32 @protected_scatter_i64(<2 x i64> %v, ptr %base) noinline optnone {
entry:
  call void @hikari_vmp()
  store <2 x i64> <i64 1, i64 1>, ptr %base, align 8
  %mix = insertelement <2 x i1> zeroinitializer, i1 true, i32 0
  %ptrs = getelementptr i64, ptr %base, <2 x i32> <i32 0, i32 1>
  call void @llvm.masked.scatter.v2i64.v2p0(<2 x i64> %v, <2 x ptr> %ptrs, i32 8, <2 x i1> %mix)
  %r = call i32 @fold_mem_i64x2(ptr %base)
  ret i32 %r
}

define i32 @reference_gather_insert(ptr %base, <4 x i32> %passthru) noinline optnone {
entry:
  %p0 = getelementptr inbounds i32, ptr %base, i32 0
  %p2 = getelementptr inbounds i32, ptr %base, i32 2
  %v0 = insertelement <4 x ptr> zeroinitializer, ptr %p0, i32 0
  %ptrs = insertelement <4 x ptr> %v0, ptr %p2, i32 2
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix = insertelement <4 x i1> %mix0, i1 true, i32 2
  %ld = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> %ptrs, i32 4, <4 x i1> %mix, <4 x i32> %passthru)
  %r = call i32 @fold_i32x4(<4 x i32> %ld)
  ret i32 %r
}

define i32 @protected_gather_insert(ptr %base, <4 x i32> %passthru) noinline optnone {
entry:
  call void @hikari_vmp()
  %p0 = getelementptr inbounds i32, ptr %base, i32 0
  %p2 = getelementptr inbounds i32, ptr %base, i32 2
  %v0 = insertelement <4 x ptr> zeroinitializer, ptr %p0, i32 0
  %ptrs = insertelement <4 x ptr> %v0, ptr %p2, i32 2
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix = insertelement <4 x i1> %mix0, i1 true, i32 2
  %ld = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> %ptrs, i32 4, <4 x i1> %mix, <4 x i32> %passthru)
  %r = call i32 @fold_i32x4(<4 x i32> %ld)
  ret i32 %r
}


define i32 @protected_gather_phi(i1 %c, ptr %base, <4 x i32> %passthru) noinline optnone {
entry:
  call void @hikari_vmp()
  br i1 %c, label %left, label %right

left:
  %pl = getelementptr i32, ptr %base, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  %l = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> %pl, i32 4, <4 x i1> <i1 true, i1 false, i1 true, i1 false>, <4 x i32> %passthru)
  %lz = call i32 @fold_i32x4(<4 x i32> %l)
  br label %done

right:
  %r = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> zeroinitializer, i32 4, <4 x i1> zeroinitializer, <4 x i32> %passthru)
  %rz = call i32 @fold_i32x4(<4 x i32> %r)
  br label %done

done:
  %pphi = phi i32 [ %lz, %left ], [ %rz, %right ]
  ret i32 %pphi
}

define i32 @protected_gather_loop(ptr %base, <4 x i32> %passthru, i32 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %i2, %loop ]
  %acc = phi i32 [ 0, %entry ], [ %acc2, %loop ]
  %ptrs = getelementptr i32, ptr %base, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  %ld = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> %ptrs, i32 4, <4 x i1> <i1 true, i1 false, i1 true, i1 false>, <4 x i32> %passthru)
  %k = call i32 @fold_i32x4(<4 x i32> %ld)
  %acc2 = add i32 %acc, %k
  %i2 = add i32 %i, 1
  %more = icmp slt i32 %i2, %n
  br i1 %more, label %loop, label %done

done:
  ret i32 %acc2
}

define i32 @protected_gather_null_inactive(<4 x i32> %passthru) noinline optnone {
entry:
  call void @hikari_vmp()
  %ld = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> zeroinitializer, i32 4, <4 x i1> zeroinitializer, <4 x i32> %passthru)
  %r = call i32 @fold_i32x4(<4 x i32> %ld)
  ret i32 %r
}

; Diamond phi of <4 x ptr> — drives PointerVectorMove, not an i32 result phi.
define i32 @reference_gather_ptrvec_phi(i1 %c, ptr %base, <4 x i32> %passthru) noinline optnone {
entry:
  br i1 %c, label %left, label %right

left:
  %pl = getelementptr i32, ptr %base, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  br label %done

right:
  %pr = getelementptr i32, ptr %base, <4 x i32> <i32 1, i32 1, i32 1, i32 1>
  br label %done

done:
  %ptrs = phi <4 x ptr> [ %pl, %left ], [ %pr, %right ]
  %ld = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> %ptrs, i32 4, <4 x i1> <i1 true, i1 true, i1 true, i1 true>, <4 x i32> %passthru)
  %r = call i32 @fold_i32x4(<4 x i32> %ld)
  ret i32 %r
}

define i32 @protected_gather_ptrvec_phi(i1 %c, ptr %base, <4 x i32> %passthru) noinline optnone {
entry:
  call void @hikari_vmp()
  br i1 %c, label %left, label %right

left:
  %pl = getelementptr i32, ptr %base, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  br label %done

right:
  %pr = getelementptr i32, ptr %base, <4 x i32> <i32 1, i32 1, i32 1, i32 1>
  br label %done

done:
  %ptrs = phi <4 x ptr> [ %pl, %left ], [ %pr, %right ]
  %ld = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> %ptrs, i32 4, <4 x i1> <i1 true, i1 true, i1 true, i1 true>, <4 x i32> %passthru)
  %r = call i32 @fold_i32x4(<4 x i32> %ld)
  ret i32 %r
}

define i32 @reference_gather_ptrvec_select(i1 %c, ptr %base, <4 x i32> %passthru) noinline optnone {
entry:
  %pl = getelementptr i32, ptr %base, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  %pr = getelementptr i32, ptr %base, <4 x i32> <i32 1, i32 1, i32 1, i32 1>
  %ptrs = select i1 %c, <4 x ptr> %pl, <4 x ptr> %pr
  %ld = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> %ptrs, i32 4, <4 x i1> <i1 true, i1 true, i1 true, i1 true>, <4 x i32> %passthru)
  %r = call i32 @fold_i32x4(<4 x i32> %ld)
  ret i32 %r
}

define i32 @protected_gather_ptrvec_select(i1 %c, ptr %base, <4 x i32> %passthru) noinline optnone {
entry:
  call void @hikari_vmp()
  %pl = getelementptr i32, ptr %base, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  %pr = getelementptr i32, ptr %base, <4 x i32> <i32 1, i32 1, i32 1, i32 1>
  %ptrs = select i1 %c, <4 x ptr> %pl, <4 x ptr> %pr
  %ld = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> %ptrs, i32 4, <4 x i1> <i1 true, i1 true, i1 true, i1 true>, <4 x i32> %passthru)
  %r = call i32 @fold_i32x4(<4 x i32> %ld)
  ret i32 %r
}

define i32 @reference_gather_ptrvec_select_mask(ptr %base, <4 x i32> %passthru) noinline optnone {
entry:
  %pl = getelementptr i32, ptr %base, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  %pr = getelementptr i32, ptr %base, <4 x i32> <i32 1, i32 1, i32 1, i32 1>
  %ptrs = select <4 x i1> <i1 true, i1 false, i1 true, i1 false>, <4 x ptr> %pl, <4 x ptr> %pr
  %ld = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> %ptrs, i32 4, <4 x i1> <i1 true, i1 true, i1 true, i1 true>, <4 x i32> %passthru)
  %r = call i32 @fold_i32x4(<4 x i32> %ld)
  ret i32 %r
}

define i32 @protected_gather_ptrvec_select_mask(ptr %base, <4 x i32> %passthru) noinline optnone {
entry:
  call void @hikari_vmp()
  %pl = getelementptr i32, ptr %base, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  %pr = getelementptr i32, ptr %base, <4 x i32> <i32 1, i32 1, i32 1, i32 1>
  %ptrs = select <4 x i1> <i1 true, i1 false, i1 true, i1 false>, <4 x ptr> %pl, <4 x ptr> %pr
  %ld = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> %ptrs, i32 4, <4 x i1> <i1 true, i1 true, i1 true, i1 true>, <4 x i32> %passthru)
  %r = call i32 @fold_i32x4(<4 x i32> %ld)
  ret i32 %r
}

define i32 @reference_gather_extract(ptr %base) noinline optnone {
entry:
  %ptrs = getelementptr i32, ptr %base, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  %p0 = extractelement <4 x ptr> %ptrs, i32 0
  %p2 = extractelement <4 x ptr> %ptrs, i32 2
  %v0 = load i32, ptr %p0, align 4
  %v2 = load i32, ptr %p2, align 4
  %r = xor i32 %v0, %v2
  ret i32 %r
}

define i32 @protected_gather_extract(ptr %base) noinline optnone {
entry:
  call void @hikari_vmp()
  %ptrs = getelementptr i32, ptr %base, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  %p0 = extractelement <4 x ptr> %ptrs, i32 0
  %p2 = extractelement <4 x ptr> %ptrs, i32 2
  %v0 = load i32, ptr %p0, align 4
  %v2 = load i32, ptr %p2, align 4
  %r = xor i32 %v0, %v2
  ret i32 %r
}

; AoS field addresses: getelementptr %Pair, ptr, <4 x i32>, i32 1.
define i32 @reference_gather_aos(ptr %base, <4 x i32> %passthru) noinline optnone {
entry:
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix = insertelement <4 x i1> %mix0, i1 true, i32 2
  %ptrs = getelementptr %Pair, ptr %base, <4 x i32> <i32 0, i32 1, i32 2, i32 3>, i32 1
  %ld = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> %ptrs, i32 4, <4 x i1> %mix, <4 x i32> %passthru)
  %r = call i32 @fold_i32x4(<4 x i32> %ld)
  ret i32 %r
}

define i32 @protected_gather_aos(ptr %base, <4 x i32> %passthru) noinline optnone {
entry:
  call void @hikari_vmp()
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix = insertelement <4 x i1> %mix0, i1 true, i32 2
  %ptrs = getelementptr %Pair, ptr %base, <4 x i32> <i32 0, i32 1, i32 2, i32 3>, i32 1
  %ld = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> %ptrs, i32 4, <4 x i1> %mix, <4 x i32> %passthru)
  %r = call i32 @fold_i32x4(<4 x i32> %ld)
  ret i32 %r
}

define i32 @reference_scatter_aos(<4 x i32> %v, ptr %base) noinline optnone {
entry:
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix = insertelement <4 x i1> %mix0, i1 true, i32 2
  %ptrs = getelementptr %Pair, ptr %base, <4 x i32> <i32 0, i32 1, i32 2, i32 3>, i32 1
  call void @llvm.masked.scatter.v4i32.v4p0(<4 x i32> %v, <4 x ptr> %ptrs, i32 4, <4 x i1> %mix)
  %all = getelementptr %Pair, ptr %base, <4 x i32> <i32 0, i32 1, i32 2, i32 3>, i32 1
  %mem = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> %all, i32 4, <4 x i1> <i1 true, i1 true, i1 true, i1 true>, <4 x i32> zeroinitializer)
  %r = call i32 @fold_i32x4(<4 x i32> %mem)
  ret i32 %r
}

define i32 @protected_scatter_aos(<4 x i32> %v, ptr %base) noinline optnone {
entry:
  call void @hikari_vmp()
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix = insertelement <4 x i1> %mix0, i1 true, i32 2
  %ptrs = getelementptr %Pair, ptr %base, <4 x i32> <i32 0, i32 1, i32 2, i32 3>, i32 1
  call void @llvm.masked.scatter.v4i32.v4p0(<4 x i32> %v, <4 x ptr> %ptrs, i32 4, <4 x i1> %mix)
  %all = getelementptr %Pair, ptr %base, <4 x i32> <i32 0, i32 1, i32 2, i32 3>, i32 1
  %mem = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> %all, i32 4, <4 x i1> <i1 true, i1 true, i1 true, i1 true>, <4 x i32> zeroinitializer)
  %r = call i32 @fold_i32x4(<4 x i32> %mem)
  ret i32 %r
}

; Array-of-arrays column: getelementptr [2 x i32], ptr, <4 x i32>, i32 1.
define i32 @reference_gather_array(ptr %base, <4 x i32> %passthru) noinline optnone {
entry:
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix = insertelement <4 x i1> %mix0, i1 true, i32 2
  %ptrs = getelementptr [2 x i32], ptr %base, <4 x i32> <i32 0, i32 1, i32 2, i32 3>, i32 1
  %ld = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> %ptrs, i32 4, <4 x i1> %mix, <4 x i32> %passthru)
  %r = call i32 @fold_i32x4(<4 x i32> %ld)
  ret i32 %r
}

define i32 @protected_gather_array(ptr %base, <4 x i32> %passthru) noinline optnone {
entry:
  call void @hikari_vmp()
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix = insertelement <4 x i1> %mix0, i1 true, i32 2
  %ptrs = getelementptr [2 x i32], ptr %base, <4 x i32> <i32 0, i32 1, i32 2, i32 3>, i32 1
  %ld = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> %ptrs, i32 4, <4 x i1> %mix, <4 x i32> %passthru)
  %r = call i32 @fold_i32x4(<4 x i32> %ld)
  ret i32 %r
}

define i32 @reference_scatter_array(<4 x i32> %v, ptr %base) noinline optnone {
entry:
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix = insertelement <4 x i1> %mix0, i1 true, i32 2
  %ptrs = getelementptr [2 x i32], ptr %base, <4 x i32> <i32 0, i32 1, i32 2, i32 3>, i32 1
  call void @llvm.masked.scatter.v4i32.v4p0(<4 x i32> %v, <4 x ptr> %ptrs, i32 4, <4 x i1> %mix)
  %all = getelementptr [2 x i32], ptr %base, <4 x i32> <i32 0, i32 1, i32 2, i32 3>, i32 1
  %mem = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> %all, i32 4, <4 x i1> <i1 true, i1 true, i1 true, i1 true>, <4 x i32> zeroinitializer)
  %r = call i32 @fold_i32x4(<4 x i32> %mem)
  ret i32 %r
}

define i32 @protected_scatter_array(<4 x i32> %v, ptr %base) noinline optnone {
entry:
  call void @hikari_vmp()
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix = insertelement <4 x i1> %mix0, i1 true, i32 2
  %ptrs = getelementptr [2 x i32], ptr %base, <4 x i32> <i32 0, i32 1, i32 2, i32 3>, i32 1
  call void @llvm.masked.scatter.v4i32.v4p0(<4 x i32> %v, <4 x ptr> %ptrs, i32 4, <4 x i1> %mix)
  %all = getelementptr [2 x i32], ptr %base, <4 x i32> <i32 0, i32 1, i32 2, i32 3>, i32 1
  %mem = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> %all, i32 4, <4 x i1> <i1 true, i1 true, i1 true, i1 true>, <4 x i32> zeroinitializer)
  %r = call i32 @fold_i32x4(<4 x i32> %mem)
  ret i32 %r
}

; 3-index AoS: getelementptr %Wrap, ptr, <4 x i32>, i32 0, i32 1.
define i32 @reference_gather_wrap(ptr %base, <4 x i32> %passthru) noinline optnone {
entry:
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix = insertelement <4 x i1> %mix0, i1 true, i32 2
  %ptrs = getelementptr %Wrap, ptr %base, <4 x i32> <i32 0, i32 1, i32 2, i32 3>, i32 0, i32 1
  %ld = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> %ptrs, i32 4, <4 x i1> %mix, <4 x i32> %passthru)
  %r = call i32 @fold_i32x4(<4 x i32> %ld)
  ret i32 %r
}

define i32 @protected_gather_wrap(ptr %base, <4 x i32> %passthru) noinline optnone {
entry:
  call void @hikari_vmp()
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix = insertelement <4 x i1> %mix0, i1 true, i32 2
  %ptrs = getelementptr %Wrap, ptr %base, <4 x i32> <i32 0, i32 1, i32 2, i32 3>, i32 0, i32 1
  %ld = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> %ptrs, i32 4, <4 x i1> %mix, <4 x i32> %passthru)
  %r = call i32 @fold_i32x4(<4 x i32> %ld)
  ret i32 %r
}

define i32 @reference_scatter_wrap(<4 x i32> %v, ptr %base) noinline optnone {
entry:
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix = insertelement <4 x i1> %mix0, i1 true, i32 2
  %ptrs = getelementptr %Wrap, ptr %base, <4 x i32> <i32 0, i32 1, i32 2, i32 3>, i32 0, i32 1
  call void @llvm.masked.scatter.v4i32.v4p0(<4 x i32> %v, <4 x ptr> %ptrs, i32 4, <4 x i1> %mix)
  %all = getelementptr %Wrap, ptr %base, <4 x i32> <i32 0, i32 1, i32 2, i32 3>, i32 0, i32 1
  %mem = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> %all, i32 4, <4 x i1> <i1 true, i1 true, i1 true, i1 true>, <4 x i32> zeroinitializer)
  %r = call i32 @fold_i32x4(<4 x i32> %mem)
  ret i32 %r
}

define i32 @protected_scatter_wrap(<4 x i32> %v, ptr %base) noinline optnone {
entry:
  call void @hikari_vmp()
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix = insertelement <4 x i1> %mix0, i1 true, i32 2
  %ptrs = getelementptr %Wrap, ptr %base, <4 x i32> <i32 0, i32 1, i32 2, i32 3>, i32 0, i32 1
  call void @llvm.masked.scatter.v4i32.v4p0(<4 x i32> %v, <4 x ptr> %ptrs, i32 4, <4 x i1> %mix)
  %all = getelementptr %Wrap, ptr %base, <4 x i32> <i32 0, i32 1, i32 2, i32 3>, i32 0, i32 1
  %mem = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> %all, i32 4, <4 x i1> <i1 true, i1 true, i1 true, i1 true>, <4 x i32> zeroinitializer)
  %r = call i32 @fold_i32x4(<4 x i32> %mem)
  ret i32 %r
}

; Clang AoS: getelementptr [4 x %Pair], ptr, i32 0, <4 x i32>, i32 1.
define i32 @reference_gather_pairarr(ptr %base, <4 x i32> %passthru) noinline optnone {
entry:
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix = insertelement <4 x i1> %mix0, i1 true, i32 2
  %ptrs = getelementptr [4 x %Pair], ptr %base, i32 0, <4 x i32> <i32 0, i32 1, i32 2, i32 3>, i32 1
  %ld = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> %ptrs, i32 4, <4 x i1> %mix, <4 x i32> %passthru)
  %ptrsi = getelementptr inbounds [4 x %Pair], ptr %base, i32 0, <4 x i32> <i32 0, i32 1, i32 2, i32 3>, i32 1
  %ldi = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> %ptrsi, i32 4, <4 x i1> %mix, <4 x i32> %passthru)
  %r0 = call i32 @fold_i32x4(<4 x i32> %ld)
  %ri = call i32 @fold_i32x4(<4 x i32> %ldi)
  %r = add i32 %r0, %ri
  ret i32 %r
}

define i32 @protected_gather_pairarr(ptr %base, <4 x i32> %passthru) noinline optnone {
entry:
  call void @hikari_vmp()
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix = insertelement <4 x i1> %mix0, i1 true, i32 2
  %ptrs = getelementptr [4 x %Pair], ptr %base, i32 0, <4 x i32> <i32 0, i32 1, i32 2, i32 3>, i32 1
  %ld = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> %ptrs, i32 4, <4 x i1> %mix, <4 x i32> %passthru)
  %ptrsi = getelementptr inbounds [4 x %Pair], ptr %base, i32 0, <4 x i32> <i32 0, i32 1, i32 2, i32 3>, i32 1
  %ldi = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> %ptrsi, i32 4, <4 x i1> %mix, <4 x i32> %passthru)
  %r0 = call i32 @fold_i32x4(<4 x i32> %ld)
  %ri = call i32 @fold_i32x4(<4 x i32> %ldi)
  %r = add i32 %r0, %ri
  ret i32 %r
}

define i32 @reference_scatter_pairarr(<4 x i32> %v, ptr %base) noinline optnone {
entry:
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix = insertelement <4 x i1> %mix0, i1 true, i32 2
  %ptrs = getelementptr [4 x %Pair], ptr %base, i32 0, <4 x i32> <i32 0, i32 1, i32 2, i32 3>, i32 1
  call void @llvm.masked.scatter.v4i32.v4p0(<4 x i32> %v, <4 x ptr> %ptrs, i32 4, <4 x i1> %mix)
  %all = getelementptr [4 x %Pair], ptr %base, i32 0, <4 x i32> <i32 0, i32 1, i32 2, i32 3>, i32 1
  %alli = getelementptr inbounds [4 x %Pair], ptr %base, i64 0, <4 x i32> <i32 0, i32 1, i32 2, i32 3>, i32 1
  %mem = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> %all, i32 4, <4 x i1> <i1 true, i1 true, i1 true, i1 true>, <4 x i32> zeroinitializer)
  %memi = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> %alli, i32 4, <4 x i1> <i1 true, i1 true, i1 true, i1 true>, <4 x i32> zeroinitializer)
  %r0 = call i32 @fold_i32x4(<4 x i32> %mem)
  %ri = call i32 @fold_i32x4(<4 x i32> %memi)
  %r = add i32 %r0, %ri
  ret i32 %r
}

define i32 @protected_scatter_pairarr(<4 x i32> %v, ptr %base) noinline optnone {
entry:
  call void @hikari_vmp()
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix = insertelement <4 x i1> %mix0, i1 true, i32 2
  %ptrs = getelementptr [4 x %Pair], ptr %base, i32 0, <4 x i32> <i32 0, i32 1, i32 2, i32 3>, i32 1
  call void @llvm.masked.scatter.v4i32.v4p0(<4 x i32> %v, <4 x ptr> %ptrs, i32 4, <4 x i1> %mix)
  %all = getelementptr [4 x %Pair], ptr %base, i32 0, <4 x i32> <i32 0, i32 1, i32 2, i32 3>, i32 1
  %alli = getelementptr inbounds [4 x %Pair], ptr %base, i64 0, <4 x i32> <i32 0, i32 1, i32 2, i32 3>, i32 1
  %mem = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> %all, i32 4, <4 x i1> <i1 true, i1 true, i1 true, i1 true>, <4 x i32> zeroinitializer)
  %memi = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> %alli, i32 4, <4 x i1> <i1 true, i1 true, i1 true, i1 true>, <4 x i32> zeroinitializer)
  %r0 = call i32 @fold_i32x4(<4 x i32> %mem)
  %ri = call i32 @fold_i32x4(<4 x i32> %memi)
  %r = add i32 %r0, %ri
  ret i32 %r
}

; Same PairArr shape with clang's i64 0 leading index.
define i32 @reference_gather_pairarr_i64(ptr %base, <4 x i32> %passthru) noinline optnone {
entry:
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix = insertelement <4 x i1> %mix0, i1 true, i32 2
  %ptrs = getelementptr [4 x %Pair], ptr %base, i64 0, <4 x i32> <i32 0, i32 1, i32 2, i32 3>, i32 1
  %ld = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> %ptrs, i32 4, <4 x i1> %mix, <4 x i32> %passthru)
  %ptrsi = getelementptr inbounds [4 x %Pair], ptr %base, i64 0, <4 x i32> <i32 0, i32 1, i32 2, i32 3>, i32 1
  %ldi = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> %ptrsi, i32 4, <4 x i1> %mix, <4 x i32> %passthru)
  %r0 = call i32 @fold_i32x4(<4 x i32> %ld)
  %ri = call i32 @fold_i32x4(<4 x i32> %ldi)
  %r = add i32 %r0, %ri
  ret i32 %r
}

define i32 @protected_gather_pairarr_i64(ptr %base, <4 x i32> %passthru) noinline optnone {
entry:
  call void @hikari_vmp()
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix = insertelement <4 x i1> %mix0, i1 true, i32 2
  %ptrs = getelementptr [4 x %Pair], ptr %base, i64 0, <4 x i32> <i32 0, i32 1, i32 2, i32 3>, i32 1
  %ld = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> %ptrs, i32 4, <4 x i1> %mix, <4 x i32> %passthru)
  %ptrsi = getelementptr inbounds [4 x %Pair], ptr %base, i64 0, <4 x i32> <i32 0, i32 1, i32 2, i32 3>, i32 1
  %ldi = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> %ptrsi, i32 4, <4 x i1> %mix, <4 x i32> %passthru)
  %r0 = call i32 @fold_i32x4(<4 x i32> %ld)
  %ri = call i32 @fold_i32x4(<4 x i32> %ldi)
  %r = add i32 %r0, %ri
  ret i32 %r
}

; Backedge phi of <4 x ptr> so PointerVectorMove runs on a loop edge.
define i32 @protected_gather_ptrvec_loop(ptr %base, <4 x i32> %passthru, i32 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  %init = getelementptr i32, ptr %base, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  br label %loop

loop:
  %ptrs = phi <4 x ptr> [ %init, %entry ], [ %ptrs, %loop ]
  %i = phi i32 [ 0, %entry ], [ %i2, %loop ]
  %acc = phi i32 [ 0, %entry ], [ %acc2, %loop ]
  %ld = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> %ptrs, i32 4, <4 x i1> <i1 true, i1 true, i1 true, i1 true>, <4 x i32> %passthru)
  %k = call i32 @fold_i32x4(<4 x i32> %ld)
  %acc2 = add i32 %acc, %k
  %i2 = add i32 %i, 1
  %more = icmp slt i32 %i2, %n
  br i1 %more, label %loop, label %done

done:
  ret i32 %acc2
}

define i32 @sink_i32(ptr %p, i32 %x) {
entry:
  ret i32 %x
}

define i32 @unsupported_gather_scalable() noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.masked.gather.nxv4i32.nxv4p0(<vscale x 4 x ptr> zeroinitializer, i32 4, <vscale x 4 x i1> zeroinitializer, <vscale x 4 x i32> zeroinitializer)
  ret i32 0
}

define i32 @unsupported_gather_as1(<4 x i1> %m, <4 x i32> %t) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.masked.gather.v4i32.v4p1(<4 x ptr addrspace(1)> zeroinitializer, i32 4, <4 x i1> %m, <4 x i32> %t)
  %e = extractelement <4 x i32> %r, i32 0
  ret i32 %e
}

define i32 @unsupported_gather_wide_ptrs(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %ptrs = getelementptr i8, ptr %p, <16 x i32> zeroinitializer
  %r = call <16 x i8> @llvm.masked.gather.v16i8.v16p0(<16 x ptr> %ptrs, i32 1, <16 x i1> zeroinitializer, <16 x i8> zeroinitializer)
  %e = extractelement <16 x i8> %r, i32 0
  %z = zext i8 %e to i32
  ret i32 %z
}

define i32 @unsupported_gather_wide_data() noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i32> @llvm.masked.gather.v8i32.v8p0(<8 x ptr> zeroinitializer, i32 4, <8 x i1> zeroinitializer, <8 x i32> zeroinitializer)
  %e = extractelement <8 x i32> %r, i32 0
  ret i32 %e
}

define i32 @unsupported_gather_musttail(ptr %p, i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %pt = insertelement <4 x i32> zeroinitializer, i32 %x, i32 0
  %ld = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> zeroinitializer, i32 4, <4 x i1> zeroinitializer, <4 x i32> %pt)
  %e = extractelement <4 x i32> %ld, i32 0
  %r = musttail call i32 @sink_i32(ptr %p, i32 %e)
  ret i32 %r
}

define i32 @unsupported_gather_poison(ptr %p, <4 x i1> %m) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> poison, i32 4, <4 x i1> %m, <4 x i32> zeroinitializer)
  %e = extractelement <4 x i32> %r, i32 0
  ret i32 %e
}

define i32 @unsupported_gather_fastcc(ptr %p, <4 x i1> %m, <4 x i32> %t) noinline optnone {
entry:
  call void @hikari_vmp()
  %ptrs = getelementptr i32, ptr %p, <4 x i32> zeroinitializer
  %r = call fastcc <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> %ptrs, i32 4, <4 x i1> %m, <4 x i32> %t)
  %e = extractelement <4 x i32> %r, i32 0
  ret i32 %e
}

define i32 @unsupported_ptrvec_arg(<4 x ptr> %ptrs, <4 x i1> %m, <4 x i32> %t) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> %ptrs, i32 4, <4 x i1> %m, <4 x i32> %t)
  %e = extractelement <4 x i32> %r, i32 0
  ret i32 %e
}

; Dynamic leading index is not PairArrForm.
define i32 @unsupported_gather_aos_dyn_lead(ptr %p, i32 %off, <4 x i1> %m, <4 x i32> %t) noinline optnone {
entry:
  call void @hikari_vmp()
  %ptrs = getelementptr [4 x %Pair], ptr %p, i32 %off, <4 x i32> zeroinitializer, i32 1
  %r = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> %ptrs, i32 4, <4 x i1> %m, <4 x i32> %t)
  %e = extractelement <4 x i32> %r, i32 0
  ret i32 %e
}

; Non-zero leading ConstantInt is not PairArrForm.
define i32 @unsupported_gather_aos_nonzero_lead(ptr %p, <4 x i1> %m, <4 x i32> %t) noinline optnone {
entry:
  call void @hikari_vmp()
  %ptrs = getelementptr [4 x %Pair], ptr %p, i32 1, <4 x i32> zeroinitializer, i32 1
  %ptrs64 = getelementptr [4 x %Pair], ptr %p, i64 1, <4 x i32> zeroinitializer, i32 1
  %r = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> %ptrs, i32 4, <4 x i1> %m, <4 x i32> %t)
  %r64 = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> %ptrs64, i32 4, <4 x i1> %m, <4 x i32> %t)
  %e = extractelement <4 x i32> %r, i32 0
  %e64 = extractelement <4 x i32> %r64, i32 0
  %s = add i32 %e, %e64
  ret i32 %s
}

; Leading i32 0 + vector + array element (not a struct field) stays rejected.
define i32 @unsupported_gather_aos_zero_array(ptr %p, <4 x i1> %m, <4 x i32> %t) noinline optnone {
entry:
  call void @hikari_vmp()
  %ptrs = getelementptr [2 x [2 x i32]], ptr %p, i32 0, <4 x i32> zeroinitializer, i32 1
  %r = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> %ptrs, i32 4, <4 x i1> %m, <4 x i32> %t)
  %e = extractelement <4 x i32> %r, i32 0
  ret i32 %e
}

; Other 3-index shapes (array then array) stay rejected.
define i32 @unsupported_gather_aos_three_array(ptr %p, <4 x i1> %m, <4 x i32> %t) noinline optnone {
entry:
  call void @hikari_vmp()
  %ptrs = getelementptr [2 x [2 x i32]], ptr %p, <4 x i32> zeroinitializer, i32 0, i32 1
  %r = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> %ptrs, i32 4, <4 x i1> %m, <4 x i32> %t)
  %e = extractelement <4 x i32> %r, i32 0
  ret i32 %e
}

; 4-index stays rejected.
define i32 @unsupported_gather_aos_four_index(ptr %p, <4 x i1> %m, <4 x i32> %t) noinline optnone {
entry:
  call void @hikari_vmp()
  %ptrs = getelementptr %Deep, ptr %p, <4 x i32> zeroinitializer, i32 0, i32 0, i32 1
  %r = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> %ptrs, i32 4, <4 x i1> %m, <4 x i32> %t)
  %e = extractelement <4 x i32> %r, i32 0
  ret i32 %e
}

; Dynamic second index stays rejected (array or otherwise).
define i32 @unsupported_gather_aos_dyn_index(ptr %p, i32 %off, <4 x i1> %m, <4 x i32> %t) noinline optnone {
entry:
  call void @hikari_vmp()
  %ptrs = getelementptr [2 x i32], ptr %p, <4 x i32> zeroinitializer, i32 %off
  %r = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> %ptrs, i32 4, <4 x i1> %m, <4 x i32> %t)
  %e = extractelement <4 x i32> %r, i32 0
  ret i32 %e
}

; Constant array index out of range stays rejected.
define i32 @unsupported_gather_array_oob(ptr %p, <4 x i1> %m, <4 x i32> %t) noinline optnone {
entry:
  call void @hikari_vmp()
  %ptrs = getelementptr [2 x i32], ptr %p, <4 x i32> zeroinitializer, i32 2
  %r = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> %ptrs, i32 4, <4 x i1> %m, <4 x i32> %t)
  %e = extractelement <4 x i32> %r, i32 0
  ret i32 %e
}

; Vector-base GEP stays rejected (not a scalar AS0 base).  Two
; distinct pointer args keep O2 from rewriting this as scalar-base
; plus a splat index.
define i32 @unsupported_gather_vector_base(ptr %p, ptr %q, <4 x i1> %m, <4 x i32> %t) noinline optnone {
entry:
  call void @hikari_vmp()
  %v0 = insertelement <4 x ptr> zeroinitializer, ptr %p, i32 0
  %v1 = insertelement <4 x ptr> %v0, ptr %q, i32 1
  %v2 = insertelement <4 x ptr> %v1, ptr %p, i32 2
  %v3 = insertelement <4 x ptr> %v2, ptr %q, i32 3
  %ptrs = getelementptr i32, <4 x ptr> %v3, i32 1
  %r = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> %ptrs, i32 4, <4 x i1> %m, <4 x i32> %t)
  %e = extractelement <4 x i32> %r, i32 0
  ret i32 %e
}

define i32 @main() {
entry:
  %d0 = alloca [4 x i32], align 16
  %d1 = alloca [4 x i32], align 16
  %d16r = alloca [4 x i16], align 8
  %d16p = alloca [4 x i16], align 8
  %dfr = alloca [2 x double], align 16
  %dfp = alloca [2 x double], align 16
  %d1r = alloca [8 x i8], align 8
  %d1p = alloca [8 x i8], align 8
  %df32r = alloca [4 x float], align 16
  %df32p = alloca [4 x float], align 16
  %d8r = alloca [8 x i8], align 8
  %d8p = alloca [8 x i8], align 8
  %dhr = alloca [4 x half], align 8
  %dhp = alloca [4 x half], align 8
  %d64r = alloca [2 x i64], align 16
  %d64p = alloca [2 x i64], align 16
  %dpr = alloca [4 x %Pair], align 16
  %dpp = alloca [4 x %Pair], align 16
  %srcpairs = load [4 x %Pair], ptr @src.pair, align 16
  store [4 x %Pair] %srcpairs, ptr %dpr, align 16
  store [4 x %Pair] %srcpairs, ptr %dpp, align 16
  %dar = alloca [4 x [2 x i32]], align 16
  %dap = alloca [4 x [2 x i32]], align 16
  %srcrows = load [4 x [2 x i32]], ptr @src.rows, align 16
  store [4 x [2 x i32]] %srcrows, ptr %dar, align 16
  store [4 x [2 x i32]] %srcrows, ptr %dap, align 16
  %dwr = alloca [4 x %Wrap], align 16
  %dwp = alloca [4 x %Wrap], align 16
  %srcwraps = load [4 x %Wrap], ptr @src.wrap, align 16
  store [4 x %Wrap] %srcwraps, ptr %dwr, align 16
  store [4 x %Wrap] %srcwraps, ptr %dwp, align 16
  %dpar = alloca [4 x %Pair], align 16
  %dpap = alloca [4 x %Pair], align 16
  store [4 x %Pair] %srcpairs, ptr %dpar, align 16
  store [4 x %Pair] %srcpairs, ptr %dpap, align 16
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
  %hpt = sitofp <4 x i32> %pt3 to <4 x half>
  %i64p0 = insertelement <2 x i64> undef, i64 1, i32 0
  %i64pt = insertelement <2 x i64> %i64p0, i64 2, i32 1
  %i64s0 = insertelement <2 x i64> undef, i64 9, i32 0
  %i64sv = insertelement <2 x i64> %i64s0, i64 8, i32 1

  %e0 = call i32 @reference_gather(ptr @src.i32, <4 x i32> %pt3)
  %a0 = call i32 @protected_gather(ptr @src.i32, <4 x i32> %pt3)
  %e1 = call i32 @reference_scatter(<4 x i32> %sv3, ptr %d0)
  %a1 = call i32 @protected_scatter(<4 x i32> %sv3, ptr %d1)
  %e2 = call i32 @reference_gather_f32(ptr @src.f32, <4 x float> %fpt)
  %a2 = call i32 @protected_gather_f32(ptr @src.f32, <4 x float> %fpt)
  %e3 = call i32 @reference_gather_i8(ptr @src.i8, <8 x i8> %i8p7)
  %a3 = call i32 @protected_gather_i8(ptr @src.i8, <8 x i8> %i8p7)
  %e4 = call i32 @reference_gather_half(ptr @src.half, <4 x half> %hpt)
  %a4 = call i32 @protected_gather_half(ptr @src.half, <4 x half> %hpt)
  %e5 = call i32 @reference_gather_i64(ptr @src.i64, <2 x i64> %i64pt)
  %a5 = call i32 @protected_gather_i64(ptr @src.i64, <2 x i64> %i64pt)
  %i16pt = trunc <4 x i32> %pt3 to <4 x i16>
  %i16sv = trunc <4 x i32> %sv3 to <4 x i16>
  %f64pt = sitofp <2 x i64> %i64pt to <2 x double>
  %f64sv = sitofp <2 x i64> %i64sv to <2 x double>
  %hsv = sitofp <4 x i32> %sv3 to <4 x half>
  %i1p0 = insertelement <8 x i1> undef, i1 true, i32 0
  %i1p1 = insertelement <8 x i1> %i1p0, i1 false, i32 1
  %i1p2 = insertelement <8 x i1> %i1p1, i1 true, i32 2
  %i1p3 = insertelement <8 x i1> %i1p2, i1 false, i32 3
  %i1p4 = insertelement <8 x i1> %i1p3, i1 true, i32 4
  %i1p5 = insertelement <8 x i1> %i1p4, i1 false, i32 5
  %i1p6 = insertelement <8 x i1> %i1p5, i1 true, i32 6
  %i1pt = insertelement <8 x i1> %i1p6, i1 false, i32 7
  %e19 = call i32 @reference_gather_i16(ptr @src.i16, <4 x i16> %i16pt)
  %a19 = call i32 @protected_gather_i16(ptr @src.i16, <4 x i16> %i16pt)
  %e20 = call i32 @reference_scatter_i16(<4 x i16> %i16sv, ptr %d16r)
  %a20 = call i32 @protected_scatter_i16(<4 x i16> %i16sv, ptr %d16p)
  %e21 = call i32 @reference_gather_f64(ptr @src.f64, <2 x double> %f64pt)
  %a21 = call i32 @protected_gather_f64(ptr @src.f64, <2 x double> %f64pt)
  %e22 = call i32 @reference_scatter_f64(<2 x double> %f64sv, ptr %dfr)
  %a22 = call i32 @protected_scatter_f64(<2 x double> %f64sv, ptr %dfp)
  %e23 = call i32 @reference_gather_i1(ptr @src.i1, <8 x i1> %i1pt)
  %a23 = call i32 @protected_gather_i1(ptr @src.i1, <8 x i1> %i1pt)
  %e24 = call i32 @reference_scatter_i1(<8 x i1> %i1pt, ptr %d1r)
  %a24 = call i32 @protected_scatter_i1(<8 x i1> %i1pt, ptr %d1p)
  %fsv = sitofp <4 x i32> %sv3 to <4 x float>
  %e25 = call i32 @reference_scatter_f32(<4 x float> %fsv, ptr %df32r)
  %a25 = call i32 @protected_scatter_f32(<4 x float> %fsv, ptr %df32p)
  %e26 = call i32 @reference_scatter_i8(<8 x i8> %i8p7, ptr %d8r)
  %a26 = call i32 @protected_scatter_i8(<8 x i8> %i8p7, ptr %d8p)
  %e27 = call i32 @reference_scatter_half(<4 x half> %hsv, ptr %dhr)
  %a27 = call i32 @protected_scatter_half(<4 x half> %hsv, ptr %dhp)
  %e28 = call i32 @reference_scatter_i64(<2 x i64> %i64sv, ptr %d64r)
  %a28 = call i32 @protected_scatter_i64(<2 x i64> %i64sv, ptr %d64p)
  %e6 = call i32 @reference_gather_insert(ptr @src.i32, <4 x i32> %pt3)
  %a6 = call i32 @protected_gather_insert(ptr @src.i32, <4 x i32> %pt3)
  %e8 = call i32 @protected_gather_phi(i1 true, ptr @src.i32, <4 x i32> %pt3)
  %e8p = getelementptr i32, ptr @src.i32, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  %e8r = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> %e8p, i32 4, <4 x i1> <i1 true, i1 false, i1 true, i1 false>, <4 x i32> %pt3)
  %e8x = call i32 @fold_i32x4(<4 x i32> %e8r)
  %e9 = call i32 @protected_gather_phi(i1 false, ptr @src.i32, <4 x i32> %pt3)
  %e9x = call i32 @fold_i32x4(<4 x i32> %pt3)
  %e10 = call i32 @protected_gather_loop(ptr @src.i32, <4 x i32> %pt3, i32 3)
  %e10x = mul i32 %e8x, 3
  %e11 = call i32 @protected_gather_null_inactive(<4 x i32> %pt3)
  %e11x = call i32 @fold_i32x4(<4 x i32> %pt3)
  %e12 = call i32 @reference_gather_ptrvec_phi(i1 true, ptr @src.i32, <4 x i32> %pt3)
  %a12 = call i32 @protected_gather_ptrvec_phi(i1 true, ptr @src.i32, <4 x i32> %pt3)
  %e13 = call i32 @reference_gather_ptrvec_phi(i1 false, ptr @src.i32, <4 x i32> %pt3)
  %a13 = call i32 @protected_gather_ptrvec_phi(i1 false, ptr @src.i32, <4 x i32> %pt3)
  %e14 = call i32 @reference_gather_ptrvec_select(i1 true, ptr @src.i32, <4 x i32> %pt3)
  %a14 = call i32 @protected_gather_ptrvec_select(i1 true, ptr @src.i32, <4 x i32> %pt3)
  %e15 = call i32 @reference_gather_ptrvec_select(i1 false, ptr @src.i32, <4 x i32> %pt3)
  %a15 = call i32 @protected_gather_ptrvec_select(i1 false, ptr @src.i32, <4 x i32> %pt3)
  %e16 = call i32 @reference_gather_ptrvec_select_mask(ptr @src.i32, <4 x i32> %pt3)
  %a16 = call i32 @protected_gather_ptrvec_select_mask(ptr @src.i32, <4 x i32> %pt3)
  %e17 = call i32 @reference_gather_extract(ptr @src.i32)
  %a17 = call i32 @protected_gather_extract(ptr @src.i32)
  %e18 = call i32 @protected_gather_ptrvec_loop(ptr @src.i32, <4 x i32> %pt3, i32 3)
  %e18x = call i32 @reference_gather_ptrvec_phi(i1 true, ptr @src.i32, <4 x i32> %pt3)
  %e18y = mul i32 %e18x, 3
  %e29 = call i32 @reference_gather_aos(ptr @src.pair, <4 x i32> %pt3)
  %a29 = call i32 @protected_gather_aos(ptr @src.pair, <4 x i32> %pt3)
  %e30 = call i32 @reference_scatter_aos(<4 x i32> %sv3, ptr %dpr)
  %a30 = call i32 @protected_scatter_aos(<4 x i32> %sv3, ptr %dpp)
  %e31 = call i32 @reference_gather_array(ptr @src.rows, <4 x i32> %pt3)
  %a31 = call i32 @protected_gather_array(ptr @src.rows, <4 x i32> %pt3)
  %e32 = call i32 @reference_scatter_array(<4 x i32> %sv3, ptr %dar)
  %a32 = call i32 @protected_scatter_array(<4 x i32> %sv3, ptr %dap)
  %e33 = call i32 @reference_gather_wrap(ptr @src.wrap, <4 x i32> %pt3)
  %a33 = call i32 @protected_gather_wrap(ptr @src.wrap, <4 x i32> %pt3)
  %e34 = call i32 @reference_scatter_wrap(<4 x i32> %sv3, ptr %dwr)
  %a34 = call i32 @protected_scatter_wrap(<4 x i32> %sv3, ptr %dwp)
  %e35 = call i32 @reference_gather_pairarr(ptr @src.pair, <4 x i32> %pt3)
  %a35 = call i32 @protected_gather_pairarr(ptr @src.pair, <4 x i32> %pt3)
  %e36 = call i32 @reference_scatter_pairarr(<4 x i32> %sv3, ptr %dpar)
  %a36 = call i32 @protected_scatter_pairarr(<4 x i32> %sv3, ptr %dpap)
  %e37 = call i32 @reference_gather_pairarr_i64(ptr @src.pair, <4 x i32> %pt3)
  %a37 = call i32 @protected_gather_pairarr_i64(ptr @src.pair, <4 x i32> %pt3)
  %sn = load i32, ptr @sentinel, align 4
  %oksn = icmp eq i32 %sn, 291

  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %e1, %a1
  %m2 = icmp eq i32 %e2, %a2
  %m3 = icmp eq i32 %e3, %a3
  %m4 = icmp eq i32 %e4, %a4
  %m5 = icmp eq i32 %e5, %a5
  %m6 = icmp eq i32 %e6, %a6
  %m8 = icmp eq i32 %e8, %e8x
  %m9 = icmp eq i32 %e9, %e9x
  %m10 = icmp eq i32 %e10, %e10x
  %m11 = icmp eq i32 %e11, %e11x
  %m12 = icmp eq i32 %e12, %a12
  %m13 = icmp eq i32 %e13, %a13
  %m14 = icmp eq i32 %e14, %a14
  %m15 = icmp eq i32 %e15, %a15
  %m16 = icmp eq i32 %e16, %a16
  %m17 = icmp eq i32 %e17, %a17
  %m18 = icmp eq i32 %e18, %e18y
  %m19 = icmp eq i32 %e19, %a19
  %m20 = icmp eq i32 %e20, %a20
  %m21 = icmp eq i32 %e21, %a21
  %m22 = icmp eq i32 %e22, %a22
  %m23 = icmp eq i32 %e23, %a23
  %m24 = icmp eq i32 %e24, %a24
  %m25 = icmp eq i32 %e25, %a25
  %m26 = icmp eq i32 %e26, %a26
  %m27 = icmp eq i32 %e27, %a27
  %m28 = icmp eq i32 %e28, %a28
  %m29 = icmp eq i32 %e29, %a29
  %m30 = icmp eq i32 %e30, %a30
  %m31 = icmp eq i32 %e31, %a31
  %m32 = icmp eq i32 %e32, %a32
  %m33 = icmp eq i32 %e33, %a33
  %m34 = icmp eq i32 %e34, %a34
  %m35 = icmp eq i32 %e35, %a35
  %m36 = icmp eq i32 %e36, %a36
  %m37 = icmp eq i32 %e37, %a37
  %t0 = and i1 %m0, %m1
  %t1 = and i1 %m2, %m3
  %t2 = and i1 %m4, %m5
  %t3 = and i1 %m6, %m6
  %t4 = and i1 %m8, %m9
  %t5 = and i1 %m10, %m11
  %t6 = and i1 %m12, %m13
  %t7 = and i1 %m14, %m15
  %t8 = and i1 %m16, %m17
  %t9 = and i1 %m18, %m19
  %t10 = and i1 %m20, %m21
  %t11 = and i1 %m22, %m23
  %t12 = and i1 %m24, %m25
  %t13 = and i1 %m26, %m27
  %ok0 = and i1 %t0, %t1
  %ok1 = and i1 %t2, %t3
  %ok2 = and i1 %t4, %t5
  %ok3 = and i1 %t6, %t7
  %ok4 = and i1 %t8, %t9
  %ok5 = and i1 %t10, %t11
  %ok6 = and i1 %t12, %t13
  %ok7 = and i1 %ok0, %ok1
  %ok8 = and i1 %ok2, %ok3
  %ok9 = and i1 %ok4, %ok5
  %ok10 = and i1 %ok6, %m28
  %ok11 = and i1 %ok7, %ok8
  %ok12 = and i1 %ok9, %ok10
  %ok13 = and i1 %ok11, %oksn
  %ok14 = and i1 %m29, %m30
  %ok15 = and i1 %m31, %m32
  %ok16 = and i1 %ok13, %ok14
  %ok17 = and i1 %m33, %m34
  %ok18 = and i1 %m35, %m36
  %ok19 = and i1 %ok16, %ok17
  %ok20 = and i1 %ok19, %ok18
  %ok = and i1 %ok20, %m37
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with:
; SKIP-O0-DAG: Skipping VMP on unsupported_gather_scalable: unsupported masked memory instruction
; SKIP-DAG: Skipping VMP on unsupported_gather_as1: unsupported masked memory instruction
; SKIP-DAG: Skipping VMP on unsupported_gather_wide_ptrs: unsupported getelementptr instruction
; SKIP-DAG: Skipping VMP on unsupported_gather_wide_data: unsupported masked memory instruction
; SKIP-DAG: Skipping VMP on unsupported_gather_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_gather_poison: unsupported masked memory instruction
; SKIP-DAG: Skipping VMP on unsupported_gather_fastcc: unsupported masked memory instruction
; SKIP-DAG: Skipping VMP on unsupported_ptrvec_arg: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_gather_aos_dyn_lead: unsupported getelementptr instruction
; SKIP-DAG: Skipping VMP on unsupported_gather_aos_nonzero_lead: unsupported getelementptr instruction
; SKIP-DAG: Skipping VMP on unsupported_gather_aos_zero_array: unsupported getelementptr instruction
; SKIP-DAG: Skipping VMP on unsupported_gather_aos_three_array: unsupported getelementptr instruction
; SKIP-DAG: Skipping VMP on unsupported_gather_aos_four_index: unsupported getelementptr instruction
; SKIP-DAG: Skipping VMP on unsupported_gather_aos_dyn_index: unsupported getelementptr instruction
; SKIP-DAG: Skipping VMP on unsupported_gather_array_oob: unsupported getelementptr instruction
; SKIP-DAG: Skipping VMP on unsupported_gather_vector_base: unsupported getelementptr instruction
; SKIP-NOT: Skipping VMP on protected_gather:
; SKIP-NOT: Skipping VMP on protected_scatter:
; SKIP-NOT: Skipping VMP on protected_gather_f32:
; SKIP-NOT: Skipping VMP on protected_gather_i8:
; SKIP-NOT: Skipping VMP on protected_gather_half:
; SKIP-NOT: Skipping VMP on protected_gather_i64:
; SKIP-NOT: Skipping VMP on protected_gather_i16:
; SKIP-NOT: Skipping VMP on protected_scatter_i16:
; SKIP-NOT: Skipping VMP on protected_gather_f64:
; SKIP-NOT: Skipping VMP on protected_scatter_f64:
; SKIP-NOT: Skipping VMP on protected_gather_i1:
; SKIP-NOT: Skipping VMP on protected_scatter_i1:
; SKIP-NOT: Skipping VMP on protected_scatter_f32:
; SKIP-NOT: Skipping VMP on protected_scatter_i8:
; SKIP-NOT: Skipping VMP on protected_scatter_half:
; SKIP-NOT: Skipping VMP on protected_scatter_i64:
; SKIP-NOT: Skipping VMP on protected_gather_insert:
; SKIP-NOT: Skipping VMP on protected_gather_phi:
; SKIP-NOT: Skipping VMP on protected_gather_loop:
; SKIP-NOT: Skipping VMP on protected_gather_null_inactive:
; SKIP-NOT: Skipping VMP on protected_gather_ptrvec_phi:
; SKIP-NOT: Skipping VMP on protected_gather_ptrvec_select:
; SKIP-NOT: Skipping VMP on protected_gather_ptrvec_select_mask:
; SKIP-NOT: Skipping VMP on protected_gather_extract:
; SKIP-NOT: Skipping VMP on protected_gather_ptrvec_loop:
; SKIP-NOT: Skipping VMP on protected_gather_aos:
; SKIP-NOT: Skipping VMP on protected_scatter_aos:
; SKIP-NOT: Skipping VMP on protected_gather_array:
; SKIP-NOT: Skipping VMP on protected_scatter_array:
; SKIP-NOT: Skipping VMP on protected_gather_wrap:
; SKIP-NOT: Skipping VMP on protected_scatter_wrap:
; SKIP-NOT: Skipping VMP on protected_gather_pairarr:
; SKIP-NOT: Skipping VMP on protected_scatter_pairarr:
; SKIP-NOT: Skipping VMP on protected_gather_pairarr_i64:

; VIRT: define i32 @protected_gather({{.*}} #[[PROT:[0-9]+]] {
; VIRT: %vmp.pvregs = alloca {{.*}}[8 x ptr]
; VIRT-NOT: ptrtoint
; VIRT-NOT: inttoptr
; VIRT: vmp.dispatch:
; VIRT-NOT: ptrtoint
; VIRT-NOT: inttoptr
; VIRT: call <4 x i32> @llvm.masked.gather.v4i32.v4p0(
; VIRT: define i32 @protected_scatter({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: ptrtoint
; VIRT-NOT: inttoptr
; VIRT: call void @llvm.masked.scatter.v4i32.v4p0(
; VIRT: define i32 @protected_gather_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x float> @llvm.masked.gather.v4f32.v4p0(
; VIRT: define i32 @protected_gather_i8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x i8> @llvm.masked.gather.v8i8.v8p0(
; VIRT: define i32 @protected_gather_half({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x half> @llvm.masked.gather.v4f16.v4p0(
; VIRT: define i32 @protected_gather_i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i64> @llvm.masked.gather.v2i64.v2p0(
; VIRT: define i32 @protected_gather_i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i16> @llvm.masked.gather.v4i16.v4p0(
; VIRT: define i32 @protected_scatter_i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.masked.scatter.v4i16.v4p0(
; VIRT: define i32 @protected_gather_f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x double> @llvm.masked.gather.v2f64.v2p0(
; VIRT: define i32 @protected_scatter_f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.masked.scatter.v2f64.v2p0(
; VIRT: define i32 @protected_gather_i1({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x i1> @llvm.masked.gather.v8i1.v8p0(
; VIRT: define i32 @protected_scatter_i1({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.masked.scatter.v8i1.v8p0(
; VIRT: define i32 @protected_scatter_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.masked.scatter.v4f32.v4p0(
; VIRT: define i32 @protected_scatter_i8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.masked.scatter.v8i8.v8p0(
; VIRT: define i32 @protected_scatter_half({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.masked.scatter.v4f16.v4p0(
; VIRT: define i32 @protected_scatter_i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.masked.scatter.v2i64.v2p0(
; VIRT: define i32 @protected_gather_insert({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: %vmp.pv.insert = insertelement <4 x ptr>
; VIRT-DAG: call <4 x i32> @llvm.masked.gather.v4i32.v4p0(
; VIRT: define i32 @protected_gather_phi({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.masked.gather.v4i32.v4p0(
; VIRT: define i32 @protected_gather_loop({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.masked.gather.v4i32.v4p0(
; VIRT: define i32 @protected_gather_null_inactive({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.masked.gather.v4i32.v4p0(
; VIRT: define i32 @protected_gather_ptrvec_phi({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: ptrtoint
; VIRT-NOT: inttoptr
; VIRT: call <4 x i32> @llvm.masked.gather.v4i32.v4p0(
; VIRT: define i32 @protected_gather_ptrvec_select({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: %vmp.pv.select = select i1 {{.*}}, <4 x ptr> {{.*}}, <4 x ptr>
; VIRT-DAG: call <4 x i32> @llvm.masked.gather.v4i32.v4p0(
; VIRT: define i32 @protected_gather_ptrvec_select_mask({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: %vmp.pv.select = select <4 x i1> {{.*}}, <4 x ptr> {{.*}}, <4 x ptr>
; VIRT-DAG: call <4 x i32> @llvm.masked.gather.v4i32.v4p0(
; VIRT: define i32 @protected_gather_extract({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: %vmp.pv.extract = extractelement <4 x ptr>
; VIRT: define i32 @protected_gather_aos({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: getelementptr %Pair, {{.*}}, i32 1
; VIRT-DAG: call <4 x i32> @llvm.masked.gather.v4i32.v4p0(
; VIRT: define i32 @protected_scatter_aos({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: getelementptr %Pair, {{.*}}, i32 1
; VIRT-DAG: call void @llvm.masked.scatter.v4i32.v4p0(
; VIRT-DAG: call <4 x i32> @llvm.masked.gather.v4i32.v4p0(
; VIRT: define i32 @protected_gather_array({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: getelementptr {{\[}}2 x i32{{\]}}, {{.*}}, i32 1
; VIRT-DAG: call <4 x i32> @llvm.masked.gather.v4i32.v4p0(
; VIRT: define i32 @protected_scatter_array({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: getelementptr {{\[}}2 x i32{{\]}}, {{.*}}, i32 1
; VIRT-DAG: call void @llvm.masked.scatter.v4i32.v4p0(
; VIRT-DAG: call <4 x i32> @llvm.masked.gather.v4i32.v4p0(
; VIRT: define i32 @protected_gather_wrap({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: getelementptr %Wrap, {{.*}}, i32 0, i32 1
; VIRT-DAG: call <4 x i32> @llvm.masked.gather.v4i32.v4p0(
; VIRT: define i32 @protected_scatter_wrap({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: getelementptr %Wrap, {{.*}}, i32 0, i32 1
; VIRT-DAG: call void @llvm.masked.scatter.v4i32.v4p0(
; VIRT-DAG: call <4 x i32> @llvm.masked.gather.v4i32.v4p0(
; VIRT: define i32 @protected_gather_pairarr({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: ptrtoint
; VIRT-NOT: inttoptr
; VIRT-DAG: getelementptr {{\[}}4 x %Pair{{\]}}, {{.*}}, i32 0, {{.*}}, i32 1
; VIRT-DAG: call <4 x i32> @llvm.masked.gather.v4i32.v4p0(
; VIRT: define i32 @protected_scatter_pairarr({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: ptrtoint
; VIRT-NOT: inttoptr
; VIRT-DAG: getelementptr {{\[}}4 x %Pair{{\]}}, {{.*}}, i32 0, {{.*}}, i32 1
; VIRT-DAG: call void @llvm.masked.scatter.v4i32.v4p0(
; VIRT-DAG: call <4 x i32> @llvm.masked.gather.v4i32.v4p0(
; VIRT: define i32 @protected_gather_pairarr_i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: getelementptr {{\[}}4 x %Pair{{\]}}, {{.*}}, i64 0, {{.*}}, i32 1
; VIRT-DAG: call <4 x i32> @llvm.masked.gather.v4i32.v4p0(
; VIRT: define i32 @protected_gather_ptrvec_loop({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: ptrtoint
; VIRT-NOT: inttoptr
; VIRT: call <4 x i32> @llvm.masked.gather.v4i32.v4p0(
; VIRT: define i32 @unsupported_gather_as1({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define i32 @unsupported_gather_wide_ptrs({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define i32 @unsupported_gather_wide_data({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define i32 @unsupported_gather_musttail({{.*}} #[[UNSUP_MT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call i32 @sink_i32(
; VIRT: define i32 @unsupported_gather_poison({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define i32 @unsupported_gather_fastcc({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define i32 @unsupported_ptrvec_arg({{.*}} #[[UNSUP_ARG:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define i32 @unsupported_gather_aos_dyn_lead({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define i32 @unsupported_gather_aos_nonzero_lead({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define i32 @unsupported_gather_aos_zero_array({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define i32 @unsupported_gather_aos_three_array({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define i32 @unsupported_gather_aos_four_index({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define i32 @unsupported_gather_aos_dyn_index({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define i32 @unsupported_gather_array_oob({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define i32 @unsupported_gather_vector_base({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"
; VIRT-NOT: attributes #[[UNSUP_MT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_ARG]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
