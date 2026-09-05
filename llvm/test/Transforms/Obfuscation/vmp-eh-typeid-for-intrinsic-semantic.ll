; llvm.eh.typeid.for re-emitted through the normal Call path: i32 result
; through the integer virtual register frame; the unique AS0 typeinfo
; pointer stays a true Constant on CallDescriptor (GlobalValue, bitcast of
; one, or null) and is never reloaded from a pointer VReg.  Dynamic
; typeinfo, eh_return, musttail, bundles, noreturn,
; returns_twice and complex ABI stay rejected.  Host lli lowers
; eh.typeid.for to i32 1, so reference/protected parity holds after the
; triple swap; AArch64 llc is the codegen check.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.ll -o %t.o0.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP-O2 < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT-O2 < %t.o2.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.ll -o %t.o2.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP-O2 < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT-O2 < %t.o2.s7.ll

target triple = "aarch64-unknown-linux-gnu"

@_ZTIi = constant i8 0
@_ZTIb = constant i8 1

declare void @hikari_vmp()
declare i32 @llvm.eh.typeid.for(ptr)
declare void @llvm.eh.return.i64(i64, ptr)
declare i32 @__gxx_personality_v0(...)

; ---- reference: native GV + bitcast + null ----

define i32 @reference() {
entry:
  %a = call i32 @llvm.eh.typeid.for(ptr @_ZTIi)
  %b = call i32 @llvm.eh.typeid.for(ptr bitcast (ptr @_ZTIb to ptr))
  %z = call i32 @llvm.eh.typeid.for(ptr null)
  %s0 = add i32 %a, %b
  %s1 = add i32 %s0, %z
  ret i32 %s1
}

; ---- protected: same under VMP ----

define i32 @protected() noinline optnone {
entry:
  call void @hikari_vmp()
  %a = call i32 @llvm.eh.typeid.for(ptr @_ZTIi)
  %b = call i32 @llvm.eh.typeid.for(ptr bitcast (ptr @_ZTIb to ptr))
  %z = call i32 @llvm.eh.typeid.for(ptr null)
  %s0 = add i32 %a, %b
  %s1 = add i32 %s0, %z
  ret i32 %s1
}

; ---- negatives: never called from main ----

define i32 @unsupported_dynamic() noinline optnone {
entry:
  call void @hikari_vmp()
  %p = alloca i8, align 1
  %t = call i32 @llvm.eh.typeid.for(ptr %p)
  ret i32 %t
}

define i32 @unsupported_noreturn() noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call i32 @llvm.eh.typeid.for(ptr @_ZTIi) noreturn
  ret i32 %t
}

define i32 @unsupported_returns_twice() noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call i32 @llvm.eh.typeid.for(ptr @_ZTIi) returns_twice
  ret i32 %t
}

define i32 @unsupported_bundle() noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call i32 @llvm.eh.typeid.for(ptr @_ZTIi) [ "deopt"(i32 0) ]
  ret i32 %t
}

define i32 @unsupported_byval(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %t = call i32 @llvm.eh.typeid.for(ptr byval(i8) %p)
  ret i32 %t
}

define void @unsupported_eh_return() noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.eh.return.i64(i64 0, ptr null)
  ret void
}

define i32 @unsupported_musttail() noinline optnone {
entry:
  call void @hikari_vmp()
  %t = musttail call i32 @llvm.eh.typeid.for(ptr @_ZTIi)
  ret i32 %t
}

; Well-formed reachable Itanium invoke is vmp-itanium-invoke-semantic.ll.

define i32 @main() {
entry:
  %e0 = call i32 @reference()
  %a0 = call i32 @protected()
  %ok = icmp eq i32 %e0, %a0
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP-DAG: Skipping VMP on unsupported_dynamic: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_noreturn: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_returns_twice: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_byval: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_eh_return: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-NOT: Skipping VMP on protected:
; SKIP-NOT: Skipping VMP on reference:

; Typeinfo must stay a Constant on re-emit (never a VReg-loaded pointer).
; VIRT: define i32 @protected(){{.*}}#[[POSATTR:[0-9]+]] {
; VIRT: %vmp.regs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: call i32 @llvm.eh.typeid.for(ptr @_ZTIi)
; VIRT-DAG: call i32 @llvm.eh.typeid.for(ptr {{(@_ZTIb|bitcast \(ptr @_ZTIb to ptr\))}})
; VIRT-DAG: call i32 @llvm.eh.typeid.for(ptr null)
; VIRT-NOT: call i32 @llvm.eh.typeid.for(ptr %

; VIRT-LABEL: define i32 @unsupported_dynamic(
; VIRT-NOT: vmp.dispatch
; VIRT: call i32 @llvm.eh.typeid.for(ptr %
; VIRT-LABEL: define i32 @unsupported_noreturn(
; VIRT-NOT: vmp.dispatch
; VIRT: call i32 @llvm.eh.typeid.for(ptr @_ZTIi)
; VIRT-LABEL: define i32 @unsupported_returns_twice(
; VIRT-NOT: vmp.dispatch
; VIRT: call i32 @llvm.eh.typeid.for(ptr @_ZTIi)
; VIRT-LABEL: define i32 @unsupported_bundle(
; VIRT-NOT: vmp.dispatch
; VIRT: call i32 @llvm.eh.typeid.for(ptr @_ZTIi)
; VIRT-LABEL: define i32 @unsupported_byval(
; VIRT-NOT: vmp.dispatch
; VIRT: call i32 @llvm.eh.typeid.for(ptr
; VIRT-LABEL: define void @unsupported_eh_return(
; VIRT-NOT: vmp.dispatch
; VIRT: call void @llvm.eh.return.i64
; VIRT-LABEL: define i32 @unsupported_musttail(
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call i32 @llvm.eh.typeid.for

; VIRT: attributes #[[POSATTR]] = { noinline optnone "hikari.vmp.selected" "hikari.vmp.virtualized" }{{$}}

; SKIP-O2-DAG: Skipping VMP on unsupported_dynamic: unsupported call instruction
; SKIP-O2-DAG: Skipping VMP on unsupported_noreturn: unsupported call instruction
; SKIP-O2-DAG: Skipping VMP on unsupported_returns_twice: unsupported call instruction
; SKIP-O2-DAG: Skipping VMP on unsupported_bundle: unsupported call instruction
; SKIP-O2-DAG: Skipping VMP on unsupported_byval: unsupported call instruction
; SKIP-O2-DAG: Skipping VMP on unsupported_eh_return: unsupported call instruction
; SKIP-O2-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-O2-NOT: Skipping VMP on protected:

; VIRT-O2: define i32 @protected(){{.*}}#[[POSATTR:[0-9]+]] {
; VIRT-O2: %vmp.regs = alloca
; VIRT-O2: vmp.dispatch:
; VIRT-O2-DAG: call i32 @llvm.eh.typeid.for(ptr @_ZTIi)
; VIRT-O2-DAG: call i32 @llvm.eh.typeid.for(ptr {{(@_ZTIb|bitcast \(ptr @_ZTIb to ptr\))}})
; VIRT-O2-DAG: call i32 @llvm.eh.typeid.for(ptr null)
; VIRT-O2-NOT: call i32 @llvm.eh.typeid.for(ptr %
; VIRT-O2-LABEL: define i32 @unsupported_dynamic(
; VIRT-O2-NOT: vmp.dispatch
; VIRT-O2: call i32 @llvm.eh.typeid.for(ptr %
; VIRT-O2: attributes #[[POSATTR]] = { noinline optnone "hikari.vmp.selected" "hikari.vmp.virtualized" }{{$}}
