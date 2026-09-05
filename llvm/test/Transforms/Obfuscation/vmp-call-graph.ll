; RUN: opt -S -verify-each -aesSeed=19 -passes='default<O0>' %s -o %t.o0.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=19 -passes='default<O2>' %s -o %t.o2.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: FileCheck %s < %t.o0.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()

define i32 @reference_countdown(i32 %value) {
entry:
  %done = icmp eq i32 %value, 0
  br i1 %done, label %base, label %recurse

base:
  ret i32 1

recurse:
  %next = sub nsw i32 %value, 1
  %child = call i32 @reference_countdown(i32 %next)
  %result = add nsw i32 %child, 1
  ret i32 %result
}

define i32 @countdown(i32 %value) noinline optnone {
entry:
  call void @hikari_vmp()
  %done = icmp eq i32 %value, 0
  br i1 %done, label %base, label %recurse

base:
  ret i32 1

recurse:
  %next = sub nsw i32 %value, 1
  %child = call i32 @countdown(i32 %next)
  %result = add nsw i32 %child, 1
  ret i32 %result
}

define i32 @even(i32 %value) noinline optnone {
entry:
  call void @hikari_vmp()
  %done = icmp eq i32 %value, 0
  br i1 %done, label %true, label %recurse

true:
  ret i32 1

recurse:
  %next = sub nsw i32 %value, 1
  %result = call i32 @odd(i32 %next)
  ret i32 %result
}

define i32 @odd(i32 %value) noinline optnone {
entry:
  call void @hikari_vmp()
  %done = icmp eq i32 %value, 0
  br i1 %done, label %false, label %recurse

false:
  ret i32 0

recurse:
  %next = sub nsw i32 %value, 1
  %result = call i32 @even(i32 %next)
  ret i32 %result
}

define i32 @main() {
entry:
  %reference = call i32 @reference_countdown(i32 5)
  %protected = call i32 @countdown(i32 5)
  %same.countdown = icmp eq i32 %reference, %protected
  %even.value = call i32 @even(i32 8)
  %odd.value = call i32 @odd(i32 8)
  %same.even = icmp eq i32 %even.value, 1
  %same.odd = icmp eq i32 %odd.value, 0
  %both = and i1 %same.countdown, %same.even
  %all = and i1 %both, %same.odd
  %exit = select i1 %all, i32 0, i32 1
  ret i32 %exit
}

; CHECK-LABEL: define i32 @countdown(
; CHECK: call i32 @countdown
; CHECK-LABEL: define i32 @even(
; CHECK: call i32 @odd
; CHECK-LABEL: define i32 @odd(
; CHECK: call i32 @even
; CHECK: "hikari.vmp.virtualized"
