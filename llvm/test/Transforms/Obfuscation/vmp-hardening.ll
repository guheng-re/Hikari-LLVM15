; RUN: opt -S -verify-each -aesSeed=91 -vmp-report-stats -passes='default<O0>' %s -o %t.first.ll 2> %t.first.err
; RUN: opt -S -verify-each -aesSeed=91 -vmp-report-stats -passes='default<O0>' %s -o %t.second.ll 2> %t.second.err
; RUN: diff %t.first.ll %t.second.ll
; RUN: opt -S -verify-each -aesSeed=92 -passes='default<O0>' %s -o %t.other-seed.ll
; RUN: not diff %t.first.ll %t.other-seed.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.first.ll > %t.host.ll
; RUN: lli -force-interpreter %t.host.ll
; RUN: FileCheck %s < %t.first.ll
; RUN: FileCheck %s --check-prefix=STATS < %t.first.err
; RUN: %python %S/Inputs/vmp-tamper-bytecode.py %t.first.ll %t.tampered.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.tampered.ll > %t.tampered.host.ll
; RUN: not lli -force-interpreter %t.tampered.host.ll
; RUN: opt -S -verify-each -aesSeed=91 -vmp-integrity-check=false -passes='default<O0>' %s -o %t.no-integrity.ll
; RUN: not grep -E 'vmp\.integrity|llvm\.trap' %t.no-integrity.ll
; RUN: opt -S -verify-each -aesSeed=91 -vmp-fake-op-rate=100 -vmp-max-bytecode-words=32 -vmp-report-stats -passes='default<O0>' %s -o %t.budget.ll 2> %t.budget.err
; RUN: FileCheck %s --check-prefix=BUDGET < %t.budget.err
; RUN: opt -S -verify-each -aesSeed=91 -vmp-max-bytecode-words=16 -passes='default<O0>' %s -o %t.skip.ll 2>&1 | FileCheck %s --check-prefix=SKIP
; RUN: opt -S -verify-each -aesSeed=91 -vmp-max-source-insts=2 -passes='default<O0>' %s -o %t.source-skip.ll 2>&1 | FileCheck %s --check-prefix=SOURCE-SKIP
; RUN: opt -S -verify-each -aesSeed=91 -vmp-fake-op-rate=100 -vmp-max-fake-ops=0 -vmp-report-stats -passes='default<O0>' %s -o %t.no-fake.ll 2> %t.no-fake.err
; RUN: FileCheck %s --check-prefix=NO-FAKE < %t.no-fake.err

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()

define i32 @protected.one(i32 %value) noinline optnone {
entry:
  call void @hikari_vmp()
  %increment = add i32 %value, 3
  %scaled = mul i32 %increment, 5
  ret i32 %scaled
}

define i32 @protected.two(i32 %value) noinline optnone {
entry:
  call void @hikari_vmp()
  %increment = add i32 %value, 3
  %scaled = mul i32 %increment, 5
  ret i32 %scaled
}

define i32 @main() {
entry:
  %one = call i32 @protected.one(i32 4)
  %two = call i32 @protected.two(i32 4)
  %same = icmp eq i32 %one, %two
  %expected = icmp eq i32 %one, 35
  %ok = and i1 %same, %expected
  %result = select i1 %ok, i32 0, i32 1
  ret i32 %result
}

; CHECK-DAG: @__hikari_vmp_bc = private unnamed_addr constant
; CHECK-DAG: @__hikari_vmp_bc.1 = private unnamed_addr constant
; CHECK-LABEL: define i32 @protected.one(
; CHECK: call i64 @llvm.fshl.i64
; CHECK: %vmp.bytecode.decode = xor i64
; CHECK: vmp.integrity.loop:
; CHECK: call void @llvm.trap()
; CHECK-LABEL: define i32 @protected.two(
; CHECK: call i64 @llvm.fshl.i64
; CHECK: "hikari.vmp.virtualized"

; STATS: VMP stats for protected.one: source-insts=3, bytecode-words={{[0-9]+}}, fake-ops=1, integrity-check=on, generated-insts={{[0-9]+}}
; STATS: VMP stats for protected.two: source-insts=3, bytecode-words={{[0-9]+}}, fake-ops=1, integrity-check=on, generated-insts={{[0-9]+}}
; BUDGET: VMP stats for protected.one: source-insts=3, bytecode-words=32, fake-ops=1, integrity-check=on
; BUDGET: VMP stats for protected.two: source-insts=3, bytecode-words=32, fake-ops=1, integrity-check=on
; SKIP: Skipping VMP on protected.one: bytecode word budget
; SKIP: Skipping VMP on protected.two: bytecode word budget
; SOURCE-SKIP: Skipping VMP on protected.one: source instruction budget
; SOURCE-SKIP: Skipping VMP on protected.two: source instruction budget
; NO-FAKE: VMP stats for protected.one: source-insts=3, bytecode-words=24, fake-ops=0
; NO-FAKE: VMP stats for protected.two: source-insts=3, bytecode-words=24, fake-ops=0
