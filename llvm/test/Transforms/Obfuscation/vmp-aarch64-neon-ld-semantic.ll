; Restricted AArch64 NEON multi-vector loads via CallDescriptor:
;   ld1x2/ld1x3/ld1x4 and ld2/ld3/ld4
; Exact IntrinsicsAArch64.td AdvSIMD_NVec_Load_Intrinsic:
;   {anyvector x N} (anyptr-to-match)
; Vector types are the practical AArch64 ISel overloads for integer
; i8/i16/i32/i64 and f32/f64 only (64/128-bit).  half stays out.
; Pointer is AS0.  Call site must be CallingConv::C and non-vararg.
; Every field 0..N-1 must be extracted exactly once; the tuple is
; exploded into independent vector VRegs.  Never the 1..16-byte
; flat-aggregate frame ({<8 x i8>,<8 x i8>} is 16 bytes and would
; otherwise match).  Whole-tuple phi/select/store/ret/insertvalue stay out.
; No dedicated VM opcode.  No extra +neon / +fullfp16 gate.
; SVE, arm.neon.vld*, half, bfloat, non-AS0, fastcc, musttail,
; operand bundles, partial/duplicate extracts, and unused loads stay
; out.  A well-formed ld2/3/4lane lives in
; vmp-aarch64-neon-ldlane-semantic.ll; the ld2lane case here is a
; partial-extract negative only.  Well-formed ld2r/ld3r/ld4r live in
; vmp-aarch64-neon-ldr-semantic.ll.
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
declare { <16 x i8>, <16 x i8> } @llvm.aarch64.neon.ld1x2.v16i8.p0(ptr)
declare { <8 x i8>, <8 x i8> } @llvm.aarch64.neon.ld1x2.v8i8.p0(ptr)
declare { <4 x i16>, <4 x i16> } @llvm.aarch64.neon.ld2.v4i16.p0(ptr)
declare { <4 x i32>, <4 x i32>, <4 x i32> } @llvm.aarch64.neon.ld1x3.v4i32.p0(ptr)
declare { <8 x i16>, <8 x i16>, <8 x i16>, <8 x i16> } @llvm.aarch64.neon.ld1x4.v8i16.p0(ptr)
declare { <4 x half>, <4 x half>, <4 x half>, <4 x half> } @llvm.aarch64.neon.ld1x4.v4f16.p0(ptr)
declare { <16 x i8>, <16 x i8> } @llvm.aarch64.neon.ld2.v16i8.p0(ptr)
declare { <2 x float>, <2 x float>, <2 x float> } @llvm.aarch64.neon.ld3.v2f32.p0(ptr)
declare { <2 x i64>, <2 x i64>, <2 x i64>, <2 x i64> } @llvm.aarch64.neon.ld4.v2i64.p0(ptr)
declare { <4 x bfloat>, <4 x bfloat> } @llvm.aarch64.neon.ld2.v4bf16.p0(ptr)
declare { <16 x i8>, <16 x i8> } @llvm.aarch64.neon.ld2lane.v16i8.p0(<16 x i8>, <16 x i8>, i64, ptr)
declare { <4 x i8>, <4 x i8> } @llvm.aarch64.neon.ld1x2.v4i8.p0(ptr)
declare { <16 x i8>, <16 x i8> } @llvm.arm.neon.vld2.v16i8.p0(ptr, i32)

@sink = global [128 x i8] zeroinitializer, align 16

define <16 x i8> @protected_ld1x2_v16(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <16 x i8>, <16 x i8> } @llvm.aarch64.neon.ld1x2.v16i8.p0(ptr %p)
  %a = extractvalue { <16 x i8>, <16 x i8> } %t, 0
  %b = extractvalue { <16 x i8>, <16 x i8> } %t, 1
  %r = xor <16 x i8> %a, %b
  ret <16 x i8> %r
}

; 16-byte {<8 x i8>,<8 x i8>} must explode into vector VRegs, not the
; ordinary flat-aggregate frame.  Both fields are extracted exactly once.
define <8 x i8> @protected_ld1x2_v8(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <8 x i8>, <8 x i8> } @llvm.aarch64.neon.ld1x2.v8i8.p0(ptr %p)
  %a = extractvalue { <8 x i8>, <8 x i8> } %t, 0
  %b = extractvalue { <8 x i8>, <8 x i8> } %t, 1
  %r = xor <8 x i8> %a, %b
  ret <8 x i8> %r
}

; 16-byte {<4 x i16>,<4 x i16>} must explode the same way as v8i8.
define <4 x i16> @protected_ld2_v4i16(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <4 x i16>, <4 x i16> } @llvm.aarch64.neon.ld2.v4i16.p0(ptr %p)
  %a = extractvalue { <4 x i16>, <4 x i16> } %t, 0
  %b = extractvalue { <4 x i16>, <4 x i16> } %t, 1
  %r = xor <4 x i16> %a, %b
  ret <4 x i16> %r
}

define <4 x i32> @protected_ld1x3_v4i32(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <4 x i32>, <4 x i32>, <4 x i32> } @llvm.aarch64.neon.ld1x3.v4i32.p0(ptr %p)
  %a = extractvalue { <4 x i32>, <4 x i32>, <4 x i32> } %t, 0
  %b = extractvalue { <4 x i32>, <4 x i32>, <4 x i32> } %t, 1
  %c = extractvalue { <4 x i32>, <4 x i32>, <4 x i32> } %t, 2
  %ab = xor <4 x i32> %a, %b
  %r = xor <4 x i32> %ab, %c
  ret <4 x i32> %r
}

define <8 x i16> @protected_ld1x4_v8i16(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <8 x i16>, <8 x i16>, <8 x i16>, <8 x i16> } @llvm.aarch64.neon.ld1x4.v8i16.p0(ptr %p)
  %a = extractvalue { <8 x i16>, <8 x i16>, <8 x i16>, <8 x i16> } %t, 0
  %b = extractvalue { <8 x i16>, <8 x i16>, <8 x i16>, <8 x i16> } %t, 1
  %c = extractvalue { <8 x i16>, <8 x i16>, <8 x i16>, <8 x i16> } %t, 2
  %d = extractvalue { <8 x i16>, <8 x i16>, <8 x i16>, <8 x i16> } %t, 3
  %ab = xor <8 x i16> %a, %b
  %cd = xor <8 x i16> %c, %d
  %r = xor <8 x i16> %ab, %cd
  ret <8 x i16> %r
}

define <16 x i8> @protected_ld2_v16(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <16 x i8>, <16 x i8> } @llvm.aarch64.neon.ld2.v16i8.p0(ptr %p)
  %a = extractvalue { <16 x i8>, <16 x i8> } %t, 0
  %b = extractvalue { <16 x i8>, <16 x i8> } %t, 1
  %r = xor <16 x i8> %a, %b
  ret <16 x i8> %r
}

define <2 x float> @protected_ld3_v2f32(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <2 x float>, <2 x float>, <2 x float> } @llvm.aarch64.neon.ld3.v2f32.p0(ptr %p)
  %a = extractvalue { <2 x float>, <2 x float>, <2 x float> } %t, 0
  %b = extractvalue { <2 x float>, <2 x float>, <2 x float> } %t, 1
  %c = extractvalue { <2 x float>, <2 x float>, <2 x float> } %t, 2
  %ab = fadd <2 x float> %a, %b
  %r = fadd <2 x float> %ab, %c
  ret <2 x float> %r
}

define <2 x i64> @protected_ld4_v2i64(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <2 x i64>, <2 x i64>, <2 x i64>, <2 x i64> } @llvm.aarch64.neon.ld4.v2i64.p0(ptr %p)
  %a = extractvalue { <2 x i64>, <2 x i64>, <2 x i64>, <2 x i64> } %t, 0
  %b = extractvalue { <2 x i64>, <2 x i64>, <2 x i64>, <2 x i64> } %t, 1
  %c = extractvalue { <2 x i64>, <2 x i64>, <2 x i64>, <2 x i64> } %t, 2
  %d = extractvalue { <2 x i64>, <2 x i64>, <2 x i64>, <2 x i64> } %t, 3
  %ab = xor <2 x i64> %a, %b
  %cd = xor <2 x i64> %c, %d
  %r = xor <2 x i64> %ab, %cd
  ret <2 x i64> %r
}

; ----- negatives: selected, not virtualized -----

define void @unsupported_ld_bfloat(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <4 x bfloat>, <4 x bfloat> } @llvm.aarch64.neon.ld2.v4bf16.p0(ptr %p)
  %a = extractvalue { <4 x bfloat>, <4 x bfloat> } %t, 0
  %b = extractvalue { <4 x bfloat>, <4 x bfloat> } %t, 1
  ret void
}

define void @unsupported_ld_unused(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <16 x i8>, <16 x i8> } @llvm.aarch64.neon.ld1x2.v16i8.p0(ptr %p)
  ret void
}

define <16 x i8> @unsupported_ld_dup_extract(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <16 x i8>, <16 x i8> } @llvm.aarch64.neon.ld1x2.v16i8.p0(ptr %p)
  %a = extractvalue { <16 x i8>, <16 x i8> } %t, 0
  %b = extractvalue { <16 x i8>, <16 x i8> } %t, 0
  %r = xor <16 x i8> %a, %b
  ret <16 x i8> %r
}

define <8 x i8> @unsupported_ld_select_tuple(ptr %p, i1 %c) noinline optnone {
entry:
  call void @hikari_vmp()
  %t0 = call { <8 x i8>, <8 x i8> } @llvm.aarch64.neon.ld1x2.v8i8.p0(ptr %p)
  %t1 = call { <8 x i8>, <8 x i8> } @llvm.aarch64.neon.ld1x2.v8i8.p0(ptr %p)
  %s = select i1 %c, { <8 x i8>, <8 x i8> } %t0, { <8 x i8>, <8 x i8> } %t1
  %a = extractvalue { <8 x i8>, <8 x i8> } %s, 0
  ret <8 x i8> %a
}

define <16 x i8> @unsupported_ld_partial_extract(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <16 x i8>, <16 x i8> } @llvm.aarch64.neon.ld1x2.v16i8.p0(ptr %p)
  %a = extractvalue { <16 x i8>, <16 x i8> } %t, 0
  ret <16 x i8> %a
}

; 16-byte pair with only one extract must not take the aggregate frame
; or the "at least one extract" explode path.
define <8 x i8> @unsupported_ld_partial_extract_v8(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <8 x i8>, <8 x i8> } @llvm.aarch64.neon.ld1x2.v8i8.p0(ptr %p)
  %a = extractvalue { <8 x i8>, <8 x i8> } %t, 0
  ret <8 x i8> %a
}

define <8 x i8> @unsupported_ld_phi_tuple(ptr %p, i1 %c) noinline optnone {
entry:
  call void @hikari_vmp()
  br i1 %c, label %left, label %right
left:
  %t0 = call { <8 x i8>, <8 x i8> } @llvm.aarch64.neon.ld1x2.v8i8.p0(ptr %p)
  br label %join
right:
  %t1 = call { <8 x i8>, <8 x i8> } @llvm.aarch64.neon.ld1x2.v8i8.p0(ptr %p)
  br label %join
join:
  %t = phi { <8 x i8>, <8 x i8> } [ %t0, %left ], [ %t1, %right ]
  %a = extractvalue { <8 x i8>, <8 x i8> } %t, 0
  ret <8 x i8> %a
}

define <8 x i8> @unsupported_ld_insertvalue(ptr %p, <8 x i8> %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <8 x i8>, <8 x i8> } @llvm.aarch64.neon.ld1x2.v8i8.p0(ptr %p)
  %a = extractvalue { <8 x i8>, <8 x i8> } %t, 0
  %b = extractvalue { <8 x i8>, <8 x i8> } %t, 1
  %u = insertvalue { <8 x i8>, <8 x i8> } %t, <8 x i8> %x, 0
  %r = extractvalue { <8 x i8>, <8 x i8> } %u, 0
  %ab = xor <8 x i8> %a, %b
  %out = xor <8 x i8> %ab, %r
  ret <8 x i8> %out
}

; Partial extract only.  Well-formed ld2/3/4lane is in
; vmp-aarch64-neon-ldlane-semantic.ll.
define <16 x i8> @unsupported_ld2lane(ptr %p, <16 x i8> %a, <16 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <16 x i8>, <16 x i8> } @llvm.aarch64.neon.ld2lane.v16i8.p0(<16 x i8> %a, <16 x i8> %b, i64 0, ptr %p)
  %r = extractvalue { <16 x i8>, <16 x i8> } %t, 0
  ret <16 x i8> %r
}

define <4 x half> @unsupported_ld_half(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <4 x half>, <4 x half>, <4 x half>, <4 x half> } @llvm.aarch64.neon.ld1x4.v4f16.p0(ptr %p)
  %a = extractvalue { <4 x half>, <4 x half>, <4 x half>, <4 x half> } %t, 0
  ret <4 x half> %a
}

define <4 x i8> @unsupported_ld_v4i8(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <4 x i8>, <4 x i8> } @llvm.aarch64.neon.ld1x2.v4i8.p0(ptr %p)
  %a = extractvalue { <4 x i8>, <4 x i8> } %t, 0
  ret <4 x i8> %a
}

define <16 x i8> @unsupported_ld_as1(ptr addrspace(1) %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <16 x i8>, <16 x i8> } @llvm.aarch64.neon.ld1x2.v16i8.p1(ptr addrspace(1) %p)
  %a = extractvalue { <16 x i8>, <16 x i8> } %t, 0
  ret <16 x i8> %a
}

declare { <16 x i8>, <16 x i8> } @llvm.aarch64.neon.ld1x2.v16i8.p1(ptr addrspace(1))

define <16 x i8> @unsupported_ld_fastcc(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call fastcc { <16 x i8>, <16 x i8> } @llvm.aarch64.neon.ld1x2.v16i8.p0(ptr %p)
  %a = extractvalue { <16 x i8>, <16 x i8> } %t, 0
  ret <16 x i8> %a
}

define { <8 x i8>, <8 x i8> } @unsupported_ld_musttail(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = musttail call { <8 x i8>, <8 x i8> } @llvm.aarch64.neon.ld1x2.v8i8.p0(ptr %p)
  ret { <8 x i8>, <8 x i8> } %t
}

define <16 x i8> @unsupported_ld_bundle(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <16 x i8>, <16 x i8> } @llvm.aarch64.neon.ld1x2.v16i8.p0(ptr %p) [ "deopt"(i32 0) ]
  %a = extractvalue { <16 x i8>, <16 x i8> } %t, 0
  ret <16 x i8> %a
}

define <16 x i8> @unsupported_arm_vld2(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <16 x i8>, <16 x i8> } @llvm.arm.neon.vld2.v16i8.p0(ptr %p, i32 1)
  %a = extractvalue { <16 x i8>, <16 x i8> } %t, 0
  ret <16 x i8> %a
}

; Whole 16-byte pair as a first-class aggregate: must not take the
; ordinary flat-aggregate Call / ResultIsAggregate path.
define { <8 x i8>, <8 x i8> } @unsupported_ld2_tuple_v8(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <8 x i8>, <8 x i8> } @llvm.aarch64.neon.ld1x2.v8i8.p0(ptr %p)
  ret { <8 x i8>, <8 x i8> } %t
}

; Whole 32-byte pair: must not be stuffed into the 16-byte aggregate frame.
define { <16 x i8>, <16 x i8> } @unsupported_ld2_tuple_v16(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <16 x i8>, <16 x i8> } @llvm.aarch64.neon.ld2.v16i8.p0(ptr %p)
  ret { <16 x i8>, <16 x i8> } %t
}

define void @unsupported_ld2_store_tuple(ptr %p, ptr %q) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <8 x i8>, <8 x i8> } @llvm.aarch64.neon.ld1x2.v8i8.p0(ptr %p)
  store { <8 x i8>, <8 x i8> } %t, ptr %q, align 8
  ret void
}

define i32 @main() {
entry:
  %p = getelementptr inbounds [128 x i8], ptr @sink, i64 0, i64 0
  %r16 = call <16 x i8> @protected_ld1x2_v16(ptr %p)
  store volatile <16 x i8> %r16, ptr %p, align 16
  %r8 = call <8 x i8> @protected_ld1x2_v8(ptr %p)
  store volatile <8 x i8> %r8, ptr %p, align 8
  %r16s = call <4 x i16> @protected_ld2_v4i16(ptr %p)
  store volatile <4 x i16> %r16s, ptr %p, align 8
  %ri = call <4 x i32> @protected_ld1x3_v4i32(ptr %p)
  store volatile <4 x i32> %ri, ptr %p, align 16
  %rs = call <8 x i16> @protected_ld1x4_v8i16(ptr %p)
  store volatile <8 x i16> %rs, ptr %p, align 16
  %r2 = call <16 x i8> @protected_ld2_v16(ptr %p)
  store volatile <16 x i8> %r2, ptr %p, align 16
  %rf = call <2 x float> @protected_ld3_v2f32(ptr %p)
  store volatile <2 x float> %rf, ptr %p, align 8
  %rl = call <2 x i64> @protected_ld4_v2i64(ptr %p)
  store volatile <2 x i64> %rl, ptr %p, align 16
  ret i32 0
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_ld_bfloat: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_ld_unused: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_ld_dup_extract: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_ld_select_tuple: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_ld_partial_extract: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_ld_partial_extract_v8: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_ld_phi_tuple: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_ld_insertvalue: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_ld2lane: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_ld_half: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_ld_v4i8: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_ld_as1: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_ld_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_ld_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_ld_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_arm_vld2: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_ld2_tuple_v8: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_ld2_tuple_v16: unsupported return type
; SKIP-DAG: Skipping VMP on unsupported_ld2_store_tuple: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_ld1x2_v16:
; SKIP-NOT: Skipping VMP on protected_ld1x2_v8:
; SKIP-NOT: Skipping VMP on protected_ld2_v4i16:
; SKIP-NOT: Skipping VMP on protected_ld1x3_v4i32:
; SKIP-NOT: Skipping VMP on protected_ld1x4_v8i16:
; SKIP-NOT: Skipping VMP on protected_ld2_v16:
; SKIP-NOT: Skipping VMP on protected_ld3_v2f32:
; SKIP-NOT: Skipping VMP on protected_ld4_v2i64:

; VIRT: define <16 x i8> @protected_ld1x2_v16({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call { <16 x i8>, <16 x i8> } @llvm.aarch64.neon.ld1x2.v16i8.p0(
; VIRT: extractvalue { <16 x i8>, <16 x i8> }
; VIRT: extractvalue { <16 x i8>, <16 x i8> }
; VIRT: define <8 x i8> @protected_ld1x2_v8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call { <8 x i8>, <8 x i8> } @llvm.aarch64.neon.ld1x2.v8i8.p0(
; VIRT: extractvalue { <8 x i8>, <8 x i8> } {{.*}}, 0
; VIRT: extractvalue { <8 x i8>, <8 x i8> } {{.*}}, 1
; VIRT: define <4 x i16> @protected_ld2_v4i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call { <4 x i16>, <4 x i16> } @llvm.aarch64.neon.ld2.v4i16.p0(
; VIRT: extractvalue { <4 x i16>, <4 x i16> } {{.*}}, 0
; VIRT: extractvalue { <4 x i16>, <4 x i16> } {{.*}}, 1
; VIRT: define <4 x i32> @protected_ld1x3_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call { <4 x i32>, <4 x i32>, <4 x i32> } @llvm.aarch64.neon.ld1x3.v4i32.p0(
; VIRT: extractvalue { <4 x i32>, <4 x i32>, <4 x i32> }
; VIRT: define <8 x i16> @protected_ld1x4_v8i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call { <8 x i16>, <8 x i16>, <8 x i16>, <8 x i16> } @llvm.aarch64.neon.ld1x4.v8i16.p0(
; VIRT: extractvalue { <8 x i16>, <8 x i16>, <8 x i16>, <8 x i16> }
; VIRT: define <16 x i8> @protected_ld2_v16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call { <16 x i8>, <16 x i8> } @llvm.aarch64.neon.ld2.v16i8.p0(
; VIRT: extractvalue { <16 x i8>, <16 x i8> }
; VIRT: define <2 x float> @protected_ld3_v2f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call { <2 x float>, <2 x float>, <2 x float> } @llvm.aarch64.neon.ld3.v2f32.p0(
; VIRT: extractvalue { <2 x float>, <2 x float>, <2 x float> }
; VIRT: define <2 x i64> @protected_ld4_v2i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call { <2 x i64>, <2 x i64>, <2 x i64>, <2 x i64> } @llvm.aarch64.neon.ld4.v2i64.p0(
; VIRT: extractvalue { <2 x i64>, <2 x i64>, <2 x i64>, <2 x i64> }
; VIRT: define {{.*}} @unsupported_ld_bfloat({{.*}} #[[UNSUPATTR:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ld_unused({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ld_dup_extract({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ld_select_tuple({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ld_partial_extract({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ld_partial_extract_v8({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ld_phi_tuple({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ld_insertvalue({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ld2lane({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ld_half({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ld_v4i8({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ld_as1({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ld_fastcc({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ld_musttail({{.*}} #[[UNSUP_MT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call { <8 x i8>, <8 x i8> } @llvm.aarch64.neon.ld1x2.v8i8.p0(
; VIRT: define {{.*}} @unsupported_ld_bundle({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call { <16 x i8>, <16 x i8> } @llvm.aarch64.neon.ld1x2.v16i8.p0({{.*}}[ "deopt"(i32 0) ]
; VIRT: define {{.*}} @unsupported_arm_vld2({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ld2_tuple_v8({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ld2_tuple_v16({{.*}} #[[UNSUP_RET:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ld2_store_tuple({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_MT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_RET]] = { {{.*}}"hikari.vmp.virtualized"
