# Compass Agent Workflows

Compass is an engineering workflow available for both Claude Code and Codex.
Each implementation keeps the main orchestrator responsible for user alignment
and final results. The Codex implementation works directly by default and fans
out focused subagents only when parallelism or independent judgment adds value;
the Claude implementation retains its own routed workflow.

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

The launcher also installs a session-scoped native status bar showing the
active Compass mode, model and effort, remaining context, and Git branch without
modifying user or project settings.

### Claude Model Routing

- `compass-orchestrator`: Sonnet 5 1M max.
- `compass-advanced-orchestrator`: Opus 5 medium.
- `compass-planner`: Opus 5.
- `compass-complex-planner`: Fable max, only when explicitly requested.
- `compass-plan-auditor`: Opus 5 max.
- `compass-pr-reviewer`: Opus 5.
- `compass-doer`: Sonnet 4.6 1M.
- `compass-implementer`: Sonnet 4.6 1M.
- `compass-context-scout`: Haiku.

The Claude implementation also includes the `change-walkthrough` skill for
creating local HTML review artifacts from PRs, branches, worktrees, diffs, or
explicit file lists.

Both implementations include a `pr-feedback` skill that reads the full diff and
thread state, classifies active feedback, applies only accepted fixes, and
rescans affected invariants without automatically publishing remote changes.

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

The Codex launcher prefers the Homebrew executable at
`/opt/homebrew/bin/codex` or `/usr/local/bin/codex`, then falls back to `codex`
on `PATH`. Set `CODEX_BIN` when you want to select another installation
explicitly. This prevents an editor extension's bundled CLI from silently
shadowing the Homebrew installation.

You can also activate Compass inside a Codex task:

```text
Use $compass-codex:compass to handle this task.
```

The main Codex session acts as `compass-orchestrator`; the plugin's custom TOML
agents are spawned as specialists. The launcher uses Codex's native TUI footer
for model, run-state, context, and Git-branch visibility instead of printing a
simulated Compass status line. After launching specialists, the orchestrator
remains active and waits for their completion packets so the workflow advances
without a manual `continue` message.

### Codex Usage Cadence

1. Start `compass-codex` from the repository you want to work on, or pass its
   path as the first argument. The launcher selects the Compass orchestrator
   model and installs the native footer for that session.
2. Give the orchestrator the task and any material constraints. It handles
   intake, planning, delegation, joins, review, and final verification.
3. Follow the footer for lightweight operational state: model and reasoning,
   `Ready` or `Working` run state, remaining context, and the current Git
   branch. Compass does not duplicate this information in transcript messages.
4. When specialists are active, Compass uses one event-driven wait. Each final
   response is a completion packet that wakes the orchestrator immediately.
5. If one of several specialists finishes, the orchestrator processes its
   result, advances any newly unblocked work, refreshes the live roster, and
   waits again only for specialists that are still pending or running. It does
   not require a manual `continue`, short-poll, or ping agents for status.
   A slash command or other user steer can wake the wait without completing an
   agent; Compass refreshes the roster and waits again rather than inferring a
   result. Specialist findings are reported only from completion packets.
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

- Scouts, planners, plan auditors, and PR reviewers are read-only.
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
| `compass-orchestrator` | `gpt-5.6-sol` | `high` |
| `compass-context-scout` | `gpt-5.6-luna` | `low` |
| `compass-planner` | `gpt-5.6-sol` | `medium` |
| `compass-plan-auditor` | `gpt-5.6-sol` | `max` |
| `compass-implementer` | `gpt-5.6-sol` | `medium` |
| `compass-quick-reviewer` | `gpt-5.6-terra` | `medium` |
| `compass-pr-reviewer` | `gpt-5.6-sol` | `high` |
| `compass-doer` | `gpt-5.6-terra` | `low` |

See [`compass-codex/README.md`](compass-codex/README.md) for installation and
Codex-specific implementation details.

## Shared Routing Model

Compass for Codex is root-first. The orchestrator directly handles small,
focused work. For substantial multi-file or multi-stage work, it actively looks
for at least one bounded planning, evidence, implementation, or validation lane
that can progress beside useful root work. Independent planners, scouts,
implementers, and doers launch together while the root owns shared contracts
and integration.

Codex review uses implementer self-check by default, an optional low-cost quick
reviewer during one non-trivial execution group, and one strong
`compass-pr-reviewer` at the end for explicit requests or objective high-risk
changes. The PR reviewer runs only after all lanes have joined and reviews the
complete integrated diff globally. Claude uses its single `compass-pr-reviewer`
at the same final integrated-review point when review is required.

## Good Engineering Practices

Use the shared [Good Engineering Practices](GOOD_ENGINEERING_PRACTICES.md)
checklist during design, implementation, and review. It distills the recurring
correctness, clarity, testing, documentation, and maintainability signals used
by the Compass PR reviewer.

## Validation

Run both contract suites from the repository root:

```bash
./compass-claude/scripts/test-compass-contracts.sh
./compass-codex/scripts/test-compass-codex-contracts.sh
```

## Benchmarks

The [Compass benchmark suite](benchmarks/README.md) provides deterministic
fixture repositories and matched single-agent profiles for Codex and Claude.
It records correctness, wall-clock time, token usage, per-model usage when the
CLI exposes it, and provider-reported cost.

Validate or preview the suite without spending model tokens:

```bash
python3 benchmarks/run.py validate --check-clis
python3 benchmarks/run.py run --profiles core --tasks all --dry-run
```

If Claude Code is available, also validate its plugin manifest:

```bash
claude plugin validate ./compass-claude
```
