---
name: context-packets
description: Build focused Compass Context Packets for Codex subagent handoffs. Use whenever Compass delegates repository research, planning, implementation, audit, review, or bounded execution.
---

# Compass Context Packets

Create one packet per subagent. Include compact evidence instead of raw dumps and make in-scope, out-of-scope, permissions, and stop conditions explicit.

```md
## Context Packet

- Parent task:
- Assigned TODO item:
- Agent:
- Goal:
- In scope:
- Out of scope:
- Relevant files/evidence:
- Constraints:
- Permission constraints:
- Stop conditions:
- Expected return format:
```

Before launch, confirm that the item is concrete, the outcome is testable, known paths and symbols are included, the agent can act without rediscovering broad context, and its return shape is routable.

For an implementer, also require:

```md
- Assigned plan excerpt for this execution group only:
- Execution group:
- Files allowed to change:
- Files to read first:
- Ordered edit steps:
- Expected behavior change:
- Implementation mode: direct current working tree
- Validation command:
- Implementation Launch Gate result: pass
- Plan conflict triggers:
```

Never assign multiple independent groups, “all groups,” or the whole plan to one implementer. Use separate packets and parallel agents when writes are independent.

Prefer focused commands and explicit reads. Preserve unrelated worktree changes. Do not use shell redirection, heredocs, `sed -i`, or similar shell writes for file edits; use apply_patch. Do not hide failures. Do not authorize remote writes unless the user explicitly placed them in scope.
