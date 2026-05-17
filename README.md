<h1 align="center">
  ✨ Omarchy Waybar ✨
</h1>

<p align="center">
  <i align="center">A high-performance, glassmorphism-inspired Waybar configuration for Hyprland.</i>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Maintained%3F-yes-green.svg" alt="Maintained">
  <img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License">
  <img src="https://img.shields.io/badge/Style-Glassmorphism-purple.svg" alt="Style">
  <img src="https://img.shields.io/badge/Made%20with-Bash%20%26%20CSS-orange.svg" alt="Made with">
</p>

<div align="center">
  <a href="#-features">Features</a> •
  <a href="#-interactive-installer">Installation</a> •
  <a href="#-tooltips">Gallery</a> •
  <a href="#-dependencies">Dependencies</a> •
  <a href="#-customization">Customization</a>
</div>

<h1 align="center">
  <br>
  <img src="assets/waybar_v2.0/waybar_new.png" alt="Omarchy Waybar" width="800">
  <br>
</h1>
---

## 🚀 Quick Install

To install this configuration with a single command, run:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/AzeemAli14/waybar-config/v2.0/install.sh)"
```

---

## 🎨 Design Philosophy

**Omarchy Waybar** isn't just a status bar; it's a dashboard for your desktop. Built with a focus on **Glassmorphism**, it features:
- 💊 **Modern Pill Aesthetic**: Refactored layout with individual capsule-shaped modules.
- 🧊 **Refined Transparency**: 70% opacity with subtle border glows.
- 🌈 **Adaptive Accents**: Colors that shift based on your active media.
- 🛠️ **Functional Tooltips**: Every icon hides a mini-dashboard with detailed insights.
- 📥 **Collapsible Tray**: A sleek, animated drawer for system tray icons.

---

## ✨ Features

### 🌤️ Pro Weather Engine (Automated)
- **Open-Meteo Integration**: Powered by **Open-Meteo** for precise, real-time data.
- **Auto-Location**: Detects your city automatically using **IP-API** (no manual setup required).
- **Comprehensive Tooltip**: Feels like, High/Low, Humidity, Wind, Cloud cover, and Sunrise/Sunset.
- **Dynamic Icons**: Changes based on weather condition and day/night cycle.
- **Perfect Alignment**: Monospaced, pixel-perfect layout for all weather vitals.

### 🎵 Advanced Media Control
- **Smart Labels**: Unique icons for Spotify, VLC, and expanded Web Browser support.
- **Dynamic Styling**: The bar glows with "Spotify Green" or "YouTube Red" based on active media.
- **Rich Dashboards**: Tooltips show high-res progress bars (`━━●──`).

### 📊 System Vitals & Network
- Monitor **CPU**, **RAM**, **Swap**, and **GPU** in one place.
- **Hybrid GPU Monitoring**: Real-time tracking for **NVIDIA**, **Intel**, and **AMD** GPUs.
- **Redesigned Vitals**: Modern Nerd Font icons and dual-GPU monitoring.
- **Real-time Network**: Download and Upload speeds with progress bars.

### 🔔 Notifications & Updates
- **Notification Center**: Integrated notification counter with right-click to dismiss all.
- **Update Available**: Discreet indicator when system updates are available.
- **Calcure Integration**: Right-click the clock to launch the **Calcure** TUI calendar.

### 🪟 Smart Window Titles
- **Concise Titles**: Automatically extracts filenames from long strings (optimized for VS Code).
- **Clean Interface**: Shows the App Name in the bar while keeping the filename in the tooltip.

---

## 🛠️ Installation

### Quick Install (Piping to Bash)
To install this configuration with a single command, run:
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/AzeemAli14/waybar-config/v2.0/install.sh)"
```

### Manual Installation
To install with the full visual experience, run:
```bash
git clone -b v2.0 https://github.com/AzeemAli14/waybar-config.git ~/.config/waybar
cd ~/.config/waybar
chmod +x install.sh
./install.sh
```

---

## 📸 Tooltips
| **Omarchy Menu** | **Current Window** | **Audio Player** |
| :---: | :---: | :---: |
| <img src="assets/waybar_v2.0/new_omarchy_menu.png" width="280"> | <img src="assets/waybar_v2.0/new_window.png" width="280"> | <img src="assets/waybar_v2.0/new_media.png" width="280"> |
| **Calendar** | **System Vitals** | **Weather Vitals** |
| <img src="assets/waybar_v2.0/new_time_calendar.png" width="280"> | <img src="assets/waybar_v2.0/new_vitals.png" width="280"> | <img src="assets/waybar_v2.0/new_weather.png" width="280"> |
| **Bluetooth Status** | **WiFi Status** | **PusleAudio Status** |
| <img src="assets/waybar_v2.0/new_bluetooth.png" width="280"> | <img src="assets/waybar_v2.0/new_networks.png" width="280"> | <img src="assets/waybar_v2.0/new_pulseAudio.png" width="280"> |
| **Battery Status** |
| <img src="assets/waybar_v2.0/new_battery.png" width="280"> |
---

## 📦 Dependencies

Ensure these are installed for the full experience:

| Type | Packages |
| :--- | :--- |
| **Core** | `waybar`, `jq`, `curl`, `awk`, `procps` (`top`, `free`) |
| **Media** | `playerctl`, `pamixer` |
| **System** | `btop`, `hyprctl`, `nvidia-smi` (optional), `quickshell`, `calcure` |
| **Fonts** | `JetBrainsMono Nerd Font` (Required for Icons) |

---

<div align="center">
  <sub><i>"Simplicity is the ultimate sophistication."</i></sub>
</div>
