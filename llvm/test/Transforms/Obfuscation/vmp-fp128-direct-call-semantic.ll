; Restricted ordinary direct non-intrinsic non-vararg CallInsts whose
; args/result are already-supported scalar integer, AS0 pointer, half,
; float, double, or scalar IEEE fp128.  Reuses CallDescriptor: fp128
; args load from the dedicated typed vmp.fp128.regs frame, results
; store back there (never i128 integer slots).  Ordinary tail on this
; already-supported ordinary tail is replayed as a non-tail call (vmp-direct-call-tail-eligibility-semantic.ll).  Calling convention, attributes,
; metadata, debug loc, and FastMathFlags on fp128 results are kept.
;
; Rejected: musttail, indirect, inline asm, operand bundles,
; invoke/callbr, constrained lround and constrained fp128 math,
; noreturn/returns_twice, complex ABI, varargs, vectors, aggregates,
; poison/undef.  Listed sqrt/fabs/fma/fmuladd.f128 live in
; vmp-fp128-math-semantic.ll.  Listed min/max and rounding live in
; vmp-fp128-minmax-round-semantic.ll.  Listed copysign/pow/powi/
; transcendentals live in vmp-fp128-copy-pow-transcendental-semantic.ll.
; Listed canonicalize.f128 lives in vmp-fp128-canonicalize-semantic.ll.
; Listed is.fpclass.f128 lives in vmp-fp128-fpclass-semantic.ll.
;
; Host lli interpreter can evaluate fp128.  FileCheck + lli + AArch64
; llc/readobj.  O0/O2 x aesSeed 97/7.
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
declare i64 @llvm.experimental.constrained.lround.i64.f128(fp128, metadata)
declare fp128 @llvm.experimental.constrained.fadd.f128(fp128, fp128, metadata, metadata)
declare fp128 @ext_fp128_vararg(fp128, ...)
declare void @ext_fp128_noreturn(fp128) noreturn
declare void @ext_fp128_sret(ptr sret(i32), fp128)

@slot.fp128 = global fp128 0xL00000000000000000000000000000000, align 16

define i32 @fold_fp128(fp128 %v) {
entry:
  %b = bitcast fp128 %v to i128
  %lo = trunc i128 %b to i64
  %hi.sh = lshr i128 %b, 64
  %hi = trunc i128 %hi.sh to i64
  %x = xor i64 %lo, %hi
  %r = trunc i64 %x to i32
  ret i32 %r
}

define fp128 @fp128_id(fp128 %x) noinline {
entry:
  ret fp128 %x
}

define fp128 @fp128_add(fp128 %a, fp128 %b) noinline {
entry:
  %s = fadd fp128 %a, %b
  ret fp128 %s
}

define fp128 @fp128_mixed(fp128 %x, i32 %k, ptr %p, double %d, half %h) noinline {
entry:
  %fromi = sitofp i32 %k to fp128
  %fromd = fpext double %d to fp128
  %fromh = fpext half %h to fp128
  %s0 = fadd fp128 %x, %fromi
  %s1 = fadd fp128 %s0, %fromd
  %s2 = fadd fp128 %s1, %fromh
  store volatile fp128 %s2, ptr %p, align 16
  %ld = load volatile fp128, ptr %p, align 16
  ret fp128 %ld
}

define void @fp128_sink(fp128 %x) noinline {
entry:
  store volatile fp128 %x, ptr @slot.fp128, align 16
  ret void
}

define i32 @fp128_to_i32(fp128 %x) noinline {
entry:
  %i = fptosi fp128 %x to i32
  ret i32 %i
}

define fastcc fp128 @fp128_fast(fp128 %x) noinline {
entry:
  %t = fadd fp128 %x, %x
  ret fp128 %t
}

define fp128 @cross_add(fp128 %x) noinline {
entry:
  %t = fadd fp128 %x, %x
  ret fp128 %t
}

; ----- positives -----

define fp128 @protected_call(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 @fp128_id(fp128 %a)
  ret fp128 %r
}

define fp128 @protected_add_call(fp128 %a, fp128 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 @fp128_add(fp128 %a, fp128 %b)
  ret fp128 %r
}

define fp128 @protected_mixed(fp128 %x, i32 %k, ptr %p, double %d, half %h) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 @fp128_mixed(fp128 %x, i32 %k, ptr %p, double %d, half %h)
  ret fp128 %r
}

define void @protected_sink(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @fp128_sink(fp128 %a)
  ret void
}

define i32 @protected_to_i32(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @fp128_to_i32(fp128 %a)
  ret i32 %r
}

define fp128 @protected_fmf(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call nnan nsz fp128 @fp128_id(fp128 %a)
  ret fp128 %r
}

define fp128 @protected_fastcc(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc fp128 @fp128_fast(fp128 %a)
  ret fp128 %r
}


define fp128 @protected_cross(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 @cross_add(fp128 %a)
  ret fp128 %r
}

define fp128 @protected_recursive(fp128 %a, i32 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  %z = icmp eq i32 %n, 0
  br i1 %z, label %done, label %rec

rec:
  %n1 = add i32 %n, -1
  %r = call fp128 @protected_recursive(fp128 %a, i32 %n1)
  ret fp128 %r

done:
  ret fp128 %a
}

define fp128 @protected_mut_a(fp128 %a, i32 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  %z = icmp eq i32 %n, 0
  br i1 %z, label %done, label %rec

rec:
  %n1 = add i32 %n, -1
  %r = call fp128 @protected_mut_b(fp128 %a, i32 %n1)
  ret fp128 %r

done:
  ret fp128 %a
}

define fp128 @protected_mut_b(fp128 %a, i32 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  %z = icmp eq i32 %n, 0
  br i1 %z, label %done, label %rec

rec:
  %n1 = add i32 %n, -1
  %r = call fp128 @protected_mut_a(fp128 %a, i32 %n1)
  ret fp128 %r

done:
  ret fp128 %a
}

; ----- negatives -----

define fp128 @unsupported_musttail(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call fp128 @fp128_id(fp128 %a)
  ret fp128 %r
}

define fp128 @unsupported_indirect(ptr %fp, fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 %fp(fp128 %a)
  ret fp128 %r
}

define fp128 @unsupported_vararg(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 (fp128, ...) @ext_fp128_vararg(fp128 %a)
  ret fp128 %r
}

define i64 @unsupported_lround(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.experimental.constrained.lround.i64.f128(fp128 %a, metadata !"fpexcept.ignore")
  ret i64 %r
}

define fp128 @unsupported_constrained(fp128 %a, fp128 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 @llvm.experimental.constrained.fadd.f128(fp128 %a, fp128 %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret fp128 %r
}

define fp128 @unsupported_bundle(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 @fp128_id(fp128 %a) [ "deopt"() ]
  ret fp128 %r
}

define void @unsupported_noreturn(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @ext_fp128_noreturn(fp128 %a)
  unreachable
}

define void @unsupported_sret(ptr sret(i32) %p, fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @ext_fp128_sret(ptr sret(i32) %p, fp128 %a)
  ret void
}

define fp128 @unsupported_poison(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 @fp128_id(fp128 poison)
  ret fp128 %r
}

define <1 x fp128> @unsupported_vector(<1 x fp128> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  ret <1 x fp128> %a
}

define i32 @main() {
entry:
  %a = fpext double 1.500000e+00 to fp128
  %b = fpext double 2.250000e+00 to fp128
  %e0 = call fp128 @fp128_id(fp128 %a)
  %p0 = call fp128 @protected_call(fp128 %a)
  %fe0 = call i32 @fold_fp128(fp128 %e0)
  %fp0 = call i32 @fold_fp128(fp128 %p0)
  %ok0 = icmp eq i32 %fe0, %fp0
  %e1 = call fp128 @fp128_add(fp128 %a, fp128 %b)
  %p1 = call fp128 @protected_add_call(fp128 %a, fp128 %b)
  %fe1 = call i32 @fold_fp128(fp128 %e1)
  %fp1 = call i32 @fold_fp128(fp128 %p1)
  %ok1 = icmp eq i32 %fe1, %fp1
  %e2 = call fp128 @fp128_mixed(fp128 %a, i32 3, ptr @slot.fp128, double 1.250000e+00, half 0xH4000)
  %p2 = call fp128 @protected_mixed(fp128 %a, i32 3, ptr @slot.fp128, double 1.250000e+00, half 0xH4000)
  %fe2 = call i32 @fold_fp128(fp128 %e2)
  %fp2 = call i32 @fold_fp128(fp128 %p2)
  %ok2 = icmp eq i32 %fe2, %fp2
  call void @fp128_sink(fp128 %a)
  %g0 = load volatile fp128, ptr @slot.fp128, align 16
  call void @protected_sink(fp128 %a)
  %g1 = load volatile fp128, ptr @slot.fp128, align 16
  %fg0 = call i32 @fold_fp128(fp128 %g0)
  %fg1 = call i32 @fold_fp128(fp128 %g1)
  %ok3 = icmp eq i32 %fg0, %fg1
  %e4 = call i32 @fp128_to_i32(fp128 %a)
  %p4 = call i32 @protected_to_i32(fp128 %a)
  %ok4 = icmp eq i32 %e4, %p4
  %e5 = call fp128 @fp128_id(fp128 %a)
  %p5 = call fp128 @protected_fmf(fp128 %a)
  %fe5 = call i32 @fold_fp128(fp128 %e5)
  %fp5 = call i32 @fold_fp128(fp128 %p5)
  %ok5 = icmp eq i32 %fe5, %fp5
  %e6 = call fastcc fp128 @fp128_fast(fp128 %a)
  %p6 = call fp128 @protected_fastcc(fp128 %a)
  %fe6 = call i32 @fold_fp128(fp128 %e6)
  %fp6 = call i32 @fold_fp128(fp128 %p6)
  %ok6 = icmp eq i32 %fe6, %fp6
  %ok7 = icmp eq i32 0, 0
  %e8 = call fp128 @cross_add(fp128 %a)
  %p8 = call fp128 @protected_cross(fp128 %a)
  %fe8 = call i32 @fold_fp128(fp128 %e8)
  %fp8 = call i32 @fold_fp128(fp128 %p8)
  %ok8 = icmp eq i32 %fe8, %fp8
  %e9 = call fp128 @protected_recursive(fp128 %a, i32 0)
  %fe9 = call i32 @fold_fp128(fp128 %e9)
  %fa = call i32 @fold_fp128(fp128 %a)
  %ok9 = icmp eq i32 %fe9, %fa
  %e10 = call fp128 @protected_mut_a(fp128 %a, i32 2)
  %fe10 = call i32 @fold_fp128(fp128 %e10)
  %ok10 = icmp eq i32 %fe10, %fa
  %t0 = and i1 %ok0, %ok1
  %t1 = and i1 %t0, %ok2
  %t2 = and i1 %t1, %ok3
  %t3 = and i1 %t2, %ok4
  %t4 = and i1 %t3, %ok5
  %t5 = and i1 %t4, %ok6
  %t6 = and i1 %t5, %ok7
  %t7 = and i1 %t6, %ok8
  %t8 = and i1 %t7, %ok9
  %ok = and i1 %t8, %ok10
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_indirect: indirect call
; SKIP-DAG: Skipping VMP on unsupported_vararg: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_lround: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_constrained: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_noreturn: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_sret: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_poison: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_vector: unsupported
; SKIP-NOT: Skipping VMP on protected_call:
; SKIP-NOT: Skipping VMP on protected_add_call:
; SKIP-NOT: Skipping VMP on protected_mixed:
; SKIP-NOT: Skipping VMP on protected_sink:
; SKIP-NOT: Skipping VMP on protected_to_i32:
; SKIP-NOT: Skipping VMP on protected_fmf:
; SKIP-NOT: Skipping VMP on protected_fastcc:
; SKIP-NOT: Skipping VMP on protected_cross:
; SKIP-NOT: Skipping VMP on protected_recursive:
; SKIP-NOT: Skipping VMP on protected_mut_a:
; SKIP-NOT: Skipping VMP on protected_mut_b:

; VIRT: define fp128 @protected_call({{.*}} #[[PROT:[0-9]+]] {
; VIRT: %vmp.fp128.regs = alloca [{{[0-9]+}} x fp128]
; VIRT: vmp.dispatch:
; VIRT-NOT: call void @hikari_vmp()
; VIRT-NOT: bitcast fp128 {{.*}} to i128
; VIRT: call{{.*}}fp128 @fp128_id(fp128
; VIRT: define fp128 @protected_add_call({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call{{.*}}fp128 @fp128_add(fp128
; VIRT: define fp128 @protected_mixed({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call{{.*}}fp128 @fp128_mixed(fp128{{.*}}i32{{.*}}ptr{{.*}}double{{.*}}half
; VIRT: define void @protected_sink({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call{{.*}}void @fp128_sink(fp128
; VIRT: define i32 @protected_to_i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call{{.*}}i32 @fp128_to_i32(fp128
; VIRT: define fp128 @protected_fmf({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call nnan nsz fp128 @fp128_id(fp128
; VIRT: define fp128 @protected_fastcc({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call fastcc fp128 @fp128_fast(fp128
; VIRT: define fp128 @protected_cross({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call{{.*}}fp128 @cross_add(fp128
; VIRT: define fp128 @protected_recursive({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call{{.*}}fp128 @protected_recursive(fp128
; VIRT: define fp128 @protected_mut_a({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call{{.*}}fp128 @protected_mut_b(fp128
; VIRT: define fp128 @protected_mut_b({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call{{.*}}fp128 @protected_mut_a(fp128
; VIRT: define {{.*}} @unsupported_musttail({{.*}} #[[UNSUPMUST:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_indirect({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_vararg({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_lround({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_constrained({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_bundle({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_noreturn({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_sret({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_poison({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_vector({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; Direct musttail is an early deselect; +no selected/virtualized.
; VIRT-NOT: attributes #[[UNSUPMUST]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPMUST]] = { {{.*}}"hikari.vmp.selected"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
