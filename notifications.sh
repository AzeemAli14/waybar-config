#!/usr/bin/env bash

# Icons
icon_empty="󰂚"
icon_full="󰂛"

# Get count from Quickshell IPC
# We use 'prop get' for a more reliable read of the count
count=$(quickshell ipc -c notifications prop get menuIpc count 2>/dev/null)

# Fallback if Quickshell is not running or IPC fails
if [ -z "$count" ] || ! [[ "$count" =~ ^[0-9]+$ ]]; then
    count=0
fi

if [ "$count" -gt 0 ]; then
    text="$icon_full"
    class="has-notifications"
else
    text="$icon_empty"
    class="none"
fi

jq -nc --arg text "$text" --arg class "$class" --arg tooltip "$count Notifications" '{text: $text, class: $class, tooltip: $tooltip}'