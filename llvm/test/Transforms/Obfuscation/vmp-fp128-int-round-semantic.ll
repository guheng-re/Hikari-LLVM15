; Scalar IEEE fp128 rounding-to-integer: llvm.lround / llvm.llround /
; llvm.lrint / llvm.llrint and llvm.fptosi.sat / llvm.fptoui.sat.
; Replayed through CallDescriptor as CreateCall of the original
; Function* on the typed vmp.fp128.regs frame.  The fp128 operand
; stays on that frame; the integer result writes an i8/i16/i32/i64
; VReg.  Never i128 reinterpretation.  No ImmArg (LangRef has none).
;
; Dest widths follow the documented AArch64 contract plus the existing
; sat surface: lround/lrint accept i32 or i64; llround/llrint accept
; i64 only; sat accepts i8/i16/i32/i64.  Ordinary tail of an already-supported CallInst is accepted; see vmp-direct-call-tail-eligibility-semantic.ll.  musttail stays rejected.  Rounding, overflow, and NaN semantics stay
; on the original intrinsic.
;
; Rejected: constrained, vector, ppc_fp128, ll*.i32, i16/i1/i128 dest,
; poison/undef, musttail, bundles, inline asm, invalid ABI.
;
; LLVM 15 AArch64 selects every accepted form via libcall (lroundl /
; llroundl / lrintl / llrintl / __fixtf* / __fixunstf*).  Host x86
; ISel also emits lroundl, but x86_64 long double is f80, so host lli
; is not a semantic oracle (probed: lround.i64.f128 of 1.5 returned 0).
; FileCheck + AArch64 llc/readobj only.  O0/O2 x aesSeed 97/7.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.ll > %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.ll > %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.s7.ll > %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.s7.ll > %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare i32 @llvm.lround.i32.f128(fp128)
declare i64 @llvm.lround.i64.f128(fp128)
declare i32 @llvm.llround.i32.f128(fp128)
declare i64 @llvm.llround.i64.f128(fp128)
declare i32 @llvm.lrint.i32.f128(fp128)
declare i64 @llvm.lrint.i64.f128(fp128)
declare i32 @llvm.llrint.i32.f128(fp128)
declare i64 @llvm.llrint.i64.f128(fp128)
declare i16 @llvm.lround.i16.f128(fp128)
declare i8 @llvm.fptosi.sat.i8.f128(fp128)
declare i16 @llvm.fptosi.sat.i16.f128(fp128)
declare i32 @llvm.fptosi.sat.i32.f128(fp128)
declare i64 @llvm.fptosi.sat.i64.f128(fp128)
declare i8 @llvm.fptoui.sat.i8.f128(fp128)
declare i16 @llvm.fptoui.sat.i16.f128(fp128)
declare i32 @llvm.fptoui.sat.i32.f128(fp128)
declare i64 @llvm.fptoui.sat.i64.f128(fp128)
declare i1 @llvm.fptosi.sat.i1.f128(fp128)
declare i128 @llvm.fptosi.sat.i128.f128(fp128)
declare <1 x i32> @llvm.fptosi.sat.v1i32.v1f128(<1 x fp128>)
declare i64 @llvm.lround.i64.ppcf128(ppc_fp128)
declare i64 @llvm.experimental.constrained.lround.i64.f128(fp128, metadata)
declare void @ext_fp128_sret(ptr sret(i32), fp128)

; ----- positives -----

define i32 @reference_lround_i32(fp128 %a) noinline {
entry:
  %r = call i32 @llvm.lround.i32.f128(fp128 %a)
  ret i32 %r
}

define i32 @protected_lround_i32(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.lround.i32.f128(fp128 %a)
  ret i32 %r
}

define i64 @reference_lround_i64(fp128 %a) noinline {
entry:
  %r = call i64 @llvm.lround.i64.f128(fp128 %a)
  ret i64 %r
}

define i64 @protected_lround_i64(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.lround.i64.f128(fp128 %a)
  ret i64 %r
}

define i64 @reference_llround_i64(fp128 %a) noinline {
entry:
  %r = call i64 @llvm.llround.i64.f128(fp128 %a)
  ret i64 %r
}

define i64 @protected_llround_i64(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.llround.i64.f128(fp128 %a)
  ret i64 %r
}

define i32 @reference_lrint_i32(fp128 %a) noinline {
entry:
  %r = call i32 @llvm.lrint.i32.f128(fp128 %a)
  ret i32 %r
}

define i32 @protected_lrint_i32(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.lrint.i32.f128(fp128 %a)
  ret i32 %r
}

define i64 @reference_lrint_i64(fp128 %a) noinline {
entry:
  %r = call i64 @llvm.lrint.i64.f128(fp128 %a)
  ret i64 %r
}

define i64 @protected_lrint_i64(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.lrint.i64.f128(fp128 %a)
  ret i64 %r
}

define i64 @reference_llrint_i64(fp128 %a) noinline {
entry:
  %r = call i64 @llvm.llrint.i64.f128(fp128 %a)
  ret i64 %r
}

define i64 @protected_llrint_i64(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.llrint.i64.f128(fp128 %a)
  ret i64 %r
}

define i8 @reference_sat_si8(fp128 %a) noinline {
entry:
  %r = call i8 @llvm.fptosi.sat.i8.f128(fp128 %a)
  ret i8 %r
}

define i8 @protected_sat_si8(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i8 @llvm.fptosi.sat.i8.f128(fp128 %a)
  ret i8 %r
}

define i16 @reference_sat_si16(fp128 %a) noinline {
entry:
  %r = call i16 @llvm.fptosi.sat.i16.f128(fp128 %a)
  ret i16 %r
}

define i16 @protected_sat_si16(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i16 @llvm.fptosi.sat.i16.f128(fp128 %a)
  ret i16 %r
}

define i32 @reference_sat_si32(fp128 %a) noinline {
entry:
  %r = call i32 @llvm.fptosi.sat.i32.f128(fp128 %a)
  ret i32 %r
}

define i32 @protected_sat_si32(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.fptosi.sat.i32.f128(fp128 %a)
  ret i32 %r
}

define i64 @reference_sat_si64(fp128 %a) noinline {
entry:
  %r = call i64 @llvm.fptosi.sat.i64.f128(fp128 %a)
  ret i64 %r
}

define i64 @protected_sat_si64(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.fptosi.sat.i64.f128(fp128 %a)
  ret i64 %r
}

define i8 @reference_sat_ui8(fp128 %a) noinline {
entry:
  %r = call i8 @llvm.fptoui.sat.i8.f128(fp128 %a)
  ret i8 %r
}

define i8 @protected_sat_ui8(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i8 @llvm.fptoui.sat.i8.f128(fp128 %a)
  ret i8 %r
}

define i16 @reference_sat_ui16(fp128 %a) noinline {
entry:
  %r = call i16 @llvm.fptoui.sat.i16.f128(fp128 %a)
  ret i16 %r
}

define i16 @protected_sat_ui16(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i16 @llvm.fptoui.sat.i16.f128(fp128 %a)
  ret i16 %r
}

define i32 @reference_sat_ui32(fp128 %a) noinline {
entry:
  %r = call i32 @llvm.fptoui.sat.i32.f128(fp128 %a)
  ret i32 %r
}

define i32 @protected_sat_ui32(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.fptoui.sat.i32.f128(fp128 %a)
  ret i32 %r
}

define i64 @reference_sat_ui64(fp128 %a) noinline {
entry:
  %r = call i64 @llvm.fptoui.sat.i64.f128(fp128 %a)
  ret i64 %r
}

define i64 @protected_sat_ui64(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.fptoui.sat.i64.f128(fp128 %a)
  ret i64 %r
}

define i64 @reference_tail(fp128 %a) noinline {
entry:
  %r = tail call i64 @llvm.lround.i64.f128(fp128 %a)
  ret i64 %r
}


define i64 @reference_phi(i1 %c, fp128 %a, fp128 %b) noinline {
entry:
  br i1 %c, label %left, label %right

left:
  %l = call i64 @llvm.lround.i64.f128(fp128 %a)
  br label %join

right:
  %r = call i64 @llvm.llround.i64.f128(fp128 %b)
  br label %join

join:
  %p = phi i64 [ %l, %left ], [ %r, %right ]
  ret i64 %p
}

define i64 @protected_phi(i1 %c, fp128 %a, fp128 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  br i1 %c, label %left, label %right

left:
  %l = call i64 @llvm.lround.i64.f128(fp128 %a)
  br label %join

right:
  %r = call i64 @llvm.llround.i64.f128(fp128 %b)
  br label %join

join:
  %p = phi i64 [ %l, %left ], [ %r, %right ]
  ret i64 %p
}

define i32 @reference_loop(fp128 %a, i32 %n) noinline {
entry:
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %acc = phi i32 [ 0, %entry ], [ %next, %loop ]
  %cur = call i32 @llvm.lrint.i32.f128(fp128 %a)
  %next = add i32 %acc, %cur
  %i1 = add i32 %i, 1
  %more = icmp slt i32 %i1, %n
  br i1 %more, label %loop, label %done

done:
  ret i32 %next
}

define i32 @protected_loop(fp128 %a, i32 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %acc = phi i32 [ 0, %entry ], [ %next, %loop ]
  %cur = call i32 @llvm.lrint.i32.f128(fp128 %a)
  %next = add i32 %acc, %cur
  %i1 = add i32 %i, 1
  %more = icmp slt i32 %i1, %n
  br i1 %more, label %loop, label %done

done:
  ret i32 %next
}

define i8 @reference_sat_ovf(fp128 %a) noinline {
entry:
  %r = call i8 @llvm.fptosi.sat.i8.f128(fp128 %a)
  ret i8 %r
}

define i8 @protected_sat_ovf(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i8 @llvm.fptosi.sat.i8.f128(fp128 %a)
  ret i8 %r
}

define i8 @reference_sat_uneg(fp128 %a) noinline {
entry:
  %r = call i8 @llvm.fptoui.sat.i8.f128(fp128 %a)
  ret i8 %r
}

define i8 @protected_sat_uneg(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i8 @llvm.fptoui.sat.i8.f128(fp128 %a)
  ret i8 %r
}

define i32 @reference_sat_nan(fp128 %a) noinline {
entry:
  %r = call i32 @llvm.fptosi.sat.i32.f128(fp128 %a)
  ret i32 %r
}

define i32 @protected_sat_nan(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.fptosi.sat.i32.f128(fp128 %a)
  ret i32 %r
}

; ----- negatives -----

define i64 @unsupported_constrained(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.experimental.constrained.lround.i64.f128(fp128 %a, metadata !"fpexcept.ignore")
  ret i64 %r
}

define i32 @unsupported_llround_i32(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.llround.i32.f128(fp128 %a)
  ret i32 %r
}

define i32 @unsupported_llrint_i32(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.llrint.i32.f128(fp128 %a)
  ret i32 %r
}

define i16 @unsupported_lround_i16(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i16 @llvm.lround.i16.f128(fp128 %a)
  ret i16 %r
}

define i1 @unsupported_sat_i1(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i1 @llvm.fptosi.sat.i1.f128(fp128 %a)
  ret i1 %r
}

define i128 @unsupported_sat_i128(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i128 @llvm.fptosi.sat.i128.f128(fp128 %a)
  ret i128 %r
}

define <1 x i32> @unsupported_vector(<1 x fp128> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <1 x i32> @llvm.fptosi.sat.v1i32.v1f128(<1 x fp128> %a)
  ret <1 x i32> %r
}

define i64 @unsupported_ppc(ppc_fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.lround.i64.ppcf128(ppc_fp128 %a)
  ret i64 %r
}

define i64 @unsupported_poison(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.lround.i64.f128(fp128 poison)
  ret i64 %r
}

define i64 @unsupported_undef(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.lround.i64.f128(fp128 undef)
  ret i64 %r
}

define i64 @unsupported_musttail(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call i64 @llvm.lround.i64.f128(fp128 %a)
  ret i64 %r
}

define i64 @unsupported_bundle(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.lround.i64.f128(fp128 %a) [ "deopt"() ]
  ret i64 %r
}

define i64 @unsupported_asm(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 asm "", "=r,w"(fp128 %a)
  ret i64 %r
}

define i64 @unsupported_indirect(ptr %fp, fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 %fp(fp128 %a)
  ret i64 %r
}

define void @unsupported_sret(ptr sret(i32) %p, fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @ext_fp128_sret(ptr sret(i32) %p, fp128 %a)
  ret void
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_constrained: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_llround_i32: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_llrint_i32: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_lround_i16: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_sat_i1: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_sat_i128: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_vector: unsupported
; SKIP-DAG: Skipping VMP on unsupported_ppc: unsupported
; SKIP-DAG: Skipping VMP on unsupported_poison: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_undef: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_asm: inline assembly
; SKIP-DAG: Skipping VMP on unsupported_indirect: indirect call
; SKIP-DAG: Skipping VMP on unsupported_sret: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_lround_i32:
; SKIP-NOT: Skipping VMP on protected_lround_i64:
; SKIP-NOT: Skipping VMP on protected_llround_i64:
; SKIP-NOT: Skipping VMP on protected_lrint_i32:
; SKIP-NOT: Skipping VMP on protected_lrint_i64:
; SKIP-NOT: Skipping VMP on protected_llrint_i64:
; SKIP-NOT: Skipping VMP on protected_sat_si8:
; SKIP-NOT: Skipping VMP on protected_sat_si16:
; SKIP-NOT: Skipping VMP on protected_sat_si32:
; SKIP-NOT: Skipping VMP on protected_sat_si64:
; SKIP-NOT: Skipping VMP on protected_sat_ui8:
; SKIP-NOT: Skipping VMP on protected_sat_ui16:
; SKIP-NOT: Skipping VMP on protected_sat_ui32:
; SKIP-NOT: Skipping VMP on protected_sat_ui64:
; SKIP-NOT: Skipping VMP on protected_phi:
; SKIP-NOT: Skipping VMP on protected_loop:
; SKIP-NOT: Skipping VMP on protected_sat_ovf:
; SKIP-NOT: Skipping VMP on protected_sat_uneg:
; SKIP-NOT: Skipping VMP on protected_sat_nan:

; VIRT: define i32 @protected_lround_i32({{.*}} #[[PROT:[0-9]+]] {
; VIRT: %vmp.fp128.regs = alloca [{{[0-9]+}} x fp128]
; VIRT: vmp.dispatch:
; VIRT-NOT: call void @hikari_vmp()
; VIRT-NOT: bitcast fp128 {{.*}} to i128
; VIRT: call i32 @llvm.lround.i32.f128(fp128
; VIRT: define i64 @protected_lround_i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.lround.i64.f128(fp128
; VIRT: define i64 @protected_llround_i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.llround.i64.f128(fp128
; VIRT: define i32 @protected_lrint_i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.lrint.i32.f128(fp128
; VIRT: define i64 @protected_lrint_i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.lrint.i64.f128(fp128
; VIRT: define i64 @protected_llrint_i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.llrint.i64.f128(fp128
; VIRT: define i8 @protected_sat_si8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i8 @llvm.fptosi.sat.i8.f128(fp128
; VIRT: define i16 @protected_sat_si16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i16 @llvm.fptosi.sat.i16.f128(fp128
; VIRT: define i32 @protected_sat_si32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.fptosi.sat.i32.f128(fp128
; VIRT: define i64 @protected_sat_si64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.fptosi.sat.i64.f128(fp128
; VIRT: define i8 @protected_sat_ui8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i8 @llvm.fptoui.sat.i8.f128(fp128
; VIRT: define i16 @protected_sat_ui16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i16 @llvm.fptoui.sat.i16.f128(fp128
; VIRT: define i32 @protected_sat_ui32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.fptoui.sat.i32.f128(fp128
; VIRT: define i64 @protected_sat_ui64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.fptoui.sat.i64.f128(fp128
; VIRT: define i64 @protected_phi({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: call i64 @llvm.lround.i64.f128(fp128
; VIRT-DAG: call i64 @llvm.llround.i64.f128(fp128
; VIRT: define i32 @protected_loop({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.lrint.i32.f128(fp128
; VIRT: define i8 @protected_sat_ovf({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i8 @llvm.fptosi.sat.i8.f128(fp128
; VIRT: define i8 @protected_sat_uneg({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i8 @llvm.fptoui.sat.i8.f128(fp128
; VIRT: define i32 @protected_sat_nan({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.fptosi.sat.i32.f128(fp128
; VIRT: define {{.*}} @unsupported_constrained({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_llround_i32({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_llrint_i32({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_lround_i16({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_sat_i1({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_sat_i128({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_vector({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ppc({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_poison({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_undef({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_musttail({{.*}} #[[UNSUPMUST:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_bundle({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_asm({{.*}} #[[UNSUPASM:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_indirect({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_sret({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; Direct musttail / inline asm are early deselects; +no selected/virtualized.
; VIRT-NOT: attributes #[[UNSUPMUST]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPMUST]] = { {{.*}}"hikari.vmp.selected"
; VIRT-NOT: attributes #[[UNSUPASM]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPASM]] = { {{.*}}"hikari.vmp.selected"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
