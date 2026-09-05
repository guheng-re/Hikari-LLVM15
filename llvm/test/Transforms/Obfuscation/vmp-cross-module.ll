; RUN: opt -S -verify-each -aesSeed=23 -passes='default<O0>' %s -o %t.main.ll
; RUN: llvm-link -S %t.main.ll %S/Inputs/vmp-cross-module-helper.ll -o %t.linked.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.linked.ll > %t.host.ll
; RUN: lli -force-interpreter %t.host.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.main.ll -o %t.o
; RUN: llvm-readobj -h %t.o | FileCheck %s --check-prefix=OBJ
; RUN: FileCheck %s < %t.main.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare i32 @external_helper(ptr, i32)

define i32 @reference(i32 %value) {
entry:
  %slot = alloca i32, align 4
  store i32 4, ptr %slot, align 4
  %call = call i32 @external_helper(ptr %slot, i32 %value)
  %stored = load i32, ptr %slot, align 4
  %result = add nsw i32 %call, %stored
  ret i32 %result
}

define i32 @protected(i32 %value) noinline optnone {
entry:
  %slot = alloca i32, align 4
  call void @hikari_vmp()
  store i32 4, ptr %slot, align 4
  %call = call i32 @external_helper(ptr %slot, i32 %value)
  %stored = load i32, ptr %slot, align 4
  %result = add nsw i32 %call, %stored
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

; CHECK-LABEL: define i32 @protected(
; CHECK: %vmp.call = call i32 @external_helper
; CHECK: "hikari.vmp.virtualized"

; OBJ: Arch: aarch64
