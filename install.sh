#!/usr/bin/env bash
set -euo pipefail

SCOPE=${1:-"--global"}
HOOK_FILE=${2:-""}
REPO_URL=${GIT_HOOKS_REPO:-"https://raw.githubusercontent.com/iamdantz/git-hooks/main"}

if [ -z "$HOOK_FILE" ]; then
    echo "Error: Target hook file required." >&2
    exit 1
fi

HOOK_TYPE=$(echo "$HOOK_FILE" | grep -oE '^(pre|post|prepare|commit|update|applypatch|fsmonitor)-[a-z]+' || echo "$HOOK_FILE" | cut -d'-' -f1-2)

if [ "$SCOPE" == "--local" ]; then
    if [ ! -d ".git" ]; then
        exit 1
    fi
    DEST_BASE=".githooks"
    DISPATCHER_PATH=".git/hooks/$HOOK_TYPE"
else
    DEST_BASE="${XDG_CONFIG_HOME:-$HOME/.config}/git/hooks"
    DISPATCHER_PATH="$DEST_BASE/$HOOK_TYPE"
    git config --global core.hooksPath "$DEST_BASE"
fi

verify_and_install() {
    local url="$1"
    local dest="$2"
    local filename
    filename=$(basename "$url")
    local tmp_file="/tmp/${filename}_$$"
    local tmp_sums="/tmp/checksums_$$"

    curl -fsSL "$url" -o "$tmp_file"
    curl -fsSL "$REPO_URL/checksums.sha256" -o "$tmp_sums"

    local expected_hash
    expected_hash=$(grep "$filename" "$tmp_sums" | awk '{print $1}' || echo "")

    if [ -z "$expected_hash" ]; then
        rm -f "$tmp_file" "$tmp_sums"
        echo "Security Error: No checksum found for $filename. Aborting." >&2
        exit 1
    fi

    local actual_hash
    if command -v sha256sum >/dev/null 2>&1; then
        actual_hash=$(sha256sum "$tmp_file" | awk '{print $1}')
    else
        actual_hash=$(shasum -a 256 "$tmp_file" | awk '{print $1}')
    fi

    if [ "$actual_hash" != "$expected_hash" ]; then
        rm -f "$tmp_file" "$tmp_sums"
        echo "SECURITY FATAL: SHA256 mismatch for $filename! Possible MITM or compromised repo." >&2
        exit 1
    fi

    mkdir -p "$(dirname "$dest")"
    mv "$tmp_file" "$dest"
    chmod +x "$dest"
    rm -f "$tmp_sums"
}

TARGET_DIR="$DEST_BASE/${HOOK_TYPE}.d"

verify_and_install "$REPO_URL/hooks/$HOOK_FILE" "$TARGET_DIR/$HOOK_FILE"
verify_and_install "$REPO_URL/core/dispatcher.sh" "$DISPATCHER_PATH"