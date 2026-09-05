; Scalar llvm.annotation: identity on operand 0.  Lowered to Move into
; the matching integer / i128 VReg.  Never CallDescriptor.  LLVM 15
; LangRef / ISel / IntrinsicLowering drop the call and forward arg0.
; Annotation text, unit, and i32 line are discarded only when they are
; compile-time constants.  ptr.annotation / var.annotation are separate.
;
; Rejected: i2/other widths, pointers/floats/vectors, runtime or escaped
; strings / line, poison/undef, musttail, bundles, fastcc,
; indirect, vararg, sret, noreturn, returns_twice.
; Well-formed i32 inline asm is vmp-inline-asm-semantic.ll.
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
declare i1 @llvm.annotation.i1(i1, ptr, ptr, i32)
declare i8 @llvm.annotation.i8(i8, ptr, ptr, i32)
declare i16 @llvm.annotation.i16(i16, ptr, ptr, i32)
declare i32 @llvm.annotation.i32(i32, ptr, ptr, i32)
declare i64 @llvm.annotation.i64(i64, ptr, ptr, i32)
declare i128 @llvm.annotation.i128(i128, ptr, ptr, i32)
declare i2 @llvm.annotation.i2(i2, ptr, ptr, i32)
declare void @ext_sret_byval(ptr sret(i32), ptr byval(i32))
declare i32 @vararg_sink(i32, ...)

; ----- positives -----

define i32 @reference_i1(i32 %x) noinline {
entry:
  %cmp = icmp sgt i32 %x, 0
  br i1 %cmp, label %pos, label %neg

pos:
  ret i32 1

neg:
  ret i32 0
}

define i32 @protected_i1(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %cmp = icmp sgt i32 %x, 0
  %ap = getelementptr inbounds [6 x i8], ptr @annotation_text, i64 0, i64 0
  %up = getelementptr inbounds [5 x i8], ptr @unit_text, i64 0, i64 0
  %e = call i1 @llvm.annotation.i1(i1 %cmp, ptr %ap, ptr %up, i32 1)
  br i1 %e, label %pos, label %neg

pos:
  ret i32 1

neg:
  ret i32 0
}

define i8 @reference_i8(i8 %x) noinline {
entry:
  ret i8 %x
}

define i8 @protected_i8(i8 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %ap = getelementptr inbounds [6 x i8], ptr @annotation_text, i64 0, i64 0
  %up = getelementptr inbounds [5 x i8], ptr @unit_text, i64 0, i64 0
  %r = call i8 @llvm.annotation.i8(i8 %x, ptr %ap, ptr %up, i32 8)
  ret i8 %r
}

define i16 @reference_i16(i16 %x) noinline {
entry:
  ret i16 %x
}

define i16 @protected_i16(i16 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %ap = getelementptr inbounds [6 x i8], ptr @annotation_text, i64 0, i64 0
  %up = getelementptr inbounds [5 x i8], ptr @unit_text, i64 0, i64 0
  %r = call i16 @llvm.annotation.i16(i16 %x, ptr %ap, ptr %up, i32 16)
  ret i16 %r
}

define i32 @reference_i32(i32 %x) noinline {
entry:
  %o = add i32 %x, 1
  ret i32 %o
}

define i32 @protected_i32(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %ap = getelementptr inbounds [6 x i8], ptr @annotation_text, i64 0, i64 0
  %up = getelementptr inbounds [5 x i8], ptr @unit_text, i64 0, i64 0
  %r = call i32 @llvm.annotation.i32(i32 %x, ptr %ap, ptr %up, i32 42)
  %o = add i32 %r, 1
  ret i32 %o
}

define i64 @reference_i64(i64 %x) noinline {
entry:
  ret i64 %x
}

define i64 @protected_i64(i64 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %ap = getelementptr inbounds [6 x i8], ptr @annotation_text, i64 0, i64 0
  %up = getelementptr inbounds [5 x i8], ptr @unit_text, i64 0, i64 0
  %r = call i64 @llvm.annotation.i64(i64 %x, ptr %ap, ptr %up, i32 64)
  ret i64 %r
}

define i128 @reference_i128(i128 %x) noinline {
entry:
  ret i128 %x
}

define i128 @protected_i128(i128 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %ap = getelementptr inbounds [6 x i8], ptr @annotation_text, i64 0, i64 0
  %up = getelementptr inbounds [5 x i8], ptr @unit_text, i64 0, i64 0
  %r = call i128 @llvm.annotation.i128(i128 %x, ptr %ap, ptr %up, i32 128)
  ret i128 %r
}

define i32 @reference_phi(i1 %c, i32 %a, i32 %b) noinline {
entry:
  br i1 %c, label %left, label %right

left:
  br label %join

right:
  br label %join

join:
  %p = phi i32 [ %a, %left ], [ %b, %right ]
  ret i32 %p
}

define i32 @protected_phi(i1 %c, i32 %a, i32 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %ap = getelementptr inbounds [6 x i8], ptr @annotation_text, i64 0, i64 0
  %up = getelementptr inbounds [5 x i8], ptr @unit_text, i64 0, i64 0
  br i1 %c, label %left, label %right

left:
  %l = call i32 @llvm.annotation.i32(i32 %a, ptr %ap, ptr %up, i32 1)
  br label %join

right:
  %r = call i32 @llvm.annotation.i32(i32 %b, ptr %ap, ptr %up, i32 2)
  br label %join

join:
  %p = phi i32 [ %l, %left ], [ %r, %right ]
  ret i32 %p
}

define i32 @reference_loop(i32 %x, i32 %n) noinline {
entry:
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %acc = phi i32 [ 0, %entry ], [ %next, %loop ]
  %next = add i32 %acc, %x
  %i1 = add i32 %i, 1
  %more = icmp slt i32 %i1, %n
  br i1 %more, label %loop, label %done

done:
  ret i32 %next
}

define i32 @protected_loop(i32 %x, i32 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  %ap = getelementptr inbounds [6 x i8], ptr @annotation_text, i64 0, i64 0
  %up = getelementptr inbounds [5 x i8], ptr @unit_text, i64 0, i64 0
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %acc = phi i32 [ 0, %entry ], [ %next, %loop ]
  %e = call i32 @llvm.annotation.i32(i32 %x, ptr %ap, ptr %up, i32 3)
  %next = add i32 %acc, %e
  %i1 = add i32 %i, 1
  %more = icmp slt i32 %i1, %n
  br i1 %more, label %loop, label %done

done:
  ret i32 %next
}

; ----- negatives -----

define i32 @unsupported_dyn_str(i32 %x, ptr %s) noinline optnone {
entry:
  call void @hikari_vmp()
  %up = getelementptr inbounds [5 x i8], ptr @unit_text, i64 0, i64 0
  %r = call i32 @llvm.annotation.i32(i32 %x, ptr %s, ptr %up, i32 1)
  ret i32 %r
}

define i32 @unsupported_dyn_line(i32 %x, i32 %line) noinline optnone {
entry:
  call void @hikari_vmp()
  %ap = getelementptr inbounds [6 x i8], ptr @annotation_text, i64 0, i64 0
  %up = getelementptr inbounds [5 x i8], ptr @unit_text, i64 0, i64 0
  %r = call i32 @llvm.annotation.i32(i32 %x, ptr %ap, ptr %up, i32 %line)
  ret i32 %r
}

define i32 @unsupported_poison() noinline optnone {
entry:
  call void @hikari_vmp()
  %ap = getelementptr inbounds [6 x i8], ptr @annotation_text, i64 0, i64 0
  %up = getelementptr inbounds [5 x i8], ptr @unit_text, i64 0, i64 0
  %r = call i32 @llvm.annotation.i32(i32 poison, ptr %ap, ptr %up, i32 1)
  ret i32 %r
}

define i32 @unsupported_undef() noinline optnone {
entry:
  call void @hikari_vmp()
  %ap = getelementptr inbounds [6 x i8], ptr @annotation_text, i64 0, i64 0
  %up = getelementptr inbounds [5 x i8], ptr @unit_text, i64 0, i64 0
  %r = call i32 @llvm.annotation.i32(i32 undef, ptr %ap, ptr %up, i32 1)
  ret i32 %r
}

define i2 @unsupported_i2(i2 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %ap = getelementptr inbounds [6 x i8], ptr @annotation_text, i64 0, i64 0
  %up = getelementptr inbounds [5 x i8], ptr @unit_text, i64 0, i64 0
  %r = call i2 @llvm.annotation.i2(i2 %x, ptr %ap, ptr %up, i32 1)
  ret i2 %r
}


define i32 @unsupported_musttail(i32 %x, ptr %ap, ptr %up, i32 %ln) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call i32 @llvm.annotation.i32(i32 %x, ptr %ap, ptr %up, i32 1)
  ret i32 %r
}

define i32 @unsupported_bundle(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %ap = getelementptr inbounds [6 x i8], ptr @annotation_text, i64 0, i64 0
  %up = getelementptr inbounds [5 x i8], ptr @unit_text, i64 0, i64 0
  %r = call i32 @llvm.annotation.i32(i32 %x, ptr %ap, ptr %up, i32 1) [ "deopt"(i32 0) ]
  ret i32 %r
}

define i32 @unsupported_fastcc(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %ap = getelementptr inbounds [6 x i8], ptr @annotation_text, i64 0, i64 0
  %up = getelementptr inbounds [5 x i8], ptr @unit_text, i64 0, i64 0
  %r = call fastcc i32 @llvm.annotation.i32(i32 %x, ptr %ap, ptr %up, i32 1)
  ret i32 %r
}


define i32 @unsupported_indirect(ptr %fp, i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 %fp(i32 %x) [ "deopt"(i32 0) ]
  ret i32 %r
}

define i32 @unsupported_vararg(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc i32 (i32, ...) @vararg_sink(i32 %x)
  ret i32 %r
}

define void @unsupported_sret(ptr sret(i32) %p, ptr byval(i32) %q) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @ext_sret_byval(ptr sret(i32) %p, ptr byval(i32) %q)
  ret void
}

define i32 @unsupported_noreturn(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %ap = getelementptr inbounds [6 x i8], ptr @annotation_text, i64 0, i64 0
  %up = getelementptr inbounds [5 x i8], ptr @unit_text, i64 0, i64 0
  %r = call i32 @llvm.annotation.i32(i32 %x, ptr %ap, ptr %up, i32 1) noreturn
  ret i32 %r
}

define i32 @unsupported_returns_twice(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %ap = getelementptr inbounds [6 x i8], ptr @annotation_text, i64 0, i64 0
  %up = getelementptr inbounds [5 x i8], ptr @unit_text, i64 0, i64 0
  %r = call i32 @llvm.annotation.i32(i32 %x, ptr %ap, ptr %up, i32 1) returns_twice
  ret i32 %r
}

define i32 @main() {
entry:
  %e1 = call i32 @reference_i1(i32 5)
  %p1 = call i32 @protected_i1(i32 5)
  %ok1 = icmp eq i32 %e1, %p1
  %e1b = call i32 @reference_i1(i32 -2)
  %p1b = call i32 @protected_i1(i32 -2)
  %ok1b = icmp eq i32 %e1b, %p1b
  %e8 = call i8 @reference_i8(i8 9)
  %p8 = call i8 @protected_i8(i8 9)
  %ok8 = icmp eq i8 %e8, %p8
  %e8b = call i8 @reference_i8(i8 -2)
  %p8b = call i8 @protected_i8(i8 -2)
  %ok8b = icmp eq i8 %e8b, %p8b
  %e16 = call i16 @reference_i16(i16 11)
  %p16 = call i16 @protected_i16(i16 11)
  %ok16 = icmp eq i16 %e16, %p16
  %e16b = call i16 @reference_i16(i16 -2)
  %p16b = call i16 @protected_i16(i16 -2)
  %ok16b = icmp eq i16 %e16b, %p16b
  %e32 = call i32 @reference_i32(i32 13)
  %p32 = call i32 @protected_i32(i32 13)
  %ok32 = icmp eq i32 %e32, %p32
  %e64 = call i64 @reference_i64(i64 15)
  %p64 = call i64 @protected_i64(i64 15)
  %ok64 = icmp eq i64 %e64, %p64
  %e128 = call i128 @reference_i128(i128 17)
  %p128 = call i128 @protected_i128(i128 17)
  %ok128 = icmp eq i128 %e128, %p128
  %ephi = call i32 @reference_phi(i1 true, i32 3, i32 8)
  %pphi = call i32 @protected_phi(i1 true, i32 3, i32 8)
  %okphi = icmp eq i32 %ephi, %pphi
  %ephi2 = call i32 @reference_phi(i1 false, i32 3, i32 8)
  %pphi2 = call i32 @protected_phi(i1 false, i32 3, i32 8)
  %okphi2 = icmp eq i32 %ephi2, %pphi2
  %el = call i32 @reference_loop(i32 2, i32 4)
  %pl = call i32 @protected_loop(i32 2, i32 4)
  %okl = icmp eq i32 %el, %pl
  %t0 = and i1 %ok1, %ok1b
  %t1 = and i1 %t0, %ok8
  %t2 = and i1 %t1, %ok8b
  %t3 = and i1 %t2, %ok16
  %t4 = and i1 %t3, %ok16b
  %t5 = and i1 %t4, %ok32
  %t6 = and i1 %t5, %ok64
  %t7 = and i1 %t6, %ok128
  %t8 = and i1 %t7, %okphi
  %t9 = and i1 %t8, %okphi2
  %ok = and i1 %t9, %okl
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_dyn_str: unsupported annotation
; SKIP-DAG: Skipping VMP on unsupported_dyn_line: unsupported annotation
; SKIP-DAG: Skipping VMP on unsupported_poison: unsupported annotation
; SKIP-DAG: Skipping VMP on unsupported_undef: unsupported annotation
; SKIP-DAG: Skipping VMP on unsupported_i2: unsupported
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported annotation
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported annotation
; SKIP-DAG: Skipping VMP on unsupported_indirect: indirect call
; SKIP-DAG: Skipping VMP on unsupported_vararg: variadic call
; SKIP-DAG: Skipping VMP on unsupported_sret: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_noreturn: unsupported annotation
; SKIP-DAG: Skipping VMP on unsupported_returns_twice: unsupported annotation
; SKIP-NOT: Skipping VMP on protected_i1:
; SKIP-NOT: Skipping VMP on protected_i8:
; SKIP-NOT: Skipping VMP on protected_i16:
; SKIP-NOT: Skipping VMP on protected_i32:
; SKIP-NOT: Skipping VMP on protected_i64:
; SKIP-NOT: Skipping VMP on protected_i128:
; SKIP-NOT: Skipping VMP on protected_phi:
; SKIP-NOT: Skipping VMP on protected_loop:

; VIRT: define i32 @protected_i1({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call void @hikari_vmp()
; VIRT-NOT: @llvm.annotation
; VIRT: }
; VIRT: define i8 @protected_i8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: @llvm.annotation
; VIRT: }
; VIRT: define i16 @protected_i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: @llvm.annotation
; VIRT: }
; VIRT: define i32 @protected_i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: @llvm.annotation
; VIRT: }
; VIRT: define i64 @protected_i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: @llvm.annotation
; VIRT: }
; VIRT: define i128 @protected_i128({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: @llvm.annotation
; VIRT: }
; VIRT: define i32 @protected_phi({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: @llvm.annotation
; VIRT: }
; VIRT: define i32 @protected_loop({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: @llvm.annotation
; VIRT: }
; VIRT: define {{.*}} @unsupported_dyn_str({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_dyn_line({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_poison({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_undef({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_i2({{.*}} #[[UNSUP]] {
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
