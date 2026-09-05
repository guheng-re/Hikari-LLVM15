; Scalar llvm.get.dynamic.area.offset.i64: target-dependent offset from
; native SP to the most recent dynamic alloca.  LangRef: most targets
; (AArch64 / x86_64) lower it to zero; PowerPC to a compile-time
; constant.  VMP must replay via CallDescriptor (i64(), C) into the
; integer VReg frame and must never pre-fold to 0 / Move.
;
; Host IntrinsicLowering and AArch64/x86 SelectionDAG Expand both
; produce 0, so triple-swapped lli -force-interpreter is meaningful
; reference/protected integer parity.  AArch64 llc/readobj/asm confirm
; the object and the zero lowering (xzr).
;
; Entry dynamic alloca in the same function is "dynamic stack state"
; (prologue alloca would change the observed area).  stacksave /
; stackrestore without a VLA may coexist.  Ordinary tail accepted and
; replayed as TCK_None; see vmp-direct-call-tail-eligibility-semantic.ll.
;
; FileCheck + host lli + AArch64 llc/readobj/asm.  O0/O2 x aesSeed 97/7.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.ll > %t.o0.live.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.live.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o0.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.ll > %t.o2.live.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.live.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o2.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.s7.ll > %t.o0.s7.live.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.s7.live.ll > %t.o0.s7.host.ll
; RUN: lli -force-interpreter %t.o0.s7.host.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o0.s7.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.s7.ll > %t.o2.s7.live.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.s7.live.ll > %t.o2.s7.host.ll
; RUN: lli -force-interpreter %t.o2.s7.host.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: llc -mtriple=aarch64-unknown-linux-gnu %t.o2.s7.live.ll -o - | FileCheck %s --check-prefix=AARCH64-ASM

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare i64 @llvm.get.dynamic.area.offset.i64()
declare i32 @llvm.get.dynamic.area.offset.i32()
declare i128 @llvm.get.dynamic.area.offset.i128()
declare ptr @llvm.stacksave()
declare void @llvm.stackrestore(ptr)
declare void @ext_sret_byval(ptr sret(i32), ptr byval(i32))

; ----- reference (native) -----

define i64 @reference(i64 %seed) noinline {
entry:
  %o = call i64 @llvm.get.dynamic.area.offset.i64()
  %r = add i64 %o, %seed
  ret i64 %r
}

define i64 @reference_vla_arith(i64 %base) noinline {
entry:
  %buf = alloca [16 x i8], align 1
  %off = call i64 @llvm.get.dynamic.area.offset.i64()
  %adj = add i64 %base, %off
  %back = sub i64 %adj, %off
  %p = getelementptr i8, ptr %buf, i64 %off
  store i8 7, ptr %p, align 1
  %ld = load i8, ptr %p, align 1
  %z = zext i8 %ld to i64
  %r = add i64 %back, %z
  ret i64 %r
}

define i64 @reference_loop(i32 %n, i64 %seed) noinline {
entry:
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %acc = phi i64 [ %seed, %entry ], [ %acc1, %loop ]
  %off = call i64 @llvm.get.dynamic.area.offset.i64()
  %acc1 = add i64 %acc, %off
  %i1 = add i32 %i, 1
  %more = icmp slt i32 %i1, %n
  br i1 %more, label %loop, label %done

done:
  ret i64 %acc1
}

define i64 @reference_stacksave(i64 %seed) noinline {
entry:
  %tok = call ptr @llvm.stacksave()
  %o = call i64 @llvm.get.dynamic.area.offset.i64()
  call void @llvm.stackrestore(ptr %tok)
  %r = add i64 %o, %seed
  ret i64 %r
}

; ----- positives -----

define i64 @protected(i64 %seed) noinline optnone {
entry:
  call void @hikari_vmp()
  %o = call i64 @llvm.get.dynamic.area.offset.i64()
  %r = add i64 %o, %seed
  ret i64 %r
}

; ASan-style VLA arithmetic (add/sub/GEP i8 + load/store) without a
; real dynamic alloca — that combo is rejected as dynamic stack state.
define i64 @protected_vla_arith(i64 %base) noinline optnone {
entry:
  call void @hikari_vmp()
  %buf = alloca [16 x i8], align 1
  %off = call i64 @llvm.get.dynamic.area.offset.i64()
  %adj = add i64 %base, %off
  %back = sub i64 %adj, %off
  %p = getelementptr i8, ptr %buf, i64 %off
  store i8 7, ptr %p, align 1
  %ld = load i8, ptr %p, align 1
  %z = zext i8 %ld to i64
  %r = add i64 %back, %z
  ret i64 %r
}

define i64 @protected_loop(i32 %n, i64 %seed) noinline optnone {
entry:
  call void @hikari_vmp()
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %acc = phi i64 [ %seed, %entry ], [ %acc1, %loop ]
  %off = call i64 @llvm.get.dynamic.area.offset.i64()
  %acc1 = add i64 %acc, %off
  %i1 = add i32 %i, 1
  %more = icmp slt i32 %i1, %n
  br i1 %more, label %loop, label %done

done:
  ret i64 %acc1
}

; stacksave / stackrestore without a VLA may coexist with DAO.
define i64 @protected_stacksave(i64 %seed) noinline optnone {
entry:
  call void @hikari_vmp()
  %tok = call ptr @llvm.stacksave()
  %o = call i64 @llvm.get.dynamic.area.offset.i64()
  call void @llvm.stackrestore(ptr %tok)
  %r = add i64 %o, %seed
  ret i64 %r
}

; ----- negatives -----

define i32 @unsupported_i32_offset() noinline optnone {
entry:
  call void @hikari_vmp()
  %o = call i32 @llvm.get.dynamic.area.offset.i32()
  ret i32 %o
}

define i128 @unsupported_i128_offset() noinline optnone {
entry:
  call void @hikari_vmp()
  %o = call i128 @llvm.get.dynamic.area.offset.i128()
  ret i128 %o
}

; Otherwise-legal entry dynamic alloca plus DAO: dynamic-stack-state
; would change the observed dynamic area.
define i32 @unsupported_dyn_alloca_dynarea(i64 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  %p = alloca i32, i64 %n, align 4
  store i32 1, ptr %p, align 4
  %off = call i64 @llvm.get.dynamic.area.offset.i64()
  %t = trunc i64 %off to i32
  %v = load i32, ptr %p, align 4
  %r = xor i32 %v, %t
  ret i32 %r
}


define i64 @unsupported_musttail() noinline optnone {
entry:
  call void @hikari_vmp()
  %o = musttail call i64 @llvm.get.dynamic.area.offset.i64()
  ret i64 %o
}

define i64 @unsupported_bundle() noinline optnone {
entry:
  call void @hikari_vmp()
  %o = call i64 @llvm.get.dynamic.area.offset.i64() [ "deopt"(i32 0) ]
  ret i64 %o
}

define i64 @unsupported_fastcc() noinline optnone {
entry:
  call void @hikari_vmp()
  %o = call fastcc i64 @llvm.get.dynamic.area.offset.i64()
  ret i64 %o
}

define void @unsupported_sret(ptr sret(i32) %p, ptr byval(i32) %q) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @ext_sret_byval(ptr sret(i32) %p, ptr byval(i32) %q)
  ret void
}

define i32 @main() {
entry:
  %e0 = call i64 @reference(i64 7)
  %a0 = call i64 @protected(i64 7)
  %e1 = call i64 @reference(i64 42)
  %a1 = call i64 @protected(i64 42)
  %m0 = icmp eq i64 %e0, %a0
  %m1 = icmp eq i64 %e1, %a1

  %e2 = call i64 @reference_vla_arith(i64 100)
  %a2 = call i64 @protected_vla_arith(i64 100)
  %e3 = call i64 @reference_vla_arith(i64 3)
  %a3 = call i64 @protected_vla_arith(i64 3)
  %m2 = icmp eq i64 %e2, %a2
  %m3 = icmp eq i64 %e3, %a3

  %e4 = call i64 @reference_loop(i32 1, i64 9)
  %a4 = call i64 @protected_loop(i32 1, i64 9)
  %e5 = call i64 @reference_loop(i32 4, i64 11)
  %a5 = call i64 @protected_loop(i32 4, i64 11)
  %m4 = icmp eq i64 %e4, %a4
  %m5 = icmp eq i64 %e5, %a5

  %e6 = call i64 @reference_stacksave(i64 13)
  %a6 = call i64 @protected_stacksave(i64 13)
  %m6 = icmp eq i64 %e6, %a6

  %t0 = and i1 %m0, %m1
  %t1 = and i1 %m2, %m3
  %t2 = and i1 %m4, %m5
  %t3 = and i1 %t0, %t1
  %t4 = and i1 %t2, %m6
  %ok = and i1 %t3, %t4
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_i32_offset: unsupported get.dynamic.area.offset
; SKIP-DAG: Skipping VMP on unsupported_i128_offset: unsupported get.dynamic.area.offset
; SKIP-DAG: Skipping VMP on unsupported_dyn_alloca_dynarea: dynamic stack state
; SKIP-DAG: Skipping VMP on unsupported_musttail: musttail call
; SKIP-DAG: Skipping VMP on unsupported_bundle: unsupported get.dynamic.area.offset
; SKIP-DAG: Skipping VMP on unsupported_fastcc: unsupported get.dynamic.area.offset
; SKIP-DAG: Skipping VMP on unsupported_sret: unsupported call instruction
; SKIP-NOT: Skipping VMP on protected:
; SKIP-NOT: Skipping VMP on protected_vla_arith:
; SKIP-NOT: Skipping VMP on protected_loop:
; SKIP-NOT: Skipping VMP on protected_stacksave:

; VIRT: define i64 @protected({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call void @hikari_vmp()
; VIRT-DAG: [[D:%.*]] = call i64 @llvm.get.dynamic.area.offset.i64()
; VIRT-DAG: store volatile i64 [[D]], ptr {{.*}}
; VIRT: }
; VIRT: define i64 @protected_vla_arith({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: [[VA:%.*]] = call i64 @llvm.get.dynamic.area.offset.i64()
; VIRT-DAG: store volatile i64 [[VA]], ptr {{.*}}
; VIRT: }
; VIRT: define i64 @protected_loop({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: [[LP:%.*]] = call i64 @llvm.get.dynamic.area.offset.i64()
; VIRT-DAG: store volatile i64 [[LP]], ptr {{.*}}
; VIRT: }
; VIRT: define i64 @protected_stacksave({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-DAG: [[SS:%.*]] = call ptr @llvm.stacksave()
; VIRT-DAG: store volatile ptr [[SS]], ptr {{.*}}, align 8
; VIRT-DAG: [[SO:%.*]] = call i64 @llvm.get.dynamic.area.offset.i64()
; VIRT-DAG: store volatile i64 [[SO]], ptr {{.*}}
; VIRT-DAG: call void @llvm.stackrestore(ptr {{.*}})
; VIRT: }
; VIRT: define {{.*}} @unsupported_i32_offset({{.*}} #[[UNSUP:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call i32 @llvm.get.dynamic.area.offset.i32()
; VIRT: define {{.*}} @unsupported_i128_offset({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: call i128 @llvm.get.dynamic.area.offset.i128()
; VIRT: define {{.*}} @unsupported_dyn_alloca_dynarea({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_musttail({{.*}} #[[UNSUPMUST:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call i64 @llvm.get.dynamic.area.offset.i64()
; VIRT: define {{.*}} @unsupported_bundle({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fastcc({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_sret({{.*}} #[[UNSUP]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPMUST]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPMUST]] = { {{.*}}"hikari.vmp.selected"
; VIRT-NOT: attributes #[[UNSUP]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
; Native reference: target expands the offset to 0, so add(seed, 0)
; is just ret.  VMP still replays the call in IR; llc of the
; interpreter uses xzr for that zero.
; AARCH64-ASM-LABEL: reference:
; AARCH64-ASM: ret
; AARCH64-ASM: xzr
