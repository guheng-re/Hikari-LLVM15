; Restricted llvm.stackprotector via the normal Call path.
; Safe form: C, exact non-vararg void(ptr, ptr), cookie is an ordinary
; AS0 pointer (pointer VReg), slot is the same-function static AS0
; pointer alloca replayed as the interpreter AllocaInst (%vmp.stack),
; not a VReg load.  No new VM opcode.  VMP does not insert
; __stack_chk_guard or ssp attributes, but keeps sspstrong on the
; function so AArch64 llc emits __stack_chk_fail.
; Ordinary tail is a hint and is replayed as TCK_None.  non-C, bundles,
; ABI, AS1 args, dynamic slots, non-pointer alloca slots, undef cookie,
; noreturn, and a real musttail of another function stay rejected.
; Host lli can run the inttoptr-cookie payload (the intrinsic stores
; the cookie into the slot).  The @__stack_chk_guard form is not
; called from main.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.ll > %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: llvm-readobj --symbols %t.o0.o | FileCheck %s --check-prefix=FAILSYM
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o0.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.live.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.ll > %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: llvm-readobj --symbols %t.o2.o | FileCheck %s --check-prefix=FAILSYM
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o2.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.live.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.s7.ll > %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llvm-readobj --symbols %t.o0.s7.o | FileCheck %s --check-prefix=FAILSYM
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o0.s7.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.s7.ll > %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llvm-readobj --symbols %t.o2.s7.o | FileCheck %s --check-prefix=FAILSYM
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o2.s7.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM

target triple = "aarch64-unknown-linux-gnu"

; Defined (not external) so host lli can materialize the module.
; The inttoptr-cookie functions do not read it; guard_gv is FileCheck-only.
@__stack_chk_guard = global ptr null
@llvm.compiler.used = appending global [1 x ptr] [ptr @__stack_chk_guard], section "llvm.metadata"

declare void @hikari_vmp()
declare void @llvm.stackprotector(ptr, ptr)
declare void @ext_sret_byval(ptr sret(i32), ptr byval(i32))

define i32 @sink_i32(ptr %p, i32 %x) {
entry:
  ret i32 %x
}

define i32 @reference_stackprotector(i64 %raw) {
entry:
  %slot = alloca ptr, align 8
  %g = inttoptr i64 %raw to ptr
  call void @llvm.stackprotector(ptr %g, ptr %slot)
  %got = load ptr, ptr %slot, align 8
  %eq = icmp eq ptr %got, %g
  %c = zext i1 %eq to i32
  ret i32 %c
}

define i32 @protected_stackprotector(i64 %raw) noinline optnone sspstrong {
entry:
  call void @hikari_vmp()
  %slot = alloca ptr, align 8
  %g = inttoptr i64 %raw to ptr
  call void @llvm.stackprotector(ptr %g, ptr %slot)
  %got = load ptr, ptr %slot, align 8
  %eq = icmp eq ptr %got, %g
  %c = zext i1 %eq to i32
  ret i32 %c
}

define void @protected_stackprotector_guard_gv() noinline optnone sspstrong {
entry:
  call void @hikari_vmp()
  %slot = alloca ptr, align 8
  call void @llvm.stackprotector(ptr @__stack_chk_guard, ptr %slot)
  ret void
}


define i32 @protected_stackprotector_sspstrong(i64 %raw) noinline optnone sspstrong {
entry:
  call void @hikari_vmp()
  %slot = alloca ptr, align 8
  %g = inttoptr i64 %raw to ptr
  call void @llvm.stackprotector(ptr %g, ptr %slot)
  %got = load ptr, ptr %slot, align 8
  %eq = icmp eq ptr %got, %g
  %c = zext i1 %eq to i32
  ret i32 %c
}

define i32 @protected_stackprotector_phi(i64 %raw, i1 %c) noinline optnone sspstrong {
entry:
  call void @hikari_vmp()
  %slot = alloca ptr, align 8
  %g = inttoptr i64 %raw to ptr
  br i1 %c, label %left, label %right
left:
  call void @llvm.stackprotector(ptr %g, ptr %slot)
  br label %join
right:
  call void @llvm.stackprotector(ptr %g, ptr %slot)
  br label %join
join:
  %got = load ptr, ptr %slot, align 8
  %eq = icmp eq ptr %got, %g
  %z = zext i1 %eq to i32
  %r = add i32 %z, 2
  ret i32 %r
}

define void @unsupported_stackprotector_noreturn() noinline optnone {
entry:
  call void @hikari_vmp()
  %slot = alloca ptr, align 8
  call void @llvm.stackprotector(ptr @__stack_chk_guard, ptr %slot) noreturn
  ret void
}

define i32 @unsupported_stackprotector_musttail(ptr %p, i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %slot = alloca ptr, align 8
  call void @llvm.stackprotector(ptr @__stack_chk_guard, ptr %slot)
  %r = musttail call i32 @sink_i32(ptr %p, i32 %x)
  ret i32 %r
}

define void @unsupported_stackprotector_badslot(i64 %raw) noinline optnone {
entry:
  call void @hikari_vmp()
  %g = inttoptr i64 %raw to ptr
  %slot = alloca i64, align 8
  call void @llvm.stackprotector(ptr %g, ptr %slot)
  ret void
}

define void @unsupported_stackprotector_undef(i64 %raw) noinline optnone {
entry:
  call void @hikari_vmp()
  %slot = alloca ptr, align 8
  call void @llvm.stackprotector(ptr undef, ptr %slot)
  ret void
}

define void @unsupported_stackprotector_dynslot(i64 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  %slot = alloca ptr, i64 %n, align 8
  call void @llvm.stackprotector(ptr @__stack_chk_guard, ptr %slot)
  ret void
}

define void @unsupported_stackprotector_as1(ptr addrspace(1) %unused) noinline optnone {
entry:
  call void @hikari_vmp()
  %slot = alloca ptr, align 8
  call void @llvm.stackprotector(ptr @__stack_chk_guard, ptr %slot)
  ret void
}

define void @unsupported_stackprotector_bundle() noinline optnone {
entry:
  call void @hikari_vmp()
  %slot = alloca ptr, align 8
  call void @llvm.stackprotector(ptr @__stack_chk_guard, ptr %slot) [ "deopt"(i32 0) ]
  ret void
}

define void @unsupported_stackprotector_fastcc() noinline optnone {
entry:
  call void @hikari_vmp()
  %slot = alloca ptr, align 8
  call fastcc void @llvm.stackprotector(ptr @__stack_chk_guard, ptr %slot)
  ret void
}

define void @unsupported_stackprotector_sret(ptr sret(i32) %p, ptr byval(i32) %q) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @ext_sret_byval(ptr sret(i32) %p, ptr byval(i32) %q)
  ret void
}

define i32 @main() {
entry:
  %e0 = call i32 @reference_stackprotector(i64 42)
  %a0 = call i32 @protected_stackprotector(i64 42)
  %a2 = call i32 @protected_stackprotector_phi(i64 42, i1 true)
  %m0 = icmp eq i32 %e0, %a0
  %m2 = icmp eq i32 %a2, 3
  %ok = and i1 %m0, %m2
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_stackprotector_noreturn: unsupported stackprotector
; SKIP-DAG: Skipping VMP on unsupported_stackprotector_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_stackprotector_badslot: unsupported stackprotector
; SKIP-DAG: Skipping VMP on unsupported_stackprotector_undef: unsupported stackprotector
; SKIP-DAG: Skipping VMP on unsupported_stackprotector_dynslot: unsupported stackprotector
; SKIP-DAG: Skipping VMP on unsupported_stackprotector_as1: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_stackprotector_bundle: unsupported stackprotector
; SKIP-DAG: Skipping VMP on unsupported_stackprotector_fastcc: unsupported stackprotector
; SKIP-DAG: Skipping VMP on unsupported_stackprotector_sret: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected_stackprotector:
; SKIP-NOT: Skipping VMP on protected_stackprotector_guard_gv:
; SKIP-NOT: Skipping VMP on protected_stackprotector_sspstrong:
; SKIP-NOT: Skipping VMP on protected_stackprotector_phi:
; SKIP-NOT: Skipping VMP on reference_stackprotector:

; Cookie is a pointer-VReg load (%vmp.ptr.reg.load).  Slot is the
; interpreter-entry alloca (%vmp.stack), also stored into the pointer
; frame, but the intrinsic's second operand is that AllocaInst.
; VIRT: define i32 @protected_stackprotector({{.*}} #[[PROT:[0-9]+]] {
; VIRT: %[[SLOT0:vmp.stack[0-9]*]] = alloca ptr, align 8
; VIRT: store volatile ptr %[[SLOT0]], ptr {{.*}}, align 8
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.stackprotector(ptr %[[CK0:vmp.ptr.reg.load[0-9]*]], ptr %[[SLOT0]])
; VIRT-NOT: call void @llvm.stackprotector(ptr {{.*}}, ptr %vmp.ptr.reg.load
; VIRT: define void @protected_stackprotector_guard_gv({{.*}} #[[PROT]] {
; VIRT-DAG: store volatile ptr @__stack_chk_guard
; VIRT: %[[SLOTG:vmp.stack[0-9]*]] = alloca ptr, align 8
; VIRT: store volatile ptr %[[SLOTG]], ptr {{.*}}, align 8
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.stackprotector(ptr %[[CKG:vmp.ptr.reg.load[0-9]*]], ptr %[[SLOTG]])
; VIRT: define i32 @protected_stackprotector_sspstrong({{.*}} #[[PROT]] {
; VIRT: %[[SLOTS:vmp.stack[0-9]*]] = alloca ptr, align 8
; VIRT: store volatile ptr %[[SLOTS]], ptr {{.*}}, align 8
; VIRT: vmp.dispatch:
; VIRT: call void @llvm.stackprotector(ptr %[[CKS:vmp.ptr.reg.load[0-9]*]], ptr %[[SLOTS]])
; VIRT: define i32 @protected_stackprotector_phi({{.*}} #[[PROT]] {
; VIRT: %[[SLOTP:vmp.stack[0-9]*]] = alloca ptr, align 8
; VIRT: store volatile ptr %[[SLOTP]], ptr {{.*}}, align 8
; VIRT: vmp.dispatch:
; VIRT-DAG: call void @llvm.stackprotector(ptr %[[CKP0:vmp.ptr.reg.load[0-9]*]], ptr %[[SLOTP]])
; VIRT-DAG: call void @llvm.stackprotector(ptr %[[CKP1:vmp.ptr.reg.load[0-9]*]], ptr %[[SLOTP]])
; VIRT: define {{.*}} @unsupported_stackprotector_noreturn({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call void @llvm.stackprotector(
; VIRT: define {{.*}} @unsupported_stackprotector_musttail({{.*}} #[[UNSUP_MT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call i32 @sink_i32(
; VIRT: define {{.*}} @unsupported_stackprotector_badslot({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_stackprotector_undef({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_stackprotector_dynslot({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_stackprotector_as1({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_stackprotector_bundle({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_stackprotector_fastcc({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_stackprotector_sret({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { noinline optnone sspstrong "hikari.vmp.selected" "hikari.vmp.virtualized" }{{$}}
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"{{.*}} }

; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; VIRT-NOT: attributes #[[UNSUP_MT]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; FAILSYM: Name: __stack_chk_fail
; FAILSYM-NEXT: Value: 0x0
; AARCH64-ASM: __stack_chk_fail
