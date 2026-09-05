; Restricted fixed half vectors on existing llvm.masked.load / store and
; llvm.vector.reduce.fadd/fmul/fmin/fmax.  Replay is CallDescriptor only
; (F16 vector encoding, whitening, integrity, fake ops).  Masked: AS0,
; supported fixed width, matching <N x i1>, i32 power-of-2 align ImmArg,
; matching passthru/value; all-false null is not accessed.  Reduce: listed
; float ops, scalar half result, C CC, last-token function +fullfp16.
; Ordinary half-vector SSA and f32/f64 paths are not gated here.
;
; Host x86 lli/ORC cannot select llvm.vector.reduce.fmin/fmax.f16.  Those
; two stay FileCheck + AArch64 llc only (function +fullfp16, no global
; -mattr).  Masked load/store and fadd/fmul reduce stay on host lli.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP-O0 < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.ll > %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.live.ll > %t.o0.host.in.ll
; RUN: python3 %S/Inputs/vmp-drop-host-half-reduce-minmax.py %t.o0.host.in.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.ll > %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.live.ll > %t.o2.host.in.ll
; RUN: python3 %S/Inputs/vmp-drop-host-half-reduce-minmax.py %t.o2.host.in.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP-O0 < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.s7.ll > %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.s7.live.ll > %t.o0.s7.host.in.ll
; RUN: python3 %S/Inputs/vmp-drop-host-half-reduce-minmax.py %t.o0.s7.host.in.ll > %t.o0.s7.host.ll
; RUN: lli -force-interpreter %t.o0.s7.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.s7.ll > %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.s7.live.ll > %t.o2.s7.host.in.ll
; RUN: python3 %S/Inputs/vmp-drop-host-half-reduce-minmax.py %t.o2.s7.host.in.ll > %t.o2.s7.host.ll
; RUN: lli -force-interpreter %t.o2.s7.host.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()

declare <4 x half> @llvm.masked.load.v4f16.p0(ptr, i32, <4 x i1>, <4 x half>)
declare void @llvm.masked.store.v4f16.p0(<4 x half>, ptr, i32, <4 x i1>)
declare half @llvm.vector.reduce.fadd.v4f16(half, <4 x half>)
declare half @llvm.vector.reduce.fmul.v4f16(half, <4 x half>)
declare half @llvm.vector.reduce.fmin.v4f16(<4 x half>)
declare half @llvm.vector.reduce.fmax.v4f16(<4 x half>)

declare <4 x half> @llvm.masked.gather.v4f16.v4p0(<4 x ptr>, i32, <4 x i1>, <4 x half>)
declare void @llvm.masked.scatter.v4f16.v4p0(<4 x half>, <4 x ptr>, i32, <4 x i1>)
declare <4 x half> @llvm.masked.expandload.v4f16(ptr, <4 x i1>, <4 x half>)
declare void @llvm.masked.compressstore.v4f16(<4 x half>, ptr, <4 x i1>)
declare <vscale x 4 x half> @llvm.masked.load.nxv4f16.p0(ptr, i32, <vscale x 4 x i1>, <vscale x 4 x half>)
declare <16 x half> @llvm.masked.load.v16f16.p0(ptr, i32, <16 x i1>, <16 x half>)
declare <4 x half> @llvm.masked.load.v4f16.p1(ptr addrspace(1), i32, <4 x i1>, <4 x half>)
declare half @llvm.vector.reduce.fmin.v16f16(<16 x half>)
declare bfloat @llvm.vector.reduce.fmin.v4bf16(<4 x bfloat>)
declare half @llvm.vp.reduce.fadd.v4f16(half, <4 x half>, <4 x i1>, i32)
declare half @llvm.vector.reduce.fadd.nxv4f16(half, <vscale x 4 x half>)

@src.h4 = private global <4 x half> <half 0xH3C00, half 0xH4000, half 0xH4200, half 0xH3800>, align 8
@seed.h4 = private global <4 x half> <half 0xH4500, half 0xH4600, half 0xH4700, half 0xH4800>, align 8
@slot.as = private global <4 x half> zeroinitializer, align 8
@sentinel.null = private global i32 291, align 4

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

define i32 @fold_halfx4(<4 x half> %v) {
entry:
  %bits = bitcast <4 x half> %v to <4 x i16>
  %r = call i32 @fold_i16x4(<4 x i16> %bits)
  ret i32 %r
}

define i32 @bits_half(half %h) {
entry:
  %i = bitcast half %h to i16
  %z = zext i16 %i to i32
  ret i32 %z
}

define void @copy_h4(ptr %dst, ptr %src) {
entry:
  %v = load <4 x half>, ptr %src, align 8
  store <4 x half> %v, ptr %dst, align 8
  ret void
}

define <4 x half> @make_h4(half %a, half %b, half %c, half %d) {
entry:
  %v0 = insertelement <4 x half> poison, half %a, i32 0
  %v1 = insertelement <4 x half> %v0, half %b, i32 1
  %v2 = insertelement <4 x half> %v1, half %c, i32 2
  %v3 = insertelement <4 x half> %v2, half %d, i32 3
  ret <4 x half> %v3
}

; Masked half must virtualize without +fullfp16.
define i32 @reference_masked(ptr %p, <4 x half> %passthru, <4 x half> %storev, ptr %dst) noinline optnone {
entry:
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix3 = insertelement <4 x i1> %mix0, i1 true, i32 2
  %ld.mix = call <4 x half> @llvm.masked.load.v4f16.p0(ptr %p, i32 2, <4 x i1> %mix3, <4 x half> %passthru)
  %ld.all = call <4 x half> @llvm.masked.load.v4f16.p0(ptr %p, i32 2, <4 x i1> <i1 true, i1 true, i1 true, i1 true>, <4 x half> %passthru)
  %ld.none = call <4 x half> @llvm.masked.load.v4f16.p0(ptr %p, i32 2, <4 x i1> zeroinitializer, <4 x half> %passthru)
  call void @llvm.masked.store.v4f16.p0(<4 x half> %storev, ptr %dst, i32 2, <4 x i1> %mix3)
  %r0 = call i32 @fold_halfx4(<4 x half> %ld.mix)
  %r1 = call i32 @fold_halfx4(<4 x half> %ld.all)
  %r2 = call i32 @fold_halfx4(<4 x half> %ld.none)
  %memv = load <4 x half>, ptr %dst, align 2
  %rm = call i32 @fold_halfx4(<4 x half> %memv)
  %x0 = xor i32 %r0, %r1
  %x1 = xor i32 %r2, %rm
  %out = xor i32 %x0, %x1
  ret i32 %out
}

define i32 @protected_masked(ptr %p, <4 x half> %passthru, <4 x half> %storev, ptr %dst) noinline optnone {
entry:
  call void @hikari_vmp()
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix3 = insertelement <4 x i1> %mix0, i1 true, i32 2
  %ld.mix = call <4 x half> @llvm.masked.load.v4f16.p0(ptr %p, i32 2, <4 x i1> %mix3, <4 x half> %passthru)
  %ld.all = call <4 x half> @llvm.masked.load.v4f16.p0(ptr %p, i32 2, <4 x i1> <i1 true, i1 true, i1 true, i1 true>, <4 x half> %passthru)
  %ld.none = call <4 x half> @llvm.masked.load.v4f16.p0(ptr %p, i32 2, <4 x i1> zeroinitializer, <4 x half> %passthru)
  call void @llvm.masked.store.v4f16.p0(<4 x half> %storev, ptr %dst, i32 2, <4 x i1> %mix3)
  %r0 = call i32 @fold_halfx4(<4 x half> %ld.mix)
  %r1 = call i32 @fold_halfx4(<4 x half> %ld.all)
  %r2 = call i32 @fold_halfx4(<4 x half> %ld.none)
  %memv = load <4 x half>, ptr %dst, align 2
  %rm = call i32 @fold_halfx4(<4 x half> %memv)
  %x0 = xor i32 %r0, %r1
  %x1 = xor i32 %r2, %rm
  %out = xor i32 %x0, %x1
  ret i32 %out
}

define i32 @reference_null_inactive(<4 x half> %passthru, <4 x half> %storev) noinline optnone {
entry:
  %ld = call <4 x half> @llvm.masked.load.v4f16.p0(ptr null, i32 2, <4 x i1> zeroinitializer, <4 x half> %passthru)
  call void @llvm.masked.store.v4f16.p0(<4 x half> %storev, ptr null, i32 2, <4 x i1> zeroinitializer)
  %fold = call i32 @fold_halfx4(<4 x half> %ld)
  %s = load i32, ptr @sentinel.null, align 4
  %out = xor i32 %fold, %s
  ret i32 %out
}

define i32 @protected_null_inactive(<4 x half> %passthru, <4 x half> %storev) noinline optnone {
entry:
  call void @hikari_vmp()
  %ld = call <4 x half> @llvm.masked.load.v4f16.p0(ptr null, i32 2, <4 x i1> zeroinitializer, <4 x half> %passthru)
  call void @llvm.masked.store.v4f16.p0(<4 x half> %storev, ptr null, i32 2, <4 x i1> zeroinitializer)
  %fold = call i32 @fold_halfx4(<4 x half> %ld)
  %s = load i32, ptr @sentinel.null, align 4
  %out = xor i32 %fold, %s
  ret i32 %out
}

define i32 @reference_reduce_arith(<4 x half> %v) noinline optnone "target-features"="+neon,+fullfp16,+fp-armv8" {
entry:
  %fadd = call half @llvm.vector.reduce.fadd.v4f16(half 0xH0000, <4 x half> %v)
  %fmul = call half @llvm.vector.reduce.fmul.v4f16(half 0xH3C00, <4 x half> %v)
  %fadd.r = call reassoc half @llvm.vector.reduce.fadd.v4f16(half 0xH0000, <4 x half> %v)
  %b0 = call i32 @bits_half(half %fadd)
  %b1 = call i32 @bits_half(half %fmul)
  %b2 = call i32 @bits_half(half %fadd.r)
  %x0 = xor i32 %b0, %b1
  %out = xor i32 %x0, %b2
  ret i32 %out
}

define i32 @protected_reduce_arith(<4 x half> %v) noinline optnone "target-features"="+neon,+fullfp16,+fp-armv8" {
entry:
  call void @hikari_vmp()
  %fadd = call half @llvm.vector.reduce.fadd.v4f16(half 0xH0000, <4 x half> %v)
  %fmul = call half @llvm.vector.reduce.fmul.v4f16(half 0xH3C00, <4 x half> %v)
  %fadd.r = call reassoc half @llvm.vector.reduce.fadd.v4f16(half 0xH0000, <4 x half> %v)
  %b0 = call i32 @bits_half(half %fadd)
  %b1 = call i32 @bits_half(half %fmul)
  %b2 = call i32 @bits_half(half %fadd.r)
  %x0 = xor i32 %b0, %b1
  %out = xor i32 %x0, %b2
  ret i32 %out
}

; FileCheck + AArch64 llc only.  Host x86 cannot select fmin/fmax.f16.
define i32 @reference_reduce_minmax(<4 x half> %v) noinline optnone "target-features"="+neon,+fullfp16,+fp-armv8" {
entry:
  %fmin = call half @llvm.vector.reduce.fmin.v4f16(<4 x half> %v)
  %fmax = call half @llvm.vector.reduce.fmax.v4f16(<4 x half> %v)
  %fmin.n = call nnan ninf half @llvm.vector.reduce.fmin.v4f16(<4 x half> %v)
  %b0 = call i32 @bits_half(half %fmin)
  %b1 = call i32 @bits_half(half %fmax)
  %b2 = call i32 @bits_half(half %fmin.n)
  %x0 = xor i32 %b0, %b1
  %out = xor i32 %x0, %b2
  ret i32 %out
}

define i32 @protected_reduce_minmax(<4 x half> %v) noinline optnone "target-features"="+neon,+fullfp16,+fp-armv8" {
entry:
  call void @hikari_vmp()
  %fmin = call half @llvm.vector.reduce.fmin.v4f16(<4 x half> %v)
  %fmax = call half @llvm.vector.reduce.fmax.v4f16(<4 x half> %v)
  %fmin.n = call nnan ninf half @llvm.vector.reduce.fmin.v4f16(<4 x half> %v)
  %b0 = call i32 @bits_half(half %fmin)
  %b1 = call i32 @bits_half(half %fmax)
  %b2 = call i32 @bits_half(half %fmin.n)
  %x0 = xor i32 %b0, %b1
  %out = xor i32 %x0, %b2
  ret i32 %out
}

define i32 @reference_loop(ptr %src, <4 x half> %init, i1 %c, i32 %n) noinline optnone "target-features"="+neon,+fullfp16,+fp-armv8" {
entry:
  br i1 %c, label %loop, label %other

other:
  %alt = fadd <4 x half> %init, %init
  br label %join

loop:
  %i = phi i32 [ 0, %entry ], [ %i.next, %loop ]
  %acc = phi <4 x half> [ %init, %entry ], [ %acc.next, %loop ]
  %idx = zext i32 %i to i64
  %q = getelementptr inbounds half, ptr %src, i64 %idx
  %mask0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mask = insertelement <4 x i1> %mask0, i1 true, i32 1
  %ld = call <4 x half> @llvm.masked.load.v4f16.p0(ptr %q, i32 2, <4 x i1> %mask, <4 x half> %acc)
  %acc.next = fadd <4 x half> %acc, %ld
  %i.next = add i32 %i, 4
  %more = icmp slt i32 %i.next, %n
  br i1 %more, label %loop, label %join

join:
  %phi = phi <4 x half> [ %alt, %other ], [ %acc.next, %loop ]
  %r = call half @llvm.vector.reduce.fadd.v4f16(half 0xH0000, <4 x half> %phi)
  %b = call i32 @bits_half(half %r)
  %f = call i32 @fold_halfx4(<4 x half> %phi)
  %out = xor i32 %b, %f
  ret i32 %out
}

define i32 @protected_loop(ptr %src, <4 x half> %init, i1 %c, i32 %n) noinline optnone "target-features"="+neon,+fullfp16,+fp-armv8" {
entry:
  call void @hikari_vmp()
  br i1 %c, label %loop, label %other

other:
  %alt = fadd <4 x half> %init, %init
  br label %join

loop:
  %i = phi i32 [ 0, %entry ], [ %i.next, %loop ]
  %acc = phi <4 x half> [ %init, %entry ], [ %acc.next, %loop ]
  %idx = zext i32 %i to i64
  %q = getelementptr inbounds half, ptr %src, i64 %idx
  %mask0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mask = insertelement <4 x i1> %mask0, i1 true, i32 1
  %ld = call <4 x half> @llvm.masked.load.v4f16.p0(ptr %q, i32 2, <4 x i1> %mask, <4 x half> %acc)
  %acc.next = fadd <4 x half> %acc, %ld
  %i.next = add i32 %i, 4
  %more = icmp slt i32 %i.next, %n
  br i1 %more, label %loop, label %join

join:
  %phi = phi <4 x half> [ %alt, %other ], [ %acc.next, %loop ]
  %r = call half @llvm.vector.reduce.fadd.v4f16(half 0xH0000, <4 x half> %phi)
  %b = call i32 @bits_half(half %r)
  %f = call i32 @fold_halfx4(<4 x half> %phi)
  %out = xor i32 %b, %f
  ret i32 %out
}

; ----- negatives: selected, not virtualized -----

define i32 @unsupported_reduce_half_no_fullfp16(<4 x half> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.vector.reduce.fmin.v4f16(<4 x half> %v)
  %b = bitcast half %r to i16
  %z = zext i16 %b to i32
  ret i32 %z
}

define i32 @unsupported_reduce_half_fullfp16_disabled(<4 x half> %v) noinline optnone "target-features"="+neon,+fullfp16,-fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.vector.reduce.fadd.v4f16(half 0xH0000, <4 x half> %v)
  %b = bitcast half %r to i16
  %z = zext i16 %b to i32
  ret i32 %z
}

define i32 @protected_masked_gather_half(<4 x i1> %m, <4 x half> %t) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x half> @llvm.masked.gather.v4f16.v4p0(<4 x ptr> zeroinitializer, i32 2, <4 x i1> %m, <4 x half> %t)
  %e = extractelement <4 x half> %r, i32 0
  %b = bitcast half %e to i16
  %z = zext i16 %b to i32
  ret i32 %z
}

define void @protected_masked_scatter_half(<4 x half> %v, <4 x i1> %m) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.masked.scatter.v4f16.v4p0(<4 x half> %v, <4 x ptr> zeroinitializer, i32 2, <4 x i1> %m)
  ret void
}

define i32 @protected_masked_expand_half(ptr %p, <4 x i1> %m, <4 x half> %t) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x half> @llvm.masked.expandload.v4f16(ptr %p, <4 x i1> %m, <4 x half> %t)
  %e = extractelement <4 x half> %r, i32 0
  %b = bitcast half %e to i16
  %z = zext i16 %b to i32
  ret i32 %z
}

define void @protected_masked_compress_half(ptr %p, <4 x half> %v, <4 x i1> %m) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.masked.compressstore.v4f16(<4 x half> %v, ptr %p, <4 x i1> %m)
  ret void
}

define i32 @unsupported_masked_as1_half(<4 x i1> %m, <4 x half> %t) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x half> @llvm.masked.load.v4f16.p1(ptr addrspace(1) addrspacecast (ptr @slot.as to ptr addrspace(1)), i32 2, <4 x i1> %m, <4 x half> %t)
  %e = extractelement <4 x half> %r, i32 0
  %b = bitcast half %e to i16
  %z = zext i16 %b to i32
  ret i32 %z
}

define i32 @unsupported_masked_wide_half(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <16 x half> @llvm.masked.load.v16f16.p0(ptr %p, i32 2, <16 x i1> <i1 true, i1 true, i1 true, i1 true, i1 true, i1 true, i1 true, i1 true, i1 true, i1 true, i1 true, i1 true, i1 true, i1 true, i1 true, i1 true>, <16 x half> zeroinitializer)
  %e = extractelement <16 x half> %r, i32 0
  %b = bitcast half %e to i16
  %z = zext i16 %b to i32
  ret i32 %z
}

define i32 @unsupported_masked_scalable() noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x half> @llvm.masked.load.nxv4f16.p0(ptr @src.h4, i32 2, <vscale x 4 x i1> zeroinitializer, <vscale x 4 x half> zeroinitializer)
  ret i32 0
}

define i32 @unsupported_reduce_wide_half() noinline optnone "target-features"="+neon,+fullfp16,+fp-armv8" {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.vector.reduce.fmin.v16f16(<16 x half> zeroinitializer)
  %b = bitcast half %r to i16
  %z = zext i16 %b to i32
  ret i32 %z
}

define i32 @unsupported_reduce_vp_half(<4 x half> %v) noinline optnone "target-features"="+neon,+fullfp16,+fp-armv8" {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.vp.reduce.fadd.v4f16(half 0xH0000, <4 x half> %v, <4 x i1> <i1 true, i1 true, i1 true, i1 true>, i32 4)
  %b = bitcast half %r to i16
  %z = zext i16 %b to i32
  ret i32 %z
}

define i32 @unsupported_reduce_bfloat() noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.vector.reduce.fmin.v4bf16(<4 x bfloat> zeroinitializer)
  %e = fpext bfloat %r to float
  %b = bitcast float %e to i32
  ret i32 %b
}

define i32 @unsupported_reduce_scalable() noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.vector.reduce.fadd.nxv4f16(half 0xH0000, <vscale x 4 x half> zeroinitializer)
  ret i32 0
}

define i32 @unsupported_reduce_fastcc_half(<4 x half> %v) noinline optnone "target-features"="+neon,+fullfp16,+fp-armv8" {
entry:
  call void @hikari_vmp()
  %r = call fastcc half @llvm.vector.reduce.fadd.v4f16(half 0xH0000, <4 x half> %v)
  %b = bitcast half %r to i16
  %z = zext i16 %b to i32
  ret i32 %z
}

define i32 @main() {
entry:
  %d0 = alloca <4 x half>, align 8
  %d1 = alloca <4 x half>, align 8
  call void @copy_h4(ptr %d0, ptr @seed.h4)
  call void @copy_h4(ptr %d1, ptr @seed.h4)
  %pt = call <4 x half> @make_h4(half 0xH3C00, half 0xH4000, half 0xH4200, half 0xH4400)
  %sv = call <4 x half> @make_h4(half 0xH3800, half 0xH3C00, half 0xH4000, half 0xH4200)
  %em = call i32 @reference_masked(ptr @src.h4, <4 x half> %pt, <4 x half> %sv, ptr %d0)
  %pm = call i32 @protected_masked(ptr @src.h4, <4 x half> %pt, <4 x half> %sv, ptr %d1)
  %ok0 = icmp eq i32 %em, %pm
  %en = call i32 @reference_null_inactive(<4 x half> %pt, <4 x half> %sv)
  %pn = call i32 @protected_null_inactive(<4 x half> %pt, <4 x half> %sv)
  %ok1 = icmp eq i32 %en, %pn
  %expf = call i32 @fold_halfx4(<4 x half> %pt)
  %exps = load i32, ptr @sentinel.null, align 4
  %expn = xor i32 %expf, %exps
  %ok2 = icmp eq i32 %en, %expn
  %er = call i32 @reference_reduce_arith(<4 x half> %pt)
  %pr = call i32 @protected_reduce_arith(<4 x half> %pt)
  %ok3 = icmp eq i32 %er, %pr
  %el0 = call i32 @reference_loop(ptr @src.h4, <4 x half> %pt, i1 true, i32 4)
  %pl0 = call i32 @protected_loop(ptr @src.h4, <4 x half> %pt, i1 true, i32 4)
  %ok4 = icmp eq i32 %el0, %pl0
  %el1 = call i32 @reference_loop(ptr @src.h4, <4 x half> %sv, i1 false, i32 4)
  %pl1 = call i32 @protected_loop(ptr @src.h4, <4 x half> %sv, i1 false, i32 4)
  %ok5 = icmp eq i32 %el1, %pl1
  %t0 = and i1 %ok0, %ok1
  %t1 = and i1 %ok2, %ok3
  %t2 = and i1 %ok4, %ok5
  %t3 = and i1 %t0, %t1
  %ok = and i1 %t3, %t2
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP-DAG: Skipping VMP on unsupported_reduce_half_no_fullfp16: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_reduce_half_fullfp16_disabled: unsupported target feature
; SKIP-NOT: Skipping VMP on protected_masked_gather_half:
; SKIP-NOT: Skipping VMP on protected_masked_scatter_half:
; SKIP-NOT: Skipping VMP on protected_masked_expand_half:
; SKIP-NOT: Skipping VMP on protected_masked_compress_half:
; SKIP-DAG: Skipping VMP on unsupported_masked_as1_half: unsupported masked memory instruction
; SKIP-DAG: Skipping VMP on unsupported_masked_wide_half: unsupported masked memory instruction
; SKIP-DAG: Skipping VMP on unsupported_reduce_vp_half: unsupported vector reduce instruction
; SKIP-DAG: Skipping VMP on unsupported_reduce_fastcc_half: unsupported vector reduce instruction
; SKIP-NOT: Skipping VMP on protected_masked:
; SKIP-NOT: Skipping VMP on protected_null_inactive:
; SKIP-NOT: Skipping VMP on protected_reduce_arith:
; SKIP-NOT: Skipping VMP on protected_reduce_minmax:
; SKIP-NOT: Skipping VMP on protected_loop:
; SKIP-NOT: Skipping VMP on reference_masked:
; SKIP-NOT: Skipping VMP on reference_reduce_arith:
; Constant scalable forms can fold under default<O2>.
; SKIP-O0-DAG: Skipping VMP on unsupported_masked_scalable: unsupported masked memory instruction
; SKIP-O0-DAG: Skipping VMP on unsupported_reduce_scalable: unsupported vector reduce instruction
; SKIP-O0-DAG: Skipping VMP on unsupported_reduce_wide_half: unsupported vector reduce instruction
; SKIP-O0-DAG: Skipping VMP on unsupported_reduce_bfloat: unsupported target feature

; VIRT-LABEL: define i32 @protected_masked(
; VIRT: vmp.dispatch:
; VIRT-DAG: call <4 x half> @llvm.masked.load.v4f16.p0(ptr {{.*}}, i32 2,
; VIRT-DAG: call void @llvm.masked.store.v4f16.p0(<4 x half> {{.*}}, ptr {{.*}}, i32 2,

; VIRT-LABEL: define i32 @protected_null_inactive(
; VIRT: vmp.dispatch:
; VIRT-DAG: call <4 x half> @llvm.masked.load.v4f16.p0(ptr {{.*}}, i32 2,
; VIRT-DAG: call void @llvm.masked.store.v4f16.p0(<4 x half> {{.*}}, ptr {{.*}}, i32 2,

; VIRT-LABEL: define i32 @protected_reduce_arith(
; VIRT: vmp.dispatch:
; VIRT-DAG: call half @llvm.vector.reduce.fadd.v4f16(
; VIRT-DAG: call half @llvm.vector.reduce.fmul.v4f16(
; VIRT-DAG: call reassoc half @llvm.vector.reduce.fadd.v4f16(

; VIRT-LABEL: define i32 @protected_reduce_minmax(
; VIRT: vmp.dispatch:
; VIRT-DAG: call half @llvm.vector.reduce.fmin.v4f16(
; VIRT-DAG: call half @llvm.vector.reduce.fmax.v4f16(
; VIRT-DAG: call nnan ninf half @llvm.vector.reduce.fmin.v4f16(

; VIRT-LABEL: define i32 @protected_loop(
; VIRT: vmp.dispatch:
; VIRT-DAG: call <4 x half> @llvm.masked.load.v4f16.p0(ptr {{.*}}, i32 2,
; VIRT-DAG: call half @llvm.vector.reduce.fadd.v4f16(
; VIRT-DAG: fadd <4 x half>

; VIRT: define {{.*}} @unsupported_reduce_half_no_fullfp16({{.*}} #[[UNSUPATTR:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_reduce_half_fullfp16_disabled({{.*}} #[[UNSUPFEAT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @protected_masked_gather_half({{.*}}
; VIRT: vmp.dispatch:
; VIRT: call <4 x half> @llvm.masked.gather.v4f16.v4p0(
; VIRT: define {{.*}} @protected_masked_scatter_half({{.*}}
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.masked.scatter.v4f16.v4p0(
; VIRT: define {{.*}} @protected_masked_expand_half({{.*}}
; VIRT: vmp.dispatch:
; VIRT: call <4 x half> @llvm.masked.expandload.v4f16(
; VIRT: define {{.*}} @protected_masked_compress_half({{.*}}
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.masked.compressstore.v4f16(
; VIRT: define {{.*}} @unsupported_masked_as1_half({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_masked_wide_half({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_reduce_wide_half(
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_reduce_vp_half(
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_reduce_bfloat({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_reduce_fastcc_half(
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #{{[0-9]+}} = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT: attributes #[[UNSUPFEAT]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPFEAT]] = { {{.*}}"hikari.vmp.virtualized"
