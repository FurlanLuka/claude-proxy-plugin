#!/usr/bin/env bash
# Stop hook: pipe the final response to Telegram when it looks like a real
# completion, not a quick reply. Reads the Stop event's JSON payload from
# stdin (see Claude Code hooks docs — Stop receives last_assistant_message).
#
# Requires two env vars, set on your machine (never committed):
#   PROXY_TELEGRAM_BOT_TOKEN — from @BotFather
#   PROXY_TELEGRAM_CHAT_ID   — your chat id
# Silently does nothing if either is unset, so this is a no-op for anyone
# who hasn't configured Telegram.
#
# Optional: PROXY_TELEGRAM_MIN_LENGTH (default 400) — only notify if the
# response is at least this many characters, to filter out quick replies.

set -euo pipefail

if [[ -z "${PROXY_TELEGRAM_BOT_TOKEN:-}" || -z "${PROXY_TELEGRAM_CHAT_ID:-}" ]]; then
  exit 0
fi

MIN_LENGTH="${PROXY_TELEGRAM_MIN_LENGTH:-400}"

payload="$(cat)"
message="$(echo "$payload" | jq -r '.last_assistant_message // empty')"

if [[ -z "$message" || "${#message}" -lt "$MIN_LENGTH" ]]; then
  exit 0
fi

# Telegram messages cap at 4096 chars — truncate with a marker if needed.
truncated="$(echo "$message" | head -c 3800)"
if [[ "${#message}" -gt 3800 ]]; then
  truncated="${truncated}...[truncated]"
fi

curl -s -X POST "https://api.telegram.org/bot${PROXY_TELEGRAM_BOT_TOKEN}/sendMessage" \
  -d chat_id="${PROXY_TELEGRAM_CHAT_ID}" \
  --data-urlencode text="${truncated}" \
  > /dev/null || true

exit 0
