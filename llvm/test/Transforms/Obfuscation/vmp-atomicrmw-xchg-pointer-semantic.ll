; AS0-pointer atomicrmw xchg under VMP (semantic regression).
; reference/* run natively, vmp/* are virtualized.  Both run the same xchg
; sequence against @ptr_cell and fold the returned old pointers plus the
; post-swap memory values into an i64 checksum; main compares them, proving
; the interpreter returns the pre-swap pointer and leaves the new pointer in
; memory.  VIRT keeps the exact monotonic / seq_cst / volatile
; syncscope("singlethread") acquire attributes on the re-emitted atomicrmw.
; Negative coverage: nonzero-AS pointer xchg and a non-AArch64 module triple
; (VMP skips all selected functions wholesale).  A non-xchg pointer atomicrmw
; cannot exist in LLVM 15 IR — the verifier requires integer/float operands
; for every non-xchg operation — so nothing needs constructing for that case.
; O0 carries the detailed VIRT checks; O2 re-checks eligibility/stability.
;
; RUN: opt -S -verify-each -aesSeed=91 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.ll -o %t.o0.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=91 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP-O2 < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT-O2 < %t.o2.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.ll -o %t.o2.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: opt -S -verify-each -aesSeed=91 -mtriple=x86_64-unknown-linux-gnu -passes='default<O0>' %s -o %t.x86.ll 2>%t.x86.err
; RUN: FileCheck %s --check-prefix=SKIP-X86 < %t.x86.err

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()

@ptr_cell = global ptr null, align 8
@obj_a = global i32 1, align 4
@obj_b = global i32 2, align 4
@obj_c = global i32 3, align 4

; ---- reference: native xchg sequence on the pointer cell ----

define i64 @reference() {
entry:
  %r0 = atomicrmw xchg ptr @ptr_cell, ptr @obj_a monotonic, align 8
  %c1 = load ptr, ptr @ptr_cell, align 8
  %r1 = atomicrmw xchg ptr @ptr_cell, ptr @obj_b seq_cst, align 8
  %c2 = load ptr, ptr @ptr_cell, align 8
  %r2 = atomicrmw volatile xchg ptr @ptr_cell, ptr @obj_c syncscope("singlethread") acquire, align 8
  %c3 = load ptr, ptr @ptr_cell, align 8
  %b0 = ptrtoint ptr %r0 to i64
  %b1 = ptrtoint ptr %r1 to i64
  %b2 = ptrtoint ptr %r2 to i64
  %b3 = ptrtoint ptr %c1 to i64
  %b4 = ptrtoint ptr %c2 to i64
  %b5 = ptrtoint ptr %c3 to i64
  %t0 = xor i64 %b0, %b1
  %t1 = xor i64 %b2, %b3
  %t2 = xor i64 %b4, %b5
  %t3 = xor i64 %t0, %t1
  %result = xor i64 %t3, %t2
  ret i64 %result
}

; ---- vmp: same sequence under VMP ----

define i64 @vmp() noinline optnone {
entry:
  call void @hikari_vmp()
  %r0 = atomicrmw xchg ptr @ptr_cell, ptr @obj_a monotonic, align 8
  %c1 = load ptr, ptr @ptr_cell, align 8
  %r1 = atomicrmw xchg ptr @ptr_cell, ptr @obj_b seq_cst, align 8
  %c2 = load ptr, ptr @ptr_cell, align 8
  %r2 = atomicrmw volatile xchg ptr @ptr_cell, ptr @obj_c syncscope("singlethread") acquire, align 8
  %c3 = load ptr, ptr @ptr_cell, align 8
  %b0 = ptrtoint ptr %r0 to i64
  %b1 = ptrtoint ptr %r1 to i64
  %b2 = ptrtoint ptr %r2 to i64
  %b3 = ptrtoint ptr %c1 to i64
  %b4 = ptrtoint ptr %c2 to i64
  %b5 = ptrtoint ptr %c3 to i64
  %t0 = xor i64 %b0, %b1
  %t1 = xor i64 %b2, %b3
  %t2 = xor i64 %b4, %b5
  %t3 = xor i64 %t0, %t1
  %result = xor i64 %t3, %t2
  ret i64 %result
}

; ---- negative: nonzero-AS pointer xchg stays rejected ----

@as1_cell = addrspace(1) global ptr null

define i32 @unsupported_as1_xchg() noinline optnone {
entry:
  call void @hikari_vmp()
  %r = atomicrmw xchg ptr addrspace(1) @as1_cell, ptr addrspace(1) null monotonic, align 8
  %b = ptrtoint ptr addrspace(1) %r to i64
  %t = trunc i64 %b to i32
  ret i32 %t
}

; ---- main: parity checks ----

define i32 @main() {
entry:
  store ptr null, ptr @ptr_cell, align 8
  %e = call i64 @reference()
  store ptr null, ptr @ptr_cell, align 8
  %a = call i64 @vmp()
  %match = icmp eq i64 %e, %a
  %code = select i1 %match, i32 0, i32 1
  ret i32 %code
}

; ---- O0 checks ----

; SKIP-DAG: Skipping VMP on unsupported_as1_xchg: unsupported atomicrmw instruction
; SKIP-NOT: Skipping VMP on vmp:

; VIRT-LABEL: define i64 @vmp(
; VIRT: %vmp.ptr.regs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: atomicrmw xchg {{.*}} monotonic
; VIRT-DAG: atomicrmw xchg {{.*}} seq_cst
; VIRT-DAG: atomicrmw volatile xchg {{.*}} syncscope("singlethread") acquire
; VIRT-DAG: load ptr, ptr
; VIRT-DAG: ptrtoint ptr {{.*}} to i64

; Negative stays native: no dispatch, no virtualized attribute.
; VIRT-LABEL: define i32 @unsupported_as1_xchg(
; VIRT-NOT: vmp.dispatch
; VIRT: atomicrmw xchg ptr addrspace(1)

; VIRT: attributes{{.*}}"hikari.vmp.virtualized"

; ---- O2 checks ----

; SKIP-O2-DAG: Skipping VMP on unsupported_as1_xchg: unsupported atomicrmw instruction
; SKIP-O2-NOT: Skipping VMP on vmp:

; VIRT-O2-LABEL: define i64 @vmp(
; VIRT-O2: %vmp.ptr.regs = alloca
; VIRT-O2: vmp.dispatch:
; VIRT-O2: atomicrmw xchg
; VIRT-O2: attributes{{.*}}"hikari.vmp.virtualized"

; Non-AArch64 module triple: VMP skips all selected functions wholesale.
; SKIP-X86: Skipping VMP: only AArch64 targets are supported
