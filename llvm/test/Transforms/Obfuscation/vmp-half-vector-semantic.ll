; Restricted fixed half-vector VMP: independent i128 vector VReg frame,
; total width 1..128, IEEE half elements.  Base SSA only: fadd/fsub/fmul/
; fdiv/frem/fneg, fcmp, select, phi, non-atomic load/store, bitcast,
; extractelement/insertelement, constant shufflevector, same-lane
; half↔float fpext/fptrunc, same-lane integer sitofp/uitofp/fptosi/fptoui
; (i1/i8/i16/i32/i64), and ordinary direct C calls.  FastMathFlags
; are restored.  Supported half-vector freeze uses existing VectorFreeze
; (native CreateFreeze).  Natural-width half-vector aggregate fields live
; in vmp-half-aggregate-semantic.ll.  half↔double / atomics stay
; skipped.  Listed half-vector math with last-token +fullfp16 lives in
; vmp-half-vector-math-semantic.ll.  Well-shaped half reduce without
; last-token +fullfp16 is an unsupported target feature.  Half
; expand/compress/gather/scatter are on the masked-memory surface
; (vmp-masked-expand-compress-semantic.ll,
; vmp-masked-gather-scatter-semantic.ll).
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
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o0.s7.ll > %t.o0.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o0.s7.live.ll -o %t.o0.s7.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.s7.live.ll > %t.o0.s7.host.ll
; RUN: lli -force-interpreter %t.o0.s7.host.ll
; RUN: opt -S -verify-each -aesSeed=7 -passes='default<O2>' %s -o %t.o2.s7.ll 2>%t.o2.s7.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o2.s7.err
; RUN: FileCheck %s --check-prefix=VIRT < %t.o2.s7.ll
; RUN: python3 %S/Inputs/vmp-drop-unsupported.py %t.o2.s7.ll > %t.o2.s7.live.ll
; RUN: llc -mtriple=aarch64-unknown-linux-gnu -filetype=obj %t.o2.s7.live.ll -o %t.o2.s7.o
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.s7.live.ll > %t.o2.s7.host.ll
; RUN: lli -force-interpreter %t.o2.s7.host.ll

target triple = "aarch64-unknown-linux-gnu"

declare void @hikari_vmp()
declare half @llvm.vector.reduce.fmin.v4f16(<4 x half>)
declare <4 x half> @llvm.masked.expandload.v4f16(ptr, <4 x i1>, <4 x half>)

@slot.h4 = private global <4 x half> zeroinitializer, align 8

%oddhalfvecfield = type { <3 x half> }

define i32 @fold_i16x4(<4 x i16> %v) {
entry:
  %e0 = extractelement <4 x i16> %v, i32 0
  %e1 = extractelement <4 x i16> %v, i32 1
  %e2 = extractelement <4 x i16> %v, i32 2
  %e3 = extractelement <4 x i16> %v, i32 3
  %z0 = zext i16 %e0 to i32
  %z1 = zext i16 %e1 to i32
  %z2 = zext i16 %e2 to i32
  %z3 = zext i16 %e3 to i32
  %s0 = add i32 %z0, %z1
  %s1 = add i32 %z2, %z3
  %r = xor i32 %s0, %s1
  ret i32 %r
}

define i32 @fold_halfx4(<4 x half> %v) {
entry:
  %bits = bitcast <4 x half> %v to <4 x i16>
  %r = call i32 @fold_i16x4(<4 x i16> %bits)
  ret i32 %r
}

define <4 x half> @add_half_vec(<4 x half> %a, <4 x half> %b) noinline {
entry:
  %s = fadd <4 x half> %a, %b
  ret <4 x half> %s
}

define i32 @reference_work(<4 x half> %a, <4 x half> %b, i1 %c) noinline optnone {
entry:
  %stk = alloca <4 x half>, align 8
  %sum = fadd nnan <4 x half> %a, %b
  %dif = fsub <4 x half> %sum, %a
  %prod = fmul <4 x half> %dif, %b
  %quot = fdiv <4 x half> %prod, %a
  %rem = frem <4 x half> %quot, %b
  %neg = fneg <4 x half> %rem
  %ogt = fcmp ogt <4 x half> %neg, %a
  %sel = select <4 x i1> %ogt, <4 x half> %neg, <4 x half> %a
  br i1 %c, label %left, label %right

left:
  %lp = fadd <4 x half> %sel, %a
  br label %join

right:
  %rp = fadd <4 x half> %sel, %b
  br label %join

join:
  %phi = phi <4 x half> [ %lp, %left ], [ %rp, %right ]
  store <4 x half> %phi, ptr %stk, align 8
  %ld = load <4 x half>, ptr %stk, align 8
  store <4 x half> %ld, ptr @slot.h4, align 8
  %gld = load <4 x half>, ptr @slot.h4, align 8
  %e1 = extractelement <4 x half> %gld, i32 1
  %ins = insertelement <4 x half> %gld, half %e1, i32 3
  %shf = shufflevector <4 x half> %ins, <4 x half> %b, <4 x i32> <i32 0, i32 5, i32 2, i32 7>
  %ext = fpext <4 x half> %shf to <4 x float>
  %tr = fptrunc <4 x float> %ext to <4 x half>
  %bc = bitcast <4 x half> %tr to <4 x i16>
  %back = bitcast <4 x i16> %bc to <4 x half>
  %called = call <4 x half> @add_half_vec(<4 x half> %back, <4 x half> %a)
  %mix = fadd <4 x half> %called, %back
  %r0 = call i32 @fold_halfx4(<4 x half> %mix)
  %r1 = call i32 @fold_i16x4(<4 x i16> %bc)
  %out = xor i32 %r0, %r1
  ret i32 %out
}

define i32 @protected_work(<4 x half> %a, <4 x half> %b, i1 %c) noinline optnone {
entry:
  call void @hikari_vmp()
  %stk = alloca <4 x half>, align 8
  %sum = fadd nnan <4 x half> %a, %b
  %dif = fsub <4 x half> %sum, %a
  %prod = fmul <4 x half> %dif, %b
  %quot = fdiv <4 x half> %prod, %a
  %rem = frem <4 x half> %quot, %b
  %neg = fneg <4 x half> %rem
  %ogt = fcmp ogt <4 x half> %neg, %a
  %sel = select <4 x i1> %ogt, <4 x half> %neg, <4 x half> %a
  br i1 %c, label %left, label %right

left:
  %lp = fadd <4 x half> %sel, %a
  br label %join

right:
  %rp = fadd <4 x half> %sel, %b
  br label %join

join:
  %phi = phi <4 x half> [ %lp, %left ], [ %rp, %right ]
  store <4 x half> %phi, ptr %stk, align 8
  %ld = load <4 x half>, ptr %stk, align 8
  store <4 x half> %ld, ptr @slot.h4, align 8
  %gld = load <4 x half>, ptr @slot.h4, align 8
  %e1 = extractelement <4 x half> %gld, i32 1
  %ins = insertelement <4 x half> %gld, half %e1, i32 3
  %shf = shufflevector <4 x half> %ins, <4 x half> %b, <4 x i32> <i32 0, i32 5, i32 2, i32 7>
  %ext = fpext <4 x half> %shf to <4 x float>
  %tr = fptrunc <4 x float> %ext to <4 x half>
  %bc = bitcast <4 x half> %tr to <4 x i16>
  %back = bitcast <4 x i16> %bc to <4 x half>
  %called = call <4 x half> @add_half_vec(<4 x half> %back, <4 x half> %a)
  %mix = fadd <4 x half> %called, %back
  %r0 = call i32 @fold_halfx4(<4 x half> %mix)
  %r1 = call i32 @fold_i16x4(<4 x i16> %bc)
  %out = xor i32 %r0, %r1
  ret i32 %out
}

define i32 @reference(<4 x half> %a, <4 x half> %b, i1 %c) noinline optnone {
entry:
  %r = call i32 @reference_work(<4 x half> %a, <4 x half> %b, i1 %c)
  ret i32 %r
}

define i32 @protected(<4 x half> %a, <4 x half> %b, i1 %c) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call i32 @protected_work(<4 x half> %a, <4 x half> %b, i1 %c)
  ret i32 %r
}

; Counted loop with a half-vector phi (VF=4, 128-bit <8 x half> mix).
define i32 @reference_loop(<4 x half> %a, <4 x half> %b, i32 %n) noinline optnone {
entry:
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %i.next, %loop ]
  %acc = phi <4 x half> [ %a, %entry ], [ %acc.next, %loop ]
  %acc.next = fadd <4 x half> %acc, %b
  %i.next = add i32 %i, 1
  %more = icmp slt i32 %i.next, %n
  br i1 %more, label %loop, label %done

done:
  %r = call i32 @fold_halfx4(<4 x half> %acc.next)
  ret i32 %r
}

define i32 @protected_loop(<4 x half> %a, <4 x half> %b, i32 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %i.next, %loop ]
  %acc = phi <4 x half> [ %a, %entry ], [ %acc.next, %loop ]
  %acc.next = fadd <4 x half> %acc, %b
  %i.next = add i32 %i, 1
  %more = icmp slt i32 %i.next, %n
  br i1 %more, label %loop, label %done

done:
  %r = call i32 @fold_halfx4(<4 x half> %acc.next)
  ret i32 %r
}

define <4 x half> @reference_ret(<4 x half> %a, <4 x half> %b) noinline optnone {
entry:
  %s = fadd <4 x half> %a, %b
  %t = fmul <4 x half> %s, <half 0xH4000, half 0xH4000, half 0xH4000, half 0xH4000>
  ret <4 x half> %t
}

define <4 x half> @protected_ret(<4 x half> %a, <4 x half> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %s = fadd <4 x half> %a, %b
  %t = fmul <4 x half> %s, <half 0xH4000, half 0xH4000, half 0xH4000, half 0xH4000>
  ret <4 x half> %t
}

define i32 @reference_wide(<8 x half> %a, <8 x half> %b) noinline optnone {
entry:
  %s = fadd <8 x half> %a, %b
  %lo = shufflevector <8 x half> %s, <8 x half> %b, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  %hi = shufflevector <8 x half> %s, <8 x half> %b, <4 x i32> <i32 4, i32 5, i32 6, i32 7>
  %r0 = call i32 @fold_halfx4(<4 x half> %lo)
  %r1 = call i32 @fold_halfx4(<4 x half> %hi)
  %out = xor i32 %r0, %r1
  ret i32 %out
}

define i32 @protected_wide(<8 x half> %a, <8 x half> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %s = fadd <8 x half> %a, %b
  %lo = shufflevector <8 x half> %s, <8 x half> %b, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  %hi = shufflevector <8 x half> %s, <8 x half> %b, <4 x i32> <i32 4, i32 5, i32 6, i32 7>
  %r0 = call i32 @fold_halfx4(<4 x half> %lo)
  %r1 = call i32 @fold_halfx4(<4 x half> %hi)
  %out = xor i32 %r0, %r1
  ret i32 %out
}

define <4 x i16> @make_i16x4(i16 %a, i16 %b, i16 %c, i16 %d) {
entry:
  %v0 = insertelement <4 x i16> poison, i16 %a, i32 0
  %v1 = insertelement <4 x i16> %v0, i16 %b, i32 1
  %v2 = insertelement <4 x i16> %v1, i16 %c, i32 2
  %v3 = insertelement <4 x i16> %v2, i16 %d, i32 3
  ret <4 x i16> %v3
}

define <4 x i8> @make_i8x4(i8 %a, i8 %b, i8 %c, i8 %d) {
entry:
  %v0 = insertelement <4 x i8> poison, i8 %a, i32 0
  %v1 = insertelement <4 x i8> %v0, i8 %b, i32 1
  %v2 = insertelement <4 x i8> %v1, i8 %c, i32 2
  %v3 = insertelement <4 x i8> %v2, i8 %d, i32 3
  ret <4 x i8> %v3
}

define <4 x i32> @make_i32x4(i32 %a, i32 %b, i32 %c, i32 %d) {
entry:
  %v0 = insertelement <4 x i32> poison, i32 %a, i32 0
  %v1 = insertelement <4 x i32> %v0, i32 %b, i32 1
  %v2 = insertelement <4 x i32> %v1, i32 %c, i32 2
  %v3 = insertelement <4 x i32> %v2, i32 %d, i32 3
  ret <4 x i32> %v3
}

define i32 @fold_i8x4(<4 x i8> %v) {
entry:
  %e0 = extractelement <4 x i8> %v, i32 0
  %e1 = extractelement <4 x i8> %v, i32 1
  %e2 = extractelement <4 x i8> %v, i32 2
  %e3 = extractelement <4 x i8> %v, i32 3
  %z0 = zext i8 %e0 to i32
  %z1 = zext i8 %e1 to i32
  %z2 = zext i8 %e2 to i32
  %z3 = zext i8 %e3 to i32
  %s0 = add i32 %z0, %z1
  %s1 = add i32 %z2, %z3
  %r = xor i32 %s0, %s1
  ret i32 %r
}

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

; Same-lane half↔integer conversions.  fptosi/fptoui sources are exact
; integer-valued halfs inside the destination range (no NaN / inf).
define i32 @reference_intcast(<4 x i16> %si, <4 x i16> %ui, <4 x i8> %sb, <4 x i32> %wi, <4 x half> %hs, <4 x half> %hu) noinline optnone {
entry:
  %sh = sitofp <4 x i16> %si to <4 x half>
  %uh = uitofp <4 x i16> %ui to <4 x half>
  %sbh = sitofp <4 x i8> %sb to <4 x half>
  %wih = sitofp <4 x i32> %wi to <4 x half>
  %si2 = fptosi <4 x half> %hs to <4 x i16>
  %ui2 = fptoui <4 x half> %hu to <4 x i16>
  %sb2 = fptosi <4 x half> %sbh to <4 x i8>
  %wi2 = fptosi <4 x half> %wih to <4 x i32>
  %r0 = call i32 @fold_halfx4(<4 x half> %sh)
  %r1 = call i32 @fold_halfx4(<4 x half> %uh)
  %r2 = call i32 @fold_i16x4(<4 x i16> %si2)
  %r3 = call i32 @fold_i16x4(<4 x i16> %ui2)
  %r4 = call i32 @fold_i8x4(<4 x i8> %sb2)
  %r5 = call i32 @fold_i32x4(<4 x i32> %wi2)
  %x0 = xor i32 %r0, %r1
  %x1 = xor i32 %r2, %r3
  %x2 = xor i32 %r4, %r5
  %y0 = xor i32 %x0, %x1
  %out = xor i32 %y0, %x2
  ret i32 %out
}

define i32 @protected_intcast(<4 x i16> %si, <4 x i16> %ui, <4 x i8> %sb, <4 x i32> %wi, <4 x half> %hs, <4 x half> %hu) noinline optnone {
entry:
  call void @hikari_vmp()
  %sh = sitofp <4 x i16> %si to <4 x half>
  %uh = uitofp <4 x i16> %ui to <4 x half>
  %sbh = sitofp <4 x i8> %sb to <4 x half>
  %wih = sitofp <4 x i32> %wi to <4 x half>
  %si2 = fptosi <4 x half> %hs to <4 x i16>
  %ui2 = fptoui <4 x half> %hu to <4 x i16>
  %sb2 = fptosi <4 x half> %sbh to <4 x i8>
  %wi2 = fptosi <4 x half> %wih to <4 x i32>
  %r0 = call i32 @fold_halfx4(<4 x half> %sh)
  %r1 = call i32 @fold_halfx4(<4 x half> %uh)
  %r2 = call i32 @fold_i16x4(<4 x i16> %si2)
  %r3 = call i32 @fold_i16x4(<4 x i16> %ui2)
  %r4 = call i32 @fold_i8x4(<4 x i8> %sb2)
  %r5 = call i32 @fold_i32x4(<4 x i32> %wi2)
  %x0 = xor i32 %r0, %r1
  %x1 = xor i32 %r2, %r3
  %x2 = xor i32 %r4, %r5
  %y0 = xor i32 %x0, %x1
  %out = xor i32 %y0, %x2
  ret i32 %out
}

define <4 x half> @make_h4(half %a, half %b, half %c, half %d) {
entry:
  %v0 = insertelement <4 x half> poison, half %a, i32 0
  %v1 = insertelement <4 x half> %v0, half %b, i32 1
  %v2 = insertelement <4 x half> %v1, half %c, i32 2
  %v3 = insertelement <4 x half> %v2, half %d, i32 3
  ret <4 x half> %v3
}

define <8 x half> @make_h8(<4 x half> %lo, <4 x half> %hi) {
entry:
  %r = shufflevector <4 x half> %lo, <4 x half> %hi, <8 x i32> <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7>
  ret <8 x half> %r
}

define i32 @reference_freeze(<4 x half> %v) noinline optnone {
entry:
  %f = freeze <4 x half> %v
  %s = fadd <4 x half> %f, %v
  %fs = freeze <4 x half> %s
  %r = call i32 @fold_halfx4(<4 x half> %fs)
  ret i32 %r
}

define i32 @protected_freeze(<4 x half> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %f = freeze <4 x half> %v
  %s = fadd <4 x half> %f, %v
  %fs = freeze <4 x half> %s
  %r = call i32 @fold_halfx4(<4 x half> %fs)
  ret i32 %r
}

; Virtualized but not executed: do not compare frozen undef/poison bits.
define <4 x half> @protected_half_freeze_undef() noinline optnone {
entry:
  call void @hikari_vmp()
  %v = freeze <4 x half> undef
  %s = fadd <4 x half> %v, <half 0xH3C00, half 0xH3C00, half 0xH3C00, half 0xH3C00>
  ret <4 x half> %s
}

define <4 x half> @protected_half_freeze_poison() noinline optnone {
entry:
  call void @hikari_vmp()
  %v = freeze <4 x half> poison
  %s = fadd <4 x half> %v, <half 0xH3C00, half 0xH3C00, half 0xH3C00, half 0xH3C00>
  ret <4 x half> %s
}

; ----- negatives: selected, not virtualized -----

define <4 x bfloat> @unsupported_bfloat_vector(<4 x bfloat> %a, <4 x bfloat> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %s = fadd <4 x bfloat> %a, %b
  ret <4 x bfloat> %s
}

; ppc_fp128 stays off the dedicated IEEE fp128 SSA frame.
define ppc_fp128 @unsupported_fp128(ppc_fp128 %a, ppc_fp128 %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %s = fadd ppc_fp128 %a, %b
  ret ppc_fp128 %s
}

define <vscale x 4 x half> @unsupported_scalable(<vscale x 4 x half> %a, <vscale x 4 x half> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %s = fadd <vscale x 4 x half> %a, %b
  ret <vscale x 4 x half> %s
}

define <2 x ptr> @unsupported_ptrvec(<2 x ptr> %a, <2 x ptr> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %c = icmp eq <2 x ptr> %a, %b
  %z = select <2 x i1> %c, <2 x ptr> %a, <2 x ptr> %b
  ret <2 x ptr> %z
}

define <16 x half> @unsupported_wide_half(<16 x half> %a, <16 x half> %b) noinline optnone {
entry:
  call void @hikari_vmp()
  %s = fadd <16 x half> %a, %b
  ret <16 x half> %s
}

define i32 @unsupported_half_atomic(ptr %p) noinline optnone {
entry:
  call void @hikari_vmp()
  %v = load atomic half, ptr %p seq_cst, align 2
  %b = bitcast half %v to i16
  %z = zext i16 %b to i32
  ret i32 %z
}

define i32 @unsupported_wide_half_freeze() noinline optnone {
entry:
  call void @hikari_vmp()
  %f = freeze <16 x half> zeroinitializer
  ret i32 0
}

; Well-shaped half fmin reduce without last-token +fullfp16.
define i32 @unsupported_reduce_half() noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call half @llvm.vector.reduce.fmin.v4f16(<4 x half> zeroinitializer)
  ret i32 0
}

; Half expandload is accepted on the masked-memory surface.
define i32 @protected_masked_half(ptr %p, <4 x i1> %m) noinline optnone {
entry:
  call void @hikari_vmp()
  %r = call <4 x half> @llvm.masked.expandload.v4f16(ptr %p, <4 x i1> %m, <4 x half> zeroinitializer)
  %e = extractelement <4 x half> %r, i32 0
  %b = bitcast half %e to i16
  %z = zext i16 %b to i32
  ret i32 %z
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

define i32 @unsupported_sitofp_bfloat(<4 x i16> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %h = sitofp <4 x i16> %v to <4 x bfloat>
  %e = extractelement <4 x bfloat> %h, i32 0
  %f = fpext bfloat %e to float
  %b = bitcast float %f to i32
  ret i32 %b
}

; <3 x half> is a supported vector but not a 8/16/32/64/128-bit field.
define i32 @unsupported_agg_half_field(<3 x half> %v) noinline optnone {
entry:
  call void @hikari_vmp()
  %n = insertvalue %oddhalfvecfield poison, <3 x half> %v, 0
  %h = extractvalue %oddhalfvecfield %n, 0
  %e = extractelement <3 x half> %h, i32 0
  %b = bitcast half %e to i16
  %z = zext i16 %b to i32
  ret i32 %z
}

define i32 @main() {
entry:
  ; 1.0, 2.0, 3.0, 0.5 and 2.0, 0.5, 1.0, 4.0
  %a = call <4 x half> @make_h4(half 0xH3C00, half 0xH4000, half 0xH4200, half 0xH3800)
  %b = call <4 x half> @make_h4(half 0xH4000, half 0xH3800, half 0xH3C00, half 0xH4400)
  %e0 = call i32 @reference(<4 x half> %a, <4 x half> %b, i1 true)
  %p0 = call i32 @protected(<4 x half> %a, <4 x half> %b, i1 true)
  %ok0 = icmp eq i32 %e0, %p0
  %e1 = call i32 @reference(<4 x half> %b, <4 x half> %a, i1 false)
  %p1 = call i32 @protected(<4 x half> %b, <4 x half> %a, i1 false)
  %ok1 = icmp eq i32 %e1, %p1
  %el = call i32 @reference_loop(<4 x half> %a, <4 x half> %b, i32 3)
  %pl = call i32 @protected_loop(<4 x half> %a, <4 x half> %b, i32 3)
  %ok2 = icmp eq i32 %el, %pl
  %er = call <4 x half> @reference_ret(<4 x half> %a, <4 x half> %b)
  %pr = call <4 x half> @protected_ret(<4 x half> %a, <4 x half> %b)
  %fr = call i32 @fold_halfx4(<4 x half> %er)
  %fpr = call i32 @fold_halfx4(<4 x half> %pr)
  %ok3 = icmp eq i32 %fr, %fpr
  %aw = call <8 x half> @make_h8(<4 x half> %a, <4 x half> %b)
  %bw = call <8 x half> @make_h8(<4 x half> %b, <4 x half> %a)
  %ew = call i32 @reference_wide(<8 x half> %aw, <8 x half> %bw)
  %pw = call i32 @protected_wide(<8 x half> %aw, <8 x half> %bw)
  %ok4 = icmp eq i32 %ew, %pw
  ; sitofp signed: -3,-1,0,2 ; uitofp: 0,1,4,7 ; i8 signed: -8,-1,0,5
  ; i32 signed: -4,-1,0,6.  fptosi halfs: -2,-1,0,3 ; fptoui: 0,1,2,4.
  %si = call <4 x i16> @make_i16x4(i16 -3, i16 -1, i16 0, i16 2)
  %ui = call <4 x i16> @make_i16x4(i16 0, i16 1, i16 4, i16 7)
  %sb = call <4 x i8> @make_i8x4(i8 -8, i8 -1, i8 0, i8 5)
  %wi = call <4 x i32> @make_i32x4(i32 -4, i32 -1, i32 0, i32 6)
  %hs = call <4 x half> @make_h4(half 0xHC000, half 0xHBC00, half 0xH0000, half 0xH4200)
  %hu = call <4 x half> @make_h4(half 0xH0000, half 0xH3C00, half 0xH4000, half 0xH4400)
  %ec = call i32 @reference_intcast(<4 x i16> %si, <4 x i16> %ui, <4 x i8> %sb, <4 x i32> %wi, <4 x half> %hs, <4 x half> %hu)
  %pc = call i32 @protected_intcast(<4 x i16> %si, <4 x i16> %ui, <4 x i8> %sb, <4 x i32> %wi, <4 x half> %hs, <4 x half> %hu)
  %ok5 = icmp eq i32 %ec, %pc
  %ef = call i32 @reference_freeze(<4 x half> %a)
  %pf = call i32 @protected_freeze(<4 x half> %a)
  %ok6 = icmp eq i32 %ef, %pf
  %t0 = and i1 %ok0, %ok1
  %t1 = and i1 %ok2, %ok3
  %t2 = and i1 %t0, %t1
  %t3 = and i1 %ok4, %ok5
  %t4 = and i1 %t2, %t3
  %ok = and i1 %t4, %ok6
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP-DAG: Skipping VMP on unsupported_bfloat_vector:
; SKIP-DAG: Skipping VMP on unsupported_fp128:
; SKIP-DAG: Skipping VMP on unsupported_scalable:
; SKIP-DAG: Skipping VMP on unsupported_ptrvec:
; SKIP-DAG: Skipping VMP on unsupported_wide_half:
; SKIP-DAG: Skipping VMP on unsupported_half_atomic: unsupported float load instruction
; SKIP-DAG: Skipping VMP on unsupported_wide_half_freeze: unsupported freeze instruction
; SKIP-DAG: Skipping VMP on unsupported_reduce_half: unsupported target feature
; SKIP-NOT: Skipping VMP on protected_masked_half:
; SKIP-DAG: Skipping VMP on unsupported_cast_half_double: unsupported vector cast instruction
; SKIP-DAG: Skipping VMP on unsupported_sitofp_bfloat: unsupported vector cast instruction
; SKIP-DAG: Skipping VMP on unsupported_agg_half_field: unsupported aggregate instruction
; SKIP-NOT: Skipping VMP on protected:
; SKIP-NOT: Skipping VMP on protected_work:
; SKIP-NOT: Skipping VMP on protected_loop:
; SKIP-NOT: Skipping VMP on protected_ret:
; SKIP-NOT: Skipping VMP on protected_wide:
; SKIP-NOT: Skipping VMP on protected_intcast:
; SKIP-NOT: Skipping VMP on protected_freeze:
; SKIP-NOT: Skipping VMP on protected_half_freeze_undef:
; SKIP-NOT: Skipping VMP on protected_half_freeze_poison:
; SKIP-NOT: Skipping VMP on reference:
; SKIP-NOT: Skipping VMP on reference_work:
; SKIP-NOT: Skipping VMP on add_half_vec:

; VIRT-LABEL: define i32 @reference_work(
; VIRT-NOT: vmp.dispatch

; VIRT-LABEL: define i32 @protected_work(
; VIRT: %vmp.vregs = alloca
; VIRT: vmp.dispatch:
; VIRT-DAG: fadd{{.*}} <4 x half>
; VIRT-DAG: fsub <4 x half>
; VIRT-DAG: fmul <4 x half>
; VIRT-DAG: fdiv <4 x half>
; VIRT-DAG: frem <4 x half>
; VIRT-DAG: fneg <4 x half>
; VIRT-DAG: fcmp ogt <4 x half>
; VIRT-DAG: select <4 x i1>
; VIRT-DAG: store{{.*}} <4 x half>
; VIRT-DAG: load <4 x half>
; VIRT-DAG: extractelement <4 x half>
; VIRT-DAG: insertelement <4 x half>
; VIRT-DAG: shufflevector <4 x half>
; VIRT-DAG: fpext <4 x half> {{.*}} to <4 x float>
; VIRT-DAG: fptrunc <4 x float> {{.*}} to <4 x half>
; VIRT-DAG: bitcast <4 x half> {{.*}} to <4 x i16>
; VIRT-DAG: call <4 x half> @add_half_vec(

; VIRT-LABEL: define i32 @protected_loop(
; VIRT: vmp.dispatch:
; VIRT-DAG: fadd <4 x half>

; VIRT-LABEL: define <4 x half> @protected_ret(
; VIRT: %vmp.vregs = alloca
; VIRT: vmp.dispatch:

; VIRT-LABEL: define i32 @protected_wide(
; VIRT: vmp.dispatch:
; VIRT-DAG: fadd <8 x half>

; VIRT-LABEL: define i32 @protected_intcast(
; VIRT: vmp.dispatch:
; VIRT-DAG: sitofp <4 x i16> {{.*}} to <4 x half>
; VIRT-DAG: uitofp <4 x i16> {{.*}} to <4 x half>
; VIRT-DAG: sitofp <4 x i8> {{.*}} to <4 x half>
; VIRT-DAG: sitofp <4 x i32> {{.*}} to <4 x half>
; VIRT-DAG: fptosi <4 x half> {{.*}} to <4 x i16>
; VIRT-DAG: fptoui <4 x half> {{.*}} to <4 x i16>
; VIRT-DAG: fptosi <4 x half> {{.*}} to <4 x i8>
; VIRT-DAG: fptosi <4 x half> {{.*}} to <4 x i32>

; VIRT-LABEL: define i32 @protected_freeze(
; VIRT: vmp.dispatch:
; VIRT-DAG: freeze <4 x half>
; VIRT-DAG: fadd <4 x half>

; VIRT-LABEL: define <4 x half> @protected_half_freeze_undef(
; VIRT: vmp.dispatch:
; VIRT-DAG: freeze <4 x half> undef
; VIRT-DAG: fadd <4 x half>

; VIRT-LABEL: define <4 x half> @protected_half_freeze_poison(
; VIRT: vmp.dispatch:
; VIRT-DAG: freeze <4 x half> poison
; VIRT-DAG: fadd <4 x half>

; VIRT: define {{.*}} @unsupported_bfloat_vector({{.*}} #[[UNSUPATTR:[0-9]+]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_fp128({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_scalable({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_ptrvec({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_wide_half({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_half_atomic({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_wide_half_freeze({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_reduce_half({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @protected_masked_half({{.*}}
; VIRT: vmp.dispatch:
; VIRT: call <4 x half> @llvm.masked.expandload.v4f16(
; VIRT: define {{.*}} @unsupported_cast_half_double({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_sitofp_bfloat({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: define {{.*}} @unsupported_agg_half_field({{.*}} #[[UNSUPATTR]] {
; VIRT-NOT: vmp.dispatch
; VIRT: attributes #{{[0-9]+}} = { {{.*}}"hikari.vmp.virtualized"{{.*}} }
; VIRT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.selected"{{.*}} }
; VIRT-NOT: attributes #[[UNSUPATTR]] = { {{.*}}"hikari.vmp.virtualized"
