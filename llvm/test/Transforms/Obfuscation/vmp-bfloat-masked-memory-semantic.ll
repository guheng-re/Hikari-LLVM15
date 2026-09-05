; Last-token +bf16 llvm.masked.load / llvm.masked.store on supported
; fixed 1..128 bfloat vectors.  Exact token only (+bf16fml does not
; count; command-line -mattr is never read).  Well-shaped listed
; calls missing or ending in -bf16 skip as unsupported target
; feature and keep hikari.vmp.selected.
;
; No new VM opcode.  CallDescriptor.LegalizeBFloatMaskedMemory.
; Never replay llvm.masked.load/store.vNbf16.  Never an unprotected
; whole-vector load/store plus select.  Each lane is a condbr-guarded
; scalar bfloat load/store; inactive lanes do not touch that address.
; Load inactive lanes keep passthru.  Per-lane alignment is
; commonAlignment(vector-align, lane*2).  Safe memory metadata and
; DebugLoc from the source call are applied to each scalar op.
;
; Rejected: atomic (not representable), scalable/overwide, non-AS0,
; non-imm or non-power-of-two align, mask/passthru mismatch (helper
; still checks; illegal IR stays out of this lit), poison/undef,
; musttail, bundles, noreturn, returns_twice, complex ABI,
; non-C, missing or last-token -bf16.
; Well-shaped C gather/scatter and expand/compress moved to sibling
; lits; this file keeps fastcc forms as ABI rejects.
;
; Host x86 cannot be assumed to select bfloat.  This lit is
; FileCheck + AArch64 llc/readobj only (function +bf16, no global
; -mattr).
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
declare <1 x bfloat> @llvm.masked.load.v1bf16.p0(ptr, i32, <1 x i1>, <1 x bfloat>)
declare void @llvm.masked.store.v1bf16.p0(<1 x bfloat>, ptr, i32, <1 x i1>)
declare <2 x bfloat> @llvm.masked.load.v2bf16.p0(ptr, i32, <2 x i1>, <2 x bfloat>)
declare <4 x bfloat> @llvm.masked.load.v4bf16.p0(ptr, i32, <4 x i1>, <4 x bfloat>)
declare void @llvm.masked.store.v4bf16.p0(<4 x bfloat>, ptr, i32, <4 x i1>)
declare <8 x bfloat> @llvm.masked.load.v8bf16.p0(ptr, i32, <8 x i1>, <8 x bfloat>)
declare void @llvm.masked.store.v8bf16.p0(<8 x bfloat>, ptr, i32, <8 x i1>)
declare <16 x bfloat> @llvm.masked.load.v16bf16.p0(ptr, i32, <16 x i1>, <16 x bfloat>)
declare <vscale x 4 x bfloat> @llvm.masked.load.nxv4bf16.p0(ptr, i32, <vscale x 4 x i1>, <vscale x 4 x bfloat>)
declare <4 x bfloat> @llvm.masked.load.v4bf16.p1(ptr addrspace(1), i32, <4 x i1>, <4 x bfloat>)
declare <4 x bfloat> @llvm.masked.gather.v4bf16.v4p0(<4 x ptr>, i32, <4 x i1>, <4 x bfloat>)
declare void @llvm.masked.scatter.v4bf16.v4p0(<4 x bfloat>, <4 x ptr>, i32, <4 x i1>)
declare <4 x bfloat> @llvm.masked.expandload.v4bf16(ptr, <4 x i1>, <4 x bfloat>)
declare void @llvm.masked.compressstore.v4bf16(<4 x bfloat>, ptr, <4 x i1>)

; ----- positives -----

define <1 x bfloat> @protected_load_v1(ptr %p, <1 x i1> %m, <1 x bfloat> %t) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <1 x bfloat> @llvm.masked.load.v1bf16.p0(ptr %p, i32 2, <1 x i1> %m, <1 x bfloat> %t)
  ret <1 x bfloat> %r
}

define <2 x bfloat> @protected_load_v2(ptr %p, <2 x i1> %m, <2 x bfloat> %t) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <2 x bfloat> @llvm.masked.load.v2bf16.p0(ptr %p, i32 2, <2 x i1> %m, <2 x bfloat> %t)
  ret <2 x bfloat> %r
}

define <4 x bfloat> @protected_load_dyn(ptr %p, <4 x i1> %m, <4 x bfloat> %t) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x bfloat> @llvm.masked.load.v4bf16.p0(ptr %p, i32 2, <4 x i1> %m, <4 x bfloat> %t)
  ret <4 x bfloat> %r
}

define <4 x bfloat> @protected_load_alltrue(ptr %p, <4 x bfloat> %t) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x bfloat> @llvm.masked.load.v4bf16.p0(ptr %p, i32 2, <4 x i1> <i1 true, i1 true, i1 true, i1 true>, <4 x bfloat> %t)
  ret <4 x bfloat> %r
}

define <4 x bfloat> @protected_load_allfalse(ptr %p, <4 x bfloat> %t) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x bfloat> @llvm.masked.load.v4bf16.p0(ptr %p, i32 2, <4 x i1> zeroinitializer, <4 x bfloat> %t)
  ret <4 x bfloat> %r
}

; align 8: lane0=8, lane1=2, lane2=4, lane3=2
define <4 x bfloat> @protected_load_align8(ptr %p, <4 x i1> %m, <4 x bfloat> %t) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x bfloat> @llvm.masked.load.v4bf16.p0(ptr %p, i32 8, <4 x i1> %m, <4 x bfloat> %t), !nontemporal !0
  ret <4 x bfloat> %r
}

define <4 x bfloat> @protected_load_align1(ptr %p, <4 x i1> %m, <4 x bfloat> %t) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x bfloat> @llvm.masked.load.v4bf16.p0(ptr %p, i32 1, <4 x i1> %m, <4 x bfloat> %t)
  ret <4 x bfloat> %r
}

define void @protected_store_dyn(ptr %p, <4 x i1> %m, <4 x bfloat> %v) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  call void @llvm.masked.store.v4bf16.p0(<4 x bfloat> %v, ptr %p, i32 2, <4 x i1> %m)
  ret void
}

define void @protected_store_v1(ptr %p, <1 x i1> %m, <1 x bfloat> %v) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  call void @llvm.masked.store.v1bf16.p0(<1 x bfloat> %v, ptr %p, i32 2, <1 x i1> %m)
  ret void
}

define <8 x bfloat> @protected_load_v8(ptr %p, <8 x i1> %m, <8 x bfloat> %t) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <8 x bfloat> @llvm.masked.load.v8bf16.p0(ptr %p, i32 2, <8 x i1> %m, <8 x bfloat> %t)
  ret <8 x bfloat> %r
}

define void @protected_store_v8(ptr %p, <8 x i1> %m, <8 x bfloat> %v) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  call void @llvm.masked.store.v8bf16.p0(<8 x bfloat> %v, ptr %p, i32 2, <8 x i1> %m)
  ret void
}

; Runtime NaN / -0 keep special-value bit patterns live under O2.
define <4 x bfloat> @protected_special(ptr %p, i1 %c, <4 x i1> %m, <4 x bfloat> %t) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %nan = select i1 %c, bfloat 0xR7FC0, bfloat 0xR0000
  %n0 = select i1 %c, bfloat 0xR8000, bfloat 0xR0000
  %pt0 = insertelement <4 x bfloat> %t, bfloat %nan, i32 0
  %pt1 = insertelement <4 x bfloat> %pt0, bfloat %n0, i32 1
  %r = call <4 x bfloat> @llvm.masked.load.v4bf16.p0(ptr %p, i32 2, <4 x i1> %m, <4 x bfloat> %pt1)
  ret <4 x bfloat> %r
}

define <4 x bfloat> @protected_last_token(ptr %p, <4 x i1> %m, <4 x bfloat> %t) noinline optnone "target-features"="+neon,+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x bfloat> @llvm.masked.load.v4bf16.p0(ptr %p, i32 2, <4 x i1> %m, <4 x bfloat> %t)
  ret <4 x bfloat> %r
}

; ----- negatives -----

define i32 @unsupported_masked_no_feature(ptr %p, <4 x i1> %m, <4 x i16> %bits) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = bitcast <4 x i16> %bits to <4 x bfloat>
  %r = call <4 x bfloat> @llvm.masked.load.v4bf16.p0(ptr %p, i32 2, <4 x i1> %m, <4 x bfloat> %t)
  %b = bitcast <4 x bfloat> %r to <4 x i16>
  %e = extractelement <4 x i16> %b, i32 0
  %w = zext i16 %e to i32
  ret i32 %w
}

define i32 @unsupported_masked_disabled(ptr %p, <4 x i1> %m, <4 x i16> %bits) noinline optnone "target-features"="+neon,+bf16,-bf16" {
entry:
  call void @hikari_vmp()
  %t = bitcast <4 x i16> %bits to <4 x bfloat>
  %r = call <4 x bfloat> @llvm.masked.load.v4bf16.p0(ptr %p, i32 2, <4 x i1> %m, <4 x bfloat> %t)
  %b = bitcast <4 x bfloat> %r to <4 x i16>
  %e = extractelement <4 x i16> %b, i32 0
  %w = zext i16 %e to i32
  ret i32 %w
}

define i32 @unsupported_masked_bf16fml_only(ptr %p, <4 x i1> %m, <4 x i16> %bits) noinline optnone "target-features"="+bf16fml" {
entry:
  call void @hikari_vmp()
  %t = bitcast <4 x i16> %bits to <4 x bfloat>
  %r = call <4 x bfloat> @llvm.masked.load.v4bf16.p0(ptr %p, i32 2, <4 x i1> %m, <4 x bfloat> %t)
  %b = bitcast <4 x bfloat> %r to <4 x i16>
  %e = extractelement <4 x i16> %b, i32 0
  %w = zext i16 %e to i32
  ret i32 %w
}


define <4 x bfloat> @unsupported_masked_musttail(ptr %p, <4 x i1> %m, <4 x bfloat> %t) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = musttail call <4 x bfloat> @llvm.masked.load.v4bf16.p0(ptr %p, i32 2, <4 x i1> %m, <4 x bfloat> %t)
  ret <4 x bfloat> %r
}

define <4 x bfloat> @unsupported_masked_bundle(ptr %p, <4 x i1> %m, <4 x bfloat> %t) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x bfloat> @llvm.masked.load.v4bf16.p0(ptr %p, i32 2, <4 x i1> %m, <4 x bfloat> %t) [ "deopt"() ]
  ret <4 x bfloat> %r
}

define void @unsupported_masked_noreturn(ptr %p, <4 x i1> %m, <4 x bfloat> %v) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  call void @llvm.masked.store.v4bf16.p0(<4 x bfloat> %v, ptr %p, i32 2, <4 x i1> %m) noreturn
  ret void
}

define void @unsupported_masked_returns_twice(ptr %p, <4 x i1> %m, <4 x bfloat> %v) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  call void @llvm.masked.store.v4bf16.p0(<4 x bfloat> %v, ptr %p, i32 2, <4 x i1> %m) returns_twice
  ret void
}

define <4 x bfloat> @unsupported_masked_fastcc(ptr %p, <4 x i1> %m, <4 x bfloat> %t) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call fastcc <4 x bfloat> @llvm.masked.load.v4bf16.p0(ptr %p, i32 2, <4 x i1> %m, <4 x bfloat> %t)
  ret <4 x bfloat> %r
}

define <4 x bfloat> @unsupported_masked_poison(ptr %p, <4 x i1> %m) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x bfloat> @llvm.masked.load.v4bf16.p0(ptr %p, i32 2, <4 x i1> %m, <4 x bfloat> poison)
  ret <4 x bfloat> %r
}

define void @unsupported_masked_undef(ptr %p, <4 x i1> %m) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  call void @llvm.masked.store.v4bf16.p0(<4 x bfloat> undef, ptr %p, i32 2, <4 x i1> %m)
  ret void
}

define <4 x bfloat> @unsupported_masked_as1(ptr addrspace(1) %p, <4 x i1> %m, <4 x bfloat> %t) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x bfloat> @llvm.masked.load.v4bf16.p1(ptr addrspace(1) %p, i32 2, <4 x i1> %m, <4 x bfloat> %t)
  ret <4 x bfloat> %r
}

define void @unsupported_wide(ptr %p) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <16 x bfloat> @llvm.masked.load.v16bf16.p0(ptr %p, i32 2, <16 x i1> zeroinitializer, <16 x bfloat> zeroinitializer)
  ret void
}

define i32 @unsupported_scalable() noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x bfloat> @llvm.masked.load.nxv4bf16.p0(ptr null, i32 2, <vscale x 4 x i1> zeroinitializer, <vscale x 4 x bfloat> zeroinitializer)
  ret i32 0
}

define i32 @unsupported_gather() noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call fastcc <4 x bfloat> @llvm.masked.gather.v4bf16.v4p0(<4 x ptr> zeroinitializer, i32 2, <4 x i1> zeroinitializer, <4 x bfloat> zeroinitializer)
  ret i32 0
}

define i32 @unsupported_scatter() noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  call fastcc void @llvm.masked.scatter.v4bf16.v4p0(<4 x bfloat> zeroinitializer, <4 x ptr> zeroinitializer, i32 2, <4 x i1> zeroinitializer)
  ret i32 0
}

define <4 x bfloat> @unsupported_expand(ptr %p, <4 x i1> %m, <4 x bfloat> %t) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call fastcc <4 x bfloat> @llvm.masked.expandload.v4bf16(ptr %p, <4 x i1> %m, <4 x bfloat> %t)
  ret <4 x bfloat> %r
}

define void @unsupported_compress(ptr %p, <4 x i1> %m, <4 x bfloat> %v) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  call fastcc void @llvm.masked.compressstore.v4bf16(<4 x bfloat> %v, ptr %p, <4 x i1> %m)
  ret void
}

!0 = !{i32 1}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_masked_no_feature: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_masked_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_masked_bf16fml_only: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_masked_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_masked_bundle: unsupported masked memory instruction
; SKIP-DAG: Skipping VMP on unsupported_masked_noreturn: unsupported masked memory instruction
; SKIP-DAG: Skipping VMP on unsupported_masked_returns_twice: unsupported masked memory instruction
; SKIP-DAG: Skipping VMP on unsupported_masked_fastcc: unsupported masked memory instruction
; SKIP-DAG: Skipping VMP on unsupported_masked_poison: unsupported masked memory instruction
; SKIP-DAG: Skipping VMP on unsupported_masked_undef: unsupported masked memory instruction
; SKIP-DAG: Skipping VMP on unsupported_masked_as1: unsupported
; SKIP-DAG: Skipping VMP on unsupported_wide: unsupported masked memory instruction
; SKIP-DAG: Skipping VMP on unsupported_scalable: unsupported masked memory instruction
; SKIP-DAG: Skipping VMP on unsupported_gather: unsupported masked memory instruction
; SKIP-DAG: Skipping VMP on unsupported_scatter: unsupported masked memory instruction
; SKIP-DAG: Skipping VMP on unsupported_expand: unsupported masked memory instruction
; SKIP-DAG: Skipping VMP on unsupported_compress: unsupported masked memory instruction
; SKIP-NOT: Skipping VMP on protected_load_v1:
; SKIP-NOT: Skipping VMP on protected_load_v2:
; SKIP-NOT: Skipping VMP on protected_load_dyn:
; SKIP-NOT: Skipping VMP on protected_load_alltrue:
; SKIP-NOT: Skipping VMP on protected_load_allfalse:
; SKIP-NOT: Skipping VMP on protected_load_align8:
; SKIP-NOT: Skipping VMP on protected_load_align1:
; SKIP-NOT: Skipping VMP on protected_store_dyn:
; SKIP-NOT: Skipping VMP on protected_store_v1:
; SKIP-NOT: Skipping VMP on protected_load_v8:
; SKIP-NOT: Skipping VMP on protected_store_v8:
; SKIP-NOT: Skipping VMP on protected_special:
; SKIP-NOT: Skipping VMP on protected_last_token:

; VIRT: define <1 x bfloat> @protected_load_v1({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.masked.load
; VIRT-NOT: load <
; VIRT: br i1
; VIRT: load bfloat
; VIRT: define <2 x bfloat> @protected_load_v2({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.masked.load
; VIRT-NOT: load <
; VIRT: br i1
; VIRT: load bfloat
; VIRT: br i1
; VIRT: load bfloat
; VIRT: define <4 x bfloat> @protected_load_dyn({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.masked.load
; VIRT-NOT: load <{{.*}}bfloat
; VIRT: br i1
; VIRT: load bfloat
; VIRT: br i1
; VIRT: load bfloat
; VIRT: br i1
; VIRT: load bfloat
; VIRT: br i1
; VIRT: load bfloat
; VIRT: define <4 x bfloat> @protected_load_alltrue({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.masked.load
; VIRT-NOT: load <{{.*}}bfloat
; VIRT: br i1
; VIRT: load bfloat
; VIRT: define <4 x bfloat> @protected_load_allfalse({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.masked.load
; VIRT-NOT: load <{{.*}}bfloat
; VIRT: br i1
; VIRT: define <4 x bfloat> @protected_load_align8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.masked.load
; VIRT: load bfloat, ptr {{.*}}, align 8, !nontemporal ![[NT:[0-9]+]]
; VIRT: load bfloat, ptr {{.*}}, align 2, !nontemporal ![[NT]]
; VIRT: load bfloat, ptr {{.*}}, align 4, !nontemporal ![[NT]]
; VIRT: load bfloat, ptr {{.*}}, align 2, !nontemporal ![[NT]]
; VIRT: define <4 x bfloat> @protected_load_align1({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: load bfloat, ptr {{.*}}, align 1
; VIRT: load bfloat, ptr {{.*}}, align 1
; VIRT: define void @protected_store_dyn({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.masked.store
; VIRT-NOT: store <{{.*}}bfloat
; VIRT: br i1
; VIRT: store bfloat
; VIRT: br i1
; VIRT: store bfloat
; VIRT: define void @protected_store_v1({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.masked.store
; VIRT: br i1
; VIRT: store bfloat
; VIRT: define <8 x bfloat> @protected_load_v8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.masked.load
; VIRT-NOT: load <{{.*}}bfloat
; VIRT: br i1
; VIRT: load bfloat
; VIRT: define void @protected_store_v8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.masked.store
; VIRT: br i1
; VIRT: store bfloat
; VIRT: define <4 x bfloat> @protected_special({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.masked.load
; VIRT: br i1
; VIRT: load bfloat
; VIRT: define <4 x bfloat> @protected_last_token({{.*}} #[[PROTLAST:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.masked.load
; VIRT: br i1
; VIRT: load bfloat
; VIRT: define {{.*}} @unsupported_masked_no_feature({{.*}} #[[UNSUPFEAT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_masked_disabled({{.*}} #[[UNSUPDIS:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_masked_bf16fml_only({{.*}} #[[UNSUPFML:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_masked_musttail({{.*}} #[[UNSUPMUST:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_masked_bundle({{.*}} #[[UNSUPMSK:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_masked_noreturn({{.*}} #[[UNSUPMSK]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_masked_returns_twice({{.*}} #[[UNSUPMSK]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_masked_fastcc({{.*}} #[[UNSUPMSK]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_masked_poison({{.*}} #[[UNSUPMSK]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_masked_undef({{.*}} #[[UNSUPMSK]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_masked_as1({{.*}} #[[UNSUPMSK]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_wide({{.*}} #[[UNSUPMSK]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_scalable({{.*}} #[[UNSUPMSK]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_gather({{.*}} #[[UNSUPMSK]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_scatter({{.*}} #[[UNSUPMSK]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_expand({{.*}} #[[UNSUPMSK]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_compress({{.*}} #[[UNSUPMSK]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[PROTLAST]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPFEAT]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT: attributes #[[UNSUPDIS]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT: attributes #[[UNSUPFML]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT: attributes #[[UNSUPMSK]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT: attributes #[[UNSUPMUST]] = { noinline optnone "target-features"="+bf16" }
; VIRT-NOT: attributes #[[UNSUPFEAT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPDIS]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPFML]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPMSK]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPMUST]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPMUST]] = { {{.*}}"hikari.vmp.selected"
; VIRT: ![[NT]] = !{i32 1}

; AARCH64: Arch: aarch64
