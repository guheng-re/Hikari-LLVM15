; Restricted AArch64 NEON tbl/tbx via the existing CallDescriptor and
; vector VReg frame.  Exact IntrinsicsAArch64.td shapes only:
;   tblN: anyvector (v16i8 x N, match indices)
;   tbxN: anyvector (match passthru, v16i8 x N, match indices)
; Result/index are supported <8 x i8> or <16 x i8>; tables are always
; <16 x i8>.  Call site must be CallingConv::C and non-vararg (fastcc
; stays selected, not virtualized).  Direct musttail skips as
; "musttail call"; operand bundles skip as unsupported call.  No
; dedicated VM opcode.  No extra +neon / +fullfp16 gate (baseline
; AArch64 AdvSIMD).  Command-line -mattr is never used.
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
declare <16 x i8> @llvm.aarch64.neon.tbl1.v16i8(<16 x i8>, <16 x i8>)
declare <8 x i8> @llvm.aarch64.neon.tbl1.v8i8(<16 x i8>, <8 x i8>)
declare <16 x i8> @llvm.aarch64.neon.tbl2.v16i8(<16 x i8>, <16 x i8>, <16 x i8>)
declare <16 x i8> @llvm.aarch64.neon.tbl3.v16i8(<16 x i8>, <16 x i8>, <16 x i8>, <16 x i8>)
declare <16 x i8> @llvm.aarch64.neon.tbl4.v16i8(<16 x i8>, <16 x i8>, <16 x i8>, <16 x i8>, <16 x i8>)
declare <16 x i8> @llvm.aarch64.neon.tbx1.v16i8(<16 x i8>, <16 x i8>, <16 x i8>)
declare <8 x i8> @llvm.aarch64.neon.tbx1.v8i8(<8 x i8>, <16 x i8>, <8 x i8>)
declare <16 x i8> @llvm.aarch64.neon.tbx2.v16i8(<16 x i8>, <16 x i8>, <16 x i8>, <16 x i8>)
declare <16 x i8> @llvm.aarch64.neon.tbx3.v16i8(<16 x i8>, <16 x i8>, <16 x i8>, <16 x i8>, <16 x i8>)
declare <16 x i8> @llvm.aarch64.neon.tbx4.v16i8(<16 x i8>, <16 x i8>, <16 x i8>, <16 x i8>, <16 x i8>, <16 x i8>)
declare <8 x i16> @llvm.aarch64.neon.tbl1.v8i16(<16 x i8>, <8 x i16>)
declare <4 x i8> @llvm.aarch64.neon.tbl1.v4i8(<16 x i8>, <4 x i8>)
declare <8 x i8> @llvm.arm.neon.vtbl1(<8 x i8>, <8 x i8>)

@sink16 = global <16 x i8> zeroinitializer, align 16
@sink8 = global <8 x i8> zeroinitializer, align 8

define <16 x i8> @protected_tbl1_v16(<16 x i8> %t, <16 x i8> %i) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <16 x i8> @llvm.aarch64.neon.tbl1.v16i8(<16 x i8> %t, <16 x i8> %i)
  ret <16 x i8> %r
}

define <8 x i8> @protected_tbl1_v8(<16 x i8> %t, <8 x i8> %i) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i8> @llvm.aarch64.neon.tbl1.v8i8(<16 x i8> %t, <8 x i8> %i)
  ret <8 x i8> %r
}

define <16 x i8> @protected_tbl2_v16(<16 x i8> %t0, <16 x i8> %t1, <16 x i8> %i) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <16 x i8> @llvm.aarch64.neon.tbl2.v16i8(<16 x i8> %t0, <16 x i8> %t1, <16 x i8> %i)
  ret <16 x i8> %r
}

define <16 x i8> @protected_tbl3_v16(<16 x i8> %t0, <16 x i8> %t1, <16 x i8> %t2, <16 x i8> %i) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <16 x i8> @llvm.aarch64.neon.tbl3.v16i8(<16 x i8> %t0, <16 x i8> %t1, <16 x i8> %t2, <16 x i8> %i)
  ret <16 x i8> %r
}

define <16 x i8> @protected_tbl4_v16(<16 x i8> %t0, <16 x i8> %t1, <16 x i8> %t2, <16 x i8> %t3, <16 x i8> %i) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <16 x i8> @llvm.aarch64.neon.tbl4.v16i8(<16 x i8> %t0, <16 x i8> %t1, <16 x i8> %t2, <16 x i8> %t3, <16 x i8> %i)
  ret <16 x i8> %r
}

define <16 x i8> @protected_tbx1_v16(<16 x i8> %p, <16 x i8> %t, <16 x i8> %i) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <16 x i8> @llvm.aarch64.neon.tbx1.v16i8(<16 x i8> %p, <16 x i8> %t, <16 x i8> %i)
  ret <16 x i8> %r
}

define <8 x i8> @protected_tbx1_v8(<8 x i8> %p, <16 x i8> %t, <8 x i8> %i) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i8> @llvm.aarch64.neon.tbx1.v8i8(<8 x i8> %p, <16 x i8> %t, <8 x i8> %i)
  ret <8 x i8> %r
}

define <16 x i8> @protected_tbx2_v16(<16 x i8> %p, <16 x i8> %t0, <16 x i8> %t1, <16 x i8> %i) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <16 x i8> @llvm.aarch64.neon.tbx2.v16i8(<16 x i8> %p, <16 x i8> %t0, <16 x i8> %t1, <16 x i8> %i)
  ret <16 x i8> %r
}

define <16 x i8> @protected_tbx3_v16(<16 x i8> %p, <16 x i8> %t0, <16 x i8> %t1, <16 x i8> %t2, <16 x i8> %i) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <16 x i8> @llvm.aarch64.neon.tbx3.v16i8(<16 x i8> %p, <16 x i8> %t0, <16 x i8> %t1, <16 x i8> %t2, <16 x i8> %i)
  ret <16 x i8> %r
}

define <16 x i8> @protected_tbx4_v16(<16 x i8> %p, <16 x i8> %t0, <16 x i8> %t1, <16 x i8> %t2, <16 x i8> %t3, <16 x i8> %i) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <16 x i8> @llvm.aarch64.neon.tbx4.v16i8(<16 x i8> %p, <16 x i8> %t0, <16 x i8> %t1, <16 x i8> %t2, <16 x i8> %t3, <16 x i8> %i)
  ret <16 x i8> %r
}

; ----- negatives: selected, not virtualized -----

define <8 x i16> @unsupported_tbl_i16(<16 x i8> %t, <8 x i16> %i) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i16> @llvm.aarch64.neon.tbl1.v8i16(<16 x i8> %t, <8 x i16> %i)
  ret <8 x i16> %r
}

define <4 x i8> @unsupported_tbl_v4i8(<16 x i8> %t, <4 x i8> %i) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i8> @llvm.aarch64.neon.tbl1.v4i8(<16 x i8> %t, <4 x i8> %i)
  ret <4 x i8> %r
}

; Well-formed llvm.aarch64.neon.pmull.v8i16 is covered by
; vmp-aarch64-neon-pmull-semantic.ll and must not stay here as a
; negative (it would virtualize).

define <8 x i8> @unsupported_arm_vtbl1(<8 x i8> %t, <8 x i8> %i) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i8> @llvm.arm.neon.vtbl1(<8 x i8> %t, <8 x i8> %i)
  ret <8 x i8> %r
}

define <16 x i8> @unsupported_tbl_fastcc(<16 x i8> %t, <16 x i8> %i) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc <16 x i8> @llvm.aarch64.neon.tbl1.v16i8(<16 x i8> %t, <16 x i8> %i)
  ret <16 x i8> %r
}

define <16 x i8> @unsupported_tbl_musttail(<16 x i8> %t, <16 x i8> %i) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call <16 x i8> @llvm.aarch64.neon.tbl1.v16i8(<16 x i8> %t, <16 x i8> %i)
  ret <16 x i8> %r
}

define <16 x i8> @unsupported_tbl_bundle(<16 x i8> %t, <16 x i8> %i) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <16 x i8> @llvm.aarch64.neon.tbl1.v16i8(<16 x i8> %t, <16 x i8> %i) [ "deopt"(i32 0) ]
  ret <16 x i8> %r
}

define <vscale x 16 x i8> @unsupported_scalable(<16 x i8> %t, <vscale x 16 x i8> %i) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 16 x i8> @llvm.aarch64.neon.tbl1.nxv16i8(<16 x i8> %t, <vscale x 16 x i8> %i)
  ret <vscale x 16 x i8> %r
}

declare <vscale x 16 x i8> @llvm.aarch64.neon.tbl1.nxv16i8(<16 x i8>, <vscale x 16 x i8>)

define i32 @main() {
entry:
  %z16 = load volatile <16 x i8>, ptr @sink16, align 16
  %z8 = load volatile <8 x i8>, ptr @sink8, align 8
  %r0 = call <16 x i8> @protected_tbl1_v16(<16 x i8> %z16, <16 x i8> %z16)
  store volatile <16 x i8> %r0, ptr @sink16, align 16
  %r1 = call <8 x i8> @protected_tbl1_v8(<16 x i8> %z16, <8 x i8> %z8)
  store volatile <8 x i8> %r1, ptr @sink8, align 8
  %r2 = call <16 x i8> @protected_tbl2_v16(<16 x i8> %z16, <16 x i8> %z16, <16 x i8> %z16)
  store volatile <16 x i8> %r2, ptr @sink16, align 16
  %r3 = call <16 x i8> @protected_tbl3_v16(<16 x i8> %z16, <16 x i8> %z16, <16 x i8> %z16, <16 x i8> %z16)
  store volatile <16 x i8> %r3, ptr @sink16, align 16
  %r4 = call <16 x i8> @protected_tbl4_v16(<16 x i8> %z16, <16 x i8> %z16, <16 x i8> %z16, <16 x i8> %z16, <16 x i8> %z16)
  store volatile <16 x i8> %r4, ptr @sink16, align 16
  %r5 = call <16 x i8> @protected_tbx1_v16(<16 x i8> %z16, <16 x i8> %z16, <16 x i8> %z16)
  store volatile <16 x i8> %r5, ptr @sink16, align 16
  %r6 = call <8 x i8> @protected_tbx1_v8(<8 x i8> %z8, <16 x i8> %z16, <8 x i8> %z8)
  store volatile <8 x i8> %r6, ptr @sink8, align 8
  %r7 = call <16 x i8> @protected_tbx2_v16(<16 x i8> %z16, <16 x i8> %z16, <16 x i8> %z16, <16 x i8> %z16)
  store volatile <16 x i8> %r7, ptr @sink16, align 16
  %r8 = call <16 x i8> @protected_tbx3_v16(<16 x i8> %z16, <16 x i8> %z16, <16 x i8> %z16, <16 x i8> %z16, <16 x i8> %z16)
  store volatile <16 x i8> %r8, ptr @sink16, align 16
  %r9 = call <16 x i8> @protected_tbx4_v16(<16 x i8> %z16, <16 x i8> %z16, <16 x i8> %z16, <16 x i8> %z16, <16 x i8> %z16, <16 x i8> %z16)
  store volatile <16 x i8> %r9, ptr @sink16, align 16
  ret i32 0
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_tbl_i16: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_tbl_v4i8: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_arm_vtbl1: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_tbl_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_tbl_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_tbl_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_scalable: unsupported return type
; SKIP-NOT: Skipping VMP on protected_tbl1_v16:
; SKIP-NOT: Skipping VMP on protected_tbl1_v8:
; SKIP-NOT: Skipping VMP on protected_tbl2_v16:
; SKIP-NOT: Skipping VMP on protected_tbl3_v16:
; SKIP-NOT: Skipping VMP on protected_tbl4_v16:
; SKIP-NOT: Skipping VMP on protected_tbx1_v16:
; SKIP-NOT: Skipping VMP on protected_tbx1_v8:
; SKIP-NOT: Skipping VMP on protected_tbx2_v16:
; SKIP-NOT: Skipping VMP on protected_tbx3_v16:
; SKIP-NOT: Skipping VMP on protected_tbx4_v16:

; VIRT: define <16 x i8> @protected_tbl1_v16({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <16 x i8> @llvm.aarch64.neon.tbl1.v16i8(
; VIRT: define <8 x i8> @protected_tbl1_v8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x i8> @llvm.aarch64.neon.tbl1.v8i8(
; VIRT: define <16 x i8> @protected_tbl2_v16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <16 x i8> @llvm.aarch64.neon.tbl2.v16i8(
; VIRT: define <16 x i8> @protected_tbl3_v16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <16 x i8> @llvm.aarch64.neon.tbl3.v16i8(
; VIRT: define <16 x i8> @protected_tbl4_v16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <16 x i8> @llvm.aarch64.neon.tbl4.v16i8(
; VIRT: define <16 x i8> @protected_tbx1_v16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <16 x i8> @llvm.aarch64.neon.tbx1.v16i8(
; VIRT: define <8 x i8> @protected_tbx1_v8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x i8> @llvm.aarch64.neon.tbx1.v8i8(
; VIRT: define <16 x i8> @protected_tbx2_v16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <16 x i8> @llvm.aarch64.neon.tbx2.v16i8(
; VIRT: define <16 x i8> @protected_tbx3_v16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <16 x i8> @llvm.aarch64.neon.tbx3.v16i8(
; VIRT: define <16 x i8> @protected_tbx4_v16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <16 x i8> @llvm.aarch64.neon.tbx4.v16i8(
; VIRT: define {{.*}} @unsupported_tbl_i16({{.*}} #[[UNSUPATTR:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_tbl_v4i8({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_arm_vtbl1({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_tbl_fastcc({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_tbl_musttail({{.*}} #[[UNSUP_MT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call <16 x i8> @llvm.aarch64.neon.tbl1.v16i8(
; VIRT: define {{.*}} @unsupported_tbl_bundle({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call <16 x i8> @llvm.aarch64.neon.tbl1.v16i8({{.*}}[ "deopt"(i32 0) ]
; VIRT: define {{.*}} @unsupported_scalable({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_MT]] = { {{.*}}"hikari.vmp.virtualized"
