---
description: Internal Compass workflow for feature work, code changes, and general implementation tasks.
---

# Routed Planning

Use this workflow for code-changing tasks inside a Compass session.

1. Classify the task.
2. Create the master Compass TODO Board.
3. Run a short intake chat before launching subagents unless the user explicitly
   asks for immediate repository inspection.
4. Gather context with `compass-context-scout` only when intake produces enough
   search guidance, the user asks for deep search, or repository evidence is
   clearly required before planning.
5. Ask `compass-planner` to produce or refine a plan.
6. If the planner returns a Planner Evidence Request, add a TODO item, build a
   targeted Context Packet, retrieve the requested evidence, and return that
   evidence to the planner.
7. Repeat the planner/evidence loop until the planner can produce a reliable
   plan, asks a user question, or reaches a stop condition.
8. If the user asks to audit the plan, or the plan is high-risk, build an Audit
   Packet and use `compass-plan-auditor`.
9. Route audit findings before implementation.
10. Present the plan and TODO Board to the user.
11. Wait for approval unless the user explicitly authorized proceeding without
   another approval gate.
12. Split approved TODO items into sequential and parallel execution groups.
13. Build a focused Context Packet for each subagent.
14. Use `compass-implementer` to execute the approved plan.
15. Use `compass-test-runner` or `compass-log-digester` for validation output.
16. Apply the verification gate before final response.

The orchestrator owns the master TODO Board. Subagents receive assigned TODO
items and report status back; they do not mutate or reprioritize the master
board.

## Intake Before Search

Use intake when the user may have useful search context. Ask one or two focused
questions before launching `compass-context-scout`, especially when the user is
still describing the idea, choosing direction, or likely knows relevant files,
feature names, routes, errors, or recent changes.

Skip intake and launch context gathering when the user explicitly asks for repo
inspection, has already provided enough search guidance, says they do not know
where to look, or the task is risky enough that evidence is required before a
plan.

Context Packet format:

```md
## Context Packet

- Parent task:
- Assigned TODO item:
- Agent:
- Model tier:
- Goal:
- In scope:
- Out of scope:
- Relevant files/evidence:
- Constraints:
- Stop conditions:
- Expected return format:
```

Planner Evidence Request format:

```md
## Planner Evidence Request

- Question to answer:
- Why it matters:
- Suggested agent:
- Suggested scout target:
- Files, symbols, or search terms:
- Constraints:
- Stop condition:
- Expected evidence:
```

Audit Packet format:

```md
## Audit Packet

- Parent task:
- User request:
- Current plan:
- TODO Board:
- Context Packets:
- Evidence summaries:
- Planner assumptions:
- Files likely involved:
- Execution groups:
- Risk checks:
- Stop conditions:
- Known constraints:
- Expected audit output:
```

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
