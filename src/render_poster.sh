#!/usr/bin/env bash

# --- Render: two-column poster+text (Kitty) or plain text fallback ---
# Expects: POSTER (path to image), ALL_TEXT (text to display), IS_KITTY (true/false)

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
