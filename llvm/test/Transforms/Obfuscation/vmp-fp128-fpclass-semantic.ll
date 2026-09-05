; Scalar IEEE fp128 llvm.is.fpclass.f128: i1 result, one scalar fp128
; operand, i32 ConstantInt ImmArg class mask (LangRef bits 0..9,
; 0..1023).  Replayed through CallDescriptor as CreateCall of the
; original Function* on the typed vmp.fp128.regs frame.  The mask
; stays a true i32 constant, never a VReg.  Never i128
; reinterpretation.  LLVM 15 AArch64 and host x86 select this
; intrinsic (libcall / expanded class tests).
;
; Masks: fcNan=3, fcInf=516, fcZero=96, fcNormal=264, fcSubnormal=144.
; Ordinary tail of an already-supported CallInst is accepted and replayed as a non-tail call; see vmp-direct-call-tail-eligibility-semantic.ll.
;
; Rejected: constrained, vector, ppc_fp128, out-of-range mask,
; poison/undef, musttail, bundles, inline asm, invalid ABI.
;
; Host lli compares reference vs protected after dropping unsupported
; bodies.  FileCheck + lli + AArch64 llc/readobj.  O0/O2 x aesSeed 97/7.
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

declare void @hikari_vmp()
declare i1 @llvm.is.fpclass.f128(fp128, i32)
declare <1 x i1> @llvm.is.fpclass.v1f128(<1 x fp128>, i32)
declare i1 @llvm.is.fpclass.ppcf128(ppc_fp128, i32)
declare fp128 @llvm.experimental.constrained.fmul.f128(fp128, fp128, metadata, metadata)
declare void @ext_fp128_sret(ptr sret(i32), fp128)

define i1 @reference_nan(fp128 %a) noinline {
entry:
  %r = call i1 @llvm.is.fpclass.f128(fp128 %a, i32 3)
  ret i1 %r
}

define i1 @protected_nan(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i1 @llvm.is.fpclass.f128(fp128 %a, i32 3)
  ret i1 %r
}

define i1 @reference_inf(fp128 %a) noinline {
entry:
  %r = call i1 @llvm.is.fpclass.f128(fp128 %a, i32 516)
  ret i1 %r
}

define i1 @protected_inf(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i1 @llvm.is.fpclass.f128(fp128 %a, i32 516)
  ret i1 %r
}

define i1 @reference_zero(fp128 %a) noinline {
entry:
  %r = call i1 @llvm.is.fpclass.f128(fp128 %a, i32 96)
  ret i1 %r
}

define i1 @protected_zero(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i1 @llvm.is.fpclass.f128(fp128 %a, i32 96)
  ret i1 %r
}

define i1 @reference_normal(fp128 %a) noinline {
entry:
  %r = call i1 @llvm.is.fpclass.f128(fp128 %a, i32 264)
  ret i1 %r
}

define i1 @protected_normal(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i1 @llvm.is.fpclass.f128(fp128 %a, i32 264)
  ret i1 %r
}

define i1 @reference_sub(fp128 %a) noinline {
entry:
  %r = call i1 @llvm.is.fpclass.f128(fp128 %a, i32 144)
  ret i1 %r
}

define i1 @protected_sub(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i1 @llvm.is.fpclass.f128(fp128 %a, i32 144)
  ret i1 %r
}

define i1 @reference_phi(i1 %c, fp128 %a, fp128 %b) noinline {
entry:
  br i1 %c, label %left, label %right

left:
  %ln = call i1 @llvm.is.fpclass.f128(fp128 %a, i32 264)
  br label %join

right:
  %rz = call i1 @llvm.is.fpclass.f128(fp128 %b, i32 96)
  br label %join

join:
  %p = phi i1 [ %ln, %left ], [ %rz, %right ]
  ret i1 %p
}

define i1 @protected_phi(i1 %c, fp128 %a, fp128 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  br i1 %c, label %left, label %right

left:
  %ln = call i1 @llvm.is.fpclass.f128(fp128 %a, i32 264)
  br label %join

right:
  %rz = call i1 @llvm.is.fpclass.f128(fp128 %b, i32 96)
  br label %join

join:
  %p = phi i1 [ %ln, %left ], [ %rz, %right ]
  ret i1 %p
}

define i32 @reference_loop(fp128 %a, i32 %n) noinline {
entry:
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %acc = phi i32 [ 0, %entry ], [ %next, %loop ]
  %hit = call i1 @llvm.is.fpclass.f128(fp128 %a, i32 264)
  %z = zext i1 %hit to i32
  %next = add i32 %acc, %z
  %i1 = add i32 %i, 1
  %more = icmp slt i32 %i1, %n
  br i1 %more, label %loop, label %done

done:
  ret i32 %next
}

define i32 @protected_loop(fp128 %a, i32 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %acc = phi i32 [ 0, %entry ], [ %next, %loop ]
  %hit = call i1 @llvm.is.fpclass.f128(fp128 %a, i32 264)
  %z = zext i1 %hit to i32
  %next = add i32 %acc, %z
  %i1 = add i32 %i, 1
  %more = icmp slt i32 %i1, %n
  br i1 %more, label %loop, label %done

done:
  ret i32 %next
}

define i1 @reference_tail(fp128 %a) noinline {
entry:
  %r = tail call i1 @llvm.is.fpclass.f128(fp128 %a, i32 264)
  ret i1 %r
}


; ----- negatives -----

define fp128 @unsupported_constrained(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 @llvm.experimental.constrained.fmul.f128(fp128 %a, fp128 %a, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret fp128 %r
}

define <1 x i1> @unsupported_vector(<1 x fp128> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <1 x i1> @llvm.is.fpclass.v1f128(<1 x fp128> %a, i32 3)
  ret <1 x i1> %r
}

define i1 @unsupported_ppc(ppc_fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i1 @llvm.is.fpclass.ppcf128(ppc_fp128 %a, i32 3)
  ret i1 %r
}

define i1 @unsupported_mask_oor(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i1 @llvm.is.fpclass.f128(fp128 %a, i32 1024)
  ret i1 %r
}

define i1 @unsupported_poison(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i1 @llvm.is.fpclass.f128(fp128 poison, i32 3)
  ret i1 %r
}

define i1 @unsupported_undef(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i1 @llvm.is.fpclass.f128(fp128 undef, i32 3)
  ret i1 %r
}

define i1 @unsupported_musttail(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call i1 @llvm.is.fpclass.f128(fp128 %a, i32 3)
  ret i1 %r
}

define i1 @unsupported_bundle(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i1 @llvm.is.fpclass.f128(fp128 %a, i32 3) [ "deopt"() ]
  ret i1 %r
}

define i1 @unsupported_asm(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i1 asm "", "=r,w"(fp128 %a)
  ret i1 %r
}

define i1 @unsupported_indirect(ptr %fp, fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i1 %fp(fp128 %a)
  ret i1 %r
}

define void @unsupported_sret(ptr sret(i32) %p, fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @ext_fp128_sret(ptr sret(i32) %p, fp128 %a)
  ret void
}

define i32 @main() {
entry:
  %one = fpext double 1.500000e+00 to fp128
  %zero = fpext double 0.000000e+00 to fp128
  %nzero = fneg fp128 %zero
  %inf = fdiv fp128 %one, %zero
  %ninf = fneg fp128 %inf
  %nan = fdiv fp128 %zero, %zero
  %dbits = bitcast i64 1 to double
  %sub = fpext double %dbits to fp128
  %e0 = call i1 @reference_nan(fp128 %nan)
  %p0 = call i1 @protected_nan(fp128 %nan)
  %ok0 = icmp eq i1 %e0, %p0
  %e0b = call i1 @reference_nan(fp128 %one)
  %p0b = call i1 @protected_nan(fp128 %one)
  %ok0b = icmp eq i1 %e0b, %p0b
  %e1 = call i1 @reference_inf(fp128 %inf)
  %p1 = call i1 @protected_inf(fp128 %inf)
  %ok1 = icmp eq i1 %e1, %p1
  %e1b = call i1 @reference_inf(fp128 %ninf)
  %p1b = call i1 @protected_inf(fp128 %ninf)
  %ok1b = icmp eq i1 %e1b, %p1b
  %e2 = call i1 @reference_zero(fp128 %zero)
  %p2 = call i1 @protected_zero(fp128 %zero)
  %ok2 = icmp eq i1 %e2, %p2
  %e2b = call i1 @reference_zero(fp128 %nzero)
  %p2b = call i1 @protected_zero(fp128 %nzero)
  %ok2b = icmp eq i1 %e2b, %p2b
  %e3 = call i1 @reference_normal(fp128 %one)
  %p3 = call i1 @protected_normal(fp128 %one)
  %ok3 = icmp eq i1 %e3, %p3
  %e4 = call i1 @reference_sub(fp128 %sub)
  %p4 = call i1 @protected_sub(fp128 %sub)
  %ok4 = icmp eq i1 %e4, %p4
  %e4b = call i1 @reference_sub(fp128 %one)
  %p4b = call i1 @protected_sub(fp128 %one)
  %ok4b = icmp eq i1 %e4b, %p4b
  %e5 = call i1 @reference_phi(i1 true, fp128 %one, fp128 %zero)
  %p5 = call i1 @protected_phi(i1 true, fp128 %one, fp128 %zero)
  %ok5 = icmp eq i1 %e5, %p5
  %e6 = call i1 @reference_phi(i1 false, fp128 %one, fp128 %zero)
  %p6 = call i1 @protected_phi(i1 false, fp128 %one, fp128 %zero)
  %ok6 = icmp eq i1 %e6, %p6
  %e7 = call i32 @reference_loop(fp128 %one, i32 3)
  %p7 = call i32 @protected_loop(fp128 %one, i32 3)
  %ok7 = icmp eq i32 %e7, %p7
  %ok8 = icmp eq i1 true, true
  %t0 = and i1 %ok0, %ok0b
  %t1 = and i1 %t0, %ok1
  %t2 = and i1 %t1, %ok1b
  %t3 = and i1 %t2, %ok2
  %t4 = and i1 %t3, %ok2b
  %t5 = and i1 %t4, %ok3
  %t6 = and i1 %t5, %ok4
  %t7 = and i1 %t6, %ok4b
  %t8 = and i1 %t7, %ok5
  %t9 = and i1 %t8, %ok6
  %t10 = and i1 %t9, %ok7
  %ok = and i1 %t10, %ok8
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_constrained: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_vector: unsupported
; SKIP-DAG: Skipping VMP on unsupported_ppc: unsupported
; SKIP-DAG: Skipping VMP on unsupported_mask_oor: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_poison: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_undef: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_asm: inline assembly
; SKIP-DAG: Skipping VMP on unsupported_indirect: indirect call
; SKIP-DAG: Skipping VMP on unsupported_sret: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_nan:
; SKIP-NOT: Skipping VMP on protected_inf:
; SKIP-NOT: Skipping VMP on protected_zero:
; SKIP-NOT: Skipping VMP on protected_normal:
; SKIP-NOT: Skipping VMP on protected_sub:
; SKIP-NOT: Skipping VMP on protected_phi:
; SKIP-NOT: Skipping VMP on protected_loop:

; VIRT: define i1 @protected_nan({{.*}} #[[PROT:[0-9]+]] {
; VIRT: %vmp.fp128.regs = alloca [{{[0-9]+}} x fp128]
; VIRT: vmp.dispatch:
; VIRT-NOT: call void @hikari_vmp()
; VIRT-NOT: bitcast fp128 {{.*}} to i128
; VIRT: call i1 @llvm.is.fpclass.f128(fp128{{.*}}, i32 3)
; VIRT: define i1 @protected_inf({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i1 @llvm.is.fpclass.f128(fp128{{.*}}, i32 516)
; VIRT: define i1 @protected_zero({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i1 @llvm.is.fpclass.f128(fp128{{.*}}, i32 96)
; VIRT: define i1 @protected_normal({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i1 @llvm.is.fpclass.f128(fp128{{.*}}, i32 264)
; VIRT: define i1 @protected_sub({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i1 @llvm.is.fpclass.f128(fp128{{.*}}, i32 144)
; VIRT: define i1 @protected_phi({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: call i1 @llvm.is.fpclass.f128(fp128{{.*}}, i32 264)
; VIRT-DAG: call i1 @llvm.is.fpclass.f128(fp128{{.*}}, i32 96)
; VIRT: define i32 @protected_loop({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i1 @llvm.is.fpclass.f128(fp128{{.*}}, i32 264)
; VIRT: define {{.*}} @unsupported_constrained({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_vector({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ppc({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_mask_oor({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_poison({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_undef({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_musttail({{.*}} #[[UNSUPMUST:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_bundle({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_asm({{.*}} #[[UNSUPASM:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_indirect({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_sret({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; Direct musttail / inline asm are early deselects; +no selected/virtualized.
; VIRT-NOT: attributes #[[UNSUPMUST]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPMUST]] = { {{.*}}"hikari.vmp.selected"
; VIRT-NOT: attributes #[[UNSUPASM]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPASM]] = { {{.*}}"hikari.vmp.selected"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
