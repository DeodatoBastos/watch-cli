#!/usr/bin/env bash
# Preview script for season selection.
# Called by fzf: --preview='bash preview_season.sh {1}'
# Expects env var: VIDEO_EXTS

S_PATH="$1"
SERIES_NAME=$(basename "$(dirname "$S_PATH")")
FILES=$(find "$S_PATH" -type f 2>/dev/null | grep -iE "\.(${VIDEO_EXTS})$" | sort)
COUNT=$(echo "$FILES" | grep -c .)

printf "SERIES: %s\n" "$SERIES_NAME"
printf "SEASON: %s\n" "$(basename "$S_PATH")"
printf "====================================\n"
printf "Episodes: %s\n" "$COUNT"

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
    printf "Avg. Ep:  %02d:%02d:%02d\n" $((AVG/3600)) $((AVG%3600/60)) $((AVG%60))
fi
printf "====================================\n"
echo "$FILES" | sed "s|$S_PATH/||" | head -n 15
