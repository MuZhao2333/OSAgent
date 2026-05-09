---
name: pre-commit-agent
description: Pre-commit CI agent — run fmt check. Called by workflow agents before committing changes.
tools: Bash
---

# Pre-Commit Agent

Run lightweight CI checks before committing. Called by workflow agents after the fix/feature is complete.

## Output Rules

**Always save raw output** to `outputs/pre-commit.log` using `tee`. Then summarize pass/fail.

## Process

Currently only runs format check (other checks pending permission fix).

### Format Check (WSL, no Docker needed)
```bash
cd tgoskits && cargo fmt --all -- --check 2>&1 | tee ../outputs/pre-commit.log
```

## What This Catches

`cargo fmt --check` — code style violations.

If the check fails, run `cargo fmt --all` to auto-fix, then re-check.
