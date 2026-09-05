; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: FileCheck %s < %t.o0.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare { i32, i1 } @llvm.sadd.with.overflow.i32(i32, i32)

define i32 @reference(i32 %a, i32 %b) {
entry:
  %pair = call { i32, i1 } @llvm.sadd.with.overflow.i32(i32 %a, i32 %b)
  %sum = extractvalue { i32, i1 } %pair, 0
  %ov = extractvalue { i32, i1 } %pair, 1
  %ov.z = zext i1 %ov to i32
  %result = xor i32 %sum, %ov.z
  ret i32 %result
}

define i32 @protected(i32 %a, i32 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %pair = call { i32, i1 } @llvm.sadd.with.overflow.i32(i32 %a, i32 %b)
  %sum = extractvalue { i32, i1 } %pair, 0
  %ov = extractvalue { i32, i1 } %pair, 1
  %ov.z = zext i1 %ov to i32
  %result = xor i32 %sum, %ov.z
  ret i32 %result
}

; Result-discarded sadd.with.overflow (no extractvalue uses).
define void @protected_discard() noinline optnone {
entry:
  call void @hikari_vmp()
  %pair = call { i32, i1 } @llvm.sadd.with.overflow.i32(i32 2147483647, i32 1)
  ret void
}

define i32 @main() {
entry:
  ; No overflow: 10+20
  %e0 = call i32 @reference(i32 10, i32 20)
  %a0 = call i32 @protected(i32 10, i32 20)
  ; Overflow: INT_MAX + 1
  %e1 = call i32 @reference(i32 2147483647, i32 1)
  %a1 = call i32 @protected(i32 2147483647, i32 1)
  call void @protected_discard()
  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %e1, %a1
  %ok = and i1 %m0, %m1
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; CHECK-LABEL: define i32 @protected(
; CHECK: vmp.dispatch:
; CHECK: call { i32, i1 } @llvm.sadd.with.overflow.i32(
; CHECK-DAG: extractvalue { i32, i1 } {{.*}}, 0
; CHECK-DAG: extractvalue { i32, i1 } {{.*}}, 1
; CHECK-LABEL: define void @protected_discard(
; CHECK: vmp.dispatch:
; CHECK: call { i32, i1 } @llvm.sadd.with.overflow.i32(
; CHECK-NOT: extractvalue
; CHECK: "hikari.vmp.virtualized"
