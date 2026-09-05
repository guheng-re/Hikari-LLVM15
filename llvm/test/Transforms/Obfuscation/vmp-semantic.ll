; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.first.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.second.ll
; RUN: diff %t.first.ll %t.second.ll
; RUN: FileCheck %s < %t.o0.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()

define i32 @reference(i32 %x) {
entry:
  %scaled = mul nsw i32 %x, 3
  %masked = xor i32 %scaled, 90
  %shifted = ashr i32 %masked, 1
  %large = icmp sgt i32 %x, 2
  br i1 %large, label %high, label %low

high:
  %high.value = add nsw i32 %shifted, 7
  br label %merge

low:
  %low.value = sub nsw i32 %shifted, 5
  br label %merge

merge:
  %selected = phi i32 [ %high.value, %high ], [ %low.value, %low ]
  %remainder = srem i32 %selected, 11
  %small = trunc i32 %remainder to i8
  %wide = sext i8 %small to i32
  br label %loop.header

loop.header:
  %index = phi i32 [ 0, %merge ], [ %next.index, %loop.body ]
  %accumulator = phi i32 [ %wide, %merge ], [ %next.accumulator, %loop.body ]
  %continue = icmp slt i32 %index, 2
  br i1 %continue, label %loop.body, label %loop.exit

loop.body:
  %next.accumulator = add nsw i32 %accumulator, %index
  %next.index = add nsw i32 %index, 1
  br label %loop.header

loop.exit:
  switch i32 %x, label %default [
    i32 0, label %case.zero
    i32 1, label %case.one
  ]

case.zero:
  %zero = add i32 %accumulator, 1
  br label %done

case.one:
  %one = or i32 %accumulator, 3
  br label %done

default:
  %other = and i32 %accumulator, 31
  br label %done

done:
  %result = phi i32 [ %zero, %case.zero ], [ %one, %case.one ], [ %other, %default ]
  ret i32 %result
}

define i32 @protected(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %scaled = mul nsw i32 %x, 3
  %masked = xor i32 %scaled, 90
  %shifted = ashr i32 %masked, 1
  %large = icmp sgt i32 %x, 2
  br i1 %large, label %high, label %low

high:
  %high.value = add nsw i32 %shifted, 7
  br label %merge

low:
  %low.value = sub nsw i32 %shifted, 5
  br label %merge

merge:
  %selected = phi i32 [ %high.value, %high ], [ %low.value, %low ]
  %remainder = srem i32 %selected, 11
  %small = trunc i32 %remainder to i8
  %wide = sext i8 %small to i32
  br label %loop.header

loop.header:
  %index = phi i32 [ 0, %merge ], [ %next.index, %loop.body ]
  %accumulator = phi i32 [ %wide, %merge ], [ %next.accumulator, %loop.body ]
  %continue = icmp slt i32 %index, 2
  br i1 %continue, label %loop.body, label %loop.exit

loop.body:
  %next.accumulator = add nsw i32 %accumulator, %index
  %next.index = add nsw i32 %index, 1
  br label %loop.header

loop.exit:
  switch i32 %x, label %default [
    i32 0, label %case.zero
    i32 1, label %case.one
  ]

case.zero:
  %zero = add i32 %accumulator, 1
  br label %done

case.one:
  %one = or i32 %accumulator, 3
  br label %done

default:
  %other = and i32 %accumulator, 31
  br label %done

done:
  %result = phi i32 [ %zero, %case.zero ], [ %one, %case.one ], [ %other, %default ]
  ret i32 %result
}

define i32 @main() {
entry:
  %reference.result = call i32 @reference(i32 9)
  %protected.result = call i32 @protected(i32 9)
  %equal = icmp eq i32 %reference.result, %protected.result
  %exit = select i1 %equal, i32 0, i32 1
  ret i32 %exit
}

; CHECK: @__hikari_vmp_bc = private unnamed_addr constant
; CHECK-LABEL: define i32 @protected(
; CHECK: vmp.dispatch:
; CHECK: switch i32
; CHECK-NOT: call void @hikari_vmp
; CHECK: "hikari.vmp.virtualized"
