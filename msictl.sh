#!/bin/bash
#
# msictl - simple CLI wrapper for the msi-ec kernel driver
# Usage: msictl <command> [value]
#
# Requires: msi-ec driver loaded (check with: cat /sys/devices/platform/msi-ec/shift_mode)

EC=/sys/devices/platform/msi-ec

# find the battery power_supply name automatically (BAT0, BAT1, etc.)
BAT=$(ls /sys/class/power_supply/ 2>/dev/null | grep -i '^BAT' | head -n1)

usage() {
    cat <<EOF
msictl - control MSI laptop settings from the terminal

Usage:
  msictl status                 Show current mode, temps, fan speed, battery limit
  msictl mode <value>           Set shift mode (see: msictl modes)
  msictl modes                  List available shift modes
  msictl fanmode <value>        Set fan mode (see: msictl fanmodes)
  msictl fanmodes                List available fan modes
  msictl boost <on|off>         Toggle cooler boost
  msictl battery <start> <end>  Set battery charge threshold (e.g. msictl battery 0 80)
  msictl kbd <0-3>               Set keyboard backlight (0=off,1=on,2=half,3=full)
  msictl webcam <on|off>          Toggle webcam
  msictl fnkey <left|right>      Set Fn key position

Examples:
  msictl mode comfort
  msictl battery 0 80
  msictl boost on
EOF
}

need_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "This command needs sudo. Re-run as: sudo msictl $*"
        exit 1
    fi
}

check_driver() {
    if [ ! -d "$EC" ]; then
        echo "Error: msi-ec driver not found at $EC"
        echo "Is the driver installed and loaded? Check with: lsmod | grep msi_ec"
        exit 1
    fi
}

check_driver

cmd="$1"
shift

case "$cmd" in
    status)
        echo "Shift mode:     $(cat $EC/shift_mode 2>/dev/null)"
        echo "Fan mode:       $(cat $EC/fan_mode 2>/dev/null)"
        echo "Cooler boost:   $(cat $EC/cooler_boost 2>/dev/null)"
        echo "CPU temp:       $(cat $EC/cpu/realtime_temperature 2>/dev/null)°C"
        echo "CPU fan speed:  $(cat $EC/cpu/realtime_fan_speed 2>/dev/null)%"
        echo "GPU temp:       $(cat $EC/gpu/realtime_temperature 2>/dev/null)°C"
        echo "GPU fan speed:  $(cat $EC/gpu/realtime_fan_speed 2>/dev/null)%"
        if [ -n "$BAT" ]; then
            echo "Battery:        $BAT"
            echo "  Charge start: $(cat /sys/class/power_supply/$BAT/charge_control_start_threshold 2>/dev/null)%"
            echo "  Charge end:   $(cat /sys/class/power_supply/$BAT/charge_control_end_threshold 2>/dev/null)%"
        fi
        ;;

    modes)
        cat "$EC/available_shift_modes" 2>/dev/null
        ;;

    fanmodes)
        cat "$EC/available_fan_modes" 2>/dev/null
        ;;

    mode)
        need_root "$cmd $*"
        val="$1"
        if [ -z "$val" ]; then
            echo "Usage: msictl mode <value>   (see: msictl modes)"
            exit 1
        fi
        echo "$val" > "$EC/shift_mode"
        echo "Shift mode set to: $(cat $EC/shift_mode)"
        ;;

    fanmode)
        need_root "$cmd $*"
        val="$1"
        if [ -z "$val" ]; then
            echo "Usage: msictl fanmode <value>   (see: msictl fanmodes)"
            exit 1
        fi
        echo "$val" > "$EC/fan_mode"
        echo "Fan mode set to: $(cat $EC/fan_mode)"
        ;;

    boost)
        need_root "$cmd $*"
        val="$1"
        if [ "$val" != "on" ] && [ "$val" != "off" ]; then
            echo "Usage: msictl boost <on|off>"
            exit 1
        fi
        echo "$val" > "$EC/cooler_boost"
        echo "Cooler boost: $(cat $EC/cooler_boost)"
        ;;

    battery)
        need_root "$cmd $*"
        start="$1"
        end="$2"
        if [ -z "$BAT" ]; then
            echo "Error: no battery found under /sys/class/power_supply/"
            exit 1
        fi
        if [ -z "$start" ] || [ -z "$end" ]; then
            echo "Usage: msictl battery <start> <end>   (e.g. msictl battery 0 80)"
            exit 1
        fi
        echo "$start" > "/sys/class/power_supply/$BAT/charge_control_start_threshold"
        echo "$end" > "/sys/class/power_supply/$BAT/charge_control_end_threshold"
        echo "Battery threshold set: start=$(cat /sys/class/power_supply/$BAT/charge_control_start_threshold)% end=$(cat /sys/class/power_supply/$BAT/charge_control_end_threshold)%"
        ;;

    kbd)
        need_root "$cmd $*"
        val="$1"
        led="/sys/class/leds/msiacpi::kbd_backlight/brightness"
        if [ -z "$val" ]; then
            echo "Usage: msictl kbd <0-3>   (0=off,1=on,2=half,3=full)"
            exit 1
        fi
        if [ ! -e "$led" ]; then
            echo "Error: keyboard backlight control not found at $led"
            exit 1
        fi
        echo "$val" > "$led"
        echo "Keyboard backlight set to: $(cat $led)"
        ;;

    webcam)
        need_root "$cmd $*"
        val="$1"
        if [ "$val" != "on" ] && [ "$val" != "off" ]; then
            echo "Usage: msictl webcam <on|off>"
            exit 1
        fi
        echo "$val" > "$EC/webcam"
        echo "Webcam: $(cat $EC/webcam)"
        ;;

    fnkey)
        need_root "$cmd $*"
        val="$1"
        if [ "$val" != "left" ] && [ "$val" != "right" ]; then
            echo "Usage: msictl fnkey <left|right>"
            exit 1
        fi
        echo "$val" > "$EC/fn_key"
        echo "Fn key position: $(cat $EC/fn_key)"
        ;;

    ""|help|-h|--help)
        usage
        ;;

    *)
        echo "Unknown command: $cmd"
        echo ""
        usage
        exit 1
        ;;
esac
