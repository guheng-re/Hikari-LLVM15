; Restricted AArch64 NEON single-vector lane load/store via
; CallDescriptor:
;   llvm.aarch64.neon.ld1lane  : vec (vec, i64 lane, ptr AS0)
;   llvm.aarch64.neon.st1lane  : void (vec, i64 lane, ptr AS0)
; Same ISel vector set as ld2/3/4lane and st2/3/4lane: 64/128-bit
; i8/i16/i32/i64/f32/f64.  Lane is a non-negative i64 ConstantInt in
; [0, Nelt) kept on CallDescriptor ImmediateArguments.  C, non-vararg.
; Ordinary tail accepted and replayed as TCK_None; musttail, bundles,
; noreturn, returns_twice, and complex ABI stay out.  No dedicated VM opcode.  No +neon/+fullfp16
; gate.  half/bfloat, SVE, arm.neon.vld1lane/vst1lane, dynamic/OOB/
; negative lanes, non-AS0, and non-ISel widths stay out.
;
; Host x86_64 cannot select these AArch64 intrinsics.  FileCheck +
; AArch64 llc/readobj/assembly on the live main-reachable subset.
; O0/O2 x aesSeed 97/7.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.ll -o %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o0.live.ll -o - | FileCheck %s --check-prefix=ASM
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.ll -o %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.s7.ll -o %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.s7.ll -o %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare <16 x i8> @llvm.aarch64.neon.ld1lane.v16i8.p0(<16 x i8>, i64, ptr)
declare <8 x i8> @llvm.aarch64.neon.ld1lane.v8i8.p0(<8 x i8>, i64, ptr)
declare <4 x i16> @llvm.aarch64.neon.ld1lane.v4i16.p0(<4 x i16>, i64, ptr)
declare <4 x i32> @llvm.aarch64.neon.ld1lane.v4i32.p0(<4 x i32>, i64, ptr)
declare <2 x float> @llvm.aarch64.neon.ld1lane.v2f32.p0(<2 x float>, i64, ptr)
declare <2 x i64> @llvm.aarch64.neon.ld1lane.v2i64.p0(<2 x i64>, i64, ptr)
declare <2 x double> @llvm.aarch64.neon.ld1lane.v2f64.p0(<2 x double>, i64, ptr)
declare <4 x half> @llvm.aarch64.neon.ld1lane.v4f16.p0(<4 x half>, i64, ptr)
declare <4 x bfloat> @llvm.aarch64.neon.ld1lane.v4bf16.p0(<4 x bfloat>, i64, ptr)
declare <4 x i8> @llvm.aarch64.neon.ld1lane.v4i8.p0(<4 x i8>, i64, ptr)
declare <16 x i8> @llvm.aarch64.neon.ld1lane.v16i8.p1(<16 x i8>, i64, ptr addrspace(1))
declare void @llvm.aarch64.neon.st1lane.v16i8.p0(<16 x i8>, i64, ptr)
declare void @llvm.aarch64.neon.st1lane.v8i8.p0(<8 x i8>, i64, ptr)
declare void @llvm.aarch64.neon.st1lane.v4i16.p0(<4 x i16>, i64, ptr)
declare void @llvm.aarch64.neon.st1lane.v4i32.p0(<4 x i32>, i64, ptr)
declare void @llvm.aarch64.neon.st1lane.v2f32.p0(<2 x float>, i64, ptr)
declare void @llvm.aarch64.neon.st1lane.v2i64.p0(<2 x i64>, i64, ptr)
declare void @llvm.aarch64.neon.st1lane.v2f64.p0(<2 x double>, i64, ptr)
declare void @llvm.aarch64.neon.st1lane.v4f16.p0(<4 x half>, i64, ptr)
declare void @llvm.aarch64.neon.st1lane.v4bf16.p0(<4 x bfloat>, i64, ptr)
declare void @llvm.aarch64.neon.st1lane.v4i8.p0(<4 x i8>, i64, ptr)
declare void @llvm.aarch64.neon.st1lane.v16i8.p1(<16 x i8>, i64, ptr addrspace(1))
declare <16 x i8> @llvm.arm.neon.vld1lane.p0.v16i8(ptr, <16 x i8>, i32, i32)

define <16 x i8> @protected_ld1lane_v16(ptr %p, <16 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <16 x i8> @llvm.aarch64.neon.ld1lane.v16i8.p0(<16 x i8> %a, i64 3, ptr align 16 %p)
  ret <16 x i8> %r
}

define <8 x i8> @protected_ld1lane_v8(ptr %p, <8 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i8> @llvm.aarch64.neon.ld1lane.v8i8.p0(<8 x i8> %a, i64 1, ptr %p)
  ret <8 x i8> %r
}

define <4 x i16> @protected_ld1lane_v4i16(ptr %p, <4 x i16> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i16> @llvm.aarch64.neon.ld1lane.v4i16.p0(<4 x i16> %a, i64 3, ptr %p)
  ret <4 x i16> %r
}

define <4 x i32> @protected_ld1lane_v4i32(ptr %p, <4 x i32> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.ld1lane.v4i32.p0(<4 x i32> %a, i64 2, ptr %p)
  ret <4 x i32> %r
}

define <2 x float> @protected_ld1lane_v2f32(ptr %p, <2 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.aarch64.neon.ld1lane.v2f32.p0(<2 x float> %a, i64 0, ptr %p)
  ret <2 x float> %r
}

define <2 x i64> @protected_ld1lane_v2i64(ptr %p, <2 x i64> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.aarch64.neon.ld1lane.v2i64.p0(<2 x i64> %a, i64 1, ptr %p)
  ret <2 x i64> %r
}

define <2 x double> @protected_ld1lane_v2f64(ptr %p, <2 x double> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x double> @llvm.aarch64.neon.ld1lane.v2f64.p0(<2 x double> %a, i64 0, ptr %p)
  ret <2 x double> %r
}

define void @protected_st1lane_v16(ptr %p, <16 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.neon.st1lane.v16i8.p0(<16 x i8> %a, i64 3, ptr align 16 %p)
  ret void
}

define void @protected_st1lane_v8(ptr %p, <8 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.neon.st1lane.v8i8.p0(<8 x i8> %a, i64 1, ptr %p)
  ret void
}

define void @protected_st1lane_v4i16(ptr %p, <4 x i16> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.neon.st1lane.v4i16.p0(<4 x i16> %a, i64 3, ptr %p)
  ret void
}

define void @protected_st1lane_v4i32(ptr %p, <4 x i32> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.neon.st1lane.v4i32.p0(<4 x i32> %a, i64 2, ptr %p)
  ret void
}

define void @protected_st1lane_v2f32(ptr %p, <2 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.neon.st1lane.v2f32.p0(<2 x float> %a, i64 0, ptr %p)
  ret void
}

define void @protected_st1lane_v2i64(ptr %p, <2 x i64> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.neon.st1lane.v2i64.p0(<2 x i64> %a, i64 1, ptr %p)
  ret void
}

define void @protected_st1lane_v2f64(ptr %p, <2 x double> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.neon.st1lane.v2f64.p0(<2 x double> %a, i64 0, ptr %p)
  ret void
}



define <16 x i8> @unsupported_ld1lane_dyn(ptr %p, <16 x i8> %a, i64 %lane) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <16 x i8> @llvm.aarch64.neon.ld1lane.v16i8.p0(<16 x i8> %a, i64 %lane, ptr %p)
  ret <16 x i8> %r
}

define <16 x i8> @unsupported_ld1lane_oob(ptr %p, <16 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <16 x i8> @llvm.aarch64.neon.ld1lane.v16i8.p0(<16 x i8> %a, i64 16, ptr %p)
  ret <16 x i8> %r
}

define <16 x i8> @unsupported_ld1lane_neg(ptr %p, <16 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <16 x i8> @llvm.aarch64.neon.ld1lane.v16i8.p0(<16 x i8> %a, i64 -1, ptr %p)
  ret <16 x i8> %r
}

define <4 x half> @unsupported_ld1lane_half(ptr %p, <4 x half> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x half> @llvm.aarch64.neon.ld1lane.v4f16.p0(<4 x half> %a, i64 0, ptr %p)
  ret <4 x half> %r
}

define <4 x i8> @unsupported_ld1lane_v4i8(ptr %p, <4 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i8> @llvm.aarch64.neon.ld1lane.v4i8.p0(<4 x i8> %a, i64 0, ptr %p)
  ret <4 x i8> %r
}

define <4 x bfloat> @unsupported_ld1lane_bfloat(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x bfloat> @llvm.aarch64.neon.ld1lane.v4bf16.p0(<4 x bfloat> zeroinitializer, i64 0, ptr %p)
  ret <4 x bfloat> %r
}

define void @unsupported_st1lane_half(ptr %p, <4 x half> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.neon.st1lane.v4f16.p0(<4 x half> %a, i64 0, ptr %p)
  ret void
}

define void @unsupported_st1lane_v4i8(ptr %p, <4 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.neon.st1lane.v4i8.p0(<4 x i8> %a, i64 0, ptr %p)
  ret void
}

define void @unsupported_st1lane_bfloat(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.neon.st1lane.v4bf16.p0(<4 x bfloat> zeroinitializer, i64 0, ptr %p)
  ret void
}

define <16 x i8> @unsupported_arm_vld1lane(ptr %p, <16 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <16 x i8> @llvm.arm.neon.vld1lane.p0.v16i8(ptr %p, <16 x i8> %a, i32 0, i32 1)
  ret <16 x i8> %r
}

define <16 x i8> @unsupported_ld1lane_as1(ptr addrspace(1) %p, <16 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <16 x i8> @llvm.aarch64.neon.ld1lane.v16i8.p1(<16 x i8> %a, i64 0, ptr addrspace(1) %p)
  ret <16 x i8> %r
}

define void @unsupported_st1lane_as1(ptr addrspace(1) %p, <16 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.neon.st1lane.v16i8.p1(<16 x i8> %a, i64 0, ptr addrspace(1) %p)
  ret void
}

define <16 x i8> @unsupported_ld1lane_fastcc(ptr %p, <16 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc <16 x i8> @llvm.aarch64.neon.ld1lane.v16i8.p0(<16 x i8> %a, i64 0, ptr %p)
  ret <16 x i8> %r
}

define <16 x i8> @unsupported_ld1lane_musttail(ptr %p, <16 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call <16 x i8> @llvm.aarch64.neon.ld1lane.v16i8.p0(<16 x i8> %a, i64 0, ptr %p)
  ret <16 x i8> %r
}

define <16 x i8> @unsupported_ld1lane_bundle(ptr %p, <16 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <16 x i8> @llvm.aarch64.neon.ld1lane.v16i8.p0(<16 x i8> %a, i64 0, ptr %p) [ "deopt"(i32 0) ]
  ret <16 x i8> %r
}

define i32 @main() {
entry:
  %buf = alloca [32 x i8], align 16
  %p = getelementptr inbounds [32 x i8], ptr %buf, i64 0, i64 0
  %a16 = load volatile <16 x i8>, ptr %p, align 16
  %l16 = call <16 x i8> @protected_ld1lane_v16(ptr %p, <16 x i8> %a16)
  store volatile <16 x i8> %l16, ptr %p, align 16
  %a8 = load volatile <8 x i8>, ptr %p, align 8
  %l8 = call <8 x i8> @protected_ld1lane_v8(ptr %p, <8 x i8> %a8)
  store volatile <8 x i8> %l8, ptr %p, align 8
  %as = load volatile <4 x i16>, ptr %p, align 8
  %ls = call <4 x i16> @protected_ld1lane_v4i16(ptr %p, <4 x i16> %as)
  store volatile <4 x i16> %ls, ptr %p, align 8
  %ai = load volatile <4 x i32>, ptr %p, align 16
  %li = call <4 x i32> @protected_ld1lane_v4i32(ptr %p, <4 x i32> %ai)
  store volatile <4 x i32> %li, ptr %p, align 16
  %af = load volatile <2 x float>, ptr %p, align 8
  %lf = call <2 x float> @protected_ld1lane_v2f32(ptr %p, <2 x float> %af)
  store volatile <2 x float> %lf, ptr %p, align 8
  %al = load volatile <2 x i64>, ptr %p, align 16
  %ll = call <2 x i64> @protected_ld1lane_v2i64(ptr %p, <2 x i64> %al)
  store volatile <2 x i64> %ll, ptr %p, align 16
  %ad = load volatile <2 x double>, ptr %p, align 16
  %ld = call <2 x double> @protected_ld1lane_v2f64(ptr %p, <2 x double> %ad)
  store volatile <2 x double> %ld, ptr %p, align 16
  call void @protected_st1lane_v16(ptr %p, <16 x i8> %a16)
  call void @protected_st1lane_v8(ptr %p, <8 x i8> %a8)
  call void @protected_st1lane_v4i16(ptr %p, <4 x i16> %as)
  call void @protected_st1lane_v4i32(ptr %p, <4 x i32> %ai)
  call void @protected_st1lane_v2f32(ptr %p, <2 x float> %af)
  call void @protected_st1lane_v2i64(ptr %p, <2 x i64> %al)
  call void @protected_st1lane_v2f64(ptr %p, <2 x double> %ad)
  ret i32 0
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_ld1lane_dyn: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_ld1lane_oob: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_ld1lane_neg: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_ld1lane_half: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_ld1lane_v4i8: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_ld1lane_bfloat: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_st1lane_half: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_st1lane_v4i8: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_st1lane_bfloat: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_arm_vld1lane: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_ld1lane_as1: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_st1lane_as1: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_ld1lane_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_ld1lane_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_ld1lane_bundle: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_ld1lane_v16:
; SKIP-NOT: Skipping VMP on protected_ld1lane_v8:
; SKIP-NOT: Skipping VMP on protected_ld1lane_v4i16:
; SKIP-NOT: Skipping VMP on protected_ld1lane_v4i32:
; SKIP-NOT: Skipping VMP on protected_ld1lane_v2f32:
; SKIP-NOT: Skipping VMP on protected_ld1lane_v2i64:
; SKIP-NOT: Skipping VMP on protected_ld1lane_v2f64:
; SKIP-NOT: Skipping VMP on protected_st1lane_v16:
; SKIP-NOT: Skipping VMP on protected_st1lane_v8:
; SKIP-NOT: Skipping VMP on protected_st1lane_v4i16:
; SKIP-NOT: Skipping VMP on protected_st1lane_v4i32:
; SKIP-NOT: Skipping VMP on protected_st1lane_v2f32:
; SKIP-NOT: Skipping VMP on protected_st1lane_v2i64:
; SKIP-NOT: Skipping VMP on protected_st1lane_v2f64:

; VIRT: define <16 x i8> @protected_ld1lane_v16({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <16 x i8> @llvm.aarch64.neon.ld1lane.v16i8.p0({{.*}}i64 3, ptr align 16
; VIRT: define <8 x i8> @protected_ld1lane_v8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x i8> @llvm.aarch64.neon.ld1lane.v8i8.p0({{.*}}i64 1,
; VIRT: define <4 x i16> @protected_ld1lane_v4i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i16> @llvm.aarch64.neon.ld1lane.v4i16.p0({{.*}}i64 3,
; VIRT: define <4 x i32> @protected_ld1lane_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.aarch64.neon.ld1lane.v4i32.p0({{.*}}i64 2,
; VIRT: define <2 x float> @protected_ld1lane_v2f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x float> @llvm.aarch64.neon.ld1lane.v2f32.p0({{.*}}i64 0,
; VIRT: define <2 x i64> @protected_ld1lane_v2i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i64> @llvm.aarch64.neon.ld1lane.v2i64.p0({{.*}}i64 1,
; VIRT: define <2 x double> @protected_ld1lane_v2f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x double> @llvm.aarch64.neon.ld1lane.v2f64.p0({{.*}}i64 0,
; VIRT: define void @protected_st1lane_v16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.aarch64.neon.st1lane.v16i8.p0({{.*}}i64 3, ptr align 16
; VIRT: define void @protected_st1lane_v8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.aarch64.neon.st1lane.v8i8.p0({{.*}}i64 1,
; VIRT: define void @protected_st1lane_v4i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.aarch64.neon.st1lane.v4i16.p0({{.*}}i64 3,
; VIRT: define void @protected_st1lane_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.aarch64.neon.st1lane.v4i32.p0({{.*}}i64 2,
; VIRT: define void @protected_st1lane_v2f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.aarch64.neon.st1lane.v2f32.p0({{.*}}i64 0,
; VIRT: define void @protected_st1lane_v2i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.aarch64.neon.st1lane.v2i64.p0({{.*}}i64 1,
; VIRT: define void @protected_st1lane_v2f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.aarch64.neon.st1lane.v2f64.p0({{.*}}i64 0,
; VIRT: define {{.*}} @unsupported_ld1lane_dyn({{.*}} #[[UNSUPATTR:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ld1lane_oob({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ld1lane_neg({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ld1lane_half({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ld1lane_v4i8({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ld1lane_bfloat({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_st1lane_half({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_st1lane_v4i8({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_st1lane_bfloat({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_arm_vld1lane({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ld1lane_as1({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_st1lane_as1({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ld1lane_fastcc({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ld1lane_musttail({{.*}} #[[UNSUP_MT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call <16 x i8> @llvm.aarch64.neon.ld1lane.v16i8.p0(
; VIRT: define {{.*}} @unsupported_ld1lane_bundle({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call <16 x i8> @llvm.aarch64.neon.ld1lane.v16i8.p0({{.*}}[ "deopt"(i32 0) ]
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_MT]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; Instruction forms, not the protected_ld1lane_* symbol names.
; ASM-DAG: ld1{{.*}}{ v0.b }[3]
; ASM-DAG: ld1{{.*}}{ v0.b }[1]
; ASM-DAG: ld1{{.*}}{ v0.h }[3]
; ASM-DAG: ld1{{.*}}{ v0.s }[2]
; ASM-DAG: ld1{{.*}}{ v0.s }[0]
; ASM-DAG: ld1{{.*}}{ v0.d }[1]
; ASM-DAG: ld1{{.*}}{ v0.d }[0]
; ASM-DAG: st1{{.*}}{ v0.b }[3]
; ASM-DAG: st1{{.*}}{ v0.b }[1]
; ASM-DAG: st1{{.*}}{ v0.h }[3]
; ASM-DAG: st1{{.*}}{ v0.s }[2]
; ASM-DAG: st1{{.*}}{ v0.s }[0]
; ASM-DAG: st1{{.*}}{ v0.d }[1]
; ASM-DAG: st1{{.*}}{ v0.d }[0]
