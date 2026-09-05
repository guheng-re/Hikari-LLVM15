; Restricted AArch64 VMP nounwind invoke + conservative direct sret:
;   void fixed-arity exact FunctionType, CallingConv::C on both the
;   invoke site and the callee, argument 0 is AS0 ptr with matching
;   sret type/attribute on declaration and invocation, nounwind, and
;   the existing minimal unreachable landingpad island.
; Replayed as the existing CallDescriptor CreateCall (sret attribute
; and output pointer preserved) plus a VM Br to the normal dest.
; Ordinary non-sret nounwind invoke is unchanged.  byval / byref /
; preallocated / inalloca / swifterror / vararg / tail / musttail,
; throwing or reachable EH, and non-AArch64 stay rejected.
; No new opcode.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.ll -o %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.live.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.ll -o %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.live.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.s7.ll -o %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.s7.live.ll > %t.o0.s7.host.ll
; RUN: lli -force-interpreter %t.o0.s7.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.s7.ll -o %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.s7.live.ll > %t.o2.s7.host.ll
; RUN: lli -force-interpreter %t.o2.s7.host.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %s | opt -S -verify-each -aesSeed=97 -passes='default<O0>' - 2>&1 | FileCheck %s --check-prefix=HOST

target triple = "aarch64-unknown-linux-gnu"

%pair = type { i32, i32 }

declare void @hikari_vmp()
declare void @hikari_fla()
declare i32 @__gxx_personality_v0(...)
declare void @may_throw()
declare void @fill_throwing_sret(ptr sret(%pair), i32, i32)
declare void @sink_sret_vararg(ptr sret(%pair), ...) nounwind

@handler_sink = global i32 0, align 4

define void @nounwind_fill_sret(ptr sret(%pair) align 4 %p, i32 %a, i32 %b) nounwind noinline optnone {
entry:
  %f0 = getelementptr inbounds %pair, ptr %p, i32 0, i32 0
  %f1 = getelementptr inbounds %pair, ptr %p, i32 0, i32 1
  store i32 %a, ptr %f0, align 4
  store i32 %b, ptr %f1, align 4
  ret void
}

define void @sink_sret_byval(ptr sret(%pair) %p, ptr byval(%pair) %q) nounwind noinline {
entry:
  ret void
}

define void @sink_sret_byref(ptr sret(%pair) %p, ptr byref(%pair) %q) nounwind noinline {
entry:
  ret void
}

define void @sink_sret_swifterror(ptr sret(%pair) %p, ptr swifterror %err) nounwind noinline {
entry:
  ret void
}

define void @sink_sret_second(i32 %x, ptr sret(%pair) %p) nounwind noinline {
entry:
  ret void
}

define fastcc void @sink_sret_fastcc(ptr sret(%pair) %p, i32 %a, i32 %b) nounwind noinline {
entry:
  ret void
}

define i32 @reference_sret(i32 %a, i32 %b) {
entry:
  %slot = alloca %pair, align 4
  call void @nounwind_fill_sret(ptr sret(%pair) align 4 %slot, i32 %a, i32 %b)
  %p0 = getelementptr inbounds %pair, ptr %slot, i32 0, i32 0
  %p1 = getelementptr inbounds %pair, ptr %slot, i32 0, i32 1
  %x = load i32, ptr %p0, align 4
  %y = load i32, ptr %p1, align 4
  %out = xor i32 %x, %y
  ret i32 %out
}

define i32 @protected_sret(i32 %a, i32 %b) noinline optnone personality ptr @__gxx_personality_v0 {
entry:
  call void @hikari_vmp()
  %slot = alloca %pair, align 4
  invoke void @nounwind_fill_sret(ptr sret(%pair) align 4 %slot, i32 %a, i32 %b)
          to label %cont unwind label %lpad
cont:
  %p0 = getelementptr inbounds %pair, ptr %slot, i32 0, i32 0
  %p1 = getelementptr inbounds %pair, ptr %slot, i32 0, i32 1
  %x = load i32, ptr %p0, align 4
  %y = load i32, ptr %p1, align 4
  %out = xor i32 %x, %y
  ret i32 %out
lpad:
  %lp = landingpad { ptr, i32 }
          cleanup
  resume { ptr, i32 } %lp
}

define void @reference_self_sret(ptr sret(%pair) align 4 %out, i32 %a, i32 %b) {
entry:
  call void @nounwind_fill_sret(ptr sret(%pair) align 4 %out, i32 %a, i32 %b)
  ret void
}

define void @protected_self_sret(ptr sret(%pair) align 4 %out, i32 %a, i32 %b) noinline optnone personality ptr @__gxx_personality_v0 {
entry:
  call void @hikari_vmp()
  invoke void @nounwind_fill_sret(ptr sret(%pair) align 4 %out, i32 %a, i32 %b)
          to label %cont unwind label %lpad
cont:
  ret void
lpad:
  %lp = landingpad { ptr, i32 }
          cleanup
  resume { ptr, i32 } %lp
}

define i32 @protected_sret_cff(i32 %a, i32 %b) noinline optnone personality ptr @__gxx_personality_v0 {
entry:
  call void @hikari_vmp()
  call void @hikari_fla()
  %slot = alloca %pair, align 4
  invoke void @nounwind_fill_sret(ptr sret(%pair) align 4 %slot, i32 %a, i32 %b)
          to label %cont unwind label %lpad
cont:
  %p0 = getelementptr inbounds %pair, ptr %slot, i32 0, i32 0
  %p1 = getelementptr inbounds %pair, ptr %slot, i32 0, i32 1
  %x = load i32, ptr %p0, align 4
  %y = load i32, ptr %p1, align 4
  %out = xor i32 %x, %y
  ret i32 %out
lpad:
  %lp = landingpad { ptr, i32 }
          cleanup
  resume { ptr, i32 } %lp
}

define i32 @unsupported_sret_byval(ptr %p, ptr %q) noinline optnone personality ptr @__gxx_personality_v0 {
entry:
  call void @hikari_vmp()
  invoke void @sink_sret_byval(ptr sret(%pair) %p, ptr byval(%pair) %q)
          to label %cont unwind label %lpad
cont:
  ret i32 0
lpad:
  %lp = landingpad { ptr, i32 }
          cleanup
  resume { ptr, i32 } %lp
}

define i32 @unsupported_sret_byref(ptr %p, ptr %q) noinline optnone personality ptr @__gxx_personality_v0 {
entry:
  call void @hikari_vmp()
  invoke void @sink_sret_byref(ptr sret(%pair) %p, ptr byref(%pair) %q)
          to label %cont unwind label %lpad
cont:
  ret i32 0
lpad:
  %lp = landingpad { ptr, i32 }
          cleanup
  resume { ptr, i32 } %lp
}

define i32 @unsupported_sret_swifterror(ptr swifterror %err) noinline optnone personality ptr @__gxx_personality_v0 {
entry:
  call void @hikari_vmp()
  %slot = alloca %pair, align 4
  invoke void @sink_sret_swifterror(ptr sret(%pair) %slot, ptr swifterror %err)
          to label %cont unwind label %lpad
cont:
  ret i32 0
lpad:
  %lp = landingpad { ptr, i32 }
          cleanup
  resume { ptr, i32 } %lp
}

define i32 @unsupported_sret_not_first(ptr %p) noinline optnone personality ptr @__gxx_personality_v0 {
entry:
  call void @hikari_vmp()
  invoke void @sink_sret_second(i32 0, ptr sret(%pair) %p)
          to label %cont unwind label %lpad
cont:
  ret i32 0
lpad:
  %lp = landingpad { ptr, i32 }
          cleanup
  resume { ptr, i32 } %lp
}

define i32 @unsupported_sret_fastcc_site(i32 %a, i32 %b) noinline optnone personality ptr @__gxx_personality_v0 {
entry:
  call void @hikari_vmp()
  %slot = alloca %pair, align 4
  invoke fastcc void @nounwind_fill_sret(ptr sret(%pair) align 4 %slot, i32 %a, i32 %b)
          to label %cont unwind label %lpad
cont:
  ret i32 0
lpad:
  %lp = landingpad { ptr, i32 }
          cleanup
  resume { ptr, i32 } %lp
}

define i32 @unsupported_sret_fastcc_callee(i32 %a, i32 %b) noinline optnone personality ptr @__gxx_personality_v0 {
entry:
  call void @hikari_vmp()
  %slot = alloca %pair, align 4
  invoke void @sink_sret_fastcc(ptr sret(%pair) %slot, i32 %a, i32 %b)
          to label %cont unwind label %lpad
cont:
  ret i32 0
lpad:
  %lp = landingpad { ptr, i32 }
          cleanup
  resume { ptr, i32 } %lp
}

define i32 @unsupported_sret_vararg(i32 %x) noinline optnone personality ptr @__gxx_personality_v0 {
entry:
  call void @hikari_vmp()
  %slot = alloca %pair, align 4
  invoke void (ptr, ...) @sink_sret_vararg(ptr sret(%pair) %slot, i32 %x)
          to label %cont unwind label %lpad
cont:
  ret i32 %x
lpad:
  %lp = landingpad { ptr, i32 }
          cleanup
  resume { ptr, i32 } %lp
}

define i32 @unsupported_sret_throwing(i32 %a, i32 %b) noinline optnone personality ptr @__gxx_personality_v0 {
entry:
  call void @hikari_vmp()
  %slot = alloca %pair, align 4
  invoke void @fill_throwing_sret(ptr sret(%pair) align 4 %slot, i32 %a, i32 %b)
          to label %cont unwind label %lpad
cont:
  ret i32 0
lpad:
  %lp = landingpad { ptr, i32 }
          cleanup
  resume { ptr, i32 } %lp
}

define i32 @unsupported_sret_reachable(i32 %a, i32 %b) noinline optnone personality ptr @__gxx_personality_v0 {
entry:
  call void @hikari_vmp()
  %slot = alloca %pair, align 4
  invoke void @nounwind_fill_sret(ptr sret(%pair) align 4 %slot, i32 %a, i32 %b)
          to label %cont unwind label %lpad
cont:
  ret i32 0
lpad:
  %lp = landingpad { ptr, i32 }
          cleanup
  store volatile i32 1, ptr @handler_sink, align 4
  resume { ptr, i32 } %lp
}

define i32 @main() {
entry:
  %e0 = call i32 @reference_sret(i32 10, i32 20)
  %a0 = call i32 @protected_sret(i32 10, i32 20)
  %e1 = call i32 @reference_sret(i32 -1, i32 42)
  %a1 = call i32 @protected_sret(i32 -1, i32 42)
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
  %e2 = call i32 @reference_sret(i32 3, i32 5)
  %a2 = call i32 @protected_sret_cff(i32 3, i32 5)
  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %e1, %a1
  %mx = icmp eq i32 %rx, %px
  %my = icmp eq i32 %ry, %py
  %m2 = icmp eq i32 %e2, %a2
  %t0 = and i1 %m0, %m1
  %t1 = and i1 %mx, %my
  %t2 = and i1 %t0, %t1
  %ok = and i1 %t2, %m2
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP-DAG: Skipping VMP on unsupported_sret_byval: exception handling
; SKIP-DAG: Skipping VMP on unsupported_sret_byref: exception handling
; SKIP-DAG: Skipping VMP on unsupported_sret_swifterror: exception handling
; SKIP-DAG: Skipping VMP on unsupported_sret_not_first: exception handling
; SKIP-DAG: Skipping VMP on unsupported_sret_fastcc_site: exception handling
; SKIP-DAG: Skipping VMP on unsupported_sret_fastcc_callee: exception handling
; SKIP-DAG: Skipping VMP on unsupported_sret_vararg: exception handling
; SKIP-DAG: Skipping VMP on unsupported_sret_throwing: exception handling
; SKIP-DAG: Skipping VMP on unsupported_sret_reachable: exception handling
; SKIP-NOT: Skipping VMP on protected_sret:
; SKIP-NOT: Skipping VMP on protected_self_sret:
; SKIP-NOT: Skipping VMP on protected_sret_cff:
; SKIP-NOT: Skipping VMP on nounwind_fill_sret:
; SKIP-NOT: Skipping VMP on reference_sret:

; VIRT: define i32 @protected_sret({{.*}} #[[PROT:[0-9]+]] personality ptr @__gxx_personality_v0 {
; VIRT: vmp.dispatch:
; VIRT: call void @nounwind_fill_sret(ptr sret(%pair) align 4
; VIRT-NOT: invoke
; VIRT-NOT: landingpad
; VIRT: define void @protected_self_sret({{.*}} #[[PROT]] personality ptr @__gxx_personality_v0 {
; VIRT: store volatile ptr %out
; VIRT-NOT: store volatile %pair %out
; VIRT: vmp.dispatch:
; VIRT: call void @nounwind_fill_sret(ptr sret(%pair) align 4
; VIRT: define i32 @protected_sret_cff({{.*}} #[[CFF:[0-9]+]] personality ptr @__gxx_personality_v0 {
; VIRT: vmp.post.cff.opcode
; VIRT: define i32 @unsupported_sret_byval({{.*}} #[[UNSUP:[0-9]+]] personality ptr @__gxx_personality_v0 {
; VIRT-NOT: vmp.dispatch
; VIRT: define i32 @unsupported_sret_byref({{.*}} #[[UNSUP]] personality ptr @__gxx_personality_v0 {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT: attributes #[[CFF]] = { {{.*}}"hikari.vmp.post.cff.applied"{{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; HOST: Skipping VMP: only AArch64 targets are supported
