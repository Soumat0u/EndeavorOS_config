#!/bin/bash
# Butona tıklayınca: bir terminalde pacman güncellemesini çalıştırır,
# bittiğinde waybar'daki güncelleme modülünü hemen tazeler.
kitty --title "Paket Güncelleme" -e bash -c "sudo pacman -Syu; echo; read -p 'Kapatmak için Enter...'"
pkill -RTMIN+8 waybar
