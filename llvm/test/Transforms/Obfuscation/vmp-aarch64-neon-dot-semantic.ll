; Restricted AArch64 NEON integer dot-product via CallDescriptor /
; vector VRegs:
;   llvm.aarch64.neon.sdot / udot
;     AdvSIMD_Dot: acc (acc, bytes, bytes)
;     ISel SIMDThreeSameVectorDot under HasDotProd:
;       <2 x i32>(<2 x i32>, <8 x i8>, <8 x i8>)  SDOT/UDOT v8i8
;       <4 x i32>(<4 x i32>, <16 x i8>, <16 x i8>) SDOT/UDOT v16i8
; LLVM 15 has no neon.sdot.lane / .laneq IR IDs.  clang vdot_lane /
; vdot_laneq is SOpInst OP_DOT_LN: splat 32-bit group + vdot.
; ISel SDOTlane matches sdot(acc, a, bitcast(duplane32)).
; Last-token function +dotprod required; missing or final
; -dotprod, +i8mm, and +crypto do not count.  Command-line
; -mattr is never consulted.  Exact C non-vararg.  Ordinary
; ordinary tail accepted and replayed as non-tail; see vmp-direct-call-tail-eligibility-semantic.ll.  bfdot / SVE stay
; out.  Well-formed usdot is vmp-aarch64-neon-usdot-semantic.ll.
; Well-formed smmla/ummla/usmmla is
; vmp-aarch64-neon-i8mm-semantic.ll.  No new opcode.
;
; Host cannot select these AArch64 intrinsics; no lli.
; FileCheck + AArch64 llc/readobj/asm (-mattr=+dotprod).  O0/O2 x 97/7.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.ll -o %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+dotprod -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+dotprod %t.o0.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.ll -o %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+dotprod -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+dotprod %t.o2.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.s7.ll -o %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+dotprod -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+dotprod %t.o0.s7.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.s7.ll -o %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+dotprod -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+dotprod %t.o2.s7.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %s | opt -S -verify-each -aesSeed=97 -passes='default<O0>' - 2>&1 | FileCheck %s --check-prefix=HOST

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare <2 x i32> @llvm.aarch64.neon.sdot.v2i32.v8i8(<2 x i32>, <8 x i8>, <8 x i8>)
declare <4 x i32> @llvm.aarch64.neon.sdot.v4i32.v16i8(<4 x i32>, <16 x i8>, <16 x i8>)
declare <2 x i32> @llvm.aarch64.neon.udot.v2i32.v8i8(<2 x i32>, <8 x i8>, <8 x i8>)
declare <4 x i32> @llvm.aarch64.neon.udot.v4i32.v16i8(<4 x i32>, <16 x i8>, <16 x i8>)
declare <4 x i32> @llvm.aarch64.neon.sdot.v4i32.v8i8(<4 x i32>, <8 x i8>, <8 x i8>)
declare <vscale x 4 x i32> @llvm.aarch64.sve.sdot.nxv4i32.nxv16i8(<vscale x 4 x i32>, <vscale x 16 x i8>, <vscale x 16 x i8>)

@sink_v2i32 = global <2 x i32> zeroinitializer, align 8
@sink_v4i32 = global <4 x i32> zeroinitializer, align 16
@sink_v8i8 = global <8 x i8> zeroinitializer, align 8
@sink_v16i8 = global <16 x i8> zeroinitializer, align 16

define <2 x i32> @protected_sdot_v8(<2 x i32> %acc, <8 x i8> %a, <8 x i8> %b) noinline optnone "target-features"="+dotprod" {
entry:
  call void @hikari_vmp()
  %r = call <2 x i32> @llvm.aarch64.neon.sdot.v2i32.v8i8(<2 x i32> %acc, <8 x i8> %a, <8 x i8> %b)
  ret <2 x i32> %r
}

define <4 x i32> @protected_sdot_v16(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b) noinline optnone "target-features"="+dotprod" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.sdot.v4i32.v16i8(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b)
  ret <4 x i32> %r
}

define <2 x i32> @protected_udot_v8(<2 x i32> %acc, <8 x i8> %a, <8 x i8> %b) noinline optnone "target-features"="+dotprod" {
entry:
  call void @hikari_vmp()
  %r = call <2 x i32> @llvm.aarch64.neon.udot.v2i32.v8i8(<2 x i32> %acc, <8 x i8> %a, <8 x i8> %b)
  ret <2 x i32> %r
}

define <4 x i32> @protected_udot_v16(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b) noinline optnone "target-features"="+dotprod" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.udot.v4i32.v16i8(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b)
  ret <4 x i32> %r
}

; clang vdot_lane / vdot_laneq: splat a 32-bit group then sdot.
; No neon.sdot.lane IR ID.  ISel may fold to SDOTlane.
define <4 x i32> @protected_sdot_laneq(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b) noinline optnone "target-features"="+dotprod" {
entry:
  call void @hikari_vmp()
  %cast = bitcast <16 x i8> %b to <4 x i32>
  %dup = shufflevector <4 x i32> %cast, <4 x i32> %cast, <4 x i32> <i32 1, i32 1, i32 1, i32 1>
  %bytes = bitcast <4 x i32> %dup to <16 x i8>
  %r = call <4 x i32> @llvm.aarch64.neon.sdot.v4i32.v16i8(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %bytes)
  ret <4 x i32> %r
}

define <2 x i32> @protected_sdot_lane(<2 x i32> %acc, <8 x i8> %a, <8 x i8> %b) noinline optnone "target-features"="+dotprod" {
entry:
  call void @hikari_vmp()
  %cast = bitcast <8 x i8> %b to <2 x i32>
  %dup = shufflevector <2 x i32> %cast, <2 x i32> %cast, <2 x i32> <i32 0, i32 0>
  %bytes = bitcast <2 x i32> %dup to <8 x i8>
  %r = call <2 x i32> @llvm.aarch64.neon.sdot.v2i32.v8i8(<2 x i32> %acc, <8 x i8> %a, <8 x i8> %bytes)
  ret <2 x i32> %r
}

define <4 x i32> @protected_sdot_last_dotprod(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b) noinline optnone "target-features"="+neon,+crc,+dotprod" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.sdot.v4i32.v16i8(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b)
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_no_dotprod(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.sdot.v4i32.v16i8(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b)
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_dotprod_disabled(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b) noinline optnone "target-features"="+dotprod,-dotprod" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.sdot.v4i32.v16i8(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b)
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_i8mm_only(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b) noinline optnone "target-features"="+i8mm" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.sdot.v4i32.v16i8(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b)
  ret <4 x i32> %r
}

; Well-formed llvm.aarch64.neon.usdot is
; vmp-aarch64-neon-usdot-semantic.ll.

; Well-formed llvm.aarch64.neon.smmla is covered by
; vmp-aarch64-neon-i8mm-semantic.ll.  Missing +i8mm would skip as
; unsupported target feature, not stay here as a dot negative.

define <4 x i32> @unsupported_mixed_width(<4 x i32> %acc, <8 x i8> %a, <8 x i8> %b) noinline optnone "target-features"="+dotprod" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.sdot.v4i32.v8i8(<4 x i32> %acc, <8 x i8> %a, <8 x i8> %b)
  ret <4 x i32> %r
}

define <vscale x 4 x i32> @unsupported_sve_sdot(<vscale x 4 x i32> %acc, <vscale x 16 x i8> %a, <vscale x 16 x i8> %b) noinline optnone "target-features"="+dotprod" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.aarch64.sve.sdot.nxv4i32.nxv16i8(<vscale x 4 x i32> %acc, <vscale x 16 x i8> %a, <vscale x 16 x i8> %b)
  ret <vscale x 4 x i32> %r
}

define <4 x i32> @unsupported_fastcc(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b) noinline optnone "target-features"="+dotprod" {
entry:
  call void @hikari_vmp()
  %r = call fastcc <4 x i32> @llvm.aarch64.neon.sdot.v4i32.v16i8(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b)
  ret <4 x i32> %r
}


define <4 x i32> @unsupported_musttail(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b) noinline optnone "target-features"="+dotprod" {
entry:
  call void @hikari_vmp()
  %r = musttail call <4 x i32> @llvm.aarch64.neon.sdot.v4i32.v16i8(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b)
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_bundle(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b) noinline optnone "target-features"="+dotprod" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.sdot.v4i32.v16i8(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b) [ "deopt"(i32 0) ]
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_noreturn(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b) noinline optnone "target-features"="+dotprod" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.sdot.v4i32.v16i8(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b) noreturn
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_returns_twice(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b) noinline optnone "target-features"="+dotprod" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.sdot.v4i32.v16i8(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b) returns_twice
  ret <4 x i32> %r
}

define i32 @main() {
entry:
  %acc2 = load volatile <2 x i32>, ptr @sink_v2i32, align 8
  %acc4 = load volatile <4 x i32>, ptr @sink_v4i32, align 16
  %a8 = load volatile <8 x i8>, ptr @sink_v8i8, align 8
  %b8 = load volatile <8 x i8>, ptr @sink_v8i8, align 8
  %a16 = load volatile <16 x i8>, ptr @sink_v16i8, align 16
  %b16 = load volatile <16 x i8>, ptr @sink_v16i8, align 16
  %r0 = call <2 x i32> @protected_sdot_v8(<2 x i32> %acc2, <8 x i8> %a8, <8 x i8> %b8)
  store volatile <2 x i32> %r0, ptr @sink_v2i32, align 8
  %r1 = call <4 x i32> @protected_sdot_v16(<4 x i32> %acc4, <16 x i8> %a16, <16 x i8> %b16)
  store volatile <4 x i32> %r1, ptr @sink_v4i32, align 16
  %r2 = call <2 x i32> @protected_udot_v8(<2 x i32> %acc2, <8 x i8> %a8, <8 x i8> %b8)
  store volatile <2 x i32> %r2, ptr @sink_v2i32, align 8
  %r3 = call <4 x i32> @protected_udot_v16(<4 x i32> %acc4, <16 x i8> %a16, <16 x i8> %b16)
  store volatile <4 x i32> %r3, ptr @sink_v4i32, align 16
  %r4 = call <4 x i32> @protected_sdot_laneq(<4 x i32> %acc4, <16 x i8> %a16, <16 x i8> %b16)
  store volatile <4 x i32> %r4, ptr @sink_v4i32, align 16
  %r5 = call <2 x i32> @protected_sdot_lane(<2 x i32> %acc2, <8 x i8> %a8, <8 x i8> %b8)
  store volatile <2 x i32> %r5, ptr @sink_v2i32, align 8
  %r6 = call <4 x i32> @protected_sdot_last_dotprod(<4 x i32> %acc4, <16 x i8> %a16, <16 x i8> %b16)
  store volatile <4 x i32> %r6, ptr @sink_v4i32, align 16
  ret i32 0
}

; SKIP-DAG: Skipping VMP on unsupported_no_dotprod: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_dotprod_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_i8mm_only: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_mixed_width: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_sve_sdot: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_noreturn: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_returns_twice: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_sdot_v8:
; SKIP-NOT: Skipping VMP on protected_sdot_v16:
; SKIP-NOT: Skipping VMP on protected_udot_v8:
; SKIP-NOT: Skipping VMP on protected_udot_v16:
; SKIP-NOT: Skipping VMP on protected_sdot_laneq:
; SKIP-NOT: Skipping VMP on protected_sdot_lane:
; SKIP-NOT: Skipping VMP on protected_sdot_last_dotprod:

; VIRT: define <2 x i32> @protected_sdot_v8({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i32> @llvm.aarch64.neon.sdot.v2i32.v8i8(
; VIRT: define <4 x i32> @protected_sdot_v16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.aarch64.neon.sdot.v4i32.v16i8(
; VIRT: define <2 x i32> @protected_udot_v8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i32> @llvm.aarch64.neon.udot.v2i32.v8i8(
; VIRT: define <4 x i32> @protected_udot_v16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.aarch64.neon.udot.v4i32.v16i8(
; VIRT: define <4 x i32> @protected_sdot_laneq({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.aarch64.neon.sdot.v4i32.v16i8(
; VIRT: define <2 x i32> @protected_sdot_lane({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i32> @llvm.aarch64.neon.sdot.v2i32.v8i8(
; VIRT: define <4 x i32> @protected_sdot_last_dotprod({{.*}} #[[LAST:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.aarch64.neon.sdot.v4i32.v16i8(
; VIRT: define {{.*}} @unsupported_no_dotprod({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT: attributes #[[LAST]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; AARCH64-ASM: {{^[[:space:]]*}}sdot{{[ \t]}}
; AARCH64-ASM: {{^[[:space:]]*}}udot{{[ \t]}}
; HOST: Skipping VMP: only AArch64 targets are supported
