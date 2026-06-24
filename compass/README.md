# Compass

Compass is a Claude Code plugin that turns a chat workspace into a routed
engineering session.

When Compass is active, the main chat runs as `compass-orchestrator`. The
orchestrator coordinates focused agents for ordinary task execution, context
gathering, planning, implementation, code review, log digestion, test execution,
and final verification.

## Intended Experience

Compass is most reliable when the orchestrator is the main-thread agent, set at
launch. Launched that way, `compass-orchestrator` owns the session with a durable
identity: its system prompt stays active every turn and survives long
conversations and context compaction.

Launch a durable Compass session from a project's integrated terminal:

```bash
claude --plugin-dir /Users/RBICS079/Projects/agent-workflows/compass \
  --agent compass:compass-orchestrator
```

A shell alias keeps this to one word:

```bash
alias compass='claude --plugin-dir /Users/RBICS079/Projects/agent-workflows/compass --agent compass:compass-orchestrator'
```

Confirm `@compass-orchestrator` appears in the startup header, then describe the
task normally. (If the host reports "agent not found", try the inline namespace
`compass@inline:compass-orchestrator`.)

### Re-centering with /compass

```text
/compass
```

`/compass` does not launch the orchestrator as the main-thread agent — the
main-thread agent can only be set at launch. It re-centers the current chat on
the Compass workflow as a one-shot prompt, which can fade over a long session.
Use it when a session was not launched as `compass-orchestrator` (for example,
the VS Code chat panel, which has no launch-flag support), or to reaffirm the
role mid-session. For durable identity, launch with `--agent` as shown above.

### Enterprise policy note

Always-on activation (a registered plugin marketplace plus the bundled
`settings.json` `agent` key) is blocked by RBI managed settings, which allowlist
only the official Anthropic marketplace. The `--plugin-dir` opt-in above is a
session-only dev load that does not register a marketplace, so it works with no
policy change. To enable always-on or the native chat panel later, open an ITSEC
ticket to allowlist the Compass marketplace source.

## Local Testing

After launching with the command above, confirm:

- `@compass-orchestrator` appears in the startup header and is the session agent.
- The Compass agents appear in `/agents`.
- A task that changes code produces a plan before implementation, then proceeds
  without an extra Compass checkpoint unless the user requests one.

## Design

Compass keeps normal Claude Code sessions unaffected. It only changes behavior
for chats where the plugin is loaded or enabled.

The role boundaries are:

- `compass-orchestrator`: Opus medium main session agent and user-facing
  router.
- `compass-doer`: Sonnet 1M general execution for ordinary delegated tasks.
- `compass-context-scout`: read-only codebase discovery.
- `compass-planner`: read-only planning and user-alignment support.
- `compass-plan-auditor`: independent read-only plan audit.
- `compass-code-reviewer`: independent read-only review of implemented code,
  diffs, branches, worktrees, or PR changes.
- `compass-implementer`: Sonnet 1M scoped implementation from an assigned
  plan.
- `compass-merge-agent`: Opus integration of accepted worktree changes onto the
  target branch.
- `compass-log-digester`: noisy log and stack trace compression.
- `compass-test-runner`: focused validation and test summaries.

The `context-packets` skill defines how `compass-orchestrator` injects focused
context into each subagent type.

Compass should not launch context gathering reflexively. The orchestrator starts
with a short intake chat when the user may have search hints or wants to talk
through the task first. It launches `compass-context-scout` after the user asks
for investigation, provides enough search guidance for a targeted packet, says
they do not know where to look, or the planner/auditor needs evidence.

For simple and nuanced questions, explanations, tradeoff discussion,
architecture or product reasoning, debugging theory, or "help me think this
through" requests, the Opus orchestrator answers directly. If repository
evidence is needed, it routes a targeted `compass-context-scout` packet first.

After presenting a plan, Compass should not drift into generic "I'll start
implementing" narration or ask for another checkpoint by default. The orchestrator
announces a visible handoff and launches `compass-implementer` with the planned
tasks and focused Context Packet. For ordinary tool-using tasks that are not
implementation plans, it launches `compass-doer`.

For PR, branch, worktree, local diff, or file-list walkthrough requests,
Compass routes to `compass-doer` with the `change-walkthrough` skill. The
default output is a local `local-notes/<slug>.html` reviewer artifact. PR body
updates are separate explicit tasks and should be split into a separate doer
when requested alongside the walkthrough.

Compass does not currently route to `visual-plan` or `visual-recap`. Those
copied skills are parked as deprecated source material until Compass has a
repo-owned viewer or a clearer local artifact workflow.

When an implementer uses an isolated worktree, Compass routes the result through
`compass-merge-agent` before verification. The orchestrator coordinates the
handoff, but Opus owns merge judgment and integration back onto the target
branch. After successful integration, `compass-merge-agent` removes the
Compass-created worktree by default. Preserved worktrees must be reported with
the reason they remain.

## Visibility

Compass should make routing visible instead of hiding it.

Compass uses a quiet inline status line by default:

```text
Compass: compass-orchestrator · planning · relaying planner update · active: compass-planner · todo: 1/4
```

The status line should stay plain and low-emphasis; it should never use HTML
tags, Markdown emphasis, a pipe-delimited banner, heading, table, or multi-line
panel.

At session start, Compass also announces:

```text
Compass active. You are speaking with compass-orchestrator.
```

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

## TODO Ownership

`compass-orchestrator` owns the master Compass TODO Board.

Subagents receive assigned TODO items and focused context. They report status
back to the orchestrator, but they do not own or reprioritize the master board.

Expanded board example:

```text
Compass TODO Board
- [done] Context scan checkout validation paths
- [active] Planner drafts scoped implementation plan
- [queued] Implement validation helper
- [queued] Add validation tests
- [blocked] Resolve plan conflict
```

Before launching a subagent, the orchestrator prepares a Context Packet from
`compass/skills/context-packets/SKILL.md`: the base packet plus the relevant
subagent profile.

Every Context Packet goes through the cheap Packet Quality Checklist in that
skill. Only broad, ambiguous, high-risk, or implementation-driving packets
escalate to Packet Review, where `compass-plan-auditor` checks the packet
against the user request, TODO Board, evidence summaries, assumptions, and
intended receiving agent before the handoff.

Compass defaults to parallel. When units of work have no shared write targets
and no data dependency, the orchestrator runs them at the same time and joins
their results before continuing — one implementer per write-safe execution
group, and one context scout per independent question. Work stays sequential
only when one unit's output feeds another, the units touch the same files, or a
sequential decision is required. Concurrency comes from launching the group in a
single message with one agent call per member; a group launched one agent per
message would run sequentially instead.

## Planner-Requested Evidence

The planner is not stuck with the first context scan. If it needs more evidence,
it returns a Planner Evidence Request to the orchestrator using the format in
`context-packets`.

The orchestrator then adds a TODO item, creates a targeted Context Packet,
launches the requested agent, and returns the compressed evidence to the
planner. When the planner returns several independent evidence requests, or the
context need splits into separate questions, the orchestrator fans out one scout
per question in parallel and joins their results before replying to the planner.
The planner/evidence loop repeats until the planner can produce a good plan, asks
the user a question, or hits a stop condition.

## Plan Audits

The user can ask Compass to audit a plan with phrases like:

```text
audit the plan
review the plan
stress test the plan
check the plan
```

Compass routes that to `compass-plan-auditor` with an Audit Packet containing
the current plan, TODO Board, stored context, evidence summaries, assumptions,
risks, execution groups, and stop conditions.

Audit results are:

- `pass`
- `pass-with-notes`
- `needs-revision`
- `needs-more-context`
- `block`

Before subagent work, Compass announces the handoff:

```text
Compass handoff: compass-context-scout
Purpose: find the checkout validation code paths.
Mode: sequential
```

After subagent work, it announces the return:

```text
Compass return: compass-context-scout
Result: found the form component, validation helper, and existing tests.
Next: ask compass-planner for a scoped plan.
```

For parallel work, Compass lists the agents, their assignments, and the join
condition before launching them, then reports when the group completes.
