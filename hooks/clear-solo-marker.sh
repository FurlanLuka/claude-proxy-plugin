#!/bin/sh
# A prompt outside plan mode ends any solo auto-approval window. A prompt inside
# plan mode is the user steering the plan solo is writing, so the marker stays.
# Always exit 0: a non-zero UserPromptSubmit hook would block the prompt.

input=$(cat)
field() { printf '%s' "$input" | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p"; }

[ "$(field permission_mode)" = "plan" ] && exit 0
sid=$(field session_id)
case "$sid" in ''|*[!A-Za-z0-9-]*) exit 0 ;; esac
rm -f "/tmp/claude-proxy-solo-$sid"
exit 0
