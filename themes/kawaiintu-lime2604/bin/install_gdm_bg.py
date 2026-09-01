#!/usr/bin/env python3
import os
import subprocess
import sys
import shutil
import re

if len(sys.argv) > 1:
    THEME_DIR = sys.argv[1]
else:
    THEME_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    
BIN_DIR = os.path.join(THEME_DIR, "bin")
SHELL_DIR = os.path.join(THEME_DIR, "gnome-shell")
BUILD_DIR = os.path.join(BIN_DIR, "build_gdm")
THEME_NAME = os.path.basename(THEME_DIR)

SOURCE_CSS = os.path.join(SHELL_DIR, "gnome-shell.css")
SOURCE_BG = os.path.join(SHELL_DIR, "login-background.png")

SYS_THEME_DIR = os.path.join("/usr/share/themes", THEME_NAME, "gnome-shell")
TARGET_GRESOURCE = os.path.join(SYS_THEME_DIR, "gnome-shell-theme.gresource")
SYSTEM_GRESOURCE = "/usr/share/gnome-shell/gnome-shell-theme.gresource"

def main():
    print("==================================================")
    print(" [*] Kawaiintu GDM Installer (Native Resource Bundle)")
    print("==================================================")

    if not os.path.exists(SOURCE_CSS):
        sys.exit(1)

    if os.path.exists(BUILD_DIR):
        shutil.rmtree(BUILD_DIR)
    os.makedirs(BUILD_DIR)

    try:
        files_out = subprocess.check_output(["gresource", "list", SYSTEM_GRESOURCE], text=True)
        system_files = files_out.strip().split("\n")
    except Exception as e:
        sys.exit(1)

    xml_files = set()

    for filepath in system_files:
        if not filepath:
            continue
        rel_path = filepath.replace("/org/gnome/shell/theme/", "")
        
        if rel_path == "login-background.png" or rel_path.endswith(".css"):
            continue

        out_path = os.path.join(BUILD_DIR, rel_path)
        os.makedirs(os.path.dirname(out_path), exist_ok=True)
        with open(out_path, "wb") as f:
            subprocess.run(["gresource", "extract", SYSTEM_GRESOURCE, filepath], stdout=f)
        xml_files.add(rel_path)

    for root, dirs, files in os.walk(SHELL_DIR):
        for file in files:
            if file.endswith(".gresource") or file == "login-background.png" or file == "default-background.png" or file.endswith(".css"):
                continue
            
            src_file = os.path.join(root, file)
            rel_path = os.path.relpath(src_file, SHELL_DIR)
            dst_file = os.path.join(BUILD_DIR, rel_path)
            
            os.makedirs(os.path.dirname(dst_file), exist_ok=True)
            shutil.copy2(src_file, dst_file)
            xml_files.add(rel_path)

    if os.path.exists(SOURCE_BG):
        shutil.copy2(SOURCE_BG, os.path.join(BUILD_DIR, "login-background.png"))
        xml_files.add("login-background.png")

    with open(SOURCE_CSS, "r") as f:
        css_content = f.read()

    css_content = re.sub(r"url\(['\"].*?login-background\.png['\"]\)(\s*!important)?", "url('login-background.png')", css_content)
    css_content = css_content.replace("background-size: cover !important;", "")
    css_content = css_content.replace("background-position: center !important;", "")
    css_content = css_content.replace("background-size: auto !important;", "")
    css_content = css_content.replace("background-position: 0 0 !important;", "")

    with open(os.path.join(BUILD_DIR, "gdm.css"), "w") as f:
        f.write(css_content)
    xml_files.add("gdm.css")

    xml_lines = [
        '<?xml version="1.0" encoding="UTF-8"?>',
        '<gresources>',
        '  <gresource prefix="/org/gnome/shell/theme">'
    ]
    for f in sorted(xml_files):
        xml_lines.append(f'    <file>{f}</file>')
    xml_lines.extend(['  </gresource>', '</gresources>'])
    
    with open(os.path.join(BUILD_DIR, "theme.xml"), "w") as f:
        f.write("\n".join(xml_lines))

    os.makedirs(SYS_THEME_DIR, exist_ok=True)

    try:
        subprocess.run(["glib-compile-resources", "theme.xml", f"--target={TARGET_GRESOURCE}"], cwd=BUILD_DIR, check=True)
        subprocess.run(["update-alternatives", "--install", "/usr/share/gnome-shell/gdm-theme.gresource", "gdm-theme.gresource", TARGET_GRESOURCE, "50"], check=True)
        subprocess.run(["update-alternatives", "--set", "gdm-theme.gresource", TARGET_GRESOURCE], check=True)
    except subprocess.CalledProcessError as e:
        sys.exit(1)
    finally:
        if os.path.exists(BUILD_DIR):
            shutil.rmtree(BUILD_DIR)

if __name__ == "__main__":
    main()
