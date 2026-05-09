# OSAgent

StarryOS kernel development framework — structured workflows for debugging, feature development, and testing.

## 目录结构

```
OSAgent/
├── CLAUDE.md                    # Claude Code 自动加载的项目上下文
├── README.md                    # 本文件
├── .claude/
│   └── agents/                  # 自定义 Agent
│       ├── debug-agent.md       #   调试 Agent（主）
│       ├── busybox-agent.md     #   Busybox 调试 Agent（主）
│       ├── feature-agent.md     #   功能开发 Agent（主）
│       ├── git-sync-agent.md    #   Git 同步子 Agent
│       ├── code-explorer-agent.md # 代码探索子 Agent（研究+追踪）
│       ├── test-runner-agent.md #  测试运行子 Agent（Linux + QEMU）
│       ├── test-agent.md        #   测试编写 Agent
│       ├── pre-commit-agent.md  #   提交前 CI 子 Agent
│       └── pr-writer.md         #   PR 撰写+发布子 Agent
├── docs/
│   ├── environment.md           # Docker/QEMU 环境配置说明
│   └── workflow.md              # 工作流快速参考
├── templates/
│   ├── pr-bugfix.md             # Bug 修复 PR 模板
│   ├── pr-feature.md            # 功能开发 PR 模板
│   └── test-case.md             # C 测试用例模板
└── config/
    └── docker-helper.sh         # Docker 快捷命令
```

## Git 仓库关系

| 远程 | 地址 | 角色 |
|------|------|------|
| `origin` | `git@github.com:MuZhao2333/tgoskits.git` | 个人 fork |
| `upstream` | `git@github.com:rcore-os/tgoskits.git` | 上游主仓库 |

### Git 规范

1. **开始工作前**: 主 agent 调用 `git-sync-agent` — 确保 `local/dev` = `origin/dev` = `upstream/dev`，再从 `dev` 开新分支
2. **分支命名**: Bugfix → `fix/<name>`，Feature → `feat/<name>`
3. **PR 目标**: 所有 PR 由 `pr-writer` 提交到 `upstream/dev` (rcore-os/tgoskits)
4. **提 PR 前**: `pr-writer` rebase 到最新 `upstream/dev`，`pre-commit-agent` 通过 CI

## 准备工作

```bash
# 1. 克隆自己 fork 的 tgoskits 仓库
git clone git@github.com:MuZhao2333/tgoskits.git

# 2. 切换到 dev 分支
cd tgoskits && git checkout dev

# 3. 设置 upstream 为原始仓库
git remote add upstream git@github.com:rcore-os/tgoskits.git

# 4. 同步所有远程分支
git fetch --all
```

## 快速开始

### 运行环境

**注意**: 建议在 Docker 容器中执行。

```bash
cd tgoskits
docker run -it --rm -v "$(pwd)":/workspace -w /workspace starryos-dev:ubuntu-qemu10.2.1
```
然后运行测试：
```bash
cargo xtask starry test qemu --arch riscv64 -c <test-name>
```

### 主 Agent (描述任务即可自动调用)

| Agent | 用途 |
|-------|------|
| `debug-agent` | **Bug 修复**: 基线 → 追踪 → 修复 → 验证 → PR |
| `busybox-agent` | **Busybox 修复**: 取测试 → 脚本 → 基线 → strace → 修复 |
| `feature-agent` | **功能开发**: 研究 → 设计 → TDD 写测试 → 实现 → 验证 |

### 子 Agent (由主 Agent 自动调用)

| Agent | 用途 | 吸收的上下文 |
|-------|------|-------------|
| `git-sync-agent` | 同步 dev, 创建工作分支 | — |
| `code-explorer-agent` | 研究 Linux 行为, 追踪内核实现, strace 分析 | **大量代码阅读** |
| `test-runner-agent` | 运行测试 (Linux/QEMU), 返回 PASS/FAIL 摘要 | **QEMU 启动日志** |
| `test-agent` | 编写 C 测试用例 | — |
| `pre-commit-agent` | fmt + clippy + sync-lint + std test | — |
| `pr-writer` | 撰写 PR, rebase, push, 创建 PR | — |

## 典型工作流

### Bug 修复 (debug-agent)
```
git-sync-agent         → 同步 git, 创建 fix/<name> 分支
test-runner-agent      → Linux 基线 (WSL)
test-runner-agent      → StarryOS QEMU 确认失败
code-explorer-agent    → 研究 Linux spec + 追踪内核实现 + 定位根因
  (main agent 实施修复)
test-runner-agent      → 验证修复 (Docker QEMU)
pre-commit-agent       → CI 检查
pr-writer              → 提交, PR, push
```

### Busybox Bugfix (busybox-agent)
```
git-sync-agent         → 同步 git, 创建 fix/<name> 分支
  (main agent: grep + fetch issue + 追加测试)
test-runner-agent      → WSL 基线
test-runner-agent      → QEMU 确认失败
code-explorer-agent    → strace + 追踪内核 + 定位修复
  (main agent 实施修复)
test-runner-agent      → 验证修复
pre-commit-agent       → CI 检查
pr-writer              → 提交, PR, push
```

### 功能开发 (feature-agent)
```
git-sync-agent         → 同步 git, 创建 feat/<name> 分支
code-explorer-agent    → 研究 Linux 行为
  (main agent: 设计)
test-agent             → 写测试用例
  (main agent: 实现)
test-runner-agent      → 构建 + QEMU 测试
pre-commit-agent       → CI 检查
pr-writer              → 提交, PR, push
```

## Claude Code 插件

### 已安装插件

| 插件 | 来源 | 用途 |
|------|------|------|
| `skill-creator@claude-plugins-official` | 官方 | 创建和优化 skill |
| `code-review@claude-plugins-official` | 官方 | PR 代码审查 |
| `github@claude-plugins-official` | 官方 | GitHub 操作 |
| `code-simplifier@claude-plugins-official` | 官方 | 代码简化 |
| `rust-analyzer-lsp@claude-plugins-official` | 官方 | Rust LSP 支持 |
