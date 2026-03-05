#!/usr/bin/env bash

# Icons (Nerdfonts)
clock_icon="󰅐"
calendar_icon="󰃭"

# Colors (Catppuccin Mocha)
clock_color="#f5c2e7"    # Pink
calendar_color="#89b4fa" # Blue
border_color="#6c7086"   # Surface1

# Current time and date
time_text=$(date +"%I:%M %p")
date_header=$(date +"%A, %d %B %Y")

# Highlight today's date in calendar
today=$(date +%e | sed 's/ //g')
calendar_raw=$(cal --color=never)
# We only want to highlight in the date section, not headers
calendar_formatted=$(echo "$calendar_raw" | sed -E "3,\$s/(^| )($today)( |$)/\\1<span background='$clock_color' color='#11111b' weight='bold'>\\2<\/span>\\3/g")

# Build Tooltip
n=$'\n'
tooltip="<span size='large' weight='bold' foreground='$calendar_color'>$calendar_icon  $date_header</span>$n"
tooltip+="<span foreground='$border_color'>━━━━━━━━━━━━━━━━━━━━━━━━━━━━</span>$n"
tooltip+="<tt><small>$calendar_formatted</small></tt>"

# Output JSON using jq
jq -nc \
    --arg text "$clock_icon $time_text" \
    --arg tooltip "$tooltip" \
    '{ text: $text, tooltip: $tooltip, class: "schedule" }'
