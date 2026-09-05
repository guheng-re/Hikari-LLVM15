; RUN: opt -S -verify-each -aesSeed=71 -passes='default<O0>' %s -o %t.o0.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=71 -passes='default<O2>' %s -o %t.o2.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: FileCheck %s < %t.o0.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare i8 @llvm.abs.i8(i8, i1 immarg)

; i1 false on signed minimum is defined (returns INT_MIN).
; i1 true on a non-minimum negative is defined (ordinary abs).
define i32 @reference(i32 %unused) {
entry:
  %min = call i8 @llvm.abs.i8(i8 -128, i1 false)
  %neg = call i8 @llvm.abs.i8(i8 -42, i1 true)
  %min.z = zext i8 %min to i32
  %neg.z = zext i8 %neg to i32
  %result = xor i32 %min.z, %neg.z
  ret i32 %result
}

define i32 @protected(i32 %unused) noinline optnone {
entry:
  call void @hikari_vmp()
  %min = call i8 @llvm.abs.i8(i8 -128, i1 false)
  %neg = call i8 @llvm.abs.i8(i8 -42, i1 true)
  %min.z = zext i8 %min to i32
  %neg.z = zext i8 %neg to i32
  %result = xor i32 %min.z, %neg.z
  ret i32 %result
}

define i32 @main() {
entry:
  %expected = call i32 @reference(i32 0)
  %actual = call i32 @protected(i32 0)
  %match = icmp eq i32 %expected, %actual
  %code = select i1 %match, i32 0, i32 1
  ret i32 %code
}

; CHECK-LABEL: define i32 @protected(
; CHECK: vmp.dispatch:
; CHECK-DAG: call i8 @llvm.abs.i8({{.*}}, i1 false)
; CHECK-DAG: call i8 @llvm.abs.i8({{.*}}, i1 true)
; CHECK: "hikari.vmp.virtualized"
