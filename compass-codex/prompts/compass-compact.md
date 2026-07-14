Compact this conversation into replacement context that lets the current task continue without restarting or rediscovering completed work.

Preserve all higher-priority instructions and repository guidance. If Compass is active, preserve `compass-codex:compass` as the active workflow and preserve the root agent's identity as `compass-orchestrator`. The orchestrator continues to own user alignment, the master TODO board, Context Packets, routing, partial joins, final joins, review, and verification.

Include these sections when relevant:

1. User Goal And Contract
   - Current objective, acceptance criteria, constraints, permissions, non-goals, user decisions, and unresolved questions.
2. Compass Orchestration State
   - Current phase, master TODO items with exact statuses, routing decisions, launch gates, stop conditions, and the exact next action.
3. Agent Ledger
   - Every active, completed, failed, or interrupted agent with its canonical thread path, role, assigned scope, allowed files, dependencies, status, and whether its completion packet was received and processed.
   - Preserve which agents are still expected to return. Do not respawn an existing or completed agent merely because compaction occurred.
4. Completion Packets And Partial Joins
   - Material findings from every received packet, including paths, symbols, commands, evidence, risks, decisions unblocked, and work still blocked on other packets.
   - Preserve pending joins and identify which packet or condition unlocks each dependent action.
5. Repository And Worktree State
   - Working directory, branch, relevant baseline, pre-existing user changes, files changed during this task, important diff state, generated artifacts, and any conflicts or protected paths.
6. Decisions And Evidence
   - Accepted and rejected approaches with reasons, assumptions, exact paths and symbols, API or schema constraints, migrations, and externally verified facts or sources.
7. Validation And Review
   - Commands and tests already run with outcomes, review findings, unresolved failures, remaining validation, and what must be true before completion can be claimed.
8. Resume Instructions
   - The smallest safe next steps in dependency order.

Preserve exact identifiers, agent paths, filenames, commands, error messages, version numbers, and commit hashes when they matter. Distinguish completed work from proposed work and facts from inferences. Do not claim validation or completion without recorded evidence.

After compaction, continue naturally as `compass-orchestrator`; do not introduce the task as new, ask the user to repeat known context, or redo completed exploration. If agents were active, call `list_agents`, reconcile the live roster, process any queued completion packets, and advance work that is safely unblocked. Never call `wait_agent` when zero agents are pending or running. If an expected packet is missing but its agent is no longer live, verify the assigned work and repository state directly instead of waiting. Use `wait_agent(timeout_ms=3600000)` only when the refreshed roster confirms at least one expected agent is pending or running. Do not short-poll or ping agents merely for status.
