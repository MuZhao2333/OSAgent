# OSAgent - StarryOS Development Framework

## Project Purpose

This project provides a structured framework for debugging, feature development, and maintenance of **StarryOS** (a Rust-based OS kernel) via the tgoskits test suite. It defines agents and templates to make StarryOS development systematic and reproducible.

Architecture is entirely agent-driven: three main workflow agents (debug, busybox, feature) call sub-agents (git-sync, code-explorer, test-runner, test-agent, pre-commit, pr-writer) at the appropriate workflow steps. Each sub-agent has a narrow, context-bounded job so the main agent stays lean.

## Git Remotes

| Remote | URL | Role |
|--------|-----|------|
| `origin` | `git@github.com:MuZhao2333/tgoskits.git` | Personal fork |
| `upstream` | `git@github.com:rcore-os/tgoskits.git` | Upstream main repo |

## Key Paths

| Path | Purpose |
|------|---------|
| `tgoskits/` | Main repo containing StarryOS kernel + test suite |
| `tgoskits/os/StarryOS/` | StarryOS kernel source |
| `tgoskits/test-suit/starryos/` | Test cases for StarryOS |
| `.claude/agents/` | Custom Claude Code agents |
| `docs/` | Workflow and environment documentation |
| `templates/` | PR and test case templates |

## Git Workflow Rules

**Every main agent starts by calling `git-sync-agent`** to ensure:

1. Working tree is clean
2. On `dev` branch, and local `dev` == `origin/dev` == `upstream/dev`
3. A new branch is created off `dev` for the current task

### Branch Naming
- Bugfix: `fix/<name>` (e.g., `fix/truncate-validation`)
- Feature: `feat/<name>` (e.g., `feat/mmap-support`)

### PR Target
- All PRs target `upstream/dev` (rcore-os/tgoskits)
- Before creating PR, `pr-writer` agent rebases onto latest `upstream/dev`

## Environment: How to Run Code

All commands are executed from the `tgoskits/` directory.

**Critical**: `cargo xtask starry` commands (build, test qemu) **must** run inside the Docker container `starryos-dev:ubuntu-qemu10.2.1`. The container provides the riscv64 toolchain and QEMU runtime.

Commands that run directly on WSL (no Docker needed): `cargo fmt`, `cargo xtask clippy`, `cargo xtask sync-lint`, `cargo xtask test` (std tests), `gcc`, `busybox`, `sh`.

### Enter Docker Container
```bash
cd tgoskits
docker run -it --rm -v "$(pwd)":/workspace -w /workspace starryos-dev:ubuntu-qemu10.2.1
```

### Run a Single Test (Docker required)
```bash
cd tgoskits && docker run --rm -v "$(pwd)":/workspace -w /workspace starryos-dev:ubuntu-qemu10.2.1 cargo xtask starry test qemu --arch riscv64 -c <test-name>
```

### Build StarryOS (Docker required)
```bash
cd tgoskits && docker run --rm -v "$(pwd)":/workspace -w /workspace starryos-dev:ubuntu-qemu10.2.1 cargo xtask starry build --arch riscv64
```

### Run Linux Baseline (for comparison, no Docker needed)
```bash
gcc test-suit/starryos/normal/qemu-smp1/<test-name>/c/src/main.c -o /tmp/a.out && /tmp/a.out
```

## Agent Architecture

### Main Workflow Agents

| Agent | Trigger | Sub-agents called |
|-------|---------|-------------------|
| `debug-agent` | "fix the truncate bug", "debug test failure" | git-sync → test-runner → code-explorer → test-runner → pre-commit → pr-writer |
| `busybox-agent` | "fix busybox hwclock" | git-sync → test-runner → code-explorer → test-runner → pre-commit → pr-writer |
| `feature-agent` | "add mmap support" | git-sync → code-explorer → test-agent → test-runner → pre-commit → pr-writer |

### Supporting Sub-Agents (called by main agents)

| Agent | Purpose | Context risk |
|-------|---------|-------------|
| `git-sync-agent` | Sync dev with upstream, create work branch | Low — simple git operations |
| `code-explorer-agent` | Research Linux behavior, search kernel source, trace impl paths, strace profiles | **Absorbs heavy code reading** |
| `test-runner-agent` | Run tests (Linux baseline or Docker QEMU), parse output, return PASS/FAIL summary | **Absorbs QEMU boot logs** |
| `test-agent` | Write C test cases (delegates research + execution to sub-agents) | Low — focused on writing test code |
| `pre-commit-agent` | Run fmt + clippy + sync-lint + std tests | Low — output is short |
| `pr-writer` | Compose structured PR, rebase, push, create PR | Low — template-based |

## Workflow Overview

### 1. Bug Fix (debug-agent)
```
git-sync-agent → test-runner (baseline + QEMU) → code-explorer (trace + research)
→ implement fix → test-runner (verify) → pre-commit-agent → pr-writer
```

### 2. Busybox Fix (busybox-agent)
```
git-sync-agent → grep + fetch test → append to script → test-runner (baseline + QEMU)
→ code-explorer (strace + trace) → fix → test-runner (verify) → pre-commit-agent → pr-writer
```

### 3. Feature Development (feature-agent)
```
git-sync-agent → code-explorer (research spec) → design → test-agent (write tests)
→ implement → test-runner (QEMU) → pre-commit-agent → pr-writer
```

### Test Suite Structure
```
tgoskits/test-suit/starryos/
  normal/qemu-smp1/
    test-<name>/
      c/
        src/main.c    # Test source
        Makefile       # Build rules
      config.json      # Test configuration
```

## Coding Conventions for this Project

- **Test-first**: Write C test cases that validate Linux behavior before fixing StarryOS
- **Linux parity**: StarryOS should match Linux syscall behavior (error codes, edge cases)
- **PR structure**: Follow the template in `templates/pr-bugfix.md` — include Bug Location, Root Cause, Before/After test results, and Fix code
- **Rust conventions**: Follow StarryOS kernel conventions (use `AxError`, `LinuxError` for error mapping)
- **Test naming**: `test-<syscall-name>/` with `c/src/main.c` as entry point
