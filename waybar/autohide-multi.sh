#!/bin/bash
# ─────────────────────────────────────────────────────────
# Multi-Monitor Waybar Auto-Hide (kill/relaunch)
# Hyprland slide animasyonunu tetiklemek için waybar
# sürecini öldürüp yeniden başlatır.
# ─────────────────────────────────────────────────────────

CONFIG_DIR="$HOME/.config/waybar"
STYLE="$CONFIG_DIR/style.css"
LOG_FILE="$CONFIG_DIR/autohide.log"
log() { echo "[$(date '+%H:%M:%S.%3N')] $*" >> "$LOG_FILE"; }
log "=== autohide-multi.sh started (PID=$$) ==="
BAR_H=52
EDGE_TRIGGER=2
POLL=0.12
COOLDOWN=600  # Durum değişimleri arası minimum ms

declare -A PID STATE MON_X MON_Y MON_EW MON_EH LAST_CHG

cleanup() { for p in "${PID[@]}"; do kill "$p" 2>/dev/null; done; exit 0; }
trap cleanup EXIT INT TERM

now_ms() { awk '{printf "%d", $1*1000}' /proc/uptime; }  # monotonic, NTP/saat kaymasından etkilenmez

in_cooldown() {
    local now=$(now_ms) last=${LAST_CHG[$1]:-0}
    (( now - last < COOLDOWN ))
}

launch_bar() {
    log "launch_bar($1): starting waybar"
    waybar -c "$CONFIG_DIR/config-${1}.jsonc" -s "$STYLE" &>/dev/null &
    PID[$1]=$!; STATE[$1]=0; LAST_CHG[$1]=$(now_ms)
    log "launch_bar($1): PID=${PID[$1]}"
    # Waybar'ın gerçekten başladığını doğrula (kısa bekleme + PID kontrolü)
    sleep 0.3
    if ! kill -0 "${PID[$1]}" 2>/dev/null; then
        log "launch_bar($1): PID ${PID[$1]} died, retrying..."
        sleep 0.5
        waybar -c "$CONFIG_DIR/config-${1}.jsonc" -s "$STYLE" &>/dev/null &
        PID[$1]=$!; LAST_CHG[$1]=$(now_ms)
        log "launch_bar($1): retry PID=${PID[$1]}"
    else
        log "launch_bar($1): PID ${PID[$1]} alive OK"
    fi
}

hide_bar() {
    [[ "${STATE[$1]}" != "0" ]] && return
    in_cooldown "$1" && return
    kill "${PID[$1]}" 2>/dev/null
    PID[$1]=""; STATE[$1]=1; LAST_CHG[$1]=$(now_ms)
}

show_bar() {
    [[ "${STATE[$1]}" != "1" ]] && return
    in_cooldown "$1" && return
    launch_bar "$1"
}

# ── Mevcut waybar süreçlerini PID ile durdur (killall kullanma!) ──
log "Killing existing waybar/autohide processes..."
for p in $(pgrep -x waybar); do log "  kill waybar PID=$p"; kill "$p" 2>/dev/null; done
for p in $(pgrep -f waybar_auto_hide); do log "  kill autohide PID=$p"; kill "$p" 2>/dev/null; done
sleep 0.4
log "Existing processes killed, starting monitor detection"

# ── Başlat ──
# Ön değerleri almak için hyprctl çalıştırıyoruz
LAST_MJ=$(hyprctl monitors -j 2>/dev/null)
while IFS=' ' read -r n mx my mw mh ms mt; do
    MON_X[$n]=$mx; MON_Y[$n]=$my
    if [[ "$mt" == "1" || "$mt" == "3" || "$mt" == "5" || "$mt" == "7" ]]; then
        temp=$mw; mw=$mh; mh=$temp
    fi
    # Logical (scaled) boyutlar: global koordinat sistemiyle uyumlu
    MON_EW[$n]=$(awk "BEGIN{printf \"%d\",$mw/$ms}")
    MON_EH[$n]=$(awk "BEGIN{printf \"%d\",$mh/$ms}")
done < <(echo "$LAST_MJ" | jq -r '.[]|"\(.name) \(.x) \(.y) \(.width) \(.height) \(.scale) \(.transform)"')

MONITORS=("${!MON_X[@]}")
for mon in "${MONITORS[@]}"; do
    launch_bar "$mon"
    sleep 0.3  # Barlar arası bekleme — eşzamanlı başlatma çakışmasını önler
done
sleep 0.5

# ── Ana döngü ──
while true; do
    mj=$(hyprctl monitors -j 2>/dev/null)

    # Monitör verisi değiştiyse (çözünürlük, hizalama, scale vb.) geometriyi güncelle
    if [[ "$mj" != "$LAST_MJ" ]]; then
        LAST_MJ="$mj"
        while IFS=' ' read -r n mx my mw mh ms mt; do
            MON_X[$n]=$mx; MON_Y[$n]=$my
            if [[ "$mt" == "1" || "$mt" == "3" || "$mt" == "5" || "$mt" == "7" ]]; then
                temp=$mw; mw=$mh; mh=$temp
            fi
            MON_EW[$n]=$(awk "BEGIN{printf \"%d\",$mw/$ms}")
            MON_EH[$n]=$(awk "BEGIN{printf \"%d\",$mh/$ms}")
        done < <(echo "$mj" | jq -r '.[]|"\(.name) \(.x) \(.y) \(.width) \(.height) \(.scale) \(.transform)"')
        MONITORS=("${!MON_X[@]}")
    fi

    cr=$(hyprctl cursorpos 2>/dev/null)
    cx=$(echo "$cr"|cut -d',' -f1|tr -d ' ')
    cy=$(echo "$cr"|cut -d',' -f2|tr -d ' ')
    [[ -z "$cx" || -z "$cy" ]] && { sleep 0.2; continue; }

    for mon in "${MONITORS[@]}"; do
        # Monitörün global logical koordinatları
        mx=${MON_X[$mon]}; my=${MON_Y[$mon]}
        ew=${MON_EW[$mon]}; eh=${MON_EH[$mon]}

        # Global koordinatlarda monitörün alt kenarı ve waybar'ın üst kenarı
        bot=$((my+eh))
        bar_top=$((bot-BAR_H))

        # Global sağ kenar
        mr=$((mx+ew))

        # İmleç bu monitörün alanında mı? (global koordinatlarda)
        co=0; (( cx>=mx && cx<mr && cy>=my && cy<bot )) && co=1

        # Sadece imleç alt kenara yaklaşınca aç; pencere durumuna bakılmaz
        if [[ "${STATE[$mon]}" == "1" ]]; then
            (( co==1 && cy>=bot-EDGE_TRIGGER )) && show_bar "$mon"
        else
            # Bar görünürken: imleç bar alanında değilse gizle
            if (( co==1 && cy>=bar_top-10 )); then :
            else hide_bar "$mon"; fi
        fi
    done

    # Ölmüş waybar süreçlerini yeniden başlat (crash recovery)
    for mon in "${MONITORS[@]}"; do
        if [[ "${STATE[$mon]}" == "0" ]] && [[ -n "${PID[$mon]}" ]] && ! kill -0 "${PID[$mon]}" 2>/dev/null; then
            STATE[$mon]=1  # Gizli olarak işaretle, böylece show_bar tekrar başlatabilsin
            launch_bar "$mon"
        fi
    done

    sleep "$POLL"
done
