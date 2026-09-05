; Restricted last-token +fullfp16 fixed 1..128
; llvm.experimental.constrained fptosi/fptoui (half vector ->
; same-lane i1/i8/i16/i32/i64 vector + fpexcept), sitofp/uitofp
; (integer vector -> same-lane half vector + round and fpexcept),
; fptrunc v*f32/v*f64->v*half (round+except), and fpext
; v*half->v*f32/v*f64 (except).  Both sides independently 1..128.
; Same MDString tokens as the scalar half constrained convert
; surface.  Replayed via CallDescriptor MetadataArguments.
; Missing or last-token -fullfp16 is "unsupported target feature".
; Does not change f32/f64 vector convert, scalar half convert, or
; add a VM opcode.  Other constrained IDs stay out.  Ordinary tail
; degrades to a normal call.  Host lli cannot be assumed to select
; half constrained ops: FileCheck + AArch64 llc/readobj only.
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
declare <2 x i1> @llvm.experimental.constrained.fptosi.v2i1.v2f16(<2 x half>, metadata)
declare <2 x i8> @llvm.experimental.constrained.fptosi.v2i8.v2f16(<2 x half>, metadata)
declare <2 x i16> @llvm.experimental.constrained.fptosi.v2i16.v2f16(<2 x half>, metadata)
declare <2 x i32> @llvm.experimental.constrained.fptosi.v2i32.v2f16(<2 x half>, metadata)
declare <2 x i64> @llvm.experimental.constrained.fptosi.v2i64.v2f16(<2 x half>, metadata)
declare <2 x i32> @llvm.experimental.constrained.fptoui.v2i32.v2f16(<2 x half>, metadata)
declare <3 x i16> @llvm.experimental.constrained.fptosi.v3i16.v3f16(<3 x half>, metadata)
declare <8 x i16> @llvm.experimental.constrained.fptosi.v8i16.v8f16(<8 x half>, metadata)
declare <2 x half> @llvm.experimental.constrained.sitofp.v2f16.v2i1(<2 x i1>, metadata, metadata)
declare <2 x half> @llvm.experimental.constrained.sitofp.v2f16.v2i8(<2 x i8>, metadata, metadata)
declare <2 x half> @llvm.experimental.constrained.sitofp.v2f16.v2i32(<2 x i32>, metadata, metadata)
declare <2 x half> @llvm.experimental.constrained.uitofp.v2f16.v2i32(<2 x i32>, metadata, metadata)
declare <2 x half> @llvm.experimental.constrained.sitofp.v2f16.v2i64(<2 x i64>, metadata, metadata)
declare <2 x half> @llvm.experimental.constrained.fptrunc.v2f16.v2f32(<2 x float>, metadata, metadata)
declare <2 x half> @llvm.experimental.constrained.fptrunc.v2f16.v2f64(<2 x double>, metadata, metadata)
declare <2 x float> @llvm.experimental.constrained.fpext.v2f32.v2f16(<2 x half>, metadata)
declare <2 x double> @llvm.experimental.constrained.fpext.v2f64.v2f16(<2 x half>, metadata)
declare <16 x i16> @llvm.experimental.constrained.fptosi.v16i16.v16f16(<16 x half>, metadata)
declare <vscale x 2 x i16> @llvm.experimental.constrained.fptosi.nxv2i16.nxv2f16(<vscale x 2 x half>, metadata)

declare <2 x half> @llvm.experimental.constrained.pow.v2f16(<2 x half>, <2 x half>, metadata, metadata)

define <2 x i32> @protected_cfptosi_v2i32_v2f16(<2 x half> %a) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <2 x i32> @llvm.experimental.constrained.fptosi.v2i32.v2f16(<2 x half> %a, metadata !"fpexcept.ignore")
  ret <2 x i32> %r
}

define <2 x i1> @protected_cfptosi_v2i1_v2f16(<2 x half> %a) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <2 x i1> @llvm.experimental.constrained.fptosi.v2i1.v2f16(<2 x half> %a, metadata !"fpexcept.maytrap")
  ret <2 x i1> %r
}

define <2 x i8> @protected_cfptosi_v2i8_v2f16(<2 x half> %a) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <2 x i8> @llvm.experimental.constrained.fptosi.v2i8.v2f16(<2 x half> %a, metadata !"fpexcept.strict")
  ret <2 x i8> %r
}

define <2 x i16> @protected_cfptosi_v2i16_v2f16(<2 x half> %a) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <2 x i16> @llvm.experimental.constrained.fptosi.v2i16.v2f16(<2 x half> %a, metadata !"fpexcept.ignore")
  ret <2 x i16> %r
}

define <2 x i64> @protected_cfptosi_v2i64_v2f16(<2 x half> %a) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.experimental.constrained.fptosi.v2i64.v2f16(<2 x half> %a, metadata !"fpexcept.maytrap")
  ret <2 x i64> %r
}

define <2 x i32> @protected_cfptoui_v2i32_v2f16(<2 x half> %a) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <2 x i32> @llvm.experimental.constrained.fptoui.v2i32.v2f16(<2 x half> %a, metadata !"fpexcept.ignore")
  ret <2 x i32> %r
}

define <3 x i16> @protected_cfptosi_v3i16_v3f16(<3 x half> %a) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <3 x i16> @llvm.experimental.constrained.fptosi.v3i16.v3f16(<3 x half> %a, metadata !"fpexcept.ignore")
  ret <3 x i16> %r
}

define <8 x i16> @protected_cfptosi_v8i16_v8f16(<8 x half> %a) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <8 x i16> @llvm.experimental.constrained.fptosi.v8i16.v8f16(<8 x half> %a, metadata !"fpexcept.strict")
  ret <8 x i16> %r
}

define <2 x half> @protected_csitofp_v2f16_v2i32(<2 x i32> %a) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <2 x half> @llvm.experimental.constrained.sitofp.v2f16.v2i32(<2 x i32> %a, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret <2 x half> %r
}

define <2 x half> @protected_csitofp_v2f16_v2i1(<2 x i1> %a) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <2 x half> @llvm.experimental.constrained.sitofp.v2f16.v2i1(<2 x i1> %a, metadata !"round.dynamic", metadata !"fpexcept.maytrap")
  ret <2 x half> %r
}

define <2 x half> @protected_csitofp_v2f16_v2i8(<2 x i8> %a) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <2 x half> @llvm.experimental.constrained.sitofp.v2f16.v2i8(<2 x i8> %a, metadata !"round.downward", metadata !"fpexcept.strict")
  ret <2 x half> %r
}

define <2 x half> @protected_cuitofp_v2f16_v2i32(<2 x i32> %a) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <2 x half> @llvm.experimental.constrained.uitofp.v2f16.v2i32(<2 x i32> %a, metadata !"round.upward", metadata !"fpexcept.ignore")
  ret <2 x half> %r
}

define <2 x half> @protected_csitofp_v2f16_v2i64(<2 x i64> %a) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <2 x half> @llvm.experimental.constrained.sitofp.v2f16.v2i64(<2 x i64> %a, metadata !"round.towardzero", metadata !"fpexcept.ignore")
  ret <2 x half> %r
}

define <2 x half> @protected_cfptrunc_v2f16_v2f32(<2 x float> %a) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <2 x half> @llvm.experimental.constrained.fptrunc.v2f16.v2f32(<2 x float> %a, metadata !"round.upward", metadata !"fpexcept.ignore")
  ret <2 x half> %r
}

define <2 x half> @protected_cfptrunc_v2f16_v2f64(<2 x double> %a) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <2 x half> @llvm.experimental.constrained.fptrunc.v2f16.v2f64(<2 x double> %a, metadata !"round.downward", metadata !"fpexcept.maytrap")
  ret <2 x half> %r
}

define <2 x float> @protected_cfpext_v2f32_v2f16(<2 x half> %a) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.experimental.constrained.fpext.v2f32.v2f16(<2 x half> %a, metadata !"fpexcept.ignore")
  ret <2 x float> %r
}

define <2 x double> @protected_cfpext_v2f64_v2f16(<2 x half> %a) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <2 x double> @llvm.experimental.constrained.fpext.v2f64.v2f16(<2 x half> %a, metadata !"fpexcept.strict")
  ret <2 x double> %r
}


define <2 x i32> @protected_cfptosi_phi_v2i32_v2f16(<2 x half> %a, i1 %p) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  br i1 %p, label %left, label %right
left:
  %l = call <2 x i32> @llvm.experimental.constrained.fptosi.v2i32.v2f16(<2 x half> %a, metadata !"fpexcept.ignore")
  br label %join
right:
  %r = call <2 x i32> @llvm.experimental.constrained.fptoui.v2i32.v2f16(<2 x half> %a, metadata !"fpexcept.ignore")
  br label %join
join:
  %q = phi <2 x i32> [ %l, %left ], [ %r, %right ]
  ret <2 x i32> %q
}

define <2 x i32> @protected_cfptosi_loop_v2i32_v2f16(<2 x half> %a, i32 %n) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  br label %hdr
hdr:
  %acc = phi <2 x i32> [ zeroinitializer, %entry ], [ %cur, %hdr ]
  %i = phi i32 [ 0, %entry ], [ %i.nxt, %hdr ]
  %cur = call <2 x i32> @llvm.experimental.constrained.fptosi.v2i32.v2f16(<2 x half> %a, metadata !"fpexcept.ignore")
  %i.nxt = add i32 %i, 1
  %more = icmp ult i32 %i.nxt, %n
  br i1 %more, label %hdr, label %done
done:
  ret <2 x i32> %cur
}

define <2 x i16> @unsupported_cfptosi_no_fullfp16(<2 x half> %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call <2 x i16> @llvm.experimental.constrained.fptosi.v2i16.v2f16(<2 x half> %a, metadata !"fpexcept.ignore")
  ret <2 x i16> %r
}

define <2 x i16> @unsupported_cfptosi_fullfp16_disabled(<2 x half> %a) noinline optnone strictfp "target-features"="+neon,+fullfp16,-fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <2 x i16> @llvm.experimental.constrained.fptosi.v2i16.v2f16(<2 x half> %a, metadata !"fpexcept.ignore")
  ret <2 x i16> %r
}

define <16 x i16> @unsupported_cfptosi_wide(<16 x half> %a) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <16 x i16> @llvm.experimental.constrained.fptosi.v16i16.v16f16(<16 x half> %a, metadata !"fpexcept.ignore")
  ret <16 x i16> %r
}

define <vscale x 2 x i16> @unsupported_cfptosi_scalable(<vscale x 2 x half> %a) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 2 x i16> @llvm.experimental.constrained.fptosi.nxv2i16.nxv2f16(<vscale x 2 x half> %a, metadata !"fpexcept.ignore")
  ret <vscale x 2 x i16> %r
}

define <2 x half> @unsupported_csin_v2f16(<2 x half> %a) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <2 x half> @llvm.experimental.constrained.pow.v2f16(<2 x half> %a, <2 x half> %a, metadata !"round.tonearest", metadata !"fpexcept.ignore") [ "deopt"(i32 0) ]
  ret <2 x half> %r
}

define <2 x i32> @unsupported_cfptosi_fastcc(<2 x half> %a) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call fastcc <2 x i32> @llvm.experimental.constrained.fptosi.v2i32.v2f16(<2 x half> %a, metadata !"fpexcept.ignore")
  ret <2 x i32> %r
}

define <2 x i32> @unsupported_cfptosi_musttail(<2 x half> %a) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = musttail call <2 x i32> @llvm.experimental.constrained.fptosi.v2i32.v2f16(<2 x half> %a, metadata !"fpexcept.ignore")
  ret <2 x i32> %r
}

define <2 x i32> @unsupported_cfptosi_bundle(<2 x half> %a) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <2 x i32> @llvm.experimental.constrained.fptosi.v2i32.v2f16(<2 x half> %a, metadata !"fpexcept.ignore") [ "deopt"(i32 0) ]
  ret <2 x i32> %r
}

define <2 x i32> @unsupported_cfptosi_poison() noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <2 x i32> @llvm.experimental.constrained.fptosi.v2i32.v2f16(<2 x half> poison, metadata !"fpexcept.ignore")
  ret <2 x i32> %r
}

define <2 x i32> @unsupported_cfptosi_undef() noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <2 x i32> @llvm.experimental.constrained.fptosi.v2i32.v2f16(<2 x half> undef, metadata !"fpexcept.ignore")
  ret <2 x i32> %r
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_cfptosi_no_fullfp16: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_cfptosi_fullfp16_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_cfptosi_wide: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_cfptosi_scalable: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_csin_v2f16: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_cfptosi_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_cfptosi_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_cfptosi_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_cfptosi_poison: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_cfptosi_undef: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_cfptosi_v2i32_v2f16:
; SKIP-NOT: Skipping VMP on protected_cfptosi_v2i1_v2f16:
; SKIP-NOT: Skipping VMP on protected_cfptosi_v2i8_v2f16:
; SKIP-NOT: Skipping VMP on protected_cfptosi_v2i16_v2f16:
; SKIP-NOT: Skipping VMP on protected_cfptosi_v2i64_v2f16:
; SKIP-NOT: Skipping VMP on protected_cfptoui_v2i32_v2f16:
; SKIP-NOT: Skipping VMP on protected_cfptosi_v3i16_v3f16:
; SKIP-NOT: Skipping VMP on protected_cfptosi_v8i16_v8f16:
; SKIP-NOT: Skipping VMP on protected_csitofp_v2f16_v2i32:
; SKIP-NOT: Skipping VMP on protected_csitofp_v2f16_v2i1:
; SKIP-NOT: Skipping VMP on protected_csitofp_v2f16_v2i8:
; SKIP-NOT: Skipping VMP on protected_cuitofp_v2f16_v2i32:
; SKIP-NOT: Skipping VMP on protected_csitofp_v2f16_v2i64:
; SKIP-NOT: Skipping VMP on protected_cfptrunc_v2f16_v2f32:
; SKIP-NOT: Skipping VMP on protected_cfptrunc_v2f16_v2f64:
; SKIP-NOT: Skipping VMP on protected_cfpext_v2f32_v2f16:
; SKIP-NOT: Skipping VMP on protected_cfpext_v2f64_v2f16:
; SKIP-NOT: Skipping VMP on protected_cfptosi_phi_v2i32_v2f16:
; SKIP-NOT: Skipping VMP on protected_cfptosi_loop_v2i32_v2f16:

; VIRT: define <2 x i32> @protected_cfptosi_v2i32_v2f16({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i32> @llvm.experimental.constrained.fptosi.v2i32.v2f16({{.*}}, metadata !"fpexcept.ignore")
; VIRT: define <2 x i1> @protected_cfptosi_v2i1_v2f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i1> @llvm.experimental.constrained.fptosi.v2i1.v2f16({{.*}}, metadata !"fpexcept.maytrap")
; VIRT: define <2 x i8> @protected_cfptosi_v2i8_v2f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i8> @llvm.experimental.constrained.fptosi.v2i8.v2f16({{.*}}, metadata !"fpexcept.strict")
; VIRT: define <2 x i16> @protected_cfptosi_v2i16_v2f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i16> @llvm.experimental.constrained.fptosi.v2i16.v2f16({{.*}}, metadata !"fpexcept.ignore")
; VIRT: define <2 x i64> @protected_cfptosi_v2i64_v2f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i64> @llvm.experimental.constrained.fptosi.v2i64.v2f16({{.*}}, metadata !"fpexcept.maytrap")
; VIRT: define <2 x i32> @protected_cfptoui_v2i32_v2f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i32> @llvm.experimental.constrained.fptoui.v2i32.v2f16({{.*}}, metadata !"fpexcept.ignore")
; VIRT: define <3 x i16> @protected_cfptosi_v3i16_v3f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <3 x i16> @llvm.experimental.constrained.fptosi.v3i16.v3f16({{.*}}, metadata !"fpexcept.ignore")
; VIRT: define <8 x i16> @protected_cfptosi_v8i16_v8f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x i16> @llvm.experimental.constrained.fptosi.v8i16.v8f16({{.*}}, metadata !"fpexcept.strict")
; VIRT: define <2 x half> @protected_csitofp_v2f16_v2i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x half> @llvm.experimental.constrained.sitofp.v2f16.v2i32({{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")
; VIRT: define <2 x half> @protected_csitofp_v2f16_v2i1({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x half> @llvm.experimental.constrained.sitofp.v2f16.v2i1({{.*}}, metadata !"round.dynamic", metadata !"fpexcept.maytrap")
; VIRT: define <2 x half> @protected_csitofp_v2f16_v2i8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x half> @llvm.experimental.constrained.sitofp.v2f16.v2i8({{.*}}, metadata !"round.downward", metadata !"fpexcept.strict")
; VIRT: define <2 x half> @protected_cuitofp_v2f16_v2i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x half> @llvm.experimental.constrained.uitofp.v2f16.v2i32({{.*}}, metadata !"round.upward", metadata !"fpexcept.ignore")
; VIRT: define <2 x half> @protected_csitofp_v2f16_v2i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x half> @llvm.experimental.constrained.sitofp.v2f16.v2i64({{.*}}, metadata !"round.towardzero", metadata !"fpexcept.ignore")
; VIRT: define <2 x half> @protected_cfptrunc_v2f16_v2f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x half> @llvm.experimental.constrained.fptrunc.v2f16.v2f32({{.*}}, metadata !"round.upward", metadata !"fpexcept.ignore")
; VIRT: define <2 x half> @protected_cfptrunc_v2f16_v2f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x half> @llvm.experimental.constrained.fptrunc.v2f16.v2f64({{.*}}, metadata !"round.downward", metadata !"fpexcept.maytrap")
; VIRT: define <2 x float> @protected_cfpext_v2f32_v2f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x float> @llvm.experimental.constrained.fpext.v2f32.v2f16({{.*}}, metadata !"fpexcept.ignore")
; VIRT: define <2 x double> @protected_cfpext_v2f64_v2f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x double> @llvm.experimental.constrained.fpext.v2f64.v2f16({{.*}}, metadata !"fpexcept.strict")
; VIRT: define <2 x i32> @protected_cfptosi_phi_v2i32_v2f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i32> @llvm.experimental.constrained.fptosi.v2i32.v2f16({{.*}}, metadata !"fpexcept.ignore")
; VIRT: define <2 x i32> @protected_cfptosi_loop_v2i32_v2f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i32> @llvm.experimental.constrained.fptosi.v2i32.v2f16({{.*}}, metadata !"fpexcept.ignore")
; VIRT: define {{.*}} @unsupported_cfptosi_no_fullfp16({{.*}} #[[UNSUPFEAT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cfptosi_fullfp16_disabled({{.*}} #[[UNSUPFEAT2:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cfptosi_wide({{.*}} #[[UNSUP_RET:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cfptosi_scalable({{.*}} #[[UNSUP_RET]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_csin_v2f16({{.*}} #[[UNSUPCC:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cfptosi_fastcc({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cfptosi_musttail({{.*}} #[[UNSUP_MT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call <2 x i32> @llvm.experimental.constrained.fptosi.v2i32.v2f16(
; VIRT: define {{.*}} @unsupported_cfptosi_bundle({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call <2 x i32> @llvm.experimental.constrained.fptosi.v2i32.v2f16({{.*}}[ "deopt"(i32 0) ]
; VIRT: define {{.*}} @unsupported_cfptosi_poison({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cfptosi_undef({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPCC]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPCC]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_MT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_RET]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPFEAT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPFEAT2]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
