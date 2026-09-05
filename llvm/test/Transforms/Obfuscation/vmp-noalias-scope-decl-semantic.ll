; llvm.experimental.noalias.scope.decl is dropped by ID like lifetime
; (no CallDescriptor replay, no VM opcode).  Default O2 inlining
; inserts these for noalias arguments; the marker must never skip
; the function — including tail, fastcc, musttail-on-the-marker, or
; a deopt bundle on the marker.  Companion !alias.scope / !noalias on
; rebuilt native memory ops is stripped in applyMetadata so scoped-AA
; is not promised without a live declaration; other metadata (e.g.
; !tbaa) is kept.  A real musttail of another function still skips.
; Does not open TLS, assume bundles, or other markers.  Host lli can
; run the integer payload; FileCheck + AArch64 llc/readobj.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: FileCheck %s --check-prefix=MEM < %t.o0.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.ll -o %t.o0.o
; RUN: llvm-readobj -h %t.o0.o | FileCheck %s --check-prefix=AARCH64
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: FileCheck %s --check-prefix=MEM < %t.o2.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.ll -o %t.o2.o
; RUN: llvm-readobj -h %t.o2.o | FileCheck %s --check-prefix=AARCH64
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O0>' %s -o %t.o0.s7.ll 2>%t.o0.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: FileCheck %s --check-prefix=MEM < %t.o0.s7.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.ll -o %t.o0.s7.o
; RUN: llvm-readobj -h %t.o0.s7.o | FileCheck %s --check-prefix=AARCH64
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: FileCheck %s --check-prefix=MEM < %t.o2.s7.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.ll -o %t.o2.s7.o
; RUN: llvm-readobj -h %t.o2.s7.o | FileCheck %s --check-prefix=AARCH64

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare void @llvm.experimental.noalias.scope.decl(metadata)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture)

define void @sink_void() {
entry:
  ret void
}

define i32 @reference_noscopedecl(i32 %x) {
entry:
  call void @llvm.experimental.noalias.scope.decl(metadata !2)
  %r = add i32 %x, 1
  ret i32 %r
}

define i32 @protected_noscopedecl(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.experimental.noalias.scope.decl(metadata !2)
  %r = add i32 %x, 1
  ret i32 %r
}

define i32 @protected_noscopedecl_tail(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  tail call void @llvm.experimental.noalias.scope.decl(metadata !2)
  %r = add i32 %x, 2
  ret i32 %r
}

define i32 @protected_noscopedecl_two(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.experimental.noalias.scope.decl(metadata !2)
  call void @llvm.experimental.noalias.scope.decl(metadata !6)
  %r = add i32 %x, 3
  ret i32 %r
}

define i32 @protected_noscopedecl_lifetime(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %slot = alloca i32, align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr %slot)
  call void @llvm.experimental.noalias.scope.decl(metadata !2)
  store i32 %x, ptr %slot, align 4
  %v = load i32, ptr %slot, align 4
  call void @llvm.lifetime.end.p0(i64 4, ptr %slot)
  %r = add i32 %v, 4
  ret i32 %r
}

define i32 @reference_noscopedecl_mem(i32 %x) {
entry:
  %slot = alloca i32, align 4
  %other = alloca i32, align 4
  call void @llvm.experimental.noalias.scope.decl(metadata !2)
  store i32 %x, ptr %slot, align 4, !alias.scope !2, !tbaa !10
  store i32 1, ptr %other, align 4, !noalias !2, !tbaa !10
  %v = load i32, ptr %slot, align 4, !alias.scope !2, !tbaa !10
  %w = load i32, ptr %other, align 4, !noalias !2, !tbaa !10
  %r = add i32 %v, %w
  ret i32 %r
}

define i32 @protected_noscopedecl_mem(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %slot = alloca i32, align 4
  %other = alloca i32, align 4
  call void @llvm.experimental.noalias.scope.decl(metadata !2)
  store i32 %x, ptr %slot, align 4, !alias.scope !2, !tbaa !10
  store i32 1, ptr %other, align 4, !noalias !2, !tbaa !10
  %v = load i32, ptr %slot, align 4, !alias.scope !2, !tbaa !10
  %w = load i32, ptr %other, align 4, !noalias !2, !tbaa !10
  %r = add i32 %v, %w
  ret i32 %r
}

define i32 @protected_noscopedecl_phi(i32 %x, i1 %p) noinline optnone {
entry:
  call void @hikari_vmp()
  br i1 %p, label %left, label %right
left:
  call void @llvm.experimental.noalias.scope.decl(metadata !2)
  %l = add i32 %x, 5
  br label %join
right:
  call void @llvm.experimental.noalias.scope.decl(metadata !6)
  %rgt = add i32 %x, 6
  br label %join
join:
  %q = phi i32 [ %l, %left ], [ %rgt, %right ]
  ret i32 %q
}

define i32 @protected_noscopedecl_loop(i32 %x, i32 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  br label %hdr
hdr:
  %acc = phi i32 [ %x, %entry ], [ %nxt, %hdr ]
  %i = phi i32 [ 0, %entry ], [ %i.nxt, %hdr ]
  call void @llvm.experimental.noalias.scope.decl(metadata !2)
  %nxt = add i32 %acc, 1
  %i.nxt = add i32 %i, 1
  %more = icmp ult i32 %i.nxt, %n
  br i1 %more, label %hdr, label %done
done:
  ret i32 %nxt
}

define i32 @protected_noscopedecl_fastcc(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  call fastcc void @llvm.experimental.noalias.scope.decl(metadata !2)
  %r = add i32 %x, 7
  ret i32 %r
}

define void @protected_noscopedecl_musttail() noinline optnone {
entry:
  call void @hikari_vmp()
  musttail call void @llvm.experimental.noalias.scope.decl(metadata !2)
  ret void
}

define i32 @protected_noscopedecl_bundle(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.experimental.noalias.scope.decl(metadata !2) [ "deopt"(i32 0) ]
  %r = add i32 %x, 8
  ret i32 %r
}

define void @unsupported_musttail_sink() noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.experimental.noalias.scope.decl(metadata !2)
  musttail call void @sink_void()
  ret void
}

define i32 @main() {
entry:
  %e0 = call i32 @reference_noscopedecl(i32 40)
  %a0 = call i32 @protected_noscopedecl(i32 40)
  %e1 = call i32 @reference_noscopedecl(i32 7)
  %a1 = call i32 @protected_noscopedecl(i32 7)
  %a2 = call i32 @protected_noscopedecl_tail(i32 40)
  %a3 = call i32 @protected_noscopedecl_two(i32 40)
  %a4 = call i32 @protected_noscopedecl_lifetime(i32 40)
  %em = call i32 @reference_noscopedecl_mem(i32 40)
  %am = call i32 @protected_noscopedecl_mem(i32 40)
  %a5 = call i32 @protected_noscopedecl_phi(i32 40, i1 true)
  %a6 = call i32 @protected_noscopedecl_loop(i32 40, i32 2)
  %a7 = call i32 @protected_noscopedecl_fastcc(i32 40)
  %a8 = call i32 @protected_noscopedecl_bundle(i32 40)
  call void @protected_noscopedecl_musttail()
  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %e1, %a1
  %m2 = icmp eq i32 %a2, 42
  %m3 = icmp eq i32 %a3, 43
  %m4 = icmp eq i32 %a4, 44
  %mm = icmp eq i32 %em, %am
  %m5 = icmp eq i32 %a5, 45
  %m6 = icmp eq i32 %a6, 42
  %m7 = icmp eq i32 %a7, 47
  %m8 = icmp eq i32 %a8, 48
  %t0 = and i1 %m0, %m1
  %t1 = and i1 %m2, %m3
  %t2 = and i1 %m4, %mm
  %t3 = and i1 %m5, %m6
  %t4 = and i1 %m7, %m8
  %ok0 = and i1 %t0, %t1
  %ok1 = and i1 %t2, %t3
  %ok2 = and i1 %ok1, %t4
  %ok = and i1 %ok0, %ok2
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

!2 = !{!3}
!3 = distinct !{!3, !4, !"sink: %p"}
!4 = distinct !{!4, !"sink"}
!6 = !{!7}
!7 = distinct !{!7, !4, !"sink: %q"}
!10 = !{!11, !11, i64 0}
!11 = !{!"int", !12, i64 0}
!12 = !{!"omnipotent char", !13, i64 0}
!13 = !{!"Simple C/C++ TBAA"}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_musttail_sink: musttail call
; SKIP-NOT: Skipping VMP on protected_noscopedecl:
; SKIP-NOT: Skipping VMP on protected_noscopedecl_tail:
; SKIP-NOT: Skipping VMP on protected_noscopedecl_two:
; SKIP-NOT: Skipping VMP on protected_noscopedecl_lifetime:
; SKIP-NOT: Skipping VMP on protected_noscopedecl_mem:
; SKIP-NOT: Skipping VMP on protected_noscopedecl_phi:
; SKIP-NOT: Skipping VMP on protected_noscopedecl_loop:
; SKIP-NOT: Skipping VMP on protected_noscopedecl_fastcc:
; SKIP-NOT: Skipping VMP on protected_noscopedecl_musttail:
; SKIP-NOT: Skipping VMP on protected_noscopedecl_bundle:
; SKIP-NOT: Skipping VMP on reference_noscopedecl:

; VIRT: define i32 @protected_noscopedecl({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: noalias.scope.decl
; VIRT: define i32 @protected_noscopedecl_tail({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: tail call
; VIRT-NOT: noalias.scope.decl
; VIRT: define i32 @protected_noscopedecl_two({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: noalias.scope.decl
; VIRT: define i32 @protected_noscopedecl_lifetime({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: llvm.lifetime.start
; VIRT-NOT: llvm.lifetime.end
; VIRT-NOT: noalias.scope.decl
; VIRT: define i32 @reference_noscopedecl_mem(
; VIRT: define i32 @protected_noscopedecl_mem({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: noalias.scope.decl
; VIRT-NOT: !alias.scope
; VIRT-NOT: !noalias
; VIRT: define i32 @protected_noscopedecl_phi({{.*}} #[[PROT]] {

; MEM: define i32 @protected_noscopedecl_mem(
; MEM: vmp.dispatch:
; MEM-DAG: store i32 {{.*}}, align 4, !tbaa !{{[0-9]+}}{{$}}
; MEM-DAG: store i32 {{.*}}, align 4, !tbaa !{{[0-9]+}}{{$}}
; MEM-DAG: load i32, {{.*}}align 4, !tbaa !{{[0-9]+}}{{$}}
; MEM-DAG: load i32, {{.*}}align 4, !tbaa !{{[0-9]+}}{{$}}
; VIRT: vmp.dispatch:
; VIRT-NOT: noalias.scope.decl
; VIRT: define i32 @protected_noscopedecl_loop({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: noalias.scope.decl
; VIRT: define i32 @protected_noscopedecl_fastcc({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: noalias.scope.decl
; VIRT: define void @protected_noscopedecl_musttail({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: musttail call
; VIRT-NOT: noalias.scope.decl
; VIRT: define i32 @protected_noscopedecl_bundle({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT-NOT: deopt
; VIRT-NOT: noalias.scope.decl
; VIRT: define {{.*}} @unsupported_musttail_sink({{.*}} #[[UNSUP_MT:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: musttail call void @sink_void(
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT-NOT: attributes #[[UNSUP_MT]] = { {{.*}}"hikari.vmp.virtualized"

; AARCH64: Arch: aarch64
