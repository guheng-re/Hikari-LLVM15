; Restricted AArch64 NEON widening integer add/sub.
; LLVM 15 has no llvm.aarch64.neon.saddl / uaddl / ssubl / usubl IR
; IDs (clang vaddl/vsubl is vmovl + add/sub).  ISel
; SIMDLongThreeVectorBHS (baseline HasNEON) matches:
;   saddl:  add (sext, sext)   v8i8->v8i16 / v4i16->v4i32 / v2i32->v2i64
;   uaddl:  add (zext, zext)   same pairs
;   ssubl:  sub (sext, sext)   same pairs
;   usubl:  sub (zext, zext)   same pairs
; Coverage is existing VectorSExt / VectorZExt / VectorAdd / VectorSub.
; Do not invent CallDescriptor IDs.  High-half saddl2 is extract_high
; of this same IR.  saddw/ssubw, saddlp/saddlv, and SVE stay
; out of this surface.  Widening sabdl/uabdl is
; vmp-aarch64-neon-sabdl-semantic.ll.  Narrow-high addhn is
; vmp-aarch64-neon-addhn-semantic.ll.  Same-width sabd/uabd is
; vmp-aarch64-neon-abd-semantic.ll.  No new opcode.
;
; Replayed IR is ordinary integer vectors; host lli can run live
; bytecode.  FileCheck + AArch64 llc/readobj/asm.  O0/O2 x 97/7.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.ll -o %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o0.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.live.ll | lli -force-interpreter
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.ll -o %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o2.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.live.ll | lli -force-interpreter
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.s7.ll -o %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o0.s7.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.s7.ll -o %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o2.s7.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %s | opt -S -verify-each -aesSeed=97 -passes='default<O0>' - 2>&1 | FileCheck %s --check-prefix=HOST

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare <vscale x 8 x i16> @llvm.aarch64.sve.saddlb.nxv8i16(<vscale x 16 x i8>, <vscale x 16 x i8>)
declare <vscale x 8 x i16> @llvm.aarch64.sve.ssublb.nxv8i16(<vscale x 16 x i8>, <vscale x 16 x i8>)

@sink_v8i8 = global <8 x i8> zeroinitializer, align 8
@sink_v8i16 = global <8 x i16> zeroinitializer, align 16
@sink_v4i16 = global <4 x i16> zeroinitializer, align 8
@sink_v4i32 = global <4 x i32> zeroinitializer, align 16
@sink_v2i32 = global <2 x i32> zeroinitializer, align 8
@sink_v2i64 = global <2 x i64> zeroinitializer, align 16

define <8 x i16> @protected_saddl_v8(<8 x i8> %a, <8 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %xa = sext <8 x i8> %a to <8 x i16>
  %xb = sext <8 x i8> %b to <8 x i16>
  %r = add <8 x i16> %xa, %xb
  ret <8 x i16> %r
}

define <4 x i32> @protected_saddl_v4(<4 x i16> %a, <4 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %xa = sext <4 x i16> %a to <4 x i32>
  %xb = sext <4 x i16> %b to <4 x i32>
  %r = add <4 x i32> %xa, %xb
  ret <4 x i32> %r
}

define <2 x i64> @protected_saddl_v2(<2 x i32> %a, <2 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %xa = sext <2 x i32> %a to <2 x i64>
  %xb = sext <2 x i32> %b to <2 x i64>
  %r = add <2 x i64> %xa, %xb
  ret <2 x i64> %r
}

define <8 x i16> @protected_uaddl_v8(<8 x i8> %a, <8 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %xa = zext <8 x i8> %a to <8 x i16>
  %xb = zext <8 x i8> %b to <8 x i16>
  %r = add <8 x i16> %xa, %xb
  ret <8 x i16> %r
}

define <4 x i32> @protected_uaddl_v4(<4 x i16> %a, <4 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %xa = zext <4 x i16> %a to <4 x i32>
  %xb = zext <4 x i16> %b to <4 x i32>
  %r = add <4 x i32> %xa, %xb
  ret <4 x i32> %r
}

define <2 x i64> @protected_uaddl_v2(<2 x i32> %a, <2 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %xa = zext <2 x i32> %a to <2 x i64>
  %xb = zext <2 x i32> %b to <2 x i64>
  %r = add <2 x i64> %xa, %xb
  ret <2 x i64> %r
}

define <8 x i16> @protected_ssubl_v8(<8 x i8> %a, <8 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %xa = sext <8 x i8> %a to <8 x i16>
  %xb = sext <8 x i8> %b to <8 x i16>
  %r = sub <8 x i16> %xa, %xb
  ret <8 x i16> %r
}

define <4 x i32> @protected_ssubl_v4(<4 x i16> %a, <4 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %xa = sext <4 x i16> %a to <4 x i32>
  %xb = sext <4 x i16> %b to <4 x i32>
  %r = sub <4 x i32> %xa, %xb
  ret <4 x i32> %r
}

define <2 x i64> @protected_ssubl_v2(<2 x i32> %a, <2 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %xa = sext <2 x i32> %a to <2 x i64>
  %xb = sext <2 x i32> %b to <2 x i64>
  %r = sub <2 x i64> %xa, %xb
  ret <2 x i64> %r
}

define <8 x i16> @protected_usubl_v8(<8 x i8> %a, <8 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %xa = zext <8 x i8> %a to <8 x i16>
  %xb = zext <8 x i8> %b to <8 x i16>
  %r = sub <8 x i16> %xa, %xb
  ret <8 x i16> %r
}

define <4 x i32> @protected_usubl_v4(<4 x i16> %a, <4 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %xa = zext <4 x i16> %a to <4 x i32>
  %xb = zext <4 x i16> %b to <4 x i32>
  %r = sub <4 x i32> %xa, %xb
  ret <4 x i32> %r
}

define <2 x i64> @protected_usubl_v2(<2 x i32> %a, <2 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %xa = zext <2 x i32> %a to <2 x i64>
  %xb = zext <2 x i32> %b to <2 x i64>
  %r = sub <2 x i64> %xa, %xb
  ret <2 x i64> %r
}

; Well-formed llvm.aarch64.neon.addhn is covered by
; vmp-aarch64-neon-addhn-semantic.ll and must not stay here as a
; negative (it would virtualize).
; Well-formed llvm.aarch64.neon.saddlp / uaddlp is
; vmp-aarch64-neon-saddlp-semantic.ll.
; Well-formed llvm.aarch64.neon.sabd / uabd is
; vmp-aarch64-neon-abd-semantic.ll and must not stay here as a
; negative (it would virtualize).

define <vscale x 8 x i16> @unsupported_sve_saddlb(<vscale x 16 x i8> %a, <vscale x 16 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 8 x i16> @llvm.aarch64.sve.saddlb.nxv8i16(<vscale x 16 x i8> %a, <vscale x 16 x i8> %b)
  ret <vscale x 8 x i16> %r
}

define <vscale x 8 x i16> @unsupported_sve_ssublb(<vscale x 16 x i8> %a, <vscale x 16 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 8 x i16> @llvm.aarch64.sve.ssublb.nxv8i16(<vscale x 16 x i8> %a, <vscale x 16 x i8> %b)
  ret <vscale x 8 x i16> %r
}

define i32 @main() {
entry:
  %a8 = load volatile <8 x i8>, ptr @sink_v8i8, align 8
  %b8 = load volatile <8 x i8>, ptr @sink_v8i8, align 8
  %r0 = call <8 x i16> @protected_saddl_v8(<8 x i8> %a8, <8 x i8> %b8)
  store volatile <8 x i16> %r0, ptr @sink_v8i16, align 16
  %a4 = load volatile <4 x i16>, ptr @sink_v4i16, align 8
  %b4 = load volatile <4 x i16>, ptr @sink_v4i16, align 8
  %r1 = call <4 x i32> @protected_saddl_v4(<4 x i16> %a4, <4 x i16> %b4)
  store volatile <4 x i32> %r1, ptr @sink_v4i32, align 16
  %a2 = load volatile <2 x i32>, ptr @sink_v2i32, align 8
  %b2 = load volatile <2 x i32>, ptr @sink_v2i32, align 8
  %r2 = call <2 x i64> @protected_saddl_v2(<2 x i32> %a2, <2 x i32> %b2)
  store volatile <2 x i64> %r2, ptr @sink_v2i64, align 16
  %r3 = call <8 x i16> @protected_uaddl_v8(<8 x i8> %a8, <8 x i8> %b8)
  store volatile <8 x i16> %r3, ptr @sink_v8i16, align 16
  %r4 = call <4 x i32> @protected_uaddl_v4(<4 x i16> %a4, <4 x i16> %b4)
  store volatile <4 x i32> %r4, ptr @sink_v4i32, align 16
  %r5 = call <2 x i64> @protected_uaddl_v2(<2 x i32> %a2, <2 x i32> %b2)
  store volatile <2 x i64> %r5, ptr @sink_v2i64, align 16
  %r6 = call <8 x i16> @protected_ssubl_v8(<8 x i8> %a8, <8 x i8> %b8)
  store volatile <8 x i16> %r6, ptr @sink_v8i16, align 16
  %r7 = call <4 x i32> @protected_ssubl_v4(<4 x i16> %a4, <4 x i16> %b4)
  store volatile <4 x i32> %r7, ptr @sink_v4i32, align 16
  %r8 = call <2 x i64> @protected_ssubl_v2(<2 x i32> %a2, <2 x i32> %b2)
  store volatile <2 x i64> %r8, ptr @sink_v2i64, align 16
  %r9 = call <8 x i16> @protected_usubl_v8(<8 x i8> %a8, <8 x i8> %b8)
  store volatile <8 x i16> %r9, ptr @sink_v8i16, align 16
  %r10 = call <4 x i32> @protected_usubl_v4(<4 x i16> %a4, <4 x i16> %b4)
  store volatile <4 x i32> %r10, ptr @sink_v4i32, align 16
  %r11 = call <2 x i64> @protected_usubl_v2(<2 x i32> %a2, <2 x i32> %b2)
  store volatile <2 x i64> %r11, ptr @sink_v2i64, align 16
  ret i32 0
}

; SKIP-DAG: Skipping VMP on unsupported_sve_saddlb: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_sve_ssublb: unsupported return type
; SKIP-NOT: Skipping VMP on protected_saddl_v8:
; SKIP-NOT: Skipping VMP on protected_saddl_v4:
; SKIP-NOT: Skipping VMP on protected_saddl_v2:
; SKIP-NOT: Skipping VMP on protected_uaddl_v8:
; SKIP-NOT: Skipping VMP on protected_uaddl_v4:
; SKIP-NOT: Skipping VMP on protected_uaddl_v2:
; SKIP-NOT: Skipping VMP on protected_ssubl_v8:
; SKIP-NOT: Skipping VMP on protected_ssubl_v4:
; SKIP-NOT: Skipping VMP on protected_ssubl_v2:
; SKIP-NOT: Skipping VMP on protected_usubl_v8:
; SKIP-NOT: Skipping VMP on protected_usubl_v4:
; SKIP-NOT: Skipping VMP on protected_usubl_v2:

; VIRT: define <8 x i16> @protected_saddl_v8({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: define <4 x i32> @protected_saddl_v4({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <2 x i64> @protected_saddl_v2({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <8 x i16> @protected_uaddl_v8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <4 x i32> @protected_uaddl_v4({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <2 x i64> @protected_uaddl_v2({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <8 x i16> @protected_ssubl_v8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <4 x i32> @protected_ssubl_v4({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <2 x i64> @protected_ssubl_v2({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <8 x i16> @protected_usubl_v8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <4 x i32> @protected_usubl_v4({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <2 x i64> @protected_usubl_v2({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define {{.*}} @unsupported_sve_saddlb({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; VReg replay splits the ISel saddl idiom into widen then add/sub.
; AARCH64-ASM: sshll
; AARCH64-ASM: ushll
; AARCH64-ASM: add{{[ \t]+}}v
; AARCH64-ASM: sub{{[ \t]+}}v
; HOST: Skipping VMP: only AArch64 targets are supported
