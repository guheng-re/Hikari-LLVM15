; llvm.stackprotector whose slot alloca is not a pointer stays rejected.
; The accepted form requires a same-function static alloca of an AS0
; pointer.  The function is never called from main; verification is
; static (opt/llc).  __stack_chk_guard is a codegen fixture only so
; AArch64 llc can lower the leftover native stackprotector.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.ll -o %t.o0.o
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP-O2 < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT-O2 < %t.o2.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.ll -o %t.o2.o
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP-O2 < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT-O2 < %t.o2.s7.ll

target triple = "aarch64-unknown-linux-gnu"

@__stack_chk_guard = external global ptr
@llvm.compiler.used = appending global [1 x ptr] [ptr @__stack_chk_guard], section "llvm.metadata"

declare void @hikari_vmp()
declare void @llvm.stackprotector(ptr, ptr)

define void @unsupported_stackprotector() noinline optnone {
entry:
  call void @hikari_vmp()
  %slot = alloca i64, align 8
  call void @llvm.stackprotector(ptr @__stack_chk_guard, ptr %slot)
  ret void
}

define i32 @main() {
entry:
  ret i32 0
}

; SKIP-DAG: Skipping VMP on unsupported_stackprotector: unsupported stackprotector
; SKIP-O2-DAG: Skipping VMP on unsupported_stackprotector: unsupported stackprotector

; VIRT: @__stack_chk_guard = external global ptr
; VIRT: define void @unsupported_stackprotector(){{.*}}#[[NEGATTR:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call void @llvm.stackprotector(ptr @__stack_chk_guard, ptr
; VIRT: attributes #[[NEGATTR]] = { noinline optnone "hikari.vmp.selected" }{{$}}

; VIRT-O2: @__stack_chk_guard = external global ptr
; VIRT-O2: define void @unsupported_stackprotector(){{.*}}#[[NEGATTR:[0-9]+]] {
; VIRT-O2-NOT: vmp.dispatch
; VIRT-O2: call void @llvm.stackprotector(ptr @__stack_chk_guard, ptr
; VIRT-O2: attributes #[[NEGATTR]] = { noinline optnone "hikari.vmp.selected" }{{$}}
