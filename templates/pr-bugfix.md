# PR Template: Bug Fix

```markdown
## Bug: <one-line summary>

<One-paragraph description of the bug and its impact.>

### Root Cause

<Which file, which function, what was missing/wrong.>

### Before Fix (code diff)

```diff
<key hunks from git diff>
```

### Test Results

**Before (StarryOS QEMU):**
```
<actual failure output>
```

**After (StarryOS QEMU):**
```
<actual success output>
```

### Changes

- `<file1>`: <what changed>
- `<file2>`: <what changed>
```
