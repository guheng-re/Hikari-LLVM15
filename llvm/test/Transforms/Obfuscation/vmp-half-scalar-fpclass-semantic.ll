; Restricted scalar llvm.is.fpclass.f16 (i1 result, half operand,
; i32 ImmArg mask replayed via CallDescriptor ImmediateArguments).
; Requires last-token function +fullfp16.  Well-shaped calls missing
; or ending in -fullfp16 skip as unsupported target feature and keep
; hikari.vmp.selected.  Does not change f32/f64 scalar is.fpclass,
; half-vector is.fpclass, or ordinary tail.  No FMF path and no
; dedicated VM opcode.
;
; Host x86 cannot be assumed to select llvm.is.fpclass.f16.  This lit
; is FileCheck + AArch64 llc/readobj only (function +fullfp16, no
; global -mattr).  Do not invent a host lli semantic oracle.
;
; Masks: fcNormal=264, fcZero=96, fcInf=516, fcNan=3.
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
declare i1 @llvm.is.fpclass.f16(half, i32)
declare i1 @llvm.is.fpclass.bf16(bfloat, i32)
declare i1 @llvm.is.fpclass.ppcf128(ppc_fp128, i32)

declare <2 x half> @llvm.experimental.constrained.pow.v2f16(<2 x half>, <2 x half>, metadata, metadata)

define i1 @reference_fpclass_normal_f16(half %a) {
entry:
  %r = call i1 @llvm.is.fpclass.f16(half %a, i32 264)
  ret i1 %r
}

define i1 @protected_fpclass_normal_f16(half %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i1 @llvm.is.fpclass.f16(half %a, i32 264)
  ret i1 %r
}

define i1 @reference_fpclass_zero_f16(half %a) {
entry:
  %r = call i1 @llvm.is.fpclass.f16(half %a, i32 96)
  ret i1 %r
}

define i1 @protected_fpclass_zero_f16(half %a) noinline optnone "target-features"="+neon,+fullfp16,+fp-armv8" {
entry:
  call void @hikari_vmp()
  %r = call i1 @llvm.is.fpclass.f16(half %a, i32 96)
  ret i1 %r
}

define i1 @reference_fpclass_inf_f16(half %a) {
entry:
  %r = call i1 @llvm.is.fpclass.f16(half %a, i32 516)
  ret i1 %r
}

define i1 @protected_fpclass_inf_f16(half %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i1 @llvm.is.fpclass.f16(half %a, i32 516)
  ret i1 %r
}

define i1 @reference_fpclass_nan_f16(half %a) {
entry:
  %r = call i1 @llvm.is.fpclass.f16(half %a, i32 3)
  ret i1 %r
}

define i1 @protected_fpclass_nan_f16(half %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i1 @llvm.is.fpclass.f16(half %a, i32 3)
  ret i1 %r
}

define i1 @reference_fpclass_tail_f16(half %a) {
entry:
  %r = tail call i1 @llvm.is.fpclass.f16(half %a, i32 264)
  ret i1 %r
}

define i1 @protected_fpclass_tail_f16(half %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = tail call i1 @llvm.is.fpclass.f16(half %a, i32 264)
  ret i1 %r
}

; ----- negatives: selected, not virtualized -----

define i1 @unsupported_half_fpclass_no_fullfp16(half %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i1 @llvm.is.fpclass.f16(half %a, i32 264)
  ret i1 %r
}

define i1 @unsupported_half_fpclass_fullfp16_disabled(half %a) noinline optnone "target-features"="+neon,+fullfp16,-fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i1 @llvm.is.fpclass.f16(half %a, i32 264)
  ret i1 %r
}

define i1 @unsupported_half_fpclass_bfloat(bfloat %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i1 @llvm.is.fpclass.bf16(bfloat %a, i32 3)
  ret i1 %r
}

define i1 @unsupported_half_fpclass_ppc(ppc_fp128 %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i1 @llvm.is.fpclass.ppcf128(ppc_fp128 %a, i32 3)
  ret i1 %r
}

define i1 @unsupported_half_fpclass_fastcc(half %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call fastcc i1 @llvm.is.fpclass.f16(half %a, i32 264)
  ret i1 %r
}

define i1 @unsupported_half_fpclass_musttail(half %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = musttail call i1 @llvm.is.fpclass.f16(half %a, i32 264)
  ret i1 %r
}

define i1 @unsupported_half_fpclass_bundle(half %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i1 @llvm.is.fpclass.f16(half %a, i32 264) [ "deopt"(i32 0) ]
  ret i1 %r
}

define <2 x half> @unsupported_half_fpclass_constrained(<2 x half> %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <2 x half> @llvm.experimental.constrained.pow.v2f16(<2 x half> %a, <2 x half> %a, metadata !"round.tonearest", metadata !"fpexcept.ignore") [ "deopt"(i32 0) ]
  ret <2 x half> %r
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_half_fpclass_no_fullfp16: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_half_fpclass_fullfp16_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_half_fpclass_bfloat: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_half_fpclass_ppc: unsupported
; SKIP-DAG: Skipping VMP on unsupported_half_fpclass_fastcc: unsupported is.fpclass
; SKIP-DAG: Skipping VMP on unsupported_half_fpclass_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_half_fpclass_bundle: unsupported is.fpclass
; SKIP-DAG: Skipping VMP on unsupported_half_fpclass_constrained: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_fpclass_normal_f16:
; SKIP-NOT: Skipping VMP on protected_fpclass_zero_f16:
; SKIP-NOT: Skipping VMP on protected_fpclass_inf_f16:
; SKIP-NOT: Skipping VMP on protected_fpclass_nan_f16:
; SKIP-NOT: Skipping VMP on protected_fpclass_tail_f16:

; VIRT: define i1 @protected_fpclass_normal_f16({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call i1 @llvm.is.fpclass.f16({{.*}}, i32 264)
; VIRT: define i1 @protected_fpclass_zero_f16({{.*}} #[[PROT2:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call i1 @llvm.is.fpclass.f16({{.*}}, i32 96)
; VIRT: define i1 @protected_fpclass_inf_f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i1 @llvm.is.fpclass.f16({{.*}}, i32 516)
; VIRT: define i1 @protected_fpclass_nan_f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i1 @llvm.is.fpclass.f16({{.*}}, i32 3)
; VIRT: define i1 @protected_fpclass_tail_f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: tail call
; VIRT: call i1 @llvm.is.fpclass.f16({{.*}}, i32 264)
; VIRT: define {{.*}} @unsupported_half_fpclass_no_fullfp16({{.*}} #[[UNSUPATTR:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_half_fpclass_fullfp16_disabled({{.*}} #[[UNSUPFEAT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_half_fpclass_bfloat({{.*}} #[[UNSUP_ARG:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_half_fpclass_ppc({{.*}} #[[UNSUP_ARG]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_half_fpclass_fastcc({{.*}} #[[UNSUPCC:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_half_fpclass_musttail({{.*}} #[[UNSUP_MT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call i1 @llvm.is.fpclass.f16(
; VIRT: define {{.*}} @unsupported_half_fpclass_bundle({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call i1 @llvm.is.fpclass.f16({{.*}}[ "deopt"(i32 0) ]
; VIRT: define {{.*}} @unsupported_half_fpclass_constrained({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[PROT2]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT: attributes #[[UNSUPFEAT]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPFEAT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPCC]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_MT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_ARG]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
