#!/bin/bash
# Generated for Wallust — updates Starship palette in-place

STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
COLORS_FILE="$HOME/.config/starship/colors.toml"

if [[ ! -f "$COLORS_FILE" ]]; then
    exit 0
fi

PALETTE_CONTENT=$(cat "$COLORS_FILE")
LINE_NUM=$(grep -n '^\[palettes\.wallust\]' "$STARSHIP_CONFIG" | head -1 | cut -d: -f1)

if [[ -n "$LINE_NUM" ]]; then
    head -n $((LINE_NUM - 1)) "$STARSHIP_CONFIG" > "${STARSHIP_CONFIG}.tmp"
    echo "" >> "${STARSHIP_CONFIG}.tmp"
    cat "$COLORS_FILE" >> "${STARSHIP_CONFIG}.tmp"
    echo "" >> "${STARSHIP_CONFIG}.tmp"
    mv "${STARSHIP_CONFIG}.tmp" "$STARSHIP_CONFIG"
fi
