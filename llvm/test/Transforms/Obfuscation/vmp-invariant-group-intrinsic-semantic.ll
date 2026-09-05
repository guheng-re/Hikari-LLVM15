; Scalar llvm.launder.invariant.group / llvm.strip.invariant.group:
; identity on the AS0 pointer operand.  Lowered to PointerMove into the
; pointer VReg.  Never CallDescriptor and never re-emitted.
;
; LLVM 15 LangRef: the result aliases the argument and is considered
; different (launder) or unassociated (strip) for load/store
; !invariant.group.  ISel/CGP/FastISel drop both to identity.  Host
; IntrinsicLowering has no case (fatal), so references use the raw
; pointer.  DefaultAttrs nocallback is part of the LLVM 15 signature
; and is accepted; rejecting it would close the surface.
;
; Rejected: nonzero address space, poison/undef, musttail, bundles,
; fastcc, indirect, vararg, noreturn, returns_twice, sret.
;
; FileCheck + lli + AArch64 llc/readobj.  O0/O2 x aesSeed 97/7.
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

@g_as1 = addrspace(1) global i32 0

declare void @hikari_vmp()
declare ptr @llvm.launder.invariant.group.p0(ptr)
declare ptr @llvm.strip.invariant.group.p0(ptr)
declare ptr addrspace(1) @llvm.launder.invariant.group.p1(ptr addrspace(1))
declare ptr addrspace(1) @llvm.strip.invariant.group.p1(ptr addrspace(1))
declare void @ext_sret_byval(ptr sret(i32), ptr byval(i32))
declare ptr @vararg_sink(ptr, ...)

define i32 @ext_use(ptr %p) noinline {
entry:
  %v = load i32, ptr %p, align 4
  ret i32 %v
}

; ----- positives -----

define i32 @reference_launder_mem(i32 %val) noinline {
entry:
  %buf = alloca i32, align 4
  store i32 %val, ptr %buf, align 4
  %out = load i32, ptr %buf, align 4
  ret i32 %out
}

define i32 @protected_launder_mem(i32 %val) noinline optnone {
entry:
  call void @hikari_vmp()
  %buf = alloca i32, align 4
  %q = call ptr @llvm.launder.invariant.group.p0(ptr %buf)
  store i32 %val, ptr %q, align 4, !invariant.group !0
  %out = load i32, ptr %q, align 4, !invariant.group !0
  ret i32 %out
}

define i32 @reference_strip_mem(i32 %val) noinline {
entry:
  %buf = alloca i32, align 4
  store i32 %val, ptr %buf, align 4
  %out = load i32, ptr %buf, align 4
  ret i32 %out
}

define i32 @protected_strip_mem(i32 %val) noinline optnone {
entry:
  call void @hikari_vmp()
  %buf = alloca i32, align 4
  %q = call ptr @llvm.strip.invariant.group.p0(ptr %buf)
  store i32 %val, ptr %q, align 4
  %out = load i32, ptr %q, align 4
  ret i32 %out
}

define i32 @reference_gep(i32 %a, i32 %b) noinline {
entry:
  %buf = alloca [2 x i32], align 4
  %p0 = getelementptr [2 x i32], ptr %buf, i64 0, i64 0
  %p1 = getelementptr [2 x i32], ptr %buf, i64 0, i64 1
  store i32 %a, ptr %p0, align 4
  store i32 %b, ptr %p1, align 4
  %x = load i32, ptr %p0, align 4
  %y = load i32, ptr %p1, align 4
  %s = add i32 %x, %y
  ret i32 %s
}

define i32 @protected_gep(i32 %a, i32 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %buf = alloca [2 x i32], align 4
  %base = call ptr @llvm.launder.invariant.group.p0(ptr %buf)
  %p0 = getelementptr [2 x i32], ptr %base, i64 0, i64 0
  %p1 = getelementptr [2 x i32], ptr %base, i64 0, i64 1
  store i32 %a, ptr %p0, align 4
  store i32 %b, ptr %p1, align 4
  %x = load i32, ptr %p0, align 4
  %y = load i32, ptr %p1, align 4
  %s = add i32 %x, %y
  ret i32 %s
}

define i32 @reference_call(i32 %val) noinline {
entry:
  %buf = alloca i32, align 4
  store i32 %val, ptr %buf, align 4
  %out = call i32 @ext_use(ptr %buf)
  ret i32 %out
}

define i32 @protected_call(i32 %val) noinline optnone {
entry:
  call void @hikari_vmp()
  %buf = alloca i32, align 4
  %q = call ptr @llvm.strip.invariant.group.p0(ptr %buf)
  store i32 %val, ptr %q, align 4
  %out = call i32 @ext_use(ptr %q)
  ret i32 %out
}

define i32 @reference_phi(i1 %c, i32 %a, i32 %b) noinline {
entry:
  %buf = alloca i32, align 4
  br i1 %c, label %left, label %right

left:
  store i32 %a, ptr %buf, align 4
  br label %join

right:
  store i32 %b, ptr %buf, align 4
  br label %join

join:
  %out = load i32, ptr %buf, align 4
  ret i32 %out
}

define i32 @protected_phi(i1 %c, i32 %a, i32 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %buf = alloca i32, align 4
  br i1 %c, label %left, label %right

left:
  %l = call ptr @llvm.launder.invariant.group.p0(ptr %buf)
  store i32 %a, ptr %l, align 4
  br label %join

right:
  %r = call ptr @llvm.strip.invariant.group.p0(ptr %buf)
  store i32 %b, ptr %r, align 4
  br label %join

join:
  %p = phi ptr [ %l, %left ], [ %r, %right ]
  %out = load i32, ptr %p, align 4
  ret i32 %out
}

define i32 @reference_loop(i32 %n) noinline {
entry:
  %buf = alloca i32, align 4
  store i32 0, ptr %buf, align 4
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %cur = load i32, ptr %buf, align 4
  %next = add i32 %cur, 1
  store i32 %next, ptr %buf, align 4
  %i1 = add i32 %i, 1
  %more = icmp slt i32 %i1, %n
  br i1 %more, label %loop, label %done

done:
  %out = load i32, ptr %buf, align 4
  ret i32 %out
}

define i32 @protected_loop(i32 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  %buf = alloca i32, align 4
  %q = call ptr @llvm.launder.invariant.group.p0(ptr %buf)
  store i32 0, ptr %q, align 4
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %cur = load i32, ptr %q, align 4
  %next = add i32 %cur, 1
  store i32 %next, ptr %q, align 4
  %i1 = add i32 %i, 1
  %more = icmp slt i32 %i1, %n
  br i1 %more, label %loop, label %done

done:
  %out = load i32, ptr %q, align 4
  ret i32 %out
}

define i32 @reference_tail(i32 %val) noinline {
entry:
  %buf = alloca i32, align 4
  store i32 %val, ptr %buf, align 4
  %out = load i32, ptr %buf, align 4
  ret i32 %out
}

define i32 @protected_tail(i32 %val) noinline optnone {
entry:
  call void @hikari_vmp()
  %buf = alloca i32, align 4
  %q = tail call ptr @llvm.launder.invariant.group.p0(ptr %buf)
  store i32 %val, ptr %q, align 4
  %out = load i32, ptr %q, align 4
  ret i32 %out
}

; ----- negatives -----

define i32 @unsupported_as1_arg(ptr addrspace(1) %p, i32 %val) noinline optnone {
entry:
  call void @hikari_vmp()
  %l = call ptr addrspace(1) @llvm.launder.invariant.group.p1(ptr addrspace(1) %p)
  store i32 %val, ptr addrspace(1) %l, align 4
  %out = load i32, ptr addrspace(1) %l, align 4
  ret i32 %out
}

define i32 @unsupported_as1_call() noinline optnone {
entry:
  call void @hikari_vmp()
  %l = call ptr addrspace(1) @llvm.launder.invariant.group.p1(ptr addrspace(1) @g_as1)
  ret i32 0
}

define i32 @unsupported_poison(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call ptr @llvm.launder.invariant.group.p0(ptr poison)
  ret i32 0
}

define i32 @unsupported_undef(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call ptr @llvm.strip.invariant.group.p0(ptr undef)
  ret i32 0
}

define ptr @unsupported_musttail(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call ptr @llvm.launder.invariant.group.p0(ptr %p)
  ret ptr %r
}

define ptr @unsupported_bundle(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call ptr @llvm.launder.invariant.group.p0(ptr %p) [ "deopt"(i32 0) ]
  ret ptr %r
}

define ptr @unsupported_fastcc(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc ptr @llvm.strip.invariant.group.p0(ptr %p)
  ret ptr %r
}


define ptr @unsupported_indirect(ptr %fp, ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call ptr %fp(ptr %p) [ "deopt"(i32 0) ]
  ret ptr %r
}

define ptr @unsupported_vararg(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc ptr (ptr, ...) @vararg_sink(ptr %p)
  ret ptr %r
}

define ptr @unsupported_noreturn(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call ptr @llvm.launder.invariant.group.p0(ptr %p) noreturn
  ret ptr %r
}

define ptr @unsupported_returns_twice(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call ptr @llvm.strip.invariant.group.p0(ptr %p) returns_twice
  ret ptr %r
}

define void @unsupported_sret(ptr sret(i32) %p, ptr byval(i32) %q) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @ext_sret_byval(ptr sret(i32) %p, ptr byval(i32) %q)
  ret void
}

define i32 @main() {
entry:
  %el = call i32 @reference_launder_mem(i32 42)
  %pl = call i32 @protected_launder_mem(i32 42)
  %okl = icmp eq i32 %el, %pl
  %el2 = call i32 @reference_launder_mem(i32 -7)
  %pl2 = call i32 @protected_launder_mem(i32 -7)
  %okl2 = icmp eq i32 %el2, %pl2
  %es = call i32 @reference_strip_mem(i32 9)
  %ps = call i32 @protected_strip_mem(i32 9)
  %oks = icmp eq i32 %es, %ps
  %eg = call i32 @reference_gep(i32 3, i32 4)
  %pg = call i32 @protected_gep(i32 3, i32 4)
  %okg = icmp eq i32 %eg, %pg
  %ec = call i32 @reference_call(i32 11)
  %pc = call i32 @protected_call(i32 11)
  %okc = icmp eq i32 %ec, %pc
  %ephi = call i32 @reference_phi(i1 true, i32 5, i32 8)
  %pphi = call i32 @protected_phi(i1 true, i32 5, i32 8)
  %okphi = icmp eq i32 %ephi, %pphi
  %ephi2 = call i32 @reference_phi(i1 false, i32 5, i32 8)
  %pphi2 = call i32 @protected_phi(i1 false, i32 5, i32 8)
  %okphi2 = icmp eq i32 %ephi2, %pphi2
  %elo = call i32 @reference_loop(i32 4)
  %plo = call i32 @protected_loop(i32 4)
  %oklo = icmp eq i32 %elo, %plo
  %et = call i32 @reference_tail(i32 13)
  %pt = call i32 @protected_tail(i32 13)
  %okt = icmp eq i32 %et, %pt
  %t0 = and i1 %okl, %okl2
  %t1 = and i1 %t0, %oks
  %t2 = and i1 %t1, %okg
  %t3 = and i1 %t2, %okc
  %t4 = and i1 %t3, %okphi
  %t5 = and i1 %t4, %okphi2
  %t6 = and i1 %t5, %oklo
  %ok = and i1 %t6, %okt
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

!0 = !{}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_as1_arg: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_as1_call: unsupported invariant.group
; SKIP-DAG: Skipping VMP on unsupported_poison: unsupported invariant.group
; SKIP-DAG: Skipping VMP on unsupported_undef: unsupported invariant.group
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported invariant.group
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported invariant.group
; SKIP-DAG: Skipping VMP on unsupported_indirect: indirect call
; SKIP-DAG: Skipping VMP on unsupported_vararg: variadic call
; SKIP-DAG: Skipping VMP on unsupported_noreturn: unsupported invariant.group
; SKIP-DAG: Skipping VMP on unsupported_returns_twice: unsupported invariant.group
; SKIP-DAG: Skipping VMP on unsupported_sret: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_launder_mem:
; SKIP-NOT: Skipping VMP on protected_strip_mem:
; SKIP-NOT: Skipping VMP on protected_gep:
; SKIP-NOT: Skipping VMP on protected_call:
; SKIP-NOT: Skipping VMP on protected_phi:
; SKIP-NOT: Skipping VMP on protected_loop:
; SKIP-NOT: Skipping VMP on protected_tail:

; VIRT: define i32 @protected_launder_mem({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call void @hikari_vmp()
; VIRT-NOT: @llvm.launder.invariant.group
; VIRT-NOT: @llvm.strip.invariant.group
; VIRT: }
; VIRT: define i32 @protected_strip_mem({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: @llvm.launder.invariant.group
; VIRT-NOT: @llvm.strip.invariant.group
; VIRT: }
; VIRT: define i32 @protected_gep({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: @llvm.launder.invariant.group
; VIRT: }
; VIRT: define i32 @protected_call({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: @llvm.strip.invariant.group
; VIRT: }
; VIRT: define i32 @protected_phi({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: @llvm.launder.invariant.group
; VIRT-NOT: @llvm.strip.invariant.group
; VIRT: }
; VIRT: define i32 @protected_loop({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: @llvm.launder.invariant.group
; VIRT: }
; VIRT: define i32 @protected_tail({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: tail call
; VIRT-NOT: @llvm.launder.invariant.group
; VIRT: }
; VIRT: define {{.*}} @unsupported_as1_arg({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_as1_call({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_poison({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_undef({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_musttail({{.*}} #[[UNSUPMUST:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_bundle({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fastcc({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_indirect({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_vararg({{.*}} #[[UNSUPVAR:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_noreturn({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_returns_twice({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_sret({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPMUST]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPMUST]] = { {{.*}}"hikari.vmp.selected"
; VIRT-NOT: attributes #[[UNSUPVAR]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
