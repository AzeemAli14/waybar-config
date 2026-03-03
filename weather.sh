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
tooltip="$icon  ${desc^}\n\
☁ Clouds: ${clouds}%\n\
  Humid:  ${humidity}%\n\
󰔏  High:   ${temp_max}°C\n\
󰔏  Low:    ${temp_min}°C\n\
  Feels:  ${feels}°C\n\
༄ Wind:   ${wind_kmph} km/h\n\
  Rise:   ${sunrise}\n\
  Set:    ${sunset}"

# ---------------- OUTPUT ----------------
echo "{\"text\":\"$icon ${temp}°C\",\"tooltip\":\"$tooltip\"}"