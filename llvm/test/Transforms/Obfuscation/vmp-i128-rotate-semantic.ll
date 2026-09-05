; Restricted scalar i128 llvm.fshl/fshr: rotate when both concatenated
; operands are the same SSA value, and ordinary two-operand funnel when
; they differ.  Replayed through the independent i128 VReg frame and
; the ordinary Call path.  main compares reference vs protected for
; rotate amounts 0/1/63/64/127/128/129 and for distinct-operand funnel.
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
declare i128 @llvm.fshl.i128(i128, i128, i128)
declare i128 @llvm.fshr.i128(i128, i128, i128)

define i32 @reference_rot(i128 %a, i128 %n) noinline optnone {
entry:
  %rotl = call i128 @llvm.fshl.i128(i128 %a, i128 %a, i128 %n)
  %rotr = call i128 @llvm.fshr.i128(i128 %a, i128 %a, i128 %n)
  %mix = xor i128 %rotl, %rotr
  %lo = trunc i128 %mix to i32
  %hi64 = lshr i128 %mix, 32
  %hi = trunc i128 %hi64 to i32
  %out = xor i32 %lo, %hi
  ret i32 %out
}

define i32 @protected_rot(i128 %a, i128 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  %rotl = call i128 @llvm.fshl.i128(i128 %a, i128 %a, i128 %n)
  %rotr = call i128 @llvm.fshr.i128(i128 %a, i128 %a, i128 %n)
  %mix = xor i128 %rotl, %rotr
  %lo = trunc i128 %mix to i32
  %hi64 = lshr i128 %mix, 32
  %hi = trunc i128 %hi64 to i32
  %out = xor i32 %lo, %hi
  ret i32 %out
}

define i32 @fold_i128(i128 %v) {
entry:
  %lo = trunc i128 %v to i32
  %hi64 = lshr i128 %v, 32
  %hi = trunc i128 %hi64 to i32
  %out = xor i32 %lo, %hi
  ret i32 %out
}

define i32 @reference_funnel(i128 %a, i128 %b, i128 %n) noinline optnone {
entry:
  %l = call i128 @llvm.fshl.i128(i128 %a, i128 %b, i128 %n)
  %r = call i128 @llvm.fshr.i128(i128 %a, i128 %b, i128 %n)
  %mix = xor i128 %l, %r
  %out = call i32 @fold_i128(i128 %mix)
  ret i32 %out
}

define i32 @protected_funnel(i128 %a, i128 %b, i128 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  %l = call i128 @llvm.fshl.i128(i128 %a, i128 %b, i128 %n)
  %r = call i128 @llvm.fshr.i128(i128 %a, i128 %b, i128 %n)
  %mix = xor i128 %l, %r
  %out = call i32 @fold_i128(i128 %mix)
  ret i32 %out
}


define i128 @sink_i128_2(i128 %a, i128 %b) {
entry:
  ret i128 %a
}

define i128 @unsupported_i128_funnel_musttail(i128 %a, i128 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i128 @llvm.fshl.i128(i128 %a, i128 %b, i128 3)
  %v = musttail call i128 @sink_i128_2(i128 %r, i128 %b)
  ret i128 %v
}

define i128 @unsupported_i128_funnel_poison(i128 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i128 @llvm.fshl.i128(i128 poison, i128 %b, i128 3)
  ret i128 %r
}

define i32 @main() {
entry:
  %ep0 = call i32 @reference_rot(i128 305419896, i128 0)
  %ap0 = call i32 @protected_rot(i128 305419896, i128 0)
  %okp0 = icmp eq i32 %ep0, %ap0
  %ep1 = call i32 @reference_rot(i128 305419896, i128 1)
  %ap1 = call i32 @protected_rot(i128 305419896, i128 1)
  %okp1 = icmp eq i32 %ep1, %ap1
  %ep63 = call i32 @reference_rot(i128 305419896, i128 63)
  %ap63 = call i32 @protected_rot(i128 305419896, i128 63)
  %okp63 = icmp eq i32 %ep63, %ap63
  %ep64 = call i32 @reference_rot(i128 305419896, i128 64)
  %ap64 = call i32 @protected_rot(i128 305419896, i128 64)
  %okp64 = icmp eq i32 %ep64, %ap64
  %ep127 = call i32 @reference_rot(i128 305419896, i128 127)
  %ap127 = call i32 @protected_rot(i128 305419896, i128 127)
  %okp127 = icmp eq i32 %ep127, %ap127
  %ep128 = call i32 @reference_rot(i128 305419896, i128 128)
  %ap128 = call i32 @protected_rot(i128 305419896, i128 128)
  %okp128 = icmp eq i32 %ep128, %ap128
  %ep129 = call i32 @reference_rot(i128 305419896, i128 129)
  %ap129 = call i32 @protected_rot(i128 305419896, i128 129)
  %okp129 = icmp eq i32 %ep129, %ap129
  %en0 = call i32 @reference_rot(i128 -305419896, i128 0)
  %an0 = call i32 @protected_rot(i128 -305419896, i128 0)
  %okn0 = icmp eq i32 %en0, %an0
  %en1 = call i32 @reference_rot(i128 -305419896, i128 1)
  %an1 = call i32 @protected_rot(i128 -305419896, i128 1)
  %okn1 = icmp eq i32 %en1, %an1
  %en63 = call i32 @reference_rot(i128 -305419896, i128 63)
  %an63 = call i32 @protected_rot(i128 -305419896, i128 63)
  %okn63 = icmp eq i32 %en63, %an63
  %en64 = call i32 @reference_rot(i128 -305419896, i128 64)
  %an64 = call i32 @protected_rot(i128 -305419896, i128 64)
  %okn64 = icmp eq i32 %en64, %an64
  %en127 = call i32 @reference_rot(i128 -305419896, i128 127)
  %an127 = call i32 @protected_rot(i128 -305419896, i128 127)
  %okn127 = icmp eq i32 %en127, %an127
  %en128 = call i32 @reference_rot(i128 -305419896, i128 128)
  %an128 = call i32 @protected_rot(i128 -305419896, i128 128)
  %okn128 = icmp eq i32 %en128, %an128
  %en129 = call i32 @reference_rot(i128 -305419896, i128 129)
  %an129 = call i32 @protected_rot(i128 -305419896, i128 129)
  %okn129 = icmp eq i32 %en129, %an129
  %t0 = and i1 %okp0, %okp1
  %t1 = and i1 %t0, %okp63
  %t2 = and i1 %t1, %okp64
  %t3 = and i1 %t2, %okp127
  %t4 = and i1 %t3, %okp128
  %t5 = and i1 %t4, %okp129
  %t6 = and i1 %t5, %okn0
  %t7 = and i1 %t6, %okn1
  %t8 = and i1 %t7, %okn63
  %t9 = and i1 %t8, %okn64
  %t10 = and i1 %t9, %okn127
  %t11 = and i1 %t10, %okn128
  %okrot = and i1 %t11, %okn129
  %ef0 = call i32 @reference_funnel(i128 305419896, i128 17, i128 3)
  %af0 = call i32 @protected_funnel(i128 305419896, i128 17, i128 3)
  %okf0 = icmp eq i32 %ef0, %af0
  %ef1 = call i32 @reference_funnel(i128 -305419896, i128 99, i128 67)
  %af1 = call i32 @protected_funnel(i128 -305419896, i128 99, i128 67)
  %okf1 = icmp eq i32 %ef1, %af1
  %okf = and i1 %okf0, %okf1
  %ok = and i1 %okrot, %okf
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_i128_funnel_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_i128_funnel_poison: unsupported fshl
; SKIP-NOT: Skipping VMP on protected_rot:
; SKIP-NOT: Skipping VMP on protected_funnel:
; SKIP-NOT: Skipping VMP on reference_rot:
; SKIP-NOT: Skipping VMP on reference_funnel:

; VIRT-LABEL: define i32 @protected_rot(
; VIRT: %vmp.i128.regs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: call i128 @llvm.fshl.i128(
; VIRT-DAG: call i128 @llvm.fshr.i128(
; VIRT: define i32 @protected_funnel({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: call i128 @llvm.fshl.i128(
; VIRT-DAG: call i128 @llvm.fshr.i128(
; VIRT: define i128 @unsupported_i128_funnel_musttail({{.*}} #[[UNSUP_MT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call i128 @sink_i128_2(
; VIRT: define i128 @unsupported_i128_funnel_poison({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #{{[0-9]+}} = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"
; VIRT-NOT: attributes #[[UNSUP_MT]] = { {{.*}}"hikari.vmp.virtualized"
