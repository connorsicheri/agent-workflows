# Compass for Claude Code

Compass is a Claude Code plugin that turns a chat workspace into a routed
engineering session.

When Compass is active, the main chat runs as `compass-orchestrator`. The
orchestrator coordinates focused agents for ordinary task execution, context
gathering, planning, implementation, code review, and final verification.

## Launching

Compass is most reliable when the orchestrator is the main-thread agent, set at
launch. Launched that way, `compass-orchestrator` owns the session with a durable
identity: its system prompt stays active every turn and survives long
conversations and context compaction.

From the repository root on POSIX shells:

```bash
./compass-claude/scripts/compass
./compass-claude/scripts/compass advanced
```

From PowerShell:

```powershell
.\compass-claude\scripts\compass.ps1
.\compass-claude\scripts\compass.ps1 advanced
```

The launcher expands those commands to Claude CLI invocations using the local
plugin directory. To inspect the exact command:

```bash
./compass-claude/scripts/compass --print-launch
```

```powershell
.\compass-claude\scripts\compass.ps1 --print-launch
```

The launchers expand to the equivalent direct Claude commands:

```bash
claude --plugin-dir ./compass-claude --agent compass:compass-orchestrator
claude --plugin-dir ./compass-claude --agent compass:compass-advanced-orchestrator
```

### Re-centering with `/compass`

```text
/compass
```

`/compass` does not launch the orchestrator as the main-thread agent. The
main-thread agent can only be set at launch. It recenters the current chat on
the Compass workflow as a one-shot prompt, which can fade over a long session.
Use it when a session was not launched as `compass-orchestrator`, or to reaffirm
the role mid-session. It cannot switch an already-running session into advanced
mode; start a new session with `compass advanced` instead.

## Local Testing

After launching with one of the commands above, confirm:

- `@compass-orchestrator` or `@compass-advanced-orchestrator` appears in the
  startup header and is the session agent.
- The Compass agents appear in `/agents`.
- A task that changes code produces a plan before implementation, then proceeds
  without an extra Compass checkpoint unless the user requests one.

## Design

Compass keeps normal Claude Code sessions unaffected. It only changes behavior
for chats where the plugin is loaded or enabled.

The role boundaries are:

- `compass-orchestrator`: Sonnet 5 1M max main session agent and user-facing
  router.
- `compass-advanced-orchestrator`: Opus medium advanced main session agent and
  user-facing router.
- `compass-doer`: Sonnet 4.6 1M general execution for ordinary delegated tasks.
- `compass-context-scout`: read-only codebase discovery.
- `compass-planner`: read-only planning and user-alignment support.
- `compass-complex-planner`: Fable max read-only planning for explicit complex,
  Fable, or deep-planning requests only.
- `compass-plan-auditor`: Opus max independent read-only plan audit.
- `compass-code-reviewer`: independent read-only review of implemented code,
  diffs, branches, worktrees, or PR changes.
- `compass-implementer`: Sonnet 4.6 1M scoped implementation from an assigned
  plan.

The `context-packets` skill defines how `compass-orchestrator` injects focused
context into each subagent type.

Compass should not launch context gathering reflexively. The orchestrator starts
with a short intake chat when the user may have search hints or wants to talk
through the task first. It launches `compass-context-scout` after the user asks
for investigation, provides enough search guidance for a targeted packet, says
they do not know where to look, or the planner/auditor needs evidence.

For simple and nuanced questions, explanations, tradeoff discussion,
architecture or product reasoning, debugging theory, or "help me think this
through" requests, the orchestrator answers directly. If repository evidence is
needed, it routes a targeted `compass-context-scout` packet first.

After presenting a plan, Compass should not drift into generic "I'll start
implementing" narration or ask for another checkpoint by default. The
orchestrator announces a visible handoff and launches scoped
`compass-implementer` agents directly in the target working tree, with one
implementer per write-safe execution group. For ordinary tool-using tasks that
are not implementation plans, it launches `compass-doer`.

For PR, branch, worktree, local diff, or file-list walkthrough requests, Compass
routes to `compass-doer` with the `change-walkthrough` skill. The default output
is a local `local-notes/<slug>.html` reviewer artifact. PR body updates are
separate explicit tasks and should be split into a separate doer when requested
alongside the walkthrough.

Compass does not create implementation worktrees. Implementation happens
directly in the target branch or current working tree. When extra confidence is
needed before verification, Compass routes the target working tree diff to
`compass-code-reviewer`.

Compass does not attempt remote publishing from the Claude sandbox. For actions
such as `git push`, opening or editing PRs, or posting remote comments, Compass
prepares local state, drafts the remote update text, and reports the exact
command for the user to run outside the sandbox.

## Visibility

Compass should make routing visible instead of hiding it.

Compass uses a quiet inline status line by default:

```text
Compass: compass-orchestrator · planning · relaying planner update · active: compass-planner · todo: 1/4
```

The status line should stay plain and low-emphasis; it should never use HTML
tags, Markdown emphasis, a pipe-delimited banner, heading, table, or multi-line
panel.

At session start, Compass also announces:

```text
Compass active. You are speaking with compass-orchestrator.
```

## TODO Ownership

`compass-orchestrator` owns the master Compass TODO Board.

Subagents receive assigned TODO items and focused context. They report status
back to the orchestrator, but they do not own or reprioritize the master board.

Expanded board example:

```text
Compass TODO Board
- [done] Context scan checkout validation paths
- [active] Planner drafts scoped implementation plan
- [queued] Implement validation helper
- [queued] Add validation tests
- [blocked] Resolve plan conflict
```

Before launching a subagent, the orchestrator prepares a Context Packet from
`compass-claude/skills/context-packets/SKILL.md`: the base packet plus the relevant
subagent profile.

Every Context Packet goes through the cheap Packet Quality Checklist in that
skill. Only broad, ambiguous, high-risk, or implementation-driving packets
escalate to Packet Review, where `compass-plan-auditor` checks the packet
against the user request, TODO Board, evidence summaries, assumptions, and
intended receiving agent before the handoff.

Compass defaults to parallel. When units of work have no shared write targets
and no data dependency, the orchestrator runs them at the same time and joins
their results before continuing: one planner per independent planning lane or
competing option, one doer per independent ordinary task, one implementer per
write-safe execution group, and one context scout per independent question.
Work stays sequential only when one unit's output feeds another, the units touch
the same files, or a sequential decision is required. Concurrency comes from
launching the group in a single message with one agent call per member; a group
launched one agent per message would run sequentially instead.

## Planner-Requested Evidence

The planner is not stuck with the first context scan. If it needs more evidence,
it returns a Planner Evidence Request to the orchestrator using the format in
`context-packets`.

The orchestrator then adds a TODO item, creates a targeted Context Packet,
launches the requested agent, and returns the compressed evidence to the
planner. When the planner returns several independent evidence requests, or the
context need splits into separate questions, the orchestrator fans out one scout
per question in parallel and joins their results before replying to the planner.
The planner/evidence loop repeats until the planner can produce a good plan, asks
the user a question, or hits a stop condition.

## Plan Audits

The user can ask Compass to audit a plan with phrases like:

```text
audit the plan
review the plan
stress test the plan
check the plan
```

Compass routes that to `compass-plan-auditor` with an Audit Packet containing
the current plan, TODO Board, stored context, evidence summaries, assumptions,
risks, execution groups, and stop conditions.

Audit results are:

- `pass`
- `pass-with-notes`
- `needs-revision`
- `needs-more-context`
- `block`

Before subagent work, Compass announces the handoff:

```text
Compass handoff: compass-context-scout
Purpose: find the checkout validation code paths.
Mode: sequential
```

After subagent work, it announces the return:

```text
Compass return: compass-context-scout
Result: found the form component, validation helper, and existing tests.
Next: ask compass-planner for a scoped plan.
```

For parallel work, Compass lists the agents, their assignments, and the join
condition before launching them, then reports when the group completes.
