; Scalar AS0 f32/f64 atomic load/store (float VReg frame, 32/64-bit slots).
; Each width has its own reference/protected pair.  Every loaded value and the
; final cell are compared as bit patterns independently (no XOR mix) so a wrong
; width replay or an integer-slot unpack cannot cancel out.
; Legal store orderings: unordered/monotonic/release/seq_cst.
; Legal load orderings: unordered/monotonic/acquire/seq_cst.
; Plus one volatile singlethread pair.  Finite values only; single-threaded.
;
; Pipeline:
;   O0: opt → SKIP (stderr) → host lli parity → VIRT (O0 IR) → AArch64 llc obj
;   O2: opt → host lli parity → AArch64 llc obj
; RUN: opt -S -verify-each -aesSeed=96 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.ll -o %t.o0.o
; RUN: opt -S -verify-each -aesSeed=96 -passes='default<O2>' %s -o %t.o2.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.ll -o %t.o2.o

target triple = "aarch64-unknown-linux-gnu"

@f32_cell = global float 0.000000e+00, align 4
@f64_cell = global double 0.000000e+00, align 8

@ref_f32_obs = global [6 x i32] zeroinitializer, align 4
@prot_f32_obs = global [6 x i32] zeroinitializer, align 4
@ref_f64_obs = global [6 x i64] zeroinitializer, align 8
@prot_f64_obs = global [6 x i64] zeroinitializer, align 8

declare void @hikari_vmp()

; f32: store then load across legal orderings, then volatile singlethread.
; Loads 2,3,4,5,6 final 6.
define void @reference_f32() {
entry:
  store float 1.000000e+00, ptr @f32_cell, align 4
  store atomic float 2.000000e+00, ptr @f32_cell unordered, align 4
  %l0 = load atomic float, ptr @f32_cell unordered, align 4
  store atomic float 3.000000e+00, ptr @f32_cell monotonic, align 4
  %l1 = load atomic float, ptr @f32_cell monotonic, align 4
  store atomic float 4.000000e+00, ptr @f32_cell release, align 4
  %l2 = load atomic float, ptr @f32_cell acquire, align 4
  store atomic float 5.000000e+00, ptr @f32_cell seq_cst, align 4
  %l3 = load atomic float, ptr @f32_cell seq_cst, align 4
  store atomic volatile float 6.000000e+00, ptr @f32_cell syncscope("singlethread") monotonic, align 4
  %l4 = load atomic volatile float, ptr @f32_cell syncscope("singlethread") acquire, align 4
  %final = load float, ptr @f32_cell, align 4
  %b0 = bitcast float %l0 to i32
  %b1 = bitcast float %l1 to i32
  %b2 = bitcast float %l2 to i32
  %b3 = bitcast float %l3 to i32
  %b4 = bitcast float %l4 to i32
  %bf = bitcast float %final to i32
  %p0 = getelementptr inbounds [6 x i32], ptr @ref_f32_obs, i64 0, i64 0
  %p1 = getelementptr inbounds [6 x i32], ptr @ref_f32_obs, i64 0, i64 1
  %p2 = getelementptr inbounds [6 x i32], ptr @ref_f32_obs, i64 0, i64 2
  %p3 = getelementptr inbounds [6 x i32], ptr @ref_f32_obs, i64 0, i64 3
  %p4 = getelementptr inbounds [6 x i32], ptr @ref_f32_obs, i64 0, i64 4
  %pf = getelementptr inbounds [6 x i32], ptr @ref_f32_obs, i64 0, i64 5
  store i32 %b0, ptr %p0, align 4
  store i32 %b1, ptr %p1, align 4
  store i32 %b2, ptr %p2, align 4
  store i32 %b3, ptr %p3, align 4
  store i32 %b4, ptr %p4, align 4
  store i32 %bf, ptr %pf, align 4
  ret void
}

define void @protected_f32() noinline optnone {
entry:
  call void @hikari_vmp()
  store float 1.000000e+00, ptr @f32_cell, align 4
  store atomic float 2.000000e+00, ptr @f32_cell unordered, align 4
  %l0 = load atomic float, ptr @f32_cell unordered, align 4
  store atomic float 3.000000e+00, ptr @f32_cell monotonic, align 4
  %l1 = load atomic float, ptr @f32_cell monotonic, align 4
  store atomic float 4.000000e+00, ptr @f32_cell release, align 4
  %l2 = load atomic float, ptr @f32_cell acquire, align 4
  store atomic float 5.000000e+00, ptr @f32_cell seq_cst, align 4
  %l3 = load atomic float, ptr @f32_cell seq_cst, align 4
  store atomic volatile float 6.000000e+00, ptr @f32_cell syncscope("singlethread") monotonic, align 4
  %l4 = load atomic volatile float, ptr @f32_cell syncscope("singlethread") acquire, align 4
  %final = load float, ptr @f32_cell, align 4
  %b0 = bitcast float %l0 to i32
  %b1 = bitcast float %l1 to i32
  %b2 = bitcast float %l2 to i32
  %b3 = bitcast float %l3 to i32
  %b4 = bitcast float %l4 to i32
  %bf = bitcast float %final to i32
  %p0 = getelementptr inbounds [6 x i32], ptr @prot_f32_obs, i64 0, i64 0
  %p1 = getelementptr inbounds [6 x i32], ptr @prot_f32_obs, i64 0, i64 1
  %p2 = getelementptr inbounds [6 x i32], ptr @prot_f32_obs, i64 0, i64 2
  %p3 = getelementptr inbounds [6 x i32], ptr @prot_f32_obs, i64 0, i64 3
  %p4 = getelementptr inbounds [6 x i32], ptr @prot_f32_obs, i64 0, i64 4
  %pf = getelementptr inbounds [6 x i32], ptr @prot_f32_obs, i64 0, i64 5
  store i32 %b0, ptr %p0, align 4
  store i32 %b1, ptr %p1, align 4
  store i32 %b2, ptr %p2, align 4
  store i32 %b3, ptr %p3, align 4
  store i32 %b4, ptr %p4, align 4
  store i32 %bf, ptr %pf, align 4
  ret void
}

; f64: same legal orderings plus volatile singlethread.  Loads 2,3,4,5,6 final 6.
define void @reference_f64() {
entry:
  store double 1.000000e+00, ptr @f64_cell, align 8
  store atomic double 2.000000e+00, ptr @f64_cell unordered, align 8
  %l0 = load atomic double, ptr @f64_cell unordered, align 8
  store atomic double 3.000000e+00, ptr @f64_cell monotonic, align 8
  %l1 = load atomic double, ptr @f64_cell monotonic, align 8
  store atomic double 4.000000e+00, ptr @f64_cell release, align 8
  %l2 = load atomic double, ptr @f64_cell acquire, align 8
  store atomic double 5.000000e+00, ptr @f64_cell seq_cst, align 8
  %l3 = load atomic double, ptr @f64_cell seq_cst, align 8
  store atomic volatile double 6.000000e+00, ptr @f64_cell syncscope("singlethread") monotonic, align 8
  %l4 = load atomic volatile double, ptr @f64_cell syncscope("singlethread") acquire, align 8
  %final = load double, ptr @f64_cell, align 8
  %b0 = bitcast double %l0 to i64
  %b1 = bitcast double %l1 to i64
  %b2 = bitcast double %l2 to i64
  %b3 = bitcast double %l3 to i64
  %b4 = bitcast double %l4 to i64
  %bf = bitcast double %final to i64
  %p0 = getelementptr inbounds [6 x i64], ptr @ref_f64_obs, i64 0, i64 0
  %p1 = getelementptr inbounds [6 x i64], ptr @ref_f64_obs, i64 0, i64 1
  %p2 = getelementptr inbounds [6 x i64], ptr @ref_f64_obs, i64 0, i64 2
  %p3 = getelementptr inbounds [6 x i64], ptr @ref_f64_obs, i64 0, i64 3
  %p4 = getelementptr inbounds [6 x i64], ptr @ref_f64_obs, i64 0, i64 4
  %pf = getelementptr inbounds [6 x i64], ptr @ref_f64_obs, i64 0, i64 5
  store i64 %b0, ptr %p0, align 8
  store i64 %b1, ptr %p1, align 8
  store i64 %b2, ptr %p2, align 8
  store i64 %b3, ptr %p3, align 8
  store i64 %b4, ptr %p4, align 8
  store i64 %bf, ptr %pf, align 8
  ret void
}

define void @protected_f64() noinline optnone {
entry:
  call void @hikari_vmp()
  store double 1.000000e+00, ptr @f64_cell, align 8
  store atomic double 2.000000e+00, ptr @f64_cell unordered, align 8
  %l0 = load atomic double, ptr @f64_cell unordered, align 8
  store atomic double 3.000000e+00, ptr @f64_cell monotonic, align 8
  %l1 = load atomic double, ptr @f64_cell monotonic, align 8
  store atomic double 4.000000e+00, ptr @f64_cell release, align 8
  %l2 = load atomic double, ptr @f64_cell acquire, align 8
  store atomic double 5.000000e+00, ptr @f64_cell seq_cst, align 8
  %l3 = load atomic double, ptr @f64_cell seq_cst, align 8
  store atomic volatile double 6.000000e+00, ptr @f64_cell syncscope("singlethread") monotonic, align 8
  %l4 = load atomic volatile double, ptr @f64_cell syncscope("singlethread") acquire, align 8
  %final = load double, ptr @f64_cell, align 8
  %b0 = bitcast double %l0 to i64
  %b1 = bitcast double %l1 to i64
  %b2 = bitcast double %l2 to i64
  %b3 = bitcast double %l3 to i64
  %b4 = bitcast double %l4 to i64
  %bf = bitcast double %final to i64
  %p0 = getelementptr inbounds [6 x i64], ptr @prot_f64_obs, i64 0, i64 0
  %p1 = getelementptr inbounds [6 x i64], ptr @prot_f64_obs, i64 0, i64 1
  %p2 = getelementptr inbounds [6 x i64], ptr @prot_f64_obs, i64 0, i64 2
  %p3 = getelementptr inbounds [6 x i64], ptr @prot_f64_obs, i64 0, i64 3
  %p4 = getelementptr inbounds [6 x i64], ptr @prot_f64_obs, i64 0, i64 4
  %pf = getelementptr inbounds [6 x i64], ptr @prot_f64_obs, i64 0, i64 5
  store i64 %b0, ptr %p0, align 8
  store i64 %b1, ptr %p1, align 8
  store i64 %b2, ptr %p2, align 8
  store i64 %b3, ptr %p3, align 8
  store i64 %b4, ptr %p4, align 8
  store i64 %bf, ptr %pf, align 8
  ret void
}

define i1 @eq6_i32(ptr %a, ptr %b) {
entry:
  %a0p = getelementptr inbounds [6 x i32], ptr %a, i64 0, i64 0
  %a1p = getelementptr inbounds [6 x i32], ptr %a, i64 0, i64 1
  %a2p = getelementptr inbounds [6 x i32], ptr %a, i64 0, i64 2
  %a3p = getelementptr inbounds [6 x i32], ptr %a, i64 0, i64 3
  %a4p = getelementptr inbounds [6 x i32], ptr %a, i64 0, i64 4
  %a5p = getelementptr inbounds [6 x i32], ptr %a, i64 0, i64 5
  %b0p = getelementptr inbounds [6 x i32], ptr %b, i64 0, i64 0
  %b1p = getelementptr inbounds [6 x i32], ptr %b, i64 0, i64 1
  %b2p = getelementptr inbounds [6 x i32], ptr %b, i64 0, i64 2
  %b3p = getelementptr inbounds [6 x i32], ptr %b, i64 0, i64 3
  %b4p = getelementptr inbounds [6 x i32], ptr %b, i64 0, i64 4
  %b5p = getelementptr inbounds [6 x i32], ptr %b, i64 0, i64 5
  %a0 = load i32, ptr %a0p, align 4
  %a1 = load i32, ptr %a1p, align 4
  %a2 = load i32, ptr %a2p, align 4
  %a3 = load i32, ptr %a3p, align 4
  %a4 = load i32, ptr %a4p, align 4
  %a5 = load i32, ptr %a5p, align 4
  %b0 = load i32, ptr %b0p, align 4
  %b1 = load i32, ptr %b1p, align 4
  %b2 = load i32, ptr %b2p, align 4
  %b3 = load i32, ptr %b3p, align 4
  %b4 = load i32, ptr %b4p, align 4
  %b5 = load i32, ptr %b5p, align 4
  %c0 = icmp eq i32 %a0, %b0
  %c1 = icmp eq i32 %a1, %b1
  %c2 = icmp eq i32 %a2, %b2
  %c3 = icmp eq i32 %a3, %b3
  %c4 = icmp eq i32 %a4, %b4
  %c5 = icmp eq i32 %a5, %b5
  %t0 = and i1 %c0, %c1
  %t1 = and i1 %c2, %c3
  %t2 = and i1 %c4, %c5
  %t3 = and i1 %t0, %t1
  %ok = and i1 %t3, %t2
  ret i1 %ok
}

define i1 @eq6_i64(ptr %a, ptr %b) {
entry:
  %a0p = getelementptr inbounds [6 x i64], ptr %a, i64 0, i64 0
  %a1p = getelementptr inbounds [6 x i64], ptr %a, i64 0, i64 1
  %a2p = getelementptr inbounds [6 x i64], ptr %a, i64 0, i64 2
  %a3p = getelementptr inbounds [6 x i64], ptr %a, i64 0, i64 3
  %a4p = getelementptr inbounds [6 x i64], ptr %a, i64 0, i64 4
  %a5p = getelementptr inbounds [6 x i64], ptr %a, i64 0, i64 5
  %b0p = getelementptr inbounds [6 x i64], ptr %b, i64 0, i64 0
  %b1p = getelementptr inbounds [6 x i64], ptr %b, i64 0, i64 1
  %b2p = getelementptr inbounds [6 x i64], ptr %b, i64 0, i64 2
  %b3p = getelementptr inbounds [6 x i64], ptr %b, i64 0, i64 3
  %b4p = getelementptr inbounds [6 x i64], ptr %b, i64 0, i64 4
  %b5p = getelementptr inbounds [6 x i64], ptr %b, i64 0, i64 5
  %a0 = load i64, ptr %a0p, align 8
  %a1 = load i64, ptr %a1p, align 8
  %a2 = load i64, ptr %a2p, align 8
  %a3 = load i64, ptr %a3p, align 8
  %a4 = load i64, ptr %a4p, align 8
  %a5 = load i64, ptr %a5p, align 8
  %b0 = load i64, ptr %b0p, align 8
  %b1 = load i64, ptr %b1p, align 8
  %b2 = load i64, ptr %b2p, align 8
  %b3 = load i64, ptr %b3p, align 8
  %b4 = load i64, ptr %b4p, align 8
  %b5 = load i64, ptr %b5p, align 8
  %c0 = icmp eq i64 %a0, %b0
  %c1 = icmp eq i64 %a1, %b1
  %c2 = icmp eq i64 %a2, %b2
  %c3 = icmp eq i64 %a3, %b3
  %c4 = icmp eq i64 %a4, %b4
  %c5 = icmp eq i64 %a5, %b5
  %t0 = and i1 %c0, %c1
  %t1 = and i1 %c2, %c3
  %t2 = and i1 %c4, %c5
  %t3 = and i1 %t0, %t1
  %ok = and i1 %t3, %t2
  ret i1 %ok
}

define i32 @main() {
entry:
  call void @reference_f32()
  call void @protected_f32()
  call void @reference_f64()
  call void @protected_f64()
  %m0 = call i1 @eq6_i32(ptr @ref_f32_obs, ptr @prot_f32_obs)
  %m1 = call i1 @eq6_i64(ptr @ref_f64_obs, ptr @prot_f64_obs)
  %ok = and i1 %m0, %m1
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with: 96
; SKIP-NOT: Skipping VMP on protected_f32:
; SKIP-NOT: Skipping VMP on protected_f64:

; VIRT-LABEL: define void @protected_f32(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: %vmp.f.bits32{{.*}} = bitcast float
; VIRT-DAG: %vmp.f.val{{.*}} = bitcast i32
; VIRT-DAG: store atomic float {{.*}} unordered
; VIRT-DAG: load atomic float, {{.*}} unordered
; VIRT-DAG: store atomic float {{.*}} monotonic
; VIRT-DAG: load atomic float, {{.*}} monotonic
; VIRT-DAG: store atomic float {{.*}} release
; VIRT-DAG: load atomic float, {{.*}} acquire
; VIRT-DAG: store atomic float {{.*}} seq_cst
; VIRT-DAG: load atomic float, {{.*}} seq_cst
; VIRT-DAG: store atomic volatile float {{.*}} syncscope("singlethread") monotonic
; VIRT-DAG: load atomic volatile float, {{.*}} syncscope("singlethread") acquire

; VIRT-LABEL: define void @protected_f64(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: %vmp.d.bits64{{.*}} = bitcast double
; VIRT-DAG: %vmp.d.val{{.*}} = bitcast i64
; VIRT-DAG: store atomic double {{.*}} unordered
; VIRT-DAG: load atomic double, {{.*}} unordered
; VIRT-DAG: store atomic double {{.*}} monotonic
; VIRT-DAG: load atomic double, {{.*}} monotonic
; VIRT-DAG: store atomic double {{.*}} release
; VIRT-DAG: load atomic double, {{.*}} acquire
; VIRT-DAG: store atomic double {{.*}} seq_cst
; VIRT-DAG: load atomic double, {{.*}} seq_cst
; VIRT-DAG: store atomic volatile double {{.*}} syncscope("singlethread") monotonic
; VIRT-DAG: load atomic volatile double, {{.*}} syncscope("singlethread") acquire
; Bound NOT to next define so f64 must not use f32 slot helpers.
; VIRT-NOT: %vmp.f.bits32
; VIRT-LABEL: define i1 @eq6_i32(

; VIRT: attributes{{.*}}"hikari.vmp.virtualized"
