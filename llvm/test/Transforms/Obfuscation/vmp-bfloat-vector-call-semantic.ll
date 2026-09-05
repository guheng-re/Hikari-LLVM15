; Ordinary last-token +bf16 direct non-intrinsic C calls whose
; already-supported argument and return surface is extended with
; scalar bfloat and fixed 1..128 bfloat vectors.  Exact token only
; when a bfloat vector participates.  Reuses CallDescriptor, the
; existing vector VReg frame, and direct-call reconstruction: vector
; args load from the frame, typed normal calls keep the original
; symbol, and vector results store back.  Listed bfloat math is not
; replayed on this path.  Scalar-only bfloat C calls stay on the
; existing scalar surface (both sides C and non-vararg).  Ordinary
; tail is accepted and replayed as a non-tail CallInst.
;
; Mixed ordinary i32/ptr/half/f32/f64/fixed-vector/flat-aggregate
; values are allowed only when they already pass the ordinary
; direct-call safety rules.  Recursive and inter-function calls keep
; the original Function* symbol.
;
; Rejected: musttail, operand bundles,
; noreturn/returns_twice, inline asm, complex ABI, pointer vectors,
; scalable/overwide bfloat vectors, bfloat aggregates, poison/undef,
; missing or last-token -bf16, and FastMathFlags on FP results.
;
; Host x86 cannot be assumed to select bfloat.  This lit is FileCheck
; + AArch64 llc/readobj only (function +bf16, no global -mattr).
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

%Pair = type { i32, i32 }

declare void @hikari_vmp()
declare bfloat @ext_bf16(bfloat)
declare <4 x bfloat> @ext_v4bf16(<4 x bfloat>)
declare <8 x bfloat> @ext_v8bf16(<8 x bfloat>)
declare void @ext_v4bf16_sink(<4 x bfloat>)
declare <4 x bfloat> @ext_v4bf16_src()
declare i32 @ext_v4bf16_to_i32(<4 x bfloat>)
declare <4 x bfloat> @ext_mixed(<4 x bfloat>, i32, ptr, float, double, half, <2 x i32>)
declare <4 x bfloat> @ext_mixed_agg(<4 x bfloat>, %Pair)
declare <4 x bfloat> @ext_mixed_scalar(<4 x bfloat>, bfloat)
declare <4 x bfloat> @cross_id(<4 x bfloat>)
declare <4 x bfloat> @ext_v4bf16_vararg(<4 x bfloat>, ...)
declare void @ext_v4bf16_noreturn(<4 x bfloat>) noreturn
declare <4 x bfloat> @ext_v4bf16_rtwice(<4 x bfloat>) returns_twice
declare void @ext_v4_sret(ptr sret(i32), <4 x bfloat>)
declare <16 x bfloat> @ext_v16bf16(<16 x bfloat>)
declare <vscale x 4 x bfloat> @ext_nxv4bf16(<vscale x 4 x bfloat>)
declare { bfloat } @ext_bf_agg({ bfloat })
declare <2 x ptr> @ext_ptrvec(<2 x ptr>)

; ----- positives -----

define bfloat @protected_call_scalar(bfloat %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @ext_bf16(bfloat %a)
  ret bfloat %r
}

define <4 x bfloat> @protected_call_v4(<4 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x bfloat> @ext_v4bf16(<4 x bfloat> %a)
  ret <4 x bfloat> %r
}

define <8 x bfloat> @protected_call_v8(<8 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <8 x bfloat> @ext_v8bf16(<8 x bfloat> %a)
  ret <8 x bfloat> %r
}

define void @protected_call_sink(<4 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  call void @ext_v4bf16_sink(<4 x bfloat> %a)
  ret void
}

define <4 x bfloat> @protected_call_src() noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x bfloat> @ext_v4bf16_src()
  ret <4 x bfloat> %r
}

define i32 @protected_call_to_i32(<4 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call i32 @ext_v4bf16_to_i32(<4 x bfloat> %a)
  ret i32 %r
}

define <4 x bfloat> @protected_mixed(<4 x bfloat> %v, i32 %i, ptr %p, float %f, double %d, half %h, <2 x i32> %iv) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x bfloat> @ext_mixed(<4 x bfloat> %v, i32 %i, ptr %p, float %f, double %d, half %h, <2 x i32> %iv)
  ret <4 x bfloat> %r
}

define <4 x bfloat> @protected_mixed_agg(<4 x bfloat> %v, %Pair %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x bfloat> @ext_mixed_agg(<4 x bfloat> %v, %Pair %a)
  ret <4 x bfloat> %r
}

define <4 x bfloat> @protected_mixed_scalar(<4 x bfloat> %v, bfloat %s) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x bfloat> @ext_mixed_scalar(<4 x bfloat> %v, bfloat %s)
  ret <4 x bfloat> %r
}

define <4 x bfloat> @protected_recursive(<4 x bfloat> %a, i32 %n) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %z = icmp eq i32 %n, 0
  br i1 %z, label %done, label %rec

rec:
  %n1 = add i32 %n, -1
  %r = call <4 x bfloat> @protected_recursive(<4 x bfloat> %a, i32 %n1)
  ret <4 x bfloat> %r

done:
  ret <4 x bfloat> %a
}



define <4 x bfloat> @protected_cross(<4 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x bfloat> @cross_id(<4 x bfloat> %a)
  ret <4 x bfloat> %r
}

define <4 x bfloat> @protected_last_token(<4 x bfloat> %a) noinline optnone "target-features"="+neon,+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x bfloat> @ext_v4bf16(<4 x bfloat> %a)
  ret <4 x bfloat> %r
}

; ----- negatives -----

define i32 @unsupported_call_no_feature() noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x bfloat> @ext_v4bf16(<4 x bfloat> zeroinitializer)
  ret i32 0
}

define i32 @unsupported_call_disabled() noinline optnone "target-features"="+neon,+bf16,-bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x bfloat> @ext_v4bf16(<4 x bfloat> zeroinitializer)
  ret i32 0
}

define i32 @unsupported_call_bf16fml_only() noinline optnone "target-features"="+bf16fml" {
entry:
  call void @hikari_vmp()
  %r = call <4 x bfloat> @ext_v4bf16(<4 x bfloat> zeroinitializer)
  ret i32 0
}

define <4 x bfloat> @unsupported_call_fmf(<4 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call nnan <4 x bfloat> @ext_v4bf16(<4 x bfloat> %a)
  ret <4 x bfloat> %r
}

define <4 x bfloat> @unsupported_call_fastcc(<4 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call fastcc <4 x bfloat> @ext_v4bf16(<4 x bfloat> %a)
  ret <4 x bfloat> %r
}

define <4 x bfloat> @unsupported_call_musttail(<4 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = musttail call <4 x bfloat> @ext_v4bf16(<4 x bfloat> %a)
  ret <4 x bfloat> %r
}

define <4 x bfloat> @unsupported_call_vararg(<4 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x bfloat> (<4 x bfloat>, ...) @ext_v4bf16_vararg(<4 x bfloat> %a)
  ret <4 x bfloat> %r
}

; Ordinary C indirect is the independent +bf16 surface
; (vmp-bfloat-indirect-call-semantic.ll).  fastcc keeps this
; sentinel closed; ordinary tail is now a positive on that surface.
define <4 x bfloat> @unsupported_call_indirect(ptr %fp, <4 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call fastcc <4 x bfloat> %fp(<4 x bfloat> %a)
  ret <4 x bfloat> %r
}

define <4 x bfloat> @unsupported_call_bundle(<4 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x bfloat> @ext_v4bf16(<4 x bfloat> %a) [ "deopt"() ]
  ret <4 x bfloat> %r
}

define void @unsupported_call_noreturn(<4 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  call void @ext_v4bf16_noreturn(<4 x bfloat> %a)
  unreachable
}

define <4 x bfloat> @unsupported_call_returns_twice(<4 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x bfloat> @ext_v4bf16_rtwice(<4 x bfloat> %a)
  ret <4 x bfloat> %r
}

define <4 x bfloat> @unsupported_call_poison() noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x bfloat> @ext_v4bf16(<4 x bfloat> poison)
  ret <4 x bfloat> %r
}

define <4 x bfloat> @unsupported_call_undef() noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x bfloat> @ext_v4bf16(<4 x bfloat> undef)
  ret <4 x bfloat> %r
}

define i32 @unsupported_call_wide() noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <16 x bfloat> @ext_v16bf16(<16 x bfloat> zeroinitializer)
  ret i32 0
}

define i32 @unsupported_call_scalable() noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x bfloat> @ext_nxv4bf16(<vscale x 4 x bfloat> zeroinitializer)
  ret i32 0
}

define i32 @unsupported_call_agg() noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call { bfloat } @ext_bf_agg({ bfloat } zeroinitializer)
  ret i32 0
}

define i32 @unsupported_call_ptrvec() noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <2 x ptr> @ext_ptrvec(<2 x ptr> zeroinitializer)
  ret i32 0
}

define <4 x bfloat> @unsupported_call_asm(<4 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x bfloat> asm "", "=w,w"(<4 x bfloat> %a)
  ret <4 x bfloat> %r
}

define void @unsupported_call_sret(ptr sret(i32) %p, <4 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  call void @ext_v4_sret(ptr sret(i32) %p, <4 x bfloat> %a)
  ret void
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_call_no_feature: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_call_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_call_bf16fml_only: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_call_fmf: unsupported float call instruction
; SKIP-DAG: Skipping VMP on unsupported_call_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_call_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_call_vararg: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_call_indirect: indirect call
; SKIP-DAG: Skipping VMP on unsupported_call_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_call_noreturn: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_call_returns_twice: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_call_poison: unsupported call
; SKIP-DAG: Skipping VMP on unsupported_call_undef: unsupported call
; SKIP-DAG: Skipping VMP on unsupported_call_wide: unsupported call
; SKIP-DAG: Skipping VMP on unsupported_call_scalable: unsupported call
; SKIP-DAG: Skipping VMP on unsupported_call_agg: unsupported call
; SKIP-DAG: Skipping VMP on unsupported_call_ptrvec: unsupported call
; SKIP-DAG: Skipping VMP on unsupported_call_asm: inline assembly
; SKIP-DAG: Skipping VMP on unsupported_call_sret: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_call_scalar:
; SKIP-NOT: Skipping VMP on protected_call_v4:
; SKIP-NOT: Skipping VMP on protected_call_v8:
; SKIP-NOT: Skipping VMP on protected_call_sink:
; SKIP-NOT: Skipping VMP on protected_call_src:
; SKIP-NOT: Skipping VMP on protected_call_to_i32:
; SKIP-NOT: Skipping VMP on protected_mixed:
; SKIP-NOT: Skipping VMP on protected_mixed_agg:
; SKIP-NOT: Skipping VMP on protected_mixed_scalar:
; SKIP-NOT: Skipping VMP on protected_recursive:
; SKIP-NOT: Skipping VMP on protected_cross:
; SKIP-NOT: Skipping VMP on protected_last_token:

; VIRT: define bfloat @protected_call_scalar({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: nnan
; VIRT: call{{.*}}bfloat @ext_bf16(
; VIRT: define <4 x bfloat> @protected_call_v4({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; Typed normal call plus vector-frame transfer; not LegalizeBFloatMath.
; VIRT-NOT: nnan
; VIRT-NOT: call float @llvm.
; VIRT-DAG: load volatile i128
; VIRT-DAG: bitcast {{.*}} to <4 x bfloat>
; VIRT: call{{.*}}<4 x bfloat> @ext_v4bf16(<4 x bfloat>
; VIRT-DAG: bitcast <4 x bfloat> {{.*}} to i{{.*}}
; VIRT-DAG: store volatile i128
; VIRT: define <8 x bfloat> @protected_call_v8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call float @llvm.
; VIRT: call{{.*}}<8 x bfloat> @ext_v8bf16(<8 x bfloat>
; VIRT: define void @protected_call_sink({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; Void sink is not an FPMathOperator: do not query FMF / invent nnan.
; VIRT-NOT: nnan
; VIRT: call{{.*}}void @ext_v4bf16_sink(<4 x bfloat>
; VIRT: define <4 x bfloat> @protected_call_src({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call{{.*}}<4 x bfloat> @ext_v4bf16_src(
; VIRT: define i32 @protected_call_to_i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: nnan
; VIRT: call{{.*}}i32 @ext_v4bf16_to_i32(<4 x bfloat>
; VIRT: define <4 x bfloat> @protected_mixed({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: bitcast {{.*}} to <4 x bfloat>
; VIRT-DAG: bitcast {{.*}} to <2 x i32>
; VIRT: call{{.*}}<4 x bfloat> @ext_mixed(
; VIRT: define <4 x bfloat> @protected_mixed_agg({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call{{.*}}<4 x bfloat> @ext_mixed_agg(
; VIRT: define <4 x bfloat> @protected_mixed_scalar({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: bitcast {{.*}} to <4 x bfloat>
; VIRT: call{{.*}}<4 x bfloat> @ext_mixed_scalar(
; VIRT: define <4 x bfloat> @protected_recursive({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; Recursive call keeps the original symbol.
; VIRT: call{{.*}}<4 x bfloat> @protected_recursive(
; VIRT: define <4 x bfloat> @protected_cross({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call{{.*}}<4 x bfloat> @cross_id(
; VIRT: define <4 x bfloat> @protected_last_token({{.*}} #[[PROTLAST:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call{{.*}}<4 x bfloat> @ext_v4bf16(<4 x bfloat>
; VIRT: define {{.*}} @unsupported_call_no_feature({{.*}} #[[UNSUPFEAT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_call_disabled({{.*}} #[[UNSUPDIS:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_call_bf16fml_only({{.*}} #[[UNSUPFML:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_call_fmf({{.*}} #[[UNSUPFMF:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call nnan <4 x bfloat> @ext_v4bf16(
; VIRT: define {{.*}} @unsupported_call_fastcc({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_call_musttail({{.*}} #[[UNSUPMUST:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_call_vararg({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_call_indirect({{.*}} #[[UNSUPIND:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_call_bundle({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_call_noreturn({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_call_returns_twice({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_call_poison({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_call_undef({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_call_wide({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_call_scalable({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_call_agg({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_call_ptrvec({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_call_asm({{.*}} #[[UNSUPMUST]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_call_sret({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT-DAG: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT-DAG: attributes #[[UNSUPFMF]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-DAG: attributes #[[PROTLAST]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT-DAG: attributes #[[UNSUPFEAT]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-DAG: attributes #[[UNSUPDIS]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-DAG: attributes #[[UNSUPFML]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; Direct musttail / inline asm are early deselects; +bf16 is kept,
; no selected/virtualized, no dispatcher.  They share this attr set.
; VIRT: attributes #[[UNSUPMUST]] = { noinline optnone "target-features"="+bf16" }
; VIRT-NOT: attributes #[[UNSUPFEAT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPDIS]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPFMF]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPMUST]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPMUST]] = { {{.*}}"hikari.vmp.selected"

; AARCH64: Arch: aarch64
