#!/bin/bash
set -e

THEME_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_NAME="$(basename "${THEME_DIR}")"

if [ -n "$SUDO_USER" ]; then
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    USER_HOME=$HOME
fi
BUILD_DIR="${USER_HOME}/.kawaiintu_build/${THEME_NAME}"
TARGET_IMG="${BUILD_DIR}/gnome-shell/login-background.png"
BIN_DIR="${THEME_DIR}/bin"

echo "=================================================="
echo " [*] Kawaiintu Login Background Change Tool"
echo "=================================================="

if [ "$EUID" -ne 0 ]; then
  echo "[!] Error: This script must be run as root (sudo)."
  exit 1
fi

if ! command -v convert >/dev/null 2>&1; then
    echo "[*] ImageMagick (convert) not found. Installing..."
    apt-get update && apt-get install -y imagemagick
fi
if ! command -v xrandr >/dev/null 2>&1; then
    echo "[*] x11-xserver-utils not found. Installing..."
    apt-get update && apt-get install -y x11-xserver-utils
fi

SCREEN_SIZE=""
if [ -n "$SUDO_USER" ] && [ -n "$DISPLAY" ]; then
    SCREEN_SIZE=$(sudo -u "$SUDO_USER" env DISPLAY="$DISPLAY" xrandr --current 2>/dev/null | grep -oP 'current \K[0-9]+ x [0-9]+' | sed 's/ x /x/')
fi
if [ -z "$SCREEN_SIZE" ]; then
    SCREEN_SIZE=$(xrandr --current 2>/dev/null | grep -oP 'current \K[0-9]+ x [0-9]+' | sed 's/ x /x/')
fi
if [ -z "$SCREEN_SIZE" ]; then
    echo "[!] Failed to get virtual canvas size. Getting physical resolution from hardware (DRM)..."
    SCREEN_SIZE=$(cat /sys/class/drm/*/modes 2>/dev/null | head -n 1)
fi
[ -z "$SCREEN_SIZE" ] && SCREEN_SIZE="1920x1080"
echo "[*] Detected virtual canvas total resolution: $SCREEN_SIZE"

SINGLE_RES=$(cat /sys/class/drm/*/modes 2>/dev/null | head -n 1)
[ -z "$SINGLE_RES" ] && SINGLE_RES="1920x1080"

if [ -n "$1" ] && [ -f "$1" ]; then
    SRC_IMG="$1"
else
    echo "[*] No argument provided: Falling back to default background."
    ANIMAL_BG="${THEME_DIR}/../background.jpg"
    if [ -f "$ANIMAL_BG" ]; then
        SRC_IMG="$ANIMAL_BG"
    elif [ -f "${BUILD_DIR}/gnome-shell/default-background.png" ]; then
        SRC_IMG="${BUILD_DIR}/gnome-shell/default-background.png"
    else
        echo "[!] Error: Background image not found."
        exit 1
    fi
fi

echo "[*] Resizing and tiling image to fit ${SCREEN_SIZE}..."

mkdir -p "$(dirname "$TARGET_IMG")"
convert "$SRC_IMG" \
    -resize "${SINGLE_RES}^" -gravity center -extent "${SINGLE_RES}" \
    -write mpr:resized_bg +delete \
    -size "${SCREEN_SIZE}" tile:mpr:resized_bg \
    "$TARGET_IMG"
chmod 644 "$TARGET_IMG"

if [ -f "${BIN_DIR}/install_gdm_bg.py" ]; then
    echo "[*] Executing GDM apply script (install_gdm_bg.py)..."
    python3 "${BIN_DIR}/install_gdm_bg.py" "${BUILD_DIR}"
else
    echo "[-] Error: ${BIN_DIR}/install_gdm_bg.py not found."
    exit 1
fi

echo "=================================================="
echo "[+] Complete! (Applied resolution: $SCREEN_SIZE)"
echo "    The new background will be applied on next logout or reboot."
echo "    * To check immediately: sudo systemctl restart gdm3"
echo "=================================================="
