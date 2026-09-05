; Restricted direct variadic CallInst via CallDescriptor.
; The *caller* stays non-variadic.  A C vararg callee may be virtualized
; under the conservative va_start/va_arg/va_end gate (see
; vmp-vaarg-semantic.ll).  protected_self_va_copy covers the
; conservative two-list va_start/va_copy/va_end form.  Only direct CallingConv::C non-intrinsic
; vararg calls are allowed: original FunctionType, actual arguments,
; attributes and C convention are replayed.  Named/fixed params use
; ordinary scalars; the variadic tail is i32/i64/double/AS0 ptr only
; (i1/i8/i16/f32/aggregate/vector/non-AS0 rejected).  Indirect variadic,
; non-C, musttail, bundles, noreturn, returns_twice and complex ABI stay
; out.
; The helper is unprotected so host lli can interpret llvm.va_start /
; va_arg / llvm.va_end and fold every tail ABI value into the i32
; return.  reference and protected each call sum_var; main compares.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.ll -o %t.o0.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.ll -o %t.o2.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll

target triple = "aarch64-unknown-linux-gnu"

@g = global i32 7
@h = global i32 9
@sum_var_fp = global ptr @sum_var

declare void @hikari_vmp()
declare void @llvm.va_start(ptr)
declare void @llvm.va_end(ptr)
declare void @llvm.va_copy(ptr, ptr)

; Unprotected variadic helper: consume the two named i32s and the four
; allowed tails (i32, i64, double, AS0 ptr) via va_start/va_arg/va_end.
; Each tail is mixed into the i32 return so host lli can see dropped or
; corrupted extras.  noinline keeps the body out of the protected
; function; the interpreter reads VarArgs through va_arg.
define i32 @sum_var(i32 %a, i32 %b, ...) noinline {
entry:
  %ap = alloca ptr, align 8
  call void @llvm.va_start(ptr %ap)
  %c = va_arg ptr %ap, i32
  %d = va_arg ptr %ap, i64
  %e = va_arg ptr %ap, double
  %p = va_arg ptr %ap, ptr
  call void @llvm.va_end(ptr %ap)
  %dlo = trunc i64 %d to i32
  %dhi64 = lshr i64 %d, 32
  %dhi = trunc i64 %dhi64 to i32
  %ebits = bitcast double %e to i64
  %elo = trunc i64 %ebits to i32
  %ehi64 = lshr i64 %ebits, 32
  %ehi = trunc i64 %ehi64 to i32
  %pv = load i32, ptr %p, align 4
  %pi = ptrtoint ptr %p to i64
  %plo = trunc i64 %pi to i32
  %named = add i32 %a, %b
  %c.w = mul i32 %c, 5
  %d.sum = add i32 %dlo, %dhi
  %d.w = mul i32 %d.sum, 7
  %e.xor = xor i32 %elo, %ehi
  %e.w = mul i32 %e.xor, 11
  %p.sum = add i32 %pv, %plo
  %p.w = mul i32 %p.sum, 13
  %r0 = add i32 %named, %c.w
  %r1 = add i32 %r0, %d.w
  %r2 = add i32 %r1, %e.w
  %r = add i32 %r2, %p.w
  ret i32 %r
}

define i32 @sum_named(i32 %a, i32 %b) noinline {
entry:
  %s = add i32 %a, %b
  ret i32 %s
}

define i32 @reference(i32 %a, i32 %b, i32 %c, i64 %d, double %e, ptr %p) {
entry:
  %r = call i32 (i32, i32, ...) @sum_var(i32 %a, i32 %b, i32 %c, i64 %d, double %e, ptr %p)
  ret i32 %r
}

define i32 @protected(i32 %a, i32 %b, i32 %c, i64 %d, double %e, ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 (i32, i32, ...) @sum_var(i32 %a, i32 %b, i32 %c, i64 %d, double %e, ptr %p)
  ret i32 %r
}

define i32 @protected_self_va_copy(i32 %n, ...) noinline optnone {
entry:
  call void @hikari_vmp()
  %ap = alloca ptr, align 8
  %aq = alloca ptr, align 8
  call void @llvm.va_start(ptr %ap)
  call void @llvm.va_copy(ptr %aq, ptr %ap)
  call void @llvm.va_end(ptr %ap)
  call void @llvm.va_end(ptr %aq)
  ret i32 %n
}

define i32 @unsupported_i8_tail(i32 %a, i32 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 (i32, i32, ...) @sum_var(i32 %a, i32 %b, i8 1)
  ret i32 %r
}

define i32 @unsupported_f32_tail(i32 %a, i32 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 (i32, i32, ...) @sum_var(i32 %a, i32 %b, float 1.0)
  ret i32 %r
}

define i32 @unsupported_indirect_vararg(i32 %a, i32 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %fp = load ptr, ptr @sum_var_fp, align 8
  %r = call i32 (i32, i32, ...) %fp(i32 %a, i32 %b, i32 1)
  ret i32 %r
}

; musttail to a variadic callee with extra args is illegal IR under
; -verify-each; this sibling uses a matching non-vararg prototype so the
; early musttail reject is still covered.
define i32 @unsupported_musttail(i32 %a, i32 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call i32 @sum_named(i32 %a, i32 %b)
  ret i32 %r
}

define i32 @unsupported_bundle(i32 %a, i32 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 (i32, i32, ...) @sum_var(i32 %a, i32 %b, i32 1) [ "deopt"(i32 0) ]
  ret i32 %r
}

define i32 @main() {
entry:
  ; named + all four tails (i32 / i64 / double / AS0 ptr @g)
  %e0 = call i32 @reference(i32 1, i32 2, i32 3, i64 4, double 5.0, ptr @g)
  %a0 = call i32 @protected(i32 1, i32 2, i32 3, i64 4, double 5.0, ptr @g)
  ; zeroed tails still pass the pointer identity
  %e1 = call i32 @reference(i32 10, i32 20, i32 0, i64 0, double 0.0, ptr @g)
  %a1 = call i32 @protected(i32 10, i32 20, i32 0, i64 0, double 0.0, ptr @g)
  ; i64 high half and a different double / pointer
  %e2 = call i32 @reference(i32 4, i32 6, i32 8, i64 4294967302, double -2.500000e+00, ptr @h)
  %a2 = call i32 @protected(i32 4, i32 6, i32 8, i64 4294967302, double -2.500000e+00, ptr @h)
  ; isolate the i32 tail
  %e3 = call i32 @reference(i32 1, i32 1, i32 99, i64 1, double 1.000000e+00, ptr @g)
  %a3 = call i32 @protected(i32 1, i32 1, i32 99, i64 1, double 1.000000e+00, ptr @g)
  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %e1, %a1
  %m2 = icmp eq i32 %e2, %a2
  %m3 = icmp eq i32 %e3, %a3
  %ok01 = and i1 %m0, %m1
  %ok23 = and i1 %m2, %m3
  %ok = and i1 %ok01, %ok23
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_i8_tail: unsupported call argument
; SKIP-DAG: Skipping VMP on unsupported_f32_tail: unsupported call argument
; SKIP-DAG: Skipping VMP on unsupported_indirect_vararg: indirect call
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected:
; SKIP-NOT: Skipping VMP on protected_self_va_copy:
; SKIP-NOT: Skipping VMP on sum_var:
; SKIP-NOT: Skipping VMP on reference:

; VIRT: define i32 @sum_var({{.*}} {
; VIRT-NOT: vmp.dispatch
; VIRT: define i32 @protected({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 (i32, i32, ...) @sum_var(i32 {{.*}}, i32 {{.*}}, i32 {{.*}}, i64 {{.*}}, double {{.*}}, ptr {{.*}})
; VIRT: define i32 @protected_self_va_copy({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: define i32 @unsupported_i8_tail({{.*}} #[[UNSUP_SEL:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call i32 (i32, i32, ...) @sum_var({{.*}}i8 1)
; VIRT: define i32 @unsupported_f32_tail({{.*}} #[[UNSUP_SEL]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call i32 (i32, i32, ...) @sum_var({{.*}}float 1.000000e+00)
; VIRT: define i32 @unsupported_indirect_vararg({{.*}} #[[UNSUP_IND:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define i32 @unsupported_musttail({{.*}} #[[UNSUP_MT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call i32 @sum_named(
; VIRT: define i32 @unsupported_bundle({{.*}} #[[UNSUP_SEL]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP_SEL]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUP_MT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT-NOT: attributes #[[UNSUP_IND]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
