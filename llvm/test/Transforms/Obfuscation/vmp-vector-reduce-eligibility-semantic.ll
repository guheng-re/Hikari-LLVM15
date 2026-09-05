; Focused llvm.vector.reduce eligibility hardening: integer
; add/mul/bit/minmax, f32 start-value fadd/fmul and fmin/fmax, f64
; start-value fadd, half +fullfp16, and last-token +bf16 legalize.
; C, exact non-vararg FTy, formal equality including the fadd/fmul
; start value.  Ordinary tail accepted and replayed as TCK_None.  Replay / bfloat
; LegalizeBFloatMath; no new opcode.  Do not add VP/scalable or
; broaden types.
;
; Host lli is reliable for the v4i32 integer mix plus f32 fadd start.
; Half, bfloat, f64, and fmin/fmax are FileCheck-only.  O0/O2 x 97/7.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP-O0 < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.ll > %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: python3 %S/Inputs/vmp-drop-host-vector-reduce.py %t.o0.live.ll > %t.o0.host.src.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.host.src.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.ll > %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: python3 %S/Inputs/vmp-drop-host-vector-reduce.py %t.o2.live.ll > %t.o2.host.src.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.host.src.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP-O0 < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.s7.ll > %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: python3 %S/Inputs/vmp-drop-host-vector-reduce.py %t.o0.s7.live.ll > %t.o0.s7.host.src.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.s7.host.src.ll > %t.o0.s7.host.ll
; RUN: lli -force-interpreter %t.o0.s7.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.s7.ll > %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: python3 %S/Inputs/vmp-drop-host-vector-reduce.py %t.o2.s7.live.ll > %t.o2.s7.host.src.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.s7.host.src.ll > %t.o2.s7.host.ll
; RUN: lli -force-interpreter %t.o2.s7.host.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare i32 @llvm.vector.reduce.add.v4i32(<4 x i32>)
declare i32 @llvm.vector.reduce.mul.v4i32(<4 x i32>)
declare i32 @llvm.vector.reduce.and.v4i32(<4 x i32>)
declare i32 @llvm.vector.reduce.or.v4i32(<4 x i32>)
declare i32 @llvm.vector.reduce.xor.v4i32(<4 x i32>)
declare i32 @llvm.vector.reduce.smin.v4i32(<4 x i32>)
declare i32 @llvm.vector.reduce.smax.v4i32(<4 x i32>)
declare i32 @llvm.vector.reduce.umax.v4i32(<4 x i32>)
declare i32 @llvm.vector.reduce.add.v8i32(<8 x i32>)
declare float @llvm.vector.reduce.fadd.v4f32(float, <4 x float>)
declare float @llvm.vector.reduce.fmul.v4f32(float, <4 x float>)
declare float @llvm.vector.reduce.fmin.v4f32(<4 x float>)
declare float @llvm.vector.reduce.fmax.v4f32(<4 x float>)
declare double @llvm.vector.reduce.fadd.v2f64(double, <2 x double>)
declare half @llvm.vector.reduce.fadd.v4f16(half, <4 x half>)
declare bfloat @llvm.vector.reduce.fadd.v4bf16(bfloat, <4 x bfloat>)
declare i32 @llvm.vp.reduce.add.v4i32(i32, <4 x i32>, <4 x i1>, i32)
declare float @llvm.experimental.constrained.fadd.f32(float, float, metadata, metadata)
declare void @ext_sret_byval(ptr sret(i32), ptr byval(i32))

define i32 @reference(<4 x i32> %v, float %s, <4 x float> %fv) noinline {
entry:
  %a = call i32 @llvm.vector.reduce.add.v4i32(<4 x i32> %v)
  %m = call i32 @llvm.vector.reduce.mul.v4i32(<4 x i32> %v)
  %d = call i32 @llvm.vector.reduce.and.v4i32(<4 x i32> %v)
  %o = call i32 @llvm.vector.reduce.or.v4i32(<4 x i32> %v)
  %x = call i32 @llvm.vector.reduce.xor.v4i32(<4 x i32> %v)
  %n = call i32 @llvm.vector.reduce.smin.v4i32(<4 x i32> %v)
  %sx = call i32 @llvm.vector.reduce.smax.v4i32(<4 x i32> %v)
  %u = call i32 @llvm.vector.reduce.umax.v4i32(<4 x i32> %v)
  %fa = call float @llvm.vector.reduce.fadd.v4f32(float %s, <4 x float> %fv)
  %fb = bitcast float %fa to i32
  %t0 = xor i32 %a, %m
  %t1 = xor i32 %d, %o
  %t2 = xor i32 %x, %n
  %t3 = xor i32 %sx, %u
  %t4 = xor i32 %t0, %t1
  %t5 = xor i32 %t2, %t3
  %t6 = xor i32 %t4, %t5
  %r = xor i32 %t6, %fb
  ret i32 %r
}

define i32 @protected(<4 x i32> %v, float %s, <4 x float> %fv) noinline optnone {
entry:
  call void @hikari_vmp()
  %a = call i32 @llvm.vector.reduce.add.v4i32(<4 x i32> %v)
  %m = call i32 @llvm.vector.reduce.mul.v4i32(<4 x i32> %v)
  %d = call i32 @llvm.vector.reduce.and.v4i32(<4 x i32> %v)
  %o = call i32 @llvm.vector.reduce.or.v4i32(<4 x i32> %v)
  %x = call i32 @llvm.vector.reduce.xor.v4i32(<4 x i32> %v)
  %n = call i32 @llvm.vector.reduce.smin.v4i32(<4 x i32> %v)
  %sx = call i32 @llvm.vector.reduce.smax.v4i32(<4 x i32> %v)
  %u = call i32 @llvm.vector.reduce.umax.v4i32(<4 x i32> %v)
  %fa = call float @llvm.vector.reduce.fadd.v4f32(float %s, <4 x float> %fv)
  %fb = bitcast float %fa to i32
  %t0 = xor i32 %a, %m
  %t1 = xor i32 %d, %o
  %t2 = xor i32 %x, %n
  %t3 = xor i32 %sx, %u
  %t4 = xor i32 %t0, %t1
  %t5 = xor i32 %t2, %t3
  %t6 = xor i32 %t4, %t5
  %r = xor i32 %t6, %fb
  ret i32 %r
}

define float @protected_fp_minmax(<4 x float> %fv) noinline optnone {
entry:
  call void @hikari_vmp()
  %n = call float @llvm.vector.reduce.fmin.v4f32(<4 x float> %fv)
  %x = call float @llvm.vector.reduce.fmax.v4f32(<4 x float> %fv)
  %fm = call float @llvm.vector.reduce.fmul.v4f32(float 1.000000e+00, <4 x float> %fv)
  %a = fadd float %n, %x
  %r = fadd float %a, %fm
  ret float %r
}

define half @protected_half(half %s, <4 x half> %v) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.vector.reduce.fadd.v4f16(half %s, <4 x half> %v)
  ret half %r
}

define bfloat @protected_bfloat(bfloat %s, <4 x bfloat> %v) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat @llvm.vector.reduce.fadd.v4bf16(bfloat %s, <4 x bfloat> %v)
  ret bfloat %r
}

define double @protected_f64(double %s, <2 x double> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call double @llvm.vector.reduce.fadd.v2f64(double %s, <2 x double> %v)
  ret double %r
}


define i32 @unsupported_reduce_fastcc(<4 x i32> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc i32 @llvm.vector.reduce.add.v4i32(<4 x i32> %v)
  ret i32 %r
}

define i32 @unsupported_reduce_musttail(<4 x i32> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call i32 @llvm.vector.reduce.add.v4i32(<4 x i32> %v)
  ret i32 %r
}

define i32 @unsupported_reduce_bundle(<4 x i32> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.vector.reduce.add.v4i32(<4 x i32> %v) [ "deopt"(i32 0) ]
  ret i32 %r
}

define i32 @unsupported_reduce_noreturn(<4 x i32> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.vector.reduce.add.v4i32(<4 x i32> %v) noreturn
  ret i32 %r
}

define i32 @unsupported_reduce_returns_twice(<4 x i32> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.vector.reduce.add.v4i32(<4 x i32> %v) returns_twice
  ret i32 %r
}

define i32 @unsupported_reduce_wide() noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.vector.reduce.add.v8i32(<8 x i32> zeroinitializer)
  ret i32 %r
}

define i32 @unsupported_reduce_poison() noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.vector.reduce.add.v4i32(<4 x i32> poison)
  ret i32 %r
}


define float @unsupported_fadd_start_poison(<4 x float> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.vector.reduce.fadd.v4f32(float poison, <4 x float> %v)
  ret float %r
}

define half @unsupported_half_no_fullfp16(half %s, <4 x half> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.vector.reduce.fadd.v4f16(half %s, <4 x half> %v)
  ret half %r
}

define half @unsupported_half_last_token(half %s, <4 x half> %v) noinline optnone "target-features"="+fullfp16,-fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.vector.reduce.fadd.v4f16(half %s, <4 x half> %v)
  ret half %r
}

define i32 @unsupported_bfloat_no_bf16(i16 %s, <4 x i16> %bits) noinline optnone {
entry:
  call void @hikari_vmp()
  %start = bitcast i16 %s to bfloat
  %v = bitcast <4 x i16> %bits to <4 x bfloat>
  %r = call bfloat @llvm.vector.reduce.fadd.v4bf16(bfloat %start, <4 x bfloat> %v)
  %t = bitcast bfloat %r to i16
  %z = zext i16 %t to i32
  ret i32 %z
}

define bfloat @unsupported_bfloat_fmf(bfloat %s, <4 x bfloat> %v) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call nnan bfloat @llvm.vector.reduce.fadd.v4bf16(bfloat %s, <4 x bfloat> %v)
  ret bfloat %r
}

define i32 @unsupported_vp(<4 x i32> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.vp.reduce.add.v4i32(i32 0, <4 x i32> %v, <4 x i1> <i1 true, i1 true, i1 true, i1 true>, i32 4)
  ret i32 %r
}

define float @unsupported_constrained_fadd_f32(float %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc float @llvm.experimental.constrained.fadd.f32(float %x, float %x, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  ret float %r
}

define void @unsupported_as1_arg(ptr addrspace(1) %unused) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.vector.reduce.add.v4i32(<4 x i32> <i32 1, i32 2, i32 3, i32 4>)
  ret void
}

define void @unsupported_sret(ptr sret(i32) %p, ptr byval(i32) %q) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @ext_sret_byval(ptr sret(i32) %p, ptr byval(i32) %q)
  ret void
}

define i32 @main() {
entry:
  %v = add <4 x i32> <i32 3, i32 -5, i32 7, i32 1>, zeroinitializer
  %fv = sitofp <4 x i32> %v to <4 x float>
  %e0 = call i32 @reference(<4 x i32> %v, float 1.000000e+00, <4 x float> %fv)
  %a0 = call i32 @protected(<4 x i32> %v, float 1.000000e+00, <4 x float> %fv)
  %v1 = add <4 x i32> <i32 2, i32 4, i32 6, i32 8>, zeroinitializer
  %fv1 = sitofp <4 x i32> %v1 to <4 x float>
  %e1 = call i32 @reference(<4 x i32> %v1, float 0.000000e+00, <4 x float> %fv1)
  %a1 = call i32 @protected(<4 x i32> %v1, float 0.000000e+00, <4 x float> %fv1)
  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %e1, %a1
  %ok = and i1 %m0, %m1
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_reduce_fastcc: unsupported vector reduce instruction
; SKIP-DAG: Skipping VMP on unsupported_reduce_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_reduce_bundle: unsupported vector reduce instruction
; SKIP-DAG: Skipping VMP on unsupported_reduce_noreturn: unsupported vector reduce instruction
; SKIP-DAG: Skipping VMP on unsupported_reduce_returns_twice: unsupported vector reduce instruction
; SKIP-DAG: Skipping VMP on unsupported_reduce_poison: unsupported vector reduce instruction
; SKIP-DAG: Skipping VMP on unsupported_fadd_start_poison: unsupported vector reduce instruction
; SKIP-DAG: Skipping VMP on unsupported_half_no_fullfp16: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_half_last_token: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_bfloat_no_bf16: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_bfloat_fmf: unsupported float call instruction
; SKIP-DAG: Skipping VMP on unsupported_vp: unsupported vector reduce instruction
; SKIP-DAG: Skipping VMP on unsupported_constrained_fadd_f32: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_as1_arg: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_sret: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected:
; SKIP-NOT: Skipping VMP on protected_fp_minmax:
; SKIP-NOT: Skipping VMP on protected_half:
; SKIP-NOT: Skipping VMP on protected_bfloat:
; SKIP-NOT: Skipping VMP on protected_f64:
; Constant-only overwide reduce can fold before VMP under default<O2>.
; SKIP-O0-DAG: Skipping VMP on unsupported_reduce_wide: unsupported vector reduce instruction

; VIRT-LABEL: define i32 @protected(
; VIRT-SAME: #[[PROT:[0-9]+]]
; VIRT: vmp.dispatch:
; VIRT-DAG: call i32 @llvm.vector.reduce.add.v4i32(
; VIRT-DAG: call i32 @llvm.vector.reduce.mul.v4i32(
; VIRT-DAG: call i32 @llvm.vector.reduce.and.v4i32(
; VIRT-DAG: call i32 @llvm.vector.reduce.or.v4i32(
; VIRT-DAG: call i32 @llvm.vector.reduce.xor.v4i32(
; VIRT-DAG: call i32 @llvm.vector.reduce.smin.v4i32(
; VIRT-DAG: call i32 @llvm.vector.reduce.smax.v4i32(
; VIRT-DAG: call i32 @llvm.vector.reduce.umax.v4i32(
; VIRT-DAG: call float @llvm.vector.reduce.fadd.v4f32(
; VIRT-LABEL: define float @protected_fp_minmax(
; VIRT: vmp.dispatch:
; VIRT-DAG: call float @llvm.vector.reduce.fmin.v4f32(
; VIRT-DAG: call float @llvm.vector.reduce.fmax.v4f32(
; VIRT-DAG: call float @llvm.vector.reduce.fmul.v4f32(
; VIRT-LABEL: define half @protected_half(
; VIRT-SAME: #[[PROTHALF:[0-9]+]]
; VIRT: vmp.dispatch:
; VIRT: call half @llvm.vector.reduce.fadd.v4f16(
; VIRT-LABEL: define bfloat @protected_bfloat(
; VIRT-SAME: #[[PROTBF:[0-9]+]]
; VIRT: vmp.dispatch:
; VIRT-NOT: call{{.*}}@llvm.vector.reduce
; VIRT: fadd float
; VIRT-LABEL: define double @protected_f64(
; VIRT: vmp.dispatch:
; VIRT: call double @llvm.vector.reduce.fadd.v2f64(
; VIRT: define {{.*}} @unsupported_reduce_fastcc({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_reduce_musttail(
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call i32 @llvm.vector.reduce.add.v4i32(
; VIRT-LABEL: define {{.*}} @unsupported_reduce_bundle(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_reduce_noreturn(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_reduce_returns_twice(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_reduce_wide(
; VIRT-LABEL: define {{.*}} @unsupported_reduce_poison(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_fadd_start_poison(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_half_no_fullfp16(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_half_last_token(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_bfloat_no_bf16(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_bfloat_fmf(
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
; VIRT: attributes #[[PROTHALF]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[PROTBF]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.selected"

; AARCH64: Arch: aarch64
