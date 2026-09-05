; Strict AArch64 VMP indirect CallInst subset for same-type scalar FP:
; f32(f32), f32(f32,f32), f64(f64), f64(f64,f64) via AS0 ptr, CallingConv::C,
; non-vararg.  FastMathFlags on FP-returning calls are restored from the
; CallDescriptor mask by emitCallHandler.  Function-pointer argument and
; select-of-globals callees.  Re-emitted as CreateCall(FunctionType*, Value*,
; Args) with callee from a pointer VReg and scalar args/results from the
; float VReg frame.  Independent bit-pattern compares (no XOR mix).
; Ternary / mixed f32/f64 / bfloat / wide vector / non-zero AS / constrained
; stay rejected.  Scalar IEEE half args/returns live on the mixed-scalar
; subset (vmp-indirect-call-half-semantic.ll).  Supported fixed-vector
; args/returns live in vmp-indirect-call-vector-semantic.ll; this file
; keeps function-level bfloat and >128-bit vector rejects.
;
; RUN: opt -S -verify-each -aesSeed=42 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.ll -o %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: opt -S -verify-each -aesSeed=42 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.ll -o %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare float @llvm.experimental.constrained.fadd.f32(float, float, metadata, metadata)

; f32(f32) helpers: fneg vs add-one (distinct finite results).
define float @fneg_f32(float %x) noinline {
entry:
  %r = fneg float %x
  ret float %r
}

define float @add1_f32(float %x) noinline {
entry:
  %r = fadd float %x, 1.000000e+00
  ret float %r
}

; f32(f32,f32) helpers: fadd vs fsub (fsub is not commutative).
define float @fadd_f32(float %a, float %b) noinline {
entry:
  %r = fadd float %a, %b
  ret float %r
}

define float @fsub_f32(float %a, float %b) noinline {
entry:
  %r = fsub float %a, %b
  ret float %r
}

; f64(f64) helpers.
define double @fneg_f64(double %x) noinline {
entry:
  %r = fneg double %x
  ret double %r
}

define double @add1_f64(double %x) noinline {
entry:
  %r = fadd double %x, 1.000000e+00
  ret double %r
}

; f64(f64,f64) helpers.
define double @fadd_f64(double %a, double %b) noinline {
entry:
  %r = fadd double %a, %b
  ret double %r
}

define double @fsub_f64(double %a, double %b) noinline {
entry:
  %r = fsub double %a, %b
  ret double %r
}

; Reference / protected: f32(f32) via ptr argument.
define float @reference_via_arg_f32(ptr %fp, float %x) {
entry:
  %r = call float %fp(float %x)
  ret float %r
}

define float @protected_via_arg_f32(ptr %fp, float %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float %fp(float %x)
  ret float %r
}

; Reference / protected: f32(f32) via select of globals.
define float @reference_via_select_f32(i1 %pick, float %x) {
entry:
  %fp = select i1 %pick, ptr @fneg_f32, ptr @add1_f32
  %r = call float %fp(float %x)
  ret float %r
}

define float @protected_via_select_f32(i1 %pick, float %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %fp = select i1 %pick, ptr @fneg_f32, ptr @add1_f32
  %r = call float %fp(float %x)
  ret float %r
}

; Reference / protected: f32(f32,f32) via ptr argument.
define float @reference_binary_via_arg_f32(ptr %fp, float %a, float %b) {
entry:
  %r = call float %fp(float %a, float %b)
  ret float %r
}

define float @protected_binary_via_arg_f32(ptr %fp, float %a, float %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float %fp(float %a, float %b)
  ret float %r
}

; Reference / protected: f32(f32,f32) via select of globals.
define float @reference_binary_via_select_f32(i1 %pick, float %a, float %b) {
entry:
  %fp = select i1 %pick, ptr @fadd_f32, ptr @fsub_f32
  %r = call float %fp(float %a, float %b)
  ret float %r
}

define float @protected_binary_via_select_f32(i1 %pick, float %a, float %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %fp = select i1 %pick, ptr @fadd_f32, ptr @fsub_f32
  %r = call float %fp(float %a, float %b)
  ret float %r
}

; Reference / protected: f64(f64) via ptr argument.
define double @reference_via_arg_f64(ptr %fp, double %x) {
entry:
  %r = call double %fp(double %x)
  ret double %r
}

define double @protected_via_arg_f64(ptr %fp, double %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call double %fp(double %x)
  ret double %r
}

; Reference / protected: f64(f64) via select of globals.
define double @reference_via_select_f64(i1 %pick, double %x) {
entry:
  %fp = select i1 %pick, ptr @fneg_f64, ptr @add1_f64
  %r = call double %fp(double %x)
  ret double %r
}

define double @protected_via_select_f64(i1 %pick, double %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %fp = select i1 %pick, ptr @fneg_f64, ptr @add1_f64
  %r = call double %fp(double %x)
  ret double %r
}

; Reference / protected: f64(f64,f64) via ptr argument.
define double @reference_binary_via_arg_f64(ptr %fp, double %a, double %b) {
entry:
  %r = call double %fp(double %a, double %b)
  ret double %r
}

define double @protected_binary_via_arg_f64(ptr %fp, double %a, double %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call double %fp(double %a, double %b)
  ret double %r
}

; Reference / protected: f64(f64,f64) via select of globals.
define double @reference_binary_via_select_f64(i1 %pick, double %a, double %b) {
entry:
  %fp = select i1 %pick, ptr @fadd_f64, ptr @fsub_f64
  %r = call double %fp(double %a, double %b)
  ret double %r
}

define double @protected_binary_via_select_f64(i1 %pick, double %a, double %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %fp = select i1 %pick, ptr @fadd_f64, ptr @fsub_f64
  %r = call double %fp(double %a, double %b)
  ret double %r
}

; FastMathFlags on eligible indirect f32(f32) calls are VMP-supported
; (CallDescriptor FMF mask restored by emitCallHandler).
define float @reference_fast_via_arg_f32(ptr %fp, float %x) {
entry:
  %r = call fast float %fp(float %x)
  ret float %r
}

define float @protected_fast_via_arg_f32(ptr %fp, float %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fast float %fp(float %x)
  ret float %r
}

; Partial flags (nnan ninf) on eligible indirect f64(f64,f64) calls.
define double @reference_nnan_via_arg_f64(ptr %fp, double %a, double %b) {
entry:
  %r = call nnan ninf double %fp(double %a, double %b)
  ret double %r
}

define double @protected_nnan_via_arg_f64(ptr %fp, double %a, double %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call nnan ninf double %fp(double %a, double %b)
  ret double %r
}

; Safety skip: mixed f32/f64 — not same-type.
define float @unsupported_mixed_f32_f64(ptr %fp, double %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float %fp(double %x)
  ret float %r
}

; Safety skip: mixed binary f64(f32, f32).
define double @unsupported_mixed_f64_f32_bin(ptr %fp, float %a, float %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call double %fp(float %a, float %b)
  ret double %r
}

; Safety skip: ternary f32 — unary/binary only.
define float @unsupported_ternary_f32(ptr %fp, float %a, float %b, float %c) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float %fp(float %a, float %b, float %c)
  ret float %r
}

; Safety skip: ternary f64.
define double @unsupported_ternary_f64(ptr %fp, double %a, double %b, double %c) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call double %fp(double %a, double %b, double %c)
  ret double %r
}

; Safety skip: bfloat — not IEEE scalar half/f32/f64.
define bfloat @unsupported_bfloat(ptr %fp, bfloat %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call bfloat %fp(bfloat %x)
  ret bfloat %r
}

; Safety skip: >128-bit vector — not a supported fixed vector.
define <8 x float> @unsupported_vector(ptr %fp, <8 x float> %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x float> %fp(<8 x float> %x)
  ret <8 x float> %r
}

; Safety skip: non-zero address-space callee pointer.
define float @unsupported_as1(ptr addrspace(1) %fp, float %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call addrspace(1) float %fp(float %x)
  ret float %r
}

; Safety skip: constrained FP builtin (direct intrinsic, extra metadata args).
define float @unsupported_constrained_fadd(float %a, float %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc float @llvm.experimental.constrained.fadd.f32(float %a, float %b, metadata !"round.tonearest", metadata !"fpexcept.strict")
  ret float %r
}

define i32 @main() {
entry:
  ; f32(f32) via arg: fneg and add1, finite non-NaN
  %e0 = call float @reference_via_arg_f32(ptr @fneg_f32, float 1.500000e+00)
  %a0 = call float @protected_via_arg_f32(ptr @fneg_f32, float 1.500000e+00)
  %be0 = bitcast float %e0 to i32
  %ba0 = bitcast float %a0 to i32
  %m0 = icmp eq i32 %be0, %ba0
  %e1 = call float @reference_via_arg_f32(ptr @add1_f32, float -2.250000e+00)
  %a1 = call float @protected_via_arg_f32(ptr @add1_f32, float -2.250000e+00)
  %be1 = bitcast float %e1 to i32
  %ba1 = bitcast float %a1 to i32
  %m1 = icmp eq i32 %be1, %ba1
  ; f32(f32) via select
  %e2 = call float @reference_via_select_f32(i1 true, float 3.000000e+00)
  %a2 = call float @protected_via_select_f32(i1 true, float 3.000000e+00)
  %be2 = bitcast float %e2 to i32
  %ba2 = bitcast float %a2 to i32
  %m2 = icmp eq i32 %be2, %ba2
  %e3 = call float @reference_via_select_f32(i1 false, float -4.000000e+00)
  %a3 = call float @protected_via_select_f32(i1 false, float -4.000000e+00)
  %be3 = bitcast float %e3 to i32
  %ba3 = bitcast float %a3 to i32
  %m3 = icmp eq i32 %be3, %ba3
  ; f32(f32,f32) via arg: fadd and non-commutative fsub
  %e4 = call float @reference_binary_via_arg_f32(ptr @fadd_f32, float 3.000000e+00, float 1.250000e+00)
  %a4 = call float @protected_binary_via_arg_f32(ptr @fadd_f32, float 3.000000e+00, float 1.250000e+00)
  %be4 = bitcast float %e4 to i32
  %ba4 = bitcast float %a4 to i32
  %m4 = icmp eq i32 %be4, %ba4
  %e5 = call float @reference_binary_via_arg_f32(ptr @fsub_f32, float -5.000000e+00, float 2.000000e+00)
  %a5 = call float @protected_binary_via_arg_f32(ptr @fsub_f32, float -5.000000e+00, float 2.000000e+00)
  %be5 = bitcast float %e5 to i32
  %ba5 = bitcast float %a5 to i32
  %m5 = icmp eq i32 %be5, %ba5
  ; f32(f32,f32) via select
  %e6 = call float @reference_binary_via_select_f32(i1 true, float 2.500000e+00, float 5.000000e-01)
  %a6 = call float @protected_binary_via_select_f32(i1 true, float 2.500000e+00, float 5.000000e-01)
  %be6 = bitcast float %e6 to i32
  %ba6 = bitcast float %a6 to i32
  %m6 = icmp eq i32 %be6, %ba6
  %e7 = call float @reference_binary_via_select_f32(i1 false, float 6.000000e+00, float 1.500000e+00)
  %a7 = call float @protected_binary_via_select_f32(i1 false, float 6.000000e+00, float 1.500000e+00)
  %be7 = bitcast float %e7 to i32
  %ba7 = bitcast float %a7 to i32
  %m7 = icmp eq i32 %be7, %ba7
  ; f64(f64) via arg
  %e8 = call double @reference_via_arg_f64(ptr @fneg_f64, double 1.500000e+00)
  %a8 = call double @protected_via_arg_f64(ptr @fneg_f64, double 1.500000e+00)
  %be8 = bitcast double %e8 to i64
  %ba8 = bitcast double %a8 to i64
  %m8 = icmp eq i64 %be8, %ba8
  %e9 = call double @reference_via_arg_f64(ptr @add1_f64, double -2.250000e+00)
  %a9 = call double @protected_via_arg_f64(ptr @add1_f64, double -2.250000e+00)
  %be9 = bitcast double %e9 to i64
  %ba9 = bitcast double %a9 to i64
  %m9 = icmp eq i64 %be9, %ba9
  ; f64(f64) via select
  %e10 = call double @reference_via_select_f64(i1 true, double 3.000000e+00)
  %a10 = call double @protected_via_select_f64(i1 true, double 3.000000e+00)
  %be10 = bitcast double %e10 to i64
  %ba10 = bitcast double %a10 to i64
  %m10 = icmp eq i64 %be10, %ba10
  %e11 = call double @reference_via_select_f64(i1 false, double -4.000000e+00)
  %a11 = call double @protected_via_select_f64(i1 false, double -4.000000e+00)
  %be11 = bitcast double %e11 to i64
  %ba11 = bitcast double %a11 to i64
  %m11 = icmp eq i64 %be11, %ba11
  ; f64(f64,f64) via arg
  %e12 = call double @reference_binary_via_arg_f64(ptr @fadd_f64, double 3.000000e+00, double 1.250000e+00)
  %a12 = call double @protected_binary_via_arg_f64(ptr @fadd_f64, double 3.000000e+00, double 1.250000e+00)
  %be12 = bitcast double %e12 to i64
  %ba12 = bitcast double %a12 to i64
  %m12 = icmp eq i64 %be12, %ba12
  %e13 = call double @reference_binary_via_arg_f64(ptr @fsub_f64, double -5.000000e+00, double 2.000000e+00)
  %a13 = call double @protected_binary_via_arg_f64(ptr @fsub_f64, double -5.000000e+00, double 2.000000e+00)
  %be13 = bitcast double %e13 to i64
  %ba13 = bitcast double %a13 to i64
  %m13 = icmp eq i64 %be13, %ba13
  ; f64(f64,f64) via select
  %e14 = call double @reference_binary_via_select_f64(i1 true, double 2.500000e+00, double 5.000000e-01)
  %a14 = call double @protected_binary_via_select_f64(i1 true, double 2.500000e+00, double 5.000000e-01)
  %be14 = bitcast double %e14 to i64
  %ba14 = bitcast double %a14 to i64
  %m14 = icmp eq i64 %be14, %ba14
  %e15 = call double @reference_binary_via_select_f64(i1 false, double 6.000000e+00, double 1.500000e+00)
  %a15 = call double @protected_binary_via_select_f64(i1 false, double 6.000000e+00, double 1.500000e+00)
  %be15 = bitcast double %e15 to i64
  %ba15 = bitcast double %a15 to i64
  %m15 = icmp eq i64 %be15, %ba15
  ; FMF indirect calls: fast f32(f32) and nnan ninf f64(f64,f64)
  %e16 = call float @reference_fast_via_arg_f32(ptr @fneg_f32, float 1.500000e+00)
  %a16 = call float @protected_fast_via_arg_f32(ptr @fneg_f32, float 1.500000e+00)
  %be16 = bitcast float %e16 to i32
  %ba16 = bitcast float %a16 to i32
  %m16 = icmp eq i32 %be16, %ba16
  %e17 = call double @reference_nnan_via_arg_f64(ptr @fadd_f64, double 7.000000e+00, double 2.000000e+00)
  %a17 = call double @protected_nnan_via_arg_f64(ptr @fadd_f64, double 7.000000e+00, double 2.000000e+00)
  %be17 = bitcast double %e17 to i64
  %ba17 = bitcast double %a17 to i64
  %m17 = icmp eq i64 %be17, %ba17
  %t0 = and i1 %m0, %m1
  %t1 = and i1 %m2, %m3
  %t2 = and i1 %m4, %m5
  %t3 = and i1 %m6, %m7
  %t4 = and i1 %m8, %m9
  %t5 = and i1 %m10, %m11
  %t6 = and i1 %m12, %m13
  %t7 = and i1 %m14, %m15
  %t8 = and i1 %t0, %t1
  %t9 = and i1 %t2, %t3
  %t10 = and i1 %t4, %t5
  %t11 = and i1 %t6, %t7
  %t12 = and i1 %t8, %t9
  %ok = and i1 %t10, %t11
  %t13 = and i1 %t12, %ok
  %t14 = and i1 %m16, %m17
  %ok2 = and i1 %t13, %t14
  %code = select i1 %ok2, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with: 42
; SKIP-DAG: Skipping VMP on unsupported_bfloat: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_vector: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_as1: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_constrained_fadd: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_via_arg_f32:
; SKIP-NOT: Skipping VMP on protected_via_select_f32:
; SKIP-NOT: Skipping VMP on protected_binary_via_arg_f32:
; SKIP-NOT: Skipping VMP on protected_binary_via_select_f32:
; SKIP-NOT: Skipping VMP on protected_via_arg_f64:
; SKIP-NOT: Skipping VMP on protected_via_select_f64:
; SKIP-NOT: Skipping VMP on protected_binary_via_arg_f64:
; SKIP-NOT: Skipping VMP on protected_binary_via_select_f64:
; SKIP-NOT: Skipping VMP on protected_fast_via_arg_f32:
; SKIP-NOT: Skipping VMP on protected_nnan_via_arg_f64:

; VIRT: define float @protected_via_arg_f32({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call float %{{.+}}(float
; VIRT: define float @protected_via_select_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call float %{{.+}}(float
; VIRT: define float @protected_binary_via_arg_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call float %{{.+}}(float {{.*}}, float
; VIRT: define float @protected_binary_via_select_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call float %{{.+}}(float {{.*}}, float
; VIRT: define double @protected_via_arg_f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call double %{{.+}}(double
; VIRT: define double @protected_via_select_f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call double %{{.+}}(double
; VIRT: define double @protected_binary_via_arg_f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call double %{{.+}}(double {{.*}}, double
; VIRT: define double @protected_binary_via_select_f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call double %{{.+}}(double {{.*}}, double
; VIRT: define float @protected_fast_via_arg_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call fast float %{{.+}}(float
; VIRT: define double @protected_nnan_via_arg_f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call nnan ninf double %{{.+}}(double
; VIRT: define bfloat @unsupported_bfloat(
; VIRT-NOT: vmp.dispatch
; VIRT: call bfloat %{{.+}}(bfloat
; VIRT: define <8 x float> @unsupported_vector(
; VIRT-NOT: vmp.dispatch
; VIRT: call <8 x float> %{{.+}}(<8 x float>
; VIRT: define float @unsupported_as1(
; VIRT-NOT: vmp.dispatch
; VIRT: call addrspace(1) float %{{.+}}(float
; VIRT: define float @unsupported_constrained_fadd(
; VIRT-NOT: vmp.dispatch
; VIRT: call fastcc float @llvm.experimental.constrained.fadd.f32(
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
