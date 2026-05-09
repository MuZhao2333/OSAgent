# StarryOS Development Workflow

## Quick Reference

| Task | Command/Agent | Description |
|------|--------------|-------------|
| Start Work | `/start-work` | Sync git state, ensure dev branch aligned, create work branch |
| Pre-Commit | `/pre-commit` | Run lightweight CI checks (fmt, clippy, sync-lint, std test) |
| Debug | `/debug` or `debug-agent` | Analyze and fix a bug |
| New Test | `/test` or `test-agent` | Create a C test case |
| Run Test | `/run-test` | Execute tests via `cargo xtask starry test qemu` |
| Build | `/build` | Rebuild StarryOS kernel |
| Compose PR | `/pr` or `pr-writer` | Write a structured PR |
| Open PR | `/open-pr` | Push and create PR targeting upstream/dev |
| New Feature | `feature-agent` | Design and implement features |

## Git Workflow

### 仓库关系

| 远程 | 地址 | 角色 |
|------|------|------|
| `origin` | `git@github.com:MuZhao2333/tgoskits.git` | 个人 fork |
| `upstream` | `git@github.com:rcore-os/tgoskits.git` | 上游主仓库 |

### 核心规则

1. **开始工作前**：`/start-work` — local `dev` = `origin/dev` = `upstream/dev`，然后从 `dev` 开新分支
2. **分支命名**：Bugfix 用 `fix/<name>`，Feature 用 `feat/<name>`
3. **PR 目标**：所有 PR 提交到 `upstream/dev` (rcore-os/tgoskits)
4. **提 PR 前**：rebase 到最新 `upstream/dev`，通过 `/pre-commit`

### 同步检查清单

```bash
# 1. 确认工作区干净
git status

# 2. 获取所有远程
git fetch --all

# 3. 切换到 dev 并同步 origin
git checkout dev
git pull --rebase origin dev

# 4. 确认 origin/dev 与 upstream/dev 一致
git diff origin/dev upstream/dev
#    (如有差异 → rebase onto upstream/dev)

# 5. 创建新分支
git checkout -b fix/<bug-name>    # bugfix
git checkout -b feat/<feat-name>  # feature
```

## Pre-Commit Flow

Before every commit, run the lightweight CI checks. These mirror what CI runs but are fast (no QEMU boot):

```bash
cd tgoskits
cargo fmt --all -- --check    # 1. Formatting
cargo xtask clippy             # 2. Lint
cargo xtask sync-lint          # 3. Sync lint
cargo xtask test               # 4. Unit tests (std)
```

Or as a one-liner:

```bash
cd tgoskits && cargo fmt --all -- --check && cargo xtask clippy && cargo xtask sync-lint && cargo xtask test
```

| Check | What It Catches |
|-------|-----------------|
| `cargo fmt --all -- --check` | Code style violations |
| `cargo xtask clippy` | Common Rust mistakes, unidiomatic code |
| `cargo xtask sync-lint` | Sync/Mutex usage issues |
| `cargo xtask test` | Unit test failures (no QEMU needed) |

If all four pass, push and let CI handle the heavy QEMU tests (starry/axvisor/arceos across riscv64/aarch64/loongarch64/x86_64).

## Full Workflows

### Bug Fix Workflow

```
0. /start-work             → Sync dev, create fix/<name> branch
1. /test <syscall>          → Write/update C test case
2. Run on Linux             → Establish baseline behavior
3. /run-test <name>         → Run in StarryOS QEMU, observe failures
4. /debug <name>            → Analyze failures, locate bug, fix code
5. /build                   → Rebuild kernel
6. /run-test <name>         → Verify fix (all PASS)
7. /pre-commit              → Run fmt, clippy, sync-lint, std tests
8. Commit                   → Ready to push
9. /open-pr                 → Push branch, create PR to upstream/dev
```

### Feature Workflow

```
0. /start-work             → Sync dev, create feat/<name> branch
1. Research Linux behavior  → Man pages, kernel source
2. /test <syscall>          → Write tests first (TDD)
3. Run on Linux             → Verify test correctness
4. feature-agent            → Implement in StarryOS
5. /build && /run-test      → Build & verify in QEMU
6. /pre-commit              → Run fmt, clippy, sync-lint, std tests
7. Commit                   → Ready to push
8. /open-pr                 → Push branch, create PR to upstream/dev
```

### Test Suite Pattern

Tests live under `tgoskits/test-suit/starryos/normal/qemu-smp1/test-<name>/`. Each test has:
- `c/src/main.c` — C test source using assertion macros
- `c/Makefile` — Build rules
- `config.json` — Test metadata (if needed)

## Error Code Quick Reference

| errno | Constant | Common Cause |
|-------|----------|-------------|
| 2 | ENOENT | File not found, empty path |
| 9 | EBADF | Invalid/bad file descriptor |
| 13 | EACCES | Permission denied |
| 20 | ENOTDIR | Path component is not a directory |
| 21 | EISDIR | Path is a directory (but file expected) |
| 22 | EINVAL | Invalid argument |
| 27 | EFBIG | File too large |
