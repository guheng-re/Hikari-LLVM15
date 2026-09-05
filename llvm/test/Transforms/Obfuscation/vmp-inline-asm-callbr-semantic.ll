; Restricted direct InlineAsm CallBr (LLVM asm goto): ATT, non-throwing,
; not alignstack, CallingConv::C, non-vararg FunctionType matching the
; InlineAsm, 0..8 r args, 1..8 same-function indirect dests.  Result
; and args are void (result only) / i1..i64 / AS0 pointer.  I/O
; constraints only "r"; labels only "i"/"X"; clobbers only {memory} /
; {cc}.  New VMOpcode::CallBr: interpreter CreateCallBr into dest
; trampolines that store dest VM PCs.  Result, if any, is stored only
; on the default dest.  PHI dests use getEdgeTarget.  Out-of-shape
; CallBr stays "callbr" and keeps hikari.vmp.selected.  Function /
; indirect callees, InvokeInst, and CallInst inline asm stay on their
; own families.
;
; Host cannot execute AArch64 inline asm (lli fatal).  FileCheck +
; AArch64 llc/readobj/asm only.  O0/O2 x 97/7.  Budget rollback keeps
; the original function.  hikari_fla requests VMP post-CFF; the
; interpreter CallBr terminator is not Branch/Ret/Unreachable, so
; post-CFF skips transactionally and keeps the virtualized shell.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.ll > %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o0.live.ll -o - | FileCheck %s --check-prefix=ASM
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.ll > %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o2.live.ll -o - | FileCheck %s --check-prefix=ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.s7.ll > %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o0.s7.live.ll -o - | FileCheck %s --check-prefix=ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.s7.ll > %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o2.s7.live.ll -o - | FileCheck %s --check-prefix=ASM
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %s | opt -S -verify-each -aesSeed=97 -passes='default<O0>' - 2>&1 | FileCheck %s --check-prefix=HOST
; RUN: opt -S -verify-each -aesSeed=97 -vmp-max-bytecode-words=1 -passes='default<O0>' %s -o %t.budget.ll 2>%t.budget.err
; RUN: FileCheck %s --check-prefix=BUDGET-ERR < %t.budget.err
; RUN: FileCheck %s --check-prefix=BUDGET-IR < %t.budget.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare void @hikari_fla()

define void @protected_goto(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  callbr void asm sideeffect "cbnz ${0:w}, ${1:l}", "r,!i"(i32 %x)
          to label %fall [label %taken]
fall:
  ret void
taken:
  ret void
}

define void @protected_two() noinline optnone {
entry:
  call void @hikari_vmp()
  callbr void asm sideeffect "", "!i,!i"()
          to label %fall [label %a, label %b]
fall:
  ret void
a:
  ret void
b:
  ret void
}

define i32 @protected_phi(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  callbr void asm sideeffect "cbnz ${0:w}, ${1:l}", "r,!i"(i32 %x)
          to label %fall [label %taken]
fall:
  br label %join
taken:
  br label %join
join:
  %p = phi i32 [ 1, %fall ], [ 2, %taken ]
  ret i32 %p
}

define i32 @protected_copy(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = callbr i32 asm "mov ${0:w}, ${1:w}", "=r,r,!i"(i32 %x)
          to label %fall [label %alt]
fall:
  ret i32 %r
alt:
  ret i32 0
}

define i32 @protected_phi_result(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = callbr i32 asm "mov ${0:w}, ${1:w}", "=r,r,!i"(i32 %x)
          to label %fall [label %alt]
fall:
  br label %join
alt:
  br label %join
join:
  %p = phi i32 [ %r, %fall ], [ 7, %alt ]
  ret i32 %p
}

define void @protected_memory() noinline optnone {
entry:
  call void @hikari_vmp()
  callbr void asm sideeffect "nop", "!i,~{memory}"()
          to label %fall [label %alt]
fall:
  ret void
alt:
  ret void
}

define void @protected_store_mem(ptr %p, i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  callbr void asm sideeffect "str ${0:w}, [$1]", "r,r,!i,~{memory}"(i32 %x, ptr %p)
          to label %fall [label %alt]
fall:
  ret void
alt:
  ret void
}

define void @protected_cff(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @hikari_fla()
  callbr void asm sideeffect "cbnz ${0:w}, ${1:l}", "r,!i"(i32 %x)
          to label %fall [label %taken]
fall:
  ret void
taken:
  ret void
}

define i32 @protected_cff_result(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @hikari_fla()
  %r = callbr i32 asm "mov ${0:w}, ${1:w}", "=r,r,!i"(i32 %x)
          to label %fall [label %alt]
fall:
  ret i32 %r
alt:
  ret i32 0
}

define void @unsupported_intel() noinline optnone {
entry:
  call void @hikari_vmp()
  callbr void asm sideeffect inteldialect "nop", "!i"()
          to label %fall [label %alt]
fall:
  ret void
alt:
  ret void
}

define void @unsupported_alignstack() noinline optnone {
entry:
  call void @hikari_vmp()
  callbr void asm sideeffect alignstack "nop", "!i"()
          to label %fall [label %alt]
fall:
  ret void
alt:
  ret void
}

define fp128 @unsupported_fp128(fp128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = callbr fp128 asm "", "=r,r,!i"(fp128 %a)
          to label %fall [label %alt]
fall:
  ret fp128 %r
alt:
  ret fp128 %a
}

define void @unsupported_alternatives(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  callbr void asm sideeffect "nop", "r|m,!i"(i32 %x)
          to label %fall [label %alt]
fall:
  ret void
alt:
  ret void
}

define void @unsupported_zero_dests() noinline optnone {
entry:
  call void @hikari_vmp()
  callbr void asm sideeffect "nop", ""()
          to label %fall []
fall:
  ret void
}

define void @unsupported_too_many_dests() noinline optnone {
entry:
  call void @hikari_vmp()
  callbr void asm sideeffect "", "!i,!i,!i,!i,!i,!i,!i,!i,!i"()
          to label %fall [label %d1, label %d2, label %d3, label %d4, label %d5, label %d6, label %d7, label %d8, label %d9]
fall:
  ret void
d1:
  ret void
d2:
  ret void
d3:
  ret void
d4:
  ret void
d5:
  ret void
d6:
  ret void
d7:
  ret void
d8:
  ret void
d9:
  ret void
}

define void @unsupported_imm_constraint() noinline optnone {
entry:
  call void @hikari_vmp()
  callbr void asm sideeffect "b ${1:l}", "i,!i"(i32 0)
          to label %fall [label %alt]
fall:
  ret void
alt:
  ret void
}

define void @unsupported_blockaddress() noinline optnone {
entry:
  call void @hikari_vmp()
  callbr void asm sideeffect "nop", "r,!i"(ptr blockaddress(@unsupported_blockaddress, %fall))
          to label %fall [label %alt]
fall:
  ret void
alt:
  ret void
}

define i32 @unsupported_matching(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = callbr i32 asm "", "=r,0,!i"(i32 %x)
          to label %fall [label %alt]
fall:
  ret i32 %r
alt:
  ret i32 0
}

define i32 @unsupported_earlyclobber(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = callbr i32 asm "", "=&r,r,!i"(i32 %x)
          to label %fall [label %alt]
fall:
  ret i32 %r
alt:
  ret i32 0
}

define void @unsupported_clobber_sp() noinline optnone {
entry:
  call void @hikari_vmp()
  callbr void asm sideeffect "nop", "!i,~{sp}"()
          to label %fall [label %alt]
fall:
  ret void
alt:
  ret void
}

define void @unsupported_fastcc() noinline optnone {
entry:
  call void @hikari_vmp()
  callbr fastcc void asm sideeffect "", "!i"()
          to label %fall [label %alt]
fall:
  ret void
alt:
  ret void
}

define void @unsupported_bundle() noinline optnone {
entry:
  call void @hikari_vmp()
  callbr void asm sideeffect "", "!i"() [ "deopt"(i32 0) ]
          to label %fall [label %alt]
fall:
  ret void
alt:
  ret void
}

define void @main() {
entry:
  ret void
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_intel: callbr
; SKIP-DAG: Skipping VMP on unsupported_alignstack: callbr
; SKIP-DAG: Skipping VMP on unsupported_fp128: callbr
; SKIP-DAG: Skipping VMP on unsupported_alternatives: callbr
; SKIP-DAG: Skipping VMP on unsupported_zero_dests: callbr
; SKIP-DAG: Skipping VMP on unsupported_too_many_dests: callbr
; SKIP-DAG: Skipping VMP on unsupported_imm_constraint: callbr
; SKIP-DAG: Skipping VMP on unsupported_blockaddress: callbr
; SKIP-DAG: Skipping VMP on unsupported_matching: callbr
; SKIP-DAG: Skipping VMP on unsupported_earlyclobber: callbr
; SKIP-DAG: Skipping VMP on unsupported_clobber_sp: callbr
; SKIP-DAG: Skipping VMP on unsupported_fastcc: callbr
; SKIP-DAG: Skipping VMP on unsupported_bundle: callbr
; SKIP-DAG: Skipping VMP post-CFF on protected_cff: candidate flattening or verification failed
; SKIP-DAG: Skipping VMP post-CFF on protected_cff_result: cross-block SSA requires fixStack
; SKIP-NOT: Skipping VMP on protected_goto:
; SKIP-NOT: Skipping VMP on protected_two:
; SKIP-NOT: Skipping VMP on protected_phi:
; SKIP-NOT: Skipping VMP on protected_copy:
; SKIP-NOT: Skipping VMP on protected_phi_result:
; SKIP-NOT: Skipping VMP on protected_memory:
; SKIP-NOT: Skipping VMP on protected_store_mem:
; SKIP-NOT: Skipping VMP on protected_cff:
; SKIP-NOT: Skipping VMP on protected_cff_result:

; VIRT-LABEL: define void @protected_goto(
; VIRT-SAME: #[[PROT:[0-9]+]]
; VIRT: vmp.dispatch:
; VIRT: callbr void asm sideeffect "cbnz ${0:w}, ${1:l}", "r,!i"(i32
; VIRT-NEXT: to label %vmp.callbr.def [label %vmp.callbr.ind]
; VIRT-LABEL: define void @protected_two(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: callbr void asm sideeffect "", "!i,!i"()
; VIRT-NEXT: to label %vmp.callbr.def [label %vmp.callbr.ind, label %vmp.callbr.ind
; VIRT-LABEL: define i32 @protected_phi(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: callbr void asm sideeffect "cbnz ${0:w}, ${1:l}", "r,!i"(i32
; VIRT-NEXT: to label %vmp.callbr.def [label %vmp.callbr.ind]
; VIRT-LABEL: define i32 @protected_copy(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: callbr i32 asm "mov ${0:w}, ${1:w}", "=r,r,!i"(i32
; VIRT-NEXT: to label %vmp.callbr.def [label %vmp.callbr.ind]
; VIRT-LABEL: define i32 @protected_phi_result(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: callbr i32 asm "mov ${0:w}, ${1:w}", "=r,r,!i"(i32
; VIRT-NEXT: to label %vmp.callbr.def [label %vmp.callbr.ind]
; VIRT-LABEL: define void @protected_memory(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: callbr void asm sideeffect "nop", "!i,~{memory}"()
; VIRT-NEXT: to label %vmp.callbr.def [label %vmp.callbr.ind]
; VIRT-LABEL: define void @protected_store_mem(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT: callbr void asm sideeffect "str ${0:w}, [$1]", "r,r,!i,~{memory}"(i32
; VIRT-NEXT: to label %vmp.callbr.def [label %vmp.callbr.ind]
; VIRT-LABEL: define void @protected_cff(
; VIRT-SAME: #[[CFF:[0-9]+]]
; VIRT: vmp.dispatch:
; VIRT: callbr void asm sideeffect "cbnz ${0:w}, ${1:l}", "r,!i"(i32
; VIRT-NEXT: to label %vmp.callbr.def [label %vmp.callbr.ind]
; VIRT-NOT: vmp.post.cff.opcode
; VIRT-LABEL: define i32 @protected_cff_result(
; VIRT-SAME: #[[CFF]]
; VIRT: vmp.dispatch:
; VIRT: callbr i32 asm "mov ${0:w}, ${1:w}", "=r,r,!i"(i32
; VIRT-NEXT: to label %vmp.callbr.def [label %vmp.callbr.ind]
; VIRT-NOT: vmp.post.cff.opcode
; VIRT: define {{.*}} @unsupported_intel({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_alignstack({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fp128({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_alternatives({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_zero_dests({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_too_many_dests({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_imm_constraint({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_blockaddress({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_matching({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_earlyclobber({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_clobber_sp({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fastcc({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_bundle({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[CFF]] = { {{.*}}"hikari.vmp.post.cff"{{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT-NOT: hikari.vmp.post.cff.applied
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; ASM-DAG: cbnz
; ASM-DAG: mov
; ASM-DAG: str
; HOST: Skipping VMP: only AArch64 targets are supported
; BUDGET-ERR: Skipping VMP on protected_goto: bytecode word budget
; BUDGET-IR-LABEL: define void @protected_goto(
; BUDGET-IR-NOT: vmp.dispatch
; BUDGET-IR: callbr void asm sideeffect "cbnz ${0:w}, ${1:l}", "r,!i"(i32
