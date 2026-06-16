#!/usr/bin/env bash
# Preview script for the main movie/series selection menu.
# Called by fzf: --preview='bash preview.sh {1}'
# Expects env vars: CLIENT_PATH, IS_KITTY, VIDEO_EXTS

ITEM="$1"

# Clear any previously drawn Kitty graphics
printf "\x1b_Ga=d,d=A\x1b\\"

# --- Detect media type and resolve file path ---
TYPE="movie"
FILE_PATH=""
SHOW_LOCAL_INFO=false

if [ -d "$ITEM" ]; then
    FILES=$(find "$ITEM" -type f 2>/dev/null | grep -iE "\.(${VIDEO_EXTS})$" | sort)
    TOTAL_EPS=$(echo "$FILES" | grep -c .)
    if [ "$TOTAL_EPS" -gt 1 ]; then
        TYPE="series"
    elif [ "$TOTAL_EPS" -eq 1 ]; then
        FILE_PATH=$(echo "$FILES" | head -n 1)
        SHOW_LOCAL_INFO=true
    fi
else
    FILE_PATH="$ITEM"
    SHOW_LOCAL_INFO=true
fi

# --- Extract local metadata via ffprobe ---
LOCAL_TEXT=""
if [ "$SHOW_LOCAL_INFO" = true ] && [ -n "$FILE_PATH" ]; then
    DURATION=$(ffprobe -v error -sexagesimal -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$FILE_PATH" 2>/dev/null)
    RES=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "$FILE_PATH" 2>/dev/null)
    CODEC=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$FILE_PATH" 2>/dev/null)
    LOCAL_TEXT=$(printf "====================================\nFile:     %s\nDuration: %s\nRes:      %s\nCodec:    %s" "$(basename "$FILE_PATH")" "${DURATION%.*}" "$RES" "$CODEC")
fi

# --- Fetch internet metadata ---
TEXT_HEADER=""
POSTER=""
if [ -f "$CLIENT_PATH" ]; then
    OUT=$(python3 "$CLIENT_PATH" "$TYPE" "$(basename "$ITEM")")
    TEXT_HEADER=$(echo "$OUT" | grep -v "__POSTER_PATH__")
    POSTER=$(echo "$OUT" | grep "__POSTER_PATH__" | cut -d":" -f2-)
fi

# --- Assemble all text ---
ALL_TEXT=""
[ -n "$TEXT_HEADER" ] && ALL_TEXT="$TEXT_HEADER"

if [ "$TYPE" = "movie" ] && [ -n "$LOCAL_TEXT" ]; then
    if [ -n "$ALL_TEXT" ]; then
        ALL_TEXT=$(printf "%s\n%s" "$ALL_TEXT" "$LOCAL_TEXT")
    else
        ALL_TEXT="$LOCAL_TEXT"
    fi
elif [ "$TYPE" = "series" ]; then
    SEASONS=$(find "$ITEM" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | grep -c .)
    SERIES_LOCAL_TEXT=$(printf "====================================\nLocal Seasons:  %s\nLocal Episodes: %s\n====================================\n" "$SEASONS" "$TOTAL_EPS")
    if [ "$SEASONS" -gt 0 ]; then
        SERIES_LOCAL_TEXT=$(printf "%s\n%s" "$SERIES_LOCAL_TEXT" "$(find "$ITEM" -maxdepth 1 -mindepth 1 -type d | sed "s|$ITEM/||" | sort)")
    else
        SERIES_LOCAL_TEXT=$(printf "%s\n%s" "$SERIES_LOCAL_TEXT" "$(echo "$FILES" | sed "s|$ITEM/||" | head -n 10)")
        [ "$TOTAL_EPS" -gt 10 ] && SERIES_LOCAL_TEXT=$(printf "%s\n..." "$SERIES_LOCAL_TEXT")
    fi

    if [ -n "$ALL_TEXT" ]; then
        ALL_TEXT=$(printf "%s\n%s" "$ALL_TEXT" "$SERIES_LOCAL_TEXT")
    else
        ALL_TEXT="$SERIES_LOCAL_TEXT"
    fi
fi

# --- Render: two-column poster+text (Kitty) or plain text fallback ---
source "$(dirname "$0")/render_poster.sh"
