#!/bin/bash

# ==============================================================================
#  WAYBAR CONFIGURATION INSTALLER
#  Designed for the Omarchy Waybar Theme
# ==============================================================================

# --- AESTHETICS & COLORS ---
# Using 256 colors for a richer palette matching the theme (Catppuccin/Pastel)
export TERM=xterm-256color

RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"
ITALIC="\033[3m"
UNDERLINE="\033[4m"

# Palette
PINK="\033[38;5;213m"
BLUE="\033[38;5;117m"
GREEN="\033[38;5;120m"
PURPLE="\033[38;5;141m"
CYAN="\033[38;5;159m"
YELLOW="\033[38;5;228m"
RED="\033[38;5;203m"
GRAY="\033[38;5;245m"

# Icons (Nerd Fonts)
ICON_CHECK="${GREEN}✔${RESET}"
ICON_ERROR="${RED}✖${RESET}"
ICON_WARN="${YELLOW}⚠${RESET}"
ICON_INFO="${BLUE}ℹ${RESET}"
ICON_ROCKET="${PINK}🚀${RESET}"
ICON_PKG="${PURPLE}📦${RESET}"
ICON_LINK="${CYAN}🔗${RESET}"
ICON_KEY="${YELLOW}🔑${RESET}"
ICON_GEAR="${GRAY}⚙${RESET}"

# --- CONFIGURATION ---
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config/waybar"
BACKUP_DIR="$CONFIG_DIR/backups/$(date +%Y%m%d_%H%M%S)"

# --- FUNCTIONS ---

print_banner() {
    clear
    echo -e "${PURPLE}"
    echo "   ____                            _            "
    echo "  / __ \                          | |           "
    echo " | |  | |_ __ ___   __ _ _ __ ___ | |__  _   _  "
    echo " | |  | | '_ \` _ \ / _\` | '__/ __|| '_ \| | | | "
    echo " | |__| | | | | | | (_| | | | (__ | | | | |_| | "
    echo "  \____/|_| |_| |_|\__,_|_|  \___||_| |_|\__, | "
    echo "                                          __/ | "
    echo "                                         |___/  "
    echo -e "${PINK}        WAYBAR INSTALLER & CONFIGURATOR${RESET}"
    echo -e "${DIM}      -------------------------------------${RESET}"
    echo ""
}

spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

print_step() {
    echo -e "${ICON_INFO} ${BOLD}$1${RESET}"
}

print_success() {
    echo -e "   ${ICON_CHECK} $1"
}

print_error() {
    echo -e "   ${ICON_ERROR} $1"
}

check_dependency() {
    if ! command -v "$1" &> /dev/null; then
        echo -e "   ${ICON_WARN} Missing dependency: ${RED}$1${RESET}"
        return 1
    else
        echo -e "   ${ICON_CHECK} Found dependency: ${GREEN}$1${RESET}"
        return 0
    fi
}

# --- MAIN SCRIPT ---

print_banner

# 1. DEPENDENCY CHECK
print_step "Checking System Dependencies..."
DEPS=("waybar" "jq" "curl" "playerctl" "pamixer" "btop")
MISSING_DEPS=0

for dep in "${DEPS[@]}"; do
    check_dependency "$dep" || ((MISSING_DEPS++))
done

if [ $MISSING_DEPS -gt 0 ]; then
    echo ""
    echo -e "${ICON_WARN} ${YELLOW}Some dependencies are missing.${RESET}"
    echo -e "   The configuration might not work fully without them."
    echo -e "   Please install them using your package manager (e.g., pacman, apt, dnf)."
    echo ""
    read -p "Do you want to continue anyway? (y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}Installation aborted.${RESET}"
        exit 1
    fi
else
    echo -e "   ${GREEN}All dependencies met!${RESET}"
fi

echo ""

# 2. BACKUP EXISTING CONFIG
print_step "Backing up existing configuration..."
if [ -d "$CONFIG_DIR" ]; then
    mkdir -p "$BACKUP_DIR"
    
    # Check if config files exist before moving
    if [ -f "$CONFIG_DIR/config.jsonc" ]; then
        cp "$CONFIG_DIR/config.jsonc" "$BACKUP_DIR/"
    fi
    if [ -f "$CONFIG_DIR/style.css" ]; then
        cp "$CONFIG_DIR/style.css" "$BACKUP_DIR/"
    fi
    # Also backup any existing scripts we are about to overwrite/link
    for script in media.sh weather.sh vitals.sh schedule.sh window.sh; do
        if [ -f "$CONFIG_DIR/$script" ]; then
            cp "$CONFIG_DIR/$script" "$BACKUP_DIR/" 2>/dev/null
        fi
    done
    
    # Backup assets folder if it exists
     if [ -d "$CONFIG_DIR/assets" ]; then
        cp -r "$CONFIG_DIR/assets" "$BACKUP_DIR/"
    fi

    echo -e "   ${ICON_PKG} Backup created at: ${CYAN}$BACKUP_DIR${RESET}"
else
    echo -e "   ${ICON_INFO} No existing directory found at $CONFIG_DIR. Creating one..."
    mkdir -p "$CONFIG_DIR"
fi

echo ""

# 3. SYMLINKING FILES
print_step "Installing Configuration Files..."

# Function to safely link files
link_file() {
    local src="$1"
    local dest="$2"
    
    # Remove existing file/link if it exists
    if [ -e "$dest" ] || [ -L "$dest" ]; then
        rm -rf "$dest"
    fi
    
    ln -sf "$src" "$dest"
    echo -e "   ${ICON_LINK} Linked: ${DIM}$(basename "$src")${RESET} -> ${BLUE}$dest${RESET}"
}

link_file "$DOTFILES_DIR/config.jsonc" "$CONFIG_DIR/config.jsonc"
link_file "$DOTFILES_DIR/style.css" "$CONFIG_DIR/style.css"
link_file "$DOTFILES_DIR/media.sh" "$CONFIG_DIR/media.sh"
link_file "$DOTFILES_DIR/weather.sh" "$CONFIG_DIR/weather.sh"
link_file "$DOTFILES_DIR/vitals.sh" "$CONFIG_DIR/vitals.sh"
link_file "$DOTFILES_DIR/schedule.sh" "$CONFIG_DIR/schedule.sh"
link_file "$DOTFILES_DIR/window.sh" "$CONFIG_DIR/window.sh"

# Link assets directory
if [ -d "$DOTFILES_DIR/assets" ]; then
    link_file "$DOTFILES_DIR/assets" "$CONFIG_DIR/assets"
fi

echo ""

# 4. PERMISSIONS
print_step "Setting Permissions..."
chmod +x "$CONFIG_DIR/"*.sh
print_success "Made all scripts executable."

echo ""

# 5. ENVIRONMENT SETUP (.env)
print_step "Configuring Environment..."

ENV_FILE="$CONFIG_DIR/.env"

if [ -f "$ENV_FILE" ]; then
    echo -e "   ${ICON_CHECK} Found existing .env file."
    read -p "   Do you want to reconfigure Weather API settings? (y/N) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        CONFIGURE_ENV=true
    else
        CONFIGURE_ENV=false
    fi
else
    echo -e "   ${ICON_WARN} No .env file found. Creating new one..."
    CONFIGURE_ENV=true
fi

if [ "$CONFIGURE_ENV" = true ]; then
    echo -e "   ${CYAN}--- Weather Configuration ---${RESET}"
    echo -e "   Get your API Key from: https://openweathermap.org/api"
    
    read -p "   Enter your OpenWeatherMap API Key: " WEATHER_API_KEY
    read -p "   Enter your City Name (e.g., London,UK): " WEATHER_CITY
    
    # Save to .env
    echo "WEATHER_API_KEY=\"$WEATHER_API_KEY\"" > "$ENV_FILE"
    echo "WEATHER_CITY=\"$WEATHER_CITY\"" >> "$ENV_FILE"
    
    print_success "Weather configuration saved to $ENV_FILE"
fi

echo ""

# 6. COMPLETION
echo -e "${GREEN}======================================================${RESET}"
echo -e "${BOLD}${PINK}   INSTALLATION COMPLETE! ${ICON_ROCKET}${RESET}"
echo -e "${GREEN}======================================================${RESET}"
echo ""
echo -e "   To apply changes, restart Waybar:"
echo -e "   ${CYAN}$ pkill waybar; waybar &${RESET}"
echo ""
echo -e "   ${DIM}Enjoy your new setup!${RESET}"
echo ""
