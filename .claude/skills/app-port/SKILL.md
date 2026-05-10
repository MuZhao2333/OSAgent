---
name: app-port
description: Port a large application to StarryOS. Profile, break into sub-goals, implement incrementally with commits.
---

# App Porting Workflow

Port a large application (Rust CLI tool, Go binary, Python script, etc.) to run on StarryOS. The workflow profiles the target app, breaks the work into small sub-goals each with its own test, and implements them test-first with one commit per goal.

The user specifies the app repository URL (e.g., `https://github.com/ultraworkers/claw-code`). Create the output directory `outputs/app-port-<app-name>/` before first use.

**Key principles**:
- **One commit per sub-goal**. Each commit is a self-contained, bisectable improvement.
- **Test-first**. Write the test, run it on WSL to confirm Linux baseline PASS, then implement.
- **1:1 sub-goal to test**. Every sub-goal names the test that verifies it.
- **PR deferred**. Don't create a PR until all sub-goals and integration tests pass.
- **Progress journal**. Update `progress.md` at each milestone; it becomes the final report.

## Step 1: Git Setup

```
Agent(subagent_type="git-sync-agent", description="Sync git and create feat branch", prompt="Sync dev branch with upstream and create a feat/<app-name> branch. All operations inside tgoskits/ directory.")
```

After git setup, initialize the progress journal:

```bash
cat > outputs/app-port-<app-name>/progress.md <<'EOF'
# Progress: <app-name>

## Timeline
- **Started**: <date>
- **Repo**: <url>
- **Branch**: feat/<app-name>

## Log
EOF
```

## Step 2: Profile the Target App

```
Agent(subagent_type="app-profiler-agent", description="Profile target app", prompt="Profile <app-repo-url> for StarryOS compatibility. Clone, build, strace the app. Cross-reference required syscalls/features with StarryOS's current support. Save the gap analysis to outputs/app-port-<app-name>/profile.log. Include a prioritized list of sub-goals in implementation order.")
```

After profiling, record in `progress.md`:
```markdown
- **<date/time>** — Profile complete. Found N required syscalls, M missing. See profile.log.
```

## Step 3: Plan — Sub-Goals and Test Strategy

The main session reads `outputs/app-port-<app-name>/profile.log` and produces the complete plan in `outputs/app-port-<app-name>/plan.md`.

### 3a: Define Sub-Goals (1:1 with tests)

Each sub-goal binds a kernel change to a specific test:

- **Small enough** to implement in one sitting (one syscall, one ioctl, one /proc file)
- **1:1 test binding** — the `test:` field names the C test case that verifies this goal
- **Ordered by dependency** (foundational syscalls first)

### 3b: Define Integration Test Strategy

Layered, from cheapest to most complete. Designed around the target app's own commands:

| Layer | What | Example (claw-code) | Depends on |
|-------|------|---------------------|------------|
| **Smoke** | Binary starts, prints help | `claw --help` | binary injectable |
| **Diagnostic** | Built-in self-check | `claw doctor` | file IO, env vars |
| **Functional** | Real workload | `claw prompt "hello"` | network, API key |

The test strategy also answers: how to cross-compile, how to inject the binary, what output proves success at each layer.

### 3c: Write the Plan File

```markdown
# Port Plan: <app-name>

## App Summary
- Repo: <url>
- Language: <rust/go/python/...>
- Build: <build command>
- Cross-compile: <riscv64 build command>
- Network required: <yes/no>

## Test Strategy
### Smoke
- Command: `<command>`
- Expected: `<what output proves it works>`

### Diagnostic (if applicable)
- Command: `<command>`
- Expected: `<what output proves it works>`

### Functional (if applicable)
- Command: `<command>`
- Expected: `<what output proves it works>`

## Sub-Goals
1. [ ] `<goal-title>` — `<what and why>`
   - File: `<kernel/path.rs>`
   - Test: `<app-name>/goal-01-<slug>` — `<what the test validates>`
2. [ ] `<goal-title>` — `<what and why>`
   - File: `<kernel/path.rs>`
   - Test: `<app-name>/goal-02-<slug>` — `<what the test validates>`
...

All tests live under `test-suit/starryos/normal/qemu-smp1/<app-name>/`. The test runner discovers cases recursively, so the case name is the relative path (e.g., `claw-code/goal-01-prlimit64`).

Integration tests go under `<app-name>/integration/`.

```

This plan is the **single source of truth**. Step 4 executes the sub-goals, Step 5 executes the test strategy.

After writing the plan, record in `progress.md`:
```markdown
- **<date/time>** — Plan complete. N sub-goals defined, M-layer integration test strategy.
```

## Step 4: Iterative Implementation Loop (Test-First)

**CRITICAL: One goal at a time.** Complete the full cycle (test → implement → verify → commit → push) for exactly ONE sub-goal before starting the next. Never implement multiple goals' kernel code in the same edit session — if two goals touch the same file, commit the first goal's changes, then edit again for the second. This ensures every commit is a bisectable, self-contained improvement.

For each sub-goal in order:

### 4a: Mark Goal In Progress

Update `plan.md`: change `[ ]` to `[~]`.

**Gate**: Before writing any code, confirm the previous goal is committed and pushed. Check `git -C tgoskits log --oneline -1` to verify.

### 4b: Research (if needed)

If the implementation isn't obvious from the profile:

```
Agent(subagent_type="code-explorer-agent", description="Research target behavior", prompt="Research Linux behavior for <syscall/feature>. Report: signature, error conditions with errno values, edge cases, and the Linux kernel source file and line range.")
```

### 4c: Write the Test First

If the test doesn't already exist, write it. Tests live under `tgoskits/test-suit/starryos/normal/qemu-smp1/<app-name>/goal-<NN>-<slug>/`:

```
Agent(subagent_type="test-agent", description="Write test case", prompt="Write a C test case for <syscall/feature>. Cover normal usage and error conditions. Place in tgoskits/test-suit/starryos/normal/qemu-smp1/<app-name>/goal-<NN>-<slug>/c/src/main.c.")
```

### 4d: WSL Baseline — Confirm Test Passes on Linux

```
Agent(subagent_type="test-runner-agent", description="Run WSL baseline", prompt="Run Linux baseline for <app-name>/goal-<NN>-<slug>: gcc tgoskits/test-suit/starryos/normal/qemu-smp1/<app-name>/goal-<NN>-<slug>/c/src/main.c -o /tmp/a.out && /tmp/a.out 2>&1 | tee ../outputs/app-port-<app-name>/goal-<NN>-wsl.log. Report PASS/FAIL.")
```

**Gate**: If the test doesn't PASS on Linux, fix the test first. The test must correctly describe the expected behavior before any kernel code is written.

### 4e: Implement the Kernel Change

Edit the relevant kernel source file(s) under `tgoskits/os/StarryOS/kernel/src/`. Follow StarryOS conventions:
- `AxError::from(LinuxError::XXX)` for error mapping
- Validate inputs early before main logic
- Return `AxResult<isize>`

### 4f: StarryOS Verify — Confirm Test Passes on StarryOS

```
Agent(subagent_type="test-runner-agent", description="Verify in StarryOS QEMU", prompt="Build StarryOS and run <app-name>/goal-<NN>-<slug> in Docker QEMU: cd tgoskits && docker run --rm -v \"$(pwd)\":/workspace -w /workspace starryos-dev:ubuntu-qemu10.2.1 cargo xtask starry test qemu --arch riscv64 -c <app-name>/goal-<NN>-<slug> 2>&1 | tee ../outputs/app-port-<app-name>/goal-<NN>-qemu.log. Report PASS/FAIL.")
```

Fix and re-run if needed. **Gate**: must PASS before committing.

### 4g: Pre-Commit Check

```
Agent(subagent_type="pre-commit-agent", description="Run pre-commit CI checks", prompt="Run cd tgoskits && (cargo fmt --all -- --check && cargo xtask clippy && cargo xtask sync-lint && cargo xtask test) 2>&1 | tee ../outputs/app-port-<app-name>/goal-<NN>-pre-commit.log. Report pass/fail for each check. If any check fails, report what to fix.")
```

**Gate**: Pre-commit must PASS. Fix any formatting/clippy/test failures before committing.

### 4h: Commit and Push

```bash
git -C tgoskits add <changed-files> && git -C tgoskits commit -m "feat(<app-name>): <brief description of goal>" && git -C tgoskits push origin feat/<app-name>
```

### 4i: Mark Complete and Log

Update `plan.md`: change `[~]` to `[x]`.

Record in `progress.md`:
```markdown
- **<date/time>** — Goal #NN complete: `<goal-title>`. Test `<app-name>/goal-<NN>-<slug>` passes on StarryOS. Commit: `<sha>`.
  - Issue (if any): <brief note about problem encountered and how it was resolved>
```

**Gate: Verify commit is pushed before moving to the next goal.**
```bash
git -C tgoskits log --oneline origin/feat/<app-name> -3
```
If the latest commit does not match the goal just completed, stop and fix. Only proceed to the next sub-goal after this gate passes.

## Step 5: Integration Test — Execute the Test Strategy

After all sub-goals are `[x]`, execute the test strategy from Step 3b. Start from the cheapest layer; only proceed if the current layer passes.

**The main session drives this** — cross-compilation and debugfs injection are host-side operations.

### 5a: Cross-Compile and Inject

From the plan's cross-compile instructions. Template:
```bash
# Rust
rustup target add riscv64gc-unknown-linux-musl
cd /tmp/app-profile && RUSTFLAGS="-C target-feature=+crt-static" cargo build --release --target riscv64gc-unknown-linux-musl

# Ensure rootfs image
ls tgoskits/target/rootfs/rootfs-riscv64-alpine.img || (cd tgoskits && cargo xtask starry rootfs --arch riscv64)

# Inject binary
cp <binary-path> /tmp/<app-name>-bin
cd tgoskits && debugfs -w target/rootfs/rootfs-riscv64-alpine.img <<'EOF'
rm /usr/bin/<app-name>
write /tmp/<app-name>-bin /usr/bin/<app-name>
sif /usr/bin/<app-name> mode 0100755
EOF
```

### 5b: Create Shell Test Case

```
tgoskits/test-suit/starryos/normal/qemu-smp1/<app-name>/integration/
  qemu-riscv64.toml     # shell_init_cmd = "/usr/bin/run.sh"
  sh/
    run.sh               # invokes /usr/bin/<app-name>, echoes EXIT:$?
```

### 5c: Run Each Layer

```
Agent(subagent_type="test-runner-agent", description="Run smoke test in QEMU", prompt="Build StarryOS and run the <app-name>/integration test case (smoke layer) in Docker QEMU: cd tgoskits && docker run --rm -v \"$(pwd)\":/workspace -w /workspace starryos-dev:ubuntu-qemu10.2.1 cargo xtask starry test qemu --arch riscv64 -c <app-name>/integration 2>&1 | tee ../outputs/app-port-<app-name>/integration-smoke.log. Report PASS/FAIL.")
```

If smoke passes, update `qemu-riscv64.toml` success/fail regex for the next layer and re-run. Record each layer's result in `progress.md`.

### 5d: Analyze and Iterate

If a layer fails, examine the log for:
- App output (did it start? crash?)
- Kernel panics
- Missing syscalls (`sys_xxx not implemented`)
- Unexpected exit codes

New issues → add as fresh sub-goals in `plan.md` → return to Step 4.

## Step 6: Wrap Up

When ALL sub-goals are `[x]` and all integration test layers pass:

### 6a: Pre-Commit

```
Agent(subagent_type="pre-commit-agent", description="Run pre-commit CI checks", prompt="Run cd tgoskits && (cargo fmt --all -- --check && cargo xtask clippy && cargo xtask sync-lint && cargo xtask test) 2>&1 | tee ../outputs/app-port-<app-name>/pre-commit.log. Report pass/fail for each check.")
```

### 6b: Finalize Progress Report

Record in `progress.md`:
```markdown
## Summary
- **Completed**: <date/time>
- **Sub-goals**: N/N complete
- **Commits**: <count>
- **Integration**: Smoke <PASS/FAIL>, Diagnostic <PASS/FAIL>, Functional <PASS/FAIL>
- **Pre-commit**: <PASS/FAIL>
```

### 6c: Ship PR

```
Agent(subagent_type="pr-writer", description="Compose and open PR", prompt="Compose a feature PR for porting <app-name> to StarryOS. Use outputs/app-port-<app-name>/progress.md for the summary. Include: the app, what was missing from StarryOS, each sub-goal implemented (list commits), integration test results, and pre-commit status. Rebase onto upstream/dev, push, and create the PR via gh CLI targeting rcore-os/tgoskits dev branch.")
```
