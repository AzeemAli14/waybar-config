#!/usr/bin/env bash

# Default icon + temp while loading
default_icon="󰖐"
default_output="{\"text\":\"$default_icon 0°C\",\"tooltip\":\"Loading weather...\"}"

# Cache setup
CACHE_DIR="$HOME/.cache/waybar"
LOCATION_CACHE="$CACHE_DIR/location.json"
WEATHER_CACHE="$CACHE_DIR/weather_meteo.json"
mkdir -p "$CACHE_DIR"

# 1. GET LOCATION (IP-API)
# Cache location for 24 hours (86400 seconds)
fetch_location() {
    local loc_data
    loc_data=$(curl -s --connect-timeout 5 "http://ip-api.com/json/")
    if [[ $(echo "$loc_data" | jq -r '.status') == "success" ]]; then
        echo "$loc_data" > "$LOCATION_CACHE"
        echo "$loc_data"
    else
        return 1
    fi
}

if [[ -f "$LOCATION_CACHE" ]]; then
    # If cache is older than 24h, try to refresh
    if [[ $(find "$LOCATION_CACHE" -mmin +1440) ]]; then
        location=$(fetch_location || cat "$LOCATION_CACHE")
    else
        location=$(cat "$LOCATION_CACHE")
    fi
else
    location=$(fetch_location)
fi

# Fallback if location fails
if [[ -z "$location" ]]; then
    lat="31.52"
    lon="74.35"
    city="Unknown"
else
    lat=$(echo "$location" | jq -r '.lat')
    lon=$(echo "$location" | jq -r '.lon')
    city=$(echo "$location" | jq -r '.city')
    country_code=$(echo "$location" | jq -r '.countryCode')
    location_str="$city, $country_code"
fi

# 2. FETCH WEATHER (Open-Meteo)
METEO_URL="https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,weather_code,cloud_cover,wind_speed_10m&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset&timezone=auto"

new_data=$(curl -s --connect-timeout 10 "$METEO_URL")

if [ -n "$new_data" ] && echo "$new_data" | jq -e '.current' >/dev/null 2>&1; then
    data="$new_data"
    echo "$data" > "$WEATHER_CACHE"
elif [ -f "$WEATHER_CACHE" ]; then
    data=$(cat "$WEATHER_CACHE")
    offline_tag=" (Offline)"
else
    echo "$default_output"
    exit 0
fi

# 3. PARSE VALUES
current=$(echo "$data" | jq -r '.current')
daily=$(echo "$data" | jq -r '.daily')

temp=$(echo "$current" | jq -r '.temperature_2m' | awk '{print int($1 + 0.5)}')
feels_p=$(echo "$current" | jq -r '.apparent_temperature' | awk '{print int($1 + 0.5)}')
temp_max_p=$(echo "$daily" | jq -r '.temperature_2m_max[0]' | awk '{print int($1 + 0.5)}')
temp_min_p=$(echo "$daily" | jq -r '.temperature_2m_min[0]' | awk '{print int($1 + 0.5)}')
humidity_p=$(echo "$current" | jq -r '.relative_humidity_2m')
wind_p=$(echo "$current" | jq -r '.wind_speed_10m' | awk '{print int($1 + 0.5)}')
clouds_p=$(echo "$current" | jq -r '.cloud_cover')
is_day=$(echo "$current" | jq -r '.is_day')
wmo_code=$(echo "$current" | jq -r '.weather_code')

# Sunrise/Sunset (convert from ISO8601 to 12h format)
sunrise_raw=$(echo "$daily" | jq -r '.sunrise[0]' | cut -d'T' -f2)
sunset_raw=$(echo "$daily" | jq -r '.sunset[0]' | cut -d'T' -f2)
sunrise=$(date -d "$sunrise_raw" +"%I:%M %p")
sunset=$(date -d "$sunset_raw" +"%I:%M %p")

# 4. ICON & DESCRIPTION MAPPING (WMO Codes)
# https://open-meteo.com/en/docs
case "$wmo_code" in
    0) desc="Clear Sky"; if [[ "$is_day" == "1" ]]; then icon="󰖙"; else icon="󰖔"; fi ;;
    1|2|3) desc="Partly Cloudy"; if [[ "$is_day" == "1" ]]; then icon="󰖕"; else icon="󰖔"; fi ;;
    45|48) desc="Foggy"; icon="󰖑" ;;
    51|53|55) desc="Drizzle"; icon="󰖗" ;;
    61|63|65) desc="Rain"; icon="󰖗" ;;
    71|73|75) desc="Snow"; icon="󰖖" ;;
    77) desc="Snow Grains"; icon="󰖖" ;;
    80|81|82) desc="Rain Showers"; icon="󰖗" ;;
    85|86) desc="Snow Showers"; icon="󰖖" ;;
    95|96|99) desc="Thunderstorm"; icon="󰖓" ;;
    *) desc="Cloudy"; icon="󰖐" ;;
esac

# 5. TOOLTIP
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
tooltip+="$(row "󰍎" "Loc:"    "$location_str")$n"
tooltip+="<span foreground='#6c7086'>━━━━━━━━━━━━━━━━━━━━━</span>$n"
tooltip+="$(row "󰈸" "Feels:" "${feels_p}°C")$n"
tooltip+="$(row "󱃂" "High:"  "${temp_max_p}°C")$n"
tooltip+="$(row "󱃃" "Low:"   "${temp_min_p}°C")$n"
tooltip+="<span foreground='#6c7086'>━━━━━━━━━━━━━━━━━━━━━</span>$n"
tooltip+="$(row "󰖐" "Clouds:" "${clouds_p}%")$n"
tooltip+="$(row "󰖜" "Humid:"  "${humidity_p}%")$n"
tooltip+="$(row "󰖝" "Wind:"   "${wind_p} km/h")$n"
tooltip+="<span foreground='#6c7086'>━━━━━━━━━━━━━━━━━━━━━</span>$n"
tooltip+="$(row "󰖙" "Rise:"   "${sunrise}")$n"
tooltip+="$(row "󰖔" "Set:"    "${sunset}")"

# 6. OUTPUT
jq -nc \
    --arg text "$icon ${temp}°C" \
    --arg tooltip "$tooltip" \
    '{ text: $text, tooltip: $tooltip }'
