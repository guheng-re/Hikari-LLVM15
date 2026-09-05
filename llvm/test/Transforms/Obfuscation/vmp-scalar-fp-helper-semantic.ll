; Scalar floating helper CallDescriptor / plan-time family:
; ceil/floor/trunc/round/rint/nearbyint/roundeven, canonicalize
; (eligibility before FMul x, 1.0 lowering), lround/llround/lrint/llrint
; (i64 from f32/f64), is.fpclass (i1 + i32 ImmArg mask), and
; fptosi/fptoui.sat to i8/i16/i32/i64 from f32/f64.  C, exact
; non-vararg FTy, formal type equality, true immediates.  Ordinary tail
; rejected.  Half listed rounding/canonicalize still need last-token
; +fullfp16.  Replay / canonicalize lowering; no new opcode.
; Do not touch fp128, bfloat, vectors, or constrained forms.
;
; Host lli is reliable for the f32 mix of ceil/floor/trunc/round,
; lround.i64, is.fpclass, and fptosi.sat.i32.  rint/nearbyint/
; roundeven/canonicalize/ll* and sat i8/i16/i64 are FileCheck-only
; (x86 JIT cannot select some of them).  O0/O2 x 97/7.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.ll > %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: python3 %S/Inputs/vmp-drop-host-scalar-fp-helper.py %t.o0.live.ll > %t.o0.host.src.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.host.src.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.ll > %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: python3 %S/Inputs/vmp-drop-host-scalar-fp-helper.py %t.o2.live.ll > %t.o2.host.src.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.host.src.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.s7.ll > %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: python3 %S/Inputs/vmp-drop-host-scalar-fp-helper.py %t.o0.s7.live.ll > %t.o0.s7.host.src.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.s7.host.src.ll > %t.o0.s7.host.ll
; RUN: lli -force-interpreter %t.o0.s7.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.s7.ll > %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: python3 %S/Inputs/vmp-drop-host-scalar-fp-helper.py %t.o2.s7.live.ll > %t.o2.s7.host.src.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.s7.host.src.ll > %t.o2.s7.host.ll
; RUN: lli -force-interpreter %t.o2.s7.host.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare float @llvm.ceil.f32(float)
declare float @llvm.floor.f32(float)
declare float @llvm.trunc.f32(float)
declare float @llvm.round.f32(float)
declare float @llvm.rint.f32(float)
declare float @llvm.nearbyint.f32(float)
declare float @llvm.roundeven.f32(float)
declare float @llvm.canonicalize.f32(float)
declare double @llvm.ceil.f64(double)
declare i64 @llvm.lround.i64.f32(float)
declare i64 @llvm.llround.i64.f32(float)
declare i64 @llvm.lrint.i64.f32(float)
declare i64 @llvm.llrint.i64.f32(float)
declare i32 @llvm.lround.i32.f32(float)
declare i1 @llvm.is.fpclass.f32(float, i32)
declare i32 @llvm.fptosi.sat.i32.f32(float)
declare i32 @llvm.fptoui.sat.i32.f32(float)
declare i64 @llvm.fptosi.sat.i64.f32(float)
declare i8 @llvm.fptosi.sat.i8.f32(float)
declare i16 @llvm.fptoui.sat.i16.f32(float)
declare half @llvm.ceil.f16(half)
declare float @llvm.experimental.constrained.fadd.f32(float, float, metadata, metadata)
declare void @ext_sret_byval(ptr sret(i32), ptr byval(i32))

; ----- host-reliable f32 mix (SSA args so O2 cannot fold before VMP) -----

define i32 @reference(float %x) noinline {
entry:
  %c = call float @llvm.ceil.f32(float %x)
  %f = call float @llvm.floor.f32(float %x)
  %t = call float @llvm.trunc.f32(float %x)
  %r = call float @llvm.round.f32(float %x)
  %lr = call i64 @llvm.lround.i64.f32(float %x)
  %cl = call i1 @llvm.is.fpclass.f32(float %x, i32 2016)
  %si = call i32 @llvm.fptosi.sat.i32.f32(float %x)
  %a = bitcast float %c to i32
  %b = bitcast float %f to i32
  %d = bitcast float %t to i32
  %e = bitcast float %r to i32
  %g = trunc i64 %lr to i32
  %h = zext i1 %cl to i32
  %i = xor i32 %a, %b
  %j = xor i32 %d, %e
  %k = xor i32 %g, %h
  %l = xor i32 %i, %j
  %m = xor i32 %l, %k
  %o = xor i32 %m, %si
  ret i32 %o
}

define i32 @protected(float %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %c = call float @llvm.ceil.f32(float %x)
  %f = call float @llvm.floor.f32(float %x)
  %t = call float @llvm.trunc.f32(float %x)
  %r = call float @llvm.round.f32(float %x)
  %lr = call i64 @llvm.lround.i64.f32(float %x)
  %cl = call i1 @llvm.is.fpclass.f32(float %x, i32 2016)
  %si = call i32 @llvm.fptosi.sat.i32.f32(float %x)
  %a = bitcast float %c to i32
  %b = bitcast float %f to i32
  %d = bitcast float %t to i32
  %e = bitcast float %r to i32
  %g = trunc i64 %lr to i32
  %h = zext i1 %cl to i32
  %i = xor i32 %a, %b
  %j = xor i32 %d, %e
  %k = xor i32 %g, %h
  %l = xor i32 %i, %j
  %m = xor i32 %l, %k
  %o = xor i32 %m, %si
  ret i32 %o
}

define float @protected_more_round(float %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %ri = call float @llvm.rint.f32(float %x)
  %n = call float @llvm.nearbyint.f32(float %x)
  %e = call float @llvm.roundeven.f32(float %x)
  %a = fadd float %ri, %n
  %r = fadd float %a, %e
  ret float %r
}

define float @protected_canonicalize(float %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.canonicalize.f32(float %x)
  ret float %r
}

define i64 @protected_int_round(float %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %a = call i64 @llvm.llround.i64.f32(float %x)
  %b = call i64 @llvm.lrint.i64.f32(float %x)
  %c = call i64 @llvm.llrint.i64.f32(float %x)
  %d = xor i64 %a, %b
  %r = xor i64 %d, %c
  ret i64 %r
}

define i32 @protected_sat(float %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %u = call i32 @llvm.fptoui.sat.i32.f32(float %x)
  %w = call i64 @llvm.fptosi.sat.i64.f32(float %x)
  %n = call i8 @llvm.fptosi.sat.i8.f32(float %x)
  %m = call i16 @llvm.fptoui.sat.i16.f32(float %x)
  %wt = trunc i64 %w to i32
  %nz = zext i8 %n to i32
  %mz = zext i16 %m to i32
  %a = xor i32 %u, %wt
  %b = xor i32 %nz, %mz
  %r = xor i32 %a, %b
  ret i32 %r
}

define i64 @protected_f64(double %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %c = call double @llvm.ceil.f64(double %x)
  %r = bitcast double %c to i64
  ret i64 %r
}

define i32 @protected_half(half %x) noinline optnone "target-features"="+fullfp16" {
entry:
  call void @hikari_vmp()
  %c = call half @llvm.ceil.f16(half %x)
  %b = bitcast half %c to i16
  %r = zext i16 %b to i32
  ret i32 %r
}

define float @protected_fast_ceil(float %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call nnan ninf float @llvm.ceil.f32(float %x)
  ret float %r
}

; ----- negatives -----


define float @unsupported_ceil_malformed(float %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.ceil.f32(float %x) noreturn
  ret float %r
}

define float @unsupported_ceil_musttail(float %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call float @llvm.ceil.f32(float %x)
  ret float %r
}

define float @unsupported_ceil_bundle(float %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.ceil.f32(float %x) [ "deopt"(i32 0) ]
  ret float %r
}

define float @unsupported_ceil_fastcc(float %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc float @llvm.ceil.f32(float %x)
  ret float %r
}

define float @unsupported_ceil_poison() noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.ceil.f32(float poison)
  ret float %r
}

define float @unsupported_ceil_returns_twice(float %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.ceil.f32(float %x) returns_twice
  ret float %r
}



define i32 @unsupported_lround_i32(float %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.lround.i32.f32(float %x)
  ret i32 %r
}


define i1 @unsupported_fpclass_fastcc(float %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc i1 @llvm.is.fpclass.f32(float %x, i32 2016)
  ret i1 %r
}



define i32 @unsupported_sat_poison() noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.fptosi.sat.i32.f32(float poison)
  ret i32 %r
}

define half @unsupported_half_ceil_no_fullfp16(half %h) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.ceil.f16(half %h)
  ret half %r
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
  %r = call float @llvm.ceil.f32(float 1.500000e+00)
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
  %e0 = call i32 @reference(float 1.500000e+00)
  %a0 = call i32 @protected(float 1.500000e+00)
  %e1 = call i32 @reference(float -2.250000e+00)
  %a1 = call i32 @protected(float -2.250000e+00)
  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %e1, %a1
  %ok = and i1 %m0, %m1
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_ceil_malformed: unsupported ceil
; SKIP-DAG: Skipping VMP on unsupported_ceil_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_ceil_bundle: unsupported ceil
; SKIP-DAG: Skipping VMP on unsupported_ceil_fastcc: unsupported ceil
; SKIP-DAG: Skipping VMP on unsupported_ceil_poison: unsupported ceil
; SKIP-DAG: Skipping VMP on unsupported_ceil_returns_twice: unsupported ceil
; SKIP-DAG: Skipping VMP on unsupported_lround_i32: unsupported lround
; SKIP-DAG: Skipping VMP on unsupported_fpclass_fastcc: unsupported is.fpclass
; SKIP-DAG: Skipping VMP on unsupported_sat_poison: unsupported fptosi.sat
; SKIP-DAG: Skipping VMP on unsupported_half_ceil_no_fullfp16: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_constrained_fadd_f32: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_as1_arg: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_sret: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected:
; SKIP-NOT: Skipping VMP on protected_more_round:
; SKIP-NOT: Skipping VMP on protected_canonicalize:
; SKIP-NOT: Skipping VMP on protected_int_round:
; SKIP-NOT: Skipping VMP on protected_sat:
; SKIP-NOT: Skipping VMP on protected_f64:
; SKIP-NOT: Skipping VMP on protected_half:
; SKIP-NOT: Skipping VMP on protected_fast_ceil:

; VIRT-LABEL: define i32 @protected(
; VIRT-SAME: #[[PROT:[0-9]+]]
; VIRT: vmp.dispatch:
; VIRT-DAG: call float @llvm.ceil.f32(
; VIRT-DAG: call float @llvm.floor.f32(
; VIRT-DAG: call float @llvm.trunc.f32(
; VIRT-DAG: call float @llvm.round.f32(
; VIRT-DAG: call i64 @llvm.lround.i64.f32(
; VIRT-DAG: call i1 @llvm.is.fpclass.f32({{.*}}, i32 2016)
; VIRT-DAG: call i32 @llvm.fptosi.sat.i32.f32(
; VIRT-LABEL: define float @protected_more_round(
; VIRT: vmp.dispatch:
; VIRT-DAG: call float @llvm.rint.f32(
; VIRT-DAG: call float @llvm.nearbyint.f32(
; VIRT-DAG: call float @llvm.roundeven.f32(
; VIRT-LABEL: define float @protected_canonicalize(
; VIRT: vmp.dispatch:
; VIRT: fmul
; VIRT-LABEL: define i64 @protected_int_round(
; VIRT: vmp.dispatch:
; VIRT-DAG: call i64 @llvm.llround.i64.f32(
; VIRT-DAG: call i64 @llvm.lrint.i64.f32(
; VIRT-DAG: call i64 @llvm.llrint.i64.f32(
; VIRT-LABEL: define i32 @protected_sat(
; VIRT: vmp.dispatch:
; VIRT-DAG: call i32 @llvm.fptoui.sat.i32.f32(
; VIRT-DAG: call i64 @llvm.fptosi.sat.i64.f32(
; VIRT-DAG: call i8 @llvm.fptosi.sat.i8.f32(
; VIRT-DAG: call i16 @llvm.fptoui.sat.i16.f32(
; VIRT-LABEL: define i64 @protected_f64(
; VIRT: vmp.dispatch:
; VIRT: call double @llvm.ceil.f64(
; VIRT-LABEL: define i32 @protected_half(
; VIRT-SAME: #[[PROTHALF:[0-9]+]]
; VIRT: vmp.dispatch:
; VIRT: call half @llvm.ceil.f16(
; VIRT-LABEL: define float @protected_fast_ceil(
; VIRT: vmp.dispatch:
; VIRT: call nnan ninf float @llvm.ceil.f32(
; VIRT: define {{.*}} @unsupported_ceil_malformed({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_ceil_musttail(
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call float @llvm.ceil.f32(
; VIRT-LABEL: define {{.*}} @unsupported_ceil_bundle(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_ceil_fastcc(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_ceil_poison(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_ceil_returns_twice(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_lround_i32(
; VIRT-NOT: vmp.dispatch
; VIRT: call i32 @llvm.lround.i32.f32(
; VIRT-LABEL: define {{.*}} @unsupported_fpclass_fastcc(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_sat_poison(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_half_ceil_no_fullfp16(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_constrained_fadd_f32(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_as1_arg(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_sret(
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[PROTHALF]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.selected"
; VIRT-NOT: attributes #[[PROTHALF]] = { {{.*}}"hikari.vmp.selected"

; AARCH64: Arch: aarch64
