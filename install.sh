#!/usr/bin/env bash
set -euo pipefail

SCOPE="--local"
VERSIONING=false
HOOK_FILE=""
HOOK_ARGS=()
REPO_URL=${GIT_HOOKS_REPO:-"https://raw.githubusercontent.com/iamdantz/git-hooks/main"}

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --global) SCOPE="--global"; shift ;;
        --local) SCOPE="--local"; shift ;;
        --versioning|--version-enabled|versioning=true|-v) VERSIONING=true; shift ;;
        -*) echo "Error: Unknown parameter passed: $1" >&2; exit 1 ;;
        *) 
            HOOK_FILE="$1"
            shift
            HOOK_ARGS=("$@")
            break
            ;;
    esac
done

if [ -z "$HOOK_FILE" ]; then
    echo "Error: Target hook file required." >&2
    echo "Usage: $0 [--local|--global] [--versioning] <hook-file>" >&2
    exit 1
fi

HOOK_TYPE=$(echo "$HOOK_FILE" | grep -oE '^(pre|post|prepare|commit|update|applypatch|fsmonitor)-[a-z]+' || echo "$HOOK_FILE" | cut -d'-' -f1-2)

if [ "$SCOPE" == "--local" ]; then
    if [ ! -d ".git" ]; then
        echo "Error: Not a git repository. '.git' directory not found." >&2
        exit 1
    fi
    
    if [ "$VERSIONING" = true ]; then
        DEST_BASE=".githooks"
    else
        DEST_BASE=".git/hooks"
    fi
    
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

    if [ "$tmp_file" != "$dest" ]; then
        mkdir -p "$(dirname "$dest")"
        mv "$tmp_file" "$dest"
    fi
    chmod +x "$dest"
    rm -f "$tmp_sums"
}

TARGET_DIR="$DEST_BASE/${HOOK_TYPE}.d"

verify_and_install "$REPO_URL/hooks/$HOOK_FILE" "$TARGET_DIR/$HOOK_FILE"
verify_and_install "$REPO_URL/core/dispatcher.sh" "$DISPATCHER_PATH"

setup_filename="${HOOK_FILE%.sh}.setup.sh"
tmp_sums="/tmp/checksums_$$"
curl -fsSL "$REPO_URL/checksums.sha256" -o "$tmp_sums"
if grep -q "$setup_filename" "$tmp_sums"; then
    echo "Found setup script for $HOOK_FILE. Running post-install..."
    SETUP_DEST="/tmp/${setup_filename}_$$"
    verify_and_install "$REPO_URL/hooks/$setup_filename" "$SETUP_DEST"
    "$SETUP_DEST" "${HOOK_ARGS[@]}" || {
        echo "Error: Post-install setup failed for $HOOK_FILE." >&2
        rm -f "$SETUP_DEST" "$tmp_sums"
        exit 1
    }
    rm -f "$SETUP_DEST"
fi
rm -f "$tmp_sums"

echo "Hook $HOOK_FILE installed successfully in $DEST_BASE."