#!/usr/bin/env bash

input="$(cat)"
compact_input="$(printf '%s' "$input" | tr -d '\r\n')"

extract_string() {
  local key="$1"
  printf '%s' "$compact_input" |
    sed -nE "s/.*\"${key}\"[[:space:]]*:[[:space:]]*\"([^\"]*)\".*/\1/p"
}

extract_number() {
  local key="$1"
  printf '%s' "$compact_input" |
    sed -nE "s/.*\"${key}\"[[:space:]]*:[[:space:]]*([0-9]+([.][0-9]+)?).*/\1/p"
}

model="$(extract_string display_name)"
effort="$(extract_string level)"
remaining="$(extract_number remaining_percentage)"

label="${COMPASS_CLAUDE_LABEL:-Compass}"
model="${model:-Claude}"

if [[ -n "$effort" ]]; then
  model_segment="$model/$effort"
else
  model_segment="$model"
fi

if [[ -n "$remaining" ]]; then
  remaining="${remaining%%.*}"
  remaining=$((10#$remaining))
  ((remaining < 0)) && remaining=0
  ((remaining > 100)) && remaining=100

  bar_width=10
  filled=$((remaining * bar_width / 100))
  empty=$((bar_width - filled))
  printf -v filled_bar '%*s' "$filled" ''
  printf -v empty_bar '%*s' "$empty" ''
  context_segment="ctx [${filled_bar// /=}${empty_bar// /-}] ${remaining}% left"
else
  context_segment='ctx [----------] --'
fi

branch=''
if command -v git >/dev/null 2>&1; then
  branch="$(git symbolic-ref --quiet --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null || true)"
fi

status="$label · $model_segment · $context_segment"
if [[ -n "$branch" ]]; then
  status="$status · $branch"
fi

printf '%s\n' "$status"
