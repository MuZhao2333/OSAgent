# OSAgent - StarryOS Development Framework

## Project Purpose

This project provides a structured framework for debugging, feature development, and maintenance of **StarryOS** (a Rust-based OS kernel). It defines skills (workflows) and sub-agents to make StarryOS development systematic and reproducible.

Architecture: **Skills define step-by-step workflows. The main session calls sub-agents at each step.** No nesting — all agent calls come from the top-level session. Sub-agents do one job, save output to `outputs/`, and return.

## Repo Structure — Two Repos

```
/home/chenzitao/OSAgent/          ← Framework repo (this project)
├── .claude/
│   ├── agents/                   ← Sub-agents (single-purpose)
│   └── skills/                   ← Workflow skills (step-by-step)
├── CLAUDE.md                     ← Project instructions
├── outputs/                      ← Saved test results
├── docs/ / templates/ / config/  ← Framework docs & templates
└── tgoskits/                     ← tgoskits repo (SEPARATE clone)
    ├── .git/                     ← tgoskits's own git
    ├── os/StarryOS/              ← Kernel source
    └── test-suit/                ← Test suite
```

**All `cd tgoskits &&` commands operate on the nested tgoskits repo.** Git operations target `tgoskits/`, NOT the framework root.

## tgoskits Git Remotes (inside `tgoskits/`)

| Remote | URL | Role |
|--------|-----|------|
| `origin` | `git@github.com:MuZhao2333/tgoskits.git` | Personal fork |
| `upstream` | `git@github.com:rcore-os/tgoskits.git` | Upstream main repo |

## Key Paths

| Path | Purpose |
|------|---------|
| `tgoskits/` | tgoskits repo root (separate git clone) |
| `tgoskits/os/StarryOS/kernel/src/` | StarryOS kernel source |
| `tgoskits/test-suit/starryos/` | Test cases for StarryOS |
| `outputs/` | All test/log outputs saved here |
| `.claude/agents/` | Sub-agents |
| `.claude/skills/` | Workflow skills |

## Architecture

### Workflow Skills (invoked by main session)

| Skill | Purpose |
|-------|---------|
| `busybox-fix` | Fix a busybox applet: fetch test → baseline → QEMU → strace → fix → verify → PR |
| `debug-fix` | Fix a kernel bug: baseline → QEMU → trace → fix → verify → PR |
| `feature-dev` | New feature: research → design → test → implement → verify → PR |
| `app-port` | Port a large app: profile → plan → implement sub-goals incrementally → integrate → PR |

### Sub-Agents (called by main session at each step)

| Agent | Purpose | Output |
|-------|---------|--------|
| `git-sync-agent` | Sync dev, create work branch | — |
| `test-runner-agent` | Run Linux baseline or Docker QEMU test | `outputs/<test>-<env>.log` |
| `code-explorer-agent` | Research Linux, trace kernel, strace profile | `outputs/<name>-strace.log` |
| `test-agent` | Write C test cases | — |
| `pre-commit-agent` | Run fmt + clippy + sync-lint + std tests | `outputs/pre-commit.log` |
| `pr-writer` | Compose PR, rebase, push, create PR | — |
| `app-profiler-agent` | Profile target app, strace analysis, gap report vs StarryOS | `outputs/app-port-<name>/profile.log` |

### How It Works

1. User asks: "fix busybox blockdev"
2. Main session invokes `busybox-fix` skill (loads workflow instructions)
3. Main session follows each step, calling sub-agents via `Agent(...)` tool
4. Each sub-agent does its job, saves output to `outputs/`, returns summary
5. Main session makes decisions (e.g., what to fix based on code-explorer's report)
6. All heavy output (QEMU, strace) stays in sub-agent context + `outputs/` files

## Environment: How to Run Code

All commands are executed from the `tgoskits/` directory.

**Critical**: All `cargo` commands that compile (clippy, test, xtask starry) **must** run inside the Docker container `starryos-dev:ubuntu-qemu10.2.1`. Docker builds write root-owned files to `target/`, so running outside Docker causes "Permission denied" errors.

Commands that run directly on WSL (no Docker needed): `cargo fmt --check` (no-compile), `gcc`, `busybox`, `sh`, `git`.

### Run a Single Test (Docker required)
```bash
cd tgoskits && docker run --rm -v "$(pwd)":/workspace -w /workspace starryos-dev:ubuntu-qemu10.2.1 cargo xtask starry test qemu --arch riscv64 -c <test-name>
```

### Run Linux Baseline (WSL, no Docker needed)
```bash
gcc test-suit/starryos/normal/qemu-smp1/<test-name>/c/src/main.c -o /tmp/a.out && /tmp/a.out
```

## Git Workflow Rules

1. Before any work: call `git-sync-agent` to sync `tgoskits/` dev branch and create a work branch
2. Branch naming: Bugfix → `fix/<name>`, Feature → `feat/<name>`
3. PR target: `upstream/dev` (rcore-os/tgoskits)
4. Before PR: `pre-commit-agent` must pass
5. Never add `Co-Authored-By` trailers — commits are authored by the human developer only

## Coding Conventions

- **Test-first**: Write C test cases that validate Linux behavior before fixing StarryOS
- **Linux parity**: StarryOS should match Linux syscall behavior (error codes, edge cases)
- **PR structure**: Follow `templates/pr-bugfix.md` or `templates/pr-feature.md`. Never include AI-branding lines. Always fill in actual code diffs and test results from `outputs/`.
- **Rust conventions**: `AxError::from(LinuxError::XXX)` for error mapping

## Critical Rule: Fix the Kernel, Not the Test

**Never modify a test case to make it pass.** The test cases from issue #13 are the source of truth — they define correct behavior. If a test fails, the bug is in the kernel, and the fix must be in the kernel code. Modifying tests to bypass failures is cheating and masks real bugs.

- Test commands and verification patterns from issue #13 are authoritative
- If a test command contains `...` as a placeholder, fill in only the minimal setup needed (e.g., creating test files), but do NOT change the applet invocation or verification logic
- The goal is Linux parity: the same test should pass on both Linux and StarryOS
- If a test passes on Linux but fails on StarryOS, there is a kernel bug to fix
