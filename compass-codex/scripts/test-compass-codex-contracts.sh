#!/usr/bin/env bash
set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

for path in \
  "$PLUGIN_DIR/.codex-plugin/plugin.json" \
  "$PLUGIN_DIR/skills/compass/SKILL.md" \
  "$PLUGIN_DIR/skills/context-packets/SKILL.md" \
  "$PLUGIN_DIR/skills/verification-gate/SKILL.md" \
  "$PLUGIN_DIR/prompts/compass-compact.md" \
  "$PLUGIN_DIR/commands/compass.md"; do
  [[ -f "$path" ]] || fail "missing file: $path"
done

for agent in compass-context-scout compass-planner compass-plan-auditor compass-implementer compass-code-reviewer compass-doer; do
  path="$PLUGIN_DIR/agents/$agent.toml"
  [[ -f "$path" ]] || fail "missing agent: $path"
  grep -Fq "name = \"$agent\"" "$path" || fail "wrong agent name: $path"
  grep -Fq 'developer_instructions = """' "$path" || fail "missing instructions: $path"
done

grep -Fq 'Implementation Launch Gate' "$PLUGIN_DIR/skills/compass/SKILL.md" || fail 'missing implementation gate'
grep -Fq 'sandbox_mode = "read-only"' "$PLUGIN_DIR/agents/compass-planner.toml" || fail 'planner must be read-only'
grep -Fq 'sandbox_mode = "workspace-write"' "$PLUGIN_DIR/agents/compass-implementer.toml" || fail 'implementer must be writable'
grep -Fq 'model = "gpt-5.6-luna"' "$PLUGIN_DIR/agents/compass-context-scout.toml" || fail 'scout must use Luna'
grep -Fq 'model_reasoning_effort = "low"' "$PLUGIN_DIR/agents/compass-context-scout.toml" || fail 'scout must use low effort'
grep -Fq 'model = "gpt-5.6-sol"' "$PLUGIN_DIR/agents/compass-planner.toml" || fail 'planner must use Sol'
grep -Fq 'model_reasoning_effort = "xhigh"' "$PLUGIN_DIR/agents/compass-planner.toml" || fail 'planner must use xhigh effort'
grep -Fq 'model_reasoning_effort = "max"' "$PLUGIN_DIR/agents/compass-plan-auditor.toml" || fail 'auditor must use max effort'
grep -Fq 'model_reasoning_effort = "high"' "$PLUGIN_DIR/agents/compass-code-reviewer.toml" || fail 'reviewer must use high effort'
grep -Fq 'model = "gpt-5.6-sol"' "$PLUGIN_DIR/agents/compass-implementer.toml" || fail 'implementer must use Sol'
grep -Fq 'model = "gpt-5.6-terra"' "$PLUGIN_DIR/agents/compass-doer.toml" || fail 'doer must use Terra'
grep -Fq -- '-m gpt-5.6-sol --ask-for-approval on-request' "$PLUGIN_DIR/scripts/compass" || fail 'orchestrator must use Sol with reviewable approvals'
grep -Fq -- '-c approvals_reviewer=auto_review' "$PLUGIN_DIR/scripts/compass" || fail 'launcher must use Approve for me review'
grep -Fq -- '-c model_reasoning_effort=medium' "$PLUGIN_DIR/scripts/compass" || fail 'orchestrator must use medium effort'
grep -Fq 'experimental_compact_prompt_file=$COMPACT_PROMPT' "$PLUGIN_DIR/scripts/compass" || fail 'launcher must configure the Compass compact prompt'
grep -Fq 'tui.status_line=["model-with-reasoning","run-state","context-remaining","git-branch"]' "$PLUGIN_DIR/scripts/compass" || fail 'launcher must configure the native status line'
if grep -Fq -- '--ask-for-approval never' "$PLUGIN_DIR/scripts/compass"; then
  fail 'launcher must not reject approval requests automatically'
fi
if grep -Fq -- '--dangerously-bypass-approvals-and-sandbox' "$PLUGIN_DIR/scripts/compass"; then
  fail 'launcher must preserve the sandbox boundary'
fi
grep -Fq "Users can run \`/agent\`" "$PLUGIN_DIR/skills/compass/SKILL.md" || fail 'skill must document native agent visibility'
grep -Fq 'wait_agent(timeout_ms=3600000)' "$PLUGIN_DIR/skills/compass/SKILL.md" || fail 'orchestrator must use event-driven long waits'
grep -Fq 'call `list_agents` immediately before every `wait_agent`' "$PLUGIN_DIR/skills/compass/SKILL.md" || fail 'orchestrator must reconcile live agents before waiting'
grep -Fq 'If zero agents are pending or running, do not call `wait_agent`' "$PLUGIN_DIR/skills/compass/SKILL.md" || fail 'orchestrator must never wait with no live agents'
grep -Fq 'Never short-poll' "$PLUGIN_DIR/skills/compass/SKILL.md" || fail 'orchestrator must prohibit empty wait polling'
grep -Fq 'merely to ask whether an agent is done' "$PLUGIN_DIR/skills/compass/SKILL.md" || fail 'orchestrator must not ping agents for status'
grep -Fq 'Compass Orchestration State' "$PLUGIN_DIR/prompts/compass-compact.md" || fail 'compact prompt must preserve orchestration state'
grep -Fq 'Agent Ledger' "$PLUGIN_DIR/prompts/compass-compact.md" || fail 'compact prompt must preserve the agent roster'
grep -Fq 'Completion Packets And Partial Joins' "$PLUGIN_DIR/prompts/compass-compact.md" || fail 'compact prompt must preserve packet joins'
grep -Fq 'Do not respawn' "$PLUGIN_DIR/prompts/compass-compact.md" || fail 'compact prompt must prevent duplicate agents'
grep -Fq 'wait_agent(timeout_ms=3600000)' "$PLUGIN_DIR/prompts/compass-compact.md" || fail 'compact prompt must preserve event-driven waiting'
grep -Fq 'Never call `wait_agent` when zero agents are pending or running' "$PLUGIN_DIR/prompts/compass-compact.md" || fail 'compact prompt must preserve the zero-live-agent guard'
if grep -Fq 'Compass: compass-orchestrator' "$PLUGIN_DIR/skills/compass/SKILL.md" "$PLUGIN_DIR/commands/compass.md"; then
  fail 'Codex Compass must not emit a simulated status line'
fi

printf 'Compass Codex contracts passed.\n'
