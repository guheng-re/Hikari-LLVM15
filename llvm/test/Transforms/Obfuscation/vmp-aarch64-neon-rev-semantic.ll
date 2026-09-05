; AArch64 NEON vrev16 / vrev32 / vrev64 review lock-in.
; LLVM 15 has no llvm.aarch64.neon.rev16 / rev32 / rev64 IR IDs.
; clang arm_neon.td VREV16 / VREV32 / VREV64 / VREV64H are WOpInst
; OP_REV16 / OP_REV32 / OP_REV64 = shuffle $p0, $p0, (rev N, mask0).
; Generated arm_neon.h emits __builtin_shufflevector (generic
; shufflevector).  AArch64 ISel isREVMask(16/32/64) lowers those
; constant masks to AArch64ISD::REV16 / REV32 / REV64 -> asm rev16 /
; rev32 / rev64.  The only in-tree rev-style IDs are SVE
; (sve.rev / sve.revb / sve.revh / sve.revw / sve.revd) and stay out.
; Do not invent neon.rev* CallDescriptor IDs.  Ordinary frontend
; forms are already the supported constant-mask shufflevector path
; (integer / half / f32 / f64 1..128).  This lit locks the clang
; little-endian integer masks and ISel-proven REV assembly.
; Scalar bswap / bitreverse, zip/uzp/trn, and float/half frontend
; vrev64 are other generic surfaces, not a new ID family.
;
; Host lli is not used: this is an AArch64 ISel lock-in, and integer
; shuffle behavior is already covered by vmp-fixed-vector-semantic.ll.
; FileCheck + AArch64 llc/readobj/asm.  O0/O2 x 97/7.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.ll -o %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o0.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.ll -o %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o2.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
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
declare void @sink8(<8 x i8>)
declare <8 x i8> @id8(<8 x i8>)
declare <vscale x 16 x i8> @llvm.aarch64.sve.rev.nxv16i8(<vscale x 16 x i8>)
declare <vscale x 8 x i16> @llvm.aarch64.sve.revb.nxv8i16(<vscale x 8 x i16>, <vscale x 8 x i1>, <vscale x 8 x i16>)
declare <vscale x 16 x i8> @llvm.aarch64.sve.revd.nxv16i8(<vscale x 16 x i8>, <vscale x 16 x i1>, <vscale x 16 x i8>)

@sink_v8i8 = global <8 x i8> zeroinitializer, align 8
@sink_v16i8 = global <16 x i8> zeroinitializer, align 16
@sink_v8i16 = global <8 x i16> zeroinitializer, align 16
@sink_v4i16 = global <4 x i16> zeroinitializer, align 8
@sink_v4i32 = global <4 x i32> zeroinitializer, align 16

; clang vrev16_u8 / vrev16_s8 little-endian mask
define <8 x i8> @protected_rev16_v8i8(<8 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = shufflevector <8 x i8> %a, <8 x i8> %a, <8 x i32> <i32 1, i32 0, i32 3, i32 2, i32 5, i32 4, i32 7, i32 6>
  ret <8 x i8> %r
}

; clang vrev16q_u8
define <16 x i8> @protected_rev16_v16i8(<16 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = shufflevector <16 x i8> %a, <16 x i8> %a, <16 x i32> <i32 1, i32 0, i32 3, i32 2, i32 5, i32 4, i32 7, i32 6, i32 9, i32 8, i32 11, i32 10, i32 13, i32 12, i32 15, i32 14>
  ret <16 x i8> %r
}

; clang vrev32_u8
define <8 x i8> @protected_rev32_v8i8(<8 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = shufflevector <8 x i8> %a, <8 x i8> %a, <8 x i32> <i32 3, i32 2, i32 1, i32 0, i32 7, i32 6, i32 5, i32 4>
  ret <8 x i8> %r
}

; clang vrev32q_u16
define <8 x i16> @protected_rev32_v8i16(<8 x i16> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = shufflevector <8 x i16> %a, <8 x i16> %a, <8 x i32> <i32 1, i32 0, i32 3, i32 2, i32 5, i32 4, i32 7, i32 6>
  ret <8 x i16> %r
}

; clang vrev64_u8
define <8 x i8> @protected_rev64_v8i8(<8 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = shufflevector <8 x i8> %a, <8 x i8> %a, <8 x i32> <i32 7, i32 6, i32 5, i32 4, i32 3, i32 2, i32 1, i32 0>
  ret <8 x i8> %r
}

; clang vrev64_u16
define <4 x i16> @protected_rev64_v4i16(<4 x i16> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = shufflevector <4 x i16> %a, <4 x i16> %a, <4 x i32> <i32 3, i32 2, i32 1, i32 0>
  ret <4 x i16> %r
}

; clang vrev64q_u32
define <4 x i32> @protected_rev64_v4i32(<4 x i32> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = shufflevector <4 x i32> %a, <4 x i32> %a, <4 x i32> <i32 1, i32 0, i32 3, i32 2>
  ret <4 x i32> %r
}

; ----- negatives: selected, not virtualized -----

define <vscale x 16 x i8> @unsupported_sve_rev(<vscale x 16 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 16 x i8> @llvm.aarch64.sve.rev.nxv16i8(<vscale x 16 x i8> %a)
  ret <vscale x 16 x i8> %r
}

define <vscale x 8 x i16> @unsupported_sve_revb(<vscale x 8 x i16> %a, <vscale x 8 x i1> %pg) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 8 x i16> @llvm.aarch64.sve.revb.nxv8i16(<vscale x 8 x i16> %a, <vscale x 8 x i1> %pg, <vscale x 8 x i16> %a)
  ret <vscale x 8 x i16> %r
}

define <vscale x 16 x i8> @unsupported_sve_revd(<vscale x 16 x i8> %a, <vscale x 16 x i1> %pg) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 16 x i8> @llvm.aarch64.sve.revd.nxv16i8(<vscale x 16 x i8> %a, <vscale x 16 x i1> %pg, <vscale x 16 x i8> %a)
  ret <vscale x 16 x i8> %r
}

; 256-bit result is outside the 1..128 fixed-vector frame.
define <32 x i8> @unsupported_wide(<16 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = shufflevector <16 x i8> %a, <16 x i8> %a, <32 x i32> <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7, i32 8, i32 9, i32 10, i32 11, i32 12, i32 13, i32 14, i32 15, i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7, i32 8, i32 9, i32 10, i32 11, i32 12, i32 13, i32 14, i32 15>
  ret <32 x i8> %r
}

define <4 x bfloat> @unsupported_bfloat(<4 x bfloat> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = shufflevector <4 x bfloat> %a, <4 x bfloat> %a, <4 x i32> <i32 1, i32 0, i32 3, i32 2>
  ret <4 x bfloat> %r
}


define <8 x i8> @unsupported_musttail(<8 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %s = shufflevector <8 x i8> %a, <8 x i8> %a, <8 x i32> <i32 1, i32 0, i32 3, i32 2, i32 5, i32 4, i32 7, i32 6>
  %r = musttail call <8 x i8> @id8(<8 x i8> %s)
  ret <8 x i8> %r
}

define <8 x i8> @unsupported_bundle(<8 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = shufflevector <8 x i8> %a, <8 x i8> %a, <8 x i32> <i32 1, i32 0, i32 3, i32 2, i32 5, i32 4, i32 7, i32 6>
  call void @sink8(<8 x i8> %r) [ "deopt"(i32 0) ]
  ret <8 x i8> %r
}

define i32 @main() {
entry:
  %a8 = load volatile <8 x i8>, ptr @sink_v8i8, align 8
  %r0 = call <8 x i8> @protected_rev16_v8i8(<8 x i8> %a8)
  store volatile <8 x i8> %r0, ptr @sink_v8i8, align 8
  %a16 = load volatile <16 x i8>, ptr @sink_v16i8, align 16
  %r1 = call <16 x i8> @protected_rev16_v16i8(<16 x i8> %a16)
  store volatile <16 x i8> %r1, ptr @sink_v16i8, align 16
  %r2 = call <8 x i8> @protected_rev32_v8i8(<8 x i8> %a8)
  store volatile <8 x i8> %r2, ptr @sink_v8i8, align 8
  %a816 = load volatile <8 x i16>, ptr @sink_v8i16, align 16
  %r3 = call <8 x i16> @protected_rev32_v8i16(<8 x i16> %a816)
  store volatile <8 x i16> %r3, ptr @sink_v8i16, align 16
  %r4 = call <8 x i8> @protected_rev64_v8i8(<8 x i8> %a8)
  store volatile <8 x i8> %r4, ptr @sink_v8i8, align 8
  %a416 = load volatile <4 x i16>, ptr @sink_v4i16, align 8
  %r5 = call <4 x i16> @protected_rev64_v4i16(<4 x i16> %a416)
  store volatile <4 x i16> %r5, ptr @sink_v4i16, align 8
  %a432 = load volatile <4 x i32>, ptr @sink_v4i32, align 16
  %r6 = call <4 x i32> @protected_rev64_v4i32(<4 x i32> %a432)
  store volatile <4 x i32> %r6, ptr @sink_v4i32, align 16
  ret i32 0
}

; SKIP-DAG: Skipping VMP on unsupported_sve_rev: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_sve_revb: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_sve_revd: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_wide: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_bfloat: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_rev16_v8i8:
; SKIP-NOT: Skipping VMP on protected_rev16_v16i8:
; SKIP-NOT: Skipping VMP on protected_rev32_v8i8:
; SKIP-NOT: Skipping VMP on protected_rev32_v8i16:
; SKIP-NOT: Skipping VMP on protected_rev64_v8i8:
; SKIP-NOT: Skipping VMP on protected_rev64_v4i16:
; SKIP-NOT: Skipping VMP on protected_rev64_v4i32:

; VIRT: define <8 x i8> @protected_rev16_v8i8({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: shufflevector <8 x i8>
; VIRT: define <16 x i8> @protected_rev16_v16i8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: shufflevector <16 x i8>
; VIRT: define <8 x i8> @protected_rev32_v8i8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: shufflevector <8 x i8>
; VIRT: define <8 x i16> @protected_rev32_v8i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: shufflevector <8 x i16>
; VIRT: define <8 x i8> @protected_rev64_v8i8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: shufflevector <8 x i8>
; VIRT: define <4 x i16> @protected_rev64_v4i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: shufflevector <4 x i16>
; VIRT: define <4 x i32> @protected_rev64_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: shufflevector <4 x i32>
; VIRT: define {{.*}} @unsupported_sve_rev({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; AARCH64-ASM-DAG: {{^[[:space:]]*}}rev16{{[ \t]}}{{v[0-9]+}}.8b
; AARCH64-ASM-DAG: {{^[[:space:]]*}}rev16{{[ \t]}}{{v[0-9]+}}.16b
; AARCH64-ASM-DAG: {{^[[:space:]]*}}rev32{{[ \t]}}{{v[0-9]+}}.8b
; AARCH64-ASM-DAG: {{^[[:space:]]*}}rev32{{[ \t]}}{{v[0-9]+}}.8h
; AARCH64-ASM-DAG: {{^[[:space:]]*}}rev64{{[ \t]}}{{v[0-9]+}}.8b
; AARCH64-ASM-DAG: {{^[[:space:]]*}}rev64{{[ \t]}}{{v[0-9]+}}.4h
; AARCH64-ASM-DAG: {{^[[:space:]]*}}rev64{{[ \t]}}{{v[0-9]+}}.4s
; HOST: Skipping VMP: only AArch64 targets are supported
