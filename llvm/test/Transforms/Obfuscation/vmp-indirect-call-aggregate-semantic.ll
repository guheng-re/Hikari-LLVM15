; Restricted indirect CallInst: already-supported small flat-aggregate
; args and/or returns on the existing 0..8 C non-vararg subset.  Callee
; is an AS0 pointer VReg (function-pointer argument, global table load,
; select, or phi).  Replay uses the existing aggregate VReg +
; CallDescriptor.  No +fullfp16 gate — this is call ABI / bit-pattern
; replay, not a half math intrinsic.  sret/byval/byref stay out.
;
; Types stay inside the existing 1..8 field, 1..64-byte flat surface
; ({i32,i32}, {ptr,i32}, {float,float}, {half,half}, {<2 x i32>,i32},
; [2 x i32]).  Finite ordinary bit patterns only for host lli
; reference vs protected compares.  Host x86 may warn about leftover
; AArch64 function attributes after the triple swap; interpreter
; semantics and AArch64 object compile are the pass criteria.
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
%mixed = type { ptr, i32 }
%ff = type { float, float }
%hh = type { half, half }
%vecf = type { <2 x i32>, i32 }
%arr = type [2 x i32]
%nest = type { { %pair, i32 }, i32 }
%wide = type { i64, i64, i64, i64, i64, i64, i64, i64, i64 }

declare void @hikari_vmp()

@cell = global i32 10, align 4
@alt = global i32 20, align 4
@slot.pair = global %pair zeroinitializer, align 8
@vt.pair = global [2 x ptr] [ptr @swap_pair, ptr @add_pair], align 8

; ----- fold helpers (native) -----

define i32 @fold_pair(%pair %p) {
entry:
  %a = extractvalue %pair %p, 0
  %b = extractvalue %pair %p, 1
  %r = xor i32 %a, %b
  ret i32 %r
}

define i32 @fold_mixed(%mixed %p) {
entry:
  %q = extractvalue %mixed %p, 0
  %k = extractvalue %mixed %p, 1
  %v = load i32, ptr %q, align 4
  %r = xor i32 %v, %k
  ret i32 %r
}

define i32 @fold_ff(%ff %p) {
entry:
  %a = extractvalue %ff %p, 0
  %b = extractvalue %ff %p, 1
  %ba = bitcast float %a to i32
  %bb = bitcast float %b to i32
  %r = xor i32 %ba, %bb
  ret i32 %r
}

define i32 @fold_hh(%hh %p) {
entry:
  %a = extractvalue %hh %p, 0
  %b = extractvalue %hh %p, 1
  %ba = bitcast half %a to i16
  %bb = bitcast half %b to i16
  %za = zext i16 %ba to i32
  %zb = zext i16 %bb to i32
  %r = xor i32 %za, %zb
  ret i32 %r
}

define i32 @fold_vecf(%vecf %p) {
entry:
  %v = extractvalue %vecf %p, 0
  %k = extractvalue %vecf %p, 1
  %e0 = extractelement <2 x i32> %v, i32 0
  %e1 = extractelement <2 x i32> %v, i32 1
  %s = add i32 %e0, %e1
  %r = xor i32 %s, %k
  ret i32 %r
}

define i32 @fold_arr(%arr %p) {
entry:
  %a = extractvalue %arr %p, 0
  %b = extractvalue %arr %p, 1
  %r = xor i32 %a, %b
  ret i32 %r
}

; ----- native callees -----

define %pair @swap_pair(%pair %p) noinline {
entry:
  %a = extractvalue %pair %p, 0
  %b = extractvalue %pair %p, 1
  %q0 = insertvalue %pair zeroinitializer, i32 %b, 0
  %q1 = insertvalue %pair %q0, i32 %a, 1
  ret %pair %q1
}

define %pair @add_pair(%pair %p) noinline {
entry:
  %a = extractvalue %pair %p, 0
  %b = extractvalue %pair %p, 1
  %s = add i32 %a, %b
  %q0 = insertvalue %pair %p, i32 %s, 0
  ret %pair %q0
}

define %pair @bump_pair(%pair %p, i32 %k) noinline {
entry:
  %a = extractvalue %pair %p, 0
  %n = add i32 %a, %k
  %q = insertvalue %pair %p, i32 %n, 0
  ret %pair %q
}

define i32 @sum_pair(%pair %p) noinline {
entry:
  %r = call i32 @fold_pair(%pair %p)
  ret i32 %r
}

define void @store_pair(%pair %p) noinline {
entry:
  store %pair %p, ptr @slot.pair, align 8
  ret void
}

define void @store_swap_pair(%pair %p) noinline {
entry:
  %s = call %pair @swap_pair(%pair %p)
  store %pair %s, ptr @slot.pair, align 8
  ret void
}

define %mixed @pick_cell(%mixed %p) noinline {
entry:
  %k = extractvalue %mixed %p, 1
  %c = icmp sgt i32 %k, 0
  %q = select i1 %c, ptr @cell, ptr @alt
  %r = insertvalue %mixed %p, ptr %q, 0
  ret %mixed %r
}

define %ff @swap_ff(%ff %p) noinline {
entry:
  %a = extractvalue %ff %p, 0
  %b = extractvalue %ff %p, 1
  %q0 = insertvalue %ff zeroinitializer, float %b, 0
  %q1 = insertvalue %ff %q0, float %a, 1
  ret %ff %q1
}

define %hh @swap_hh(%hh %p) noinline {
entry:
  %a = extractvalue %hh %p, 0
  %b = extractvalue %hh %p, 1
  %q0 = insertvalue %hh zeroinitializer, half %b, 0
  %q1 = insertvalue %hh %q0, half %a, 1
  ret %hh %q1
}

define %vecf @swap_vecf(%vecf %p) noinline {
entry:
  %v = extractvalue %vecf %p, 0
  %k = extractvalue %vecf %p, 1
  %e0 = extractelement <2 x i32> %v, i32 0
  %e1 = extractelement <2 x i32> %v, i32 1
  %nv = insertelement <2 x i32> %v, i32 %e1, i32 0
  %nv2 = insertelement <2 x i32> %nv, i32 %e0, i32 1
  %q0 = insertvalue %vecf zeroinitializer, <2 x i32> %nv2, 0
  %q1 = insertvalue %vecf %q0, i32 %k, 1
  ret %vecf %q1
}

define %arr @swap_arr(%arr %p) noinline {
entry:
  %a = extractvalue %arr %p, 0
  %b = extractvalue %arr %p, 1
  %q0 = insertvalue %arr zeroinitializer, i32 %b, 0
  %q1 = insertvalue %arr %q0, i32 %a, 1
  ret %arr %q1
}

; ----- {i32,i32} via function-pointer argument -----

define %pair @reference_via_arg(ptr %fp, %pair %p) {
entry:
  %r = call %pair %fp(%pair %p)
  ret %pair %r
}

define %pair @protected_via_arg(ptr %fp, %pair %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call %pair %fp(%pair %p)
  ret %pair %r
}

; ----- {i32,i32} via select of globals -----

define %pair @reference_via_select(i1 %pick, %pair %p) {
entry:
  %fp = select i1 %pick, ptr @swap_pair, ptr @add_pair
  %r = call %pair %fp(%pair %p)
  ret %pair %r
}

define %pair @protected_via_select(i1 %pick, %pair %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %fp = select i1 %pick, ptr @swap_pair, ptr @add_pair
  %r = call %pair %fp(%pair %p)
  ret %pair %r
}

; ----- {i32,i32} via global table -----

define %pair @reference_via_global(i64 %idx, %pair %p) {
entry:
  %slot = getelementptr inbounds [2 x ptr], ptr @vt.pair, i64 0, i64 %idx
  %fp = load ptr, ptr %slot, align 8
  %r = call %pair %fp(%pair %p)
  ret %pair %r
}

define %pair @protected_via_global(i64 %idx, %pair %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %slot = getelementptr inbounds [2 x ptr], ptr @vt.pair, i64 0, i64 %idx
  %fp = load ptr, ptr %slot, align 8
  %r = call %pair %fp(%pair %p)
  ret %pair %r
}

; ----- {i32,i32} via phi of globals -----

define %pair @reference_via_phi(i1 %pick, %pair %p) {
entry:
  br i1 %pick, label %left, label %right

left:
  br label %join

right:
  br label %join

join:
  %fp = phi ptr [ @swap_pair, %left ], [ @add_pair, %right ]
  %r = call %pair %fp(%pair %p)
  ret %pair %r
}

define %pair @protected_via_phi(i1 %pick, %pair %p) noinline optnone {
entry:
  call void @hikari_vmp()
  br i1 %pick, label %left, label %right

left:
  br label %join

right:
  br label %join

join:
  %fp = phi ptr [ @swap_pair, %left ], [ @add_pair, %right ]
  %r = call %pair %fp(%pair %p)
  ret %pair %r
}

; ----- mixed aggregate + scalar, void, i32 return -----

define %pair @reference_mixed_i32(ptr %fp, %pair %p, i32 %k) {
entry:
  %r = call %pair %fp(%pair %p, i32 %k)
  ret %pair %r
}

define %pair @protected_mixed_i32(ptr %fp, %pair %p, i32 %k) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call %pair %fp(%pair %p, i32 %k)
  ret %pair %r
}

define i32 @reference_sum(ptr %fp, %pair %p) {
entry:
  %r = call i32 %fp(%pair %p)
  ret i32 %r
}

define i32 @protected_sum(ptr %fp, %pair %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 %fp(%pair %p)
  ret i32 %r
}

define void @reference_void(ptr %fp, %pair %p) {
entry:
  call void %fp(%pair %p)
  ret void
}

define void @protected_void(ptr %fp, %pair %p) noinline optnone {
entry:
  call void @hikari_vmp()
  call void %fp(%pair %p)
  ret void
}

; ----- other supported aggregate shapes -----

define %mixed @reference_mixed(ptr %fp, %mixed %p) {
entry:
  %r = call %mixed %fp(%mixed %p)
  ret %mixed %r
}

define %mixed @protected_mixed(ptr %fp, %mixed %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call %mixed %fp(%mixed %p)
  ret %mixed %r
}

define %ff @reference_ff(ptr %fp, %ff %p) {
entry:
  %r = call %ff %fp(%ff %p)
  ret %ff %r
}

define %ff @protected_ff(ptr %fp, %ff %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call %ff %fp(%ff %p)
  ret %ff %r
}

define %hh @reference_hh(ptr %fp, %hh %p) {
entry:
  %r = call %hh %fp(%hh %p)
  ret %hh %r
}

define %hh @protected_hh(ptr %fp, %hh %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call %hh %fp(%hh %p)
  ret %hh %r
}

define %vecf @reference_vecf(ptr %fp, %vecf %p) {
entry:
  %r = call %vecf %fp(%vecf %p)
  ret %vecf %r
}

define %vecf @protected_vecf(ptr %fp, %vecf %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call %vecf %fp(%vecf %p)
  ret %vecf %r
}

define %arr @reference_arr(ptr %fp, %arr %p) {
entry:
  %r = call %arr %fp(%arr %p)
  ret %arr %r
}

define %arr @protected_arr(ptr %fp, %arr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call %arr %fp(%arr %p)
  ret %arr %r
}

; ----- negatives: selected, not virtualized -----

define %nest @unsupported_nested(ptr %fp, %nest %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call %nest %fp(%nest %p)
  ret %nest %r
}

define %wide @unsupported_wide(ptr %fp, %wide %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call %wide %fp(%wide %p)
  ret %wide %r
}

define { i32, i32, i32, i32, i32, i32, i32, i32, i32 } @unsupported_five(ptr %fp, { i32, i32, i32, i32, i32, i32, i32, i32, i32 } %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call { i32, i32, i32, i32, i32, i32, i32, i32, i32 } %fp({ i32, i32, i32, i32, i32, i32, i32, i32, i32 } %p)
  ret { i32, i32, i32, i32, i32, i32, i32, i32, i32 } %r
}

define %pair @unsupported_fastcc(ptr %fp, %pair %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc %pair %fp(%pair %p)
  ret %pair %r
}

define %pair @unsupported_vararg(ptr %fp, %pair %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call %pair (%pair, ...) %fp(%pair %p, i32 1)
  ret %pair %r
}

define %pair @unsupported_byval(ptr %fp, ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call %pair %fp(ptr byval(%pair) %p)
  ret %pair %r
}

define i32 @main() {
entry:
  %p0 = insertvalue %pair zeroinitializer, i32 3, 0
  %p = insertvalue %pair %p0, i32 9, 1

  ; {i32,i32} via arg: swap / add
  %e0 = call %pair @reference_via_arg(ptr @swap_pair, %pair %p)
  %a0 = call %pair @protected_via_arg(ptr @swap_pair, %pair %p)
  %fe0 = call i32 @fold_pair(%pair %e0)
  %fa0 = call i32 @fold_pair(%pair %a0)
  %m0 = icmp eq i32 %fe0, %fa0
  %e1 = call %pair @reference_via_arg(ptr @add_pair, %pair %p)
  %a1 = call %pair @protected_via_arg(ptr @add_pair, %pair %p)
  %fe1 = call i32 @fold_pair(%pair %e1)
  %fa1 = call i32 @fold_pair(%pair %a1)
  %m1 = icmp eq i32 %fe1, %fa1

  ; select
  %e2 = call %pair @reference_via_select(i1 true, %pair %p)
  %a2 = call %pair @protected_via_select(i1 true, %pair %p)
  %fe2 = call i32 @fold_pair(%pair %e2)
  %fa2 = call i32 @fold_pair(%pair %a2)
  %m2 = icmp eq i32 %fe2, %fa2
  %e3 = call %pair @reference_via_select(i1 false, %pair %p)
  %a3 = call %pair @protected_via_select(i1 false, %pair %p)
  %fe3 = call i32 @fold_pair(%pair %e3)
  %fa3 = call i32 @fold_pair(%pair %a3)
  %m3 = icmp eq i32 %fe3, %fa3

  ; global table
  %e4 = call %pair @reference_via_global(i64 0, %pair %p)
  %a4 = call %pair @protected_via_global(i64 0, %pair %p)
  %fe4 = call i32 @fold_pair(%pair %e4)
  %fa4 = call i32 @fold_pair(%pair %a4)
  %m4 = icmp eq i32 %fe4, %fa4
  %e5 = call %pair @reference_via_global(i64 1, %pair %p)
  %a5 = call %pair @protected_via_global(i64 1, %pair %p)
  %fe5 = call i32 @fold_pair(%pair %e5)
  %fa5 = call i32 @fold_pair(%pair %a5)
  %m5 = icmp eq i32 %fe5, %fa5

  ; phi
  %e6 = call %pair @reference_via_phi(i1 true, %pair %p)
  %a6 = call %pair @protected_via_phi(i1 true, %pair %p)
  %fe6 = call i32 @fold_pair(%pair %e6)
  %fa6 = call i32 @fold_pair(%pair %a6)
  %m6 = icmp eq i32 %fe6, %fa6
  %e7 = call %pair @reference_via_phi(i1 false, %pair %p)
  %a7 = call %pair @protected_via_phi(i1 false, %pair %p)
  %fe7 = call i32 @fold_pair(%pair %e7)
  %fa7 = call i32 @fold_pair(%pair %a7)
  %m7 = icmp eq i32 %fe7, %fa7

  ; mixed aggregate + i32
  %e8 = call %pair @reference_mixed_i32(ptr @bump_pair, %pair %p, i32 4)
  %a8 = call %pair @protected_mixed_i32(ptr @bump_pair, %pair %p, i32 4)
  %fe8 = call i32 @fold_pair(%pair %e8)
  %fa8 = call i32 @fold_pair(%pair %a8)
  %m8 = icmp eq i32 %fe8, %fa8

  ; i32(%pair)
  %e9 = call i32 @reference_sum(ptr @sum_pair, %pair %p)
  %a9 = call i32 @protected_sum(ptr @sum_pair, %pair %p)
  %m9 = icmp eq i32 %e9, %a9

  ; void(%pair)
  store %pair zeroinitializer, ptr @slot.pair, align 8
  call void @reference_void(ptr @store_pair, %pair %p)
  %ev10 = load %pair, ptr @slot.pair, align 8
  store %pair zeroinitializer, ptr @slot.pair, align 8
  call void @protected_void(ptr @store_pair, %pair %p)
  %av10 = load %pair, ptr @slot.pair, align 8
  %fe10 = call i32 @fold_pair(%pair %ev10)
  %fa10 = call i32 @fold_pair(%pair %av10)
  %m10 = icmp eq i32 %fe10, %fa10
  store %pair zeroinitializer, ptr @slot.pair, align 8
  call void @reference_void(ptr @store_swap_pair, %pair %p)
  %ev11 = load %pair, ptr @slot.pair, align 8
  store %pair zeroinitializer, ptr @slot.pair, align 8
  call void @protected_void(ptr @store_swap_pair, %pair %p)
  %av11 = load %pair, ptr @slot.pair, align 8
  %fe11 = call i32 @fold_pair(%pair %ev11)
  %fa11 = call i32 @fold_pair(%pair %av11)
  %m11 = icmp eq i32 %fe11, %fa11

  ; {ptr,i32}
  %mx0 = insertvalue %mixed zeroinitializer, ptr @cell, 0
  %mx = insertvalue %mixed %mx0, i32 1, 1
  %e12 = call %mixed @reference_mixed(ptr @pick_cell, %mixed %mx)
  %a12 = call %mixed @protected_mixed(ptr @pick_cell, %mixed %mx)
  %fe12 = call i32 @fold_mixed(%mixed %e12)
  %fa12 = call i32 @fold_mixed(%mixed %a12)
  %m12 = icmp eq i32 %fe12, %fa12

  ; {float,float} finite
  %ff0 = insertvalue %ff zeroinitializer, float 1.500000e+00, 0
  %ff1 = insertvalue %ff %ff0, float -2.250000e+00, 1
  %e13 = call %ff @reference_ff(ptr @swap_ff, %ff %ff1)
  %a13 = call %ff @protected_ff(ptr @swap_ff, %ff %ff1)
  %fe13 = call i32 @fold_ff(%ff %e13)
  %fa13 = call i32 @fold_ff(%ff %a13)
  %m13 = icmp eq i32 %fe13, %fa13

  ; {half,half} finite, no +fullfp16
  %hh0 = insertvalue %hh zeroinitializer, half 0xH3E00, 0
  %hh1 = insertvalue %hh %hh0, half 0xHC080, 1
  %e14 = call %hh @reference_hh(ptr @swap_hh, %hh %hh1)
  %a14 = call %hh @protected_hh(ptr @swap_hh, %hh %hh1)
  %fe14 = call i32 @fold_hh(%hh %e14)
  %fa14 = call i32 @fold_hh(%hh %a14)
  %m14 = icmp eq i32 %fe14, %fa14

  ; {<2 x i32>, i32}
  %vf0 = insertvalue %vecf zeroinitializer, <2 x i32> <i32 4, i32 7>, 0
  %vf1 = insertvalue %vecf %vf0, i32 11, 1
  %e15 = call %vecf @reference_vecf(ptr @swap_vecf, %vecf %vf1)
  %a15 = call %vecf @protected_vecf(ptr @swap_vecf, %vecf %vf1)
  %fe15 = call i32 @fold_vecf(%vecf %e15)
  %fa15 = call i32 @fold_vecf(%vecf %a15)
  %m15 = icmp eq i32 %fe15, %fa15

  ; [2 x i32]
  %ar0 = insertvalue %arr zeroinitializer, i32 6, 0
  %ar1 = insertvalue %arr %ar0, i32 13, 1
  %e16 = call %arr @reference_arr(ptr @swap_arr, %arr %ar1)
  %a16 = call %arr @protected_arr(ptr @swap_arr, %arr %ar1)
  %fe16 = call i32 @fold_arr(%arr %e16)
  %fa16 = call i32 @fold_arr(%arr %a16)
  %m16 = icmp eq i32 %fe16, %fa16

  %t0 = and i1 %m0, %m1
  %t1 = and i1 %m2, %m3
  %t2 = and i1 %m4, %m5
  %t3 = and i1 %m6, %m7
  %t4 = and i1 %m8, %m9
  %t5 = and i1 %m10, %m11
  %t6 = and i1 %m12, %m13
  %t7 = and i1 %m14, %m15
  %u0 = and i1 %t0, %t1
  %u1 = and i1 %t2, %t3
  %u2 = and i1 %t4, %t5
  %u3 = and i1 %t6, %t7
  %u4 = and i1 %u0, %u1
  %u5 = and i1 %u2, %u3
  %ok = and i1 %u4, %u5
  %ok2 = and i1 %ok, %m16
  %code = select i1 %ok2, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_nested: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_wide: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_five: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_fastcc: indirect call
; SKIP-DAG: Skipping VMP on unsupported_vararg: indirect call
; SKIP-DAG: Skipping VMP on unsupported_byval: indirect call
; SKIP-NOT: Skipping VMP on protected_via_arg:
; SKIP-NOT: Skipping VMP on protected_via_select:
; SKIP-NOT: Skipping VMP on protected_via_global:
; SKIP-NOT: Skipping VMP on protected_via_phi:
; SKIP-NOT: Skipping VMP on protected_mixed_i32:
; SKIP-NOT: Skipping VMP on protected_sum:
; SKIP-NOT: Skipping VMP on protected_void:
; SKIP-NOT: Skipping VMP on protected_mixed:
; SKIP-NOT: Skipping VMP on protected_ff:
; SKIP-NOT: Skipping VMP on protected_hh:
; SKIP-NOT: Skipping VMP on protected_vecf:
; SKIP-NOT: Skipping VMP on protected_arr:

; VIRT: define %pair @protected_via_arg({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call %pair %{{.+}}(%pair
; VIRT: define %pair @protected_via_select({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call %pair %{{.+}}(%pair
; VIRT: define %pair @protected_via_global({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call %pair %{{.+}}(%pair
; VIRT: define %pair @protected_via_phi({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call %pair %{{.+}}(%pair
; VIRT: define %pair @protected_mixed_i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call %pair %{{.+}}(%pair {{.*}}, i32
; VIRT: define i32 @protected_sum({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 %{{.+}}(%pair
; VIRT: define void @protected_void({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void %{{.+}}(%pair
; VIRT: define %mixed @protected_mixed({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call %mixed %{{.+}}(%mixed
; VIRT: define %ff @protected_ff({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call %ff %{{.+}}(%ff
; VIRT: define %hh @protected_hh({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call %hh %{{.+}}(%hh
; VIRT: define %vecf @protected_vecf({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call %vecf %{{.+}}(%vecf
; VIRT: define {{.*}} @protected_arr({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call {{.*}} %{{.+}}(
; VIRT: define {{.*}} @unsupported_nested({{.*}} #[[UNSUPATTR:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_wide({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_five({{.*}} #[[UNSUPATTR]] {
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
