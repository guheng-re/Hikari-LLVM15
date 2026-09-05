; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.vmp.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.vmp.ll > %t.host.ll
; RUN: lli -force-interpreter %t.host.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()

define i32 @protected() {
entry:
  call void @hikari_vmp()
  ret i32 42
}

define i32 @main() {
entry:
  %value = call i32 @protected()
  %equal = icmp eq i32 %value, 42
  %result = select i1 %equal, i32 0, i32 1
  ret i32 %result
}
