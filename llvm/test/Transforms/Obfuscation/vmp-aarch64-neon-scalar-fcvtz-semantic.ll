; Restricted AArch64 scalar toward-zero saturating float-to-int
; via CallDescriptor (float in, integer out):
;   llvm.aarch64.neon.fcvtzs / fcvtzu
;     AdvSIMD_FPToIntRounding: anyint (anyfloat)
;     ISel FPToIntegerIntPats:
;       i32/i64 from f32/f64 (baseline)
;       i32/i64 from f16 (HasFullFP16)
; Asm is scalar FP fcvtzs w/x, s/d/h.  Clang vcvts_s32_f32 /
; vcvtd_s64_f64 / vcvth_s32_f16.  Must not lower to
; fptosi/fptoui (FCVTZS saturates OOR and maps NaN to 0;
; fptosi is poison).  i16(f16) has no scalar Pat.  Vector
; fcvtz is vmp-aarch64-neon-fcvtz-semantic.ll and must not
; stay here as a well-formed skip.  Last-token +fullfp16
; required for half; f32/f64 need no extra token.  +fp16fml
; does not count.  Command-line -mattr never consulted for
; eligibility.  Exact C non-vararg.  Ordinary tail accepted and replayed as non-tail; see vmp-direct-call-tail-eligibility-semantic.ll.  No FMF (integer result).  No new
; opcode.
;
; Host cannot select these AArch64 intrinsics; no lli.
; FileCheck + AArch64 llc/readobj/asm (-mattr=+fullfp16).
; O0/O2 x 97/7.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.ll -o %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+fullfp16 -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+fullfp16 %t.o0.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.ll -o %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+fullfp16 -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+fullfp16 %t.o2.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.s7.ll -o %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+fullfp16 -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+fullfp16 %t.o0.s7.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.s7.ll -o %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+fullfp16 -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+fullfp16 %t.o2.s7.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %s | opt -S -verify-each -aesSeed=97 -passes='default<O0>' - 2>&1 | FileCheck %s --check-prefix=HOST

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare void @ext_sret_byval(ptr sret(i32), ptr byval(i32))
declare i32 @llvm.aarch64.neon.fcvtzs.i32.f32(float)
declare i32 @llvm.aarch64.neon.fcvtzu.i32.f32(float)
declare i64 @llvm.aarch64.neon.fcvtzs.i64.f64(double)
declare i32 @llvm.aarch64.neon.fcvtzs.i32.f64(double)
declare i64 @llvm.aarch64.neon.fcvtzs.i64.f32(float)
declare i32 @llvm.aarch64.neon.fcvtzs.i32.f16(half)
declare i64 @llvm.aarch64.neon.fcvtzu.i64.f16(half)
declare i16 @llvm.aarch64.neon.fcvtzs.i16.f16(half)
declare <1 x i64> @llvm.aarch64.neon.fcvtzu.v1i64.v1f64(<1 x double>)
declare <vscale x 4 x i32> @llvm.aarch64.sve.fcvtzs.nxv4i32.nxv4f32(<vscale x 4 x i32>, <vscale x 4 x i1>, <vscale x 4 x float>)

@sink_f32 = global float 0.0, align 4
@sink_f64 = global double 0.0, align 8
@sink_f16 = global half 0xH0000, align 2
@sink_i32 = global i32 0, align 4
@sink_i64 = global i64 0, align 8

define i32 @protected_fcvtzs_f32(float %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.fcvtzs.i32.f32(float %a)
  ret i32 %r
}

define i32 @protected_fcvtzu_f32(float %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.fcvtzu.i32.f32(float %a)
  ret i32 %r
}

define i64 @protected_fcvtzs_f64(double %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.aarch64.neon.fcvtzs.i64.f64(double %a)
  ret i64 %r
}

define i32 @protected_fcvtzs_f64_i32(double %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.fcvtzs.i32.f64(double %a)
  ret i32 %r
}

define i64 @protected_fcvtzs_f32_i64(float %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.aarch64.neon.fcvtzs.i64.f32(float %a)
  ret i64 %r
}

define i32 @protected_fcvtzs_f16(half %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.fcvtzs.i32.f16(half %a)
  ret i32 %r
}

define i64 @protected_fcvtzu_last_fullfp16(half %a) noinline optnone "target-features"="+neon,+fp16fml,+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.aarch64.neon.fcvtzu.i64.f16(half %a)
  ret i64 %r
}

; +Inf stays live fcvtzs (saturates; not folded).
define i32 @protected_fcvtzs_inf() noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.fcvtzs.i32.f32(float 0x7FF0000000000000)
  ret i32 %r
}

; ----- negatives: selected, not virtualized -----

define i16 @unsupported_i16_f16(half %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i16 @llvm.aarch64.neon.fcvtzs.i16.f16(half %a)
  ret i16 %r
}

define i32 @unsupported_f16_no_fullfp16(half %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.fcvtzs.i32.f16(half %a)
  ret i32 %r
}

define i32 @unsupported_fullfp16_disabled(half %a) noinline optnone "target-features"="+fullfp16,-fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.fcvtzs.i32.f16(half %a)
  ret i32 %r
}

define i32 @unsupported_fp16fml_only(half %a) noinline optnone "target-features"="+fp16fml" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.fcvtzs.i32.f16(half %a)
  ret i32 %r
}

define <1 x i64> @unsupported_v1f64(<1 x double> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <1 x i64> @llvm.aarch64.neon.fcvtzu.v1i64.v1f64(<1 x double> %a)
  ret <1 x i64> %r
}

define <vscale x 4 x i32> @unsupported_sve(<vscale x 4 x i32> %a, <vscale x 4 x i1> %pg, <vscale x 4 x float> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.aarch64.sve.fcvtzs.nxv4i32.nxv4f32(<vscale x 4 x i32> %a, <vscale x 4 x i1> %pg, <vscale x 4 x float> %b)
  ret <vscale x 4 x i32> %r
}

define i32 @unsupported_fastcc(float %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc i32 @llvm.aarch64.neon.fcvtzs.i32.f32(float %a)
  ret i32 %r
}


define i32 @unsupported_musttail(float %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call i32 @llvm.aarch64.neon.fcvtzs.i32.f32(float %a)
  ret i32 %r
}

define i32 @unsupported_bundle(float %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.fcvtzs.i32.f32(float %a) [ "deopt"(i32 0) ]
  ret i32 %r
}

define i32 @unsupported_noreturn(float %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.fcvtzs.i32.f32(float %a) noreturn
  ret i32 %r
}

define i32 @unsupported_returns_twice(float %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.fcvtzs.i32.f32(float %a) returns_twice
  ret i32 %r
}

define void @unsupported_sret(ptr sret(i32) %p, ptr byval(i32) %q) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @ext_sret_byval(ptr sret(i32) %p, ptr byval(i32) %q)
  ret void
}

define i32 @main() {
entry:
  %a = load volatile float, ptr @sink_f32, align 4
  %r0 = call i32 @protected_fcvtzs_f32(float %a)
  store volatile i32 %r0, ptr @sink_i32, align 4
  %r1 = call i32 @protected_fcvtzu_f32(float %a)
  store volatile i32 %r1, ptr @sink_i32, align 4
  %d = load volatile double, ptr @sink_f64, align 8
  %r2 = call i64 @protected_fcvtzs_f64(double %d)
  store volatile i64 %r2, ptr @sink_i64, align 8
  %r3 = call i32 @protected_fcvtzs_f64_i32(double %d)
  store volatile i32 %r3, ptr @sink_i32, align 4
  %r4 = call i64 @protected_fcvtzs_f32_i64(float %a)
  store volatile i64 %r4, ptr @sink_i64, align 8
  %h = load volatile half, ptr @sink_f16, align 2
  %r5 = call i32 @protected_fcvtzs_f16(half %h)
  store volatile i32 %r5, ptr @sink_i32, align 4
  %r6 = call i64 @protected_fcvtzu_last_fullfp16(half %h)
  store volatile i64 %r6, ptr @sink_i64, align 8
  %r7 = call i32 @protected_fcvtzs_inf()
  store volatile i32 %r7, ptr @sink_i32, align 4
  ret i32 0
}

; SKIP-DAG: Skipping VMP on unsupported_i16_f16: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_f16_no_fullfp16: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_fullfp16_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_fp16fml_only: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_v1f64: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_sve: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_noreturn: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_returns_twice: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_sret: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_fcvtzs_f32:
; SKIP-NOT: Skipping VMP on protected_fcvtzu_f32:
; SKIP-NOT: Skipping VMP on protected_fcvtzs_f64:
; SKIP-NOT: Skipping VMP on protected_fcvtzs_f64_i32:
; SKIP-NOT: Skipping VMP on protected_fcvtzs_f32_i64:
; SKIP-NOT: Skipping VMP on protected_fcvtzs_f16:
; SKIP-NOT: Skipping VMP on protected_fcvtzu_last_fullfp16:
; SKIP-NOT: Skipping VMP on protected_fcvtzs_inf:

; VIRT: define i32 @protected_fcvtzs_f32({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.neon.fcvtzs.i32.f32(
; VIRT: define i32 @protected_fcvtzu_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.neon.fcvtzu.i32.f32(
; VIRT: define i64 @protected_fcvtzs_f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.aarch64.neon.fcvtzs.i64.f64(
; VIRT: define i32 @protected_fcvtzs_f64_i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define i64 @protected_fcvtzs_f32_i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define i32 @protected_fcvtzs_f16({{.*}} #[[PROTH:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.neon.fcvtzs.i32.f16(
; VIRT: define i64 @protected_fcvtzu_last_fullfp16({{.*}} #[[PROTL:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: define i32 @protected_fcvtzs_inf({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.neon.fcvtzs.i32.f32(
; VIRT: define {{.*}} @unsupported_i16_f16({{.*}} #[[UNSUPH:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_f16_no_fullfp16({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT: attributes #[[PROTH]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT: attributes #[[PROTL]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; AARCH64-ASM-DAG: {{^[[:space:]]*}}fcvtzs{{[ \t]}}{{[wx]}}
; AARCH64-ASM-DAG: {{^[[:space:]]*}}fcvtzu{{[ \t]}}{{[wx]}}
; HOST: Skipping VMP: only AArch64 targets are supported
