# /visual-plan

Deprecated in Compass. This folder is parked for possible future local visual
plan work, but active Compass agents should not route to it by default.

Turn ordinary implementation plans into rich interactive visual review surfaces.

`/visual-plan` turns the plan an agent would normally write in chat into a
human-optimized MDX document. Instead of a long wall of prose, reviewers get
custom components built for understanding: architecture diagrams, wireframes,
interactive prototypes, file maps, annotated code, OpenAPI-style API specs,
visual schema maps, open questions, and comments.

It solves for plans that are too important to bury in chat. The output is
scannable and intuitive enough for a human to approve before code changes start.

In Compass, visual plans are MDX folders under the repository root
`plans/<slug>/`. The default path writes MDX locally and does not require a Plan
connector, bridge, external command, or upstream install.

## What It Does

- Grounds plans in real repo files, schemas, actions, and symbols.
- Chooses the right visual surface: document-only, wireframe canvas, prototype,
  design direction, or visual intake.
- Uses MDX and custom components for diagrams, UI flows, API specs, schema maps,
  diffs, code annotations, and reviewer questions.
- Writes the result as a structured local review document instead of inline chat Markdown.
- Keeps the plan as the approval gate before source edits begin.

## When To Use It

Use it for multi-file, ambiguous, risky, architecture-heavy, data-heavy, or
UI-heavy work where the wrong direction would be expensive. It is also useful
when a pasted text plan needs a richer review surface.

Skip it for trivial fixes, single-line changes, or anything whose diff is easier
to review than a plan.

## What Reviewers Get

Reviewers get a local plan artifact that is built for scanning. Decisions,
files, diagrams, contracts, UI states, prototype behavior, schema shape, API
boundaries, and unresolved questions live in one consumable place.

The point is not just prettier planning. It is a better medium for human review:
visual where visuals help, structured where structure helps, and grounded in the
actual codebase.

## Modes

`/visual-plan` can run in these modes:

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
