; Restricted AArch64 NEON half/single convert via CallDescriptor /
; vector VRegs:
;   llvm.aarch64.neon.vcvtfp2hf
;     v4i16(<4 x float>)  ISel FCVTNv4i16  -> fcvtn v.4h, v.4s
;   llvm.aarch64.neon.vcvthf2fp
;     v4f32(<4 x i16>)    ISel FCVTLv4i16  -> fcvtl v.4s, v.4h
; Clang vcvt_f16_f32 / vcvt_f32_f16.  Result of fp2hf is i16 bits
; (historical half packing), not <4 x half>.  High-half fcvtn2 /
; fcvtl2 is concat / extract of this ID, not a second IR ID.
; Must not rewrite to fptrunc / fpext.  No +fullfp16 (i16, not
; half).  Exact C non-vararg.  Ordinary tail accepted and replayed as non-tail; see vmp-direct-call-tail-eligibility-semantic.ll.  FMF on vcvthf2fp rejected by the float-call
; FMF gate.  No last-token gate.  No ImmediateArguments.
; Well-formed fcvtxn is vmp-aarch64-neon-fcvtxn-semantic.ll.
; No new opcode.
;
; Host cannot select these AArch64 intrinsics; no lli.
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
declare <4 x i16> @llvm.aarch64.neon.vcvtfp2hf(<4 x float>)
declare <4 x float> @llvm.aarch64.neon.vcvthf2fp(<4 x i16>)
declare <4 x float> @llvm.arm.neon.vcvthf2fp(<4 x i16>)
declare <vscale x 4 x float> @llvm.aarch64.sve.fcvt.f32f16(<vscale x 4 x float>, <vscale x 4 x i1>, <vscale x 8 x half>)

@sink_v4f32 = global <4 x float> zeroinitializer, align 16
@sink_v4i16 = global <4 x i16> zeroinitializer, align 8
@sink_v8i16 = global <8 x i16> zeroinitializer, align 16

define <4 x i16> @protected_vcvtfp2hf(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i16> @llvm.aarch64.neon.vcvtfp2hf(<4 x float> %a)
  ret <4 x i16> %r
}

define <4 x float> @protected_vcvthf2fp(<4 x i16> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.vcvthf2fp(<4 x i16> %a)
  ret <4 x float> %r
}

; High-half fcvtn2 is concat of the same ID, not a second IR ID.
define <8 x i16> @protected_vcvtfp2hf_high(<4 x i16> %lo, <4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %hi = call <4 x i16> @llvm.aarch64.neon.vcvtfp2hf(<4 x float> %a)
  %r = shufflevector <4 x i16> %lo, <4 x i16> %hi, <8 x i32> <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7>
  ret <8 x i16> %r
}

; High-half fcvtl2 is extract of v8i16 then the same ID.
define <4 x float> @protected_vcvthf2fp_high(<8 x i16> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %hi = shufflevector <8 x i16> %a, <8 x i16> poison, <4 x i32> <i32 4, i32 5, i32 6, i32 7>
  %r = call <4 x float> @llvm.aarch64.neon.vcvthf2fp(<4 x i16> %hi)
  ret <4 x float> %r
}

; ----- negatives: selected, not virtualized -----

define <4 x float> @unsupported_arm(<4 x i16> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.arm.neon.vcvthf2fp(<4 x i16> %a)
  ret <4 x float> %r
}

define <vscale x 4 x float> @unsupported_sve(<vscale x 4 x float> %inactive, <vscale x 4 x i1> %pg, <vscale x 8 x half> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x float> @llvm.aarch64.sve.fcvt.f32f16(<vscale x 4 x float> %inactive, <vscale x 4 x i1> %pg, <vscale x 8 x half> %a)
  ret <vscale x 4 x float> %r
}

define <4 x float> @unsupported_fmf(<4 x i16> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call nnan <4 x float> @llvm.aarch64.neon.vcvthf2fp(<4 x i16> %a)
  ret <4 x float> %r
}

define <4 x i16> @unsupported_fastcc(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc <4 x i16> @llvm.aarch64.neon.vcvtfp2hf(<4 x float> %a)
  ret <4 x i16> %r
}


define <4 x i16> @unsupported_musttail(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call <4 x i16> @llvm.aarch64.neon.vcvtfp2hf(<4 x float> %a)
  ret <4 x i16> %r
}

define <4 x i16> @unsupported_bundle(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i16> @llvm.aarch64.neon.vcvtfp2hf(<4 x float> %a) [ "deopt"(i32 0) ]
  ret <4 x i16> %r
}

define <4 x i16> @unsupported_noreturn(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i16> @llvm.aarch64.neon.vcvtfp2hf(<4 x float> %a) noreturn
  ret <4 x i16> %r
}

define <4 x i16> @unsupported_returns_twice(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i16> @llvm.aarch64.neon.vcvtfp2hf(<4 x float> %a) returns_twice
  ret <4 x i16> %r
}

define void @unsupported_sret(ptr sret(i32) %p, ptr byval(i32) %q) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @ext_sret_byval(ptr sret(i32) %p, ptr byval(i32) %q)
  ret void
}

define i32 @main() {
entry:
  %a = load volatile <4 x float>, ptr @sink_v4f32, align 16
  %r0 = call <4 x i16> @protected_vcvtfp2hf(<4 x float> %a)
  store volatile <4 x i16> %r0, ptr @sink_v4i16, align 8
  %b = load volatile <4 x i16>, ptr @sink_v4i16, align 8
  %r1 = call <4 x float> @protected_vcvthf2fp(<4 x i16> %b)
  store volatile <4 x float> %r1, ptr @sink_v4f32, align 16
  %r2 = call <8 x i16> @protected_vcvtfp2hf_high(<4 x i16> %b, <4 x float> %a)
  store volatile <8 x i16> %r2, ptr @sink_v8i16, align 16
  %w = load volatile <8 x i16>, ptr @sink_v8i16, align 16
  %r3 = call <4 x float> @protected_vcvthf2fp_high(<8 x i16> %w)
  store volatile <4 x float> %r3, ptr @sink_v4f32, align 16
  ret i32 0
}

; SKIP-DAG: Skipping VMP on unsupported_arm: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_sve: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_fmf: unsupported float call instruction
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_noreturn: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_returns_twice: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_sret: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_vcvtfp2hf:
; SKIP-NOT: Skipping VMP on protected_vcvthf2fp:
; SKIP-NOT: Skipping VMP on protected_vcvtfp2hf_high:
; SKIP-NOT: Skipping VMP on protected_vcvthf2fp_high:

; VIRT: define <4 x i16> @protected_vcvtfp2hf({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i16> @llvm.aarch64.neon.vcvtfp2hf(
; VIRT: define <4 x float> @protected_vcvthf2fp({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x float> @llvm.aarch64.neon.vcvthf2fp(
; VIRT: define <8 x i16> @protected_vcvtfp2hf_high({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i16> @llvm.aarch64.neon.vcvtfp2hf(
; VIRT: define <4 x float> @protected_vcvthf2fp_high({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x float> @llvm.aarch64.neon.vcvthf2fp(
; VIRT: define {{.*}} @unsupported_arm({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; AARCH64-ASM-DAG: {{^[[:space:]]*}}fcvtn{{[ \t]}}
; AARCH64-ASM-DAG: {{^[[:space:]]*}}fcvtl{{[ \t]}}
; HOST: Skipping VMP: only AArch64 targets are supported
