; RUN: opt -S -verify-each -aesSeed=13 -passes='default<O0>' %s -o %t.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.ll > %t.host.ll
; RUN: lli -force-interpreter %t.host.ll
; RUN: opt -S -verify-each -aesSeed=13 -passes='default<O2>' %s -o %t.o2.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.ll -o %t.o
; RUN: llvm-readobj --file-headers %t.o | FileCheck %s --check-prefix=OBJECT
; RUN: FileCheck %s < %t.ll

target triple = "aarch64-unknown-linux-gnu"

@number = global i32 0, align 4
@pointer.slot = global ptr null, align 8
@value = global i32 5, align 4

declare void @hikari_vmp()

define i32 @protected(i32 %value) noinline optnone {
entry:
  call void @hikari_vmp()
  store atomic i32 %value, ptr @number release, align 4
  %acquired = load atomic i32, ptr @number acquire, align 4
  store atomic i32 11, ptr @number syncscope("singlethread") monotonic, align 4
  %single.thread = load atomic i32, ptr @number syncscope("singlethread") monotonic, align 4
  %ordered = load atomic i32, ptr @number seq_cst, align 4
  store atomic ptr @value, ptr @pointer.slot release, align 8
  %loaded.pointer = load atomic ptr, ptr @pointer.slot acquire, align 8
  %pointer.matches = icmp eq ptr %loaded.pointer, @value
  %pointer.value = zext i1 %pointer.matches to i32
  %first = add i32 %acquired, %single.thread
  %second = add i32 %first, %ordered
  %result = add i32 %second, %pointer.value
  ret i32 %result
}

define i32 @main() {
entry:
  %result = call i32 @protected(i32 7)
  %ok = icmp eq i32 %result, 30
  %status = select i1 %ok, i32 0, i32 1
  ret i32 %status
}

; CHECK-LABEL: define i32 @protected(
; CHECK-DAG: store atomic i32{{.*}}release
; CHECK-DAG: load atomic i32{{.*}}acquire
; CHECK-DAG: syncscope("singlethread") monotonic
; CHECK-DAG: load atomic i32{{.*}}seq_cst
; CHECK-DAG: store atomic ptr{{.*}}release
; CHECK-DAG: load atomic ptr{{.*}}acquire
; CHECK: "hikari.vmp.virtualized"
; OBJECT: Arch: aarch64
