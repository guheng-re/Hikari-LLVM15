; Thread-local GlobalValues are ordinary AS0 pointer constants.
; clang -O2 `_Thread_local int t; return t+1` is `load i32, ptr @t`.
; The early getUnsupportedReason walk no longer deselects TLS
; operands; the address is stored in a pointer VReg and lowered
; by AArch64 ISel.  The interpreter runs on the same thread.
; No new VM opcode.  A real musttail of another function still
; skips.  Host lli allocates TLS storage but does not apply the
; initializer, so main stores known values before each call.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64

target triple = "aarch64-unknown-linux-gnu"

@tls_i32 = thread_local global i32 1, align 4
@tls_ie = thread_local(initialexec) global i32 10, align 4
@tls_arr = thread_local global [2 x i32] [i32 3, i32 4], align 4

declare void @hikari_vmp()

define i32 @sink_i32(ptr %p, i32 %x) {
entry:
  %v = load i32, ptr %p, align 4
  %r = add i32 %v, %x
  ret i32 %r
}

define i32 @reference_tls_load() {
entry:
  %v = load i32, ptr @tls_i32, align 4
  %r = add i32 %v, 1
  ret i32 %r
}

define i32 @protected_tls_load() noinline optnone {
entry:
  call void @hikari_vmp()
  %v = load i32, ptr @tls_i32, align 4
  %r = add i32 %v, 1
  ret i32 %r
}

define i32 @protected_tls_store(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  store i32 %x, ptr @tls_i32, align 4
  %v = load i32, ptr @tls_i32, align 4
  ret i32 %v
}

define i32 @protected_tls_ie() noinline optnone {
entry:
  call void @hikari_vmp()
  %v = load i32, ptr @tls_ie, align 4
  %r = add i32 %v, 2
  ret i32 %r
}

define i32 @protected_tls_gep() noinline optnone {
entry:
  call void @hikari_vmp()
  %p = getelementptr inbounds [2 x i32], ptr @tls_arr, i64 0, i64 1
  %v = load i32, ptr %p, align 4
  %r = add i32 %v, 3
  ret i32 %r
}

define i32 @protected_tls_addr(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %eq = icmp eq ptr %p, @tls_i32
  %z = zext i1 %eq to i32
  ret i32 %z
}

define i32 @protected_tls_call() noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @sink_i32(ptr @tls_i32, i32 4)
  ret i32 %r
}

define i32 @protected_tls_phi(i1 %c) noinline optnone {
entry:
  call void @hikari_vmp()
  br i1 %c, label %left, label %right
left:
  %l = load i32, ptr @tls_i32, align 4
  br label %join
right:
  %rgt = load i32, ptr @tls_i32, align 4
  br label %join
join:
  %q = phi i32 [ %l, %left ], [ %rgt, %right ]
  %s = add i32 %q, 6
  ret i32 %s
}

define i32 @protected_tls_loop(i32 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %i.next, %loop ]
  %acc = phi i32 [ 0, %entry ], [ %acc.next, %loop ]
  %v = load i32, ptr @tls_i32, align 4
  %acc.next = add i32 %acc, %v
  %i.next = add i32 %i, 1
  %cont = icmp slt i32 %i.next, %n
  br i1 %cont, label %loop, label %done
done:
  %r = add i32 %acc.next, 0
  ret i32 %r
}

define i32 @unsupported_tls_musttail(ptr %p, i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %v = load i32, ptr @tls_i32, align 4
  %sum = add i32 %v, %x
  %r = musttail call i32 @sink_i32(ptr %p, i32 %sum)
  ret i32 %r
}

define i32 @main() {
entry:
  store i32 40, ptr @tls_i32, align 4
  %e0 = call i32 @reference_tls_load()
  store i32 40, ptr @tls_i32, align 4
  %a0 = call i32 @protected_tls_load()
  %a1 = call i32 @protected_tls_store(i32 50)
  store i32 10, ptr @tls_ie, align 4
  %a2 = call i32 @protected_tls_ie()
  %p1 = getelementptr inbounds [2 x i32], ptr @tls_arr, i64 0, i64 1
  store i32 7, ptr %p1, align 4
  %a3 = call i32 @protected_tls_gep()
  %a4 = call i32 @protected_tls_addr(ptr @tls_i32)
  store i32 40, ptr @tls_i32, align 4
  %a5 = call i32 @protected_tls_call()
  store i32 40, ptr @tls_i32, align 4
  %a6 = call i32 @protected_tls_phi(i1 true)
  store i32 40, ptr @tls_i32, align 4
  %a7 = call i32 @protected_tls_loop(i32 2)
  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %a1, 50
  %m2 = icmp eq i32 %a2, 12
  %m3 = icmp eq i32 %a3, 10
  %m4 = icmp eq i32 %a4, 1
  %m5 = icmp eq i32 %a5, 44
  %m6 = icmp eq i32 %a6, 46
  %m7 = icmp eq i32 %a7, 80
  %t0 = and i1 %m0, %m1
  %t1 = and i1 %m2, %m3
  %t2 = and i1 %m4, %m5
  %t3 = and i1 %m6, %m7
  %ok0 = and i1 %t0, %t1
  %ok1 = and i1 %t2, %t3
  %ok = and i1 %ok0, %ok1
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_tls_musttail: musttail call
; SKIP-NOT: Skipping VMP on protected_tls_load:
; SKIP-NOT: Skipping VMP on protected_tls_store:
; SKIP-NOT: Skipping VMP on protected_tls_ie:
; SKIP-NOT: Skipping VMP on protected_tls_gep:
; SKIP-NOT: Skipping VMP on protected_tls_addr:
; SKIP-NOT: Skipping VMP on protected_tls_call:
; SKIP-NOT: Skipping VMP on protected_tls_phi:
; SKIP-NOT: Skipping VMP on protected_tls_loop:
; SKIP-NOT: Skipping VMP on reference_tls_load:

; VIRT: define i32 @protected_tls_load({{.*}} #[[PROT:[0-9]+]] {
; VIRT-DAG: store volatile ptr @tls_i32
; VIRT: vmp.dispatch:
; VIRT-DAG: load i32, ptr
; VIRT: define i32 @protected_tls_store({{.*}} #[[PROT]] {
; VIRT-DAG: store volatile ptr @tls_i32
; VIRT: vmp.dispatch:
; VIRT: define i32 @protected_tls_ie({{.*}} #[[PROT]] {
; VIRT-DAG: store volatile ptr @tls_ie
; VIRT: vmp.dispatch:
; VIRT: define i32 @protected_tls_gep({{.*}} #[[PROT]] {
; VIRT-DAG: store volatile ptr {{.*}}@tls_arr
; VIRT: vmp.dispatch:
; VIRT: define i32 @protected_tls_addr({{.*}} #[[PROT]] {
; VIRT-DAG: store volatile ptr @tls_i32
; VIRT: vmp.dispatch:
; VIRT: define i32 @protected_tls_call({{.*}} #[[PROT]] {
; VIRT-DAG: store volatile ptr @tls_i32
; VIRT: vmp.dispatch:
; VIRT: call i32 @sink_i32(ptr {{.*}}, i32 {{.*}})
; VIRT: define i32 @protected_tls_phi({{.*}} #[[PROT]] {
; VIRT-DAG: store volatile ptr @tls_i32
; VIRT: vmp.dispatch:
; VIRT: define i32 @protected_tls_loop({{.*}} #[[PROT]] {
; VIRT-DAG: store volatile ptr @tls_i32
; VIRT: vmp.dispatch:
; VIRT: define {{.*}} @unsupported_tls_musttail({{.*}} #[[UNSUP_MT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call i32 @sink_i32(
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT-NOT: attributes #[[UNSUP_MT]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
