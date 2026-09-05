; RUN: opt -S -verify-each -aesSeed=79 -passes='default<O0>' %s -o %t.o0.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=79 -passes='default<O2>' %s -o %t.o2.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: FileCheck %s < %t.o0.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
; bswap requires an even number of bytes; i8 is invalid LLVM IR, so use i16.
declare i16 @llvm.bswap.i16(i16)
declare i8 @llvm.bitreverse.i8(i8)
declare i32 @llvm.bswap.i32(i32)
declare i32 @llvm.bitreverse.i32(i32)

; Scalar bswap (i16/i32) and bitreverse (i8/i32); results mixed for compare.
define i32 @reference(i32 %x) {
entry:
  %x8 = trunc i32 %x to i8
  %x16 = trunc i32 %x to i16
  %bs16 = call i16 @llvm.bswap.i16(i16 %x16)
  %br8 = call i8 @llvm.bitreverse.i8(i8 %x8)
  %bs32 = call i32 @llvm.bswap.i32(i32 %x)
  %br32 = call i32 @llvm.bitreverse.i32(i32 %x)
  %bs16.z = zext i16 %bs16 to i32
  %br8.z = zext i8 %br8 to i32
  %m0 = xor i32 %bs16.z, %br8.z
  %m1 = xor i32 %bs32, %br32
  %result = xor i32 %m0, %m1
  ret i32 %result
}

define i32 @protected(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %x8 = trunc i32 %x to i8
  %x16 = trunc i32 %x to i16
  %bs16 = call i16 @llvm.bswap.i16(i16 %x16)
  %br8 = call i8 @llvm.bitreverse.i8(i8 %x8)
  %bs32 = call i32 @llvm.bswap.i32(i32 %x)
  %br32 = call i32 @llvm.bitreverse.i32(i32 %x)
  %bs16.z = zext i16 %bs16 to i32
  %br8.z = zext i8 %br8 to i32
  %m0 = xor i32 %bs16.z, %br8.z
  %m1 = xor i32 %bs32, %br32
  %result = xor i32 %m0, %m1
  ret i32 %result
}

define i32 @main() {
entry:
  ; Non-zero mixed bit pattern.
  %e0 = call i32 @reference(i32 305419896)
  %a0 = call i32 @protected(i32 305419896)
  ; Zero input.
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
; CHECK-DAG: call i16 @llvm.bswap.i16(
; CHECK-DAG: call i8 @llvm.bitreverse.i8(
; CHECK-DAG: call i32 @llvm.bswap.i32(
; CHECK-DAG: call i32 @llvm.bitreverse.i32(
; CHECK: "hikari.vmp.virtualized"
