//===- Virtualization.h - VMP obfuscation pass ------------------*- C++ -*-===//
//
// Part of the Hikari obfuscation component.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_TRANSFORMS_OBFUSCATION_VIRTUALIZATION_H
#define LLVM_TRANSFORMS_OBFUSCATION_VIRTUALIZATION_H

#include "llvm/IR/PassManager.h"
#include "llvm/Pass.h"

namespace llvm {

class Function;
class Module;
class PassRegistry;

/// The new-pass-manager entry point for the late VMP pass.
///
/// The pass runs at the optimizer end and replaces selected AArch64 integer
/// functions with their per-function bytecode interpreter.
class VirtualizationPass : public PassInfoMixin<VirtualizationPass> {
public:
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &AM);
  static bool isRequired() { return true; }
};

/// Prepare VMP selections before the normal optimizer pipeline can inline or
/// erase the Hikari marker calls.
void prepareVMPSelection(Module &M);

/// The legacy-pass-manager entry point for the late VMP pass.
FunctionPass *createVirtualizationPass();
void initializeVirtualizationPass(PassRegistry &Registry);

} // end namespace llvm

#endif // LLVM_TRANSFORMS_OBFUSCATION_VIRTUALIZATION_H
