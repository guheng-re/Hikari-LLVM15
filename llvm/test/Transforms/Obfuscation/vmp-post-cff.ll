; RUN: opt -S -verify-each -aesSeed=73 -passes='default<O0>' %s -o %t.default.ll
; RUN: opt -S -verify-each -aesSeed=73 -passes='default<O0>' %s -o %t.repeat.ll
; RUN: diff %t.default.ll %t.repeat.ll
; RUN: opt -S -verify-each -aesSeed=74 -passes='default<O0>' %s -o %t.other-seed.ll
; RUN: not cmp -s %t.default.ll %t.other-seed.ll
; RUN: FileCheck %s --check-prefix=DEFAULT < %t.default.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.default.ll > %t.default.host.ll
; RUN: lli -force-interpreter %t.default.host.ll
; RUN: %python %S/Inputs/vmp-tamper-bytecode.py %t.default.ll %t.tampered.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.tampered.ll > %t.tampered.host.ll
; RUN: not lli -force-interpreter %t.tampered.host.ll
; RUN: opt -S -verify-each -aesSeed=73 -vmp-integrity-check=false -passes='default<O0>' %s -o %t.no-integrity.ll
; RUN: not grep -E 'vmp\.integrity|llvm\.trap' %t.no-integrity.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.no-integrity.ll > %t.no-integrity.host.ll
; RUN: lli -force-interpreter %t.no-integrity.host.ll
; RUN: opt -S -verify-each -aesSeed=73 -passes='default<O2>' %s -o %t.o2.ll
; RUN: FileCheck %s --check-prefix=O2 < %t.o2.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: opt -S -verify-each -aesSeed=73 -passes='lto<O2>' %s -o %t.lto.ll
; RUN: FileCheck %s --check-prefix=LTO < %t.lto.ll
; RUN: opt -enable-new-pm=0 -S -verify-each -O0 -aesSeed=73 %s -o %t.legacy.ll
; RUN: FileCheck %s --check-prefix=LEGACY < %t.legacy.ll
; RUN: opt -S -verify-each -aesSeed=73 -enable-cffobf -passes='default<O0>' %s -o %t.normal-global.ll
; RUN: FileCheck %s --check-prefix=NORMAL-GLOBAL < %t.normal-global.ll
; RUN: opt -S -verify-each -aesSeed=73 -enable-vmp-post-cff -passes='default<O0>' %s -o %t.global.ll
; RUN: FileCheck %s --check-prefix=GLOBAL < %t.global.ll
; RUN: opt -S -verify-each -aesSeed=73 -vmp-post-cff-max-blocks=1 -passes='default<O0>' %s -o %t.block-budget.ll 2>&1 | FileCheck %s --check-prefix=BUDGET
; RUN: opt -S -verify-each -aesSeed=73 -vmp-post-cff-max-insts=1 -passes='default<O0>' %s -o %t.inst-budget.ll 2>&1 | FileCheck %s --check-prefix=INST-BUDGET
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.default.ll -o %t.aarch64.o
; RUN: llvm-readobj -h %t.aarch64.o | FileCheck %s --check-prefix=AARCH64
; RUN: clang -target aarch64-unknown-linux-gnu -O0 -c %s -o %t.clang.aarch64.o

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare void @hikari_fla()
declare void @hikari_nofla()

define i32 @combo(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @hikari_fla()
  %positive = icmp sgt i32 %x, 0
  br i1 %positive, label %then, label %otherwise

then:
  %then.value = add i32 %x, 1
  br label %merge

otherwise:
  %otherwise.value = sub i32 1, %x
  br label %merge

merge:
  %result = phi i32 [ %then.value, %then ], [ %otherwise.value, %otherwise ]
  ret i32 %result
}

define i32 @vmp.only(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %result = add i32 %x, 2
  ret i32 %result
}

define i32 @nofla.wins(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  call void @hikari_fla()
  call void @hikari_nofla()
  %result = add i32 %x, 3
  ret i32 %result
}

define i32 @plain.fla(i32 %x) noinline optnone {
entry:
  call void @hikari_fla()
  %test = icmp eq i32 %x, 0
  br i1 %test, label %zero, label %nonzero

zero:
  br label %done

nonzero:
  br label %done

done:
  %result = phi i32 [ 8, %zero ], [ 9, %nonzero ]
  ret i32 %result
}

define i32 @direct.attr(i32 %x) noinline optnone {
entry:
  %test = icmp eq i32 %x, 0
  br i1 %test, label %zero, label %nonzero

zero:
  ret i32 10

nonzero:
  ret i32 11
}

define i32 @main() {
entry:
  %combo = call i32 @combo(i32 4)
  %vmp = call i32 @vmp.only(i32 4)
  %nofla = call i32 @nofla.wins(i32 4)
  %plain = call i32 @plain.fla(i32 4)
  %direct = call i32 @direct.attr(i32 4)
  %sum.0 = add i32 %combo, %vmp
  %sum.1 = add i32 %sum.0, %nofla
  %sum.2 = add i32 %sum.1, %plain
  %sum.3 = add i32 %sum.2, %direct
  %ok = icmp eq i32 %sum.3, 38
  %result = select i1 %ok, i32 0, i32 1
  ret i32 %result
}

; DEFAULT-NOT: @hikari_
; DEFAULT-LABEL: define i32 @combo(
; DEFAULT: %switchVar = alloca i32
; DEFAULT: vmp.integrity.loop:
; DEFAULT: call void @llvm.trap()
; DEFAULT-LABEL: define i32 @vmp.only(
; DEFAULT-NOT: switchVar
; DEFAULT: vmp.dispatch:
; DEFAULT-LABEL: define i32 @nofla.wins(
; DEFAULT-NOT: switchVar
; DEFAULT: vmp.dispatch:
; DEFAULT-LABEL: define i32 @plain.fla(
; DEFAULT: %switchVar = alloca i32
; DEFAULT-LABEL: define i32 @direct.attr(
; DEFAULT-NOT: vmp.dispatch:
; DEFAULT-COUNT-1: "hikari.vmp.post.cff.applied"

; O2-LABEL: define i32 @combo(
; O2: %switchVar = alloca i32
; O2: "hikari.vmp.post.cff.applied"

; LTO-LABEL: define i32 @combo(
; LTO: %switchVar = alloca i32
; LTO: "hikari.vmp.post.cff.applied"

; LEGACY-LABEL: define i32 @combo(
; LEGACY: %switchVar = alloca i32
; LEGACY: "hikari.vmp.post.cff.applied"

; NORMAL-GLOBAL-LABEL: define i32 @vmp.only(
; NORMAL-GLOBAL-NOT: switchVar
; NORMAL-GLOBAL: vmp.dispatch:

; GLOBAL-LABEL: define i32 @vmp.only(
; GLOBAL: %switchVar = alloca i32
; GLOBAL-LABEL: define i32 @nofla.wins(
; GLOBAL-NOT: switchVar
; GLOBAL: vmp.dispatch:
; GLOBAL-COUNT-1: "hikari.vmp.post.cff.applied"

; BUDGET: Skipping VMP post-CFF on combo: basic-block budget exceeded
; INST-BUDGET: Skipping VMP post-CFF on combo: instruction budget exceeded

; AARCH64: Arch: aarch64
