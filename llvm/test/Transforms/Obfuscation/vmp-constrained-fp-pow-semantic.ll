; Restricted scalar llvm.experimental.constrained.pow (two same-type
; f32/f64 + round/except MDString) and powi (f32/f64 base, ordinary
; i32 exponent + round/except).  Tokens match the existing
; constrained-arith set.  Replayed via CallDescriptor
; MetadataArguments as identical MetadataAsValue MDStrings.  No FMF
; and no dedicated VM opcode.  Ordinary tail degrades to a normal
; call.  Protected functions carry strictfp.  Does not change
; ordinary pow/powi.  Adjacent C constrained.pow sentinels were
; retargeted to fastcc.  Well-shaped half without last-token
; +fullfp16 uses the shared half constrained feature-gate
; ("unsupported target feature").
;
; Host lli is not a strictfp environment and is not a semantic oracle.
; FileCheck + AArch64 llc/readobj only.
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
declare float @llvm.experimental.constrained.pow.f32(float, float, metadata, metadata)
declare float @llvm.experimental.constrained.powi.f32(float, i32, metadata, metadata)
declare double @llvm.experimental.constrained.pow.f64(double, double, metadata, metadata)
declare double @llvm.experimental.constrained.powi.f64(double, i32, metadata, metadata)
declare half @llvm.experimental.constrained.pow.f16(half, half, metadata, metadata)
declare bfloat @llvm.experimental.constrained.pow.bf16(bfloat, bfloat, metadata, metadata)
declare fp128 @llvm.experimental.constrained.pow.f128(fp128, fp128, metadata, metadata)
declare float @llvm.experimental.constrained.fadd.f32(float, float, metadata, metadata)

declare <2 x half> @llvm.experimental.constrained.pow.v2f16(<2 x half>, <2 x half>, metadata, metadata)

define float @protected_cpow_nearest_f32(float %a, float %b) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.experimental.constrained.pow.f32(float %a, float %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret float %r
}

define float @protected_cpow_dyn_f32(float %a, float %b) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.experimental.constrained.pow.f32(float %a, float %b, metadata !"round.dynamic", metadata !"fpexcept.maytrap")
  ret float %r
}

define float @protected_cpow_down_f32(float %a, float %b) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.experimental.constrained.pow.f32(float %a, float %b, metadata !"round.downward", metadata !"fpexcept.strict")
  ret float %r
}

define float @protected_cpowi_up_f32(float %a, i32 %e) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.experimental.constrained.powi.f32(float %a, i32 %e, metadata !"round.upward", metadata !"fpexcept.ignore")
  ret float %r
}

define float @protected_cpowi_imm_f32(float %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.experimental.constrained.powi.f32(float %a, i32 3, metadata !"round.towardzero", metadata !"fpexcept.ignore")
  ret float %r
}

define double @protected_cpow_f64(double %a, double %b) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call double @llvm.experimental.constrained.pow.f64(double %a, double %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret double %r
}

define double @protected_cpowi_f64(double %a, i32 %e) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call double @llvm.experimental.constrained.powi.f64(double %a, i32 %e, metadata !"round.dynamic", metadata !"fpexcept.maytrap")
  ret double %r
}


define float @protected_cpow_phi_f32(float %a, float %b, i1 %c) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  br i1 %c, label %left, label %right
left:
  %l = call float @llvm.experimental.constrained.pow.f32(float %a, float %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  br label %join
right:
  %r = call float @llvm.experimental.constrained.powi.f32(float %a, i32 2, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  br label %join
join:
  %p = phi float [ %l, %left ], [ %r, %right ]
  ret float %p
}

define float @protected_cpow_loop_f32(float %a, float %b, i32 %n) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  br label %hdr
hdr:
  %acc = phi float [ %a, %entry ], [ %nxt, %hdr ]
  %i = phi i32 [ 0, %entry ], [ %i.nxt, %hdr ]
  %cur = call float @llvm.experimental.constrained.pow.f32(float %acc, float %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  %nxt = call float @llvm.experimental.constrained.fadd.f32(float %acc, float 1.000000e+00, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  %i.nxt = add i32 %i, 1
  %more = icmp ult i32 %i.nxt, %n
  br i1 %more, label %hdr, label %done
done:
  ret float %cur
}

define half @unsupported_cpow_half(half %a, half %b) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.experimental.constrained.pow.f16(half %a, half %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret half %r
}

define bfloat @unsupported_cpow_bfloat(bfloat %a, bfloat %b) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.experimental.constrained.pow.bf16(bfloat %a, bfloat %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret bfloat %r
}

define fp128 @unsupported_cpow_fp128(fp128 %a, fp128 %b) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call fp128 @llvm.experimental.constrained.pow.f128(fp128 %a, fp128 %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret fp128 %r
}

define <2 x half> @unsupported_cpow_vector(<2 x half> %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call <2 x half> @llvm.experimental.constrained.pow.v2f16(<2 x half> %a, <2 x half> %a, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret <2 x half> %r
}

define float @unsupported_cpow_fastcc(float %a, float %b) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call fastcc float @llvm.experimental.constrained.pow.f32(float %a, float %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret float %r
}

define float @unsupported_cpow_musttail(float %a, float %b) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = musttail call float @llvm.experimental.constrained.pow.f32(float %a, float %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret float %r
}

define float @unsupported_cpow_bundle(float %a, float %b) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.experimental.constrained.pow.f32(float %a, float %b, metadata !"round.tonearest", metadata !"fpexcept.ignore") [ "deopt"(i32 0) ]
  ret float %r
}

define float @unsupported_cpow_poison(float %b) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.experimental.constrained.pow.f32(float poison, float %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret float %r
}

define float @unsupported_cpow_undef(float %b) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.experimental.constrained.pow.f32(float undef, float %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret float %r
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_cpow_half: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_cpow_bfloat: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_cpow_fp128: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_cpow_vector: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_cpow_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_cpow_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_cpow_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_cpow_poison: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_cpow_undef: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_cpow_nearest_f32:
; SKIP-NOT: Skipping VMP on protected_cpow_dyn_f32:
; SKIP-NOT: Skipping VMP on protected_cpow_down_f32:
; SKIP-NOT: Skipping VMP on protected_cpowi_up_f32:
; SKIP-NOT: Skipping VMP on protected_cpowi_imm_f32:
; SKIP-NOT: Skipping VMP on protected_cpow_f64:
; SKIP-NOT: Skipping VMP on protected_cpowi_f64:
; SKIP-NOT: Skipping VMP on protected_cpow_phi_f32:
; SKIP-NOT: Skipping VMP on protected_cpow_loop_f32:

; VIRT: define float @protected_cpow_nearest_f32({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.experimental.constrained.pow.f32({{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")
; VIRT: define float @protected_cpow_dyn_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.experimental.constrained.pow.f32({{.*}}, metadata !"round.dynamic", metadata !"fpexcept.maytrap")
; VIRT: define float @protected_cpow_down_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.experimental.constrained.pow.f32({{.*}}, metadata !"round.downward", metadata !"fpexcept.strict")
; VIRT: define float @protected_cpowi_up_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.experimental.constrained.powi.f32({{.*}}, metadata !"round.upward", metadata !"fpexcept.ignore")
; VIRT: define float @protected_cpowi_imm_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.experimental.constrained.powi.f32({{.*}}, metadata !"round.towardzero", metadata !"fpexcept.ignore")
; VIRT: define double @protected_cpow_f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call double @llvm.experimental.constrained.pow.f64({{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")
; VIRT: define double @protected_cpowi_f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call double @llvm.experimental.constrained.powi.f64({{.*}}, metadata !"round.dynamic", metadata !"fpexcept.maytrap")
; VIRT: define float @protected_cpow_phi_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.experimental.constrained.pow.f32({{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")
; VIRT: define float @protected_cpow_loop_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.experimental.constrained.pow.f32({{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")
; VIRT: define {{.*}} @unsupported_cpow_half({{.*}} #[[UNSUPCC:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cpow_bfloat({{.*}} #[[UNSUP_ARG:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cpow_fp128({{.*}} #[[UNSUP_ARG]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cpow_vector({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cpow_fastcc({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cpow_musttail({{.*}} #[[UNSUP_MT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call float @llvm.experimental.constrained.pow.f32(
; VIRT: define {{.*}} @unsupported_cpow_bundle({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call float @llvm.experimental.constrained.pow.f32({{.*}}[ "deopt"(i32 0) ]
; VIRT: define {{.*}} @unsupported_cpow_poison({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cpow_undef({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPCC]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPCC]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_MT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_ARG]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
