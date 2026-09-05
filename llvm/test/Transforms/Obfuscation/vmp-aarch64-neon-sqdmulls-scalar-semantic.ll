; Restricted AArch64 NEON scalar saturating doubling long
; multiply via CallDescriptor / integer VRegs:
;   llvm.aarch64.neon.sqdmulls.scalar
;     non-overloaded i64(i32, i32)
;     ISel SIMDThreeScalarMixedHS SQDMULL, baseline HasNEON:
;       only i64(i32, i32)  ->  sqdmull d, s, s
;     i16 encoding has an empty pattern.
; Clang vqdmulls_s32.  Lane forms are extractelement + this ID
; (ISel SQDMULLv1i64_indexed).  Saturating 2*a*b signed to i64.
; Must not rewrite to smull, mul, or vector sqdmull.
; Exact C non-vararg.  Ordinary tail accepted and replayed as non-tail; see vmp-direct-call-tail-eligibility-semantic.ll.  No last-token gate.  No ImmediateArguments.
; Well-formed vector sqdmull is
; vmp-aarch64-neon-sqdmull-semantic.ll.
; Well-formed sqdmlal idiom is
; vmp-aarch64-neon-sqdmlal-semantic.ll.
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
declare i64 @llvm.aarch64.neon.sqdmulls.scalar(i32, i32)
declare <vscale x 4 x i32> @llvm.aarch64.sve.sqdmullb.nxv4i32(<vscale x 8 x i16>, <vscale x 8 x i16>)

@sink_i32 = global i32 0, align 4
@sink_i64 = global i64 0, align 8
@sink_v4i32 = global <4 x i32> zeroinitializer, align 16

define i64 @protected_sqdmulls_scalar(i32 %a, i32 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.aarch64.neon.sqdmulls.scalar(i32 %a, i32 %b)
  ret i64 %r
}

; Clang vqdmulls_lane is extractelement + this ID.
define i64 @protected_sqdmulls_lane(i32 %a, <4 x i32> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %b = extractelement <4 x i32> %v, i32 1
  %r = call i64 @llvm.aarch64.neon.sqdmulls.scalar(i32 %a, i32 %b)
  ret i64 %r
}

; 2*SMAX*SMAX saturates i64.  Replay the ID, not mul.
define i64 @protected_sqdmulls_sat(i32 %unused) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.aarch64.neon.sqdmulls.scalar(i32 2147483647, i32 2147483647)
  ret i64 %r
}

define i64 @protected_sqdmulls_smin(i32 %unused) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.aarch64.neon.sqdmulls.scalar(i32 -2147483648, i32 -2147483648)
  ret i64 %r
}

; ----- negatives: selected, not virtualized -----

; Well-formed llvm.aarch64.neon.sqdmull is
; vmp-aarch64-neon-sqdmull-semantic.ll and must not stay here
; with SKIP (it would virtualize).

define <vscale x 4 x i32> @unsupported_sve_sqdmullb(<vscale x 8 x i16> %a, <vscale x 8 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.aarch64.sve.sqdmullb.nxv4i32(<vscale x 8 x i16> %a, <vscale x 8 x i16> %b)
  ret <vscale x 4 x i32> %r
}

define i64 @unsupported_fastcc(i32 %a, i32 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc i64 @llvm.aarch64.neon.sqdmulls.scalar(i32 %a, i32 %b)
  ret i64 %r
}


define i64 @unsupported_musttail(i32 %a, i32 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call i64 @llvm.aarch64.neon.sqdmulls.scalar(i32 %a, i32 %b)
  ret i64 %r
}

define i64 @unsupported_bundle(i32 %a, i32 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.aarch64.neon.sqdmulls.scalar(i32 %a, i32 %b) [ "deopt"(i32 0) ]
  ret i64 %r
}

define i64 @unsupported_noreturn(i32 %a, i32 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.aarch64.neon.sqdmulls.scalar(i32 %a, i32 %b) noreturn
  ret i64 %r
}

define i64 @unsupported_returns_twice(i32 %a, i32 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.aarch64.neon.sqdmulls.scalar(i32 %a, i32 %b) returns_twice
  ret i64 %r
}

define void @unsupported_sret(ptr sret(i32) %p, ptr byval(i32) %q) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @ext_sret_byval(ptr sret(i32) %p, ptr byval(i32) %q)
  ret void
}

define i32 @main() {
entry:
  %a = load volatile i32, ptr @sink_i32, align 4
  %b = load volatile i32, ptr @sink_i32, align 4
  %r0 = call i64 @protected_sqdmulls_scalar(i32 %a, i32 %b)
  store volatile i64 %r0, ptr @sink_i64, align 8
  %v = load volatile <4 x i32>, ptr @sink_v4i32, align 16
  %r1 = call i64 @protected_sqdmulls_lane(i32 %a, <4 x i32> %v)
  store volatile i64 %r1, ptr @sink_i64, align 8
  %r2 = call i64 @protected_sqdmulls_sat(i32 %a)
  store volatile i64 %r2, ptr @sink_i64, align 8
  %r3 = call i64 @protected_sqdmulls_smin(i32 %a)
  store volatile i64 %r3, ptr @sink_i64, align 8
  ret i32 0
}

; SKIP-DAG: Skipping VMP on unsupported_sve_sqdmullb: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_noreturn: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_returns_twice: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_sret: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_sqdmulls_scalar:
; SKIP-NOT: Skipping VMP on protected_sqdmulls_lane:
; SKIP-NOT: Skipping VMP on protected_sqdmulls_sat:
; SKIP-NOT: Skipping VMP on protected_sqdmulls_smin:

; VIRT: define i64 @protected_sqdmulls_scalar({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.aarch64.neon.sqdmulls.scalar(
; VIRT: define i64 @protected_sqdmulls_lane({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.aarch64.neon.sqdmulls.scalar(
; VIRT: define i64 @protected_sqdmulls_sat({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.aarch64.neon.sqdmulls.scalar(
; VIRT: define i64 @protected_sqdmulls_smin({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.aarch64.neon.sqdmulls.scalar(
; VIRT: define {{.*}} @unsupported_sve_sqdmullb({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; AARCH64-ASM-DAG: {{^[[:space:]]*}}sqdmull{{[ \t]}}{{d[0-9]+}}
; HOST: Skipping VMP: only AArch64 targets are supported
