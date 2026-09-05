; Restricted same-function jump-table indirectbr: load ptr from a
; private/internal constant [1..16 x ptr] of this function's
; blockaddresses (or a two-index GEP of that table).  Replay is the
; existing IndirectBr handler.  Planning rewrites table slots to
; __hikari_vmp_ba.* labels so deleteBody cannot dangle.
; External-linkage tables, and private tables exported by an
; external global or alias, stay "unsupported indirectbr" —
; rewriting them would change a cross-module interface.
; inttoptr / PHI dests stay on vmp-indirectbr.ll.
;
; FileCheck + host lli + AArch64 llc/readobj.  O0/O2 x 97/7.
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
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %s | opt -S -verify-each -aesSeed=97 -passes='default<O0>' - 2>&1 | FileCheck %s --check-prefix=HOST
; RUN: opt -S -verify-each -aesSeed=97 -vmp-max-bytecode-words=1 -passes='default<O0>' %s -o %t.budget.ll 2>%t.budget.err
; RUN: FileCheck %s --check-prefix=BUDGET-ERR < %t.budget.err
; RUN: FileCheck %s --check-prefix=BUDGET-IR < %t.budget.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()

@jt.reference = private unnamed_addr constant [3 x ptr] [
  ptr blockaddress(@reference, %L0),
  ptr blockaddress(@reference, %L1),
  ptr blockaddress(@reference, %L2)
]

@jt.protected = private unnamed_addr constant [3 x ptr] [
  ptr blockaddress(@protected, %L0),
  ptr blockaddress(@protected, %L1),
  ptr blockaddress(@protected, %L2)
]

@jt.constidx = private unnamed_addr constant [2 x ptr] [
  ptr blockaddress(@protected_constidx, %A),
  ptr blockaddress(@protected_constidx, %B)
]

@jt.foreign = private unnamed_addr constant [2 x ptr] [
  ptr blockaddress(@foreign_target, %T),
  ptr blockaddress(@foreign_target, %U)
]

@jt.shared = private unnamed_addr constant [2 x ptr] [
  ptr blockaddress(@shared_observer, %Keep),
  ptr blockaddress(@shared_observer, %Keep)
]

@jt.volatile = private unnamed_addr constant [3 x ptr] [
  ptr blockaddress(@reference, %L0),
  ptr blockaddress(@reference, %L1),
  ptr blockaddress(@reference, %L2)
]

; External linkage is the only reject: same-function BAs, single user,
; non-volatile load, dests listed.  drop-unsupported strips this
; global with the function so live llc does not see a dangling BA.
@jt.external = constant [3 x ptr] [
  ptr blockaddress(@unsupported_external, %L0),
  ptr blockaddress(@unsupported_external, %L1),
  ptr blockaddress(@unsupported_external, %L2)
]

; Private table, same-function BAs, only instruction user is F — but
; an external pointer global publishes the table address.
@jt.unsupported_leaked = private unnamed_addr constant [3 x ptr] [
  ptr blockaddress(@unsupported_export_proxy, %L0),
  ptr blockaddress(@unsupported_export_proxy, %L1),
  ptr blockaddress(@unsupported_export_proxy, %L2)
]
@jt.unsupported_export = constant ptr @jt.unsupported_leaked

; Private table published by an external alias.
@jt.unsupported_aliased = private unnamed_addr constant [3 x ptr] [
  ptr blockaddress(@unsupported_alias_proxy, %L0),
  ptr blockaddress(@unsupported_alias_proxy, %L1),
  ptr blockaddress(@unsupported_alias_proxy, %L2)
]
@jt.unsupported_alias = alias [3 x ptr], ptr @jt.unsupported_aliased

; Keep the unused proxies alive through O2 so the leak is still visible
; at VMP eligibility.
@llvm.compiler.used = appending global [2 x ptr] [ptr @jt.unsupported_export, ptr @jt.unsupported_alias], section "llvm.metadata"

define i32 @reference(i32 %i) noinline {
entry:
  %idx = zext i32 %i to i64
  %p = getelementptr inbounds [3 x ptr], ptr @jt.reference, i64 0, i64 %idx
  %dest = load ptr, ptr %p, align 8
  indirectbr ptr %dest, [label %L0, label %L1, label %L2]
L0:
  ret i32 10
L1:
  ret i32 20
L2:
  ret i32 30
}

define i32 @protected(i32 %i) noinline optnone {
entry:
  call void @hikari_vmp()
  %idx = zext i32 %i to i64
  %p = getelementptr inbounds [3 x ptr], ptr @jt.protected, i64 0, i64 %idx
  %dest = load ptr, ptr %p, align 8
  indirectbr ptr %dest, [label %L0, label %L1, label %L2]
L0:
  ret i32 10
L1:
  ret i32 20
L2:
  ret i32 30
}

define i32 @protected_constidx() noinline optnone {
entry:
  call void @hikari_vmp()
  %dest = load ptr, ptr getelementptr inbounds ([2 x ptr], ptr @jt.constidx, i64 0, i64 1), align 8
  indirectbr ptr %dest, [label %A, label %B]
A:
  ret i32 1
B:
  ret i32 2
}

define void @foreign_target() {
entry:
  br label %T
T:
  br label %U
U:
  ret void
}

define i32 @unsupported_foreign(i32 %i) noinline optnone {
entry:
  call void @hikari_vmp()
  %idx = zext i32 %i to i64
  %p = getelementptr inbounds [2 x ptr], ptr @jt.foreign, i64 0, i64 %idx
  %dest = load ptr, ptr %p, align 8
  indirectbr ptr %dest, [label %A, label %B]
A:
  ret i32 1
B:
  ret i32 2
}

define ptr @shared_observer() noinline {
entry:
  br label %Keep
Keep:
  %p = load ptr, ptr @jt.shared, align 8
  ret ptr %p
}

define i32 @unsupported_shared(i32 %i) noinline optnone {
entry:
  call void @hikari_vmp()
  %idx = zext i32 %i to i64
  %p = getelementptr inbounds [2 x ptr], ptr @jt.shared, i64 0, i64 %idx
  %dest = load ptr, ptr %p, align 8
  indirectbr ptr %dest, [label %A, label %B]
A:
  ret i32 1
B:
  ret i32 2
}

define i32 @unsupported_volatile(i32 %i) noinline optnone {
entry:
  call void @hikari_vmp()
  %idx = zext i32 %i to i64
  %p = getelementptr inbounds [3 x ptr], ptr @jt.volatile, i64 0, i64 %idx
  %dest = load volatile ptr, ptr %p, align 8
  indirectbr ptr %dest, [label %L0, label %L1, label %L2]
L0:
  ret i32 10
L1:
  ret i32 20
L2:
  ret i32 30
}

define i32 @unsupported_external(i32 %i) noinline optnone {
entry:
  call void @hikari_vmp()
  %idx = zext i32 %i to i64
  %p = getelementptr inbounds [3 x ptr], ptr @jt.external, i64 0, i64 %idx
  %dest = load ptr, ptr %p, align 8
  indirectbr ptr %dest, [label %L0, label %L1, label %L2]
L0:
  ret i32 10
L1:
  ret i32 20
L2:
  ret i32 30
}

define i32 @unsupported_export_proxy(i32 %i) noinline optnone {
entry:
  call void @hikari_vmp()
  %idx = zext i32 %i to i64
  %p = getelementptr inbounds [3 x ptr], ptr @jt.unsupported_leaked, i64 0, i64 %idx
  %dest = load ptr, ptr %p, align 8
  indirectbr ptr %dest, [label %L0, label %L1, label %L2]
L0:
  ret i32 10
L1:
  ret i32 20
L2:
  ret i32 30
}

define i32 @unsupported_alias_proxy(i32 %i) noinline optnone {
entry:
  call void @hikari_vmp()
  %idx = zext i32 %i to i64
  %p = getelementptr inbounds [3 x ptr], ptr @jt.unsupported_aliased, i64 0, i64 %idx
  %dest = load ptr, ptr %p, align 8
  indirectbr ptr %dest, [label %L0, label %L1, label %L2]
L0:
  ret i32 10
L1:
  ret i32 20
L2:
  ret i32 30
}

define i32 @main() {
entry:
  %e0 = call i32 @reference(i32 0)
  %a0 = call i32 @protected(i32 0)
  %e1 = call i32 @reference(i32 1)
  %a1 = call i32 @protected(i32 1)
  %e2 = call i32 @reference(i32 2)
  %a2 = call i32 @protected(i32 2)
  %c = call i32 @protected_constidx()
  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %e1, %a1
  %m2 = icmp eq i32 %e2, %a2
  %m3 = icmp eq i32 %c, 2
  %t0 = and i1 %m0, %m1
  %t1 = and i1 %m2, %m3
  %ok = and i1 %t0, %t1
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_foreign: unsupported indirectbr instruction
; SKIP-DAG: Skipping VMP on unsupported_shared: unsupported indirectbr instruction
; SKIP-DAG: Skipping VMP on unsupported_volatile: unsupported indirectbr instruction
; SKIP-DAG: Skipping VMP on unsupported_external: unsupported indirectbr instruction
; SKIP-DAG: Skipping VMP on unsupported_export_proxy: unsupported indirectbr instruction
; SKIP-DAG: Skipping VMP on unsupported_alias_proxy: unsupported indirectbr instruction
; SKIP-NOT: Skipping VMP on protected:
; SKIP-NOT: Skipping VMP on protected_constidx:
; SKIP-NOT: Skipping VMP on reference:

; VIRT: @jt.protected = {{.*}}__hikari_vmp_ba.protected.
; VIRT: @jt.external = {{.*}}blockaddress(@unsupported_external,
; VIRT-NOT: @jt.external = {{.*}}__hikari_vmp_ba
; VIRT: @jt.unsupported_leaked = {{.*}}blockaddress(@unsupported_export_proxy,
; VIRT-NOT: @jt.unsupported_leaked = {{.*}}__hikari_vmp_ba
; VIRT: @jt.unsupported_aliased = {{.*}}blockaddress(@unsupported_alias_proxy,
; VIRT-NOT: @jt.unsupported_aliased = {{.*}}__hikari_vmp_ba
; VIRT-LABEL: define i32 @protected(
; VIRT-SAME: #[[PROT:[0-9]+]]
; VIRT: vmp.dispatch:
; VIRT-DAG: icmp eq ptr
; VIRT-DAG: __hikari_vmp_ba.protected.
; VIRT-LABEL: define i32 @protected_constidx(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: define {{.*}} @unsupported_foreign({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_shared({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_volatile({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_external({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_export_proxy({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_alias_proxy({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; HOST: Skipping VMP: only AArch64 targets are supported
; BUDGET-ERR: Skipping VMP on protected: bytecode word budget
; BUDGET-IR: @jt.protected = {{.*}}blockaddress(@protected,
; BUDGET-IR-NOT: __hikari_vmp_ba.protected.
