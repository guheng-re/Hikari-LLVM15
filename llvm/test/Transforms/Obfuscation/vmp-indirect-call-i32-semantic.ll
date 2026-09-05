; Strict minimal AArch64 VMP indirect CallInst subset: same-width i1(i1),
; i8(i8), i16(i16), i32(i32), i64(i64), void(i32) callbacks, and same-width
; binary i1(i1,i1)/i8(i8,i8)/i16(i16,i16)/i32(i32,i32)/i64(i64,i64), and ternary
; i16(i16,i16,i16)/i32(i32,i32,i32)/i64(i64,i64,i64) via AS0 ptr, CallingConv::C,
; non-vararg.  Ternary i1/i8 stay rejected.  Direct calls stay on existing paths.
; Re-emitted as CreateCall(FunctionType*, Value*, Args) with callee from a
; pointer virtual register.  Mixed widths / void(i64) stay rejected.
;
; RUN: opt -S -verify-each -aesSeed=41 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o0.ll -o %t.o0.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.live.ll -o %t.o0.o
; RUN: opt -S -verify-each -aesSeed=41 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: opt -S -passes='internalize,globaldce' -internalize-public-api-list=main %t.o2.ll -o %t.o2.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.live.ll -o %t.o2.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll

target triple = "aarch64-unknown-linux-gnu"

@sink = global i32 0, align 4

declare void @hikari_vmp()

define i32 @add_one(i32 %x) noinline {
entry:
  %r = add i32 %x, 1
  ret i32 %r
}

define i32 @add_two(i32 %x) noinline {
entry:
  %r = add i32 %x, 2
  ret i32 %r
}

define i64 @add_one_i64(i64 %x) noinline {
entry:
  %r = add i64 %x, 1
  ret i64 %r
}

define i64 @add_two_i64(i64 %x) noinline {
entry:
  %r = add i64 %x, 2
  ret i64 %r
}

define i1 @not_i1(i1 %x) noinline {
entry:
  %r = xor i1 %x, true
  ret i1 %r
}

define i1 @id_i1(i1 %x) noinline {
entry:
  ret i1 %x
}

define i8 @add_one_i8(i8 %x) noinline {
entry:
  %r = add i8 %x, 1
  ret i8 %r
}

define i8 @add_two_i8(i8 %x) noinline {
entry:
  %r = add i8 %x, 2
  ret i8 %r
}

define i16 @add_one_i16(i16 %x) noinline {
entry:
  %r = add i16 %x, 1
  ret i16 %r
}

define i16 @add_two_i16(i16 %x) noinline {
entry:
  %r = add i16 %x, 2
  ret i16 %r
}

; void(i32) callbacks: side effects via @sink for semantic comparison.
define void @store_sink(i32 %x) noinline {
entry:
  store i32 %x, ptr @sink, align 4
  ret void
}

define void @store_neg_sink(i32 %x) noinline {
entry:
  %n = sub i32 0, %x
  store i32 %n, ptr @sink, align 4
  ret void
}

; Fixed binary i32(i32, i32) -> i32 helpers.
define i32 @add_i32(i32 %a, i32 %b) noinline {
entry:
  %r = add i32 %a, %b
  ret i32 %r
}

define i32 @sub_i32(i32 %a, i32 %b) noinline {
entry:
  %r = sub i32 %a, %b
  ret i32 %r
}

; Same-width binary i64(i64, i64) -> i64 helpers.
define i64 @add_i64(i64 %a, i64 %b) noinline {
entry:
  %r = add i64 %a, %b
  ret i64 %r
}

define i64 @sub_i64(i64 %a, i64 %b) noinline {
entry:
  %r = sub i64 %a, %b
  ret i64 %r
}

; Same-width binary i16(i16, i16) -> i16 helpers.
define i16 @add_i16_bin(i16 %a, i16 %b) noinline {
entry:
  %r = add i16 %a, %b
  ret i16 %r
}

define i16 @sub_i16_bin(i16 %a, i16 %b) noinline {
entry:
  %r = sub i16 %a, %b
  ret i16 %r
}

; Same-width binary i8(i8, i8) -> i8 helpers.
define i8 @add_i8_bin(i8 %a, i8 %b) noinline {
entry:
  %r = add i8 %a, %b
  ret i8 %r
}

define i8 @sub_i8_bin(i8 %a, i8 %b) noinline {
entry:
  %r = sub i8 %a, %b
  ret i8 %r
}

; Same-width binary i1(i1, i1) -> i1 helpers.
define i1 @and_i1_bin(i1 %a, i1 %b) noinline {
entry:
  %r = and i1 %a, %b
  ret i1 %r
}

define i1 @xor_i1_bin(i1 %a, i1 %b) noinline {
entry:
  %r = xor i1 %a, %b
  ret i1 %r
}

; Reference / protected: runtime function pointer via ptr argument (i32).
define i32 @reference_via_arg(ptr %fp, i32 %x) {
entry:
  %r = call i32 %fp(i32 %x)
  ret i32 %r
}

define i32 @protected_via_arg(ptr %fp, i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 %fp(i32 %x)
  ret i32 %r
}

; Reference / protected: runtime function pointer via select of globals (i32).
define i32 @reference_via_select(i1 %pick, i32 %x) {
entry:
  %fp = select i1 %pick, ptr @add_one, ptr @add_two
  %r = call i32 %fp(i32 %x)
  ret i32 %r
}

define i32 @protected_via_select(i1 %pick, i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %fp = select i1 %pick, ptr @add_one, ptr @add_two
  %r = call i32 %fp(i32 %x)
  ret i32 %r
}

; Reference / protected: same-width i64(i64) via ptr argument.
define i64 @reference_via_arg_i64(ptr %fp, i64 %x) {
entry:
  %r = call i64 %fp(i64 %x)
  ret i64 %r
}

define i64 @protected_via_arg_i64(ptr %fp, i64 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 %fp(i64 %x)
  ret i64 %r
}

; Reference / protected: i64(i64) via select of globals.
define i64 @reference_via_select_i64(i1 %pick, i64 %x) {
entry:
  %fp = select i1 %pick, ptr @add_one_i64, ptr @add_two_i64
  %r = call i64 %fp(i64 %x)
  ret i64 %r
}

define i64 @protected_via_select_i64(i1 %pick, i64 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %fp = select i1 %pick, ptr @add_one_i64, ptr @add_two_i64
  %r = call i64 %fp(i64 %x)
  ret i64 %r
}

; Reference / protected: same-width i1(i1) via ptr argument.
define i1 @reference_via_arg_i1(ptr %fp, i1 %x) {
entry:
  %r = call i1 %fp(i1 %x)
  ret i1 %r
}

define i1 @protected_via_arg_i1(ptr %fp, i1 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i1 %fp(i1 %x)
  ret i1 %r
}

; Reference / protected: i1(i1) via select of globals.
define i1 @reference_via_select_i1(i1 %pick, i1 %x) {
entry:
  %fp = select i1 %pick, ptr @not_i1, ptr @id_i1
  %r = call i1 %fp(i1 %x)
  ret i1 %r
}

define i1 @protected_via_select_i1(i1 %pick, i1 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %fp = select i1 %pick, ptr @not_i1, ptr @id_i1
  %r = call i1 %fp(i1 %x)
  ret i1 %r
}

; Reference / protected: same-width i8(i8) via ptr argument.
define i8 @reference_via_arg_i8(ptr %fp, i8 %x) {
entry:
  %r = call i8 %fp(i8 %x)
  ret i8 %r
}

define i8 @protected_via_arg_i8(ptr %fp, i8 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i8 %fp(i8 %x)
  ret i8 %r
}

; Reference / protected: i8(i8) via select of globals.
define i8 @reference_via_select_i8(i1 %pick, i8 %x) {
entry:
  %fp = select i1 %pick, ptr @add_one_i8, ptr @add_two_i8
  %r = call i8 %fp(i8 %x)
  ret i8 %r
}

define i8 @protected_via_select_i8(i1 %pick, i8 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %fp = select i1 %pick, ptr @add_one_i8, ptr @add_two_i8
  %r = call i8 %fp(i8 %x)
  ret i8 %r
}

; Reference / protected: same-width i16(i16) via ptr argument.
define i16 @reference_via_arg_i16(ptr %fp, i16 %x) {
entry:
  %r = call i16 %fp(i16 %x)
  ret i16 %r
}

define i16 @protected_via_arg_i16(ptr %fp, i16 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i16 %fp(i16 %x)
  ret i16 %r
}

; Reference / protected: i16(i16) via select of globals.
define i16 @reference_via_select_i16(i1 %pick, i16 %x) {
entry:
  %fp = select i1 %pick, ptr @add_one_i16, ptr @add_two_i16
  %r = call i16 %fp(i16 %x)
  ret i16 %r
}

define i16 @protected_via_select_i16(i1 %pick, i16 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %fp = select i1 %pick, ptr @add_one_i16, ptr @add_two_i16
  %r = call i16 %fp(i16 %x)
  ret i16 %r
}

; Reference / protected: void(i32) via ptr argument.
define void @reference_void_via_arg(ptr %fp, i32 %x) {
entry:
  call void %fp(i32 %x)
  ret void
}

define void @protected_void_via_arg(ptr %fp, i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  call void %fp(i32 %x)
  ret void
}

; Reference / protected: void(i32) via select of globals.
define void @reference_void_via_select(i1 %pick, i32 %x) {
entry:
  %fp = select i1 %pick, ptr @store_sink, ptr @store_neg_sink
  call void %fp(i32 %x)
  ret void
}

define void @protected_void_via_select(i1 %pick, i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %fp = select i1 %pick, ptr @store_sink, ptr @store_neg_sink
  call void %fp(i32 %x)
  ret void
}

; Reference / protected: fixed binary i32(i32, i32) via ptr argument.
define i32 @reference_binary_via_arg(ptr %fp, i32 %a, i32 %b) {
entry:
  %r = call i32 %fp(i32 %a, i32 %b)
  ret i32 %r
}

define i32 @protected_binary_via_arg(ptr %fp, i32 %a, i32 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 %fp(i32 %a, i32 %b)
  ret i32 %r
}

; Reference / protected: binary i32(i32, i32) via select of globals.
define i32 @reference_binary_via_select(i1 %pick, i32 %a, i32 %b) {
entry:
  %fp = select i1 %pick, ptr @add_i32, ptr @sub_i32
  %r = call i32 %fp(i32 %a, i32 %b)
  ret i32 %r
}

define i32 @protected_binary_via_select(i1 %pick, i32 %a, i32 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %fp = select i1 %pick, ptr @add_i32, ptr @sub_i32
  %r = call i32 %fp(i32 %a, i32 %b)
  ret i32 %r
}

; Reference / protected: same-width binary i64(i64, i64) via ptr argument.
define i64 @reference_binary_via_arg_i64(ptr %fp, i64 %a, i64 %b) {
entry:
  %r = call i64 %fp(i64 %a, i64 %b)
  ret i64 %r
}

define i64 @protected_binary_via_arg_i64(ptr %fp, i64 %a, i64 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 %fp(i64 %a, i64 %b)
  ret i64 %r
}

; Reference / protected: binary i64(i64, i64) via select of globals.
define i64 @reference_binary_via_select_i64(i1 %pick, i64 %a, i64 %b) {
entry:
  %fp = select i1 %pick, ptr @add_i64, ptr @sub_i64
  %r = call i64 %fp(i64 %a, i64 %b)
  ret i64 %r
}

define i64 @protected_binary_via_select_i64(i1 %pick, i64 %a, i64 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %fp = select i1 %pick, ptr @add_i64, ptr @sub_i64
  %r = call i64 %fp(i64 %a, i64 %b)
  ret i64 %r
}

; Reference / protected: same-width binary i16(i16, i16) via ptr argument.
define i16 @reference_binary_via_arg_i16(ptr %fp, i16 %a, i16 %b) {
entry:
  %r = call i16 %fp(i16 %a, i16 %b)
  ret i16 %r
}

define i16 @protected_binary_via_arg_i16(ptr %fp, i16 %a, i16 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i16 %fp(i16 %a, i16 %b)
  ret i16 %r
}

; Reference / protected: binary i16(i16, i16) via select of globals.
define i16 @reference_binary_via_select_i16(i1 %pick, i16 %a, i16 %b) {
entry:
  %fp = select i1 %pick, ptr @add_i16_bin, ptr @sub_i16_bin
  %r = call i16 %fp(i16 %a, i16 %b)
  ret i16 %r
}

define i16 @protected_binary_via_select_i16(i1 %pick, i16 %a, i16 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %fp = select i1 %pick, ptr @add_i16_bin, ptr @sub_i16_bin
  %r = call i16 %fp(i16 %a, i16 %b)
  ret i16 %r
}

; Reference / protected: same-width binary i8(i8, i8) via ptr argument.
define i8 @reference_binary_via_arg_i8(ptr %fp, i8 %a, i8 %b) {
entry:
  %r = call i8 %fp(i8 %a, i8 %b)
  ret i8 %r
}

define i8 @protected_binary_via_arg_i8(ptr %fp, i8 %a, i8 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i8 %fp(i8 %a, i8 %b)
  ret i8 %r
}

; Reference / protected: binary i8(i8, i8) via select of globals.
define i8 @reference_binary_via_select_i8(i1 %pick, i8 %a, i8 %b) {
entry:
  %fp = select i1 %pick, ptr @add_i8_bin, ptr @sub_i8_bin
  %r = call i8 %fp(i8 %a, i8 %b)
  ret i8 %r
}

define i8 @protected_binary_via_select_i8(i1 %pick, i8 %a, i8 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %fp = select i1 %pick, ptr @add_i8_bin, ptr @sub_i8_bin
  %r = call i8 %fp(i8 %a, i8 %b)
  ret i8 %r
}

; Reference / protected: same-width binary i1(i1, i1) via ptr argument.
define i1 @reference_binary_via_arg_i1(ptr %fp, i1 %a, i1 %b) {
entry:
  %r = call i1 %fp(i1 %a, i1 %b)
  ret i1 %r
}

define i1 @protected_binary_via_arg_i1(ptr %fp, i1 %a, i1 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i1 %fp(i1 %a, i1 %b)
  ret i1 %r
}

; Reference / protected: binary i1(i1, i1) via select of globals.
define i1 @reference_binary_via_select_i1(i1 %pick, i1 %a, i1 %b) {
entry:
  %fp = select i1 %pick, ptr @and_i1_bin, ptr @xor_i1_bin
  %r = call i1 %fp(i1 %a, i1 %b)
  ret i1 %r
}

define i1 @protected_binary_via_select_i1(i1 %pick, i1 %a, i1 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %fp = select i1 %pick, ptr @and_i1_bin, ptr @xor_i1_bin
  %r = call i1 %fp(i1 %a, i1 %b)
  ret i1 %r
}

; Fixed ternary i32(i32, i32, i32) -> i32 helpers.
define i32 @add3_i32(i32 %a, i32 %b, i32 %c) noinline {
entry:
  %t = add i32 %a, %b
  %r = add i32 %t, %c
  ret i32 %r
}

define i32 @mul_add_i32(i32 %a, i32 %b, i32 %c) noinline {
entry:
  %p = mul i32 %a, %b
  %r = add i32 %p, %c
  ret i32 %r
}

; Reference / protected: ternary i32(i32, i32, i32) via ptr argument.
define i32 @reference_ternary_via_arg(ptr %fp, i32 %a, i32 %b, i32 %c) {
entry:
  %r = call i32 %fp(i32 %a, i32 %b, i32 %c)
  ret i32 %r
}

define i32 @protected_ternary_via_arg(ptr %fp, i32 %a, i32 %b, i32 %c) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 %fp(i32 %a, i32 %b, i32 %c)
  ret i32 %r
}

; Reference / protected: ternary via select of globals.
define i32 @reference_ternary_via_select(i1 %pick, i32 %a, i32 %b, i32 %c) {
entry:
  %fp = select i1 %pick, ptr @add3_i32, ptr @mul_add_i32
  %r = call i32 %fp(i32 %a, i32 %b, i32 %c)
  ret i32 %r
}

define i32 @protected_ternary_via_select(i1 %pick, i32 %a, i32 %b, i32 %c) noinline optnone {
entry:
  call void @hikari_vmp()
  %fp = select i1 %pick, ptr @add3_i32, ptr @mul_add_i32
  %r = call i32 %fp(i32 %a, i32 %b, i32 %c)
  ret i32 %r
}

; Fixed ternary i64(i64, i64, i64) -> i64 helpers.
define i64 @add3_i64(i64 %a, i64 %b, i64 %c) noinline {
entry:
  %t = add i64 %a, %b
  %r = add i64 %t, %c
  ret i64 %r
}

define i64 @mul_add_i64(i64 %a, i64 %b, i64 %c) noinline {
entry:
  %p = mul i64 %a, %b
  %r = add i64 %p, %c
  ret i64 %r
}

; Reference / protected: ternary i64(i64, i64, i64) via ptr argument.
define i64 @reference_ternary_via_arg_i64(ptr %fp, i64 %a, i64 %b, i64 %c) {
entry:
  %r = call i64 %fp(i64 %a, i64 %b, i64 %c)
  ret i64 %r
}

define i64 @protected_ternary_via_arg_i64(ptr %fp, i64 %a, i64 %b, i64 %c) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 %fp(i64 %a, i64 %b, i64 %c)
  ret i64 %r
}

; Reference / protected: ternary i64 via select of globals.
define i64 @reference_ternary_via_select_i64(i1 %pick, i64 %a, i64 %b, i64 %c) {
entry:
  %fp = select i1 %pick, ptr @add3_i64, ptr @mul_add_i64
  %r = call i64 %fp(i64 %a, i64 %b, i64 %c)
  ret i64 %r
}

define i64 @protected_ternary_via_select_i64(i1 %pick, i64 %a, i64 %b, i64 %c) noinline optnone {
entry:
  call void @hikari_vmp()
  %fp = select i1 %pick, ptr @add3_i64, ptr @mul_add_i64
  %r = call i64 %fp(i64 %a, i64 %b, i64 %c)
  ret i64 %r
}

; Fixed ternary i16(i16, i16, i16) -> i16 helpers.
define i16 @add3_i16(i16 %a, i16 %b, i16 %c) noinline {
entry:
  %t = add i16 %a, %b
  %r = add i16 %t, %c
  ret i16 %r
}

define i16 @mul_add_i16(i16 %a, i16 %b, i16 %c) noinline {
entry:
  %p = mul i16 %a, %b
  %r = add i16 %p, %c
  ret i16 %r
}

; Reference / protected: ternary i16(i16, i16, i16) via ptr argument.
define i16 @reference_ternary_via_arg_i16(ptr %fp, i16 %a, i16 %b, i16 %c) {
entry:
  %r = call i16 %fp(i16 %a, i16 %b, i16 %c)
  ret i16 %r
}

define i16 @protected_ternary_via_arg_i16(ptr %fp, i16 %a, i16 %b, i16 %c) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i16 %fp(i16 %a, i16 %b, i16 %c)
  ret i16 %r
}

; Reference / protected: ternary i16 via select of globals.
define i16 @reference_ternary_via_select_i16(i1 %pick, i16 %a, i16 %b, i16 %c) {
entry:
  %fp = select i1 %pick, ptr @add3_i16, ptr @mul_add_i16
  %r = call i16 %fp(i16 %a, i16 %b, i16 %c)
  ret i16 %r
}

define i16 @protected_ternary_via_select_i16(i1 %pick, i16 %a, i16 %b, i16 %c) noinline optnone {
entry:
  call void @hikari_vmp()
  %fp = select i1 %pick, ptr @add3_i16, ptr @mul_add_i16
  %r = call i16 %fp(i16 %a, i16 %b, i16 %c)
  ret i16 %r
}

; Safety skips: vararg FunctionType.
define i32 @unsupported_vararg(ptr %fp, i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 (i32, ...) %fp(i32 %x)
  ret i32 %r
}

; Safety skips: mixed width i64(i32) — not same-width subset.
define i64 @unsupported_mixed_i64_i32(ptr %fp, i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 %fp(i32 %x)
  ret i64 %r
}

; Safety skips: mixed width i32(i64).
define i32 @unsupported_mixed_i32_i64(ptr %fp, i64 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 %fp(i64 %x)
  ret i32 %r
}

; Safety skips: mixed width i1(i32).
define i1 @unsupported_mixed_i1_i32(ptr %fp, i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i1 %fp(i32 %x)
  ret i1 %r
}

; Safety skips: mixed width i32(i1).
define i32 @unsupported_mixed_i32_i1(ptr %fp, i1 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 %fp(i1 %x)
  ret i32 %r
}

; Safety skips: mixed width i8(i16).
define i8 @unsupported_mixed_i8_i16(ptr %fp, i16 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i8 %fp(i16 %x)
  ret i8 %r
}

; Safety skips: mixed width i16(i8).
define i16 @unsupported_mixed_i16_i8(ptr %fp, i8 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i16 %fp(i8 %x)
  ret i16 %r
}

; Safety skips: mixed width i16(i32).
define i16 @unsupported_mixed_i16_i32(ptr %fp, i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i16 %fp(i32 %x)
  ret i16 %r
}

; Safety skips: mixed width i32(i16).
define i32 @unsupported_mixed_i32_i16(ptr %fp, i16 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 %fp(i16 %x)
  ret i32 %r
}

; Safety skips: non-zero address-space callee pointer.
define i32 @unsupported_as1(ptr addrspace(1) %fp, i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call addrspace(1) i32 %fp(i32 %x)
  ret i32 %r
}

; Safety skips: void(i64) — not the void(i32) callback form.
define void @unsupported_void_i64(ptr %fp, i64 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  call void %fp(i64 %x)
  ret void
}

; Safety skips: void() zero-arg — not the void(i32) callback form.
define void @unsupported_void_zero(ptr %fp) noinline optnone {
entry:
  call void @hikari_vmp()
  call void %fp()
  ret void
}

; Safety skips: mixed binary i32(i32, i64) — not i32(i32, i32).
define i32 @unsupported_binary_i32_i64(ptr %fp, i32 %a, i64 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 %fp(i32 %a, i64 %b)
  ret i32 %r
}

; Safety skips: mixed binary i64(i32, i32) — wrong param/return mix.
define i64 @unsupported_binary_i64_ret(ptr %fp, i32 %a, i32 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 %fp(i32 %a, i32 %b)
  ret i64 %r
}

; Safety skips: mixed binary i64(i64, i32) — not same-width binary.
define i64 @unsupported_binary_i64_i32(ptr %fp, i64 %a, i32 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 %fp(i64 %a, i32 %b)
  ret i64 %r
}

; Safety skips: mixed binary i32(i64, i64) — wrong return width.
define i32 @unsupported_binary_i32_ret_i64(ptr %fp, i64 %a, i64 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 %fp(i64 %a, i64 %b)
  ret i32 %r
}

; Safety skips: mixed binary i16(i16, i32) — not same-width binary.
define i16 @unsupported_binary_i16_i32(ptr %fp, i16 %a, i32 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i16 %fp(i16 %a, i32 %b)
  ret i16 %r
}

; Safety skips: mixed binary i32(i16, i16) — wrong return width.
define i32 @unsupported_binary_i32_ret_i16(ptr %fp, i16 %a, i16 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 %fp(i16 %a, i16 %b)
  ret i32 %r
}

; Safety skips: mixed binary i8(i8, i16) — not same-width binary.
define i8 @unsupported_binary_i8_i16(ptr %fp, i8 %a, i16 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i8 %fp(i8 %a, i16 %b)
  ret i8 %r
}

; Safety skips: mixed binary i16(i8, i8) — wrong return width.
define i16 @unsupported_binary_i16_ret_i8(ptr %fp, i8 %a, i8 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i16 %fp(i8 %a, i8 %b)
  ret i16 %r
}

; Safety skips: mixed binary i1(i1, i8) — not same-width binary.
define i1 @unsupported_binary_i1_i8(ptr %fp, i1 %a, i8 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i1 %fp(i1 %a, i8 %b)
  ret i1 %r
}

; Safety skips: mixed binary i8(i1, i1) — wrong return width.
define i8 @unsupported_binary_i8_ret_i1(ptr %fp, i1 %a, i1 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i8 %fp(i1 %a, i1 %b)
  ret i8 %r
}

; Safety skips: ternary i32(i32, i32, i64) — not fixed i32 triple.
define i32 @unsupported_ternary_i32_i64(ptr %fp, i32 %a, i32 %b, i64 %c) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 %fp(i32 %a, i32 %b, i64 %c)
  ret i32 %r
}

; Safety skips: ternary i64(i32, i32, i32) — wrong param widths.
define i64 @unsupported_ternary_i64_ret(ptr %fp, i32 %a, i32 %b, i32 %c) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 %fp(i32 %a, i32 %b, i32 %c)
  ret i64 %r
}

; Safety skips: ternary i64(i64, i64, i32) — not same-width triple.
define i64 @unsupported_ternary_i64_i32(ptr %fp, i64 %a, i64 %b, i32 %c) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i64 %fp(i64 %a, i64 %b, i32 %c)
  ret i64 %r
}

; Safety skips: ternary i32(i64, i64, i64) — wrong return width.
define i32 @unsupported_ternary_i32_ret_i64(ptr %fp, i64 %a, i64 %b, i64 %c) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 %fp(i64 %a, i64 %b, i64 %c)
  ret i32 %r
}

; Safety skips: ternary i1(i1, i1, i1) — arity-3 width policy rejects i1.
define i1 @unsupported_ternary_i1(ptr %fp, i1 %a, i1 %b, i1 %c) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i1 %fp(i1 %a, i1 %b, i1 %c)
  ret i1 %r
}

; Safety skips: ternary i8(i8, i8, i8) — arity-3 width policy rejects i8.
define i8 @unsupported_ternary_i8(ptr %fp, i8 %a, i8 %b, i8 %c) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i8 %fp(i8 %a, i8 %b, i8 %c)
  ret i8 %r
}

define i32 @main() {
entry:
  ; i32 via arg: positive and negative inputs
  %e0 = call i32 @reference_via_arg(ptr @add_one, i32 10)
  %a0 = call i32 @protected_via_arg(ptr @add_one, i32 10)
  %m0 = icmp eq i32 %e0, %a0
  %e1 = call i32 @reference_via_arg(ptr @add_two, i32 -10)
  %a1 = call i32 @protected_via_arg(ptr @add_two, i32 -10)
  %m1 = icmp eq i32 %e1, %a1
  ; i32 via select
  %e2 = call i32 @reference_via_select(i1 true, i32 7)
  %a2 = call i32 @protected_via_select(i1 true, i32 7)
  %m2 = icmp eq i32 %e2, %a2
  %e3 = call i32 @reference_via_select(i1 false, i32 -7)
  %a3 = call i32 @protected_via_select(i1 false, i32 -7)
  %m3 = icmp eq i32 %e3, %a3
  ; i64 via arg: positive and negative
  %e4 = call i64 @reference_via_arg_i64(ptr @add_one_i64, i64 100)
  %a4 = call i64 @protected_via_arg_i64(ptr @add_one_i64, i64 100)
  %m4 = icmp eq i64 %e4, %a4
  %e5 = call i64 @reference_via_arg_i64(ptr @add_two_i64, i64 -100)
  %a5 = call i64 @protected_via_arg_i64(ptr @add_two_i64, i64 -100)
  %m5 = icmp eq i64 %e5, %a5
  ; i64 via select: positive and negative
  %e6 = call i64 @reference_via_select_i64(i1 true, i64 42)
  %a6 = call i64 @protected_via_select_i64(i1 true, i64 42)
  %m6 = icmp eq i64 %e6, %a6
  %e7 = call i64 @reference_via_select_i64(i1 false, i64 -42)
  %a7 = call i64 @protected_via_select_i64(i1 false, i64 -42)
  %m7 = icmp eq i64 %e7, %a7
  ; i1 via arg: true and false
  %e8 = call i1 @reference_via_arg_i1(ptr @not_i1, i1 true)
  %a8 = call i1 @protected_via_arg_i1(ptr @not_i1, i1 true)
  %m8 = icmp eq i1 %e8, %a8
  %e9 = call i1 @reference_via_arg_i1(ptr @id_i1, i1 false)
  %a9 = call i1 @protected_via_arg_i1(ptr @id_i1, i1 false)
  %m9 = icmp eq i1 %e9, %a9
  ; i1 via select: true/false pick and true/false arg
  %e10 = call i1 @reference_via_select_i1(i1 true, i1 true)
  %a10 = call i1 @protected_via_select_i1(i1 true, i1 true)
  %m10 = icmp eq i1 %e10, %a10
  %e11 = call i1 @reference_via_select_i1(i1 false, i1 false)
  %a11 = call i1 @protected_via_select_i1(i1 false, i1 false)
  %m11 = icmp eq i1 %e11, %a11
  ; i8 via arg: positive and negative
  %e12 = call i8 @reference_via_arg_i8(ptr @add_one_i8, i8 10)
  %a12 = call i8 @protected_via_arg_i8(ptr @add_one_i8, i8 10)
  %m12 = icmp eq i8 %e12, %a12
  %e13 = call i8 @reference_via_arg_i8(ptr @add_two_i8, i8 -10)
  %a13 = call i8 @protected_via_arg_i8(ptr @add_two_i8, i8 -10)
  %m13 = icmp eq i8 %e13, %a13
  ; i8 via select: positive and negative
  %e14 = call i8 @reference_via_select_i8(i1 true, i8 7)
  %a14 = call i8 @protected_via_select_i8(i1 true, i8 7)
  %m14 = icmp eq i8 %e14, %a14
  %e15 = call i8 @reference_via_select_i8(i1 false, i8 -7)
  %a15 = call i8 @protected_via_select_i8(i1 false, i8 -7)
  %m15 = icmp eq i8 %e15, %a15
  ; i16 via arg: positive and negative
  %e16 = call i16 @reference_via_arg_i16(ptr @add_one_i16, i16 10)
  %a16 = call i16 @protected_via_arg_i16(ptr @add_one_i16, i16 10)
  %m16 = icmp eq i16 %e16, %a16
  %e17 = call i16 @reference_via_arg_i16(ptr @add_two_i16, i16 -10)
  %a17 = call i16 @protected_via_arg_i16(ptr @add_two_i16, i16 -10)
  %m17 = icmp eq i16 %e17, %a17
  ; i16 via select: positive and negative
  %e18 = call i16 @reference_via_select_i16(i1 true, i16 7)
  %a18 = call i16 @protected_via_select_i16(i1 true, i16 7)
  %m18 = icmp eq i16 %e18, %a18
  %e19 = call i16 @reference_via_select_i16(i1 false, i16 -7)
  %a19 = call i16 @protected_via_select_i16(i1 false, i16 -7)
  %m19 = icmp eq i16 %e19, %a19
  ; void(i32) via arg: positive and negative side effects on @sink
  store i32 0, ptr @sink, align 4
  call void @reference_void_via_arg(ptr @store_sink, i32 42)
  %ev0 = load i32, ptr @sink, align 4
  store i32 0, ptr @sink, align 4
  call void @protected_void_via_arg(ptr @store_sink, i32 42)
  %av0 = load i32, ptr @sink, align 4
  %m20 = icmp eq i32 %ev0, %av0
  store i32 0, ptr @sink, align 4
  call void @reference_void_via_arg(ptr @store_neg_sink, i32 -7)
  %ev1 = load i32, ptr @sink, align 4
  store i32 0, ptr @sink, align 4
  call void @protected_void_via_arg(ptr @store_neg_sink, i32 -7)
  %av1 = load i32, ptr @sink, align 4
  %m21 = icmp eq i32 %ev1, %av1
  ; void(i32) via select: true/false pick, positive and negative args
  store i32 0, ptr @sink, align 4
  call void @reference_void_via_select(i1 true, i32 11)
  %ev2 = load i32, ptr @sink, align 4
  store i32 0, ptr @sink, align 4
  call void @protected_void_via_select(i1 true, i32 11)
  %av2 = load i32, ptr @sink, align 4
  %m22 = icmp eq i32 %ev2, %av2
  store i32 0, ptr @sink, align 4
  call void @reference_void_via_select(i1 false, i32 -11)
  %ev3 = load i32, ptr @sink, align 4
  store i32 0, ptr @sink, align 4
  call void @protected_void_via_select(i1 false, i32 -11)
  %av3 = load i32, ptr @sink, align 4
  %m23 = icmp eq i32 %ev3, %av3
  ; binary i32(i32,i32) via arg: positive and negative
  %eb0 = call i32 @reference_binary_via_arg(ptr @add_i32, i32 3, i32 5)
  %ab0 = call i32 @protected_binary_via_arg(ptr @add_i32, i32 3, i32 5)
  %m24 = icmp eq i32 %eb0, %ab0
  %eb1 = call i32 @reference_binary_via_arg(ptr @sub_i32, i32 -8, i32 3)
  %ab1 = call i32 @protected_binary_via_arg(ptr @sub_i32, i32 -8, i32 3)
  %m25 = icmp eq i32 %eb1, %ab1
  ; binary via select
  %eb2 = call i32 @reference_binary_via_select(i1 true, i32 10, i32 4)
  %ab2 = call i32 @protected_binary_via_select(i1 true, i32 10, i32 4)
  %m26 = icmp eq i32 %eb2, %ab2
  %eb3 = call i32 @reference_binary_via_select(i1 false, i32 10, i32 -4)
  %ab3 = call i32 @protected_binary_via_select(i1 false, i32 10, i32 -4)
  %m27 = icmp eq i32 %eb3, %ab3
  ; binary i64(i64,i64) via arg: positive and negative
  %eb4 = call i64 @reference_binary_via_arg_i64(ptr @add_i64, i64 30, i64 50)
  %ab4 = call i64 @protected_binary_via_arg_i64(ptr @add_i64, i64 30, i64 50)
  %m28 = icmp eq i64 %eb4, %ab4
  %eb5 = call i64 @reference_binary_via_arg_i64(ptr @sub_i64, i64 -80, i64 30)
  %ab5 = call i64 @protected_binary_via_arg_i64(ptr @sub_i64, i64 -80, i64 30)
  %m29 = icmp eq i64 %eb5, %ab5
  ; binary i64 via select
  %eb6 = call i64 @reference_binary_via_select_i64(i1 true, i64 100, i64 40)
  %ab6 = call i64 @protected_binary_via_select_i64(i1 true, i64 100, i64 40)
  %m30 = icmp eq i64 %eb6, %ab6
  %eb7 = call i64 @reference_binary_via_select_i64(i1 false, i64 100, i64 -40)
  %ab7 = call i64 @protected_binary_via_select_i64(i1 false, i64 100, i64 -40)
  %m31 = icmp eq i64 %eb7, %ab7
  ; binary i16(i16,i16) via arg: positive and negative
  %eb8 = call i16 @reference_binary_via_arg_i16(ptr @add_i16_bin, i16 3, i16 5)
  %ab8 = call i16 @protected_binary_via_arg_i16(ptr @add_i16_bin, i16 3, i16 5)
  %m32 = icmp eq i16 %eb8, %ab8
  %eb9 = call i16 @reference_binary_via_arg_i16(ptr @sub_i16_bin, i16 -8, i16 3)
  %ab9 = call i16 @protected_binary_via_arg_i16(ptr @sub_i16_bin, i16 -8, i16 3)
  %m33 = icmp eq i16 %eb9, %ab9
  ; binary i16 via select
  %eb10 = call i16 @reference_binary_via_select_i16(i1 true, i16 10, i16 4)
  %ab10 = call i16 @protected_binary_via_select_i16(i1 true, i16 10, i16 4)
  %m34 = icmp eq i16 %eb10, %ab10
  %eb11 = call i16 @reference_binary_via_select_i16(i1 false, i16 10, i16 -4)
  %ab11 = call i16 @protected_binary_via_select_i16(i1 false, i16 10, i16 -4)
  %m35 = icmp eq i16 %eb11, %ab11
  ; binary i8(i8,i8) via arg: positive and negative
  %eb12 = call i8 @reference_binary_via_arg_i8(ptr @add_i8_bin, i8 3, i8 5)
  %ab12 = call i8 @protected_binary_via_arg_i8(ptr @add_i8_bin, i8 3, i8 5)
  %m36 = icmp eq i8 %eb12, %ab12
  %eb13 = call i8 @reference_binary_via_arg_i8(ptr @sub_i8_bin, i8 -8, i8 3)
  %ab13 = call i8 @protected_binary_via_arg_i8(ptr @sub_i8_bin, i8 -8, i8 3)
  %m37 = icmp eq i8 %eb13, %ab13
  ; binary i8 via select
  %eb14 = call i8 @reference_binary_via_select_i8(i1 true, i8 10, i8 4)
  %ab14 = call i8 @protected_binary_via_select_i8(i1 true, i8 10, i8 4)
  %m38 = icmp eq i8 %eb14, %ab14
  %eb15 = call i8 @reference_binary_via_select_i8(i1 false, i8 10, i8 -4)
  %ab15 = call i8 @protected_binary_via_select_i8(i1 false, i8 10, i8 -4)
  %m39 = icmp eq i8 %eb15, %ab15
  ; binary i1(i1,i1) via arg: true/false combinations
  %eb16 = call i1 @reference_binary_via_arg_i1(ptr @and_i1_bin, i1 true, i1 false)
  %ab16 = call i1 @protected_binary_via_arg_i1(ptr @and_i1_bin, i1 true, i1 false)
  %m40 = icmp eq i1 %eb16, %ab16
  %eb17 = call i1 @reference_binary_via_arg_i1(ptr @xor_i1_bin, i1 true, i1 true)
  %ab17 = call i1 @protected_binary_via_arg_i1(ptr @xor_i1_bin, i1 true, i1 true)
  %m41 = icmp eq i1 %eb17, %ab17
  ; binary i1 via select
  %eb18 = call i1 @reference_binary_via_select_i1(i1 true, i1 true, i1 false)
  %ab18 = call i1 @protected_binary_via_select_i1(i1 true, i1 true, i1 false)
  %m42 = icmp eq i1 %eb18, %ab18
  %eb19 = call i1 @reference_binary_via_select_i1(i1 false, i1 false, i1 true)
  %ab19 = call i1 @protected_binary_via_select_i1(i1 false, i1 false, i1 true)
  %m43 = icmp eq i1 %eb19, %ab19
  ; ternary i32(i32,i32,i32) via arg: positive and negative
  %et0 = call i32 @reference_ternary_via_arg(ptr @add3_i32, i32 1, i32 2, i32 3)
  %at0 = call i32 @protected_ternary_via_arg(ptr @add3_i32, i32 1, i32 2, i32 3)
  %m44 = icmp eq i32 %et0, %at0
  %et1 = call i32 @reference_ternary_via_arg(ptr @mul_add_i32, i32 -4, i32 5, i32 -6)
  %at1 = call i32 @protected_ternary_via_arg(ptr @mul_add_i32, i32 -4, i32 5, i32 -6)
  %m45 = icmp eq i32 %et1, %at1
  ; ternary via select
  %et2 = call i32 @reference_ternary_via_select(i1 true, i32 2, i32 3, i32 4)
  %at2 = call i32 @protected_ternary_via_select(i1 true, i32 2, i32 3, i32 4)
  %m46 = icmp eq i32 %et2, %at2
  %et3 = call i32 @reference_ternary_via_select(i1 false, i32 3, i32 -2, i32 7)
  %at3 = call i32 @protected_ternary_via_select(i1 false, i32 3, i32 -2, i32 7)
  %m47 = icmp eq i32 %et3, %at3
  ; ternary i64(i64,i64,i64) via arg: positive and negative
  %et4 = call i64 @reference_ternary_via_arg_i64(ptr @add3_i64, i64 10, i64 20, i64 30)
  %at4 = call i64 @protected_ternary_via_arg_i64(ptr @add3_i64, i64 10, i64 20, i64 30)
  %m48 = icmp eq i64 %et4, %at4
  %et5 = call i64 @reference_ternary_via_arg_i64(ptr @mul_add_i64, i64 -4, i64 5, i64 -6)
  %at5 = call i64 @protected_ternary_via_arg_i64(ptr @mul_add_i64, i64 -4, i64 5, i64 -6)
  %m49 = icmp eq i64 %et5, %at5
  ; ternary i64 via select
  %et6 = call i64 @reference_ternary_via_select_i64(i1 true, i64 2, i64 3, i64 4)
  %at6 = call i64 @protected_ternary_via_select_i64(i1 true, i64 2, i64 3, i64 4)
  %m50 = icmp eq i64 %et6, %at6
  %et7 = call i64 @reference_ternary_via_select_i64(i1 false, i64 3, i64 -2, i64 7)
  %at7 = call i64 @protected_ternary_via_select_i64(i1 false, i64 3, i64 -2, i64 7)
  %m51 = icmp eq i64 %et7, %at7
  ; ternary i16(i16,i16,i16) via arg: positive and negative
  %et8 = call i16 @reference_ternary_via_arg_i16(ptr @add3_i16, i16 1, i16 2, i16 3)
  %at8 = call i16 @protected_ternary_via_arg_i16(ptr @add3_i16, i16 1, i16 2, i16 3)
  %m52 = icmp eq i16 %et8, %at8
  %et9 = call i16 @reference_ternary_via_arg_i16(ptr @mul_add_i16, i16 -4, i16 5, i16 -6)
  %at9 = call i16 @protected_ternary_via_arg_i16(ptr @mul_add_i16, i16 -4, i16 5, i16 -6)
  %m53 = icmp eq i16 %et9, %at9
  ; ternary i16 via select
  %et10 = call i16 @reference_ternary_via_select_i16(i1 true, i16 2, i16 3, i16 4)
  %at10 = call i16 @protected_ternary_via_select_i16(i1 true, i16 2, i16 3, i16 4)
  %m54 = icmp eq i16 %et10, %at10
  %et11 = call i16 @reference_ternary_via_select_i16(i1 false, i16 3, i16 -2, i16 7)
  %at11 = call i16 @protected_ternary_via_select_i16(i1 false, i16 3, i16 -2, i16 7)
  %m55 = icmp eq i16 %et11, %at11
  %t0 = and i1 %m0, %m1
  %t1 = and i1 %m2, %m3
  %t2 = and i1 %m4, %m5
  %t3 = and i1 %m6, %m7
  %t4 = and i1 %m8, %m9
  %t5 = and i1 %m10, %m11
  %t6 = and i1 %m12, %m13
  %t7 = and i1 %m14, %m15
  %t8 = and i1 %m16, %m17
  %t9 = and i1 %m18, %m19
  %t10 = and i1 %m20, %m21
  %t11 = and i1 %m22, %m23
  %t12 = and i1 %m24, %m25
  %t13 = and i1 %m26, %m27
  %t14 = and i1 %m28, %m29
  %t15 = and i1 %m30, %m31
  %t16 = and i1 %m32, %m33
  %t17 = and i1 %m34, %m35
  %t18 = and i1 %m36, %m37
  %t19 = and i1 %m38, %m39
  %t20 = and i1 %m40, %m41
  %t21 = and i1 %m42, %m43
  %t22 = and i1 %m44, %m45
  %t23 = and i1 %m46, %m47
  %t24 = and i1 %m48, %m49
  %t25 = and i1 %m50, %m51
  %t26 = and i1 %m52, %m53
  %t27 = and i1 %m54, %m55
  %t28 = and i1 %t0, %t1
  %t29 = and i1 %t2, %t3
  %t30 = and i1 %t4, %t5
  %t31 = and i1 %t6, %t7
  %t32 = and i1 %t8, %t9
  %t33 = and i1 %t10, %t11
  %t34 = and i1 %t12, %t13
  %t35 = and i1 %t14, %t15
  %t36 = and i1 %t16, %t17
  %t37 = and i1 %t18, %t19
  %t38 = and i1 %t20, %t21
  %t39 = and i1 %t22, %t23
  %t40 = and i1 %t24, %t25
  %t41 = and i1 %t26, %t27
  %t42 = and i1 %t28, %t29
  %t43 = and i1 %t30, %t31
  %ok = and i1 %t42, %t43
  %ok2 = and i1 %ok, %t32
  %ok3 = and i1 %ok2, %t33
  %ok4 = and i1 %ok3, %t34
  %ok5 = and i1 %ok4, %t35
  %ok6 = and i1 %ok5, %t36
  %ok7 = and i1 %ok6, %t37
  %ok8 = and i1 %ok7, %t38
  %ok9 = and i1 %ok8, %t39
  %ok10 = and i1 %ok9, %t40
  %ok11 = and i1 %ok10, %t41
  %code = select i1 %ok11, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with: 41
; SKIP-DAG: Skipping VMP on unsupported_vararg: indirect call
; SKIP-DAG: Skipping VMP on unsupported_as1: unsupported argument type
; SKIP-NOT: Skipping VMP on protected_via_arg:
; SKIP-NOT: Skipping VMP on protected_via_select:
; SKIP-NOT: Skipping VMP on protected_via_arg_i64:
; SKIP-NOT: Skipping VMP on protected_via_select_i64:
; SKIP-NOT: Skipping VMP on protected_via_arg_i1:
; SKIP-NOT: Skipping VMP on protected_via_select_i1:
; SKIP-NOT: Skipping VMP on protected_via_arg_i8:
; SKIP-NOT: Skipping VMP on protected_via_select_i8:
; SKIP-NOT: Skipping VMP on protected_via_arg_i16:
; SKIP-NOT: Skipping VMP on protected_via_select_i16:
; SKIP-NOT: Skipping VMP on protected_void_via_arg:
; SKIP-NOT: Skipping VMP on protected_void_via_select:
; SKIP-NOT: Skipping VMP on protected_binary_via_arg:
; SKIP-NOT: Skipping VMP on protected_binary_via_select:
; SKIP-NOT: Skipping VMP on protected_binary_via_arg_i64:
; SKIP-NOT: Skipping VMP on protected_binary_via_select_i64:
; SKIP-NOT: Skipping VMP on protected_binary_via_arg_i16:
; SKIP-NOT: Skipping VMP on protected_binary_via_select_i16:
; SKIP-NOT: Skipping VMP on protected_binary_via_arg_i8:
; SKIP-NOT: Skipping VMP on protected_binary_via_select_i8:
; SKIP-NOT: Skipping VMP on protected_binary_via_arg_i1:
; SKIP-NOT: Skipping VMP on protected_binary_via_select_i1:
; SKIP-NOT: Skipping VMP on protected_ternary_via_arg:
; SKIP-NOT: Skipping VMP on protected_ternary_via_select:
; SKIP-NOT: Skipping VMP on protected_ternary_via_arg_i64:
; SKIP-NOT: Skipping VMP on protected_ternary_via_select_i64:
; SKIP-NOT: Skipping VMP on protected_ternary_via_arg_i16:
; SKIP-NOT: Skipping VMP on protected_ternary_via_select_i16:

; VIRT: define i32 @protected_via_arg({{.*}} #[[PROT:[0-9]+]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 %{{.+}}(i32
; VIRT: define i32 @protected_via_select({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 %{{.+}}(i32
; VIRT: define i64 @protected_via_arg_i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 %{{.+}}(i64
; VIRT: define i64 @protected_via_select_i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 %{{.+}}(i64
; VIRT: define i1 @protected_via_arg_i1({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i1 %{{.+}}(i1
; VIRT: define i1 @protected_via_select_i1({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i1 %{{.+}}(i1
; VIRT: define i8 @protected_via_arg_i8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i8 %{{.+}}(i8
; VIRT: define i8 @protected_via_select_i8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i8 %{{.+}}(i8
; VIRT: define i16 @protected_via_arg_i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i16 %{{.+}}(i16
; VIRT: define i16 @protected_via_select_i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i16 %{{.+}}(i16
; VIRT: define void @protected_void_via_arg({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void %{{.+}}(i32
; VIRT: define void @protected_void_via_select({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call void %{{.+}}(i32
; VIRT: define i32 @protected_binary_via_arg({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 %{{.+}}(i32 {{.*}}, i32
; VIRT: define i32 @protected_binary_via_select({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 %{{.+}}(i32 {{.*}}, i32
; VIRT: define i64 @protected_binary_via_arg_i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 %{{.+}}(i64 {{.*}}, i64
; VIRT: define i64 @protected_binary_via_select_i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 %{{.+}}(i64 {{.*}}, i64
; VIRT: define i16 @protected_binary_via_arg_i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i16 %{{.+}}(i16 {{.*}}, i16
; VIRT: define i16 @protected_binary_via_select_i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i16 %{{.+}}(i16 {{.*}}, i16
; VIRT: define i8 @protected_binary_via_arg_i8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i8 %{{.+}}(i8 {{.*}}, i8
; VIRT: define i8 @protected_binary_via_select_i8({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i8 %{{.+}}(i8 {{.*}}, i8
; VIRT: define i1 @protected_binary_via_arg_i1({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i1 %{{.+}}(i1 {{.*}}, i1
; VIRT: define i1 @protected_binary_via_select_i1({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i1 %{{.+}}(i1 {{.*}}, i1
; VIRT: define i32 @protected_ternary_via_arg({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 %{{.+}}(i32 {{.*}}, i32 {{.*}}, i32
; VIRT: define i32 @protected_ternary_via_select({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i32 %{{.+}}(i32 {{.*}}, i32 {{.*}}, i32
; VIRT: define i64 @protected_ternary_via_arg_i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 %{{.+}}(i64 {{.*}}, i64 {{.*}}, i64
; VIRT: define i64 @protected_ternary_via_select_i64({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i64 %{{.+}}(i64 {{.*}}, i64 {{.*}}, i64
; VIRT: define i16 @protected_ternary_via_arg_i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i16 %{{.+}}(i16 {{.*}}, i16 {{.*}}, i16
; VIRT: define i16 @protected_ternary_via_select_i16({{.*}} #[[PROT]] {
; VIRT: vmp.dispatch:
; VIRT: call i16 %{{.+}}(i16 {{.*}}, i16 {{.*}}, i16
; VIRT: define i32 @unsupported_vararg(
; VIRT-NOT: vmp.dispatch
; VIRT: call i32 (i32, ...) %{{.+}}(i32
; VIRT: define i32 @unsupported_as1(
; VIRT-NOT: vmp.dispatch
; VIRT: call addrspace(1) i32 %{{.+}}(i32
; VIRT: attributes #[[PROT]] = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
