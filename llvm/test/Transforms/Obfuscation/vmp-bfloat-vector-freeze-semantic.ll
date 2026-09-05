; Last-token +bf16 FreezeInst on supported fixed 1..128 bfloat
; vectors.  Reuses the existing vector VReg frame and VectorFreeze
; opcode (native typed CreateFreeze).  Defined sources load from the
; frame; undef/poison may appear only at the FreezeInst and use the
; established VectorFreeze source-kind materialization.  No new
; opcode, no float math, no FastMathFlags.
;
; Exact last-token +bf16 only (+bf16fml / +fullfp16 do not count;
; command-line -mattr is never read).  Well-shaped freeze missing or
; ending in -bf16 skips as unsupported target feature and keeps
; hikari.vmp.selected.
;
; Host x86 cannot be assumed to select bfloat.  This lit is FileCheck
; + AArch64 llc/readobj only (function +bf16, no global -mattr).
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.ll > %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.ll > %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.s7.ll > %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.s7.ll > %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()

; ----- positives -----

define <4 x bfloat> @protected_freeze_v4(<4 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %f = freeze <4 x bfloat> %a
  ret <4 x bfloat> %f
}

define <1 x bfloat> @protected_freeze_v1(<1 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %f = freeze <1 x bfloat> %a
  ret <1 x bfloat> %f
}

define <2 x bfloat> @protected_freeze_v2(<2 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %f = freeze <2 x bfloat> %a
  ret <2 x bfloat> %f
}

define <8 x bfloat> @protected_freeze_v8(<8 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %f = freeze <8 x bfloat> %a
  ret <8 x bfloat> %f
}

define <4 x bfloat> @protected_freeze_const() noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %f = freeze <4 x bfloat> <bfloat 0xR3F80, bfloat 0xR0000, bfloat 0xRBF80, bfloat 0xR4000>
  ret <4 x bfloat> %f
}

; Virtualized but not executed: do not compare frozen undef/poison bits.
define <4 x bfloat> @protected_freeze_undef() noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %f = freeze <4 x bfloat> undef
  ret <4 x bfloat> %f
}

define <4 x bfloat> @protected_freeze_poison() noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %f = freeze <4 x bfloat> poison
  ret <4 x bfloat> %f
}

define <4 x bfloat> @protected_freeze_phi(i1 %c, <4 x bfloat> %a, <4 x bfloat> %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  br i1 %c, label %left, label %right

left:
  br label %join

right:
  br label %join

join:
  %p = phi <4 x bfloat> [ %a, %left ], [ %b, %right ]
  %f = freeze <4 x bfloat> %p
  ret <4 x bfloat> %f
}

define <4 x bfloat> @protected_freeze_select(i1 %c, <4 x bfloat> %a, <4 x bfloat> %b) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %s = select i1 %c, <4 x bfloat> %a, <4 x bfloat> %b
  %f = freeze <4 x bfloat> %s
  ret <4 x bfloat> %f
}

define <4 x bfloat> @protected_freeze_loop(<4 x bfloat> %a, i32 %n) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  br label %loop

loop:
  %iv = phi i32 [ 0, %entry ], [ %iv.next, %loop ]
  %acc = phi <4 x bfloat> [ %a, %entry ], [ %fr, %loop ]
  %fr = freeze <4 x bfloat> %acc
  %iv.next = add i32 %iv, 1
  %cmp = icmp slt i32 %iv.next, %n
  br i1 %cmp, label %loop, label %done

done:
  ret <4 x bfloat> %fr
}

define <4 x bfloat> @protected_last_token(<4 x bfloat> %a) noinline optnone "target-features"="+neon,+bf16" {
entry:
  call void @hikari_vmp()
  %f = freeze <4 x bfloat> %a
  ret <4 x bfloat> %f
}

; ----- negatives -----

define i32 @unsupported_no_feature() noinline optnone {
entry:
  call void @hikari_vmp()
  %f = freeze <4 x bfloat> zeroinitializer
  ret i32 0
}

define i32 @unsupported_disabled() noinline optnone "target-features"="+neon,+bf16,-bf16" {
entry:
  call void @hikari_vmp()
  %f = freeze <4 x bfloat> zeroinitializer
  ret i32 0
}

define i32 @unsupported_bf16fml_only() noinline optnone "target-features"="+bf16fml" {
entry:
  call void @hikari_vmp()
  %f = freeze <4 x bfloat> zeroinitializer
  ret i32 0
}

define i32 @unsupported_wide() noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %f = freeze <16 x bfloat> zeroinitializer
  ret i32 0
}

define i32 @unsupported_scalable() noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %f = freeze <vscale x 4 x bfloat> zeroinitializer
  ret i32 0
}

define i32 @unsupported_ptrvec() noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %f = freeze <2 x ptr> zeroinitializer
  ret i32 0
}

define i32 @unsupported_agg() noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %f = freeze { bfloat } zeroinitializer
  ret i32 0
}

; Poison remains closed outside FreezeInst.
define <4 x bfloat> @unsupported_poison_select(i1 %c, <4 x bfloat> %a) noinline optnone "target-features"="+bf16" {
entry:
  call void @hikari_vmp()
  %s = select i1 %c, <4 x bfloat> poison, <4 x bfloat> %a
  ret <4 x bfloat> %s
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_no_feature: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_disabled: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_bf16fml_only: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_wide: unsupported freeze instruction
; SKIP-DAG: Skipping VMP on unsupported_scalable: unsupported freeze instruction
; SKIP-DAG: Skipping VMP on unsupported_ptrvec: unsupported freeze instruction
; SKIP-DAG: Skipping VMP on unsupported_agg: unsupported freeze instruction
; SKIP-DAG: Skipping VMP on unsupported_poison_select: unsupported
; SKIP-NOT: Skipping VMP on protected_freeze_v4:
; SKIP-NOT: Skipping VMP on protected_freeze_v1:
; SKIP-NOT: Skipping VMP on protected_freeze_v2:
; SKIP-NOT: Skipping VMP on protected_freeze_v8:
; SKIP-NOT: Skipping VMP on protected_freeze_const:
; SKIP-NOT: Skipping VMP on protected_freeze_undef:
; SKIP-NOT: Skipping VMP on protected_freeze_poison:
; SKIP-NOT: Skipping VMP on protected_freeze_phi:
; SKIP-NOT: Skipping VMP on protected_freeze_select:
; SKIP-NOT: Skipping VMP on protected_freeze_loop:
; SKIP-NOT: Skipping VMP on protected_last_token:

; VIRT: define <4 x bfloat> @protected_freeze_v4({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; Typed freeze in the interpreter; original hikari_vmp body is gone.
; VIRT-NOT: call void @hikari_vmp()
; VIRT-NOT: fadd
; VIRT: freeze <4 x bfloat>
; VIRT: define <1 x bfloat> @protected_freeze_v1({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: call void @hikari_vmp()
; VIRT: freeze <1 x bfloat>
; VIRT: define <2 x bfloat> @protected_freeze_v2({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: freeze <2 x bfloat>
; VIRT: define <8 x bfloat> @protected_freeze_v8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: freeze <8 x bfloat>
; VIRT: define <4 x bfloat> @protected_freeze_const({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: freeze <4 x bfloat>
; VIRT: define <4 x bfloat> @protected_freeze_undef({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: freeze <4 x bfloat> undef
; VIRT: define <4 x bfloat> @protected_freeze_poison({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: freeze <4 x bfloat> poison
; VIRT: define <4 x bfloat> @protected_freeze_phi({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; Original SSA phi is VReg traffic; freeze is typed in the handler.
; VIRT: freeze <4 x bfloat>
; VIRT: define <4 x bfloat> @protected_freeze_select({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; Bfloat select stays on the i16 bit path; freeze is still typed.
; VIRT-DAG: select
; VIRT-DAG: freeze <4 x bfloat>
; VIRT: define <4 x bfloat> @protected_freeze_loop({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: freeze <4 x bfloat>
; VIRT: define <4 x bfloat> @protected_last_token({{.*}} #[[PROTLAST:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: freeze <4 x bfloat>
; VIRT: define {{.*}} @unsupported_no_feature({{.*}} #[[UNSUPFEAT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_disabled({{.*}} #[[UNSUPDIS:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_bf16fml_only({{.*}} #[[UNSUPFML:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_wide({{.*}} #[[UNSUPFRZ:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_scalable({{.*}} #[[UNSUPFRZ]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ptrvec({{.*}} #[[UNSUPFRZ]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_agg({{.*}} #[[UNSUPFRZ]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_poison_select({{.*}} #[[UNSUPFRZ]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[PROTLAST]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPFEAT]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT: attributes #[[UNSUPDIS]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT: attributes #[[UNSUPFML]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT: attributes #[[UNSUPFRZ]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPFEAT]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPDIS]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPFML]] = { {{.*}}"hikari.vmp.virtualized"
; VIRT-NOT: attributes #[[UNSUPFRZ]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
