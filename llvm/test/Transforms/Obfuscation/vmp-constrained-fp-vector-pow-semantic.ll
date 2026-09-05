; Restricted fixed 1..128 llvm.experimental.constrained.pow
; (two same-type f32/f64 vectors + round/except) and powi
; (vector base, ordinary i32 exponent + round/except).  The i32
; exponent is a VReg, not ImmArg; FileCheck must not require a
; literal i32 constant.  Same MDString tokens as the scalar
; constrained pow surface.  Replayed via CallDescriptor
; MetadataArguments.  Does not change scalar constrained pow/powi
; or add a VM opcode.  No +fullfp16 gate on f32/f64.  Well-shaped
; half-vector pow without last-token +fullfp16 is
; "unsupported target feature".  Ordinary tail degrades to a
; normal call.  Host lli is not a strictfp oracle: FileCheck +
; AArch64 llc/readobj only.
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
declare <2 x float> @llvm.experimental.constrained.pow.v2f32(<2 x float>, <2 x float>, metadata, metadata)
declare <2 x float> @llvm.experimental.constrained.powi.v2f32(<2 x float>, i32, metadata, metadata)
declare <3 x float> @llvm.experimental.constrained.pow.v3f32(<3 x float>, <3 x float>, metadata, metadata)
declare <2 x double> @llvm.experimental.constrained.pow.v2f64(<2 x double>, <2 x double>, metadata, metadata)
declare <2 x double> @llvm.experimental.constrained.powi.v2f64(<2 x double>, i32, metadata, metadata)
declare <2 x half> @llvm.experimental.constrained.pow.v2f16(<2 x half>, <2 x half>, metadata, metadata)
declare <8 x double> @llvm.experimental.constrained.pow.v8f64(<8 x double>, <8 x double>, metadata, metadata)
declare <vscale x 2 x float> @llvm.experimental.constrained.pow.nxv2f32(<vscale x 2 x float>, <vscale x 2 x float>, metadata, metadata)

define <2 x float> @protected_cpow_v2f32(<2 x float> %a, <2 x float> %b) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.experimental.constrained.pow.v2f32(<2 x float> %a, <2 x float> %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret <2 x float> %r
}

define <2 x float> @protected_cpow_dyn_v2f32(<2 x float> %a, <2 x float> %b) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.experimental.constrained.pow.v2f32(<2 x float> %a, <2 x float> %b, metadata !"round.dynamic", metadata !"fpexcept.maytrap")
  ret <2 x float> %r
}

define <2 x float> @protected_cpow_down_v2f32(<2 x float> %a, <2 x float> %b) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.experimental.constrained.pow.v2f32(<2 x float> %a, <2 x float> %b, metadata !"round.downward", metadata !"fpexcept.strict")
  ret <2 x float> %r
}

define <2 x float> @protected_cpow_up_v2f32(<2 x float> %a, <2 x float> %b) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.experimental.constrained.pow.v2f32(<2 x float> %a, <2 x float> %b, metadata !"round.upward", metadata !"fpexcept.ignore")
  ret <2 x float> %r
}

define <2 x float> @protected_cpow_zero_v2f32(<2 x float> %a, <2 x float> %b) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.experimental.constrained.pow.v2f32(<2 x float> %a, <2 x float> %b, metadata !"round.towardzero", metadata !"fpexcept.ignore")
  ret <2 x float> %r
}

define <2 x float> @protected_cpowi_runtime_v2f32(<2 x float> %a, i32 %e) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.experimental.constrained.powi.v2f32(<2 x float> %a, i32 %e, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret <2 x float> %r
}

define <2 x float> @protected_cpowi_imm_v2f32(<2 x float> %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.experimental.constrained.powi.v2f32(<2 x float> %a, i32 3, metadata !"round.dynamic", metadata !"fpexcept.maytrap")
  ret <2 x float> %r
}

define <3 x float> @protected_cpow_v3f32(<3 x float> %a, <3 x float> %b) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call <3 x float> @llvm.experimental.constrained.pow.v3f32(<3 x float> %a, <3 x float> %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret <3 x float> %r
}

define <2 x double> @protected_cpow_v2f64(<2 x double> %a, <2 x double> %b) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call <2 x double> @llvm.experimental.constrained.pow.v2f64(<2 x double> %a, <2 x double> %b, metadata !"round.tonearest", metadata !"fpexcept.strict")
  ret <2 x double> %r
}

define <2 x double> @protected_cpowi_v2f64(<2 x double> %a, i32 %e) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call <2 x double> @llvm.experimental.constrained.powi.v2f64(<2 x double> %a, i32 %e, metadata !"round.towardzero", metadata !"fpexcept.ignore")
  ret <2 x double> %r
}


define <2 x float> @protected_cpow_phi_v2f32(<2 x float> %a, <2 x float> %b, i32 %e, i1 %p) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  br i1 %p, label %left, label %right
left:
  %l = call <2 x float> @llvm.experimental.constrained.pow.v2f32(<2 x float> %a, <2 x float> %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  br label %join
right:
  %r = call <2 x float> @llvm.experimental.constrained.powi.v2f32(<2 x float> %a, i32 %e, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  br label %join
join:
  %q = phi <2 x float> [ %l, %left ], [ %r, %right ]
  ret <2 x float> %q
}

define <2 x float> @protected_cpow_loop_v2f32(<2 x float> %a, <2 x float> %b, i32 %n) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  br label %hdr
hdr:
  %acc = phi <2 x float> [ %a, %entry ], [ %cur, %hdr ]
  %i = phi i32 [ 0, %entry ], [ %i.nxt, %hdr ]
  %cur = call <2 x float> @llvm.experimental.constrained.pow.v2f32(<2 x float> %acc, <2 x float> %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  %i.nxt = add i32 %i, 1
  %more = icmp ult i32 %i.nxt, %n
  br i1 %more, label %hdr, label %done
done:
  ret <2 x float> %cur
}

define <2 x half> @unsupported_cpow_v2f16(<2 x half> %a, <2 x half> %b) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call <2 x half> @llvm.experimental.constrained.pow.v2f16(<2 x half> %a, <2 x half> %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret <2 x half> %r
}

define <8 x double> @unsupported_cpow_wide(<8 x double> %a, <8 x double> %b) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call <8 x double> @llvm.experimental.constrained.pow.v8f64(<8 x double> %a, <8 x double> %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret <8 x double> %r
}

define <vscale x 2 x float> @unsupported_cpow_scalable(<vscale x 2 x float> %a, <vscale x 2 x float> %b) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 2 x float> @llvm.experimental.constrained.pow.nxv2f32(<vscale x 2 x float> %a, <vscale x 2 x float> %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret <vscale x 2 x float> %r
}

define <2 x half> @unsupported_csin_v2f16(<2 x half> %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call <2 x half> @llvm.experimental.constrained.pow.v2f16(<2 x half> %a, <2 x half> %a, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret <2 x half> %r
}

define <2 x float> @unsupported_cpow_fastcc(<2 x float> %a, <2 x float> %b) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call fastcc <2 x float> @llvm.experimental.constrained.pow.v2f32(<2 x float> %a, <2 x float> %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret <2 x float> %r
}

define <2 x float> @unsupported_cpow_musttail(<2 x float> %a, <2 x float> %b) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = musttail call <2 x float> @llvm.experimental.constrained.pow.v2f32(<2 x float> %a, <2 x float> %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret <2 x float> %r
}

define <2 x float> @unsupported_cpow_bundle(<2 x float> %a, <2 x float> %b) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.experimental.constrained.pow.v2f32(<2 x float> %a, <2 x float> %b, metadata !"round.tonearest", metadata !"fpexcept.ignore") [ "deopt"(i32 0) ]
  ret <2 x float> %r
}

define <2 x float> @unsupported_cpow_poison(<2 x float> %b) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.experimental.constrained.pow.v2f32(<2 x float> poison, <2 x float> %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret <2 x float> %r
}

define <2 x float> @unsupported_cpow_undef(<2 x float> %b) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.experimental.constrained.pow.v2f32(<2 x float> undef, <2 x float> %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret <2 x float> %r
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_cpow_v2f16: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_cpow_wide: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_cpow_scalable: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_csin_v2f16: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_cpow_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_cpow_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_cpow_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_cpow_poison: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_cpow_undef: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_cpow_v2f32:
; SKIP-NOT: Skipping VMP on protected_cpow_dyn_v2f32:
; SKIP-NOT: Skipping VMP on protected_cpow_down_v2f32:
; SKIP-NOT: Skipping VMP on protected_cpow_up_v2f32:
; SKIP-NOT: Skipping VMP on protected_cpow_zero_v2f32:
; SKIP-NOT: Skipping VMP on protected_cpowi_runtime_v2f32:
; SKIP-NOT: Skipping VMP on protected_cpowi_imm_v2f32:
; SKIP-NOT: Skipping VMP on protected_cpow_v3f32:
; SKIP-NOT: Skipping VMP on protected_cpow_v2f64:
; SKIP-NOT: Skipping VMP on protected_cpowi_v2f64:
; SKIP-NOT: Skipping VMP on protected_cpow_phi_v2f32:
; SKIP-NOT: Skipping VMP on protected_cpow_loop_v2f32:

; VIRT: define <2 x float> @protected_cpow_v2f32({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x float> @llvm.experimental.constrained.pow.v2f32({{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")
; VIRT: define <2 x float> @protected_cpow_dyn_v2f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x float> @llvm.experimental.constrained.pow.v2f32({{.*}}, metadata !"round.dynamic", metadata !"fpexcept.maytrap")
; VIRT: define <2 x float> @protected_cpow_down_v2f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x float> @llvm.experimental.constrained.pow.v2f32({{.*}}, metadata !"round.downward", metadata !"fpexcept.strict")
; VIRT: define <2 x float> @protected_cpow_up_v2f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x float> @llvm.experimental.constrained.pow.v2f32({{.*}}, metadata !"round.upward", metadata !"fpexcept.ignore")
; VIRT: define <2 x float> @protected_cpow_zero_v2f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x float> @llvm.experimental.constrained.pow.v2f32({{.*}}, metadata !"round.towardzero", metadata !"fpexcept.ignore")
; VIRT: define <2 x float> @protected_cpowi_runtime_v2f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x float> @llvm.experimental.constrained.powi.v2f32({{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")
; VIRT: define <2 x float> @protected_cpowi_imm_v2f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x float> @llvm.experimental.constrained.powi.v2f32({{.*}}, metadata !"round.dynamic", metadata !"fpexcept.maytrap")
; VIRT: define <3 x float> @protected_cpow_v3f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <3 x float> @llvm.experimental.constrained.pow.v3f32({{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")
; VIRT: define <2 x double> @protected_cpow_v2f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x double> @llvm.experimental.constrained.pow.v2f64({{.*}}, metadata !"round.tonearest", metadata !"fpexcept.strict")
; VIRT: define <2 x double> @protected_cpowi_v2f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x double> @llvm.experimental.constrained.powi.v2f64({{.*}}, metadata !"round.towardzero", metadata !"fpexcept.ignore")
; VIRT: define <2 x float> @protected_cpow_phi_v2f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x float> @llvm.experimental.constrained.pow.v2f32({{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")
; VIRT: define <2 x float> @protected_cpow_loop_v2f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x float> @llvm.experimental.constrained.pow.v2f32({{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")
; VIRT: define {{.*}} @unsupported_cpow_v2f16({{.*}} #[[UNSUPCC:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cpow_wide({{.*}} #[[UNSUP_RET:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cpow_scalable({{.*}} #[[UNSUP_RET]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_csin_v2f16({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cpow_fastcc({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cpow_musttail({{.*}} #[[UNSUP_MT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call <2 x float> @llvm.experimental.constrained.pow.v2f32(
; VIRT: define {{.*}} @unsupported_cpow_bundle({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call <2 x float> @llvm.experimental.constrained.pow.v2f32({{.*}}[ "deopt"(i32 0) ]
; VIRT: define {{.*}} @unsupported_cpow_poison({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cpow_undef({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPCC]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPCC]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_MT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_RET]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
