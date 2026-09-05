; Native freeze handlers (Freeze / PointerFreeze / FloatFreeze), not Move.
; RUN: opt -S -verify-each -aesSeed=67 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=67 -passes='default<O2>' %s -o %t.o2.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()

; Integer + pointer + float freeze mixed into a comparable i32.
define i32 @reference(i32 %x, ptr %p, float %f) {
entry:
  %fx = freeze i32 %x
  %fp = freeze ptr %p
  %ff = freeze float %f
  store i32 %fx, ptr %fp, align 4
  %loaded = load i32, ptr %fp, align 4
  %bits = bitcast float %ff to i32
  %mix = xor i32 %loaded, %bits
  %result = add i32 %mix, 1
  ret i32 %result
}

define i32 @protected(i32 %x, ptr %p, float %f) noinline optnone {
entry:
  call void @hikari_vmp()
  %fx = freeze i32 %x
  %fp = freeze ptr %p
  %ff = freeze float %f
  store i32 %fx, ptr %fp, align 4
  %loaded = load i32, ptr %fp, align 4
  %bits = bitcast float %ff to i32
  %mix = xor i32 %loaded, %bits
  %result = add i32 %mix, 1
  ret i32 %result
}

; Multiple integer widths through freeze (handlers freeze at SSA width).
define i32 @reference_widths(i32 %x) {
entry:
  %x8 = trunc i32 %x to i8
  %x16 = trunc i32 %x to i16
  %x64 = sext i32 %x to i64
  %x1 = trunc i32 %x to i1
  %f8 = freeze i8 %x8
  %f16 = freeze i16 %x16
  %f32 = freeze i32 %x
  %f64 = freeze i64 %x64
  %f1 = freeze i1 %x1
  %z8 = zext i8 %f8 to i32
  %z16 = zext i16 %f16 to i32
  %z1 = zext i1 %f1 to i32
  %t64 = trunc i64 %f64 to i32
  %m0 = xor i32 %f32, %z8
  %m1 = xor i32 %z16, %z1
  %m2 = xor i32 %t64, %m0
  %mix = xor i32 %m2, %m1
  ret i32 %mix
}

define i32 @protected_widths(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %x8 = trunc i32 %x to i8
  %x16 = trunc i32 %x to i16
  %x64 = sext i32 %x to i64
  %x1 = trunc i32 %x to i1
  %f8 = freeze i8 %x8
  %f16 = freeze i16 %x16
  %f32 = freeze i32 %x
  %f64 = freeze i64 %x64
  %f1 = freeze i1 %x1
  %z8 = zext i8 %f8 to i32
  %z16 = zext i16 %f16 to i32
  %z1 = zext i1 %f1 to i32
  %t64 = trunc i64 %f64 to i32
  %m0 = xor i32 %f32, %z8
  %m1 = xor i32 %z16, %z1
  %m2 = xor i32 %t64, %m0
  %mix = xor i32 %m2, %m1
  ret i32 %mix
}

; Float-only freeze + bitcast mix (exercises FloatFreeze handler).
define i32 @reference_float_freeze(float %a, float %b) {
entry:
  %fa = freeze float %a
  %fb = freeze float %b
  %s = fadd float %fa, %fb
  %fs = freeze float %s
  %bits = bitcast float %fs to i32
  ret i32 %bits
}

define i32 @protected_float_freeze(float %a, float %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %fa = freeze float %a
  %fb = freeze float %b
  %s = fadd float %fa, %fb
  %fs = freeze float %s
  %bits = bitcast float %fs to i32
  ret i32 %bits
}

; freeze of defined constants (integer + float).
define i32 @reference_const_freeze() {
entry:
  %vi = freeze i32 7
  %vf = freeze float 1.500000e+00
  %bits = bitcast float %vf to i32
  %mix = xor i32 %vi, %bits
  ret i32 %mix
}

define i32 @protected_const_freeze() noinline optnone {
entry:
  call void @hikari_vmp()
  %vi = freeze i32 7
  %vf = freeze float 1.500000e+00
  %bits = bitcast float %vf to i32
  %mix = xor i32 %vi, %bits
  ret i32 %mix
}

; freeze-of-freeze chain (still identity on defined values).
define i32 @reference_double_freeze(i32 %x, float %f) {
entry:
  %x0 = freeze i32 %x
  %x1 = freeze i32 %x0
  %f0 = freeze float %f
  %f1 = freeze float %f0
  %bits = bitcast float %f1 to i32
  %mix = xor i32 %x1, %bits
  ret i32 %mix
}

define i32 @protected_double_freeze(i32 %x, float %f) noinline optnone {
entry:
  call void @hikari_vmp()
  %x0 = freeze i32 %x
  %x1 = freeze i32 %x0
  %f0 = freeze float %f
  %f1 = freeze float %f0
  %bits = bitcast float %f1 to i32
  %mix = xor i32 %x1, %bits
  ret i32 %mix
}

; Pointer-only freeze of a stack slot address.
define i32 @reference_ptr_freeze(i32 %x) {
entry:
  %slot = alloca i32, align 4
  %fp = freeze ptr %slot
  store i32 %x, ptr %fp, align 4
  %loaded = load i32, ptr %fp, align 4
  %result = add i32 %loaded, 1
  ret i32 %result
}

define i32 @protected_ptr_freeze(i32 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %slot = alloca i32, align 4
  %fp = freeze ptr %slot
  store i32 %x, ptr %fp, align 4
  %loaded = load i32, ptr %fp, align 4
  %result = add i32 %loaded, 1
  ret i32 %result
}

; Direct freeze of undef/poison for supported types (virtualized; results are
; arbitrary fixed values — not compared in main, only FileCheck handlers).
define i32 @protected_freeze_undef() noinline optnone {
entry:
  call void @hikari_vmp()
  %vi = freeze i32 undef
  %vf = freeze float undef
  %vp = freeze ptr undef
  store i32 %vi, ptr %vp, align 4
  %bits = bitcast float %vf to i32
  %mix = xor i32 %vi, %bits
  ret i32 %mix
}

define i32 @protected_freeze_poison() noinline optnone {
entry:
  call void @hikari_vmp()
  %vi = freeze i32 poison
  %vf = freeze float poison
  %vp = freeze ptr poison
  store i32 %vi, ptr %vp, align 4
  %bits = bitcast float %vf to i32
  %mix = xor i32 %vi, %bits
  ret i32 %mix
}

define i32 @main() {
entry:
  %slot = alloca i32, align 4
  store i32 0, ptr %slot, align 4
  %e0 = call i32 @reference(i32 41, ptr %slot, float 1.500000e+00)
  store i32 0, ptr %slot, align 4
  %a0 = call i32 @protected(i32 41, ptr %slot, float 1.500000e+00)
  store i32 0, ptr %slot, align 4
  %e1 = call i32 @reference(i32 -7, ptr %slot, float -2.250000e+00)
  store i32 0, ptr %slot, align 4
  %a1 = call i32 @protected(i32 -7, ptr %slot, float -2.250000e+00)
  %e2 = call i32 @reference_widths(i32 42)
  %a2 = call i32 @protected_widths(i32 42)
  %e3 = call i32 @reference_widths(i32 -100)
  %a3 = call i32 @protected_widths(i32 -100)
  %e4 = call i32 @reference_float_freeze(float 1.500000e+00, float 2.250000e+00)
  %a4 = call i32 @protected_float_freeze(float 1.500000e+00, float 2.250000e+00)
  %e5 = call i32 @reference_float_freeze(float -0.000000e+00, float 1.000000e+00)
  %a5 = call i32 @protected_float_freeze(float -0.000000e+00, float 1.000000e+00)
  %e6 = call i32 @reference_const_freeze()
  %a6 = call i32 @protected_const_freeze()
  %e7 = call i32 @reference_double_freeze(i32 9, float 3.250000e+00)
  %a7 = call i32 @protected_double_freeze(i32 9, float 3.250000e+00)
  %e8 = call i32 @reference_ptr_freeze(i32 11)
  %a8 = call i32 @protected_ptr_freeze(i32 11)
  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %e1, %a1
  %m2 = icmp eq i32 %e2, %a2
  %m3 = icmp eq i32 %e3, %a3
  %m4 = icmp eq i32 %e4, %a4
  %m5 = icmp eq i32 %e5, %a5
  %m6 = icmp eq i32 %e6, %a6
  %m7 = icmp eq i32 %e7, %a7
  %m8 = icmp eq i32 %e8, %a8
  %t0 = and i1 %m0, %m1
  %t1 = and i1 %t0, %m2
  %t2 = and i1 %t1, %m3
  %t3 = and i1 %t2, %m4
  %t4 = and i1 %t3, %m5
  %t5 = and i1 %t4, %m6
  %t6 = and i1 %t5, %m7
  %ok = and i1 %t6, %m8
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with: 67
; SKIP-NOT: Skipping VMP on protected:
; SKIP-NOT: Skipping VMP on protected_widths:
; SKIP-NOT: Skipping VMP on protected_float_freeze:
; SKIP-NOT: Skipping VMP on protected_const_freeze:
; SKIP-NOT: Skipping VMP on protected_double_freeze:
; SKIP-NOT: Skipping VMP on protected_ptr_freeze:
; SKIP-NOT: Skipping VMP on protected_freeze_undef:
; SKIP-NOT: Skipping VMP on protected_freeze_poison:

; VIRT-LABEL: define i32 @protected(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; Native freeze handlers (must not be plain Move).
; VIRT-DAG: freeze i32
; VIRT-DAG: freeze ptr
; VIRT-DAG: freeze float

; VIRT-LABEL: define i32 @protected_widths(
; VIRT: vmp.dispatch:
; Avoid "freeze i1" matching "freeze i16".
; VIRT-DAG: freeze i8{{([^0-9]|$)}}
; VIRT-DAG: freeze i16{{([^0-9]|$)}}
; VIRT-DAG: freeze i32{{([^0-9]|$)}}
; VIRT-DAG: freeze i64{{([^0-9]|$)}}
; VIRT-DAG: freeze i1{{([^0-9]|$)}}

; VIRT-LABEL: define i32 @protected_float_freeze(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: freeze float
; VIRT-DAG: fadd float

; VIRT-LABEL: define i32 @protected_const_freeze(
; VIRT: vmp.dispatch:
; VIRT-DAG: freeze i32
; VIRT-DAG: freeze float

; VIRT-LABEL: define i32 @protected_double_freeze(
; VIRT: vmp.dispatch:
; VIRT-DAG: freeze i32
; VIRT-DAG: freeze float

; VIRT-LABEL: define i32 @protected_ptr_freeze(
; VIRT: vmp.dispatch:
; VIRT-DAG: freeze ptr

; Direct freeze undef/poison virtualized with native freeze handlers.
; VIRT-LABEL: define i32 @protected_freeze_undef(
; VIRT: vmp.dispatch:
; VIRT-DAG: freeze i32 undef
; VIRT-DAG: freeze float undef
; VIRT-DAG: freeze ptr undef
; VIRT-LABEL: define i32 @protected_freeze_poison(
; VIRT: vmp.dispatch:
; VIRT-DAG: freeze i32 poison
; VIRT-DAG: freeze float poison
; VIRT-DAG: freeze ptr poison

; Attributes for virtualized functions are emitted after all defines.
; VIRT: attributes{{.*}}"hikari.vmp.virtualized"
