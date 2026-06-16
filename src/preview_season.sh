#!/usr/bin/env bash
# Preview script for season selection.
# Called by fzf: --preview='bash preview_season.sh {1}'
# Expects env var: VIDEO_EXTS

S_PATH="$1"
SERIES_NAME=$(basename "$(dirname "$S_PATH")")
FILES=$(find "$S_PATH" -type f 2>/dev/null | grep -iE "\.(${VIDEO_EXTS})$" | sort)
COUNT=$(echo "$FILES" | grep -c .)

ALL_TEXT=$(printf "SERIES: %s\n" "$SERIES_NAME")
ALL_TEXT=$(printf "%s\nSEASON: %s\n====================================\nEpisodes: %s" "$ALL_TEXT" "$(basename "$S_PATH")" "$COUNT")

# Avg duration from first 10 episodes
TOTAL_SEC=0
SAMPLES=0
while read -r f; do
    [ -z "$f" ] && continue
    D=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$f" 2>/dev/null)
    [ -z "$D" ] && continue
    TOTAL_SEC=$((TOTAL_SEC + ${D%.*}))
    SAMPLES=$((SAMPLES + 1))
    [ $SAMPLES -ge 10 ] && break
done <<EOF
$FILES
EOF

if [ $SAMPLES -gt 0 ]; then
    AVG=$((TOTAL_SEC / SAMPLES))
    ALL_TEXT=$(printf "%s\nAvg. Ep:  %02d:%02d:%02d" "$ALL_TEXT" $((AVG/3600)) $((AVG%3600/60)) $((AVG%60)))
fi
ALL_TEXT=$(printf "%s\n====================================\n%s" "$ALL_TEXT" "$(echo "$FILES" | sed "s|$S_PATH/||" | head -n 15)")

# Fetch internet metadata to get poster
POSTER=""
if [ -n "$CLIENT_PATH" ] && [ -f "$CLIENT_PATH" ]; then
    OUT=$(python3 "$CLIENT_PATH" "series" "$SERIES_NAME")
    POSTER=$(echo "$OUT" | grep "__POSTER_PATH__" | cut -d":" -f2-)
fi

# Render poster and text
source "$(dirname "$0")/render_poster.sh"
