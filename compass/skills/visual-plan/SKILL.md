---
name: visual-plan
description: >-
  Deprecated parked Compass skill. Kept for future local visual plan work, but
  not active in Compass routing.
  Turn ordinary text plans into rich interactive visual plans with diagrams,
  file maps, annotated code, open questions, and UI/prototype review when
  useful.
metadata:
  visibility: internal
  status: deprecated
---

# Visual Plan Deprecated

This skill is currently deprecated in Compass. It is kept in the repository as
parked source material for a possible future local plan viewer, but active
Compass agents should not load or route to it by default.

If this skill is reactivated later, the intended direction is local repo-owned
artifacts under `plans/<slug>/`, not hosted connector plans.

## Archived Guidance

Agent-Native Plans is structured visual planning mode for coding agents. Build
the plan you would normally write in Markdown, but as a scannable document with
editable blocks mixed in: inline diagrams, code snippets,
open questions, and an optional top visual review area (wireframe canvas, live
prototype, or both in tabs). Architecture and backend plans stay document-only;
UI and product plans start with the top canvas/prototype (the Visual Surface
Choice section owns that rule).

`/visual-plan` is the packaged command and main entry point. Choose the review
mode from the task: UI-first when the work is primarily product UI and review
should start with screens, prototype-first when review should start with a
functional live prototype, design-first when review needs full-fidelity branded
screens, or visual-intake when the user explicitly wants a questionnaire before
planning. When a Codex, Claude Code, Markdown, or pasted plan already exists,
`/visual-plan` uses that source plan as the starting point and builds the review
surface from it instead of starting over.

## When To Use

Create or adapt a visual plan whenever the plan would be better as a reviewable
artifact than a chat paragraph. This includes modest work such as a single UI
surface with states, a small workflow, a before/after product change, or a
component/API/data-shape decision that needs alignment, plus larger multi-file,
ambiguous, long-running, risky, or UI-heavy work. Use it when architecture /
data flow / UI direction / options / open questions would benefit from inline
diagrams or structured blocks, when the user needs to react to a direction
before you implement, or when an existing text plan needs a richer review
surface.

## Plan Discipline

- **Gate thoughtfully.** A visual plan is a richer review surface, not only a
  tool for giant projects. Use it when the user needs to see, compare, comment
  on, or approve a direction before code, even for a modest UI/state/workflow
  change. Skip it for truly trivial, unambiguous work — typos, one-line fixes, a
  single well-specified function, anything whose diff you could describe in one
  sentence — and just make the change. Never pad a plan with filler and never
  ship a single-step plan.
- **Research before you draft.** Read the real files, actions, schema, and
  patterns first; name actual files, symbols, and data shapes instead of
  inventing them. Check existing `actions/` before proposing endpoints and prefer
  named client helpers over raw fetch. Delegate wide exploration to a sub-agent.
  Lead with reuse: for each step, name what it reuses — existing actions, schema,
  components, helpers — before what it adds, so the plan explains the genuinely new
  delta instead of redescribing what already exists.
- **Decide the hard-to-reverse bets first.** For non-trivial backend, data, or API
  work, sketch where the feature is headed, then call out the decisions that are
  expensive to undo once data or callers depend on them — wire format, public ids,
  data-model shape, auth and ownership boundaries — and get those right in the plan
  even if most of the feature ships later. Then scope to the smallest first cut that
  proves the approach without foreclosing it, stating both what is in and what is
  explicitly deferred.
- **Keep examples at the right altitude.** When the user's idea is a broad
  framework, product, or operating-model change, do not collapse it into the
  first concrete example, provider, or sync path they mention. Separate the core
  abstraction from motivating examples and app/provider adapters. Use examples
  to make the plan legible, but label them as examples unless they are the whole
  requested scope.
- **Publish standalone plans.** If the user pasted, referenced, or already has a
  Codex / Claude Code / Markdown plan, treat it as source material, but rewrite
  the published plan as a clean standalone proposal. Preserve the source plan's
  useful intent and codebase facts, label inferred visuals as inferred, and avoid
  revision language such as "preserve the prior plan", "do not drop the old
  idea", "unlike the previous version", or "this revision changes...". A reader
  who never saw the chat or earlier drafts should understand the plan.
- **Make the first read concrete.** If the plan is meant to be shared with
  someone outside the chat, or if the concept is abstract, lead near the top with
  one concrete product example before mode tables, architecture, or roadmaps. For
  UI-capable concepts, that usually means a top-canvas app state that shows the
  real user workflow in product terms. Do not rely on phrases that only make
  sense in conversation, and do not frame the plan as "not the old idea"; state
  the positive model directly.
- **Planning is read-only.** Make no source edits while building or reviewing the
  plan. Start editing only after the user approves the direction.
- **Clarify vs. assume.** Do not ask how to build it — explore and present the
  approach and options in the plan. Ask a clarifying question only when an
  ambiguity would change the design and you cannot resolve it from the code; use
  the host agent's normal ask-user-question flow and batch 2-4 high-leverage
  questions before finalizing. Otherwise state the assumption explicitly and
  proceed, and keep anything unresolved in the plan's single bottom
  `question-form` Open Questions block. For complex plans, do a final
  open-question pass before handoff: if a decision would affect architecture,
  scope, UX, data shape, or rollout, either decide it in the plan with rationale
  or put it in that bottom form with a recommended default.
- **The plan is the approval gate.** After surfacing it, ask the user to review
  and approve before you write code, and name which files/areas the work touches.
  Presenting the plan and requesting sign-off is the approval step — do not ask a
  separate "does this look good?" question.
- **The document is the source of truth, not the chat.** When scope shifts,
  update `plans/<slug>/plan.mdx`, `canvas.mdx`, or `prototype.mdx` rather than
  only changing course in chat, and make the updated document stand alone. Do
  not describe the update as a correction to an earlier draft inside the plan
  itself. Re-read the approved plan before major steps.

## Compass Local Plan Artifacts — Never Inline

In Compass, the deliverable is ALWAYS a structured local plan artifact under the
repository root `plans/<slug>/`, not a chat-only plan and not a hosted Plan
connector artifact. The Plan MCP connector is optional and must be used only
when the user explicitly asks for hosted publishing or commenting.

Create a folder such as `plans/pr-3-consume-the-verdict/` and write:

- `plan.mdx` for the review document.
- `canvas.mdx` when the plan needs wireframes, storyboards, or UI state maps.
- `prototype.mdx` only when the plan includes an interactive prototype.
- `.plan-state.json` only if the local Plan tooling needs state.

NEVER hand the plan over as inline chat content — no Markdown-only prose, ASCII
sketch, table, or fenced wireframe as the primary deliverable. A short chat
handoff may summarize where the local artifact lives and what to review, but the
plan itself belongs in `plans/<slug>/`.

Do not treat a missing Plan connector as a blocker. Do not ask the user to fix
hosted connector setup unless they explicitly ask to publish to the hosted Plan
app. Do not fetch a live block catalog, run a local bridge, or use external Plan
tooling unless the user explicitly asks for that extra validation or rendered
preview. The default Compass workflow is pure file authoring.

## Core Workflow

1. Follow the host agent's normal planning flow: inspect the codebase, delegate
   wide exploration when useful, gather the info needed, and ask native
   clarifying questions as needed before generating the plan. If a source plan
   already exists, gather its exact text from the user's paste, a referenced
   file, or recent visible agent context; do not invent source text.
2. Use the bundled references in this skill directory for block and wireframe
   guidance. Do not fetch a live block catalog by default. If the user
   explicitly asks for rendered validation/preview, you may use optional Plan
   tooling after approval.
3. For UI/product plans, compose the top canvas first with the primary
   wireframes and annotated states, then write the document with native blocks
   using the canvas, wireframe, and document-quality rules below. For
   broad product architecture plans with a user-facing implication, add a
   concrete "what this looks like in the app" visual before the abstract
   architecture or mode tables. Keep the document close to the standalone
   Markdown plan the agent would normally output. If an existing plan was
   provided, carry forward the right facts and decisions without referring to
   the previous draft or explaining how this version differs. For non-visual
   plans, skip the top visual surface (Visual Surface Choice below owns the rule)
   and put `diagram`, `data-model`,
   `api-endpoint`, `diff`, `file-tree`, `code`, and `annotated-code` blocks
   directly next to the relevant prose.
   Wide document layout is renderer-owned and intentionally allowlisted: only
   literal code-review surfaces (`diff`, `annotated-code`) and `tabs` blocks
   with vertical orientation or diff-like children break out wider than prose.
   Keep `api-endpoint`, `openapi-spec`, `data-model`, `json-explorer`,
   `wireframe`, question, and `custom-html` blocks in normal document flow unless
   their own renderer says otherwise.
4. Write the local MDX files under `plans/<slug>/`.
5. Surface the local artifact path, usually `plans/<slug>/plan.mdx`. If the user
   explicitly requested a rendered preview and approved the optional command,
   also report the preview URL.
6. Treat review feedback as file or chat feedback. Update `plan.mdx`,
   `canvas.mdx`, or `prototype.mdx` directly.
7. Use hosted create/update/export tools or external Plan tooling only when the
   user explicitly opts into that path.

## Self-Review Before Handoff

For high-stakes plans — architecture, backend, data-model, migration, multi-file,
or otherwise risky work — run one adversarial self-review pass before treating the
plan as final. Skip it for small, UI-only, or single-decision plans where the cost
outweighs the value. Keep the pass cheap and non-blocking:

- **Surface the plan first, review concurrently.** Post the link and let the user
  start reading, then run the review in parallel — never make the user wait on it.
- **Review the written plan; do not re-research.** Critique the plan text and its
  own blocks. The grounding was already done while drafting, so the review checks
  the output instead of re-exploring the repo.
- **Spawn one skeptical reviewer** whose only job is to find what is weak, missing,
  or wrong — not to praise. Point it at: hard-to-reverse decisions made implicitly
  or not at all (wire format, public ids, data-model shape, auth, ownership); steps
  not anchored in real files or symbols; a menu of options where the plan should
  commit to one; obvious missing decisions ("what happens when X?", "why not Y?");
  and padding or single-step filler.
- **Fix vs. ask.** Apply clear-cut fixes yourself by editing the local MDX files
  — vague non-goals, unanchored claims, an obvious missing decision. Route
  genuine judgment calls back to the user instead: add them to the bottom
  `question-form` Open Questions block or batch them into the normal
  ask-user-question flow. Do not silently decide them.
- **Do not surprise the user mid-read.** On a large plan, apply the patches before
  the editor loads; otherwise note briefly that a self-review is running so the
  plan changing under them is expected. When you next respond, summarize what the
  review changed and what it surfaced for the user to decide.

## Visual Surface Choice

Choose the surface before creating the plan or after reading the source plan. Do
not add visual chrome by default:

For UI/product plans, the top canvas is usually the primary review surface. Put
the first meaningful wireframes there, not buried as document-body blocks. Use
multiple canvas artboards when states matter, such as the default view, an
overflow menu or popover, a side panel, loading, or error. Put short annotations
beside frames with `targetId` plus `placement`; keep implementation details,
tradeoffs, file maps, data contracts, risks, and verification in the document
body below the canvas.

When the user asks for a flow, storyboard, journey, wireframe, canvas, or "what
this looks like", treat that as a canvas-first request. Make one artboard per
user-visible state, connect only adjacent transitions, and use short canvas
annotations for the product notes. Do not substitute a document-body `diagram`
block for the requested storyboard just because HTML diagrams are faster to
write; diagrams belong below the canvas for backend mechanics, architecture, or
data-flow explanation.

Keep product wireframes and explanatory/meta diagrams separate. Start with pure
screens that look like the app state under discussion, without callout prose or
architecture notes embedded inside the UI. Put arrows, labels, contracts, data
flow, and mode explanations in separate annotations, separate canvas diagrams,
or the document body.

When the plan touches an existing app, inspect the current shell/components
before drawing. The first artboard should look like the real app at the same
density: existing sidebars, toolbar placement, overflow menus, app chrome, and
framework agent chrome stay in their real places. Model secondary surfaces as
separate states, such as a top-right overflow popover, sheet, panel, loading
state, or separate AgentSidebar, rather than inventing a permanent inspector or
folding framework chrome into the product UI.

- **No visual surface** for architecture-only, backend-only, data migration,
  copy-only, or otherwise non-visual plans. Do not use the top canvas for
  architecture diagrams, dependency maps, file plans, API contracts, or
  data-flow-only reviews. Use a strong document with local inline diagrams
  only when relationships need a visual explanation, usually one spatial diagram
  per recommendation or decision. Prefer grouped regions, layers, quadrants,
  matrices, or before/after panels over a single-axis chain unless the
  relationship is truly sequential.
- **Canvas only** for one static screen, a before/after comparison, a component
  state, a small popover, or a visual direction that does not require clicking.
  Put those wireframes in `content.canvas` and omit `content.prototype`.
- **Canvas + prototype** for multi-step UI flows, onboarding, wizards,
  review/approval flows, navigation changes, or anything where the reviewer
  needs to operate the behavior. Keep the static wireframes in
  `content.canvas`, add the aligned functional prototype in
  `content.prototype`, and rely on the top visual tabs to switch between them.
- **Prototype-first** when the user asks to operate the UI or when interaction is
  the main question. Write `prototype.mdx`, and preserve static mocks in
  `canvas.mdx` where useful.

For mixed canvas + prototype plans, reuse the same real labels, app statuses,
and screen ids across both surfaces. The canvas is the inspectable static reference;
the prototype is the interactive version of that same flow, not a separate
design direction.

## Wireframe Quality

UI recap/plan wireframes must meet a strict quality bar — full-width chrome,
pinned bottom bars, real product content, before/after comparability, the right
`surface` preset, `--wf-*` tokens instead of hex, and no `<html>`/`<style>`/font
tags. Use semantic HTML fragments inside `<Screen surface="..." html={...} />`;
do not include full `<html>`, `<head>`, `<style>`, or font tags. Keep labels,
controls, rows, popovers, and before/after states realistic and padded so text
does not overlap.

## Canvas

The canvas is the static UI mockup surface: the `surface` locks each artboard's
footprint, mixed surfaces lay out in lanes, and annotations are plain-text
designer notes anchored by `targetId`/`placement`.
Canvas artboards use the same HTML wireframe path as document-body
`WireframeBlock` screens: author `<Screen surface="..." html={...} />` with a
semantic HTML fragment. Do not author fresh kit-tree children such as
`<FrameScreen>`, `<Card>`, `<Row>`, or `<Btn>` inside canvas `<Screen>` tags;
those are legacy compatibility markup for old plans and produce brittle canvas
layouts. Edit `plans/<slug>/canvas.mdx` directly for canvas changes.

## Document Quality

The document is a serious technical plan, not marketing: outcome-first,
prose-first, self-contained, built from the right native blocks, with open
questions in a single bottom `question-form` and a pre-handoff visual check.
Lead with the concrete outcome, ground claims in real files and symbols, keep
prose compact, and place structured blocks directly beside the explanation they
support.

## Optional Reference Files

The `references/` folder contains deeper maintainer notes and examples. Do not
read those files during normal skill use unless the user explicitly approves or
asks for deeper reference material; this skill is self-contained for the default
Compass workflow.

## Local Editing Guidance

Create and update `plans/<slug>/plan.mdx`, `canvas.mdx`, and `prototype.mdx`
directly. When the user critiques a plan's look or structure, update the local
artifact and improve this skill guidance when the feedback reveals a reusable
rule.

## Compass Local-Files Contract

Compass always uses the local-files contract for this skill unless the user
explicitly asks to publish to a hosted Plan app. The plan data must never be sent
to the Plan MCP server or Plan app action surface by default. Do not fetch the
live block catalog by default; use the bundled references.

The local-files contract is:

- Read source context from local files and shell commands only.
- Use the bundled references before writing structured MDX. For `checklist` and
  `question-form`, include stable ids and labels: checklist items need `id` and
  `label`; question-form questions need `id`, `title`, and `mode`; and each
  option needs `id` and `label`.
- Write the plan as a local MDX folder under the repository root
  `plans/<slug>/`. The folder contains `plan.mdx`, optional `canvas.mdx`,
  optional `prototype.mdx`, and optional `.plan-state.json`.
- Do not validate or serve with external Plan tooling unless the user explicitly
  asks for a rendered preview or validation.
- Do **not** call `create-visual-plan`, `create-ui-plan`,
  `create-prototype-plan`, `create-plan-design`, `import-visual-plan-source`,
  `update-visual-plan`, `patch-visual-plan-source`, `get-plan-feedback`,
  `export-visual-plan`, or any hosted Plan tool for that plan.
- Treat feedback as file or chat feedback: update the MDX files directly and
  summarize the changed local paths. Hosted comments, sharing, history, and
  publish/export receipts are unavailable until the user explicitly opts into
  publishing.

Local-files mode prevents plan content from going to the Agent-Native Plan
database. It does not by itself make the coding agent's language model local;
for that stronger privacy boundary, the host agent/model must also be local or
otherwise approved by the user.

## Interpreting comment anchors

For Compass local files, treat feedback as chat or file review feedback and
edit the local MDX files directly. Hosted comment anchors apply only when the
user explicitly asked to publish to hosted Plans.

- **Coordinate frames.** `targetX`/`targetY` are percentages *within* the
  element named by `targetSelector`/`targetKind`. Bare `x`/`y` are percentages
  of the whole plan document. `canvasX`/`canvasY` are raw board-world pixels on
  the design canvas (board size given when available).
- **Wireframe pins.** Anchors on wireframes include `targetNodeId` and
  `targetNodePath` (e.g. `card > list > listItem "Acme Inc"`) identifying the
  exact kit node. Use `targetNodeId` directly with wireframe node patch ops;
  use `data-design-id` values from design artboards with
  `update-design-element-style`. Prefer the node id/path over raw coordinates;
  fall back to coordinates plus the focused screenshot (red ring marks the exact
  point) only when no node id is present.
- **Text quotes.** Resolve `textQuote` against current prose using
  `contextBefore`/`contextAfter` for disambiguation. If `ambiguous: true`, ask
  the user — do not guess which occurrence is meant.
- **Detached comments.** `get-plan-feedback` flags threads whose quoted text no
  longer exists as `detached` (in `detachedThreads`). Reconcile these against
  rewritten content — never silently drop them.
- **Routing.** `resolutionTarget` is the only routing signal: act on `agent`,
  treat `human` as context only. `@mentions` are people to notify, never a
  routing signal.
- **Two-axis state.** Mark every ingested comment as consumed
  (`consumedCommentIds` on `update-visual-plan`). Set `status=resolved` only on
  agent-targeted comments you actually addressed; leave human-targeted comments
  open.

## Visibility & Sharing

Use `set-resource-visibility` and `share-resource` only for hosted plans the
user explicitly asked to publish. Compass local plan files under `plans/<slug>/`
follow repository access rules.

## Setup & Authentication

No hosted setup or external command is required for Compass local plan
artifacts. Create the `plans/<slug>/` MDX files directly from the bundled
instructions.

Hosted setup, authentication, sharing, and comments are outside the default
Compass flow. Mention them only when the user explicitly asks to publish or
share through the hosted Plan app.
