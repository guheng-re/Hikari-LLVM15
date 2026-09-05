; Restricted scalar i128 pure bit intrinsics: ctpop / bswap / bitreverse /
; ctlz / cttz, replayed through the independent i128 VReg frame and the
; ordinary Call path.  Saturation, general funnel, abs and min/max live
; in vmp-i128-abs-minmax-sat-semantic.ll; extractvalue i128
; *with.overflow lives in vmp-i128-overflow-semantic.ll.  Same-operand
; i128 rotate lives in
; vmp-i128-rotate-semantic.ll.  is_zero_poison=true uses a nonzero operand.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.ll > %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.live.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.ll > %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.live.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.s7.ll > %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.s7.live.ll > %t.o0.s7.host.ll
; RUN: lli -force-interpreter %t.o0.s7.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.s7.ll > %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.s7.live.ll > %t.o2.s7.host.ll
; RUN: lli -force-interpreter %t.o2.s7.host.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare i128 @llvm.ctpop.i128(i128)
declare i128 @llvm.bswap.i128(i128)
declare i128 @llvm.bitreverse.i128(i128)
declare i128 @llvm.ctlz.i128(i128, i1 immarg)
declare i128 @llvm.cttz.i128(i128, i1 immarg)
declare i128 @llvm.fshl.i128(i128, i128, i128)

define i32 @reference_bits(i128 %a) noinline optnone {
entry:
  %pop = call i128 @llvm.ctpop.i128(i128 %a)
  %sw = call i128 @llvm.bswap.i128(i128 %a)
  %rev = call i128 @llvm.bitreverse.i128(i128 %a)
  %nz = or i128 %a, 1
  %lz0 = call i128 @llvm.ctlz.i128(i128 %a, i1 false)
  %lz1 = call i128 @llvm.ctlz.i128(i128 %nz, i1 true)
  %tz0 = call i128 @llvm.cttz.i128(i128 %a, i1 false)
  %tz1 = call i128 @llvm.cttz.i128(i128 %nz, i1 true)
  %t0 = xor i128 %pop, %sw
  %t1 = xor i128 %t0, %rev
  %t2 = xor i128 %t1, %lz0
  %t3 = xor i128 %t2, %lz1
  %t4 = xor i128 %t3, %tz0
  %t5 = xor i128 %t4, %tz1
  %lo = trunc i128 %t5 to i32
  %hi64 = lshr i128 %t5, 32
  %hi = trunc i128 %hi64 to i32
  %out = xor i32 %lo, %hi
  ret i32 %out
}

define i32 @protected_bits(i128 %a) noinline optnone {
entry:
  call void @hikari_vmp()
  %pop = call i128 @llvm.ctpop.i128(i128 %a)
  %sw = call i128 @llvm.bswap.i128(i128 %a)
  %rev = call i128 @llvm.bitreverse.i128(i128 %a)
  %nz = or i128 %a, 1
  %lz0 = call i128 @llvm.ctlz.i128(i128 %a, i1 false)
  %lz1 = call i128 @llvm.ctlz.i128(i128 %nz, i1 true)
  %tz0 = call i128 @llvm.cttz.i128(i128 %a, i1 false)
  %tz1 = call i128 @llvm.cttz.i128(i128 %nz, i1 true)
  %t0 = xor i128 %pop, %sw
  %t1 = xor i128 %t0, %rev
  %t2 = xor i128 %t1, %lz0
  %t3 = xor i128 %t2, %lz1
  %t4 = xor i128 %t3, %tz0
  %t5 = xor i128 %t4, %tz1
  %lo = trunc i128 %t5 to i32
  %hi64 = lshr i128 %t5, 32
  %hi = trunc i128 %hi64 to i32
  %out = xor i32 %lo, %hi
  ret i32 %out
}

define i128 @unsupported_i128_fshl(i128 %a, i128 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i128 @llvm.fshl.i128(i128 %a, i128 %b, i128 3)
  ret i128 %r
}

define i32 @main() {
entry:
  %e0 = call i32 @reference_bits(i128 305419896)
  %a0 = call i32 @protected_bits(i128 305419896)
  %ok0 = icmp eq i32 %e0, %a0
  %e1 = call i32 @reference_bits(i128 4294967296)
  %a1 = call i32 @protected_bits(i128 4294967296)
  %ok1 = icmp eq i32 %e1, %a1
  %e2 = call i32 @reference_bits(i128 -1)
  %a2 = call i32 @protected_bits(i128 -1)
  %ok2 = icmp eq i32 %e2, %a2
  %e3 = call i32 @reference_bits(i128 0)
  %a3 = call i32 @protected_bits(i128 0)
  %ok3 = icmp eq i32 %e3, %a3
  %t0 = and i1 %ok0, %ok1
  %t1 = and i1 %t0, %ok2
  %ok = and i1 %t1, %ok3
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP-DAG: Skipping VMP on unsupported_i128_fshl: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_bits:
; SKIP-NOT: Skipping VMP on reference_bits:

; VIRT-LABEL: define i32 @protected_bits(
; VIRT: %vmp.i128.regs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: call i128 @llvm.ctpop.i128(
; VIRT-DAG: call i128 @llvm.bswap.i128(
; VIRT-DAG: call i128 @llvm.bitreverse.i128(
; VIRT-DAG: call i128 @llvm.ctlz.i128({{.*}}, i1 false)
; VIRT-DAG: call i128 @llvm.ctlz.i128({{.*}}, i1 true)
; VIRT-DAG: call i128 @llvm.cttz.i128({{.*}}, i1 false)
; VIRT-DAG: call i128 @llvm.cttz.i128({{.*}}, i1 true)
; VIRT: define i128 @unsupported_i128_fshl({{.*}} #[[UNSUPATTR:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #{{[0-9]+}} = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.virtualized"
