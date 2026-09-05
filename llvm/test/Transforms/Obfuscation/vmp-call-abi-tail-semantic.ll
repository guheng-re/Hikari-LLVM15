; Focused ordinary-tail lock-in for the six already-supported ABI
; CallInst helpers.  Ordinary tail is an optimization hint and is
; replayed as a normal non-tail CreateCall (TCK_None):
;   isSupportedDirectSretCall
;   isSupportedDirectByvalCall
;   isSupportedDirectByrefCall
;   isSupportedDirectNoreturnCall
;   isSupportedIndirectMinimalCall
;   isBFloatIndirectCallShape
; Each surface has a virtualized non-tail protected_* and a matching
; protected_*_tail.  Generic direct / fastcc tail live in
; vmp-direct-call-tail-eligibility-semantic.ll and
; vmp-tail-call-semantic.ll.  musttail stays the early "musttail call"
; diagnostic (indirect musttail, including +bf16 bfloat, is late
; "indirect call").  Feature gates stay first: well-shaped bfloat
; indirect without +bf16 remains "unsupported target feature" even
; when tailed.  InvokeInst, callbr, inline asm, operand bundles, and
; still-closed ABI stay out.
;
; Host lli is reliable for i32 sret / read-only byval / byref /
; noreturn-success / indirect add_one.  Bfloat is FileCheck + AArch64
; llc only (host cannot be assumed to select it); host IR is
; internalized to main.  Byval sinks only read so force-interpreter
; vs real ABI copy cannot diverge.  O0/O2 x 97/7.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.ll > %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.live.ll -o %t.o0.host.src.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.host.src.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.ll > %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.live.ll -o %t.o2.host.src.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.host.src.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.s7.ll > %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.s7.live.ll -o %t.o0.s7.host.src.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.s7.host.src.ll > %t.o0.s7.host.ll
; RUN: lli -force-interpreter %t.o0.s7.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.s7.ll > %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.s7.live.ll -o %t.o2.s7.host.src.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.s7.host.src.ll > %t.o2.s7.host.ll
; RUN: lli -force-interpreter %t.o2.s7.host.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %s | opt -S -verify-each -aesSeed=97 -passes='default<O0>' - 2>&1 | FileCheck %s --check-prefix=HOST

target triple = "aarch64-unknown-linux-gnu"

%pair = type { i32, i32 }

declare void @hikari_vmp()

@slot = private global i32 0, align 4

define void @sink_sret(ptr sret(%pair) align 4 %p, i32 %a, i32 %b) noinline {
entry:
  %f0 = getelementptr inbounds %pair, ptr %p, i32 0, i32 0
  %f1 = getelementptr inbounds %pair, ptr %p, i32 0, i32 1
  store i32 %a, ptr %f0, align 4
  store i32 %b, ptr %f1, align 4
  ret void
}

define i32 @sink_byval(ptr byval(%pair) align 8 %p, i32 %k) noinline {
entry:
  %f0 = getelementptr inbounds %pair, ptr %p, i32 0, i32 0
  %f1 = getelementptr inbounds %pair, ptr %p, i32 0, i32 1
  %x = load i32, ptr %f0, align 4
  %y = load i32, ptr %f1, align 4
  %t = xor i32 %x, %y
  %r = xor i32 %t, %k
  ret i32 %r
}

define i32 @sink_byref(ptr byref(%pair) align 8 %p, i32 %k) noinline {
entry:
  %f0 = getelementptr inbounds %pair, ptr %p, i32 0, i32 0
  %f1 = getelementptr inbounds %pair, ptr %p, i32 0, i32 1
  %x = load i32, ptr %f0, align 4
  %y = load i32, ptr %f1, align 4
  store i32 1, ptr %f0, align 4
  store i32 2, ptr %f1, align 4
  %t = xor i32 %x, %y
  %r = xor i32 %t, %k
  ret i32 %r
}

define void @abort_now(i32 %code) noreturn noinline {
entry:
  store volatile i32 %code, ptr @slot, align 4
  unreachable
}

define i32 @add_one(i32 %x) noinline {
entry:
  %r = add i32 %x, 1
  ret i32 %r
}

define bfloat @bf_id(bfloat %x) noinline {
entry:
  %b = bitcast bfloat %x to i16
  %r = bitcast i16 %b to bfloat
  ret bfloat %r
}

define i32 @reference_sret(i32 %a, i32 %b) noinline optnone {
entry:
  %slot = alloca %pair, align 4
  call void @sink_sret(ptr sret(%pair) align 4 %slot, i32 %a, i32 %b)
  %p0 = getelementptr inbounds %pair, ptr %slot, i32 0, i32 0
  %p1 = getelementptr inbounds %pair, ptr %slot, i32 0, i32 1
  %x = load i32, ptr %p0, align 4
  %y = load i32, ptr %p1, align 4
  %out = xor i32 %x, %y
  ret i32 %out
}

define i32 @protected_sret(i32 %a, i32 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %slot = alloca %pair, align 4
  call void @sink_sret(ptr sret(%pair) align 4 %slot, i32 %a, i32 %b)
  %p0 = getelementptr inbounds %pair, ptr %slot, i32 0, i32 0
  %p1 = getelementptr inbounds %pair, ptr %slot, i32 0, i32 1
  %x = load i32, ptr %p0, align 4
  %y = load i32, ptr %p1, align 4
  %out = xor i32 %x, %y
  ret i32 %out
}

define i32 @protected_sret_tail(i32 %a, i32 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %slot = alloca %pair, align 4
  tail call void @sink_sret(ptr sret(%pair) align 4 %slot, i32 %a, i32 %b)
  %p0 = getelementptr inbounds %pair, ptr %slot, i32 0, i32 0
  %p1 = getelementptr inbounds %pair, ptr %slot, i32 0, i32 1
  %x = load i32, ptr %p0, align 4
  %y = load i32, ptr %p1, align 4
  %out = xor i32 %x, %y
  ret i32 %out
}

define i32 @reference_byval(i32 %a, i32 %b, i32 %k) noinline optnone {
entry:
  %slot = alloca %pair, align 8
  %p0 = getelementptr inbounds %pair, ptr %slot, i32 0, i32 0
  %p1 = getelementptr inbounds %pair, ptr %slot, i32 0, i32 1
  store i32 %a, ptr %p0, align 4
  store i32 %b, ptr %p1, align 4
  %r = call i32 @sink_byval(ptr byval(%pair) align 8 %slot, i32 %k)
  ret i32 %r
}

define i32 @protected_byval(i32 %a, i32 %b, i32 %k) noinline optnone {
entry:
  call void @hikari_vmp()
  %slot = alloca %pair, align 8
  %p0 = getelementptr inbounds %pair, ptr %slot, i32 0, i32 0
  %p1 = getelementptr inbounds %pair, ptr %slot, i32 0, i32 1
  store i32 %a, ptr %p0, align 4
  store i32 %b, ptr %p1, align 4
  %r = call i32 @sink_byval(ptr byval(%pair) align 8 %slot, i32 %k)
  ret i32 %r
}

define i32 @protected_byval_tail(i32 %a, i32 %b, i32 %k) noinline optnone {
entry:
  call void @hikari_vmp()
  %slot = alloca %pair, align 8
  %p0 = getelementptr inbounds %pair, ptr %slot, i32 0, i32 0
  %p1 = getelementptr inbounds %pair, ptr %slot, i32 0, i32 1
  store i32 %a, ptr %p0, align 4
  store i32 %b, ptr %p1, align 4
  %r = tail call i32 @sink_byval(ptr byval(%pair) align 8 %slot, i32 %k)
  ret i32 %r
}

define i32 @reference_byref(i32 %a, i32 %b, i32 %k) noinline optnone {
entry:
  %slot = alloca %pair, align 8
  %p0 = getelementptr inbounds %pair, ptr %slot, i32 0, i32 0
  %p1 = getelementptr inbounds %pair, ptr %slot, i32 0, i32 1
  store i32 %a, ptr %p0, align 4
  store i32 %b, ptr %p1, align 4
  %r = call i32 @sink_byref(ptr byref(%pair) align 8 %slot, i32 %k)
  %x = load i32, ptr %p0, align 4
  %y = load i32, ptr %p1, align 4
  %t = xor i32 %r, %x
  %out = xor i32 %t, %y
  ret i32 %out
}

define i32 @protected_byref(i32 %a, i32 %b, i32 %k) noinline optnone {
entry:
  call void @hikari_vmp()
  %slot = alloca %pair, align 8
  %p0 = getelementptr inbounds %pair, ptr %slot, i32 0, i32 0
  %p1 = getelementptr inbounds %pair, ptr %slot, i32 0, i32 1
  store i32 %a, ptr %p0, align 4
  store i32 %b, ptr %p1, align 4
  %r = call i32 @sink_byref(ptr byref(%pair) align 8 %slot, i32 %k)
  %x = load i32, ptr %p0, align 4
  %y = load i32, ptr %p1, align 4
  %t = xor i32 %r, %x
  %out = xor i32 %t, %y
  ret i32 %out
}

define i32 @protected_byref_tail(i32 %a, i32 %b, i32 %k) noinline optnone {
entry:
  call void @hikari_vmp()
  %slot = alloca %pair, align 8
  %p0 = getelementptr inbounds %pair, ptr %slot, i32 0, i32 0
  %p1 = getelementptr inbounds %pair, ptr %slot, i32 0, i32 1
  store i32 %a, ptr %p0, align 4
  store i32 %b, ptr %p1, align 4
  %r = tail call i32 @sink_byref(ptr byref(%pair) align 8 %slot, i32 %k)
  %x = load i32, ptr %p0, align 4
  %y = load i32, ptr %p1, align 4
  %t = xor i32 %r, %x
  %out = xor i32 %t, %y
  ret i32 %out
}

define i32 @reference_noreturn(i32 %x, i1 %fail) noinline optnone {
entry:
  br i1 %fail, label %err, label %ok
err:
  call void @abort_now(i32 %x)
  unreachable
ok:
  store i32 %x, ptr @slot, align 4
  %v = load i32, ptr @slot, align 4
  %out = add i32 %v, 3
  ret i32 %out
}

define i32 @protected_noreturn(i32 %x, i1 %fail) noinline optnone {
entry:
  call void @hikari_vmp()
  br i1 %fail, label %err, label %ok
err:
  call void @abort_now(i32 %x)
  unreachable
ok:
  store i32 %x, ptr @slot, align 4
  %v = load i32, ptr @slot, align 4
  %out = add i32 %v, 3
  ret i32 %out
}

define i32 @protected_noreturn_tail(i32 %x, i1 %fail) noinline optnone {
entry:
  call void @hikari_vmp()
  br i1 %fail, label %err, label %ok
err:
  tail call void @abort_now(i32 %x)
  unreachable
ok:
  store i32 %x, ptr @slot, align 4
  %v = load i32, ptr @slot, align 4
  %out = add i32 %v, 3
  ret i32 %out
}

define i32 @reference_indirect(ptr %fp, i32 %x) noinline optnone {
entry:
  %r = call i32 %fp(i32 %x)
  ret i32 %r
}

define i32 @protected_indirect(ptr %fp, i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 %fp(i32 %x)
  ret i32 %r
}

define i32 @protected_indirect_tail(ptr %fp, i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = tail call i32 %fp(i32 %x)
  ret i32 %r
}

define bfloat @protected_bfloat_indirect(ptr %fp, bfloat %x) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = call bfloat %fp(bfloat %x)
  ret bfloat %r
}

define bfloat @protected_bfloat_indirect_tail(ptr %fp, bfloat %x) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = tail call bfloat %fp(bfloat %x)
  ret bfloat %r
}

define void @unsupported_sret_musttail(ptr sret(%pair) align 4 %p, i32 %a, i32 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  musttail call void @sink_sret(ptr sret(%pair) align 4 %p, i32 %a, i32 %b)
  ret void
}

define i32 @unsupported_indirect_musttail(ptr %fp, i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = musttail call i32 %fp(ptr %fp, i32 %x)
  ret i32 %r
}

define bfloat @unsupported_bfloat_indirect_musttail(ptr %fp, bfloat %x) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %r = musttail call bfloat %fp(ptr %fp, bfloat %x)
  ret bfloat %r
}

define i32 @unsupported_bfloat_indirect_tail_no_feature(ptr %fp, i16 %bits) noinline optnone {
entry:
  call void @hikari_vmp()
  %x = bitcast i16 %bits to bfloat
  %r = tail call bfloat %fp(bfloat %x)
  %t = bitcast bfloat %r to i16
  %z = zext i16 %t to i32
  ret i32 %z
}

define i32 @main() {
entry:
  %es = call i32 @reference_sret(i32 10, i32 20)
  %ps = call i32 @protected_sret(i32 10, i32 20)
  %ts = call i32 @protected_sret_tail(i32 10, i32 20)
  %oks0 = icmp eq i32 %es, %ps
  %oks1 = icmp eq i32 %es, %ts
  %oks = and i1 %oks0, %oks1
  %ev = call i32 @reference_byval(i32 10, i32 20, i32 3)
  %pv = call i32 @protected_byval(i32 10, i32 20, i32 3)
  %tv = call i32 @protected_byval_tail(i32 10, i32 20, i32 3)
  %okv0 = icmp eq i32 %ev, %pv
  %okv1 = icmp eq i32 %ev, %tv
  %okv = and i1 %okv0, %okv1
  %er = call i32 @reference_byref(i32 10, i32 20, i32 4)
  %pr = call i32 @protected_byref(i32 10, i32 20, i32 4)
  %tr = call i32 @protected_byref_tail(i32 10, i32 20, i32 4)
  %okr0 = icmp eq i32 %er, %pr
  %okr1 = icmp eq i32 %er, %tr
  %okr = and i1 %okr0, %okr1
  store i32 0, ptr @slot, align 4
  %en = call i32 @reference_noreturn(i32 7, i1 false)
  store i32 0, ptr @slot, align 4
  %pn = call i32 @protected_noreturn(i32 7, i1 false)
  store i32 0, ptr @slot, align 4
  %tn = call i32 @protected_noreturn_tail(i32 7, i1 false)
  %okn0 = icmp eq i32 %en, %pn
  %okn1 = icmp eq i32 %en, %tn
  %okn = and i1 %okn0, %okn1
  %ei = call i32 @reference_indirect(ptr @add_one, i32 9)
  %pi = call i32 @protected_indirect(ptr @add_one, i32 9)
  %ti = call i32 @protected_indirect_tail(ptr @add_one, i32 9)
  %oki0 = icmp eq i32 %ei, %pi
  %oki1 = icmp eq i32 %ei, %ti
  %oki = and i1 %oki0, %oki1
  %t0 = and i1 %oks, %okv
  %t1 = and i1 %okr, %okn
  %t2 = and i1 %t0, %t1
  %ok = and i1 %t2, %oki
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_sret_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_indirect_musttail: indirect call
; SKIP-DAG: Skipping VMP on unsupported_bfloat_indirect_musttail: indirect call
; SKIP-DAG: Skipping VMP on unsupported_bfloat_indirect_tail_no_feature: unsupported target feature
; SKIP-NOT: Skipping VMP on protected_sret:
; SKIP-NOT: Skipping VMP on protected_sret_tail:
; SKIP-NOT: Skipping VMP on protected_byval:
; SKIP-NOT: Skipping VMP on protected_byval_tail:
; SKIP-NOT: Skipping VMP on protected_byref:
; SKIP-NOT: Skipping VMP on protected_byref_tail:
; SKIP-NOT: Skipping VMP on protected_noreturn:
; SKIP-NOT: Skipping VMP on protected_noreturn_tail:
; SKIP-NOT: Skipping VMP on protected_indirect:
; SKIP-NOT: Skipping VMP on protected_indirect_tail:
; SKIP-NOT: Skipping VMP on protected_bfloat_indirect:
; SKIP-NOT: Skipping VMP on protected_bfloat_indirect_tail:

; VIRT-LABEL: define i32 @protected_sret(
; VIRT-SAME: #[[PROT:[0-9]+]]
; VIRT: vmp.dispatch:
; VIRT-NOT: tail call void @sink_sret(
; VIRT: call void @sink_sret(ptr sret(%pair) align 4
; VIRT-LABEL: define i32 @protected_sret_tail(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT-NOT: tail call void @sink_sret(
; VIRT: call void @sink_sret(ptr sret(%pair) align 4
; VIRT-LABEL: define i32 @protected_byval(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT-NOT: tail call i32 @sink_byval(
; VIRT: call i32 @sink_byval(ptr byval(%pair) align 8
; VIRT-LABEL: define i32 @protected_byval_tail(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT-NOT: tail call i32 @sink_byval(
; VIRT: call i32 @sink_byval(ptr byval(%pair) align 8
; VIRT-LABEL: define i32 @protected_byref(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT-NOT: tail call i32 @sink_byref(
; VIRT: call i32 @sink_byref(ptr byref(%pair) align 8
; VIRT-LABEL: define i32 @protected_byref_tail(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT-NOT: tail call i32 @sink_byref(
; VIRT: call i32 @sink_byref(ptr byref(%pair) align 8
; VIRT-LABEL: define i32 @protected_noreturn(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT-NOT: tail call void @abort_now(
; VIRT: call void @abort_now(
; VIRT-NEXT: unreachable
; VIRT-LABEL: define i32 @protected_noreturn_tail(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT-NOT: tail call void @abort_now(
; VIRT: call void @abort_now(
; VIRT-NEXT: unreachable
; VIRT-LABEL: define i32 @protected_indirect(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT-NOT: tail call i32
; VIRT: call i32 %{{.+}}(i32
; VIRT-LABEL: define i32 @protected_indirect_tail(
; VIRT-SAME: #[[PROT]]
; VIRT: vmp.dispatch:
; VIRT-NOT: tail call i32
; VIRT: call i32 %{{.+}}(i32
; VIRT-LABEL: define bfloat @protected_bfloat_indirect(
; VIRT-SAME: #[[PROTBF:[0-9]+]]
; VIRT: vmp.dispatch:
; VIRT-NOT: tail call bfloat
; VIRT: call bfloat %{{.+}}(bfloat
; VIRT-LABEL: define bfloat @protected_bfloat_indirect_tail(
; VIRT-SAME: #[[PROTBF]]
; VIRT: vmp.dispatch:
; VIRT-NOT: tail call bfloat
; VIRT: call bfloat %{{.+}}(bfloat
; VIRT-LABEL: define {{.*}} @unsupported_sret_musttail(
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call void @sink_sret(
; VIRT-LABEL: define {{.*}} @unsupported_indirect_musttail(
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call i32 %{{.+}}(
; VIRT-LABEL: define {{.*}} @unsupported_bfloat_indirect_musttail(
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call bfloat %{{.+}}(
; VIRT: define {{.*}} @unsupported_bfloat_indirect_tail_no_feature({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[PROTBF]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; HOST: Skipping VMP: only AArch64 targets are supported
