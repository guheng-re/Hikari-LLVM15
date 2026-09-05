// For open-source license, please refer to [License](https://github.com/HikariObfuscator/Hikari/wiki/License).
//===----------------------------------------------------------------------===//
#include "llvm/Transforms/Obfuscation/Obfuscation.h"
#include "llvm/Transforms/Obfuscation/CryptoUtils.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/Triple.h"
#include "llvm/IR/Verifier.h"
#include "llvm/Transforms/Utils/Cloning.h"
#include "llvm/Transforms/Utils/PromoteMemToReg.h"
#include "llvm/IR/InstIterator.h"
#if LLVM_VERSION_MAJOR >= 9
#include "llvm/Transforms/Obfuscation/LegacyLowerSwitch.h"
#endif
#include <fcntl.h>
using namespace llvm;

namespace {
static cl::opt<unsigned> VMPPostCFFMaxBlocks(
    "vmp-post-cff-max-blocks", cl::init(256), cl::NotHidden,
    cl::desc("Maximum number of blocks accepted by VMP post-CFF."));
static cl::opt<unsigned> VMPPostCFFMaxInsts(
    "vmp-post-cff-max-insts", cl::init(8192), cl::NotHidden,
    cl::desc("Maximum number of instructions accepted by VMP post-CFF."));

static constexpr StringLiteral VMPVirtualizedAttribute =
    "hikari.vmp.virtualized";
static constexpr StringLiteral VMPPostCFFSelectionAttribute =
    "hikari.vmp.post.cff";
static constexpr StringLiteral VMPPostCFFAppliedAttribute =
    "hikari.vmp.post.cff.applied";

struct Flattening : public FunctionPass {
  static char ID; // Pass identification, replacement for typeid
  bool flag;
  Flattening() : FunctionPass(ID) { this->flag = true; }
  Flattening(bool flag) : FunctionPass(ID) { this->flag = flag; }
  bool runOnFunction(Function &F) override;
  bool flatten(Function *f, bool PreserveVMPState = false);
};

struct VMPPostFlattening : public FunctionPass {
  static char ID;
  VMPPostFlattening() : FunctionPass(ID) {}
  bool runOnFunction(Function &F) override;
};

static void reportVMPPostCFFSkip(const Function &F, StringRef Reason) {
  errs() << "Skipping VMP post-CFF on " << F.getName() << ": " << Reason
         << "\n";
}

static bool isAArch64Module(const Function &F) {
  return Triple(F.getParent()->getTargetTriple()).isAArch64();
}

static bool hasUnsupportedVMPPostCFFSSA(const Function &F) {
  for (const BasicBlock &BB : F) {
    for (const Instruction &I : BB) {
      // The regular CFF pass repairs these values with fixStack().  That
      // operation is intentionally forbidden for the VMP interpreter because
      // it can rewrite volatile VM state accesses.
      if (isa<PHINode>(I))
        return true;
      if (!isa<AllocaInst>(I) && I.isUsedOutsideOfBlock(&BB))
        return true;
    }
  }
  return false;
}

static LoadInst *materializeVMPDispatchCondition(Function &F) {
  SwitchInst *DispatchSwitch = nullptr;
  for (BasicBlock &BB : F) {
    if (auto *Switch = dyn_cast<SwitchInst>(BB.getTerminator())) {
      if (BB.getName() != "vmp.dispatch" || DispatchSwitch)
        return nullptr;
      DispatchSwitch = Switch;
    }
  }
  if (!DispatchSwitch)
    return nullptr;

  Instruction *EntryInsertion =
      &*F.getEntryBlock().getFirstInsertionPt();
  Type *ConditionTy = DispatchSwitch->getCondition()->getType();
  auto *ConditionSlot = new AllocaInst(ConditionTy, 0,
                                       "vmp.post.cff.opcode", EntryInsertion);
  new StoreInst(DispatchSwitch->getCondition(), ConditionSlot, DispatchSwitch);
  auto *ConditionLoad = new LoadInst(ConditionTy, ConditionSlot,
                                     "vmp.post.cff.opcode.load", DispatchSwitch);
  DispatchSwitch->setCondition(ConditionLoad);
  return ConditionLoad;
}

static void localizeLoweredSwitchCondition(LoadInst *ConditionLoad) {
  SmallVector<Use *, 16> CrossBlockUses;
  BasicBlock *ConditionBlock = ConditionLoad->getParent();
  for (Use &U : ConditionLoad->uses()) {
    auto *User = dyn_cast<Instruction>(U.getUser());
    if (User && User->getParent() != ConditionBlock)
      CrossBlockUses.push_back(&U);
  }

  for (Use *U : CrossBlockUses) {
    auto *User = cast<Instruction>(U->getUser());
    auto *LocalLoad = new LoadInst(ConditionLoad->getType(),
                                   ConditionLoad->getPointerOperand(),
                                   "vmp.post.cff.opcode.load", User);
    U->set(LocalLoad);
  }
}

/// deleteBody() drops hung-off operands (personality / prefix /
/// prologue), function metadata, and forces ExternalLinkage.
/// VMP already restored personality on the virtualized shell; post-CFF
/// must not throw that Function-level state away.
struct SavedFunctionLevelState {
  GlobalValue::LinkageTypes Linkage = GlobalValue::ExternalLinkage;
  Constant *Personality = nullptr;
  Constant *Prefix = nullptr;
  Constant *Prologue = nullptr;
  SmallVector<std::pair<unsigned, MDNode *>, 8> Metadata;
};

static SavedFunctionLevelState saveFunctionLevelState(const Function &F) {
  SavedFunctionLevelState S;
  S.Linkage = F.getLinkage();
  if (F.hasPersonalityFn())
    S.Personality = F.getPersonalityFn();
  if (F.hasPrefixData())
    S.Prefix = F.getPrefixData();
  if (F.hasPrologueData())
    S.Prologue = F.getPrologueData();
  F.getAllMetadata(S.Metadata);
  return S;
}

static void restoreFunctionLevelState(Function &F,
                                      const SavedFunctionLevelState &S) {
  F.setLinkage(S.Linkage);
  if (S.Personality)
    F.setPersonalityFn(S.Personality);
  if (S.Prefix)
    F.setPrefixData(S.Prefix);
  if (S.Prologue)
    F.setPrologueData(S.Prologue);
  for (const auto &MD : S.Metadata)
    F.setMetadata(MD.first, MD.second);
}

static Function *cloneVMPPostCFFCandidate(Function &F) {
  Module *M = F.getParent();
  Function *Candidate = Function::Create(
      F.getFunctionType(), GlobalValue::PrivateLinkage, F.getAddressSpace(),
      F.getName() + ".vmp.post.cff.candidate", M);

  ValueToValueMapTy VMap;
  // Preserve recursion and direct calls to the original public symbol.  This
  // also keeps the temporary clone isolated from the program ABI.
  VMap[&F] = &F;
  Function::arg_iterator NewArg = Candidate->arg_begin();
  for (Argument &OldArg : F.args())
    VMap[&OldArg] = &*NewArg++;

  SmallVector<ReturnInst *, 8> Returns;
  CloneFunctionInto(Candidate, &F, VMap,
                    CloneFunctionChangeType::LocalChangesOnly, Returns);
  Candidate->setDSOLocal(true);
  return Candidate;
}

static bool flattenVMPPostCFF(Function &F) {
  if (F.size() > VMPPostCFFMaxBlocks) {
    reportVMPPostCFFSkip(F, "basic-block budget exceeded");
    return false;
  }
  if (F.getInstructionCount() > VMPPostCFFMaxInsts) {
    reportVMPPostCFFSkip(F, "instruction budget exceeded");
    return false;
  }
  if (hasUnsupportedVMPPostCFFSSA(F)) {
    reportVMPPostCFFSkip(F, "cross-block SSA requires fixStack");
    return false;
  }

  Function *Candidate = cloneVMPPostCFFCandidate(F);
  Flattening CFF(false);
  if (!CFF.flatten(Candidate, true) || verifyFunction(*Candidate, &errs())) {
    reportVMPPostCFFSkip(F, "candidate flattening or verification failed");
    Candidate->eraseFromParent();
    return false;
  }

  Function::arg_iterator OriginalArg = F.arg_begin();
  for (Argument &CandidateArg : Candidate->args())
    CandidateArg.replaceAllUsesWith(&*OriginalArg++);

  const SavedFunctionLevelState Saved = saveFunctionLevelState(F);
  F.deleteBody();
  restoreFunctionLevelState(F, Saved);
  F.getBasicBlockList().splice(F.begin(), Candidate->getBasicBlockList());
  Candidate->eraseFromParent();
  F.addFnAttr(VMPPostCFFAppliedAttribute);
  return true;
}
} // namespace

char Flattening::ID = 0;
char VMPPostFlattening::ID = 0;
FunctionPass *llvm::createFlatteningPass(bool flag) {
  return new Flattening(flag);
}
FunctionPass *llvm::createFlatteningPass() { return new Flattening(); }
INITIALIZE_PASS(Flattening, "cffobf", "Enable Control Flow Flattening.", true,
                true)
INITIALIZE_PASS(VMPPostFlattening, "vmp-post-cff",
                "Flatten virtualized VMP interpreter control flow.", true,
                true)
FunctionPass *llvm::createVMPPostFlatteningPass() {
  return new VMPPostFlattening();
}
bool Flattening::runOnFunction(Function &F) {
  Function *tmp = &F;
  // Do we obfuscate
  if (toObfuscate(flag, tmp, "fla")) {
    errs() << "Running ControlFlowFlattening On " << F.getName() << "\n";
    return flatten(tmp);
  }

  return false;
}

bool VMPPostFlattening::runOnFunction(Function &F) {
  if (!F.hasFnAttribute(VMPVirtualizedAttribute) ||
      !F.hasFnAttribute(VMPPostCFFSelectionAttribute) ||
      F.hasFnAttribute(VMPPostCFFAppliedAttribute) || !isAArch64Module(F))
    return false;
  return flattenVMPPostCFF(F);
}

PreservedAnalyses llvm::VMPPostFlatteningPass::run(
    Function &F, FunctionAnalysisManager &) {
  return VMPPostFlattening().runOnFunction(F) ? PreservedAnalyses::none()
                                               : PreservedAnalyses::all();
}

bool Flattening::flatten(Function *f, bool PreserveVMPState) {
  vector<BasicBlock *> origBB;
  BasicBlock *loopEntry;
  BasicBlock *loopEnd;
  LoadInst *load;
  SwitchInst *switchI;
  AllocaInst *switchVar;

  // SCRAMBLER
  std::map<uint32_t,uint32_t> scrambling_key;
  // END OF SCRAMBLER

  // Lower switch
  LoadInst *VMPDispatchCondition = nullptr;
  if (PreserveVMPState) {
    VMPDispatchCondition = materializeVMPDispatchCondition(*f);
    if (!VMPDispatchCondition)
      return false;
  }
#if LLVM_VERSION_MAJOR >= 9
  FunctionPass *lower = createLegacyLowerSwitchPass();
  lower->runOnFunction(*f);
#else
  FunctionPass *lower = createLowerSwitchPass();
  lower->runOnFunction(*f);
#endif
  if (PreserveVMPState)
    localizeLoweredSwitchCondition(VMPDispatchCondition);

  // Save all original BB
  for (Function::iterator i = f->begin(); i != f->end(); ++i) {
    BasicBlock *tmp = &*i;
    if (tmp->isEHPad() || tmp->isLandingPad()) {
          errs()<<f->getName()<<" Contains Exception Handing Instructions and is unsupported for flattening in the open-source version of Hikari.\n";
          return false;
    }
    origBB.push_back(tmp);

    BasicBlock *bb = &*i;
    if (!isa<BranchInst>(bb->getTerminator()) &&
        !isa<ReturnInst>(bb->getTerminator()) &&
        !(PreserveVMPState && isa<UnreachableInst>(bb->getTerminator()))) {
      return false;
    }
  }

  // Nothing to flatten
  if (origBB.size() <= 1) {
    return false;
  }

  // Remove first BB
  origBB.erase(origBB.begin());

  // Get a pointer on the first BB
  Function::iterator tmp = f->begin(); //++tmp;
  BasicBlock *insert = &*tmp;

  // If main begin with an if
  BranchInst *br = NULL;
  if (isa<BranchInst>(insert->getTerminator())) {
    br = cast<BranchInst>(insert->getTerminator());
  }

  if (br != NULL) { // https://github.com/eshard/obfuscator-llvm/commit/af789724563ff3d300317fe4a9a9b0f3a88007eb
    BasicBlock::iterator i = insert->end();
    --i;

    if (insert->size() > 1) {
      --i;
    }

    BasicBlock *tmpBB = insert->splitBasicBlock(i, "first");
    origBB.insert(origBB.begin(), tmpBB);
  }

  // Remove jump
  Instruction* oldTerm=insert->getTerminator();

  // Create switch variable and set as it
  switchVar =
      new AllocaInst(Type::getInt32Ty(f->getContext()), 0, "switchVar",oldTerm);
  oldTerm->eraseFromParent();
  new StoreInst(
      ConstantInt::get(Type::getInt32Ty(f->getContext()),
                       llvm::cryptoutils->scramble32(0, scrambling_key)),
      switchVar, insert);

  // Create main loop
  loopEntry = BasicBlock::Create(f->getContext(), "loopEntry", f, insert);
  loopEnd = BasicBlock::Create(f->getContext(), "loopEnd", f, insert);

#if LLVM_VERSION_MAJOR >= 15
  load = new LoadInst(Type::getInt32Ty(f->getContext()), switchVar,
                      "switchVar", loopEntry);
#elif LLVM_VERSION_MAJOR >= 14
  load = new LoadInst(switchVar->getType()->getPointerElementType(), switchVar, "switchVar", loopEntry);
#elif LLVM_VERSION_MAJOR >= 10
  load = new LoadInst(switchVar->getType()->getElementType(), switchVar, "switchVar", loopEntry);
#else
  load = new LoadInst(switchVar, "switchVar", loopEntry);
#endif

  // Move first BB on top
  insert->moveBefore(loopEntry);
  BranchInst::Create(loopEntry, insert);

  // loopEnd jump to loopEntry
  BranchInst::Create(loopEntry, loopEnd);

  BasicBlock *swDefault =
      BasicBlock::Create(f->getContext(), "switchDefault", f, loopEnd);
  BranchInst::Create(loopEnd, swDefault);

  // Create switch instruction itself and set condition
  switchI = SwitchInst::Create(&*f->begin(), swDefault, 0, loopEntry);
  switchI->setCondition(load);

  // Remove branch jump from 1st BB and make a jump to the while
  f->begin()->getTerminator()->eraseFromParent();

  BranchInst::Create(loopEntry, &*f->begin());

  // Put all BB in the switch
  for (vector<BasicBlock *>::iterator b = origBB.begin(); b != origBB.end();
       ++b) {
    BasicBlock *i = *b;
    ConstantInt *numCase = NULL;

    // Move the BB inside the switch (only visual, no code logic)
    i->moveBefore(loopEnd);

    // Add case to switch
    numCase = cast<ConstantInt>(ConstantInt::get(
        switchI->getCondition()->getType(),
        llvm::cryptoutils->scramble32(switchI->getNumCases(), scrambling_key)));
    switchI->addCase(numCase, i);
  }

  // Recalculate switchVar
  for (vector<BasicBlock *>::iterator b = origBB.begin(); b != origBB.end();
       ++b) {
    BasicBlock *i = *b;
    ConstantInt *numCase = NULL;

    // Ret BB
    if (i->getTerminator()->getNumSuccessors() == 0) {
      continue;
    }

    // If it's a non-conditional jump
    if (i->getTerminator()->getNumSuccessors() == 1) {
      // Get successor and delete terminator
      BasicBlock *succ = i->getTerminator()->getSuccessor(0);
      i->getTerminator()->eraseFromParent();

      // Get next case
      numCase = switchI->findCaseDest(succ);

      // If next case == default case (switchDefault)
      if (numCase == NULL) {
        numCase = cast<ConstantInt>(
            ConstantInt::get(switchI->getCondition()->getType(),
                             llvm::cryptoutils->scramble32(
                                 switchI->getNumCases() - 1, scrambling_key)));
      }

      // Update switchVar and jump to the end of loop
      new StoreInst(numCase, load->getPointerOperand(), i);
      BranchInst::Create(loopEnd, i);
      continue;
    }

    // If it's a conditional jump
    if (i->getTerminator()->getNumSuccessors() == 2) {
      // Get next cases
      ConstantInt *numCaseTrue =
          switchI->findCaseDest(i->getTerminator()->getSuccessor(0));
      ConstantInt *numCaseFalse =
          switchI->findCaseDest(i->getTerminator()->getSuccessor(1));

      // Check if next case == default case (switchDefault)
      if (numCaseTrue == NULL) {
        numCaseTrue = cast<ConstantInt>(
            ConstantInt::get(switchI->getCondition()->getType(),
                             llvm::cryptoutils->scramble32(
                                 switchI->getNumCases() - 1, scrambling_key)));
      }

      if (numCaseFalse == NULL) {
        numCaseFalse = cast<ConstantInt>(
            ConstantInt::get(switchI->getCondition()->getType(),
                             llvm::cryptoutils->scramble32(
                                 switchI->getNumCases() - 1, scrambling_key)));
      }

      // Create a SelectInst
      BranchInst *br = cast<BranchInst>(i->getTerminator());
      SelectInst *sel =
          SelectInst::Create(br->getCondition(), numCaseTrue, numCaseFalse, "",
                             i->getTerminator());

      // Erase terminator
      i->getTerminator()->eraseFromParent();
      // Update switchVar and jump to the end of loop
      new StoreInst(sel, load->getPointerOperand(), i);
      BranchInst::Create(loopEnd, i);
      continue;
    }
  }
  if (!PreserveVMPState) {
    errs()<<"Fixing Stack\n";
    fixStack(f);
    errs()<<"Fixed Stack\n";
  }

  return true;
}
