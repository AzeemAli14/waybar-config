#!/usr/bin/env bash

# Icons
icon_empty="󰂚"
icon_full="󱅫"
icon_dnd="󰂛"

# Colors (Catppuccin Mocha)
red="#f38ba8"
peach="#fab387"
lavender="#b4befe"
mauve="#cba6f7"
green="#a6e3a1"
overlay="#45475a"
text_color="#cdd6f4"

divider="<span foreground='$overlay'>━━━━━━━━━━━━━━━━━━━━━━━━━━━━</span>"

# Get count from Quickshell IPC
count=$(quickshell ipc -c notifications prop get menuIpc count 2>/dev/null)

# Get mako mode for DND detection
mode=$(makoctl mode)

# Fallback if Quickshell is not running or IPC fails
if [ -z "$count" ] || ! [[ "$count" =~ ^[0-9]+$ ]]; then
    count=0
fi

if echo "$mode" | grep -q -v "^default$"; then
    # DND Mode (any mode other than just 'default')
    text="<span color='$peach'>$icon_dnd</span>"
    if [ "$count" -gt 0 ]; then
        text+=" <span size='small' color='$peach' weight='bold'>$count</span>"
    fi
    class="dnd"
    tooltip="<span size='14000' weight='bold' foreground='$peach'>󰂞 DO NOT DISTURB</span>
$divider
<span foreground='$text_color'>󱅫 Pending:</span>  <span weight='bold' foreground='$peach'>$count Notifications</span>

<span size='10000' alpha='70%'><i>Silence is golden. Alerts are held.</i></span>"
elif [ "$count" -gt 0 ]; then
    # Notifications present
    text="<span color='$red'>$icon_full</span> <span color='$text_color' weight='bold'>$count</span>"
    class="has-notifications"
    tooltip="<span size='14000' weight='bold' foreground='$red'>󱅫 NOTIFICATIONS</span>
$divider
<span foreground='$text_color'>󰂛 Count:</span>    <span weight='bold' foreground='$red'>$count Active</span>
<span foreground='$green'>󰆊 Action:</span>   <span weight='bold' foreground='$mauve'>Left-Click</span> to View
<span foreground='$red'>󰆴 Dismiss:</span>  <span weight='bold' foreground='$mauve'>Right-Click</span> to Clear
$divider
<span size='10000' alpha='70%'><i>Stay updated with your latest alerts.</i></span>"
else
    # No notifications
    text="<span color='$red'>$icon_empty</span>"
    class="none"
    tooltip="<span size='14000' weight='bold' foreground='$lavender'>󰂚 NOTIFICATIONS</span>
$divider
<span foreground='$text_color'>󰄬 Status:</span>   <span weight='bold' foreground='$green'>All caught up!</span>
$divider
<span size='10000' alpha='70%'><i>No new alerts at the moment.</i></span>"
fi

jq -nc --arg text "$text" --arg class "$class" --arg tooltip "$tooltip" '{text: $text, class: $class, tooltip: $tooltip}'
