# Compass

Compass is a Claude Code plugin that turns a chat workspace into a routed
engineering session.

When Compass is active, the main chat runs as `compass-orchestrator`. The
orchestrator coordinates focused agents for context gathering, planning,
implementation, log digestion, test execution, and final verification.

## Intended Experience

Start a Compass workspace, then describe the task normally:

```text
/compass
```

If the host requires plugin namespacing, use the closest available Compass
launcher shown by `/help` after loading the plugin. The core behavior is the
same: Compass should become the session mode, not a workflow command you repeat
for every task.

## Local Testing

From another project, load this plugin source directly:

```bash
claude --plugin-dir /Users/RBICS079/Projects/agent-workflows/compass
```

Then confirm:

- The `compass-orchestrator` agent is active for the session.
- The Compass agents appear in `/agents`.
- A task that changes code produces a plan before implementation.
- The implementer does not edit before plan approval unless explicitly told to
  proceed without another approval gate.

## Design

Compass keeps normal Claude Code sessions unaffected. It only changes behavior
for chats where the plugin is loaded or enabled.

The role boundaries are:

- `compass-orchestrator`: main session agent and user-facing router.
- `compass-context-scout`: read-only codebase discovery.
- `compass-planner`: read-only planning and user-alignment support.
- `compass-implementer`: scoped implementation from an approved plan.
- `compass-log-digester`: noisy log and stack trace compression.
- `compass-test-runner`: focused validation and test summaries.

## Visibility

Compass should make routing visible instead of hiding it.

At session start, Compass announces:

```text
Compass active. You are speaking with compass-orchestrator (Sonnet).
```

Before subagent work, it announces the handoff:

```text
Compass handoff: compass-context-scout (Haiku)
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
