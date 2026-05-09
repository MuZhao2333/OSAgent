#!/bin/bash
# StarryOS Cargo Xtask Helper

TGOSKITS_DIR="/mnt/d/OS/biglabB/OSAgent/tgoskits"

# Run a single test in QEMU
run_test() {
  local test_name=$1
  cd "$TGOSKITS_DIR"
  cargo xtask starry test qemu --arch riscv64 -c "$test_name"
}

# Build StarryOS
build() {
  cd "$TGOSKITS_DIR"
  cargo xtask starry build --arch riscv64
}

# Run C test on local Linux (baseline for comparison)
run_local() {
  local test_name=$1
  local test_dir="$TGOSKITS_DIR/test-suit/starryos/normal/qemu-smp1/$test_name/c"
  cd "$test_dir"
  gcc src/main.c -o /tmp/a.out && /tmp/a.out
}

# Usage examples:
#   run_test test-truncate       - Run truncate tests in StarryOS QEMU
#   build                        - Rebuild StarryOS
#   run_local test-truncate      - Compile & run test on WSL Linux (baseline)
