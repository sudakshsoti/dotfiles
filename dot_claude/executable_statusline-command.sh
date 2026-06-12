#!/usr/bin/env bash
# Claude Code statusLine command
# Reads JSON from stdin and outputs a status line string.

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
dir=$(basename "$cwd")

repo=$(echo "$input" | jq -r '.workspace.repo | if . then .owner + "/" + .name else empty end')

model=$(echo "$input" | jq -r '.model.display_name // empty')

used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

effort=$(echo "$input" | jq -r '.effort.level // empty')

# Build the line
parts=()

[ -n "$dir" ] && parts+=("$dir")
[ -n "$repo" ] && parts+=("$repo")
[ -n "$model" ] && parts+=("$model")
[ -n "$used" ] && parts+=("ctx:$(printf '%.0f' "$used")%")
[ -n "$effort" ] && parts+=("effort:$effort")

# Join with " | " (IFS only uses its first char, so build it explicitly)
line="${parts[0]}"
for p in "${parts[@]:1}"; do line+=" | $p"; done
printf '%s' "$line"
