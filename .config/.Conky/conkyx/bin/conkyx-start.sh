#!/bin/sh
###############################################################################
# conkyx-start.sh — Start Conky with the conkyx config
#
# Usage: conkyx-start.sh [--stop] [--restart]
###############################################################################

# Resolve paths relative to this script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONKYX_DIR="$(dirname "$SCRIPT_DIR")"
CONKYRC="$CONKYX_DIR/config/conkyrc"
LOG_FILE="$HOME/.config/.Conky/conky.log"
MAX_LOG_ENTRIES=100

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $*" >> "$LOG_FILE"
}

rotate_log() {
    if [ -f "$LOG_FILE" ] && [ "$(wc -l < "$LOG_FILE")" -ge "$MAX_LOG_ENTRIES" ]; then
        tail -n $((MAX_LOG_ENTRIES / 2)) "$LOG_FILE" > "$LOG_FILE.tmp"
        mv "$LOG_FILE.tmp" "$LOG_FILE"
    fi
}

stop_conky() {
    if pgrep -x conky >/dev/null 2>&1; then
        pkill -x conky
        log "Stopped Conky"
    fi
}

start_conky() {
    if ! command -v conky >/dev/null 2>&1; then
        log "Error: conky not installed"
        echo "Error: conky not installed" >&2
        exit 1
    fi

    if [ ! -f "$CONKYRC" ]; then
        log "Error: config not found at $CONKYRC"
        echo "Error: config not found at $CONKYRC" >&2
        exit 1
    fi

    if pgrep -x conky >/dev/null 2>&1; then
        log "Conky is already running"
        echo "Conky is already running (use --restart to reload)"
        return 0
    fi

    mkdir -p "$(dirname "$LOG_FILE")"
    rotate_log
    log "Starting Conky"
    conky --config "$CONKYRC" -d
    log "Conky started"
}

trap 'stop_conky; exit 0' INT TERM

case "${1:-}" in
    --stop)    stop_conky ;;
    --restart) stop_conky; sleep 1; start_conky ;;
    *)         start_conky ;;
esac
