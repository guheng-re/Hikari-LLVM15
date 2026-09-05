; Restricted SVE llvm.vector.reduce.* on full-register types: last-token
; +sve; nxv16i8 / nxv8i16 / nxv4i32 / nxv2i64 integer add/and/or/xor/
; smin/smax/umin/umax; nxv4f32 / nxv2f64 fadd/fmin/fmax; nxv8f16 also
; last-token +fullfp16.  Vector on nxv16i8 frame; scalar dest on the
; integer or float frame.  Rebuilt as the same intrinsic (not
; CallDescriptor).  mul/fmul stay skipped (LLVM 15 ISel "Expanding
; reductions for scalable vectors is undefined").  Host cannot execute
; AArch64 SVE.  FileCheck + AArch64 llc/readobj/asm (llc: -mattr=+sve,
; +fullfp16 -fast-isel=false).  O0/O2 x 97/7.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.ll > %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+sve,+fullfp16 -fast-isel=false -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+sve,+fullfp16 -fast-isel=false %t.o0.live.ll -o - | FileCheck %s --check-prefix=ASM
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.ll > %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+sve,+fullfp16 -fast-isel=false -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+sve,+fullfp16 -fast-isel=false %t.o2.live.ll -o - | FileCheck %s --check-prefix=ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.s7.ll > %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+sve,+fullfp16 -fast-isel=false -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+sve,+fullfp16 -fast-isel=false %t.o0.s7.live.ll -o - | FileCheck %s --check-prefix=ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.s7.ll > %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+sve,+fullfp16 -fast-isel=false -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+sve,+fullfp16 -fast-isel=false %t.o2.s7.live.ll -o - | FileCheck %s --check-prefix=ASM
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %s | opt -S -verify-each -aesSeed=97 -passes='default<O0>' - 2>&1 | FileCheck %s --check-prefix=HOST
; RUN: opt -S -verify-each -aesSeed=97 -vmp-max-bytecode-words=1 -passes='default<O0>' %s -o %t.budget.ll 2>%t.budget.err
; RUN: FileCheck %s --check-prefix=BUDGET-ERR < %t.budget.err
; RUN: FileCheck %s --check-prefix=BUDGET-IR < %t.budget.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare i8 @llvm.vector.reduce.add.nxv16i8(<vscale x 16 x i8>)
declare i16 @llvm.vector.reduce.add.nxv8i16(<vscale x 8 x i16>)
declare i32 @llvm.vector.reduce.add.nxv4i32(<vscale x 4 x i32>)
declare i32 @llvm.vector.reduce.and.nxv4i32(<vscale x 4 x i32>)
declare i32 @llvm.vector.reduce.or.nxv4i32(<vscale x 4 x i32>)
declare i32 @llvm.vector.reduce.xor.nxv4i32(<vscale x 4 x i32>)
declare i32 @llvm.vector.reduce.smin.nxv4i32(<vscale x 4 x i32>)
declare i32 @llvm.vector.reduce.smax.nxv4i32(<vscale x 4 x i32>)
declare i32 @llvm.vector.reduce.umin.nxv4i32(<vscale x 4 x i32>)
declare i32 @llvm.vector.reduce.umax.nxv4i32(<vscale x 4 x i32>)
declare i32 @llvm.vector.reduce.mul.nxv4i32(<vscale x 4 x i32>)
declare i64 @llvm.vector.reduce.add.nxv2i64(<vscale x 2 x i64>)
declare i64 @llvm.vector.reduce.smin.nxv2i64(<vscale x 2 x i64>)
declare float @llvm.vector.reduce.fadd.nxv4f32(float, <vscale x 4 x float>)
declare float @llvm.vector.reduce.fmin.nxv4f32(<vscale x 4 x float>)
declare float @llvm.vector.reduce.fmax.nxv4f32(<vscale x 4 x float>)
declare float @llvm.vector.reduce.fmul.nxv4f32(float, <vscale x 4 x float>)
declare double @llvm.vector.reduce.fadd.nxv2f64(double, <vscale x 2 x double>)
declare half @llvm.vector.reduce.fadd.nxv8f16(half, <vscale x 8 x half>)
declare half @llvm.vector.reduce.fmin.nxv8f16(<vscale x 8 x half>)

define i32 @protected_add_i32(<vscale x 4 x i32> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.vector.reduce.add.nxv4i32(<vscale x 4 x i32> %a)
  ret i32 %r
}

define i32 @protected_and_i32(<vscale x 4 x i32> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.vector.reduce.and.nxv4i32(<vscale x 4 x i32> %a)
  ret i32 %r
}

define i32 @protected_or_i32(<vscale x 4 x i32> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.vector.reduce.or.nxv4i32(<vscale x 4 x i32> %a)
  ret i32 %r
}

define i32 @protected_xor_i32(<vscale x 4 x i32> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.vector.reduce.xor.nxv4i32(<vscale x 4 x i32> %a)
  ret i32 %r
}

define i32 @protected_smin_i32(<vscale x 4 x i32> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.vector.reduce.smin.nxv4i32(<vscale x 4 x i32> %a)
  ret i32 %r
}

define i32 @protected_smax_i32(<vscale x 4 x i32> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.vector.reduce.smax.nxv4i32(<vscale x 4 x i32> %a)
  ret i32 %r
}

define i32 @protected_umin_i32(<vscale x 4 x i32> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.vector.reduce.umin.nxv4i32(<vscale x 4 x i32> %a)
  ret i32 %r
}

define i32 @protected_umax_i32(<vscale x 4 x i32> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.vector.reduce.umax.nxv4i32(<vscale x 4 x i32> %a)
  ret i32 %r
}

define i8 @protected_add_i8(<vscale x 16 x i8> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call i8 @llvm.vector.reduce.add.nxv16i8(<vscale x 16 x i8> %a)
  ret i8 %r
}

define i16 @protected_add_i16(<vscale x 8 x i16> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call i16 @llvm.vector.reduce.add.nxv8i16(<vscale x 8 x i16> %a)
  ret i16 %r
}

define i64 @protected_add_i64(<vscale x 2 x i64> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.vector.reduce.add.nxv2i64(<vscale x 2 x i64> %a)
  ret i64 %r
}

define i64 @protected_smin_i64(<vscale x 2 x i64> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.vector.reduce.smin.nxv2i64(<vscale x 2 x i64> %a)
  ret i64 %r
}

define float @protected_fadd_f32(float %s, <vscale x 4 x float> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.vector.reduce.fadd.nxv4f32(float %s, <vscale x 4 x float> %a)
  ret float %r
}

define float @protected_fmin_f32(<vscale x 4 x float> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.vector.reduce.fmin.nxv4f32(<vscale x 4 x float> %a)
  ret float %r
}

define float @protected_fmax_f32(<vscale x 4 x float> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.vector.reduce.fmax.nxv4f32(<vscale x 4 x float> %a)
  ret float %r
}

define double @protected_fadd_f64(double %s, <vscale x 2 x double> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call double @llvm.vector.reduce.fadd.nxv2f64(double %s, <vscale x 2 x double> %a)
  ret double %r
}

define half @protected_fadd_f16(half %s, <vscale x 8 x half> %a) noinline optnone "target-features"="+sve,+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.vector.reduce.fadd.nxv8f16(half %s, <vscale x 8 x half> %a)
  ret half %r
}

define half @protected_fmin_f16(<vscale x 8 x half> %a) noinline optnone "target-features"="+sve,+fullfp16" {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.vector.reduce.fmin.nxv8f16(<vscale x 8 x half> %a)
  ret half %r
}

define i32 @unsupported_nofeat(<vscale x 4 x i32> %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.vector.reduce.add.nxv4i32(<vscale x 4 x i32> %a)
  ret i32 %r
}

define i32 @unsupported_internal_nofeat(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %a = load <vscale x 4 x i32>, ptr %p, align 16
  %r = call i32 @llvm.vector.reduce.add.nxv4i32(<vscale x 4 x i32> %a)
  ret i32 %r
}

define i32 @unsupported_half_nofp16(ptr %p) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %a = load <vscale x 8 x half>, ptr %p, align 16
  %r = call half @llvm.vector.reduce.fadd.nxv8f16(half 0xH0000, <vscale x 8 x half> %a)
  ret i32 0
}

define i32 @unsupported_mul(ptr %p) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %a = load <vscale x 4 x i32>, ptr %p, align 16
  %r = call i32 @llvm.vector.reduce.mul.nxv4i32(<vscale x 4 x i32> %a)
  ret i32 %r
}

define i32 @unsupported_fmul(ptr %p) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %a = load <vscale x 4 x float>, ptr %p, align 16
  %r = call float @llvm.vector.reduce.fmul.nxv4f32(float 1.0, <vscale x 4 x float> %a)
  ret i32 0
}

define i32 @unsupported_poison(<vscale x 4 x i32> %a) noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.vector.reduce.add.nxv4i32(<vscale x 4 x i32> poison)
  ret i32 %r
}

define void @main() {
entry:
  ret void
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_nofeat: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_internal_nofeat: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_half_nofp16: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_mul: unsupported vector reduce instruction
; SKIP-DAG: Skipping VMP on unsupported_fmul: unsupported vector reduce instruction
; SKIP-DAG: Skipping VMP on unsupported_poison: unsupported vector reduce instruction
; SKIP-NOT: Skipping VMP on protected_add_i32:
; SKIP-NOT: Skipping VMP on protected_and_i32:
; SKIP-NOT: Skipping VMP on protected_or_i32:
; SKIP-NOT: Skipping VMP on protected_xor_i32:
; SKIP-NOT: Skipping VMP on protected_smin_i32:
; SKIP-NOT: Skipping VMP on protected_smax_i32:
; SKIP-NOT: Skipping VMP on protected_umin_i32:
; SKIP-NOT: Skipping VMP on protected_umax_i32:
; SKIP-NOT: Skipping VMP on protected_add_i8:
; SKIP-NOT: Skipping VMP on protected_add_i16:
; SKIP-NOT: Skipping VMP on protected_add_i64:
; SKIP-NOT: Skipping VMP on protected_smin_i64:
; SKIP-NOT: Skipping VMP on protected_fadd_f32:
; SKIP-NOT: Skipping VMP on protected_fmin_f32:
; SKIP-NOT: Skipping VMP on protected_fmax_f32:
; SKIP-NOT: Skipping VMP on protected_fadd_f64:
; SKIP-NOT: Skipping VMP on protected_fadd_f16:
; SKIP-NOT: Skipping VMP on protected_fmin_f16:

; VIRT-LABEL: define i32 @protected_add_i32(
; VIRT-SAME: #[[PROT:[0-9]+]]
; VIRT: vmp.sve.regs
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.vector.reduce.add.nxv4i32(
; VIRT-LABEL: define i32 @protected_and_i32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.vector.reduce.and.nxv4i32(
; VIRT-LABEL: define i32 @protected_or_i32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.vector.reduce.or.nxv4i32(
; VIRT-LABEL: define i32 @protected_xor_i32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.vector.reduce.xor.nxv4i32(
; VIRT-LABEL: define i32 @protected_smin_i32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.vector.reduce.smin.nxv4i32(
; VIRT-LABEL: define i32 @protected_smax_i32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.vector.reduce.smax.nxv4i32(
; VIRT-LABEL: define i32 @protected_umin_i32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.vector.reduce.umin.nxv4i32(
; VIRT-LABEL: define i32 @protected_umax_i32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.vector.reduce.umax.nxv4i32(
; VIRT-LABEL: define i8 @protected_add_i8(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call i8 @llvm.vector.reduce.add.nxv16i8(
; VIRT-LABEL: define i16 @protected_add_i16(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call i16 @llvm.vector.reduce.add.nxv8i16(
; VIRT-LABEL: define i64 @protected_add_i64(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.vector.reduce.add.nxv2i64(
; VIRT-LABEL: define i64 @protected_smin_i64(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.vector.reduce.smin.nxv2i64(
; VIRT-LABEL: define float @protected_fadd_f32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.vector.reduce.fadd.nxv4f32(
; VIRT-LABEL: define float @protected_fmin_f32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.vector.reduce.fmin.nxv4f32(
; VIRT-LABEL: define float @protected_fmax_f32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call float @llvm.vector.reduce.fmax.nxv4f32(
; VIRT-LABEL: define double @protected_fadd_f64(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call double @llvm.vector.reduce.fadd.nxv2f64(
; VIRT-LABEL: define half @protected_fadd_f16(
; VIRT-SAME: #[[PROTHALF:[0-9]+]]
; VIRT: vmp.dispatch:
; VIRT: call half @llvm.vector.reduce.fadd.nxv8f16(
; VIRT-LABEL: define half @protected_fmin_f16(
; VIRT-SAME: #[[PROTHALF]]
; VIRT: vmp.dispatch:
; VIRT: call half @llvm.vector.reduce.fmin.nxv8f16(
; VIRT: define {{.*}} @unsupported_nofeat({{.*}} #[[UNSUP:[0-9]+]]
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[PROTHALF]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; ASM-DAG: uaddv{{.*}}z{{[0-9]+}}.s
; ASM-DAG: andv{{.*}}z{{[0-9]+}}.s
; ASM-DAG: orv{{.*}}z{{[0-9]+}}.s
; ASM-DAG: eorv{{.*}}z{{[0-9]+}}.s
; ASM-DAG: sminv{{.*}}z{{[0-9]+}}.s
; ASM-DAG: smaxv{{.*}}z{{[0-9]+}}.s
; ASM-DAG: uminv{{.*}}z{{[0-9]+}}.s
; ASM-DAG: umaxv{{.*}}z{{[0-9]+}}.s
; ASM-DAG: uaddv{{.*}}z{{[0-9]+}}.b
; ASM-DAG: uaddv{{.*}}z{{[0-9]+}}.h
; ASM-DAG: uaddv{{.*}}z{{[0-9]+}}.d
; ASM-DAG: sminv{{.*}}z{{[0-9]+}}.d
; ASM-DAG: fadda{{.*}}z{{[0-9]+}}.s
; ASM-DAG: fminnmv{{.*}}z{{[0-9]+}}.s
; ASM-DAG: fmaxnmv{{.*}}z{{[0-9]+}}.s
; ASM-DAG: fadda{{.*}}z{{[0-9]+}}.d
; ASM-DAG: fadda{{.*}}z{{[0-9]+}}.h
; ASM-DAG: fminnmv{{.*}}z{{[0-9]+}}.h
; HOST: Skipping VMP: only AArch64 targets are supported
; BUDGET-ERR: Skipping VMP on protected_add_i32: bytecode word budget
; BUDGET-IR-LABEL: define i32 @protected_add_i32(
; BUDGET-IR-NOT: vmp.dispatch
; BUDGET-IR: call i32 @llvm.vector.reduce.add.nxv4i32(
