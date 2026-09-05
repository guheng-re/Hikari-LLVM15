; llvm.pcmarker is implemented as a strict, no-op degradation: the VMP
; planner consumes and omits the exact intrinsic (no VM opcode, no
; CallDescriptor, nothing re-emitted in the dispatcher), because LLVM 15
; backends cannot select ISD::PCMARKER — a replay would break AArch64
; codegen of every virtualized function with "Cannot select: ch =
; PCMarker".  This preserves only the program's business semantics, not the
; codegen-marker semantics of an intrinsic no backend can lower.  The
; reference function uses the equivalent pure-integer arithmetic without
; pcmarker; the protected function keeps two pcmarkers with different i32
; values at the same arithmetic points.  main compares the results over
; multiple inputs.  The llvm.debugtrap sibling stays rejected (deliberately
; not generalized to other marker/debug intrinsics), so its function is
; skipped with the stable "unsupported call instruction" diagnostic, keeps
; its native call and has no VMP dispatcher; it is never called from main,
; so the trap is never executed.
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
; Whole-function no-pcmarker checks: from the protected LABEL to the next
; LABEL (unsupported_debugtrap) the entire transformed function must contain
; neither @llvm.pcmarker nor any pcmarker replay trace.  The stray top-level
; declaration is outside that range and stays allowed.  Both seeds are
; covered for O0 and O2.
; RUN: FileCheck %s --check-prefix=NO-PCMARKER < %t.o0.ll
; RUN: FileCheck %s --check-prefix=NO-PCMARKER-O2 < %t.o2.ll
; RUN: FileCheck %s --check-prefix=NO-PCMARKER < %t.o0.s7.ll
; RUN: FileCheck %s --check-prefix=NO-PCMARKER-O2 < %t.o2.s7.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare void @llvm.pcmarker(i32)
declare void @llvm.debugtrap()

; ---- reference: native pure-integer arithmetic ----

; No pcmarker here: the protected side consumes its markers as no-ops, so
; the observable behavior is exactly this arithmetic (both compute
; (seed+5)*2 - seed).

define i32 @reference(i32 %seed) {
entry:
  %p1 = add i32 %seed, 5
  %p2 = mul i32 %p1, 2
  %r = sub i32 %p2, %seed
  ret i32 %r
}

; ---- protected: same arithmetic with two consumed pcmarkers ----

define i32 @protected(i32 %seed) noinline optnone {
entry:
  call void @hikari_vmp()
  %p1 = add i32 %seed, 5
  call void @llvm.pcmarker(i32 %p1)
  %p2 = mul i32 %p1, 2
  call void @llvm.pcmarker(i32 %p2)
  %r = sub i32 %p2, %seed
  ret i32 %r
}

; ---- negative case: must SKIP, never virtualize ----

; The debugtrap sibling stays rejected by the intrinsic whitelist (the
; pcmarker support is deliberately not generalized to other marker/debug
; intrinsics); the function itself is otherwise eligible, so the reason is
; a stable unsupported call.  The function is never called from main, so
; the trap is never executed.
define i32 @unsupported_debugtrap(i32 %seed) noinline optnone {
entry:
  call void @hikari_vmp()
  %p1 = add i32 %seed, 5
  call void @llvm.debugtrap()
  %r = add i32 %p1, 1
  ret i32 %r
}

; ---- main: parity checks ----

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

; SKIP-DAG: Skipping VMP on unsupported_debugtrap: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected:

; VIRT-LABEL: define i32 @protected(
; VIRT: %vmp.regs = alloca
; VIRT: vmp.dispatch:
; The two pcmarker calls are consumed and omitted by the planner: no VM
; opcode, no CallDescriptor, nothing re-emitted in the dispatcher.  The
; surrounding arithmetic still runs through the integer virtual frame.
; VIRT-NOT: llvm.pcmarker
; VIRT-NOT: pcmarker
; VIRT-DAG: [[SR:%.*]] = sub i32 [[SR0:%.*]], [[SR1:%.*]]
; VIRT-DAG: [[SR0]] = trunc i64 [[SR0W:%.*]] to i32
; VIRT-DAG: [[SR0W]] = load volatile i64, ptr {{.*}}, align 4
; VIRT-DAG: [[SR1]] = trunc i64 [[SR1W:%.*]] to i32
; VIRT-DAG: [[SR1W]] = load volatile i64, ptr {{.*}}, align 4

; Negative case stays native: no dispatch, no virtualized attribute.
; VIRT-LABEL: define i32 @unsupported_debugtrap(
; VIRT-NOT: vmp.dispatch
; VIRT: call void @llvm.debugtrap()

; VIRT: attributes{{.*}}"hikari.vmp.virtualized"{{.*}}

; ---- O2 checks ----

; SKIP-O2-DAG: Skipping VMP on unsupported_debugtrap: unsupported call instruction
; SKIP-O2-NOT: Skipping VMP on protected:

; The protected function is optnone, so the virtualized structure is
; identical at O2; the O2 checks stay virtualization/verification-safe.
; VIRT-O2-LABEL: define i32 @protected(
; VIRT-O2: vmp.dispatch:
; VIRT-O2-NOT: llvm.pcmarker
; VIRT-O2-NOT: pcmarker
; VIRT-O2-DAG: [[SR:%.*]] = sub i32 [[SR0:%.*]], [[SR1:%.*]]
; VIRT-O2-DAG: [[SR0]] = trunc i64 [[SR0W:%.*]] to i32
; VIRT-O2-DAG: [[SR0W]] = load volatile i64, ptr {{.*}}, align 4
; VIRT-O2-DAG: [[SR1]] = trunc i64 [[SR1W:%.*]] to i32
; VIRT-O2-DAG: [[SR1W]] = load volatile i64, ptr {{.*}}, align 4

; Negative case stays native at O2 as well.
; VIRT-O2-LABEL: define i32 @unsupported_debugtrap(
; VIRT-O2-NOT: vmp.dispatch
; VIRT-O2: call void @llvm.debugtrap()
; VIRT-O2: attributes{{.*}}"hikari.vmp.virtualized"{{.*}}

; ---- whole-function no-pcmarker checks (O0, both seeds) ----

; Independent, explicit whole-range assertion: the NOT window is delimited
; by LABELs, so it spans the entire transformed protected function from
; `define i32 @protected(` up to the next LABEL (`define i32
; @unsupported_debugtrap(`).  Neither the intrinsic name nor any pcmarker
; replay trace may appear anywhere in that range.  The top-level stray
; declaration (`declare void @llvm.pcmarker`) sits before the first LABEL
; and is intentionally not covered.
; NO-PCMARKER-LABEL: define i32 @protected(
; NO-PCMARKER-NOT: @llvm.pcmarker
; NO-PCMARKER-NOT: pcmarker
; NO-PCMARKER-LABEL: define i32 @unsupported_debugtrap(

; ---- whole-function no-pcmarker checks (O2, both seeds) ----

; NO-PCMARKER-O2-LABEL: define i32 @protected(
; NO-PCMARKER-O2-NOT: @llvm.pcmarker
; NO-PCMARKER-O2-NOT: pcmarker
; NO-PCMARKER-O2-LABEL: define i32 @unsupported_debugtrap(
