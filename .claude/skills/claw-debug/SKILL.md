---
name: claw-debug
description: Iteratively debug and fix StarryOS kernel to pass the claw-code/integration test. Only modify kernel code, never test cases or claw-code. No commits.
---

# Claw-Code Debug Workflow

Iteratively fix StarryOS kernel issues blocking the `claw-code/integration` test case.
**Only modify StarryOS kernel source.** Never modify test cases or claw-code. No commits needed.

## Core Loop

```
Run test (sub-agent) → Analyze failure (main session) → Trace & fix kernel (main session) → Record progress (main session) → Repeat until PASS
```

Main session drives analysis and editing. Sub-agents only for running tests and targeted code lookups.

## Step 1: Run Integration Test

Use the test-runner-agent to run the test in Docker QEMU:

```
Agent(subagent_type="test-runner-agent", description="Run claw-code integration test", prompt="Build StarryOS and run the claw-code/integration test case in Docker QEMU. Command: cd tgoskits && docker run --rm -v \"$(pwd)\":/workspace -w /workspace starryos-dev:ubuntu-qemu10.2.1 bash -c \"rustup toolchain install nightly-2026-04-27 && cargo xtask starry test qemu --arch riscv64 -c claw-code/integration\" 2>&1 | tee ../outputs/app-port-claw-code/integration-test-v<N>.log. Increment N each run. Report: PASS/FAIL, which test step failed, and key output (exit codes, error messages).")
```

The main session reads `outputs/app-port-claw-code/integration-test-v<N>.log` for detailed analysis.

## Step 2: Analyze Failure

Read the test output log. Determine which test(s) failed:

- **Smoke/Diagnostic failure** (steps 1-2): Binary can't start → basic syscall or ELF loading issue
- **Network diagnostic failure** (steps 3-6): DNS/HTTP/HTTPS broken → network stack issue
- **Functional failure EXIT:-1** (step 7): claw hangs at `Thinking...` → async I/O (epoll/tokio) issue
- **Functional failure non-zero exit**: claw crashed or returned error → check stderr output
- **Kernel panic**: Check panic message for root cause

## Step 3: Trace Root Cause

The **main session** drives the analysis. Use code-explorer-agent only for targeted lookups (find a symbol, grep a keyword, locate an implementation). The main session reads the relevant source files, traces the logic, and determines the root cause.

Typical flow:
1. Main session reads the test log, identifies the failing step and error pattern
2. Main session uses `grep` / `Glob` / code-explorer-agent to locate relevant kernel code
3. Main session reads the source files directly with `Read`
4. Main session traces the logic chain and identifies the root cause
5. Main session formulates the fix

For targeted lookups only, use code-explorer-agent:
```
Agent(subagent_type="code-explorer-agent", description="Find specific implementation", prompt="Search tgoskits/os/ for <specific symbol/file/pattern>. Quick lookup only — report file path and line number.")
```

## Step 4: Implement Kernel Fix

Edit the relevant kernel source file(s) directly. Key constraints:

- **ONLY modify files under `tgoskits/os/`** (kernel, arceos modules)
- **NEVER modify** `tgoskits/test-suit/` or application code
- Follow StarryOS conventions: `AxError::from(LinuxError::XXX)` for errors
- Validate inputs early before main logic
- Return `AxResult<isize>` for syscalls

## Step 5: Verify Fix

Use the test-runner-agent again with incremented version number:

```
Agent(subagent_type="test-runner-agent", description="Verify fix in QEMU", prompt="Build StarryOS and run the claw-code/integration test case in Docker QEMU (version N+1). Command: cd tgoskits && docker run --rm -v \"$(pwd)\":/workspace -w /workspace starryos-dev:ubuntu-qemu10.2.1 bash -c \"rustup toolchain install nightly-2026-04-27 && cargo xtask starry test qemu --arch riscv64 -c claw-code/integration\" 2>&1 | tee ../outputs/app-port-claw-code/integration-test-v<N+1>.log. Report: PASS/FAIL, which test step passed/failed, key output.")
```

- If fix works: previously failing test now passes, continue to next failure
- If fix doesn't work: analyze new output, go to Step 2
- If fix causes regression: revert and try different approach

## Step 6: Record Progress

After each iteration (whether fix worked or not), append to `outputs/app-port-claw-code/progress.md`:

```markdown
- **2026-05-11 HH:MM** — Iteration #N. Test: integration-test-v<N>.log.
  - Finding: <what was wrong>
  - Fix: <what was changed, file path>
  - Result: <PASS/FAIL — which test step>
```

Keep entries concise. This builds a complete debugging trail.

## Step 7: Iterate

Continue the loop until all tests pass with `ALL_TESTS_DONE`.

### Test execution order (fail-fast):

| Order | Test | Current Status |
|-------|------|---------------|
| 1 | Smoke: `claw --help` | PASS |
| 2 | Diagnostic: `claw version` | PASS |
| 3 | Network: resolv.conf | PASS |
| 4 | Network: DNS lookup | PASS |
| 5 | Network: HTTPS (wget) | PASS |
| 6 | Network: HTTP (wget) | PASS |
| 7 | Functional: `claw prompt 'hello'` | **FAIL** |
| 8 | Tool: `claw --allowedTools bash prompt 'echo hello world'` | Blocked by #7 |
| 9 | Project: `claw create file` | Blocked by #7 |
| 10 | Project: `claw C compile & run` | Blocked by #7 |

## Known Issue: Async I/O

The current blocker is async I/O (reqwest/tokio via epoll). Key files:

- `tgoskits/os/arceos/modules/axnet-ng/src/device/ethernet.rs` — `register_waker()` is no-op without IRQ
- `tgoskits/os/arceos/modules/axnet-ng/src/service.rs` — `register_waker()` may not set fallback poll timer
- `tgoskits/os/StarryOS/kernel/src/syscall/io_mpx/epoll.rs` — epoll implementation
- `tgoskits/os/StarryOS/kernel/src/file/epoll.rs` — epoll file operations

Blocking I/O (wget) works. The fix must ensure epoll wakers are triggered when network data arrives, even without IRQ.
