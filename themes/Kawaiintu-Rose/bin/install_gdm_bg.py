#!/usr/bin/env python3
import os
import subprocess
import sys
import shutil

THEME_DIR = "/usr/share/themes/kawaiintu-rose2604"
BIN_DIR = os.path.join(THEME_DIR, "bin")
SHELL_DIR = os.path.join(THEME_DIR, "gnome-shell")
BUILD_DIR = os.path.join(BIN_DIR, "build_gdm")

SOURCE_CSS = os.path.join(SHELL_DIR, "gnome-shell.css")
TARGET_GRESOURCE = os.path.join(SHELL_DIR, "gnome-shell-theme.gresource")
SYSTEM_GRESOURCE = "/usr/share/gnome-shell/theme/Yaru/gnome-shell-theme.gresource"

def main():
    print("==================================================")
    print(" [*] Kawaiintu GDM インストーラー (外部画像/CSS特化版)")
    print("==================================================")

    if not os.path.exists(SOURCE_CSS):
        print(f"[!] エラー: カスタムCSS ({SOURCE_CSS}) が見つかりません。")
        sys.exit(1)

    if os.path.exists(BUILD_DIR):
        shutil.rmtree(BUILD_DIR)
    os.makedirs(BUILD_DIR)

    print("[*] システムの標準UIパーツ(Yaru)を抽出しています...")
    try:
        files_out = subprocess.check_output(["gresource", "list", SYSTEM_GRESOURCE], text=True)
        files = files_out.strip().split("\n")
    except Exception as e:
        print(f"[!] リスト取得に失敗しました: {e}")
        sys.exit(1)

    xml_lines = [
        '<?xml version="1.0" encoding="UTF-8"?>',
        '<gresources>',
        '  <gresource prefix="/org/gnome/shell/theme">'
    ]

    for filepath in files:
        rel_path = filepath.replace("/org/gnome/shell/theme/", "")
        
        # 純正の画像とCSSは除外（後で自分のもので上書きするため）
        # ※ login-background.png は内部に抱え込まず外部参照にするため、ここで破棄します。
        if rel_path == "login-background.png" or rel_path.endswith("gnome-shell.css") or rel_path.endswith("gdm.css"):
            continue

        out_path = os.path.join(BUILD_DIR, rel_path)
        os.makedirs(os.path.dirname(out_path), exist_ok=True)
        with open(out_path, "wb") as f:
            subprocess.run(["gresource", "extract", SYSTEM_GRESOURCE, filepath], stdout=f)
        xml_lines.append(f'    <file>{rel_path}</file>')

    print("[*] カスタムCSSを組み込んでいます...")
    # gnome-shell.css として配置
    shutil.copy2(SOURCE_CSS, os.path.join(BUILD_DIR, "gnome-shell.css"))
    xml_lines.append('    <file>gnome-shell.css</file>')
    
    # ！！！最重要！！！ GDMのフェイルセーフ回避のために gdm.css としてもコピー配置する
    shutil.copy2(SOURCE_CSS, os.path.join(BUILD_DIR, "gdm.css"))
    xml_lines.append('    <file>gdm.css</file>')

    # 変更点：画像の封入処理を完全削除
    print("[*] 背景画像はCSSからの外部参照 (file://) となるため、リソースへの封入をスキップします。")

    xml_lines.extend(['  </gresource>', '</gresources>'])
    with open(os.path.join(BUILD_DIR, "theme.xml"), "w") as f:
        f.write("\n".join(xml_lines))

    os.makedirs(SHELL_DIR, exist_ok=True)

    print(f"[*] カプセルを生成中... ({TARGET_GRESOURCE})")
    try:
        subprocess.run(["glib-compile-resources", "theme.xml", f"--target={TARGET_GRESOURCE}"], cwd=BUILD_DIR, check=True)
        
        print("[*] Alternative (gdm-theme.gresource) に登録・適用します...")
        subprocess.run(["update-alternatives", "--install", "/usr/share/gnome-shell/gdm-theme.gresource", "gdm-theme.gresource", TARGET_GRESOURCE, "50"], check=True)
        subprocess.run(["update-alternatives", "--set", "gdm-theme.gresource", TARGET_GRESOURCE], check=True)
        
        print("\n[+] 全行程完了！: GDMを再起動してください。")
        print("    ※ 今後は bg_change.sh などで外部の画像を差し替えるだけで背景が変更されます。")
    except subprocess.CalledProcessError as e:
        print(f"[!] コマンド実行中にエラーが発生しました: {e}")
        sys.exit(1)
    finally:
        if os.path.exists(BUILD_DIR):
            shutil.rmtree(BUILD_DIR)

if __name__ == "__main__":
    main()
    
