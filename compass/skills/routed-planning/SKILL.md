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
   clearly required before planning. When the need splits into independent
   questions, fan out one scout per question in parallel (see Parallel
   Execution) and join their results.
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
11. Proceed to implementation unless the user asked for a manual checkpoint.
12. Split planned TODO items into execution groups, defaulting to parallel (see
    Parallel Execution).
13. Build a focused Context Packet for each subagent using the
    `context-packets` skill.
14. Use `compass-implementer` to execute the plan, launching write-safe groups
    in parallel.
15. If any implementer ran in an isolated worktree, use `compass-merge-agent`
    to review and integrate accepted changes onto the target branch. The
    orchestrator coordinates this handoff but does not perform the merge.
16. Use `compass-test-runner` or `compass-log-digester` for validation output.
17. Apply the verification gate before final response.

The orchestrator owns the master TODO Board. Subagents receive assigned TODO
items and report status back; they do not mutate or reprioritize the master
board.

## Worktree Integration

Treat isolated implementer worktrees as scratch state. The source of truth is
the user's target branch or working tree after accepted changes have been
integrated.

When an implementer returns worktree output, the next implementation step is a
sequential handoff to `compass-merge-agent` with:

- Target branch or working tree.
- Implementer worktree path.
- Changed files and diff summary.
- Allowed files and assigned plan excerpt.
- Validation already run by the implementer.
- Cleanup policy for the worktree. Default to clean up after successful
  integration unless the user asked to inspect the worktree.

`compass-merge-agent` owns integration judgment, conflict handling, and applying
accepted changes. It also owns cleanup for Compass-created worktrees after
successful integration. The orchestrator must not manually copy, cherry-pick,
merge, or clean up worktree changes.

## Parallel Execution

Default to parallel. This applies to both context gathering (multiple scouts for
independent questions), ordinary delegated work (one doer per independent write
target or external side effect), and implementation (one implementer per
write-safe execution group). Sequential is the deliberate exception, used only
when one unit's output feeds another, units touch the same files, they change a
shared public API, schema, or contract, or a sequential decision is required.

Do not bundle independent artifact creation and remote updates into a single
doer. A local artifact such as a walkthrough file and a remote change such as a
PR description update should be separate parallel `compass-doer` launches when
they share only the same source spec.

Concurrency requires the right launch shape: agents only run at the same time
when launched in a single message with one Agent tool call per agent. Agents
launched in separate messages run one after another regardless of how the
handoff is announced. Every announced parallel group must therefore be launched
as one message with one Agent call per member, and joined before dependent work
begins.

## Intake Before Search

Use intake when the user may have useful search context. Ask one or two focused
questions before launching `compass-context-scout`, especially when the user is
still describing the idea, choosing direction, or likely knows relevant files,
feature names, routes, errors, or recent changes.

Skip intake and launch context gathering when the user explicitly asks for repo
inspection, has already provided enough search guidance, says they do not know
where to look, or the task is risky enough that evidence is required before a
plan.

Context Packet format is defined in the `context-packets` skill. Use its base
packet plus the relevant agent-specific profile.

Planner Evidence Request format is defined in the `context-packets` skill.

Audit Packet format is defined in the `context-packets` skill.

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
