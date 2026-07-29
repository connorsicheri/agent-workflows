---
name: verification-gate
description: Apply a formal root-owned verification checklist to high-risk, strong-reviewed, or explicitly requested Compass work.
---

# Compass Verification Gate

This is a root-orchestrator checklist, not a separate agent or mandatory phase. Ordinary work uses focused validation and final diff inspection without invoking this skill.

For high-risk, strong-reviewed, or explicitly requested verification:

1. Compare the integrated result with the user's requested outcome.
2. Inspect the final diff and confirm unrelated changes were preserved.
3. Run the narrowest relevant tests, lint, type checks, builds, or contract checks.
4. Resolve or disclose material review findings and remaining uncertainty.

Verification evidence must come from the target working tree.
