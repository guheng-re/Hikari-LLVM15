; Focused AS0 integer atomicrmw max/min/umax/umin lock-in (generic IR,
; no new opcode).  Production already replays native CreateAtomicRMW:
; result is the old value, the cell becomes signed or unsigned
; min/max(old, rhs), and ordering / syncscope / volatile / alignment /
; memory metadata are copied onto the interpreter instruction.
; Integer-only i8/i16/i32/i64.  Do not treat nand, fmax/fmin, xchg,
; add/sub, and/or/xor, cmpxchg, or fence as this family's negatives —
; those stay on the existing broader atomicrmw surface.  Pointer/float
; integer-extrema RMW are LLVM 15 verifier-illegal.  unordered and
; i1/vector/aggregate extrema are also illegal.
;
; Sequences force signed vs unsigned divergence: signed max of -20 vs 5
; keeps 5, while unsigned umax of 5 vs -1 keeps all-ones.  Independent
; olds+finals (no XOR mix).  i32 seq_cst max carries !tbaa.
;
; Parseable misses: i128 max/min/umax/umin, AS1 max, 256-bit vector
; return, non-AArch64 module triple.
;
; Pipeline:
;   O0/O2 x aesSeed 97/7: opt → SKIP → VIRT → internalize main →
;   AArch64 llc/readobj → host lli on transformed triple only.
;   Source-triple swap is HOST.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.ll -o %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.live.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.ll -o %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.live.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.s7.ll -o %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.s7.live.ll > %t.o0.s7.host.ll
; RUN: lli -force-interpreter %t.o0.s7.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.s7.ll -o %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.s7.live.ll > %t.o2.s7.host.ll
; RUN: lli -force-interpreter %t.o2.s7.host.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %s | opt -S -verify-each -aesSeed=97 -passes='default<O0>' - 2>&1 | FileCheck %s --check-prefix=HOST

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()

@i8_max = global i8 0, align 1
@i8_umin = global i8 0, align 1
@i16_min = global i16 0, align 2
@i16_umax = global i16 0, align 2
@i32_max = global i32 0, align 4
@i32_umax = global i32 0, align 4
@i64_min = global i64 0, align 8
@i64_umin = global i64 0, align 8
@i128_cell = global i128 0, align 16
@as1_cell = addrspace(1) global i32 0, align 4

@ref_i8_obs = global [6 x i8] zeroinitializer, align 1
@prot_i8_obs = global [6 x i8] zeroinitializer, align 1
@ref_i16_obs = global [6 x i16] zeroinitializer, align 2
@prot_i16_obs = global [6 x i16] zeroinitializer, align 2
@ref_i32_obs = global [6 x i32] zeroinitializer, align 4
@prot_i32_obs = global [6 x i32] zeroinitializer, align 4
@ref_i64_obs = global [6 x i64] zeroinitializer, align 8
@prot_i64_obs = global [6 x i64] zeroinitializer, align 8

; i8 signed max: -20 then 5 keeps 5; then -1 leaves 5 (signed).
; i8 unsigned umin: -1 then 7 becomes 7; then 3 becomes 3.
; i16 signed min: 10 then -3 becomes -3; then 1 leaves -3.
; i16 unsigned umax: 5 then -1 becomes all-ones; then 7 leaves all-ones.
; i32 signed max: -20 then 5, then -1 seq_cst !tbaa leaves 5.
; i32 unsigned umax: 5 then -1, volatile 7 leaves all-ones.
; i64 signed min: 10 then -3, then 1 leaves -3.
; i64 unsigned umin: -1 then 7, volatile 3 becomes 3.
define void @reference() {
entry:
  store i8 -20, ptr @i8_max, align 1
  %x80 = atomicrmw max ptr @i8_max, i8 5 monotonic, align 1
  %x81 = atomicrmw volatile max ptr @i8_max, i8 -1 syncscope("singlethread") acq_rel, align 1
  %x8f = load i8, ptr @i8_max, align 1
  store i8 -1, ptr @i8_umin, align 1
  %n80 = atomicrmw umin ptr @i8_umin, i8 7 acquire, align 1
  %n81 = atomicrmw umin ptr @i8_umin, i8 3 release, align 1
  %n8f = load i8, ptr @i8_umin, align 1
  store i8 %x80, ptr getelementptr inbounds ([6 x i8], ptr @ref_i8_obs, i64 0, i64 0), align 1
  store i8 %x81, ptr getelementptr inbounds ([6 x i8], ptr @ref_i8_obs, i64 0, i64 1), align 1
  store i8 %x8f, ptr getelementptr inbounds ([6 x i8], ptr @ref_i8_obs, i64 0, i64 2), align 1
  store i8 %n80, ptr getelementptr inbounds ([6 x i8], ptr @ref_i8_obs, i64 0, i64 3), align 1
  store i8 %n81, ptr getelementptr inbounds ([6 x i8], ptr @ref_i8_obs, i64 0, i64 4), align 1
  store i8 %n8f, ptr getelementptr inbounds ([6 x i8], ptr @ref_i8_obs, i64 0, i64 5), align 1

  store i16 10, ptr @i16_min, align 2
  %m160 = atomicrmw min ptr @i16_min, i16 -3 seq_cst, align 2
  %m161 = atomicrmw min ptr @i16_min, i16 1 acquire, align 2
  %m16f = load i16, ptr @i16_min, align 2
  store i16 5, ptr @i16_umax, align 2
  %u160 = atomicrmw volatile umax ptr @i16_umax, i16 -1 syncscope("singlethread") seq_cst, align 2
  %u161 = atomicrmw umax ptr @i16_umax, i16 7 release, align 2
  %u16f = load i16, ptr @i16_umax, align 2
  store i16 %m160, ptr getelementptr inbounds ([6 x i16], ptr @ref_i16_obs, i64 0, i64 0), align 2
  store i16 %m161, ptr getelementptr inbounds ([6 x i16], ptr @ref_i16_obs, i64 0, i64 1), align 2
  store i16 %m16f, ptr getelementptr inbounds ([6 x i16], ptr @ref_i16_obs, i64 0, i64 2), align 2
  store i16 %u160, ptr getelementptr inbounds ([6 x i16], ptr @ref_i16_obs, i64 0, i64 3), align 2
  store i16 %u161, ptr getelementptr inbounds ([6 x i16], ptr @ref_i16_obs, i64 0, i64 4), align 2
  store i16 %u16f, ptr getelementptr inbounds ([6 x i16], ptr @ref_i16_obs, i64 0, i64 5), align 2

  store i32 -20, ptr @i32_max, align 4
  %x320 = atomicrmw max ptr @i32_max, i32 5 monotonic, align 4
  %x321 = atomicrmw max ptr @i32_max, i32 -1 seq_cst, align 4, !tbaa !3
  %x32f = load i32, ptr @i32_max, align 4
  store i32 5, ptr @i32_umax, align 4
  %u320 = atomicrmw umax ptr @i32_umax, i32 -1 release, align 4
  %u321 = atomicrmw volatile umax ptr @i32_umax, i32 7 syncscope("singlethread") acquire, align 4
  %u32f = load i32, ptr @i32_umax, align 4
  store i32 %x320, ptr getelementptr inbounds ([6 x i32], ptr @ref_i32_obs, i64 0, i64 0), align 4
  store i32 %x321, ptr getelementptr inbounds ([6 x i32], ptr @ref_i32_obs, i64 0, i64 1), align 4
  store i32 %x32f, ptr getelementptr inbounds ([6 x i32], ptr @ref_i32_obs, i64 0, i64 2), align 4
  store i32 %u320, ptr getelementptr inbounds ([6 x i32], ptr @ref_i32_obs, i64 0, i64 3), align 4
  store i32 %u321, ptr getelementptr inbounds ([6 x i32], ptr @ref_i32_obs, i64 0, i64 4), align 4
  store i32 %u32f, ptr getelementptr inbounds ([6 x i32], ptr @ref_i32_obs, i64 0, i64 5), align 4

  store i64 10, ptr @i64_min, align 8
  %m640 = atomicrmw min ptr @i64_min, i64 -3 acq_rel, align 8
  %m641 = atomicrmw min ptr @i64_min, i64 1 seq_cst, align 8
  %m64f = load i64, ptr @i64_min, align 8
  store i64 -1, ptr @i64_umin, align 8
  %n640 = atomicrmw umin ptr @i64_umin, i64 7 monotonic, align 8
  %n641 = atomicrmw volatile umin ptr @i64_umin, i64 3 syncscope("singlethread") release, align 8
  %n64f = load i64, ptr @i64_umin, align 8
  store i64 %m640, ptr getelementptr inbounds ([6 x i64], ptr @ref_i64_obs, i64 0, i64 0), align 8
  store i64 %m641, ptr getelementptr inbounds ([6 x i64], ptr @ref_i64_obs, i64 0, i64 1), align 8
  store i64 %m64f, ptr getelementptr inbounds ([6 x i64], ptr @ref_i64_obs, i64 0, i64 2), align 8
  store i64 %n640, ptr getelementptr inbounds ([6 x i64], ptr @ref_i64_obs, i64 0, i64 3), align 8
  store i64 %n641, ptr getelementptr inbounds ([6 x i64], ptr @ref_i64_obs, i64 0, i64 4), align 8
  store i64 %n64f, ptr getelementptr inbounds ([6 x i64], ptr @ref_i64_obs, i64 0, i64 5), align 8
  ret void
}

define void @protected() noinline optnone {
entry:
  call void @hikari_vmp()
  store i8 -20, ptr @i8_max, align 1
  %x80 = atomicrmw max ptr @i8_max, i8 5 monotonic, align 1
  %x81 = atomicrmw volatile max ptr @i8_max, i8 -1 syncscope("singlethread") acq_rel, align 1
  %x8f = load i8, ptr @i8_max, align 1
  store i8 -1, ptr @i8_umin, align 1
  %n80 = atomicrmw umin ptr @i8_umin, i8 7 acquire, align 1
  %n81 = atomicrmw umin ptr @i8_umin, i8 3 release, align 1
  %n8f = load i8, ptr @i8_umin, align 1
  store i8 %x80, ptr getelementptr inbounds ([6 x i8], ptr @prot_i8_obs, i64 0, i64 0), align 1
  store i8 %x81, ptr getelementptr inbounds ([6 x i8], ptr @prot_i8_obs, i64 0, i64 1), align 1
  store i8 %x8f, ptr getelementptr inbounds ([6 x i8], ptr @prot_i8_obs, i64 0, i64 2), align 1
  store i8 %n80, ptr getelementptr inbounds ([6 x i8], ptr @prot_i8_obs, i64 0, i64 3), align 1
  store i8 %n81, ptr getelementptr inbounds ([6 x i8], ptr @prot_i8_obs, i64 0, i64 4), align 1
  store i8 %n8f, ptr getelementptr inbounds ([6 x i8], ptr @prot_i8_obs, i64 0, i64 5), align 1

  store i16 10, ptr @i16_min, align 2
  %m160 = atomicrmw min ptr @i16_min, i16 -3 seq_cst, align 2
  %m161 = atomicrmw min ptr @i16_min, i16 1 acquire, align 2
  %m16f = load i16, ptr @i16_min, align 2
  store i16 5, ptr @i16_umax, align 2
  %u160 = atomicrmw volatile umax ptr @i16_umax, i16 -1 syncscope("singlethread") seq_cst, align 2
  %u161 = atomicrmw umax ptr @i16_umax, i16 7 release, align 2
  %u16f = load i16, ptr @i16_umax, align 2
  store i16 %m160, ptr getelementptr inbounds ([6 x i16], ptr @prot_i16_obs, i64 0, i64 0), align 2
  store i16 %m161, ptr getelementptr inbounds ([6 x i16], ptr @prot_i16_obs, i64 0, i64 1), align 2
  store i16 %m16f, ptr getelementptr inbounds ([6 x i16], ptr @prot_i16_obs, i64 0, i64 2), align 2
  store i16 %u160, ptr getelementptr inbounds ([6 x i16], ptr @prot_i16_obs, i64 0, i64 3), align 2
  store i16 %u161, ptr getelementptr inbounds ([6 x i16], ptr @prot_i16_obs, i64 0, i64 4), align 2
  store i16 %u16f, ptr getelementptr inbounds ([6 x i16], ptr @prot_i16_obs, i64 0, i64 5), align 2

  store i32 -20, ptr @i32_max, align 4
  %x320 = atomicrmw max ptr @i32_max, i32 5 monotonic, align 4
  %x321 = atomicrmw max ptr @i32_max, i32 -1 seq_cst, align 4, !tbaa !3
  %x32f = load i32, ptr @i32_max, align 4
  store i32 5, ptr @i32_umax, align 4
  %u320 = atomicrmw umax ptr @i32_umax, i32 -1 release, align 4
  %u321 = atomicrmw volatile umax ptr @i32_umax, i32 7 syncscope("singlethread") acquire, align 4
  %u32f = load i32, ptr @i32_umax, align 4
  store i32 %x320, ptr getelementptr inbounds ([6 x i32], ptr @prot_i32_obs, i64 0, i64 0), align 4
  store i32 %x321, ptr getelementptr inbounds ([6 x i32], ptr @prot_i32_obs, i64 0, i64 1), align 4
  store i32 %x32f, ptr getelementptr inbounds ([6 x i32], ptr @prot_i32_obs, i64 0, i64 2), align 4
  store i32 %u320, ptr getelementptr inbounds ([6 x i32], ptr @prot_i32_obs, i64 0, i64 3), align 4
  store i32 %u321, ptr getelementptr inbounds ([6 x i32], ptr @prot_i32_obs, i64 0, i64 4), align 4
  store i32 %u32f, ptr getelementptr inbounds ([6 x i32], ptr @prot_i32_obs, i64 0, i64 5), align 4

  store i64 10, ptr @i64_min, align 8
  %m640 = atomicrmw min ptr @i64_min, i64 -3 acq_rel, align 8
  %m641 = atomicrmw min ptr @i64_min, i64 1 seq_cst, align 8
  %m64f = load i64, ptr @i64_min, align 8
  store i64 -1, ptr @i64_umin, align 8
  %n640 = atomicrmw umin ptr @i64_umin, i64 7 monotonic, align 8
  %n641 = atomicrmw volatile umin ptr @i64_umin, i64 3 syncscope("singlethread") release, align 8
  %n64f = load i64, ptr @i64_umin, align 8
  store i64 %m640, ptr getelementptr inbounds ([6 x i64], ptr @prot_i64_obs, i64 0, i64 0), align 8
  store i64 %m641, ptr getelementptr inbounds ([6 x i64], ptr @prot_i64_obs, i64 0, i64 1), align 8
  store i64 %m64f, ptr getelementptr inbounds ([6 x i64], ptr @prot_i64_obs, i64 0, i64 2), align 8
  store i64 %n640, ptr getelementptr inbounds ([6 x i64], ptr @prot_i64_obs, i64 0, i64 3), align 8
  store i64 %n641, ptr getelementptr inbounds ([6 x i64], ptr @prot_i64_obs, i64 0, i64 4), align 8
  store i64 %n64f, ptr getelementptr inbounds ([6 x i64], ptr @prot_i64_obs, i64 0, i64 5), align 8
  ret void
}

define i128 @unsupported_i128_max() {
entry:
  call void @hikari_vmp()
  %v = atomicrmw max ptr @i128_cell, i128 1 monotonic, align 16
  ret i128 %v
}

define i128 @unsupported_i128_min() {
entry:
  call void @hikari_vmp()
  %v = atomicrmw min ptr @i128_cell, i128 1 seq_cst, align 16
  ret i128 %v
}

define i128 @unsupported_i128_umax() {
entry:
  call void @hikari_vmp()
  %v = atomicrmw umax ptr @i128_cell, i128 1 acquire, align 16
  ret i128 %v
}

define i128 @unsupported_i128_umin() {
entry:
  call void @hikari_vmp()
  %v = atomicrmw umin ptr @i128_cell, i128 1 release, align 16
  ret i128 %v
}

define i32 @unsupported_as1_max() {
entry:
  call void @hikari_vmp()
  %v = atomicrmw max ptr addrspace(1) @as1_cell, i32 1 seq_cst, align 4
  ret i32 %v
}

; Vector atomicrmw max is verifier-illegal.  A 256-bit vector return is
; parseable and still misses the 1..128-bit vector gate.
define <8 x i32> @unsupported_vector_max() {
entry:
  call void @hikari_vmp()
  ret <8 x i32> zeroinitializer
}

define i1 @eq6_i8(ptr %a, ptr %b) {
entry:
  %a0p = getelementptr inbounds [6 x i8], ptr %a, i64 0, i64 0
  %a1p = getelementptr inbounds [6 x i8], ptr %a, i64 0, i64 1
  %a2p = getelementptr inbounds [6 x i8], ptr %a, i64 0, i64 2
  %a3p = getelementptr inbounds [6 x i8], ptr %a, i64 0, i64 3
  %a4p = getelementptr inbounds [6 x i8], ptr %a, i64 0, i64 4
  %a5p = getelementptr inbounds [6 x i8], ptr %a, i64 0, i64 5
  %b0p = getelementptr inbounds [6 x i8], ptr %b, i64 0, i64 0
  %b1p = getelementptr inbounds [6 x i8], ptr %b, i64 0, i64 1
  %b2p = getelementptr inbounds [6 x i8], ptr %b, i64 0, i64 2
  %b3p = getelementptr inbounds [6 x i8], ptr %b, i64 0, i64 3
  %b4p = getelementptr inbounds [6 x i8], ptr %b, i64 0, i64 4
  %b5p = getelementptr inbounds [6 x i8], ptr %b, i64 0, i64 5
  %a0 = load i8, ptr %a0p, align 1
  %a1 = load i8, ptr %a1p, align 1
  %a2 = load i8, ptr %a2p, align 1
  %a3 = load i8, ptr %a3p, align 1
  %a4 = load i8, ptr %a4p, align 1
  %a5 = load i8, ptr %a5p, align 1
  %b0 = load i8, ptr %b0p, align 1
  %b1 = load i8, ptr %b1p, align 1
  %b2 = load i8, ptr %b2p, align 1
  %b3 = load i8, ptr %b3p, align 1
  %b4 = load i8, ptr %b4p, align 1
  %b5 = load i8, ptr %b5p, align 1
  %c0 = icmp eq i8 %a0, %b0
  %c1 = icmp eq i8 %a1, %b1
  %c2 = icmp eq i8 %a2, %b2
  %c3 = icmp eq i8 %a3, %b3
  %c4 = icmp eq i8 %a4, %b4
  %c5 = icmp eq i8 %a5, %b5
  %t0 = and i1 %c0, %c1
  %t1 = and i1 %c2, %c3
  %t2 = and i1 %c4, %c5
  %t3 = and i1 %t0, %t1
  %ok = and i1 %t3, %t2
  ret i1 %ok
}

define i1 @eq6_i16(ptr %a, ptr %b) {
entry:
  %a0p = getelementptr inbounds [6 x i16], ptr %a, i64 0, i64 0
  %a1p = getelementptr inbounds [6 x i16], ptr %a, i64 0, i64 1
  %a2p = getelementptr inbounds [6 x i16], ptr %a, i64 0, i64 2
  %a3p = getelementptr inbounds [6 x i16], ptr %a, i64 0, i64 3
  %a4p = getelementptr inbounds [6 x i16], ptr %a, i64 0, i64 4
  %a5p = getelementptr inbounds [6 x i16], ptr %a, i64 0, i64 5
  %b0p = getelementptr inbounds [6 x i16], ptr %b, i64 0, i64 0
  %b1p = getelementptr inbounds [6 x i16], ptr %b, i64 0, i64 1
  %b2p = getelementptr inbounds [6 x i16], ptr %b, i64 0, i64 2
  %b3p = getelementptr inbounds [6 x i16], ptr %b, i64 0, i64 3
  %b4p = getelementptr inbounds [6 x i16], ptr %b, i64 0, i64 4
  %b5p = getelementptr inbounds [6 x i16], ptr %b, i64 0, i64 5
  %a0 = load i16, ptr %a0p, align 2
  %a1 = load i16, ptr %a1p, align 2
  %a2 = load i16, ptr %a2p, align 2
  %a3 = load i16, ptr %a3p, align 2
  %a4 = load i16, ptr %a4p, align 2
  %a5 = load i16, ptr %a5p, align 2
  %b0 = load i16, ptr %b0p, align 2
  %b1 = load i16, ptr %b1p, align 2
  %b2 = load i16, ptr %b2p, align 2
  %b3 = load i16, ptr %b3p, align 2
  %b4 = load i16, ptr %b4p, align 2
  %b5 = load i16, ptr %b5p, align 2
  %c0 = icmp eq i16 %a0, %b0
  %c1 = icmp eq i16 %a1, %b1
  %c2 = icmp eq i16 %a2, %b2
  %c3 = icmp eq i16 %a3, %b3
  %c4 = icmp eq i16 %a4, %b4
  %c5 = icmp eq i16 %a5, %b5
  %t0 = and i1 %c0, %c1
  %t1 = and i1 %c2, %c3
  %t2 = and i1 %c4, %c5
  %t3 = and i1 %t0, %t1
  %ok = and i1 %t3, %t2
  ret i1 %ok
}

define i1 @eq6_i32(ptr %a, ptr %b) {
entry:
  %a0p = getelementptr inbounds [6 x i32], ptr %a, i64 0, i64 0
  %a1p = getelementptr inbounds [6 x i32], ptr %a, i64 0, i64 1
  %a2p = getelementptr inbounds [6 x i32], ptr %a, i64 0, i64 2
  %a3p = getelementptr inbounds [6 x i32], ptr %a, i64 0, i64 3
  %a4p = getelementptr inbounds [6 x i32], ptr %a, i64 0, i64 4
  %a5p = getelementptr inbounds [6 x i32], ptr %a, i64 0, i64 5
  %b0p = getelementptr inbounds [6 x i32], ptr %b, i64 0, i64 0
  %b1p = getelementptr inbounds [6 x i32], ptr %b, i64 0, i64 1
  %b2p = getelementptr inbounds [6 x i32], ptr %b, i64 0, i64 2
  %b3p = getelementptr inbounds [6 x i32], ptr %b, i64 0, i64 3
  %b4p = getelementptr inbounds [6 x i32], ptr %b, i64 0, i64 4
  %b5p = getelementptr inbounds [6 x i32], ptr %b, i64 0, i64 5
  %a0 = load i32, ptr %a0p, align 4
  %a1 = load i32, ptr %a1p, align 4
  %a2 = load i32, ptr %a2p, align 4
  %a3 = load i32, ptr %a3p, align 4
  %a4 = load i32, ptr %a4p, align 4
  %a5 = load i32, ptr %a5p, align 4
  %b0 = load i32, ptr %b0p, align 4
  %b1 = load i32, ptr %b1p, align 4
  %b2 = load i32, ptr %b2p, align 4
  %b3 = load i32, ptr %b3p, align 4
  %b4 = load i32, ptr %b4p, align 4
  %b5 = load i32, ptr %b5p, align 4
  %c0 = icmp eq i32 %a0, %b0
  %c1 = icmp eq i32 %a1, %b1
  %c2 = icmp eq i32 %a2, %b2
  %c3 = icmp eq i32 %a3, %b3
  %c4 = icmp eq i32 %a4, %b4
  %c5 = icmp eq i32 %a5, %b5
  %t0 = and i1 %c0, %c1
  %t1 = and i1 %c2, %c3
  %t2 = and i1 %c4, %c5
  %t3 = and i1 %t0, %t1
  %ok = and i1 %t3, %t2
  ret i1 %ok
}

define i1 @eq6_i64(ptr %a, ptr %b) {
entry:
  %a0p = getelementptr inbounds [6 x i64], ptr %a, i64 0, i64 0
  %a1p = getelementptr inbounds [6 x i64], ptr %a, i64 0, i64 1
  %a2p = getelementptr inbounds [6 x i64], ptr %a, i64 0, i64 2
  %a3p = getelementptr inbounds [6 x i64], ptr %a, i64 0, i64 3
  %a4p = getelementptr inbounds [6 x i64], ptr %a, i64 0, i64 4
  %a5p = getelementptr inbounds [6 x i64], ptr %a, i64 0, i64 5
  %b0p = getelementptr inbounds [6 x i64], ptr %b, i64 0, i64 0
  %b1p = getelementptr inbounds [6 x i64], ptr %b, i64 0, i64 1
  %b2p = getelementptr inbounds [6 x i64], ptr %b, i64 0, i64 2
  %b3p = getelementptr inbounds [6 x i64], ptr %b, i64 0, i64 3
  %b4p = getelementptr inbounds [6 x i64], ptr %b, i64 0, i64 4
  %b5p = getelementptr inbounds [6 x i64], ptr %b, i64 0, i64 5
  %a0 = load i64, ptr %a0p, align 8
  %a1 = load i64, ptr %a1p, align 8
  %a2 = load i64, ptr %a2p, align 8
  %a3 = load i64, ptr %a3p, align 8
  %a4 = load i64, ptr %a4p, align 8
  %a5 = load i64, ptr %a5p, align 8
  %b0 = load i64, ptr %b0p, align 8
  %b1 = load i64, ptr %b1p, align 8
  %b2 = load i64, ptr %b2p, align 8
  %b3 = load i64, ptr %b3p, align 8
  %b4 = load i64, ptr %b4p, align 8
  %b5 = load i64, ptr %b5p, align 8
  %c0 = icmp eq i64 %a0, %b0
  %c1 = icmp eq i64 %a1, %b1
  %c2 = icmp eq i64 %a2, %b2
  %c3 = icmp eq i64 %a3, %b3
  %c4 = icmp eq i64 %a4, %b4
  %c5 = icmp eq i64 %a5, %b5
  %t0 = and i1 %c0, %c1
  %t1 = and i1 %c2, %c3
  %t2 = and i1 %c4, %c5
  %t3 = and i1 %t0, %t1
  %ok = and i1 %t3, %t2
  ret i1 %ok
}

define i32 @main() {
entry:
  call void @reference()
  call void @protected()
  %m0 = call i1 @eq6_i8(ptr @ref_i8_obs, ptr @prot_i8_obs)
  %m1 = call i1 @eq6_i16(ptr @ref_i16_obs, ptr @prot_i16_obs)
  %m2 = call i1 @eq6_i32(ptr @ref_i32_obs, ptr @prot_i32_obs)
  %m3 = call i1 @eq6_i64(ptr @ref_i64_obs, ptr @prot_i64_obs)
  %t0 = and i1 %m0, %m1
  %t1 = and i1 %m2, %m3
  %ok = and i1 %t0, %t1
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

!0 = !{!"Simple C/C++ TBAA"}
!1 = !{!"omnipotent char", !0, i64 0}
!2 = !{!"int", !1, i64 0}
!3 = !{!2, !2, i64 0}

; SKIP-DAG: Skipping VMP on unsupported_i128_max: unsupported atomicrmw instruction
; SKIP-DAG: Skipping VMP on unsupported_i128_min: unsupported atomicrmw instruction
; SKIP-DAG: Skipping VMP on unsupported_i128_umax: unsupported atomicrmw instruction
; SKIP-DAG: Skipping VMP on unsupported_i128_umin: unsupported atomicrmw instruction
; SKIP-DAG: Skipping VMP on unsupported_as1_max: unsupported atomicrmw instruction
; SKIP-DAG: Skipping VMP on unsupported_vector_max: unsupported return type
; SKIP-NOT: Skipping VMP on protected:
; SKIP-NOT: Skipping VMP on reference:

; VIRT-LABEL: define void @protected(
; VIRT: vmp.dispatch:
; VIRT-DAG: atomicrmw max {{.*}} i8 {{.*}} monotonic, align 1
; VIRT-DAG: atomicrmw volatile max {{.*}} i8 {{.*}} syncscope("singlethread") acq_rel, align 1
; VIRT-DAG: atomicrmw umin {{.*}} i8 {{.*}} acquire, align 1
; VIRT-DAG: atomicrmw umin {{.*}} i8 {{.*}} release, align 1
; VIRT-DAG: atomicrmw min {{.*}} i16 {{.*}} seq_cst, align 2
; VIRT-DAG: atomicrmw min {{.*}} i16 {{.*}} acquire, align 2
; VIRT-DAG: atomicrmw volatile umax {{.*}} i16 {{.*}} syncscope("singlethread") seq_cst, align 2
; VIRT-DAG: atomicrmw umax {{.*}} i16 {{.*}} release, align 2
; VIRT-DAG: atomicrmw max {{.*}} i32 {{.*}} monotonic, align 4
; VIRT-DAG: atomicrmw max {{.*}} i32 {{.*}} seq_cst, align 4, !tbaa !
; VIRT-DAG: atomicrmw umax {{.*}} i32 {{.*}} release, align 4
; VIRT-DAG: atomicrmw volatile umax {{.*}} i32 {{.*}} syncscope("singlethread") acquire, align 4
; VIRT-DAG: atomicrmw min {{.*}} i64 {{.*}} acq_rel, align 8
; VIRT-DAG: atomicrmw min {{.*}} i64 {{.*}} seq_cst, align 8
; VIRT-DAG: atomicrmw umin {{.*}} i64 {{.*}} monotonic, align 8
; VIRT-DAG: atomicrmw volatile umin {{.*}} i64 {{.*}} syncscope("singlethread") release, align 8

; VIRT-LABEL: define i128 @unsupported_i128_max(
; VIRT-NOT: vmp.dispatch:
; VIRT: atomicrmw max {{.*}} i128

; VIRT-LABEL: define i128 @unsupported_i128_min(
; VIRT-NOT: vmp.dispatch:
; VIRT: atomicrmw min {{.*}} i128

; VIRT-LABEL: define i128 @unsupported_i128_umax(
; VIRT-NOT: vmp.dispatch:
; VIRT: atomicrmw umax {{.*}} i128

; VIRT-LABEL: define i128 @unsupported_i128_umin(
; VIRT-NOT: vmp.dispatch:
; VIRT: atomicrmw umin {{.*}} i128

; VIRT-LABEL: define i32 @unsupported_as1_max(
; VIRT-NOT: vmp.dispatch:
; VIRT: atomicrmw max ptr addrspace(1)

; VIRT-LABEL: define <8 x i32> @unsupported_vector_max(
; VIRT-NOT: vmp.dispatch:
; VIRT: ret <8 x i32>

; VIRT: attributes{{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; HOST: Skipping VMP: only AArch64 targets are supported
