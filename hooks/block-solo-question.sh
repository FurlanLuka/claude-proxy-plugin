#!/bin/sh
# solo asks no questions. While the session marker exists, AskUserQuestion is denied
# and the model is told to decide instead, so the rule holds even when the model
# forgets it. No marker = no output = the question goes through as usual.
# Always exit 0: the decision is carried by stdout JSON only.

input=$(cat)
field() { printf '%s' "$input" | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p"; }

sid=$(field session_id)
case "$sid" in ''|*[!A-Za-z0-9-]*) exit 0 ;; esac
[ -f "/tmp/claude-proxy-solo-$sid" ] || exit 0

printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"proxy:solo is active, so no questions. Make this call yourself by the solo rules and add it to Decisions made. The user ends solo by invoking proxy:pair or saying \"stop solo\"."}}'
exit 0
