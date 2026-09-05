; Normal path: virtualize static dual-target indirectbr.
; RUN: opt -S -verify-each -aesSeed=83 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=83 -passes='default<O2>' %s -o %t.o2.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
;
; Budget fallback: planning may materialize BA labels, then abort on bytecode
; word budget. Labels created for this failed attempt must be erased.
; RUN: opt -S -verify-each -aesSeed=83 -vmp-max-bytecode-words=1 -passes='default<O0>' %s -o %t.budget.ll 2>%t.budget.err
; RUN: FileCheck %s --check-prefix=BUDGET-ERR < %t.budget.err
; RUN: FileCheck %s --check-prefix=BUDGET-IR < %t.budget.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()

; Legal static dual-target indirectbr via select of same-function blockaddresses.
; Destinations have no PHI (no edge-copy required).
define i32 @reference(i1 %c) {
entry:
  %dest = select i1 %c, ptr blockaddress(@reference, %then), ptr blockaddress(@reference, %else)
  indirectbr ptr %dest, [label %then, label %else]
then:
  ret i32 10
else:
  ret i32 20
}

define i32 @protected(i1 %c) noinline optnone {
entry:
  call void @hikari_vmp()
  %dest = select i1 %c, ptr blockaddress(@protected, %then), ptr blockaddress(@protected, %else)
  indirectbr ptr %dest, [label %then, label %else]
then:
  ret i32 10
else:
  ret i32 20
}

; Dynamic address via inttoptr remains unsupported.
define i32 @dynamic_addr(i64 %bits) {
entry:
  call void @hikari_vmp()
  %p = inttoptr i64 %bits to ptr
  indirectbr ptr %p, [label %a, label %b]
a:
  ret i32 1
b:
  ret i32 2
}

; Destination with PHI requires edge copy; stay unsupported.
define i32 @phi_dest(i1 %c, i32 %x, i32 %y) {
entry:
  call void @hikari_vmp()
  br i1 %c, label %left, label %right
left:
  %dest.l = select i1 true, ptr blockaddress(@phi_dest, %join), ptr blockaddress(@phi_dest, %join)
  indirectbr ptr %dest.l, [label %join]
right:
  br label %join
join:
  %v = phi i32 [ %x, %left ], [ %y, %right ]
  ret i32 %v
}

define i32 @main() {
entry:
  %e0 = call i32 @reference(i1 true)
  %a0 = call i32 @protected(i1 true)
  %e1 = call i32 @reference(i1 false)
  %a1 = call i32 @protected(i1 false)
  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %e1, %a1
  %ok = and i1 %m0, %m1
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP-DAG: Skipping VMP on dynamic_addr: unsupported indirectbr instruction
; SKIP-DAG: Skipping VMP on phi_dest: unsupported indirectbr instruction

; VIRT-LABEL: define i32 @protected(
; VIRT: vmp.dispatch:
; VIRT-DAG: icmp eq ptr {{.*}}@__hikari_vmp_ba.protected.
; VIRT-DAG: call void @llvm.trap()
; VIRT-LABEL: define i32 @dynamic_addr(
; VIRT: indirectbr ptr %p
; VIRT-LABEL: define i32 @phi_dest(
; VIRT: indirectbr
; VIRT: attributes{{.*}}"hikari.vmp.virtualized"

; BUDGET-ERR: Skipping VMP on protected: bytecode word budget
; BUDGET-IR-LABEL: define i32 @protected(
; BUDGET-IR: indirectbr ptr %dest, [label %then, label %else]
; BUDGET-IR-NOT: __hikari_vmp_ba
; BUDGET-IR-NOT: "hikari.vmp.virtualized"
