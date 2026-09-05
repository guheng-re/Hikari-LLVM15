; llvm.ubsantrap as a dedicated terminating VM opcode (VMOpcode::Trap with
; Variant = 1 + category): the interpreter re-emits the same
; llvm.ubsantrap(i8 category) — never rewritten to llvm.trap, because
; AArch64 encodes the category (i8 12 -> brk #0x550c) — followed by native
; unreachable, with no PC advance and no register I/O.  The category
; travels in the opcode Variant (a compile-time constant, as the immarg
; requires) and is mirrored into the Auxiliary0 bytecode word, so it flows
; through the whiten/integrity machinery.  reference/protected put
; llvm.ubsantrap(i8 12) on an untaken bad path behind a conditional branch
; and return a pure-integer result on the good path; main only ever takes
; the good path.  The negative has a non-empty "trap-func-name" CALL-SITE
; attribute (which would turn the trap into a call to a custom external
; function instead of the default target trap — the backend reads it from
; the call site's AttributeList, not the enclosing function): its
; ubsantrap stays rejected with the stable "unsupported call instruction"
; diagnostic, no dispatcher, native call preserved, and the function is
; never called.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.ll -o %t.o0.o
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o0.ll -o - | FileCheck %s --check-prefix=ASM
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP-O2 < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT-O2 < %t.o2.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.ll -o %t.o2.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; Second fixed aesSeed: the checks above bind no register number, opcode or
; handler order, so the replay structure must be identical under a different
; seed (llc/lli on the seed-97 IR already prove the transform is valid and
; executes; the second seed re-checks the structure only).
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP-O2 < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT-O2 < %t.o2.s7.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare void @llvm.ubsantrap(i8 immarg)

; ---- reference: native, trap on untaken bad path ----

define i32 @reference(i32 %seed) {
entry:
  %c = icmp eq i32 %seed, 0
  br i1 %c, label %bad, label %good
bad:
  call void @llvm.ubsantrap(i8 12)
  unreachable
good:
  %r = add i32 %seed, 1
  ret i32 %r
}

; ---- protected: same under VMP ----

define i32 @protected(i32 %seed) noinline optnone {
entry:
  call void @hikari_vmp()
  %c = icmp eq i32 %seed, 0
  br i1 %c, label %bad, label %good
bad:
  call void @llvm.ubsantrap(i8 12)
  unreachable
good:
  %r = add i32 %seed, 1
  ret i32 %r
}

; ---- negative case: must SKIP, never virtualize ----

; A non-empty "trap-func-name" CALL-SITE attribute would lower the
; ubsantrap to a call to a custom external function instead of the default
; target trap (the backend reads it from the call site's AttributeList),
; so the call is rejected by the dedicated gate; the function itself is
; otherwise eligible, so the reason is a stable unsupported call.  The
; function is never called from main, so it is never executed.
define i32 @unsupported_custom_trap(i32 %seed) noinline optnone {
entry:
  call void @hikari_vmp()
  %c = icmp eq i32 %seed, 0
  br i1 %c, label %bad, label %good
bad:
  call void @llvm.ubsantrap(i8 5) "trap-func-name"="custom_ubsan_fail"
  unreachable
good:
  %r = add i32 %seed, 2
  ret i32 %r
}

; Stub for the custom trap function named by the call-site attribute: the
; backend lowers the ubsantrap to a call to it, and the host JIT needs the
; symbol to exist even though the negative function is never executed.
define void @custom_ubsan_fail() {
entry:
  ret void
}

; ---- main: parity checks over the good path only ----

define i32 @main() {
entry:
  %e0 = call i32 @reference(i32 7)
  %a0 = call i32 @protected(i32 7)
  %e1 = call i32 @reference(i32 42)
  %a1 = call i32 @protected(i32 42)
  %e2 = call i32 @reference(i32 1000)
  %a2 = call i32 @protected(i32 1000)
  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %e1, %a1
  %m2 = icmp eq i32 %e2, %a2
  %t0 = and i1 %m0, %m1
  %ok = and i1 %t0, %m2
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; ---- O0 checks ----

; SKIP-DAG: Skipping VMP on unsupported_custom_trap: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected:

; The attribute-group numbers are captured from each function definition
; ([[POSATTR]]/[[NEGATTR]]) and from the call-site group reference
; ([[NEGCALL]]), then each group is matched by its exact contents at the
; end of the module — no reliance on global group ordering, and no
; negative-lookahead needed (an exact group match is the positive proof).
; VIRT: define i32 @protected(i32 %seed){{.*}}#[[POSATTR:[0-9]+]] {
; VIRT: %vmp.regs = alloca
; VIRT: vmp.dispatch:
; The ubsantrap is re-emitted inside the interpreter as the same intrinsic
; (never rewritten to llvm.trap) followed by unreachable; the i8 category
; stays a literal 12.
; VIRT-DAG: call void @llvm.ubsantrap(i8 12)
; VIRT-DAG: unreachable

; Negative case stays native: no dispatch, no virtualized attribute.  The
; call-site trap-func-name attribute is preserved on the native call (LLVM
; prints it as a group reference on the call, with the string in the
; trailing attribute-group block).
; VIRT: define i32 @unsupported_custom_trap(i32 %seed){{.*}}#[[NEGATTR:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call void @llvm.ubsantrap(i8 5) #[[NEGCALL:[0-9]+]]
; VIRT: define void @custom_ubsan_fail(

; Attribute-group regression guards, bound by the captured numbers: the
; protected group must be exactly the virtualized set, the negative
; function's own group must be exactly the noinline optnone + selected set
; (had the negative been virtualized, its group would contain
; "hikari.vmp.virtualized" and this exact match would fail), and the
; call-site group keeps the custom trap-func-name string.
; VIRT: attributes #[[POSATTR]] = { noinline optnone "hikari.vmp.selected" "hikari.vmp.virtualized" }{{$}}
; VIRT: attributes #[[NEGATTR]] = { noinline optnone "hikari.vmp.selected" }{{$}}
; VIRT: attributes #[[NEGCALL]] = { "trap-func-name"="custom_ubsan_fail" }{{$}}

; ---- O2 checks ----

; SKIP-O2-DAG: Skipping VMP on unsupported_custom_trap: unsupported call instruction
; SKIP-O2-NOT: Skipping VMP on protected:

; The protected function is optnone, so the virtualized structure is
; identical at O2; the O2 checks stay virtualization/verification-safe.
; VIRT-O2: define i32 @protected(i32 %seed){{.*}}#[[POSATTR:[0-9]+]] {
; VIRT-O2: %vmp.regs = alloca
; VIRT-O2: vmp.dispatch:
; VIRT-O2-DAG: call void @llvm.ubsantrap(i8 12)
; VIRT-O2-DAG: unreachable

; Negative case stays native at O2 as well.
; VIRT-O2: define i32 @unsupported_custom_trap(i32 %seed){{.*}}#[[NEGATTR:[0-9]+]] {
; VIRT-O2-NOT: vmp.dispatch
; VIRT-O2: call void @llvm.ubsantrap(i8 5) #[[NEGCALL:[0-9]+]]
; VIRT-O2: define void @custom_ubsan_fail(
; VIRT-O2: attributes #[[POSATTR]] = { noinline optnone "hikari.vmp.selected" "hikari.vmp.virtualized" }{{$}}
; VIRT-O2: attributes #[[NEGATTR]] = { noinline optnone "hikari.vmp.selected" }{{$}}
; VIRT-O2: attributes #[[NEGCALL]] = { "trap-func-name"="custom_ubsan_fail" }{{$}}

; ---- asm check ----

; AArch64 encodes the UBSan trap category: i8 12 -> brk #0x550c.
; ASM: brk #0x550c
