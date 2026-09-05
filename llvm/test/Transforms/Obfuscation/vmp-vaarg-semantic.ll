; Conservative same-function C va_start / va_arg / va_end.
; The protected function itself is CallingConv::C variadic.  The va_list
; is an entry static alloca of the System V x86_64 va_list object so
; host lli (ORC JIT after the triple swap) can lower va_start/va_arg.
; AArch64 llc still consumes the same IR for object generation.
; i32 / i64 / double / AS0 pointer through a dedicated VAArg opcode that
; restores the list address from the pointer VReg and emits a native
; va_arg (memory cursor updated).  va_start / va_end replay via Call.
; Different extra-arg counts, a consuming loop, a branch that picks
; i32 vs i64, and a store/load through a pointer tail are compared
; against an unprotected reference.  One restricted va_copy form is
; accepted: two entry static va_lists, one va_start on the source, one
; va_copy onto the dest, va_arg from both, va_end on both.  Repeated /
; chained copy, missing va_end, copy after source va_end, va_arg after
; source or dest va_end, float va_arg, non-entry lists, and a
; variadic-tail Call from a vararg function stay skipped.
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
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.live.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.s7.ll > %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.s7.live.ll > %t.o0.s7.host.ll
; RUN: lli -force-interpreter %t.o0.s7.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.s7.ll > %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.s7.live.ll > %t.o2.s7.host.ll
; RUN: lli -force-interpreter %t.o2.s7.host.ll

target triple = "aarch64-unknown-linux-gnu"

; Host-lli / x86_64 System V va_list.  Entry static alloca of this
; object is the unique va_list the conservative VMP gate accepts.
%va_list = type { i32, i32, ptr, ptr }

@g = global i32 7
@h = global i32 9

declare void @hikari_vmp()
declare void @llvm.va_start(ptr)
declare void @llvm.va_end(ptr)
declare void @llvm.va_copy(ptr, ptr)
declare i32 @opaque_var(i32, ...)
declare i32 @sink_i32(ptr, i32)
declare void @ext_sret_byval(ptr sret(i32), ptr byval(i32))

define i32 @reference_mix(i32 %n, ...) noinline optnone {
entry:
  %ap = alloca %va_list, align 8
  call void @llvm.va_start(ptr %ap)
  %a = va_arg ptr %ap, i32
  %b = va_arg ptr %ap, i64
  %c = va_arg ptr %ap, double
  %p = va_arg ptr %ap, ptr
  call void @llvm.va_end(ptr %ap)
  %blo = trunc i64 %b to i32
  %bhi64 = lshr i64 %b, 32
  %bhi = trunc i64 %bhi64 to i32
  %cbits = bitcast double %c to i64
  %clo = trunc i64 %cbits to i32
  %chi64 = lshr i64 %cbits, 32
  %chi = trunc i64 %chi64 to i32
  %pv = load i32, ptr %p, align 4
  %pi = ptrtoint ptr %p to i64
  %plo = trunc i64 %pi to i32
  %aw = mul i32 %a, 5
  %b.sum = add i32 %blo, %bhi
  %bw = mul i32 %b.sum, 7
  %c.xor = xor i32 %clo, %chi
  %cw = mul i32 %c.xor, 11
  %p.sum = add i32 %pv, %plo
  %pw = mul i32 %p.sum, 13
  %r0 = add i32 %n, %aw
  %r1 = add i32 %r0, %bw
  %r2 = add i32 %r1, %cw
  %r = add i32 %r2, %pw
  ret i32 %r
}

define i32 @protected_mix(i32 %n, ...) noinline optnone {
entry:
  call void @hikari_vmp()
  %ap = alloca %va_list, align 8
  call void @llvm.va_start(ptr %ap)
  %a = va_arg ptr %ap, i32
  %b = va_arg ptr %ap, i64
  %c = va_arg ptr %ap, double
  %p = va_arg ptr %ap, ptr
  call void @llvm.va_end(ptr %ap)
  %blo = trunc i64 %b to i32
  %bhi64 = lshr i64 %b, 32
  %bhi = trunc i64 %bhi64 to i32
  %cbits = bitcast double %c to i64
  %clo = trunc i64 %cbits to i32
  %chi64 = lshr i64 %cbits, 32
  %chi = trunc i64 %chi64 to i32
  %pv = load i32, ptr %p, align 4
  %pi = ptrtoint ptr %p to i64
  %plo = trunc i64 %pi to i32
  %aw = mul i32 %a, 5
  %b.sum = add i32 %blo, %bhi
  %bw = mul i32 %b.sum, 7
  %c.xor = xor i32 %clo, %chi
  %cw = mul i32 %c.xor, 11
  %p.sum = add i32 %pv, %plo
  %pw = mul i32 %p.sum, 13
  %r0 = add i32 %n, %aw
  %r1 = add i32 %r0, %bw
  %r2 = add i32 %r1, %cw
  %r = add i32 %r2, %pw
  ret i32 %r
}

define i32 @reference_loop(i32 %n, ...) noinline optnone {
entry:
  %ap = alloca %va_list, align 8
  call void @llvm.va_start(ptr %ap)
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %i.next, %loop ]
  %acc = phi i32 [ %n, %entry ], [ %acc.next, %loop ]
  %v = va_arg ptr %ap, i32
  %acc.next = xor i32 %acc, %v
  %i.next = add i32 %i, 1
  %more = icmp ult i32 %i.next, %n
  br i1 %more, label %loop, label %done

done:
  call void @llvm.va_end(ptr %ap)
  ret i32 %acc.next
}

define i32 @protected_loop(i32 %n, ...) noinline optnone {
entry:
  call void @hikari_vmp()
  %ap = alloca %va_list, align 8
  call void @llvm.va_start(ptr %ap)
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %i.next, %loop ]
  %acc = phi i32 [ %n, %entry ], [ %acc.next, %loop ]
  %v = va_arg ptr %ap, i32
  %acc.next = xor i32 %acc, %v
  %i.next = add i32 %i, 1
  %more = icmp ult i32 %i.next, %n
  br i1 %more, label %loop, label %done

done:
  call void @llvm.va_end(ptr %ap)
  ret i32 %acc.next
}

; n != 0 consumes i32 then i32; n == 0 consumes i64 then i32.
define i32 @reference_branch(i32 %n, ...) noinline optnone {
entry:
  %ap = alloca %va_list, align 8
  call void @llvm.va_start(ptr %ap)
  %nz = icmp ne i32 %n, 0
  br i1 %nz, label %take32, label %take64

take32:
  %x32 = va_arg ptr %ap, i32
  %x32z = zext i32 %x32 to i64
  br label %join

take64:
  %x64 = va_arg ptr %ap, i64
  br label %join

join:
  %x = phi i64 [ %x32z, %take32 ], [ %x64, %take64 ]
  %y = va_arg ptr %ap, i32
  call void @llvm.va_end(ptr %ap)
  %xh = trunc i64 %x to i32
  %r0 = xor i32 %xh, %y
  %r = xor i32 %r0, %n
  ret i32 %r
}

define i32 @protected_branch(i32 %n, ...) noinline optnone {
entry:
  call void @hikari_vmp()
  %ap = alloca %va_list, align 8
  call void @llvm.va_start(ptr %ap)
  %nz = icmp ne i32 %n, 0
  br i1 %nz, label %take32, label %take64

take32:
  %x32 = va_arg ptr %ap, i32
  %x32z = zext i32 %x32 to i64
  br label %join

take64:
  %x64 = va_arg ptr %ap, i64
  br label %join

join:
  %x = phi i64 [ %x32z, %take32 ], [ %x64, %take64 ]
  %y = va_arg ptr %ap, i32
  call void @llvm.va_end(ptr %ap)
  %xh = trunc i64 %x to i32
  %r0 = xor i32 %xh, %y
  %r = xor i32 %r0, %n
  ret i32 %r
}

define i32 @reference_mem(i32 %n, ...) noinline optnone {
entry:
  %ap = alloca %va_list, align 8
  call void @llvm.va_start(ptr %ap)
  %v = va_arg ptr %ap, i32
  %p = va_arg ptr %ap, ptr
  call void @llvm.va_end(ptr %ap)
  store i32 %v, ptr %p, align 4
  %ld = load i32, ptr %p, align 4
  %r = xor i32 %ld, %n
  ret i32 %r
}

define i32 @protected_mem(i32 %n, ...) noinline optnone {
entry:
  call void @hikari_vmp()
  %ap = alloca %va_list, align 8
  call void @llvm.va_start(ptr %ap)
  %v = va_arg ptr %ap, i32
  %p = va_arg ptr %ap, ptr
  call void @llvm.va_end(ptr %ap)
  store i32 %v, ptr %p, align 4
  %ld = load i32, ptr %p, align 4
  %r = xor i32 %ld, %n
  ret i32 %r
}

; Snapshot then independent cursors: after copy, two va_arg on ap
; then one va_arg on aq.  Independent lists yield the first extra on
; aq; a shared cursor would yield the third extra.
define i32 @reference_vacopy(i32 %n, ...) noinline optnone {
entry:
  %ap = alloca %va_list, align 8
  %aq = alloca %va_list, align 8
  call void @llvm.va_start(ptr %ap)
  call void @llvm.va_copy(ptr %aq, ptr %ap)
  %a0 = va_arg ptr %ap, i32
  %a1 = va_arg ptr %ap, i32
  %b0 = va_arg ptr %aq, i32
  %b1 = va_arg ptr %aq, i32
  call void @llvm.va_end(ptr %ap)
  call void @llvm.va_end(ptr %aq)
  %t0 = mul i32 %a0, 3
  %t1 = mul i32 %a1, 5
  %t2 = mul i32 %b0, 7
  %t3 = mul i32 %b1, 11
  %r0 = add i32 %n, %t0
  %r1 = add i32 %r0, %t1
  %r2 = add i32 %r1, %t2
  %r = add i32 %r2, %t3
  ret i32 %r
}

define i32 @protected_vacopy(i32 %n, ...) noinline optnone {
entry:
  call void @hikari_vmp()
  %ap = alloca %va_list, align 8
  %aq = alloca %va_list, align 8
  call void @llvm.va_start(ptr %ap)
  call void @llvm.va_copy(ptr %aq, ptr %ap)
  %a0 = va_arg ptr %ap, i32
  %a1 = va_arg ptr %ap, i32
  %b0 = va_arg ptr %aq, i32
  %b1 = va_arg ptr %aq, i32
  call void @llvm.va_end(ptr %ap)
  call void @llvm.va_end(ptr %aq)
  %t0 = mul i32 %a0, 3
  %t1 = mul i32 %a1, 5
  %t2 = mul i32 %b0, 7
  %t3 = mul i32 %b1, 11
  %r0 = add i32 %n, %t0
  %r1 = add i32 %r0, %t1
  %r2 = add i32 %r1, %t2
  %r = add i32 %r2, %t3
  ret i32 %r
}

; Repeated copy of the same source.
define i32 @unsupported_vacopy_dup(i32 %n, ...) noinline optnone {
entry:
  call void @hikari_vmp()
  %ap = alloca %va_list, align 8
  %aq = alloca %va_list, align 8
  %ar = alloca %va_list, align 8
  call void @llvm.va_start(ptr %ap)
  call void @llvm.va_copy(ptr %aq, ptr %ap)
  call void @llvm.va_copy(ptr %ar, ptr %ap)
  %v = va_arg ptr %ap, i32
  call void @llvm.va_end(ptr %ap)
  call void @llvm.va_end(ptr %aq)
  call void @llvm.va_end(ptr %ar)
  ret i32 %v
}

; Chained copy: dest of the first copy is src of the second.
define i32 @unsupported_vacopy_chain(i32 %n, ...) noinline optnone {
entry:
  call void @hikari_vmp()
  %ap = alloca %va_list, align 8
  %aq = alloca %va_list, align 8
  %ar = alloca %va_list, align 8
  call void @llvm.va_start(ptr %ap)
  call void @llvm.va_copy(ptr %aq, ptr %ap)
  call void @llvm.va_copy(ptr %ar, ptr %aq)
  %v = va_arg ptr %ar, i32
  call void @llvm.va_end(ptr %ap)
  call void @llvm.va_end(ptr %aq)
  call void @llvm.va_end(ptr %ar)
  ret i32 %v
}

; Copy from a source list that has already been va_end'd.
define i32 @unsupported_vacopy_after_end(i32 %n, ...) noinline optnone {
entry:
  call void @hikari_vmp()
  %ap = alloca %va_list, align 8
  %aq = alloca %va_list, align 8
  call void @llvm.va_start(ptr %ap)
  call void @llvm.va_end(ptr %ap)
  call void @llvm.va_copy(ptr %aq, ptr %ap)
  %v = va_arg ptr %aq, i32
  call void @llvm.va_end(ptr %aq)
  ret i32 %v
}

; va_arg on the source after its va_end.
define i32 @unsupported_vaarg_after_src_end(i32 %n, ...) noinline optnone {
entry:
  call void @hikari_vmp()
  %ap = alloca %va_list, align 8
  %aq = alloca %va_list, align 8
  call void @llvm.va_start(ptr %ap)
  call void @llvm.va_copy(ptr %aq, ptr %ap)
  call void @llvm.va_end(ptr %ap)
  %v = va_arg ptr %ap, i32
  call void @llvm.va_end(ptr %aq)
  ret i32 %v
}

; va_arg on the dest after its va_end.
define i32 @unsupported_vaarg_after_dest_end(i32 %n, ...) noinline optnone {
entry:
  call void @hikari_vmp()
  %ap = alloca %va_list, align 8
  %aq = alloca %va_list, align 8
  call void @llvm.va_start(ptr %ap)
  call void @llvm.va_copy(ptr %aq, ptr %ap)
  call void @llvm.va_end(ptr %aq)
  %v = va_arg ptr %aq, i32
  call void @llvm.va_end(ptr %ap)
  ret i32 %v
}

; Dest list never va_end'd.
define i32 @unsupported_vacopy_noend(i32 %n, ...) noinline optnone {
entry:
  call void @hikari_vmp()
  %ap = alloca %va_list, align 8
  %aq = alloca %va_list, align 8
  call void @llvm.va_start(ptr %ap)
  call void @llvm.va_copy(ptr %aq, ptr %ap)
  %v = va_arg ptr %aq, i32
  call void @llvm.va_end(ptr %ap)
  ret i32 %v
}

define i32 @unsupported_float_vaarg(i32 %n, ...) noinline optnone {
entry:
  call void @hikari_vmp()
  %ap = alloca %va_list, align 8
  call void @llvm.va_start(ptr %ap)
  %f = va_arg ptr %ap, float
  call void @llvm.va_end(ptr %ap)
  %b = bitcast float %f to i32
  ret i32 %b
}

define i32 @unsupported_nonentry_valist(i32 %n, ...) noinline optnone {
entry:
  call void @hikari_vmp()
  br label %bb

bb:
  %ap = alloca %va_list, align 8
  call void @llvm.va_start(ptr %ap)
  %v = va_arg ptr %ap, i32
  call void @llvm.va_end(ptr %ap)
  ret i32 %v
}

define i32 @unsupported_vararg_call(i32 %n, ...) noinline optnone {
entry:
  call void @hikari_vmp()
  %ap = alloca %va_list, align 8
  call void @llvm.va_start(ptr %ap)
  %x = va_arg ptr %ap, i32
  call void @llvm.va_end(ptr %ap)
  %r = call i32 (i32, ...) @opaque_var(i32 %n, i32 %x)
  ret i32 %r
}


define i32 @unsupported_fastcc_vastart(i32 %n, ...) noinline optnone {
entry:
  call void @hikari_vmp()
  %ap = alloca %va_list, align 8
  call fastcc void @llvm.va_start(ptr %ap)
  %v = va_arg ptr %ap, i32
  call void @llvm.va_end(ptr %ap)
  ret i32 %v
}

define i32 @unsupported_noreturn_vastart(i32 %n, ...) noinline optnone {
entry:
  call void @hikari_vmp()
  %ap = alloca %va_list, align 8
  call void @llvm.va_start(ptr %ap) noreturn
  %v = va_arg ptr %ap, i32
  call void @llvm.va_end(ptr %ap)
  ret i32 %v
}

define i32 @unsupported_bundle_vastart(i32 %n, ...) noinline optnone {
entry:
  call void @hikari_vmp()
  %ap = alloca %va_list, align 8
  call void @llvm.va_start(ptr %ap) [ "deopt"(i32 0) ]
  %v = va_arg ptr %ap, i32
  call void @llvm.va_end(ptr %ap)
  ret i32 %v
}

define i32 @unsupported_as1_arg(ptr addrspace(1) %unused, i32 %n, ...) noinline optnone {
entry:
  call void @hikari_vmp()
  %ap = alloca %va_list, align 8
  call void @llvm.va_start(ptr %ap)
  %v = va_arg ptr %ap, i32
  call void @llvm.va_end(ptr %ap)
  ret i32 %v
}

define i32 @unsupported_vacopy_same(i32 %n, ...) noinline optnone {
entry:
  call void @hikari_vmp()
  %ap = alloca %va_list, align 8
  call void @llvm.va_start(ptr %ap)
  call void @llvm.va_copy(ptr %ap, ptr %ap)
  %v = va_arg ptr %ap, i32
  call void @llvm.va_end(ptr %ap)
  ret i32 %v
}

define i32 @unsupported_musttail(ptr %p, i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call i32 @sink_i32(ptr %p, i32 %x)
  ret i32 %r
}

define void @unsupported_sret(ptr sret(i32) %p, ptr byval(i32) %q) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @ext_sret_byval(ptr sret(i32) %p, ptr byval(i32) %q)
  ret void
}

define i32 @main() {
entry:
  %e0 = call i32 (i32, ...) @reference_mix(i32 1, i32 3, i64 4, double 5.000000e+00, ptr @g)
  %a0 = call i32 (i32, ...) @protected_mix(i32 1, i32 3, i64 4, double 5.000000e+00, ptr @g)
  %ok0 = icmp eq i32 %e0, %a0
  %e1 = call i32 (i32, ...) @reference_mix(i32 10, i32 0, i64 0, double 0.000000e+00, ptr @h)
  %a1 = call i32 (i32, ...) @protected_mix(i32 10, i32 0, i64 0, double 0.000000e+00, ptr @h)
  %ok1 = icmp eq i32 %e1, %a1
  %e2 = call i32 (i32, ...) @reference_loop(i32 3, i32 10, i32 20, i32 30)
  %a2 = call i32 (i32, ...) @protected_loop(i32 3, i32 10, i32 20, i32 30)
  %ok2 = icmp eq i32 %e2, %a2
  %e3 = call i32 (i32, ...) @reference_loop(i32 2, i32 7, i32 8)
  %a3 = call i32 (i32, ...) @protected_loop(i32 2, i32 7, i32 8)
  %ok3 = icmp eq i32 %e3, %a3
  %diff.loop = icmp ne i32 %e2, %e3
  %e4 = call i32 (i32, ...) @reference_branch(i32 1, i32 5, i32 9)
  %a4 = call i32 (i32, ...) @protected_branch(i32 1, i32 5, i32 9)
  %ok4 = icmp eq i32 %e4, %a4
  %e5 = call i32 (i32, ...) @reference_branch(i32 0, i64 4294967301, i32 9)
  %a5 = call i32 (i32, ...) @protected_branch(i32 0, i64 4294967301, i32 9)
  %ok5 = icmp eq i32 %e5, %a5
  %diff.br = icmp ne i32 %e4, %e5
  %sref = alloca i32, align 4
  %sprot = alloca i32, align 4
  store i32 0, ptr %sref, align 4
  store i32 0, ptr %sprot, align 4
  %e6 = call i32 (i32, ...) @reference_mem(i32 4, i32 21, ptr %sref)
  %a6 = call i32 (i32, ...) @protected_mem(i32 4, i32 21, ptr %sprot)
  %ok6r = icmp eq i32 %e6, %a6
  %mref = load i32, ptr %sref, align 4
  %mprot = load i32, ptr %sprot, align 4
  %ok6m = icmp eq i32 %mref, %mprot
  %expect = icmp eq i32 %mref, 21
  %t0 = and i1 %ok0, %ok1
  %t1 = and i1 %ok2, %ok3
  %t2 = and i1 %ok4, %ok5
  %t3 = and i1 %ok6r, %ok6m
  %t4 = and i1 %t0, %t1
  %t5 = and i1 %t2, %t3
  %t6 = and i1 %t4, %t5
  %t7 = and i1 %diff.loop, %diff.br
  %t8 = and i1 %t6, %t7
  %e7 = call i32 (i32, ...) @reference_vacopy(i32 1, i32 10, i32 20, i32 30, i32 40)
  %a7 = call i32 (i32, ...) @protected_vacopy(i32 1, i32 10, i32 20, i32 30, i32 40)
  %ok7 = icmp eq i32 %e7, %a7
  ; Independent cursors: 1 + 3*10 + 5*20 + 7*10 + 11*20 = 1+30+100+70+220 = 421
  ; Shared cursor would be 1 + 3*10 + 5*20 + 7*30 + 11*40 = 761
  %expect.copy = icmp eq i32 %e7, 421
  %t9 = and i1 %t8, %ok7
  %ok = and i1 %t9, %expect
  %okc = and i1 %ok, %expect.copy
  %code = select i1 %okc, i32 0, i32 1
  ret i32 %code
}

; SKIP-DAG: Skipping VMP on unsupported_vacopy_dup: unsupported va_arg instruction
; SKIP-DAG: Skipping VMP on unsupported_vacopy_chain: unsupported va_arg instruction
; SKIP-DAG: Skipping VMP on unsupported_vacopy_after_end: unsupported va_arg instruction
; SKIP-DAG: Skipping VMP on unsupported_vaarg_after_src_end: unsupported va_arg instruction
; SKIP-DAG: Skipping VMP on unsupported_vaarg_after_dest_end: unsupported va_arg instruction
; SKIP-DAG: Skipping VMP on unsupported_vacopy_noend: unsupported va_arg instruction
; SKIP-DAG: Skipping VMP on unsupported_float_vaarg: unsupported va_arg instruction
; SKIP-DAG: Skipping VMP on unsupported_nonentry_valist: unsupported va_arg instruction
; SKIP-DAG: Skipping VMP on unsupported_vararg_call: variadic call
; SKIP-DAG: Skipping VMP on unsupported_fastcc_vastart: unsupported va_start
; SKIP-DAG: Skipping VMP on unsupported_noreturn_vastart: unsupported va_start
; SKIP-DAG: Skipping VMP on unsupported_bundle_vastart: unsupported va_start
; SKIP-DAG: Skipping VMP on unsupported_as1_arg: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_vacopy_same: unsupported va_copy
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_sret: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_mix:
; SKIP-NOT: Skipping VMP on protected_loop:
; SKIP-NOT: Skipping VMP on protected_branch:
; SKIP-NOT: Skipping VMP on protected_mem:
; SKIP-NOT: Skipping VMP on protected_vacopy:
; SKIP-NOT: Skipping VMP on reference_mix:
; SKIP-NOT: Skipping VMP on reference_loop:
; SKIP-NOT: Skipping VMP on reference_branch:
; SKIP-NOT: Skipping VMP on reference_mem:
; SKIP-NOT: Skipping VMP on reference_vacopy:

; VIRT-LABEL: define i32 @protected_mix(i32 %n, ...)
; VIRT: vmp.dispatch:
; VIRT-DAG: call void @llvm.va_start(ptr
; VIRT-DAG: va_arg ptr {{.*}}, i32
; VIRT-DAG: va_arg ptr {{.*}}, i64
; VIRT-DAG: va_arg ptr {{.*}}, double
; VIRT-DAG: va_arg ptr {{.*}}, ptr
; VIRT-DAG: call void @llvm.va_end(ptr
; VIRT-LABEL: define i32 @protected_loop(i32 %n, ...)
; VIRT: vmp.dispatch:
; VIRT-DAG: call void @llvm.va_start(ptr
; VIRT-DAG: va_arg ptr {{.*}}, i32
; VIRT-DAG: call void @llvm.va_end(ptr
; VIRT-LABEL: define i32 @protected_branch(i32 %n, ...)
; VIRT: vmp.dispatch:
; VIRT-DAG: va_arg ptr {{.*}}, i32
; VIRT-DAG: va_arg ptr {{.*}}, i64
; VIRT-LABEL: define i32 @protected_mem(i32 %n, ...)
; VIRT: vmp.dispatch:
; VIRT-DAG: va_arg ptr {{.*}}, i32
; VIRT-DAG: va_arg ptr {{.*}}, ptr
; VIRT-LABEL: define i32 @protected_vacopy(i32 %n, ...)
; VIRT: vmp.dispatch:
; VIRT-DAG: call void @llvm.va_start(ptr
; VIRT-DAG: call void @llvm.va_copy(ptr
; VIRT-DAG: va_arg ptr {{.*}}, i32
; VIRT-DAG: call void @llvm.va_end(ptr
; VIRT: define {{.*}} @unsupported_vacopy_dup({{.*}} #[[UNSUPATTR:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_vacopy_chain({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_vacopy_after_end({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_vaarg_after_src_end({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_vaarg_after_dest_end({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_vacopy_noend({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_float_vaarg({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_nonentry_valist({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_vararg_call({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fastcc_vastart({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_noreturn_vastart({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_bundle_vastart({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_as1_arg({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_vacopy_same({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_musttail({{.*}} #[[UNSUPMUST:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call i32 @sink_i32(
; VIRT: define {{.*}} @unsupported_sret({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #{{[0-9]+}} = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPMUST]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPMUST]] = { {{.*}}"hikari.vmp.selected"

; AARCH64: Arch: aarch64
