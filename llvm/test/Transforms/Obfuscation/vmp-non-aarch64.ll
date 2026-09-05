; RUN: opt -S -verify-each -passes='default<O0>' %s -o - 2>&1 | FileCheck %s --check-prefix=DIAG
; RUN: opt -S -verify-each -passes='default<O0>' %s -o - | FileCheck %s --check-prefix=IR

target triple = "x86_64-unknown-linux-gnu"

declare void @hikari_vmp()

define i32 @marker() {
entry:
  call void @hikari_vmp()
  ret i32 1
}

; DIAG: Skipping VMP: only AArch64 targets are supported
; IR-NOT: "hikari.vmp.selected"
