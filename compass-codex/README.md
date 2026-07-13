# Compass for Codex

This is the Codex-native Compass plugin. It keeps the main Codex session as the orchestrator and delegates focused work to project-defined custom subagents.

## Included roles

- `compass-context-scout`: bounded read-only repository evidence.
- `compass-planner`: implementation-ready execution plans.
- `compass-plan-auditor`: high-risk plan and packet audits.
- `compass-implementer`: one scoped write-safe execution group.
- `compass-code-reviewer`: read-only review of actual changes.
- `compass-doer`: focused tasks that do not need the full planning loop.

## Model routing

| Role | Model | Reasoning effort |
| --- | --- | --- |
| `compass-orchestrator` | `gpt-5.6-sol` | `medium` |
| `compass-context-scout` | `gpt-5.6-luna` | `low` |
| `compass-planner` | `gpt-5.6-sol` | `xhigh` |
| `compass-plan-auditor` | `gpt-5.6-sol` | `max` |
| `compass-implementer` | `gpt-5.6-terra` | `medium` |
| `compass-code-reviewer` | `gpt-5.6-sol` | `high` |
| `compass-doer` | `gpt-5.6-terra` | `medium` |

## Local installation

From the repository root:

```bash
codex plugin marketplace add "$PWD"
codex plugin add compass-codex@personal
```

Start a new Codex thread after installation, then invoke the Compass command or ask Codex to use the `compass-codex:compass` skill.

For a terminal-first session:

```bash
./compass-codex/scripts/compass
```

## Native status and agent visibility

The launcher configures Codex's native TUI footer to show the orchestrator's
model and reasoning effort, run state, remaining context, and Git branch.
Compass does not print a simulated status line or periodic waiting messages in
the transcript.

Run `/agent` or `/subagents` inside the Codex CLI to inspect and switch between
active or completed specialist threads. The native footer is configurable at
any time with `/statusline`.

Run plugin checks with:

```bash
./compass-codex/scripts/test-compass-codex-contracts.sh
```
