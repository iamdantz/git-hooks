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

git config hooks.syncactivity.path "$SHADOW_PATH" || git config --global hooks.syncactivity.path "$SHADOW_PATH"

if [ ! -d "$SHADOW_PATH" ]; then
    mkdir -p "$SHADOW_PATH"
    echo "Created shadow repo directory at $SHADOW_PATH"
fi

if [ ! -d "$SHADOW_PATH/.git" ]; then
    pushd "$SHADOW_PATH" > /dev/null
    git init
    echo "Initialized git repository in $SHADOW_PATH"
    popd > /dev/null
fi

exit 0