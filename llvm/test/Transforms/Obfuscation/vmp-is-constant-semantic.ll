; Restricted llvm.is.constant (__builtin_constant_p) lowers to a Move
; of i1 true/false.  Must not CallDescriptor-replay: a VReg load is
; never a manifest constant, so replay would fold every originally-
; constant operand to false.  Matches LowerConstantIntrinsics:
; true iff the original operand is a manifest compile-time constant
; (ConstantInt/FP/null / ConstantExpr of those, including i128 and
; supported fixed vectors).  GlobalValue is a Constant but not
; manifest.  An add of a volatile load is runtime SSA and stays
; false at O0 and O2.  Host lli cannot execute the intrinsic, so
; main checks known 0/1 results.  poison / undef / musttail /
; bundles stay rejected; i2 / AS1 / >128-bit vectors skip as
; unsupported argument types.  No new opcode.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64

target triple = "aarch64-unknown-linux-gnu"

@g_i32 = global i32 40, align 4
@g_arr = global [2 x i32] [i32 1, i32 2], align 4

declare void @hikari_vmp()
declare i1 @llvm.is.constant.i1(i1)
declare i1 @llvm.is.constant.i8(i8)
declare i1 @llvm.is.constant.i16(i16)
declare i1 @llvm.is.constant.i32(i32)
declare i1 @llvm.is.constant.i64(i64)
declare i1 @llvm.is.constant.i128(i128)
declare i1 @llvm.is.constant.i2(i2)
declare i1 @llvm.is.constant.p0(ptr)
declare i1 @llvm.is.constant.p1(ptr addrspace(1))
declare i1 @llvm.is.constant.f16(half)
declare i1 @llvm.is.constant.f32(float)
declare i1 @llvm.is.constant.f64(double)
declare i1 @llvm.is.constant.v2i32(<2 x i32>)
declare i1 @llvm.is.constant.v4i32(<4 x i32>)
declare i1 @llvm.is.constant.v2f32(<2 x float>)
declare i1 @llvm.is.constant.v8i32(<8 x i32>)

define i32 @sink_i32(ptr %p, i32 %x) {
entry:
  ret i32 %x
}

define i32 @protected_is_constant_i32() noinline optnone {
entry:
  call void @hikari_vmp()
  %c = call i1 @llvm.is.constant.i32(i32 5)
  %z = zext i1 %c to i32
  ret i32 %z
}

define i32 @protected_is_constant_runtime(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %c = call i1 @llvm.is.constant.i32(i32 %x)
  %z = zext i1 %c to i32
  ret i32 %z
}

define i32 @protected_is_constant_widths() noinline optnone {
entry:
  call void @hikari_vmp()
  %a = call i1 @llvm.is.constant.i1(i1 true)
  %b = call i1 @llvm.is.constant.i8(i8 3)
  %c = call i1 @llvm.is.constant.i16(i16 4)
  %d = call i1 @llvm.is.constant.i64(i64 7)
  %az = zext i1 %a to i32
  %bz = zext i1 %b to i32
  %cz = zext i1 %c to i32
  %dz = zext i1 %d to i32
  %s0 = add i32 %az, %bz
  %s1 = add i32 %s0, %cz
  %s2 = add i32 %s1, %dz
  ret i32 %s2
}

define i32 @protected_is_constant_ptr_null() noinline optnone {
entry:
  call void @hikari_vmp()
  %c = call i1 @llvm.is.constant.p0(ptr null)
  %z = zext i1 %c to i32
  ret i32 %z
}

define i32 @protected_is_constant_global() noinline optnone {
entry:
  call void @hikari_vmp()
  %c = call i1 @llvm.is.constant.p0(ptr @g_i32)
  %z = zext i1 %c to i32
  ret i32 %z
}

define i32 @protected_is_constant_inttoptr() noinline optnone {
entry:
  call void @hikari_vmp()
  %c = call i1 @llvm.is.constant.p0(ptr inttoptr (i64 16 to ptr))
  %z = zext i1 %c to i32
  ret i32 %z
}

define i32 @protected_is_constant_gep_global() noinline optnone {
entry:
  call void @hikari_vmp()
  %c = call i1 @llvm.is.constant.p0(ptr getelementptr ([2 x i32], ptr @g_arr, i64 0, i64 1))
  %z = zext i1 %c to i32
  ret i32 %z
}

define i32 @protected_is_constant_fp() noinline optnone {
entry:
  call void @hikari_vmp()
  %h = call i1 @llvm.is.constant.f16(half 0xH3C00)
  %f = call i1 @llvm.is.constant.f32(float 1.000000e+00)
  %d = call i1 @llvm.is.constant.f64(double 2.000000e+00)
  %hz = zext i1 %h to i32
  %fz = zext i1 %f to i32
  %dz = zext i1 %d to i32
  %s0 = add i32 %hz, %fz
  %s1 = add i32 %s0, %dz
  ret i32 %s1
}

define i32 @protected_is_constant_constexpr() noinline optnone {
entry:
  call void @hikari_vmp()
  %c = call i1 @llvm.is.constant.i32(i32 add (i32 1, i32 2))
  %z = zext i1 %c to i32
  ret i32 %z
}

define i32 @protected_is_constant_ssa_add() noinline optnone {
entry:
  call void @hikari_vmp()
  %slot = alloca i32, align 4
  store volatile i32 1, ptr %slot, align 4
  %a = load volatile i32, ptr %slot, align 4
  %b = add i32 %a, 2
  %c = call i1 @llvm.is.constant.i32(i32 %b)
  %z = zext i1 %c to i32
  ret i32 %z
}

define i32 @protected_is_constant_tail() noinline optnone {
entry:
  call void @hikari_vmp()
  %c = tail call i1 @llvm.is.constant.i32(i32 11)
  %z = zext i1 %c to i32
  ret i32 %z
}

define i32 @protected_is_constant_select(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %c = call i1 @llvm.is.constant.i32(i32 5)
  %r = select i1 %c, i32 7, i32 %x
  ret i32 %r
}

define i32 @protected_is_constant_phi(i1 %c, i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  br i1 %c, label %left, label %right

left:
  %l = call i1 @llvm.is.constant.i32(i32 4)
  %lz = zext i1 %l to i32
  br label %done

right:
  %r = call i1 @llvm.is.constant.i32(i32 %x)
  %rz = zext i1 %r to i32
  br label %done

done:
  %p = phi i32 [ %lz, %left ], [ %rz, %right ]
  ret i32 %p
}

define i32 @protected_is_constant_loop(i32 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %i2, %loop ]
  %sum = phi i32 [ 0, %entry ], [ %sum2, %loop ]
  %k = call i1 @llvm.is.constant.i32(i32 1)
  %kz = zext i1 %k to i32
  %sum2 = add i32 %sum, %kz
  %i2 = add i32 %i, 1
  %more = icmp slt i32 %i2, %n
  br i1 %more, label %loop, label %done

done:
  ret i32 %sum2
}

define i32 @protected_is_constant_ptr_arg(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %c = call i1 @llvm.is.constant.p0(ptr %p)
  %z = zext i1 %c to i32
  ret i32 %z
}

define i32 @protected_is_constant_i128() noinline optnone {
entry:
  call void @hikari_vmp()
  %c = call i1 @llvm.is.constant.i128(i128 1)
  %z = zext i1 %c to i32
  ret i32 %z
}

define i32 @protected_is_constant_i128_runtime(i128 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %c = call i1 @llvm.is.constant.i128(i128 %x)
  %z = zext i1 %c to i32
  ret i32 %z
}

define i32 @protected_is_constant_i128_cexpr() noinline optnone {
entry:
  call void @hikari_vmp()
  %c = call i1 @llvm.is.constant.i128(i128 add (i128 1, i128 2))
  %z = zext i1 %c to i32
  ret i32 %z
}

define i32 @protected_is_constant_vec() noinline optnone {
entry:
  call void @hikari_vmp()
  %c = call i1 @llvm.is.constant.v2i32(<2 x i32> <i32 1, i32 2>)
  %z = zext i1 %c to i32
  ret i32 %z
}

define i32 @protected_is_constant_vec_runtime(<2 x i32> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %c = call i1 @llvm.is.constant.v2i32(<2 x i32> %v)
  %z = zext i1 %c to i32
  ret i32 %z
}

define i32 @protected_is_constant_vec_v4() noinline optnone {
entry:
  call void @hikari_vmp()
  %c = call i1 @llvm.is.constant.v4i32(<4 x i32> <i32 1, i32 2, i32 3, i32 4>)
  %z = zext i1 %c to i32
  ret i32 %z
}

define i32 @protected_is_constant_vec_f32() noinline optnone {
entry:
  call void @hikari_vmp()
  %c = call i1 @llvm.is.constant.v2f32(<2 x float> <float 1.000000e+00, float 2.000000e+00>)
  %z = zext i1 %c to i32
  ret i32 %z
}

define i32 @unsupported_is_constant_poison() noinline optnone {
entry:
  call void @hikari_vmp()
  %c = call i1 @llvm.is.constant.i32(i32 poison)
  %z = zext i1 %c to i32
  ret i32 %z
}

define i32 @unsupported_is_constant_undef() noinline optnone {
entry:
  call void @hikari_vmp()
  %c = call i1 @llvm.is.constant.i32(i32 undef)
  %z = zext i1 %c to i32
  ret i32 %z
}

define i32 @unsupported_is_constant_musttail(ptr %p, i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %c = call i1 @llvm.is.constant.i32(i32 5)
  %z = zext i1 %c to i32
  %v = musttail call i32 @sink_i32(ptr %p, i32 %z)
  ret i32 %v
}

define i32 @unsupported_is_constant_bundle(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %c = call i1 @llvm.is.constant.i32(i32 %x) [ "deopt"() ]
  %z = zext i1 %c to i32
  ret i32 %z
}

define i32 @unsupported_is_constant_i2(i2 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %c = call i1 @llvm.is.constant.i2(i2 %x)
  %z = zext i1 %c to i32
  ret i32 %z
}

define i32 @unsupported_is_constant_as1(ptr addrspace(1) %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %c = call i1 @llvm.is.constant.p1(ptr addrspace(1) %p)
  %z = zext i1 %c to i32
  ret i32 %z
}

define i32 @unsupported_is_constant_wide(<8 x i32> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %c = call i1 @llvm.is.constant.v8i32(<8 x i32> %v)
  %z = zext i1 %c to i32
  ret i32 %z
}

define i32 @main() {
entry:
  %a0 = call i32 @protected_is_constant_i32()
  %a1 = call i32 @protected_is_constant_runtime(i32 5)
  %a2 = call i32 @protected_is_constant_widths()
  %a3 = call i32 @protected_is_constant_ptr_null()
  %a4 = call i32 @protected_is_constant_global()
  %a5 = call i32 @protected_is_constant_inttoptr()
  %a6 = call i32 @protected_is_constant_gep_global()
  %a7 = call i32 @protected_is_constant_fp()
  %a8 = call i32 @protected_is_constant_constexpr()
  %a9 = call i32 @protected_is_constant_ssa_add()
  %a10 = call i32 @protected_is_constant_tail()
  %a11 = call i32 @protected_is_constant_select(i32 99)
  %a12 = call i32 @protected_is_constant_phi(i1 true, i32 99)
  %a13 = call i32 @protected_is_constant_phi(i1 false, i32 99)
  %a14 = call i32 @protected_is_constant_loop(i32 3)
  %a15 = call i32 @protected_is_constant_ptr_arg(ptr @g_i32)
  %a16 = call i32 @protected_is_constant_i128()
  %a17 = call i32 @protected_is_constant_i128_runtime(i128 9)
  %a18 = call i32 @protected_is_constant_i128_cexpr()
  %a19 = call i32 @protected_is_constant_vec()
  %vr = insertelement <2 x i32> undef, i32 3, i32 0
  %vs = insertelement <2 x i32> %vr, i32 4, i32 1
  %a20 = call i32 @protected_is_constant_vec_runtime(<2 x i32> %vs)
  %a21 = call i32 @protected_is_constant_vec_v4()
  %a22 = call i32 @protected_is_constant_vec_f32()
  %m0 = icmp eq i32 %a0, 1
  %m1 = icmp eq i32 %a1, 0
  %m2 = icmp eq i32 %a2, 4
  %m3 = icmp eq i32 %a3, 1
  %m4 = icmp eq i32 %a4, 0
  %m5 = icmp eq i32 %a5, 1
  %m6 = icmp eq i32 %a6, 0
  %m7 = icmp eq i32 %a7, 3
  %m8 = icmp eq i32 %a8, 1
  %m9 = icmp eq i32 %a9, 0
  %m10 = icmp eq i32 %a10, 1
  %m11 = icmp eq i32 %a11, 7
  %m12 = icmp eq i32 %a12, 1
  %m13 = icmp eq i32 %a13, 0
  %m14 = icmp eq i32 %a14, 3
  %m15 = icmp eq i32 %a15, 0
  %m16 = icmp eq i32 %a16, 1
  %m17 = icmp eq i32 %a17, 0
  %m18 = icmp eq i32 %a18, 1
  %m19 = icmp eq i32 %a19, 1
  %m20 = icmp eq i32 %a20, 0
  %m21 = icmp eq i32 %a21, 1
  %m22 = icmp eq i32 %a22, 1
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
  %t10 = and i1 %m20, %m21
  %ok0 = and i1 %t0, %t1
  %ok1 = and i1 %t2, %t3
  %ok2 = and i1 %t4, %t5
  %ok3 = and i1 %t6, %t7
  %ok4 = and i1 %t8, %t9
  %ok5 = and i1 %ok0, %ok1
  %ok6 = and i1 %ok2, %ok3
  %ok7 = and i1 %ok4, %t10
  %ok8 = and i1 %ok5, %ok6
  %ok = and i1 %ok8, %ok7
  %ok9 = and i1 %ok, %m22
  %code = select i1 %ok9, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_is_constant_poison: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_is_constant_undef: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_is_constant_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_is_constant_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_is_constant_i2: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_is_constant_as1: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_is_constant_wide: unsupported argument type
; SKIP-NOT: Skipping VMP on protected_is_constant_i32:
; SKIP-NOT: Skipping VMP on protected_is_constant_runtime:
; SKIP-NOT: Skipping VMP on protected_is_constant_widths:
; SKIP-NOT: Skipping VMP on protected_is_constant_ptr_null:
; SKIP-NOT: Skipping VMP on protected_is_constant_global:
; SKIP-NOT: Skipping VMP on protected_is_constant_inttoptr:
; SKIP-NOT: Skipping VMP on protected_is_constant_gep_global:
; SKIP-NOT: Skipping VMP on protected_is_constant_fp:
; SKIP-NOT: Skipping VMP on protected_is_constant_constexpr:
; SKIP-NOT: Skipping VMP on protected_is_constant_ssa_add:
; SKIP-NOT: Skipping VMP on protected_is_constant_tail:
; SKIP-NOT: Skipping VMP on protected_is_constant_select:
; SKIP-NOT: Skipping VMP on protected_is_constant_phi:
; SKIP-NOT: Skipping VMP on protected_is_constant_loop:
; SKIP-NOT: Skipping VMP on protected_is_constant_ptr_arg:
; SKIP-NOT: Skipping VMP on protected_is_constant_i128:
; SKIP-NOT: Skipping VMP on protected_is_constant_i128_runtime:
; SKIP-NOT: Skipping VMP on protected_is_constant_i128_cexpr:
; SKIP-NOT: Skipping VMP on protected_is_constant_vec:
; SKIP-NOT: Skipping VMP on protected_is_constant_vec_runtime:
; SKIP-NOT: Skipping VMP on protected_is_constant_vec_v4:
; SKIP-NOT: Skipping VMP on protected_is_constant_vec_f32:

; VIRT: define i32 @protected_is_constant_i32({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call {{.*}}@llvm.is.constant
; VIRT: define i32 @protected_is_constant_runtime({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call {{.*}}@llvm.is.constant
; VIRT: define i32 @protected_is_constant_widths({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call {{.*}}@llvm.is.constant
; VIRT: define i32 @protected_is_constant_ptr_null({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call {{.*}}@llvm.is.constant
; VIRT: define i32 @protected_is_constant_global({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call {{.*}}@llvm.is.constant
; VIRT: define i32 @protected_is_constant_inttoptr({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call {{.*}}@llvm.is.constant
; VIRT: define i32 @protected_is_constant_gep_global({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call {{.*}}@llvm.is.constant
; VIRT: define i32 @protected_is_constant_fp({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call {{.*}}@llvm.is.constant
; VIRT: define i32 @protected_is_constant_constexpr({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call {{.*}}@llvm.is.constant
; VIRT: define i32 @protected_is_constant_ssa_add({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call {{.*}}@llvm.is.constant
; VIRT: define i32 @protected_is_constant_tail({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: tail call
; VIRT-NOT: call {{.*}}@llvm.is.constant
; VIRT: define i32 @protected_is_constant_select({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call {{.*}}@llvm.is.constant
; VIRT: define i32 @protected_is_constant_phi({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call {{.*}}@llvm.is.constant
; VIRT: define i32 @protected_is_constant_loop({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call {{.*}}@llvm.is.constant
; VIRT: define i32 @protected_is_constant_ptr_arg({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call {{.*}}@llvm.is.constant
; VIRT: define i32 @protected_is_constant_i128({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call {{.*}}@llvm.is.constant
; VIRT: define i32 @protected_is_constant_i128_runtime({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call {{.*}}@llvm.is.constant
; VIRT: define i32 @protected_is_constant_i128_cexpr({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call {{.*}}@llvm.is.constant
; VIRT: define i32 @protected_is_constant_vec({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call {{.*}}@llvm.is.constant
; VIRT: define i32 @protected_is_constant_vec_runtime({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call {{.*}}@llvm.is.constant
; VIRT: define i32 @protected_is_constant_vec_v4({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call {{.*}}@llvm.is.constant
; VIRT: define i32 @protected_is_constant_vec_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call {{.*}}@llvm.is.constant
; VIRT: define i32 @unsupported_is_constant_poison({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define i32 @unsupported_is_constant_undef({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define i32 @unsupported_is_constant_musttail({{.*}} #[[UNSUP_MT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call i32 @sink_i32(
; VIRT: define i32 @unsupported_is_constant_bundle({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define i32 @unsupported_is_constant_i2({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define i32 @unsupported_is_constant_as1({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define i32 @unsupported_is_constant_wide({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"
; VIRT-NOT: attributes #[[UNSUP_MT]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
