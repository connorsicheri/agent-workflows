---
description: Internal Compass workflow for feature work, code changes, and general implementation tasks.
---

# Routed Planning

Use this workflow for code-changing tasks inside a Compass session.

1. Classify the task.
2. Gather context with `compass-context-scout` if relevant files or behavior are
   unclear.
3. Ask `compass-planner` to produce or refine a plan.
4. Present the plan to the user.
5. Wait for approval unless the user explicitly authorized proceeding without
   another approval gate.
6. Use `compass-implementer` to execute the approved plan.
7. Use `compass-test-runner` or `compass-log-digester` for validation output.
8. Apply the verification gate before final response.

Classify as:

- Trivial edit.
- Focused bug fix.
- Broad investigation.
- Refactor.
- Architecture decision.
- Security-sensitive change.
- Migration or data model change.
- Public API change.

Stop and return to the user if the implementation scope or risk changes
materially.
