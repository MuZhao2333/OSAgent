---
description: Create a new test case for a StarryOS syscall
---

# Create Test Case

Create a C test case for a StarryOS syscall. Follow this process:

1. **Choose the target syscall** (e.g., `truncate`, `openat`, `mmap`)
2. **Research Linux behavior**: Check man pages for expected error codes and edge cases
3. **Write the test**: Create `tgoskits/test-suit/starryos/normal/qemu-smp1/test-<name>/c/src/main.c`
4. **Include these test categories**:
   - Normal usage (happy path)
   - Edge cases (empty, boundary values, zero, max)
   - Error conditions (invalid inputs → specific errno)
   - Cross-feature interactions (symlinks, directories, pipes)
5. **Run on Linux first** to verify test correctness
6. **Run on StarryOS QEMU** to find gaps

$ARGUMENTS
