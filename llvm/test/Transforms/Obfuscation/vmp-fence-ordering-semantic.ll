; Focused LLVM 15 FenceInst lock-in (generic IR, no new opcode).
; Production already replays native CreateFence with the source
; ordering and syncscope.  Fences are side-effecting; the interpreter
; must re-emit them, not delete or lower them to nothing.  LLVM 15
; verifier permits only acquire / release / acq_rel / seq_cst
; (monotonic and unordered are illegal IR, not skip sentinels).
; Do not treat atomicrmw / cmpxchg as this family's negatives.
;
; FileCheck locks each legal ordering and singlethread syncscope on
; the re-emitted fences.  Sequential host lli only checks the
; surrounding integer payload (a fence is a no-op in-order).
;
; Parseable misses: musttail (control-flow), 256-bit vector return,
; non-AArch64.  Pipeline: AArch64 transform, internalize/globaldce
; to main, AArch64 llc/readobj, then only the live triple is swapped
; for host lli.
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
declare i32 @sink_i32(i32)

@cell = global i32 0, align 4
@ref_obs = global [2 x i32] zeroinitializer, align 4
@prot_obs = global [2 x i32] zeroinitializer, align 4

; Payload: store 7 release, fence acquire, load, fence release,
; store a+1 monotonic, fence seq_cst, load, fence acq_rel,
; fence singlethread acquire, fence singlethread seq_cst.
define void @reference() {
entry:
  store atomic i32 7, ptr @cell release, align 4
  fence acquire
  %a = load atomic i32, ptr @cell acquire, align 4
  fence release
  %inc = add i32 %a, 1
  store atomic i32 %inc, ptr @cell monotonic, align 4
  fence seq_cst
  %b = load atomic i32, ptr @cell seq_cst, align 4
  fence acq_rel
  fence syncscope("singlethread") acquire
  fence syncscope("singlethread") seq_cst
  store i32 %a, ptr getelementptr inbounds ([2 x i32], ptr @ref_obs, i64 0, i64 0), align 4
  store i32 %b, ptr getelementptr inbounds ([2 x i32], ptr @ref_obs, i64 0, i64 1), align 4
  ret void
}

define void @protected() noinline optnone {
entry:
  call void @hikari_vmp()
  store atomic i32 7, ptr @cell release, align 4
  fence acquire
  %a = load atomic i32, ptr @cell acquire, align 4
  fence release
  %inc = add i32 %a, 1
  store atomic i32 %inc, ptr @cell monotonic, align 4
  fence seq_cst
  %b = load atomic i32, ptr @cell seq_cst, align 4
  fence acq_rel
  fence syncscope("singlethread") acquire
  fence syncscope("singlethread") seq_cst
  store i32 %a, ptr getelementptr inbounds ([2 x i32], ptr @prot_obs, i64 0, i64 0), align 4
  store i32 %b, ptr getelementptr inbounds ([2 x i32], ptr @prot_obs, i64 0, i64 1), align 4
  ret void
}

define i32 @unsupported_musttail(i32 %x) {
entry:
  call void @hikari_vmp()
  %r = musttail call i32 @sink_i32(i32 %x)
  ret i32 %r
}

define <8 x i32> @unsupported_vector_fence() {
entry:
  call void @hikari_vmp()
  ret <8 x i32> zeroinitializer
}

define i32 @main() {
entry:
  store i32 0, ptr @cell, align 4
  call void @reference()
  store i32 0, ptr @cell, align 4
  call void @protected()
  %r0 = load i32, ptr getelementptr inbounds ([2 x i32], ptr @ref_obs, i64 0, i64 0), align 4
  %r1 = load i32, ptr getelementptr inbounds ([2 x i32], ptr @ref_obs, i64 0, i64 1), align 4
  %p0 = load i32, ptr getelementptr inbounds ([2 x i32], ptr @prot_obs, i64 0, i64 0), align 4
  %p1 = load i32, ptr getelementptr inbounds ([2 x i32], ptr @prot_obs, i64 0, i64 1), align 4
  %c0 = icmp eq i32 %r0, %p0
  %c1 = icmp eq i32 %r1, %p1
  %ok = and i1 %c0, %c1
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_vector_fence: unsupported return type
; SKIP-NOT: Skipping VMP on protected:
; SKIP-NOT: Skipping VMP on reference:

; VIRT-LABEL: define void @protected(
; VIRT: vmp.dispatch:
; VIRT-DAG: fence acquire
; VIRT-DAG: fence release
; VIRT-DAG: fence seq_cst
; VIRT-DAG: fence acq_rel
; VIRT-DAG: fence syncscope("singlethread") acquire
; VIRT-DAG: fence syncscope("singlethread") seq_cst
; VIRT-DAG: store atomic i32 {{.*}} release
; VIRT-DAG: load atomic i32,{{.*}} acquire
; VIRT-DAG: store atomic i32 {{.*}} monotonic
; VIRT-DAG: load atomic i32,{{.*}} seq_cst

; VIRT-LABEL: define i32 @unsupported_musttail(
; VIRT-NOT: vmp.dispatch:
; VIRT: musttail call

; VIRT-LABEL: define <8 x i32> @unsupported_vector_fence(
; VIRT-NOT: vmp.dispatch:
; VIRT: ret <8 x i32>

; VIRT: attributes{{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; HOST: Skipping VMP: only AArch64 targets are supported
