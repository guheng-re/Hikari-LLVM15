; Ordinary llvm.memset / memcpy / memmove with a runtime i32/i64 length
; (argument, SSA, or constant).  Length travels through integer VRegs and
; the intrinsic is re-emitted.  memcpy.inline stays ImmArg-constant-only;
; atomic mem* rules are unchanged.
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

declare void @hikari_vmp()
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg)
declare void @llvm.memmove.p0.p0.i64(ptr nocapture writeonly, ptr nocapture readonly, i64, i1 immarg)
declare void @llvm.memset.p0.i32(ptr nocapture writeonly, i8, i32, i1 immarg)
declare void @llvm.memcpy.p0.p0.i32(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i32, i1 immarg)
declare void @llvm.memmove.p0.p0.i32(ptr nocapture writeonly, ptr nocapture readonly, i32, i1 immarg)
declare void @llvm.memset.p0.i8(ptr nocapture writeonly, i8, i8, i1 immarg)

define i32 @fold16(ptr %p) {
entry:
  %p0 = load i8, ptr %p, align 1
  %p1p = getelementptr inbounds i8, ptr %p, i64 1
  %p1 = load i8, ptr %p1p, align 1
  %p2p = getelementptr inbounds i8, ptr %p, i64 2
  %p2 = load i8, ptr %p2p, align 1
  %p3p = getelementptr inbounds i8, ptr %p, i64 3
  %p3 = load i8, ptr %p3p, align 1
  %z0 = zext i8 %p0 to i32
  %z1 = zext i8 %p1 to i32
  %z2 = zext i8 %p2 to i32
  %z3 = zext i8 %p3 to i32
  %s0 = add i32 %z0, %z1
  %s1 = add i32 %z2, %z3
  %r = xor i32 %s0, %s1
  ret i32 %r
}

; Runtime i64 length: memset, memcpy, then overlapping memmove (dest after src).
define i32 @reference(i64 %n, i32 %seed) noinline optnone {
entry:
  %buf = alloca [16 x i8], align 1
  %dst = alloca [16 x i8], align 1
  %fill = trunc i32 %seed to i8
  call void @llvm.memset.p0.i64(ptr %buf, i8 %fill, i64 %n, i1 false)
  call void @llvm.memcpy.p0.p0.i64(ptr %dst, ptr %buf, i64 %n, i1 false)
  %after = getelementptr inbounds i8, ptr %buf, i64 1
  call void @llvm.memmove.p0.p0.i64(ptr %after, ptr %buf, i64 %n, i1 false)
  %a = call i32 @fold16(ptr %dst)
  %b = call i32 @fold16(ptr %buf)
  %c = xor i32 %a, %b
  %out = xor i32 %c, %seed
  ret i32 %out
}

define i32 @protected(i64 %n, i32 %seed) noinline optnone {
entry:
  call void @hikari_vmp()
  %buf = alloca [16 x i8], align 1
  %dst = alloca [16 x i8], align 1
  %fill = trunc i32 %seed to i8
  call void @llvm.memset.p0.i64(ptr %buf, i8 %fill, i64 %n, i1 false)
  call void @llvm.memcpy.p0.p0.i64(ptr %dst, ptr %buf, i64 %n, i1 false)
  %after = getelementptr inbounds i8, ptr %buf, i64 1
  call void @llvm.memmove.p0.p0.i64(ptr %after, ptr %buf, i64 %n, i1 false)
  %a = call i32 @fold16(ptr %dst)
  %b = call i32 @fold16(ptr %buf)
  %c = xor i32 %a, %b
  %out = xor i32 %c, %seed
  ret i32 %out
}

; Runtime i32 length: same memset / memcpy / overlapping memmove sequence.
define i32 @reference_i32(i32 %n, i32 %seed) noinline optnone {
entry:
  %buf = alloca [16 x i8], align 1
  %dst = alloca [16 x i8], align 1
  %fill = trunc i32 %seed to i8
  call void @llvm.memset.p0.i32(ptr %buf, i8 %fill, i32 %n, i1 false)
  call void @llvm.memcpy.p0.p0.i32(ptr %dst, ptr %buf, i32 %n, i1 false)
  %after = getelementptr inbounds i8, ptr %buf, i64 1
  call void @llvm.memmove.p0.p0.i32(ptr %after, ptr %buf, i32 %n, i1 false)
  %a = call i32 @fold16(ptr %dst)
  %b = call i32 @fold16(ptr %buf)
  %c = xor i32 %a, %b
  %out = xor i32 %c, %seed
  ret i32 %out
}

define i32 @protected_i32(i32 %n, i32 %seed) noinline optnone {
entry:
  call void @hikari_vmp()
  %buf = alloca [16 x i8], align 1
  %dst = alloca [16 x i8], align 1
  %fill = trunc i32 %seed to i8
  call void @llvm.memset.p0.i32(ptr %buf, i8 %fill, i32 %n, i1 false)
  call void @llvm.memcpy.p0.p0.i32(ptr %dst, ptr %buf, i32 %n, i1 false)
  %after = getelementptr inbounds i8, ptr %buf, i64 1
  call void @llvm.memmove.p0.p0.i32(ptr %after, ptr %buf, i32 %n, i1 false)
  %a = call i32 @fold16(ptr %dst)
  %b = call i32 @fold16(ptr %buf)
  %c = xor i32 %a, %b
  %out = xor i32 %c, %seed
  ret i32 %out
}

define i32 @unsupported_mem_i8len(ptr %p, i8 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @llvm.memset.p0.i8(ptr %p, i8 0, i8 %n, i1 false)
  ret i32 0
}

define i32 @main() {
entry:
  %e0 = call i32 @reference(i64 4, i32 17)
  %a0 = call i32 @protected(i64 4, i32 17)
  %ok0 = icmp eq i32 %e0, %a0
  %e1 = call i32 @reference(i64 8, i32 17)
  %a1 = call i32 @protected(i64 8, i32 17)
  %ok1 = icmp eq i32 %e1, %a1
  %e2 = call i32 @reference_i32(i32 4, i32 17)
  %a2 = call i32 @protected_i32(i32 4, i32 17)
  %ok2 = icmp eq i32 %e2, %a2
  %e3 = call i32 @reference_i32(i32 8, i32 17)
  %a3 = call i32 @protected_i32(i32 8, i32 17)
  %ok3 = icmp eq i32 %e3, %a3
  %t0 = and i1 %ok0, %ok1
  %t1 = and i1 %ok2, %ok3
  %ok = and i1 %t0, %t1
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP-DAG: Skipping VMP on unsupported_mem_i8len: unsupported memset
; SKIP-NOT: Skipping VMP on protected:
; SKIP-NOT: Skipping VMP on protected_i32:
; SKIP-NOT: Skipping VMP on reference:
; SKIP-NOT: Skipping VMP on reference_i32:

; VIRT-LABEL: define i32 @protected(
; VIRT: vmp.dispatch:
; VIRT-DAG: call void @llvm.memset.p0.i64({{.*}}i64 {{.*}}, i1 false)
; VIRT-DAG: call void @llvm.memcpy.p0.p0.i64({{.*}}i64 {{.*}}, i1 false)
; VIRT-DAG: call void @llvm.memmove.p0.p0.i64({{.*}}i64 {{.*}}, i1 false)

; VIRT-LABEL: define i32 @protected_i32(
; VIRT: vmp.dispatch:
; VIRT-DAG: call void @llvm.memset.p0.i32({{.*}}i32 {{.*}}, i1 false)
; VIRT-DAG: call void @llvm.memcpy.p0.p0.i32({{.*}}i32 {{.*}}, i1 false)
; VIRT-DAG: call void @llvm.memmove.p0.p0.i32({{.*}}i32 {{.*}}, i1 false)
; VIRT: define {{.*}} @unsupported_mem_i8len({{.*}} #[[UNSUPATTR:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #{{[0-9]+}} = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.virtualized"