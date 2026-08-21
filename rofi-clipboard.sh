#!/usr/bin/env bash

CACHE_DIR="$HOME/.cache/cliphist-preview"
mkdir -p "$CACHE_DIR"

shopt -s nocasematch

MAX_ITEMS=100

# ============================================================
# Load clipboard history
# ============================================================

readarray -t LINES < <(cliphist list)

if (( ${#LINES[@]} > MAX_ITEMS )); then
    LINES=("${LINES[@]:0:$MAX_ITEMS}")
fi

declare -a DISPLAY=()
declare -a ICONPATH=()
declare -A MAP=()
declare -A SEEN=()

IMG_BIN_RE='binary data.* (png|jpe?g|webp|gif|bmp|svg|tiff|ico)'
IMG_FILE_RE='\.(png|jpe?g|webp|gif|bmp|svg)$'

# ============================================================
# Build clipboard entries
# ============================================================

for LINE in "${LINES[@]}"; do
    ID="${LINE%%$'\t'*}"
    REST="${LINE#*$'\t'}"

    SEEN["$ID"]=1

    ICON=""
    IS_IMAGE=0

    if [[ "$REST" =~ $IMG_BIN_RE ]]; then
        IS_IMAGE=1

        for CF in "$CACHE_DIR/$ID".*; do
            [[ -e "$CF" ]] && {
                ICON="$CF"
                break
            }
        done

        if [[ -z "$ICON" ]]; then
            PNG_FILE="$CACHE_DIR/$ID.png"

            echo "$LINE" |
                cliphist decode > "$PNG_FILE" 2>/dev/null

            ICON="$PNG_FILE"
        fi

    elif [[ -f "$REST" && "$REST" =~ $IMG_FILE_RE ]]; then
        IS_IMAGE=1
        ICON="$REST"
    fi

    if (( IS_IMAGE )); then
        DISPLAY+=("    Image!")
    else
        DISPLAY+=("$REST")
    fi

    MAP["${#DISPLAY[@]}"]="$LINE"
    ICONPATH+=("$ICON")
done

# ============================================================
# Clean old image cache
# ============================================================

CLEAN_INTERVAL=3600
LAST_CLEAN="$CACHE_DIR/.last_clean"

if [[ ! -f "$LAST_CLEAN" ]] ||
   (( $(date +%s) - $(stat -c %Y "$LAST_CLEAN" 2>/dev/null || echo 0) > CLEAN_INTERVAL )); then

    for F in "$CACHE_DIR"/*; do
        [[ -e "$F" ]] || continue

        B="${F##*/}"
        IDX="${B%%.*}"

        [[ -z "${SEEN[$IDX]+x}" ]] && rm -f "$F"
    done

    touch "$LAST_CLEAN"
fi

# ============================================================
# Empty history
# ============================================================

if (( ${#DISPLAY[@]} == 0 )); then
    echo "    Clipboard history is empty!" |
        rofi -dmenu \
            -i \
            -p " Clipboard" \
            -l 3 \
            -markup-rows

    exit 0
fi

# ============================================================
# Rofi clipboard menu
# ============================================================

CLEAR_BTN="<span foreground='#c90000' weight='black'> 󰃢  [ Clear All History ] 󰃢 </span>"

SELECTED=$(
    {
        echo "$CLEAR_BTN"

        for I in "${!DISPLAY[@]}"; do
            if [[ -n "${ICONPATH[$I]}" && -f "${ICONPATH[$I]}" ]]; then
                printf '%s\0icon\037%s\n' \
                    "${DISPLAY[$I]}" \
                    "${ICONPATH[$I]}"
            else
                printf '%s\n' "${DISPLAY[$I]}"
            fi
        done

    } |
    rofi -dmenu \
        -show-icons \
        -p '    Clipboard' \
        -i \
        -markup-rows \
        -format i \
        -lines 15 \
        -levenshtein-sort
)

EXIT_CODE=$?

# ESC
if [[ $EXIT_CODE -ne 0 || -z "$SELECTED" ]]; then
    exit 0
fi

# ============================================================
# Clear All
# ============================================================

if [[ "$SELECTED" -eq 0 ]]; then

    cliphist wipe

    rm -f "$CACHE_DIR"/*

    exit 0
fi

# ============================================================
# Selected clipboard entry
# ============================================================

REAL_INDEX="$SELECTED"
ORIG_LINE="${MAP[$REAL_INDEX]}"

if [[ -z "$ORIG_LINE" ]]; then
    exit 0
fi

ID="${ORIG_LINE%%$'\t'*}"
CONTENT="${ORIG_LINE#*$'\t'}"

ICON="${ICONPATH[$((REAL_INDEX - 1))]}"

# Detect image
IS_IMAGE=0

if [[ "$CONTENT" =~ $IMG_BIN_RE ]]; then
    IS_IMAGE=1
elif [[ -f "$CONTENT" && "$CONTENT" =~ $IMG_FILE_RE ]]; then
    IS_IMAGE=1
fi

# ============================================================
# Detail
# ============================================================

if (( IS_IMAGE )); then

    TYPE="Image"
    TYPE_ICON=""

    detail_text=" <span foreground='#89b4fa'><b>Source:</b></span> <span foreground='#ffffff'><b>Clipboard</b></span> | $TYPE_ICON <span foreground='#f9e2af'><b>Type:</b></span> <span foreground='#ffffff'><b>$TYPE</b></span>
----------------------------------------
 <span foreground='#a6e3a1'><b>Content:</b></span>
<span foreground='#cdd6f4'>Image data</span>
"

else

    TYPE="Text"
    TYPE_ICON="󰊄"

    # Escape text for Pango markup
    ESCAPED_CONTENT="$CONTENT"

    ESCAPED_CONTENT="${ESCAPED_CONTENT//&/&amp;}"
    ESCAPED_CONTENT="${ESCAPED_CONTENT//</&lt;}"
    ESCAPED_CONTENT="${ESCAPED_CONTENT//>/&gt;}"

    detail_text=" <span foreground='#89b4fa'><b>Source:</b></span> <span foreground='#ffffff'><b>Clipboard</b></span> | $TYPE_ICON <span foreground='#f9e2af'><b>Type:</b></span> <span foreground='#ffffff'><b>$TYPE</b></span>
----------------------------------------
 <span foreground='#a6e3a1'><b>Content:</b></span>
<span foreground='#cdd6f4'>$ESCAPED_CONTENT</span>"

fi

# ============================================================
# Show detail box
# ============================================================

rofi -e "$detail_text" -markup

# ============================================================
# Actions
# ============================================================

action=$(
    echo -e "󱐋   Copy\n   Remove\n   Back" |
        rofi -dmenu \
            -i \
            -p "Action" \
            -l 3
)

case "$action" in

    "󱐋   Copy")

        echo "$ORIG_LINE" |
            cliphist decode |
            wl-copy

        exit 0
        ;;

    "   Remove")

        if printf '%s\n' "$ORIG_LINE" |
            cliphist delete 2>/dev/null; then

            true

        else

            true

        fi

        sleep 0.2
        exec "$0"

        ;;

    "   Back")
        exec "$0"
        ;;

esac

exec "$0"
