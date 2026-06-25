#!/bin/bash
# ~/.config/waybar/autohide.sh

# Waybar yüksekliği (bu değeri geçince bar gizlenir)
BAR_HEIGHT=42

# Başlangıçta Waybar'ın açık olduğunu varsayıyoruz, onu gizliyoruz
killall -SIGUSR1 waybar
hidden=1

while true; do
    # Fare pozisyonunu al (örnek: "1920, 500")
    pos=$(hyprctl cursorpos 2>/dev/null)
    y=$(echo "$pos" | cut -d',' -f2 | tr -d ' ')
    
    # Hata durumunda devam et
    if [ -z "$y" ]; then
        sleep 0.2
        continue
    fi

    # Fare ekranın en üstünde mi? (Y < 5)
    if [ "$y" -lt 5 ]; then
        if [ "$hidden" -eq 1 ]; then
            killall -SIGUSR1 waybar
            hidden=0
        fi
    # Fare bardan çıktı mı? (Y > BAR_HEIGHT)
    elif [ "$y" -gt "$BAR_HEIGHT" ]; then
        if [ "$hidden" -eq 0 ]; then
            killall -SIGUSR1 waybar
            hidden=1
        fi
    fi
    
    sleep 0.1
done
