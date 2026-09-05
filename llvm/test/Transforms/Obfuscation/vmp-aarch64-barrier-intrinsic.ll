; llvm.aarch64.dmb / dsb / isb: C, exact non-vararg void(i32).  CRm is
; a CallDescriptor immediate (never a VReg).  dmb/dsb CRm in
; {1,2,3,5,6,7,9,10,11,13,14,15}; isb SY (15) only.  Replay; never
; fold or delete.  Ordinary tail accepted and replayed as non-tail;
; see vmp-direct-call-tail-eligibility-semantic.ll.
;
; Host cannot select these (AArch64-only), so no lli.
; FileCheck + AArch64 llc/readobj/asm only.
;
; Reserved CRm, non-SY isb, and dynamic CRm stay rejected.  Call-site
; noreturn is the probed-legal malformed form.
;
; FileCheck + AArch64 llc/readobj/asm.  O0/O2 x aesSeed 97/7.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.ll > %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o0.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.ll > %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o2.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.s7.ll > %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o0.s7.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.s7.ll > %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o2.s7.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare void @llvm.aarch64.dmb(i32)
declare void @llvm.aarch64.dsb(i32)
declare void @llvm.aarch64.isb(i32)
declare void @ext_sret_byval(ptr sret(i32), ptr byval(i32))

; ----- positives -----

define i32 @protected(i32 %val) noinline optnone {
entry:
  call void @hikari_vmp()
  %slot = alloca i32, align 4
  store i32 %val, ptr %slot, align 4
  call void @llvm.aarch64.dmb(i32 15)
  call void @llvm.aarch64.dsb(i32 11)
  call void @llvm.aarch64.isb(i32 15)
  %out = load i32, ptr %slot, align 4
  ret i32 %out
}

define void @protected_dmb_oshld() noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.dmb(i32 1)
  ret void
}

; ----- negatives -----

define void @unsupported_malformed() noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.dmb(i32 15) noreturn
  ret void
}

define void @unsupported_as1_arg(ptr addrspace(1) %unused) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.dmb(i32 15)
  ret void
}

define void @unsupported_dmb_crm0() noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.dmb(i32 0)
  ret void
}

define void @unsupported_dmb_crm4() noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.dmb(i32 4)
  ret void
}

define void @unsupported_isb_not_sy() noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.isb(i32 11)
  ret void
}

define void @unsupported_dmb_dynamic(i32 %opt) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.dmb(i32 %opt)
  ret void
}


define void @unsupported_musttail(i32 %unused) noinline optnone {
entry:
  call void @hikari_vmp()
  musttail call void @llvm.aarch64.dmb(i32 15)
  ret void
}

define void @unsupported_bundle() noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.aarch64.dsb(i32 11) [ "deopt"(i32 0) ]
  ret void
}

define void @unsupported_fastcc() noinline optnone {
entry:
  call void @hikari_vmp()
  call fastcc void @llvm.aarch64.isb(i32 15)
  ret void
}

define void @unsupported_sret(ptr sret(i32) %p, ptr byval(i32) %q) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @ext_sret_byval(ptr sret(i32) %p, ptr byval(i32) %q)
  ret void
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_malformed: unsupported dmb
; SKIP-DAG: Skipping VMP on unsupported_as1_arg: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_dmb_crm0: unsupported dmb
; SKIP-DAG: Skipping VMP on unsupported_dmb_crm4: unsupported dmb
; SKIP-DAG: Skipping VMP on unsupported_isb_not_sy: unsupported isb
; SKIP-DAG: Skipping VMP on unsupported_dmb_dynamic: unsupported dmb
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported dsb
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported isb
; SKIP-DAG: Skipping VMP on unsupported_sret: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected:
; SKIP-NOT: Skipping VMP on protected_dmb_oshld:

; VIRT: define i32 @protected({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call void @hikari_vmp()
; Barriers are re-emitted with the original CRm immediates (never deleted).
; VIRT-DAG: call void @llvm.aarch64.dmb(i32 15)
; VIRT-DAG: call void @llvm.aarch64.dsb(i32 11)
; VIRT-DAG: call void @llvm.aarch64.isb(i32 15)
; VIRT: }
; VIRT: define void @protected_dmb_oshld({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: call void @llvm.aarch64.dmb(i32 1)
; VIRT: }
; VIRT: define {{.*}} @unsupported_malformed({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_as1_arg({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_dmb_crm0({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_dmb_crm4({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_isb_not_sy({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_dmb_dynamic({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_musttail({{.*}} #[[UNSUPMUST:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call void @llvm.aarch64.dmb(i32 15)
; VIRT: define {{.*}} @unsupported_bundle({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fastcc({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_sret({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPMUST]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPMUST]] = { {{.*}}"hikari.vmp.selected"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; Replay lowers to the real barrier encodings (not deleted).
; AARCH64-ASM-DAG: dmb{{.*}}sy
; AARCH64-ASM-DAG: dsb{{.*}}ish
; AARCH64-ASM-DAG: isb
