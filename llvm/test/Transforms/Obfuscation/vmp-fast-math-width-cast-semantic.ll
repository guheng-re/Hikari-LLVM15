; Scalar f32<->f64 fpext/fptrunc width casts under VMP, with the FMF plumbing
; in place.  LLVM 15's parser rejects fast-math keywords on fpext/fptrunc
; (that syntax arrived in LLVM 16), so a textual FMF width cast cannot exist
; here: the positive cases exercise the packed Variant's no-FMF form
; (source width 32/64 in the low 8 bits, zero FMF bits above), which is the
; exact compatibility path for API-constructed FMF casts.  The interpreter
; unpacks source width and FMF and re-applies flags on native
; CreateFPExt/CreateFPTrunc.  reference/* run natively, vmp/* are virtualized;
; main compares bitcast results (1.1 inputs make a bitcast-as-conversion
; detectable).  Negative cases (half and vector width casts via the argument
; gate) and a non-AArch64 module skip safely.
; O0 carries the detailed VIRT checks; O2 re-checks eligibility/stability.
;
; RUN: opt -S -verify-each -aesSeed=109 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.ll -o %t.o0.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=109 -passes='default<O2>' %s -o %t.o2.ll 2>%t.o2.err
; RUN: FileCheck %s --check-prefix=SKIP-O2 < %t.o2.err
; RUN: FileCheck %s --check-prefix=VIRT-O2 < %t.o2.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.ll -o %t.o2.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: opt -S -verify-each -aesSeed=109 -mtriple=x86_64-unknown-linux-gnu -passes='default<O0>' %s -o %t.x86.ll 2>%t.x86.err
; RUN: FileCheck %s --check-prefix=SKIP-X86 < %t.x86.err

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()

; ---- reference: native width casts ----

; f32 -> f64 widen; result compared as i64 bits.
define i32 @reference_widen(float %x) {
entry:
  %d = fpext float %x to double
  %b = bitcast double %d to i64
  %lo = trunc i64 %b to i32
  %hi = lshr i64 %b, 32
  %hi32 = trunc i64 %hi to i32
  %mix = xor i32 %lo, %hi32
  ret i32 %mix
}

; f64 -> f32 narrow.
define i32 @reference_narrow(double %x) {
entry:
  %f = fptrunc double %x to float
  %b = bitcast float %f to i32
  ret i32 %b
}

; ---- vmp: same chains under VMP ----

define i32 @vmp_widen(float %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %d = fpext float %x to double
  %b = bitcast double %d to i64
  %lo = trunc i64 %b to i32
  %hi = lshr i64 %b, 32
  %hi32 = trunc i64 %hi to i32
  %mix = xor i32 %lo, %hi32
  ret i32 %mix
}

define i32 @vmp_narrow(double %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %f = fptrunc double %x to float
  %b = bitcast float %f to i32
  ret i32 %b
}

; ---- negative cases: must SKIP, never virtualize ----

; half fpext rejected at the argument-type gate.
define i32 @unsupported_half_fpext(half %h) noinline optnone {
entry:
  call void @hikari_vmp()
  %d = fpext half %h to double
  ret i32 0
}

; vector fptrunc rejected at the argument-type gate.
define i32 @unsupported_vec_fptrunc(<2 x double> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %f = fptrunc <2 x double> %v to <2 x float>
  ret i32 0
}

; ---- main: parity checks ----

define i32 @main() {
entry:
  %e0 = call i32 @reference_widen(float 0x3FF4CCCD00000000)
  %a0 = call i32 @vmp_widen(float 0x3FF4CCCD00000000)
  %e1 = call i32 @reference_narrow(double 1.100000e+00)
  %a1 = call i32 @vmp_narrow(double 1.100000e+00)
  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %e1, %a1
  %ok = and i1 %m0, %m1
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; ---- O0 checks ----

; SKIP-DAG: Skipping VMP on unsupported_half_fpext: unsupported argument type
; SKIP-DAG: Skipping VMP on unsupported_vec_fptrunc: unsupported argument type
; SKIP-NOT: Skipping VMP on vmp_:

; VIRT-LABEL: define i32 @vmp_widen(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT: fpext float {{.*}} to double
; VIRT-LABEL: define i32 @vmp_narrow(
; VIRT: %vmp.fregs = alloca
; VIRT: vmp.dispatch:
; VIRT: fptrunc double {{.*}} to float

; Negative cases stay native: no dispatch, no virtualized attribute.
; VIRT-LABEL: define i32 @unsupported_half_fpext(
; VIRT-NOT: vmp.dispatch
; VIRT: fpext half
; VIRT-LABEL: define i32 @unsupported_vec_fptrunc(
; VIRT-NOT: vmp.dispatch
; VIRT: fptrunc <2 x double>

; VIRT: attributes{{.*}}"hikari.vmp.virtualized"

; ---- O2 checks ----

; SKIP-O2-DAG: Skipping VMP on unsupported_half_fpext: unsupported argument type
; SKIP-O2-DAG: Skipping VMP on unsupported_vec_fptrunc: unsupported argument type
; SKIP-O2-NOT: Skipping VMP on vmp_:

; VIRT-O2-LABEL: define i32 @vmp_widen(
; VIRT-O2: %vmp.fregs = alloca
; VIRT-O2: vmp.dispatch:
; VIRT-O2: fpext float {{.*}} to double
; VIRT-O2: attributes{{.*}}"hikari.vmp.virtualized"

; Non-AArch64 module triple: VMP skips all selected functions wholesale.
; SKIP-X86: Skipping VMP: only AArch64 targets are supported
