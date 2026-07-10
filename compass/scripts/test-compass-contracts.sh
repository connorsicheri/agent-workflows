#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COMPASS_DIR="$ROOT_DIR/compass"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_file() {
  local path="$1"
  [[ -f "$path" ]] || fail "missing file: $path"
}

assert_no_file() {
  local path="$1"
  [[ ! -e "$path" ]] || fail "unexpected file: $path"
}

assert_contains() {
  local path="$1"
  local needle="$2"
  grep -Fq -- "$needle" "$path" || fail "$path does not contain: $needle"
}

assert_not_contains() {
  local path="$1"
  local needle="$2"
  if grep -Fq -- "$needle" "$path"; then
    fail "$path unexpectedly contains: $needle"
  fi
}

assert_permission_guidance() {
  local path="$1"
  assert_contains "$path" "permission-aware command style"
  assert_contains "$path" 'git -C'
  assert_contains "$path" "command substitution"
  assert_contains "$path" "shell loops"
  assert_contains "$path" "npx"
  assert_contains "$path" "install/update"
  assert_contains "$path" "Do not create"
  assert_contains "$path" "shell writes"
  assert_contains "$path" "heredocs"
  assert_contains "$path" 'sed -i'
  assert_contains "$path" '>/dev/null'
}

assert_no_file "$COMPASS_DIR/agents/compass-merge-agent.md"

assert_contains "$COMPASS_DIR/agents/compass-orchestrator.md" "use"
assert_contains "$COMPASS_DIR/agents/compass-orchestrator.md" "model: claude-sonnet-5[1m]"
assert_contains "$COMPASS_DIR/agents/compass-orchestrator.md" "effort: max"
assert_not_contains "$COMPASS_DIR/agents/compass-orchestrator.md" "compass-merge-agent"
assert_contains "$COMPASS_DIR/agents/compass-orchestrator.md" "Compass does not create implementation worktrees"
assert_contains "$COMPASS_DIR/agents/compass-orchestrator.md" "Claude sandbox sessions cannot reliably perform remote publishing"
assert_contains "$COMPASS_DIR/agents/compass-orchestrator.md" "\`git push\`"
assert_contains "$COMPASS_DIR/agents/compass-orchestrator.md" "outside the sandbox"
assert_contains "$COMPASS_DIR/agents/compass-orchestrator.md" "## Permission-Aware Tool Use"
assert_contains "$COMPASS_DIR/agents/compass-orchestrator.md" "Include permission constraints in Context Packets"
assert_contains "$COMPASS_DIR/agents/compass-orchestrator.md" "Before every subagent handoff, run a fan-out check"
assert_contains "$COMPASS_DIR/agents/compass-orchestrator.md" 'Use multiple `compass-planner` launches'
assert_contains "$COMPASS_DIR/agents/compass-orchestrator.md" 'Use `compass-complex-planner` only when the user explicitly asks'
assert_contains "$COMPASS_DIR/agents/compass-orchestrator.md" "Do not route to"
assert_contains "$COMPASS_DIR/agents/compass-orchestrator.md" "implementation-ready"
assert_contains "$COMPASS_DIR/agents/compass-orchestrator.md" "ordered edit steps"
assert_contains "$COMPASS_DIR/agents/compass-orchestrator.md" "## Implementation Launch Gate"
assert_contains "$COMPASS_DIR/agents/compass-orchestrator.md" "Groups 1-N"
assert_contains "$COMPASS_DIR/agents/compass-orchestrator.md" "If the plan has five or more"
assert_contains "$COMPASS_DIR/agents/compass-orchestrator.md" 'five `compass-implementer` agents'
assert_file "$COMPASS_DIR/agents/compass-advanced-orchestrator.md"
assert_contains "$COMPASS_DIR/agents/compass-advanced-orchestrator.md" "name: compass-advanced-orchestrator"
assert_contains "$COMPASS_DIR/agents/compass-advanced-orchestrator.md" "model: opus"
assert_contains "$COMPASS_DIR/agents/compass-advanced-orchestrator.md" "effort: medium"
assert_contains "$COMPASS_DIR/agents/compass-advanced-orchestrator.md" "compass:routed-planning"
assert_not_contains "$COMPASS_DIR/agents/compass-advanced-orchestrator.md" "compass-merge-agent"
assert_contains "$COMPASS_DIR/agents/compass-advanced-orchestrator.md" "## Fan-Out Bias"
assert_contains "$COMPASS_DIR/agents/compass-advanced-orchestrator.md" "## Implementation Fan-Out"
assert_contains "$COMPASS_DIR/agents/compass-advanced-orchestrator.md" 'Do not pass an entire approved plan to one `compass-implementer`'
assert_contains "$COMPASS_DIR/agents/compass-advanced-orchestrator.md" 'Use `compass-complex-planner` only when the user explicitly asks'
assert_contains "$COMPASS_DIR/agents/compass-advanced-orchestrator.md" "explicit user-directed route"
assert_contains "$COMPASS_DIR/agents/compass-advanced-orchestrator.md" "one focused Context"
assert_contains "$COMPASS_DIR/agents/compass-advanced-orchestrator.md" "Only launch \`compass-implementer\` with implementation-ready packets"
assert_contains "$COMPASS_DIR/agents/compass-advanced-orchestrator.md" "Implementation Launch Gate"
assert_contains "$COMPASS_DIR/agents/compass-advanced-orchestrator.md" "Claude sandbox sessions cannot reliably perform remote publishing"
assert_file "$COMPASS_DIR/scripts/compass"
assert_contains "$COMPASS_DIR/scripts/compass" 'if [[ "${1:-}" == "advanced" ]]'
assert_contains "$COMPASS_DIR/scripts/compass" 'AGENT="compass-advanced-orchestrator"'
assert_contains "$COMPASS_DIR/scripts/compass" '--print-launch'
assert_contains "$COMPASS_DIR/scripts/compass" 'COMPASS_PLUGIN_ROOT=%q claude'
assert_contains "$COMPASS_DIR/scripts/compass" '--settings "$STATUS_SETTINGS"'
assert_contains "$COMPASS_DIR/scripts/compass" '--agent "compass:$AGENT"'
assert_contains "$COMPASS_DIR/scripts/compass" "Claude Code CLI not found on PATH"
assert_file "$COMPASS_DIR/scripts/compass.ps1"
assert_contains "$COMPASS_DIR/scripts/compass.ps1" "compass-advanced-orchestrator"
assert_contains "$COMPASS_DIR/scripts/compass.ps1" "--print-launch"
assert_contains "$COMPASS_DIR/scripts/compass.ps1" "ConvertTo-Json"
assert_contains "$COMPASS_DIR/scripts/compass.ps1" "Claude Code CLI not found on PATH"
tmp_compass_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_compass_dir"' EXIT
mkdir -p "$tmp_compass_dir/bin"
ln -s "$COMPASS_DIR/scripts/compass" "$tmp_compass_dir/bin/compass"
symlink_launch="$("$tmp_compass_dir/bin/compass" --print-launch)"
[[ "$symlink_launch" == *"COMPASS_PLUGIN_ROOT=$COMPASS_DIR"* ]] || fail "symlinked launcher did not resolve Compass root"
[[ "$symlink_launch" == *"--plugin-dir $COMPASS_DIR"* ]] || fail "symlinked launcher did not use Compass plugin dir"
assert_file "$COMPASS_DIR/bin/compass-statusline"
[[ -x "$COMPASS_DIR/bin/compass-statusline" ]] || fail "not executable: $COMPASS_DIR/bin/compass-statusline"
assert_file "$COMPASS_DIR/bin/compass-subagent-statusline"
[[ -x "$COMPASS_DIR/bin/compass-subagent-statusline" ]] || fail "not executable: $COMPASS_DIR/bin/compass-subagent-statusline"
assert_contains "$COMPASS_DIR/settings.json" '"subagentStatusLine"'
assert_contains "$COMPASS_DIR/settings.json" '${CLAUDE_PLUGIN_ROOT}/bin/compass-subagent-statusline'
if command -v node >/dev/null 2>&1; then
  main_statusline_output="$(printf '%s' '{"agent":{"name":"compass-orchestrator"},"model":{"display_name":"Sonnet 5"},"workspace":{"current_dir":"/tmp/project"},"context_window":{"used_percentage":42},"cost":{"total_cost_usd":0.125}}' | "$COMPASS_DIR/bin/compass-statusline")"
  [[ "$main_statusline_output" == *'Compass orchestrator'* ]] || fail "main status line output missing Compass agent"
  [[ "$main_statusline_output" == *'ctx 42%'* ]] || fail "main status line output missing context"

  statusline_output="$(printf '%s' '{"columns":90,"tasks":[{"id":"task-1","name":"compass-context-scout","status":"running","description":"Map existing eval and review infrastructure","tokenCount":20300,"cwd":"/tmp/project"}]}' | "$COMPASS_DIR/bin/compass-subagent-statusline")"
  [[ "$statusline_output" == *'"id":"task-1"'* ]] || fail "subagent status line output missing task id"
  [[ "$statusline_output" == *'Compass scout running'* ]] || fail "subagent status line output missing formatted row"
else
  printf 'Skipping status-line runtime checks: node not found on PATH.\n' >&2
fi
assert_contains "$COMPASS_DIR/commands/compass.md" "This slash command cannot change"
assert_contains "$COMPASS_DIR/commands/compass.md" "compass advanced"

assert_permission_guidance "$COMPASS_DIR/agents/compass-doer.md"
assert_permission_guidance "$COMPASS_DIR/agents/compass-context-scout.md"
assert_permission_guidance "$COMPASS_DIR/agents/compass-planner.md"
assert_permission_guidance "$COMPASS_DIR/agents/compass-implementer.md"
assert_permission_guidance "$COMPASS_DIR/agents/compass-plan-auditor.md"
assert_permission_guidance "$COMPASS_DIR/agents/compass-code-reviewer.md"
assert_no_file "$COMPASS_DIR/agents/compass-test-runner.md"
assert_no_file "$COMPASS_DIR/agents/compass-log-digester.md"

assert_contains "$COMPASS_DIR/agents/compass-doer.md" "model: claude-sonnet-4-6[1m]"
assert_contains "$COMPASS_DIR/agents/compass-doer.md" "\`git push\`"
assert_contains "$COMPASS_DIR/agents/compass-doer.md" "Do not attempt remote writes"
assert_contains "$COMPASS_DIR/agents/compass-context-scout.md" "maxTurns: 10"
assert_contains "$COMPASS_DIR/agents/compass-context-scout.md" "## Evidence Budget"
assert_contains "$COMPASS_DIR/agents/compass-context-scout.md" "The orchestrator owns follow-up evidence"
assert_contains "$COMPASS_DIR/agents/compass-context-scout.md" "Treat budget pressure as a return condition"
assert_contains "$COMPASS_DIR/agents/compass-context-scout.md" "Never return mid-investigation without a verdict"
assert_contains "$COMPASS_DIR/agents/compass-context-scout.md" "## Claim Verification Mode"
assert_contains "$COMPASS_DIR/agents/compass-context-scout.md" "Verdict: valid | invalid | partially-valid | inconclusive"
assert_not_contains "$COMPASS_DIR/agents/compass-implementer.md" "ready for merge-agent"
assert_contains "$COMPASS_DIR/agents/compass-implementer.md" "Review readiness: ready for code-reviewer"
assert_contains "$COMPASS_DIR/agents/compass-implementer.md" "model: claude-sonnet-4-6[1m]"
assert_contains "$COMPASS_DIR/agents/compass-implementer.md" "assigns multiple independent execution groups"
assert_contains "$COMPASS_DIR/agents/compass-implementer.md" "Your assignment should already be decomposed"
assert_contains "$COMPASS_DIR/agents/compass-implementer.md" "lacks ordered edit steps"
assert_contains "$COMPASS_DIR/agents/compass-implementer.md" "Implementation Launch Gate result: pass"

assert_not_contains "$COMPASS_DIR/agents/compass-orchestrator.md" "compass-discussion"
assert_not_contains "$COMPASS_DIR/commands/compass.md" "compass-discussion"

assert_file "$COMPASS_DIR/agents/compass-code-reviewer.md"
assert_contains "$COMPASS_DIR/agents/compass-code-reviewer.md" "name: compass-code-reviewer"
assert_contains "$COMPASS_DIR/agents/compass-code-reviewer.md" "model: opus"
assert_contains "$COMPASS_DIR/agents/compass-code-reviewer.md" "disallowedTools: Edit, Write"
assert_contains "$COMPASS_DIR/agents/compass-code-reviewer.md" "JSDoc"
assert_contains "$COMPASS_DIR/agents/compass-code-reviewer.md" "Proper DD logging"
assert_contains "$COMPASS_DIR/agents/compass-code-reviewer.md" "Mermaid diagrams"
assert_contains "$COMPASS_DIR/agents/compass-code-reviewer.md" "Files over 400 lines"
assert_contains "$COMPASS_DIR/agents/compass-code-reviewer.md" "Magic strings"
assert_contains "$COMPASS_DIR/agents/compass-code-reviewer.md" "dependency injection"
assert_contains "$COMPASS_DIR/agents/compass-code-reviewer.md" "Findings first"
assert_contains "$COMPASS_DIR/agents/compass-code-reviewer.md" "Code Review Evidence Request"
assert_contains "$COMPASS_DIR/agents/compass-code-reviewer.md" "user-facing report agent"
assert_contains "$COMPASS_DIR/agents/compass-code-reviewer.md" "Compass Routing Footer"
assert_file "$COMPASS_DIR/agents/compass-complex-planner.md"
assert_permission_guidance "$COMPASS_DIR/agents/compass-complex-planner.md"
assert_contains "$COMPASS_DIR/agents/compass-complex-planner.md" "name: compass-complex-planner"
assert_contains "$COMPASS_DIR/agents/compass-complex-planner.md" "model: fable"
assert_contains "$COMPASS_DIR/agents/compass-complex-planner.md" "effort: max"
assert_contains "$COMPASS_DIR/agents/compass-complex-planner.md" "Complex Planner Handoff Rejected"
assert_contains "$COMPASS_DIR/agents/compass-complex-planner.md" "explicitly requested"
assert_contains "$COMPASS_DIR/agents/compass-complex-planner.md" "Architecture And Sequencing Notes"
assert_contains "$COMPASS_DIR/agents/compass-complex-planner.md" "Compass Routing Footer"
assert_contains "$COMPASS_DIR/agents/compass-planner.md" "user-facing report agent"
assert_contains "$COMPASS_DIR/agents/compass-planner.md" "Compass Routing Footer"
assert_contains "$COMPASS_DIR/agents/compass-planner.md" "Bias toward more, smaller execution groups"
assert_contains "$COMPASS_DIR/agents/compass-planner.md" "Each execution group must be implementation-ready"
assert_contains "$COMPASS_DIR/agents/compass-planner.md" "no open design choices"
assert_contains "$COMPASS_DIR/agents/compass-plan-auditor.md" "user-facing report agent"
assert_contains "$COMPASS_DIR/agents/compass-plan-auditor.md" "effort: max"
assert_contains "$COMPASS_DIR/agents/compass-plan-auditor.md" "Compass Routing Footer"
assert_contains "$COMPASS_DIR/agents/compass-orchestrator.md" "## User-Facing Report Agents"
assert_contains "$COMPASS_DIR/agents/compass-orchestrator.md" "relay it with minimal framing"
assert_contains "$COMPASS_DIR/agents/compass-orchestrator.md" "Do not duplicate the report"
assert_contains "$COMPASS_DIR/commands/compass.md" "user-facing report agents"
assert_contains "$COMPASS_DIR/commands/compass.md" "Do not rewrite or duplicate"
assert_contains "$COMPASS_DIR/agents/compass-orchestrator.md" "Use \`compass-code-reviewer\`"
assert_contains "$COMPASS_DIR/commands/compass.md" "Use \`compass-code-reviewer\`"

assert_not_contains "$COMPASS_DIR/skills/context-packets/SKILL.md" '### `compass-merge-agent`'
assert_not_contains "$COMPASS_DIR/skills/context-packets/SKILL.md" '### `compass-discussion`'
assert_not_contains "$COMPASS_DIR/skills/context-packets/SKILL.md" "Discussion Evidence Request"
assert_contains "$COMPASS_DIR/skills/context-packets/SKILL.md" "## Permission Constraints"
assert_contains "$COMPASS_DIR/skills/context-packets/SKILL.md" "Permission constraints:"
assert_contains "$COMPASS_DIR/skills/context-packets/SKILL.md" "Do not create or modify repository files with shell writes"
assert_contains "$COMPASS_DIR/skills/context-packets/SKILL.md" 'one `compass-planner` packet per'
assert_contains "$COMPASS_DIR/skills/context-packets/SKILL.md" 'Build a `compass-complex-planner` packet only when'
assert_contains "$COMPASS_DIR/skills/context-packets/SKILL.md" '### `compass-complex-planner`'
assert_contains "$COMPASS_DIR/skills/context-packets/SKILL.md" "Explicit user direction authorizing complex planner"
assert_contains "$COMPASS_DIR/skills/context-packets/SKILL.md" 'one `compass-implementer` packet per'
assert_contains "$COMPASS_DIR/skills/context-packets/SKILL.md" 'one `compass-doer` packet per'
assert_contains "$COMPASS_DIR/skills/context-packets/SKILL.md" "for this execution group only"
assert_contains "$COMPASS_DIR/skills/context-packets/SKILL.md" "Expected behavior change"
assert_contains "$COMPASS_DIR/skills/context-packets/SKILL.md" "ordered edit steps"
assert_contains "$COMPASS_DIR/skills/context-packets/SKILL.md" "Implementation Launch Gate result"
assert_contains "$COMPASS_DIR/skills/context-packets/SKILL.md" "direct target branch/current working tree only"
assert_contains "$COMPASS_DIR/skills/context-packets/SKILL.md" "Do not run remote publishing"
assert_contains "$COMPASS_DIR/skills/context-packets/SKILL.md" "\`gh pr create\`"
assert_contains "$COMPASS_DIR/skills/context-packets/SKILL.md" "Verdict required"
assert_contains "$COMPASS_DIR/skills/context-packets/SKILL.md" "For claim verification"
assert_contains "$COMPASS_DIR/agents/compass-orchestrator.md" "When launching scouts for claim verification"
assert_contains "$COMPASS_DIR/agents/compass-orchestrator.md" "return \`inconclusive\` with evidence gaps"
assert_contains "$COMPASS_DIR/agents/compass-orchestrator.md" "Scouts are bounded by design"
assert_contains "$COMPASS_DIR/commands/compass.md" "If a bounded scout returns partial evidence"
assert_contains "$COMPASS_DIR/skills/context-packets/SKILL.md" "Budget guard"
assert_contains "$COMPASS_DIR/skills/context-packets/SKILL.md" '### `compass-code-reviewer`'
assert_contains "$COMPASS_DIR/skills/context-packets/SKILL.md" "Code Review Evidence Request"
assert_contains "$COMPASS_DIR/skills/context-packets/SKILL.md" "## User-Facing Report Agents"
assert_contains "$COMPASS_DIR/skills/context-packets/SKILL.md" "complete user-facing"
assert_contains "$COMPASS_DIR/skills/context-packets/SKILL.md" "Compass Routing Footer"
assert_contains "$COMPASS_DIR/commands/compass.md" "Keep tool use permission-aware"
assert_contains "$COMPASS_DIR/commands/compass.md" "Do not create or modify repository files through shell writes"
assert_contains "$COMPASS_DIR/commands/compass.md" "Compass does not create implementation worktrees"
assert_contains "$COMPASS_DIR/commands/compass.md" "Gate result must be \`pass\`"
assert_contains "$COMPASS_DIR/commands/compass.md" "Claude sandbox sessions cannot reliably perform remote publishing"
assert_not_contains "$COMPASS_DIR/commands/compass.md" "compass-merge-agent"

assert_contains "$COMPASS_DIR/skills/routed-planning/SKILL.md" "use"
assert_not_contains "$COMPASS_DIR/skills/routed-planning/SKILL.md" "compass-merge-agent"
assert_contains "$COMPASS_DIR/skills/routed-planning/SKILL.md" "Compass does not create implementation worktrees"
assert_contains "$COMPASS_DIR/skills/routed-planning/SKILL.md" "Do not assign remote writes to doers"
assert_contains "$COMPASS_DIR/skills/routed-planning/SKILL.md" "from the Claude sandbox"
assert_contains "$COMPASS_DIR/agents/compass-orchestrator.md" "split \`compass-doer\` launches by independent write"
assert_contains "$COMPASS_DIR/agents/compass-orchestrator.md" "creation, inspections, summaries"
assert_contains "$COMPASS_DIR/agents/compass-orchestrator.md" "one doer packet"
assert_contains "$COMPASS_DIR/commands/compass.md" "one doer per"
assert_contains "$COMPASS_DIR/commands/compass.md" "local note generation"
assert_contains "$COMPASS_DIR/commands/compass.md" "PR description text"
assert_contains "$COMPASS_DIR/commands/compass.md" "Do not pass the full approved"
assert_contains "$COMPASS_DIR/commands/compass.md" "Before any specialist handoff, run a fan-out check"
assert_contains "$COMPASS_DIR/commands/compass.md" 'Use `compass-complex-planner` only when the user explicitly asks'
assert_contains "$COMPASS_DIR/commands/compass.md" 'build a `compass-complex-planner` Context Packet'
assert_contains "$COMPASS_DIR/commands/compass.md" "Before launching \`compass-implementer\`, verify the packet is"
assert_contains "$COMPASS_DIR/skills/routed-planning/SKILL.md" "one doer per independent"
assert_contains "$COMPASS_DIR/skills/routed-planning/SKILL.md" "editing a PR body"
assert_contains "$COMPASS_DIR/skills/routed-planning/SKILL.md" "one planner per independent"
assert_contains "$COMPASS_DIR/skills/routed-planning/SKILL.md" '`compass-complex-planner` is not a risk-triggered escalation path'
assert_contains "$COMPASS_DIR/skills/routed-planning/SKILL.md" "Before any handoff, run a fan-out check"
assert_contains "$COMPASS_DIR/skills/routed-planning/SKILL.md" "Implementation handoffs must be code-ready"
assert_contains "$COMPASS_DIR/skills/routed-planning/SKILL.md" "Run the Implementation Launch Gate"
assert_contains "$COMPASS_DIR/skills/visibility-protocol/SKILL.md" "## Implementation Review Checkpoint"
assert_contains "$COMPASS_DIR/skills/visibility-protocol/SKILL.md" "planners covering"
assert_not_contains "$COMPASS_DIR/skills/visibility-protocol/SKILL.md" "compass-merge-agent"
assert_not_contains "$COMPASS_DIR/skills/visibility-protocol/SKILL.md" "Compass phase: discussion"
assert_file "$COMPASS_DIR/skills/change-walkthrough/SKILL.md"
assert_contains "$COMPASS_DIR/skills/change-walkthrough/SKILL.md" "local-notes/<slug>.html"
assert_contains "$COMPASS_DIR/skills/change-walkthrough/SKILL.md" "Do not update the PR body"
assert_contains "$COMPASS_DIR/skills/change-walkthrough/SKILL.md" "outside the sandbox"
assert_contains "$COMPASS_DIR/skills/change-walkthrough/SKILL.md" "Reviewer path"
assert_contains "$COMPASS_DIR/skills/change-walkthrough/SKILL.md" "diff reality check"
assert_contains "$COMPASS_DIR/skills/change-walkthrough/SKILL.md" "Mermaid-style diagrams"
assert_contains "$COMPASS_DIR/skills/change-walkthrough/SKILL.md" "Do not require \`npx\`"
assert_contains "$COMPASS_DIR/agents/compass-orchestrator.md" "change walkthrough HTML artifact"
assert_contains "$COMPASS_DIR/agents/compass-orchestrator.md" "prepare local artifacts or draft"
assert_contains "$COMPASS_DIR/agents/compass-doer.md" "\`change-walkthrough\` skill"
assert_contains "$COMPASS_DIR/commands/compass.md" "Use the \`change-walkthrough\` skill"
assert_contains "$ROOT_DIR/README.md" "\`change-walkthrough\`"
assert_contains "$COMPASS_DIR/README.md" "\`change-walkthrough\` skill"

assert_no_file "$COMPASS_DIR/scripts/update-compass-map.sh"
assert_no_file "$ROOT_DIR/claude-orchestration-workflow/Claude Code Routed Agent System Plan.md"
assert_no_file "$ROOT_DIR/.compass/dashboard.html"
assert_no_file "$ROOT_DIR/.compass/compass-map.md"
assert_no_file "$ROOT_DIR/.claude/skills/_probe.md"
assert_no_file "$COMPASS_DIR/.compass/compass-map.md"
assert_not_contains "$ROOT_DIR/README.md" "update-compass-map"
assert_not_contains "$COMPASS_DIR/README.md" "update-compass-map"
assert_not_contains "$COMPASS_DIR/commands/compass.md" "update-compass-map"
assert_not_contains "$COMPASS_DIR/skills/visibility-protocol/SKILL.md" "update-compass-map"
assert_not_contains "$ROOT_DIR/README.md" ".compass/dashboard.html"
assert_not_contains "$COMPASS_DIR/README.md" ".compass/dashboard.html"
assert_not_contains "$COMPASS_DIR/commands/compass.md" ".compass/dashboard.html"
assert_not_contains "$COMPASS_DIR/skills/visibility-protocol/SKILL.md" ".compass/dashboard.html"
assert_not_contains "$COMPASS_DIR/agents/compass-orchestrator.md" "Compass Map"
assert_contains "$COMPASS_DIR/bin/compass-subagent-statusline" "'compass-complex-planner': 'complex-planner'"

assert_contains "$COMPASS_DIR/.claude-plugin/plugin.json" "code review"
assert_contains "$COMPASS_DIR/.claude-plugin/plugin.json" "complex planner"
assert_contains "$COMPASS_DIR/.claude-plugin/plugin.json" "Compass Contributors"
assert_contains "$COMPASS_DIR/.claude-plugin/marketplace.json" "code review"
assert_contains "$COMPASS_DIR/.claude-plugin/marketplace.json" "complex planner"
assert_contains "$COMPASS_DIR/.claude-plugin/marketplace.json" "Compass Contributors"
assert_contains "$ROOT_DIR/README.md" "\`compass-orchestrator\`: Sonnet 5 1M max."
assert_contains "$ROOT_DIR/README.md" "\`compass-advanced-orchestrator\`: Opus medium."
assert_not_contains "$ROOT_DIR/README.md" "\`compass-merge-agent\`: Opus."
assert_not_contains "$ROOT_DIR/README.md" "\`compass-discussion\`: Opus."
assert_contains "$ROOT_DIR/README.md" "\`compass-complex-planner\`: Fable max, only when explicitly requested."
assert_contains "$ROOT_DIR/README.md" "\`compass-plan-auditor\`: Opus max."
assert_contains "$ROOT_DIR/README.md" "\`compass-code-reviewer\`: Opus."
assert_contains "$ROOT_DIR/README.md" "\`compass-doer\`: Sonnet 4.6 1M."
assert_contains "$ROOT_DIR/README.md" "\`compass-implementer\`: Sonnet 4.6 1M."
assert_not_contains "$ROOT_DIR/README.md" "\`compass-log-digester\`"
assert_not_contains "$ROOT_DIR/README.md" "\`compass-test-runner\`"
assert_not_contains "$COMPASS_DIR/README.md" "\`compass-merge-agent\`"
assert_contains "$COMPASS_DIR/README.md" "\`compass-complex-planner\`: Fable max read-only planning"
assert_contains "$COMPASS_DIR/README.md" "Sonnet 5 1M max main session agent"
assert_contains "$COMPASS_DIR/README.md" "Opus medium advanced main session agent"
assert_contains "$COMPASS_DIR/README.md" "one planner per independent planning lane"
assert_contains "$COMPASS_DIR/README.md" "does not attempt remote publishing"
assert_not_contains "$COMPASS_DIR/README.md" "\`compass-discussion\`"
assert_contains "$COMPASS_DIR/README.md" "\`compass-code-reviewer\`"
assert_contains "$COMPASS_DIR/README.md" "Sonnet 4.6 1M general execution"
assert_contains "$COMPASS_DIR/README.md" "Sonnet 4.6 1M scoped implementation"
assert_not_contains "$COMPASS_DIR/README.md" "\`compass-log-digester\`"
assert_not_contains "$COMPASS_DIR/README.md" "\`compass-test-runner\`"
assert_no_file "$COMPASS_DIR/skills/visual-plan/SKILL.md"
assert_no_file "$COMPASS_DIR/skills/visual-recap/SKILL.md"
assert_no_file "$COMPASS_DIR/skills/visual-plan/README.md"
assert_no_file "$COMPASS_DIR/skills/visual-recap/README.md"
assert_not_contains "$ROOT_DIR/README.md" "visual-plan"
assert_not_contains "$ROOT_DIR/README.md" "visual-recap"
assert_not_contains "$COMPASS_DIR/README.md" "visual-plan"
assert_not_contains "$COMPASS_DIR/README.md" "visual-recap"
assert_not_contains "$COMPASS_DIR/agents/compass-doer.md" "compass:visual-plan"
assert_not_contains "$COMPASS_DIR/agents/compass-doer.md" "compass:visual-recap"
assert_not_contains "$COMPASS_DIR/agents/compass-orchestrator.md" "compass:visual-plan"
assert_not_contains "$COMPASS_DIR/agents/compass-orchestrator.md" "compass:visual-recap"
assert_not_contains "$COMPASS_DIR/commands/compass.md" "compass:visual-plan"
assert_not_contains "$COMPASS_DIR/commands/compass.md" "compass:visual-recap"
assert_file "$ROOT_DIR/.gitignore"
assert_contains "$ROOT_DIR/.gitignore" "/.compass/"
assert_contains "$ROOT_DIR/.gitignore" "/.claude/"
assert_contains "$ROOT_DIR/.gitignore" "/compass/.compass/"

assert_not_contains "$ROOT_DIR/README.md" "/Users/"
assert_not_contains "$COMPASS_DIR/README.md" "/Users/"
assert_not_contains "$COMPASS_DIR/commands/compass.md" "/Users/"
assert_not_contains "$COMPASS_DIR/skills/visibility-protocol/SKILL.md" "/Users/"

if command -v claude >/dev/null 2>&1; then
  claude plugin validate "$COMPASS_DIR" >/dev/null
fi

printf 'Compass contract checks passed.\n'
