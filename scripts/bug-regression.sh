#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EXP_INDEX="$SCRIPT_DIR/../references/experience/index.json"
BUG_ID="${1:-}"

if [ -z "$BUG_ID" ]; then
  echo "Usage: $0 --id <exp-id>"
  echo "  Attempts to reproduce a known bug locally"
  echo "  Returns 0 if bug is STILL PRESENT, 1 if FIXED, 2 if UNVERIFIABLE"
  exit 1
fi

if [ "$BUG_ID" = "--id" ]; then
  BUG_ID="${2:-}"
  if [ -z "$BUG_ID" ]; then
    echo "Error: exp-id required"
    exit 1
  fi
fi

get_bug_field() {
  local field="$1"
  python3 -c "
import json, sys
with open('$EXP_INDEX') as f:
    data = json.load(f)
for exp in data.get('experiences', []):
    if exp.get('id') == '$BUG_ID':
        print(exp.get('$field', ''))
        sys.exit(0)
sys.exit(1)
" 2>/dev/null
}

TITLE=$(get_bug_field "title")
TOPIC=$(get_bug_field "topic")
STATUS=$(get_bug_field "status")
BUG_FILE=$(get_bug_field "file")

if [ -z "$TITLE" ]; then
  echo "Bug $BUG_ID not found in experience index"
  exit 2
fi

echo "============================================"
echo "BUG Regression Test: $TITLE"
echo "ID: $BUG_ID | Topic: $TOPIC | Status: $STATUS"
echo "============================================"

REPRO_SCRIPT="$SCRIPT_DIR/../references/experience/$BUG_FILE.repro.sh"

if [ -f "$REPRO_SCRIPT" ]; then
  echo "Running reproduction script: $REPRO_SCRIPT"
  if bash "$REPRO_SCRIPT"; then
    echo ""
    echo "RESULT: BUG STILL PRESENT"
    echo "The reproduction script succeeded, indicating the bug is NOT fixed."
    exit 0
  else
    echo ""
    echo "RESULT: BUG APPEARS FIXED"
    echo "The reproduction script failed, indicating the bug may be fixed."
    exit 1
  fi
fi

echo "No reproduction script found ($REPRO_SCRIPT)."
echo "Checking changelog for mentions of this bug..."

OPENCLAW_VERSION=$(openclaw --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "")
if [ -n "$OPENCLAW_VERSION" ]; then
  RELEASE_URL="https://github.com/openclaw/openclaw/releases/tag/v${OPENCLAW_VERSION}"
  echo "Fetching release notes: $RELEASE_URL"
  CHANGELOG=$(curl -sL --max-time 15 "$RELEASE_URL" 2>/dev/null || echo "")

  if [ -n "$CHANGELOG" ]; then
    KEYWORDS=$(echo "$TITLE" | tr ' ' '|')
    if echo "$CHANGELOG" | grep -qiE "($KEYWORDS)"; then
      echo "RESULT: CHANGELOG MENTIONS RELATED FIX - likely fixed"
      exit 1
    else
      echo "RESULT: NO MENTION IN CHANGELOG - likely still present"
      exit 0
    fi
  fi
fi

echo "RESULT: UNVERIFIABLE (no repro script, no changelog data)"
exit 2
