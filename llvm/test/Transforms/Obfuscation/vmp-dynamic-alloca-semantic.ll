; Restricted entry-block dynamic alloca: AS0, sized scalar allocated
; type, explicit alignment.  Array count is a direct i32/i64 argument
; or a pure entry-block integer DAG that already has an integer VReg
; (args/constants, add/sub/mul, div/rem, bitwise, shifts, trunc/zext/
; sext, icmp, select; nuw/nsw/exact preserved).  Dedicated
; VMOpcode::DynamicAlloca loads that count and CreateAlloca in the
; interpreter execution path (not the static-alloca prologue).
; Constant/static alloca is unchanged.  Load/call-derived counts,
; non-entry, aggregate/vector/AS1 elements, and stacksave/restore /
; get.dynamic.area.offset combos stay skipped.
; reference_icmp / protected_icmp cover a real ICmp size-DAG node:
; urem by a nonzero constant, icmp feeding select, plus an add.
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
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %s | opt -S -verify-each -aesSeed=97 -passes='default<O0>' - 2>&1 | FileCheck %s --check-prefix=HOST

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare ptr @llvm.stacksave()
declare void @llvm.stackrestore(ptr)
declare i64 @llvm.get.dynamic.area.offset.i64()
declare i64 @opaque_dyn_count(i64)

define i32 @reference(i64 %n) noinline optnone {
entry:
  %p = alloca i32, i64 %n, align 4
  br label %loop

loop:
  %i = phi i64 [ 0, %entry ], [ %i.next, %loop ]
  %acc = phi i32 [ 0, %entry ], [ %acc.next, %loop ]
  %slot = getelementptr inbounds i32, ptr %p, i64 %i
  %iv = trunc i64 %i to i32
  %val = add i32 %iv, 11
  store i32 %val, ptr %slot, align 4
  %ld = load i32, ptr %slot, align 4
  %acc.next = xor i32 %acc, %ld
  %i.next = add i64 %i, 1
  %more = icmp ult i64 %i.next, %n
  br i1 %more, label %loop, label %done

done:
  ret i32 %acc.next
}

define i32 @protected(i64 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  %p = alloca i32, i64 %n, align 4
  br label %loop

loop:
  %i = phi i64 [ 0, %entry ], [ %i.next, %loop ]
  %acc = phi i32 [ 0, %entry ], [ %acc.next, %loop ]
  %slot = getelementptr inbounds i32, ptr %p, i64 %i
  %iv = trunc i64 %i to i32
  %val = add i32 %iv, 11
  store i32 %val, ptr %slot, align 4
  %ld = load i32, ptr %slot, align 4
  %acc.next = xor i32 %acc, %ld
  %i.next = add i64 %i, 1
  %more = icmp ult i64 %i.next, %n
  br i1 %more, label %loop, label %done

done:
  ret i32 %acc.next
}

define i32 @reference_plus1(i64 %n) noinline optnone {
entry:
  %n1 = add nuw nsw i64 %n, 1
  %p = alloca i32, i64 %n1, align 4
  br label %loop

loop:
  %i = phi i64 [ 0, %entry ], [ %i.next, %loop ]
  %acc = phi i32 [ 0, %entry ], [ %acc.next, %loop ]
  %slot = getelementptr inbounds i32, ptr %p, i64 %i
  %iv = trunc i64 %i to i32
  %val = add i32 %iv, 11
  store i32 %val, ptr %slot, align 4
  %ld = load i32, ptr %slot, align 4
  %acc.next = xor i32 %acc, %ld
  %i.next = add i64 %i, 1
  %more = icmp ult i64 %i.next, %n1
  br i1 %more, label %loop, label %done

done:
  ret i32 %acc.next
}

define i32 @protected_plus1(i64 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  %n1 = add nuw nsw i64 %n, 1
  %p = alloca i32, i64 %n1, align 4
  br label %loop

loop:
  %i = phi i64 [ 0, %entry ], [ %i.next, %loop ]
  %acc = phi i32 [ 0, %entry ], [ %acc.next, %loop ]
  %slot = getelementptr inbounds i32, ptr %p, i64 %i
  %iv = trunc i64 %i to i32
  %val = add i32 %iv, 11
  store i32 %val, ptr %slot, align 4
  %ld = load i32, ptr %slot, align 4
  %acc.next = xor i32 %acc, %ld
  %i.next = add i64 %i, 1
  %more = icmp ult i64 %i.next, %n1
  br i1 %more, label %loop, label %done

done:
  ret i32 %acc.next
}

define i32 @reference_combo(i32 %n, i1 %wide) noinline optnone {
entry:
  %n8 = trunc i32 %n to i8
  %n64 = zext i8 %n8 to i64
  %dbl = shl nuw nsw i64 %n64, 1
  %half = lshr exact i64 %dbl, 1
  %cnt = select i1 %wide, i64 %dbl, i64 %half
  %p = alloca i32, i64 %cnt, align 4
  br label %loop

loop:
  %i = phi i64 [ 0, %entry ], [ %i.next, %loop ]
  %acc = phi i32 [ 0, %entry ], [ %acc.next, %loop ]
  %slot = getelementptr inbounds i32, ptr %p, i64 %i
  %iv = trunc i64 %i to i32
  %val = add i32 %iv, 11
  store i32 %val, ptr %slot, align 4
  %ld = load i32, ptr %slot, align 4
  %acc.next = xor i32 %acc, %ld
  %i.next = add i64 %i, 1
  %more = icmp ult i64 %i.next, %cnt
  br i1 %more, label %loop, label %done

done:
  ret i32 %acc.next
}

define i32 @protected_combo(i32 %n, i1 %wide) noinline optnone {
entry:
  call void @hikari_vmp()
  %n8 = trunc i32 %n to i8
  %n64 = zext i8 %n8 to i64
  %dbl = shl nuw nsw i64 %n64, 1
  %half = lshr exact i64 %dbl, 1
  %cnt = select i1 %wide, i64 %dbl, i64 %half
  %p = alloca i32, i64 %cnt, align 4
  br label %loop

loop:
  %i = phi i64 [ 0, %entry ], [ %i.next, %loop ]
  %acc = phi i32 [ 0, %entry ], [ %acc.next, %loop ]
  %slot = getelementptr inbounds i32, ptr %p, i64 %i
  %iv = trunc i64 %i to i32
  %val = add i32 %iv, 11
  store i32 %val, ptr %slot, align 4
  %ld = load i32, ptr %slot, align 4
  %acc.next = xor i32 %acc, %ld
  %i.next = add i64 %i, 1
  %more = icmp ult i64 %i.next, %cnt
  br i1 %more, label %loop, label %done

done:
  ret i32 %acc.next
}

; Size = (n urem 3) == 0 ? 5 : (n urem 3) + 2.  Inputs 3 and 4 yield
; counts 5 and 3 (positive, small, distinct).  The loop writes/reads
; every slot so main compares both memory-derived checksums and rets.
define i32 @reference_icmp(i64 %n) noinline optnone {
entry:
  %rem = urem i64 %n, 3
  %is0 = icmp eq i64 %rem, 0
  %adj = add nuw nsw i64 %rem, 2
  %cnt = select i1 %is0, i64 5, i64 %adj
  %p = alloca i32, i64 %cnt, align 4
  br label %loop

loop:
  %i = phi i64 [ 0, %entry ], [ %i.next, %loop ]
  %acc = phi i32 [ 0, %entry ], [ %acc.next, %loop ]
  %slot = getelementptr inbounds i32, ptr %p, i64 %i
  %iv = trunc i64 %i to i32
  %val = add i32 %iv, 11
  store i32 %val, ptr %slot, align 4
  %ld = load i32, ptr %slot, align 4
  %acc.next = xor i32 %acc, %ld
  %i.next = add i64 %i, 1
  %more = icmp ult i64 %i.next, %cnt
  br i1 %more, label %loop, label %done

done:
  ret i32 %acc.next
}

define i32 @protected_icmp(i64 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  %rem = urem i64 %n, 3
  %is0 = icmp eq i64 %rem, 0
  %adj = add nuw nsw i64 %rem, 2
  %cnt = select i1 %is0, i64 5, i64 %adj
  %p = alloca i32, i64 %cnt, align 4
  br label %loop

loop:
  %i = phi i64 [ 0, %entry ], [ %i.next, %loop ]
  %acc = phi i32 [ 0, %entry ], [ %acc.next, %loop ]
  %slot = getelementptr inbounds i32, ptr %p, i64 %i
  %iv = trunc i64 %i to i32
  %val = add i32 %iv, 11
  store i32 %val, ptr %slot, align 4
  %ld = load i32, ptr %slot, align 4
  %acc.next = xor i32 %acc, %ld
  %i.next = add i64 %i, 1
  %more = icmp ult i64 %i.next, %cnt
  br i1 %more, label %loop, label %done

done:
  ret i32 %acc.next
}

; i32 parameter count (ordinary integer VReg, not i64).
define i32 @reference_i32(i32 %n) noinline optnone {
entry:
  %p = alloca i32, i32 %n, align 4
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %i.next, %loop ]
  %acc = phi i32 [ 0, %entry ], [ %acc.next, %loop ]
  %ie = zext i32 %i to i64
  %slot = getelementptr inbounds i32, ptr %p, i64 %ie
  %val = add i32 %i, 11
  store i32 %val, ptr %slot, align 4
  %ld = load i32, ptr %slot, align 4
  %acc.next = xor i32 %acc, %ld
  %i.next = add i32 %i, 1
  %more = icmp ult i32 %i.next, %n
  br i1 %more, label %loop, label %done

done:
  ret i32 %acc.next
}

define i32 @protected_i32(i32 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  %p = alloca i32, i32 %n, align 4
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %i.next, %loop ]
  %acc = phi i32 [ 0, %entry ], [ %acc.next, %loop ]
  %ie = zext i32 %i to i64
  %slot = getelementptr inbounds i32, ptr %p, i64 %ie
  %val = add i32 %i, 11
  store i32 %val, ptr %slot, align 4
  %ld = load i32, ptr %slot, align 4
  %acc.next = xor i32 %acc, %ld
  %i.next = add i32 %i, 1
  %more = icmp ult i32 %i.next, %n
  br i1 %more, label %loop, label %done

done:
  ret i32 %acc.next
}

; Runtime zero count: LLVM permits alloca of 0 elements.  Do not
; load/store the object; only compare the converted pointer.
define i32 @reference_zero(i64 %n) noinline optnone {
entry:
  %p = alloca i32, i64 %n, align 4
  %i = ptrtoint ptr %p to i64
  %q = inttoptr i64 %i to ptr
  %eq = icmp eq ptr %p, %q
  %r = select i1 %eq, i32 0, i32 1
  ret i32 %r
}

define i32 @protected_zero(i64 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  %p = alloca i32, i64 %n, align 4
  %i = ptrtoint ptr %p to i64
  %q = inttoptr i64 %i to ptr
  %eq = icmp eq ptr %p, %q
  %r = select i1 %eq, i32 0, i32 1
  ret i32 %r
}

; Conversion-fed memory: store/load through inttoptr(ptrtoint(alloca)).
define i32 @reference_conv(i64 %n) noinline optnone {
entry:
  %p = alloca i32, i64 %n, align 4
  %i = ptrtoint ptr %p to i64
  %q = inttoptr i64 %i to ptr
  store i32 42, ptr %q, align 4
  %v = load i32, ptr %p, align 4
  ret i32 %v
}

define i32 @protected_conv(i64 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  %p = alloca i32, i64 %n, align 4
  %i = ptrtoint ptr %p to i64
  %q = inttoptr i64 %i to ptr
  store i32 42, ptr %q, align 4
  %v = load i32, ptr %p, align 4
  ret i32 %v
}

define i32 @unsupported_dyn_alloca_load(ptr %src) noinline optnone {
entry:
  call void @hikari_vmp()
  %c = load i64, ptr %src, align 8
  %p = alloca i32, i64 %c, align 4
  store i32 1, ptr %p, align 4
  %v = load i32, ptr %p, align 4
  ret i32 %v
}

define i32 @unsupported_dyn_alloca_call(i64 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  %c = call i64 @opaque_dyn_count(i64 %n)
  %p = alloca i32, i64 %c, align 4
  store i32 1, ptr %p, align 4
  %v = load i32, ptr %p, align 4
  ret i32 %v
}

define i32 @unsupported_dyn_alloca_nonentry(i64 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  br label %bb

bb:
  %p = alloca i32, i64 %n, align 4
  store i32 1, ptr %p, align 4
  %v = load i32, ptr %p, align 4
  ret i32 %v
}

; Otherwise-legal entry dynamic alloca plus stacksave/restore:
; dynamic-stack-state interaction, so skip.
define i32 @unsupported_dyn_alloca_stackstate(i64 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  %tok = call ptr @llvm.stacksave()
  %p = alloca i32, i64 %n, align 4
  store i32 1, ptr %p, align 4
  call void @llvm.stackrestore(ptr %tok)
  ret i32 0
}

; Otherwise-legal entry dynamic alloca plus get.dynamic.area.offset.i64:
; dynamic-stack-state interaction, so skip.
define i32 @unsupported_dyn_alloca_dynarea(i64 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  %p = alloca i32, i64 %n, align 4
  store i32 1, ptr %p, align 4
  %off = call i64 @llvm.get.dynamic.area.offset.i64()
  %t = trunc i64 %off to i32
  %v = load i32, ptr %p, align 4
  %r = xor i32 %v, %t
  ret i32 %r
}

define i32 @unsupported_dyn_alloca_agg(i64 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  %p = alloca { i32, i32 }, i64 %n, align 8
  ret i32 0
}

define i32 @unsupported_dyn_alloca_vec(i64 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  %p = alloca <2 x i32>, i64 %n, align 8
  ret i32 0
}

define i32 @unsupported_dyn_alloca_as1(i64 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  %p = alloca i32, i64 %n, align 4, addrspace(1)
  ret i32 0
}

define i32 @main() {
entry:
  %e0 = call i32 @reference(i64 3)
  %a0 = call i32 @protected(i64 3)
  %ok0 = icmp eq i32 %e0, %a0
  %e1 = call i32 @reference(i64 5)
  %a1 = call i32 @protected(i64 5)
  %ok1 = icmp eq i32 %e1, %a1
  %e2 = call i32 @reference_plus1(i64 3)
  %a2 = call i32 @protected_plus1(i64 3)
  %ok2 = icmp eq i32 %e2, %a2
  %e3 = call i32 @reference_plus1(i64 5)
  %a3 = call i32 @protected_plus1(i64 5)
  %ok3 = icmp eq i32 %e3, %a3
  %e4 = call i32 @reference_combo(i32 3, i1 false)
  %a4 = call i32 @protected_combo(i32 3, i1 false)
  %ok4 = icmp eq i32 %e4, %a4
  %e5 = call i32 @reference_combo(i32 5, i1 true)
  %a5 = call i32 @protected_combo(i32 5, i1 true)
  %ok5 = icmp eq i32 %e5, %a5
  %e6 = call i32 @reference_icmp(i64 3)
  %a6 = call i32 @protected_icmp(i64 3)
  %ok6 = icmp eq i32 %e6, %a6
  %e7 = call i32 @reference_icmp(i64 4)
  %a7 = call i32 @protected_icmp(i64 4)
  %ok7 = icmp eq i32 %e7, %a7
  %e8 = call i32 @reference_i32(i32 3)
  %a8 = call i32 @protected_i32(i32 3)
  %ok8 = icmp eq i32 %e8, %a8
  %e9 = call i32 @reference_zero(i64 0)
  %a9 = call i32 @protected_zero(i64 0)
  %ok9 = icmp eq i32 %e9, %a9
  %e10 = call i32 @reference_conv(i64 3)
  %a10 = call i32 @protected_conv(i64 3)
  %ok10 = icmp eq i32 %e10, %a10
  %diff = icmp ne i32 %e6, %e7
  %t0 = and i1 %ok0, %ok1
  %t1 = and i1 %ok2, %ok3
  %t2 = and i1 %ok4, %ok5
  %t3 = and i1 %ok6, %ok7
  %t4 = and i1 %ok8, %ok9
  %t5 = and i1 %ok10, %diff
  %t6 = and i1 %t0, %t1
  %t7 = and i1 %t2, %t3
  %t8 = and i1 %t4, %t5
  %t9 = and i1 %t6, %t7
  %ok = and i1 %t8, %t9
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP-DAG: Skipping VMP on unsupported_dyn_alloca_load: unsupported stack allocation
; SKIP-DAG: Skipping VMP on unsupported_dyn_alloca_call: unsupported stack allocation
; SKIP-DAG: Skipping VMP on unsupported_dyn_alloca_nonentry: unsupported stack allocation
; SKIP-DAG: Skipping VMP on unsupported_dyn_alloca_stackstate: dynamic stack state
; SKIP-DAG: Skipping VMP on unsupported_dyn_alloca_dynarea: dynamic stack state
; SKIP-DAG: Skipping VMP on unsupported_dyn_alloca_agg: unsupported stack allocation
; SKIP-DAG: Skipping VMP on unsupported_dyn_alloca_vec: unsupported stack allocation
; SKIP-DAG: Skipping VMP on unsupported_dyn_alloca_as1: unsupported stack allocation
; SKIP-NOT: Skipping VMP on protected:
; SKIP-NOT: Skipping VMP on protected_plus1:
; SKIP-NOT: Skipping VMP on protected_combo:
; SKIP-NOT: Skipping VMP on protected_icmp:
; SKIP-NOT: Skipping VMP on protected_i32:
; SKIP-NOT: Skipping VMP on protected_zero:
; SKIP-NOT: Skipping VMP on protected_conv:
; SKIP-NOT: Skipping VMP on reference:

; VIRT-DAG: define i32 @protected({{.*}} #[[PROT:[0-9]+]] {
; VIRT-DAG: define i32 @protected_plus1(
; VIRT-DAG: define i32 @protected_combo(
; VIRT-DAG: define i32 @protected_icmp(
; VIRT-DAG: define i32 @protected_i32(
; VIRT-DAG: define i32 @protected_zero(
; VIRT-DAG: define i32 @protected_conv(
; VIRT-DAG: vmp.dispatch:
; VIRT-DAG: alloca i32, i64
; VIRT-DAG: alloca i32, i32
; VIRT-DAG: vmp.dyn.stack = alloca
; VIRT-DAG: define {{.*}} @unsupported_dyn_alloca_load({{.*}} #[[UNSUPATTR:[0-9]+]] {
; VIRT-DAG: define {{.*}} @unsupported_dyn_alloca_call({{.*}} #[[UNSUPATTR]] {
; VIRT-DAG: define {{.*}} @unsupported_dyn_alloca_nonentry({{.*}} #[[UNSUPATTR]] {
; VIRT-DAG: define {{.*}} @unsupported_dyn_alloca_stackstate({{.*}} #[[UNSUPATTR]] {
; VIRT-DAG: define {{.*}} @unsupported_dyn_alloca_dynarea({{.*}} #[[UNSUPATTR]] {
; VIRT-DAG: define {{.*}} @unsupported_dyn_alloca_agg({{.*}} #[[UNSUPATTR]] {
; VIRT-DAG: define {{.*}} @unsupported_dyn_alloca_vec({{.*}} #[[UNSUPATTR]] {
; VIRT-DAG: define {{.*}} @unsupported_dyn_alloca_as1({{.*}} #[[UNSUPATTR]] {
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; HOST: Skipping VMP: only AArch64 targets are supported