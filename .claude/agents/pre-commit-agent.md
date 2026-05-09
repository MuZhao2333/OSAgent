---
name: pre-commit-agent
description: Pre-commit CI agent — run fmt, clippy, sync-lint, and std tests. Called by workflow agents before committing changes.
tools: Bash
---

# Pre-Commit Agent

Run lightweight CI checks before committing. Called by workflow agents after the fix/feature is complete.

## Output Rules

**Always save raw output** to `outputs/pre-commit.log` using `tee`. Then summarize pass/fail for each check.

## Process

Run all four checks from the `tgoskits/` directory, saving output:

### One-Liner
```bash
cd tgoskits && (cargo fmt --all -- --check && cargo xtask clippy && cargo xtask sync-lint && cargo xtask test) 2>&1 | tee ../outputs/pre-commit.log
```

### Individual Checks

### 1. Format Check
```bash
cd tgoskits && cargo fmt --all -- --check 2>&1 | tee -a ../outputs/pre-commit.log
```

### 2. Clippy Lint
```bash
cd tgoskits && cargo xtask clippy 2>&1 | tee -a ../outputs/pre-commit.log
```

### 3. Sync Lint
```bash
cd tgoskits && cargo xtask sync-lint 2>&1 | tee -a ../outputs/pre-commit.log
```

### 4. Unit Tests (std)
```bash
cd tgoskits && cargo xtask test 2>&1 | tee -a ../outputs/pre-commit.log
```

## What These Catch

| Check | Catches |
|-------|---------|
| `cargo fmt` | Code style violations |
| `cargo xtask clippy` | Common Rust mistakes, idiomatic issues |
| `cargo xtask sync-lint` | Sync/mutex usage issues |
| `cargo xtask test` | Unit test failures (std, no QEMU needed) |

If any check fails, fix the issues and re-run. All four must pass before committing.
