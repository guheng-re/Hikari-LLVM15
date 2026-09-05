; Restricted scalar llvm.experimental.constrained.fptosi/fptoui/
; sitofp/uitofp/fptrunc/fpext.  fptosi/fptoui: f32/f64 -> i1/i8/i16/
; i32/i64 + fpexcept MDString.  sitofp/uitofp: i1/i8/i16/i32/i64 ->
; f32/f64 + round and fpexcept MDString.  fptrunc only f64->f32 with
; round+except.  fpext only f32->f64 with except.  Tokens match the
; existing constrained-arith set.  Replayed via CallDescriptor
; MetadataArguments as identical MetadataAsValue MDStrings.  No FMF
; and no dedicated VM opcode.  Ordinary tail degrades to a normal
; call.  Protected functions carry strictfp.  Well-shaped half without
; last-token +fullfp16 uses the shared half constrained feature-gate
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
declare i1 @llvm.experimental.constrained.fptosi.i1.f32(float, metadata)
declare i8 @llvm.experimental.constrained.fptosi.i8.f32(float, metadata)
declare i16 @llvm.experimental.constrained.fptosi.i16.f32(float, metadata)
declare i32 @llvm.experimental.constrained.fptosi.i32.f32(float, metadata)
declare i64 @llvm.experimental.constrained.fptosi.i64.f64(double, metadata)
declare i8 @llvm.experimental.constrained.fptoui.i8.f32(float, metadata)
declare i32 @llvm.experimental.constrained.fptoui.i32.f32(float, metadata)
declare i64 @llvm.experimental.constrained.fptoui.i64.f64(double, metadata)
declare float @llvm.experimental.constrained.sitofp.f32.i1(i1, metadata, metadata)
declare float @llvm.experimental.constrained.sitofp.f32.i8(i8, metadata, metadata)
declare float @llvm.experimental.constrained.sitofp.f32.i16(i16, metadata, metadata)
declare float @llvm.experimental.constrained.sitofp.f32.i32(i32, metadata, metadata)
declare double @llvm.experimental.constrained.sitofp.f64.i64(i64, metadata, metadata)
declare float @llvm.experimental.constrained.uitofp.f32.i8(i8, metadata, metadata)
declare float @llvm.experimental.constrained.uitofp.f32.i32(i32, metadata, metadata)
declare double @llvm.experimental.constrained.uitofp.f64.i64(i64, metadata, metadata)
declare float @llvm.experimental.constrained.fptrunc.f32.f64(double, metadata, metadata)
declare double @llvm.experimental.constrained.fpext.f64.f32(float, metadata)
declare i16 @llvm.experimental.constrained.fptosi.i16.f16(half, metadata)
declare i32 @llvm.experimental.constrained.fptosi.i32.bf16(bfloat, metadata)
declare i32 @llvm.experimental.constrained.fptosi.i32.f128(fp128, metadata)
declare i128 @llvm.experimental.constrained.fptosi.i128.f32(float, metadata)
declare <vscale x 4 x i32> @llvm.experimental.constrained.fptosi.nxv4i32.nxv4f32(<vscale x 4 x float>, metadata)
declare float @llvm.experimental.constrained.ceil.f32(float, metadata)

declare <2 x half> @llvm.experimental.constrained.pow.v2f16(<2 x half>, <2 x half>, metadata, metadata)

define i1 @protected_cfptosi_i1_f32(float %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call i1 @llvm.experimental.constrained.fptosi.i1.f32(float %a, metadata !"fpexcept.ignore")
  ret i1 %r
}

define i8 @protected_cfptosi_i8_f32(float %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call i8 @llvm.experimental.constrained.fptosi.i8.f32(float %a, metadata !"fpexcept.maytrap")
  ret i8 %r
}

define i16 @protected_cfptosi_i16_f32(float %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call i16 @llvm.experimental.constrained.fptosi.i16.f32(float %a, metadata !"fpexcept.strict")
  ret i16 %r
}

define i32 @protected_cfptosi_i32_f32(float %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.experimental.constrained.fptosi.i32.f32(float %a, metadata !"fpexcept.ignore")
  ret i32 %r
}

define i64 @protected_cfptosi_i64_f64(double %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.experimental.constrained.fptosi.i64.f64(double %a, metadata !"fpexcept.ignore")
  ret i64 %r
}

define i8 @protected_cfptoui_i8_f32(float %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call i8 @llvm.experimental.constrained.fptoui.i8.f32(float %a, metadata !"fpexcept.ignore")
  ret i8 %r
}

define i32 @protected_cfptoui_i32_f32(float %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.experimental.constrained.fptoui.i32.f32(float %a, metadata !"fpexcept.maytrap")
  ret i32 %r
}

define i64 @protected_cfptoui_i64_f64(double %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.experimental.constrained.fptoui.i64.f64(double %a, metadata !"fpexcept.strict")
  ret i64 %r
}

define float @protected_csitofp_f32_i1(i1 %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.experimental.constrained.sitofp.f32.i1(i1 %a, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret float %r
}

define float @protected_csitofp_f32_i8(i8 %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.experimental.constrained.sitofp.f32.i8(i8 %a, metadata !"round.dynamic", metadata !"fpexcept.maytrap")
  ret float %r
}

define float @protected_csitofp_f32_i16(i16 %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.experimental.constrained.sitofp.f32.i16(i16 %a, metadata !"round.downward", metadata !"fpexcept.strict")
  ret float %r
}

define float @protected_csitofp_f32_i32(i32 %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.experimental.constrained.sitofp.f32.i32(i32 %a, metadata !"round.upward", metadata !"fpexcept.ignore")
  ret float %r
}

define double @protected_csitofp_f64_i64(i64 %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call double @llvm.experimental.constrained.sitofp.f64.i64(i64 %a, metadata !"round.towardzero", metadata !"fpexcept.ignore")
  ret double %r
}

define float @protected_cuitofp_f32_i8(i8 %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.experimental.constrained.uitofp.f32.i8(i8 %a, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret float %r
}

define float @protected_cuitofp_f32_i32(i32 %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.experimental.constrained.uitofp.f32.i32(i32 %a, metadata !"round.dynamic", metadata !"fpexcept.maytrap")
  ret float %r
}

define double @protected_cuitofp_f64_i64(i64 %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call double @llvm.experimental.constrained.uitofp.f64.i64(i64 %a, metadata !"round.downward", metadata !"fpexcept.strict")
  ret double %r
}

define float @protected_cfptrunc_f32_f64(double %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.experimental.constrained.fptrunc.f32.f64(double %a, metadata !"round.upward", metadata !"fpexcept.ignore")
  ret float %r
}

define double @protected_cfpext_f64_f32(float %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call double @llvm.experimental.constrained.fpext.f64.f32(float %a, metadata !"fpexcept.maytrap")
  ret double %r
}


define i32 @protected_cfptosi_phi_f32(float %a, float %b, i1 %c) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  br i1 %c, label %left, label %right
left:
  %l = call i32 @llvm.experimental.constrained.fptosi.i32.f32(float %a, metadata !"fpexcept.ignore")
  br label %join
right:
  %r = call i32 @llvm.experimental.constrained.fptoui.i32.f32(float %b, metadata !"fpexcept.ignore")
  br label %join
join:
  %p = phi i32 [ %l, %left ], [ %r, %right ]
  ret i32 %p
}

define float @protected_csitofp_loop_f32(i32 %a, i32 %n) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  br label %hdr
hdr:
  %acc = phi i32 [ %a, %entry ], [ %nxt, %hdr ]
  %i = phi i32 [ 0, %entry ], [ %i.nxt, %hdr ]
  %cur = call float @llvm.experimental.constrained.sitofp.f32.i32(i32 %acc, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  %nxt = add i32 %acc, 1
  %i.nxt = add i32 %i, 1
  %more = icmp ult i32 %i.nxt, %n
  br i1 %more, label %hdr, label %done
done:
  ret float %cur
}

define i16 @unsupported_cfptosi_half(half %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call i16 @llvm.experimental.constrained.fptosi.i16.f16(half %a, metadata !"fpexcept.ignore")
  ret i16 %r
}

define i32 @unsupported_cfptosi_bfloat(bfloat %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.experimental.constrained.fptosi.i32.bf16(bfloat %a, metadata !"fpexcept.ignore")
  ret i32 %r
}

define i32 @unsupported_cfptosi_fp128(fp128 %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.experimental.constrained.fptosi.i32.f128(fp128 %a, metadata !"fpexcept.ignore")
  ret i32 %r
}

define i128 @unsupported_cfptosi_i128(float %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call i128 @llvm.experimental.constrained.fptosi.i128.f32(float %a, metadata !"fpexcept.ignore")
  ret i128 %r
}

define <2 x half> @unsupported_cfptosi_vector(<2 x half> %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call <2 x half> @llvm.experimental.constrained.pow.v2f16(<2 x half> %a, <2 x half> %a, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret <2 x half> %r
}

define <vscale x 4 x i32> @unsupported_cfptosi_scalable(<vscale x 4 x float> %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x i32> @llvm.experimental.constrained.fptosi.nxv4i32.nxv4f32(<vscale x 4 x float> %a, metadata !"fpexcept.ignore")
  ret <vscale x 4 x i32> %r
}

; Well-shaped C constrained.ceil is now a supported rounding surface.
; fastcc keeps this a skip.
define float @unsupported_cceil_f32(float %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call fastcc float @llvm.experimental.constrained.ceil.f32(float %a, metadata !"fpexcept.ignore")
  ret float %r
}

define i32 @unsupported_cfptosi_fastcc(float %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call fastcc i32 @llvm.experimental.constrained.fptosi.i32.f32(float %a, metadata !"fpexcept.ignore")
  ret i32 %r
}

define i32 @unsupported_cfptosi_musttail(float %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = musttail call i32 @llvm.experimental.constrained.fptosi.i32.f32(float %a, metadata !"fpexcept.ignore")
  ret i32 %r
}

define i32 @unsupported_cfptosi_bundle(float %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.experimental.constrained.fptosi.i32.f32(float %a, metadata !"fpexcept.ignore") [ "deopt"(i32 0) ]
  ret i32 %r
}

define i32 @unsupported_cfptosi_poison() noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.experimental.constrained.fptosi.i32.f32(float poison, metadata !"fpexcept.ignore")
  ret i32 %r
}

define i32 @unsupported_cfptosi_undef() noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.experimental.constrained.fptosi.i32.f32(float undef, metadata !"fpexcept.ignore")
  ret i32 %r
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_cfptosi_half: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_cfptosi_bfloat: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_cfptosi_fp128: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_cfptosi_i128: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_cfptosi_vector: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_cfptosi_scalable: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_cceil_f32: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_cfptosi_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_cfptosi_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_cfptosi_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_cfptosi_poison: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_cfptosi_undef: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_cfptosi_i1_f32:
; SKIP-NOT: Skipping VMP on protected_cfptosi_i8_f32:
; SKIP-NOT: Skipping VMP on protected_cfptosi_i16_f32:
; SKIP-NOT: Skipping VMP on protected_cfptosi_i32_f32:
; SKIP-NOT: Skipping VMP on protected_cfptosi_i64_f64:
; SKIP-NOT: Skipping VMP on protected_cfptoui_i8_f32:
; SKIP-NOT: Skipping VMP on protected_cfptoui_i32_f32:
; SKIP-NOT: Skipping VMP on protected_cfptoui_i64_f64:
; SKIP-NOT: Skipping VMP on protected_csitofp_f32_i1:
; SKIP-NOT: Skipping VMP on protected_csitofp_f32_i8:
; SKIP-NOT: Skipping VMP on protected_csitofp_f32_i16:
; SKIP-NOT: Skipping VMP on protected_csitofp_f32_i32:
; SKIP-NOT: Skipping VMP on protected_csitofp_f64_i64:
; SKIP-NOT: Skipping VMP on protected_cuitofp_f32_i8:
; SKIP-NOT: Skipping VMP on protected_cuitofp_f32_i32:
; SKIP-NOT: Skipping VMP on protected_cuitofp_f64_i64:
; SKIP-NOT: Skipping VMP on protected_cfptrunc_f32_f64:
; SKIP-NOT: Skipping VMP on protected_cfpext_f64_f32:
; SKIP-NOT: Skipping VMP on protected_cfptosi_phi_f32:
; SKIP-NOT: Skipping VMP on protected_csitofp_loop_f32:

; VIRT: define i1 @protected_cfptosi_i1_f32({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call i1 @llvm.experimental.constrained.fptosi.i1.f32({{.*}}, metadata !"fpexcept.ignore")
; VIRT: define i8 @protected_cfptosi_i8_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i8 @llvm.experimental.constrained.fptosi.i8.f32({{.*}}, metadata !"fpexcept.maytrap")
; VIRT: define i16 @protected_cfptosi_i16_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i16 @llvm.experimental.constrained.fptosi.i16.f32({{.*}}, metadata !"fpexcept.strict")
; VIRT: define i32 @protected_cfptosi_i32_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.experimental.constrained.fptosi.i32.f32({{.*}}, metadata !"fpexcept.ignore")
; VIRT: define i64 @protected_cfptosi_i64_f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.experimental.constrained.fptosi.i64.f64({{.*}}, metadata !"fpexcept.ignore")
; VIRT: define i8 @protected_cfptoui_i8_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i8 @llvm.experimental.constrained.fptoui.i8.f32({{.*}}, metadata !"fpexcept.ignore")
; VIRT: define i32 @protected_cfptoui_i32_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.experimental.constrained.fptoui.i32.f32({{.*}}, metadata !"fpexcept.maytrap")
; VIRT: define i64 @protected_cfptoui_i64_f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.experimental.constrained.fptoui.i64.f64({{.*}}, metadata !"fpexcept.strict")
; VIRT: define float @protected_csitofp_f32_i1({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.experimental.constrained.sitofp.f32.i1({{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")
; VIRT: define float @protected_csitofp_f32_i8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.experimental.constrained.sitofp.f32.i8({{.*}}, metadata !"round.dynamic", metadata !"fpexcept.maytrap")
; VIRT: define float @protected_csitofp_f32_i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.experimental.constrained.sitofp.f32.i16({{.*}}, metadata !"round.downward", metadata !"fpexcept.strict")
; VIRT: define float @protected_csitofp_f32_i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.experimental.constrained.sitofp.f32.i32({{.*}}, metadata !"round.upward", metadata !"fpexcept.ignore")
; VIRT: define double @protected_csitofp_f64_i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call double @llvm.experimental.constrained.sitofp.f64.i64({{.*}}, metadata !"round.towardzero", metadata !"fpexcept.ignore")
; VIRT: define float @protected_cuitofp_f32_i8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.experimental.constrained.uitofp.f32.i8({{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")
; VIRT: define float @protected_cuitofp_f32_i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.experimental.constrained.uitofp.f32.i32({{.*}}, metadata !"round.dynamic", metadata !"fpexcept.maytrap")
; VIRT: define double @protected_cuitofp_f64_i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call double @llvm.experimental.constrained.uitofp.f64.i64({{.*}}, metadata !"round.downward", metadata !"fpexcept.strict")
; VIRT: define float @protected_cfptrunc_f32_f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.experimental.constrained.fptrunc.f32.f64({{.*}}, metadata !"round.upward", metadata !"fpexcept.ignore")
; VIRT: define double @protected_cfpext_f64_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call double @llvm.experimental.constrained.fpext.f64.f32({{.*}}, metadata !"fpexcept.maytrap")
; VIRT: define i32 @protected_cfptosi_phi_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.experimental.constrained.fptosi.i32.f32({{.*}}, metadata !"fpexcept.ignore")
; VIRT: define float @protected_csitofp_loop_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.experimental.constrained.sitofp.f32.i32({{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")
; VIRT: define {{.*}} @unsupported_cfptosi_half({{.*}} #[[UNSUPCC:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cfptosi_bfloat({{.*}} #[[UNSUP_ARG:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cfptosi_fp128({{.*}} #[[UNSUP_ARG]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cfptosi_i128({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cfptosi_vector({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cfptosi_scalable({{.*}} #[[UNSUP_SC:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cceil_f32({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call fastcc float @llvm.experimental.constrained.ceil.f32(
; VIRT: define {{.*}} @unsupported_cfptosi_fastcc({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cfptosi_musttail({{.*}} #[[UNSUP_MT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call i32 @llvm.experimental.constrained.fptosi.i32.f32(
; VIRT: define {{.*}} @unsupported_cfptosi_bundle({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call i32 @llvm.experimental.constrained.fptosi.i32.f32({{.*}}[ "deopt"(i32 0) ]
; VIRT: define {{.*}} @unsupported_cfptosi_poison({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cfptosi_undef({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPCC]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPCC]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_MT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_ARG]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_SC]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
