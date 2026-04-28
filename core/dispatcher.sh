#!/usr/bin/env bash
set -euo pipefail

HOOK_NAME=$(basename "$0")
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")

GLOBAL_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/git/hooks/${HOOK_NAME}.d"
LOCAL_VERSIONED_DIR="$REPO_ROOT/.githooks/${HOOK_NAME}.d"
LOCAL_PRIVATE_DIR="$REPO_ROOT/.git/hooks/${HOOK_NAME}.d"

STDIN_DATA=""
if [ ! -t 0 ]; then
    STDIN_DATA=$(cat)
fi

execute_hooks() {
    local dir="$1"
    if [ -d "$dir" ]; then
        mapfile -t hooks < <(find "$dir" -maxdepth 1 -executable -type f | sort)
        for hook in "${hooks[@]}"; do
            if [ -n "$STDIN_DATA" ]; then
                echo "$STDIN_DATA" | "$hook" "$@"
            else
                "$hook" "$@"
            fi
        done
    fi
}

execute_hooks "$GLOBAL_DIR"
execute_hooks "$LOCAL_VERSIONED_DIR"
execute_hooks "$LOCAL_PRIVATE_DIR"