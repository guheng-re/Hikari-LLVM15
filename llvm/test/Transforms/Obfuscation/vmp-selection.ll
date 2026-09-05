; RUN: opt -S -verify-each -passes='default<O0>' %s -o - | FileCheck %s --check-prefix=MARKED
; RUN: opt -S -verify-each -enable-vmpobf -passes='default<O2>' %s -o - | FileCheck %s --check-prefix=GLOBAL

target triple = "aarch64-unknown-linux-gnu"

@counter = global i32 0

declare void @hikari_vmp()
declare void @hikari_novmp()

define i32 @marker() {
entry:
  call void @hikari_vmp()
  ret i32 7
}

define i32 @plain() {
entry:
  ret i32 9
}

define i32 @disabled() {
entry:
  call void @hikari_novmp()
  ret i32 11
}

define i32 @atomic() {
entry:
  %old = atomicrmw add ptr @counter, i32 1 seq_cst
  ret i32 %old
}

; MARKED-NOT: @hikari_vmp
; MARKED-NOT: @hikari_novmp
; MARKED: @__hikari_vmp_bc = private unnamed_addr constant
; MARKED: vmp.dispatch:
; MARKED-COUNT-1: noinline "hikari.vmp.selected" "hikari.vmp.virtualized"

; GLOBAL-NOT: @hikari_vmp
; GLOBAL-NOT: @hikari_novmp
; GLOBAL: @__hikari_vmp_bc = private unnamed_addr constant
; GLOBAL: vmp.dispatch:
; GLOBAL-COUNT-1: noinline
; GLOBAL-COUNT-2: "hikari.vmp.selected" "hikari.vmp.virtualized"
