; Minimal O2 regression: ordinary direct double call must stay VMP-eligible under default<O2>.
; Empty sinks let O2 rewrite unused call args to poison; VMP rejects poison → skip.
; Volatile store in the sink keeps the arg live so protected_double_call virtualizes at O2.
;
; RUN: opt -S -verify-each -aesSeed=109 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.ll -o %t.o2.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()

@__vmp_double_sink_slot = private global double 0.000000e+00

define void @double_sink(double %x) {
entry:
  store volatile double %x, ptr @__vmp_double_sink_slot, align 8
  ret void
}

define double @double_combine(double %a, double %b) noinline {
entry:
  %s = fadd double %a, %b
  %t = fmul double %s, 2.000000e+00
  ret double %t
}

define i32 @reference_double_call(double %a, double %b) {
entry:
  %s = fadd double %a, %b
  call void @double_sink(double %s)
  %c = call double @double_combine(double %a, double %b)
  %bits64 = bitcast double %c to i64
  %lo = trunc i64 %bits64 to i32
  %hi = lshr i64 %bits64, 32
  %hi32 = trunc i64 %hi to i32
  %mix = xor i32 %lo, %hi32
  ret i32 %mix
}

define i32 @protected_double_call(double %a, double %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %s = fadd double %a, %b
  call void @double_sink(double %s)
  %c = call double @double_combine(double %a, double %b)
  %bits64 = bitcast double %c to i64
  %lo = trunc i64 %bits64 to i32
  %hi = lshr i64 %bits64, 32
  %hi32 = trunc i64 %hi to i32
  %mix = xor i32 %lo, %hi32
  ret i32 %mix
}

; Ternary indirect double stays rejected (unary/binary same-type is covered
; by vmp-indirect-call-float-semantic.ll).
define double @unsupported_indirect(ptr %fp, double %a, double %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call double %fp(double %a, double %b, double %a)
  ret double %r
}

define i32 @main() {
entry:
  store volatile double 0.000000e+00, ptr @__vmp_double_sink_slot, align 8
  %e0 = call i32 @reference_double_call(double 1.500000e+00, double 2.250000e+00)
  %s0 = load volatile double, ptr @__vmp_double_sink_slot, align 8
  store volatile double 0.000000e+00, ptr @__vmp_double_sink_slot, align 8
  %a0 = call i32 @protected_double_call(double 1.500000e+00, double 2.250000e+00)
  %t0 = load volatile double, ptr @__vmp_double_sink_slot, align 8
  store volatile double 0.000000e+00, ptr @__vmp_double_sink_slot, align 8
  %e1 = call i32 @reference_double_call(double -3.000000e+00, double 4.000000e+00)
  %s1 = load volatile double, ptr @__vmp_double_sink_slot, align 8
  store volatile double 0.000000e+00, ptr @__vmp_double_sink_slot, align 8
  %a1 = call i32 @protected_double_call(double -3.000000e+00, double 4.000000e+00)
  %t1 = load volatile double, ptr @__vmp_double_sink_slot, align 8
  %m0 = icmp eq i32 %e0, %a0
  %d0 = fcmp oeq double %s0, %t0
  %m1 = icmp eq i32 %e1, %a1
  %d1 = fcmp oeq double %s1, %t1
  %ok0 = and i1 %m0, %d0
  %ok1 = and i1 %m1, %d1
  %ok = and i1 %ok0, %ok1
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; Ternary mixed-scalar indirect double is now in the supported subset.
; SKIP-NOT: Skipping VMP on unsupported_indirect:
; Must not skip the protected direct-call body at O2.
; SKIP-NOT: Skipping VMP on protected_double_call:

; VIRT-LABEL: define i32 @protected_double_call(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: fadd double
; VIRT-DAG: call void @double_sink(double
; VIRT-DAG: call double @double_combine(double

; VIRT-LABEL: define double @unsupported_indirect(
; VIRT: vmp.dispatch:
; VIRT: call double

; VIRT: attributes{{.*}}"hikari.vmp.virtualized"{{.*}}
