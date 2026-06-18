#!/usr/bin/env bash
set -euo pipefail

project_root="${1:-$PWD}"
phase="${2:-orientation}"
active_agents="${3:-none}"
todo_state="${4:-0/0}"
last_completed="${5:-session start}"
next_step="${6:-awaiting user input}"

# Each Claude Code session has a stable PPID (the Claude process PID).
# Use it as the session ID so concurrent sessions write separate files.
session_id="$PPID"
dashboard_dir="$project_root/.compass"
dashboard_file="$dashboard_dir/dashboard-${session_id}.html"

mkdir -p "$dashboard_dir"

# Remove dashboards whose parent process is no longer running.
for stale in "$dashboard_dir"/dashboard-*.html; do
  [ -f "$stale" ] || continue
  stale_pid="${stale##*dashboard-}"
  stale_pid="${stale_pid%.html}"
  if [[ "$stale_pid" =~ ^[0-9]+$ ]] && ! kill -0 "$stale_pid" 2>/dev/null; then
    rm -f "$stale"
  fi
done

# Track whether this is a new session so we can open the browser once.
is_new_session=false
[ ! -f "$dashboard_file" ] && is_new_session=true

# Git branch
branch="unknown"
if git -C "$project_root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch="$(git -C "$project_root" branch --show-current 2>/dev/null || true)"
  [ -z "$branch" ] && branch="$(git -C "$project_root" rev-parse --short HEAD 2>/dev/null || true)"
fi

updated="$(date '+%H:%M:%S')"

# Phase → CSS class
case "$phase" in
  context)                        phase_class="context" ;;
  planning|plan-audit)            phase_class="planning" ;;
  implementation)                 phase_class="implementation" ;;
  verification)                   phase_class="verification" ;;
  *)                              phase_class="idle" ;;
esac

# Build agent cards.
# Format: "agent-key|Display Name|role description"
declare -a AGENTS=(
  "compass-orchestrator|orchestrator|routes all work"
  "compass-planner|planner|creates plans"
  "compass-plan-auditor|plan-auditor|audits plans"
  "compass-context-scout|context-scout|repo discovery"
  "compass-log-digester|log-digester|digests logs"
  "compass-doer|doer|delegated tasks"
  "compass-implementer|implementer|executes plans"
  "compass-test-runner|test-runner|runs tests"
)

agent_cards=""
for entry in "${AGENTS[@]}"; do
  key="${entry%%|*}"
  rest="${entry#*|}"
  display="${rest%%|*}"
  role="${rest#*|}"
  css="agent"
  [[ "$active_agents" == *"$key"* ]] && css="agent active"
  agent_cards+="<div class=\"${css}\"><div class=\"agent-name\"><span class=\"agent-dot\"></span>${display}</div><div class=\"agent-role\">${role}</div></div>"
done

tmp_file="${dashboard_file}.tmp"

cat > "$tmp_file" << HTMLEOF
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta http-equiv="refresh" content="2">
  <title>Compass · ${phase}</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif;
      background: #0f172a;
      color: #e2e8f0;
      min-height: 100vh;
      padding: 28px;
    }
    .header {
      display: flex;
      align-items: center;
      gap: 14px;
      margin-bottom: 28px;
      padding-bottom: 20px;
      border-bottom: 1px solid #1e293b;
    }
    .logo {
      font-size: 0.95rem;
      font-weight: 700;
      color: #475569;
      letter-spacing: 0.18em;
      text-transform: uppercase;
    }
    .phase-badge {
      padding: 3px 12px;
      border-radius: 999px;
      font-size: 0.72rem;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 0.06em;
    }
    .phase-idle           { background: #1e293b; color: #475569; }
    .phase-context        { background: #1e3a5f; color: #93c5fd; }
    .phase-planning       { background: #2d1b69; color: #c4b5fd; }
    .phase-implementation { background: #431407; color: #fdba74; }
    .phase-verification   { background: #14532d; color: #86efac; }
    .todo-counter {
      margin-left: auto;
      font-size: 0.8rem;
      color: #334155;
      font-variant-numeric: tabular-nums;
    }
    .section-label {
      font-size: 0.65rem;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 0.14em;
      color: #334155;
      margin-bottom: 10px;
    }
    .agents {
      display: grid;
      grid-template-columns: repeat(4, 1fr);
      gap: 8px;
      margin-bottom: 28px;
    }
    .agent {
      background: #1e293b;
      border: 1px solid #1e293b;
      border-radius: 8px;
      padding: 12px 14px;
    }
    .agent-name {
      font-size: 0.78rem;
      font-weight: 500;
      color: #334155;
    }
    .agent-role {
      font-size: 0.66rem;
      color: #1e293b;
      margin-top: 3px;
    }
    .agent-dot {
      display: inline-block;
      width: 6px;
      height: 6px;
      border-radius: 50%;
      background: #334155;
      margin-right: 7px;
      vertical-align: middle;
      position: relative;
      top: -1px;
    }
    .agent.active {
      background: #0f2847;
      border-color: #1d4ed8;
      box-shadow: 0 0 0 1px #1d4ed8, 0 0 18px rgba(29,78,216,0.12);
    }
    .agent.active .agent-name { color: #93c5fd; }
    .agent.active .agent-role { color: #3b82f6; }
    .agent.active .agent-dot {
      background: #3b82f6;
      animation: glow 1.8s ease-in-out infinite;
    }
    @keyframes glow {
      0%, 100% { box-shadow: 0 0 4px rgba(59,130,246,0.8); }
      50%       { box-shadow: 0 0 10px rgba(96,165,250,0.9); }
    }
    .meta { display: flex; flex-direction: column; gap: 7px; }
    .meta-row { font-size: 0.75rem; display: flex; gap: 10px; }
    .meta-label { color: #334155; font-weight: 500; min-width: 72px; }
    .meta-value { color: #475569; }
    .footer {
      margin-top: 28px;
      font-size: 0.62rem;
      color: #1e293b;
    }
  </style>
</head>
<body>
  <div class="header">
    <span class="logo">Compass</span>
    <span class="phase-badge phase-${phase_class}">${phase}</span>
    <span class="todo-counter">${todo_state}</span>
  </div>

  <div class="section-label">Agents</div>
  <div class="agents">${agent_cards}</div>

  <div class="section-label">Status</div>
  <div class="meta">
    <div class="meta-row"><span class="meta-label">Last</span><span class="meta-value">${last_completed}</span></div>
    <div class="meta-row"><span class="meta-label">Next</span><span class="meta-value">${next_step}</span></div>
    <div class="meta-row"><span class="meta-label">Branch</span><span class="meta-value">${branch}</span></div>
  </div>

  <div class="footer">↻ refreshes every 2s &nbsp;·&nbsp; session ${session_id} &nbsp;·&nbsp; ${updated}</div>
</body>
</html>
HTMLEOF

mv "$tmp_file" "$dashboard_file"

# Open the browser once per session.
if [ "$is_new_session" = true ] && command -v open >/dev/null 2>&1; then
  open "$dashboard_file" || true
fi

printf '%s\n' "$dashboard_file"
