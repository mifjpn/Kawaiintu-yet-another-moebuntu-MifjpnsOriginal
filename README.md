# Kawaiintu - Yet Another Moebuntu

## Introduction
Kawaiintu is introduced as a Moebuntu with one more change added—a modernized, wholesome reimagining of the "moe" aesthetic, stripped of all inappropriate or extreme elements.

We believe that true "cuteness" should be universally pleasant and accessible, free from specific developer obsessions or problematic underlying themes. Furthermore, we reject development cultures where design is prioritized at the expense of engineering respect.

In light of this, Kawaiintu was born with a focus on pure "cuteness." We have incorporated a highly refined, visually pleasing icon set and system theme, powered by automated resource generation using Bash and Python. By leveraging AI and advanced technical expertise, we built this clean, robust ecosystem in an extremely short period.

The sweetness that constitutes our cute elements is tastefully expressed through carefully selected background images, ensuring a comfortable desktop experience.

Please rest assured that while the underlying philosophy and technical foundation have been completely overhauled, the extensive customization features you expect remain fully intact.

## Overview
![Kawaiintu Background](themes/background.jpg)

A cute, integrated custom theme package for Ubuntu (GTK 4.0). Inspired by the Moebuntu concept, this "mifjpn's original" edition features unique color variations and custom graphical assets.

## Features
* **Multiple Color Variations**: 9 colors available (Pink, Blue, Cyan, Green, Lime, Orange, Purple, Red, Rose) to completely customize your system's look.
* **Original Character Banners**: Includes 8 motif banners (Cat, Penguin, Frog, Fox, Wolf, Sprout, Butterfly, Deer) for UI accents.
* **Custom System Sounds**: Features original system sounds, including standard Moesound and maid voice packs.
* **Total Coordination**: Comes with a dedicated custom icon pack (`KawaiintuIcon`) and custom boot screen themes (`plymouth`) for a consistent desktop experience.

## Directory Structure
* `banner/`: Original banner images (PNG)
* `icons/`: Kawaiintu custom icon pack (`.tar.xz`)
* `plymouth/`: Custom boot screen (Plymouth) themes
* `sound/`: System sound archives
* `themes/`: GTK theme archives and background wallpapers

## Installation & Usage
Kawaiintu completely eliminates the historical, tedious manual installation steps. Environment configuration is fully optimized through automation scripts.

### 1. Prerequisites (GNOME Shell Extension)
To change the GNOME Shell theme, the **User Themes** extension is required.
1. Open your terminal and install the Extension Manager:
   ```bash
   sudo apt install gnome-shell-extension-manager gnome-tweaks

    Launch Extension Manager, go to the Browse tab, search for User Themes, and install it.

    Enable User Themes in the installed extensions list.

2. Applying Themes via Scripts

Execute the bundled scripts in your terminal to automatically set up the GTK theme, GDM (Login Screen), and Plymouth (Boot Screen):

   ◯ ./install.sh
    Automatically deploys theme files to /usr/share/themes/ and configures system-level components (GDM/Plymouth), including the essential update-initramfs initialization. (Requires sudo)

   ◯ ./bg_change.sh
    A helper script to change the GDM login screen background to any image of your choice. Follow the on-screen terminal prompts.

   ◯ ./uninstall.sh
    Safely restores your GDM, Plymouth, and system themes back to the default Ubuntu configuration.

3. Icons & System Sounds

Extract and place the asset packages into the system directories:

    ◯Icons Pack: Extract your preferred color variant to /usr/share/icons/

    ◯Sound Pack: Extract the audio archive to /usr/share/sounds/

After placing the files, launch GNOME Tweaks and navigate to the Appearance and Sound tabs to select and apply the Kawaiintu assets.
4. Desktop Wallpaper

Open themes/background.jpg (or any preferred image) in your file manager, right-click, and select "Set as Wallpaper".
Appendix: Setting deb Firefox as default on Ubuntu 22.04+

Since Ubuntu 22.04, Firefox is packaged as a Snap by default, which may block communication with GNOME extensions. Follow these steps to replace it with the traditional native Deb package if needed:

    Remove the Snap version:
    #!Bash

    snap remove --purge firefox
    sudo apt remove --autoremove firefox

    Add the Mozilla Team PPA:
    #!Bash

    sudo add-apt-repository ppa:mozillateam/ppa

    Configure APT priority:
    Create a preferences file to prioritize the PPA over the Ubuntu snap transition package:
    #!Bash

    sudo nano /etc/apt/preferences.d/99mozillateamppa

    Paste the following content, then save and exit (Ctrl+O -> Enter -> Ctrl+X):
    Plaintext

    Package: firefox*
    Pin: release o=LP-PPA-mozillateam
    Pin-Priority: 1001

    Package: firefox*
    Pin: release o=Ubuntu
    Pin-Priority: -1

    Install Firefox via APT:
    #!Bash

    sudo apt update
    sudo apt install firefox

License

This project uses separate licenses for software components and multimedia assets:

    Code, Scripts, and Configurations: MIT License

    Media Assets (Images, Icons, Banners, and Sounds): CC BY-SA 4.0

Please refer to LICENSE.md for full details.
Author

mifjpn
