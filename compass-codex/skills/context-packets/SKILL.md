---
name: context-packets
description: Build compact Compass handoffs only when delegation has a concrete latency or independent-judgment benefit.
---

# Compact Context Packets

Packet preparation must be cheaper than doing the delegated task in the root. Include only context the specialist cannot efficiently discover inside its bounded scope.

```md
## Context Packet

- Goal:
- Relevant evidence:
- Constraints:
- Deliverable:
```

For file-writing work, add only:

```md
- Allowed files or subsystem:
- Expected behavior:
- Validation:
- Stop if:
```

For quick review, add the completed execution-group diff or file scope, expected
behavior, known risk, and validation already run.

For `compass-pr-reviewer`, add the complete final diff, original request,
resolved user clarifications, acceptance criteria, changed tests, known risks,
and prior review findings when this is a follow-up round. For stateful, async,
retry, background, or externally side-effecting work, identify candidate
success or terminal states so the reviewer can derive and check the governing
invariants across every path.

Create one packet per independent lane and launch parallel-safe lanes together. Keep tightly coupled work in one packet. Do not split work by file when the edits share a behavior, contract, or validation path.

Preserve unrelated worktree changes. Use `apply_patch` for file edits. Do not authorize destructive or remote writes unless the user explicitly placed them in scope.
