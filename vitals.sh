#!/usr/bin/env bash

# Modern Icons (Nerdfonts - Material/Lucide style)
cpu_icon="󰘚"      # Integrated circuit/CPU chip
mem_icon="󰍛"      # Memory card/RAM
intel_icon="󰢮"    # GPU icon
nvidia_icon="󰾲"   # Different GPU style for contrast

# Get CPU usage
cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}' | cut -d. -f1)
[ -z "$cpu_usage" ] && cpu_usage=0

# Get Memory usage
mem_data=$(free -m | awk '/Mem:/ {print $2,$3}')
mem_total=$(echo "$mem_data" | awk '{print $1}')
mem_used=$(echo "$mem_data" | awk '{print $2}')
mem_usage=$(( 100 * mem_used / mem_total ))

# Get NVIDIA GPU usage
if command -v nvidia-smi &> /dev/null; then
    nvidia_usage=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | head -n1)
    [ -z "$nvidia_usage" ] && nvidia_usage=0
else
    nvidia_usage=0
fi

# Get Intel GPU usage (frequency percentage)
intel_cur=$(cat /sys/class/drm/card2/device/drm/card2/gt/gt0/rps_cur_freq_mhz 2>/dev/null || echo 0)
intel_max=$(cat /sys/class/drm/card2/device/drm/card2/gt/gt0/rps_max_freq_mhz 2>/dev/null || echo 1)
intel_usage=$(( 100 * intel_cur / intel_max ))

# Text for bar
bar_text="<span foreground='#89dceb' size='large'>$cpu_icon</span> $cpu_usage% <span foreground='#cba6f7' size='large'>$mem_icon</span> $mem_usage% <span foreground='#a6e3a1' size='large'>$intel_icon</span> $intel_usage% <span foreground='#f9e2af' size='large'>$nvidia_icon</span> $nvidia_usage%"

# Build Rich Tooltip
tooltip="<span size='13000' foreground='#89dceb'>$cpu_icon  <b>CPU Load</b></span>
<span foreground='#6c7086'>━━━━━━━━━━━━━━━━━━━━━</span>
<tt>Current Usage:  $cpu_usage%</tt>

<span size='13000' foreground='#cba6f7'>$mem_icon  <b>Memory Vitals</b></span>
<span foreground='#6c7086'>━━━━━━━━━━━━━━━━━━━━━</span>
<tt>Used:           ${mem_used}MB / ${mem_total}MB</tt>
<tt>Percentage:     $mem_usage%</tt>

<span size='13000' foreground='#a6e3a1'>$intel_icon  <b>Intel Graphics</b></span>
<span foreground='#6c7086'>━━━━━━━━━━━━━━━━━━━━━</span>
<tt>Frequency:      ${intel_cur}MHz / ${intel_max}MHz</tt>
<tt>Usage Est:      $intel_usage%</tt>

<span size='13000' foreground='#f9e2af'>$nvidia_icon  <b>NVIDIA GPU</b></span>
<span foreground='#6c7086'>━━━━━━━━━━━━━━━━━━━━━</span>
<tt>Utilization:    $nvidia_usage%</tt>"

# Output JSON
jq -nc \
    --arg text "$bar_text" \
    --arg tooltip "$tooltip" \
    '{ text: $text, tooltip: $tooltip, class: "vitals" }'
