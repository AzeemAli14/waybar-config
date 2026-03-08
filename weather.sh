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

# Fetch weather (fast timeout so it doesn't hang at boot)
data=$(curl -s --connect-timeout 3 \
"https://api.openweathermap.org/data/2.5/weather?q=${CITY}&units=metric&appid=${API}")

# If API fails → show default
if [ -z "$data" ] || [ "$(echo "$data" | jq -r '.cod')" != "200" ]; then
    echo "$default_output"
    exit 0
fi

# ---------------- PARSE VALUES ----------------
temp=$(echo "$data" | jq -r '.main.temp | round')
feels=$(echo "$data" | jq -r '.main.feels_like | round')
temp_min=$(echo "$data" | jq -r '.main.temp_min | round')
temp_max=$(echo "$data" | jq -r '.main.temp_max | round')
humidity=$(echo "$data" | jq -r '.main.humidity')
wind_ms=$(echo "$data" | jq -r '.wind.speed')
clouds=$(echo "$data" | jq -r '.clouds.all')
desc=$(echo "$data" | jq -r '.weather[0].description')
icon_code=$(echo "$data" | jq -r '.weather[0].icon')
sunrise_ts=$(echo "$data" | jq -r '.sys.sunrise')
sunset_ts=$(echo "$data" | jq -r '.sys.sunset')

# Convert wind
wind_kmph=$(awk "BEGIN {printf \"%.0f\", $wind_ms * 3.6}")

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
# Pad values for better alignment
printf -v feels_p "%3s" "$feels"
printf -v temp_max_p "%3s" "$temp_max"
printf -v temp_min_p "%3s" "$temp_min"
printf -v clouds_p "%3s" "$clouds"
printf -v humidity_p "%3s" "$humidity"
printf -v wind_p "%3s" "$wind_kmph"

# Helper for aligned rows
n=$'\n'
row() {
    local icon=$1
    local label=$2
    local value=$3
    # Reduced label padding to 8 chars and icon gap to 2 spaces.
    local p_label=$(printf "%-9s" "$label")
    # Removed the extra space after the label for a tighter look.
    echo "<tt><b>$icon  $p_label</b>$value</tt>"
}

# Using Pango markup for beauty
tooltip="<span size='13000' foreground='#89dceb'>$icon   <b>${desc^}</b></span>$n"
tooltip+="<span foreground='#6c7086'>━━━━━━━━━━━━━━━━━━━━━</span>$n"
tooltip+="$(row "" "Feels:" "${feels_p}°C")$n"
tooltip+="$(row "" "High:"  "${temp_max_p}°C")$n"
tooltip+="$(row "" "Low:"   "${temp_min_p}°C")$n"
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