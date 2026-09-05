; Scalar llvm.vscale via normal Call path (i1/i8/i16/i32/i64 result VReg).
; No dedicated VM opcode.  Requires an explicit function "target-features"
; attribute that enables +sve (last +sve/-sve token wins).  Missing/disabled
; +sve reports "unsupported target feature"; i128 reports the generic call
; reject.  Command-line -mattr is never used for eligibility or object gen.
;
; Host x86_64 cannot select vscale; after the triple rewrite, rewrite remaining
; llvm.vscale.*() calls to "add <ty> 0, 1" so lli can run the and-with-0
; differential (always 0) without depending on absolute VL.
;
; llc object gen is restricted to main + reachable +sve functions so bodies
; that intentionally lack SVE (and would not select) are not linked in.
;
; RUN: opt -S -verify-each -aesSeed=167 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.ll -o %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: sed -e 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' -e 's/call \(i[0-9][0-9]*\) @llvm\.vscale\.i[0-9][0-9]*()/add \1 0, 1/g' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=167 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.ll -o %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: sed -e 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' -e 's/call \(i[0-9][0-9]*\) @llvm\.vscale\.i[0-9][0-9]*()/add \1 0, 1/g' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare i8 @llvm.vscale.i8()
declare i32 @llvm.vscale.i32()
declare i64 @llvm.vscale.i64()
declare i128 @llvm.vscale.i128()

; Consume i8/i32/i64 vscale results: zext/trunc merge, and with 0 (always 0).
; Explicit +sve on the function attribute (not inferred from llc -mattr).
define i32 @reference_vscale() "target-features"="+sve" {
entry:
  %a = call i8 @llvm.vscale.i8()
  %b = call i32 @llvm.vscale.i32()
  %c = call i64 @llvm.vscale.i64()
  %a32 = zext i8 %a to i32
  %c32 = trunc i64 %c to i32
  %ab = add i32 %a32, %b
  %sum = add i32 %ab, %c32
  %out = and i32 %sum, 0
  ret i32 %out
}

define i32 @protected_vscale() noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %a = call i8 @llvm.vscale.i8()
  %b = call i32 @llvm.vscale.i32()
  %c = call i64 @llvm.vscale.i64()
  %a32 = zext i8 %a to i32
  %c32 = trunc i64 %c to i32
  %ab = add i32 %a32, %b
  %sum = add i32 %ab, %c32
  %out = and i32 %sum, 0
  ret i32 %out
}

; Last token -sve wins over an earlier +sve — feature-gate skip (not call).
define i32 @unsupported_vscale_sve_disabled() noinline optnone "target-features"="+neon,+sve,-sve" {
entry:
  call void @hikari_vmp()
  %v = call i32 @llvm.vscale.i32()
  %out = and i32 %v, 0
  ret i32 %out
}

; No target-features attribute — feature-gate skip (even with valid width).
define i32 @unsupported_vscale_no_target_features() noinline optnone {
entry:
  call void @hikari_vmp()
  %v = call i32 @llvm.vscale.i32()
  %out = and i32 %v, 0
  ret i32 %out
}

; Function returns supported i32 so skip is from intrinsic shape (i128
; result), not the function return-type gate.  +sve is present so the reject
; is "unsupported call instruction", not the SVE feature gate.
define i32 @unsupported_vscale_i128() noinline optnone "target-features"="+sve" {
entry:
  call void @hikari_vmp()
  %v = call i128 @llvm.vscale.i128()
  %out = trunc i128 %v to i32
  ret i32 %out
}

define i32 @main() {
entry:
  %e0 = call i32 @reference_vscale()
  %a0 = call i32 @protected_vscale()
  %e1 = call i32 @reference_vscale()
  %a1 = call i32 @protected_vscale()
  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %e1, %a1
  %ok = and i1 %m0, %m1
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with: 167
; SKIP-DAG: Skipping VMP on unsupported_vscale_i128: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_vscale_sve_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_vscale_no_target_features: unsupported target feature
; SKIP-NOT: Skipping VMP on protected_vscale:

; VIRT: define i32 @protected_vscale({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: call i8 @llvm.vscale.i8(
; VIRT-DAG: call i32 @llvm.vscale.i32(
; VIRT-DAG: call i64 @llvm.vscale.i64(
; VIRT: define i32 @unsupported_vscale_sve_disabled({{.*}} #[[UNSUP_DIS:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call i32 @llvm.vscale.i32(
; VIRT: define i32 @unsupported_vscale_no_target_features({{.*}} #[[UNSUP_NO:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call i32 @llvm.vscale.i32(
; VIRT: define i32 @unsupported_vscale_i128({{.*}} #[[UNSUP128:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call i128 @llvm.vscale.i128(
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP_DIS]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT: attributes #[[UNSUP_NO]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT: attributes #[[UNSUP128]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
