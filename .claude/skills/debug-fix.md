---
name: debug-fix
description: Debug and fix a StarryOS kernel bug. Follow step-by-step workflow calling sub-agents.
---

# Bug Fix Workflow

Debug a StarryOS kernel bug. Call each sub-agent in order, save all outputs to `outputs/`.

## Step 1: Git Setup

```
Agent(subagent_type="git-sync-agent", description="Sync git and create fix branch", prompt="Sync dev branch with upstream and create a fix/<bug-name> branch. All operations inside tgoskits/ directory.")
```

## Step 2: Linux Baseline

```
Agent(subagent_type="test-runner-agent", description="Run Linux baseline", prompt="Run Linux baseline for test-<name>: cd tgoskits && gcc test-suit/starryos/normal/qemu-smp1/test-<name>/c/src/main.c -o /tmp/a.out && /tmp/a.out 2>&1 | tee outputs/<test>-linux.log. Report PASS/FAIL summary.")
```

## Step 3: StarryOS QEMU Confirm Failure

```
Agent(subagent_type="test-runner-agent", description="Run StarryOS QEMU test", prompt="Build and run test-<name> in Docker QEMU: cd tgoskits && docker run --rm -v \"$(pwd)\":/workspace -w /workspace starryos-dev:ubuntu-qemu10.2.1 cargo xtask starry test qemu --arch riscv64 -c <name> 2>&1 | tee outputs/<test>-qemu-failure.log. Report PASS/FAIL summary with failure details.")
```

Compare Linux vs StarryOS results. Identify mismatched error codes and behaviors.

## Step 4: Trace and Analyze

```
Agent(subagent_type="code-explorer-agent", description="Trace kernel implementation", prompt="1. Research Linux expected behavior for syscall <name> (man page, error conditions, errno values). 2. Search StarryOS kernel at tgoskits/os/StarryOS/kernel/src/syscall/ for the implementation. 3. Trace from syscall entry to return. Note: input validation, error mapping, core logic. 4. Compare with Linux — what's missing or wrong? 5. Report: file path, line range, root cause, and specific fix needed.")
```

## Step 5: Implement Fix

Based on code-explorer's report, edit the relevant file(s). Follow StarryOS conventions:
- `AxError::from(LinuxError::XXX)` for error mapping
- Validate inputs early before main logic

## Step 6: Verify Fix

```
Agent(subagent_type="test-runner-agent", description="Verify fix in QEMU", prompt="Build and run test-<name> in Docker QEMU: cd tgoskits && docker run --rm -v \"$(pwd)\":/workspace -w /workspace starryos-dev:ubuntu-qemu10.2.1 cargo xtask starry test qemu --arch riscv64 -c <name> 2>&1 | tee outputs/<test>-qemu-fixed.log. Report PASS/FAIL. Confirm all tests pass.")
```

## Step 7: Pre-Commit

```
Agent(subagent_type="pre-commit-agent", description="Run pre-commit CI checks", prompt="Run cd tgoskits && (cargo fmt --all -- --check && cargo xtask clippy && cargo xtask sync-lint && cargo xtask test) 2>&1 | tee ../outputs/pre-commit.log. Report pass/fail for each check.")
```

## Step 8: Ship

Commit the fix inside `tgoskits/`, then:
```
Agent(subagent_type="pr-writer", description="Compose and open PR", prompt="Compose a bugfix PR for <bug-name>. Include: bug summary, root cause, before/after test results from outputs/. Rebase onto upstream/dev, push, and create the PR via gh CLI targeting rcore-os/tgoskits dev branch.")
```
