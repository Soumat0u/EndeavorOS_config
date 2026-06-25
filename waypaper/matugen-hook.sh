#!/bin/bash

WALLPAPER="$1"
CACHE_IMG="/tmp/matugen_frame.jpg"
TARGET=""

# 1. Eğer bir klasörse (Wallpaper Engine projeleri genelde klasördür)
if [[ -d "$WALLPAPER" ]]; then
    # Klasör içindeki preview dosyasını bul
    if [[ -f "$WALLPAPER/preview.jpg" ]]; then
        TARGET="$WALLPAPER/preview.jpg"
    elif [[ -f "$WALLPAPER/preview.png" ]]; then
        TARGET="$WALLPAPER/preview.png"
    else
        # preview yoksa içindeki ilk görseli al
        TARGET=$(find "$WALLPAPER" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" \) | head -n 1)
    fi

# 2. Eğer video veya GIF ise ffmpeg ile 1. saniyedeki kareyi alıp önbelleğe kaydet
elif [[ "$WALLPAPER" == *.mp4 || "$WALLPAPER" == *.mkv || "$WALLPAPER" == *.webm || "$WALLPAPER" == *.gif ]]; then
    # Siyah ekran gelmemesi için 1. saniyedeki frame'i alır
    ffmpeg -y -ss 00:00:01 -i "$WALLPAPER" -vframes 1 -q:v 2 "$CACHE_IMG" >/dev/null 2>&1
    TARGET="$CACHE_IMG"

# 3. Zaten normal bir resimse doğrudan kullan
else
    TARGET="$WALLPAPER"
fi

echo "$(date) - Matugen hook called with $1. Extracted target: $TARGET" >> /tmp/matugen-hook.log

# Eğer hedef dosya bulunmuşsa Matugen'i çalıştır
if [[ -n "$TARGET" && -f "$TARGET" ]]; then
    matugen image --source-color-index 0 "$TARGET" >> /tmp/matugen-hook.log 2>&1
fi
