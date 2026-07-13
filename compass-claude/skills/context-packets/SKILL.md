---
description: Internal Compass rules for building focused subagent Context Packets and Audit Packets.
---

# Context Packets

Use this skill whenever `compass-orchestrator` prepares an Agent-tool prompt for
a Compass subagent. The orchestrator owns packet construction. Subagents consume
the packet, restate the assigned work when their prompt requires it, and return
the requested output shape.

## Packet Rules

- Build one packet per subagent launch.
- Keep packets scoped to the assigned TODO item or execution group.
- Include enough evidence for the subagent to act without rediscovering the
  whole task.
- Prefer paths, symbols, commands, and compact evidence summaries over raw file
  dumps or long logs.
- State what is out of scope so focused agents do not widen the work.
- Include permission constraints when the subagent may run Bash or change
  files.
- State stop conditions that should return control to `compass-orchestrator`.
- For parallel groups, give each subagent a packet with distinct write targets
  or independent evidence questions.
- For planning, build one `compass-planner` packet per independent planning
  lane, risk area, or competing implementation option. Do not collapse multiple
  independent lanes into one broad planner packet unless a single architectural
  decision must be made first.
- Build a `compass-complex-planner` packet only when the user explicitly asks
  for the complex planner, Fable planner, or deep planning mode. Do not infer
  this route from task size, risk, ambiguity, or failed attempts. Include the
  explicit user direction in the packet.
- For implementation plans, build one `compass-implementer` packet per
  Execution Group. Do not make the full approved plan the assigned scope for a
  single implementer unless the planner produced exactly one sequential group.
  Each implementer packet must be implementation-ready: exact allowed files,
  ordered edit steps, expected behavior change, validation command, and stop
  conditions. If the orchestrator cannot fill those fields, return to planning
  or evidence gathering instead of launching implementation.
  Set implementation mode to direct target branch/current working tree. Do not
  ask implementers to create isolated worktrees.
  Do not assign "all groups", "Groups 1-N", "all steps", the whole plan, or
  multiple independent execution groups to one implementer. Run the
  Implementation Launch Gate before launch.
- For ordinary delegated work, build one `compass-doer` packet per independent
  artifact, inspection, command, file update, repository object, URL, or
  external side effect.
- Run the Packet Quality Checklist before launching any subagent.
- Use Packet Review only when the checklist flags risk or the packet will drive
  high-impact work.

## Packet Quality Checklist

The orchestrator runs this cheap self-check for every Context Packet before
launching a subagent:

- The assigned TODO item is concrete and action-oriented.
- The goal names the outcome, not just the activity.
- In scope and out of scope are both explicit.
- Relevant files, symbols, commands, evidence summaries, or search terms are
  included when known.
- Constraints include user instructions, repository limits, and workflow limits
  that could affect the agent's choices.
- Stop conditions tell the subagent when to return instead of guessing.
- Permission constraints identify simple preferred commands, approval-prone
  command forms to avoid, and whether file changes must use edit tools.
- Expected return format is specific enough for the orchestrator to route the
  result.
- The receiving agent can act without rediscovering broad context that the
  orchestrator already has.

If any item fails, revise the packet before launch or escalate to Packet
Review.

## Packet Review

Use Packet Review as a targeted judgment checkpoint, not as a default toll on
every handoff. The reviewer should be a stronger reasoning model when available,
but the review must stay narrow: improve the packet, do not re-plan the whole
task.

Trigger Packet Review when any of these are true:

- The packet drives implementation that touches shared behavior, public APIs,
  data models, migrations, auth, permissions, or security-sensitive code.
- The task is broad, ambiguous, or high-risk.
- The packet depends on compressed evidence from multiple agents.
- A prior subagent reported missing context, scope drift, or plan conflict.
- The user asks for extra caution.
- The orchestrator has low confidence after the Packet Quality Checklist.

Do not use Packet Review for narrow scout or doer tasks when the checklist
passes and the blast radius is low.

### Packet Review Bundle

Send this bundle to the reviewer:

```md
## Packet Review Bundle

- User request:
- Current TODO Board:
- Intended receiving agent:
- What the packet must enable:
- Proposed Context Packet:
- Evidence summaries used:
- Plan excerpt, if any:
- Known assumptions:
- Known risks:
- Specific review question:
```

Expected review output:

```md
## Packet Review Result

- Result: pass | revise | block
- Missing context:
- Ambiguous instructions:
- Scope risks:
- Suggested packet edits:
```

Route the result as follows:

- `pass`: launch the subagent with the packet.
- `revise`: apply the suggested packet edits, then launch if the checklist now
  passes.
- `block`: stop and resolve the missing context, user decision, or plan issue
  before launching the subagent.

## Base Context Packet

Use this base shape for ordinary subagent launches, then add the relevant
agent-specific fields below.

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
- Permission constraints:
- Stop conditions:
- Expected return format:
```

## Permission Constraints

Use this guidance in packets whenever the receiving agent may run shell
commands or change files:

- Prefer one focused command per question over compound shell scripts.
- Prefer `git -C <repo> ...` over `cd <repo>` plus chained commands.
- Prefer `rg`, `git diff`, `git status`, `git show`, `sed`, `head`, and
  explicit file reads for inspection.
- Avoid `npx`, install/update commands, command substitution, shell loops over
  command output, dense pipes, `&&` / `||` chains, and output redirection unless
  explicitly required by the task.
- Do not create or modify repository files with shell writes: `echo`,
  `printf`, `cat >`, heredocs, `tee`, `sed -i`, `>` or `>>`.
- Use Edit, Write, or MultiEdit-style tooling for file changes.
- Do not run remote publishing or remote-write commands from the Claude sandbox:
  `git push`, `gh pr create`, `gh pr edit`, `gh pr merge`, `gh issue edit`,
  remote comments/posts, or remote service updates. Draft the remote update and
  command for the user to run outside the sandbox instead.
- Do not hide command failures with `>/dev/null` or `2>/dev/null`; let failures
  surface so they can be summarized.

## Agent Packet Profiles

## User-Facing Report Agents

`compass-planner`, `compass-plan-auditor`, and `compass-code-reviewer` produce
polished reports for the user. The orchestrator should relay those reports with
minimal framing and use the required Compass Routing Footer for routing
decisions. Packets for these agents should ask for a complete user-facing
report, not private notes for the orchestrator.

### `compass-context-scout`

Use for repository discovery and planner/auditor evidence requests.

Add:

- Question to answer:
- Search targets:
- Known files or symbols:
- Areas to avoid:
- Evidence needed:
- Output limit: include max files/commands and max response size:
- Budget guard: return partial evidence, gaps, and the next narrow evidence
  request instead of continuing broad discovery:
- Verdict required: yes/no, and verdict labels if applicable:

Expected return format:

1. Verdict or direct answer first when the packet asks a targeted question.
2. Relevant files and why they matter.
3. Important functions, classes, routes, schemas, or config entries.
4. Dependency relationships.
5. Constraints or risks discovered.
6. Open questions or evidence gaps.
7. Compact recommendation for the planner, including the next narrow evidence
   request if more scouting is needed.

For claim verification, require this compact shape:

```md
## Verdict

- Claim:
- Verdict: valid | invalid | partially-valid | inconclusive
- Confidence: high | medium | low
- One-sentence reason:

## Evidence

- `path`: fact found

## Gaps

- Missing or unverified evidence:

## Recommendation

- Suggested next step:
```

### `compass-planner`

Use when asking for a plan or plan revision.

Add:

- User request:
- Planning lane or option:
- Lane scope and boundaries:
- Relationship to other planner lanes:
- Expected join output:
- Evidence summaries:
- Non-goals:
- Decisions needed:
- Candidate files:
- Validation expectations:
- Known risks:

Expected return format:

- User Alignment.
- Recommendation.
- Implementation Plan.
- Files Likely Involved.
- Execution Groups.
- Risk Check.
- Instructions For Implementer.
- Stop Conditions.
- Compass Routing Footer.

### `compass-complex-planner`

Use only when the user explicitly asks for the complex planner, Fable planner,
or deep planning mode. Do not use this profile as an inferred escalation from
normal planning, even for broad or high-risk work.

Add:

- User request:
- Explicit user direction authorizing complex planner:
- Planning lane or option:
- Lane scope and boundaries:
- Relationship to other planner lanes:
- Expected join output:
- Evidence summaries:
- Non-goals:
- Architecture decisions needed:
- Candidate files:
- Validation expectations:
- Known risks:
- Stop condition if explicit direction is missing: return to `compass-planner`.

Expected return format:

- User Alignment.
- Recommendation.
- Architecture And Sequencing Notes.
- Implementation Plan.
- Files Likely Involved.
- Execution Groups.
- Risk Check.
- Instructions For Implementer.
- Stop Conditions.
- Compass Routing Footer.

### `compass-implementer`

Use for assigned implementation work only.

Add:

- Assigned plan excerpt for this execution group only:
- Execution group:
- Files allowed to change for this execution group:
- Files to read first:
- Ordered edit steps:
- Expected behavior change:
- Prior subagent results:
- Implementation mode: direct target branch/current working tree only:
- Validation command:
- Implementation Launch Gate result:
- Plan conflict triggers:

Expected return format:

- Changed files.
- Diff summary.
- Behavior changed.
- Validation run.
- Review readiness.
- Remaining risks.
- TODO item status.

### `compass-code-reviewer`

Use for reviewing implemented code, diffs, branches, worktrees, PR changes, or
focused file lists. This is for actual code review after code exists; use
`compass-plan-auditor` for reviewing proposed plans.

Add:

- Review target: diff, branch, PR, worktree, or file list:
- Diff source or comparison base:
- Files changed:
- User review checklist:
- Repository conventions to check:
- Known risks or sensitive areas:
- Tests or validation already run:
- Areas out of scope:
- Severity threshold for blocking:

Expected return format:

- Findings ordered by severity, with file and line references where possible.
- Open questions.
- Review notes, including scope reviewed, checks performed, tests inspected,
  residual risk, and TODO item status.
- Compass Routing Footer.

If more evidence is needed before a reliable review, return one or more Code
Review Evidence Requests:

```md
## Code Review Evidence Request

- Question to answer:
- Why it matters:
- Suggested agent: compass-context-scout | compass-doer
- Suggested target:
- Files, symbols, commands, or search terms:
- Constraints:
- Stop condition:
- Expected evidence:
```

### `compass-plan-auditor`

Use for independent plan review.

Build an Audit Packet instead of the base Context Packet:

```md
## Audit Packet

- Parent task:
- User request:
- Current plan:
- TODO Board:
- Context Packets:
- Evidence summaries:
- Planner assumptions:
- Files likely involved:
- Execution groups:
- Risk checks:
- Stop conditions:
- Known constraints:
- Expected audit output:
```

Expected return format:

- Result.
- Confidence.
- Summary.
- Checks.
- Findings.
- Required Fixes.
- Evidence Requests, if needed.
- Recommendation.
- Compass Routing Footer.

### `compass-doer`

Use for ordinary delegated work that does not need the full code-change
planning flow.

For multi-item ordinary requests, use one doer packet per independent item. Do
not ask one doer to inspect several unrelated repository objects, run unrelated
commands, or create a local artifact in the same packet unless one output
directly depends on another. Do not assign remote-write side effects to doers in
the Claude sandbox; assign drafting/preparation instead.

Add:

- Direct task:
- Tool, skill, command, or artifact to use:
- Files allowed to change, if any:
- Destructive actions assigned, if any:
- Handoff trigger:

Expected return format:

- Task completed.
- Tools, skills, or commands used.
- Files read or changed, if any.
- Key result.
- Validation or verification performed.
- Remaining risks or follow-up.
- TODO item status.

## Planner Evidence Request

When `compass-planner` needs more evidence, it returns this shape for the
orchestrator to convert into one or more `compass-context-scout` or
`compass-doer` packets:

```md
## Planner Evidence Request

- Question to answer:
- Why it matters:
- Suggested agent:
- Suggested scout target:
- Files, symbols, or search terms:
- Constraints:
- Stop condition:
- Expected evidence:
```
