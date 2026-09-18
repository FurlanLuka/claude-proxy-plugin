#!/bin/sh
# No output = the normal approval dialog appears. Always exit 0: a
# PermissionRequest hook decides only via stdout JSON; non-zero just prints a warning.
# The marker is keyed on session_id (always present in hook input); the other two
# hooks create and remove it.
# ExitPlanMode is a user-interaction tool: Claude Code honors "allow" only when the
# decision also carries updatedInput echoing the tool input, so the plan is passed
# back verbatim. That needs a real JSON parser; without jq or python3 the dialog appears.

input=$(cat)
field() { printf '%s' "$input" | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p"; }

sid=$(field session_id)
case "$sid" in ''|*[!A-Za-z0-9-]*) exit 0 ;; esac
[ -f "/tmp/claude-proxy-solo-$sid" ] || exit 0

if command -v jq >/dev/null 2>&1; then
  printf '%s' "$input" | jq -c '{hookSpecificOutput:{hookEventName:"PermissionRequest",decision:{behavior:"allow",updatedInput:(.tool_input // {})}}}'
elif command -v python3 >/dev/null 2>&1; then
  printf '%s' "$input" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(json.dumps({"hookSpecificOutput":{"hookEventName":"PermissionRequest","decision":{"behavior":"allow","updatedInput":d.get("tool_input") or {}}}}, separators=(",",":"), ensure_ascii=False))'
fi
exit 0
