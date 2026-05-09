# StarryOS Environment Setup

## Prerequisites

- WSL2 with Docker Desktop
- Docker image: `starryos-dev:ubuntu-qemu10.2.1`

## Commands

All commands are run from the `tgoskits/` directory using `cargo xtask`.

### Run a Single Test
```bash
cd tgoskits
cargo xtask starry test qemu --arch riscv64 -c <test-name>
```
Example: `cargo xtask starry test qemu --arch riscv64 -c test-pipe-syscall`

### Build StarryOS
```bash
cargo xtask starry build --arch riscv64
```

### Run Linux Baseline (for comparison)
```bash
cd tgoskits
gcc test-suit/starryos/normal/qemu-smp1/<test-name>/c/src/main.c -o /tmp/a.out && /tmp/a.out
```
