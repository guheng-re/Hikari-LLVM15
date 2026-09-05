; llvm.stackguard(): system stack-protector cookie.  C, exact
; non-vararg ptr(), AS0, zero args.  Replay via CallDescriptor into
; the pointer VReg; never precompute the canary.  VMP does not insert
; @__stack_chk_guard or ssp attributes.
;
; AArch64 LOAD_STACK_GUARD Post-RA requires @__stack_chk_guard in the
; module (ISel memoperands).  llvm.compiler.used keeps it through O2
; GlobalDCE.  Host lli/JIT cannot provide the symbol (segfault), so no
; lli.  FileCheck + AArch64 llc/readobj/asm only.
;
; Non-AS0 result cannot be declared (fixed llvm_ptr_ty).  AS1 unused
; argument hits the argument-type gate.  Call-site noreturn is the
; probed-legal malformed form.  Ordinary tail accepted and replayed as TCK_None.
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

; Required by AArch64 LOAD_STACK_GUARD lowering.  Not inserted by VMP.
@__stack_chk_guard = external global ptr
@llvm.compiler.used = appending global [1 x ptr] [ptr @__stack_chk_guard], section "llvm.metadata"

declare void @hikari_vmp()
declare ptr @llvm.stackguard()
declare void @ext_sret_byval(ptr sret(i32), ptr byval(i32))

; ----- positives -----

define i32 @protected() noinline optnone {
entry:
  call void @hikari_vmp()
  %a = call ptr @llvm.stackguard()
  %b = call ptr @llvm.stackguard()
  %eq = icmp eq ptr %a, %b
  %c = zext i1 %eq to i32
  ret i32 %c
}

define ptr @protected_loop(i32 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %g = call ptr @llvm.stackguard()
  store ptr %g, ptr %slot, align 8
  %i1 = add i32 %i, 1
  %more = icmp slt i32 %i1, %n
  br i1 %more, label %loop, label %done

done:
  %out = load ptr, ptr %slot, align 8
  ret ptr %out
}

; ----- negatives -----

define ptr @unsupported_malformed() noinline optnone {
entry:
  call void @hikari_vmp()
  %a = call ptr @llvm.stackguard() noreturn
  ret ptr %a
}

define ptr @unsupported_as1_arg(ptr addrspace(1) %unused) noinline optnone {
entry:
  call void @hikari_vmp()
  %a = call ptr @llvm.stackguard()
  ret ptr %a
}


define ptr @unsupported_musttail() noinline optnone {
entry:
  call void @hikari_vmp()
  %a = musttail call ptr @llvm.stackguard()
  ret ptr %a
}

define ptr @unsupported_bundle() noinline optnone {
entry:
  call void @hikari_vmp()
  %a = call ptr @llvm.stackguard() [ "deopt"(i32 0) ]
  ret ptr %a
}

define ptr @unsupported_fastcc() noinline optnone {
entry:
  call void @hikari_vmp()
  %a = call fastcc ptr @llvm.stackguard()
  ret ptr %a
}

define void @unsupported_sret(ptr sret(i32) %p, ptr byval(i32) %q) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @ext_sret_byval(ptr sret(i32) %p, ptr byval(i32) %q)
  ret void
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_malformed: unsupported stackguard
; SKIP-DAG: Skipping VMP on unsupported_as1_arg: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported stackguard
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported stackguard
; SKIP-DAG: Skipping VMP on unsupported_sret: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected:
; SKIP-NOT: Skipping VMP on protected_loop:

; VIRT: @__stack_chk_guard = external global ptr
; VIRT: define i32 @protected({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call void @hikari_vmp()
; The canary is re-emitted as the original intrinsic (never null /
; inttoptr / a precomputed constant).
; VIRT-DAG: [[SG0:%.*]] = call ptr @llvm.stackguard()
; VIRT-DAG: [[SG1:%.*]] = call ptr @llvm.stackguard()
; VIRT-DAG: store volatile ptr [[SG0]], ptr {{.*}}, align 8
; VIRT-DAG: store volatile ptr [[SG1]], ptr {{.*}}, align 8
; VIRT: }
; VIRT: define ptr @protected_loop({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: [[SL:%.*]] = call ptr @llvm.stackguard()
; VIRT-DAG: store volatile ptr [[SL]], ptr {{.*}}, align 8
; VIRT: }
; VIRT: define {{.*}} @unsupported_malformed({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_as1_arg({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_musttail({{.*}} #[[UNSUPMUST:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call ptr @llvm.stackguard()
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
; LOAD_STACK_GUARD materializes the cookie from __stack_chk_guard.
; AARCH64-ASM: __stack_chk_guard
