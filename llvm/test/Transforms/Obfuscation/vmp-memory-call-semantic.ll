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

%pair = type { i32, i32 }

@global = global i32 3, align 4

declare void @hikari_vmp()

define fastcc i32 @mutate(ptr noundef %out, i32 noundef %value) noinline {
entry:
  %previous = load i32, ptr %out, align 4
  %next = add nsw i32 %previous, %value
  store i32 %next, ptr %out, align 4
  ret i32 %next
}

define fastcc ptr @choose(ptr %left, ptr %right, i1 %use.left) noinline {
entry:
  %selected = select i1 %use.left, ptr %left, ptr %right
  ret ptr %selected
}

define fastcc void @touch(ptr %out) noinline {
entry:
  %value = load i32, ptr %out, align 4
  store i32 %value, ptr %out, align 4
  ret void
}

define fastcc i32 @sum4(i32 %a, i32 %b, i32 %c, i32 %d) noinline {
entry:
  %first = add nsw i32 %a, %b
  %second = add nsw i32 %c, %d
  %result = add nsw i32 %first, %second
  ret i32 %result
}

define i32 @reference(i32 %x) {
entry:
  %storage = alloca [2 x %pair], align 4
  %first = getelementptr inbounds [2 x %pair], ptr %storage, i64 0, i64 0, i32 0
  %second = getelementptr inbounds [2 x %pair], ptr %storage, i64 0, i64 1, i32 1
  store i32 %x, ptr %first, align 4
  store volatile i32 %x, ptr %second, align 4
  %positive = icmp sgt i32 %x, 0
  br i1 %positive, label %left, label %right

left:
  br label %merge

right:
  br label %merge

merge:
  %selected = phi ptr [ %first, %left ], [ %second, %right ]
  %equals.first = icmp eq ptr %selected, %first
  %index = zext i1 %equals.first to i64
  %dynamic = getelementptr inbounds [2 x %pair], ptr %storage, i64 0, i64 %index, i32 0
  store i32 %x, ptr %dynamic, align 4
  %chosen = call fastcc ptr @choose(ptr %selected, ptr %second, i1 %equals.first)
  %target = select i1 %equals.first, ptr %chosen, ptr %second
  call fastcc void @touch(ptr %target)
  %before = load volatile i32, ptr %target, align 4
  %called = call fastcc i32 @mutate(ptr noundef %target, i32 noundef %before)
  %after = load i32, ptr %target, align 4
  %global.value = load i32, ptr @global, align 4
  %result = call fastcc i32 @sum4(i32 %called, i32 %after, i32 %global.value, i32 %x)
  %with.global = add nsw i32 %result, %global.value
  store i32 %with.global, ptr @global, align 4
  ret i32 %with.global
}

define i32 @protected(i32 %x) noinline optnone {
entry:
  %storage = alloca [2 x %pair], align 4
  call void @hikari_vmp()
  %first = getelementptr inbounds [2 x %pair], ptr %storage, i64 0, i64 0, i32 0
  %second = getelementptr inbounds [2 x %pair], ptr %storage, i64 0, i64 1, i32 1
  store i32 %x, ptr %first, align 4
  store volatile i32 %x, ptr %second, align 4
  %positive = icmp sgt i32 %x, 0
  br i1 %positive, label %left, label %right

left:
  br label %merge

right:
  br label %merge

merge:
  %selected = phi ptr [ %first, %left ], [ %second, %right ]
  %equals.first = icmp eq ptr %selected, %first
  %index = zext i1 %equals.first to i64
  %dynamic = getelementptr inbounds [2 x %pair], ptr %storage, i64 0, i64 %index, i32 0
  store i32 %x, ptr %dynamic, align 4
  %chosen = call fastcc ptr @choose(ptr %selected, ptr %second, i1 %equals.first)
  %target = select i1 %equals.first, ptr %chosen, ptr %second
  call fastcc void @touch(ptr %target)
  %before = load volatile i32, ptr %target, align 4
  %called = call fastcc i32 @mutate(ptr noundef %target, i32 noundef %before)
  %after = load i32, ptr %target, align 4
  %global.value = load i32, ptr @global, align 4
  %result = call fastcc i32 @sum4(i32 %called, i32 %after, i32 %global.value, i32 %x)
  %with.global = add nsw i32 %result, %global.value
  store i32 %with.global, ptr @global, align 4
  ret i32 %with.global
}

define i32 @main() {
entry:
  %reference.result = call i32 @reference(i32 7)
  store i32 3, ptr @global, align 4
  %protected.result = call i32 @protected(i32 7)
  %equal = icmp eq i32 %reference.result, %protected.result
  %exit = select i1 %equal, i32 0, i32 1
  ret i32 %exit
}

; CHECK: @__hikari_vmp_bc = private unnamed_addr constant
; CHECK-LABEL: define i32 @protected(
; CHECK: %vmp.ptr.regs = alloca
; CHECK: %vmp.stack = alloca [2 x %pair]
; CHECK: load volatile i32
; CHECK-DAG: call fastcc ptr @choose
; CHECK-DAG: call fastcc void @touch
; CHECK-DAG: call fastcc i32 @mutate
; CHECK-DAG: call fastcc i32 @sum4
; CHECK: "hikari.vmp.virtualized"
