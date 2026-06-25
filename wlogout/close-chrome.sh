#!/bin/bash
# Chrome'un ana (browser) process'ini bulup SIGTERM gönderir, çocuk
# process'lere (zygote/gpu/renderer/crashpad) dokunmaz — onlar ana
# process kapanınca otomatik sonlanır. Düzgün kapanma exit_type'ı
# "Normal" yapar, bir sonraki açılışta sekmeler otomatik geri gelir.
main_pids=()
for pid in $(pgrep -f '/app/extra/chrome' 2>/dev/null); do
    comm=$(cat "/proc/$pid/comm" 2>/dev/null)
    [ "$comm" = "chrome" ] || continue
    tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null | grep -q -- '--type=' && continue
    kill -TERM "$pid" 2>/dev/null
    main_pids+=("$pid")
done

# Sabit bir süre tahmin etmek yerine, ana process(ler) gerçekten kapanana
# kadar bekle; kapanır kapanmaz hemen devam et. 10s üst sınır sadece
# Chrome takılırsa logout/shutdown'ı sonsuza dek bloklamamak için.
deadline=$(( $(date +%s) + 10 ))
for pid in "${main_pids[@]}"; do
    while kill -0 "$pid" 2>/dev/null; do
        [ "$(date +%s)" -ge "$deadline" ] && break
        sleep 0.1
    done
done
