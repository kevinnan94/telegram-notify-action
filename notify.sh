#!/usr/bin/env bash
# Sends $TG_MESSAGE to $TG_CHAT_ID via the Telegram Bot API. Prints the message id.
# Set TG_DRY_RUN=1 to print the JSON payload instead of calling the API (used by tests).
set -euo pipefail

: "${TG_TOKEN:?TG_TOKEN is required}"
: "${TG_CHAT_ID:?TG_CHAT_ID is required}"
: "${TG_MESSAGE:?TG_MESSAGE is required}"
TG_PARSE_MODE="${TG_PARSE_MODE:-HTML}"
TG_DISABLE_PREVIEW="${TG_DISABLE_PREVIEW:-true}"
MAX_LEN=4096

msg="$TG_MESSAGE"
if [ "${#msg}" -gt "$MAX_LEN" ]; then
  msg="${msg:0:$((MAX_LEN - 1))}…"
fi

# Build JSON with jq when available, otherwise with python. Both escape the text correctly.
if command -v jq >/dev/null 2>&1; then
  payload=$(jq -cn --arg chat "$TG_CHAT_ID" --arg text "$msg" --arg mode "$TG_PARSE_MODE" \
    --argjson preview "$([ "$TG_DISABLE_PREVIEW" = "true" ] && echo true || echo false)" \
    '{chat_id:$chat, text:$text, parse_mode:$mode, disable_web_page_preview:$preview}')
else
  payload=$(python3 - "$TG_CHAT_ID" "$msg" "$TG_PARSE_MODE" "$TG_DISABLE_PREVIEW" <<'PY'
import json, sys
chat, text, mode, preview = sys.argv[1:5]
print(json.dumps({"chat_id": chat, "text": text, "parse_mode": mode,
                  "disable_web_page_preview": preview == "true"}, ensure_ascii=False, separators=(",", ":")))
PY
)
fi

if [ "${TG_DRY_RUN:-0}" = "1" ]; then
  echo "$payload"
  exit 0
fi

response=$(curl -sS -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
  -H "Content-Type: application/json" -d "$payload") || { echo "telegram: request failed" >&2; exit 1; }

if ! printf '%s' "$response" | grep -q '"ok":true'; then
  # never echo the token; the API response does not contain it
  echo "telegram: API error: $(printf '%s' "$response" | head -c 300)" >&2
  exit 1
fi

printf '%s' "$response" | sed -n 's/.*"message_id":\([0-9]*\).*/\1/p'
