; RUN: opt -S -verify-each -aesSeed=31 -passes='default<O0>' %s -o %t.o0.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=31 -passes='default<O2>' %s -o %t.o2.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: FileCheck %s < %t.o0.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()

define i32 @reference(ptr %base, i64 %index) {
entry:
  %elem = getelementptr inbounds i32, ptr %base, i64 %index
  %eq = icmp eq ptr %elem, %base
  %ne = icmp ne ptr %elem, %base
  %ult = icmp ult ptr %base, %elem
  %uge = icmp uge ptr %elem, %base
  %eq.i = zext i1 %eq to i32
  %ne.i = zext i1 %ne to i32
  %ult.i = zext i1 %ult to i32
  %uge.i = zext i1 %uge to i32
  %sum0 = add i32 %eq.i, %ne.i
  %sum1 = add i32 %sum0, %ult.i
  %sum2 = add i32 %sum1, %uge.i
  ret i32 %sum2
}

define i32 @protected(ptr %base, i64 %index) noinline optnone {
entry:
  call void @hikari_vmp()
  %elem = getelementptr inbounds i32, ptr %base, i64 %index
  %eq = icmp eq ptr %elem, %base
  %ne = icmp ne ptr %elem, %base
  %ult = icmp ult ptr %base, %elem
  %uge = icmp uge ptr %elem, %base
  %eq.i = zext i1 %eq to i32
  %ne.i = zext i1 %ne to i32
  %ult.i = zext i1 %ult to i32
  %uge.i = zext i1 %uge to i32
  %sum0 = add i32 %eq.i, %ne.i
  %sum1 = add i32 %sum0, %ult.i
  %sum2 = add i32 %sum1, %uge.i
  ret i32 %sum2
}

define i32 @main() {
entry:
  %buf = alloca [4 x i32], align 4
  %base = getelementptr inbounds [4 x i32], ptr %buf, i64 0, i64 0
  %expected = call i32 @reference(ptr %base, i64 2)
  %actual = call i32 @protected(ptr %base, i64 2)
  %match = icmp eq i32 %expected, %actual
  %code = select i1 %match, i32 0, i32 1
  ret i32 %code
}

; CHECK-LABEL: define i32 @protected(
; CHECK: vmp.dispatch:
; CHECK-DAG: icmp eq ptr
; CHECK-DAG: icmp ne ptr
; CHECK-DAG: icmp ult ptr
; CHECK-DAG: icmp uge ptr
; CHECK: "hikari.vmp.virtualized"
