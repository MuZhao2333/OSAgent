# OSAgent

StarryOS kernel development framework — structured workflows for debugging, feature development, and testing.

## 目录结构

```
OSAgent/
├── CLAUDE.md                    # Claude Code 自动加载的项目上下文
├── README.md                    # 本文件
├── .claude/
│   ├── agents/                  # 自定义 Agent
│   │   ├── debug-agent.md       #   调试 Agent
│   │   ├── feature-agent.md     #   功能开发 Agent
│   │   ├── test-agent.md        #   测试 Agent
│   │   └── pr-writer.md         #   PR 撰写 Agent
│   └── commands/                # 自定义 Slash Commands
│       ├── start-work.md        #   /start-work — 同步 git，创建开发分支
│       ├── pre-commit.md         #   /pre-commit — 提交前轻量 CI
│       ├── debug.md             #   /debug — 调试 StarryOS bug
│       ├── test.md              #   /test — 创建测试用例
│       ├── build.md             #   /build — 构建内核
│       ├── run-test.md          #   /run-test — 运行 QEMU 测试
│       ├── pr.md                #   /pr — 撰写 PR
│       └── open-pr.md           #   /open-pr — Push 并创建 PR
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

1. **开始工作前**: `/start-work` — 确保 `local/dev` = `origin/dev` = `upstream/dev`，再从 `dev` 开新分支
2. **分支命名**: Bugfix → `fix/<name>`，Feature → `feat/<name>`
3. **PR 目标**: 所有 PR 提交到 `upstream/dev` (rcore-os/tgoskits)
4. **提 PR 前**: rebase 到最新 `upstream/dev`，通过 `/pre-commit`

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

### Slash Commands

| 命令 | 用途 |
|------|------|
| `/start-work` | 同步 git (local=origin=upstream), 创建 fix/feat 分支 |
| `/pre-commit` | 提交前轻量 CI 检查 (fmt, clippy, sync-lint, std test) |
| `/debug <bug-name>` | 分析并修复 StarryOS bug |
| `/test <syscall>` | 为 syscall 创建 C 测试用例 |
| `/run-test <test-name>` | 在 QEMU 中运行测试 |
| `/build` | 重新构建 StarryOS 内核 |
| `/pr` | 撰写结构化 PR |
| `/open-pr` | Push 分支并创建 PR 到 upstream/dev |

### Agents

| Agent | 用途 |
|-------|------|
| `debug-agent` | 系统化定位、分析和修复 kernel bug |
| `feature-agent` | 设计和实现新的 syscall 或内核功能 |
| `test-agent` | 编写 C 测试用例，对比 Linux vs StarryOS 行为 |
| `pr-writer` | 按项目模板撰写结构化 PR |

## 典型工作流

### Bug 修复
```
/start-work          → 同步 git, 创建 fix/<name> 分支
/test <syscall>      → 编写测试用例
Run on Linux         → 建立基线
/run-test <name>     → 在 StarryOS 运行，观察失败项
/debug <name>        → 分析根因，修复代码
/build               → 重新构建
/run-test <name>     → 验证修复 (全部 PASS)
/pre-commit          → fmt + clippy + sync-lint + std test
Commit               → 提交
/open-pr             → Push + 创建 PR 到 upstream/dev
```

### 功能开发
```
/start-work          → 同步 git, 创建 feat/<name> 分支
Research Linux       → 查阅 man pages，了解预期行为
/test <syscall>      → 先写测试 (TDD)
feature-agent        → 在 StarryOS 中实现
/build && /run-test  → QEMU 验证
/pre-commit          → fmt + clippy + sync-lint + std test
Commit               → 提交
/open-pr             → Push + 创建 PR 到 upstream/dev
```

## PR 模板结构

Bug 修复 PR 包含 11 个部分：
1. Bug 总结 → 2. 发现路径 → 3. Bug 位置表 → 4. 修复前代码 → 5. 根因分析 → 6. 影响范围 → 7. 测例路径 → 8. 修复前测试结果 → 9. 期望行为( Linux 基线 ) → 10. 修复代码 → 11. 修复后测试结果

详见 `templates/pr-bugfix.md`。

## Claude Code 插件

### 已注册 Marketplace

| Marketplace | 来源 | 添加方式 |
|---|---|---|
| `claude-plugins-official` | `anthropics/claude-plugins-official` | 系统预置 |
| `anthropic-agent-skills` | `anthropics/skills` | `/plugin marketplace add anthropics/skills` |

### 已安装插件

| 插件 | 来源 | 用途 |
|------|------|------|
| `skill-creator@claude-plugins-official` | 官方 | 创建和优化 skill |
| `code-review@claude-plugins-official` | 官方 | PR 代码审查 |
| `github@claude-plugins-official` | 官方 | GitHub 操作 |
| `code-simplifier@claude-plugins-official` | 官方 | 代码简化 |
| `rust-analyzer-lsp@claude-plugins-official` | 官方 | Rust LSP 支持 |

### 复现步骤

```bash
# 1. 添加 marketplace
/plugin marketplace add anthropics/skills

# 2. 浏览并安装插件
/plugin browse claude-plugins-official
#   → 依次安装: skill-creator, code-review, github, code-simplifier, rust-analyzer-lsp

# 3. 重载
/reload-plugins
```
