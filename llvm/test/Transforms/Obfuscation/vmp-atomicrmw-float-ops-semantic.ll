; Focused AS0 scalar f32/f64 atomicrmw fadd/fsub/fmax/fmin lock-in
; (generic IR, no new opcode).  Production already replays native
; CreateAtomicRMW: result is the old value; the cell becomes
; old+rhs / old-rhs / maxnum(old,rhs) / minnum(old,rhs) per LLVM 15
; LangRef.  maxnum/minnum: if one operand is NaN, return the other;
; fmax(+/-0,+/-0) may return either zero, so this lit does not lock
; signed-zero extrema bits.  Signed-zero is locked on fadd
; (-0)+(+0) → +0.  Ordering / syncscope / volatile / alignment /
; memory metadata are copied.  Do not treat integer RMW, xchg,
; cmpxchg, or fence as this family's negatives.
;
; Independent bit-pattern observations (no XOR mix).  f32 fmax
; seq_cst carries !tbaa.  Parseable misses: half/bfloat/fp128 fadd,
; AS1 fadd, 256-bit vector return, non-AArch64.  Rejected bodies stay
; out of host lli: AArch64 transform, internalize/globaldce to main,
; then substitute only the live triple.
;
; Pipeline:
;   O0/O2 x aesSeed 97/7: opt → SKIP → VIRT → internalize main →
;   AArch64 llc/readobj → host lli on transformed triple only.
;   Source-triple swap is HOST.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.ll -o %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.live.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.ll -o %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.live.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.s7.ll -o %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.s7.live.ll > %t.o0.s7.host.ll
; RUN: lli -force-interpreter %t.o0.s7.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.s7.ll -o %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.s7.live.ll > %t.o2.s7.host.ll
; RUN: lli -force-interpreter %t.o2.s7.host.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %s | opt -S -verify-each -aesSeed=97 -passes='default<O0>' - 2>&1 | FileCheck %s --check-prefix=HOST

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()

@f32_add = global float 0.000000e+00, align 4
@f32_sub = global float 0.000000e+00, align 4
@f32_max = global float 0.000000e+00, align 4
@f32_min = global float 0.000000e+00, align 4
@f32_sz = global float 0.000000e+00, align 4
@f64_add = global double 0.000000e+00, align 8
@f64_max = global double 0.000000e+00, align 8
@f64_min = global double 0.000000e+00, align 8
@hcell = global half 0xH0000, align 2
@bfcell = global bfloat 0xR0000, align 2
@fp128_cell = global fp128 0xL00000000000000000000000000000000, align 16
@as1_cell = addrspace(1) global float 0.000000e+00, align 4

@ref_f32_obs = global [8 x i32] zeroinitializer, align 4
@prot_f32_obs = global [8 x i32] zeroinitializer, align 4
@ref_f64_obs = global [6 x i64] zeroinitializer, align 8
@prot_f64_obs = global [6 x i64] zeroinitializer, align 8

; f32 fadd: 1+2+3 → olds 1,3 final 6.
; f32 fsub: 10-1.5 then volatile -2.5 → olds 10,8.5 final 6.
; f32 signed zero: store -0, fadd +0 → old -0 bits, final +0 bits.
; f32 fmax maxnum: qNaN then 1.0 seq_cst !tbaa → old is NaN, final 1.0.
; f32 fmin: 3 then 2 → old 3 final 2.
; f64 fadd: 1+2+3 → 1,3,6.
; f64 fmax: 3 then 5 then 1 → 3,5,5.
; f64 fmin maxnum-NaN: qNaN then 2.0 → old is NaN, final 2.0.
define void @reference() {
entry:
  store float 1.000000e+00, ptr @f32_add, align 4
  %a0 = atomicrmw fadd ptr @f32_add, float 2.000000e+00 monotonic, align 4
  %a1 = atomicrmw fadd ptr @f32_add, float 3.000000e+00 acquire, align 4
  %af = load float, ptr @f32_add, align 4
  store float 1.000000e+01, ptr @f32_sub, align 4
  %s0 = atomicrmw fsub ptr @f32_sub, float 1.500000e+00 release, align 4
  %s1 = atomicrmw volatile fsub ptr @f32_sub, float 2.500000e+00 syncscope("singlethread") acq_rel, align 4
  %sf = load float, ptr @f32_sub, align 4
  store float -0.000000e+00, ptr @f32_sz, align 4
  %z0 = atomicrmw fadd ptr @f32_sz, float 0.000000e+00 seq_cst, align 4
  %zf = load float, ptr @f32_sz, align 4
  store float 0x7FF8000000000000, ptr @f32_max, align 4
  %x0 = atomicrmw fmax ptr @f32_max, float 1.000000e+00 seq_cst, align 4, !tbaa !3
  %xf = load float, ptr @f32_max, align 4
  %xnan = fcmp uno float %x0, %x0
  %xflag = zext i1 %xnan to i32
  store float 3.000000e+00, ptr @f32_min, align 4
  %n0 = atomicrmw volatile fmin ptr @f32_min, float 2.000000e+00 syncscope("singlethread") acquire, align 4
  %nf = load float, ptr @f32_min, align 4
  %ba0 = bitcast float %a0 to i32
  %ba1 = bitcast float %a1 to i32
  %baf = bitcast float %af to i32
  %bs0 = bitcast float %s0 to i32
  %bs1 = bitcast float %s1 to i32
  %bsf = bitcast float %sf to i32
  %bz0 = bitcast float %z0 to i32
  %bzf = bitcast float %zf to i32
  %bn0 = bitcast float %n0 to i32
  %bxf = bitcast float %xf to i32
  store i32 %ba0, ptr getelementptr inbounds ([8 x i32], ptr @ref_f32_obs, i64 0, i64 0), align 4
  store i32 %ba1, ptr getelementptr inbounds ([8 x i32], ptr @ref_f32_obs, i64 0, i64 1), align 4
  store i32 %baf, ptr getelementptr inbounds ([8 x i32], ptr @ref_f32_obs, i64 0, i64 2), align 4
  store i32 %bs0, ptr getelementptr inbounds ([8 x i32], ptr @ref_f32_obs, i64 0, i64 3), align 4
  store i32 %bn0, ptr getelementptr inbounds ([8 x i32], ptr @ref_f32_obs, i64 0, i64 4), align 4
  store i32 %bz0, ptr getelementptr inbounds ([8 x i32], ptr @ref_f32_obs, i64 0, i64 5), align 4
  store i32 %bzf, ptr getelementptr inbounds ([8 x i32], ptr @ref_f32_obs, i64 0, i64 6), align 4
  store i32 %bxf, ptr getelementptr inbounds ([8 x i32], ptr @ref_f32_obs, i64 0, i64 7), align 4

  store double 1.000000e+00, ptr @f64_add, align 8
  %d0 = atomicrmw fadd ptr @f64_add, double 2.000000e+00 monotonic, align 8
  %d1 = atomicrmw fadd ptr @f64_add, double 3.000000e+00 acq_rel, align 8
  %df = load double, ptr @f64_add, align 8
  store double 3.000000e+00, ptr @f64_max, align 8
  %e0 = atomicrmw fmax ptr @f64_max, double 5.000000e+00 release, align 8
  %ef = load double, ptr @f64_max, align 8
  store double 0x7FF8000000000000, ptr @f64_min, align 8
  %g0 = atomicrmw fmin ptr @f64_min, double 2.000000e+00 seq_cst, align 8
  %gf = load double, ptr @f64_min, align 8
  %gnan = fcmp uno double %g0, %g0
  %gflag = zext i1 %gnan to i64
  %bd0 = bitcast double %d0 to i64
  %bd1 = bitcast double %d1 to i64
  %bdf = bitcast double %df to i64
  %be0 = bitcast double %e0 to i64
  %bef = bitcast double %ef to i64
  store i64 %bd0, ptr getelementptr inbounds ([6 x i64], ptr @ref_f64_obs, i64 0, i64 0), align 8
  store i64 %bd1, ptr getelementptr inbounds ([6 x i64], ptr @ref_f64_obs, i64 0, i64 1), align 8
  store i64 %bdf, ptr getelementptr inbounds ([6 x i64], ptr @ref_f64_obs, i64 0, i64 2), align 8
  store i64 %be0, ptr getelementptr inbounds ([6 x i64], ptr @ref_f64_obs, i64 0, i64 3), align 8
  store i64 %bef, ptr getelementptr inbounds ([6 x i64], ptr @ref_f64_obs, i64 0, i64 4), align 8
  %bgf = bitcast double %gf to i64
  store i64 %bgf, ptr getelementptr inbounds ([6 x i64], ptr @ref_f64_obs, i64 0, i64 5), align 8
  ret void
}

define void @protected() noinline optnone {
entry:
  call void @hikari_vmp()
  store float 1.000000e+00, ptr @f32_add, align 4
  %a0 = atomicrmw fadd ptr @f32_add, float 2.000000e+00 monotonic, align 4
  %a1 = atomicrmw fadd ptr @f32_add, float 3.000000e+00 acquire, align 4
  %af = load float, ptr @f32_add, align 4
  store float 1.000000e+01, ptr @f32_sub, align 4
  %s0 = atomicrmw fsub ptr @f32_sub, float 1.500000e+00 release, align 4
  %s1 = atomicrmw volatile fsub ptr @f32_sub, float 2.500000e+00 syncscope("singlethread") acq_rel, align 4
  %sf = load float, ptr @f32_sub, align 4
  store float -0.000000e+00, ptr @f32_sz, align 4
  %z0 = atomicrmw fadd ptr @f32_sz, float 0.000000e+00 seq_cst, align 4
  %zf = load float, ptr @f32_sz, align 4
  store float 0x7FF8000000000000, ptr @f32_max, align 4
  %x0 = atomicrmw fmax ptr @f32_max, float 1.000000e+00 seq_cst, align 4, !tbaa !3
  %xf = load float, ptr @f32_max, align 4
  %xnan = fcmp uno float %x0, %x0
  %xflag = zext i1 %xnan to i32
  store float 3.000000e+00, ptr @f32_min, align 4
  %n0 = atomicrmw volatile fmin ptr @f32_min, float 2.000000e+00 syncscope("singlethread") acquire, align 4
  %nf = load float, ptr @f32_min, align 4
  %ba0 = bitcast float %a0 to i32
  %ba1 = bitcast float %a1 to i32
  %baf = bitcast float %af to i32
  %bs0 = bitcast float %s0 to i32
  %bs1 = bitcast float %s1 to i32
  %bsf = bitcast float %sf to i32
  %bz0 = bitcast float %z0 to i32
  %bzf = bitcast float %zf to i32
  %bn0 = bitcast float %n0 to i32
  %bxf = bitcast float %xf to i32
  store i32 %ba0, ptr getelementptr inbounds ([8 x i32], ptr @prot_f32_obs, i64 0, i64 0), align 4
  store i32 %ba1, ptr getelementptr inbounds ([8 x i32], ptr @prot_f32_obs, i64 0, i64 1), align 4
  store i32 %baf, ptr getelementptr inbounds ([8 x i32], ptr @prot_f32_obs, i64 0, i64 2), align 4
  store i32 %bs0, ptr getelementptr inbounds ([8 x i32], ptr @prot_f32_obs, i64 0, i64 3), align 4
  store i32 %bn0, ptr getelementptr inbounds ([8 x i32], ptr @prot_f32_obs, i64 0, i64 4), align 4
  store i32 %bz0, ptr getelementptr inbounds ([8 x i32], ptr @prot_f32_obs, i64 0, i64 5), align 4
  store i32 %bzf, ptr getelementptr inbounds ([8 x i32], ptr @prot_f32_obs, i64 0, i64 6), align 4
  store i32 %bxf, ptr getelementptr inbounds ([8 x i32], ptr @prot_f32_obs, i64 0, i64 7), align 4

  store double 1.000000e+00, ptr @f64_add, align 8
  %d0 = atomicrmw fadd ptr @f64_add, double 2.000000e+00 monotonic, align 8
  %d1 = atomicrmw fadd ptr @f64_add, double 3.000000e+00 acq_rel, align 8
  %df = load double, ptr @f64_add, align 8
  store double 3.000000e+00, ptr @f64_max, align 8
  %e0 = atomicrmw fmax ptr @f64_max, double 5.000000e+00 release, align 8
  %ef = load double, ptr @f64_max, align 8
  store double 0x7FF8000000000000, ptr @f64_min, align 8
  %g0 = atomicrmw fmin ptr @f64_min, double 2.000000e+00 seq_cst, align 8
  %gf = load double, ptr @f64_min, align 8
  %gnan = fcmp uno double %g0, %g0
  %gflag = zext i1 %gnan to i64
  %bd0 = bitcast double %d0 to i64
  %bd1 = bitcast double %d1 to i64
  %bdf = bitcast double %df to i64
  %be0 = bitcast double %e0 to i64
  %bef = bitcast double %ef to i64
  store i64 %bd0, ptr getelementptr inbounds ([6 x i64], ptr @prot_f64_obs, i64 0, i64 0), align 8
  store i64 %bd1, ptr getelementptr inbounds ([6 x i64], ptr @prot_f64_obs, i64 0, i64 1), align 8
  store i64 %bdf, ptr getelementptr inbounds ([6 x i64], ptr @prot_f64_obs, i64 0, i64 2), align 8
  store i64 %be0, ptr getelementptr inbounds ([6 x i64], ptr @prot_f64_obs, i64 0, i64 3), align 8
  store i64 %bef, ptr getelementptr inbounds ([6 x i64], ptr @prot_f64_obs, i64 0, i64 4), align 8
  %bgf = bitcast double %gf to i64
  store i64 %bgf, ptr getelementptr inbounds ([6 x i64], ptr @prot_f64_obs, i64 0, i64 5), align 8
  ret void
}

define void @unsupported_half_fadd() {
entry:
  call void @hikari_vmp()
  %v = atomicrmw fadd ptr @hcell, half 0xH3C00 seq_cst, align 2
  ret void
}

define void @unsupported_bfloat_fadd() {
entry:
  call void @hikari_vmp()
  %v = atomicrmw fadd ptr @bfcell, bfloat 0xR3F80 seq_cst, align 2
  ret void
}

define void @unsupported_fp128_fadd() {
entry:
  call void @hikari_vmp()
  %v = atomicrmw fadd ptr @fp128_cell, fp128 0xL00000000000000003FFF000000000000 seq_cst, align 16
  ret void
}

define float @unsupported_as1_fadd() {
entry:
  call void @hikari_vmp()
  %v = atomicrmw fadd ptr addrspace(1) @as1_cell, float 1.000000e+00 seq_cst, align 4
  ret float %v
}

define <8 x float> @unsupported_vector_fadd() {
entry:
  call void @hikari_vmp()
  ret <8 x float> zeroinitializer
}

define i1 @eq8_i32(ptr %a, ptr %b) {
entry:
  %a0p = getelementptr inbounds [8 x i32], ptr %a, i64 0, i64 0
  %a1p = getelementptr inbounds [8 x i32], ptr %a, i64 0, i64 1
  %a2p = getelementptr inbounds [8 x i32], ptr %a, i64 0, i64 2
  %a3p = getelementptr inbounds [8 x i32], ptr %a, i64 0, i64 3
  %a4p = getelementptr inbounds [8 x i32], ptr %a, i64 0, i64 4
  %a5p = getelementptr inbounds [8 x i32], ptr %a, i64 0, i64 5
  %a6p = getelementptr inbounds [8 x i32], ptr %a, i64 0, i64 6
  %a7p = getelementptr inbounds [8 x i32], ptr %a, i64 0, i64 7
  %b0p = getelementptr inbounds [8 x i32], ptr %b, i64 0, i64 0
  %b1p = getelementptr inbounds [8 x i32], ptr %b, i64 0, i64 1
  %b2p = getelementptr inbounds [8 x i32], ptr %b, i64 0, i64 2
  %b3p = getelementptr inbounds [8 x i32], ptr %b, i64 0, i64 3
  %b4p = getelementptr inbounds [8 x i32], ptr %b, i64 0, i64 4
  %b5p = getelementptr inbounds [8 x i32], ptr %b, i64 0, i64 5
  %b6p = getelementptr inbounds [8 x i32], ptr %b, i64 0, i64 6
  %b7p = getelementptr inbounds [8 x i32], ptr %b, i64 0, i64 7
  %a0 = load i32, ptr %a0p, align 4
  %a1 = load i32, ptr %a1p, align 4
  %a2 = load i32, ptr %a2p, align 4
  %a3 = load i32, ptr %a3p, align 4
  %a4 = load i32, ptr %a4p, align 4
  %a5 = load i32, ptr %a5p, align 4
  %a6 = load i32, ptr %a6p, align 4
  %a7 = load i32, ptr %a7p, align 4
  %b0 = load i32, ptr %b0p, align 4
  %b1 = load i32, ptr %b1p, align 4
  %b2 = load i32, ptr %b2p, align 4
  %b3 = load i32, ptr %b3p, align 4
  %b4 = load i32, ptr %b4p, align 4
  %b5 = load i32, ptr %b5p, align 4
  %b6 = load i32, ptr %b6p, align 4
  %b7 = load i32, ptr %b7p, align 4
  %c0 = icmp eq i32 %a0, %b0
  %c1 = icmp eq i32 %a1, %b1
  %c2 = icmp eq i32 %a2, %b2
  %c3 = icmp eq i32 %a3, %b3
  %c4 = icmp eq i32 %a4, %b4
  %c5 = icmp eq i32 %a5, %b5
  %c6 = icmp eq i32 %a6, %b6
  %c7 = icmp eq i32 %a7, %b7
  %t0 = and i1 %c0, %c1
  %t1 = and i1 %c2, %c3
  %t2 = and i1 %c4, %c5
  %t3 = and i1 %c6, %c7
  %t4 = and i1 %t0, %t1
  %t5 = and i1 %t2, %t3
  %ok = and i1 %t4, %t5
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
  call void @reference()
  call void @protected()
  %m0 = call i1 @eq8_i32(ptr @ref_f32_obs, ptr @prot_f32_obs)
  %m1 = call i1 @eq6_i64(ptr @ref_f64_obs, ptr @prot_f64_obs)
  %ok = and i1 %m0, %m1
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

!0 = !{!"Simple C/C++ TBAA"}
!1 = !{!"omnipotent char", !0, i64 0}
!2 = !{!"float", !1, i64 0}
!3 = !{!2, !2, i64 0}

; SKIP-DAG: Skipping VMP on unsupported_half_fadd: unsupported atomicrmw instruction
; SKIP-DAG: Skipping VMP on unsupported_bfloat_fadd: unsupported atomicrmw instruction
; SKIP-DAG: Skipping VMP on unsupported_fp128_fadd: unsupported atomicrmw instruction
; SKIP-DAG: Skipping VMP on unsupported_as1_fadd: unsupported atomicrmw instruction
; SKIP-DAG: Skipping VMP on unsupported_vector_fadd: unsupported return type
; SKIP-NOT: Skipping VMP on protected:
; SKIP-NOT: Skipping VMP on reference:

; VIRT-LABEL: define void @protected(
; VIRT: vmp.dispatch:
; VIRT-DAG: atomicrmw fadd {{.*}} float {{.*}} monotonic, align 4
; VIRT-DAG: atomicrmw fadd {{.*}} float {{.*}} acquire, align 4
; VIRT-DAG: atomicrmw fsub {{.*}} float {{.*}} release, align 4
; VIRT-DAG: atomicrmw volatile fsub {{.*}} float {{.*}} syncscope("singlethread") acq_rel, align 4
; VIRT-DAG: atomicrmw fadd {{.*}} float {{.*}} seq_cst, align 4
; VIRT-DAG: atomicrmw fmax {{.*}} float {{.*}} seq_cst, align 4, !tbaa !
; VIRT-DAG: atomicrmw volatile fmin {{.*}} float {{.*}} syncscope("singlethread") acquire, align 4
; VIRT-DAG: atomicrmw fadd {{.*}} double {{.*}} monotonic, align 8
; VIRT-DAG: atomicrmw fadd {{.*}} double {{.*}} acq_rel, align 8
; VIRT-DAG: atomicrmw fmax {{.*}} double {{.*}} release, align 8
; VIRT-DAG: atomicrmw fmin {{.*}} double {{.*}} seq_cst, align 8

; VIRT-LABEL: define void @unsupported_half_fadd(
; VIRT-NOT: vmp.dispatch:
; VIRT: atomicrmw fadd {{.*}} half

; VIRT-LABEL: define void @unsupported_bfloat_fadd(
; VIRT-NOT: vmp.dispatch:
; VIRT: atomicrmw fadd {{.*}} bfloat

; VIRT-LABEL: define void @unsupported_fp128_fadd(
; VIRT-NOT: vmp.dispatch:
; VIRT: atomicrmw fadd {{.*}} fp128

; VIRT-LABEL: define float @unsupported_as1_fadd(
; VIRT-NOT: vmp.dispatch:
; VIRT: atomicrmw fadd ptr addrspace(1)

; VIRT-LABEL: define <8 x float> @unsupported_vector_fadd(
; VIRT-NOT: vmp.dispatch:
; VIRT: ret <8 x float>

; VIRT: attributes{{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; HOST: Skipping VMP: only AArch64 targets are supported
