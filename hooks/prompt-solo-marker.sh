#!/bin/sh
# UserPromptSubmit owns the typed path. A typed /proxy:solo never reaches the Skill
# tool (the command expands straight into the prompt), so that prompt arms the
# marker. Any other prompt outside plan mode ends the auto-approval window. A prompt
# inside plan mode is the user steering the plan solo is writing, so the marker stays.
# A background agent or workflow reporting back also fires UserPromptSubmit, with the
# report as the prompt. That is not the user speaking, so it leaves the marker alone.
# Always exit 0: a non-zero UserPromptSubmit hook would block the prompt.

input=$(cat)
field() { printf '%s' "$input" | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p"; }

sid=$(field session_id)
case "$sid" in ''|*[!A-Za-z0-9-]*) exit 0 ;; esac
# prompt text arrives JSON-escaped, so a newline after the command is the two characters \n
case "$(field prompt)" in
  "<task-notification>"*) exit 0 ;;
  /proxy:solo|"/proxy:solo "*|"/proxy:solo\\n"*|"/proxy:solo\\t"*) touch "/tmp/claude-proxy-solo-$sid"; exit 0 ;;
esac
[ "$(field permission_mode)" = "plan" ] && exit 0
rm -f "/tmp/claude-proxy-solo-$sid"
exit 0
