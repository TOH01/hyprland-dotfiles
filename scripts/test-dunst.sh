#!/usr/bin/env bash

set -euo pipefail

send_notification() {
    local urgency="$1"
    local title="$2"
    local body="$3"

    notify-send -u "${urgency}" "${title}" "${body}"
}

mode="${1:-demo}"

case "${mode}" in
    low)
        send_notification "low" "Low Notification" "This is a low-priority Dunst test notification."
        ;;
    normal)
        send_notification "normal" "Normal Notification" "This is a normal Dunst test notification."
        ;;
    critical)
        send_notification "critical" "Critical Notification" "This is a critical Dunst test notification."
        ;;
    demo)
        send_notification "low" "Low Notification" "This is a low-priority Dunst test notification."
        sleep 5
        send_notification "normal" "Normal Notification" "This is a normal Dunst test notification."
        sleep 5
        send_notification "critical" "Critical Notification" "This is a critical Dunst test notification."
        ;;
    -h|--help)
        cat <<'EOF'
Usage: ./scripts/test-dunst.sh [low|normal|critical|demo]

Examples:
  ./scripts/test-dunst.sh normal
  ./scripts/test-dunst.sh critical
  ./scripts/test-dunst.sh demo
EOF
        ;;
    *)
        printf 'Unknown mode: %s\n' "${mode}" >&2
        exit 1
        ;;
esac
