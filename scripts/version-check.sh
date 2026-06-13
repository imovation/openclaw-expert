#!/usr/bin/env bash
set -euo pipefail

STATE_FILE="$HOME/.openclaw-expert/version-state.json"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

command_exists() {
  command -v "$1" &>/dev/null
}

get_current_version() {
  if command_exists openclaw; then
    openclaw --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1
  else
    echo ""
  fi
}

do_detect() {
  CURRENT=$(get_current_version)
  if [ -z "$CURRENT" ]; then
    echo "NOT_INSTALLED"
    return 1
  fi

  if [ ! -f "$STATE_FILE" ]; then
    echo "FIRST_RUN:$CURRENT"
    return 2
  fi

  LAST=$(python3 -c "import json; print(json.load(open('$STATE_FILE')).get('last_known_version',''))" 2>/dev/null || echo "")
  if [ "$CURRENT" != "$LAST" ]; then
    echo "VERSION_CHANGED:${LAST}->${CURRENT}"
    return 0
  else
    echo "UP_TO_DATE:$CURRENT"
    return 0
  fi
}

do_record() {
  CURRENT=$(get_current_version)
  if [ -z "$CURRENT" ]; then
    echo "Error: openclaw not installed"
    exit 1
  fi
  mkdir -p "$(dirname "$STATE_FILE")"
  python3 -c "
import json, datetime
state = {
  'last_known_version': '$CURRENT',
  'last_docs_update': datetime.datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ'),
  'installed_method': 'npm'
}
with open('$STATE_FILE', 'w') as f:
  json.dump(state, f, indent=2)
"
  echo "Recorded version: $CURRENT"
}

case "${1:-detect}" in
  --detect|-d) do_detect ;;
  --record|-r) do_record ;;
  --version|-v)
    get_current_version
    ;;
  *)
    echo "Usage: $0 [--detect|--record|--version]"
    echo "  --detect    Check if openclaw version changed"
    echo "  --record    Record current version to state file"
    echo "  --version   Print current openclaw version"
    exit 1
    ;;
esac
