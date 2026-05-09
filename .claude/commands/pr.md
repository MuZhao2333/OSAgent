---
description: Compose a structured PR for a StarryOS bugfix or feature
---

# Compose PR

Compose a pull request for StarryOS. Follow the exact template from `templates/pr-bugfix.md` for bug fixes or `templates/pr-feature.md` for features.

## For Bug Fixes

Include ALL of these sections:
1. **Bug summary** (one line)
2. **发现路径** (how you found it)
3. **Bug 位置** table (file, line, function)
4. **修复前** code block (original broken code)
5. **根因分析** (root cause — one paragraph per sub-issue, with "why")
6. **影响范围** (impact analysis)
7. **测例路径** (test case path)
8. **修改前测试结果** (before: StarryOS QEMU output with FAIL lines)
9. **期望行为** (expected: Linux baseline output with all PASS)
10. **修复** (the fixed code)
11. **修复后测试结果** (after: StarryOS QEMU output with all PASS)

## For Features

Include: Motivation, Design, Implementation (file + description per change), Test Plan, Linux Parity notes.

$ARGUMENTS
