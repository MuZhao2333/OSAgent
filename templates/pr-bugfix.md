# PR Template: Bug Fix

Copy this template for bug fix pull requests.

```markdown
## Bug: <syscall_name> — <one-line summary>

<2-3 sentence description of what is broken and in which scenarios.>

### 发现路径

<How the bug was found: code review, test comparison between Linux and StarryOS, etc.>

### Bug 位置

| 项目 | 值 |
|------|-----|
| 文件 | `tgoskits/os/StarryOS/kernel/src/syscall/<module>/<file>.rs` |
| 行号 | <start>–<end> |
| 函数 | `sys_<name>` |

**修复前:**

\`\`\`rust
// Original broken code
\`\`\`

### 根因分析

<For each sub-bug, a paragraph explaining:
1. What input/scenario triggers it
2. Why the current code fails (missing check? wrong error code? logic error?)
3. How Linux handles the same scenario>

### 影响范围

<Describe the impact:
- Security implications (if any)
- Application compatibility
- Cross-platform behavior differences>

### 测例路径

- `tgoskits/test-suit/starryos/normal/qemu-smp1/test-<name>/`

### 修改前测试结果 (StarryOS riscv64 QEMU)

\`\`\`text
// Output showing FAIL lines
\`\`\`

### 期望行为 (Linux/WSL 验证结果)

\`\`\`text
// Output from Linux showing all PASS
\`\`\`

### 修复

\`\`\`rust
// Fixed code with changes annotated
\`\`\`

### 修复后测试结果 (StarryOS riscv64 QEMU)

\`\`\`text
// Output showing all PASS after fix
\`\`\`
```
