; Restricted AArch64 NEON saturating integer add/sub via CallDescriptor:
;   sqadd / uqadd / sqsub / uqsub
; Exact IntrinsicsAArch64.td AdvSIMD_2IntArg_Intrinsic:
;   anyint (match, match)
; This surface further requires a practical AArch64 ISel integer
; vector: 64-bit <8 x i8>/<4 x i16>/<2 x i32> or 128-bit
; <16 x i8>/<8 x i16>/<4 x i32>/<2 x i64>.  Well-formed scalar
; i32/i64 sqadd/uqadd/sqsub/uqsub is
; vmp-aarch64-neon-scalar-satint-semantic.ll and must not stay
; here as a skip (it would virtualize).  <1 x i64>,
; half/bfloat/float, <4 x i8>, and SVE stay out.  Call site
; must be CallingConv::C and non-vararg.
; Re-emitted via CallDescriptor / vector VRegs.  No dedicated VM
; opcode.  No extra +neon / +fullfp16 gate.
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
declare <16 x i8> @llvm.aarch64.neon.sqadd.v16i8(<16 x i8>, <16 x i8>)
declare <8 x i8> @llvm.aarch64.neon.uqadd.v8i8(<8 x i8>, <8 x i8>)
declare <8 x i16> @llvm.aarch64.neon.sqadd.v8i16(<8 x i16>, <8 x i16>)
declare <4 x i32> @llvm.aarch64.neon.sqsub.v4i32(<4 x i32>, <4 x i32>)
declare <2 x i32> @llvm.aarch64.neon.uqsub.v2i32(<2 x i32>, <2 x i32>)
declare <2 x i64> @llvm.aarch64.neon.uqsub.v2i64(<2 x i64>, <2 x i64>)
declare <1 x i64> @llvm.aarch64.neon.sqadd.v1i64(<1 x i64>, <1 x i64>)
declare <4 x i8> @llvm.aarch64.neon.sqadd.v4i8(<4 x i8>, <4 x i8>)
declare <16 x i8> @llvm.aarch64.sve.sqadd.x.v16i8(<16 x i8>, <16 x i8>)

@sink = global [128 x i8] zeroinitializer, align 16

define <16 x i8> @protected_sqadd_v16i8(<16 x i8> %a, <16 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <16 x i8> @llvm.aarch64.neon.sqadd.v16i8(<16 x i8> %a, <16 x i8> %b)
  ret <16 x i8> %r
}

define <8 x i8> @protected_uqadd_v8i8(<8 x i8> %a, <8 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i8> @llvm.aarch64.neon.uqadd.v8i8(<8 x i8> %a, <8 x i8> %b)
  ret <8 x i8> %r
}

define <8 x i16> @protected_sqadd_v8i16(<8 x i16> %a, <8 x i16> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i16> @llvm.aarch64.neon.sqadd.v8i16(<8 x i16> %a, <8 x i16> %b)
  ret <8 x i16> %r
}

define <4 x i32> @protected_sqsub_v4i32(<4 x i32> %a, <4 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.aarch64.neon.sqsub.v4i32(<4 x i32> %a, <4 x i32> %b)
  ret <4 x i32> %r
}

define <2 x i32> @protected_uqsub_v2i32(<2 x i32> %a, <2 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i32> @llvm.aarch64.neon.uqsub.v2i32(<2 x i32> %a, <2 x i32> %b)
  ret <2 x i32> %r
}

define <2 x i64> @protected_uqsub_v2i64(<2 x i64> %a, <2 x i64> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <2 x i64> @llvm.aarch64.neon.uqsub.v2i64(<2 x i64> %a, <2 x i64> %b)
  ret <2 x i64> %r
}

; ----- negatives: selected, not virtualized -----

; Well-formed scalar llvm.aarch64.neon.sqadd/uqadd/sqsub/uqsub
; is vmp-aarch64-neon-scalar-satint-semantic.ll.

define <1 x i64> @unsupported_satint_v1i64(<1 x i64> %a, <1 x i64> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <1 x i64> @llvm.aarch64.neon.sqadd.v1i64(<1 x i64> %a, <1 x i64> %b)
  ret <1 x i64> %r
}

define <4 x i8> @unsupported_satint_v4i8(<4 x i8> %a, <4 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i8> @llvm.aarch64.neon.sqadd.v4i8(<4 x i8> %a, <4 x i8> %b)
  ret <4 x i8> %r
}

; Well-formed llvm.aarch64.neon.suqadd / usqadd is covered by
; vmp-aarch64-neon-suqadd-semantic.ll and must not stay here as a
; negative (it would virtualize).
; Well-formed llvm.aarch64.neon.shadd / uhadd / srhadd / urhadd is
; covered by vmp-aarch64-neon-hadd-semantic.ll and must not stay
; here as a negative (it would virtualize).

define <16 x i8> @unsupported_satint_sve(<16 x i8> %a, <16 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <16 x i8> @llvm.aarch64.sve.sqadd.x.v16i8(<16 x i8> %a, <16 x i8> %b)
  ret <16 x i8> %r
}

define <16 x i8> @unsupported_satint_fastcc(<16 x i8> %a, <16 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc <16 x i8> @llvm.aarch64.neon.sqadd.v16i8(<16 x i8> %a, <16 x i8> %b)
  ret <16 x i8> %r
}

define <16 x i8> @unsupported_satint_musttail(<16 x i8> %a, <16 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call <16 x i8> @llvm.aarch64.neon.sqadd.v16i8(<16 x i8> %a, <16 x i8> %b)
  ret <16 x i8> %r
}

define <16 x i8> @unsupported_satint_bundle(<16 x i8> %a, <16 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <16 x i8> @llvm.aarch64.neon.sqadd.v16i8(<16 x i8> %a, <16 x i8> %b) [ "deopt"(i32 0) ]
  ret <16 x i8> %r
}

define i32 @main() {
entry:
  %p = getelementptr inbounds [128 x i8], ptr @sink, i64 0, i64 0
  %a16 = load volatile <16 x i8>, ptr %p, align 16
  %r16 = call <16 x i8> @protected_sqadd_v16i8(<16 x i8> %a16, <16 x i8> %a16)
  store volatile <16 x i8> %r16, ptr %p, align 16
  %a8 = load volatile <8 x i8>, ptr %p, align 8
  %r8 = call <8 x i8> @protected_uqadd_v8i8(<8 x i8> %a8, <8 x i8> %a8)
  store volatile <8 x i8> %r8, ptr %p, align 8
  %ah = load volatile <8 x i16>, ptr %p, align 16
  %rh = call <8 x i16> @protected_sqadd_v8i16(<8 x i16> %ah, <8 x i16> %ah)
  store volatile <8 x i16> %rh, ptr %p, align 16
  %ai = load volatile <4 x i32>, ptr %p, align 16
  %ri = call <4 x i32> @protected_sqsub_v4i32(<4 x i32> %ai, <4 x i32> %ai)
  store volatile <4 x i32> %ri, ptr %p, align 16
  %as = load volatile <2 x i32>, ptr %p, align 8
  %rs = call <2 x i32> @protected_uqsub_v2i32(<2 x i32> %as, <2 x i32> %as)
  store volatile <2 x i32> %rs, ptr %p, align 8
  %al = load volatile <2 x i64>, ptr %p, align 16
  %rl = call <2 x i64> @protected_uqsub_v2i64(<2 x i64> %al, <2 x i64> %al)
  store volatile <2 x i64> %rl, ptr %p, align 16
  ret i32 0
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_satint_v1i64: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_satint_v4i8: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_satint_sve: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_satint_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_satint_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_satint_bundle: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_sqadd_v16i8:
; SKIP-NOT: Skipping VMP on protected_uqadd_v8i8:
; SKIP-NOT: Skipping VMP on protected_sqadd_v8i16:
; SKIP-NOT: Skipping VMP on protected_sqsub_v4i32:
; SKIP-NOT: Skipping VMP on protected_uqsub_v2i32:
; SKIP-NOT: Skipping VMP on protected_uqsub_v2i64:

; VIRT: define <16 x i8> @protected_sqadd_v16i8({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call <16 x i8> @llvm.aarch64.neon.sqadd.v16i8(
; VIRT: define <8 x i8> @protected_uqadd_v8i8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x i8> @llvm.aarch64.neon.uqadd.v8i8(
; VIRT: define <8 x i16> @protected_sqadd_v8i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <8 x i16> @llvm.aarch64.neon.sqadd.v8i16(
; VIRT: define <4 x i32> @protected_sqsub_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <4 x i32> @llvm.aarch64.neon.sqsub.v4i32(
; VIRT: define <2 x i32> @protected_uqsub_v2i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i32> @llvm.aarch64.neon.uqsub.v2i32(
; VIRT: define <2 x i64> @protected_uqsub_v2i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call <2 x i64> @llvm.aarch64.neon.uqsub.v2i64(
; VIRT: define {{.*}} @unsupported_satint_v1i64({{.*}} #[[UNSUPATTR:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_satint_v4i8({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_satint_sve({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_satint_fastcc({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_satint_musttail({{.*}} #[[UNSUP_MT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call <16 x i8> @llvm.aarch64.neon.sqadd.v16i8(
; VIRT: define {{.*}} @unsupported_satint_bundle({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call <16 x i8> @llvm.aarch64.neon.sqadd.v16i8({{.*}}[ "deopt"(i32 0) ]
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_MT]] = { {{.*}}"hikari.vmp.virtualized"
