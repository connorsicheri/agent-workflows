---
description: Internal Compass checklist for validating work before declaring a task complete.
---

# Verification Gate

Use this after implementation and before the final response.

Required checks:

1. Compare the implementation against the assigned plan.
2. Confirm no unrelated files were changed.
3. Run focused tests when available.
4. Reduce verbose output to the smallest useful error excerpts.
5. Identify unverified assumptions.
6. Identify remaining risks.

Final report format:

```md
## What Changed

- File:
- Change:

## Validation

- Command:
- Result:

## Plan Adherence

- Followed assigned plan:
- Deviations:

## Remaining Risks

- Risk:
- Suggested follow-up:
```
