; Restricted AArch64 NEON across-lane floating-point min/max reduce
; via CallDescriptor: fminv / fmaxv / fminnmv / fmaxnmv
; Exact IntrinsicsAArch64.td AdvSIMD_1VectorArg_Float_Across_Intrinsic:
;   anyfloat (anyvector)
; This surface further requires a scalar f32/f64 result whose type
; matches the element type of one practical AArch64 ISel f32/f64
; vector: 64-bit <2 x float> or 128-bit <4 x float>/<2 x double>.
; half/bfloat, <1 x double>, leftover <3 x float>, mismatched result
; width, integer sminv (independent surface), SVE,
; and arm.neon stay out.
; Call site must be CallingConv::C and non-vararg.
; Re-emitted via CallDescriptor (vector VReg in, scalar float VReg
; out).  No dedicated VM opcode.  No extra +neon / +fullfp16 gate.
; Does not widen the ordinary or pairwise ID lists.
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
declare float @llvm.aarch64.neon.fminv.f32.v2f32(<2 x float>)
declare float @llvm.aarch64.neon.fmaxv.f32.v4f32(<4 x float>)
declare double @llvm.aarch64.neon.fminnmv.f64.v2f64(<2 x double>)
declare float @llvm.aarch64.neon.fmaxnmv.f32.v2f32(<2 x float>)
declare float @llvm.aarch64.neon.fminv.f32.v4f32(<4 x float>)
declare double @llvm.aarch64.neon.fmaxnmv.f64.v2f64(<2 x double>)
declare half @llvm.aarch64.neon.fminv.f16.v4f16(<4 x half>)
declare bfloat @llvm.aarch64.neon.fminv.bf16.v4bf16(<4 x bfloat>)
declare double @llvm.aarch64.neon.fminv.f64.v1f64(<1 x double>)
declare float @llvm.aarch64.neon.fminv.f32.v3f32(<3 x float>)
declare double @llvm.aarch64.neon.fminv.f64.v4f32(<4 x float>)
declare float @llvm.aarch64.sve.fminv.v4f32(<4 x i1>, <4 x float>)
declare <4 x float> @llvm.arm.neon.vmins.v4f32(<4 x float>, <4 x float>)

@sink = global [128 x i8] zeroinitializer, align 16

define float @protected_fminv_v2f32(<2 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.aarch64.neon.fminv.f32.v2f32(<2 x float> %a)
  ret float %r
}

define float @protected_fmaxv_v4f32(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.aarch64.neon.fmaxv.f32.v4f32(<4 x float> %a)
  ret float %r
}

define double @protected_fminnmv_v2f64(<2 x double> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call double @llvm.aarch64.neon.fminnmv.f64.v2f64(<2 x double> %a)
  ret double %r
}

define float @protected_fmaxnmv_v2f32(<2 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.aarch64.neon.fmaxnmv.f32.v2f32(<2 x float> %a)
  ret float %r
}

define float @protected_fminv_v4f32(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.aarch64.neon.fminv.f32.v4f32(<4 x float> %a)
  ret float %r
}

define double @protected_fmaxnmv_v2f64(<2 x double> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call double @llvm.aarch64.neon.fmaxnmv.f64.v2f64(<2 x double> %a)
  ret double %r
}

; ----- negatives: selected, not virtualized -----

define half @unsupported_fminmaxv_half(<4 x half> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.aarch64.neon.fminv.f16.v4f16(<4 x half> %a)
  ret half %r
}

define void @unsupported_fminmaxv_bfloat() noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.aarch64.neon.fminv.bf16.v4bf16(<4 x bfloat> zeroinitializer)
  ret void
}

define double @unsupported_fminmaxv_v1f64(<1 x double> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call double @llvm.aarch64.neon.fminv.f64.v1f64(<1 x double> %a)
  ret double %r
}

define float @unsupported_fminmaxv_v3f32(<3 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.aarch64.neon.fminv.f32.v3f32(<3 x float> %a)
  ret float %r
}

define double @unsupported_fminmaxv_mismatch(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call double @llvm.aarch64.neon.fminv.f64.v4f32(<4 x float> %a)
  ret double %r
}

; Well-formed llvm.aarch64.neon.sminv is covered by
; vmp-aarch64-neon-int-across-semantic.ll and must not stay here
; as a negative (it would virtualize).  Well-formed
; llvm.aarch64.neon.faddv is vmp-aarch64-neon-faddv-semantic.ll.

define float @unsupported_fminmaxv_sve(<4 x i1> %pg, <4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.aarch64.sve.fminv.v4f32(<4 x i1> %pg, <4 x float> %a)
  ret float %r
}

define <4 x float> @unsupported_fminmaxv_arm(<4 x float> %a, <4 x float> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x float> @llvm.arm.neon.vmins.v4f32(<4 x float> %a, <4 x float> %b)
  ret <4 x float> %r
}

define float @unsupported_fminmaxv_fastcc(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc float @llvm.aarch64.neon.fmaxv.f32.v4f32(<4 x float> %a)
  ret float %r
}

define float @unsupported_fminmaxv_musttail(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call float @llvm.aarch64.neon.fmaxv.f32.v4f32(<4 x float> %a)
  ret float %r
}

define float @unsupported_fminmaxv_bundle(<4 x float> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.aarch64.neon.fmaxv.f32.v4f32(<4 x float> %a) [ "deopt"(i32 0) ]
  ret float %r
}

define i32 @main() {
entry:
  %p = getelementptr inbounds [128 x i8], ptr @sink, i64 0, i64 0
  %a2 = load volatile <2 x float>, ptr %p, align 8
  %r2 = call float @protected_fminv_v2f32(<2 x float> %a2)
  store volatile float %r2, ptr %p, align 4
  %a4 = load volatile <4 x float>, ptr %p, align 16
  %r4 = call float @protected_fmaxv_v4f32(<4 x float> %a4)
  store volatile float %r4, ptr %p, align 4
  %ad = load volatile <2 x double>, ptr %p, align 16
  %rd = call double @protected_fminnmv_v2f64(<2 x double> %ad)
  store volatile double %rd, ptr %p, align 8
  %rn = call float @protected_fmaxnmv_v2f32(<2 x float> %a2)
  store volatile float %rn, ptr %p, align 4
  %rf = call float @protected_fminv_v4f32(<4 x float> %a4)
  store volatile float %rf, ptr %p, align 4
  %rm = call double @protected_fmaxnmv_v2f64(<2 x double> %ad)
  store volatile double %rm, ptr %p, align 8
  ret i32 0
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_fminmaxv_half: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_fminmaxv_bfloat: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_fminmaxv_v1f64: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_fminmaxv_v3f32: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_fminmaxv_mismatch: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_fminmaxv_sve: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_fminmaxv_arm: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_fminmaxv_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_fminmaxv_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_fminmaxv_bundle: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_fminv_v2f32:
; SKIP-NOT: Skipping VMP on protected_fmaxv_v4f32:
; SKIP-NOT: Skipping VMP on protected_fminnmv_v2f64:
; SKIP-NOT: Skipping VMP on protected_fmaxnmv_v2f32:
; SKIP-NOT: Skipping VMP on protected_fminv_v4f32:
; SKIP-NOT: Skipping VMP on protected_fmaxnmv_v2f64:

; VIRT: define float @protected_fminv_v2f32({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.aarch64.neon.fminv.f32.v2f32(
; VIRT: define float @protected_fmaxv_v4f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.aarch64.neon.fmaxv.f32.v4f32(
; VIRT: define double @protected_fminnmv_v2f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call double @llvm.aarch64.neon.fminnmv.f64.v2f64(
; VIRT: define float @protected_fmaxnmv_v2f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.aarch64.neon.fmaxnmv.f32.v2f32(
; VIRT: define float @protected_fminv_v4f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.aarch64.neon.fminv.f32.v4f32(
; VIRT: define double @protected_fmaxnmv_v2f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call double @llvm.aarch64.neon.fmaxnmv.f64.v2f64(
; VIRT: define {{.*}} @unsupported_fminmaxv_half({{.*}} #[[UNSUPATTR:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fminmaxv_bfloat({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fminmaxv_v1f64({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fminmaxv_v3f32({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fminmaxv_mismatch({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fminmaxv_sve({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fminmaxv_arm({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fminmaxv_fastcc({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fminmaxv_musttail({{.*}} #[[UNSUP_MT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call float @llvm.aarch64.neon.fmaxv.f32.v4f32(
; VIRT: define {{.*}} @unsupported_fminmaxv_bundle({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call float @llvm.aarch64.neon.fmaxv.f32.v4f32({{.*}}[ "deopt"(i32 0) ]
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_MT]] = { {{.*}}"hikari.vmp.virtualized"
