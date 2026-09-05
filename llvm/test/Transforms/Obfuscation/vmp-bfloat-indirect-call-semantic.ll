; Restricted last-token +bf16 indirect C calls whose fixed 0..8
; non-vararg prototype may carry scalar bfloat and supported 1..128
; bfloat-vector args/returns.  Callee is an AS0 pointer VReg
; (function-pointer argument, global table load, select, or phi).
; Replay reuses CallDescriptor plus the existing float VReg (scalar)
; and vector VReg (fixed bfloat vectors).  Bfloat values must not be
; lowered as integer bit patterns.  Exact token only.  Well-shaped
; calls missing or ending in -bf16 skip as unsupported target feature
; and keep hikari.vmp.selected.
;
; Ordinary tail is a hint and is replayed as TCK_None (interpreter
; must not keep tail call).  Non-tail function-pointer recursion
; stays accepted.  musttail stays the late "indirect call" skip.
;
; Rejected: musttail, operand bundles, inline asm, varargs,
; noreturn, returns_twice, complex ABI, scalable/overwide, aggregate
; results, non-C, poison/undef, FastMathFlags, missing/final -bf16.
;
; Callees use i16 bitcasts so AArch64 ISel can compile them.  Host
; x86 cannot be assumed to select bfloat.  This lit is FileCheck +
; AArch64 llc/readobj only (function +bf16, no global -mattr).
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

%Pair = type { i32, i32 }

declare void @hikari_vmp()

@slot.bf = global bfloat 0xR0000, align 2
@vt.bf = global [2 x ptr] [ptr @bf_id, ptr @bf_flip], align 8
@vt.v4 = global [2 x ptr] [ptr @v4_id, ptr @v4_flip], align 8
@cb.rec = global ptr @protected_fp_rec, align 8

define bfloat @bf_id(bfloat %x) noinline {
entry:
  ret bfloat %x
}

define bfloat @bf_flip(bfloat %x) noinline {
entry:
  %b = bitcast bfloat %x to i16
  %n = xor i16 %b, -32768
  %r = bitcast i16 %n to bfloat
  ret bfloat %r
}

define bfloat @bf_mix(bfloat %x, i32 %k) noinline {
entry:
  %b = bitcast bfloat %x to i16
  %t = trunc i32 %k to i16
  %s = add i16 %b, %t
  %r = bitcast i16 %s to bfloat
  ret bfloat %r
}

define i32 @bf_to_i32(bfloat %x) noinline {
entry:
  %b = bitcast bfloat %x to i16
  %z = zext i16 %b to i32
  ret i32 %z
}

define void @bf_store(bfloat %x) noinline {
entry:
  store bfloat %x, ptr @slot.bf, align 2
  ret void
}

define <4 x bfloat> @v4_id(<4 x bfloat> %x) noinline {
entry:
  ret <4 x bfloat> %x
}

define <4 x bfloat> @v4_flip(<4 x bfloat> %x) noinline {
entry:
  %b = bitcast <4 x bfloat> %x to <4 x i16>
  %n = xor <4 x i16> %b, <i16 -32768, i16 -32768, i16 -32768, i16 -32768>
  %r = bitcast <4 x i16> %n to <4 x bfloat>
  ret <4 x bfloat> %r
}

define <8 x bfloat> @v8_id(<8 x bfloat> %x) noinline {
entry:
  ret <8 x bfloat> %x
}

; ----- positives -----

define bfloat @protected_via_arg(ptr %fp, bfloat %x) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat %fp(bfloat %x)
  ret bfloat %r
}

define bfloat @protected_via_select(i1 %pick, bfloat %x) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %fp = select i1 %pick, ptr @bf_id, ptr @bf_flip
  %r = call bfloat %fp(bfloat %x)
  ret bfloat %r
}

define bfloat @protected_via_global(i64 %idx, bfloat %x) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %slot = getelementptr inbounds [2 x ptr], ptr @vt.bf, i64 0, i64 %idx
  %fp = load ptr, ptr %slot, align 8
  %r = call bfloat %fp(bfloat %x)
  ret bfloat %r
}

define bfloat @protected_via_phi(i1 %pick, bfloat %x) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  br i1 %pick, label %left, label %right

left:
  br label %join

right:
  br label %join

join:
  %fp = phi ptr [ @bf_id, %left ], [ @bf_flip, %right ]
  %r = call bfloat %fp(bfloat %x)
  ret bfloat %r
}

define bfloat @protected_mixed(ptr %fp, bfloat %x, i32 %k) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat %fp(bfloat %x, i32 %k)
  ret bfloat %r
}

define i32 @protected_to_i32(ptr %fp, bfloat %x) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call i32 %fp(bfloat %x)
  ret i32 %r
}

define void @protected_void(ptr %fp, bfloat %x) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  call void %fp(bfloat %x)
  ret void
}

define <4 x bfloat> @protected_v4_via_arg(ptr %fp, <4 x bfloat> %x) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x bfloat> %fp(<4 x bfloat> %x)
  ret <4 x bfloat> %r
}

define <4 x bfloat> @protected_v4_via_global(i64 %idx, <4 x bfloat> %x) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %slot = getelementptr inbounds [2 x ptr], ptr @vt.v4, i64 0, i64 %idx
  %fp = load ptr, ptr %slot, align 8
  %r = call <4 x bfloat> %fp(<4 x bfloat> %x)
  ret <4 x bfloat> %r
}

define <4 x bfloat> @protected_v4_via_select(i1 %pick, <4 x bfloat> %x) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %fp = select i1 %pick, ptr @v4_id, ptr @v4_flip
  %r = call <4 x bfloat> %fp(<4 x bfloat> %x)
  ret <4 x bfloat> %r
}

define <8 x bfloat> @protected_v8_via_arg(ptr %fp, <8 x bfloat> %x) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <8 x bfloat> %fp(<8 x bfloat> %x)
  ret <8 x bfloat> %r
}

define bfloat @protected_last_token(ptr %fp, bfloat %x) noinline optnone "target-features"="+neon,+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat %fp(bfloat %x)
  ret bfloat %r
}



; Function-pointer recursion: non-tail call through a global that may
; point at this same virtualized function.
define bfloat @protected_fp_rec(bfloat %x, i32 %n) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %z = icmp eq i32 %n, 0
  br i1 %z, label %done, label %rec

rec:
  %n1 = add i32 %n, -1
  %fp = load ptr, ptr @cb.rec, align 8
  %r = call bfloat %fp(bfloat %x, i32 %n1)
  ret bfloat %r

done:
  ret bfloat %x
}

; ----- negatives -----

define i32 @unsupported_no_feature(ptr %fp) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call bfloat %fp(bfloat 0xR3F80)
  ret i32 0
}

define i32 @unsupported_disabled(ptr %fp) noinline optnone "target-features"="+neon,+bf16,-bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat %fp(bfloat 0xR3F80)
  ret i32 0
}

define bfloat @unsupported_fmf(ptr %fp, bfloat %x) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call nnan bfloat %fp(bfloat %x)
  ret bfloat %r
}

define bfloat @unsupported_musttail(bfloat %x) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %fp = load ptr, ptr @vt.bf, align 8
  %r = musttail call bfloat %fp(bfloat %x)
  ret bfloat %r
}

define bfloat @unsupported_fastcc(ptr %fp, bfloat %x) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call fastcc bfloat %fp(bfloat %x)
  ret bfloat %r
}

define bfloat @unsupported_vararg(ptr %fp, bfloat %x) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat (bfloat, ...) %fp(bfloat %x)
  ret bfloat %r
}

define bfloat @unsupported_bundle(ptr %fp, bfloat %x) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat %fp(bfloat %x) [ "deopt"() ]
  ret bfloat %r
}

define void @unsupported_noreturn(ptr %fp, bfloat %x) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  call void %fp(bfloat %x) noreturn
  unreachable
}

define bfloat @unsupported_returns_twice(ptr %fp, bfloat %x) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat %fp(bfloat %x) returns_twice
  ret bfloat %r
}

define void @unsupported_sret(ptr %fp, ptr sret(i32) %p, bfloat %x) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  call void %fp(ptr sret(i32) %p, bfloat %x)
  ret void
}

define bfloat @unsupported_poison(ptr %fp) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat %fp(bfloat poison)
  ret bfloat %r
}

define i32 @unsupported_wide(ptr %fp) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <16 x bfloat> %fp(<16 x bfloat> zeroinitializer)
  ret i32 0
}

define i32 @unsupported_scalable(ptr %fp) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x bfloat> %fp(<vscale x 4 x bfloat> zeroinitializer)
  ret i32 0
}

define i32 @unsupported_agg_ret(ptr %fp) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call %Pair %fp(bfloat 0xR3F80)
  ret i32 0
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_no_feature: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_fmf: unsupported float call instruction
; SKIP-DAG: Skipping VMP on unsupported_musttail: indirect call
; SKIP-DAG: Skipping VMP on unsupported_fastcc: indirect call
; SKIP-DAG: Skipping VMP on unsupported_vararg: indirect call
; SKIP-DAG: Skipping VMP on unsupported_bundle: indirect call
; SKIP-DAG: Skipping VMP on unsupported_noreturn: indirect call
; SKIP-DAG: Skipping VMP on unsupported_returns_twice: indirect call
; SKIP-DAG: Skipping VMP on unsupported_sret: indirect call
; SKIP-DAG: Skipping VMP on unsupported_poison: indirect call
; SKIP-DAG: Skipping VMP on unsupported_wide: indirect call
; SKIP-DAG: Skipping VMP on unsupported_scalable: indirect call
; SKIP-DAG: Skipping VMP on unsupported_agg_ret: indirect call
; SKIP-NOT: Skipping VMP on protected_via_arg:
; SKIP-NOT: Skipping VMP on protected_via_select:
; SKIP-NOT: Skipping VMP on protected_via_global:
; SKIP-NOT: Skipping VMP on protected_via_phi:
; SKIP-NOT: Skipping VMP on protected_mixed:
; SKIP-NOT: Skipping VMP on protected_to_i32:
; SKIP-NOT: Skipping VMP on protected_void:
; SKIP-NOT: Skipping VMP on protected_v4_via_arg:
; SKIP-NOT: Skipping VMP on protected_v4_via_global:
; SKIP-NOT: Skipping VMP on protected_v4_via_select:
; SKIP-NOT: Skipping VMP on protected_v8_via_arg:
; SKIP-NOT: Skipping VMP on protected_last_token:
; SKIP-NOT: Skipping VMP on protected_fp_rec:

; VIRT: define bfloat @protected_via_arg({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; Scalar bfloat travels on the float frame, not an i16 integer slot.
; VIRT-NOT: nnan
; VIRT-DAG: load volatile i64
; VIRT: call{{.*}}bfloat %{{.+}}(bfloat
; VIRT: define bfloat @protected_via_select({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call{{.*}}bfloat %{{.+}}(bfloat
; VIRT: define bfloat @protected_via_global({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call{{.*}}bfloat %{{.+}}(bfloat
; VIRT: define bfloat @protected_via_phi({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call{{.*}}bfloat %{{.+}}(bfloat
; VIRT: define bfloat @protected_mixed({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call{{.*}}bfloat %{{.+}}(bfloat{{.*}}i32
; VIRT: define i32 @protected_to_i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: nnan
; VIRT: call{{.*}}i32 %{{.+}}(bfloat
; VIRT: define void @protected_void({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: nnan
; VIRT: call{{.*}}void %{{.+}}(bfloat
; VIRT: define <4 x bfloat> @protected_v4_via_arg({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; Vector args load from the i128 vector frame.
; VIRT-NOT: nnan
; VIRT-DAG: load volatile i128
; VIRT-DAG: bitcast {{.*}} to <4 x bfloat>
; VIRT: call{{.*}}<4 x bfloat> %{{.+}}(<4 x bfloat>
; VIRT-DAG: bitcast <4 x bfloat> {{.*}} to i{{.*}}
; VIRT-DAG: store volatile i128
; VIRT: define <4 x bfloat> @protected_v4_via_global({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call{{.*}}<4 x bfloat> %{{.+}}(<4 x bfloat>
; VIRT: define <4 x bfloat> @protected_v4_via_select({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call{{.*}}<4 x bfloat> %{{.+}}(<4 x bfloat>
; VIRT: define <8 x bfloat> @protected_v8_via_arg({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call{{.*}}<8 x bfloat> %{{.+}}(<8 x bfloat>
; VIRT: define bfloat @protected_last_token({{.*}} #[[PROTLAST:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call{{.*}}bfloat %{{.+}}(bfloat
; VIRT: define bfloat @protected_fp_rec({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: tail call
; VIRT: call{{.*}}bfloat %{{.+}}(bfloat{{.*}}i32
; VIRT: define {{.*}} @unsupported_no_feature({{.*}} #[[UNSUPFEAT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_disabled({{.*}} #[[UNSUPDIS:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fmf({{.*}} #[[UNSUPFMF:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call nnan bfloat %{{.+}}(bfloat
; VIRT: define {{.*}} @unsupported_musttail({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fastcc({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_vararg({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_bundle({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_noreturn({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_returns_twice({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_sret({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_poison({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_wide({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_scalable({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_agg_ret({{.*}} #[[UNSUPFMF]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[PROTLAST]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT-DAG: attributes #[[UNSUPFMF]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-DAG: attributes #[[UNSUPFEAT]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-DAG: attributes #[[UNSUPDIS]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPFEAT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPDIS]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPFMF]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
