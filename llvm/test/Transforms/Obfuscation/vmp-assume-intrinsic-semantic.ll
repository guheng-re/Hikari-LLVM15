; RUN: opt -S -verify-each -aesSeed=89 -passes='default<O0>' %s -o %t.o0.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=89 -passes='default<O2>' %s -o %t.o2.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: FileCheck %s < %t.o0.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare void @llvm.assume(i1 noundef)

; Plain llvm.assume (constant true + icmp-derived true) re-emitted via Call path.
define i32 @reference(i32 %x) {
entry:
  call void @llvm.assume(i1 true)
  %positive = icmp sgt i32 %x, 0
  call void @llvm.assume(i1 %positive)
  %y = add i32 %x, 1
  %ok = icmp sgt i32 %y, 1
  br i1 %ok, label %cont, label %fail
cont:
  %result = xor i32 %y, 3
  ret i32 %result
fail:
  ret i32 -1
}

define i32 @protected(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.assume(i1 true)
  %positive = icmp sgt i32 %x, 0
  call void @llvm.assume(i1 %positive)
  %y = add i32 %x, 1
  %ok = icmp sgt i32 %y, 1
  br i1 %ok, label %cont, label %fail
cont:
  %result = xor i32 %y, 3
  ret i32 %result
fail:
  ret i32 -1
}

define i32 @main() {
entry:
  %e0 = call i32 @reference(i32 7)
  %a0 = call i32 @protected(i32 7)
  %e1 = call i32 @reference(i32 2)
  %a1 = call i32 @protected(i32 2)
  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %e1, %a1
  %ok = and i1 %m0, %m1
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; CHECK-LABEL: define i32 @protected(
; CHECK: vmp.dispatch:
; CHECK-DAG: call void @llvm.assume(
; CHECK: "hikari.vmp.virtualized"
