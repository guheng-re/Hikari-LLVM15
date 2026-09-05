; Restricted direct InlineAsm pointer-memory: AS0 pointer in an "r"
; register used as a load/store address, optionally with ~{memory}.
; This is already accepted by isSupportedDirectInlineAsmCall
; (void / i1..i64 / AS0 ptr, I/O "r", clobbers {memory}/{cc}).
; vmp-inline-asm-semantic.ll only locks an empty-string pointer
; register copy and a pointer-free dmb ~{memory}; it does not emit
; ldr/str through a pointer.  Do not relax to "m" / "*m" / "=*r" /
; "=*m" / AS1.
;
; Host cannot execute AArch64 inline asm (lli fatal).  FileCheck +
; AArch64 llc/readobj/asm only.  O0/O2 x 97/7.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.ll > %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o0.live.ll -o - | FileCheck %s --check-prefix=ASM
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.ll > %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o2.live.ll -o - | FileCheck %s --check-prefix=ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.s7.ll > %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o0.s7.live.ll -o - | FileCheck %s --check-prefix=ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.s7.ll > %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o2.s7.live.ll -o - | FileCheck %s --check-prefix=ASM
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %s | opt -S -verify-each -aesSeed=97 -passes='default<O0>' - 2>&1 | FileCheck %s --check-prefix=HOST

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()

@g.as1 = internal addrspace(1) global i32 0

define i32 @protected_load_i32(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 asm sideeffect "ldr ${0:w}, [$1]", "=r,r,~{memory}"(ptr %p)
  ret i32 %r
}

define void @protected_store_i32(ptr %p, i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  call void asm sideeffect "str ${0:w}, [$1]", "r,r,~{memory}"(i32 %x, ptr %p)
  ret void
}

define i64 @protected_load_i64(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 asm sideeffect "ldr $0, [$1]", "=r,r,~{memory}"(ptr %p)
  ret i64 %r
}

define i32 @protected_load_tail(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = tail call i32 asm sideeffect "ldr ${0:w}, [$1]", "=r,r,~{memory}"(ptr %p)
  ret i32 %r
}

define void @protected_store_noclobber(ptr %p, i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  call void asm sideeffect "str ${0:w}, [$1]", "r,r"(i32 %x, ptr %p)
  ret void
}

define i32 @unsupported_m(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 asm "ldr $0, $1", "=r,*m"(ptr elementtype(i32) %p)
  ret i32 %r
}

define void @unsupported_indirect_r(ptr %p, i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  call void asm sideeffect "str ${1:w}, $0", "=*r,r"(ptr elementtype(i32) %p, i32 %x)
  ret void
}

define i32 @unsupported_as1() noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 asm sideeffect "ldr ${0:w}, [$1]", "=r,r,~{memory}"(ptr addrspace(1) @g.as1)
  ret i32 %r
}

define void @main() {
entry:
  ret void
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_m: inline assembly
; SKIP-DAG: Skipping VMP on unsupported_indirect_r: inline assembly
; SKIP-DAG: Skipping VMP on unsupported_as1: inline assembly
; SKIP-NOT: Skipping VMP on protected_load_i32:
; SKIP-NOT: Skipping VMP on protected_store_i32:
; SKIP-NOT: Skipping VMP on protected_load_i64:
; SKIP-NOT: Skipping VMP on protected_load_tail:
; SKIP-NOT: Skipping VMP on protected_store_noclobber:

; VIRT-LABEL: define i32 @protected_load_i32(
; VIRT-SAME: #[[PROT:[0-9]+]]
; VIRT: vmp.dispatch:
; VIRT-NOT: tail call i32 asm
; VIRT: call i32 asm sideeffect "ldr ${0:w}, [$1]", "=r,r,~{memory}"(ptr
; VIRT-LABEL: define void @protected_store_i32(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call void asm sideeffect "str ${0:w}, [$1]", "r,r,~{memory}"(i32
; VIRT-LABEL: define i64 @protected_load_i64(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call i64 asm sideeffect "ldr $0, [$1]", "=r,r,~{memory}"(ptr
; VIRT-LABEL: define i32 @protected_load_tail(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT-NOT: tail call i32 asm
; VIRT: call i32 asm sideeffect "ldr ${0:w}, [$1]", "=r,r,~{memory}"(ptr
; VIRT-LABEL: define void @protected_store_noclobber(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: call void asm sideeffect "str ${0:w}, [$1]", "r,r"(i32
; VIRT: define {{.*}} @unsupported_m({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_indirect_r({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_as1({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; ASM-DAG: ldr w{{[0-9]+}}, [x
; ASM-DAG: str w{{[0-9]+}}, [x
; ASM-DAG: ldr x{{[0-9]+}}, [x
; HOST: Skipping VMP: only AArch64 targets are supported
