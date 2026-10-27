#!/usr/bin/env bash
# Self-check for notify.sh in dry-run mode. Run: bash test/test_notify.sh
set -euo pipefail
cd "$(dirname "$0")/.."
export TG_DRY_RUN=1 TG_TOKEN=x TG_CHAT_ID=123

fail() { echo "FAIL: $1" >&2; exit 1; }

out=$(TG_MESSAGE='hello <b>world</b> & "quotes"' ./notify.sh)
echo "$out" | grep -q '"chat_id":"123"' || fail "chat_id missing"
echo "$out" | grep -q '"parse_mode":"HTML"' || fail "default parse_mode"
echo "$out" | grep -q '"disable_web_page_preview":true' || fail "preview default"
echo "$out" | grep -q 'hello <b>world</b> & \\"quotes\\"' || fail "text not JSON-escaped: $out"

out=$(TG_MESSAGE='x' TG_PARSE_MODE=MarkdownV2 TG_DISABLE_PREVIEW=false ./notify.sh)
echo "$out" | grep -q '"parse_mode":"MarkdownV2"' || fail "parse_mode override"
echo "$out" | grep -q '"disable_web_page_preview":false' || fail "preview override"

long=$(head -c 5000 /dev/zero | tr '\0' 'a')
out=$(TG_MESSAGE="$long" ./notify.sh)
len=$(echo "$out" | python3 -c 'import json,sys; print(len(json.load(sys.stdin)["text"]))')
[ "$len" -le 4096 ] || fail "message not truncated: $len"

if TG_MESSAGE= ./notify.sh 2>/dev/null; then fail "empty message should fail"; fi

echo "OK: all checks passed"
