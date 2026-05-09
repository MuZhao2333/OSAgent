# StarryOS Development Workflow

## Quick Reference

| Task | Agent | Description |
|------|-------|-------------|
| **Bug Fix** | `debug-agent` | Baseline → trace → fix → verify → PR |
| **Busybox Fix** | `busybox-agent` | Fetch test → script → baseline → strace → fix |
| **New Feature** | `feature-agent` | Research → design → TDD → implement → verify |
| **New Test** | `test-agent` | Write C test cases, delegate run + compare to sub-agents |

### Sub-Agents (called by main agents)

| Agent | Called by | Purpose |
|-------|-----------|---------|
| `git-sync-agent` | All main (Step 0) | Sync dev, create fix/feat branch |
| `code-explorer-agent` | debug, busybox, feature | Research Linux, trace kernel, strace profile |
| `test-runner-agent` | All main | Run tests (Linux or QEMU), return clean summary |
| `test-agent` | feature (optional) | Write C test cases |
| `pre-commit-agent` | All main (pre-commit) | Run fmt, clippy, sync-lint, std tests |
| `pr-writer` | All main (final step) | Compose PR, rebase, push, create PR |

## Git Workflow

### 仓库关系

| 远程 | 地址 | 角色 |
|------|------|------|
| `origin` | `git@github.com:MuZhao2333/tgoskits.git` | 个人 fork |
| `upstream` | `git@github.com:rcore-os/tgoskits.git` | 上游主仓库 |

### 核心规则

1. **开始工作前**: 主 agent 调用 `git-sync-agent` — local `dev` = `origin/dev` = `upstream/dev`，然后从 `dev` 开新分支
2. **分支命名**: Bugfix 用 `fix/<name>`，Feature 用 `feat/<name>`
3. **PR 目标**: 所有 PR 由 `pr-writer` 提交到 `upstream/dev` (rcore-os/tgoskits)
4. **提 PR 前**: `pr-writer` rebase 到最新 `upstream/dev`，`pre-commit-agent` 通过 CI 检查

## Full Workflows

### Bug Fix (debug-agent)

```
git-sync-agent              → Sync dev, create fix/<name> branch
test-runner-agent           → Linux baseline (compile + run on WSL)
test-runner-agent           → StarryOS QEMU confirm (build + test in Docker)
code-explorer-agent         → Research Linux spec + trace StarryOS impl + find root cause
  (main agent implements fix)
test-runner-agent           → Verify fix (build + test in Docker)
pre-commit-agent            → fmt + clippy + sync-lint + std tests
pr-writer                   → Compose PR, rebase, push, create PR to upstream/dev
```

### Busybox Bugfix (busybox-agent)

```
git-sync-agent              → Sync dev, create fix/<name> branch
  (main agent: grep script, fetch issue, append test)
test-runner-agent           → Linux busybox baseline (WSL)
test-runner-agent           → StarryOS QEMU confirm (Docker)
code-explorer-agent         → strace profile + trace StarryOS impl + find fix
  (main agent implements fix)
test-runner-agent           → Verify fix (build + test in Docker)
pre-commit-agent            → fmt + clippy + sync-lint + std tests
pr-writer                   → Compose PR, rebase, push, create PR
```

### Feature Development (feature-agent)

```
git-sync-agent              → Sync dev, create feat/<name> branch
code-explorer-agent         → Research Linux behavior (man page, kernel source)
  (main agent: design architecture)
test-agent                  → Write C test cases (TDD)
  (main agent: implement feature)
test-runner-agent           → Build + test in Docker QEMU
pre-commit-agent            → fmt + clippy + sync-lint + std tests
pr-writer                   → Compose PR, rebase, push, create PR
```

## Test Suite Pattern

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
