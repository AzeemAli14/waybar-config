#!/usr/bin/env bash

# Use playerctl to get metadata
player_status=$(playerctl status 2>/dev/null)
if [ -z "$player_status" ]; then
    echo "{\"text\":\"󰒲 No media\", \"tooltip\":\"Nothing playing\"}"
    exit 0
fi

# Get player name
player_name=$(playerctl metadata --format '{{playerName}}' 2>/dev/null)

# Theme colors
case "$player_name" in
    "spotify")
        player_icon="󰓇"
        accent_color="#1DB954"
        player_display="Spotify"
        ;;
    "firefox"|"chromium"|"google-chrome"|"brave")
        player_icon="󰈹"
        accent_color="#ff7b00"
        player_display="Web Browser"
        ;;
    "vlc")
        player_icon="󰕼"
        accent_color="#ff8100"
        player_display="VLC"
        ;;
    *)
        player_icon="󰝚"
        accent_color="#88c0d0"
        player_display="${player_name^}"
        ;;
esac

# Get status icon
if [ "$player_status" = "Playing" ]; then
    status_icon="󰐊"
    status_text="Playing"
else
    status_icon="󰏤"
    status_text="Paused"
fi

# Get metadata
title=$(playerctl metadata title 2>/dev/null)
artist=$(playerctl metadata artist 2>/dev/null)
album=$(playerctl metadata album 2>/dev/null)

# Escape special XML characters for Pango
title_esc=$(echo "$title" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&apos;/g')
artist_esc=$(echo "$artist" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&apos;/g')
album_esc=$(echo "$album" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&apos;/g')

# Progress Bar Logic
position=$(playerctl position 2>/dev/null | cut -d. -f1)
length=$(playerctl metadata mpris:length 2>/dev/null)

if [ -n "$length" ] && [ "$length" -gt 0 ]; then
    length_sec=$((length / 1000000))
    pos_min=$(printf "%02d:%02d" $((position/60)) $((position%60)))
    len_min=$(printf "%02d:%02d" $((length_sec/60)) $((length_sec%60)))
    percent=$(( 100 * position / length_sec ))
    
    bar_size=20
    filled_size=$(( percent * bar_size / 100 ))
    empty_size=$(( bar_size - filled_size ))
    
    bar_filled=""
    for ((i=0; i<filled_size; i++)); do bar_filled+="━"; done
    
    bar_empty=""
    for ((i=0; i<empty_size-1; i++)); do bar_empty+="─"; done
    
    progress_info="\n\n<tt>$pos_min <span color='$accent_color'>$bar_filled●</span>$bar_empty $len_min</tt>"
else
    progress_info=""
fi

# Main Bar Text
if [ ${#title_esc} -gt 25 ]; then
    title_display="${title_esc:0:22}..."
else
    title_display="$title_esc"
fi
full_text="$player_icon $status_icon $title_display <span size='smaller' alpha='70%'>- $artist_esc</span>"

# Build Beautiful Tooltip
tooltip="<span color='$accent_color' weight='bold' size='large'>$player_icon $player_display</span>\n"
tooltip+="<span size='x-large' weight='bold'>$title_esc</span>\n"
tooltip+="<span size='large' alpha='80%'>󰠃 $artist_esc</span>\n"
if [ -n "$album_esc" ] && [ "$album_esc" != "$title_esc" ]; then
    tooltip+="<span alpha='60%'>󰀥 $album_esc</span>"
fi
tooltip+="$progress_info"

echo "{\"text\":\"$full_text\", \"tooltip\":\"$tooltip\", \"class\":\"$player_status $player_name\"}"
