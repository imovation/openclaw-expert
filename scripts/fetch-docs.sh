#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOCS_DIR="$SCRIPT_DIR/../references/official-docs"
INDEX_FILE="$DOCS_DIR/index.json"
NEW_VERSION="${1:-}"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

if [ -z "$NEW_VERSION" ]; then
  echo "Usage: $0 --version <version>"
  echo "  Fetches/refreshes all official docs from openclaw.ai"
  exit 1
fi

if [ "$NEW_VERSION" = "--version" ]; then
  NEW_VERSION="${2:-}"
  if [ -z "$NEW_VERSION" ]; then
    echo "Error: version required"
    exit 1
  fi
fi

echo "Fetching OpenClaw docs for version: $NEW_VERSION"

if [ -f "$INDEX_FILE" ]; then
  echo "Found existing index, refreshing docs..."

  python3 -c "
import json, subprocess, sys, os, datetime

with open('$INDEX_FILE') as f:
    index = json.load(f)

updated = 0
failed = 0
skipped = 0

for doc in index.get('docs', []):
    url = doc['source_url']
    filepath = os.path.join('$DOCS_DIR', doc['file'])
    os.makedirs(os.path.dirname(filepath), exist_ok=True)

    html_tmp = os.path.join('$TMP_DIR', os.path.basename(doc['file']) + '.html')
    result = subprocess.run(['curl', '-sL', '--max-time', '30', url],
                          capture_output=True, text=True)
    if result.returncode != 0:
        print(f'FAIL: {url}')
        failed += 1
        continue

    with open(html_tmp, 'w') as f:
        f.write(result.stdout)

    import re
    content = result.stdout
    content = re.sub(r'<script[^>]*>.*?</script>', '', content, flags=re.DOTALL)
    content = re.sub(r'<style[^>]*>.*?</style>', '', content, flags=re.DOTALL)
    content = re.sub(r'<[^>]+>', ' ', content)
    content = re.sub(r'\s+', ' ', content).strip()

    with open(filepath, 'w') as f:
        f.write(f'# {doc.get(\"title\", os.path.basename(doc[\"file\"]))}\n\n')
        f.write(f'> Source: {url}\n')
        f.write(f'> Fetched: {datetime.datetime.utcnow().strftime(\"%Y-%m-%dT%H:%M:%SZ\")}\n\n')
        f.write(content[:50000])

    doc['fetched_at'] = datetime.datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')
    updated += 1
    print(f'OK: {doc[\"file\"]}')

index['version'] = '$NEW_VERSION'
index['updated_at'] = datetime.datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')

with open('$INDEX_FILE', 'w') as f:
    json.dump(index, f, indent=2, ensure_ascii=False)

print(f'\\nSummary: {updated} updated, {failed} failed, {skipped} skipped')
"
else
  echo "No index file found at $INDEX_FILE"
  echo "Run knowledge base initialization first (Task 12)"
  exit 1
fi

echo "Docs fetch complete"
