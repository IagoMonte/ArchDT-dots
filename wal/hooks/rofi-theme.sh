#!/bin/bash

# PATH Pywal colors.json
WAL="$HOME/.cache/wal/colors.json"
# PATH pywal-rofi.rasi
OUTPUT="$HOME/.config/rofi/pywal-rofi.rasi"

# get colors
BG=$(jq -r .special.background "$WAL")
FG=$(jq -r .special.foreground "$WAL")
COLOR3=$(jq -r .colors.color3 "$WAL")
COLOR4=$(jq -r .colors.color4 "$WAL")
COLOR5=$(jq -r .colors.color5 "$WAL")
BGT=$BG"8C" #4D = Opacity in HEX
COLOR5T=$COLOR5"8C" #4D = Opacity in HEX
BGT2=$BG"80"
#pywal-rofi.rasi
cat << EOF > "$OUTPUT"

/*$
#    ____      _                  ____                      _ 
#  / ___|___ | | ___  _ __ ___  |  _ \ _   ___      ____ _| |
# | |   / _ \| |/ _ \| '__/ __| | |_) | | | \ \ /\ / / _\ | |
# | |__| (_) | | (_) | |  \__ \ |  __/| |_| |\ V  V / (_| | |
#  \____\___/|_|\___/|_|  |___/ |_|    \__, | \_/\_/ \__,_|_|
#                                      |___/                 
*/

* {
    bg0:    $BGT;
    bg1:    $COLOR3;
    bg2:    $BGT2;
    bg3:    $COLOR5T;
    fg0:    $FG;
    fg1:    $FG;
    fg2:    $FG;
    fg3:    $FG;
}
EOF