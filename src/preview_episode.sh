#!/usr/bin/env bash
# Preview script for episode selection.
# Called by fzf: --preview='bash preview_episode.sh {1}'

FILE_PATH="$1"
SEASON_NAME=$(basename "$(dirname "$FILE_PATH")")

printf "SEASON:  %s\n" "$SEASON_NAME"
printf "EPISODE: %s\n" "$(basename "$FILE_PATH")"
printf "====================================\n"

DURATION=$(ffprobe -v error -sexagesimal -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$FILE_PATH" 2>/dev/null)
printf "Duration: %s\n" "${DURATION%.*}"

RES=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "$FILE_PATH" 2>/dev/null)
printf "Res:      %s\n" "$RES"
