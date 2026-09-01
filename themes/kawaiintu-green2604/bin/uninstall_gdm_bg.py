#!/usr/bin/env python3
import os
import subprocess

import sys, os
if len(sys.argv) > 1:
    THEME_DIR = sys.argv[1]
else:
    THEME_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TARGET_GRESOURCE = os.path.join(THEME_DIR, "gnome-shell", "gnome-shell-theme.gresource")
LINK_NAME = "gdm-theme.gresource"

def main():
    print("==================================================")
    print(" [*] Kawaiintu GDM Uninstaller (Unlink Version)")
    print("==================================================")

    print(f"[*] Deregistering Alternative ({LINK_NAME})...")
    try:
        subprocess.run(["update-alternatives", "--remove", LINK_NAME, TARGET_GRESOURCE], check=True)
        subprocess.run(["update-alternatives", "--auto", LINK_NAME], check=True)
        print("[+] Alternative deregistration and restoration to system default complete.")
        
        print("\n[+] Uninstallation prep complete. Follow these steps to fully restore:")
        print("    1. sudo systemctl restart gdm3")
        print(f"    2. sudo rm -rf {THEME_DIR}  (* If you wish to delete the theme itself)")
    except subprocess.CalledProcessError as e:
        print(f"[-] An error occurred while deregistering Alternative: {e}")

if __name__ == "__main__":
    main()
