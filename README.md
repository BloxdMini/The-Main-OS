# NEXUS OS

NEXUS OS is an Ubuntu 24.04 live desktop for 64-bit AMD64 PCs. Try its **standalone interactive desktop preview** in a browser or launch the real live ISO in QEMU on Windows—no Git clone required.

## Windows: download and run in QEMU

1. [Download `Start-NEXUS-OS.bat`](https://raw.githubusercontent.com/BloxdMini/The-Main-OS/main/Start-NEXUS-OS.bat).
2. Double-click the downloaded batch file. It downloads the latest published ISO into `%LOCALAPPDATA%\NEXUS OS`, installs QEMU via `winget` if needed, and boots the ISO.
3. Run `Start-NEXUS-OS.bat --update` to download the newest ISO again.

The launcher requires an internet connection for the initial ISO download. QEMU installation may require confirmation or administrator permission. The guest needs about 4 GB of memory. The live ISO does not install or make changes to your Windows disk.

The latest ISO is published as verified download parts on [GitHub Releases](https://github.com/BloxdMini/The-Main-OS/releases/latest) after the main-branch build and QEMU boot check succeeds. The launcher reassembles and checksum-verifies them. Downloading the batch file alone does not fetch or run the ISO; run it on Windows to start the setup.

## Browser preview

[Open or download the self-contained NEXUS desktop preview](https://raw.githubusercontent.com/BloxdMini/The-Main-OS/main/nexus-os-preview.html). It includes clickable desktop apps, a draggable window, settings, a local text editor, a demo terminal, a browser start page, a software guide that can copy an apt command, external links to Google Play, Apple's App Store, and Microsoft Store, and direct links to the Windows launcher and release. These are browser-preview interactions only: it does not run Linux applications, install packages, or access your computer's files. Use the QEMU ISO for the real OS.

## Building the ISO

The reproducible build and live-session tools are in [`custom-os-build`](custom-os-build/README.md). The image targets AMD64, not every CPU architecture or host operating system.

NEXUS is an Ubuntu-based live workstation, not a compatibility layer for every Ubuntu, Kali, Termux, and Windows command. It includes an actual Ubuntu package manager for native software; Google Play, Apple's App Store, and Microsoft Store links open their websites but do not install Android or Windows apps on Linux. Its shell and security utilities are selected from Ubuntu's repositories. Tor is disabled at boot; run `sudo tor-routing` to configure and start its local SOCKS proxy. Only applications explicitly configured to use it go through Tor. The included network monitor is a basic local heuristic—not a guarantee that a machine is free of spyware or data collection.
