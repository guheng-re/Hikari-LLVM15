; Scalar AS0 llvm.ptr.annotation: identity on operand 0.  Lowered to
; PointerMove into the pointer VReg.  Never CallDescriptor.  LLVM 15
; LangRef / ISel / IntrinsicLowering drop the call and forward the
; pointer.  Annotation text, unit, i32 line, and the extra arg pointer
; are discarded only when they are compile-time constants.
;
; llvm.annotation / llvm.var.annotation / codeview.annotation are not
; opened by this surface.
;
; Rejected: nonconstant or escaped strings / line / extra arg, nonzero
; AS, poison/undef, musttail, bundles, fastcc, indirect, vararg,
; sret, noreturn, returns_twice.
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

@annotation_text = private unnamed_addr constant [6 x i8] c"annot\00"
@unit_text = private unnamed_addr constant [5 x i8] c"unit\00"
@g_as1 = addrspace(1) global i32 0

declare void @hikari_vmp()
declare ptr @llvm.ptr.annotation.p0(ptr, ptr, ptr, i32, ptr)
declare ptr addrspace(1) @llvm.ptr.annotation.p1(ptr addrspace(1), ptr, ptr, i32, ptr)
declare void @ext_sret_byval(ptr sret(i32), ptr byval(i32))
declare ptr @vararg_sink(ptr, ...)

define i32 @ext_use(ptr %p) noinline {
entry:
  %v = load i32, ptr %p, align 4
  ret i32 %v
}

; ----- positives -----

define i32 @reference_mem(i32 %x) noinline {
entry:
  %a = alloca i32, align 4
  store i32 %x, ptr %a, align 4
  %l = load i32, ptr %a, align 4
  ret i32 %l
}

define i32 @protected_mem(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %a = alloca i32, align 4
  store i32 %x, ptr %a, align 4
  %ap = getelementptr inbounds [6 x i8], ptr @annotation_text, i64 0, i64 0
  %up = getelementptr inbounds [5 x i8], ptr @unit_text, i64 0, i64 0
  %p = call ptr @llvm.ptr.annotation.p0(ptr %a, ptr %ap, ptr %up, i32 42, ptr null)
  %l = load i32, ptr %p, align 4
  ret i32 %l
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
  %ap = getelementptr inbounds [6 x i8], ptr @annotation_text, i64 0, i64 0
  %up = getelementptr inbounds [5 x i8], ptr @unit_text, i64 0, i64 0
  %base = call ptr @llvm.ptr.annotation.p0(ptr %buf, ptr %ap, ptr %up, i32 7, ptr null)
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
  %ap = getelementptr inbounds [6 x i8], ptr @annotation_text, i64 0, i64 0
  %up = getelementptr inbounds [5 x i8], ptr @unit_text, i64 0, i64 0
  %p = call ptr @llvm.ptr.annotation.p0(ptr %buf, ptr %ap, ptr %up, i32 9, ptr null)
  store i32 %val, ptr %p, align 4
  %out = call i32 @ext_use(ptr %p)
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
  %ap = getelementptr inbounds [6 x i8], ptr @annotation_text, i64 0, i64 0
  %up = getelementptr inbounds [5 x i8], ptr @unit_text, i64 0, i64 0
  %p = call ptr @llvm.ptr.annotation.p0(ptr %buf, ptr %ap, ptr %up, i32 3, ptr null)
  store i32 0, ptr %p, align 4
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %cur = load i32, ptr %p, align 4
  %next = add i32 %cur, 1
  store i32 %next, ptr %p, align 4
  %i1 = add i32 %i, 1
  %more = icmp slt i32 %i1, %n
  br i1 %more, label %loop, label %done

done:
  %out = load i32, ptr %p, align 4
  ret i32 %out
}

define i32 @reference_tail(i32 %x) noinline {
entry:
  %a = alloca i32, align 4
  store i32 %x, ptr %a, align 4
  %l = load i32, ptr %a, align 4
  ret i32 %l
}

define i32 @protected_tail(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %a = alloca i32, align 4
  store i32 %x, ptr %a, align 4
  %ap = getelementptr inbounds [6 x i8], ptr @annotation_text, i64 0, i64 0
  %up = getelementptr inbounds [5 x i8], ptr @unit_text, i64 0, i64 0
  %p = tail call ptr @llvm.ptr.annotation.p0(ptr %a, ptr %ap, ptr %up, i32 1, ptr null)
  %l = load i32, ptr %p, align 4
  ret i32 %l
}

; ----- negatives -----

define i32 @unsupported_dyn_str(ptr %s, ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %up = getelementptr inbounds [5 x i8], ptr @unit_text, i64 0, i64 0
  %q = call ptr @llvm.ptr.annotation.p0(ptr %p, ptr %s, ptr %up, i32 1, ptr null)
  ret i32 0
}

define i32 @unsupported_dyn_line(ptr %p, i32 %line) noinline optnone {
entry:
  call void @hikari_vmp()
  %ap = getelementptr inbounds [6 x i8], ptr @annotation_text, i64 0, i64 0
  %up = getelementptr inbounds [5 x i8], ptr @unit_text, i64 0, i64 0
  %q = call ptr @llvm.ptr.annotation.p0(ptr %p, ptr %ap, ptr %up, i32 %line, ptr null)
  ret i32 0
}

define i32 @unsupported_dyn_arg(ptr %p, ptr %extra) noinline optnone {
entry:
  call void @hikari_vmp()
  %ap = getelementptr inbounds [6 x i8], ptr @annotation_text, i64 0, i64 0
  %up = getelementptr inbounds [5 x i8], ptr @unit_text, i64 0, i64 0
  %q = call ptr @llvm.ptr.annotation.p0(ptr %p, ptr %ap, ptr %up, i32 1, ptr %extra)
  ret i32 0
}

define i32 @unsupported_poison(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %ap = getelementptr inbounds [6 x i8], ptr @annotation_text, i64 0, i64 0
  %up = getelementptr inbounds [5 x i8], ptr @unit_text, i64 0, i64 0
  %q = call ptr @llvm.ptr.annotation.p0(ptr poison, ptr %ap, ptr %up, i32 1, ptr null)
  ret i32 0
}

define i32 @unsupported_undef(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %ap = getelementptr inbounds [6 x i8], ptr @annotation_text, i64 0, i64 0
  %up = getelementptr inbounds [5 x i8], ptr @unit_text, i64 0, i64 0
  %q = call ptr @llvm.ptr.annotation.p0(ptr undef, ptr %ap, ptr %up, i32 1, ptr null)
  ret i32 0
}

define i32 @unsupported_as1_arg(ptr addrspace(1) %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %ap = getelementptr inbounds [6 x i8], ptr @annotation_text, i64 0, i64 0
  %up = getelementptr inbounds [5 x i8], ptr @unit_text, i64 0, i64 0
  %q = call ptr addrspace(1) @llvm.ptr.annotation.p1(ptr addrspace(1) %p, ptr %ap, ptr %up, i32 1, ptr null)
  ret i32 0
}

define i32 @unsupported_as1_call() noinline optnone {
entry:
  call void @hikari_vmp()
  %ap = getelementptr inbounds [6 x i8], ptr @annotation_text, i64 0, i64 0
  %up = getelementptr inbounds [5 x i8], ptr @unit_text, i64 0, i64 0
  %q = call ptr addrspace(1) @llvm.ptr.annotation.p1(ptr addrspace(1) @g_as1, ptr %ap, ptr %up, i32 1, ptr null)
  ret i32 0
}

define ptr @unsupported_musttail(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %ap = getelementptr inbounds [6 x i8], ptr @annotation_text, i64 0, i64 0
  %up = getelementptr inbounds [5 x i8], ptr @unit_text, i64 0, i64 0
  %q = musttail call ptr @llvm.ptr.annotation.p0(ptr %p, ptr %ap, ptr %up, i32 1, ptr null)
  ret ptr %q
}

define ptr @unsupported_bundle(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %ap = getelementptr inbounds [6 x i8], ptr @annotation_text, i64 0, i64 0
  %up = getelementptr inbounds [5 x i8], ptr @unit_text, i64 0, i64 0
  %q = call ptr @llvm.ptr.annotation.p0(ptr %p, ptr %ap, ptr %up, i32 1, ptr null) [ "deopt"(i32 0) ]
  ret ptr %q
}

define ptr @unsupported_fastcc(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %ap = getelementptr inbounds [6 x i8], ptr @annotation_text, i64 0, i64 0
  %up = getelementptr inbounds [5 x i8], ptr @unit_text, i64 0, i64 0
  %q = call fastcc ptr @llvm.ptr.annotation.p0(ptr %p, ptr %ap, ptr %up, i32 1, ptr null)
  ret ptr %q
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

define ptr @unsupported_noreturn(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %ap = getelementptr inbounds [6 x i8], ptr @annotation_text, i64 0, i64 0
  %up = getelementptr inbounds [5 x i8], ptr @unit_text, i64 0, i64 0
  %q = call ptr @llvm.ptr.annotation.p0(ptr %p, ptr %ap, ptr %up, i32 1, ptr null) noreturn
  ret ptr %q
}

define ptr @unsupported_returns_twice(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %ap = getelementptr inbounds [6 x i8], ptr @annotation_text, i64 0, i64 0
  %up = getelementptr inbounds [5 x i8], ptr @unit_text, i64 0, i64 0
  %q = call ptr @llvm.ptr.annotation.p0(ptr %p, ptr %ap, ptr %up, i32 1, ptr null) returns_twice
  ret ptr %q
}

define i32 @main() {
entry:
  %em = call i32 @reference_mem(i32 7)
  %pm = call i32 @protected_mem(i32 7)
  %okm = icmp eq i32 %em, %pm
  %eg = call i32 @reference_gep(i32 3, i32 4)
  %pg = call i32 @protected_gep(i32 3, i32 4)
  %okg = icmp eq i32 %eg, %pg
  %ec = call i32 @reference_call(i32 11)
  %pc = call i32 @protected_call(i32 11)
  %okc = icmp eq i32 %ec, %pc
  %el = call i32 @reference_loop(i32 4)
  %pl = call i32 @protected_loop(i32 4)
  %okl = icmp eq i32 %el, %pl
  %et = call i32 @reference_tail(i32 13)
  %pt = call i32 @protected_tail(i32 13)
  %okt = icmp eq i32 %et, %pt
  %t0 = and i1 %okm, %okg
  %t1 = and i1 %t0, %okc
  %t2 = and i1 %t1, %okl
  %ok = and i1 %t2, %okt
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_dyn_str: unsupported ptr.annotation
; SKIP-DAG: Skipping VMP on unsupported_dyn_line: unsupported ptr.annotation
; SKIP-DAG: Skipping VMP on unsupported_dyn_arg: unsupported ptr.annotation
; SKIP-DAG: Skipping VMP on unsupported_poison: unsupported ptr.annotation
; SKIP-DAG: Skipping VMP on unsupported_undef: unsupported ptr.annotation
; SKIP-DAG: Skipping VMP on unsupported_as1_arg: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_as1_call: unsupported ptr.annotation
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported ptr.annotation
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported ptr.annotation
; SKIP-DAG: Skipping VMP on unsupported_indirect: indirect call
; SKIP-DAG: Skipping VMP on unsupported_vararg: variadic call
; SKIP-DAG: Skipping VMP on unsupported_sret: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_noreturn: unsupported ptr.annotation
; SKIP-DAG: Skipping VMP on unsupported_returns_twice: unsupported ptr.annotation
; SKIP-NOT: Skipping VMP on protected_mem:
; SKIP-NOT: Skipping VMP on protected_gep:
; SKIP-NOT: Skipping VMP on protected_call:
; SKIP-NOT: Skipping VMP on protected_loop:
; SKIP-NOT: Skipping VMP on protected_tail:

; VIRT: define i32 @protected_mem({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call void @hikari_vmp()
; VIRT-NOT: @llvm.ptr.annotation
; VIRT: }
; VIRT: define i32 @protected_gep({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: @llvm.ptr.annotation
; VIRT: }
; VIRT: define i32 @protected_call({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: @llvm.ptr.annotation
; VIRT: }
; VIRT: define i32 @protected_loop({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: @llvm.ptr.annotation
; VIRT: }
; VIRT: define i32 @protected_tail({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: tail call
; VIRT-NOT: @llvm.ptr.annotation
; VIRT: }
; VIRT: define {{.*}} @unsupported_dyn_str({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_dyn_line({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_dyn_arg({{.*}} #[[UNSUP]] {
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
; VIRT: define {{.*}} @unsupported_noreturn({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_returns_twice({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPMUST]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPMUST]] = { {{.*}}"hikari.vmp.selected"
; VIRT-NOT: attributes #[[UNSUPVAR]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
