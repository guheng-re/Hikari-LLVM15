; Poison/undef vector construction: insertelement into a whole-value
; poison/undef base, and shufflevector with a poison/undef unused
; operand.  This is the Clang/LLVM splat and build sequence
; (`insertelement poison, %x, 0` then `shufflevector %v, poison,
; zeroinitializer`).  Bases are materialized at the handler; they are
; never stored in a VReg.  Inserted elements, extract sources,
; arithmetic, and call arguments still reject poison/undef.
;
; Data vectors: i8/i16/i32/i64/float/half, total width 1..128.
; Pointer-vector insert into poison is the gather-address build form.
; Ordinary tail is not part of this surface.
;
; Rejected: poison inserted element, extract of poison, arithmetic on
; poison, scalable, overwide, fp128/ppc vectors.
;
; Host lli executes native insertelement/shufflevector.  FileCheck +
; lli + AArch64 llc/readobj.  O0/O2 x aesSeed 97/7.
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

define i32 @fold4(<4 x i32> %v) {
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

; ----- positives -----

define <4 x i32> @reference_build(i32 %a, i32 %b, i32 %c, i32 %d) noinline {
entry:
  %v0 = insertelement <4 x i32> poison, i32 %a, i32 0
  %v1 = insertelement <4 x i32> %v0, i32 %b, i32 1
  %v2 = insertelement <4 x i32> %v1, i32 %c, i32 2
  %v3 = insertelement <4 x i32> %v2, i32 %d, i32 3
  ret <4 x i32> %v3
}

define <4 x i32> @protected_build(i32 %a, i32 %b, i32 %c, i32 %d) noinline optnone {
entry:
  call void @hikari_vmp()
  %v0 = insertelement <4 x i32> poison, i32 %a, i32 0
  %v1 = insertelement <4 x i32> %v0, i32 %b, i32 1
  %v2 = insertelement <4 x i32> %v1, i32 %c, i32 2
  %v3 = insertelement <4 x i32> %v2, i32 %d, i32 3
  ret <4 x i32> %v3
}

define <4 x i32> @reference_undef_base(i32 %a) noinline {
entry:
  %v0 = insertelement <4 x i32> undef, i32 %a, i32 0
  %v1 = insertelement <4 x i32> %v0, i32 %a, i32 1
  %v2 = insertelement <4 x i32> %v1, i32 %a, i32 2
  %v3 = insertelement <4 x i32> %v2, i32 %a, i32 3
  ret <4 x i32> %v3
}

define <4 x i32> @protected_undef_base(i32 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %v0 = insertelement <4 x i32> undef, i32 %a, i32 0
  %v1 = insertelement <4 x i32> %v0, i32 %a, i32 1
  %v2 = insertelement <4 x i32> %v1, i32 %a, i32 2
  %v3 = insertelement <4 x i32> %v2, i32 %a, i32 3
  ret <4 x i32> %v3
}

define <4 x i32> @reference_splat(i32 %x) noinline {
entry:
  %v0 = insertelement <4 x i32> poison, i32 %x, i32 0
  %s = shufflevector <4 x i32> %v0, <4 x i32> poison, <4 x i32> zeroinitializer
  ret <4 x i32> %s
}

define <4 x i32> @protected_splat(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %v0 = insertelement <4 x i32> poison, i32 %x, i32 0
  %s = shufflevector <4 x i32> %v0, <4 x i32> poison, <4 x i32> zeroinitializer
  ret <4 x i32> %s
}

define <4 x float> @reference_splat_f32(float %x) noinline {
entry:
  %v0 = insertelement <4 x float> poison, float %x, i32 0
  %s = shufflevector <4 x float> %v0, <4 x float> poison, <4 x i32> zeroinitializer
  ret <4 x float> %s
}

define <4 x float> @protected_splat_f32(float %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %v0 = insertelement <4 x float> poison, float %x, i32 0
  %s = shufflevector <4 x float> %v0, <4 x float> poison, <4 x i32> zeroinitializer
  ret <4 x float> %s
}

define <8 x i16> @reference_build_i16(i16 %a, i16 %b) noinline {
entry:
  %v0 = insertelement <8 x i16> poison, i16 %a, i32 0
  %v1 = insertelement <8 x i16> %v0, i16 %b, i32 1
  %s = shufflevector <8 x i16> %v1, <8 x i16> poison, <8 x i32> <i32 0, i32 1, i32 0, i32 1, i32 0, i32 1, i32 0, i32 1>
  ret <8 x i16> %s
}

define <8 x i16> @protected_build_i16(i16 %a, i16 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %v0 = insertelement <8 x i16> poison, i16 %a, i32 0
  %v1 = insertelement <8 x i16> %v0, i16 %b, i32 1
  %s = shufflevector <8 x i16> %v1, <8 x i16> poison, <8 x i32> <i32 0, i32 1, i32 0, i32 1, i32 0, i32 1, i32 0, i32 1>
  ret <8 x i16> %s
}

define <8 x i8> @reference_build_i8(i8 %a) noinline {
entry:
  %v0 = insertelement <8 x i8> poison, i8 %a, i32 0
  %s = shufflevector <8 x i8> %v0, <8 x i8> undef, <8 x i32> zeroinitializer
  ret <8 x i8> %s
}

define <8 x i8> @protected_build_i8(i8 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %v0 = insertelement <8 x i8> poison, i8 %a, i32 0
  %s = shufflevector <8 x i8> %v0, <8 x i8> undef, <8 x i32> zeroinitializer
  ret <8 x i8> %s
}

define <4 x half> @reference_splat_half(half %x) noinline {
entry:
  %v0 = insertelement <4 x half> poison, half %x, i32 0
  %s = shufflevector <4 x half> %v0, <4 x half> poison, <4 x i32> zeroinitializer
  ret <4 x half> %s
}

define <4 x half> @protected_splat_half(half %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %v0 = insertelement <4 x half> poison, half %x, i32 0
  %s = shufflevector <4 x half> %v0, <4 x half> poison, <4 x i32> zeroinitializer
  ret <4 x half> %s
}

define <2 x i64> @reference_build_i64(i64 %a, i64 %b) noinline {
entry:
  %v0 = insertelement <2 x i64> poison, i64 %a, i32 0
  %v1 = insertelement <2 x i64> %v0, i64 %b, i32 1
  ret <2 x i64> %v1
}

define <2 x i64> @protected_build_i64(i64 %a, i64 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %v0 = insertelement <2 x i64> poison, i64 %a, i32 0
  %v1 = insertelement <2 x i64> %v0, i64 %b, i32 1
  ret <2 x i64> %v1
}

define i32 @reference_ptr_insert(ptr %p, ptr %q) noinline {
entry:
  %v0 = insertelement <2 x ptr> poison, ptr %p, i32 0
  %v1 = insertelement <2 x ptr> %v0, ptr %q, i32 1
  %e0 = extractelement <2 x ptr> %v1, i32 0
  %e1 = extractelement <2 x ptr> %v1, i32 1
  %ok0 = icmp eq ptr %e0, %p
  %ok1 = icmp eq ptr %e1, %q
  %ok = and i1 %ok0, %ok1
  %z = zext i1 %ok to i32
  ret i32 %z
}

define i32 @protected_ptr_insert(ptr %p, ptr %q) noinline optnone {
entry:
  call void @hikari_vmp()
  %v0 = insertelement <2 x ptr> poison, ptr %p, i32 0
  %v1 = insertelement <2 x ptr> %v0, ptr %q, i32 1
  %e0 = extractelement <2 x ptr> %v1, i32 0
  %e1 = extractelement <2 x ptr> %v1, i32 1
  %ok0 = icmp eq ptr %e0, %p
  %ok1 = icmp eq ptr %e1, %q
  %ok = and i1 %ok0, %ok1
  %z = zext i1 %ok to i32
  ret i32 %z
}

define <4 x i32> @reference_phi(i1 %c, i32 %a, i32 %b) noinline {
entry:
  br i1 %c, label %left, label %right

left:
  %l0 = insertelement <4 x i32> poison, i32 %a, i32 0
  %l = shufflevector <4 x i32> %l0, <4 x i32> poison, <4 x i32> zeroinitializer
  br label %join

right:
  %r0 = insertelement <4 x i32> poison, i32 %b, i32 0
  %r = shufflevector <4 x i32> %r0, <4 x i32> poison, <4 x i32> zeroinitializer
  br label %join

join:
  %p = phi <4 x i32> [ %l, %left ], [ %r, %right ]
  ret <4 x i32> %p
}

define <4 x i32> @protected_phi(i1 %c, i32 %a, i32 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  br i1 %c, label %left, label %right

left:
  %l0 = insertelement <4 x i32> poison, i32 %a, i32 0
  %l = shufflevector <4 x i32> %l0, <4 x i32> poison, <4 x i32> zeroinitializer
  br label %join

right:
  %r0 = insertelement <4 x i32> poison, i32 %b, i32 0
  %r = shufflevector <4 x i32> %r0, <4 x i32> poison, <4 x i32> zeroinitializer
  br label %join

join:
  %p = phi <4 x i32> [ %l, %left ], [ %r, %right ]
  ret <4 x i32> %p
}

define i32 @reference_loop(i32 %x, i32 %n) noinline {
entry:
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %acc = phi i32 [ 0, %entry ], [ %next, %loop ]
  %v0 = insertelement <4 x i32> poison, i32 %x, i32 0
  %s = shufflevector <4 x i32> %v0, <4 x i32> poison, <4 x i32> zeroinitializer
  %e = extractelement <4 x i32> %s, i32 2
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
  %v0 = insertelement <4 x i32> poison, i32 %x, i32 0
  %s = shufflevector <4 x i32> %v0, <4 x i32> poison, <4 x i32> zeroinitializer
  %e = extractelement <4 x i32> %s, i32 2
  %next = add i32 %acc, %e
  %i1 = add i32 %i, 1
  %more = icmp slt i32 %i1, %n
  br i1 %more, label %loop, label %done

done:
  ret i32 %next
}

; ----- negatives -----

define <4 x i32> @unsupported_poison_element(<4 x i32> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = insertelement <4 x i32> %v, i32 poison, i32 0
  ret <4 x i32> %r
}

define i32 @unsupported_extract_poison() noinline optnone {
entry:
  call void @hikari_vmp()
  %r = extractelement <4 x i32> poison, i32 0
  ret i32 %r
}

define <4 x i32> @unsupported_add_poison(<4 x i32> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = add <4 x i32> %v, poison
  ret <4 x i32> %r
}

define <vscale x 4 x i32> @unsupported_scalable(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %v0 = insertelement <vscale x 4 x i32> poison, i32 %x, i32 0
  ret <vscale x 4 x i32> %v0
}

define <8 x i32> @unsupported_overwide(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %v0 = insertelement <8 x i32> poison, i32 %x, i32 0
  ret <8 x i32> %v0
}

define <1 x fp128> @unsupported_fp128(fp128 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %v0 = insertelement <1 x fp128> poison, fp128 %x, i32 0
  ret <1 x fp128> %v0
}

define <1 x ppc_fp128> @unsupported_ppc(ppc_fp128 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %v0 = insertelement <1 x ppc_fp128> poison, ppc_fp128 %x, i32 0
  ret <1 x ppc_fp128> %v0
}

define i32 @main() {
entry:
  %eb = call <4 x i32> @reference_build(i32 1, i32 2, i32 3, i32 4)
  %pb = call <4 x i32> @protected_build(i32 1, i32 2, i32 3, i32 4)
  %feb = call i32 @fold4(<4 x i32> %eb)
  %fpb = call i32 @fold4(<4 x i32> %pb)
  %ok0 = icmp eq i32 %feb, %fpb
  %eu = call <4 x i32> @reference_undef_base(i32 9)
  %pu = call <4 x i32> @protected_undef_base(i32 9)
  %feu = call i32 @fold4(<4 x i32> %eu)
  %fpu = call i32 @fold4(<4 x i32> %pu)
  %ok1 = icmp eq i32 %feu, %fpu
  %es = call <4 x i32> @reference_splat(i32 7)
  %ps = call <4 x i32> @protected_splat(i32 7)
  %fes = call i32 @fold4(<4 x i32> %es)
  %fps = call i32 @fold4(<4 x i32> %ps)
  %ok2 = icmp eq i32 %fes, %fps
  %ef = call <4 x float> @reference_splat_f32(float 2.000000e+00)
  %pf = call <4 x float> @protected_splat_f32(float 2.000000e+00)
  %bef = bitcast <4 x float> %ef to <4 x i32>
  %bpf = bitcast <4 x float> %pf to <4 x i32>
  %fef = call i32 @fold4(<4 x i32> %bef)
  %fpf = call i32 @fold4(<4 x i32> %bpf)
  %ok3 = icmp eq i32 %fef, %fpf
  %e16 = call <8 x i16> @reference_build_i16(i16 3, i16 5)
  %p16 = call <8 x i16> @protected_build_i16(i16 3, i16 5)
  %be16 = bitcast <8 x i16> %e16 to <4 x i32>
  %bp16 = bitcast <8 x i16> %p16 to <4 x i32>
  %fe16 = call i32 @fold4(<4 x i32> %be16)
  %fp16 = call i32 @fold4(<4 x i32> %bp16)
  %ok4 = icmp eq i32 %fe16, %fp16
  %e8 = call <8 x i8> @reference_build_i8(i8 11)
  %p8 = call <8 x i8> @protected_build_i8(i8 11)
  %ze8 = zext <8 x i8> %e8 to <8 x i16>
  %zp8 = zext <8 x i8> %p8 to <8 x i16>
  %be8 = bitcast <8 x i16> %ze8 to <4 x i32>
  %bp8 = bitcast <8 x i16> %zp8 to <4 x i32>
  %fe8 = call i32 @fold4(<4 x i32> %be8)
  %fp8 = call i32 @fold4(<4 x i32> %bp8)
  %ok5 = icmp eq i32 %fe8, %fp8
  %eh = call <4 x half> @reference_splat_half(half 0xH4000)
  %ph = call <4 x half> @protected_splat_half(half 0xH4000)
  %feh = fpext <4 x half> %eh to <4 x float>
  %fph = fpext <4 x half> %ph to <4 x float>
  %beh = bitcast <4 x float> %feh to <4 x i32>
  %bph = bitcast <4 x float> %fph to <4 x i32>
  %ffeh = call i32 @fold4(<4 x i32> %beh)
  %ffph = call i32 @fold4(<4 x i32> %bph)
  %ok6 = icmp eq i32 %ffeh, %ffph
  %e64 = call <2 x i64> @reference_build_i64(i64 1, i64 2)
  %p64 = call <2 x i64> @protected_build_i64(i64 1, i64 2)
  %e64a = extractelement <2 x i64> %e64, i32 0
  %e64b = extractelement <2 x i64> %e64, i32 1
  %p64a = extractelement <2 x i64> %p64, i32 0
  %p64b = extractelement <2 x i64> %p64, i32 1
  %ok7a = icmp eq i64 %e64a, %p64a
  %ok7b = icmp eq i64 %e64b, %p64b
  %ok7 = and i1 %ok7a, %ok7b
  %ep = call i32 @reference_ptr_insert(ptr null, ptr null)
  %pp = call i32 @protected_ptr_insert(ptr null, ptr null)
  %ok8a = icmp eq i32 %ep, %pp
  %ok8b = icmp eq i32 %ep, 1
  %ok8 = and i1 %ok8a, %ok8b
  %ephi = call <4 x i32> @reference_phi(i1 true, i32 4, i32 8)
  %pphi = call <4 x i32> @protected_phi(i1 true, i32 4, i32 8)
  %fephi = call i32 @fold4(<4 x i32> %ephi)
  %fpphi = call i32 @fold4(<4 x i32> %pphi)
  %ok9 = icmp eq i32 %fephi, %fpphi
  %ephi2 = call <4 x i32> @reference_phi(i1 false, i32 4, i32 8)
  %pphi2 = call <4 x i32> @protected_phi(i1 false, i32 4, i32 8)
  %fephi2 = call i32 @fold4(<4 x i32> %ephi2)
  %fpphi2 = call i32 @fold4(<4 x i32> %pphi2)
  %ok10 = icmp eq i32 %fephi2, %fpphi2
  %el = call i32 @reference_loop(i32 3, i32 4)
  %pl = call i32 @protected_loop(i32 3, i32 4)
  %ok11 = icmp eq i32 %el, %pl
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
  %ok = and i1 %t9, %ok11
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_poison_element: unsupported insertelement instruction
; SKIP-DAG: Skipping VMP on unsupported_extract_poison: unsupported extractelement instruction
; SKIP-DAG: Skipping VMP on unsupported_add_poison: unsupported
; SKIP-DAG: Skipping VMP on unsupported_scalable: unsupported
; SKIP-DAG: Skipping VMP on unsupported_overwide: unsupported
; SKIP-DAG: Skipping VMP on unsupported_fp128: unsupported
; SKIP-DAG: Skipping VMP on unsupported_ppc: unsupported
; SKIP-NOT: Skipping VMP on protected_build:
; SKIP-NOT: Skipping VMP on protected_undef_base:
; SKIP-NOT: Skipping VMP on protected_splat:
; SKIP-NOT: Skipping VMP on protected_splat_f32:
; SKIP-NOT: Skipping VMP on protected_build_i16:
; SKIP-NOT: Skipping VMP on protected_build_i8:
; SKIP-NOT: Skipping VMP on protected_splat_half:
; SKIP-NOT: Skipping VMP on protected_build_i64:
; SKIP-NOT: Skipping VMP on protected_ptr_insert:
; SKIP-NOT: Skipping VMP on protected_phi:
; SKIP-NOT: Skipping VMP on protected_loop:

; VIRT: define <4 x i32> @protected_build({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call void @hikari_vmp()
; VIRT-DAG: insertelement <4 x i32> poison, i32
; VIRT: define <4 x i32> @protected_undef_base({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: insertelement <4 x i32> undef, i32
; VIRT: define <4 x i32> @protected_splat({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: insertelement <4 x i32> poison, i32
; VIRT-DAG: shufflevector <4 x i32> {{.*}}, <4 x i32> poison
; VIRT: define <4 x float> @protected_splat_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: insertelement <4 x float> poison, float
; VIRT: define <8 x i16> @protected_build_i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: insertelement <8 x i16> poison, i16
; VIRT: define <8 x i8> @protected_build_i8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: insertelement <8 x i8> poison, i8
; VIRT: define <4 x half> @protected_splat_half({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: insertelement <4 x half> poison, half
; VIRT: define <2 x i64> @protected_build_i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: insertelement <2 x i64> poison, i64
; VIRT: define i32 @protected_ptr_insert({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: insertelement <2 x ptr> poison, ptr
; VIRT: define <4 x i32> @protected_phi({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: insertelement <4 x i32> poison, i32
; VIRT: define i32 @protected_loop({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: insertelement <4 x i32> poison, i32
; VIRT: define {{.*}} @unsupported_poison_element({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_extract_poison({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_add_poison({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_scalable({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_overwide({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fp128({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ppc({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
