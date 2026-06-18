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
- `compass/skills/`: internal workflows used by the orchestrator.
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
panel. Claude Code chat may not render Mermaid diagrams. VS Code Markdown
Preview does render Mermaid fenced code blocks, so Compass treats Mermaid as a
Markdown preview artifact. Compass should not paste Mermaid, graph code, or text
maps into chat.

Compass automatically maintains the rendered map artifact:

```text
.compass/compass-map.md
```

The orchestrator should update it whenever Compass state changes: session
start, phase changes, agent starts/finishes, TODO state changes, plan changes,
evidence requests, audit requests, parallel work, blocked states, and final
summary. Open it with VS Code Markdown Preview for the rendered diagram. In
chat, Compass may link it quietly as `Map: .compass/compass-map.md` when useful;
the graph source should stay only in the Markdown artifact.

Compass updates the map through one deterministic Bash path instead of choosing
between file tools at runtime:

```bash
bash /Users/RBICS079/Projects/agent-workflows/compass/scripts/update-compass-map.sh "$PWD" orientation none 0/0 "session start" "awaiting user input"
```

The updater creates `.compass`, touches and reads `compass-map.md`, writes a
temporary file, then moves it into place.

`compass-orchestrator` owns the master Compass TODO Board. Subagents receive
assigned TODO items and focused Context Packets, then report status back.

Expanded TODO Board example:

```text
Compass TODO Board
- [done] Context scan checkout validation paths
- [active] Planner drafts scoped implementation plan
- [queued] Implement validation helper
- [queued] Add validation tests
- [blocked] Await user approval
```

Context Packet example:

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

The planner can request more context before producing a plan:

```md
## Planner Evidence Request

- Question to answer:
- Why it matters:
- Suggested agent: compass-context-scout
- Suggested scout target:
- Files, symbols, or search terms:
- Constraints:
- Stop condition:
- Expected evidence:
```

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
