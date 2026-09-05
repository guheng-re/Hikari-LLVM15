; Scalar llvm.lrint.i64.f32 via normal Call path (float arg VReg, i64 result VReg).
; Rounding follows the current rounding mode (default FE_TONEAREST).  No dedicated
; VM opcode.
;
; RUN: opt -S -verify-each -aesSeed=111 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.ll -o %t.o0.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=111 -passes='default<O2>' %s -o %t.o2.ll
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.ll -o %t.o2.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare i64 @llvm.lrint.i64.f32(float)

; Bit-pattern i32 input: bitcast to float, lrint to i64.
define i64 @reference_lrint(i32 %bits) {
entry:
  %a = bitcast i32 %bits to float
  %r = call i64 @llvm.lrint.i64.f32(float %a)
  ret i64 %r
}

define i64 @protected_lrint(i32 %bits) noinline optnone {
entry:
  call void @hikari_vmp()
  %a = bitcast i32 %bits to float
  %r = call i64 @llvm.lrint.i64.f32(float %a)
  ret i64 %r
}

define i32 @main() {
entry:
  ; +0.5  bits 0x3f000000 (default round-to-nearest, even-ties may apply)
  %e0 = call i64 @reference_lrint(i32 1056964608)
  %a0 = call i64 @protected_lrint(i32 1056964608)
  ; -0.5  bits 0xbf000000
  %e1 = call i64 @reference_lrint(i32 -1090519040)
  %a1 = call i64 @protected_lrint(i32 -1090519040)
  ; +1.5  bits 0x3fc00000
  %e2 = call i64 @reference_lrint(i32 1069547520)
  %a2 = call i64 @protected_lrint(i32 1069547520)
  ; -1.5  bits 0xbfc00000
  %e3 = call i64 @reference_lrint(i32 -1077936128)
  %a3 = call i64 @protected_lrint(i32 -1077936128)
  ; +0.0 bits 0
  %e4 = call i64 @reference_lrint(i32 0)
  %a4 = call i64 @protected_lrint(i32 0)
  ; -0.0 bits 0x80000000
  %e5 = call i64 @reference_lrint(i32 -2147483648)
  %a5 = call i64 @protected_lrint(i32 -2147483648)
  %m0 = icmp eq i64 %e0, %a0
  %m1 = icmp eq i64 %e1, %a1
  %m2 = icmp eq i64 %e2, %a2
  %m3 = icmp eq i64 %e3, %a3
  %m4 = icmp eq i64 %e4, %a4
  %m5 = icmp eq i64 %e5, %a5
  %t0 = and i1 %m0, %m1
  %t1 = and i1 %t0, %m2
  %t2 = and i1 %t1, %m3
  %t3 = and i1 %t2, %m4
  %ok = and i1 %t3, %m5
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with: 111
; SKIP-NOT: Skipping VMP on protected_lrint:

; VIRT-LABEL: define i64 @protected_lrint(
; VIRT: vmp.dispatch:
; VIRT: call i64 @llvm.lrint.i64.f32(

; VIRT: attributes{{.*}}"hikari.vmp.virtualized"
