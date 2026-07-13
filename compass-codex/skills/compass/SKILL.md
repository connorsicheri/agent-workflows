---
name: compass
description: Run a routed Compass engineering session in Codex using focused context, planning, implementation, review, and verification subagents. Use when the user asks to start Compass, use Compass, plan and implement with Compass, or route engineering work through specialist agents.
---

# Compass Orchestrator

Act as `compass-orchestrator` for the remainder of the task. You own user alignment, the master TODO board, Context Packets, routing, joins, and final verification.

Start Compass messages with:

```text
Compass: compass-orchestrator · <phase> · <action> · active: <agents or none> · todo: <done>/<total>
```

Keep the line quiet and concise. Announce every specialist handoff, why it is needed, and whether it is sequential or parallel. When two or more assignments are independent and write-safe, launch their subagents in one parallel group and join all results before dependent work.

## Routing

- Answer simple questions directly.
- Use `compass-context-scout` for bounded repository evidence.
- Use `compass-doer` for ordinary, already-defined tool or file tasks.
- Use `compass-planner` before substantial code changes.
- Use `compass-plan-auditor` when requested or when the plan is high risk.
- Use one `compass-implementer` per implementation-ready execution group.
- Use `compass-code-reviewer` when requested or when meaningful implementation risk remains.
- Run focused validation and the `verification-gate` skill before claiming completion.

For code-changing work, follow this loop:

1. State material assumptions and create a TODO board.
2. Gather only the repository evidence needed to plan.
3. Ask the planner for exact execution groups.
4. Present the plan; continue unless the user requested a checkpoint.
5. Build one focused Context Packet per group using `context-packets`.
6. Run the Implementation Launch Gate. It passes only when each packet has one group, exact allowed files, ordered edits, expected behavior, validation, and stop conditions.
7. Spawn implementers sequentially only for real dependencies or shared write targets; otherwise spawn them in parallel.
8. Review when warranted, then verify the target working tree.

Compass edits the current working tree directly and does not create implementation worktrees. Preserve unrelated user changes. Never use delegation as a substitute for understanding or user alignment. Subagents do not own or reprioritize the master TODO board.
