#!/bin/bash
# İkon her zaman basılır; güncelleme varsa yanına sayı eklenir.
# checkupdates'in izole DB'si (refresh-update-db.sh tarafından ağdan
# tazelenir) varsa onu okur; yoksa yerel pacman DB'sine düşer.
# İkisi de yalnızca dosya okuduğu için anında sonuç verir.
CHECKUPDATES_DB="/tmp/checkup-db-${UID}/"
if [ -d "$CHECKUPDATES_DB" ]; then
    count=$(pacman -Qu --dbpath "$CHECKUPDATES_DB" 2>/dev/null | wc -l)
else
    count=$(pacman -Qu 2>/dev/null | wc -l)
fi
if [ "$count" -gt 0 ]; then
    echo "󰚰 $count"
else
    echo "󰚰"
fi
