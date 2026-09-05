; Restricted AArch64 NEON multi-vector lane loads via CallDescriptor:
;   ld2lane / ld3lane / ld4lane
; Exact IntrinsicsAArch64.td AdvSIMD_NVec_Load_Lane_Intrinsic:
;   {vec x N} (vec x N, i64 lane, anyptr)
; Vector types are the practical AArch64 ISel overloads for integer
; i8/i16/i32/i64 and f32/f64 only (64/128-bit).  half stays out.
; Lane is i64 ConstantInt in [0, Nelt).  Pointer is AS0.
; Call site must be CallingConv::C and non-vararg.
; Every field 0..N-1 must be extracted exactly once; the tuple is
; exploded into independent vector VRegs.  Never the 1..16-byte
; flat-aggregate frame ({<8 x i8>,<8 x i8>} and {<4 x i16>,<4 x i16>}
; are 16 bytes and would otherwise match).  Whole-tuple
; phi/select/store/ret/insertvalue stay out.
; No dedicated VM opcode.  No extra +neon / +fullfp16 gate.
; ld1lane lives in vmp-aarch64-neon-ldst1lane-semantic.ll.
; Well-formed ld2r/ld3r/ld4r live in vmp-aarch64-neon-ldr-semantic.ll.
; SVE, arm.neon.vld*lane, dynamic/OOB/negative lanes, half, bfloat,
; unused/dup extracts, non-AS0, fastcc, musttail, and operand bundles
; stay out.
;
; Host x86_64 cannot select these AArch64 intrinsics.  Do not rewrite
; them for host and do not run lli.  Validate with FileCheck + AArch64
; object generation on the live main-reachable subset.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.ll -o %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.ll -o %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.s7.ll -o %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.s7.ll -o %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare { <16 x i8>, <16 x i8> } @llvm.aarch64.neon.ld2lane.v16i8.p0(<16 x i8>, <16 x i8>, i64, ptr)
declare { <8 x i8>, <8 x i8> } @llvm.aarch64.neon.ld2lane.v8i8.p0(<8 x i8>, <8 x i8>, i64, ptr)
declare { <4 x i16>, <4 x i16> } @llvm.aarch64.neon.ld2lane.v4i16.p0(<4 x i16>, <4 x i16>, i64, ptr)
declare { <4 x i32>, <4 x i32>, <4 x i32> } @llvm.aarch64.neon.ld3lane.v4i32.p0(<4 x i32>, <4 x i32>, <4 x i32>, i64, ptr)
declare { <2 x float>, <2 x float>, <2 x float> } @llvm.aarch64.neon.ld3lane.v2f32.p0(<2 x float>, <2 x float>, <2 x float>, i64, ptr)
declare { <2 x i64>, <2 x i64>, <2 x i64>, <2 x i64> } @llvm.aarch64.neon.ld4lane.v2i64.p0(<2 x i64>, <2 x i64>, <2 x i64>, <2 x i64>, i64, ptr)
declare { <4 x half>, <4 x half> } @llvm.aarch64.neon.ld2lane.v4f16.p0(<4 x half>, <4 x half>, i64, ptr)
declare { <4 x bfloat>, <4 x bfloat> } @llvm.aarch64.neon.ld2lane.v4bf16.p0(<4 x bfloat>, <4 x bfloat>, i64, ptr)
declare { <16 x i8>, <16 x i8> } @llvm.arm.neon.vld2lane.v16i8.p0(ptr, <16 x i8>, <16 x i8>, i32, i32)
declare { <4 x i8>, <4 x i8> } @llvm.aarch64.neon.ld2lane.v4i8.p0(<4 x i8>, <4 x i8>, i64, ptr)

@sink = global [128 x i8] zeroinitializer, align 16

define <16 x i8> @protected_ld2lane_v16(ptr %p, <16 x i8> %a, <16 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <16 x i8>, <16 x i8> } @llvm.aarch64.neon.ld2lane.v16i8.p0(<16 x i8> %a, <16 x i8> %b, i64 3, ptr %p)
  %x = extractvalue { <16 x i8>, <16 x i8> } %t, 0
  %y = extractvalue { <16 x i8>, <16 x i8> } %t, 1
  %r = xor <16 x i8> %x, %y
  ret <16 x i8> %r
}

; 16-byte {<8 x i8>,<8 x i8>} must explode into vector VRegs.
define <8 x i8> @protected_ld2lane_v8(ptr %p, <8 x i8> %a, <8 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <8 x i8>, <8 x i8> } @llvm.aarch64.neon.ld2lane.v8i8.p0(<8 x i8> %a, <8 x i8> %b, i64 1, ptr %p)
  %x = extractvalue { <8 x i8>, <8 x i8> } %t, 0
  %y = extractvalue { <8 x i8>, <8 x i8> } %t, 1
  %r = xor <8 x i8> %x, %y
  ret <8 x i8> %r
}

; 16-byte {<4 x i16>,<4 x i16>} must explode the same way as v8i8.
define <4 x i16> @protected_ld2lane_v4i16(ptr %p, <4 x i16> %a, <4 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <4 x i16>, <4 x i16> } @llvm.aarch64.neon.ld2lane.v4i16.p0(<4 x i16> %a, <4 x i16> %b, i64 3, ptr %p)
  %x = extractvalue { <4 x i16>, <4 x i16> } %t, 0
  %y = extractvalue { <4 x i16>, <4 x i16> } %t, 1
  %r = xor <4 x i16> %x, %y
  ret <4 x i16> %r
}

define <4 x i32> @protected_ld3lane_v4i32(ptr %p, <4 x i32> %a, <4 x i32> %b, <4 x i32> %c) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <4 x i32>, <4 x i32>, <4 x i32> } @llvm.aarch64.neon.ld3lane.v4i32.p0(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c, i64 2, ptr %p)
  %x = extractvalue { <4 x i32>, <4 x i32>, <4 x i32> } %t, 0
  %y = extractvalue { <4 x i32>, <4 x i32>, <4 x i32> } %t, 1
  %z = extractvalue { <4 x i32>, <4 x i32>, <4 x i32> } %t, 2
  %xy = xor <4 x i32> %x, %y
  %r = xor <4 x i32> %xy, %z
  ret <4 x i32> %r
}

define <2 x float> @protected_ld3lane_v2f32(ptr %p, <2 x float> %a, <2 x float> %b, <2 x float> %c) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <2 x float>, <2 x float>, <2 x float> } @llvm.aarch64.neon.ld3lane.v2f32.p0(<2 x float> %a, <2 x float> %b, <2 x float> %c, i64 0, ptr %p)
  %x = extractvalue { <2 x float>, <2 x float>, <2 x float> } %t, 0
  %y = extractvalue { <2 x float>, <2 x float>, <2 x float> } %t, 1
  %z = extractvalue { <2 x float>, <2 x float>, <2 x float> } %t, 2
  %xy = fadd <2 x float> %x, %y
  %r = fadd <2 x float> %xy, %z
  ret <2 x float> %r
}

define <2 x i64> @protected_ld4lane_v2i64(ptr %p, <2 x i64> %a, <2 x i64> %b, <2 x i64> %c, <2 x i64> %d) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <2 x i64>, <2 x i64>, <2 x i64>, <2 x i64> } @llvm.aarch64.neon.ld4lane.v2i64.p0(<2 x i64> %a, <2 x i64> %b, <2 x i64> %c, <2 x i64> %d, i64 1, ptr %p)
  %x = extractvalue { <2 x i64>, <2 x i64>, <2 x i64>, <2 x i64> } %t, 0
  %y = extractvalue { <2 x i64>, <2 x i64>, <2 x i64>, <2 x i64> } %t, 1
  %z = extractvalue { <2 x i64>, <2 x i64>, <2 x i64>, <2 x i64> } %t, 2
  %w = extractvalue { <2 x i64>, <2 x i64>, <2 x i64>, <2 x i64> } %t, 3
  %xy = xor <2 x i64> %x, %y
  %zw = xor <2 x i64> %z, %w
  %r = xor <2 x i64> %xy, %zw
  ret <2 x i64> %r
}

; ----- negatives: selected, not virtualized -----

define void @unsupported_ldlane_unused(ptr %p, <16 x i8> %a, <16 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <16 x i8>, <16 x i8> } @llvm.aarch64.neon.ld2lane.v16i8.p0(<16 x i8> %a, <16 x i8> %b, i64 0, ptr %p)
  ret void
}

define <16 x i8> @unsupported_ldlane_dup(ptr %p, <16 x i8> %a, <16 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <16 x i8>, <16 x i8> } @llvm.aarch64.neon.ld2lane.v16i8.p0(<16 x i8> %a, <16 x i8> %b, i64 0, ptr %p)
  %x = extractvalue { <16 x i8>, <16 x i8> } %t, 0
  %y = extractvalue { <16 x i8>, <16 x i8> } %t, 0
  %r = xor <16 x i8> %x, %y
  ret <16 x i8> %r
}

define <8 x i8> @unsupported_ldlane_select(ptr %p, <8 x i8> %a, <8 x i8> %b, i1 %c) noinline optnone {
entry:
  call void @hikari_vmp()
  %t0 = call { <8 x i8>, <8 x i8> } @llvm.aarch64.neon.ld2lane.v8i8.p0(<8 x i8> %a, <8 x i8> %b, i64 0, ptr %p)
  %t1 = call { <8 x i8>, <8 x i8> } @llvm.aarch64.neon.ld2lane.v8i8.p0(<8 x i8> %a, <8 x i8> %b, i64 1, ptr %p)
  %s = select i1 %c, { <8 x i8>, <8 x i8> } %t0, { <8 x i8>, <8 x i8> } %t1
  %x = extractvalue { <8 x i8>, <8 x i8> } %s, 0
  ret <8 x i8> %x
}

define <8 x i8> @unsupported_ldlane_phi(ptr %p, <8 x i8> %a, <8 x i8> %b, i1 %c) noinline optnone {
entry:
  call void @hikari_vmp()
  br i1 %c, label %left, label %right
left:
  %t0 = call { <8 x i8>, <8 x i8> } @llvm.aarch64.neon.ld2lane.v8i8.p0(<8 x i8> %a, <8 x i8> %b, i64 0, ptr %p)
  br label %join
right:
  %t1 = call { <8 x i8>, <8 x i8> } @llvm.aarch64.neon.ld2lane.v8i8.p0(<8 x i8> %a, <8 x i8> %b, i64 1, ptr %p)
  br label %join
join:
  %t = phi { <8 x i8>, <8 x i8> } [ %t0, %left ], [ %t1, %right ]
  %x = extractvalue { <8 x i8>, <8 x i8> } %t, 0
  ret <8 x i8> %x
}

define <8 x i8> @unsupported_ldlane_insertvalue(ptr %p, <8 x i8> %a, <8 x i8> %b, <8 x i8> %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <8 x i8>, <8 x i8> } @llvm.aarch64.neon.ld2lane.v8i8.p0(<8 x i8> %a, <8 x i8> %b, i64 0, ptr %p)
  %e0 = extractvalue { <8 x i8>, <8 x i8> } %t, 0
  %e1 = extractvalue { <8 x i8>, <8 x i8> } %t, 1
  %u = insertvalue { <8 x i8>, <8 x i8> } %t, <8 x i8> %x, 0
  %r = extractvalue { <8 x i8>, <8 x i8> } %u, 0
  %ab = xor <8 x i8> %e0, %e1
  %out = xor <8 x i8> %ab, %r
  ret <8 x i8> %out
}

define void @unsupported_ldlane_store(ptr %p, ptr %q, <8 x i8> %a, <8 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <8 x i8>, <8 x i8> } @llvm.aarch64.neon.ld2lane.v8i8.p0(<8 x i8> %a, <8 x i8> %b, i64 0, ptr %p)
  store { <8 x i8>, <8 x i8> } %t, ptr %q, align 8
  ret void
}

define <16 x i8> @unsupported_ldlane_partial(ptr %p, <16 x i8> %a, <16 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <16 x i8>, <16 x i8> } @llvm.aarch64.neon.ld2lane.v16i8.p0(<16 x i8> %a, <16 x i8> %b, i64 0, ptr %p)
  %x = extractvalue { <16 x i8>, <16 x i8> } %t, 0
  ret <16 x i8> %x
}

define { <8 x i8>, <8 x i8> } @unsupported_ldlane_tuple_v8(ptr %p, <8 x i8> %a, <8 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <8 x i8>, <8 x i8> } @llvm.aarch64.neon.ld2lane.v8i8.p0(<8 x i8> %a, <8 x i8> %b, i64 0, ptr %p)
  ret { <8 x i8>, <8 x i8> } %t
}

define { <16 x i8>, <16 x i8> } @unsupported_ldlane_tuple_v16(ptr %p, <16 x i8> %a, <16 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <16 x i8>, <16 x i8> } @llvm.aarch64.neon.ld2lane.v16i8.p0(<16 x i8> %a, <16 x i8> %b, i64 0, ptr %p)
  ret { <16 x i8>, <16 x i8> } %t
}

define <16 x i8> @unsupported_ldlane_dyn(ptr %p, <16 x i8> %a, <16 x i8> %b, i64 %lane) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <16 x i8>, <16 x i8> } @llvm.aarch64.neon.ld2lane.v16i8.p0(<16 x i8> %a, <16 x i8> %b, i64 %lane, ptr %p)
  %x = extractvalue { <16 x i8>, <16 x i8> } %t, 0
  %y = extractvalue { <16 x i8>, <16 x i8> } %t, 1
  %r = xor <16 x i8> %x, %y
  ret <16 x i8> %r
}

define <16 x i8> @unsupported_ldlane_oob(ptr %p, <16 x i8> %a, <16 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <16 x i8>, <16 x i8> } @llvm.aarch64.neon.ld2lane.v16i8.p0(<16 x i8> %a, <16 x i8> %b, i64 16, ptr %p)
  %x = extractvalue { <16 x i8>, <16 x i8> } %t, 0
  %y = extractvalue { <16 x i8>, <16 x i8> } %t, 1
  %r = xor <16 x i8> %x, %y
  ret <16 x i8> %r
}

define <16 x i8> @unsupported_ldlane_neg(ptr %p, <16 x i8> %a, <16 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <16 x i8>, <16 x i8> } @llvm.aarch64.neon.ld2lane.v16i8.p0(<16 x i8> %a, <16 x i8> %b, i64 -1, ptr %p)
  %x = extractvalue { <16 x i8>, <16 x i8> } %t, 0
  %y = extractvalue { <16 x i8>, <16 x i8> } %t, 1
  %r = xor <16 x i8> %x, %y
  ret <16 x i8> %r
}

define <4 x half> @unsupported_ldlane_half(ptr %p, <4 x half> %a, <4 x half> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <4 x half>, <4 x half> } @llvm.aarch64.neon.ld2lane.v4f16.p0(<4 x half> %a, <4 x half> %b, i64 0, ptr %p)
  %x = extractvalue { <4 x half>, <4 x half> } %t, 0
  %y = extractvalue { <4 x half>, <4 x half> } %t, 1
  %r = fadd <4 x half> %x, %y
  ret <4 x half> %r
}

define <4 x i8> @unsupported_ldlane_v4i8(ptr %p, <4 x i8> %a, <4 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <4 x i8>, <4 x i8> } @llvm.aarch64.neon.ld2lane.v4i8.p0(<4 x i8> %a, <4 x i8> %b, i64 0, ptr %p)
  %x = extractvalue { <4 x i8>, <4 x i8> } %t, 0
  %y = extractvalue { <4 x i8>, <4 x i8> } %t, 1
  %r = xor <4 x i8> %x, %y
  ret <4 x i8> %r
}

define void @unsupported_ldlane_bfloat(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <4 x bfloat>, <4 x bfloat> } @llvm.aarch64.neon.ld2lane.v4bf16.p0(<4 x bfloat> zeroinitializer, <4 x bfloat> zeroinitializer, i64 0, ptr %p)
  %x = extractvalue { <4 x bfloat>, <4 x bfloat> } %t, 0
  %y = extractvalue { <4 x bfloat>, <4 x bfloat> } %t, 1
  ret void
}

define <16 x i8> @unsupported_arm_vld2lane(ptr %p, <16 x i8> %a, <16 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <16 x i8>, <16 x i8> } @llvm.arm.neon.vld2lane.v16i8.p0(ptr %p, <16 x i8> %a, <16 x i8> %b, i32 0, i32 1)
  %x = extractvalue { <16 x i8>, <16 x i8> } %t, 0
  %y = extractvalue { <16 x i8>, <16 x i8> } %t, 1
  %r = xor <16 x i8> %x, %y
  ret <16 x i8> %r
}

define <16 x i8> @unsupported_ldlane_as1(ptr addrspace(1) %p, <16 x i8> %a, <16 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <16 x i8>, <16 x i8> } @llvm.aarch64.neon.ld2lane.v16i8.p1(<16 x i8> %a, <16 x i8> %b, i64 0, ptr addrspace(1) %p)
  %x = extractvalue { <16 x i8>, <16 x i8> } %t, 0
  %y = extractvalue { <16 x i8>, <16 x i8> } %t, 1
  %r = xor <16 x i8> %x, %y
  ret <16 x i8> %r
}

declare { <16 x i8>, <16 x i8> } @llvm.aarch64.neon.ld2lane.v16i8.p1(<16 x i8>, <16 x i8>, i64, ptr addrspace(1))

define <16 x i8> @unsupported_ldlane_fastcc(ptr %p, <16 x i8> %a, <16 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call fastcc { <16 x i8>, <16 x i8> } @llvm.aarch64.neon.ld2lane.v16i8.p0(<16 x i8> %a, <16 x i8> %b, i64 0, ptr %p)
  %x = extractvalue { <16 x i8>, <16 x i8> } %t, 0
  %y = extractvalue { <16 x i8>, <16 x i8> } %t, 1
  %r = xor <16 x i8> %x, %y
  ret <16 x i8> %r
}

define { <8 x i8>, <8 x i8> } @unsupported_ldlane_musttail(ptr %p, <8 x i8> %a, <8 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = musttail call { <8 x i8>, <8 x i8> } @llvm.aarch64.neon.ld2lane.v8i8.p0(<8 x i8> %a, <8 x i8> %b, i64 0, ptr %p)
  ret { <8 x i8>, <8 x i8> } %t
}

define <16 x i8> @unsupported_ldlane_bundle(ptr %p, <16 x i8> %a, <16 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <16 x i8>, <16 x i8> } @llvm.aarch64.neon.ld2lane.v16i8.p0(<16 x i8> %a, <16 x i8> %b, i64 0, ptr %p) [ "deopt"(i32 0) ]
  %x = extractvalue { <16 x i8>, <16 x i8> } %t, 0
  %y = extractvalue { <16 x i8>, <16 x i8> } %t, 1
  %r = xor <16 x i8> %x, %y
  ret <16 x i8> %r
}

define i32 @main() {
entry:
  %p = getelementptr inbounds [128 x i8], ptr @sink, i64 0, i64 0
  %a16 = load volatile <16 x i8>, ptr %p, align 16
  %r16 = call <16 x i8> @protected_ld2lane_v16(ptr %p, <16 x i8> %a16, <16 x i8> %a16)
  store volatile <16 x i8> %r16, ptr %p, align 16
  %a8 = load volatile <8 x i8>, ptr %p, align 8
  %r8 = call <8 x i8> @protected_ld2lane_v8(ptr %p, <8 x i8> %a8, <8 x i8> %a8)
  store volatile <8 x i8> %r8, ptr %p, align 8
  %a16s = load volatile <4 x i16>, ptr %p, align 8
  %r16s = call <4 x i16> @protected_ld2lane_v4i16(ptr %p, <4 x i16> %a16s, <4 x i16> %a16s)
  store volatile <4 x i16> %r16s, ptr %p, align 8
  %ai = load volatile <4 x i32>, ptr %p, align 16
  %ri = call <4 x i32> @protected_ld3lane_v4i32(ptr %p, <4 x i32> %ai, <4 x i32> %ai, <4 x i32> %ai)
  store volatile <4 x i32> %ri, ptr %p, align 16
  %af = load volatile <2 x float>, ptr %p, align 8
  %rf = call <2 x float> @protected_ld3lane_v2f32(ptr %p, <2 x float> %af, <2 x float> %af, <2 x float> %af)
  store volatile <2 x float> %rf, ptr %p, align 8
  %al = load volatile <2 x i64>, ptr %p, align 16
  %rl = call <2 x i64> @protected_ld4lane_v2i64(ptr %p, <2 x i64> %al, <2 x i64> %al, <2 x i64> %al, <2 x i64> %al)
  store volatile <2 x i64> %rl, ptr %p, align 16
  ret i32 0
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_ldlane_unused: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_ldlane_dup: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_ldlane_select: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_ldlane_phi: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_ldlane_insertvalue: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_ldlane_store: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_ldlane_partial: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_ldlane_tuple_v8: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_ldlane_tuple_v16: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_ldlane_dyn: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_ldlane_oob: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_ldlane_neg: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_ldlane_half: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_ldlane_v4i8: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_ldlane_bfloat: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_arm_vld2lane: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_ldlane_as1: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_ldlane_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_ldlane_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_ldlane_bundle: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_ld2lane_v16:
; SKIP-NOT: Skipping VMP on protected_ld2lane_v8:
; SKIP-NOT: Skipping VMP on protected_ld2lane_v4i16:
; SKIP-NOT: Skipping VMP on protected_ld3lane_v4i32:
; SKIP-NOT: Skipping VMP on protected_ld3lane_v2f32:
; SKIP-NOT: Skipping VMP on protected_ld4lane_v2i64:

; VIRT: define <16 x i8> @protected_ld2lane_v16({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call { <16 x i8>, <16 x i8> } @llvm.aarch64.neon.ld2lane.v16i8.p0({{.*}}i64 3,
; VIRT: extractvalue { <16 x i8>, <16 x i8> }
; VIRT: extractvalue { <16 x i8>, <16 x i8> }
; VIRT: define <8 x i8> @protected_ld2lane_v8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call { <8 x i8>, <8 x i8> } @llvm.aarch64.neon.ld2lane.v8i8.p0({{.*}}i64 1,
; VIRT: extractvalue { <8 x i8>, <8 x i8> } {{.*}}, 0
; VIRT: extractvalue { <8 x i8>, <8 x i8> } {{.*}}, 1
; VIRT: define <4 x i16> @protected_ld2lane_v4i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call { <4 x i16>, <4 x i16> } @llvm.aarch64.neon.ld2lane.v4i16.p0({{.*}}i64 3,
; VIRT: extractvalue { <4 x i16>, <4 x i16> } {{.*}}, 0
; VIRT: extractvalue { <4 x i16>, <4 x i16> } {{.*}}, 1
; VIRT: define <4 x i32> @protected_ld3lane_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call { <4 x i32>, <4 x i32>, <4 x i32> } @llvm.aarch64.neon.ld3lane.v4i32.p0({{.*}}i64 2,
; VIRT: extractvalue { <4 x i32>, <4 x i32>, <4 x i32> }
; VIRT: define <2 x float> @protected_ld3lane_v2f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call { <2 x float>, <2 x float>, <2 x float> } @llvm.aarch64.neon.ld3lane.v2f32.p0({{.*}}i64 0,
; VIRT: extractvalue { <2 x float>, <2 x float>, <2 x float> }
; VIRT: define <2 x i64> @protected_ld4lane_v2i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call { <2 x i64>, <2 x i64>, <2 x i64>, <2 x i64> } @llvm.aarch64.neon.ld4lane.v2i64.p0({{.*}}i64 1,
; VIRT: extractvalue { <2 x i64>, <2 x i64>, <2 x i64>, <2 x i64> }
; VIRT: define {{.*}} @unsupported_ldlane_unused({{.*}} #[[UNSUPATTR:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ldlane_dup({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ldlane_select({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ldlane_phi({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ldlane_insertvalue({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ldlane_store({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ldlane_partial({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ldlane_tuple_v8({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ldlane_tuple_v16({{.*}} #[[UNSUP_RET:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ldlane_dyn({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ldlane_oob({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ldlane_neg({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ldlane_half({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ldlane_v4i8({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ldlane_bfloat({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_arm_vld2lane({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ldlane_as1({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ldlane_fastcc({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ldlane_musttail({{.*}} #[[UNSUP_MT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call { <8 x i8>, <8 x i8> } @llvm.aarch64.neon.ld2lane.v8i8.p0(
; VIRT: define {{.*}} @unsupported_ldlane_bundle({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call { <16 x i8>, <16 x i8> } @llvm.aarch64.neon.ld2lane.v16i8.p0({{.*}}[ "deopt"(i32 0) ]
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_MT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_RET]] = { {{.*}}"hikari.vmp.virtualized"
