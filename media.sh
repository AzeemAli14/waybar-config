#!/usr/bin/env bash

# Use playerctl to get metadata
player_status=$(playerctl status 2>/dev/null)
if [ -z "$player_status" ]; then
    echo "{\"text\":\"󰒲 No media\", \"tooltip\":\"Nothing playing\"}"
    # Reset scroll state when nothing is playing
    echo "0" > /tmp/waybar_media_scroll 2>/dev/null
    exit 0
fi

# Get player name
player_name=$(playerctl metadata --format '{{playerName}}' 2>/dev/null | tr '[:upper:]' '[:lower:]')
player_url=$(playerctl metadata xesam:url 2>/dev/null)
title=$(playerctl metadata title 2>/dev/null)
artist=$(playerctl metadata artist 2>/dev/null)
album=$(playerctl metadata album 2>/dev/null)

# Theme colors
case "$player_name" in
    "spotify")
        player_icon="󰓇"
        accent_color="#1DB954"
        player_display="Spotify"
        ;;
    "firefox"*|"chromium"*|"google-chrome"*|"brave"*|"microsoft-edge"*|"opera"*|"librewolf"*|"floorp"*|"thorium"*|"vivaldi"*|"browser"*|"chrome"*|"plasma-browser-integration"*)
        if [[ "${player_url,,}" == *"youtube.com"* ]] || [[ "${player_url,,}" == *"music.youtube.com"* ]] || [[ "${title,,}" == *"youtube"* ]]; then
            player_icon="󰗃"
            accent_color="#FF0000"
            player_display="YouTube"
        elif [[ "${player_url,,}" == *"soundcloud.com"* ]] || [[ "${title,,}" == *"soundcloud"* ]]; then
            player_icon="󰓀"
            accent_color="#ff5500"
            player_display="SoundCloud"
        else
            player_icon=""
            accent_color="#7858df"
            player_display="Web Browser"
        fi
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

# Progress Bar Logic
position=$(playerctl position 2>/dev/null | cut -d. -f1)
length=$(playerctl metadata mpris:length 2>/dev/null)

if [ -n "$length" ] && [ "$length" -gt 0 ]; then
    length_sec=$((length / 1000000))
    pos_min=$(printf "%02d:%02d" $((position/60)) $((position%60)))
    len_min=$(printf "%02d:%02d" $((length_sec/60)) $((length_sec%60)))
    percent=$(( 100 * position / length_sec ))
    
    bar_size=25
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

# Scrolling Logic
MAX_LEN_BAR=25
MAX_LEN_TT=35
title_scrolled="$title"
title_tt_scrolled="$title"

state_file="/tmp/waybar_media_scroll"
[ ! -f "$state_file" ] && echo "0" > "$state_file"
offset=$(cat "$state_file")

# Bar Scroller
if [ ${#title} -gt $MAX_LEN_BAR ]; then
    padded_title="$title   "
    len=${#padded_title}
    title_scrolled="${padded_title:offset % len:MAX_LEN_BAR}"
    remaining=$(( MAX_LEN_BAR - ${#title_scrolled} ))
    [ $remaining -gt 0 ] && title_scrolled+="${padded_title:0:remaining}"
fi

# Tooltip Scroller
if [ ${#title} -gt $MAX_LEN_TT ]; then
    padded_title_tt="$title   "
    len_tt=${#padded_title_tt}
    title_tt_scrolled="${padded_title_tt:offset % len_tt:MAX_LEN_TT}"
    remaining_tt=$(( MAX_LEN_TT - ${#title_tt_scrolled} ))
    [ $remaining_tt -gt 0 ] && title_tt_scrolled+="${padded_title_tt:0:remaining_tt}"
fi

# Update offset
if [ "$player_status" = "Playing" ]; then
    echo "$((offset + 1))" > "$state_file"
fi

# Escape special XML characters for Pango
title_scrolled_esc=$(echo "$title_scrolled" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&apos;/g')
title_tt_scrolled_esc=$(echo "$title_tt_scrolled" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&apos;/g')
artist_esc=$(echo "$artist" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&apos;/g')
album_esc=$(echo "$album" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&apos;/g')

full_text="$player_icon $status_icon $title_scrolled_esc <span size='smaller' alpha='70%'>- $artist_esc</span>"

# Build Beautiful Tooltip
tooltip="<span color='$accent_color' weight='bold' size='large'>$player_icon $player_display</span>\n"
tooltip+="<span size='large' font='JetBrainsMono Nerd Font' weight='bold'><tt>$title_tt_scrolled_esc</tt></span>\n"
tooltip+="<span size='medium' alpha='80%'>󰠃 $artist_esc</span>\n"
if [ -n "$album_esc" ] && [ "$album_esc" != "$title_esc" ]; then
    tooltip+="<span alpha='60%'>󰀥 $album_esc</span>"
fi
tooltip+="$progress_info"

echo "{\"text\":\"$full_text\", \"tooltip\":\"$tooltip\", \"class\":\"$player_status $player_name\"}"
