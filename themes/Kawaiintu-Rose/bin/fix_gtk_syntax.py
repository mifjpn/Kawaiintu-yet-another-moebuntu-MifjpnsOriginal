#!/usr/bin/env python3
import re
import os

TARGET_FILES = [
    "/usr/share/themes/kawaiintu-rose2604/gtk-3.0/gtk.css",
    "/usr/share/themes/kawaiintu-rose2604/gtk-4.0/gtk.css"
]

def fix_syntax():
    print("==================================================")
    print(" [*] GTK CSS 構文修復ツール")
    print("==================================================")
    for filepath in TARGET_FILES:
        if not os.path.exists(filepath):
            print(f" [-] スキップ: {filepath} が見つかりません。")
            continue
        
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        # 構造({}や;)を維持したまま、エラーの原因である '!important' のみを安全に除去
        cleaned_content = re.sub(r'\s*!important', '', content)

        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(cleaned_content)
        
        print(f" [+] 修復完了: {filepath}")
    print("==================================================")

if __name__ == "__main__":
    fix_syntax()
    
