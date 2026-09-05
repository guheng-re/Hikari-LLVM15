; llvm.readcyclecounter(): target cycle counter.  C, exact non-vararg
; i64(), zero args.  Replay via CallDescriptor into the i64 integer
; VReg; never pre-fold or delete.  AArch64 ISel is MRS PMCCNTR_EL0
; with +perfmon (else 0).  Ordinary tail accepted and replayed as TCK_None.
;
; Host IntrinsicLowering warns and replaces with 0, so no lli.
; FileCheck + AArch64 llc/readobj/asm only.  llc uses +perfmon so the
; replayed call is not target-folded to xzr.
;
; Non-i64 / non-i64() FTy cannot share a module with the canonical
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
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+perfmon -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+perfmon %t.o0.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.ll > %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+perfmon -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+perfmon %t.o2.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.s7.ll > %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+perfmon -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+perfmon %t.o0.s7.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.s7.ll > %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+perfmon -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -mattr=+perfmon %t.o2.s7.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare i64 @llvm.readcyclecounter()
declare void @ext_sret_byval(ptr sret(i32), ptr byval(i32))

; ----- positives -----

define i64 @protected() noinline optnone {
entry:
  call void @hikari_vmp()
  %a = call i64 @llvm.readcyclecounter()
  %b = call i64 @llvm.readcyclecounter()
  %s = add i64 %a, %b
  ret i64 %s
}

define i64 @protected_use() noinline optnone {
entry:
  call void @hikari_vmp()
  %slot = alloca i64, align 8
  %c = call i64 @llvm.readcyclecounter()
  store i64 %c, ptr %slot, align 8
  %v = load i64, ptr %slot, align 8
  %m = and i64 %v, 255
  ret i64 %m
}

; ----- negatives -----

define i64 @unsupported_malformed() noinline optnone {
entry:
  call void @hikari_vmp()
  %a = call i64 @llvm.readcyclecounter() noreturn
  ret i64 %a
}

define i64 @unsupported_as1_arg(ptr addrspace(1) %unused) noinline optnone {
entry:
  call void @hikari_vmp()
  %a = call i64 @llvm.readcyclecounter()
  ret i64 %a
}


define i64 @unsupported_musttail() noinline optnone {
entry:
  call void @hikari_vmp()
  %a = musttail call i64 @llvm.readcyclecounter()
  ret i64 %a
}

define i64 @unsupported_bundle() noinline optnone {
entry:
  call void @hikari_vmp()
  %a = call i64 @llvm.readcyclecounter() [ "deopt"(i32 0) ]
  ret i64 %a
}

define i64 @unsupported_fastcc() noinline optnone {
entry:
  call void @hikari_vmp()
  %a = call fastcc i64 @llvm.readcyclecounter()
  ret i64 %a
}

define void @unsupported_sret(ptr sret(i32) %p, ptr byval(i32) %q) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @ext_sret_byval(ptr sret(i32) %p, ptr byval(i32) %q)
  ret void
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_malformed: unsupported readcyclecounter
; SKIP-DAG: Skipping VMP on unsupported_as1_arg: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported readcyclecounter
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported readcyclecounter
; SKIP-DAG: Skipping VMP on unsupported_sret: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected:
; SKIP-NOT: Skipping VMP on protected_use:

; VIRT: define i64 @protected({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call void @hikari_vmp()
; Cycle counter is re-emitted as the original intrinsic (never a
; constant 0 / Move).
; VIRT-DAG: [[C0:%.*]] = call i64 @llvm.readcyclecounter()
; VIRT-DAG: [[C1:%.*]] = call i64 @llvm.readcyclecounter()
; VIRT-DAG: store volatile i64 [[C0]], ptr {{.*}}, align 4
; VIRT-DAG: store volatile i64 [[C1]], ptr {{.*}}, align 4
; VIRT: }
; VIRT: define i64 @protected_use({{.*}} #[[PROT]] {
; Interpreter frame also has i64 allocas; the user slot is the
; pointer published into the pointer VReg.
; VIRT: store volatile ptr {{.*}}, ptr {{.*}}, align 8
; VIRT: vmp.dispatch:
; VIRT-DAG: [[CU:%.*]] = call i64 @llvm.readcyclecounter()
; VIRT-DAG: store volatile i64 [[CU]], ptr {{.*}}, align 4
; VIRT-DAG: store i64 {{.*}}, ptr {{.*}}, align 8
; VIRT-DAG: load i64, ptr {{.*}}, align 8
; VIRT: }
; VIRT: define {{.*}} @unsupported_malformed({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_as1_arg({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_musttail({{.*}} #[[UNSUPMUST:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call i64 @llvm.readcyclecounter()
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
; +perfmon lowering of the replayed intrinsic (not xzr).
; AARCH64-ASM: mrs{{.*}}PMCCNTR_EL0
