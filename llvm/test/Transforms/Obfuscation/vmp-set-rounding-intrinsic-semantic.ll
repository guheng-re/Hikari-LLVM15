; llvm.set.rounding(i32): set the C rounding mode.  C, exact non-vararg
; void(i32), formal type equality.  Replay via CallDescriptor from the
; i32 integer VReg; never delete.  AArch64 lowering writes FPCR[23:22].
; Ordinary tail accepted and replayed as TCK_None.  Paired flt.rounds stays CallDescriptor
; replay so the environment remains observable.
;
; Host IntrinsicLowering has no set.rounding case (pure interpreter
; fatals), so no lli.  FileCheck + AArch64 llc/readobj/asm only.
;
; Non-void(i32) FTy cannot share a module with the canonical declare
; (verifier: incompatible signature).  poison mode and AS1 unused
; argument are the type/operand negatives.  Call-site noreturn is the
; probed-legal malformed form.
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
declare i32 @llvm.flt.rounds()
declare void @llvm.set.rounding(i32)
declare void @ext_sret_byval(ptr sret(i32), ptr byval(i32))

; ----- positives -----

define i32 @protected() noinline optnone {
entry:
  call void @hikari_vmp()
  %old = call i32 @llvm.flt.rounds()
  call void @llvm.set.rounding(i32 %old)
  %new = call i32 @llvm.flt.rounds()
  %eq = icmp eq i32 %old, %new
  %c = zext i1 %eq to i32
  ret i32 %c
}

define i32 @protected_use() noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.set.rounding(i32 1)
  %r = call i32 @llvm.flt.rounds()
  %m = and i32 %r, 3
  ret i32 %m
}

; ----- negatives -----

define void @unsupported_malformed() noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.set.rounding(i32 1) noreturn
  ret void
}

define void @unsupported_as1_arg(ptr addrspace(1) %unused) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.set.rounding(i32 1)
  ret void
}

define void @unsupported_poison() noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.set.rounding(i32 poison)
  ret void
}


define void @unsupported_musttail(i32 %m) noinline optnone {
entry:
  call void @hikari_vmp()
  musttail call void @llvm.set.rounding(i32 %m)
  ret void
}

define void @unsupported_bundle() noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.set.rounding(i32 1) [ "deopt"(i32 0) ]
  ret void
}

define void @unsupported_fastcc() noinline optnone {
entry:
  call void @hikari_vmp()
  call fastcc void @llvm.set.rounding(i32 1)
  ret void
}

define void @unsupported_sret(ptr sret(i32) %p, ptr byval(i32) %q) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @ext_sret_byval(ptr sret(i32) %p, ptr byval(i32) %q)
  ret void
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_malformed: unsupported set.rounding
; SKIP-DAG: Skipping VMP on unsupported_as1_arg: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_poison: unsupported set.rounding
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported set.rounding
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported set.rounding
; SKIP-DAG: Skipping VMP on unsupported_sret: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected:
; SKIP-NOT: Skipping VMP on protected_use:

; VIRT: define i32 @protected({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call void @hikari_vmp()
; Environment is re-emitted as the original pair (never deleted).
; VIRT-DAG: call i32 @llvm.flt.rounds()
; VIRT-DAG: call void @llvm.set.rounding(i32
; VIRT: }
; VIRT: define i32 @protected_use({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: call void @llvm.set.rounding(i32
; VIRT-DAG: call i32 @llvm.flt.rounds()
; VIRT: }
; VIRT: define {{.*}} @unsupported_malformed({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_as1_arg({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_poison({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_musttail({{.*}} #[[UNSUPMUST:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call void @llvm.set.rounding(i32 %m)
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
; Rounding mode is written through FPCR (not deleted).
; AARCH64-ASM: mrs{{.*}}FPCR
; AARCH64-ASM: msr{{.*}}FPCR
