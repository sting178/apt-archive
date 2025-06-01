#!/bin/bash
set -e

REPO="$1"
MAJOR="$2"

TAGS=$(curl -s "https://api.github.com/repos/$REPO/releases" | jq -r '.[].tag_name')
FILTERED=$(echo "$TAGS" | grep -E '^v?[0-9]+\.[0-9]+\.[0-9]+$')
[ -n "$MAJOR" ] && FILTERED=$(echo "$FILTERED" | grep -E "^v?$MAJOR\.")
LATEST=$(echo "$FILTERED" | sed 's/^v//' | sort -V | tail -n 1)

if [ -z "$LATEST" ]; then
  echo "No matching release for $REPO with major $MAJOR" >&2
  exit 1
fi

echo "$LATEST"
