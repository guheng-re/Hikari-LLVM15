; Scalar llvm.thread.pointer: runtime TLS base, never a constant or
; global.  LangRef: pointer to the current thread's TLS area.
; AArch64 ISel: AArch64ISD::THREAD_POINTER -> MRS TPIDR_EL0.
; VMP replays via CallDescriptor (ptr(), C, attributes, DebugLoc) and
; stores the result in the pointer VReg frame.
;
; Host IntrinsicLowering has no thread.pointer case (lli fatals) and
; x86 vs AArch64 TLS ABI differs, so this lit is FileCheck + AArch64
; llc/readobj/asm only.  Do not fold the call away.
;
; Rejected: musttail, bundles, fastcc, indirect, sret, AS1 args,
; poison/undef icmp against TP (zero-arg intrinsic has no poison operand
; form the verifier will accept), and malformed call-site noreturn /
; returns_twice.
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

@g = global i32 0
@tls = thread_local global i32 0

declare void @hikari_vmp()
declare ptr @llvm.thread.pointer()
declare void @ext_sret_byval(ptr sret(i32), ptr byval(i32))

; ----- positives -----

define ptr @protected_once() noinline optnone {
entry:
  call void @hikari_vmp()
  %p = call ptr @llvm.thread.pointer()
  ret ptr %p
}

define i1 @protected_twice() noinline optnone {
entry:
  call void @hikari_vmp()
  %a = call ptr @llvm.thread.pointer()
  %b = call ptr @llvm.thread.pointer()
  %eq = icmp eq ptr %a, %b
  ret i1 %eq
}

define i1 @protected_cmp() noinline optnone {
entry:
  call void @hikari_vmp()
  %tp = call ptr @llvm.thread.pointer()
  %ng = icmp ne ptr %tp, @g
  %nt = icmp ne ptr %tp, @tls
  %ok = and i1 %ng, %nt
  ret i1 %ok
}

define ptr @protected_mem() noinline optnone {
entry:
  call void @hikari_vmp()
  %tp = call ptr @llvm.thread.pointer()
  %slot = alloca ptr, align 8
  store ptr %tp, ptr %slot, align 8
  %ld = load ptr, ptr %slot, align 8
  %gep = getelementptr i8, ptr %ld, i64 0
  ret ptr %gep
}

define i32 @protected_br() noinline optnone {
entry:
  call void @hikari_vmp()
  %a = call ptr @llvm.thread.pointer()
  %b = call ptr @llvm.thread.pointer()
  %eq = icmp eq ptr %a, %b
  br i1 %eq, label %same, label %diff

same:
  ret i32 1

diff:
  ret i32 0
}

define ptr @protected_loop(i32 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  %slot = alloca ptr, align 8
  store ptr null, ptr %slot, align 8
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %tp = call ptr @llvm.thread.pointer()
  store ptr %tp, ptr %slot, align 8
  %i1 = add i32 %i, 1
  %more = icmp slt i32 %i1, %n
  br i1 %more, label %loop, label %done

done:
  %out = load ptr, ptr %slot, align 8
  ret ptr %out
}

define ptr @protected_tail() noinline optnone {
entry:
  call void @hikari_vmp()
  %p = tail call ptr @llvm.thread.pointer()
  ret ptr %p
}

; ----- negatives -----

define ptr @unsupported_musttail() noinline optnone {
entry:
  call void @hikari_vmp()
  %p = musttail call ptr @llvm.thread.pointer()
  ret ptr %p
}

define ptr @unsupported_bundle() noinline optnone {
entry:
  call void @hikari_vmp()
  %p = call ptr @llvm.thread.pointer() [ "deopt"(i32 0) ]
  ret ptr %p
}

define ptr @unsupported_fastcc() noinline optnone {
entry:
  call void @hikari_vmp()
  %p = call fastcc ptr @llvm.thread.pointer()
  ret ptr %p
}


define ptr @unsupported_indirect(ptr %fp) noinline optnone {
entry:
  call void @hikari_vmp()
  %p = call ptr %fp() [ "deopt"(i32 0) ]
  ret ptr %p
}

define void @unsupported_sret(ptr sret(i32) %p, ptr byval(i32) %q) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @ext_sret_byval(ptr sret(i32) %p, ptr byval(i32) %q)
  ret void
}

define ptr @unsupported_as1_arg(ptr addrspace(1) %unused) noinline optnone {
entry:
  call void @hikari_vmp()
  %p = call ptr @llvm.thread.pointer()
  ret ptr %p
}

; Zero-arg intrinsic: poison cannot appear as a TP operand.  The only
; legal poison form next to a live TP call is a pointer icmp; that
; deselects via the comparison operand gate (poison is not a VReg).
define i1 @unsupported_poison() noinline optnone {
entry:
  call void @hikari_vmp()
  %p = call ptr @llvm.thread.pointer()
  %c = icmp eq ptr %p, poison
  ret i1 %c
}

; Call-site noreturn on a readnone register read is verifier-legal
; (same probe as sponentry) but semantically malformed.  Dedicated
; thread.pointer gate rejects doesNotReturn.
define ptr @unsupported_malformed() noinline optnone {
entry:
  call void @hikari_vmp()
  %p = call ptr @llvm.thread.pointer() noreturn
  ret ptr %p
}

define ptr @unsupported_returns_twice() noinline optnone {
entry:
  call void @hikari_vmp()
  %p = call ptr @llvm.thread.pointer() returns_twice
  ret ptr %p
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported thread.pointer
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported thread.pointer
; SKIP-DAG: Skipping VMP on unsupported_indirect: indirect call
; SKIP-DAG: Skipping VMP on unsupported_sret: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_as1_arg: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_poison: unsupported comparison
; SKIP-DAG: Skipping VMP on unsupported_malformed: unsupported thread.pointer
; SKIP-DAG: Skipping VMP on unsupported_returns_twice: unsupported thread.pointer
; SKIP-NOT: Skipping VMP on protected_once:
; SKIP-NOT: Skipping VMP on protected_twice:
; SKIP-NOT: Skipping VMP on protected_cmp:
; SKIP-NOT: Skipping VMP on protected_mem:
; SKIP-NOT: Skipping VMP on protected_br:
; SKIP-NOT: Skipping VMP on protected_loop:
; SKIP-NOT: Skipping VMP on protected_tail:

; VIRT: define ptr @protected_once({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call void @hikari_vmp()
; VIRT-NOT: store volatile ptr @g
; VIRT-NOT: store volatile ptr @tls
; VIRT-DAG: [[TP:%.*]] = call ptr @llvm.thread.pointer()
; VIRT-DAG: store volatile ptr [[TP]], ptr {{.*}}, align 8
; VIRT: }
; VIRT: define i1 @protected_twice({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call ptr @llvm.thread.pointer()
; VIRT: call ptr @llvm.thread.pointer()
; VIRT: }
; VIRT: define i1 @protected_cmp({{.*}} #[[PROT]] {
; Globals are materialized into pointer VRegs; the TP call is not
; replaced by @g or @tls.
; VIRT-DAG: store volatile ptr @g
; VIRT-DAG: store volatile ptr @tls
; VIRT: vmp.dispatch:
; VIRT-DAG: call ptr @llvm.thread.pointer()
; VIRT: }
; VIRT: define ptr @protected_mem({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: [[MP:%.*]] = call ptr @llvm.thread.pointer()
; VIRT-DAG: store volatile ptr [[MP]], ptr {{.*}}, align 8
; VIRT: }
; VIRT: define i32 @protected_br({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call ptr @llvm.thread.pointer()
; VIRT: call ptr @llvm.thread.pointer()
; VIRT: }
; VIRT: define ptr @protected_loop({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: call ptr @llvm.thread.pointer()
; VIRT: }
; VIRT: define ptr @protected_tail({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: tail call ptr @llvm.thread.pointer
; VIRT-DAG: [[TL:%.*]] = call ptr @llvm.thread.pointer()
; VIRT-DAG: store volatile ptr [[TL]], ptr {{.*}}, align 8
; VIRT: }
; VIRT: define {{.*}} @unsupported_musttail({{.*}} #[[UNSUPMUST:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_bundle({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fastcc({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_indirect({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_sret({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_as1_arg({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_poison({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_malformed({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_returns_twice({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPMUST]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPMUST]] = { {{.*}}"hikari.vmp.selected"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; AARCH64-ASM: TPIDR_EL0
