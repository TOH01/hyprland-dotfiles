#!/bin/bash

LOCATION="${WEATHER_LOCATION:-Wandlitz}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
CACHE_FILE="$CACHE_DIR/waybar-weather"
URL="${WEATHER_URL:-https://wttr.in/${LOCATION}?format=%t+%C}"

sanitize_weather() {
    local weather="$1"

    weather="${weather//$'\r'/}"
    weather="${weather//$'\n'/ }"
    weather="${weather//+/ }"

    printf '%s' "$weather" | sed 's/[[:space:]][[:space:]]*/ /g; s/^ //; s/ $//'
}

is_valid_weather() {
    local weather="$1"

    [[ -n "$weather" ]] || return 1
    [[ "$weather" != *"<"* ]] || return 1
    [[ "$weather" != *">"* ]] || return 1
    [[ "$weather" != *"Unknown location"* ]] || return 1
    [[ "$weather" != *"Sorry"* ]] || return 1
    [[ "$weather" != *"upstream connect error"* ]] || return 1
    [[ "$weather" =~ ^[+-]?[0-9]+([.][0-9]+)?°[CF]([[:space:]].+)?$ ]]
}

mkdir -p "$CACHE_DIR"

weather="$(curl -fsS --max-time 5 "$URL" 2>/dev/null || true)"
weather="$(sanitize_weather "$weather")"

if is_valid_weather "$weather"; then
    printf '%s\n' "$weather" > "$CACHE_FILE"
    printf '%s\n' "$weather"
    exit 0
fi

if [[ -s "$CACHE_FILE" ]]; then
    cached_weather="$(sanitize_weather "$(cat "$CACHE_FILE")")"

    if is_valid_weather "$cached_weather"; then
        printf '%s\n' "$cached_weather"
        exit 0
    fi
fi

printf '%s\n' "Weather unavailable"
