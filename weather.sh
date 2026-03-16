#!/usr/bin/env bash

# Default icon + temp while loading
default_icon="󰖐"
default_output="{\"text\":\"$default_icon 0°C\",\"tooltip\":\"Loading weather...\"}"

# Load .env
if [ -f "$HOME/.config/waybar/.env" ]; then
    source "$HOME/.config/waybar/.env"
else
    echo '{"text":"No .env","tooltip":"Create ~/.config/waybar/.env"}'
    exit 1
fi

API="$WEATHER_API_KEY"
CITY="$WEATHER_CITY"
CITY_ENCODED=$(echo "$CITY" | jq -sRr @uri)

# Cache setup
CACHE_DIR="$HOME/.cache/waybar"
CACHE_FILE="$CACHE_DIR/weather.json"
mkdir -p "$CACHE_DIR"

# Fetch current weather and forecast
new_data=$(curl -s --connect-timeout 3 \
"https://api.openweathermap.org/data/2.5/weather?q=${CITY_ENCODED}&units=metric&appid=${API}")

new_forecast=$(curl -s --connect-timeout 3 \
"https://api.openweathermap.org/data/2.5/forecast?q=${CITY_ENCODED}&units=metric&appid=${API}")

# Logic: Use new data if successful, otherwise fallback to cache
if [ -n "$new_data" ] && [ "$(echo "$new_data" | jq -r '.cod')" == "200" ]; then
    data="$new_data"
    forecast="$new_forecast"
    # Save to cache for offline view
    echo "{\"data\": $data, \"forecast\": $forecast}" > "$CACHE_FILE"
elif [ -f "$CACHE_FILE" ]; then
    # API failed, but we have a cache
    data=$(jq -c '.data' "$CACHE_FILE")
    forecast=$(jq -c '.forecast' "$CACHE_FILE")
    offline_tag=" (Offline)"
else
    # No API and no cache → show default
    echo "$default_output"
    exit 0
fi

# ---------------- PARSE VALUES ----------------
temp_raw=$(echo "$data" | jq -r '.main.temp')
feels_raw=$(echo "$data" | jq -r '.main.feels_like')

# Extract High/Low from forecast (next 24 hours)
if [ -n "$forecast" ] && [ "$(echo "$forecast" | jq -r '.cod')" == "200" ]; then
    temp_max_raw=$(echo "$forecast" | jq -r '[.list[0,1,2,3,4,5,6,7].main.temp_max] | max')
    temp_min_raw=$(echo "$forecast" | jq -r '[.list[0,1,2,3,4,5,6,7].main.temp_min] | min')
else
    temp_max_raw=$(echo "$data" | jq -r '.main.temp_max')
    temp_min_raw=$(echo "$data" | jq -r '.main.temp_min')
fi

humidity=$(echo "$data" | jq -r '.main.humidity')
wind_ms=$(echo "$data" | jq -r '.wind.speed')
clouds=$(echo "$data" | jq -r '.clouds.all')
desc=$(echo "$data" | jq -r '.weather[0].description')
icon_code=$(echo "$data" | jq -r '.weather[0].icon')
sunrise_ts=$(echo "$data" | jq -r '.sys.sunrise')
sunset_ts=$(echo "$data" | jq -r '.sys.sunset')

# Convert wind (ms to kmph)
wind_kmph=$(awk "BEGIN {printf \"%.0f\", $wind_ms * 3.6}")

# Format values for alignment
temp=$(printf "%.0f" "$temp_raw")
feels_p=$(printf "%.1f" "$feels_raw")
temp_max_p=$(printf "%.1f" "$temp_max_raw")
temp_min_p=$(printf "%.1f" "$temp_min_raw")
humidity_p="$humidity"
clouds_p="$clouds"
wind_p="$wind_kmph"

# Convert sunrise/sunset to local time
sunrise=$(date -d @"$sunrise_ts" +"%I:%M %p")
sunset=$(date -d @"$sunset_ts" +"%I:%M %p")

# ---------------- ICON MAPPING ----------------
case "$icon_code" in
  01d) icon="󰖙" ;;
  01n) icon="󰖔" ;;
  02d) icon="󰖕" ;;
  02n) icon="󰼱" ;;
  03*|04*) icon="󰖐" ;;
  09*) icon="󰖗" ;;
  10d) icon="󰖗" ;;
  10n) icon="󰼳" ;;
  11*) icon="󰖓" ;;
  13*) icon="󰖖" ;;
  50*) icon="󰖑" ;;
  *) icon="󰖐" ;;
esac

# ---------------- TOOLTIP ----------------
n=$'\n'
# Helper for aligned rows
row() {
    local icon=$1
    local label=$2
    local value=$3
    # Padding the label to exactly 9 characters. 
    # Everything inside <tt> for monospace alignment.
    local p_label=$(printf "%-9s" "$label")
    echo "<tt><b>$icon $p_label</b>$value</tt>"
}

# Using Pango markup for beauty
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
