; Restricted fixed 1..128 llvm.experimental.constrained
; ceil/floor/trunc/round/roundeven (one f32/f64 vector + fpexcept)
; and rint/nearbyint (same-type vector + round and fpexcept).
; Same MDString tokens as the scalar constrained rounding surface.
; Replayed via CallDescriptor MetadataArguments.  Does not change
; scalar constrained rounding or add a VM opcode.  No +fullfp16
; gate on f32/f64.  Well-shaped half-vector ceil without last-token
; +fullfp16 is "unsupported target feature".  Ordinary tail
; degrades to a normal call.  Host lli is not a strictfp oracle:
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
declare <2 x float> @llvm.experimental.constrained.ceil.v2f32(<2 x float>, metadata)
declare <2 x float> @llvm.experimental.constrained.floor.v2f32(<2 x float>, metadata)
declare <2 x float> @llvm.experimental.constrained.trunc.v2f32(<2 x float>, metadata)
declare <2 x float> @llvm.experimental.constrained.round.v2f32(<2 x float>, metadata)
declare <2 x float> @llvm.experimental.constrained.roundeven.v2f32(<2 x float>, metadata)
declare <2 x float> @llvm.experimental.constrained.rint.v2f32(<2 x float>, metadata, metadata)
declare <2 x float> @llvm.experimental.constrained.nearbyint.v2f32(<2 x float>, metadata, metadata)
declare <3 x float> @llvm.experimental.constrained.ceil.v3f32(<3 x float>, metadata)
declare <2 x double> @llvm.experimental.constrained.ceil.v2f64(<2 x double>, metadata)
declare <2 x float> @llvm.experimental.constrained.fadd.v2f32(<2 x float>, <2 x float>, metadata, metadata)
declare <2 x half> @llvm.experimental.constrained.ceil.v2f16(<2 x half>, metadata)
declare <8 x double> @llvm.experimental.constrained.ceil.v8f64(<8 x double>, metadata)
declare <vscale x 2 x float> @llvm.experimental.constrained.ceil.nxv2f32(<vscale x 2 x float>, metadata)

declare <2 x half> @llvm.experimental.constrained.pow.v2f16(<2 x half>, <2 x half>, metadata, metadata)

define <2 x float> @protected_cceil_v2f32(<2 x float> %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.experimental.constrained.ceil.v2f32(<2 x float> %a, metadata !"fpexcept.ignore")
  ret <2 x float> %r
}

define <2 x float> @protected_cfloor_v2f32(<2 x float> %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.experimental.constrained.floor.v2f32(<2 x float> %a, metadata !"fpexcept.maytrap")
  ret <2 x float> %r
}

define <2 x float> @protected_ctrunc_v2f32(<2 x float> %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.experimental.constrained.trunc.v2f32(<2 x float> %a, metadata !"fpexcept.strict")
  ret <2 x float> %r
}

define <2 x float> @protected_cround_v2f32(<2 x float> %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.experimental.constrained.round.v2f32(<2 x float> %a, metadata !"fpexcept.ignore")
  ret <2 x float> %r
}

define <2 x float> @protected_croundeven_v2f32(<2 x float> %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.experimental.constrained.roundeven.v2f32(<2 x float> %a, metadata !"fpexcept.maytrap")
  ret <2 x float> %r
}

define <2 x float> @protected_crint_nearest_v2f32(<2 x float> %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.experimental.constrained.rint.v2f32(<2 x float> %a, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret <2 x float> %r
}

define <2 x float> @protected_crint_dyn_v2f32(<2 x float> %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.experimental.constrained.rint.v2f32(<2 x float> %a, metadata !"round.dynamic", metadata !"fpexcept.maytrap")
  ret <2 x float> %r
}

define <2 x float> @protected_cnearbyint_down_v2f32(<2 x float> %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.experimental.constrained.nearbyint.v2f32(<2 x float> %a, metadata !"round.downward", metadata !"fpexcept.strict")
  ret <2 x float> %r
}

define <2 x float> @protected_cnearbyint_up_v2f32(<2 x float> %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.experimental.constrained.nearbyint.v2f32(<2 x float> %a, metadata !"round.upward", metadata !"fpexcept.ignore")
  ret <2 x float> %r
}

define <2 x float> @protected_crint_zero_v2f32(<2 x float> %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.experimental.constrained.rint.v2f32(<2 x float> %a, metadata !"round.towardzero", metadata !"fpexcept.ignore")
  ret <2 x float> %r
}

define <3 x float> @protected_cceil_v3f32(<3 x float> %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call <3 x float> @llvm.experimental.constrained.ceil.v3f32(<3 x float> %a, metadata !"fpexcept.ignore")
  ret <3 x float> %r
}

define <2 x double> @protected_cceil_v2f64(<2 x double> %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call <2 x double> @llvm.experimental.constrained.ceil.v2f64(<2 x double> %a, metadata !"fpexcept.strict")
  ret <2 x double> %r
}


define <2 x float> @protected_cceil_phi_v2f32(<2 x float> %a, <2 x float> %b, i1 %p) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  br i1 %p, label %left, label %right
left:
  %l = call <2 x float> @llvm.experimental.constrained.ceil.v2f32(<2 x float> %a, metadata !"fpexcept.ignore")
  br label %join
right:
  %r = call <2 x float> @llvm.experimental.constrained.floor.v2f32(<2 x float> %b, metadata !"fpexcept.ignore")
  br label %join
join:
  %q = phi <2 x float> [ %l, %left ], [ %r, %right ]
  ret <2 x float> %q
}

define <2 x float> @protected_cceil_loop_v2f32(<2 x float> %a, i32 %n) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  br label %hdr
hdr:
  %acc = phi <2 x float> [ %a, %entry ], [ %nxt, %hdr ]
  %i = phi i32 [ 0, %entry ], [ %i.nxt, %hdr ]
  %cur = call <2 x float> @llvm.experimental.constrained.ceil.v2f32(<2 x float> %acc, metadata !"fpexcept.ignore")
  %nxt = call <2 x float> @llvm.experimental.constrained.fadd.v2f32(<2 x float> %acc, <2 x float> <float 1.000000e+00, float 1.000000e+00>, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  %i.nxt = add i32 %i, 1
  %more = icmp ult i32 %i.nxt, %n
  br i1 %more, label %hdr, label %done
done:
  ret <2 x float> %cur
}

define <2 x half> @unsupported_cceil_v2f16(<2 x half> %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call <2 x half> @llvm.experimental.constrained.ceil.v2f16(<2 x half> %a, metadata !"fpexcept.ignore")
  ret <2 x half> %r
}

define <8 x double> @unsupported_cceil_wide(<8 x double> %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call <8 x double> @llvm.experimental.constrained.ceil.v8f64(<8 x double> %a, metadata !"fpexcept.ignore")
  ret <8 x double> %r
}

define <vscale x 2 x float> @unsupported_cceil_scalable(<vscale x 2 x float> %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 2 x float> @llvm.experimental.constrained.ceil.nxv2f32(<vscale x 2 x float> %a, metadata !"fpexcept.ignore")
  ret <vscale x 2 x float> %r
}

define <2 x half> @unsupported_cminnum_v2f32(<2 x half> %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call <2 x half> @llvm.experimental.constrained.pow.v2f16(<2 x half> %a, <2 x half> %a, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret <2 x half> %r
}

define <2 x float> @unsupported_cceil_fastcc(<2 x float> %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call fastcc <2 x float> @llvm.experimental.constrained.ceil.v2f32(<2 x float> %a, metadata !"fpexcept.ignore")
  ret <2 x float> %r
}

define <2 x float> @unsupported_cceil_musttail(<2 x float> %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = musttail call <2 x float> @llvm.experimental.constrained.ceil.v2f32(<2 x float> %a, metadata !"fpexcept.ignore")
  ret <2 x float> %r
}

define <2 x float> @unsupported_cceil_bundle(<2 x float> %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.experimental.constrained.ceil.v2f32(<2 x float> %a, metadata !"fpexcept.ignore") [ "deopt"(i32 0) ]
  ret <2 x float> %r
}

define <2 x float> @unsupported_cceil_poison() noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.experimental.constrained.ceil.v2f32(<2 x float> poison, metadata !"fpexcept.ignore")
  ret <2 x float> %r
}

define <2 x float> @unsupported_cceil_undef() noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.experimental.constrained.ceil.v2f32(<2 x float> undef, metadata !"fpexcept.ignore")
  ret <2 x float> %r
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_cceil_v2f16: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_cceil_wide: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_cceil_scalable: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_cminnum_v2f32: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_cceil_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_cceil_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_cceil_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_cceil_poison: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_cceil_undef: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_cceil_v2f32:
; SKIP-NOT: Skipping VMP on protected_cfloor_v2f32:
; SKIP-NOT: Skipping VMP on protected_ctrunc_v2f32:
; SKIP-NOT: Skipping VMP on protected_cround_v2f32:
; SKIP-NOT: Skipping VMP on protected_croundeven_v2f32:
; SKIP-NOT: Skipping VMP on protected_crint_nearest_v2f32:
; SKIP-NOT: Skipping VMP on protected_crint_dyn_v2f32:
; SKIP-NOT: Skipping VMP on protected_cnearbyint_down_v2f32:
; SKIP-NOT: Skipping VMP on protected_cnearbyint_up_v2f32:
; SKIP-NOT: Skipping VMP on protected_crint_zero_v2f32:
; SKIP-NOT: Skipping VMP on protected_cceil_v3f32:
; SKIP-NOT: Skipping VMP on protected_cceil_v2f64:
; SKIP-NOT: Skipping VMP on protected_cceil_phi_v2f32:
; SKIP-NOT: Skipping VMP on protected_cceil_loop_v2f32:

; VIRT: define <2 x float> @protected_cceil_v2f32({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x float> @llvm.experimental.constrained.ceil.v2f32({{.*}}, metadata !"fpexcept.ignore")
; VIRT: define <2 x float> @protected_cfloor_v2f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x float> @llvm.experimental.constrained.floor.v2f32({{.*}}, metadata !"fpexcept.maytrap")
; VIRT: define <2 x float> @protected_ctrunc_v2f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x float> @llvm.experimental.constrained.trunc.v2f32({{.*}}, metadata !"fpexcept.strict")
; VIRT: define <2 x float> @protected_cround_v2f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x float> @llvm.experimental.constrained.round.v2f32({{.*}}, metadata !"fpexcept.ignore")
; VIRT: define <2 x float> @protected_croundeven_v2f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x float> @llvm.experimental.constrained.roundeven.v2f32({{.*}}, metadata !"fpexcept.maytrap")
; VIRT: define <2 x float> @protected_crint_nearest_v2f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x float> @llvm.experimental.constrained.rint.v2f32({{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")
; VIRT: define <2 x float> @protected_crint_dyn_v2f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x float> @llvm.experimental.constrained.rint.v2f32({{.*}}, metadata !"round.dynamic", metadata !"fpexcept.maytrap")
; VIRT: define <2 x float> @protected_cnearbyint_down_v2f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x float> @llvm.experimental.constrained.nearbyint.v2f32({{.*}}, metadata !"round.downward", metadata !"fpexcept.strict")
; VIRT: define <2 x float> @protected_cnearbyint_up_v2f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x float> @llvm.experimental.constrained.nearbyint.v2f32({{.*}}, metadata !"round.upward", metadata !"fpexcept.ignore")
; VIRT: define <2 x float> @protected_crint_zero_v2f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x float> @llvm.experimental.constrained.rint.v2f32({{.*}}, metadata !"round.towardzero", metadata !"fpexcept.ignore")
; VIRT: define <3 x float> @protected_cceil_v3f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <3 x float> @llvm.experimental.constrained.ceil.v3f32({{.*}}, metadata !"fpexcept.ignore")
; VIRT: define <2 x double> @protected_cceil_v2f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x double> @llvm.experimental.constrained.ceil.v2f64({{.*}}, metadata !"fpexcept.strict")
; VIRT: define <2 x float> @protected_cceil_phi_v2f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x float> @llvm.experimental.constrained.ceil.v2f32({{.*}}, metadata !"fpexcept.ignore")
; VIRT: define <2 x float> @protected_cceil_loop_v2f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x float> @llvm.experimental.constrained.ceil.v2f32({{.*}}, metadata !"fpexcept.ignore")
; VIRT: define {{.*}} @unsupported_cceil_v2f16({{.*}} #[[UNSUPCC:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cceil_wide({{.*}} #[[UNSUP_RET:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cceil_scalable({{.*}} #[[UNSUP_RET]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cminnum_v2f32({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cceil_fastcc({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cceil_musttail({{.*}} #[[UNSUP_MT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call <2 x float> @llvm.experimental.constrained.ceil.v2f32(
; VIRT: define {{.*}} @unsupported_cceil_bundle({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call <2 x float> @llvm.experimental.constrained.ceil.v2f32({{.*}}[ "deopt"(i32 0) ]
; VIRT: define {{.*}} @unsupported_cceil_poison({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cceil_undef({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPCC]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPCC]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_MT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_RET]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
