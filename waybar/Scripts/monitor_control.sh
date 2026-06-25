#!/usr/bin/env bash

# Eğer panel zaten açıksa kapat (Toggle mantığı)
if eww active-windows | grep -q "brightness_menu"; then
    eww close brightness_menu
    exit 0
fi

# Farenin bulunduğu monitörü ve koordinatını anlık çek
ACTIVE_MONITOR=$(hyprctl activeworkspace -j | jq -r '.monitorID')
CURSOR_POS=$(hyprctl cursorpos)

# Gizli boşluk ve karakterlerden kurtulmak için temizleme işlemi
MOUSE_X=$(echo "$CURSOR_POS" | awk -F, '{print $1}' | tr -d '[:space:]')
MOUSE_Y=$(echo "$CURSOR_POS" | awk -F, '{print $2}' | tr -d '[:space:]')

# Panelin genişliğini ortalamak için X'i hizalıyoruz (Genişlik 320px olduğu için ~160 çıkarıyoruz)
X_POS=$((MOUSE_X - 160))
Y_POS=$((MOUSE_Y + 15))

# Ekranın en soluna taşmayı engelle
if [ "$X_POS" -lt 0 ]; then X_POS=0; fi

# --- ÇÖZÜMÜN ANAHTARI BURADA ---
# Hatalı olan "--pos" komutu silindi. Koordinatları direkt olarak EWW'ye değişken ile gönderiyoruz.
eww update pos_x="$X_POS" pos_y="$Y_POS"

# EWW penceresini doğru monitör argümanı (--screen) ile başlatıyoruz
eww open brightness_menu --screen "$ACTIVE_MONITOR"

# Arka planda donanımla konuşan parlaklık güncelleme fonksiyonu (Terminali kilitlemez)
update_brightness_async() {
    get_brightness() {
        local bus=$1
        local raw_val=$(ddcutil getvcp 10 --bus "$bus" 2>/dev/null | grep -oP 'current value =\s*\K[0-9,.]+')
        if [ -n "$raw_val" ]; then
            echo "$raw_val" | cut -d',' -f1 | cut -d'.' -f1
        else
            echo "50"
        fi
    }

    VIVID_CUR=$(get_brightness 4)
    LED_CUR=$(get_brightness 10)

    # Değerleri EWW panelindeki slider'lara canlı ilet
    eww update vivid_cur="$VIVID_CUR" led_cur="$LED_CUR"
}

# Sistemi meşgul etmeden arka planda çalıştır
update_brightness_async &