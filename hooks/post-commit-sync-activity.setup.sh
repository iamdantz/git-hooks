#!/usr/bin/env bash

set -euo pipefail

SHADOW_PATH="${XDG_CONFIG_HOME:-$HOME/.config}/git/dev/shadow-repo"
REMOTE_URL=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --path) SHADOW_PATH="$2"; shift 2 ;;
        --remote) REMOTE_URL="$2"; shift 2 ;;
        *) echo "Warning: Unknown option for sync-activity hook setup: $1" >&2; shift ;;
    esac
done

echo "Setting up shadow repo at $SHADOW_PATH..."

# Configure path securely
CURRENT_PATH=$(git config hooks.syncactivity.path || git config --global hooks.syncactivity.path || echo "")

if [ "$CURRENT_PATH" != "$SHADOW_PATH" ]; then
    git config hooks.syncactivity.path "$SHADOW_PATH" || git config --global hooks.syncactivity.path "$SHADOW_PATH"
fi

if [ ! -d "$SHADOW_PATH" ]; then
    mkdir -p "$SHADOW_PATH"
fi

if [ ! -d "$SHADOW_PATH/.git" ]; then
    pushd "$SHADOW_PATH" > /dev/null
    git init -b main
    echo "Initialized git repository in $SHADOW_PATH"
    
    if [ -n "$REMOTE_URL" ]; then
        git remote add origin "$REMOTE_URL"
        echo "Configured remote origin: $REMOTE_URL"
    else
        echo -e "\n\033[0;31mACTION REQUIRED: No --remote provided. You MUST manually add an 'origin' remote to $SHADOW_PATH before the hook can push.\033[0m\n"
    fi
    popd > /dev/null
fi

exit 0