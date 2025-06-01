#!/bin/bash
set -e

echo "$GPG_PRIVATE_KEY" | base64 -d | gpg --import
