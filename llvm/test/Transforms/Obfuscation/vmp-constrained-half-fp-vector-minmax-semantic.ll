; Restricted last-token +fullfp16 fixed 1..128
; llvm.experimental.constrained minnum/maxnum/minimum/maximum on
; IEEE half vectors: two same-type operands plus one fpexcept
; MDString (LLVM 15 has no rounding operand).  Same MDString
; tokens as the scalar half constrained minmax surface.  Replayed
; via CallDescriptor MetadataArguments.  Missing or last-token
; -fullfp16 is "unsupported target feature".  Does not change
; f32/f64 vector minmax, scalar half minmax, or add a VM opcode.
; Other constrained IDs stay out.  Ordinary tail degrades to a
; normal call.  Host lli cannot be assumed to select half
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
declare <2 x half> @llvm.experimental.constrained.minnum.v2f16(<2 x half>, <2 x half>, metadata)
declare <2 x half> @llvm.experimental.constrained.maxnum.v2f16(<2 x half>, <2 x half>, metadata)
declare <2 x half> @llvm.experimental.constrained.minimum.v2f16(<2 x half>, <2 x half>, metadata)
declare <2 x half> @llvm.experimental.constrained.maximum.v2f16(<2 x half>, <2 x half>, metadata)
declare <3 x half> @llvm.experimental.constrained.minnum.v3f16(<3 x half>, <3 x half>, metadata)
declare <8 x half> @llvm.experimental.constrained.minnum.v8f16(<8 x half>, <8 x half>, metadata)
declare <2 x half> @llvm.experimental.constrained.fadd.v2f16(<2 x half>, <2 x half>, metadata, metadata)
declare <16 x half> @llvm.experimental.constrained.minnum.v16f16(<16 x half>, <16 x half>, metadata)
declare <vscale x 2 x half> @llvm.experimental.constrained.minnum.nxv2f16(<vscale x 2 x half>, <vscale x 2 x half>, metadata)

declare <2 x half> @llvm.experimental.constrained.pow.v2f16(<2 x half>, <2 x half>, metadata, metadata)

define <2 x half> @protected_cminnum_v2f16(<2 x half> %a, <2 x half> %b) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <2 x half> @llvm.experimental.constrained.minnum.v2f16(<2 x half> %a, <2 x half> %b, metadata !"fpexcept.ignore")
  ret <2 x half> %r
}

define <2 x half> @protected_cmaxnum_v2f16(<2 x half> %a, <2 x half> %b) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <2 x half> @llvm.experimental.constrained.maxnum.v2f16(<2 x half> %a, <2 x half> %b, metadata !"fpexcept.maytrap")
  ret <2 x half> %r
}

define <2 x half> @protected_cminimum_v2f16(<2 x half> %a, <2 x half> %b) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <2 x half> @llvm.experimental.constrained.minimum.v2f16(<2 x half> %a, <2 x half> %b, metadata !"fpexcept.strict")
  ret <2 x half> %r
}

define <2 x half> @protected_cmaximum_v2f16(<2 x half> %a, <2 x half> %b) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <2 x half> @llvm.experimental.constrained.maximum.v2f16(<2 x half> %a, <2 x half> %b, metadata !"fpexcept.ignore")
  ret <2 x half> %r
}

define <3 x half> @protected_cminnum_v3f16(<3 x half> %a, <3 x half> %b) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <3 x half> @llvm.experimental.constrained.minnum.v3f16(<3 x half> %a, <3 x half> %b, metadata !"fpexcept.ignore")
  ret <3 x half> %r
}

define <8 x half> @protected_cminnum_v8f16(<8 x half> %a, <8 x half> %b) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <8 x half> @llvm.experimental.constrained.minnum.v8f16(<8 x half> %a, <8 x half> %b, metadata !"fpexcept.strict")
  ret <8 x half> %r
}


define <2 x half> @protected_cminnum_phi_v2f16(<2 x half> %a, <2 x half> %b, i1 %p) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  br i1 %p, label %left, label %right
left:
  %l = call <2 x half> @llvm.experimental.constrained.minnum.v2f16(<2 x half> %a, <2 x half> %b, metadata !"fpexcept.ignore")
  br label %join
right:
  %r = call <2 x half> @llvm.experimental.constrained.maxnum.v2f16(<2 x half> %a, <2 x half> %b, metadata !"fpexcept.ignore")
  br label %join
join:
  %q = phi <2 x half> [ %l, %left ], [ %r, %right ]
  ret <2 x half> %q
}

define <2 x half> @protected_cminnum_loop_v2f16(<2 x half> %a, <2 x half> %b, i32 %n) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  br label %hdr
hdr:
  %acc = phi <2 x half> [ %a, %entry ], [ %nxt, %hdr ]
  %i = phi i32 [ 0, %entry ], [ %i.nxt, %hdr ]
  %cur = call <2 x half> @llvm.experimental.constrained.minnum.v2f16(<2 x half> %acc, <2 x half> %b, metadata !"fpexcept.ignore")
  %nxt = call <2 x half> @llvm.experimental.constrained.fadd.v2f16(<2 x half> %acc, <2 x half> <half 0xH3C00, half 0xH3C00>, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  %i.nxt = add i32 %i, 1
  %more = icmp ult i32 %i.nxt, %n
  br i1 %more, label %hdr, label %done
done:
  ret <2 x half> %cur
}

define <2 x half> @unsupported_cminnum_no_fullfp16(<2 x half> %a, <2 x half> %b) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call <2 x half> @llvm.experimental.constrained.minnum.v2f16(<2 x half> %a, <2 x half> %b, metadata !"fpexcept.ignore")
  ret <2 x half> %r
}

define <2 x half> @unsupported_cminnum_fullfp16_disabled(<2 x half> %a, <2 x half> %b) noinline optnone strictfp "target-features"="+neon,+fullfp16,-fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <2 x half> @llvm.experimental.constrained.minnum.v2f16(<2 x half> %a, <2 x half> %b, metadata !"fpexcept.ignore")
  ret <2 x half> %r
}

define <16 x half> @unsupported_cminnum_wide(<16 x half> %a, <16 x half> %b) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <16 x half> @llvm.experimental.constrained.minnum.v16f16(<16 x half> %a, <16 x half> %b, metadata !"fpexcept.ignore")
  ret <16 x half> %r
}

define <vscale x 2 x half> @unsupported_cminnum_scalable(<vscale x 2 x half> %a, <vscale x 2 x half> %b) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 2 x half> @llvm.experimental.constrained.minnum.nxv2f16(<vscale x 2 x half> %a, <vscale x 2 x half> %b, metadata !"fpexcept.ignore")
  ret <vscale x 2 x half> %r
}

define <2 x half> @unsupported_csin_v2f16(<2 x half> %a) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <2 x half> @llvm.experimental.constrained.pow.v2f16(<2 x half> %a, <2 x half> %a, metadata !"round.tonearest", metadata !"fpexcept.ignore") [ "deopt"(i32 0) ]
  ret <2 x half> %r
}

define <2 x half> @unsupported_cminnum_fastcc(<2 x half> %a, <2 x half> %b) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call fastcc <2 x half> @llvm.experimental.constrained.minnum.v2f16(<2 x half> %a, <2 x half> %b, metadata !"fpexcept.ignore")
  ret <2 x half> %r
}

define <2 x half> @unsupported_cminnum_musttail(<2 x half> %a, <2 x half> %b) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = musttail call <2 x half> @llvm.experimental.constrained.minnum.v2f16(<2 x half> %a, <2 x half> %b, metadata !"fpexcept.ignore")
  ret <2 x half> %r
}

define <2 x half> @unsupported_cminnum_bundle(<2 x half> %a, <2 x half> %b) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <2 x half> @llvm.experimental.constrained.minnum.v2f16(<2 x half> %a, <2 x half> %b, metadata !"fpexcept.ignore") [ "deopt"(i32 0) ]
  ret <2 x half> %r
}

define <2 x half> @unsupported_cminnum_poison(<2 x half> %b) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <2 x half> @llvm.experimental.constrained.minnum.v2f16(<2 x half> poison, <2 x half> %b, metadata !"fpexcept.ignore")
  ret <2 x half> %r
}

define <2 x half> @unsupported_cminnum_undef(<2 x half> %b) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <2 x half> @llvm.experimental.constrained.minnum.v2f16(<2 x half> undef, <2 x half> %b, metadata !"fpexcept.ignore")
  ret <2 x half> %r
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_cminnum_no_fullfp16: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_cminnum_fullfp16_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_cminnum_wide: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_cminnum_scalable: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_csin_v2f16: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_cminnum_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_cminnum_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_cminnum_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_cminnum_poison: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_cminnum_undef: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_cminnum_v2f16:
; SKIP-NOT: Skipping VMP on protected_cmaxnum_v2f16:
; SKIP-NOT: Skipping VMP on protected_cminimum_v2f16:
; SKIP-NOT: Skipping VMP on protected_cmaximum_v2f16:
; SKIP-NOT: Skipping VMP on protected_cminnum_v3f16:
; SKIP-NOT: Skipping VMP on protected_cminnum_v8f16:
; SKIP-NOT: Skipping VMP on protected_cminnum_phi_v2f16:
; SKIP-NOT: Skipping VMP on protected_cminnum_loop_v2f16:

; VIRT: define <2 x half> @protected_cminnum_v2f16({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x half> @llvm.experimental.constrained.minnum.v2f16({{.*}}, metadata !"fpexcept.ignore")
; VIRT: define <2 x half> @protected_cmaxnum_v2f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x half> @llvm.experimental.constrained.maxnum.v2f16({{.*}}, metadata !"fpexcept.maytrap")
; VIRT: define <2 x half> @protected_cminimum_v2f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x half> @llvm.experimental.constrained.minimum.v2f16({{.*}}, metadata !"fpexcept.strict")
; VIRT: define <2 x half> @protected_cmaximum_v2f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x half> @llvm.experimental.constrained.maximum.v2f16({{.*}}, metadata !"fpexcept.ignore")
; VIRT: define <3 x half> @protected_cminnum_v3f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <3 x half> @llvm.experimental.constrained.minnum.v3f16({{.*}}, metadata !"fpexcept.ignore")
; VIRT: define <8 x half> @protected_cminnum_v8f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x half> @llvm.experimental.constrained.minnum.v8f16({{.*}}, metadata !"fpexcept.strict")
; VIRT: define <2 x half> @protected_cminnum_phi_v2f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x half> @llvm.experimental.constrained.minnum.v2f16({{.*}}, metadata !"fpexcept.ignore")
; VIRT: define <2 x half> @protected_cminnum_loop_v2f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x half> @llvm.experimental.constrained.minnum.v2f16({{.*}}, metadata !"fpexcept.ignore")
; VIRT: define {{.*}} @unsupported_cminnum_no_fullfp16({{.*}} #[[UNSUPFEAT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cminnum_fullfp16_disabled({{.*}} #[[UNSUPFEAT2:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cminnum_wide({{.*}} #[[UNSUP_RET:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cminnum_scalable({{.*}} #[[UNSUP_RET]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_csin_v2f16({{.*}} #[[UNSUPCC:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cminnum_fastcc({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cminnum_musttail({{.*}} #[[UNSUP_MT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call <2 x half> @llvm.experimental.constrained.minnum.v2f16(
; VIRT: define {{.*}} @unsupported_cminnum_bundle({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call <2 x half> @llvm.experimental.constrained.minnum.v2f16({{.*}}[ "deopt"(i32 0) ]
; VIRT: define {{.*}} @unsupported_cminnum_poison({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cminnum_undef({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPCC]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPCC]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_MT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_RET]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPFEAT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPFEAT2]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
