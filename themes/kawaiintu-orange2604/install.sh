#!/bin/bash
set -e

THEME_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_NAME="$(basename "${THEME_DIR}")"
GREETER_CONF="/etc/gdm3/greeter.dconf-defaults"

if [ "$EUID" -ne 0 ]; then
  echo "[!] Error: This script must be run as root (sudo)."
  exit 1
fi

if [ -n "$SUDO_USER" ]; then
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    USER_HOME=$HOME
fi
BUILD_DIR="${USER_HOME}/.kawaiintu_build/${THEME_NAME}"

echo "=================================================="
echo " [*] Kawaiintu Setup Script (${THEME_NAME})"
echo " [*] Workspace: ${BUILD_DIR}"
echo "=================================================="

echo "[*] Checking for required tools..."
if ! command -v glib-compile-resources &> /dev/null; then
    apt-get update && apt-get install -y libglib2.0-dev-bin
fi
if ! command -v convert &> /dev/null; then
    echo "[*] Installing ImageMagick..."
    apt-get update && apt-get install -y imagemagick
fi
if ! command -v xrandr &> /dev/null; then
    echo "[*] Installing x11-xserver-utils..."
    apt-get update && apt-get install -y x11-xserver-utils
fi
if ! dpkg -l | grep -qw "gnome-shell-extensions"; then
    echo "[*] Installing gnome-shell-extensions..."
    apt-get install -y gnome-shell-extensions
fi

echo "[*] Preparing build assets in the workspace..."
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"
cp -r "${THEME_DIR}/gnome-shell" "${BUILD_DIR}/"
cp -r "${THEME_DIR}/gtk-3.0" "${BUILD_DIR}/" 2>/dev/null || true
cp -r "${THEME_DIR}/gtk-4.0" "${BUILD_DIR}/" 2>/dev/null || true
cp -r "${THEME_DIR}/bin" "${BUILD_DIR}/"

echo "[*] Detecting display resolution and optimizing background..."
SCREEN_SIZE=""

if [ -n "$SUDO_USER" ] && [ -n "$DISPLAY" ]; then
    SCREEN_SIZE=$(sudo -u "$SUDO_USER" env DISPLAY="$DISPLAY" xrandr --current 2>/dev/null | grep -oP 'current \K[0-9]+ x [0-9]+' | sed 's/ x /x/')
fi
if [ -z "$SCREEN_SIZE" ]; then
    SCREEN_SIZE=$(xrandr --current 2>/dev/null | grep -oP 'current \K[0-9]+ x [0-9]+' | sed 's/ x /x/')
fi

if [ -z "$SCREEN_SIZE" ]; then
    SCREEN_SIZE=$(cat /sys/class/drm/*/modes 2>/dev/null | head -n 1)
fi

[ -z "$SCREEN_SIZE" ] && SCREEN_SIZE="1920x1080"

SINGLE_RES=$(cat /sys/class/drm/*/modes 2>/dev/null | head -n 1)
[ -z "$SINGLE_RES" ] && SINGLE_RES="1920x1080"

# background.jpg を正しく読み込む処理
ANIMAL_BG="${THEME_DIR}/../background.jpg"
if [ -f "$ANIMAL_BG" ]; then
    SRC_IMG="$ANIMAL_BG"
elif [ -f "${BUILD_DIR}/gnome-shell/default-background.png" ]; then
    SRC_IMG="${BUILD_DIR}/gnome-shell/default-background.png"
else
    SRC_IMG=""
fi

if [ -n "$SRC_IMG" ]; then
    convert "$SRC_IMG" \
        -resize "${SINGLE_RES}^" -gravity center -extent "${SINGLE_RES}" \
        -write mpr:resized_bg +delete \
        -size "${SCREEN_SIZE}" tile:mpr:resized_bg \
        "${BUILD_DIR}/gnome-shell/login-background.png"
    chmod 644 "${BUILD_DIR}/gnome-shell/login-background.png"
fi

echo "[*] Synchronizing dark CSS..."
if [ -f "${BUILD_DIR}/gnome-shell/gnome-shell.css" ]; then
    cp -f "${BUILD_DIR}/gnome-shell/gnome-shell.css" "${BUILD_DIR}/gnome-shell/gnome-shell-dark.css"
fi
if [ -f "${BUILD_DIR}/gtk-4.0/gtk.css" ]; then
    cp -f "${BUILD_DIR}/gtk-4.0/gtk.css" "${BUILD_DIR}/gtk-4.0/gtk-dark.css"
fi
if [ -f "${BUILD_DIR}/gtk-3.0/gtk.css" ]; then
    cp -f "${BUILD_DIR}/gtk-3.0/gtk.css" "${BUILD_DIR}/gtk-3.0/gtk-dark.css"
fi

echo "[*] Disabling GDM logo..."
sed -i "s|^#* *logo=.*|logo=''|g" "$GREETER_CONF"
sed -i "s|^#* *fallback-logo=.*|fallback-logo=''|g" "$GREETER_CONF"
dconf update

echo "[*] Running gresource compiler script..."
if [ -f "${BUILD_DIR}/bin/install_gdm_bg.py" ]; then
    python3 "${BUILD_DIR}/bin/install_gdm_bg.py" "${BUILD_DIR}"
else
    echo "[!] Error: ${BUILD_DIR}/bin/install_gdm_bg.py not found."
    exit 1
fi

echo "[*] Applying Kawaiintu desktop environment tweaks..."
if [ -n "$SUDO_USER" ]; then
    REAL_UID=$(id -u "$SUDO_USER")
    export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${REAL_UID}/bus"
    
    sudo -u "$SUDO_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com || true
    
    sudo -u "$SUDO_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" dconf write /org/gnome/desktop/interface/gtk-theme "'$THEME_NAME'"
    sudo -u "$SUDO_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" dconf write /org/gnome/shell/extensions/user-theme/name "'$THEME_NAME'"
fi
