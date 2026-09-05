; llvm.pseudoprobe as a strict constant re-emission: the fixed
; void(i64, i64, i32, i64) intrinsic is admitted only when all four
; arguments are ConstantInt, and isCallImmediateArgument keeps them as true
; literals on the descriptor so the call handler re-emits them inside the
; interpreter as constants — never as load/trunc of virtual-register
; values, because SelectionDAG reads probe args with cast<ConstantInt>.
; The probe call is neither omitted nor replaced.  reference and protected
; run the same pure-integer arithmetic with one probe in the middle each,
; using visibly different constants; main compares the observable results
; over multiple inputs.  The dynamic-argument sibling (i64 %g) is rejected
; by the whitelist with the stable "unsupported call instruction"
; diagnostic and stays native, but its SelectionDAG lowering reads the
; probe args with cast<ConstantInt> (undefined behaviour for an SSA value,
; a crash in assert builds), so llc and lli run on a copy with the uncalled
; negative function dropped by sed; the negative itself is asserted on the
; unmodified module and is never executed.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: sed '/^define i32 @unsupported_dynamic_probe(/,/^}/d' %t.o0.ll > %t.o0.codegen.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.codegen.ll -o %t.o0.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.codegen.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP-O2 < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT-O2 < %t.o2.ll
; RUN: sed '/^define i32 @unsupported_dynamic_probe(/,/^}/d' %t.o2.ll > %t.o2.codegen.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.codegen.ll -o %t.o2.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.codegen.ll > %t.o2.host.ll
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
declare void @llvm.pseudoprobe(i64, i64, i32, i64)

; ---- reference: native with one constant probe ----

define i32 @reference(i32 %seed) {
entry:
  %p = mul i32 %seed, 3
  call void @llvm.pseudoprobe(i64 100, i64 200, i32 0, i64 3)
  %o = add i32 %p, 1
  ret i32 %o
}

; ---- protected: same arithmetic with a different constant probe under VMP ----

define i32 @protected(i32 %seed) noinline optnone {
entry:
  call void @hikari_vmp()
  %p = mul i32 %seed, 3
  call void @llvm.pseudoprobe(i64 101, i64 201, i32 0, i64 5)
  %o = add i32 %p, 1
  ret i32 %o
}

; ---- negative case: must SKIP, never virtualize ----

; The dynamic-argument probe sibling is rejected by the whitelist (the
; strict form requires all four args to be ConstantInt); the function
; itself is otherwise eligible, so the reason is a stable unsupported call.
; The function is never called from main, so the dynamic probe is never
; executed.
define i32 @unsupported_dynamic_probe(i32 %seed, i64 %g) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.pseudoprobe(i64 %g, i64 2, i32 1, i64 0)
  %o = add i32 %seed, 1
  ret i32 %o
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

; SKIP-DAG: Skipping VMP on unsupported_dynamic_probe: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected:

; VIRT-LABEL: define i32 @protected(
; VIRT: %vmp.regs = alloca
; VIRT: vmp.dispatch:
; The pseudoprobe call is re-emitted exactly once inside the interpreter
; with all four arguments as true literals (i64/i64/i32/i64) — never as
; load/trunc of virtual-register values.
; VIRT-DAG: call void @llvm.pseudoprobe(i64 101, i64 201, i32 0, i64 5)

; Negative case stays native: no dispatch, no virtualized attribute.
; VIRT-LABEL: define i32 @unsupported_dynamic_probe(
; VIRT-NOT: vmp.dispatch
; VIRT: call void @llvm.pseudoprobe(i64 %g, i64 2, i32 1, i64 0)

; VIRT: attributes{{.*}}"hikari.vmp.virtualized"{{.*}}

; ---- O2 checks ----

; SKIP-O2-DAG: Skipping VMP on unsupported_dynamic_probe: unsupported call instruction
; SKIP-O2-NOT: Skipping VMP on protected:

; The protected function is optnone, so the virtualized structure is
; identical at O2; the O2 checks stay virtualization/verification-safe.
; VIRT-O2-LABEL: define i32 @protected(
; VIRT-O2: %vmp.regs = alloca
; VIRT-O2: vmp.dispatch:
; VIRT-O2-DAG: call void @llvm.pseudoprobe(i64 101, i64 201, i32 0, i64 5)

; Negative case stays native at O2 as well.
; VIRT-O2-LABEL: define i32 @unsupported_dynamic_probe(
; VIRT-O2-NOT: vmp.dispatch
; VIRT-O2: call void @llvm.pseudoprobe(i64 %g, i64 2, i32 1, i64 0)
; VIRT-O2: attributes{{.*}}"hikari.vmp.virtualized"{{.*}}
