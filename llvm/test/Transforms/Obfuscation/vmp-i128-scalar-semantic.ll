; Restricted scalar i128: independent i128 integer VReg frame (not the
; i64 integer slots, not the vector/aggregate i128 frames).  Covers
; arith/bitwise/shifts with nuw/nsw/exact, icmp, select, phi (diamond
; and loop-carried), freeze, trunc/zext/sext, non-atomic AS0 load/store,
; args/returns, a virtualized i128-returning callee, and a direct C
; i128 call.  Atomics, insertvalue/whole-pair *with.overflow, va_arg, switch, GEP i128 index,
; dyn-alloca i128 count/element, i128 ptrtoint/inttoptr, variadic
; named i128, indirect i128, non-C (fastcc) i128 call sites or callees,
; vector/aggregate i128, and non-bit integer intrinsics stay rejected.
; Pure bit i128 intrinsics live in vmp-i128-bit-intrinsic-semantic.ll.
; Same-operand i128 rotate lives in vmp-i128-rotate-semantic.ll.
; Extractvalue i128 *with.overflow lives in vmp-i128-overflow-semantic.ll.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.ll > %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.live.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.ll > %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.live.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.s7.ll > %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.s7.live.ll > %t.o0.s7.host.ll
; RUN: lli -force-interpreter %t.o0.s7.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.s7.ll > %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.s7.live.ll > %t.o2.s7.host.ll
; RUN: lli -force-interpreter %t.o2.s7.host.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare void @llvm.va_start(ptr)
declare void @llvm.va_end(ptr)
declare i128 @llvm.fshl.i128(i128, i128, i128)
declare i32 @named_i128_var(i128, ...)

@g.i128 = private global i128 0, align 16

define i128 @mix_i128(i128 %a, i128 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %s = add i128 %a, %b
  ret i128 %s
}

define i32 @reference_work(i128 %a, i128 %b, i1 %c) noinline optnone {
entry:
  %stk = alloca i128, align 16
  %sum = add nuw nsw i128 %a, %b
  %dif = sub i128 %sum, %a
  %prod = mul i128 %dif, %b
  %band = and i128 %prod, %a
  %bor = or i128 %band, %b
  %bxor = xor i128 %bor, %a
  %sh = shl nuw i128 %bxor, 1
  %fr = freeze i128 %sh
  store i128 %fr, ptr %stk, align 16
  %ld = load i128, ptr %stk, align 16
  store i128 %ld, ptr @g.i128, align 16
  %gld = load i128, ptr @g.i128, align 16
  %gt = icmp ugt i128 %gld, %a
  %sel = select i1 %gt, i128 %gld, i128 %a
  br i1 %c, label %left, label %right

left:
  %lp = add i128 %sel, 1
  br label %join

right:
  %rp = add i128 %sel, 2
  br label %join

join:
  %phi = phi i128 [ %lp, %left ], [ %rp, %right ]
  %called = call i128 @mix_i128(i128 %phi, i128 %b)
  %narrow = trunc i128 %called to i64
  %wide = zext i64 %narrow to i128
  %back = trunc i128 %wide to i32
  %hi64 = lshr i128 %called, 32
  %hi = trunc i128 %hi64 to i32
  %out = xor i32 %back, %hi
  ret i32 %out
}

define i32 @protected_work(i128 %a, i128 %b, i1 %c) noinline optnone {
entry:
  call void @hikari_vmp()
  %stk = alloca i128, align 16
  %sum = add nuw nsw i128 %a, %b
  %dif = sub i128 %sum, %a
  %prod = mul i128 %dif, %b
  %band = and i128 %prod, %a
  %bor = or i128 %band, %b
  %bxor = xor i128 %bor, %a
  %sh = shl nuw i128 %bxor, 1
  %fr = freeze i128 %sh
  store i128 %fr, ptr %stk, align 16
  %ld = load i128, ptr %stk, align 16
  store i128 %ld, ptr @g.i128, align 16
  %gld = load i128, ptr @g.i128, align 16
  %gt = icmp ugt i128 %gld, %a
  %sel = select i1 %gt, i128 %gld, i128 %a
  br i1 %c, label %left, label %right

left:
  %lp = add i128 %sel, 1
  br label %join

right:
  %rp = add i128 %sel, 2
  br label %join

join:
  %phi = phi i128 [ %lp, %left ], [ %rp, %right ]
  %called = call i128 @mix_i128(i128 %phi, i128 %b)
  %narrow = trunc i128 %called to i64
  %wide = zext i64 %narrow to i128
  %back = trunc i128 %wide to i32
  %hi64 = lshr i128 %called, 32
  %hi = trunc i128 %hi64 to i32
  %out = xor i32 %back, %hi
  ret i32 %out
}

; Declared accept-list ops that the first work pair does not exercise:
; udiv/sdiv/urem/srem/exact, ashr, sext.  i128 ptrtoint/inttoptr stay out.
define i32 @reference_extra(i128 %a, i128 %b) noinline optnone {
entry:
  %stk = alloca i128, align 16
  %n32 = trunc i128 %a to i32
  %sx = sext i32 %n32 to i128
  %ash = ashr i128 %sx, 1
  %dbl = shl i128 %b, 1
  %qex = udiv exact i128 %dbl, 2
  %q = udiv i128 %a, %b
  %r = urem i128 %a, %b
  %sq = sdiv i128 %sx, %b
  %sr = srem i128 %sx, %b
  store i128 %sx, ptr %stk, align 16
  %ld = load i128, ptr %stk, align 16
  %t0 = xor i128 %q, %r
  %t1 = xor i128 %t0, %sq
  %t2 = xor i128 %t1, %sr
  %t3 = xor i128 %t2, %ash
  %t4 = xor i128 %t3, %qex
  %t5 = xor i128 %t4, %ld
  %out = trunc i128 %t5 to i32
  ret i32 %out
}

define i32 @protected_extra(i128 %a, i128 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %stk = alloca i128, align 16
  %n32 = trunc i128 %a to i32
  %sx = sext i32 %n32 to i128
  %ash = ashr i128 %sx, 1
  %dbl = shl i128 %b, 1
  %qex = udiv exact i128 %dbl, 2
  %q = udiv i128 %a, %b
  %r = urem i128 %a, %b
  %sq = sdiv i128 %sx, %b
  %sr = srem i128 %sx, %b
  store i128 %sx, ptr %stk, align 16
  %ld = load i128, ptr %stk, align 16
  %t0 = xor i128 %q, %r
  %t1 = xor i128 %t0, %sq
  %t2 = xor i128 %t1, %sr
  %t3 = xor i128 %t2, %ash
  %t4 = xor i128 %t3, %qex
  %t5 = xor i128 %t4, %ld
  %out = trunc i128 %t5 to i32
  ret i32 %out
}

; Loop-carried i128 phi: already inside the accepted phi surface; this
; pair only checks the backedge and zero-trip exit Move paths against
; a native reference.  n==0 skips the body and takes %start at done.
define i32 @reference_loop(i128 %start, i128 %step, i32 %n) noinline optnone {
entry:
  %go = icmp ne i32 %n, 0
  br i1 %go, label %loop, label %done

loop:
  %acc = phi i128 [ %start, %entry ], [ %acc.next, %loop ]
  %i = phi i32 [ 0, %entry ], [ %i.next, %loop ]
  %sum = add i128 %acc, %step
  %acc.next = xor i128 %sum, %acc
  %i.next = add i32 %i, 1
  %more = icmp ult i32 %i.next, %n
  br i1 %more, label %loop, label %done

done:
  %acc.fin = phi i128 [ %start, %entry ], [ %acc.next, %loop ]
  %lo = trunc i128 %acc.fin to i32
  %hi64 = lshr i128 %acc.fin, 32
  %hi = trunc i128 %hi64 to i32
  %out = xor i32 %lo, %hi
  ret i32 %out
}

define i32 @protected_loop(i128 %start, i128 %step, i32 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  %go = icmp ne i32 %n, 0
  br i1 %go, label %loop, label %done

loop:
  %acc = phi i128 [ %start, %entry ], [ %acc.next, %loop ]
  %i = phi i32 [ 0, %entry ], [ %i.next, %loop ]
  %sum = add i128 %acc, %step
  %acc.next = xor i128 %sum, %acc
  %i.next = add i32 %i, 1
  %more = icmp ult i32 %i.next, %n
  br i1 %more, label %loop, label %done

done:
  %acc.fin = phi i128 [ %start, %entry ], [ %acc.next, %loop ]
  %lo = trunc i128 %acc.fin to i32
  %hi64 = lshr i128 %acc.fin, 32
  %hi = trunc i128 %hi64 to i32
  %out = xor i32 %lo, %hi
  ret i32 %out
}

define i128 @unsupported_atomic_i128(ptr %p, i128 %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = atomicrmw xchg ptr %p, i128 %v monotonic
  ret i128 %r
}

define i128 @unsupported_atomic_load_i128(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = load atomic i128, ptr %p monotonic, align 16
  ret i128 %r
}

define void @unsupported_atomic_store_i128(ptr %p, i128 %v) noinline optnone {
entry:
  call void @hikari_vmp()
  store atomic i128 %v, ptr %p monotonic, align 16
  ret void
}

define i128 @unsupported_cmpxchg_i128(ptr %p, i128 %c, i128 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  %pair = cmpxchg ptr %p, i128 %c, i128 %n monotonic monotonic
  %r = extractvalue { i128, i1 } %pair, 0
  ret i128 %r
}

define i32 @unsupported_switch_i128(i128 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  switch i128 %n, label %other [
    i128 0, label %z
    i128 1, label %o
  ]

z:
  ret i32 0

o:
  ret i32 1

other:
  ret i32 2
}

define i128 @unsupported_vaarg_i128(i32 %n, ...) noinline optnone {
entry:
  call void @hikari_vmp()
  %ap = alloca { i32, i32, ptr, ptr }, align 8
  call void @llvm.va_start(ptr %ap)
  %v = va_arg ptr %ap, i128
  call void @llvm.va_end(ptr %ap)
  ret i128 %v
}

define ptr @unsupported_gep_i128(ptr %p, i128 %i) noinline optnone {
entry:
  call void @hikari_vmp()
  %q = getelementptr i32, ptr %p, i128 %i
  ret ptr %q
}

define i128 @unsupported_ptrtoint_i128(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %v = ptrtoint ptr %p to i128
  ret i128 %v
}

define ptr @unsupported_inttoptr_i128(i128 %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %p = inttoptr i128 %v to ptr
  ret ptr %p
}

define ptr @unsupported_dyn_alloca_i128_count(i128 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  %p = alloca i32, i128 %n, align 4
  ret ptr %p
}

define ptr @unsupported_dyn_alloca_i128_elem(i64 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  %p = alloca i128, i64 %n, align 16
  ret ptr %p
}

define i32 @unsupported_i128_vector(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %a = load <1 x i128>, ptr %p, align 16
  %r = add <1 x i128> %a, %a
  store <1 x i128> %r, ptr %p, align 16
  ret i32 0
}

define i32 @unsupported_i128_aggregate(i128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %s = insertvalue { i128 } undef, i128 %a, 0
  %e = extractvalue { i128 } %s, 0
  %t = trunc i128 %e to i32
  ret i32 %t
}

define i128 @unsupported_i128_fshl(i128 %a, i128 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i128 @llvm.fshl.i128(i128 %a, i128 %b, i128 3)
  ret i128 %r
}

define i32 @unsupported_variadic_named_i128(i128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 (i128, ...) @named_i128_var(i128 %a, i32 1)
  ret i32 %r
}

define i128 @unsupported_indirect_i128(ptr %f, i128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i128 %f(i128 %a)
  ret i128 %r
}

define fastcc i128 @sink_fastcc_i128(i128 %a) noinline {
entry:
  ret i128 %a
}

define i32 @unsupported_i128_fastcc(i128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc i128 @sink_fastcc_i128(i128 %a)
  %t = trunc i128 %r to i32
  ret i32 %t
}

; Call site is C; callee Function is fastcc — both sides must be C.
define i32 @unsupported_i128_fastcc_callee(i128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i128 @sink_fastcc_i128(i128 %a)
  %t = trunc i128 %r to i32
  ret i32 %t
}

define i32 @main() {
entry:
  %e0 = call i32 @reference_work(i128 1, i128 2, i1 false)
  %a0 = call i32 @protected_work(i128 1, i128 2, i1 false)
  %ok0 = icmp eq i32 %e0, %a0
  %e1 = call i32 @reference_work(i128 7, i128 9, i1 true)
  %a1 = call i32 @protected_work(i128 7, i128 9, i1 true)
  %ok1 = icmp eq i32 %e1, %a1
  %e2 = call i32 @reference_work(i128 4294967296, i128 3, i1 false)
  %a2 = call i32 @protected_work(i128 4294967296, i128 3, i1 false)
  %ok2 = icmp eq i32 %e2, %a2
  %e3 = call i32 @reference_extra(i128 20, i128 3)
  %a3 = call i32 @protected_extra(i128 20, i128 3)
  %ok3 = icmp eq i32 %e3, %a3
  %e4 = call i32 @reference_extra(i128 -20, i128 3)
  %a4 = call i32 @protected_extra(i128 -20, i128 3)
  %ok4 = icmp eq i32 %e4, %a4
  %e5 = call i32 @reference_extra(i128 4294967296, i128 5)
  %a5 = call i32 @protected_extra(i128 4294967296, i128 5)
  %ok5 = icmp eq i32 %e5, %a5
  %e6 = call i32 @reference_loop(i128 1, i128 2, i32 4)
  %a6 = call i32 @protected_loop(i128 1, i128 2, i32 4)
  %ok6 = icmp eq i32 %e6, %a6
  %e7 = call i32 @reference_loop(i128 4294967296, i128 3, i32 5)
  %a7 = call i32 @protected_loop(i128 4294967296, i128 3, i32 5)
  %ok7 = icmp eq i32 %e7, %a7
  %e8 = call i32 @reference_loop(i128 -7, i128 9, i32 1)
  %a8 = call i32 @protected_loop(i128 -7, i128 9, i32 1)
  %ok8 = icmp eq i32 %e8, %a8
  %e9 = call i32 @reference_loop(i128 4294967296, i128 11, i32 0)
  %a9 = call i32 @protected_loop(i128 4294967296, i128 11, i32 0)
  %ok9 = icmp eq i32 %e9, %a9
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

; SKIP-DAG: Skipping VMP on unsupported_atomic_i128: unsupported atomicrmw instruction
; SKIP-DAG: Skipping VMP on unsupported_atomic_load_i128: unsupported load instruction
; SKIP-DAG: Skipping VMP on unsupported_atomic_store_i128: unsupported store instruction
; SKIP-DAG: Skipping VMP on unsupported_cmpxchg_i128: unsupported cmpxchg instruction
; SKIP-DAG: Skipping VMP on unsupported_switch_i128: unsupported switch condition
; SKIP-DAG: Skipping VMP on unsupported_vaarg_i128: unsupported va_arg instruction
; SKIP-DAG: Skipping VMP on unsupported_gep_i128: unsupported getelementptr index
; SKIP-DAG: Skipping VMP on unsupported_ptrtoint_i128: unsupported cast instruction
; SKIP-DAG: Skipping VMP on unsupported_inttoptr_i128: unsupported cast instruction
; SKIP-DAG: Skipping VMP on unsupported_dyn_alloca_i128_count: unsupported stack allocation
; SKIP-DAG: Skipping VMP on unsupported_dyn_alloca_i128_elem: unsupported stack allocation
; SKIP-DAG: Skipping VMP on unsupported_i128_vector: unsupported vector load instruction
; SKIP-DAG: Skipping VMP on unsupported_i128_aggregate: unsupported aggregate instruction
; SKIP-DAG: Skipping VMP on unsupported_i128_fshl: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_variadic_named_i128: unsupported call argument
; SKIP-DAG: Skipping VMP on unsupported_indirect_i128: indirect call
; SKIP-DAG: Skipping VMP on unsupported_i128_fastcc: unsupported call return type
; SKIP-DAG: Skipping VMP on unsupported_i128_fastcc_callee: unsupported call return type
; SKIP-NOT: Skipping VMP on protected_work:
; SKIP-NOT: Skipping VMP on protected_extra:
; SKIP-NOT: Skipping VMP on protected_loop:
; SKIP-NOT: Skipping VMP on reference_work:
; SKIP-NOT: Skipping VMP on reference_extra:
; SKIP-NOT: Skipping VMP on reference_loop:
; SKIP-NOT: Skipping VMP on mix_i128:

; VIRT: define i128 @mix_i128(
; VIRT: %vmp.i128.regs = alloca
; VIRT: vmp.dispatch:
; VIRT: add i128
; VIRT-LABEL: define i32 @protected_work(
; VIRT: %vmp.i128.regs = alloca
; VIRT: vmp.dispatch:
; VIRT: add nuw nsw i128
; VIRT-LABEL: define i32 @protected_extra(
; VIRT: %vmp.i128.regs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: sdiv i128
; VIRT-DAG: ashr i128
; VIRT-DAG: sext i32
; VIRT-LABEL: define i32 @reference_loop(
; VIRT: phi i128
; VIRT-LABEL: define i32 @protected_loop(
; VIRT: %vmp.i128.regs = alloca
; VIRT: vmp.dispatch:
; VIRT-NOT: phi i128
; VIRT: define i128 @unsupported_atomic_i128({{.*}} #[[UNSUPATTR:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_atomic_load_i128({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_atomic_store_i128({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cmpxchg_i128({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_switch_i128({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_vaarg_i128({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_gep_i128({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ptrtoint_i128({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_inttoptr_i128({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_dyn_alloca_i128_count({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_dyn_alloca_i128_elem({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_i128_vector({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_i128_aggregate({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_i128_fshl({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_variadic_named_i128({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_indirect_i128({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_i128_fastcc({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_i128_fastcc_callee({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #{{[0-9]+}} = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.virtualized"
