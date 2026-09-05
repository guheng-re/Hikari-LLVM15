; RUN: opt -S -verify-each -aesSeed=73 -passes='default<O0>' %s -o %t.o0.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=73 -passes='default<O2>' %s -o %t.o2.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: FileCheck %s < %t.o0.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare i8 @llvm.ctpop.i8(i8)
declare i8 @llvm.ctlz.i8(i8, i1 immarg)
declare i8 @llvm.cttz.i8(i8, i1 immarg)
declare i32 @llvm.ctpop.i32(i32)
declare i32 @llvm.ctlz.i32(i32, i1 immarg)
declare i32 @llvm.cttz.i32(i32, i1 immarg)

; Covers ctpop + ctlz/cttz on i8 and i32.
; Zero input only uses is_zero_undef=false (true would be poison).
define i32 @reference(i32 %x) {
entry:
  %x8 = trunc i32 %x to i8
  %pop8 = call i8 @llvm.ctpop.i8(i8 %x8)
  %lz8.z = call i8 @llvm.ctlz.i8(i8 0, i1 false)
  %tz8.z = call i8 @llvm.cttz.i8(i8 0, i1 false)
  %lz8 = call i8 @llvm.ctlz.i8(i8 %x8, i1 false)
  %tz8 = call i8 @llvm.cttz.i8(i8 %x8, i1 false)
  %pop32 = call i32 @llvm.ctpop.i32(i32 %x)
  %lz32.z = call i32 @llvm.ctlz.i32(i32 0, i1 false)
  %tz32.z = call i32 @llvm.cttz.i32(i32 0, i1 false)
  %lz32 = call i32 @llvm.ctlz.i32(i32 %x, i1 false)
  %tz32 = call i32 @llvm.cttz.i32(i32 %x, i1 false)
  %pop8.z = zext i8 %pop8 to i32
  %lz8.z.z = zext i8 %lz8.z to i32
  %tz8.z.z = zext i8 %tz8.z to i32
  %lz8.e = zext i8 %lz8 to i32
  %tz8.e = zext i8 %tz8 to i32
  %m0 = xor i32 %pop8.z, %lz8.z.z
  %m1 = xor i32 %tz8.z.z, %lz8.e
  %m2 = xor i32 %tz8.e, %pop32
  %m3 = xor i32 %lz32.z, %tz32.z
  %m4 = xor i32 %lz32, %tz32
  %t0 = xor i32 %m0, %m1
  %t1 = xor i32 %m2, %m3
  %t2 = xor i32 %t0, %t1
  %result = xor i32 %t2, %m4
  ret i32 %result
}

define i32 @protected(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %x8 = trunc i32 %x to i8
  %pop8 = call i8 @llvm.ctpop.i8(i8 %x8)
  %lz8.z = call i8 @llvm.ctlz.i8(i8 0, i1 false)
  %tz8.z = call i8 @llvm.cttz.i8(i8 0, i1 false)
  %lz8 = call i8 @llvm.ctlz.i8(i8 %x8, i1 false)
  %tz8 = call i8 @llvm.cttz.i8(i8 %x8, i1 false)
  %pop32 = call i32 @llvm.ctpop.i32(i32 %x)
  %lz32.z = call i32 @llvm.ctlz.i32(i32 0, i1 false)
  %tz32.z = call i32 @llvm.cttz.i32(i32 0, i1 false)
  %lz32 = call i32 @llvm.ctlz.i32(i32 %x, i1 false)
  %tz32 = call i32 @llvm.cttz.i32(i32 %x, i1 false)
  %pop8.z = zext i8 %pop8 to i32
  %lz8.z.z = zext i8 %lz8.z to i32
  %tz8.z.z = zext i8 %tz8.z to i32
  %lz8.e = zext i8 %lz8 to i32
  %tz8.e = zext i8 %tz8 to i32
  %m0 = xor i32 %pop8.z, %lz8.z.z
  %m1 = xor i32 %tz8.z.z, %lz8.e
  %m2 = xor i32 %tz8.e, %pop32
  %m3 = xor i32 %lz32.z, %tz32.z
  %m4 = xor i32 %lz32, %tz32
  %t0 = xor i32 %m0, %m1
  %t1 = xor i32 %m2, %m3
  %t2 = xor i32 %t0, %t1
  %result = xor i32 %t2, %m4
  ret i32 %result
}

define i32 @main() {
entry:
  ; Non-zero mixed bits.
  %e0 = call i32 @reference(i32 305419896)
  %a0 = call i32 @protected(i32 305419896)
  ; Zero input: exercises is_zero_undef=false for ctlz/cttz.
  %e1 = call i32 @reference(i32 0)
  %a1 = call i32 @protected(i32 0)
  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %e1, %a1
  %ok = and i1 %m0, %m1
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; CHECK-LABEL: define i32 @protected(
; CHECK: vmp.dispatch:
; CHECK-DAG: call i8 @llvm.ctpop.i8(
; CHECK-DAG: call i8 @llvm.ctlz.i8({{.*}}, i1 false)
; CHECK-DAG: call i8 @llvm.cttz.i8({{.*}}, i1 false)
; CHECK-DAG: call i32 @llvm.ctpop.i32(
; CHECK-DAG: call i32 @llvm.ctlz.i32({{.*}}, i1 false)
; CHECK-DAG: call i32 @llvm.cttz.i32({{.*}}, i1 false)
; CHECK: "hikari.vmp.virtualized"
