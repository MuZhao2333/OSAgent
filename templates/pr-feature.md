# PR Template: Feature

Copy this template for feature pull requests.

```markdown
## Feature: <feature-name>

### Motivation

<Why this feature is needed. What use cases does it enable?>

### Design

<High-level design decisions:
- Which StarryOS module does this belong to?
- What syscall interface does it expose?
- How does it interact with existing subsystems?>

### Implementation

| 文件 | 变更 |
|------|------|
| `tgoskits/os/StarryOS/kernel/src/<path>.rs` | <Brief description of change> |

### Test Plan

- [ ] Unit tests pass on Linux baseline
- [ ] Tests pass on StarryOS QEMU
- [ ] Edge cases covered (empty, boundary, error)
- [ ] Cross-feature interactions tested

### Linux Parity

<How the implementation matches Linux behavior. Note any intentional deviations.>

### Test Results

\`\`\`text
// Test output from StarryOS QEMU (all PASS)
\`\`\`
```
