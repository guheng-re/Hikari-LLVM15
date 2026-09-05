; RUN: opt -S -verify-each -aesSeed=37 -passes='default<O0>' %s -o %t.o0.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=37 -passes='default<O2>' %s -o %t.o2.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: FileCheck %s < %t.o0.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture)

define i32 @reference(i32 %x) {
entry:
  %slot = alloca i32, align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr %slot)
  store i32 %x, ptr %slot, align 4
  %value = load i32, ptr %slot, align 4
  call void @llvm.lifetime.end.p0(i64 4, ptr %slot)
  %result = add i32 %value, 1
  ret i32 %result
}

define i32 @protected(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %slot = alloca i32, align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr %slot)
  store i32 %x, ptr %slot, align 4
  %value = load i32, ptr %slot, align 4
  call void @llvm.lifetime.end.p0(i64 4, ptr %slot)
  %result = add i32 %value, 1
  ret i32 %result
}

define i32 @main() {
entry:
  %expected = call i32 @reference(i32 41)
  %actual = call i32 @protected(i32 41)
  %match = icmp eq i32 %expected, %actual
  %code = select i1 %match, i32 0, i32 1
  ret i32 %code
}

; CHECK-LABEL: define i32 @protected(
; CHECK: vmp.dispatch:
; CHECK-NOT: call void @llvm.lifetime.start
; CHECK-NOT: call void @llvm.lifetime.end
; CHECK: "hikari.vmp.virtualized"
