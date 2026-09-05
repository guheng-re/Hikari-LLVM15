; Restricted AArch64 NEON multi-vector lane stores via CallDescriptor:
;   st2lane / st3lane / st4lane
; Exact IntrinsicsAArch64.td AdvSIMD_NVec_Store_Lane_Intrinsic:
;   void (vec x N, i64 lane, anyptr)
; Vector types are the practical AArch64 ISel overloads for integer
; i8/i16/i32/i64 and f32/f64 only (64/128-bit).  half stays out.
; Lane is i64 ConstantInt in [0, Nelt).  Pointer is AS0.
; Call site must be CallingConv::C and non-vararg.
; Re-emitted via CallDescriptor (vector VRegs + immediate lane +
; pointer VReg).  No dedicated VM opcode.  No extra +neon / +fullfp16
; gate.  st1lane lives in vmp-aarch64-neon-ldst1lane-semantic.ll.
; SVE, arm.neon.vst*lane, dynamic/OOB/negative lanes,
; half, bfloat, non-AS0, fastcc, musttail, and operand bundles stay out.
;
; Host x86_64 cannot select these AArch64 intrinsics.  Do not rewrite
; them for host and do not run lli.  Validate with FileCheck + AArch64
; object generation on the live main-reachable subset.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.ll -o %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.ll -o %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.s7.ll -o %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.s7.ll -o %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare void @llvm.aarch64.neon.st2lane.v16i8.p0(<16 x i8>, <16 x i8>, i64, ptr)
declare void @llvm.aarch64.neon.st2lane.v8i8.p0(<8 x i8>, <8 x i8>, i64, ptr)
declare void @llvm.aarch64.neon.st2lane.v4i16.p0(<4 x i16>, <4 x i16>, i64, ptr)
declare void @llvm.aarch64.neon.st3lane.v4i32.p0(<4 x i32>, <4 x i32>, <4 x i32>, i64, ptr)
declare void @llvm.aarch64.neon.st3lane.v2f32.p0(<2 x float>, <2 x float>, <2 x float>, i64, ptr)
declare void @llvm.aarch64.neon.st4lane.v2i64.p0(<2 x i64>, <2 x i64>, <2 x i64>, <2 x i64>, i64, ptr)
declare void @llvm.aarch64.neon.st2lane.v4f16.p0(<4 x half>, <4 x half>, i64, ptr)
declare void @llvm.aarch64.neon.st2lane.v4bf16.p0(<4 x bfloat>, <4 x bfloat>, i64, ptr)
declare void @llvm.aarch64.neon.st2lane.v4i8.p0(<4 x i8>, <4 x i8>, i64, ptr)
declare void @llvm.arm.neon.vst2lane.p0.v16i8(ptr, <16 x i8>, <16 x i8>, i32, i32)

@sink = global [128 x i8] zeroinitializer, align 16

define void @protected_st2lane_v16(ptr %p, <16 x i8> %a, <16 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.neon.st2lane.v16i8.p0(<16 x i8> %a, <16 x i8> %b, i64 3, ptr %p)
  ret void
}

define void @protected_st2lane_v8(ptr %p, <8 x i8> %a, <8 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.neon.st2lane.v8i8.p0(<8 x i8> %a, <8 x i8> %b, i64 1, ptr %p)
  ret void
}

define void @protected_st2lane_v4i16(ptr %p, <4 x i16> %a, <4 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.neon.st2lane.v4i16.p0(<4 x i16> %a, <4 x i16> %b, i64 3, ptr %p)
  ret void
}

define void @protected_st3lane_v4i32(ptr %p, <4 x i32> %a, <4 x i32> %b, <4 x i32> %c) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.neon.st3lane.v4i32.p0(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c, i64 2, ptr %p)
  ret void
}

define void @protected_st3lane_v2f32(ptr %p, <2 x float> %a, <2 x float> %b, <2 x float> %c) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.neon.st3lane.v2f32.p0(<2 x float> %a, <2 x float> %b, <2 x float> %c, i64 0, ptr %p)
  ret void
}

define void @protected_st4lane_v2i64(ptr %p, <2 x i64> %a, <2 x i64> %b, <2 x i64> %c, <2 x i64> %d) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.neon.st4lane.v2i64.p0(<2 x i64> %a, <2 x i64> %b, <2 x i64> %c, <2 x i64> %d, i64 1, ptr %p)
  ret void
}

; ----- negatives: selected, not virtualized -----

define void @unsupported_stlane_dyn(ptr %p, <16 x i8> %a, <16 x i8> %b, i64 %lane) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.neon.st2lane.v16i8.p0(<16 x i8> %a, <16 x i8> %b, i64 %lane, ptr %p)
  ret void
}

define void @unsupported_stlane_oob(ptr %p, <16 x i8> %a, <16 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.neon.st2lane.v16i8.p0(<16 x i8> %a, <16 x i8> %b, i64 16, ptr %p)
  ret void
}

define void @unsupported_stlane_neg(ptr %p, <16 x i8> %a, <16 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.neon.st2lane.v16i8.p0(<16 x i8> %a, <16 x i8> %b, i64 -1, ptr %p)
  ret void
}

define void @unsupported_stlane_half(ptr %p, <4 x half> %a, <4 x half> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.neon.st2lane.v4f16.p0(<4 x half> %a, <4 x half> %b, i64 0, ptr %p)
  ret void
}

define void @unsupported_stlane_v4i8(ptr %p, <4 x i8> %a, <4 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.neon.st2lane.v4i8.p0(<4 x i8> %a, <4 x i8> %b, i64 0, ptr %p)
  ret void
}

define void @unsupported_stlane_bfloat(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.neon.st2lane.v4bf16.p0(<4 x bfloat> zeroinitializer, <4 x bfloat> zeroinitializer, i64 0, ptr %p)
  ret void
}

define void @unsupported_arm_vst2lane(ptr %p, <16 x i8> %a, <16 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.arm.neon.vst2lane.p0.v16i8(ptr %p, <16 x i8> %a, <16 x i8> %b, i32 0, i32 1)
  ret void
}

define void @unsupported_stlane_as1(ptr addrspace(1) %p, <16 x i8> %a, <16 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.neon.st2lane.v16i8.p1(<16 x i8> %a, <16 x i8> %b, i64 0, ptr addrspace(1) %p)
  ret void
}

declare void @llvm.aarch64.neon.st2lane.v16i8.p1(<16 x i8>, <16 x i8>, i64, ptr addrspace(1))

define void @unsupported_stlane_fastcc(ptr %p, <16 x i8> %a, <16 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  call fastcc void @llvm.aarch64.neon.st2lane.v16i8.p0(<16 x i8> %a, <16 x i8> %b, i64 0, ptr %p)
  ret void
}

define void @unsupported_stlane_musttail(<16 x i8> %a, <16 x i8> %b, ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  musttail call void @llvm.aarch64.neon.st2lane.v16i8.p0(<16 x i8> %a, <16 x i8> %b, i64 0, ptr %p)
  ret void
}

define void @unsupported_stlane_bundle(ptr %p, <16 x i8> %a, <16 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.neon.st2lane.v16i8.p0(<16 x i8> %a, <16 x i8> %b, i64 0, ptr %p) [ "deopt"(i32 0) ]
  ret void
}

define i32 @main() {
entry:
  %p = getelementptr inbounds [128 x i8], ptr @sink, i64 0, i64 0
  %a16 = load volatile <16 x i8>, ptr %p, align 16
  call void @protected_st2lane_v16(ptr %p, <16 x i8> %a16, <16 x i8> %a16)
  %a8 = load volatile <8 x i8>, ptr %p, align 8
  call void @protected_st2lane_v8(ptr %p, <8 x i8> %a8, <8 x i8> %a8)
  %as = load volatile <4 x i16>, ptr %p, align 8
  call void @protected_st2lane_v4i16(ptr %p, <4 x i16> %as, <4 x i16> %as)
  %ai = load volatile <4 x i32>, ptr %p, align 16
  call void @protected_st3lane_v4i32(ptr %p, <4 x i32> %ai, <4 x i32> %ai, <4 x i32> %ai)
  %af = load volatile <2 x float>, ptr %p, align 8
  call void @protected_st3lane_v2f32(ptr %p, <2 x float> %af, <2 x float> %af, <2 x float> %af)
  %al = load volatile <2 x i64>, ptr %p, align 16
  call void @protected_st4lane_v2i64(ptr %p, <2 x i64> %al, <2 x i64> %al, <2 x i64> %al, <2 x i64> %al)
  ret i32 0
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_stlane_dyn: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_stlane_oob: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_stlane_neg: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_stlane_half: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_stlane_v4i8: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_stlane_bfloat: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_arm_vst2lane: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_stlane_as1: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_stlane_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_stlane_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_stlane_bundle: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_st2lane_v16:
; SKIP-NOT: Skipping VMP on protected_st2lane_v8:
; SKIP-NOT: Skipping VMP on protected_st2lane_v4i16:
; SKIP-NOT: Skipping VMP on protected_st3lane_v4i32:
; SKIP-NOT: Skipping VMP on protected_st3lane_v2f32:
; SKIP-NOT: Skipping VMP on protected_st4lane_v2i64:

; VIRT: define void @protected_st2lane_v16({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.aarch64.neon.st2lane.v16i8.p0({{.*}}i64 3,
; VIRT: define void @protected_st2lane_v8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.aarch64.neon.st2lane.v8i8.p0({{.*}}i64 1,
; VIRT: define void @protected_st2lane_v4i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.aarch64.neon.st2lane.v4i16.p0({{.*}}i64 3,
; VIRT: define void @protected_st3lane_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.aarch64.neon.st3lane.v4i32.p0({{.*}}i64 2,
; VIRT: define void @protected_st3lane_v2f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.aarch64.neon.st3lane.v2f32.p0({{.*}}i64 0,
; VIRT: define void @protected_st4lane_v2i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.aarch64.neon.st4lane.v2i64.p0({{.*}}i64 1,
; VIRT: define {{.*}} @unsupported_stlane_dyn({{.*}} #[[UNSUPATTR:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_stlane_oob({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_stlane_neg({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_stlane_half({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_stlane_v4i8({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_stlane_bfloat({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_arm_vst2lane({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_stlane_as1({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_stlane_fastcc({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_stlane_musttail({{.*}} #[[UNSUP_MT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call void @llvm.aarch64.neon.st2lane.v16i8.p0(
; VIRT: define {{.*}} @unsupported_stlane_bundle({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call void @llvm.aarch64.neon.st2lane.v16i8.p0({{.*}}[ "deopt"(i32 0) ]
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_MT]] = { {{.*}}"hikari.vmp.virtualized"
