; All six *add/*sub/*mul.with.overflow.i1 intrinsics through the shared
; AddWithOverflow handler.  The i1 signed domain is {-1, 0} and the
; unsigned domain is {0, 1}; with those bit patterns the six intrinsics
; exercise distinct overflow combinations under the actual LLVM i1
; semantics: sadd/uadd overflow only on (1,1) (1+1=2), ssub/usub overflow
; only on (0,1) (0-1 underflows), smul overflows only on (1,1)
; ((-1)*(-1)=+1 is outside the signed i1 range), and umul never overflows.
; reference/* run natively, protected/* are virtualized; every call
; extracts aggregate fields 0 (result) and 1 (overflow flag), and each
; field is zero-extended, shifted and OR-packed into its own pair of i32
; bit positions (bit 2k = result, bit 2k+1 = flag), so both fields stay
; observable.  main compares reference and protected over all four (i1, i1)
; inputs.  reference is noinline optnone because LLVM 15's InstCombine
; rewrites smul.with.overflow.i1 into a plain `and` whose overflow flag is
; always 0 (KnownBits treats a 1-bit signed multiply as never overflowing),
; while SelectionDAG executes the intrinsic as overflowing for (true, true)
; ((-1)*(-1)=+1 is outside the signed i1 range) — an upstream optimizer vs
; codegen divergence on i1.  optnone keeps the reference body free of that
; rewrite so the O2 run compares executed semantics on both sides.
; Extractvalue i128 *with.overflow is accepted on the dedicated path
; (vmp-i128-overflow-semantic.ll).  This file keeps a still-rejected
; insertvalue / whole-pair i128 overflow use.
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
declare { i1, i1 } @llvm.sadd.with.overflow.i1(i1, i1)
declare { i1, i1 } @llvm.uadd.with.overflow.i1(i1, i1)
declare { i1, i1 } @llvm.ssub.with.overflow.i1(i1, i1)
declare { i1, i1 } @llvm.usub.with.overflow.i1(i1, i1)
declare { i1, i1 } @llvm.smul.with.overflow.i1(i1, i1)
declare { i1, i1 } @llvm.umul.with.overflow.i1(i1, i1)
declare { i128, i1 } @llvm.uadd.with.overflow.i128(i128, i128)

; ---- reference: native six-intrinsic pack ----

; Each pair of i1 fields is packed into its own two i32 bits:
; bit 2k = result of intrinsic k, bit 2k+1 = its overflow flag.
; noinline optnone keeps the O2 pipeline from rewriting the i1 intrinsic
; calls into different semantics (see the header).

define i32 @reference(i1 %a, i1 %b) noinline optnone {
entry:
  %p0 = call { i1, i1 } @llvm.sadd.with.overflow.i1(i1 %a, i1 %b)
  %r0 = extractvalue { i1, i1 } %p0, 0
  %f0 = extractvalue { i1, i1 } %p0, 1
  %r0.z = zext i1 %r0 to i32
  %f0.z = zext i1 %f0 to i32
  %f0.s = shl i32 %f0.z, 1
  %c0 = or i32 %r0.z, %f0.s
  %p1 = call { i1, i1 } @llvm.uadd.with.overflow.i1(i1 %a, i1 %b)
  %r1 = extractvalue { i1, i1 } %p1, 0
  %f1 = extractvalue { i1, i1 } %p1, 1
  %r1.z = zext i1 %r1 to i32
  %r1.s = shl i32 %r1.z, 2
  %f1.z = zext i1 %f1 to i32
  %f1.s = shl i32 %f1.z, 3
  %c1 = or i32 %c0, %r1.s
  %c2 = or i32 %c1, %f1.s
  %p2 = call { i1, i1 } @llvm.ssub.with.overflow.i1(i1 %a, i1 %b)
  %r2 = extractvalue { i1, i1 } %p2, 0
  %f2 = extractvalue { i1, i1 } %p2, 1
  %r2.z = zext i1 %r2 to i32
  %r2.s = shl i32 %r2.z, 4
  %f2.z = zext i1 %f2 to i32
  %f2.s = shl i32 %f2.z, 5
  %c3 = or i32 %c2, %r2.s
  %c4 = or i32 %c3, %f2.s
  %p3 = call { i1, i1 } @llvm.usub.with.overflow.i1(i1 %a, i1 %b)
  %r3 = extractvalue { i1, i1 } %p3, 0
  %f3 = extractvalue { i1, i1 } %p3, 1
  %r3.z = zext i1 %r3 to i32
  %r3.s = shl i32 %r3.z, 6
  %f3.z = zext i1 %f3 to i32
  %f3.s = shl i32 %f3.z, 7
  %c5 = or i32 %c4, %r3.s
  %c6 = or i32 %c5, %f3.s
  %p4 = call { i1, i1 } @llvm.smul.with.overflow.i1(i1 %a, i1 %b)
  %r4 = extractvalue { i1, i1 } %p4, 0
  %f4 = extractvalue { i1, i1 } %p4, 1
  %r4.z = zext i1 %r4 to i32
  %r4.s = shl i32 %r4.z, 8
  %f4.z = zext i1 %f4 to i32
  %f4.s = shl i32 %f4.z, 9
  %c7 = or i32 %c6, %r4.s
  %c8 = or i32 %c7, %f4.s
  %p5 = call { i1, i1 } @llvm.umul.with.overflow.i1(i1 %a, i1 %b)
  %r5 = extractvalue { i1, i1 } %p5, 0
  %f5 = extractvalue { i1, i1 } %p5, 1
  %r5.z = zext i1 %r5 to i32
  %r5.s = shl i32 %r5.z, 10
  %f5.z = zext i1 %f5 to i32
  %f5.s = shl i32 %f5.z, 11
  %c9 = or i32 %c8, %r5.s
  %code = or i32 %c9, %f5.s
  ret i32 %code
}

; ---- protected: same six intrinsics under VMP ----

define i32 @protected(i1 %a, i1 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %p0 = call { i1, i1 } @llvm.sadd.with.overflow.i1(i1 %a, i1 %b)
  %r0 = extractvalue { i1, i1 } %p0, 0
  %f0 = extractvalue { i1, i1 } %p0, 1
  %r0.z = zext i1 %r0 to i32
  %f0.z = zext i1 %f0 to i32
  %f0.s = shl i32 %f0.z, 1
  %c0 = or i32 %r0.z, %f0.s
  %p1 = call { i1, i1 } @llvm.uadd.with.overflow.i1(i1 %a, i1 %b)
  %r1 = extractvalue { i1, i1 } %p1, 0
  %f1 = extractvalue { i1, i1 } %p1, 1
  %r1.z = zext i1 %r1 to i32
  %r1.s = shl i32 %r1.z, 2
  %f1.z = zext i1 %f1 to i32
  %f1.s = shl i32 %f1.z, 3
  %c1 = or i32 %c0, %r1.s
  %c2 = or i32 %c1, %f1.s
  %p2 = call { i1, i1 } @llvm.ssub.with.overflow.i1(i1 %a, i1 %b)
  %r2 = extractvalue { i1, i1 } %p2, 0
  %f2 = extractvalue { i1, i1 } %p2, 1
  %r2.z = zext i1 %r2 to i32
  %r2.s = shl i32 %r2.z, 4
  %f2.z = zext i1 %f2 to i32
  %f2.s = shl i32 %f2.z, 5
  %c3 = or i32 %c2, %r2.s
  %c4 = or i32 %c3, %f2.s
  %p3 = call { i1, i1 } @llvm.usub.with.overflow.i1(i1 %a, i1 %b)
  %r3 = extractvalue { i1, i1 } %p3, 0
  %f3 = extractvalue { i1, i1 } %p3, 1
  %r3.z = zext i1 %r3 to i32
  %r3.s = shl i32 %r3.z, 6
  %f3.z = zext i1 %f3 to i32
  %f3.s = shl i32 %f3.z, 7
  %c5 = or i32 %c4, %r3.s
  %c6 = or i32 %c5, %f3.s
  %p4 = call { i1, i1 } @llvm.smul.with.overflow.i1(i1 %a, i1 %b)
  %r4 = extractvalue { i1, i1 } %p4, 0
  %f4 = extractvalue { i1, i1 } %p4, 1
  %r4.z = zext i1 %r4 to i32
  %r4.s = shl i32 %r4.z, 8
  %f4.z = zext i1 %f4 to i32
  %f4.s = shl i32 %f4.z, 9
  %c7 = or i32 %c6, %r4.s
  %c8 = or i32 %c7, %f4.s
  %p5 = call { i1, i1 } @llvm.umul.with.overflow.i1(i1 %a, i1 %b)
  %r5 = extractvalue { i1, i1 } %p5, 0
  %f5 = extractvalue { i1, i1 } %p5, 1
  %r5.z = zext i1 %r5 to i32
  %r5.s = shl i32 %r5.z, 10
  %f5.z = zext i1 %f5 to i32
  %f5.s = shl i32 %f5.z, 11
  %c9 = or i32 %c8, %r5.s
  %code = or i32 %c9, %f5.s
  ret i32 %code
}

; ---- negative case: must SKIP, never virtualize ----

; insertvalue / whole-pair i128 overflow stays rejected: the dedicated
; path requires only single-index extractvalue 0/1.
define i32 @unsupported_overflow_i128(i128 %a, i128 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %pair = call { i128, i1 } @llvm.uadd.with.overflow.i128(i128 %a, i128 %b)
  %q = insertvalue { i128, i1 } %pair, i1 true, 1
  %sum = extractvalue { i128, i1 } %q, 0
  %sum.t = trunc i128 %sum to i32
  ret i32 %sum.t
}

; ---- main: parity checks over all four (i1, i1) inputs ----

define i32 @main() {
entry:
  %e0 = call i32 @reference(i1 false, i1 false)
  %a0 = call i32 @protected(i1 false, i1 false)
  %e1 = call i32 @reference(i1 false, i1 true)
  %a1 = call i32 @protected(i1 false, i1 true)
  %e2 = call i32 @reference(i1 true, i1 false)
  %a2 = call i32 @protected(i1 true, i1 false)
  %e3 = call i32 @reference(i1 true, i1 true)
  %a3 = call i32 @protected(i1 true, i1 true)
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

; The insertvalue i128 overflow sibling is rejected by the late call
; gate (aggregate is not used only via extractvalue 0/1).
; SKIP-DAG: Skipping VMP on unsupported_overflow_i128: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected:

; VIRT-LABEL: define i32 @protected(
; VIRT: %vmp.regs = alloca
; VIRT: vmp.dispatch:
; All six i1 with.overflow calls are replayed exactly by the AddWithOverflow
; handler; each call's two arguments are truncs of i64 volatile
; integer-frame loads, and each aggregate field is extracted separately
; (field 0 = result, field 1 = flag), zero-extended to i64 and
; volatile-stored into the integer frame.  Handler order is randomized, so
; all checks are DAG with definitions before uses.
; sadd
; VIRT-DAG: [[S0:%.*]] = call { i1, i1 } @llvm.sadd.with.overflow.i1(i1 [[S0A:%.*]], i1 [[S0B:%.*]])
; VIRT-DAG: [[S0A]] = trunc i64 [[S0AW:%.*]] to i1
; VIRT-DAG: [[S0AW]] = load volatile i64, ptr {{.*}}, align 4
; VIRT-DAG: [[S0B]] = trunc i64 [[S0BW:%.*]] to i1
; VIRT-DAG: [[S0BW]] = load volatile i64, ptr {{.*}}, align 4
; VIRT-DAG: [[S0R:%.*]] = extractvalue { i1, i1 } [[S0]], 0
; VIRT-DAG: [[S0RW:%.*]] = zext i1 [[S0R]] to i64
; VIRT-DAG: store volatile i64 [[S0RW]], ptr {{.*}}, align 4
; VIRT-DAG: [[S0F:%.*]] = extractvalue { i1, i1 } [[S0]], 1
; VIRT-DAG: [[S0FW:%.*]] = zext i1 [[S0F]] to i64
; VIRT-DAG: store volatile i64 [[S0FW]], ptr {{.*}}, align 4
; uadd
; VIRT-DAG: [[U0:%.*]] = call { i1, i1 } @llvm.uadd.with.overflow.i1(i1 [[U0A:%.*]], i1 [[U0B:%.*]])
; VIRT-DAG: [[U0A]] = trunc i64 [[U0AW:%.*]] to i1
; VIRT-DAG: [[U0AW]] = load volatile i64, ptr {{.*}}, align 4
; VIRT-DAG: [[U0B]] = trunc i64 [[U0BW:%.*]] to i1
; VIRT-DAG: [[U0BW]] = load volatile i64, ptr {{.*}}, align 4
; VIRT-DAG: [[U0R:%.*]] = extractvalue { i1, i1 } [[U0]], 0
; VIRT-DAG: [[U0RW:%.*]] = zext i1 [[U0R]] to i64
; VIRT-DAG: store volatile i64 [[U0RW]], ptr {{.*}}, align 4
; VIRT-DAG: [[U0F:%.*]] = extractvalue { i1, i1 } [[U0]], 1
; VIRT-DAG: [[U0FW:%.*]] = zext i1 [[U0F]] to i64
; VIRT-DAG: store volatile i64 [[U0FW]], ptr {{.*}}, align 4
; ssub
; VIRT-DAG: [[SB:%.*]] = call { i1, i1 } @llvm.ssub.with.overflow.i1(i1 [[SBA:%.*]], i1 [[SBB:%.*]])
; VIRT-DAG: [[SBA]] = trunc i64 [[SBAW:%.*]] to i1
; VIRT-DAG: [[SBAW]] = load volatile i64, ptr {{.*}}, align 4
; VIRT-DAG: [[SBB]] = trunc i64 [[SBBW:%.*]] to i1
; VIRT-DAG: [[SBBW]] = load volatile i64, ptr {{.*}}, align 4
; VIRT-DAG: [[SBR:%.*]] = extractvalue { i1, i1 } [[SB]], 0
; VIRT-DAG: [[SBRW:%.*]] = zext i1 [[SBR]] to i64
; VIRT-DAG: store volatile i64 [[SBRW]], ptr {{.*}}, align 4
; VIRT-DAG: [[SBF:%.*]] = extractvalue { i1, i1 } [[SB]], 1
; VIRT-DAG: [[SBFW:%.*]] = zext i1 [[SBF]] to i64
; VIRT-DAG: store volatile i64 [[SBFW]], ptr {{.*}}, align 4
; usub
; VIRT-DAG: [[UB:%.*]] = call { i1, i1 } @llvm.usub.with.overflow.i1(i1 [[UBA:%.*]], i1 [[UBB:%.*]])
; VIRT-DAG: [[UBA]] = trunc i64 [[UBAW:%.*]] to i1
; VIRT-DAG: [[UBAW]] = load volatile i64, ptr {{.*}}, align 4
; VIRT-DAG: [[UBB]] = trunc i64 [[UBBW:%.*]] to i1
; VIRT-DAG: [[UBBW]] = load volatile i64, ptr {{.*}}, align 4
; VIRT-DAG: [[UBR:%.*]] = extractvalue { i1, i1 } [[UB]], 0
; VIRT-DAG: [[UBRW:%.*]] = zext i1 [[UBR]] to i64
; VIRT-DAG: store volatile i64 [[UBRW]], ptr {{.*}}, align 4
; VIRT-DAG: [[UBF:%.*]] = extractvalue { i1, i1 } [[UB]], 1
; VIRT-DAG: [[UBFW:%.*]] = zext i1 [[UBF]] to i64
; VIRT-DAG: store volatile i64 [[UBFW]], ptr {{.*}}, align 4
; smul
; VIRT-DAG: [[SM:%.*]] = call { i1, i1 } @llvm.smul.with.overflow.i1(i1 [[SMA:%.*]], i1 [[SMB:%.*]])
; VIRT-DAG: [[SMA]] = trunc i64 [[SMAW:%.*]] to i1
; VIRT-DAG: [[SMAW]] = load volatile i64, ptr {{.*}}, align 4
; VIRT-DAG: [[SMB]] = trunc i64 [[SMBW:%.*]] to i1
; VIRT-DAG: [[SMBW]] = load volatile i64, ptr {{.*}}, align 4
; VIRT-DAG: [[SMR:%.*]] = extractvalue { i1, i1 } [[SM]], 0
; VIRT-DAG: [[SMRW:%.*]] = zext i1 [[SMR]] to i64
; VIRT-DAG: store volatile i64 [[SMRW]], ptr {{.*}}, align 4
; VIRT-DAG: [[SMF:%.*]] = extractvalue { i1, i1 } [[SM]], 1
; VIRT-DAG: [[SMFW:%.*]] = zext i1 [[SMF]] to i64
; VIRT-DAG: store volatile i64 [[SMFW]], ptr {{.*}}, align 4
; umul
; VIRT-DAG: [[UM:%.*]] = call { i1, i1 } @llvm.umul.with.overflow.i1(i1 [[UMA:%.*]], i1 [[UMB:%.*]])
; VIRT-DAG: [[UMA]] = trunc i64 [[UMAW:%.*]] to i1
; VIRT-DAG: [[UMAW]] = load volatile i64, ptr {{.*}}, align 4
; VIRT-DAG: [[UMB]] = trunc i64 [[UMBW:%.*]] to i1
; VIRT-DAG: [[UMBW]] = load volatile i64, ptr {{.*}}, align 4
; VIRT-DAG: [[UMR:%.*]] = extractvalue { i1, i1 } [[UM]], 0
; VIRT-DAG: [[UMRW:%.*]] = zext i1 [[UMR]] to i64
; VIRT-DAG: store volatile i64 [[UMRW]], ptr {{.*}}, align 4
; VIRT-DAG: [[UMF:%.*]] = extractvalue { i1, i1 } [[UM]], 1
; VIRT-DAG: [[UMFW:%.*]] = zext i1 [[UMF]] to i64
; VIRT-DAG: store volatile i64 [[UMFW]], ptr {{.*}}, align 4

; Negative case stays native: no dispatch, no virtualized attribute.
; VIRT-LABEL: define i32 @unsupported_overflow_i128(
; VIRT-NOT: vmp.dispatch
; VIRT: call { i128, i1 } @llvm.uadd.with.overflow.i128(

; VIRT: attributes{{.*}}"hikari.vmp.virtualized"{{.*}}

; ---- O2 checks ----

; SKIP-O2-DAG: Skipping VMP on unsupported_overflow_i128: unsupported call instruction
; SKIP-O2-NOT: Skipping VMP on protected:

; VIRT-O2-LABEL: define i32 @protected(
; VIRT-O2: %vmp.regs = alloca
; VIRT-O2: vmp.dispatch:
; The protected function is optnone, so the replay structure is identical
; at O2.
; VIRT-O2-DAG: [[S0:%.*]] = call { i1, i1 } @llvm.sadd.with.overflow.i1(i1 [[S0A:%.*]], i1 [[S0B:%.*]])
; VIRT-O2-DAG: [[S0A]] = trunc i64 [[S0AW:%.*]] to i1
; VIRT-O2-DAG: [[S0AW]] = load volatile i64, ptr {{.*}}, align 4
; VIRT-O2-DAG: [[S0B]] = trunc i64 [[S0BW:%.*]] to i1
; VIRT-O2-DAG: [[S0BW]] = load volatile i64, ptr {{.*}}, align 4
; VIRT-O2-DAG: [[S0R:%.*]] = extractvalue { i1, i1 } [[S0]], 0
; VIRT-O2-DAG: [[S0RW:%.*]] = zext i1 [[S0R]] to i64
; VIRT-O2-DAG: store volatile i64 [[S0RW]], ptr {{.*}}, align 4
; VIRT-O2-DAG: [[S0F:%.*]] = extractvalue { i1, i1 } [[S0]], 1
; VIRT-O2-DAG: [[S0FW:%.*]] = zext i1 [[S0F]] to i64
; VIRT-O2-DAG: store volatile i64 [[S0FW]], ptr {{.*}}, align 4
; VIRT-O2-DAG: [[U0:%.*]] = call { i1, i1 } @llvm.uadd.with.overflow.i1(i1 [[U0A:%.*]], i1 [[U0B:%.*]])
; VIRT-O2-DAG: [[U0A]] = trunc i64 [[U0AW:%.*]] to i1
; VIRT-O2-DAG: [[U0AW]] = load volatile i64, ptr {{.*}}, align 4
; VIRT-O2-DAG: [[U0B]] = trunc i64 [[U0BW:%.*]] to i1
; VIRT-O2-DAG: [[U0BW]] = load volatile i64, ptr {{.*}}, align 4
; VIRT-O2-DAG: [[U0R:%.*]] = extractvalue { i1, i1 } [[U0]], 0
; VIRT-O2-DAG: [[U0RW:%.*]] = zext i1 [[U0R]] to i64
; VIRT-O2-DAG: store volatile i64 [[U0RW]], ptr {{.*}}, align 4
; VIRT-O2-DAG: [[U0F:%.*]] = extractvalue { i1, i1 } [[U0]], 1
; VIRT-O2-DAG: [[U0FW:%.*]] = zext i1 [[U0F]] to i64
; VIRT-O2-DAG: store volatile i64 [[U0FW]], ptr {{.*}}, align 4
; VIRT-O2-DAG: [[SB:%.*]] = call { i1, i1 } @llvm.ssub.with.overflow.i1(i1 [[SBA:%.*]], i1 [[SBB:%.*]])
; VIRT-O2-DAG: [[SBA]] = trunc i64 [[SBAW:%.*]] to i1
; VIRT-O2-DAG: [[SBAW]] = load volatile i64, ptr {{.*}}, align 4
; VIRT-O2-DAG: [[SBB]] = trunc i64 [[SBBW:%.*]] to i1
; VIRT-O2-DAG: [[SBBW]] = load volatile i64, ptr {{.*}}, align 4
; VIRT-O2-DAG: [[SBR:%.*]] = extractvalue { i1, i1 } [[SB]], 0
; VIRT-O2-DAG: [[SBRW:%.*]] = zext i1 [[SBR]] to i64
; VIRT-O2-DAG: store volatile i64 [[SBRW]], ptr {{.*}}, align 4
; VIRT-O2-DAG: [[SBF:%.*]] = extractvalue { i1, i1 } [[SB]], 1
; VIRT-O2-DAG: [[SBFW:%.*]] = zext i1 [[SBF]] to i64
; VIRT-O2-DAG: store volatile i64 [[SBFW]], ptr {{.*}}, align 4
; VIRT-O2-DAG: [[UB:%.*]] = call { i1, i1 } @llvm.usub.with.overflow.i1(i1 [[UBA:%.*]], i1 [[UBB:%.*]])
; VIRT-O2-DAG: [[UBA]] = trunc i64 [[UBAW:%.*]] to i1
; VIRT-O2-DAG: [[UBAW]] = load volatile i64, ptr {{.*}}, align 4
; VIRT-O2-DAG: [[UBB]] = trunc i64 [[UBBW:%.*]] to i1
; VIRT-O2-DAG: [[UBBW]] = load volatile i64, ptr {{.*}}, align 4
; VIRT-O2-DAG: [[UBR:%.*]] = extractvalue { i1, i1 } [[UB]], 0
; VIRT-O2-DAG: [[UBRW:%.*]] = zext i1 [[UBR]] to i64
; VIRT-O2-DAG: store volatile i64 [[UBRW]], ptr {{.*}}, align 4
; VIRT-O2-DAG: [[UBF:%.*]] = extractvalue { i1, i1 } [[UB]], 1
; VIRT-O2-DAG: [[UBFW:%.*]] = zext i1 [[UBF]] to i64
; VIRT-O2-DAG: store volatile i64 [[UBFW]], ptr {{.*}}, align 4
; VIRT-O2-DAG: [[SM:%.*]] = call { i1, i1 } @llvm.smul.with.overflow.i1(i1 [[SMA:%.*]], i1 [[SMB:%.*]])
; VIRT-O2-DAG: [[SMA]] = trunc i64 [[SMAW:%.*]] to i1
; VIRT-O2-DAG: [[SMAW]] = load volatile i64, ptr {{.*}}, align 4
; VIRT-O2-DAG: [[SMB]] = trunc i64 [[SMBW:%.*]] to i1
; VIRT-O2-DAG: [[SMBW]] = load volatile i64, ptr {{.*}}, align 4
; VIRT-O2-DAG: [[SMR:%.*]] = extractvalue { i1, i1 } [[SM]], 0
; VIRT-O2-DAG: [[SMRW:%.*]] = zext i1 [[SMR]] to i64
; VIRT-O2-DAG: store volatile i64 [[SMRW]], ptr {{.*}}, align 4
; VIRT-O2-DAG: [[SMF:%.*]] = extractvalue { i1, i1 } [[SM]], 1
; VIRT-O2-DAG: [[SMFW:%.*]] = zext i1 [[SMF]] to i64
; VIRT-O2-DAG: store volatile i64 [[SMFW]], ptr {{.*}}, align 4
; VIRT-O2-DAG: [[UM:%.*]] = call { i1, i1 } @llvm.umul.with.overflow.i1(i1 [[UMA:%.*]], i1 [[UMB:%.*]])
; VIRT-O2-DAG: [[UMA]] = trunc i64 [[UMAW:%.*]] to i1
; VIRT-O2-DAG: [[UMAW]] = load volatile i64, ptr {{.*}}, align 4
; VIRT-O2-DAG: [[UMB]] = trunc i64 [[UMBW:%.*]] to i1
; VIRT-O2-DAG: [[UMBW]] = load volatile i64, ptr {{.*}}, align 4
; VIRT-O2-DAG: [[UMR:%.*]] = extractvalue { i1, i1 } [[UM]], 0
; VIRT-O2-DAG: [[UMRW:%.*]] = zext i1 [[UMR]] to i64
; VIRT-O2-DAG: store volatile i64 [[UMRW]], ptr {{.*}}, align 4
; VIRT-O2-DAG: [[UMF:%.*]] = extractvalue { i1, i1 } [[UM]], 1
; VIRT-O2-DAG: [[UMFW:%.*]] = zext i1 [[UMF]] to i64
; VIRT-O2-DAG: store volatile i64 [[UMFW]], ptr {{.*}}, align 4

; Negative case stays native at O2 as well.
; VIRT-O2-LABEL: define i32 @unsupported_overflow_i128(
; VIRT-O2-NOT: vmp.dispatch
; VIRT-O2: call { i128, i1 } @llvm.uadd.with.overflow.i128(
; VIRT-O2: attributes{{.*}}"hikari.vmp.virtualized"{{.*}}
