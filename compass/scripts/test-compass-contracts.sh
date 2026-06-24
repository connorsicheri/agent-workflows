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

assert_file "$COMPASS_DIR/agents/compass-merge-agent.md"
assert_contains "$COMPASS_DIR/agents/compass-merge-agent.md" "name: compass-merge-agent"
assert_contains "$COMPASS_DIR/agents/compass-merge-agent.md" "model: opus"
assert_contains "$COMPASS_DIR/agents/compass-merge-agent.md" "tools: Read, Edit, Write, Bash, Glob, Grep"
assert_contains "$COMPASS_DIR/agents/compass-merge-agent.md" "Integration Conflict Report"
assert_contains "$COMPASS_DIR/agents/compass-merge-agent.md" "Completion Report"
assert_contains "$COMPASS_DIR/agents/compass-merge-agent.md" "Clean up Compass-created worktrees by default after successful integration"
assert_contains "$COMPASS_DIR/agents/compass-merge-agent.md" "git worktree remove"
assert_contains "$COMPASS_DIR/agents/compass-merge-agent.md" "git worktree prune"
assert_contains "$COMPASS_DIR/agents/compass-merge-agent.md" "Worktree cleanup performed, or preservation reason."

assert_contains "$COMPASS_DIR/agents/compass-orchestrator.md" "use"
assert_contains "$COMPASS_DIR/agents/compass-orchestrator.md" "model: opus"
assert_contains "$COMPASS_DIR/agents/compass-orchestrator.md" "effort: medium"
assert_contains "$COMPASS_DIR/agents/compass-orchestrator.md" "compass-merge-agent"
assert_contains "$COMPASS_DIR/agents/compass-orchestrator.md" "The orchestrator must not manually copy, merge, cherry-pick, or recreate"
assert_contains "$COMPASS_DIR/agents/compass-orchestrator.md" "completed Compass worktree should be left behind silently."
assert_contains "$COMPASS_DIR/agents/compass-orchestrator.md" "## Permission-Aware Tool Use"
assert_contains "$COMPASS_DIR/agents/compass-orchestrator.md" "Include permission constraints in Context Packets"

assert_permission_guidance "$COMPASS_DIR/agents/compass-doer.md"
assert_permission_guidance "$COMPASS_DIR/agents/compass-context-scout.md"
assert_permission_guidance "$COMPASS_DIR/agents/compass-planner.md"
assert_permission_guidance "$COMPASS_DIR/agents/compass-test-runner.md"
assert_permission_guidance "$COMPASS_DIR/agents/compass-log-digester.md"
assert_permission_guidance "$COMPASS_DIR/agents/compass-implementer.md"
assert_permission_guidance "$COMPASS_DIR/agents/compass-merge-agent.md"
assert_permission_guidance "$COMPASS_DIR/agents/compass-plan-auditor.md"
assert_permission_guidance "$COMPASS_DIR/agents/compass-code-reviewer.md"

assert_contains "$COMPASS_DIR/agents/compass-doer.md" "model: sonnet[1m]"
assert_contains "$COMPASS_DIR/agents/compass-implementer.md" "Worktree path, if running in an isolated worktree."
assert_contains "$COMPASS_DIR/agents/compass-implementer.md" "Integration readiness: ready for merge-agent"
assert_contains "$COMPASS_DIR/agents/compass-implementer.md" "model: sonnet[1m]"

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
assert_contains "$COMPASS_DIR/agents/compass-orchestrator.md" "Use \`compass-code-reviewer\`"
assert_contains "$COMPASS_DIR/commands/compass.md" "Use \`compass-code-reviewer\`"

assert_contains "$COMPASS_DIR/skills/context-packets/SKILL.md" '### `compass-merge-agent`'
assert_contains "$COMPASS_DIR/skills/context-packets/SKILL.md" "Target branch or working tree:"
assert_contains "$COMPASS_DIR/skills/context-packets/SKILL.md" "Integration conflict triggers:"
assert_contains "$COMPASS_DIR/skills/context-packets/SKILL.md" "clean up after successful integration unless preservation is"
assert_not_contains "$COMPASS_DIR/skills/context-packets/SKILL.md" '### `compass-discussion`'
assert_not_contains "$COMPASS_DIR/skills/context-packets/SKILL.md" "Discussion Evidence Request"
assert_contains "$COMPASS_DIR/skills/context-packets/SKILL.md" "## Permission Constraints"
assert_contains "$COMPASS_DIR/skills/context-packets/SKILL.md" "Permission constraints:"
assert_contains "$COMPASS_DIR/skills/context-packets/SKILL.md" "Do not create or modify repository files with shell writes"
assert_contains "$COMPASS_DIR/skills/context-packets/SKILL.md" '### `compass-code-reviewer`'
assert_contains "$COMPASS_DIR/skills/context-packets/SKILL.md" "Code Review Evidence Request"
assert_contains "$COMPASS_DIR/commands/compass.md" "Keep tool use permission-aware"
assert_contains "$COMPASS_DIR/commands/compass.md" "Do not create or modify repository files through shell writes"

assert_contains "$COMPASS_DIR/skills/routed-planning/SKILL.md" "use"
assert_contains "$COMPASS_DIR/skills/routed-planning/SKILL.md" "compass-merge-agent"
assert_contains "$COMPASS_DIR/skills/routed-planning/SKILL.md" "Default to clean up after successful"
assert_contains "$COMPASS_DIR/agents/compass-orchestrator.md" "split \`compass-doer\` launches by independent write"
assert_contains "$COMPASS_DIR/agents/compass-orchestrator.md" "independent artifact creation and remote updates"
assert_contains "$COMPASS_DIR/commands/compass.md" "one doer per"
assert_contains "$COMPASS_DIR/commands/compass.md" "local note generation and PR description updates"
assert_contains "$COMPASS_DIR/skills/routed-planning/SKILL.md" "one doer per independent write"
assert_contains "$COMPASS_DIR/skills/routed-planning/SKILL.md" "PR description update"
assert_contains "$COMPASS_DIR/skills/visibility-protocol/SKILL.md" "## Integration Handoff"
assert_not_contains "$COMPASS_DIR/skills/visibility-protocol/SKILL.md" "Compass phase: discussion"
assert_contains "$COMPASS_DIR/commands/compass.md" "Use \`compass-merge-agent\` for worktree merge or integration work."
assert_contains "$COMPASS_DIR/commands/compass.md" "Do not leave Compass-created worktrees behind silently."
assert_file "$COMPASS_DIR/skills/change-walkthrough/SKILL.md"
assert_contains "$COMPASS_DIR/skills/change-walkthrough/SKILL.md" "local-notes/<slug>.html"
assert_contains "$COMPASS_DIR/skills/change-walkthrough/SKILL.md" "Do not update the PR body"
assert_contains "$COMPASS_DIR/skills/change-walkthrough/SKILL.md" "Reviewer path"
assert_contains "$COMPASS_DIR/skills/change-walkthrough/SKILL.md" "diff reality check"
assert_contains "$COMPASS_DIR/skills/change-walkthrough/SKILL.md" "Mermaid-style diagrams"
assert_contains "$COMPASS_DIR/skills/change-walkthrough/SKILL.md" "Do not require \`npx\`"
assert_contains "$COMPASS_DIR/agents/compass-orchestrator.md" "change walkthrough HTML artifact"
assert_contains "$COMPASS_DIR/agents/compass-orchestrator.md" "one doer creates the local HTML walkthrough"
assert_contains "$COMPASS_DIR/agents/compass-doer.md" "\`change-walkthrough\` skill"
assert_contains "$COMPASS_DIR/commands/compass.md" "Use the \`change-walkthrough\` skill"
assert_contains "$ROOT_DIR/README.md" "\`change-walkthrough\`"
assert_contains "$COMPASS_DIR/README.md" "\`change-walkthrough\` skill"

assert_contains "$COMPASS_DIR/scripts/update-compass-map.sh" "implementation|integration"
assert_contains "$COMPASS_DIR/scripts/update-compass-map.sh" "compass-merge-agent|merge-agent|integrates worktrees"
assert_not_contains "$COMPASS_DIR/scripts/update-compass-map.sh" "compass-discussion"
assert_contains "$COMPASS_DIR/scripts/update-compass-map.sh" "compass-code-reviewer|code-reviewer|reviews code"

assert_contains "$COMPASS_DIR/.claude-plugin/plugin.json" "code review"
assert_contains "$COMPASS_DIR/.claude-plugin/marketplace.json" "code review"
assert_contains "$ROOT_DIR/README.md" "\`compass-orchestrator\`: Opus medium."
assert_contains "$ROOT_DIR/README.md" "\`compass-merge-agent\`: Opus."
assert_not_contains "$ROOT_DIR/README.md" "\`compass-discussion\`: Opus."
assert_contains "$ROOT_DIR/README.md" "\`compass-code-reviewer\`: Opus."
assert_contains "$ROOT_DIR/README.md" "\`compass-doer\`: Sonnet 1M."
assert_contains "$ROOT_DIR/README.md" "\`compass-implementer\`: Sonnet 1M."
assert_contains "$COMPASS_DIR/README.md" "\`compass-merge-agent\`"
assert_contains "$COMPASS_DIR/README.md" "Opus medium main session agent"
assert_not_contains "$COMPASS_DIR/README.md" "\`compass-discussion\`"
assert_contains "$COMPASS_DIR/README.md" "\`compass-code-reviewer\`"
assert_contains "$COMPASS_DIR/README.md" "Sonnet 1M general execution"
assert_contains "$COMPASS_DIR/README.md" "Sonnet 1M scoped implementation"
assert_contains "$COMPASS_DIR/skills/visual-plan/SKILL.md" "status: deprecated"
assert_contains "$COMPASS_DIR/skills/visual-plan/SKILL.md" "visibility: internal"
assert_contains "$COMPASS_DIR/skills/visual-plan/SKILL.md" "currently deprecated in Compass"
assert_contains "$COMPASS_DIR/skills/visual-recap/SKILL.md" "status: deprecated"
assert_contains "$COMPASS_DIR/skills/visual-recap/SKILL.md" "visibility: internal"
assert_contains "$COMPASS_DIR/skills/visual-recap/SKILL.md" "currently deprecated in Compass"
assert_contains "$ROOT_DIR/README.md" "parked as deprecated"
assert_contains "$COMPASS_DIR/README.md" "does not currently route to \`visual-plan\` or \`visual-recap\`"
assert_not_contains "$COMPASS_DIR/agents/compass-doer.md" "compass:visual-plan"
assert_not_contains "$COMPASS_DIR/agents/compass-doer.md" "compass:visual-recap"
assert_not_contains "$COMPASS_DIR/agents/compass-orchestrator.md" "compass:visual-plan"
assert_not_contains "$COMPASS_DIR/agents/compass-orchestrator.md" "compass:visual-recap"
assert_not_contains "$COMPASS_DIR/commands/compass.md" "compass:visual-plan"
assert_not_contains "$COMPASS_DIR/commands/compass.md" "compass:visual-recap"
assert_not_contains "$COMPASS_DIR/skills/visual-plan/SKILL.md" "npx"
assert_not_contains "$COMPASS_DIR/skills/visual-recap/SKILL.md" "npx"
assert_not_contains "$COMPASS_DIR/skills/visual-plan/SKILL.md" "READ \`references/"
assert_not_contains "$COMPASS_DIR/skills/visual-recap/SKILL.md" "READ \`references/"
assert_not_contains "$COMPASS_DIR/skills/visual-plan/SKILL.md" "Before authoring the plan document, READ"
assert_not_contains "$COMPASS_DIR/skills/visual-recap/SKILL.md" "Before authoring ANY wireframe"

if command -v claude >/dev/null 2>&1; then
  claude plugin validate "$COMPASS_DIR" >/dev/null
fi

printf 'Compass contract checks passed.\n'
