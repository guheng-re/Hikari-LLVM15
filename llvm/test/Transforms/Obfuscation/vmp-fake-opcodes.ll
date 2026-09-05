; RUN: opt -S -verify-each -aesSeed=1 -vmp-fake-op-rate=100 -vmp-max-fake-ops=64 -passes='default<O0>' %s -o %t.ll
; RUN: FileCheck %s < %t.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.ll > %t.host.ll
; RUN: lli -force-interpreter %t.host.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()

define i32 @protected.fake.opcodes(i32 %value) noinline optnone {
entry:
  call void @hikari_vmp()
  %a = add i32 %value, 1
  %b = xor i32 %a, 17
  %c = mul i32 %b, 3
  %d = add i32 %c, 5
  %e = xor i32 %d, 9
  %f = mul i32 %e, 7
  %g = add i32 %f, 11
  %h = xor i32 %g, 19
  %i = mul i32 %h, 13
  ret i32 %i
}

define i32 @main() {
entry:
  %result = call i32 @protected.fake.opcodes(i32 4)
  %ok = icmp eq i32 %result, 6864
  %exit = select i1 %ok, i32 0, i32 1
  ret i32 %exit
}

; CHECK-LABEL: define i32 @protected.fake.opcodes(
; CHECK-DAG: vmp.fake.add
; CHECK-DAG: vmp.fake.xor
; CHECK-DAG: vmp.fake.rotate
; CHECK: "hikari.vmp.virtualized"
