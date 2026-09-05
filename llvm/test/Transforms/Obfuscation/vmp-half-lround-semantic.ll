; Restricted scalar llvm.lround.i64.f16 / llvm.llround.i64.f16 /
; llvm.lrint.i64.f16 / llvm.llrint.i64.f16.  Replayed via the existing
; CallDescriptor and integer/float VReg frames.  Requires last-token
; function +fullfp16.  Well-shaped calls missing or ending in
; -fullfp16 skip as unsupported target feature and keep
; hikari.vmp.selected.  Does not change f32/f64 lround/llround/lrint/
; llrint, half ordinary math, half sat, or half-vector paths.
; Ordinary tail degrades to a normal call.  No FMF path and no
; dedicated VM opcode.
;
; Host x86 cannot be assumed to select half-to-i64 rounding.  This lit
; is FileCheck + AArch64 llc/readobj only (function +fullfp16, no
; global -mattr).  Native reference functions also carry +fullfp16 so
; AArch64 llc can select lround f16; they are not VMP-selected.  Do
; not invent a host lli semantic oracle.
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
declare i64 @llvm.lround.i64.f16(half)
declare i64 @llvm.llround.i64.f16(half)
declare i64 @llvm.lrint.i64.f16(half)
declare i64 @llvm.llrint.i64.f16(half)
declare i32 @llvm.lround.i32.f16(half)
declare i64 @llvm.lround.i64.bf16(bfloat)
declare i64 @llvm.experimental.constrained.lround.i64.f128(fp128, metadata)

; ----- positives -----

declare <2 x half> @llvm.experimental.constrained.pow.v2f16(<2 x half>, <2 x half>, metadata, metadata)

define i64 @reference_lround_f16(half %a) "target-features"="+fullfp16" {
entry:
  %r = call i64 @llvm.lround.i64.f16(half %a)
  ret i64 %r
}

define i64 @protected_lround_f16(half %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.lround.i64.f16(half %a)
  ret i64 %r
}

define i64 @reference_llround_f16(half %a) "target-features"="+fullfp16" {
entry:
  %r = call i64 @llvm.llround.i64.f16(half %a)
  ret i64 %r
}

define i64 @protected_llround_f16(half %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.llround.i64.f16(half %a)
  ret i64 %r
}

define i64 @reference_lrint_f16(half %a) "target-features"="+fullfp16" {
entry:
  %r = call i64 @llvm.lrint.i64.f16(half %a)
  ret i64 %r
}

define i64 @protected_lrint_f16(half %a) noinline optnone "target-features"="+neon,+fullfp16,+fp-armv8" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.lrint.i64.f16(half %a)
  ret i64 %r
}

define i64 @reference_llrint_f16(half %a) "target-features"="+fullfp16" {
entry:
  %r = call i64 @llvm.llrint.i64.f16(half %a)
  ret i64 %r
}

define i64 @protected_llrint_f16(half %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.llrint.i64.f16(half %a)
  ret i64 %r
}

define i64 @reference_lround_tail_f16(half %a) "target-features"="+fullfp16" {
entry:
  %r = tail call i64 @llvm.lround.i64.f16(half %a)
  ret i64 %r
}

define i64 @protected_lround_tail_f16(half %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = tail call i64 @llvm.lround.i64.f16(half %a)
  ret i64 %r
}

define i64 @reference_lround_phi_f16(half %a, half %b, i1 %c) "target-features"="+fullfp16" {
entry:
  br i1 %c, label %left, label %right
left:
  %l = call i64 @llvm.lround.i64.f16(half %a)
  br label %join
right:
  %r = call i64 @llvm.llround.i64.f16(half %b)
  br label %join
join:
  %p = phi i64 [ %l, %left ], [ %r, %right ]
  ret i64 %p
}

define i64 @protected_lround_phi_f16(half %a, half %b, i1 %c) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  br i1 %c, label %left, label %right
left:
  %l = call i64 @llvm.lround.i64.f16(half %a)
  br label %join
right:
  %r = call i64 @llvm.llround.i64.f16(half %b)
  br label %join
join:
  %p = phi i64 [ %l, %left ], [ %r, %right ]
  ret i64 %p
}

define i64 @reference_lrint_loop_f16(half %a, i32 %n) "target-features"="+fullfp16" {
entry:
  br label %hdr
hdr:
  %acc = phi half [ %a, %entry ], [ %nxt, %hdr ]
  %i = phi i32 [ 0, %entry ], [ %i.nxt, %hdr ]
  %cur = call i64 @llvm.lrint.i64.f16(half %acc)
  %nxt = fadd half %acc, 0xH3C00
  %i.nxt = add i32 %i, 1
  %more = icmp ult i32 %i.nxt, %n
  br i1 %more, label %hdr, label %done
done:
  ret i64 %cur
}

define i64 @protected_lrint_loop_f16(half %a, i32 %n) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  br label %hdr
hdr:
  %acc = phi half [ %a, %entry ], [ %nxt, %hdr ]
  %i = phi i32 [ 0, %entry ], [ %i.nxt, %hdr ]
  %cur = call i64 @llvm.lrint.i64.f16(half %acc)
  %nxt = fadd half %acc, 0xH3C00
  %i.nxt = add i32 %i, 1
  %more = icmp ult i32 %i.nxt, %n
  br i1 %more, label %hdr, label %done
done:
  ret i64 %cur
}

; ----- negatives: selected, not virtualized -----

define i64 @unsupported_half_lround_no_fullfp16(half %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.lround.i64.f16(half %a)
  ret i64 %r
}

define i64 @unsupported_half_lround_fullfp16_disabled(half %a) noinline optnone "target-features"="+neon,+fullfp16,-fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.llround.i64.f16(half %a)
  ret i64 %r
}

define i32 @unsupported_half_lround_i32(half %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.lround.i32.f16(half %a)
  ret i32 %r
}

define i64 @unsupported_half_lround_bfloat(bfloat %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.lround.i64.bf16(bfloat %a)
  ret i64 %r
}

define i64 @unsupported_half_lround_fp128(fp128 %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.experimental.constrained.lround.i64.f128(fp128 %a, metadata !"fpexcept.ignore")
  ret i64 %r
}

; LLVM 15 lround has no vector overload.  A vector-typed constrained
; round stays outside this scalar surface and is a safe skip.
define <2 x half> @unsupported_half_lround_vector(<2 x half> %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <2 x half> @llvm.experimental.constrained.pow.v2f16(<2 x half> %a, <2 x half> %a, metadata !"round.tonearest", metadata !"fpexcept.ignore") [ "deopt"(i32 0) ]
  ret <2 x half> %r
}

define i64 @unsupported_half_lround_fastcc(half %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call fastcc i64 @llvm.lround.i64.f16(half %a)
  ret i64 %r
}

define i64 @unsupported_half_lround_musttail(half %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = musttail call i64 @llvm.lround.i64.f16(half %a)
  ret i64 %r
}

define i64 @unsupported_half_lround_bundle(half %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.lround.i64.f16(half %a) [ "deopt"(i32 0) ]
  ret i64 %r
}

define <2 x half> @unsupported_half_lround_constrained(<2 x half> %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <2 x half> @llvm.experimental.constrained.pow.v2f16(<2 x half> %a, <2 x half> %a, metadata !"round.tonearest", metadata !"fpexcept.ignore") [ "deopt"(i32 0) ]
  ret <2 x half> %r
}

define i64 @unsupported_half_lround_poison(half %a) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.lround.i64.f16(half poison)
  ret i64 %r
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_half_lround_no_fullfp16: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_half_lround_fullfp16_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_half_lround_i32: unsupported lround
; SKIP-DAG: Skipping VMP on unsupported_half_lround_bfloat: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_half_lround_fp128: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_half_lround_vector: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_half_lround_fastcc: unsupported lround
; SKIP-DAG: Skipping VMP on unsupported_half_lround_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_half_lround_bundle: unsupported lround
; SKIP-DAG: Skipping VMP on unsupported_half_lround_constrained: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_half_lround_poison: unsupported lround
; SKIP-NOT: Skipping VMP on protected_lround_f16:
; SKIP-NOT: Skipping VMP on protected_llround_f16:
; SKIP-NOT: Skipping VMP on protected_lrint_f16:
; SKIP-NOT: Skipping VMP on protected_llrint_f16:
; SKIP-NOT: Skipping VMP on protected_lround_tail_f16:
; SKIP-NOT: Skipping VMP on protected_lround_phi_f16:
; SKIP-NOT: Skipping VMP on protected_lrint_loop_f16:

; VIRT: define i64 @protected_lround_f16({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.lround.i64.f16(
; VIRT: define i64 @protected_llround_f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.llround.i64.f16(
; VIRT: define i64 @protected_lrint_f16({{.*}} #[[PROT2:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.lrint.i64.f16(
; VIRT: define i64 @protected_llrint_f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.llrint.i64.f16(
; VIRT: define i64 @protected_lround_tail_f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: tail call
; VIRT: call i64 @llvm.lround.i64.f16(
; VIRT: define i64 @protected_lround_phi_f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.lround.i64.f16(
; VIRT: define i64 @protected_lrint_loop_f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.lrint.i64.f16(
; VIRT: define {{.*}} @unsupported_half_lround_no_fullfp16({{.*}} #[[UNSUPATTR:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_half_lround_fullfp16_disabled({{.*}} #[[UNSUPFEAT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_half_lround_i32({{.*}} #[[UNSUPCC:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_half_lround_bfloat({{.*}} #[[UNSUP_ARG:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_half_lround_fp128({{.*}} #[[UNSUP_ARG]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_half_lround_vector({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_half_lround_fastcc({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_half_lround_musttail({{.*}} #[[UNSUP_MT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call i64 @llvm.lround.i64.f16(
; VIRT: define {{.*}} @unsupported_half_lround_bundle({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call i64 @llvm.lround.i64.f16({{.*}}[ "deopt"(i32 0) ]
; VIRT: define {{.*}} @unsupported_half_lround_constrained({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_half_lround_poison({{.*}} #[[UNSUPCC]] {
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
