; llvm.localaddress(): local variable area of this function.  C, exact
; non-vararg ptr(), AS0, zero args.  Replay via CallDescriptor into the
; pointer VReg; never synthesize the address.  AArch64 is CopyFromReg of
; SP (no EH funclets / var-sized objects).  Ordinary tail accepted and replayed as TCK_None.
; localescape / localrecover / eh.recoverfp stay unsupported.
;
; Host IntrinsicLowering has no localaddress case (pure interpreter
; fatals), so no lli.  FileCheck + AArch64 llc/readobj/asm only.
;
; Non-AS0 result / non-ptr() FTy cannot share a module with the
; canonical declare (fixed llvm_ptr_ty; verifier: incompatible
; signature).  AS1 unused argument hits the argument-type gate.
; Call-site noreturn is the probed-legal malformed form.
;
; FileCheck + AArch64 llc/readobj/asm.  O0/O2 x aesSeed 97/7.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.ll > %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o0.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.ll > %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o2.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.s7.ll > %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o0.s7.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.s7.ll > %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o2.s7.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare ptr @llvm.localaddress()
declare void @llvm.localescape(...)
declare ptr @llvm.localrecover(ptr, ptr, i32 immarg)
declare ptr @llvm.eh.recoverfp(ptr, ptr)
declare void @ext_sret_byval(ptr sret(i32), ptr byval(i32))

; Verifier: localrecover indices must be in-range for this function's
; localescape.  AArch64 ISel records a frame-escape offset; llc is OK.
define void @parent() {
entry:
  %a = alloca i32, align 4
  call void (...) @llvm.localescape(ptr %a)
  ret void
}

; ----- positives -----

define i32 @protected() noinline optnone {
entry:
  call void @hikari_vmp()
  %a = call ptr @llvm.localaddress()
  %b = call ptr @llvm.localaddress()
  %eq = icmp eq ptr %a, %b
  %c = zext i1 %eq to i32
  ret i32 %c
}

define i32 @protected_mem() noinline optnone {
entry:
  call void @hikari_vmp()
  %slot = alloca i32, align 4
  store i32 7, ptr %slot, align 4
  %la = call ptr @llvm.localaddress()
  %p = getelementptr i8, ptr %la, i64 0
  %ne = icmp ne ptr %p, %slot
  %v = load i32, ptr %slot, align 4
  %z = zext i1 %ne to i32
  %r = add i32 %v, %z
  ret i32 %r
}

; ----- negatives -----

define ptr @unsupported_malformed() noinline optnone {
entry:
  call void @hikari_vmp()
  %a = call ptr @llvm.localaddress() noreturn
  ret ptr %a
}

define ptr @unsupported_as1_arg(ptr addrspace(1) %unused) noinline optnone {
entry:
  call void @hikari_vmp()
  %a = call ptr @llvm.localaddress()
  ret ptr %a
}


define ptr @unsupported_musttail() noinline optnone {
entry:
  call void @hikari_vmp()
  %a = musttail call ptr @llvm.localaddress()
  ret ptr %a
}

define ptr @unsupported_bundle() noinline optnone {
entry:
  call void @hikari_vmp()
  %a = call ptr @llvm.localaddress() [ "deopt"(i32 0) ]
  ret ptr %a
}

define ptr @unsupported_fastcc() noinline optnone {
entry:
  call void @hikari_vmp()
  %a = call fastcc ptr @llvm.localaddress()
  ret ptr %a
}

define void @unsupported_sret(ptr sret(i32) %p, ptr byval(i32) %q) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @ext_sret_byval(ptr sret(i32) %p, ptr byval(i32) %q)
  ret void
}

define void @unsupported_localescape() noinline optnone {
entry:
  call void @hikari_vmp()
  %a = alloca i32, align 4
  call void (...) @llvm.localescape(ptr %a)
  ret void
}

define ptr @unsupported_localrecover() noinline optnone {
entry:
  call void @hikari_vmp()
  %p = call ptr @llvm.localrecover(ptr @parent, ptr null, i32 0)
  ret ptr %p
}

define ptr @unsupported_eh_recoverfp() noinline optnone {
entry:
  call void @hikari_vmp()
  %p = call ptr @llvm.eh.recoverfp(ptr @parent, ptr null)
  ret ptr %p
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_malformed: unsupported localaddress
; SKIP-DAG: Skipping VMP on unsupported_as1_arg: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported localaddress
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported localaddress
; SKIP-DAG: Skipping VMP on unsupported_sret: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_localescape: variadic call
; SKIP-DAG: Skipping VMP on unsupported_localrecover: unsupported call instruction
; SKIP-DAG: Skipping VMP on unsupported_eh_recoverfp: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected:
; SKIP-NOT: Skipping VMP on protected_mem:

; VIRT: define i32 @protected({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call void @hikari_vmp()
; Local area is re-emitted as the original intrinsic (never null /
; inttoptr / a synthesized GEP of a constant).
; VIRT-DAG: [[LA0:%.*]] = call ptr @llvm.localaddress()
; VIRT-DAG: [[LA1:%.*]] = call ptr @llvm.localaddress()
; VIRT-DAG: store volatile ptr [[LA0]], ptr {{.*}}, align 8
; VIRT-DAG: store volatile ptr [[LA1]], ptr {{.*}}, align 8
; VIRT: }
; VIRT: define i32 @protected_mem({{.*}} #[[PROT]] {
; Static alloca stays in the rewritten entry and is published into the
; pointer VReg; GEP of localaddress is a VReg-index i8 GEP, not a
; synthesized constant address.
; VIRT: [[SLOT:%.*]] = alloca i32, align 4
; VIRT: store volatile ptr [[SLOT]], ptr {{.*}}, align 8
; VIRT: vmp.dispatch:
; VIRT-DAG: [[LM:%.*]] = call ptr @llvm.localaddress()
; VIRT-DAG: store volatile ptr [[LM]], ptr {{.*}}, align 8
; VIRT-DAG: getelementptr i8, ptr {{.*}}, i64
; VIRT-DAG: store i32 {{.*}}, ptr {{.*}}, align 4
; VIRT-DAG: load i32, ptr {{.*}}, align 4
; VIRT: }
; VIRT: define {{.*}} @unsupported_malformed({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_as1_arg({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_musttail({{.*}} #[[UNSUPMUST:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call ptr @llvm.localaddress()
; VIRT: define {{.*}} @unsupported_bundle({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fastcc({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_sret({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define void @unsupported_localescape(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define ptr @unsupported_localrecover(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define ptr @unsupported_eh_recoverfp(
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPMUST]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPMUST]] = { {{.*}}"hikari.vmp.selected"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; Local area lowers from SP (CopyFromReg of getLocalAddressRegister).
; AARCH64-ASM: mov{{.*}}sp
