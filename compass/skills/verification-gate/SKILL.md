---
description: Internal Compass checklist for validating work before declaring a task complete.
---

# Verification Gate

Use this after implementation and before the final response.

Required checks:

1. Compare the implementation against the approved plan.
2. Confirm no unrelated files were changed.
3. Run focused tests when available.
4. Use `compass-test-runner` for verbose test output.
5. Use `compass-log-digester` for noisy errors.
6. Identify unverified assumptions.
7. Identify remaining risks.

Final report format:

```md
## What Changed

- File:
- Change:

## Validation

- Command:
- Result:

## Plan Adherence

- Followed approved plan:
- Deviations:

## Remaining Risks

- Risk:
- Suggested follow-up:
```
