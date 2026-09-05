; Scalar llvm.arithmetic.fence.f32/f64 re-emitted through the normal Call
; path — never lowered to a Move and never deleted: the fence blocks
; fast-math reassociation across the point, and SelectionDAG lowers it to
; TargetOpcode::ARITH_FENCE (an asm comment in verbose output).  Inputs go
; through a float computation, cross the fence, then join a later
; fast-math expression; the fast flags travel on the CallDescriptor and are
; restored by the call handler.  reference/* run natively, protected/* are
; virtualized; main compares results over multiple f32/f64 inputs.  The
; vector form (llvm.arithmetic.fence.v4f32) stays rejected: the vector
; argument is not a supported VMP register type, so the function-level gate
; skips the whole function with the stable "unsupported argument type"
; diagnostic, keeping the native call and no VMP dispatcher.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.ll -o %t.o0.o
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o0.ll -o - | FileCheck %s --check-prefix=ASM
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP-O2 < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT-O2 < %t.o2.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.ll -o %t.o2.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; Second fixed aesSeed: the checks above bind no register number, opcode or
; handler order, so the replay structure must be identical under a different
; seed (llc/lli on the seed-97 IR already prove the transform is valid and
; executes; the second seed re-checks the structure only).
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP-O2 < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT-O2 < %t.o2.s7.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare float @llvm.arithmetic.fence.f32(float)
declare double @llvm.arithmetic.fence.f64(double)
declare <4 x float> @llvm.arithmetic.fence.v4f32(<4 x float>)

; ---- reference: native f32 fence ----

define float @reference_f32(float %x) {
entry:
  %m = fmul float %x, 3.0
  %f = call fast float @llvm.arithmetic.fence.f32(float %m)
  %a = fadd fast float %f, 1.0
  ret float %a
}

; ---- protected: same f32 fence under VMP ----

define float @protected_f32(float %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %m = fmul float %x, 3.0
  %f = call fast float @llvm.arithmetic.fence.f32(float %m)
  %a = fadd fast float %f, 1.0
  ret float %a
}

; ---- reference: native f64 fence ----

define double @reference_f64(double %x) {
entry:
  %m = fmul double %x, 3.0
  %f = call fast double @llvm.arithmetic.fence.f64(double %m)
  %a = fadd fast double %f, 1.0
  ret double %a
}

; ---- protected: same f64 fence under VMP ----

define double @protected_f64(double %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %m = fmul double %x, 3.0
  %f = call fast double @llvm.arithmetic.fence.f64(double %m)
  %a = fadd fast double %f, 1.0
  ret double %a
}

; ---- negative case: must SKIP, never virtualize ----

; The vector form stays rejected by the scalar whitelist; the vector
; argument is not a supported VMP register type, so the function-level gate
; rejects the whole function with the stable "unsupported argument type"
; reason before any call is examined.  The vector fence is never executed.
define i32 @unsupported_vector_fence(<4 x float> %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %f = call <4 x float> @llvm.arithmetic.fence.v4f32(<4 x float> %x)
  %v = extractelement <4 x float> %f, i32 0
  %c = fptosi float %v to i32
  ret i32 %c
}

; ---- main: parity checks ----

define i32 @main() {
entry:
  %e0 = call float @reference_f32(float 1.5)
  %a0 = call float @protected_f32(float 1.5)
  %e1 = call float @reference_f32(float 2.25)
  %a1 = call float @protected_f32(float 2.25)
  %e2 = call float @reference_f32(float -0.5)
  %a2 = call float @protected_f32(float -0.5)
  %e3 = call double @reference_f64(double 1.5)
  %a3 = call double @protected_f64(double 1.5)
  %e4 = call double @reference_f64(double 2.25)
  %a4 = call double @protected_f64(double 2.25)
  %e5 = call double @reference_f64(double -0.5)
  %a5 = call double @protected_f64(double -0.5)
  %m0 = fcmp oeq float %e0, %a0
  %m1 = fcmp oeq float %e1, %a1
  %m2 = fcmp oeq float %e2, %a2
  %m3 = fcmp oeq double %e3, %a3
  %m4 = fcmp oeq double %e4, %a4
  %m5 = fcmp oeq double %e5, %a5
  %t0 = and i1 %m0, %m1
  %t1 = and i1 %t0, %m2
  %t2 = and i1 %t1, %m3
  %t3 = and i1 %t2, %m4
  %ok = and i1 %t3, %m5
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; ---- O0 checks ----

; SKIP-DAG: Skipping VMP on unsupported_vector_fence: unsupported argument type
; SKIP-NOT: Skipping VMP on protected_f32:
; SKIP-NOT: Skipping VMP on protected_f64:

; VIRT-LABEL: define float @protected_f32(
; VIRT: %vmp.regs = alloca
; VIRT: vmp.dispatch:
; The f32 fence is re-emitted inside the interpreter with its fast-math
; flags restored on the call.
; VIRT-DAG: call fast float @llvm.arithmetic.fence.f32(float {{.*}})

; VIRT-LABEL: define double @protected_f64(
; VIRT: %vmp.regs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: call fast double @llvm.arithmetic.fence.f64(double {{.*}})

; Negative case stays native: no dispatch, no virtualized attribute.
; VIRT-LABEL: define i32 @unsupported_vector_fence(
; VIRT-NOT: vmp.dispatch
; VIRT: call <4 x float> @llvm.arithmetic.fence.v4f32(<4 x float> %x)

; VIRT: attributes{{.*}}"hikari.vmp.virtualized"{{.*}}

; ---- O2 checks ----

; SKIP-O2-DAG: Skipping VMP on unsupported_vector_fence: unsupported argument type
; SKIP-O2-NOT: Skipping VMP on protected_f32:
; SKIP-O2-NOT: Skipping VMP on protected_f64:

; The protected functions are optnone, so the virtualized structure is
; identical at O2; the O2 checks stay virtualization/verification-safe.
; VIRT-O2-LABEL: define float @protected_f32(
; VIRT-O2: %vmp.regs = alloca
; VIRT-O2: vmp.dispatch:
; VIRT-O2-DAG: call fast float @llvm.arithmetic.fence.f32(float {{.*}})

; VIRT-O2-LABEL: define double @protected_f64(
; VIRT-O2: %vmp.regs = alloca
; VIRT-O2: vmp.dispatch:
; VIRT-O2-DAG: call fast double @llvm.arithmetic.fence.f64(double {{.*}})

; Negative case stays native at O2 as well.
; VIRT-O2-LABEL: define i32 @unsupported_vector_fence(
; VIRT-O2-NOT: vmp.dispatch
; VIRT-O2: call <4 x float> @llvm.arithmetic.fence.v4f32(<4 x float> %x)
; VIRT-O2: attributes{{.*}}"hikari.vmp.virtualized"{{.*}}

; ---- asm check ----

; The fence survives to the object stream as the ARITH_FENCE pseudo-op
; comment (only in verbose asm output).
; ASM: ARITH_FENCE
