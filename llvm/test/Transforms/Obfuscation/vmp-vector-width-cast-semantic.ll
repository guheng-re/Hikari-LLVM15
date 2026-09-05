; Cross-element-width vector CastInst on the fixed-vector VMP surface.
; trunc/zext/sext, fpext/fptrunc, and sitofp/uitofp/fptosi/fptoui may
; change element width; same-width bitcast is unchanged.  Same lane
; count; both ends 1..128; elements i1/i8/i16/i32/i64/f32/f64.
; Same-lane half↔float lives in vmp-half-vector-semantic.ll; half↔double
; stays skipped.
; LLVM 15 CastInst is not an FPMathOperator (FMF on casts is LLVM 16),
; so legal FMF is only on surrounding fadd/fmul/select/phi.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP-O0 < %t.o0.err
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
; RUN: FileCheck %s --check-prefix=SKIP-O0 < %t.o0.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()

define i32 @fold_i32x4(<4 x i32> %v) {
entry:
  %e0 = extractelement <4 x i32> %v, i32 0
  %e1 = extractelement <4 x i32> %v, i32 1
  %e2 = extractelement <4 x i32> %v, i32 2
  %e3 = extractelement <4 x i32> %v, i32 3
  %s0 = add i32 %e0, %e1
  %s1 = add i32 %e2, %e3
  %r = xor i32 %s0, %s1
  ret i32 %r
}

define i32 @fold_i64x2(<2 x i64> %v) {
entry:
  %e0 = extractelement <2 x i64> %v, i32 0
  %e1 = extractelement <2 x i64> %v, i32 1
  %x = xor i64 %e0, %e1
  %t = trunc i64 %x to i32
  ret i32 %t
}

; <4 x i8> <-> <4 x i32>, <4 x i16> <-> <4 x i32>, i1 mask zext,
; overflow/trunc edges, leftover-style byte add.
define i32 @reference_int_width(<4 x i8> %b, <4 x i16> %s, <4 x i32> %w) noinline optnone {
entry:
  %bz = zext <4 x i8> %b to <4 x i32>
  %bs = sext <4 x i8> %b to <4 x i32>
  %bt = trunc <4 x i32> %w to <4 x i8>
  %btz = zext <4 x i8> %bt to <4 x i32>
  %sz = zext <4 x i16> %s to <4 x i32>
  %ss = sext <4 x i16> %s to <4 x i32>
  %st = trunc <4 x i32> %w to <4 x i16>
  %stz = zext <4 x i16> %st to <4 x i32>
  %neg = icmp slt <4 x i32> %w, zeroinitializer
  %mz = zext <4 x i1> %neg to <4 x i32>
  %sum = add <4 x i32> %bz, %sz
  %back = trunc <4 x i32> %sum to <4 x i8>
  %backz = zext <4 x i8> %back to <4 x i32>
  %m0 = xor <4 x i32> %bz, %bs
  %m1 = xor <4 x i32> %btz, %sz
  %m2 = xor <4 x i32> %ss, %stz
  %m3 = xor <4 x i32> %mz, %backz
  %m4 = xor <4 x i32> %m0, %m1
  %m5 = xor <4 x i32> %m2, %m3
  %mix = xor <4 x i32> %m4, %m5
  %r = call i32 @fold_i32x4(<4 x i32> %mix)
  ret i32 %r
}

define i32 @protected_int_width(<4 x i8> %b, <4 x i16> %s, <4 x i32> %w) noinline optnone {
entry:
  call void @hikari_vmp()
  %bz = zext <4 x i8> %b to <4 x i32>
  %bs = sext <4 x i8> %b to <4 x i32>
  %bt = trunc <4 x i32> %w to <4 x i8>
  %btz = zext <4 x i8> %bt to <4 x i32>
  %sz = zext <4 x i16> %s to <4 x i32>
  %ss = sext <4 x i16> %s to <4 x i32>
  %st = trunc <4 x i32> %w to <4 x i16>
  %stz = zext <4 x i16> %st to <4 x i32>
  %neg = icmp slt <4 x i32> %w, zeroinitializer
  %mz = zext <4 x i1> %neg to <4 x i32>
  %sum = add <4 x i32> %bz, %sz
  %back = trunc <4 x i32> %sum to <4 x i8>
  %backz = zext <4 x i8> %back to <4 x i32>
  %m0 = xor <4 x i32> %bz, %bs
  %m1 = xor <4 x i32> %btz, %sz
  %m2 = xor <4 x i32> %ss, %stz
  %m3 = xor <4 x i32> %mz, %backz
  %m4 = xor <4 x i32> %m0, %m1
  %m5 = xor <4 x i32> %m2, %m3
  %mix = xor <4 x i32> %m4, %m5
  %r = call i32 @fold_i32x4(<4 x i32> %mix)
  ret i32 %r
}

; <4 x i32> <-> <4 x float>, <2 x i32> <-> <2 x double>,
; <4 x i8> sitofp to <4 x float>, same-width bitcast, f32<->f64 via
; <2 x float> <-> <2 x double> (the 4xf32<->4xf64 pair is 256 bits).
define i32 @reference_fp_cast(<4 x i32> %w, <4 x float> %f, <2 x i32> %w2, <2 x float> %f2, <4 x i8> %b) noinline optnone {
entry:
  %sf = sitofp <4 x i32> %w to <4 x float>
  %uf = uitofp <4 x i32> %w to <4 x float>
  %si = fptosi <4 x float> %f to <4 x i32>
  %ui = fptoui <4 x float> %f to <4 x i32>
  %bf = sitofp <4 x i8> %b to <4 x float>
  %bc = bitcast <4 x float> %f to <4 x i32>
  %sd = sitofp <2 x i32> %w2 to <2 x double>
  %ud = uitofp <2 x i32> %w2 to <2 x double>
  %sdi = fptosi <2 x double> %sd to <2 x i32>
  %udi = fptoui <2 x double> %ud to <2 x i32>
  %dx = fpext <2 x float> %f2 to <2 x double>
  %dn = fptrunc <2 x double> %dx to <2 x float>
  %dxi = fptosi <2 x double> %dx to <2 x i32>
  %dni = bitcast <2 x float> %dn to <2 x i32>
  %m0 = fadd <4 x float> %sf, %uf
  %m1 = fadd <4 x float> %m0, %bf
  %m1i = fptosi <4 x float> %m1 to <4 x i32>
  %m2 = xor <4 x i32> %si, %ui
  %m3 = xor <4 x i32> %bc, %m1i
  %m4 = xor <4 x i32> %m2, %m3
  %r0 = call i32 @fold_i32x4(<4 x i32> %m4)
  %p0 = xor <2 x i32> %sdi, %udi
  %p1 = xor <2 x i32> %dxi, %dni
  %p2 = xor <2 x i32> %p0, %p1
  %e0 = extractelement <2 x i32> %p2, i32 0
  %e1 = extractelement <2 x i32> %p2, i32 1
  %r1 = xor i32 %e0, %e1
  %out = xor i32 %r0, %r1
  ret i32 %out
}

define i32 @protected_fp_cast(<4 x i32> %w, <4 x float> %f, <2 x i32> %w2, <2 x float> %f2, <4 x i8> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %sf = sitofp <4 x i32> %w to <4 x float>
  %uf = uitofp <4 x i32> %w to <4 x float>
  %si = fptosi <4 x float> %f to <4 x i32>
  %ui = fptoui <4 x float> %f to <4 x i32>
  %bf = sitofp <4 x i8> %b to <4 x float>
  %bc = bitcast <4 x float> %f to <4 x i32>
  %sd = sitofp <2 x i32> %w2 to <2 x double>
  %ud = uitofp <2 x i32> %w2 to <2 x double>
  %sdi = fptosi <2 x double> %sd to <2 x i32>
  %udi = fptoui <2 x double> %ud to <2 x i32>
  %dx = fpext <2 x float> %f2 to <2 x double>
  %dn = fptrunc <2 x double> %dx to <2 x float>
  %dxi = fptosi <2 x double> %dx to <2 x i32>
  %dni = bitcast <2 x float> %dn to <2 x i32>
  %m0 = fadd <4 x float> %sf, %uf
  %m1 = fadd <4 x float> %m0, %bf
  %m1i = fptosi <4 x float> %m1 to <4 x i32>
  %m2 = xor <4 x i32> %si, %ui
  %m3 = xor <4 x i32> %bc, %m1i
  %m4 = xor <4 x i32> %m2, %m3
  %r0 = call i32 @fold_i32x4(<4 x i32> %m4)
  %p0 = xor <2 x i32> %sdi, %udi
  %p1 = xor <2 x i32> %dxi, %dni
  %p2 = xor <2 x i32> %p0, %p1
  %e0 = extractelement <2 x i32> %p2, i32 0
  %e1 = extractelement <2 x i32> %p2, i32 1
  %r1 = xor i32 %e0, %e1
  %out = xor i32 %r0, %r1
  ret i32 %out
}

; Legal FMF lives on fadd/fmul (not on the LLVM 15 cast).
define i32 @reference_fmf(<4 x i32> %w, <2 x float> %f2) noinline optnone {
entry:
  %sf = sitofp <4 x i32> %w to <4 x float>
  %fa = fadd fast <4 x float> %sf, %sf
  %fm = fmul nnan ninf <4 x float> %fa, <float 2.000000e+00, float 2.000000e+00, float 2.000000e+00, float 2.000000e+00>
  %dx = fpext <2 x float> %f2 to <2 x double>
  %da = fadd fast <2 x double> %dx, %dx
  %di = fptosi <4 x float> %fm to <4 x i32>
  %r0 = call i32 @fold_i32x4(<4 x i32> %di)
  %db = bitcast <2 x double> %da to <2 x i64>
  %r1 = call i32 @fold_i64x2(<2 x i64> %db)
  %out = xor i32 %r0, %r1
  ret i32 %out
}

define i32 @protected_fmf(<4 x i32> %w, <2 x float> %f2) noinline optnone {
entry:
  call void @hikari_vmp()
  %sf = sitofp <4 x i32> %w to <4 x float>
  %fa = fadd fast <4 x float> %sf, %sf
  %fm = fmul nnan ninf <4 x float> %fa, <float 2.000000e+00, float 2.000000e+00, float 2.000000e+00, float 2.000000e+00>
  %dx = fpext <2 x float> %f2 to <2 x double>
  %da = fadd fast <2 x double> %dx, %dx
  %di = fptosi <4 x float> %fm to <4 x i32>
  %r0 = call i32 @fold_i32x4(<4 x i32> %di)
  %db = bitcast <2 x double> %da to <2 x i64>
  %r1 = call i32 @fold_i64x2(<2 x i64> %db)
  %out = xor i32 %r0, %r1
  ret i32 %out
}

; ----- negatives: selected, not virtualized -----

; Constant scalable zext can fold under default<O2>; O0 must skip.
define i32 @unsupported_cast_scalable() noinline optnone {
entry:
  call void @hikari_vmp()
  %r = zext <vscale x 4 x i8> zeroinitializer to <vscale x 4 x i32>
  ret i32 0
}

define i32 @unsupported_cast_wide(<4 x i16> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %w = zext <4 x i16> %v to <4 x i64>
  %e = extractelement <4 x i64> %w, i32 0
  %t = trunc i64 %e to i32
  ret i32 %t
}

define i32 @unsupported_cast_half_double(<2 x half> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %d = fpext <2 x half> %v to <2 x double>
  %e = extractelement <2 x double> %d, i32 0
  %b = bitcast double %e to i64
  %t = trunc i64 %b to i32
  ret i32 %t
}

; Conversion casts with mismatched EC are verifier-illegal.  inttoptr
; of a supported integer vector to a pointer vector is the live stand-in.
define ptr @unsupported_cast_ptrvec(<2 x i64> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %p = inttoptr <2 x i64> %v to <2 x ptr>
  %e = extractelement <2 x ptr> %p, i32 0
  ret ptr %e
}

; <4 x float> -> <4 x double> is 128 -> 256, over the 128-bit cap.
define i32 @unsupported_cast_over128(<4 x float> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %w = fpext <4 x float> %v to <4 x double>
  %e = extractelement <4 x double> %w, i32 0
  %b = bitcast double %e to i64
  %t = trunc i64 %b to i32
  ret i32 %t
}

define i32 @main() {
entry:
  %b0 = insertelement <4 x i8> poison, i8 -1, i32 0
  %b1 = insertelement <4 x i8> %b0, i8 -128, i32 1
  %b2 = insertelement <4 x i8> %b1, i8 1, i32 2
  %b3 = insertelement <4 x i8> %b2, i8 0, i32 3

  %s0 = insertelement <4 x i16> poison, i16 -2, i32 0
  %s1 = insertelement <4 x i16> %s0, i16 400, i32 1
  %s2 = insertelement <4 x i16> %s1, i16 -30000, i32 2
  %s3 = insertelement <4 x i16> %s2, i16 7, i32 3

  %w0 = insertelement <4 x i32> poison, i32 300, i32 0
  %w1 = insertelement <4 x i32> %w0, i32 -5, i32 1
  %w2 = insertelement <4 x i32> %w1, i32 7, i32 2
  %w3 = insertelement <4 x i32> %w2, i32 1, i32 3

  %ei = call i32 @reference_int_width(<4 x i8> %b3, <4 x i16> %s3, <4 x i32> %w3)
  %ai = call i32 @protected_int_width(<4 x i8> %b3, <4 x i16> %s3, <4 x i32> %w3)
  %ok0 = icmp eq i32 %ei, %ai

  %f = sitofp <4 x i32> %w3 to <4 x float>
  %w2v = shufflevector <4 x i32> %w3, <4 x i32> poison, <2 x i32> <i32 0, i32 1>
  %f2 = sitofp <2 x i32> %w2v to <2 x float>
  %ef = call i32 @reference_fp_cast(<4 x i32> %w3, <4 x float> %f, <2 x i32> %w2v, <2 x float> %f2, <4 x i8> %b3)
  %af = call i32 @protected_fp_cast(<4 x i32> %w3, <4 x float> %f, <2 x i32> %w2v, <2 x float> %f2, <4 x i8> %b3)
  %ok1 = icmp eq i32 %ef, %af

  %em = call i32 @reference_fmf(<4 x i32> %w3, <2 x float> %f2)
  %am = call i32 @protected_fmf(<4 x i32> %w3, <2 x float> %f2)
  %ok2 = icmp eq i32 %em, %am

  %t0 = and i1 %ok0, %ok1
  %ok = and i1 %t0, %ok2
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP-DAG: Skipping VMP on unsupported_cast_wide: unsupported vector cast instruction
; SKIP-DAG: Skipping VMP on unsupported_cast_half_double: unsupported vector cast instruction
; SKIP-DAG: Skipping VMP on unsupported_cast_ptrvec: unsupported vector cast instruction
; SKIP-DAG: Skipping VMP on unsupported_cast_over128: unsupported vector cast instruction
; SKIP-NOT: Skipping VMP on protected_int_width:
; SKIP-NOT: Skipping VMP on protected_fp_cast:
; SKIP-NOT: Skipping VMP on protected_fmf:
; Constant scalable zext can fold under default<O2>.
; SKIP-O0-DAG: Skipping VMP on unsupported_cast_scalable: unsupported vector cast instruction

; VIRT-LABEL: define i32 @protected_int_width(
; VIRT: vmp.dispatch:
; VIRT-DAG: zext <4 x i8>
; VIRT-DAG: sext <4 x i8>
; VIRT-DAG: trunc <4 x i32> {{.*}} to <4 x i8>
; VIRT-DAG: zext <4 x i16>
; VIRT-DAG: sext <4 x i16>
; VIRT-DAG: trunc <4 x i32> {{.*}} to <4 x i16>
; VIRT-DAG: zext <4 x i1>

; VIRT-LABEL: define i32 @protected_fp_cast(
; VIRT: vmp.dispatch:
; VIRT-DAG: sitofp <4 x i32> {{.*}} to <4 x float>
; VIRT-DAG: uitofp <4 x i32> {{.*}} to <4 x float>
; VIRT-DAG: fptosi <4 x float> {{.*}} to <4 x i32>
; VIRT-DAG: fptoui <4 x float> {{.*}} to <4 x i32>
; VIRT-DAG: sitofp <4 x i8> {{.*}} to <4 x float>
; VIRT-DAG: sitofp <2 x i32> {{.*}} to <2 x double>
; VIRT-DAG: fpext <2 x float> {{.*}} to <2 x double>
; VIRT-DAG: fptrunc <2 x double> {{.*}} to <2 x float>
; VIRT-DAG: bitcast <4 x float> {{.*}} to <4 x i32>

; VIRT-LABEL: define i32 @protected_fmf(
; VIRT: vmp.dispatch:
; VIRT-DAG: sitofp <4 x i32> {{.*}} to <4 x float>
; VIRT-DAG: fadd fast <4 x float>
; VIRT-DAG: fmul nnan ninf <4 x float>
; VIRT-DAG: fpext <2 x float> {{.*}} to <2 x double>
; VIRT-DAG: fadd fast <2 x double>

; VIRT-LABEL: define {{.*}} @unsupported_cast_scalable(
; VIRT-LABEL: define {{.*}} @unsupported_cast_wide(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_cast_half_double(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_cast_ptrvec(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_cast_over128(
; VIRT-NOT: vmp.dispatch
; VIRT: "hikari.vmp.virtualized"
