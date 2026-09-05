; Focused AS0 integer atomicrmw and/or/xor lock-in (generic IR, no new
; opcode).  Production already replays native CreateAtomicRMW: result is
; the old value, the cell becomes old&mask / old|bits / old^bits, and
; ordering / syncscope / volatile / alignment / memory metadata are
; copied onto the interpreter instruction.  Integer-only i8/i16/i32/i64.
; Do not treat nand/min/max, fadd/fsub, xchg, add/sub, cmpxchg, or fence
; as this family's negatives — those stay on the existing broader
; atomicrmw surface.  Pointer/float and/or/xor are LLVM 15
; verifier-illegal (non-xchg RMW must be integer).  unordered and
; i1/vector/aggregate bitwise RMW are also illegal.
;
; Each width records independent olds+finals (no XOR mix) so a wrong
; width unpack, swapped old/new, or and/or/xor mix-up cannot cancel.
; i32 seq_cst or carries !tbaa to prove metadata replay.
;
; Parseable misses: i128 and/or/xor, AS1 and, 256-bit vector return,
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

@i8_and = global i8 0, align 1
@i8_or = global i8 0, align 1
@i16_xor = global i16 0, align 2
@i16_and = global i16 0, align 2
@i32_or = global i32 0, align 4
@i32_and = global i32 0, align 4
@i64_xor = global i64 0, align 8
@i64_or = global i64 0, align 8
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

; i8 and: 0xff & 0x0f → 0x0f, & 0x33 → 0x03.  Olds 255,15 final 3.
; i8 or:  0x10 | 0x01 → 0x11, volatile | 0x02 → 0x13.  Olds 16,17 final 19.
; i16 xor: 0xaaaa ^ 0xffff → 0x5555, ^ 0x5555 → 0.
; i16 and: 0xf0f0 & 0xff00 → 0xf000.
; i32 or: 0 | 1 → 1, | 2 seq_cst !tbaa → 3.
; i32 and: -1 & 255 → 255, volatile & 15 → 15.
; i64 xor: -1 ^ 1 → -2, volatile ^ 1 → -1.
; i64 or:  0 | 4 → 4, | 8 → 12.
define void @reference() {
entry:
  store i8 255, ptr @i8_and, align 1
  %a80 = atomicrmw and ptr @i8_and, i8 15 monotonic, align 1
  %a81 = atomicrmw and ptr @i8_and, i8 51 acquire, align 1
  %a8f = load i8, ptr @i8_and, align 1
  store i8 16, ptr @i8_or, align 1
  %o80 = atomicrmw or ptr @i8_or, i8 1 release, align 1
  %o81 = atomicrmw volatile or ptr @i8_or, i8 2 syncscope("singlethread") acq_rel, align 1
  %o8f = load i8, ptr @i8_or, align 1
  store i8 %a80, ptr getelementptr inbounds ([6 x i8], ptr @ref_i8_obs, i64 0, i64 0), align 1
  store i8 %a81, ptr getelementptr inbounds ([6 x i8], ptr @ref_i8_obs, i64 0, i64 1), align 1
  store i8 %a8f, ptr getelementptr inbounds ([6 x i8], ptr @ref_i8_obs, i64 0, i64 2), align 1
  store i8 %o80, ptr getelementptr inbounds ([6 x i8], ptr @ref_i8_obs, i64 0, i64 3), align 1
  store i8 %o81, ptr getelementptr inbounds ([6 x i8], ptr @ref_i8_obs, i64 0, i64 4), align 1
  store i8 %o8f, ptr getelementptr inbounds ([6 x i8], ptr @ref_i8_obs, i64 0, i64 5), align 1

  store i16 43690, ptr @i16_xor, align 2
  %x160 = atomicrmw xor ptr @i16_xor, i16 65535 seq_cst, align 2
  %x161 = atomicrmw xor ptr @i16_xor, i16 21845 acquire, align 2
  %x16f = load i16, ptr @i16_xor, align 2
  store i16 61680, ptr @i16_and, align 2
  %a160 = atomicrmw volatile and ptr @i16_and, i16 65280 syncscope("singlethread") seq_cst, align 2
  %a16f = load i16, ptr @i16_and, align 2
  store i16 %x160, ptr getelementptr inbounds ([6 x i16], ptr @ref_i16_obs, i64 0, i64 0), align 2
  store i16 %x161, ptr getelementptr inbounds ([6 x i16], ptr @ref_i16_obs, i64 0, i64 1), align 2
  store i16 %x16f, ptr getelementptr inbounds ([6 x i16], ptr @ref_i16_obs, i64 0, i64 2), align 2
  store i16 %a160, ptr getelementptr inbounds ([6 x i16], ptr @ref_i16_obs, i64 0, i64 3), align 2
  store i16 %a16f, ptr getelementptr inbounds ([6 x i16], ptr @ref_i16_obs, i64 0, i64 4), align 2

  store i32 0, ptr @i32_or, align 4
  %o320 = atomicrmw or ptr @i32_or, i32 1 monotonic, align 4
  %o321 = atomicrmw or ptr @i32_or, i32 2 seq_cst, align 4, !tbaa !3
  %o32f = load i32, ptr @i32_or, align 4
  store i32 -1, ptr @i32_and, align 4
  %a320 = atomicrmw and ptr @i32_and, i32 255 release, align 4
  %a321 = atomicrmw volatile and ptr @i32_and, i32 15 syncscope("singlethread") acquire, align 4
  %a32f = load i32, ptr @i32_and, align 4
  store i32 %o320, ptr getelementptr inbounds ([6 x i32], ptr @ref_i32_obs, i64 0, i64 0), align 4
  store i32 %o321, ptr getelementptr inbounds ([6 x i32], ptr @ref_i32_obs, i64 0, i64 1), align 4
  store i32 %o32f, ptr getelementptr inbounds ([6 x i32], ptr @ref_i32_obs, i64 0, i64 2), align 4
  store i32 %a320, ptr getelementptr inbounds ([6 x i32], ptr @ref_i32_obs, i64 0, i64 3), align 4
  store i32 %a321, ptr getelementptr inbounds ([6 x i32], ptr @ref_i32_obs, i64 0, i64 4), align 4
  store i32 %a32f, ptr getelementptr inbounds ([6 x i32], ptr @ref_i32_obs, i64 0, i64 5), align 4

  store i64 -1, ptr @i64_xor, align 8
  %x640 = atomicrmw xor ptr @i64_xor, i64 1 acq_rel, align 8
  %x641 = atomicrmw volatile xor ptr @i64_xor, i64 1 syncscope("singlethread") release, align 8
  %x64f = load i64, ptr @i64_xor, align 8
  store i64 0, ptr @i64_or, align 8
  %o640 = atomicrmw or ptr @i64_or, i64 4 monotonic, align 8
  %o641 = atomicrmw or ptr @i64_or, i64 8 seq_cst, align 8
  %o64f = load i64, ptr @i64_or, align 8
  store i64 %x640, ptr getelementptr inbounds ([6 x i64], ptr @ref_i64_obs, i64 0, i64 0), align 8
  store i64 %x641, ptr getelementptr inbounds ([6 x i64], ptr @ref_i64_obs, i64 0, i64 1), align 8
  store i64 %x64f, ptr getelementptr inbounds ([6 x i64], ptr @ref_i64_obs, i64 0, i64 2), align 8
  store i64 %o640, ptr getelementptr inbounds ([6 x i64], ptr @ref_i64_obs, i64 0, i64 3), align 8
  store i64 %o641, ptr getelementptr inbounds ([6 x i64], ptr @ref_i64_obs, i64 0, i64 4), align 8
  store i64 %o64f, ptr getelementptr inbounds ([6 x i64], ptr @ref_i64_obs, i64 0, i64 5), align 8
  ret void
}

define void @protected() noinline optnone {
entry:
  call void @hikari_vmp()
  store i8 255, ptr @i8_and, align 1
  %a80 = atomicrmw and ptr @i8_and, i8 15 monotonic, align 1
  %a81 = atomicrmw and ptr @i8_and, i8 51 acquire, align 1
  %a8f = load i8, ptr @i8_and, align 1
  store i8 16, ptr @i8_or, align 1
  %o80 = atomicrmw or ptr @i8_or, i8 1 release, align 1
  %o81 = atomicrmw volatile or ptr @i8_or, i8 2 syncscope("singlethread") acq_rel, align 1
  %o8f = load i8, ptr @i8_or, align 1
  store i8 %a80, ptr getelementptr inbounds ([6 x i8], ptr @prot_i8_obs, i64 0, i64 0), align 1
  store i8 %a81, ptr getelementptr inbounds ([6 x i8], ptr @prot_i8_obs, i64 0, i64 1), align 1
  store i8 %a8f, ptr getelementptr inbounds ([6 x i8], ptr @prot_i8_obs, i64 0, i64 2), align 1
  store i8 %o80, ptr getelementptr inbounds ([6 x i8], ptr @prot_i8_obs, i64 0, i64 3), align 1
  store i8 %o81, ptr getelementptr inbounds ([6 x i8], ptr @prot_i8_obs, i64 0, i64 4), align 1
  store i8 %o8f, ptr getelementptr inbounds ([6 x i8], ptr @prot_i8_obs, i64 0, i64 5), align 1

  store i16 43690, ptr @i16_xor, align 2
  %x160 = atomicrmw xor ptr @i16_xor, i16 65535 seq_cst, align 2
  %x161 = atomicrmw xor ptr @i16_xor, i16 21845 acquire, align 2
  %x16f = load i16, ptr @i16_xor, align 2
  store i16 61680, ptr @i16_and, align 2
  %a160 = atomicrmw volatile and ptr @i16_and, i16 65280 syncscope("singlethread") seq_cst, align 2
  %a16f = load i16, ptr @i16_and, align 2
  store i16 %x160, ptr getelementptr inbounds ([6 x i16], ptr @prot_i16_obs, i64 0, i64 0), align 2
  store i16 %x161, ptr getelementptr inbounds ([6 x i16], ptr @prot_i16_obs, i64 0, i64 1), align 2
  store i16 %x16f, ptr getelementptr inbounds ([6 x i16], ptr @prot_i16_obs, i64 0, i64 2), align 2
  store i16 %a160, ptr getelementptr inbounds ([6 x i16], ptr @prot_i16_obs, i64 0, i64 3), align 2
  store i16 %a16f, ptr getelementptr inbounds ([6 x i16], ptr @prot_i16_obs, i64 0, i64 4), align 2

  store i32 0, ptr @i32_or, align 4
  %o320 = atomicrmw or ptr @i32_or, i32 1 monotonic, align 4
  %o321 = atomicrmw or ptr @i32_or, i32 2 seq_cst, align 4, !tbaa !3
  %o32f = load i32, ptr @i32_or, align 4
  store i32 -1, ptr @i32_and, align 4
  %a320 = atomicrmw and ptr @i32_and, i32 255 release, align 4
  %a321 = atomicrmw volatile and ptr @i32_and, i32 15 syncscope("singlethread") acquire, align 4
  %a32f = load i32, ptr @i32_and, align 4
  store i32 %o320, ptr getelementptr inbounds ([6 x i32], ptr @prot_i32_obs, i64 0, i64 0), align 4
  store i32 %o321, ptr getelementptr inbounds ([6 x i32], ptr @prot_i32_obs, i64 0, i64 1), align 4
  store i32 %o32f, ptr getelementptr inbounds ([6 x i32], ptr @prot_i32_obs, i64 0, i64 2), align 4
  store i32 %a320, ptr getelementptr inbounds ([6 x i32], ptr @prot_i32_obs, i64 0, i64 3), align 4
  store i32 %a321, ptr getelementptr inbounds ([6 x i32], ptr @prot_i32_obs, i64 0, i64 4), align 4
  store i32 %a32f, ptr getelementptr inbounds ([6 x i32], ptr @prot_i32_obs, i64 0, i64 5), align 4

  store i64 -1, ptr @i64_xor, align 8
  %x640 = atomicrmw xor ptr @i64_xor, i64 1 acq_rel, align 8
  %x641 = atomicrmw volatile xor ptr @i64_xor, i64 1 syncscope("singlethread") release, align 8
  %x64f = load i64, ptr @i64_xor, align 8
  store i64 0, ptr @i64_or, align 8
  %o640 = atomicrmw or ptr @i64_or, i64 4 monotonic, align 8
  %o641 = atomicrmw or ptr @i64_or, i64 8 seq_cst, align 8
  %o64f = load i64, ptr @i64_or, align 8
  store i64 %x640, ptr getelementptr inbounds ([6 x i64], ptr @prot_i64_obs, i64 0, i64 0), align 8
  store i64 %x641, ptr getelementptr inbounds ([6 x i64], ptr @prot_i64_obs, i64 0, i64 1), align 8
  store i64 %x64f, ptr getelementptr inbounds ([6 x i64], ptr @prot_i64_obs, i64 0, i64 2), align 8
  store i64 %o640, ptr getelementptr inbounds ([6 x i64], ptr @prot_i64_obs, i64 0, i64 3), align 8
  store i64 %o641, ptr getelementptr inbounds ([6 x i64], ptr @prot_i64_obs, i64 0, i64 4), align 8
  store i64 %o64f, ptr getelementptr inbounds ([6 x i64], ptr @prot_i64_obs, i64 0, i64 5), align 8
  ret void
}

define i128 @unsupported_i128_and() {
entry:
  call void @hikari_vmp()
  %v = atomicrmw and ptr @i128_cell, i128 1 monotonic, align 16
  ret i128 %v
}

define i128 @unsupported_i128_or() {
entry:
  call void @hikari_vmp()
  %v = atomicrmw or ptr @i128_cell, i128 1 seq_cst, align 16
  ret i128 %v
}

define i128 @unsupported_i128_xor() {
entry:
  call void @hikari_vmp()
  %v = atomicrmw xor ptr @i128_cell, i128 1 acquire, align 16
  ret i128 %v
}

define i32 @unsupported_as1_and() {
entry:
  call void @hikari_vmp()
  %v = atomicrmw and ptr addrspace(1) @as1_cell, i32 1 seq_cst, align 4
  ret i32 %v
}

; Vector atomicrmw and is verifier-illegal.  A 256-bit vector return is
; parseable and still misses the 1..128-bit vector gate.
define <8 x i32> @unsupported_vector_and() {
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

; SKIP-DAG: Skipping VMP on unsupported_i128_and: unsupported atomicrmw instruction
; SKIP-DAG: Skipping VMP on unsupported_i128_or: unsupported atomicrmw instruction
; SKIP-DAG: Skipping VMP on unsupported_i128_xor: unsupported atomicrmw instruction
; SKIP-DAG: Skipping VMP on unsupported_as1_and: unsupported atomicrmw instruction
; SKIP-DAG: Skipping VMP on unsupported_vector_and: unsupported return type
; SKIP-NOT: Skipping VMP on protected:
; SKIP-NOT: Skipping VMP on reference:

; VIRT-LABEL: define void @protected(
; VIRT: vmp.dispatch:
; VIRT-DAG: atomicrmw and {{.*}} i8 {{.*}} monotonic, align 1
; VIRT-DAG: atomicrmw and {{.*}} i8 {{.*}} acquire, align 1
; VIRT-DAG: atomicrmw or {{.*}} i8 {{.*}} release, align 1
; VIRT-DAG: atomicrmw volatile or {{.*}} i8 {{.*}} syncscope("singlethread") acq_rel, align 1
; VIRT-DAG: atomicrmw xor {{.*}} i16 {{.*}} seq_cst, align 2
; VIRT-DAG: atomicrmw xor {{.*}} i16 {{.*}} acquire, align 2
; VIRT-DAG: atomicrmw volatile and {{.*}} i16 {{.*}} syncscope("singlethread") seq_cst, align 2
; VIRT-DAG: atomicrmw or {{.*}} i32 {{.*}} monotonic, align 4
; VIRT-DAG: atomicrmw or {{.*}} i32 {{.*}} seq_cst, align 4, !tbaa !
; VIRT-DAG: atomicrmw and {{.*}} i32 {{.*}} release, align 4
; VIRT-DAG: atomicrmw volatile and {{.*}} i32 {{.*}} syncscope("singlethread") acquire, align 4
; VIRT-DAG: atomicrmw xor {{.*}} i64 {{.*}} acq_rel, align 8
; VIRT-DAG: atomicrmw volatile xor {{.*}} i64 {{.*}} syncscope("singlethread") release, align 8
; VIRT-DAG: atomicrmw or {{.*}} i64 {{.*}} monotonic, align 8
; VIRT-DAG: atomicrmw or {{.*}} i64 {{.*}} seq_cst, align 8

; VIRT-LABEL: define i128 @unsupported_i128_and(
; VIRT-NOT: vmp.dispatch:
; VIRT: atomicrmw and {{.*}} i128

; VIRT-LABEL: define i128 @unsupported_i128_or(
; VIRT-NOT: vmp.dispatch:
; VIRT: atomicrmw or {{.*}} i128

; VIRT-LABEL: define i128 @unsupported_i128_xor(
; VIRT-NOT: vmp.dispatch:
; VIRT: atomicrmw xor {{.*}} i128

; VIRT-LABEL: define i32 @unsupported_as1_and(
; VIRT-NOT: vmp.dispatch:
; VIRT: atomicrmw and ptr addrspace(1)

; VIRT-LABEL: define <8 x i32> @unsupported_vector_and(
; VIRT-NOT: vmp.dispatch:
; VIRT: ret <8 x i32>

; VIRT: attributes{{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; HOST: Skipping VMP: only AArch64 targets are supported
