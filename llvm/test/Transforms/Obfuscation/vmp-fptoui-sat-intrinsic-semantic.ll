; Scalar llvm.fptoui.sat.i32.f32 via normal Call path (float arg VReg, i32 result
; VReg).  Saturating toward-zero unsigned conversion; no dedicated VM opcode.
;
; RUN: opt -S -verify-each -aesSeed=145 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.ll -o %t.o0.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=145 -passes='default<O2>' %s -o %t.o2.ll
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.ll -o %t.o2.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare i32 @llvm.fptoui.sat.i32.f32(float)

; Bit-pattern i32 input: bitcast to float, fptoui.sat to i32 bit pattern.
define i32 @reference_fptoui_sat(i32 %bits) {
entry:
  %a = bitcast i32 %bits to float
  %r = call i32 @llvm.fptoui.sat.i32.f32(float %a)
  ret i32 %r
}

define i32 @protected_fptoui_sat(i32 %bits) noinline optnone {
entry:
  call void @hikari_vmp()
  %a = bitcast i32 %bits to float
  %r = call i32 @llvm.fptoui.sat.i32.f32(float %a)
  ret i32 %r
}

define i32 @main() {
entry:
  ; +1.5  bits 0x3fc00000 -> toward zero -> 1
  %e0 = call i32 @reference_fptoui_sat(i32 1069547520)
  %a0 = call i32 @protected_fptoui_sat(i32 1069547520)
  ; -1.5  bits 0xbfc00000 -> negative clamps to 0
  %e1 = call i32 @reference_fptoui_sat(i32 -1077936128)
  %a1 = call i32 @protected_fptoui_sat(i32 -1077936128)
  ; +4.2949673e9  bits 0x4f800000 -> positive overflow sat -> UINT_MAX
  %e2 = call i32 @reference_fptoui_sat(i32 1333788672)
  %a2 = call i32 @protected_fptoui_sat(i32 1333788672)
  ; +inf bits 0x7f800000 -> UINT_MAX
  %e3 = call i32 @reference_fptoui_sat(i32 2139095040)
  %a3 = call i32 @protected_fptoui_sat(i32 2139095040)
  ; -inf bits 0xff800000 -> 0
  %e4 = call i32 @reference_fptoui_sat(i32 -8388608)
  %a4 = call i32 @protected_fptoui_sat(i32 -8388608)
  ; quiet NaN bits 0x7fc00000 -> 0
  %e5 = call i32 @reference_fptoui_sat(i32 2143289344)
  %a5 = call i32 @protected_fptoui_sat(i32 2143289344)
  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %e1, %a1
  %m2 = icmp eq i32 %e2, %a2
  %m3 = icmp eq i32 %e3, %a3
  %m4 = icmp eq i32 %e4, %a4
  %m5 = icmp eq i32 %e5, %a5
  %t0 = and i1 %m0, %m1
  %t1 = and i1 %t0, %m2
  %t2 = and i1 %t1, %m3
  %t3 = and i1 %t2, %m4
  %ok = and i1 %t3, %m5
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with: 145
; SKIP-NOT: Skipping VMP on protected_fptoui_sat:

; VIRT-LABEL: define i32 @protected_fptoui_sat(
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.fptoui.sat.i32.f32(

; VIRT: attributes{{.*}}"hikari.vmp.virtualized"
