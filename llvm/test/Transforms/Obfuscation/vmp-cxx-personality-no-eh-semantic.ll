; Personality without EH control flow.  clang often keeps a
; personality (commonly @__gxx_personality_v0, also C
; @__gcc_personality_v0) after invoke is optimized away.  VMP
; virtualizes the ordinary body and must restore the original
; personality Constant (deleteBody drops hung-off operands; no
; name filter).  VMP post-CFF must keep that Function-level
; state (personality, linkage, prefix, prologue, function
; metadata) when it splices the flattened shell.  prefix /
; prologue are FileCheck'd on the virtualized IR only; main
; must not call those functions because host lli/ORC treats
; prefix/prologue bytes as an entry point.  AArch64 llc is
; module smoke, not a prefix-specific check.  invoke /
; landingpad / resume / EH pads stay rejected.  No new opcode.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare void @hikari_fla()
declare i32 @__gxx_personality_v0(...)
declare i32 @__gcc_personality_v0(...)

@may_throw.sink = private global i32 0

define i32 @may_throw() noinline optnone {
entry:
  store volatile i32 1, ptr @may_throw.sink, align 4
  ret i32 0
}

define i32 @reference_add(i32 %x) {
entry:
  %r = add i32 %x, 1
  ret i32 %r
}

define i32 @protected_add(i32 %x) noinline optnone personality ptr @__gxx_personality_v0 {
entry:
  call void @hikari_vmp()
  %r = add i32 %x, 1
  ret i32 %r
}

define i32 @reference_phi(i1 %c, i32 %x, i32 %y) {
entry:
  br i1 %c, label %left, label %right
left:
  %l = add i32 %x, 2
  br label %join
right:
  %r = add i32 %y, 3
  br label %join
join:
  %v = phi i32 [ %l, %left ], [ %r, %right ]
  ret i32 %v
}

define i32 @protected_phi(i1 %c, i32 %x, i32 %y) noinline optnone personality ptr @__gxx_personality_v0 {
entry:
  call void @hikari_vmp()
  br i1 %c, label %left, label %right
left:
  %l = add i32 %x, 2
  br label %join
right:
  %r = add i32 %y, 3
  br label %join
join:
  %v = phi i32 [ %l, %left ], [ %r, %right ]
  ret i32 %v
}

define i32 @reference_loop(i32 %n) {
entry:
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %i2, %loop ]
  %acc = phi i32 [ 0, %entry ], [ %acc2, %loop ]
  %acc2 = add i32 %acc, %i
  %i2 = add i32 %i, 1
  %more = icmp slt i32 %i2, %n
  br i1 %more, label %loop, label %done
done:
  ret i32 %acc2
}

define i32 @protected_loop(i32 %n) noinline optnone personality ptr @__gxx_personality_v0 {
entry:
  call void @hikari_vmp()
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %i2, %loop ]
  %acc = phi i32 [ 0, %entry ], [ %acc2, %loop ]
  %acc2 = add i32 %acc, %i
  %i2 = add i32 %i, 1
  %more = icmp slt i32 %i2, %n
  br i1 %more, label %loop, label %done
done:
  ret i32 %acc2
}

define i32 @protected_gcc(i32 %x) noinline optnone personality ptr @__gcc_personality_v0 {
entry:
  call void @hikari_vmp()
  %r = add i32 %x, 7
  ret i32 %r
}

define i32 @protected_cff(i32 %x) noinline optnone personality ptr @__gxx_personality_v0 {
entry:
  call void @hikari_vmp()
  call void @hikari_fla()
  %r = add i32 %x, 1
  ret i32 %r
}

define internal i32 @protected_internal_cff(i32 %x) noinline optnone personality ptr @__gcc_personality_v0 {
entry:
  call void @hikari_vmp()
  call void @hikari_fla()
  %r = add i32 %x, 7
  ret i32 %r
}

; Not called from main: lli/ORC would execute prefix i32 42 as code.
define i32 @protected_prefix(i32 %x) noinline optnone prefix i32 42 personality ptr @__gxx_personality_v0 {
entry:
  call void @hikari_vmp()
  %r = add i32 %x, 1
  ret i32 %r
}

; Not called from main: same lli/ORC entry-point hazard as prefix.
define i32 @protected_prologue_cff(i32 %x) noinline optnone prologue i32 7 personality ptr @__gxx_personality_v0 {
entry:
  call void @hikari_vmp()
  call void @hikari_fla()
  %r = add i32 %x, 1
  ret i32 %r
}

define i32 @protected_annot(i32 %x) noinline optnone personality ptr @__gxx_personality_v0 !annotation !0 {
entry:
  call void @hikari_vmp()
  %r = add i32 %x, 1
  ret i32 %r
}

; Well-formed reachable Itanium invoke is vmp-itanium-invoke-semantic.ll.

define i32 @main() {
entry:
  %e0 = call i32 @reference_add(i32 4)
  %a0 = call i32 @protected_add(i32 4)
  %e1 = call i32 @reference_phi(i1 true, i32 10, i32 20)
  %a1 = call i32 @protected_phi(i1 true, i32 10, i32 20)
  %e2 = call i32 @reference_phi(i1 false, i32 10, i32 20)
  %a2 = call i32 @protected_phi(i1 false, i32 10, i32 20)
  %e3 = call i32 @reference_loop(i32 5)
  %a3 = call i32 @protected_loop(i32 5)
  %e4 = add i32 4, 7
  %a4 = call i32 @protected_gcc(i32 4)
  %e5 = call i32 @reference_add(i32 4)
  %a5 = call i32 @protected_cff(i32 4)
  %e6 = add i32 4, 7
  %a6 = call i32 @protected_internal_cff(i32 4)
  %e9 = call i32 @reference_add(i32 4)
  %a9 = call i32 @protected_annot(i32 4)
  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %e1, %a1
  %m2 = icmp eq i32 %e2, %a2
  %m3 = icmp eq i32 %e3, %a3
  %m4 = icmp eq i32 %e4, %a4
  %m5 = icmp eq i32 %e5, %a5
  %m6 = icmp eq i32 %e6, %a6
  %m9 = icmp eq i32 %e9, %a9
  %t0 = and i1 %m0, %m1
  %t1 = and i1 %m2, %m3
  %t2 = and i1 %t0, %t1
  %t3 = and i1 %m4, %m5
  %t4 = and i1 %t2, %t3
  %t5 = and i1 %m6, %m9
  %ok = and i1 %t4, %t5
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with:
; SKIP-NOT: Skipping VMP on protected_add:
; SKIP-NOT: Skipping VMP on protected_phi:
; SKIP-NOT: Skipping VMP on protected_loop:
; SKIP-NOT: Skipping VMP on protected_gcc:
; SKIP-NOT: Skipping VMP on protected_cff:
; SKIP-NOT: Skipping VMP on protected_internal_cff:
; SKIP-NOT: Skipping VMP on protected_prefix:
; SKIP-NOT: Skipping VMP on protected_prologue_cff:
; SKIP-NOT: Skipping VMP on protected_annot:

; VIRT: define i32 @protected_add({{.*}} #[[PROT:[0-9]+]] personality ptr @__gxx_personality_v0 {
; VIRT: vmp.dispatch:
; VIRT: define i32 @protected_phi({{.*}} #[[PROT]] personality ptr @__gxx_personality_v0 {
; VIRT: vmp.dispatch:
; VIRT: define i32 @protected_loop({{.*}} #[[PROT]] personality ptr @__gxx_personality_v0 {
; VIRT: vmp.dispatch:
; VIRT: define i32 @protected_gcc({{.*}} #[[PROT]] personality ptr @__gcc_personality_v0 {
; VIRT: vmp.dispatch:
; VIRT: define i32 @protected_cff({{.*}} #[[CFF:[0-9]+]] personality ptr @__gxx_personality_v0 {
; VIRT: vmp.post.cff.opcode
; VIRT: define internal {{.*}}@protected_internal_cff({{.*}} personality ptr @__gcc_personality_v0 {
; VIRT: vmp.post.cff.opcode
; VIRT: define i32 @protected_prefix({{.*}} #[[PROT]] prefix i32 42 personality ptr @__gxx_personality_v0 {
; VIRT: vmp.dispatch:
; VIRT: define i32 @protected_prologue_cff({{.*}} #[[CFF]] prologue i32 7 personality ptr @__gxx_personality_v0 {
; VIRT: vmp.post.cff.opcode
; VIRT: define i32 @protected_annot({{.*}} personality ptr @__gxx_personality_v0 !annotation ![[ANN:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT: attributes #[[CFF]] = { {{.*}}"hikari.vmp.post.cff.applied"{{.*}}"hikari.vmp.virtualized"
; VIRT: ![[ANN]] = !{!"vmp-keep-annotation"}

; AARCH64: Arch: aarch64

!0 = !{!"vmp-keep-annotation"}
