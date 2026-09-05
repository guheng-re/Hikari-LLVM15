; RUN: opt -S -verify-each -aesSeed=123 -passes='function(vmpobf)' %s -o %t.first.ll
; RUN: opt -S -verify-each -aesSeed=123 -passes='function(vmpobf)' %s -o %t.second.ll
; RUN: diff %t.first.ll %t.second.ll
; RUN: opt -S -verify-each -aesSeed=124 -passes='function(vmpobf)' %s -o %t.other.ll
; RUN: not diff %t.first.ll %t.other.ll
; RUN: FileCheck %s < %t.first.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.first.ll > %t.host.ll
; RUN: lli -force-interpreter %t.host.ll

target triple = "aarch64-unknown-linux-gnu"

define i32 @direct.vmp(i32 %value) noinline optnone #0 {
entry:
  %sum = add i32 %value, 7
  ret i32 %sum
}

define i32 @main() {
entry:
  %result = call i32 @direct.vmp(i32 5)
  %ok = icmp eq i32 %result, 12
  %exit = select i1 %ok, i32 0, i32 1
  ret i32 %exit
}

attributes #0 = { "hikari.vmp.selected" }

; CHECK: @__hikari_vmp_bc = private unnamed_addr constant
; CHECK-LABEL: define i32 @direct.vmp(
; CHECK: "hikari.vmp.virtualized"
