#!/bin/bash
# update-sddm.sh — Wallust hook'undan çağrılır, root yetkisiyle çalışır.
# Kullanım: sudo /home/safak/.config/wallust/scripts/update-sddm.sh <WALLPAPER_PATH>
#
# Yapılanlar:
#  1) Duvar kağıdını /usr/share/sddm/themes/sugar-dark/Background.jpg'a kopyala
#  2) /tmp/sddm-wallust-colors.conf'dan renkleri okuyup theme.conf'a yaz

set -euo pipefail

THEME_DIR="/usr/share/sddm/themes/sugar-dark"
THEME_CONF="$THEME_DIR/theme.conf"
COLORS_TMP="/tmp/sddm-wallust-colors.conf"
WALLPAPER="${1:-}"

# ── 1) Renk satırlarını oku ────────────────────────────────────────────────
if [[ ! -f "$COLORS_TMP" ]]; then
    echo "[update-sddm] Renk dosyası bulunamadı: $COLORS_TMP" >&2
    exit 1
fi

MAIN_COLOR=$(grep -oP '(?<=MainColor=")[^"]+' "$COLORS_TMP" || echo "#e0e4db")
ACCENT_COLOR=$(grep -oP '(?<=AccentColor=")[^"]+' "$COLORS_TMP" || echo "#9cd49f")

# ── 2) theme.conf'daki renk satırlarını güncelle ───────────────────────────
sed -i \
    -e "s|^MainColor=.*|MainColor=\"${MAIN_COLOR}\"|" \
    -e "s|^AccentColor=.*|AccentColor=\"${ACCENT_COLOR}\"|" \
    "$THEME_CONF"

# ── 3) Duvar kağıdını kopyala ──────────────────────────────────────────────
if [[ -n "$WALLPAPER" && -f "$WALLPAPER" ]]; then
    MIME=$(file --mime-type -b "$WALLPAPER")
    case "$MIME" in
        image/jpeg|image/jpg)
            cp "$WALLPAPER" "$THEME_DIR/Background.jpg"
            ;;
        image/png)
            # PNG'yi JPEG'e dönüştür (sugar-dark .jpg bekler)
            if command -v convert &>/dev/null; then
                convert "$WALLPAPER" "$THEME_DIR/Background.jpg"
            else
                cp "$WALLPAPER" "$THEME_DIR/Background.jpg"
            fi
            ;;
        image/webp|image/avif|image/gif)
            if command -v convert &>/dev/null; then
                convert "${WALLPAPER}[0]" "$THEME_DIR/Background.jpg"
            fi
            ;;
        video/*|application/*)
            # Video ise ffmpeg ile önizleme karesi al
            if command -v ffmpeg &>/dev/null; then
                DURATION=$(ffprobe -v error -show_entries format=duration \
                    -of default=noprint_wrappers=1:nokey=1 "$WALLPAPER" 2>/dev/null || echo "1.0")
                SEEK=$(echo "$DURATION" | awk '{print $1 * 0.2}')
                ffmpeg -y -ss "$SEEK" -i "$WALLPAPER" -vframes 1 -q:v 2 \
                    "$THEME_DIR/Background.jpg" >/dev/null 2>&1
            fi
            ;;
    esac
    echo "[update-sddm] Duvar kağıdı güncellendi: $WALLPAPER"
fi

echo "[update-sddm] Renkler güncellendi — MainColor=$MAIN_COLOR AccentColor=$ACCENT_COLOR"
