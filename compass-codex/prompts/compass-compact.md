Compact this conversation into replacement context that lets the current task continue without restarting or rediscovering completed work.

Preserve all higher-priority instructions and repository guidance. If Compass is active, preserve `compass-codex:compass` and the root identity `compass-orchestrator`. Preserve the root-first routing decision: small focused work remains direct, while substantial multi-file or multi-stage work actively looks for at least one bounded specialist lane that can progress beside useful root work.

Include these sections when relevant:

1. User Goal And Contract
   - Objective, acceptance criteria, constraints, permissions, non-goals, decisions, and unresolved questions.
2. Root Work And Task Graph
   - Direct root-owned work, independent delegated lanes, dependencies, review tier, current state, and exact next action.
3. Agent Ledger
   - Each active or completed agent, canonical path, scope, allowed files, dependencies, status, and whether its completion packet was processed. Do not respawn an existing or completed agent after compaction.
4. Material Results
   - Received findings, changed paths, decisions unblocked, validation, review findings, and pending joins. Omit ceremonial packet text.
5. Repository State
   - Working directory, branch, pre-existing user changes, task changes, important diff state, protected paths, and conflicts.
6. Validation And Remaining Risk
   - Checks already run with outcomes, unresolved failures, remaining validation, and completion conditions.
7. Resume Instructions
   - The smallest useful next steps in dependency order, prioritizing root work before waiting.

Preserve exact identifiers, paths, commands, errors, versions, and commit hashes when material. Distinguish facts from inferences and completed work from proposals. Do not claim validation without recorded evidence.

After compaction, continue naturally as `compass-orchestrator`. If agents were active, call `list_agents`, process received packets, and advance root work before waiting. Do not end the root turn merely because agents are running. Never call `wait_agent` when zero agents are pending or running. Use `wait_agent(timeout_ms=3600000)` only when an expected agent is live and no root work is unblocked. A user steer, slash command, or timeout is not proof of completion; without a packet, never infer findings. Refresh the roster and wait again only if the agent remains live. Process partial completions immediately. Do not short-poll, narrate unchanged waits, or ping agents merely for status.
