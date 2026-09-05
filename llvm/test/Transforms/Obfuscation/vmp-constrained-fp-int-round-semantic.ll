; Restricted scalar llvm.experimental.constrained.lrint/lround and
; llrint/llround.  Dest widths follow AArch64 ISel: lrint/lround
; accept i32 or i64; llrint/llround accept i64 only.  Source is
; scalar f32/f64.  lrint/llrint take round+except MDString;
; lround/llround take except only.  Tokens match the existing
; constrained-arith set.  Replayed via CallDescriptor
; MetadataArguments as identical MetadataAsValue MDStrings.  No FMF
; and no dedicated VM opcode.  Ordinary tail degrades to a normal
; call.  Protected functions carry strictfp.  Well-shaped half without
; last-token +fullfp16 uses the shared half constrained feature-gate
; ("unsupported target feature").
; LLVM 15 verifier rejects vector overloads of these four IDs, so the
; vector skip uses well-formed constrained.pow.v2f16 instead.
; Does not change the non-constrained i64-only lround whitelist.
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
declare i64 @llvm.experimental.constrained.lrint.i64.f32(float, metadata, metadata)
declare i64 @llvm.experimental.constrained.llrint.i64.f32(float, metadata, metadata)
declare i64 @llvm.experimental.constrained.lround.i64.f32(float, metadata)
declare i64 @llvm.experimental.constrained.llround.i64.f32(float, metadata)
declare i64 @llvm.experimental.constrained.lrint.i64.f64(double, metadata, metadata)
declare i64 @llvm.experimental.constrained.llrint.i64.f64(double, metadata, metadata)
declare i64 @llvm.experimental.constrained.lround.i64.f64(double, metadata)
declare i64 @llvm.experimental.constrained.llround.i64.f64(double, metadata)
declare i32 @llvm.experimental.constrained.lrint.i32.f32(float, metadata, metadata)
declare i32 @llvm.experimental.constrained.lround.i32.f32(float, metadata)
declare i32 @llvm.experimental.constrained.lrint.i32.f64(double, metadata, metadata)
declare i32 @llvm.experimental.constrained.lround.i32.f64(double, metadata)
declare i32 @llvm.experimental.constrained.llrint.i32.f32(float, metadata, metadata)
declare i32 @llvm.experimental.constrained.llround.i32.f32(float, metadata)
declare i16 @llvm.experimental.constrained.lround.i16.f32(float, metadata)
declare i128 @llvm.experimental.constrained.lround.i128.f32(float, metadata)
declare i64 @llvm.experimental.constrained.lround.i64.f16(half, metadata)
declare i64 @llvm.experimental.constrained.lround.i64.bf16(bfloat, metadata)
declare i64 @llvm.experimental.constrained.lround.i64.f128(fp128, metadata)
declare float @llvm.experimental.constrained.fadd.f32(float, float, metadata, metadata)
declare <2 x half> @llvm.experimental.constrained.pow.v2f16(<2 x half>, <2 x half>, metadata, metadata)

define i64 @protected_clrint_f32(float %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.experimental.constrained.lrint.i64.f32(float %a, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret i64 %r
}

define i64 @protected_cllrint_dyn_f32(float %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.experimental.constrained.llrint.i64.f32(float %a, metadata !"round.dynamic", metadata !"fpexcept.maytrap")
  ret i64 %r
}

define i64 @protected_clrint_down_f32(float %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.experimental.constrained.lrint.i64.f32(float %a, metadata !"round.downward", metadata !"fpexcept.strict")
  ret i64 %r
}

define i64 @protected_cllrint_up_f32(float %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.experimental.constrained.llrint.i64.f32(float %a, metadata !"round.upward", metadata !"fpexcept.ignore")
  ret i64 %r
}

define i64 @protected_clrint_zero_f32(float %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.experimental.constrained.lrint.i64.f32(float %a, metadata !"round.towardzero", metadata !"fpexcept.ignore")
  ret i64 %r
}

define i64 @protected_clround_f32(float %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.experimental.constrained.lround.i64.f32(float %a, metadata !"fpexcept.ignore")
  ret i64 %r
}

define i64 @protected_cllround_maytrap_f32(float %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.experimental.constrained.llround.i64.f32(float %a, metadata !"fpexcept.maytrap")
  ret i64 %r
}

define i64 @protected_clround_strict_f32(float %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.experimental.constrained.lround.i64.f32(float %a, metadata !"fpexcept.strict")
  ret i64 %r
}

define i64 @protected_clrint_f64(double %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.experimental.constrained.lrint.i64.f64(double %a, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret i64 %r
}

define i64 @protected_cllrint_f64(double %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.experimental.constrained.llrint.i64.f64(double %a, metadata !"round.dynamic", metadata !"fpexcept.maytrap")
  ret i64 %r
}

define i64 @protected_clround_f64(double %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.experimental.constrained.lround.i64.f64(double %a, metadata !"fpexcept.ignore")
  ret i64 %r
}

define i64 @protected_cllround_f64(double %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.experimental.constrained.llround.i64.f64(double %a, metadata !"fpexcept.strict")
  ret i64 %r
}

define i32 @protected_clrint_i32_f32(float %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.experimental.constrained.lrint.i32.f32(float %a, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret i32 %r
}

define i32 @protected_clround_i32_f32(float %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.experimental.constrained.lround.i32.f32(float %a, metadata !"fpexcept.ignore")
  ret i32 %r
}

define i32 @protected_clrint_i32_f64(double %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.experimental.constrained.lrint.i32.f64(double %a, metadata !"round.downward", metadata !"fpexcept.strict")
  ret i32 %r
}

define i32 @protected_clround_i32_f64(double %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.experimental.constrained.lround.i32.f64(double %a, metadata !"fpexcept.maytrap")
  ret i32 %r
}


define i64 @protected_clround_phi_f32(float %a, float %b, i1 %c) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  br i1 %c, label %left, label %right
left:
  %l = call i64 @llvm.experimental.constrained.lround.i64.f32(float %a, metadata !"fpexcept.ignore")
  br label %join
right:
  %r = call i64 @llvm.experimental.constrained.llround.i64.f32(float %b, metadata !"fpexcept.ignore")
  br label %join
join:
  %p = phi i64 [ %l, %left ], [ %r, %right ]
  ret i64 %p
}

define i64 @protected_clrint_loop_f32(float %a, i32 %n) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  br label %hdr
hdr:
  %acc = phi float [ %a, %entry ], [ %nxt, %hdr ]
  %i = phi i32 [ 0, %entry ], [ %i.nxt, %hdr ]
  %cur = call i64 @llvm.experimental.constrained.lrint.i64.f32(float %acc, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  %nxt = call float @llvm.experimental.constrained.fadd.f32(float %acc, float 1.000000e+00, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  %i.nxt = add i32 %i, 1
  %more = icmp ult i32 %i.nxt, %n
  br i1 %more, label %hdr, label %done
done:
  ret i64 %cur
}

define i32 @unsupported_cllround_i32(float %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.experimental.constrained.llround.i32.f32(float %a, metadata !"fpexcept.ignore")
  ret i32 %r
}

define i32 @unsupported_cllrint_i32(float %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.experimental.constrained.llrint.i32.f32(float %a, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret i32 %r
}

define i16 @unsupported_clround_i16(float %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call i16 @llvm.experimental.constrained.lround.i16.f32(float %a, metadata !"fpexcept.ignore")
  ret i16 %r
}

define i128 @unsupported_clround_i128(float %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call i128 @llvm.experimental.constrained.lround.i128.f32(float %a, metadata !"fpexcept.ignore")
  ret i128 %r
}

define i64 @unsupported_clround_half(half %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.experimental.constrained.lround.i64.f16(half %a, metadata !"fpexcept.ignore")
  ret i64 %r
}

define i64 @unsupported_clround_bfloat(bfloat %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.experimental.constrained.lround.i64.bf16(bfloat %a, metadata !"fpexcept.ignore")
  ret i64 %r
}

define i64 @unsupported_clround_fp128(fp128 %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.experimental.constrained.lround.i64.f128(fp128 %a, metadata !"fpexcept.ignore")
  ret i64 %r
}

define <2 x half> @unsupported_cceil_vector(<2 x half> %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call <2 x half> @llvm.experimental.constrained.pow.v2f16(<2 x half> %a, <2 x half> %a, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret <2 x half> %r
}

define i64 @unsupported_clround_fastcc(float %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call fastcc i64 @llvm.experimental.constrained.lround.i64.f32(float %a, metadata !"fpexcept.ignore")
  ret i64 %r
}

define i64 @unsupported_clround_musttail(float %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = musttail call i64 @llvm.experimental.constrained.lround.i64.f32(float %a, metadata !"fpexcept.ignore")
  ret i64 %r
}

define i64 @unsupported_clround_bundle(float %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.experimental.constrained.lround.i64.f32(float %a, metadata !"fpexcept.ignore") [ "deopt"(i32 0) ]
  ret i64 %r
}

define i64 @unsupported_clround_poison() noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.experimental.constrained.lround.i64.f32(float poison, metadata !"fpexcept.ignore")
  ret i64 %r
}

define i64 @unsupported_clround_undef() noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.experimental.constrained.lround.i64.f32(float undef, metadata !"fpexcept.ignore")
  ret i64 %r
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_cllround_i32: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_cllrint_i32: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_clround_i16: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_clround_i128: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_clround_half: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_clround_bfloat: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_clround_fp128: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_cceil_vector: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_clround_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_clround_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_clround_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_clround_poison: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_clround_undef: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_clrint_f32:
; SKIP-NOT: Skipping VMP on protected_cllrint_dyn_f32:
; SKIP-NOT: Skipping VMP on protected_clrint_down_f32:
; SKIP-NOT: Skipping VMP on protected_cllrint_up_f32:
; SKIP-NOT: Skipping VMP on protected_clrint_zero_f32:
; SKIP-NOT: Skipping VMP on protected_clround_f32:
; SKIP-NOT: Skipping VMP on protected_cllround_maytrap_f32:
; SKIP-NOT: Skipping VMP on protected_clround_strict_f32:
; SKIP-NOT: Skipping VMP on protected_clrint_f64:
; SKIP-NOT: Skipping VMP on protected_cllrint_f64:
; SKIP-NOT: Skipping VMP on protected_clround_f64:
; SKIP-NOT: Skipping VMP on protected_cllround_f64:
; SKIP-NOT: Skipping VMP on protected_clrint_i32_f32:
; SKIP-NOT: Skipping VMP on protected_clround_i32_f32:
; SKIP-NOT: Skipping VMP on protected_clrint_i32_f64:
; SKIP-NOT: Skipping VMP on protected_clround_i32_f64:
; SKIP-NOT: Skipping VMP on protected_clround_phi_f32:
; SKIP-NOT: Skipping VMP on protected_clrint_loop_f32:

; VIRT: define i64 @protected_clrint_f32({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.experimental.constrained.lrint.i64.f32({{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")
; VIRT: define i64 @protected_cllrint_dyn_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.experimental.constrained.llrint.i64.f32({{.*}}, metadata !"round.dynamic", metadata !"fpexcept.maytrap")
; VIRT: define i64 @protected_clrint_down_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.experimental.constrained.lrint.i64.f32({{.*}}, metadata !"round.downward", metadata !"fpexcept.strict")
; VIRT: define i64 @protected_cllrint_up_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.experimental.constrained.llrint.i64.f32({{.*}}, metadata !"round.upward", metadata !"fpexcept.ignore")
; VIRT: define i64 @protected_clrint_zero_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.experimental.constrained.lrint.i64.f32({{.*}}, metadata !"round.towardzero", metadata !"fpexcept.ignore")
; VIRT: define i64 @protected_clround_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.experimental.constrained.lround.i64.f32({{.*}}, metadata !"fpexcept.ignore")
; VIRT: define i64 @protected_cllround_maytrap_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.experimental.constrained.llround.i64.f32({{.*}}, metadata !"fpexcept.maytrap")
; VIRT: define i64 @protected_clround_strict_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.experimental.constrained.lround.i64.f32({{.*}}, metadata !"fpexcept.strict")
; VIRT: define i64 @protected_clrint_f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.experimental.constrained.lrint.i64.f64({{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")
; VIRT: define i64 @protected_cllrint_f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.experimental.constrained.llrint.i64.f64({{.*}}, metadata !"round.dynamic", metadata !"fpexcept.maytrap")
; VIRT: define i64 @protected_clround_f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.experimental.constrained.lround.i64.f64({{.*}}, metadata !"fpexcept.ignore")
; VIRT: define i64 @protected_cllround_f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.experimental.constrained.llround.i64.f64({{.*}}, metadata !"fpexcept.strict")
; VIRT: define i32 @protected_clrint_i32_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.experimental.constrained.lrint.i32.f32({{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")
; VIRT: define i32 @protected_clround_i32_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.experimental.constrained.lround.i32.f32({{.*}}, metadata !"fpexcept.ignore")
; VIRT: define i32 @protected_clrint_i32_f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.experimental.constrained.lrint.i32.f64({{.*}}, metadata !"round.downward", metadata !"fpexcept.strict")
; VIRT: define i32 @protected_clround_i32_f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.experimental.constrained.lround.i32.f64({{.*}}, metadata !"fpexcept.maytrap")
; VIRT: define i64 @protected_clround_phi_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.experimental.constrained.lround.i64.f32({{.*}}, metadata !"fpexcept.ignore")
; VIRT: define i64 @protected_clrint_loop_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.experimental.constrained.lrint.i64.f32({{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")
; VIRT: define {{.*}} @unsupported_cllround_i32({{.*}} #[[UNSUPCC:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cllrint_i32({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_clround_i16({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_clround_i128({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_clround_half({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_clround_bfloat({{.*}} #[[UNSUP_ARG:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_clround_fp128({{.*}} #[[UNSUP_ARG]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cceil_vector({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_clround_fastcc({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_clround_musttail({{.*}} #[[UNSUP_MT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call i64 @llvm.experimental.constrained.lround.i64.f32(
; VIRT: define {{.*}} @unsupported_clround_bundle({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call i64 @llvm.experimental.constrained.lround.i64.f32({{.*}}[ "deopt"(i32 0) ]
; VIRT: define {{.*}} @unsupported_clround_poison({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_clround_undef({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPCC]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPCC]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_MT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_ARG]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
