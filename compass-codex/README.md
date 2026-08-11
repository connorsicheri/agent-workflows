# Compass for Codex

This is the Codex-native Compass plugin. It keeps small focused work in the root orchestrator and actively delegates useful independent lanes on substantial multi-file or multi-stage work.

## Included roles

- `compass-context-scout`: bounded read-only repository evidence.
- `compass-planner`: compact execution groups for independent planning lanes.
- `compass-plan-auditor`: explicit or exceptional-risk plan audits.
- `compass-implementer`: one scoped write-safe execution group.
- `compass-quick-reviewer`: low-cost correctness review for one execution group.
- `compass-pr-reviewer`: strong end-of-task review of the complete integrated change.
- `compass-doer`: low-cost independent bounded tasks.

## Model routing

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

## Root-first routing

Compass handles small, short single-lane work directly in the main session.
Focused non-trivial bugs and features may also stay in root when agent startup
and handoff would cost more than they save. For substantial multi-file or
multi-stage work, the orchestrator actively looks for at least one bounded
planning, evidence, implementation, or validation lane that can progress beside
useful root work.

When work contains independent lanes, Compass launches planners, scouts,
implementers, or doers together and keeps a useful root-owned lane moving while
they run. File count alone does not trigger delegation: every specialist lane
still needs a clear outcome and enough independent work to justify its handoff.
Planner output is a compact task graph: each group has an outcome, owner, scope,
ordered edits, dependencies, validation, completion condition, and review tier.
Groups stay large enough to justify agent startup and tightly coupled work stays
together.

Review has three levels:

- Implementer self-check is the default.
- `compass-quick-reviewer` optionally checks branching logic, state transitions,
  concurrency, error recovery, or non-trivial data transformation in one lane
  while other work continues. It is not used for routine type, docs, formatting,
  or straightforward configuration changes.
- `compass-pr-reviewer` performs one strong global review, after every lane has
  joined, only when the user asks or the work affects security, authentication,
  permissions, migrations, irreversible data operations, public APIs, shared
  data contracts, or integration across independent lanes that lacks reliable
  coverage. It reviews the complete final diff, never an intermediate group.

Ordinary work ends with focused validation and root diff inspection. Formal
verification is reserved for high-risk, strong-reviewed, or explicitly
requested work.

The `pr-feedback` skill handles review comments with complete thread-aware
context, four-way triage, minimal accepted fixes, and invariant rescanning. It
does not checkout, commit, push, reply, resolve threads, label PRs, or update PR
bodies without explicit authorization.

## Langfuse integration

Compass bundles the official Langfuse Agent Skill for tracing,
prompt-management, dataset, evaluation, migration, and error-analysis
workflows. It also registers the unauthenticated `langfuse-docs` MCP so
Compass can search and retrieve current Langfuse documentation.

The authenticated project-data MCP remains an explicit per-user setup because
its endpoint depends on the Langfuse region and it exposes read, write, and
delete tools. See [Langfuse in Compass Codex](docs/langfuse.md) for credentials,
MCP endpoints, capabilities, safety controls, and verification.

## Local installation

From the repository root:

```bash
codex plugin marketplace add "$PWD"
codex plugin add compass-codex@personal
```

Start a new Codex thread after installation, then invoke the Compass command or ask Codex to use the `compass-codex:compass` skill.

The launcher prefers a Homebrew Codex installation at
`/opt/homebrew/bin/codex` or `/usr/local/bin/codex` before falling back to the
first `codex` on `PATH`. This avoids accidentally launching an older CLI bundled
with an editor extension. Set `CODEX_BIN` to override the executable explicitly.

For a terminal-first session:

```bash
./compass-codex/scripts/compass
```

## Native status and agent visibility

The launcher configures Codex's native TUI footer to show the orchestrator's
model and reasoning effort, run state, remaining context, and Git branch.
Compass does not print a simulated status line or periodic waiting messages in
the transcript.

After specialists launch, the orchestrator keeps the root workflow active and
uses one event-driven wait. A specialist's final response is its completion
packet, and packet delivery wakes the orchestrator immediately. If one of
several specialists finishes, Compass processes that result and advances any
newly unblocked work before waiting again for the remaining live specialists.

Compass refreshes the native agent roster before each wait and never waits when
no specialist is pending or running. It does not short-poll, print repeated
empty wait results, or ping agents merely to check whether they are done. Codex
may still render one native waiting entry for an active wait. The native footer
remains configurable with `/statusline`.

A user command such as `/agent` can wake the root wait without completing a
specialist. Compass treats that as an interruption only: it refreshes the live
roster and waits again when the specialist is still running. It reports
specialist findings only from a delivered completion packet, never from the
fact that a wait returned.

This cadence prioritizes automatic workflow continuation. Codex issue #30813
currently prevents `/agent` from opening the expected selector for some V2
subagents; Compass does not stop the root workflow and require a manual
`continue` as a workaround.

## Compaction

The launcher supplies `prompts/compass-compact.md` as Codex's compaction prompt.
When `/compact` runs, the replacement context preserves the Compass identity,
root-owned work, task graph, agent ledger, material completion results, pending
joins, worktree state, decisions, validation, and exact resume action. Active or
completed agents must not be respawned merely because compaction occurred.

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
