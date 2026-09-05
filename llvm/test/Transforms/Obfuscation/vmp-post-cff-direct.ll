; RUN: opt -S -verify-each -aesSeed=73 -passes='function(vmpobf,vmp-post-cff,vmp-post-cff)' %s -o %t.ll
; RUN: FileCheck %s < %t.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.ll > %t.host.ll
; RUN: lli -force-interpreter %t.host.ll

target triple = "aarch64-unknown-linux-gnu"

define i32 @direct.post.cff(i32 %x) noinline optnone "hikari.vmp.selected" "hikari.vmp.post.cff" {
entry:
  %test = icmp eq i32 %x, 0
  br i1 %test, label %zero, label %nonzero

zero:
  ret i32 10

nonzero:
  ret i32 11
}

define i32 @main() {
entry:
  %value = call i32 @direct.post.cff(i32 4)
  %ok = icmp eq i32 %value, 11
  %result = select i1 %ok, i32 0, i32 1
  ret i32 %result
}

; CHECK-LABEL: define i32 @direct.post.cff(
; CHECK: %switchVar = alloca i32
; CHECK: "hikari.vmp.post.cff.applied"
