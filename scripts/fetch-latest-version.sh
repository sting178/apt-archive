#!/bin/bash
set -e

REPO="$1"
MAJOR="$2"

# Ensure APT_GITHUB_TOKEN is set
if [ -z "$APT_GITHUB_TOKEN" ]; then
  echo "Error: No APT_GITHUB_TOKEN nor GH_PAT is set. Please set one in your Codespaces environment."
  exit 1
fi

TAGS=$(curl -s \
  -H "Authorization: Bearer ${APT_GITHUB_TOKEN}" \
  "https://api.github.com/repos/$REPO/releases" | jq -r '.[].tag_name')
FILTERED=$(echo "$TAGS" | grep -E '^v?[0-9]+\.[0-9]+\.[0-9]+$')
[ -n "$MAJOR" ] && FILTERED=$(echo "$FILTERED" | grep -E "^v?$MAJOR\.")
LATEST=$(echo "$FILTERED" | sed 's/^v//' | sort -V | tail -n 1)

if [ -z "$LATEST" ]; then
  echo "No matching release for $REPO with major $MAJOR" >&2
  exit 1
fi

echo "$LATEST"
