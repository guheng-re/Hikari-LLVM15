; uadd.with.overflow differential: i32 (existing) and i1 (new).  The i1
; form extracts both aggregate fields and packs them into an injective i32
; exit code (bit0 = sum, bit1 = overflow), so a VM fault in either the
; result or the flag register changes main's comparison.  reference/* run
; natively, protected/* are virtualized through the dedicated AddWithOverflow
; handler, which replays the exact intrinsic and writes each field through
; its own register (result and flag each zero-extended to an i64 integer
; frame slot volatile store).  Extractvalue i128 *with.overflow is
; accepted on the same dedicated path (vmp-i128-overflow-semantic.ll).
; This file keeps a still-rejected insertvalue / whole-pair i128
; overflow use: late eligibility skips with "unsupported call
; instruction", keeping the native call and no VMP dispatcher.
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

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare { i32, i1 } @llvm.uadd.with.overflow.i32(i32, i32)
declare { i1, i1 } @llvm.uadd.with.overflow.i1(i1, i1)
declare { i128, i1 } @llvm.uadd.with.overflow.i128(i128, i128)

; ---- reference: native i32 with.overflow ----

define i32 @reference(i32 %a, i32 %b) {
entry:
  %pair = call { i32, i1 } @llvm.uadd.with.overflow.i32(i32 %a, i32 %b)
  %sum = extractvalue { i32, i1 } %pair, 0
  %ov = extractvalue { i32, i1 } %pair, 1
  %ov.z = zext i1 %ov to i32
  %result = xor i32 %sum, %ov.z
  ret i32 %result
}

; ---- protected: same i32 with.overflow under VMP ----

define i32 @protected(i32 %a, i32 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %pair = call { i32, i1 } @llvm.uadd.with.overflow.i32(i32 %a, i32 %b)
  %sum = extractvalue { i32, i1 } %pair, 0
  %ov = extractvalue { i32, i1 } %pair, 1
  %ov.z = zext i1 %ov to i32
  %result = xor i32 %sum, %ov.z
  ret i32 %result
}

; ---- reference: native i1 with.overflow ----

; Both aggregate fields are extracted and packed into an injective i32 exit
; code: bit0 = sum, bit1 = overflow.  Each of the four input pairs maps to a
; distinct code (false+false -> 0, false+true -> 1, true+false -> 1,
; true+true -> 2), so main verifies the result and the flag independently.

define i32 @reference_i1(i1 %a, i1 %b) {
entry:
  %pair = call { i1, i1 } @llvm.uadd.with.overflow.i1(i1 %a, i1 %b)
  %sum = extractvalue { i1, i1 } %pair, 0
  %ov = extractvalue { i1, i1 } %pair, 1
  %sum.z = zext i1 %sum to i32
  %ov.z = zext i1 %ov to i32
  %ov.s = shl i32 %ov.z, 1
  %result = or i32 %sum.z, %ov.s
  ret i32 %result
}

; ---- protected: same i1 with.overflow under VMP ----

define i32 @protected_i1(i1 %a, i1 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %pair = call { i1, i1 } @llvm.uadd.with.overflow.i1(i1 %a, i1 %b)
  %sum = extractvalue { i1, i1 } %pair, 0
  %ov = extractvalue { i1, i1 } %pair, 1
  %sum.z = zext i1 %sum to i32
  %ov.z = zext i1 %ov to i32
  %ov.s = shl i32 %ov.z, 1
  %result = or i32 %sum.z, %ov.s
  ret i32 %result
}

; ---- negative case: must SKIP, never virtualize ----

; insertvalue / whole-pair i128 overflow stays rejected: the dedicated
; path requires only single-index extractvalue 0/1.  The insertvalue
; user keeps the call off that path, so eligibility reports
; "unsupported call instruction" and the body stays native.
define i32 @unsupported_overflow_i128(i128 %a, i128 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %pair = call { i128, i1 } @llvm.uadd.with.overflow.i128(i128 %a, i128 %b)
  %q = insertvalue { i128, i1 } %pair, i1 true, 1
  %sum = extractvalue { i128, i1 } %q, 0
  %sum.t = trunc i128 %sum to i32
  ret i32 %sum.t
}

; ---- main: parity checks ----

define i32 @main() {
entry:
  ; i32: no overflow (10+20) and unsigned overflow (UINT_MAX + 1).
  %e0 = call i32 @reference(i32 10, i32 20)
  %a0 = call i32 @protected(i32 10, i32 20)
  %e1 = call i32 @reference(i32 4294967295, i32 1)
  %a1 = call i32 @protected(i32 4294967295, i32 1)
  ; i1: false+false, false+true, true+false, true+true.
  %e2 = call i32 @reference_i1(i1 false, i1 false)
  %a2 = call i32 @protected_i1(i1 false, i1 false)
  %e3 = call i32 @reference_i1(i1 false, i1 true)
  %a3 = call i32 @protected_i1(i1 false, i1 true)
  %e4 = call i32 @reference_i1(i1 true, i1 false)
  %a4 = call i32 @protected_i1(i1 true, i1 false)
  %e5 = call i32 @reference_i1(i1 true, i1 true)
  %a5 = call i32 @protected_i1(i1 true, i1 true)
  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %e1, %a1
  %m2 = icmp eq i32 %e2, %a2
  %m3 = icmp eq i32 %e3, %a3
  %m4 = icmp eq i32 %e4, %a4
  %m5 = icmp eq i32 %e5, %a5
  %t0 = and i1 %m0, %m1
  %t1 = and i1 %t0, %m2
  %t2 = and i1 %t1, %m3
  %t3 = and i1 %t2, %m4
  %ok = and i1 %t3, %m5
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; ---- O0 checks ----

; The insertvalue i128 overflow sibling is rejected by the late call
; gate (aggregate is not used only via extractvalue 0/1).
; SKIP-DAG: Skipping VMP on unsupported_overflow_i128: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected:
; SKIP-NOT: Skipping VMP on protected_i1:

; VIRT-LABEL: define i32 @protected(
; VIRT: vmp.dispatch:
; The i32 with.overflow call is replayed by the AddWithOverflow handler; the
; result and flag are written through extractvalue and volatile stores.
; VIRT-DAG: call { i32, i1 } @llvm.uadd.with.overflow.i32(
; VIRT-DAG: extractvalue { i32, i1 } {{.*}}, 0
; VIRT-DAG: extractvalue { i32, i1 } {{.*}}, 1

; VIRT-LABEL: define i32 @protected_i1(
; VIRT: vmp.dispatch:
; The i1 with.overflow call is replayed exactly; both arguments are truncs
; of i64 volatile integer-frame loads.  Each aggregate field is extracted
; separately, zero-extended to i64 and volatile-stored into the integer
; frame — the handler captures one register per extractvalue, so the result
; and the flag land in distinct slots.  Handler order is randomized, so all
; checks are DAG with definitions before uses.
; VIRT-DAG: [[OV:%.*]] = call { i1, i1 } @llvm.uadd.with.overflow.i1(i1 [[OA:%.*]], i1 [[OB:%.*]])
; VIRT-DAG: [[OA]] = trunc i64 [[OAW:%.*]] to i1
; VIRT-DAG: [[OAW]] = load volatile i64, ptr {{.*}}, align 4
; VIRT-DAG: [[OB]] = trunc i64 [[OBW:%.*]] to i1
; VIRT-DAG: [[OBW]] = load volatile i64, ptr {{.*}}, align 4
; VIRT-DAG: [[OR:%.*]] = extractvalue { i1, i1 } [[OV]], 0
; VIRT-DAG: [[ORW:%.*]] = zext i1 [[OR]] to i64
; VIRT-DAG: store volatile i64 [[ORW]], ptr {{.*}}, align 4
; VIRT-DAG: [[OF:%.*]] = extractvalue { i1, i1 } [[OV]], 1
; VIRT-DAG: [[OFW:%.*]] = zext i1 [[OF]] to i64
; VIRT-DAG: store volatile i64 [[OFW]], ptr {{.*}}, align 4

; Negative case stays native: no dispatch, no virtualized attribute.
; VIRT-LABEL: define i32 @unsupported_overflow_i128(
; VIRT-NOT: vmp.dispatch
; VIRT: call { i128, i1 } @llvm.uadd.with.overflow.i128(

; VIRT: attributes{{.*}}"hikari.vmp.virtualized"{{.*}}

; ---- O2 checks ----

; SKIP-O2-DAG: Skipping VMP on unsupported_overflow_i128: unsupported call instruction
; SKIP-O2-NOT: Skipping VMP on protected:
; SKIP-O2-NOT: Skipping VMP on protected_i1:

; VIRT-O2-LABEL: define i32 @protected(
; VIRT-O2: vmp.dispatch:
; VIRT-O2-DAG: call { i32, i1 } @llvm.uadd.with.overflow.i32(
; VIRT-O2-DAG: extractvalue { i32, i1 } {{.*}}, 0
; VIRT-O2-DAG: extractvalue { i32, i1 } {{.*}}, 1

; VIRT-O2-LABEL: define i32 @protected_i1(
; VIRT-O2: vmp.dispatch:
; VIRT-O2-DAG: [[OV:%.*]] = call { i1, i1 } @llvm.uadd.with.overflow.i1(i1 [[OA:%.*]], i1 [[OB:%.*]])
; VIRT-O2-DAG: [[OA]] = trunc i64 [[OAW:%.*]] to i1
; VIRT-O2-DAG: [[OAW]] = load volatile i64, ptr {{.*}}, align 4
; VIRT-O2-DAG: [[OB]] = trunc i64 [[OBW:%.*]] to i1
; VIRT-O2-DAG: [[OBW]] = load volatile i64, ptr {{.*}}, align 4
; VIRT-O2-DAG: [[OR:%.*]] = extractvalue { i1, i1 } [[OV]], 0
; VIRT-O2-DAG: [[ORW:%.*]] = zext i1 [[OR]] to i64
; VIRT-O2-DAG: store volatile i64 [[ORW]], ptr {{.*}}, align 4
; VIRT-O2-DAG: [[OF:%.*]] = extractvalue { i1, i1 } [[OV]], 1
; VIRT-O2-DAG: [[OFW:%.*]] = zext i1 [[OF]] to i64
; VIRT-O2-DAG: store volatile i64 [[OFW]], ptr {{.*}}, align 4

; Negative case stays native at O2 as well.
; VIRT-O2-LABEL: define i32 @unsupported_overflow_i128(
; VIRT-O2-NOT: vmp.dispatch
; VIRT-O2: call { i128, i1 } @llvm.uadd.with.overflow.i128(
; VIRT-O2: attributes{{.*}}"hikari.vmp.virtualized"{{.*}}
