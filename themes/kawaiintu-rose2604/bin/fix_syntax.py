#!/usr/bin/env python3
import re
import os

TARGET_FILES = [
    "/usr/share/themes/kawaiintu-rose2604/gtk-4.0/gtk.css",
    "/usr/share/themes/kawaiintu-rose2604/gtk-3.0/gtk.css"
]

def fix_syntax():
    print("==================================================")
    print(" [*] GTK CSS Syntax Repair Tool")
    print("==================================================")
    for filepath in TARGET_FILES:
        if not os.path.exists(filepath):
            print(" [-] Skipped: " + filepath + " not found.")
            continue
        
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        cleaned_content = re.sub(r'\s*!important', '', content)

        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(cleaned_content)
        
        print(" [+] Repair complete: " + filepath)
    print("==================================================")

if __name__ == "__main__":
    fix_syntax()
