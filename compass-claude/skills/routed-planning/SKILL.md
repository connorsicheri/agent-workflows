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
5. Ask one or more `compass-planner` agents to produce or refine a plan. When
   the planning problem has independent domains, separable risks, or competing
   viable approaches, fan out planner lanes in parallel and join their reports.
6. Use `compass-complex-planner` only when the user explicitly asks for the
   complex planner, Fable planner, or deep planning mode. Do not infer this
   route from task size, risk, ambiguity, or failed attempts.
7. If the planner returns a Planner Evidence Request, add a TODO item, build a
   targeted Context Packet, retrieve the requested evidence, and return that
   evidence to the planner.
8. Repeat the planner/evidence loop until the planner can produce a reliable
   plan, asks a user question, or reaches a stop condition.
9. If the user asks to audit the plan, or the plan is high-risk, build an Audit
   Packet and use `compass-plan-auditor`.
10. Route audit findings before implementation.
11. Present the plan and TODO Board to the user.
12. Proceed to implementation unless the user asked for a manual checkpoint.
13. Split planned TODO items into execution groups, defaulting to parallel (see
    Parallel Execution).
14. Build a focused Context Packet for each subagent using the
    `context-packets` skill.
15. Use `compass-implementer` to execute the plan, launching write-safe groups
    in parallel.
16. After all implementation groups have joined, use the single
    `compass-pr-reviewer` on the complete integrated target working tree diff
    when review is needed before final verification. Never use it for an
    intermediate execution group.
17. Run focused validation and apply the verification gate before final
    response.

The orchestrator owns the master TODO Board. Subagents receive assigned TODO
items and report status back; they do not mutate or reprioritize the master
board.

## Direct Implementation

Compass does not create implementation worktrees. The source of truth is the
user's target branch or current working tree, and every `compass-implementer`
packet must target that working tree directly.

Do not route implementation through a separate integration agent. Do not ask a
Compass subagent to create scratch worktrees, copy changes between worktrees,
cherry-pick, merge, or integrate isolated implementation output. When review is
needed before final verification, wait for every implementation group to join,
then use `compass-pr-reviewer` against the complete integrated target working
tree diff.

## Parallel Execution

Default to parallel. This applies to planning (one planner per independent
planning lane or competing option), context gathering (multiple scouts for
independent questions), ordinary delegated work (one doer per independent write
target, artifact, command, repository object, or external side effect), and
implementation (one implementer per write-safe execution group). Sequential is
the deliberate exception, used only when one unit's output feeds another, units
touch the same files, they change a shared public API, schema, or contract, or a
sequential decision is required.

Before any handoff, run a fan-out check. If the work contains two or more
independent units, split them into separate packets and launch them together.
Do not use a single broad planner, doer, scout, or implementer packet for
convenience when independent packets would let the agents work in parallel.

`compass-complex-planner` is not a risk-triggered escalation path. Use it only
when the user explicitly directs Compass to use the complex planner, Fable
planner, or deep planning mode, and include that explicit direction in the
Context Packet. Otherwise use `compass-planner`.

Do not bundle independent artifact creation, inspections, summaries, command
runs, or file updates into a single doer. Do not assign remote writes to doers
from the Claude sandbox. For requests such as pushing a branch, opening a PR,
editing a PR body, or commenting on a remote issue, prepare local state, draft
the remote update text, and report the exact command for the user to run outside
the sandbox.

Implementation handoffs must be code-ready before launch. The planner and
orchestrator own decomposition: each `compass-implementer` packet must include
exact allowed files, ordered edit steps, expected behavior change, validation
command, and stop conditions. If those details are missing, gather more evidence
or return to `compass-planner`; do not ask the implementer to figure out how to
split the work, choose an approach, find write targets, or define completion.

Run the Implementation Launch Gate before any implementer Agent call. The gate
passes only when implementation mode is direct target branch/current working
tree, every implementer packet maps to one execution group or tightly coupled
sequential slice, and no packet assigns "all groups", "Groups 1-N", "all
steps", or the whole plan. A plan with five or more independent execution groups
should launch at least five scoped implementers across its parallel group(s)
unless concrete dependencies force fewer.

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
