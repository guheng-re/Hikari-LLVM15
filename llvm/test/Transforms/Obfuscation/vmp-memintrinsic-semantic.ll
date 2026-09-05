; RUN: opt -S -verify-each -aesSeed=29 -passes='default<O0>' %s -o %t.o0.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=29 -passes='default<O2>' %s -o %t.o2.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: FileCheck %s < %t.o0.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg)
declare void @llvm.memmove.p0.p0.i64(ptr nocapture writeonly, ptr nocapture readonly, i64, i1 immarg)

; Single buffer exercises nonvolatile memset/memcpy plus both overlapping
; memmove directions.  Destination-after-source overlap fails if lowered as
; naive forward memcpy.
define i32 @reference(i32 %seed) {
entry:
  %buf = alloca [8 x i8], align 1
  call void @llvm.memset.p0.i64(ptr %buf, i8 0, i64 8, i1 false)
  store i32 %seed, ptr %buf, align 1
  %tail = getelementptr inbounds i8, ptr %buf, i64 4
  call void @llvm.memcpy.p0.p0.i64(ptr %tail, ptr %buf, i64 4, i1 false)
  ; dest after source: memmove(buf+1, buf, 4)
  %after = getelementptr inbounds i8, ptr %buf, i64 1
  call void @llvm.memmove.p0.p0.i64(ptr %after, ptr %buf, i64 4, i1 false)
  ; dest before source: memmove(buf, buf+1, 4)
  call void @llvm.memmove.p0.p0.i64(ptr %buf, ptr %after, i64 4, i1 false)
  %lo = load i32, ptr %buf, align 1
  %hi = load i32, ptr %tail, align 1
  %mixed = xor i32 %lo, %hi
  %result = add i32 %mixed, %seed
  ret i32 %result
}

define i32 @protected(i32 %seed) noinline optnone {
entry:
  call void @hikari_vmp()
  %buf = alloca [8 x i8], align 1
  call void @llvm.memset.p0.i64(ptr %buf, i8 0, i64 8, i1 false)
  store i32 %seed, ptr %buf, align 1
  %tail = getelementptr inbounds i8, ptr %buf, i64 4
  call void @llvm.memcpy.p0.p0.i64(ptr %tail, ptr %buf, i64 4, i1 false)
  %after = getelementptr inbounds i8, ptr %buf, i64 1
  call void @llvm.memmove.p0.p0.i64(ptr %after, ptr %buf, i64 4, i1 false)
  call void @llvm.memmove.p0.p0.i64(ptr %buf, ptr %after, i64 4, i1 false)
  %lo = load i32, ptr %buf, align 1
  %hi = load i32, ptr %tail, align 1
  %mixed = xor i32 %lo, %hi
  %result = add i32 %mixed, %seed
  ret i32 %result
}

define i32 @main() {
entry:
  %expected = call i32 @reference(i32 305419896)
  %actual = call i32 @protected(i32 305419896)
  %match = icmp eq i32 %expected, %actual
  %code = select i1 %match, i32 0, i32 1
  ret i32 %code
}

; CHECK-LABEL: define i32 @protected(
; CHECK: vmp.dispatch:
; CHECK-DAG: call void @llvm.memset.p0.i64({{.*}}, i1 false)
; CHECK-DAG: call void @llvm.memcpy.p0.p0.i64({{.*}}, i1 false)
; CHECK-DAG: call void @llvm.memmove.p0.p0.i64({{.*}}, i1 false)
; CHECK: "hikari.vmp.virtualized"
