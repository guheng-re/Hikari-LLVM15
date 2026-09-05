; Strict AArch64 VMP indirect CallInst subset for same-type AS0 pointers:
; ptr(ptr) and ptr(ptr,ptr) via AS0 ptr, CallingConv::C, non-vararg.
; Function-pointer argument and select-of-globals callees.  Re-emitted as
; CreateCall(FunctionType*, Value*, Args) with callee and pointer args/results
; from the pointer VReg frame.  Inputs are global addresses or static stack
; addresses.  Independent icmp eq/ne of reference vs protected pointer
; returns (no ptrtoint/XOR mix).  void(ptr), mixed i32/ptr and f32/ptr,
; ternary, non-zero AS param/result/callee stay rejected.
;
; RUN: opt -S -verify-each -aesSeed=44 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.ll -o %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: opt -S -verify-each -aesSeed=44 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.ll -o %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll

target triple = "aarch64-unknown-linux-gnu"

; Distinct global addresses used as pointer inputs / known results.
@g_a = global i32 1, align 4
@g_b = global i32 2, align 4

declare void @hikari_vmp()

; ptr(ptr) helpers: identity vs ignore-input constant @g_b (distinct results).
define ptr @id_ptr(ptr %p) noinline {
entry:
  ret ptr %p
}

define ptr @const_b_ptr(ptr %p) noinline {
entry:
  ret ptr @g_b
}

; ptr(ptr,ptr) helpers: first vs second (not commutative; catches arg order).
define ptr @first_ptr(ptr %a, ptr %b) noinline {
entry:
  ret ptr %a
}

define ptr @second_ptr(ptr %a, ptr %b) noinline {
entry:
  ret ptr %b
}

; Reference / protected: ptr(ptr) via ptr argument.
define ptr @reference_via_arg_ptr(ptr %fp, ptr %p) {
entry:
  %r = call ptr %fp(ptr %p)
  ret ptr %r
}

define ptr @protected_via_arg_ptr(ptr %fp, ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call ptr %fp(ptr %p)
  ret ptr %r
}

; Reference / protected: ptr(ptr) via select of globals.
define ptr @reference_via_select_ptr(i1 %pick, ptr %p) {
entry:
  %fp = select i1 %pick, ptr @id_ptr, ptr @const_b_ptr
  %r = call ptr %fp(ptr %p)
  ret ptr %r
}

define ptr @protected_via_select_ptr(i1 %pick, ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %fp = select i1 %pick, ptr @id_ptr, ptr @const_b_ptr
  %r = call ptr %fp(ptr %p)
  ret ptr %r
}

; Reference / protected: ptr(ptr,ptr) via ptr argument.
define ptr @reference_binary_via_arg_ptr(ptr %fp, ptr %a, ptr %b) {
entry:
  %r = call ptr %fp(ptr %a, ptr %b)
  ret ptr %r
}

define ptr @protected_binary_via_arg_ptr(ptr %fp, ptr %a, ptr %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call ptr %fp(ptr %a, ptr %b)
  ret ptr %r
}

; Reference / protected: ptr(ptr,ptr) via select of globals.
define ptr @reference_binary_via_select_ptr(i1 %pick, ptr %a, ptr %b) {
entry:
  %fp = select i1 %pick, ptr @first_ptr, ptr @second_ptr
  %r = call ptr %fp(ptr %a, ptr %b)
  ret ptr %r
}

define ptr @protected_binary_via_select_ptr(i1 %pick, ptr %a, ptr %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %fp = select i1 %pick, ptr @first_ptr, ptr @second_ptr
  %r = call ptr %fp(ptr %a, ptr %b)
  ret ptr %r
}

; Safety skip: void(ptr) — not a returning same-type pointer form.
define void @unsupported_void_ptr(ptr %fp, ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  call void %fp(ptr %p)
  ret void
}

; Safety skip: mixed ptr(i32).
define ptr @unsupported_mixed_ptr_i32(ptr %fp, i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call ptr %fp(i32 %x)
  ret ptr %r
}

; Safety skip: mixed i32(ptr).
define i32 @unsupported_mixed_i32_ptr(ptr %fp, ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 %fp(ptr %p)
  ret i32 %r
}

; Safety skip: mixed ptr(float).
define ptr @unsupported_mixed_ptr_f32(ptr %fp, float %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call ptr %fp(float %x)
  ret ptr %r
}

; Safety skip: mixed float(ptr).
define float @unsupported_mixed_f32_ptr(ptr %fp, ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float %fp(ptr %p)
  ret float %r
}

; Safety skip: mixed binary ptr(ptr, i32).
define ptr @unsupported_mixed_ptr_i32_bin(ptr %fp, ptr %a, i32 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call ptr %fp(ptr %a, i32 %b)
  ret ptr %r
}

; Safety skip: ternary ptr(ptr,ptr,ptr) — unary/binary only.
define ptr @unsupported_ternary_ptr(ptr %fp, ptr %a, ptr %b, ptr %c) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call ptr %fp(ptr %a, ptr %b, ptr %c)
  ret ptr %r
}

; Safety skip: non-zero address-space parameter.
define ptr @unsupported_as1_arg(ptr %fp, ptr addrspace(1) %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call ptr %fp(ptr addrspace(1) %p)
  ret ptr %r
}

; Safety skip: non-zero address-space result.
define ptr addrspace(1) @unsupported_as1_ret(ptr %fp, ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call ptr addrspace(1) %fp(ptr %p)
  ret ptr addrspace(1) %r
}

; Safety skip: non-zero address-space function pointer.
define ptr @unsupported_as1_fp(ptr addrspace(1) %fp, ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call addrspace(1) ptr %fp(ptr %p)
  ret ptr %r
}

define i32 @main() {
entry:
  %stk_a = alloca i32, align 4
  %stk_b = alloca i32, align 4

  ; ptr(ptr) via arg, global inputs: identity vs const @g_b
  %e0 = call ptr @reference_via_arg_ptr(ptr @id_ptr, ptr @g_a)
  %a0 = call ptr @protected_via_arg_ptr(ptr @id_ptr, ptr @g_a)
  %m0 = icmp eq ptr %e0, %a0
  %k0 = icmp eq ptr %a0, @g_a
  %n0 = icmp ne ptr %a0, @g_b
  %e1 = call ptr @reference_via_arg_ptr(ptr @const_b_ptr, ptr @g_a)
  %a1 = call ptr @protected_via_arg_ptr(ptr @const_b_ptr, ptr @g_a)
  %m1 = icmp eq ptr %e1, %a1
  %k1 = icmp eq ptr %a1, @g_b
  %n1 = icmp ne ptr %a1, @g_a
  ; Distinct helpers: identity(@g_a) != const_b(@g_a)
  %d0 = icmp ne ptr %a0, %a1

  ; ptr(ptr) via select, global inputs
  %e2 = call ptr @reference_via_select_ptr(i1 true, ptr @g_a)
  %a2 = call ptr @protected_via_select_ptr(i1 true, ptr @g_a)
  %m2 = icmp eq ptr %e2, %a2
  %k2 = icmp eq ptr %a2, @g_a
  %e3 = call ptr @reference_via_select_ptr(i1 false, ptr @g_a)
  %a3 = call ptr @protected_via_select_ptr(i1 false, ptr @g_a)
  %m3 = icmp eq ptr %e3, %a3
  %k3 = icmp eq ptr %a3, @g_b
  %d1 = icmp ne ptr %a2, %a3

  ; ptr(ptr) via arg, static stack inputs
  %e4 = call ptr @reference_via_arg_ptr(ptr @id_ptr, ptr %stk_a)
  %a4 = call ptr @protected_via_arg_ptr(ptr @id_ptr, ptr %stk_a)
  %m4 = icmp eq ptr %e4, %a4
  %k4 = icmp eq ptr %a4, %stk_a
  %n4 = icmp ne ptr %a4, %stk_b
  %e5 = call ptr @reference_via_arg_ptr(ptr @const_b_ptr, ptr %stk_a)
  %a5 = call ptr @protected_via_arg_ptr(ptr @const_b_ptr, ptr %stk_a)
  %m5 = icmp eq ptr %e5, %a5
  %k5 = icmp eq ptr %a5, @g_b

  ; ptr(ptr,ptr) via arg, global inputs: first vs second (order)
  %e6 = call ptr @reference_binary_via_arg_ptr(ptr @first_ptr, ptr @g_a, ptr @g_b)
  %a6 = call ptr @protected_binary_via_arg_ptr(ptr @first_ptr, ptr @g_a, ptr @g_b)
  %m6 = icmp eq ptr %e6, %a6
  %k6 = icmp eq ptr %a6, @g_a
  %n6 = icmp ne ptr %a6, @g_b
  %e7 = call ptr @reference_binary_via_arg_ptr(ptr @second_ptr, ptr @g_a, ptr @g_b)
  %a7 = call ptr @protected_binary_via_arg_ptr(ptr @second_ptr, ptr @g_a, ptr @g_b)
  %m7 = icmp eq ptr %e7, %a7
  %k7 = icmp eq ptr %a7, @g_b
  %n7 = icmp ne ptr %a7, @g_a
  %d2 = icmp ne ptr %a6, %a7

  ; ptr(ptr,ptr) via select, global inputs
  %e8 = call ptr @reference_binary_via_select_ptr(i1 true, ptr @g_a, ptr @g_b)
  %a8 = call ptr @protected_binary_via_select_ptr(i1 true, ptr @g_a, ptr @g_b)
  %m8 = icmp eq ptr %e8, %a8
  %k8 = icmp eq ptr %a8, @g_a
  %e9 = call ptr @reference_binary_via_select_ptr(i1 false, ptr @g_a, ptr @g_b)
  %a9 = call ptr @protected_binary_via_select_ptr(i1 false, ptr @g_a, ptr @g_b)
  %m9 = icmp eq ptr %e9, %a9
  %k9 = icmp eq ptr %a9, @g_b
  %d3 = icmp ne ptr %a8, %a9

  ; ptr(ptr,ptr) via arg, static stack inputs (argument order)
  %e10 = call ptr @reference_binary_via_arg_ptr(ptr @first_ptr, ptr %stk_a, ptr %stk_b)
  %a10 = call ptr @protected_binary_via_arg_ptr(ptr @first_ptr, ptr %stk_a, ptr %stk_b)
  %m10 = icmp eq ptr %e10, %a10
  %k10 = icmp eq ptr %a10, %stk_a
  %n10 = icmp ne ptr %a10, %stk_b
  %e11 = call ptr @reference_binary_via_arg_ptr(ptr @second_ptr, ptr %stk_a, ptr %stk_b)
  %a11 = call ptr @protected_binary_via_arg_ptr(ptr @second_ptr, ptr %stk_a, ptr %stk_b)
  %m11 = icmp eq ptr %e11, %a11
  %k11 = icmp eq ptr %a11, %stk_b
  %n11 = icmp ne ptr %a11, %stk_a
  %d4 = icmp ne ptr %a10, %a11

  ; Independent and-reduction (no XOR mix of pointer results).
  %t0 = and i1 %m0, %m1
  %t1 = and i1 %k0, %n0
  %t2 = and i1 %k1, %n1
  %t3 = and i1 %d0, %m2
  %t4 = and i1 %k2, %m3
  %t5 = and i1 %k3, %d1
  %t6 = and i1 %m4, %k4
  %t7 = and i1 %n4, %m5
  %t8 = and i1 %k5, %m6
  %t9 = and i1 %k6, %n6
  %t10 = and i1 %m7, %k7
  %t11 = and i1 %n7, %d2
  %t12 = and i1 %m8, %k8
  %t13 = and i1 %m9, %k9
  %t14 = and i1 %d3, %m10
  %t15 = and i1 %k10, %n10
  %t16 = and i1 %m11, %k11
  %t17 = and i1 %n11, %d4
  %u0 = and i1 %t0, %t1
  %u1 = and i1 %t2, %t3
  %u2 = and i1 %t4, %t5
  %u3 = and i1 %t6, %t7
  %u4 = and i1 %t8, %t9
  %u5 = and i1 %t10, %t11
  %u6 = and i1 %t12, %t13
  %u7 = and i1 %t14, %t15
  %u8 = and i1 %t16, %t17
  %v0 = and i1 %u0, %u1
  %v1 = and i1 %u2, %u3
  %v2 = and i1 %u4, %u5
  %v3 = and i1 %u6, %u7
  %w0 = and i1 %v0, %v1
  %w1 = and i1 %v2, %v3
  %ok = and i1 %w0, %w1
  %ok2 = and i1 %ok, %u8
  %code = select i1 %ok2, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with: 44
; SKIP-DAG: Skipping VMP on unsupported_as1_arg: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_as1_ret: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_as1_fp: unsupported argument type
; SKIP-NOT: Skipping VMP on protected_via_arg_ptr:
; SKIP-NOT: Skipping VMP on protected_via_select_ptr:
; SKIP-NOT: Skipping VMP on protected_binary_via_arg_ptr:
; SKIP-NOT: Skipping VMP on protected_binary_via_select_ptr:

; VIRT: define ptr @protected_via_arg_ptr({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call ptr %{{.+}}(ptr
; VIRT: define ptr @protected_via_select_ptr({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call ptr %{{.+}}(ptr
; VIRT: define ptr @protected_binary_via_arg_ptr({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call ptr %{{.+}}(ptr {{.*}}, ptr
; VIRT: define ptr @protected_binary_via_select_ptr({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call ptr %{{.+}}(ptr {{.*}}, ptr
; VIRT: define ptr @unsupported_as1_arg(
; VIRT-NOT: vmp.dispatch
; VIRT: call ptr %{{.+}}(ptr addrspace(1)
; VIRT: define ptr addrspace(1) @unsupported_as1_ret(
; VIRT-NOT: vmp.dispatch
; VIRT: call ptr addrspace(1) %{{.+}}(ptr
; VIRT: define ptr @unsupported_as1_fp(
; VIRT-NOT: vmp.dispatch
; VIRT: call addrspace(1) ptr %{{.+}}(ptr
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
