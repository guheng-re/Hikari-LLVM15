; Restricted AArch64 NEON multi-vector stores via CallDescriptor:
;   st1x2/st1x3/st1x4 and st2/st3/st4
; Exact IntrinsicsAArch64.td AdvSIMD_NVec_Store_Intrinsic:
;   void (anyvector x N, anyptr-to-match)
; Vector types are the practical AArch64 ISel overloads for integer
; i8/i16/i32/i64 and f32/f64 only (64/128-bit).  half stays out.
; Pointer is AS0.  Call site must be CallingConv::C and non-vararg.
; No dedicated VM opcode.  No extra +neon / +fullfp16 gate.  Well-formed
; st2/3/4lane lives in vmp-aarch64-neon-stlane-semantic.ll; the st2lane
; case here is a dynamic-lane negative only.  SVE, arm.neon.vst*,
; non-AS0, fastcc, musttail, and operand bundles stay out.
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
declare void @llvm.aarch64.neon.st1x2.v16i8.p0(<16 x i8>, <16 x i8>, ptr)
declare void @llvm.aarch64.neon.st1x2.v8i8.p0(<8 x i8>, <8 x i8>, ptr)
declare void @llvm.aarch64.neon.st1x3.v4i32.p0(<4 x i32>, <4 x i32>, <4 x i32>, ptr)
declare void @llvm.aarch64.neon.st1x4.v8i16.p0(<8 x i16>, <8 x i16>, <8 x i16>, <8 x i16>, ptr)
declare void @llvm.aarch64.neon.st1x4.v4f16.p0(<4 x half>, <4 x half>, <4 x half>, <4 x half>, ptr)
declare void @llvm.aarch64.neon.st2.v16i8.p0(<16 x i8>, <16 x i8>, ptr)
declare void @llvm.aarch64.neon.st3.v2f32.p0(<2 x float>, <2 x float>, <2 x float>, ptr)
declare void @llvm.aarch64.neon.st4.v2i64.p0(<2 x i64>, <2 x i64>, <2 x i64>, <2 x i64>, ptr)
declare void @llvm.aarch64.neon.st2lane.v16i8.p0(<16 x i8>, <16 x i8>, i64, ptr)
declare void @llvm.aarch64.neon.st1x2.v4i8.p0(<4 x i8>, <4 x i8>, ptr)
declare void @llvm.arm.neon.vst1x2.p0.v16i8(ptr, <16 x i8>, <16 x i8>)

@sink = global [128 x i8] zeroinitializer, align 16

define void @protected_st1x2_v16(ptr %p, <16 x i8> %a, <16 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.neon.st1x2.v16i8.p0(<16 x i8> %a, <16 x i8> %b, ptr %p)
  ret void
}

define void @protected_st1x2_v8(ptr %p, <8 x i8> %a, <8 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.neon.st1x2.v8i8.p0(<8 x i8> %a, <8 x i8> %b, ptr %p)
  ret void
}

define void @protected_st1x3_v4i32(ptr %p, <4 x i32> %a, <4 x i32> %b, <4 x i32> %c) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.neon.st1x3.v4i32.p0(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c, ptr %p)
  ret void
}

define void @protected_st1x4_v8i16(ptr %p, <8 x i16> %a, <8 x i16> %b, <8 x i16> %c, <8 x i16> %d) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.neon.st1x4.v8i16.p0(<8 x i16> %a, <8 x i16> %b, <8 x i16> %c, <8 x i16> %d, ptr %p)
  ret void
}

define void @protected_st2_v16(ptr %p, <16 x i8> %a, <16 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.neon.st2.v16i8.p0(<16 x i8> %a, <16 x i8> %b, ptr %p)
  ret void
}

define void @protected_st3_v2f32(ptr %p, <2 x float> %a, <2 x float> %b, <2 x float> %c) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.neon.st3.v2f32.p0(<2 x float> %a, <2 x float> %b, <2 x float> %c, ptr %p)
  ret void
}

define void @protected_st4_v2i64(ptr %p, <2 x i64> %a, <2 x i64> %b, <2 x i64> %c, <2 x i64> %d) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.neon.st4.v2i64.p0(<2 x i64> %a, <2 x i64> %b, <2 x i64> %c, <2 x i64> %d, ptr %p)
  ret void
}

; ----- negatives: selected, not virtualized -----

; Dynamic lane.  Well-formed st2/3/4lane is in
; vmp-aarch64-neon-stlane-semantic.ll.
define void @unsupported_st2lane(ptr %p, <16 x i8> %a, <16 x i8> %b, i64 %lane) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.neon.st2lane.v16i8.p0(<16 x i8> %a, <16 x i8> %b, i64 %lane, ptr %p)
  ret void
}

define void @unsupported_st_half(ptr %p, <4 x half> %a, <4 x half> %b, <4 x half> %c, <4 x half> %d) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.neon.st1x4.v4f16.p0(<4 x half> %a, <4 x half> %b, <4 x half> %c, <4 x half> %d, ptr %p)
  ret void
}

define void @unsupported_st_v4i8(ptr %p, <4 x i8> %a, <4 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.neon.st1x2.v4i8.p0(<4 x i8> %a, <4 x i8> %b, ptr %p)
  ret void
}

define void @unsupported_st_as1(ptr addrspace(1) %p, <16 x i8> %a, <16 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.neon.st1x2.v16i8.p1(<16 x i8> %a, <16 x i8> %b, ptr addrspace(1) %p)
  ret void
}

declare void @llvm.aarch64.neon.st1x2.v16i8.p1(<16 x i8>, <16 x i8>, ptr addrspace(1))

define void @unsupported_st_fastcc(ptr %p, <16 x i8> %a, <16 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  call fastcc void @llvm.aarch64.neon.st1x2.v16i8.p0(<16 x i8> %a, <16 x i8> %b, ptr %p)
  ret void
}

define void @unsupported_st_musttail(<16 x i8> %a, <16 x i8> %b, ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  musttail call void @llvm.aarch64.neon.st1x2.v16i8.p0(<16 x i8> %a, <16 x i8> %b, ptr %p)
  ret void
}

define void @unsupported_st_bundle(ptr %p, <16 x i8> %a, <16 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.neon.st1x2.v16i8.p0(<16 x i8> %a, <16 x i8> %b, ptr %p) [ "deopt"(i32 0) ]
  ret void
}

define void @unsupported_arm_vst1x2(ptr %p, <16 x i8> %a, <16 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.arm.neon.vst1x2.p0.v16i8(ptr %p, <16 x i8> %a, <16 x i8> %b)
  ret void
}

define i32 @main() {
entry:
  %p = getelementptr inbounds [128 x i8], ptr @sink, i64 0, i64 0
  %a16 = load volatile <16 x i8>, ptr %p, align 16
  %b16 = load volatile <16 x i8>, ptr %p, align 16
  call void @protected_st1x2_v16(ptr %p, <16 x i8> %a16, <16 x i8> %b16)
  %a8 = load volatile <8 x i8>, ptr %p, align 8
  %b8 = load volatile <8 x i8>, ptr %p, align 8
  call void @protected_st1x2_v8(ptr %p, <8 x i8> %a8, <8 x i8> %b8)
  %ai = load volatile <4 x i32>, ptr %p, align 16
  call void @protected_st1x3_v4i32(ptr %p, <4 x i32> %ai, <4 x i32> %ai, <4 x i32> %ai)
  %as = load volatile <8 x i16>, ptr %p, align 16
  call void @protected_st1x4_v8i16(ptr %p, <8 x i16> %as, <8 x i16> %as, <8 x i16> %as, <8 x i16> %as)
  call void @protected_st2_v16(ptr %p, <16 x i8> %a16, <16 x i8> %b16)
  %af = load volatile <2 x float>, ptr %p, align 8
  call void @protected_st3_v2f32(ptr %p, <2 x float> %af, <2 x float> %af, <2 x float> %af)
  %al = load volatile <2 x i64>, ptr %p, align 16
  call void @protected_st4_v2i64(ptr %p, <2 x i64> %al, <2 x i64> %al, <2 x i64> %al, <2 x i64> %al)
  ret i32 0
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_st2lane: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_st_half: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_st_v4i8: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_st_as1: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_st_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_st_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_st_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_arm_vst1x2: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_st1x2_v16:
; SKIP-NOT: Skipping VMP on protected_st1x2_v8:
; SKIP-NOT: Skipping VMP on protected_st1x3_v4i32:
; SKIP-NOT: Skipping VMP on protected_st1x4_v8i16:
; SKIP-NOT: Skipping VMP on protected_st2_v16:
; SKIP-NOT: Skipping VMP on protected_st3_v2f32:
; SKIP-NOT: Skipping VMP on protected_st4_v2i64:

; VIRT: define void @protected_st1x2_v16({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.aarch64.neon.st1x2.v16i8.p0(
; VIRT: define void @protected_st1x2_v8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.aarch64.neon.st1x2.v8i8.p0(
; VIRT: define void @protected_st1x3_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.aarch64.neon.st1x3.v4i32.p0(
; VIRT: define void @protected_st1x4_v8i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.aarch64.neon.st1x4.v8i16.p0(
; VIRT: define void @protected_st2_v16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.aarch64.neon.st2.v16i8.p0(
; VIRT: define void @protected_st3_v2f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.aarch64.neon.st3.v2f32.p0(
; VIRT: define void @protected_st4_v2i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.aarch64.neon.st4.v2i64.p0(
; VIRT: define {{.*}} @unsupported_st2lane({{.*}} #[[UNSUPATTR:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_st_half({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_st_v4i8({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_st_as1({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_st_fastcc({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_st_musttail({{.*}} #[[UNSUP_MT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call void @llvm.aarch64.neon.st1x2.v16i8.p0(
; VIRT: define {{.*}} @unsupported_st_bundle({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call void @llvm.aarch64.neon.st1x2.v16i8.p0({{.*}}[ "deopt"(i32 0) ]
; VIRT: define {{.*}} @unsupported_arm_vst1x2({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_MT]] = { {{.*}}"hikari.vmp.virtualized"
