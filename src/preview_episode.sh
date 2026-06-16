#!/usr/bin/env bash
# Preview script for episode selection.
# Called by fzf: --preview='bash preview_episode.sh {1}'

FILE_PATH="$1"
SEASON_NAME=$(basename "$(dirname "$FILE_PATH")")

DURATION=$(ffprobe -v error -sexagesimal -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$FILE_PATH" 2>/dev/null)
RES=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "$FILE_PATH" 2>/dev/null)

ALL_TEXT=$(printf "SEASON:  %s\nEPISODE: %s\n====================================\nDuration: %s\nRes:      %s\n" "$SEASON_NAME" "$(basename "$FILE_PATH")" "${DURATION%.*}" "$RES")

# Fetch internet metadata to get poster
SERIES_NAME=$(basename "$(dirname "$(dirname "$FILE_PATH")")")
POSTER=""
if [ -n "$CLIENT_PATH" ] && [ -f "$CLIENT_PATH" ]; then
    OUT=$(python3 "$CLIENT_PATH" "series" "$SERIES_NAME")
    POSTER=$(echo "$OUT" | grep "__POSTER_PATH__" | cut -d":" -f2-)
fi

# Render poster and text
source "$(dirname "$0")/render_poster.sh"
