---
name: busybox-fix
description: Fix a busybox applet for StarryOS. Test cases from linux-compatible-testsuit#13, no WSL baseline needed.
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

## Step 3: Get Test Command from Issue #13

Fetch https://github.com/rcore-os/linux-compatible-testsuit/issues/13, find the `<applet>` entry in the table. Extract **exactly** as listed:
- Test name (e.g., `busybox_blockdev`, `blkdiscard`)
- Shell command (the "测试命令" column) — use verbatim, do not modify
- Verification pattern (the "验证方式" column) — use verbatim, do not modify

**Critical**: The test command and verification must match the issue #13 entry **exactly**. Do not change, simplify, or "strengthen" the verification pattern — the issue is the source of truth.

The verification pattern dictates the `if` line in the script:
- `grep -qF "X"` or `grep -qE "X"` → `if echo "$_t" | <verification>; then`
- `[ -n "$_t" ]` → `if [ -n "$_t" ]; then`
- `rc=$?; [ "$rc" -eq 0 ]` → `if [ $? -eq 0 ]; then` (simplified exit code check)
- `rc=$?; [ "$rc" -eq 0 ] && grep -q "X"` → `if [ $? -eq 0 ] && echo "$_t" | grep -q "X"; then`

## Step 4: Append Test to Script

Add before `echo "=== BusyBox Test Summary ==="` in `tgoskits/test-suit/starryos/normal/qemu-smp1/busybox/sh/busybox-tests.sh`:

```sh
_t=$({ timeout 10 sh -c "<command from issue #13 exactly>"; } 2>&1)
if <verification adapted from issue #13 per rules above>; then echo "PASS: <test_name>"; PASS=$((PASS+1)); else echo "FAIL: <test_name>"; FAIL=$((FAIL+1)); fi
```

The `<command>` inside the script must be byte-for-byte identical to the "测试命令" column in issue #13.

## Step 5: StarryOS QEMU Confirm Failure

```
Agent(subagent_type="test-runner-agent", description="Run busybox QEMU test", prompt="Build StarryOS and run the busybox test in Docker QEMU: cd tgoskits && docker run --rm -v \"$(pwd)\":/workspace -w /workspace starryos-dev:ubuntu-qemu10.2.1 cargo xtask starry test qemu --arch riscv64 -c busybox 2>&1 | tee outputs/busybox-qemu-failure.log. Report PASS/FAIL for the <applet> test specifically.")
```

## Step 6: Debug

```
Agent(subagent_type="code-explorer-agent", description="Profile and trace failure", prompt="1. Run strace on Linux: strace -f busybox <applet> <args> 2>&1 | tee ../outputs/<applet>-strace.log. 2. Identify which syscalls the applet calls. 3. Search StarryOS kernel at tgoskits/os/StarryOS/kernel/src/syscall/ for the implementation of those syscalls. 4. Trace each syscall from entry to return, noting missing implementation, wrong error codes, or logic errors. 5. Report: what specific changes are needed in which files.")
```

## Step 7: Implement Fix

Based on code-explorer's report, implement the kernel fix. Edit the relevant file(s) under `tgoskits/os/StarryOS/kernel/src/syscall/`.

## Step 8: Verify Fix

```
Agent(subagent_type="test-runner-agent", description="Verify fix in QEMU", prompt="Build StarryOS and run busybox test in Docker QEMU: cd tgoskits && docker run --rm -v \"$(pwd)\":/workspace -w /workspace starryos-dev:ubuntu-qemu10.2.1 cargo xtask starry test qemu --arch riscv64 -c busybox 2>&1 | tee outputs/busybox-qemu-fixed.log. Report PASS/FAIL summary. Confirm the <applet> test passes and no regressions.")
```

## Step 9: Pre-Commit

```
Agent(subagent_type="pre-commit-agent", description="Run pre-commit CI checks", prompt="Run cd tgoskits && (cargo fmt --all -- --check && cargo xtask clippy && cargo xtask sync-lint && cargo xtask test) 2>&1 | tee ../outputs/pre-commit.log. Report pass/fail for each check.")
```

## Step 10: Ship

Commit both files (test script + kernel fix) inside `tgoskits/`, then:
```
Agent(subagent_type="pr-writer", description="Compose and open PR", prompt="Compose a bugfix PR for busybox <applet>. Describe: what the applet does, which syscalls were failing, what was fixed. Include before/after test results from outputs/. Rebase onto upstream/dev, push, and create the PR via gh CLI targeting rcore-os/tgoskits dev branch.")
```
