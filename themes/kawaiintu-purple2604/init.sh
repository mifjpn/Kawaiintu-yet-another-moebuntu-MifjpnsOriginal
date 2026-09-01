#!/bin/bash
set -e

THEME_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_NAME="$(basename "${THEME_DIR}")"
GREETER_CONF="/etc/gdm3/greeter.dconf-defaults"

echo "=================================================="
echo " [*] Kawaiintu Initialization & Ubuntu Trademark Removal Script (${THEME_NAME})"
echo "=================================================="

if [ "$EUID" -ne 0 ]; then
  echo "[!] Error: This script must be run with sudo."
  exit 1
fi

echo "[*] Completely removing Ubuntu trademarks and logos from GDM..."
sed -i "s|^#* *logo=.*|logo=''|g" "$GREETER_CONF"
sed -i "s|^#* *fallback-logo=.*|fallback-logo=''|g" "$GREETER_CONF"
dconf update
echo "[+] Logo settings have been completely disabled."

echo "[*] Restoring GDM theme priority to default (Yaru)..."
if command -v update-alternatives &> /dev/null; then
    update-alternatives --set gdm-theme.gresource /usr/share/gnome-shell/theme/Yaru/gnome-shell-theme.gresource || update-alternatives --auto gdm-theme.gresource
    update-alternatives --remove gdm-theme.gresource "/usr/share/gnome-shell/theme/${THEME_NAME}.gresource" 2>/dev/null || true
fi

echo "[*] Forcing desktop environment theme settings to default (Yaru)..."
if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_UID=$(id -u "$SUDO_USER")
    if [ -S "/run/user/${REAL_UID}/bus" ]; then
        export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${REAL_UID}/bus"
        
        sudo -u "$SUDO_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" dconf write /org/gnome/desktop/interface/gtk-theme "'Yaru'"
        sudo -u "$SUDO_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" dconf write /org/gnome/desktop/interface/color-scheme "'default'"
        sudo -u "$SUDO_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" dconf write /org/gnome/shell/extensions/user-theme/name "'Yaru'"
        
        sudo -u "$SUDO_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" gnome-extensions disable user-theme@gnome-shell-extensions.gcampax.github.com || true
        
        echo "[+] Successfully restored GTK/Shell theme settings for user ($SUDO_USER) to Yaru."
    else
        echo "  -> D-Bus session not found. Assuming ISO build environment, skipping immediate user UI restoration."
    fi
else
    echo "  -> Interactive user not found. Only system settings were initialized."
fi

echo "[*] Cleaning up build workspace..."
if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    USER_HOME=$HOME
fi
BUILD_DIR="${USER_HOME}/.kawaiintu_build/${THEME_NAME}"

if [ -d "$BUILD_DIR" ]; then
    rm -rf "$BUILD_DIR"
    rm -rf "/usr/share/backgrounds/${THEME_NAME}"
    rm -rf "/usr/share/themes/${THEME_NAME}"
    echo "[+] Workspace removed: ${BUILD_DIR}"
fi

echo "=================================================="
echo "[+] All initialization and trademark removal completed!"
echo "    Please restart GDM with: sudo systemctl restart gdm3"
echo "=================================================="
