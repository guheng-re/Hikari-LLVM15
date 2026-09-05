; Focused llvm.masked.{load,store,gather,scatter,expandload,
; compressstore} eligibility hardening, including last-token +bf16
; legalize.  C, exact non-vararg FTy, formal equality, i32 alignment
; ImmediateArguments on load/store/gather/scatter.  Ordinary tail
; rejected.  Native replay / bfloat LegalizeBFloatMaskedMemory; no
; new opcode.  Do not add VP/scalable or broaden types.
;
; Host lli is reliable for the v4i32 load/store/expand/compress/
; gather/scatter mix.  Half and bfloat are FileCheck-only.
; O0/O2 x 97/7.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.ll > %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: python3 %S/Inputs/vmp-drop-host-masked-memory.py %t.o0.live.ll > %t.o0.host.src.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.host.src.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.ll > %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: python3 %S/Inputs/vmp-drop-host-masked-memory.py %t.o2.live.ll > %t.o2.host.src.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.host.src.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.s7.ll > %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: python3 %S/Inputs/vmp-drop-host-masked-memory.py %t.o0.s7.live.ll > %t.o0.s7.host.src.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.s7.host.src.ll > %t.o0.s7.host.ll
; RUN: lli -force-interpreter %t.o0.s7.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.s7.ll > %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: python3 %S/Inputs/vmp-drop-host-masked-memory.py %t.o2.s7.live.ll > %t.o2.s7.host.src.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.s7.host.src.ll > %t.o2.s7.host.ll
; RUN: lli -force-interpreter %t.o2.s7.host.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare <4 x i32> @llvm.masked.load.v4i32.p0(ptr, i32, <4 x i1>, <4 x i32>)
declare void @llvm.masked.store.v4i32.p0(<4 x i32>, ptr, i32, <4 x i1>)
declare <4 x i32> @llvm.masked.expandload.v4i32(ptr, <4 x i1>, <4 x i32>)
declare void @llvm.masked.compressstore.v4i32(<4 x i32>, ptr, <4 x i1>)
declare <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr>, i32, <4 x i1>, <4 x i32>)
declare void @llvm.masked.scatter.v4i32.v4p0(<4 x i32>, <4 x ptr>, i32, <4 x i1>)
declare <4 x half> @llvm.masked.load.v4f16.p0(ptr, i32, <4 x i1>, <4 x half>)
declare <4 x bfloat> @llvm.masked.load.v4bf16.p0(ptr, i32, <4 x i1>, <4 x bfloat>)
declare <4 x i32> @llvm.masked.load.v4i32.p1(ptr addrspace(1), i32, <4 x i1>, <4 x i32>)
declare <4 x i32> @llvm.vp.load.v4i32.p0(ptr, <4 x i1>, i32)
declare float @llvm.experimental.constrained.fadd.f32(float, float, metadata, metadata)
declare void @ext_sret_byval(ptr sret(i32), ptr byval(i32))

@src.i32 = private global [4 x i32] [i32 10, i32 20, i32 30, i32 40], align 16
@dst.i32 = private global [4 x i32] zeroinitializer, align 16
@slot.as = private global [4 x i32] zeroinitializer, align 16

define i32 @fold_i32x4(<4 x i32> %v) {
entry:
  %e0 = extractelement <4 x i32> %v, i32 0
  %e1 = extractelement <4 x i32> %v, i32 1
  %e2 = extractelement <4 x i32> %v, i32 2
  %e3 = extractelement <4 x i32> %v, i32 3
  %s0 = add i32 %e0, %e1
  %s1 = add i32 %e2, %e3
  %r = xor i32 %s0, %s1
  ret i32 %r
}

define i32 @reference(ptr %p, ptr %d, <4 x i32> %pt, <4 x i32> %sv) noinline {
entry:
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix = insertelement <4 x i1> %mix0, i1 true, i32 2
  %ld = call <4 x i32> @llvm.masked.load.v4i32.p0(ptr %p, i32 4, <4 x i1> %mix, <4 x i32> %pt)
  call void @llvm.masked.store.v4i32.p0(<4 x i32> %sv, ptr %d, i32 4, <4 x i1> %mix)
  %ex = call <4 x i32> @llvm.masked.expandload.v4i32(ptr %p, <4 x i1> %mix, <4 x i32> %pt)
  call void @llvm.masked.compressstore.v4i32(<4 x i32> %sv, ptr %d, <4 x i1> %mix)
  %ptrs = getelementptr i32, ptr %p, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  %g = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> %ptrs, i32 4, <4 x i1> %mix, <4 x i32> %pt)
  %dptrs = getelementptr i32, ptr %d, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  call void @llvm.masked.scatter.v4i32.v4p0(<4 x i32> %sv, <4 x ptr> %dptrs, i32 4, <4 x i1> %mix)
  %t0 = call i32 @fold_i32x4(<4 x i32> %ld)
  %t1 = call i32 @fold_i32x4(<4 x i32> %ex)
  %t2 = call i32 @fold_i32x4(<4 x i32> %g)
  %x0 = xor i32 %t0, %t1
  %r = xor i32 %x0, %t2
  ret i32 %r
}

define i32 @protected(ptr %p, ptr %d, <4 x i32> %pt, <4 x i32> %sv) noinline optnone {
entry:
  call void @hikari_vmp()
  %mix0 = insertelement <4 x i1> zeroinitializer, i1 true, i32 0
  %mix = insertelement <4 x i1> %mix0, i1 true, i32 2
  %ld = call <4 x i32> @llvm.masked.load.v4i32.p0(ptr %p, i32 4, <4 x i1> %mix, <4 x i32> %pt)
  call void @llvm.masked.store.v4i32.p0(<4 x i32> %sv, ptr %d, i32 4, <4 x i1> %mix)
  %ex = call <4 x i32> @llvm.masked.expandload.v4i32(ptr %p, <4 x i1> %mix, <4 x i32> %pt)
  call void @llvm.masked.compressstore.v4i32(<4 x i32> %sv, ptr %d, <4 x i1> %mix)
  %ptrs = getelementptr i32, ptr %p, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  %g = call <4 x i32> @llvm.masked.gather.v4i32.v4p0(<4 x ptr> %ptrs, i32 4, <4 x i1> %mix, <4 x i32> %pt)
  %dptrs = getelementptr i32, ptr %d, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  call void @llvm.masked.scatter.v4i32.v4p0(<4 x i32> %sv, <4 x ptr> %dptrs, i32 4, <4 x i1> %mix)
  %t0 = call i32 @fold_i32x4(<4 x i32> %ld)
  %t1 = call i32 @fold_i32x4(<4 x i32> %ex)
  %t2 = call i32 @fold_i32x4(<4 x i32> %g)
  %x0 = xor i32 %t0, %t1
  %r = xor i32 %x0, %t2
  ret i32 %r
}

define <4 x half> @protected_half(ptr %p, <4 x i1> %m, <4 x half> %t) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x half> @llvm.masked.load.v4f16.p0(ptr %p, i32 2, <4 x i1> %m, <4 x half> %t)
  ret <4 x half> %r
}

define <4 x bfloat> @protected_bfloat(ptr %p, <4 x i1> %m, <4 x bfloat> %t) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call <4 x bfloat> @llvm.masked.load.v4bf16.p0(ptr %p, i32 2, <4 x i1> %m, <4 x bfloat> %t)
  ret <4 x bfloat> %r
}




define <4 x i32> @unsupported_load_fastcc(ptr %p, <4 x i1> %m, <4 x i32> %t) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc <4 x i32> @llvm.masked.load.v4i32.p0(ptr %p, i32 4, <4 x i1> %m, <4 x i32> %t)
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_load_musttail(ptr %p, <4 x i1> %m, <4 x i32> %t) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call <4 x i32> @llvm.masked.load.v4i32.p0(ptr %p, i32 4, <4 x i1> %m, <4 x i32> %t)
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_load_bundle(ptr %p, <4 x i1> %m, <4 x i32> %t) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.masked.load.v4i32.p0(ptr %p, i32 4, <4 x i1> %m, <4 x i32> %t) [ "deopt"(i32 0) ]
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_load_noreturn(ptr %p, <4 x i1> %m, <4 x i32> %t) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.masked.load.v4i32.p0(ptr %p, i32 4, <4 x i1> %m, <4 x i32> %t) noreturn
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_load_returns_twice(ptr %p, <4 x i1> %m, <4 x i32> %t) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.masked.load.v4i32.p0(ptr %p, i32 4, <4 x i1> %m, <4 x i32> %t) returns_twice
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_load_poison_mask(ptr %p, <4 x i32> %t) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.masked.load.v4i32.p0(ptr %p, i32 4, <4 x i1> poison, <4 x i32> %t)
  ret <4 x i32> %r
}

define <4 x i32> @unsupported_load_poison_passthru(ptr %p, <4 x i1> %m) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.masked.load.v4i32.p0(ptr %p, i32 4, <4 x i1> %m, <4 x i32> poison)
  ret <4 x i32> %r
}

define i32 @unsupported_bfloat_no_bf16(ptr %p, <4 x i1> %m, <4 x i16> %bits) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = bitcast <4 x i16> %bits to <4 x bfloat>
  %r = call <4 x bfloat> @llvm.masked.load.v4bf16.p0(ptr %p, i32 2, <4 x i1> %m, <4 x bfloat> %t)
  %o = bitcast <4 x bfloat> %r to <4 x i16>
  %e = extractelement <4 x i16> %o, i32 0
  %z = zext i16 %e to i32
  ret i32 %z
}

define <4 x i32> @unsupported_vp(ptr %p, <4 x i1> %m) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.vp.load.v4i32.p0(ptr %p, <4 x i1> %m, i32 4)
  ret <4 x i32> %r
}

define float @unsupported_constrained_fadd_f32(float %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc float @llvm.experimental.constrained.fadd.f32(float %x, float %x, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret float %r
}

define i32 @unsupported_as1_arg(<4 x i1> %m, <4 x i32> %t) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x i32> @llvm.masked.load.v4i32.p1(ptr addrspace(1) addrspacecast (ptr @slot.as to ptr addrspace(1)), i32 4, <4 x i1> %m, <4 x i32> %t)
  %e = extractelement <4 x i32> %r, i32 0
  ret i32 %e
}

define void @unsupported_sret(ptr sret(i32) %p, ptr byval(i32) %q) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @ext_sret_byval(ptr sret(i32) %p, ptr byval(i32) %q)
  ret void
}

define i32 @main() {
entry:
  %d0 = alloca [4 x i32], align 16
  %d1 = alloca [4 x i32], align 16
  store <4 x i32> zeroinitializer, ptr %d0, align 16
  store <4 x i32> zeroinitializer, ptr %d1, align 16
  %pt = add <4 x i32> <i32 1, i32 2, i32 3, i32 4>, zeroinitializer
  %sv = add <4 x i32> <i32 5, i32 6, i32 7, i32 8>, zeroinitializer
  %e0 = call i32 @reference(ptr @src.i32, ptr %d0, <4 x i32> %pt, <4 x i32> %sv)
  %a0 = call i32 @protected(ptr @src.i32, ptr %d1, <4 x i32> %pt, <4 x i32> %sv)
  %pt1 = add <4 x i32> <i32 9, i32 8, i32 7, i32 6>, zeroinitializer
  store <4 x i32> zeroinitializer, ptr %d0, align 16
  store <4 x i32> zeroinitializer, ptr %d1, align 16
  %e1 = call i32 @reference(ptr @src.i32, ptr %d0, <4 x i32> %pt1, <4 x i32> %sv)
  %a1 = call i32 @protected(ptr @src.i32, ptr %d1, <4 x i32> %pt1, <4 x i32> %sv)
  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %e1, %a1
  %ok = and i1 %m0, %m1
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_load_fastcc: unsupported masked memory instruction
; SKIP-DAG: Skipping VMP on unsupported_load_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_load_bundle: unsupported masked memory instruction
; SKIP-DAG: Skipping VMP on unsupported_load_noreturn: unsupported masked memory instruction
; SKIP-DAG: Skipping VMP on unsupported_load_returns_twice: unsupported masked memory instruction
; SKIP-DAG: Skipping VMP on unsupported_load_poison_mask: unsupported masked memory instruction
; SKIP-DAG: Skipping VMP on unsupported_load_poison_passthru: unsupported masked memory instruction
; SKIP-DAG: Skipping VMP on unsupported_bfloat_no_bf16: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_vp: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_constrained_fadd_f32: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_as1_arg: unsupported masked memory instruction
; SKIP-DAG: Skipping VMP on unsupported_sret: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected:
; SKIP-NOT: Skipping VMP on protected_half:
; SKIP-NOT: Skipping VMP on protected_bfloat:

; VIRT-LABEL: define i32 @protected(
; VIRT-SAME: #[[PROT:[0-9]+]]
; VIRT: vmp.dispatch:
; VIRT-DAG: call <4 x i32> @llvm.masked.load.v4i32.p0(
; VIRT-DAG: call void @llvm.masked.store.v4i32.p0(
; VIRT-DAG: call <4 x i32> @llvm.masked.expandload.v4i32(
; VIRT-DAG: call void @llvm.masked.compressstore.v4i32(
; VIRT-DAG: call <4 x i32> @llvm.masked.gather.v4i32.v4p0(
; VIRT-DAG: call void @llvm.masked.scatter.v4i32.v4p0(
; VIRT-LABEL: define <4 x half> @protected_half(
; VIRT: vmp.dispatch:
; VIRT: call <4 x half> @llvm.masked.load.v4f16.p0(
; VIRT-LABEL: define <4 x bfloat> @protected_bfloat(
; VIRT-SAME: #[[PROTBF:[0-9]+]]
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.masked.load
; VIRT: load bfloat
; VIRT: define {{.*}} @unsupported_load_fastcc({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_load_musttail(
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call <4 x i32> @llvm.masked.load.v4i32.p0(
; VIRT-LABEL: define {{.*}} @unsupported_load_bundle(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_load_noreturn(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_load_returns_twice(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_load_poison_mask(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_load_poison_passthru(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_bfloat_no_bf16(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_vp(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_constrained_fadd_f32(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_as1_arg(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_sret(
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[PROTBF]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.selected"

; AARCH64: Arch: aarch64
