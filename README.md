# Compass Agent System

Compass is a Claude Code plugin that turns a chat into a routed engineering
workspace. Start a Compass session once, then work normally while
`compass-orchestrator` coordinates planning, context gathering, implementation,
code review, and verification through focused subagents.

## Repository Layout

- `compass/.claude-plugin/plugin.json`: plugin manifest.
- `compass/settings.json`: default session-agent and subagent status-line
  settings.
- `compass/scripts/compass`: POSIX launcher.
- `compass/scripts/compass.ps1`: PowerShell launcher.
- `compass/bin/compass-statusline`: main Claude Code status-line formatter.
- `compass/bin/compass-subagent-statusline`: subagent panel row formatter.
- `compass/commands/compass.md`: `/compass` recentering command.
- `compass/agents/`: orchestrator and specialist agent definitions.
- `compass/skills/`: internal Compass workflows and packet formats, including
  `change-walkthrough` for local review artifacts.

## Requirements

- Claude Code CLI available as `claude`.
- Node.js available as `node` for the status-line scripts.
- Bash, zsh, or another shell that can run the POSIX launcher, or PowerShell
  for the `.ps1` launcher.

## Start A Session

From the repository root on macOS, Linux, or other POSIX shells:

```bash
./compass/scripts/compass
./compass/scripts/compass advanced
```

From PowerShell:

```powershell
.\compass\scripts\compass.ps1
.\compass\scripts\compass.ps1 advanced
```

To inspect the exact Claude command without launching:

```bash
./compass/scripts/compass --print-launch
```

```powershell
.\compass\scripts\compass.ps1 --print-launch
```

You can also run Claude directly from the repository root:

```bash
claude --plugin-dir ./compass --agent compass:compass-orchestrator
claude --plugin-dir ./compass --agent compass:compass-advanced-orchestrator
```

The direct command skips the custom main status line, but it still loads the
Compass plugin and agents.

## Optional PATH Setup

If you want `compass` to be available as a command on POSIX systems:

```bash
mkdir -p "$HOME/.local/bin"
ln -sf "$PWD/compass/scripts/compass" "$HOME/.local/bin/compass"
```

Make sure `$HOME/.local/bin` is on `PATH`. PowerShell users can run the `.ps1`
launcher directly or create their own profile alias to that script.

## Runtime Behavior

When Compass starts, the active agent is:

```text
compass-orchestrator
```

Advanced mode starts:

```text
compass-advanced-orchestrator
```

Compass does not show model names in user-facing banners because the runtime
model may be selected by Claude Code. The plugin still declares preferred model
tiers internally:

- `compass-orchestrator`: Sonnet 5 1M max.
- `compass-advanced-orchestrator`: Opus medium.
- `compass-planner`: Opus.
- `compass-complex-planner`: Fable max, only when explicitly requested.
- `compass-plan-auditor`: Opus max.
- `compass-code-reviewer`: Opus.
- `compass-doer`: Sonnet 4.6 1M.
- `compass-implementer`: Sonnet 4.6 1M.
- `compass-context-scout`: Haiku.

`/compass` recenters an already-running chat on the Compass workflow, but it
cannot change the main session agent after launch. For the most durable
experience, start the session with one of the launchers above.

## Routing Model

Compass starts with a short intake chat before deep search when that would help.
The orchestrator asks for useful search hints first, then launches
`compass-context-scout` only when repository evidence is needed or requested.

For code-changing work, Compass plans first, creates focused Context Packets,
then delegates implementation to one `compass-implementer` per write-safe
execution group. When extra confidence is needed, it routes the target working
tree diff to `compass-code-reviewer` before final verification.

Compass does not create implementation worktrees and does not attempt remote
publishing from sandboxed Claude sessions. For actions such as `git push`,
opening PRs, editing PR descriptions, or posting remote comments, Compass
prepares local state or draft text and reports the command for the user to run
outside the sandbox.

## Visibility

Compass is intentionally explicit about routing. It should show the user when a
subagent is being used, why it is being used, and whether work is sequential or
parallel.

The default user-facing status line is quiet and inline:

```text
Compass: compass-orchestrator · planning · relaying planner update · active: compass-planner · todo: 1/4
```

The orchestrator owns the master Compass TODO Board. Subagents receive assigned
TODO items and focused Context Packets, then report status back.

Sequential handoff example:

```text
Compass handoff: compass-context-scout
Purpose: find the checkout validation code paths.
Mode: sequential
```

Parallel group example:

```text
Compass parallel group 1
Agents:
- compass-implementer: form validation files
- compass-implementer: validation tests
Join condition: both agents complete without plan conflicts.
```

## Validation

Run the contract checks from the repository root:

```bash
./compass/scripts/test-compass-contracts.sh
```

If the Claude CLI is available, validate the plugin manifest:

```bash
claude plugin validate ./compass
```
