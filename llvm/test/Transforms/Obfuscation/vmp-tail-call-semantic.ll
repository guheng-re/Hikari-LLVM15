; Ordinary tail on an already-supported direct CallInst (here fastcc
; helper, same CC as the non-tail protected path) is an optimization
; hint.  VMP virtualizes it and replays a normal non-tail CreateCall
; (TCK_None).  musttail stays the early "musttail call" diagnostic.
; InvokeInst / callbr / inline asm / bundles / closed ABI stay out.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.ll > %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.live.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.ll > %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.live.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.s7.ll > %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.s7.live.ll > %t.o0.s7.host.ll
; RUN: lli -force-interpreter %t.o0.s7.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.s7.ll > %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.s7.live.ll > %t.o2.s7.host.ll
; RUN: lli -force-interpreter %t.o2.s7.host.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %s | opt -S -verify-each -aesSeed=97 -passes='default<O0>' - 2>&1 | FileCheck %s --check-prefix=HOST

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()

define fastcc i32 @helper(i32 %x) noinline {
entry:
  %scaled = mul nsw i32 %x, 3
  %result = add nsw i32 %scaled, 5
  ret i32 %result
}

define i32 @reference(i32 %x) {
entry:
  %value = call fastcc i32 @helper(i32 %x)
  %result = add nsw i32 %value, 1
  ret i32 %result
}

define i32 @protected(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %value = call fastcc i32 @helper(i32 %x)
  %result = add nsw i32 %value, 1
  ret i32 %result
}

define i32 @protected_tail(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %value = tail call fastcc i32 @helper(i32 %x)
  %result = add nsw i32 %value, 1
  ret i32 %result
}

define i32 @musttail_helper(i32 %x) noinline {
entry:
  ret i32 %x
}

define i32 @unsupported_musttail(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %value = musttail call i32 @musttail_helper(i32 %x)
  ret i32 %value
}

define i32 @main() {
entry:
  %expected = call i32 @reference(i32 7)
  %actual = call i32 @protected(i32 7)
  %tailed = call i32 @protected_tail(i32 7)
  %match0 = icmp eq i32 %expected, %actual
  %match1 = icmp eq i32 %expected, %tailed
  %match = and i1 %match0, %match1
  %code = select i1 %match, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-NOT: Skipping VMP on protected:
; SKIP-NOT: Skipping VMP on protected_tail:
; SKIP-NOT: Skipping VMP on helper:
; SKIP-NOT: Skipping VMP on reference:

; VIRT-LABEL: define i32 @protected(
; VIRT-SAME: #[[PROT:[0-9]+]]
; VIRT: vmp.dispatch:
; VIRT: call fastcc i32 @helper(
; VIRT-LABEL: define i32 @protected_tail(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT-NOT: tail call
; VIRT: call fastcc i32 @helper(
; VIRT-LABEL: define {{.*}} @unsupported_musttail(
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call i32 @musttail_helper(
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }

; AARCH64: Arch: aarch64
; HOST: Skipping VMP: only AArch64 targets are supported
