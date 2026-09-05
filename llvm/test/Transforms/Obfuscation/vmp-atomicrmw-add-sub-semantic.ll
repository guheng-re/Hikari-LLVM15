; Focused AS0 integer atomicrmw add/sub lock-in (generic IR, no new opcode).
; Production already replays native CreateAtomicRMW: result is the old
; value, the cell becomes old+/-delta with two's-complement wrap (same
; bits for signed and unsigned), and ordering / syncscope / volatile /
; alignment / memory metadata are copied onto the interpreter instruction.
; Integer-only i8/i16/i32/i64.  Do not treat and/or/xor/nand/min/max,
; fadd/fsub, xchg, cmpxchg, or fence as this family's negatives — those
; stay on the existing broader atomicrmw surface.
; Pointer/float add are LLVM 15 verifier-illegal (non-xchg RMW must be
; integer).  unordered and i1/vector/aggregate add/sub are also illegal.
;
; Each width records add olds+final and sub olds+final independently
; (no XOR mix) so a wrong-width unpack or swapped old/new cannot cancel.
; Sequences include wrap (0xff+1, 0-1, 0x7fffffff+1 via i32 -1+1).
; i32 seq_cst add carries !tbaa to prove metadata replay.
;
; Parseable misses: i128 add/sub, AS1 add, 256-bit vector return,
; non-AArch64 module triple.
;
; Pipeline:
;   O0/O2 x aesSeed 97/7: opt → SKIP → VIRT → internalize main →
;   AArch64 llc/readobj → host lli.  Source-triple swap is HOST.
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

@i8_add = global i8 0, align 1
@i8_sub = global i8 0, align 1
@i16_add = global i16 0, align 2
@i16_sub = global i16 0, align 2
@i32_add = global i32 0, align 4
@i32_sub = global i32 0, align 4
@i64_add = global i64 0, align 8
@i64_sub = global i64 0, align 8
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

; i8 add: 200+56 wraps to 0, then +1 → 1.  Olds 200,0 final 1.
; i8 sub: 5-6 wraps to 255, then volatile -1 → 254.  Olds 5,255 final 254.
; i16 add: 65535+2 wraps to 1, then +3 → 4.
; i16 sub: 0-1 wraps to 65535, then -1 → 65534.
; i32 add: -1+1 → 0, +1 seq_cst !tbaa → 1.
; i32 sub: 0-1 → -1, volatile -1 → -2.
; i64 add: -1+1 acq_rel → 0, volatile +2 → 2.
; i64 sub: 0-1 → -1, -1 seq_cst → -2.
define void @reference() {
entry:
  store i8 200, ptr @i8_add, align 1
  %a80 = atomicrmw add ptr @i8_add, i8 56 monotonic, align 1
  %a81 = atomicrmw add ptr @i8_add, i8 1 acquire, align 1
  %a8f = load i8, ptr @i8_add, align 1
  store i8 5, ptr @i8_sub, align 1
  %s80 = atomicrmw sub ptr @i8_sub, i8 6 release, align 1
  %s81 = atomicrmw volatile sub ptr @i8_sub, i8 1 syncscope("singlethread") acq_rel, align 1
  %s8f = load i8, ptr @i8_sub, align 1
  store i8 %a80, ptr getelementptr inbounds ([6 x i8], ptr @ref_i8_obs, i64 0, i64 0), align 1
  store i8 %a81, ptr getelementptr inbounds ([6 x i8], ptr @ref_i8_obs, i64 0, i64 1), align 1
  store i8 %a8f, ptr getelementptr inbounds ([6 x i8], ptr @ref_i8_obs, i64 0, i64 2), align 1
  store i8 %s80, ptr getelementptr inbounds ([6 x i8], ptr @ref_i8_obs, i64 0, i64 3), align 1
  store i8 %s81, ptr getelementptr inbounds ([6 x i8], ptr @ref_i8_obs, i64 0, i64 4), align 1
  store i8 %s8f, ptr getelementptr inbounds ([6 x i8], ptr @ref_i8_obs, i64 0, i64 5), align 1

  store i16 65535, ptr @i16_add, align 2
  %a160 = atomicrmw add ptr @i16_add, i16 2 seq_cst, align 2
  %a161 = atomicrmw add ptr @i16_add, i16 3 acquire, align 2
  %a16f = load i16, ptr @i16_add, align 2
  store i16 0, ptr @i16_sub, align 2
  %s160 = atomicrmw volatile sub ptr @i16_sub, i16 1 syncscope("singlethread") seq_cst, align 2
  %s161 = atomicrmw sub ptr @i16_sub, i16 1 release, align 2
  %s16f = load i16, ptr @i16_sub, align 2
  store i16 %a160, ptr getelementptr inbounds ([6 x i16], ptr @ref_i16_obs, i64 0, i64 0), align 2
  store i16 %a161, ptr getelementptr inbounds ([6 x i16], ptr @ref_i16_obs, i64 0, i64 1), align 2
  store i16 %a16f, ptr getelementptr inbounds ([6 x i16], ptr @ref_i16_obs, i64 0, i64 2), align 2
  store i16 %s160, ptr getelementptr inbounds ([6 x i16], ptr @ref_i16_obs, i64 0, i64 3), align 2
  store i16 %s161, ptr getelementptr inbounds ([6 x i16], ptr @ref_i16_obs, i64 0, i64 4), align 2
  store i16 %s16f, ptr getelementptr inbounds ([6 x i16], ptr @ref_i16_obs, i64 0, i64 5), align 2

  store i32 -1, ptr @i32_add, align 4
  %a320 = atomicrmw add ptr @i32_add, i32 1 monotonic, align 4
  %a321 = atomicrmw add ptr @i32_add, i32 1 seq_cst, align 4, !tbaa !3
  %a32f = load i32, ptr @i32_add, align 4
  store i32 0, ptr @i32_sub, align 4
  %s320 = atomicrmw sub ptr @i32_sub, i32 1 release, align 4
  %s321 = atomicrmw volatile sub ptr @i32_sub, i32 1 syncscope("singlethread") acquire, align 4
  %s32f = load i32, ptr @i32_sub, align 4
  store i32 %a320, ptr getelementptr inbounds ([6 x i32], ptr @ref_i32_obs, i64 0, i64 0), align 4
  store i32 %a321, ptr getelementptr inbounds ([6 x i32], ptr @ref_i32_obs, i64 0, i64 1), align 4
  store i32 %a32f, ptr getelementptr inbounds ([6 x i32], ptr @ref_i32_obs, i64 0, i64 2), align 4
  store i32 %s320, ptr getelementptr inbounds ([6 x i32], ptr @ref_i32_obs, i64 0, i64 3), align 4
  store i32 %s321, ptr getelementptr inbounds ([6 x i32], ptr @ref_i32_obs, i64 0, i64 4), align 4
  store i32 %s32f, ptr getelementptr inbounds ([6 x i32], ptr @ref_i32_obs, i64 0, i64 5), align 4

  store i64 -1, ptr @i64_add, align 8
  %a640 = atomicrmw add ptr @i64_add, i64 1 acq_rel, align 8
  %a641 = atomicrmw volatile add ptr @i64_add, i64 2 syncscope("singlethread") release, align 8
  %a64f = load i64, ptr @i64_add, align 8
  store i64 0, ptr @i64_sub, align 8
  %s640 = atomicrmw sub ptr @i64_sub, i64 1 monotonic, align 8
  %s641 = atomicrmw sub ptr @i64_sub, i64 1 seq_cst, align 8
  %s64f = load i64, ptr @i64_sub, align 8
  store i64 %a640, ptr getelementptr inbounds ([6 x i64], ptr @ref_i64_obs, i64 0, i64 0), align 8
  store i64 %a641, ptr getelementptr inbounds ([6 x i64], ptr @ref_i64_obs, i64 0, i64 1), align 8
  store i64 %a64f, ptr getelementptr inbounds ([6 x i64], ptr @ref_i64_obs, i64 0, i64 2), align 8
  store i64 %s640, ptr getelementptr inbounds ([6 x i64], ptr @ref_i64_obs, i64 0, i64 3), align 8
  store i64 %s641, ptr getelementptr inbounds ([6 x i64], ptr @ref_i64_obs, i64 0, i64 4), align 8
  store i64 %s64f, ptr getelementptr inbounds ([6 x i64], ptr @ref_i64_obs, i64 0, i64 5), align 8
  ret void
}

define void @protected() noinline optnone {
entry:
  call void @hikari_vmp()
  store i8 200, ptr @i8_add, align 1
  %a80 = atomicrmw add ptr @i8_add, i8 56 monotonic, align 1
  %a81 = atomicrmw add ptr @i8_add, i8 1 acquire, align 1
  %a8f = load i8, ptr @i8_add, align 1
  store i8 5, ptr @i8_sub, align 1
  %s80 = atomicrmw sub ptr @i8_sub, i8 6 release, align 1
  %s81 = atomicrmw volatile sub ptr @i8_sub, i8 1 syncscope("singlethread") acq_rel, align 1
  %s8f = load i8, ptr @i8_sub, align 1
  store i8 %a80, ptr getelementptr inbounds ([6 x i8], ptr @prot_i8_obs, i64 0, i64 0), align 1
  store i8 %a81, ptr getelementptr inbounds ([6 x i8], ptr @prot_i8_obs, i64 0, i64 1), align 1
  store i8 %a8f, ptr getelementptr inbounds ([6 x i8], ptr @prot_i8_obs, i64 0, i64 2), align 1
  store i8 %s80, ptr getelementptr inbounds ([6 x i8], ptr @prot_i8_obs, i64 0, i64 3), align 1
  store i8 %s81, ptr getelementptr inbounds ([6 x i8], ptr @prot_i8_obs, i64 0, i64 4), align 1
  store i8 %s8f, ptr getelementptr inbounds ([6 x i8], ptr @prot_i8_obs, i64 0, i64 5), align 1

  store i16 65535, ptr @i16_add, align 2
  %a160 = atomicrmw add ptr @i16_add, i16 2 seq_cst, align 2
  %a161 = atomicrmw add ptr @i16_add, i16 3 acquire, align 2
  %a16f = load i16, ptr @i16_add, align 2
  store i16 0, ptr @i16_sub, align 2
  %s160 = atomicrmw volatile sub ptr @i16_sub, i16 1 syncscope("singlethread") seq_cst, align 2
  %s161 = atomicrmw sub ptr @i16_sub, i16 1 release, align 2
  %s16f = load i16, ptr @i16_sub, align 2
  store i16 %a160, ptr getelementptr inbounds ([6 x i16], ptr @prot_i16_obs, i64 0, i64 0), align 2
  store i16 %a161, ptr getelementptr inbounds ([6 x i16], ptr @prot_i16_obs, i64 0, i64 1), align 2
  store i16 %a16f, ptr getelementptr inbounds ([6 x i16], ptr @prot_i16_obs, i64 0, i64 2), align 2
  store i16 %s160, ptr getelementptr inbounds ([6 x i16], ptr @prot_i16_obs, i64 0, i64 3), align 2
  store i16 %s161, ptr getelementptr inbounds ([6 x i16], ptr @prot_i16_obs, i64 0, i64 4), align 2
  store i16 %s16f, ptr getelementptr inbounds ([6 x i16], ptr @prot_i16_obs, i64 0, i64 5), align 2

  store i32 -1, ptr @i32_add, align 4
  %a320 = atomicrmw add ptr @i32_add, i32 1 monotonic, align 4
  %a321 = atomicrmw add ptr @i32_add, i32 1 seq_cst, align 4, !tbaa !3
  %a32f = load i32, ptr @i32_add, align 4
  store i32 0, ptr @i32_sub, align 4
  %s320 = atomicrmw sub ptr @i32_sub, i32 1 release, align 4
  %s321 = atomicrmw volatile sub ptr @i32_sub, i32 1 syncscope("singlethread") acquire, align 4
  %s32f = load i32, ptr @i32_sub, align 4
  store i32 %a320, ptr getelementptr inbounds ([6 x i32], ptr @prot_i32_obs, i64 0, i64 0), align 4
  store i32 %a321, ptr getelementptr inbounds ([6 x i32], ptr @prot_i32_obs, i64 0, i64 1), align 4
  store i32 %a32f, ptr getelementptr inbounds ([6 x i32], ptr @prot_i32_obs, i64 0, i64 2), align 4
  store i32 %s320, ptr getelementptr inbounds ([6 x i32], ptr @prot_i32_obs, i64 0, i64 3), align 4
  store i32 %s321, ptr getelementptr inbounds ([6 x i32], ptr @prot_i32_obs, i64 0, i64 4), align 4
  store i32 %s32f, ptr getelementptr inbounds ([6 x i32], ptr @prot_i32_obs, i64 0, i64 5), align 4

  store i64 -1, ptr @i64_add, align 8
  %a640 = atomicrmw add ptr @i64_add, i64 1 acq_rel, align 8
  %a641 = atomicrmw volatile add ptr @i64_add, i64 2 syncscope("singlethread") release, align 8
  %a64f = load i64, ptr @i64_add, align 8
  store i64 0, ptr @i64_sub, align 8
  %s640 = atomicrmw sub ptr @i64_sub, i64 1 monotonic, align 8
  %s641 = atomicrmw sub ptr @i64_sub, i64 1 seq_cst, align 8
  %s64f = load i64, ptr @i64_sub, align 8
  store i64 %a640, ptr getelementptr inbounds ([6 x i64], ptr @prot_i64_obs, i64 0, i64 0), align 8
  store i64 %a641, ptr getelementptr inbounds ([6 x i64], ptr @prot_i64_obs, i64 0, i64 1), align 8
  store i64 %a64f, ptr getelementptr inbounds ([6 x i64], ptr @prot_i64_obs, i64 0, i64 2), align 8
  store i64 %s640, ptr getelementptr inbounds ([6 x i64], ptr @prot_i64_obs, i64 0, i64 3), align 8
  store i64 %s641, ptr getelementptr inbounds ([6 x i64], ptr @prot_i64_obs, i64 0, i64 4), align 8
  store i64 %s64f, ptr getelementptr inbounds ([6 x i64], ptr @prot_i64_obs, i64 0, i64 5), align 8
  ret void
}

define i128 @unsupported_i128_add() {
entry:
  call void @hikari_vmp()
  %v = atomicrmw add ptr @i128_cell, i128 1 monotonic, align 16
  ret i128 %v
}

define i128 @unsupported_i128_sub() {
entry:
  call void @hikari_vmp()
  %v = atomicrmw sub ptr @i128_cell, i128 1 seq_cst, align 16
  ret i128 %v
}

define i32 @unsupported_as1_add() {
entry:
  call void @hikari_vmp()
  %v = atomicrmw add ptr addrspace(1) @as1_cell, i32 1 seq_cst, align 4
  ret i32 %v
}

; Vector atomicrmw add is verifier-illegal.  A 256-bit vector return is
; parseable and still misses the 1..128-bit vector gate.
define <8 x i32> @unsupported_vector_add() {
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

; SKIP-DAG: Skipping VMP on unsupported_i128_add: unsupported atomicrmw instruction
; SKIP-DAG: Skipping VMP on unsupported_i128_sub: unsupported atomicrmw instruction
; SKIP-DAG: Skipping VMP on unsupported_as1_add: unsupported atomicrmw instruction
; SKIP-DAG: Skipping VMP on unsupported_vector_add: unsupported return type
; SKIP-NOT: Skipping VMP on protected:
; SKIP-NOT: Skipping VMP on reference:

; VIRT-LABEL: define void @protected(
; VIRT: vmp.dispatch:
; VIRT-DAG: atomicrmw add {{.*}} i8 {{.*}} monotonic, align 1
; VIRT-DAG: atomicrmw add {{.*}} i8 {{.*}} acquire, align 1
; VIRT-DAG: atomicrmw sub {{.*}} i8 {{.*}} release, align 1
; VIRT-DAG: atomicrmw volatile sub {{.*}} i8 {{.*}} syncscope("singlethread") acq_rel, align 1
; VIRT-DAG: atomicrmw add {{.*}} i16 {{.*}} seq_cst, align 2
; VIRT-DAG: atomicrmw add {{.*}} i16 {{.*}} acquire, align 2
; VIRT-DAG: atomicrmw volatile sub {{.*}} i16 {{.*}} syncscope("singlethread") seq_cst, align 2
; VIRT-DAG: atomicrmw sub {{.*}} i16 {{.*}} release, align 2
; VIRT-DAG: atomicrmw add {{.*}} i32 {{.*}} monotonic, align 4
; VIRT-DAG: atomicrmw add {{.*}} i32 {{.*}} seq_cst, align 4, !tbaa !
; VIRT-DAG: atomicrmw sub {{.*}} i32 {{.*}} release, align 4
; VIRT-DAG: atomicrmw volatile sub {{.*}} i32 {{.*}} syncscope("singlethread") acquire, align 4
; VIRT-DAG: atomicrmw add {{.*}} i64 {{.*}} acq_rel, align 8
; VIRT-DAG: atomicrmw volatile add {{.*}} i64 {{.*}} syncscope("singlethread") release, align 8
; VIRT-DAG: atomicrmw sub {{.*}} i64 {{.*}} monotonic, align 8
; VIRT-DAG: atomicrmw sub {{.*}} i64 {{.*}} seq_cst, align 8

; VIRT-LABEL: define i128 @unsupported_i128_add(
; VIRT-NOT: vmp.dispatch:
; VIRT: atomicrmw add {{.*}} i128

; VIRT-LABEL: define i128 @unsupported_i128_sub(
; VIRT-NOT: vmp.dispatch:
; VIRT: atomicrmw sub {{.*}} i128

; VIRT-LABEL: define i32 @unsupported_as1_add(
; VIRT-NOT: vmp.dispatch:
; VIRT: atomicrmw add ptr addrspace(1)

; VIRT-LABEL: define <8 x i32> @unsupported_vector_add(
; VIRT-NOT: vmp.dispatch:
; VIRT: ret <8 x i32>

; VIRT: attributes{{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; HOST: Skipping VMP: only AArch64 targets are supported
