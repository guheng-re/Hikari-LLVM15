; AS0 llvm.var.annotation: void marker.  LangRef / ISel / IRTranslator /
; IntrinsicLowering discard it.  VMP consumes well-formed calls with a
; supported AS0 data pointer and compile-time annotation/unit/line/extra
; operands.  Never CallDescriptor.  llvm.annotation / codeview.annotation
; are not opened here.
;
; Rejected: nonconstant or escaped strings / line / extra arg, poison/
; undef, musttail, bundles, fastcc, indirect,
; vararg, sret, noreturn, returns_twice.
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

declare void @hikari_vmp()
declare void @llvm.var.annotation(ptr, ptr, ptr, i32, ptr)
declare void @llvm.codeview.annotation(metadata)
declare void @ext_sret_byval(ptr sret(i32), ptr byval(i32))
declare ptr @vararg_sink(ptr, ...)

; ----- positives -----

define i32 @reference_mem(i32 %x) noinline {
entry:
  %v = alloca i32, align 4
  store i32 %x, ptr %v, align 4
  %l = load i32, ptr %v, align 4
  %r = mul i32 %l, 3
  %o = add i32 %r, 1
  ret i32 %o
}

define i32 @protected_mem(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %v = alloca i32, align 4
  store i32 %x, ptr %v, align 4
  %ap = getelementptr inbounds [6 x i8], ptr @annotation_text, i64 0, i64 0
  %up = getelementptr inbounds [5 x i8], ptr @unit_text, i64 0, i64 0
  call void @llvm.var.annotation(ptr %v, ptr %ap, ptr %up, i32 42, ptr null)
  %l = load i32, ptr %v, align 4
  %r = mul i32 %l, 3
  %o = add i32 %r, 1
  ret i32 %o
}

define i32 @reference_phi(i1 %c, i32 %a, i32 %b) noinline {
entry:
  %slot = alloca i32, align 4
  br i1 %c, label %left, label %right

left:
  store i32 %a, ptr %slot, align 4
  br label %join

right:
  store i32 %b, ptr %slot, align 4
  br label %join

join:
  %p = phi i32 [ %a, %left ], [ %b, %right ]
  ret i32 %p
}

define i32 @protected_phi(i1 %c, i32 %a, i32 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %slot = alloca i32, align 4
  %ap = getelementptr inbounds [6 x i8], ptr @annotation_text, i64 0, i64 0
  %up = getelementptr inbounds [5 x i8], ptr @unit_text, i64 0, i64 0
  br i1 %c, label %left, label %right

left:
  store i32 %a, ptr %slot, align 4
  call void @llvm.var.annotation(ptr %slot, ptr %ap, ptr %up, i32 1, ptr null)
  br label %join

right:
  store i32 %b, ptr %slot, align 4
  call void @llvm.var.annotation(ptr %slot, ptr %ap, ptr %up, i32 2, ptr null)
  br label %join

join:
  %p = phi i32 [ %a, %left ], [ %b, %right ]
  ret i32 %p
}

define i32 @reference_loop(i32 %n) noinline {
entry:
  %slot = alloca i32, align 4
  store i32 0, ptr %slot, align 4
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %cur = load i32, ptr %slot, align 4
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
  %ap = getelementptr inbounds [6 x i8], ptr @annotation_text, i64 0, i64 0
  %up = getelementptr inbounds [5 x i8], ptr @unit_text, i64 0, i64 0
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  call void @llvm.var.annotation(ptr %slot, ptr %ap, ptr %up, i32 3, ptr null)
  %cur = load i32, ptr %slot, align 4
  %next = add i32 %cur, 1
  store i32 %next, ptr %slot, align 4
  %i1 = add i32 %i, 1
  %more = icmp slt i32 %i1, %n
  br i1 %more, label %loop, label %done

done:
  %out = load i32, ptr %slot, align 4
  ret i32 %out
}

; ----- negatives -----

define i32 @unsupported_dyn_str(ptr %s, ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %up = getelementptr inbounds [5 x i8], ptr @unit_text, i64 0, i64 0
  call void @llvm.var.annotation(ptr %p, ptr %s, ptr %up, i32 1, ptr null)
  ret i32 0
}

define i32 @unsupported_dyn_line(ptr %p, i32 %line) noinline optnone {
entry:
  call void @hikari_vmp()
  %ap = getelementptr inbounds [6 x i8], ptr @annotation_text, i64 0, i64 0
  %up = getelementptr inbounds [5 x i8], ptr @unit_text, i64 0, i64 0
  call void @llvm.var.annotation(ptr %p, ptr %ap, ptr %up, i32 %line, ptr null)
  ret i32 0
}

define i32 @unsupported_dyn_arg(ptr %p, ptr %extra) noinline optnone {
entry:
  call void @hikari_vmp()
  %ap = getelementptr inbounds [6 x i8], ptr @annotation_text, i64 0, i64 0
  %up = getelementptr inbounds [5 x i8], ptr @unit_text, i64 0, i64 0
  call void @llvm.var.annotation(ptr %p, ptr %ap, ptr %up, i32 1, ptr %extra)
  ret i32 0
}

define i32 @unsupported_poison() noinline optnone {
entry:
  call void @hikari_vmp()
  %ap = getelementptr inbounds [6 x i8], ptr @annotation_text, i64 0, i64 0
  %up = getelementptr inbounds [5 x i8], ptr @unit_text, i64 0, i64 0
  call void @llvm.var.annotation(ptr poison, ptr %ap, ptr %up, i32 1, ptr null)
  ret i32 0
}

define i32 @unsupported_undef() noinline optnone {
entry:
  call void @hikari_vmp()
  %ap = getelementptr inbounds [6 x i8], ptr @annotation_text, i64 0, i64 0
  %up = getelementptr inbounds [5 x i8], ptr @unit_text, i64 0, i64 0
  call void @llvm.var.annotation(ptr undef, ptr %ap, ptr %up, i32 1, ptr null)
  ret i32 0
}


define void @unsupported_musttail(ptr %p, ptr %ap, ptr %up, i32 %ln, ptr %ex) noinline optnone {
entry:
  call void @hikari_vmp()
  musttail call void @llvm.var.annotation(ptr %p, ptr %ap, ptr %up, i32 1, ptr null)
  ret void
}

define i32 @unsupported_bundle(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %ap = getelementptr inbounds [6 x i8], ptr @annotation_text, i64 0, i64 0
  %up = getelementptr inbounds [5 x i8], ptr @unit_text, i64 0, i64 0
  call void @llvm.var.annotation(ptr %p, ptr %ap, ptr %up, i32 1, ptr null) [ "deopt"(i32 0) ]
  ret i32 0
}

define i32 @unsupported_fastcc(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %ap = getelementptr inbounds [6 x i8], ptr @annotation_text, i64 0, i64 0
  %up = getelementptr inbounds [5 x i8], ptr @unit_text, i64 0, i64 0
  call fastcc void @llvm.var.annotation(ptr %p, ptr %ap, ptr %up, i32 1, ptr null)
  ret i32 0
}


define i32 @unsupported_indirect(ptr %fp, ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  call void %fp(ptr %p) [ "deopt"(i32 0) ]
  ret i32 0
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

define i32 @unsupported_noreturn(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %ap = getelementptr inbounds [6 x i8], ptr @annotation_text, i64 0, i64 0
  %up = getelementptr inbounds [5 x i8], ptr @unit_text, i64 0, i64 0
  call void @llvm.var.annotation(ptr %p, ptr %ap, ptr %up, i32 1, ptr null) noreturn
  ret i32 0
}

define i32 @unsupported_returns_twice(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %ap = getelementptr inbounds [6 x i8], ptr @annotation_text, i64 0, i64 0
  %up = getelementptr inbounds [5 x i8], ptr @unit_text, i64 0, i64 0
  call void @llvm.var.annotation(ptr %p, ptr %ap, ptr %up, i32 1, ptr null) returns_twice
  ret i32 0
}

define i32 @unsupported_codeview_annotation(i32 %seed) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.codeview.annotation(metadata !0)
  %o = add i32 %seed, 1
  ret i32 %o
}

define i32 @main() {
entry:
  %em = call i32 @reference_mem(i32 7)
  %pm = call i32 @protected_mem(i32 7)
  %okm = icmp eq i32 %em, %pm
  %em2 = call i32 @reference_mem(i32 42)
  %pm2 = call i32 @protected_mem(i32 42)
  %okm2 = icmp eq i32 %em2, %pm2
  %ephi = call i32 @reference_phi(i1 true, i32 3, i32 9)
  %pphi = call i32 @protected_phi(i1 true, i32 3, i32 9)
  %okphi = icmp eq i32 %ephi, %pphi
  %ephi2 = call i32 @reference_phi(i1 false, i32 3, i32 9)
  %pphi2 = call i32 @protected_phi(i1 false, i32 3, i32 9)
  %okphi2 = icmp eq i32 %ephi2, %pphi2
  %el = call i32 @reference_loop(i32 4)
  %pl = call i32 @protected_loop(i32 4)
  %okl = icmp eq i32 %el, %pl
  %t0 = and i1 %okm, %okm2
  %t1 = and i1 %t0, %okphi
  %t2 = and i1 %t1, %okphi2
  %ok = and i1 %t2, %okl
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

!0 = !{!"vmp"}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_dyn_str: unsupported var.annotation
; SKIP-DAG: Skipping VMP on unsupported_dyn_line: unsupported var.annotation
; SKIP-DAG: Skipping VMP on unsupported_dyn_arg: unsupported var.annotation
; SKIP-DAG: Skipping VMP on unsupported_poison: unsupported var.annotation
; SKIP-DAG: Skipping VMP on unsupported_undef: unsupported var.annotation
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported var.annotation
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported var.annotation
; SKIP-DAG: Skipping VMP on unsupported_indirect: indirect call
; SKIP-DAG: Skipping VMP on unsupported_vararg: variadic call
; SKIP-DAG: Skipping VMP on unsupported_sret: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_noreturn: unsupported var.annotation
; SKIP-DAG: Skipping VMP on unsupported_returns_twice: unsupported var.annotation
; SKIP-DAG: Skipping VMP on unsupported_codeview_annotation: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_mem:
; SKIP-NOT: Skipping VMP on protected_phi:
; SKIP-NOT: Skipping VMP on protected_loop:

; VIRT: define i32 @protected_mem({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call void @hikari_vmp()
; VIRT-NOT: @llvm.var.annotation
; VIRT: }
; VIRT: define i32 @protected_phi({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: @llvm.var.annotation
; VIRT: }
; VIRT: define i32 @protected_loop({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: @llvm.var.annotation
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
; VIRT: define {{.*}} @unsupported_codeview_annotation({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call void @llvm.codeview.annotation
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPMUST]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPMUST]] = { {{.*}}"hikari.vmp.selected"
; VIRT-NOT: attributes #[[UNSUPVAR]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
