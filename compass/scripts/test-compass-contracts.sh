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
assert_contains "$COMPASS_DIR/agents/compass-orchestrator.md" "compass-merge-agent"
assert_contains "$COMPASS_DIR/agents/compass-orchestrator.md" "The orchestrator must not manually copy, merge, cherry-pick, or recreate"
assert_contains "$COMPASS_DIR/agents/compass-orchestrator.md" "completed Compass worktree should be left behind silently."

assert_contains "$COMPASS_DIR/agents/compass-implementer.md" "Worktree path, if running in an isolated worktree."
assert_contains "$COMPASS_DIR/agents/compass-implementer.md" "Integration readiness: ready for merge-agent"

assert_contains "$COMPASS_DIR/skills/context-packets/SKILL.md" '### `compass-merge-agent`'
assert_contains "$COMPASS_DIR/skills/context-packets/SKILL.md" "Target branch or working tree:"
assert_contains "$COMPASS_DIR/skills/context-packets/SKILL.md" "Integration conflict triggers:"
assert_contains "$COMPASS_DIR/skills/context-packets/SKILL.md" "clean up after successful integration unless preservation is"

assert_contains "$COMPASS_DIR/skills/routed-planning/SKILL.md" "use"
assert_contains "$COMPASS_DIR/skills/routed-planning/SKILL.md" "compass-merge-agent"
assert_contains "$COMPASS_DIR/skills/routed-planning/SKILL.md" "Default to clean up after successful"
assert_contains "$COMPASS_DIR/skills/visibility-protocol/SKILL.md" "## Integration Handoff"
assert_contains "$COMPASS_DIR/commands/compass.md" "Use \`compass-merge-agent\` for worktree merge or integration work."
assert_contains "$COMPASS_DIR/commands/compass.md" "Do not leave Compass-created worktrees behind silently."

assert_contains "$COMPASS_DIR/scripts/update-compass-map.sh" "implementation|integration"
assert_contains "$COMPASS_DIR/scripts/update-compass-map.sh" "compass-merge-agent|merge-agent|integrates worktrees"

assert_contains "$COMPASS_DIR/.claude-plugin/plugin.json" "implementer, merge, context"
assert_contains "$COMPASS_DIR/.claude-plugin/marketplace.json" "implementer, merge, context"
assert_contains "$ROOT_DIR/README.md" "\`compass-merge-agent\`: Opus."
assert_contains "$COMPASS_DIR/README.md" "\`compass-merge-agent\`"

if command -v claude >/dev/null 2>&1; then
  claude plugin validate "$COMPASS_DIR" >/dev/null
fi

printf 'Compass contract checks passed.\n'
