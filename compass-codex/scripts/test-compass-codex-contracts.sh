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
grep -Fq 'model = "gpt-5.6-terra"' "$PLUGIN_DIR/agents/compass-implementer.toml" || fail 'implementer must use Terra'
grep -Fq 'model = "gpt-5.6-terra"' "$PLUGIN_DIR/agents/compass-doer.toml" || fail 'doer must use Terra'
grep -Fq -- '-m gpt-5.6-sol -c model_reasoning_effort=medium' "$PLUGIN_DIR/scripts/compass" || fail 'orchestrator must use Sol medium'
grep -Fq 'tui.status_line=["model-with-reasoning","run-state","context-remaining","git-branch"]' "$PLUGIN_DIR/scripts/compass" || fail 'launcher must configure the native status line'
grep -Fq "Users can run \`/agent\`" "$PLUGIN_DIR/skills/compass/SKILL.md" || fail 'skill must document native agent visibility'
if grep -Fq 'Compass: compass-orchestrator' "$PLUGIN_DIR/skills/compass/SKILL.md" "$PLUGIN_DIR/commands/compass.md"; then
  fail 'Codex Compass must not emit a simulated status line'
fi

printf 'Compass Codex contracts passed.\n'
