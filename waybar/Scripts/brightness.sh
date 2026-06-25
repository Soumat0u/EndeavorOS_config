#!/bin/bash
OUTPUT=$1
CMD=$2
STEP=5

# DP-1 veya DP-2 için önbellek dosyaları
CACHE_BUS="/tmp/waybar_ddcutil_bus_${OUTPUT}"
CACHE_VAL="/tmp/waybar_ddcutil_val_${OUTPUT}"

# Monitörün I2C bus adresini bul (İlk çalışmada cache'e kaydeder)
if [ ! -s "$CACHE_BUS" ]; then
    ddcutil detect --terse > /tmp/ddc_detect.tmp
    grep -B 1 "DRM connector: .*${OUTPUT}" /tmp/ddc_detect.tmp | head -n 1 | awk -F'/dev/i2c-' '{print $2}' > "$CACHE_BUS"
fi
BUS=$(cat "$CACHE_BUS")

if [ -z "$BUS" ]; then
    echo "{\"text\": \"Error\", \"tooltip\": \"Monitor not found\"}"
    exit 0
fi

# Mevcut parlaklığı al (Sadece ilk çalışmada)
if [ ! -s "$CACHE_VAL" ]; then
    VAL=$(ddcutil getvcp 10 --bus=$BUS --terse 2>/dev/null | awk '{print $4}')
    [ -z "$VAL" ] && VAL=50
    echo "$VAL" > "$CACHE_VAL"
fi
VAL=$(cat "$CACHE_VAL")

# Kaydırma (Scroll) işlemi varsa
case $CMD in
  up)
    VAL=$(( VAL + STEP ))
    [ $VAL -gt 100 ] && VAL=100
    echo $VAL > "$CACHE_VAL"
    # Arka planda anında ddcutil ile donanıma uygula
    ddcutil setvcp 10 $VAL --bus=$BUS --noverify >/dev/null 2>&1 &
    ;;
  down)
    VAL=$(( VAL - STEP ))
    [ $VAL -lt 0 ] && VAL=0
    echo $VAL > "$CACHE_VAL"
    # Arka planda anında ddcutil ile donanıma uygula
    ddcutil setvcp 10 $VAL --bus=$BUS --noverify >/dev/null 2>&1 &
    ;;
esac

# Waybar'a güncel JSON çıktısını dön
echo "{\"text\": \"${VAL}%\", \"tooltip\": \"Brightness: ${VAL}%\", \"percentage\": $VAL}"
