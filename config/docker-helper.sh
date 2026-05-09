#!/bin/bash
# StarryOS Cargo Xtask Helper — wraps cargo xtask starry commands in Docker

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TGOSKITS_DIR="$(cd "$SCRIPT_DIR/../../tgoskits" && pwd)"
DOCKER_IMG="starryos-dev:ubuntu-qemu10.2.1"

# Run a single test in Docker QEMU
run_test() {
  local test_name=$1
  cd "$TGOSKITS_DIR"
  docker run --rm -v "$(pwd)":/workspace -w /workspace "$DOCKER_IMG" \
    cargo xtask starry test qemu --arch riscv64 -c "$test_name"
}

# Build StarryOS in Docker
build() {
  cd "$TGOSKITS_DIR"
  docker run --rm -v "$(pwd)":/workspace -w /workspace "$DOCKER_IMG" \
    cargo xtask starry build --arch riscv64
}

# Run C test on local Linux (baseline, no Docker needed)
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
