#!/bin/bash
# Görsellerinin olduğu klasörü belirt
IMAGE_DIR="/home/safak/Resimler/Wallpapers" 
# Rastgele bir görsel seç
IMAGE=$(find "$IMAGE_DIR" -type f | shuf -n 1)
# Görseli göster
chafa -s 40x20 "$IMAGE"