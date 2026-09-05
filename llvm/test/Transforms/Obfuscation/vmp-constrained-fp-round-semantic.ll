; Restricted scalar llvm.experimental.constrained.ceil/floor/trunc/
; round/roundeven (one f32/f64 + fpexcept MDString) and rint/nearbyint
; (same-type f32/f64 + round and fpexcept MDString).  Tokens match the
; existing constrained-arith set.  Replayed via CallDescriptor
; MetadataArguments as identical MetadataAsValue MDStrings.  No FMF
; and no dedicated VM opcode.  Ordinary tail degrades to a normal
; call.  Protected functions carry strictfp.  Well-shaped half
; without last-token +fullfp16 uses the shared half constrained
; feature-gate ("unsupported target feature").
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
declare float @llvm.experimental.constrained.ceil.f32(float, metadata)
declare float @llvm.experimental.constrained.floor.f32(float, metadata)
declare float @llvm.experimental.constrained.trunc.f32(float, metadata)
declare float @llvm.experimental.constrained.round.f32(float, metadata)
declare float @llvm.experimental.constrained.roundeven.f32(float, metadata)
declare float @llvm.experimental.constrained.rint.f32(float, metadata, metadata)
declare float @llvm.experimental.constrained.nearbyint.f32(float, metadata, metadata)
declare double @llvm.experimental.constrained.ceil.f64(double, metadata)
declare double @llvm.experimental.constrained.floor.f64(double, metadata)
declare double @llvm.experimental.constrained.trunc.f64(double, metadata)
declare double @llvm.experimental.constrained.round.f64(double, metadata)
declare double @llvm.experimental.constrained.roundeven.f64(double, metadata)
declare double @llvm.experimental.constrained.rint.f64(double, metadata, metadata)
declare double @llvm.experimental.constrained.nearbyint.f64(double, metadata, metadata)
declare half @llvm.experimental.constrained.ceil.f16(half, metadata)
declare bfloat @llvm.experimental.constrained.ceil.bf16(bfloat, metadata)
declare fp128 @llvm.experimental.constrained.ceil.f128(fp128, metadata)

declare <2 x half> @llvm.experimental.constrained.pow.v2f16(<2 x half>, <2 x half>, metadata, metadata)

define float @protected_cceil_f32(float %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.experimental.constrained.ceil.f32(float %a, metadata !"fpexcept.ignore")
  ret float %r
}

define float @protected_cfloor_f32(float %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.experimental.constrained.floor.f32(float %a, metadata !"fpexcept.maytrap")
  ret float %r
}

define float @protected_ctrunc_f32(float %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.experimental.constrained.trunc.f32(float %a, metadata !"fpexcept.strict")
  ret float %r
}

define float @protected_cround_f32(float %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.experimental.constrained.round.f32(float %a, metadata !"fpexcept.ignore")
  ret float %r
}

define float @protected_croundeven_f32(float %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.experimental.constrained.roundeven.f32(float %a, metadata !"fpexcept.maytrap")
  ret float %r
}

define float @protected_crint_nearest_f32(float %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.experimental.constrained.rint.f32(float %a, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret float %r
}

define float @protected_crint_dyn_f32(float %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.experimental.constrained.rint.f32(float %a, metadata !"round.dynamic", metadata !"fpexcept.maytrap")
  ret float %r
}

define float @protected_cnearbyint_down_f32(float %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.experimental.constrained.nearbyint.f32(float %a, metadata !"round.downward", metadata !"fpexcept.strict")
  ret float %r
}

define float @protected_cnearbyint_up_f32(float %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.experimental.constrained.nearbyint.f32(float %a, metadata !"round.upward", metadata !"fpexcept.ignore")
  ret float %r
}

define float @protected_crint_zero_f32(float %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.experimental.constrained.rint.f32(float %a, metadata !"round.towardzero", metadata !"fpexcept.ignore")
  ret float %r
}

define double @protected_cceil_f64(double %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call double @llvm.experimental.constrained.ceil.f64(double %a, metadata !"fpexcept.ignore")
  ret double %r
}

define double @protected_cfloor_f64(double %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call double @llvm.experimental.constrained.floor.f64(double %a, metadata !"fpexcept.maytrap")
  ret double %r
}

define double @protected_ctrunc_f64(double %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call double @llvm.experimental.constrained.trunc.f64(double %a, metadata !"fpexcept.strict")
  ret double %r
}

define double @protected_cround_f64(double %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call double @llvm.experimental.constrained.round.f64(double %a, metadata !"fpexcept.ignore")
  ret double %r
}

define double @protected_croundeven_f64(double %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call double @llvm.experimental.constrained.roundeven.f64(double %a, metadata !"fpexcept.ignore")
  ret double %r
}

define double @protected_crint_f64(double %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call double @llvm.experimental.constrained.rint.f64(double %a, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret double %r
}

define double @protected_cnearbyint_f64(double %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call double @llvm.experimental.constrained.nearbyint.f64(double %a, metadata !"round.dynamic", metadata !"fpexcept.maytrap")
  ret double %r
}


define float @protected_cceil_phi_f32(float %a, float %b, i1 %c) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  br i1 %c, label %left, label %right
left:
  %l = call float @llvm.experimental.constrained.ceil.f32(float %a, metadata !"fpexcept.ignore")
  br label %join
right:
  %r = call float @llvm.experimental.constrained.floor.f32(float %b, metadata !"fpexcept.ignore")
  br label %join
join:
  %p = phi float [ %l, %left ], [ %r, %right ]
  ret float %p
}

define float @protected_cceil_loop_f32(float %a, i32 %n) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  br label %hdr
hdr:
  %acc = phi float [ %a, %entry ], [ %nxt, %hdr ]
  %i = phi i32 [ 0, %entry ], [ %i.nxt, %hdr ]
  %cur = call float @llvm.experimental.constrained.ceil.f32(float %acc, metadata !"fpexcept.ignore")
  %nxt = call float @llvm.experimental.constrained.floor.f32(float %acc, metadata !"fpexcept.ignore")
  %i.nxt = add i32 %i, 1
  %more = icmp ult i32 %i.nxt, %n
  br i1 %more, label %hdr, label %done
done:
  ret float %cur
}

define half @unsupported_cceil_half(half %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.experimental.constrained.ceil.f16(half %a, metadata !"fpexcept.ignore")
  ret half %r
}

define bfloat @unsupported_cceil_bfloat(bfloat %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.experimental.constrained.ceil.bf16(bfloat %a, metadata !"fpexcept.ignore")
  ret bfloat %r
}

define fp128 @unsupported_cceil_fp128(fp128 %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call fp128 @llvm.experimental.constrained.ceil.f128(fp128 %a, metadata !"fpexcept.ignore")
  ret fp128 %r
}

define <2 x half> @unsupported_cceil_vector(<2 x half> %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call <2 x half> @llvm.experimental.constrained.pow.v2f16(<2 x half> %a, <2 x half> %a, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret <2 x half> %r
}

define float @unsupported_cceil_fastcc(float %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call fastcc float @llvm.experimental.constrained.ceil.f32(float %a, metadata !"fpexcept.ignore")
  ret float %r
}

define float @unsupported_cceil_musttail(float %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = musttail call float @llvm.experimental.constrained.ceil.f32(float %a, metadata !"fpexcept.ignore")
  ret float %r
}

define float @unsupported_cceil_bundle(float %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.experimental.constrained.ceil.f32(float %a, metadata !"fpexcept.ignore") [ "deopt"(i32 0) ]
  ret float %r
}

define float @unsupported_cceil_poison() noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.experimental.constrained.ceil.f32(float poison, metadata !"fpexcept.ignore")
  ret float %r
}

define float @unsupported_cceil_undef() noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.experimental.constrained.ceil.f32(float undef, metadata !"fpexcept.ignore")
  ret float %r
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_cceil_half: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_cceil_bfloat: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_cceil_fp128: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_cceil_vector: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_cceil_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_cceil_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_cceil_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_cceil_poison: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_cceil_undef: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_cceil_f32:
; SKIP-NOT: Skipping VMP on protected_cfloor_f32:
; SKIP-NOT: Skipping VMP on protected_ctrunc_f32:
; SKIP-NOT: Skipping VMP on protected_cround_f32:
; SKIP-NOT: Skipping VMP on protected_croundeven_f32:
; SKIP-NOT: Skipping VMP on protected_crint_nearest_f32:
; SKIP-NOT: Skipping VMP on protected_crint_dyn_f32:
; SKIP-NOT: Skipping VMP on protected_cnearbyint_down_f32:
; SKIP-NOT: Skipping VMP on protected_cnearbyint_up_f32:
; SKIP-NOT: Skipping VMP on protected_crint_zero_f32:
; SKIP-NOT: Skipping VMP on protected_cceil_f64:
; SKIP-NOT: Skipping VMP on protected_cfloor_f64:
; SKIP-NOT: Skipping VMP on protected_ctrunc_f64:
; SKIP-NOT: Skipping VMP on protected_cround_f64:
; SKIP-NOT: Skipping VMP on protected_croundeven_f64:
; SKIP-NOT: Skipping VMP on protected_crint_f64:
; SKIP-NOT: Skipping VMP on protected_cnearbyint_f64:
; SKIP-NOT: Skipping VMP on protected_cceil_phi_f32:
; SKIP-NOT: Skipping VMP on protected_cceil_loop_f32:

; VIRT: define float @protected_cceil_f32({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.experimental.constrained.ceil.f32({{.*}}, metadata !"fpexcept.ignore")
; VIRT: define float @protected_cfloor_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.experimental.constrained.floor.f32({{.*}}, metadata !"fpexcept.maytrap")
; VIRT: define float @protected_ctrunc_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.experimental.constrained.trunc.f32({{.*}}, metadata !"fpexcept.strict")
; VIRT: define float @protected_cround_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.experimental.constrained.round.f32({{.*}}, metadata !"fpexcept.ignore")
; VIRT: define float @protected_croundeven_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.experimental.constrained.roundeven.f32({{.*}}, metadata !"fpexcept.maytrap")
; VIRT: define float @protected_crint_nearest_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.experimental.constrained.rint.f32({{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")
; VIRT: define float @protected_crint_dyn_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.experimental.constrained.rint.f32({{.*}}, metadata !"round.dynamic", metadata !"fpexcept.maytrap")
; VIRT: define float @protected_cnearbyint_down_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.experimental.constrained.nearbyint.f32({{.*}}, metadata !"round.downward", metadata !"fpexcept.strict")
; VIRT: define float @protected_cnearbyint_up_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.experimental.constrained.nearbyint.f32({{.*}}, metadata !"round.upward", metadata !"fpexcept.ignore")
; VIRT: define float @protected_crint_zero_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.experimental.constrained.rint.f32({{.*}}, metadata !"round.towardzero", metadata !"fpexcept.ignore")
; VIRT: define double @protected_cceil_f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call double @llvm.experimental.constrained.ceil.f64({{.*}}, metadata !"fpexcept.ignore")
; VIRT: define double @protected_cfloor_f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call double @llvm.experimental.constrained.floor.f64({{.*}}, metadata !"fpexcept.maytrap")
; VIRT: define double @protected_ctrunc_f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call double @llvm.experimental.constrained.trunc.f64({{.*}}, metadata !"fpexcept.strict")
; VIRT: define double @protected_cround_f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call double @llvm.experimental.constrained.round.f64({{.*}}, metadata !"fpexcept.ignore")
; VIRT: define double @protected_croundeven_f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call double @llvm.experimental.constrained.roundeven.f64({{.*}}, metadata !"fpexcept.ignore")
; VIRT: define double @protected_crint_f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call double @llvm.experimental.constrained.rint.f64({{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")
; VIRT: define double @protected_cnearbyint_f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call double @llvm.experimental.constrained.nearbyint.f64({{.*}}, metadata !"round.dynamic", metadata !"fpexcept.maytrap")
; VIRT: define float @protected_cceil_phi_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.experimental.constrained.ceil.f32({{.*}}, metadata !"fpexcept.ignore")
; VIRT: define float @protected_cceil_loop_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.experimental.constrained.ceil.f32({{.*}}, metadata !"fpexcept.ignore")
; VIRT: define {{.*}} @unsupported_cceil_half({{.*}} #[[UNSUPCC:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cceil_bfloat({{.*}} #[[UNSUP_ARG:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cceil_fp128({{.*}} #[[UNSUP_ARG]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cceil_vector({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cceil_fastcc({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cceil_musttail({{.*}} #[[UNSUP_MT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call float @llvm.experimental.constrained.ceil.f32(
; VIRT: define {{.*}} @unsupported_cceil_bundle({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call float @llvm.experimental.constrained.ceil.f32({{.*}}[ "deopt"(i32 0) ]
; VIRT: define {{.*}} @unsupported_cceil_poison({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cceil_undef({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPCC]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPCC]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_MT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_ARG]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
