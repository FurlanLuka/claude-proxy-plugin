#!/bin/sh
# No output = the normal approval dialog appears. Always exit 0: a
# PermissionRequest hook decides only via stdout JSON; non-zero just prints a warning.

input=$(cat)
dir=$(printf '%s' "$input" | sed -n 's/.*"scratchpad_dir"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')

[ -n "$dir" ] && [ -f "$dir/proxy-solo" ] && \
  printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PermissionRequest","decision":{"behavior":"allow"}}}'
exit 0
