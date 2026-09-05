; Listed last-token +bf16 llvm.fptosi.sat / llvm.fptoui.sat from
; scalar bfloat or a supported fixed bfloat vector (total width
; 1..128) to i8/i16/i32/i64 (scalar or same-lane vector; dest width
; independently 1..128).  Exact token only.  Well-shaped listed
; calls missing or ending in -bf16 skip as unsupported target
; feature and keep hikari.vmp.selected.
;
; No new VM opcode.  CallDescriptor.LegalizeBFloatMath: promote each
; bfloat source to f32, call the matching f32 sat intrinsic with the
; exact integer destination type, and store to the integer or integer
; vector VReg.  Vectors are per-lane.  Native llvm.fptosi.sat.*.bf16
; must not reach AArch64 ISel.  Ordinary non-sat fptosi/fptoui are
; unchanged.
;
; Not opened: i1/i128 dest, dest or source overwide, FastMathFlags if
; representable, constrained, atomics, scalable, poison/undef, invalid
; signatures, absent or last-token -bf16.
;
; Host x86 cannot be assumed to select bfloat sat.  This lit is
; FileCheck + AArch64 llc/readobj only (function +bf16, no global
; -mattr).
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
declare i8 @llvm.fptosi.sat.i8.bf16(bfloat)
declare i8 @llvm.fptoui.sat.i8.bf16(bfloat)
declare i16 @llvm.fptosi.sat.i16.bf16(bfloat)
declare i16 @llvm.fptoui.sat.i16.bf16(bfloat)
declare i32 @llvm.fptosi.sat.i32.bf16(bfloat)
declare i32 @llvm.fptoui.sat.i32.bf16(bfloat)
declare i64 @llvm.fptosi.sat.i64.bf16(bfloat)
declare i64 @llvm.fptoui.sat.i64.bf16(bfloat)
declare i1 @llvm.fptosi.sat.i1.bf16(bfloat)
declare i128 @llvm.fptosi.sat.i128.bf16(bfloat)
declare <4 x i8> @llvm.fptosi.sat.v4i8.v4bf16(<4 x bfloat>)
declare <4 x i32> @llvm.fptosi.sat.v4i32.v4bf16(<4 x bfloat>)
declare <4 x i32> @llvm.fptoui.sat.v4i32.v4bf16(<4 x bfloat>)
declare <2 x i64> @llvm.fptosi.sat.v2i64.v2bf16(<2 x bfloat>)
declare <8 x i16> @llvm.fptoui.sat.v8i16.v8bf16(<8 x bfloat>)
declare <4 x i64> @llvm.fptosi.sat.v4i64.v4bf16(<4 x bfloat>)

; ----- positives -----

define i8 @protected_fptosi_i8(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call i8 @llvm.fptosi.sat.i8.bf16(bfloat %a)
  ret i8 %r
}

define i8 @protected_fptoui_i8(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call i8 @llvm.fptoui.sat.i8.bf16(bfloat %a)
  ret i8 %r
}

define i16 @protected_fptosi_i16(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call i16 @llvm.fptosi.sat.i16.bf16(bfloat %a)
  ret i16 %r
}

define i16 @protected_fptoui_i16(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call i16 @llvm.fptoui.sat.i16.bf16(bfloat %a)
  ret i16 %r
}

define i32 @protected_fptosi_i32(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.fptosi.sat.i32.bf16(bfloat %a)
  ret i32 %r
}

define i32 @protected_fptoui_i32(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.fptoui.sat.i32.bf16(bfloat %a)
  ret i32 %r
}

define i64 @protected_fptosi_i64(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.fptosi.sat.i64.bf16(bfloat %a)
  ret i64 %r
}

define i64 @protected_fptoui_i64(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.fptoui.sat.i64.bf16(bfloat %a)
  ret i64 %r
}

; Negative source: signed sat keeps the sign; unsigned sat clamps to 0.
define i8 @protected_fptosi_neg() noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call i8 @llvm.fptosi.sat.i8.bf16(bfloat 0xRC000)
  ret i8 %r
}

define i8 @protected_fptoui_neg() noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call i8 @llvm.fptoui.sat.i8.bf16(bfloat 0xRC000)
  ret i8 %r
}

; Overflow: +Inf saturates to the integer max.
define i8 @protected_fptosi_overflow() noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call i8 @llvm.fptosi.sat.i8.bf16(bfloat 0xR7F80)
  ret i8 %r
}

define i32 @protected_last_token(bfloat %a) noinline optnone "target-features"="-bf16,+neon,+bf16" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.fptosi.sat.i32.bf16(bfloat %a)
  ret i32 %r
}

define <4 x i8> @protected_fptosi_v4i8(<4 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i8> @llvm.fptosi.sat.v4i8.v4bf16(<4 x bfloat> %a)
  ret <4 x i8> %r
}

define <4 x i32> @protected_fptosi_v4i32(<4 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.fptosi.sat.v4i32.v4bf16(<4 x bfloat> %a)
  ret <4 x i32> %r
}

define <4 x i32> @protected_fptoui_v4i32(<4 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.fptoui.sat.v4i32.v4bf16(<4 x bfloat> %a)
  ret <4 x i32> %r
}

define <2 x i64> @protected_fptosi_v2i64(<2 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.fptosi.sat.v2i64.v2bf16(<2 x bfloat> %a)
  ret <2 x i64> %r
}

define <8 x i16> @protected_fptoui_v8i16(<8 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <8 x i16> @llvm.fptoui.sat.v8i16.v8bf16(<8 x bfloat> %a)
  ret <8 x i16> %r
}

; ----- negatives -----

define i32 @unsupported_fptosi_no_feature(i16 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %b = bitcast i16 %a to bfloat
  %r = call i32 @llvm.fptosi.sat.i32.bf16(bfloat %b)
  ret i32 %r
}

define i32 @unsupported_fptoui_disabled(i16 %a) noinline optnone "target-features"="+neon,+bf16,-bf16" {
entry:
  call void @hikari_vmp()
  %b = bitcast i16 %a to bfloat
  %r = call i32 @llvm.fptoui.sat.i32.bf16(bfloat %b)
  ret i32 %r
}

define i1 @unsupported_fptosi_i1(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call i1 @llvm.fptosi.sat.i1.bf16(bfloat %a)
  ret i1 %r
}

define i128 @unsupported_fptosi_i128(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call i128 @llvm.fptosi.sat.i128.bf16(bfloat %a)
  ret i128 %r
}

define i32 @unsupported_fptosi_poison() noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.fptosi.sat.i32.bf16(bfloat poison)
  ret i32 %r
}

define i64 @unsupported_fptosi_v4i64(<4 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x i64> @llvm.fptosi.sat.v4i64.v4bf16(<4 x bfloat> %a)
  %e = extractelement <4 x i64> %r, i32 0
  ret i64 %e
}

define i64 @unsupported_fptosi_v4_no_feature(i64 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %a = bitcast i64 %x to <4 x bfloat>
  %r = call <4 x i32> @llvm.fptosi.sat.v4i32.v4bf16(<4 x bfloat> %a)
  %e = extractelement <4 x i32> %r, i32 0
  %z = zext i32 %e to i64
  ret i64 %z
}

define <16 x bfloat> @unsupported_sat_v16(<16 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  ret <16 x bfloat> %a
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_fptosi_no_feature: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_fptoui_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_fptosi_i1: unsupported call
; SKIP-DAG: Skipping VMP on unsupported_fptosi_i128: unsupported call
; SKIP-DAG: Skipping VMP on unsupported_fptosi_poison: unsupported call
; SKIP-DAG: Skipping VMP on unsupported_fptosi_v4i64: unsupported call
; SKIP-DAG: Skipping VMP on unsupported_fptosi_v4_no_feature: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_sat_v16: unsupported
; SKIP-NOT: Skipping VMP on protected_fptosi_i8:
; SKIP-NOT: Skipping VMP on protected_fptoui_i8:
; SKIP-NOT: Skipping VMP on protected_fptosi_i16:
; SKIP-NOT: Skipping VMP on protected_fptoui_i16:
; SKIP-NOT: Skipping VMP on protected_fptosi_i32:
; SKIP-NOT: Skipping VMP on protected_fptoui_i32:
; SKIP-NOT: Skipping VMP on protected_fptosi_i64:
; SKIP-NOT: Skipping VMP on protected_fptoui_i64:
; SKIP-NOT: Skipping VMP on protected_fptosi_neg:
; SKIP-NOT: Skipping VMP on protected_fptoui_neg:
; SKIP-NOT: Skipping VMP on protected_fptosi_overflow:
; SKIP-NOT: Skipping VMP on protected_last_token:
; SKIP-NOT: Skipping VMP on protected_fptosi_v4i8:
; SKIP-NOT: Skipping VMP on protected_fptosi_v4i32:
; SKIP-NOT: Skipping VMP on protected_fptoui_v4i32:
; SKIP-NOT: Skipping VMP on protected_fptosi_v2i64:
; SKIP-NOT: Skipping VMP on protected_fptoui_v8i16:

; VIRT: define i8 @protected_fptosi_i8({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.fptosi.sat.{{.*}}bf16
; VIRT: call i8 @llvm.fptosi.sat.i8.f32
; VIRT: define i8 @protected_fptoui_i8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.fptoui.sat.{{.*}}bf16
; VIRT: call i8 @llvm.fptoui.sat.i8.f32
; VIRT: define i16 @protected_fptosi_i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i16 @llvm.fptosi.sat.i16.f32
; VIRT: define i16 @protected_fptoui_i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i16 @llvm.fptoui.sat.i16.f32
; VIRT: define i32 @protected_fptosi_i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.fptosi.sat.i32.f32
; VIRT: define i32 @protected_fptoui_i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.fptoui.sat.i32.f32
; VIRT: define i64 @protected_fptosi_i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.fptosi.sat.i64.f32
; VIRT: define i64 @protected_fptoui_i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.fptoui.sat.i64.f32
; Constant sat may fold at O2 before VMP; still virtualized, no native bf16.
; VIRT: define i8 @protected_fptosi_neg({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.fptosi.sat.{{.*}}bf16
; VIRT: define i8 @protected_fptoui_neg({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.fptoui.sat.{{.*}}bf16
; VIRT: define i8 @protected_fptosi_overflow({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.fptosi.sat.{{.*}}bf16
; VIRT: define i32 @protected_last_token({{.*}} #[[PROTLAST:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.fptosi.sat.i32.f32
; VIRT: define <4 x i8> @protected_fptosi_v4i8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.fptosi.sat.v4i8.v4bf16
; VIRT: call i8 @llvm.fptosi.sat.i8.f32
; VIRT: define <4 x i32> @protected_fptosi_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.fptosi.sat.v4i32.v4bf16
; VIRT: call i32 @llvm.fptosi.sat.i32.f32
; VIRT: define <4 x i32> @protected_fptoui_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.fptoui.sat.i32.f32
; VIRT: define <2 x i64> @protected_fptosi_v2i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.fptosi.sat.i64.f32
; VIRT: define <8 x i16> @protected_fptoui_v8i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i16 @llvm.fptoui.sat.i16.f32
; VIRT: define {{.*}} @unsupported_fptosi_no_feature({{.*}} #[[UNSUPFEAT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fptoui_disabled({{.*}} #[[UNSUPDIS:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fptosi_i1({{.*}} #[[UNSUPCALL:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fptosi_i128({{.*}} #[[UNSUPCALL]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fptosi_poison({{.*}} #[[UNSUPCALL]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fptosi_v4i64({{.*}} #[[UNSUPCALL]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fptosi_v4_no_feature({{.*}} #[[UNSUPFEAT]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_sat_v16({{.*}} #[[UNSUPCALL]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[PROTLAST]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPFEAT]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT: attributes #[[UNSUPDIS]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT: attributes #[[UNSUPCALL]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPFEAT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPDIS]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPCALL]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
