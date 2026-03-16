#!/bin/bash

# ==============================================================================
#  WAYBAR CONFIGURATION INSTALLER
#  Designed for the Omarchy Waybar Theme
# ==============================================================================

# --- AESTHETICS & COLORS ---
export TERM=xterm-256color

RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"
ITALIC="\033[3m"

# Palette
PINK="\033[38;5;213m"
BLUE="\033[38;5;117m"
GREEN="\033[38;5;120m"
PURPLE="\033[38;5;141m"
CYAN="\033[38;5;159m"
YELLOW="\033[38;5;228m"
RED="\033[38;5;203m"
GRAY="\033[38;5;245m"

# Icons
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
REPO_URL="https://github.com/yourusername/waybar-config.git" # TODO: Update this URL
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

print_step() { echo -e "${ICON_INFO} ${BOLD}$1${RESET}"; }
print_success() { echo -e "   ${ICON_CHECK} $1"; }
print_error() { echo -e "   ${ICON_ERROR} $1"; }

check_dependency() {
    if ! command -v "$1" &> /dev/null; then
        echo -e "   ${ICON_WARN} Missing: ${RED}$1${RESET}"
        return 1
    else
        echo -e "   ${ICON_CHECK} Found: ${GREEN}$1${RESET}"
        return 0
    fi
}

# --- MAIN SCRIPT ---

print_banner

# 1. DOWNLOAD LOGIC (For curl | bash)
if [ ! -d "$CONFIG_DIR/.git" ]; then
    print_step "Setting up repository..."
    if command -v git &> /dev/null; then
        if [ -d "$CONFIG_DIR" ]; then
            mkdir -p "$BACKUP_DIR"
            mv "$CONFIG_DIR"/* "$BACKUP_DIR/" 2>/dev/null
        fi
        git clone "$REPO_URL" "$CONFIG_DIR"
        cd "$CONFIG_DIR" || exit
    else
        print_error "Git is not installed. Please install git first."
        exit 1
    fi
fi

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 2. DEPENDENCY CHECK
print_step "Checking System Dependencies..."
DEPS=("waybar" "jq" "curl" "playerctl" "pamixer" "btop")
for dep in "${DEPS[@]}"; do check_dependency "$dep"; done

echo ""

# 3. BACKUP & INSTALL
print_step "Installing Configuration Files..."

link_file() {
    local src="$1"
    local dest="$2"
    [ -e "$dest" ] || [ -L "$dest" ] && rm -rf "$dest"
    ln -sf "$src" "$dest"
    echo -e "   ${ICON_LINK} ${DIM}$(basename "$src")${RESET} -> ${BLUE}$dest${RESET}"
}

files=(config.jsonc style.css media.sh weather.sh vitals.sh schedule.sh window.sh assets)
for file in "${files[@]}"; do
    link_file "$DOTFILES_DIR/$file" "$CONFIG_DIR/$file"
done

# 4. PERMISSIONS
chmod +x "$CONFIG_DIR/"*.sh
print_success "Permissions set."

# 5. WEATHER CONFIG
ENV_FILE="$CONFIG_DIR/.env"
if [ ! -f "$ENV_FILE" ] || [[ $1 == "--reconfig" ]]; then
    print_step "Configuring Weather API..."
    echo -e "   Get API Key: ${CYAN}https://openweathermap.org/api${RESET}"
    read -p "   Enter API Key: " KEY
    read -p "   Enter City (e.g., London,UK): " CITY
    echo "WEATHER_API_KEY=\"$KEY\"" > "$ENV_FILE"
    echo "WEATHER_CITY=\"$CITY\"" >> "$ENV_FILE"
    print_success "Config saved to .env"
fi

echo ""
echo -e "${GREEN}======================================================${RESET}"
echo -e "${BOLD}${PINK}   INSTALLATION COMPLETE! ${ICON_ROCKET}${RESET}"
echo -e "${GREEN}======================================================${RESET}"
echo -e "\n   Restart Waybar to apply changes."
echo ""
