; Focused AS0 integer atomicrmw xchg lock-in (generic IR, no new opcode).
; Production already replays native CreateAtomicRMW: result is the old
; value, the new value is stored, and ordering / syncscope / volatile /
; alignment / memory metadata are copied onto the interpreter instruction.
; This lit is integer-only (i8/i16/i32/i64).  Pointer xchg lives in
; vmp-atomicrmw-xchg-pointer-semantic.ll; f32/f64 xchg lives in
; vmp-atomicrmw-xchg-float-semantic.ll.  Do not treat add/sub/and/or/xor/
; nand/min/max/cmpxchg/fence as this family's negatives — those stay on
; the existing broader atomicrmw surface.
;
; Each width records six old values plus the final cell independently
; (no XOR mix) so a wrong width unpack or a swapped old/new cannot
; cancel out.  i32 seq_cst carries !tbaa to prove metadata replay.
;
; LLVM 15 verifier rejects unordered atomicrmw and non-byte / non-pow2
; integer payloads (i1, aggregates, vectors), so those are not skip
; sentinels.  Parseable misses: i128, half, fp128, AS1, vector return,
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

@i8_cell = global i8 0, align 1
@i16_cell = global i16 0, align 2
@i32_cell = global i32 0, align 4
@i64_cell = global i64 0, align 8
@i128_cell = global i128 0, align 16
@hcell = global half 0xH0000, align 2
@fp128_cell = global fp128 0xL00000000000000000000000000000000, align 16
@as1_cell = addrspace(1) global i32 0, align 4

@ref_i8_obs = global [7 x i8] zeroinitializer, align 1
@prot_i8_obs = global [7 x i8] zeroinitializer, align 1
@ref_i16_obs = global [7 x i16] zeroinitializer, align 2
@prot_i16_obs = global [7 x i16] zeroinitializer, align 2
@ref_i32_obs = global [7 x i32] zeroinitializer, align 4
@prot_i32_obs = global [7 x i32] zeroinitializer, align 4
@ref_i64_obs = global [7 x i64] zeroinitializer, align 8
@prot_i64_obs = global [7 x i64] zeroinitializer, align 8

; i8: 1 then xchg 2/3/4/5/6/7.  Olds 1..6, final 7.
; i16/i32/i64 use the same sequence.  i32 seq_cst keeps !tbaa.
define void @reference() {
entry:
  store i8 1, ptr @i8_cell, align 1
  %b0 = atomicrmw xchg ptr @i8_cell, i8 2 monotonic, align 1
  %b1 = atomicrmw xchg ptr @i8_cell, i8 3 acquire, align 1
  %b2 = atomicrmw xchg ptr @i8_cell, i8 4 release, align 1
  %b3 = atomicrmw xchg ptr @i8_cell, i8 5 acq_rel, align 1
  %b4 = atomicrmw xchg ptr @i8_cell, i8 6 seq_cst, align 1
  %b5 = atomicrmw volatile xchg ptr @i8_cell, i8 7 syncscope("singlethread") seq_cst, align 1
  %bf = load i8, ptr @i8_cell, align 1
  store i8 %b0, ptr getelementptr inbounds ([7 x i8], ptr @ref_i8_obs, i64 0, i64 0), align 1
  store i8 %b1, ptr getelementptr inbounds ([7 x i8], ptr @ref_i8_obs, i64 0, i64 1), align 1
  store i8 %b2, ptr getelementptr inbounds ([7 x i8], ptr @ref_i8_obs, i64 0, i64 2), align 1
  store i8 %b3, ptr getelementptr inbounds ([7 x i8], ptr @ref_i8_obs, i64 0, i64 3), align 1
  store i8 %b4, ptr getelementptr inbounds ([7 x i8], ptr @ref_i8_obs, i64 0, i64 4), align 1
  store i8 %b5, ptr getelementptr inbounds ([7 x i8], ptr @ref_i8_obs, i64 0, i64 5), align 1
  store i8 %bf, ptr getelementptr inbounds ([7 x i8], ptr @ref_i8_obs, i64 0, i64 6), align 1

  store i16 1, ptr @i16_cell, align 2
  %h0 = atomicrmw xchg ptr @i16_cell, i16 2 monotonic, align 2
  %h1 = atomicrmw xchg ptr @i16_cell, i16 3 acquire, align 2
  %h2 = atomicrmw xchg ptr @i16_cell, i16 4 release, align 2
  %h3 = atomicrmw xchg ptr @i16_cell, i16 5 acq_rel, align 2
  %h4 = atomicrmw xchg ptr @i16_cell, i16 6 seq_cst, align 2
  %h5 = atomicrmw volatile xchg ptr @i16_cell, i16 7 syncscope("singlethread") acquire, align 2
  %hf = load i16, ptr @i16_cell, align 2
  store i16 %h0, ptr getelementptr inbounds ([7 x i16], ptr @ref_i16_obs, i64 0, i64 0), align 2
  store i16 %h1, ptr getelementptr inbounds ([7 x i16], ptr @ref_i16_obs, i64 0, i64 1), align 2
  store i16 %h2, ptr getelementptr inbounds ([7 x i16], ptr @ref_i16_obs, i64 0, i64 2), align 2
  store i16 %h3, ptr getelementptr inbounds ([7 x i16], ptr @ref_i16_obs, i64 0, i64 3), align 2
  store i16 %h4, ptr getelementptr inbounds ([7 x i16], ptr @ref_i16_obs, i64 0, i64 4), align 2
  store i16 %h5, ptr getelementptr inbounds ([7 x i16], ptr @ref_i16_obs, i64 0, i64 5), align 2
  store i16 %hf, ptr getelementptr inbounds ([7 x i16], ptr @ref_i16_obs, i64 0, i64 6), align 2

  store i32 1, ptr @i32_cell, align 4
  %w0 = atomicrmw xchg ptr @i32_cell, i32 2 monotonic, align 4
  %w1 = atomicrmw xchg ptr @i32_cell, i32 3 acquire, align 4
  %w2 = atomicrmw xchg ptr @i32_cell, i32 4 release, align 4
  %w3 = atomicrmw xchg ptr @i32_cell, i32 5 acq_rel, align 4
  %w4 = atomicrmw xchg ptr @i32_cell, i32 6 seq_cst, align 4, !tbaa !3
  %w5 = atomicrmw volatile xchg ptr @i32_cell, i32 7 syncscope("singlethread") acq_rel, align 4
  %wf = load i32, ptr @i32_cell, align 4
  store i32 %w0, ptr getelementptr inbounds ([7 x i32], ptr @ref_i32_obs, i64 0, i64 0), align 4
  store i32 %w1, ptr getelementptr inbounds ([7 x i32], ptr @ref_i32_obs, i64 0, i64 1), align 4
  store i32 %w2, ptr getelementptr inbounds ([7 x i32], ptr @ref_i32_obs, i64 0, i64 2), align 4
  store i32 %w3, ptr getelementptr inbounds ([7 x i32], ptr @ref_i32_obs, i64 0, i64 3), align 4
  store i32 %w4, ptr getelementptr inbounds ([7 x i32], ptr @ref_i32_obs, i64 0, i64 4), align 4
  store i32 %w5, ptr getelementptr inbounds ([7 x i32], ptr @ref_i32_obs, i64 0, i64 5), align 4
  store i32 %wf, ptr getelementptr inbounds ([7 x i32], ptr @ref_i32_obs, i64 0, i64 6), align 4

  store i64 1, ptr @i64_cell, align 8
  %d0 = atomicrmw xchg ptr @i64_cell, i64 2 monotonic, align 8
  %d1 = atomicrmw xchg ptr @i64_cell, i64 3 acquire, align 8
  %d2 = atomicrmw xchg ptr @i64_cell, i64 4 release, align 8
  %d3 = atomicrmw xchg ptr @i64_cell, i64 5 acq_rel, align 8
  %d4 = atomicrmw xchg ptr @i64_cell, i64 6 seq_cst, align 8
  %d5 = atomicrmw volatile xchg ptr @i64_cell, i64 7 syncscope("singlethread") release, align 8
  %df = load i64, ptr @i64_cell, align 8
  store i64 %d0, ptr getelementptr inbounds ([7 x i64], ptr @ref_i64_obs, i64 0, i64 0), align 8
  store i64 %d1, ptr getelementptr inbounds ([7 x i64], ptr @ref_i64_obs, i64 0, i64 1), align 8
  store i64 %d2, ptr getelementptr inbounds ([7 x i64], ptr @ref_i64_obs, i64 0, i64 2), align 8
  store i64 %d3, ptr getelementptr inbounds ([7 x i64], ptr @ref_i64_obs, i64 0, i64 3), align 8
  store i64 %d4, ptr getelementptr inbounds ([7 x i64], ptr @ref_i64_obs, i64 0, i64 4), align 8
  store i64 %d5, ptr getelementptr inbounds ([7 x i64], ptr @ref_i64_obs, i64 0, i64 5), align 8
  store i64 %df, ptr getelementptr inbounds ([7 x i64], ptr @ref_i64_obs, i64 0, i64 6), align 8
  ret void
}

define void @protected() noinline optnone {
entry:
  call void @hikari_vmp()
  store i8 1, ptr @i8_cell, align 1
  %b0 = atomicrmw xchg ptr @i8_cell, i8 2 monotonic, align 1
  %b1 = atomicrmw xchg ptr @i8_cell, i8 3 acquire, align 1
  %b2 = atomicrmw xchg ptr @i8_cell, i8 4 release, align 1
  %b3 = atomicrmw xchg ptr @i8_cell, i8 5 acq_rel, align 1
  %b4 = atomicrmw xchg ptr @i8_cell, i8 6 seq_cst, align 1
  %b5 = atomicrmw volatile xchg ptr @i8_cell, i8 7 syncscope("singlethread") seq_cst, align 1
  %bf = load i8, ptr @i8_cell, align 1
  store i8 %b0, ptr getelementptr inbounds ([7 x i8], ptr @prot_i8_obs, i64 0, i64 0), align 1
  store i8 %b1, ptr getelementptr inbounds ([7 x i8], ptr @prot_i8_obs, i64 0, i64 1), align 1
  store i8 %b2, ptr getelementptr inbounds ([7 x i8], ptr @prot_i8_obs, i64 0, i64 2), align 1
  store i8 %b3, ptr getelementptr inbounds ([7 x i8], ptr @prot_i8_obs, i64 0, i64 3), align 1
  store i8 %b4, ptr getelementptr inbounds ([7 x i8], ptr @prot_i8_obs, i64 0, i64 4), align 1
  store i8 %b5, ptr getelementptr inbounds ([7 x i8], ptr @prot_i8_obs, i64 0, i64 5), align 1
  store i8 %bf, ptr getelementptr inbounds ([7 x i8], ptr @prot_i8_obs, i64 0, i64 6), align 1

  store i16 1, ptr @i16_cell, align 2
  %h0 = atomicrmw xchg ptr @i16_cell, i16 2 monotonic, align 2
  %h1 = atomicrmw xchg ptr @i16_cell, i16 3 acquire, align 2
  %h2 = atomicrmw xchg ptr @i16_cell, i16 4 release, align 2
  %h3 = atomicrmw xchg ptr @i16_cell, i16 5 acq_rel, align 2
  %h4 = atomicrmw xchg ptr @i16_cell, i16 6 seq_cst, align 2
  %h5 = atomicrmw volatile xchg ptr @i16_cell, i16 7 syncscope("singlethread") acquire, align 2
  %hf = load i16, ptr @i16_cell, align 2
  store i16 %h0, ptr getelementptr inbounds ([7 x i16], ptr @prot_i16_obs, i64 0, i64 0), align 2
  store i16 %h1, ptr getelementptr inbounds ([7 x i16], ptr @prot_i16_obs, i64 0, i64 1), align 2
  store i16 %h2, ptr getelementptr inbounds ([7 x i16], ptr @prot_i16_obs, i64 0, i64 2), align 2
  store i16 %h3, ptr getelementptr inbounds ([7 x i16], ptr @prot_i16_obs, i64 0, i64 3), align 2
  store i16 %h4, ptr getelementptr inbounds ([7 x i16], ptr @prot_i16_obs, i64 0, i64 4), align 2
  store i16 %h5, ptr getelementptr inbounds ([7 x i16], ptr @prot_i16_obs, i64 0, i64 5), align 2
  store i16 %hf, ptr getelementptr inbounds ([7 x i16], ptr @prot_i16_obs, i64 0, i64 6), align 2

  store i32 1, ptr @i32_cell, align 4
  %w0 = atomicrmw xchg ptr @i32_cell, i32 2 monotonic, align 4
  %w1 = atomicrmw xchg ptr @i32_cell, i32 3 acquire, align 4
  %w2 = atomicrmw xchg ptr @i32_cell, i32 4 release, align 4
  %w3 = atomicrmw xchg ptr @i32_cell, i32 5 acq_rel, align 4
  %w4 = atomicrmw xchg ptr @i32_cell, i32 6 seq_cst, align 4, !tbaa !3
  %w5 = atomicrmw volatile xchg ptr @i32_cell, i32 7 syncscope("singlethread") acq_rel, align 4
  %wf = load i32, ptr @i32_cell, align 4
  store i32 %w0, ptr getelementptr inbounds ([7 x i32], ptr @prot_i32_obs, i64 0, i64 0), align 4
  store i32 %w1, ptr getelementptr inbounds ([7 x i32], ptr @prot_i32_obs, i64 0, i64 1), align 4
  store i32 %w2, ptr getelementptr inbounds ([7 x i32], ptr @prot_i32_obs, i64 0, i64 2), align 4
  store i32 %w3, ptr getelementptr inbounds ([7 x i32], ptr @prot_i32_obs, i64 0, i64 3), align 4
  store i32 %w4, ptr getelementptr inbounds ([7 x i32], ptr @prot_i32_obs, i64 0, i64 4), align 4
  store i32 %w5, ptr getelementptr inbounds ([7 x i32], ptr @prot_i32_obs, i64 0, i64 5), align 4
  store i32 %wf, ptr getelementptr inbounds ([7 x i32], ptr @prot_i32_obs, i64 0, i64 6), align 4

  store i64 1, ptr @i64_cell, align 8
  %d0 = atomicrmw xchg ptr @i64_cell, i64 2 monotonic, align 8
  %d1 = atomicrmw xchg ptr @i64_cell, i64 3 acquire, align 8
  %d2 = atomicrmw xchg ptr @i64_cell, i64 4 release, align 8
  %d3 = atomicrmw xchg ptr @i64_cell, i64 5 acq_rel, align 8
  %d4 = atomicrmw xchg ptr @i64_cell, i64 6 seq_cst, align 8
  %d5 = atomicrmw volatile xchg ptr @i64_cell, i64 7 syncscope("singlethread") release, align 8
  %df = load i64, ptr @i64_cell, align 8
  store i64 %d0, ptr getelementptr inbounds ([7 x i64], ptr @prot_i64_obs, i64 0, i64 0), align 8
  store i64 %d1, ptr getelementptr inbounds ([7 x i64], ptr @prot_i64_obs, i64 0, i64 1), align 8
  store i64 %d2, ptr getelementptr inbounds ([7 x i64], ptr @prot_i64_obs, i64 0, i64 2), align 8
  store i64 %d3, ptr getelementptr inbounds ([7 x i64], ptr @prot_i64_obs, i64 0, i64 3), align 8
  store i64 %d4, ptr getelementptr inbounds ([7 x i64], ptr @prot_i64_obs, i64 0, i64 4), align 8
  store i64 %d5, ptr getelementptr inbounds ([7 x i64], ptr @prot_i64_obs, i64 0, i64 5), align 8
  store i64 %df, ptr getelementptr inbounds ([7 x i64], ptr @prot_i64_obs, i64 0, i64 6), align 8
  ret void
}

; i128 is verifier-legal but outside the i8/i16/i32/i64 integer gate.
define i128 @unsupported_i128_xchg() {
entry:
  call void @hikari_vmp()
  %v = atomicrmw xchg ptr @i128_cell, i128 1 monotonic, align 16
  ret i128 %v
}

; half xchg is verifier-legal; integer-family payload miss.
define void @unsupported_half_xchg() {
entry:
  call void @hikari_vmp()
  %v = atomicrmw xchg ptr @hcell, half 0xH3C00 seq_cst, align 2
  ret void
}

; fp128 xchg is verifier-legal; not f32/f64 and not integer.
define void @unsupported_fp128_xchg() {
entry:
  call void @hikari_vmp()
  %v = atomicrmw xchg ptr @fp128_cell, fp128 0xL00000000000000003FFF000000000000 seq_cst, align 16
  ret void
}

; Nonzero address space: AS1 global, supported i32 payload.
define i32 @unsupported_as1_xchg() {
entry:
  call void @hikari_vmp()
  %v = atomicrmw xchg ptr addrspace(1) @as1_cell, i32 1 seq_cst, align 4
  ret i32 %v
}

; Vector atomicrmw xchg is rejected by the LLVM 15 verifier.  A 256-bit
; vector return is parseable and still misses the 1..128-bit vector gate.
define <8 x i32> @unsupported_vector_xchg() {
entry:
  call void @hikari_vmp()
  ret <8 x i32> zeroinitializer
}

define i1 @eq7_i8(ptr %a, ptr %b) {
entry:
  %a0p = getelementptr inbounds [7 x i8], ptr %a, i64 0, i64 0
  %a1p = getelementptr inbounds [7 x i8], ptr %a, i64 0, i64 1
  %a2p = getelementptr inbounds [7 x i8], ptr %a, i64 0, i64 2
  %a3p = getelementptr inbounds [7 x i8], ptr %a, i64 0, i64 3
  %a4p = getelementptr inbounds [7 x i8], ptr %a, i64 0, i64 4
  %a5p = getelementptr inbounds [7 x i8], ptr %a, i64 0, i64 5
  %a6p = getelementptr inbounds [7 x i8], ptr %a, i64 0, i64 6
  %b0p = getelementptr inbounds [7 x i8], ptr %b, i64 0, i64 0
  %b1p = getelementptr inbounds [7 x i8], ptr %b, i64 0, i64 1
  %b2p = getelementptr inbounds [7 x i8], ptr %b, i64 0, i64 2
  %b3p = getelementptr inbounds [7 x i8], ptr %b, i64 0, i64 3
  %b4p = getelementptr inbounds [7 x i8], ptr %b, i64 0, i64 4
  %b5p = getelementptr inbounds [7 x i8], ptr %b, i64 0, i64 5
  %b6p = getelementptr inbounds [7 x i8], ptr %b, i64 0, i64 6
  %a0 = load i8, ptr %a0p, align 1
  %a1 = load i8, ptr %a1p, align 1
  %a2 = load i8, ptr %a2p, align 1
  %a3 = load i8, ptr %a3p, align 1
  %a4 = load i8, ptr %a4p, align 1
  %a5 = load i8, ptr %a5p, align 1
  %a6 = load i8, ptr %a6p, align 1
  %b0 = load i8, ptr %b0p, align 1
  %b1 = load i8, ptr %b1p, align 1
  %b2 = load i8, ptr %b2p, align 1
  %b3 = load i8, ptr %b3p, align 1
  %b4 = load i8, ptr %b4p, align 1
  %b5 = load i8, ptr %b5p, align 1
  %b6 = load i8, ptr %b6p, align 1
  %c0 = icmp eq i8 %a0, %b0
  %c1 = icmp eq i8 %a1, %b1
  %c2 = icmp eq i8 %a2, %b2
  %c3 = icmp eq i8 %a3, %b3
  %c4 = icmp eq i8 %a4, %b4
  %c5 = icmp eq i8 %a5, %b5
  %c6 = icmp eq i8 %a6, %b6
  %t0 = and i1 %c0, %c1
  %t1 = and i1 %c2, %c3
  %t2 = and i1 %c4, %c5
  %t3 = and i1 %t0, %t1
  %t4 = and i1 %t2, %c6
  %ok = and i1 %t3, %t4
  ret i1 %ok
}

define i1 @eq7_i16(ptr %a, ptr %b) {
entry:
  %a0p = getelementptr inbounds [7 x i16], ptr %a, i64 0, i64 0
  %a1p = getelementptr inbounds [7 x i16], ptr %a, i64 0, i64 1
  %a2p = getelementptr inbounds [7 x i16], ptr %a, i64 0, i64 2
  %a3p = getelementptr inbounds [7 x i16], ptr %a, i64 0, i64 3
  %a4p = getelementptr inbounds [7 x i16], ptr %a, i64 0, i64 4
  %a5p = getelementptr inbounds [7 x i16], ptr %a, i64 0, i64 5
  %a6p = getelementptr inbounds [7 x i16], ptr %a, i64 0, i64 6
  %b0p = getelementptr inbounds [7 x i16], ptr %b, i64 0, i64 0
  %b1p = getelementptr inbounds [7 x i16], ptr %b, i64 0, i64 1
  %b2p = getelementptr inbounds [7 x i16], ptr %b, i64 0, i64 2
  %b3p = getelementptr inbounds [7 x i16], ptr %b, i64 0, i64 3
  %b4p = getelementptr inbounds [7 x i16], ptr %b, i64 0, i64 4
  %b5p = getelementptr inbounds [7 x i16], ptr %b, i64 0, i64 5
  %b6p = getelementptr inbounds [7 x i16], ptr %b, i64 0, i64 6
  %a0 = load i16, ptr %a0p, align 2
  %a1 = load i16, ptr %a1p, align 2
  %a2 = load i16, ptr %a2p, align 2
  %a3 = load i16, ptr %a3p, align 2
  %a4 = load i16, ptr %a4p, align 2
  %a5 = load i16, ptr %a5p, align 2
  %a6 = load i16, ptr %a6p, align 2
  %b0 = load i16, ptr %b0p, align 2
  %b1 = load i16, ptr %b1p, align 2
  %b2 = load i16, ptr %b2p, align 2
  %b3 = load i16, ptr %b3p, align 2
  %b4 = load i16, ptr %b4p, align 2
  %b5 = load i16, ptr %b5p, align 2
  %b6 = load i16, ptr %b6p, align 2
  %c0 = icmp eq i16 %a0, %b0
  %c1 = icmp eq i16 %a1, %b1
  %c2 = icmp eq i16 %a2, %b2
  %c3 = icmp eq i16 %a3, %b3
  %c4 = icmp eq i16 %a4, %b4
  %c5 = icmp eq i16 %a5, %b5
  %c6 = icmp eq i16 %a6, %b6
  %t0 = and i1 %c0, %c1
  %t1 = and i1 %c2, %c3
  %t2 = and i1 %c4, %c5
  %t3 = and i1 %t0, %t1
  %t4 = and i1 %t2, %c6
  %ok = and i1 %t3, %t4
  ret i1 %ok
}

define i1 @eq7_i32(ptr %a, ptr %b) {
entry:
  %a0p = getelementptr inbounds [7 x i32], ptr %a, i64 0, i64 0
  %a1p = getelementptr inbounds [7 x i32], ptr %a, i64 0, i64 1
  %a2p = getelementptr inbounds [7 x i32], ptr %a, i64 0, i64 2
  %a3p = getelementptr inbounds [7 x i32], ptr %a, i64 0, i64 3
  %a4p = getelementptr inbounds [7 x i32], ptr %a, i64 0, i64 4
  %a5p = getelementptr inbounds [7 x i32], ptr %a, i64 0, i64 5
  %a6p = getelementptr inbounds [7 x i32], ptr %a, i64 0, i64 6
  %b0p = getelementptr inbounds [7 x i32], ptr %b, i64 0, i64 0
  %b1p = getelementptr inbounds [7 x i32], ptr %b, i64 0, i64 1
  %b2p = getelementptr inbounds [7 x i32], ptr %b, i64 0, i64 2
  %b3p = getelementptr inbounds [7 x i32], ptr %b, i64 0, i64 3
  %b4p = getelementptr inbounds [7 x i32], ptr %b, i64 0, i64 4
  %b5p = getelementptr inbounds [7 x i32], ptr %b, i64 0, i64 5
  %b6p = getelementptr inbounds [7 x i32], ptr %b, i64 0, i64 6
  %a0 = load i32, ptr %a0p, align 4
  %a1 = load i32, ptr %a1p, align 4
  %a2 = load i32, ptr %a2p, align 4
  %a3 = load i32, ptr %a3p, align 4
  %a4 = load i32, ptr %a4p, align 4
  %a5 = load i32, ptr %a5p, align 4
  %a6 = load i32, ptr %a6p, align 4
  %b0 = load i32, ptr %b0p, align 4
  %b1 = load i32, ptr %b1p, align 4
  %b2 = load i32, ptr %b2p, align 4
  %b3 = load i32, ptr %b3p, align 4
  %b4 = load i32, ptr %b4p, align 4
  %b5 = load i32, ptr %b5p, align 4
  %b6 = load i32, ptr %b6p, align 4
  %c0 = icmp eq i32 %a0, %b0
  %c1 = icmp eq i32 %a1, %b1
  %c2 = icmp eq i32 %a2, %b2
  %c3 = icmp eq i32 %a3, %b3
  %c4 = icmp eq i32 %a4, %b4
  %c5 = icmp eq i32 %a5, %b5
  %c6 = icmp eq i32 %a6, %b6
  %t0 = and i1 %c0, %c1
  %t1 = and i1 %c2, %c3
  %t2 = and i1 %c4, %c5
  %t3 = and i1 %t0, %t1
  %t4 = and i1 %t2, %c6
  %ok = and i1 %t3, %t4
  ret i1 %ok
}

define i1 @eq7_i64(ptr %a, ptr %b) {
entry:
  %a0p = getelementptr inbounds [7 x i64], ptr %a, i64 0, i64 0
  %a1p = getelementptr inbounds [7 x i64], ptr %a, i64 0, i64 1
  %a2p = getelementptr inbounds [7 x i64], ptr %a, i64 0, i64 2
  %a3p = getelementptr inbounds [7 x i64], ptr %a, i64 0, i64 3
  %a4p = getelementptr inbounds [7 x i64], ptr %a, i64 0, i64 4
  %a5p = getelementptr inbounds [7 x i64], ptr %a, i64 0, i64 5
  %a6p = getelementptr inbounds [7 x i64], ptr %a, i64 0, i64 6
  %b0p = getelementptr inbounds [7 x i64], ptr %b, i64 0, i64 0
  %b1p = getelementptr inbounds [7 x i64], ptr %b, i64 0, i64 1
  %b2p = getelementptr inbounds [7 x i64], ptr %b, i64 0, i64 2
  %b3p = getelementptr inbounds [7 x i64], ptr %b, i64 0, i64 3
  %b4p = getelementptr inbounds [7 x i64], ptr %b, i64 0, i64 4
  %b5p = getelementptr inbounds [7 x i64], ptr %b, i64 0, i64 5
  %b6p = getelementptr inbounds [7 x i64], ptr %b, i64 0, i64 6
  %a0 = load i64, ptr %a0p, align 8
  %a1 = load i64, ptr %a1p, align 8
  %a2 = load i64, ptr %a2p, align 8
  %a3 = load i64, ptr %a3p, align 8
  %a4 = load i64, ptr %a4p, align 8
  %a5 = load i64, ptr %a5p, align 8
  %a6 = load i64, ptr %a6p, align 8
  %b0 = load i64, ptr %b0p, align 8
  %b1 = load i64, ptr %b1p, align 8
  %b2 = load i64, ptr %b2p, align 8
  %b3 = load i64, ptr %b3p, align 8
  %b4 = load i64, ptr %b4p, align 8
  %b5 = load i64, ptr %b5p, align 8
  %b6 = load i64, ptr %b6p, align 8
  %c0 = icmp eq i64 %a0, %b0
  %c1 = icmp eq i64 %a1, %b1
  %c2 = icmp eq i64 %a2, %b2
  %c3 = icmp eq i64 %a3, %b3
  %c4 = icmp eq i64 %a4, %b4
  %c5 = icmp eq i64 %a5, %b5
  %c6 = icmp eq i64 %a6, %b6
  %t0 = and i1 %c0, %c1
  %t1 = and i1 %c2, %c3
  %t2 = and i1 %c4, %c5
  %t3 = and i1 %t0, %t1
  %t4 = and i1 %t2, %c6
  %ok = and i1 %t3, %t4
  ret i1 %ok
}

define i32 @main() {
entry:
  call void @reference()
  call void @protected()
  %m0 = call i1 @eq7_i8(ptr @ref_i8_obs, ptr @prot_i8_obs)
  %m1 = call i1 @eq7_i16(ptr @ref_i16_obs, ptr @prot_i16_obs)
  %m2 = call i1 @eq7_i32(ptr @ref_i32_obs, ptr @prot_i32_obs)
  %m3 = call i1 @eq7_i64(ptr @ref_i64_obs, ptr @prot_i64_obs)
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

; SKIP-DAG: Skipping VMP on unsupported_i128_xchg: unsupported atomicrmw instruction
; SKIP-DAG: Skipping VMP on unsupported_half_xchg: unsupported atomicrmw instruction
; SKIP-DAG: Skipping VMP on unsupported_fp128_xchg: unsupported atomicrmw instruction
; SKIP-DAG: Skipping VMP on unsupported_as1_xchg: unsupported atomicrmw instruction
; SKIP-DAG: Skipping VMP on unsupported_vector_xchg: unsupported return type
; SKIP-NOT: Skipping VMP on protected:
; SKIP-NOT: Skipping VMP on reference:

; VIRT-LABEL: define void @protected(
; VIRT: vmp.dispatch:
; VIRT-DAG: atomicrmw xchg {{.*}} i8 {{.*}} monotonic, align 1
; VIRT-DAG: atomicrmw xchg {{.*}} i8 {{.*}} acquire, align 1
; VIRT-DAG: atomicrmw xchg {{.*}} i8 {{.*}} release, align 1
; VIRT-DAG: atomicrmw xchg {{.*}} i8 {{.*}} acq_rel, align 1
; VIRT-DAG: atomicrmw xchg {{.*}} i8 {{.*}} seq_cst, align 1
; VIRT-DAG: atomicrmw volatile xchg {{.*}} i8 {{.*}} syncscope("singlethread") seq_cst, align 1
; VIRT-DAG: atomicrmw xchg {{.*}} i16 {{.*}} monotonic, align 2
; VIRT-DAG: atomicrmw xchg {{.*}} i16 {{.*}} acquire, align 2
; VIRT-DAG: atomicrmw xchg {{.*}} i16 {{.*}} release, align 2
; VIRT-DAG: atomicrmw xchg {{.*}} i16 {{.*}} acq_rel, align 2
; VIRT-DAG: atomicrmw xchg {{.*}} i16 {{.*}} seq_cst, align 2
; VIRT-DAG: atomicrmw volatile xchg {{.*}} i16 {{.*}} syncscope("singlethread") acquire, align 2
; VIRT-DAG: atomicrmw xchg {{.*}} i32 {{.*}} monotonic, align 4
; VIRT-DAG: atomicrmw xchg {{.*}} i32 {{.*}} acquire, align 4
; VIRT-DAG: atomicrmw xchg {{.*}} i32 {{.*}} release, align 4
; VIRT-DAG: atomicrmw xchg {{.*}} i32 {{.*}} acq_rel, align 4
; VIRT-DAG: atomicrmw xchg {{.*}} i32 {{.*}} seq_cst, align 4, !tbaa !
; VIRT-DAG: atomicrmw volatile xchg {{.*}} i32 {{.*}} syncscope("singlethread") acq_rel, align 4
; VIRT-DAG: atomicrmw xchg {{.*}} i64 {{.*}} monotonic, align 8
; VIRT-DAG: atomicrmw xchg {{.*}} i64 {{.*}} acquire, align 8
; VIRT-DAG: atomicrmw xchg {{.*}} i64 {{.*}} release, align 8
; VIRT-DAG: atomicrmw xchg {{.*}} i64 {{.*}} acq_rel, align 8
; VIRT-DAG: atomicrmw xchg {{.*}} i64 {{.*}} seq_cst, align 8
; VIRT-DAG: atomicrmw volatile xchg {{.*}} i64 {{.*}} syncscope("singlethread") release, align 8

; VIRT-LABEL: define i128 @unsupported_i128_xchg(
; VIRT-NOT: vmp.dispatch:
; VIRT: atomicrmw xchg {{.*}} i128

; VIRT-LABEL: define void @unsupported_half_xchg(
; VIRT-NOT: vmp.dispatch:
; VIRT: atomicrmw xchg {{.*}} half

; VIRT-LABEL: define void @unsupported_fp128_xchg(
; VIRT-NOT: vmp.dispatch:
; VIRT: atomicrmw xchg {{.*}} fp128

; VIRT-LABEL: define i32 @unsupported_as1_xchg(
; VIRT-NOT: vmp.dispatch:
; VIRT: atomicrmw xchg ptr addrspace(1)

; VIRT-LABEL: define <8 x i32> @unsupported_vector_xchg(
; VIRT-NOT: vmp.dispatch:
; VIRT: ret <8 x i32>

; VIRT: attributes{{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; HOST: Skipping VMP: only AArch64 targets are supported
