; Restricted AArch64 NEON widening absolute difference.
; LLVM 15 has no llvm.aarch64.neon.sabdl / uabdl IR IDs
; (IntrinsicsAArch64.td defines only same-width sabd/uabd and
; SVE sabdlb/sabdlt/uabdlb/uabdlt).  clang vabdl is SOpInst
; OP_ABDL: vmovl(unsigned cast, vabd) == zext(sabd/uabd).
; ISel SIMDLongThreeVectorBHSabdl (baseline HasNEON) matches:
;   sabdl: zext(sabd)  v8i8->v8i16 / v4i16->v4i32 / v2i32->v2i64
;   uabdl: zext(uabd)  same pairs
; Extra DAG pats match only uabdl as abs(sub(zext,zext)).
; Narrow signedness lives on sabd vs uabd; the widened result is
; always zero-extended (absdiff is non-negative).  Coverage is
; existing sabd/uabd CallDescriptor + VectorZExt.  Do not invent
; CallDescriptor IDs or high-half sabdl2 IDs.  High-half is
; extract_high of this same IR.  Accumulate-long sabal/uabal
; (add+zext(sabd)) has no IR ID and is out of this surface;
; well-formed sabal IR virtualizes via existing ops and must not
; stay here as a skip-negative.  Same-width sabd/uabd is
; vmp-aarch64-neon-abd-semantic.ll.  v2i64 / v4i8 / 256-bit
; v16i16 / fabd / half / SVE stay out.  Well-formed sisd.fabd is
; vmp-aarch64-neon-sisd-fabd-semantic.ll and must not stay here
; as a skip (it would virtualize).  Exact C non-vararg.
; Ordinary tail accepted and replayed as non-tail; see vmp-direct-call-tail-eligibility-semantic.ll.  No last-token
; gate.  No new opcode.
;
; VReg replay splits the ISel sabdl idiom into sabd/uabd then
; ushll.  Host cannot select the AArch64 abd intrinsic; no lli.
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
declare <8 x i8> @llvm.aarch64.neon.sabd.v8i8(<8 x i8>, <8 x i8>)
declare <4 x i16> @llvm.aarch64.neon.sabd.v4i16(<4 x i16>, <4 x i16>)
declare <2 x i32> @llvm.aarch64.neon.sabd.v2i32(<2 x i32>, <2 x i32>)
declare <8 x i8> @llvm.aarch64.neon.uabd.v8i8(<8 x i8>, <8 x i8>)
declare <4 x i16> @llvm.aarch64.neon.uabd.v4i16(<4 x i16>, <4 x i16>)
declare <2 x i32> @llvm.aarch64.neon.uabd.v2i32(<2 x i32>, <2 x i32>)
declare <2 x i64> @llvm.aarch64.neon.sabd.v2i64(<2 x i64>, <2 x i64>)
declare <4 x i8> @llvm.aarch64.neon.sabd.v4i8(<4 x i8>, <4 x i8>)
declare <16 x i8> @llvm.aarch64.neon.sabd.v16i8(<16 x i8>, <16 x i8>)
declare <vscale x 8 x i16> @llvm.aarch64.sve.sabdlb.nxv8i16(<vscale x 16 x i8>, <vscale x 16 x i8>)
declare <vscale x 8 x i16> @llvm.aarch64.sve.sabdlt.nxv8i16(<vscale x 16 x i8>, <vscale x 16 x i8>)
declare <vscale x 8 x i16> @llvm.aarch64.sve.uabdlb.nxv8i16(<vscale x 16 x i8>, <vscale x 16 x i8>)

@sink_v8i8 = global <8 x i8> zeroinitializer, align 8
@sink_v8i16 = global <8 x i16> zeroinitializer, align 16
@sink_v4i16 = global <4 x i16> zeroinitializer, align 8
@sink_v4i32 = global <4 x i32> zeroinitializer, align 16
@sink_v2i32 = global <2 x i32> zeroinitializer, align 8
@sink_v2i64 = global <2 x i64> zeroinitializer, align 16

define <8 x i16> @protected_sabdl_v8i8(<8 x i8> %a, <8 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %abd = call <8 x i8> @llvm.aarch64.neon.sabd.v8i8(<8 x i8> %a, <8 x i8> %b)
  %r = zext <8 x i8> %abd to <8 x i16>
  ret <8 x i16> %r
}

define <4 x i32> @protected_sabdl_v4i16(<4 x i16> %a, <4 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %abd = call <4 x i16> @llvm.aarch64.neon.sabd.v4i16(<4 x i16> %a, <4 x i16> %b)
  %r = zext <4 x i16> %abd to <4 x i32>
  ret <4 x i32> %r
}

define <2 x i64> @protected_sabdl_v2i32(<2 x i32> %a, <2 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %abd = call <2 x i32> @llvm.aarch64.neon.sabd.v2i32(<2 x i32> %a, <2 x i32> %b)
  %r = zext <2 x i32> %abd to <2 x i64>
  ret <2 x i64> %r
}

define <8 x i16> @protected_uabdl_v8i8(<8 x i8> %a, <8 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %abd = call <8 x i8> @llvm.aarch64.neon.uabd.v8i8(<8 x i8> %a, <8 x i8> %b)
  %r = zext <8 x i8> %abd to <8 x i16>
  ret <8 x i16> %r
}

define <4 x i32> @protected_uabdl_v4i16(<4 x i16> %a, <4 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %abd = call <4 x i16> @llvm.aarch64.neon.uabd.v4i16(<4 x i16> %a, <4 x i16> %b)
  %r = zext <4 x i16> %abd to <4 x i32>
  ret <4 x i32> %r
}

define <2 x i64> @protected_uabdl_v2i32(<2 x i32> %a, <2 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %abd = call <2 x i32> @llvm.aarch64.neon.uabd.v2i32(<2 x i32> %a, <2 x i32> %b)
  %r = zext <2 x i32> %abd to <2 x i64>
  ret <2 x i64> %r
}

; Well-formed same-width sabd/uabd is vmp-aarch64-neon-abd-semantic.ll
; and must not stay here as a negative (it would virtualize).
; Well-formed add+zext(sabd) (ISel sabal) virtualizes via existing
; ops and must not stay here as a skip-negative.

define <2 x i64> @unsupported_v2i64(<2 x i64> %a, <2 x i64> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.aarch64.neon.sabd.v2i64(<2 x i64> %a, <2 x i64> %b)
  ret <2 x i64> %r
}

define <4 x i16> @unsupported_v4i8(<4 x i8> %a, <4 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %abd = call <4 x i8> @llvm.aarch64.neon.sabd.v4i8(<4 x i8> %a, <4 x i8> %b)
  %r = zext <4 x i8> %abd to <4 x i16>
  ret <4 x i16> %r
}

define <16 x i16> @unsupported_v16i16(<16 x i8> %a, <16 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %abd = call <16 x i8> @llvm.aarch64.neon.sabd.v16i8(<16 x i8> %a, <16 x i8> %b)
  %r = zext <16 x i8> %abd to <16 x i16>
  ret <16 x i16> %r
}

; Well-formed llvm.aarch64.neon.fabd is covered by
; vmp-aarch64-neon-fabd-semantic.ll and must not stay here as a
; negative (it would virtualize, or half would become a feature miss).
; Well-formed sisd.fabd is vmp-aarch64-neon-sisd-fabd-semantic.ll.

define <vscale x 8 x i16> @unsupported_sve_sabdlb(<vscale x 16 x i8> %a, <vscale x 16 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 8 x i16> @llvm.aarch64.sve.sabdlb.nxv8i16(<vscale x 16 x i8> %a, <vscale x 16 x i8> %b)
  ret <vscale x 8 x i16> %r
}

define <vscale x 8 x i16> @unsupported_sve_sabdlt(<vscale x 16 x i8> %a, <vscale x 16 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 8 x i16> @llvm.aarch64.sve.sabdlt.nxv8i16(<vscale x 16 x i8> %a, <vscale x 16 x i8> %b)
  ret <vscale x 8 x i16> %r
}

define <vscale x 8 x i16> @unsupported_sve_uabdlb(<vscale x 16 x i8> %a, <vscale x 16 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 8 x i16> @llvm.aarch64.sve.uabdlb.nxv8i16(<vscale x 16 x i8> %a, <vscale x 16 x i8> %b)
  ret <vscale x 8 x i16> %r
}

define <8 x i16> @unsupported_fastcc(<8 x i8> %a, <8 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %abd = call fastcc <8 x i8> @llvm.aarch64.neon.sabd.v8i8(<8 x i8> %a, <8 x i8> %b)
  %r = zext <8 x i8> %abd to <8 x i16>
  ret <8 x i16> %r
}


define <8 x i8> @unsupported_musttail(<8 x i8> %a, <8 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  ; musttail must be followed by ret of the call; the zext half
  ; cannot legally follow.  This still rejects the ABDL-shaped
  ; function.
  %abd = musttail call <8 x i8> @llvm.aarch64.neon.sabd.v8i8(<8 x i8> %a, <8 x i8> %b)
  ret <8 x i8> %abd
}

define <8 x i16> @unsupported_bundle(<8 x i8> %a, <8 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %abd = call <8 x i8> @llvm.aarch64.neon.sabd.v8i8(<8 x i8> %a, <8 x i8> %b) [ "deopt"(i32 0) ]
  %r = zext <8 x i8> %abd to <8 x i16>
  ret <8 x i16> %r
}

define <8 x i16> @unsupported_noreturn(<8 x i8> %a, <8 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %abd = call <8 x i8> @llvm.aarch64.neon.sabd.v8i8(<8 x i8> %a, <8 x i8> %b) noreturn
  %r = zext <8 x i8> %abd to <8 x i16>
  ret <8 x i16> %r
}

define <8 x i16> @unsupported_returns_twice(<8 x i8> %a, <8 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %abd = call <8 x i8> @llvm.aarch64.neon.sabd.v8i8(<8 x i8> %a, <8 x i8> %b) returns_twice
  %r = zext <8 x i8> %abd to <8 x i16>
  ret <8 x i16> %r
}

define i32 @main() {
entry:
  %a8 = load volatile <8 x i8>, ptr @sink_v8i8, align 8
  %b8 = load volatile <8 x i8>, ptr @sink_v8i8, align 8
  %r0 = call <8 x i16> @protected_sabdl_v8i8(<8 x i8> %a8, <8 x i8> %b8)
  store volatile <8 x i16> %r0, ptr @sink_v8i16, align 16
  %a4 = load volatile <4 x i16>, ptr @sink_v4i16, align 8
  %b4 = load volatile <4 x i16>, ptr @sink_v4i16, align 8
  %r1 = call <4 x i32> @protected_sabdl_v4i16(<4 x i16> %a4, <4 x i16> %b4)
  store volatile <4 x i32> %r1, ptr @sink_v4i32, align 16
  %a2 = load volatile <2 x i32>, ptr @sink_v2i32, align 8
  %b2 = load volatile <2 x i32>, ptr @sink_v2i32, align 8
  %r2 = call <2 x i64> @protected_sabdl_v2i32(<2 x i32> %a2, <2 x i32> %b2)
  store volatile <2 x i64> %r2, ptr @sink_v2i64, align 16
  %r3 = call <8 x i16> @protected_uabdl_v8i8(<8 x i8> %a8, <8 x i8> %b8)
  store volatile <8 x i16> %r3, ptr @sink_v8i16, align 16
  %r4 = call <4 x i32> @protected_uabdl_v4i16(<4 x i16> %a4, <4 x i16> %b4)
  store volatile <4 x i32> %r4, ptr @sink_v4i32, align 16
  %r5 = call <2 x i64> @protected_uabdl_v2i32(<2 x i32> %a2, <2 x i32> %b2)
  store volatile <2 x i64> %r5, ptr @sink_v2i64, align 16
  ret i32 0
}

; SKIP-DAG: Skipping VMP on unsupported_v2i64: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_v4i8: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_v16i16: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_sve_sabdlb: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_sve_sabdlt: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_sve_uabdlb: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_noreturn: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_returns_twice: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_sabdl_v8i8:
; SKIP-NOT: Skipping VMP on protected_sabdl_v4i16:
; SKIP-NOT: Skipping VMP on protected_sabdl_v2i32:
; SKIP-NOT: Skipping VMP on protected_uabdl_v8i8:
; SKIP-NOT: Skipping VMP on protected_uabdl_v4i16:
; SKIP-NOT: Skipping VMP on protected_uabdl_v2i32:

; VIRT: define <8 x i16> @protected_sabdl_v8i8({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x i8> @llvm.aarch64.neon.sabd.v8i8(
; VIRT: define <4 x i32> @protected_sabdl_v4i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <2 x i64> @protected_sabdl_v2i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <8 x i16> @protected_uabdl_v8i8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x i8> @llvm.aarch64.neon.uabd.v8i8(
; VIRT: define <4 x i32> @protected_uabdl_v4i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <2 x i64> @protected_uabdl_v2i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define {{.*}} @unsupported_v2i64({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; VReg replay splits the ISel sabdl idiom into abd then ushll.
; AARCH64-ASM: {{^[[:space:]]*}}sabd{{[ \t]}}
; AARCH64-ASM: {{^[[:space:]]*}}uabd{{[ \t]}}
; AARCH64-ASM: {{^[[:space:]]*}}ushll{{[ \t]}}
; HOST: Skipping VMP: only AArch64 targets are supported
