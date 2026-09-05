; Restricted AArch64 scalar FACGE/FACGT via CallDescriptor
; (scalar float VRegs in, scalar integer VRegs out):
;   llvm.aarch64.neon.facge / facgt
;     AdvSIMD_2Arg_FloatCompare: anyint (anyfloat, match)
;     ISel SIMDThreeScalarFPCmp, baseline HasNEON:
;       i32(float) / i64(double)
;     plus HasFullFP16:
;       i32(half)  FACGE16/FACGT16 INSERT_SUBREG
; Clang vcages_f32 / vcaged_f64 / vcageh_f16 (half truncates
; the i32 mask to i16 after this ID).  vcale/vcalt swap
; operands.  Must not lower to fabs+fcmp: FACGE/FACGT raise
; Invalid on sNaN; ARM FABS does not.  |+0|==|-0|.  qNaN is
; unordered-false (zero).  Result is an all-ones / zero integer
; of the float's bit width (i32 for half), not i1.
; Vector facge is vmp-aarch64-neon-facge-facgt-semantic.ll and
; must not stay here as a well-formed skip.  v1f64 stays out.
; Last-token +fullfp16 required for half; f32/f64 need no extra
; token.  +fp16fml does not count.  FastMathFlags cannot attach
; (integer result).  Command-line -mattr never consulted.
; Exact C non-vararg.  Ordinary tail accepted and replayed as non-tail; see vmp-direct-call-tail-eligibility-semantic.ll.  No new opcode.
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
declare i32 @llvm.aarch64.neon.facge.i32.f32(float, float)
declare i64 @llvm.aarch64.neon.facgt.i64.f64(double, double)
declare i32 @llvm.aarch64.neon.facge.i32.f16(half, half)
declare i32 @llvm.aarch64.neon.facgt.i32.f16(half, half)
declare i16 @llvm.aarch64.neon.facge.i16.f16(half, half)
declare <1 x i64> @llvm.aarch64.neon.facge.v1i64.v1f64(<1 x double>, <1 x double>)
declare i32 @llvm.aarch64.neon.facge.i32.bf16(bfloat, bfloat)
declare <vscale x 4 x i1> @llvm.aarch64.sve.facge.nxv4f32(<vscale x 4 x i1>, <vscale x 4 x float>, <vscale x 4 x float>)

@sink_f32 = global float 0.000000e+00, align 4
@sink_f64 = global double 0.000000e+00, align 8
@sink_f16 = global half 0xH0000, align 2
@sink_i32 = global i32 0, align 4
@sink_i64 = global i64 0, align 8

define i32 @protected_facge_f32(float %a, float %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.facge.i32.f32(float %a, float %b)
  ret i32 %r
}

define i64 @protected_facgt_f64(double %a, double %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.aarch64.neon.facgt.i64.f64(double %a, double %b)
  ret i64 %r
}

define i32 @protected_facge_f16(half %a, half %b) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.facge.i32.f16(half %a, half %b)
  ret i32 %r
}

define i32 @protected_facgt_last_fullfp16(half %a, half %b) noinline optnone "target-features"="+neon,+fp16fml,+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.facgt.i32.f16(half %a, half %b)
  ret i32 %r
}

; clang vcale is operand-swapped facge.
define i32 @protected_vcale_swap(float %a, float %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.facge.i32.f32(float %b, float %a)
  ret i32 %r
}

; ----- negatives: selected, not virtualized -----

define i16 @unsupported_i16_f16(half %a, half %b) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i16 @llvm.aarch64.neon.facge.i16.f16(half %a, half %b)
  ret i16 %r
}

define i32 @unsupported_f16_no_fullfp16(half %a, half %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.facge.i32.f16(half %a, half %b)
  ret i32 %r
}

define i32 @unsupported_fullfp16_disabled(half %a, half %b) noinline optnone "target-features"="+fullfp16,-fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.facge.i32.f16(half %a, half %b)
  ret i32 %r
}

define i32 @unsupported_fp16fml_only(half %a, half %b) noinline optnone "target-features"="+fp16fml" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.facgt.i32.f16(half %a, half %b)
  ret i32 %r
}

define <1 x i64> @unsupported_v1f64(<1 x double> %a, <1 x double> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <1 x i64> @llvm.aarch64.neon.facge.v1i64.v1f64(<1 x double> %a, <1 x double> %b)
  ret <1 x i64> %r
}

define i32 @unsupported_bfloat(bfloat %a, bfloat %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.facge.i32.bf16(bfloat %a, bfloat %b)
  ret i32 %r
}

define <vscale x 4 x i1> @unsupported_sve(<vscale x 4 x i1> %pg, <vscale x 4 x float> %a, <vscale x 4 x float> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i1> @llvm.aarch64.sve.facge.nxv4f32(<vscale x 4 x i1> %pg, <vscale x 4 x float> %a, <vscale x 4 x float> %b)
  ret <vscale x 4 x i1> %r
}

define i32 @unsupported_fastcc(float %a, float %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc i32 @llvm.aarch64.neon.facge.i32.f32(float %a, float %b)
  ret i32 %r
}


define i32 @unsupported_musttail(float %a, float %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call i32 @llvm.aarch64.neon.facge.i32.f32(float %a, float %b)
  ret i32 %r
}

define i32 @unsupported_bundle(float %a, float %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.facge.i32.f32(float %a, float %b) [ "deopt"(i32 0) ]
  ret i32 %r
}

define i32 @unsupported_noreturn(float %a, float %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.facge.i32.f32(float %a, float %b) noreturn
  ret i32 %r
}

define i32 @unsupported_returns_twice(float %a, float %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.facge.i32.f32(float %a, float %b) returns_twice
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
  %s0 = load volatile float, ptr @sink_f32, align 4
  %s1 = load volatile float, ptr @sink_f32, align 4
  %r0 = call i32 @protected_facge_f32(float %s0, float %s1)
  store volatile i32 %r0, ptr @sink_i32, align 4
  %d0 = load volatile double, ptr @sink_f64, align 8
  %d1 = load volatile double, ptr @sink_f64, align 8
  %r1 = call i64 @protected_facgt_f64(double %d0, double %d1)
  store volatile i64 %r1, ptr @sink_i64, align 8
  %h0 = load volatile half, ptr @sink_f16, align 2
  %h1 = load volatile half, ptr @sink_f16, align 2
  %r2 = call i32 @protected_facge_f16(half %h0, half %h1)
  store volatile i32 %r2, ptr @sink_i32, align 4
  %r3 = call i32 @protected_facgt_last_fullfp16(half %h0, half %h1)
  store volatile i32 %r3, ptr @sink_i32, align 4
  %r4 = call i32 @protected_vcale_swap(float %s0, float %s1)
  store volatile i32 %r4, ptr @sink_i32, align 4
  ret i32 0
}

; SKIP-DAG: Skipping VMP on unsupported_i16_f16: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_f16_no_fullfp16: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_fullfp16_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_fp16fml_only: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_v1f64: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_bfloat: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_sve: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_noreturn: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_returns_twice: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_sret: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_facge_f32:
; SKIP-NOT: Skipping VMP on protected_facgt_f64:
; SKIP-NOT: Skipping VMP on protected_facge_f16:
; SKIP-NOT: Skipping VMP on protected_facgt_last_fullfp16:
; SKIP-NOT: Skipping VMP on protected_vcale_swap:

; VIRT: define i32 @protected_facge_f32({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.neon.facge.i32.f32(
; VIRT: define i64 @protected_facgt_f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.aarch64.neon.facgt.i64.f64(
; VIRT: define i32 @protected_facge_f16({{.*}} #[[PROTH:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.neon.facge.i32.f16(
; VIRT: define i32 @protected_facgt_last_fullfp16({{.*}} #[[LAST:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.neon.facgt.i32.f16(
; VIRT: define i32 @protected_vcale_swap({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.neon.facge.i32.f32(
; VIRT: define {{.*}} @unsupported_f16_no_fullfp16({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT: attributes #[[PROTH]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT: attributes #[[LAST]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; AARCH64-ASM-DAG: {{^[[:space:]]*}}facge{{[ \t]}}{{s[0-9]+}}
; AARCH64-ASM-DAG: {{^[[:space:]]*}}facgt{{[ \t]}}{{d[0-9]+}}
; AARCH64-ASM-DAG: {{^[[:space:]]*}}facge{{[ \t]}}{{h[0-9]+}}
; AARCH64-ASM-DAG: {{^[[:space:]]*}}facgt{{[ \t]}}{{h[0-9]+}}
; HOST: Skipping VMP: only AArch64 targets are supported
