#!/bin/bash

# --- Omarchy Waybar Installer ---
# This script sets up the Waybar configuration.

# Get current directory
DOTFILES_DIR=$(pwd)
CONFIG_DIR="$HOME/.config/waybar"

echo "🚀 Starting Omarchy Waybar Installation..."

# Create config directory if it doesn't exist
if [ ! -d "$CONFIG_DIR" ]; then
    echo "📁 Creating Waybar config directory: $CONFIG_DIR"
    mkdir -p "$CONFIG_DIR"
fi

# Backup existing config
if [ -f "$CONFIG_DIR/config.jsonc" ]; then
    echo "📦 Backing up existing Waybar configuration..."
    mv "$CONFIG_DIR/config.jsonc" "$CONFIG_DIR/config.jsonc.bak"
    mv "$CONFIG_DIR/style.css" "$CONFIG_DIR/style.css.bak"
fi

# Link configuration files
echo "🔗 Symlinking configuration files..."
ln -sf "$DOTFILES_DIR/config.jsonc" "$CONFIG_DIR/config.jsonc"
ln -sf "$DOTFILES_DIR/style.css" "$CONFIG_DIR/style.css"
ln -sf "$DOTFILES_DIR/media.sh" "$CONFIG_DIR/media.sh"
ln -sf "$DOTFILES_DIR/weather.sh" "$CONFIG_DIR/weather.sh"
ln -sf "$DOTFILES_DIR/window.sh" "$CONFIG_DIR/window.sh"
ln -sf "$DOTFILES_DIR/assets" "$CONFIG_DIR/assets"

# Make scripts executable
echo "🔑 Setting executable permissions for scripts..."
chmod +x "$CONFIG_DIR/media.sh" "$CONFIG_DIR/weather.sh" "$CONFIG_DIR/window.sh"

# Setup .env if it doesn't exist
if [ ! -f "$CONFIG_DIR/.env" ]; then
    echo "🌍 Setting up .env for weather..."
    echo 'WEATHER_API_KEY=""' > "$CONFIG_DIR/.env"
    echo 'WEATHER_CITY=""' >> "$CONFIG_DIR/.env"
    echo "⚠️  Please update your weather details in $CONFIG_DIR/.env"
fi

echo "✨ Installation complete! Please restart Waybar to see changes."
echo "   Command: pkill waybar; waybar &"
