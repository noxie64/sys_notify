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

fail() {
    echo "$HELP"
}

ICONS_DEFAULT="$HOME/.config/wired/sys_notify/icons_default"
ICONS_CRITICAL="$HOME/.config/wired/sys_notify/icons_critical"
audio_out() {
    wpctl_output="$(wpctl get-volume @DEFAULT_SINK@)"

    if [ "$(echo "$wpctl_output" | grep -oF \[MUTED\])" = \[MUTED\] ]; then
        notify-send "" "" --hint="string:wired-tag:sys_notify" \
            -i "$ICONS_DEFAULT"/mute.png -t 900
        exit 0
    fi

    volume="$(bc -l <<<"scale=0; ($(echo "$wpctl_output" | grep -oE "[[:digit:]]{0,2}\.[[:digit:]]{2}") * 100) / 1")"

    if [ "$volume" = "" ]; then
        notify-send "" "" --hint="string:wired-tag:sys_notify" \
            -i "$ICONS_DEFAULT"/unmute.png -t 900
        exit 0
    fi

    notify-send "" "$volume" --hint="string:wired-tag:sys_notify" \
        -i "$ICONS_DEFAULT"/volume_change.png -h int:value:"$volume" -t 1100
}

audio_in() {
    wpctl_output="$(wpctl get-volume @DEFAULT_SOURCE@)"

    if [ "$(echo "$wpctl_output" | grep -oF \[MUTED\])" = \[MUTED\] ]; then
        notify-send "" "" --hint="string:wired-tag:sys_notify" \
            -i "$ICONS_DEFAULT"/mic_mute.png -t 900
        exit 0
    fi

    notify-send "" "$volume" --hint="string:wired-tag:sys_notify" \
        -i "$ICONS_DEFAULT"/mic.png
}

backlight() {
    brightness="$(brightnessctl info | grep -oE "([[:digit:]]{1,3}%)" | grep -oE "[[:digit:]]{1,3}")"

    notify-send "" "$brightness" --hint="string:wired-tag:sys_notify" \
        -i "$ICONS_DEFAULT"/light_full.png -h int:value:"$brightness" -t 1100

}

battery_level() {
    capacity="$(cat /sys/class/power_supply/BAT0/capacity)"

    if [ "$capacity" -lt 20 ] && [ "$capacity" -gt 10 ]; then
        notify-send -u critical "Battery" "Your battery is running low."
        exit 0
    fi

    if [ "$capacity" -le 10 ]; then
        notify-send "" "" -i "$ICONS_CRITICAL/battery.png)" \
            --hint="string:wired-tag:sys_notify"
    fi
}

charging_cable() {
    echo 'Cable'
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
