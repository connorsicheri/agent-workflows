#!/usr/bin/env bash
set -euo pipefail

project_root="${1:-$PWD}"
phase="${2:-orientation}"
active_agents="${3:-none}"
todo_state="${4:-0/0}"
last_completed="${5:-session start}"
next_step="${6:-awaiting user input}"

map_dir="$project_root/.compass"
map_file="$map_dir/compass-map.md"
tmp_file="$map_file.tmp"

mkdir -p "$map_dir"
touch "$map_file"

# Claude Code's file tools can require read-before-write. Keep the same
# deterministic behavior here even though Bash could overwrite directly.
cat "$map_file" >/dev/null

branch="unknown"
if git -C "$project_root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch="$(git -C "$project_root" branch --show-current 2>/dev/null || true)"
  if [ -z "$branch" ]; then
    branch="$(git -C "$project_root" rev-parse --short HEAD 2>/dev/null || true)"
  fi
fi

updated="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

active_class_lines=""
if [[ "$active_agents" == *"compass-planner"* ]]; then
  active_class_lines+="  class P current;"$'\n'
fi
if [[ "$active_agents" == *"compass-plan-auditor"* ]]; then
  active_class_lines+="  class A current;"$'\n'
fi
if [[ "$active_agents" == *"compass-context-scout"* ]]; then
  active_class_lines+="  class S current;"$'\n'
fi
if [[ "$active_agents" == *"compass-log-digester"* ]]; then
  active_class_lines+="  class L current;"$'\n'
fi
if [[ "$active_agents" == *"compass-doer"* ]]; then
  active_class_lines+="  class D current;"$'\n'
fi
if [[ "$active_agents" == *"compass-implementer"* ]]; then
  active_class_lines+="  class I current;"$'\n'
fi
if [[ "$active_agents" == *"compass-test-runner"* ]]; then
  active_class_lines+="  class T current;"$'\n'
fi

cat > "$tmp_file" <<EOF
# Compass Map

- Phase: $phase
- Active agents: $active_agents
- TODO: $todo_state
- Last completed: $last_completed
- Next: $next_step
- Branch: $branch
- Updated: $updated

\`\`\`mermaid
flowchart LR
  U["User"]
  O["compass-orchestrator"]

  subgraph State["Session state"]
    direction TB
    B["TODO board"]
    M[".compass/compass-map.md"]
  end

  subgraph Planning["Planning"]
    direction TB
    P["compass-planner"]
    A["compass-plan-auditor"]
  end

  subgraph Discovery["Discovery and diagnostics"]
    direction TB
    S["compass-context-scout"]
    L["compass-log-digester"]
  end

  subgraph Execution["Execution"]
    direction TB
    D["compass-doer"]
    I["compass-implementer"]
    T["compass-test-runner"]
  end

  U <--> O
  O <--> B
  O --> M
  O -. plan .-> P
  O -. audit .-> A
  O -. inspect .-> S
  O -. digest logs .-> L
  O -. do task .-> D
  O -. implement .-> I
  O -. verify .-> T

  classDef focus fill:#ffffff,stroke:#475569,stroke-width:2px,color:#111827;
  classDef current fill:#f8fafc,stroke:#334155,stroke-width:3px,color:#111827;
  classDef support fill:#ffffff,stroke:#cbd5e1,stroke-width:1.5px,color:#334155;
  class U,O,B,M focus;
  class P,A,S,L,D,I,T support;
${active_class_lines}
\`\`\`
EOF

mv "$tmp_file" "$map_file"
printf '%s\n' "$map_file"
