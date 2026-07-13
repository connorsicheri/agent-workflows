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
agents are spawned as specialists.

### Codex Model Routing

The Codex launcher and agent definitions pin models so inexpensive agents
handle bounded work while stronger models make higher-risk decisions.

| Role | Model | Reasoning effort |
| --- | --- | --- |
| `compass-orchestrator` | `gpt-5.6-sol` | `medium` |
| `compass-context-scout` | `gpt-5.6-luna` | `low` |
| `compass-planner` | `gpt-5.6-sol` | `xhigh` |
| `compass-plan-auditor` | `gpt-5.6-sol` | `max` |
| `compass-implementer` | `gpt-5.6-terra` | `medium` |
| `compass-code-reviewer` | `gpt-5.6-sol` | `high` |
| `compass-doer` | `gpt-5.6-terra` | `medium` |

See [`compass-codex/README.md`](compass-codex/README.md) for installation and
Codex-specific implementation details.

## Shared Routing Model

Compass starts with intake when user context would make repository searches
sharper. For substantial code changes, it gathers focused evidence, creates an
implementation-ready plan, delegates one write-safe execution group per
implementer, reviews when warranted, and verifies the target working tree.

Compass makes routing visible through quiet status lines and explicit
sequential or parallel handoffs. The orchestrator owns the master TODO board;
subagents receive bounded Context Packets and return scoped results.

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
