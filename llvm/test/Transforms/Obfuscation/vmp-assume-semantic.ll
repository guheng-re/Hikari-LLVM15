; RUN: opt -S -verify-each -aesSeed=41 -passes='default<O0>' %s -o %t.o0.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=41 -passes='default<O2>' %s -o %t.o2.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: FileCheck %s < %t.o0.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare void @llvm.assume(i1)

define i32 @reference(i32 %x) {
entry:
  %positive = icmp sgt i32 %x, 0
  call void @llvm.assume(i1 %positive)
  %result = add i32 %x, 1
  ret i32 %result
}

define i32 @protected(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %positive = icmp sgt i32 %x, 0
  call void @llvm.assume(i1 %positive)
  %result = add i32 %x, 1
  ret i32 %result
}

define i32 @main() {
entry:
  %expected = call i32 @reference(i32 7)
  %actual = call i32 @protected(i32 7)
  %match = icmp eq i32 %expected, %actual
  %code = select i1 %match, i32 0, i32 1
  ret i32 %code
}

; CHECK-LABEL: define i32 @protected(
; CHECK: vmp.dispatch:
; CHECK: call void @llvm.assume(
; CHECK: "hikari.vmp.virtualized"
