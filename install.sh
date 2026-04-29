#!/usr/bin/env bash
set -euo pipefail

SCOPE="--local"
VERSIONING=false
RECURSIVE=false
HOOK_FILE=""
HOOK_ARGS=()
REPO_URL=${GIT_HOOKS_REPO:-"https://raw.githubusercontent.com/iamdantz/git-hooks/main"}

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --global) SCOPE="--global"; shift ;;
        --local) SCOPE="--local"; shift ;;
        --versioning|--version-enabled|versioning=true|-v) VERSIONING=true; shift ;;
        -R|--recursive) RECURSIVE=true; shift ;;
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
    echo "Usage: $0 [--local|--global] [--versioning] [-R|--recursive] <hook-file>" >&2
    exit 1
fi

HOOK_TYPE=$(echo "$HOOK_FILE" | grep -oE '^(pre|post|prepare|commit|update|applypatch|fsmonitor)-[a-z]+' || echo "$HOOK_FILE" | cut -d'-' -f1-2)

TARGET_REPOS=()

if [ "$SCOPE" == "--local" ]; then
    if [ "$RECURSIVE" = true ]; then
        # Find 1st level subdirectories that are valid git repos
        for d in */.git/; do
            if [ -d "$d" ]; then
                TARGET_REPOS+=("$(dirname "$d")")
            fi
        done
        if [ ${#TARGET_REPOS[@]} -eq 0 ]; then
            echo "Error: No first-level git repositories found." >&2
            exit 1
        fi
    else
        if [ ! -d ".git" ]; then
            echo "Error: Not a git repository. '.git' directory not found." >&2
            exit 1
        fi
        TARGET_REPOS+=(".")
    fi
else
    # Global scope ignores recursion logic
    TARGET_REPOS+=("GLOBAL")
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

# 1. Download to staging area first to prevent repeated calls over network in recursive mode
STAGING_DIR="/tmp/git-hooks-staging_$$"
mkdir -p "$STAGING_DIR"

verify_and_install "$REPO_URL/hooks/$HOOK_FILE" "$STAGING_DIR/$HOOK_FILE"
verify_and_install "$REPO_URL/core/dispatcher.sh" "$STAGING_DIR/dispatcher.sh"

setup_filename="${HOOK_FILE%.sh}.setup.sh"
HAS_SETUP=false
tmp_sums="/tmp/checksums_$$"
curl -fsSL "$REPO_URL/checksums.sha256" -o "$tmp_sums"
if grep -q "$setup_filename" "$tmp_sums"; then
    verify_and_install "$REPO_URL/hooks/$setup_filename" "$STAGING_DIR/$setup_filename"
    HAS_SETUP=true
fi
rm -f "$tmp_sums"

# 2. Iterate and deploy
for repo in "${TARGET_REPOS[@]}"; do
    if [ "$repo" == "GLOBAL" ]; then
        DEST_BASE="${XDG_CONFIG_HOME:-$HOME/.config}/git/hooks"
        DISPATCHER_PATH="$DEST_BASE/$HOOK_TYPE"
        git config --global core.hooksPath "$DEST_BASE"
        echo "Installing $HOOK_FILE globally in $DEST_BASE..."
    else
        echo "Installing $HOOK_FILE in $repo..."
        if [ "$VERSIONING" = true ]; then
            DEST_BASE="$repo/.githooks"
        else
            DEST_BASE="$repo/.git/hooks"
        fi
        DISPATCHER_PATH="$repo/.git/hooks/$HOOK_TYPE"
    fi

    TARGET_DIR="$DEST_BASE/${HOOK_TYPE}.d"
    
    mkdir -p "$TARGET_DIR" "$(dirname "$DISPATCHER_PATH")"
    cp "$STAGING_DIR/$HOOK_FILE" "$TARGET_DIR/$HOOK_FILE"
    cp "$STAGING_DIR/dispatcher.sh" "$DISPATCHER_PATH"

    if [ "$HAS_SETUP" = true ]; then
        if [ "$repo" != "GLOBAL" ] && [ "$repo" != "." ]; then
            pushd "$repo" > /dev/null
        fi
        
        "$STAGING_DIR/$setup_filename" "${HOOK_ARGS[@]}" || {
            echo "Error: Post-install setup failed for $HOOK_FILE in $repo." >&2
            if [ "$repo" != "GLOBAL" ] && [ "$repo" != "." ]; then popd > /dev/null; fi
            rm -rf "$STAGING_DIR"
            exit 1
        }
        
        if [ "$repo" != "GLOBAL" ] && [ "$repo" != "." ]; then
            popd > /dev/null
        fi
    fi
    echo "Hook $HOOK_FILE installed successfully in $DEST_BASE."
    echo "--------------------------------------------------------"
done

rm -rf "$STAGING_DIR"
