#!/usr/bin/env bash

set -euo pipefail

SHADOW_PATH="${XDG_CONFIG_HOME:-$HOME/.config}/git/dev/shadow-repo"

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --path) SHADOW_PATH="$2"; shift 2 ;;
        *) echo "Warning: Unknown option for sync-activity hook setup: $1" >&2; shift ;;
    esac
done

echo "Setting up shadow repo at $SHADOW_PATH..."

# Configure path securely
CURRENT_PATH=$(git config hooks.syncactivity.path || git config --global hooks.syncactivity.path || echo "")

if [ "$CURRENT_PATH" != "$SHADOW_PATH" ]; then
    git config hooks.syncactivity.path "$SHADOW_PATH" || git config --global hooks.syncactivity.path "$SHADOW_PATH"
    echo "Configured shadow repo path to $SHADOW_PATH"
fi

if [ ! -d "$SHADOW_PATH" ]; then
    mkdir -p "$SHADOW_PATH"
    echo "Created shadow repo directory at $SHADOW_PATH"
fi

if [ ! -d "$SHADOW_PATH/.git" ]; then
    pushd "$SHADOW_PATH" > /dev/null
    git init
    echo "Initialized git repository in $SHADOW_PATH"
    popd > /dev/null
else
    echo "Shadow repo at $SHADOW_PATH is already a git repository. Skipping init."
fi

exit 0