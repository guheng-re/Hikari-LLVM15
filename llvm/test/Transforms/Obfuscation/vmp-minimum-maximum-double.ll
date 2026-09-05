; Scalar llvm.minimum.f64 / llvm.maximum.f64 direct call under VMP.
; Legal-width f32/f64 vector minimum/maximum lives in
; vmp-fp-vector-minmax-semantic.ll and is not re-covered here.
; reference/* run natively, protected/* are virtualized; bitcast-to-integer
; parity proves the interpreter re-emits the exact minimum/maximum intrinsics.
; minimum and maximum are compared independently (not XOR-mixed) so a swap of
; the two cannot pass.  Runtime inputs cover ordinary values, one-sided quiet
; NaN, both-sided quiet NaN with distinct payloads, and +0/-0.  Assertions
; compare reference vs protected bit patterns only: LangRef does not pin the
; both-NaN payload or which signed zero IEEE minimum/maximum may return when
; the operands compare equal.
; Fast-math minimum/maximum.f64 is VMP-supported (CallDescriptor FMF mask
; restored): reference_fast_*/protected_fast_* are virtualized with the
; partial nnan flag combination and compared on finite inputs.
; Negative cases (leftover minimum.v8f64) SKIP with no vmp.dispatch.
; O0 carries the detailed VIRT checks; O2 re-checks eligibility/stability.
;
; Host x86 lli/JIT cannot select llvm.minimum/maximum.  Do not rewrite those
; intrinsics to minnum/maxnum and do not strip functions for host.  Validate
; with FileCheck + AArch64 object generation only (same IR that VMP produces).
;
; RUN: opt -S -verify-each -aesSeed=113 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.ll -o %t.o0.o
; RUN: opt -S -verify-each -aesSeed=113 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP-O2 < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT-O2 < %t.o2.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.ll -o %t.o2.o

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare double @llvm.minimum.f64(double, double)
declare double @llvm.maximum.f64(double, double)
declare <8 x double> @llvm.minimum.v8f64(<8 x double>, <8 x double>)

; ---- reference: native minimum.f64 / maximum.f64, compared as i64 bits ----

define i64 @reference_minimum_double(double %a, double %b) {
entry:
  %mn = call double @llvm.minimum.f64(double %a, double %b)
  %mn.i = bitcast double %mn to i64
  ret i64 %mn.i
}

define i64 @reference_maximum_double(double %a, double %b) {
entry:
  %mx = call double @llvm.maximum.f64(double %a, double %b)
  %mx.i = bitcast double %mx to i64
  ret i64 %mx.i
}

; ---- protected: same minimum.f64 / maximum.f64 under VMP ----

define i64 @protected_minimum_double(double %a, double %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %mn = call double @llvm.minimum.f64(double %a, double %b)
  %mn.i = bitcast double %mn to i64
  ret i64 %mn.i
}

define i64 @protected_maximum_double(double %a, double %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %mx = call double @llvm.maximum.f64(double %a, double %b)
  %mx.i = bitcast double %mx to i64
  ret i64 %mx.i
}

; ---- fast-math minimum/maximum.f64: VMP-supported (FMF mask restored) ----

define i64 @reference_fast_minimum_double(double %a, double %b) {
entry:
  %mn = call nnan double @llvm.minimum.f64(double %a, double %b)
  %mn.i = bitcast double %mn to i64
  ret i64 %mn.i
}

define i64 @reference_fast_maximum_double(double %a, double %b) {
entry:
  %mx = call nnan double @llvm.maximum.f64(double %a, double %b)
  %mx.i = bitcast double %mx to i64
  ret i64 %mx.i
}

define i64 @protected_fast_minimum_double(double %a, double %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %mn = call nnan double @llvm.minimum.f64(double %a, double %b)
  %mn.i = bitcast double %mn to i64
  ret i64 %mn.i
}

define i64 @protected_fast_maximum_double(double %a, double %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %mx = call nnan double @llvm.maximum.f64(double %a, double %b)
  %mx.i = bitcast double %mx to i64
  ret i64 %mx.i
}

; ---- negative cases: must SKIP, never virtualize ----

; Leftover >128-bit vector llvm.minimum.v8f64 stays rejected
; (unsupported return type).  Keep operands on arguments so O2 IPSCCP
; cannot constant-fold the intrinsic before VMP sees it.  Native call
; is preserved.  Legal-width f32/f64 vector minimum is covered by
; vmp-fp-vector-minmax-semantic.ll.
define <8 x double> @unsupported_minimum_v8f64(<8 x double> %a, <8 x double> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x double> @llvm.minimum.v8f64(<8 x double> %a, <8 x double> %b)
  ret <8 x double> %r
}

; ---- main: parity checks (finite, one NaN, both NaN, +0/-0) ----

define i32 @main() {
entry:
  ; finite: 1.0 and -2.0
  %e0n = call i64 @reference_minimum_double(double 1.000000e+00, double -2.000000e+00)
  %a0n = call i64 @protected_minimum_double(double 1.000000e+00, double -2.000000e+00)
  %e0x = call i64 @reference_maximum_double(double 1.000000e+00, double -2.000000e+00)
  %a0x = call i64 @protected_maximum_double(double 1.000000e+00, double -2.000000e+00)
  ; one quiet NaN (payload 0x1234) and 1.0
  %e1n = call i64 @reference_minimum_double(double 0x7FF8000000001234, double 1.000000e+00)
  %a1n = call i64 @protected_minimum_double(double 0x7FF8000000001234, double 1.000000e+00)
  %e1x = call i64 @reference_maximum_double(double 0x7FF8000000001234, double 1.000000e+00)
  %a1x = call i64 @protected_maximum_double(double 0x7FF8000000001234, double 1.000000e+00)
  ; both quiet NaN with differing payloads: compare parity only, not payload
  %e2n = call i64 @reference_minimum_double(double 0x7FF8000000001234, double 0x7FF8000000002434)
  %a2n = call i64 @protected_minimum_double(double 0x7FF8000000001234, double 0x7FF8000000002434)
  %e2x = call i64 @reference_maximum_double(double 0x7FF8000000001234, double 0x7FF8000000002434)
  %a2x = call i64 @protected_maximum_double(double 0x7FF8000000001234, double 0x7FF8000000002434)
  ; +0 and -0; LangRef does not pin which signed zero IEEE minimum/maximum
  ; returns when the values compare equal
  %e3n = call i64 @reference_minimum_double(double 0.000000e+00, double -0.000000e+00)
  %a3n = call i64 @protected_minimum_double(double 0.000000e+00, double -0.000000e+00)
  %e3x = call i64 @reference_maximum_double(double 0.000000e+00, double -0.000000e+00)
  %a3x = call i64 @protected_maximum_double(double 0.000000e+00, double -0.000000e+00)
  ; fast minimum/maximum: 1.0/-2.0 and 3.0/1.5 (finite inputs, nnan)
  %e4n = call i64 @reference_fast_minimum_double(double 1.000000e+00, double -2.000000e+00)
  %a4n = call i64 @protected_fast_minimum_double(double 1.000000e+00, double -2.000000e+00)
  %e4x = call i64 @reference_fast_maximum_double(double 1.000000e+00, double -2.000000e+00)
  %a4x = call i64 @protected_fast_maximum_double(double 1.000000e+00, double -2.000000e+00)
  %e5n = call i64 @reference_fast_minimum_double(double 3.000000e+00, double 1.500000e+00)
  %a5n = call i64 @protected_fast_minimum_double(double 3.000000e+00, double 1.500000e+00)
  %e5x = call i64 @reference_fast_maximum_double(double 3.000000e+00, double 1.500000e+00)
  %a5x = call i64 @protected_fast_maximum_double(double 3.000000e+00, double 1.500000e+00)
  %m0n = icmp eq i64 %e0n, %a0n
  %m0x = icmp eq i64 %e0x, %a0x
  %m1n = icmp eq i64 %e1n, %a1n
  %m1x = icmp eq i64 %e1x, %a1x
  %m2n = icmp eq i64 %e2n, %a2n
  %m2x = icmp eq i64 %e2x, %a2x
  %m3n = icmp eq i64 %e3n, %a3n
  %m3x = icmp eq i64 %e3x, %a3x
  %m4n = icmp eq i64 %e4n, %a4n
  %m4x = icmp eq i64 %e4x, %a4x
  %m5n = icmp eq i64 %e5n, %a5n
  %m5x = icmp eq i64 %e5x, %a5x
  %t0 = and i1 %m0n, %m0x
  %t1 = and i1 %m1n, %m1x
  %t2 = and i1 %m2n, %m2x
  %t3 = and i1 %m3n, %m3x
  %t4 = and i1 %m4n, %m4x
  %t5 = and i1 %m5n, %m5x
  %t6 = and i1 %t0, %t1
  %t7 = and i1 %t2, %t3
  %t8 = and i1 %t4, %t5
  %t9 = and i1 %t6, %t7
  %ok = and i1 %t8, %t9
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; ---- O0 checks ----

; SKIP-DAG: Skipping VMP on unsupported_minimum_v8f64: unsupported return type
; SKIP-NOT: Skipping VMP on protected_minimum_double:
; SKIP-NOT: Skipping VMP on protected_maximum_double:
; SKIP-NOT: Skipping VMP on protected_fast_minimum_double:
; SKIP-NOT: Skipping VMP on protected_fast_maximum_double:

; VIRT-LABEL: define i64 @protected_minimum_double(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: call double @llvm.minimum.f64(double
; VIRT-DAG: bitcast double {{.*}} to i64

; VIRT-LABEL: define i64 @protected_maximum_double(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: call double @llvm.maximum.f64(double
; VIRT-DAG: bitcast double {{.*}} to i64

; VIRT-LABEL: define i64 @protected_fast_minimum_double(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT: call nnan double @llvm.minimum.f64(double
; VIRT: bitcast double {{.*}} to i64

; VIRT-LABEL: define i64 @protected_fast_maximum_double(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT: call nnan double @llvm.maximum.f64(double
; VIRT: bitcast double {{.*}} to i64

; Negative cases stay native: no dispatch, no virtualized attribute.
; VIRT-LABEL: define <8 x double> @unsupported_minimum_v8f64(
; VIRT-NOT: vmp.dispatch
; VIRT: call <8 x double> @llvm.minimum.v8f64(

; VIRT: attributes{{.*}}"hikari.vmp.virtualized"{{.*}}

; ---- O2 checks ----

; SKIP-O2-DAG: Skipping VMP on unsupported_minimum_v8f64: unsupported return type
; SKIP-O2-NOT: Skipping VMP on protected_minimum_double:
; SKIP-O2-NOT: Skipping VMP on protected_maximum_double:
; SKIP-O2-NOT: Skipping VMP on protected_fast_minimum_double:
; SKIP-O2-NOT: Skipping VMP on protected_fast_maximum_double:

; VIRT-O2-LABEL: define i64 @protected_minimum_double(
; VIRT-O2: %vmp.fregs = alloca
; VIRT-O2: vmp.dispatch:
; VIRT-O2-DAG: call double @llvm.minimum.f64(double

; VIRT-O2-LABEL: define i64 @protected_maximum_double(
; VIRT-O2: %vmp.fregs = alloca
; VIRT-O2: vmp.dispatch:
; VIRT-O2-DAG: call double @llvm.maximum.f64(double

; VIRT-O2-LABEL: define i64 @protected_fast_minimum_double(
; VIRT-O2: %vmp.fregs = alloca
; VIRT-O2: vmp.dispatch:
; VIRT-O2: call nnan double @llvm.minimum.f64(double
; VIRT-O2: bitcast double {{.*}} to i64

; VIRT-O2-LABEL: define i64 @protected_fast_maximum_double(
; VIRT-O2: %vmp.fregs = alloca
; VIRT-O2: vmp.dispatch:
; VIRT-O2: call nnan double @llvm.maximum.f64(double
; VIRT-O2: bitcast double {{.*}} to i64
; Negative cases stay native at O2 as well.
; VIRT-O2-LABEL: define <8 x double> @unsupported_minimum_v8f64(
; VIRT-O2-NOT: vmp.dispatch
; VIRT-O2: call <8 x double> @llvm.minimum.v8f64(
; VIRT-O2: attributes{{.*}}"hikari.vmp.virtualized"{{.*}}
