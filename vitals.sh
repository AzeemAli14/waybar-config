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
net_color="#f9e2af"    # Yellow
swap_color="#f5c2e7"   # Pink
border_color="#6c7086" # Surface1

# Icons for Network
down_icon="󰇚"
up_icon="󰕒"

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

# Get GPU usage (Hybrid support: NVIDIA + Intel/AMD)
gpu_usage=0
gpu_usage_display="N/A"

# 1. Try NVIDIA
if command -v nvidia-smi >/dev/null 2>&1; then
    nv_usage=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | head -n 1 2>/dev/null)
    if [[ -n "$nv_usage" && "$nv_usage" =~ ^[0-9]+$ ]]; then
        gpu_usage=$nv_usage
        gpu_usage_display="${nv_usage}%"
    fi
fi

# 2. Try Intel/AMD via sysfs
for card in /sys/class/drm/card*; do
    # Generic busy percent (AMD)
    if [ -f "$card/device/gpu_busy_percent" ]; then
        sys_usage=$(cat "$card/device/gpu_busy_percent" 2>/dev/null)
        if [[ -n "$sys_usage" && "$sys_usage" =~ ^[0-9]+$ ]]; then
            if [ "$sys_usage" -gt "$gpu_usage" ]; then
                gpu_usage=$sys_usage
                gpu_usage_display="${sys_usage}%"
            fi
        fi
    fi

    # Intel frequency-based fallback
    intel_path=""
    if [ -d "$card/gt/gt0" ]; then
        intel_path="$card/gt/gt0"
    elif [ -d "$card/device/gt/gt0" ]; then
        intel_path="$card/device/gt/gt0"
    fi

    if [ -n "$intel_path" ]; then
        curr=$(cat "$intel_path/rps_act_freq_mhz" 2>/dev/null || cat "${intel_path%/gt/gt0}/gt_act_freq_mhz" 2>/dev/null || cat "$intel_path/rps_cur_freq_mhz" 2>/dev/null)
        max=$(cat "$intel_path/rps_max_freq_mhz" 2>/dev/null || cat "${intel_path%/gt/gt0}/gt_max_freq_mhz" 2>/dev/null)
        min=$(cat "$intel_path/rps_min_freq_mhz" 2>/dev/null || cat "${intel_path%/gt/gt0}/gt_min_freq_mhz" 2>/dev/null)
        
        if [[ -n "$curr" && -n "$max" && -n "$min" && "$max" -gt "$min" ]]; then
            i_usage=$(( 100 * (curr - min) / (max - min) ))
            (( i_usage < 0 )) && i_usage=0
            (( i_usage > 100 )) && i_usage=100
            if [ "$i_usage" -gt "$gpu_usage" ]; then
                gpu_usage=$i_usage
                gpu_usage_display="${i_usage}%"
            fi
        fi
    fi
done
gpu_bar=$(get_bar "$gpu_usage" "$gpu_color")

# --- NETWORK CALCULATION ---
net_stats_file="/tmp/vitals_net_stats"
read_net_data() {
    awk 'NR > 2 && $1 != "lo:" {rx += $2; tx += $10} END {printf "%.0f %.0f", rx, tx}' /proc/net/dev
}

current_time=$(date +%s%N)
read rx_curr tx_curr <<< $(read_net_data)

if [ -f "$net_stats_file" ]; then
    read rx_prev tx_prev prev_time < "$net_stats_file"
    time_diff_ns=$(( current_time - prev_time ))
    time_diff=$(awk "BEGIN {print $time_diff_ns / 1000000000}")
    
    if (( $(awk "BEGIN {print ($time_diff > 0)}") )); then
        rx_speed=$(awk "BEGIN {print ($rx_curr - rx_prev) / $time_diff}")
        tx_speed=$(awk "BEGIN {print ($tx_curr - tx_prev) / $time_diff}")
    else
        rx_speed=0
        tx_speed=0
    fi
else
    rx_speed=0
    tx_speed=0
fi
echo "$rx_curr $tx_curr $current_time" > "$net_stats_file"

# Format speed helper
format_speed() {
    local bytes=$1
    if (( $(awk "BEGIN {print ($bytes < 1024)}") )); then
        printf "%.1f B/s" "$bytes"
    elif (( $(awk "BEGIN {print ($bytes < 1048576)}") )); then
        printf "%.1f KB/s" "$(awk "BEGIN {print $bytes / 1024}")"
    else
        printf "%.1f MB/s" "$(awk "BEGIN {print $bytes / 1048576}")"
    fi
}

rx_fmt=$(format_speed "$rx_speed")
tx_fmt=$(format_speed "$tx_speed")

# Network bars (scaled to 100 Mbps = ~12.5 MB/s)
rx_percent=$(awk "BEGIN {p = ($rx_speed / 12500000) * 100; print (p > 100 ? 100 : p)}")
tx_percent=$(awk "BEGIN {p = ($tx_speed / 12500000) * 100; print (p > 100 ? 100 : p)}")
rx_bar=$(get_bar "${rx_percent%.*}" "$net_color")
tx_bar=$(get_bar "${tx_percent%.*}" "$net_color")

# --- FIXED WIDTH LOGIC ---
# Pad to 2 characters so "9%" becomes " 9%" and aligns with "10%"
cpu_pad=$(printf "%2d" "$cpu_usage")
mem_pad=$(printf "%2d" "$mem_usage")
gpu_pad=$(printf "%2d" "$gpu_usage")

# Text for bar
bar_text="<span color='$cpu_color'>$cpu_icon</span> $cpu_pad% <span color='$mem_color'>$mem_icon</span> $mem_pad% <span color='$gpu_color'>$gpu_icon</span> $gpu_pad%"

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
tooltip+=$(row "GPU Usage" "$gpu_usage_display" "$gpu_bar" "$gpu_color" "$gpu_icon")
# tooltip+="<span foreground='$border_color'>━━━━━━━━━━━━━━━━━━━━━━━━━━━━</span>$n"
# tooltip+=$(row "Download" "$rx_fmt" "$rx_bar" "$net_color" "$down_icon")$n
# tooltip+=$(row "Upload" "$tx_fmt" "$tx_bar" "$net_color" "$up_icon")

# Output JSON for Waybar using jq
jq -nc \
    --arg text "$bar_text" \
    --arg tooltip "$tooltip" \
    '{ text: $text, tooltip: $tooltip, class: "vitals" }'
