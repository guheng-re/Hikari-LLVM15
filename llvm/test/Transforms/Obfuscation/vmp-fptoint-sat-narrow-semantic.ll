; Scalar llvm.fptosi.sat / llvm.fptoui.sat from f32/f64 to i8/i16 via
; the existing CallDescriptor path.  i32/i64 wrappers, vector sat
; convert, and ordinary fptosi/fptoui stay unchanged.  Well-shaped
; half sat without last-token +fullfp16 is an unsupported-target-feature
; skip (independent surface: vmp-half-sat-convert-semantic.ll).
; Finite inputs only: in-range, unsigned negative clamp-to-zero, and
; overflow saturation.  Ordinary tail accepted and replayed as TCK_None.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.ll > %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.live.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.ll > %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.live.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.s7.ll > %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.s7.live.ll > %t.o0.s7.host.ll
; RUN: lli -force-interpreter %t.o0.s7.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.s7.ll > %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.s7.live.ll > %t.o2.s7.host.ll
; RUN: lli -force-interpreter %t.o2.s7.host.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare i8 @llvm.fptosi.sat.i8.f32(float)
declare i8 @llvm.fptoui.sat.i8.f32(float)
declare i16 @llvm.fptosi.sat.i16.f32(float)
declare i16 @llvm.fptoui.sat.i16.f32(float)
declare i8 @llvm.fptosi.sat.i8.f64(double)
declare i8 @llvm.fptoui.sat.i8.f64(double)
declare i16 @llvm.fptosi.sat.i16.f64(double)
declare i16 @llvm.fptoui.sat.i16.f64(double)
declare i1 @llvm.fptosi.sat.i1.f32(float)
declare i8 @llvm.fptosi.sat.i8.f16(half)
declare i8 @llvm.experimental.constrained.fptosi.i8.f32(float, metadata)

define i8 @reference_fptosi_sat_i8_f32(float %x) {
entry:
  %r = call i8 @llvm.fptosi.sat.i8.f32(float %x)
  ret i8 %r
}

define i8 @protected_fptosi_sat_i8_f32(float %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i8 @llvm.fptosi.sat.i8.f32(float %x)
  ret i8 %r
}

define i8 @reference_fptoui_sat_i8_f32(float %x) {
entry:
  %r = call i8 @llvm.fptoui.sat.i8.f32(float %x)
  ret i8 %r
}

define i8 @protected_fptoui_sat_i8_f32(float %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i8 @llvm.fptoui.sat.i8.f32(float %x)
  ret i8 %r
}

define i16 @reference_fptosi_sat_i16_f32(float %x) {
entry:
  %r = call i16 @llvm.fptosi.sat.i16.f32(float %x)
  ret i16 %r
}

define i16 @protected_fptosi_sat_i16_f32(float %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i16 @llvm.fptosi.sat.i16.f32(float %x)
  ret i16 %r
}

define i16 @reference_fptoui_sat_i16_f32(float %x) {
entry:
  %r = call i16 @llvm.fptoui.sat.i16.f32(float %x)
  ret i16 %r
}

define i16 @protected_fptoui_sat_i16_f32(float %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i16 @llvm.fptoui.sat.i16.f32(float %x)
  ret i16 %r
}

define i8 @reference_fptosi_sat_i8_f64(double %x) {
entry:
  %r = call i8 @llvm.fptosi.sat.i8.f64(double %x)
  ret i8 %r
}

define i8 @protected_fptosi_sat_i8_f64(double %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i8 @llvm.fptosi.sat.i8.f64(double %x)
  ret i8 %r
}

define i8 @reference_fptoui_sat_i8_f64(double %x) {
entry:
  %r = call i8 @llvm.fptoui.sat.i8.f64(double %x)
  ret i8 %r
}

define i8 @protected_fptoui_sat_i8_f64(double %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i8 @llvm.fptoui.sat.i8.f64(double %x)
  ret i8 %r
}

define i16 @reference_fptosi_sat_i16_f64(double %x) {
entry:
  %r = call i16 @llvm.fptosi.sat.i16.f64(double %x)
  ret i16 %r
}

define i16 @protected_fptosi_sat_i16_f64(double %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i16 @llvm.fptosi.sat.i16.f64(double %x)
  ret i16 %r
}

define i16 @reference_fptoui_sat_i16_f64(double %x) {
entry:
  %r = call i16 @llvm.fptoui.sat.i16.f64(double %x)
  ret i16 %r
}

define i16 @protected_fptoui_sat_i16_f64(double %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i16 @llvm.fptoui.sat.i16.f64(double %x)
  ret i16 %r
}

define i8 @reference_fptosi_sat_i8_phi(float %a, float %b, i1 %c) {
entry:
  br i1 %c, label %left, label %right
left:
  %l = call i8 @llvm.fptosi.sat.i8.f32(float %a)
  br label %join
right:
  %r = call i8 @llvm.fptosi.sat.i8.f32(float %b)
  br label %join
join:
  %p = phi i8 [ %l, %left ], [ %r, %right ]
  ret i8 %p
}

define i8 @protected_fptosi_sat_i8_phi(float %a, float %b, i1 %c) noinline optnone {
entry:
  call void @hikari_vmp()
  br i1 %c, label %left, label %right
left:
  %l = call i8 @llvm.fptosi.sat.i8.f32(float %a)
  br label %join
right:
  %r = call i8 @llvm.fptosi.sat.i8.f32(float %b)
  br label %join
join:
  %p = phi i8 [ %l, %left ], [ %r, %right ]
  ret i8 %p
}

define i8 @reference_fptosi_sat_i8_loop(float %a, i32 %n) {
entry:
  br label %hdr
hdr:
  %acc = phi float [ %a, %entry ], [ %nxt, %hdr ]
  %i = phi i32 [ 0, %entry ], [ %i.nxt, %hdr ]
  %cur = call i8 @llvm.fptosi.sat.i8.f32(float %acc)
  %nxt = fadd float %acc, 1.000000e+00
  %i.nxt = add i32 %i, 1
  %more = icmp ult i32 %i.nxt, %n
  br i1 %more, label %hdr, label %done
done:
  ret i8 %cur
}

define i8 @protected_fptosi_sat_i8_loop(float %a, i32 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  br label %hdr
hdr:
  %acc = phi float [ %a, %entry ], [ %nxt, %hdr ]
  %i = phi i32 [ 0, %entry ], [ %i.nxt, %hdr ]
  %cur = call i8 @llvm.fptosi.sat.i8.f32(float %acc)
  %nxt = fadd float %acc, 1.000000e+00
  %i.nxt = add i32 %i, 1
  %more = icmp ult i32 %i.nxt, %n
  br i1 %more, label %hdr, label %done
done:
  ret i8 %cur
}

define i8 @reference_fptosi_sat_i8_tail(float %x) {
entry:
  %r = tail call i8 @llvm.fptosi.sat.i8.f32(float %x)
  ret i8 %r
}


define i1 @unsupported_narrow_sat_i1(float %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i1 @llvm.fptosi.sat.i1.f32(float %x)
  ret i1 %r
}

; Well-shaped half sat without last-token +fullfp16 is a feature skip.
define i8 @unsupported_narrow_sat_half(half %h) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i8 @llvm.fptosi.sat.i8.f16(half %h)
  ret i8 %r
}

define i8 @unsupported_narrow_sat_fastcc(float %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc i8 @llvm.fptosi.sat.i8.f32(float %x)
  ret i8 %r
}

define i8 @unsupported_narrow_sat_musttail(float %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call i8 @llvm.fptosi.sat.i8.f32(float %x)
  ret i8 %r
}

define i8 @unsupported_narrow_sat_bundle(float %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i8 @llvm.fptosi.sat.i8.f32(float %x) [ "deopt"(i32 0) ]
  ret i8 %r
}

; Well-shaped C constrained.fptosi.i8.f32 is now a supported convert
; surface.  fastcc keeps this a skip.
define i8 @unsupported_narrow_sat_constrained(float %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc i8 @llvm.experimental.constrained.fptosi.i8.f32(float %x, metadata !"fpexcept.ignore")
  ret i8 %r
}

define i8 @unsupported_narrow_sat_poison() noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i8 @llvm.fptosi.sat.i8.f32(float poison)
  ret i8 %r
}

define i32 @main() {
entry:
  %e0 = call i8 @reference_fptosi_sat_i8_f32(float 1.500000e+00)
  %a0 = call i8 @protected_fptosi_sat_i8_f32(float 1.500000e+00)
  %m0 = icmp eq i8 %e0, %a0

  %e1 = call i8 @reference_fptosi_sat_i8_f32(float -1.500000e+00)
  %a1 = call i8 @protected_fptosi_sat_i8_f32(float -1.500000e+00)
  %m1 = icmp eq i8 %e1, %a1

  %e2 = call i8 @reference_fptosi_sat_i8_f32(float 2.000000e+02)
  %a2 = call i8 @protected_fptosi_sat_i8_f32(float 2.000000e+02)
  %m2 = icmp eq i8 %e2, %a2

  %e3 = call i8 @reference_fptosi_sat_i8_f32(float -2.000000e+02)
  %a3 = call i8 @protected_fptosi_sat_i8_f32(float -2.000000e+02)
  %m3 = icmp eq i8 %e3, %a3

  %e4 = call i8 @reference_fptoui_sat_i8_f32(float 1.500000e+00)
  %a4 = call i8 @protected_fptoui_sat_i8_f32(float 1.500000e+00)
  %m4 = icmp eq i8 %e4, %a4

  %e5 = call i8 @reference_fptoui_sat_i8_f32(float -1.500000e+00)
  %a5 = call i8 @protected_fptoui_sat_i8_f32(float -1.500000e+00)
  %m5 = icmp eq i8 %e5, %a5

  %e6 = call i8 @reference_fptoui_sat_i8_f32(float 3.000000e+02)
  %a6 = call i8 @protected_fptoui_sat_i8_f32(float 3.000000e+02)
  %m6 = icmp eq i8 %e6, %a6

  %e7 = call i16 @reference_fptosi_sat_i16_f32(float 1.500000e+00)
  %a7 = call i16 @protected_fptosi_sat_i16_f32(float 1.500000e+00)
  %m7 = icmp eq i16 %e7, %a7

  %e8 = call i16 @reference_fptosi_sat_i16_f32(float 4.000000e+04)
  %a8 = call i16 @protected_fptosi_sat_i16_f32(float 4.000000e+04)
  %m8 = icmp eq i16 %e8, %a8

  %e9 = call i16 @reference_fptosi_sat_i16_f32(float -4.000000e+04)
  %a9 = call i16 @protected_fptosi_sat_i16_f32(float -4.000000e+04)
  %m9 = icmp eq i16 %e9, %a9

  %e10 = call i16 @reference_fptoui_sat_i16_f32(float -1.500000e+00)
  %a10 = call i16 @protected_fptoui_sat_i16_f32(float -1.500000e+00)
  %m10 = icmp eq i16 %e10, %a10

  %e11 = call i16 @reference_fptoui_sat_i16_f32(float 7.000000e+04)
  %a11 = call i16 @protected_fptoui_sat_i16_f32(float 7.000000e+04)
  %m11 = icmp eq i16 %e11, %a11

  %e12 = call i8 @reference_fptosi_sat_i8_f64(double 1.500000e+00)
  %a12 = call i8 @protected_fptosi_sat_i8_f64(double 1.500000e+00)
  %m12 = icmp eq i8 %e12, %a12

  %e13 = call i8 @reference_fptosi_sat_i8_f64(double -2.000000e+02)
  %a13 = call i8 @protected_fptosi_sat_i8_f64(double -2.000000e+02)
  %m13 = icmp eq i8 %e13, %a13

  %e14 = call i8 @reference_fptoui_sat_i8_f64(double -1.500000e+00)
  %a14 = call i8 @protected_fptoui_sat_i8_f64(double -1.500000e+00)
  %m14 = icmp eq i8 %e14, %a14

  %e15 = call i8 @reference_fptoui_sat_i8_f64(double 3.000000e+02)
  %a15 = call i8 @protected_fptoui_sat_i8_f64(double 3.000000e+02)
  %m15 = icmp eq i8 %e15, %a15

  %e16 = call i16 @reference_fptosi_sat_i16_f64(double 1.500000e+00)
  %a16 = call i16 @protected_fptosi_sat_i16_f64(double 1.500000e+00)
  %m16 = icmp eq i16 %e16, %a16

  %e17 = call i16 @reference_fptosi_sat_i16_f64(double -4.000000e+04)
  %a17 = call i16 @protected_fptosi_sat_i16_f64(double -4.000000e+04)
  %m17 = icmp eq i16 %e17, %a17

  %e18 = call i16 @reference_fptoui_sat_i16_f64(double -1.500000e+00)
  %a18 = call i16 @protected_fptoui_sat_i16_f64(double -1.500000e+00)
  %m18 = icmp eq i16 %e18, %a18

  %e19 = call i16 @reference_fptoui_sat_i16_f64(double 7.000000e+04)
  %a19 = call i16 @protected_fptoui_sat_i16_f64(double 7.000000e+04)
  %m19 = icmp eq i16 %e19, %a19

  %e20 = call i8 @reference_fptosi_sat_i8_phi(float 1.500000e+00, float 2.000000e+02, i1 true)
  %a20 = call i8 @protected_fptosi_sat_i8_phi(float 1.500000e+00, float 2.000000e+02, i1 true)
  %m20 = icmp eq i8 %e20, %a20

  %e21 = call i8 @reference_fptosi_sat_i8_phi(float 1.500000e+00, float 2.000000e+02, i1 false)
  %a21 = call i8 @protected_fptosi_sat_i8_phi(float 1.500000e+00, float 2.000000e+02, i1 false)
  %m21 = icmp eq i8 %e21, %a21

  %e22 = call i8 @reference_fptosi_sat_i8_loop(float 1.500000e+00, i32 2)
  %a22 = call i8 @protected_fptosi_sat_i8_loop(float 1.500000e+00, i32 2)
  %m22 = icmp eq i8 %e22, %a22

  %t0 = and i1 %m0, %m1
  %t1 = and i1 %m2, %m3
  %t2 = and i1 %m4, %m5
  %t3 = and i1 %m6, %m7
  %t4 = and i1 %m8, %m9
  %t5 = and i1 %m10, %m11
  %t6 = and i1 %m12, %m13
  %t7 = and i1 %m14, %m15
  %t8 = and i1 %m16, %m17
  %t9 = and i1 %m18, %m19
  %t10 = and i1 %m20, %m21
  %u0 = and i1 %t0, %t1
  %u1 = and i1 %t2, %t3
  %u2 = and i1 %t4, %t5
  %u3 = and i1 %t6, %t7
  %u4 = and i1 %t8, %t9
  %u5 = and i1 %t10, %m22
  %v0 = and i1 %u0, %u1
  %v1 = and i1 %u2, %u3
  %v2 = and i1 %u4, %u5
  %w0 = and i1 %v0, %v1
  %ok = and i1 %w0, %v2
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_narrow_sat_i1: unsupported fptosi.sat
; SKIP-DAG: Skipping VMP on unsupported_narrow_sat_half: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_narrow_sat_fastcc: unsupported fptosi.sat
; SKIP-DAG: Skipping VMP on unsupported_narrow_sat_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_narrow_sat_bundle: unsupported fptosi.sat
; SKIP-DAG: Skipping VMP on unsupported_narrow_sat_constrained: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_narrow_sat_poison: unsupported fptosi.sat
; SKIP-NOT: Skipping VMP on protected_fptosi_sat_i8_f32:
; SKIP-NOT: Skipping VMP on protected_fptoui_sat_i8_f32:
; SKIP-NOT: Skipping VMP on protected_fptosi_sat_i16_f32:
; SKIP-NOT: Skipping VMP on protected_fptoui_sat_i16_f32:
; SKIP-NOT: Skipping VMP on protected_fptosi_sat_i8_f64:
; SKIP-NOT: Skipping VMP on protected_fptoui_sat_i8_f64:
; SKIP-NOT: Skipping VMP on protected_fptosi_sat_i16_f64:
; SKIP-NOT: Skipping VMP on protected_fptoui_sat_i16_f64:
; SKIP-NOT: Skipping VMP on protected_fptosi_sat_i8_phi:
; SKIP-NOT: Skipping VMP on protected_fptosi_sat_i8_loop:

; VIRT: define i8 @protected_fptosi_sat_i8_f32({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call i8 @llvm.fptosi.sat.i8.f32(
; VIRT: define i8 @protected_fptoui_sat_i8_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i8 @llvm.fptoui.sat.i8.f32(
; VIRT: define i16 @protected_fptosi_sat_i16_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i16 @llvm.fptosi.sat.i16.f32(
; VIRT: define i16 @protected_fptoui_sat_i16_f32({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i16 @llvm.fptoui.sat.i16.f32(
; VIRT: define i8 @protected_fptosi_sat_i8_f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i8 @llvm.fptosi.sat.i8.f64(
; VIRT: define i8 @protected_fptoui_sat_i8_f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i8 @llvm.fptoui.sat.i8.f64(
; VIRT: define i16 @protected_fptosi_sat_i16_f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i16 @llvm.fptosi.sat.i16.f64(
; VIRT: define i16 @protected_fptoui_sat_i16_f64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i16 @llvm.fptoui.sat.i16.f64(
; VIRT: define i8 @protected_fptosi_sat_i8_phi({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i8 @llvm.fptosi.sat.i8.f32(
; VIRT: define i8 @protected_fptosi_sat_i8_loop({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i8 @llvm.fptosi.sat.i8.f32(
; VIRT: define {{.*}} @unsupported_narrow_sat_i1({{.*}} #[[UNSUPATTR:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_narrow_sat_half({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_narrow_sat_fastcc({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_narrow_sat_musttail({{.*}} #[[UNSUP_MT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call i8 @llvm.fptosi.sat.i8.f32(
; VIRT: define {{.*}} @unsupported_narrow_sat_bundle({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call i8 @llvm.fptosi.sat.i8.f32({{.*}}[ "deopt"(i32 0) ]
; VIRT: define {{.*}} @unsupported_narrow_sat_constrained({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call fastcc i8 @llvm.experimental.constrained.fptosi.i8.f32(
; VIRT: define {{.*}} @unsupported_narrow_sat_poison({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP_MT]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
