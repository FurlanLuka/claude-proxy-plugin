#!/bin/sh
# No output = the normal approval dialog appears. Always exit 0: a
# PermissionRequest hook decides only via stdout JSON; non-zero just prints a warning.
# The marker is keyed on session_id (always present in hook input) and created by
# arm-solo-marker.sh when proxy:solo is invoked.

input=$(cat)
field() { printf '%s' "$input" | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p"; }

sid=$(field session_id)
case "$sid" in ''|*[!A-Za-z0-9-]*) exit 0 ;; esac
[ -f "/tmp/claude-proxy-solo-$sid" ] && \
  printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PermissionRequest","decision":{"behavior":"allow"}}}'
exit 0
