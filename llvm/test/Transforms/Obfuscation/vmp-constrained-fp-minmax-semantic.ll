; Restricted scalar llvm.experimental.constrained.minnum/maxnum/
; minimum/maximum: two same-type f32/f64 operands plus one fpexcept
; MDString (LLVM 15 has no rounding operand).  Tokens match the
; existing constrained-arith set.  Replayed via CallDescriptor
; MetadataArguments as identical MetadataAsValue MDStrings.  No FMF
; and no dedicated VM opcode.  Ordinary tail degrades to a normal
; call.  Protected functions carry strictfp.
; Does not change ordinary minnum/maxnum/minimum/maximum.  Vector
; skip uses constrained.pow.  Well-shaped half without last-token
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
declare float @llvm.experimental.constrained.minnum.f32(float, float, metadata)
declare float @llvm.experimental.constrained.maxnum.f32(float, float, metadata)
declare float @llvm.experimental.constrained.minimum.f32(float, float, metadata)
declare float @llvm.experimental.constrained.maximum.f32(float, float, metadata)
declare double @llvm.experimental.constrained.minnum.f64(double, double, metadata)
declare double @llvm.experimental.constrained.maxnum.f64(double, double, metadata)
declare double @llvm.experimental.constrained.minimum.f64(double, double, metadata)
declare double @llvm.experimental.constrained.maximum.f64(double, double, metadata)
declare half @llvm.experimental.constrained.minnum.f16(half, half, metadata)
declare bfloat @llvm.experimental.constrained.minnum.bf16(bfloat, bfloat, metadata)
declare fp128 @llvm.experimental.constrained.minnum.f128(fp128, fp128, metadata)
declare float @llvm.experimental.constrained.fadd.f32(float, float, metadata, metadata)

declare <2 x half> @llvm.experimental.constrained.pow.v2f16(<2 x half>, <2 x half>, metadata, metadata)

define float @protected_cminnum_f32(float %a, float %b) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.experimental.constrained.minnum.f32(float %a, float %b, metadata !"fpexcept.ignore")
  ret float %r
}

define float @protected_cmaxnum_maytrap_f32(float %a, float %b) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.experimental.constrained.maxnum.f32(float %a, float %b, metadata !"fpexcept.maytrap")
  ret float %r
}

define float @protected_cminimum_strict_f32(float %a, float %b) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.experimental.constrained.minimum.f32(float %a, float %b, metadata !"fpexcept.strict")
  ret float %r
}

define float @protected_cmaximum_f32(float %a, float %b) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.experimental.constrained.maximum.f32(float %a, float %b, metadata !"fpexcept.ignore")
  ret float %r
}

define double @protected_cminnum_f64(double %a, double %b) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call double @llvm.experimental.constrained.minnum.f64(double %a, double %b, metadata !"fpexcept.ignore")
  ret double %r
}

define double @protected_cmaxnum_f64(double %a, double %b) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call double @llvm.experimental.constrained.maxnum.f64(double %a, double %b, metadata !"fpexcept.maytrap")
  ret double %r
}

define double @protected_cminimum_f64(double %a, double %b) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call double @llvm.experimental.constrained.minimum.f64(double %a, double %b, metadata !"fpexcept.strict")
  ret double %r
}

define double @protected_cmaximum_f64(double %a, double %b) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call double @llvm.experimental.constrained.maximum.f64(double %a, double %b, metadata !"fpexcept.ignore")
  ret double %r
}


define float @protected_cminnum_phi_f32(float %a, float %b, i1 %c) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  br i1 %c, label %left, label %right
left:
  %l = call float @llvm.experimental.constrained.minnum.f32(float %a, float %b, metadata !"fpexcept.ignore")
  br label %join
right:
  %r = call float @llvm.experimental.constrained.maxnum.f32(float %a, float %b, metadata !"fpexcept.ignore")
  br label %join
join:
  %p = phi float [ %l, %left ], [ %r, %right ]
  ret float %p
}

define float @protected_cminnum_loop_f32(float %a, float %b, i32 %n) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  br label %hdr
hdr:
  %acc = phi float [ %a, %entry ], [ %nxt, %hdr ]
  %i = phi i32 [ 0, %entry ], [ %i.nxt, %hdr ]
  %cur = call float @llvm.experimental.constrained.minnum.f32(float %acc, float %b, metadata !"fpexcept.ignore")
  %nxt = call float @llvm.experimental.constrained.fadd.f32(float %acc, float 1.000000e+00, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  %i.nxt = add i32 %i, 1
  %more = icmp ult i32 %i.nxt, %n
  br i1 %more, label %hdr, label %done
done:
  ret float %cur
}

define half @unsupported_cminnum_half(half %a, half %b) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.experimental.constrained.minnum.f16(half %a, half %b, metadata !"fpexcept.ignore")
  ret half %r
}

define bfloat @unsupported_cminnum_bfloat(bfloat %a, bfloat %b) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.experimental.constrained.minnum.bf16(bfloat %a, bfloat %b, metadata !"fpexcept.ignore")
  ret bfloat %r
}

define fp128 @unsupported_cminnum_fp128(fp128 %a, fp128 %b) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call fp128 @llvm.experimental.constrained.minnum.f128(fp128 %a, fp128 %b, metadata !"fpexcept.ignore")
  ret fp128 %r
}

define <2 x half> @unsupported_cminnum_vector(<2 x half> %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call <2 x half> @llvm.experimental.constrained.pow.v2f16(<2 x half> %a, <2 x half> %a, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret <2 x half> %r
}

define float @unsupported_cminnum_fastcc(float %a, float %b) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call fastcc float @llvm.experimental.constrained.minnum.f32(float %a, float %b, metadata !"fpexcept.ignore")
  ret float %r
}

define float @unsupported_cminnum_musttail(float %a, float %b) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = musttail call float @llvm.experimental.constrained.minnum.f32(float %a, float %b, metadata !"fpexcept.ignore")
  ret float %r
}

define float @unsupported_cminnum_bundle(float %a, float %b) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.experimental.constrained.minnum.f32(float %a, float %b, metadata !"fpexcept.ignore") [ "deopt"(i32 0) ]
  ret float %r
}

define float @unsupported_cminnum_poison(float %b) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.experimental.constrained.minnum.f32(float poison, float %b, metadata !"fpexcept.ignore")
  ret float %r
}

define float @unsupported_cminnum_undef(float %b) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.experimental.constrained.minnum.f32(float undef, float %b, metadata !"fpexcept.ignore")
  ret float %r
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_cminnum_half: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_cminnum_bfloat: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_cminnum_fp128: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_cminnum_vector: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_cminnum_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_cminnum_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_cminnum_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_cminnum_poison: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_cminnum_undef: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_cminnum_f32:
; SKIP-NOT: Skipping VMP on protected_cmaxnum_maytrap_f32:
; SKIP-NOT: Skipping VMP on protected_cminimum_strict_f32:
; SKIP-NOT: Skipping VMP on protected_cmaximum_f32:
; SKIP-NOT: Skipping VMP on protected_cminnum_f64:
; SKIP-NOT: Skipping VMP on protected_cmaxnum_f64:
; SKIP-NOT: Skipping VMP on protected_cminimum_f64:
; SKIP-NOT: Skipping VMP on protected_cmaximum_f64:
; SKIP-NOT: Skipping VMP on protected_cminnum_phi_f32:
; SKIP-NOT: Skipping VMP on protected_cminnum_loop_f32:

; VIRT: define float @protected_cminnum_f32({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.experimental.constrained.minnum.f32({{.*}}, metadata !"fpexcept.ignore")
; VIRT: define float @protected_cmaxnum_maytrap_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.experimental.constrained.maxnum.f32({{.*}}, metadata !"fpexcept.maytrap")
; VIRT: define float @protected_cminimum_strict_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.experimental.constrained.minimum.f32({{.*}}, metadata !"fpexcept.strict")
; VIRT: define float @protected_cmaximum_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.experimental.constrained.maximum.f32({{.*}}, metadata !"fpexcept.ignore")
; VIRT: define double @protected_cminnum_f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call double @llvm.experimental.constrained.minnum.f64({{.*}}, metadata !"fpexcept.ignore")
; VIRT: define double @protected_cmaxnum_f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call double @llvm.experimental.constrained.maxnum.f64({{.*}}, metadata !"fpexcept.maytrap")
; VIRT: define double @protected_cminimum_f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call double @llvm.experimental.constrained.minimum.f64({{.*}}, metadata !"fpexcept.strict")
; VIRT: define double @protected_cmaximum_f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call double @llvm.experimental.constrained.maximum.f64({{.*}}, metadata !"fpexcept.ignore")
; VIRT: define float @protected_cminnum_phi_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.experimental.constrained.minnum.f32({{.*}}, metadata !"fpexcept.ignore")
; VIRT: define float @protected_cminnum_loop_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.experimental.constrained.minnum.f32({{.*}}, metadata !"fpexcept.ignore")
; VIRT: define {{.*}} @unsupported_cminnum_half({{.*}} #[[UNSUPCC:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cminnum_bfloat({{.*}} #[[UNSUP_ARG:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cminnum_fp128({{.*}} #[[UNSUP_ARG]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cminnum_vector({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cminnum_fastcc({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cminnum_musttail({{.*}} #[[UNSUP_MT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call float @llvm.experimental.constrained.minnum.f32(
; VIRT: define {{.*}} @unsupported_cminnum_bundle({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call float @llvm.experimental.constrained.minnum.f32({{.*}}[ "deopt"(i32 0) ]
; VIRT: define {{.*}} @unsupported_cminnum_poison({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cminnum_undef({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPCC]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPCC]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_MT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_ARG]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
