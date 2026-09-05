// RUN: %clang -target aarch64-unknown-linux-gnu -O2 -Xclang -disable-lifetime-markers -S -emit-llvm %s -o %t.ll
// RUN: FileCheck %s --check-prefix=IR < %t.ll
// RUN: %clang -target aarch64-unknown-linux-gnu -O2 -Xclang -disable-lifetime-markers -c %s -o %t.o
// RUN: llvm-readobj --file-headers %t.o | FileCheck %s

struct pair {
  int left;
  int right;
};

extern int vmp_helper(int *out, int value);

__attribute__((annotate("vmp"), noinline, optnone)) int vmp_memory(int value) {
  struct pair values[2];
  values[0].left = value;
  values[1].right = value + 1;
  int *selected = value > 0 ? &values[0].left : &values[1].right;
  *selected = vmp_helper(selected, *selected);
  return *selected;
}

// CHECK: Arch: aarch64
// IR: @__hikari_vmp_bc = private unnamed_addr constant
// IR-LABEL: define dso_local i32 @vmp_memory(
// IR: alloca [{{[0-9]+}} x ptr]
// IR: call i32 @vmp_helper
// IR: "hikari.vmp.virtualized"
