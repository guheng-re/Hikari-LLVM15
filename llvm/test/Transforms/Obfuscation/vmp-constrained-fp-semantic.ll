; Restricted scalar llvm.experimental.constrained.fadd/fsub/fmul/fdiv/
; frem/fma/sqrt/fcmp/fcmps on IEEE f32/f64.  Rounding, exception, and
; fcmp predicate operands are exact MDString tokens replayed via
; CallDescriptor MetadataArguments (same MetadataAsValue MDString after
; the source call is deleted).  Replayed via the existing Call opcode
; and float/integer VRegs.  No FMF path and no dedicated VM opcode.
; Ordinary tail of an already-supported CallInst is accepted and replayed as a non-tail call; see vmp-direct-call-tail-eligibility-semantic.ll.
;
; Host lli is not a strictfp environment and is not a semantic oracle.
; FileCheck + AArch64 llc/readobj only.  drop-unsupported strips
; @unsupported_* so exotic negatives never reach llc.
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
declare float @llvm.experimental.constrained.fadd.f32(float, float, metadata, metadata)
declare float @llvm.experimental.constrained.fsub.f32(float, float, metadata, metadata)
declare float @llvm.experimental.constrained.fmul.f32(float, float, metadata, metadata)
declare float @llvm.experimental.constrained.fdiv.f32(float, float, metadata, metadata)
declare float @llvm.experimental.constrained.frem.f32(float, float, metadata, metadata)
declare float @llvm.experimental.constrained.fma.f32(float, float, float, metadata, metadata)
declare float @llvm.experimental.constrained.sqrt.f32(float, metadata, metadata)
declare i1 @llvm.experimental.constrained.fcmp.f32(float, float, metadata, metadata)
declare i1 @llvm.experimental.constrained.fcmps.f32(float, float, metadata, metadata)
declare double @llvm.experimental.constrained.fadd.f64(double, double, metadata, metadata)
declare double @llvm.experimental.constrained.fsub.f64(double, double, metadata, metadata)
declare double @llvm.experimental.constrained.fmul.f64(double, double, metadata, metadata)
declare double @llvm.experimental.constrained.fdiv.f64(double, double, metadata, metadata)
declare double @llvm.experimental.constrained.frem.f64(double, double, metadata, metadata)
declare double @llvm.experimental.constrained.fma.f64(double, double, double, metadata, metadata)
declare double @llvm.experimental.constrained.sqrt.f64(double, metadata, metadata)
declare i1 @llvm.experimental.constrained.fcmp.f64(double, double, metadata, metadata)
declare i1 @llvm.experimental.constrained.fcmps.f64(double, double, metadata, metadata)
declare half @llvm.experimental.constrained.fadd.f16(half, half, metadata, metadata)
declare bfloat @llvm.experimental.constrained.fadd.bf16(bfloat, bfloat, metadata, metadata)
declare fp128 @llvm.experimental.constrained.fadd.f128(fp128, fp128, metadata, metadata)
declare float @llvm.experimental.constrained.ceil.f32(float, metadata)
declare float @llvm.experimental.constrained.sitofp.f32.i32(i32, metadata, metadata)

; ----- f32 positives -----

declare <2 x half> @llvm.experimental.constrained.pow.v2f16(<2 x half>, <2 x half>, metadata, metadata)

define float @protected_cfadd_f32(float %a, float %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.experimental.constrained.fadd.f32(float %a, float %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret float %r
}

define float @protected_cfadd_dyn_f32(float %a, float %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.experimental.constrained.fadd.f32(float %a, float %b, metadata !"round.dynamic", metadata !"fpexcept.maytrap")
  ret float %r
}

define float @protected_cfadd_down_f32(float %a, float %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.experimental.constrained.fadd.f32(float %a, float %b, metadata !"round.downward", metadata !"fpexcept.strict")
  ret float %r
}

define float @protected_cfsub_f32(float %a, float %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.experimental.constrained.fsub.f32(float %a, float %b, metadata !"round.upward", metadata !"fpexcept.ignore")
  ret float %r
}

define float @protected_cfmul_f32(float %a, float %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.experimental.constrained.fmul.f32(float %a, float %b, metadata !"round.towardzero", metadata !"fpexcept.maytrap")
  ret float %r
}

define float @protected_cfdiv_f32(float %a, float %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.experimental.constrained.fdiv.f32(float %a, float %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret float %r
}

define float @protected_cfrem_f32(float %a, float %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.experimental.constrained.frem.f32(float %a, float %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret float %r
}

define float @protected_cfma_f32(float %a, float %b, float %c) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.experimental.constrained.fma.f32(float %a, float %b, float %c, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret float %r
}

define float @protected_csqrt_f32(float %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.experimental.constrained.sqrt.f32(float %a, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret float %r
}

define i1 @protected_cfcmp_oeq_f32(float %a, float %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i1 @llvm.experimental.constrained.fcmp.f32(float %a, float %b, metadata !"oeq", metadata !"fpexcept.ignore")
  ret i1 %r
}

define i1 @protected_cfcmp_ult_f32(float %a, float %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i1 @llvm.experimental.constrained.fcmp.f32(float %a, float %b, metadata !"ult", metadata !"fpexcept.maytrap")
  ret i1 %r
}

define i1 @protected_cfcmps_ogt_f32(float %a, float %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i1 @llvm.experimental.constrained.fcmps.f32(float %a, float %b, metadata !"ogt", metadata !"fpexcept.strict")
  ret i1 %r
}


define float @protected_cfadd_phi_f32(float %a, float %b, i1 %c) noinline optnone {
entry:
  call void @hikari_vmp()
  br i1 %c, label %left, label %right
left:
  %l = call float @llvm.experimental.constrained.fadd.f32(float %a, float %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  br label %join
right:
  %r = call float @llvm.experimental.constrained.fsub.f32(float %a, float %b, metadata !"round.downward", metadata !"fpexcept.ignore")
  br label %join
join:
  %p = phi float [ %l, %left ], [ %r, %right ]
  ret float %p
}

define float @protected_cfadd_loop_f32(float %a, i32 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  br label %hdr
hdr:
  %acc = phi float [ %a, %entry ], [ %nxt, %hdr ]
  %i = phi i32 [ 0, %entry ], [ %i.nxt, %hdr ]
  %cur = call float @llvm.experimental.constrained.fadd.f32(float %acc, float 1.000000e+00, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  %nxt = call float @llvm.experimental.constrained.fadd.f32(float %acc, float 1.000000e+00, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  %i.nxt = add i32 %i, 1
  %more = icmp ult i32 %i.nxt, %n
  br i1 %more, label %hdr, label %done
done:
  ret float %cur
}

; ----- f64 positives -----

define double @protected_cfadd_f64(double %a, double %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call double @llvm.experimental.constrained.fadd.f64(double %a, double %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret double %r
}

define double @protected_cfsub_f64(double %a, double %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call double @llvm.experimental.constrained.fsub.f64(double %a, double %b, metadata !"round.dynamic", metadata !"fpexcept.maytrap")
  ret double %r
}

define double @protected_cfmul_f64(double %a, double %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call double @llvm.experimental.constrained.fmul.f64(double %a, double %b, metadata !"round.downward", metadata !"fpexcept.strict")
  ret double %r
}

define double @protected_cfdiv_f64(double %a, double %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call double @llvm.experimental.constrained.fdiv.f64(double %a, double %b, metadata !"round.upward", metadata !"fpexcept.ignore")
  ret double %r
}

define double @protected_cfrem_f64(double %a, double %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call double @llvm.experimental.constrained.frem.f64(double %a, double %b, metadata !"round.towardzero", metadata !"fpexcept.ignore")
  ret double %r
}

define double @protected_cfma_f64(double %a, double %b, double %c) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call double @llvm.experimental.constrained.fma.f64(double %a, double %b, double %c, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret double %r
}

define double @protected_csqrt_f64(double %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call double @llvm.experimental.constrained.sqrt.f64(double %a, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret double %r
}

define i1 @protected_cfcmp_one_f64(double %a, double %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i1 @llvm.experimental.constrained.fcmp.f64(double %a, double %b, metadata !"one", metadata !"fpexcept.ignore")
  ret i1 %r
}

define i1 @protected_cfcmps_uno_f64(double %a, double %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i1 @llvm.experimental.constrained.fcmps.f64(double %a, double %b, metadata !"uno", metadata !"fpexcept.maytrap")
  ret i1 %r
}

; ----- negatives -----

define half @unsupported_cfadd_half(half %a, half %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.experimental.constrained.fadd.f16(half %a, half %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret half %r
}

define bfloat @unsupported_cfadd_bfloat(bfloat %a, bfloat %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.experimental.constrained.fadd.bf16(bfloat %a, bfloat %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret bfloat %r
}

define fp128 @unsupported_cfadd_fp128(fp128 %a, fp128 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 @llvm.experimental.constrained.fadd.f128(fp128 %a, fp128 %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret fp128 %r
}

define <2 x half> @unsupported_cfadd_vector(<2 x half> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x half> @llvm.experimental.constrained.pow.v2f16(<2 x half> %a, <2 x half> %a, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret <2 x half> %r
}

; Well-shaped C constrained.ceil is now a supported rounding surface.
; fastcc keeps this a skip.
define float @unsupported_cceil_f32(float %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc float @llvm.experimental.constrained.ceil.f32(float %a, metadata !"fpexcept.ignore")
  ret float %r
}

; Well-shaped C sitofp is now a supported convert surface.  fastcc
; keeps this a skip.
define float @unsupported_csitofp_f32(i32 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc float @llvm.experimental.constrained.sitofp.f32.i32(i32 %a, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret float %r
}

define float @unsupported_cfadd_fastcc(float %a, float %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc float @llvm.experimental.constrained.fadd.f32(float %a, float %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret float %r
}

define float @unsupported_cfadd_musttail(float %a, float %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call float @llvm.experimental.constrained.fadd.f32(float %a, float %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret float %r
}

define float @unsupported_cfadd_bundle(float %a, float %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.experimental.constrained.fadd.f32(float %a, float %b, metadata !"round.tonearest", metadata !"fpexcept.ignore") [ "deopt"(i32 0) ]
  ret float %r
}

define float @unsupported_cfadd_poison(float %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.experimental.constrained.fadd.f32(float poison, float %a, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret float %r
}

define float @unsupported_cfadd_undef(float %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.experimental.constrained.fadd.f32(float undef, float %a, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret float %r
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_cfadd_half: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_cfadd_bfloat: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_cfadd_fp128: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_cfadd_vector: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_cceil_f32: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_csitofp_f32: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_cfadd_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_cfadd_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_cfadd_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_cfadd_poison: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_cfadd_undef: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_cfadd_f32:
; SKIP-NOT: Skipping VMP on protected_cfadd_dyn_f32:
; SKIP-NOT: Skipping VMP on protected_cfadd_down_f32:
; SKIP-NOT: Skipping VMP on protected_cfsub_f32:
; SKIP-NOT: Skipping VMP on protected_cfmul_f32:
; SKIP-NOT: Skipping VMP on protected_cfdiv_f32:
; SKIP-NOT: Skipping VMP on protected_cfrem_f32:
; SKIP-NOT: Skipping VMP on protected_cfma_f32:
; SKIP-NOT: Skipping VMP on protected_csqrt_f32:
; SKIP-NOT: Skipping VMP on protected_cfcmp_oeq_f32:
; SKIP-NOT: Skipping VMP on protected_cfcmp_ult_f32:
; SKIP-NOT: Skipping VMP on protected_cfcmps_ogt_f32:
; SKIP-NOT: Skipping VMP on protected_cfadd_phi_f32:
; SKIP-NOT: Skipping VMP on protected_cfadd_loop_f32:
; SKIP-NOT: Skipping VMP on protected_cfadd_f64:
; SKIP-NOT: Skipping VMP on protected_cfsub_f64:
; SKIP-NOT: Skipping VMP on protected_cfmul_f64:
; SKIP-NOT: Skipping VMP on protected_cfdiv_f64:
; SKIP-NOT: Skipping VMP on protected_cfrem_f64:
; SKIP-NOT: Skipping VMP on protected_cfma_f64:
; SKIP-NOT: Skipping VMP on protected_csqrt_f64:
; SKIP-NOT: Skipping VMP on protected_cfcmp_one_f64:
; SKIP-NOT: Skipping VMP on protected_cfcmps_uno_f64:

; VIRT: define float @protected_cfadd_f32({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.experimental.constrained.fadd.f32({{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")
; VIRT: define float @protected_cfadd_dyn_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.experimental.constrained.fadd.f32({{.*}}, metadata !"round.dynamic", metadata !"fpexcept.maytrap")
; VIRT: define float @protected_cfadd_down_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.experimental.constrained.fadd.f32({{.*}}, metadata !"round.downward", metadata !"fpexcept.strict")
; VIRT: define float @protected_cfsub_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.experimental.constrained.fsub.f32({{.*}}, metadata !"round.upward", metadata !"fpexcept.ignore")
; VIRT: define float @protected_cfmul_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.experimental.constrained.fmul.f32({{.*}}, metadata !"round.towardzero", metadata !"fpexcept.maytrap")
; VIRT: define float @protected_cfdiv_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.experimental.constrained.fdiv.f32({{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")
; VIRT: define float @protected_cfrem_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.experimental.constrained.frem.f32({{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")
; VIRT: define float @protected_cfma_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.experimental.constrained.fma.f32({{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")
; VIRT: define float @protected_csqrt_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.experimental.constrained.sqrt.f32({{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")
; VIRT: define i1 @protected_cfcmp_oeq_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i1 @llvm.experimental.constrained.fcmp.f32({{.*}}, metadata !"oeq", metadata !"fpexcept.ignore")
; VIRT: define i1 @protected_cfcmp_ult_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i1 @llvm.experimental.constrained.fcmp.f32({{.*}}, metadata !"ult", metadata !"fpexcept.maytrap")
; VIRT: define i1 @protected_cfcmps_ogt_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i1 @llvm.experimental.constrained.fcmps.f32({{.*}}, metadata !"ogt", metadata !"fpexcept.strict")
; VIRT: define float @protected_cfadd_phi_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.experimental.constrained.fadd.f32({{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")
; VIRT: define float @protected_cfadd_loop_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.experimental.constrained.fadd.f32({{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")
; VIRT: define double @protected_cfadd_f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call double @llvm.experimental.constrained.fadd.f64({{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")
; VIRT: define double @protected_cfsub_f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call double @llvm.experimental.constrained.fsub.f64({{.*}}, metadata !"round.dynamic", metadata !"fpexcept.maytrap")
; VIRT: define double @protected_cfmul_f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call double @llvm.experimental.constrained.fmul.f64({{.*}}, metadata !"round.downward", metadata !"fpexcept.strict")
; VIRT: define double @protected_cfdiv_f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call double @llvm.experimental.constrained.fdiv.f64({{.*}}, metadata !"round.upward", metadata !"fpexcept.ignore")
; VIRT: define double @protected_cfrem_f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call double @llvm.experimental.constrained.frem.f64({{.*}}, metadata !"round.towardzero", metadata !"fpexcept.ignore")
; VIRT: define double @protected_cfma_f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call double @llvm.experimental.constrained.fma.f64({{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")
; VIRT: define double @protected_csqrt_f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call double @llvm.experimental.constrained.sqrt.f64({{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")
; VIRT: define i1 @protected_cfcmp_one_f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i1 @llvm.experimental.constrained.fcmp.f64({{.*}}, metadata !"one", metadata !"fpexcept.ignore")
; VIRT: define i1 @protected_cfcmps_uno_f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i1 @llvm.experimental.constrained.fcmps.f64({{.*}}, metadata !"uno", metadata !"fpexcept.maytrap")
; VIRT: define {{.*}} @unsupported_cfadd_half({{.*}} #[[UNSUP_HF:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cfadd_bfloat({{.*}} #[[UNSUP_ARG:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cfadd_fp128({{.*}} #[[UNSUP_ARG]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cfadd_vector({{.*}} #[[UNSUPCC:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cceil_f32({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call fastcc float @llvm.experimental.constrained.ceil.f32(
; VIRT: define {{.*}} @unsupported_csitofp_f32({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call fastcc float @llvm.experimental.constrained.sitofp.f32.i32(
; VIRT: define {{.*}} @unsupported_cfadd_fastcc({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cfadd_musttail({{.*}} #[[UNSUP_MT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call float @llvm.experimental.constrained.fadd.f32(
; VIRT: define {{.*}} @unsupported_cfadd_bundle({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call float @llvm.experimental.constrained.fadd.f32({{.*}}[ "deopt"(i32 0) ]
; VIRT: define {{.*}} @unsupported_cfadd_poison({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cfadd_undef({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPCC]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPCC]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_MT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_ARG]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_HF]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
