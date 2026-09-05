; Restricted ordinary direct noreturn CallInst: C, non-intrinsic,
; non-vararg, void, scalar int / AS0 ptr / f32/f64 args.  Dedicated
; terminating opcode replays the call then unreachable (no PC advance).
; Noreturn intrinsics, musttail, indirect, and complex ABI stay out.
; Ordinary tail is a hint and is replayed as TCK_None.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.ll > %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.live.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.ll > %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.live.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.s7.ll > %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.s7.live.ll > %t.o0.s7.host.ll
; RUN: lli -force-interpreter %t.o0.s7.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.s7.ll > %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.s7.live.ll > %t.o2.s7.host.ll
; RUN: lli -force-interpreter %t.o2.s7.host.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()

@slot = private global i32 0, align 4

define void @abort_now(i32 %code) noreturn noinline {
entry:
  store volatile i32 %code, ptr @slot, align 4
  unreachable
}

define i32 @reference(i32 %x, i1 %fail) noinline optnone {
entry:
  br i1 %fail, label %err, label %ok

err:
  call void @abort_now(i32 %x)
  unreachable

ok:
  store i32 %x, ptr @slot, align 4
  %v = load i32, ptr @slot, align 4
  %out = add i32 %v, 3
  ret i32 %out
}

define i32 @protected(i32 %x, i1 %fail) noinline optnone {
entry:
  call void @hikari_vmp()
  br i1 %fail, label %err, label %ok

err:
  call void @abort_now(i32 %x)
  unreachable

ok:
  store i32 %x, ptr @slot, align 4
  %v = load i32, ptr @slot, align 4
  %out = add i32 %v, 3
  ret i32 %out
}


define i32 @unsupported_indirect_noreturn(ptr %fp, i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  call void %fp(i32 %x) noreturn
  unreachable
}

define i32 @main() {
entry:
  store i32 0, ptr @slot, align 4
  %e0 = call i32 @reference(i32 7, i1 false)
  %s0 = load i32, ptr @slot, align 4
  store i32 0, ptr @slot, align 4
  %a0 = call i32 @protected(i32 7, i1 false)
  %s1 = load i32, ptr @slot, align 4
  %ok0 = icmp eq i32 %e0, %a0
  %ok1 = icmp eq i32 %s0, %s1
  %ok2 = icmp eq i32 %s1, 7
  %t0 = and i1 %ok0, %ok1
  %ok = and i1 %t0, %ok2
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP-DAG: Skipping VMP on unsupported_indirect_noreturn: indirect call
; SKIP-NOT: Skipping VMP on protected:
; SKIP-NOT: Skipping VMP on reference:
; SKIP-NOT: Skipping VMP on abort_now:

; VIRT-LABEL: define i32 @protected(
; VIRT: vmp.dispatch:
; VIRT: call void @abort_now(
; VIRT-NEXT: unreachable
; VIRT: define {{.*}} @unsupported_indirect_noreturn({{.*}} #[[UNSUPATTR:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #{{[0-9]+}} = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.virtualized"