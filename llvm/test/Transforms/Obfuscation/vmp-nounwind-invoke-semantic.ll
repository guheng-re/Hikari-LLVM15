; Restricted AArch64 VMP nounwind direct invoke:
;   InvokeInst only when callee/callsite is nounwind, BOTH the invoke
;   site and the direct callee Function are CallingConv::C, the invoke
;   FunctionType is exactly the callee FunctionType, the call otherwise
;   matches the ordinary direct-call ABI/type surface, it is not
;   tail/musttail/bundled/noreturn/returns_twice/inline-asm/vararg/
;   complex ABI, and the unwind dest is a minimal unreachable EH-only
;   island (landingpad + in-block extractvalue + resume/unreachable,
;   no normal predecessor, no live PHI/outside use).
; Lowered transactionally to the existing CallDescriptor CreateCall
; plus a VM PC transfer to the normal dest.  The unwind edge is never
; generated or executed.  Personality is preserved.  Reachable
; Itanium invoke/landingpad/resume is vmp-itanium-invoke-semantic.ll
; and must not stay here as a well-formed skip.  Windows pads and
; malformed EH CFG stay "exception handling".  Restricted InlineAsm
; CallBr is vmp-inline-asm-callbr-semantic.ll (not this family).
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

declare void @hikari_vmp()
declare void @hikari_fla()
declare i32 @__gxx_personality_v0(...)
declare i32 @__gcc_personality_v0(...)
declare void @vsum(i32, ...)
declare void @fill_sret(ptr sret(i32))
declare i128 @id_i128(i128)
declare void @may_throw()

@sink = global i32 0, align 4
@handler_sink = global i32 0, align 4

define i32 @nounwind_add(i32 %x) nounwind noinline optnone {
entry:
  %r = add i32 %x, 1
  ret i32 %r
}

define void @nounwind_sink(i32 %x) nounwind noinline optnone {
entry:
  store volatile i32 %x, ptr @sink, align 4
  ret void
}

define i32 @reference_add(i32 %x) {
entry:
  %r = call i32 @nounwind_add(i32 %x)
  ret i32 %r
}

define i32 @protected_add(i32 %x) noinline optnone personality ptr @__gxx_personality_v0 {
entry:
  call void @hikari_vmp()
  %r = invoke i32 @nounwind_add(i32 %x)
          to label %cont unwind label %lpad
cont:
  ret i32 %r
lpad:
  %lp = landingpad { ptr, i32 }
          cleanup
  resume { ptr, i32 } %lp
}

define i32 @reference_phi(i1 %c, i32 %x) {
entry:
  br i1 %c, label %left, label %right
left:
  %lv = call i32 @nounwind_add(i32 %x)
  br label %join
right:
  %rv = add i32 %x, 2
  br label %join
join:
  %v = phi i32 [ %lv, %left ], [ %rv, %right ]
  ret i32 %v
}

define i32 @protected_phi(i1 %c, i32 %x) noinline optnone personality ptr @__gxx_personality_v0 {
entry:
  call void @hikari_vmp()
  br i1 %c, label %left, label %right
left:
  %lv = invoke i32 @nounwind_add(i32 %x)
          to label %left.cont unwind label %lpad
left.cont:
  br label %join
right:
  %rv = add i32 %x, 2
  br label %join
join:
  %v = phi i32 [ %lv, %left.cont ], [ %rv, %right ]
  ret i32 %v
lpad:
  %lp = landingpad { ptr, i32 }
          cleanup
  resume { ptr, i32 } %lp
}

define i32 @reference_shared(i32 %x) {
entry:
  %a = call i32 @nounwind_add(i32 %x)
  %b = call i32 @nounwind_add(i32 %a)
  ret i32 %b
}

define i32 @protected_shared(i32 %x) noinline optnone personality ptr @__gxx_personality_v0 {
entry:
  call void @hikari_vmp()
  %a = invoke i32 @nounwind_add(i32 %x)
          to label %mid unwind label %lpad
mid:
  %b = invoke i32 @nounwind_add(i32 %a)
          to label %end unwind label %lpad
end:
  ret i32 %b
lpad:
  %lp = landingpad { ptr, i32 }
          cleanup
  resume { ptr, i32 } %lp
}

define i32 @protected_extract(i32 %x) noinline optnone personality ptr @__gcc_personality_v0 {
entry:
  call void @hikari_vmp()
  %r = invoke i32 @nounwind_add(i32 %x)
          to label %cont unwind label %lpad
cont:
  ret i32 %r
lpad:
  %lp = landingpad { ptr, i32 }
          cleanup
  %exn = extractvalue { ptr, i32 } %lp, 0
  %sel = extractvalue { ptr, i32 } %lp, 1
  resume { ptr, i32 } %lp
}

define i32 @protected_unreach(i32 %x) noinline optnone personality ptr @__gxx_personality_v0 {
entry:
  call void @hikari_vmp()
  %r = invoke i32 @nounwind_add(i32 %x)
          to label %cont unwind label %lpad
cont:
  ret i32 %r
lpad:
  %lp = landingpad { ptr, i32 }
          cleanup
  unreachable
}

define i32 @protected_void(i32 %x) noinline optnone personality ptr @__gxx_personality_v0 {
entry:
  call void @hikari_vmp()
  invoke void @nounwind_sink(i32 %x)
          to label %cont unwind label %lpad
cont:
  %v = load volatile i32, ptr @sink, align 4
  ret i32 %v
lpad:
  %lp = landingpad { ptr, i32 }
          cleanup
  resume { ptr, i32 } %lp
}

define i32 @protected_cff(i32 %x) noinline optnone personality ptr @__gxx_personality_v0 {
entry:
  call void @hikari_vmp()
  call void @hikari_fla()
  %r = invoke i32 @nounwind_add(i32 %x)
          to label %cont unwind label %lpad
cont:
  ret i32 %r
lpad:
  %lp = landingpad { ptr, i32 }
          cleanup
  resume { ptr, i32 } %lp
}

; Well-formed reachable Itanium invoke/landingpad/resume is
; vmp-itanium-invoke-semantic.ll.

define i32 @unsupported_indirect(ptr %fp, i32 %x) noinline optnone personality ptr @__gxx_personality_v0 {
entry:
  call void @hikari_vmp()
  %r = invoke i32 %fp(i32 %x)
          to label %cont unwind label %lpad
cont:
  ret i32 %r
lpad:
  %lp = landingpad { ptr, i32 }
          cleanup
  resume { ptr, i32 } %lp
}

define i32 @unsupported_vararg(i32 %x) noinline optnone personality ptr @__gxx_personality_v0 {
entry:
  call void @hikari_vmp()
  invoke void (i32, ...) @vsum(i32 %x, i32 1)
          to label %cont unwind label %lpad
cont:
  ret i32 %x
lpad:
  %lp = landingpad { ptr, i32 }
          cleanup
  resume { ptr, i32 } %lp
}

define i32 @unsupported_sret(i32 %x) noinline optnone personality ptr @__gxx_personality_v0 {
entry:
  call void @hikari_vmp()
  %slot = alloca i32, align 4
  invoke void @fill_sret(ptr sret(i32) %slot)
          to label %cont unwind label %lpad
cont:
  %v = load i32, ptr %slot, align 4
  ret i32 %v
lpad:
  %lp = landingpad { ptr, i32 }
          cleanup
  resume { ptr, i32 } %lp
}

define i128 @unsupported_i128(i128 %x) noinline optnone personality ptr @__gxx_personality_v0 {
entry:
  call void @hikari_vmp()
  %r = invoke i128 @id_i128(i128 %x)
          to label %cont unwind label %lpad
cont:
  ret i128 %r
lpad:
  %lp = landingpad { ptr, i32 }
          cleanup
  resume { ptr, i32 } %lp
}

define i32 @unsupported_bundle(i32 %x) noinline optnone personality ptr @__gxx_personality_v0 {
entry:
  call void @hikari_vmp()
  %r = invoke i32 @nounwind_add(i32 %x) [ "deopt"() ]
          to label %cont unwind label %lpad
cont:
  ret i32 %r
lpad:
  %lp = landingpad { ptr, i32 }
          cleanup
  resume { ptr, i32 } %lp
}

define i32 @unsupported_noreturn(i32 %x) noinline optnone personality ptr @__gxx_personality_v0 {
entry:
  call void @hikari_vmp()
  invoke void @nounwind_sink(i32 %x) noreturn
          to label %cont unwind label %lpad
cont:
  ret i32 %x
lpad:
  %lp = landingpad { ptr, i32 }
          cleanup
  resume { ptr, i32 } %lp
}

define fastcc i32 @fastcc_add(i32 %x) nounwind noinline optnone {
entry:
  %r = add i32 %x, 1
  ret i32 %r
}

; fastcc on the invoke site; callee stays C.
define i32 @unsupported_fastcc_site(i32 %x) noinline optnone personality ptr @__gxx_personality_v0 {
entry:
  call void @hikari_vmp()
  %r = invoke fastcc i32 @nounwind_add(i32 %x)
          to label %cont unwind label %lpad
cont:
  ret i32 %r
lpad:
  %lp = landingpad { ptr, i32 }
          cleanup
  resume { ptr, i32 } %lp
}

; C invoke of a fastcc callee definition.
define i32 @unsupported_fastcc_callee(i32 %x) noinline optnone personality ptr @__gxx_personality_v0 {
entry:
  call void @hikari_vmp()
  %r = invoke i32 @fastcc_add(i32 %x)
          to label %cont unwind label %lpad
cont:
  ret i32 %r
lpad:
  %lp = landingpad { ptr, i32 }
          cleanup
  resume { ptr, i32 } %lp
}

; Representable opaque-pointer prototype mismatch: direct Function*
; whose FunctionType is i32(i32), invoke FunctionType is i32(i64).
define i32 @unsupported_ftype_mismatch(i64 %x) noinline optnone personality ptr @__gxx_personality_v0 {
entry:
  call void @hikari_vmp()
  %r = invoke i32 (i64) @nounwind_add(i64 %x)
          to label %cont unwind label %lpad
cont:
  ret i32 %r
lpad:
  %lp = landingpad { ptr, i32 }
          cleanup
  resume { ptr, i32 } %lp
}

define i32 @main() {
entry:
  %e0 = call i32 @reference_add(i32 4)
  %a0 = call i32 @protected_add(i32 4)
  %e1 = call i32 @reference_phi(i1 true, i32 10)
  %a1 = call i32 @protected_phi(i1 true, i32 10)
  %e2 = call i32 @reference_phi(i1 false, i32 10)
  %a2 = call i32 @protected_phi(i1 false, i32 10)
  %e3 = call i32 @reference_shared(i32 3)
  %a3 = call i32 @protected_shared(i32 3)
  %e4 = call i32 @reference_add(i32 7)
  %a4 = call i32 @protected_extract(i32 7)
  %e5 = call i32 @reference_add(i32 8)
  %a5 = call i32 @protected_unreach(i32 8)
  %a6 = call i32 @protected_void(i32 9)
  %e7 = call i32 @reference_add(i32 4)
  %a7 = call i32 @protected_cff(i32 4)
  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %e1, %a1
  %m2 = icmp eq i32 %e2, %a2
  %m3 = icmp eq i32 %e3, %a3
  %m4 = icmp eq i32 %e4, %a4
  %m5 = icmp eq i32 %e5, %a5
  %m6 = icmp eq i32 %a6, 9
  %m7 = icmp eq i32 %e7, %a7
  %t0 = and i1 %m0, %m1
  %t1 = and i1 %m2, %m3
  %t2 = and i1 %m4, %m5
  %t3 = and i1 %m6, %m7
  %t4 = and i1 %t0, %t1
  %t5 = and i1 %t2, %t3
  %ok = and i1 %t4, %t5
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP-DAG: Skipping VMP on unsupported_indirect: exception handling
; SKIP-DAG: Skipping VMP on unsupported_vararg: exception handling
; SKIP-DAG: Skipping VMP on unsupported_sret: exception handling
; SKIP-DAG: Skipping VMP on unsupported_i128: exception handling
; SKIP-DAG: Skipping VMP on unsupported_bundle: exception handling
; SKIP-DAG: Skipping VMP on unsupported_noreturn: exception handling
; SKIP-DAG: Skipping VMP on unsupported_fastcc_site: exception handling
; SKIP-DAG: Skipping VMP on unsupported_fastcc_callee: exception handling
; SKIP-DAG: Skipping VMP on unsupported_ftype_mismatch: exception handling
; SKIP-NOT: Skipping VMP on protected_add:
; SKIP-NOT: Skipping VMP on protected_phi:
; SKIP-NOT: Skipping VMP on protected_shared:
; SKIP-NOT: Skipping VMP on protected_extract:
; SKIP-NOT: Skipping VMP on protected_unreach:
; SKIP-NOT: Skipping VMP on protected_void:
; SKIP-NOT: Skipping VMP on protected_cff:
; SKIP-NOT: Skipping VMP on nounwind_add:
; SKIP-NOT: Skipping VMP on reference_add:

; VIRT: define i32 @protected_add({{.*}} #[[PROT:[0-9]+]] personality ptr @__gxx_personality_v0 {
; VIRT: vmp.dispatch:
; VIRT: call i32 @nounwind_add(i32
; VIRT-NOT: invoke
; VIRT-NOT: landingpad
; VIRT: define i32 @protected_phi({{.*}} #[[PROT]] personality ptr @__gxx_personality_v0 {
; VIRT: vmp.dispatch:
; VIRT: define i32 @protected_shared({{.*}} #[[PROT]] personality ptr @__gxx_personality_v0 {
; VIRT: vmp.dispatch:
; VIRT: define i32 @protected_extract({{.*}} #[[PROT]] personality ptr @__gcc_personality_v0 {
; VIRT: vmp.dispatch:
; VIRT: define i32 @protected_unreach({{.*}} #[[PROT]] personality ptr @__gxx_personality_v0 {
; VIRT: vmp.dispatch:
; VIRT: define i32 @protected_void({{.*}} #[[PROT]] personality ptr @__gxx_personality_v0 {
; VIRT: vmp.dispatch:
; VIRT: call void @nounwind_sink(i32
; VIRT: define i32 @protected_cff({{.*}} #[[CFF:[0-9]+]] personality ptr @__gxx_personality_v0 {
; VIRT: vmp.post.cff.opcode
; VIRT: define i32 @unsupported_indirect({{.*}} #[[UNSUP:[0-9]+]] personality ptr @__gxx_personality_v0 {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT: attributes #[[CFF]] = { {{.*}}"hikari.vmp.post.cff.applied"{{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; HOST: Skipping VMP: only AArch64 targets are supported
