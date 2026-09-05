; Focused fixed-prototype indirect CallInst eligibility: ordinary
; tail is a hint on isSupportedIndirectMinimalCall and the last-token
; +bf16 bfloat indirect path (replay TCK_None).  C, non-vararg, 0..8, formal type
; equality, AS0 callee pointer, existing scalar/vector/aggregate
; coverage, and CallDescriptor replay are unchanged.  Direct-call
; paths are not touched.
;
; Host lli is reliable for i32 callback via a function-pointer
; argument and a select callee.  Bfloat is FileCheck-only.
; O0/O2 x 97/7.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.ll > %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: python3 %S/Inputs/vmp-drop-host-indirect-call.py %t.o0.live.ll > %t.o0.host.src.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.host.src.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.ll > %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: python3 %S/Inputs/vmp-drop-host-indirect-call.py %t.o2.live.ll > %t.o2.host.src.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.host.src.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.s7.ll > %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: python3 %S/Inputs/vmp-drop-host-indirect-call.py %t.o0.s7.live.ll > %t.o0.s7.host.src.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.s7.host.src.ll > %t.o0.s7.host.ll
; RUN: lli -force-interpreter %t.o0.s7.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.s7.ll > %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: python3 %S/Inputs/vmp-drop-host-indirect-call.py %t.o2.s7.live.ll > %t.o2.s7.host.src.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.s7.host.src.ll > %t.o2.s7.host.ll
; RUN: lli -force-interpreter %t.o2.s7.host.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare void @ext_sret_byval(ptr sret(i32), ptr byval(i32))

define i32 @add_one(i32 %x) noinline {
entry:
  %r = add i32 %x, 1
  ret i32 %r
}

define i32 @add_two(i32 %x) noinline {
entry:
  %r = add i32 %x, 2
  ret i32 %r
}

define bfloat @bf_id(bfloat %x) noinline {
entry:
  ret bfloat %x
}

define i32 @reference(ptr %fp, i32 %x) noinline {
entry:
  %r = call i32 %fp(i32 %x)
  ret i32 %r
}

define i32 @protected(ptr %fp, i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 %fp(i32 %x)
  ret i32 %r
}

define i32 @reference_select(i1 %c, i32 %x) noinline {
entry:
  %fp = select i1 %c, ptr @add_one, ptr @add_two
  %r = call i32 %fp(i32 %x)
  ret i32 %r
}

define i32 @protected_select(i1 %c, i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %fp = select i1 %c, ptr @add_one, ptr @add_two
  %r = call i32 %fp(i32 %x)
  ret i32 %r
}

define bfloat @protected_bfloat(ptr %fp, bfloat %x) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat %fp(bfloat %x)
  ret bfloat %r
}



define i32 @unsupported_fastcc(ptr %fp, i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc i32 %fp(i32 %x)
  ret i32 %r
}

define i32 @unsupported_musttail(ptr %fp, i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call i32 %fp(ptr %fp, i32 %x)
  ret i32 %r
}

define i32 @unsupported_bundle(ptr %fp, i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 %fp(i32 %x) [ "deopt"(i32 0) ]
  ret i32 %r
}

define i32 @unsupported_noreturn(ptr %fp, i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 %fp(i32 %x) noreturn
  ret i32 %r
}

define i32 @unsupported_returns_twice(ptr %fp, i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 %fp(i32 %x) returns_twice
  ret i32 %r
}

define i32 @unsupported_variadic(ptr %fp, i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 (i32, ...) %fp(i32 %x, i32 1)
  ret i32 %r
}

define i32 @unsupported_byval(ptr %fp, ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 %fp(ptr byval(i32) %p)
  ret i32 %r
}

define i32 @unsupported_poison(ptr %fp) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 %fp(i32 poison)
  ret i32 %r
}

define i32 @unsupported_bfloat_no_bf16(ptr %fp) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call bfloat %fp(bfloat 0xR3F80)
  ret i32 0
}

define void @unsupported_sret(ptr sret(i32) %p, ptr byval(i32) %q) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @ext_sret_byval(ptr sret(i32) %p, ptr byval(i32) %q)
  ret void
}

define i32 @main() {
entry:
  %e0 = call i32 @reference(ptr @add_one, i32 3)
  %a0 = call i32 @protected(ptr @add_one, i32 3)
  %e1 = call i32 @reference(ptr @add_two, i32 5)
  %a1 = call i32 @protected(ptr @add_two, i32 5)
  %e2 = call i32 @reference_select(i1 true, i32 7)
  %a2 = call i32 @protected_select(i1 true, i32 7)
  %e3 = call i32 @reference_select(i1 false, i32 7)
  %a3 = call i32 @protected_select(i1 false, i32 7)
  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %e1, %a1
  %m2 = icmp eq i32 %e2, %a2
  %m3 = icmp eq i32 %e3, %a3
  %t0 = and i1 %m0, %m1
  %t1 = and i1 %m2, %m3
  %ok = and i1 %t0, %t1
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_fastcc: indirect call
; SKIP-DAG: Skipping VMP on unsupported_musttail: indirect call
; SKIP-DAG: Skipping VMP on unsupported_bundle: indirect call
; SKIP-DAG: Skipping VMP on unsupported_noreturn: indirect call
; SKIP-DAG: Skipping VMP on unsupported_returns_twice: indirect call
; SKIP-DAG: Skipping VMP on unsupported_variadic: indirect call
; SKIP-DAG: Skipping VMP on unsupported_byval: indirect call
; SKIP-DAG: Skipping VMP on unsupported_poison: indirect call
; SKIP-DAG: Skipping VMP on unsupported_bfloat_no_bf16: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_sret: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected:
; SKIP-NOT: Skipping VMP on protected_select:
; SKIP-NOT: Skipping VMP on protected_bfloat:

; VIRT-LABEL: define i32 @protected(
; VIRT-SAME: #[[PROT:[0-9]+]]
; VIRT: vmp.dispatch:
; VIRT: call i32 %{{.+}}(i32
; VIRT-LABEL: define i32 @protected_select(
; VIRT: vmp.dispatch:
; VIRT: call i32 %{{.+}}(i32
; VIRT-LABEL: define bfloat @protected_bfloat(
; VIRT-SAME: #[[PROTBF:[0-9]+]]
; VIRT: vmp.dispatch:
; VIRT: call bfloat %{{.+}}(bfloat
; VIRT: define {{.*}} @unsupported_fastcc({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_musttail(
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call i32 %{{.+}}(
; VIRT-LABEL: define {{.*}} @unsupported_bundle(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_noreturn(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_returns_twice(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_variadic(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_byval(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_poison(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_bfloat_no_bf16(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_sret(
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[PROTBF]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.selected"

; AARCH64: Arch: aarch64
