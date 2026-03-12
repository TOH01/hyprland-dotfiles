#!/bin/bash

MONITOR="DP-1"
RES="2560x1440@360"
STATE_FILE="$HOME/.cache/hypr_mode_state"

ID_SILENT="65f620f1-adae-4175-b8f2-822aef8109c2"
ID_WORK="0fb79238-3580-4aeb-a4b5-eab23a52c1c6"
ID_GAME="8e877d53-7883-417f-918b-2193cf8b1888"

if [ ! -f "$STATE_FILE" ]; then
    echo "workstation" > "$STATE_FILE"
fi

CURRENT_MODE=$(cat "$STATE_FILE")

apply_fan_mode() {
    curl -s -c /tmp/cc_cookie -u "CCAdmin:fedora" -X POST "http://localhost:11987/login" > /dev/null
    curl -s -b /tmp/cc_cookie -X POST "http://localhost:11987/modes-active/$1" > /dev/null
    rm -f /tmp/cc_cookie
}

apply_mode() {
    case $1 in
        "afk")
            apply_fan_mode "$ID_SILENT"
            powerprofilesctl set power-saver
            hyprctl keyword monitor "$MONITOR,$RES,0x0,1.33,bitdepth,10"
            ;;

        "workstation")
            apply_fan_mode "$ID_WORK"
            powerprofilesctl set balanced
            hyprctl keyword monitor "$MONITOR,$RES,0x0,1.33,bitdepth,10"
            ;;

        "gaming")
            apply_fan_mode "$ID_GAME"
            powerprofilesctl set performance
            hyprctl keyword monitor "$MONITOR,$RES,0x0,1.33,bitdepth,10,cm,hdr,sdrbrightness,1.2,sdrsaturation,0.98"
            ;;
    esac
}

if [ "$1" == "next" ]; then
    if [ "$CURRENT_MODE" == "workstation" ]; then NEXT="gaming";
    elif [ "$CURRENT_MODE" == "gaming" ]; then NEXT="afk";
    else NEXT="workstation"; fi

    echo "$NEXT" > "$STATE_FILE"
    apply_mode "$NEXT"

    pkill -RTMIN+8 waybar

elif [ "$1" == "apply" ]; then
    apply_mode "$CURRENT_MODE"
fi

case $(cat "$STATE_FILE") in
    "afk") echo '{"text":"󰒲 ", "class":"afk"}' ;;
    "workstation") echo '{"text":"󰇄 ", "class":"workstation"}' ;;
    "gaming") echo '{"text":"󰓓 ", "class":"gaming"}' ;;
esac
