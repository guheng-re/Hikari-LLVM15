; Scalar AS0 integer atomicrmw incl. umin, scalar f32 atomicrmw fadd, and
; integer cmpxchg (legacy path: vmp-atomicrmw-xchg.ll).
; RUN: opt -S -verify-each -aesSeed=91 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=91 -passes='default<O2>' %s -o %t.o2.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll

target triple = "aarch64-unknown-linux-gnu"

@cell = global i32 0, align 4
@acc = global i32 0, align 4
@delta = global i32 0, align 4
@mask = global i32 0, align 4
@bits = global i32 0, align 4
@flip = global i32 0, align 4
@nandg = global i32 0, align 4
@peak = global i32 0, align 4
@trough = global i32 0, align 4
@uhi = global i32 0, align 4
@ulo = global i32 0, align 4
@fcell = global float 0.0, align 4

declare void @hikari_vmp()

; Includes signed max/min and unsigned umax/umin (all-ones vs small positives).
define i32 @reference() {
entry:
  store i32 10, ptr @cell, align 4
  %x0 = atomicrmw xchg ptr @cell, i32 20 monotonic, align 4
  %x1 = atomicrmw xchg ptr @cell, i32 30 seq_cst, align 4
  %x2 = atomicrmw volatile xchg ptr @cell, i32 40 syncscope("singlethread") acquire, align 4
  %xfinal = load i32, ptr @cell, align 4
  store i32 100, ptr @acc, align 4
  %a0 = atomicrmw add ptr @acc, i32 7 monotonic, align 4
  %a1 = atomicrmw add ptr @acc, i32 3 release, align 4
  %afinal = load i32, ptr @acc, align 4
  store i32 50, ptr @delta, align 4
  %s0 = atomicrmw sub ptr @delta, i32 8 monotonic, align 4
  %s1 = atomicrmw volatile sub ptr @delta, i32 5 release, align 4
  %sfinal = load i32, ptr @delta, align 4
  store i32 255, ptr @mask, align 4
  %n0 = atomicrmw and ptr @mask, i32 15 monotonic, align 4
  %n1 = atomicrmw volatile and ptr @mask, i32 7 acquire, align 4
  %nfinal = load i32, ptr @mask, align 4
  store i32 1, ptr @bits, align 4
  %o0 = atomicrmw or ptr @bits, i32 2 monotonic, align 4
  %o1 = atomicrmw volatile or ptr @bits, i32 4 release, align 4
  %ofinal = load i32, ptr @bits, align 4
  store i32 15, ptr @flip, align 4
  %z0 = atomicrmw xor ptr @flip, i32 3 monotonic, align 4
  %z1 = atomicrmw volatile xor ptr @flip, i32 5 seq_cst, align 4
  %zfinal = load i32, ptr @flip, align 4
  store i32 255, ptr @nandg, align 4
  %d0 = atomicrmw nand ptr @nandg, i32 15 monotonic, align 4
  %d1 = atomicrmw volatile nand ptr @nandg, i32 7 acquire, align 4
  %dfinal = load i32, ptr @nandg, align 4
  ; signed max: -20 then +5 keeps +5; then -1 leaves +5 (signed, not unsigned).
  store i32 -20, ptr @peak, align 4
  %p0 = atomicrmw max ptr @peak, i32 5 monotonic, align 4
  %p1 = atomicrmw volatile max ptr @peak, i32 -1 release, align 4
  %pfinal = load i32, ptr @peak, align 4
  ; signed min: +10 then -3 becomes -3; then +1 leaves -3 (signed).
  store i32 10, ptr @trough, align 4
  %u0 = atomicrmw min ptr @trough, i32 -3 monotonic, align 4
  %u1 = atomicrmw volatile min ptr @trough, i32 1 release, align 4
  %ufinal = load i32, ptr @trough, align 4
  ; unsigned umax: 5 then -1 (0xffffffff) becomes all-ones (unsigned, not signed).
  store i32 5, ptr @uhi, align 4
  %w0 = atomicrmw umax ptr @uhi, i32 -1 monotonic, align 4
  %w1 = atomicrmw volatile umax ptr @uhi, i32 7 release, align 4
  %wfinal = load i32, ptr @uhi, align 4
  ; unsigned umin: -1 then 7 becomes 7; then 3 becomes 3 (unsigned).
  store i32 -1, ptr @ulo, align 4
  %v0 = atomicrmw umin ptr @ulo, i32 7 monotonic, align 4
  %v1 = atomicrmw volatile umin ptr @ulo, i32 3 release, align 4
  %vfinal = load i32, ptr @ulo, align 4
  %m0 = xor i32 %x0, %x1
  %m1 = xor i32 %x2, %xfinal
  %m2 = xor i32 %a0, %a1
  %m3 = xor i32 %s0, %s1
  %m4 = xor i32 %n0, %n1
  %m5 = xor i32 %o0, %o1
  %m6 = xor i32 %z0, %z1
  %m7 = xor i32 %d0, %d1
  %m8 = xor i32 %p0, %p1
  %m9 = xor i32 %u0, %u1
  %ma = xor i32 %w0, %w1
  %mb = xor i32 %v0, %v1
  %t0 = xor i32 %m0, %m1
  %t1 = xor i32 %m2, %m3
  %t2 = xor i32 %m4, %m5
  %t3 = xor i32 %m6, %m7
  %t4 = xor i32 %m8, %m9
  %t5 = xor i32 %ma, %mb
  %t6 = xor i32 %t0, %t1
  %t7 = xor i32 %t2, %t3
  %t8 = xor i32 %t4, %t5
  %t9 = xor i32 %t6, %t7
  %ta = xor i32 %t9, %t8
  %tb = xor i32 %ta, %sfinal
  %tc = xor i32 %tb, %afinal
  %td = xor i32 %tc, %nfinal
  %te = xor i32 %td, %ofinal
  %tf = xor i32 %te, %zfinal
  %tg = xor i32 %tf, %dfinal
  %th = xor i32 %tg, %pfinal
  %ti = xor i32 %th, %ufinal
  %tj = xor i32 %ti, %wfinal
  %result = xor i32 %tj, %vfinal
  ret i32 %result
}

define i32 @protected() noinline optnone {
entry:
  call void @hikari_vmp()
  store i32 10, ptr @cell, align 4
  %x0 = atomicrmw xchg ptr @cell, i32 20 monotonic, align 4
  %x1 = atomicrmw xchg ptr @cell, i32 30 seq_cst, align 4
  %x2 = atomicrmw volatile xchg ptr @cell, i32 40 syncscope("singlethread") acquire, align 4
  %xfinal = load i32, ptr @cell, align 4
  store i32 100, ptr @acc, align 4
  %a0 = atomicrmw add ptr @acc, i32 7 monotonic, align 4
  %a1 = atomicrmw add ptr @acc, i32 3 release, align 4
  %afinal = load i32, ptr @acc, align 4
  store i32 50, ptr @delta, align 4
  %s0 = atomicrmw sub ptr @delta, i32 8 monotonic, align 4
  %s1 = atomicrmw volatile sub ptr @delta, i32 5 release, align 4
  %sfinal = load i32, ptr @delta, align 4
  store i32 255, ptr @mask, align 4
  %n0 = atomicrmw and ptr @mask, i32 15 monotonic, align 4
  %n1 = atomicrmw volatile and ptr @mask, i32 7 acquire, align 4
  %nfinal = load i32, ptr @mask, align 4
  store i32 1, ptr @bits, align 4
  %o0 = atomicrmw or ptr @bits, i32 2 monotonic, align 4
  %o1 = atomicrmw volatile or ptr @bits, i32 4 release, align 4
  %ofinal = load i32, ptr @bits, align 4
  store i32 15, ptr @flip, align 4
  %z0 = atomicrmw xor ptr @flip, i32 3 monotonic, align 4
  %z1 = atomicrmw volatile xor ptr @flip, i32 5 seq_cst, align 4
  %zfinal = load i32, ptr @flip, align 4
  store i32 255, ptr @nandg, align 4
  %d0 = atomicrmw nand ptr @nandg, i32 15 monotonic, align 4
  %d1 = atomicrmw volatile nand ptr @nandg, i32 7 acquire, align 4
  %dfinal = load i32, ptr @nandg, align 4
  store i32 -20, ptr @peak, align 4
  %p0 = atomicrmw max ptr @peak, i32 5 monotonic, align 4
  %p1 = atomicrmw volatile max ptr @peak, i32 -1 release, align 4
  %pfinal = load i32, ptr @peak, align 4
  store i32 10, ptr @trough, align 4
  %u0 = atomicrmw min ptr @trough, i32 -3 monotonic, align 4
  %u1 = atomicrmw volatile min ptr @trough, i32 1 release, align 4
  %ufinal = load i32, ptr @trough, align 4
  store i32 5, ptr @uhi, align 4
  %w0 = atomicrmw umax ptr @uhi, i32 -1 monotonic, align 4
  %w1 = atomicrmw volatile umax ptr @uhi, i32 7 release, align 4
  %wfinal = load i32, ptr @uhi, align 4
  store i32 -1, ptr @ulo, align 4
  %v0 = atomicrmw umin ptr @ulo, i32 7 monotonic, align 4
  %v1 = atomicrmw volatile umin ptr @ulo, i32 3 release, align 4
  %vfinal = load i32, ptr @ulo, align 4
  %m0 = xor i32 %x0, %x1
  %m1 = xor i32 %x2, %xfinal
  %m2 = xor i32 %a0, %a1
  %m3 = xor i32 %s0, %s1
  %m4 = xor i32 %n0, %n1
  %m5 = xor i32 %o0, %o1
  %m6 = xor i32 %z0, %z1
  %m7 = xor i32 %d0, %d1
  %m8 = xor i32 %p0, %p1
  %m9 = xor i32 %u0, %u1
  %ma = xor i32 %w0, %w1
  %mb = xor i32 %v0, %v1
  %t0 = xor i32 %m0, %m1
  %t1 = xor i32 %m2, %m3
  %t2 = xor i32 %m4, %m5
  %t3 = xor i32 %m6, %m7
  %t4 = xor i32 %m8, %m9
  %t5 = xor i32 %ma, %mb
  %t6 = xor i32 %t0, %t1
  %t7 = xor i32 %t2, %t3
  %t8 = xor i32 %t4, %t5
  %t9 = xor i32 %t6, %t7
  %ta = xor i32 %t9, %t8
  %tb = xor i32 %ta, %sfinal
  %tc = xor i32 %tb, %afinal
  %td = xor i32 %tc, %nfinal
  %te = xor i32 %td, %ofinal
  %tf = xor i32 %te, %zfinal
  %tg = xor i32 %tf, %dfinal
  %th = xor i32 %tg, %pfinal
  %ti = xor i32 %th, %ufinal
  %tj = xor i32 %ti, %wfinal
  %result = xor i32 %tj, %vfinal
  ret i32 %result
}

; Scalar f32 atomicrmw fadd is VMP-supported (re-emitted by the atomicrmw
; handler); kept here as a virtualization coverage check, not a negative.
define float @atomic_fadd() {
entry:
  call void @hikari_vmp()
  %v = atomicrmw fadd ptr @fcell, float 1.0 seq_cst, align 4
  ret float %v
}

; Integer cmpxchg is VMP-supported (extractvalue of the pair); kept here as a
; virtualization coverage check, not a negative.
define i32 @compare_exchange() {
entry:
  call void @hikari_vmp()
  %pair = cmpxchg ptr @cell, i32 0, i32 1 seq_cst seq_cst, align 4
  %v = extractvalue { i32, i1 } %pair, 0
  ret i32 %v
}

define i32 @main() {
entry:
  %e = call i32 @reference()
  %a = call i32 @protected()
  %match = icmp eq i32 %e, %a
  %code = select i1 %match, i32 0, i32 1
  ret i32 %code
}

; None of the protected/covered functions may be skipped at O0.
; SKIP-NOT: Skipping VMP on protected:
; SKIP-NOT: Skipping VMP on atomic_fadd:
; SKIP-NOT: Skipping VMP on compare_exchange:

; VIRT-LABEL: define i32 @protected(
; VIRT: vmp.dispatch:
; VIRT-DAG: atomicrmw xchg {{.*}} monotonic
; VIRT-DAG: atomicrmw xchg {{.*}} seq_cst
; VIRT-DAG: atomicrmw volatile xchg {{.*}} syncscope("singlethread") acquire
; VIRT-DAG: atomicrmw add {{.*}} monotonic
; VIRT-DAG: atomicrmw add {{.*}} release
; VIRT-DAG: atomicrmw sub {{.*}} monotonic
; VIRT-DAG: atomicrmw volatile sub {{.*}} release
; VIRT-DAG: atomicrmw and {{.*}} monotonic
; VIRT-DAG: atomicrmw volatile and {{.*}} acquire
; VIRT-DAG: atomicrmw or {{.*}} monotonic
; VIRT-DAG: atomicrmw volatile or {{.*}} release
; VIRT-DAG: atomicrmw xor {{.*}} monotonic
; VIRT-DAG: atomicrmw volatile xor {{.*}} seq_cst
; VIRT-DAG: atomicrmw nand {{.*}} monotonic
; VIRT-DAG: atomicrmw volatile nand {{.*}} acquire
; VIRT-DAG: atomicrmw max {{.*}} monotonic
; VIRT-DAG: atomicrmw volatile max {{.*}} release
; VIRT-DAG: atomicrmw min {{.*}} monotonic
; VIRT-DAG: atomicrmw volatile min {{.*}} release
; VIRT-DAG: atomicrmw umax {{.*}} monotonic
; VIRT-DAG: atomicrmw volatile umax {{.*}} release
; VIRT-DAG: atomicrmw umin {{.*}} monotonic
; VIRT-DAG: atomicrmw volatile umin {{.*}} release
; Scalar f32 atomicrmw fadd virtualizes and is re-emitted by the handler.
; VIRT-LABEL: define float @atomic_fadd(
; VIRT: vmp.dispatch:
; VIRT: atomicrmw fadd
; Integer cmpxchg virtualizes (extractvalue pair handled by the cmpxchg opcode).
; VIRT-LABEL: define i32 @compare_exchange(
; VIRT: vmp.dispatch:
; VIRT: cmpxchg
; VIRT: attributes{{.*}}"hikari.vmp.virtualized"
