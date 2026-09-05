; Native fence re-emit (ordering + syncscope). Not cmpxchg.
; RUN: opt -S -verify-each -aesSeed=29 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=29 -passes='default<O2>' %s -o %t.o2.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll

target triple = "aarch64-unknown-linux-gnu"

@number = global i32 0, align 4

declare void @hikari_vmp()

define i32 @reference(i32 %x) {
entry:
  store atomic i32 %x, ptr @number release, align 4
  fence acquire
  %a = load atomic i32, ptr @number acquire, align 4
  fence release
  store atomic i32 %a, ptr @number monotonic, align 4
  fence seq_cst
  %b = load atomic i32, ptr @number seq_cst, align 4
  fence syncscope("singlethread") acq_rel
  %sum = add i32 %a, %b
  ret i32 %sum
}

define i32 @protected(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  store atomic i32 %x, ptr @number release, align 4
  fence acquire
  %a = load atomic i32, ptr @number acquire, align 4
  fence release
  store atomic i32 %a, ptr @number monotonic, align 4
  fence seq_cst
  %b = load atomic i32, ptr @number seq_cst, align 4
  fence syncscope("singlethread") acq_rel
  %sum = add i32 %a, %b
  ret i32 %sum
}

; AS0 pointer cmpxchg now virtualizes (vmp-cmpxchg-semantic.ll).

define i32 @main() {
entry:
  store i32 0, ptr @number, align 4
  %e0 = call i32 @reference(i32 7)
  store i32 0, ptr @number, align 4
  %a0 = call i32 @protected(i32 7)
  store i32 0, ptr @number, align 4
  %e1 = call i32 @reference(i32 11)
  store i32 0, ptr @number, align 4
  %a1 = call i32 @protected(i32 11)
  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %e1, %a1
  %ok = and i1 %m0, %m1
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with: 29
; SKIP-NOT: Skipping VMP on protected:

; VIRT-LABEL: define i32 @protected(
; VIRT: vmp.dispatch:
; VIRT-DAG: fence acquire
; VIRT-DAG: fence release
; VIRT-DAG: fence seq_cst
; VIRT-DAG: fence syncscope("singlethread") acq_rel
; VIRT-DAG: store atomic i32
; VIRT-DAG: load atomic i32

; VIRT: attributes{{.*}}"hikari.vmp.virtualized"
