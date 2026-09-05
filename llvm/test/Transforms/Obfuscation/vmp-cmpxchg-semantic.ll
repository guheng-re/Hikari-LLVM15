; Scalar integer AtomicCmpXchgInst (extractvalue value + success only).
; RUN: opt -S -verify-each -aesSeed=37 -passes='default<O0>' %s -o %t.o0.ll 2>%t.o0.err
; RUN: FileCheck %s --check-prefix=SKIP < %t.o0.err
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o0.ll > %t.o0.host.ll
; RUN: lli -force-interpreter %t.o0.host.ll
; RUN: opt -S -verify-each -aesSeed=37 -passes='default<O2>' %s -o %t.o2.ll
; RUN: sed 's/aarch64-unknown-linux-gnu/x86_64-unknown-linux-gnu/' %t.o2.ll > %t.o2.host.ll
; RUN: lli -force-interpreter %t.o2.host.ll
; RUN: FileCheck %s --check-prefix=VIRT < %t.o0.ll

target triple = "aarch64-unknown-linux-gnu"

@slot32 = global i32 0, align 4
@slot8 = global i8 0, align 1

declare void @hikari_vmp()

define i32 @reference(i32 %desired, i32 %newv) {
entry:
  store i32 0, ptr @slot32, align 4
  %pair = cmpxchg ptr @slot32, i32 %desired, i32 %newv seq_cst seq_cst
  %old = extractvalue { i32, i1 } %pair, 0
  %ok = extractvalue { i32, i1 } %pair, 1
  %z = zext i1 %ok to i32
  %mix = xor i32 %old, %z
  ret i32 %mix
}

define i32 @protected(i32 %desired, i32 %newv) noinline optnone {
entry:
  call void @hikari_vmp()
  store i32 0, ptr @slot32, align 4
  %pair = cmpxchg ptr @slot32, i32 %desired, i32 %newv seq_cst seq_cst
  %old = extractvalue { i32, i1 } %pair, 0
  %ok = extractvalue { i32, i1 } %pair, 1
  %z = zext i1 %ok to i32
  %mix = xor i32 %old, %z
  ret i32 %mix
}

; Multi-width + weak + syncscope + success-only extract.
define i32 @reference_widths(i8 %d, i8 %n) {
entry:
  store i8 5, ptr @slot8, align 1
  %pair = cmpxchg weak ptr @slot8, i8 %d, i8 %n syncscope("singlethread") acquire monotonic
  %old = extractvalue { i8, i1 } %pair, 0
  %ok = extractvalue { i8, i1 } %pair, 1
  %zo = zext i8 %old to i32
  %zs = zext i1 %ok to i32
  %mix = xor i32 %zo, %zs
  ret i32 %mix
}

define i32 @protected_widths(i8 %d, i8 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  store i8 5, ptr @slot8, align 1
  %pair = cmpxchg weak ptr @slot8, i8 %d, i8 %n syncscope("singlethread") acquire monotonic
  %old = extractvalue { i8, i1 } %pair, 0
  %ok = extractvalue { i8, i1 } %pair, 1
  %zo = zext i8 %old to i32
  %zs = zext i1 %ok to i32
  %mix = xor i32 %zo, %zs
  ret i32 %mix
}

; Value-only extract (no success field use).
define i32 @reference_value_only(i32 %d, i32 %n) {
entry:
  store i32 9, ptr @slot32, align 4
  %pair = cmpxchg ptr @slot32, i32 %d, i32 %n monotonic monotonic
  %old = extractvalue { i32, i1 } %pair, 0
  ret i32 %old
}

define i32 @protected_value_only(i32 %d, i32 %n) noinline optnone {
entry:
  call void @hikari_vmp()
  store i32 9, ptr @slot32, align 4
  %pair = cmpxchg ptr @slot32, i32 %d, i32 %n monotonic monotonic
  %old = extractvalue { i32, i1 } %pair, 0
  ret i32 %old
}

; AS0 pointer-payload cmpxchg (weak volatile + syncscope).
@pslot = global ptr null, align 8
@gval = global i32 1, align 4

define i32 @reference_pointer(ptr %expected) {
entry:
  store ptr null, ptr @pslot, align 8
  %pair = cmpxchg weak volatile ptr @pslot, ptr %expected, ptr @gval syncscope("singlethread") seq_cst acquire
  %old = extractvalue { ptr, i1 } %pair, 0
  %ok = extractvalue { ptr, i1 } %pair, 1
  %old.null = icmp eq ptr %old, null
  %final = load ptr, ptr @pslot, align 8
  %final.g = icmp eq ptr %final, @gval
  %z0 = zext i1 %old.null to i32
  %z1 = zext i1 %ok to i32
  %z2 = zext i1 %final.g to i32
  %m0 = xor i32 %z0, %z1
  %mix = xor i32 %m0, %z2
  ret i32 %mix
}

; Result-discarded volatile cmpxchg (no extractvalue uses).
; Placed immediately before protected_pointer so VIRT-NOT extractvalue is scoped.
define void @reference_discard() {
entry:
  store i32 4, ptr @slot32, align 4
  %pair = cmpxchg volatile ptr @slot32, i32 4, i32 12 seq_cst acquire
  ret void
}

define void @protected_discard() noinline optnone {
entry:
  call void @hikari_vmp()
  store i32 4, ptr @slot32, align 4
  %pair = cmpxchg volatile ptr @slot32, i32 4, i32 12 seq_cst acquire
  ret void
}

define i32 @protected_pointer(ptr %expected) noinline optnone {
entry:
  call void @hikari_vmp()
  store ptr null, ptr @pslot, align 8
  %pair = cmpxchg weak volatile ptr @pslot, ptr %expected, ptr @gval syncscope("singlethread") seq_cst acquire
  %old = extractvalue { ptr, i1 } %pair, 0
  %ok = extractvalue { ptr, i1 } %pair, 1
  %old.null = icmp eq ptr %old, null
  %final = load ptr, ptr @pslot, align 8
  %final.g = icmp eq ptr %final, @gval
  %z0 = zext i1 %old.null to i32
  %z1 = zext i1 %ok to i32
  %z2 = zext i1 %final.g to i32
  %m0 = xor i32 %z0, %z1
  %mix = xor i32 %m0, %z2
  ret i32 %mix
}

define i32 @main() {
entry:
  %e0 = call i32 @reference(i32 0, i32 7)
  %a0 = call i32 @protected(i32 0, i32 7)
  %e1 = call i32 @reference(i32 1, i32 9)
  %a1 = call i32 @protected(i32 1, i32 9)
  %e2 = call i32 @reference_widths(i8 5, i8 3)
  %a2 = call i32 @protected_widths(i8 5, i8 3)
  %e3 = call i32 @reference_widths(i8 0, i8 1)
  %a3 = call i32 @protected_widths(i8 0, i8 1)
  %e4 = call i32 @reference_value_only(i32 9, i32 2)
  %a4 = call i32 @protected_value_only(i32 9, i32 2)
  %e5 = call i32 @reference_value_only(i32 0, i32 4)
  %a5 = call i32 @protected_value_only(i32 0, i32 4)
  call void @reference_discard()
  %ld_ref = load i32, ptr @slot32, align 4
  call void @protected_discard()
  %ld_prot = load i32, ptr @slot32, align 4
  ; Pointer success: expected null matches stored null
  %e6 = call i32 @reference_pointer(ptr null)
  %a6 = call i32 @protected_pointer(ptr null)
  ; Pointer failure: expected @gval does not match null
  %e7 = call i32 @reference_pointer(ptr @gval)
  %a7 = call i32 @protected_pointer(ptr @gval)
  %m0 = icmp eq i32 %e0, %a0
  %m1 = icmp eq i32 %e1, %a1
  %m2 = icmp eq i32 %e2, %a2
  %m3 = icmp eq i32 %e3, %a3
  %m4 = icmp eq i32 %e4, %a4
  %m5 = icmp eq i32 %e5, %a5
  %m6 = icmp eq i32 %ld_ref, %ld_prot
  %m7 = icmp eq i32 %e6, %a6
  %m8 = icmp eq i32 %e7, %a7
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

; SKIP: seeded with: 37
; SKIP-NOT: Skipping VMP on protected:
; SKIP-NOT: Skipping VMP on protected_widths:
; SKIP-NOT: Skipping VMP on protected_value_only:
; SKIP-NOT: Skipping VMP on protected_discard:
; SKIP-NOT: Skipping VMP on protected_pointer:

; VIRT-LABEL: define i32 @protected(
; VIRT: vmp.dispatch:
; VIRT-DAG: cmpxchg {{.*}}seq_cst seq_cst
; VIRT-DAG: extractvalue {{.*}}, 0
; VIRT-DAG: extractvalue {{.*}}, 1

; VIRT-LABEL: define i32 @protected_widths(
; VIRT: vmp.dispatch:
; VIRT-DAG: cmpxchg weak {{.*}}syncscope("singlethread") acquire monotonic
; VIRT-DAG: extractvalue

; VIRT-LABEL: define i32 @protected_value_only(
; VIRT: vmp.dispatch:
; VIRT-DAG: cmpxchg {{.*}}monotonic monotonic
; VIRT-DAG: extractvalue {{.*}}, 0

; VIRT-LABEL: define void @protected_discard(
; VIRT: vmp.dispatch:
; VIRT: cmpxchg volatile {{.*}}seq_cst acquire
; VIRT-NOT: extractvalue
; VIRT-LABEL: define i32 @protected_pointer(
; VIRT: vmp.dispatch:
; VIRT-DAG: cmpxchg weak volatile {{.*}}syncscope("singlethread") seq_cst acquire
; VIRT-DAG: extractvalue {{.*}}, 0
; VIRT-DAG: extractvalue {{.*}}, 1

; VIRT: attributes{{.*}}"hikari.vmp.virtualized"
