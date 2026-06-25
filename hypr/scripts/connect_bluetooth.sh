#!/bin/bash
MAC="6D:03:AB:DF:A0:CD"

# Servislerin yüklenmesi için bekle
sleep 10

# Bluetooth'u aç
bluetoothctl power on
sleep 2

# Normal şekilde güvenip bağlanmayı dene
bluetoothctl trust $MAC
bluetoothctl connect $MAC

# Bağlantının kurulması için biraz bekle
sleep 5

# Bağlantı durumunu kontrol et
if ! bluetoothctl info $MAC | grep -q "Connected: yes"; then
    echo "Bağlantı başarısız. Cihaz kaldırılıp yeniden taranıyor..."
    
    # Cihazı tamamen kaldır
    bluetoothctl remove $MAC
    sleep 2
    
    # Taramayı 10 saniye arka planda çalıştır
    bluetoothctl --timeout 10 scan on &
    
    # Cihazın bulunması için bekle
    sleep 5
    
    # Yeniden eşleştir, güven ve bağlan
    bluetoothctl pair $MAC
    bluetoothctl trust $MAC
    bluetoothctl connect $MAC
fi
