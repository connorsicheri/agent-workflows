# Good Engineering Practices

This checklist distills the recurring signals used by Compass PR reviewers.
Use it during design, implementation, and review. Apply only the relevant items,
and prefer the repository's established conventions and the user's requirements
when they are more specific.

## Correctness And Safety

- [ ] Preserve existing behavior and public contracts unless the change
  intentionally updates them.
- [ ] Check edge cases, empty states, failure paths, ordering, async behavior,
  and state transitions—not only the happy path.
- [ ] Validate data at system boundaries with explicit schemas or DTOs instead
  of making callers probe uncertain shapes.
- [ ] Give extra scrutiny to authorization, migrations, deployments, external
  integrations, and operations that can expose or destroy data.
- [ ] Keep secrets, credentials, personal data, and other sensitive values out
  of source code, errors, and logs.

## Clarity And Simplicity

- [ ] Use descriptive, searchable names that express business meaning. Prefer
  verb-led function names and clear boolean names such as `isReady`,
  `hasAccess`, or `canRetry`.
- [ ] Keep control flow easy to scan with guard clauses and early returns. Avoid
  deep nesting, nested ternaries, and long boolean expressions.
- [ ] Keep each function at one level of abstraction: business steps should not
  compete with low-level formatting, transport, persistence, or logging details.
- [ ] Give modules, components, hooks, and services one clear responsibility.
- [ ] Prefer the smallest implementation that solves the current requirement;
  avoid speculative abstractions and configuration.
- [ ] Replace business-significant strings, thresholds, timeouts, retry counts,
  statuses, and indexes with well-named constants, enums, maps, or configuration.

## Boundaries And Reuse

- [ ] Search for established helpers, primitives, and patterns before adding a
  new one. Do not create near-duplicates or repeated fallback logic.
- [ ] Put helpers and constants where maintainers will expect to find them,
  following the repository's existing structure.
- [ ] Separate rendering, domain decisions, data fetching, state
  synchronization, response normalization, and payload construction when they
  are substantial enough to obscure one another.
- [ ] Keep internal transport or database shapes behind clear interfaces rather
  than leaking them into UI or unrelated callers.
- [ ] Prefer immutable data and dependency injection when they create a clearer
  boundary or materially improve testability.
- [ ] Reuse design tokens, theme variables, shared UI primitives, and the
  existing localization layer instead of adding one-off styles or raw
  user-facing strings.

## Tests And Verification

- [ ] Add focused coverage for changed business rules, API boundaries,
  authorization, migrations, hooks, selectors, utilities, fallbacks, empty
  states, errors, and important UI states.
- [ ] Test behavior and meaningful branches, not merely implementation details
  or the happy path.
- [ ] Reproduce a bug with a failing test when practical, then verify the fix
  makes that test pass.
- [ ] Run the narrowest relevant tests, lint, type checks, builds, or contract
  checks and inspect the final diff before declaring the work complete.
- [ ] Confirm that every changed line supports the requested outcome and that
  unrelated user changes remain intact.

## Documentation And Operations

- [ ] Include JSDoc or the language's equivalent docblock for important exported
  functions, classes, components, hooks, types, interfaces, and reusable
  utilities. Explain purpose, inputs, outputs, side effects, errors, and
  non-obvious constraints without merely repeating the signature.
- [ ] Include descriptions on collections and their fields. Explain each
  field's business meaning, expected format or unit, allowed values, default,
  required or optional behavior, and relationships when those details are not
  self-evident. Apply the same standard to schemas, DTOs, forms, and
  configuration objects.
- [ ] Document callbacks, async behavior, loading and error states, controlled
  state, and non-obvious business rules where the code alone does not
  communicate intent.
- [ ] Update README files, sample environment files, configuration examples,
  setup instructions, and operational docs when developer-visible behavior
  changes.
- [ ] Add a small Mermaid flowchart, sequence diagram, state diagram, or entity
  relationship diagram when it materially clarifies a multi-step workflow or
  architecture.
- [ ] Use structured, useful observability events with enough safe context to
  diagnose failures, while avoiding noisy or sensitive logs.
- [ ] Remove imports, variables, helpers, comments, and branches made obsolete
  by the current change. Do not broaden the cleanup to unrelated code.
- [ ] Treat files over roughly 400 lines as a prompt for extra scrutiny, not an
  automatic refactor; split them only when responsibility, navigation, or
  testability has genuinely degraded.

## Review Discipline

- [ ] Review the requested behavior, diff, tests, and relevant surrounding code
  before judging a change.
- [ ] Lead with correctness, security, data-loss, contract, migration, and
  regression risks; keep style comments proportional to their actual impact.
- [ ] Tie every finding to concrete evidence, explain why it matters, and
  suggest the smallest reasonable fix.
- [ ] Distinguish blocking issues from targeted follow-ups and order findings by
  severity.
- [ ] If evidence is missing, ask a focused question instead of guessing. If no
  issues are found, state the residual risk or unverified area clearly.
