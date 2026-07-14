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
| `compass-implementer` | `gpt-5.6-sol` | `medium` |
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

After specialists launch, the orchestrator uses one event-driven long wait.
Each specialist's final response is its completion packet, and packet delivery
wakes the orchestrator immediately. Compass does not short-poll, print repeated
empty wait results, or ping agents merely to check whether they are done. Codex
may still render one native waiting entry while the long wait is active.

Before every long wait, Compass refreshes the native agent roster. A wait is
allowed only while at least one expected specialist is pending or running. If
no agents are live, Compass processes already-delivered packets and continues;
when a completion packet was lost to a user-turn race, it verifies the assigned
work and worktree directly instead of waiting on an agent that has stopped.

## Compaction

The launcher supplies `prompts/compass-compact.md` as Codex's compaction prompt.
When `/compact` runs, the replacement context preserves the Compass identity,
user contract, master TODO board, agent ledger, completion packets, partial
joins, worktree state, decisions, validation, and exact resume action. Active
or completed agents must not be respawned merely because compaction occurred.

The launcher resolves its real plugin directory before passing the prompt path,
so compaction also works when `compass-codex` is started through the recommended
`~/.local/bin` symlink.

## Approve for me permissions

The launcher uses `--ask-for-approval on-request` with
`approvals_reviewer=auto_review`. When a Compass agent needs an eligible
sandbox escalation, Codex routes the request to its reviewer agent instead of
pausing for routine human approval. It preserves each role's sandbox:

- Context, planning, audit, and review agents remain read-only.
- Implementers and doers retain workspace-write access.

The reviewer can approve or deny eligible requests and instruct Compass to find
a safer path after a denial. Tool-specific or destructive approvals that are
not eligible for auto-review can still reach you. Compass does not use
`--dangerously-bypass-approvals-and-sandbox`, so it does not gain unrestricted
filesystem or network access. Activating the Compass skill inside an existing
Codex task inherits that task's current permission mode; launch with
`compass-codex` when you want the **Approve for me** default.

Run plugin checks with:

```bash
./compass-codex/scripts/test-compass-codex-contracts.sh
```
