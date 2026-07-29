---
description: Internal Compass workflow for auditing a proposed plan against available context before implementation.
---

# Plan Audit

Use this workflow when:

- The user asks to "audit the plan", "review the plan", "stress test the plan",
  "check the plan", or similar.
- The plan touches architecture, public APIs, schemas, migrations, auth,
  permissions, or security-sensitive code.
- The planner has low confidence.
- Implementation already hit a plan conflict.
- The orchestrator wants independent review before execution.

The orchestrator owns routing and TODO state.

## Sequence

1. Add a TODO item for plan audit.
2. Build an Audit Packet for `compass-plan-auditor` using the
   `context-packets` skill.
3. Copy the user request and complete proposed plan without editorializing.
   Add only explicit authoritative constraints and direct source references.
   Do not add suspected issues, risk summaries, likely findings, or a review
   agenda.
4. Launch `compass-plan-auditor`.
5. Route the audit result:
   - `pass`: proceed to user alignment or implementation.
   - `pass-with-notes`: show notes and proceed unless the notes require a
     plan revision.
   - `needs-revision`: return to `compass-planner`.
   - `needs-more-context`: launch the requested scout/log/test agent.
   - `block`: stop with the blocking reason and recommended next step.

Audit Packet format is defined in the `context-packets` skill.

If the auditor requests more evidence, the orchestrator treats it like a planner
evidence request: add a TODO item, create a targeted Context Packet, retrieve
the evidence, and return it to the auditor.
