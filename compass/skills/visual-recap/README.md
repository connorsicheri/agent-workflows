# /visual-recap

Deprecated in Compass. This folder is parked for possible future local visual
recap work, but active Compass agents should not route to it by default.

Turn a branch, commit, or PR diff into an interactive visual recap with
annotated diffs, diagrams, API/schema summaries, file maps, UI state summaries,
and focused review notes.

`/visual-recap` is the reverse of `/visual-plan`: instead of planning a future
change, it summarizes a diff, branch, commit, or PR after the work exists. The
goal is to help reviewers understand the shape of a change before they dive into
raw line-by-line diffs.

It solves for diffs that hide the shape of the change. Reviewers can understand
contracts, architecture moves, schema changes, and UI impact before diving into
raw line-by-line review.

The recap is a human-optimized MDX document with custom components for the
things raw diffs are bad at explaining: annotated diffs, diagrams, visual schema
maps, OpenAPI-style API diffs, file maps, UI state summaries, and focused review
notes.

In Compass, visual recaps are MDX folders under the repository root
`plans/<slug>/`. The default path writes MDX locally and does not require a Plan
connector, bridge, external command, or upstream install.

## What It Does

- Reads the actual changed files and diff.
- Writes an interactive local recap with file maps, diagrams, visual schema
  maps, API diffs, annotated diffs, UI state summaries, and focused key changes.
- Keeps recaps substantial enough for real review without dumping every line.
- Makes large changes consumable before a reviewer opens raw GitHub diff view.

## When To Use It

Use it for PRs or work units that are large, multi-file, UI-heavy, or touch
schema, API contracts, permissions, architecture, or review-critical behavior.

Skip it for tiny, obvious diffs that review faster directly in GitHub.

## What Reviewers Get

Reviewers get the shape of the change first: what moved, which contracts
changed, what data or API surfaces were touched, how UI states differ, and where
the risky lines are. Then they can review the raw diff with a map in their head.

## Modes

`/visual-recap` can run in these modes:

- **Compass local files (default):** writes `plans/<slug>/` and keeps the
  artifact in the repo.
- **Hosted Plans:** optional, only when the user asks for hosted publishing,
  comments, or sharing.
- **Self-hosted/custom URL:** optional, only when the user asks to connect a
  custom Plan app or local development tunnel.

Use local files mode by default. Use hosted mode only when the user wants
comments and shareable links. Rendered previews are optional and should only run
when the user asks for them.

## Compass Usage

Compass imports this skill directly. No hosted Plan MCP connector is required.
Create or update `plans/<slug>/plan.mdx`, optional `canvas.mdx`, and optional
`prototype.mdx`. External validation or rendered previews are optional and
should only run when the user asks for them.
