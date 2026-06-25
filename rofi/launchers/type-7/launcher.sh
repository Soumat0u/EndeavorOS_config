#!/usr/bin/env bash

## Author : Aditya Shakya (adi1090x)
## Github : @adi1090x
#
## Rofi   : Launcher (Modi Drun, Run, File Browser, Window)
#
## Available Styles
#
## style-1     style-2     style-3     style-4     style-5
## style-6     style-7     style-8     style-9     style-10

dir="$HOME/.config/rofi/launchers/type-7"
theme='style-5'

## Inputbar arkaplanı için wallpaper klasöründen rastgele statik görsel seç
wallpaper_dir="$HOME/Masaüstü/wallpapers"
random_wallpaper=$(find "$wallpaper_dir" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | shuf -n 1)

## Run
rofi \
    -show drun \
    -theme ${dir}/${theme}.rasi \
    -theme-str "inputbar { background-image: url(\"${random_wallpaper}\", width); }"
