---
description: Run a StarryOS test in Docker QEMU and report results
---

# Run StarryOS Test

Run a test case against StarryOS in the Docker QEMU environment.

## Steps

1. **Identify the test name** (e.g., `test-truncate`, `test-pipe-syscall`)
2. **Run the test**:
```bash
cd tgoskits
cargo xtask starry test qemu --arch riscv64 -c <test-name>
```
3. **Parse the output**: Identify PASS and FAIL lines
4. **If failures exist**: Compare with the expected Linux baseline (compile and run the C test directly on WSL)
5. **Report**: Summarize pass/fail counts and list any failures

$ARGUMENTS
