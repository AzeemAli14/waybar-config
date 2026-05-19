#!/bin/bash
set -e

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
ICON_GEAR="${GRAY}⚙${RESET}"

# --- CONFIGURATION ---
REPO_URL="https://github.com/AzeemAli14/waybar-config.git"
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
            echo -e "   ${ICON_INFO} Backing up existing config to ${DIM}$BACKUP_DIR${RESET}"
            # Use a more robust move to avoid "no such file" errors
            find "$CONFIG_DIR" -maxdepth 1 -not -name "$(basename "$BACKUP_DIR")" -not -path "$CONFIG_DIR" -exec mv {} "$BACKUP_DIR/" \; 2>/dev/null || true
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
DEPS=("waybar" "jq" "curl" "playerctl" "pamixer" "btop" "awk" "top" "free" "quickshell" "calcure" "mako")
MISSING_DEPS=()
for dep in "${DEPS[@]}"; do
    if ! check_dependency "$dep"; then
        MISSING_DEPS+=("$dep")
    fi
done

if [ ${#MISSING_DEPS[@]} -ne 0 ]; then
    echo -e "\n   ${ICON_ERROR} ${RED}Missing critical dependencies: ${MISSING_DEPS[*]}${RESET}"
    echo -e "   Please install them using your package manager."
    exit 1
fi

# Optional Dependencies
echo -e "\n   ${ICON_GEAR} ${DIM}Checking optional dependencies...${RESET}"
check_dependency "nvidia-smi" || echo -e "      ${DIM}(Optional: Required for NVIDIA GPU monitoring)${RESET}"
check_dependency "omarchy-update-available" || echo -e "      ${DIM}(Optional: Required for Omarchy update notifications)${RESET}"

# Check for JetBrainsMono Nerd Font
if fc-list :family | grep -iq "JetBrainsMono Nerd Font"; then
    print_success "Found: JetBrainsMono Nerd Font"
else
    echo -e "   ${ICON_WARN} Missing: ${RED}JetBrainsMono Nerd Font${RESET}"
    echo -e "      ${DIM}(Required for icons to display correctly)${RESET}"
fi

echo ""

# 3. BACKUP & INSTALL
print_step "Installing Configuration Files..."

link_file() {
    local src="$1"
    local dest="$2"
    
    # If source and destination are the same, just ensure it's executable if it's a script
    if [[ "$src" == "$dest" ]]; then
        echo -e "   ${ICON_CHECK} ${DIM}$(basename "$src")${RESET} is already in place."
        return
    fi

    [ -e "$dest" ] || [ -L "$dest" ] && rm -rf "$dest"
    ln -sf "$src" "$dest"
    echo -e "   ${ICON_LINK} ${DIM}$(basename "$src")${RESET} -> ${BLUE}$dest${RESET}"
}

files=(config.jsonc style.css media.sh weather.sh vitals.sh schedule.sh window.sh notifications.sh assets)
for file in "${files[@]}"; do
    link_file "$DOTFILES_DIR/$file" "$CONFIG_DIR/$file"
done

# 4. PERMISSIONS
chmod +x "$CONFIG_DIR/"*.sh
print_success "Permissions set for scripts."

# 5. CLEANUP & FINALIZE
print_step "Finalizing installation..."
# Remove legacy .env if it exists as it's no longer needed for weather
[ -f "$CONFIG_DIR/.env" ] && rm "$CONFIG_DIR/.env"

echo ""
echo -e "${GREEN}======================================================${RESET}"
echo -e "${BOLD}${PINK}   INSTALLATION COMPLETE! ${ICON_ROCKET}${RESET}"
echo -e "${GREEN}======================================================${RESET}"
echo -e "\n   ${BOLD}Next Steps:${RESET}"
echo -e "   1. Ensure ${CYAN}JetBrainsMono Nerd Font${RESET} is installed."
echo -e "   2. Restart Waybar: ${DIM}pkill waybar && waybar &${RESET}"
echo -e "   3. Enjoy your glassmorphism dashboard!"
echo ""
