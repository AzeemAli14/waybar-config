#!/usr/bin/env bash

# Icons (Nerdfonts)
cpu_icon="󰻠"
mem_icon="󰍛"

# Colors
cpu_color="#89dceb"
mem_color="#89dceb"

# Get CPU usage
cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}' | cut -d. -f1)
[ -z "$cpu_usage" ] && cpu_usage=0

# Get Memory usage
mem_data=$(free -m | awk '/Mem:/ {print $2,$3}')
mem_total=$(echo "$mem_data" | awk '{print $1}')
mem_used=$(echo "$mem_data" | awk '{print $2}')
mem_usage=$(( 100 * mem_used / mem_total ))

# Text for bar
bar_text="<span color='$cpu_color'>$cpu_icon</span> $cpu_usage% <span color='$mem_color'>$mem_icon</span> $mem_usage%"

# Output JSON
jq -nc \
    --arg text "$bar_text" \
    --arg tooltip "CPU: $cpu_usage% | RAM: $mem_usage%" \
    '{ text: $text, tooltip: $tooltip, class: "vitals" }'

