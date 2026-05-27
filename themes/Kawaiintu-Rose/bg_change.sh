#!/bin/bash
set -e

THEME_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_IMG="${THEME_DIR}/login-background.png"

echo "=================================================="
echo " [*] Kawaiintu ログイン背景変更ツール (自動変換/単色対応版)"
echo "=================================================="

if [ "$EUID" -ne 0 ]; then
  echo "[!] エラー: このスクリプトは sudo で実行してください。"
  exit 1
fi

echo "[*] 必須ツール (ImageMagick) を確認しています..."
if ! command -v convert &> /dev/null; then
    echo "[-] ImageMagickが見つかりません。自動インストールを開始します..."
    apt-get update
    apt-get install -y imagemagick
    echo "[+] インストールが完了しました。"
fi

# 引数がない、またはファイルが存在しない場合のフォールバック処理
if [ -z "$1" ] || [ ! -f "$1" ]; then
    echo "[*] 画像が指定されていない、または見つかりません。"
    echo "[*] デフォルトのダーク背景 (#222222) を自動生成して適用します..."
    # ImageMagickで 1920x1080 の #222222 単色PNGを生成
    convert -size 1920x1080 xc:"#222222" "$TARGET_IMG"
else
    SRC_IMG="$1"
    echo "[*] 指定された画像を最適なPNGフォーマットに変換・適用しています..."
    convert "$SRC_IMG" "$TARGET_IMG"
fi

chmod 644 "$TARGET_IMG"

# カプセル化スクリプトがある場合は再実行してGDMに反映させる
BIN_DIR="${THEME_DIR}/bin"
if [ -f "${BIN_DIR}/install_gdm_bg.py" ]; then
    echo "[*] カプセル生成スクリプトを実行し、GDMに画像を反映します..."
    python3 "${BIN_DIR}/install_gdm_bg.py"
fi

echo "=================================================="
echo "[+] 変更が完全に完了しました！"
echo "    次回のログアウトまたは起動時から新しい画像が適用されます。"
echo "    ※ sudo systemctl restart gdm3 で即時確認できます。"
echo "=================================================="
