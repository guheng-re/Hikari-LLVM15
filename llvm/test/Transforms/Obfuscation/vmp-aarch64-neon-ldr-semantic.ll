; Restricted AArch64 NEON replicate-load via CallDescriptor:
;   llvm.aarch64.neon.ld2r / ld3r / ld4r
; Same AdvSIMD_NVec_Load_Intrinsic shape as ld1xN/ldN:
;   {vec x N} (ptr AS0)
; Same ISel vector set: 64/128-bit i8/i16/i32/i64/f32/f64.
; Every field 0..N-1 is a single-index extractvalue exactly once;
; exploded into independent vector VRegs.  Never the 1..64-byte
; flat-aggregate frame.  C, non-vararg.  Ordinary tail accepted and
; replayed as TCK_None; musttail, bundles, noreturn, returns_twice,
; and complex ABI stay out.
; No dedicated VM opcode.  No +neon/+fullfp16 gate.
; half/bfloat, SVE, arm.neon.vld*, non-AS0, non-ISel widths,
; partial/dup/unused extracts, and first-class tuples stay out.
; Well-formed ld1xN/ldN live in vmp-aarch64-neon-ld-semantic.ll.
;
; Host x86_64 cannot select these AArch64 intrinsics.  FileCheck +
; AArch64 llc/readobj/assembly on the live main-reachable subset.
; O0/O2 x aesSeed 97/7.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.ll -o %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o0.live.ll -o - | FileCheck %s --check-prefix=ASM
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.ll -o %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.s7.ll -o %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.s7.ll -o %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare { <16 x i8>, <16 x i8> } @llvm.aarch64.neon.ld2r.v16i8.p0(ptr)
declare { <8 x i8>, <8 x i8> } @llvm.aarch64.neon.ld2r.v8i8.p0(ptr)
declare { <4 x i16>, <4 x i16> } @llvm.aarch64.neon.ld2r.v4i16.p0(ptr)
declare { <4 x i32>, <4 x i32>, <4 x i32> } @llvm.aarch64.neon.ld3r.v4i32.p0(ptr)
declare { <2 x float>, <2 x float>, <2 x float> } @llvm.aarch64.neon.ld3r.v2f32.p0(ptr)
declare { <2 x i64>, <2 x i64>, <2 x i64>, <2 x i64> } @llvm.aarch64.neon.ld4r.v2i64.p0(ptr)
declare { <2 x double>, <2 x double>, <2 x double>, <2 x double> } @llvm.aarch64.neon.ld4r.v2f64.p0(ptr)
declare { <4 x half>, <4 x half> } @llvm.aarch64.neon.ld2r.v4f16.p0(ptr)
declare { <4 x bfloat>, <4 x bfloat> } @llvm.aarch64.neon.ld2r.v4bf16.p0(ptr)
declare { <4 x i8>, <4 x i8> } @llvm.aarch64.neon.ld2r.v4i8.p0(ptr)
declare { <16 x i8>, <16 x i8> } @llvm.aarch64.neon.ld2r.v16i8.p1(ptr addrspace(1))
declare { <16 x i8>, <16 x i8> } @llvm.arm.neon.vld2.v16i8.p0(ptr, i32)

define <16 x i8> @protected_ld2r_v16(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <16 x i8>, <16 x i8> } @llvm.aarch64.neon.ld2r.v16i8.p0(ptr align 16 %p)
  %a = extractvalue { <16 x i8>, <16 x i8> } %t, 0
  %b = extractvalue { <16 x i8>, <16 x i8> } %t, 1
  %r = xor <16 x i8> %a, %b
  ret <16 x i8> %r
}

; 16-byte {<8 x i8>,<8 x i8>} must explode into vector VRegs.
define <8 x i8> @protected_ld2r_v8(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <8 x i8>, <8 x i8> } @llvm.aarch64.neon.ld2r.v8i8.p0(ptr %p)
  %a = extractvalue { <8 x i8>, <8 x i8> } %t, 0
  %b = extractvalue { <8 x i8>, <8 x i8> } %t, 1
  %r = xor <8 x i8> %a, %b
  ret <8 x i8> %r
}

define <4 x i16> @protected_ld2r_v4i16(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <4 x i16>, <4 x i16> } @llvm.aarch64.neon.ld2r.v4i16.p0(ptr %p)
  %a = extractvalue { <4 x i16>, <4 x i16> } %t, 0
  %b = extractvalue { <4 x i16>, <4 x i16> } %t, 1
  %r = xor <4 x i16> %a, %b
  ret <4 x i16> %r
}

define <4 x i32> @protected_ld3r_v4i32(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <4 x i32>, <4 x i32>, <4 x i32> } @llvm.aarch64.neon.ld3r.v4i32.p0(ptr %p)
  %a = extractvalue { <4 x i32>, <4 x i32>, <4 x i32> } %t, 0
  %b = extractvalue { <4 x i32>, <4 x i32>, <4 x i32> } %t, 1
  %c = extractvalue { <4 x i32>, <4 x i32>, <4 x i32> } %t, 2
  %ab = xor <4 x i32> %a, %b
  %r = xor <4 x i32> %ab, %c
  ret <4 x i32> %r
}

define <2 x float> @protected_ld3r_v2f32(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <2 x float>, <2 x float>, <2 x float> } @llvm.aarch64.neon.ld3r.v2f32.p0(ptr %p)
  %a = extractvalue { <2 x float>, <2 x float>, <2 x float> } %t, 0
  %b = extractvalue { <2 x float>, <2 x float>, <2 x float> } %t, 1
  %c = extractvalue { <2 x float>, <2 x float>, <2 x float> } %t, 2
  %ab = fadd <2 x float> %a, %b
  %r = fadd <2 x float> %ab, %c
  ret <2 x float> %r
}

define <2 x i64> @protected_ld4r_v2i64(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <2 x i64>, <2 x i64>, <2 x i64>, <2 x i64> } @llvm.aarch64.neon.ld4r.v2i64.p0(ptr %p)
  %a = extractvalue { <2 x i64>, <2 x i64>, <2 x i64>, <2 x i64> } %t, 0
  %b = extractvalue { <2 x i64>, <2 x i64>, <2 x i64>, <2 x i64> } %t, 1
  %c = extractvalue { <2 x i64>, <2 x i64>, <2 x i64>, <2 x i64> } %t, 2
  %d = extractvalue { <2 x i64>, <2 x i64>, <2 x i64>, <2 x i64> } %t, 3
  %ab = xor <2 x i64> %a, %b
  %cd = xor <2 x i64> %c, %d
  %r = xor <2 x i64> %ab, %cd
  ret <2 x i64> %r
}

define <2 x double> @protected_ld4r_v2f64(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <2 x double>, <2 x double>, <2 x double>, <2 x double> } @llvm.aarch64.neon.ld4r.v2f64.p0(ptr %p)
  %a = extractvalue { <2 x double>, <2 x double>, <2 x double>, <2 x double> } %t, 0
  %b = extractvalue { <2 x double>, <2 x double>, <2 x double>, <2 x double> } %t, 1
  %c = extractvalue { <2 x double>, <2 x double>, <2 x double>, <2 x double> } %t, 2
  %d = extractvalue { <2 x double>, <2 x double>, <2 x double>, <2 x double> } %t, 3
  %ab = fadd <2 x double> %a, %b
  %cd = fadd <2 x double> %c, %d
  %r = fadd <2 x double> %ab, %cd
  ret <2 x double> %r
}


define { <16 x i8>, <16 x i8> } @unsupported_ld2r_musttail(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = musttail call { <16 x i8>, <16 x i8> } @llvm.aarch64.neon.ld2r.v16i8.p0(ptr %p)
  ret { <16 x i8>, <16 x i8> } %t
}

define <16 x i8> @unsupported_ld2r_bundle(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <16 x i8>, <16 x i8> } @llvm.aarch64.neon.ld2r.v16i8.p0(ptr %p) [ "deopt"(i32 0) ]
  %a = extractvalue { <16 x i8>, <16 x i8> } %t, 0
  %b = extractvalue { <16 x i8>, <16 x i8> } %t, 1
  %r = xor <16 x i8> %a, %b
  ret <16 x i8> %r
}

define <16 x i8> @unsupported_ld2r_fastcc(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call fastcc { <16 x i8>, <16 x i8> } @llvm.aarch64.neon.ld2r.v16i8.p0(ptr %p)
  %a = extractvalue { <16 x i8>, <16 x i8> } %t, 0
  %b = extractvalue { <16 x i8>, <16 x i8> } %t, 1
  %r = xor <16 x i8> %a, %b
  ret <16 x i8> %r
}

define <4 x half> @unsupported_ld2r_half(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <4 x half>, <4 x half> } @llvm.aarch64.neon.ld2r.v4f16.p0(ptr %p)
  %a = extractvalue { <4 x half>, <4 x half> } %t, 0
  %b = extractvalue { <4 x half>, <4 x half> } %t, 1
  %r = fadd <4 x half> %a, %b
  ret <4 x half> %r
}

define void @unsupported_ld2r_bfloat(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <4 x bfloat>, <4 x bfloat> } @llvm.aarch64.neon.ld2r.v4bf16.p0(ptr %p)
  %a = extractvalue { <4 x bfloat>, <4 x bfloat> } %t, 0
  %b = extractvalue { <4 x bfloat>, <4 x bfloat> } %t, 1
  ret void
}

define <4 x i8> @unsupported_ld2r_v4i8(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <4 x i8>, <4 x i8> } @llvm.aarch64.neon.ld2r.v4i8.p0(ptr %p)
  %a = extractvalue { <4 x i8>, <4 x i8> } %t, 0
  %b = extractvalue { <4 x i8>, <4 x i8> } %t, 1
  %r = xor <4 x i8> %a, %b
  ret <4 x i8> %r
}

define <16 x i8> @unsupported_ld2r_as1(ptr addrspace(1) %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <16 x i8>, <16 x i8> } @llvm.aarch64.neon.ld2r.v16i8.p1(ptr addrspace(1) %p)
  %a = extractvalue { <16 x i8>, <16 x i8> } %t, 0
  %b = extractvalue { <16 x i8>, <16 x i8> } %t, 1
  %r = xor <16 x i8> %a, %b
  ret <16 x i8> %r
}

define void @unsupported_ld2r_unused(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <16 x i8>, <16 x i8> } @llvm.aarch64.neon.ld2r.v16i8.p0(ptr %p)
  ret void
}

define <16 x i8> @unsupported_ld2r_partial(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <16 x i8>, <16 x i8> } @llvm.aarch64.neon.ld2r.v16i8.p0(ptr %p)
  %a = extractvalue { <16 x i8>, <16 x i8> } %t, 0
  ret <16 x i8> %a
}

define <16 x i8> @unsupported_ld2r_dup(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <16 x i8>, <16 x i8> } @llvm.aarch64.neon.ld2r.v16i8.p0(ptr %p)
  %a = extractvalue { <16 x i8>, <16 x i8> } %t, 0
  %b = extractvalue { <16 x i8>, <16 x i8> } %t, 0
  %r = xor <16 x i8> %a, %b
  ret <16 x i8> %r
}

define { <16 x i8>, <16 x i8> } @unsupported_ld2r_tuple(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <16 x i8>, <16 x i8> } @llvm.aarch64.neon.ld2r.v16i8.p0(ptr %p)
  ret { <16 x i8>, <16 x i8> } %t
}

define <16 x i8> @unsupported_arm_vld2(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call { <16 x i8>, <16 x i8> } @llvm.arm.neon.vld2.v16i8.p0(ptr %p, i32 1)
  %a = extractvalue { <16 x i8>, <16 x i8> } %t, 0
  %b = extractvalue { <16 x i8>, <16 x i8> } %t, 1
  %r = xor <16 x i8> %a, %b
  ret <16 x i8> %r
}

define i32 @main() {
entry:
  %buf = alloca [64 x i8], align 16
  %p = getelementptr inbounds [64 x i8], ptr %buf, i64 0, i64 0
  %r16 = call <16 x i8> @protected_ld2r_v16(ptr %p)
  store volatile <16 x i8> %r16, ptr %p, align 16
  %r8 = call <8 x i8> @protected_ld2r_v8(ptr %p)
  store volatile <8 x i8> %r8, ptr %p, align 8
  %rs = call <4 x i16> @protected_ld2r_v4i16(ptr %p)
  store volatile <4 x i16> %rs, ptr %p, align 8
  %ri = call <4 x i32> @protected_ld3r_v4i32(ptr %p)
  store volatile <4 x i32> %ri, ptr %p, align 16
  %rf = call <2 x float> @protected_ld3r_v2f32(ptr %p)
  store volatile <2 x float> %rf, ptr %p, align 8
  %rl = call <2 x i64> @protected_ld4r_v2i64(ptr %p)
  store volatile <2 x i64> %rl, ptr %p, align 16
  %rd = call <2 x double> @protected_ld4r_v2f64(ptr %p)
  store volatile <2 x double> %rd, ptr %p, align 16
  ret i32 0
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_ld2r_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_ld2r_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_ld2r_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_ld2r_half: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_ld2r_bfloat: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_ld2r_v4i8: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_ld2r_as1: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_ld2r_unused: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_ld2r_partial: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_ld2r_dup: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_ld2r_tuple: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_arm_vld2: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_ld2r_v16:
; SKIP-NOT: Skipping VMP on protected_ld2r_v8:
; SKIP-NOT: Skipping VMP on protected_ld2r_v4i16:
; SKIP-NOT: Skipping VMP on protected_ld3r_v4i32:
; SKIP-NOT: Skipping VMP on protected_ld3r_v2f32:
; SKIP-NOT: Skipping VMP on protected_ld4r_v2i64:
; SKIP-NOT: Skipping VMP on protected_ld4r_v2f64:

; VIRT: define <16 x i8> @protected_ld2r_v16({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call { <16 x i8>, <16 x i8> } @llvm.aarch64.neon.ld2r.v16i8.p0(ptr align 16
; VIRT: extractvalue { <16 x i8>, <16 x i8> } {{.*}}, 0
; VIRT: extractvalue { <16 x i8>, <16 x i8> } {{.*}}, 1
; VIRT: define <8 x i8> @protected_ld2r_v8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call { <8 x i8>, <8 x i8> } @llvm.aarch64.neon.ld2r.v8i8.p0(
; VIRT: extractvalue { <8 x i8>, <8 x i8> } {{.*}}, 0
; VIRT: extractvalue { <8 x i8>, <8 x i8> } {{.*}}, 1
; VIRT: define <4 x i16> @protected_ld2r_v4i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call { <4 x i16>, <4 x i16> } @llvm.aarch64.neon.ld2r.v4i16.p0(
; VIRT: extractvalue { <4 x i16>, <4 x i16> } {{.*}}, 0
; VIRT: extractvalue { <4 x i16>, <4 x i16> } {{.*}}, 1
; VIRT: define <4 x i32> @protected_ld3r_v4i32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call { <4 x i32>, <4 x i32>, <4 x i32> } @llvm.aarch64.neon.ld3r.v4i32.p0(
; VIRT: extractvalue { <4 x i32>, <4 x i32>, <4 x i32> }
; VIRT: define <2 x float> @protected_ld3r_v2f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call { <2 x float>, <2 x float>, <2 x float> } @llvm.aarch64.neon.ld3r.v2f32.p0(
; VIRT: extractvalue { <2 x float>, <2 x float>, <2 x float> }
; VIRT: define <2 x i64> @protected_ld4r_v2i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call { <2 x i64>, <2 x i64>, <2 x i64>, <2 x i64> } @llvm.aarch64.neon.ld4r.v2i64.p0(
; VIRT: extractvalue { <2 x i64>, <2 x i64>, <2 x i64>, <2 x i64> }
; VIRT: define <2 x double> @protected_ld4r_v2f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call { <2 x double>, <2 x double>, <2 x double>, <2 x double> } @llvm.aarch64.neon.ld4r.v2f64.p0(
; VIRT: extractvalue { <2 x double>, <2 x double>, <2 x double>, <2 x double> }
; VIRT: define {{.*}} @unsupported_ld2r_musttail({{.*}} #[[UNSUP_MT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call { <16 x i8>, <16 x i8> } @llvm.aarch64.neon.ld2r.v16i8.p0(
; VIRT: define {{.*}} @unsupported_ld2r_bundle({{.*}} #[[UNSUPATTR:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call { <16 x i8>, <16 x i8> } @llvm.aarch64.neon.ld2r.v16i8.p0({{.*}}[ "deopt"(i32 0) ]
; VIRT: define {{.*}} @unsupported_ld2r_fastcc({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ld2r_half({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ld2r_bfloat({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ld2r_v4i8({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ld2r_as1({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ld2r_unused({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ld2r_partial({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ld2r_dup({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ld2r_tuple({{.*}} #[[UNSUP_RET:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_arm_vld2({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_MT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_RET]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; Instruction forms, not protected_ld2r_* symbol names.
; ASM-DAG: ld2r{{.*}}{ v0.16b, v1.16b }
; ASM-DAG: ld2r{{.*}}{ v0.8b, v1.8b }
; ASM-DAG: ld2r{{.*}}{ v0.4h, v1.4h }
; ASM-DAG: ld3r{{.*}}{ v0.4s, v1.4s, v2.4s }
; ASM-DAG: ld3r{{.*}}{ v0.2s, v1.2s, v2.2s }
; ASM-DAG: ld4r{{.*}}{ v0.2d, v1.2d, v2.2d, v3.2d }
