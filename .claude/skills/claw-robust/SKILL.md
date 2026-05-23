---
name: claw-robust
description: Robustness testing for claw-code on StarryOS. Generate test prompts, run in QEMU, classify failures (claw vs kernel), fix, and repeat.
---

# Claw-Code Robustness Testing

Iteratively generate claw test prompts, run in Docker QEMU on StarryOS, classify failures as claw binary bugs or StarryOS kernel bugs, and fix them.

## Core Loop

```
Generate test case → Create shell test → Run in QEMU → Classify failure → Fix (claw or kernel) → Record → Repeat N times
```

## Step 1: Generate Test Case

Generate or accept a realistic claw prompt that exercises multiple capabilities. Prompts should be:
- **Complex enough** to stress tool combinations (bash + write, multi-step workflows)
- **Verifiable** — the expected outcome should be checkable (file exists, output contains string, etc.)
- **Diverse** — vary which tools and workflows are tested

Example prompts (start simple, escalate complexity):

| # | Prompt | Tools | Verification |
|---|--------|-------|-------------|
| 1 | search for llm agent papers and write a digest | bash, write | file exists, non-empty |
| 2 | use bash to find all .txt files, list them sorted by size, and write the result to /tmp/sorted.txt | bash, write | file content matches |
| 3 | download a file from example.com, count its lines, and save the count to /tmp/linecount.txt | bash, write | file contains a number |
| 4 | write a Python script that computes fibonacci(20), run it, save output to /tmp/fib.txt | bash, write | file contains "6765" |
| 5 | create a markdown report about the current system (uname, disk, memory), save to /tmp/sysinfo.md | bash, write | file has uname output |

**The main session generates or selects the prompt.** The user may also specify prompts.

## Step 2: Create Shell Test Case

Create a new test case directory under `tgoskits/test-suit/starryos/normal/qemu-smp1/claw-code/`:

```
claw-code/robust-01/          ← increment NN each iteration
├── qemu-x86_64.toml
└── sh/
    └── claw-robust-test.sh
```

### qemu-x86_64.toml template

```toml
args = [
    "-nographic",
    "-m", "512M",
    "-device", "virtio-blk-pci,drive=disk0",
    "-drive", "id=disk0,if=none,format=raw,file=${workspace}/target/rootfs/rootfs-x86_64-alpine.img",
    "-device", "virtio-net-pci,netdev=net0",
    "-netdev", "user,id=net0"
]
uefi = false
to_bin = false
shell_prefix = "root@starry:"
shell_init_cmd = "/usr/bin/claw-robust-test.sh"
success_regex = ["ALL_TESTS_DONE"]
fail_regex = ['(?i)\bpanic(?:ked)?\b', 'ALL_TESTS_FAILED']
timeout = 1800
```

### claw-robust-test.sh template

```bash
#!/bin/sh
# Robustness test: <short description>
API_BASE_URL="https://api.deepseek.com/anthropic"
API_AUTH_TOKEN="sk-e269d580c7174e2a99bb21d1626c38e3"
API_MODEL="deepseek-chat"
# Setup fake git repo (claw requires it)
mkdir -p /tmp/work/.git/refs/heads /tmp/work/.git/objects
echo "ref: refs/heads/master" > /tmp/work/.git/HEAD
echo "[core]" > /tmp/work/.git/config
echo "	repositoryformatversion = 0" >> /tmp/work/.git/config
echo "	bare = false" >> /tmp/work/.git/config

echo "=== Robust-<NN>: <description> ==="
cd /tmp/work && env \
  ANTHROPIC_BASE_URL="${API_BASE_URL}" \
  ANTHROPIC_AUTH_TOKEN="${API_AUTH_TOKEN}" \
  ANTHROPIC_MODEL="${API_MODEL}" \
  timeout 600 /usr/bin/claw --allowedTools bash,write prompt '<ESCAPED_PROMPT>' 2>&1
EXIT_CODE=$?

# Verification step: check expected output
<VERIFICATION_COMMANDS>

if [ $EXIT_CODE -eq 0 ]; then
    echo "ALL_TESTS_DONE"
else
    echo "ALL_TESTS_FAILED: claw exited with code $EXIT_CODE"
    exit 1
fi
```

**IMPORTANT**: Escape single quotes in the prompt by replacing `'` with `'\''`.

**IMPORTANT**: Claw runs with sandbox workspace at `/tmp/work/`. Use workspace-relative paths in prompts (e.g., `digest.md`) and check files at their actual workspace path (e.g., `/tmp/work/digest.md`) in verification. Never use `/tmp/` paths in prompts — claw will reject them as escaping the workspace boundary.

The main session writes these files directly. After creating the test case, inject the shell script into the rootfs:

```bash
cd tgoskits && docker run --rm -v "$(pwd)":/workspace -w /workspace starryos-dev:ubuntu-qemu10.2.1 bash -c "
  debugfs -w target/rootfs/rootfs-x86_64-alpine.img -R 'rm /usr/bin/claw-robust-test.sh' 2>/dev/null || true
  debugfs -w target/rootfs/rootfs-x86_64-alpine.img -R 'write test-suit/starryos/normal/qemu-smp1/claw-code/robust-NN/sh/claw-robust-test.sh /usr/bin/claw-robust-test.sh'
"
```

If the rootfs has been reset (re-extracted from cache), re-inject the claw binary first:
```bash
cd tgoskits && docker run --rm -v "$(pwd)":/workspace -w /workspace starryos-dev:ubuntu-qemu10.2.1 bash -c "
  curl -sL -o /tmp/claw https://github.com/MuZhao2333/tgoskits/releases/download/claw-code-binary/claw
  chmod +x /tmp/claw
  debugfs -w target/rootfs/rootfs-x86_64-alpine.img -R 'rm /usr/bin/claw' 2>/dev/null || true
  debugfs -w target/rootfs/rootfs-x86_64-alpine.img -R 'write /tmp/claw /usr/bin/claw'
  debugfs -w target/rootfs/rootfs-x86_64-alpine.img -R 'sif /usr/bin/claw mode 0100755'
"
```

## Step 3: Run Test

```
Agent(subagent_type="test-runner-agent", description="Run robust-NN test", prompt="Build StarryOS and run the claw-code/robust-NN test case in Docker QEMU. Command: cd tgoskits && docker run --rm -v \"$(pwd)\":/workspace -w /workspace starryos-dev:ubuntu-qemu10.2.1 cargo xtask starry test qemu --arch x86_64 -c claw-code/robust-NN 2>&1 | tee ../outputs/claw-robust/test-NN.log. Report: PASS/FAIL, exit codes, error messages, panic traces.")
```

The main session reads `outputs/claw-robust/test-NN.log` for detailed analysis.

## Step 4: Classify and Fix Failure

Read the test log and classify the root cause:

| Symptom | Classification | Fix Location |
|---------|---------------|-------------|
| `api returned 400/401/429` | **claw bug** | `claw-code/rust/` |
| `content[].thinking must be passed back` | **claw bug** (thinking preservation) | `claw-code/rust/` |
| `tool_use ids without tool_result blocks` | **claw bug** (message construction) | `claw-code/rust/` |
| Kernel panic: `#PF`, `#GP`, page fault at `starry_kernel::` | **kernel bug** | `tgoskits/os/` |
| `Panic` at StarryOS source path | **kernel bug** | `tgoskits/os/` |
| Syscall returns wrong error code (e.g., EINVAL when should be ENOSYS) | **kernel bug** | `tgoskits/os/` |
| `exit code 1` with no clear API error | Check stderr for claw error vs kernel trace | Either |
| Tool execution fails (sandboxing, EFAULT, EACCES) | Could be either — trace deeper | Either |
| Hang / timeout (no output for >60s) | Likely **kernel bug** (async I/O, epoll) | `tgoskits/os/` |

### Fixing a kernel bug
- Modify files under `tgoskits/os/` only
- Follow StarryOS conventions: `AxError::from(LinuxError::XXX)`
- Return `AxResult<isize>` for syscalls

### Fixing a claw bug
- Modify files under `claw-code/rust/`
- Rebuild: `cd claw-code/rust && CARGO_TARGET_DIR=/tmp/claw-build3 cargo build --release -p rusty-claude-cli --target x86_64-unknown-linux-musl`
- Upload: `gh release upload claw-code-binary /tmp/claw-build3/x86_64-unknown-linux-musl/release/claw --repo MuZhao2333/tgoskits --clobber`
- Commit and push fix to `https://github.com/MuZhao2333/claw-code`

## Step 5: Re-run After Fix

After applying a fix, re-run the same test to verify:
- Re-inject the binary (if claw fix) and test script into rootfs
- Run test again with incremented log version (test-NN-v2.log, etc.)

## Step 6: Record Progress

Append to `outputs/claw-robust/progress.md`:

```markdown
- **2026-05-15 HH:MM** — Robust-NN. Prompt: "<prompt>".
  - Result: PASS/FAIL
  - Finding: <what was wrong, if failed>
  - Classification: claw bug / kernel bug / both
  - Fix: <what was changed, file paths>
  - Verdict: PASS after N retries / UNRESOLVED
```

## Step 7: Iterate

Continue loop until all N generated tests pass. When a test passes, move to the next one. If a test cannot be fixed within reasonable effort (3+ attempts without progress), document and skip.

### Test Tracking

At the start of each run, read `outputs/claw-robust/progress.md` to see which tests have been completed and which are pending.

### Prompt Complexity Escalation

Start with simpler prompts (single tool) and escalate to multi-tool workflows:

| Round | Complexity | Tool Set | Timeout |
|-------|-----------|----------|---------|
| 1-2 | Single tool (bash) | `bash` | 300s |
| 3-4 | Two tools (bash + write) | `bash,write` | 600s |
| 5-6 | Network + files (curl + process + write) | `bash,write` | 600s |
| 7+ | Multi-step programming (write code, compile, run) | `bash,write` | 900s |

### Parallel Test Accumulation

Previous tests remain in the test suite. After fixing a bug, re-run ALL previous robustness tests to check for regressions. The main session can run multiple tests sequentially.
