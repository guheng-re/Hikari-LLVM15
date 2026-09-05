; RUN: opt -S -verify-each -aesSeed=83 -passes='default<O0>' %s -o %t.o0.ll
; RUN: FileCheck %s < %t.o0.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=83 -passes='default<O2>' %s -o %t.o2.ll
; RUN: FileCheck %s < %t.o2.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()

define i32 @reference(i32 %x) {
entry:
  %ok = icmp sge i32 %x, 0
  br i1 %ok, label %live, label %dead

live:
  %result = add i32 %x, 1
  ret i32 %result

dead:
  unreachable
}

define i32 @protected(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %ok = icmp sge i32 %x, 0
  br i1 %ok, label %live, label %dead

live:
  %result = add i32 %x, 1
  ret i32 %result

dead:
  unreachable
}

; Main only exercises the live path so host lli stays defined.
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
; CHECK: unreachable
; CHECK: "hikari.vmp.virtualized"
