; REQUIRES: vmp-aarch64-runner
; RUN: opt -S -verify-each -aesSeed=123 -vmp-report-stats -passes='default<O0>' %s -o %t.ll 2> %t.stats
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.ll -o %t.o
; RUN: llvm-readobj --file-headers %t.o | FileCheck %s --check-prefix=OBJECT
; RUN: %vmp_aarch64_runner --object %t.o --expect 0 --iterations 10000 --metrics %t.metrics.json
; RUN: %python %S/Inputs/vmp-aarch64-metrics.py --metrics %t.metrics.json --llvm-size llvm-size --object %t.o --stats %t.stats

target triple = "aarch64-unknown-linux-gnu"

@state = global i32 0, align 4

declare void @hikari_vmp()

define i32 @vmp.recursive(i32 %value) noinline optnone {
entry:
  call void @hikari_vmp()
  %done = icmp eq i32 %value, 0
  br i1 %done, label %base, label %step

base:
  ret i32 0

step:
  %next = sub i32 %value, 1
  %sum = call i32 @vmp.recursive(i32 %next)
  %result = add i32 %sum, %value
  ret i32 %result
}

define i32 @vmp.memory.atomic(i32 %value) noinline optnone {
entry:
  call void @hikari_vmp()
  %slot = alloca i32, align 4
  store i32 %value, ptr %slot, align 4
  %local = load i32, ptr %slot, align 4
  store atomic i32 %local, ptr @state release, align 4
  %loaded = load atomic i32, ptr @state acquire, align 4
  ret i32 %loaded
}

define i32 @main() {
entry:
  %sum = call i32 @vmp.recursive(i32 5)
  %memory = call i32 @vmp.memory.atomic(i32 27)
  %sum.ok = icmp eq i32 %sum, 15
  %memory.ok = icmp eq i32 %memory, 27
  %ok = and i1 %sum.ok, %memory.ok
  %exit = select i1 %ok, i32 0, i32 1
  ret i32 %exit
}

; OBJECT: Arch: aarch64
