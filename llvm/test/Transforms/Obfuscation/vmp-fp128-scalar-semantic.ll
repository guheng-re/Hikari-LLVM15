; Bounded scalar IEEE fp128 VMP: dedicated typed [N x fp128] frame
; (vmp.fp128.regs), never the i128 integer frame or the i64
; half/f32/f64/bfloat float frame.  Covers args/returns, ConstantFP,
; entry static alloca, non-atomic AS0 load/store, fadd/fsub/fmul/fdiv/
; frem/fneg with FastMathFlags, fcmp, select, phi (parallel copy),
; freeze (undef/poison only at FreezeInst), and fp128 <-> half/float/
; double plus i1/i8/i16/i32/i64 conversions.
;
; Not opened: vectors, aggregate fields, atomics, pointer casts,
; varargs, indirect calls, complex ABI, constrained lround and
; constrained fp128 math, arbitrary direct fp128 calls, ppc_fp128,
; bitcast to i128.  Listed sqrt/fabs/fma/fmuladd.f128 live in
; vmp-fp128-math-semantic.ll.  Listed min/max and rounding live in
; vmp-fp128-minmax-round-semantic.ll.  Listed copysign/pow/powi/
; transcendentals live in vmp-fp128-copy-pow-transcendental-semantic.ll.
; Listed canonicalize.f128 lives in vmp-fp128-canonicalize-semantic.ll.
; Listed is.fpclass.f128 lives in vmp-fp128-fpclass-semantic.ll.
; Listed lround/llround/lrint/llrint and fptosi.sat/fptoui.sat live
; in vmp-fp128-int-round-semantic.ll.
;
; Host lli interpreter can evaluate fp128.  FileCheck + lli + AArch64
; llc/readobj.  O0/O2 x aesSeed 97/7.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.ll > %t.o0.live.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.live.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.ll > %t.o2.live.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.live.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.s7.ll > %t.o0.s7.live.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.s7.live.ll > %t.o0.s7.host.ll
; RUN: lli -force-interpreter %t.o0.s7.host.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.s7.ll > %t.o2.s7.live.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.s7.live.ll > %t.o2.s7.host.ll
; RUN: lli -force-interpreter %t.o2.s7.host.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare i64 @llvm.experimental.constrained.lround.i64.f128(fp128, metadata)
declare fp128 @llvm.experimental.constrained.fadd.f128(fp128, fp128, metadata, metadata)
declare fp128 @ext_fp128_vararg(fp128, ...)

@g.fp128 = private global fp128 0xL00000000000000000000000000000000, align 16

define i32 @fold_fp128(fp128 %v) {
entry:
  %b = bitcast fp128 %v to i128
  %lo = trunc i128 %b to i64
  %hi.sh = lshr i128 %b, 64
  %hi = trunc i128 %hi.sh to i64
  %x = xor i64 %lo, %hi
  %r = trunc i64 %x to i32
  ret i32 %r
}

define fp128 @reference_arith(fp128 %a, fp128 %b) {
entry:
  %s = fadd fp128 %a, %b
  %d = fsub fp128 %s, %b
  %m = fmul fp128 %d, %a
  %q = fdiv fp128 %m, %b
  %r = frem fp128 %q, %a
  %n = fneg fp128 %r
  ret fp128 %n
}

define fp128 @protected_arith(fp128 %a, fp128 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %s = fadd fp128 %a, %b
  %d = fsub fp128 %s, %b
  %m = fmul fp128 %d, %a
  %q = fdiv fp128 %m, %b
  %r = frem fp128 %q, %a
  %n = fneg fp128 %r
  ret fp128 %n
}

define fp128 @protected_fmf(fp128 %a, fp128 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %s = fadd nnan nsz fp128 %a, %b
  ret fp128 %s
}

define i32 @reference_cmp(fp128 %a, fp128 %b) {
entry:
  %ogt = fcmp ogt fp128 %a, %b
  %olt = fcmp olt fp128 %a, %b
  %oeq = fcmp oeq fp128 %a, %b
  %une = fcmp une fp128 %a, %b
  %ugt = fcmp ugt fp128 %a, %b
  %z0 = zext i1 %ogt to i32
  %z1 = zext i1 %olt to i32
  %z2 = zext i1 %oeq to i32
  %z3 = zext i1 %une to i32
  %z4 = zext i1 %ugt to i32
  %t0 = or i32 %z0, %z1
  %t1 = or i32 %t0, %z2
  %t2 = or i32 %t1, %z3
  %r = or i32 %t2, %z4
  ret i32 %r
}

define i32 @protected_cmp(fp128 %a, fp128 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %ogt = fcmp ogt fp128 %a, %b
  %olt = fcmp olt fp128 %a, %b
  %oeq = fcmp oeq fp128 %a, %b
  %une = fcmp une fp128 %a, %b
  %ugt = fcmp ugt fp128 %a, %b
  %z0 = zext i1 %ogt to i32
  %z1 = zext i1 %olt to i32
  %z2 = zext i1 %oeq to i32
  %z3 = zext i1 %une to i32
  %z4 = zext i1 %ugt to i32
  %t0 = or i32 %z0, %z1
  %t1 = or i32 %t0, %z2
  %t2 = or i32 %t1, %z3
  %r = or i32 %t2, %z4
  ret i32 %r
}

define fp128 @reference_select(i1 %c, fp128 %a, fp128 %b) {
entry:
  %s = select i1 %c, fp128 %a, fp128 %b
  ret fp128 %s
}

define fp128 @protected_select(i1 %c, fp128 %a, fp128 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %s = select i1 %c, fp128 %a, fp128 %b
  ret fp128 %s
}

define fp128 @reference_phi(i1 %c, fp128 %a, fp128 %b) {
entry:
  br i1 %c, label %left, label %right
left:
  br label %join
right:
  br label %join
join:
  %p = phi fp128 [ %a, %left ], [ %b, %right ]
  ret fp128 %p
}

define fp128 @protected_phi(i1 %c, fp128 %a, fp128 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  br i1 %c, label %left, label %right
left:
  br label %join
right:
  br label %join
join:
  %p = phi fp128 [ %a, %left ], [ %b, %right ]
  ret fp128 %p
}

define fp128 @reference_loop(fp128 %a, i32 %n) {
entry:
  br label %loop
loop:
  %iv = phi i32 [ 0, %entry ], [ %iv.next, %loop ]
  %acc = phi fp128 [ %a, %entry ], [ %acc.next, %loop ]
  %acc.next = fadd fp128 %acc, %a
  %iv.next = add i32 %iv, 1
  %cmp = icmp slt i32 %iv.next, %n
  br i1 %cmp, label %loop, label %done
done:
  ret fp128 %acc.next
}

define fp128 @protected_loop(fp128 %a, i32 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  br label %loop
loop:
  %iv = phi i32 [ 0, %entry ], [ %iv.next, %loop ]
  %acc = phi fp128 [ %a, %entry ], [ %acc.next, %loop ]
  %acc.next = fadd fp128 %acc, %a
  %iv.next = add i32 %iv, 1
  %cmp = icmp slt i32 %iv.next, %n
  br i1 %cmp, label %loop, label %done
done:
  ret fp128 %acc.next
}

define fp128 @reference_mem(fp128 %a) {
entry:
  %p = alloca fp128, align 16
  store fp128 %a, ptr %p, align 16
  %v = load fp128, ptr %p, align 16
  store volatile fp128 %v, ptr @g.fp128, align 16
  %g = load volatile fp128, ptr @g.fp128, align 16
  ret fp128 %g
}

define fp128 @protected_mem(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %p = alloca fp128, align 16
  store fp128 %a, ptr %p, align 16
  %v = load fp128, ptr %p, align 16
  store volatile fp128 %v, ptr @g.fp128, align 16
  %g = load volatile fp128, ptr @g.fp128, align 16
  ret fp128 %g
}

define fp128 @reference_const() {
entry:
  ret fp128 0xL00000000000000003FFF000000000000
}

define fp128 @protected_const() noinline optnone {
entry:
  call void @hikari_vmp()
  ret fp128 0xL00000000000000003FFF000000000000
}

define fp128 @reference_conv(i32 %i, double %d, float %f, half %h) {
entry:
  %fromi = sitofp i32 %i to fp128
  %fromu = uitofp i32 %i to fp128
  %fromd = fpext double %d to fp128
  %fromf = fpext float %f to fp128
  %fromh = fpext half %h to fp128
  %s0 = fadd fp128 %fromi, %fromu
  %s1 = fadd fp128 %s0, %fromd
  %s2 = fadd fp128 %s1, %fromf
  %s3 = fadd fp128 %s2, %fromh
  ret fp128 %s3
}

define fp128 @protected_conv(i32 %i, double %d, float %f, half %h) noinline optnone {
entry:
  call void @hikari_vmp()
  %fromi = sitofp i32 %i to fp128
  %fromu = uitofp i32 %i to fp128
  %fromd = fpext double %d to fp128
  %fromf = fpext float %f to fp128
  %fromh = fpext half %h to fp128
  %s0 = fadd fp128 %fromi, %fromu
  %s1 = fadd fp128 %s0, %fromd
  %s2 = fadd fp128 %s1, %fromf
  %s3 = fadd fp128 %s2, %fromh
  ret fp128 %s3
}

define i32 @reference_trunc(fp128 %a) {
entry:
  %si = fptosi fp128 %a to i32
  %ui = fptoui fp128 %a to i16
  %uz = zext i16 %ui to i32
  %td = fptrunc fp128 %a to double
  %db = bitcast double %td to i64
  %dt = trunc i64 %db to i32
  %t0 = add i32 %si, %uz
  %r = xor i32 %t0, %dt
  ret i32 %r
}

define i32 @protected_trunc(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %si = fptosi fp128 %a to i32
  %ui = fptoui fp128 %a to i16
  %uz = zext i16 %ui to i32
  %td = fptrunc fp128 %a to double
  %db = bitcast double %td to i64
  %dt = trunc i64 %db to i32
  %t0 = add i32 %si, %uz
  %r = xor i32 %t0, %dt
  ret i32 %r
}

define fp128 @protected_freeze(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %f = freeze fp128 %a
  ret fp128 %f
}

define fp128 @protected_freeze_undef() noinline optnone {
entry:
  call void @hikari_vmp()
  %f = freeze fp128 undef
  ret fp128 %f
}

define fp128 @protected_freeze_poison() noinline optnone {
entry:
  call void @hikari_vmp()
  %f = freeze fp128 poison
  ret fp128 %f
}

define fp128 @protected_ret(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  ret fp128 %a
}

; ----- negatives -----

define <1 x fp128> @unsupported_vector(<1 x fp128> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  ret <1 x fp128> %a
}

define { fp128 } @unsupported_agg({ fp128 } %a) noinline optnone {
entry:
  call void @hikari_vmp()
  ret { fp128 } %a
}

define fp128 @unsupported_atomic(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %v = load atomic fp128, ptr %p seq_cst, align 16
  ret fp128 %v
}

define i64 @unsupported_lround(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.experimental.constrained.lround.i64.f128(fp128 %a, metadata !"fpexcept.ignore")
  ret i64 %r
}

define fp128 @unsupported_constrained(fp128 %a, fp128 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 @llvm.experimental.constrained.fadd.f128(fp128 %a, fp128 %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret fp128 %r
}

; Ordinary direct fp128 C is the independent
; vmp-fp128-direct-call-semantic.ll surface.  Vararg stays closed.
define fp128 @unsupported_direct_call(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 (fp128, ...) @ext_fp128_vararg(fp128 %a)
  ret fp128 %r
}

define fp128 @unsupported_indirect(ptr %fp, fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 %fp(fp128 %a)
  ret fp128 %r
}

define i128 @unsupported_bitcast(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %b = bitcast fp128 %a to i128
  ret i128 %b
}

define ppc_fp128 @unsupported_ppc(ppc_fp128 %a, ppc_fp128 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %s = fadd ppc_fp128 %a, %b
  ret ppc_fp128 %s
}

define fp128 @unsupported_poison_add(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %s = fadd fp128 %a, poison
  ret fp128 %s
}

define i32 @main() {
entry:
  %a = fpext double 1.500000e+00 to fp128
  %b = fpext double 2.250000e+00 to fp128
  %e0 = call fp128 @reference_arith(fp128 %a, fp128 %b)
  %p0 = call fp128 @protected_arith(fp128 %a, fp128 %b)
  %fe0 = call i32 @fold_fp128(fp128 %e0)
  %fp0 = call i32 @fold_fp128(fp128 %p0)
  %ok0 = icmp eq i32 %fe0, %fp0
  %e1 = call i32 @reference_cmp(fp128 %a, fp128 %b)
  %p1 = call i32 @protected_cmp(fp128 %a, fp128 %b)
  %ok1 = icmp eq i32 %e1, %p1
  %e2 = call fp128 @reference_select(i1 true, fp128 %a, fp128 %b)
  %p2 = call fp128 @protected_select(i1 true, fp128 %a, fp128 %b)
  %fe2 = call i32 @fold_fp128(fp128 %e2)
  %fp2 = call i32 @fold_fp128(fp128 %p2)
  %ok2 = icmp eq i32 %fe2, %fp2
  %e3 = call fp128 @reference_phi(i1 false, fp128 %a, fp128 %b)
  %p3 = call fp128 @protected_phi(i1 false, fp128 %a, fp128 %b)
  %fe3 = call i32 @fold_fp128(fp128 %e3)
  %fp3 = call i32 @fold_fp128(fp128 %p3)
  %ok3 = icmp eq i32 %fe3, %fp3
  %e4 = call fp128 @reference_loop(fp128 %a, i32 3)
  %p4 = call fp128 @protected_loop(fp128 %a, i32 3)
  %fe4 = call i32 @fold_fp128(fp128 %e4)
  %fp4 = call i32 @fold_fp128(fp128 %p4)
  %ok4 = icmp eq i32 %fe4, %fp4
  %e5 = call fp128 @reference_mem(fp128 %a)
  %p5 = call fp128 @protected_mem(fp128 %a)
  %fe5 = call i32 @fold_fp128(fp128 %e5)
  %fp5 = call i32 @fold_fp128(fp128 %p5)
  %ok5 = icmp eq i32 %fe5, %fp5
  %e6 = call fp128 @reference_const()
  %p6 = call fp128 @protected_const()
  %fe6 = call i32 @fold_fp128(fp128 %e6)
  %fp6 = call i32 @fold_fp128(fp128 %p6)
  %ok6 = icmp eq i32 %fe6, %fp6
  %e7 = call fp128 @reference_conv(i32 7, double 1.250000e+00, float 0x3FF0000000000000, half 0xH4000)
  %p7 = call fp128 @protected_conv(i32 7, double 1.250000e+00, float 0x3FF0000000000000, half 0xH4000)
  %fe7 = call i32 @fold_fp128(fp128 %e7)
  %fp7 = call i32 @fold_fp128(fp128 %p7)
  %ok7 = icmp eq i32 %fe7, %fp7
  %one = fpext double 3.000000e+00 to fp128
  %e8 = call i32 @reference_trunc(fp128 %one)
  %p8 = call i32 @protected_trunc(fp128 %one)
  %ok8 = icmp eq i32 %e8, %p8
  %pr = call fp128 @protected_ret(fp128 %a)
  %fr = call i32 @fold_fp128(fp128 %pr)
  %fa = call i32 @fold_fp128(fp128 %a)
  %ok9 = icmp eq i32 %fr, %fa
  %t0 = and i1 %ok0, %ok1
  %t1 = and i1 %t0, %ok2
  %t2 = and i1 %t1, %ok3
  %t3 = and i1 %t2, %ok4
  %t4 = and i1 %t3, %ok5
  %t5 = and i1 %t4, %ok6
  %t6 = and i1 %t5, %ok7
  %t7 = and i1 %t6, %ok8
  %ok = and i1 %t7, %ok9
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_vector: unsupported
; SKIP-DAG: Skipping VMP on unsupported_agg: unsupported
; SKIP-DAG: Skipping VMP on unsupported_atomic: unsupported float load instruction
; SKIP-DAG: Skipping VMP on unsupported_lround: unsupported call
; SKIP-DAG: Skipping VMP on unsupported_constrained: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_direct_call: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_indirect: indirect call
; SKIP-DAG: Skipping VMP on unsupported_bitcast: unsupported cast instruction
; SKIP-DAG: Skipping VMP on unsupported_ppc: unsupported
; SKIP-DAG: Skipping VMP on unsupported_poison_add: unsupported float fadd instruction
; SKIP-NOT: Skipping VMP on protected_arith:
; SKIP-NOT: Skipping VMP on protected_fmf:
; SKIP-NOT: Skipping VMP on protected_cmp:
; SKIP-NOT: Skipping VMP on protected_select:
; SKIP-NOT: Skipping VMP on protected_phi:
; SKIP-NOT: Skipping VMP on protected_loop:
; SKIP-NOT: Skipping VMP on protected_mem:
; SKIP-NOT: Skipping VMP on protected_const:
; SKIP-NOT: Skipping VMP on protected_conv:
; SKIP-NOT: Skipping VMP on protected_trunc:
; SKIP-NOT: Skipping VMP on protected_freeze:
; SKIP-NOT: Skipping VMP on protected_ret:

; VIRT: define fp128 @protected_arith({{.*}} #[[PROT:[0-9]+]] {
; VIRT: %vmp.fp128.regs = alloca [{{[0-9]+}} x fp128]
; VIRT: vmp.dispatch:
; Typed fp128 ops on the dedicated frame; not i128 integer arithmetic.
; VIRT-NOT: fadd i128
; VIRT-DAG: fadd fp128
; VIRT-DAG: fsub fp128
; VIRT-DAG: fmul fp128
; VIRT-DAG: fdiv fp128
; VIRT-DAG: frem fp128
; VIRT-DAG: fneg fp128
; VIRT: define fp128 @protected_fmf({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: fadd nnan nsz fp128
; VIRT: define i32 @protected_cmp({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: fcmp ogt fp128
; VIRT-DAG: fcmp olt fp128
; VIRT-DAG: fcmp oeq fp128
; VIRT-DAG: fcmp une fp128
; VIRT-DAG: fcmp ugt fp128
; VIRT: define fp128 @protected_select({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: select i1 {{.*}}, fp128
; VIRT: define fp128 @protected_phi({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define fp128 @protected_loop({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: fadd fp128
; VIRT: define fp128 @protected_mem({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: load fp128
; VIRT-DAG: store fp128
; VIRT: define fp128 @protected_const({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define fp128 @protected_conv({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: sitofp {{.*}} to fp128
; VIRT-DAG: uitofp {{.*}} to fp128
; VIRT-DAG: fpext double {{.*}} to fp128
; VIRT-DAG: fpext float {{.*}} to fp128
; VIRT-DAG: fpext half {{.*}} to fp128
; VIRT: define i32 @protected_trunc({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: fptosi fp128
; VIRT-DAG: fptoui fp128
; VIRT-DAG: fptrunc fp128 {{.*}} to double
; VIRT: define fp128 @protected_freeze({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: freeze fp128
; VIRT: define fp128 @protected_freeze_undef({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: freeze fp128 undef
; VIRT: define fp128 @protected_freeze_poison({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: freeze fp128 poison
; VIRT: define fp128 @protected_ret({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define {{.*}} @unsupported_vector({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_agg({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_atomic({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_lround({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_constrained({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_direct_call({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_indirect({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_bitcast({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ppc({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_poison_add({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
