; RUN: opt -S -verify-each -enable-vmpobf -passes='default<O0>' %s -o - 2>&1 | FileCheck %s

target triple = "aarch64-unknown-linux-gnu"

@number = global i32 0, align 4

declare i32 @plain(i32)
declare void @sink(ptr byval(i32))
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)

define i32 @dynamic(ptr %src) {
entry:
  ; Load-derived length stays rejected (pure entry add of an argument is now legal).
  %ld = load i64, ptr %src, align 8
  %n1 = add i64 %ld, 1
  %slot = alloca i32, i64 %n1, align 4
  store i32 1, ptr %slot, align 4
  %value = load i32, ptr %slot, align 4
  ret i32 %value
}

define i32 @integer_bitcast(i32 %value) {
entry:
  %bits = bitcast i32 %value to float
  %rounded = fptosi float %bits to i32
  ret i32 %rounded
}

declare void @llvm.memset.p0.i8(ptr nocapture writeonly, i8, i8, i1 immarg)

define void @memory_intrinsic(ptr %address, i8 %len) {
entry:
  ; Non-i32/i64 length remains unsupported.
  call void @llvm.memset.p0.i8(ptr %address, i8 0, i8 %len, i1 false)
  ret void
}

define void @volatile_memory_intrinsic(ptr %address) {
entry:
  ; Constant-length AS0 volatile memset is supported and replayed.
  call void @llvm.memset.p0.i64(ptr %address, i8 0, i64 4, i1 true)
  ret void
}

define i32 @musttail_call(i32 %x) {
entry:
  %value = musttail call i32 @plain(i32 %x)
  ret i32 %value
}

define void @complex_abi() {
entry:
  %slot = alloca i32, align 4
  call void @sink(ptr byval(i32) %slot)
  ret void
}

define i32 @nonzero_address_space(ptr addrspace(1) %address) {
entry:
  %value = load i32, ptr addrspace(1) %address, align 4
  ret i32 %value
}

define float @floating(float %value) {
entry:
  %result = fadd float %value, 1.000000e+00
  ret float %result
}

define i1 @signed_pointer_icmp(ptr %left, ptr %right) {
entry:
  ; Signed pointer relational icmp remains unsupported.
  %cmp = icmp slt ptr %left, %right
  ret i1 %cmp
}

define i32 @atomic() {
entry:
  %value = atomicrmw add ptr @number, i32 1 seq_cst
  ret i32 %value
}

; AS0 pointer cmpxchg is supported and replayed (success flag extracted).
@pslot = global ptr null, align 8
@gval = global i32 1, align 4
define i32 @compare_exchange() {
entry:
  %pair = cmpxchg ptr @pslot, ptr null, ptr @gval seq_cst seq_cst
  %ok = extractvalue { ptr, i1 } %pair, 1
  %z = zext i1 %ok to i32
  ret i32 %z
}

; Still-unsupported paths (selection vs late eligibility may interleave).
; CHECK-DAG: Skipping VMP on musttail_call: musttail call
; CHECK-DAG: Skipping VMP on dynamic: unsupported stack allocation
; CHECK-DAG: Skipping VMP on memory_intrinsic: unsupported call instruction
; CHECK-DAG: Skipping VMP on complex_abi: unsupported call instruction
; CHECK-DAG: Skipping VMP on nonzero_address_space: unsupported argument type
; CHECK-DAG: Skipping VMP on signed_pointer_icmp: unsupported comparison
; No longer skipped (virtualized): integer_bitcast, floating, atomicrmw add,
; constant-length AS0 volatile memset, AS0 pointer cmpxchg.

; IR checks follow source emission order.
; CHECK-LABEL: define i32 @dynamic(
; CHECK: alloca i32, i64 %n1
; CHECK-LABEL: define i32 @integer_bitcast(
; CHECK: vmp.dispatch:
; CHECK-DAG: bitcast i32 {{.*}} to float
; CHECK-DAG: fptosi float {{.*}} to i32
; CHECK-LABEL: define void @memory_intrinsic(
; CHECK: call void @llvm.memset.p0.i8
; CHECK-LABEL: define void @volatile_memory_intrinsic(
; CHECK: vmp.dispatch:
; CHECK: call void @llvm.memset.p0.i64({{.*}}, i1 true)
; CHECK-LABEL: define float @floating(
; CHECK: vmp.dispatch:
; CHECK: fadd float
; CHECK-LABEL: define i32 @atomic(
; CHECK: vmp.dispatch:
; CHECK: atomicrmw add ptr {{.*}}, i32 {{.*}} seq_cst
; CHECK-LABEL: define i32 @compare_exchange(
; CHECK: vmp.dispatch:
; CHECK: cmpxchg ptr {{.*}}, ptr {{.*}}, ptr {{.*}} seq_cst seq_cst
; CHECK: attributes{{.*}}"hikari.vmp.virtualized"
