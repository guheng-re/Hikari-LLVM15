; RUN: opt -S -verify-each -passes='function(vmpobf,vmp-post-cff)' %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target triple = "x86_64-unknown-linux-gnu"

define i32 @not.aarch64(i32 %value) "hikari.vmp.selected" "hikari.vmp.post.cff" {
entry:
  ret i32 %value
}

; CHECK-LABEL: define i32 @not.aarch64(
; CHECK-NOT: switchVar
; CHECK: ret i32 %value
; CHECK-NOT: hikari.vmp.virtualized
; CHECK-NOT: hikari.vmp.post.cff.applied
