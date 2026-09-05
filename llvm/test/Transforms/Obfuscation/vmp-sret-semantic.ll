; Restricted AArch64 sret ABI: direct non-intrinsic non-vararg C void
; CallInst whose argument 0 is AS0 ptr with matching StructRet on the
; call site and the callee formal.  Replayed through the existing
; CallDescriptor (FunctionType / CC / AttributeList / align / metadata).
; reference calls reference_sink_sret; protected calls protected_sink_sret
; (same ABI, hikari_vmp on the sink) so VMP caller -> VMP sret callee is
; covered.  A virtualized function's own sret argument stays an AS0
; pointer VReg; the pointee is never an aggregate VReg.  Matching
; byval-only lives in vmp-byval-semantic.ll.  sret+byval / byref /
; non-C / sret-not-first / musttail / indirect stay rejected.
; Ordinary tail is a hint and is replayed as TCK_None.
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

%pair = type { i32, i32 }

declare void @hikari_vmp()

define void @reference_sink_sret(ptr sret(%pair) align 4 %p, i32 %a, i32 %b) noinline optnone {
entry:
  %f0 = getelementptr inbounds %pair, ptr %p, i32 0, i32 0
  %f1 = getelementptr inbounds %pair, ptr %p, i32 0, i32 1
  store i32 %a, ptr %f0, align 4
  store i32 %b, ptr %f1, align 4
  ret void
}

define void @protected_sink_sret(ptr sret(%pair) align 4 %p, i32 %a, i32 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %f0 = getelementptr inbounds %pair, ptr %p, i32 0, i32 0
  %f1 = getelementptr inbounds %pair, ptr %p, i32 0, i32 1
  store i32 %a, ptr %f0, align 4
  store i32 %b, ptr %f1, align 4
  ret void
}

define i32 @reference(i32 %a, i32 %b) noinline optnone {
entry:
  %slot = alloca %pair, align 4
  call void @reference_sink_sret(ptr sret(%pair) align 4 %slot, i32 %a, i32 %b)
  %p0 = getelementptr inbounds %pair, ptr %slot, i32 0, i32 0
  %p1 = getelementptr inbounds %pair, ptr %slot, i32 0, i32 1
  %x = load i32, ptr %p0, align 4
  %y = load i32, ptr %p1, align 4
  %out = xor i32 %x, %y
  ret i32 %out
}

define i32 @protected(i32 %a, i32 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %slot = alloca %pair, align 4
  call void @protected_sink_sret(ptr sret(%pair) align 4 %slot, i32 %a, i32 %b)
  %p0 = getelementptr inbounds %pair, ptr %slot, i32 0, i32 0
  %p1 = getelementptr inbounds %pair, ptr %slot, i32 0, i32 1
  %x = load i32, ptr %p0, align 4
  %y = load i32, ptr %p1, align 4
  %out = xor i32 %x, %y
  ret i32 %out
}

; The function itself carries sret: incoming pointer only, no aggregate
; return object.
define void @reference_self_sret(ptr sret(%pair) align 4 %out, i32 %a, i32 %b) noinline optnone {
entry:
  %f0 = getelementptr inbounds %pair, ptr %out, i32 0, i32 0
  %f1 = getelementptr inbounds %pair, ptr %out, i32 0, i32 1
  store i32 %a, ptr %f0, align 4
  store i32 %b, ptr %f1, align 4
  ret void
}

define void @protected_self_sret(ptr sret(%pair) align 4 %out, i32 %a, i32 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %f0 = getelementptr inbounds %pair, ptr %out, i32 0, i32 0
  %f1 = getelementptr inbounds %pair, ptr %out, i32 0, i32 1
  store i32 %a, ptr %f0, align 4
  store i32 %b, ptr %f1, align 4
  ret void
}

define void @sink_sret_byval(ptr sret(%pair) %p, ptr byval(%pair) %q) noinline {
entry:
  ret void
}

define fastcc void @sink_sret_fastcc(ptr sret(%pair) %p) noinline {
entry:
  ret void
}

define void @sink_sret_second(i32 %x, ptr sret(%pair) %p) noinline {
entry:
  ret void
}

define i32 @unsupported_sret_byval(ptr %p, ptr %q) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @sink_sret_byval(ptr sret(%pair) %p, ptr byval(%pair) %q)
  ret i32 0
}

define i32 @unsupported_sret_fastcc(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @sink_sret_fastcc(ptr sret(%pair) %p)
  ret i32 0
}

define i32 @unsupported_sret_not_first(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @sink_sret_second(i32 0, ptr sret(%pair) %p)
  ret i32 0
}


define i32 @unsupported_sret_indirect(ptr %fp, ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  call void %fp(ptr sret(%pair) %p)
  ret i32 0
}

define i32 @main() {
entry:
  %e0 = call i32 @reference(i32 10, i32 20)
  %a0 = call i32 @protected(i32 10, i32 20)
  %ok0 = icmp eq i32 %e0, %a0
  %e1 = call i32 @reference(i32 -1, i32 42)
  %a1 = call i32 @protected(i32 -1, i32 42)
  %ok1 = icmp eq i32 %e1, %a1
  %rs = alloca %pair, align 4
  %ps = alloca %pair, align 4
  call void @reference_self_sret(ptr sret(%pair) align 4 %rs, i32 7, i32 9)
  call void @protected_self_sret(ptr sret(%pair) align 4 %ps, i32 7, i32 9)
  %r0p = getelementptr inbounds %pair, ptr %rs, i32 0, i32 0
  %r1p = getelementptr inbounds %pair, ptr %rs, i32 0, i32 1
  %p0p = getelementptr inbounds %pair, ptr %ps, i32 0, i32 0
  %p1p = getelementptr inbounds %pair, ptr %ps, i32 0, i32 1
  %rx = load i32, ptr %r0p, align 4
  %ry = load i32, ptr %r1p, align 4
  %px = load i32, ptr %p0p, align 4
  %py = load i32, ptr %p1p, align 4
  %okx = icmp eq i32 %rx, %px
  %oky = icmp eq i32 %ry, %py
  %t0 = and i1 %ok0, %ok1
  %t1 = and i1 %t0, %okx
  %ok = and i1 %t1, %oky
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP-DAG: Skipping VMP on unsupported_sret_byval: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_sret_fastcc: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_sret_not_first: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_sret_indirect: indirect call
; SKIP-NOT: Skipping VMP on protected:
; SKIP-NOT: Skipping VMP on protected_sink_sret:
; SKIP-NOT: Skipping VMP on protected_self_sret:
; SKIP-NOT: Skipping VMP on reference:
; SKIP-NOT: Skipping VMP on reference_sink_sret:
; SKIP-NOT: Skipping VMP on reference_self_sret:

; VIRT-LABEL: define void @protected_sink_sret(
; VIRT: %vmp.ptr.regs = alloca
; VIRT: store volatile ptr %p
; VIRT-NOT: store volatile %pair %p
; VIRT: vmp.dispatch:

; VIRT-LABEL: define i32 @protected(
; VIRT: %vmp.ptr.regs = alloca
; VIRT: vmp.dispatch:
; VIRT: call void @protected_sink_sret(ptr sret(%pair) align 4

; VIRT-LABEL: define void @protected_self_sret(
; VIRT: %vmp.ptr.regs = alloca
; VIRT: store volatile ptr %out
; VIRT-NOT: store volatile %pair %out
; VIRT: vmp.dispatch:

; VIRT: define i32 @unsupported_sret_byval({{.*}} #[[UNSUPATTR:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define i32 @unsupported_sret_fastcc({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define i32 @unsupported_sret_not_first({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define i32 @unsupported_sret_indirect({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #{{[0-9]+}} = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.virtualized"
