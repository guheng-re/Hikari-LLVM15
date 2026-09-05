; llvm.flt.rounds(): current C rounding mode.  C, exact non-vararg
; i32(), zero args.  Replay via CallDescriptor into the i32 integer
; VReg; never pre-fold or delete.  AArch64 lowering reads FPCR[23:22].
; Ordinary tail accepted and replayed as TCK_None.  set.rounding is a separate family.
;
; Host IntrinsicLowering replaces with constant 1, so no lli.
; FileCheck + AArch64 llc/readobj/asm only.
;
; Non-i32 / non-i32() FTy cannot share a module with the canonical
; declare (verifier: incompatible signature).  AS1 unused argument
; hits the argument-type gate.  Call-site noreturn is the probed-legal
; malformed form.
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
declare void @ext_sret_byval(ptr sret(i32), ptr byval(i32))

; ----- positives -----

define i32 @protected() noinline optnone {
entry:
  call void @hikari_vmp()
  %a = call i32 @llvm.flt.rounds()
  %b = call i32 @llvm.flt.rounds()
  %s = add i32 %a, %b
  ret i32 %s
}

define i32 @protected_use() noinline optnone {
entry:
  call void @hikari_vmp()
  %slot = alloca i32, align 4
  %r = call i32 @llvm.flt.rounds()
  %m = and i32 %r, 3
  store i32 %m, ptr %slot, align 4
  %v = load i32, ptr %slot, align 4
  ret i32 %v
}

; ----- negatives -----

define i32 @unsupported_malformed() noinline optnone {
entry:
  call void @hikari_vmp()
  %a = call i32 @llvm.flt.rounds() noreturn
  ret i32 %a
}

define i32 @unsupported_as1_arg(ptr addrspace(1) %unused) noinline optnone {
entry:
  call void @hikari_vmp()
  %a = call i32 @llvm.flt.rounds()
  ret i32 %a
}


define i32 @unsupported_musttail() noinline optnone {
entry:
  call void @hikari_vmp()
  %a = musttail call i32 @llvm.flt.rounds()
  ret i32 %a
}

define i32 @unsupported_bundle() noinline optnone {
entry:
  call void @hikari_vmp()
  %a = call i32 @llvm.flt.rounds() [ "deopt"(i32 0) ]
  ret i32 %a
}

define i32 @unsupported_fastcc() noinline optnone {
entry:
  call void @hikari_vmp()
  %a = call fastcc i32 @llvm.flt.rounds()
  ret i32 %a
}

define void @unsupported_sret(ptr sret(i32) %p, ptr byval(i32) %q) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @ext_sret_byval(ptr sret(i32) %p, ptr byval(i32) %q)
  ret void
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_malformed: unsupported flt.rounds
; SKIP-DAG: Skipping VMP on unsupported_as1_arg: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported flt.rounds
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported flt.rounds
; SKIP-DAG: Skipping VMP on unsupported_sret: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected:
; SKIP-NOT: Skipping VMP on protected_use:

; VIRT: define i32 @protected({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call void @hikari_vmp()
; Rounding mode is re-emitted as the original intrinsic (never a
; constant 1 / Move).
; VIRT-DAG: [[R0:%.*]] = call i32 @llvm.flt.rounds()
; VIRT-DAG: [[R1:%.*]] = call i32 @llvm.flt.rounds()
; VIRT: }
; VIRT: define i32 @protected_use({{.*}} #[[PROT]] {
; VIRT: [[SLOT:%.*]] = alloca i32, align 4
; VIRT: store volatile ptr [[SLOT]], ptr {{.*}}, align 8
; VIRT: vmp.dispatch:
; VIRT-DAG: [[RU:%.*]] = call i32 @llvm.flt.rounds()
; VIRT-DAG: store i32 {{.*}}, ptr {{.*}}, align 4
; VIRT-DAG: load i32, ptr {{.*}}, align 4
; VIRT: }
; VIRT: define {{.*}} @unsupported_malformed({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_as1_arg({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_musttail({{.*}} #[[UNSUPMUST:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call i32 @llvm.flt.rounds()
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
; Rounding mode is read from FPCR (not a synthesized constant).
; AARCH64-ASM: mrs{{.*}}FPCR
