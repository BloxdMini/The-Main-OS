# NEXUS OS

NEXUS OS is an Ubuntu 24.04 live image for 64-bit x86 (AMD64) systems, with an XFCE desktop and a focused set of network, development, and security tools. The build creates a hybrid BIOS/UEFI ISO; it does not install to a disk or configure all system traffic to use Tor.

## Build Locally

Requirements: Docker, at least 20 GB of free disk space, and 4 GB of memory for a VM.

From the repository root:

```sh
docker build -t nexus-os-builder ./custom-os-build
mkdir -p custom-os-build/output
docker run --rm --privileged \
	-v "$PWD/custom-os-build/output:/output" \
	nexus-os-builder
```

The ISO is written to `custom-os-build/output/nexus-os.iso`. The build container needs mount capabilities to configure a temporary chroot. The builder packages the ISO without installing GRUB to a host disk.

## Desktop and tools

The live image is Ubuntu 24.04 Noble for AMD64, using the Ubuntu archive only. It includes XFCE, a NEXUS wallpaper and logo, Greybird styling, a configured terminal, and Zsh as the default shell for the live user. Bash remains installed and available for scripts and compatibility. Epiphany is the installed web browser; Synaptic is the graphical Ubuntu package manager and uses PolicyKit for authorization. The desktop includes launchers for settings, software management, and an app-catalog page.

The app-catalog page opens the official Google Play, Apple App Store, and Microsoft Store websites in the browser. These sites are for browsing; their Android and Windows apps do not install as native Ubuntu applications. Install Ubuntu software with Synaptic or `sudo apt install`. The preinstalled command-line/security set is curated rather than exhaustive: it includes common development runtimes, network diagnostics, packet analysis, and tools such as Nmap, SQLmap, Aircrack-ng, John, Hashcat, Lynis, and Firejail. The Ubuntu, Kali, and Termux command sets are not identical; Windows `cmd.exe` commands do not run natively in this Linux image. Adding Kali rolling repositories or claiming universal command compatibility would make the Ubuntu base less reliable.

The image recipe adds no telemetry agent. Ubuntu package updates can make network requests while the live session is running. `network-monitor` is a local heuristic checker, not proof against spyware or data exfiltration. Tor is opt-in and provides a local SOCKS proxy; only applications explicitly configured to use it go through Tor. A Tor new-identity request does not guarantee a different exit IP.

## GitHub Actions

The `Build NEXUS OS ISO` workflow builds the image, boots it in QEMU with a virtual display, checks for LightDM startup in the serial log, and uploads `nexus-os-iso` as a seven-day artifact. Successful builds from `main` also update the [latest downloadable ISO release](https://github.com/BloxdMini/The-Main-OS/releases/latest). Large ISO files are split into verified download parts for GitHub Releases. Start a build from the repository's Actions tab or with `workflow_dispatch`.

Windows users can download [`Start-NEXUS-OS.bat`](https://raw.githubusercontent.com/BloxdMini/The-Main-OS/main/Start-NEXUS-OS.bat) and run it without cloning the repository. It downloads the latest ISO and starts QEMU; see the [project README](../README.md) for details.

## Live Session Tools

- `network-monitor` runs the included network checks.
- `nexus-hardening` applies system hardening and should only be run after reviewing its system-wide changes.
- `tor-routing` configures the packaged Tor service and local SOCKS proxy; applications must explicitly use the proxy. It does not run automatically in the live session.

This image is for authorized security testing and education. The ISO has a live session and is not an installer.
