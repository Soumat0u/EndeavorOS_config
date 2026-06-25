#!/bin/bash

# A script to automatically align DP-2 based on DP-1's current resolution and scale
# It generates a monitors.lua file and reloads Hyprland safely.

MONITORS_LUA="$HOME/.config/hypr/monitors.lua"

function apply_4k {
    cat <<EOF > "$MONITORS_LUA"
hl.monitor({
    output   = "DP-1",
    mode     = "3840x2160@160",
    position = "0x200",
    scale    = 1.5,
})
hl.monitor({
    output   = "DP-2",
    mode     = "1920x1080@180",
    position = "2560x350",
    scale    = 1,
    transform = 0,
})
EOF
    hyprctl reload > /dev/null
    # Duvar kağıdını yeni çözünürlüğe/konuma uyarlamak için yeniden başlat
    pkill mpvpaper; pkill swww-daemon; pkill swaybg; waypaper --restore >/dev/null 2>&1 &
    notify-send "Monitör Modu" "4K 160Hz aktif edildi." -t 2000
}

function apply_1080p {
    cat <<EOF > "$MONITORS_LUA"
hl.monitor({
    output   = "DP-1",
    mode     = "1920x1080@320",
    position = "0x0",
    scale    = 1.0,
})
hl.monitor({
    output   = "DP-2",
    mode     = "1920x1080@180",
    position = "1920x0",
    scale    = 1,
    transform = 0,
})
EOF
    hyprctl reload > /dev/null
    # Duvar kağıdını yeni çözünürlüğe/konuma uyarlamak için yeniden başlat
    pkill mpvpaper; pkill swww-daemon; pkill swaybg; waypaper --restore >/dev/null 2>&1 &
    notify-send "Monitör Modu" "1080p 320Hz aktif edildi." -t 2000
}

function check_and_apply {
    local dp1_json=$(hyprctl monitors all -j | jq '.[] | select(.name=="DP-1")')
    if [ -z "$dp1_json" ]; then return; fi

    # EDID verisindeki donanım modunu kontrol et
    local has_4k=$(echo "$dp1_json" | jq '.availableModes | join(",") | contains("3840x2160")')
    
    if [ "$has_4k" == "true" ]; then
        apply_4k
    else
        apply_1080p
    fi
}

function toggle {
    local dp1_json=$(hyprctl monitors all -j | jq '.[] | select(.name=="DP-1")')
    if [ -z "$dp1_json" ]; then return; fi
    
    local has_4k=$(echo "$dp1_json" | jq '.availableModes | join(",") | contains("3840x2160")')
    
    # Check what is currently in monitors.lua to toggle
    if grep -q "3840x2160" "$MONITORS_LUA" 2>/dev/null; then
        if [ "$has_4k" == "false" ]; then
            notify-send "Hata" "Monitör şu an donanımsal olarak 1080p modunda. 4K'ya geçmek için monitörün tuşunu kullanın."
            return
        fi
        apply_1080p
    else
        if [ "$has_4k" == "false" ]; then
            notify-send "Hata" "Monitör şu an donanımsal olarak 1080p modunda. 4K'ya geçmek için monitörün tuşunu kullanın."
            return
        fi
        apply_4k
    fi
}

function daemon {
    # Eğer monitors.lua yoksa oluştur
    if [ ! -f "$MONITORS_LUA" ]; then
        check_and_apply
    fi

    # Hyprland IPC'den monitör takılıp çıkarılmasını dinle
    socat -U - UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | while read -r line; do
        if [[ "$line" == "monitoradded>>"* || "$line" == "monitorremoved>>"* ]]; then
            # Donanımsal geçişin oturması için bekle
            sleep 2
            check_and_apply
        fi
    done
}

if [ "$1" == "--toggle" ]; then
    toggle
else
    daemon
fi
