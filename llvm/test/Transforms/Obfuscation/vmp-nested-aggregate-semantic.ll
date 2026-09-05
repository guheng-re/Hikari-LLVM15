; Restricted one-level nested aggregates on the [4 x i128] 64-byte
; aggregate slot.  A top-level field may be a leaf aggregate
; ({i32,i32}, [2 x i32], {half,half}, …); that leaf may not itself
; contain an aggregate.  insertvalue/extractvalue allow 1 or 2 indices.
; load/store/select/phi, ordinary direct C args/returns, and restricted
; indirect C replay reuse the existing aggregate frame.  Two-or-more
; level nests (including { [2 x {i32,i32}], i32 } and [2 x nest]),
; 2-index paths that would enter a second nest, 3+ indices,
; leftover-width vector fields, 9+ fields,
; >64-byte layouts, reserved NEON tuples, and i128 fields stay rejected.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP-O0 < %t.o0.err
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
; RUN: FileCheck %s --check-prefix=SKIP-O0 < %t.o0.s7.err
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

%pair = type { i32, i32 }
%nest = type { %pair, i32 }
%arrpair = type [2 x %pair]
%arrfield = type { [2 x i32], i32 }
%deep = type { %nest, i32 }
%midarr = type { [2 x %pair], i32 }
%arrnest = type [2 x %nest]
%leftover = type { <3 x i32> }
%i128field = type { i128 }
%hugefield = type { [8 x i64], i32 }

declare void @hikari_vmp()
declare { <8 x i8>, <8 x i8> } @llvm.aarch64.neon.ld1x2.v8i8.p0(ptr)

@slot.nest = private global %nest zeroinitializer, align 4
@slot.arrpair = private global %arrpair zeroinitializer, align 4
@slot.arrfield = private global %arrfield zeroinitializer, align 4

define i32 @fold_pair(%pair %p) {
entry:
  %a = extractvalue %pair %p, 0
  %b = extractvalue %pair %p, 1
  %r = xor i32 %a, %b
  ret i32 %r
}

define i32 @fold_nest(%nest %n) {
entry:
  %p = extractvalue %nest %n, 0
  %k = extractvalue %nest %n, 1
  %s = call i32 @fold_pair(%pair %p)
  %r = xor i32 %s, %k
  ret i32 %r
}

define %pair @swap_pair(%pair %p) noinline {
entry:
  %a = extractvalue %pair %p, 0
  %b = extractvalue %pair %p, 1
  %q0 = insertvalue %pair poison, i32 %b, 0
  %q1 = insertvalue %pair %q0, i32 %a, 1
  ret %pair %q1
}

define %nest @swap_nest(%nest %n) noinline {
entry:
  %p = extractvalue %nest %n, 0
  %s = call %pair @swap_pair(%pair %p)
  %r = insertvalue %nest %n, %pair %s, 0
  ret %nest %r
}

define %nest @make_nest(i32 %a, i32 %b, i32 %k) {
entry:
  %p0 = insertvalue %pair poison, i32 %a, 0
  %p1 = insertvalue %pair %p0, i32 %b, 1
  %n0 = insertvalue %nest poison, %pair %p1, 0
  %n1 = insertvalue %nest %n0, i32 %k, 1
  ret %nest %n1
}

; ----- { {i32,i32}, i32 }: select / diamond join / load / store / 2-index -----

define i32 @reference_nest(i32 %a, i32 %b, i32 %k, i1 %c) noinline optnone {
entry:
  %p0 = insertvalue %pair poison, i32 %a, 0
  %p1 = insertvalue %pair %p0, i32 %b, 1
  %n0 = insertvalue %nest poison, %pair %p1, 0
  %n1 = insertvalue %nest %n0, i32 %k, 1
  %n2 = insertvalue %nest %n1, i32 7, 0, 1
  %inner = extractvalue %nest %n2, 0, 0
  %alt = insertvalue %nest zeroinitializer, i32 %a, 1
  %sel = select i1 %c, %nest %n2, %nest %alt
  br i1 %c, label %left, label %right

left:
  %lp = insertvalue %nest %sel, i32 9, 1
  br label %join

right:
  %rp = insertvalue %nest %sel, i32 11, 1
  br label %join

join:
  %phi = phi %nest [ %lp, %left ], [ %rp, %right ]
  store %nest %phi, ptr @slot.nest, align 4
  %ld = load %nest, ptr @slot.nest, align 4
  %sw = call %nest @swap_nest(%nest %ld)
  %s0 = call i32 @fold_nest(%nest %ld)
  %s1 = call i32 @fold_nest(%nest %sw)
  %e1 = extractvalue %nest %phi, 1
  %x0 = xor i32 %s0, %s1
  %x1 = xor i32 %e1, %inner
  %out = xor i32 %x0, %x1
  ret i32 %out
}

define i32 @protected_nest(i32 %a, i32 %b, i32 %k, i1 %c) noinline optnone {
entry:
  call void @hikari_vmp()
  %p0 = insertvalue %pair poison, i32 %a, 0
  %p1 = insertvalue %pair %p0, i32 %b, 1
  %n0 = insertvalue %nest poison, %pair %p1, 0
  %n1 = insertvalue %nest %n0, i32 %k, 1
  %n2 = insertvalue %nest %n1, i32 7, 0, 1
  %inner = extractvalue %nest %n2, 0, 0
  %alt = insertvalue %nest zeroinitializer, i32 %a, 1
  %sel = select i1 %c, %nest %n2, %nest %alt
  br i1 %c, label %left, label %right

left:
  %lp = insertvalue %nest %sel, i32 9, 1
  br label %join

right:
  %rp = insertvalue %nest %sel, i32 11, 1
  br label %join

join:
  %phi = phi %nest [ %lp, %left ], [ %rp, %right ]
  store %nest %phi, ptr @slot.nest, align 4
  %ld = load %nest, ptr @slot.nest, align 4
  %sw = call %nest @swap_nest(%nest %ld)
  %s0 = call i32 @fold_nest(%nest %ld)
  %s1 = call i32 @fold_nest(%nest %sw)
  %e1 = extractvalue %nest %phi, 1
  %x0 = xor i32 %s0, %s1
  %x1 = xor i32 %e1, %inner
  %out = xor i32 %x0, %x1
  ret i32 %out
}

; ----- [2 x {i32,i32}] -----

define i32 @reference_arrpair(i32 %a, i32 %b) noinline optnone {
entry:
  %p0 = insertvalue %pair poison, i32 %a, 0
  %p1 = insertvalue %pair %p0, i32 %b, 1
  %q0 = insertvalue %pair poison, i32 %b, 0
  %q1 = insertvalue %pair %q0, i32 %a, 1
  %a0 = insertvalue [2 x %pair] poison, %pair %p1, 0
  %a1 = insertvalue [2 x %pair] %a0, %pair %q1, 1
  store [2 x %pair] %a1, ptr @slot.arrpair, align 4
  %ld = load [2 x %pair], ptr @slot.arrpair, align 4
  %e0 = extractvalue [2 x %pair] %ld, 0
  %e1 = extractvalue [2 x %pair] %ld, 1
  %s0 = call i32 @fold_pair(%pair %e0)
  %s1 = call i32 @fold_pair(%pair %e1)
  %r = xor i32 %s0, %s1
  ret i32 %r
}

define i32 @protected_arrpair(i32 %a, i32 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %p0 = insertvalue %pair poison, i32 %a, 0
  %p1 = insertvalue %pair %p0, i32 %b, 1
  %q0 = insertvalue %pair poison, i32 %b, 0
  %q1 = insertvalue %pair %q0, i32 %a, 1
  %a0 = insertvalue [2 x %pair] poison, %pair %p1, 0
  %a1 = insertvalue [2 x %pair] %a0, %pair %q1, 1
  store [2 x %pair] %a1, ptr @slot.arrpair, align 4
  %ld = load [2 x %pair], ptr @slot.arrpair, align 4
  %e0 = extractvalue [2 x %pair] %ld, 0
  %e1 = extractvalue [2 x %pair] %ld, 1
  %s0 = call i32 @fold_pair(%pair %e0)
  %s1 = call i32 @fold_pair(%pair %e1)
  %r = xor i32 %s0, %s1
  ret i32 %r
}

; ----- { [2 x i32], i32 } -----

define i32 @reference_arrfield(i32 %a, i32 %b) noinline optnone {
entry:
  %v0 = insertvalue [2 x i32] poison, i32 %a, 0
  %v1 = insertvalue [2 x i32] %v0, i32 %b, 1
  %p0 = insertvalue %arrfield poison, [2 x i32] %v1, 0
  %p1 = insertvalue %arrfield %p0, i32 5, 1
  store %arrfield %p1, ptr @slot.arrfield, align 4
  %ld = load %arrfield, ptr @slot.arrfield, align 4
  %inner = extractvalue %arrfield %ld, 0, 1
  %k = extractvalue %arrfield %ld, 1
  %r = xor i32 %inner, %k
  ret i32 %r
}

define i32 @protected_arrfield(i32 %a, i32 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %v0 = insertvalue [2 x i32] poison, i32 %a, 0
  %v1 = insertvalue [2 x i32] %v0, i32 %b, 1
  %p0 = insertvalue %arrfield poison, [2 x i32] %v1, 0
  %p1 = insertvalue %arrfield %p0, i32 5, 1
  store %arrfield %p1, ptr @slot.arrfield, align 4
  %ld = load %arrfield, ptr @slot.arrfield, align 4
  %inner = extractvalue %arrfield %ld, 0, 1
  %k = extractvalue %arrfield %ld, 1
  %r = xor i32 %inner, %k
  ret i32 %r
}

; ----- nest return and restricted indirect C -----

define %nest @reference_ret_nest(i32 %a, i32 %b, i32 %k) noinline optnone {
entry:
  %r = call %nest @make_nest(i32 %a, i32 %b, i32 %k)
  ret %nest %r
}

define %nest @protected_ret_nest(i32 %a, i32 %b, i32 %k) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call %nest @make_nest(i32 %a, i32 %b, i32 %k)
  ret %nest %r
}

define %nest @reference_indirect(ptr %fp, %nest %n) noinline optnone {
entry:
  %r = call %nest %fp(%nest %n)
  ret %nest %r
}

define %nest @protected_indirect(ptr %fp, %nest %n) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call %nest %fp(%nest %n)
  ret %nest %r
}

; ----- back-edge loop phi on { {i32,i32}, i32 } (not a diamond join) -----

define i32 @reference_loopphi_nest(i32 %n) noinline optnone {
entry:
  %init = insertvalue %nest zeroinitializer, i32 %n, 1
  br label %loop

loop:
  %acc = phi %nest [ %init, %entry ], [ %next, %loop ]
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %cur = extractvalue %nest %acc, 1
  %inc = add i32 %cur, 1
  %next = insertvalue %nest %acc, i32 %inc, 1
  %i1 = add i32 %i, 1
  %c = icmp slt i32 %i1, 3
  br i1 %c, label %loop, label %done

done:
  %r = call i32 @fold_nest(%nest %next)
  ret i32 %r
}

define i32 @protected_loopphi_nest(i32 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  %init = insertvalue %nest zeroinitializer, i32 %n, 1
  br label %loop

loop:
  %acc = phi %nest [ %init, %entry ], [ %next, %loop ]
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %cur = extractvalue %nest %acc, 1
  %inc = add i32 %cur, 1
  %next = insertvalue %nest %acc, i32 %inc, 1
  %i1 = add i32 %i, 1
  %c = icmp slt i32 %i1, 3
  br i1 %c, label %loop, label %done

done:
  %r = call i32 @fold_nest(%nest %next)
  ret i32 %r
}

; ----- negatives: two-level nest and other existing rejects stay closed -----

define i32 @unsupported_agg_deep(i32 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %n = insertvalue %deep poison, i32 %a, 1
  %e = extractvalue %deep %n, 1
  ret i32 %e
}

; Two-level: struct of (array of struct).
define i32 @unsupported_agg_midarr(i32 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %n = insertvalue %midarr poison, i32 %a, 1
  %e = extractvalue %midarr %n, 1
  ret i32 %e
}

; Two-level: array of one-level nest.
define i32 @unsupported_agg_arrnest(i32 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %n = insertvalue [2 x %nest] poison, i32 %a, 0, 1
  %e = extractvalue [2 x %nest] %n, 0, 1
  ret i32 %e
}

; Two-index path into a two-level type (first index is itself a nest).
define i32 @unsupported_agg_deep_two_indices(i32 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %n = insertvalue %deep poison, i32 %a, 0, 1
  %e = extractvalue %deep %n, 0, 1
  ret i32 %e
}

define i32 @unsupported_agg_three_indices(i32 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %n = insertvalue %deep poison, i32 %a, 0, 0, 0
  %e = extractvalue %deep %n, 0, 0, 0
  ret i32 %e
}

define i32 @unsupported_agg_leftover(<3 x i32> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %n = insertvalue %leftover poison, <3 x i32> %v, 0
  %e = extractvalue %leftover %n, 0
  %t = extractelement <3 x i32> %e, i32 0
  ret i32 %t
}

define i32 @unsupported_agg_i128(i128 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %n = insertvalue %i128field poison, i128 %x, 0
  %e = extractvalue %i128field %n, 0
  %t = trunc i128 %e to i32
  ret i32 %t
}

define i32 @unsupported_agg_huge(i32 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %n = insertvalue %hugefield poison, i32 %a, 1
  %e = extractvalue %hugefield %n, 1
  ret i32 %e
}

define void @unsupported_neon_ld2_store_tuple(ptr %p, ptr %q) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <8 x i8>, <8 x i8> } @llvm.aarch64.neon.ld1x2.v8i8.p0(ptr %p)
  store { <8 x i8>, <8 x i8> } %t, ptr %q, align 8
  ret void
}

define i32 @main() {
entry:
  %e0 = call i32 @reference_nest(i32 1, i32 2, i32 3, i1 true)
  %a0 = call i32 @protected_nest(i32 1, i32 2, i32 3, i1 true)
  %ok0 = icmp eq i32 %e0, %a0
  %e1 = call i32 @reference_nest(i32 4, i32 5, i32 6, i1 false)
  %a1 = call i32 @protected_nest(i32 4, i32 5, i32 6, i1 false)
  %ok1 = icmp eq i32 %e1, %a1
  %e2 = call i32 @reference_arrpair(i32 7, i32 8)
  %a2 = call i32 @protected_arrpair(i32 7, i32 8)
  %ok2 = icmp eq i32 %e2, %a2
  %e3 = call i32 @reference_arrfield(i32 9, i32 10)
  %a3 = call i32 @protected_arrfield(i32 9, i32 10)
  %ok3 = icmp eq i32 %e3, %a3
  %er = call %nest @reference_ret_nest(i32 1, i32 2, i32 3)
  %ar = call %nest @protected_ret_nest(i32 1, i32 2, i32 3)
  %fr = call i32 @fold_nest(%nest %er)
  %fa = call i32 @fold_nest(%nest %ar)
  %ok4 = icmp eq i32 %fr, %fa
  %seed = call %nest @make_nest(i32 3, i32 4, i32 5)
  %ei = call %nest @reference_indirect(ptr @swap_nest, %nest %seed)
  %ai = call %nest @protected_indirect(ptr @swap_nest, %nest %seed)
  %fi = call i32 @fold_nest(%nest %ei)
  %fj = call i32 @fold_nest(%nest %ai)
  %ok5 = icmp eq i32 %fi, %fj
  %el = call i32 @reference_loopphi_nest(i32 10)
  %al = call i32 @protected_loopphi_nest(i32 10)
  %ok6 = icmp eq i32 %el, %al
  %t0 = and i1 %ok0, %ok1
  %t1 = and i1 %ok2, %ok3
  %t2 = and i1 %ok4, %ok5
  %u0 = and i1 %t0, %t1
  %u1 = and i1 %t2, %ok6
  %ok = and i1 %u0, %u1
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP-DAG: Skipping VMP on unsupported_agg_deep: unsupported aggregate instruction
; SKIP-DAG: Skipping VMP on unsupported_agg_midarr: unsupported aggregate instruction
; SKIP-DAG: Skipping VMP on unsupported_agg_arrnest: unsupported aggregate instruction
; SKIP-DAG: Skipping VMP on unsupported_agg_deep_two_indices: unsupported aggregate instruction
; SKIP-DAG: Skipping VMP on unsupported_agg_three_indices: unsupported aggregate instruction
; SKIP-DAG: Skipping VMP on unsupported_agg_leftover: unsupported aggregate instruction
; SKIP-DAG: Skipping VMP on unsupported_agg_i128: unsupported aggregate instruction
; SKIP-DAG: Skipping VMP on unsupported_agg_huge: unsupported aggregate instruction
; SKIP-DAG: Skipping VMP on unsupported_neon_ld2_store_tuple: unsupported call instruction
; SKIP-O0-DAG: Skipping VMP on unsupported_agg_deep: unsupported aggregate instruction
; SKIP-NOT: Skipping VMP on protected_nest:
; SKIP-NOT: Skipping VMP on protected_arrpair:
; SKIP-NOT: Skipping VMP on protected_arrfield:
; SKIP-NOT: Skipping VMP on protected_ret_nest:
; SKIP-NOT: Skipping VMP on protected_indirect:
; SKIP-NOT: Skipping VMP on protected_loopphi_nest:

; VIRT-LABEL: define i32 @protected_nest(
; VIRT: %vmp.aregs = alloca [{{[0-9]+}} x [4 x i128]]
; VIRT: store volatile %nest
; VIRT: vmp.dispatch:
; VIRT-DAG: insertvalue %nest
; VIRT-DAG: extractvalue %nest
; VIRT-DAG: load volatile %nest,
; VIRT-DAG: store volatile %nest
; VIRT-DAG: call %nest @swap_nest(

; VIRT-LABEL: define i32 @protected_arrpair(
; VIRT: vmp.dispatch:
; VIRT-DAG: insertvalue [2 x %pair]
; VIRT-DAG: extractvalue [2 x %pair]
; VIRT-DAG: load volatile [2 x %pair],
; VIRT-DAG: store volatile [2 x %pair]

; VIRT-LABEL: define i32 @protected_arrfield(
; VIRT: vmp.dispatch:
; VIRT-DAG: insertvalue %arrfield
; VIRT-DAG: extractvalue %arrfield
; VIRT-DAG: load volatile %arrfield,
; VIRT-DAG: store volatile %arrfield

; VIRT-LABEL: define %nest @protected_ret_nest(
; VIRT: vmp.dispatch:
; VIRT: ret %nest

; VIRT-LABEL: define %nest @protected_indirect(
; VIRT: vmp.dispatch:
; VIRT: call %nest

; VIRT-LABEL: define i32 @protected_loopphi_nest(
; VIRT: vmp.dispatch:
; VIRT-DAG: insertvalue %nest
; VIRT-DAG: extractvalue %nest
; VIRT-DAG: call i32 @fold_nest(%nest

; VIRT: define {{.*}} @unsupported_agg_deep({{.*}} #[[UNSUPATTR:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_agg_midarr({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_agg_arrnest({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_agg_deep_two_indices({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_agg_three_indices({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_agg_leftover({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_agg_i128({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_agg_huge({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_neon_ld2_store_tuple({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #{{[0-9]+}} = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.virtualized"
