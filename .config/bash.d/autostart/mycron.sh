#!/usr/bin/env bash
#
# mycron.sh – a simple cron replacement in pure Bash
#

set -u -o pipefail
shopt -s nullglob

readonly CONFIG_DIR="${HOME}/.config/bash.d/data/mycron"
readonly LOCK_FILE="/tmp/mycron.pid"

# ensure config dir exists
mkdir -p "${CONFIG_DIR}" || {
  echo "Error: cannot create ${CONFIG_DIR}" >&2
  exit 1
}

# single‐instance lock
if [[ -f "${LOCK_FILE}" ]]; then
  existing_pid=$(< "${LOCK_FILE}")
  if kill -0 "${existing_pid}" 2>/dev/null; then
    echo "mycron.sh already running (PID ${existing_pid}), exiting." >&2
    exit 1
  else
    rm -f "${LOCK_FILE}"
  fi
fi
echo $$ > "${LOCK_FILE}"
trap 'rm -f "${LOCK_FILE}"' EXIT

# match one cron‐style field ($1) against the current value ($2)
matches_field() {
  local field="$1" current="$2" minval="$3" name="$4"
  [[ "$field" == "*" ]] && return 0
  IFS=',' read -ra parts <<< "$field"
  for elt in "${parts[@]}"; do
    if [[ $elt =~ ^\*\/([0-9]+)$ ]]; then
      local step=${BASH_REMATCH[1]}
      (( (current - minval) % step == 0 )) && return 0
    elif [[ $elt =~ ^([0-9]+)-([0-9]+)$ ]]; then
      local start=${BASH_REMATCH[1]} end=${BASH_REMATCH[2]}
      (( current >= start && current <= end )) && return 0
    elif [[ $elt =~ ^[0-9]+$ ]]; then
      (( current == elt )) && return 0
    else
      echo "Warning: invalid ${name} element '${elt}'" >&2
    fi
  done
  return 1
}

# main loop
while true; do
  # ←--- **NO SPACES** around the = here:
  current_minute=$((10#$(date +%M)))
  current_hour=$((10#$(date +%H)))
  current_dom=$((10#$(date +%d)))
  current_mon=$((10#$(date +%m)))
  current_dow=$((10#$(date +%w)))

  for cfg in "${CONFIG_DIR}"/*; do
    [[ -f $cfg ]] || continue
    while IFS= read -r raw || [[ -n $raw ]]; do
      line="${raw#"${raw%%[![:space:]]*}"}"
      [[ -z $line || ${line:0:1} == "#" ]] && continue

      cron_re='^([^[:space:]]+)[[:space:]]+([^[:space:]]+)[[:space:]]+([^[:space:]]+)[[:space:]]+([^[:space:]]+)[[:space:]]+([^[:space:]]+)[[:space:]]+(.+)$'
      if [[ $line =~ $cron_re ]]; then
        # ←--- **NO SPACES** around the = here, either
        minute_f="${BASH_REMATCH[1]}"
        hour_f="${BASH_REMATCH[2]}"
        dom_f="${BASH_REMATCH[3]}"
        mon_f="${BASH_REMATCH[4]}"
        dow_f="${BASH_REMATCH[5]}"
        cmd="${BASH_REMATCH[6]}"

        if matches_field "$minute_f" "$current_minute" 0 "minute" \
         && matches_field "$hour_f"   "$current_hour"   0 "hour" \
         && matches_field "$dom_f"    "$current_dom"    1 "day-of-month" \
         && matches_field "$mon_f"    "$current_mon"    1 "month" \
         && matches_field "$dow_f"    "$current_dow"    0 "day-of-week"
        then
          ( bash -c "$cmd" ) &
        fi
      else
        echo "Skipping invalid line in $cfg: $raw" >&2
      fi
    done < "$cfg"
  done

  # sleep to the top of the next minute
  sec=$((10#$(date +%S)))
  sleep $((60 - sec))
done
