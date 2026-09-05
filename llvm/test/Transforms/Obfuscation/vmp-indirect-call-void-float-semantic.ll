; Strict AArch64 VMP indirect CallInst subset for void scalar-FP callbacks:
; void(f32) and void(f64) via AS0 ptr, CallingConv::C, non-vararg, unary only.
; Function-pointer argument and select-of-globals callees.  Re-emitted as
; CreateCall(FunctionType*, Value*, Args) with callee from a pointer VReg and
; the scalar argument from the float VReg frame.  Independent global slots
; observe callback side effects (no XOR mix of functions or widths).
; Zero-arg / binary+ / bfloat / wide vector / pointer / mixed / non-zero AS stay out.
; Scalar IEEE half void callbacks live on the mixed-scalar subset
; (vmp-indirect-call-half-semantic.ll).  Supported fixed-vector void
; callbacks live in vmp-indirect-call-vector-semantic.ll; this file
; keeps function-level bfloat and >128-bit vector rejects.
; Returning-FP FMF rejection is unchanged (void calls are not FPMathOperators).
;
; RUN: opt -S -verify-each -aesSeed=43 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.ll -o %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: opt -S -verify-each -aesSeed=43 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.ll -o %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll

target triple = "aarch64-unknown-linux-gnu"

; Independent observation slots: one per callback kind and width.
@slot_f32_id = global float 0.000000e+00, align 4
@slot_f32_neg = global float 0.000000e+00, align 4
@slot_f64_id = global double 0.000000e+00, align 8
@slot_f64_neg = global double 0.000000e+00, align 8

declare void @hikari_vmp()

; void(f32) helpers: identity store vs fneg store (distinct finite results).
define void @store_f32(float %x) noinline {
entry:
  store float %x, ptr @slot_f32_id, align 4
  ret void
}

define void @store_neg_f32(float %x) noinline {
entry:
  %n = fneg float %x
  store float %n, ptr @slot_f32_neg, align 4
  ret void
}

; void(f64) helpers.
define void @store_f64(double %x) noinline {
entry:
  store double %x, ptr @slot_f64_id, align 8
  ret void
}

define void @store_neg_f64(double %x) noinline {
entry:
  %n = fneg double %x
  store double %n, ptr @slot_f64_neg, align 8
  ret void
}

; Reference / protected: void(f32) via ptr argument.
define void @reference_void_via_arg_f32(ptr %fp, float %x) {
entry:
  call void %fp(float %x)
  ret void
}

define void @protected_void_via_arg_f32(ptr %fp, float %x) noinline optnone {
entry:
  call void @hikari_vmp()
  call void %fp(float %x)
  ret void
}

; Reference / protected: void(f32) via select of globals.
define void @reference_void_via_select_f32(i1 %pick, float %x) {
entry:
  %fp = select i1 %pick, ptr @store_f32, ptr @store_neg_f32
  call void %fp(float %x)
  ret void
}

define void @protected_void_via_select_f32(i1 %pick, float %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %fp = select i1 %pick, ptr @store_f32, ptr @store_neg_f32
  call void %fp(float %x)
  ret void
}

; Reference / protected: void(f64) via ptr argument.
define void @reference_void_via_arg_f64(ptr %fp, double %x) {
entry:
  call void %fp(double %x)
  ret void
}

define void @protected_void_via_arg_f64(ptr %fp, double %x) noinline optnone {
entry:
  call void @hikari_vmp()
  call void %fp(double %x)
  ret void
}

; Reference / protected: void(f64) via select of globals.
define void @reference_void_via_select_f64(i1 %pick, double %x) {
entry:
  %fp = select i1 %pick, ptr @store_f64, ptr @store_neg_f64
  call void %fp(double %x)
  ret void
}

define void @protected_void_via_select_f64(i1 %pick, double %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %fp = select i1 %pick, ptr @store_f64, ptr @store_neg_f64
  call void %fp(double %x)
  ret void
}

; Safety skip: void(f32, f32) — unary only.
define void @unsupported_void_f32_f32(ptr %fp, float %a, float %b) noinline optnone {
entry:
  call void @hikari_vmp()
  call void %fp(float %a, float %b)
  ret void
}

; Safety skip: void(f64, f64) — unary only.
define void @unsupported_void_f64_f64(ptr %fp, double %a, double %b) noinline optnone {
entry:
  call void @hikari_vmp()
  call void %fp(double %a, double %b)
  ret void
}

; Safety skip: void(bfloat) — not IEEE scalar half/f32/f64.
define void @unsupported_void_bfloat(ptr %fp, bfloat %x) noinline optnone {
entry:
  call void @hikari_vmp()
  call void %fp(bfloat %x)
  ret void
}

; Safety skip: void(>128-bit vector) — not a supported fixed vector.
define void @unsupported_void_vector(ptr %fp, <8 x float> %x) noinline optnone {
entry:
  call void @hikari_vmp()
  call void %fp(<8 x float> %x)
  ret void
}

; Safety skip: non-zero address-space callee pointer.
define void @unsupported_as1(ptr addrspace(1) %fp, float %x) noinline optnone {
entry:
  call void @hikari_vmp()
  call addrspace(1) void %fp(float %x)
  ret void
}

; Safety skip: void() zero-arg — not the unary void(f32)/void(f64) form.
define void @unsupported_void_zero(ptr %fp) noinline optnone {
entry:
  call void @hikari_vmp()
  call void %fp()
  ret void
}

; Safety skip: void(ptr) — pointer parameter stays out.
define void @unsupported_void_ptr(ptr %fp, ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  call void %fp(ptr %p)
  ret void
}

; Safety skip: mixed void(f32, f64) — not same-type unary.
define void @unsupported_mixed_f32_f64(ptr %fp, float %a, double %b) noinline optnone {
entry:
  call void @hikari_vmp()
  call void %fp(float %a, double %b)
  ret void
}

define i32 @main() {
entry:
  ; void(f32) via arg: identity and fneg, finite non-NaN, independent slots
  store float 0.000000e+00, ptr @slot_f32_id, align 4
  call void @reference_void_via_arg_f32(ptr @store_f32, float 1.500000e+00)
  %ev0 = load float, ptr @slot_f32_id, align 4
  store float 0.000000e+00, ptr @slot_f32_id, align 4
  call void @protected_void_via_arg_f32(ptr @store_f32, float 1.500000e+00)
  %av0 = load float, ptr @slot_f32_id, align 4
  %be0 = bitcast float %ev0 to i32
  %ba0 = bitcast float %av0 to i32
  %m0 = icmp eq i32 %be0, %ba0
  store float 0.000000e+00, ptr @slot_f32_neg, align 4
  call void @reference_void_via_arg_f32(ptr @store_neg_f32, float -2.250000e+00)
  %ev1 = load float, ptr @slot_f32_neg, align 4
  store float 0.000000e+00, ptr @slot_f32_neg, align 4
  call void @protected_void_via_arg_f32(ptr @store_neg_f32, float -2.250000e+00)
  %av1 = load float, ptr @slot_f32_neg, align 4
  %be1 = bitcast float %ev1 to i32
  %ba1 = bitcast float %av1 to i32
  %m1 = icmp eq i32 %be1, %ba1
  ; void(f32) via select
  store float 0.000000e+00, ptr @slot_f32_id, align 4
  call void @reference_void_via_select_f32(i1 true, float 3.000000e+00)
  %ev2 = load float, ptr @slot_f32_id, align 4
  store float 0.000000e+00, ptr @slot_f32_id, align 4
  call void @protected_void_via_select_f32(i1 true, float 3.000000e+00)
  %av2 = load float, ptr @slot_f32_id, align 4
  %be2 = bitcast float %ev2 to i32
  %ba2 = bitcast float %av2 to i32
  %m2 = icmp eq i32 %be2, %ba2
  store float 0.000000e+00, ptr @slot_f32_neg, align 4
  call void @reference_void_via_select_f32(i1 false, float -4.000000e+00)
  %ev3 = load float, ptr @slot_f32_neg, align 4
  store float 0.000000e+00, ptr @slot_f32_neg, align 4
  call void @protected_void_via_select_f32(i1 false, float -4.000000e+00)
  %av3 = load float, ptr @slot_f32_neg, align 4
  %be3 = bitcast float %ev3 to i32
  %ba3 = bitcast float %av3 to i32
  %m3 = icmp eq i32 %be3, %ba3
  ; void(f64) via arg
  store double 0.000000e+00, ptr @slot_f64_id, align 8
  call void @reference_void_via_arg_f64(ptr @store_f64, double 1.500000e+00)
  %ev4 = load double, ptr @slot_f64_id, align 8
  store double 0.000000e+00, ptr @slot_f64_id, align 8
  call void @protected_void_via_arg_f64(ptr @store_f64, double 1.500000e+00)
  %av4 = load double, ptr @slot_f64_id, align 8
  %be4 = bitcast double %ev4 to i64
  %ba4 = bitcast double %av4 to i64
  %m4 = icmp eq i64 %be4, %ba4
  store double 0.000000e+00, ptr @slot_f64_neg, align 8
  call void @reference_void_via_arg_f64(ptr @store_neg_f64, double -2.250000e+00)
  %ev5 = load double, ptr @slot_f64_neg, align 8
  store double 0.000000e+00, ptr @slot_f64_neg, align 8
  call void @protected_void_via_arg_f64(ptr @store_neg_f64, double -2.250000e+00)
  %av5 = load double, ptr @slot_f64_neg, align 8
  %be5 = bitcast double %ev5 to i64
  %ba5 = bitcast double %av5 to i64
  %m5 = icmp eq i64 %be5, %ba5
  ; void(f64) via select
  store double 0.000000e+00, ptr @slot_f64_id, align 8
  call void @reference_void_via_select_f64(i1 true, double 3.000000e+00)
  %ev6 = load double, ptr @slot_f64_id, align 8
  store double 0.000000e+00, ptr @slot_f64_id, align 8
  call void @protected_void_via_select_f64(i1 true, double 3.000000e+00)
  %av6 = load double, ptr @slot_f64_id, align 8
  %be6 = bitcast double %ev6 to i64
  %ba6 = bitcast double %av6 to i64
  %m6 = icmp eq i64 %be6, %ba6
  store double 0.000000e+00, ptr @slot_f64_neg, align 8
  call void @reference_void_via_select_f64(i1 false, double -4.000000e+00)
  %ev7 = load double, ptr @slot_f64_neg, align 8
  store double 0.000000e+00, ptr @slot_f64_neg, align 8
  call void @protected_void_via_select_f64(i1 false, double -4.000000e+00)
  %av7 = load double, ptr @slot_f64_neg, align 8
  %be7 = bitcast double %ev7 to i64
  %ba7 = bitcast double %av7 to i64
  %m7 = icmp eq i64 %be7, %ba7
  %t0 = and i1 %m0, %m1
  %t1 = and i1 %m2, %m3
  %t2 = and i1 %m4, %m5
  %t3 = and i1 %m6, %m7
  %t4 = and i1 %t0, %t1
  %t5 = and i1 %t2, %t3
  %ok = and i1 %t4, %t5
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with: 43
; SKIP-DAG: Skipping VMP on unsupported_void_bfloat: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_void_vector: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_as1: unsupported argument type
; SKIP-NOT: Skipping VMP on protected_void_via_arg_f32:
; SKIP-NOT: Skipping VMP on protected_void_via_select_f32:
; SKIP-NOT: Skipping VMP on protected_void_via_arg_f64:
; SKIP-NOT: Skipping VMP on protected_void_via_select_f64:

; VIRT: define void @protected_void_via_arg_f32({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call void %{{.+}}(float
; VIRT: define void @protected_void_via_select_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void %{{.+}}(float
; VIRT: define void @protected_void_via_arg_f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void %{{.+}}(double
; VIRT: define void @protected_void_via_select_f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void %{{.+}}(double
; VIRT: define void @unsupported_void_bfloat(
; VIRT-NOT: vmp.dispatch
; VIRT: call void %{{.+}}(bfloat
; VIRT: define void @unsupported_void_vector(
; VIRT-NOT: vmp.dispatch
; VIRT: call void %{{.+}}(<8 x float>
; VIRT: define void @unsupported_as1(
; VIRT-NOT: vmp.dispatch
; VIRT: call addrspace(1) void %{{.+}}(float
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
