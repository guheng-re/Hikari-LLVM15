; Restricted indirect CallInst: already-supported fixed-vector args
; and/or returns on the existing 0..8 C non-vararg subset.  Callee is
; an AS0 pointer VReg (function-pointer argument, global table load,
; select, or phi).  Replay uses the existing vector VReg +
; CallDescriptor; any valid FastMathFlags on a float-vector return
; are restored.  No +fullfp16 gate — this is call ABI, not a half
; vector math intrinsic.
;
; Widths stay inside the existing 1..128 fixed-vector surface
; (<4 x i32>, <2 x i64>, <8 x i16>, <4 x float>, <2 x double>,
; <4 x half>).  Finite ordinary bit patterns only for host lli
; reference vs protected compares.  Host x86 may warn about leftover
; AArch64 function attributes after the triple swap; interpreter
; semantics and AArch64 object compile are the pass criteria.
; Supported small-flat-aggregate args/returns live in
; vmp-indirect-call-aggregate-semantic.ll; this file keeps a nested
; aggregate reject.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.ll -o %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.live.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.ll -o %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.live.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.s7.ll -o %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.s7.live.ll > %t.o0.s7.host.ll
; RUN: lli -force-interpreter %t.o0.s7.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.s7.ll -o %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.s7.live.ll > %t.o2.s7.host.ll
; RUN: lli -force-interpreter %t.o2.s7.host.ll

target triple = "aarch64-unknown-linux-gnu"

%pair = type { i32, i32 }
%pairnest = type { { %pair, i32 }, i32 }

declare void @hikari_vmp()

@slot.i32x4 = global <4 x i32> zeroinitializer, align 16
@vt.i32 = global [2 x ptr] [ptr @vadd4, ptr @vxor4], align 8

; ----- fold helpers (native) -----

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

define i32 @fold_i64x2(<2 x i64> %v) {
entry:
  %e0 = extractelement <2 x i64> %v, i32 0
  %e1 = extractelement <2 x i64> %v, i32 1
  %x = xor i64 %e0, %e1
  %lo = trunc i64 %x to i32
  %hi64 = lshr i64 %x, 32
  %hi = trunc i64 %hi64 to i32
  %r = xor i32 %lo, %hi
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

define i32 @fold_i16x8(<8 x i16> %v) {
entry:
  %lo = shufflevector <8 x i16> %v, <8 x i16> poison, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  %hi = shufflevector <8 x i16> %v, <8 x i16> poison, <4 x i32> <i32 4, i32 5, i32 6, i32 7>
  %a = call i32 @fold_i16x4(<4 x i16> %lo)
  %b = call i32 @fold_i16x4(<4 x i16> %hi)
  %r = xor i32 %a, %b
  ret i32 %r
}

define i32 @fold_f32x4(<4 x float> %v) {
entry:
  %bits = bitcast <4 x float> %v to <4 x i32>
  %r = call i32 @fold_i32x4(<4 x i32> %bits)
  ret i32 %r
}

define i32 @fold_f64x2(<2 x double> %v) {
entry:
  %bits = bitcast <2 x double> %v to <2 x i64>
  %r = call i32 @fold_i64x2(<2 x i64> %bits)
  ret i32 %r
}

define i32 @fold_halfx4(<4 x half> %v) {
entry:
  %bits = bitcast <4 x half> %v to <4 x i16>
  %r = call i32 @fold_i16x4(<4 x i16> %bits)
  ret i32 %r
}

; ----- native callees -----

define <4 x i32> @vadd4(<4 x i32> %a, <4 x i32> %b) noinline {
entry:
  %r = add <4 x i32> %a, %b
  ret <4 x i32> %r
}

define <4 x i32> @vxor4(<4 x i32> %a, <4 x i32> %b) noinline {
entry:
  %r = xor <4 x i32> %a, %b
  ret <4 x i32> %r
}

define <2 x i64> @vadd2i64(<2 x i64> %a, <2 x i64> %b) noinline {
entry:
  %r = add <2 x i64> %a, %b
  ret <2 x i64> %r
}

define <8 x i16> @vadd8i16(<8 x i16> %a, <8 x i16> %b) noinline {
entry:
  %r = add <8 x i16> %a, %b
  ret <8 x i16> %r
}

define <4 x float> @vfadd4(<4 x float> %a, <4 x float> %b) noinline {
entry:
  %r = fadd <4 x float> %a, %b
  ret <4 x float> %r
}

define <4 x float> @vfsub4(<4 x float> %a, <4 x float> %b) noinline {
entry:
  %r = fsub <4 x float> %a, %b
  ret <4 x float> %r
}

define <2 x double> @vdadd2(<2 x double> %a, <2 x double> %b) noinline {
entry:
  %r = fadd <2 x double> %a, %b
  ret <2 x double> %r
}

define <4 x half> @vhadd4(<4 x half> %a, <4 x half> %b) noinline {
entry:
  %r = fadd <4 x half> %a, %b
  ret <4 x half> %r
}

define <4 x i32> @vinsert_i32(<4 x i32> %a, i32 %k) noinline {
entry:
  %r = insertelement <4 x i32> %a, i32 %k, i32 0
  ret <4 x i32> %r
}

define i32 @vsum4(<4 x i32> %a) noinline {
entry:
  %r = call i32 @fold_i32x4(<4 x i32> %a)
  ret i32 %r
}

define void @vstore4(<4 x i32> %v) noinline {
entry:
  store <4 x i32> %v, ptr @slot.i32x4, align 16
  ret void
}

define void @vstore_neg4(<4 x i32> %v) noinline {
entry:
  %n = sub <4 x i32> zeroinitializer, %v
  store <4 x i32> %n, ptr @slot.i32x4, align 16
  ret void
}

; ----- <4 x i32> via function-pointer argument -----

define <4 x i32> @reference_via_arg(ptr %fp, <4 x i32> %a, <4 x i32> %b) {
entry:
  %r = call <4 x i32> %fp(<4 x i32> %a, <4 x i32> %b)
  ret <4 x i32> %r
}

define <4 x i32> @protected_via_arg(ptr %fp, <4 x i32> %a, <4 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> %fp(<4 x i32> %a, <4 x i32> %b)
  ret <4 x i32> %r
}

; ----- <4 x i32> via select of globals -----

define <4 x i32> @reference_via_select(i1 %pick, <4 x i32> %a, <4 x i32> %b) {
entry:
  %fp = select i1 %pick, ptr @vadd4, ptr @vxor4
  %r = call <4 x i32> %fp(<4 x i32> %a, <4 x i32> %b)
  ret <4 x i32> %r
}

define <4 x i32> @protected_via_select(i1 %pick, <4 x i32> %a, <4 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %fp = select i1 %pick, ptr @vadd4, ptr @vxor4
  %r = call <4 x i32> %fp(<4 x i32> %a, <4 x i32> %b)
  ret <4 x i32> %r
}

; ----- <4 x i32> via global table -----

define <4 x i32> @reference_via_global(i64 %idx, <4 x i32> %a, <4 x i32> %b) {
entry:
  %slot = getelementptr inbounds [2 x ptr], ptr @vt.i32, i64 0, i64 %idx
  %fp = load ptr, ptr %slot, align 8
  %r = call <4 x i32> %fp(<4 x i32> %a, <4 x i32> %b)
  ret <4 x i32> %r
}

define <4 x i32> @protected_via_global(i64 %idx, <4 x i32> %a, <4 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %slot = getelementptr inbounds [2 x ptr], ptr @vt.i32, i64 0, i64 %idx
  %fp = load ptr, ptr %slot, align 8
  %r = call <4 x i32> %fp(<4 x i32> %a, <4 x i32> %b)
  ret <4 x i32> %r
}

; ----- <4 x i32> via phi of globals -----

define <4 x i32> @reference_via_phi(i1 %pick, <4 x i32> %a, <4 x i32> %b) {
entry:
  br i1 %pick, label %left, label %right

left:
  br label %join

right:
  br label %join

join:
  %fp = phi ptr [ @vadd4, %left ], [ @vxor4, %right ]
  %r = call <4 x i32> %fp(<4 x i32> %a, <4 x i32> %b)
  ret <4 x i32> %r
}

define <4 x i32> @protected_via_phi(i1 %pick, <4 x i32> %a, <4 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  br i1 %pick, label %left, label %right

left:
  br label %join

right:
  br label %join

join:
  %fp = phi ptr [ @vadd4, %left ], [ @vxor4, %right ]
  %r = call <4 x i32> %fp(<4 x i32> %a, <4 x i32> %b)
  ret <4 x i32> %r
}

; ----- other supported widths / mixed scalar+vector -----

define <2 x i64> @reference_i64x2(ptr %fp, <2 x i64> %a, <2 x i64> %b) {
entry:
  %r = call <2 x i64> %fp(<2 x i64> %a, <2 x i64> %b)
  ret <2 x i64> %r
}

define <2 x i64> @protected_i64x2(ptr %fp, <2 x i64> %a, <2 x i64> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> %fp(<2 x i64> %a, <2 x i64> %b)
  ret <2 x i64> %r
}

define <8 x i16> @reference_i16x8(ptr %fp, <8 x i16> %a, <8 x i16> %b) {
entry:
  %r = call <8 x i16> %fp(<8 x i16> %a, <8 x i16> %b)
  ret <8 x i16> %r
}

define <8 x i16> @protected_i16x8(ptr %fp, <8 x i16> %a, <8 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i16> %fp(<8 x i16> %a, <8 x i16> %b)
  ret <8 x i16> %r
}

define <4 x i32> @reference_mixed_i32(ptr %fp, <4 x i32> %a, i32 %k) {
entry:
  %r = call <4 x i32> %fp(<4 x i32> %a, i32 %k)
  ret <4 x i32> %r
}

define <4 x i32> @protected_mixed_i32(ptr %fp, <4 x i32> %a, i32 %k) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> %fp(<4 x i32> %a, i32 %k)
  ret <4 x i32> %r
}

define i32 @reference_sum(ptr %fp, <4 x i32> %a) {
entry:
  %r = call i32 %fp(<4 x i32> %a)
  ret i32 %r
}

define i32 @protected_sum(ptr %fp, <4 x i32> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 %fp(<4 x i32> %a)
  ret i32 %r
}

define void @reference_void(ptr %fp, <4 x i32> %v) {
entry:
  call void %fp(<4 x i32> %v)
  ret void
}

define void @protected_void(ptr %fp, <4 x i32> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  call void %fp(<4 x i32> %v)
  ret void
}

; ----- float / half vectors + FMF -----

define <4 x float> @reference_f32(ptr %fp, <4 x float> %a, <4 x float> %b) {
entry:
  %r = call <4 x float> %fp(<4 x float> %a, <4 x float> %b)
  ret <4 x float> %r
}

define <4 x float> @protected_f32(ptr %fp, <4 x float> %a, <4 x float> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> %fp(<4 x float> %a, <4 x float> %b)
  ret <4 x float> %r
}

define <2 x double> @reference_f64(ptr %fp, <2 x double> %a, <2 x double> %b) {
entry:
  %r = call <2 x double> %fp(<2 x double> %a, <2 x double> %b)
  ret <2 x double> %r
}

define <2 x double> @protected_f64(ptr %fp, <2 x double> %a, <2 x double> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x double> %fp(<2 x double> %a, <2 x double> %b)
  ret <2 x double> %r
}

define <4 x half> @reference_half(ptr %fp, <4 x half> %a, <4 x half> %b) {
entry:
  %r = call <4 x half> %fp(<4 x half> %a, <4 x half> %b)
  ret <4 x half> %r
}

define <4 x half> @protected_half(ptr %fp, <4 x half> %a, <4 x half> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x half> %fp(<4 x half> %a, <4 x half> %b)
  ret <4 x half> %r
}

define <4 x float> @reference_fast(ptr %fp, <4 x float> %a, <4 x float> %b) {
entry:
  %r = call fast <4 x float> %fp(<4 x float> %a, <4 x float> %b)
  ret <4 x float> %r
}

define <4 x float> @protected_fast(ptr %fp, <4 x float> %a, <4 x float> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fast <4 x float> %fp(<4 x float> %a, <4 x float> %b)
  ret <4 x float> %r
}

define <4 x float> @reference_nnan(ptr %fp, <4 x float> %a, <4 x float> %b) {
entry:
  %r = call nnan ninf <4 x float> %fp(<4 x float> %a, <4 x float> %b)
  ret <4 x float> %r
}

define <4 x float> @protected_nnan(ptr %fp, <4 x float> %a, <4 x float> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call nnan ninf <4 x float> %fp(<4 x float> %a, <4 x float> %b)
  ret <4 x float> %r
}

; ----- negatives: selected, not virtualized -----

define <vscale x 4 x i32> @unsupported_scalable(ptr %fp, <vscale x 4 x i32> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> %fp(<vscale x 4 x i32> %v)
  ret <vscale x 4 x i32> %r
}

define <8 x i32> @unsupported_wide(ptr %fp, <8 x i32> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i32> %fp(<8 x i32> %v)
  ret <8 x i32> %r
}

define <2 x ptr> @unsupported_ptrvec(ptr %fp, <2 x ptr> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x ptr> %fp(<2 x ptr> %v)
  ret <2 x ptr> %r
}

define %pairnest @unsupported_aggregate(ptr %fp, %pairnest %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call %pairnest %fp(%pairnest %p)
  ret %pairnest %r
}

define <4 x i32> @unsupported_fastcc(ptr %fp, <4 x i32> %a, <4 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc <4 x i32> %fp(<4 x i32> %a, <4 x i32> %b)
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_vararg(ptr %fp, <4 x i32> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> (<4 x i32>, ...) %fp(<4 x i32> %a, i32 1)
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_byval(ptr %fp, ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> %fp(ptr byval(%pair) %p)
  ret <4 x i32> %r
}

define i32 @main() {
entry:
  %va = add <4 x i32> <i32 1, i32 2, i32 3, i32 4>, zeroinitializer
  %vb = add <4 x i32> <i32 5, i32 6, i32 7, i32 8>, zeroinitializer

  ; <4 x i32> via arg: add / xor
  %e0 = call <4 x i32> @reference_via_arg(ptr @vadd4, <4 x i32> %va, <4 x i32> %vb)
  %a0 = call <4 x i32> @protected_via_arg(ptr @vadd4, <4 x i32> %va, <4 x i32> %vb)
  %fe0 = call i32 @fold_i32x4(<4 x i32> %e0)
  %fa0 = call i32 @fold_i32x4(<4 x i32> %a0)
  %m0 = icmp eq i32 %fe0, %fa0
  %e1 = call <4 x i32> @reference_via_arg(ptr @vxor4, <4 x i32> %va, <4 x i32> %vb)
  %a1 = call <4 x i32> @protected_via_arg(ptr @vxor4, <4 x i32> %va, <4 x i32> %vb)
  %fe1 = call i32 @fold_i32x4(<4 x i32> %e1)
  %fa1 = call i32 @fold_i32x4(<4 x i32> %a1)
  %m1 = icmp eq i32 %fe1, %fa1

  ; select
  %e2 = call <4 x i32> @reference_via_select(i1 true, <4 x i32> %va, <4 x i32> %vb)
  %a2 = call <4 x i32> @protected_via_select(i1 true, <4 x i32> %va, <4 x i32> %vb)
  %fe2 = call i32 @fold_i32x4(<4 x i32> %e2)
  %fa2 = call i32 @fold_i32x4(<4 x i32> %a2)
  %m2 = icmp eq i32 %fe2, %fa2
  %e3 = call <4 x i32> @reference_via_select(i1 false, <4 x i32> %va, <4 x i32> %vb)
  %a3 = call <4 x i32> @protected_via_select(i1 false, <4 x i32> %va, <4 x i32> %vb)
  %fe3 = call i32 @fold_i32x4(<4 x i32> %e3)
  %fa3 = call i32 @fold_i32x4(<4 x i32> %a3)
  %m3 = icmp eq i32 %fe3, %fa3

  ; global table
  %e4 = call <4 x i32> @reference_via_global(i64 0, <4 x i32> %va, <4 x i32> %vb)
  %a4 = call <4 x i32> @protected_via_global(i64 0, <4 x i32> %va, <4 x i32> %vb)
  %fe4 = call i32 @fold_i32x4(<4 x i32> %e4)
  %fa4 = call i32 @fold_i32x4(<4 x i32> %a4)
  %m4 = icmp eq i32 %fe4, %fa4
  %e5 = call <4 x i32> @reference_via_global(i64 1, <4 x i32> %va, <4 x i32> %vb)
  %a5 = call <4 x i32> @protected_via_global(i64 1, <4 x i32> %va, <4 x i32> %vb)
  %fe5 = call i32 @fold_i32x4(<4 x i32> %e5)
  %fa5 = call i32 @fold_i32x4(<4 x i32> %a5)
  %m5 = icmp eq i32 %fe5, %fa5

  ; phi
  %e6 = call <4 x i32> @reference_via_phi(i1 true, <4 x i32> %va, <4 x i32> %vb)
  %a6 = call <4 x i32> @protected_via_phi(i1 true, <4 x i32> %va, <4 x i32> %vb)
  %fe6 = call i32 @fold_i32x4(<4 x i32> %e6)
  %fa6 = call i32 @fold_i32x4(<4 x i32> %a6)
  %m6 = icmp eq i32 %fe6, %fa6
  %e7 = call <4 x i32> @reference_via_phi(i1 false, <4 x i32> %va, <4 x i32> %vb)
  %a7 = call <4 x i32> @protected_via_phi(i1 false, <4 x i32> %va, <4 x i32> %vb)
  %fe7 = call i32 @fold_i32x4(<4 x i32> %e7)
  %fa7 = call i32 @fold_i32x4(<4 x i32> %a7)
  %m7 = icmp eq i32 %fe7, %fa7

  ; <2 x i64>
  %la = add <2 x i64> <i64 11, i64 22>, zeroinitializer
  %lb = add <2 x i64> <i64 33, i64 44>, zeroinitializer
  %e8 = call <2 x i64> @reference_i64x2(ptr @vadd2i64, <2 x i64> %la, <2 x i64> %lb)
  %a8 = call <2 x i64> @protected_i64x2(ptr @vadd2i64, <2 x i64> %la, <2 x i64> %lb)
  %fe8 = call i32 @fold_i64x2(<2 x i64> %e8)
  %fa8 = call i32 @fold_i64x2(<2 x i64> %a8)
  %m8 = icmp eq i32 %fe8, %fa8

  ; <8 x i16>
  %sa = add <8 x i16> <i16 1, i16 2, i16 3, i16 4, i16 5, i16 6, i16 7, i16 8>, zeroinitializer
  %sb = add <8 x i16> <i16 8, i16 7, i16 6, i16 5, i16 4, i16 3, i16 2, i16 1>, zeroinitializer
  %e9 = call <8 x i16> @reference_i16x8(ptr @vadd8i16, <8 x i16> %sa, <8 x i16> %sb)
  %a9 = call <8 x i16> @protected_i16x8(ptr @vadd8i16, <8 x i16> %sa, <8 x i16> %sb)
  %fe9 = call i32 @fold_i16x8(<8 x i16> %e9)
  %fa9 = call i32 @fold_i16x8(<8 x i16> %a9)
  %m9 = icmp eq i32 %fe9, %fa9

  ; mixed vector + i32
  %e10 = call <4 x i32> @reference_mixed_i32(ptr @vinsert_i32, <4 x i32> %va, i32 99)
  %a10 = call <4 x i32> @protected_mixed_i32(ptr @vinsert_i32, <4 x i32> %va, i32 99)
  %fe10 = call i32 @fold_i32x4(<4 x i32> %e10)
  %fa10 = call i32 @fold_i32x4(<4 x i32> %a10)
  %m10 = icmp eq i32 %fe10, %fa10

  ; i32(<4 x i32>)
  %e11 = call i32 @reference_sum(ptr @vsum4, <4 x i32> %va)
  %a11 = call i32 @protected_sum(ptr @vsum4, <4 x i32> %va)
  %m11 = icmp eq i32 %e11, %a11

  ; void(<4 x i32>)
  store <4 x i32> zeroinitializer, ptr @slot.i32x4, align 16
  call void @reference_void(ptr @vstore4, <4 x i32> %va)
  %ev12 = load <4 x i32>, ptr @slot.i32x4, align 16
  store <4 x i32> zeroinitializer, ptr @slot.i32x4, align 16
  call void @protected_void(ptr @vstore4, <4 x i32> %va)
  %av12 = load <4 x i32>, ptr @slot.i32x4, align 16
  %fe12 = call i32 @fold_i32x4(<4 x i32> %ev12)
  %fa12 = call i32 @fold_i32x4(<4 x i32> %av12)
  %m12 = icmp eq i32 %fe12, %fa12
  store <4 x i32> zeroinitializer, ptr @slot.i32x4, align 16
  call void @reference_void(ptr @vstore_neg4, <4 x i32> %vb)
  %ev13 = load <4 x i32>, ptr @slot.i32x4, align 16
  store <4 x i32> zeroinitializer, ptr @slot.i32x4, align 16
  call void @protected_void(ptr @vstore_neg4, <4 x i32> %vb)
  %av13 = load <4 x i32>, ptr @slot.i32x4, align 16
  %fe13 = call i32 @fold_i32x4(<4 x i32> %ev13)
  %fa13 = call i32 @fold_i32x4(<4 x i32> %av13)
  %m13 = icmp eq i32 %fe13, %fa13

  ; <4 x float> / <2 x double> / <4 x half>, finite
  %fa = fadd <4 x float> <float 1.000000e+00, float 2.000000e+00, float 3.000000e+00, float 4.000000e+00>, zeroinitializer
  %fb = fadd <4 x float> <float 5.000000e-01, float -1.500000e+00, float 2.500000e+00, float 1.250000e+00>, zeroinitializer
  %e14 = call <4 x float> @reference_f32(ptr @vfadd4, <4 x float> %fa, <4 x float> %fb)
  %a14 = call <4 x float> @protected_f32(ptr @vfadd4, <4 x float> %fa, <4 x float> %fb)
  %fe14 = call i32 @fold_f32x4(<4 x float> %e14)
  %fa14 = call i32 @fold_f32x4(<4 x float> %a14)
  %m14 = icmp eq i32 %fe14, %fa14
  %e15 = call <4 x float> @reference_f32(ptr @vfsub4, <4 x float> %fa, <4 x float> %fb)
  %a15 = call <4 x float> @protected_f32(ptr @vfsub4, <4 x float> %fa, <4 x float> %fb)
  %fe15 = call i32 @fold_f32x4(<4 x float> %e15)
  %fa15 = call i32 @fold_f32x4(<4 x float> %a15)
  %m15 = icmp eq i32 %fe15, %fa15

  %da = fadd <2 x double> <double 1.500000e+00, double -2.250000e+00>, zeroinitializer
  %db = fadd <2 x double> <double 3.000000e+00, double 5.000000e-01>, zeroinitializer
  %e16 = call <2 x double> @reference_f64(ptr @vdadd2, <2 x double> %da, <2 x double> %db)
  %a16 = call <2 x double> @protected_f64(ptr @vdadd2, <2 x double> %da, <2 x double> %db)
  %fe16 = call i32 @fold_f64x2(<2 x double> %e16)
  %fa16 = call i32 @fold_f64x2(<2 x double> %a16)
  %m16 = icmp eq i32 %fe16, %fa16

  %ha = fadd <4 x half> <half 0xH3C00, half 0xH4000, half 0xH4200, half 0xH3800>, zeroinitializer
  %hb = fadd <4 x half> <half 0xH3E00, half 0xHC000, half 0xH4100, half 0xH3C00>, zeroinitializer
  %e17 = call <4 x half> @reference_half(ptr @vhadd4, <4 x half> %ha, <4 x half> %hb)
  %a17 = call <4 x half> @protected_half(ptr @vhadd4, <4 x half> %ha, <4 x half> %hb)
  %fe17 = call i32 @fold_halfx4(<4 x half> %e17)
  %fa17 = call i32 @fold_halfx4(<4 x half> %a17)
  %m17 = icmp eq i32 %fe17, %fa17

  ; FMF structure + finite bits
  %e18 = call <4 x float> @reference_fast(ptr @vfadd4, <4 x float> %fa, <4 x float> %fb)
  %a18 = call <4 x float> @protected_fast(ptr @vfadd4, <4 x float> %fa, <4 x float> %fb)
  %fe18 = call i32 @fold_f32x4(<4 x float> %e18)
  %fa18 = call i32 @fold_f32x4(<4 x float> %a18)
  %m18 = icmp eq i32 %fe18, %fa18
  %e19 = call <4 x float> @reference_nnan(ptr @vfsub4, <4 x float> %fa, <4 x float> %fb)
  %a19 = call <4 x float> @protected_nnan(ptr @vfsub4, <4 x float> %fa, <4 x float> %fb)
  %fe19 = call i32 @fold_f32x4(<4 x float> %e19)
  %fa19 = call i32 @fold_f32x4(<4 x float> %a19)
  %m19 = icmp eq i32 %fe19, %fa19

  %t0 = and i1 %m0, %m1
  %t1 = and i1 %m2, %m3
  %t2 = and i1 %m4, %m5
  %t3 = and i1 %m6, %m7
  %t4 = and i1 %m8, %m9
  %t5 = and i1 %m10, %m11
  %t6 = and i1 %m12, %m13
  %t7 = and i1 %m14, %m15
  %t8 = and i1 %m16, %m17
  %t9 = and i1 %m18, %m19
  %u0 = and i1 %t0, %t1
  %u1 = and i1 %t2, %t3
  %u2 = and i1 %t4, %t5
  %u3 = and i1 %t6, %t7
  %u4 = and i1 %t8, %t9
  %u5 = and i1 %u0, %u1
  %u6 = and i1 %u2, %u3
  %ok = and i1 %u5, %u6
  %ok2 = and i1 %ok, %u4
  %code = select i1 %ok2, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_scalable: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_wide: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_ptrvec: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_aggregate: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_fastcc: indirect call
; SKIP-DAG: Skipping VMP on unsupported_vararg: indirect call
; SKIP-DAG: Skipping VMP on unsupported_byval: indirect call
; SKIP-NOT: Skipping VMP on protected_via_arg:
; SKIP-NOT: Skipping VMP on protected_via_select:
; SKIP-NOT: Skipping VMP on protected_via_global:
; SKIP-NOT: Skipping VMP on protected_via_phi:
; SKIP-NOT: Skipping VMP on protected_i64x2:
; SKIP-NOT: Skipping VMP on protected_i16x8:
; SKIP-NOT: Skipping VMP on protected_mixed_i32:
; SKIP-NOT: Skipping VMP on protected_sum:
; SKIP-NOT: Skipping VMP on protected_void:
; SKIP-NOT: Skipping VMP on protected_f32:
; SKIP-NOT: Skipping VMP on protected_f64:
; SKIP-NOT: Skipping VMP on protected_half:
; SKIP-NOT: Skipping VMP on protected_fast:
; SKIP-NOT: Skipping VMP on protected_nnan:

; VIRT: define <4 x i32> @protected_via_arg({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> %{{.+}}(<4 x i32> {{.*}}, <4 x i32>
; VIRT: define <4 x i32> @protected_via_select({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> %{{.+}}(<4 x i32> {{.*}}, <4 x i32>
; VIRT: define <4 x i32> @protected_via_global({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> %{{.+}}(<4 x i32> {{.*}}, <4 x i32>
; VIRT: define <4 x i32> @protected_via_phi({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> %{{.+}}(<4 x i32> {{.*}}, <4 x i32>
; VIRT: define <2 x i64> @protected_i64x2({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i64> %{{.+}}(<2 x i64> {{.*}}, <2 x i64>
; VIRT: define <8 x i16> @protected_i16x8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x i16> %{{.+}}(<8 x i16> {{.*}}, <8 x i16>
; VIRT: define <4 x i32> @protected_mixed_i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> %{{.+}}(<4 x i32> {{.*}}, i32
; VIRT: define i32 @protected_sum({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 %{{.+}}(<4 x i32>
; VIRT: define void @protected_void({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void %{{.+}}(<4 x i32>
; VIRT: define <4 x float> @protected_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x float> %{{.+}}(<4 x float> {{.*}}, <4 x float>
; VIRT: define <2 x double> @protected_f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x double> %{{.+}}(<2 x double> {{.*}}, <2 x double>
; VIRT: define <4 x half> @protected_half({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x half> %{{.+}}(<4 x half> {{.*}}, <4 x half>
; VIRT: define <4 x float> @protected_fast({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call fast <4 x float> %{{.+}}(<4 x float> {{.*}}, <4 x float>
; VIRT: define <4 x float> @protected_nnan({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call nnan ninf <4 x float> %{{.+}}(<4 x float> {{.*}}, <4 x float>
; VIRT: define {{.*}} @unsupported_scalable({{.*}} #[[UNSUPATTR:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_wide({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ptrvec({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_aggregate({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fastcc({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_vararg({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_byval({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.virtualized"
