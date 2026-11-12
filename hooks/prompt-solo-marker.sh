#!/bin/sh
# UserPromptSubmit owns the typed path. A typed /proxy:solo never reaches the Skill
# tool (the command expands straight into the prompt), so that prompt arms the
# marker. A typed /proxy:pair or /proxy:brainstorm, or a prompt that is only "stop solo" / "exit solo",
# disarms it. Every other prompt leaves the marker alone: steering a solo run must
# not end it, and subagent reports, task notifications and messages from other
# sessions also arrive here as prompts. Their shapes change between Claude Code
# versions, so nothing here tries to tell them apart from the user.
# Always exit 0: a non-zero UserPromptSubmit hook would block the prompt.

input=$(cat)
field() { printf '%s' "$input" | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p"; }

sid=$(field session_id)
case "$sid" in ''|*[!A-Za-z0-9-]*) exit 0 ;; esac
prompt=$(field prompt)
# prompt text arrives JSON-escaped, so a newline after the command is the two characters \n
case "$prompt" in
  /proxy:solo|"/proxy:solo "*|"/proxy:solo\\n"*|"/proxy:solo\\t"*) touch "/tmp/claude-proxy-solo-$sid"; exit 0 ;;
  /proxy:pair|"/proxy:pair "*|"/proxy:pair\\n"*|"/proxy:pair\\t"*|\
  /proxy:brainstorm|"/proxy:brainstorm "*|"/proxy:brainstorm\\n"*|"/proxy:brainstorm\\t"*) rm -f "/tmp/claude-proxy-solo-$sid"; exit 0 ;;
esac
# Spoken or typed stop: the whole prompt, ignoring case and trailing punctuation.
spoken=$(printf '%s' "$prompt" | tr '[:upper:]' '[:lower:]' | sed 's/[[:space:][:punct:]]*$//')
case "$spoken" in
  "stop solo"|"exit solo") rm -f "/tmp/claude-proxy-solo-$sid" ;;
esac
exit 0
