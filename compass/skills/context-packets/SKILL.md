---
description: Internal Compass rules for building focused subagent Context Packets and Audit Packets.
---

# Context Packets

Use this skill whenever `compass-orchestrator` prepares an Agent-tool prompt for
a Compass subagent. The orchestrator owns packet construction. Subagents consume
the packet, restate the assigned work when their prompt requires it, and return
the requested output shape.

## Packet Rules

- Build one packet per subagent launch.
- Keep packets scoped to the assigned TODO item or execution group.
- Include enough evidence for the subagent to act without rediscovering the
  whole task.
- Prefer paths, symbols, commands, and compact evidence summaries over raw file
  dumps or long logs.
- State what is out of scope so focused agents do not widen the work.
- State stop conditions that should return control to `compass-orchestrator`.
- For parallel groups, give each subagent a packet with distinct write targets
  or independent evidence questions.
- Run the Packet Quality Checklist before launching any subagent.
- Use Packet Review only when the checklist flags risk or the packet will drive
  high-impact work.

## Packet Quality Checklist

The orchestrator runs this cheap self-check for every Context Packet before
launching a subagent:

- The assigned TODO item is concrete and action-oriented.
- The goal names the outcome, not just the activity.
- In scope and out of scope are both explicit.
- Relevant files, symbols, commands, evidence summaries, or search terms are
  included when known.
- Constraints include user instructions, repository limits, and workflow limits
  that could affect the agent's choices.
- Stop conditions tell the subagent when to return instead of guessing.
- Expected return format is specific enough for the orchestrator to route the
  result.
- The receiving agent can act without rediscovering broad context that the
  orchestrator already has.

If any item fails, revise the packet before launch or escalate to Packet
Review.

## Packet Review

Use Packet Review as a targeted judgment checkpoint, not as a default toll on
every handoff. The reviewer should be a stronger reasoning model when available,
but the review must stay narrow: improve the packet, do not re-plan the whole
task.

Trigger Packet Review when any of these are true:

- The packet drives implementation that touches shared behavior, public APIs,
  data models, migrations, auth, permissions, or security-sensitive code.
- The task is broad, ambiguous, or high-risk.
- The packet depends on compressed evidence from multiple agents.
- A prior subagent reported missing context, scope drift, or plan conflict.
- The user asks for extra caution.
- The orchestrator has low confidence after the Packet Quality Checklist.

Do not use Packet Review for narrow scout, log-digester, test-runner, or doer
tasks when the checklist passes and the blast radius is low.

### Packet Review Bundle

Send this bundle to the reviewer:

```md
## Packet Review Bundle

- User request:
- Current TODO Board:
- Intended receiving agent:
- What the packet must enable:
- Proposed Context Packet:
- Evidence summaries used:
- Plan excerpt, if any:
- Known assumptions:
- Known risks:
- Specific review question:
```

Expected review output:

```md
## Packet Review Result

- Result: pass | revise | block
- Missing context:
- Ambiguous instructions:
- Scope risks:
- Suggested packet edits:
```

Route the result as follows:

- `pass`: launch the subagent with the packet.
- `revise`: apply the suggested packet edits, then launch if the checklist now
  passes.
- `block`: stop and resolve the missing context, user decision, or plan issue
  before launching the subagent.

## Base Context Packet

Use this base shape for ordinary subagent launches, then add the relevant
agent-specific fields below.

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

## Agent Packet Profiles

### `compass-context-scout`

Use for repository discovery and planner/auditor evidence requests.

Add:

- Question to answer:
- Search targets:
- Known files or symbols:
- Areas to avoid:
- Evidence needed:
- Output limit:

Expected return format:

1. Relevant files and why they matter.
2. Important functions, classes, routes, schemas, or config entries.
3. Dependency relationships.
4. Constraints or risks discovered.
5. Open questions.
6. Compact recommendation for the planner.

### `compass-planner`

Use when asking for a plan or plan revision.

Add:

- User request:
- Evidence summaries:
- Non-goals:
- Decisions needed:
- Candidate files:
- Validation expectations:
- Known risks:

Expected return format:

- User Alignment.
- Recommendation.
- Implementation Plan.
- Files Likely Involved.
- Execution Groups.
- Risk Check.
- Instructions For Implementer.
- Stop Conditions.

### `compass-implementer`

Use for assigned implementation work only.

Add:

- Assigned plan excerpt:
- Execution group:
- Files allowed to change:
- Files to read first:
- Prior subagent results:
- Validation command:
- Plan conflict triggers:

Expected return format:

- Changed files.
- Behavior changed.
- Validation run.
- Remaining risks.
- TODO item status.

### `compass-test-runner`

Use for focused validation and test-output interpretation.

Add:

- Commands to run:
- Changed files under test:
- Expected result:
- Failure interpretation needed:
- Output limit:
- Broader validation question:

Expected return format:

1. Commands run.
2. Pass/fail result.
3. Failing tests.
4. Minimal error snippets.
5. Probable cause.
6. Suggested fix direction.
7. Whether broader validation is needed.

### `compass-log-digester`

Use for verbose logs, CI output, stack traces, or command output.

Add:

- Log source:
- Command that produced the output:
- Question to answer:
- Noise to ignore:
- Smallest useful excerpt requested:

Expected return format:

1. Failing command or log source.
2. Smallest relevant error excerpt.
3. Likely root cause.
4. Files or symbols probably involved.
5. Suggested next diagnostic step.
6. Whether the issue appears deterministic or flaky, if inferable.

### `compass-plan-auditor`

Use for independent plan review.

Build an Audit Packet instead of the base Context Packet:

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

Expected return format:

- Result.
- Confidence.
- Summary.
- Checks.
- Findings.
- Required Fixes.
- Evidence Requests, if needed.
- Recommendation.

### `compass-doer`

Use for ordinary delegated work that does not need the full code-change
planning flow.

Add:

- Direct task:
- Tool, skill, command, or artifact to use:
- Files allowed to change, if any:
- Destructive actions assigned, if any:
- Handoff trigger:

Expected return format:

- Task completed.
- Tools, skills, or commands used.
- Files read or changed, if any.
- Key result.
- Validation or verification performed.
- Remaining risks or follow-up.
- TODO item status.

## Planner Evidence Request

When `compass-planner` needs more evidence, it returns this shape for the
orchestrator to convert into one or more `compass-context-scout`,
`compass-log-digester`, or `compass-test-runner` packets:

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
