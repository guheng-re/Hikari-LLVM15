; Mixed-scalar indirect CallInst: IEEE scalar half args and/or returns
; on the existing 0..8 C non-vararg subset.  Callee is an AS0 pointer
; VReg (function-pointer argument, global table load, select, or phi).
; Replay uses the existing float VReg + CallDescriptor; any valid
; FastMathFlags on a half return are restored.  No +fullfp16 gate —
; this is call ABI, not a half math intrinsic.
; Supported fixed half-vector args/returns live in
; vmp-indirect-call-vector-semantic.ll; this file keeps a >128-bit
; half-vector reject.  Supported {half,half} indirect args/returns live
; in vmp-indirect-call-aggregate-semantic.ll; this file keeps a nested
; aggregate reject.
;
; Finite ordinary bit patterns only (no NaN / Inf) for host lli
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

%hh = type { half, half }
%hhnest = type { { %hh, i32 }, i32 }

declare void @hikari_vmp()

@slot.h = global half 0xH0000, align 2
@vt.h = global [2 x ptr] [ptr @hneg, ptr @hadd1], align 8

; half(half): fneg vs add-one (distinct finite results).
define half @hneg(half %x) noinline {
entry:
  %r = fneg half %x
  ret half %r
}

define half @hadd1(half %x) noinline {
entry:
  %r = fadd half %x, 0xH3C00
  ret half %r
}

; half(half, half): fadd vs non-commutative fsub.
define half @hadd(half %a, half %b) noinline {
entry:
  %r = fadd half %a, %b
  ret half %r
}

define half @hsub(half %a, half %b) noinline {
entry:
  %r = fsub half %a, %b
  ret half %r
}

; half(half, i32): mix a half arg with an existing integer type.
define half @hadd_i32(half %x, i32 %k) noinline {
entry:
  %kf = sitofp i32 %k to half
  %r = fadd half %x, %kf
  ret half %r
}

; i32(half): half argument, existing integer return.
define i32 @htoi(half %x) noinline {
entry:
  %r = fptosi half %x to i32
  ret i32 %r
}

; half(float): do not tighten the existing f32 operand rule.
define half @hfromf(float %x) noinline {
entry:
  %r = fptrunc float %x to half
  ret half %r
}

; void(half) side effect.
define void @store_h(half %x) noinline {
entry:
  store half %x, ptr @slot.h, align 2
  ret void
}

define void @store_neg_h(half %x) noinline {
entry:
  %n = fneg half %x
  store half %n, ptr @slot.h, align 2
  ret void
}

; ----- reference / protected: half(half) via function-pointer argument -----

define half @reference_via_arg(ptr %fp, half %x) {
entry:
  %r = call half %fp(half %x)
  ret half %r
}

define half @protected_via_arg(ptr %fp, half %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call half %fp(half %x)
  ret half %r
}

; ----- reference / protected: half(half) via select of globals -----

define half @reference_via_select(i1 %pick, half %x) {
entry:
  %fp = select i1 %pick, ptr @hneg, ptr @hadd1
  %r = call half %fp(half %x)
  ret half %r
}

define half @protected_via_select(i1 %pick, half %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %fp = select i1 %pick, ptr @hneg, ptr @hadd1
  %r = call half %fp(half %x)
  ret half %r
}

; ----- reference / protected: half(half) via global table load -----

define half @reference_via_global(i64 %idx, half %x) {
entry:
  %slot = getelementptr inbounds [2 x ptr], ptr @vt.h, i64 0, i64 %idx
  %fp = load ptr, ptr %slot, align 8
  %r = call half %fp(half %x)
  ret half %r
}

define half @protected_via_global(i64 %idx, half %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %slot = getelementptr inbounds [2 x ptr], ptr @vt.h, i64 0, i64 %idx
  %fp = load ptr, ptr %slot, align 8
  %r = call half %fp(half %x)
  ret half %r
}

; ----- reference / protected: half(half) via phi of globals -----

define half @reference_via_phi(i1 %pick, half %x) {
entry:
  br i1 %pick, label %left, label %right

left:
  br label %join

right:
  br label %join

join:
  %fp = phi ptr [ @hneg, %left ], [ @hadd1, %right ]
  %r = call half %fp(half %x)
  ret half %r
}

define half @protected_via_phi(i1 %pick, half %x) noinline optnone {
entry:
  call void @hikari_vmp()
  br i1 %pick, label %left, label %right

left:
  br label %join

right:
  br label %join

join:
  %fp = phi ptr [ @hneg, %left ], [ @hadd1, %right ]
  %r = call half %fp(half %x)
  ret half %r
}

; ----- half(half, half) via function-pointer argument -----

define half @reference_binary_via_arg(ptr %fp, half %a, half %b) {
entry:
  %r = call half %fp(half %a, half %b)
  ret half %r
}

define half @protected_binary_via_arg(ptr %fp, half %a, half %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call half %fp(half %a, half %b)
  ret half %r
}

; ----- half return + half and i32 args -----

define half @reference_mixed_i32(ptr %fp, half %x, i32 %k) {
entry:
  %r = call half %fp(half %x, i32 %k)
  ret half %r
}

define half @protected_mixed_i32(ptr %fp, half %x, i32 %k) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call half %fp(half %x, i32 %k)
  ret half %r
}

; ----- i32 return + half arg -----

define i32 @reference_htoi(ptr %fp, half %x) {
entry:
  %r = call i32 %fp(half %x)
  ret i32 %r
}

define i32 @protected_htoi(ptr %fp, half %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 %fp(half %x)
  ret i32 %r
}

; ----- half return + existing f32 arg (do not tighten f32) -----

define half @reference_from_f32(ptr %fp, float %x) {
entry:
  %r = call half %fp(float %x)
  ret half %r
}

define half @protected_from_f32(ptr %fp, float %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call half %fp(float %x)
  ret half %r
}

; ----- void(half) via function-pointer argument -----

define void @reference_void(ptr %fp, half %x) {
entry:
  call void %fp(half %x)
  ret void
}

define void @protected_void(ptr %fp, half %x) noinline optnone {
entry:
  call void @hikari_vmp()
  call void %fp(half %x)
  ret void
}

; ----- FMF on half returns (structure + finite bit match) -----

define half @reference_fast(ptr %fp, half %x) {
entry:
  %r = call fast half %fp(half %x)
  ret half %r
}

define half @protected_fast(ptr %fp, half %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fast half %fp(half %x)
  ret half %r
}

define half @reference_nnan(ptr %fp, half %a, half %b) {
entry:
  %r = call nnan ninf half %fp(half %a, half %b)
  ret half %r
}

define half @protected_nnan(ptr %fp, half %a, half %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call nnan ninf half %fp(half %a, half %b)
  ret half %r
}

; ----- negatives: selected, not virtualized -----

define <16 x half> @unsupported_half_vector(ptr %fp, <16 x half> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <16 x half> %fp(<16 x half> %v)
  ret <16 x half> %r
}

define %hhnest @unsupported_aggregate(ptr %fp, %hhnest %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call %hhnest %fp(%hhnest %p)
  ret %hhnest %r
}

define half @unsupported_fastcc(ptr %fp, half %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc half %fp(half %x)
  ret half %r
}

define half @unsupported_vararg(ptr %fp, half %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call half (half, ...) %fp(half %x, half 0xH3C00)
  ret half %r
}

define half @unsupported_byval(ptr %fp, ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call half %fp(ptr byval(%hh) %p)
  ret half %r
}

define i32 @main() {
entry:
  ; half(half) via arg: fneg / add1, finite non-NaN
  %e0 = call half @reference_via_arg(ptr @hneg, half 0xH3E00)
  %a0 = call half @protected_via_arg(ptr @hneg, half 0xH3E00)
  %be0 = bitcast half %e0 to i16
  %ba0 = bitcast half %a0 to i16
  %m0 = icmp eq i16 %be0, %ba0
  %e1 = call half @reference_via_arg(ptr @hadd1, half 0xHC080)
  %a1 = call half @protected_via_arg(ptr @hadd1, half 0xHC080)
  %be1 = bitcast half %e1 to i16
  %ba1 = bitcast half %a1 to i16
  %m1 = icmp eq i16 %be1, %ba1

  ; half(half) via select
  %e2 = call half @reference_via_select(i1 true, half 0xH4200)
  %a2 = call half @protected_via_select(i1 true, half 0xH4200)
  %be2 = bitcast half %e2 to i16
  %ba2 = bitcast half %a2 to i16
  %m2 = icmp eq i16 %be2, %ba2
  %e3 = call half @reference_via_select(i1 false, half 0xHC400)
  %a3 = call half @protected_via_select(i1 false, half 0xHC400)
  %be3 = bitcast half %e3 to i16
  %ba3 = bitcast half %a3 to i16
  %m3 = icmp eq i16 %be3, %ba3

  ; half(half) via global table
  %e4 = call half @reference_via_global(i64 0, half 0xH4100)
  %a4 = call half @protected_via_global(i64 0, half 0xH4100)
  %be4 = bitcast half %e4 to i16
  %ba4 = bitcast half %a4 to i16
  %m4 = icmp eq i16 %be4, %ba4
  %e5 = call half @reference_via_global(i64 1, half 0xH3800)
  %a5 = call half @protected_via_global(i64 1, half 0xH3800)
  %be5 = bitcast half %e5 to i16
  %ba5 = bitcast half %a5 to i16
  %m5 = icmp eq i16 %be5, %ba5

  ; half(half) via phi
  %e6 = call half @reference_via_phi(i1 true, half 0xH4000)
  %a6 = call half @protected_via_phi(i1 true, half 0xH4000)
  %be6 = bitcast half %e6 to i16
  %ba6 = bitcast half %a6 to i16
  %m6 = icmp eq i16 %be6, %ba6
  %e7 = call half @reference_via_phi(i1 false, half 0xH4500)
  %a7 = call half @protected_via_phi(i1 false, half 0xH4500)
  %be7 = bitcast half %e7 to i16
  %ba7 = bitcast half %a7 to i16
  %m7 = icmp eq i16 %be7, %ba7

  ; half(half, half) via arg: fadd / non-commutative fsub
  %e8 = call half @reference_binary_via_arg(ptr @hadd, half 0xH4200, half 0xH3800)
  %a8 = call half @protected_binary_via_arg(ptr @hadd, half 0xH4200, half 0xH3800)
  %be8 = bitcast half %e8 to i16
  %ba8 = bitcast half %a8 to i16
  %m8 = icmp eq i16 %be8, %ba8
  %e9 = call half @reference_binary_via_arg(ptr @hsub, half 0xHC500, half 0xH4000)
  %a9 = call half @protected_binary_via_arg(ptr @hsub, half 0xHC500, half 0xH4000)
  %be9 = bitcast half %e9 to i16
  %ba9 = bitcast half %a9 to i16
  %m9 = icmp eq i16 %be9, %ba9

  ; half + i32 mix
  %e10 = call half @reference_mixed_i32(ptr @hadd_i32, half 0xH4000, i32 3)
  %a10 = call half @protected_mixed_i32(ptr @hadd_i32, half 0xH4000, i32 3)
  %be10 = bitcast half %e10 to i16
  %ba10 = bitcast half %a10 to i16
  %m10 = icmp eq i16 %be10, %ba10

  ; i32(half)
  %e11 = call i32 @reference_htoi(ptr @htoi, half 0xH4500)
  %a11 = call i32 @protected_htoi(ptr @htoi, half 0xH4500)
  %m11 = icmp eq i32 %e11, %a11

  ; half(float)
  %e12 = call half @reference_from_f32(ptr @hfromf, float 2.500000e+00)
  %a12 = call half @protected_from_f32(ptr @hfromf, float 2.500000e+00)
  %be12 = bitcast half %e12 to i16
  %ba12 = bitcast half %a12 to i16
  %m12 = icmp eq i16 %be12, %ba12

  ; void(half) identity / fneg via independent slot resets
  store half 0xH0000, ptr @slot.h, align 2
  call void @reference_void(ptr @store_h, half 0xH3E00)
  %ev13 = load half, ptr @slot.h, align 2
  store half 0xH0000, ptr @slot.h, align 2
  call void @protected_void(ptr @store_h, half 0xH3E00)
  %av13 = load half, ptr @slot.h, align 2
  %be13 = bitcast half %ev13 to i16
  %ba13 = bitcast half %av13 to i16
  %m13 = icmp eq i16 %be13, %ba13
  store half 0xH0000, ptr @slot.h, align 2
  call void @reference_void(ptr @store_neg_h, half 0xHC080)
  %ev14 = load half, ptr @slot.h, align 2
  store half 0xH0000, ptr @slot.h, align 2
  call void @protected_void(ptr @store_neg_h, half 0xHC080)
  %av14 = load half, ptr @slot.h, align 2
  %be14 = bitcast half %ev14 to i16
  %ba14 = bitcast half %av14 to i16
  %m14 = icmp eq i16 %be14, %ba14

  ; FMF half returns, finite bits
  %e15 = call half @reference_fast(ptr @hneg, half 0xH3E00)
  %a15 = call half @protected_fast(ptr @hneg, half 0xH3E00)
  %be15 = bitcast half %e15 to i16
  %ba15 = bitcast half %a15 to i16
  %m15 = icmp eq i16 %be15, %ba15
  %e16 = call half @reference_nnan(ptr @hadd, half 0xH4700, half 0xH4000)
  %a16 = call half @protected_nnan(ptr @hadd, half 0xH4700, half 0xH4000)
  %be16 = bitcast half %e16 to i16
  %ba16 = bitcast half %a16 to i16
  %m16 = icmp eq i16 %be16, %ba16

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
; SKIP-DAG: Skipping VMP on unsupported_half_vector: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_aggregate: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_fastcc: indirect call
; SKIP-DAG: Skipping VMP on unsupported_vararg: indirect call
; SKIP-DAG: Skipping VMP on unsupported_byval: indirect call
; SKIP-NOT: Skipping VMP on protected_via_arg:
; SKIP-NOT: Skipping VMP on protected_via_select:
; SKIP-NOT: Skipping VMP on protected_via_global:
; SKIP-NOT: Skipping VMP on protected_via_phi:
; SKIP-NOT: Skipping VMP on protected_binary_via_arg:
; SKIP-NOT: Skipping VMP on protected_mixed_i32:
; SKIP-NOT: Skipping VMP on protected_htoi:
; SKIP-NOT: Skipping VMP on protected_from_f32:
; SKIP-NOT: Skipping VMP on protected_void:
; SKIP-NOT: Skipping VMP on protected_fast:
; SKIP-NOT: Skipping VMP on protected_nnan:

; VIRT: define half @protected_via_arg({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call half %{{.+}}(half
; VIRT: define half @protected_via_select({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call half %{{.+}}(half
; VIRT: define half @protected_via_global({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call half %{{.+}}(half
; VIRT: define half @protected_via_phi({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call half %{{.+}}(half
; VIRT: define half @protected_binary_via_arg({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call half %{{.+}}(half {{.*}}, half
; VIRT: define half @protected_mixed_i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call half %{{.+}}(half {{.*}}, i32
; VIRT: define i32 @protected_htoi({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 %{{.+}}(half
; VIRT: define half @protected_from_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call half %{{.+}}(float
; VIRT: define void @protected_void({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void %{{.+}}(half
; VIRT: define half @protected_fast({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call fast half %{{.+}}(half
; VIRT: define half @protected_nnan({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call nnan ninf half %{{.+}}(half {{.*}}, half
; VIRT: define {{.*}} @unsupported_half_vector({{.*}} #[[UNSUPATTR:[0-9]+]] {
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
