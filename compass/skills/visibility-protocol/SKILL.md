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

## Session Start

Say:

```text
Compass active. You are speaking with compass-orchestrator (Sonnet).
```

## Phase Changes

Use short phase markers:

```text
Compass phase: context
Compass phase: planning
Compass phase: implementation
Compass phase: verification
```

## Sequential Handoff

Before calling a subagent:

```text
Compass handoff: <agent> (<model>)
Purpose: <one sentence>
Mode: sequential
```

After it returns:

```text
Compass return: <agent>
Result: <one sentence>
Next: <one sentence>
```

## Parallel Handoff

Before launching parallel work:

```text
Compass parallel group <n>
Agents:
- <agent>: <assignment>
- <agent>: <assignment>
Join condition: <what must be true before continuing>
```

After all agents return:

```text
Compass parallel group <n> complete.
Result: <one sentence>
Next: <one sentence>
```

## Subagent Reports

Subagents should start with:

```text
Compass agent report: <agent> (<model>)
```

Keep reports compact. The orchestrator should summarize report output for the
user instead of pasting large raw subagent transcripts.
