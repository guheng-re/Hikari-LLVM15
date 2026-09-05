; Focused generic direct CallDescriptor ordinary-tail accept:
; already-supported CallInst tail is an optimization hint and is
; virtualized, then replayed as a normal non-tail CreateCall
; (TCK_None).  musttail stays the early "musttail call" diagnostic.
; Feature/shape gates stay first: well-shaped bfloat without +bf16
; remains "unsupported target feature" even when tailed.  Dedicated
; terminating llvm.trap still continues on its own path.  InvokeInst,
; callbr, inline asm, operand bundles, and still-closed ABI stay out.
; Shape helpers (including sret/byval/byref/noreturn and restricted
; indirect) must not reject ordinary tail; replay is TCK_None.
;
; Host lli is reliable for i32 add_one / <2 x i32> id / variadic
; sum and constrained fadd FileCheck-only on some hosts.  bfloat
; and fp128 are FileCheck-only.  O0/O2 x 97/7.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.ll > %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: python3 %S/Inputs/vmp-drop-host-direct-call-tail.py %t.o0.live.ll > %t.o0.host.src.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.host.src.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.ll > %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: python3 %S/Inputs/vmp-drop-host-direct-call-tail.py %t.o2.live.ll > %t.o2.host.src.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.host.src.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.s7.ll > %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: python3 %S/Inputs/vmp-drop-host-direct-call-tail.py %t.o0.s7.live.ll > %t.o0.s7.host.src.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.s7.host.src.ll > %t.o0.s7.host.ll
; RUN: lli -force-interpreter %t.o0.s7.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.s7.ll > %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: python3 %S/Inputs/vmp-drop-host-direct-call-tail.py %t.o2.s7.live.ll > %t.o2.s7.host.src.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.s7.host.src.ll > %t.o2.s7.host.ll
; RUN: lli -force-interpreter %t.o2.s7.host.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %s | opt -S -verify-each -aesSeed=97 -passes='default<O0>' - 2>&1 | FileCheck %s --check-prefix=HOST

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare void @llvm.trap()
declare float @llvm.experimental.constrained.fadd.f32(float, float, metadata, metadata)
declare i32 @printf(ptr, ...)

@fmt = private unnamed_addr constant [3 x i8] c"%d\00", align 1

define i32 @add_one(i32 %x) noinline {
entry:
  %r = add i32 %x, 1
  ret i32 %r
}

define <2 x i32> @id_v2i32(<2 x i32> %v) noinline {
entry:
  ret <2 x i32> %v
}

define bfloat @bf_id(bfloat %x) noinline {
entry:
  ret bfloat %x
}

define fp128 @fp128_id(fp128 %x) noinline {
entry:
  ret fp128 %x
}

define i32 @reference_i32(i32 %x) noinline {
entry:
  %r = call i32 @add_one(i32 %x)
  ret i32 %r
}

define i32 @protected_i32(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @add_one(i32 %x)
  ret i32 %r
}

define <2 x i32> @protected_v2i32(<2 x i32> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i32> @id_v2i32(<2 x i32> %v)
  ret <2 x i32> %r
}

define i32 @protected_variadic(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %p = getelementptr inbounds [3 x i8], ptr @fmt, i64 0, i64 0
  %r = call i32 (ptr, ...) @printf(ptr %p, i32 %x)
  ret i32 %r
}

define float @protected_constrained(float %a, float %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.experimental.constrained.fadd.f32(float %a, float %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret float %r
}

define bfloat @protected_bfloat(bfloat %x) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @bf_id(bfloat %x)
  ret bfloat %r
}

define fp128 @protected_fp128(fp128 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fp128 @fp128_id(fp128 %x)
  ret fp128 %r
}

define void @protected_trap(i1 %c) noinline optnone {
entry:
  call void @hikari_vmp()
  br i1 %c, label %die, label %ok
die:
  call void @llvm.trap()
  unreachable
ok:
  ret void
}

define i32 @protected_i32_tail(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = tail call i32 @add_one(i32 %x)
  ret i32 %r
}

define <2 x i32> @protected_v2i32_tail(<2 x i32> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = tail call <2 x i32> @id_v2i32(<2 x i32> %v)
  ret <2 x i32> %r
}

define i32 @protected_variadic_tail(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %p = getelementptr inbounds [3 x i8], ptr @fmt, i64 0, i64 0
  %r = tail call i32 (ptr, ...) @printf(ptr %p, i32 %x)
  ret i32 %r
}

define float @protected_constrained_tail(float %a, float %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = tail call float @llvm.experimental.constrained.fadd.f32(float %a, float %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret float %r
}

define bfloat @protected_bfloat_tail(bfloat %x) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = tail call bfloat @bf_id(bfloat %x)
  ret bfloat %r
}

define fp128 @protected_fp128_tail(fp128 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = tail call fp128 @fp128_id(fp128 %x)
  ret fp128 %r
}

define i32 @unsupported_bfloat_tail_no_feature(i16 %bits) noinline optnone {
entry:
  call void @hikari_vmp()
  %x = bitcast i16 %bits to bfloat
  %r = tail call bfloat @bf_id(bfloat %x)
  %t = bitcast bfloat %r to i16
  %z = zext i16 %t to i32
  ret i32 %z
}

define i32 @unsupported_i32_musttail(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call i32 @add_one(i32 %x)
  ret i32 %r
}

define i32 @main() {
entry:
  %e0 = call i32 @reference_i32(i32 3)
  %a0 = call i32 @protected_i32(i32 3)
  %e1 = call i32 @reference_i32(i32 9)
  %a1 = call i32 @protected_i32_tail(i32 9)
  %v = add <2 x i32> <i32 1, i32 2>, zeroinitializer
  %pv = call <2 x i32> @protected_v2i32_tail(<2 x i32> %v)
  %e2 = extractelement <2 x i32> %pv, i32 0
  %e3 = extractelement <2 x i32> %pv, i32 1
  %okv = icmp eq i32 %e2, 1
  %okv2 = icmp eq i32 %e3, 2
  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %e1, %a1
  %t0 = and i1 %m0, %m1
  %t1 = and i1 %okv, %okv2
  %ok = and i1 %t0, %t1
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_bfloat_tail_no_feature: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_i32_musttail: musttail call
; SKIP-NOT: Skipping VMP on protected_i32:
; SKIP-NOT: Skipping VMP on protected_i32_tail:
; SKIP-NOT: Skipping VMP on protected_v2i32:
; SKIP-NOT: Skipping VMP on protected_v2i32_tail:
; SKIP-NOT: Skipping VMP on protected_variadic:
; SKIP-NOT: Skipping VMP on protected_variadic_tail:
; SKIP-NOT: Skipping VMP on protected_constrained:
; SKIP-NOT: Skipping VMP on protected_constrained_tail:
; SKIP-NOT: Skipping VMP on protected_bfloat:
; SKIP-NOT: Skipping VMP on protected_bfloat_tail:
; SKIP-NOT: Skipping VMP on protected_fp128:
; SKIP-NOT: Skipping VMP on protected_fp128_tail:
; SKIP-NOT: Skipping VMP on protected_trap:

; VIRT-LABEL: define i32 @protected_i32(
; VIRT-SAME: #[[PROT:[0-9]+]]
; VIRT: vmp.dispatch:
; VIRT: call i32 @add_one(i32
; VIRT-LABEL: define <2 x i32> @protected_v2i32(
; VIRT: vmp.dispatch:
; VIRT: call <2 x i32> @id_v2i32(
; VIRT-LABEL: define i32 @protected_variadic(
; VIRT: vmp.dispatch:
; VIRT: call i32 (ptr, ...) @printf(
; VIRT-LABEL: define float @protected_constrained(
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.experimental.constrained.fadd.f32(
; VIRT-LABEL: define bfloat @protected_bfloat(
; VIRT-SAME: #[[PROTBF:[0-9]+]]
; VIRT: vmp.dispatch:
; VIRT: call bfloat @bf_id(
; VIRT-LABEL: define fp128 @protected_fp128(
; VIRT: vmp.dispatch:
; VIRT: call fp128 @fp128_id(
; VIRT-LABEL: define void @protected_trap(
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.trap()
; VIRT-LABEL: define i32 @protected_i32_tail(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT-NOT: tail call i32 @add_one(
; VIRT: call i32 @add_one(i32
; VIRT-LABEL: define <2 x i32> @protected_v2i32_tail(
; VIRT: vmp.dispatch:
; VIRT-NOT: tail call <2 x i32> @id_v2i32(
; VIRT: call <2 x i32> @id_v2i32(
; VIRT-LABEL: define i32 @protected_variadic_tail(
; VIRT: vmp.dispatch:
; VIRT-NOT: tail call i32 (ptr, ...) @printf(
; VIRT: call i32 (ptr, ...) @printf(
; VIRT-LABEL: define float @protected_constrained_tail(
; VIRT: vmp.dispatch:
; VIRT-NOT: tail call float @llvm.experimental.constrained.fadd.f32(
; VIRT: call float @llvm.experimental.constrained.fadd.f32(
; VIRT-LABEL: define bfloat @protected_bfloat_tail(
; VIRT: vmp.dispatch:
; VIRT-NOT: tail call bfloat @bf_id(
; VIRT: call bfloat @bf_id(
; VIRT-LABEL: define fp128 @protected_fp128_tail(
; VIRT: vmp.dispatch:
; VIRT-NOT: tail call fp128 @fp128_id(
; VIRT: call fp128 @fp128_id(
; VIRT-LABEL: define {{.*}} @unsupported_bfloat_tail_no_feature(
; VIRT-SAME: #[[UNSUP:[0-9]+]]
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_i32_musttail(
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call i32 @add_one(
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[PROTBF]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; HOST: Skipping VMP: only AArch64 targets are supported
