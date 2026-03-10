#!/bin/bash

HELP=$(printf "
%s [operation]

Send system-notifications

positional argument:
\t- 'adio_in'  : call on mic state change
\t- 'adio_out' : call on speaker state change
\t- 'backlight': call on backlight state change
\t- 'battery_level': display battery_level notification
\t- 'charging_cable': display charging_cable status notification
" "$0")

OP=$1
ID_DB="/tmp/sys_notify_current"
TIMEOUT_LONG=1100
TIMEOUT_SHORT=900

fail() {
    echo "$HELP"
}

today () {
    date +%d-%m-%Y
}

to_json() {
    echo "{\"id\": $1, \"timeout\": $2, \"date\": \"$(today)\", \"millis\": $(date +%s)}"
}

notify () {
    replace=0

    if [ -e "$ID_DB" ]; then
        id="$(jq .id $ID_DB)"
        millis="$(jq .millis $ID_DB)"
        timeout="$(jq .timeout $ID_DB)"
        json_date="$(jq -r .date $ID_DB)"

        echo "$(($millis - $(date +%s)))"
        if [ "$json_date" == "$(today)" ] && [ $(($(date +%s) - millis)) -lt "$timeout" ]; then
            echo "Replace ${id} $(($(date +%s) - millis))"
            replace=1
        fi
    fi
    to_json "$(notify-send $([ $replace -eq 1 ] && echo " --replace-id=$id ") -t "$1" --print-id "${@:2}")" "$1" > "$ID_DB"
}

ICONS_DEFAULT="$HOME/.config/wired/sys_notify/icons_default"
ICONS_CRITICAL="$HOME/.config/wired/sys_notify/icons_critical"
audio_out() {
    wpctl_output="$(wpctl get-volume @DEFAULT_SINK@)"

    if [ "$(echo "$wpctl_output" | grep -oF \[MUTED\])" = \[MUTED\] ]; then
        notify "$TIMEOUT_SHORT" "" "" --hint="string:wired-tag:sys_notify" \
            -i "$ICONS_DEFAULT"/mute.png
        exit 0
    fi

    volume="$(bc -l <<<"scale=0; ($(echo "$wpctl_output" | grep -oE "[[:digit:]]{0,2}\.[[:digit:]]{2}") * 100) / 1")"

    if [ "$volume" = "" ]; then
        notify "$TIMEOUT_SHORT" "" "" --hint="string:wired-tag:sys_notify" \
            -i "$ICONS_DEFAULT"/unmute.png
        exit 0
    fi

    notify $TIMEOUT_LONG "" "$volume" --hint="string:wired-tag:sys_notify" \
        -i "$ICONS_DEFAULT"/volume_change.png -h int:value:"$volume"
}

audio_in() {
    wpctl_output="$(wpctl get-volume @DEFAULT_SOURCE@)"

    if [ "$(echo "$wpctl_output" | grep -oF \[MUTED\])" = \[MUTED\] ]; then
        notify "$TIMEOUT_SHORT" "" "" --hint="string:wired-tag:sys_notify" \
            -i "$ICONS_DEFAULT"/mic_mute.png
        exit 0
    fi

    notify "$TIMEOUT_SHORT" "" "$volume" --hint="string:wired-tag:sys_notify" \
        -i "$ICONS_DEFAULT"/mic.png
}

backlight() {
    brightness="$(brightnessctl info | grep -oE "([[:digit:]]{1,3}%)" | grep -oE "[[:digit:]]{1,3}")"

    notify $TIMEOUT_LONG "" "$brightness" --hint="string:wired-tag:sys_notify" \
        -i "$ICONS_DEFAULT"/light_full.png -h int:value:"$brightness"

}

battery_level() {
    capacity="$(cat /sys/class/power_supply/BAT0/capacity)"

    if [ "$capacity" -lt 20 ] && [ "$capacity" -gt 10 ]; then
        notify-send -u critical "Battery" "Your battery is running low."
        exit 0
    fi

    if [ "$capacity" -le 10 ]; then
        notify $TIMEOUT_LONG "" "" -i "$ICONS_CRITICAL/battery.png" \
            --hint="string:wired-tag:sys_notify"
    fi
}

charging_cable() {
    plugged_in="$(cat /sys/class/power_supply/AC/online)"

    if [ "$plugged_in" -eq 1 ]; then
        notify $TIMEOUT_LONG "" "" -i "$ICONS_DEFAULT/plug.png" \
            --hint="string:wired-tag:sys_notify"
        exit 0
    fi

    notify $TIMEOUT_LONG "" "" -i "$ICONS_DEFAULT/unplug.png" \
        --hint="string:wired-tag:sys_notify"
    exit 0
}

case "${OP}" in
audio_out) audio_out ;;
audio_in) audio_in ;;
backlight) backlight ;;
battery_level) battery_level ;;
charging_cable) charging_cable ;;
-h) fail ;;
*)
    fail
    exit 1
    ;;
esac
