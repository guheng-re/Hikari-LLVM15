; Restricted scalar last-token +fullfp16
; llvm.experimental.constrained.sin/cos/exp/exp2/log/log2/log10: one
; IEEE half operand plus round and fpexcept MDString.  Reuses the
; f32/f64 transcendental shape checker and the shared last-token
; +fullfp16 feature-gate.  Replayed via CallDescriptor
; MetadataArguments.  Does not change f32/f64 transcendental, half
; arith/fmuladd/rounding/int-round/convert/minmax, or add a VM
; opcode.  Missing or last-token -fullfp16 is "unsupported target
; feature".  Host lli cannot be assumed to select half constrained
; ops: FileCheck + AArch64 llc/readobj only.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.ll > %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.ll > %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.s7.ll > %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.s7.ll > %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare half @llvm.experimental.constrained.sin.f16(half, metadata, metadata)
declare half @llvm.experimental.constrained.cos.f16(half, metadata, metadata)
declare half @llvm.experimental.constrained.exp.f16(half, metadata, metadata)
declare half @llvm.experimental.constrained.exp2.f16(half, metadata, metadata)
declare half @llvm.experimental.constrained.log.f16(half, metadata, metadata)
declare half @llvm.experimental.constrained.log2.f16(half, metadata, metadata)
declare half @llvm.experimental.constrained.log10.f16(half, metadata, metadata)
declare half @llvm.experimental.constrained.fadd.f16(half, half, metadata, metadata)

declare <2 x half> @llvm.experimental.constrained.pow.v2f16(<2 x half>, <2 x half>, metadata, metadata)

define half @protected_csin_nearest_f16(half %a) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.experimental.constrained.sin.f16(half %a, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret half %r
}

define half @protected_ccos_dyn_f16(half %a) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.experimental.constrained.cos.f16(half %a, metadata !"round.dynamic", metadata !"fpexcept.maytrap")
  ret half %r
}

define half @protected_cexp_down_f16(half %a) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.experimental.constrained.exp.f16(half %a, metadata !"round.downward", metadata !"fpexcept.strict")
  ret half %r
}

define half @protected_cexp2_up_f16(half %a) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.experimental.constrained.exp2.f16(half %a, metadata !"round.upward", metadata !"fpexcept.ignore")
  ret half %r
}

define half @protected_clog_zero_f16(half %a) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.experimental.constrained.log.f16(half %a, metadata !"round.towardzero", metadata !"fpexcept.ignore")
  ret half %r
}

define half @protected_clog2_f16(half %a) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.experimental.constrained.log2.f16(half %a, metadata !"round.tonearest", metadata !"fpexcept.maytrap")
  ret half %r
}

define half @protected_clog10_f16(half %a) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.experimental.constrained.log10.f16(half %a, metadata !"round.tonearest", metadata !"fpexcept.strict")
  ret half %r
}


define half @protected_csin_phi_f16(half %a, half %b, i1 %p) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  br i1 %p, label %left, label %right
left:
  %l = call half @llvm.experimental.constrained.sin.f16(half %a, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  br label %join
right:
  %r = call half @llvm.experimental.constrained.cos.f16(half %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  br label %join
join:
  %q = phi half [ %l, %left ], [ %r, %right ]
  ret half %q
}

define half @protected_csin_loop_f16(half %a, i32 %n) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  br label %hdr
hdr:
  %acc = phi half [ %a, %entry ], [ %nxt, %hdr ]
  %i = phi i32 [ 0, %entry ], [ %i.nxt, %hdr ]
  %cur = call half @llvm.experimental.constrained.sin.f16(half %acc, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  %nxt = call half @llvm.experimental.constrained.fadd.f16(half %acc, half 0xH3C00, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  %i.nxt = add i32 %i, 1
  %more = icmp ult i32 %i.nxt, %n
  br i1 %more, label %hdr, label %done
done:
  ret half %cur
}

define half @unsupported_csin_no_fullfp16(half %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.experimental.constrained.sin.f16(half %a, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret half %r
}

define half @unsupported_csin_fullfp16_disabled(half %a) noinline optnone strictfp "target-features"="+neon,+fullfp16,-fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.experimental.constrained.sin.f16(half %a, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret half %r
}

define <2 x half> @unsupported_csin_vector(<2 x half> %a) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <2 x half> @llvm.experimental.constrained.pow.v2f16(<2 x half> %a, <2 x half> %a, metadata !"round.tonearest", metadata !"fpexcept.ignore") [ "deopt"(i32 0) ]
  ret <2 x half> %r
}

define half @unsupported_csin_fastcc(half %a) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call fastcc half @llvm.experimental.constrained.sin.f16(half %a, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret half %r
}

define half @unsupported_csin_musttail(half %a) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = musttail call half @llvm.experimental.constrained.sin.f16(half %a, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret half %r
}

define half @unsupported_csin_bundle(half %a) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.experimental.constrained.sin.f16(half %a, metadata !"round.tonearest", metadata !"fpexcept.ignore") [ "deopt"(i32 0) ]
  ret half %r
}

define half @unsupported_csin_poison() noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.experimental.constrained.sin.f16(half poison, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret half %r
}

define half @unsupported_csin_undef() noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.experimental.constrained.sin.f16(half undef, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret half %r
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_csin_no_fullfp16: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_csin_fullfp16_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_csin_vector: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_csin_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_csin_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_csin_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_csin_poison: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_csin_undef: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_csin_nearest_f16:
; SKIP-NOT: Skipping VMP on protected_ccos_dyn_f16:
; SKIP-NOT: Skipping VMP on protected_cexp_down_f16:
; SKIP-NOT: Skipping VMP on protected_cexp2_up_f16:
; SKIP-NOT: Skipping VMP on protected_clog_zero_f16:
; SKIP-NOT: Skipping VMP on protected_clog2_f16:
; SKIP-NOT: Skipping VMP on protected_clog10_f16:
; SKIP-NOT: Skipping VMP on protected_csin_phi_f16:
; SKIP-NOT: Skipping VMP on protected_csin_loop_f16:

; VIRT: define half @protected_csin_nearest_f16({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call half @llvm.experimental.constrained.sin.f16({{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")
; VIRT: define half @protected_ccos_dyn_f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call half @llvm.experimental.constrained.cos.f16({{.*}}, metadata !"round.dynamic", metadata !"fpexcept.maytrap")
; VIRT: define half @protected_cexp_down_f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call half @llvm.experimental.constrained.exp.f16({{.*}}, metadata !"round.downward", metadata !"fpexcept.strict")
; VIRT: define half @protected_cexp2_up_f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call half @llvm.experimental.constrained.exp2.f16({{.*}}, metadata !"round.upward", metadata !"fpexcept.ignore")
; VIRT: define half @protected_clog_zero_f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call half @llvm.experimental.constrained.log.f16({{.*}}, metadata !"round.towardzero", metadata !"fpexcept.ignore")
; VIRT: define half @protected_clog2_f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call half @llvm.experimental.constrained.log2.f16({{.*}}, metadata !"round.tonearest", metadata !"fpexcept.maytrap")
; VIRT: define half @protected_clog10_f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call half @llvm.experimental.constrained.log10.f16({{.*}}, metadata !"round.tonearest", metadata !"fpexcept.strict")
; VIRT: define half @protected_csin_phi_f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call half @llvm.experimental.constrained.sin.f16({{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")
; VIRT: define half @protected_csin_loop_f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call half @llvm.experimental.constrained.sin.f16({{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")
; VIRT: define {{.*}} @unsupported_csin_no_fullfp16({{.*}} #[[UNSUPFEAT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_csin_fullfp16_disabled({{.*}} #[[UNSUPFEAT2:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_csin_vector({{.*}} #[[UNSUPCC:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_csin_fastcc({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_csin_musttail({{.*}} #[[UNSUP_MT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call half @llvm.experimental.constrained.sin.f16(
; VIRT: define {{.*}} @unsupported_csin_bundle({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call half @llvm.experimental.constrained.sin.f16({{.*}}[ "deopt"(i32 0) ]
; VIRT: define {{.*}} @unsupported_csin_poison({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_csin_undef({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPCC]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPCC]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_MT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPFEAT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPFEAT2]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
