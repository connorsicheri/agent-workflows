---
description: Internal Compass workflow for bugs, failing tests, runtime errors, regressions, and unclear failures.
---

# Debugging

Use this workflow for bugs and failures.

1. Reproduce or identify the failure.
2. Use `compass-log-digester` if logs are verbose.
3. Use `compass-test-runner` if focused validation is needed.
4. Use `compass-context-scout` if relevant code paths are unclear.
5. Send compressed evidence to `compass-planner`.
6. Align the fix plan with the user.
7. Use `compass-implementer`.
8. Validate with focused tests.
9. If tests fail twice for unclear reasons, stop and re-plan.

Evidence required before planning:

- Failing behavior.
- Expected behavior.
- Minimal error excerpt.
- Relevant files.
- Suspected root cause.
- Confidence level.
- Unknowns.

Prefer the smallest fix that addresses the root cause.
