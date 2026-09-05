; Restricted llvm.vector.reduce.* for auto-vectorization loop tails.
; VMP replays the intrinsic through CallDescriptor (vector args, scalar
; result, FunctionType, C CC, attributes, metadata, FastMathFlags).
; Integer: add/mul/and/or/xor/smin/smax/umin/umax.  Float: fadd/fmul
; (LLVM 15 start + vec) and fmin/fmax.  Half float reduce is gated by
; last-token +fullfp16 (see vmp-half-vector-masked-reduce-semantic.ll).
; AArch64 llc selects this set.
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

declare i32 @llvm.vector.reduce.add.v4i32(<4 x i32>)
declare i32 @llvm.vector.reduce.mul.v4i32(<4 x i32>)
declare i32 @llvm.vector.reduce.and.v4i32(<4 x i32>)
declare i32 @llvm.vector.reduce.or.v4i32(<4 x i32>)
declare i32 @llvm.vector.reduce.xor.v4i32(<4 x i32>)
declare i32 @llvm.vector.reduce.smin.v4i32(<4 x i32>)
declare i32 @llvm.vector.reduce.smax.v4i32(<4 x i32>)
declare i32 @llvm.vector.reduce.umin.v4i32(<4 x i32>)
declare i32 @llvm.vector.reduce.umax.v4i32(<4 x i32>)
declare i16 @llvm.vector.reduce.smin.v8i16(<8 x i16>)
declare i8 @llvm.vector.reduce.add.v16i8(<16 x i8>)
declare i64 @llvm.vector.reduce.add.v2i64(<2 x i64>)
declare i1 @llvm.vector.reduce.or.v4i1(<4 x i1>)
declare i1 @llvm.vector.reduce.and.v4i1(<4 x i1>)
declare i1 @llvm.vector.reduce.xor.v4i1(<4 x i1>)
declare float @llvm.vector.reduce.fadd.v4f32(float, <4 x float>)
declare float @llvm.vector.reduce.fmul.v4f32(float, <4 x float>)
declare float @llvm.vector.reduce.fmin.v4f32(<4 x float>)
declare float @llvm.vector.reduce.fmax.v4f32(<4 x float>)
declare double @llvm.vector.reduce.fadd.v2f64(double, <2 x double>)
declare double @llvm.vector.reduce.fmul.v2f64(double, <2 x double>)
declare double @llvm.vector.reduce.fmin.v2f64(<2 x double>)
declare double @llvm.vector.reduce.fmax.v2f64(<2 x double>)

declare i32 @llvm.vector.reduce.add.v8i32(<8 x i32>)
declare i32 @llvm.vector.reduce.add.nxv4i32(<vscale x 4 x i32>)
declare half @llvm.vector.reduce.fmin.v4f16(<4 x half>)
declare i3 @llvm.vector.reduce.add.v4i3(<4 x i3>)
declare i32 @llvm.vp.reduce.add.v4i32(i32, <4 x i32>, <4 x i1>, i32)

@chunks = private global [8 x i32] [i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7, i32 8], align 16

; Middle-block style tail: accumulate VF=4 chunks, then reduce.add.
define i32 @reference_loop_reduce(ptr %p, i32 %n) noinline optnone {
entry:
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %i.next, %loop ]
  %acc = phi <4 x i32> [ zeroinitializer, %entry ], [ %acc.next, %loop ]
  %idx = zext i32 %i to i64
  %q = getelementptr inbounds i32, ptr %p, i64 %idx
  %ld = load <4 x i32>, ptr %q, align 4
  %acc.next = add <4 x i32> %acc, %ld
  %i.next = add i32 %i, 4
  %more = icmp slt i32 %i.next, %n
  br i1 %more, label %loop, label %tail

tail:
  %r = call i32 @llvm.vector.reduce.add.v4i32(<4 x i32> %acc.next)
  ret i32 %r
}

define i32 @protected_loop_reduce(ptr %p, i32 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %i.next, %loop ]
  %acc = phi <4 x i32> [ zeroinitializer, %entry ], [ %acc.next, %loop ]
  %idx = zext i32 %i to i64
  %q = getelementptr inbounds i32, ptr %p, i64 %idx
  %ld = load <4 x i32>, ptr %q, align 4
  %acc.next = add <4 x i32> %acc, %ld
  %i.next = add i32 %i, 4
  %more = icmp slt i32 %i.next, %n
  br i1 %more, label %loop, label %tail

tail:
  %r = call i32 @llvm.vector.reduce.add.v4i32(<4 x i32> %acc.next)
  ret i32 %r
}

define i32 @reference_int_reduce(<4 x i32> %leftover) noinline optnone {
entry:
  %add = call i32 @llvm.vector.reduce.add.v4i32(<4 x i32> %leftover)
  %mul = call i32 @llvm.vector.reduce.mul.v4i32(<4 x i32> %leftover)
  %and = call i32 @llvm.vector.reduce.and.v4i32(<4 x i32> %leftover)
  %or  = call i32 @llvm.vector.reduce.or.v4i32(<4 x i32> %leftover)
  %xor = call i32 @llvm.vector.reduce.xor.v4i32(<4 x i32> %leftover)
  %smin = call i32 @llvm.vector.reduce.smin.v4i32(<4 x i32> %leftover)
  %smax = call i32 @llvm.vector.reduce.smax.v4i32(<4 x i32> %leftover)
  %umin = call i32 @llvm.vector.reduce.umin.v4i32(<4 x i32> %leftover)
  %umax = call i32 @llvm.vector.reduce.umax.v4i32(<4 x i32> %leftover)
  %as16 = bitcast <4 x i32> %leftover to <8 x i16>
  %smin16 = call i16 @llvm.vector.reduce.smin.v8i16(<8 x i16> %as16)
  %as8 = bitcast <4 x i32> %leftover to <16 x i8>
  %add8 = call i8 @llvm.vector.reduce.add.v16i8(<16 x i8> %as8)
  %as64 = bitcast <4 x i32> %leftover to <2 x i64>
  %add64 = call i64 @llvm.vector.reduce.add.v2i64(<2 x i64> %as64)
  %neg = icmp slt <4 x i32> %leftover, zeroinitializer
  %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %neg)
  %all = call i1 @llvm.vector.reduce.and.v4i1(<4 x i1> %neg)
  %par = call i1 @llvm.vector.reduce.xor.v4i1(<4 x i1> %neg)
  %s16z = sext i16 %smin16 to i32
  %a8z = zext i8 %add8 to i32
  %a64t = trunc i64 %add64 to i32
  %anyz = zext i1 %any to i32
  %allz = zext i1 %all to i32
  %parz = zext i1 %par to i32
  %m0 = xor i32 %add, %mul
  %m1 = xor i32 %and, %or
  %m2 = xor i32 %xor, %smin
  %m3 = xor i32 %smax, %umin
  %m4 = xor i32 %umax, %s16z
  %m5 = xor i32 %a8z, %a64t
  %m6 = xor i32 %anyz, %allz
  %m7 = xor i32 %m0, %m1
  %m8 = xor i32 %m2, %m3
  %m9 = xor i32 %m4, %m5
  %ma = xor i32 %m6, %parz
  %mb = xor i32 %m7, %m8
  %mc = xor i32 %m9, %ma
  %out = xor i32 %mb, %mc
  ret i32 %out
}

define i32 @protected_int_reduce(<4 x i32> %leftover) noinline optnone {
entry:
  call void @hikari_vmp()
  %add = call i32 @llvm.vector.reduce.add.v4i32(<4 x i32> %leftover)
  %mul = call i32 @llvm.vector.reduce.mul.v4i32(<4 x i32> %leftover)
  %and = call i32 @llvm.vector.reduce.and.v4i32(<4 x i32> %leftover)
  %or  = call i32 @llvm.vector.reduce.or.v4i32(<4 x i32> %leftover)
  %xor = call i32 @llvm.vector.reduce.xor.v4i32(<4 x i32> %leftover)
  %smin = call i32 @llvm.vector.reduce.smin.v4i32(<4 x i32> %leftover)
  %smax = call i32 @llvm.vector.reduce.smax.v4i32(<4 x i32> %leftover)
  %umin = call i32 @llvm.vector.reduce.umin.v4i32(<4 x i32> %leftover)
  %umax = call i32 @llvm.vector.reduce.umax.v4i32(<4 x i32> %leftover)
  %as16 = bitcast <4 x i32> %leftover to <8 x i16>
  %smin16 = call i16 @llvm.vector.reduce.smin.v8i16(<8 x i16> %as16)
  %as8 = bitcast <4 x i32> %leftover to <16 x i8>
  %add8 = call i8 @llvm.vector.reduce.add.v16i8(<16 x i8> %as8)
  %as64 = bitcast <4 x i32> %leftover to <2 x i64>
  %add64 = call i64 @llvm.vector.reduce.add.v2i64(<2 x i64> %as64)
  %neg = icmp slt <4 x i32> %leftover, zeroinitializer
  %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %neg)
  %all = call i1 @llvm.vector.reduce.and.v4i1(<4 x i1> %neg)
  %par = call i1 @llvm.vector.reduce.xor.v4i1(<4 x i1> %neg)
  %s16z = sext i16 %smin16 to i32
  %a8z = zext i8 %add8 to i32
  %a64t = trunc i64 %add64 to i32
  %anyz = zext i1 %any to i32
  %allz = zext i1 %all to i32
  %parz = zext i1 %par to i32
  %m0 = xor i32 %add, %mul
  %m1 = xor i32 %and, %or
  %m2 = xor i32 %xor, %smin
  %m3 = xor i32 %smax, %umin
  %m4 = xor i32 %umax, %s16z
  %m5 = xor i32 %a8z, %a64t
  %m6 = xor i32 %anyz, %allz
  %m7 = xor i32 %m0, %m1
  %m8 = xor i32 %m2, %m3
  %m9 = xor i32 %m4, %m5
  %ma = xor i32 %m6, %parz
  %mb = xor i32 %m7, %m8
  %mc = xor i32 %m9, %ma
  %out = xor i32 %mb, %mc
  ret i32 %out
}

define i32 @reference_fp_reduce(<4 x float> %leftover) noinline optnone {
entry:
  %fadd = call float @llvm.vector.reduce.fadd.v4f32(float 0.000000e+00, <4 x float> %leftover)
  %fadd.fast = call fast float @llvm.vector.reduce.fadd.v4f32(float 0.000000e+00, <4 x float> %leftover)
  %fmul = call float @llvm.vector.reduce.fmul.v4f32(float 1.000000e+00, <4 x float> %leftover)
  %fmul.re = call reassoc float @llvm.vector.reduce.fmul.v4f32(float 1.000000e+00, <4 x float> %leftover)
  %fmin = call float @llvm.vector.reduce.fmin.v4f32(<4 x float> %leftover)
  %fmin.fmf = call nnan ninf float @llvm.vector.reduce.fmin.v4f32(<4 x float> %leftover)
  %fmax = call float @llvm.vector.reduce.fmax.v4f32(<4 x float> %leftover)
  %fmax.fmf = call nsz contract float @llvm.vector.reduce.fmax.v4f32(<4 x float> %leftover)
  %as64 = bitcast <4 x float> %leftover to <2 x double>
  %dadd = call double @llvm.vector.reduce.fadd.v2f64(double 0.000000e+00, <2 x double> %as64)
  %dmul = call double @llvm.vector.reduce.fmul.v2f64(double 1.000000e+00, <2 x double> %as64)
  %dmin = call double @llvm.vector.reduce.fmin.v2f64(<2 x double> %as64)
  %dmax = call double @llvm.vector.reduce.fmax.v2f64(<2 x double> %as64)
  %b0 = bitcast float %fadd to i32
  %b1 = bitcast float %fadd.fast to i32
  %b2 = bitcast float %fmul to i32
  %b3 = bitcast float %fmul.re to i32
  %b4 = bitcast float %fmin to i32
  %b5 = bitcast float %fmin.fmf to i32
  %b6 = bitcast float %fmax to i32
  %b7 = bitcast float %fmax.fmf to i32
  %d0 = bitcast double %dadd to i64
  %d1 = bitcast double %dmul to i64
  %d2 = bitcast double %dmin to i64
  %d3 = bitcast double %dmax to i64
  %d0t = trunc i64 %d0 to i32
  %d1t = trunc i64 %d1 to i32
  %d2t = trunc i64 %d2 to i32
  %d3t = trunc i64 %d3 to i32
  %x0 = xor i32 %b0, %b1
  %x1 = xor i32 %b2, %b3
  %x2 = xor i32 %b4, %b5
  %x3 = xor i32 %b6, %b7
  %x4 = xor i32 %d0t, %d1t
  %x5 = xor i32 %d2t, %d3t
  %y0 = xor i32 %x0, %x1
  %y1 = xor i32 %x2, %x3
  %y2 = xor i32 %x4, %x5
  %y3 = xor i32 %y0, %y1
  %out = xor i32 %y3, %y2
  ret i32 %out
}

define i32 @protected_fp_reduce(<4 x float> %leftover) noinline optnone {
entry:
  call void @hikari_vmp()
  %fadd = call float @llvm.vector.reduce.fadd.v4f32(float 0.000000e+00, <4 x float> %leftover)
  %fadd.fast = call fast float @llvm.vector.reduce.fadd.v4f32(float 0.000000e+00, <4 x float> %leftover)
  %fmul = call float @llvm.vector.reduce.fmul.v4f32(float 1.000000e+00, <4 x float> %leftover)
  %fmul.re = call reassoc float @llvm.vector.reduce.fmul.v4f32(float 1.000000e+00, <4 x float> %leftover)
  %fmin = call float @llvm.vector.reduce.fmin.v4f32(<4 x float> %leftover)
  %fmin.fmf = call nnan ninf float @llvm.vector.reduce.fmin.v4f32(<4 x float> %leftover)
  %fmax = call float @llvm.vector.reduce.fmax.v4f32(<4 x float> %leftover)
  %fmax.fmf = call nsz contract float @llvm.vector.reduce.fmax.v4f32(<4 x float> %leftover)
  %as64 = bitcast <4 x float> %leftover to <2 x double>
  %dadd = call double @llvm.vector.reduce.fadd.v2f64(double 0.000000e+00, <2 x double> %as64)
  %dmul = call double @llvm.vector.reduce.fmul.v2f64(double 1.000000e+00, <2 x double> %as64)
  %dmin = call double @llvm.vector.reduce.fmin.v2f64(<2 x double> %as64)
  %dmax = call double @llvm.vector.reduce.fmax.v2f64(<2 x double> %as64)
  %b0 = bitcast float %fadd to i32
  %b1 = bitcast float %fadd.fast to i32
  %b2 = bitcast float %fmul to i32
  %b3 = bitcast float %fmul.re to i32
  %b4 = bitcast float %fmin to i32
  %b5 = bitcast float %fmin.fmf to i32
  %b6 = bitcast float %fmax to i32
  %b7 = bitcast float %fmax.fmf to i32
  %d0 = bitcast double %dadd to i64
  %d1 = bitcast double %dmul to i64
  %d2 = bitcast double %dmin to i64
  %d3 = bitcast double %dmax to i64
  %d0t = trunc i64 %d0 to i32
  %d1t = trunc i64 %d1 to i32
  %d2t = trunc i64 %d2 to i32
  %d3t = trunc i64 %d3 to i32
  %x0 = xor i32 %b0, %b1
  %x1 = xor i32 %b2, %b3
  %x2 = xor i32 %b4, %b5
  %x3 = xor i32 %b6, %b7
  %x4 = xor i32 %d0t, %d1t
  %x5 = xor i32 %d2t, %d3t
  %y0 = xor i32 %x0, %x1
  %y1 = xor i32 %x2, %x3
  %y2 = xor i32 %x4, %x5
  %y3 = xor i32 %y0, %y1
  %out = xor i32 %y3, %y2
  ret i32 %out
}

; ----- negatives: selected, not virtualized -----

define i32 @unsupported_reduce_scalable() noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.vector.reduce.add.nxv4i32(<vscale x 4 x i32> zeroinitializer)
  ret i32 %r
}

define i32 @unsupported_reduce_wide() noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.vector.reduce.add.v8i32(<8 x i32> zeroinitializer)
  ret i32 %r
}

; Well-shaped half fmin without last-token +fullfp16: feature skip.
define i32 @unsupported_reduce_half() noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.vector.reduce.fmin.v4f16(<4 x half> zeroinitializer)
  ret i32 0
}

define i32 @unsupported_reduce_wrong_elt() noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i3 @llvm.vector.reduce.add.v4i3(<4 x i3> <i3 1, i3 1, i3 1, i3 1>)
  %z = zext i3 %r to i32
  ret i32 %z
}

define i32 @unsupported_reduce_wrong_signature(<4 x i32> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call fastcc i32 @llvm.vector.reduce.add.v4i32(<4 x i32> %v)
  ret i32 %r
}

define i32 @unsupported_reduce_family(<4 x i32> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @llvm.vp.reduce.add.v4i32(i32 0, <4 x i32> %v, <4 x i1> <i1 true, i1 true, i1 true, i1 true>, i32 4)
  ret i32 %r
}

; Mixed C i32(<4 x i32>) indirect is a previously opened CallDescriptor
; surface, not a reduce-family reject.
define i32 @protected_indirect_vector_call(ptr %fp, <4 x i32> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 %fp(<4 x i32> %v)
  ret i32 %r
}

define i32 @main() {
entry:
  %a0 = insertelement <4 x i32> poison, i32 3, i32 0
  %a1 = insertelement <4 x i32> %a0, i32 -5, i32 1
  %a2 = insertelement <4 x i32> %a1, i32 7, i32 2
  %a3 = insertelement <4 x i32> %a2, i32 1, i32 3

  %ei = call i32 @reference_int_reduce(<4 x i32> %a3)
  %ai = call i32 @protected_int_reduce(<4 x i32> %a3)
  %ok0 = icmp eq i32 %ei, %ai

  %fa = sitofp <4 x i32> %a3 to <4 x float>
  %ef = call i32 @reference_fp_reduce(<4 x float> %fa)
  %af = call i32 @protected_fp_reduce(<4 x float> %fa)
  %ok1 = icmp eq i32 %ef, %af

  %el = call i32 @reference_loop_reduce(ptr @chunks, i32 8)
  %al = call i32 @protected_loop_reduce(ptr @chunks, i32 8)
  %ok2 = icmp eq i32 %el, %al

  %t0 = and i1 %ok0, %ok1
  %ok = and i1 %t0, %ok2
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP-DAG: Skipping VMP on unsupported_reduce_scalable: unsupported vector reduce instruction
; SKIP-DAG: Skipping VMP on unsupported_reduce_half: unsupported target feature
; SKIP-DAG: Skipping VMP on unsupported_reduce_wrong_signature: unsupported vector reduce instruction
; SKIP-DAG: Skipping VMP on unsupported_reduce_family: unsupported vector reduce instruction
; SKIP-NOT: Skipping VMP on protected_indirect_vector_call:
; SKIP-NOT: Skipping VMP on protected_loop_reduce:
; SKIP-NOT: Skipping VMP on protected_int_reduce:
; SKIP-NOT: Skipping VMP on protected_fp_reduce:
; Constant-only wide / i3 reduces can be folded before VMP under default<O2>.
; SKIP-O0-DAG: Skipping VMP on unsupported_reduce_wide: unsupported vector reduce instruction
; SKIP-O0-DAG: Skipping VMP on unsupported_reduce_wrong_elt: unsupported vector reduce instruction

; VIRT-LABEL: define i32 @protected_loop_reduce(
; VIRT: vmp.dispatch:
; VIRT: call i32 @llvm.vector.reduce.add.v4i32(

; VIRT-LABEL: define i32 @protected_int_reduce(
; VIRT: vmp.dispatch:
; VIRT-DAG: call i32 @llvm.vector.reduce.add.v4i32(
; VIRT-DAG: call i32 @llvm.vector.reduce.mul.v4i32(
; VIRT-DAG: call i32 @llvm.vector.reduce.and.v4i32(
; VIRT-DAG: call i32 @llvm.vector.reduce.or.v4i32(
; VIRT-DAG: call i32 @llvm.vector.reduce.xor.v4i32(
; VIRT-DAG: call i32 @llvm.vector.reduce.smin.v4i32(
; VIRT-DAG: call i32 @llvm.vector.reduce.smax.v4i32(
; VIRT-DAG: call i32 @llvm.vector.reduce.umin.v4i32(
; VIRT-DAG: call i32 @llvm.vector.reduce.umax.v4i32(
; VIRT-DAG: call i16 @llvm.vector.reduce.smin.v8i16(
; VIRT-DAG: call i8 @llvm.vector.reduce.add.v16i8(
; VIRT-DAG: call i64 @llvm.vector.reduce.add.v2i64(
; VIRT-DAG: call i1 @llvm.vector.reduce.or.v4i1(
; VIRT-DAG: call i1 @llvm.vector.reduce.and.v4i1(
; VIRT-DAG: call i1 @llvm.vector.reduce.xor.v4i1(

; VIRT-LABEL: define i32 @protected_fp_reduce(
; VIRT: vmp.dispatch:
; VIRT-DAG: call float @llvm.vector.reduce.fadd.v4f32(
; VIRT-DAG: call fast float @llvm.vector.reduce.fadd.v4f32(
; VIRT-DAG: call float @llvm.vector.reduce.fmul.v4f32(
; VIRT-DAG: call reassoc float @llvm.vector.reduce.fmul.v4f32(
; VIRT-DAG: call float @llvm.vector.reduce.fmin.v4f32(
; VIRT-DAG: call nnan ninf float @llvm.vector.reduce.fmin.v4f32(
; VIRT-DAG: call float @llvm.vector.reduce.fmax.v4f32(
; VIRT-DAG: call nsz contract float @llvm.vector.reduce.fmax.v4f32(
; VIRT-DAG: call double @llvm.vector.reduce.fadd.v2f64(
; VIRT-DAG: call double @llvm.vector.reduce.fmul.v2f64(
; VIRT-DAG: call double @llvm.vector.reduce.fmin.v2f64(
; VIRT-DAG: call double @llvm.vector.reduce.fmax.v2f64(

; VIRT-LABEL: define {{.*}} @unsupported_reduce_scalable(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_reduce_wide(
; VIRT-LABEL: define {{.*}} @unsupported_reduce_half(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_reduce_wrong_elt(
; VIRT-LABEL: define {{.*}} @unsupported_reduce_wrong_signature(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @unsupported_reduce_family(
; VIRT-NOT: vmp.dispatch
; VIRT-LABEL: define {{.*}} @protected_indirect_vector_call(
; VIRT: vmp.dispatch:
; VIRT: "hikari.vmp.virtualized"
