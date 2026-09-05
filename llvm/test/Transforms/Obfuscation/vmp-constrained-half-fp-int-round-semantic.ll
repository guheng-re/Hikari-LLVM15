; Restricted scalar last-token +fullfp16
; llvm.experimental.constrained.lrint/lround (i32 or i64 dest) and
; llrint/llround (i64 dest only) from IEEE half.  Dest widths follow
; AArch64 ISel, not the non-constrained half i64-only whitelist.
; Reuses the f32/f64 int-round shape checker and the shared
; last-token +fullfp16 feature-gate.  Replayed via CallDescriptor
; MetadataArguments.  Does not change f32/f64 int-round, unconstrained
; half i64 lround, half convert, or add a VM opcode.  Missing or
; last-token -fullfp16 is "unsupported target feature".  LLVM 15
; verifier rejects vector overloads of these four IDs, so the vector
; skip uses well-formed constrained.pow.v2f16.  Host lli cannot be
; assumed to select half constrained ops: FileCheck + AArch64
; llc/readobj only.
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
declare i64 @llvm.experimental.constrained.lrint.i64.f16(half, metadata, metadata)
declare i64 @llvm.experimental.constrained.llrint.i64.f16(half, metadata, metadata)
declare i64 @llvm.experimental.constrained.lround.i64.f16(half, metadata)
declare i64 @llvm.experimental.constrained.llround.i64.f16(half, metadata)
declare i32 @llvm.experimental.constrained.lrint.i32.f16(half, metadata, metadata)
declare i32 @llvm.experimental.constrained.lround.i32.f16(half, metadata)
declare i32 @llvm.experimental.constrained.llrint.i32.f16(half, metadata, metadata)
declare i32 @llvm.experimental.constrained.llround.i32.f16(half, metadata)
declare i16 @llvm.experimental.constrained.lround.i16.f16(half, metadata)
declare i128 @llvm.experimental.constrained.lround.i128.f16(half, metadata)
declare half @llvm.experimental.constrained.fadd.f16(half, half, metadata, metadata)
declare <2 x half> @llvm.experimental.constrained.pow.v2f16(<2 x half>, <2 x half>, metadata, metadata)

define i64 @protected_clrint_nearest_f16(half %a) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.experimental.constrained.lrint.i64.f16(half %a, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret i64 %r
}

define i64 @protected_cllrint_dyn_f16(half %a) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.experimental.constrained.llrint.i64.f16(half %a, metadata !"round.dynamic", metadata !"fpexcept.maytrap")
  ret i64 %r
}

define i64 @protected_clrint_down_f16(half %a) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.experimental.constrained.lrint.i64.f16(half %a, metadata !"round.downward", metadata !"fpexcept.strict")
  ret i64 %r
}

define i64 @protected_cllrint_up_f16(half %a) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.experimental.constrained.llrint.i64.f16(half %a, metadata !"round.upward", metadata !"fpexcept.ignore")
  ret i64 %r
}

define i64 @protected_clrint_zero_f16(half %a) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.experimental.constrained.lrint.i64.f16(half %a, metadata !"round.towardzero", metadata !"fpexcept.ignore")
  ret i64 %r
}

define i64 @protected_clround_f16(half %a) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.experimental.constrained.lround.i64.f16(half %a, metadata !"fpexcept.ignore")
  ret i64 %r
}

define i64 @protected_cllround_maytrap_f16(half %a) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.experimental.constrained.llround.i64.f16(half %a, metadata !"fpexcept.maytrap")
  ret i64 %r
}

define i64 @protected_clround_strict_f16(half %a) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.experimental.constrained.lround.i64.f16(half %a, metadata !"fpexcept.strict")
  ret i64 %r
}

define i32 @protected_clrint_i32_f16(half %a) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.experimental.constrained.lrint.i32.f16(half %a, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret i32 %r
}

define i32 @protected_clround_i32_f16(half %a) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.experimental.constrained.lround.i32.f16(half %a, metadata !"fpexcept.maytrap")
  ret i32 %r
}


define i64 @protected_clround_phi_f16(half %a, half %b, i1 %p) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  br i1 %p, label %left, label %right
left:
  %l = call i64 @llvm.experimental.constrained.lround.i64.f16(half %a, metadata !"fpexcept.ignore")
  br label %join
right:
  %r = call i64 @llvm.experimental.constrained.llround.i64.f16(half %b, metadata !"fpexcept.ignore")
  br label %join
join:
  %q = phi i64 [ %l, %left ], [ %r, %right ]
  ret i64 %q
}

define i64 @protected_clrint_loop_f16(half %a, i32 %n) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  br label %hdr
hdr:
  %acc = phi half [ %a, %entry ], [ %nxt, %hdr ]
  %i = phi i32 [ 0, %entry ], [ %i.nxt, %hdr ]
  %cur = call i64 @llvm.experimental.constrained.lrint.i64.f16(half %acc, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  %nxt = call half @llvm.experimental.constrained.fadd.f16(half %acc, half 0xH3C00, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  %i.nxt = add i32 %i, 1
  %more = icmp ult i32 %i.nxt, %n
  br i1 %more, label %hdr, label %done
done:
  ret i64 %cur
}

define i64 @unsupported_clround_no_fullfp16(half %a) noinline optnone strictfp {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.experimental.constrained.lround.i64.f16(half %a, metadata !"fpexcept.ignore")
  ret i64 %r
}

define i64 @unsupported_clround_fullfp16_disabled(half %a) noinline optnone strictfp "target-features"="+neon,+fullfp16,-fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.experimental.constrained.lround.i64.f16(half %a, metadata !"fpexcept.ignore")
  ret i64 %r
}

define i32 @unsupported_cllround_i32_f16(half %a) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.experimental.constrained.llround.i32.f16(half %a, metadata !"fpexcept.ignore")
  ret i32 %r
}

define i32 @unsupported_cllrint_i32_f16(half %a) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.experimental.constrained.llrint.i32.f16(half %a, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret i32 %r
}

define i16 @unsupported_clround_i16_f16(half %a) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i16 @llvm.experimental.constrained.lround.i16.f16(half %a, metadata !"fpexcept.ignore")
  ret i16 %r
}

define i128 @unsupported_clround_i128_f16(half %a) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i128 @llvm.experimental.constrained.lround.i128.f16(half %a, metadata !"fpexcept.ignore")
  ret i128 %r
}

define <2 x half> @unsupported_cceil_vector(<2 x half> %a) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call <2 x half> @llvm.experimental.constrained.pow.v2f16(<2 x half> %a, <2 x half> %a, metadata !"round.tonearest", metadata !"fpexcept.ignore") [ "deopt"(i32 0) ]
  ret <2 x half> %r
}

define i64 @unsupported_clround_fastcc(half %a) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call fastcc i64 @llvm.experimental.constrained.lround.i64.f16(half %a, metadata !"fpexcept.ignore")
  ret i64 %r
}

define i64 @unsupported_clround_musttail(half %a) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = musttail call i64 @llvm.experimental.constrained.lround.i64.f16(half %a, metadata !"fpexcept.ignore")
  ret i64 %r
}

define i64 @unsupported_clround_bundle(half %a) noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.experimental.constrained.lround.i64.f16(half %a, metadata !"fpexcept.ignore") [ "deopt"(i32 0) ]
  ret i64 %r
}

define i64 @unsupported_clround_poison() noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.experimental.constrained.lround.i64.f16(half poison, metadata !"fpexcept.ignore")
  ret i64 %r
}

define i64 @unsupported_clround_undef() noinline optnone strictfp "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.experimental.constrained.lround.i64.f16(half undef, metadata !"fpexcept.ignore")
  ret i64 %r
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_clround_no_fullfp16: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_clround_fullfp16_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_cllround_i32_f16: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_cllrint_i32_f16: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_clround_i16_f16: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_clround_i128_f16: unsupported call instruction

; SKIP-DAG: Skipping VMP on unsupported_cceil_vector: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_clround_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_clround_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_clround_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_clround_poison: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_clround_undef: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_clrint_nearest_f16:
; SKIP-NOT: Skipping VMP on protected_cllrint_dyn_f16:
; SKIP-NOT: Skipping VMP on protected_clrint_down_f16:
; SKIP-NOT: Skipping VMP on protected_cllrint_up_f16:
; SKIP-NOT: Skipping VMP on protected_clrint_zero_f16:
; SKIP-NOT: Skipping VMP on protected_clround_f16:
; SKIP-NOT: Skipping VMP on protected_cllround_maytrap_f16:
; SKIP-NOT: Skipping VMP on protected_clround_strict_f16:
; SKIP-NOT: Skipping VMP on protected_clrint_i32_f16:
; SKIP-NOT: Skipping VMP on protected_clround_i32_f16:
; SKIP-NOT: Skipping VMP on protected_clround_phi_f16:
; SKIP-NOT: Skipping VMP on protected_clrint_loop_f16:

; VIRT: define i64 @protected_clrint_nearest_f16({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.experimental.constrained.lrint.i64.f16({{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")
; VIRT: define i64 @protected_cllrint_dyn_f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.experimental.constrained.llrint.i64.f16({{.*}}, metadata !"round.dynamic", metadata !"fpexcept.maytrap")
; VIRT: define i64 @protected_clrint_down_f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.experimental.constrained.lrint.i64.f16({{.*}}, metadata !"round.downward", metadata !"fpexcept.strict")
; VIRT: define i64 @protected_cllrint_up_f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.experimental.constrained.llrint.i64.f16({{.*}}, metadata !"round.upward", metadata !"fpexcept.ignore")
; VIRT: define i64 @protected_clrint_zero_f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.experimental.constrained.lrint.i64.f16({{.*}}, metadata !"round.towardzero", metadata !"fpexcept.ignore")
; VIRT: define i64 @protected_clround_f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.experimental.constrained.lround.i64.f16({{.*}}, metadata !"fpexcept.ignore")
; VIRT: define i64 @protected_cllround_maytrap_f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.experimental.constrained.llround.i64.f16({{.*}}, metadata !"fpexcept.maytrap")
; VIRT: define i64 @protected_clround_strict_f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.experimental.constrained.lround.i64.f16({{.*}}, metadata !"fpexcept.strict")
; VIRT: define i32 @protected_clrint_i32_f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.experimental.constrained.lrint.i32.f16({{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")
; VIRT: define i32 @protected_clround_i32_f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.experimental.constrained.lround.i32.f16({{.*}}, metadata !"fpexcept.maytrap")
; VIRT: define i64 @protected_clround_phi_f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.experimental.constrained.lround.i64.f16({{.*}}, metadata !"fpexcept.ignore")
; VIRT: define i64 @protected_clrint_loop_f16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.experimental.constrained.lrint.i64.f16({{.*}}, metadata !"round.tonearest", metadata !"fpexcept.ignore")
; VIRT: define {{.*}} @unsupported_clround_no_fullfp16({{.*}} #[[UNSUPFEAT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_clround_fullfp16_disabled({{.*}} #[[UNSUPFEAT2:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cllround_i32_f16({{.*}} #[[UNSUPCC:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cllrint_i32_f16({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_clround_i16_f16({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_clround_i128_f16({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cceil_vector({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_clround_fastcc({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_clround_musttail({{.*}} #[[UNSUP_MT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call i64 @llvm.experimental.constrained.lround.i64.f16(
; VIRT: define {{.*}} @unsupported_clround_bundle({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call i64 @llvm.experimental.constrained.lround.i64.f16({{.*}}[ "deopt"(i32 0) ]
; VIRT: define {{.*}} @unsupported_clround_poison({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_clround_undef({{.*}} #[[UNSUPCC]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPCC]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPCC]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_MT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPFEAT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPFEAT2]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
