; Focused AS0 integer cmpxchg lock-in (generic IR, no new opcode).
; Production already replays native CreateAtomicCmpXchg: no load/icmp/store
; lowering and no aggregate VReg.  extractvalue 0 is the old value,
; extractvalue 1 is i1 success; weak/strong, success/failure orderings,
; syncscope, volatile, alignment, and memory metadata are copied.
; Integer-only i8/i16/i32/i64.  AS0 pointer cmpxchg stays on
; vmp-cmpxchg-semantic.ll.  Do not treat atomicrmw or fence as this
; family's negatives.
;
; Each width records one success and one failure independently (old,
; zext(ok), cell; no XOR mix).  i32 success carries !tbaa.  LLVM 15
; failure orderings are monotonic/acquire/seq_cst only; release as
; failure is parseable here and must stay skipped.
;
; Parseable misses: i128, AS1, returning the {ty,i1} pair, 256-bit
; vector return, non-AArch64.  LLVM 15 rejects unordered/release/
; acq_rel failure orderings at parse time, so those are not skip
; sentinels.  Rejected i128 bodies stay out of host lli: AArch64
; transform,
; internalize/globaldce to main, then substitute only the live triple.
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

@i8_cell = global i8 0, align 1
@i16_cell = global i16 0, align 2
@i32_cell = global i32 0, align 4
@i64_cell = global i64 0, align 8
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

; i8 weak: 5→7 success acquire/monotonic, then expected 0 fails.
; i16: 100→200 success mon/mon, then expected 1 fails.
; i32: 10→20 success seq_cst/seq_cst !tbaa, then volatile expected 0
;      fails seq_cst/acquire.
; i64: 1→2 success singlethread acq_rel/monotonic, then expected 0
;      fails seq_cst/seq_cst.
define void @reference() {
entry:
  store i8 5, ptr @i8_cell, align 1
  %p8s = cmpxchg weak ptr @i8_cell, i8 5, i8 7 acquire monotonic, align 1
  %o8s = extractvalue { i8, i1 } %p8s, 0
  %k8s = extractvalue { i8, i1 } %p8s, 1
  %c8s = load i8, ptr @i8_cell, align 1
  %p8f = cmpxchg weak ptr @i8_cell, i8 0, i8 9 acquire monotonic, align 1
  %o8f = extractvalue { i8, i1 } %p8f, 0
  %k8f = extractvalue { i8, i1 } %p8f, 1
  %c8f = load i8, ptr @i8_cell, align 1
  %z8s = zext i1 %k8s to i8
  %z8f = zext i1 %k8f to i8
  store i8 %o8s, ptr getelementptr inbounds ([6 x i8], ptr @ref_i8_obs, i64 0, i64 0), align 1
  store i8 %z8s, ptr getelementptr inbounds ([6 x i8], ptr @ref_i8_obs, i64 0, i64 1), align 1
  store i8 %c8s, ptr getelementptr inbounds ([6 x i8], ptr @ref_i8_obs, i64 0, i64 2), align 1
  store i8 %o8f, ptr getelementptr inbounds ([6 x i8], ptr @ref_i8_obs, i64 0, i64 3), align 1
  store i8 %z8f, ptr getelementptr inbounds ([6 x i8], ptr @ref_i8_obs, i64 0, i64 4), align 1
  store i8 %c8f, ptr getelementptr inbounds ([6 x i8], ptr @ref_i8_obs, i64 0, i64 5), align 1

  store i16 100, ptr @i16_cell, align 2
  %p16s = cmpxchg ptr @i16_cell, i16 100, i16 200 monotonic monotonic, align 2
  %o16s = extractvalue { i16, i1 } %p16s, 0
  %k16s = extractvalue { i16, i1 } %p16s, 1
  %c16s = load i16, ptr @i16_cell, align 2
  %p16f = cmpxchg ptr @i16_cell, i16 1, i16 3 monotonic monotonic, align 2
  %o16f = extractvalue { i16, i1 } %p16f, 0
  %k16f = extractvalue { i16, i1 } %p16f, 1
  %c16f = load i16, ptr @i16_cell, align 2
  %z16s = zext i1 %k16s to i16
  %z16f = zext i1 %k16f to i16
  store i16 %o16s, ptr getelementptr inbounds ([6 x i16], ptr @ref_i16_obs, i64 0, i64 0), align 2
  store i16 %z16s, ptr getelementptr inbounds ([6 x i16], ptr @ref_i16_obs, i64 0, i64 1), align 2
  store i16 %c16s, ptr getelementptr inbounds ([6 x i16], ptr @ref_i16_obs, i64 0, i64 2), align 2
  store i16 %o16f, ptr getelementptr inbounds ([6 x i16], ptr @ref_i16_obs, i64 0, i64 3), align 2
  store i16 %z16f, ptr getelementptr inbounds ([6 x i16], ptr @ref_i16_obs, i64 0, i64 4), align 2
  store i16 %c16f, ptr getelementptr inbounds ([6 x i16], ptr @ref_i16_obs, i64 0, i64 5), align 2

  store i32 10, ptr @i32_cell, align 4
  %p32s = cmpxchg ptr @i32_cell, i32 10, i32 20 seq_cst seq_cst, align 4, !tbaa !3
  %o32s = extractvalue { i32, i1 } %p32s, 0
  %k32s = extractvalue { i32, i1 } %p32s, 1
  %c32s = load i32, ptr @i32_cell, align 4
  %p32f = cmpxchg volatile ptr @i32_cell, i32 0, i32 30 seq_cst acquire, align 4
  %o32f = extractvalue { i32, i1 } %p32f, 0
  %k32f = extractvalue { i32, i1 } %p32f, 1
  %c32f = load i32, ptr @i32_cell, align 4
  %z32s = zext i1 %k32s to i32
  %z32f = zext i1 %k32f to i32
  store i32 %o32s, ptr getelementptr inbounds ([6 x i32], ptr @ref_i32_obs, i64 0, i64 0), align 4
  store i32 %z32s, ptr getelementptr inbounds ([6 x i32], ptr @ref_i32_obs, i64 0, i64 1), align 4
  store i32 %c32s, ptr getelementptr inbounds ([6 x i32], ptr @ref_i32_obs, i64 0, i64 2), align 4
  store i32 %o32f, ptr getelementptr inbounds ([6 x i32], ptr @ref_i32_obs, i64 0, i64 3), align 4
  store i32 %z32f, ptr getelementptr inbounds ([6 x i32], ptr @ref_i32_obs, i64 0, i64 4), align 4
  store i32 %c32f, ptr getelementptr inbounds ([6 x i32], ptr @ref_i32_obs, i64 0, i64 5), align 4

  store i64 1, ptr @i64_cell, align 8
  %p64s = cmpxchg ptr @i64_cell, i64 1, i64 2 syncscope("singlethread") acq_rel monotonic, align 8
  %o64s = extractvalue { i64, i1 } %p64s, 0
  %k64s = extractvalue { i64, i1 } %p64s, 1
  %c64s = load i64, ptr @i64_cell, align 8
  %p64f = cmpxchg ptr @i64_cell, i64 0, i64 3 seq_cst seq_cst, align 8
  %o64f = extractvalue { i64, i1 } %p64f, 0
  %k64f = extractvalue { i64, i1 } %p64f, 1
  %c64f = load i64, ptr @i64_cell, align 8
  %z64s = zext i1 %k64s to i64
  %z64f = zext i1 %k64f to i64
  store i64 %o64s, ptr getelementptr inbounds ([6 x i64], ptr @ref_i64_obs, i64 0, i64 0), align 8
  store i64 %z64s, ptr getelementptr inbounds ([6 x i64], ptr @ref_i64_obs, i64 0, i64 1), align 8
  store i64 %c64s, ptr getelementptr inbounds ([6 x i64], ptr @ref_i64_obs, i64 0, i64 2), align 8
  store i64 %o64f, ptr getelementptr inbounds ([6 x i64], ptr @ref_i64_obs, i64 0, i64 3), align 8
  store i64 %z64f, ptr getelementptr inbounds ([6 x i64], ptr @ref_i64_obs, i64 0, i64 4), align 8
  store i64 %c64f, ptr getelementptr inbounds ([6 x i64], ptr @ref_i64_obs, i64 0, i64 5), align 8
  ret void
}

define void @protected() noinline optnone {
entry:
  call void @hikari_vmp()
  store i8 5, ptr @i8_cell, align 1
  %p8s = cmpxchg weak ptr @i8_cell, i8 5, i8 7 acquire monotonic, align 1
  %o8s = extractvalue { i8, i1 } %p8s, 0
  %k8s = extractvalue { i8, i1 } %p8s, 1
  %c8s = load i8, ptr @i8_cell, align 1
  %p8f = cmpxchg weak ptr @i8_cell, i8 0, i8 9 acquire monotonic, align 1
  %o8f = extractvalue { i8, i1 } %p8f, 0
  %k8f = extractvalue { i8, i1 } %p8f, 1
  %c8f = load i8, ptr @i8_cell, align 1
  %z8s = zext i1 %k8s to i8
  %z8f = zext i1 %k8f to i8
  store i8 %o8s, ptr getelementptr inbounds ([6 x i8], ptr @prot_i8_obs, i64 0, i64 0), align 1
  store i8 %z8s, ptr getelementptr inbounds ([6 x i8], ptr @prot_i8_obs, i64 0, i64 1), align 1
  store i8 %c8s, ptr getelementptr inbounds ([6 x i8], ptr @prot_i8_obs, i64 0, i64 2), align 1
  store i8 %o8f, ptr getelementptr inbounds ([6 x i8], ptr @prot_i8_obs, i64 0, i64 3), align 1
  store i8 %z8f, ptr getelementptr inbounds ([6 x i8], ptr @prot_i8_obs, i64 0, i64 4), align 1
  store i8 %c8f, ptr getelementptr inbounds ([6 x i8], ptr @prot_i8_obs, i64 0, i64 5), align 1

  store i16 100, ptr @i16_cell, align 2
  %p16s = cmpxchg ptr @i16_cell, i16 100, i16 200 monotonic monotonic, align 2
  %o16s = extractvalue { i16, i1 } %p16s, 0
  %k16s = extractvalue { i16, i1 } %p16s, 1
  %c16s = load i16, ptr @i16_cell, align 2
  %p16f = cmpxchg ptr @i16_cell, i16 1, i16 3 monotonic monotonic, align 2
  %o16f = extractvalue { i16, i1 } %p16f, 0
  %k16f = extractvalue { i16, i1 } %p16f, 1
  %c16f = load i16, ptr @i16_cell, align 2
  %z16s = zext i1 %k16s to i16
  %z16f = zext i1 %k16f to i16
  store i16 %o16s, ptr getelementptr inbounds ([6 x i16], ptr @prot_i16_obs, i64 0, i64 0), align 2
  store i16 %z16s, ptr getelementptr inbounds ([6 x i16], ptr @prot_i16_obs, i64 0, i64 1), align 2
  store i16 %c16s, ptr getelementptr inbounds ([6 x i16], ptr @prot_i16_obs, i64 0, i64 2), align 2
  store i16 %o16f, ptr getelementptr inbounds ([6 x i16], ptr @prot_i16_obs, i64 0, i64 3), align 2
  store i16 %z16f, ptr getelementptr inbounds ([6 x i16], ptr @prot_i16_obs, i64 0, i64 4), align 2
  store i16 %c16f, ptr getelementptr inbounds ([6 x i16], ptr @prot_i16_obs, i64 0, i64 5), align 2

  store i32 10, ptr @i32_cell, align 4
  %p32s = cmpxchg ptr @i32_cell, i32 10, i32 20 seq_cst seq_cst, align 4, !tbaa !3
  %o32s = extractvalue { i32, i1 } %p32s, 0
  %k32s = extractvalue { i32, i1 } %p32s, 1
  %c32s = load i32, ptr @i32_cell, align 4
  %p32f = cmpxchg volatile ptr @i32_cell, i32 0, i32 30 seq_cst acquire, align 4
  %o32f = extractvalue { i32, i1 } %p32f, 0
  %k32f = extractvalue { i32, i1 } %p32f, 1
  %c32f = load i32, ptr @i32_cell, align 4
  %z32s = zext i1 %k32s to i32
  %z32f = zext i1 %k32f to i32
  store i32 %o32s, ptr getelementptr inbounds ([6 x i32], ptr @prot_i32_obs, i64 0, i64 0), align 4
  store i32 %z32s, ptr getelementptr inbounds ([6 x i32], ptr @prot_i32_obs, i64 0, i64 1), align 4
  store i32 %c32s, ptr getelementptr inbounds ([6 x i32], ptr @prot_i32_obs, i64 0, i64 2), align 4
  store i32 %o32f, ptr getelementptr inbounds ([6 x i32], ptr @prot_i32_obs, i64 0, i64 3), align 4
  store i32 %z32f, ptr getelementptr inbounds ([6 x i32], ptr @prot_i32_obs, i64 0, i64 4), align 4
  store i32 %c32f, ptr getelementptr inbounds ([6 x i32], ptr @prot_i32_obs, i64 0, i64 5), align 4

  store i64 1, ptr @i64_cell, align 8
  %p64s = cmpxchg ptr @i64_cell, i64 1, i64 2 syncscope("singlethread") acq_rel monotonic, align 8
  %o64s = extractvalue { i64, i1 } %p64s, 0
  %k64s = extractvalue { i64, i1 } %p64s, 1
  %c64s = load i64, ptr @i64_cell, align 8
  %p64f = cmpxchg ptr @i64_cell, i64 0, i64 3 seq_cst seq_cst, align 8
  %o64f = extractvalue { i64, i1 } %p64f, 0
  %k64f = extractvalue { i64, i1 } %p64f, 1
  %c64f = load i64, ptr @i64_cell, align 8
  %z64s = zext i1 %k64s to i64
  %z64f = zext i1 %k64f to i64
  store i64 %o64s, ptr getelementptr inbounds ([6 x i64], ptr @prot_i64_obs, i64 0, i64 0), align 8
  store i64 %z64s, ptr getelementptr inbounds ([6 x i64], ptr @prot_i64_obs, i64 0, i64 1), align 8
  store i64 %c64s, ptr getelementptr inbounds ([6 x i64], ptr @prot_i64_obs, i64 0, i64 2), align 8
  store i64 %o64f, ptr getelementptr inbounds ([6 x i64], ptr @prot_i64_obs, i64 0, i64 3), align 8
  store i64 %z64f, ptr getelementptr inbounds ([6 x i64], ptr @prot_i64_obs, i64 0, i64 4), align 8
  store i64 %c64f, ptr getelementptr inbounds ([6 x i64], ptr @prot_i64_obs, i64 0, i64 5), align 8
  ret void
}

define i128 @unsupported_i128_cmpxchg() {
entry:
  call void @hikari_vmp()
  %p = cmpxchg ptr @i128_cell, i128 0, i128 1 monotonic monotonic, align 16
  %v = extractvalue { i128, i1 } %p, 0
  ret i128 %v
}

define i32 @unsupported_as1_cmpxchg() {
entry:
  call void @hikari_vmp()
  %p = cmpxchg ptr addrspace(1) @as1_cell, i32 0, i32 1 seq_cst seq_cst, align 4
  %v = extractvalue { i32, i1 } %p, 0
  ret i32 %v
}

; Returning the {ty,i1} pair uses the aggregate, not extractvalue.
define { i32, i1 } @unsupported_aggregate_cmpxchg() {
entry:
  call void @hikari_vmp()
  %p = cmpxchg ptr @i32_cell, i32 0, i32 1 monotonic monotonic, align 4
  ret { i32, i1 } %p
}

define <8 x i32> @unsupported_vector_cmpxchg() {
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

; SKIP-DAG: Skipping VMP on unsupported_i128_cmpxchg: unsupported cmpxchg instruction
; SKIP-DAG: Skipping VMP on unsupported_as1_cmpxchg: unsupported cmpxchg instruction
; SKIP-DAG: Skipping VMP on unsupported_aggregate_cmpxchg: unsupported cmpxchg instruction
; SKIP-DAG: Skipping VMP on unsupported_vector_cmpxchg: unsupported return type
; SKIP-NOT: Skipping VMP on protected:
; SKIP-NOT: Skipping VMP on reference:

; VIRT-LABEL: define void @protected(
; VIRT: vmp.dispatch:
; VIRT-DAG: cmpxchg weak {{.*}} i8 {{.*}} acquire monotonic, align 1
; VIRT-DAG: cmpxchg {{.*}} i16 {{.*}} monotonic monotonic, align 2
; VIRT-DAG: cmpxchg {{.*}} i32 {{.*}} seq_cst seq_cst, align 4, !tbaa !
; VIRT-DAG: cmpxchg volatile {{.*}} i32 {{.*}} seq_cst acquire, align 4
; VIRT-DAG: cmpxchg {{.*}} i64 {{.*}} syncscope("singlethread") acq_rel monotonic, align 8
; VIRT-DAG: cmpxchg {{.*}} i64 {{.*}} seq_cst seq_cst, align 8
; VIRT-DAG: extractvalue {{.*}}, 0
; VIRT-DAG: extractvalue {{.*}}, 1

; VIRT-LABEL: define i128 @unsupported_i128_cmpxchg(
; VIRT-NOT: vmp.dispatch:
; VIRT: cmpxchg {{.*}} i128

; VIRT-LABEL: define i32 @unsupported_as1_cmpxchg(
; VIRT-NOT: vmp.dispatch:
; VIRT: cmpxchg ptr addrspace(1)

; VIRT-LABEL: define { i32, i1 } @unsupported_aggregate_cmpxchg(
; VIRT-NOT: vmp.dispatch:
; VIRT: cmpxchg {{.*}} i32

; VIRT-LABEL: define <8 x i32> @unsupported_vector_cmpxchg(
; VIRT-NOT: vmp.dispatch:
; VIRT: ret <8 x i32>

; VIRT: attributes{{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; HOST: Skipping VMP: only AArch64 targets are supported
