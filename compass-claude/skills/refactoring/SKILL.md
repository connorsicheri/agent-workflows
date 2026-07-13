---
description: Internal Compass workflow for behavior-preserving refactors and cleanup.
---

# Refactoring

Use this workflow for behavior-preserving changes.

1. Use `compass-context-scout` to map the affected area.
2. Send compressed evidence to `compass-planner`.
3. Have the planner define the refactor boundary.
4. Present the plan to the user.
5. Use `compass-implementer`.
6. Run focused validation.

The planner must define:

- What behavior must stay unchanged.
- What files are in scope.
- What files are out of scope.
- What tests should pass.
- What risks exist.
- What stop conditions apply.

The implementer must not introduce new features. If implementation requires
behavior changes, stop and return to the user.
