---
name: pr-feedback
description: Address GitHub pull request review feedback by building complete thread-aware context, classifying unresolved comments, making justified minimal fixes, rescanning affected behavior invariants, and drafting or posting responses only when authorized. Use when the user asks to inspect, triage, address, resolve, implement, or respond to PR feedback, review comments, or requested changes.
---

# PR Feedback

Handle one PR directly. If the user explicitly asks to process multiple PRs,
parallelize by PR only when the runtime permits it and the repositories or
working trees are independent.

Follow repository guidance and preserve unrelated work. Treat local code edits
as authorized when the user asks to address or fix feedback. Treat checkout,
commit, push, comment, review, thread-resolution, label, and PR-body operations
as separate actions that require explicit authorization.

## 1. Resolve The PR Safely

Resolve a supplied PR number, URL, or branch. Otherwise use the PR associated
with the current branch.

Inspect `git status -sb` before checking out or switching branches. Reuse the
current branch when it already contains the PR. If switching would interfere
with unrelated or ambiguous local changes, stop and ask instead of stashing,
discarding, or moving them.

## 2. Build Complete Context

Before deciding on any comment, read:

- Repository instructions and relevant product conventions.
- PR title, body, base and head branches, and current head commit.
- The complete diff against the base branch.
- Inline review threads, including resolution and outdated state.
- Review summaries and issue-level PR discussion.
- Relevant surrounding code, callers, tests, and types.
- Linked requirements only when they are material and accessible.

Prefer thread-aware GitHub reads for actionable feedback. Do not treat a flat
comment list as complete when resolution, replies, or outdated anchors matter.
Understand the PR's intent and the complete feedback set before editing; one
comment may conflict with another or expose a problem spanning several files.

## 3. Triage Every Active Thread

Classify each unresolved, non-outdated feedback thread:

| Decision | Meaning | Action |
| --- | --- | --- |
| `accept` | Correct and improves the PR within its intent | Make the change |
| `decline` | Incorrect, regressive, or conflicts with intended behavior | Keep the code and explain with evidence |
| `already-addressed` | Current code already satisfies the request | Point to the existing behavior |
| `out-of-scope` | Valid but materially outside this PR | Preserve scope and identify the follow-up |

Cluster duplicate or related comments by underlying behavior. Resolve
contradictory suggestions before editing. Prioritize correctness and established
repository conventions over preference-level style feedback. When feedback asks
for a specific contract or operational surface, do not silently substitute a
different one.

If the user asked to fix all feedback, implement every accepted cluster that is
unambiguous and in scope. Stop for a user decision when feedback changes product
behavior, meaningfully expands scope, or creates a material tradeoff. If the
user asked only for inspection or triage, report the decisions without editing.

## 4. Implement Accepted Feedback

For each accepted cluster:

1. Read the affected implementation and adjacent paths.
2. Make the smallest change that resolves the underlying issue.
3. Keep every changed line traceable to accepted feedback.
4. Add or update focused tests when behavior changes.

Do not change code for declined, already-addressed, or out-of-scope feedback.
Do not broaden into adjacent cleanup.

## 5. Rescan Affected Invariants

After high-risk fixes, review the affected behavior rather than only the
commented line. Identify:

- Changed persisted state.
- Async, retry, queue, manual recovery, or background flows.
- External side effects that must be durable.
- Success and terminal states.
- The invariant that must hold whenever each state is reached.

Check direct flows, retries, manual recovery UI, alternate updates, jobs,
callbacks, errors, missing-object and partial-failure handling, and cleanup.
When one comment reveals a shared invariant, scan all paths that can violate it
and fix the invariant instead of one symptom.

If a complete invariant-preserving fix would materially expand the PR, stop and
explain the tradeoff before applying a knowingly narrow fix. Run the narrowest
relevant tests, type checks, lint, or other validation after the changes.

## 6. Preserve The PR Narrative

When feedback resolves an ambiguity or establishes behavior a future reviewer
must understand, draft the corresponding update to the PR description. Fold the
decision and rationale into the dependency-ordered `Changes` narrative without
recounting the conversation or mentioning the agent.

Keep that narrative detailed enough to explain the end-to-end changed flow and
its important review boundaries. Expand high-importance contracts, permissions,
persisted state, migrations, concurrency, retries, lifecycle transitions,
public APIs, and external side effects with the relevant invariants, handoffs,
failure behavior, and affected consumers. Add or revise a focused Mermaid
diagram when three or more interacting components, ordered async work,
branching decisions, state transitions, or data relationships are materially
clearer visually. Do not add decorative diagrams or turn trivial changes into
architecture essays.

Update the remote PR body only when the user explicitly authorizes that action.

## 7. Perform Remote Actions Deliberately

Only when explicitly authorized:

- Stage the exact intended paths; never use `git add -A` in a mixed worktree.
- Commit and push the selected fixes.
- Reply to the in-scope unresolved threads with the decision, evidence, and
  resulting change or rationale.
- Resolve a thread only after its accepted change is present and supported by
  the requested validation.

Do not automatically reply to every historical comment, post a summary table,
apply AI-review labels, or publish canned responses. Keep replies concise and
specific. Do not describe a remote action as completed unless it succeeded.

## 8. Report The Result

Report the PR URL, decision for each active feedback cluster, files changed,
checks run, unresolved decisions, and any replies or remote actions that were
drafted rather than performed.
