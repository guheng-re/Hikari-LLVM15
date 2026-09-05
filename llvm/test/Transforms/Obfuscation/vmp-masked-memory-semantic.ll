; Restricted llvm.masked.load / llvm.masked.store /
; llvm.masked.expandload / llvm.masked.compressstore on the fixed-vector
; VMP surface: AS0 ptr, <N x i1> mask, matching passthru/value.  load/store
; keep an i32 alignment ImmArg; expand/compress have no alignment operand.
; Replayed via CallDescriptor.  Inactive lanes stay unaccessed.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP-O0 < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.ll > %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.live.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.ll > %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.live.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP-O0 < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()

declare <4 x i32> @llvm.masked.load.v4i32.p0(ptr, i32, <4 x i1>, <4 x i32>)
declare void @llvm.masked.store.v4i32.p0(<4 x i32>, ptr, i32, <4 x i1>)
declare <4 x float> @llvm.masked.load.v4f32.p0(ptr, i32, <4 x i1>, <4 x float>)
declare void @llvm.masked.store.v4f32.p0(<4 x float>, ptr, i32, <4 x i1>)
declare <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr>, i32, <4 x i1>, <4 x i32>)
declare void @llvm.masked.scatter.v4i32.v4p0(<4 x i32>, <4 x ptr>, i32, <4 x i1>)
declare <4 x i32> @llvm.masked.expandload.v4i32(ptr, <4 x i1>, <4 x i32>)
declare void @llvm.masked.compressstore.v4i32(<4 x i32>, ptr, <4 x i1>)
declare <vscale x 4 x i32> @llvm.masked.load.nxv4i32.p0(ptr, i32, <vscale x 4 x i1>, <vscale x 4 x i32>)
declare <8 x i32> @llvm.masked.load.v8i32.p0(ptr, i32, <8 x i1>, <8 x i32>)
declare <4 x half> @llvm.masked.expandload.v4f16(ptr, <4 x i1>, <4 x half>)
declare <4 x i32> @llvm.masked.load.v4i32.p1(ptr addrspace(1), i32, <4 x i1>, <4 x i32>)
declare void @llvm.masked.store.v2p0.p0(<2 x ptr>, ptr, i32, <2 x i1>)

@src.i32 = private global [8 x i32] [i32 10, i32 20, i32 30, i32 40, i32 50, i32 60, i32 70, i32 80], align 16
@pred.i32 = private global [8 x i32] [i32 -1, i32 1, i32 -2, i32 2, i32 -3, i32 3, i32 -4, i32 4], align 16
@src.f32 = private global [4 x float] [float 1.000000e+00, float 2.000000e+00, float 3.000000e+00, float 4.000000e+00], align 16
@slot.as = private global [4 x i32] zeroinitializer, align 16
@sentinel.null = private global i32 291, align 4

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

; Mixed-mask load: inactive lanes keep passthru.  Store: inactive lanes
; leave prior memory.  Several masks (mixed / all-true / all-false).
define i32 @reference_i32(ptr %p, <4 x i32> %passthru, <4 x i32> %storev, ptr %dst) noinline optnone {
entry:
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix3 = insertelement <4 x i1> %mix0, i1 true, i32 2
  %ld.mix = call <4 x i32> @llvm.masked.load.v4i32.p0(ptr %p, i32 4, <4 x i1> %mix3, <4 x i32> %passthru)
  %ld.all = call <4 x i32> @llvm.masked.load.v4i32.p0(ptr %p, i32 4, <4 x i1> <i1 true, i1 true, i1 true, i1 true>, <4 x i32> %passthru)
  %ld.none = call <4 x i32> @llvm.masked.load.v4i32.p0(ptr %p, i32 4, <4 x i1> zeroinitializer, <4 x i32> %passthru)
  call void @llvm.masked.store.v4i32.p0(<4 x i32> %storev, ptr %dst, i32 4, <4 x i1> %mix3)
  %r0 = call i32 @fold_i32x4(<4 x i32> %ld.mix)
  %r1 = call i32 @fold_i32x4(<4 x i32> %ld.all)
  %r2 = call i32 @fold_i32x4(<4 x i32> %ld.none)
  %mem = call i32 @fold_mem4(ptr %dst)
  %x0 = xor i32 %r0, %r1
  %x1 = xor i32 %r2, %mem
  %out = xor i32 %x0, %x1
  ret i32 %out
}

define i32 @protected_i32(ptr %p, <4 x i32> %passthru, <4 x i32> %storev, ptr %dst) noinline optnone {
entry:
  call void @hikari_vmp()
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix3 = insertelement <4 x i1> %mix0, i1 true, i32 2
  %ld.mix = call <4 x i32> @llvm.masked.load.v4i32.p0(ptr %p, i32 4, <4 x i1> %mix3, <4 x i32> %passthru)
  %ld.all = call <4 x i32> @llvm.masked.load.v4i32.p0(ptr %p, i32 4, <4 x i1> <i1 true, i1 true, i1 true, i1 true>, <4 x i32> %passthru)
  %ld.none = call <4 x i32> @llvm.masked.load.v4i32.p0(ptr %p, i32 4, <4 x i1> zeroinitializer, <4 x i32> %passthru)
  call void @llvm.masked.store.v4i32.p0(<4 x i32> %storev, ptr %dst, i32 4, <4 x i1> %mix3)
  %r0 = call i32 @fold_i32x4(<4 x i32> %ld.mix)
  %r1 = call i32 @fold_i32x4(<4 x i32> %ld.all)
  %r2 = call i32 @fold_i32x4(<4 x i32> %ld.none)
  %mem = call i32 @fold_mem4(ptr %dst)
  %x0 = xor i32 %r0, %r1
  %x1 = xor i32 %r2, %mem
  %out = xor i32 %x0, %x1
  ret i32 %out
}

define i32 @reference_f32(ptr %p, <4 x float> %passthru, <4 x float> %storev, ptr %dst) noinline optnone {
entry:
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix3 = insertelement <4 x i1> %mix0, i1 true, i32 2
  %ld = call <4 x float> @llvm.masked.load.v4f32.p0(ptr %p, i32 4, <4 x i1> %mix3, <4 x float> %passthru)
  call void @llvm.masked.store.v4f32.p0(<4 x float> %storev, ptr %dst, i32 4, <4 x i1> %mix3)
  %bits = bitcast <4 x float> %ld to <4 x i32>
  %r0 = call i32 @fold_i32x4(<4 x i32> %bits)
  %memf = load <4 x float>, ptr %dst, align 4
  %memb = bitcast <4 x float> %memf to <4 x i32>
  %r1 = call i32 @fold_i32x4(<4 x i32> %memb)
  %out = xor i32 %r0, %r1
  ret i32 %out
}

define i32 @protected_f32(ptr %p, <4 x float> %passthru, <4 x float> %storev, ptr %dst) noinline optnone {
entry:
  call void @hikari_vmp()
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix3 = insertelement <4 x i1> %mix0, i1 true, i32 2
  %ld = call <4 x float> @llvm.masked.load.v4f32.p0(ptr %p, i32 4, <4 x i1> %mix3, <4 x float> %passthru)
  call void @llvm.masked.store.v4f32.p0(<4 x float> %storev, ptr %dst, i32 4, <4 x i1> %mix3)
  %bits = bitcast <4 x float> %ld to <4 x i32>
  %r0 = call i32 @fold_i32x4(<4 x i32> %bits)
  %memf = load <4 x float>, ptr %dst, align 4
  %memb = bitcast <4 x float> %memf to <4 x i32>
  %r1 = call i32 @fold_i32x4(<4 x i32> %memb)
  %out = xor i32 %r0, %r1
  ret i32 %out
}

; Conditional auto-vec leftover: mask from pred[i]<0, load src, store dest.
define i32 @reference_loop(ptr %src, ptr %dst, ptr %pred, i32 %n) noinline optnone {
entry:
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %i.next, %loop ]
  %idx = zext i32 %i to i64
  %sp = getelementptr inbounds i32, ptr %src, i64 %idx
  %dp = getelementptr inbounds i32, ptr %dst, i64 %idx
  %pp = getelementptr inbounds i32, ptr %pred, i64 %idx
  %pv = load <4 x i32>, ptr %pp, align 4
  %mask = icmp slt <4 x i32> %pv, zeroinitializer
  %passthru = load <4 x i32>, ptr %dp, align 4
  %ld = call <4 x i32> @llvm.masked.load.v4i32.p0(ptr %sp, i32 4, <4 x i1> %mask, <4 x i32> %passthru)
  call void @llvm.masked.store.v4i32.p0(<4 x i32> %ld, ptr %dp, i32 4, <4 x i1> %mask)
  %i.next = add i32 %i, 4
  %more = icmp slt i32 %i.next, %n
  br i1 %more, label %loop, label %done

done:
  %r0 = call i32 @fold_mem4(ptr %dst)
  %q = getelementptr inbounds i32, ptr %dst, i64 4
  %r1 = call i32 @fold_mem4(ptr %q)
  %out = xor i32 %r0, %r1
  ret i32 %out
}

define i32 @protected_loop(ptr %src, ptr %dst, ptr %pred, i32 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %i.next, %loop ]
  %idx = zext i32 %i to i64
  %sp = getelementptr inbounds i32, ptr %src, i64 %idx
  %dp = getelementptr inbounds i32, ptr %dst, i64 %idx
  %pp = getelementptr inbounds i32, ptr %pred, i64 %idx
  %pv = load <4 x i32>, ptr %pp, align 4
  %mask = icmp slt <4 x i32> %pv, zeroinitializer
  %passthru = load <4 x i32>, ptr %dp, align 4
  %ld = call <4 x i32> @llvm.masked.load.v4i32.p0(ptr %sp, i32 4, <4 x i1> %mask, <4 x i32> %passthru)
  call void @llvm.masked.store.v4i32.p0(<4 x i32> %ld, ptr %dp, i32 4, <4 x i1> %mask)
  %i.next = add i32 %i, 4
  %more = icmp slt i32 %i.next, %n
  br i1 %more, label %loop, label %done

done:
  %r0 = call i32 @fold_mem4(ptr %dst)
  %q = getelementptr inbounds i32, ptr %dst, i64 4
  %r1 = call i32 @fold_mem4(ptr %q)
  %out = xor i32 %r0, %r1
  ret i32 %out
}

; All-false mask on ptr null: load must yield passthru, store must not
; touch memory or the separate sentinel.
define i32 @reference_null_inactive(<4 x i32> %passthru, <4 x i32> %storev) noinline optnone {
entry:
  %ld = call <4 x i32> @llvm.masked.load.v4i32.p0(ptr null, i32 4, <4 x i1> zeroinitializer, <4 x i32> %passthru)
  call void @llvm.masked.store.v4i32.p0(<4 x i32> %storev, ptr null, i32 4, <4 x i1> zeroinitializer)
  %fold = call i32 @fold_i32x4(<4 x i32> %ld)
  %s = load i32, ptr @sentinel.null, align 4
  %out = xor i32 %fold, %s
  ret i32 %out
}

define i32 @protected_null_inactive(<4 x i32> %passthru, <4 x i32> %storev) noinline optnone {
entry:
  call void @hikari_vmp()
  %ld = call <4 x i32> @llvm.masked.load.v4i32.p0(ptr null, i32 4, <4 x i1> zeroinitializer, <4 x i32> %passthru)
  call void @llvm.masked.store.v4i32.p0(<4 x i32> %storev, ptr null, i32 4, <4 x i1> zeroinitializer)
  %fold = call i32 @fold_i32x4(<4 x i32> %ld)
  %s = load i32, ptr @sentinel.null, align 4
  %out = xor i32 %fold, %s
  ret i32 %out
}

; ----- negatives: selected, not virtualized -----

define i32 @protected_masked_gather(<4 x i1> %m, <4 x i32> %t) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> zeroinitializer, i32 4, <4 x i1> %m, <4 x i32> %t)
  %e = extractelement <4 x i32> %r, i32 0
  ret i32 %e
}

define void @protected_masked_scatter(<4 x i32> %v, <4 x i1> %m) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.masked.scatter.v4i32.v4p0(<4 x i32> %v, <4 x ptr> zeroinitializer, i32 4, <4 x i1> %m)
  ret void
}

define i32 @protected_masked_expand(ptr %p, <4 x i1> %m, <4 x i32> %t) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.masked.expandload.v4i32(ptr %p, <4 x i1> %m, <4 x i32> %t)
  %e = extractelement <4 x i32> %r, i32 0
  ret i32 %e
}

define void @protected_masked_compress(ptr %p, <4 x i32> %v, <4 x i1> %m) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.masked.compressstore.v4i32(<4 x i32> %v, ptr %p, <4 x i1> %m)
  ret void
}

define i32 @unsupported_masked_scalable() noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.masked.load.nxv4i32.p0(ptr @src.i32, i32 4, <vscale x 4 x i1> zeroinitializer, <vscale x 4 x i32> zeroinitializer)
  ret i32 0
}

define i32 @unsupported_masked_wide(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i32> @llvm.masked.load.v8i32.p0(ptr %p, i32 4, <8 x i1> <i1 true, i1 true, i1 true, i1 true, i1 true, i1 true, i1 true, i1 true>, <8 x i32> zeroinitializer)
  %e = extractelement <8 x i32> %r, i32 0
  ret i32 %e
}

; Half expandload is on the same surface as half masked.load/store.
; Named protected_* so vmp-drop-unsupported.py keeps it for llc.
define i32 @protected_masked_half(ptr %p, <4 x i1> %m) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x half> @llvm.masked.expandload.v4f16(ptr %p, <4 x i1> %m, <4 x half> zeroinitializer)
  %e = extractelement <4 x half> %r, i32 0
  %f = fpext half %e to float
  %b = bitcast float %f to i32
  ret i32 %b
}

define i32 @unsupported_masked_as1(<4 x i1> %m, <4 x i32> %t) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.masked.load.v4i32.p1(ptr addrspace(1) addrspacecast (ptr @slot.as to ptr addrspace(1)), i32 4, <4 x i1> %m, <4 x i32> %t)
  %e = extractelement <4 x i32> %r, i32 0
  ret i32 %e
}

define ptr @unsupported_masked_ptrvec(ptr %p, <2 x i1> %m) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.masked.store.v2p0.p0(<2 x ptr> zeroinitializer, ptr %p, i32 8, <2 x i1> %m)
  ret ptr %p
}

define i32 @unsupported_masked_fastcc(ptr %p, <4 x i1> %m, <4 x i32> %t) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc <4 x i32> @llvm.masked.load.v4i32.p0(ptr %p, i32 4, <4 x i1> %m, <4 x i32> %t)
  %e = extractelement <4 x i32> %r, i32 0
  ret i32 %e
}

define void @copy4(ptr %dst, ptr %src) {
entry:
  %v = load <4 x i32>, ptr %src, align 4
  store <4 x i32> %v, ptr %dst, align 4
  ret void
}

define void @copy8(ptr %dst, ptr %src) {
entry:
  %v0 = load <4 x i32>, ptr %src, align 4
  store <4 x i32> %v0, ptr %dst, align 4
  %s = getelementptr inbounds i32, ptr %src, i64 4
  %d = getelementptr inbounds i32, ptr %dst, i64 4
  %v1 = load <4 x i32>, ptr %s, align 4
  store <4 x i32> %v1, ptr %d, align 4
  ret void
}

define i32 @main() {
entry:
  %d0 = alloca [4 x i32], align 16
  %d1 = alloca [4 x i32], align 16
  %f0 = alloca [4 x float], align 16
  %f1 = alloca [4 x float], align 16
  %l0 = alloca [8 x i32], align 16
  %l1 = alloca [8 x i32], align 16

  call void @copy4(ptr %d0, ptr @src.i32)
  call void @copy4(ptr %d1, ptr @src.i32)
  call void @copy4(ptr %f0, ptr @src.f32)
  call void @copy4(ptr %f1, ptr @src.f32)
  call void @copy8(ptr %l0, ptr @src.i32)
  call void @copy8(ptr %l1, ptr @src.i32)

  %pt0 = insertelement <4 x i32> poison, i32 1, i32 0
  %pt1 = insertelement <4 x i32> %pt0, i32 2, i32 1
  %pt2 = insertelement <4 x i32> %pt1, i32 3, i32 2
  %pt3 = insertelement <4 x i32> %pt2, i32 4, i32 3
  %sv0 = insertelement <4 x i32> poison, i32 9, i32 0
  %sv1 = insertelement <4 x i32> %sv0, i32 8, i32 1
  %sv2 = insertelement <4 x i32> %sv1, i32 7, i32 2
  %sv3 = insertelement <4 x i32> %sv2, i32 6, i32 3

  %ei = call i32 @reference_i32(ptr @src.i32, <4 x i32> %pt3, <4 x i32> %sv3, ptr %d0)
  %ai = call i32 @protected_i32(ptr @src.i32, <4 x i32> %pt3, <4 x i32> %sv3, ptr %d1)
  %ok0 = icmp eq i32 %ei, %ai

  %fpt = sitofp <4 x i32> %pt3 to <4 x float>
  %fsv = sitofp <4 x i32> %sv3 to <4 x float>
  %ef = call i32 @reference_f32(ptr @src.f32, <4 x float> %fpt, <4 x float> %fsv, ptr %f0)
  %af = call i32 @protected_f32(ptr @src.f32, <4 x float> %fpt, <4 x float> %fsv, ptr %f1)
  %ok1 = icmp eq i32 %ef, %af

  %el = call i32 @reference_loop(ptr @src.i32, ptr %l0, ptr @pred.i32, i32 8)
  %al = call i32 @protected_loop(ptr @src.i32, ptr %l1, ptr @pred.i32, i32 8)
  %ok2 = icmp eq i32 %el, %al

  %en = call i32 @reference_null_inactive(<4 x i32> %pt3, <4 x i32> %sv3)
  %an = call i32 @protected_null_inactive(<4 x i32> %pt3, <4 x i32> %sv3)
  %ok3 = icmp eq i32 %en, %an
  %expf = call i32 @fold_i32x4(<4 x i32> %pt3)
  %exps = load i32, ptr @sentinel.null, align 4
  %expn = xor i32 %expf, %exps
  %ok4 = icmp eq i32 %en, %expn

  %t0 = and i1 %ok0, %ok1
  %t1 = and i1 %ok2, %ok3
  %t2 = and i1 %t0, %t1
  %ok = and i1 %t2, %ok4
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP-NOT: Skipping VMP on protected_masked_gather:
; SKIP-NOT: Skipping VMP on protected_masked_scatter:
; SKIP-DAG: Skipping VMP on unsupported_masked_wide: unsupported masked memory instruction
; SKIP-DAG: Skipping VMP on unsupported_masked_as1: unsupported masked memory instruction
; SKIP-DAG: Skipping VMP on unsupported_masked_ptrvec: unsupported masked memory instruction
; SKIP-DAG: Skipping VMP on unsupported_masked_fastcc: unsupported masked memory instruction
; SKIP-NOT: Skipping VMP on protected_masked_expand:
; SKIP-NOT: Skipping VMP on protected_masked_compress:
; SKIP-NOT: Skipping VMP on protected_masked_half:
; SKIP-NOT: Skipping VMP on protected_i32:
; SKIP-NOT: Skipping VMP on protected_f32:
; SKIP-NOT: Skipping VMP on protected_loop:
; SKIP-NOT: Skipping VMP on protected_null_inactive:
; Well-shaped SVE masked.load without last-token +sve: feature miss.
; Accepted SVE integer masked.load/store: vmp-sve-masked-memory-semantic.ll.
; Constant scalable masked.load can fold under default<O2>.
; SKIP-O0-DAG: Skipping VMP on unsupported_masked_scalable: unsupported target feature

; VIRT-LABEL: define i32 @protected_i32(
; VIRT: vmp.dispatch:
; VIRT-DAG: call <4 x i32> @llvm.masked.load.v4i32.p0(ptr {{.*}}, i32 4,
; VIRT-DAG: call void @llvm.masked.store.v4i32.p0(<4 x i32> {{.*}}, ptr {{.*}}, i32 4,

; VIRT-LABEL: define i32 @protected_f32(
; VIRT: vmp.dispatch:
; VIRT-DAG: call <4 x float> @llvm.masked.load.v4f32.p0(ptr {{.*}}, i32 4,
; VIRT-DAG: call void @llvm.masked.store.v4f32.p0(<4 x float> {{.*}}, ptr {{.*}}, i32 4,

; VIRT-LABEL: define i32 @protected_loop(
; VIRT: vmp.dispatch:
; VIRT-DAG: call <4 x i32> @llvm.masked.load.v4i32.p0(ptr {{.*}}, i32 4,
; VIRT-DAG: call void @llvm.masked.store.v4i32.p0(<4 x i32> {{.*}}, ptr {{.*}}, i32 4,

; VIRT-LABEL: define i32 @protected_null_inactive(
; VIRT: vmp.dispatch:
; VIRT-DAG: call <4 x i32> @llvm.masked.load.v4i32.p0(ptr {{.*}}, i32 4,
; VIRT-DAG: call void @llvm.masked.store.v4i32.p0(<4 x i32> {{.*}}, ptr {{.*}}, i32 4,

; VIRT-LABEL: define {{.*}} @protected_masked_gather(
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.masked.gather.v4i32.v4p0(
; VIRT-LABEL: define {{.*}} @protected_masked_scatter(
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.masked.scatter.v4i32.v4p0(
; VIRT-LABEL: define {{.*}} @protected_masked_expand(
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.masked.expandload.v4i32(
; VIRT-LABEL: define {{.*}} @protected_masked_compress(
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.masked.compressstore.v4i32(
; VIRT-LABEL: define {{.*}} @unsupported_masked_scalable(
; VIRT-LABEL: define {{.*}} @unsupported_masked_wide(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @protected_masked_half(
; VIRT: vmp.dispatch:
; VIRT: call <4 x half> @llvm.masked.expandload.v4f16(
; VIRT-LABEL: define {{.*}} @unsupported_masked_as1(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_masked_ptrvec(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_masked_fastcc(
; VIRT-NOT: vmp.dispatch
; VIRT: "hikari.vmp.virtualized"
