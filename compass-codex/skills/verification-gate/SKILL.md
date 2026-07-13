---
name: verification-gate
description: Verify Compass work before completion by checking scope, diffs, validation evidence, and unresolved risk.
---

# Compass Verification Gate

Before declaring a task complete:

1. Compare the result with the user request and accepted plan.
2. Inspect the final diff and confirm unrelated user changes were preserved.
3. Run the narrowest relevant tests, lint, type checks, builds, or contract checks.
4. Confirm every TODO item is done or explicitly reported as blocked.
5. Confirm review findings are resolved or disclosed.
6. Report what was validated and any remaining uncertainty.

Do not claim success from an implementer report alone. Verification evidence must come from the target working tree.
