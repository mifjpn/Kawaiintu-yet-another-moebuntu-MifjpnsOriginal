#!/bin/bash
set -e

# スクリプト自身のディレクトリパスからテーマ名(色)を自動取得する
THEME_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_NAME="$(basename "${THEME_DIR}")"
BIN_DIR="${THEME_DIR}/bin"
GREETER_CONF="/etc/gdm3/greeter.dconf-defaults"

echo "=================================================="
echo " [*] Kawaiintu セットアップスクリプト (${THEME_NAME} 専用)"
echo "=================================================="

if [ "$EUID" -ne 0 ]; then
  echo "[!] エラー: このスクリプトは sudo で実行してください。"
  exit 1
fi

echo "[*] 必須ツールを確認しています..."
if ! command -v glib-compile-resources &> /dev/null; then
    apt-get update
    apt-get install -y libglib2.0-dev-bin
fi

if ! dpkg -l | grep -qw "gnome-shell-extensions"; then
    echo "[*] 拡張機能パック(gnome-shell-extensions)をインストールしています..."
    apt-get install -y gnome-shell-extensions
fi

echo "[*] ログイン背景をリセットし、ダークCSSを同期しています..."
if [ -f "${THEME_DIR}/gnome-shell/default-background.png" ]; then
    cp -f "${THEME_DIR}/gnome-shell/default-background.png" "${THEME_DIR}/login-background.png"
    chmod 644 "${THEME_DIR}/login-background.png"
fi

if [ -f "${THEME_DIR}/gnome-shell/gnome-shell.css" ]; then
    cp -f "${THEME_DIR}/gnome-shell/gnome-shell.css" "${THEME_DIR}/gnome-shell/gnome-shell-dark.css"
fi
if [ -f "${THEME_DIR}/gtk-4.0/gtk.css" ]; then
    cp -f "${THEME_DIR}/gtk-4.0/gtk.css" "${THEME_DIR}/gtk-4.0/gtk-dark.css"
fi
if [ -f "${THEME_DIR}/gtk-3.0/gtk.css" ]; then
    cp -f "${THEME_DIR}/gtk-3.0/gtk.css" "${THEME_DIR}/gtk-3.0/gtk-dark.css"
fi

echo "[*] GDMのロゴを非表示に設定しています..."
sed -i "s|^#* *logo=.*|logo=''|g" "$GREETER_CONF"
sed -i "s|^#* *fallback-logo=.*|fallback-logo=''|g" "$GREETER_CONF"
dconf update

echo "[*] カプセル生成スクリプトを実行します..."
if [ -f "${BIN_DIR}/install_gdm_bg.py" ]; then
    python3 "${BIN_DIR}/install_gdm_bg.py"
else
    echo "[!] エラー: ${BIN_DIR}/install_gdm_bg.py が見つかりません。"
    exit 1
fi

echo "[*] デスクトップ環境のTweakを Kawaiintu に強制上書きしています..."
if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_UID=$(id -u "$SUDO_USER")
    
    # ソケットの存在確認を追加（uninstall.shと同じ安全な手法）
    if [ -S "/run/user/${REAL_UID}/bus" ]; then
        export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${REAL_UID}/bus"
        
        # 1. User Theme拡張機能の有効化
        sudo -u "$SUDO_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com || true
        
        # 2. GTK(レガシー)テーマの適用
        sudo -u "$SUDO_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" dconf write /org/gnome/desktop/interface/gtk-theme "'$THEME_NAME'"
        
        # 3. ウィンドウマネージャー(枠・ボタン)テーマの適用【追加】
        sudo -u "$SUDO_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" dconf write /org/gnome/desktop/wm/preferences/theme "'$THEME_NAME'"
        
        # 4. カラースキームの干渉を防ぐ【追加】
        sudo -u "$SUDO_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" dconf write /org/gnome/desktop/interface/color-scheme "'default'"
        
        # 5. Shell(トップバーなど)テーマの適用
        sudo -u "$SUDO_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" dconf write /org/gnome/shell/extensions/user-theme/name "'$THEME_NAME'"
        
    else
        echo "  -> D-Busセッションが見つかりません。GUIへの即時反映をスキップします。"
    fi
fi

echo "=================================================="
echo "[+] ${THEME_NAME} のインストール行程が完了しました！"
echo "    sudo systemctl restart gdm3 でGDMを再起動してください。"
echo "=================================================="
