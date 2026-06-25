#!/usr/bin/env bash

#// Çalışıyorsa kapat (Toggle)
if pgrep -x "wlogout" >/dev/null; then
    pkill -x "wlogout"
    exit 0
fi

#// Senin mutlak dosya yolların
confDir="$HOME/.config"
wLayout="${confDir}/wlogout/layout"
wlTmplt="${confDir}/wlogout/style.css"

#// Hata kontrolü: Eğer dosyalar yerinde değilse sistemi kilitleme
if [ ! -f "${wLayout}" ] || [ ! -f "${wlTmplt}" ]; then
    echo "HATA: /home/safak/.config/wlogout/ klasöründe 'layout' veya 'style.css' bulunamadı!"
    exit 1
fi

#// Monitör çözünürlüğünü ve Hyprland ölçeğini algıla
x_mon=$(hyprctl -j monitors | jq '.[] | select(.focused==true) | .width')
y_mon=$(hyprctl -j monitors | jq '.[] | select(.focused==true) | .height')
hypr_scale=$(hyprctl -j monitors | jq '.[] | select (.focused == true) | .scale' | sed 's/\.//')

#// Sütun sayısı (6 Buton Tek Satır)
wlColms=6

#// ÇÖZÜNÜRLÜĞE GÖRE DİNAMİK MARGIN HESABI (Issue #51 Resmi Çözümüyle Entegre)
#// Ölçeği hesaba katarak dikeyde %38, yatayda sol/sağ için ekran oranına göre boşluk bırakır.
export margin_top=$(( y_mon * 38 / hypr_scale ))
export margin_bottom=$(( y_mon * 38 / hypr_scale ))
export margin_left=$(( x_mon * 22 / hypr_scale ))
export margin_right=$(( x_mon * 22 / hypr_scale ))

#// LAUNCH WLOGOUT: Hesaplanan dinamik margin değerlerini parametre olarak fırlatıyoruz
wlogout -b "${wlColms}" \
        -c 0 -r 0 \
        -T "${margin_top}" -B "${margin_bottom}" -L "${margin_left}" -R "${margin_right}" \
        --layout "${wLayout}" \
        --css "${wlTmplt}" \
        --protocol layer-shell --class "wlogout" &