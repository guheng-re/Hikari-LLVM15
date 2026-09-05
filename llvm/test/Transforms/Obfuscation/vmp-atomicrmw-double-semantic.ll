; Scalar AS0 double atomicrmw fadd/fsub/fmax/fmin (float VReg frame, 64-bit slots).
; Each op has its own reference/protected pair.  Every old value and the final
; cell are compared as i64 bit patterns independently (no XOR mix) so a wrong
; op or an f32-width replay cannot cancel out.
; fadd covers monotonic/acquire/release/acq_rel/seq_cst plus volatile
; singlethread; fsub/fmax/fmin cover the remaining legal volatile/syncscope
; combinations without mixing results across ops.
;
; Pipeline:
;   O0: opt → SKIP (stderr) → host lli parity → VIRT (O0 IR) → AArch64 llc obj
;   O2: opt → host lli parity → AArch64 llc obj
; RUN: opt -S -verify-each -aesSeed=94 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.ll -o %t.o0.o
; RUN: opt -S -verify-each -aesSeed=94 -passes='default<O2>' %s -o %t.o2.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.ll -o %t.o2.o

target triple = "aarch64-unknown-linux-gnu"

@fadd_cell = global double 0.000000e+00, align 8
@fsub_cell = global double 0.000000e+00, align 8
@fmax_cell = global double 0.000000e+00, align 8
@fmin_cell = global double 0.000000e+00, align 8

@ref_fadd_obs = global [7 x i64] zeroinitializer, align 8
@prot_fadd_obs = global [7 x i64] zeroinitializer, align 8
@ref_fsub_obs = global [3 x i64] zeroinitializer, align 8
@prot_fsub_obs = global [3 x i64] zeroinitializer, align 8
@ref_fmax_obs = global [3 x i64] zeroinitializer, align 8
@prot_fmax_obs = global [3 x i64] zeroinitializer, align 8
@ref_fmin_obs = global [3 x i64] zeroinitializer, align 8
@prot_fmin_obs = global [3 x i64] zeroinitializer, align 8

declare void @hikari_vmp()

; fadd: 1+2+3+4+5+6+7 across all five orderings plus volatile singlethread.
define void @reference_fadd() {
entry:
  store double 1.000000e+00, ptr @fadd_cell, align 8
  %o0 = atomicrmw fadd ptr @fadd_cell, double 2.000000e+00 monotonic, align 8
  %o1 = atomicrmw fadd ptr @fadd_cell, double 3.000000e+00 acquire, align 8
  %o2 = atomicrmw fadd ptr @fadd_cell, double 4.000000e+00 release, align 8
  %o3 = atomicrmw fadd ptr @fadd_cell, double 5.000000e+00 acq_rel, align 8
  %o4 = atomicrmw fadd ptr @fadd_cell, double 6.000000e+00 seq_cst, align 8
  %o5 = atomicrmw volatile fadd ptr @fadd_cell, double 7.000000e+00 syncscope("singlethread") seq_cst, align 8
  %final = load double, ptr @fadd_cell, align 8
  %b0 = bitcast double %o0 to i64
  %b1 = bitcast double %o1 to i64
  %b2 = bitcast double %o2 to i64
  %b3 = bitcast double %o3 to i64
  %b4 = bitcast double %o4 to i64
  %b5 = bitcast double %o5 to i64
  %bf = bitcast double %final to i64
  %p0 = getelementptr inbounds [7 x i64], ptr @ref_fadd_obs, i64 0, i64 0
  %p1 = getelementptr inbounds [7 x i64], ptr @ref_fadd_obs, i64 0, i64 1
  %p2 = getelementptr inbounds [7 x i64], ptr @ref_fadd_obs, i64 0, i64 2
  %p3 = getelementptr inbounds [7 x i64], ptr @ref_fadd_obs, i64 0, i64 3
  %p4 = getelementptr inbounds [7 x i64], ptr @ref_fadd_obs, i64 0, i64 4
  %p5 = getelementptr inbounds [7 x i64], ptr @ref_fadd_obs, i64 0, i64 5
  %pf = getelementptr inbounds [7 x i64], ptr @ref_fadd_obs, i64 0, i64 6
  store i64 %b0, ptr %p0, align 8
  store i64 %b1, ptr %p1, align 8
  store i64 %b2, ptr %p2, align 8
  store i64 %b3, ptr %p3, align 8
  store i64 %b4, ptr %p4, align 8
  store i64 %b5, ptr %p5, align 8
  store i64 %bf, ptr %pf, align 8
  ret void
}

define void @protected_fadd() noinline optnone {
entry:
  call void @hikari_vmp()
  store double 1.000000e+00, ptr @fadd_cell, align 8
  %o0 = atomicrmw fadd ptr @fadd_cell, double 2.000000e+00 monotonic, align 8
  %o1 = atomicrmw fadd ptr @fadd_cell, double 3.000000e+00 acquire, align 8
  %o2 = atomicrmw fadd ptr @fadd_cell, double 4.000000e+00 release, align 8
  %o3 = atomicrmw fadd ptr @fadd_cell, double 5.000000e+00 acq_rel, align 8
  %o4 = atomicrmw fadd ptr @fadd_cell, double 6.000000e+00 seq_cst, align 8
  %o5 = atomicrmw volatile fadd ptr @fadd_cell, double 7.000000e+00 syncscope("singlethread") seq_cst, align 8
  %final = load double, ptr @fadd_cell, align 8
  %b0 = bitcast double %o0 to i64
  %b1 = bitcast double %o1 to i64
  %b2 = bitcast double %o2 to i64
  %b3 = bitcast double %o3 to i64
  %b4 = bitcast double %o4 to i64
  %b5 = bitcast double %o5 to i64
  %bf = bitcast double %final to i64
  %p0 = getelementptr inbounds [7 x i64], ptr @prot_fadd_obs, i64 0, i64 0
  %p1 = getelementptr inbounds [7 x i64], ptr @prot_fadd_obs, i64 0, i64 1
  %p2 = getelementptr inbounds [7 x i64], ptr @prot_fadd_obs, i64 0, i64 2
  %p3 = getelementptr inbounds [7 x i64], ptr @prot_fadd_obs, i64 0, i64 3
  %p4 = getelementptr inbounds [7 x i64], ptr @prot_fadd_obs, i64 0, i64 4
  %p5 = getelementptr inbounds [7 x i64], ptr @prot_fadd_obs, i64 0, i64 5
  %pf = getelementptr inbounds [7 x i64], ptr @prot_fadd_obs, i64 0, i64 6
  store i64 %b0, ptr %p0, align 8
  store i64 %b1, ptr %p1, align 8
  store i64 %b2, ptr %p2, align 8
  store i64 %b3, ptr %p3, align 8
  store i64 %b4, ptr %p4, align 8
  store i64 %b5, ptr %p5, align 8
  store i64 %bf, ptr %pf, align 8
  ret void
}

; fsub: monotonic then volatile singlethread acq_rel.
define void @reference_fsub() {
entry:
  store double 1.000000e+01, ptr @fsub_cell, align 8
  %o0 = atomicrmw fsub ptr @fsub_cell, double 1.500000e+00 monotonic, align 8
  %o1 = atomicrmw volatile fsub ptr @fsub_cell, double 2.500000e+00 syncscope("singlethread") acq_rel, align 8
  %final = load double, ptr @fsub_cell, align 8
  %b0 = bitcast double %o0 to i64
  %b1 = bitcast double %o1 to i64
  %bf = bitcast double %final to i64
  %p0 = getelementptr inbounds [3 x i64], ptr @ref_fsub_obs, i64 0, i64 0
  %p1 = getelementptr inbounds [3 x i64], ptr @ref_fsub_obs, i64 0, i64 1
  %pf = getelementptr inbounds [3 x i64], ptr @ref_fsub_obs, i64 0, i64 2
  store i64 %b0, ptr %p0, align 8
  store i64 %b1, ptr %p1, align 8
  store i64 %bf, ptr %pf, align 8
  ret void
}

define void @protected_fsub() noinline optnone {
entry:
  call void @hikari_vmp()
  store double 1.000000e+01, ptr @fsub_cell, align 8
  %o0 = atomicrmw fsub ptr @fsub_cell, double 1.500000e+00 monotonic, align 8
  %o1 = atomicrmw volatile fsub ptr @fsub_cell, double 2.500000e+00 syncscope("singlethread") acq_rel, align 8
  %final = load double, ptr @fsub_cell, align 8
  %b0 = bitcast double %o0 to i64
  %b1 = bitcast double %o1 to i64
  %bf = bitcast double %final to i64
  %p0 = getelementptr inbounds [3 x i64], ptr @prot_fsub_obs, i64 0, i64 0
  %p1 = getelementptr inbounds [3 x i64], ptr @prot_fsub_obs, i64 0, i64 1
  %pf = getelementptr inbounds [3 x i64], ptr @prot_fsub_obs, i64 0, i64 2
  store i64 %b0, ptr %p0, align 8
  store i64 %b1, ptr %p1, align 8
  store i64 %bf, ptr %pf, align 8
  ret void
}

; fmax: seq_cst then release.  3 then max 5 then max 1 → olds 3,5 final 5.
define void @reference_fmax() {
entry:
  store double 3.000000e+00, ptr @fmax_cell, align 8
  %o0 = atomicrmw fmax ptr @fmax_cell, double 5.000000e+00 seq_cst, align 8
  %o1 = atomicrmw fmax ptr @fmax_cell, double 1.000000e+00 release, align 8
  %final = load double, ptr @fmax_cell, align 8
  %b0 = bitcast double %o0 to i64
  %b1 = bitcast double %o1 to i64
  %bf = bitcast double %final to i64
  %p0 = getelementptr inbounds [3 x i64], ptr @ref_fmax_obs, i64 0, i64 0
  %p1 = getelementptr inbounds [3 x i64], ptr @ref_fmax_obs, i64 0, i64 1
  %pf = getelementptr inbounds [3 x i64], ptr @ref_fmax_obs, i64 0, i64 2
  store i64 %b0, ptr %p0, align 8
  store i64 %b1, ptr %p1, align 8
  store i64 %bf, ptr %pf, align 8
  ret void
}

define void @protected_fmax() noinline optnone {
entry:
  call void @hikari_vmp()
  store double 3.000000e+00, ptr @fmax_cell, align 8
  %o0 = atomicrmw fmax ptr @fmax_cell, double 5.000000e+00 seq_cst, align 8
  %o1 = atomicrmw fmax ptr @fmax_cell, double 1.000000e+00 release, align 8
  %final = load double, ptr @fmax_cell, align 8
  %b0 = bitcast double %o0 to i64
  %b1 = bitcast double %o1 to i64
  %bf = bitcast double %final to i64
  %p0 = getelementptr inbounds [3 x i64], ptr @prot_fmax_obs, i64 0, i64 0
  %p1 = getelementptr inbounds [3 x i64], ptr @prot_fmax_obs, i64 0, i64 1
  %pf = getelementptr inbounds [3 x i64], ptr @prot_fmax_obs, i64 0, i64 2
  store i64 %b0, ptr %p0, align 8
  store i64 %b1, ptr %p1, align 8
  store i64 %bf, ptr %pf, align 8
  ret void
}

; fmin: acquire then volatile acq_rel.  3 then min 2 then min 4 → olds 3,2 final 2.
define void @reference_fmin() {
entry:
  store double 3.000000e+00, ptr @fmin_cell, align 8
  %o0 = atomicrmw fmin ptr @fmin_cell, double 2.000000e+00 acquire, align 8
  %o1 = atomicrmw volatile fmin ptr @fmin_cell, double 4.000000e+00 acq_rel, align 8
  %final = load double, ptr @fmin_cell, align 8
  %b0 = bitcast double %o0 to i64
  %b1 = bitcast double %o1 to i64
  %bf = bitcast double %final to i64
  %p0 = getelementptr inbounds [3 x i64], ptr @ref_fmin_obs, i64 0, i64 0
  %p1 = getelementptr inbounds [3 x i64], ptr @ref_fmin_obs, i64 0, i64 1
  %pf = getelementptr inbounds [3 x i64], ptr @ref_fmin_obs, i64 0, i64 2
  store i64 %b0, ptr %p0, align 8
  store i64 %b1, ptr %p1, align 8
  store i64 %bf, ptr %pf, align 8
  ret void
}

define void @protected_fmin() noinline optnone {
entry:
  call void @hikari_vmp()
  store double 3.000000e+00, ptr @fmin_cell, align 8
  %o0 = atomicrmw fmin ptr @fmin_cell, double 2.000000e+00 acquire, align 8
  %o1 = atomicrmw volatile fmin ptr @fmin_cell, double 4.000000e+00 acq_rel, align 8
  %final = load double, ptr @fmin_cell, align 8
  %b0 = bitcast double %o0 to i64
  %b1 = bitcast double %o1 to i64
  %bf = bitcast double %final to i64
  %p0 = getelementptr inbounds [3 x i64], ptr @prot_fmin_obs, i64 0, i64 0
  %p1 = getelementptr inbounds [3 x i64], ptr @prot_fmin_obs, i64 0, i64 1
  %pf = getelementptr inbounds [3 x i64], ptr @prot_fmin_obs, i64 0, i64 2
  store i64 %b0, ptr %p0, align 8
  store i64 %b1, ptr %p1, align 8
  store i64 %bf, ptr %pf, align 8
  ret void
}

define i1 @eq3(ptr %a, ptr %b) {
entry:
  %a0p = getelementptr inbounds [3 x i64], ptr %a, i64 0, i64 0
  %a1p = getelementptr inbounds [3 x i64], ptr %a, i64 0, i64 1
  %a2p = getelementptr inbounds [3 x i64], ptr %a, i64 0, i64 2
  %b0p = getelementptr inbounds [3 x i64], ptr %b, i64 0, i64 0
  %b1p = getelementptr inbounds [3 x i64], ptr %b, i64 0, i64 1
  %b2p = getelementptr inbounds [3 x i64], ptr %b, i64 0, i64 2
  %a0 = load i64, ptr %a0p, align 8
  %a1 = load i64, ptr %a1p, align 8
  %a2 = load i64, ptr %a2p, align 8
  %b0 = load i64, ptr %b0p, align 8
  %b1 = load i64, ptr %b1p, align 8
  %b2 = load i64, ptr %b2p, align 8
  %c0 = icmp eq i64 %a0, %b0
  %c1 = icmp eq i64 %a1, %b1
  %c2 = icmp eq i64 %a2, %b2
  %t0 = and i1 %c0, %c1
  %ok = and i1 %t0, %c2
  ret i1 %ok
}

define i1 @eq7(ptr %a, ptr %b) {
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
  call void @reference_fadd()
  call void @protected_fadd()
  call void @reference_fsub()
  call void @protected_fsub()
  call void @reference_fmax()
  call void @protected_fmax()
  call void @reference_fmin()
  call void @protected_fmin()
  %m0 = call i1 @eq7(ptr @ref_fadd_obs, ptr @prot_fadd_obs)
  %m1 = call i1 @eq3(ptr @ref_fsub_obs, ptr @prot_fsub_obs)
  %m2 = call i1 @eq3(ptr @ref_fmax_obs, ptr @prot_fmax_obs)
  %m3 = call i1 @eq3(ptr @ref_fmin_obs, ptr @prot_fmin_obs)
  %t0 = and i1 %m0, %m1
  %t1 = and i1 %m2, %m3
  %ok = and i1 %t0, %t1
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with: 94
; SKIP-NOT: Skipping VMP on protected_fadd:
; SKIP-NOT: Skipping VMP on protected_fsub:
; SKIP-NOT: Skipping VMP on protected_fmax:
; SKIP-NOT: Skipping VMP on protected_fmin:

; VIRT-LABEL: define void @protected_fadd(
; VIRT: vmp.dispatch:
; VIRT-DAG: atomicrmw fadd {{.*}} double {{.*}} monotonic
; VIRT-DAG: atomicrmw fadd {{.*}} double {{.*}} acquire
; VIRT-DAG: atomicrmw fadd {{.*}} double {{.*}} release
; VIRT-DAG: atomicrmw fadd {{.*}} double {{.*}} acq_rel
; VIRT-DAG: atomicrmw fadd {{.*}} double {{.*}} seq_cst
; VIRT-DAG: atomicrmw volatile fadd {{.*}} double {{.*}} syncscope("singlethread") seq_cst

; VIRT-LABEL: define void @protected_fsub(
; VIRT: vmp.dispatch:
; VIRT-DAG: atomicrmw fsub {{.*}} double {{.*}} monotonic
; VIRT-DAG: atomicrmw volatile fsub {{.*}} double {{.*}} syncscope("singlethread") acq_rel

; VIRT-LABEL: define void @protected_fmax(
; VIRT: vmp.dispatch:
; VIRT-DAG: atomicrmw fmax {{.*}} double {{.*}} seq_cst
; VIRT-DAG: atomicrmw fmax {{.*}} double {{.*}} release

; VIRT-LABEL: define void @protected_fmin(
; VIRT: vmp.dispatch:
; VIRT-DAG: atomicrmw fmin {{.*}} double {{.*}} acquire
; VIRT-DAG: atomicrmw volatile fmin {{.*}} double {{.*}} acq_rel

; VIRT: attributes{{.*}}"hikari.vmp.virtualized"
