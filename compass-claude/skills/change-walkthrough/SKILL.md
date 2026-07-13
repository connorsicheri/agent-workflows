---
description: Create a local interactive HTML walkthrough that explains a PR, branch, worktree, local diff, or explicit file list for reviewers and future maintainers.
---

# Change Walkthrough

Use this skill when the user asks for an HTML walkthrough, PR walkthrough,
change summary document, reviewer guide, branch explanation, or local artifact
that explains code changes. The output is a comprehension artifact for humans,
not a PR update by default.

## Output Contract

- Write one local `.html` file, defaulting to `local-notes/<slug>.html` unless
  the user specifies another path.
- Keep it local-first and repo-private. Prefer ignored folders such as
  `local-notes/`; do not add the artifact to the PR diff unless requested.
- Do not update the PR body, issue, or remote service from the Claude sandbox.
  If the user asks for a PR update, draft the text and exact command for the
  user to run outside the sandbox. If both an HTML artifact and PR update text
  are requested, Compass should split them into separate doer tasks.
- Use normal file edit/write tooling for the HTML. Do not create it with shell
  redirects, heredocs, `tee`, or `echo >>`.
- Do not require `npx`, hosted plan tooling, build tools, or external preview
  services.

## Evidence Rules

Before authoring, identify the diff source:

- GitHub PR number or URL.
- Local branch compared with a base branch.
- Local uncommitted diff.
- Worktree path.
- Explicit file list or user-provided notes.

Gather enough evidence to make the document trustworthy:

- Changed files and diff summary.
- Important routes, components, actions, queries, data models, migrations, and
  tests.
- Existing PR body or issue description when the user asks to compare or update
  it.
- Generated-file or snapshot-heavy diff areas that should be separated from
  human-authored logic.

Distinguish verified facts from inference. Do not claim behavior unless it is
supported by source, tests, PR text, or user-provided context. If something was
not verified, say so in the artifact.

## Document Shape

The artifact should answer these in the first minute:

1. What changed?
2. What feature areas or workstreams exist?
3. Which files should a reviewer inspect first?
4. What is the end-to-end flow?
5. What security, correctness, data, or UX risks matter?
6. What tests or validation back it up?
7. What is uncertain or not verified?

Use this default section order, omitting sections that do not apply:

1. Overview.
2. Reviewer path: top files to inspect first and why.
3. Architecture or end-to-end flow.
4. Feature/workstream sections.
5. File-by-file changes grouped by area.
6. Security, permissions, data, migration, or observability notes.
7. Tests and validation.
8. Risks, open questions, and what was not verified.
9. Optional PR-description-ready summary, only when requested.

## HTML UX Pattern

Use a readable, self-contained HTML document:

- Fixed compact header with PR/branch/title metadata.
- Sticky numbered side nav on desktop; hidden or simplified on mobile.
- Constrained main content width with generous spacing.
- Small stat cards for diff size, generated files, changed files, tests, or
  feature areas when useful.
- Badges for states, statuses, risk levels, or feature areas.
- Tables for file-by-file review maps.
- Callouts for important review context.
- Responsive CSS in a `<style>` block.
- Minimal JavaScript only for local navigation affordances such as scrollspy.

Avoid ornamental hero pages, marketing copy, animations, or decorative visual
noise. The document should feel like a practical reviewer surface.

## Diagrams

Use Mermaid-style diagrams when they reduce cognitive load:

- `flowchart` for architecture, data flow, or branching logic.
- `sequenceDiagram` for request, upload, async processing, and integration
  flows.
- `stateDiagram-v2` for lifecycle/status transitions.

Do not force diagrams into simple changes. If Mermaid rendering depends on a
CDN or external script, make that tradeoff visible in the HTML comments or use a
styled `<pre>` fallback. The document must remain readable even if diagrams do
not render.

## Content Quality

- Keep prose concrete and reviewer-oriented.
- Group files by feature area or responsibility, not just alphabetically.
- Include a "diff reality check" when generated files dominate line counts.
- Include a "reviewer path" for large changes.
- Prefer short snippets or function names over large pasted code blocks.
- Use file paths and symbols as evidence anchors.
- Name tests that were read or run, and note gaps.
- Call out when the PR body omits a feature area discovered in the diff.

## Completion

After writing the artifact, verify:

- The file exists at the intended path.
- It contains the expected title and major sections.
- Links/anchors are internally consistent.
- The document can be opened directly in a browser.

Return the path, the evidence source, the major sections included, and any
unverified areas.
