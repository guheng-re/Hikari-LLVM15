; Restricted AArch64 NEON scalar saturating narrow via
; CallDescriptor / integer VRegs:
;   llvm.aarch64.neon.scalar.sqxtn / uqxtn / sqxtun
;     AdvSIMD_1IntArg_Narrow: anyint (anyint)
;     Signedness is the ID:
;       sqxtn  signed -> signed
;       uqxtn  unsigned -> unsigned
;       sqxtun signed -> unsigned
;     ISel SIMDTwoScalarMixedBHS, baseline HasNEON:
;       only i32(i64)  ->  sqxtn/uqxtn/sqxtun s, d
;     i16(i32) / i8(i16) encodings have empty patterns.
; Clang vqmovnd_s64 / vqmovnd_u64 / vqmovund_s64.
; h/s forms use vector sqxtn, not these IDs.
; Must not rewrite to trunc or vector sqxtn.
; Exact C non-vararg.  Ordinary tail accepted and replayed as non-tail; see vmp-direct-call-tail-eligibility-semantic.ll.  No last-token gate.  No ImmediateArguments.
; Well-formed vector sqxtn is
; vmp-aarch64-neon-sat-narrow-semantic.ll.
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
declare i32 @llvm.aarch64.neon.scalar.sqxtn.i32.i64(i64)
declare i32 @llvm.aarch64.neon.scalar.uqxtn.i32.i64(i64)
declare i32 @llvm.aarch64.neon.scalar.sqxtun.i32.i64(i64)
declare i16 @llvm.aarch64.neon.scalar.sqxtn.i16.i32(i32)
declare i8 @llvm.aarch64.neon.scalar.sqxtn.i8.i16(i16)
declare <vscale x 16 x i8> @llvm.aarch64.sve.sqxtnb.nxv8i16(<vscale x 8 x i16>)

@sink_i32 = global i32 0, align 4
@sink_i64 = global i64 0, align 8

define i32 @protected_scalar_sqxtn(i64 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.scalar.sqxtn.i32.i64(i64 %a)
  ret i32 %r
}

define i32 @protected_scalar_uqxtn(i64 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.scalar.uqxtn.i32.i64(i64 %a)
  ret i32 %r
}

define i32 @protected_scalar_sqxtun(i64 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.scalar.sqxtun.i32.i64(i64 %a)
  ret i32 %r
}

; Out-of-range signed min/max: replay scalar.sqxtn, not trunc.
define i32 @protected_scalar_sqxtn_sat(i64 %unused) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.scalar.sqxtn.i32.i64(i64 -2147483649)
  ret i32 %r
}

define i32 @protected_scalar_uqxtn_sat(i64 %unused) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.scalar.uqxtn.i32.i64(i64 4294967296)
  ret i32 %r
}

define i32 @protected_scalar_sqxtun_neg(i64 %unused) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.scalar.sqxtun.i32.i64(i64 -1)
  ret i32 %r
}

; Signed high: INT32_MAX+1 saturates (sqxtn), not trunc.
define i32 @protected_scalar_sqxtn_hi(i64 %unused) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.scalar.sqxtn.i32.i64(i64 2147483648)
  ret i32 %r
}

; Unsigned view of -1 is UINT64_MAX -> UINT32_MAX (uqxtn).
define i32 @protected_scalar_uqxtn_neg(i64 %unused) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.scalar.uqxtn.i32.i64(i64 -1)
  ret i32 %r
}

; Signed-to-unsigned high: 2^32 saturates to UINT32_MAX (sqxtun).
define i32 @protected_scalar_sqxtun_hi(i64 %unused) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.scalar.sqxtun.i32.i64(i64 4294967296)
  ret i32 %r
}

; ----- negatives: selected, not virtualized -----

define i16 @unsupported_i16(i32 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i16 @llvm.aarch64.neon.scalar.sqxtn.i16.i32(i32 %a)
  ret i16 %r
}

define i8 @unsupported_i8(i16 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i8 @llvm.aarch64.neon.scalar.sqxtn.i8.i16(i16 %a)
  ret i8 %r
}

; Well-formed llvm.aarch64.neon.sqxtn is
; vmp-aarch64-neon-sat-narrow-semantic.ll and must not stay here
; with SKIP (it would virtualize).

define <vscale x 16 x i8> @unsupported_sve_sqxtnb(<vscale x 8 x i16> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 16 x i8> @llvm.aarch64.sve.sqxtnb.nxv8i16(<vscale x 8 x i16> %a)
  ret <vscale x 16 x i8> %r
}

define i32 @unsupported_fastcc(i64 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc i32 @llvm.aarch64.neon.scalar.sqxtn.i32.i64(i64 %a)
  ret i32 %r
}


define i32 @unsupported_musttail(i64 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call i32 @llvm.aarch64.neon.scalar.sqxtn.i32.i64(i64 %a)
  ret i32 %r
}

define i32 @unsupported_bundle(i64 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.scalar.sqxtn.i32.i64(i64 %a) [ "deopt"(i32 0) ]
  ret i32 %r
}

define i32 @unsupported_noreturn(i64 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.scalar.sqxtn.i32.i64(i64 %a) noreturn
  ret i32 %r
}

define i32 @unsupported_returns_twice(i64 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.neon.scalar.sqxtn.i32.i64(i64 %a) returns_twice
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
  %a = load volatile i64, ptr @sink_i64, align 8
  %r0 = call i32 @protected_scalar_sqxtn(i64 %a)
  store volatile i32 %r0, ptr @sink_i32, align 4
  %r1 = call i32 @protected_scalar_uqxtn(i64 %a)
  store volatile i32 %r1, ptr @sink_i32, align 4
  %r2 = call i32 @protected_scalar_sqxtun(i64 %a)
  store volatile i32 %r2, ptr @sink_i32, align 4
  %r3 = call i32 @protected_scalar_sqxtn_sat(i64 %a)
  store volatile i32 %r3, ptr @sink_i32, align 4
  %r4 = call i32 @protected_scalar_uqxtn_sat(i64 %a)
  store volatile i32 %r4, ptr @sink_i32, align 4
  %r5 = call i32 @protected_scalar_sqxtun_neg(i64 %a)
  store volatile i32 %r5, ptr @sink_i32, align 4
  %r6 = call i32 @protected_scalar_sqxtn_hi(i64 %a)
  store volatile i32 %r6, ptr @sink_i32, align 4
  %r7 = call i32 @protected_scalar_uqxtn_neg(i64 %a)
  store volatile i32 %r7, ptr @sink_i32, align 4
  %r8 = call i32 @protected_scalar_sqxtun_hi(i64 %a)
  store volatile i32 %r8, ptr @sink_i32, align 4
  ret i32 0
}

; SKIP-DAG: Skipping VMP on unsupported_i16: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_i8: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_sve_sqxtnb: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_noreturn: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_returns_twice: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_sret: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_scalar_sqxtn:
; SKIP-NOT: Skipping VMP on protected_scalar_uqxtn:
; SKIP-NOT: Skipping VMP on protected_scalar_sqxtun:
; SKIP-NOT: Skipping VMP on protected_scalar_sqxtn_sat:
; SKIP-NOT: Skipping VMP on protected_scalar_uqxtn_sat:
; SKIP-NOT: Skipping VMP on protected_scalar_sqxtun_neg:
; SKIP-NOT: Skipping VMP on protected_scalar_sqxtn_hi:
; SKIP-NOT: Skipping VMP on protected_scalar_uqxtn_neg:
; SKIP-NOT: Skipping VMP on protected_scalar_sqxtun_hi:

; VIRT: define i32 @protected_scalar_sqxtn({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.neon.scalar.sqxtn.i32.i64(
; VIRT: define i32 @protected_scalar_uqxtn({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.neon.scalar.uqxtn.i32.i64(
; VIRT: define i32 @protected_scalar_sqxtun({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.neon.scalar.sqxtun.i32.i64(
; VIRT: define i32 @protected_scalar_sqxtn_sat({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.neon.scalar.sqxtn.i32.i64(
; VIRT: define i32 @protected_scalar_uqxtn_sat({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define i32 @protected_scalar_sqxtun_neg({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.neon.scalar.sqxtun.i32.i64(
; VIRT: define i32 @protected_scalar_sqxtn_hi({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.neon.scalar.sqxtn.i32.i64(
; VIRT: define i32 @protected_scalar_uqxtn_neg({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.neon.scalar.uqxtn.i32.i64(
; VIRT: define i32 @protected_scalar_sqxtun_hi({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.aarch64.neon.scalar.sqxtun.i32.i64(
; VIRT: define {{.*}} @unsupported_i16({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; AARCH64-ASM-DAG: {{^[[:space:]]*}}sqxtn{{[ \t]}}{{s[0-9]+}},{{[ \t]}}{{d[0-9]+}}
; AARCH64-ASM-DAG: {{^[[:space:]]*}}uqxtn{{[ \t]}}{{s[0-9]+}},{{[ \t]}}{{d[0-9]+}}
; AARCH64-ASM-DAG: {{^[[:space:]]*}}sqxtun{{[ \t]}}{{s[0-9]+}},{{[ \t]}}{{d[0-9]+}}
; HOST: Skipping VMP: only AArch64 targets are supported
