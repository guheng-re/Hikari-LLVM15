; Scalar AS0 atomicrmw xchg of float/double (float VReg frame, 32/64-bit slots).
; Each width has its own reference/protected pair.  Every xchg old value and the
; final cell are compared as bit patterns independently (no XOR mix) so a wrong
; width replay or an integer-slot unpack cannot cancel out.
; f32 covers monotonic/acquire/release/acq_rel/seq_cst plus volatile
; singlethread seq_cst; f64 covers the same five orderings plus volatile
; singlethread acq_rel.  Finite values only; single-threaded, no NaN.
;
; Negative cases are parseable LLVM 15 IR that must miss the xchg float gate:
; half xchg, bfloat xchg (wrong payload), AS1 xchg, and a vector return (LLVM 15
; verifier rejects vector atomicrmw xchg, so the vector miss is the register
; gate).
;
; Pipeline:
;   O0: opt → SKIP (stderr) → host lli parity → VIRT (O0 IR) → AArch64 llc obj
;   O2: opt → host lli parity → AArch64 llc obj
; RUN: opt -S -verify-each -aesSeed=95 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.ll -o %t.o0.o
; RUN: opt -S -verify-each -aesSeed=95 -passes='default<O2>' %s -o %t.o2.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.ll -o %t.o2.o

target triple = "aarch64-unknown-linux-gnu"

@f32_cell = global float 0.000000e+00, align 4
@f64_cell = global double 0.000000e+00, align 8
@hcell = global half 0xH0000, align 2
@bfcell = global bfloat 0xR0000, align 2
@as1_cell = addrspace(1) global float 0.000000e+00, align 4

@ref_f32_obs = global [7 x i32] zeroinitializer, align 4
@prot_f32_obs = global [7 x i32] zeroinitializer, align 4
@ref_f64_obs = global [7 x i64] zeroinitializer, align 8
@prot_f64_obs = global [7 x i64] zeroinitializer, align 8

declare void @hikari_vmp()

; f32: 1 then xchg 2/3/4/5/6/7 across all five orderings plus volatile
; singlethread seq_cst.  Olds 1,2,3,4,5,6 final 7.
define void @reference_f32() {
entry:
  store float 1.000000e+00, ptr @f32_cell, align 4
  %o0 = atomicrmw xchg ptr @f32_cell, float 2.000000e+00 monotonic, align 4
  %o1 = atomicrmw xchg ptr @f32_cell, float 3.000000e+00 acquire, align 4
  %o2 = atomicrmw xchg ptr @f32_cell, float 4.000000e+00 release, align 4
  %o3 = atomicrmw xchg ptr @f32_cell, float 5.000000e+00 acq_rel, align 4
  %o4 = atomicrmw xchg ptr @f32_cell, float 6.000000e+00 seq_cst, align 4
  %o5 = atomicrmw volatile xchg ptr @f32_cell, float 7.000000e+00 syncscope("singlethread") seq_cst, align 4
  %final = load float, ptr @f32_cell, align 4
  %b0 = bitcast float %o0 to i32
  %b1 = bitcast float %o1 to i32
  %b2 = bitcast float %o2 to i32
  %b3 = bitcast float %o3 to i32
  %b4 = bitcast float %o4 to i32
  %b5 = bitcast float %o5 to i32
  %bf = bitcast float %final to i32
  %p0 = getelementptr inbounds [7 x i32], ptr @ref_f32_obs, i64 0, i64 0
  %p1 = getelementptr inbounds [7 x i32], ptr @ref_f32_obs, i64 0, i64 1
  %p2 = getelementptr inbounds [7 x i32], ptr @ref_f32_obs, i64 0, i64 2
  %p3 = getelementptr inbounds [7 x i32], ptr @ref_f32_obs, i64 0, i64 3
  %p4 = getelementptr inbounds [7 x i32], ptr @ref_f32_obs, i64 0, i64 4
  %p5 = getelementptr inbounds [7 x i32], ptr @ref_f32_obs, i64 0, i64 5
  %pf = getelementptr inbounds [7 x i32], ptr @ref_f32_obs, i64 0, i64 6
  store i32 %b0, ptr %p0, align 4
  store i32 %b1, ptr %p1, align 4
  store i32 %b2, ptr %p2, align 4
  store i32 %b3, ptr %p3, align 4
  store i32 %b4, ptr %p4, align 4
  store i32 %b5, ptr %p5, align 4
  store i32 %bf, ptr %pf, align 4
  ret void
}

define void @protected_f32() noinline optnone {
entry:
  call void @hikari_vmp()
  store float 1.000000e+00, ptr @f32_cell, align 4
  %o0 = atomicrmw xchg ptr @f32_cell, float 2.000000e+00 monotonic, align 4
  %o1 = atomicrmw xchg ptr @f32_cell, float 3.000000e+00 acquire, align 4
  %o2 = atomicrmw xchg ptr @f32_cell, float 4.000000e+00 release, align 4
  %o3 = atomicrmw xchg ptr @f32_cell, float 5.000000e+00 acq_rel, align 4
  %o4 = atomicrmw xchg ptr @f32_cell, float 6.000000e+00 seq_cst, align 4
  %o5 = atomicrmw volatile xchg ptr @f32_cell, float 7.000000e+00 syncscope("singlethread") seq_cst, align 4
  %final = load float, ptr @f32_cell, align 4
  %b0 = bitcast float %o0 to i32
  %b1 = bitcast float %o1 to i32
  %b2 = bitcast float %o2 to i32
  %b3 = bitcast float %o3 to i32
  %b4 = bitcast float %o4 to i32
  %b5 = bitcast float %o5 to i32
  %bf = bitcast float %final to i32
  %p0 = getelementptr inbounds [7 x i32], ptr @prot_f32_obs, i64 0, i64 0
  %p1 = getelementptr inbounds [7 x i32], ptr @prot_f32_obs, i64 0, i64 1
  %p2 = getelementptr inbounds [7 x i32], ptr @prot_f32_obs, i64 0, i64 2
  %p3 = getelementptr inbounds [7 x i32], ptr @prot_f32_obs, i64 0, i64 3
  %p4 = getelementptr inbounds [7 x i32], ptr @prot_f32_obs, i64 0, i64 4
  %p5 = getelementptr inbounds [7 x i32], ptr @prot_f32_obs, i64 0, i64 5
  %pf = getelementptr inbounds [7 x i32], ptr @prot_f32_obs, i64 0, i64 6
  store i32 %b0, ptr %p0, align 4
  store i32 %b1, ptr %p1, align 4
  store i32 %b2, ptr %p2, align 4
  store i32 %b3, ptr %p3, align 4
  store i32 %b4, ptr %p4, align 4
  store i32 %b5, ptr %p5, align 4
  store i32 %bf, ptr %pf, align 4
  ret void
}

; f64: 10 then xchg 20/30/40/50/60/70.  Volatile uses singlethread acq_rel.
define void @reference_f64() {
entry:
  store double 1.000000e+01, ptr @f64_cell, align 8
  %o0 = atomicrmw xchg ptr @f64_cell, double 2.000000e+01 monotonic, align 8
  %o1 = atomicrmw xchg ptr @f64_cell, double 3.000000e+01 acquire, align 8
  %o2 = atomicrmw xchg ptr @f64_cell, double 4.000000e+01 release, align 8
  %o3 = atomicrmw xchg ptr @f64_cell, double 5.000000e+01 acq_rel, align 8
  %o4 = atomicrmw xchg ptr @f64_cell, double 6.000000e+01 seq_cst, align 8
  %o5 = atomicrmw volatile xchg ptr @f64_cell, double 7.000000e+01 syncscope("singlethread") acq_rel, align 8
  %final = load double, ptr @f64_cell, align 8
  %b0 = bitcast double %o0 to i64
  %b1 = bitcast double %o1 to i64
  %b2 = bitcast double %o2 to i64
  %b3 = bitcast double %o3 to i64
  %b4 = bitcast double %o4 to i64
  %b5 = bitcast double %o5 to i64
  %bf = bitcast double %final to i64
  %p0 = getelementptr inbounds [7 x i64], ptr @ref_f64_obs, i64 0, i64 0
  %p1 = getelementptr inbounds [7 x i64], ptr @ref_f64_obs, i64 0, i64 1
  %p2 = getelementptr inbounds [7 x i64], ptr @ref_f64_obs, i64 0, i64 2
  %p3 = getelementptr inbounds [7 x i64], ptr @ref_f64_obs, i64 0, i64 3
  %p4 = getelementptr inbounds [7 x i64], ptr @ref_f64_obs, i64 0, i64 4
  %p5 = getelementptr inbounds [7 x i64], ptr @ref_f64_obs, i64 0, i64 5
  %pf = getelementptr inbounds [7 x i64], ptr @ref_f64_obs, i64 0, i64 6
  store i64 %b0, ptr %p0, align 8
  store i64 %b1, ptr %p1, align 8
  store i64 %b2, ptr %p2, align 8
  store i64 %b3, ptr %p3, align 8
  store i64 %b4, ptr %p4, align 8
  store i64 %b5, ptr %p5, align 8
  store i64 %bf, ptr %pf, align 8
  ret void
}

define void @protected_f64() noinline optnone {
entry:
  call void @hikari_vmp()
  store double 1.000000e+01, ptr @f64_cell, align 8
  %o0 = atomicrmw xchg ptr @f64_cell, double 2.000000e+01 monotonic, align 8
  %o1 = atomicrmw xchg ptr @f64_cell, double 3.000000e+01 acquire, align 8
  %o2 = atomicrmw xchg ptr @f64_cell, double 4.000000e+01 release, align 8
  %o3 = atomicrmw xchg ptr @f64_cell, double 5.000000e+01 acq_rel, align 8
  %o4 = atomicrmw xchg ptr @f64_cell, double 6.000000e+01 seq_cst, align 8
  %o5 = atomicrmw volatile xchg ptr @f64_cell, double 7.000000e+01 syncscope("singlethread") acq_rel, align 8
  %final = load double, ptr @f64_cell, align 8
  %b0 = bitcast double %o0 to i64
  %b1 = bitcast double %o1 to i64
  %b2 = bitcast double %o2 to i64
  %b3 = bitcast double %o3 to i64
  %b4 = bitcast double %o4 to i64
  %b5 = bitcast double %o5 to i64
  %bf = bitcast double %final to i64
  %p0 = getelementptr inbounds [7 x i64], ptr @prot_f64_obs, i64 0, i64 0
  %p1 = getelementptr inbounds [7 x i64], ptr @prot_f64_obs, i64 0, i64 1
  %p2 = getelementptr inbounds [7 x i64], ptr @prot_f64_obs, i64 0, i64 2
  %p3 = getelementptr inbounds [7 x i64], ptr @prot_f64_obs, i64 0, i64 3
  %p4 = getelementptr inbounds [7 x i64], ptr @prot_f64_obs, i64 0, i64 4
  %p5 = getelementptr inbounds [7 x i64], ptr @prot_f64_obs, i64 0, i64 5
  %pf = getelementptr inbounds [7 x i64], ptr @prot_f64_obs, i64 0, i64 6
  store i64 %b0, ptr %p0, align 8
  store i64 %b1, ptr %p1, align 8
  store i64 %b2, ptr %p2, align 8
  store i64 %b3, ptr %p3, align 8
  store i64 %b4, ptr %p4, align 8
  store i64 %b5, ptr %p5, align 8
  store i64 %bf, ptr %pf, align 8
  ret void
}

; half xchg is verifier-legal but outside the scalar f32/f64 xchg gate.
define void @unsupported_half_xchg() {
entry:
  call void @hikari_vmp()
  %v = atomicrmw xchg ptr @hcell, half 0xH3C00 seq_cst, align 2
  ret void
}

; bfloat xchg is a parseable wrong payload (not f32/f64).
define void @unsupported_bfloat_xchg() {
entry:
  call void @hikari_vmp()
  %v = atomicrmw xchg ptr @bfcell, bfloat 0xR3F80 seq_cst, align 2
  ret void
}

; Nonzero address space: AS1 global, supported float return, so the miss is
; the atomicrmw pointer-AS gate rather than an argument-type gate.
define float @unsupported_as1_xchg() {
entry:
  call void @hikari_vmp()
  %v = atomicrmw xchg ptr addrspace(1) @as1_cell, float 1.000000e+00 seq_cst, align 4
  ret float %v
}

; Vector atomicrmw xchg is rejected by the LLVM 15 verifier.  A 256-bit
; vector return is parseable and still misses the 1..128-bit vector gate
; (a legal <2 x float> return would now virtualize; integer lock-in is
; vmp-atomicrmw-xchg-integer-semantic.ll).
define <8 x float> @unsupported_vector_xchg() {
entry:
  call void @hikari_vmp()
  ret <8 x float> zeroinitializer
}

define i1 @eq7_i32(ptr %a, ptr %b) {
entry:
  %a0p = getelementptr inbounds [7 x i32], ptr %a, i64 0, i64 0
  %a1p = getelementptr inbounds [7 x i32], ptr %a, i64 0, i64 1
  %a2p = getelementptr inbounds [7 x i32], ptr %a, i64 0, i64 2
  %a3p = getelementptr inbounds [7 x i32], ptr %a, i64 0, i64 3
  %a4p = getelementptr inbounds [7 x i32], ptr %a, i64 0, i64 4
  %a5p = getelementptr inbounds [7 x i32], ptr %a, i64 0, i64 5
  %a6p = getelementptr inbounds [7 x i32], ptr %a, i64 0, i64 6
  %b0p = getelementptr inbounds [7 x i32], ptr %b, i64 0, i64 0
  %b1p = getelementptr inbounds [7 x i32], ptr %b, i64 0, i64 1
  %b2p = getelementptr inbounds [7 x i32], ptr %b, i64 0, i64 2
  %b3p = getelementptr inbounds [7 x i32], ptr %b, i64 0, i64 3
  %b4p = getelementptr inbounds [7 x i32], ptr %b, i64 0, i64 4
  %b5p = getelementptr inbounds [7 x i32], ptr %b, i64 0, i64 5
  %b6p = getelementptr inbounds [7 x i32], ptr %b, i64 0, i64 6
  %a0 = load i32, ptr %a0p, align 4
  %a1 = load i32, ptr %a1p, align 4
  %a2 = load i32, ptr %a2p, align 4
  %a3 = load i32, ptr %a3p, align 4
  %a4 = load i32, ptr %a4p, align 4
  %a5 = load i32, ptr %a5p, align 4
  %a6 = load i32, ptr %a6p, align 4
  %b0 = load i32, ptr %b0p, align 4
  %b1 = load i32, ptr %b1p, align 4
  %b2 = load i32, ptr %b2p, align 4
  %b3 = load i32, ptr %b3p, align 4
  %b4 = load i32, ptr %b4p, align 4
  %b5 = load i32, ptr %b5p, align 4
  %b6 = load i32, ptr %b6p, align 4
  %c0 = icmp eq i32 %a0, %b0
  %c1 = icmp eq i32 %a1, %b1
  %c2 = icmp eq i32 %a2, %b2
  %c3 = icmp eq i32 %a3, %b3
  %c4 = icmp eq i32 %a4, %b4
  %c5 = icmp eq i32 %a5, %b5
  %c6 = icmp eq i32 %a6, %b6
  %t0 = and i1 %c0, %c1
  %t1 = and i1 %c2, %c3
  %t2 = and i1 %c4, %c5
  %t3 = and i1 %t0, %t1
  %t4 = and i1 %t2, %c6
  %ok = and i1 %t3, %t4
  ret i1 %ok
}

define i1 @eq7_i64(ptr %a, ptr %b) {
entry:
  %a0p = getelementptr inbounds [7 x i64], ptr %a, i64 0, i64 0
  %a1p = getelementptr inbounds [7 x i64], ptr %a, i64 0, i64 1
  %a2p = getelementptr inbounds [7 x i64], ptr %a, i64 0, i64 2
  %a3p = getelementptr inbounds [7 x i64], ptr %a, i64 0, i64 3
  %a4p = getelementptr inbounds [7 x i64], ptr %a, i64 0, i64 4
  %a5p = getelementptr inbounds [7 x i64], ptr %a, i64 0, i64 5
  %a6p = getelementptr inbounds [7 x i64], ptr %a, i64 0, i64 6
  %b0p = getelementptr inbounds [7 x i64], ptr %b, i64 0, i64 0
  %b1p = getelementptr inbounds [7 x i64], ptr %b, i64 0, i64 1
  %b2p = getelementptr inbounds [7 x i64], ptr %b, i64 0, i64 2
  %b3p = getelementptr inbounds [7 x i64], ptr %b, i64 0, i64 3
  %b4p = getelementptr inbounds [7 x i64], ptr %b, i64 0, i64 4
  %b5p = getelementptr inbounds [7 x i64], ptr %b, i64 0, i64 5
  %b6p = getelementptr inbounds [7 x i64], ptr %b, i64 0, i64 6
  %a0 = load i64, ptr %a0p, align 8
  %a1 = load i64, ptr %a1p, align 8
  %a2 = load i64, ptr %a2p, align 8
  %a3 = load i64, ptr %a3p, align 8
  %a4 = load i64, ptr %a4p, align 8
  %a5 = load i64, ptr %a5p, align 8
  %a6 = load i64, ptr %a6p, align 8
  %b0 = load i64, ptr %b0p, align 8
  %b1 = load i64, ptr %b1p, align 8
  %b2 = load i64, ptr %b2p, align 8
  %b3 = load i64, ptr %b3p, align 8
  %b4 = load i64, ptr %b4p, align 8
  %b5 = load i64, ptr %b5p, align 8
  %b6 = load i64, ptr %b6p, align 8
  %c0 = icmp eq i64 %a0, %b0
  %c1 = icmp eq i64 %a1, %b1
  %c2 = icmp eq i64 %a2, %b2
  %c3 = icmp eq i64 %a3, %b3
  %c4 = icmp eq i64 %a4, %b4
  %c5 = icmp eq i64 %a5, %b5
  %c6 = icmp eq i64 %a6, %b6
  %t0 = and i1 %c0, %c1
  %t1 = and i1 %c2, %c3
  %t2 = and i1 %c4, %c5
  %t3 = and i1 %t0, %t1
  %t4 = and i1 %t2, %c6
  %ok = and i1 %t3, %t4
  ret i1 %ok
}

define i32 @main() {
entry:
  call void @reference_f32()
  call void @protected_f32()
  call void @reference_f64()
  call void @protected_f64()
  %m0 = call i1 @eq7_i32(ptr @ref_f32_obs, ptr @prot_f32_obs)
  %m1 = call i1 @eq7_i64(ptr @ref_f64_obs, ptr @prot_f64_obs)
  %ok = and i1 %m0, %m1
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with: 95
; SKIP-DAG: Skipping VMP on unsupported_half_xchg: unsupported atomicrmw instruction
; SKIP-DAG: Skipping VMP on unsupported_bfloat_xchg: unsupported atomicrmw instruction
; SKIP-DAG: Skipping VMP on unsupported_as1_xchg: unsupported atomicrmw instruction
; SKIP-DAG: Skipping VMP on unsupported_vector_xchg: unsupported return type
; SKIP-NOT: Skipping VMP on protected_f32:
; SKIP-NOT: Skipping VMP on protected_f64:

; VIRT-LABEL: define void @protected_f32(
; VIRT: vmp.dispatch:
; VIRT-DAG: atomicrmw xchg {{.*}} float {{.*}} monotonic
; VIRT-DAG: atomicrmw xchg {{.*}} float {{.*}} acquire
; VIRT-DAG: atomicrmw xchg {{.*}} float {{.*}} release
; VIRT-DAG: atomicrmw xchg {{.*}} float {{.*}} acq_rel
; VIRT-DAG: atomicrmw xchg {{.*}} float {{.*}} seq_cst
; VIRT-DAG: atomicrmw volatile xchg {{.*}} float {{.*}} syncscope("singlethread") seq_cst

; VIRT-LABEL: define void @protected_f64(
; VIRT: vmp.dispatch:
; VIRT-DAG: atomicrmw xchg {{.*}} double {{.*}} monotonic
; VIRT-DAG: atomicrmw xchg {{.*}} double {{.*}} acquire
; VIRT-DAG: atomicrmw xchg {{.*}} double {{.*}} release
; VIRT-DAG: atomicrmw xchg {{.*}} double {{.*}} acq_rel
; VIRT-DAG: atomicrmw xchg {{.*}} double {{.*}} seq_cst
; VIRT-DAG: atomicrmw volatile xchg {{.*}} double {{.*}} syncscope("singlethread") acq_rel

; VIRT-LABEL: define void @unsupported_half_xchg(
; VIRT-NOT: vmp.dispatch:
; VIRT: atomicrmw xchg {{.*}} half

; VIRT-LABEL: define void @unsupported_bfloat_xchg(
; VIRT-NOT: vmp.dispatch:
; VIRT: atomicrmw xchg {{.*}} bfloat

; VIRT-LABEL: define float @unsupported_as1_xchg(
; VIRT-NOT: vmp.dispatch:
; VIRT: atomicrmw xchg ptr addrspace(1)

; VIRT-LABEL: define <8 x float> @unsupported_vector_xchg(
; VIRT-NOT: vmp.dispatch:
; VIRT: ret <8 x float>

; VIRT: attributes{{.*}}"hikari.vmp.virtualized"
