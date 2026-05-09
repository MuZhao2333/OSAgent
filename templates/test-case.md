# Test Case Template

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>

// ================================================
//  TEST: <syscall_name>
//  FILE: test-<name>/c/src/main.c
// ================================================

int main() {
    int ret;
    int fd;
    char template[] = "/tmp/test_XXXXXX";

    // ---- Normal cases ----

    // Test 1: Basic functionality
    fd = mkstemp(template);
    if (fd < 0) { perror("mkstemp"); return 1; }
    // ... test logic ...
    printf("  PASS | line:%d | description\n", __LINE__);
    close(fd);

    // ---- Edge cases ----

    // Test: Boundary values
    // Test: Empty input
    // Test: Maximum values

    // ---- Error cases ----

    // Test: Invalid input → expected errno
    // Test: Permission denied → expected errno
    // Test: Bad fd → expected errno

    // ---- Cross-feature interactions ----

    // Test: With symlinks
    // Test: With directories
    // Test: With pipes

    printf("\\n------------------------------------------------\\n");
    printf("  DONE: N pass, M fail\\n");
    return 0;
}
```

## Test Categories Checklist

When writing a test case, cover ALL applicable categories:

- [ ] **Normal usage**: Does the syscall work as intended?
- [ ] **Empty/null inputs**: What happens with `""`, `NULL`, `0`?
- [ ] **Negative values**: `-1`, `INT_MIN`, etc.
- [ ] **Boundary values**: `0`, `MAX`, `MAX+1`
- [ ] **Invalid fd**: Closed fd, out-of-range fd, wrong type fd
- [ ] **Permission errors**: Read-only, no access
- [ ] **File/directory conflicts**: Path is dir, path component is file
- [ ] **Non-existent paths**: Missing file, broken symlink
- [ ] **Symlinks**: Behavior through symlinks
- [ ] **Special files**: `/dev/null`, pipes, sockets
- [ ] **Multiple operations**: Repeated calls, interleaved calls
