; Scalar AS0 float atomicrmw fadd/fsub/fmax/fmin (float VReg frame).
; Double fadd/fsub/fmax/fmin coverage lives in vmp-atomicrmw-double-semantic.ll.
; RUN: opt -S -verify-each -aesSeed=93 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=93 -passes='default<O2>' %s -o %t.o2.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll

target triple = "aarch64-unknown-linux-gnu"

@fadd_cell = global float 0.0, align 4
@fsub_cell = global float 0.0, align 4
@fmax_cell = global float 0.0, align 4
@fmin_cell = global float 0.0, align 4
@as1_cell = addrspace(1) global float 0.0, align 4

declare void @hikari_vmp()

; fadd: old values + final cell mixed into comparable i32 bits.
define i32 @reference_fadd() {
entry:
  store float 1.000000e+00, ptr @fadd_cell, align 4
  %o0 = atomicrmw fadd ptr @fadd_cell, float 2.000000e+00 monotonic, align 4
  %o1 = atomicrmw fadd ptr @fadd_cell, float 3.000000e+00 seq_cst, align 4
  %o2 = atomicrmw volatile fadd ptr @fadd_cell, float 4.000000e+00 syncscope("singlethread") acquire, align 4
  %final = load float, ptr @fadd_cell, align 4
  %b0 = bitcast float %o0 to i32
  %b1 = bitcast float %o1 to i32
  %b2 = bitcast float %o2 to i32
  %bf = bitcast float %final to i32
  %m0 = xor i32 %b0, %b1
  %m1 = xor i32 %b2, %bf
  %mix = xor i32 %m0, %m1
  ret i32 %mix
}

define i32 @protected_fadd() noinline optnone {
entry:
  call void @hikari_vmp()
  store float 1.000000e+00, ptr @fadd_cell, align 4
  %o0 = atomicrmw fadd ptr @fadd_cell, float 2.000000e+00 monotonic, align 4
  %o1 = atomicrmw fadd ptr @fadd_cell, float 3.000000e+00 seq_cst, align 4
  %o2 = atomicrmw volatile fadd ptr @fadd_cell, float 4.000000e+00 syncscope("singlethread") acquire, align 4
  %final = load float, ptr @fadd_cell, align 4
  %b0 = bitcast float %o0 to i32
  %b1 = bitcast float %o1 to i32
  %b2 = bitcast float %o2 to i32
  %bf = bitcast float %final to i32
  %m0 = xor i32 %b0, %b1
  %m1 = xor i32 %b2, %bf
  %mix = xor i32 %m0, %m1
  ret i32 %mix
}

; fsub with release ordering.
define i32 @reference_fsub() {
entry:
  store float 1.000000e+01, ptr @fsub_cell, align 4
  %o0 = atomicrmw fsub ptr @fsub_cell, float 1.500000e+00 monotonic, align 4
  %o1 = atomicrmw volatile fsub ptr @fsub_cell, float 2.500000e+00 syncscope("singlethread") acq_rel, align 4
  %final = load float, ptr @fsub_cell, align 4
  %b0 = bitcast float %o0 to i32
  %b1 = bitcast float %o1 to i32
  %bf = bitcast float %final to i32
  %m0 = xor i32 %b0, %b1
  %mix = xor i32 %m0, %bf
  ret i32 %mix
}

define i32 @protected_fsub() noinline optnone {
entry:
  call void @hikari_vmp()
  store float 1.000000e+01, ptr @fsub_cell, align 4
  %o0 = atomicrmw fsub ptr @fsub_cell, float 1.500000e+00 monotonic, align 4
  %o1 = atomicrmw volatile fsub ptr @fsub_cell, float 2.500000e+00 syncscope("singlethread") acq_rel, align 4
  %final = load float, ptr @fsub_cell, align 4
  %b0 = bitcast float %o0 to i32
  %b1 = bitcast float %o1 to i32
  %bf = bitcast float %final to i32
  %m0 = xor i32 %b0, %b1
  %mix = xor i32 %m0, %bf
  ret i32 %mix
}

; fmax: store 3.0 then fmax 5.0 seq_cst; mix old + final as i32.
define i32 @reference_fmax() {
entry:
  store float 3.000000e+00, ptr @fmax_cell, align 4
  %old = atomicrmw fmax ptr @fmax_cell, float 5.000000e+00 seq_cst, align 4
  %final = load float, ptr @fmax_cell, align 4
  %bo = bitcast float %old to i32
  %bf = bitcast float %final to i32
  %mix = xor i32 %bo, %bf
  ret i32 %mix
}

define i32 @protected_fmax() noinline optnone {
entry:
  call void @hikari_vmp()
  store float 3.000000e+00, ptr @fmax_cell, align 4
  %old = atomicrmw fmax ptr @fmax_cell, float 5.000000e+00 seq_cst, align 4
  %final = load float, ptr @fmax_cell, align 4
  %bo = bitcast float %old to i32
  %bf = bitcast float %final to i32
  %mix = xor i32 %bo, %bf
  ret i32 %mix
}

; fmin: store 3.0 then volatile fmin 2.0 singlethread acq_rel.
define i32 @reference_fmin() {
entry:
  store float 3.000000e+00, ptr @fmin_cell, align 4
  %old = atomicrmw volatile fmin ptr @fmin_cell, float 2.000000e+00 syncscope("singlethread") acq_rel, align 4
  %final = load float, ptr @fmin_cell, align 4
  %bo = bitcast float %old to i32
  %bf = bitcast float %final to i32
  %mix = xor i32 %bo, %bf
  ret i32 %mix
}

define i32 @protected_fmin() noinline optnone {
entry:
  call void @hikari_vmp()
  store float 3.000000e+00, ptr @fmin_cell, align 4
  %old = atomicrmw volatile fmin ptr @fmin_cell, float 2.000000e+00 syncscope("singlethread") acq_rel, align 4
  %final = load float, ptr @fmin_cell, align 4
  %bo = bitcast float %old to i32
  %bf = bitcast float %final to i32
  %mix = xor i32 %bo, %bf
  ret i32 %mix
}

; Unsupported: nonzero address-space pointer.
define float @unsupported_as1_fadd(ptr addrspace(1) %p) {
entry:
  call void @hikari_vmp()
  %v = atomicrmw fadd ptr addrspace(1) %p, float 1.000000e+00 seq_cst, align 4
  ret float %v
}

define i32 @main() {
entry:
  %e0 = call i32 @reference_fadd()
  %a0 = call i32 @protected_fadd()
  %e1 = call i32 @reference_fsub()
  %a1 = call i32 @protected_fsub()
  %e2 = call i32 @reference_fmax()
  %a2 = call i32 @protected_fmax()
  %e3 = call i32 @reference_fmin()
  %a3 = call i32 @protected_fmin()
  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %e1, %a1
  %m2 = icmp eq i32 %e2, %a2
  %m3 = icmp eq i32 %e3, %a3
  %t0 = and i1 %m0, %m1
  %t1 = and i1 %m2, %m3
  %ok = and i1 %t0, %t1
  %code = select i1 %ok, i32 0, i32 1
  ret i32 %code
}

; SKIP: seeded with: 93
; SKIP-DAG: Skipping VMP on unsupported_as1_fadd: unsupported argument type
; SKIP-NOT: Skipping VMP on protected_fadd:
; SKIP-NOT: Skipping VMP on protected_fsub:
; SKIP-NOT: Skipping VMP on protected_fmax:
; SKIP-NOT: Skipping VMP on protected_fmin:

; VIRT-LABEL: define i32 @protected_fadd(
; VIRT: vmp.dispatch:
; VIRT-DAG: atomicrmw fadd {{.*}} monotonic
; VIRT-DAG: atomicrmw fadd {{.*}} seq_cst
; VIRT-DAG: atomicrmw volatile fadd {{.*}} syncscope("singlethread") acquire

; VIRT-LABEL: define i32 @protected_fsub(
; VIRT: vmp.dispatch:
; VIRT-DAG: atomicrmw fsub {{.*}} monotonic
; VIRT-DAG: atomicrmw volatile fsub {{.*}} syncscope("singlethread") acq_rel

; VIRT-LABEL: define i32 @protected_fmax(
; VIRT: vmp.dispatch:
; VIRT: atomicrmw fmax {{.*}} seq_cst

; VIRT-LABEL: define i32 @protected_fmin(
; VIRT: vmp.dispatch:
; VIRT: atomicrmw volatile fmin {{.*}} syncscope("singlethread") acq_rel

; VIRT-LABEL: define float @unsupported_as1_fadd(
; VIRT: atomicrmw fadd ptr addrspace(1)

; VIRT: attributes{{.*}}"hikari.vmp.virtualized"
