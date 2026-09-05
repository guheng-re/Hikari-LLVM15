; Scalar integer bit CallDescriptor family: ctpop / bswap / bitreverse
; (T(T)), ctlz / cttz (T(T, i1) is_zero_poison ImmArg), fshl / fshr
; (T(T,T,T)) including restricted scalar i128 funnel.  C, exact
; non-vararg FTy, formal type equality.  Ordinary tail accepted and replayed as TCK_None.
; Replay; no new opcode.  Vectors stay on their own surface.
;
; Host IntrinsicLowering has ctpop/bswap/ctlz/cttz (reliable lli).
; bitreverse / fshl / fshr / i128 funnel have no host case — FileCheck
; + AArch64 llc/readobj only for those.
;
; FileCheck + host lli (count/bswap) + AArch64 llc/readobj.  O0/O2 x 97/7.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.ll > %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.live.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.ll > %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.live.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.s7.ll > %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.s7.live.ll > %t.o0.s7.host.ll
; RUN: lli -force-interpreter %t.o0.s7.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.s7.ll > %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.s7.live.ll > %t.o2.s7.host.ll
; RUN: lli -force-interpreter %t.o2.s7.host.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare i32 @llvm.ctpop.i32(i32)
declare i32 @llvm.bswap.i32(i32)
declare i32 @llvm.bitreverse.i32(i32)
declare i32 @llvm.ctlz.i32(i32, i1 immarg)
declare i32 @llvm.cttz.i32(i32, i1 immarg)
declare i32 @llvm.fshl.i32(i32, i32, i32)
declare i32 @llvm.fshr.i32(i32, i32, i32)
declare i128 @llvm.fshl.i128(i128, i128, i128)
declare i128 @llvm.fshr.i128(i128, i128, i128)
declare void @ext_sret_byval(ptr sret(i32), ptr byval(i32))

; ----- positives (lli: ctpop/bswap/ctlz/cttz) -----

define i32 @reference(i32 %x) noinline {
entry:
  %p = call i32 @llvm.ctpop.i32(i32 %x)
  %s = call i32 @llvm.bswap.i32(i32 %x)
  %lz = call i32 @llvm.ctlz.i32(i32 %x, i1 false)
  %tz = call i32 @llvm.cttz.i32(i32 %x, i1 false)
  %a = add i32 %p, %s
  %b = add i32 %lz, %tz
  %r = xor i32 %a, %b
  ret i32 %r
}

define i32 @protected(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %p = call i32 @llvm.ctpop.i32(i32 %x)
  %s = call i32 @llvm.bswap.i32(i32 %x)
  %lz = call i32 @llvm.ctlz.i32(i32 %x, i1 false)
  %tz = call i32 @llvm.cttz.i32(i32 %x, i1 false)
  %a = add i32 %p, %s
  %b = add i32 %lz, %tz
  %r = xor i32 %a, %b
  ret i32 %r
}

define i32 @protected_ctlz_true(i32 %nz) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.ctlz.i32(i32 %nz, i1 true)
  ret i32 %r
}

define i32 @protected_bitreverse(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.bitreverse.i32(i32 %x)
  ret i32 %r
}

define i32 @protected_fshl(i32 %a, i32 %b, i32 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.fshl.i32(i32 %a, i32 %b, i32 %n)
  ret i32 %r
}

define i32 @protected_fshr(i32 %a, i32 %b, i32 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.fshr.i32(i32 %a, i32 %b, i32 %n)
  ret i32 %r
}

define i128 @protected_i128_funnel(i128 %a, i128 %b, i128 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  %l = call i128 @llvm.fshl.i128(i128 %a, i128 %b, i128 %n)
  %r = call i128 @llvm.fshr.i128(i128 %a, i128 %b, i128 %n)
  %x = xor i128 %l, %r
  ret i128 %x
}

; ----- negatives -----

define i32 @unsupported_ctpop_malformed(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.ctpop.i32(i32 %x) noreturn
  ret i32 %r
}


define i32 @unsupported_ctpop_musttail(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call i32 @llvm.ctpop.i32(i32 %x)
  ret i32 %r
}

define i32 @unsupported_ctpop_bundle(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.ctpop.i32(i32 %x) [ "deopt"(i32 0) ]
  ret i32 %r
}

define i32 @unsupported_ctpop_fastcc(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc i32 @llvm.ctpop.i32(i32 %x)
  ret i32 %r
}

define i32 @unsupported_ctpop_poison() noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.ctpop.i32(i32 poison)
  ret i32 %r
}


define i32 @unsupported_bswap_fastcc(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc i32 @llvm.bswap.i32(i32 %x)
  ret i32 %r
}


define i32 @unsupported_fshr_fastcc(i32 %a, i32 %b, i32 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc i32 @llvm.fshr.i32(i32 %a, i32 %b, i32 %n)
  ret i32 %r
}


define i128 @unsupported_i128_fshl_poison(i128 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i128 @llvm.fshl.i128(i128 poison, i128 %b, i128 3)
  ret i128 %r
}

define void @unsupported_as1_arg(ptr addrspace(1) %unused) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.ctpop.i32(i32 1)
  ret void
}

define void @unsupported_sret(ptr sret(i32) %p, ptr byval(i32) %q) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @ext_sret_byval(ptr sret(i32) %p, ptr byval(i32) %q)
  ret void
}

define i32 @main() {
entry:
  %e0 = call i32 @reference(i32 305419896)
  %a0 = call i32 @protected(i32 305419896)
  %m0 = icmp eq i32 %e0, %a0
  %e1 = call i32 @reference(i32 1)
  %a1 = call i32 @protected(i32 1)
  %m1 = icmp eq i32 %e1, %a1
  %ok = and i1 %m0, %m1
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_ctpop_malformed: unsupported ctpop
; SKIP-DAG: Skipping VMP on unsupported_ctpop_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_ctpop_bundle: unsupported ctpop
; SKIP-DAG: Skipping VMP on unsupported_ctpop_fastcc: unsupported ctpop
; SKIP-DAG: Skipping VMP on unsupported_ctpop_poison: unsupported ctpop
; SKIP-DAG: Skipping VMP on unsupported_bswap_fastcc: unsupported bswap
; SKIP-DAG: Skipping VMP on unsupported_fshr_fastcc: unsupported fshr
; SKIP-DAG: Skipping VMP on unsupported_i128_fshl_poison: unsupported fshl
; SKIP-DAG: Skipping VMP on unsupported_as1_arg: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_sret: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected:
; SKIP-NOT: Skipping VMP on protected_ctlz_true:
; SKIP-NOT: Skipping VMP on protected_bitreverse:
; SKIP-NOT: Skipping VMP on protected_fshl:
; SKIP-NOT: Skipping VMP on protected_fshr:
; SKIP-NOT: Skipping VMP on protected_i128_funnel:

; VIRT: define i32 @protected({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: call i32 @llvm.ctpop.i32(
; VIRT-DAG: call i32 @llvm.bswap.i32(
; VIRT-DAG: call i32 @llvm.ctlz.i32({{.*}}, i1 false)
; VIRT-DAG: call i32 @llvm.cttz.i32({{.*}}, i1 false)
; VIRT: }
; VIRT: define i32 @protected_ctlz_true({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: call i32 @llvm.ctlz.i32({{.*}}, i1 true)
; VIRT: }
; VIRT: define i32 @protected_bitreverse({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: call i32 @llvm.bitreverse.i32(
; VIRT: }
; VIRT: define i32 @protected_fshl({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: call i32 @llvm.fshl.i32(
; VIRT: }
; VIRT: define i32 @protected_fshr({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: call i32 @llvm.fshr.i32(
; VIRT: }
; VIRT: define i128 @protected_i128_funnel({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: call i128 @llvm.fshl.i128(
; VIRT-DAG: call i128 @llvm.fshr.i128(
; VIRT: }
; VIRT: define {{.*}} @unsupported_ctpop_malformed({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ctpop_musttail({{.*}} #[[UNSUPMUST:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call i32 @llvm.ctpop.i32(
; VIRT: define {{.*}} @unsupported_ctpop_bundle({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ctpop_fastcc({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ctpop_poison({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_bswap_fastcc({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fshr_fastcc({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_i128_fshl_poison({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_as1_arg({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_sret({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPMUST]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPMUST]] = { {{.*}}"hikari.vmp.selected"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
