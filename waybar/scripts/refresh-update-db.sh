#!/bin/bash
# systemd timer tarafından periyodik (15 dakikada bir) tetiklenir:
# checkupdates'in kendi izole (root gerektirmeyen) veritabanını ağdan
# senkronize eder, ardından waybar'daki güncelleme modülünü tazeler.
checkupdates >/dev/null 2>&1
pkill -RTMIN+8 waybar 2>/dev/null
