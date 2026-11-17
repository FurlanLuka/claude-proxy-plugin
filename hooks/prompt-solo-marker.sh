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

# The prompt arrives JSON-escaped: a newline typed after the command is the two
# characters \n. Decode it with a real parser when one is present, so trailing
# whitespace is whitespace. Without jq or python3, fall back to the raw field with
# the common whitespace escapes turned into spaces. That fallback cannot tell a real
# newline from a typed backslash followed by n, so the stop command below is only
# honored there when the raw prompt holds no backslash at all: when unsure, solo
# stays armed and the user says it again.
decoded=yes
if command -v jq >/dev/null 2>&1; then
  prompt=$(printf '%s' "$input" | jq -r '.prompt // empty' 2>/dev/null)
elif command -v python3 >/dev/null 2>&1; then
  prompt=$(printf '%s' "$input" | python3 -c 'import json,sys
try:
    value = json.load(sys.stdin).get("prompt")
    sys.stdout.write(value if isinstance(value, str) else "")
except Exception:
    pass' 2>/dev/null)
else
  decoded=no
  raw=$(field prompt)
  prompt=$(printf '%s' "$raw" | sed 's/\\[nrt]/ /g')
fi

# One line, single-spaced at the edges: tabs and line breaks count as spaces.
flat=$(printf '%s' "$prompt" | tr '\n\r\t' '   ' | sed 's/^ *//; s/ *$//')
case "$flat" in
  /proxy:solo|"/proxy:solo "*) touch "/tmp/claude-proxy-solo-$sid"; exit 0 ;;
  /proxy:pair|"/proxy:pair "*|/proxy:brainstorm|"/proxy:brainstorm "*) rm -f "/tmp/claude-proxy-solo-$sid"; exit 0 ;;
esac

# Spoken or typed stop: the whole prompt, ignoring case and trailing punctuation.
if [ "$decoded" = no ]; then
  case "$raw" in *\\*) exit 0 ;; esac
fi
spoken=$(printf '%s' "$flat" | tr '[:upper:]' '[:lower:]' | sed 's/[[:space:][:punct:]]*$//')
case "$spoken" in
  "stop solo"|"exit solo") rm -f "/tmp/claude-proxy-solo-$sid" ;;
esac
exit 0
