; llvm.debugtrap re-emitted through the normal Call path — it is NOT a
; terminating intrinsic, so it must not reuse the terminating Trap opcode
; (which would wrongly insert unreachable) and must not be deleted.  The
; call handler re-emits call void @llvm.debugtrap() inside the interpreter
; and scheduling continues afterwards; the CallDescriptor preserves the
; call-site attributes, including a custom "trap-func-name" (the backend
; lowers the default form to brk #0xf000 on AArch64 and a custom form to a
; call of that function).  Default and custom reference/protected pairs put
; the trap on an untaken bad path that branches back to the good path;
; main only ever takes the good path.  The negative has a call-site
; noreturn attribute: the generic call gate rejects it with the stable
; "unsupported call instruction" diagnostic, no dispatcher, native call
; preserved, and the function is never called.
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
declare void @llvm.debugtrap()

; ---- reference: native default debugtrap ----

define i32 @reference(i32 %seed) {
entry:
  %c = icmp eq i32 %seed, 0
  br i1 %c, label %bad, label %good
bad:
  call void @llvm.debugtrap()
  br label %good
good:
  %r = add i32 %seed, 1
  ret i32 %r
}

; ---- protected: same default debugtrap under VMP ----

define i32 @protected(i32 %seed) noinline optnone {
entry:
  call void @hikari_vmp()
  %c = icmp eq i32 %seed, 0
  br i1 %c, label %bad, label %good
bad:
  call void @llvm.debugtrap()
  br label %good
good:
  %r = add i32 %seed, 1
  ret i32 %r
}

; ---- reference: native custom-trap-function debugtrap ----

define i32 @reference_custom(i32 %seed) {
entry:
  %c = icmp eq i32 %seed, 0
  br i1 %c, label %bad, label %good
bad:
  call void @llvm.debugtrap() "trap-func-name"="custom_debug_handler"
  br label %good
good:
  %r = add i32 %seed, 2
  ret i32 %r
}

; ---- protected: same custom debugtrap under VMP ----

define i32 @protected_custom(i32 %seed) noinline optnone {
entry:
  call void @hikari_vmp()
  %c = icmp eq i32 %seed, 0
  br i1 %c, label %bad, label %good
bad:
  call void @llvm.debugtrap() "trap-func-name"="custom_debug_handler"
  br label %good
good:
  %r = add i32 %seed, 2
  ret i32 %r
}

; Stub for the custom trap function named by the call-site attribute: the
; backend lowers the debugtrap to a call to it, and the host JIT needs the
; symbol to exist even though the bad path is never executed.
define void @custom_debug_handler() {
entry:
  ret void
}

; ---- negative case: must SKIP, never virtualize ----

; A call-site noreturn attribute makes the debugtrap look like a
; terminating call, which the dedicated non-terminating whitelist rejects;
; the function itself is otherwise eligible, so the reason is a stable
; unsupported call.  The function is never called from main.
define i32 @unsupported_noreturn_debugtrap(i32 %seed) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.debugtrap() noreturn
  %r = add i32 %seed, 3
  ret i32 %r
}

; ---- main: parity checks over the good path only ----

define i32 @main() {
entry:
  %e0 = call i32 @reference(i32 7)
  %a0 = call i32 @protected(i32 7)
  %e1 = call i32 @reference(i32 42)
  %a1 = call i32 @protected(i32 42)
  %e2 = call i32 @reference_custom(i32 1000)
  %a2 = call i32 @protected_custom(i32 1000)
  %e3 = call i32 @reference_custom(i32 -5)
  %a3 = call i32 @protected_custom(i32 -5)
  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %e1, %a1
  %m2 = icmp eq i32 %e2, %a2
  %m3 = icmp eq i32 %e3, %a3
  %t0 = and i1 %m0, %m1
  %t1 = and i1 %t0, %m2
  %ok = and i1 %t1, %m3
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; ---- O0 checks ----

; SKIP-DAG: Skipping VMP on unsupported_noreturn_debugtrap: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected:
; SKIP-NOT: Skipping VMP on protected_custom:

; The default debugtrap is re-emitted inside the interpreter exactly as the
; intrinsic call and scheduling continues afterwards (the handler branches
; back to vmp.dispatch) — no terminating llvm.trap/unreachable is produced
; by it.  The attribute-group numbers are captured from the function
; definitions and from the call-site group references, then each group is
; matched by its exact contents.
; VIRT: define i32 @protected(i32 %seed){{.*}}#[[POSATTR:[0-9]+]] {
; VIRT: %vmp.regs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: call void @llvm.debugtrap()
; VIRT-DAG: br label %vmp.dispatch

; VIRT: define i32 @protected_custom(i32 %seed){{.*}}#[[POSCATTR:[0-9]+]] {
; VIRT: %vmp.regs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: call void @llvm.debugtrap() #[[NEGCALL:[0-9]+]]
; VIRT-DAG: br label %vmp.dispatch
; VIRT: define void @custom_debug_handler(

; Negative case stays native: no dispatch, no virtualized attribute.
; VIRT: define i32 @unsupported_noreturn_debugtrap(i32 %seed){{.*}}#[[NEGATTR:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call void @llvm.debugtrap() #{{[0-9]+}}

; Attribute-group regression guards, bound by the captured numbers: both
; protected groups have identical contents, so LLVM prints them as one
; shared group (the function-header captures [[POSATTR]]/[[POSCATTR]] both
; resolve to it, which is itself the proof that both protected functions
; reference the virtualized set); the group content is asserted once.  The
; negative function's own group must be exactly the noinline optnone +
; selected set (had the negative been virtualized, its group would contain
; "hikari.vmp.virtualized" and this exact match would fail), and the custom
; call-site group keeps the trap-func-name string.
; VIRT: attributes #[[POSCATTR]] = { noinline optnone "hikari.vmp.selected" "hikari.vmp.virtualized" }{{$}}
; VIRT: attributes #[[NEGATTR]] = { noinline optnone "hikari.vmp.selected" }{{$}}
; VIRT: attributes #[[NEGCALL]] = { "trap-func-name"="custom_debug_handler" }{{$}}
; VIRT: attributes #{{[0-9]+}} = { noreturn }{{$}}

; ---- O2 checks ----

; SKIP-O2-DAG: Skipping VMP on unsupported_noreturn_debugtrap: unsupported call instruction
; SKIP-O2-NOT: Skipping VMP on protected:
; SKIP-O2-NOT: Skipping VMP on protected_custom:

; The protected functions are optnone, so the virtualized structure is
; identical at O2; the O2 checks stay virtualization/verification-safe.
; VIRT-O2: define i32 @protected(i32 %seed){{.*}}#[[POSATTR:[0-9]+]] {
; VIRT-O2: %vmp.regs = alloca
; VIRT-O2: vmp.dispatch:
; VIRT-O2-DAG: call void @llvm.debugtrap()
; VIRT-O2-DAG: br label %vmp.dispatch

; VIRT-O2: define i32 @protected_custom(i32 %seed){{.*}}#[[POSCATTR:[0-9]+]] {
; VIRT-O2: %vmp.regs = alloca
; VIRT-O2: vmp.dispatch:
; VIRT-O2-DAG: call void @llvm.debugtrap() #[[NEGCALL:[0-9]+]]
; VIRT-O2-DAG: br label %vmp.dispatch
; VIRT-O2: define void @custom_debug_handler(

; Negative case stays native at O2 as well.
; VIRT-O2: define i32 @unsupported_noreturn_debugtrap(i32 %seed){{.*}}#[[NEGATTR:[0-9]+]] {
; VIRT-O2-NOT: vmp.dispatch
; VIRT-O2: call void @llvm.debugtrap() #{{[0-9]+}}
; VIRT-O2: attributes #[[POSCATTR]] = { noinline optnone "hikari.vmp.selected" "hikari.vmp.virtualized" }{{$}}
; VIRT-O2: attributes #[[NEGATTR]] = { noinline optnone "hikari.vmp.selected" }{{$}}
; VIRT-O2: attributes #[[NEGCALL]] = { "trap-func-name"="custom_debug_handler" }{{$}}
; VIRT-O2: attributes #{{[0-9]+}} = { noreturn }{{$}}

; ---- asm check ----

; The default debugtrap lowers to brk #0xf000 on AArch64; the custom form
; lowers to a call of the named handler.
; ASM: brk #0xf000
; ASM: bl custom_debug_handler
