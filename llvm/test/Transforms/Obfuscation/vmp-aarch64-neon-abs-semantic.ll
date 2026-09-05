; Restricted AArch64 NEON integer abs via CallDescriptor /
; vector VRegs:
;   llvm.aarch64.neon.abs
;     AdvSIMD_1Arg: any (match)
;     ISel custom-lowers legal integer vectors to ISD::ABS,
;     then SIMDTwoVectorBHSD ABS, baseline HasNEON:
;       <8 x i8> / <16 x i8> / <4 x i16> / <8 x i16>
;       <2 x i32> / <4 x i32> / <2 x i64>
; Clang integer vabs / vabsq.  Float vabs is llvm.fabs.
; Well-formed scalar i64 is
; vmp-aarch64-neon-scalar-abs-semantic.ll and must not stay
; here as a skip (it would virtualize).  Scalar i32 is
; ISel-fatal and stays out.
; INT_MIN stays INT_MIN (not SQABS saturate).  Must not
; rewrite to llvm.abs (different ID + is_int_min_poison
; ImmArg) or sqabs.  Exact C non-vararg.  Ordinary tail accepted and replayed as non-tail; see vmp-direct-call-tail-eligibility-semantic.ll.  No last-token gate.
; Well-formed llvm.abs is the generic integer-vector abs
; surface.  Well-formed sqabs is
; vmp-aarch64-neon-sat-absneg-semantic.ll.
; No new opcode.
;
; Host cannot select this AArch64 intrinsic; no lli.
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
declare void @ext_sret_byval(ptr sret(i32), ptr byval(i32))
declare <8 x i8> @llvm.aarch64.neon.abs.v8i8(<8 x i8>)
declare <16 x i8> @llvm.aarch64.neon.abs.v16i8(<16 x i8>)
declare <4 x i16> @llvm.aarch64.neon.abs.v4i16(<4 x i16>)
declare <8 x i16> @llvm.aarch64.neon.abs.v8i16(<8 x i16>)
declare <2 x i32> @llvm.aarch64.neon.abs.v2i32(<2 x i32>)
declare <4 x i32> @llvm.aarch64.neon.abs.v4i32(<4 x i32>)
declare <2 x i64> @llvm.aarch64.neon.abs.v2i64(<2 x i64>)
declare i32 @llvm.aarch64.neon.abs.i32(i32)
; Well-formed scalar llvm.aarch64.neon.abs.i64 is
; vmp-aarch64-neon-scalar-abs-semantic.ll and would
; virtualize here.
declare <1 x i64> @llvm.aarch64.neon.abs.v1i64(<1 x i64>)
declare <4 x i8> @llvm.aarch64.neon.abs.v4i8(<4 x i8>)
declare <4 x float> @llvm.aarch64.neon.abs.v4f32(<4 x float>)
declare <vscale x 16 x i8> @llvm.aarch64.sve.abs.nxv16i8(<vscale x 16 x i8>, <vscale x 16 x i1>, <vscale x 16 x i8>)

@sink_v8i8 = global <8 x i8> zeroinitializer, align 8
@sink_v16i8 = global <16 x i8> zeroinitializer, align 16
@sink_v4i16 = global <4 x i16> zeroinitializer, align 8
@sink_v8i16 = global <8 x i16> zeroinitializer, align 16
@sink_v2i32 = global <2 x i32> zeroinitializer, align 8
@sink_v4i32 = global <4 x i32> zeroinitializer, align 16
@sink_v2i64 = global <2 x i64> zeroinitializer, align 16

define <8 x i8> @protected_abs_v8i8(<8 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i8> @llvm.aarch64.neon.abs.v8i8(<8 x i8> %a)
  ret <8 x i8> %r
}

define <16 x i8> @protected_abs_v16i8(<16 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <16 x i8> @llvm.aarch64.neon.abs.v16i8(<16 x i8> %a)
  ret <16 x i8> %r
}

define <4 x i16> @protected_abs_v4i16(<4 x i16> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i16> @llvm.aarch64.neon.abs.v4i16(<4 x i16> %a)
  ret <4 x i16> %r
}

define <8 x i16> @protected_abs_v8i16(<8 x i16> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i16> @llvm.aarch64.neon.abs.v8i16(<8 x i16> %a)
  ret <8 x i16> %r
}

define <2 x i32> @protected_abs_v2i32(<2 x i32> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i32> @llvm.aarch64.neon.abs.v2i32(<2 x i32> %a)
  ret <2 x i32> %r
}

define <4 x i32> @protected_abs_v4i32(<4 x i32> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.abs.v4i32(<4 x i32> %a)
  ret <4 x i32> %r
}

define <2 x i64> @protected_abs_v2i64(<2 x i64> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.aarch64.neon.abs.v2i64(<2 x i64> %a)
  ret <2 x i64> %r
}

; Signed-min input: neon.abs keeps INT_MIN (not sqabs saturate).
define <8 x i8> @protected_abs_smin(<8 x i8> %unused) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i8> @llvm.aarch64.neon.abs.v8i8(<8 x i8> <i8 -128, i8 -128, i8 -1, i8 0, i8 1, i8 127, i8 -128, i8 42>)
  ret <8 x i8> %r
}

; ----- negatives: selected, not virtualized -----

define i32 @unsupported_scalar_i32(i32 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.abs.i32(i32 %a)
  ret i32 %r
}

define <1 x i64> @unsupported_v1i64(<1 x i64> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <1 x i64> @llvm.aarch64.neon.abs.v1i64(<1 x i64> %a)
  ret <1 x i64> %r
}

define <4 x i8> @unsupported_v4i8(<4 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i8> @llvm.aarch64.neon.abs.v4i8(<4 x i8> %a)
  ret <4 x i8> %r
}

define <4 x float> @unsupported_float(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.abs.v4f32(<4 x float> %a)
  ret <4 x float> %r
}

define <vscale x 16 x i8> @unsupported_sve_abs(<vscale x 16 x i8> %a, <vscale x 16 x i1> %pg) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 16 x i8> @llvm.aarch64.sve.abs.nxv16i8(<vscale x 16 x i8> %a, <vscale x 16 x i1> %pg, <vscale x 16 x i8> %a)
  ret <vscale x 16 x i8> %r
}

define <8 x i8> @unsupported_fastcc(<8 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc <8 x i8> @llvm.aarch64.neon.abs.v8i8(<8 x i8> %a)
  ret <8 x i8> %r
}


define <8 x i8> @unsupported_musttail(<8 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call <8 x i8> @llvm.aarch64.neon.abs.v8i8(<8 x i8> %a)
  ret <8 x i8> %r
}

define <8 x i8> @unsupported_bundle(<8 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i8> @llvm.aarch64.neon.abs.v8i8(<8 x i8> %a) [ "deopt"(i32 0) ]
  ret <8 x i8> %r
}

define <8 x i8> @unsupported_noreturn(<8 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i8> @llvm.aarch64.neon.abs.v8i8(<8 x i8> %a) noreturn
  ret <8 x i8> %r
}

define <8 x i8> @unsupported_returns_twice(<8 x i8> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i8> @llvm.aarch64.neon.abs.v8i8(<8 x i8> %a) returns_twice
  ret <8 x i8> %r
}

define void @unsupported_sret(ptr sret(i32) %p, ptr byval(i32) %q) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @ext_sret_byval(ptr sret(i32) %p, ptr byval(i32) %q)
  ret void
}

define i32 @main() {
entry:
  %a8 = load volatile <8 x i8>, ptr @sink_v8i8, align 8
  %r0 = call <8 x i8> @protected_abs_v8i8(<8 x i8> %a8)
  store volatile <8 x i8> %r0, ptr @sink_v8i8, align 8
  %a16 = load volatile <16 x i8>, ptr @sink_v16i8, align 16
  %r1 = call <16 x i8> @protected_abs_v16i8(<16 x i8> %a16)
  store volatile <16 x i8> %r1, ptr @sink_v16i8, align 16
  %a4h = load volatile <4 x i16>, ptr @sink_v4i16, align 8
  %r2 = call <4 x i16> @protected_abs_v4i16(<4 x i16> %a4h)
  store volatile <4 x i16> %r2, ptr @sink_v4i16, align 8
  %a8h = load volatile <8 x i16>, ptr @sink_v8i16, align 16
  %r3 = call <8 x i16> @protected_abs_v8i16(<8 x i16> %a8h)
  store volatile <8 x i16> %r3, ptr @sink_v8i16, align 16
  %a2s = load volatile <2 x i32>, ptr @sink_v2i32, align 8
  %r4 = call <2 x i32> @protected_abs_v2i32(<2 x i32> %a2s)
  store volatile <2 x i32> %r4, ptr @sink_v2i32, align 8
  %a4s = load volatile <4 x i32>, ptr @sink_v4i32, align 16
  %r5 = call <4 x i32> @protected_abs_v4i32(<4 x i32> %a4s)
  store volatile <4 x i32> %r5, ptr @sink_v4i32, align 16
  %a2d = load volatile <2 x i64>, ptr @sink_v2i64, align 16
  %r6 = call <2 x i64> @protected_abs_v2i64(<2 x i64> %a2d)
  store volatile <2 x i64> %r6, ptr @sink_v2i64, align 16
  %r7 = call <8 x i8> @protected_abs_smin(<8 x i8> %a8)
  store volatile <8 x i8> %r7, ptr @sink_v8i8, align 8
  ret i32 0
}

; SKIP-DAG: Skipping VMP on unsupported_scalar_i32: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_v1i64: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_v4i8: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_float: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_sve_abs: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_noreturn: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_returns_twice: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_sret: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_abs_v8i8:
; SKIP-NOT: Skipping VMP on protected_abs_v16i8:
; SKIP-NOT: Skipping VMP on protected_abs_v4i16:
; SKIP-NOT: Skipping VMP on protected_abs_v8i16:
; SKIP-NOT: Skipping VMP on protected_abs_v2i32:
; SKIP-NOT: Skipping VMP on protected_abs_v4i32:
; SKIP-NOT: Skipping VMP on protected_abs_v2i64:
; SKIP-NOT: Skipping VMP on protected_abs_smin:

; VIRT: define <8 x i8> @protected_abs_v8i8({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x i8> @llvm.aarch64.neon.abs.v8i8(
; VIRT: define <16 x i8> @protected_abs_v16i8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <16 x i8> @llvm.aarch64.neon.abs.v16i8(
; VIRT: define <4 x i16> @protected_abs_v4i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <8 x i16> @protected_abs_v8i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <2 x i32> @protected_abs_v2i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <4 x i32> @protected_abs_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define <2 x i64> @protected_abs_v2i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i64> @llvm.aarch64.neon.abs.v2i64(
; VIRT: define <8 x i8> @protected_abs_smin({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x i8> @llvm.aarch64.neon.abs.v8i8(
; VIRT: define {{.*}} @unsupported_scalar_i32({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; AARCH64-ASM-DAG: {{^[[:space:]]*}}abs{{[ \t]}}{{v[0-9]+}}.8b
; AARCH64-ASM-DAG: {{^[[:space:]]*}}abs{{[ \t]}}{{v[0-9]+}}.16b
; AARCH64-ASM-DAG: {{^[[:space:]]*}}abs{{[ \t]}}{{v[0-9]+}}.4h
; AARCH64-ASM-DAG: {{^[[:space:]]*}}abs{{[ \t]}}{{v[0-9]+}}.8h
; AARCH64-ASM-DAG: {{^[[:space:]]*}}abs{{[ \t]}}{{v[0-9]+}}.2s
; AARCH64-ASM-DAG: {{^[[:space:]]*}}abs{{[ \t]}}{{v[0-9]+}}.4s
; AARCH64-ASM-DAG: {{^[[:space:]]*}}abs{{[ \t]}}{{v[0-9]+}}.2d
; HOST: Skipping VMP: only AArch64 targets are supported
