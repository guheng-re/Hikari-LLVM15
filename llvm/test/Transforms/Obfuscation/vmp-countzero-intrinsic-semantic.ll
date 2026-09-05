; RUN: opt -S -verify-each -aesSeed=47 -passes='default<O0>' %s -o %t.o0.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=47 -passes='default<O2>' %s -o %t.o2.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: FileCheck %s < %t.o0.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare i32 @llvm.ctlz.i32(i32, i1 immarg)
declare i32 @llvm.cttz.i32(i32, i1 immarg)

define i32 @reference(i32 %x) {
entry:
  ; Nonzero input for is_zero_poison=true calls (zero would be poison).
  %nz = or i32 %x, 1
  %lz.false = call i32 @llvm.ctlz.i32(i32 %x, i1 false)
  %lz.true = call i32 @llvm.ctlz.i32(i32 %nz, i1 true)
  %tz.false = call i32 @llvm.cttz.i32(i32 %x, i1 false)
  %tz.true = call i32 @llvm.cttz.i32(i32 %nz, i1 true)
  %mix0 = xor i32 %lz.false, %lz.true
  %mix1 = xor i32 %tz.false, %tz.true
  %result = xor i32 %mix0, %mix1
  ret i32 %result
}

define i32 @protected(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %nz = or i32 %x, 1
  %lz.false = call i32 @llvm.ctlz.i32(i32 %x, i1 false)
  %lz.true = call i32 @llvm.ctlz.i32(i32 %nz, i1 true)
  %tz.false = call i32 @llvm.cttz.i32(i32 %x, i1 false)
  %tz.true = call i32 @llvm.cttz.i32(i32 %nz, i1 true)
  %mix0 = xor i32 %lz.false, %lz.true
  %mix1 = xor i32 %tz.false, %tz.true
  %result = xor i32 %mix0, %mix1
  ret i32 %result
}

define i32 @main() {
entry:
  %expected = call i32 @reference(i32 305419896)
  %actual = call i32 @protected(i32 305419896)
  %match = icmp eq i32 %expected, %actual
  %code = select i1 %match, i32 0, i32 1
  ret i32 %code
}

; CHECK-LABEL: define i32 @protected(
; CHECK: vmp.dispatch:
; CHECK-DAG: call i32 @llvm.ctlz.i32({{.*}}, i1 false)
; CHECK-DAG: call i32 @llvm.ctlz.i32({{.*}}, i1 true)
; CHECK-DAG: call i32 @llvm.cttz.i32({{.*}}, i1 false)
; CHECK-DAG: call i32 @llvm.cttz.i32({{.*}}, i1 true)
; CHECK: "hikari.vmp.virtualized"
