; Fixed-vector VMP: independent i128 vector VReg frame, 1..128 bits,
; elements i1/i8/i16/i32/i64/f32/f64 (half vectors live in
; vmp-half-vector-semantic.ll).  reference vs protected host lli
; parity over integer/float arith, masks, phi/select, extract/insert,
; constant shuffle, stack memory, direct calls, and vector args/returns.
;
; RUN: opt -S -verify-each -aesSeed=97 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
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
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.s7.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()

@slot.i32x4 = private global <4 x i32> zeroinitializer
@slot.f32x4 = private global <4 x float> zeroinitializer

define <4 x i32> @vec_i32_combine(<4 x i32> %a, <4 x i32> %b) noinline {
entry:
  %s = add <4 x i32> %a, %b
  %t = mul <4 x i32> %s, <i32 2, i32 2, i32 2, i32 2>
  ret <4 x i32> %t
}

define <4 x float> @vec_f32_combine(<4 x float> %a, <4 x float> %b) noinline {
entry:
  %s = fadd <4 x float> %a, %b
  %t = fmul <4 x float> %s, <float 2.000000e+00, float 2.000000e+00, float 2.000000e+00, float 2.000000e+00>
  ret <4 x float> %t
}

define void @vec_i32_sink(<4 x i32> %v) noinline {
entry:
  store volatile <4 x i32> %v, ptr @slot.i32x4, align 16
  ret void
}

; Fold a <4 x i32> into i32 so lli can compare a single exit code.
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

define i32 @fold_f32x4(<4 x float> %v) {
entry:
  %bits = bitcast <4 x float> %v to <4 x i32>
  %r = call i32 @fold_i32x4(<4 x i32> %bits)
  ret i32 %r
}

define i32 @reference_int(<4 x i32> %a, <4 x i32> %b) noinline optnone {
entry:
  %add = add <4 x i32> %a, %b
  %sub = sub <4 x i32> %add, %b
  %mul = mul <4 x i32> %sub, <i32 3, i32 5, i32 7, i32 9>
  %and = and <4 x i32> %mul, %a
  %or  = or  <4 x i32> %and, %b
  %xor = xor <4 x i32> %or, %add
  %shl = shl <4 x i32> %xor, <i32 1, i32 1, i32 1, i32 1>
  %lsh = lshr <4 x i32> %shl, <i32 1, i32 1, i32 1, i32 1>
  %ash = ashr <4 x i32> %lsh, <i32 0, i32 0, i32 0, i32 0>
  %eq  = icmp eq <4 x i32> %ash, %a
  %sel = select <4 x i1> %eq, <4 x i32> %ash, <4 x i32> %b
  %cmp = icmp slt <4 x i32> %a, %b
  %one = insertelement <4 x i32> %sel, i32 1, i32 0
  %ext = extractelement <4 x i32> %one, i32 2
  %ins = insertelement <4 x i32> %one, i32 %ext, i32 3
  %shf = shufflevector <4 x i32> %ins, <4 x i32> %b, <4 x i32> <i32 0, i32 5, i32 2, i32 7>
  %stk = alloca <4 x i32>, align 16
  store volatile <4 x i32> %shf, ptr %stk, align 16
  %ld  = load volatile <4 x i32>, ptr %stk, align 16
  %sc  = icmp sgt i32 %ext, 0
  %phs = select i1 %sc, <4 x i32> %ld, <4 x i32> %a
  %called = call <4 x i32> @vec_i32_combine(<4 x i32> %phs, <4 x i32> %b)
  call void @vec_i32_sink(<4 x i32> %called)
  %r = call i32 @fold_i32x4(<4 x i32> %called)
  %c0 = extractelement <4 x i1> %cmp, i32 0
  %c1 = extractelement <4 x i1> %cmp, i32 1
  %c2 = extractelement <4 x i1> %cmp, i32 2
  %c3 = extractelement <4 x i1> %cmp, i32 3
  %z0 = zext i1 %c0 to i32
  %z1 = zext i1 %c1 to i32
  %z2 = zext i1 %c2 to i32
  %z3 = zext i1 %c3 to i32
  %zm0 = add i32 %z0, %z1
  %zm1 = add i32 %z2, %z3
  %zm = xor i32 %zm0, %zm1
  %out = xor i32 %r, %zm
  ret i32 %out
}

define i32 @protected_int(<4 x i32> %a, <4 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %add = add <4 x i32> %a, %b
  %sub = sub <4 x i32> %add, %b
  %mul = mul <4 x i32> %sub, <i32 3, i32 5, i32 7, i32 9>
  %and = and <4 x i32> %mul, %a
  %or  = or  <4 x i32> %and, %b
  %xor = xor <4 x i32> %or, %add
  %shl = shl <4 x i32> %xor, <i32 1, i32 1, i32 1, i32 1>
  %lsh = lshr <4 x i32> %shl, <i32 1, i32 1, i32 1, i32 1>
  %ash = ashr <4 x i32> %lsh, <i32 0, i32 0, i32 0, i32 0>
  %eq  = icmp eq <4 x i32> %ash, %a
  %sel = select <4 x i1> %eq, <4 x i32> %ash, <4 x i32> %b
  %cmp = icmp slt <4 x i32> %a, %b
  %one = insertelement <4 x i32> %sel, i32 1, i32 0
  %ext = extractelement <4 x i32> %one, i32 2
  %ins = insertelement <4 x i32> %one, i32 %ext, i32 3
  %shf = shufflevector <4 x i32> %ins, <4 x i32> %b, <4 x i32> <i32 0, i32 5, i32 2, i32 7>
  %stk = alloca <4 x i32>, align 16
  store volatile <4 x i32> %shf, ptr %stk, align 16
  %ld  = load volatile <4 x i32>, ptr %stk, align 16
  %sc  = icmp sgt i32 %ext, 0
  %phs = select i1 %sc, <4 x i32> %ld, <4 x i32> %a
  %called = call <4 x i32> @vec_i32_combine(<4 x i32> %phs, <4 x i32> %b)
  call void @vec_i32_sink(<4 x i32> %called)
  %r = call i32 @fold_i32x4(<4 x i32> %called)
  %c0 = extractelement <4 x i1> %cmp, i32 0
  %c1 = extractelement <4 x i1> %cmp, i32 1
  %c2 = extractelement <4 x i1> %cmp, i32 2
  %c3 = extractelement <4 x i1> %cmp, i32 3
  %z0 = zext i1 %c0 to i32
  %z1 = zext i1 %c1 to i32
  %z2 = zext i1 %c2 to i32
  %z3 = zext i1 %c3 to i32
  %zm0 = add i32 %z0, %z1
  %zm1 = add i32 %z2, %z3
  %zm = xor i32 %zm0, %zm1
  %out = xor i32 %r, %zm
  ret i32 %out
}

define i32 @reference_fp(<4 x float> %a, <4 x float> %b) noinline optnone {
entry:
  %add = fadd <4 x float> %a, %b
  %sub = fsub <4 x float> %add, %b
  %mul = fmul <4 x float> %sub, <float 2.000000e+00, float 3.000000e+00, float 4.000000e+00, float 5.000000e+00>
  %div = fdiv <4 x float> %mul, <float 1.000000e+00, float 1.000000e+00, float 2.000000e+00, float 4.000000e+00>
  %rem = frem <4 x float> %div, <float 8.000000e+00, float 8.000000e+00, float 8.000000e+00, float 8.000000e+00>
  %neg = fneg <4 x float> %rem
  %fc  = fcmp olt <4 x float> %a, %b
  %sel = select <4 x i1> %fc, <4 x float> %neg, <4 x float> %b
  %bc  = bitcast <4 x float> %sel to <4 x i32>
  %ia  = fptosi <4 x float> %a to <4 x i32>
  %si  = sitofp <4 x i32> %ia to <4 x float>
  %mix = fadd <4 x float> %si, %sel
  %called = call <4 x float> @vec_f32_combine(<4 x float> %mix, <4 x float> %b)
  store volatile <4 x float> %called, ptr @slot.f32x4, align 16
  %r = call i32 @fold_f32x4(<4 x float> %called)
  %rb = call i32 @fold_i32x4(<4 x i32> %bc)
  %out = xor i32 %r, %rb
  ret i32 %out
}

define i32 @protected_fp(<4 x float> %a, <4 x float> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %add = fadd <4 x float> %a, %b
  %sub = fsub <4 x float> %add, %b
  %mul = fmul <4 x float> %sub, <float 2.000000e+00, float 3.000000e+00, float 4.000000e+00, float 5.000000e+00>
  %div = fdiv <4 x float> %mul, <float 1.000000e+00, float 1.000000e+00, float 2.000000e+00, float 4.000000e+00>
  %rem = frem <4 x float> %div, <float 8.000000e+00, float 8.000000e+00, float 8.000000e+00, float 8.000000e+00>
  %neg = fneg <4 x float> %rem
  %fc  = fcmp olt <4 x float> %a, %b
  %sel = select <4 x i1> %fc, <4 x float> %neg, <4 x float> %b
  %bc  = bitcast <4 x float> %sel to <4 x i32>
  %ia  = fptosi <4 x float> %a to <4 x i32>
  %si  = sitofp <4 x i32> %ia to <4 x float>
  %mix = fadd <4 x float> %si, %sel
  %called = call <4 x float> @vec_f32_combine(<4 x float> %mix, <4 x float> %b)
  store volatile <4 x float> %called, ptr @slot.f32x4, align 16
  %r = call i32 @fold_f32x4(<4 x float> %called)
  %rb = call i32 @fold_i32x4(<4 x i32> %bc)
  %out = xor i32 %r, %rb
  ret i32 %out
}

; Vector-returning virtualized function: args and return stay on the vector frame.
define <4 x i32> @reference_ret(<4 x i32> %a, <4 x i32> %b) noinline optnone {
entry:
  %s = add <4 x i32> %a, %b
  %t = xor <4 x i32> %s, <i32 1, i32 2, i32 3, i32 4>
  ret <4 x i32> %t
}

define <4 x i32> @protected_ret(<4 x i32> %a, <4 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %s = add <4 x i32> %a, %b
  %t = xor <4 x i32> %s, <i32 1, i32 2, i32 3, i32 4>
  ret <4 x i32> %t
}

define i32 @reference_phi(<4 x i32> %a, <4 x i32> %b, i32 %k) noinline optnone {
entry:
  %pos = icmp sgt i32 %k, 0
  br i1 %pos, label %left, label %right

left:
  %lv = add <4 x i32> %a, %b
  br label %join

right:
  %rv = sub <4 x i32> %a, %b
  br label %join

join:
  %p = phi <4 x i32> [ %lv, %left ], [ %rv, %right ]
  %r = call i32 @fold_i32x4(<4 x i32> %p)
  ret i32 %r
}

define i32 @protected_phi(<4 x i32> %a, <4 x i32> %b, i32 %k) noinline optnone {
entry:
  call void @hikari_vmp()
  %pos = icmp sgt i32 %k, 0
  br i1 %pos, label %left, label %right

left:
  %lv = add <4 x i32> %a, %b
  br label %join

right:
  %rv = sub <4 x i32> %a, %b
  br label %join

join:
  %p = phi <4 x i32> [ %lv, %left ], [ %rv, %right ]
  %r = call i32 @fold_i32x4(<4 x i32> %p)
  ret i32 %r
}

; Same-width integer <-> vector bitcast (<2 x i32> <-> i64).
define i32 @reference_bits(i64 %x) noinline optnone {
entry:
  %v = bitcast i64 %x to <2 x i32>
  %a = add <2 x i32> %v, <i32 1, i32 2>
  %y = bitcast <2 x i32> %a to i64
  %lo = trunc i64 %y to i32
  %hi = lshr i64 %y, 32
  %hi32 = trunc i64 %hi to i32
  %r = xor i32 %lo, %hi32
  ret i32 %r
}

define i32 @protected_bits(i64 %x) noinline optnone {
entry:
  call void @hikari_vmp()
  %v = bitcast i64 %x to <2 x i32>
  %a = add <2 x i32> %v, <i32 1, i32 2>
  %y = bitcast <2 x i32> %a to i64
  %lo = trunc i64 %y to i32
  %hi = lshr i64 %y, 32
  %hi32 = trunc i64 %hi to i32
  %r = xor i32 %lo, %hi32
  ret i32 %r
}

; ----- negatives: selected, not virtualized -----

define <vscale x 4 x i32> @unsupported_scalable(<vscale x 4 x i32> %a, <vscale x 4 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %s = add <vscale x 4 x i32> %a, %b
  ret <vscale x 4 x i32> %s
}

define <8 x i32> @unsupported_wide_vector(<8 x i32> %a, <8 x i32> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %s = add <8 x i32> %a, %b
  ret <8 x i32> %s
}

define <2 x ptr> @unsupported_vector_ptr(<2 x ptr> %a, <2 x ptr> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %c = icmp eq <2 x ptr> %a, %b
  %z = select <2 x i1> %c, <2 x ptr> %a, <2 x ptr> %b
  ret <2 x ptr> %z
}

define <4 x bfloat> @unsupported_bfloat_vector(<4 x bfloat> %a, <4 x bfloat> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %s = fadd <4 x bfloat> %a, %b
  ret <4 x bfloat> %s
}

; >128-bit indirect vector stays out of the restricted indirect subset
; (legal 1..128 fixed-vector indirect calls live in
; vmp-indirect-call-vector-semantic.ll).
define <8 x i32> @unsupported_indirect_vector_call(ptr %fp, <8 x i32> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i32> %fp(<8 x i32> %v)
  ret <8 x i32> %r
}

; Dynamic table lookup with a non-i8 anyvector instantiation.  Legal
; <8 x i8>/<16 x i8> tbl/tbx live in
; vmp-aarch64-neon-tbl-tbx-semantic.ll; this file keeps a non-i8 tbl
; reject (not a constant-mask shufflevector).
declare <8 x i16> @llvm.aarch64.neon.tbl1.v8i16(<16 x i8>, <8 x i16>)

define <8 x i16> @unsupported_dynamic_shuffle(<16 x i8> %a, <8 x i16> %idx) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <8 x i16> @llvm.aarch64.neon.tbl1.v8i16(<16 x i8> %a, <8 x i16> %idx)
  ret <8 x i16> %r
}

; LLVM 15 forbids atomicrmw/load/store of vector types (verifier requires
; integer/fp/ptr).  A 128-bit integer xchg is the legal stand-in for a
; vector-width atomic and is rejected as an unsupported register type.
define i128 @unsupported_vector_atomic(ptr %p, i128 %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = atomicrmw xchg ptr %p, i128 %v monotonic
  ret i128 %r
}

define i32 @main() {
entry:
  %a = insertelement <4 x i32> poison, i32 1, i32 0
  %a1 = insertelement <4 x i32> %a, i32 2, i32 1
  %a2 = insertelement <4 x i32> %a1, i32 3, i32 2
  %a3 = insertelement <4 x i32> %a2, i32 4, i32 3
  %b = insertelement <4 x i32> poison, i32 5, i32 0
  %b1 = insertelement <4 x i32> %b, i32 6, i32 1
  %b2 = insertelement <4 x i32> %b1, i32 7, i32 2
  %b3 = insertelement <4 x i32> %b2, i32 8, i32 3
  %ei = call i32 @reference_int(<4 x i32> %a3, <4 x i32> %b3)
  %ai = call i32 @protected_int(<4 x i32> %a3, <4 x i32> %b3)
  %ok0 = icmp eq i32 %ei, %ai

  %fa = sitofp <4 x i32> %a3 to <4 x float>
  %fb = sitofp <4 x i32> %b3 to <4 x float>
  %ef = call i32 @reference_fp(<4 x float> %fa, <4 x float> %fb)
  %af = call i32 @protected_fp(<4 x float> %fa, <4 x float> %fb)
  %ok1 = icmp eq i32 %ef, %af

  %er = call <4 x i32> @reference_ret(<4 x i32> %a3, <4 x i32> %b3)
  %ar = call <4 x i32> @protected_ret(<4 x i32> %a3, <4 x i32> %b3)
  %fr = call i32 @fold_i32x4(<4 x i32> %er)
  %far = call i32 @fold_i32x4(<4 x i32> %ar)
  %ok2 = icmp eq i32 %fr, %far

  %ep = call i32 @reference_phi(<4 x i32> %a3, <4 x i32> %b3, i32 1)
  %ap = call i32 @protected_phi(<4 x i32> %a3, <4 x i32> %b3, i32 1)
  %ok3 = icmp eq i32 %ep, %ap
  %en = call i32 @reference_phi(<4 x i32> %a3, <4 x i32> %b3, i32 -1)
  %an = call i32 @protected_phi(<4 x i32> %a3, <4 x i32> %b3, i32 -1)
  %ok4 = icmp eq i32 %en, %an

  %eb = call i32 @reference_bits(i64 1234567890123)
  %ab = call i32 @protected_bits(i64 1234567890123)
  %ok5 = icmp eq i32 %eb, %ab

  %t0 = and i1 %ok0, %ok1
  %t1 = and i1 %ok2, %ok3
  %t2 = and i1 %ok4, %ok5
  %t3 = and i1 %t0, %t1
  %ok = and i1 %t3, %t2
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with:
; SKIP-DAG: Skipping VMP on unsupported_scalable:
; SKIP-DAG: Skipping VMP on unsupported_wide_vector:
; SKIP-DAG: Skipping VMP on unsupported_vector_ptr:
; SKIP-DAG: Skipping VMP on unsupported_bfloat_vector:
; SKIP-DAG: Skipping VMP on unsupported_indirect_vector_call:
; SKIP-DAG: Skipping VMP on unsupported_dynamic_shuffle:
; SKIP-DAG: Skipping VMP on unsupported_vector_atomic:
; SKIP-NOT: Skipping VMP on protected_int:
; SKIP-NOT: Skipping VMP on protected_fp:
; SKIP-NOT: Skipping VMP on protected_ret:
; SKIP-NOT: Skipping VMP on protected_phi:
; SKIP-NOT: Skipping VMP on protected_bits:

; VIRT: @__hikari_vmp_bc = private unnamed_addr constant
; VIRT: define i32 @protected_int({{.*}} {
; VIRT: %vmp.vregs = alloca [{{[0-9]+}} x i128]
; VIRT: store volatile i128
; VIRT: vmp.dispatch:
; VIRT: load volatile i128
; VIRT: define i32 @protected_fp({{.*}} {
; VIRT: %vmp.vregs = alloca [{{[0-9]+}} x i128]
; VIRT: store volatile i128
; VIRT: vmp.dispatch:
; VIRT: load volatile i128
; VIRT: define <4 x i32> @protected_ret({{.*}} {
; VIRT: %vmp.vregs = alloca [{{[0-9]+}} x i128]
; VIRT: store volatile i128
; VIRT: vmp.dispatch:
; VIRT: load volatile i128
; VIRT: define i32 @protected_phi({{.*}} {
; VIRT: %vmp.vregs = alloca [{{[0-9]+}} x i128]
; VIRT: store volatile i128
; VIRT: vmp.dispatch:
; VIRT: load volatile i128
; VIRT: define i32 @protected_bits({{.*}} {
; VIRT: %vmp.vregs = alloca [{{[0-9]+}} x i128]
; VIRT: store volatile i128
; VIRT: vmp.dispatch:
; VIRT: load volatile i128
; VIRT: define {{.*}} @unsupported_scalable({{.*}} #[[UNSUPATTR:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_wide_vector({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_vector_ptr({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_bfloat_vector({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_indirect_vector_call({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_dynamic_shuffle({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_vector_atomic({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #{{[0-9]+}} = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.virtualized"
