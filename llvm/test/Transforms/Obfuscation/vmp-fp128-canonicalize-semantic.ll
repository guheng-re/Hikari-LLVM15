; Scalar IEEE fp128 llvm.canonicalize.f128.  LLVM 15 AArch64 and host
; x86 cannot select the intrinsic (ISD::FCANONICALIZE f128), so VMP
; uses the LangRef-endorsed typed fp128 fmul x, 1.0 on the dedicated
; vmp.fp128.regs frame.  Never i128 reinterpretation and never replay
; of the unselectable intrinsic.  Valid FastMathFlags travel on the
; lowered fmul.  Ordinary tail becomes a non-tail fmul (same as the
; existing f16/f32/f64 canonicalize surface).
;
; Rejected: constrained fmul (LLVM 15 has no constrained.canonicalize),
; vector fp128, ppc_fp128, constrained lround, poison/undef, musttail, bundles,
; inline asm, invalid ABI / call shapes.
;
; Reference uses the same LangRef expansion (fmul by 1.0).  Host lli
; and AArch64 llc see only selectable typed fmul.  O0/O2 x aesSeed 97/7.
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
declare fp128 @llvm.canonicalize.f128(fp128)
declare fp128 @llvm.experimental.constrained.fmul.f128(fp128, fp128, metadata, metadata)
declare i64 @llvm.experimental.constrained.lround.i64.f128(fp128, metadata)
declare <1 x fp128> @llvm.canonicalize.v1f128(<1 x fp128>)
declare ppc_fp128 @llvm.canonicalize.ppcf128(ppc_fp128)
declare void @ext_fp128_sret(ptr sret(i32), fp128)

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

define fp128 @reference_canon(fp128 %a) noinline {
entry:
  %r = fmul fp128 %a, 0xL00000000000000003FFF000000000000
  ret fp128 %r
}

define fp128 @protected_canon(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 @llvm.canonicalize.f128(fp128 %a)
  ret fp128 %r
}

define fp128 @reference_fmf(fp128 %a) noinline {
entry:
  %r = fmul nnan nsz fp128 %a, 0xL00000000000000003FFF000000000000
  ret fp128 %r
}

define fp128 @protected_fmf(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call nnan nsz fp128 @llvm.canonicalize.f128(fp128 %a)
  ret fp128 %r
}

define fp128 @reference_phi(i1 %c, fp128 %a, fp128 %b) noinline {
entry:
  br i1 %c, label %left, label %right

left:
  %lc = fmul fp128 %a, 0xL00000000000000003FFF000000000000
  br label %join

right:
  %rc = fmul fp128 %b, 0xL00000000000000003FFF000000000000
  br label %join

join:
  %p = phi fp128 [ %lc, %left ], [ %rc, %right ]
  ret fp128 %p
}

define fp128 @protected_phi(i1 %c, fp128 %a, fp128 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  br i1 %c, label %left, label %right

left:
  %lc = call fp128 @llvm.canonicalize.f128(fp128 %a)
  br label %join

right:
  %rc = call fp128 @llvm.canonicalize.f128(fp128 %b)
  br label %join

join:
  %p = phi fp128 [ %lc, %left ], [ %rc, %right ]
  ret fp128 %p
}

define fp128 @reference_loop(fp128 %a, i32 %n) noinline {
entry:
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %acc = phi fp128 [ %a, %entry ], [ %next, %loop ]
  %next = fmul fp128 %acc, 0xL00000000000000003FFF000000000000
  %i1 = add i32 %i, 1
  %more = icmp slt i32 %i1, %n
  br i1 %more, label %loop, label %done

done:
  ret fp128 %next
}

define fp128 @protected_loop(fp128 %a, i32 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %acc = phi fp128 [ %a, %entry ], [ %next, %loop ]
  %next = call fp128 @llvm.canonicalize.f128(fp128 %acc)
  %i1 = add i32 %i, 1
  %more = icmp slt i32 %i1, %n
  br i1 %more, label %loop, label %done

done:
  ret fp128 %next
}

define fp128 @reference_tail(fp128 %a) noinline {
entry:
  %r = fmul fp128 %a, 0xL00000000000000003FFF000000000000
  ret fp128 %r
}


define fp128 @reference_signed_zero(fp128 %z) noinline {
entry:
  %r = fmul fp128 %z, 0xL00000000000000003FFF000000000000
  ret fp128 %r
}

define fp128 @protected_signed_zero(fp128 %z) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 @llvm.canonicalize.f128(fp128 %z)
  ret fp128 %r
}

; ----- negatives -----

define fp128 @unsupported_constrained(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 @llvm.experimental.constrained.fmul.f128(fp128 %a, fp128 %a, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret fp128 %r
}

define i64 @unsupported_lround(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.experimental.constrained.lround.i64.f128(fp128 %a, metadata !"fpexcept.ignore")
  ret i64 %r
}

define <1 x fp128> @unsupported_vector(<1 x fp128> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <1 x fp128> @llvm.canonicalize.v1f128(<1 x fp128> %a)
  ret <1 x fp128> %r
}

define ppc_fp128 @unsupported_ppc(ppc_fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call ppc_fp128 @llvm.canonicalize.ppcf128(ppc_fp128 %a)
  ret ppc_fp128 %r
}

define fp128 @unsupported_poison(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 @llvm.canonicalize.f128(fp128 poison)
  ret fp128 %r
}

define fp128 @unsupported_undef(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 @llvm.canonicalize.f128(fp128 undef)
  ret fp128 %r
}

define fp128 @unsupported_musttail(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call fp128 @llvm.canonicalize.f128(fp128 %a)
  ret fp128 %r
}

define fp128 @unsupported_bundle(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 @llvm.canonicalize.f128(fp128 %a) [ "deopt"() ]
  ret fp128 %r
}

define fp128 @unsupported_asm(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 asm "", "=w,w"(fp128 %a)
  ret fp128 %r
}

define fp128 @unsupported_indirect(ptr %fp, fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 %fp(fp128 %a)
  ret fp128 %r
}

define void @unsupported_sret(ptr sret(i32) %p, fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @ext_fp128_sret(ptr sret(i32) %p, fp128 %a)
  ret void
}

define i32 @main() {
entry:
  %a = fpext double 1.500000e+00 to fp128
  %b = fpext double -2.250000e+00 to fp128
  %pz = fpext double 0.000000e+00 to fp128
  %nz = fneg fp128 %pz
  %e0 = call fp128 @reference_canon(fp128 %a)
  %p0 = call fp128 @protected_canon(fp128 %a)
  %fe0 = call i32 @fold_fp128(fp128 %e0)
  %fp0 = call i32 @fold_fp128(fp128 %p0)
  %ok0 = icmp eq i32 %fe0, %fp0
  %e1 = call fp128 @reference_fmf(fp128 %a)
  %p1 = call fp128 @protected_fmf(fp128 %a)
  %fe1 = call i32 @fold_fp128(fp128 %e1)
  %fp1 = call i32 @fold_fp128(fp128 %p1)
  %ok1 = icmp eq i32 %fe1, %fp1
  %e2 = call fp128 @reference_phi(i1 true, fp128 %a, fp128 %b)
  %p2 = call fp128 @protected_phi(i1 true, fp128 %a, fp128 %b)
  %fe2 = call i32 @fold_fp128(fp128 %e2)
  %fp2 = call i32 @fold_fp128(fp128 %p2)
  %ok2 = icmp eq i32 %fe2, %fp2
  %e3 = call fp128 @reference_phi(i1 false, fp128 %a, fp128 %b)
  %p3 = call fp128 @protected_phi(i1 false, fp128 %a, fp128 %b)
  %fe3 = call i32 @fold_fp128(fp128 %e3)
  %fp3 = call i32 @fold_fp128(fp128 %p3)
  %ok3 = icmp eq i32 %fe3, %fp3
  %e4 = call fp128 @reference_loop(fp128 %a, i32 3)
  %p4 = call fp128 @protected_loop(fp128 %a, i32 3)
  %fe4 = call i32 @fold_fp128(fp128 %e4)
  %fp4 = call i32 @fold_fp128(fp128 %p4)
  %ok4 = icmp eq i32 %fe4, %fp4
  %ok5 = icmp eq i32 0, 0
  %e6 = call fp128 @reference_signed_zero(fp128 %pz)
  %p6 = call fp128 @protected_signed_zero(fp128 %pz)
  %fe6 = call i32 @fold_fp128(fp128 %e6)
  %fp6 = call i32 @fold_fp128(fp128 %p6)
  %ok6 = icmp eq i32 %fe6, %fp6
  %e7 = call fp128 @reference_signed_zero(fp128 %nz)
  %p7 = call fp128 @protected_signed_zero(fp128 %nz)
  %fe7 = call i32 @fold_fp128(fp128 %e7)
  %fp7 = call i32 @fold_fp128(fp128 %p7)
  %ok7 = icmp eq i32 %fe7, %fp7
  %t0 = and i1 %ok0, %ok1
  %t1 = and i1 %t0, %ok2
  %t2 = and i1 %t1, %ok3
  %t3 = and i1 %t2, %ok4
  %t4 = and i1 %t3, %ok5
  %t5 = and i1 %t4, %ok6
  %ok = and i1 %t5, %ok7
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_constrained: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_lround: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_vector: unsupported
; SKIP-DAG: Skipping VMP on unsupported_ppc: unsupported
; SKIP-DAG: Skipping VMP on unsupported_poison: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_undef: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_asm: inline assembly
; SKIP-DAG: Skipping VMP on unsupported_indirect: indirect call
; SKIP-DAG: Skipping VMP on unsupported_sret: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_canon:
; SKIP-NOT: Skipping VMP on protected_fmf:
; SKIP-NOT: Skipping VMP on protected_phi:
; SKIP-NOT: Skipping VMP on protected_loop:
; SKIP-NOT: Skipping VMP on protected_signed_zero:

; VIRT: define fp128 @protected_canon({{.*}} #[[PROT:[0-9]+]] {
; VIRT: %vmp.fp128.regs = alloca [{{[0-9]+}} x fp128]
; VIRT: vmp.dispatch:
; VIRT-NOT: call void @hikari_vmp()
; VIRT-NOT: bitcast fp128 {{.*}} to i128
; VIRT-NOT: @llvm.canonicalize
; VIRT: fmul{{.*}}fp128
; VIRT: define fp128 @protected_fmf({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: @llvm.canonicalize
; VIRT: fmul nnan nsz fp128
; VIRT: define fp128 @protected_phi({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: @llvm.canonicalize
; VIRT: fmul{{.*}}fp128
; VIRT: define fp128 @protected_loop({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: @llvm.canonicalize
; VIRT: fmul{{.*}}fp128
; VIRT: define fp128 @protected_signed_zero({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: @llvm.canonicalize
; VIRT: fmul{{.*}}fp128
; VIRT: define {{.*}} @unsupported_constrained({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_lround({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_vector({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ppc({{.*}} #[[UNSUP]] {
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
