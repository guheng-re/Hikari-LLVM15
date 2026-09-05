; Scalar llvm.objectsize: fold on the original AS0 pointer at VMP time
; via LLVM 15 getObjectSize + specified-null rules.  Move of that
; constant into the i32/i64 integer VReg.  Never CallDescriptor.
;
; Call replay is unsound: a VReg load is not the alloca/global, so a
; known size would become LangRef-unknown.  Host IntrinsicLowering has
; no objectsize case (lli fatals); references use the DataLayout size.
;
; Accepted only when static (dynamic=false) and the size is definite:
; static alloca, definitive global, constant GEP into those, select of
; two known objects (min/max), AS0 null.  Unknown/dynamic/non-AS0 stay
; skipped — never MustSucceed 0/-1.
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

target datalayout = "e-m:e-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128"
target triple = "aarch64-unknown-linux-gnu"

%Padded = type { i8, i32 }

@g4 = global [4 x i32] zeroinitializer, align 4
@g_as1 = addrspace(1) global i32 0

declare void @hikari_vmp()
declare i64 @llvm.objectsize.i64.p0(ptr, i1 immarg, i1 immarg, i1 immarg)
declare i32 @llvm.objectsize.i32.p0(ptr, i1 immarg, i1 immarg, i1 immarg)
declare i8 @llvm.objectsize.i8.p0(ptr, i1 immarg, i1 immarg, i1 immarg)
declare i128 @llvm.objectsize.i128.p0(ptr, i1 immarg, i1 immarg, i1 immarg)
declare i64 @llvm.objectsize.i64.p1(ptr addrspace(1), i1 immarg, i1 immarg, i1 immarg)
declare void @ext_sret_byval(ptr sret(i32), ptr byval(i32))

; ----- positives: references are the AArch64 alloc-size constants -----

define i64 @reference_alloca() noinline {
entry:
  ret i64 32
}

define i64 @protected_alloca() noinline optnone {
entry:
  call void @hikari_vmp()
  %buf = alloca [8 x i32], align 4
  %s = call i64 @llvm.objectsize.i64.p0(ptr %buf, i1 false, i1 true, i1 false)
  ret i64 %s
}

define i32 @reference_i32() noinline {
entry:
  ret i32 4
}

define i32 @protected_i32() noinline optnone {
entry:
  call void @hikari_vmp()
  %buf = alloca i32, align 4
  %s = call i32 @llvm.objectsize.i32.p0(ptr %buf, i1 false, i1 true, i1 false)
  ret i32 %s
}

define i64 @reference_padded() noinline {
entry:
  ret i64 8
}

define i64 @protected_padded() noinline optnone {
entry:
  call void @hikari_vmp()
  %buf = alloca %Padded, align 4
  %s = call i64 @llvm.objectsize.i64.p0(ptr %buf, i1 false, i1 true, i1 false)
  ret i64 %s
}

define i64 @reference_global() noinline {
entry:
  ret i64 16
}

define i64 @protected_global() noinline optnone {
entry:
  call void @hikari_vmp()
  %s = call i64 @llvm.objectsize.i64.p0(ptr @g4, i1 false, i1 true, i1 false)
  ret i64 %s
}

define i64 @reference_gep() noinline {
entry:
  ret i64 24
}

define i64 @protected_gep() noinline optnone {
entry:
  call void @hikari_vmp()
  %buf = alloca [8 x i32], align 4
  %p = getelementptr [8 x i32], ptr %buf, i64 0, i64 2
  %s = call i64 @llvm.objectsize.i64.p0(ptr %p, i1 false, i1 true, i1 false)
  ret i64 %s
}

define i64 @reference_null() noinline {
entry:
  ret i64 0
}

define i64 @protected_null() noinline optnone {
entry:
  call void @hikari_vmp()
  %s = call i64 @llvm.objectsize.i64.p0(ptr null, i1 false, i1 false, i1 false)
  ret i64 %s
}

define i64 @reference_null_unknown_max() noinline {
entry:
  ret i64 -1
}

define i64 @protected_null_unknown_max() noinline optnone {
entry:
  call void @hikari_vmp()
  %s = call i64 @llvm.objectsize.i64.p0(ptr null, i1 false, i1 true, i1 false)
  ret i64 %s
}

define i64 @reference_null_unknown_min() noinline {
entry:
  ret i64 0
}

define i64 @protected_null_unknown_min() noinline optnone {
entry:
  call void @hikari_vmp()
  %s = call i64 @llvm.objectsize.i64.p0(ptr null, i1 true, i1 true, i1 false)
  ret i64 %s
}

define i64 @reference_select_min(i1 %c) noinline {
entry:
  ret i64 1
}

define i64 @protected_select_min(i1 %c) noinline optnone {
entry:
  call void @hikari_vmp()
  %a = alloca i8, align 1
  %b = alloca [16 x i8], align 1
  %p = select i1 %c, ptr %a, ptr %b
  %s = call i64 @llvm.objectsize.i64.p0(ptr %p, i1 true, i1 true, i1 false)
  ret i64 %s
}

define i64 @reference_select_max(i1 %c) noinline {
entry:
  ret i64 16
}

define i64 @protected_select_max(i1 %c) noinline optnone {
entry:
  call void @hikari_vmp()
  %a = alloca i8, align 1
  %b = alloca [16 x i8], align 1
  %p = select i1 %c, ptr %a, ptr %b
  %s = call i64 @llvm.objectsize.i64.p0(ptr %p, i1 false, i1 true, i1 false)
  ret i64 %s
}

define i64 @reference_loop(i32 %n) noinline {
entry:
  %acc0 = mul i32 %n, 32
  %acc = zext i32 %acc0 to i64
  ret i64 %acc
}

define i64 @protected_loop(i32 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  %buf = alloca [8 x i32], align 4
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %acc = phi i64 [ 0, %entry ], [ %next, %loop ]
  %s = call i64 @llvm.objectsize.i64.p0(ptr %buf, i1 false, i1 true, i1 false)
  %next = add i64 %acc, %s
  %i1 = add i32 %i, 1
  %more = icmp slt i32 %i1, %n
  br i1 %more, label %loop, label %done

done:
  ret i64 %next
}

define i64 @reference_tail() noinline {
entry:
  ret i64 32
}

define i64 @protected_tail() noinline optnone {
entry:
  call void @hikari_vmp()
  %buf = alloca [8 x i32], align 4
  %s = tail call i64 @llvm.objectsize.i64.p0(ptr %buf, i1 false, i1 true, i1 false)
  ret i64 %s
}

; ----- negatives -----

define i64 @unsupported_arg(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %s = call i64 @llvm.objectsize.i64.p0(ptr %p, i1 false, i1 true, i1 false)
  ret i64 %s
}

define i64 @unsupported_inttoptr(i64 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %p = inttoptr i64 %x to ptr
  %s = call i64 @llvm.objectsize.i64.p0(ptr %p, i1 false, i1 true, i1 false)
  ret i64 %s
}

define i64 @unsupported_dynamic() noinline optnone {
entry:
  call void @hikari_vmp()
  %buf = alloca [8 x i32], align 4
  %s = call i64 @llvm.objectsize.i64.p0(ptr %buf, i1 false, i1 true, i1 true)
  ret i64 %s
}

define i64 @unsupported_poison() noinline optnone {
entry:
  call void @hikari_vmp()
  %s = call i64 @llvm.objectsize.i64.p0(ptr poison, i1 false, i1 true, i1 false)
  ret i64 %s
}

define i64 @unsupported_undef() noinline optnone {
entry:
  call void @hikari_vmp()
  %s = call i64 @llvm.objectsize.i64.p0(ptr undef, i1 false, i1 true, i1 false)
  ret i64 %s
}

define i64 @unsupported_as1() noinline optnone {
entry:
  call void @hikari_vmp()
  %s = call i64 @llvm.objectsize.i64.p1(ptr addrspace(1) @g_as1, i1 false, i1 true, i1 false)
  ret i64 %s
}

define i128 @unsupported_i128() noinline optnone {
entry:
  call void @hikari_vmp()
  %buf = alloca [8 x i32], align 4
  %s = call i128 @llvm.objectsize.i128.p0(ptr %buf, i1 false, i1 true, i1 false)
  ret i128 %s
}

define i8 @unsupported_i8() noinline optnone {
entry:
  call void @hikari_vmp()
  %buf = alloca [8 x i32], align 4
  %s = call i8 @llvm.objectsize.i8.p0(ptr %buf, i1 false, i1 true, i1 false)
  ret i8 %s
}

define i64 @unsupported_musttail() noinline optnone {
entry:
  call void @hikari_vmp()
  %buf = alloca [8 x i32], align 4
  %s = musttail call i64 @llvm.objectsize.i64.p0(ptr %buf, i1 false, i1 true, i1 false)
  ret i64 %s
}

define i64 @unsupported_bundle() noinline optnone {
entry:
  call void @hikari_vmp()
  %buf = alloca [8 x i32], align 4
  %s = call i64 @llvm.objectsize.i64.p0(ptr %buf, i1 false, i1 true, i1 false) [ "deopt"(i32 0) ]
  ret i64 %s
}

define i64 @unsupported_fastcc() noinline optnone {
entry:
  call void @hikari_vmp()
  %buf = alloca [8 x i32], align 4
  %s = call fastcc i64 @llvm.objectsize.i64.p0(ptr %buf, i1 false, i1 true, i1 false)
  ret i64 %s
}


define i64 @unsupported_indirect(ptr %fp, ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %s = call i64 %fp(ptr %p) [ "deopt"(i32 0) ]
  ret i64 %s
}

define void @unsupported_sret(ptr sret(i32) %p, ptr byval(i32) %q) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @ext_sret_byval(ptr sret(i32) %p, ptr byval(i32) %q)
  ret void
}

define i32 @main() {
entry:
  %ea = call i64 @reference_alloca()
  %pa = call i64 @protected_alloca()
  %oka = icmp eq i64 %ea, %pa
  %ei = call i32 @reference_i32()
  %pi = call i32 @protected_i32()
  %oki = icmp eq i32 %ei, %pi
  %ep = call i64 @reference_padded()
  %pp = call i64 @protected_padded()
  %okp = icmp eq i64 %ep, %pp
  %eg = call i64 @reference_global()
  %pg = call i64 @protected_global()
  %okg = icmp eq i64 %eg, %pg
  %egep = call i64 @reference_gep()
  %pgep = call i64 @protected_gep()
  %okgep = icmp eq i64 %egep, %pgep
  %en = call i64 @reference_null()
  %pn = call i64 @protected_null()
  %okn = icmp eq i64 %en, %pn
  %enx = call i64 @reference_null_unknown_max()
  %pnx = call i64 @protected_null_unknown_max()
  %oknx = icmp eq i64 %enx, %pnx
  %enn = call i64 @reference_null_unknown_min()
  %pnn = call i64 @protected_null_unknown_min()
  %oknn = icmp eq i64 %enn, %pnn
  %esmin = call i64 @reference_select_min(i1 true)
  %psmin = call i64 @protected_select_min(i1 true)
  %oksmin = icmp eq i64 %esmin, %psmin
  %esmin2 = call i64 @reference_select_min(i1 false)
  %psmin2 = call i64 @protected_select_min(i1 false)
  %oksmin2 = icmp eq i64 %esmin2, %psmin2
  %esmax = call i64 @reference_select_max(i1 true)
  %psmax = call i64 @protected_select_max(i1 true)
  %oksmax = icmp eq i64 %esmax, %psmax
  %esmax2 = call i64 @reference_select_max(i1 false)
  %psmax2 = call i64 @protected_select_max(i1 false)
  %oksmax2 = icmp eq i64 %esmax2, %psmax2
  %el = call i64 @reference_loop(i32 3)
  %pl = call i64 @protected_loop(i32 3)
  %okl = icmp eq i64 %el, %pl
  %et = call i64 @reference_tail()
  %pt = call i64 @protected_tail()
  %okt = icmp eq i64 %et, %pt
  %t0 = and i1 %oka, %oki
  %t1 = and i1 %t0, %okp
  %t2 = and i1 %t1, %okg
  %t3 = and i1 %t2, %okgep
  %t4 = and i1 %t3, %okn
  %t5 = and i1 %t4, %oknx
  %t6 = and i1 %t5, %oknn
  %t7 = and i1 %t6, %oksmin
  %t8 = and i1 %t7, %oksmin2
  %t9 = and i1 %t8, %oksmax
  %t10 = and i1 %t9, %oksmax2
  %t11 = and i1 %t10, %okl
  %ok = and i1 %t11, %okt
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_arg: unsupported objectsize
; SKIP-DAG: Skipping VMP on unsupported_inttoptr: unsupported objectsize
; SKIP-DAG: Skipping VMP on unsupported_dynamic: unsupported objectsize
; SKIP-DAG: Skipping VMP on unsupported_poison: unsupported objectsize
; SKIP-DAG: Skipping VMP on unsupported_undef: unsupported objectsize
; SKIP-DAG: Skipping VMP on unsupported_as1: unsupported objectsize
; SKIP-DAG: Skipping VMP on unsupported_i128: unsupported objectsize
; SKIP-DAG: Skipping VMP on unsupported_i8: unsupported objectsize
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported objectsize
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported objectsize
; SKIP-DAG: Skipping VMP on unsupported_indirect: indirect call
; SKIP-DAG: Skipping VMP on unsupported_sret: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_alloca:
; SKIP-NOT: Skipping VMP on protected_i32:
; SKIP-NOT: Skipping VMP on protected_padded:
; SKIP-NOT: Skipping VMP on protected_global:
; SKIP-NOT: Skipping VMP on protected_gep:
; SKIP-NOT: Skipping VMP on protected_null:
; SKIP-NOT: Skipping VMP on protected_null_unknown_max:
; SKIP-NOT: Skipping VMP on protected_null_unknown_min:
; SKIP-NOT: Skipping VMP on protected_select_min:
; SKIP-NOT: Skipping VMP on protected_select_max:
; SKIP-NOT: Skipping VMP on protected_loop:
; SKIP-NOT: Skipping VMP on protected_tail:

; VIRT: define i64 @protected_alloca({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call void @hikari_vmp()
; VIRT-NOT: @llvm.objectsize
; VIRT: }
; VIRT: define i32 @protected_i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: @llvm.objectsize
; VIRT: }
; VIRT: define i64 @protected_padded({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: @llvm.objectsize
; VIRT: }
; VIRT: define i64 @protected_global({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: @llvm.objectsize
; VIRT: }
; VIRT: define i64 @protected_gep({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: @llvm.objectsize
; VIRT: }
; VIRT: define i64 @protected_null({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: @llvm.objectsize
; VIRT: }
; VIRT: define i64 @protected_null_unknown_max({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: @llvm.objectsize
; VIRT: }
; VIRT: define i64 @protected_null_unknown_min({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: @llvm.objectsize
; VIRT: }
; VIRT: define i64 @protected_select_min({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: @llvm.objectsize
; VIRT: }
; VIRT: define i64 @protected_select_max({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: @llvm.objectsize
; VIRT: }
; VIRT: define i64 @protected_loop({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: @llvm.objectsize
; VIRT: }
; VIRT: define i64 @protected_tail({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: tail call
; VIRT-NOT: @llvm.objectsize
; VIRT: }
; VIRT: define {{.*}} @unsupported_arg({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_inttoptr({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_dynamic({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_poison({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_undef({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_as1({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_i128({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_i8({{.*}} #[[UNSUP]] {
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
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPMUST]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPMUST]] = { {{.*}}"hikari.vmp.selected"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
