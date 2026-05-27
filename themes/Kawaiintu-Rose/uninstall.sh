#!/bin/bash
set -e

THEME_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_NAME="$(basename "${THEME_DIR}")"
GREETER_CONF="/etc/gdm3/greeter.dconf-defaults"

echo "=================================================="
echo " [*] Kawaiintu 構成初期化 ＆ Ubuntu商標排除スクリプト (${THEME_NAME})"
echo "=================================================="

if [ "$EUID" -ne 0 ]; then
  echo "[!] エラー: このスクリプトは sudo で実行してください。"
  exit 1
fi

echo "[*] GDMからUbuntuの商標・ロゴを完全に排除しています..."
sed -i "s|^#* *logo=.*|logo=''|g" "$GREETER_CONF"
sed -i "s|^#* *fallback-logo=.*|fallback-logo=''|g" "$GREETER_CONF"
dconf update
echo "[+] ロゴ設定を完全に無効化しました。"

echo "[*] GDMテーマの主導権を標準(Yaru)に指定しています..."
if command -v update-alternatives &> /dev/null; then
    update-alternatives --set gdm-theme.gresource /usr/share/gnome-shell/theme/Yaru/gnome-shell-theme.gresource || update-alternatives --auto gdm-theme.gresource
fi

echo "[*] デスクトップ環境のテーマ設定を標準(Yaru)に強制上書きしています..."
# ISOビルド(chroot)環境を考慮し、生身のユーザーセッションが存在する場合のみ実行
if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_UID=$(id -u "$SUDO_USER")
    if [ -S "/run/user/${REAL_UID}/bus" ]; then
        export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${REAL_UID}/bus"
        
        sudo -u "$SUDO_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" dconf write /org/gnome/desktop/interface/gtk-theme "'Yaru'"
        sudo -u "$SUDO_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" dconf write /org/gnome/desktop/interface/color-scheme "'default'"
        sudo -u "$SUDO_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" dconf write /org/gnome/shell/extensions/user-theme/name "'Yaru'"
        
        echo "[+] ユーザー($SUDO_USER)のGTK/Shellテーマ設定をYaruで上書き完了しました。（アイコン設定は保持）"
    else
        echo "  -> D-Busセッションが見つかりません。ISOビルド環境と判定し、ユーザーUIの即時復元をスキップします。"
    fi
else
    echo "  -> 対話的ユーザーが見つかりません。システム設定の初期化のみ行いました。"
fi

echo "=================================================="
echo "[+] すべての初期化と商標排除が完了しました！"
echo "    sudo systemctl restart gdm3 でGDMを再起動してください。"
echo "=================================================="
