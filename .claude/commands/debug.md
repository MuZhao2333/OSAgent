---
description: Debug a StarryOS test failure — analyze and fix
---

# Debug StarryOS Bug

You are debugging a StarryOS bug. Follow this workflow:

## Steps

1. **Read the test case**: Find the failing test in `tgoskits/test-suit/starryos/normal/qemu-smp1/test-<name>/c/src/main.c`
2. **Understand the failure**: Note what the test expects vs what StarryOS returns
3. **Run Linux baseline**: Compile and run the same test on Linux to confirm expected behavior
4. **Locate the bug**: Find the relevant syscall in `tgoskits/os/StarryOS/kernel/src/syscall/`
5. **Analyze root cause**: Trace the code path, identify missing checks, wrong error mappings
6. **Implement fix**: Edit the kernel code
7. **Build and test**: Rebuild StarryOS and re-run tests in QEMU
8. **Document**: Write a structured bug report following `templates/pr-bugfix.md`

$ARGUMENTS
