; Normal-edge behavior only for the real Itanium invoke surface.
; protected uses an eligible non-nounwind direct invoke to a defined
; helper that never throws; the reachable {ptr,i32} cleanup landingpad
; and resume stay in the CFG but are not executed.  reference uses a
; plain call to the same helper (identical normal result).
; Transform on AArch64, then compare host lli -force-interpreter after
; rewriting only the already-virtualized live module's triple to
; x86_64.  This is not an unwind/catch test.  Real AArch64 unwind is
; not added under REQUIRES: vmp-aarch64-runner; that contract does not
; document linking the Itanium C++ EH runtime.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.ll -o %t.o0.live.ll
; RUN: FileCheck %s --check-prefix=LIVE < %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h -S --symbols %t.o0.o | FileCheck %s --check-prefixes=AARCH64,AARCH64-OBJ
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o0.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.live.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.ll -o %t.o2.live.ll
; RUN: FileCheck %s --check-prefix=LIVE < %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h -S --symbols %t.o2.o | FileCheck %s --check-prefixes=AARCH64,AARCH64-OBJ
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o2.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.live.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.s7.ll -o %t.o0.s7.live.ll
; RUN: FileCheck %s --check-prefix=LIVE < %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h -S --symbols %t.o0.s7.o | FileCheck %s --check-prefixes=AARCH64,AARCH64-OBJ
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o0.s7.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.s7.live.ll > %t.o0.s7.host.ll
; RUN: lli -force-interpreter %t.o0.s7.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.s7.ll -o %t.o2.s7.live.ll
; RUN: FileCheck %s --check-prefix=LIVE < %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h -S --symbols %t.o2.s7.o | FileCheck %s --check-prefixes=AARCH64,AARCH64-OBJ
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o2.s7.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.s7.live.ll > %t.o2.s7.host.ll
; RUN: lli -force-interpreter %t.o2.s7.host.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %s | opt -S -verify-each -aesSeed=97 -passes='default<O0>' - 2>&1 | FileCheck %s --check-prefix=HOST

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare i32 @__gxx_personality_v0(...)

; Defined, not nounwind, never throws.  Must stay non-nounwind so the
; invoke takes the real Itanium surface rather than the discarded
; nounwind-island Call+Br path.  optnone blocks default<O2>
; FunctionAttrs from inferring nounwind on this trivial body.
define i32 @add_never_throws(i32 %x) noinline optnone {
entry:
  %r = add i32 %x, 1
  ret i32 %r
}

define i32 @reference(i32 %x) noinline optnone {
entry:
  %r = call i32 @add_never_throws(i32 %x)
  ret i32 %r
}

define i32 @protected(i32 %x) noinline optnone personality ptr @__gxx_personality_v0 {
entry:
  call void @hikari_vmp()
  %r = invoke i32 @add_never_throws(i32 %x)
          to label %cont unwind label %lpad
cont:
  ret i32 %r
lpad:
  %lp = landingpad { ptr, i32 }
          cleanup
  resume { ptr, i32 } %lp
}

define i32 @main() {
entry:
  %e0 = call i32 @reference(i32 41)
  %a0 = call i32 @protected(i32 41)
  %e1 = call i32 @reference(i32 -7)
  %a1 = call i32 @protected(i32 -7)
  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %e1, %a1
  %ok = and i1 %m0, %m1
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP-NOT: Skipping VMP on protected:
; SKIP-NOT: Skipping VMP on reference:
; SKIP-NOT: Skipping VMP on add_never_throws:

; VIRT: define i32 @protected({{.*}} #[[PROT:[0-9]+]] personality ptr @__gxx_personality_v0 {
; VIRT: landingpad { ptr, i32 }
; VIRT-NOT: call i32 @add_never_throws
; VIRT: vmp.dispatch:
; VIRT-DAG: invoke i32 @add_never_throws(i32
; VIRT-DAG: resume { ptr, i32 }
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"

; LIVE: define {{.*}}@protected({{.*}} personality ptr @__gxx_personality_v0 {
; LIVE: landingpad { ptr, i32 }
; LIVE-NOT: call i32 @add_never_throws
; LIVE-DAG: invoke i32 @add_never_throws(i32
; LIVE-DAG: resume { ptr, i32 }

; AARCH64: Arch: aarch64
; AARCH64-OBJ-DAG: Name: .gcc_except_table
; AARCH64-OBJ-DAG: Name: .eh_frame
; AARCH64-OBJ-DAG: Name: __gxx_personality_v0
; AARCH64-OBJ-DAG: Name: _Unwind_Resume
; AARCH64-OBJ-DAG: Name: add_never_throws
; AARCH64-ASM-DAG: .cfi_personality {{.*}}__gxx_personality_v0
; AARCH64-ASM-DAG: .cfi_lsda
; AARCH64-ASM-DAG: {{GCC_except_table|\.gcc_except_table}}
; AARCH64-ASM-DAG: {{^[[:space:]]*}}bl{{[ \t]+}}add_never_throws
; AARCH64-ASM-DAG: {{^[[:space:]]*}}bl{{[ \t]+}}_Unwind_Resume
; HOST: Skipping VMP: only AArch64 targets are supported
