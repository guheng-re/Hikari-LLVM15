; RUN: opt -S -verify-each -passes='default<O0>' %s -o - | FileCheck %s

target triple = "aarch64-unknown-linux-gnu"

@.annotation = private unnamed_addr constant [4 x i8] c"vmp\00", section "llvm.metadata"
@.file = private unnamed_addr constant [4 x i8] c"x.c\00", section "llvm.metadata"
@llvm.global.annotations = appending global [1 x { ptr, ptr, ptr, i32, ptr }] [{ ptr, ptr, ptr, i32, ptr } { ptr @annotated, ptr @.annotation, ptr @.file, i32 1, ptr null }], section "llvm.metadata"

define i32 @annotated(i32 %value) {
entry:
  %result = add nsw i32 %value, 1
  ret i32 %result
}

; CHECK: @__hikari_vmp_bc = private unnamed_addr constant
; CHECK-LABEL: define i32 @annotated(
; CHECK: vmp.dispatch:
; CHECK: "hikari.vmp.selected" "hikari.vmp.virtualized"
