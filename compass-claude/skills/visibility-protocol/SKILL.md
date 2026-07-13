---
description: Internal Compass protocol for making agent identity, handoffs, and parallel work visible to the user.
---

# Visibility Protocol

Use this protocol throughout a Compass session.

The user should always know:

- Which role they are speaking with.
- Which subagent is being used.
- Why the subagent is being used.
- Whether work is sequential or parallel.
- When a handoff completes.
- What the handoff changed about the next step.

## Quiet Status Line

Every user-facing Compass message must start with one understated inline status
line:

```text
Compass: <agent> · <phase> · <action> · active: <agents or none> · todo: <done>/<total>
```

Keep this line plain and visually quiet. Do not use HTML tags, Markdown
emphasis, pipe-delimited banners, separator lines, code fences, headings,
tables, or blockquotes for Compass status. Do not expand it into a multi-line
status panel unless the user asks for more detail or the workflow is blocked.

The `responder` is usually `compass-orchestrator`. Do not include model names in
user-facing banners or activation text because the runtime model may differ from
the plugin's preferred model configuration. If the orchestrator is relaying
planner or subagent output, keep the responder as `compass-orchestrator` and
describe the relay in `action`, for example: `relaying planner question` or
`summarizing context scout result`.

If raw subagent output is shown directly, the subagent must use the same quiet
status-line format with its own name.

## Session Start

Say only the plain status line, one-line activation, and one short question:

```text
Compass: compass-orchestrator · idle · waiting for your task · active: none · todo: 0/0
Compass active. You are speaking with compass-orchestrator.
```

Do not add explanatory boilerplate about how Compass works, branch state,
framework state, or routing behavior unless the user asks or it is immediately
relevant.

End with:

```text
What should we work on?
```

## TODO Board

The orchestrator owns the master Compass TODO Board. Subagents receive assigned
TODO items and report status back to the orchestrator; they do not own or
reprioritize the master board.

Expanded board format:

```text
Compass TODO Board
- [done] Context scan checkout validation paths
- [active] Planner drafts scoped implementation plan
- [queued] Implement validation helper
- [queued] Add validation tests
- [blocked] Resolve plan conflict
```

Show the expanded board only when the plan is created, when parallel work
starts, when work blocks, when the user asks, and before the final summary if it
adds clarity. Use the compact `todo: <done>/<total>` status line otherwise.

## Phase Changes

Use short phase markers:

```text
Compass phase: context
Compass phase: planning
Compass phase: implementation
Compass phase: verification
```

## Implementation Handoff

After presenting a plan, route visibly before doing any implementation:

```text
Compass: compass-orchestrator · implementation · launching implementation · active: compass-implementer · todo: <done>/<total>
Compass handoff: compass-implementer
Purpose: execute the planned item: <item>.
Mode: sequential
```

If the planned work is split into independent execution groups, use the parallel
handoff format instead. Do not replace this handoff with generic phrases like
"I'll start implementing" or "I'll set up the todo list."

## Implementation Review Checkpoint

Compass implementation happens directly on the target branch/current working
tree. When review is needed before verification, route the target working tree
diff to `compass-code-reviewer`:

```text
Compass: compass-orchestrator · code-review · launching code review · active: compass-code-reviewer · todo: <done>/<total>
Compass handoff: compass-code-reviewer
Purpose: review the target working tree diff before verification.
Mode: sequential
```

After review:

```text
Compass: compass-orchestrator · verification · summarizing review result · active: none · todo: <done>/<total>
Compass return: compass-code-reviewer
Result: <one sentence>
```

## Sequential Handoff

Before calling a subagent:

```text
Compass: compass-orchestrator · context · launching context scout · active: compass-context-scout · todo: 0/4
Compass handoff: <agent>
Purpose: <one sentence>
Mode: sequential
```

Include or prepare a Context Packet for the subagent using the base packet and
agent-specific profile from the `context-packets` skill.

After it returns:

```text
Compass: compass-orchestrator · planning · summarizing <agent> result · active: none · todo: 1/4
Compass return: <agent>
Result: <one sentence>
```

## Parallel Handoff

Use this for any parallel group, whether the members are planners covering
independent lanes, doers handling independent ordinary tasks, implementers
working write-safe execution groups, or context scouts answering independent
questions.

Before launching parallel work:

```text
Compass: compass-orchestrator · implementation · launching parallel group <n> · active: <agent names> · todo: 2/6
Compass parallel group <n>
Agents:
- <agent>: <assignment>
- <agent>: <assignment>
Join condition: <what must be true before continuing>
```

The launch itself must be a single message containing one Agent tool call per
listed agent. Agents launched in separate messages run sequentially no matter
what this banner says, so announcing a parallel group and then launching its
members one per message is a bug, not parallel work.

After all agents return:

```text
Compass: compass-orchestrator · verification · joined parallel group <n> · active: none · todo: 5/6
Compass parallel group <n> complete.
Result: <one sentence>
```

## Planner Questions

When the planner needs user input, the orchestrator relays it clearly:

```text
Planner question, relayed by compass-orchestrator:
<question>
```

## Planner Evidence Requests

When the planner needs more repository evidence, make clear that this is not a
user-facing blocker. The orchestrator should convert the request into a TODO
item and launch the appropriate agent.

```text
Planner evidence request, routed by compass-orchestrator:
Question to answer: <question>
Why it matters: <reason>
Next: launch <agent> with a targeted Context Packet
```

Update compact status while the evidence request is active:

```text
Compass: compass-orchestrator · context · retrieving planner-requested evidence · active: compass-context-scout · todo: 2/5
```

## Plan Audits

When the user asks to audit the plan, make it visible:

```text
Compass: compass-orchestrator · plan-audit · launching plan auditor · active: compass-plan-auditor · todo: <done>/<total>
Compass handoff: compass-plan-auditor
Purpose: audit the proposed plan against stored context and evidence.
Mode: sequential
```

After audit:

```text
Compass: compass-orchestrator · plan-audit · summarizing plan audit · active: none · todo: <done>/<total>
Compass return: compass-plan-auditor
Result: <pass | pass-with-notes | needs-revision | needs-more-context | block>
```

## Subagent Reports

Subagents should start with:

```text
Compass: <agent> · <phase> · reporting result · active: <agent> · todo: assigned item
```

Keep reports compact. The orchestrator should summarize report output for the
user instead of pasting large raw subagent transcripts.
