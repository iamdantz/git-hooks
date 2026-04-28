#!/bin/bash

set -euo pipefail

SHADOW_REPO_PATH="${XDG_CONFIG_HOME:-$HOME/.config}/git/dev/shadow-repo"
ACTIVITY_FILE="activity.log"

if git remote -v | grep -q "github.com"; then
    exit 0
fi

if [ ! -d "$SHADOW_REPO_PATH" ]; then
    echo "Error: Shadow repo path not found." >&2
    exit 1
fi

COMMIT_HASH=$(git rev-parse --short HEAD)
TIMESTAMP=$(date -u +'%Y-%m-%dT%H:%M:%SZ')

pushd "$SHADOW_REPO_PATH" > /dev/null
    echo "$TIMESTAMP | External Activity | Ref: $COMMIT_HASH" >> "$ACTIVITY_FILE"
    
    git add "$ACTIVITY_FILE"
    git commit --no-verify -m "Sync activity: $TIMESTAMP"
    git push origin main
popd > /dev/null