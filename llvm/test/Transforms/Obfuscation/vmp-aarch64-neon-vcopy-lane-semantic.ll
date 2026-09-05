; Restricted AArch64 NEON vcopy.lane via CallDescriptor.
; Exact AdvSIMD_2Vector2Index_Intrinsic:
;   anyvector (anyvector, i64, match<0>, i64)
; This surface requires dest == src == result and a 128-bit integer
; ISel type: <16 x i8>, <8 x i16>, <4 x i32>, <2 x i64>.  Lane indices
; are i64 ConstantInt in [0, N) and stay CallDescriptor immediates
; (not ImmArg in the TD).  Call site must be CallingConv::C and
; non-vararg.  No dedicated VM opcode.  No extra +neon gate.
; 64-bit, half, f32/f64, mismatched widths, dynamic/OOR lanes, fastcc,
; musttail, and operand bundles stay out.
;
; Host x86_64 cannot select this AArch64 intrinsic.  Do not rewrite it
; for host and do not run lli.  Validate with FileCheck + AArch64
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
declare <16 x i8> @llvm.aarch64.neon.vcopy.lane.v16i8.v16i8(<16 x i8>, i64, <16 x i8>, i64)
declare <8 x i16> @llvm.aarch64.neon.vcopy.lane.v8i16.v8i16(<8 x i16>, i64, <8 x i16>, i64)
declare <4 x i32> @llvm.aarch64.neon.vcopy.lane.v4i32.v4i32(<4 x i32>, i64, <4 x i32>, i64)
declare <2 x i64> @llvm.aarch64.neon.vcopy.lane.v2i64.v2i64(<2 x i64>, i64, <2 x i64>, i64)
declare <8 x i8> @llvm.aarch64.neon.vcopy.lane.v8i8.v8i8(<8 x i8>, i64, <8 x i8>, i64)
declare <8 x i8> @llvm.aarch64.neon.vcopy.lane.v8i8.v16i8(<16 x i8>, i64, <8 x i8>, i64)
declare <4 x half> @llvm.aarch64.neon.vcopy.lane.v4f16.v4f16(<4 x half>, i64, <4 x half>, i64)
declare <4 x float> @llvm.aarch64.neon.vcopy.lane.v4f32.v4f32(<4 x float>, i64, <4 x float>, i64)

@sink16 = global <16 x i8> zeroinitializer, align 16

define <16 x i8> @protected_vcopy_v16i8(<16 x i8> %d, <16 x i8> %s) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <16 x i8> @llvm.aarch64.neon.vcopy.lane.v16i8.v16i8(<16 x i8> %d, i64 0, <16 x i8> %s, i64 1)
  ret <16 x i8> %r
}

define <8 x i16> @protected_vcopy_v8i16(<8 x i16> %d, <8 x i16> %s) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i16> @llvm.aarch64.neon.vcopy.lane.v8i16.v8i16(<8 x i16> %d, i64 3, <8 x i16> %s, i64 7)
  ret <8 x i16> %r
}

define <4 x i32> @protected_vcopy_v4i32(<4 x i32> %d, <4 x i32> %s) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.vcopy.lane.v4i32.v4i32(<4 x i32> %d, i64 1, <4 x i32> %s, i64 2)
  ret <4 x i32> %r
}

define <2 x i64> @protected_vcopy_v2i64(<2 x i64> %d, <2 x i64> %s) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.aarch64.neon.vcopy.lane.v2i64.v2i64(<2 x i64> %d, i64 0, <2 x i64> %s, i64 1)
  ret <2 x i64> %r
}

; ----- negatives: selected, not virtualized -----

define <8 x i8> @unsupported_vcopy_v8i8(<8 x i8> %d, <8 x i8> %s) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i8> @llvm.aarch64.neon.vcopy.lane.v8i8.v8i8(<8 x i8> %d, i64 0, <8 x i8> %s, i64 1)
  ret <8 x i8> %r
}

define <8 x i8> @unsupported_vcopy_mismatch(<16 x i8> %d, <8 x i8> %s) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i8> @llvm.aarch64.neon.vcopy.lane.v8i8.v16i8(<16 x i8> %d, i64 0, <8 x i8> %s, i64 1)
  ret <8 x i8> %r
}

define <4 x half> @unsupported_vcopy_half(<4 x half> %d, <4 x half> %s) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x half> @llvm.aarch64.neon.vcopy.lane.v4f16.v4f16(<4 x half> %d, i64 0, <4 x half> %s, i64 1)
  ret <4 x half> %r
}

define <4 x float> @unsupported_vcopy_f32(<4 x float> %d, <4 x float> %s) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.vcopy.lane.v4f32.v4f32(<4 x float> %d, i64 0, <4 x float> %s, i64 1)
  ret <4 x float> %r
}

define <16 x i8> @unsupported_vcopy_dyn(<16 x i8> %d, <16 x i8> %s, i64 %i) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <16 x i8> @llvm.aarch64.neon.vcopy.lane.v16i8.v16i8(<16 x i8> %d, i64 %i, <16 x i8> %s, i64 1)
  ret <16 x i8> %r
}

define <16 x i8> @unsupported_vcopy_oor(<16 x i8> %d, <16 x i8> %s) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <16 x i8> @llvm.aarch64.neon.vcopy.lane.v16i8.v16i8(<16 x i8> %d, i64 16, <16 x i8> %s, i64 0)
  ret <16 x i8> %r
}

define <16 x i8> @unsupported_vcopy_fastcc(<16 x i8> %d, <16 x i8> %s) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc <16 x i8> @llvm.aarch64.neon.vcopy.lane.v16i8.v16i8(<16 x i8> %d, i64 0, <16 x i8> %s, i64 1)
  ret <16 x i8> %r
}

define <16 x i8> @unsupported_vcopy_musttail(<16 x i8> %d, i64 %di, <16 x i8> %s, i64 %si) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call <16 x i8> @llvm.aarch64.neon.vcopy.lane.v16i8.v16i8(<16 x i8> %d, i64 0, <16 x i8> %s, i64 1)
  ret <16 x i8> %r
}

define <16 x i8> @unsupported_vcopy_bundle(<16 x i8> %d, <16 x i8> %s) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <16 x i8> @llvm.aarch64.neon.vcopy.lane.v16i8.v16i8(<16 x i8> %d, i64 0, <16 x i8> %s, i64 1) [ "deopt"(i32 0) ]
  ret <16 x i8> %r
}

define i32 @main() {
entry:
  %z = load volatile <16 x i8>, ptr @sink16, align 16
  %r0 = call <16 x i8> @protected_vcopy_v16i8(<16 x i8> %z, <16 x i8> %z)
  store volatile <16 x i8> %r0, ptr @sink16, align 16
  %s = bitcast <16 x i8> %z to <8 x i16>
  %r1 = call <8 x i16> @protected_vcopy_v8i16(<8 x i16> %s, <8 x i16> %s)
  %b1 = bitcast <8 x i16> %r1 to <16 x i8>
  store volatile <16 x i8> %b1, ptr @sink16, align 16
  %w = bitcast <16 x i8> %z to <4 x i32>
  %r2 = call <4 x i32> @protected_vcopy_v4i32(<4 x i32> %w, <4 x i32> %w)
  %b2 = bitcast <4 x i32> %r2 to <16 x i8>
  store volatile <16 x i8> %b2, ptr @sink16, align 16
  %l = bitcast <16 x i8> %z to <2 x i64>
  %r3 = call <2 x i64> @protected_vcopy_v2i64(<2 x i64> %l, <2 x i64> %l)
  %b3 = bitcast <2 x i64> %r3 to <16 x i8>
  store volatile <16 x i8> %b3, ptr @sink16, align 16
  ret i32 0
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_vcopy_v8i8: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_vcopy_mismatch: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_vcopy_half: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_vcopy_f32: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_vcopy_dyn: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_vcopy_oor: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_vcopy_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_vcopy_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_vcopy_bundle: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_vcopy_v16i8:
; SKIP-NOT: Skipping VMP on protected_vcopy_v8i16:
; SKIP-NOT: Skipping VMP on protected_vcopy_v4i32:
; SKIP-NOT: Skipping VMP on protected_vcopy_v2i64:

; VIRT: define <16 x i8> @protected_vcopy_v16i8({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <16 x i8> @llvm.aarch64.neon.vcopy.lane.v16i8.v16i8({{.*}}i64 0,{{.*}}i64 1)
; VIRT: define <8 x i16> @protected_vcopy_v8i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x i16> @llvm.aarch64.neon.vcopy.lane.v8i16.v8i16({{.*}}i64 3,{{.*}}i64 7)
; VIRT: define <4 x i32> @protected_vcopy_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.aarch64.neon.vcopy.lane.v4i32.v4i32({{.*}}i64 1,{{.*}}i64 2)
; VIRT: define <2 x i64> @protected_vcopy_v2i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i64> @llvm.aarch64.neon.vcopy.lane.v2i64.v2i64({{.*}}i64 0,{{.*}}i64 1)
; VIRT: define {{.*}} @unsupported_vcopy_v8i8({{.*}} #[[UNSUPATTR:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_vcopy_mismatch({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_vcopy_half({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_vcopy_f32({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_vcopy_dyn({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_vcopy_oor({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_vcopy_fastcc({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_vcopy_musttail({{.*}} #[[UNSUP_MT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call <16 x i8> @llvm.aarch64.neon.vcopy.lane.v16i8.v16i8(
; VIRT: define {{.*}} @unsupported_vcopy_bundle({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call <16 x i8> @llvm.aarch64.neon.vcopy.lane.v16i8.v16i8({{.*}}[ "deopt"(i32 0) ]
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_MT]] = { {{.*}}"hikari.vmp.virtualized"
