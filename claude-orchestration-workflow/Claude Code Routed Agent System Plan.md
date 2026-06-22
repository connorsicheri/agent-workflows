# Compass: Claude Code Routed Agent Plugin Plan

## 1. Objective

Build **Compass**, a Claude Code plugin that turns a chat workspace into a
routed engineering session.

The goal is not to make every Claude Code chat use routing. The goal is to make
it easy to intentionally enter a Compass session, where the main chat becomes an
orchestrator that coordinates planning, context gathering, implementation, and
verification through specialized agents.

Target user experience:

```text
/compass
```

After that, the active workspace behaves as a routed agent system:

```text
User
  |
  v
Compass Orchestrator
  |
  | gathers context when needed
  v
Context Scout / Log Digester / Test Runner
  |
  | provide compressed evidence
  v
Planner
  |
  | asks questions, discusses tradeoffs, aligns with user
  v
User Alignment Gate
  |
  | after approval
  v
Implementer
  |
  | makes scoped changes
  v
Verification
  |
  v
Final Summary
```

The important behavior is:

1. A single prompt can start the routed workflow.
2. The router and planner may have a real back-and-forth with the user.
3. Implementation does not begin until the plan is aligned.
4. The planner and implementer remain separate roles.
5. Token-heavy work is delegated to cheaper, focused agents.
6. Compass is packaged as a plugin, so it can be reused across projects without
   copying `.claude/` files into every repository.
7. Agent identity, subagent handoffs, subagent returns, and parallel execution
   groups are visible to the user.

## 2. Core Design Decision

Compass should be a **session-mode plugin**, not a collection of commands that
the user must invoke for every task.

Earlier designs considered skills such as `/devflow:route`,
`/devflow:debug`, and `/devflow:refactor`. That is too much ceremony. The user
does not want to pick a specific workflow command for each request.

Instead:

- The plugin name is `compass`.
- The user-facing session entrypoint is `/compass`.
- Once Compass is active, the main chat is the orchestrator.
- The orchestrator decides when to use the planner, implementer, context scout,
  log digester, and test runner.
- Skills remain internal reusable workflow modules, not the primary interface.

Claude Code plugin skills are often namespaced depending on installation and
layout. If the runtime requires a namespaced fallback such as `/compass:start`,
the product behavior should still be described as "start Compass." The target
interface remains `/compass` where the host supports that shape.

## 3. Plugin Structure

Create a self-contained plugin:

```text
compass/
  .claude-plugin/
    plugin.json
  README.md
  settings.json
  agents/
    compass-orchestrator.md
    compass-planner.md
    compass-plan-auditor.md
    compass-implementer.md
    compass-context-scout.md
    compass-log-digester.md
    compass-test-runner.md
  skills/
    routed-planning/
      SKILL.md
    plan-audit/
      SKILL.md
    debugging/
      SKILL.md
    refactoring/
      SKILL.md
    visibility-protocol/
      SKILL.md
    verification-gate/
      SKILL.md
```

### Why this structure

- `settings.json` makes Compass behave like a session mode by setting the main
  agent to `compass-orchestrator`.
- `agents/` defines role boundaries and model/tool scopes.
- `skills/` defines reusable procedures the orchestrator can load when needed.
- The plugin can be installed, enabled, disabled, updated, and shared as a
  single unit.

## 4. Plugin Manifest

File:

```text
compass/.claude-plugin/plugin.json
```

Proposed content:

```json
{
  "name": "compass",
  "description": "A routed engineering session for Claude Code with planner, implementer, context, and verification agents.",
  "version": "0.1.0",
  "author": {
    "name": "Local"
  }
}
```

Keep the manifest small at first. Add repository, homepage, license, or
marketplace metadata later only when distribution requires it.

## 5. Plugin Settings

File:

```text
compass/settings.json
```

Proposed content:

```json
{
  "agent": "compass-orchestrator"
}
```

This is the key to the desired experience. When the Compass plugin is active,
the main session runs as the Compass orchestrator.

This avoids always-on project instructions. Normal Claude Code sessions remain
normal. Compass sessions become routed workspaces.

## 6. Agent Overview

| Agent | Model | Purpose | Tool Scope |
| --- | --- | --- | --- |
| `compass-orchestrator` | Sonnet | Main session agent; routes work and talks with the user | Read, Bash, Agent, skills |
| `compass-planner` | Opus or Sonnet | Creates user-aligned plans and asks clarifying questions | Read-only |
| `compass-plan-auditor` | Opus | Audits plans against stored context, evidence, assumptions, risks, and stop conditions | Read-only |
| `compass-implementer` | Sonnet | Implements the assigned plan | Edit/write/test |
| `compass-context-scout` | Haiku | Broad repo search and compressed evidence | Read-only |
| `compass-log-digester` | Haiku | Summarizes logs, stack traces, and noisy output | Read-only |
| `compass-test-runner` | Haiku or Sonnet | Runs focused validation and summarizes results | Bash/read-only |

### Model routing

Default routing:

- Haiku: search, logs, tests, repetitive diagnostics.
- Sonnet: orchestration, normal implementation, medium reasoning.
- Opus: architecture, ambiguity, high-risk planning, repeated failures, final
  review of complex changes.

Use Opus only when the decision quality justifies the cost:

- Architecture decisions.
- Public API changes.
- Schema, migration, or data model changes.
- Auth, permissions, or security-sensitive changes.
- Repeated failed implementation attempts.
- Final review of complex multi-file work.

## 7. Compass Orchestrator

File:

```text
compass/agents/compass-orchestrator.md
```

Purpose:

The orchestrator is the main chat persona for a Compass session. It talks with
the user, classifies the task, delegates context gathering, requests a plan,
keeps the user aligned, and only then starts implementation.

The orchestrator is allowed to have a real discussion with the user. It should
not rush to implementation if the plan is unclear.

Frontmatter sketch:

```md
---
name: compass-orchestrator
description: Main Compass session agent. Routes engineering tasks through planner, context, implementation, and verification agents.
tools: Agent, Read, Glob, Grep, Bash
model: sonnet
effort: medium
---
```

Core instructions:

```md
# Compass Orchestrator

You are the main agent for a Compass routed engineering session.

Your job is to coordinate the work, not to silently do every role yourself.

For code-changing tasks:

1. Understand the user's requested outcome.
2. Start with a short intake chat before launching context agents unless the
   user explicitly asks for immediate repository inspection.
3. State assumptions and ambiguity.
4. Use `compass-context-scout` when repository context is needed and intake has
   produced enough search guidance, or when the user asks for deep search.
5. Use `compass-log-digester` for noisy logs or stack traces.
6. Ask `compass-planner` to create or refine the plan.
7. If requested or high-risk, ask `compass-plan-auditor` to audit the plan.
8. Present the plan to the user.
9. Proceed to implementation after presenting the plan unless the user asks for
   a manual checkpoint.
10. Use `compass-implementer` to make changes.
11. Use `compass-test-runner` and the verification gate before final response.

You may ask the user clarifying questions. Prefer one or two high-value
questions over a long questionnaire.

Do not launch context gathering reflexively. Use intake when the user may know
the relevant files, routes, feature names, error text, recent changes, expected
behavior, non-goals, or constraints. Launch `compass-context-scout` after those
hints are captured, when the user asks for investigation, when the user does not
know where to look, or when planner/auditor evidence is required.

For trivial non-code answers, answer directly.

For trivial code edits, produce a micro-plan and proceed unless the user asked
for a separate manual checkpoint.

Stop and return to the user if:

- The plan requires broader scope than expected.
- The implementation path changes public APIs unexpectedly.
- Data models, migrations, auth, permissions, or security logic are affected
  unexpectedly.
- Tests fail twice for unclear reasons.
- The smallest viable fix is no longer obvious.
```

## 8. Planner Agent

File:

```text
compass/agents/compass-planner.md
```

Purpose:

The planner owns judgment, tradeoffs, assumptions, and user alignment. It does
not edit files.

Frontmatter sketch:

```md
---
name: compass-planner
description: Creates and refines user-aligned implementation plans. Does not edit files.
tools: Read, Glob, Grep, Bash
disallowedTools: Edit, Write
model: opus
effort: high
maxTurns: 10
---
```

Planner output format:

```md
## User Alignment

- Requested outcome:
- What the user appears to care about:
- Non-goals:
- Assumptions:
- Questions or approval points:

## Recommendation

- Recommended approach:
- Alternatives considered:
- Why this approach is preferred:

## Implementation Plan

1.
2.
3.

## Files Likely Involved

- `path`: reason

## Execution Groups

Group 1:
- Step:

Group 2:
- Step:

## Risk Check

- Scope risk:
- Architecture risk:
- Security risk:
- Data/model risk:
- Test risk:

## Instructions For Implementer

Precise implementation instructions.

## Stop Conditions

Conditions that require returning to the user or planner before continuing.
```

The planner may recommend questions for the orchestrator to ask the user. The
orchestrator should handle the conversation, then return updated context to the
planner if the plan needs revision.

## 9. Implementer Agent

File:

```text
compass/agents/compass-implementer.md
```

Purpose:

The implementer executes the assigned plan. It does not silently re-plan.

Frontmatter sketch:

```md
---
name: compass-implementer
description: Implements assigned Compass plans with minimal scope creep.
tools: Read, Edit, Write, Bash, Glob, Grep
model: sonnet
effort: medium
maxTurns: 14
---
```

Core rules:

- Restate the assigned plan before editing.
- Touch only files included in the assigned plan unless a stop condition is
  reached.
- Make the smallest viable diff.
- Do not introduce unrelated cleanup.
- Proceed when the assigned plan includes public APIs, schemas, migrations,
  auth, permissions, or security-sensitive code.
- Stop on plan conflicts and report evidence.
- Run focused validation when available.

Plan conflict report:

```md
## Plan Conflict

- What changed:
- Evidence:
- Why the assigned plan may be invalid:
- Recommended next step:
```

## 10. Context Scout

File:

```text
compass/agents/compass-context-scout.md
```

Purpose:

Find relevant repository context cheaply and return compressed evidence.

Use when:

- Relevant files are unknown.
- More than three files may be involved.
- The change spans modules.
- System behavior is unclear.
- Broad search output would pollute the main conversation.

Return only:

1. Relevant files and why they matter.
2. Important functions, classes, routes, schemas, or config entries.
3. Dependency relationships.
4. Constraints or risks discovered.
5. Open questions.
6. Compact recommendation for the planner.

Do not include full file contents.

## 11. Log Digester

File:

```text
compass/agents/compass-log-digester.md
```

Purpose:

Compress noisy terminal output, stack traces, CI logs, and test output.

Return:

1. Failing command or log source.
2. Smallest relevant error excerpt.
3. Likely root cause.
4. Files or symbols probably involved.
5. Suggested next diagnostic step.
6. Whether the issue appears deterministic or flaky, if inferable.

Do not paste full logs.

## 12. Test Runner

File:

```text
compass/agents/compass-test-runner.md
```

Purpose:

Run focused validation and summarize results. The test runner does not fix
code.

Return:

1. Commands run.
2. Pass/fail result.
3. Failing tests.
4. Minimal error snippets.
5. Probable cause.
6. Suggested fix direction.
7. Whether broader validation is needed.

Prefer focused tests over full suites unless the user or orchestrator asks for
full validation.

## 13. Skills

Skills are internal reusable procedures. They are not the primary interface.

### `routed-planning`

Use for feature work, code changes, and general implementation tasks.

Responsibilities:

- Classify the request.
- Run intake before search when user hints could narrow the work.
- Gather context only when needed or requested.
- Ask planner for a plan.
- Align with the user.
- Hand off to implementer after approval.

### `debugging`

Use for bugs, failing tests, runtime errors, regressions, and unclear failures.

Required evidence before planning:

- Failing behavior.
- Expected behavior.
- Minimal error excerpt.
- Relevant files.
- Suspected root cause.
- Confidence level.
- Unknowns.

### `refactoring`

Use for behavior-preserving changes.

Planner must define:

- Behavior that must remain unchanged.
- Files in scope.
- Files out of scope.
- Tests that should pass.
- Risks.
- Stop conditions.

### `visibility-protocol`

Use throughout the Compass session to make routing visible.

Compass uses a quiet inline status line by default:

```text
Compass: compass-orchestrator · planning · relaying planner update · active: compass-planner · todo: 1/4
```

The status line should stay plain and low-emphasis; it should never use HTML
tags, Markdown emphasis, a pipe-delimited banner, heading, table, or multi-line
panel.

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

`compass-orchestrator` owns the master Compass TODO Board. Subagents receive
assigned TODO items and focused Context Packets, then report status back.

Expanded TODO Board example:

```text
Compass TODO Board
- [done] Context scan checkout validation paths
- [active] Planner drafts scoped implementation plan
- [queued] Implement validation helper
- [queued] Add validation tests
- [blocked] Resolve plan conflict
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
Packet to the right agent, and returns compressed evidence to the planner. The
planner/evidence loop repeats until the planner can produce a good plan, asks
the user a question, or reaches a stop condition.

Required handoff markers:

```text
Compass handoff: compass-context-scout
Purpose: find the relevant files.
Mode: sequential
Compass return: compass-context-scout
Result: found the primary component and test file.
Next: ask compass-planner for a scoped plan.
```

For parallel execution:

```text
Compass parallel group 1
Agents:
- compass-implementer: form validation files
- compass-implementer: validation tests
Join condition: both agents complete without plan conflicts.
```

After joining:

```text
Compass parallel group 1 complete.
Result: both workers completed; no plan conflicts reported.
```

The user should never have to infer whether the orchestrator is thinking,
delegating, waiting on a subagent, or joining parallel work.

### `verification-gate`

Use after implementation and before final response.

Required checks:

1. Compare implementation against the assigned plan.
2. Confirm no unrelated files changed.
3. Run focused tests when available.
4. Summarize unverified assumptions.
5. Summarize remaining risks.

Final report format:

```md
## What Changed

- File:
- Change:

## Validation

- Command:
- Result:

## Plan Adherence

- Followed assigned plan:
- Deviations:

## Remaining Risks

- Risk:
- Suggested follow-up:
```

## 14. Session Behavior

Compass should feel like entering a coordinated workspace.

### User starts Compass

```text
/compass
```

Compass responds by taking the role of orchestrator and asking what the user
wants to work on. It must explicitly announce:

```text
Compass active. You are speaking with compass-orchestrator.
```

### User describes a task

```text
Add validation to the checkout form.
```

Compass flow:

1. Orchestrator announces the active phase.
2. Orchestrator asks clarifying questions if needed.
3. Orchestrator announces any subagent handoff.
4. Context scout finds relevant files if needed.
5. Orchestrator announces the subagent return and next step.
6. Planner drafts a plan.
7. Orchestrator discusses the plan with the user.
8. User approves or edits the plan.
9. Implementer executes.
10. Test runner validates.
11. Verification gate checks adherence.
12. Orchestrator summarizes the result.

### User wants speed

The user can say:

```text
Proceed after the plan unless I explicitly ask for a manual checkpoint.
```

Compass may then show a micro-plan and continue automatically.

### User wants strict control

The user can say:

```text
Strict mode. Show me every plan and wait for my checkpoint before implementation.
```

Compass must wait for the requested checkpoint before editing.

## 15. Success Criteria

Compass is successful when:

- A user can start a Compass session with one prompt.
- The main chat behaves as the orchestrator after Compass starts.
- The planner can ask questions and revise plans before implementation.
- The user can tell which Compass role is currently speaking.
- The user sees each subagent handoff, return, and parallel execution group.
- Implementation begins after plan presentation unless the user requested a
  checkpoint.
- Context-heavy work is delegated and summarized.
- Implementation follows the assigned plan.
- Verification reports what was checked and what remains risky.
- Normal Claude Code sessions remain unaffected when Compass is not active.

## 16. Implementation Order

Build in this order:

1. Create `compass/.claude-plugin/plugin.json`.
   - Verify: plugin metadata is valid.
2. Create `compass/settings.json`.
   - Verify: plugin activates `compass-orchestrator` as the main agent.
3. Create `compass/agents/compass-orchestrator.md`.
   - Verify: Compass session can route and ask questions.
4. Create `compass/agents/compass-context-scout.md`.
   - Verify: broad search returns compressed evidence.
5. Create `compass/agents/compass-planner.md`.
   - Verify: planner produces user-aligned plans and does not edit files.
6. Create `compass/agents/compass-plan-auditor.md`.
   - Verify: auditor reviews plans without editing files.
7. Create `compass/agents/compass-implementer.md`.
   - Verify: implementer follows the assigned plan.
8. Create `compass/agents/compass-test-runner.md`.
   - Verify: focused tests are summarized.
9. Create `compass/agents/compass-log-digester.md`.
   - Verify: noisy logs are compressed.
10. Create internal workflow skills.
   - Verify: orchestrator can use them as procedural guidance.
11. Create `compass/skills/plan-audit/SKILL.md`.
    - Verify: user can trigger "audit the plan".
12. Create `compass/skills/visibility-protocol/SKILL.md`.
    - Verify: session start, handoff, return, and parallel markers are defined.
13. Add `README.md`.
    - Verify: setup and session usage are clear.
14. Test locally with the plugin loader.
    - Verify: agents appear, Compass starts, and routing works.

## 17. Validation Prompts

### Session start

```text
/compass
```

Expected behavior:

- Compass becomes the active routed workspace.
- Compass announces the user is speaking with `compass-orchestrator`.
- The orchestrator asks what the user wants to work on.

### Planning separation

```text
Add a small feature. Make a plan and align with me before implementation.
```

Expected behavior:

- Orchestrator announces the context or planning phase.
- Orchestrator delegates context if needed.
- Orchestrator announces handoff and return for each subagent.
- Planner creates a plan.
- Orchestrator discusses plan with the user.
- No implementation happens before approval.

### Plan audit

```text
Audit the plan before implementation.
```

Expected behavior:

- Orchestrator builds an Audit Packet.
- `compass-plan-auditor` reviews the plan against stored context and evidence.
- Orchestrator routes pass, revision, more-context, or block results before
  implementation.

### Context-cost check

```text
Investigate how authentication works in this repo. Do not edit files.
```

Expected behavior:

- Context scout performs broad read-only discovery.
- Main session receives compressed evidence.
- No implementer is used.

### Debugging check

```text
Diagnose the failing tests and propose the smallest fix. Do not implement until
I approve.
```

Expected behavior:

- Test runner or log digester summarizes failure.
- Context scout finds relevant code.
- Planner proposes the fix plan.
- No implementation happens before approval.

### Implementation check

```text
Approved. Implement the plan.
```

Expected behavior:

- Implementer makes scoped changes.
- Implementer stops if the plan is invalidated.
- Test runner validates.
- Orchestrator reports plan adherence and remaining risks.

## 18. Open Questions

1. Exact launcher mechanics:
   - Target UX is `/compass`.
   - If Claude Code requires plugin skill namespacing in the selected install
     path, use the closest supported launcher while preserving the Compass
     session-mode behavior.
2. Default planner model:
   - Opus is best for high-risk planning.
   - Sonnet may be enough for everyday plans.
   - Start with Opus for planner if cost is acceptable; otherwise make the
     planner inherit or use Sonnet and escalate to Opus only on risk triggers.
3. Parallel implementers:
   - Keep the design ready for parallel execution groups.
   - Do not optimize for parallelism until the basic Compass session flow works.

## 19. Final Design Summary

Compass creates a routed Claude Code workspace.

The main session is the orchestrator. The planner decides. The user aligns. The
implementer executes. Cheap agents absorb noisy or token-heavy work. Verification
checks the result before the final response.

The critical shift from the earlier design is packaging:

- No always-on project-level routing.
- No need to invoke a specific workflow skill for every task.
- Start Compass once, then work normally inside the routed session.
