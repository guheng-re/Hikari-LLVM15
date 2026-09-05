; Restricted AArch64 NEON Int8 matrix-multiply-accumulate via
; CallDescriptor / vector VRegs:
;   llvm.aarch64.neon.smmla / ummla / usmmla
;     AdvSIMD_MatMul: acc (acc, bytes, bytes)
;     ISel SIMDThreeSameVectorMatMul under HasMatMulInt8:
;       <4 x i32>(<4 x i32>, <16 x i8>, <16 x i8>)
;       SMMLA / UMMLA / USMMLA  (Rd.4s, Rn.16b, Rm.16b)
; Last-token function +i8mm required; missing or final -i8mm,
; +dotprod, and +crypto do not count.  Command-line -mattr is
; never consulted.  Exact C non-vararg.  Ordinary tail accepted and replayed as non-tail; see vmp-direct-call-tail-eligibility-semantic.ll.  sdot / udot / SVE stay out.
; Well-formed usdot is vmp-aarch64-neon-usdot-semantic.ll.
; Well-formed +bf16 bfdot/bfmmla is
; vmp-aarch64-neon-bf16-semantic.ll.  No new opcode.  Only the
; 128-bit ISel layout.
;
; Host cannot select these AArch64 intrinsics; no lli.
; FileCheck + AArch64 llc/readobj/asm (-mattr=+i8mm).  O0/O2 x 97/7.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.ll -o %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+i8mm -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+i8mm %t.o0.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.ll -o %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+i8mm -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+i8mm %t.o2.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.s7.ll -o %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+i8mm -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+i8mm %t.o0.s7.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.s7.ll -o %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+i8mm -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+i8mm %t.o2.s7.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %s | opt -S -verify-each -aesSeed=97 -passes='default<O0>' - 2>&1 | FileCheck %s --check-prefix=HOST

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare <4 x i32> @llvm.aarch64.neon.smmla.v4i32.v16i8(<4 x i32>, <16 x i8>, <16 x i8>)
declare <4 x i32> @llvm.aarch64.neon.ummla.v4i32.v16i8(<4 x i32>, <16 x i8>, <16 x i8>)
declare <4 x i32> @llvm.aarch64.neon.usmmla.v4i32.v16i8(<4 x i32>, <16 x i8>, <16 x i8>)
declare <2 x i32> @llvm.aarch64.neon.smmla.v2i32.v8i8(<2 x i32>, <8 x i8>, <8 x i8>)
declare <4 x float> @llvm.aarch64.neon.bfdot.v4f32.v8bf16(<4 x float>, <8 x bfloat>, <8 x bfloat>)
declare <4 x float> @llvm.aarch64.neon.bfmmla(<4 x float>, <8 x bfloat>, <8 x bfloat>)
declare <4 x half> @llvm.aarch64.neon.smmla.v4f16.v8f16(<4 x half>, <8 x half>, <8 x half>)
declare <vscale x 4 x i32> @llvm.aarch64.sve.smmla.nxv4i32.nxv16i8(<vscale x 4 x i32>, <vscale x 16 x i8>, <vscale x 16 x i8>)

@sink_v4i32 = global <4 x i32> zeroinitializer, align 16
@sink_v16i8 = global <16 x i8> zeroinitializer, align 16

define <4 x i32> @protected_smmla(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b) noinline optnone "target-features"="+i8mm" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.smmla.v4i32.v16i8(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b)
  ret <4 x i32> %r
}

define <4 x i32> @protected_ummla(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b) noinline optnone "target-features"="+i8mm" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.ummla.v4i32.v16i8(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b)
  ret <4 x i32> %r
}

define <4 x i32> @protected_usmmla(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b) noinline optnone "target-features"="+i8mm" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.usmmla.v4i32.v16i8(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b)
  ret <4 x i32> %r
}

define <4 x i32> @protected_smmla_last_i8mm(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b) noinline optnone "target-features"="+neon,+crc,+i8mm" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.smmla.v4i32.v16i8(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b)
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_no_i8mm(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.smmla.v4i32.v16i8(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b)
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_i8mm_disabled(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b) noinline optnone "target-features"="+i8mm,-i8mm" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.smmla.v4i32.v16i8(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b)
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_dotprod_only(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b) noinline optnone "target-features"="+dotprod" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.smmla.v4i32.v16i8(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b)
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_f32mm_only(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b) noinline optnone "target-features"="+f32mm" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.smmla.v4i32.v16i8(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b)
  ret <4 x i32> %r
}

; Well-formed llvm.aarch64.neon.sdot / udot is covered by
; vmp-aarch64-neon-dot-semantic.ll and must not stay here with
; last-token +dotprod (it would virtualize).

; Well-formed llvm.aarch64.neon.usdot is
; vmp-aarch64-neon-usdot-semantic.ll and must not stay here with
; last-token +i8mm (it would virtualize).

; Well-formed llvm.aarch64.neon.bfdot / bfmmla with last-token +bf16
; is vmp-aarch64-neon-bf16-semantic.ll.  +i8mm-only bfloat formals
; still fail first as unsupported argument type.
define <4 x float> @unsupported_bfdot(<4 x float> %acc, <8 x bfloat> %a, <8 x bfloat> %b) noinline optnone "target-features"="+i8mm" {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.bfdot.v4f32.v8bf16(<4 x float> %acc, <8 x bfloat> %a, <8 x bfloat> %b)
  ret <4 x float> %r
}

define <4 x float> @unsupported_bfmmla(<4 x float> %acc, <8 x bfloat> %a, <8 x bfloat> %b) noinline optnone "target-features"="+i8mm" {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.bfmmla(<4 x float> %acc, <8 x bfloat> %a, <8 x bfloat> %b)
  ret <4 x float> %r
}

define <4 x half> @unsupported_half(<4 x half> %acc, <8 x half> %a, <8 x half> %b) noinline optnone "target-features"="+i8mm" {
entry:
  call void @hikari_vmp()
  %r = call <4 x half> @llvm.aarch64.neon.smmla.v4f16.v8f16(<4 x half> %acc, <8 x half> %a, <8 x half> %b)
  ret <4 x half> %r
}

define <2 x i32> @unsupported_v8i8(<2 x i32> %acc, <8 x i8> %a, <8 x i8> %b) noinline optnone "target-features"="+i8mm" {
entry:
  call void @hikari_vmp()
  %r = call <2 x i32> @llvm.aarch64.neon.smmla.v2i32.v8i8(<2 x i32> %acc, <8 x i8> %a, <8 x i8> %b)
  ret <2 x i32> %r
}

define <vscale x 4 x i32> @unsupported_sve_smmla(<vscale x 4 x i32> %acc, <vscale x 16 x i8> %a, <vscale x 16 x i8> %b) noinline optnone "target-features"="+i8mm" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.aarch64.sve.smmla.nxv4i32.nxv16i8(<vscale x 4 x i32> %acc, <vscale x 16 x i8> %a, <vscale x 16 x i8> %b)
  ret <vscale x 4 x i32> %r
}

define <4 x i32> @unsupported_fastcc(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b) noinline optnone "target-features"="+i8mm" {
entry:
  call void @hikari_vmp()
  %r = call fastcc <4 x i32> @llvm.aarch64.neon.smmla.v4i32.v16i8(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b)
  ret <4 x i32> %r
}


define <4 x i32> @unsupported_musttail(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b) noinline optnone "target-features"="+i8mm" {
entry:
  call void @hikari_vmp()
  %r = musttail call <4 x i32> @llvm.aarch64.neon.smmla.v4i32.v16i8(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b)
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_bundle(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b) noinline optnone "target-features"="+i8mm" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.smmla.v4i32.v16i8(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b) [ "deopt"(i32 0) ]
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_noreturn(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b) noinline optnone "target-features"="+i8mm" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.smmla.v4i32.v16i8(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b) noreturn
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_returns_twice(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b) noinline optnone "target-features"="+i8mm" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.smmla.v4i32.v16i8(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b) returns_twice
  ret <4 x i32> %r
}

define i32 @main() {
entry:
  %acc = load volatile <4 x i32>, ptr @sink_v4i32, align 16
  %a = load volatile <16 x i8>, ptr @sink_v16i8, align 16
  %b = load volatile <16 x i8>, ptr @sink_v16i8, align 16
  %r0 = call <4 x i32> @protected_smmla(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b)
  store volatile <4 x i32> %r0, ptr @sink_v4i32, align 16
  %r1 = call <4 x i32> @protected_ummla(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b)
  store volatile <4 x i32> %r1, ptr @sink_v4i32, align 16
  %r2 = call <4 x i32> @protected_usmmla(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b)
  store volatile <4 x i32> %r2, ptr @sink_v4i32, align 16
  %r3 = call <4 x i32> @protected_smmla_last_i8mm(<4 x i32> %acc, <16 x i8> %a, <16 x i8> %b)
  store volatile <4 x i32> %r3, ptr @sink_v4i32, align 16
  ret i32 0
}

; SKIP-DAG: Skipping VMP on unsupported_no_i8mm: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_i8mm_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_dotprod_only: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_f32mm_only: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_bfdot: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_bfmmla: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_half: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_v8i8: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_sve_smmla: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_noreturn: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_returns_twice: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_smmla:
; SKIP-NOT: Skipping VMP on protected_ummla:
; SKIP-NOT: Skipping VMP on protected_usmmla:
; SKIP-NOT: Skipping VMP on protected_smmla_last_i8mm:

; VIRT: define <4 x i32> @protected_smmla({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.aarch64.neon.smmla.v4i32.v16i8(
; VIRT: define <4 x i32> @protected_ummla({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.aarch64.neon.ummla.v4i32.v16i8(
; VIRT: define <4 x i32> @protected_usmmla({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.aarch64.neon.usmmla.v4i32.v16i8(
; VIRT: define <4 x i32> @protected_smmla_last_i8mm({{.*}} #[[LAST:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.aarch64.neon.smmla.v4i32.v16i8(
; VIRT: define {{.*}} @unsupported_no_i8mm({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT: attributes #[[LAST]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; AARCH64-ASM: {{^[[:space:]]*}}smmla{{[ \t]}}
; AARCH64-ASM: {{^[[:space:]]*}}ummla{{[ \t]}}
; AARCH64-ASM: {{^[[:space:]]*}}usmmla{{[ \t]}}
; HOST: Skipping VMP: only AArch64 targets are supported
