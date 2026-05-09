---
description: Open a PR targeting upstream/dev with the current branch changes
---

# Open Pull Request

Push the current branch and open a pull request to `upstream/dev`.

## Prerequisites

- Pre-commit checks pass: `/pre-commit`
- Commits are on a `fix/<name>` or `feat/<name>` branch off `dev`
- Branch is rebased onto latest `upstream/dev`

## Steps

### 1. Sync and rebase
```bash
cd tgoskits
git fetch upstream
git rebase upstream/dev
```

### 2. Run pre-commit (if not already done)
```bash
cargo fmt --all -- --check && cargo xtask clippy && cargo xtask sync-lint && cargo xtask test
```

### 3. Push branch
```bash
git push origin HEAD
```

### 4. Create PR
Use the `gh` CLI to create a PR targeting `upstream/dev`:
```bash
gh pr create \
  --base dev \
  --repo rcore-os/tgoskits \
  --title "<title>" \
  --body "$(cat <<'EOF'
## Bug: <summary>  (or ## Feature: <summary>)

<Follow the PR template from templates/pr-bugfix.md or templates/pr-feature.md>
EOF
)"
```

Or create via GitHub web UI, ensuring the base repository is `rcore-os/tgoskits` and branch is `dev`.

$ARGUMENTS
