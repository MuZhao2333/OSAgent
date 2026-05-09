---
description: Run lightweight CI checks before committing — fmt, clippy, sync-lint, std tests
---

# Pre-Commit Checks

Run the lightweight subset of CI checks before committing. These are fast and catch the most common issues.

## Steps

### 1. Format Check
```bash
cd tgoskits
cargo fmt --all -- --check
```

### 2. Clippy Lint
```bash
cd tgoskits
cargo xtask clippy
```

### 3. Sync Lint
```bash
cd tgoskits
cargo xtask sync-lint
```

### 4. Unit Tests (std)
```bash
cd tgoskits
cargo xtask test
```

## Quick One-Liner
```bash
cd tgoskits && cargo fmt --all -- --check && cargo xtask clippy && cargo xtask sync-lint && cargo xtask test
```

## What These Catch

| Check | Catches |
|-------|---------|
| `cargo fmt` | Code style violations |
| `cargo xtask clippy` | Common Rust mistakes, idiomatic issues |
| `cargo xtask sync-lint` | Sync/mutex usage issues |
| `cargo xtask test` | Unit test failures (std, no QEMU needed) |

If all four pass, the code is ready to commit. For full validation, CI also runs QEMU tests across riscv64/aarch64/loongarch64/x86_64 — but those are heavy and run in CI, not pre-commit.

$ARGUMENTS
