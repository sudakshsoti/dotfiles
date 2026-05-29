#!/usr/bin/env bash
# Claude Code Notification hook — macOS banner + bell
# Reads hook JSON from stdin and surfaces a native notification.
# Clicking the banner focuses Zed (Claude Code runs inside a Zed terminal thread).

input=$(cat)
message=$(echo "$input" | jq -r '.message // "Claude needs your attention"')
cwd=$(echo "$input" | jq -r '.cwd // ""')
title="Claude Code"
subtitle="${cwd##*/}"

# terminal-notifier supports a click action (-activate <bundle-id>); osascript does not.
# Reference it by absolute path — hooks can run with a minimal PATH.
TN="$HOME/.local/bin/terminal-notifier"
[ -x "$TN" ] || TN="$(command -v terminal-notifier 2>/dev/null)"

if [ -n "$TN" ] && [ -x "$TN" ]; then
  "$TN" -title "$title" \
        -subtitle "$subtitle" \
        -message "$message" \
        -sound Glass \
        -activate dev.zed.Zed >/dev/null 2>&1
else
  # Fallback: osascript banner (no click-to-focus support)
  msg_escaped=${message//\"/\\\"}
  sub_escaped=${subtitle//\"/\\\"}
  osascript -e "display notification \"${msg_escaped}\" with title \"${title}\" subtitle \"${sub_escaped}\" sound name \"Glass\"" >/dev/null 2>&1
fi

# Terminal bell as a fallback for when notifications are silenced
printf '\a' >/dev/tty 2>/dev/null || true
