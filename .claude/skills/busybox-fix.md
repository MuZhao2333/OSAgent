---
name: busybox-fix
description: Fix a busybox applet for StarryOS. Follow step-by-step workflow calling sub-agents.
---

# Busybox Fix Workflow

Fix a failing busybox applet. Call each sub-agent in order, save all outputs to `outputs/`.

The user specifies the applet name (e.g., `blockdev`, `hwclock`).

## Step 1: Git Setup

```
Agent(subagent_type="git-sync-agent", description="Sync git and create fix branch", prompt="Sync dev branch with upstream and create a fix/<applet-name> branch. All operations inside tgoskits/ directory.")
```

## Step 2: Confirm Applet is Missing

```bash
grep -F "<applet>" tgoskits/test-suit/starryos/normal/qemu-smp1/busybox/sh/busybox-tests.sh
```
Expect no output. If found, the applet may already be tested — check with user.

## Step 3: Get Test Command

Fetch https://github.com/rcore-os/linux-compatible-testsuit/issues/13, find the `<applet>` entry. Extract:
- Test name (e.g., `busybox_blockdev`)
- Shell command to exercise the applet
- Verification pattern (grep match, exit code, etc.)

Evaluate the verification — a loose pattern like `grep -qF "blockdev"` matches error messages too. Strengthen if needed.

## Step 4: Append Test to Script

Add before `echo "=== BusyBox Test Summary ==="` in `tgoskits/test-suit/starryos/normal/qemu-smp1/busybox/sh/busybox-tests.sh`:

```sh
_t=$({ timeout 10 sh -c "<command>"; } 2>&1)
if echo "$_t" | <verification>; then echo "PASS: <test_name>"; PASS=$((PASS+1)); else echo "FAIL: <test_name>"; FAIL=$((FAIL+1)); fi
```

## Step 5: Linux Baseline

First: `busybox --list 2>/dev/null | grep -w "<applet>"`

If available:
```
Agent(subagent_type="test-runner-agent", description="Run Linux busybox baseline", prompt="Run the busybox test script on WSL (no Docker): cd tgoskits/test-suit/starryos/normal/qemu-smp1/busybox/sh && sh busybox-tests.sh 2>&1 | tee ../../../../../../../outputs/busybox-linux.log. Report PASS/FAIL for the <applet> test specifically.")
```

If not available, skip and rely on the issue's verification pattern.

## Step 6: StarryOS QEMU Confirm Failure

```
Agent(subagent_type="test-runner-agent", description="Run busybox QEMU test", prompt="Build StarryOS and run the busybox test in Docker QEMU: cd tgoskits && docker run --rm -v \"$(pwd)\":/workspace -w /workspace starryos-dev:ubuntu-qemu10.2.1 cargo xtask starry test qemu --arch riscv64 -c busybox 2>&1 | tee outputs/busybox-qemu-failure.log. Report PASS/FAIL for the <applet> test specifically.")
```

## Step 7: Debug

```
Agent(subagent_type="code-explorer-agent", description="Profile and trace failure", prompt="1. Run strace on Linux: strace -f busybox <applet> <args> 2>&1 | tee ../outputs/<applet>-strace.log. 2. Identify which syscalls the applet calls. 3. Search StarryOS kernel at tgoskits/os/StarryOS/kernel/src/syscall/ for the implementation of those syscalls. 4. Trace each syscall from entry to return, noting missing implementation, wrong error codes, or logic errors. 5. Report: what specific changes are needed in which files.")
```

## Step 8: Implement Fix

Based on code-explorer's report, implement the kernel fix. Edit the relevant file(s) under `tgoskits/os/StarryOS/kernel/src/syscall/`.

## Step 9: Verify Fix

```
Agent(subagent_type="test-runner-agent", description="Verify fix in QEMU", prompt="Build StarryOS and run busybox test in Docker QEMU: cd tgoskits && docker run --rm -v \"$(pwd)\":/workspace -w /workspace starryos-dev:ubuntu-qemu10.2.1 cargo xtask starry test qemu --arch riscv64 -c busybox 2>&1 | tee outputs/busybox-qemu-fixed.log. Report PASS/FAIL summary. Confirm the <applet> test passes and no regressions.")
```

## Step 10: Pre-Commit

```
Agent(subagent_type="pre-commit-agent", description="Run pre-commit CI checks", prompt="Run cd tgoskits && (cargo fmt --all -- --check && cargo xtask clippy && cargo xtask sync-lint && cargo xtask test) 2>&1 | tee ../outputs/pre-commit.log. Report pass/fail for each check.")
```

## Step 11: Ship

Commit both files (test script + kernel fix) inside `tgoskits/`, then:
```
Agent(subagent_type="pr-writer", description="Compose and open PR", prompt="Compose a bugfix PR for busybox <applet>. Describe: what the applet does, which syscalls were failing, what was fixed. Include before/after test results from outputs/. Rebase onto upstream/dev, push, and create the PR via gh CLI targeting rcore-os/tgoskits dev branch.")
```
