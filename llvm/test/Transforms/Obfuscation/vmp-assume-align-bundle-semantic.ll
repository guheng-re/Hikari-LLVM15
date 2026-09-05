; Restricted llvm.assume knowledge operand bundles replayed via
; CallDescriptor.  Align is the O2 __builtin_assume_aligned shape:
;   call void @llvm.assume(i1 true) [ "align"(ptr %p, i64 16) ]
; ConstantInt align stays power-of-two; ConstantInt offset stays
; an immediate.  Non-constant ordinary i64 align / offset are
; extra integer VRegs on the existing payload path.
; nonnull / noundef (i1..i64 or AS0 ptr) / dereferenceable /
; dereferenceable_or_null / cold() share the same path.
; ignore / deopt / musttail / poison/undef / non-i64
; dynamic align / non-power-of-two ConstantInt alignments stay rejected.
; C, exact void(i1), formal type equality.  Ordinary tail accepted
; and replayed as TCK_None; see vmp-direct-call-tail-eligibility-semantic.ll.
; No new VM opcode.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.ll > %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.live.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.ll > %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.live.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.s7.ll > %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.s7.ll > %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare void @llvm.assume(i1 noundef)
declare void @ext_sret_byval(ptr sret(i32), ptr byval(i32))

define i32 @sink_i32(ptr %p, i32 %x) {
entry:
  ret i32 %x
}

define i32 @reference_assume_align(ptr %p) {
entry:
  call void @llvm.assume(i1 true) [ "align"(ptr %p, i64 16) ]
  %v = load i32, ptr %p, align 4
  %r = add i32 %v, 1
  ret i32 %r
}

define i32 @protected_assume_bare(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.assume(i1 true)
  %c = icmp sgt i32 %x, 0
  call void @llvm.assume(i1 %c)
  ret i32 %x
}

define i32 @protected_assume_align(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.assume(i1 true) [ "align"(ptr %p, i64 16) ]
  %v = load i32, ptr %p, align 4
  %r = add i32 %v, 1
  ret i32 %r
}

define i32 @protected_assume_align_offset(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.assume(i1 true) [ "align"(ptr %p, i64 16, i64 0) ]
  %v = load i32, ptr %p, align 4
  %r = add i32 %v, 2
  ret i32 %r
}

define i32 @protected_assume_align_cond(ptr %p, i1 %c) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.assume(i1 %c) [ "align"(ptr %p, i64 8) ]
  %v = load i32, ptr %p, align 4
  %r = add i32 %v, 3
  ret i32 %r
}

define i32 @protected_assume_align_alloca(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %slot = alloca i32, align 16
  store i32 %x, ptr %slot, align 4
  call void @llvm.assume(i1 true) [ "align"(ptr %slot, i64 16) ]
  %v = load i32, ptr %slot, align 4
  %r = add i32 %v, 4
  ret i32 %r
}


define i32 @protected_assume_align_phi(ptr %p, i1 %c) noinline optnone {
entry:
  call void @hikari_vmp()
  br i1 %c, label %left, label %right
left:
  call void @llvm.assume(i1 true) [ "align"(ptr %p, i64 16) ]
  %l = load i32, ptr %p, align 4
  br label %join
right:
  %rgt = load i32, ptr %p, align 4
  br label %join
join:
  %q = phi i32 [ %l, %left ], [ %rgt, %right ]
  %s = add i32 %q, 6
  ret i32 %s
}

define i32 @protected_assume_nonnull(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.assume(i1 true) [ "nonnull"(ptr %p) ]
  %v = load i32, ptr %p, align 4
  %r = add i32 %v, 7
  ret i32 %r
}

define i32 @protected_assume_noundef(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.assume(i1 true) [ "noundef"(i32 %x) ]
  %r = add i32 %x, 8
  ret i32 %r
}

define i32 @protected_assume_deref(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.assume(i1 true) [ "dereferenceable"(ptr %p, i64 4) ]
  %v = load i32, ptr %p, align 4
  %r = add i32 %v, 9
  ret i32 %r
}

define i32 @protected_assume_deref_or_null(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.assume(i1 true) [ "dereferenceable_or_null"(ptr %p, i64 4) ]
  %v = load i32, ptr %p, align 4
  %r = add i32 %v, 10
  ret i32 %r
}

define i32 @protected_assume_align_nonnull(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.assume(i1 true) [ "align"(ptr %p, i64 16), "nonnull"(ptr %p) ]
  %v = load i32, ptr %p, align 4
  %r = add i32 %v, 11
  ret i32 %r
}


define i32 @protected_assume_cold(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.assume(i1 true) [ "cold"() ]
  %r = add i32 %x, 13
  ret i32 %r
}

define i32 @protected_assume_cold_nonnull(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.assume(i1 true) [ "cold"(), "nonnull"(ptr %p) ]
  %v = load i32, ptr %p, align 4
  %r = add i32 %v, 14
  ret i32 %r
}


define i32 @protected_assume_align_dyn(ptr %p, i64 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.assume(i1 true) [ "align"(ptr %p, i64 %a) ]
  %v = load i32, ptr %p, align 4
  %r = add i32 %v, 16
  ret i32 %r
}

define i32 @protected_assume_align_dyn_off(ptr %p, i64 %a, i64 %o) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.assume(i1 true) [ "align"(ptr %p, i64 %a, i64 %o) ]
  %v = load i32, ptr %p, align 4
  %r = add i32 %v, 17
  ret i32 %r
}

define i32 @protected_assume_align_const_dyn_off(ptr %p, i64 %o) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.assume(i1 true) [ "align"(ptr %p, i64 16, i64 %o) ]
  %v = load i32, ptr %p, align 4
  %r = add i32 %v, 18
  ret i32 %r
}

define i32 @unsupported_assume_ignore(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.assume(i1 true) [ "ignore"(ptr %p) ]
  %v = load i32, ptr %p, align 4
  ret i32 %v
}

define i32 @unsupported_assume_nounwind(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.assume(i1 true) [ "nounwind"() ]
  ret i32 %x
}

define i32 @unsupported_assume_musttail(ptr %p, i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.assume(i1 true) [ "align"(ptr %p, i64 16) ]
  %v = musttail call i32 @sink_i32(ptr %p, i32 %x)
  ret i32 %v
}

define i32 @unsupported_assume_align_poison(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.assume(i1 true) [ "align"(ptr poison, i64 16) ]
  %v = load i32, ptr %p, align 4
  ret i32 %v
}

define i32 @unsupported_assume_align_undef(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.assume(i1 true) [ "align"(ptr undef, i64 16) ]
  %v = load i32, ptr %p, align 4
  ret i32 %v
}

define i32 @unsupported_assume_align_badpow(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.assume(i1 true) [ "align"(ptr %p, i64 3) ]
  %v = load i32, ptr %p, align 4
  ret i32 %v
}

define i32 @unsupported_assume_align_dyn_i32(ptr %p, i32 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.assume(i1 true) [ "align"(ptr %p, i32 %a) ]
  %v = load i32, ptr %p, align 4
  ret i32 %v
}

define i32 @unsupported_assume_align_dyn_poison(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.assume(i1 true) [ "align"(ptr %p, i64 poison) ]
  %v = load i32, ptr %p, align 4
  ret i32 %v
}

define i32 @unsupported_assume_align_dyn_undef(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.assume(i1 true) [ "align"(ptr %p, i64 undef) ]
  %v = load i32, ptr %p, align 4
  ret i32 %v
}

define void @unsupported_assume_malformed() noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.assume(i1 true) noreturn
  ret void
}

define void @unsupported_assume_fastcc() noinline optnone {
entry:
  call void @hikari_vmp()
  call fastcc void @llvm.assume(i1 true)
  ret void
}

define void @unsupported_assume_as1_arg(ptr addrspace(1) %unused) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.assume(i1 true)
  ret void
}

define void @unsupported_assume_sret(ptr sret(i32) %p, ptr byval(i32) %q) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @ext_sret_byval(ptr sret(i32) %p, ptr byval(i32) %q)
  ret void
}

define i32 @main() {
entry:
  %buf = alloca i32, align 16
  store i32 40, ptr %buf, align 4
  %e0 = call i32 @reference_assume_align(ptr %buf)
  %a0 = call i32 @protected_assume_align(ptr %buf)
  %a1 = call i32 @protected_assume_align_offset(ptr %buf)
  %a2 = call i32 @protected_assume_align_cond(ptr %buf, i1 true)
  %a3 = call i32 @protected_assume_align_alloca(i32 40)
  %ab = call i32 @protected_assume_bare(i32 40)
  %a4 = add i32 40, 5
  %a5 = call i32 @protected_assume_align_phi(ptr %buf, i1 true)
  %a6 = call i32 @protected_assume_nonnull(ptr %buf)
  %a7 = call i32 @protected_assume_noundef(i32 40)
  %a8 = call i32 @protected_assume_deref(ptr %buf)
  %a9 = call i32 @protected_assume_deref_or_null(ptr %buf)
  %a10 = call i32 @protected_assume_align_nonnull(ptr %buf)
  %a11 = add i32 40, 12
  %a12 = call i32 @protected_assume_cold(i32 40)
  %a13 = call i32 @protected_assume_cold_nonnull(ptr %buf)
  %a14 = add i32 40, 15
  %a15 = call i32 @protected_assume_align_dyn(ptr %buf, i64 16)
  %a16 = call i32 @protected_assume_align_dyn_off(ptr %buf, i64 16, i64 0)
  %a17 = call i32 @protected_assume_align_const_dyn_off(ptr %buf, i64 0)
  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %a1, 42
  %m2 = icmp eq i32 %a2, 43
  %m3 = icmp eq i32 %a3, 44
  %m4 = icmp eq i32 %a4, 45
  %m5 = icmp eq i32 %a5, 46
  %m6 = icmp eq i32 %a6, 47
  %m7 = icmp eq i32 %a7, 48
  %m8 = icmp eq i32 %a8, 49
  %m9 = icmp eq i32 %a9, 50
  %m10 = icmp eq i32 %a10, 51
  %m11 = icmp eq i32 %a11, 52
  %m12 = icmp eq i32 %a12, 53
  %m13 = icmp eq i32 %a13, 54
  %m14 = icmp eq i32 %a14, 55
  %m15 = icmp eq i32 %a15, 56
  %m16 = icmp eq i32 %a16, 57
  %m17 = icmp eq i32 %a17, 58
  %t0 = and i1 %m0, %m1
  %t1 = and i1 %m2, %m3
  %t2 = and i1 %m4, %m5
  %t3 = and i1 %m6, %m7
  %t4 = and i1 %m8, %m9
  %t5 = and i1 %m10, %m11
  %t6 = and i1 %m12, %m13
  %t7 = and i1 %m15, %m16
  %ok0 = and i1 %t0, %t1
  %ok1 = and i1 %t2, %t3
  %ok2 = and i1 %t4, %t5
  %ok3 = and i1 %ok0, %ok1
  %ok4 = and i1 %ok2, %t6
  %ok5 = and i1 %ok4, %m14
  %ok6 = and i1 %ok5, %t7
  %ok = and i1 %ok3, %ok6
  %ok7 = and i1 %ok, %m17
  %mb = icmp eq i32 %ab, 40
  %ok8 = and i1 %ok7, %mb
  %code = select i1 %ok8, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_assume_ignore: unsupported assume
; SKIP-DAG: Skipping VMP on unsupported_assume_nounwind: unsupported assume
; SKIP-DAG: Skipping VMP on unsupported_assume_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_assume_align_poison: unsupported assume
; SKIP-DAG: Skipping VMP on unsupported_assume_align_undef: unsupported assume
; SKIP-DAG: Skipping VMP on unsupported_assume_align_badpow: unsupported assume
; SKIP-DAG: Skipping VMP on unsupported_assume_align_dyn_i32: unsupported assume
; SKIP-DAG: Skipping VMP on unsupported_assume_align_dyn_poison: unsupported assume
; SKIP-DAG: Skipping VMP on unsupported_assume_align_dyn_undef: unsupported assume
; SKIP-DAG: Skipping VMP on unsupported_assume_malformed: unsupported assume
; SKIP-DAG: Skipping VMP on unsupported_assume_fastcc: unsupported assume
; SKIP-DAG: Skipping VMP on unsupported_assume_as1_arg: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_assume_sret: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_assume_bare:
; SKIP-NOT: Skipping VMP on protected_assume_align:
; SKIP-NOT: Skipping VMP on protected_assume_align_offset:
; SKIP-NOT: Skipping VMP on protected_assume_align_cond:
; SKIP-NOT: Skipping VMP on protected_assume_align_alloca:
; SKIP-NOT: Skipping VMP on protected_assume_align_phi:
; SKIP-NOT: Skipping VMP on protected_assume_nonnull:
; SKIP-NOT: Skipping VMP on protected_assume_noundef:
; SKIP-NOT: Skipping VMP on protected_assume_deref:
; SKIP-NOT: Skipping VMP on protected_assume_deref_or_null:
; SKIP-NOT: Skipping VMP on protected_assume_align_nonnull:
; SKIP-NOT: Skipping VMP on protected_assume_cold:
; SKIP-NOT: Skipping VMP on protected_assume_cold_nonnull:
; SKIP-NOT: Skipping VMP on protected_assume_align_dyn:
; SKIP-NOT: Skipping VMP on protected_assume_align_dyn_off:
; SKIP-NOT: Skipping VMP on protected_assume_align_const_dyn_off:
; SKIP-NOT: Skipping VMP on reference_assume_align:

; VIRT: define i32 @protected_assume_bare({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: call void @llvm.assume(i1 {{.*}})
; VIRT: }
; VIRT: define i32 @protected_assume_align({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.assume(i1 {{.*}}) [ "align"(ptr {{.*}}, i64 16) ]
; VIRT: define i32 @protected_assume_align_offset({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.assume(i1 {{.*}}) [ "align"(ptr {{.*}}, i64 16, i64 0) ]
; VIRT: define i32 @protected_assume_align_cond({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.assume(i1 {{.*}}) [ "align"(ptr {{.*}}, i64 8) ]
; VIRT: define i32 @protected_assume_align_alloca({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.assume(i1 {{.*}}) [ "align"(ptr {{.*}}, i64 16) ]
; VIRT: define i32 @protected_assume_align_phi({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.assume(i1 {{.*}}) [ "align"(ptr {{.*}}, i64 16) ]
; VIRT: define i32 @protected_assume_nonnull({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.assume(i1 {{.*}}) [ "nonnull"(ptr {{.*}}) ]
; VIRT: define i32 @protected_assume_noundef({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.assume(i1 {{.*}}) [ "noundef"(i32 {{.*}}) ]
; VIRT: define i32 @protected_assume_deref({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.assume(i1 {{.*}}) [ "dereferenceable"(ptr {{.*}}, i64 4) ]
; VIRT: define i32 @protected_assume_deref_or_null({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.assume(i1 {{.*}}) [ "dereferenceable_or_null"(ptr {{.*}}, i64 4) ]
; VIRT: define i32 @protected_assume_align_nonnull({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.assume(i1 {{.*}}) [ "align"(ptr {{.*}}, i64 16), "nonnull"(ptr {{.*}}) ]
; VIRT: define i32 @protected_assume_cold({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.assume(i1 {{.*}}) [ "cold"() ]
; VIRT: define i32 @protected_assume_cold_nonnull({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.assume(i1 {{.*}}) [ "cold"(), "nonnull"(ptr {{.*}}) ]
; VIRT: define i32 @protected_assume_align_dyn({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.assume(i1 {{.*}}) [ "align"(ptr {{.*}}, i64 {{.*}}) ]
; VIRT: define i32 @protected_assume_align_dyn_off({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.assume(i1 {{.*}}) [ "align"(ptr {{.*}}, i64 {{.*}}, i64 {{.*}}) ]
; VIRT: define i32 @protected_assume_align_const_dyn_off({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.assume(i1 {{.*}}) [ "align"(ptr {{.*}}, i64 16, i64 {{.*}}) ]
; VIRT: define {{.*}} @unsupported_assume_ignore({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call void @llvm.assume(i1 true) [ "ignore"(ptr {{.*}}) ]
; VIRT: define {{.*}} @unsupported_assume_nounwind({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call void @llvm.assume(i1 true) [ "nounwind"() ]
; VIRT: define {{.*}} @unsupported_assume_musttail({{.*}} #[[UNSUP_MT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call i32 @sink_i32(
; VIRT: define {{.*}} @unsupported_assume_align_poison({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_assume_align_undef({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_assume_align_badpow({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_assume_align_dyn_i32({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_assume_align_dyn_poison({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_assume_align_dyn_undef({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_assume_malformed({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_assume_fastcc({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_assume_as1_arg({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_assume_sret({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_MT]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
