; Restricted AArch64 VMP ptrtoint / inttoptr:
;   ptrtoint addrspace(0) ptr -> i64
;   inttoptr i64 -> addrspace(0) ptr
; Paired VMOpcode::PtrToInt / IntToPtr replay CreatePtrToInt /
; CreateIntToPtr across the existing pointer and i64 integer VReg
; frames.  No provenance fold, no bitcast substitute.  Results feed
; GEP, load/store, icmp, select, phi, and permitted direct/indirect
; calls.  Non-AS0, non-i64, vectors, aggregates, non-integral AS,
; and addrspacecast stay rejected (existing cast skip strings).
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

@gcell = global [2 x i32] [i32 11, i32 22], align 4

declare void @hikari_vmp()

define i32 @add1(ptr %p) noinline {
entry:
  %v = load i32, ptr %p, align 4
  %r = add i32 %v, 1
  ret i32 %r
}

define i32 @add2(ptr %p) noinline {
entry:
  %v = load i32, ptr %p, align 4
  %r = add i32 %v, 2
  ret i32 %r
}

; ---- argument origin: ptrtoint/inttoptr then load ----
define i32 @reference_arg(ptr %p) {
entry:
  %i = ptrtoint ptr %p to i64
  %q = inttoptr i64 %i to ptr
  %v = load i32, ptr %q, align 4
  ret i32 %v
}

define i32 @protected_arg(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %i = ptrtoint ptr %p to i64
  %q = inttoptr i64 %i to ptr
  %v = load i32, ptr %q, align 4
  ret i32 %v
}

; ---- alloca origin + round-trip integer identity ----
define i32 @reference_alloca(i32 %x) {
entry:
  %slot = alloca i32, align 4
  store i32 %x, ptr %slot, align 4
  %i0 = ptrtoint ptr %slot to i64
  %q = inttoptr i64 %i0 to ptr
  %i1 = ptrtoint ptr %q to i64
  %same = icmp eq i64 %i0, %i1
  %adj = select i1 %same, i32 0, i32 100
  %v = load i32, ptr %q, align 4
  %r = add i32 %v, %adj
  ret i32 %r
}

define i32 @protected_alloca(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %slot = alloca i32, align 4
  store i32 %x, ptr %slot, align 4
  %i0 = ptrtoint ptr %slot to i64
  %q = inttoptr i64 %i0 to ptr
  %i1 = ptrtoint ptr %q to i64
  %same = icmp eq i64 %i0, %i1
  %adj = select i1 %same, i32 0, i32 100
  %v = load i32, ptr %q, align 4
  %r = add i32 %v, %adj
  ret i32 %r
}

; ---- global origin ----
define i32 @reference_global() {
entry:
  %p = getelementptr inbounds [2 x i32], ptr @gcell, i64 0, i64 0
  %i = ptrtoint ptr %p to i64
  %q = inttoptr i64 %i to ptr
  %v = load i32, ptr %q, align 4
  ret i32 %v
}

define i32 @protected_global() noinline optnone {
entry:
  call void @hikari_vmp()
  %p = getelementptr inbounds [2 x i32], ptr @gcell, i64 0, i64 0
  %i = ptrtoint ptr %p to i64
  %q = inttoptr i64 %i to ptr
  %v = load i32, ptr %q, align 4
  ret i32 %v
}

; ---- GEP origin, then conversion-fed GEP + store/load ----
define i32 @reference_gep(ptr %base) {
entry:
  %p1 = getelementptr inbounds i32, ptr %base, i64 1
  %i = ptrtoint ptr %p1 to i64
  %q = inttoptr i64 %i to ptr
  store i32 7, ptr %q, align 4
  %p1b = getelementptr inbounds i32, ptr %q, i64 0
  %v = load i32, ptr %p1b, align 4
  ret i32 %v
}

define i32 @protected_gep(ptr %base) noinline optnone {
entry:
  call void @hikari_vmp()
  %p1 = getelementptr inbounds i32, ptr %base, i64 1
  %i = ptrtoint ptr %p1 to i64
  %q = inttoptr i64 %i to ptr
  store i32 7, ptr %q, align 4
  %p1b = getelementptr inbounds i32, ptr %q, i64 0
  %v = load i32, ptr %p1b, align 4
  ret i32 %v
}

; ---- conversion-fed icmp / select / phi / direct + indirect call ----
define i32 @reference_flow(ptr %p, i1 %c) {
entry:
  %i = ptrtoint ptr %p to i64
  %q0 = inttoptr i64 %i to ptr
  %q1 = inttoptr i64 %i to ptr
  %ps = select i1 %c, ptr %q0, ptr %q1
  br i1 %c, label %t, label %f
t:
  br label %j
f:
  br label %j
j:
  %pj = phi ptr [ %q0, %t ], [ %q1, %f ]
  %eq = icmp eq ptr %pj, %ps
  %adj = select i1 %eq, i32 0, i32 50
  %d = call i32 @add1(ptr %pj)
  %fp = select i1 %c, ptr @add1, ptr @add2
  %ind = call i32 %fp(ptr %ps)
  %s0 = add i32 %d, %ind
  %s1 = add i32 %s0, %adj
  ret i32 %s1
}

define i32 @protected_flow(ptr %p, i1 %c) noinline optnone {
entry:
  call void @hikari_vmp()
  %i = ptrtoint ptr %p to i64
  %q0 = inttoptr i64 %i to ptr
  %q1 = inttoptr i64 %i to ptr
  %ps = select i1 %c, ptr %q0, ptr %q1
  br i1 %c, label %t, label %f
t:
  br label %j
f:
  br label %j
j:
  %pj = phi ptr [ %q0, %t ], [ %q1, %f ]
  %eq = icmp eq ptr %pj, %ps
  %adj = select i1 %eq, i32 0, i32 50
  %d = call i32 @add1(ptr %pj)
  %fp = select i1 %c, ptr @add1, ptr @add2
  %ind = call i32 %fp(ptr %ps)
  %s0 = add i32 %d, %ind
  %s1 = add i32 %s0, %adj
  ret i32 %s1
}

; ---- negatives: selected, not virtualized ----
define i32 @unsupported_ptrtoint_i32(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %i = ptrtoint ptr %p to i32
  ret i32 %i
}

define i8 @unsupported_ptrtoint_i8(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %i = ptrtoint ptr %p to i8
  ret i8 %i
}

define i128 @unsupported_ptrtoint_i128(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %i = ptrtoint ptr %p to i128
  ret i128 %i
}

define ptr @unsupported_inttoptr_i32(i32 %i) noinline optnone {
entry:
  call void @hikari_vmp()
  %p = inttoptr i32 %i to ptr
  ret ptr %p
}

define ptr @unsupported_inttoptr_i128(i128 %i) noinline optnone {
entry:
  call void @hikari_vmp()
  %p = inttoptr i128 %i to ptr
  ret ptr %p
}

define i64 @unsupported_ptrtoint_as1(ptr addrspace(1) %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %i = ptrtoint ptr addrspace(1) %p to i64
  ret i64 %i
}

define ptr addrspace(1) @unsupported_inttoptr_as1(i64 %i) noinline optnone {
entry:
  call void @hikari_vmp()
  %p = inttoptr i64 %i to ptr addrspace(1)
  ret ptr addrspace(1) %p
}

define i64 @unsupported_inttoptr_as1_body(i64 %i) noinline optnone {
entry:
  call void @hikari_vmp()
  %p = inttoptr i64 %i to ptr addrspace(1)
  %x = ptrtoint ptr addrspace(1) %p to i64
  ret i64 %x
}

define <2 x i64> @unsupported_ptrtoint_vec(<2 x ptr> %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %i = ptrtoint <2 x ptr> %p to <2 x i64>
  ret <2 x i64> %i
}

define <2 x ptr> @unsupported_inttoptr_vec(<2 x i64> %i) noinline optnone {
entry:
  call void @hikari_vmp()
  %p = inttoptr <2 x i64> %i to <2 x ptr>
  ret <2 x ptr> %p
}

define ptr @unsupported_addrspacecast(ptr addrspace(1) %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %q = addrspacecast ptr addrspace(1) %p to ptr
  ret ptr %q
}

define i32 @main() {
entry:
  %buf = alloca [2 x i32], align 4
  %p0 = getelementptr inbounds [2 x i32], ptr %buf, i64 0, i64 0
  %p1 = getelementptr inbounds [2 x i32], ptr %buf, i64 0, i64 1
  store i32 41, ptr %p0, align 4
  store i32 0, ptr %p1, align 4

  %e0 = call i32 @reference_arg(ptr %p0)
  %a0 = call i32 @protected_arg(ptr %p0)
  %c0 = icmp eq i32 %e0, %a0

  %e1 = call i32 @reference_alloca(i32 13)
  %a1 = call i32 @protected_alloca(i32 13)
  %c1 = icmp eq i32 %e1, %a1

  %e2 = call i32 @reference_global()
  %a2 = call i32 @protected_global()
  %c2 = icmp eq i32 %e2, %a2

  store i32 0, ptr %p1, align 4
  %e3 = call i32 @reference_gep(ptr %p0)
  store i32 0, ptr %p1, align 4
  %a3 = call i32 @protected_gep(ptr %p0)
  %c3 = icmp eq i32 %e3, %a3

  store i32 20, ptr %p0, align 4
  %e4 = call i32 @reference_flow(ptr %p0, i1 true)
  store i32 20, ptr %p0, align 4
  %a4 = call i32 @protected_flow(ptr %p0, i1 true)
  %c4 = icmp eq i32 %e4, %a4

  store i32 20, ptr %p0, align 4
  %e5 = call i32 @reference_flow(ptr %p0, i1 false)
  store i32 20, ptr %p0, align 4
  %a5 = call i32 @protected_flow(ptr %p0, i1 false)
  %c5 = icmp eq i32 %e5, %a5

  %t0 = and i1 %c0, %c1
  %t1 = and i1 %c2, %c3
  %t2 = and i1 %c4, %c5
  %t3 = and i1 %t0, %t1
  %ok = and i1 %t3, %t2
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_ptrtoint_i32: unsupported cast instruction
; SKIP-DAG: Skipping VMP on unsupported_ptrtoint_i8: unsupported cast instruction
; SKIP-DAG: Skipping VMP on unsupported_ptrtoint_i128: unsupported cast instruction
; SKIP-DAG: Skipping VMP on unsupported_inttoptr_i32: unsupported cast instruction
; SKIP-DAG: Skipping VMP on unsupported_inttoptr_i128: unsupported cast instruction
; SKIP-DAG: Skipping VMP on unsupported_ptrtoint_as1: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_inttoptr_as1: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_inttoptr_as1_body: unsupported cast instruction
; SKIP-DAG: Skipping VMP on unsupported_ptrtoint_vec: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_inttoptr_vec: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_addrspacecast: unsupported argument type
; SKIP-NOT: Skipping VMP on protected_arg:
; SKIP-NOT: Skipping VMP on protected_alloca:
; SKIP-NOT: Skipping VMP on protected_global:
; SKIP-NOT: Skipping VMP on protected_gep:
; SKIP-NOT: Skipping VMP on protected_flow:

; VIRT-DAG: define i32 @protected_arg({{.*}} #[[PROT:[0-9]+]] {
; VIRT-DAG: define i32 @protected_alloca(
; VIRT-DAG: define i32 @protected_global(
; VIRT-DAG: define i32 @protected_gep(
; VIRT-DAG: define i32 @protected_flow(
; VIRT-DAG: vmp.dispatch:
; VIRT-DAG: ptrtoint ptr {{.*}} to i64
; VIRT-DAG: inttoptr i64 {{.*}} to ptr
; VIRT-DAG: define {{.*}} @unsupported_ptrtoint_i32({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-DAG: define {{.*}} @unsupported_ptrtoint_i8({{.*}} #[[UNSUP]] {
; VIRT-DAG: define {{.*}} @unsupported_ptrtoint_i128({{.*}} #[[UNSUP]] {
; VIRT-DAG: define {{.*}} @unsupported_inttoptr_i32({{.*}} #[[UNSUP]] {
; VIRT-DAG: define {{.*}} @unsupported_inttoptr_i128({{.*}} #[[UNSUP]] {
; VIRT-DAG: define {{.*}} @unsupported_ptrtoint_as1({{.*}} #[[UNSUP]] {
; VIRT-DAG: define {{.*}} @unsupported_inttoptr_as1({{.*}} #[[UNSUP]] {
; VIRT-DAG: define {{.*}} @unsupported_inttoptr_as1_body({{.*}} #[[UNSUP]] {
; VIRT-DAG: define {{.*}} @unsupported_ptrtoint_vec({{.*}} #[[UNSUP]] {
; VIRT-DAG: define {{.*}} @unsupported_inttoptr_vec({{.*}} #[[UNSUP]] {
; VIRT-DAG: define {{.*}} @unsupported_addrspacecast({{.*}} #[[UNSUP]] {
; VIRT-DAG: ptrtoint ptr {{.*}} to i32
; VIRT-DAG: addrspacecast ptr addrspace(1)
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; HOST: Skipping VMP: only AArch64 targets are supported
