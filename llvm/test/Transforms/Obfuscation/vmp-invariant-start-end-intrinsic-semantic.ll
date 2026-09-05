; llvm.invariant.start / llvm.invariant.end are LangRef unchanging/
; mutable markers.  ISel and IntrinsicLowering discard them.  VMP
; consumes well-formed AS0 pairs without replay (like lifetime) when
; the start token is used only by matching ends.  Regenerated
; load/store/call metadata drops !invariant.load / !invariant.group /
; !alias.scope / !noalias so shared handlers cannot keep invalid
; invariant or scoped-AA promises.
;
; Rejected: token escape, unpaired end, poison/undef, nonzero AS,
; musttail, bundles, fastcc, indirect, vararg, sret.
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
declare ptr @llvm.invariant.start.p0(i64, ptr nocapture)
declare void @llvm.invariant.end.p0(ptr, i64, ptr nocapture)
declare ptr @llvm.invariant.start.p1(i64, ptr addrspace(1) nocapture)
declare void @ext_sret_byval(ptr sret(i32), ptr byval(i32))
declare ptr @vararg_sink(ptr, ...)

; ----- positives -----

define i32 @reference_mem(i32 %x) noinline {
entry:
  %slot = alloca i32, align 4
  store i32 %x, ptr %slot, align 4
  %s = call ptr @llvm.invariant.start.p0(i64 4, ptr %slot)
  %v = load i32, ptr %slot, align 4
  call void @llvm.invariant.end.p0(ptr %s, i64 4, ptr %slot)
  store i32 1, ptr %slot, align 4
  %after = load i32, ptr %slot, align 4
  %sum = add i32 %v, %after
  ret i32 %sum
}

define i32 @protected_mem(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %slot = alloca i32, align 4
  store i32 %x, ptr %slot, align 4, !invariant.group !0
  %s = call ptr @llvm.invariant.start.p0(i64 4, ptr %slot)
  %v = load i32, ptr %slot, align 4, !invariant.load !0, !invariant.group !0
  call void @llvm.invariant.end.p0(ptr %s, i64 4, ptr %slot)
  store i32 1, ptr %slot, align 4
  %after = load i32, ptr %slot, align 4
  %sum = add i32 %v, %after
  ret i32 %sum
}

define i32 @reference_pair(i32 %seed) noinline {
entry:
  %a = alloca i32, align 4
  %b = alloca i64, align 8
  store i32 %seed, ptr %a, align 4
  %seed64 = zext i32 %seed to i64
  store i64 %seed64, ptr %b, align 8
  %sa = call ptr @llvm.invariant.start.p0(i64 4, ptr %a)
  %la = load i32, ptr %a, align 4
  call void @llvm.invariant.end.p0(ptr %sa, i64 4, ptr %a)
  %sb = call ptr @llvm.invariant.start.p0(i64 8, ptr %b)
  %lb = load i64, ptr %b, align 8
  call void @llvm.invariant.end.p0(ptr %sb, i64 8, ptr %b)
  %lbi = trunc i64 %lb to i32
  %o = add i32 %la, %lbi
  ret i32 %o
}

define i32 @protected_pair(i32 %seed) noinline optnone {
entry:
  call void @hikari_vmp()
  %a = alloca i32, align 4
  %b = alloca i64, align 8
  store i32 %seed, ptr %a, align 4
  %seed64 = zext i32 %seed to i64
  store i64 %seed64, ptr %b, align 8
  %sa = call ptr @llvm.invariant.start.p0(i64 4, ptr %a)
  %la = load i32, ptr %a, align 4
  call void @llvm.invariant.end.p0(ptr %sa, i64 4, ptr %a)
  %sb = call ptr @llvm.invariant.start.p0(i64 8, ptr %b)
  %lb = load i64, ptr %b, align 8
  call void @llvm.invariant.end.p0(ptr %sb, i64 8, ptr %b)
  %lbi = trunc i64 %lb to i32
  %o = add i32 %la, %lbi
  ret i32 %o
}

define i32 @reference_phi(i1 %c, i32 %a, i32 %b) noinline {
entry:
  %slot = alloca i32, align 4
  br i1 %c, label %left, label %right

left:
  store i32 %a, ptr %slot, align 4
  %sl = call ptr @llvm.invariant.start.p0(i64 4, ptr %slot)
  %vl = load i32, ptr %slot, align 4
  call void @llvm.invariant.end.p0(ptr %sl, i64 4, ptr %slot)
  br label %join

right:
  store i32 %b, ptr %slot, align 4
  %sr = call ptr @llvm.invariant.start.p0(i64 4, ptr %slot)
  %vr = load i32, ptr %slot, align 4
  call void @llvm.invariant.end.p0(ptr %sr, i64 4, ptr %slot)
  br label %join

join:
  %p = phi i32 [ %vl, %left ], [ %vr, %right ]
  ret i32 %p
}

define i32 @protected_phi(i1 %c, i32 %a, i32 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %slot = alloca i32, align 4
  br i1 %c, label %left, label %right

left:
  store i32 %a, ptr %slot, align 4
  %sl = call ptr @llvm.invariant.start.p0(i64 4, ptr %slot)
  %vl = load i32, ptr %slot, align 4
  call void @llvm.invariant.end.p0(ptr %sl, i64 4, ptr %slot)
  br label %join

right:
  store i32 %b, ptr %slot, align 4
  %sr = call ptr @llvm.invariant.start.p0(i64 4, ptr %slot)
  %vr = load i32, ptr %slot, align 4
  call void @llvm.invariant.end.p0(ptr %sr, i64 4, ptr %slot)
  br label %join

join:
  %p = phi i32 [ %vl, %left ], [ %vr, %right ]
  ret i32 %p
}

define i32 @reference_loop(i32 %n) noinline {
entry:
  %slot = alloca i32, align 4
  store i32 0, ptr %slot, align 4
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %s = call ptr @llvm.invariant.start.p0(i64 4, ptr %slot)
  %cur = load i32, ptr %slot, align 4
  call void @llvm.invariant.end.p0(ptr %s, i64 4, ptr %slot)
  %next = add i32 %cur, 1
  store i32 %next, ptr %slot, align 4
  %i1 = add i32 %i, 1
  %more = icmp slt i32 %i1, %n
  br i1 %more, label %loop, label %done

done:
  %out = load i32, ptr %slot, align 4
  ret i32 %out
}

define i32 @protected_loop(i32 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  %slot = alloca i32, align 4
  store i32 0, ptr %slot, align 4
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %s = call ptr @llvm.invariant.start.p0(i64 4, ptr %slot)
  %cur = load i32, ptr %slot, align 4
  call void @llvm.invariant.end.p0(ptr %s, i64 4, ptr %slot)
  %next = add i32 %cur, 1
  store i32 %next, ptr %slot, align 4
  %i1 = add i32 %i, 1
  %more = icmp slt i32 %i1, %n
  br i1 %more, label %loop, label %done

done:
  %out = load i32, ptr %slot, align 4
  ret i32 %out
}

define i32 @reference_tail(i32 %x) noinline {
entry:
  %slot = alloca i32, align 4
  store i32 %x, ptr %slot, align 4
  %s = tail call ptr @llvm.invariant.start.p0(i64 4, ptr %slot)
  %v = load i32, ptr %slot, align 4
  tail call void @llvm.invariant.end.p0(ptr %s, i64 4, ptr %slot)
  ret i32 %v
}

define i32 @protected_tail(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %slot = alloca i32, align 4
  store i32 %x, ptr %slot, align 4
  %s = tail call ptr @llvm.invariant.start.p0(i64 4, ptr %slot)
  %v = load i32, ptr %slot, align 4
  tail call void @llvm.invariant.end.p0(ptr %s, i64 4, ptr %slot)
  ret i32 %v
}

; ----- negatives -----

define ptr @unsupported_escape(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %s = call ptr @llvm.invariant.start.p0(i64 4, ptr %p)
  ret ptr %s
}

define void @unsupported_unpaired_end(ptr %p, ptr %tok) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.invariant.end.p0(ptr %tok, i64 4, ptr %p)
  ret void
}

define i32 @unsupported_poison(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %s = call ptr @llvm.invariant.start.p0(i64 4, ptr poison)
  ret i32 0
}

define i32 @unsupported_undef(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %s = call ptr @llvm.invariant.start.p0(i64 4, ptr undef)
  ret i32 0
}

define i32 @unsupported_as1_arg(ptr addrspace(1) %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %s = call ptr @llvm.invariant.start.p1(i64 4, ptr addrspace(1) %p)
  ret i32 0
}

define i32 @unsupported_as1_call() noinline optnone {
entry:
  call void @hikari_vmp()
  %s = call ptr @llvm.invariant.start.p1(i64 4, ptr addrspace(1) @g_as1)
  ret i32 0
}

define ptr @unsupported_musttail(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %s = musttail call ptr @llvm.invariant.start.p0(i64 4, ptr %p)
  ret ptr %s
}

define ptr @unsupported_bundle(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %s = call ptr @llvm.invariant.start.p0(i64 4, ptr %p) [ "deopt"(i32 0) ]
  ret ptr %s
}

define ptr @unsupported_fastcc(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %s = call fastcc ptr @llvm.invariant.start.p0(i64 4, ptr %p)
  ret ptr %s
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

define void @unsupported_sret(ptr sret(i32) %p, ptr byval(i32) %q) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @ext_sret_byval(ptr sret(i32) %p, ptr byval(i32) %q)
  ret void
}

define i32 @main() {
entry:
  %em = call i32 @reference_mem(i32 7)
  %pm = call i32 @protected_mem(i32 7)
  %okm = icmp eq i32 %em, %pm
  %ep = call i32 @reference_pair(i32 42)
  %pp = call i32 @protected_pair(i32 42)
  %okp = icmp eq i32 %ep, %pp
  %ephi = call i32 @reference_phi(i1 true, i32 3, i32 9)
  %pphi = call i32 @protected_phi(i1 true, i32 3, i32 9)
  %okphi = icmp eq i32 %ephi, %pphi
  %ephi2 = call i32 @reference_phi(i1 false, i32 3, i32 9)
  %pphi2 = call i32 @protected_phi(i1 false, i32 3, i32 9)
  %okphi2 = icmp eq i32 %ephi2, %pphi2
  %el = call i32 @reference_loop(i32 4)
  %pl = call i32 @protected_loop(i32 4)
  %okl = icmp eq i32 %el, %pl
  %et = call i32 @reference_tail(i32 11)
  %pt = call i32 @protected_tail(i32 11)
  %okt = icmp eq i32 %et, %pt
  %t0 = and i1 %okm, %okp
  %t1 = and i1 %t0, %okphi
  %t2 = and i1 %t1, %okphi2
  %t3 = and i1 %t2, %okl
  %ok = and i1 %t3, %okt
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

!0 = !{}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_escape: unsupported invariant.start
; SKIP-DAG: Skipping VMP on unsupported_unpaired_end: unsupported invariant.end
; SKIP-DAG: Skipping VMP on unsupported_poison: unsupported invariant.start
; SKIP-DAG: Skipping VMP on unsupported_undef: unsupported invariant.start
; SKIP-DAG: Skipping VMP on unsupported_as1_arg: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_as1_call: unsupported invariant.start
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported invariant.start
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported invariant.start
; SKIP-DAG: Skipping VMP on unsupported_indirect: indirect call
; SKIP-DAG: Skipping VMP on unsupported_vararg: variadic call
; SKIP-DAG: Skipping VMP on unsupported_sret: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_mem:
; SKIP-NOT: Skipping VMP on protected_pair:
; SKIP-NOT: Skipping VMP on protected_phi:
; SKIP-NOT: Skipping VMP on protected_loop:
; SKIP-NOT: Skipping VMP on protected_tail:

; VIRT: define i32 @protected_mem({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call void @hikari_vmp()
; VIRT-NOT: @llvm.invariant.start
; VIRT-NOT: @llvm.invariant.end
; VIRT-NOT: !invariant.load
; VIRT-NOT: !invariant.group
; VIRT: }
; VIRT: define i32 @protected_pair({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: @llvm.invariant.start
; VIRT-NOT: @llvm.invariant.end
; VIRT: }
; VIRT: define i32 @protected_phi({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: @llvm.invariant.start
; VIRT-NOT: @llvm.invariant.end
; VIRT: }
; VIRT: define i32 @protected_loop({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: @llvm.invariant.start
; VIRT-NOT: @llvm.invariant.end
; VIRT: }
; VIRT: define i32 @protected_tail({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: @llvm.invariant.start
; VIRT-NOT: @llvm.invariant.end
; VIRT: }
; VIRT: define {{.*}} @unsupported_escape({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_unpaired_end({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_poison({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_undef({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_as1_arg({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_as1_call({{.*}} #[[UNSUP]] {
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
; VIRT: define {{.*}} @unsupported_sret({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPMUST]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPMUST]] = { {{.*}}"hikari.vmp.selected"
; VIRT-NOT: attributes #[[UNSUPVAR]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
