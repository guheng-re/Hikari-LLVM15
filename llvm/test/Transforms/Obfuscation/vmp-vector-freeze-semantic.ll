; Restricted fixed-vector freeze: VectorFreeze opcode, native CreateFreeze,
; packVectorVariant carries type + FreezeSourceKind.  Defined integer/float
; vectors are compared; direct undef/poison vector freeze is virtualized
; but not executed.  Scalable and pointer-vector freeze stay skipped.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.ll > %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.live.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.ll > %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.live.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.s7.ll > %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.s7.live.ll > %t.o0.s7.host.ll
; RUN: lli -force-interpreter %t.o0.s7.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.s7.ll > %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.s7.live.ll > %t.o2.s7.host.ll
; RUN: lli -force-interpreter %t.o2.s7.host.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()

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

define i32 @reference(<4 x i32> %a, <2 x float> %b) noinline optnone {
entry:
  %fa = freeze <4 x i32> %a
  %s = add <4 x i32> %fa, %a
  %fs = freeze <4 x i32> %s
  %fb = freeze <2 x float> %b
  %bits = bitcast <2 x float> %fb to <2 x i32>
  %e0 = extractelement <2 x i32> %bits, i32 0
  %e1 = extractelement <2 x i32> %bits, i32 1
  %fx = xor i32 %e0, %e1
  %ir = call i32 @fold_i32x4(<4 x i32> %fs)
  %out = xor i32 %ir, %fx
  ret i32 %out
}

define i32 @protected(<4 x i32> %a, <2 x float> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %fa = freeze <4 x i32> %a
  %s = add <4 x i32> %fa, %a
  %fs = freeze <4 x i32> %s
  %fb = freeze <2 x float> %b
  %bits = bitcast <2 x float> %fb to <2 x i32>
  %e0 = extractelement <2 x i32> %bits, i32 0
  %e1 = extractelement <2 x i32> %bits, i32 1
  %fx = xor i32 %e0, %e1
  %ir = call i32 @fold_i32x4(<4 x i32> %fs)
  %out = xor i32 %ir, %fx
  ret i32 %out
}

; Not called from main: FileCheck only.
define <4 x i32> @protected_vec_freeze_undef() noinline optnone {
entry:
  call void @hikari_vmp()
  %v = freeze <4 x i32> undef
  ret <4 x i32> %v
}

define <2 x float> @protected_vec_freeze_poison() noinline optnone {
entry:
  call void @hikari_vmp()
  %v = freeze <2 x float> poison
  ret <2 x float> %v
}

define i32 @unsupported_scalable_freeze() noinline optnone {
entry:
  call void @hikari_vmp()
  %f = freeze <vscale x 2 x i32> zeroinitializer
  ret i32 0
}

define i32 @unsupported_ptrvec_freeze() noinline optnone {
entry:
  call void @hikari_vmp()
  %f = freeze <2 x ptr> zeroinitializer
  ret i32 0
}

define i32 @main() {
entry:
  %a0 = insertelement <4 x i32> poison, i32 1, i32 0
  %a1 = insertelement <4 x i32> %a0, i32 2, i32 1
  %a2 = insertelement <4 x i32> %a1, i32 3, i32 2
  %a3 = insertelement <4 x i32> %a2, i32 4, i32 3
  %b0 = insertelement <2 x float> poison, float 1.500000e+00, i32 0
  %b1 = insertelement <2 x float> %b0, float 2.250000e+00, i32 1
  %e0 = call i32 @reference(<4 x i32> %a3, <2 x float> %b1)
  %p0 = call i32 @protected(<4 x i32> %a3, <2 x float> %b1)
  %ok0 = icmp eq i32 %e0, %p0
  %c0 = insertelement <4 x i32> poison, i32 -3, i32 0
  %c1 = insertelement <4 x i32> %c0, i32 8, i32 1
  %c2 = insertelement <4 x i32> %c1, i32 0, i32 2
  %c3 = insertelement <4 x i32> %c2, i32 11, i32 3
  %d0 = insertelement <2 x float> poison, float -0.000000e+00, i32 0
  %d1 = insertelement <2 x float> %d0, float 4.000000e+00, i32 1
  %e1 = call i32 @reference(<4 x i32> %c3, <2 x float> %d1)
  %p1 = call i32 @protected(<4 x i32> %c3, <2 x float> %d1)
  %ok1 = icmp eq i32 %e1, %p1
  %ok = and i1 %ok0, %ok1
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP-DAG: Skipping VMP on unsupported_scalable_freeze: unsupported freeze instruction
; SKIP-DAG: Skipping VMP on unsupported_ptrvec_freeze: unsupported freeze instruction
; SKIP-NOT: Skipping VMP on protected:
; SKIP-NOT: Skipping VMP on protected_vec_freeze_undef:
; SKIP-NOT: Skipping VMP on protected_vec_freeze_poison:

; VIRT-LABEL: define i32 @protected(
; VIRT: %vmp.vregs = alloca [{{[0-9]+}} x i128]
; VIRT: vmp.dispatch:
; VIRT-DAG: freeze <4 x i32>
; VIRT-DAG: freeze <2 x float>
; VIRT-DAG: add <4 x i32>

; VIRT-LABEL: define <4 x i32> @protected_vec_freeze_undef(
; VIRT: vmp.dispatch:
; VIRT: freeze <4 x i32> undef

; VIRT-LABEL: define <2 x float> @protected_vec_freeze_poison(
; VIRT: vmp.dispatch:
; VIRT: freeze <2 x float> poison

; VIRT: define {{.*}} @unsupported_scalable_freeze({{.*}} #[[UNSUPATTR:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ptrvec_freeze({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #{{[0-9]+}} = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.virtualized"