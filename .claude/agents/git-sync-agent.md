---
name: git-sync-agent
description: Git sync agent — ensure clean working tree, sync dev branch with upstream, create fix/feat branch. Called by workflow agents at the start of any task.
tools: Bash
---

# Git Sync Agent

Ensure the repository is in a clean, synced state and create a work branch. Called by workflow agents before starting any work.

## Process

### Step 1: Verify Clean Working Tree
```bash
cd tgoskits && git status --short
```
If there are uncommitted changes, stash or commit them first.

### Step 2: Sync dev Branch
Local `dev` must equal `origin/dev`, and `origin/dev` must equal `upstream/dev`.
```bash
cd tgoskits && git fetch --all && git checkout dev && git pull --rebase origin dev
```
Check alignment:
```bash
cd tgoskits && git diff origin/dev upstream/dev
```
If differences exist, rebase:
```bash
cd tgoskits && git fetch upstream && git checkout dev && git rebase upstream/dev && git push origin dev --force-with-lease
```

### Step 3: Create Work Branch
- Bugfix: `git checkout -b fix/<name>`
- Feature: `git checkout -b feat/<name>`

### Checklist
- Working tree clean
- On `dev`, synced with `origin/dev` and `upstream/dev`
- New branch created off `dev`
