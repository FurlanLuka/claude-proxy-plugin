#!/bin/sh
# Invoking proxy:solo arms the session marker that lets ExitPlanMode auto-approve;
# invoking proxy:pair disarms it. The model never writes the marker itself, so no
# permission classifier has to judge that write.
# Always exit 0: this hook must never block a skill invocation.

input=$(cat)
field() { printf '%s' "$input" | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p"; }

sid=$(field session_id)
case "$sid" in ''|*[!A-Za-z0-9-]*) exit 0 ;; esac
case "$(field skill)" in
  proxy:solo) touch "/tmp/claude-proxy-solo-$sid" ;;
  proxy:pair) rm -f "/tmp/claude-proxy-solo-$sid" ;;
esac
exit 0
