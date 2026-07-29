#!/usr/bin/env bash
set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_contains() {
  local path="$1"
  local text="$2"
  local message="$3"
  grep -Fq -- "$text" "$path" || fail "$message"
}

assert_not_contains() {
  local path="$1"
  local text="$2"
  local message="$3"
  if grep -Fq -- "$text" "$path"; then
    fail "$message"
  fi
}

for path in \
  "$PLUGIN_DIR/.codex-plugin/plugin.json" \
  "$PLUGIN_DIR/skills/compass/SKILL.md" \
  "$PLUGIN_DIR/skills/context-packets/SKILL.md" \
  "$PLUGIN_DIR/skills/pr-feedback/SKILL.md" \
  "$PLUGIN_DIR/skills/verification-gate/SKILL.md" \
  "$PLUGIN_DIR/prompts/compass-compact.md" \
  "$PLUGIN_DIR/commands/compass.md"; do
  [[ -f "$path" ]] || fail "missing file: $path"
done

for agent in compass-context-scout compass-planner compass-plan-auditor compass-implementer compass-quick-reviewer compass-pr-reviewer compass-doer; do
  path="$PLUGIN_DIR/agents/$agent.toml"
  [[ -f "$path" ]] || fail "missing agent: $path"
  assert_contains "$path" "name = \"$agent\"" "wrong agent name: $path"
  assert_contains "$path" 'developer_instructions = """' "missing instructions: $path"
done

SKILL="$PLUGIN_DIR/skills/compass/SKILL.md"
COMMAND="$PLUGIN_DIR/commands/compass.md"
PACKETS="$PLUGIN_DIR/skills/context-packets/SKILL.md"
VERIFY="$PLUGIN_DIR/skills/verification-gate/SKILL.md"
PR_FEEDBACK="$PLUGIN_DIR/skills/pr-feedback/SKILL.md"

# Root-first routing scenarios.
assert_contains "$SKILL" 'Work directly in the root orchestrator for small, focused work.' 'root-first execution must be the default'
assert_contains "$SKILL" 'Do not delegate solely because a task changes code or touches several files' 'code changes must not automatically delegate'
assert_contains "$SKILL" 'For substantial multi-file or multi-stage work, actively identify at least one bounded lane to delegate' 'substantial work must seek a delegated lane'
assert_contains "$SKILL" 'Focused non-trivial bug fixes and features may still stay in root' 'single-lane non-trivial work must remain root-eligible'
assert_contains "$SKILL" 'At least one independent planning, evidence, implementation, or validation lane can run alongside useful root work.' 'one parallel specialist lane must justify delegation'
assert_contains "$SKILL" 'For substantial tasks, bias toward launching one specialist when a clean independent lane exists' 'substantial tasks must bias toward delegation'
assert_contains "$SKILL" 'The root should own one useful lane whenever possible while specialists run.' 'root must keep useful work on the critical path'
assert_contains "$SKILL" 'A couple of localized TypeScript type fixes: root only, no reviewer.' 'small type fixes must stay entirely in root'
assert_contains "$SKILL" 'A substantial feature spanning implementation and tests: delegate one bounded implementation or validation lane' 'substantial features must delegate useful work'
assert_contains "$SKILL" 'Three independent package failures: parallel evidence or implementation lanes' 'independent failures must fan out'
assert_contains "$SKILL" 'An authentication migration: use planners only for independent uncertainties, then strong review and formal verification.' 'high-risk work must retain proportionate rigor'
assert_contains "$COMMAND" 'start with the root-first path' 'Compass command must start root-first'
assert_contains "$COMMAND" 'actively look for at least one bounded specialist lane' 'Compass command must seek delegation on substantial work'
assert_not_contains "$SKILL" 'For code-changing work, follow this loop:' 'skill must not restore a mandatory code-change pipeline'
assert_not_contains "$SKILL" 'Implementation Launch Gate' 'skill must not require the removed launch gate'

# Planning optimizes useful concurrency without microtask fan-out.
assert_contains "$SKILL" 'Launch independent planners together' 'independent planning lanes must run concurrently'
assert_contains "$SKILL" 'smallest independently verifiable slice that is still large enough to justify an agent launch' 'execution groups must be bite-sized without becoming microtasks'
assert_contains "$SKILL" 'avoid creating more groups than available parallelism can use' 'planner must account for launch overhead'
assert_contains "$PLUGIN_DIR/agents/compass-planner.toml" 'Optimize for critical-path time and useful concurrency.' 'planner must optimize for wall time'
assert_contains "$PLUGIN_DIR/agents/compass-planner.toml" 'recommended owner (`root` or `implementer`)' 'planner must assign root-owned and delegated lanes'
assert_contains "$PLUGIN_DIR/agents/compass-planner.toml" 'review tier (`self-check`, `quick`, or `strong`)' 'planner must assign review tiers'
assert_not_contains "$PLUGIN_DIR/agents/compass-planner.toml" 'polished user-facing report with' 'planner must not spend time on the old exhaustive report'

# Review is tiered and objectively triggered.
assert_contains "$SKILL" 'Every implementer self-checks its diff' 'self-check must be the default review tier'
assert_contains "$SKILL" 'A quick review is not a mandatory gate' 'quick review must remain optional'
assert_contains "$SKILL" 'branching logic, state transitions, concurrency, error recovery, or non-trivial data transformation' 'quick review must have objective logic triggers'
assert_contains "$SKILL" 'Do not use it for routine type fixes, formatting, documentation, straightforward configuration' 'quick review must skip small routine work'
assert_contains "$SKILL" 'is not followed by a reviewer re-review' 'quick review fixes must not trigger another review round'
assert_contains "$SKILL" 'Use `compass-pr-reviewer` as the strong end-of-task reviewer only when' 'strong review must have a strict trigger'
assert_contains "$SKILL" 'File count alone is not a review trigger.' 'large file counts must not automatically review'
assert_contains "$SKILL" 'Do not run both quick and strong review by default.' 'review tiers must not stack automatically'
assert_contains "$PLUGIN_DIR/agents/compass-quick-reviewer.toml" 'Return `pass` or at most three concrete findings.' 'quick reviewer output must stay bounded'
assert_contains "$PLUGIN_DIR/agents/compass-quick-reviewer.toml" 'Do not broaden into architecture, style, naming, documentation, or speculative cleanup' 'quick reviewer must remain narrow'
assert_contains "$PLUGIN_DIR/agents/compass-pr-reviewer.toml" 'independent implementation lanes change one integrated behavior without reliable integration coverage' 'strong reviewer must use objective integration risk'
assert_contains "$PLUGIN_DIR/agents/compass-pr-reviewer.toml" 'complete final integrated change' 'PR reviewer must review globally after integration'
assert_contains "$PLUGIN_DIR/agents/compass-pr-reviewer.toml" 'derive the invariant' 'PR reviewer must derive high-risk behavior invariants'
assert_contains "$PLUGIN_DIR/agents/compass-pr-reviewer.toml" 'manual recovery' 'PR reviewer must scan alternate terminal-state paths'
assert_contains "$PLUGIN_DIR/agents/compass-pr-reviewer.toml" 'fix-introduced' 'PR reviewer must classify follow-up findings'
assert_contains "$PACKETS" 'For `compass-pr-reviewer`, add the complete final diff' 'PR reviewer packet must contain the global final diff'
assert_contains "$PLUGIN_DIR/agents/compass-planner.toml" 'Assign `self-check` by default.' 'planner must not over-assign review agents'

# Ordinary validation stays in root; formal verification is selective.
assert_contains "$SKILL" 'Ordinary work does not invoke a separate verification phase or skill.' 'ordinary work must not enter a formal verification phase'
assert_contains "$VERIFY" 'This is a root-orchestrator checklist, not a separate agent or mandatory phase.' 'verification gate must be root-owned and selective'
assert_contains "$VERIFY" 'Ordinary work uses focused validation and final diff inspection without invoking this skill.' 'ordinary validation must remain lightweight'

# Delegation packets stay cheaper than direct execution.
assert_contains "$PACKETS" 'Packet preparation must be cheaper than doing the delegated task in the root.' 'packet overhead must be bounded'
assert_contains "$PACKETS" 'Create one packet per independent lane and launch parallel-safe lanes together.' 'packets must map to useful parallel lanes'
assert_not_contains "$PACKETS" 'Implementation Launch Gate result' 'packets must not carry the removed launch gate'

# PR feedback uses complete context and preserves remote-write boundaries.
assert_contains "$PR_FEEDBACK" 'Classify each unresolved, non-outdated feedback thread' 'PR feedback must triage every active thread'
for decision in accept decline already-addressed out-of-scope; do
  assert_contains "$PR_FEEDBACK" "\`$decision\`" "PR feedback missing decision: $decision"
done
assert_contains "$PR_FEEDBACK" '## 5. Rescan Affected Invariants' 'PR feedback fixes must trigger invariant rescanning when warranted'
assert_contains "$PR_FEEDBACK" 'never use `git add -A`' 'PR feedback must stage surgically'
assert_contains "$PR_FEEDBACK" 'Do not automatically reply to every historical comment' 'PR feedback must avoid noisy automatic replies'
assert_contains "$PR_FEEDBACK" 'apply AI-review labels' 'PR feedback must prohibit AI labels'
assert_contains "$PR_FEEDBACK" 'Update the remote PR body only when the user explicitly authorizes that action.' 'PR feedback must protect PR-body writes'
assert_contains "$PR_FEEDBACK" 'end-to-end changed flow' 'PR feedback must preserve a detailed change narrative'
assert_contains "$PR_FEEDBACK" 'focused Mermaid' 'PR feedback must preserve useful diagrams'
assert_contains "$PLUGIN_DIR/README.md" 'The `pr-feedback` skill handles review comments' 'Codex README must document PR feedback'

# Model routing reserves high effort for exceptional judgment.
assert_contains "$PLUGIN_DIR/agents/compass-context-scout.toml" 'model_reasoning_effort = "low"' 'scout must use low effort'
assert_contains "$PLUGIN_DIR/agents/compass-doer.toml" 'model_reasoning_effort = "low"' 'doer must use low effort'
assert_contains "$PLUGIN_DIR/agents/compass-planner.toml" 'model_reasoning_effort = "medium"' 'planner must use medium effort'
assert_contains "$PLUGIN_DIR/agents/compass-implementer.toml" 'model_reasoning_effort = "medium"' 'implementer must use medium effort'
assert_contains "$PLUGIN_DIR/agents/compass-quick-reviewer.toml" 'model = "gpt-5.6-terra"' 'quick reviewer must use Terra'
assert_contains "$PLUGIN_DIR/agents/compass-quick-reviewer.toml" 'model_reasoning_effort = "medium"' 'quick reviewer must use medium effort'
assert_contains "$PLUGIN_DIR/agents/compass-pr-reviewer.toml" 'model_reasoning_effort = "high"' 'strong reviewer must retain high effort'
assert_contains "$PLUGIN_DIR/agents/compass-pr-reviewer.toml" 'end-to-end behavior' 'strong reviewer must enforce detailed PR narratives'
assert_contains "$PLUGIN_DIR/agents/compass-pr-reviewer.toml" 'high-importance contracts' 'strong reviewer must scrutinize important paths'
assert_contains "$PLUGIN_DIR/agents/compass-pr-reviewer.toml" 'three or more interacting components' 'strong reviewer must request useful diagrams'
assert_contains "$PLUGIN_DIR/agents/compass-plan-auditor.toml" 'model_reasoning_effort = "max"' 'exceptional auditor must retain max effort'
assert_contains "$PLUGIN_DIR/agents/compass-plan-auditor.toml" 'Run only for an explicit user audit or exceptional' 'auditor must not be part of ordinary routing'

# Launcher and permissions preserve the existing safe local workflow.
assert_contains "$PLUGIN_DIR/scripts/compass" '-m gpt-5.6-sol --ask-for-approval on-request' 'orchestrator must use Sol with reviewable approvals'
assert_contains "$PLUGIN_DIR/scripts/compass" '-c approvals_reviewer=auto_review' 'launcher must use Approve for me review'
assert_contains "$PLUGIN_DIR/scripts/compass" '-c model_reasoning_effort=high' 'orchestrator must use high effort'
assert_contains "$PLUGIN_DIR/scripts/compass" 'CODEX_CMD=/opt/homebrew/bin/codex' 'launcher must prefer the Apple Silicon Homebrew CLI'
assert_contains "$PLUGIN_DIR/scripts/compass" 'CODEX_CMD=/usr/local/bin/codex' 'launcher must support the Intel Homebrew CLI'
assert_contains "$PLUGIN_DIR/scripts/compass" 'CODEX_BIN' 'launcher must support an explicit Codex binary override'
assert_contains "$PLUGIN_DIR/scripts/compass" 'experimental_compact_prompt_file=$COMPACT_PROMPT' 'launcher must configure the Compass compact prompt'
assert_contains "$PLUGIN_DIR/scripts/compass" 'tui.status_line=["model-with-reasoning","run-state","context-remaining","git-branch"]' 'launcher must configure the native status line'
assert_not_contains "$PLUGIN_DIR/scripts/compass" '--ask-for-approval never' 'launcher must not reject approval requests automatically'
assert_not_contains "$PLUGIN_DIR/scripts/compass" '--dangerously-bypass-approvals-and-sandbox' 'launcher must preserve the sandbox boundary'

# Event-driven joins remain correct without making agents mandatory.
assert_contains "$SKILL" 'process root-owned work before waiting' 'root work must precede waiting'
assert_contains "$SKILL" 'wait_agent(timeout_ms=3600000)' 'orchestrator must use event-driven long waits'
assert_contains "$SKILL" 'Treat a wake as an event, not proof of completion.' 'orchestrator must not infer completion from a wake'
assert_contains "$SKILL" 'Never infer specialist findings from status alone' 'orchestrator must require actual packets'
assert_contains "$PLUGIN_DIR/prompts/compass-compact.md" 'Root Work And Task Graph' 'compact prompt must preserve root-owned work'
assert_contains "$PLUGIN_DIR/prompts/compass-compact.md" 'prioritizing root work before waiting' 'compaction must preserve latency-aware continuation'
assert_contains "$PLUGIN_DIR/prompts/compass-compact.md" 'wait_agent(timeout_ms=3600000)' 'compact prompt must preserve event-driven waiting'

if grep -Fq 'Compass: compass-orchestrator' "$SKILL" "$COMMAND"; then
  fail 'Codex Compass must not emit a simulated status line'
fi

printf 'Compass Codex contracts passed.\n'
