#!/usr/bin/env bash

# Icons (Nerdfonts)
vitals_icon="" # Pulse icon for header
cpu_icon=""    # CPU Chip icon
mem_icon=""    # RAM/Microchip icon
gpu_icon="󰢮"
swap_icon="󰓡"

# Colors (Catppuccin Mocha)
vitals_color="#cba6f7" # Mauve
cpu_color="#89b4fa"    # Blue
mem_color="#a6e3a1"    # Green
gpu_color="#fab387"    # Peach
swap_color="#f5c2e7"   # Pink
border_color="#6c7086" # Surface1

# Function to generate a progress bar
get_bar() {
    local percent=$1
    local color=$2
    local bar_size=15
    local filled=$(( (percent * bar_size) / 100 ))
    local empty=$(( bar_size - filled ))
    
    local bar="<span color='$color'>"
    for ((i=0; i<filled; i++)); do bar+="━"; done
    bar+="</span><span color='$border_color'>"
    for ((i=0; i<empty; i++)); do bar+="─"; done
    bar+="</span>"
    echo "$bar"
}

# Get CPU usage
cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}' | cut -d. -f1)
[ -z "$cpu_usage" ] && cpu_usage=0
cpu_bar=$(get_bar "$cpu_usage" "$cpu_color")

# Get Memory usage
mem_data=$(free -m | awk '/Mem:/ {print $2,$3}')
mem_total=$(echo "$mem_data" | awk '{print $1}')
mem_used=$(echo "$mem_data" | awk '{print $2}')
mem_usage=$(( 100 * mem_used / mem_total ))
mem_bar=$(get_bar "$mem_usage" "$mem_color")

# Get Swap usage
swap_data=$(free -m | awk '/Swap:/ {print $2,$3}')
swap_total=$(echo "$swap_data" | awk '{print $1}')
swap_used=$(echo "$swap_data" | awk '{print $2}')
if [ "$swap_total" -gt 0 ]; then
    swap_usage=$(( 100 * swap_used / swap_total ))
else
    swap_usage=0
fi
swap_bar=$(get_bar "$swap_usage" "$swap_color")

# Get GPU usage (Intel fallback)
gpu_usage="N/A"
gpu_bar=$(get_bar 0 "$gpu_color")

# --- FIXED WIDTH LOGIC ---
# Pad to 2 characters so "9%" becomes " 9%" and aligns with "10%"
cpu_pad=$(printf "%2d" "$cpu_usage")
mem_pad=$(printf "%2d" "$mem_usage")

# Text for bar
bar_text="<span color='$cpu_color'>$cpu_icon</span> $cpu_pad% <span color='$mem_color'>$mem_icon</span> $mem_pad%"

# Build Beautiful Tooltip with fixed-width alignment
n=$'\n'

# Helper for aligned rows using fixed-width spaces
# We use <tt> (monospace) for the whole row to ensure alignment
row() {
    local label=$1
    local value=$2
    local bar=$3
    local color=$4
    local icon=$5
    
    # Label is padded to 13 characters
    local padded_label=$(printf "%-13s" "$label")
    echo "<tt><span foreground='$color'>$icon $padded_label</span> $value</tt>$n<tt>$bar</tt>"
}

tooltip="<span size='large' weight='bold' foreground='$vitals_color'>$vitals_icon  System Vitals</span>$n"
tooltip+="<span foreground='$border_color'>━━━━━━━━━━━━━━━━━━━━━━━━━━━━</span>$n"

# Add rows
tooltip+=$(row "CPU Usage" "$cpu_usage%" "$cpu_bar" "$cpu_color" "$cpu_icon")$n
tooltip+=$(row "Memory Used" "$mem_used/$mem_total MiB ($mem_usage%)" "$mem_bar" "$mem_color" "$mem_icon")$n
tooltip+=$(row "Swap Used" "$swap_used/$swap_total MiB ($swap_usage%)" "$swap_bar" "$swap_color" "$swap_icon")$n
tooltip+=$(row "GPU Usage" "$gpu_usage" "$gpu_bar" "$gpu_color" "$gpu_icon")

# Output JSON for Waybar using jq
jq -nc \
    --arg text "$bar_text" \
    --arg tooltip "$tooltip" \
    '{ text: $text, tooltip: $tooltip, class: "vitals" }'
