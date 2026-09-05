; Scalar llvm.clear_cache: not a no-op on AArch64.  LangRef: make
; [begin, end) visible to the execution unit.  ISel emits the
; __clear_cache libcall.  VMP replays the intrinsic via CallDescriptor
; (void(ptr, ptr), C, attributes, DebugLoc) with both range pointers
; from the pointer VReg frame.
;
; Host x86 lli treats clear_cache as a nop; AArch64 llc must still
; produce __clear_cache.
;
; Rejected: poison/undef, musttail, bundles, fastcc, indirect,
; sret, AS1 arguments.
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
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o0.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.ll > %t.o2.live.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.live.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o2.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.s7.ll > %t.o0.s7.live.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.s7.live.ll > %t.o0.s7.host.ll
; RUN: lli -force-interpreter %t.o0.s7.host.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o0.s7.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.s7.ll > %t.o2.s7.live.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.s7.live.ll > %t.o2.s7.host.ll
; RUN: lli -force-interpreter %t.o2.s7.host.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o2.s7.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare void @llvm.clear_cache(ptr, ptr)
declare void @ext_sret_byval(ptr sret(i32), ptr byval(i32))

; ----- positives -----

define i32 @reference_mem(i32 %val) noinline {
entry:
  %buf = alloca [4 x i32], align 4
  %begin = getelementptr inbounds [4 x i32], ptr %buf, i64 0, i64 0
  %end = getelementptr inbounds [4 x i32], ptr %buf, i64 0, i64 4
  call void @llvm.clear_cache(ptr %begin, ptr %end)
  store i32 %val, ptr %begin, align 4
  %out = load i32, ptr %begin, align 4
  ret i32 %out
}

define i32 @protected_mem(i32 %val) noinline optnone {
entry:
  call void @hikari_vmp()
  %buf = alloca [4 x i32], align 4
  %begin = getelementptr inbounds [4 x i32], ptr %buf, i64 0, i64 0
  %end = getelementptr inbounds [4 x i32], ptr %buf, i64 0, i64 4
  call void @llvm.clear_cache(ptr %begin, ptr %end)
  store i32 %val, ptr %begin, align 4
  %out = load i32, ptr %begin, align 4
  ret i32 %out
}

define void @reference_range(ptr %begin, ptr %end) noinline {
entry:
  call void @llvm.clear_cache(ptr %begin, ptr %end)
  ret void
}

define void @protected_range(ptr %begin, ptr %end) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.clear_cache(ptr %begin, ptr %end)
  ret void
}

define i32 @reference_loop(i32 %n) noinline {
entry:
  %buf = alloca i32, align 4
  store i32 0, ptr %buf, align 4
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %end = getelementptr i32, ptr %buf, i64 1
  call void @llvm.clear_cache(ptr %buf, ptr %end)
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
  store i32 0, ptr %buf, align 4
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %end = getelementptr i32, ptr %buf, i64 1
  call void @llvm.clear_cache(ptr %buf, ptr %end)
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

define void @protected_tail(ptr %begin, ptr %end) noinline optnone {
entry:
  call void @hikari_vmp()
  tail call void @llvm.clear_cache(ptr %begin, ptr %end)
  ret void
}

; ----- negatives -----

define void @unsupported_poison(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.clear_cache(ptr poison, ptr %p)
  ret void
}

define void @unsupported_undef(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.clear_cache(ptr %p, ptr undef)
  ret void
}

define void @unsupported_musttail(ptr %begin, ptr %end) noinline optnone {
entry:
  call void @hikari_vmp()
  musttail call void @llvm.clear_cache(ptr %begin, ptr %end)
  ret void
}

define void @unsupported_bundle(ptr %begin, ptr %end) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.clear_cache(ptr %begin, ptr %end) [ "deopt"(i32 0) ]
  ret void
}

define void @unsupported_fastcc(ptr %begin, ptr %end) noinline optnone {
entry:
  call void @hikari_vmp()
  call fastcc void @llvm.clear_cache(ptr %begin, ptr %end)
  ret void
}


define void @unsupported_indirect(ptr %fp, ptr %begin, ptr %end) noinline optnone {
entry:
  call void @hikari_vmp()
  call void %fp(ptr %begin, ptr %end) [ "deopt"(i32 0) ]
  ret void
}

define void @unsupported_sret(ptr sret(i32) %p, ptr byval(i32) %q) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @ext_sret_byval(ptr sret(i32) %p, ptr byval(i32) %q)
  ret void
}

define void @unsupported_as1_arg(ptr addrspace(1) %begin, ptr addrspace(1) %end) noinline optnone {
entry:
  call void @hikari_vmp()
  %b = addrspacecast ptr addrspace(1) %begin to ptr
  %e = addrspacecast ptr addrspace(1) %end to ptr
  call void @llvm.clear_cache(ptr %b, ptr %e)
  ret void
}

define i32 @main() {
entry:
  %em = call i32 @reference_mem(i32 42)
  %pm = call i32 @protected_mem(i32 42)
  %okm = icmp eq i32 %em, %pm
  %em2 = call i32 @reference_mem(i32 -7)
  %pm2 = call i32 @protected_mem(i32 -7)
  %okm2 = icmp eq i32 %em2, %pm2
  %buf = alloca [4 x i32], align 4
  %rb = getelementptr inbounds [4 x i32], ptr %buf, i64 0, i64 0
  %re = getelementptr inbounds [4 x i32], ptr %buf, i64 0, i64 4
  call void @reference_range(ptr %rb, ptr %re)
  call void @protected_range(ptr %rb, ptr %re)
  call void @protected_tail(ptr %rb, ptr %re)
  %el = call i32 @reference_loop(i32 3)
  %pl = call i32 @protected_loop(i32 3)
  %okl = icmp eq i32 %el, %pl
  %t0 = and i1 %okm, %okm2
  %ok = and i1 %t0, %okl
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_poison: unsupported clear_cache
; SKIP-DAG: Skipping VMP on unsupported_undef: unsupported clear_cache
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported clear_cache
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported clear_cache
; SKIP-DAG: Skipping VMP on unsupported_indirect: indirect call
; SKIP-DAG: Skipping VMP on unsupported_sret: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_as1_arg: unsupported argument type
; SKIP-NOT: Skipping VMP on protected_mem:
; SKIP-NOT: Skipping VMP on protected_range:
; SKIP-NOT: Skipping VMP on protected_loop:
; SKIP-NOT: Skipping VMP on protected_tail:

; VIRT: define i32 @protected_mem({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call void @hikari_vmp()
; VIRT-DAG: call void @llvm.clear_cache(ptr [[MB:%.*]], ptr [[ME:%.*]])
; VIRT-DAG: [[MB]] = load volatile ptr, ptr {{.*}}, align 8
; VIRT-DAG: [[ME]] = load volatile ptr, ptr {{.*}}, align 8
; VIRT: }
; VIRT: define void @protected_range({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: call void @llvm.clear_cache(ptr [[RB:%.*]], ptr [[RE:%.*]])
; VIRT-DAG: [[RB]] = load volatile ptr, ptr {{.*}}, align 8
; VIRT-DAG: [[RE]] = load volatile ptr, ptr {{.*}}, align 8
; VIRT: }
; VIRT: define i32 @protected_loop({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: call void @llvm.clear_cache(ptr [[LB:%.*]], ptr [[LE:%.*]])
; VIRT-DAG: [[LB]] = load volatile ptr, ptr {{.*}}, align 8
; VIRT-DAG: [[LE]] = load volatile ptr, ptr {{.*}}, align 8
; VIRT: }
; VIRT: define void @protected_tail({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: tail call void @llvm.clear_cache
; VIRT-DAG: call void @llvm.clear_cache(ptr [[TB:%.*]], ptr [[TE:%.*]])
; VIRT-DAG: [[TB]] = load volatile ptr, ptr {{.*}}, align 8
; VIRT-DAG: [[TE]] = load volatile ptr, ptr {{.*}}, align 8
; VIRT: }
; VIRT: define {{.*}} @unsupported_poison({{.*}} #[[UNSUP:[0-9]+]] {
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
; VIRT: define {{.*}} @unsupported_sret({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_as1_arg({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPMUST]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPMUST]] = { {{.*}}"hikari.vmp.selected"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; AARCH64-ASM: __clear_cache
