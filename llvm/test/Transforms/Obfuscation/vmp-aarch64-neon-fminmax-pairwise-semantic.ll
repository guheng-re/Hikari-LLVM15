; Restricted AArch64 NEON pairwise floating-point vector min/max via
; CallDescriptor: fminp / fmaxp / fminnmp / fmaxnmp
; Exact IntrinsicsAArch64.td AdvSIMD_2VectorArg_Intrinsic:
;   anyvector (match, match)
; This surface further requires the same practical AArch64 ISel
; f32/f64 vectors as ordinary neon fmin/fmax: 64-bit <2 x float> or
; 128-bit <4 x float>/<2 x double>.  half/bfloat, <1 x double>,
; leftover <3 x float>, integer anyvector,
; SVE, and arm.neon stay out.  Call site must be
; CallingConv::C and non-vararg.
; Re-emitted via CallDescriptor / vector VRegs.  No dedicated VM
; opcode.  No extra +neon / +fullfp16 gate.  Does not widen the
; ordinary fmin/fmax ID list.
;
; Host x86_64 cannot select these AArch64 intrinsics.  Do not rewrite
; them for host and do not run lli.  Validate with FileCheck + AArch64
; object generation on the live main-reachable subset.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.ll -o %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.ll -o %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.s7.ll -o %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.s7.ll -o %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare <2 x float> @llvm.aarch64.neon.fminp.v2f32(<2 x float>, <2 x float>)
declare <4 x float> @llvm.aarch64.neon.fmaxp.v4f32(<4 x float>, <4 x float>)
declare <2 x double> @llvm.aarch64.neon.fminnmp.v2f64(<2 x double>, <2 x double>)
declare <2 x float> @llvm.aarch64.neon.fmaxnmp.v2f32(<2 x float>, <2 x float>)
declare <2 x double> @llvm.aarch64.neon.fminp.v2f64(<2 x double>, <2 x double>)
declare <4 x float> @llvm.aarch64.neon.fmaxnmp.v4f32(<4 x float>, <4 x float>)
declare <4 x half> @llvm.aarch64.neon.fminp.v4f16(<4 x half>, <4 x half>)
declare <4 x bfloat> @llvm.aarch64.neon.fminp.v4bf16(<4 x bfloat>, <4 x bfloat>)
declare <1 x double> @llvm.aarch64.neon.fminp.v1f64(<1 x double>, <1 x double>)
declare <3 x float> @llvm.aarch64.neon.fminp.v3f32(<3 x float>, <3 x float>)
declare <4 x i32> @llvm.aarch64.neon.fminp.v4i32(<4 x i32>, <4 x i32>)
declare <4 x float> @llvm.aarch64.sve.fminp.v4f32(<4 x i1>, <4 x float>, <4 x float>)
declare <4 x float> @llvm.arm.neon.vminnm.v4f32(<4 x float>, <4 x float>)

@sink = global [128 x i8] zeroinitializer, align 16

define <2 x float> @protected_fminp_v2f32(<2 x float> %a, <2 x float> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.aarch64.neon.fminp.v2f32(<2 x float> %a, <2 x float> %b)
  ret <2 x float> %r
}

define <4 x float> @protected_fmaxp_v4f32(<4 x float> %a, <4 x float> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.fmaxp.v4f32(<4 x float> %a, <4 x float> %b)
  ret <4 x float> %r
}

define <2 x double> @protected_fminnmp_v2f64(<2 x double> %a, <2 x double> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x double> @llvm.aarch64.neon.fminnmp.v2f64(<2 x double> %a, <2 x double> %b)
  ret <2 x double> %r
}

define <2 x float> @protected_fmaxnmp_v2f32(<2 x float> %a, <2 x float> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x float> @llvm.aarch64.neon.fmaxnmp.v2f32(<2 x float> %a, <2 x float> %b)
  ret <2 x float> %r
}

define <2 x double> @protected_fminp_v2f64(<2 x double> %a, <2 x double> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x double> @llvm.aarch64.neon.fminp.v2f64(<2 x double> %a, <2 x double> %b)
  ret <2 x double> %r
}

define <4 x float> @protected_fmaxnmp_v4f32(<4 x float> %a, <4 x float> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.fmaxnmp.v4f32(<4 x float> %a, <4 x float> %b)
  ret <4 x float> %r
}

; ----- negatives: selected, not virtualized -----

define <4 x half> @unsupported_fminmaxp_half(<4 x half> %a, <4 x half> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x half> @llvm.aarch64.neon.fminp.v4f16(<4 x half> %a, <4 x half> %b)
  ret <4 x half> %r
}

define void @unsupported_fminmaxp_bfloat() noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x bfloat> @llvm.aarch64.neon.fminp.v4bf16(<4 x bfloat> zeroinitializer, <4 x bfloat> zeroinitializer)
  ret void
}

define <1 x double> @unsupported_fminmaxp_v1f64(<1 x double> %a, <1 x double> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <1 x double> @llvm.aarch64.neon.fminp.v1f64(<1 x double> %a, <1 x double> %b)
  ret <1 x double> %r
}

define <3 x float> @unsupported_fminmaxp_v3f32(<3 x float> %a, <3 x float> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <3 x float> @llvm.aarch64.neon.fminp.v3f32(<3 x float> %a, <3 x float> %b)
  ret <3 x float> %r
}

define <4 x i32> @unsupported_fminmaxp_intvec(<4 x i32> %a, <4 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.fminp.v4i32(<4 x i32> %a, <4 x i32> %b)
  ret <4 x i32> %r
}

; Well-formed llvm.aarch64.neon.sminp / smaxp / uminp / umaxp is
; covered by vmp-aarch64-neon-int-pairwise-minmax-semantic.ll and
; must not stay here as a negative (it would virtualize).
; Well-formed llvm.minnum is covered by
; vmp-fp-vector-minmax-semantic.ll.  Well-formed
; llvm.aarch64.neon.faddv is vmp-aarch64-neon-faddv-semantic.ll.

define <4 x float> @unsupported_fminmaxp_sve(<4 x i1> %pg, <4 x float> %a, <4 x float> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.sve.fminp.v4f32(<4 x i1> %pg, <4 x float> %a, <4 x float> %b)
  ret <4 x float> %r
}

define <4 x float> @unsupported_fminmaxp_arm(<4 x float> %a, <4 x float> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.arm.neon.vminnm.v4f32(<4 x float> %a, <4 x float> %b)
  ret <4 x float> %r
}

define <4 x float> @unsupported_fminmaxp_fastcc(<4 x float> %a, <4 x float> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc <4 x float> @llvm.aarch64.neon.fmaxp.v4f32(<4 x float> %a, <4 x float> %b)
  ret <4 x float> %r
}

define <4 x float> @unsupported_fminmaxp_musttail(<4 x float> %a, <4 x float> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call <4 x float> @llvm.aarch64.neon.fmaxp.v4f32(<4 x float> %a, <4 x float> %b)
  ret <4 x float> %r
}

define <4 x float> @unsupported_fminmaxp_bundle(<4 x float> %a, <4 x float> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.aarch64.neon.fmaxp.v4f32(<4 x float> %a, <4 x float> %b) [ "deopt"(i32 0) ]
  ret <4 x float> %r
}

define i32 @main() {
entry:
  %p = getelementptr inbounds [128 x i8], ptr @sink, i64 0, i64 0
  %a2 = load volatile <2 x float>, ptr %p, align 8
  %r2 = call <2 x float> @protected_fminp_v2f32(<2 x float> %a2, <2 x float> %a2)
  store volatile <2 x float> %r2, ptr %p, align 8
  %a4 = load volatile <4 x float>, ptr %p, align 16
  %r4 = call <4 x float> @protected_fmaxp_v4f32(<4 x float> %a4, <4 x float> %a4)
  store volatile <4 x float> %r4, ptr %p, align 16
  %ad = load volatile <2 x double>, ptr %p, align 16
  %rd = call <2 x double> @protected_fminnmp_v2f64(<2 x double> %ad, <2 x double> %ad)
  store volatile <2 x double> %rd, ptr %p, align 16
  %rn = call <2 x float> @protected_fmaxnmp_v2f32(<2 x float> %a2, <2 x float> %a2)
  store volatile <2 x float> %rn, ptr %p, align 8
  %rf = call <2 x double> @protected_fminp_v2f64(<2 x double> %ad, <2 x double> %ad)
  store volatile <2 x double> %rf, ptr %p, align 16
  %rm = call <4 x float> @protected_fmaxnmp_v4f32(<4 x float> %a4, <4 x float> %a4)
  store volatile <4 x float> %rm, ptr %p, align 16
  ret i32 0
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_fminmaxp_half: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_fminmaxp_bfloat: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_fminmaxp_v1f64: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_fminmaxp_v3f32: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_fminmaxp_intvec: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_fminmaxp_sve: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_fminmaxp_arm: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_fminmaxp_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_fminmaxp_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_fminmaxp_bundle: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_fminp_v2f32:
; SKIP-NOT: Skipping VMP on protected_fmaxp_v4f32:
; SKIP-NOT: Skipping VMP on protected_fminnmp_v2f64:
; SKIP-NOT: Skipping VMP on protected_fmaxnmp_v2f32:
; SKIP-NOT: Skipping VMP on protected_fminp_v2f64:
; SKIP-NOT: Skipping VMP on protected_fmaxnmp_v4f32:

; VIRT: define <2 x float> @protected_fminp_v2f32({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x float> @llvm.aarch64.neon.fminp.v2f32(
; VIRT: define <4 x float> @protected_fmaxp_v4f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x float> @llvm.aarch64.neon.fmaxp.v4f32(
; VIRT: define <2 x double> @protected_fminnmp_v2f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x double> @llvm.aarch64.neon.fminnmp.v2f64(
; VIRT: define <2 x float> @protected_fmaxnmp_v2f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x float> @llvm.aarch64.neon.fmaxnmp.v2f32(
; VIRT: define <2 x double> @protected_fminp_v2f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x double> @llvm.aarch64.neon.fminp.v2f64(
; VIRT: define <4 x float> @protected_fmaxnmp_v4f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x float> @llvm.aarch64.neon.fmaxnmp.v4f32(
; VIRT: define {{.*}} @unsupported_fminmaxp_half({{.*}} #[[UNSUPATTR:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fminmaxp_bfloat({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fminmaxp_v1f64({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fminmaxp_v3f32({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fminmaxp_intvec({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fminmaxp_sve({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fminmaxp_arm({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fminmaxp_fastcc({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fminmaxp_musttail({{.*}} #[[UNSUP_MT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call <4 x float> @llvm.aarch64.neon.fmaxp.v4f32(
; VIRT: define {{.*}} @unsupported_fminmaxp_bundle({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call <4 x float> @llvm.aarch64.neon.fmaxp.v4f32({{.*}}[ "deopt"(i32 0) ]
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_MT]] = { {{.*}}"hikari.vmp.virtualized"
