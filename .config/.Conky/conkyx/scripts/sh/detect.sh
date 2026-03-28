#!/bin/sh
###############################################################################
# detect.sh — Auto-detect hardware for Conky helper scripts
#
# Sourced by other scripts. Exports:
#   CONKY_NET_IFACE   — primary network interface (e.g., wlan0, wlo1, eth0)
#   CONKY_BAT_DEV     — battery device name (e.g., BAT0, BAT1) or empty
#   CONKY_CPU_CORES   — number of CPU cores
#   CONKY_THERMAL     — thermal zone path for CPU temp
###############################################################################

# Allow env overrides
: "${CONKY_NET_IFACE:=}"
: "${CONKY_BAT_DEV:=}"
: "${CONKY_CPU_CORES:=}"
: "${CONKY_THERMAL:=}"

# --- Network interface ---
if [ -z "$CONKY_NET_IFACE" ]; then
    # Prefer wireless, then first non-lo interface
    for _iface in /sys/class/net/*/wireless; do
        if [ -d "$_iface" ]; then
            CONKY_NET_IFACE="$(basename "$(dirname "$_iface")")"
            break
        fi
    done
    if [ -z "$CONKY_NET_IFACE" ]; then
        for _iface in /sys/class/net/*; do
            _name="$(basename "$_iface")"
            case "$_name" in lo) continue ;; esac
            # Prefer interfaces that are UP
            if [ -f "$_iface/operstate" ]; then
                _state="$(cat "$_iface/operstate" 2>/dev/null)"
                if [ "$_state" = "up" ]; then
                    CONKY_NET_IFACE="$_name"
                    break
                fi
            fi
            # Fallback to first non-lo
            [ -z "$CONKY_NET_IFACE" ] && CONKY_NET_IFACE="$_name"
        done
    fi
fi

# --- Battery ---
if [ -z "$CONKY_BAT_DEV" ]; then
    for _bat in /sys/class/power_supply/BAT*; do
        if [ -d "$_bat" ]; then
            CONKY_BAT_DEV="$(basename "$_bat")"
            break
        fi
    done
fi

# --- CPU cores ---
if [ -z "$CONKY_CPU_CORES" ]; then
    CONKY_CPU_CORES="$(grep -c ^processor /proc/cpuinfo 2>/dev/null || echo 1)"
fi

# --- Thermal zone ---
if [ -z "$CONKY_THERMAL" ]; then
    for _tz in /sys/class/thermal/thermal_zone*; do
        if [ -f "$_tz/type" ]; then
            _type="$(cat "$_tz/type" 2>/dev/null)"
            case "$_type" in
                cpu-thermal|coretemp|x86_pkg_temp)
                    CONKY_THERMAL="$_tz"
                    break
                    ;;
            esac
        fi
    done
    # Fallback to zone0
    [ -z "$CONKY_THERMAL" ] && [ -d /sys/class/thermal/thermal_zone0 ] && \
        CONKY_THERMAL="/sys/class/thermal/thermal_zone0"
fi

export CONKY_NET_IFACE CONKY_BAT_DEV CONKY_CPU_CORES CONKY_THERMAL
