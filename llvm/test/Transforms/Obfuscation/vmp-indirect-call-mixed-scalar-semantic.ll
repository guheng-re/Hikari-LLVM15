; Mixed-scalar indirect CallInst (vtable / callback): 0..8 args,
; void/i1/i8/i16/i32/i64/AS0 ptr/half/f32/f64, CallingConv::C, non-vararg.
; Scalar half args/returns are covered by vmp-indirect-call-half-semantic.ll.
; Supported fixed-vector args/returns live in
; vmp-indirect-call-vector-semantic.ll; this file keeps a >128-bit
; vector reject.
; Callee is an AS0 pointer VReg (global table load, select, or phi).
; CallDescriptor replays FunctionType, args, CC, attributes, metadata, FMF.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.ll -o %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.live.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.ll -o %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.live.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll

target triple = "aarch64-unknown-linux-gnu"

%pair = type { i32, i32 }

declare void @hikari_vmp()

@cell = global i32 10, align 4
@alt = global i32 20, align 4
@vt.mix = global [2 x ptr] [ptr @mix_add, ptr @mix_xor], align 8

; i32(ptr, i8, i64, float, double, i32)
define i32 @mix_add(ptr %p, i8 %a, i64 %b, float %c, double %d, i32 %e) noinline {
entry:
  %pv = load i32, ptr %p, align 4
  %az = zext i8 %a to i32
  %bz = trunc i64 %b to i32
  %cz = fptosi float %c to i32
  %dz = fptosi double %d to i32
  %s0 = add i32 %pv, %az
  %s1 = add i32 %s0, %bz
  %s2 = add i32 %s1, %cz
  %s3 = add i32 %s2, %dz
  %r = add i32 %s3, %e
  ret i32 %r
}

define i32 @mix_xor(ptr %p, i8 %a, i64 %b, float %c, double %d, i32 %e) noinline {
entry:
  %pv = load i32, ptr %p, align 4
  %az = zext i8 %a to i32
  %bz = trunc i64 %b to i32
  %cz = fptosi float %c to i32
  %dz = fptosi double %d to i32
  %s0 = add i32 %pv, %az
  %s1 = add i32 %s0, %bz
  %s2 = add i32 %s1, %cz
  %s3 = add i32 %s2, %dz
  %r = xor i32 %s3, %e
  ret i32 %r
}

; void(ptr, i32, double) side effect
define void @acc_store(ptr %p, i32 %x, double %d) noinline {
entry:
  %old = load i32, ptr %p, align 4
  %di = fptosi double %d to i32
  %s = add i32 %old, %x
  %n = add i32 %s, %di
  store i32 %n, ptr %p, align 4
  ret void
}

define void @acc_store2(ptr %p, i32 %x, double %d) noinline {
entry:
  %old = load i32, ptr %p, align 4
  %di = fptosi double %d to i32
  %s = sub i32 %old, %x
  %n = add i32 %s, %di
  store i32 %n, ptr %p, align 4
  ret void
}

; ptr(i32, ptr)
define ptr @pick_pos(i32 %i, ptr %p) noinline {
entry:
  %c = icmp sgt i32 %i, 0
  %r = select i1 %c, ptr %p, ptr @alt
  ret ptr %r
}

define ptr @pick_neg(i32 %i, ptr %p) noinline {
entry:
  %c = icmp slt i32 %i, 0
  %r = select i1 %c, ptr %p, ptr @alt
  ret ptr %r
}

; double(float, i64)
define double @widen_add(float %f, i64 %i) noinline {
entry:
  %d = fpext float %f to double
  %id = sitofp i64 %i to double
  %r = fadd double %d, %id
  ret double %r
}

define double @widen_sub(float %f, i64 %i) noinline {
entry:
  %d = fpext float %f to double
  %id = sitofp i64 %i to double
  %r = fsub double %d, %id
  ret double %r
}

define i32 @reference_vtable(i64 %idx, ptr %p, i8 %a, i64 %b, float %c, double %d, i32 %e) {
entry:
  %slot = getelementptr inbounds [2 x ptr], ptr @vt.mix, i64 0, i64 %idx
  %fp = load ptr, ptr %slot, align 8
  %r = call i32 %fp(ptr %p, i8 %a, i64 %b, float %c, double %d, i32 %e)
  ret i32 %r
}

define i32 @protected_vtable(i64 %idx, ptr %p, i8 %a, i64 %b, float %c, double %d, i32 %e) noinline optnone {
entry:
  call void @hikari_vmp()
  %slot = getelementptr inbounds [2 x ptr], ptr @vt.mix, i64 0, i64 %idx
  %fp = load ptr, ptr %slot, align 8
  %r = call i32 %fp(ptr %p, i8 %a, i64 %b, float %c, double %d, i32 %e)
  ret i32 %r
}

define i32 @reference_select(i1 %pick, ptr %p, i8 %a, i64 %b, float %c, double %d, i32 %e) {
entry:
  %fp = select i1 %pick, ptr @mix_add, ptr @mix_xor
  %r = call i32 %fp(ptr %p, i8 %a, i64 %b, float %c, double %d, i32 %e)
  ret i32 %r
}

define i32 @protected_select(i1 %pick, ptr %p, i8 %a, i64 %b, float %c, double %d, i32 %e) noinline optnone {
entry:
  call void @hikari_vmp()
  %fp = select i1 %pick, ptr @mix_add, ptr @mix_xor
  %r = call i32 %fp(ptr %p, i8 %a, i64 %b, float %c, double %d, i32 %e)
  ret i32 %r
}

define i32 @reference_phi(i1 %pick, ptr %p, i8 %a, i64 %b, float %c, double %d, i32 %e) {
entry:
  br i1 %pick, label %left, label %right

left:
  br label %join

right:
  br label %join

join:
  %fp = phi ptr [ @mix_add, %left ], [ @mix_xor, %right ]
  %r = call i32 %fp(ptr %p, i8 %a, i64 %b, float %c, double %d, i32 %e)
  ret i32 %r
}

define i32 @protected_phi(i1 %pick, ptr %p, i8 %a, i64 %b, float %c, double %d, i32 %e) noinline optnone {
entry:
  call void @hikari_vmp()
  br i1 %pick, label %left, label %right

left:
  br label %join

right:
  br label %join

join:
  %fp = phi ptr [ @mix_add, %left ], [ @mix_xor, %right ]
  %r = call i32 %fp(ptr %p, i8 %a, i64 %b, float %c, double %d, i32 %e)
  ret i32 %r
}

define void @reference_void(ptr %fp, ptr %p, i32 %x, double %d) {
entry:
  call void %fp(ptr %p, i32 %x, double %d)
  ret void
}

define void @protected_void(ptr %fp, ptr %p, i32 %x, double %d) noinline optnone {
entry:
  call void @hikari_vmp()
  call void %fp(ptr %p, i32 %x, double %d)
  ret void
}

define ptr @reference_ptr(ptr %fp, i32 %i, ptr %p) {
entry:
  %r = call ptr %fp(i32 %i, ptr %p)
  ret ptr %r
}

define ptr @protected_ptr(ptr %fp, i32 %i, ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call ptr %fp(i32 %i, ptr %p)
  ret ptr %r
}

define i32 @reference_fmf(ptr %fp, float %f, i64 %i) {
entry:
  %r = call nnan ninf double %fp(float %f, i64 %i)
  %bits = bitcast double %r to i64
  %lo = trunc i64 %bits to i32
  %hi64 = lshr i64 %bits, 32
  %hi = trunc i64 %hi64 to i32
  %x = xor i32 %lo, %hi
  ret i32 %x
}

define i32 @protected_fmf(ptr %fp, float %f, i64 %i) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call nnan ninf double %fp(float %f, i64 %i)
  %bits = bitcast double %r to i64
  %lo = trunc i64 %bits to i32
  %hi64 = lshr i64 %bits, 32
  %hi = trunc i64 %hi64 to i32
  %x = xor i32 %lo, %hi
  ret i32 %x
}

; ----- negatives: selected, not virtualized -----

define i32 @unsupported_nine(ptr %fp, i32 %a0, i32 %a1, i32 %a2, i32 %a3, i32 %a4, i32 %a5, i32 %a6, i32 %a7, i32 %a8) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 %fp(i32 %a0, i32 %a1, i32 %a2, i32 %a3, i32 %a4, i32 %a5, i32 %a6, i32 %a7, i32 %a8)
  ret i32 %r
}

define <8 x i32> @unsupported_vector(ptr %fp, <8 x i32> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i32> %fp(<8 x i32> %v)
  ret <8 x i32> %r
}

define i32 @unsupported_variadic(ptr %fp, i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 (i32, ...) %fp(i32 %x, i32 1)
  ret i32 %r
}

define i32 @unsupported_fastcc(ptr %fp, i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc i32 %fp(i32 %x)
  ret i32 %r
}

define i32 @unsupported_bundle(ptr %fp, i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 %fp(i32 %x) [ "deopt"(i32 0) ]
  ret i32 %r
}

define i32 @unsupported_musttail(ptr %fp, i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call i32 %fp(ptr %fp, i32 %x)
  ret i32 %r
}

define i32 @unsupported_byval(ptr %fp, ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 %fp(ptr byval(%pair) %p)
  ret i32 %r
}

define i32 @main() {
entry:
  %v0 = call i32 @reference_vtable(i64 0, ptr @cell, i8 3, i64 4, float 5.000000e+00, double 6.000000e+00, i32 7)
  %p0 = call i32 @protected_vtable(i64 0, ptr @cell, i8 3, i64 4, float 5.000000e+00, double 6.000000e+00, i32 7)
  %ok0 = icmp eq i32 %v0, %p0
  %v1 = call i32 @reference_vtable(i64 1, ptr @cell, i8 3, i64 4, float 5.000000e+00, double 6.000000e+00, i32 7)
  %p1 = call i32 @protected_vtable(i64 1, ptr @cell, i8 3, i64 4, float 5.000000e+00, double 6.000000e+00, i32 7)
  %ok1 = icmp eq i32 %v1, %p1

  %s0 = call i32 @reference_select(i1 true, ptr @cell, i8 1, i64 2, float 3.000000e+00, double 4.000000e+00, i32 5)
  %q0 = call i32 @protected_select(i1 true, ptr @cell, i8 1, i64 2, float 3.000000e+00, double 4.000000e+00, i32 5)
  %ok2 = icmp eq i32 %s0, %q0
  %s1 = call i32 @reference_select(i1 false, ptr @cell, i8 1, i64 2, float 3.000000e+00, double 4.000000e+00, i32 5)
  %q1 = call i32 @protected_select(i1 false, ptr @cell, i8 1, i64 2, float 3.000000e+00, double 4.000000e+00, i32 5)
  %ok3 = icmp eq i32 %s1, %q1

  %h0 = call i32 @reference_phi(i1 true, ptr @cell, i8 2, i64 3, float 4.000000e+00, double 5.000000e+00, i32 6)
  %i0 = call i32 @protected_phi(i1 true, ptr @cell, i8 2, i64 3, float 4.000000e+00, double 5.000000e+00, i32 6)
  %ok4 = icmp eq i32 %h0, %i0
  %h1 = call i32 @reference_phi(i1 false, ptr @cell, i8 2, i64 3, float 4.000000e+00, double 5.000000e+00, i32 6)
  %i1 = call i32 @protected_phi(i1 false, ptr @cell, i8 2, i64 3, float 4.000000e+00, double 5.000000e+00, i32 6)
  %ok5 = icmp eq i32 %h1, %i1

  store i32 100, ptr @cell, align 4
  call void @reference_void(ptr @acc_store, ptr @cell, i32 3, double 2.000000e+00)
  %vr = load i32, ptr @cell, align 4
  store i32 100, ptr @cell, align 4
  call void @protected_void(ptr @acc_store, ptr @cell, i32 3, double 2.000000e+00)
  %pr = load i32, ptr @cell, align 4
  %ok6 = icmp eq i32 %vr, %pr
  store i32 50, ptr @cell, align 4
  call void @reference_void(ptr @acc_store2, ptr @cell, i32 4, double 1.000000e+00)
  %vr2 = load i32, ptr @cell, align 4
  store i32 50, ptr @cell, align 4
  call void @protected_void(ptr @acc_store2, ptr @cell, i32 4, double 1.000000e+00)
  %pr2 = load i32, ptr @cell, align 4
  %ok7 = icmp eq i32 %vr2, %pr2

  %rp = call ptr @reference_ptr(ptr @pick_pos, i32 1, ptr @cell)
  %pp = call ptr @protected_ptr(ptr @pick_pos, i32 1, ptr @cell)
  %ok8 = icmp eq ptr %rp, %pp
  %rn = call ptr @reference_ptr(ptr @pick_neg, i32 1, ptr @cell)
  %pn = call ptr @protected_ptr(ptr @pick_neg, i32 1, ptr @cell)
  %ok9 = icmp eq ptr %rn, %pn

  %rf = call i32 @reference_fmf(ptr @widen_add, float 2.500000e+00, i64 3)
  %pf = call i32 @protected_fmf(ptr @widen_add, float 2.500000e+00, i64 3)
  %ok10 = icmp eq i32 %rf, %pf
  %rs = call i32 @reference_fmf(ptr @widen_sub, float 8.000000e+00, i64 2)
  %ps = call i32 @protected_fmf(ptr @widen_sub, float 8.000000e+00, i64 2)
  %ok11 = icmp eq i32 %rs, %ps

  %t0 = and i1 %ok0, %ok1
  %t1 = and i1 %ok2, %ok3
  %t2 = and i1 %ok4, %ok5
  %t3 = and i1 %ok6, %ok7
  %t4 = and i1 %ok8, %ok9
  %t5 = and i1 %ok10, %ok11
  %u0 = and i1 %t0, %t1
  %u1 = and i1 %t2, %t3
  %u2 = and i1 %t4, %t5
  %u3 = and i1 %u0, %u1
  %ok = and i1 %u3, %u2
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_nine: indirect call
; SKIP-DAG: Skipping VMP on unsupported_vector: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_variadic: indirect call
; SKIP-DAG: Skipping VMP on unsupported_fastcc: indirect call
; SKIP-DAG: Skipping VMP on unsupported_bundle: indirect call
; SKIP-DAG: Skipping VMP on unsupported_musttail: indirect call
; SKIP-DAG: Skipping VMP on unsupported_byval: indirect call
; SKIP-NOT: Skipping VMP on protected_vtable:
; SKIP-NOT: Skipping VMP on protected_select:
; SKIP-NOT: Skipping VMP on protected_phi:
; SKIP-NOT: Skipping VMP on protected_void:
; SKIP-NOT: Skipping VMP on protected_ptr:
; SKIP-NOT: Skipping VMP on protected_fmf:

; VIRT: define i32 @protected_vtable({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 %{{.+}}(ptr {{.*}}, i8 {{.*}}, i64 {{.*}}, float {{.*}}, double {{.*}}, i32
; VIRT: define i32 @protected_select({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 %{{.+}}(ptr {{.*}}, i8 {{.*}}, i64 {{.*}}, float {{.*}}, double {{.*}}, i32
; VIRT: define i32 @protected_phi({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 %{{.+}}(ptr {{.*}}, i8 {{.*}}, i64 {{.*}}, float {{.*}}, double {{.*}}, i32
; VIRT: define void @protected_void({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void %{{.+}}(ptr {{.*}}, i32 {{.*}}, double
; VIRT: define ptr @protected_ptr({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call ptr %{{.+}}(i32 {{.*}}, ptr
; VIRT: define i32 @protected_fmf({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call nnan ninf double %{{.+}}(float {{.*}}, i64
; VIRT: define {{.*}} @unsupported_nine({{.*}} #[[UNSUPATTR:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_vector({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_variadic({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fastcc({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_bundle({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_musttail({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call
; VIRT: define {{.*}} @unsupported_byval({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.virtualized"
