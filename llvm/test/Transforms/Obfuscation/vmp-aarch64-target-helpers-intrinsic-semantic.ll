; AArch64 target-helper CallDescriptor family: clrex, hint, cls/cls64,
; sdiv/udiv i32/i64, crc32*, scalar frint32z/64z/32x/64x.f32.
; C, exact non-vararg FTy, formal type equality.  Ordinary tail is
; rejected.  +crc / +fptoint last-token gates are unchanged.
; Replay via CallDescriptor; never fold/delete.  No new opcode.
;
; Host cannot select these (AArch64-only), so no lli.
; FileCheck + AArch64 llc/readobj/asm.  O0/O2 x aesSeed 97/7.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.ll > %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+crc,+fptoint -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+crc,+fptoint %t.o0.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.ll > %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+crc,+fptoint -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+crc,+fptoint %t.o2.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.s7.ll > %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+crc,+fptoint -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+crc,+fptoint %t.o0.s7.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.s7.ll > %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+crc,+fptoint -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+crc,+fptoint %t.o2.s7.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare void @llvm.aarch64.clrex()
declare void @llvm.aarch64.hint(i32)
declare i32 @llvm.aarch64.cls(i32)
declare i32 @llvm.aarch64.cls64(i64)
declare i32 @llvm.aarch64.sdiv.i32(i32, i32)
declare i64 @llvm.aarch64.udiv.i64(i64, i64)
declare i32 @llvm.aarch64.crc32w(i32, i32)
declare float @llvm.aarch64.frint32z.f32(float)
declare void @ext_sret_byval(ptr sret(i32), ptr byval(i32))

; ----- positives -----

define void @protected_clrex() noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.clrex()
  ret void
}

define void @protected_hint() noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.hint(i32 0)
  ret void
}

define i32 @protected_cls(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.cls(i32 %x)
  ret i32 %r
}

define i32 @protected_sdiv(i32 %a, i32 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.sdiv.i32(i32 %a, i32 %b)
  ret i32 %r
}

define i64 @protected_udiv(i64 %a, i64 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 @llvm.aarch64.udiv.i64(i64 %a, i64 %b)
  ret i64 %r
}

define i32 @protected_crc32w(i32 %a, i32 %b) noinline optnone "target-features"="+crc" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.crc32w(i32 %a, i32 %b)
  ret i32 %r
}

define float @protected_frint32z(float %x) noinline optnone "target-features"="+fptoint" {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.aarch64.frint32z.f32(float %x)
  ret float %r
}

; ----- negatives -----

define void @unsupported_clrex_malformed() noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.clrex() noreturn
  ret void
}


define void @unsupported_clrex_musttail() noinline optnone {
entry:
  call void @hikari_vmp()
  musttail call void @llvm.aarch64.clrex()
  ret void
}

define void @unsupported_clrex_bundle() noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.clrex() [ "deopt"(i32 0) ]
  ret void
}

define void @unsupported_clrex_fastcc() noinline optnone {
entry:
  call void @hikari_vmp()
  call fastcc void @llvm.aarch64.clrex()
  ret void
}

define void @unsupported_hint_dynamic(i32 %imm) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.hint(i32 %imm)
  ret void
}

define void @unsupported_hint_oor() noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.hint(i32 128)
  ret void
}


define void @unsupported_hint_fastcc() noinline optnone {
entry:
  call void @hikari_vmp()
  call fastcc void @llvm.aarch64.hint(i32 0)
  ret void
}

define i32 @unsupported_cls_poison() noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.cls(i32 poison)
  ret i32 %r
}



define i32 @unsupported_sdiv_fastcc(i32 %a, i32 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc i32 @llvm.aarch64.sdiv.i32(i32 %a, i32 %b)
  ret i32 %r
}



define i32 @unsupported_crc32_fastcc(i32 %a, i32 %b) noinline optnone "target-features"="+crc" {
entry:
  call void @hikari_vmp()
  %r = call fastcc i32 @llvm.aarch64.crc32w(i32 %a, i32 %b)
  ret i32 %r
}

define i32 @unsupported_crc32_poison(i32 %a) noinline optnone "target-features"="+crc" {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.aarch64.crc32w(i32 %a, i32 poison)
  ret i32 %r
}


define float @unsupported_frint_fastcc(float %x) noinline optnone "target-features"="+fptoint" {
entry:
  call void @hikari_vmp()
  %r = call fastcc float @llvm.aarch64.frint32z.f32(float %x)
  ret float %r
}

define float @unsupported_frint_poison() noinline optnone "target-features"="+fptoint" {
entry:
  call void @hikari_vmp()
  %r = call float @llvm.aarch64.frint32z.f32(float poison)
  ret float %r
}

define void @unsupported_as1_arg(ptr addrspace(1) %unused) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.clrex()
  ret void
}

define void @unsupported_sret(ptr sret(i32) %p, ptr byval(i32) %q) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @ext_sret_byval(ptr sret(i32) %p, ptr byval(i32) %q)
  ret void
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_clrex_malformed: unsupported clrex
; SKIP-DAG: Skipping VMP on unsupported_clrex_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_clrex_bundle: unsupported clrex
; SKIP-DAG: Skipping VMP on unsupported_clrex_fastcc: unsupported clrex
; SKIP-DAG: Skipping VMP on unsupported_hint_dynamic: unsupported hint
; SKIP-DAG: Skipping VMP on unsupported_hint_oor: unsupported hint
; SKIP-DAG: Skipping VMP on unsupported_hint_fastcc: unsupported hint
; SKIP-DAG: Skipping VMP on unsupported_cls_poison: unsupported cls
; SKIP-DAG: Skipping VMP on unsupported_sdiv_fastcc: unsupported sdiv
; SKIP-DAG: Skipping VMP on unsupported_crc32_fastcc: unsupported crc32
; SKIP-DAG: Skipping VMP on unsupported_crc32_poison: unsupported crc32
; SKIP-DAG: Skipping VMP on unsupported_frint_fastcc: unsupported frint
; SKIP-DAG: Skipping VMP on unsupported_frint_poison: unsupported frint
; SKIP-DAG: Skipping VMP on unsupported_as1_arg: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_sret: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_clrex:
; SKIP-NOT: Skipping VMP on protected_hint:
; SKIP-NOT: Skipping VMP on protected_cls:
; SKIP-NOT: Skipping VMP on protected_sdiv:
; SKIP-NOT: Skipping VMP on protected_udiv:
; SKIP-NOT: Skipping VMP on protected_crc32w:
; SKIP-NOT: Skipping VMP on protected_frint32z:

; VIRT: define void @protected_clrex({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: call void @llvm.aarch64.clrex()
; VIRT: }
; VIRT: define void @protected_hint({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: call void @llvm.aarch64.hint(i32 0)
; VIRT: }
; VIRT: define i32 @protected_cls({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: call i32 @llvm.aarch64.cls(i32
; VIRT: }
; VIRT: define i32 @protected_sdiv({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: call i32 @llvm.aarch64.sdiv.i32(i32
; VIRT: }
; VIRT: define i64 @protected_udiv({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: call i64 @llvm.aarch64.udiv.i64(i64
; VIRT: }
; VIRT: define i32 @protected_crc32w({{.*}} #[[PROTCRC:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: call i32 @llvm.aarch64.crc32w(i32
; VIRT: }
; VIRT: define float @protected_frint32z({{.*}} #[[PROTFR:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: call float @llvm.aarch64.frint32z.f32(float
; VIRT: }
; VIRT: define {{.*}} @unsupported_clrex_malformed({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_clrex_musttail({{.*}} #[[UNSUPMUST:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call void @llvm.aarch64.clrex()
; VIRT: define {{.*}} @unsupported_clrex_bundle({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_clrex_fastcc({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_hint_dynamic({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_hint_oor({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_hint_fastcc({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_cls_poison({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_sdiv_fastcc({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_crc32_fastcc(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_crc32_poison(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_frint_fastcc(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_frint_poison(
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_as1_arg({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_sret({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[PROTCRC]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[PROTFR]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPMUST]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPMUST]] = { {{.*}}"hikari.vmp.selected"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; AARCH64-ASM-DAG: clrex
; AARCH64-ASM-DAG: cls{{.*}}w
; AARCH64-ASM-DAG: sdiv
; AARCH64-ASM-DAG: udiv
; AARCH64-ASM-DAG: crc32w
; AARCH64-ASM-DAG: frint32z
