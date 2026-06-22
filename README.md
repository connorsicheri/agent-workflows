# Agent Workflows

This repository contains Compass, a Claude Code plugin that turns a chat into a
routed engineering workspace.

Compass is designed to be started once for a session with:

```text
/compass
```

After that, the user speaks to `compass-orchestrator`, which coordinates
planning, context gathering, implementation, test execution, log digestion, and
verification through focused subagents.

Compass starts with conversation before deep search when that would help. The
orchestrator asks for useful search hints first, then launches
`compass-context-scout` only when repository evidence is needed or requested.

## What Was Built

The plugin source lives in:

```text
compass/
```

Important files:

- `compass/.claude-plugin/plugin.json`: plugin manifest.
- `compass/settings.json`: sets the base session agent to
  `compass-orchestrator`.
- `compass/commands/compass.md`: global `/compass` launcher behavior.
- `compass/agents/`: Compass orchestrator and subagent definitions.
- `compass/skills/`: internal workflows used by the orchestrator, including
  `context-packets` for subagent packet construction.
- `claude-orchestration-workflow/Claude Code Routed Agent System Plan.md`:
  detailed design notes and implementation plan.

## Integration Approach

The original idea was to install Compass through a local Claude Code marketplace.
That was attempted, but the machine's enterprise policy only allowed the
official Anthropic marketplace:

```text
Marketplace source 'dir:/Users/RBICS079/Projects/agent-workflows' is blocked by enterprise policy.
Allowed sources: github:anthropics/claude-plugins-official
```

Because of that, Compass was integrated through Claude's personal local plugin
and command paths instead.

The registered plugin path is a symlink:

```text
~/.claude/skills/compass
  -> /Users/RBICS079/Projects/agent-workflows/compass
```

The global command is also a symlink:

```text
~/.claude/commands/compass.md
  -> /Users/RBICS079/Projects/agent-workflows/compass/commands/compass.md
```

This gives the useful development behavior: edit the source in this repository,
then reload Claude Code or start a new VS Code Claude session to pick up the
changes.

## Validation

The plugin was validated through the registered path:

```bash
claude plugin validate /Users/RBICS079/.claude/skills/compass
```

Expected result:

```text
Validating plugin manifest: /Users/RBICS079/.claude/skills/compass/.claude-plugin/plugin.json

✔ Validation passed
```

## Runtime Behavior

When `/compass` starts, Compass should announce:

```text
Compass active. You are speaking with compass-orchestrator.
```

The base session agent is:

```text
compass-orchestrator
```

Compass does not show model names in user-facing banners because the runtime
model may be selected by Claude Code or the VS Code extension. The plugin still
declares preferred model tiers internally:

- `compass-planner`: Opus.
- `compass-plan-auditor`: Opus.
- `compass-implementer`: Sonnet.
- `compass-merge-agent`: Opus.
- `compass-context-scout`: Haiku.
- `compass-log-digester`: Haiku.
- `compass-test-runner`: Haiku.

## Visibility Protocol

Compass is intentionally explicit about routing. It should show the user when a
subagent is being used, why it is being used, and whether the work is sequential
or parallel.

Compass uses a quiet inline status line by default:

```text
Compass: compass-orchestrator · planning · relaying planner update · active: compass-planner · todo: 1/4
```

The status line should stay plain and low-emphasis; it should never use HTML
tags, Markdown emphasis, a pipe-delimited banner, heading, table, or multi-line
panel.

Compass automatically maintains the live dashboard artifact:

```text
.compass/dashboard.html
```

The orchestrator should update it whenever Compass state changes: session
start, phase changes, agent starts/finishes, TODO state changes, plan changes,
evidence requests, audit requests, parallel work, blocked states, and final
summary. The dashboard opens automatically at session start and refreshes every
2 seconds.

Compass updates the dashboard through one deterministic Bash path instead of
choosing between file tools at runtime:

```bash
bash /Users/RBICS079/Projects/agent-workflows/compass/scripts/update-compass-map.sh "$PWD" orientation none 0/0 "session start" "awaiting user input" --init
```

The updater creates `.compass`, writes a temporary dashboard file, then moves it
into place.

`compass-orchestrator` owns the master Compass TODO Board. Subagents receive
assigned TODO items and focused Context Packets, then report status back.

Expanded TODO Board example:

```text
Compass TODO Board
- [done] Context scan checkout validation paths
- [active] Planner drafts scoped implementation plan
- [queued] Implement validation helper
- [queued] Add validation tests
- [blocked] Resolve plan conflict
```

Context Packet shapes live in `compass/skills/context-packets/SKILL.md`. The
orchestrator uses the base packet plus the relevant subagent profile before
each handoff.

The planner can request more context before producing a plan. The Planner
Evidence Request format also lives in `context-packets`.

The orchestrator owns that loop: it adds a TODO item, sends a targeted Context
Packet to the right agent, and returns compressed evidence to the planner.

The user can also ask Compass to audit the plan. Compass routes that to
`compass-plan-auditor` with an Audit Packet containing the current plan, TODO
Board, stored context, evidence summaries, assumptions, risks, execution
groups, and stop conditions. Audit results are `pass`, `pass-with-notes`,
`needs-revision`, `needs-more-context`, or `block`.

Sequential handoff example:

```text
Compass handoff: compass-context-scout
Purpose: find the checkout validation code paths.
Mode: sequential
```

Return example:

```text
Compass return: compass-context-scout
Result: found the form component, validation helper, and existing tests.
Next: ask compass-planner for a scoped plan.
```

Parallel group example:

```text
Compass parallel group 1
Agents:
- compass-implementer: form validation files
- compass-implementer: validation tests
Join condition: both agents complete without plan conflicts.
```

## Updating Compass

Because the global registration uses symlinks, changes should be made directly
in this repository under `compass/`.

After editing, validate with:

```bash
claude plugin validate /Users/RBICS079/.claude/skills/compass
```

Then reload Claude Code or start a fresh VS Code Claude session.

## Recreating The Integration

If this setup needs to be recreated on the same machine:

```bash
mkdir -p /Users/RBICS079/.claude/skills
ln -s /Users/RBICS079/Projects/agent-workflows/compass /Users/RBICS079/.claude/skills/compass

mkdir -p /Users/RBICS079/.claude/commands
ln -s /Users/RBICS079/Projects/agent-workflows/compass/commands/compass.md /Users/RBICS079/.claude/commands/compass.md

claude plugin validate /Users/RBICS079/.claude/skills/compass
```

If the symlinks already exist, remove or update them intentionally rather than
creating duplicates.
