# Compass Agent Workflows

Compass is a routed engineering workflow available for both Claude Code and
Codex. Each implementation coordinates planning, repository context,
implementation, code review, and verification through focused subagents while
keeping the main orchestrator responsible for user alignment and final results.

## Implementations

| Runtime | Directory | Command | Configuration format |
| --- | --- | --- | --- |
| Claude Code | `compass-claude/` | `compass` | Claude plugin, Markdown agents, skills, and commands |
| Codex | `compass-codex/` | `compass-codex` | Codex plugin, TOML agents, skills, and commands |

The implementations are intentionally separate. Changes to one runtime do not
silently change the other runtime's agent definitions, model choices, or
launcher behavior.

## Repository Layout

- `compass-claude/`: Claude Code implementation and its detailed README.
- `compass-codex/`: Codex implementation and its detailed README.
- `.agents/plugins/marketplace.json`: repo-local Codex marketplace entry.

## Install The Shell Commands

The recommended setup keeps the launchers in this checkout and exposes stable
commands through `~/.local/bin`.

From the repository root:

```bash
mkdir -p "$HOME/.local/bin"
ln -sfn "$PWD/compass-claude/scripts/compass" "$HOME/.local/bin/compass"
ln -sfn "$PWD/compass-codex/scripts/compass" "$HOME/.local/bin/compass-codex"
```

Add this line to `~/.zshrc` if it is not already present:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Reload the current shell:

```bash
source "$HOME/.zshrc"
```

Verify both shortcuts:

```bash
command -v compass
command -v compass-codex
```

If you prefer aliases instead of symlinks, add these directly to `~/.zshrc`,
replacing the checkout path when necessary:

```bash
alias compass="$HOME/Projects/agent-workflows/compass-claude/scripts/compass"
alias compass-codex="$HOME/Projects/agent-workflows/compass-codex/scripts/compass"
```

Use either the symlink approach or the alias approach, not both.

## Claude Code

### Requirements

- Claude Code CLI available as `claude`.
- Bash, zsh, another POSIX shell, or PowerShell.

### Start

After installing the shortcut:

```bash
compass
compass advanced
```

Without the shortcut:

```bash
./compass-claude/scripts/compass
./compass-claude/scripts/compass advanced
```

From PowerShell:

```powershell
.\compass-claude\scripts\compass.ps1
.\compass-claude\scripts\compass.ps1 advanced
```

Claude starts `compass-orchestrator` as the main session agent. Advanced mode
starts `compass-advanced-orchestrator`. See
[`compass-claude/README.md`](compass-claude/README.md) for the Claude-specific
agent roles, model preferences, and workflow details.

### Claude Model Routing

- `compass-orchestrator`: Sonnet 5 1M max.
- `compass-advanced-orchestrator`: Opus medium.
- `compass-planner`: Opus.
- `compass-complex-planner`: Fable max, only when explicitly requested.
- `compass-plan-auditor`: Opus max.
- `compass-code-reviewer`: Opus.
- `compass-doer`: Sonnet 4.6 1M.
- `compass-implementer`: Sonnet 4.6 1M.
- `compass-context-scout`: Haiku.

The Claude implementation also includes the `change-walkthrough` skill for
creating local HTML review artifacts from PRs, branches, worktrees, diffs, or
explicit file lists.

## Codex

### Requirements

- Codex CLI available as `codex`.
- A Codex plan or workspace with access to the configured Sol, Terra, and Luna
  models.

### Install The Plugin

From the repository root:

```bash
codex plugin marketplace add "$PWD"
codex plugin add compass-codex@personal
```

Start a new Codex thread after installation or after reinstalling an update.

### Start

After installing the shortcut:

```bash
compass-codex
```

Without the shortcut:

```bash
./compass-codex/scripts/compass
```

You can also activate Compass inside a Codex task:

```text
Use $compass-codex:compass to handle this task.
```

The main Codex session acts as `compass-orchestrator`; the plugin's custom TOML
agents are spawned as specialists. The launcher uses Codex's native TUI footer
for model, run-state, context, and Git-branch visibility instead of printing a
simulated Compass status line. Use `/agent` or `/subagents` to inspect and
switch between specialist threads.

### Codex Usage Cadence

1. Start `compass-codex` from the repository you want to work on, or pass its
   path as the first argument. The launcher selects the Compass orchestrator
   model and installs the native footer for that session.
2. Give the orchestrator the task and any material constraints. It handles
   intake, planning, delegation, joins, review, and final verification.
3. Follow the footer for lightweight operational state: model and reasoning,
   `Ready` or `Working` run state, remaining context, and the current Git
   branch. Compass does not duplicate this information in transcript messages.
4. When specialists are active, run `/agent` or `/subagents`, select a thread,
   and inspect its progress, tool calls, or result. Open the picker again to
   return to the main orchestrator thread or inspect another specialist.
5. Leave the orchestrator quiet while agent state is unchanged. Specialists
   return final responses as completion packets, and the orchestrator uses one
   event-driven long wait that wakes as soon as a packet arrives. It does not
   short-poll, print repeated empty wait results, or ping agents for status.
   Before waiting, it refreshes the agent roster and proceeds only if at least
   one expected agent is pending or running. With no live agents, it reconciles
   available packets or verifies the assigned work directly instead of waiting.
   Codex may still display one native waiting entry for a valid active wait.
6. Run `/statusline` to adjust the footer during a session. To change the
   default used by `compass-codex`, edit the `tui.status_line` override in
   `compass-codex/scripts/compass`. When activating the Compass skill inside an
   already-running Codex task, use `/statusline` because the launcher override
   was not applied.
7. Run `/compact` when the root thread needs more context space. The Compass
   compaction prompt preserves the user contract, TODO board, agent roster,
   completion packets, partial joins, worktree state, validation, and exact
   resume action. The resumed orchestrator must reconcile existing agents and
   must not respawn or redo completed work merely because compaction occurred.
8. Start a new Codex thread after installing or reinstalling the plugin so the
   latest skill and agent definitions are loaded.

### Codex Permission Cadence

The `compass-codex` launcher selects Codex's **Approve for me** behavior with
`--ask-for-approval on-request` and `approvals_reviewer=auto_review`. Eligible
escalation requests go to Codex's reviewer agent instead of routinely stopping
for human approval, while the role-specific sandboxes remain intact:

- Scouts, planners, plan auditors, and code reviewers are read-only.
- Implementers and doers can write inside the selected workspace.

The reviewer approves or denies eligible boundary crossings. Tool-specific or
destructive requests that are not eligible for auto-review can still reach the
user. The launcher does not enable unrestricted full access or automatic
network access. When Compass is activated inside an existing Codex task instead
of through `compass-codex`, it inherits that task's permission mode; use
`/permissions` if you want to change it for that session.

### Codex Model Routing

The Codex launcher and agent definitions pin models so inexpensive agents
handle bounded work while stronger models make higher-risk decisions.

| Role | Model | Reasoning effort |
| --- | --- | --- |
| `compass-orchestrator` | `gpt-5.6-sol` | `medium` |
| `compass-context-scout` | `gpt-5.6-luna` | `low` |
| `compass-planner` | `gpt-5.6-sol` | `xhigh` |
| `compass-plan-auditor` | `gpt-5.6-sol` | `max` |
| `compass-implementer` | `gpt-5.6-sol` | `medium` |
| `compass-code-reviewer` | `gpt-5.6-sol` | `high` |
| `compass-doer` | `gpt-5.6-terra` | `medium` |

See [`compass-codex/README.md`](compass-codex/README.md) for installation and
Codex-specific implementation details.

## Shared Routing Model

Compass starts with intake when user context would make repository searches
sharper. For substantial code changes, it gathers focused evidence, creates an
implementation-ready plan, delegates one write-safe execution group per
implementer, reviews when warranted, and verifies the target working tree.

Compass uses runtime-native visibility for routing and handoffs. The
orchestrator owns the master TODO board; subagents receive bounded Context
Packets and return scoped results.

## Validation

Run both contract suites from the repository root:

```bash
./compass-claude/scripts/test-compass-contracts.sh
./compass-codex/scripts/test-compass-codex-contracts.sh
```

If Claude Code is available, also validate its plugin manifest:

```bash
claude plugin validate ./compass-claude
```
