; llvm.experimental.widenable.condition is lowered inside the VMP to a Move
; of constant i1 true into the call's integer virtual register — the same
; default as LowerWidenableCondition — so the control flow of a widenable
; guard is preserved without re-emitting the intrinsic in the dispatcher
; (no CallDescriptor, no VMOpcode).  The reference function uses the
; equivalent true condition; the protected function calls the intrinsic at
; the same point, ANDs it with an ordinary comparison and branches, with
; the two paths returning different integers.  main compares the results
; over positive/negative/zero inputs.  The adjacent experimental intrinsic
; llvm.experimental.guard was probed first but cannot be used: with its
; required deopt operand bundle and full vararg call signature it verifies,
; yet llc aborts with "Cannot select: intrinsic %llvm.experimental.guard"
; on every LLVM 15 backend (aarch64 and x86_64), so the negative case uses
; llvm.debugtrap instead (parses, verifies, code-generates, never
; executed).  Its function is skipped with the stable "unsupported call
; instruction" diagnostic, keeps its native call and has no VMP dispatcher.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: FileCheck %s --check-prefix=NO-REPLAY < %t.o0.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.ll -o %t.o0.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP-O2 < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT-O2 < %t.o2.ll
; RUN: FileCheck %s --check-prefix=NO-REPLAY-O2 < %t.o2.ll
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
; RUN: FileCheck %s --check-prefix=NO-REPLAY < %t.o0.s7.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP-O2 < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT-O2 < %t.o2.s7.ll
; RUN: FileCheck %s --check-prefix=NO-REPLAY-O2 < %t.o2.s7.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare i1 @llvm.experimental.widenable.condition()
declare void @llvm.debugtrap()

; ---- reference: equivalent true condition ----

; The widenable default is true, so the reference ANDs a literal true with
; the comparison; both functions compute seed>0 ? seed*3 : seed+7.

define i32 @reference(i32 %seed) {
entry:
  %c = icmp sgt i32 %seed, 0
  %t = and i1 true, %c
  br i1 %t, label %pos, label %neg
pos:
  %p = mul i32 %seed, 3
  ret i32 %p
neg:
  %n = add i32 %seed, 7
  ret i32 %n
}

; ---- protected: same guard shape with the widenable intrinsic ----

define i32 @protected(i32 %seed) noinline optnone {
entry:
  call void @hikari_vmp()
  %wc = call i1 @llvm.experimental.widenable.condition()
  %c = icmp sgt i32 %seed, 0
  %t = and i1 %wc, %c
  br i1 %t, label %pos, label %neg
pos:
  %p = mul i32 %seed, 3
  ret i32 %p
neg:
  %n = add i32 %seed, 7
  ret i32 %n
}

; ---- negative case: must SKIP, never virtualize ----

; The debugtrap sibling stays rejected by the intrinsic whitelist (the
; widenable support is deliberately not generalized to other experimental
; or debug intrinsics); the function itself is otherwise eligible, so the
; reason is a stable unsupported call.  The function is never called from
; main, so the trap is never executed.
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
  ; Positive, negative, and zero inputs exercise both branch paths.
  %e0 = call i32 @reference(i32 7)
  %a0 = call i32 @protected(i32 7)
  %e1 = call i32 @reference(i32 -3)
  %a1 = call i32 @protected(i32 -3)
  %e2 = call i32 @reference(i32 0)
  %a2 = call i32 @protected(i32 0)
  %e3 = call i32 @reference(i32 1000)
  %a3 = call i32 @protected(i32 1000)
  %e4 = call i32 @reference(i32 -42)
  %a4 = call i32 @protected(i32 -42)
  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %e1, %a1
  %m2 = icmp eq i32 %e2, %a2
  %m3 = icmp eq i32 %e3, %a3
  %m4 = icmp eq i32 %e4, %a4
  %t0 = and i1 %m0, %m1
  %t1 = and i1 %t0, %m2
  %t2 = and i1 %t1, %m3
  %ok = and i1 %t2, %m4
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; ---- O0 checks ----

; SKIP-DAG: Skipping VMP on unsupported_debugtrap: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected:

; VIRT-LABEL: define i32 @protected(
; VIRT: %vmp.regs = alloca
; The lowered Move materializes constant i1 true in the integer frame:
; the initializer stores the zero-extended i64 value 1 volatile.
; VIRT-DAG: store volatile i64 1, ptr {{.*}}, align 4
; VIRT: vmp.dispatch:
; The guard condition and the branch still run through the integer virtual
; frame: the and/condbr sources are truncs of i64 volatile loads.  Handler
; order is randomized, so the checks are DAG with definitions before uses.
; VIRT-DAG: [[TC:%.*]] = trunc i64 [[TCW:%.*]] to i1
; VIRT-DAG: [[TCW]] = load volatile i64, ptr {{.*}}, align 4

; Negative case stays native: no dispatch, no virtualized attribute.
; VIRT-LABEL: define i32 @unsupported_debugtrap(
; VIRT-NOT: vmp.dispatch
; VIRT: call void @llvm.debugtrap()

; VIRT: attributes{{.*}}"hikari.vmp.virtualized"{{.*}}

; Whole-function no-replay checks (O0, both seeds): from the protected
; LABEL to the next LABEL (unsupported_debugtrap) neither the intrinsic
; name nor any widenable trace may appear.  The top-level declaration sits
; before the first LABEL and is intentionally not covered.
; NO-REPLAY-LABEL: define i32 @protected(
; NO-REPLAY-NOT: experimental.widenable.condition
; NO-REPLAY-NOT: widenable
; NO-REPLAY-LABEL: define i32 @unsupported_debugtrap(

; ---- O2 checks ----

; SKIP-O2-DAG: Skipping VMP on unsupported_debugtrap: unsupported call instruction
; SKIP-O2-NOT: Skipping VMP on protected:

; The protected function is optnone, so the virtualized structure is
; identical at O2; the O2 checks stay virtualization/verification-safe.
; VIRT-O2-LABEL: define i32 @protected(
; VIRT-O2: %vmp.regs = alloca
; VIRT-O2-DAG: store volatile i64 1, ptr {{.*}}, align 4
; VIRT-O2: vmp.dispatch:
; VIRT-O2-DAG: [[TC:%.*]] = trunc i64 [[TCW:%.*]] to i1
; VIRT-O2-DAG: [[TCW]] = load volatile i64, ptr {{.*}}, align 4

; Negative case stays native at O2 as well.
; VIRT-O2-LABEL: define i32 @unsupported_debugtrap(
; VIRT-O2-NOT: vmp.dispatch
; VIRT-O2: call void @llvm.debugtrap()
; VIRT-O2: attributes{{.*}}"hikari.vmp.virtualized"{{.*}}

; Whole-function no-replay checks (O2, both seeds).
; NO-REPLAY-O2-LABEL: define i32 @protected(
; NO-REPLAY-O2-NOT: experimental.widenable.condition
; NO-REPLAY-O2-NOT: widenable
; NO-REPLAY-O2-LABEL: define i32 @unsupported_debugtrap(
