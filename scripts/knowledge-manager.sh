#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EXP_INDEX="$SCRIPT_DIR/../references/experience/index.json"
DOCS_INDEX="$SCRIPT_DIR/../references/official-docs/index.json"
EXP_ACTIVE_DIR="$SCRIPT_DIR/../references/experience/active"

command="${1:-}"
shift || true

usage() {
  echo "Usage: $0 <command> [options]"
  echo ""
  echo "Commands:"
  echo "  check-dedup --topic <topic> --title <title> --content <file>"
  echo "      Check if new experience overlaps with existing docs/experiences"
  echo "      Outputs: new | merge:<file> | skip"
  echo ""
  echo "  add-experience --topic <topic> --title <title> --content <file> --type <bug|experience>"
  echo "      Add a new experience file and update index"
  echo ""
  echo "  merge-experience --existing <file> --content <file>"
  echo "      Merge new content into existing experience file"
  echo ""
  echo "  archive-experience --id <exp-id> --fixed-in <version>"
  echo "      Move an experience from active/ to archived/"
  echo ""
  echo "  unarchive-experience --id <exp-id>"
  echo "      Move an experience from archived/ back to active/"
  echo ""
}

check_dedup() {
  local topic="" title="" content_file=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --topic) topic="$2"; shift 2 ;;
      --title) title="$2"; shift 2 ;;
      --content) content_file="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  if [ -z "$topic" ] || [ -z "$title" ] || [ -z "$content_file" ]; then
    echo "Error: --topic, --title, and --content are required"
    exit 1
  fi

  NEW_TITLE=$(echo "$title" | tr '[:upper:]' '[:lower:]')
  NEW_CONTENT=$(cat "$content_file" | tr '[:upper:]' '[:lower:]')
  NEW_KEYWORDS=$(echo "$NEW_TITLE" | tr -c 'a-z0-9' ' ')

  # Check against official docs
  DOCS_TOPIC_DIR="$SCRIPT_DIR/../references/official-docs/$topic"
  if [ -d "$DOCS_TOPIC_DIR" ]; then
    for doc in "$DOCS_TOPIC_DIR"/*.md; do
      [ -f "$doc" ] || continue
      DOC_CONTENT=$(cat "$doc" | tr '[:upper:]' '[:lower:]')
      COMMON=0
      for word in $NEW_KEYWORDS; do
        [ ${#word} -lt 4 ] && continue
        if echo "$DOC_CONTENT" | grep -qw "$word"; then
          COMMON=$((COMMON + 1))
        fi
      done
      TOTAL=$(echo "$NEW_KEYWORDS" | wc -w)
      if [ "$TOTAL" -gt 0 ] && [ "$COMMON" -gt $((TOTAL * 3 / 4)) ]; then
        echo "skip"
        return
      fi
    done
  fi

  # Check against active experiences
  ACTIVE_TOPIC_DIR="$EXP_ACTIVE_DIR/$topic"
  if [ -d "$ACTIVE_TOPIC_DIR" ]; then
    for exp_file in "$ACTIVE_TOPIC_DIR"/*.md; do
      [ -f "$exp_file" ] || continue
      EXP_CONTENT=$(cat "$exp_file" | tr '[:upper:]' '[:lower:]')
      EXP_TITLE=$(basename "$exp_file" .md | tr '-' ' ' | tr '[:upper:]' '[:lower:]')

      COMMON=0
      for word in $NEW_KEYWORDS; do
        [ ${#word} -lt 4 ] && continue
        if echo "$EXP_CONTENT" | grep -qw "$word"; then
          COMMON=$((COMMON + 1))
        fi
      done
      TOTAL=$(echo "$NEW_KEYWORDS" | wc -w)
      if [ "$TOTAL" -gt 0 ] && [ "$COMMON" -gt $((TOTAL * 2 / 3)) ]; then
        REL_PATH=$(echo "$exp_file" | sed "s|$EXP_ACTIVE_DIR/||")
        echo "merge:$REL_PATH"
        return
      fi
    done
  fi

  echo "new"
}

add_experience() {
  local topic="" title="" content_file="" exp_type="experience"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --topic) topic="$2"; shift 2 ;;
      --title) title="$2"; shift 2 ;;
      --content) content_file="$2"; shift 2 ;;
      --type) exp_type="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  if [ -z "$topic" ] || [ -z "$title" ] || [ -z "$content_file" ]; then
    echo "Error: --topic, --title, and --content are required"
    exit 1
  fi

  EXP_DIR="$EXP_ACTIVE_DIR/$topic"
  mkdir -p "$EXP_DIR"

  FILE_NAME=$(echo "$title" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-')
  EXP_FILE="$EXP_DIR/${FILE_NAME}.md"
  TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  OPENCLAW_VER=$(openclaw --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "unknown")

  cp "$content_file" "$EXP_FILE"
  EXP_ID="exp-$(date +%s)"

  python3 -c "
import json, sys
with open('$EXP_INDEX') as f:
    index = json.load(f)

new_exp = {
    'id': '$EXP_ID',
    'title': '''$title''',
    'topic': '$topic',
    'file': 'active/$topic/${FILE_NAME}.md',
    'keywords': '''$(echo "$title" | tr '[:upper:]' '[:lower:]' | tr ' ' ',')''',
    'type': '$exp_type',
    'related_bug': None,
    'status': 'active',
    'created_at': '$TIMESTAMP',
    'openclaw_version': '$OPENCLAW_VER'
}

index['experiences'].append(new_exp)
index['updated_at'] = '$TIMESTAMP'

with open('$EXP_INDEX', 'w') as f:
    json.dump(index, f, indent=2, ensure_ascii=False)
print('Added: $EXP_ID')
"
}

merge_experience() {
  local existing_file="" content_file=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --existing) existing_file="$2"; shift 2 ;;
      --content) content_file="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  if [ -z "$existing_file" ] || [ -z "$content_file" ]; then
    echo "Error: --existing and --content are required"
    exit 1
  fi

  FULL_EXISTING="$EXP_ACTIVE_DIR/$existing_file"
  if [ ! -f "$FULL_EXISTING" ]; then
    echo "Error: existing file not found: $FULL_EXISTING"
    exit 1
  fi

  {
    cat "$FULL_EXISTING"
    echo ""
    echo "---"
    echo "## 补充经验（$(date -u +"%Y-%m-%d")）"
    cat "$content_file"
  } > "${FULL_EXISTING}.tmp"

  mv "${FULL_EXISTING}.tmp" "$FULL_EXISTING"
  echo "Merged into: $existing_file"
}

archive_experience() {
  local exp_id="" fixed_in=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --id) exp_id="$2"; shift 2 ;;
      --fixed-in) fixed_in="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  python3 -c "
import json, shutil, os

with open('$EXP_INDEX') as f:
    index = json.load(f)

for exp in index['experiences']:
    if exp['id'] == '$exp_id':
        topic = exp['topic']
        old_file = '$EXP_ACTIVE_DIR/' + exp['file'].replace('active/', '')
        new_relative = 'archived/' + topic + '/' + os.path.basename(exp['file'])
        new_file = '$SCRIPT_DIR/../references/experience/' + new_relative

        os.makedirs(os.path.dirname(new_file), exist_ok=True)
        if os.path.exists(old_file):
            shutil.move(old_file, new_file)

        exp['file'] = new_relative
        exp['status'] = 'archived'
        if '$fixed_in':
            exp['fixed_in'] = '$fixed_in'

        print(f'Archived: ' + exp['id'] + ' -> ' + new_relative)
        break

index['updated_at'] = '$(date -u +"%Y-%m-%dT%H:%M:%SZ")'
with open('$EXP_INDEX', 'w') as f:
    json.dump(index, f, indent=2, ensure_ascii=False)
"
}

unarchive_experience() {
  local exp_id=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --id) exp_id="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  python3 -c "
import json, shutil, os

with open('$EXP_INDEX') as f:
    index = json.load(f)

for exp in index['experiences']:
    if exp['id'] == '$exp_id':
        topic = exp['topic']
        old_file = '$SCRIPT_DIR/../references/experience/' + exp['file']
        new_relative = 'active/' + topic + '/' + os.path.basename(exp['file'])
        new_file = '$EXP_ACTIVE_DIR/' + topic + '/' + os.path.basename(exp['file'])

        os.makedirs(os.path.dirname(new_file), exist_ok=True)
        if os.path.exists(old_file):
            shutil.move(old_file, new_file)

        exp['file'] = new_relative
        exp['status'] = 'active'
        if 'fixed_in' in exp:
            del exp['fixed_in']

        print(f'Unarchived: ' + exp['id'] + ' -> ' + new_relative)
        break

index['updated_at'] = '$(date -u +"%Y-%m-%dT%H:%M:%SZ")'
with open('$EXP_INDEX', 'w') as f:
    json.dump(index, f, indent=2, ensure_ascii=False)
"
}

case "$command" in
  check-dedup)  check_dedup "$@" ;;
  add-experience) add_experience "$@" ;;
  merge-experience) merge_experience "$@" ;;
  archive-experience) archive_experience "$@" ;;
  unarchive-experience) unarchive_experience "$@" ;;
  -h|--help|"") usage ;;
  *) echo "Unknown command: $command"; usage; exit 1 ;;
esac
