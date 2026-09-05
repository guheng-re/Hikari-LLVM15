; Last-token +bf16 llvm.masked.gather / llvm.masked.scatter on
; supported fixed 1..128 bfloat vectors.  Exact token only (+bf16fml
; does not count; command-line -mattr is never read).  Well-shaped
; listed calls missing or ending in -bf16 skip as unsupported target
; feature and keep hikari.vmp.selected.
;
; No new VM opcode.  CallDescriptor.LegalizeBFloatMaskedMemory.
; Never replay llvm.masked.gather/scatter.vNbf16.  Never an
; unprotected whole-vector access plus select.  Pointers are a
; matching <N x ptr> AS0 (N=1..8) in the existing pointer-vector
; frame.  Each lane is a condbr-guarded scalar bfloat load/store of
; that lane's pointer; inactive lanes do not dereference.  Gather
; inactive lanes keep passthru.  Every lane uses the ImmArg
; alignment (addresses are independent).  Safe memory metadata and
; DebugLoc from the source call are applied to each scalar op.
;
; Rejected: non-AS0, pointer/mask/value lane mismatch (helper still
; checks; illegal IR stays out), scalable/overwide, non-imm or
; non-power-of-two align, musttail, bundles, noreturn,
; returns_twice, complex ABI, non-C, missing or last-token -bf16,
; poison/undef, masked.load/store (covered by the sibling lit).
; Well-shaped C expand/compress moved to
; vmp-bfloat-expand-compress-semantic.ll; this file keeps fastcc
; forms as ABI rejects.
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
declare <1 x bfloat> @llvm.masked.gather.v1bf16.v1p0(<1 x ptr>, i32, <1 x i1>, <1 x bfloat>)
declare void @llvm.masked.scatter.v1bf16.v1p0(<1 x bfloat>, <1 x ptr>, i32, <1 x i1>)
declare <2 x bfloat> @llvm.masked.gather.v2bf16.v2p0(<2 x ptr>, i32, <2 x i1>, <2 x bfloat>)
declare void @llvm.masked.scatter.v2bf16.v2p0(<2 x bfloat>, <2 x ptr>, i32, <2 x i1>)
declare <4 x bfloat> @llvm.masked.gather.v4bf16.v4p0(<4 x ptr>, i32, <4 x i1>, <4 x bfloat>)
declare void @llvm.masked.scatter.v4bf16.v4p0(<4 x bfloat>, <4 x ptr>, i32, <4 x i1>)
declare <8 x bfloat> @llvm.masked.gather.v8bf16.v8p0(<8 x ptr>, i32, <8 x i1>, <8 x bfloat>)
declare void @llvm.masked.scatter.v8bf16.v8p0(<8 x bfloat>, <8 x ptr>, i32, <8 x i1>)
declare <16 x bfloat> @llvm.masked.gather.v16bf16.v16p0(<16 x ptr>, i32, <16 x i1>, <16 x bfloat>)
declare <vscale x 4 x bfloat> @llvm.masked.gather.nxv4bf16.nxv4p0(<vscale x 4 x ptr>, i32, <vscale x 4 x i1>, <vscale x 4 x bfloat>)
declare <4 x bfloat> @llvm.masked.gather.v4bf16.v4p1(<4 x ptr addrspace(1)>, i32, <4 x i1>, <4 x bfloat>)
declare <4 x bfloat> @llvm.masked.load.v4bf16.p0(ptr, i32, <4 x i1>, <4 x bfloat>)
declare <4 x bfloat> @llvm.masked.expandload.v4bf16(ptr, <4 x i1>, <4 x bfloat>)
declare void @llvm.masked.compressstore.v4bf16(<4 x bfloat>, ptr, <4 x i1>)

; ----- positives -----

define <1 x bfloat> @protected_gather_v1(ptr %base, <1 x i1> %m, <1 x bfloat> %t) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %ptrs = insertelement <1 x ptr> zeroinitializer, ptr %base, i32 0
  %r = call <1 x bfloat> @llvm.masked.gather.v1bf16.v1p0(<1 x ptr> %ptrs, i32 2, <1 x i1> %m, <1 x bfloat> %t)
  ret <1 x bfloat> %r
}

define <2 x bfloat> @protected_gather_v2(ptr %base, <2 x i32> %idx, <2 x i1> %m, <2 x bfloat> %t) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %ptrs = getelementptr bfloat, ptr %base, <2 x i32> %idx
  %r = call <2 x bfloat> @llvm.masked.gather.v2bf16.v2p0(<2 x ptr> %ptrs, i32 2, <2 x i1> %m, <2 x bfloat> %t)
  ret <2 x bfloat> %r
}

define <4 x bfloat> @protected_gather_dyn(ptr %base, <4 x i32> %idx, <4 x i1> %m, <4 x bfloat> %t) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %ptrs = getelementptr bfloat, ptr %base, <4 x i32> %idx
  %r = call <4 x bfloat> @llvm.masked.gather.v4bf16.v4p0(<4 x ptr> %ptrs, i32 2, <4 x i1> %m, <4 x bfloat> %t)
  ret <4 x bfloat> %r
}

define <4 x bfloat> @protected_gather_alltrue(ptr %base, <4 x bfloat> %t) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %ptrs = getelementptr bfloat, ptr %base, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  %r = call <4 x bfloat> @llvm.masked.gather.v4bf16.v4p0(<4 x ptr> %ptrs, i32 2, <4 x i1> <i1 true, i1 true, i1 true, i1 true>, <4 x bfloat> %t)
  ret <4 x bfloat> %r
}

define <4 x bfloat> @protected_gather_allfalse(ptr %base, <4 x bfloat> %t) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %ptrs = getelementptr bfloat, ptr %base, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  %r = call <4 x bfloat> @llvm.masked.gather.v4bf16.v4p0(<4 x ptr> %ptrs, i32 2, <4 x i1> zeroinitializer, <4 x bfloat> %t)
  ret <4 x bfloat> %r
}

; Independent pointers: ImmArg align applies to every lane.
define <4 x bfloat> @protected_gather_align8(ptr %base, <4 x i32> %idx, <4 x i1> %m, <4 x bfloat> %t) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %ptrs = getelementptr bfloat, ptr %base, <4 x i32> %idx
  %r = call <4 x bfloat> @llvm.masked.gather.v4bf16.v4p0(<4 x ptr> %ptrs, i32 8, <4 x i1> %m, <4 x bfloat> %t), !nontemporal !0
  ret <4 x bfloat> %r
}

define <4 x bfloat> @protected_gather_align1(ptr %base, <4 x i32> %idx, <4 x i1> %m, <4 x bfloat> %t) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %ptrs = getelementptr bfloat, ptr %base, <4 x i32> %idx
  %r = call <4 x bfloat> @llvm.masked.gather.v4bf16.v4p0(<4 x ptr> %ptrs, i32 1, <4 x i1> %m, <4 x bfloat> %t)
  ret <4 x bfloat> %r
}

define void @protected_scatter_dyn(<4 x bfloat> %v, ptr %base, <4 x i32> %idx, <4 x i1> %m) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %ptrs = getelementptr bfloat, ptr %base, <4 x i32> %idx
  call void @llvm.masked.scatter.v4bf16.v4p0(<4 x bfloat> %v, <4 x ptr> %ptrs, i32 2, <4 x i1> %m)
  ret void
}

define void @protected_scatter_v1(<1 x bfloat> %v, ptr %base, <1 x i1> %m) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %ptrs = insertelement <1 x ptr> zeroinitializer, ptr %base, i32 0
  call void @llvm.masked.scatter.v1bf16.v1p0(<1 x bfloat> %v, <1 x ptr> %ptrs, i32 2, <1 x i1> %m)
  ret void
}

define <8 x bfloat> @protected_gather_v8(ptr %base, <8 x i1> %m, <8 x bfloat> %t) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %ptrs = getelementptr bfloat, ptr %base, <8 x i8> <i8 0, i8 1, i8 2, i8 3, i8 4, i8 5, i8 6, i8 7>
  %r = call <8 x bfloat> @llvm.masked.gather.v8bf16.v8p0(<8 x ptr> %ptrs, i32 2, <8 x i1> %m, <8 x bfloat> %t)
  ret <8 x bfloat> %r
}

define void @protected_scatter_v8(<8 x bfloat> %v, ptr %base, <8 x i1> %m) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %ptrs = getelementptr bfloat, ptr %base, <8 x i8> <i8 0, i8 1, i8 2, i8 3, i8 4, i8 5, i8 6, i8 7>
  call void @llvm.masked.scatter.v8bf16.v8p0(<8 x bfloat> %v, <8 x ptr> %ptrs, i32 2, <8 x i1> %m)
  ret void
}

; Runtime NaN / -0 keep special-value bit patterns live under O2.
define <4 x bfloat> @protected_special(ptr %base, i1 %c, <4 x i32> %idx, <4 x i1> %m, <4 x bfloat> %t) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %nan = select i1 %c, bfloat 0xR7FC0, bfloat 0xR0000
  %n0 = select i1 %c, bfloat 0xR8000, bfloat 0xR0000
  %pt0 = insertelement <4 x bfloat> %t, bfloat %nan, i32 0
  %pt1 = insertelement <4 x bfloat> %pt0, bfloat %n0, i32 1
  %ptrs = getelementptr bfloat, ptr %base, <4 x i32> %idx
  %r = call <4 x bfloat> @llvm.masked.gather.v4bf16.v4p0(<4 x ptr> %ptrs, i32 2, <4 x i1> %m, <4 x bfloat> %pt1)
  ret <4 x bfloat> %r
}

define <4 x bfloat> @protected_last_token(ptr %base, <4 x i32> %idx, <4 x i1> %m, <4 x bfloat> %t) noinline optnone "target-features"="+neon,+bf16" {
entry:
  call void @hikari_vmp()
  %ptrs = getelementptr bfloat, ptr %base, <4 x i32> %idx
  %r = call <4 x bfloat> @llvm.masked.gather.v4bf16.v4p0(<4 x ptr> %ptrs, i32 2, <4 x i1> %m, <4 x bfloat> %t)
  ret <4 x bfloat> %r
}

define <4 x bfloat> @protected_gather_insert(ptr %a, ptr %b, <4 x i1> %m, <4 x bfloat> %t) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %v0 = insertelement <4 x ptr> zeroinitializer, ptr %a, i32 0
  %v1 = insertelement <4 x ptr> %v0, ptr %b, i32 1
  %v2 = insertelement <4 x ptr> %v1, ptr %a, i32 2
  %ptrs = insertelement <4 x ptr> %v2, ptr %b, i32 3
  %r = call <4 x bfloat> @llvm.masked.gather.v4bf16.v4p0(<4 x ptr> %ptrs, i32 2, <4 x i1> %m, <4 x bfloat> %t)
  ret <4 x bfloat> %r
}

; ----- negatives -----

define i32 @unsupported_gs_no_feature(ptr %base, <4 x i1> %m, <4 x i16> %bits) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = bitcast <4 x i16> %bits to <4 x bfloat>
  %ptrs = getelementptr bfloat, ptr %base, <4 x i32> zeroinitializer
  %r = call <4 x bfloat> @llvm.masked.gather.v4bf16.v4p0(<4 x ptr> %ptrs, i32 2, <4 x i1> %m, <4 x bfloat> %t)
  %b = bitcast <4 x bfloat> %r to <4 x i16>
  %e = extractelement <4 x i16> %b, i32 0
  %w = zext i16 %e to i32
  ret i32 %w
}

define i32 @unsupported_gs_disabled(ptr %base, <4 x i1> %m, <4 x i16> %bits) noinline optnone "target-features"="+neon,+bf16,-bf16" {
entry:
  call void @hikari_vmp()
  %t = bitcast <4 x i16> %bits to <4 x bfloat>
  %ptrs = getelementptr bfloat, ptr %base, <4 x i32> zeroinitializer
  %r = call <4 x bfloat> @llvm.masked.gather.v4bf16.v4p0(<4 x ptr> %ptrs, i32 2, <4 x i1> %m, <4 x bfloat> %t)
  %b = bitcast <4 x bfloat> %r to <4 x i16>
  %e = extractelement <4 x i16> %b, i32 0
  %w = zext i16 %e to i32
  ret i32 %w
}

define i32 @unsupported_gs_bf16fml_only(ptr %base, <4 x i1> %m, <4 x i16> %bits) noinline optnone "target-features"="+bf16fml" {
entry:
  call void @hikari_vmp()
  %t = bitcast <4 x i16> %bits to <4 x bfloat>
  %ptrs = getelementptr bfloat, ptr %base, <4 x i32> zeroinitializer
  %r = call <4 x bfloat> @llvm.masked.gather.v4bf16.v4p0(<4 x ptr> %ptrs, i32 2, <4 x i1> %m, <4 x bfloat> %t)
  %b = bitcast <4 x bfloat> %r to <4 x i16>
  %e = extractelement <4 x i16> %b, i32 0
  %w = zext i16 %e to i32
  ret i32 %w
}


define <4 x bfloat> @unsupported_gs_musttail(ptr %base, <4 x i1> %m, <4 x bfloat> %t) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %ptrs = getelementptr bfloat, ptr %base, <4 x i32> zeroinitializer
  %r = musttail call <4 x bfloat> @llvm.masked.gather.v4bf16.v4p0(<4 x ptr> %ptrs, i32 2, <4 x i1> %m, <4 x bfloat> %t)
  ret <4 x bfloat> %r
}

define <4 x bfloat> @unsupported_gs_bundle(ptr %base, <4 x i1> %m, <4 x bfloat> %t) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %ptrs = getelementptr bfloat, ptr %base, <4 x i32> zeroinitializer
  %r = call <4 x bfloat> @llvm.masked.gather.v4bf16.v4p0(<4 x ptr> %ptrs, i32 2, <4 x i1> %m, <4 x bfloat> %t) [ "deopt"() ]
  ret <4 x bfloat> %r
}

define void @unsupported_gs_noreturn(<4 x bfloat> %v, ptr %base, <4 x i1> %m) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %ptrs = getelementptr bfloat, ptr %base, <4 x i32> zeroinitializer
  call void @llvm.masked.scatter.v4bf16.v4p0(<4 x bfloat> %v, <4 x ptr> %ptrs, i32 2, <4 x i1> %m) noreturn
  ret void
}

define void @unsupported_gs_returns_twice(<4 x bfloat> %v, ptr %base, <4 x i1> %m) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %ptrs = getelementptr bfloat, ptr %base, <4 x i32> zeroinitializer
  call void @llvm.masked.scatter.v4bf16.v4p0(<4 x bfloat> %v, <4 x ptr> %ptrs, i32 2, <4 x i1> %m) returns_twice
  ret void
}

define <4 x bfloat> @unsupported_gs_fastcc(ptr %base, <4 x i1> %m, <4 x bfloat> %t) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %ptrs = getelementptr bfloat, ptr %base, <4 x i32> zeroinitializer
  %r = call fastcc <4 x bfloat> @llvm.masked.gather.v4bf16.v4p0(<4 x ptr> %ptrs, i32 2, <4 x i1> %m, <4 x bfloat> %t)
  ret <4 x bfloat> %r
}

define <4 x bfloat> @unsupported_gs_poison(ptr %base, <4 x i1> %m) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %ptrs = getelementptr bfloat, ptr %base, <4 x i32> zeroinitializer
  %r = call <4 x bfloat> @llvm.masked.gather.v4bf16.v4p0(<4 x ptr> %ptrs, i32 2, <4 x i1> %m, <4 x bfloat> poison)
  ret <4 x bfloat> %r
}

define void @unsupported_gs_undef(<4 x bfloat> %v, ptr %base, <4 x i1> %m) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  call void @llvm.masked.scatter.v4bf16.v4p0(<4 x bfloat> %v, <4 x ptr> undef, i32 2, <4 x i1> %m)
  ret void
}

define <4 x bfloat> @unsupported_gs_as1(<4 x ptr addrspace(1)> %ps, <4 x i1> %m, <4 x bfloat> %t) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x bfloat> @llvm.masked.gather.v4bf16.v4p1(<4 x ptr addrspace(1)> %ps, i32 2, <4 x i1> %m, <4 x bfloat> %t)
  ret <4 x bfloat> %r
}

define void @unsupported_wide(ptr %base) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %ptrs = getelementptr bfloat, ptr %base, <16 x i32> zeroinitializer
  %r = call <16 x bfloat> @llvm.masked.gather.v16bf16.v16p0(<16 x ptr> %ptrs, i32 2, <16 x i1> zeroinitializer, <16 x bfloat> zeroinitializer)
  ret void
}

define i32 @unsupported_scalable() noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <vscale x 4 x bfloat> @llvm.masked.gather.nxv4bf16.nxv4p0(<vscale x 4 x ptr> zeroinitializer, i32 2, <vscale x 4 x i1> zeroinitializer, <vscale x 4 x bfloat> zeroinitializer)
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
; SKIP-DAG: Skipping VMP on unsupported_gs_no_feature: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_gs_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_gs_bf16fml_only: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_gs_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_gs_bundle: unsupported masked memory instruction
; SKIP-DAG: Skipping VMP on unsupported_gs_noreturn: unsupported masked memory instruction
; SKIP-DAG: Skipping VMP on unsupported_gs_returns_twice: unsupported masked memory instruction
; SKIP-DAG: Skipping VMP on unsupported_gs_fastcc: unsupported masked memory instruction
; SKIP-DAG: Skipping VMP on unsupported_gs_poison: unsupported masked memory instruction
; SKIP-DAG: Skipping VMP on unsupported_gs_undef: unsupported
; SKIP-DAG: Skipping VMP on unsupported_gs_as1: unsupported
; SKIP-DAG: Skipping VMP on unsupported_wide: unsupported
; SKIP-DAG: Skipping VMP on unsupported_scalable: unsupported masked memory instruction
; SKIP-DAG: Skipping VMP on unsupported_expand: unsupported masked memory instruction
; SKIP-DAG: Skipping VMP on unsupported_compress: unsupported masked memory instruction
; SKIP-NOT: Skipping VMP on protected_gather_v1:
; SKIP-NOT: Skipping VMP on protected_gather_v2:
; SKIP-NOT: Skipping VMP on protected_gather_dyn:
; SKIP-NOT: Skipping VMP on protected_gather_alltrue:
; SKIP-NOT: Skipping VMP on protected_gather_allfalse:
; SKIP-NOT: Skipping VMP on protected_gather_align8:
; SKIP-NOT: Skipping VMP on protected_gather_align1:
; SKIP-NOT: Skipping VMP on protected_scatter_dyn:
; SKIP-NOT: Skipping VMP on protected_scatter_v1:
; SKIP-NOT: Skipping VMP on protected_gather_v8:
; SKIP-NOT: Skipping VMP on protected_scatter_v8:
; SKIP-NOT: Skipping VMP on protected_special:
; SKIP-NOT: Skipping VMP on protected_last_token:
; SKIP-NOT: Skipping VMP on protected_gather_insert:

; VIRT: define <1 x bfloat> @protected_gather_v1({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.masked.gather
; VIRT-NOT: load <{{.*}}bfloat
; VIRT: br i1
; VIRT: load bfloat
; VIRT: define <2 x bfloat> @protected_gather_v2({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.masked.gather
; VIRT: br i1
; VIRT: load bfloat
; VIRT: br i1
; VIRT: load bfloat
; VIRT: define <4 x bfloat> @protected_gather_dyn({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.masked.gather
; VIRT-NOT: load <{{.*}}bfloat
; VIRT: br i1
; VIRT: load bfloat
; VIRT: br i1
; VIRT: load bfloat
; VIRT: br i1
; VIRT: load bfloat
; VIRT: br i1
; VIRT: load bfloat
; VIRT: define <4 x bfloat> @protected_gather_alltrue({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.masked.gather
; VIRT: br i1
; VIRT: load bfloat
; VIRT: define <4 x bfloat> @protected_gather_allfalse({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.masked.gather
; VIRT: br i1
; VIRT: define <4 x bfloat> @protected_gather_align8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.masked.gather
; VIRT: load bfloat, ptr {{.*}}, align 8, !nontemporal ![[NT:[0-9]+]]
; VIRT: load bfloat, ptr {{.*}}, align 8, !nontemporal ![[NT]]
; VIRT: load bfloat, ptr {{.*}}, align 8, !nontemporal ![[NT]]
; VIRT: load bfloat, ptr {{.*}}, align 8, !nontemporal ![[NT]]
; VIRT: define <4 x bfloat> @protected_gather_align1({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: load bfloat, ptr {{.*}}, align 1
; VIRT: load bfloat, ptr {{.*}}, align 1
; VIRT: define void @protected_scatter_dyn({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.masked.scatter
; VIRT-NOT: store <{{.*}}bfloat
; VIRT: br i1
; VIRT: store bfloat
; VIRT: br i1
; VIRT: store bfloat
; VIRT: define void @protected_scatter_v1({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.masked.scatter
; VIRT: br i1
; VIRT: store bfloat
; VIRT: define <8 x bfloat> @protected_gather_v8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.masked.gather
; VIRT: br i1
; VIRT: load bfloat
; VIRT: define void @protected_scatter_v8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.masked.scatter
; VIRT: br i1
; VIRT: store bfloat
; VIRT: define <4 x bfloat> @protected_special({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.masked.gather
; VIRT: br i1
; VIRT: load bfloat
; VIRT: define <4 x bfloat> @protected_last_token({{.*}} #[[PROTLAST:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.masked.gather
; VIRT: br i1
; VIRT: load bfloat
; VIRT: define <4 x bfloat> @protected_gather_insert({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.masked.gather
; VIRT: br i1
; VIRT: load bfloat
; VIRT: define {{.*}} @unsupported_gs_no_feature({{.*}} #[[UNSUPFEAT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_gs_disabled({{.*}} #[[UNSUPDIS:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_gs_bf16fml_only({{.*}} #[[UNSUPFML:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_gs_musttail({{.*}} #[[UNSUPMUST:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_gs_bundle({{.*}} #[[UNSUPMSK:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_gs_noreturn({{.*}} #[[UNSUPMSK]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_gs_returns_twice({{.*}} #[[UNSUPMSK]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_gs_fastcc({{.*}} #[[UNSUPMSK]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_gs_poison({{.*}} #[[UNSUPMSK]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_gs_undef({{.*}} #[[UNSUPMSK]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_gs_as1({{.*}} #[[UNSUPMSK]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_wide({{.*}} #[[UNSUPMSK]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_scalable({{.*}} #[[UNSUPMSK]] {
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
