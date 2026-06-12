#!/bin/bash
# Toggle watched status for a file or directory.
# Usage: toggle_watched.sh WATCHED_FILE TARGET_PATH
WATCHED_FILE="$1"
TARGET="$2"

# Touch file to ensure it exists
touch "$WATCHED_FILE"

if [ -f "$TARGET" ]; then
    if grep -Fxq "$TARGET" "$WATCHED_FILE"; then
        grep -Fxv "$TARGET" "$WATCHED_FILE" > "${WATCHED_FILE}.tmp" && mv "${WATCHED_FILE}.tmp" "$WATCHED_FILE"
    else
        echo "$TARGET" >> "$WATCHED_FILE"
    fi
elif [ -d "$TARGET" ]; then
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    python3 "$SCRIPT_DIR/toggle_watched.py" "$WATCHED_FILE" "$TARGET"
fi
