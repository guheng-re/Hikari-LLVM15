; Restricted AArch64 VMP Itanium C++ invoke / landingpad / resume:
;   direct fixed C invoke whose unwind dest is a reachable {ptr,i32}
;   landingpad (cleanup / catch / filter).  The interpreter handler
;   emits a native InvokeInst; the normal edge writes the result VReg
;   and redispatches; the unwind edge is a native LandingPadInst with
;   the original clauses, stores the aggregate into the landingpad
;   VReg, then enters the virtual landingpad PC.  Resume reloads that
;   aggregate and emits a native ResumeInst.
; Nounwind + unreachable island stays vmp-nounwind-invoke-semantic.ll
; (Call+Br, no EH shell).  Windows funclets, indirect/vararg/bundle/
; tail/musttail/noreturn/returns_twice/complex ABI, non-Itanium
; personality, and malformed pads stay "exception handling".
; Post-CFF sees the EH shell and keeps the virtualized function.
; Host cannot reliably execute C++ EH here; no lli / no runner.  main
; does not call the protected shells.  @llvm.used keeps those five
; functions alive through internalize+globaldce so llc/readobj see the
; EH shells.  Normal-edge host lli (helper never throws) is
; vmp-itanium-invoke-normal-edge-semantic.ll and is not an unwind test.
; Target AArch64 unwind is not claimed: VMP_AARCH64_RUNNER is documented
; only for C ABI integer/memory/recursion/atomic objects
; (vmp-aarch64-runner.ll).  It does not promise libstdc++/libc++abi/
; libunwind, so no REQUIRES: vmp-aarch64-runner throw/catch lit.
; FileCheck + AArch64 llc/readobj.  O0/O2 x 97/7.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.ll -o %t.o0.live.ll
; RUN: FileCheck %s --check-prefix=LIVE < %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h -S --symbols %t.o0.o | FileCheck %s --check-prefixes=AARCH64,AARCH64-OBJ
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o0.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.ll -o %t.o2.live.ll
; RUN: FileCheck %s --check-prefix=LIVE < %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h -S --symbols %t.o2.o | FileCheck %s --check-prefixes=AARCH64,AARCH64-OBJ
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o2.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.s7.ll -o %t.o0.s7.live.ll
; RUN: FileCheck %s --check-prefix=LIVE < %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h -S --symbols %t.o0.s7.o | FileCheck %s --check-prefixes=AARCH64,AARCH64-OBJ
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o0.s7.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.s7.ll -o %t.o2.s7.live.ll
; RUN: FileCheck %s --check-prefix=LIVE < %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h -S --symbols %t.o2.s7.o | FileCheck %s --check-prefixes=AARCH64,AARCH64-OBJ
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o2.s7.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %s | opt -S -verify-each -aesSeed=97 -passes='default<O0>' - 2>&1 | FileCheck %s --check-prefix=HOST

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare void @hikari_fla()
declare i32 @__gxx_personality_v0(...)
declare i32 @__gcc_personality_v0(...)
declare i32 @__objc_personality_v0(...)
declare i32 @maybe_add(i32)
declare void @may_throw()
declare void @cleanup_sink()
declare i32 @llvm.eh.typeid.for(ptr)
@_ZTIi = external constant i8

define i32 @protected_result(i32 %x) noinline optnone personality ptr @__gxx_personality_v0 {
entry:
  call void @hikari_vmp()
  %r = invoke i32 @maybe_add(i32 %x)
          to label %cont unwind label %lpad
cont:
  ret i32 %r
lpad:
  %lp = landingpad { ptr, i32 }
          cleanup
  resume { ptr, i32 } %lp
}

define i32 @protected_catch() noinline optnone personality ptr @__gxx_personality_v0 {
entry:
  call void @hikari_vmp()
  invoke void @may_throw()
          to label %cont unwind label %lpad
cont:
  ret i32 0
lpad:
  %lp = landingpad { ptr, i32 }
          catch ptr @_ZTIi
  %sel = extractvalue { ptr, i32 } %lp, 1
  %tid = call i32 @llvm.eh.typeid.for(ptr @_ZTIi)
  %m = icmp eq i32 %sel, %tid
  br i1 %m, label %caught, label %rethrow
caught:
  ret i32 %sel
rethrow:
  resume { ptr, i32 } %lp
}

define void @protected_cleanup() noinline optnone personality ptr @__gxx_personality_v0 {
entry:
  call void @hikari_vmp()
  invoke void @may_throw()
          to label %cont unwind label %lpad
cont:
  ret void
lpad:
  %lp = landingpad { ptr, i32 }
          cleanup
  call void @cleanup_sink()
  resume { ptr, i32 } %lp
}

define i32 @protected_lpad_phi(i1 %c, i32 %x, i32 %y) noinline optnone personality ptr @__gxx_personality_v0 {
entry:
  call void @hikari_vmp()
  br i1 %c, label %a, label %b
a:
  invoke void @may_throw()
          to label %cont unwind label %lpad
b:
  invoke void @may_throw()
          to label %cont unwind label %lpad
cont:
  ret i32 0
lpad:
  %p = phi i32 [ %x, %a ], [ %y, %b ]
  %lp = landingpad { ptr, i32 }
          cleanup
  %sel = extractvalue { ptr, i32 } %lp, 1
  %s = add i32 %p, %sel
  ret i32 %s
}

define i32 @protected_cff(i32 %x) noinline optnone personality ptr @__gxx_personality_v0 {
entry:
  call void @hikari_vmp()
  call void @hikari_fla()
  %r = invoke i32 @maybe_add(i32 %x)
          to label %cont unwind label %lpad
cont:
  ret i32 %r
lpad:
  %lp = landingpad { ptr, i32 }
          cleanup
  resume { ptr, i32 } %lp
}

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

define i32 @unsupported_objc(i32 %x) noinline optnone personality ptr @__objc_personality_v0 {
entry:
  call void @hikari_vmp()
  %r = invoke i32 @maybe_add(i32 %x)
          to label %cont unwind label %lpad
cont:
  ret i32 %r
lpad:
  %lp = landingpad { ptr, i32 }
          cleanup
  resume { ptr, i32 } %lp
}

define i32 @unsupported_fastcc(i32 %x) noinline optnone personality ptr @__gxx_personality_v0 {
entry:
  call void @hikari_vmp()
  %r = invoke fastcc i32 @maybe_add(i32 %x)
          to label %cont unwind label %lpad
cont:
  ret i32 %r
lpad:
  %lp = landingpad { ptr, i32 }
          cleanup
  resume { ptr, i32 } %lp
}

define i32 @unsupported_bundle(i32 %x) noinline optnone personality ptr @__gxx_personality_v0 {
entry:
  call void @hikari_vmp()
  %r = invoke i32 @maybe_add(i32 %x) [ "deopt"() ]
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
  invoke void @may_throw() noreturn
          to label %cont unwind label %lpad
cont:
  ret i32 %x
lpad:
  %lp = landingpad { ptr, i32 }
          cleanup
  resume { ptr, i32 } %lp
}

define i32 @main() {
entry:
  ret i32 0
}

; Keep the protected EH shells live without executing them.  main is the
; only public API for internalize; without llvm.used, globaldce would
; drop every virtualized invoke/landingpad/resume before llc.
@llvm.used = appending global [5 x ptr] [
  ptr @protected_result,
  ptr @protected_catch,
  ptr @protected_cleanup,
  ptr @protected_lpad_phi,
  ptr @protected_cff
], section "llvm.used"

; SKIP-DAG: Skipping VMP on unsupported_indirect: exception handling
; SKIP-DAG: Skipping VMP on unsupported_objc: exception handling
; SKIP-DAG: Skipping VMP on unsupported_fastcc: exception handling
; SKIP-DAG: Skipping VMP on unsupported_bundle: exception handling
; SKIP-DAG: Skipping VMP on unsupported_noreturn: exception handling
; SKIP-DAG: Skipping VMP post-CFF on protected_cff:
; SKIP-NOT: Skipping VMP on protected_result:
; SKIP-NOT: Skipping VMP on protected_catch:
; SKIP-NOT: Skipping VMP on protected_cleanup:
; SKIP-NOT: Skipping VMP on protected_lpad_phi:
; SKIP-NOT: Skipping VMP on protected_cff:

; VIRT: define i32 @protected_result({{.*}} #[[PROT:[0-9]+]] personality ptr @__gxx_personality_v0 {
; VIRT: vmp.dispatch:
; VIRT: invoke i32 @maybe_add(i32
; VIRT: define i32 @protected_catch({{.*}} personality ptr @__gxx_personality_v0 {
; VIRT: catch ptr @_ZTIi
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.eh.typeid.for(ptr @_ZTIi)
; VIRT: define void @protected_cleanup({{.*}} personality ptr @__gxx_personality_v0 {
; VIRT: vmp.dispatch:
; VIRT: call void @cleanup_sink(
; VIRT: define i32 @protected_lpad_phi({{.*}} personality ptr @__gxx_personality_v0 {
; VIRT: vmp.dispatch:
; VIRT: invoke void @may_throw(
; VIRT: define i32 @protected_cff({{.*}} personality ptr @__gxx_personality_v0 {
; VIRT: vmp.dispatch:
; VIRT: invoke i32 @maybe_add(i32
; VIRT: define i32 @unsupported_indirect({{.*}} #[[UNSUP:[0-9]+]] personality ptr @__gxx_personality_v0 {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: hikari.vmp.post.cff.applied
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; LIVE: define {{.*}}@protected_result(
; LIVE: define {{.*}}@protected_catch(
; LIVE: define {{.*}}@protected_cleanup(
; LIVE: define {{.*}}@protected_lpad_phi(
; LIVE: define {{.*}}@protected_cff(
; LIVE-NOT: define {{.*}}@unsupported_indirect(

; AARCH64: Arch: aarch64
; AARCH64-OBJ-DAG: Name: .gcc_except_table
; AARCH64-OBJ-DAG: Name: .eh_frame
; AARCH64-OBJ-DAG: Name: .text.protected_result
; AARCH64-OBJ-DAG: Name: .text.protected_catch
; AARCH64-OBJ-DAG: Name: .text.protected_cleanup
; AARCH64-OBJ-DAG: Name: .text.protected_lpad_phi
; AARCH64-OBJ-DAG: Name: .text.protected_cff
; AARCH64-OBJ-DAG: Name: __gxx_personality_v0
; AARCH64-OBJ-DAG: Name: _Unwind_Resume
; AARCH64-OBJ-DAG: Name: maybe_add
; AARCH64-OBJ-DAG: Name: may_throw
; AARCH64-OBJ-DAG: Name: cleanup_sink
; AARCH64-OBJ-DAG: Name: _ZTIi
; AARCH64-ASM-DAG: .cfi_personality {{.*}}__gxx_personality_v0
; AARCH64-ASM-DAG: .cfi_lsda
; AARCH64-ASM-DAG: {{GCC_except_table|\.gcc_except_table}}
; AARCH64-ASM-DAG: {{^[[:space:]]*}}bl{{[ \t]+}}maybe_add
; AARCH64-ASM-DAG: {{^[[:space:]]*}}bl{{[ \t]+}}may_throw
; AARCH64-ASM-DAG: {{^[[:space:]]*}}bl{{[ \t]+}}_Unwind_Resume
; AARCH64-ASM-DAG: {{^[[:space:]]*}}bl{{[ \t]+}}cleanup_sink
; HOST: Skipping VMP: only AArch64 targets are supported
