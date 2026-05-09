# StarryOS Environment Setup

## Prerequisites

- WSL2 with Docker Desktop
- Docker image: `starryos-dev:ubuntu-qemu10.2.1`

## Docker Requirement

All `cargo xtask starry` commands (build, test qemu) **must** run inside the Docker container. The container provides the riscv64 toolchain and QEMU runtime that StarryOS depends on.

Commands that run directly on WSL (no Docker needed):
- `gcc` / compiling C test cases for Linux baseline
- `busybox` / `sh` for running busybox-tests.sh
- `grep`, `git`, and other standard tools

## Commands

All commands are run from the `tgoskits/` directory.

### Enter Docker Container (interactive)
```bash
cd tgoskits
docker run -it --rm -v "$(pwd)":/workspace -w /workspace starryos-dev:ubuntu-qemu10.2.1
```
Once inside, run `cargo xtask starry ...` commands directly.

### Run a Single Test (one-liner)
```bash
cd tgoskits && docker run --rm -v "$(pwd)":/workspace -w /workspace starryos-dev:ubuntu-qemu10.2.1 cargo xtask starry test qemu --arch riscv64 -c <test-name>
```
Example: `cd tgoskits && docker run --rm -v "$(pwd)":/workspace -w /workspace starryos-dev:ubuntu-qemu10.2.1 cargo xtask starry test qemu --arch riscv64 -c test-pipe-syscall`

### Build StarryOS
```bash
cd tgoskits && docker run --rm -v "$(pwd)":/workspace -w /workspace starryos-dev:ubuntu-qemu10.2.1 cargo xtask starry build --arch riscv64
```

### Run Linux Baseline (for comparison, no Docker needed)
```bash
gcc test-suit/starryos/normal/qemu-smp1/<test-name>/c/src/main.c -o /tmp/a.out && /tmp/a.out
```
