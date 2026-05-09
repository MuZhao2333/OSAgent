# OSAgent - StarryOS Development Framework

## Project Purpose

This project provides a structured framework for debugging, feature development, and maintenance of **StarryOS** (a Rust-based OS kernel) via the tgoskits test suite. It defines workflows, agents, commands, and templates to make StarryOS development systematic and reproducible.

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
| `.claude/commands/` | Custom slash commands |
| `docs/` | Workflow and environment documentation |
| `templates/` | PR and test case templates |

## Git Workflow Rules

**Before starting any work, always run `/start-work`** to ensure:

1. Working tree is clean
2. On `dev` branch, and local `dev` == `origin/dev` == `upstream/dev`
3. A new branch is created off `dev` for the current task

### Branch Naming
- Bugfix: `fix/<name>` (e.g., `fix/truncate-validation`)
- Feature: `feat/<name>` (e.g., `feat/mmap-support`)

### PR Target
- All PRs target `upstream/dev` (rcore-os/tgoskits)
- Before creating PR, rebase onto latest `upstream/dev`: `git fetch upstream && git rebase upstream/dev`
- Use `/open-pr` to push and create the PR

## Environment: How to Run Code

All commands are executed from the `tgoskits/` directory using `cargo xtask`:

```bash
cd tgoskits
```

### Pre-Commit Checks (Lightweight CI)
Run these before every commit — fast, no QEMU needed:

```bash
cargo fmt --all -- --check    # Code formatting
cargo xtask clippy             # Rust linting
cargo xtask sync-lint          # Sync/Mutex usage checks
cargo xtask test               # Unit tests (std)
```

One-liner: `cargo fmt --all -- --check && cargo xtask clippy && cargo xtask sync-lint && cargo xtask test`

### Run a Single Test
```bash
cargo xtask starry test qemu --arch riscv64 -c <test-name>
```
Example: `cargo xtask starry test qemu --arch riscv64 -c test-pipe-syscall`

### Build StarryOS
```bash
cargo xtask starry build --arch riscv64
```

### Run Linux Baseline (for comparison)
```bash
# Compile and run the C test case directly on WSL
gcc test-suit/starryos/normal/qemu-smp1/<test-name>/c/src/main.c -o /tmp/a.out && /tmp/a.out
```

## Workflow Overview

### Debug Workflow
0. **`/start-work`** — sync dev, create `fix/<name>` branch
1. Identify the bug location in StarryOS source
2. Write/update a C test case in `tgoskits/test-suit/starryos/`
3. Run baseline on Linux/WSL: `gcc test.c && ./a.out`
4. Run in StarryOS QEMU: `cargo xtask starry test qemu --arch riscv64 -c <test-name>`
5. Compare results: identify mismatched error codes and behaviors
6. Fix the kernel code
7. Rebuild and re-test until all tests pass
8. **`/pre-commit`** — run fmt, clippy, sync-lint, std tests
9. Commit the fix
10. **`/open-pr`** — rebase onto upstream/dev, push, create PR to upstream/dev

### Feature Development Workflow
0. **`/start-work`** — sync dev, create `feat/<name>` branch
1. Design the feature and identify affected syscalls/modules
2. Check Linux behavior for the expected API contract
3. Write test cases first (TDD)
4. Implement in StarryOS kernel
5. Verify against Linux baseline
6. **`/pre-commit`** — run fmt, clippy, sync-lint, std tests
7. Commit
8. **`/open-pr`** — rebase onto upstream/dev, push, create PR to upstream/dev

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
