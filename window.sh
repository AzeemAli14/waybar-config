#!/usr/bin/env bash

# Function to get icon based on app class or title
get_icon() {
    local class=$(echo "$1" | tr '[:upper:]' '[:lower:]')
    local title=$(echo "$2" | tr '[:upper:]' '[:lower:]')
    
    # Check class first
    case "$class" in
        *firefox*) echo "󰈹" ;;
        *chrome*) echo "󰊯" ;;
        *chromium*) echo "󰊯" ;;
        *brave*) echo "󰖟" ;;
        *discord*) echo "󰙯" ;;
        *vesktop*) echo "󰙯" ;;
        *code*) echo "󰨞" ;;
        *vsc*) echo "󰨞" ;;
        *spotify*) echo "󰓇" ;;
        *vlc*) echo "󰕼" ;;
        *thunar*) echo "󰉋" ;;
        *nautilus*) echo "󰉋" ;;
        *dolphin*) echo "󰉋" ;;
        *terminal* | *kitty* | *foot* | *alacritty* | *ghostty*) echo "󰆍" ;;
        *telegram*) echo "󰭻" ;;
        *slack*) echo "󰒱" ;;
        *steam*) echo "󰓓" ;;
        *obsidian*) echo "󱓧" ;;
        *blender*) echo "󰂫" ;;
        *inkscape*) echo "󰴔" ;;
        *gimp*) echo "󰴕" ;;
        *libreoffice*) echo "󰏆" ;;
        *thunderbird*) echo "󰇰" ;;
        *) 
            # If class is generic, check title for common webapps
            if [[ "$title" == *youtube* ]]; then echo "󰗃";
            elif [[ "$title" == *gmail* ]]; then echo "󰊫";
            elif [[ "$title" == *github* ]]; then echo "󰊤";
            elif [[ "$title" == *whatsapp* ]]; then echo "󰖣";
            elif [[ "$title" == *messenger* ]]; then echo "󰈎";
            elif [[ "$title" == *reddit* ]]; then echo "󰑍";
            elif [[ "$title" == *twitter* || "$title" == *' x '* ]]; then echo "󰕄";
            else echo "󰣆"; fi # Default icon
            ;;
    esac
}

print_status() {
    window=$(hyprctl activewindow -j 2>/dev/null)
    address=$(echo "$window" | jq -r '.address // empty')

    if [[ -n "$address" && "$address" != "null" ]]; then
        class=$(echo "$window" | jq -r '.class // "Unknown"')
        title=$(echo "$window" | jq -r '.title // ""')
        
        # 1. Clean up reverse-DNS names (e.g., com.mitchellh.ghostty -> ghostty)
        clean_name="${class##*.}"
        
        # 2. Strip WebApp noise and browser prefixes
        clean_name="${clean_name#-Default}"
        clean_name="${clean_name%-Default}"
        clean_name="${clean_name#chrome-}"
        clean_name="${clean_name#brave-}"
        clean_name="${clean_name#chromium-}"
        
        # 3. Determine App Name (display_class) and Concise Title (display_title)
        display_title="$title"
        display_class="${clean_name^}"
        
        # Handle specific app logic and generic names
        if [[ "${class,,}" == *"code"* || "${class,,}" == *"vsc"* ]]; then
            display_class="VS Code"
        elif [[ "$clean_name" == "Com_"* || "$clean_name" == "com_"* || "$clean_name" == "Unknown" || "$clean_name" == "" || "$clean_name" == "chromium-browser" ]]; then
            # If class is generic, try to extract app name from the title
            if [[ "$title" == *" - "* ]]; then
                display_class="${title#* - }"
                display_title="${title%% - *}"
            elif [[ "$title" == *" | "* ]]; then
                display_class="${title#* | }"
                display_title="${title%% | *}"
            fi
        fi

        # Specific overrides for common apps
        case "${display_class,,}" in
            "codium") display_class="VSCodium" ;;
            "code-url-handler") display_class="VS Code" ;;
            *firefox*) display_class="Firefox" ;;
            *chrome*) display_class="Chrome" ;;
            *chromium*) display_class="Chromium" ;;
            *brave*) display_class="Brave" ;;
            *discord*) display_class="Discord" ;;
            *vesktop*) display_class="Vesktop" ;;
            *spotify*) display_class="Spotify" ;;
        esac

        # --- GENERAL CONCISE TITLE LOGIC (for Tooltip) ---
        # Strip common app suffixes from title if they haven't been stripped yet
        case "${class,,}" in
            *firefox*) display_title="${display_title% - Mozilla Firefox}" ;;
            *chrome*)  display_title="${display_title% - Google Chrome}" ;;
            *chromium*) display_title="${display_title% - Chromium}" ;;
            *brave*)   display_title="${display_title% - Brave}" ;;
            *code*|*vsc*) display_title="${display_title% - Visual Studio Code}" ;;
        esac

        # Further trim if there are separators left (take the first segment)
        # This handles patterns like "Filename - Folder - App" or "Page - Site"
        if [[ "$display_title" == *" - "* ]]; then
            display_title="${display_title%% - *}"
        elif [[ "$display_title" == *" — "* ]]; then
            display_title="${display_title%% — *}"
        elif [[ "$display_title" == *" | "* ]]; then
            display_title="${display_title%% | *}"
        elif [[ "$display_title" == *" • "* ]]; then
            display_title="${display_title%% • *}"
        fi
        
        # Strip trailing parenthetical info (e.g., " (Workspace)", " (Incognito)")
        display_title="${display_title%% (*}"

        # Truncate bar text if too long
        if [ ${#display_class} -gt 20 ]; then
            display_class="${display_class:0:17}..."
        fi

        icon=$(get_icon "$class" "$title")

        # Prepare tooltip (Concise Title)
        tooltip_text="<span size='12000' foreground='#cba6f7'><b>󱂬 Window Details</b></span>
<span foreground='#6c7086'>━━━━━━━━━━━━━━━━━━━━━</span>
<tt><b>󰀻 App:   </b> $display_class</tt>
<tt><b>󰟵 Title: </b> $display_title</tt>"
        
        # Text for the bar: Icon + App Name
        bar_text="<span size='11000' foreground='#cba6f7'>$icon</span>  <span weight='bold'>$display_class</span>"

        jq -nc \
            --arg text "$bar_text" \
            --arg tooltip "$tooltip_text" \
            '{ text: $text, class: "custom-window", tooltip: $tooltip }'
    else
        # Hide module completely on empty workspace
        jq -nc '{ text: "", class: "empty", tooltip: "" }'
    fi
}

# Use a more efficient way to wait for events if possible, but for now, stay with loop
while true; do
    print_status
    sleep 1
done
