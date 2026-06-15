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
if [ -n "$POSTER" ] && [ "$IS_KITTY" = "true" ]; then
    # Clear previous images from Kitty memory
    printf "\x1b_Ga=d,d=A\x1b\\\\" > /dev/tty

    IMAGE_HEIGHT=$(( FZF_PREVIEW_LINES - 1 ))
    [ "$IMAGE_HEIGHT" -lt 5 ] && IMAGE_HEIGHT=5

    # Width from 2:3 poster aspect ratio and 1:2 terminal cell ratio: cols = lines * 4/3
    POSTER_WIDTH=$(( IMAGE_HEIGHT * 4 / 3 ))

    # Cap to 50% of preview pane
    MAX_WIDTH=$(( FZF_PREVIEW_COLUMNS * 50 / 100 ))
    if [ "$POSTER_WIDTH" -gt "$MAX_WIDTH" ]; then
        POSTER_WIDTH=$MAX_WIDTH
        IMAGE_HEIGHT=$(( POSTER_WIDTH * 3 / 4 ))
    fi

    GAP=3
    TEXT_WIDTH=$(( FZF_PREVIEW_COLUMNS - POSTER_WIDTH - GAP ))

    ESC=$(printf "\033")
    TEXT_PLAIN=$(echo "$ALL_TEXT" | sed "s/${ESC}\[[0-9;]*m//g")
    TEXT_WRAPPED=$(echo "$TEXT_PLAIN" | fold -s -w "$TEXT_WIDTH")

    printf "${ESC}_Ga=d,d=A${ESC}\\\\" > /dev/tty

    # Calculate exact pixel bounds (10x20 cell) to prevent icat aspect ratio distortion
    WPX=$(( POSTER_WIDTH * 10 ))
    HPX=$(( IMAGE_HEIGHT * 20 ))
    RAW_ART=$(kitty +kitten icat --align left --silent --stdin no --transfer-mode memory --unicode-placeholder --use-window-size "${POSTER_WIDTH},${IMAGE_HEIGHT},${WPX},${HPX}" "$POSTER" 2>/dev/null | tr -d "\\r")

    # Send APC sequence directly to terminal (bypassing fzf)
    APC_SEQ=$(echo "$RAW_ART" | grep -o "${ESC}_G.*${ESC}\\\\")
    printf "%s" "$APC_SEQ" > /dev/tty

    # Strip APC so fzf only sees unicode placeholders
    POSTER_ART=$(echo "$RAW_ART" | sed "s/${ESC}_G.*${ESC}\\\\//")
    IMG_COLOR=$(echo "$POSTER_ART" | grep -o -m 1 "^${ESC}\[[0-9;:]*m")

    GAP_STR=$(printf "%${GAP}s" "")
    POSTER_PAD=$(printf "%-${POSTER_WIDTH}s" "")

    POSTER_N=$(echo "$POSTER_ART" | wc -l)
    TEXT_N=$(echo "$TEXT_WRAPPED" | wc -l)
    MAX_N=$POSTER_N
    [ "$TEXT_N" -gt "$MAX_N" ] && MAX_N=$TEXT_N

    # Merge columns line by line
    i=1
    while [ "$i" -le "$MAX_N" ]; do
        if [ "$i" -le "$POSTER_N" ]; then
            P=$(echo "$POSTER_ART" | sed -n "${i}p")
            P="${IMG_COLOR}${P}"
            # Pad poster line to POSTER_WIDTH for alignment
            P_STRIPPED=$(echo "$P" | sed "s/${ESC}\[[0-9;:]*m//g")
            P_LEN=${#P_STRIPPED}
            PAD_LEN=$(( POSTER_WIDTH - P_LEN ))
            if [ "$PAD_LEN" -gt 0 ]; then
                PAD_SPACES=$(printf "%${PAD_LEN}s" "")
                P="${P}${PAD_SPACES}"
            fi
        else
            P="$POSTER_PAD"
        fi

        if [ "$i" -le "$TEXT_N" ]; then
            T=$(echo "$TEXT_WRAPPED" | sed -n "${i}p")
        else
            T=""
        fi
        printf "%s%s\033[97m%s\033[0m\n" "$P" "$GAP_STR" "$T"
        i=$((i + 1))
    done
else
    # Single-column fallback
    ESC=$(printf "\033")
    TEXT_PLAIN=$(echo "$ALL_TEXT" | sed "s/${ESC}\[[0-9;]*m//g")
    echo "$TEXT_PLAIN" | sed "s/^/\033[97m/; s/$/\033[0m/"
fi
