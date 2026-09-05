; Restricted AArch64 byref ABI: direct non-intrinsic non-vararg C
; CallInst with at least one AS0 ptr ByRef argument whose pointee type
; matches the callee formal.  Replayed through CallDescriptor
; (FunctionType / CC / AttributeList / byref type / align / metadata).
; reference calls reference_sink_byref; protected calls
; protected_sink_byref (same ABI, hikari_vmp on the sink) so VMP
; caller -> VMP byref callee is covered.  Callee stores through byref
; are visible to the caller.  A virtualized function's own byref
; argument stays an AS0 pointer VReg.  sret+byref / byval+byref / musttail /
; indirect / type or position mismatch stay rejected.
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

define i32 @reference_sink_byref(ptr byref(%pair) align 8 %p, i32 %k, i32 %m) noinline optnone {
entry:
  %f0 = getelementptr inbounds %pair, ptr %p, i32 0, i32 0
  %f1 = getelementptr inbounds %pair, ptr %p, i32 0, i32 1
  %x = load i32, ptr %f0, align 4
  %y = load i32, ptr %f1, align 4
  store i32 1, ptr %f0, align 4
  store i32 2, ptr %f1, align 4
  %t0 = xor i32 %x, %y
  %t1 = xor i32 %t0, %k
  %r = xor i32 %t1, %m
  ret i32 %r
}

define i32 @protected_sink_byref(ptr byref(%pair) align 8 %p, i32 %k, i32 %m) noinline optnone {
entry:
  call void @hikari_vmp()
  %f0 = getelementptr inbounds %pair, ptr %p, i32 0, i32 0
  %f1 = getelementptr inbounds %pair, ptr %p, i32 0, i32 1
  %x = load i32, ptr %f0, align 4
  %y = load i32, ptr %f1, align 4
  store i32 1, ptr %f0, align 4
  store i32 2, ptr %f1, align 4
  %t0 = xor i32 %x, %y
  %t1 = xor i32 %t0, %k
  %r = xor i32 %t1, %m
  ret i32 %r
}

define i32 @reference(i32 %a, i32 %b, i32 %k, i32 %m) noinline optnone {
entry:
  %slot = alloca %pair, align 8
  %p0 = getelementptr inbounds %pair, ptr %slot, i32 0, i32 0
  %p1 = getelementptr inbounds %pair, ptr %slot, i32 0, i32 1
  store i32 %a, ptr %p0, align 4
  store i32 %b, ptr %p1, align 4
  %r = call i32 @reference_sink_byref(ptr byref(%pair) align 8 %slot, i32 %k, i32 %m)
  %x = load i32, ptr %p0, align 4
  %y = load i32, ptr %p1, align 4
  %t0 = xor i32 %r, %x
  %out = xor i32 %t0, %y
  ret i32 %out
}

define i32 @protected(i32 %a, i32 %b, i32 %k, i32 %m) noinline optnone {
entry:
  call void @hikari_vmp()
  %slot = alloca %pair, align 8
  %p0 = getelementptr inbounds %pair, ptr %slot, i32 0, i32 0
  %p1 = getelementptr inbounds %pair, ptr %slot, i32 0, i32 1
  store i32 %a, ptr %p0, align 4
  store i32 %b, ptr %p1, align 4
  %r = call i32 @protected_sink_byref(ptr byref(%pair) align 8 %slot, i32 %k, i32 %m)
  %x = load i32, ptr %p0, align 4
  %y = load i32, ptr %p1, align 4
  %t0 = xor i32 %r, %x
  %out = xor i32 %t0, %y
  ret i32 %out
}

define void @sink_sret_byref(ptr sret(%pair) %p, ptr byref(%pair) %q) noinline {
entry:
  ret void
}

define i32 @sink_byval_byref(ptr byval(%pair) %p, ptr byref(%pair) %q) noinline {
entry:
  ret i32 0
}

define i32 @sink_byref_i32(ptr byref(i32) align 4 %p, i32 %k) noinline {
entry:
  ret i32 0
}

define i32 @sink_byref_left(ptr byref(%pair) align 8 %a, ptr %b) noinline {
entry:
  ret i32 0
}

define i32 @unsupported_byref_sret(ptr %p, ptr %q) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @sink_sret_byref(ptr sret(%pair) %p, ptr byref(%pair) %q)
  ret i32 0
}

define i32 @unsupported_byref_byval(ptr %p, ptr %q) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @sink_byval_byref(ptr byval(%pair) %p, ptr byref(%pair) %q)
  ret i32 %r
}


define i32 @unsupported_byref_indirect(ptr %fp, ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 %fp(ptr byref(%pair) %p)
  ret i32 %r
}

define i32 @unsupported_byref_type(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @sink_byref_i32(ptr byref(%pair) align 8 %p, i32 0)
  ret i32 %r
}

define i32 @unsupported_byref_pos(ptr %p, ptr %q) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @sink_byref_left(ptr %p, ptr byref(%pair) align 8 %q)
  ret i32 %r
}

define i32 @main() {
entry:
  %e0 = call i32 @reference(i32 10, i32 20, i32 3, i32 4)
  %a0 = call i32 @protected(i32 10, i32 20, i32 3, i32 4)
  %ok0 = icmp eq i32 %e0, %a0
  %e1 = call i32 @reference(i32 -1, i32 42, i32 7, i32 9)
  %a1 = call i32 @protected(i32 -1, i32 42, i32 7, i32 9)
  %ok1 = icmp eq i32 %e1, %a1
  %ok = and i1 %ok0, %ok1
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP-DAG: Skipping VMP on unsupported_byref_sret: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_byref_byval: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_byref_indirect: indirect call
; SKIP-DAG: Skipping VMP on unsupported_byref_type: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_byref_pos: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected:
; SKIP-NOT: Skipping VMP on protected_sink_byref:
; SKIP-NOT: Skipping VMP on reference:
; SKIP-NOT: Skipping VMP on reference_sink_byref:

; VIRT-LABEL: define i32 @protected_sink_byref(
; VIRT: %vmp.ptr.regs = alloca
; VIRT: store volatile ptr %p
; VIRT-NOT: store volatile %pair %p
; VIRT: vmp.dispatch:

; VIRT-LABEL: define i32 @protected(
; VIRT: %vmp.ptr.regs = alloca
; VIRT: vmp.dispatch:
; VIRT: call i32 @protected_sink_byref(ptr byref(%pair) align 8

; VIRT: define i32 @unsupported_byref_sret({{.*}} #[[UNSUPATTR:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define i32 @unsupported_byref_byval({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define i32 @unsupported_byref_indirect({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define i32 @unsupported_byref_type({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define i32 @unsupported_byref_pos({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #{{[0-9]+}} = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.virtualized"
