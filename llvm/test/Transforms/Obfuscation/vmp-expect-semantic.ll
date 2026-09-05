; RUN: opt -S -verify-each -aesSeed=73 -passes='default<O0>' %s -o %t.o0.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=73 -passes='default<O2>' %s -o %t.o2.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: FileCheck %s < %t.o0.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare i1 @llvm.expect.i1(i1, i1)

define i32 @reference(i32 %x) {
entry:
  %cmp = icmp sgt i32 %x, 0
  %likely = call i1 @llvm.expect.i1(i1 %cmp, i1 true)
  br i1 %likely, label %pos, label %nonpos

pos:
  %p = add i32 %x, 1
  br label %done

nonpos:
  %n = sub i32 1, %x
  br label %done

done:
  %result = phi i32 [ %p, %pos ], [ %n, %nonpos ]
  ret i32 %result
}

define i32 @protected(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %cmp = icmp sgt i32 %x, 0
  %likely = call i1 @llvm.expect.i1(i1 %cmp, i1 true)
  br i1 %likely, label %pos, label %nonpos

pos:
  %p = add i32 %x, 1
  br label %done

nonpos:
  %n = sub i32 1, %x
  br label %done

done:
  %result = phi i32 [ %p, %pos ], [ %n, %nonpos ]
  ret i32 %result
}

define i32 @main() {
entry:
  %e0 = call i32 @reference(i32 5)
  %a0 = call i32 @protected(i32 5)
  %e1 = call i32 @reference(i32 -3)
  %a1 = call i32 @protected(i32 -3)
  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %e1, %a1
  %ok = and i1 %m0, %m1
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; CHECK-LABEL: define i32 @protected(
; CHECK: vmp.dispatch:
; CHECK-NOT: call {{.*}}@llvm.expect
; CHECK: "hikari.vmp.virtualized"
