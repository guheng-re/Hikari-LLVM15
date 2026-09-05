; Compose already-supported stacksave / static alloca / stackrestore:
; save the stack, write/read a static alloca, restore, then mix the loaded
; value.  No dynamic alloca.  The token travels through the pointer virtual
; register frame and is re-emitted (never precomputed).  Host lli lowers
; stacksave to null and stackrestore to a no-op; the alloca load/store
; still gives reference/protected parity.  AArch64 llc is the codegen check.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.ll -o %t.o0.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP-O2 < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT-O2 < %t.o2.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.ll -o %t.o2.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP-O2 < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT-O2 < %t.o2.s7.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare ptr @llvm.stacksave()
declare void @llvm.stackrestore(ptr)

define i32 @reference(i32 %x) {
entry:
  %tok = call ptr @llvm.stacksave()
  %p = alloca i32, align 4
  store i32 %x, ptr %p, align 4
  %v = load i32, ptr %p, align 4
  call void @llvm.stackrestore(ptr %tok)
  %s = add i32 %v, %x
  ret i32 %s
}

define i32 @protected(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %tok = call ptr @llvm.stacksave()
  %p = alloca i32, align 4
  store i32 %x, ptr %p, align 4
  %v = load i32, ptr %p, align 4
  call void @llvm.stackrestore(ptr %tok)
  %s = add i32 %v, %x
  ret i32 %s
}

; Otherwise-legal computed-length entry dynamic alloca plus
; stacksave/restore: dynamic-stack-state interaction, so skip.
; the token, so skip as dynamic stack state.
define i32 @unsupported_dyn_alloca(i32 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  %tok = call ptr @llvm.stacksave()
  %n1 = add i32 %n, 1
  %p = alloca i32, i32 %n1, align 4
  store i32 1, ptr %p, align 4
  call void @llvm.stackrestore(ptr %tok)
  ret i32 0
}

define i32 @main() {
entry:
  %e0 = call i32 @reference(i32 7)
  %a0 = call i32 @protected(i32 7)
  %e1 = call i32 @reference(i32 -3)
  %a1 = call i32 @protected(i32 -3)
  %e2 = call i32 @reference(i32 0)
  %a2 = call i32 @protected(i32 0)
  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %e1, %a1
  %m2 = icmp eq i32 %e2, %a2
  %t0 = and i1 %m0, %m1
  %ok = and i1 %t0, %m2
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP-DAG: Skipping VMP on unsupported_dyn_alloca: dynamic stack state
; SKIP-NOT: Skipping VMP on protected:
; SKIP-O2-DAG: Skipping VMP on unsupported_dyn_alloca: dynamic stack state
; SKIP-O2-NOT: Skipping VMP on protected:

; VIRT: define i32 @protected({{.*}}#[[POSATTR:[0-9]+]] {
; VIRT: %vmp.regs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: [[SS:%.*]] = call ptr @llvm.stacksave()
; VIRT-DAG: store volatile ptr [[SS]], ptr {{.*}}, align 8
; VIRT-DAG: store i32
; VIRT-DAG: load i32
; VIRT-DAG: call void @llvm.stackrestore(ptr
; VIRT-LABEL: define i32 @unsupported_dyn_alloca(
; VIRT-NOT: vmp.dispatch
; VIRT: alloca i32, i32 %
; VIRT: attributes #[[POSATTR]] = { noinline optnone "hikari.vmp.selected" "hikari.vmp.virtualized" }{{$}}

; VIRT-O2: define i32 @protected({{.*}}#[[POSATTR:[0-9]+]] {
; VIRT-O2: %vmp.regs = alloca
; VIRT-O2: vmp.dispatch:
; VIRT-O2-DAG: [[SS:%.*]] = call ptr @llvm.stacksave()
; VIRT-O2-DAG: store volatile ptr [[SS]], ptr {{.*}}, align 8
; VIRT-O2-DAG: store i32
; VIRT-O2-DAG: load i32
; VIRT-O2-DAG: call void @llvm.stackrestore(ptr
; VIRT-O2-LABEL: define i32 @unsupported_dyn_alloca(
; VIRT-O2-NOT: vmp.dispatch
; VIRT-O2: alloca i32, i32 %
; VIRT-O2: attributes #[[POSATTR]] = { noinline optnone "hikari.vmp.selected" "hikari.vmp.virtualized" }{{$}}
