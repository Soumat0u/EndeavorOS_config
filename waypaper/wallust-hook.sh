#!/bin/bash
exec > /tmp/wallust-hook.log 2>&1
set -x
WALLPAPER="${1/#\~/$HOME}"
WALLPAPER="${WALLPAPER//\\/}"
CACHE_IMG="/tmp/wallust_frame.jpg"
TARGET=""

if [[ -d "$WALLPAPER" ]]; then
    if [[ -f "$WALLPAPER/preview.jpg" ]]; then
        TARGET="$WALLPAPER/preview.jpg"
    elif [[ -f "$WALLPAPER/preview.png" ]]; then
        TARGET="$WALLPAPER/preview.png"
    else
        TARGET=$(find "$WALLPAPER" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" \) | head -n 1)
    fi
elif [[ "$WALLPAPER" == *.mp4 || "$WALLPAPER" == *.mkv || "$WALLPAPER" == *.webm || "$WALLPAPER" == *.gif ]]; then
    # Videonun süresini hesapla ve %20'sinden bir kare al (başlangıçtaki siyah ekranları atlamak için)
    DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$WALLPAPER" 2>/dev/null || echo "1.0")
    SEEK_TIME=$(echo "$DURATION" | awk '{print $1 * 0.2}')
    
    # Kareyi çıkarırken renk doygunluğunu (saturation) %50 artır ki Wallust çok daha canlı renkler yakalayabilsin
    ffmpeg -y -ss "$SEEK_TIME" -i "$WALLPAPER" -vf "eq=saturation=1.5" -vframes 1 -q:v 2 "$CACHE_IMG" >/dev/null 2>&1
    TARGET="$CACHE_IMG"
else
    TARGET="$WALLPAPER"
fi

if [[ -n "$TARGET" && -f "$TARGET" ]]; then
    # Run Wallust
    wallust run "$TARGET" >/dev/null 2>&1
    
    # Reload apps
    # Waybar ve auto-hide-multi scriptini yeni renklerle yeniden başlat
    pkill -f "autohide-multi.sh" 2>/dev/null || true
    killall -q waybar 2>/dev/null || true
    sleep 0.5
    nohup bash ~/.config/waybar/autohide-multi.sh > /dev/null 2>&1 &

    # Hyprland renklerini güncelle
    hyprctl reload

    # Kitty terminal renklerini güncelle
    kill -SIGUSR1 $(pgrep -f 'kitty') 2>/dev/null || true

    # Cava renklerini güncelle
    killall -USR1 cava 2>/dev/null || true

    # Snappy-switcher renklerini güncelle (yeniden başlatarak)
    killall -9 snappy-switcher 2>/dev/null || true
    sleep 0.5
    nohup snappy-switcher --daemon >/dev/null 2>&1 &

    # Swaync bildirim merkezini yenile
    timeout 1 swaync-client -rs 2>/dev/null || true

    # Dunst bildirim temasını yeni renklerle yeniden başlat
    pkill -x dunst 2>/dev/null || true
    sleep 0.3
    nohup dunst >/dev/null 2>&1 &

    # SwayOSD ses çubuğunu yeni renklerle yeniden başlat
    killall -9 swayosd-server 2>/dev/null || true
    sleep 1
    swayosd-server --style ~/.config/swayosd/style.css --top-margin 0.92 >/dev/null 2>&1 &
    
    # Starship update (call the script)
    ~/.config/wallust/scripts/update-starship.sh

    # SDDM sugar-dark: duvar kağıdı + wallust renklerini güncelle
    # /tmp/sddm-wallust-colors.conf wallust tarafından zaten üretildi (wallust.toml'daki sddm şablonu)
    # Orijinal duvar kağıdını kullan (video ise ffmpeg kare zaten CACHE_IMG'de)
    SDDM_WALLPAPER="$WALLPAPER"
    if [[ "$WALLPAPER" == *.mp4 || "$WALLPAPER" == *.mkv || "$WALLPAPER" == *.webm || "$WALLPAPER" == *.gif ]]; then
        SDDM_WALLPAPER="$CACHE_IMG"
    fi
    sudo /home/safak/.config/wallust/scripts/update-sddm.sh "$SDDM_WALLPAPER" >> /tmp/wallust-hook.log 2>&1 || true
fi
