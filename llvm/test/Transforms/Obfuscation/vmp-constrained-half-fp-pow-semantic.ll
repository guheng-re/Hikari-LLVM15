; Restricted scalar last-token +fullfp16
; llvm.experimental.constrained.pow (two IEEE half + round/except)
; and powi (half base, ordinary i32 exponent + round/except).
; Reuses the f32/f64 pow shape checker and the shared last-token
; +fullfp16 feature-gate.  Replayed via CallDescriptor
; MetadataArguments.  Constant i32 powi exponents travel through
; integer VRegs; FileCheck must not require a literal i32 immediate.
; This is the last LLVM 15 scalar half ConstrainedOps math ID.
; Does not change f32/f64 pow, other half constrained families, or
; add a VM opcode.  Missing or last-token -fullfp16 is "unsupported
; target feature".  Host lli cannot be assumed to select half
; constrained ops: FileCheck + AArch64 llc/readobj only.
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
declare half @llvm.experimental.constrained.pow.f16(half, half, metadata, metadata)
declare half @llvm.experimental.constrained.powi.f16(half, i32, metadata, metadata)
declare half @llvm.experimental.constrained.fadd.f16(half, half, metadata, metadata)
declare <2 x half> @llvm.experimental.constrained.pow.v2f16(<2 x half>, <2 x half>, metadata, metadata)

define half @protected_cpow_nearest_f16(half %a, half %b) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.experimental.constrained.pow.f16(half %a, half %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret half %r
}

define half @protected_cpow_dyn_f16(half %a, half %b) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.experimental.constrained.pow.f16(half %a, half %b, metadata !"round.dynamic", metadata !"fpexcept.maytrap")
  ret half %r
}

define half @protected_cpow_down_f16(half %a, half %b) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.experimental.constrained.pow.f16(half %a, half %b, metadata !"round.downward", metadata !"fpexcept.strict")
  ret half %r
}

define half @protected_cpowi_up_f16(half %a, i32 %e) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.experimental.constrained.powi.f16(half %a, i32 %e, metadata !"round.upward", metadata !"fpexcept.ignore")
  ret half %r
}

define half @protected_cpowi_imm_f16(half %a) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.experimental.constrained.powi.f16(half %a, i32 3, metadata !"round.towardzero", metadata !"fpexcept.ignore")
  ret half %r
}


define half @protected_cpow_phi_f16(half %a, half %b, i32 %e, i1 %p) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  br i1 %p, label %left, label %right
left:
  %l = call half @llvm.experimental.constrained.pow.f16(half %a, half %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  br label %join
right:
  %r = call half @llvm.experimental.constrained.powi.f16(half %a, i32 %e, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  br label %join
join:
  %q = phi half [ %l, %left ], [ %r, %right ]
  ret half %q
}

define half @protected_cpow_loop_f16(half %a, half %b, i32 %n) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  br label %hdr
hdr:
  %acc = phi half [ %a, %entry ], [ %nxt, %hdr ]
  %i = phi i32 [ 0, %entry ], [ %i.nxt, %hdr ]
  %cur = call half @llvm.experimental.constrained.pow.f16(half %acc, half %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  %nxt = call half @llvm.experimental.constrained.fadd.f16(half %acc, half 0xH3C00, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  %i.nxt = add i32 %i, 1
  %more = icmp ult i32 %i.nxt, %n
  br i1 %more, label %hdr, label %done
done:
  ret half %cur
}

define half @unsupported_cpow_no_fullfp16(half %a, half %b) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.experimental.constrained.pow.f16(half %a, half %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret half %r
}

define half @unsupported_cpow_fullfp16_disabled(half %a, half %b) noinline optnone strictfp "target-features"="+neon,+fullfp16,-fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.experimental.constrained.pow.f16(half %a, half %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret half %r
}

define <2 x half> @unsupported_cpow_vector(<2 x half> %a, <2 x half> %b) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <2 x half> @llvm.experimental.constrained.pow.v2f16(<2 x half> %a, <2 x half> %b, metadata !"round.tonearest", metadata !"fpexcept.ignore") [ "deopt"(i32 0) ]
  ret <2 x half> %r
}

define half @unsupported_cpow_fastcc(half %a, half %b) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call fastcc half @llvm.experimental.constrained.pow.f16(half %a, half %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret half %r
}

define half @unsupported_cpow_musttail(half %a, half %b) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = musttail call half @llvm.experimental.constrained.pow.f16(half %a, half %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret half %r
}

define half @unsupported_cpow_bundle(half %a, half %b) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.experimental.constrained.pow.f16(half %a, half %b, metadata !"round.tonearest", metadata !"fpexcept.ignore") [ "deopt"(i32 0) ]
  ret half %r
}

define half @unsupported_cpow_poison(half %b) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.experimental.constrained.pow.f16(half poison, half %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret half %r
}

define half @unsupported_cpow_undef(half %b) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.experimental.constrained.pow.f16(half undef, half %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret half %r
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_cpow_no_fullfp16: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_cpow_fullfp16_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_cpow_vector: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_cpow_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_cpow_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_cpow_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_cpow_poison: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_cpow_undef: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_cpow_nearest_f16:
; SKIP-NOT: Skipping VMP on protected_cpow_dyn_f16:
; SKIP-NOT: Skipping VMP on protected_cpow_down_f16:
; SKIP-NOT: Skipping VMP on protected_cpowi_up_f16:
; SKIP-NOT: Skipping VMP on protected_cpowi_imm_f16:
; SKIP-NOT: Skipping VMP on protected_cpow_phi_f16:
; SKIP-NOT: Skipping VMP on protected_cpow_loop_f16:

; VIRT: define half @protected_cpow_nearest_f16({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call half @llvm.experimental.constrained.pow.f16({{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")
; VIRT: define half @protected_cpow_dyn_f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call half @llvm.experimental.constrained.pow.f16({{.*}}, metadata !"round.dynamic", metadata !"fpexcept.maytrap")
; VIRT: define half @protected_cpow_down_f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call half @llvm.experimental.constrained.pow.f16({{.*}}, metadata !"round.downward", metadata !"fpexcept.strict")
; VIRT: define half @protected_cpowi_up_f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call half @llvm.experimental.constrained.powi.f16({{.*}}, metadata !"round.upward", metadata !"fpexcept.ignore")
; VIRT: define half @protected_cpowi_imm_f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call half @llvm.experimental.constrained.powi.f16({{.*}}, metadata !"round.towardzero", metadata !"fpexcept.ignore")
; VIRT: define half @protected_cpow_phi_f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call half @llvm.experimental.constrained.pow.f16({{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")
; VIRT: define half @protected_cpow_loop_f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call half @llvm.experimental.constrained.pow.f16({{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")
; VIRT: define {{.*}} @unsupported_cpow_no_fullfp16({{.*}} #[[UNSUPFEAT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cpow_fullfp16_disabled({{.*}} #[[UNSUPFEAT2:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cpow_vector({{.*}} #[[UNSUPCC:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cpow_fastcc({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cpow_musttail({{.*}} #[[UNSUP_MT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call half @llvm.experimental.constrained.pow.f16(
; VIRT: define {{.*}} @unsupported_cpow_bundle({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call half @llvm.experimental.constrained.pow.f16({{.*}}[ "deopt"(i32 0) ]
; VIRT: define {{.*}} @unsupported_cpow_poison({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cpow_undef({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPCC]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPCC]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_MT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPFEAT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPFEAT2]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
