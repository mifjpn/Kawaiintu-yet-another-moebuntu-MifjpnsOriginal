#!/usr/bin/env python3
import os
import subprocess

THEME_DIR = "/usr/share/themes/kawaiintu-rose2604"
TARGET_GRESOURCE = os.path.join(THEME_DIR, "gnome-shell", "gnome-shell-theme.gresource")
LINK_NAME = "gdm-theme.gresource"

def main():
    print("==================================================")
    print(" [*] Kawaiintu GDM アンインストーラー (リンク解除版)")
    print("==================================================")

    print(f"[*] Alternative ({LINK_NAME}) の登録を解除しています...")
    try:
        # カスタムテーマの登録解除
        subprocess.run(["update-alternatives", "--remove", LINK_NAME, TARGET_GRESOURCE], check=True)
        # 自動モード（システム標準のYaru）へフォールバック
        subprocess.run(["update-alternatives", "--auto", LINK_NAME], check=True)
        print("[+] Alternativeの解除とシステム標準への復帰が完了しました。")
        
        print("\n[+] アンインストール準備完了。以下の手順で元の状態に戻ります。")
        print("    1. sudo systemctl restart gdm3")
        print(f"    2. sudo rm -rf {THEME_DIR}  (※テーマ自体を削除する場合)")
    except subprocess.CalledProcessError as e:
        print(f"[-] Alternativeの設定解除中にエラーが発生しました: {e}")

if __name__ == "__main__":
    main()
    
    
