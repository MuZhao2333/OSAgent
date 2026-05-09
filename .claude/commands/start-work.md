---
description: Ensure git state is clean and synced before starting work — dev branch alignment, upstream sync
---

# Start Work: Sync Git State

Before any bugfix or feature work, ensure the repository is in a clean, synced state.

## Step 1: Verify Clean Working Tree

```bash
cd tgoskits
git status --short
```

If there are uncommitted changes, stash or commit them first.

## Step 2: Sync dev Branch

Local `dev` must equal `origin/dev`, and `origin/dev` must equal `upstream/dev`.

```bash
git fetch --all

# Switch to dev
git checkout dev

# Sync with origin
git pull --rebase origin dev

# Check if origin/dev matches upstream/dev
git diff origin/dev upstream/dev
```

If `git diff origin/dev upstream/dev` shows differences, the fork is out of date:

```bash
# Rebase onto upstream
git fetch upstream
git checkout dev
git rebase upstream/dev
git push origin dev --force-with-lease
```

## Step 3: Create Feature/Fix Branch

All bugfix and feature work must happen on a new branch off `dev`.

### Bugfix
```bash
git checkout dev
git checkout -b fix/<bug-name>
```

### Feature
```bash
git checkout dev
git checkout -b feat/<feature-name>
```

## Summary Checklist

- [ ] Working tree clean (`git status`)
- [ ] On `dev` branch
- [ ] `origin/dev` is up to date with `upstream/dev` (`git diff origin/dev upstream/dev` is empty)
- [ ] New branch created off `dev` for the current task
- [ ] Branch naming: `fix/<name>` for bugfix, `feat/<name>` for feature

## PR Target

All pull requests target `upstream/dev` (rcore-os/tgoskits dev branch).

$ARGUMENTS
