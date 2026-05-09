---
name: feature-dev
description: Develop a new StarryOS kernel feature. Follow step-by-step workflow calling sub-agents.
---

# Feature Development Workflow

Develop a new syscall or kernel feature for StarryOS. Call each sub-agent in order, save all outputs to `outputs/`.

## Step 1: Git Setup

```
Agent(subagent_type="git-sync-agent", description="Sync git and create feat branch", prompt="Sync dev branch with upstream and create a feat/<feature-name> branch. All operations inside tgoskits/ directory.")
```

## Step 2: Research Linux Behavior

```
Agent(subagent_type="code-explorer-agent", description="Research Linux feature behavior", prompt="Research Linux behavior for <feature/syscall>. Read the man page, check Linux kernel source for edge cases. Return: signature, all error conditions with errno values, edge cases. Save to outputs/<feature>-research.log.")
```

## Step 3: Design

Based on research, design the implementation:
- Which StarryOS module (fs, mm, task, net)?
- Syscall signature following StarryOS conventions
- Error mapping plan: Linux errno → `AxError::from(LinuxError::XXX)`

## Step 4: Write Test Cases

```
Agent(subagent_type="test-agent", description="Write test cases", prompt="Write C test cases for <feature-name>. Cover: normal usage, edge cases (empty, boundary, max), error conditions (invalid inputs with expected errno), cross-feature interactions. Place in tgoskits/test-suit/starryos/normal/qemu-smp1/test-<name>/.")
```

## Step 5: Implement

Implement the feature in the appropriate file under `tgoskits/os/StarryOS/kernel/src/syscall/`. Follow StarryOS patterns:
```rust
pub fn sys_<name>(arg1: Type, arg2: Type) -> AxResult<isize> {
    // Early input validation
    // Core logic
    // Return result or error
}
```

## Step 6: Build and Test

```
Agent(subagent_type="test-runner-agent", description="Build and test in QEMU", prompt="Build and run test-<name> in Docker QEMU: cd tgoskits && docker run --rm -v \"$(pwd)\":/workspace -w /workspace starryos-dev:ubuntu-qemu10.2.1 cargo xtask starry test qemu --arch riscv64 -c <name> 2>&1 | tee outputs/<name>-qemu.log. Report PASS/FAIL summary.")
```

Fix any discrepancies and re-run if needed.

## Step 7: Pre-Commit

```
Agent(subagent_type="pre-commit-agent", description="Run pre-commit CI checks", prompt="Run cd tgoskits && (cargo fmt --all -- --check && cargo xtask clippy && cargo xtask sync-lint && cargo xtask test) 2>&1 | tee ../outputs/pre-commit.log. Report pass/fail for each check.")
```

## Step 8: Ship

Commit the changes inside `tgoskits/`, then:
```
Agent(subagent_type="pr-writer", description="Compose and open PR", prompt="Compose a feature PR for <feature-name>. Include: motivation, design, implementation details, test results from outputs/. Rebase onto upstream/dev, push, and create the PR via gh CLI targeting rcore-os/tgoskits dev branch.")
```
