; llvm.stacksave / llvm.stackrestore: C, exact non-vararg ptr() /
; void(ptr), AS0, operand type equality.  Replay via CallDescriptor;
; never fold stack state.  Entry dynamic alloca in the same function
; is "dynamic stack state".  Ordinary tail accepted and replayed as TCK_None.
;
; Host IntrinsicLowering: stacksave -> null, stackrestore -> nop, so
; triple-swapped lli -force-interpreter is meaningful reference/protected
; parity (not native SP capture).  AArch64 llc/readobj remain the
; codegen check.
;
; FileCheck + host lli + AArch64 llc/readobj.  O0/O2 x aesSeed 97/7.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.ll > %t.o0.live.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.live.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.ll > %t.o2.live.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.live.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.s7.ll > %t.o0.s7.live.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.s7.live.ll > %t.o0.s7.host.ll
; RUN: lli -force-interpreter %t.o0.s7.host.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.s7.ll > %t.o2.s7.live.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.s7.live.ll > %t.o2.s7.host.ll
; RUN: lli -force-interpreter %t.o2.s7.host.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare ptr @llvm.stacksave()
declare void @llvm.stackrestore(ptr)
declare void @ext_sret_byval(ptr sret(i32), ptr byval(i32))

; ----- reference -----

define i32 @reference() noinline {
entry:
  %a = call ptr @llvm.stacksave()
  call void @llvm.stackrestore(ptr %a)
  %b = call ptr @llvm.stacksave()
  call void @llvm.stackrestore(ptr %b)
  %eq = icmp eq ptr %a, %b
  %c = zext i1 %eq to i32
  ret i32 %c
}

define i32 @reference_nested() noinline {
entry:
  %outer = call ptr @llvm.stacksave()
  %inner = call ptr @llvm.stacksave()
  %p = alloca i32, align 4
  store i32 42, ptr %p, align 4
  %v = load i32, ptr %p, align 4
  call void @llvm.stackrestore(ptr %inner)
  call void @llvm.stackrestore(ptr %outer)
  ret i32 %v
}

; ----- positives -----

define i32 @protected() noinline optnone {
entry:
  call void @hikari_vmp()
  %a = call ptr @llvm.stacksave()
  call void @llvm.stackrestore(ptr %a)
  %b = call ptr @llvm.stacksave()
  call void @llvm.stackrestore(ptr %b)
  %eq = icmp eq ptr %a, %b
  %c = zext i1 %eq to i32
  ret i32 %c
}

define i32 @protected_nested() noinline optnone {
entry:
  call void @hikari_vmp()
  %outer = call ptr @llvm.stacksave()
  %inner = call ptr @llvm.stacksave()
  %p = alloca i32, align 4
  store i32 42, ptr %p, align 4
  %v = load i32, ptr %p, align 4
  call void @llvm.stackrestore(ptr %inner)
  call void @llvm.stackrestore(ptr %outer)
  ret i32 %v
}

; ----- negatives -----

; Entry dynamic alloca + stacksave/restore: prologue alloca would
; reorder stack state.
define i32 @unsupported_dyn_alloca_stackstate(i64 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  %tok = call ptr @llvm.stacksave()
  %p = alloca i32, i64 %n, align 4
  store i32 1, ptr %p, align 4
  call void @llvm.stackrestore(ptr %tok)
  ret i32 0
}

define ptr @unsupported_malformed() noinline optnone {
entry:
  call void @hikari_vmp()
  %a = call ptr @llvm.stacksave() noreturn
  ret ptr %a
}

define void @unsupported_restore_poison() noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.stackrestore(ptr poison)
  ret void
}

define ptr @unsupported_as1_arg(ptr addrspace(1) %unused) noinline optnone {
entry:
  call void @hikari_vmp()
  %a = call ptr @llvm.stacksave()
  call void @llvm.stackrestore(ptr %a)
  ret ptr %a
}


define ptr @unsupported_musttail() noinline optnone {
entry:
  call void @hikari_vmp()
  %a = musttail call ptr @llvm.stacksave()
  ret ptr %a
}

define ptr @unsupported_bundle() noinline optnone {
entry:
  call void @hikari_vmp()
  %a = call ptr @llvm.stacksave() [ "deopt"(i32 0) ]
  ret ptr %a
}

define ptr @unsupported_fastcc() noinline optnone {
entry:
  call void @hikari_vmp()
  %a = call fastcc ptr @llvm.stacksave()
  ret ptr %a
}

define void @unsupported_sret(ptr sret(i32) %p, ptr byval(i32) %q) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @ext_sret_byval(ptr sret(i32) %p, ptr byval(i32) %q)
  ret void
}

define i32 @main() {
entry:
  %e0 = call i32 @reference()
  %a0 = call i32 @protected()
  %m0 = icmp eq i32 %e0, %a0
  %e1 = call i32 @reference_nested()
  %a1 = call i32 @protected_nested()
  %m1 = icmp eq i32 %e1, %a1
  %ok = and i1 %m0, %m1
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_dyn_alloca_stackstate: dynamic stack state
; SKIP-DAG: Skipping VMP on unsupported_malformed: unsupported stacksave
; SKIP-DAG: Skipping VMP on unsupported_restore_poison: unsupported stackrestore
; SKIP-DAG: Skipping VMP on unsupported_as1_arg: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported stacksave
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported stacksave
; SKIP-DAG: Skipping VMP on unsupported_sret: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected:
; SKIP-NOT: Skipping VMP on protected_nested:

; VIRT: define i32 @protected({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call void @hikari_vmp()
; VIRT-DAG: [[SS0:%.*]] = call ptr @llvm.stacksave()
; VIRT-DAG: [[SS1:%.*]] = call ptr @llvm.stacksave()
; VIRT-DAG: store volatile ptr [[SS0]], ptr {{.*}}, align 8
; VIRT-DAG: store volatile ptr [[SS1]], ptr {{.*}}, align 8
; VIRT-DAG: call void @llvm.stackrestore(ptr {{.*}})
; VIRT-DAG: call void @llvm.stackrestore(ptr {{.*}})
; VIRT: }
; VIRT: define i32 @protected_nested({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: call ptr @llvm.stacksave()
; VIRT-DAG: call ptr @llvm.stacksave()
; VIRT-DAG: call void @llvm.stackrestore(ptr {{.*}})
; VIRT-DAG: call void @llvm.stackrestore(ptr {{.*}})
; VIRT: }
; VIRT: define {{.*}} @unsupported_dyn_alloca_stackstate({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_malformed({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_restore_poison({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_as1_arg({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_musttail({{.*}} #[[UNSUPMUST:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call ptr @llvm.stacksave()
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
