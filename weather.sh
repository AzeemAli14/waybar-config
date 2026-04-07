#!/usr/bin/env bash

# Default icon + temp while loading
default_icon="󰖐"
default_output="{\"text\":\"$default_icon 0°C\",\"tooltip\":\"Loading weather...\"}"

# Load .env for city
if [ -f "$HOME/.config/waybar/.env" ]; then
    source "$HOME/.config/waybar/.env"
else
    # Fallback city if .env is missing
    WEATHER_CITY="Lahore"
fi

CITY="$WEATHER_CITY"
CITY_ENCODED=$(echo -n "$CITY" | jq -sRr @uri)

# Cache setup
CACHE_DIR="$HOME/.cache/waybar"
CACHE_FILE="$CACHE_DIR/weather_wttr.json"
mkdir -p "$CACHE_DIR"

# Fetch weather from wttr.in (v2 JSON format)
new_data=$(curl -s -H "User-Agent: curl" --connect-timeout 10 "https://wttr.in/${CITY_ENCODED}?format=j1")

# Logic: Use new data if successful, otherwise fallback to cache
if [ -n "$new_data" ] && echo "$new_data" | jq -e '.current_condition[0]' >/dev/null 2>&1; then
    data="$new_data"
    echo "$data" > "$CACHE_FILE"
elif [ -f "$CACHE_FILE" ]; then
    data=$(cat "$CACHE_FILE")
    offline_tag=" (Offline)"
else
    echo "$default_output"
    exit 0
fi

# ---------------- PARSE VALUES ----------------
current=$(echo "$data" | jq -r '.current_condition[0]')
today=$(echo "$data" | jq -r '.weather[0]')

temp=$(echo "$current" | jq -r '.temp_C')
feels_p=$(echo "$current" | jq -r '.FeelsLikeC')
temp_max_p=$(echo "$today" | jq -r '.maxtempC')
temp_min_p=$(echo "$today" | jq -r '.mintempC')
humidity_p=$(echo "$current" | jq -r '.humidity')
wind_p=$(echo "$current" | jq -r '.windspeedKmph')
clouds_p=$(echo "$current" | jq -r '.cloudcover')
desc=$(echo "$current" | jq -r '.weatherDesc[0].value')
weather_code=$(echo "$current" | jq -r '.weatherCode')

# Astronomy
sunrise=$(echo "$today" | jq -r '.astronomy[0].sunrise')
sunset=$(echo "$today" | jq -r '.astronomy[0].sunset')

# ---------------- ICON MAPPING (WWO Codes) ----------------
# Mapping based on: https://www.worldweatheronline.com/feed/wwo_condition_codes.xml
case "$weather_code" in
    113) # Sunny / Clear
        # We don't easily have day/night info here without extra logic, 
        # but wttr.in description often says "Clear" for night.
        if [[ "$desc" == "Clear" ]]; then icon="󰖔"; else icon="󰖙"; fi ;;
    116) icon="󰖕" ;; # Partly Cloudy
    119) icon="󰖐" ;; # Cloudy
    122) icon="󰖐" ;; # Overcast
    143|248|260) icon="󰖑" ;; # Fog / Mist
    176|263|266|281|284|293|296|299|302|305|308|311|314) icon="󰖗" ;; # Rain / Drizzle
    179|182|185|227|230|323|326|329|332|335|338|350|368|371|374|377) icon="󰖖" ;; # Snow / Sleet
    200|386|389|392|395) icon="󰖓" ;; # Thunderstorm
    *) icon="󰖐" ;;
esac

# ---------------- TOOLTIP ----------------
n=$'\n'
row() {
    local icon=$1
    local label=$2
    local value=$3
    local p_label=$(printf "%-9s" "$label")
    echo "<tt><b>$icon $p_label</b>$value</tt>"
}

tooltip="<span size='13000' foreground='#89dceb'>$icon   <b>${desc^}$offline_tag</b></span>$n"
tooltip+="<span foreground='#6c7086'>━━━━━━━━━━━━━━━━━━━━━</span>$n"
tooltip+="$(row "󰈸" "Feels:" "${feels_p}°C")$n"
tooltip+="$(row "󱃂" "High:"  "${temp_max_p}°C")$n"
tooltip+="$(row "󱃃" "Low:"   "${temp_min_p}°C")$n"
tooltip+="<span foreground='#6c7086'>━━━━━━━━━━━━━━━━━━━━━</span>$n"
tooltip+="$(row "󰖐" "Clouds:" "${clouds_p}%")$n"
tooltip+="$(row "󰖖" "Humid:"  "${humidity_p}%")$n"
tooltip+="$(row "󰖝" "Wind:"   "${wind_p} km/h")$n"
tooltip+="<span foreground='#6c7086'>━━━━━━━━━━━━━━━━━━━━━</span>$n"
tooltip+="$(row "󰖙" "Rise:"   "${sunrise}")$n"
tooltip+="$(row "󰖔" "Set:"    "${sunset}")"

# ---------------- OUTPUT ----------------
jq -nc \
    --arg text "$icon ${temp}°C" \
    --arg tooltip "$tooltip" \
    '{ text: $text, tooltip: $tooltip }'
